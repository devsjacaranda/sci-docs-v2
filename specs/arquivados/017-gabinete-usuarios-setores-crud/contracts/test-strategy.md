# Test Strategy: Gestão Institucional — Usuários e Setores

**Feature**: 017-gabinete-usuarios-setores-crud  
**Process**: TDD vertical slices ([tdd](../../../.cursor/skills/tdd/SKILL.md), [testing-conventions](../../../.cursor/skills/testing-conventions/SKILL.md))

## Princípios

- **Vertical slices**: 1 test → 1 implementação → repeat — **nunca** horizontal (todos tests depois todo código)
- Testes via **interface pública** (HTTP, component render, user events)
- API: Jest + Supertest; Client: Vitest + RTL + MSW

---

## API — ordem TDD sugerida

### Slice 1 — List users paginated (P1)

| RED | GREEN |
|-----|-------|
| `list-users.use-case.spec.ts` — returns page/limit/total, filters status active | `ListUsersUseCase` + repository |
| `setor.controller.spec.ts` GET `/users?page=1&limit=10` | wire controller |

### Slice 2 — Create user (P1)

| RED | GREEN |
|-----|-------|
| reject role `admin_plataforma` | Zod refine |
| reject duplicate email | use-case 409 |
| create with setorIds | `CreateUserUseCase` |

### Slice 3 — Inactivate / restore user (P1)

| RED | GREEN |
|-----|-------|
| DELETE sets deletedAt; login fails after | inactivate + auth integration |
| POST restore clears deletedAt; login works | restore use-case |
| forbid self-inactivate | 403 |
| forbid last admin inactivate | 403 |

### Slice 4 — Reset password (P1)

| RED | GREEN |
|-----|-------|
| POST reset-password updates hash | `ResetUserPasswordUseCase` |

### Slice 5 — InstitutionalAdminGuard (P1)

| RED | GREEN |
|-----|-------|
| GAB member allowed | guard |
| non-GAB user 403 | guard |
| admin_tenant bypass | guard |

### Slice 6 — Setores CRUD (P2)

Mirror slices 1–3 for `/setores`: list paginated, create, inactivate, restore, sigla duplicate.

---

## Client — ordem TDD sugerida

### Slice C1 — InstitutionalStatGrid + layout (P2)

| RED | GREEN |
|-----|-------|
| renders 4 KPI cards from stats prop | `InstitutionalStatGrid` |
| breadcrumb from screenId | `InstitutionalListLayout` |

### Slice C2 — UsersAdminPanel list (P1)

| RED | GREEN |
|-----|-------|
| MSW GET `/users` → table rows + pagination | panel + api client |
| filter status triggers query param | filter state |

### Slice C3 — Create user dialog (P1)

| RED | GREEN |
|-----|-------|
| submit POST `/users` → list refresh | dialog + mutation |

### Slice C4 — Inactivate / restore / reset (P1)

| RED | GREEN |
|-----|-------|
| Inativar calls DELETE; row status Inativo | action menu |
| Restaurar calls POST restore | |
| Reset senha dialog POST | |

### Slice C5 — Gabinete pages + gate (P1)

| RED | GREEN |
|-----|-------|
| `GabineteUsuariosPage.e2e.test.tsx` — 403 without access | gate + page |
| authorized sees full layout stack | |

### Slice C6 — Plataforma paridade (P2)

| RED | GREEN |
|-----|-------|
| `UsersAdminPanel` context=plataforma same columns | props context |
| SC-006 checklist manual QA doc in quickstart | |

---

## MSW handlers

File: `apps/web/src/test/msw/handlers/institutional-admin.ts`

- GET `/users` paginated fixtures (active + inactive)
- GET `/setores` paginated
- POST/PATCH/DELETE/restore/reset-password mutations update in-memory store

---

## Coverage targets

| Area | Minimum |
|------|---------|
| Use-cases business rules | 100% branches (self, last admin, dup) |
| Guard | all role matrix rows |
| Client panels | primary flows + empty state |
| E2E Vitest | 2 journeys (Gabinete CRUD user, Plataforma list setores) |

---

## Commands

```powershell
# API
cd ci-api-v2; npm test -- --testPathPattern=setor

# Client
cd ci-client-v2; npm test -- --filter=@ci/web -- institutional
```

---

## Traceability → Spec

| Spec US | Test slice |
|---------|------------|
| US1 | C2, Slice 1 |
| US2 | Slice 2–4, C3–C4 |
| US3 | Slice 6 list, C2 setores |
| US4 | Slice 6 CRUD |
| US5 | C6 |
| US6 | C1 (no license badges test) |
| US7 | C5, Slice 5 |
