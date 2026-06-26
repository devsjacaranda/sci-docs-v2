# Implementation Plan: Gerenciamento de Usuários e Setores — Gabinete

**Branch**: `017-gabinete-usuarios-setores-crud` | **Date**: 2026-06-25 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/017-gabinete-usuarios-setores-crud/spec.md`

## Summary

Entregar CRUD completo de **usuários** e **setores** no `@ci/web`, acessível pelo **Gabinete** (membros do setor vinculado ao módulo) e por **Plataforma** (`admin_tenant` / `admin_plataforma`), reutilizando um **componente compartilhado** de listagem admin com design system canônico: breadcrumb, cards KPI, botão criar, filtros, tabela e paginação (API + client).

**Gap corrigido**: painéis `PlatformUsersPanel` / `PlatformSectorsPanel` com API parcial, delete local no mock, senha fixa no create, guards API só `admin_plataforma`, sem restore/reset-password/inativar explícito, sem rotas Gabinete.

**API** (`ci-api-v2`): migrar incrementalmente módulo `setor` — novos use-cases/repositories para list paginada, inativar, restaurar, reset senha; guard de acesso institucional Gabinete; **sem** `@RequireLicenca`.

**Client** (`ci-client-v2`): páginas dedicadas `/gabinete/usuarios` e `/gabinete/setores`; refatorar painéis Plataforma para layout compartilhado; navegação Gabinete → **Gestão institucional**; MSW + testes Vitest.

## Technical Context

**Language/Version**: TypeScript 5.x / 6.x; Node.js 20 LTS

**Primary Dependencies**:

| Pacote | Stack |
|--------|-------|
| **ci-api-v2** | NestJS 11, Fastify, Pino, Zod (nestjs-zod), Prisma 7, PostgreSQL, bcryptjs |
| **ci-client-v2** | React 19, Vite 8, Tailwind v4, shadcn/ui (`@ci/ui`), react-router-dom 7, Vitest 3, MSW 2 |

**Storage**: PostgreSQL — modelos existentes `User`, `Setor`, `UserSetor`; soft delete via Prisma extension (`deletedAt`); **sem migration** estrutural

**Testing**:

| Camada | API | Client |
|--------|-----|--------|
| Unitário | Jest — use-cases (inativar self, último admin, sigla dup, role allowlist) | Vitest — mappers stats, filtros client |
| Componente | — | Vitest + RTL — list layout, dialogs, pagination |
| Contrato | Zod schemas + Supertest fixtures | Zod response + MSW handlers |
| Integração | Jest — controller + guards Gabinete/Plataforma | Vitest — page + MSW jornada CRUD |
| E2E | Supertest — login bloqueado pós-inativar | Vitest — fluxo Gabinete + paridade Plataforma |

**Target Platform**: API Linux/container; SPA browser (`@ci/web`)

**Project Type**: Full-stack (API + client)

**Performance Goals**: GET list paginada < 300ms p95 para até 500 registros; busca debounced 300ms no client

**Constraints**:

- TDD obrigatório RED → GREEN → REFACTOR (vertical slices)
- Zod only — sem class-validator
- Tenant AsyncLocalStorage — nunca passar `tenantId` manual
- **Sem** `@RequireLicenca` — funcionalidade Base ([licenca-contracts](../../../.cursor/skills/licenca-contracts/SKILL.md))
- Papéis CRUD: `user` e `chefe_setor` apenas — nunca `admin_plataforma` via UI
- Copy PT-BR institucional ([regras-plataforma.md](../../../.cursor/docs/regras-plataforma.md))
- Paleta Mint ([mint-palette.mdc](../../../.cursor/rules/mint-palette.mdc))
- UI pattern: espelhar `GabineteCadastroLayout` + `GabineteStatGrid` + `GabinetePagination` ([ui-ux-pro-max](../../../.cursor/skills/ui-ux-pro-max/SKILL.md))

**Scale/Scope**: ~12 use-cases/repositories novos ou refatorados, 1 guard, 2 páginas Gabinete, 2 painéis refatorados, 4 screens/nav entries, ~35 arquivos de teste

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Princípio | Status | Notas |
|-----------|--------|-------|
| I. Spec-Driven | ✅ PASS | Spec 017 validada; plano segue fluxo |
| II. Test-First | ✅ PASS | test-strategy.md — vertical slices TDD |
| III. Stack fixa | ✅ PASS | NestJS 11 + Prisma 7 + React 19 + Vite 8 + Zod |
| IV. Multi-tenant | ✅ PASS | Repositories com ALS; escopo tenant |
| IV. Licenças | ✅ PASS | **Sem** `@RequireLicenca`; Base only; fora filtro licença client |
| V. Escopo mínimo | ✅ PASS | Estende `setor` legado incrementalmente; client em `modules/setor/` |

**Post-design re-check**: Guard compartilhado Gabinete+Plataforma justificado por FR-005/FR-006. Layout compartilhado evita duplicar UI (Constitution V). Migração incremental de `*.service.ts` → use-cases alinhada a `ci-api-arquitetura`. Sem Complexity Tracking.

## Project Structure

### Documentation (this feature)

```text
specs/017-gabinete-usuarios-setores-crud/
├── plan.md              # Este arquivo
├── research.md          # Decisões técnicas (Phase 0)
├── data-model.md        # DTOs, filtros, state transitions
├── quickstart.md        # Validação manual + testes
├── contracts/
│   ├── rest-api-gestao-institucional.md
│   ├── client-gestao-institucional-ui.md
│   └── test-strategy.md
└── tasks.md             # Phase 2 — /speckit-tasks
```

### Source Code (repository root)

```text
ci-api-v2/
├── src/modules/setor/
│   ├── setor.controller.ts              # estender rotas + guards
│   ├── setor.schemas.ts                 # + query pagination, restore, reset
│   ├── guards/
│   │   └── institutional-admin.guard.ts # GAB module + admin bypass
│   ├── repository/                      # NOVO — 1 op por arquivo
│   │   ├── list-users-paginated.repository.ts
│   │   ├── list-setores-paginated.repository.ts
│   │   ├── inactivate-user.repository.ts
│   │   ├── restore-user.repository.ts
│   │   ├── reset-user-password.repository.ts
│   │   └── ... (setor equivalents)
│   ├── use-cases/
│   │   ├── list-users.use-case.ts
│   │   ├── create-user.use-case.ts
│   │   ├── inactivate-user.use-case.ts
│   │   ├── restore-user.use-case.ts
│   │   ├── reset-user-password.use-case.ts
│   │   └── ... (setor CRUD)
│   └── test/
│       ├── use-cases/
│       └── setor.controller.spec.ts
├── src/modules/auth/
│   └── auth.service.ts                  # já bloqueia deletedAt !== null

