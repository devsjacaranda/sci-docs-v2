---
description: "Task list for Gerenciamento Usuários e Setores Gabinete (017-gabinete-usuarios-setores-crud)"
---

# Tasks: Gerenciamento de Usuários e Setores — Gabinete

**Input**: Design documents from `civ2-docs/specs/017-gabinete-usuarios-setores-crud/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Tests**: **Obrigatórios** — TDD (constitution II + plan.md + `contracts/test-strategy.md`): unitário, componente, contrato Supertest, integração MSW e E2E Vitest. **Sem migration Prisma** — soft delete existente.

**Organization**: US1–US3 são P1; US4–US6 são P2; US7 é P3. Caminhos relativos à raiz `ci-v2/`. Módulo API `setor` e painéis `PlatformUsersPanel`/`PlatformSectorsPanel` **já existem parcialmente** — tasks **completam** guard Gabinete, paginação API, ciclo de vida e layout institucional compartilhado.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Pode executar em paralelo (arquivos diferentes, sem dependências pendentes)
- **[Story]**: User story da spec (US1–US7)

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Fixtures MSW, estrutura de pastas e exports para TDD

- [X] T001 [P] Criar fixtures client `ci-client-v2/apps/web/src/modules/setor/fixtures/users-list-paginated.json` e `setores-list-paginated.json` conforme `data-model.md`
- [X] T002 [P] Criar fixtures API `ci-api-v2/src/modules/setor/test/fixtures/users-list-response.json` e `setores-list-response.json`
- [X] T003 [P] Implementar handlers MSW em `ci-client-v2/apps/web/src/test/msw/handlers/institutional-admin.ts` (GET/POST/PATCH/DELETE/restore/reset-password) e registrar em `ci-client-v2/apps/web/src/test/msw/handlers.ts`
- [X] T004 [P] Criar pasta `ci-client-v2/apps/web/src/modules/setor/components/institutional/` com barrel `index.ts` exportando componentes (vazios/stub)
- [X] T005 [P] Criar pasta `ci-api-v2/src/modules/setor/repository/` e `ci-api-v2/src/modules/setor/use-cases/` com README inline no `setor.module.ts` registrando providers vazios (stub)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Guard institucional, schemas Zod paginados, componentes layout design system — **bloqueia todas as user stories**

**⚠️ CRITICAL**: Nenhuma user story começa antes desta fase

### Tests first (TDD — RED)

- [X] T006 [P] Escrever testes (RED) `institutional-admin.guard.spec.ts` em `ci-api-v2/src/modules/setor/guards/institutional-admin.guard.spec.ts` — matriz GAB/admin_tenant/admin_plataforma/403
- [X] T007 [P] Escrever testes (RED) `setor.schemas.spec.ts` em `ci-api-v2/src/modules/setor/setor.schemas.spec.ts` — ListUsersQuery, CreateUserBody role allowlist, ResetUserPasswordBody
- [X] T008 [P] Escrever testes (RED) `InstitutionalStatGrid.test.tsx` em `ci-client-v2/apps/web/src/modules/setor/components/institutional/__tests__/InstitutionalStatGrid.test.tsx`
- [X] T009 [P] Escrever testes (RED) `InstitutionalListLayout.test.tsx` em `ci-client-v2/apps/web/src/modules/setor/components/institutional/__tests__/InstitutionalListLayout.test.tsx` — breadcrumb via screenId

### API foundational

- [X] T010 Implementar `InstitutionalAdminGuard` em `ci-api-v2/src/modules/setor/guards/institutional-admin.guard.ts` usando `CheckModuloAccessUseCase` com `gabinete` (GREEN T006)
- [X] T011 Estender Zod em `ci-api-v2/src/modules/setor/setor.schemas.ts` — query paginada, create/update user role refine, reset password body (GREEN T007)
- [X] T012 Registrar guard e novos providers em `ci-api-v2/src/modules/setor/setor.module.ts` — substituir `@Roles(admin_plataforma)` por `InstitutionalAdminGuard` nas rotas users/setores em `ci-api-v2/src/modules/setor/setor.controller.ts`

### Client foundational (design system)

- [X] T013 [P] Implementar `InstitutionalListLayout.tsx` em `ci-client-v2/apps/web/src/modules/setor/components/institutional/InstitutionalListLayout.tsx` — `ScreenBreadcrumb` + `getBreadcrumbs` (GREEN T009)
- [X] T014 [P] Implementar `InstitutionalStatGrid.tsx` em `ci-client-v2/apps/web/src/modules/setor/components/institutional/InstitutionalStatGrid.tsx` — 4 KPI cards paleta Mint (GREEN T008)
- [X] T015 [P] Implementar `InstitutionalListHeader.tsx` em `ci-client-v2/apps/web/src/modules/setor/components/institutional/InstitutionalListHeader.tsx` — título, descrição, contador, botão criar CTA + prop `onCreateClick`
- [X] T016 [P] Implementar `InstitutionalFiltersCard.tsx` em `ci-client-v2/apps/web/src/modules/setor/components/institutional/InstitutionalFiltersCard.tsx` — slot children (status select + busca)
- [X] T017 [P] Implementar `InstitutionalTableCard.tsx` em `ci-client-v2/apps/web/src/modules/setor/components/institutional/InstitutionalTableCard.tsx` — wrapper `DataViewShell` + loading/empty
- [X] T018 [P] Implementar `InstitutionalPagination.tsx` em `ci-client-v2/apps/web/src/modules/setor/components/institutional/InstitutionalPagination.tsx` — clone `GabinetePagination` API-driven
- [X] T019 [P] Implementar `institutional-list-stats.ts` em `ci-client-v2/apps/web/src/modules/setor/lib/institutional-list-stats.ts` — mappers KPI usuários e setores

**Checkpoint**: Guard GREEN; schemas validam contrato; layout stack renderiza breadcrumb + KPI + pagination stub

---

## Phase 3: User Story 1 — Listar e buscar usuários no Gabinete (Priority: P1) 🎯 MVP

**Goal**: GET `/users` paginado + tela `/gabinete/usuarios` com busca, filtro status, tabela e paginação API

**Independent Test**: Membro GAB abre `/gabinete/usuarios` — vê breadcrumb, 4 KPI, filtros, tabela paginada; filtro Inativos altera query `status=inactive`

### Tests for User Story 1 (TDD — RED first)

- [X] T020 [P] [US1] Escrever testes (RED) `list-users-paginated.repository.spec.ts` *(opcional — coberto indiretamente por use-case)*
- [X] T021 [P] [US1] Escrever testes (RED) `list-users.use-case.spec.ts` em `ci-api-v2/src/modules/setor/use-cases/list-users.use-case.spec.ts`
- [X] T022 [P] [US1] Escrever testes (RED) `setor.controller.spec.ts` — GET `/users?page=1&limit=20&q=&status=active` em `ci-api-v2/src/modules/setor/setor.controller.spec.ts`
- [X] T023 [P] [US1] Escrever testes (RED) `UsersAdminPanel.list.test.tsx` em `ci-client-v2/apps/web/src/modules/setor/components/__tests__/UsersAdminPanel.list.test.tsx` — MSW + tabela + pagination
- [X] T024 [P] [US1] Escrever testes (RED) `institutional-list-stats.test.ts` em `ci-client-v2/apps/web/src/modules/setor/lib/__tests__/institutional-list-stats.test.ts`

### Implementation for User Story 1

- [X] T025 [P] [US1] Implementar `list-users-paginated.repository.ts` em `ci-api-v2/src/modules/setor/repository/list-users-paginated.repository.ts` (GREEN T020)
- [X] T026 [US1] Implementar `list-users.use-case.ts` em `ci-api-v2/src/modules/setor/use-cases/list-users.use-case.ts` — map `UserListItem` + status (GREEN T021)
- [X] T027 [US1] Wire GET `/users` paginado em `ci-api-v2/src/modules/setor/setor.controller.ts` delegando `ListUsersUseCase` (GREEN T022)
- [X] T028 [P] [US1] Criar `users-admin.ts` em `ci-client-v2/apps/web/src/modules/setor/api/users-admin.ts` — `fetchUsers({ page, limit, q, status })`
- [X] T029 [US1] Refatorar `UsersAdminPanel.tsx` em `ci-client-v2/apps/web/src/modules/setor/components/UsersAdminPanel.tsx` — extrair de `PlatformUsersPanel.tsx`; layout stack; list-only; props `context`, `screenId` (GREEN T023)
- [X] T030 [US1] Criar `GabineteUsuariosPage.tsx` em `ci-client-v2/apps/web/src/modules/setor/pages/GabineteUsuariosPage.tsx` — render `UsersAdminPanel context="gabinete"`
- [X] T031 [US1] Registrar rota lazy `/gabinete/usuarios` no router shell (ex.: `ci-client-v2/apps/web/src/modules/shell/routes/` ou arquivo de rotas gabinete existente)

**Checkpoint**: US1 — listagem usuários Gabinete funcional com paginação API; MVP list-only

---

## Phase 4: User Story 2 — CRUD completo de usuários (Priority: P1)

**Goal**: Criar, editar, inativar, restaurar, resetar senha — papéis `user`/`chefe_setor` only

**Independent Test**: Fluxo quickstart §2 — create → edit → reset password → inactivate (login fail) → restore (login ok)

### Tests for User Story 2 (TDD — RED first)

- [X] T032 [P] [US2] Escrever testes (RED) `create-user.use-case.spec.ts` — reject admin_plataforma, dup email
- [X] T033 [P] [US2] Escrever testes (RED) `update-user.use-case.spec.ts` em `ci-api-v2/src/modules/setor/use-cases/update-user.use-case.spec.ts`
- [X] T034 [P] [US2] Escrever testes (RED) `inactivate-user.use-case.spec.ts` — self forbidden, last admin forbidden
- [X] T035 [P] [US2] Escrever testes (RED) `restore-user.use-case.spec.ts` em `ci-api-v2/src/modules/setor/use-cases/restore-user.use-case.spec.ts`
- [X] T036 [P] [US2] Escrever testes (RED) `reset-user-password.use-case.spec.ts` em `ci-api-v2/src/modules/setor/use-cases/reset-user-password.use-case.spec.ts`
- [X] T037 [P] [US2] Escrever testes integração (RED) login bloqueado pós-inativar em `ci-api-v2/src/modules/auth/auth.service.spec.ts` ou `ci-api-v2/src/modules/setor/test/inactivate-user-auth.integration.spec.ts`
- [X] T038 [P] [US2] Escrever testes (RED) `UsersAdminPanel.crud.test.tsx` em `ci-client-v2/apps/web/src/modules/setor/components/__tests__/UsersAdminPanel.crud.test.tsx` — dialogs Inativar/Restaurar/Resetar senha

### Implementation for User Story 2

- [X] T039 [P] [US2] Implementar repositories *(consolidado nos use-cases via PrismaService — sem arquivos separados)*
- [X] T040 [US2] Implementar `create-user.use-case.ts` em `ci-api-v2/src/modules/setor/use-cases/create-user.use-case.ts` (GREEN T032)
- [X] T041 [US2] Implementar `update-user.use-case.ts` (GREEN T033)
- [X] T042 [US2] Implementar `inactivate-user.use-case.ts` (GREEN T034)
- [X] T043 [US2] Implementar `restore-user.use-case.ts` (GREEN T035)
- [X] T044 [US2] Implementar `reset-user-password.use-case.ts` (GREEN T036)
- [X] T045 [US2] Wire POST/PATCH/DELETE `/users/:id`, POST `/users/:id/restore`, POST `/users/:id/reset-password` em `ci-api-v2/src/modules/setor/setor.controller.ts`; deprecar lógica em `user-admin.service.ts`
- [X] T046 [US2] Estender `users-admin.ts` — `createUser`, `updateUser`, `inactivateUser`, `restoreUser`, `resetUserPassword`
- [X] T047 [US2] Completar `UsersAdminPanel.tsx` — dialogs criar/editar, confirm Inativar/Restaurar, Resetar senha; copy **nunca** "Excluir" (GREEN T038)
- [X] T048 [US2] Remover senha fixa `password123` e delete local-only; garantir refetch list após mutação

**Checkpoint**: US2 — CRUD usuários production-ready; auth bloqueia inativo

---

## Phase 5: User Story 3 — Listar setores no Gabinete (Priority: P1)

**Goal**: GET `/setores` paginado + tela `/gabinete/setores` com layout stack idêntico a usuários

**Independent Test**: Membro GAB abre `/gabinete/setores` — colunas sigla, nome, chefe, membros, status; paginação API

### Tests for User Story 3 (TDD — RED first)

- [X] T049 [P] [US3] Escrever testes (RED) `list-setores-paginated.repository.spec.ts` *(opcional)*
- [X] T050 [P] [US3] Escrever testes (RED) `list-setores.use-case.spec.ts` em `ci-api-v2/src/modules/setor/use-cases/list-setores.use-case.spec.ts`
- [X] T051 [P] [US3] Escrever testes (RED) GET `/setores` paginado em `ci-api-v2/src/modules/setor/setor.controller.spec.ts`
- [X] T052 [P] [US3] Escrever testes (RED) `SetoresAdminPanel.list.test.tsx` em `ci-client-v2/apps/web/src/modules/setor/components/__tests__/SetoresAdminPanel.list.test.tsx`

### Implementation for User Story 3

- [X] T053 [P] [US3] Implementar `list-setores-paginated.repository.ts` (GREEN T049)
- [X] T054 [US3] Implementar `list-setores.use-case.ts` (GREEN T050)
- [X] T055 [US3] Wire GET `/setores` paginado em `setor.controller.ts` (GREEN T051)
- [X] T056 [P] [US3] Criar `setores-admin.ts` em `ci-client-v2/apps/web/src/modules/setor/api/setores-admin.ts`
- [X] T057 [US3] Refatorar `SetoresAdminPanel.tsx` em `ci-client-v2/apps/web/src/modules/setor/components/SetoresAdminPanel.tsx` — extrair de `PlatformSectorsPanel.tsx` (GREEN T052)
- [X] T058 [US3] Criar `GabineteSetoresPage.tsx` em `ci-client-v2/apps/web/src/modules/setor/pages/GabineteSetoresPage.tsx`
- [X] T059 [US3] Registrar rota lazy `/gabinete/setores` no router shell

**Checkpoint**: US3 — listagem setores Gabinete independente de US1/US2

---

## Phase 6: User Story 4 — CRUD completo de setores (Priority: P2)

**Goal**: Criar, editar, inativar, restaurar setores; sigla única; chefe opcional

**Independent Test**: quickstart §3 — create → inactivate → restore; sigla dup → 409

### Tests for User Story 4 (TDD — RED first)

- [X] T060 [P] [US4] Escrever testes (RED) `create-setor.use-case.spec.ts` — sigla duplicate
- [X] T061 [P] [US4] Escrever testes (RED) `update-setor.use-case.spec.ts` em `ci-api-v2/src/modules/setor/use-cases/update-setor.use-case.spec.ts`
- [X] T062 [P] [US4] Escrever testes (RED) `inactivate-setor.use-case.spec.ts` e `restore-setor.use-case.spec.ts`
- [X] T063 [P] [US4] Escrever testes (RED) `SetoresAdminPanel.crud.test.tsx` em `ci-client-v2/apps/web/src/modules/setor/components/__tests__/SetoresAdminPanel.crud.test.tsx`

### Implementation for User Story 4

- [X] T064 [P] [US4] Implementar repositories setor CRUD *(consolidado nos use-cases via PrismaService)*
- [X] T065 [US4] Implementar use-cases `create-setor`, `update-setor`, `inactivate-setor`, `restore-setor` em `ci-api-v2/src/modules/setor/use-cases/` (GREEN T060–T062)
- [X] T066 [US4] Wire POST/PATCH/DELETE `/setores/:id`, POST `/setores/:id/restore` em `setor.controller.ts`; migrar de `setor.service.ts`
- [X] T067 [US4] Estender `setores-admin.ts` com mutações
- [X] T068 [US4] Completar `SetoresAdminPanel.tsx` — dialogs CRUD + Inativar/Restaurar (GREEN T063)

**Checkpoint**: US4 — CRUD setores completo

---

## Phase 7: User Story 5 — Paridade com telas de Plataforma (Priority: P2)

**Goal**: `/administracao/plataforma/usuarios|setores` usam mesmos painéis com `context="plataforma"`

**Independent Test**: Admin institucional vê mesmas colunas/KPI/filtros/paginação; alteração reflete em rota Gabinete

### Tests for User Story 5 (TDD — RED first)

- [X] T069 [P] [US5] Escrever testes (RED) `UsersAdminPanel.plataforma.test.tsx` — props context=plataforma, gate platform admin
- [X] T070 [P] [US5] Escrever testes (RED) `SetoresAdminPanel.plataforma.test.tsx` em `ci-client-v2/apps/web/src/modules/setor/components/__tests__/SetoresAdminPanel.plataforma.test.tsx`

### Implementation for User Story 5

- [X] T071 [US5] Atualizar `ci-client-v2/apps/web/src/modules/shell/pages/ScreenPage.tsx` — `UsersAdminPanel`/`SetoresAdminPanel` substituem `PlatformUsersPanel`/`PlatformSectorsPanel`
- [X] T072 [US5] Atualizar exports em `ci-client-v2/apps/web/src/modules/setor/index.ts` — reexport painéis novos; deprecar Platform*Panel
- [X] T073 [US5] Garantir `checkAdminScreenAccess` em `ci-client-v2/apps/web/src/modules/permissao/lib/permissions.ts` continua exigindo platform admin para rotas Plataforma (GREEN T069–T070)

**Checkpoint**: US5 — paridade SC-006 verificável

---

## Phase 8: User Story 6 — Navegação e ausência de licenças premium (Priority: P2)

**Goal**: Entradas Gabinete → Gestão institucional; telas imunes ao filtro global de licenças; zero stats premium

**Independent Test**: Sidebar mostra Usuários/Setores sob Gabinete; filtro Cedro ativo não oculta telas; sem badges licença

### Tests for User Story 6 (TDD — RED first)

- [X] T074 [P] [US6] Escrever testes (RED) `license-filter.institutional.test.ts` em `ci-client-v2/apps/web/src/modules/shell/lib/__tests__/license-filter.institutional.test.ts` — screens sempre visíveis
- [X] T075 [P] [US6] Escrever testes (RED) `navigation.gabinete-gestao.test.ts` em `ci-client-v2/apps/web/src/modules/shell/config/__tests__/navigation.gabinete-gestao.test.ts`

### Implementation for User Story 6

- [X] T076 [US6] Registrar screens `gabinete-usuarios` e `gabinete-setores` em `ci-client-v2/apps/web/src/modules/shell/config/screens.ts` — `licenses: ['base']`, paths `/gabinete/usuarios`, `/gabinete/setores`
- [X] T077 [US6] Adicionar subseção **Gestão institucional** em `ci-client-v2/apps/web/src/modules/shell/config/navigation.ts` — itens Usuários e Setores no grupo `gabinete`
- [X] T078 [US6] Estender `navItemMatchesFilter` / `GABINETE_INSTITUTIONAL_SCREENS` em `ci-client-v2/apps/web/src/modules/shell/lib/license-filter.ts` e `permissions.ts` (GREEN T074)
- [X] T079 [US6] Garantir painéis **não** renderizam `LicenseBadges` nem stats premium — apenas `InstitutionalStatGrid` Base (GREEN T075)

**Checkpoint**: US6 — FR-003 satisfeito

---

## Phase 9: User Story 7 — Controle de acesso e 403 padronizado (Priority: P3)

**Goal**: 403 copy padronizada para não-GAB; Gabinete pages com gate; API 403 consistente

**Independent Test**: Servidor sem GAB → `/gabinete/usuarios` 403; membro GAB → 200

### Tests for User Story 7 (TDD — RED first)

- [X] T080 [P] [US7] Escrever testes (RED) Supertest 403 non-GAB em `ci-api-v2/src/modules/setor/setor.controller.spec.ts`
- [X] T081 [P] [US7] Escrever testes (RED) `GabineteUsuariosPage.e2e.test.tsx` em `ci-client-v2/apps/web/src/modules/setor/__tests__/GabineteUsuariosPage.e2e.test.tsx`
- [X] T082 [P] [US7] Escrever testes (RED) `GabineteSetoresPage.e2e.test.tsx` em `ci-client-v2/apps/web/src/modules/setor/__tests__/GabineteSetoresPage.e2e.test.tsx`

### Implementation for User Story 7

- [X] T083 [US7] Criar `InstitutionalAdminGate.tsx` em `ci-client-v2/apps/web/src/modules/setor/components/InstitutionalAdminGate.tsx` — wrap pages Gabinete; copy 403 padronizada
- [X] T084 [US7] Integrar gate em `GabineteUsuariosPage.tsx` e `GabineteSetoresPage.tsx` (GREEN T081–T082)
- [X] T085 [US7] Ajustar mensagem login usuário inativo em `ci-api-v2/src/modules/auth/auth.service.ts` — copy institucional FR-012 (se necessário)

**Checkpoint**: US7 — matriz de acesso completa

---

## Phase 10: Polish & Cross-Cutting Concerns

**Purpose**: Cleanup legado, exports, validação quickstart

- [X] T086 [P] Remover ou marcar deprecated `PlatformUsersPanel.tsx` e `PlatformSectorsPanel.tsx` em `ci-client-v2/apps/web/src/modules/setor/components/` após migração completa
- [X] T087 [P] Atualizar `ci-client-v2/apps/web/src/modules/setor/api/setores.ts` — delegar para `users-admin.ts`/`setores-admin.ts` ou reexport
- [X] T088 [P] Export barrel `ci-client-v2/apps/web/src/modules/setor/components/institutional/index.ts` — todos componentes públicos
- [X] T089 Executar validação `civ2-docs/specs/017-gabinete-usuarios-setores-crud/quickstart.md` — checklist SC-001 a SC-006 *(automated: 50 API + 18 client tests verdes; SC-001/SC-002 timing manual)*
- [X] T090 [P] Criar `STATUS.md` em `civ2-docs/specs/017-gabinete-usuarios-setores-crud/STATUS.md` — resumo implementação pós-merge

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Sem dependências
- **Foundational (Phase 2)**: Depende Setup — **BLOQUEIA** US1–US7
- **US1 (Phase 3)**: Após Foundational — MVP listagem usuários
- **US2 (Phase 4)**: Depende US1 (mesmo painel) — CRUD usuários
- **US3 (Phase 5)**: Após Foundational — **paralelo** a US1/US2 (arquivos diferentes)
- **US4 (Phase 6)**: Depende US3 (mesmo painel setores)
- **US5 (Phase 7)**: Depende US2 + US4 (painéis completos)
- **US6 (Phase 8)**: Pode iniciar após T030/T058 (rotas); completar com T079
- **US7 (Phase 9)**: Depende pages Gabinete (T030, T058)
- **Polish (Phase 10)**: Depende stories desejadas completas

### User Story Dependencies

| Story | Depende de | Independente quando |
|-------|------------|---------------------|
| US1 | Phase 2 | List users Gabinete + API GET paginado |
| US2 | US1 | CRUD user full flow |
| US3 | Phase 2 | List setores Gabinete (paralelo US1) |
| US4 | US3 | CRUD setor full flow |
| US5 | US2, US4 | Plataforma paridade |
| US6 | Rotas Gabinete | Nav + license immunity |
| US7 | Pages Gabinete | 403 gates |

### Parallel Opportunities

- **Phase 1**: T001–T005 todos [P]
- **Phase 2**: T006–T009 RED em paralelo; T013–T018 UI em paralelo após T010–T011
- **US1 + US3**: Após Phase 2, dev A = US1, dev B = US3
- **US2 + US4**: Idem após listagens respectivas

### Parallel Example: User Story 1

```bash
# RED tests em paralelo:
T020 list-users-paginated.repository.spec.ts
T021 list-users.use-case.spec.ts
T023 UsersAdminPanel.list.test.tsx

