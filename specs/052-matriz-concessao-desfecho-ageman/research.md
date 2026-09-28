# Research: Matriz Concessão × Desfecho e Ajustes de Status/Encerramento (AGEMAN)

**Date**: 2026-09-28 · **Spec**: [spec.md](./spec.md)

## 1. Estado real do encerramento (código já implementado, mais avançado que os drafts 050-desfecho)

A spec [050-relatorio-gestao-desfecho-ageman](../050-relatorio-gestao-desfecho-ageman/spec.md) e seu `plan.md`/`tasks.md` descrevem um design (enum `desfechoEncerramento` nullable + `houveResolucao`) que **não é o que está implementado**. O código real já entrou em produção com um design mais simples, via uma migration própria:

```1:1:ci-api-v2/prisma/migrations/20260924160000_manifestacao_closed_meio_juridico/migration.sql
ALTER TYPE "ManifestacaoStatus" ADD VALUE 'closed_meio_juridico';
```

```1:9:ci-api-v2/prisma/schema/manifestacao.prisma
enum ManifestacaoStatus {
  draft
  in_review
  forwarding
  answered
  closed
  closed_unresolved
  closed_meio_juridico
}
```

Encerramento (`encerrar-manifestacao.use-case.ts` + `lib/manifestacao-desfecho.ts`) aceita **hoje**:

| `desfecho` enviado | `ManifestacaoStatus` resultante |
| --- | --- |
| `resolvida` | `closed` |
| `meio_juridico` | `closed_meio_juridico` |
| `pendente` | `closed_unresolved` |

Client (`ManifestacaoActionDialogs.tsx`) renderiza `DESFECHO_ENCERRAMENTO_OPTIONS` (de `manifestacao-desfecho-copy.ts`) como 3 botões-pílula — **exatamente o bug reportado na imagem 3**: encerrar como "Pendente" fecha a demanda com status `closed_unresolved`, contraditório com o próprio nome.

**Implicação para 052 (FR-003)**: a mudança é **restringir o enum existente** (client + Zod `manifestacaoDesfechoEncerramentoSchema` em `ouvidoria.schemas.ts`) de 3 para 2 valores — não introduzir um novo campo/coluna. `resolveEncerramentoStatus`/`statusFromDesfechoEncerramento` perdem o branch `pendente`; TypeScript força a remoção (union exaustiva).

**Nota para tasks futuras (fora de 052)**: `civ2-docs/specs/050-relatorio-gestao-desfecho-ageman/{plan.md,contracts,tasks.md}` estão desalinhados com o código real (`tasks.md` T101-T120 seguem todos `[ ]`, mas parte do schema já foi implementada por fora do fluxo Spec Kit). Recomenda-se um `/speckit-complete` ou correção manual dessa spec depois de 052 — **não** é escopo desta feature corrigir a documentação da 050.

## 2. Semântica de "pendente" — três conceitos coexistindo hoje

Confirmado em `dashboard.repositories.ts` (`kpisFromStatusGroups`, blocos `resolutividade`, `demandasFinalizadas`, `demandasPendentes`):

| Campo/bucket atual | Regra SQL | Conceito |
| --- | --- | --- |
| `kpis.desfechoPendentes` / `resolutividade[].pendentes` / `demandasFinalizadas[].pendentes` | `status = 'closed_unresolved'` | **Encerrada** com o desfecho legado "Pendente" (bug da US2) |
| `kpis.pendentes` | `status IN ('draft','in_review','forwarding')` | Aberta (ampla) |
| `demandasPendentes[].emAnalise` | `status = 'in_review'` | Aberta, subconjunto específico |
| `demandasPendentes[].naoFinalizadas` | `status NOT IN ('answered','closed','closed_unresolved','closed_meio_juridico')` | Aberta (= `draft`+`in_review`+`forwarding`, mesmo conjunto de `kpis.pendentes`) |

A clarificação da spec (FR-001a: "Pendente" da matriz = ainda não encerrada) **reaproveita exatamente a regra de `naoFinalizadas`/`kpis.pendentes`** (status fora do conjunto `DESFECHO_STATUS_IN_SQL`), já validada e testada — não é uma regra nova.

O bucket legado (FR-004) reaproveita a regra já existente de `desfechoPendentes`/`resolutividade.pendentes` (`status = 'closed_unresolved'`), só que agora **por concessão** em vez de agregado total/mensal.

