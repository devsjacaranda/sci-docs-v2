---
description: "Task list for Super Admin SaaS App (011-super-admin-saas-app)"
---

# Tasks: Super Admin SaaS App

**Input**: Design documents from `specs/011-super-admin-saas-app/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Tests**: **Obrigatórios** — TDD full-stack (constitution II + plan.md + `contracts/test-strategy.md`): Jest (API unit + e2e) e Vitest/RTL/MSW (client). Caminhos relativos à raiz `ci-v2/`.

**Organization**: US1 (P1) → US2 (P2) → … → US6 (P6). API antes do client em cada story quando houver dependência de contrato.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Pode executar em paralelo (arquivos diferentes, sem dependências pendentes)
- **[Story]**: User story da spec (US1–US6)

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Scaffold do app `@ci/admin-saas` e módulo API vazio

- [X] T001 Criar `ci-client-v2/apps/admin-saas/package.json` (`@ci/admin-saas`) espelhando deps de `apps/web` (React 19, Vite 8, Vitest, MSW, `@ci/ui`, `@ci/domain`)
- [X] T002 [P] Criar `ci-client-v2/apps/admin-saas/vite.config.ts` com port `5174`, alias `@/`, `envDir` monorepo root
- [X] T003 [P] Criar `ci-client-v2/apps/admin-saas/tsconfig.json`, `tsconfig.app.json`, `tsconfig.node.json` estendendo `@ci/typescript-config`
- [X] T004 [P] Criar `ci-client-v2/apps/admin-saas/index.html` e `ci-client-v2/apps/admin-saas/src/app/main.tsx` (bootstrap mínimo)
- [X] T005 Adicionar `@ci/admin-saas` em workspaces e scripts `dev:admin` / filtro turbo em `ci-client-v2/package.json`
- [X] T006 [P] Documentar `VITE_API_URL` em `ci-client-v2/apps/admin-saas/.env.example`
- [X] T007 Criar scaffold `ci-api-v2/src/modules/admin-plataforma/admin-plataforma.module.ts` e registrar `AdminPlataformaModule` em `ci-api-v2/src/app.module.ts`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Schemas base, interceptor ALS, infra client (router, api client, MSW, vitest) — **bloqueia todas as user stories**

**⚠️ CRITICAL**: Nenhuma user story começa antes desta fase

- [X] T008 [P] Implementar `ci-api-v2/src/common/interceptors/admin-tenant-context.interceptor.ts` — resolve `:tenantId` (UUID/slug) e executa handler em `requestContext.run({ tenantId })`
- [X] T009 [P] Escrever testes (RED) `ci-api-v2/src/common/interceptors/admin-tenant-context.interceptor.spec.ts` — tenant válido/inválido
- [X] T010 [P] Implementar `ci-api-v2/src/modules/admin-plataforma/admin-plataforma.schemas.ts` — schemas Zod auth + enums compartilhados (export mínimo inicial)
- [X] T011 [P] Escrever testes (RED) `ci-api-v2/src/modules/admin-plataforma/admin-plataforma.schemas.spec.ts` — validação AdminLoginBody, CreateTenantBody slug
- [X] T012 [P] Criar `ci-client-v2/apps/admin-saas/vitest.config.ts` e `ci-client-v2/apps/admin-saas/vitest.setup.ts` (jsdom + jest-dom)
- [X] T013 [P] Criar `ci-client-v2/apps/admin-saas/src/modules/shared/lib/api-client.ts` — fetch wrapper com `Authorization` Bearer, **sem** `X-Tenant-ID`
- [X] T014 [P] Criar `ci-client-v2/apps/admin-saas/src/test/msw/server.ts` e handlers skeleton em `ci-client-v2/apps/admin-saas/src/test/msw/handlers/admin-plataforma.ts`
- [X] T015 Criar `ci-client-v2/apps/admin-saas/src/app/providers.tsx` e `ci-client-v2/apps/admin-saas/src/app/router.tsx` — rotas placeholder `/login`, `/`
- [X] T016 GREEN em T009 (interceptor) e T011 (schemas) após implementação

**Checkpoint**: Módulo API registrado; interceptor testado; client bootstrapped com vitest

---

## Phase 3: User Story 1 — Login e shell do Super Admin (Priority: P1) 🎯 MVP

**Goal**: Login dedicado sem tenant, JWT admin_saas, shell com nav Admins/Tenants, rotas protegidas

**Independent Test**: `POST /admin/auth/login` sem X-Tenant-ID → 200; app `5174/login` → dashboard com sidebar (CT-E2E-001, CT-JRN-001, CT-UI-001/002)

### Tests for User Story 1 (TDD — RED first)

- [X] T017 [P] [US1] Escrever testes (RED) `ci-api-v2/src/modules/admin-plataforma/use-cases/login-admin-saas.use-case.spec.ts` — CT-API-001
- [X] T018 [P] [US1] Escrever testes (RED) `ci-api-v2/test/admin-plataforma.e2e-spec.ts` — CT-E2E-001, CT-E2E-002, CT-E2E-003 (login + 401 sem token)
- [X] T019 [P] [US1] Escrever testes (RED) `ci-client-v2/apps/admin-saas/src/modules/auth/__tests__/LoginPage.test.tsx` — CT-UI-001
- [X] T020 [P] [US1] Escrever testes (RED) `ci-client-v2/apps/admin-saas/src/modules/shell/__tests__/ProtectedRoute.test.tsx` — CT-UI-002
- [X] T021 [P] [US1] Escrever testes (RED) `ci-client-v2/apps/admin-saas/src/modules/auth/__tests__/login-journey.e2e.test.tsx` — CT-JRN-001 (MSW + MemoryRouter)

### Implementation for User Story 1 — API

- [X] T022 [P] [US1] Criar `ci-api-v2/src/modules/admin-plataforma/repository/find-admin-by-email.repository.ts`
- [X] T023 [US1] Implementar `ci-api-v2/src/modules/admin-plataforma/use-cases/login-admin-saas.use-case.ts` — JWT `tenantId: "platform"`, role `admin_saas` (GREEN T017)
- [X] T024 [P] [US1] Implementar `ci-api-v2/src/modules/admin-plataforma/use-cases/get-admin-me.use-case.ts`
- [X] T025 [US1] Implementar `ci-api-v2/src/modules/admin-plataforma/admin-auth.controller.ts` — `POST /admin/auth/login` (`@Public` `@SkipTenant`), `GET /admin/auth/me` (`@SkipTenant` `@Roles(admin_saas)`)
- [X] T026 [US1] Wire providers no `ci-api-v2/src/modules/admin-plataforma/admin-plataforma.module.ts` (GREEN T018)

### Implementation for User Story 1 — Client

- [X] T027 [P] [US1] Implementar `ci-client-v2/apps/admin-saas/src/modules/auth/context/AuthContext.tsx` — token `sessionStorage`, login/logout
- [X] T028 [P] [US1] Implementar `ci-client-v2/apps/admin-saas/src/modules/auth/api/auth.ts` — `login`, `getMe`
- [X] T029 [P] [US1] Implementar `ci-client-v2/apps/admin-saas/src/modules/shell/components/ProtectedRoute.tsx`
- [X] T030 [P] [US1] Implementar `ci-client-v2/apps/admin-saas/src/modules/shell/components/AdminShell.tsx` — sidebar Admins, Tenants, Perfil, Logout; paleta Mint
- [X] T031 [US1] Implementar `ci-client-v2/apps/admin-saas/src/modules/auth/pages/LoginPage.tsx` — e-mail/senha, sem tenant, erro genérico (GREEN T019)
- [X] T032 [US1] Implementar `ci-client-v2/apps/admin-saas/src/modules/shell/pages/DashboardPage.tsx` — links rápidos Admins/Tenants
- [X] T033 [US1] Atualizar `ci-client-v2/apps/admin-saas/src/app/router.tsx` — `/login` public, `/` protected com AdminShell (GREEN T020, T021)
- [X] T034 [US1] Completar MSW handlers login/me em `ci-client-v2/apps/admin-saas/src/test/msw/handlers/admin-plataforma.ts`

**Checkpoint**: MVP — super admin autentica no app dedicado e vê shell navegável

---

## Phase 4: User Story 2 — Gerenciamento de super admins (Priority: P2)

**Goal**: CRUD super admins, reset senha, perfil próprio, bloqueio último admin ativo

**Independent Test**: Listar/criar/editar admin; reset senha; PATCH password perfil; 409 LAST_ADMIN_ACTIVE (CT-API-002…005, CT-E2E-004 parcial, CT-UI-003)

### Tests for User Story 2 (TDD — RED first)

- [X] T035 [P] [US2] Escrever testes (RED) `ci-api-v2/src/modules/admin-plataforma/use-cases/create-admin.use-case.spec.ts` — CT-API-002
- [X] T036 [P] [US2] Escrever testes (RED) `ci-api-v2/src/modules/admin-plataforma/use-cases/update-admin.use-case.spec.ts` — CT-API-003
- [X] T037 [P] [US2] Escrever testes (RED) `ci-api-v2/src/modules/admin-plataforma/use-cases/reset-admin-password.use-case.spec.ts` — CT-API-004
- [X] T038 [P] [US2] Escrever testes (RED) `ci-api-v2/src/modules/admin-plataforma/use-cases/change-own-password.use-case.spec.ts` — CT-API-005
- [X] T039 [P] [US2] Estender (RED) `ci-api-v2/test/admin-plataforma.e2e-spec.ts` — CRUD admins, CT-E2E-004 (403 token tenant user)
- [X] T040 [P] [US2] Escrever testes (RED) `ci-client-v2/apps/admin-saas/src/modules/admin-plataforma/__tests__/AdminsListPage.test.tsx` — CT-UI-003

### Implementation for User Story 2 — API

- [X] T041 [P] [US2] Implementar repositories em `ci-api-v2/src/modules/admin-plataforma/repository/admin-plataforma.repositories.ts` — list, findById, create, update, countActive
- [X] T042 [P] [US2] Implementar `ci-api-v2/src/modules/admin-plataforma/use-cases/list-admins.use-case.ts`
- [X] T043 [P] [US2] Implementar `ci-api-v2/src/modules/admin-plataforma/use-cases/create-admin.use-case.ts` (GREEN T035)
- [X] T044 [P] [US2] Implementar `ci-api-v2/src/modules/admin-plataforma/use-cases/update-admin.use-case.ts` (GREEN T036)
- [X] T045 [P] [US2] Implementar `ci-api-v2/src/modules/admin-plataforma/use-cases/reset-admin-password.use-case.ts` (GREEN T037)
- [X] T046 [US2] Implementar `ci-api-v2/src/modules/admin-plataforma/use-cases/change-own-password.use-case.ts` (GREEN T038)
- [X] T047 [US2] Estender `ci-api-v2/src/modules/admin-plataforma/admin-plataforma.schemas.ts` — CreateAdminBody, UpdateAdminBody, ResetAdminPasswordBody, ChangeOwnPasswordBody
- [X] T048 [US2] Implementar endpoints admins em `ci-api-v2/src/modules/admin-plataforma/admin-plataforma.controller.ts` — GET/POST/PATCH `/admin/admins`, POST reset-password; PATCH `/admin/auth/password` (GREEN T039)

### Implementation for User Story 2 — Client

- [X] T049 [P] [US2] Implementar `ci-client-v2/apps/admin-saas/src/modules/admin-plataforma/api/admins.ts`
- [X] T050 [P] [US2] Implementar `ci-client-v2/apps/admin-saas/src/modules/admin-plataforma/pages/AdminsListPage.tsx` (GREEN T040)
- [X] T051 [US2] Implementar `ci-client-v2/apps/admin-saas/src/modules/admin-plataforma/pages/AdminFormPage.tsx` — create/edit + dialog reset senha
- [X] T052 [US2] Implementar `ci-client-v2/apps/admin-saas/src/modules/auth/pages/ProfilePage.tsx` — alterar própria senha
- [X] T053 [US2] Registrar rotas `/admins`, `/admins/new`, `/admins/:id/edit`, `/profile` em `ci-client-v2/apps/admin-saas/src/app/router.tsx`

**Checkpoint**: Governança do time SaaS operacional sem depender de tenants

---

## Phase 5: User Story 3 — Gerenciamento de tenants — dados (Priority: P3)

**Goal**: CRUD tenants (nome, slug, status); rejeitar slug duplicado; tenant inativo bloqueia login tenant app

**Independent Test**: Criar/listar/editar/desativar tenant; slug conflict 409 (CT-API-006/007, CT-E2E-005 parcial, CT-UI-004, CT-JRN-002)

### Tests for User Story 3 (TDD — RED first)

- [X] T054 [P] [US3] Escrever testes (RED) `ci-api-v2/src/modules/admin-plataforma/use-cases/create-tenant.use-case.spec.ts` — CT-API-006
- [X] T055 [P] [US3] Escrever testes (RED) `ci-api-v2/src/modules/admin-plataforma/use-cases/update-tenant.use-case.spec.ts` — CT-API-007
- [X] T056 [P] [US3] Escrever testes (RED) `ci-api-v2/src/modules/admin-plataforma/use-cases/list-tenants.use-case.spec.ts`
- [X] T057 [P] [US3] Estender (RED) `ci-api-v2/test/admin-plataforma.e2e-spec.ts` — CRUD tenants, CT-E2E-007 tenant inativo
- [X] T058 [P] [US3] Escrever testes (RED) `ci-client-v2/apps/admin-saas/src/modules/admin-plataforma/__tests__/TenantsListPage.test.tsx` — CT-UI-004
- [X] T059 [P] [US3] Escrever testes (RED) `ci-client-v2/apps/admin-saas/src/modules/admin-plataforma/__tests__/create-tenant-journey.e2e.test.tsx` — CT-JRN-002

### Implementation for User Story 3 — API

- [X] T060 [P] [US3] Implementar `ci-api-v2/src/modules/admin-plataforma/repository/tenant-admin.repositories.ts` — list, findByIdOrSlug, create, update, slugExists
- [X] T061 [P] [US3] Implementar `ci-api-v2/src/modules/admin-plataforma/use-cases/list-tenants.use-case.ts` (GREEN T056)
- [X] T062 [P] [US3] Implementar `ci-api-v2/src/modules/admin-plataforma/use-cases/create-tenant.use-case.ts` — side-effect 4 TenantLicenca (GREEN T054)
- [X] T063 [P] [US3] Implementar `ci-api-v2/src/modules/admin-plataforma/use-cases/get-tenant-detail.use-case.ts`
- [X] T064 [US3] Implementar `ci-api-v2/src/modules/admin-plataforma/use-cases/update-tenant.use-case.ts` (GREEN T055)
- [X] T065 [US3] Estender schemas e controller em `ci-api-v2/src/modules/admin-plataforma/admin-plataforma.controller.ts` — GET/POST `/admin/tenants`, GET/PATCH `/admin/tenants/:tenantId` (GREEN T057)

### Implementation for User Story 3 — Client

- [X] T066 [P] [US3] Implementar `ci-client-v2/apps/admin-saas/src/modules/admin-plataforma/api/tenants.ts`
- [X] T067 [P] [US3] Implementar `ci-client-v2/apps/admin-saas/src/modules/admin-plataforma/pages/TenantsListPage.tsx` (GREEN T058)
- [X] T068 [US3] Implementar `ci-client-v2/apps/admin-saas/src/modules/admin-plataforma/pages/TenantFormPage.tsx` — create/edit
- [X] T069 [US3] Implementar `ci-client-v2/apps/admin-saas/src/modules/admin-plataforma/pages/TenantDetailPage.tsx` — aba Dados (GREEN T059)
- [X] T070 [US3] Registrar rotas `/tenants`, `/tenants/new`, `/tenants/:tenantId`, `/tenants/:tenantId/edit` em `ci-client-v2/apps/admin-saas/src/app/router.tsx`

**Checkpoint**: Provisionamento de tenants end-to-end (dados)

---

## Phase 6: User Story 4 — Licenças por tenant (Priority: P4)

**Goal**: Visualizar e toggle 4 licenças canônicas por tenant

**Independent Test**: Detalhe tenant exibe Carvalho, Pau-Brasil, Jatobá, Cedro; PATCH toggle persiste (CT-API-008, CT-UI-005, CT-JRN-003)

### Tests for User Story 4 (TDD — RED first)

- [X] T071 [P] [US4] Escrever testes (RED) `ci-api-v2/src/modules/admin-plataforma/use-cases/toggle-tenant-licenca.use-case.spec.ts` — CT-API-008
- [X] T072 [P] [US4] Estender (RED) `ci-api-v2/test/admin-plataforma.e2e-spec.ts` — PATCH licença
- [X] T073 [P] [US4] Escrever testes (RED) `ci-client-v2/apps/admin-saas/src/modules/admin-plataforma/__tests__/TenantDetailPage.licencas.test.tsx` — CT-UI-005
- [X] T074 [P] [US4] Escrever testes (RED) `ci-client-v2/apps/admin-saas/src/modules/admin-plataforma/__tests__/toggle-licenca-journey.e2e.test.tsx` — CT-JRN-003

### Implementation for User Story 4 — API

- [X] T075 [P] [US4] Implementar `ci-api-v2/src/modules/admin-plataforma/repository/tenant-licenca.repositories.ts`
- [X] T076 [US4] Implementar `ci-api-v2/src/modules/admin-plataforma/use-cases/toggle-tenant-licenca.use-case.ts` (GREEN T071)
- [X] T077 [US4] Estender `get-tenant-detail.use-case.ts` para incluir licenças com labels PT-BR
- [X] T078 [US4] Adicionar `PATCH /admin/tenants/:tenantId/licencas/:licencaSlug` em `ci-api-v2/src/modules/admin-plataforma/admin-plataforma.controller.ts` (GREEN T072)

### Implementation for User Story 4 — Client

- [X] T079 [P] [US4] Estender `ci-client-v2/apps/admin-saas/src/modules/admin-plataforma/api/tenants.ts` — toggleLicenca
- [X] T080 [US4] Adicionar aba Licenças em `ci-client-v2/apps/admin-saas/src/modules/admin-plataforma/pages/TenantDetailPage.tsx` — 4 toggles + tooltip (GREEN T073, T074)

**Checkpoint**: Controle de licenças por tenant operacional

---

## Phase 7: User Story 5 — Setores do tenant selecionado (Priority: P5)

**Goal**: CRUD setores cross-tenant via path param; exige tenant selecionado

**Independent Test**: `/admin/tenants/demo/setores` list/create/update/delete; interceptor ALS (CT-API-009)

### Tests for User Story 5 (TDD — RED first)

- [X] T081 [P] [US5] Escrever testes (RED) `ci-api-v2/src/modules/admin-plataforma/use-cases/admin-setor.use-case.spec.ts` — CT-API-009
- [X] T082 [P] [US5] Estender (RED) `ci-api-v2/test/admin-plataforma.e2e-spec.ts` — setores scoped
- [X] T083 [P] [US5] Escrever testes (RED) `ci-client-v2/apps/admin-saas/src/modules/admin-plataforma/__tests__/TenantSetoresPage.test.tsx`

### Implementation for User Story 5 — API

- [X] T084 [P] [US5] Implementar use-cases setor em `ci-api-v2/src/modules/admin-plataforma/use-cases/admin-setor.use-cases.ts` — list/create/update/remove (delega Prisma com ALS)
- [X] T085 [US5] Implementar `ci-api-v2/src/modules/admin-plataforma/admin-tenant-setor.controller.ts` com `@UseInterceptors(AdminTenantContextInterceptor)` (GREEN T081, T082)

### Implementation for User Story 5 — Client

- [X] T086 [P] [US5] Implementar `ci-client-v2/apps/admin-saas/src/modules/admin-plataforma/api/setores.ts`
- [X] T087 [US5] Implementar `ci-client-v2/apps/admin-saas/src/modules/admin-plataforma/pages/TenantSetoresPage.tsx` — header tenant context (GREEN T083)
- [X] T088 [US5] Registrar rota `/tenants/:tenantId/setores` e link na aba Setores do TenantDetailPage

**Checkpoint**: Estrutura organizacional configurável cross-tenant

---

## Phase 8: User Story 6 — Usuários do tenant selecionado (Priority: P6)

**Goal**: CRUD usuários tenant; roles sem admin_saas; reset senha

**Independent Test**: Criar user admin_plataforma; rejeitar admin_saas role; email dup (CT-API-010, CT-E2E-006, CT-UI-006)

### Tests for User Story 6 (TDD — RED first)

- [X] T089 [P] [US6] Escrever testes (RED) `ci-api-v2/src/modules/admin-plataforma/use-cases/admin-user.use-case.spec.ts` — CT-API-010
- [X] T090 [P] [US6] Estender (RED) `ci-api-v2/test/admin-plataforma.e2e-spec.ts` — CT-E2E-006
- [X] T091 [P] [US6] Escrever testes (RED) `ci-client-v2/apps/admin-saas/src/modules/admin-plataforma/__tests__/TenantUsersPage.test.tsx` — CT-UI-006

### Implementation for User Story 6 — API

- [X] T092 [P] [US6] Implementar use-cases user em `ci-api-v2/src/modules/admin-plataforma/use-cases/admin-user.use-cases.ts` — list/create/update/remove/reset-password; filtrar roles
- [X] T093 [US6] Implementar `ci-api-v2/src/modules/admin-plataforma/admin-tenant-user.controller.ts` com interceptor ALS (GREEN T089, T090)

### Implementation for User Story 6 — Client

- [X] T094 [P] [US6] Implementar `ci-client-v2/apps/admin-saas/src/modules/admin-plataforma/api/users.ts`
- [X] T095 [US6] Implementar `ci-client-v2/apps/admin-saas/src/modules/admin-plataforma/pages/TenantUsersPage.tsx` — select roles Usuário/Chefe/Admin plataforma (GREEN T091)
- [X] T096 [US6] Registrar rota `/tenants/:tenantId/users` e link na aba Usuários do TenantDetailPage

**Checkpoint**: Ciclo completo onboarding tenant (dados → licenças → setores → pessoas)

---

## Phase 9: Polish & Cross-Cutting Concerns

**Purpose**: CORS, build, quickstart, isolamento credenciais, documentação

- [X] T097 [P] Configurar CORS Fastify para origin `http://localhost:5174` em `ci-api-v2` (env ou bootstrap)
- [X] T098 [P] Escrever testes (RED/GREEN) isolamento credenciais em `ci-api-v2/test/admin-plataforma.e2e-spec.ts` — saas@ no tenant login, tenant user no admin login
- [X] T099 [P] Adicionar script `verify-module-layout` ou checklist espelho API em `ci-client-v2/apps/admin-saas/scripts/` (opcional, espelhar web)
- [X] T100 Executar validação `specs/011-super-admin-saas-app/quickstart.md` — checklist SC-001…SC-006 manual
- [X] T101 [P] `npm run test -- admin-plataforma` e `npm run test:e2e -- admin-plataforma` green em `ci-api-v2`
- [X] T102 [P] `npm run test` e `npm run typecheck` green em `ci-client-v2/apps/admin-saas`
- [X] T103 `npm run build --filter=@ci/admin-saas` — artefato `apps/admin-saas/dist/`
- [X] T104 [P] Escrever teste (RED/GREEN) `ci-client-v2/apps/admin-saas/src/modules/auth/__tests__/logout-journey.e2e.test.tsx` — CT-JRN-004

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Sem dependências
- **Foundational (Phase 2)**: Depende Setup — **BLOQUEIA** US1–US6
- **US1 (Phase 3)**: Depende Foundational — **MVP**
- **US2 (Phase 4)**: Depende US1 (auth token + shell)
- **US3 (Phase 5)**: Depende US1; independente de US2
- **US4 (Phase 6)**: Depende US3 (tenant detail)
- **US5 (Phase 7)**: Depende US3 (tenant selecionado); interceptor da Phase 2
- **US6 (Phase 8)**: Depende US5 (setores para vínculos user); pode paralelizar API com US5 após US3
- **Polish (Phase 9)**: Depende stories desejadas completas

