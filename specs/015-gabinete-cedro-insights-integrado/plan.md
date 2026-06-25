# Implementation Plan: Insights Cedro — Gabinete (integração completa)

**Branch**: `015-gabinete-cedro-insights-integrado` | **Date**: 2026-06-24 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/015-gabinete-cedro-insights-integrado/spec.md`

## Summary

Completar **Insights IA Cedro** em `/gabinete/insights`: análise consultiva **somente leitura** integrando **atos**, **protocolos**, **controles numéricos**, **notificações/autos** e **documentos tramitados** — agregação determinística (sem LLM), geração híbrida (job diário + histórico + *Consultar IA* com throttle 1h).

**Gap atual (012 parcial)**: API só implementa `volume_by_status` e loader limitado a `CabinetDemanda`; client é lista simplificada sem rastreio/histórico; bugs de trace (`module: 'ouvidoria'`) e POST client (`origin: 'manual'`).

**API** (`ci-api-v2`): estender `gabinete-insights` — loader unificado, 13 regras em `lib/aggregation/`, migration enum `InsightCategory`, corrigir mapper/trace, seed demo enriquecido.

**Client** (`ci-client-v2`): extrair componentes Cedro shared; reescrever `GabineteInsightsPage` com paridade `OuvidoriaInsightsPage`; API client + mappers + testes MSW.

## Technical Context

**Language/Version**: TypeScript 5.x / 6.x; Node.js 20 LTS

**Primary Dependencies**:

| Pacote | Stack |
|--------|-------|
| **ci-api-v2** | NestJS 11, Fastify, Pino, Zod, Prisma 7, PostgreSQL, `@nestjs/schedule` (existente) |
| **ci-client-v2** | React 19, Vite 8, Tailwind v4, shadcn/ui, react-router-dom 7, Vitest 3, MSW 2 |

**Storage**: PostgreSQL — entidades `GabineteInsightBatch/Insight/Evidence` **existentes**; migration additive em `InsightCategory`; leitura de `CabinetDemanda`, `CabinetProtocolo`, `CabinetControleNumerico`, `CabinetControleNotificacao`, `CabinetControleAutoInfracao`, `CabinetDocumentoTramitado`, `Setor`

**Testing** (sem Postgres de teste dedicado):

| Camada | API | Client |
|--------|-----|--------|
| Unitário | Jest — 13 regras, throttle, mappers, analysis-window | Vitest — mappers, formatters |
| Componente | — | Vitest + RTL — shared cedro + GabineteInsightsPage |
| Contrato | fixtures JSON + Zod schemas | MSW + Zod response |
| Integração | use-cases + Prisma mock | api client + MSW |
| E2E | Supertest (deps mockadas) | Vitest journey MemoryRouter |

**Target Platform**: API Linux/container; SPA browser

**Project Type**: Full-stack (API + client)

**Performance Goals**: Recálculo ≤ 30s para até 10.000 atos + cadastros (SC-003); GET latest &lt; 500ms p95

**Constraints**:

- TDD obrigatório (Constitution II)
- Zod only — sem class-validator
- Tenant via AsyncLocalStorage
- Cedro read-only — nunca altera atos/protocolos/controles
- Copy: [regras-plataforma.md](../../../.cursor/docs/regras-plataforma.md) — *Consultar IA*, **Somente leitura**, sheet ~85%
- UI vocabulário **ato/atos** no Gabinete
- Testes **sem** banco Postgres separado

**Scale/Scope**: 1 migration enum, ~13 arquivos regras, 1 loader unificado, 4 componentes shared, 1 página refatorada + 1 reescrita, ~35 arquivos teste

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Princípio | Status | Notas |
|-----------|--------|-------|
| I. Spec-Driven | ✅ PASS | Spec 015 + checklist validados |
| II. Test-First | ✅ PASS | test-strategy.md; CT-GAB-INS/UI |
| III. Stack fixa | ✅ PASS | NestJS 11 + Prisma 7 + React 19 |
| IV. Multi-tenant | ✅ PASS | Lotes/insights com tenantId; guards módulo + Cedro |
| IV. Licenças | ✅ PASS | `@RequireLicenca('cedro')` |
| V. Escopo mínimo | ✅ PASS | Completa submódulo existente; shared Cedro evita duplicação |

**Post-design re-check**: Migration additive enum — sem violação. Refator Ouvidoria → shared Cedro é regressão testada, escopo controlado. Sem Complexity Tracking.

## Project Structure

### Documentation (this feature)

```text
specs/015-gabinete-cedro-insights-integrado/
├── plan.md              # Este arquivo
├── research.md          # Decisões técnicas (Phase 0)
├── data-model.md        # Entidades + slugs + trace payload
├── quickstart.md        # Validação manual + testes
├── contracts/
│   ├── rest-api-gabinete-insights.md
│   ├── client-gabinete-insights-ui.md
│   └── test-strategy.md
└── tasks.md             # Phase 2 — /speckit-tasks
```

### Source Code (repository root)

```text
ci-api-v2/
├── prisma/
│   ├── schema/ouvidoria-insights.prisma   # + enum InsightCategory values
│   └── migrations/YYYYMMDD_gabinete_insight_categories/
├── src/modules/gabinete-insights/
│   ├── lib/aggregation/
│   │   ├── operational.rules.ts          # expandir
│   │   ├── protocol.rules.ts             # novo
│   │   ├── control-numeric.rules.ts      # novo
│   │   ├── notifications.rules.ts        # novo
│   │   ├── tramitados.rules.ts           # novo
│   │   └── index.ts                      # aggregateGabineteInsights
│   ├── repository/
│   │   ├── load-gabinete-analysis-data.repository.ts  # novo (substitui loader parcial)
│   │   └── … (persistence/query existentes)
│   ├── use-cases/                        # ajustar generate + trace
│   ├── jobs/                             # existente
│   ├── gabinete-insights.mapper.ts       # fix buildTraceRecord → gabinete
│   └── test/                             # + fixtures + specs por regra
└── prisma/seed/
    └── seed-gabinete-demo.ts             # enriquecer cadastros insights

