# Implementation Plan: Autenticação e Permissão por Setor

**Branch**: `002-auth-setor-permissao` | **Date**: 2026-06-05 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/002-auth-setor-permissao/spec.md`

## Summary

Implementar controle de acesso a módulos de negócio por **setor organizacional**: vínculos configuráveis módulo–setor, usuários com múltiplos setores de lotação, tela **403 · Acesso negado** (sem ocultar navegação), solicitação notify-only a **todos os chefes** dos setores vinculados, e guards consistentes API + client. Migração Prisma de `User.setorId` singular para N:N; novos módulos NestJS `setor` e `permissao`; client substitui mock por REST preservando `AccessDenied403`.

## Technical Context

**Language/Version**: TypeScript 5.x; Node.js 20 LTS

**Primary Dependencies**:

| Pacote | Stack |
|--------|-------|
| **ci-api-v2** | NestJS 11, Fastify, Pino, Zod, Prisma 7, PostgreSQL, JWT |
| **ci-client-v2** | React 19, Vite 8, Tailwind v4, shadcn/ui, react-router-dom 7 |

**Storage**: PostgreSQL — entidades Setor, UserSetor, ModuloSetor, SolicitacaoPermissao, NotificacaoPermissao (ver [data-model.md](./data-model.md))

**Testing**: Jest (API unit + e2e); client typecheck + smoke manual ([quickstart.md](./quickstart.md))

**Target Platform**: API Linux/container; SPA browser

**Project Type**: Full-stack (API independente + frontend monorepo)

**Performance Goals**: Avaliação de permissão < 50ms p95 (cache JWT setorIds); notificações persistidas em < 1 min (SC-003)

**Constraints**:

- TDD obrigatório (Constitution II)
- Zod only — sem class-validator
- Tenant via AsyncLocalStorage — sem `tenantId` manual em services
- Licenças universais por tenant/usuário (FR-015) — sem `UserLicenca`
- Notify-only — sem workflow aprovação in-app (FR-016)
- Copy UI conforme [regras-plataforma.md](../../.cursor/docs/regras-plataforma.md) e mint-palette

**Scale/Scope**: ~10 módulos, dezenas de setores por tenant, 3 painéis admin existentes + API ~15 endpoints

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Princípio | Status | Notas |
|-----------|--------|-------|
| I. Spec-Driven | ✅ PASS | Spec 002 validada; plano segue fluxo |
| II. Test-First | ✅ PASS | Guards/services com Jest antes de controllers; e2e 403 + solicitação |
| III. Stack fixa | ✅ PASS | NestJS 11 + Prisma 7 + React 19 + Vite 8 — sem desvio |
| IV. Multi-tenant | ✅ PASS | Todas entidades com `tenantId`; guards respeitam ALS |
| IV. Licenças | ✅ PASS | FR-015 via tenant; LicencaGuard mantido |
| V. Escopo mínimo | ✅ PASS | Módulos `setor` + `permissao`; sem refatoração unrelated |

**Post-design re-check**: Modelo N:N justificado pela spec; sem violações requiring Complexity Tracking.

## Project Structure

### Documentation (this feature)

```text
specs/002-auth-setor-permissao/
├── plan.md              # Este arquivo
├── research.md          # Decisões técnicas (Phase 0)
├── data-model.md        # Entidades Prisma
├── quickstart.md        # Validação pós-implementação
├── contracts/
│   ├── rest-api-permissions.md
│   ├── modulo-slugs.md
│   └── client-permission-ui.md
└── tasks.md             # Phase 2 — /speckit-tasks
```

### Source Code (repository root)

```text
ci-api-v2/
├── prisma/
│   ├── schema/
│   │   ├── setor.prisma          # + chefeUserId, sigla
│   │   ├── user.prisma           # remove setorId
│   │   ├── user-setor.prisma     # NEW N:N lotação
│   │   ├── modulo-setor.prisma   # NEW vínculos
│   │   ├── permissao.prisma      # NEW solicitação + notificação
│   │   └── enums.prisma          # + ModuloSlug
│   ├── migrations/
│   └── seed.ts                   # multi-setor demo
├── src/
│   ├── common/
│   │   ├── guards/
│   │   │   └── modulo-permissao.guard.ts    # NEW
│   │   └── decorators/
│   │       └── require-modulo.decorator.ts  # NEW
│   └── modules/
│       ├── auth/                 # extend JWT + /me
│       ├── setor/                # NEW CRUD + membros
│       └── permissao/            # NEW vínculos, solicitações, notificações
└── test/
    └── app.e2e-spec.ts           # + cenários 403