ci-client-v2/apps/web/src/modules/setor/
├── pages/
│   ├── GabineteUsuariosPage.tsx         # /gabinete/usuarios
│   └── GabineteSetoresPage.tsx            # /gabinete/setores
├── components/
│   ├── institutional/                     # NOVO — shared layout
│   │   ├── InstitutionalListLayout.tsx    # breadcrumb
│   │   ├── InstitutionalListHeader.tsx    # title + create CTA
│   │   ├── InstitutionalStatGrid.tsx      # KPI cards (Base)
│   │   ├── InstitutionalFiltersCard.tsx
│   │   ├── InstitutionalTableCard.tsx
│   │   └── InstitutionalPagination.tsx
│   ├── UsersAdminPanel.tsx              # refator de PlatformUsersPanel
│   └── SetoresAdminPanel.tsx            # refator de PlatformSectorsPanel
├── api/
│   ├── users-admin.ts                   # paginated API client
│   └── setores-admin.ts
├── lib/
│   └── institutional-list-stats.ts      # KPI derivados
└── __tests__/

ci-client-v2/apps/web/src/modules/shell/
├── config/navigation.ts                 # Gabinete → Gestão institucional
├── config/screens.ts                      # gabinete-usuarios, gabinete-setores
└── pages/ScreenPage.tsx                 # wire Plataforma panels

ci-client-v2/apps/web/src/modules/permissao/
└── lib/permissions.ts                   # GAB screens access check
```

**Structure Decision**: Monorepo existente — API em `ci-api-v2/src/modules/setor/` (domínio canônico user/setor); client em `ci-client-v2/apps/web/src/modules/setor/` espelhando API. Layout institucional extraído do padrão Gabinete cadastro (`GabineteCadastroLayout`, `GabineteStatGrid`, `GabinetePagination`) para reuso Plataforma + Gabinete.

## Complexity Tracking

> Não aplicável — sem violações de constitution.

## Phase 0 & 1 Artifacts

| Artifact | Path | Status |
|----------|------|--------|
| Research | [research.md](./research.md) | ✅ |
| Data model | [data-model.md](./data-model.md) | ✅ |
| REST contract | [contracts/rest-api-gestao-institucional.md](./contracts/rest-api-gestao-institucional.md) | ✅ |
| Client contract | [contracts/client-gestao-institucional-ui.md](./contracts/client-gestao-institucional-ui.md) | ✅ |
| Test strategy | [contracts/test-strategy.md](./contracts/test-strategy.md) | ✅ |
| Quickstart | [quickstart.md](./quickstart.md) | ✅ |

## Next Step

Executar **`/speckit-tasks`** para gerar `tasks.md` acionável com TDD vertical slices.
