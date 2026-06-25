---
description: "Task list for Insights Cedro Ouvidoria (007-ouvidoria-cedro-insights)"
---

# Tasks: Insights Cedro — Ouvidoria

**Input**: Design documents from `specs/007-ouvidoria-cedro-insights/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Tests**: **Obrigatórios** — TDD (constitution II + plan.md + `contracts/test-strategy.md`): unitário, componente, contrato, integração (mocks/in-memory) e E2E (Supertest + Vitest journey). **Sem banco Postgres de teste dedicado** — Prisma mock, fixtures JSON, MSW.

**Organization**: US2/US3/US6/US1/US7/US8 são P1; US4/US5 são P2. Caminhos relativos à raiz `ci-v2/`.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Pode executar em paralelo (arquivos diferentes, sem dependências pendentes)
- **[Story]**: User story da spec (US1–US8)

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Dependências, fixtures, MSW e scaffolding do submódulo

- [X] T001 Adicionar `@nestjs/schedule` em `ci-api-v2/package.json` e instalar
- [X] T002 [P] Documentar `INSIGHTS_CRON` (opcional) em `ci-api-v2/.env.example`
- [X] T003 [P] Criar fixtures `ci-api-v2/src/modules/ouvidoria-insights/test/fixtures/manifestacoes-sample.json` conforme `data-model.md`
- [X] T004 [P] Criar fixtures `ci-api-v2/src/modules/ouvidoria-insights/test/fixtures/insight-batch-completed.json` e `insight-list-empty.json`
- [X] T005 [P] Criar fixtures client `ci-client-v2/apps/web/src/modules/ouvidoria/fixtures/insights-batch-completed.json` e `insights-empty.json`
- [X] T006 [P] Adicionar handlers MSW em `ci-client-v2/apps/web/src/test/msw/handlers/ouvidoria-insights.ts` e registrar em `ci-client-v2/apps/web/src/test/msw/handlers.ts`
- [X] T007 Criar esqueleto `ci-api-v2/src/modules/ouvidoria-insights/ouvidoria-insights.module.ts` com pastas `lib/`, `repository/`, `use-cases/`, `jobs/`, `test/`
- [X] T008 Registrar `OuvidoriaInsightsModule` em `ci-api-v2/src/app.module.ts`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Schema Prisma, tipos base, schemas Zod, repositórios e libs puras — **bloqueia todas as user stories**

**⚠️ CRITICAL**: Nenhuma user story começa antes desta fase

### Tests first (TDD — RED)

- [X] T009 [P] Escrever testes (RED) `analysis-window.spec.ts` em `ci-api-v2/src/modules/ouvidoria-insights/lib/analysis-window.spec.ts` — janela 90 dias com `jest.useFakeTimers`
- [X] T010 [P] Escrever testes (RED) `insight-impact.spec.ts` em `ci-api-v2/src/modules/ouvidoria-insights/lib/insight-impact.spec.ts`
- [X] T011 [P] Escrever testes de contrato (RED) em `ci-api-v2/src/modules/ouvidoria-insights/ouvidoria-insights.schemas.spec.ts` — CT-INS-001, CT-INS-004, CT-INS-006 contra fixtures

### Schema & migration

- [X] T012 Criar `ci-api-v2/prisma/schema/ouvidoria-insights.prisma` — `OuvidoriaInsightBatch`, `OuvidoriaInsight`, `OuvidoriaInsightEvidence` + enums conforme `data-model.md`
- [X] T013 Registrar schema em `ci-api-v2/prisma/schema/schema.prisma` e gerar migration (`npx prisma migrate dev`)

### Implementation for Foundational

- [X] T014 [P] Implementar `analysis-window.ts` em `ci-api-v2/src/modules/ouvidoria-insights/lib/analysis-window.ts` (GREEN T009)
- [X] T015 [P] Implementar `insight-impact.ts` em `ci-api-v2/src/modules/ouvidoria-insights/lib/insight-impact.ts` (GREEN T010)
- [X] T016 Implementar Zod DTOs em `ci-api-v2/src/modules/ouvidoria-insights/ouvidoria-insights.schemas.ts` (GREEN T011)
- [X] T017 [P] Criar `ouvidoria-insights.types.ts` e mappers PT-BR (`impactLabel`, `originLabel`, `sourceLabel`) em `ci-api-v2/src/modules/ouvidoria-insights/ouvidoria-insights.mapper.ts`
- [X] T018 [P] Implementar `load-manifestacoes-for-analysis.repository.ts` + spec com Prisma mock em `ci-api-v2/src/modules/ouvidoria-insights/repository/`
- [X] T019 [P] Implementar repositórios persistência — `create-insight-batch.repository.ts`, `update-insight-batch-status.repository.ts`, `create-insight.repository.ts`, `create-insight-evidence.repository.ts` + specs mock Prisma
- [X] T020 [P] Implementar `find-latest-insight-batch.repository.ts`, `list-insight-batches.repository.ts`, `find-insight-batch-by-id.repository.ts`, `list-insights-by-batch.repository.ts` + specs mock Prisma
- [X] T021 Implementar `find-insight-by-id.repository.ts` e `find-last-on-demand-batch.repository.ts` (throttle) + specs em `ci-api-v2/src/modules/ouvidoria-insights/test/repository/`
- [X] T022 Registrar `ScheduleModule.forRoot()` e stub controller em `ci-api-v2/src/modules/ouvidoria-insights/ouvidoria-insights.controller.ts` com `@RequireModulo('ouvidoria')` e `@RequireLicenca('cedro')` em todas as rotas

**Checkpoint**: Schema migrado; libs puras GREEN; repositórios testados com mock; controller com guards

---

## Phase 3: User Story 2 — Insights operacionais (Priority: P1)

**Goal**: Regras determinísticas de volume, backlog, aging, tempos entre eventos e gargalos por setor

**Independent Test**: `npm test -- operational.rules` passa CT-INS-OP-*; fixture `manifestacoes-sample.json` produz ≥1 insight operacional

### Tests for User Story 2 (TDD — RED first)

- [X] T023 [P] [US2] Escrever testes (RED) `operational.rules.spec.ts` em `ci-api-v2/src/modules/ouvidoria-insights/lib/aggregation/operational.rules.spec.ts` — CT-INS-OP-001…003
- [X] T024 [P] [US2] Escrever testes (RED) `throttle.spec.ts` em `ci-api-v2/src/modules/ouvidoria-insights/lib/throttle.spec.ts` — 1h `on_demand` com fake timers

### Implementation for User Story 2

- [X] T025 [US2] Implementar `operational.rules.ts` em `ci-api-v2/src/modules/ouvidoria-insights/lib/aggregation/operational.rules.ts` (GREEN T023)
- [X] T026 [US2] Implementar `throttle.ts` (`isThrottled`, `retryAfterSeconds`) em `ci-api-v2/src/modules/ouvidoria-insights/lib/throttle.ts` (GREEN T024)

**Checkpoint**: Regras operacionais puras testáveis sem DB

---

## Phase 4: User Story 3 — Insights geográficos (Priority: P1)

**Goal**: Picos por município IBGE e bairro/zona vs média institucional

**Independent Test**: `npm test -- geographic.rules` passa CT-INS-GEO-001

> **Paralelo**: Phase 3 e Phase 4 podem rodar em paralelo após Phase 2.

### Tests for User Story 3 (TDD — RED first)

- [X] T027 [P] [US3] Escrever testes (RED) `geographic.rules.spec.ts` em `ci-api-v2/src/modules/ouvidoria-insights/lib/aggregation/geographic.rules.spec.ts`

### Implementation for User Story 3

- [X] T028 [US3] Implementar `geographic.rules.ts` em `ci-api-v2/src/modules/ouvidoria-insights/lib/aggregation/geographic.rules.ts` (GREEN T027)

**Checkpoint**: Regras geográficas puras; registros sem endereço não forçam localização

---

## Phase 5: User Story 4 — Padrões de texto simples (Priority: P2)

**Goal**: Top-N termos/assuntos por contagem determinística (sem NLP)

**Independent Test**: `npm test -- text-frequency.rules` passa CT-INS-TXT-001; omite se &lt;5 manifestações

### Tests for User Story 4 (TDD — RED first)

- [X] T029 [P] [US4] Escrever testes (RED) `text-frequency.rules.spec.ts` em `ci-api-v2/src/modules/ouvidoria-insights/lib/aggregation/text-frequency.rules.spec.ts`

### Implementation for User Story 4

- [X] T030 [US4] Implementar `text-frequency.rules.ts` em `ci-api-v2/src/modules/ouvidoria-insights/lib/aggregation/text-frequency.rules.ts` (GREEN T029)

---

## Phase 6: User Story 5 — Mix de prioridade e perfil (Priority: P2)

**Goal**: Taxa anônimas, proporções tipo/prioridade, correlações consultivas

**Independent Test**: `npm test -- profile.rules` passa CT-INS-PRF-001

### Tests for User Story 5 (TDD — RED first)

- [X] T031 [P] [US5] Escrever testes (RED) `profile.rules.spec.ts` em `ci-api-v2/src/modules/ouvidoria-insights/lib/aggregation/profile.rules.spec.ts`

### Implementation for User Story 5

- [X] T032 [US5] Implementar `profile.rules.ts` em `ci-api-v2/src/modules/ouvidoria-insights/lib/aggregation/profile.rules.ts` (GREEN T031)

---

## Phase 7: User Story 6 — Geração híbrida, histórico e recálculo (Priority: P1)

**Goal**: Job diário, persistência de lotes, GET última geração, histórico de batches, POST *Consultar IA* com throttle 1h

**Independent Test**: `npm run test:e2e -- ouvidoria-insights` CT-INS-001/003/005/006; `generate-insights.integration-spec.ts` GREEN

**Depends on**: Phase 3 (operacional mínimo); Phase 4 para insights geo em geração completa; Phase 5/6 opcionais para geração rica

### Tests for User Story 6 (TDD — RED first)

- [X] T033 [US6] Escrever testes (RED) `generate-insights.use-case.spec.ts` em `ci-api-v2/src/modules/ouvidoria-insights/test/use-cases/generate-insights.use-case.spec.ts` — orquestra rules + persist mock
- [X] T034 [P] [US6] Escrever testes (RED) `list-latest-insights.use-case.spec.ts` e `list-insight-batches.use-case.spec.ts` em `ci-api-v2/src/modules/ouvidoria-insights/test/use-cases/`
- [X] T035 [P] [US6] Escrever testes (RED) `get-insight-batch-detail.use-case.spec.ts` em `ci-api-v2/src/modules/ouvidoria-insights/test/use-cases/`
- [X] T036 [US6] Escrever teste integração (RED) `generate-insights.integration-spec.ts` em `ci-api-v2/src/modules/ouvidoria-insights/test/integration/generate-insights.integration-spec.ts` — store in-memory, sem Postgres

### Implementation for User Story 6

- [X] T037 [US6] Implementar `generate-insights.use-case.ts` — agrega US2–US5 rules, persiste batch/insights/evidences, status `running|completed|failed` (GREEN T033)
- [X] T038 [P] [US6] Implementar `list-latest-insights.use-case.ts` e `list-insight-batches.use-case.ts` (GREEN T034)
- [X] T039 [P] [US6] Implementar `get-insight-batch-detail.use-case.ts` (GREEN T035)
- [X] T040 [US6] Implementar `generate-insights-scheduled.job.ts` em `ci-api-v2/src/modules/ouvidoria-insights/jobs/` + spec com fake timers
- [X] T041 [US6] Implementar endpoints em `ouvidoria-insights.controller.ts`: `GET /ouvidoria/insights`, `GET /ouvidoria/insights/batches`, `GET /ouvidoria/insights/batches/:batchId`, `POST /ouvidoria/insights/generate` conforme `contracts/rest-api-ouvidoria-insights.md`
- [X] T042 [US6] GREEN integração `generate-insights.integration-spec.ts` (INT-INS-001…003)
- [X] T043 [US6] Escrever E2E (RED) `ci-api-v2/test/ouvidoria-insights.e2e-spec.ts` — CT-INS-001, CT-INS-003, CT-INS-005, CT-INS-006 com Prisma mock + `tenantLicenca` inclui `cedro`
- [X] T044 [US6] GREEN E2E Supertest `ouvidoria-insights.e2e-spec.ts` (E2E-INS-001, E2E-INS-003)

**Checkpoint**: API gera, persiste, lista e throttle sem alterar manifestações (mock call counts SC-005)

---

## Phase 8: User Story 7 — Rastreabilidade Cedro (Priority: P1)

**Goal**: `GET /ouvidoria/insights/:id/trace` + sheet UI sem `externalQueries`

**Independent Test**: CT-INS-004, CT-INS-008; CMP-INS-004/005 GREEN

**Depends on**: Phase 7 (insights persistidos)

### Tests for User Story 7 (TDD — RED first)

- [X] T045 [US7] Escrever testes (RED) `get-insight-trace.use-case.spec.ts` em `ci-api-v2/src/modules/ouvidoria-insights/test/use-cases/` — sem `externalQueries`, sem PII
- [X] T046 [P] [US7] Escrever testes componente (RED) `InsightTraceSheet.test.tsx` em `ci-client-v2/apps/web/src/modules/ouvidoria/__tests__/InsightTraceSheet.test.tsx` — CMP-INS-004, CMP-INS-005

### Implementation for User Story 7

- [X] T047 [US7] Implementar `get-insight-trace.use-case.ts` + mapper trace payload Cedro (GREEN T045)
- [X] T048 [US7] Implementar `GET /ouvidoria/insights/:insightId/trace` em `ouvidoria-insights.controller.ts`
- [X] T049 [US7] Estender `ouvidoria-insights.e2e-spec.ts` — CT-INS-004, CT-INS-008, E2E-INS-004
- [X] T050 [US7] Implementar `InsightTraceSheet.tsx` em `ci-client-v2/apps/web/src/modules/ouvidoria/components/InsightTraceSheet.tsx` (GREEN T046) — sheet ~85%, badge Somente leitura

**Checkpoint**: Rastreio API + UI sem fontes externas

---

## Phase 9: User Story 1 — Ver painel Insights IA (Priority: P1) 🎯 MVP

**Goal**: Página `/ouvidoria/insights` real substituindo mock — lista insights, fonte interna, impacto, recomendação

**Independent Test**: CMP-INS-001…003, E2E-INS-UI-001; quickstart §2 manual

**Depends on**: Phase 7 (GET list API); Phase 8 para trace opcional no MVP estendido

### Tests for User Story 1 (TDD — RED first)

- [X] T051 [P] [US1] Escrever testes (RED) `insights-mappers.test.ts` em `ci-client-v2/apps/web/src/modules/ouvidoria/__tests__/insights-mappers.test.ts` — CT-INS-MAP-001…003
- [X] T052 [P] [US1] Escrever testes contrato (RED) `insights.contract.test.ts` em `ci-client-v2/apps/web/src/modules/ouvidoria/__tests__/insights.contract.test.ts` — parse fixtures CT-INS-001
- [X] T053 [P] [US1] Escrever testes componente (RED) `InsightCard.test.tsx` e `InsightsPanel.test.tsx` em `ci-client-v2/apps/web/src/modules/ouvidoria/__tests__/`
- [X] T054 [US1] Escrever teste integração (RED) `OuvidoriaInsightsPage.integration.test.tsx` em `ci-client-v2/apps/web/src/modules/ouvidoria/__tests/` — INT-INS-001 com MSW
- [X] T055 [US1] Escrever teste E2E UI (RED) `OuvidoriaInsightsPage.e2e.test.tsx` — E2E-INS-UI-001 jornada MemoryRouter + MSW

### Implementation for User Story 1

- [X] T056 [P] [US1] Implementar mappers client em `ci-client-v2/apps/web/src/modules/ouvidoria/api/insights-mappers.ts` (GREEN T051)
- [X] T057 [US1] Implementar `ci-client-v2/apps/web/src/modules/ouvidoria/api/insights.ts` — `fetchInsights`, tipos Zod (GREEN T052)
- [X] T058 [P] [US1] Implementar `InsightCard.tsx` e `InsightsPanel.tsx` em `ci-client-v2/apps/web/src/modules/ouvidoria/components/` (GREEN T053)
- [X] T059 [US1] Implementar `OuvidoriaInsightsPage.tsx` em `ci-client-v2/apps/web/src/modules/ouvidoria/pages/OuvidoriaInsightsPage.tsx` — header Insights IA, badge Somente leitura, empty states
- [X] T060 [US1] Registrar lazy route `ouvidoria-insights` em `ci-client-v2/apps/web/src/app/router.tsx` e export em `ci-client-v2/apps/web/src/modules/ouvidoria/index.ts`
- [X] T061 [US1] Ajustar `ci-client-v2/apps/web/src/modules/shell/pages/ScreenPage.tsx` para **não** renderizar `CedroModulePanel` quando `screenId === 'ouvidoria-insights'`
- [X] T062 [US1] GREEN `OuvidoriaInsightsPage.integration.test.tsx` e `OuvidoriaInsightsPage.e2e.test.tsx`

**Checkpoint**: MVP — painel Insights IA com dados API (MSW ou dev); ≤3 cliques desde overview (SC-001)

---

## Phase 10: User Story 6 (UI) — Histórico e Consultar IA (Priority: P1)

**Goal**: Painel histórico de lotes, ação *Consultar IA*, throttle 429 na UI

**Independent Test**: CMP-INS-006/007/008; INT-INS-002/003 GREEN

**Depends on**: Phase 9 (página base)

### Tests for User Story 6 UI (TDD — RED first)

- [X] T063 [P] [US6] Escrever testes (RED) `InsightsHistoryPanel.test.tsx` em `ci-client-v2/apps/web/src/modules/ouvidoria/__tests/` — CMP-INS-006
- [X] T064 [P] [US6] Estender `OuvidoriaInsightsPage.e2e.test.tsx` (RED) — CMP-INS-007 Consultar IA, CMP-INS-008 throttle E2E-INS-UI-003

### Implementation for User Story 6 UI

- [X] T065 [US6] Implementar `InsightsHistoryPanel.tsx` em `ci-client-v2/apps/web/src/modules/ouvidoria/components/InsightsHistoryPanel.tsx` (GREEN T063)
- [X] T066 [US6] Adicionar `generateInsights()` em `api/insights.ts` e botão *Consultar IA* na página com loading/toast throttle (GREEN T064)
- [X] T067 [US6] Completar MSW handlers POST generate + 429 em `ci-client-v2/apps/web/src/test/msw/handlers/ouvidoria-insights.ts`

**Checkpoint**: Histórico comparável (SC-004); recálculo sob demanda na UI

---

## Phase 11: User Story 8 — Acesso, licença e sigilo (Priority: P1)

**Goal**: 403 sem setor ouvidoria; Cedro obrigatório; zero PII em agregações e evidências

**Independent Test**: E2E-INS-002, SC-007; e2e + contract audit

**Depends on**: Phase 7–9

### Tests for User Story 8 (TDD — RED first)

- [X] T068 [US8] Estender `ouvidoria-insights.e2e-spec.ts` (RED) — E2E-INS-002 `MODULO_SETOR_DENIED` sem setor Ouvidoria
- [X] T069 [P] [US8] Estender `get-insight-trace.use-case.spec.ts` e `generate-insights.use-case.spec.ts` (RED) — evidências anônimas sem campos `requester*` (SC-007)

### Implementation for User Story 8

- [X] T070 [US8] Garantir `LicencaSlug.cedro` no mock `tenantService.getActiveLicencas` em todos os testes e2e insights (GREEN T068)
- [X] T071 [US8] Auditar mappers/repos — filtrar PII ao montar `snapshotFields` e trace `records` (GREEN T069)
- [X] T072 [US8] Adicionar caso empty `insufficient_volume` em `list-latest-insights.use-case.ts` + teste CT-INS-002

**Checkpoint**: Segurança e sigilo validados em testes automatizados

---

## Phase 12: Polish & Cross-Cutting Concerns

**Purpose**: Copy, limpeza mocks, validação final

- [X] T073 [P] Ajustar copy em `ci-client-v2/apps/web/src/modules/ouvidoria/pages/OuvidoriaOverviewPage.tsx` — branding Insights IA sem prometer IA generativa
- [X] T074 [P] Remover dependência de `cedroInsightsByModule.ouvidoria` para rota real em `ci-client-v2/apps/web/src/modules/shell/data/mock-data.ts` (manter global/outros módulos)
- [X] T075 Executar `cd ci-api-v2; npm test; npm run test:e2e -- --testPathPattern=ouvidoria-insights` — exit 0
- [X] T076 Executar `cd ci-client-v2/apps/web; npm run test -- insights; npm run typecheck` — exit 0
- [X] T077 Validar cenários manuais em `specs/007-ouvidoria-cedro-insights/quickstart.md` §2

---

## Dependencies & Execution Order

### Phase Dependencies

```text
Phase 1 Setup
  → Phase 2 Foundational (BLOCKS ALL)
  → Phase 3 US2 Operational ║ Phase 4 US3 Geographic (paralelo)
  → Phase 5 US4 Text ║ Phase 6 US5 Profile (paralelo, P2)
  → Phase 7 US6 API generation
  → Phase 8 US7 Trace
  → Phase 9 US1 Client MVP
  → Phase 10 US6 UI history + Consultar IA
  → Phase 11 US8 Access/PII
  → Phase 12 Polish
