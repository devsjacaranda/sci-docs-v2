# Implementation Plan: Maturidade Carvalho — Ouvidoria

**Branch**: `009-ouvidoria-carvalho-maturidade` | **Date**: 2026-06-19 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/009-ouvidoria-carvalho-maturidade/spec.md`

## Summary

Implementar **Dashboard de Maturidade Carvalho** em `/ouvidoria/maturidade`: score híbrido nos 3 eixos (CI, GOV, TI) via fórmula R-50 (`round(0,6 × autoavaliação + 0,4 × conformidade Jatobá)`), autoavaliação trimestral da equipe, indicadores operacionais canônicos (volume, tempo médio, prazos vencidos, taxa resolução, satisfação híbrida), radar + evolução temporal (Nivo), rastreabilidade em sheet e **CRUD de planos de ação** com notas de progresso. **Somente leitura** para scores/indicadores — Carvalho nunca altera manifestações nem achados Jatobá.

**API** (`ci-api-v2`): submódulo `ouvidoria-maturidade` — regras puras em `lib/` (score híbrido, mapeamento Jatobá→eixos, indicadores), use-cases, repositories Prisma, REST sob `/ouvidoria/maturidade/*`, leitura cross-module de `ouvidoria-fiscalizacao` (último run), `@RequireModulo('ouvidoria')` + `@RequireLicenca('carvalho')`.

**Client** (`ci-client-v2`): `OuvidoriaMaturidadePage` + componentes Carvalho em `modules/ouvidoria/`; substituir mock `CarvalhoMaturityPanel` / `ScreenPage` para `ouvidoria-maturidade`; integrar alertas Carvalho em `license-alerts.ts` com score real da API.

**Testes (sem banco extra)**: unitário, componente, contrato, integração (mocks/in-memory) e E2E (Supertest + RTL journey com MSW) — ver [contracts/test-strategy.md](./contracts/test-strategy.md).

## Technical Context

**Language/Version**: TypeScript 5.x / 6.x; Node.js 20 LTS

**Primary Dependencies**:

| Pacote | Stack |
|--------|-------|
| **ci-api-v2** | NestJS 11, Fastify, Pino, Zod, Prisma 7, PostgreSQL |
| **ci-client-v2** | React 19, Vite 8, Tailwind v4, shadcn/ui, Nivo (`@nivo/radar`, `@nivo/line`), react-router-dom 7, Vitest 3, MSW 2 |

**Storage**: PostgreSQL — novas entidades de período, perguntas Carvalho, submissão/respostas, snapshot de score, plano de ação e notas; leitura de `Manifestacao`, `ManifestacaoEvento`, `OuvidoriaFiscalizacaoRun/Result/Check`, `OuvidoriaFiscalizacaoAnswer` (satisfação externa quando existir)

**Testing** (sem Postgres de teste dedicado):

| Camada | API | Client |
|--------|-----|--------|
| Unitário | Jest — hybrid-score, jatoba-axis-map, conformity-rate, self-assessment-score, indicators/* | Vitest — mappers score/alerta, Nivo data adapters |
| Componente | — | Vitest + RTL — radar, timeline, indicators, trace sheet, action plans |
| Contrato | Zod + fixtures JSON; Supertest valida body | Zod response + MSW handlers |
| Integração | Jest — use-cases + repositories com **Prisma mock** ou store in-memory | Vitest — api client + page + MSW |
| E2E | Supertest app Nest — **deps mockadas** (padrão `ouvidoria-insights.e2e-spec.ts`) | Vitest — página completa + MemoryRouter + MSW (jornada UI) |

**Target Platform**: API Linux/container; SPA browser

**Project Type**: Full-stack (API + client)

**Performance Goals**: GET dashboard &lt; 500ms p95; cálculo score + indicadores ≤ 2s para até 500 manifestações e 1 execução Jatobá

**Constraints**:

- TDD obrigatório (Constitution II); RED → GREEN → REFACTOR
- Zod only — sem class-validator
- Tenant via AsyncLocalStorage
- Carvalho read-only sobre manifestações/Jatobá — planos de ação são única escrita gerencial
- Fórmula R-50 fixa na v1 (60/40); score indisponível sem autoavaliação (FR-003)
- Fonte parcial quando Jatobá ausente (FR-004)
- Copy: [regras-plataforma.md](../../.cursor/docs/regras-plataforma.md) — Maturidade, Somente leitura, sheet **Como calculamos este score**
- Meta 80%; Crítico &lt; 70%; Atenção ≥ 70% e &lt; 80% (R-52, R-64/R-65)
- Satisfação híbrida: Jatobá externo (quando respostas escala existirem) + autoavaliação Carvalho
- **Testes**: **NUNCA** exigir banco Postgres separado — mocks Prisma, fixtures in-memory, MSW

**Scale/Scope**: ~8 entidades Prisma novas, ~12 endpoints REST, 1 página client + ~10 componentes, seed perguntas Carvalho, ~40 arquivos de teste

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Princípio | Status | Notas |
|-----------|--------|-------|
| I. Spec-Driven | ✅ PASS | Spec 009 validada; plano segue fluxo |
| II. Test-First | ✅ PASS | Cinco camadas documentadas em test-strategy; sem banco extra |
| III. Stack fixa | ✅ PASS | NestJS 11 + Prisma 7 + React 19 + Vite 8 + Nivo |
| IV. Multi-tenant | ✅ PASS | Entidades com `tenantId`; guards módulo + Carvalho |
| IV. Licenças | ✅ PASS | `@RequireLicenca('carvalho')`; read-only scores; Jatobá só leitura |
| V. Escopo mínimo | ✅ PASS | Submódulo `ouvidoria-maturidade`; client em `modules/ouvidoria/` |

**Post-design re-check**: Leitura cross-module de fiscalização via repository dedicado (sem acoplar use-cases Jatobá). Snapshots persistidos justificados por evolução temporal (FR-006, SC-009). Planos de ação com CRUD isolado. Sem Complexity Tracking necessário.

## Project Structure

### Documentation (this feature)

```text
specs/009-ouvidoria-carvalho-maturidade/
├── plan.md              # Este arquivo
├── research.md          # Decisões técnicas (Phase 0)
├── data-model.md        # Entidades Prisma maturidade
├── quickstart.md        # Validação manual + comandos de teste
├── contracts/
│   ├── rest-api-ouvidoria-maturidade.md
│   ├── client-ouvidoria-maturidade-ui.md
│   └── test-strategy.md
└── tasks.md             # Phase 2 — /speckit-tasks
```

### Source Code (repository root)

```text
ci-api-v2/
├── prisma/schema/
│   └── ouvidoria-maturidade.prisma    # Period, Question, Submission, Answer, Snapshot, ActionPlan, Note, Config
├── prisma/seed/
│   └── seed-maturidade-questions.ts   # perguntas Carvalho default por eixo
├── src/modules/ouvidoria-maturidade/
│   ├── ouvidoria-maturidade.module.ts
│   ├── ouvidoria-maturidade.controller.ts
│   ├── ouvidoria-maturidade.schemas.ts
│   ├── ouvidoria-maturidade.types.ts
│   ├── ouvidoria-maturidade.mapper.ts
│   ├── lib/
│   │   ├── hybrid-score.ts            # R-50 puro
│   │   ├── jatoba-axis-map.ts         # ruleId → eixo
│   │   ├── conformity-rate-by-axis.ts
│   │   ├── self-assessment-score.ts
│   │   ├── maturity-alert.ts          # critical/warning thresholds
│   │   └── indicators/
│   │       ├── volume.indicator.ts
│   │       ├── response-time.indicator.ts
│   │       ├── overdue-rate.indicator.ts
│   │       ├── resolution-rate.indicator.ts
│   │       └── satisfaction.indicator.ts
│   ├── repository/
│   ├── use-cases/
│   └── test/
│       ├── lib/
│       ├── use-cases/
│       └── integration/
└── test/
    └── ouvidoria-maturidade.e2e-spec.ts

ci-client-v2/apps/web/src/modules/ouvidoria/
├── api/
│   ├── maturidade.ts
│   └── maturidade-mappers.ts
├── components/
│   ├── MaturidadePanel.tsx
│   ├── MaturidadeScoreCards.tsx
│   ├── MaturidadeRadarChart.tsx
│   ├── MaturidadeTimelineChart.tsx
│   ├── MaturidadeIndicatorsRow.tsx
│   ├── MaturidadeTraceSheet.tsx
│   ├── SelfAssessmentDialog.tsx
│   ├── ActionPlansPanel.tsx
│   └── ActionPlanDialog.tsx
├── pages/
│   └── OuvidoriaMaturidadePage.tsx
├── fixtures/
│   └── maturidade-*.json
└── __tests__/
    ├── maturidade.contract.test.ts
    ├── maturidade-mappers.test.ts
    ├── MaturidadePanel.test.tsx
    ├── MaturidadeTraceSheet.test.tsx
    ├── ActionPlansPanel.test.tsx
    ├── OuvidoriaMaturidadePage.integration.test.tsx
    └── OuvidoriaMaturidadePage.e2e.test.tsx
```

**Structure Decision**: Submódulo API dedicado espelhando `ouvidoria-insights` (cálculo + persistência isolada). Regras em `lib/` sem Prisma para maximizar unit tests. Leitura Jatobá via repository query-only em `ouvidoria-fiscalizacao` tables. Client colocated em `ouvidoria/` com override de rota em `router.tsx` (padrão insights/auditoria).

## Complexity Tracking

> Vazio — sem violações de constitution que exijam justificativa.

## Phase Artifacts

| Artefato | Caminho |
|----------|---------|
| Research | [research.md](./research.md) |
| Data model | [data-model.md](./data-model.md) |
| REST contract | [contracts/rest-api-ouvidoria-maturidade.md](./contracts/rest-api-ouvidoria-maturidade.md) |
| UI contract | [contracts/client-ouvidoria-maturidade-ui.md](./contracts/client-ouvidoria-maturidade-ui.md) |
| Test strategy | [contracts/test-strategy.md](./contracts/test-strategy.md) |
| Quickstart | [quickstart.md](./quickstart.md) |

## Next Step

`/speckit-tasks` — TDD por camada conforme [test-strategy.md](./contracts/test-strategy.md).
