# Research: Tramitação como Protocolo

**Feature**: 035-tramitacao-protocolo · **Input**: spec.md, codebase (`ci-api-v2/src/modules/tramitacao/`, `ci-client-v2/apps/web/src/modules/tramitacao/`)

Todas as ambiguidades de **negócio** já foram resolvidas interativamente com o solicitante durante `/speckit-specify` (duas rodadas de perguntas — ver spec.md → Assumptions). Este documento resolve as decisões **técnicas** necessárias para o design (Phase 1), avaliando alternativas dentro do padrão já estabelecido no módulo e no restante do monorepo.

## 1. Estratégia de substituição de dados (reset)

**Decision**: Reescrever o schema Prisma do módulo Tramitação **in place** (mesmos nomes de arquivo `ci-api-v2/prisma/schema/tramitacao.prisma`), renomeando as entidades para o vocabulário de Protocolo, e gerar **uma única migration de reset**: `DROP TABLE` de todas as tabelas atuais de `TramitacaoDemanda*` (cascade) seguido de `CREATE TABLE` das novas entidades de `TramitacaoProtocolo*`. Não há migration de dados (linha reta com a decisão do usuário: "reset total").

**Rationale**: O usuário confirmou explicitamente reset de dados porque o ambiente está em desenvolvimento. Reescrever o schema no mesmo arquivo (em vez de criar um novo módulo paralelo) segue a Constitution V (clean code/modularidade — 1 módulo por domínio, sem duplicação) e evita manter dois modelos mentais simultâneos no código.

**Alternatives considered**:
- *Migration incremental com `ALTER TABLE` renomeando colunas/tabelas*: rejeitada — a mudança de cardinalidade (um único `currentSectorId` → N setores participantes via tabela associativa) não é uma renomeação simples; `DROP`+`CREATE` é mais direto e não há dados a preservar.
- *Novo módulo `protocolo/` paralelo ao `tramitacao/` legado*: rejeitada — dobra a superfície de manutenção para uma feature que substitui integralmente a anterior; violaria a modularidade da Constitution V sem ganho real.

## 2. Nomenclatura das entidades Prisma

**Decision**: Renomear as entidades mantendo o prefixo `Tramitacao` (nome do módulo/pacote não muda) e trocando `Demanda` por `Protocolo`:

| Atual | Novo |
|---|---|
| `TramitacaoDemanda` | `TramitacaoProtocolo` |
| `TramitacaoDemandaSequence` | `TramitacaoProtocoloSequence` |
| `TramitacaoDemandaEvento` | `TramitacaoProtocoloEvento` |
| `TramitacaoDemandaAnexo` | `TramitacaoProtocoloAnexo` |
| `TramitacaoDemandaAnexoAccess` | `TramitacaoProtocoloAnexoAccess` |
| `TramitacaoDemandaAnexoDesentranhamento` | `TramitacaoProtocoloAnexoDesentranhamento` |
| *(novo)* | `TramitacaoProtocoloSetor` — participante setor |
| *(novo)* | `TramitacaoProtocoloGestor` — permissão de gestão concedida (US8) |

**Rationale**: Mantém o módulo (`ci-api-v2/src/modules/tramitacao/`) e o namespace de rotas (`/tramitacao/...`) estáveis — apenas a entidade central e seu vocabulário mudam, minimizando o raio de impacto em módulos que já apontam para `tramitacao` (Gabinete/Ouvidoria/Jurídico via `sourceModule`). `protocolNumber` já usa o prefixo `TRAM-AAAA-NNNN`, que continua fazendo sentido e **não muda**.

**Alternatives considered**: Renomear o módulo inteiro para `protocolo/` — rejeitado por ampliar inutilmente o escopo (rotas, licença, navegação, todas as integrações cross-módulo precisariam mudar de path).

## 3. Modelo de participação (setores) e permissão de gestão

**Decision**:
- `TramitacaoProtocoloSetor` — tabela associativa `(tenantId, protocoloId, setorId, createdAt)`, `@@unique([protocoloId, setorId])`. Qualquer usuário membro de um setor presente aqui tem acesso de leitura e pode adicionar atualizações (FR-006).
- `TramitacaoProtocoloGestor` — tabela associativa `(tenantId, protocoloId, userId, concedidoPorUserId, createdAt)`, `@@unique([protocoloId, userId])`. Representa permissão de **gestão** (incluir setor, encerrar) concedida explicitamente a um participante além do autor.
- O **autor** (`TramitacaoProtocolo.autorUserId`) tem permissão de gestão implícita — não precisa de linha em `TramitacaoProtocoloGestor`.
- Função central `canManageProtocolo(protocolo, gestores, actor)` em `lib/` resolve: `actor.id === protocolo.autorUserId || gestores.some(g => g.userId === actor.id)`.

