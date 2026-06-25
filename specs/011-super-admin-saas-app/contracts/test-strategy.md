# Contract: Test Strategy — Super Admin SaaS App

**Feature**: 011-super-admin-saas-app  
**References**: [plan.md](../plan.md) · constitution II · [rest-api-admin-plataforma.md](./rest-api-admin-plataforma.md) · [client-admin-saas-ui.md](./client-admin-saas-ui.md)

## Princípio: TDD full-stack

API: Jest RED → GREEN antes de controllers. Client: Vitest RED → GREEN antes de pages. E2E API valida contratos REST; journey UI usa MSW.

---

## Escopo de testes

| Camada | API | Client |
|--------|-----|--------|
| Unitário use-case | ✅ | ✅ lib/validation |
| Schemas Zod | ✅ | — |
| Guards/interceptor | ✅ | — |
| Controller integration | ✅ e2e | — |
| Componente RTL | — | ✅ |
| Contrato UI | — | ✅ copy, rotas |
| Journey E2E UI | — | ✅ MSW + MemoryRouter |
| Playwright/browser | — | ❌ out of scope v1 |

---

## API (`ci-api-v2`)

### Infraestrutura

| Ferramenta | Uso |
|------------|-----|
| Jest | runner |
| `@nestjs/testing` | module testing |
| supertest | e2e HTTP |
| Prisma mock / test DB | e2e isolado |

**Scripts**:

```powershell
cd ci-api-v2
npm test -- admin-plataforma
npm run test:e2e -- admin-plataforma
```

### Matriz — use-cases (unit)

| ID | Use-case | Casos mínimos |
|----|----------|---------------|
| CT-API-001 | `login-admin-saas` | credenciais ok; inválidas; admin inativo; não lookup User |
| CT-API-002 | `create-admin` | ok; email duplicado 409 |
| CT-API-003 | `update-admin` | ok; LAST_ADMIN_ACTIVE |
| CT-API-004 | `reset-admin-password` | ok; hash gerado |
| CT-API-005 | `change-own-password` | ok; senha atual errada 401 |
| CT-API-006 | `create-tenant` | ok + 4 licenças; slug conflict |
| CT-API-007 | `update-tenant` | desativar; slug conflict |
| CT-API-008 | `toggle-tenant-licenca` | toggle; licença inválida 404 |
| CT-API-009 | setor CRUD (admin) | create/list/update/delete scoped |
| CT-API-010 | user CRUD (admin) | create; role admin_saas rejeitado; email dup |

### Matriz — e2e (`admin-plataforma.e2e-spec.ts`)

| ID | Cenário | Assert |
|----|---------|--------|
| CT-E2E-001 | POST /admin/auth/login sem X-Tenant-ID | 200 + JWT admin_saas |
| CT-E2E-002 | POST /admin/auth/login user tenant | 401 |
| CT-E2E-003 | GET /admin/admins sem token | 401 |
| CT-E2E-004 | GET /admin/admins com token tenant user | 403 |
| CT-E2E-005 | CRUD tenant + licenças | 201/200 |
| CT-E2E-006 | POST /admin/tenants/:id/users admin_plataforma | 201 |
| CT-E2E-007 | Tenant inativo → login tenant app falha | 404/401 |

---

## Client (`ci-client-v2/apps/admin-saas`)

### Infraestrutura

| Ferramenta | Uso |
|------------|-----|
| Vitest 3 | runner |
| RTL + user-event | interação |
| MSW 2 | mock `/admin/*` |
| jsdom | DOM |

**Scripts**:

```powershell
cd ci-client-v2/apps/admin-saas
npm run test
npm run typecheck
```

### Matriz — componentes

| ID | Componente | Assert mínimo |
|----|------------|---------------|
| CT-UI-001 | `LoginPage` | sem campo tenant; submit chama login |
| CT-UI-002 | `ProtectedRoute` | redirect /login |
| CT-UI-003 | `AdminsListPage` | colunas email/status |
| CT-UI-004 | `TenantsListPage` | badge inativo visível |
| CT-UI-005 | `TenantDetailPage` | 4 licenças com labels canônicos |
| CT-UI-006 | `TenantUsersPage` | roles sem admin_saas |

### Matriz — journey (MSW)

| ID | Journey | Assert |
|----|---------|--------|
| CT-JRN-001 | login → dashboard | nav Admins/Tenants |
| CT-JRN-002 | criar tenant | redirect detalhe |
| CT-JRN-003 | toggle licença | MSW PATCH + UI refresh |
| CT-JRN-004 | logout | token cleared |

---

## Ordem TDD recomendada (implement phase)

1. API schemas + login use-case + e2e login
2. API admins CRUD + e2e
3. API tenants + licenças + e2e
4. API setores/users scoped + e2e
5. Client scaffold + auth + login tests
6. Client admins pages
7. Client tenants + licenças
8. Client setores/users
9. quickstart manual validation

---

## Fixtures / seed

- Reutilizar seed `saas@ci.com` / `password123`
- Tenant `demo` existente para testes scoped
- MSW handlers em `apps/admin-saas/src/test/msw/handlers/admin-plataforma.ts`