# GREEN sequencial: T025 → T026 → T027 → T029
```

### Parallel Example: User Story 3 (enquanto US2 progride)

```bash
T049 list-setores-paginated.repository.spec.ts
T050 list-setores.use-case.spec.ts
T052 SetoresAdminPanel.list.test.tsx
```

---

## Implementation Strategy

### MVP First (User Story 1)

1. Phase 1 Setup
2. Phase 2 Foundational
3. Phase 3 US1 — listagem usuários Gabinete
4. **STOP** — validar quickstart §1 parcial + testes T020–T031

### Incremental Delivery

1. US1 → US2 (usuários completo)
2. US3 → US4 (setores completo) — pode overlap com US2
3. US5 Plataforma paridade
4. US6 Nav + licenças
5. US7 403 hardening

### Suggested MVP Scope

**MVP = Phase 1 + Phase 2 + Phase 3 (US1)** — listagem paginada usuários no Gabinete com design system completo (breadcrumb, KPI, filtros, tabela, paginação API).

---

## Notes

- **Sem** `@RequireLicenca` em rotas desta feature
- Paginação: **sempre** server-side em produção; `paginateClient` só MSW/offline
- TDD vertical: RED spec → GREEN mínimo → REFACTOR; nunca batch all tests
- Commit sugerido após cada checkpoint de fase
- Total: **90 tasks** — US1: 12 | US2: 17 | US3: 11 | US4: 9 | US5: 5 | US6: 6 | US7: 6 | Setup: 5 | Foundational: 14 | Polish: 5
