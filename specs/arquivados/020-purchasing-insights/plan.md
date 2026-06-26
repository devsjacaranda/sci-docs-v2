# Implementation Plan: Insights IA Cedro — Purchasing

**Branch**: `020-purchasing-insights` | **Date**: 2026-06-25 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/020-purchasing-insights/spec.md`

**Dependência concluída**: [018 Purchasing CRUD](../arquivados/018-purchasing-crud/spec.md) — demandas, PCAs, artefatos e Pesquisa de Preços.

**Paridade estrutural**: [015 Gabinete Cedro Insights](../arquivados/015-gabinete-cedro-insights-integrado/plan.md), adaptado ao domínio Compras.

## Summary

Implementar **Insights IA Cedro** em `/compras/insights`: painel consultivo **somente leitura** sobre demandas reais do tenant (status derivado, PCAs, objetos, valores estimados, backlog documental), complementado por **consultas simuladas PNCP/COMPRASNET** por objeto de contratação (preço de referência, faixa, contratos similares, fornecedores similares — rotulados *Dados simulados — MVP*).

**Gap atual**: rota existe como mock (`CedroModulePanel` + `cedroInsightsByModule.compras`); **não** há módulo API `compras-insights`, schema Prisma, nem `ComprasInsightsPage`.

**API** (`ci-api-v2`): novo submódulo `compras-insights` espelhando `gabinete-insights` / `ouvidoria-insights` — entidades `CompraInsightBatch/Insight/Evidence`, loader unificado sobre `CompraDemanda` + artefatos, regras determinísticas em `lib/aggregation/`, simulador PNCP em `lib/external/pncp-simulator.ts`, job diário, throttle 1h, export HTML.

**Client** (`ci-client-v2`): `ComprasInsightsPage` com componentes `shared/components/cedro/` (estendidos para `externalQueries` no rastreio), API client + mappers, override router `compras-insights`, MSW handlers.

## Technical Context

**Language/Version**: TypeScript 5.x / 6.x; Node.js 20 LTS

**Primary Dependencies**:

| Pacote | Stack |
|--------|-------|
| **ci-api-v2** | NestJS 11, Fastify, Pino, Zod, Prisma 7, PostgreSQL, `@nestjs/schedule` (existente) |
| **ci-client-v2** | React 19, Vite 8, Tailwind v4, shadcn/ui, react-router-dom 7, Vitest 3, MSW 2 |

**Storage**: PostgreSQL — **novas** entidades `CompraInsightBatch`, `CompraInsight`, `CompraInsightEvidence`; migration additive em `InsightCategory` (`external_benchmark`, `pricing`); leitura de `CompraDemanda`, `CompraPca`, `CompraPesquisaPrecos` e demais artefatos (018)

**Testing** (sem Postgres de teste dedicado):

| Camada | API | Client |
|--------|-----|--------|
| Unitário | Jest — regras operacionais, simulador PNCP, throttle, mappers | Vitest — mappers, simulador display |
| Componente | — | Vitest + RTL — shared cedro + ComprasInsightsPage |
| Contrato | fixtures JSON + Zod schemas | MSW + Zod response |
| Integração | use-cases + Prisma mock | api client + MSW |
| E2E | Supertest (deps mockadas) | Vitest journey MemoryRouter |

**Target Platform**: API Linux/container; SPA browser

**Project Type**: Full-stack (API + client)

**Performance Goals**: Consulta simulada ≤ 5s percebidos (SC-002); GET latest &lt; 500ms p95; recálculo ≤ 30s para até 500 demandas; export ≤ 30s com até 20 insights (SC-007)

**Constraints**:

- TDD obrigatório (Constitution II)
- Zod only — sem class-validator
- Tenant via AsyncLocalStorage
- Cedro read-only — **nunca** altera demandas/artefatos (SC-004)
- Copy: [regras-plataforma.md](../../../.cursor/docs/regras-plataforma.md) — *Consultar IA*, **Somente leitura**, sheet ~85%
- UI vocabulário **demanda/demandas** no domínio Compras
- PNCP/COMPRASNET **simulados** — copy explícita em cards, rastreio e export
- Testes **sem** banco Postgres separado

**Scale/Scope**: 1 schema Prisma novo, 1 migration enum, ~8 slugs de regra, 1 simulador externo, 1 loader, extensão leve shared Cedro (externalQueries), 1 página + API client, export HTML, ~40 arquivos teste

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Princípio | Status | Notas |
|-----------|--------|-------|
| I. Spec-Driven | ✅ PASS | Spec 020 + checklist validados |
| II. Test-First | ✅ PASS | test-strategy.md; CT-COM-INS/UI |
| III. Stack fixa | ✅ PASS | NestJS 11 + Prisma 7 + React 19 |
| IV. Multi-tenant | ✅ PASS | Lotes/insights com tenantId; guards módulo + Cedro |
| IV. Licenças | ✅ PASS | `@RequireLicenca('cedro')` + `@RequireModulo('compras')` |
| V. Escopo mínimo | ✅ PASS | Submódulo licenciado separado (padrão 007/015); reutiliza shared Cedro |

**Post-design re-check**: Enum migration additive; simulador PNCP isolado em lib pura; export HTML evita nova dependência PDF. Extensão `externalQueries` no shared Cedro é backward-compatible (opcional). Sem Complexity Tracking.

## Project Structure

### Documentation (this feature)

```text
specs/020-purchasing-insights/
├── plan.md              # Este arquivo
├── research.md          # Decisões técnicas (Phase 0)
├── data-model.md        # Entidades + slugs + trace payload
├── quickstart.md        # Validação manual + testes
├── contracts/
│   ├── rest-api-compras-insights.md
│   ├── client-compras-insights-ui.md
│   └── test-strategy.md
└── tasks.md             # Phase 2 — /speckit-tasks
```

### Source Code (repository root)

```text
ci-api-v2/
├── prisma/
│   ├── schema/compras-insights.prisma     # CompraInsightBatch/Insight/Evidence
│   └── migrations/YYYYMMDD_compras_insights/
├── src/modules/compras-insights/
│   ├── compras-insights.module.ts
│   ├── compras-insights.controller.ts     # @Controller('compras/insights')
│   ├── compras-insights.schemas.ts
│   ├── compras-insights.mapper.ts
│   ├── compras-insights.types.ts
│   ├── lib/
│   │   ├── aggregation/
│   │   │   ├── operational.rules.ts       # status, PCA, backlog artefatos
│   │   │   ├── pricing.rules.ts           # mediana, divergência externa
│   │   │   ├── external.rules.ts          # insights híbridos PNCP
│   │   │   └── index.ts
│   │   ├── external/pncp-simulator.ts     # simulador determinístico
│   │   ├── analysis-window.ts             # 90 dias (copiar padrão)
│   │   └── throttle.ts
│   ├── repository/
│   │   ├── load-compras-analysis-data.repository.ts
│   │   └── insight-*.repositories.ts
│   ├── use-cases/
│   │   ├── generate-insights.use-case.ts
│   │   ├── list-latest-insights.use-case.ts
│   │   ├── list-insight-batches.use-case.ts
│   │   ├── get-insight-batch-detail.use-case.ts
│   │   ├── get-insight-trace.use-case.ts
│   │   └── export-insights-report.use-case.ts
│   ├── jobs/generate-insights-scheduled.job.ts
│   └── test/
│       ├── fixtures/compras-analysis-sample.json
│       └── … specs por regra + use-cases

