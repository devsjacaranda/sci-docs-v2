---
description: "Task list for Documentos confidenciais na Tramitação (033-tramitacao-docs-confidenciais)"
---

# Tasks: Documentos confidenciais na Tramitação

**Input**: Design documents from `civ2-docs/specs/033-tramitacao-docs-confidenciais/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Tests**: **Obrigatórios** — TDD (constitution II + plan.md + `contracts/test-strategy.md`): unitário, integração API e Vitest/RTL client. **1 migration** Prisma; Postgres dev via seed Jacaranda.

**Organization**: 7 user stories (US1–US7). Caminhos relativos à raiz `ci-v2/`.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Pode executar em paralelo (arquivos diferentes, sem dependências pendentes)
- **[Story]**: User story da spec (US1–US7)

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Verificar dependências existentes e preparar estrutura de anexos

- [X] T001 Verificar `StorageModule` importado em `ci-api-v2/src/modules/tramitacao/tramitacao.module.ts` (adicionar se ausente)
- [X] T002 [P] Criar `ci-api-v2/src/modules/tramitacao/tramitacao-anexo.constants.ts` reexportando `MAX_ANEXO_BYTES` e `isAllowedMime` de `ci-api-v2/src/modules/ouvidoria/ouvidoria-anexo.constants.ts`
- [X] T003 [P] Confirmar referências gabinete/ouvidoria: `ci-api-v2/src/modules/gabinete/use-cases/demanda-anexo.use-case.ts` e `ci-client-v2/apps/web/src/modules/ouvidoria/components/AnexoUploadZone.tsx`
- [X] T004 [P] Confirmar diretórios client: `ci-client-v2/apps/web/src/modules/tramitacao/api/`, `components/`, `lib/`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Migration Prisma + repositórios base + schemas Zod anexo — **bloqueia US1–US7**

**⚠️ CRITICAL**: Nenhuma user story começa antes desta fase

### Schema & migration

- [X] T005 Adicionar `uploadConfirmed`, `uploadedByUserId`, `isConfidential` e relação `accessGrants` em `TramitacaoDemandaAnexo` conforme `data-model.md` em `ci-api-v2/prisma/schema/tramitacao.prisma`
- [X] T006 Criar model `TramitacaoDemandaAnexoAccess` com `@@unique([anexoId, userId])` e índices em `ci-api-v2/prisma/schema/tramitacao.prisma`
- [X] T007 Gerar e aplicar migration em `ci-api-v2/prisma/migrations/` (`npx prisma migrate dev`)

### Repositories & module

- [X] T008 [P] Implementar `ci-api-v2/src/modules/tramitacao/repository/anexo.repositories.ts` — `CreateAnexoRepository`, `RequireAnexoRepository`, `ConfirmAnexoRepository`, `CreateAnexoAccessRepository`, `ListAnexoAccessRepository`
- [X] T009 Estender `GetDemandaByIdRepository` para incluir `eventos.anexos` e `accessGrants` em `ci-api-v2/src/modules/tramitacao/repository/demanda.repositories.ts`
- [X] T010 Adicionar schemas Zod base `presignAnexoBodySchema`, `confirmAnexoBodySchema`, `addLinkAnexoBodySchema` (sem ACL ainda) em `ci-api-v2/src/modules/tramitacao/tramitacao.schemas.ts`
- [X] T011 Registrar providers anexo use cases (stubs) e `StorageService` em `ci-api-v2/src/modules/tramitacao/tramitacao.module.ts`

**Checkpoint**: Schema migrado; repos e schemas base prontos; módulo compila

---

## Phase 3: User Story 1 — Anexar documentos na tramitação (Priority: P1) 🎯 MVP

**Goal**: Upload arquivo (presign/confirm) e link em criar/responder/encaminhar; anexos na timeline por evento

**Independent Test**: Quickstart Cenário 1 — PDF público na criação; B e B2 baixam; CT-DC-001, CT-DC-002, CT-DC-005

### Tests for User Story 1 (TDD — RED first)

- [X] T012 [P] [US1] Escrever testes (RED) unit presign limites em `ci-api-v2/src/modules/tramitacao/test/use-cases/presign-anexo.use-case.spec.ts` — CT-DC-003, CT-DC-004
- [X] T013 [P] [US1] Escrever testes (RED) integração upload em `ci-api-v2/src/modules/tramitacao/test/anexo-upload.integration.spec.ts` — CT-DC-001, CT-DC-002, CT-DC-005

### Implementation for User Story 1 — API

- [X] T014 [US1] Implementar `PresignAnexoUseCase` em `ci-api-v2/src/modules/tramitacao/use-cases/presign-anexo.use-case.ts` (GREEN T012, T013)
- [X] T015 [US1] Implementar `ConfirmAnexoUseCase` (público, `isConfidential=false`) em `ci-api-v2/src/modules/tramitacao/use-cases/confirm-anexo.use-case.ts` (GREEN T013)
- [X] T016 [US1] Implementar `AddLinkAnexoUseCase` em `ci-api-v2/src/modules/tramitacao/use-cases/add-link-anexo.use-case.ts` (GREEN T013)
- [X] T017 [US1] Expor rotas `POST .../anexos/presign`, `POST .../anexos/:anexoId/confirm`, `POST .../anexos/link` em `ci-api-v2/src/modules/tramitacao/tramitacao.controller.ts`
- [X] T018 [US1] Estender `GetDemandaDetailUseCase` e `toDemandaDetail` com `evento.anexos[]` (todos `accessLevel=full` por ora) em `ci-api-v2/src/modules/tramitacao/use-cases/get-demanda-detail.use-case.ts` e `ci-api-v2/src/modules/tramitacao/tramitacao.mapper.ts` (GREEN T013)
- [X] T019 [US1] Retornar `eventId` em `reply-demanda.use-case.ts` e `forward-demanda.use-case.ts` para vincular `eventoId` no confirm
- [X] T020 [US1] Aplicar `resolveUserTableId` em presign/confirm para `uploadedByUserId` em `ci-api-v2/src/modules/tramitacao/use-cases/presign-anexo.use-case.ts`

### Implementation for User Story 1 — Client

- [X] T021 [P] [US1] Criar `ci-client-v2/apps/web/src/modules/tramitacao/api/anexos.ts` — `presignAnexo`, `confirmAnexo`, `addLinkAnexo`
- [X] T022 [P] [US1] Criar `ci-client-v2/apps/web/src/modules/tramitacao/lib/anexo-schemas.ts` — parse resposta anexo detail
- [X] T023 [US1] Criar `TramitacaoAnexoUploadZone.tsx` (upload arquivo + link, sem confidencial ainda) em `ci-client-v2/apps/web/src/modules/tramitacao/components/TramitacaoAnexoUploadZone.tsx`
- [X] T024 [US1] Criar `TramitacaoAnexoList.tsx` (lista full com download) em `ci-client-v2/apps/web/src/modules/tramitacao/components/TramitacaoAnexoList.tsx`
- [X] T025 [US1] Integrar upload zone em compose setorial e sheets reply/forward em `ci-client-v2/apps/web/src/modules/tramitacao/components/TramitacaoInboxWorkspace.tsx` — orquestração create → presign → confirm

**Checkpoint**: Anexo público end-to-end; timeline mostra anexos; CT-DC-001..005 GREEN

---

## Phase 4: User Story 2 — Marcar anexo como confidencial (Priority: P1)

**Goal**: Toggle confidencial por anexo; multi-setor; ≥1 usuário/setor; validação server

**Independent Test**: Quickstart Cenário 2 e 3 — ACL multi-setor persistida; envio bloqueado sem usuários; CT-DC-006..009

### Tests for User Story 2 (TDD — RED first)

- [X] T026 [P] [US2] Escrever testes (RED) Zod ACL em `ci-api-v2/src/modules/tramitacao/tramitacao.schemas.spec.ts` — CT-DC-U03
- [X] T027 [P] [US2] Escrever testes (RED) `validate-anexo-access.spec.ts` em `ci-api-v2/src/modules/tramitacao/lib/validate-anexo-access.spec.ts` — CT-DC-U04
- [X] T028 [P] [US2] Escrever testes (RED) ACL integração em `ci-api-v2/src/modules/tramitacao/test/anexo-confidential.integration.spec.ts` — CT-DC-006..009

### Implementation for User Story 2 — API

- [X] T029 [US2] Implementar `validateUsersBelongToSectors` em `ci-api-v2/src/modules/tramitacao/lib/validate-anexo-access.ts` (GREEN T027)
- [X] T030 [US2] Estender `confirmAnexoBodySchema` e `addLinkAnexoBodySchema` com `confidentialAccessSchema` (`access[]` obrigatório se `isConfidential`) em `ci-api-v2/src/modules/tramitacao/tramitacao.schemas.ts` (GREEN T026)
- [X] T031 [US2] Estender `ConfirmAnexoUseCase` e `AddLinkAnexoUseCase` para persistir `TramitacaoDemandaAnexoAccess` rows em `ci-api-v2/src/modules/tramitacao/use-cases/confirm-anexo.use-case.ts` e `add-link-anexo.use-case.ts` (GREEN T028)
- [X] T032 [US2] Retornar erros `CONFIDENTIAL_ACCESS_REQUIRED`, `EMPTY_SECTOR_USERS`, `USER_NOT_IN_SECTOR` no controller/use cases

### Implementation for User Story 2 — Client

- [X] T033 [P] [US2] Criar `ConfidentialAccessPicker.tsx` (multi-setor + usuários por setor) em `ci-client-v2/apps/web/src/modules/tramitacao/components/ConfidentialAccessPicker.tsx`
- [X] T034 [US2] Estender `TramitacaoAnexoUploadZone.tsx` com toggle confidencial e `ConfidentialAccessPicker` por item staged
- [X] T035 [US2] Passar `isConfidential` + `access` no `confirmAnexo`/`addLinkAnexo` de `ci-client-v2/apps/web/src/modules/tramitacao/api/anexos.ts`
- [X] T036 [US2] Bloquear envio no workspace quando confidencial sem usuário/setor válido em `TramitacaoInboxWorkspace.tsx`

**Checkpoint**: ACL persistida; validações client+server; CT-DC-006..009 GREEN

---

## Phase 5: User Story 3 — Visualização diferenciada (Priority: P1)

**Goal**: Autorizado vê full; não autorizado vê placeholder sem URL; download guardado

**Independent Test**: Quickstart Cenário 2 — B full, B2 placeholder; CT-DC-010..014, CT-DC-U01, CT-DC-U02

### Tests for User Story 3 (TDD — RED first)

- [X] T037 [P] [US3] Escrever testes (RED) `resolve-anexo-access.spec.ts` em `ci-api-v2/src/modules/tramitacao/lib/resolve-anexo-access.spec.ts` — CT-DC-U01
- [X] T038 [P] [US3] Escrever testes (RED) mapper anexo em `ci-api-v2/src/modules/tramitacao/tramitacao.mapper.spec.ts` — CT-DC-U02
- [X] T039 [P] [US3] Estender testes (RED) integração detail/download em `ci-api-v2/src/modules/tramitacao/test/anexo-confidential.integration.spec.ts` — CT-DC-010..014

### Implementation for User Story 3 — API

- [X] T040 [US3] Implementar `resolveAnexoAccessLevel(actor, anexo)` em `ci-api-v2/src/modules/tramitacao/lib/resolve-anexo-access.ts` — autor sempre full (GREEN T037)
- [X] T041 [US3] Implementar `toAnexoDto(anexo, accessLevel)` com placeholder sem `url`/`storageKey` em `ci-api-v2/src/modules/tramitacao/tramitacao.mapper.ts` (GREEN T038)
- [X] T042 [US3] Aplicar `resolveAnexoAccessLevel` em `GetDemandaDetailUseCase` passando actor JWT em `ci-api-v2/src/modules/tramitacao/use-cases/get-demanda-detail.use-case.ts` (GREEN T039)
- [X] T043 [US3] Implementar `DownloadAnexoUseCase` com guard ACL em `ci-api-v2/src/modules/tramitacao/use-cases/download-anexo.use-case.ts` (GREEN T039)
- [X] T044 [US3] Expor `GET .../anexos/:anexoId/download` em `ci-api-v2/src/modules/tramitacao/tramitacao.controller.ts`

### Implementation for User Story 3 — Client

- [X] T045 [US3] Estender `TramitacaoAnexoList.tsx` — card placeholder (ícone cadeado, sem botão download) vs full com `getAnexoDownloadUrl` em `ci-client-v2/apps/web/src/modules/tramitacao/api/anexos.ts`
- [X] T046 [US3] Renderizar `TramitacaoAnexoList` na timeline do detalhe em `TramitacaoInboxWorkspace.tsx`

**Checkpoint**: Placeholder nunca vaza URL; download 403 para não autorizado; CT-DC-010..014 GREEN

---

## Phase 6: User Story 4 — Anexos confidenciais na caixa pessoal (Priority: P2)

**Goal**: Mesmo fluxo setor→usuários em mensagens pessoais; destinatário não autorizado vê placeholder

**Independent Test**: Quickstart Cenário 5 — A→B confidencial autoriza C; B placeholder, C full; CT-DC-018

### Tests for User Story 4 (TDD — RED first)

- [X] T047 [P] [US4] Escrever testes (RED) integração pessoal+confidencial em `ci-api-v2/src/modules/tramitacao/test/anexo-forward-promote.integration.spec.ts` — CT-DC-018

### Implementation for User Story 4

- [X] T048 [US4] Garantir presign/confirm respeitam `assertPersonalDemandaAccess` em rotas anexo do controller para demandas `originType=personal`
- [X] T049 [US4] Integrar `TramitacaoAnexoUploadZone` + confidencial no compose pessoal (`inboxMode=personal`) em `TramitacaoInboxWorkspace.tsx` (GREEN T047)
- [X] T050 [US4] Orquestrar anexos pós-`POST /demandas/personal` e pós-reply pessoal com `eventoId` binding

**Checkpoint**: Caixa pessoal com confidencialidade; CT-DC-018 GREEN

---

## Phase 7: User Story 5 — Preservar confidencialidade ao encaminhar (Priority: P2)

**Goal**: ACL imutável no forward; novos anexos com ACL própria; membros setor destino não ganham acesso

**Independent Test**: Quickstart Cenário 4 — forward preserva ACL; novo anexo público; CT-DC-015, CT-DC-016

### Tests for User Story 5 (TDD — RED first)

- [X] T051 [P] [US5] Escrever testes (RED) forward ACL em `ci-api-v2/src/modules/tramitacao/test/anexo-forward-promote.integration.spec.ts` — CT-DC-015, CT-DC-016

### Implementation for User Story 5

- [X] T052 [US5] Verificar `ForwardDemandaUseCase` não altera `TramitacaoDemandaAnexoAccess` — adicionar teste de não-regressão se necessário em `forward-demanda.use-case.ts`
- [X] T053 [US5] Integrar upload zone no sheet encaminhar setorial com `eventoId` do evento `forwarded` em `TramitacaoInboxWorkspace.tsx` (GREEN T051)
- [X] T054 [US5] Documentar no payload do evento `forwarded` contagem de anexos confidenciais (opcional, sem expandir ACL)

**Checkpoint**: Forward não expande sigilo; CT-DC-015, CT-DC-016 GREEN

---

## Phase 8: User Story 6 — Promover pessoal→setor mantendo ACL (Priority: P2)

**Goal**: Thread visível ao setor; anexos confidenciais permanecem restritos

**Independent Test**: Quickstart Cenário 6 — colegas setor placeholder; autorizado full; CT-DC-017

### Tests for User Story 6 (TDD — RED first)

- [X] T055 [P] [US6] Escrever testes (RED) promote ACL em `ci-api-v2/src/modules/tramitacao/test/anexo-forward-promote.integration.spec.ts` — CT-DC-017

### Implementation for User Story 6

- [X] T056 [US6] Verificar `PromotePersonalToSectorUseCase` não muta `accessGrants` em `ci-api-v2/src/modules/tramitacao/use-cases/promote-personal-to-sector.use-case.ts` (GREEN T055)
- [X] T057 [US6] Após promoção, detail setorial retorna placeholders corretos para não autorizados via `resolveAnexoAccessLevel`

**Checkpoint**: Promoção não expande ACL; CT-DC-017 GREEN

---

## Phase 9: User Story 7 — Auditoria admin_tenant (Priority: P2)

**Goal**: admin_tenant vê todos anexos confidenciais full; mutações bloqueadas

**Independent Test**: Quickstart Cenário 7 — admin download confidencial; reply bloqueado; CT-DC-013

### Tests for User Story 7 (TDD — RED first)

- [X] T058 [P] [US7] Escrever testes (RED) admin audit em `ci-api-v2/src/modules/tramitacao/test/anexo-confidential.integration.spec.ts` — CT-DC-013

### Implementation for User Story 7

- [X] T059 [US7] Adicionar bypass `admin_tenant` em `resolveAnexoAccessLevel` em `ci-api-v2/src/modules/tramitacao/lib/resolve-anexo-access.ts` (GREEN T058)
- [X] T060 [US7] Garantir rotas anexo/download respeitam `audit_read_only` de `assertPersonalDemandaAccess` — sem presign/confirm para admin em modo audit

**Checkpoint**: Admin vê full; read-only preservado; CT-DC-013 GREEN

---

## Phase 10: Polish & Cross-Cutting Concerns

**Purpose**: Testes client, MSW, validação manual, copy

- [X] T061 [P] Escrever testes (RED) `ConfidentialAccessPicker.test.tsx` em `ci-client-v2/apps/web/src/modules/tramitacao/components/__tests__/ConfidentialAccessPicker.test.tsx` — CT-DC-019
- [X] T062 [P] Escrever testes (RED) `TramitacaoAnexoList.test.tsx` em `ci-client-v2/apps/web/src/modules/tramitacao/components/__tests__/TramitacaoAnexoList.test.tsx` — CT-DC-020
- [X] T063 [P] Escrever testes (RED) `TramitacaoInboxWorkspace.anexos.test.tsx` em `ci-client-v2/apps/web/src/modules/tramitacao/components/__tests__/TramitacaoInboxWorkspace.anexos.test.tsx` — CT-DC-021
- [X] T064 [P] Estender MSW handlers anexos em `ci-client-v2/apps/web/src/test/msw/handlers/tramitacao.ts` — CT-DC-022
- [X] T065 Executar quickstart Cenários 1–7 de `civ2-docs/specs/033-tramitacao-docs-confidenciais/quickstart.md` e registrar desvios
- [X] T066 [P] Revisar copy PT-BR confidencial em componentes contra `.cursor/docs/regras-plataforma.md`
- [X] T067 Rodar suite completa: `npm test -- --testPathPatterns=anexo` (API) e `npm test -- tramitacao` (client)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Sem dependências
- **Foundational (Phase 2)**: Depende Setup — **BLOQUEIA todas as user stories**
- **US1 (Phase 3)**: Depende Foundational — MVP upload público
- **US2 (Phase 4)**: Depende US1 (confirm/link existentes)
- **US3 (Phase 5)**: Depende US2 (ACL persistida para resolver acesso)
- **US4 (Phase 6)**: Depende US2+US3 (confidencialidade funcional)
- **US5 (Phase 7)**: Depende US1+US3 (anexos + placeholder)
- **US6 (Phase 8)**: Depende US4+US5 (pessoal + forward)
- **US7 (Phase 9)**: Depende US3 (resolve access)
- **Polish (Phase 10)**: Depende US1–US7 desejados

### User Story Dependencies

| Story | Depende de | Independente após |
|-------|------------|-------------------|
| US1 | Foundational | Upload público E2E |
| US2 | US1 | ACL multi-setor |
| US3 | US2 | Placeholder + download |
| US4 | US2, US3 | Caixa pessoal confidencial |
| US5 | US1, US3 | Forward ACL imutável |
| US6 | US4, US5 | Promoção mantém ACL |
| US7 | US3 | Admin audit full |

### Parallel Opportunities

- Phase 1: T002, T003, T004 em paralelo
- Phase 2: T008 paralelo após T007
- US1: T012, T013 paralelo; T021, T022 paralelo
- US2: T026, T027, T028 paralelo; T033 paralelo com API após T030
- US3: T037, T038, T039 paralelo
- US4–US7: testes RED [P] antes de implementação
- Polish: T061–T064, T066 em paralelo

### Parallel Example: User Story 1

```bash
# RED tests em paralelo:
T012 presign-anexo.use-case.spec.ts
T013 anexo-upload.integration.spec.ts

