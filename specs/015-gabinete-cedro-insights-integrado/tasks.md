---
description: "Task list for Insights Cedro Gabinete integrado (015-gabinete-cedro-insights-integrado)"
---

# Tasks: Insights Cedro — Gabinete (integração completa)

**Input**: Design documents from `civ2-docs/specs/015-gabinete-cedro-insights-integrado/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Tests**: **Obrigatórios** — TDD (constitution II + plan.md + `contracts/test-strategy.md`): unitário, componente, contrato, integração (mocks/in-memory) e E2E. **Sem Postgres de teste dedicado**.

**Organization**: 7 user stories P1 (US1–US7). Caminhos relativos à raiz `ci-v2/`. Submódulo API e client **já existem** (012 parcial) — tasks **completam** agregações e UI.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Pode executar em paralelo (arquivos diferentes, sem dependências pendentes)
- **[Story]**: User story da spec (US1–US7)

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Fixtures, MSW, esqueleto shared Cedro

- [X] T001 [P] Criar fixture `ci-api-v2/src/modules/gabinete-insights/test/fixtures/gabinete-analysis-sample.json` — atos + protocolos + controles + notificações + autos + tramitados (≥15 registros variados)
- [X] T002 [P] Atualizar fixtures `ci-api-v2/src/modules/gabinete-insights/test/fixtures/insight-batch-completed.json` e `insight-list-empty.json` — multi-categoria + emptyReason variants
- [X] T003 [P] Criar fixtures client `ci-client-v2/apps/web/src/modules/gabinete/fixtures/insights-batch-completed.json` e `insights-empty.json` espelhando contrato REST
- [X] T004 [P] Adicionar handlers MSW em `ci-client-v2/apps/web/src/test/msw/handlers/gabinete-insights.ts` e registrar em `ci-client-v2/apps/web/src/test/msw/handlers.ts`
- [X] T005 [P] Criar esqueleto `ci-client-v2/apps/web/src/modules/shared/components/cedro/` (index barrel opcional)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Migration enum, loader unificado, orquestrador de agregação, fix mapper trace — **bloqueia todas as user stories**

**⚠️ CRITICAL**: Nenhuma user story começa antes desta fase

### Tests first (TDD — RED)

- [X] T006 [P] Escrever testes (RED) `load-gabinete-analysis-data.repository.spec.ts` em `ci-api-v2/src/modules/gabinete-insights/test/repository/load-gabinete-analysis-data.repository.spec.ts` — janela 90d, soft delete, standalone cadastros
- [X] T007 [P] Escrever testes (RED) `gabinete-insights.mapper.spec.ts` em `ci-api-v2/src/modules/gabinete-insights/test/gabinete-insights.mapper.spec.ts` — `buildTraceRecord` deve retornar `module: 'gabinete'`, omitir PII
- [X] T008 [P] Escrever testes (RED) `aggregation.index.spec.ts` em `ci-api-v2/src/modules/gabinete-insights/lib/aggregation/aggregation.index.spec.ts` — orquestrador chama regras e filtra null

### Schema & types

- [X] T009 Estender enum `InsightCategory` em `ci-api-v2/prisma/schema/ouvidoria-insights.prisma` — adicionar `protocol`, `control_numeric`, `enforcement`, `tramitacao`; gerar migration em `ci-api-v2/prisma/migrations/`
- [X] T010 [P] Atualizar `ci-api-v2/src/modules/gabinete-insights/gabinete-insights.types.ts` — interfaces `GabineteAnalysisData`, `ProtocoloForAnalysis`, etc.; `MIN_RECORDS_PER_DIMENSION = 5`; remover/substituir `MIN_DEMANDAS_FOR_INSIGHTS`; `CATEGORY_LABEL` com novos valores

### Implementation for Foundational

- [X] T011 Implementar `load-gabinete-analysis-data.repository.ts` em `ci-api-v2/src/modules/gabinete-insights/repository/` (GREEN T006) — queries paralelas CabinetDemanda, CabinetProtocolo, CabinetControleNumerico, CabinetControleNotificacao, CabinetControleAutoInfracao, CabinetDocumentoTramitado + Setor
- [X] T012 [P] Criar `ci-api-v2/src/modules/gabinete-insights/lib/aggregation/index.ts` — `aggregateGabineteInsights(data, window)` compõe candidatos (GREEN T008)
- [X] T013 Refatorar `ci-api-v2/src/modules/gabinete-insights/use-cases/generate-insights.use-case.ts` — usar loader unificado; remover gate global `MIN_DEMANDAS=3`; permitir lote com insights parciais por categoria
- [X] T014 [P] Mover `volume_by_status` de `ci-api-v2/src/modules/gabinete-insights/lib/aggregation/volume.rules.ts` para `operational.rules.ts`; manter re-export ou deprecar `volume.rules.ts`
- [X] T015 Corrigir `ci-api-v2/src/modules/gabinete-insights/gabinete-insights.mapper.ts` — `buildTraceRecord` → `module: 'gabinete'`, labels status/origem ato, links `demandaId`; remover copy ouvidoria (GREEN T007)
- [X] T016 [P] Atualizar `ci-api-v2/src/modules/gabinete-insights/gabinete-insights.module.ts` — registrar `LoadGabineteAnalysisDataRepository`; desregistrar `LoadDemandasForAnalysisRepository` se substituído
- [X] T017 [P] Atualizar `ci-api-v2/src/modules/gabinete-insights/gabinete-insights.schemas.ts` e `gabinete-insights.schemas.spec.ts` — validar `emptyReason`, response batch completo conforme `contracts/rest-api-gabinete-insights.md`

**Checkpoint**: Migration aplicada; loader unificado GREEN; mapper trace corrigido; generate use-case usa novo pipeline

---

## Phase 3: User Story 2 — Insights operacionais de atos (Priority: P1)

**Goal**: Volume por status, mix origem, backlog/aging, gargalos encaminhamento, tempos entre eventos

**Independent Test**: `npm test -- operational.rules` passa CT-GAB-INS-001…003; fixture sample produz ≥1 insight `operational`

### Tests for User Story 2 (TDD — RED first)

- [X] T018 [P] [US2] Escrever testes (RED) `operational.rules.spec.ts` em `ci-api-v2/src/modules/gabinete-insights/lib/aggregation/operational.rules.spec.ts` — slugs `volume_by_status`, `origin_mix`, `backlog_aging`, `forwarding_bottleneck`, `timeline_durations`; null se &lt;5 registros

### Implementation for User Story 2

- [X] T019 [US2] Implementar regras em `ci-api-v2/src/modules/gabinete-insights/lib/aggregation/operational.rules.ts` (GREEN T018)
- [X] T020 [US2] Registrar regras operacionais em `ci-api-v2/src/modules/gabinete-insights/lib/aggregation/index.ts`

**Checkpoint**: Regras operacionais puras testáveis sem DB

---

## Phase 4: User Story 3 — Insights protocolo e controle numérico (Priority: P1)

**Goal**: Concentração forma entrada, tipo documento, protocolos órfãos; tipo documental dominante em controles numéricos

**Independent Test**: `npm test -- protocol.rules control-numeric.rules` passa CT-GAB-INS-004…005

> **Paralelo**: Phase 3 e Phase 4 podem rodar em paralelo após Phase 2.

### Tests for User Story 3 (TDD — RED first)

- [X] T021 [P] [US3] Escrever testes (RED) `protocol.rules.spec.ts` em `ci-api-v2/src/modules/gabinete-insights/lib/aggregation/protocol.rules.spec.ts` — `protocol_entry_mode`, `protocol_document_type`, `protocol_orphan`
- [X] T022 [P] [US3] Escrever testes (RED) `control-numeric.rules.spec.ts` em `ci-api-v2/src/modules/gabinete-insights/lib/aggregation/control-numeric.rules.spec.ts` — `control_numeric_by_type`

### Implementation for User Story 3

- [X] T023 [US3] Implementar `protocol.rules.ts` em `ci-api-v2/src/modules/gabinete-insights/lib/aggregation/` (GREEN T021)
- [X] T024 [US3] Implementar `control-numeric.rules.ts` em `ci-api-v2/src/modules/gabinete-insights/lib/aggregation/` (GREEN T022)
- [X] T025 [US3] Registrar regras US3 em `ci-api-v2/src/modules/gabinete-insights/lib/aggregation/index.ts`

**Checkpoint**: Insights protocolo e controle numérico geráveis a partir de cadastros standalone

---

## Phase 5: User Story 4 — Notificações, autos e documentos tramitados (Priority: P1)

**Goal**: Tendências notificações/autos (dedup `groupId`); concentração por setor tramitador

**Independent Test**: `npm test -- notifications.rules tramitados.rules` passa CT-GAB-INS-006…008

### Tests for User Story 4 (TDD — RED first)

- [X] T026 [P] [US4] Escrever testes (RED) `notifications.rules.spec.ts` em `ci-api-v2/src/modules/gabinete-insights/lib/aggregation/notifications.rules.spec.ts` — `notifications_trend`, `autos_trend`, `notification_auto_ratio`, dedup groupId
- [X] T027 [P] [US4] Escrever testes (RED) `tramitados.rules.spec.ts` em `ci-api-v2/src/modules/gabinete-insights/lib/aggregation/tramitados.rules.spec.ts` — `tramitados_by_sector`

### Implementation for User Story 4

- [X] T028 [US4] Implementar `notifications.rules.ts` em `ci-api-v2/src/modules/gabinete-insights/lib/aggregation/` (GREEN T026)
- [X] T029 [US4] Implementar `tramitados.rules.ts` em `ci-api-v2/src/modules/gabinete-insights/lib/aggregation/` (GREEN T027)
- [X] T030 [US4] Registrar regras US4 em `ci-api-v2/src/modules/gabinete-insights/lib/aggregation/index.ts`; validar SC-007 com fixture sample (≥3 categorias)

**Checkpoint**: Pipeline API produz insights integrados de todas as fontes Gabinete

---

## Phase 6: User Story 5 — Geração híbrida, histórico e recálculo (Priority: P1)

**Goal**: Job diário, GET última geração, histórico batches, POST *Consultar IA* throttle 1h, conflito running

**Independent Test**: `npm test -- generate-insights` + job spec passam CT-GAB-INS-010…011; histórico ≥2 lotes

**Depends on**: Phase 3–5 (regras registradas no orquestrador)

### Tests for User Story 5 (TDD — RED first)

- [X] T031 [P] [US5] Escrever testes (RED) `generate-insights.use-case.spec.ts` em `ci-api-v2/src/modules/gabinete-insights/test/use-cases/generate-insights.use-case.spec.ts` — persist mock, throttle 429, standalone sem atos
- [X] T032 [P] [US5] Escrever testes (RED) `list-latest-insights.use-case.spec.ts` em `ci-api-v2/src/modules/gabinete-insights/test/use-cases/list-latest-insights.use-case.spec.ts` — emptyReason `never_generated` | `insufficient_volume` | `no_data`
- [X] T033 [P] [US5] Escrever testes (RED) `list-insight-batches.use-case.spec.ts` e `get-insight-batch-detail.use-case.spec.ts` em `ci-api-v2/src/modules/gabinete-insights/test/use-cases/`
- [X] T034 [P] [US5] Escrever testes (RED) `generate-insights-scheduled.job.spec.ts` em `ci-api-v2/src/modules/gabinete-insights/jobs/` — origin `scheduled`
- [X] T035 [P] [US5] Escrever teste contrato (RED) `gabinete-insights.contract.spec.ts` em `ci-api-v2/src/modules/gabinete-insights/test/gabinete-insights.contract.spec.ts` — GET/POST shapes vs fixtures

### Implementation for User Story 5

- [X] T036 [US5] GREEN `generate-insights.use-case.ts`, `list-latest-insights.use-case.ts`, `list-insight-batches.use-case.ts`, `get-insight-batch-detail.use-case.ts` (T031–T033)
- [X] T037 [US5] Validar/enhance `ci-api-v2/src/modules/gabinete-insights/jobs/generate-insights-scheduled.job.ts` (GREEN T034)
- [X] T038 [US5] Validar rotas em `ci-api-v2/src/modules/gabinete-insights/gabinete-insights.controller.ts` — alinhar paths a `contracts/rest-api-gabinete-insights.md` (GET `/`, `/batches`, `/batches/:id`, POST `/generate`, GET `/:id/trace`)
- [X] T039 [US5] GREEN contrato `gabinete-insights.contract.spec.ts` (T035)

**Checkpoint**: API Cedro Gabinete completa end-to-end com mocks; job agendado testado

---

## Phase 7: User Story 6 — Rastreabilidade Cedro (Priority: P1)

**Goal**: Sheet ~85% com passos raciocínio, evidências, link ato; sem consultas externas

**Independent Test**: `npm test -- get-insight-trace` CT-GAB-INS-009; trace payload `module: 'gabinete'`

### Tests for User Story 6 (TDD — RED first)

- [X] T040 [P] [US6] Escrever testes (RED) `get-insight-trace.use-case.spec.ts` em `ci-api-v2/src/modules/gabinete-insights/test/use-cases/get-insight-trace.use-case.spec.ts` — reasoningSteps, records, sem externalQueries
- [X] T041 [P] [US6] Escrever testes (RED) `InsightTraceSheet.test.tsx` em `ci-client-v2/apps/web/src/modules/shared/components/cedro/__tests__/InsightTraceSheet.test.tsx` — abertura sheet, link `/gabinete/atos/:id`

### Implementation for User Story 6

- [X] T042 [US6] GREEN `get-insight-trace.use-case.ts` em `ci-api-v2/src/modules/gabinete-insights/use-cases/` (T040)
- [X] T043 [US6] Extrair `InsightTraceSheet.tsx` para `ci-client-v2/apps/web/src/modules/shared/components/cedro/InsightTraceSheet.tsx` parametrizado (`moduleId`, `detailPathPrefix`, `fetchTrace`)
- [X] T044 [US6] Refatorar `ci-client-v2/apps/web/src/modules/ouvidoria/components/InsightTraceSheet.tsx` → reexport/wrapper shared; rodar `npm run test -- InsightTraceSheet` ouvidoria (regressão)

**Checkpoint**: Rastreio API + sheet shared funcionais

---

## Phase 8: User Story 1 — Painel Insights IA funcional (Priority: P1) 🎯 MVP UI

**Goal**: Paridade Ouvidoria Cedro — cards completos, stats, histórico, *Consultar IA*, badge Somente leitura

**Independent Test**: VS-001 quickstart — `/gabinete/insights` com ≥3 categorias, fonte *Dados internos — Gabinete*, CT-GAB-UI-001…003

**Depends on**: Phase 5–7 (API + trace); shared Cedro components

### Tests for User Story 1 (TDD — RED first)

- [X] T045 [P] [US1] Escrever testes (RED) `insights-mappers.test.ts` em `ci-client-v2/apps/web/src/modules/gabinete/__tests__/insights-mappers.test.ts` — impactLabel, formatGeneratedAt, countHighImpact
- [X] T046 [P] [US1] Escrever testes (RED) `insights.contract.test.ts` em `ci-client-v2/apps/web/src/modules/gabinete/__tests__/insights.contract.test.ts` — Zod vs fixtures
- [X] T047 [P] [US1] Escrever testes (RED) `InsightsPanel.test.tsx` e `InsightsHistoryPanel.test.tsx` em `ci-client-v2/apps/web/src/modules/shared/components/cedro/__tests__/`
- [X] T048 [US1] Escrever testes (RED) `GabineteInsightsPage.test.tsx` em `ci-client-v2/apps/web/src/modules/gabinete/__tests__/GabineteInsightsPage.test.tsx` — CT-GAB-UI-001…003

### Implementation for User Story 1

- [X] T049 [P] [US1] Extrair `InsightCard.tsx`, `InsightsPanel.tsx`, `InsightsHistoryPanel.tsx` para `ci-client-v2/apps/web/src/modules/shared/components/cedro/` (GREEN T047)
- [X] T050 [US1] Implementar `ci-client-v2/apps/web/src/modules/gabinete/api/insights-mappers.ts` (GREEN T045)
- [X] T051 [US1] Expandir `ci-client-v2/apps/web/src/modules/gabinete/api/insights.ts` — fetch latest, batches, batch detail, trace, generate com `origin: 'on_demand'`; `InsightsApiError` throttle (GREEN T046)
- [X] T052 [US1] Reescrever `ci-client-v2/apps/web/src/modules/gabinete/pages/GabineteInsightsPage.tsx` — header Cedro, stats row, shared panels, dialog *Consultar IA*, integração trace sheet (GREEN T048)
- [X] T053 [US1] Refatorar `ci-client-v2/apps/web/src/modules/ouvidoria/pages/OuvidoriaInsightsPage.tsx` para consumir shared Cedro; rodar testes ouvidoria insights (regressão)

**Checkpoint**: MVP UI — painel Gabinete substitui lista simplificada; paridade funcional com Ouvidoria

---

## Phase 9: User Story 7 — Acesso, licença e estados vazios (Priority: P1)

**Goal**: 403 módulo, licença Cedro, emptyReason orientador, stale banner, zero insights fabricados

**Independent Test**: CT-GAB-UI-006/007/008; VS-004 quickstart

### Tests for User Story 7 (TDD — RED first)

- [X] T054 [P] [US7] Estender `GabineteInsightsPage.test.tsx` — cenários 403 AccessDenied403, emptyReason messages + CTA, banner `isStale` (RED CT-GAB-UI-006…008)
- [X] T055 [P] [US7] Escrever testes (RED) guards em `ci-api-v2/src/modules/gabinete-insights/test/gabinete-insights.guards.spec.ts` — `@RequireModulo('gabinete')` + `@RequireLicenca('cedro')`

### Implementation for User Story 7

- [X] T056 [US7] Implementar estados vazios e banner stale em `GabineteInsightsPage.tsx` conforme `contracts/client-gabinete-insights-ui.md` (GREEN T054)
- [X] T057 [US7] Validar `emptyReason` propagado do API client; ajustar copy PT (*cadastre atos e controles…*) — vocabulário **ato**
- [X] T058 [US7] GREEN testes guards (T055); confirmar item nav visível com 403 no client

**Checkpoint**: Todos cenários empty/access cobertos; SC-008 atendido

---

## Phase 10: Polish & Cross-Cutting Concerns

**Purpose**: Seed demo, validação manual, documentação status

- [X] T059 [P] Enriquecer `ci-api-v2/prisma/seed/seed-gabinete-demo.ts` — protocolos standalone, controles numéricos, notificações/autos agrupados, docs tramitados multi-setor (SC-007)
- [X] T060 [P] Atualizar handlers MSW `ci-client-v2/apps/web/src/test/msw/handlers/gabinete-insights.ts` com fixtures finais pós-implement
- [X] T061 Executar suite completa: `npm test -- --testPathPatterns=gabinete-insights` (API) + `npm run test --workspace=@ci/web -- --run GabineteInsights` + regressão `OuvidoriaInsights`
- [X] T062 Validar manualmente quickstart VS-001…VS-004 em `civ2-docs/specs/015-gabinete-cedro-insights-integrado/quickstart.md`
- [X] T063 [P] Criar `civ2-docs/specs/015-gabinete-cedro-insights-integrado/STATUS.md` — entregas, comandos validação, dívidas
- [X] T064 [P] Marcar tasks concluídas `[X]` neste arquivo após merge-ready

---

## Dependencies & Execution Order

### Phase Dependencies

```text
Phase 1 (Setup)
    ↓
