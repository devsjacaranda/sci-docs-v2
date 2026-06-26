# Research: Super Admin SaaS App

**Feature**: 011-super-admin-saas-app  
**Date**: 2026-06-23  
**References**: [spec.md](./spec.md) · [plan.md](./plan.md) · `auth-patterns` · `ci-api-v2/CONTEXT.md`

## R1 — App separado vs rotas no @ci/web

**Decision**: Novo app `apps/admin-saas` (`@ci/admin-saas`), Vite port **5174**, build artefato `apps/admin-saas/dist/`.

**Rationale**: Spec FR-001/FR-002 exigem login sem tenant e público exclusivo super admin. App tenant carrega shell de licenças, `X-Tenant-ID` e roles tenant — acoplar admin SaaS aumentaria complexidade de routing, auth context e deploy.

**Alternatives considered**:
- Rotas `/saas/*` em `@ci/web` — rejeitado: mesmo bundle/deploy, risco de confusão de credenciais e tenant header.
- Micro-frontend — rejeitado: over-engineering para v1.

---

## R2 — Auth dedicada sem X-Tenant-ID

**Decision**:
- `POST /admin/auth/login` — `@Public()` + `@SkipTenant()`; valida apenas `AdminPlataforma`.
- `GET /admin/auth/me`, `PATCH /admin/auth/password` — `@SkipTenant()` + `@Roles(admin_saas)`.
- JWT payload: `{ sub, role: admin_saas, tenantId: "platform" }` (sentinel fixo).
- Client admin **nunca** envia `X-Tenant-ID`.

**Rationale**: `TenantGuard` já suporta `@SkipTenant()` e `@Public()` sem tenant ([`tenant.guard.ts`](../../../ci-api-v2/src/common/guards/tenant.guard.ts)). Sentinel evita refatorar guards legados que leem `tenantId` do JWT.

**Alternatives considered**:
- Tenant slug reservado `platform` no seed — rejeitado: mistura super admin com entidade Tenant real.
- Remover `tenantId` do JWT admin — rejeitado: blast radius em `auth.service.getMe` e interceptors.

---

## R3 — Prefixo e organização API

**Decision**: Módulo `admin-plataforma`; prefixo global `/admin`.

| Controller | Prefixo | Escopo |
|------------|---------|--------|
| `AdminAuthController` | `/admin/auth` | login, me, password |
| `AdminPlataformaController` | `/admin` | admins CRUD, tenants CRUD, licenças |
| `AdminTenantSetorController` | `/admin/tenants/:tenantId/setores` | setores |
| `AdminTenantUserController` | `/admin/tenants/:tenantId/users` | usuários |

Todos os handlers protegidos: `@Roles(UserRole.admin_saas)` exceto login público.

**Rationale**: Namespace claro; LicencaGuard e ModuloPermissaoGuard passam quando não há `@RequireLicenca` / `@RequireModulo`. Futuro `@SkipModuloPermissao` se necessário no controller class level.

**Alternatives considered**:
- Reutilizar `/auth/login` sem tenant — rejeitado: comportamento atual exige tenant ativo; manter compatibilidade tenant app.

---

## R4 — Cross-tenant ALS para setores/usuários

**Decision**: `AdminTenantContextInterceptor` aplicado em controllers com `:tenantId`:
1. Valida UUID/slug e existência do tenant (ativo ou inativo — super admin vê inativos).
2. Executa handler dentro de `requestContext.run({ tenantId: resolved.id, userId, role })`.
3. Use-cases admin delegam a repositories espelhando lógica `setor`/`user-admin` existente.

**Rationale**: Constitution IV — ALS em vez de `tenantId` solto. Paridade funcional com [`setor.service.ts`](../../../ci-api-v2/src/modules/setor/setor.service.ts) e [`user-admin.service.ts`](../../../ci-api-v2/src/modules/setor/user-admin.service.ts).

**Alternatives considered**:
- Importar `SetorService` direto no admin controller — rejeitado: services legados acoplados a `@Roles(admin_plataforma)` no controller tenant.
- Passar `tenantId` em cada use-case param — rejeitado: viola convention ALS.

---

## R5 — Provisionamento de licenças na criação de tenant

**Decision**: `create-tenant.use-case` cria tenant + 4 registros `TenantLicenca` (Carvalho, Pau-Brasil, Jatobá, Cedro) com `active: true` por padrão.

**Rationale**: Spec US4 — tenant recém-criado já exibe quatro licenças. Alinha com seed existente e [`licencas-canonicas.md`](../../../.cursor/docs/licencas-canonicas.md) — conjunto fixo de 4 licenças; toggle controla disponibilidade operacional.

**Alternatives considered**:
- Licenças lazy on first access — rejeitado: UI detalhe tenant espera lista completa.

---

## R6 — Regras de negócio admin

**Decision**:
- Desativar último `AdminPlataforma` ativo → `409 Conflict` com código `LAST_ADMIN_ACTIVE`.
- Slug tenant duplicado → `409` código `TENANT_SLUG_CONFLICT`.
- E-mail admin duplicado → `409` código `ADMIN_EMAIL_CONFLICT`.
- E-mail user duplicado no tenant → `409` código `USER_EMAIL_CONFLICT`.
- Roles atribuíveis a users tenant via admin: `user`, `chefe_setor`, `admin_plataforma` — **nunca** `admin_saas`.
- Soft delete setores/users via extension Prisma existente.

**Rationale**: Spec edge cases + segurança — super admin role só via tabela `AdminPlataforma`.

---

## R7 — UI/UX admin app

**Decision**: Design system Mint (`mint-palette.mdc`); shell sidebar com seções **Dashboard**, **Admins**, **Tenants**; detalhe tenant com abas **Dados**, **Licenças**, **Setores**, **Usuários**; login minimalista (sem branding tenant).

**Rationale**: Skill `ui-ux-pro-max`; operadores internos SaaS; desktop-first com responsividade básica.

**Alternatives considered**:
- Reutilizar `AuthLayout` do `@ci/web` — aceito como inspiração visual, implementação separada no admin-saas para evitar dependência cross-app.

---

## R8 — Turbo e scripts dev

**Decision**:
- `@ci/admin-saas` adicionado a workspaces.
- Root scripts: `dev:admin` → `turbo run dev --filter=@ci/admin-saas`.
- Env: `VITE_API_URL` compartilhado com web (`.env` monorepo root).

**Rationale**: Padrão Turborepo existente; API única `ci-api-v2`.

---

## R9 — Separação credenciais tenant vs SaaS

**Decision**: `POST /auth/login` (tenant app) continua exigindo tenant; login admin SaaS **não** autentica via rota tenant mesmo se e-mail existir em `AdminPlataforma`. Inversamente, credenciais tenant não autenticam em `/admin/auth/login`.

**Rationale**: Spec edge cases — credenciais SaaS válidas apenas no app dedicado.

**Implementation note**: Rotas distintas já separam lookup (`AdminPlataforma` vs `User`).
