# Tasks: Migração de Dados v1 → v2 — Tenant AGEMAN (Agema)

**Input**: Design documents from `civ2-docs/specs/036-migracao-agema-v1/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Tests**: TDD obrigatório (Constitution II) — testes RED antes da implementação para mappers de migração e módulo `siged`.

**Organization**: Tasks grouped by user story to enable independent implementation and testing.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks)
- **[Story]**: Which user story this task belongs to (US1, US2, US3, US4)
- Include exact file paths in descriptions

## Path Conventions

- **Backend / scripts**: `ci-api-v2/scripts/migracao-agema-v1/` e `ci-api-v2/src/modules/siged/`
- **Prisma**: `ci-api-v2/prisma/schema/siged.prisma`
- **Client (opcional US4 UI)**: `ci-client-v2/apps/web/src/modules/gabinete/`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Estrutura de pastas, dependências e constantes compartilhadas da migração

- [x] T001 Create migration script directory tree per plan.md in `ci-api-v2/scripts/migracao-agema-v1/` (`source/`, `mappers/`, `load/`, `reconciliation/`, `types/`, `mappers/__tests__/`)
- [x] T002 Add `mysql2` dependency and `tsx` script alias in `ci-api-v2/package.json` for running migration CLI
- [x] T003 [P] Create AGEMAN tenant constants (`AGEMAN_V1_TENANT_ID`, slug `ageman`) in `ci-api-v2/scripts/migracao-agema-v1/constants.ts`
- [x] T004 [P] Create shared v1 row TypeScript types in `ci-api-v2/scripts/migracao-agema-v1/types/v1-rows.ts` (users, sectors, manifestations, protocolos, etc.)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Infraestrutura de extração, rastreabilidade e tenant — **BLOCKS all user stories**

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T005 Update User Story 1 Acceptance Scenario 4 in `civ2-docs/specs/036-migracao-agema-v1/spec.md` to reflect research R5 (chefe de setor não existe no v1 — `chefeUserId` permanece `null` pós-migração; atribuição manual no v2)
- [x] T006 Implement MySQL v1 read client using `MYSQL_V1_URL` in `ci-api-v2/scripts/migracao-agema-v1/source/mysql-v1.client.ts`
- [x] T007 Implement id-map read/write store in `ci-api-v2/scripts/migracao-agema-v1/reconciliation/id-map-store.ts` (persist `v1Id → v2Id` per entity, not versioned)
- [x] T008 Create exclusion list scaffold and candidate generator in `ci-api-v2/scripts/migracao-agema-v1/mappers/exclusion-list.ts` and `ci-api-v2/scripts/migracao-agema-v1/mappers/generate-exclusion-candidates.ts` (heuristics only — output for human review per FR-024)
- [x] T009 [P] Write failing tests for tenant mapper in `ci-api-v2/scripts/migracao-agema-v1/mappers/__tests__/tenant.mapper.spec.ts` with fixtures from dump sample
- [x] T010 [P] Implement tenant mapper in `ci-api-v2/scripts/migracao-agema-v1/mappers/tenant.mapper.ts` (name, active, slug `ageman`, timestamps)
- [x] T011 Implement idempotent tenant load in `ci-api-v2/scripts/migracao-agema-v1/load/tenant.load.ts` using `createPrismaClient()` with explicit `tenantId` (research R3)
- [x] T012 Create migration orchestrator skeleton with `--dry-run` flag in `ci-api-v2/scripts/migracao-agema-v1/run-migration.ts` (tenant phase only initially)
- [x] T013 Create count-report CLI skeleton with `--source-only` in `ci-api-v2/scripts/migracao-agema-v1/reconciliation/count-report.ts`

**Checkpoint**: Tenant AGEMAN can be extracted from MySQL v1 and loaded into PostgreSQL v2 idempotently; id-map and exclusion infrastructure ready

---

## Phase 3: User Story 1 — Servidores acessam o v2 com identidade existente (Priority: P1) 🎯 MVP

**Goal**: Migrar usuários, setores, vínculos usuário-setor e administradores da instituição; preservar login com mesma senha bcrypt

**Independent Test**: Login no v2 com credenciais de um usuário real da AGEMAN migrado; verificar setores vinculados e acesso de admin para `isSuperAdmin` (SC-001, SC-002)

### Tests for User Story 1 ⚠️

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [x] T014 [P] [US1] Write failing tests for auth mapper (User, AdminTenant, Setor, UserSetor) in `ci-api-v2/scripts/migracao-agema-v1/mappers/__tests__/auth.mapper.spec.ts` including `isSuperAdmin → AdminTenant` and `chefeUserId = null`
- [x] T015 [P] [US1] Write failing tests for exclusion FK nulling (FR-025) in `ci-api-v2/scripts/migracao-agema-v1/mappers/__tests__/exclusion-integrity.spec.ts` (real record referencing excluded test user → `createdByUserId = null`)

### Implementation for User Story 1

- [x] T016 [P] [US1] Implement auth mapper in `ci-api-v2/scripts/migracao-agema-v1/mappers/auth.mapper.ts` (users, sectors, user_sectors; passwordHash as-is; no re-hash)
- [x] T017 [P] [US1] Create AGEMAN ModuloSetor mapping config (setor sigla → `ModuloSlug[]`) reviewed with product team in `ci-api-v2/scripts/migracao-agema-v1/mappers/modulo-setor-ageman.config.ts` (research R2 — not 1:1 RBAC copy)
- [x] T018 [US1] Implement idempotent auth load (User, AdminTenant, Setor, UserSetor, ModuloSetor) in `ci-api-v2/scripts/migracao-agema-v1/load/auth.load.ts`
- [x] T019 [US1] Wire auth phase into orchestrator after tenant in `ci-api-v2/scripts/migracao-agema-v1/run-migration.ts`
- [x] T020 [US1] Extend count-report for users, setores, userSetores, adminTenants in `ci-api-v2/scripts/migracao-agema-v1/reconciliation/count-report.ts`

**Checkpoint**: User Story 1 fully functional — login + setores + admin tenant migrados; count-report validates SC-002

---

## Phase 4: User Story 2 — Ouvidoria mantém histórico de manifestações (Priority: P2)

**Goal**: Migrar manifestações, requerentes (respeitando anonimato), endereços, anexos físicos e linha do tempo de eventos

**Independent Test**: Buscar manifestação pelo número de protocolo original no v2; confirmar dados, anonimato e anexo baixável (SC-003)

### Tests for User Story 2 ⚠️

- [x] T021 [P] [US2] Write failing tests for ouvidoria mapper (enum conversion, anonymous redaction) in `ci-api-v2/scripts/migracao-agema-v1/mappers/__tests__/ouvidoria.mapper.spec.ts`
- [x] T022 [P] [US2] Write failing tests for event reconstruction ordering in `ci-api-v2/scripts/migracao-agema-v1/mappers/__tests__/ouvidoria-events.spec.ts`

### Implementation for User Story 2

- [x] T023 [P] [US2] Implement enum mapping tables (`ManifestacaoTipo`/`Status`/`Priority`/`EventoTipo`) in `ci-api-v2/scripts/migracao-agema-v1/mappers/ouvidoria-enums.ts`
- [x] T024 [P] [US2] Implement ouvidoria mapper in `ci-api-v2/scripts/migracao-agema-v1/mappers/ouvidoria.mapper.ts` (manifestations, addresses, attachments metadata, events)
- [x] T025 [P] [US2] Implement storage file copy helper reusing `ci-api-v2/src/modules/shared/storage/storage.port.ts` in `ci-api-v2/scripts/migracao-agema-v1/load/storage-copy.ts` (research R7)
- [x] T026 [US2] Implement idempotent ouvidoria load in `ci-api-v2/scripts/migracao-agema-v1/load/ouvidoria.load.ts` (Manifestacao, Address, ManifestacaoAnexo, ManifestacaoEvento, ManifestacaoSequence)
- [x] T027 [US2] Wire ouvidoria phase into orchestrator after auth in `ci-api-v2/scripts/migracao-agema-v1/run-migration.ts`
- [x] T028 [US2] Extend count-report for manifestações, anexos, eventos in `ci-api-v2/scripts/migracao-agema-v1/reconciliation/count-report.ts`

**Checkpoint**: User Stories 1 AND 2 independently testable — manifestações localizáveis por protocolo original

---

## Phase 5: User Story 3 — Gabinete mantém protocolos e controles (Priority: P2)

**Goal**: Migrar protocolos, controles numéricos, notificações, autos de infração e documentos tramitados por setor

**Independent Test**: Localizar protocolo pelo número interno no v2; confirmar controles numéricos, notificações, autos e documentos tramitados vinculados (SC-004)

### Tests for User Story 3 ⚠️

- [x] T029 [P] [US3] Write failing tests for gabinete mapper in `ci-api-v2/scripts/migracao-agema-v1/mappers/__tests__/gabinete.mapper.spec.ts` (protocolos, controles, entryMode siged, zero demandas OK)
- [x] T030 [P] [US3] Write failing tests for sector-table → Setor mapping in `ci-api-v2/scripts/migracao-agema-v1/mappers/__tests__/documentos-tramitados.mapper.spec.ts`

### Implementation for User Story 3

- [x] T031 [P] [US3] Implement gabinete mapper in `ci-api-v2/scripts/migracao-agema-v1/mappers/gabinete.mapper.ts` (protocolos, controle_numerico_*, notificacoes, autos_infracao, documentos_tramitados_*)
- [x] T032 [US3] Implement idempotent gabinete load in `ci-api-v2/scripts/migracao-agema-v1/load/gabinete.load.ts` (CabinetProtocolo, CabinetControleNumerico, CabinetControleNotificacao, CabinetControleAutoInfracao, CabinetDocumentoTramitado)
- [x] T033 [US3] Wire gabinete phase into orchestrator after ouvidoria in `ci-api-v2/scripts/migracao-agema-v1/run-migration.ts`
- [x] T034 [US3] Extend count-report for protocolos, controles, documentos tramitados in `ci-api-v2/scripts/migracao-agema-v1/reconciliation/count-report.ts`
- [x] T035 [US3] Add `--compare` mode to count-report producing pass/fail per entity for SC-006 in `ci-api-v2/scripts/migracao-agema-v1/reconciliation/count-report.ts`

**Checkpoint**: User Stories 1–3 complete — full migration pipeline Tenant → Auth → Ouvidoria → Gabinete with reconciliation

---

## Phase 6: User Story 4 — Consulta tramitação SIGED ao vivo (Priority: P3)

**Goal**: Módulo NestJS `siged` consulta tramitações reais via API municipal; expõe endpoint no v2; credenciais por tenant

**Independent Test**: `GET /gabinete/protocolos/:id/tramitacoes-siged` retorna tramitações para protocolo com `sigedNumber`; retorna `sem_numero_siged` quando ausente; retorna `siged_indisponivel` em falha (SC-007, FR-020..023)

### Tests for User Story 4 ⚠️

- [x] T036 [P] [US4] Write failing tests for SIGED API client (token cache, pagination, error mapping) in `ci-api-v2/src/modules/siged/repository/siged-api.client.spec.ts` with HTTP mocks
- [x] T037 [P] [US4] Write failing tests for get-tramitacoes use case in `ci-api-v2/src/modules/siged/use-cases/get-tramitacoes-protocolo.use-case.spec.ts` (sem_numero_siged, siged_indisponivel, 403)

### Implementation for User Story 4

- [x] T038 [US4] Add `TenantSigedConfig` model and Prisma migration in `ci-api-v2/prisma/schema/siged.prisma` and run migration (relation on `Tenant` in `ci-api-v2/prisma/schema/tenant.prisma`)
- [x] T039 [P] [US4] Implement Zod schemas mirroring `integração-siged/openapi.json` in `ci-api-v2/src/modules/siged/siged.schemas.ts`
- [x] T040 [P] [US4] Implement SIGED HTTP client and JWT token cache in `ci-api-v2/src/modules/siged/repository/siged-api.client.ts` and `ci-api-v2/src/modules/siged/repository/siged-token-cache.ts`
- [x] T041 [US4] Implement get-tramitacoes-protocolo use case in `ci-api-v2/src/modules/siged/use-cases/get-tramitacoes-protocolo.use-case.ts` (resolve `CabinetProtocolo.sigedNumber`, paginate SIGED API)
- [x] T042 [US4] Implement controller endpoint `GET /gabinete/protocolos/:protocoloId/tramitacoes-siged` in `ci-api-v2/src/modules/siged/siged.controller.ts` per `contracts/siged-integration.md`
- [x] T043 [US4] Wire SigedModule in `ci-api-v2/src/modules/siged/siged.module.ts` and register in `ci-api-v2/src/app.module.ts`
- [x] T044 [P] [US4] Add optional client panel "Tramitação SIGED" consuming the new endpoint in `ci-client-v2/apps/web/src/modules/gabinete/` (API hook + UI section on protocolo detail — FR-022 visual distinction)

**Checkpoint**: User Story 4 complete — endpoint testável com mocks; E2E real após credenciais SIGED em `TenantSigedConfig.active = true` (research R4)

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Validação end-to-end, aprovação de exclusões e documentação operacional

- [x] T045 Run full migration dry-run against restored MySQL dump per `civ2-docs/specs/036-migracao-agema-v1/quickstart.md` and fix any mapper/load gaps
- [ ] T046 Obtain AGEMAN team approval for finalized exclusion list in `ci-api-v2/scripts/migracao-agema-v1/mappers/exclusion-list.ts` before staging/production run (FR-024)
- [x] T047 Execute staging migration + `count-report --compare`; document results in `civ2-docs/specs/036-migracao-agema-v1/reconciliation/staging-run.md` (SC-006)
- [x] T048 [P] Run `npm test -- --testPathPatterns=migracao-agema-v1` and `npm test -- --testPathPatterns=siged` in `ci-api-v2/` and ensure all green
- [x] T049 Document SIGED credential activation steps (`TenantSigedConfig`, `secretariaId=18692`, `active=true`) in `civ2-docs/specs/036-migracao-agema-v1/quickstart.md`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **Foundational (Phase 2)**: Depends on Setup — **BLOCKS all user stories**
- **User Story 1 (Phase 3)**: Depends on Foundational (tenant + infra)
- **User Story 2 (Phase 4)**: Depends on US1 (needs User/Setor ids for FKs and `createdByUserId`)
- **User Story 3 (Phase 5)**: Depends on US1 (Setor for documentos tramitados); US2 recommended first (Manifestacao FK if any demanda links)
- **User Story 4 (Phase 6)**: Depends on US3 for full E2E with migrated protocolos; module code can start in parallel after Foundational using test fixtures
- **Polish (Phase 7)**: Depends on US1–US4 completion (or US1–US3 if SIGED go-live deferred)

### User Story Dependencies

| Story | Depends on | Independently testable when |
|-------|------------|----------------------------|
| US1 (P1) | Foundational | Login + setores + admin tenant in v2 |
| US2 (P2) | US1 | Manifestação buscável por protocolo |
| US3 (P2) | US1 (+ US2 for linked demandas) | Protocolo + controles visíveis |
| US4 (P3) | US3 (E2E); mocks only needs protocol fixture | Endpoint returns SIGED tramitações or graceful errors |

### Within Each User Story

- Tests MUST fail (RED) before implementation (GREEN)
- Mappers before load scripts
- Load scripts before orchestrator wiring
- Count-report extended after each domain load

### Parallel Opportunities

- **Phase 1**: T003 ∥ T004
- **Phase 2**: T009 ∥ T010 (after T008)
- **Phase 3**: T014 ∥ T015; T016 ∥ T017
- **Phase 4**: T021 ∥ T022; T023 ∥ T024 ∥ T025
- **Phase 5**: T029 ∥ T030; T031 can start after tests RED
- **Phase 6**: T036 ∥ T037; T039 ∥ T040; T044 can run parallel to backend if API contract stable
- **Phase 7**: T048 ∥ T049

---

## Parallel Example: User Story 1

```bash
# RED — launch mapper tests together:
Task T014: auth.mapper.spec.ts
Task T015: exclusion-integrity.spec.ts