**Rationale**: Reflete a resposta do usuário ("quem abriu + pessoas incluídas, porém com permissão") — a colaboração (ler/atualizar) é ampla por setor, mas a gestão (incluir setor/encerrar) é uma permissão nominal e explícita, não herdada automaticamente por todos os membros do setor. Separar em duas tabelas evita sobrecarregar `TramitacaoProtocoloSetor` com uma flag que se aplicaria a "todos os membros daquele setor" (o que não é o modelo desejado — a gestão é por pessoa, não por setor).

**Alternatives considered**: Flag `podeGerir` dentro de `TramitacaoProtocoloSetor` — rejeitada porque gestão é concedida a **usuários** específicos (inclusive potencialmente um usuário fora dos setores incluídos, ex. o autor antes de qualquer setor existir), não ao setor como um todo.

## 4. Tipo "pessoal" (1:1) — modelagem

**Decision**: Manter como campos diretos em `TramitacaoProtocolo` (sem tabela associativa): `tipo: pessoal`, `autorUserId`, `targetUserId` (NOT NULL apenas quando `tipo = pessoal`). Não populam `TramitacaoProtocoloSetor`. Ambos os participantes (autor e destinatário) têm acesso de leitura/atualização; gestão (encerrar) segue a mesma regra do autor + `TramitacaoProtocoloGestor` (ex.: autor concede gestão ao destinatário se desejar, embora não seja o caso comum).

**Rationale**: Preserva a simplicidade do modelo pessoal já existente hoje (`targetUserId` em `TramitacaoDemanda`) e evita over-engineering (tabela associativa para um relacionamento estritamente 1:1 é redundante). Confirma a decisão do usuário ("tipo separado").

## 5. Linha do tempo (evento) — novos tipos e remoção do "encaminhado que move"

**Decision**: Novo enum `TramitacaoProtocoloEventoTipo`:

```
aberto
atualizacao
setor_incluido
gestao_concedida
vinculo_anexado
encerrado
desentranhamento_solicitado
desentranhamento_aprovado
desentranhamento_rejeitado
```

- `aberto` substitui `created` (evento inicial, subject/body/anexos iniciais).
- `atualizacao` substitui `reply` (qualquer nova mensagem/anexo adicionado por qualquer participante — não move nada).
- `forwarded` **é removido** — não existe mais "encaminhar que move de setor" (FR-005). É substituído por `setor_incluido` (inclusão, não substituição) e por `atualizacao` regular para conteúdo.
- `status_changed`/`archived` (do modelo antigo) são substituídos por `encerrado` (evento único de fechamento, dado que "arquivar" deixa de existir como conceito — vira "encerrar").
- `vinculo_anexado` é o evento de **entranhar dados de outro módulo em protocolo já existente** (US4), carregando `sourceModule/sourceRecordId/sourceSnapshot` no payload do evento (o protocolo pode ter múltiplos entranhamentos ao longo do tempo, diferente da vinculação única de origem na abertura).

**Rationale**: Elimina de raiz a semântica de "mensagem que trafega" (constatação central do usuário) e formaliza os eventos como uma linha do tempo de **atualizações cumulativas** sobre um contêiner estável.

**Alternatives considered**: Manter `forwarded` renomeado para representar apenas "setor incluído" — rejeitado por confundir o vocabulário (o termo "forward" carrega semântica de movimento que o produto quer eliminar).

## 6. Reconciliação com a feature 034 (Desentranhamento) — EM CURSO

**Contexto**: 034 está ~66% implementada (29/44 tasks) e define aprovadores via "contraparte atual" (`author_requests` → aprovador é quem está do lado receptor **atual** da demanda; `recipient_requests` → aprovador é o autor). Esse conceito de "lado receptor atual" **deixa de existir** no modelo de protocolo (não há mais um único setor atual — há N participantes simultâneos).

**Decision**: Reconciliar 034 como parte desta refatoração (não como pré-requisito bloqueante separado), redefinindo a direção:
- Se o **solicitante é o autor do anexo** → aprovadores = **todos os demais participantes** do protocolo (todos os membros de todos os setores incluídos, exceto o próprio autor; ou o outro usuário, no tipo pessoal).
- Se o **solicitante não é o autor** → aprovador = **o autor do anexo** (inalterado).
- Regra de "primeira decisão vale" (FR-009 da 034) é preservada e passa a operar sobre esse conjunto ampliado de aprovadores.

O enum `TramitacaoDesentranhamentoDirection` é renomeado para manter clareza (`autor_solicita` / `participante_solicita`) mas a **mecânica de aprovação única (primeira vale)** e todo o restante do comportamento (anexo nunca apagado, `desentranhadoAt`, histórico, ACL) é 100% preservado, conforme FR-021 da spec 035.