```

### User Story Dependencies

| Story | Depende de | Independente quando |
|-------|------------|---------------------|
| US2 | Phase 2 | Rules + unit tests |
| US3 | Phase 2 | Rules + unit tests |
| US4 | Phase 2 | Rules + unit tests |
| US5 | Phase 2 | Rules + unit tests |
| US6 | US2 (+ US3–US5 para geração completa) | API e2e com mocks |
| US7 | US6 | Trace endpoint + sheet |
| US1 | US6 GET list | Page + MSW |
| US8 | US6–US9 | e2e 403 + PII audit |

### Parallel Opportunities

- **Phase 1**: T002–T006 em paralelo
- **Phase 2**: T009–T011, T014–T015, T018–T020 em paralelo após T012–T013
- **Phase 3 ∥ Phase 4**: operational vs geographic rules
- **Phase 5 ∥ Phase 6**: text vs profile rules
- **Phase 9**: T051–T053 paralelo antes de T059
- **Phase 12**: T073 ∥ T074

### Parallel Example: User Story 1

```bash
# Testes RED em paralelo:
T051 insights-mappers.test.ts
T052 insights.contract.test.ts
T053 InsightCard.test.tsx + InsightsPanel.test.tsx

# Componentes em paralelo após API client:
T058 InsightCard.tsx + InsightsPanel.tsx
```

---

## Implementation Strategy

### MVP First (P1 mínimo)

1. Phase 1 + Phase 2 (Foundational)
2. Phase 3 US2 (operacional)
3. Phase 7 US6 (API generate + list) — sem US4/US5 inicialmente
4. Phase 9 US1 (página client)
5. **STOP**: demo painel com insights operacionais reais

### Entrega completa v2

6. Phase 4 US3 + Phase 5 US4 + Phase 6 US5 (regras restantes)
7. Phase 8 US7 + Phase 10 US6 UI + Phase 11 US8
8. Phase 12 Polish

### Estimativa de tarefas

| Fase | Tasks | Story |
|------|-------|-------|
| Setup | 8 | — |
| Foundational | 14 | — |
| US2 | 4 | Operacional |
| US3 | 2 | Geográfico |
| US4 | 2 | Texto P2 |
| US5 | 2 | Perfil P2 |
| US6 API | 12 | Geração |
| US7 | 6 | Rastreio |
| US1 | 12 | Painel MVP |
| US6 UI | 5 | Histórico + Consultar IA |
| US8 | 5 | Acesso/sigilo |
| Polish | 5 | — |
| **Total** | **77** | |

---

## Notes

- Todos os testes de integração/E2E usam **Prisma mock** ou **MSW** — nunca `ci_api_v2_test` Postgres
- Job agendado: testar com `jest.useFakeTimers`, não wait real em CI
- Throttle E2E: usar fake timers ou fixture batch `on_demand` recente
- Wire US4/US5 em `generate-insights.use-case.ts` quando Phases 5–6 completas
- Commit após cada task ou grupo RED→GREEN
