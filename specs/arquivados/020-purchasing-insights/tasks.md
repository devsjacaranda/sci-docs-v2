---
description: "Task list for Insights IA Cedro Compras (020-purchasing-insights)"
---

# Tasks: Insights IA Cedro — Purchasing

**Input**: Design documents from `civ2-docs/specs/020-purchasing-insights/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md · **018 Purchasing CRUD** concluído

**Tests**: **Obrigatórios** — TDD (constitution II + plan.md + `contracts/test-strategy.md`): unitário, componente, contrato, integração (mocks) e E2E. **Sem Postgres de teste dedicado**.

**Organization**: 7 user stories (US1–US7). Caminhos relativos à raiz `ci-v2/`. Submódulo **`compras-insights` não existe** — criar do zero espelhando `gabinete-insights` / `ouvidoria-insights`.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Pode executar em paralelo (arquivos diferentes, sem dependências pendentes)
- **[Story]**: User story da spec (US1–US7)

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Fixtures, MSW, esqueleto do módulo API e client

- [X] T001 [P] Criar fixture `ci-api-v2/src/modules/compras-insights/test/fixtures/compras-analysis-sample.json` — demandas multi-status + PCAs + objetos + Pesquisas de Preços + backlog artefatos (≥10 registros)
- [X] T002 [P] Criar fixtures `ci-api-v2/src/modules/compras-insights/test/fixtures/pncp-simulator-cases.json`, `insight-batch-completed.json` e `insight-list-empty.json` — externalQueries + emptyReason variants
- [X] T003 [P] Criar fixtures client `ci-client-v2/apps/web/src/modules/compras/fixtures/insights-batch-completed.json` e `insights-empty.json` espelhando contrato REST
- [X] T004 [P] Adicionar handlers MSW em `ci-client-v2/apps/web/src/test/msw/handlers/compras-insights.ts` e registrar em `ci-client-v2/apps/web/src/test/msw/handlers.ts`
- [X] T005 [P] Criar esqueleto módulo `ci-api-v2/src/modules/compras-insights/` — `compras-insights.module.ts`, `compras-insights.controller.ts`, `compras-insights.schemas.ts`, `compras-insights.types.ts`, `compras-insights.mapper.ts` (stubs exportáveis)
- [X] T006 [P] Exportar funções puras de derivação de `ci-api-v2/src/modules/compras/compras.mapper.ts` (`deriveDemandaStatus`, `deriveProgress`, `buildChecklist`, `countSatisfiedArtefacts`) para reuso no loader — sem alterar comportamento existente (regressão testes compras)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Prisma, migration enum, loader, orquestrador, repos persistência — **bloqueia todas as user stories**

**⚠️ CRITICAL**: Nenhuma user story começa antes desta fase

### Tests first (TDD — RED)

- [X] T007 [P] Escrever testes (RED) `load-compras-analysis-data.repository.spec.ts` em `ci-api-v2/src/modules/compras-insights/test/repository/load-compras-analysis-data.repository.spec.ts` — janela 90d, soft delete, status derivado, artefatos
- [X] T008 [P] Escrever testes (RED) `compras-insights.mapper.spec.ts` em `ci-api-v2/src/modules/compras-insights/test/compras-insights.mapper.spec.ts` — `buildTraceRecord` → `module: 'compras'`, `externalQueries` quando slug externo, link demanda
- [X] T009 [P] Escrever testes (RED) `aggregation.index.spec.ts` em `ci-api-v2/src/modules/compras-insights/lib/aggregation/aggregation.index.spec.ts` — orquestrador compõe candidatos e filtra null

### Schema & types

- [X] T010 Criar `ci-api-v2/prisma/schema/compras-insights.prisma` — `CompraInsightBatch`, `CompraInsight`, `CompraInsightEvidence`; registrar relações Tenant em `ci-api-v2/prisma/schema/schema.prisma` se necessário
- [X] T011 Estender enum `InsightCategory` em `ci-api-v2/prisma/schema/ouvidoria-insights.prisma` — adicionar `pricing`, `external_benchmark`; gerar migration em `ci-api-v2/prisma/migrations/`
- [X] T012 [P] Implementar `ci-api-v2/src/modules/compras-insights/compras-insights.types.ts` — `ComprasAnalysisData`, `DemandaForAnalysis`, `MIN_RECORDS_PER_DIMENSION = 5`, `CATEGORY_LABEL`, labels PT fonte interna/externa

### Implementation for Foundational

- [X] T013 [P] Copiar/adaptar `ci-api-v2/src/modules/compras-insights/lib/analysis-window.ts` e `lib/throttle.ts` de `gabinete-insights/lib/` — incluir `analysis-window.spec.ts` e `throttle.spec.ts`
- [X] T014 [P] Implementar repos em `ci-api-v2/src/modules/compras-insights/repository/insight-persistence.repositories.ts` e `insight-query.repositories.ts` — espelhar padrão `gabinete-insights/repository/`
- [X] T015 Implementar `load-compras-analysis-data.repository.ts` em `ci-api-v2/src/modules/compras-insights/repository/` (GREEN T007) — `CompraDemanda` + PCA + 7 artefatos + campos derivados
- [X] T016 [P] Criar `ci-api-v2/src/modules/compras-insights/lib/aggregation/index.ts` — `aggregateComprasInsights(data, window)` (GREEN T009)
- [X] T017 Implementar `ci-api-v2/src/modules/compras-insights/compras-insights.mapper.ts` — list items, batch, trace com `externalQueries` opcional (GREEN T008)
- [X] T018 [P] Implementar `ci-api-v2/src/modules/compras-insights/compras-insights.schemas.ts` + `compras-insights.schemas.spec.ts` — Zod shapes conforme `contracts/rest-api-compras-insights.md`
- [X] T019 Registrar `ComprasInsightsModule` em `ci-api-v2/src/app.module.ts`; controller `@Controller('compras/insights')` + `@RequireModulo('compras')` + `@RequireLicenca('cedro')`

**Checkpoint**: Migration aplicada; loader GREEN; mapper trace; module registrado; orquestrador vazio funcional

---

## Phase 3: User Story 3 — Insights operacionais de demandas e valores (Priority: P1)

**Goal**: Volume por status, concentração PCA, backlog artefatos, valor acima mediana, pesquisa ausente

**Independent Test**: `npm test -- operational.rules pricing.rules` passa CT-COM-INS-001…005; fixture sample produz ≥1 insight `operational` e ≥1 `pricing`

### Tests for User Story 3 (TDD — RED first)

- [X] T020 [P] [US3] Escrever testes (RED) `operational.rules.spec.ts` em `ci-api-v2/src/modules/compras-insights/lib/aggregation/operational.rules.spec.ts` — slugs `demand_volume_by_status`, `demand_concentration_by_pca`, `demand_artefact_backlog`; null se &lt;5 demandas
- [X] T021 [P] [US3] Escrever testes (RED) `pricing.rules.spec.ts` em `ci-api-v2/src/modules/compras-insights/lib/aggregation/pricing.rules.spec.ts` — slugs `demand_value_above_median`, `demand_missing_price_survey`; não inventa valor

### Implementation for User Story 3

- [X] T022 [US3] Implementar `operational.rules.ts` em `ci-api-v2/src/modules/compras-insights/lib/aggregation/` (GREEN T020)
- [X] T023 [US3] Implementar `pricing.rules.ts` em `ci-api-v2/src/modules/compras-insights/lib/aggregation/` (GREEN T021)
- [X] T024 [US3] Registrar regras US3 em `ci-api-v2/src/modules/compras-insights/lib/aggregation/index.ts`

**Checkpoint**: Regras operacionais e pricing puras testáveis sem DB

---

## Phase 4: User Story 2 — Consulta simulada PNCP/COMPRASNET (Priority: P1)

**Goal**: Simulador determinístico por objeto; insights preço referência, divergência, fornecedores similares — rotulados simulados

**Independent Test**: `npm test -- pncp-simulator external.rules` passa CT-COM-INS-006…008; objeto &lt;10 chars → confidence low

> **Paralelo**: Phase 3 e Phase 4 podem rodar em paralelo após Phase 2.

### Tests for User Story 2 (TDD — RED first)

- [X] T025 [P] [US2] Escrever testes (RED) `pncp-simulator.spec.ts` em `ci-api-v2/src/modules/compras-insights/lib/external/pncp-simulator.spec.ts` — determinismo hash, faixa preço, fornecedores fictícios, objeto curto
- [X] T026 [P] [US2] Escrever testes (RED) `external.rules.spec.ts` em `ci-api-v2/src/modules/compras-insights/lib/aggregation/external.rules.spec.ts` — slugs `external_price_reference`, `external_value_divergence`, `external_similar_suppliers`; sourceLabel simulado

### Implementation for User Story 2

- [X] T027 [US2] Implementar `pncp-simulator.ts` em `ci-api-v2/src/modules/compras-insights/lib/external/` (GREEN T025)
- [X] T028 [US2] Implementar `external.rules.ts` em `ci-api-v2/src/modules/compras-insights/lib/aggregation/` (GREEN T026)
- [X] T029 [US2] Registrar regras US2 em `ci-api-v2/src/modules/compras-insights/lib/aggregation/index.ts`; validar ≥3 categorias com fixture sample

**Checkpoint**: Pipeline produz insights internos + externos simulados

---

## Phase 5: User Story 4 — Geração híbrida, histórico e recálculo (Priority: P1)

**Goal**: Job diário, GET última geração, histórico batches, POST *Consultar IA* throttle 1h, conflito running

**Independent Test**: `npm test -- generate-insights` + job spec passam CT-COM-INS-010…011; histórico ≥2 lotes

**Depends on**: Phase 3–4 (regras registradas)

### Tests for User Story 4 (TDD — RED first)

- [X] T030 [P] [US4] Escrever testes (RED) `generate-insights.use-case.spec.ts` em `ci-api-v2/src/modules/compras-insights/test/use-cases/generate-insights.use-case.spec.ts` — persist mock, throttle 429, read-only (não altera CompraDemanda)
- [X] T031 [P] [US4] Escrever testes (RED) `list-latest-insights.use-case.spec.ts` em `ci-api-v2/src/modules/compras-insights/test/use-cases/list-latest-insights.use-case.spec.ts` — emptyReason `never_generated` | `insufficient_volume` | `no_data`
- [X] T032 [P] [US4] Escrever testes (RED) `list-insight-batches.use-case.spec.ts` e `get-insight-batch-detail.use-case.spec.ts` em `ci-api-v2/src/modules/compras-insights/test/use-cases/`
- [X] T033 [P] [US4] Escrever testes (RED) `generate-insights-scheduled.job.spec.ts` em `ci-api-v2/src/modules/compras-insights/jobs/` — origin `scheduled`
- [X] T034 [P] [US4] Escrever teste contrato (RED) `compras-insights.contract.spec.ts` em `ci-api-v2/src/modules/compras-insights/test/compras-insights.contract.spec.ts` — GET/POST shapes vs fixtures

### Implementation for User Story 4

- [X] T035 [US4] GREEN `generate-insights.use-case.ts`, `list-latest-insights.use-case.ts`, `list-insight-batches.use-case.ts`, `get-insight-batch-detail.use-case.ts` em `ci-api-v2/src/modules/compras-insights/use-cases/` (T030–T032)
- [X] T036 [US4] Implementar `generate-insights-scheduled.job.ts` em `ci-api-v2/src/modules/compras-insights/jobs/` (GREEN T033) — espelhar `gabinete-insights/jobs/`
- [X] T037 [US4] Implementar rotas em `ci-api-v2/src/modules/compras-insights/compras-insights.controller.ts` — GET `/`, `/batches`, `/batches/:id`, POST `/generate`, GET `/:id/trace` conforme `contracts/rest-api-compras-insights.md`
- [X] T038 [US4] GREEN contrato `compras-insights.contract.spec.ts` (T034)

**Checkpoint**: API Cedro Compras end-to-end com mocks; job agendado testado

---

## Phase 6: User Story 5 — Rastreabilidade Cedro (Priority: P1)

**Goal**: Sheet ~85% com passos, evidências demanda, seção PNCP simulado quando aplicável

**Independent Test**: `npm test -- get-insight-trace` CT-COM-INS-009; trace `module: 'compras'` + `externalQueries`

### Tests for User Story 5 (TDD — RED first)

- [X] T039 [P] [US5] Escrever testes (RED) `get-insight-trace.use-case.spec.ts` em `ci-api-v2/src/modules/compras-insights/test/use-cases/get-insight-trace.use-case.spec.ts` — reasoningSteps, records demanda, externalQueries PNCP
- [X] T040 [P] [US5] Escrever testes (RED) extensão `InsightTraceSheet.test.tsx` em `ci-client-v2/apps/web/src/modules/shared/components/cedro/__tests__/InsightTraceSheet.test.tsx` — seção externa simulada + link `/compras/:id`

### Implementation for User Story 5

- [X] T041 [US5] GREEN `get-insight-trace.use-case.ts` em `ci-api-v2/src/modules/compras-insights/use-cases/` (T039)
- [X] T042 [P] [US5] Estender `ci-client-v2/apps/web/src/modules/shared/components/cedro/types.ts` — `CedroExternalQuery`; atualizar `CedroInsightTraceResponse.externalQueries?`
- [X] T043 [US5] Estender `ci-client-v2/apps/web/src/modules/shared/components/cedro/InsightTraceSheet.tsx` — render condicional seção *PNCP/COMPRASNET — simulado* + disclaimer (GREEN T040); regressão Gabinete/Ouvidoria

**Checkpoint**: Rastreio API + sheet shared com consultas externas

---

## Phase 7: User Story 1 — Painel Insights IA funcional (Priority: P1) 🎯 MVP UI

**Goal**: Paridade Cedro — cards, stats, histórico, *Consultar IA*, badge Somente leitura, chip *Dados simulados — MVP*

**Independent Test**: VS-001 quickstart — `/compras/insights` com insights reais, CT-COM-UI-001…003

**Depends on**: Phase 5–6 (API + trace)

### Tests for User Story 1 (TDD — RED first)

- [X] T044 [P] [US1] Escrever testes (RED) `insights-mappers.test.ts` em `ci-client-v2/apps/web/src/modules/compras/__tests__/insights-mappers.test.ts` — impactLabel, formatGeneratedAt, sourceLabel simulado
- [X] T045 [P] [US1] Escrever testes (RED) `insights.contract.test.ts` em `ci-client-v2/apps/web/src/modules/compras/__tests__/insights.contract.test.ts` — Zod vs fixtures
- [X] T046 [US1] Escrever testes (RED) `ComprasInsightsPage.test.tsx` em `ci-client-v2/apps/web/src/modules/compras/__tests__/ComprasInsightsPage.test.tsx` — CT-COM-UI-001…003

### Implementation for User Story 1

- [X] T047 [P] [US1] Implementar `ci-client-v2/apps/web/src/modules/compras/api/insights-mappers.ts` (GREEN T044)
- [X] T048 [US1] Implementar `ci-client-v2/apps/web/src/modules/compras/api/insights.ts` — fetch latest, batches, batch detail, trace, generate `origin: 'on_demand'`; `InsightsApiError` throttle (GREEN T045)
- [X] T049 [US1] Criar `ci-client-v2/apps/web/src/modules/compras/pages/ComprasInsightsPage.tsx` — header Insights IA, stats row, `InsightsPanel` + `InsightsHistoryPanel` + `InsightTraceSheet` shared, dialog *Consultar IA*, vocabulário **demanda** (GREEN T046)
- [X] T050 [US1] Override rota `compras-insights` em `ci-client-v2/apps/web/src/app/router.tsx` — lazy `ComprasInsightsPage` substituindo mock `ScreenPage`

**Checkpoint**: MVP UI — painel Compras substitui mock CedroModulePanel

---

## Phase 8: User Story 6 — Acesso, licença e estados vazios (Priority: P1)

**Goal**: 403 módulo, licença Cedro, emptyReason orientador, stale banner, zero insights fabricados, read-only

**Independent Test**: CT-COM-UI-006…007; VS-004 quickstart; SC-004 demanda inalterada pós-generate

### Tests for User Story 6 (TDD — RED first)

- [X] T051 [P] [US6] Estender `ComprasInsightsPage.test.tsx` — 403 AccessDenied403, emptyReason + CTA, banner `isStale` (RED CT-COM-UI-006…007)
- [X] T052 [P] [US6] Escrever testes (RED) `compras-insights.guards.spec.ts` em `ci-api-v2/src/modules/compras-insights/test/compras-insights.guards.spec.ts` — `@RequireModulo('compras')` + `@RequireLicenca('cedro')`; regressão CRUD base sem Cedro
- [X] T053 [P] [US6] Escrever teste (RED) read-only em `generate-insights.use-case.spec.ts` — snapshot CompraDemanda antes/depois generate (CT-COM-INS-011)

### Implementation for User Story 6

- [X] T054 [US6] Implementar estados vazios e banner stale em `ComprasInsightsPage.tsx` conforme `contracts/client-compras-insights-ui.md` (GREEN T051)
- [X] T055 [US6] Propagar `emptyReason` do API client; copy PT (*registre demandas para habilitar insights*) — vocabulário **demanda**
- [X] T056 [US6] GREEN testes guards (T052) e read-only (T053)

**Checkpoint**: Governança licença + empty states; SC-004/SC-006 atendidos

---

## Phase 9: User Story 7 — Exportar relatório (Priority: P2)

**Goal**: GET export HTML print-friendly; botão client; disclaimer PNCP; bloqueio sem geração

**Independent Test**: CT-COM-INS-013 + CT-COM-UI-008; VS-005 quickstart

**Depends on**: Phase 5 (API generate) + Phase 7 (UI)

### Tests for User Story 7 (TDD — RED first)

- [X] T057 [P] [US7] Escrever testes (RED) `export-insights-report.use-case.spec.ts` em `ci-api-v2/src/modules/compras-insights/test/use-cases/export-insights-report.use-case.spec.ts` — HTML com insights, badge consultivo, disclaimer simulado; 422 sem geração
- [X] T058 [P] [US7] Estender `ComprasInsightsPage.test.tsx` — botão *Exportar relatório* download blob (RED CT-COM-UI-008)

### Implementation for User Story 7

- [X] T059 [US7] Implementar `export-insights-report.use-case.ts` em `ci-api-v2/src/modules/compras-insights/use-cases/` (GREEN T057)
- [X] T060 [US7] Adicionar rota `GET /compras/insights/export` em `compras-insights.controller.ts`; client `exportComprasInsightsReport()` em `ci-client-v2/apps/web/src/modules/compras/api/insights.ts`
- [X] T061 [US7] Botão *Exportar relatório* em `ComprasInsightsPage.tsx` — desabilitado sem geração; orientação se vazio (GREEN T058)

**Checkpoint**: Export HTML funcional; SC-007 atendido

---

## Phase 10: Polish & Cross-Cutting Concerns

**Purpose**: Seed demo, validação manual, documentação status

- [X] T062 [P] Enriquecer seed Jacaranda em `ci-api-v2/prisma/seed/` — demandas DEAE com objetos variados e Pesquisas de Preços para ≥3 categorias pós-generate
- [X] T063 [P] Atualizar handlers MSW `ci-client-v2/apps/web/src/test/msw/handlers/compras-insights.ts` com fixtures finais
- [X] T064 Executar suite completa: `npm test -- --testPathPatterns=compras-insights` (API) + `npm run test --workspace=@ci/web -- --run ComprasInsights` + regressão `GabineteInsights` + `OuvidoriaInsights`
- [X] T065 Validar manualmente quickstart VS-001…VS-005 em `civ2-docs/specs/020-purchasing-insights/quickstart.md`
- [X] T066 [P] Criar `civ2-docs/specs/020-purchasing-insights/STATUS.md` — entregas, comandos validação, dívidas
- [X] T067 [P] Marcar tasks concluídas `[X]` neste arquivo após merge-ready
- [X] T068 [P] Seed Jacaranda — 10 demandas DEAE realistas + batch insights Cedro pré-gerado; remover mock PNCP da pipeline e UI

---

## Dependencies & Execution Order

### Phase Dependencies

```text
Phase 1 (Setup)
    ↓