## 3. Rótulo "Em análise" — impacto real do rename (FR-005/006)

`in_review` tem rótulo "Em análise" em **muito mais lugares** do que o filtro da lista de demandas:

| Arquivo | Uso |
| --- | --- |
| `ci-api-v2/src/modules/ouvidoria/ouvidoria.mapper.ts` → `MANIFESTACAO_STATUS_LABEL` | Rótulo interno do status (ficha, listagem via API, PDF/DOCX da manifestação) |
| `ci-api-v2/src/modules/ouvidoria/ouvidoria.mapper.ts` → `PUBLIC_MANIFESTACAO_STATUS_LABEL` | Rótulo **público** (consulta pública do cidadão, spec 043) — `in_review` **e** `forwarding` mapeiam ambos para "Em análise" hoje |
| `ci-client-v2/.../pages/ManifestacoesListPage.tsx` → `STATUS_OPTIONS` (filtro) e KPI card "Em análise" | Lista interna de demandas |
| `ci-client-v2/.../lib/manifestacoes-list-stats.ts` | KPI card "Em análise" (outra tela/variação) |
| `ci-client-v2/.../pages/OuvidoriaRelatorioGestaoPage.tsx` (card "Demandas pendentes") + `lib/relatorio-gestao-mappers.ts` (`mapDemandasPendentesChart`) | Linha "Em análise" dentro do bloco que já é o "Pendente" agregado (`demandasPendentes`) |
| `ci-api-v2/.../lib/relatorio-gestao-pdf-sections.ts` + `export-relatorio-gestao-excel.use-case.ts` | KPI "Em análise" nos exports do relatório |

**Decisão**: renomear `in_review` → "Pendente" **em todos os pontos acima** (para todos os tenants, por clarificação), inclusive na consulta pública do cidadão — é a mesma entidade de status, não há motivo de produto para deixá-la inconsistente entre telas. `forwarding` mantém seu próprio rótulo interno ("Tramitando"); a consulta pública pode continuar agrupando `forwarding` com o novo rótulo "Pendente" ou ganhar rótulo próprio — **decisão de implementação de baixo risco, documentada em `data-model.md`**, sem precisar de nova clarificação (não altera requisito de produto, só abrangência de arquivo).

`ManifestacoesListPage.tsx` **já** usa o padrão de desambiguação por sufixo para o status `closed_unresolved` → `"Pendente (desfecho)"`. Esse padrão é reaproveitado (FR-006): `in_review` → `"Pendente"` (sem sufixo, sentido primário) vs. `closed_unresolved` → mantém `"Pendente (desfecho)"` — já existente, não precisa de novo texto.

## 4. "Catálogo de tipos de concessão" — não existe tabela; é derivado

Busca por `Concessao`/`TipoConcessao` no schema Prisma não encontrou nenhum modelo — `OuvidoriaAcessoConcessao` é sobre **permissão de acesso** a manifestações, não sobre catálogo de serviços. O "catálogo" de concessão é hoje só um **mapa de constantes** (`AGEMAN_PROGRAMA_LABEL` em `lib/ageman-catalog.ts`) aplicado via SQL `CASE` (`sqlMapProgramaConcessaoCase` em `lib/map-programa-concessao.ts`), sem flag de tenant.

Isso é consistente com o princípio já registrado na spec irmã 050-tipo-concessao (Edge Cases): *"Tenant não-AGEMAN: bloco continua genérico — mapa reflete programas cadastrados; sem hardcode de tenant."*

**Decisão (implementa a clarificação "só para tenants com catálogo cadastrado" sem introduzir hardcode nem tabela nova)**: o filtro de concessão (FR-007) é **sempre a mesma implementação para todos os tenants**, mas suas opções são **derivadas dos dados** — o backend expõe as concessões **distintas presentes no tenant** (mesma expressão SQL `sqlMapProgramaConcessaoCase`); se a lista vier vazia (tenant sem nenhuma manifestação com `programa`/`serviceMode` mapeável), o controle de filtro não é renderizado. Nenhuma tabela nova, nenhum hardcode de slug de tenant.

## 5. Rótulo do código de concessão '5' — três grafias divergentes hoje (achado do `/speckit-analyze`)

Busca ampla por "Zona Azul"/"Estacionamento Rotativo" no monorepo encontrou **três rótulos diferentes** para o mesmo código `'5'`, em três fontes "canônicas" distintas que não se comunicam entre si:

| Fonte | Rótulo | Onde é usado hoje |
| --- | --- | --- |
| `sqlMapProgramaConcessaoCase` (`lib/map-programa-concessao.ts:13`) | `'Zona Azul'` | SQL literal — alimenta `porMotivo`/`porTipoManifestacao`/orientações (specs 042/049/050), já em produção |
| `AGEMAN_PROGRAMA_LABEL['5']` (`lib/ageman-catalog.ts:12`) | `'Estacionamento Rotativo'` | `resolveProgramaCode`/`resolveProgramaLabel` — usado pelo backfill de motivo; é a fonte que o plan.md desta feature reaproveita para o filtro da US4 |
| `AGEMAN_TIPO_MANIFESTACAO_OPTIONS['5']` (client, `ageman-dashboard-motivo-options.ts:8`) | `'Estacionamento Rotativo (Zona Azul)'` | Único ponto do código atual que já precisou reconciliar as duas grafias — usado no gráfico "Manifestações por Motivo (AGEMAN)" |
| `TIPO_MOTIVO_ALIASES['5']` (client, `relatorio-gestao-mappers.ts:261`) | aceita `['Zona Azul', 'Estacionamento Rotativo (Zona Azul)']` como aliases equivalentes | Confirma que o client já trata as duas grafias como o mesmo conceito, mas não conhece a variante plana `'Estacionamento Rotativo'` do backend |

**Risco para 052**: sem uma decisão explícita, a matriz da US1 (que reaproveita `sqlMapProgramaConcessaoCase` → `'Zona Azul'`) e o filtro da US4 (que reaproveitaria `AGEMAN_PROGRAMA_LABEL` → `'Estacionamento Rotativo'`) exibiriam **rótulos diferentes para a mesma concessão**, quebrando exatamente o cruzamento exigido por SC-003 ("contagem que bate exatamente com o total exibido no relatório/matriz").

**Decisão**: padronizar, nas duas superfícies **novas** desta feature (matriz US1 e filtro US4), o rótulo **`'Estacionamento Rotativo (Zona Azul)'`** — reaproveita o texto já estabelecido em `AGEMAN_TIPO_MANIFESTACAO_OPTIONS` (única fonte que já resolveu esta ambiguidade), preserva o termo histórico "Zona Azul" (dado legado/planilha) sem perder "Estacionamento Rotativo" (termo atual da AGEMAN).

**Correção de escopo (achada durante `/speckit-implement`, T001B)**: `AGEMAN_PROGRAMA_LABEL` **não** é exclusivo do filtro da US4 — é reaproveitado também por `ListProgramasPublicosUseCase` (endpoint público do formulário de nova manifestação, spec 043, fora de escopo de 052) e pelo catálogo público equivalente no client (`ci-client-v2/.../lib/ageman-catalog.ts` → `AGEMAN_PROGRAMA_OPTIONS`, testado literalmente com `'Estacionamento Rotativo'` sem sufixo em `ManifestacaoStepOneForm.validation.test.tsx`). Mutar `AGEMAN_PROGRAMA_LABEL['5']` diretamente mudaria também esse endpoint/formulário público — fora do escopo desta feature. **Implementação corrigida**: novo módulo `lib/concessao-label.ts` (API), só para US1/US4:

- `resolveConcessaoMatrizLabel(programaCode)`: override local `{ '5': 'Estacionamento Rotativo (Zona Azul)' }` sobre `AGEMAN_PROGRAMA_LABEL` — usado pelo filtro/opções da US4 (T045) e por qualquer resolução direta por código.
- `normalizeConcessaoSqlLabel(rawLabel)`: reescreve o valor bruto `'Zona Azul'` (saída do `CASE` de `sqlMapProgramaConcessaoCase`) para o rótulo canônico — usado pelo repository da matriz da US1 (T008) por cima do resultado do `CASE`, sem alterar o `CASE` em si.
- `AGEMAN_PROGRAMA_LABEL['5']` (`ageman-catalog.ts`) **permanece** `'Estacionamento Rotativo'`, sem alteração — preserva o endpoint público e o catálogo client existentes.
- **Não** se altera `sqlMapProgramaConcessaoCase` em si (evita regressão nos blocos já em produção `porMotivo`/`porTipoManifestacao` das specs 042/049/050, fora de escopo de 052).

## 6. Filtro de lista — mecanismo existente a estender

