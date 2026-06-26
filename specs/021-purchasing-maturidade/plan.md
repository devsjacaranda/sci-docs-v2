# Implementation Plan: Maturidade Carvalho — Compras

**Branch**: `021-purchasing-maturidade` | **Date**: 2026-06-25 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/021-purchasing-maturidade/spec.md`

## Summary

Implementar **Maturidade Carvalho** em `/compras/maturidade`: questionário de autoavaliação por **4 dimensões de domínio** (Planejamento, Instrução processual, Conformidade, Resultados), score global e por dimensão, **score híbrido Jatobá somente na dimensão Conformidade** (R-50: 60/40), histórico trimestral, **orientações de melhoria** consultivas (sem action plans), persistência de **respostas parciais**, indicadores operacionais Compras (funil artefatos, inconsistências, conformidade licitatória) e **exportação HTML** de relatório. Carvalho é **somente leitura** sobre demandas e artefatos.

**API** (`ci-api-v2`): submódulo `compras-maturidade` — paridade estrutural `gabinete-maturidade`, adaptado a dimensões Compras; leitura cross-module de `compras-fiscalizacao`; guards `@RequireModulo('compras')` + `@RequireLicenca('carvalho')`.

**Client** (`ci-client-v2`): `ComprasMaturidadePage` reutilizando componentes Nivo/Carvalho de Ouvidoria; novos `MaturidadeOrientationsPanel` e export; substituir mock `compras-maturidade` em router.

**Dependências**: Base 018 (domínio Compras); Jatobá 019 **opcional** (enriquece Conformidade); Cedro 020 **sem integração**.

## Technical Context

**Language/Version**: TypeScript 5.x / 6.x; Node.js 20 LTS

**Primary Dependencies**:

| Pacote | Stack |
|--------|-------|
| **ci-api-v2** | NestJS 11, Fastify, Pino, Zod, Prisma 7, PostgreSQL |
| **ci-client-v2** | React 19, Vite 8, Tailwind v4, shadcn/ui, Nivo (`@nivo/radar`, `@nivo/line`), react-router-dom 7, Vitest 3, MSW 2 |

**Storage**: PostgreSQL — novas entidades `ComprasMaturidade*` (config, período, perguntas, submission draft/submitted, respostas, snapshot); leitura de `CompraDemanda`/artefatos via `compras.mapper.ts`; leitura de `ComprasFiscalizacaoRun/Check/Result` (spec 019)

**Testing** (sem Postgres de teste dedicado):

| Camada | API | Client |
|--------|-----|--------|
| Unitário | Jest — hybrid-score, self-assessment-score, improvement-orientations, jatoba-dimension-map, indicators/* | Vitest — mappers, chart adapters, orientations panel |
| Contrato | Zod + fixtures JSON; Supertest | Zod + MSW |
| Integração | Use-cases + Prisma mock | Page + MSW |
| E2E | Supertest Nest mock deps | RTL jornada completa |

**Target Platform**: API Linux/container; SPA browser

**Project Type**: Full-stack (API + client)

**Performance Goals**: GET dashboard &lt; 500ms p95; cálculo score ≤ 3s percebido (SC-002); export HTML ≤ 30s (SC-006)

**Constraints**:

- TDD obrigatório (Constitution II); RED → GREEN → REFACTOR
- Zod only — sem class-validator
- Tenant via AsyncLocalStorage — nunca `tenantId` manual
- Carvalho read-only sobre demandas/artefatos (FR-012, SC-005)
- Híbrido Jatobá **apenas** dimensão Conformidade (FR-007) — diverge de Gabinete/Ouvidoria
- Patamar *Adequado*: ≥ 60/100; meta institucional alertas: 80
- Vocabulário UI: **demanda/demandas**; rota `/compras/maturidade`
- Sem action plans nesta entrega (FR-015)
- Respostas parciais via submission `draft` + PATCH (FR-008)
- Copy: [regras-plataforma.md](../../../.cursor/docs/regras-plataforma.md), [licencas-canonicas.md](../../../.cursor/docs/licencas-canonicas.md)

**Scale/Scope**: ~6 entidades Prisma novas, ~9 endpoints REST, 1 página + ~8 componentes (6 reuso + 2 novos), seed ~16 perguntas, ~45 arquivos de teste

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Princípio | Status | Notas |
|-----------|--------|-------|
| I. Spec-Driven | ✅ PASS | Spec 021 validada; plano segue fluxo |
| II. Test-First | ✅ PASS | test-strategy.md; sem banco extra |
| III. Stack fixa | ✅ PASS | NestJS 11 + Prisma 7 + React 19 + Vite 8 + Nivo |
| IV. Multi-tenant | ✅ PASS | Entidades com `tenantId`; guards módulo + Carvalho |
| IV. Licenças | ✅ PASS | `@RequireLicenca('carvalho')`; read-only operação; Jatobá só leitura |
| V. Escopo mínimo | ✅ PASS | Submódulo `compras-maturidade`; client em `modules/compras/` |

**Post-design re-check**: Novo enum `ComprasMaturityDimension` justificado — dimensões de domínio distintas de CI/GOV/TI. Snapshots + draft submission justificados por FR-008 e histórico temporal. Leitura cross-module fiscalização via repository dedicado (padrão gabinete-maturidade). Sem Complexity Tracking necessário.

## Project Structure

### Documentation (this feature)

```text
specs/021-purchasing-maturidade/
├── plan.md              # Este arquivo
├── research.md          # Decisões técnicas (Phase 0)
├── data-model.md        # Entidades Prisma maturidade Compras
├── quickstart.md        # Validação manual + comandos de teste
├── contracts/
│   ├── rest-api-compras-maturidade.md
│   ├── client-compras-maturidade-ui.md
│   └── test-strategy.md
└── tasks.md             # Phase 2 — /speckit-tasks
```

### Source Code (repository root)

```text
ci-api-v2/
├── prisma/schema/
│   └── compras-maturidade.prisma       # Config, Period, Question, Submission, Answer, Snapshot
├── prisma/seed/
│   └── seed-compras-maturidade-questions.ts
├── src/modules/compras-maturidade/
│   ├── compras-maturidade.module.ts
│   ├── compras-maturidade.controller.ts
│   ├── compras-maturidade.schemas.ts
│   ├── compras-maturidade.types.ts
│   ├── compras-maturidade.mapper.ts
│   ├── lib/
│   │   ├── hybrid-score.ts             # reutilizar/adaptar de gabinete
│   │   ├── self-assessment-score.ts
│   │   ├── jatoba-dimension-map.ts     # agregação JAT-CMP-* → Conformidade
│   │   ├── conformity-rate.ts          # taxa única Conformidade
│   │   ├── improvement-orientations.ts # catálogo orientações
│   │   ├── maturity-alert.ts
│   │   ├── period-utils.ts
│   │   ├── export-report.ts            # HTML template
│   │   └── indicators/
│   │       ├── artefact-funnel.indicator.ts
│   │       ├── budget-inconsistency.indicator.ts
│   │       └── licitation-conformity.indicator.ts
│   ├── repository/
│   │   ├── maturidade-*.repositories.ts
│   │   └── fiscalizacao-read.repositories.ts
│   ├── use-cases/
│   │   ├── ensure-current-period.use-case.ts
│   │   ├── get-maturidade-dashboard.use-case.ts
│   │   ├── get-self-assessment.use-case.ts
│   │   ├── patch-self-assessment-answers.use-case.ts
│   │   ├── submit-self-assessment.use-case.ts
│   │   ├── compute-and-persist-score.use-case.ts
│   │   ├── compute-jatoba-conformity.use-case.ts
│   │   ├── compute-indicators.use-case.ts
│   │   ├── get-score-trace.use-case.ts
│   │   ├── get-indicator-trace.use-case.ts
│   │   └── export-maturidade-report.use-case.ts
│   └── test/
│       ├── fixtures/
│       └── *.spec.ts
└── test/
    └── compras-maturidade.e2e-spec.ts

