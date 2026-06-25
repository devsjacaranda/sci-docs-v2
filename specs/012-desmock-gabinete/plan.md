# Implementation Plan: Desmock Gabinete — Demandas, Protocolos e Licenças

**Branch**: `012-desmock-gabinete` | **Date**: 2026-06-23 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/012-desmock-gabinete/spec.md`

## Summary

Substituir mocks do **Gabinete do Presidente** por dados reais multi-tenant: módulo **Base** (`CabinetDemanda` = ata internamente, API pública **`cabinetId`** / rotas `/gabinete/cabinets/*`, UI **ato/atos** em `/gabinete/atos/*`), `CabinetProtocolo`, controles opcionais unificados, anexos **Wasabi**, stub **Tramitar**, Dashboard KPIs) + licenças **Jatobá**, **Carvalho** e **Cedro** espelhando Ouvidoria 007/008/009. Controles vivem em **abas no detalhe do ato** (não páginas standalone v1). Documentos Tramitados: **uma tabela + Setor**; UI mock até módulo Tramitação existir.

### Amendment 2026-06-23 (decisões stakeholder)

| Decisão | Implementação |
|---------|---------------|
| UI placement 1B | Abas no detalhe `/gabinete/atos/:id` — Protocolo, Controle Numérico, Notificações/Autos, Documentos Tramitados (mock) |
| Naming FK | API/DTOs: `cabinetId`; Prisma interno: `CabinetDemanda`; vocabulário UI: **ato/atos** (sem "demanda") |
| REST | `/gabinete/cabinets/:cabinetId/...` nested CRUD |
| Documentos tramitados | Tabela unificada no schema; **sem API** nesta fase — mock UI com coluna Setor |

## Technical Context

**Language/Version**: TypeScript 5.x / 6.x; Node.js 20 LTS

**Primary Dependencies**:

| Pacote | Stack |
|--------|-------|
| **ci-api-v2** | NestJS 11, Fastify, Pino, Zod, Prisma 7, PostgreSQL, `@aws-sdk/client-s3`, `@nestjs/schedule` |
| **ci-client-v2** | React 19, Vite 8, Tailwind v4, shadcn/ui, Nivo, react-router-dom 7, TanStack Query, Vitest 3, MSW 2 |

**Storage**: PostgreSQL — `gabinete.prisma`, `gabinete-fiscalizacao.prisma`, `gabinete-maturidade.prisma`, `gabinete-insights.prisma`; Wasabi/MinIO para anexos

**Testing**: Jest (API unit/integration/e2e) + Vitest/RTL/MSW (client); sem Postgres de teste dedicado — [test-strategy.md](./contracts/test-strategy.md)

**Target Platform**: API Linux/container; SPA browser (`@ci/web`)

**Project Type**: Full-stack (API + client monorepo)

**Performance Goals**: Lista demandas paginada < 500ms p95; dashboard < 500ms p95; fiscalização run ≤ 30s para 500 demandas

**Constraints**:

- TDD obrigatório RED → GREEN → REFACTOR
- Zod only — sem class-validator
- Tenant AsyncLocalStorage — nunca passar `tenantId` manual
- `@RequireModulo('gabinete')` + `@RequireLicenca` nas rotas de licença
- Jatobá/Cedro/Carvalho read-only sobre demandas
- Copy [regras-plataforma.md](../../.cursor/docs/regras-plataforma.md); paleta mint-palette
- Tramitar **não** integra módulo Tramitação

**Scale/Scope**: ~15 entidades Prisma, 4 módulos NestJS, ~35 endpoints REST, 7 páginas client, seed Jacaranda, atualização `licencas-canonicas.md`

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Princípio | Status | Notas |
|-----------|--------|-------|
| I. Spec-Driven | ✅ PASS | Spec 012 + checklist validados |
| II. Test-First | ✅ PASS | test-strategy 5 camadas |
| III. Stack fixa | ✅ PASS | NestJS 11 + Prisma 7 + React 19 + Vite 8 |
| IV. Multi-tenant | ✅ PASS | Todas entidades `tenantId`; guards módulo/licença |
| IV. Licenças | ✅ PASS | Jatobá + Carvalho + Cedro + Base |
| V. Escopo mínimo | ✅ PASS | 4 módulos espelho ouvidoria; client `modules/gabinete/` |

**Post-design re-check**: Extração `StorageService` compartilhado justificada (R4); 4 módulos NestJS justificados por fronteiras de licença (R8). Sem Complexity Tracking necessário.

## Project Structure

### Documentation (this feature)

```text
specs/012-desmock-gabinete/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   ├── rest-api-gabinete.md
│   ├── rest-api-gabinete-fiscalizacao.md
│   ├── rest-api-gabinete-maturidade.md
│   ├── rest-api-gabinete-insights.md
│   ├── client-gabinete-ui.md
│   └── test-strategy.md
└── tasks.md             # Phase 2 — /speckit-tasks
```

### Source Code (repository root)

```text
ci-api-v2/
├── prisma/schema/
│   ├── gabinete.prisma                    # Demanda, Protocolo, controles, anexos, sequence
│   ├── gabinete-fiscalizacao.prisma
│   ├── gabinete-maturidade.prisma
│   └── gabinete-insights.prisma
├── prisma/seed/
│   ├── seed-gabinete-demo.ts
│   ├── seed-fiscalizacao-questions-gabinete.ts
│   └── seed-maturidade-questions-gabinete.ts
├── src/modules/
│   ├── shared/storage/                    # StorageService extraído (R4)
│   │   └── storage.service.ts
│   ├── gabinete/
│   │   ├── gabinete.module.ts
│   │   ├── gabinete.controller.ts
│   │   ├── gabinete.schemas.ts
│   │   ├── use-cases/
│   │   │   ├── create-demanda.use-case.ts
│   │   │   ├── list-demandas.use-case.ts
│   │   │   ├── get-demanda-detail.use-case.ts
│   │   │   ├── update-demanda.use-case.ts
│   │   │   ├── forward-demanda.use-case.ts
│   │   │   ├── get-dashboard.use-case.ts
│   │   │   └── controles/*.use-case.ts
│   │   └── repository/
│   ├── gabinete-fiscalizacao/             # espelho ouvidoria-fiscalizacao
│   ├── gabinete-maturidade/               # espelho ouvidoria-maturidade
│   └── gabinete-insights/                 # espelho ouvidoria-insights
└── test/
    └── gabinete.e2e-spec.ts

ci-client-v2/apps/web/src/modules/gabinete/
├── index.ts
├── api/
│   ├── demandas.ts
│   ├── dashboard.ts
│   ├── fiscalizacao.ts
│   ├── maturidade.ts
│   └── insights.ts
├── pages/
│   ├── GabineteDashboardPage.tsx
│   ├── GabineteDemandasListPage.tsx
│   ├── GabineteDemandaCreatePage.tsx
│   ├── GabineteDemandaDetailPage.tsx
│   ├── GabineteAuditoriaPage.tsx
│   ├── GabineteMaturidadePage.tsx
│   └── GabineteInsightsPage.tsx
├── components/
│   ├── DemandaForm.tsx
│   ├── DemandaTimeline.tsx
│   ├── ControlesTabs.tsx
│   ├── ForwardDemandaDialog.tsx
│   └── … (fiscalizacao/maturidade/insights clones adaptados)
└── fixtures/
```

**Structure Decision**: Quatro módulos API por domínio/licença (Constitution V); client único `gabinete/` espelhando `ouvidoria/`. `ScreenPage` deixa de renderizar mock para rotas `gabinete-*`.

## Phase 0 — Research

Concluída em [research.md](./research.md). Decisões R1–R15 (nomenclatura, unificação v2, Wasabi compartilhado, submódulos licença, testes mock).

## Phase 1 — Design

| Artefato | Path |
|----------|------|
| Data model | [data-model.md](./data-model.md) |
| REST Base | [contracts/rest-api-gabinete.md](./contracts/rest-api-gabinete.md) |
| REST Jatobá | [contracts/rest-api-gabinete-fiscalizacao.md](./contracts/rest-api-gabinete-fiscalizacao.md) |
| REST Carvalho | [contracts/rest-api-gabinete-maturidade.md](./contracts/rest-api-gabinete-maturidade.md) |
| REST Cedro | [contracts/rest-api-gabinete-insights.md](./contracts/rest-api-gabinete-insights.md) |
| UI | [contracts/client-gabinete-ui.md](./contracts/client-gabinete-ui.md) |
| Tests | [contracts/test-strategy.md](./contracts/test-strategy.md) |
| Quickstart | [quickstart.md](./quickstart.md) |

## Implementation phases (for /speckit-tasks)

### Phase A — Schema & seed

1. Prisma `gabinete.prisma` + enums + migration
2. Seed setor Gabinete ↔ módulo `gabinete` (Jacaranda)
3. Seed demo demandas + controles

### Phase B — Storage compartilhado

1. Extrair `StorageService` de ouvidoria → `shared/storage`
2. Refatorar ouvidoria para importar shared (regression tests)

### Phase C — Gabinete Base API

1. CRUD demanda + protocolo + sequence
2. Anexos presign/confirm
3. Forward stub + eventos
4. CRUD controles nested
5. Dashboard aggregations
6. e2e Base

### Phase D — Gabinete Fiscalização (Jatobá)

1. Schema + checks + run/panel
2. Job schedule + seed questions
3. Client `GabineteAuditoriaPage`

### Phase E — Gabinete Insights (Cedro)

1. Schema + aggregation rules + runs
2. Client `GabineteInsightsPage`

### Phase F — Gabinete Maturidade (Carvalho)

1. Schema + self-assessment + hybrid score
2. Client `GabineteMaturidadePage`

### Phase G — Client Base + shell

1. Páginas demandas/dashboard
2. Rotas lazy + redirects atos→demandas
3. navigation.ts + screens.ts cleanup mocks
4. Atualizar `licencas-canonicas.md` (Base Gabinete)

## Complexity Tracking

> Nenhuma violação requiring justification.

| Item | Notes |
|------|-------|
| 4 módulos NestJS | Fronteira licença + espelho ouvidoria comprovado |
| Storage shared | Reuso Wasabi cross-módulo |
| Enum status extenso | Herança v1 AGEMAN — mapper UI simplifica |

## Risks

| Risk | Mitigation |
|------|------------|
| Escopo grande (12 US) | tasks.md vertical slices; Base antes licenças |
| Refactor StorageService quebra Ouvidoria | Tests ouvidoria regression antes merge |
| Confusão Atos vs Demandas | Redirects + copy; atualizar licencas-canonicas |
| Tramitar stub vs expectativa SIGED | Banner UI + spec out-of-scope explícito |

## Dependencies

- **002-auth-setor-permissao**: guards, ModuloSetor
- **003-ouvidoria**: StorageService, padrão anexos/eventos
- **007/008/009**: templates submódulos licença
- **Setor** existente

## Out of scope (reminder)

- Tramitação real (005)
- Pau-Brasil modelos/assinatura
- Migração dados v1
- Consulta pública

## Next step

Run **`/speckit-tasks`** to generate `tasks.md` with dependency-ordered implementation items.