# Client API em paralelo (após T015):
T021 api/anexos.ts
T022 lib/anexo-schemas.ts
```

### Parallel Example: User Story 2

```bash
# RED em paralelo:
T026 tramitacao.schemas.spec.ts
T027 validate-anexo-access.spec.ts
T028 anexo-confidential.integration.spec.ts

# Client picker paralelo à API após schemas:
T033 ConfidentialAccessPicker.tsx
```

---

## Implementation Strategy

### MVP First (User Story 1 apenas)

1. Phase 1 Setup + Phase 2 Foundational
2. Phase 3 US1 — upload público end-to-end
3. **STOP**: Validar Cenário 1 quickstart; CT-DC-001..005 GREEN
4. Demo: anexos na timeline sem confidencialidade

### Incremental Delivery (recomendado)

1. Foundational → US1 (upload) → **MVP demo**
2. US2 + US3 (confidencial + placeholder) → **valor central do cliente**
3. US4–US7 (pessoal, forward, promote, audit) → cobertura completa spec
4. Polish → merge-ready

### Suggested MVP Scope

**US1 + US2 + US3** (P1) entregam o núcleo: anexar, marcar confidencial, ver placeholder. US4–US7 são incrementos P2.

---

## Notes

- TDD: RED confirmado antes de GREEN em cada fase de testes
- `uploadedByUserId`: sempre `resolveUserTableId` — nunca `req.user.userId` direto
- Placeholder: nunca serializar `url`, `storageKey`, `downloadUrl` (SC-002)
- ACL imutável após confirm — forward/promote não tocam `TramitacaoDemandaAnexoAccess`
- Total: **67 tasks** — T001–T067
