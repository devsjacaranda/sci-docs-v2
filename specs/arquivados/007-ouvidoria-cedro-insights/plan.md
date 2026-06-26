# Implementation Plan: Insights Cedro — Ouvidoria

**Branch**: `007-ouvidoria-cedro-insights` | **Date**: 2026-06-19 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/007-ouvidoria-cedro-insights/spec.md`

## Summary

Implementar **Insights IA Cedro** em `/ouvidoria/insights`: análise consultiva **somente leitura** sobre manifestações confirmadas do tenant (operacional, geográfico, texto por agregação determinística, perfil), com geração híbrida (job diário + persistência de lotes + recálculo sob demanda com throttling 1h). **Sem modelo de IA nem integrações externas** — branding *Insights IA* / *Consultar IA* mantido.

**API** (`ci-api-v2`): novo submódulo `ouvidoria-insights` — agregadores puros, use-cases, repositories Prisma, `@nestjs/schedule` para job, REST sob `/ouvidoria/insights`, `@RequireModulo('ouvidoria')` + `@RequireLicenca('cedro')`.

**Client** (`ci-client-v2`): página real em `modules/ouvidoria/pages/`, API client, componentes Cedro com sheet de rastreio; substituir mock `CedroModulePanel` / `ScreenPage` para `ouvidoria-insights`.

**Testes (sem banco extra)**: unitário, componente, contrato, integração (mocks/in-memory) e E2E (Supertest + RTL journey com MSW) — ver [contracts/test-strategy.md](./contracts/test-strategy.md).

## Technical Context

**Language/Version**: TypeScript 5.x / 6.x; Node.js 20 LTS

**Primary Dependencies**:

| Pacote | Stack |
|--------|-------|
| **ci-api-v2** | NestJS 11, Fastify, Pino, Zod, Prisma 7, PostgreSQL, `@nestjs/schedule` (novo) |
| **ci-client-v2** | React 19, Vite 8, Tailwind v4, shadcn/ui, react-router-dom 7, Vitest 3, MSW 2 |

**Storage**: PostgreSQL — novas entidades `OuvidoriaInsightBatch`, `OuvidoriaInsight`, `OuvidoriaInsightEvidence`; leitura de `Manifestacao`, `ManifestacaoEvento`, `Address`, `Municipio`

**Testing** (sem Postgres de teste dedicado):

| Camada | API | Client |
|--------|-----|--------|
| Unitário | Jest — agregadores puros, throttling, mappers | Vitest — formatters, mappers impacto |
| Componente | — | Vitest + RTL — cards, histórico, sheet rastreio |
| Contrato | Zod + fixtures JSON; Supertest valida body | Zod response + MSW handlers |
| Integração | Jest — use-cases + repositories com **Prisma mock** ou store in-memory | Vitest — api client + hooks + MSW |
| E2E | Supertest app Nest — **deps mockadas** (padrão `ouvidoria.e2e-spec.ts`) | Vitest — página completa + MemoryRouter + MSW (jornada UI) |

**Target Platform**: API Linux/container; SPA browser

**Project Type**: Full-stack (API + client)

**Performance Goals**: Recálculo sob demanda ≤ 30s para até 10.000 manifestações (SC-003); listagem insights &lt; 500ms p95

**Constraints**:

- TDD obrigatório (Constitution II); RED → GREEN → REFACTOR
- Zod only — sem class-validator
- Tenant via AsyncLocalStorage
- Cedro read-only — nunca altera `Manifestacao` / eventos
- Cedro **nunca** conta SLA nem substitui Jatobá (FR-015, R-91)
- Tempos derivados de **eventos** — sem campo `prazo` na manifestação
- Copy: [regras-plataforma.md](../../.cursor/docs/regras-plataforma.md) — Insights IA, Somente leitura, sheet ~85%
- **Testes**: **NUNCA** exigir banco Postgres separado — mocks Prisma, fixtures in-memory, MSW

**Scale/Scope**: 3 entidades Prisma novas, ~8 endpoints REST, 1 job agendado, 1 página client + 4 componentes, ~25 arquivos de teste

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Princípio | Status | Notas |
|-----------|--------|-------|
| I. Spec-Driven | ✅ PASS | Spec 007 validada; plano segue fluxo |
| II. Test-First | ✅ PASS | Cinco camadas documentadas em test-strategy; sem banco extra |
| III. Stack fixa | ✅ PASS | NestJS 11 + Prisma 7 + React 19 + Vite 8 |
| IV. Multi-tenant | ✅ PASS | Lotes/insights com `tenantId`; guards módulo + Cedro |
| IV. Licenças | ✅ PASS | `@RequireLicenca('cedro')`; read-only Cedro |
| V. Escopo mínimo | ✅ PASS | Submódulo `ouvidoria-insights` colocado em `modules/`; client em `modules/ouvidoria/` |

**Post-design re-check**: `@nestjs/schedule` é extensão padrão Nest — não viola stack. Persistência de lotes justificada por FR-005/FR-009 (histórico). Sem Complexity Tracking necessário.

## Project Structure

### Documentation (this feature)

```text
specs/007-ouvidoria-cedro-insights/
├── plan.md              # Este arquivo
├── research.md          # Decisões técnicas (Phase 0)
├── data-model.md        # Entidades Prisma insights
├── quickstart.md        # Validação manual + comandos de teste
├── contracts/
│   ├── rest-api-ouvidoria-insights.md
│   ├── client-ouvidoria-insights-ui.md
│   └── test-strategy.md
└── tasks.md             # Phase 2 — /speckit-tasks
```

### Source Code (repository root)

```text
ci-api-v2/
├── prisma/schema/
│   └── ouvidoria-insights.prisma    # Batch + Insight + Evidence + enums
├── src/modules/ouvidoria-insights/
│   ├── ouvidoria-insights.module.ts
│   ├── ouvidoria-insights.controller.ts
│   ├── ouvidoria-insights.schemas.ts
│   ├── ouvidoria-insights.types.ts
│   ├── lib/                         # agregadores PUROS (unit-testáveis)
│   │   ├── aggregation/
│   │   │   ├── operational.rules.ts
│   │   │   ├── geographic.rules.ts
│   │   │   ├── text-frequency.rules.ts
│   │   │   └── profile.rules.ts
│   │   ├── insight-impact.ts
│   │   └── analysis-window.ts
│   ├── repository/
│   ├── use-cases/
│   ├── jobs/
│   │   └── generate-insights-scheduled.job.ts
│   └── test/
│       ├── lib/                     # unit
│       ├── use-cases/               # unit + integration (mock prisma)
│       └── repository/              # unit (mock prisma)
└── test/
    └── ouvidoria-insights.e2e-spec.ts   # E2E Supertest (mocks)

