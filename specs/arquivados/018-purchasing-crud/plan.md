# Implementation Plan: Purchasing — CRUD de Demandas e Artefatos

**Branch**: `018-purchasing-crud` | **Date**: 2026-06-25 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/018-purchasing-crud/spec.md`

## Summary

Entregar o módulo **Compras** full-stack (Lei 14.133/2021) substituindo mocks visuais por domínio real: **PCAs** (gestão via sheet na listagem), **demandas** com numeração sequencial, hub **quebra-cabeça** com 7 artefatos documentais e **status/progresso derivados** — sem colunas persistidas de progresso na entidade demanda.

**Gap atual**: `ModuloSlug.compras` existe em enums/permissões, mas **zero** Prisma models, endpoints ou páginas reais; client usa `screens.ts` mock com rotas divergentes (`/compras/demandas/*`, `/compras/pca/*`).

**API** (`ci-api-v2`): greenfield `modules/compras/` — `@RequireModulo('compras')`, **sem** `@RequireLicenca` (Base).

**Client** (`ci-client-v2`): novo `modules/compras/` com rotas canônicas `/compras`, `/compras/novo`, `/compras/:id`, sub-rotas de artefatos; override em `router.tsx`.

## Technical Context

**Language/Version**: TypeScript 5.x / 6.x; Node.js 20 LTS

**Primary Dependencies**:

| Pacote | Stack |
|--------|-------|
| **ci-api-v2** | NestJS 11, Fastify, Pino, Zod (nestjs-zod), Prisma 7, PostgreSQL |
| **ci-client-v2** | React 19, Vite 8, Tailwind v4, shadcn/ui (`@ci/ui`), react-router-dom 7, Vitest 3, MSW 2, TanStack Query |

**Storage**: PostgreSQL — novo `prisma/schema/compras.prisma` (9 models + sequence); comprovantes via Wasabi presign (`StorageModule`); soft delete via Prisma extension

**Testing**:

| Camada | API | Client |
|--------|-----|--------|
| Unitário | Jest — use-cases (status derivado, ETP waived, sequence, filtros) | Vitest — mapper checklist, validação forms |
| Contrato | Zod + Supertest `compras.contract.spec.ts` | MSW + Zod response |
| Integração | Jest — tenant isolation, modulo guard | Vitest — jornada CRUD com MSW |
| E2E manual | quickstart.md | quickstart.md |

**Target Platform**: API Linux/container; SPA browser (`@ci/web`)

**Project Type**: Full-stack (API + client)

**Performance Goals**: Listagem filtrada ≤ 2s percebido com até 500 demandas (SC-005); paginação server-side default 20

**Constraints**:

- TDD obrigatório RED → GREEN → REFACTOR ([testing-conventions](../../../.cursor/skills/testing-conventions/SKILL.md))
- Zod only — sem class-validator
- Tenant AsyncLocalStorage — nunca passar `tenantId` manual
- **Sem** `@RequireLicenca` — Base only (FR-024)
- Vocabulário UI: **demanda/demandas**, módulo **Compras** (FR-025/026)
- Status/progresso **derivados** — sem coluna `status` em `CompraDemanda` (FR-017/018)
- Escopo **exclui** Jatobá/Cedro/Carvalho/Pau-Brasil (FR-029) e PDF export (FR-028)
- Paleta Mint + shadcn ([ui-ux-pro-max](../../../.cursor/skills/ui-ux-pro-max/SKILL.md))

**Scale/Scope**: ~9 Prisma models, ~25 use-cases, 1 controller, 10 páginas client, 7 forms artefato, seed Jacaranda, ~45 arquivos de teste

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Princípio | Status | Notas |
|-----------|--------|-------|
| I. Spec-Driven | ✅ PASS | Spec 018 validada; plano segue fluxo |
| II. Test-First | ✅ PASS | test-strategy.md — vertical slices TDD |
| III. Stack fixa | ✅ PASS | NestJS 11 + Prisma 7 + React 19 + Vite 8 + Zod |
| IV. Multi-tenant | ✅ PASS | Models com tenantId; ALS; 404 cross-tenant |
| IV. Licenças | ✅ PASS | Base only — sem `@RequireLicenca` |
| V. Escopo mínimo | ✅ PASS | Greenfield módulo isolado; espelha gabinete |

**Post-design re-check**: Status derivado sem coluna persistida atende FR-017/018 e Constitution V (sem over-engineering de cache). Presign upload reutiliza infra existente. Prefixo `Compra*` evita colisão com Gabinete. Sem Complexity Tracking.

## Project Structure

### Documentation (this feature)

```text
specs/018-purchasing-crud/
├── plan.md              # Este arquivo
├── research.md          # Decisões técnicas (Phase 0)
├── data-model.md        # Entidades, enums, DTOs derivados
├── quickstart.md        # Validação manual + testes
├── contracts/
│   ├── rest-api-compras.md
│   ├── client-compras-ui.md
│   └── test-strategy.md
└── tasks.md             # Phase 2 — /speckit-tasks
```

### Source Code (repository root)

```text
ci-api-v2/
├── prisma/schema/compras.prisma           # NOVO — CompraPca, CompraDemanda, 7 artefatos, sequence
├── prisma/migrations/                     # migration gerada
├── prisma/seed/seed-jacaranda-tenant.ts   # + modulo compras → DEAE + PCAs/demandas demo
└── src/modules/compras/
    ├── compras.module.ts
    ├── compras.controller.ts              # @RequireModulo('compras')
    ├── compras.schemas.ts                 # Zod — query, bodies, responses
    ├── compras.mapper.ts                  # status/progress/checklist derivados + labels PT
    ├── repository/
    │   ├── pca.repositories.ts
    │   ├── demanda.repositories.ts
    │   ├── demanda-sequence.repository.ts
    │   └── artefatos.repositories.ts
    ├── use-cases/
    │   ├── create-pca.use-case.ts
    │   ├── list-pca.use-case.ts
    │   ├── close-pca.use-case.ts
    │   ├── create-demanda.use-case.ts
    │   ├── list-demandas.use-case.ts
    │   ├── get-demanda-detail.use-case.ts
    │   ├── delete-demanda.use-case.ts
    │   └── upsert-{dfd,etp,analise-riscos,tr,pesquisa-precos,dotacao,parecer}.use-case.ts
    └── test/
        ├── compras.contract.spec.ts
        └── use-cases/

ci-client-v2/apps/web/src/modules/compras/
├── api/
│   ├── pca.ts
│   ├── demandas.ts
│   ├── artefatos.ts
│   └── types.ts
├── components/
│   ├── DemandasTable.tsx
│   ├── DemandasFilters.tsx
│   ├── PcaManageSheet.tsx
│   ├── ArtefactChecklist.tsx
│   ├── DemandaArtefactLayout.tsx
│   ├── ComprovanteUpload.tsx
│   └── EmptyStateCompras.tsx
├── pages/
│   ├── DemandasListPage.tsx               # /compras
│   ├── DemandaCreatePage.tsx              # /compras/novo
│   ├── DemandaHubPage.tsx                 # /compras/:demandaId
│   └── artefatos/
│       ├── DfdPage.tsx
│       ├── EtpPage.tsx
│       ├── AnaliseRiscosPage.tsx
│       ├── TrPage.tsx
│       ├── PesquisaPrecosPage.tsx
│       ├── DotacaoPage.tsx
│       └── ParecerPage.tsx
├── lib/
│   └── artefact-labels.ts
└── __tests__/

ci-client-v2/apps/web/src/app/router.tsx     # override rotas compras
ci-client-v2/apps/web/src/modules/shell/config/navigation.ts
ci-client-v2/apps/web/src/modules/shell/config/screens.ts  # deprecar mocks substituídos
ci-api-v2/src/app.module.ts                  # import ComprasModule
```

**Structure Decision**: Monorepo existente — API greenfield em `ci-api-v2/src/modules/compras/` espelhando arquitetura `gabinete/`; client em `modules/compras/` com rotas canônicas da spec (não mocks). Licenciados (019–021) **não** entram neste plano.

## Complexity Tracking

> Não aplicável — sem violações de constitution.

## Phase 0 & 1 Artifacts

| Artifact | Path | Status |
|----------|------|--------|
| Research | [research.md](./research.md) | ✅ |
| Data model | [data-model.md](./data-model.md) | ✅ |
| REST contract | [contracts/rest-api-compras.md](./contracts/rest-api-compras.md) | ✅ |
| Client contract | [contracts/client-compras-ui.md](./contracts/client-compras-ui.md) | ✅ |
| Test strategy | [contracts/test-strategy.md](./contracts/test-strategy.md) | ✅ |
| Quickstart | [quickstart.md](./quickstart.md) | ✅ |

## Next Step

Executar **`/speckit-tasks`** para gerar `tasks.md` acionável com TDD vertical slices.