ci-client-v2/apps/web/src/modules/
├── shared/components/cedro/
│   ├── InsightTraceSheet.tsx              # + seção externalQueries (opcional)
│   └── types.ts                           # + CedroExternalQuery
├── compras/
│   ├── pages/ComprasInsightsPage.tsx      # novo — substitui mock
│   ├── api/insights.ts
│   ├── api/insights-mappers.ts
│   ├── fixtures/insights-*.json
│   └── __tests__/                         # page + contract + MSW
└── app/router.tsx                         # override 'compras-insights'
```

**Structure Decision**: Monorepo CI v2 — submódulo `compras-insights` separado de `compras` CRUD (padrão licença Cedro 007/012/015). Componentes Cedro em `shared` com extensão mínima para consultas externas simuladas. Derivação de status/progresso reutiliza lógica de `compras.mapper.ts` (import ou duplicar funções puras exportadas).

## Implementation Phases (preview for tasks)

### Phase A — API foundation (TDD)

1. RED: schema Zod + testes contrato REST
2. Prisma `compras-insights.prisma` + migration enum categories
3. RED: testes unitários simulador PNCP + regras operacionais
4. GREEN: loader + aggregation + generate use-case
5. Job agendado + throttle + trace com `externalQueries`
6. Export HTML use-case + rota GET export
7. Seed: enriquecer demandas Jacaranda para ≥ 3 categorias de insight

### Phase B — Client paridade (TDD)

1. Extender `InsightTraceSheet` + types (backward-compatible)
2. `compras/api/insights.ts` + mappers
3. `ComprasInsightsPage` — stats, panel, histórico, export, Consultar IA
4. Router override + MSW handlers
5. Regressão shared Cedro (Gabinete/Ouvidoria)

### Phase C — Polish

1. Banner stale (7d)
2. quickstart VS-001…005 manual
3. Remover dependência do mock `cedroInsightsByModule.compras` na rota real

## Complexity Tracking

> Nenhuma violação de constitution que exija justificativa formal.

| Item | Nota |
|------|------|
| Novo schema Prisma (3 tabelas) | Padrão Cedro por domínio — Ouvidoria/Gabinete já isolados |
| Simulador PNCP determinístico | Evita integração real; testável sem rede |
| Export HTML vs PDF | Spec aceita equivalente; sem pdfkit no repo |

## Artifacts Generated

| Artifact | Path |
|----------|------|
| Research | [research.md](./research.md) |
| Data model | [data-model.md](./data-model.md) |
| REST contract | [contracts/rest-api-compras-insights.md](./contracts/rest-api-compras-insights.md) |
| Client contract | [contracts/client-compras-insights-ui.md](./contracts/client-compras-insights-ui.md) |
| Test strategy | [contracts/test-strategy.md](./contracts/test-strategy.md) |
| Quickstart | [quickstart.md](./quickstart.md) |

## Next Step

Executar **`/speckit-tasks`** para gerar `tasks.md` acionável.
