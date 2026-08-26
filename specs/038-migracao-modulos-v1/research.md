# Phase 0 — Research: Migração de Módulos v1 → v2

**Spec**: [spec.md](./spec.md) · **Plan**: [plan.md](./plan.md) · **Data**: 2026-08-21

Todas as incógnitas técnicas foram resolvidas. Nenhum `NEEDS CLARIFICATION` permanece.

## Sumário das decisões

| # | Assunto | Decisão |
|---|---------|---------|
| R1 | Maquinário de migração | Estender `scripts/migracao-agema-v1/` existente |
| R2 | Base externa do Diagnóstico | Segundo cliente `mysql2` read-only, fora do Prisma |
| R3 | Anexos / storage | Reusar `storageKey` do v1 verbatim; corrigir nomes de env |
| R4 | Playwright | Workspace `e2e/` novo; `addInitScript` no v2, `storageState` no v1 |
| R5 | Comparação de dados | Script cross-engine com normalizadores declarados |
| R6 | Status de encerramento | Dois status distintos no v2 |
| R7 | Dashboard da Ouvidoria | 7 endpoints agregados na API, gráficos em Nivo |
| R8 | Documentos da manifestação | `docx` no servidor; PDF no servidor (não no browser) |
| R9 | Fluxo de demandas | Implementar receber/devolver/reencaminhar; corrigir `currentSector` |
| R10 | Documentos tramitados | Consolidar 13 → 1 com `sectorId` + `order` |
| R11 | Controle numérico | Consolidar 6 → 1 com `documentType` (superset já cobre) |
| R12 | Numeração | Preservar número legado; semear sequence pelo máximo do v1 |
| R13 | Setor / Diretorias | Adicionar `nomeCompleto`, `descricao`, `active` |
| R14 | Processos do Diagnóstico | Portar CTE de dedup + classificação + cache |
| R15 | Marcadores | Só servidor; remover fallback de `localStorage` |
| R16 | PDF timbrado | PDFKit no servidor, decomposto em serviços pequenos |
| R17 | Documentos institucionais | Portar modelo ASJUR + sequence transacional + job de abandono |
| R18 | Portal público | Novo app no Turborepo, `--mode` por tenant, Tailwind v4 |
| R19 | Endpoints públicos | Criar na API v2 (não existem hoje) |
| R20 | Anexos públicos órfãos | Risco aberto — investigação é pré-requisito |
| R21 | Gating do Diagnóstico | Permissão de módulo, não UUID de tenant hardcoded |

---

## R1 — Reusar o maquinário de migração já existente

**Decisão**: estender `ci-api-v2/scripts/migracao-agema-v1/`, preservando sua arquitetura em quatro camadas (`source/` → `mappers/` → `load/` → `reconciliation/`).

**Rationale**: o pipeline já cobre as fases `tenant`, `auth`, `ouvidoria` e `gabinete`, com `--dry-run`, `--phase`, id-map persistido em `.cache/`, lista de exclusão curada e testes unitários mapper-first (5 arquivos em `mappers/__tests__/`). Reescrever descartaria trabalho validado em execução de staging (10/08/2026).

**Lacunas concretas a corrigir** (a spec exige idempotência e correspondência total):

| Lacuna | Evidência | Correção no plano |
|--------|-----------|-------------------|
| Idempotência parcial | `ManifestacaoAnexo`, `ManifestacaoEvento` e os 4 controles do Gabinete usam `create` puro → re-execução duplica | Chave natural determinística por registro + `upsert` |
| `Address` não migrado | `data-model.md` da 036 previa; `ouvidoria.mapper.ts` não implementa | Implementar (FR-018 exige endereço) |
| `ManifestacaoSequence` não semeada | Ausente do loader | Semear pelo máximo do v1 (R12) |
| `count-report` não desconta exclusões | `--source-only` reporta v1 bruto | Aplicar lista de exclusão nas contagens (FR-006) |
| `--compare` cobre parcialmente | Sem anexos, eventos, `AdminTenant` | Ampliar a todas as entidades migradas |
| Storage só local | `load/storage-copy.ts` copia no filesystem | Ver R3 — desnecessário, chaves são reutilizáveis |
| `CabinetDemanda` não migrado | Loader assume 0 registros AGEMAN | Confirmar contagem antes de assumir |

**Alternativas rejeitadas**: (a) começar de zero — descarta mapeamentos de enum já validados; (b) usar ferramenta ETL externa — adiciona dependência e tira a migração do alcance dos testes Jest do repositório.

---

## R2 — Base externa do Diagnóstico: segundo cliente MySQL read-only