### User Story Dependencies

| Story | Depende de | Independente testável após |
|-------|------------|----------------------------|
| US1 | Foundational | Login + shell |
| US2 | US1 | CRUD admins |
| US3 | US1 | CRUD tenants |
| US4 | US3 | Toggle licenças |
| US5 | US3 | CRUD setores |
| US6 | US3, US5 (setorIds) | CRUD users |

### Parallel Opportunities

- Phase 1: T002, T003, T004, T006 em paralelo
- Phase 2: T008–T014 em paralelo (após T007)
- Por story: todos os testes RED `[P]` antes da implementação
- US2 API (T041–T048) paralelo com US3 API (T060–T065) **após US1** — times diferentes
- US5 e US6 API paralelizáveis após US3

### Parallel Example: User Story 1

```bash
# RED tests em paralelo:
T017 login-admin-saas.use-case.spec.ts
T018 admin-plataforma.e2e-spec.ts
T019 LoginPage.test.tsx
T020 ProtectedRoute.test.tsx
T021 login-journey.e2e.test.tsx

# API impl paralelo (após T022):
T023 login use-case
T024 get-admin-me use-case
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Phase 1 Setup
2. Phase 2 Foundational
3. Phase 3 US1 (API login + client shell)
4. **STOP** — validar quickstart P1 + CT-E2E-001

### Incremental Delivery

1. US1 → login/shell (MVP)
2. US2 → admins governance
3. US3 → tenants
4. US4 → licenças
5. US5 → setores
6. US6 → usuários (provisionamento completo SC-002)
7. Phase 9 polish

### Suggested MVP Scope

**User Story 1 (P1)** — 18 tasks (T017–T034) após Setup + Foundational (T001–T016)

**Total tasks**: 104

---

## Notes

- Seguir layout canônico API: 1 use-case = 1 arquivo; 1 repository op = 1 arquivo (`modules/permissao/` referência)
- Nunca enviar `X-Tenant-ID` no client admin-saas
- Nunca permitir role `admin_saas` em create/update user tenant
- `@ci/web` permanece inalterado (FR-028)
- Commit sugerido após cada checkpoint de user story
