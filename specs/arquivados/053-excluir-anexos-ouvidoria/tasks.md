# Tasks: Excluir Anexos de Manifestação (Ouvidoria)

**Input**: Design documents from `civ2-docs/specs/053-excluir-anexos-ouvidoria/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/delete-manifestacao-anexo.md, security.md, quickstart.md

**Tests**: TDD obrigatório (Constitution II — RED → GREEN → REFACTOR). Cada tarefa de teste deve falhar antes da implementação correspondente. Skills: `tdd`, `testing-conventions` (API, Jest), Vitest no client.

**Organization**: Tasks grouped by user story. US2–US5 estendem o mesmo use-case; não são entregas paralelas de arquivos novos.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks)
- **[Story]**: Which user story this task belongs to (US1–US5)
- Include exact file paths in descriptions

## Path Conventions

- **API**: `ci-api-v2/src/modules/ouvidoria/` e `ci-api-v2/src/modules/shared/storage/`
- **Client**: `ci-client-v2/apps/web/src/modules/ouvidoria/`
- **Schema**: `ci-api-v2/prisma/schema/`

---

## Phase 1: Setup (Schema)

**Purpose**: Tombstone e evento no banco, sem lógica ainda

- [x] T001 Adicionar em `ManifestacaoAnexo` os campos `deletedAt DateTime?`, `deletedByUserId String?`, `deletedByActorId String?`, `deletedByActorRole UserRole?`, a relação nomeada `deletedBy` (`"ManifestacaoAnexoDeletedBy"`, `onDelete: SetNull`), renomear a relação de upload para `"ManifestacaoAnexoUploadedBy"` e o índice `@@index([manifestacaoId, deletedAt])` em `ci-api-v2/prisma/schema/manifestacao.prisma`; acrescentar `attachment_deleted` ao enum `ManifestacaoEventoTipo` no mesmo arquivo
- [x] T002 Atualizar as relações inversas em `ci-api-v2/prisma/schema/user.prisma`: `manifestacaoAnexos` aponta para `"ManifestacaoAnexoUploadedBy"` e nova `manifestacaoAnexosExcluidos` aponta para `"ManifestacaoAnexoDeletedBy"`
- [x] T003 Criar `ci-api-v2/prisma/migrations/20261008120000_manifestacao_anexo_tombstone/migration.sql` com as colunas, a FK `deletedByUserId` `ON DELETE SET NULL`, o índice e o `CHECK ("deletedAt" IS NULL OR ("storageKey" IS NULL AND "externalUrl" IS NULL))` conforme `data-model.md`
- [x] T004 Criar `ci-api-v2/prisma/migrations/20261008120100_manifestacao_evento_attachment_deleted/migration.sql` só com `ALTER TYPE "ManifestacaoEventoTipo" ADD VALUE 'attachment_deleted'` (migration separada, padrão `20260924160000_manifestacao_closed_meio_juridico`)
- [x] T005 Rodar `npx prisma generate` em `ci-api-v2/` e `npm run prisma:validate`

**Checkpoint**: Schema gera client sem erro; nenhuma rota nova ainda

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Peças compartilhadas por todas as histórias. Nenhuma user story começa antes disto.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T006 [P] Escrever teste RED de `canDeleteAnexos` em `ci-api-v2/src/modules/ouvidoria/lib/manifestacao-anexo-delete-policy.spec.ts`: `draft`, `in_review`, `forwarding`, `answered` → true; `closed`, `closed_unresolved`, `closed_meio_juridico` → false
- [x] T007 Implementar `canDeleteAnexos(status)` em `ci-api-v2/src/modules/ouvidoria/lib/manifestacao-anexo-delete-policy.ts` reutilizando `isManifestacaoEncerrada` de `ci-api-v2/src/modules/ouvidoria/lib/manifestacao-desfecho.ts` até T006 passar
- [x] T008 [P] Escrever teste RED de exclusão permanente em `ci-api-v2/src/modules/shared/storage/storage.service.delete-permanently.spec.ts`: chave exata (não prefixo), versões + delete markers, bucket sem `VersionId`, `HeadObject` ainda existente → erro, `AccessDenied` → erro, chave de outro tenant → recusa, chave vazia/`..` → recusa, modo stub apaga o arquivo local
- [x] T009 Acrescentar `deleteObjectPermanently(storageKey)` em `ci-api-v2/src/modules/shared/storage/storage.port.ts` e implementar em `ci-api-v2/src/modules/shared/storage/storage.service.ts` (`validateTenantPath`, `ListObjectVersions` filtrado por `Key === storageKey`, `DeleteObject` com `VersionId`, `HeadObject` deve dar `NotFound`; stub usa `deleteLocalObject`). Não alterar `deleteObject`. Até T008 passar
- [x] T010 [P] Acrescentar `ANEXO_DELETE_CLOSED`, `ANEXO_DELETE_BLOCKED` e `ANEXO_DELETE_FAILED` em `OUVIDORIA_ERROR` e as mensagens em PT-BR de `contracts/delete-manifestacao-anexo.md` em `ci-api-v2/src/modules/ouvidoria/lib/ouvidoria-errors.ts`
- [x] T011 [P] Escrever teste RED em `ci-api-v2/src/modules/ouvidoria/test/repository/find-manifestacao-for-anexo-delete.repository.spec.ts`: o `where` contém `id`, `tenantId` do contexto e `deletedAt: null`; manifestação de outro tenant ou removida não retorna
- [x] T012 [P] Escrever teste RED em `ci-api-v2/src/modules/ouvidoria/test/repository/tombstone-manifestacao-anexo.repository.spec.ts`: `updateMany` filtra `id` + `manifestacaoId` + `tenantId` + `deletedAt: null`, zera `storageKey` e `externalUrl`, grava autor; evento `attachment_deleted` só quando `count === 1`; `count === 0` não cria evento
- [x] T013 Implementar `FindManifestacaoForAnexoDeleteRepository` em `ci-api-v2/src/modules/ouvidoria/repository/find-manifestacao-for-anexo-delete.repository.ts` até T011 passar. Usar `this.prisma` (client base) com `tenantId` e `deletedAt` explícitos — não reutilizar `RequireManifestacaoRepository`
- [x] T014 [P] Implementar `FindManifestacaoAnexoIncludingDeletedRepository` em `ci-api-v2/src/modules/ouvidoria/repository/find-manifestacao-anexo-including-deleted.repository.ts` com `where: { id, manifestacaoId, tenantId }`
- [x] T015 [P] Implementar `CountAnexosSharingStorageKeyRepository` em `ci-api-v2/src/modules/ouvidoria/repository/count-anexos-sharing-storage-key.repository.ts` (`tenantId`, `storageKey`, `deletedAt: null`, `id` diferente)
- [x] T016 Implementar `TombstoneManifestacaoAnexoRepository` em `ci-api-v2/src/modules/ouvidoria/repository/tombstone-manifestacao-anexo.repository.ts` (`$transaction`: `updateMany` + evento só se `count === 1`, `titulo` constante `Anexo excluído`, `autorUserId` opcional) até T012 passar
- [x] T017 [P] Implementar `ResolveAnexoActorLabelRepository` em `ci-api-v2/src/modules/ouvidoria/repository/resolve-anexo-actor-label.repository.ts`: `admin_tenant` → `AdminTenant.name ?? email` filtrando `{ id, tenantId }`; `admin_saas` → `Administrador da plataforma`; papel de `User` → `null` (o nome vem do FK)
- [x] T018 Em `FindManifestacaoByIdRepository` de `ci-api-v2/src/modules/ouvidoria/repository/manifestacao.repositories.ts`, trocar `anexos: true` por `anexos: { where: { deletedAt: null } }`; em `FindManifestacaoAnexoRepository`, incluir `deletedAt: null` no `where`
- [x] T019 [P] Estender `ci-api-v2/src/modules/ouvidoria/lib/map-manifestacao-anexos.spec.ts` com RED: anexo `file` ou `link` com `deletedAt` preenchido não aparece em `mapManifestacaoAnexos`
- [x] T020 Fazer `isVisibleManifestacaoAnexo` rejeitar `deletedAt` em `ci-api-v2/src/modules/ouvidoria/lib/map-manifestacao-anexos.ts` até T019 passar
- [x] T021 [P] Adicionar `DeleteManifestacaoAnexoParams` (Zod: `id` e `anexoId` `trim`, 1–64 caracteres, sem `z.uuid()`) em `ci-api-v2/src/modules/ouvidoria/ouvidoria.schemas.ts`

**Checkpoint**: Policy, storage, repos e filtro de leitura testados. Use-case ainda não existe.

---

## Phase 3: User Story 1 — Excluir um arquivo anexado com segurança (Priority: P1) 🎯 MVP

**Goal**: Usuário com acesso exclui um arquivo de manifestação aberta, confirma na tela, o arquivo some do Wasabi e a linha do tempo registra o evento.

**Independent Test**: Manifestação `in_review` com um arquivo → Excluir → Confirmar → item some, evento "Anexo excluído" aparece, objeto inexistente no storage (quickstart cenário 1). Cancelar não chama a API (cenário 2).

### Tests for User Story 1 ⚠️

- [x] T022 [P] [US1] Escrever teste RED em `ci-api-v2/src/modules/ouvidoria/test/use-cases/delete-manifestacao-anexo.use-case.spec.ts` para o caminho feliz de `kind=file`: `deleteObjectPermanently` é chamado **antes** do tombstone, resposta `{ ok: true, alreadyDeleted: false }`, evento criado uma vez; usuário sem acesso recebe 403 e storage/tombstone não são chamados; anexo inexistente → 404 `OUVIDORIA_ANEXO_NOT_FOUND`; upload nunca confirmado / objeto ausente no storage → sucesso

### Implementation for User Story 1

- [x] T023 [US1] Implementar `DeleteManifestacaoAnexoUseCase` em `ci-api-v2/src/modules/ouvidoria/use-cases/delete-manifestacao-anexo.use-case.ts` com a ordem de `plan.md` (manifestação → acesso → anexo → status → chave compartilhada → storage → tombstone) cobrindo o caminho de arquivo de T022. Log Pino `anexo.deleted` / `anexo.delete_failed` com ids, ator e papel, **sem** nome do arquivo
- [x] T024 [US1] Registrar o use-case e os repositories novos em `ci-api-v2/src/modules/ouvidoria/ouvidoria.module.ts` e expor `DELETE manifestacoes/:id/anexos/:anexoId` com `@RequireModulo('ouvidoria')`, `@Throttle` (20/min) e `DeleteManifestacaoAnexoParams` em `ci-api-v2/src/modules/ouvidoria/ouvidoria.controller.ts`
- [x] T025 [P] [US1] Devolver `anexosExcluiveis: canDeleteAnexos(status)` em `ci-api-v2/src/modules/ouvidoria/use-cases/get-manifestacao-detail.use-case.ts` e `ci-api-v2/src/modules/ouvidoria/use-cases/get-manifestacao-revisao.use-case.ts`
- [x] T026 [P] [US1] Escrever teste RED em `ci-client-v2/apps/web/src/modules/ouvidoria/lib/__tests__/manifestacao-detail-view.anexos.test.ts`: `anexosExcluiveis` ausente ou não booleano vira `false`; `true`/`false` explícitos são respeitados
- [x] T027 [US1] Mapear `anexosExcluiveis` em `ManifestacaoDetailView` de `ci-client-v2/apps/web/src/modules/ouvidoria/lib/manifestacao-detail-view.ts` até T026 passar
- [x] T028 [P] [US1] Adicionar `deleteManifestacaoAnexo` e fazer `presignAnexo` / `addLinkAnexo` devolverem o `anexoId` real em `ci-client-v2/apps/web/src/modules/ouvidoria/api/anexos.ts`; cobrir com teste em `ci-client-v2/apps/web/src/modules/ouvidoria/__tests__/anexos-api.delete.test.ts`
- [x] T029 [P] [US1] Escrever testes RED de `ConfirmDeleteAnexoDialog` e `ManifestacaoAnexoItem` em `ci-client-v2/apps/web/src/modules/ouvidoria/__tests__/ConfirmDeleteAnexoDialog.test.tsx` e `ci-client-v2/apps/web/src/modules/ouvidoria/__tests__/ManifestacaoAnexoItem.test.tsx`: botão só com `anexosExcluiveis`; Cancelar, Esc e clique fora não chamam a API; confirmar chama uma vez; rótulo do botão inclui o nome do arquivo; foco inicial em Cancelar
- [x] T030 [US1] Implementar `ci-client-v2/apps/web/src/modules/ouvidoria/components/ConfirmDeleteAnexoDialog.tsx` (Dialog de `@ci/ui`, aviso de irreversibilidade) e `ci-client-v2/apps/web/src/modules/ouvidoria/components/ManifestacaoAnexoItem.tsx` até T029 passar
- [x] T031 [US1] Usar `ManifestacaoAnexoItem` no card Anexos de `ci-client-v2/apps/web/src/modules/ouvidoria/pages/ManifestacaoDetailPage.tsx`, recarregando o detalhe após sucesso
- [x] T032 [US1] Usar o id real retornado por presign/link em `ci-client-v2/apps/web/src/modules/ouvidoria/components/AnexoUploadZone.tsx` e o mesmo item (com exclusão) em `RevisaoAnexos` de `ci-client-v2/apps/web/src/modules/ouvidoria/pages/ManifestacaoWizardPage.tsx`, sem descartar os dados do rascunho em edição

**Checkpoint**: Arquivo de manifestação aberta é excluído pela tela de detalhe e pelo assistente (quickstart 1, 2, 9, 10)

---

## Phase 4: User Story 2 — Proteger encerradas e o isolamento entre instituições (Priority: P1)

**Goal**: Encerrada não exclui; anexo de outra manifestação ou instituição responde "não encontrado" e nada é apagado.

**Independent Test**: quickstart cenários 3 e 4 — botão ausente na encerrada; `DELETE` direto devolve 409/404 e o storage não é chamado.

### Tests for User Story 2 ⚠️

- [x] T033 [P] [US2] Acrescentar casos RED no spec de T022 (`delete-manifestacao-anexo.use-case.spec.ts`): status encerrado (`closed`, `closed_unresolved`, `closed_meio_juridico`) → 409 `OUVIDORIA_ANEXO_DELETE_CLOSED` e storage não chamado; anexo de outra manifestação → 404; manifestação de outro `tenantId` ou com `deletedAt` → 404 `OUVIDORIA_NOT_FOUND`

### Implementation for User Story 2

- [x] T034 [US2] Implementar os ramos de status, tenant e manifestação removida em `ci-api-v2/src/modules/ouvidoria/use-cases/delete-manifestacao-anexo.use-case.ts` até T033 passar
- [x] T035 [P] [US2] Estender `ci-client-v2/apps/web/src/modules/ouvidoria/__tests__/ManifestacaoAnexoItem.test.tsx`: com `anexosExcluiveis=false` nenhum botão "Excluir" é renderizado (manifestação encerrada)

**Checkpoint**: Nenhum arquivo de manifestação encerrada ou de outro tenant é tocado (SC-003)

---

## Phase 5: User Story 3 — Falhas e repetições não deixam estado inconsistente (Priority: P1)

**Goal**: Falha do Wasabi mantém o anexo ativo; repetir a exclusão não duplica evento; chave compartilhada bloqueia.

**Independent Test**: quickstart cenários 5 e 6 — erro visível, item permanece, segunda chamada `alreadyDeleted: true` com um único evento.

### Tests for User Story 3 ⚠️

- [x] T036 [P] [US3] Acrescentar casos RED no spec de T022: storage lança → sem tombstone e sem evento, erro `OUVIDORIA_ANEXO_DELETE_FAILED`; chave que não começa com `<tenantId>/` → mesmo erro, sem apagar; outro anexo ativo com a mesma `storageKey` → 409 `OUVIDORIA_ANEXO_DELETE_BLOCKED` e storage não chamado; anexo já excluído → `{ alreadyDeleted: true }` sem storage e sem evento; `updateMany` com `count === 0` não cria segundo evento
- [x] T037 [P] [US3] Escrever teste RED em `ci-client-v2/apps/web/src/modules/ouvidoria/__tests__/ManifestacaoAnexoItem.test.tsx`: durante a requisição o botão fica desabilitado; erro da API mantém o item e mostra alerta; sucesso remove o item

### Implementation for User Story 3

- [x] T038 [US3] Implementar os ramos de falha, chave compartilhada e idempotência em `ci-api-v2/src/modules/ouvidoria/use-cases/delete-manifestacao-anexo.use-case.ts` até T036 passar, e o `warn` quando o status lido de novo na transação estiver encerrado (risco R-1 de `security.md`)
- [x] T039 [US3] Tratar pendência, erro e sucesso em `ci-client-v2/apps/web/src/modules/ouvidoria/components/ManifestacaoAnexoItem.tsx` e `ConfirmDeleteAnexoDialog.tsx` até T037 passar
- [x] T040 [P] [US3] Mapear `OUVIDORIA_ANEXO_DELETE_CLOSED`, `OUVIDORIA_ANEXO_DELETE_BLOCKED` e `OUVIDORIA_ANEXO_DELETE_FAILED` (server, `retryable: true`, HTTP 500) em `CODE_SPECS` de `ci-client-v2/apps/web/src/modules/ouvidoria/api/errors.ts` e cobrir em `ci-client-v2/apps/web/src/modules/ouvidoria/__tests__/ouvidoria-errors.test.ts`

**Checkpoint**: SC-004 e SC-006 verificáveis pelos testes do use-case

---

## Phase 6: User Story 4 — Excluir anexo do tipo link externo (Priority: P2)

**Goal**: Link sai da lista com o mesmo diálogo e o mesmo evento, sem chamada ao armazenamento.

**Independent Test**: quickstart cenário 7 — storage não é chamado; evento existe; URL não permanece no registro.

### Tests for User Story 4 ⚠️

- [x] T041 [P] [US4] Acrescentar caso RED no spec de T022: `kind=link` confirma exclusão, `deleteObjectPermanently` **não** é chamado, tombstone zera `externalUrl` e o evento é criado; link em manifestação encerrada continua 409

### Implementation for User Story 4

- [x] T042 [US4] Implementar o ramo `kind=link` (pular storage e a checagem de chave compartilhada) em `ci-api-v2/src/modules/ouvidoria/use-cases/delete-manifestacao-anexo.use-case.ts` até T041 passar
- [x] T043 [P] [US4] Ajustar o rótulo do diálogo para "Remover link" quando `kind=link` e "Excluir arquivo" quando `kind=file` em `ci-client-v2/apps/web/src/modules/ouvidoria/components/ConfirmDeleteAnexoDialog.tsx`, com o caso no teste de T029

**Checkpoint**: Link e arquivo compartilham a rota e divergem só na chamada ao storage

---

## Phase 7: User Story 5 — Rastreabilidade (Priority: P2)

**Goal**: Quem excluiu (inclusive admin da instituição) fica identificável; o cidadão na consulta pública não vê o evento; exportações não embutem o arquivo excluído.

**Independent Test**: quickstart cenários 8, 11 e 12 — evento com "Por &lt;admin&gt;"; PDF/DOCX sem o anexo; `marcos` da consulta pública sem "Anexo excluído".

### Tests for User Story 5 ⚠️

- [x] T044 [P] [US5] Acrescentar caso RED no spec de T022: ator `admin_tenant` grava `deletedByUserId` ausente, `deletedByActorId` + `deletedByActorRole`, e a `descricao` do evento contém `Por <rótulo>`; ator `user` usa `autorUserId` e não duplica o nome na descrição
- [x] T045 [P] [US5] Escrever teste RED em `ci-api-v2/src/modules/ouvidoria/test/use-cases/consulta-publica.use-case.spec.ts` (criar o arquivo se não existir, no padrão dos specs vizinhos): `marcos` omite evento `tipo=attachment_deleted` e mantém os demais
- [x] T046 [P] [US5] Estender `ci-api-v2/src/modules/ouvidoria/lib/compose-manifestacao-export-anexos.spec.ts` e `ci-api-v2/src/modules/ouvidoria/lib/map-manifestacao-anexos.spec.ts` para garantir que anexo excluído (file e link) não entra na exportação nem no DTO

### Implementation for User Story 5

- [x] T047 [US5] Ligar `ResolveAnexoActorLabelRepository` na montagem da `descricao` dentro de `ci-api-v2/src/modules/ouvidoria/use-cases/delete-manifestacao-anexo.use-case.ts` (nome do arquivo só na `descricao`, nunca no `titulo`) até T044 passar
- [x] T048 [US5] Filtrar `tipo !== attachment_deleted` ao montar `marcos` em `ci-api-v2/src/modules/ouvidoria/use-cases/consulta-publica.use-case.ts` até T045 passar
- [x] T049 [US5] Confirmar que PDF/DOCX e o documento usam `row.anexos` já filtrado por T018; se algum caminho ler anexos sem `deletedAt: null`, aplicar o mesmo filtro em `ci-api-v2/src/modules/ouvidoria/use-cases/generate-manifestacao-pdf.use-case.ts` e `generate-manifestacao-docx.use-case.ts` até T046 passar

**Checkpoint**: SC-005 e SC-007 cobertos; consulta pública não vaza o nome do arquivo

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Fechar a verificação da spec e os pré-requisitos operacionais

- [x] T050 [P] Atualizar `ci-api-v2/src/modules/ouvidoria/test/use-cases/get-manifestacao-detail.use-case.spec.ts` para o campo `anexosExcluiveis` e para anexo excluído ausente da lista
- [x] T051 Rodar a suíte de `quickstart.md` §2 (`npm test` com os padrões indicados na API e no client) e `npm run lint` + `npm run build` em `ci-api-v2/` — testes e build OK (2026-10-08); `npm run lint` falha por ~1113 erros **pré-existentes** no repo (fora do escopo 053)
- [x] T052 Executar os cenários manuais 1–13 de `civ2-docs/specs/053-excluir-anexos-ouvidoria/quickstart.md` no stub local e registrar o que não pôde ser exercido — ver `VALIDATION.md`
- [x] T053 Executar o checklist operacional de `quickstart.md` §0 (versionamento do bucket, Object Lock, permissões da credencial, SQL de chaves fora de `<tenantId>/` e de chaves duplicadas) em homologação e anotar o resultado antes de considerar a feature concluída — requisito da spec (SC-002) — ver `ops-checklist-result.md` (Wasabi pendente homolog; SQL dev registrado)
- [x] T054 Marcar o item de teste cross-tenant em `civ2-docs/specs/053-excluir-anexos-ouvidoria/security.md` depois que T033 e T011 estiverem verdes

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: sem dependências
- **Foundational (Phase 2)**: depende de T005 — bloqueia todas as histórias
- **US1 (Phase 3)**: depende da Phase 2
- **US2 (Phase 4)**: depende de T023 (o use-case existe)
- **US3 (Phase 5)**: depende de T023; independente de US2 no arquivo de teste, mas toca o mesmo use-case — fazer em sequência
- **US4 (Phase 6)**: depende de T023
- **US5 (Phase 7)**: depende de T016, T017 e T018
- **Polish (Phase 8)**: depende das histórias desejadas; T053 é gate de produção, não de código

### User Story Dependencies

- **US1 (P1)**: primeira história; entrega o caminho feliz de arquivo + UI
- **US2 (P1)**: estende o mesmo use-case; testável só com a rota de US1
- **US3 (P1)**: estende o mesmo use-case; não depende de US4/US5
- **US4 (P2)**: ramo de link no use-case de US1; UI reusa o diálogo de US1
- **US5 (P2)**: rótulo de admin, filtro da consulta pública e exportação; não muda a rota

### Within Each User Story

- Testes RED antes da implementação da mesma história
- Repositories antes do use-case (Phase 2 antes da Phase 3)
- Use-case antes da rota (T023 antes de T024)
- Componente antes das páginas (T030 antes de T031/T032)

### Parallel Opportunities

- T006, T008, T010, T011, T012, T019 e T021 (testes e erros, arquivos distintos) após T005
- T014, T015 e T017 (repositories distintos) após T005
- T025, T026 e T028 após T023/T024
- T033, T036, T041, T044, T045 e T046 são o mesmo arquivo de use-case ou specs diferentes: T045 e T046 são [P] entre si; os acréscimos no spec do use-case (T033, T036, T041, T044) são sequenciais

---

## Parallel Example: Foundational

```text
# Após T005, em paralelo (arquivos diferentes):
T006 policy spec
T008 storage spec
T010 error codes
T011 find-manifestacao spec
T012 tombstone spec
T021 Zod params
```

## Parallel Example: User Story 1 (depois de T024)

```text
T025 anexosExcluiveis na API (detail + revisão)
T026 teste do view model
T028 cliente HTTP deleteManifestacaoAnexo
T029 testes do diálogo
```

---

## Implementation Strategy

### MVP First (User Story 1)

1. Phase 1 e Phase 2
2. Phase 3 (US1)
3. Parar e validar quickstart cenários 1, 2, 9 e 10 no stub

### Antes de expor em homologação com Wasabi real

US1 sozinha deixa de fora os bloqueios de encerrada, tenant e falha (US2 e US3, ambas P1). Não publicar o botão sem Phase 4 e Phase 5. US4 e US5 entram em seguida. T053 (versionamento / Object Lock / chaves legadas) é obrigatório para marcar a feature concluída.

### Incremental Delivery

1. Setup + Foundational → peças testadas, sem rota
2. US1 → excluir arquivo pela tela
3. US2 + US3 → seguro para dados reais
4. US4 → links
5. US5 → auditoria visível e consulta pública limpa

---

## Notes

- [P] = arquivos diferentes, sem depender de tarefa incompleta
- US2, US3, US4 e US5 alteram `delete-manifestacao-anexo.use-case.ts`: não paralelizar essas implementações
- Repositories novos não usam `prisma.db` nem `RequireManifestacaoRepository` (achado F1 de `security.md`)
- Não usar `StorageService.deleteObject` nesta feature
- Commit por fase ou por história, só quando pedido