# GREEN — parallel mappers:
Task T016: auth.mapper.ts
Task T017: modulo-setor-ageman.config.ts
```

---

## Parallel Example: User Story 4

```bash
# RED — parallel test files:
Task T036: siged-api.client.spec.ts
Task T037: get-tramitacoes-protocolo.use-case.spec.ts

# GREEN — parallel implementation (after T038 migration):
Task T039: siged.schemas.ts
Task T040: siged-api.client.ts + siged-token-cache.ts
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (tenant migrado)
3. Complete Phase 3: User Story 1 (auth completo)
4. **STOP and VALIDATE**: Login real AGEMAN + count-report setores/usuários
5. Demo MVP — servidores já conseguem entrar no v2

### Incremental Delivery

1. Setup + Foundational → tenant AGEMAN no v2
2. US1 → login + setores (**MVP**)
3. US2 → ouvidoria histórica completa
4. US3 → gabinete + reconciliação SC-006
5. US4 → consulta SIGED ao vivo (mocks first; credenciais reais depois)

### Parallel Team Strategy

With multiple developers after Foundational:

- **Dev A**: US1 auth mappers + load
- **Dev B**: US2 ouvidoria (after US1 load skeleton exists)
- **Dev C**: US4 siged module (mock-based, independent of migration run)

---

## Notes

- `chefeUserId` **não é migrado** — research R5; spec atualizada em T005
- RBAC v1 (`roles`/`permissions`) **não é copiado 1:1** — usar `modulo-setor-ageman.config.ts` (T017)
- Exclusion list requires **human approval** before production (T046)
- SIGED live E2E blocked until credentials provided (research R4) — module still shippable with mocks
- Re-run migration is idempotent — safe to execute multiple times on staging
- id-map JSON files are **not committed** (gitignore under `reconciliation/`)