ci-client-v2/apps/web/src/
├── components/admin/
│   └── AccessDenied403.tsx       # multi-líder
├── lib/
│   ├── permissions.ts            # API-driven; notify all chiefs
│   └── auth.ts                   # real login
├── context/AuthContext.tsx       # setorIds from API
├── data/admin-mock.ts            # deprecate → API
└── pages/ScreenPage.tsx          # 403 gate
```

**Structure Decision**: Dois módulos de domínio na API (`setor`, `permissao`) seguindo layout existente em `ci-api-v2/src/modules/`. Guard global registrado em `app.module.ts` após `LicencaGuard`. Client mantém lógica em `permissions.ts` até eventual extração para `@ci/domain` (fora desta feature).

## Phase 0 — Research

Concluída em [research.md](./research.md). Decisões-chave:

- R1: `UserSetor` N:N
- R2: `Setor.chefeUserId`
- R3: `ModuloSetor` + enum slugs
- R4: `ModuloPermissaoGuard`
- R5: JWT `setorIds[]`
- R6: Solicitação + N notificações
- R7: Licenças via tenant only
- R8: Mock → REST no client

## Phase 1 — Design

| Artefato | Path |
|----------|------|
| Data model | [data-model.md](./data-model.md) |
| REST contract | [contracts/rest-api-permissions.md](./contracts/rest-api-permissions.md) |
| Module slugs | [contracts/modulo-slugs.md](./contracts/modulo-slugs.md) |
| UI contract | [contracts/client-permission-ui.md](./contracts/client-permission-ui.md) |
| Quickstart | [quickstart.md](./quickstart.md) |

## Implementation phases (for /speckit-tasks)

### Phase A — Schema & seed (API)

1. Prisma migration: UserSetor, ModuloSetor, SolicitacaoPermissao, NotificacaoPermissao, Setor.chefeUserId
2. Migrate data: `User.setorId` → `UserSetor` rows
3. Expand seed demo (Gabinete, Jurídico, Protocolo multi-setor)

### Phase B — Auth & guards (API)

1. Extend login/JWT/`/auth/me` with `setorIds[]`, `chiefOfSetorIds[]`
2. Implement `ModuloPermissaoGuard` + `@RequireModulo`
3. Unit tests RED→GREEN

### Phase C — Domain modules (API)

1. `SetorModule`: CRUD, membros
2. `PermissaoModule`: vínculos, solicitações, notificações
3. E2e tests

### Phase D — Client integration

1. Replace mock auth with API
2. Update `permissions.ts` + `AccessDenied403` (multi-leader)
3. Wire admin panels to REST
4. Smoke per quickstart

## Complexity Tracking

> Nenhuma violação de constitution requiring justification.

| Item | Notes |
|------|-------|
| N:N UserSetor | Required by spec FR-002 |
| New guard in pipeline | Required by FR-012 |

## Risks

| Risk | Mitigation |
|------|------------|
| JWT stale after admin changes setores | Short TTL + refetch `/auth/me` on admin screens |
| Mock diverge (notify 1 chief) | Fix in Phase D per contract |
| `chefe_setor` role vs per-setor chefe | Document: role for admin routes; `chefeUserId` for notifications |

## Next step

Run **`/speckit-tasks`** to generate `tasks.md` with dependency-ordered implementation items.