Phase 2 (Foundational) — BLOCKS ALL
    ↓
Phase 3 (US3) ──┐
Phase 4 (US2) ──┘── paralelo após Phase 2
    ↓
Phase 5 (US4) — generate + history + job
    ↓
Phase 6 (US5) — trace + sheet externalQueries
    ↓
Phase 7 (US1) — MVP UI
    ↓
Phase 8 (US6) — access + empty + read-only
    ↓
Phase 9 (US7) — export P2
    ↓
Phase 10 (Polish)
```

### User Story Dependencies

| Story | Depende de | Entrega independente |
|-------|------------|----------------------|
| US3 | Phase 2 | Regras operacionais + pricing unit test |
| US2 | Phase 2 | Simulador PNCP + regras externas unit test |
| US4 | US2 + US3 | API generate/history/throttle |
| US5 | US4 | Trace + externalQueries |
| US1 | US4 + US5 | Painel UI paridade |
| US6 | US1 | Empty/access/stale/read-only |
| US7 | US1 + US4 | Export HTML |

### Parallel Opportunities

- **Phase 1**: T001–T006 em paralelo
- **Phase 2 RED**: T007–T009 em paralelo; T012–T014 em paralelo após T010–T011
- **Phase 3–4**: após Phase 2, dois devs em US3/US2 simultaneamente
- **Phase 5 RED**: T030–T034 em paralelo
- **Phase 7 RED**: T044–T045 em paralelo

### Parallel Example: User Stories 2 & 3

```bash
# Após Phase 2 complete:
Dev A: T020→T022→T024  # operational + pricing rules
Dev B: T025→T027→T029  # pncp-simulator + external rules
# Merge index.ts antes de Phase 5
```

---

## Implementation Strategy

### MVP First (API mínimo + UI básica)

1. Phase 1 + Phase 2 (foundational)
2. Phase 3 (US3) — `demand_volume_by_status` + `demand_concentration_by_pca`
3. Phase 5 (US4) — generate + list latest
4. Phase 7 (US1) — painel com cards reais
5. **STOP e VALIDAR** VS-001 quickstart

### Entrega incremental completa

1. Setup + Foundational
2. US3 → US2 (regras API)
3. US4 (persistência + histórico)
4. US5 (rastreio PNCP)
5. US1 (UI paridade)
6. US6 + US7 + Polish

### Parallel Team Strategy

| Dev | Fases |
|-----|-------|
| A | Phase 2 + US3 + US4 generate |
| B | US2 simulador PNCP + US5 trace |
| C | US1 client + US6 empty/access |

---

## Notes

- TDD: RED antes de GREEN em cada fase de testes
- Client POST generate: usar `origin: 'on_demand'` — nunca `'manual'`
- Copy: *Consultar IA*, **Somente leitura**, *Dados simulados — MVP*, vocabulário **demanda/demandas**
- Regressão shared Cedro + compras CRUD obrigatória após T043, T064
- Não usar hook `update-agent-context.ps1` neste repo — atualizar `specify-rules.mdc` manualmente (preserva conteúdo rico)
- Commit sugerido após cada checkpoint de fase