**Decisão**: acessar a base de processos judiciais por um cliente `mysql2` dedicado, read-only, **fora do Prisma**, espelhando o padrão de `scripts/migracao-agema-v1/source/mysql-v1.client.ts` — mas como serviço injetável do NestJS, não script CLI.

**Rationale**: Prisma 7 é single-datasource por client (`provider = "postgresql"`, sem URL no schema, adapter `@prisma/adapter-pg`). Adicionar um segundo datasource MySQL exigiria um segundo generator + schema + client gerado, aumentando a superfície de build para uma base que a aplicação **nunca escreve** e cujo schema não controlamos (é alimentada por robô de automação jurídica). O repositório já provou o padrão `mysql2` paralelo na 036.

**Forma concreta**: `modules/diagnostico/services/automacao-db.service.ts` com pool (`connectionLimit`, `queueLimit`, keep-alive), env `DIAGNOSTICO_DATABASE_URL`, `DIAGNOSTICO_PROCESSO_TABLE`, `DIAGNOSTICO_DB_POOL_SIZE`, `DIAGNOSTICO_QUERY_CACHE_TTL_MS`, `DIAGNOSTICO_QUERY_CACHE_MAX_ENTRIES` — todas registradas no `envSchema` Zod como opcionais coerentes (ausência → módulo responde indisponível de forma explícita, nunca silenciosa; FR-059).

**Alternativas rejeitadas**: (a) segundo Prisma client MySQL — custo de build e schema não controlado; (b) sincronizar para o PostgreSQL — o usuário decidiu conexão direta, e um job de sync introduziria defasagem e uma cópia a manter; (c) ler via API do v1 — mantém dependência do v1 vivo, contra o objetivo de encerramento de módulo.

---

## R3 — Anexos: chaves do v1 são reutilizáveis; o bug de env é o problema real

**Decisão**: **não copiar nem renomear objetos no bucket.** Migrar `file_storage.caminho_arquivo` diretamente para `storageKey`, verbatim. Corrigir os nomes das variáveis de ambiente e passar a validá-las.

**Rationale**: o `StorageService` do v2 trata `storageKey` como string opaca — `buildStorageKey()` só é chamado no caminho de **escrita**; a leitura (`presignDownload`) repassa a chave para `GetObjectCommand` sem derivar padrão. Logo uma chave do v1 (`{tenantUUID}/{entityType}/{entityId}/{uuid}-{nome}.{ext}`) gera URL assinada válida imediatamente. Bucket, endpoint, região e access key são idênticos entre os dois `.env` (verificado por comparação de digest, sem expor valores).

**Bug encontrado, com correção decidida pelo usuário**: `ci-api-v2/.env` traz os nomes do v1 (`ACCESS_KEY`, `SECRET_KEY`, `BUCKET`, `ENDPOINT_URL`, `REGION_NAME`), mas o código lê `WASABI_ACCESS_KEY`, `WASABI_SECRET_KEY`, `WASABI_ENDPOINT`. Como essas três decidem `useStub`, o v2 está **em stub local silencioso** — grava em `.local-storage` e serve URLs `/storage/stub/...`, sem lançar erro (ao contrário do v1, que falha no construtor). Correção: renomear as chaves para `WASABI_*` **e** adicionar as variáveis ao `envSchema` para o boot falhar em vez de degradar em silêncio.

**Consequências para a migração**:

| Origem (`file_storage`) | Destino v2 | Nota |
|---|---|---|
| `caminho_arquivo` | `storageKey` | verbatim |
| `nome_original` | `fileName` | usado no `Content-Disposition` — **não** usar `nome_arquivo` (sanitizado) |
| `tipo_mime` | `mimeType` | |
| `tamanho_arquivo` | `sizeBytes` | |
| `criado_em` | `createdAt` / `attachedAt` | |
| `tipo_entidade` + `id_entidade` | junção via id-map | |
| `criado_por` | `uploadedByUserId` | pode ser nulo no v1 — ver abaixo |
| `deletado_em IS NULL` | filtro | |
| — | `uploadConfirmed = true` | objeto já existe no bucket |
| — | `kind = file` | v1 não tem anexo-link |

Dois ajustes obrigatórios: `WASABI_PREFIX` deve permanecer vazio (senão chaves novas ganham prefixo e as migradas não, criando duas gerações de namespace); e `uploadedByUserId` é `NOT NULL` em `ManifestacaoAnexo` enquanto `criado_por` do v1 é nulo em várias linhas — tornar a coluna nullable, coerente com a regra do repositório para actors sem linha em `User` (`resolve-user-table-id.ts`).