ci-client-v2/apps/web/src/modules/compras/
├── api/
│   ├── maturidade.ts
│   ├── maturidade-mappers.ts
│   └── maturidade-chart-adapters.ts
├── pages/
│   └── ComprasMaturidadePage.tsx
├── components/maturidade/
│   ├── MaturidadeOrientationsPanel.tsx
│   └── MaturidadeExportButton.tsx
├── fixtures/
│   └── maturidade-dashboard-*.json
├── __tests__/
│   ├── ComprasMaturidadePage.integration.test.tsx
│   ├── ComprasMaturidadePage.e2e.test.tsx
│   └── maturidade.contract.test.ts
└── index.ts                            # COMPRAS_OVERRIDES + lazy export

ci-client-v2/apps/web/src/test/msw/handlers/
└── compras-maturidade.ts
```

**Structure Decision**: Submódulo API isolado espelhando `gabinete-maturidade/` (referência viva), client colocado em `modules/compras/` seguindo paridade `ComprasInsightsPage` / `ComprasFiscalizacaoPage`. Componentes Carvalho reusados de `modules/ouvidoria/components/` com props adaptadas para dimensões Compras.

## Phase 0 Output

Ver [research.md](./research.md) — 12 decisões resolvidas (dimensões, híbrido Conformidade-only, draft parcial, orientações, export HTML, indicadores Compras, seed).

## Phase 1 Output

| Artefato | Path |
|----------|------|
| Data model | [data-model.md](./data-model.md) |
| REST contract | [contracts/rest-api-compras-maturidade.md](./contracts/rest-api-compras-maturidade.md) |
| Client contract | [contracts/client-compras-maturidade-ui.md](./contracts/client-compras-maturidade-ui.md) |
| Test strategy | [contracts/test-strategy.md](./contracts/test-strategy.md) |
| Quickstart | [quickstart.md](./quickstart.md) |

## Complexity Tracking

> Nenhuma violação de constitution que exija justificativa.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| — | — | — |

## Next Step

Executar `/speckit-tasks` para gerar `tasks.md` acionável com dependências ordenadas (schema → API lib → use-cases → client → seed → e2e).