ci-client-v2/apps/web/src/modules/
├── shared/components/cedro/              # novo — extrair de ouvidoria
│   ├── InsightCard.tsx
│   ├── InsightsPanel.tsx
│   ├── InsightsHistoryPanel.tsx
│   └── InsightTraceSheet.tsx
├── ouvidoria/
│   ├── pages/OuvidoriaInsightsPage.tsx   # refator → shared
│   └── components/                       # deprecar/mover para shared
└── gabinete/
    ├── pages/GabineteInsightsPage.tsx    # reescrever paridade
    ├── api/insights.ts                   # expandir + mappers
    ├── fixtures/insights-*.json
    └── __tests__/                        # page + contract + MSW
```

**Structure Decision**: Monorepo CI v2 — API em `ci-api-v2`, client em `ci-client-v2/apps/web`. Submódulo `gabinete-insights` permanece separado de `gabinete` CRUD (padrão licença Cedro 007/012). Componentes Cedro em `shared` para paridade FR-022 sem duplicar UI.

## Implementation Phases (preview for tasks)

### Phase A — API aggregation (TDD)

1. RED: testes unitários 13 slugs com `gabinete-analysis-sample.json`
2. GREEN: implementar regras + loader unificado
3. Migration `InsightCategory` + atualizar labels
4. Ajustar `GenerateInsightsUseCase` — remover gate `MIN_DEMANDAS=3`, usar mínimo por dimensão (5)
5. Fix mapper trace (`module: 'gabinete'`, labels ato, omitir PII)
6. Integração use-cases + seed demo

### Phase B — Client paridade (TDD)

1. Extrair shared Cedro; refatorar Ouvidoria (regressão)
2. `gabinete/api/insights.ts` + mappers completos
3. Reescrever `GabineteInsightsPage`
4. MSW + testes CT-GAB-UI-*

### Phase C — Polish

1. Job stale banner (7d)
2. quickstart VS-001…004 manual
3. Documentar STATUS em spec folder pós-implement

## Complexity Tracking

> Nenhuma violação de constitution que exija justificativa formal.

| Item | Nota |
|------|------|
| Shared Cedro extraction | Reduz duplicação; regressão ouvidoria obrigatória |
| Enum migration | Necessário para SC-007 categorias distintas |

## Artifacts Generated

| Artifact | Path |
|----------|------|
| Research | [research.md](./research.md) |
| Data model | [data-model.md](./data-model.md) |
| REST contract | [contracts/rest-api-gabinete-insights.md](./contracts/rest-api-gabinete-insights.md) |
| Client contract | [contracts/client-gabinete-insights-ui.md](./contracts/client-gabinete-insights-ui.md) |
| Test strategy | [contracts/test-strategy.md](./contracts/test-strategy.md) |
| Quickstart | [quickstart.md](./quickstart.md) |

## Next Step

Executar **`/speckit-tasks`** para gerar `tasks.md` acionável.