**Rationale**: A spec 035 exige explicitamente preservar 034 (FR-021), mas 034 foi desenhada sobre o conceito de "lado receptor atual" que este plano elimina. Adaptar a resolução de aprovadores para "qualquer outro participante" é a tradução mais direta do requisito original (034 FR-003: "usuários do lado receptor atual da demanda") para o novo modelo N-participantes, sem alterar o valor de negócio (dar à contraparte o poder de decidir sobre documento que não é seu).

**Alternatives considered**:
- *Concluir 034 primeiro no modelo antigo, depois migrar*: rejeitado — dado o reset total de dados e a reescrita do schema, seria trabalho duplicado (implementar testes de integração 034 pendentes sobre um modelo que será apagado dias depois).
- *Remover completamente o conceito de desentranhamento e reabrir como feature nova depois*: rejeitado — spec 035 FR-021 exige preservação explícita; o usuário já validou isso na fase de specify.

## 7. Notificações — novos tipos

**Decision**: Renomear/estender `NotificacaoType` (enum compartilhado em `notificacao.prisma`) substituindo os tipos ligados a "encaminhamento":

| Removido | Novo | Disparo |
|---|---|---|
| `tramitacao_nova_demanda` | `tramitacao_protocolo_setor_incluido` | Setor incluído no protocolo (abertura ou inclusão posterior) |
| `tramitacao_resposta` | `tramitacao_protocolo_atualizacao` | Nova atualização (mensagem/anexo) por qualquer participante |
| — | `tramitacao_protocolo_encerrado` | Protocolo encerrado |
| `tramitacao_pessoal_nova` | `tramitacao_protocolo_pessoal_aberto` | Protocolo pessoal aberto para o destinatário |
| `tramitacao_pessoal_resposta` | `tramitacao_protocolo_pessoal_atualizacao` | Nova atualização em protocolo pessoal |
| `tramitacao_pessoal_encaminhada` | *(removido)* | Não existe mais "encaminhar pessoal" |
| `tramitacao_desentranhamento_*` | *(inalterado)* | Preservado (034) |

**Rationale**: Mantém o canal in-app já existente (WebSocket + `Notificacao` table) e o padrão de `ResolveTramitacaoRecipientsService`/`TramitacaoNotificacaoService`, apenas alinhando os rótulos ao vocabulário de protocolo e removendo o que não tem mais equivalente (encaminhar pessoal).

## 8. Exportação (Baixar) — PDF + ZIP

**Decision**: Um único artefato **ZIP** contendo:
- `dossie.pdf` — gerado com `pdf-lib` (já é dependência de `ci-api-v2`, usado em `it-fiscalizacao/lib/anpd-pdf-template.ts`), com cabeçalho do protocolo, participantes e linha do tempo de atualizações.
- pasta `anexos/` — os arquivos originais aos quais o solicitante tem acesso (`resolveAnexoAccessLevel === 'full'`), nomeados de forma legível (`{ordem}-{fileName}`).

Novo caso de uso `ExportProtocoloUseCase`: monta o PDF, busca os anexos elegíveis via `StorageService` (novo método `getObjectBuffer` — `GetObjectCommand` retornando `Buffer`, análogo ao `getObjectText` já existente), empacota tudo em memória com **JSZip** (nova dependência, `ci-api-v2/package.json`), sobe o ZIP final via `storage.putObject` e retorna uma URL de download presignada (`storage.presignDownload`), seguindo exatamente o padrão já usado por `GenerateAnpdNotificationUseCase`.

**Rationale**: Reaproveita 100% do padrão de storage já existente (presign/putObject) e a única dependência nova (`jszip`) é leve, pura-JS, e resolve a montagem do ZIP em memória sem precisar de streaming complexo — adequado ao volume esperado (protocolos administrativos, não terabytes de anexos). Empacotar PDF+anexos em **um único ZIP** (em vez de dois downloads separados) simplifica a UX do botão "Baixar" para uma única ação/arquivo, sem contradizer a spec (que descreve o resultado, não a embalagem exata — este detalhe fica explicitamente deferido ao planejamento nas Assumptions da spec).

**Alternatives considered**:
- *Dois arquivos separados (PDF direto + ZIP separado)*: rejeitado — pior UX (dois cliques/downloads) sem ganho técnico.
- *`archiver` (streaming)*: rejeitado para v1 — exige lidar com streams no meio de uma requisição HTTP síncrona; `jszip` (buffer-based) é suficiente e mais simples dado o volume esperado (protocolos administrativos internos, não datasets massivos). Se o volume real dos anexos exceder um limite razoável (definido em `research.md` → guard de tamanho, ex. soma > 200MB), a v1 retorna erro 422 orientando contato com suporte, em vez de tentar otimizar prematuramente.