Vale portar do v1 o `validateTenantPath`, que o v2 não tem: garante que a chave lida começa pelo tenant do requisitante, reforçando FR-079.

---

## R4 — Playwright: workspace, versão e as duas mecânicas de sessão

**Decisão**: novo workspace `ci-client-v2/e2e/` (pacote `@ci/e2e`), `@playwright/test` **1.62.1**, com autenticação por API e duas mecânicas distintas de injeção de sessão.

**Rationale por partes**:

**Localização** — `packages/*` significa "biblioteca consumida pelos apps" (`@ci/ui`, `@ci/shared`, `@ci/domain`); Playwright não é isso. `e2e/` como terceiro membro de `workspaces` mantém a convenção legível e fica fora dos globs `@source` do Tailwind v4. `turbo.json` ganha uma task `e2e` com `cache: false` e **sem** `dependsOn: ["^build"]`, porque a comparação é entre *dev servers*. Os dois servidores sobem pelo `webServer` do próprio Playwright (array de dois, `reuseExistingServer: !process.env.CI`) — nunca por `turbo run dev`, que é `persistent: true` e não devolveria o controle.

**Sessão — o ponto delicado**: o `storageState` do Playwright cobre cookies, `localStorage`, IndexedDB e passkeys, mas **não `sessionStorage`** (documentado oficialmente; a issue #38682 foi fechada como *won't fix*). E o v2 guarda o JWT exatamente em `sessionStorage['ci-access-token']`. Pior: o `AuthProvider` decide o estado inicial de forma síncrona no primeiro render, então o token precisa existir **antes** do primeiro script da página — semear depois do `goto` causa redirect para `/login`.

| App | Origem | Onde vive a sessão | Mecânica |
|---|---|---|---|
| v1 client | `localhost:8080` | `localStorage` (`accessToken`, `refreshToken`, `userData`, `tenantId`, `isSuperAdmin`) | `storageState` — nativo |
| v2 web | `localhost:5173` | `sessionStorage['ci-access-token']` | `context.addInitScript` antes de qualquer `goto` |

Para um spec que dirige os dois lados, usar **dois `browser.newContext()` no mesmo teste** (um com `storageState` do v1, outro com o init script do v2) em vez de um `page` só — evita conflito de `storageState` no nível de `project`. O guard do init script deve checar `window.location.port`, não `hostname`: as duas origens são `localhost`, diferindo só na porta.

**Tenant no v2 é build-time**: vem de `VITE_TENANT_ID` lido do `.env` da raiz (`envDir` compartilhado). Não há como trocar tenant em runtime — se algum dia for preciso testar outro tenant, será um `project` por tenant com seu próprio `webServer` e `env`. Para esta spec (só AGEMAN) isso não é limitação.

**Portas — correção obrigatória**: `apps/web/vite.config.ts` não fixa porta (default 5173) e **5174 pertence ao `admin-saas`**. Hoje o dev server do `@ci/web` subiu em 5174 porque 5173 estava ocupada — ou seja, um E2E apontado para 5174 poderia bater no app errado. O plano fixa `port: 5173, strictPort: true` em `apps/web` para eliminar o fallback silencioso do Vite.

**Prior art reaproveitável** de `C:\controle-interno-workspace\e2e` (Playwright 1.49, pacote standalone): o padrão de fixture `base.extend` com `option: true`, o `network-recorder.ts` (screenshots numerados + gravação de rede por artifact dir), o gate por env (`isXProdEnabled()` + `requireXEnv()` lançando erro) e a disciplina de teardown em `try/finally`. **Não reaproveitar**: injeção em `localStorage` para o v2, o `docker-compose.e2e.yml` (sobe MySQL 8, irrelevante para o PostgreSQL do v2), as rotas do v1, e sobretudo o anti-padrão de **senhas hardcoded como fallback** em `export-dashboard.helper.ts` — credenciais vêm só de env, sem default, e o E2E desta spec **nunca** aponta para produção.

**Alternativas rejeitadas**: (a) Playwright dentro de `apps/web` — mistura teste de browser com o build do app e confunde o `@source` do Tailwind; (b) pacote standalone fora do monorepo (como no v1) — perde o lockfile único e a descoberta pelo turbo; (c) tentar persistir `sessionStorage` via `storageState` — impossível por design.

---

## R5 — Comparação de dados cross-engine

**Decisão**: script Node único que abre as duas conexões (`mysql2` para o v1, Prisma/`pg` para o v2), compara por entidade em dois níveis — **contagem** e **conteúdo campo a campo** — e emite relatório com divergências identificadas por registro e campo. Equivalências de representação ficam num **mapa declarado e revisável**, não embutidas na lógica.

**Rationale**: FR-008 exige tratar como equivalentes as diferenças esperadas entre os sistemas e acusar tudo fora disso. Um mapa declarativo torna auditável *o que* foi considerado equivalente — o oposto de comparações tolerantes espalhadas pelo código, que escondem perda de dado.

**Normalizadores necessários** (derivados dos gaps reais):

| Classe | Exemplo | Tratamento |
|---|---|---|
| Enum PT → EN | `PENDENTE` → `in_review`, `ALTA` → `high` | tabela de mapeamento explícita |
| Data/hora | `datetime(3)` MySQL vs `timestamptz` PostgreSQL | comparar em UTC; falhar se deslizar de dia |
| Decimal | `Decimal(15,2)` nos dois lados | comparar como string de escala fixa, nunca como float |
| Texto | espaços à direita, `NULL` vs `''` | `trim`; `NULL` e vazio equivalentes só onde o v1 usava ambos indistintamente |
| Chave de junção | id v1 → id v2 | via id-map persistido |

O relatório precisa de **três contagens** por entidade (origem, exclusões aprovadas, destino) para satisfazer FR-006, e o script termina em código de falha quando há divergência fora do mapa (FR-007). Um teste dedicado injeta divergência de propósito e exige que o script reprove — FR-011 e SC-004 tornam isso obrigatório, não opcional.

**Alternativa rejeitada**: comparar por dump/diff textual — inviável entre engines diferentes com nomes de coluna e enums distintos.

---

## R6 — Encerramento da manifestação: dois status distintos

**Decisão** (confirmada com o usuário): criar no v2 dois status de encerramento — encerrada **com** resolução e encerrada **sem** resolução — em vez do `closed` único de hoje.

**Rationale**: o v1 distingue `ARQUIVADO` (cancelada) de `ARQUIVADO_OK` (resolvida), e o KPI de **resolutividade** do painel é literalmente a razão entre os dois. Colapsar em `closed` destruiria o indicador — perda de capacidade, o que FR-014 e SC-015 proíbem. Derivar do status mantém a agregação simples e o dado auto-descritivo, sem depender de um booleano acessório poder estar nulo em registros migrados.

**Impacto**: novo valor no enum `ManifestacaoStatus`; migração mapeia `ARQUIVADO`/`ARQUIVADO_OK` um a um; a agregação de resolutividade (R7) lê status, não campo. Os campos `foiAtendido` e `medidasResolucao` do v1 migram como dados descritivos (FR-018 pede preservação de conteúdo), mas **não** são a fonte do KPI.

**Alternativa rejeitada**: manter `closed` + flag `foiAtendido` — deixaria o indicador dependente de campo opcional e exigiria backfill para todo registro histórico.

---

## R7 — Painel da Ouvidoria: 7 agregações na API, gráficos em Nivo

**Decisão**: implementar as sete agregações como endpoints da API v2, com `year`/`month` opcionais, e renderizar tudo em **Nivo** no cliente.

**Rationale**: hoje o `/ouvidoria/dashboard` do v2 é mock (`DashboardCharts`, case `'ouvidoria'`) — gap de 100%. Agregar no banco (e não no cliente) é exigência de FR-076: o v1 já sofre de filtragem client-side sobre 1000 registros carregados, vício que a spec proíbe reproduzir. Nivo é imposto pela constitution (stack fixa); o v1 usa Recharts em parte dos gráficos, então **os gráficos são reescritos, não portados**.

**Semântica exata a preservar** (levantada do `manifestation-dashboard.repository.ts`):

| Agregação | Conta | Agrupa por | Filtro de período |
|---|---|---|---|
| Resolutividade | status encerrado (com e sem resolução) | mês de `archivedAt` | `archivedAt` |
| Atendimentos por mês | todas as manifestações | mês de `createdAt` | `createdAt` |
| Demandas finalizadas | respondidas + encerradas | mês de `respondedAt` (se respondida) senão `archivedAt` | data de referência |
| Demandas pendentes | pendentes + em análise | mês de `createdAt` | `createdAt` |
| Por tipo | por tipo, incluindo "sem tipo" | mês × tipo | `createdAt` |
| Por forma de atendimento | por canal | mês | `createdAt` |
| Por motivo da manifestação | por motivo (taxonomia AGEMAN) | mês × motivo | `createdAt` |

Duas correções de dívida do v1 a **não** reproduzir: o card "Em Análise" do painel é **hardcoded 0** no v1 (verificado na página de dashboard) enquanto a aba de manifestações calcula o valor real — no v2 o valor é sempre real; e o card rotulado "Respondido" no v1 soma respondidas + arquivadas + arquivadas-ok, rótulo enganoso — no v2 rótulo e conteúdo coincidem.

**Fora de escopo**: o gráfico "por motivo interno" do v1 é agregação 100% client-side sobre `internal-services` e existe para a ARSEPAM, não para a AGEMAN. Fica fora (só AGEMAN nesta spec).

---

## R8 — Documento da manifestação: geração no servidor

**Decisão**: gerar o documento da manifestação **no servidor** — DOCX com a biblioteca `docx`, PDF com PDFKit (mesma dependência de R16).

**Rationale**: o v1 gera DOCX no servidor mas o PDF **no browser** com `jspdf`, o que joga branding, layout e dados sensíveis para o cliente e produz saída dependente do navegador. Centralizar no servidor dá um único ponto de verdade para o timbrado, permite testar a saída e evita divergência entre o DOCX e o PDF do mesmo registro.

**Alternativa rejeitada**: manter `jspdf` no cliente — reproduz a dívida e impede teste automatizado do documento gerado.

---

## R9 — Fluxo de demandas do Gabinete: completar as ações e corrigir o setor atual

**Decisão**: implementar `receber`, `devolver` e `reencaminhar` como operações próprias; corrigir o `forward` para atualizar o setor atual; e gerar o histórico de encaminhamentos como documento no servidor.

**Rationale**: o `ForwardCabinetUseCase` do v2 hoje faz append em `forwardings` e muda o status para *em trânsito*, mas **não atualiza `currentSector` nem `sectorId`** — a demanda "anda" no histórico sem andar no cadastro, o que quebra o filtro por setor atual exigido por FR-026 e a listagem de FR-027. E três ações do v1 não existem no v2:

| Ação v1 | Efeito no v1 | Situação no v2 |
|---|---|---|
| `receber` | status → recebido; notifica quem encaminhou | ausente |
| `devolver` | só de DEJUR; destino Ouvidoria/Gabinete; status → devolvida | ausente |
| `reencaminhar` | delega a encaminhar (mesma lógica) | sem rota/semântica própria |
| `anexar` | evento tipo RESPOSTA + anexos | anexo existe, evento de resposta não |
| PDF do histórico | documento institucional | ausente |

Os enums mapeiam **1:1** nos dois sentidos (7 setores, 19 status) — só a convenção de nome difere, então não há valor órfão. O histórico do v1 vive num JSON `encaminhamentos` com forma própria (`tipo`, `titulo`, `setor`, `setorOrigem`, `usuario`, `data`, `observacoes`, `anexos`); no v2 a linha do tempo é `CabinetDemandaEvento` (tabela), que é o destino correto — o JSON migra convertido em eventos, não copiado como blob, atendendo à exigência de ordem cronológica e autor por evento (FR-031).

Nota de arquitetura: o v2 acopla o encaminhamento à abertura de protocolo no módulo Tramitação (`OpenProtocoloLinkedUseCase`), fluxo que não existia no v1. Isso é ganho, não gap — mas o `receber` do v1 não tem equivalente na Tramitação, então a ação precisa existir no Gabinete.

---

## R10 — Documentos tramitados: consolidar 13 tabelas com cuidado

**Decisão**: manter a consolidação em `CabinetDocumentoTramitado` com `sectorId`, e **adicionar o campo `order`** para não perder a coluna `ord`.

**Rationale**: as 13 tabelas do v1 **não têm o mesmo conjunto de colunas** — este é o achado que mais ameaça a migração:

| Grupo de tabelas | Peculiaridade |
|---|---|
| `degplan` | única com `data_despacho` e `prazo`; usa `numero_siged`; **não** tem `observacao` |
| `deae`, `deip`, `deer`, `ouvidoria` | `qtde` + `n_siged` + `observacao` |
| `deret`, `deres` | **`ord` (Int) em vez de `qtde`** |
| `gdp`, `cmr`, `ci`, `governanca` | `tipo_do_protocolo` + `siged` |
| `ascom` | `tipo_protocolo` + `siged` |
| `dejur` | **só vínculos e auditoria — zero campos de documento** |

Consequências decididas: `ord` vai para um novo campo `order` (não para `quantity`, que tem outro significado); as três grafias de número SIGED (`numero_siged`, `n_siged`, `siged`) convergem para `sigedNumber`; as duas de tipo (`tipo_protocolo`, `tipo_do_protocolo`) para `protocolType`; `prazo` do DEGPLAN vai para `deadline` e **não** é misturado com `notes`; e as linhas do DEJUR migram como registros mínimos (só setor e vínculos), preservando a existência sem inventar conteúdo.

Contagem exata de tabelas a validar antes da carga: o loader atual da 036 percorre **12** tabelas, mas o schema do v1 define **13**. Essa diferença precisa ser conciliada, sob risco de um setor inteiro não migrar.

---

## R11 — Controle numérico: o superset do v2 já cobre os 6 tipos

**Decisão**: manter `CabinetControleNumerico` com `documentType`, sem novos campos.

**Rationale**: as 6 tabelas também diferem entre si, mas o modelo do v2 é superset de todas — nenhuma coluna se perde, campos não aplicáveis ficam nulos:

| Tipo v1 | Campos próprios | Destino |
|---|---|---|
| `oficio` | `orgao`, `enderecado`, `historico`, `formalizado_por`, `minutado_por` | `agency`, `addressee`, `history`, `formalizedBy`, `draftedBy` |
| `oficio_circular` | + `assunto`, `solicitante`; sem histórico/formalizado/minutado | `subject`, `requester` |
| `portaria`, `resolucao` | `historico`, `solicitado_por` | `history`, `requester` |
| `memorando`, `memorando_circular` | **`destino`** (não `enderecado`) | `addressee` |

O único cuidado é o mapeamento `destino → addressee` nos memorandos, que de outra forma cairia num campo errado ou se perderia.

---

## R12 — Numeração: preservar o legado, semear a sequência

**Decisão**: registros migrados **conservam o número original** do v1; as sequências do v2 são semeadas a partir do máximo encontrado no v1; números novos seguem o formato do v2.

**Rationale**: FR-002 e SC-003 exigem que uma busca pelo identificador do v1 encontre o registro no v2 — reformatar números migrados quebraria isso. Por outro lado, a geração nova deve usar o mecanismo transacional do v2 (`CabinetDemandaSequence`, `ManifestacaoSequence`), que é superior ao `max+1` do v1: o v1 faz `findFirst` ordenado e conta registros excluídos no máximo, sujeito a corrida e a buracos.

Formatos envolvidos: demandas `GAB2026001` (v1, 3 dígitos) vs `GAB-2026-0001` (v2, 4 dígitos); manifestações numéricas/`PUB` (v1) vs `OUV-YYYY-NNNN` (v2). Semear pelo máximo **parseado** do v1 evita que a primeira demanda nova colida com uma migrada. Protocolo do Gabinete e controle numérico permanecem **manuais** nos dois sistemas — não inventar automação onde o usuário digita o número.

---

## R13 — Setor / Diretorias: campos ausentes no v2

**Decisão**: adicionar `nomeCompleto`, `descricao` e `active` ao `Setor`; mapear `user_sectors.is_manager` do v1 para `Setor.chefeUserId`; e criar a tela de Diretorias no contexto do Gabinete.

**Rationale**: FR-038 exige sigla, nome, nome completo e ativo/inativo — o `Setor` do v2 tem apenas `name`, `sigla` e `chefeUserId`, usando `deletedAt` como proxy de inatividade. Inativar não é excluir: um setor inativo precisa continuar visível na administração e fora das listas de destino (FR-039), o que `deletedAt` não expressa.

Divergência de modelo a resolver: o v1 marca gestor **por par usuário-setor** (`is_manager`), o v2 tem **um** `chefeUserId` por setor. Quando o v1 tiver mais de um gestor no mesmo setor, a migração elege um e registra os demais como membros — decisão que precisa ficar no relatório de migração para não parecer perda silenciosa.

No cliente, o v1 rotula a tela como "Diretorias" dentro do menu Gabinete; o v2 só tem administração de "Setor" fora do Gabinete. A tela nova usa o vocabulário do usuário (Diretorias) sobre a entidade `Setor`.

---

## R14 — Processos do Diagnóstico: portar dedup, classificação e cache

**Decisão**: reproduzir fielmente a semântica de consulta do v1 — CTE de deduplicação, regras de categoria e de tipo de resultado, e cache em memória com TTL — e **ampliar** os campos de busca no servidor.

**Rationale**: a base externa tem mais de uma linha por processo, e o v1 resolve isso com `ROW_NUMBER() OVER (PARTITION BY Numero_do_processo ORDER BY CHAR_LENGTH(COALESCE(Resultado_da_reclamacao,'')) DESC)`, mantendo a linha de resultado mais longo. Qualquer desvio muda as contagens e reprovaria SC-015. As classificações também são regras textuais precisas:

- **Categoria**: `SENTENCA` quando o texto concatenado de objeto+resultado contém termos de sentença (procedência, improcedência, procedência em parte, reparação do dano); `PETICAO_INICIAL` quando contém termos de petição **e não** de sentença; `OUTROS` caso contrário.
- **Tipo de resultado**: cascata **exclusiva e ordenada** — sem resultado → condenação → improcedência → procedência → julgado → em andamento → outros. A ordem importa: inverter muda a classificação.

Dívida do v1 a corrigir: o backend só aceita `autor`, `numeroDoProcesso` e `todos` como campo de busca, mas o cliente oferece sete opções e **refaz o filtro no cliente** sobre a página retornada — exatamente o vício que FR-076 proíbe. No v2 os sete campos são suportados no servidor.

O campo `ultimaAtualizacao` é sempre nulo no v1 (a base não tem timestamp); manter nulo e não inventar.

---

## R15 — Marcadores: apenas servidor

**Decisão**: persistir marcações somente no servidor, com unicidade por tenant + usuário + número de processo. Remover o fallback de `localStorage`.

**Rationale**: FR-077 e SC-010 proíbem dado de negócio dependente do navegador. O fallback do v1 é acionado por falha do GET, falha do toggle, ou 503 de schema ausente, e grava sob a chave `diagnostico-marcadores:{userId}` avisando que ficou "só neste navegador" — ou seja, degrada em perda de dado. No v2 a indisponibilidade é erro explícito com nova tentativa (FR-078), nunca persistência local.

---

## R16 — PDF timbrado: PDFKit no servidor, decomposto

**Decisão**: PDFKit no servidor, com o timbrado da AGEMAN, e a flag de inclusão de gráficos — mas **decomposto em serviços pequenos**, não num arquivo monolítico.

**Rationale**: o v1 concentra a geração em arquivos enormes (`generate-asjur-document-pdf.use-case.ts` com 1260 linhas, `asjur-pdf-layout.service.ts` com 758). A constitution exige uma operação por arquivo em use-cases; reproduzir esses monólitos violaria o princípio e recriaria dívida que a spec proíbe (FR-074). A decomposição natural: resolução do timbrado, composição de cabeçalho/rodapé, renderização de tabelas, renderização de gráficos e o use-case que orquestra.

Os assets do timbrado são PNG por tenant e precisam de etapa de cópia para o build. A geração em DOCX via Carbone existe no v1 apenas para a SEDEL — **fora de escopo** (só AGEMAN).

---

## R17 — Documentos institucionais: portar o modelo, a sequência e o job

**Decisão**: portar o modelo de documentos institucionais com quatro entidades (modelo, documento, sequência, trilha de acesso), sequência **transacional** por tenant/tipo/ano, e job de abandono de reservas.

**Rationale**: FR-066 exige impedir número duplicado inclusive sob emissão simultânea, e FR-065 exige liberar ou marcar como abandonada a reserva não concluída, mantendo a lacuna rastreável. O v1 resolve os dois pontos de forma que vale preservar: `upsert` com `increment` dentro de transação para a sequência, e job a cada 6 horas que marca como abandonado o que ficou reservado por mais de 24 horas.

Uma correção: o job do v1 faz `updateMany` **sem registrar auditoria** do abandono — então a lacuna na numeração não fica rastreável, contrariando o que FR-065 pede. No v2 o abandono gera evento de auditoria.

Ciclo de vida a preservar: reservado → rascunho (no primeiro salvamento) → enviado (payload congelado); reservado → abandonado (por prazo); reservado ou rascunho → cancelado (com motivo obrigatório). O PDF é bloqueado para reservado e abandonado. A leitura de documento enviado gera registro de acesso (FR-064).

Os modelos definem campos tipados (texto, área de texto, data, moeda, texto rico, assinatura, parágrafos, tabela de informações) — a renderização precisa suportar todos, incluindo assinatura como imagem e a tabela de lote de processos.

Acesso: no v1 as rotas institucionais exigem participação no setor jurídico, e quem não participa vê apenas documentos enviados. Essa regra migra como permissão de setor no v2 (FR-079), não como verificação de sigla hardcoded.

---

## R18 — Portal público: novo app no Turborepo

**Decisão**: novo app `apps/publico` (`@ci/publico`) seguindo exatamente o padrão de `apps/admin-saas`, com **`envDir` local** e seleção de tenant por `--mode` do Vite. Escopo restrito ao fluxo AGEMAN de manifestação; o sub-app da SEDEL fica fora (decisão do usuário). O formulário guiado é reproduzido **sem LLM** (decisão do usuário).

**Rationale**: o app do v1 seleciona tenant copiando arquivo (`copyFileSync('.env.ageman', '.env')`) antes de subir o Vite. Isso é incompatível com o monorepo: os apps do v2 usam `envDir` apontado para a **raiz** do `ci-client-v2`, então a cópia sobrescreveria o `.env` compartilhado e **quebraria o `@ci/web`**. O mecanismo nativo `vite --mode ageman` lendo `.env.ageman` elimina o hack e o risco.

**Incompatibilidades concretas a tratar** (o portal é Tailwind 3 + Radix individual; o alvo é Tailwind 4 + shadcn):

| Item | v1 | v2 |
|---|---|---|
| Diretivas CSS | `@tailwind base/components/utilities` | `@import "tailwindcss"` |
| Configuração | `tailwind.config.js` + PostCSS + autoprefixer | plugin Vite + `@theme inline` |
| Tokens de cor | HSL em triplas (`0 0% 100%`) consumidas por `hsl(var(--x))` | cor completa em `--color-*` |
| Conteúdo escaneado | `content: []` | `@source` no CSS |
| Radix | 6 pacotes individuais | pacote unificado |
| Roteamento | `react-router-dom` 6 | 7 (major) |
| Ícones | `lucide-react` 0.462 | 1.17 (major) |
| HTTP | Axios | `fetch` via `createApiClient` |

Além dos majors de Vite (7→8), Tailwind (3→4), TypeScript e ESLint. Os tokens precisam ser reescritos **e** realinhados à paleta Mint — o portal hoje usa um azul institucional que não é a paleta do v2.

Dois componentes genuinamente ausentes de `@ci/ui` e necessários: **toast** e **stepper**. Entram no pacote compartilhado, não no app.

Um anti-padrão a **não** portar: o `PublicApp` do v1 navega por eventos de `window` (`open-review-modal`, `reset-chatbot`, `start-manifestation`) em vez de estado ou rotas. Reescrever como estado React.

A acessibilidade do portal (tamanho de fonte, modos de daltonismo, leitura por síntese de voz) depende de filtros SVG declarados no HTML — precisam ser portados junto, senão os modos de cor silenciosamente não funcionam.

---

## R19 — Endpoints públicos: não existem no v2

**Decisão**: criar na API v2 os endpoints públicos de abertura de manifestação, envio de anexo e consulta, com proteção contra envio automatizado.

**Rationale**: varredura por `@Public()` no `ci-api-v2` mostra que o **único** endpoint público da Ouvidoria hoje é a consulta por protocolo e chave. Não existem equivalentes de abertura pública nem de upload público. O portal, portanto, **não tem para onde apontar** — isso é trabalho de API que o plano contabiliza, não apenas migração de frontend.

A proteção contra automação (FR-071) usa verificação de desafio no envio, com as chaves em variáveis de ambiente validadas, e limite de taxa por origem.

---

## R20 — Risco aberto: anexos públicos sem vínculo

**Decisão**: tratar como **investigação obrigatória antes da carga**, não como suposição.

**Rationale**: no v1, o upload público grava com tipo de entidade `public` e id `temp-{timestamp}-{aleatório}`, ou seja, **a linha de storage não referencia manifestação alguma**. O vínculo é presumivelmente feito na criação da manifestação, consumindo o id temporário devolvido pelo upload — mas isso não foi confirmado no código. Se o vínculo não for reconstruível, os anexos vindos do portal público se perdem, violando FR-012 e SC-007.

Mitigação: uma tarefa de investigação precede a carga de anexos; caso o vínculo seja irrecuperável para parte dos registros, eles entram no relatório de anexos não localizados (FR-013) em vez de desaparecer em silêncio.

---

## R21 — Gating do Diagnóstico: permissão de módulo, não tenant hardcoded

**Decisão**: proteger o Diagnóstico por permissão de módulo e setor (o mecanismo padrão do v2), **sem** exigir licença adicional.

**Rationale**: o v1 trava o módulo comparando o UUID do tenant com uma constante (`isAgemanTenantId`), o que é dívida: qualquer nova instituição exigiria alterar código. O v2 já tem o pipeline `TenantGuard` → `JwtAuthGuard` → `RolesGuard` → `LicencaGuard` → `ModuloPermissaoGuard`, e a vinculação módulo-setor resolve isso por dado. Como fiscalização, insights e maturidade estão fora de escopo, nenhuma das quatro licenças (Carvalho, Pau-Brasil, Jatobá, Cedro) é exigida — o Diagnóstico é módulo operacional de base, como Ouvidoria e Gabinete.

Efeito prático: só a AGEMAN vê o módulo porque só ela terá a vinculação, não porque o código diz o nome dela.
