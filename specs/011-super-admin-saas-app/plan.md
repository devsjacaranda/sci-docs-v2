# Implementation Plan: Super Admin SaaS App

**Branch**: `011-super-admin-saas-app` | **Date**: 2026-06-23 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/011-super-admin-saas-app/spec.md`

## Summary

Entregar app SPA dedicado (`@ci/admin-saas`) para super admins da plataforma (`admin_saas` / `AdminPlataforma`) com login **sem tenant**, shell administrativo e CRUD cross-tenant de super admins, tenants, licenças, setores e usuários. Backend: novo módulo NestJS `admin-plataforma` em `ci-api-v2` com rotas prefixadas `/admin/*`, guards `@Roles(admin_saas)` + `@SkipTenant()` onde aplicável, e interceptor de contexto tenant via path param para operações scoped. Reutiliza pacotes `@ci/ui`, `@ci/domain` e paleta Mint; TDD obrigatório API (Jest) + client (Vitest/RTL).

**Abordagem**: auth dedicada (`POST /admin/auth/login`); gestão global sem ALS tenant; rotas aninhadas `/admin/tenants/:tenantId/setores|users` com `AdminTenantContextInterceptor` populando ALS para reuse de lógica Prisma; client espelha módulo API em `apps/admin-saas/src/modules/admin-plataforma/`.

## Technical Context

**Language/Version**: TypeScript 6.x; Node.js 20 LTS

**Primary Dependencies**:

| Pacote | Stack |
|--------|-------|
| **ci-api-v2** | NestJS 11, Fastify, Pino, Zod (nestjs-zod), Prisma 7, PostgreSQL, JWT, bcryptjs |
| **ci-client-v2** | React 19, Vite 8, Tailwind v4, shadcn/ui (`@ci/ui`), react-router-dom 7, Vitest 3, MSW 2 |

**Storage**: PostgreSQL — entidades existentes `AdminPlataforma`, `Tenant`, `TenantLicenca`, `Setor`, `User`, `UserSetor`, `ModuloSetor` (sem migration estrutural v1; ver [data-model.md](./data-model.md))

**Testing**:

| Camada | Local | Ferramentas |
|--------|-------|-------------|
| API unit | `ci-api-v2/src/modules/admin-plataforma/**/*.spec.ts` | Jest — use-cases, guards, schemas |
| API e2e | `ci-api-v2/test/admin-plataforma.e2e-spec.ts` | Jest + supertest — auth, CRUD, 403 |
| Client unit | `apps/admin-saas/src/modules/**/__tests__/` | Vitest — validação, mappers |
| Client component | `apps/admin-saas/src/modules/**/__tests__/` | Vitest + RTL |
| Client contract | `apps/admin-saas/src/modules/**/__tests__/*.contract.test.tsx` | Vitest — copy, rotas, labels |
| Client journey | `apps/admin-saas/src/modules/**/__tests__/*.e2e.test.tsx` | Vitest + MemoryRouter + MSW |

**Target Platform**: API Linux/container; SPA browser (desktop-first, responsivo)

**Project Type**: Full-stack (API independente + segundo app no monorepo Turborepo)

**Performance Goals**: Listagens admin < 500ms p95 em dev; login < 1s; provisionamento tenant (UI) conforme SC-002 (< 5 min operador)

**Constraints**:

- TDD obrigatório (Constitution II) — RED → GREEN → REFACTOR
- Zod only — sem class-validator
- Tenant via ALS em operações scoped — admin cross-tenant usa `:tenantId` no path + interceptor (Constitution IV)
- `@SkipTenant()` + `@Roles(admin_saas)` em rotas globais admin; LicencaGuard/ModuloPermissaoGuard não aplicam em `/admin/*`
- JWT admin_saas: `tenantId: "platform"` (sentinel) — sem header `X-Tenant-ID` no client admin
- App tenant `@ci/web` inalterado em escopo (FR-028)
- Skills: `auth-patterns`, `ui-ux-pro-max`, `vite-react-best-practices`, `testing-conventions`, `nestjs-module-scaffold`, `ci-api-arquitetura`

**Scale/Scope**: 1 novo app SPA (~12–15 páginas), 1 módulo API (~20 endpoints), 0 migrations Prisma v1, ~2 controllers auth+admin, reutilização lógica setor/user

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Princípio | Status | Notas |
|-----------|--------|-------|
| I. Spec-Driven | ✅ PASS | Spec 011 validada; plano segue fluxo |
| II. Test-First | ✅ PASS | Estratégia em [contracts/test-strategy.md](./contracts/test-strategy.md) |
| III. Stack fixa | ✅ PASS | NestJS 11 + Prisma 7 + React 19 + Vite 8 + shadcn |
| IV. Multi-tenant | ✅ PASS | ALS via interceptor em rotas `:tenantId`; sentinel `platform` para JWT global |
| IV. Licenças | ✅ PASS | Toggle `TenantLicenca.active`; nomenclatura canônica |
| V. Escopo mínimo | ✅ PASS | Módulo `admin-plataforma` + app `admin-saas`; setor/user via reuse |

**Post-design re-check**: Segundo app Turborepo justificado em Complexity Tracking (deploy/URL separados, público distinto). Layout use-case/repository no módulo admin segue referência `permissao/`. Interceptor ALS evita passar `tenantId` solto em use-cases. Sem violações adicionais.

## Project Structure

### Documentation (this feature)

```text
specs/011-super-admin-saas-app/
├── plan.md              # Este arquivo
├── research.md          # Decisões técnicas (Phase 0)
├── data-model.md        # Entidades e regras
├── quickstart.md        # Validação manual + comandos
├── contracts/
│   ├── rest-api-admin-plataforma.md
│   ├── client-admin-saas-ui.md
│   └── test-strategy.md
└── tasks.md             # Phase 2 — /speckit-tasks
```

### Source Code (repository root)

```text
ci-api-v2/
├── src/
│   ├── common/
│   │   ├── decorators/skip-tenant.decorator.ts    # existente — reuse
│   │   └── interceptors/
│   │       └── admin-tenant-context.interceptor.ts  # NEW — ALS from :tenantId
│   └── modules/
│       └── admin-plataforma/
│           ├── admin-plataforma.module.ts
│           ├── admin-plataforma.controller.ts       # admins + tenants + licencas
│           ├── admin-plataforma.schemas.ts
│           ├── admin-auth.controller.ts             # POST login, GET me, PATCH profile
│           ├── admin-tenant-setor.controller.ts     # /admin/tenants/:tenantId/setores
│           ├── admin-tenant-user.controller.ts      # /admin/tenants/:tenantId/users
│           ├── use-cases/
│           │   ├── login-admin-saas.use-case.ts
│           │   ├── list-admins.use-case.ts
│           │   ├── create-admin.use-case.ts
│           │   ├── update-admin.use-case.ts
│           │   ├── reset-admin-password.use-case.ts
│           │   ├── change-own-password.use-case.ts
│           │   ├── list-tenants.use-case.ts
│           │   ├── create-tenant.use-case.ts
│           │   ├── update-tenant.use-case.ts
│           │   ├── get-tenant-detail.use-case.ts
│           │   ├── toggle-tenant-licenca.use-case.ts
│           │   └── ... (setor/user delegates)
│           └── repository/
│               ├── admin-plataforma.repositories.ts
│               ├── tenant-admin.repositories.ts
│               └── tenant-licenca.repositories.ts
└── test/
    └── admin-plataforma.e2e-spec.ts

ci-client-v2/
├── apps/
│   ├── web/                                       # inalterado — app tenant
│   └── admin-saas/                                # NEW — @ci/admin-saas
│       ├── package.json
│       ├── vite.config.ts                         # port 5174
│       ├── index.html
│       └── src/
│           ├── app/
│           │   ├── main.tsx
│           │   ├── router.tsx
│           │   └── providers.tsx
│           └── modules/
│               ├── shell/                         # layout, nav, guards
│               │   ├── components/AdminShell.tsx
│               │   ├── components/ProtectedRoute.tsx
│               │   └── pages/DashboardPage.tsx
│               ├── auth/
│               │   ├── pages/LoginPage.tsx
│               │   ├── pages/ProfilePage.tsx
│               │   ├── api/auth.ts
│               │   └── context/AuthContext.tsx
│               └── admin-plataforma/
│                   ├── pages/
│                   │   ├── AdminsListPage.tsx
│                   │   ├── AdminFormPage.tsx
│                   │   ├── TenantsListPage.tsx
│                   │   ├── TenantDetailPage.tsx
│                   │   ├── TenantFormPage.tsx
│                   │   ├── TenantSetoresPage.tsx
│                   │   └── TenantUsersPage.tsx
│                   ├── components/
│                   ├── api/
│                   └── lib/
├── package.json                                   # scripts dev:admin, build
└── turbo.json                                     # pipeline @ci/admin-saas
```

**Structure Decision**: Segundo app em `apps/admin-saas` (`@ci/admin-saas`) deployável separado; módulos espelham API (`auth`, `admin-plataforma`, `shell`). API segue layout canônico use-case/repository em `modules/admin-plataforma/`. Rotas tenant-scoped aninhadas sob `/admin/tenants/:tenantId/` com interceptor ALS.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| Segundo app SPA no Turborepo | Super admin exige URL/porta/deploy separados do app tenant; credenciais e fluxo auth distintos (sem tenant) | Rotas `/admin` dentro de `@ci/web` misturaria públicos, exigiria tenant header workaround e aumentaria superfície de ataque no app cliente |
| Interceptor ALS cross-tenant | Constitution IV proíbe `tenantId` solto; reuse de queries Prisma tenant-scoped | Duplicar toda lógica setor/user em repositórios admin-only aumentaria drift vs módulo `setor` existente |
| JWT sentinel `tenantId: "platform"` | Guards e `getMe` existentes esperam `tenantId` no payload | Refatorar todos guards para tenant opcional teria blast radius em módulos legados |