## 9. Guard de tamanho da exportação

**Decision**: Antes de montar o ZIP, somar `sizeBytes` de todos os anexos elegíveis; se o total exceder **200MB**, retornar `422 EXPORT_TOO_LARGE` com mensagem orientando a exportar anexos individualmente pela listagem em vez de usar "Baixar tudo". Sem paginação/streaming nesta versão.

**Rationale**: Guard simples e barato de implementar que evita degradação do processo Node em memória; 200MB é uma margem confortável para o volume de anexos administrativos observado no domínio (documentos PDF/imagens, não vídeos). Documentado como constraint técnica em vez de deixar o comportamento indefinido.

## 10. Ordenação da lista "Meus protocolos" e `updatedAt`

**Decision**: Reaproveitar o campo `updatedAt` (`@updatedAt` do Prisma) de `TramitacaoProtocolo` como "data da última atualização" — todo `use-case` que grava um evento (`atualizacao`, `setor_incluido`, `vinculo_anexado`, `encerrado`, eventos de desentranhamento) DEVE tocar o protocolo pai (`prisma.tramitacaoProtocolo.update({ where: { id }, data: {} })` ou incluir no mesmo `$transaction`) para que o Prisma atualize `updatedAt` automaticamente. A listagem ordena por `updatedAt DESC`.

**Rationale**: Reaproveita mecanismo nativo do Prisma já usado no restante do monorepo, sem precisar de um campo denormalizado adicional (`lastActivityAt`) ou trigger SQL — simples e correto o suficiente para o volume esperado (SC-003 exige refletir em "segundos", o que uma query `ORDER BY updatedAt DESC` atende trivialmente).

## 11. Licenciamento e navegação (client)

**Decision**: Sem mudança de licença — a Tramitação continua licença **Base** (`Base` na tabela de licenças canônicas), mesmas rotas (`/tramitacao/dashboard`, `/tramitacao/demandas`→ renomear para `/tramitacao/protocolos` e `/tramitacao/protocolos/:id`, `/tramitacao/protocolos/novo`). O termo de rota muda de `demandas` para `protocolos` para consistência com o novo vocabulário, mas a estrutura de `screens.ts`/overrides permanece a mesma.

**Rationale**: Rotas amigáveis alinhadas ao vocabulário de produto ajudam a reforçar a mudança de paradigma na UI (URL, breadcrumbs, títulos) sem alterar a arquitetura de licenciamento existente.

## 12. Reaproveitamento de UI existente vs. reescrita

**Decision**: Como o usuário pediu para "revisitar todo o modal/tela usando ui-ux-pro-max" em conversas anteriores e esta é uma refatoração de paradigma (não incremental), o plano assume **reescrita completa dos componentes de UI do módulo** (`TramitacaoInboxWorkspace`, `TramitacaoComposeForm/Screen`, `TramitacaoActionModal`, `TramitacaoConversationThread`, `TramitacaoEncaminhamentosPanel`) sob os novos nomes/conceitos (Protocolo, Participantes, Atualizações, Encerrar, Baixar), em vez de tentar adaptar incrementalmente componentes cujo modelo mental (inbox de mensagens) não existe mais. Reaproveita-se: `TramitacaoAnexoUploadZone`, `ConfidentialAccessPicker/Panel`, `TramitacaoAnexoList` (compatíveis após rename de props/tipos), hooks de setor (`useTramitacaoSectorId`), tema (`tramitacao-theme.ts`).

**Rationale**: Tentar "consertar" telas que modelam encaminhamento/pastas de e-mail para um paradigma de processo geraria código confuso e nomes desalinhados com o domínio (violaria linguagem ubíqua). Componentes puramente mecânicos (upload, ACL confidencial, tema) são independentes do paradigma e continuam válidos.

## 13. Skills a aplicar na implementação

- `nestjs-module-scaffold` + `ci-api-arquitetura` — reestruturação de use-cases/repository por domínio.
- `prisma-schema-workflow` — migration de reset.
- `tdd` + `testing-conventions` — TDD obrigatório (Constitution II).
- `zod-validation-sanitization` — novos schemas (`tramitacao.schemas.ts`).
- `ui-ux-pro-max` — reescrita das telas/modais do client (conforme pedido explícito do usuário em conversa anterior).
- `vite-react-best-practices` — rotas lazy, performance da lista "Meus protocolos".
- `auth-patterns` — `resolveUserTableId`/`withActorPayload` em todos os novos campos FK para `User`.