ci-client-v2/apps/web/src/modules/ouvidoria/
├── api/
│   └── insights.ts                  # fetch + types
├── components/
│   ├── InsightsPanel.tsx
│   ├── InsightCard.tsx
│   ├── InsightTraceSheet.tsx
│   └── InsightsHistoryPanel.tsx
├── pages/
│   └── OuvidoriaInsightsPage.tsx
├── fixtures/
│   └── insights-*.json              # contract + MSW
└── __tests__/
    ├── insights.contract.test.ts
    ├── InsightsPanel.test.tsx       # component
    ├── OuvidoriaInsightsPage.integration.test.tsx
    └── OuvidoriaInsightsPage.e2e.test.tsx
```

**Structure Decision**: Submódulo API dedicado (agregação + persistência isolada da CRUD ouvidoria). Client colocated em `ouvidoria/` espelhando API. Agregadores em `lib/` sem Prisma para maximizar cobertura unitária sem DB.

## Complexity Tracking

> Vazio — sem violações de constitution que exijam justificativa.

## Phase Artifacts

| Artefato | Caminho |
|----------|---------|
| Research | [research.md](./research.md) |
| Data model | [data-model.md](./data-model.md) |
| REST contract | [contracts/rest-api-ouvidoria-insights.md](./contracts/rest-api-ouvidoria-insights.md) |
| UI contract | [contracts/client-ouvidoria-insights-ui.md](./contracts/client-ouvidoria-insights-ui.md) |
| Test strategy | [contracts/test-strategy.md](./contracts/test-strategy.md) |
| Quickstart | [quickstart.md](./quickstart.md) |

## Next Step

`/speckit-tasks` — TDD por camada conforme [test-strategy.md](./contracts/test-strategy.md).