Phase 2 (Foundational) — BLOCKS ALL
    ↓
Phase 3 (US2) ──┐
Phase 4 (US3) ──┼── paralelo após Phase 2
Phase 5 (US4) ──┘
    ↓
Phase 6 (US5) — integra regras + persistência
    ↓
Phase 7 (US6) — trace API + sheet shared
    ↓
Phase 8 (US1) — MVP UI (depende API + shared)
    ↓
Phase 9 (US7) — empty/access polish
    ↓
Phase 10 (Polish)
```

### User Story Dependencies

| Story | Depende de | Entrega independente |
|-------|------------|----------------------|
| US2 | Phase 2 | Regras operacionais unit test |
| US3 | Phase 2 | Regras protocolo/controle unit test |
| US4 | Phase 2 | Regras enforcement/tramitação unit test |
| US5 | US2–US4 | API generate/history/throttle |
| US6 | US5 | Trace payload + sheet |
| US1 | US5–US6 | Painel UI paridade |
| US7 | US1 | Empty/access/stale |

### Parallel Opportunities

- **Phase 1**: T001–T005 em paralelo
- **Phase 2 RED**: T006–T008 em paralelo
- **Phase 3–5**: após Phase 2, três devs em US2/US3/US4 simultaneamente
- **Phase 6 RED**: T031–T035 em paralelo
- **Phase 8 RED**: T045–T047 em paralelo; T049 extrair shared enquanto API finaliza

### Parallel Example: User Stories 2–4

```bash
# Após Phase 2 complete:
Dev A: T018→T019→T020  # operational.rules
Dev B: T021→T023→T025  # protocol + control-numeric
Dev C: T026→T028→T030  # notifications + tramitados
# Merge index.ts (T020, T025, T030) antes de Phase 6
```

---

## Implementation Strategy

### MVP First (API mínimo + UI básica)

1. Phase 1 + Phase 2 (foundational)
2. Phase 3 (US2) — pelo menos `volume_by_status` + `origin_mix`
3. Phase 6 (US5) — generate + list latest
4. Phase 8 (US1) — painel com cards reais
5. **STOP e VALIDAR** VS-001 quickstart

### Entrega incremental completa

1. Setup + Foundational
2. US2 → US3 → US4 (regras API)
3. US5 (persistência + histórico)
4. US6 (rastreio)
5. US1 (UI paridade)
6. US7 + Polish

### Parallel Team Strategy

| Dev | Fases |
|-----|-------|
| A | Phase 2 + US2 + US5 generate |
| B | US3 + US4 aggregation |
| C | US6 + US1 client shared |

---

## Notes

- TDD: RED antes de GREEN em cada fase de testes
- Nunca usar `origin: 'manual'` no client — usar `on_demand` (bug atual)
- Copy: *Consultar IA*, **Somente leitura**, vocabulário **ato/atos**
- Regressão Ouvidoria obrigatória após extrair shared Cedro (T044, T053, T061)
- Commit sugerido após cada checkpoint de fase