`ListManifestacoesUseCase` → `ListManifestacoesRepository.execute` já aceita filtros (`type`, `status`, `priority`, `category`, `protocol`, `motivo`, `channel`, `from`, `to`, `origem`) validados em `listManifestacoesQuerySchema` (Zod). O campo `programa` já existe na tabela `Manifestacao` (usado nas agregações do dashboard) — **não precisa de migration**. Basta adicionar `concessao` (valor = label canônico, ex. `"Água / Saneamento"`, ou o código curto `'1'..'5'`) ao schema/filtro/repositório, resolvendo via `resolveProgramaCode`/`AGEMAN_PROGRAMA_LABEL` (reaproveita `lib/ageman-catalog.ts`) em vez de duplicar mapeamento — rótulo do código `'5'` ajustado conforme §5.

## 7. Decisões consolidadas

| Decisão | Escolha | Motivo |
| --- | --- | --- |
| Nova coluna/enum Prisma para a matriz? | **Não** | Toda a agregação deriva de `status` (já enum existente) + `programa`/`serviceMode` (já colunas existentes). |
| Onde entra a matriz na API? | Novo campo no `GET /ouvidoria/relatorio-gestao` existente (mesmo filtro `year`/`month` do relatório) | Mesma cohort/período dos demais blocos; evita rota dedicada (diferente do gap 4 série histórica, que precisa de range de anos). |
| Nome do campo novo | `concessaoPorDesfecho` | Consistente com `demandasPorDesfecho` (050-desfecho) e `porMotivo`/`porFormaAtendimento` já existentes. |
| Nº de colunas visíveis na tabela FR-001 | **4** (Resolvida/Jurídico/Pendente/Pendente (desfecho)), não 3 | O bucket legado (FR-004) é exibido como coluna própria na mesma tabela, não escondido/agregado — ajustado no `spec.md` (achado do `/speckit-analyze`, FR-001 dizia "três colunas"). |
| Bucket legado (FR-004) | Campo extra por linha `pendenteEncerradaLegado`, rótulo de exibição **"Pendente (desfecho)"** (mesmo texto já usado em `STATUS_OPTIONS` para `closed_unresolved`, não um terceiro rótulo novo) | Nome de campo explícito evita colisão com a coluna `pendente` (= aberta, FR-001a); rótulo de exibição reaproveita o texto já existente em produção, sem inventar vocabulário novo (FR-006). |
| Rótulo do código de concessão `'5'` | **`'Estacionamento Rotativo (Zona Azul)'`**, tanto na matriz (US1) quanto no filtro (US4), via novo `lib/concessao-label.ts` — **sem** mutar `AGEMAN_PROGRAMA_LABEL` (preserva endpoint público `ListProgramasPublicosUseCase` e catálogo client público) | Ver §5 — unifica 3 grafias divergentes hoje, reaproveitando o texto já usado em `AGEMAN_TIPO_MANIFESTACAO_OPTIONS`, sem regressão no formulário público de nova manifestação. |
| Restrição do enum de encerramento | Reduzir `manifestacaoDesfechoEncerramentoSchema` (Zod) e `MANIFESTACAO_DESFECHO_ENCERRAMENTO` (client/server) para `['resolvida', 'meio_juridico']` | Único ponto de verdade hoje; TS exaustivo força atualizar `statusFromDesfechoEncerramento`. |
| Filtro de concessão na lista | Novo query param `concessao` em `listManifestacoesQuerySchema` + `ListManifestacoesRepository`; opções carregadas de um endpoint/agregação que retorna concessões distintas do tenant | Reaproveita `resolveProgramaCode`/`AGEMAN_PROGRAMA_LABEL`; sem tabela nova (ver §4). |
| Rename "Em análise" → "Pendente" | Em `MANIFESTACAO_STATUS_LABEL`, `PUBLIC_MANIFESTACAO_STATUS_LABEL`, `STATUS_OPTIONS`, KPI cards (`manifestacoes-list-stats.ts`, `ManifestacoesListPage.tsx`), export PDF/Excel (`relatorio-gestao-pdf-sections.ts`, `export-relatorio-gestao-excel.use-case.ts`), `relatorio-gestao-mappers.ts` (`mapDemandasPendentesChart`) | Todos os pontos hoje usam o mesmo rótulo textual "Em análise" para `in_review`; consistência exigida pela FR-005/FR-006. |
