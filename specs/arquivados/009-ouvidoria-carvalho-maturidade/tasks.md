---
description: "Task list for Maturidade Carvalho Ouvidoria (009-ouvidoria-carvalho-maturidade)"
---

# Tasks: Maturidade Carvalho — Ouvidoria

**Input**: Design documents from `specs/009-ouvidoria-carvalho-maturidade/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Tests**: **Obrigatórios** — TDD (constitution II + plan.md + `contracts/test-strategy.md`): unitário, componente, contrato, integração (mocks/in-memory) e E2E (Supertest + Vitest journey). **Sem banco Postgres de teste dedicado** — Prisma mock, fixtures JSON, MSW.

**Organization**: US1–US5 e US7–US8 são P1; US6 é P2. Caminhos relativos à raiz `ci-v2/`.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Pode executar em paralelo (arquivos diferentes, sem dependências pendentes)
- **[Story]**: User story da spec (US1–US8)

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Fixtures, MSW, scaffolding do submódulo

- [X] T001 [P] Criar fixtures API `ci-api-v2/src/modules/ouvidoria-maturidade/test/fixtures/maturidade-dashboard-full.json` e `maturidade-dashboard-empty.json` conforme `contracts/rest-api-ouvidoria-maturidade.md`
- [X] T002 [P] Criar fixtures API `ci-api-v2/src/modules/ouvidoria-maturidade/test/fixtures/jatoba-checks-sample.json` e `self-assessment-answers.json`
- [X] T003 [P] Criar fixtures client `ci-client-v2/apps/web/src/modules/ouvidoria/fixtures/maturidade-dashboard-full.json` e `maturidade-dashboard-empty.json`
- [X] T004 [P] Adicionar handlers MSW em `ci-client-v2/apps/web/src/test/msw/handlers/ouvidoria-maturidade.ts` e registrar em `ci-client-v2/apps/web/src/test/msw/handlers.ts`
- [X] T005 Criar esqueleto `ci-api-v2/src/modules/ouvidoria-maturidade/ouvidoria-maturidade.module.ts` com pastas `lib/`, `lib/indicators/`, `repository/`, `use-cases/`, `test/`
- [X] T006 Registrar `OuvidoriaMaturidadeModule` em `ci-api-v2/src/app.module.ts`
- [X] T007 [P] Criar seed stub `ci-api-v2/prisma/seed/seed-maturidade-questions.ts` e registrar em `ci-api-v2/prisma/seed.ts`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Schema Prisma, libs puras, Zod, repositórios base — **bloqueia todas as user stories**

**⚠️ CRITICAL**: Nenhuma user story começa antes desta fase

### Tests first (TDD — RED)

- [X] T008 [P] Escrever testes (RED) `hybrid-score.spec.ts` em `ci-api-v2/src/modules/ouvidoria-maturidade/lib/hybrid-score.spec.ts` — CT-MAT-SCR-001…004 (R-50, partialSource)
- [X] T009 [P] Escrever testes (RED) `jatoba-axis-map.spec.ts` em `ci-api-v2/src/modules/ouvidoria-maturidade/lib/jatoba-axis-map.spec.ts` — CT-MAT-MAP-001
- [X] T010 [P] Escrever testes (RED) `conformity-rate-by-axis.spec.ts` em `ci-api-v2/src/modules/ouvidoria-maturidade/lib/conformity-rate-by-axis.spec.ts` — CT-MAT-JAT-001
- [X] T011 [P] Escrever testes (RED) `self-assessment-score.spec.ts` em `ci-api-v2/src/modules/ouvidoria-maturidade/lib/self-assessment-score.spec.ts` — CT-MAT-SELF-001
- [X] T012 [P] Escrever testes (RED) `maturity-alert.spec.ts` em `ci-api-v2/src/modules/ouvidoria-maturidade/lib/maturity-alert.spec.ts` — CT-MAT-ALR-001
- [X] T013 [P] Escrever testes de contrato (RED) em `ci-api-v2/src/modules/ouvidoria-maturidade/ouvidoria-maturidade.schemas.spec.ts` — CT-MAT-001, CT-MAT-002 contra fixtures

### Schema & migration

- [X] T014 Criar `ci-api-v2/prisma/schema/ouvidoria-maturidade.prisma` — Config, Period, Question, Submission, Answer, ScoreSnapshot, ActionPlan, ActionPlanNote + enums conforme `data-model.md`
- [X] T015 Registrar schema em `ci-api-v2/prisma/schema/schema.prisma`, relações em `tenant.prisma` e gerar migration (`npx prisma migrate dev`)

### Implementation for Foundational

- [X] T016 [P] Implementar `hybrid-score.ts` em `ci-api-v2/src/modules/ouvidoria-maturidade/lib/hybrid-score.ts` (GREEN T008)
- [X] T017 [P] Implementar `jatoba-axis-map.ts` em `ci-api-v2/src/modules/ouvidoria-maturidade/lib/jatoba-axis-map.ts` (GREEN T009)
- [X] T018 [P] Implementar `conformity-rate-by-axis.ts` em `ci-api-v2/src/modules/ouvidoria-maturidade/lib/conformity-rate-by-axis.ts` (GREEN T010)
- [X] T019 [P] Implementar `self-assessment-score.ts` em `ci-api-v2/src/modules/ouvidoria-maturidade/lib/self-assessment-score.ts` (GREEN T011)
- [X] T020 [P] Implementar `maturity-alert.ts` em `ci-api-v2/src/modules/ouvidoria-maturidade/lib/maturity-alert.ts` (GREEN T012)
- [X] T021 Implementar Zod DTOs em `ci-api-v2/src/modules/ouvidoria-maturidade/ouvidoria-maturidade.schemas.ts` (GREEN T013)
- [X] T022 [P] Criar `ouvidoria-maturidade.types.ts` e mappers PT-BR em `ci-api-v2/src/modules/ouvidoria-maturidade/ouvidoria-maturidade.mapper.ts` — `axisLabel`, `alertLabel`, `statusLabel`, trace payload sem PII
- [X] T023 [P] Implementar repositórios período/perguntas — `find-current-period.repository.ts`, `ensure-current-period.repository.ts`, `list-maturidade-questions.repository.ts` + specs mock Prisma em `ci-api-v2/src/modules/ouvidoria-maturidade/test/repository/`
- [X] T024 [P] Implementar repositório read-only Jatobá — `find-latest-fiscalizacao-for-maturidade.repository.ts` (checks/results do último run) + spec mock Prisma
- [X] T025 Implementar stub controller em `ci-api-v2/src/modules/ouvidoria-maturidade/ouvidoria-maturidade.controller.ts` com `@RequireModulo('ouvidoria')` e `@RequireLicenca('carvalho')`

**Checkpoint**: Schema migrado; libs score GREEN; repositórios mockados; controller com guards

---

## Phase 3: User Story 3 — Autoavaliação Carvalho (Priority: P1)

**Goal**: Período trimestral, perguntas por eixo, GET/PUT self-assessment, notas por eixo

**Independent Test**: `submit-self-assessment.integration-spec.ts` GREEN; CT-MAT-SELF-001

**Depends on**: Phase 2 (schema + self-assessment-score)

### Tests for User Story 3 (TDD — RED first)

- [X] T026 [US3] Escrever testes (RED) `submit-self-assessment.use-case.spec.ts` em `ci-api-v2/src/modules/ouvidoria-maturidade/test/use-cases/submit-self-assessment.use-case.spec.ts`
- [X] T027 [P] [US3] Escrever testes (RED) `get-self-assessment.use-case.spec.ts` em `ci-api-v2/src/modules/ouvidoria-maturidade/test/use-cases/get-self-assessment.use-case.spec.ts`
- [X] T028 [US3] Escrever teste integração (RED) `submit-self-assessment.integration-spec.ts` em `ci-api-v2/src/modules/ouvidoria-maturidade/test/integration/submit-self-assessment.integration-spec.ts` — INT-MAT-002

### Implementation for User Story 3

- [X] T029 [P] [US3] Implementar repositórios submissão — `upsert-submission.repository.ts`, `create-answer.repository.ts`, `find-submission-by-period.repository.ts` + specs mock Prisma
- [X] T030 [US3] Implementar `ensure-current-period.use-case.ts` em `ci-api-v2/src/modules/ouvidoria-maturidade/use-cases/ensure-current-period.use-case.ts`
- [X] T031 [US3] Implementar `get-self-assessment.use-case.ts` (GREEN T027)
- [X] T032 [US3] Implementar `submit-self-assessment.use-case.ts` — calcula notas CI/GOV/TI, persiste answers (GREEN T026)
- [X] T033 [US3] Implementar endpoints `GET /ouvidoria/maturidade/periods/current`, `GET /ouvidoria/maturidade/self-assessment`, `PUT /ouvidoria/maturidade/self-assessment` em `ouvidoria-maturidade.controller.ts`
- [X] T034 [US3] Completar seed `ci-api-v2/prisma/seed/seed-maturidade-questions.ts` — ≥2 perguntas quantificáveis por eixo + 1 satisfação
- [X] T035 [US3] GREEN integração `submit-self-assessment.integration-spec.ts` (INT-MAT-002)

**Checkpoint**: Autoavaliação submetível; notas por eixo calculadas; período vigente criado automaticamente

---

## Phase 4: User Story 7 — Consumo conformidade Jatobá (Priority: P1)

**Goal**: Taxa conformidade por eixo a partir do último run Jatobá; referência no rastreio

**Independent Test**: `conformity-rate-by-axis.spec.ts` + use-case spec com fixture `jatoba-checks-sample.json`

**Depends on**: Phase 2 (jatoba-axis-map, find-latest-fiscalizacao repo)

### Tests for User Story 7 (TDD — RED first)

- [X] T036 [US7] Escrever testes (RED) `compute-jatoba-conformity-by-axis.use-case.spec.ts` em `ci-api-v2/src/modules/ouvidoria-maturidade/test/use-cases/compute-jatoba-conformity-by-axis.use-case.spec.ts`

### Implementation for User Story 7

- [X] T037 [US7] Implementar `compute-jatoba-conformity-by-axis.use-case.ts` — lê último run completed, aplica mapeamento ruleId→eixo (GREEN T036)
- [X] T038 [P] [US7] Implementar repositório `find-external-satisfaction-answers.repository.ts` — query answers escala de questionários externos Jatobá (retorna vazio se stub 008)

**Checkpoint**: Componente Jatobá 40% disponível quando run existe; null graceful quando ausente

---

## Phase 5: User Story 2 — Score híbrido por eixo (Priority: P1)

**Goal**: Snapshot persistido, score geral, fonte parcial, indisponível sem autoavaliação

**Independent Test**: E2E-MAT-007 formula 60/40; E2E-MAT-004 score indisponível sem submission

**Depends on**: Phase 3 (submissão), Phase 4 (conformidade Jatobá)

### Tests for User Story 2 (TDD — RED first)

- [X] T039 [US2] Escrever testes (RED) `compute-and-persist-score.use-case.spec.ts` em `ci-api-v2/src/modules/ouvidoria-maturidade/test/use-cases/compute-and-persist-score.use-case.spec.ts`
- [X] T040 [P] [US2] Escrever testes (RED) `get-score-trace.use-case.spec.ts` em `ci-api-v2/src/modules/ouvidoria-maturidade/test/use-cases/get-score-trace.use-case.spec.ts` — CT-MAT-003 sem PII

### Implementation for User Story 2

- [X] T041 [P] [US2] Implementar repositórios snapshot — `upsert-score-snapshot.repository.ts`, `find-score-snapshot-by-period.repository.ts`, `list-score-history.repository.ts` + specs mock Prisma
- [X] T042 [US2] Implementar `compute-and-persist-score.use-case.ts` — orquestra self + jatoba + hybrid-score + alert (GREEN T039)
- [X] T043 [US2] Implementar `get-score-trace.use-case.ts` — payload sheet **Como calculamos este score** (GREEN T040)
- [X] T044 [US2] Implementar `GET /ouvidoria/maturidade/score/trace` em `ouvidoria-maturidade.controller.ts`
- [X] T045 [US2] Invocar `compute-and-persist-score` após `submit-self-assessment` e no GET dashboard quando run Jatobá mais recente que snapshot

**Checkpoint**: Score híbrido R-50 persistido; rastreio API disponível

---

## Phase 6: User Story 4 — Indicadores operacionais (Priority: P1)

**Goal**: 5 indicadores canônicos + trace por tipo

**Independent Test**: specs `lib/indicators/*.spec.ts` GREEN; GET indicator trace

**Depends on**: Phase 2; leitura manifestações + fiscalização

### Tests for User Story 4 (TDD — RED first)

- [X] T046 [P] [US4] Escrever testes (RED) `volume.indicator.spec.ts` em `ci-api-v2/src/modules/ouvidoria-maturidade/lib/indicators/volume.indicator.spec.ts` — CT-MAT-IND-VOL
- [X] T047 [P] [US4] Escrever testes (RED) `response-time.indicator.spec.ts` em `ci-api-v2/src/modules/ouvidoria-maturidade/lib/indicators/response-time.indicator.spec.ts` — CT-MAT-IND-RT
- [X] T048 [P] [US4] Escrever testes (RED) `overdue-rate.indicator.spec.ts` em `ci-api-v2/src/modules/ouvidoria-maturidade/lib/indicators/overdue-rate.indicator.spec.ts` — CT-MAT-IND-OD
- [X] T049 [P] [US4] Escrever testes (RED) `resolution-rate.indicator.spec.ts` em `ci-api-v2/src/modules/ouvidoria-maturidade/lib/indicators/resolution-rate.indicator.spec.ts` — CT-MAT-IND-RES
- [X] T050 [P] [US4] Escrever testes (RED) `satisfaction.indicator.spec.ts` em `ci-api-v2/src/modules/ouvidoria-maturidade/lib/indicators/satisfaction.indicator.spec.ts` — CT-MAT-IND-SAT híbrido + partial

### Implementation for User Story 4

- [X] T051 [P] [US4] Implementar `volume.indicator.ts`, `response-time.indicator.ts`, `overdue-rate.indicator.ts`, `resolution-rate.indicator.ts`, `satisfaction.indicator.ts` em `ci-api-v2/src/modules/ouvidoria-maturidade/lib/indicators/` (GREEN T046–T050)
- [X] T052 [US4] Implementar `compute-indicators.use-case.ts` — janela 90 dias, orquestra 5 indicadores
- [X] T053 [US4] Implementar `get-indicator-trace.use-case.ts` + `GET /ouvidoria/maturidade/indicators/:type/trace`

**Checkpoint**: Indicadores calculados; não compõem score diretamente (FR-008)

---

## Phase 7: User Story 1 — Dashboard Maturidade (Priority: P1) 🎯 MVP

**Goal**: `GET /ouvidoria/maturidade` + página real substituindo mock — score, indicadores, empty states

**Independent Test**: CMP-MAT-001/002; E2E-MAT-UI-001; quickstart §2 manual

**Depends on**: Phase 5 (score), Phase 6 (indicadores)

### Tests for User Story 1 (TDD — RED first)

- [X] T054 [P] [US1] Escrever testes (RED) `maturidade-mappers.test.ts` em `ci-client-v2/apps/web/src/modules/ouvidoria/__tests__/maturidade-mappers.test.ts` — CT-MAT-MAP-001…005
- [X] T055 [P] [US1] Escrever testes contrato (RED) `maturidade.contract.test.ts` em `ci-client-v2/apps/web/src/modules/ouvidoria/__tests__/maturidade.contract.test.ts`
- [X] T056 [P] [US1] Escrever testes componente (RED) `MaturidadeScoreCards.test.tsx` em `ci-client-v2/apps/web/src/modules/ouvidoria/__tests__/MaturidadeScoreCards.test.tsx` — CMP-MAT-001, CMP-MAT-002
- [X] T057 [P] [US1] Escrever testes componente (RED) `MaturidadeIndicatorsRow.test.tsx` em `ci-client-v2/apps/web/src/modules/ouvidoria/__tests__/MaturidadeIndicatorsRow.test.tsx` — CMP-MAT-005
- [X] T058 [US1] Escrever teste integração (RED) `OuvidoriaMaturidadePage.integration.test.tsx` em `ci-client-v2/apps/web/src/modules/ouvidoria/__tests__/OuvidoriaMaturidadePage.integration.test.tsx` — INT-MAT-001
- [X] T059 [US1] Escrever teste E2E UI (RED) `OuvidoriaMaturidadePage.e2e.test.tsx` em `ci-client-v2/apps/web/src/modules/ouvidoria/__tests__/OuvidoriaMaturidadePage.e2e.test.tsx` — E2E-MAT-UI-001

### Implementation for User Story 1 — API

- [X] T060 [US1] Implementar `get-maturidade-dashboard.use-case.ts` — score + indicators + history + jatobaReference + emptyReason
- [X] T061 [US1] Implementar `GET /ouvidoria/maturidade` em `ouvidoria-maturidade.controller.ts` conforme `contracts/rest-api-ouvidoria-maturidade.md`

### Implementation for User Story 1 — Client

- [X] T062 [P] [US1] Implementar `ci-client-v2/apps/web/src/modules/ouvidoria/api/maturidade-mappers.ts` (GREEN T054)
- [X] T063 [US1] Implementar `ci-client-v2/apps/web/src/modules/ouvidoria/api/maturidade.ts` — `fetchMaturidadeDashboard`, `fetchScoreTrace`, tipos Zod (GREEN T055)
- [X] T064 [P] [US1] Implementar `MaturidadeScoreCards.tsx` e `MaturidadeIndicatorsRow.tsx` em `ci-client-v2/apps/web/src/modules/ouvidoria/components/` (GREEN T056, T057)
- [X] T065 [US1] Implementar `MaturidadePanel.tsx` — orquestra score cards, indicadores, banner stale Jatobá, badge **Somente leitura**
- [X] T066 [US1] Implementar `OuvidoriaMaturidadePage.tsx` em `ci-client-v2/apps/web/src/modules/ouvidoria/pages/OuvidoriaMaturidadePage.tsx`
- [X] T067 [US1] Registrar lazy route `ouvidoria-maturidade` em `ci-client-v2/apps/web/src/app/router.tsx` OUVIDORIA_OVERRIDES e export em `ci-client-v2/apps/web/src/modules/ouvidoria/index.ts`
- [X] T068 [US1] Ajustar `ci-client-v2/apps/web/src/modules/shell/pages/ScreenPage.tsx` para **não** renderizar `CarvalhoMaturityPanel` quando `screenId === 'ouvidoria-maturidade'`
- [X] T069 [US1] GREEN `OuvidoriaMaturidadePage.integration.test.tsx` e `OuvidoriaMaturidadePage.e2e.test.tsx`

**Checkpoint**: MVP — dashboard maturidade com dados API; ≤3 cliques desde overview (SC-001)

---

## Phase 8: User Story 5 — Radar e evolução temporal (Priority: P1)

**Goal**: Nivo radar 3 eixos + line chart histórico; meta 80%

**Independent Test**: CMP-MAT-003/004 GREEN

**Depends on**: Phase 7 (dashboard data)

### Tests for User Story 5 (TDD — RED first)

- [X] T070 [P] [US5] Escrever testes componente (RED) `MaturidadeRadarChart.test.tsx` em `ci-client-v2/apps/web/src/modules/ouvidoria/__tests__/MaturidadeRadarChart.test.tsx` — CMP-MAT-003
- [X] T071 [P] [US5] Escrever testes componente (RED) `MaturidadeTimelineChart.test.tsx` em `ci-client-v2/apps/web/src/modules/ouvidoria/__tests__/MaturidadeTimelineChart.test.tsx` — CMP-MAT-004

### Implementation for User Story 5

- [X] T072 [P] [US5] Implementar `MaturidadeRadarChart.tsx` — `@nivo/radar`, 3 eixos, meta 80%, cores semânticas Mint (GREEN T070)
- [X] T073 [P] [US5] Implementar `MaturidadeTimelineChart.tsx` — `@nivo/line`, série overall + eixos, empty 1 ponto (GREEN T071)
- [X] T074 [US5] Integrar charts em `MaturidadePanel.tsx` e lazy-load Nivo

**Checkpoint**: Radar + timeline; SC-009 com ≥2 períodos no seed

---

## Phase 9: Rastreabilidade + Autoavaliação UI (suporta US1/US2 — P1)

**Goal**: Sheet **Como calculamos este score** + dialog autoavaliação

**Independent Test**: CMP-MAT-006/007 GREEN

**Depends on**: Phase 7 (página base), Phase 3 (API self-assessment)

### Tests (TDD — RED first)

- [X] T075 [P] Escrever testes componente (RED) `MaturidadeTraceSheet.test.tsx` em `ci-client-v2/apps/web/src/modules/ouvidoria/__tests__/MaturidadeTraceSheet.test.tsx` — CMP-MAT-006
- [X] T076 [P] Escrever testes componente (RED) `SelfAssessmentDialog.test.tsx` em `ci-client-v2/apps/web/src/modules/ouvidoria/__tests__/SelfAssessmentDialog.test.tsx` — CMP-MAT-007

### Implementation

- [X] T077 [US1] Implementar `MaturidadeTraceSheet.tsx` em `ci-client-v2/apps/web/src/modules/ouvidoria/components/MaturidadeTraceSheet.tsx` — sheet ~85%, título canônico (GREEN T075)
- [X] T078 [US3] Implementar `SelfAssessmentDialog.tsx` em `ci-client-v2/apps/web/src/modules/ouvidoria/components/SelfAssessmentDialog.tsx` — perguntas por eixo, PUT submit (GREEN T076)
- [X] T079 [US1] Conectar ações *Como calculamos este score?* e *Responder autoavaliação* em `OuvidoriaMaturidadePage.tsx`

**Checkpoint**: SC-003 rastreio 100%; autoavaliação ponta a ponta na UI

---

## Phase 10: User Story 6 — Planos de ação (Priority: P2)

**Goal**: CRUD planos + notas de progresso; filtros; gestor only

**Independent Test**: INT-MAT-003; E2E-MAT-005 403 não-gestor; SC-008

**Depends on**: Phase 7 (página maturidade)

### Tests for User Story 6 (TDD — RED first)

- [X] T080 [US6] Escrever testes (RED) `create-action-plan.use-case.spec.ts`, `update-action-plan.use-case.spec.ts`, `list-action-plans.use-case.spec.ts` em `ci-api-v2/src/modules/ouvidoria-maturidade/test/use-cases/`
- [X] T081 [P] [US6] Escrever testes (RED) `add-action-plan-note.use-case.spec.ts` em `ci-api-v2/src/modules/ouvidoria-maturidade/test/use-cases/`
- [X] T082 [P] [US6] Escrever testes componente (RED) `ActionPlansPanel.test.tsx` em `ci-client-v2/apps/web/src/modules/ouvidoria/__tests__/ActionPlansPanel.test.tsx` — CMP-MAT-008

### Implementation for User Story 6 — API

- [X] T083 [P] [US6] Implementar repositórios — `create-action-plan.repository.ts`, `update-action-plan.repository.ts`, `list-action-plans.repository.ts`, `find-action-plan-by-id.repository.ts`, `create-action-plan-note.repository.ts` + specs mock Prisma
- [X] T084 [US6] Implementar use-cases CRUD planos + notas (GREEN T080, T081)
- [X] T085 [US6] Implementar endpoints action-plans em `ouvidoria-maturidade.controller.ts` — GET list, POST, GET :id, PATCH :id, POST :id/notes; guard gestor ouvidoria

### Implementation for User Story 6 — Client

- [X] T086 [US6] Estender `ci-client-v2/apps/web/src/modules/ouvidoria/api/maturidade.ts` — funções action-plans + MSW handlers
- [X] T087 [US6] Implementar `ActionPlansPanel.tsx` e `ActionPlanDialog.tsx` em `ci-client-v2/apps/web/src/modules/ouvidoria/components/` (GREEN T082)
- [X] T088 [US6] Integrar seção planos e ação *Novo plano de ação* em `OuvidoriaMaturidadePage.tsx`

**Checkpoint**: Planos de ação rastreáveis; única escrita gerencial da tela

---

## Phase 11: User Story 8 — Governança (Priority: P1)

**Goal**: 403 sem módulo; read-only scores; alertas licença Carvalho; nenhuma mutação em manifestações/Jatobá

**Independent Test**: E2E-MAT-002, E2E-MAT-006; SC-004, SC-010

**Depends on**: Phase 7 (dashboard)

### Tests for User Story 8 (TDD — RED first)

- [X] T089 [US8] Escrever E2E (RED) `ci-api-v2/test/ouvidoria-maturidade.e2e-spec.ts` — E2E-MAT-001, E2E-MAT-002, E2E-MAT-004, E2E-MAT-006, E2E-MAT-007 com Prisma mock + `tenantLicenca` inclui `carvalho`

### Implementation for User Story 8

- [X] T090 [US8] GREEN E2E Supertest `ouvidoria-maturidade.e2e-spec.ts` — validar guards e immutabilidade manifestação mock
- [X] T091 [US8] Atualizar `ci-client-v2/apps/web/src/modules/shell/lib/license-alerts.ts` — consumir `score.overallAlert` da API em vez de `maturityByModule` mock para ouvidoria
- [X] T092 [US8] Verificar copy **Somente leitura**, *nota de maturidade* (R-81) e empty states em `OuvidoriaMaturidadePage.tsx`

**Checkpoint**: Governança completa; chip Carvalho Crítico/Atenção (SC-010)

---

## Phase 12: Polish & Cross-Cutting

**Purpose**: Seed demo, documentação STATUS, validação quickstart

- [X] T093 [P] Estender `ci-api-v2/prisma/seed.ts` — período trimestre demo + submissão exemplo + snapshot score para tenant demo
- [X] T094 [P] Criar `specs/009-ouvidoria-carvalho-maturidade/STATUS.md` com critérios de done e link quickstart
- [X] T095 Executar quickstart `specs/009-ouvidoria-carvalho-maturidade/quickstart.md` §1 (testes CI) e corrigir falhas
- [X] T096 [P] Atualizar `specify-rules.mdc` plano ativo para STATUS concluído quando feature merge-ready

---

## Dependencies & Execution Order

### Phase Dependencies

```text
Phase 1 Setup
  → Phase 2 Foundational (BLOCKS ALL)
    → Phase 3 US3 Autoavaliação
    → Phase 4 US7 Jatobá (parallel com US3 após Foundational)
    → Phase 5 US2 Score (needs US3 + US7)
    → Phase 6 US4 Indicadores (parallel com US5 após Foundational)
    → Phase 7 US1 Dashboard (needs US2 + US4)
    → Phase 8 US5 Charts (needs US1)
    → Phase 9 Trace + SelfAssessment UI (needs US1 + US3)
    → Phase 10 US6 Planos (needs US1)
    → Phase 11 US8 Governança (needs US1)
    → Phase 12 Polish
```

### User Story Dependencies

| Story | Depende de | Entrega independente |
|-------|------------|----------------------|
| US3 Autoavaliação | Foundational | API PUT/GET self-assessment |
| US7 Jatobá | Foundational | Taxa conformidade por eixo |
| US2 Score híbrido | US3, US7 | Snapshot + trace API |
| US4 Indicadores | Foundational | 5 indicadores + trace |
| US1 Dashboard | US2, US4 | Página `/ouvidoria/maturidade` 🎯 MVP |
| US5 Radar/timeline | US1 | Charts Nivo |
| US6 Planos | US1 | CRUD planos gestor |
| US8 Governança | US1 | Guards + alertas |

### Parallel Opportunities

- **Phase 1**: T001–T004, T007 em paralelo
- **Phase 2 RED**: T008–T013 em paralelo; T016–T020 em paralelo após schema
- **Phase 3 + 4**: após Foundational, US3 e US7 podem avançar em paralelo (devs diferentes)
- **Phase 6**: T046–T050 specs indicators em paralelo; T051 indicators impl em paralelo
- **Phase 7 client**: T054–T057, T062–T064 em paralelo
- **Phase 8**: T070–T073 charts em paralelo

### Parallel Example: Foundational libs

```bash
# Após T014 migration, lançar em paralelo:
T016 hybrid-score.ts
T017 jatoba-axis-map.ts
T018 conformity-rate-by-axis.ts
T019 self-assessment-score.ts
T020 maturity-alert.ts
```

### Parallel Example: Indicators

```bash
T046 volume.indicator.spec.ts
T047 response-time.indicator.spec.ts
T048 overdue-rate.indicator.spec.ts
T049 resolution-rate.indicator.spec.ts
T050 satisfaction.indicator.spec.ts
```

---

## Implementation Strategy

### MVP First (User Story 1 path)

1. Phase 1: Setup
2. Phase 2: Foundational (**CRITICAL**)
3. Phase 3: US3 Autoavaliação
4. Phase 4: US7 Jatobá
5. Phase 5: US2 Score
6. Phase 6: US4 Indicadores
7. Phase 7: US1 Dashboard 🎯 **STOP e validar MVP**
8. Phase 9: Trace + SelfAssessment UI (completa MVP usável)
9. Fases 8, 10, 11 incrementais

### Incremental Delivery

1. Setup + Foundational → base pronta
2. US3 + US7 + US2 → score calculável via API
3. US4 + US1 → dashboard visível (MVP demo)
4. US5 + Phase 9 → gráficos + autoavaliação UI
5. US6 → planos de ação
6. US8 + Polish → produção-ready

---

## Notes

- [P] = arquivos diferentes, sem conflito de merge
- Cada user story mapeada a fases com label [USn] nos tasks de implementação
- Verificar RED antes de GREEN em todo ciclo TDD
- Commit após cada task ou grupo lógico
- **Nunca** alterar `Manifestacao` ou tabelas Jatobá a partir deste módulo

---

## Task Summary

| Métrica | Valor |
|---------|-------|
| **Total tasks** | 96 |
| US1 Dashboard | 16 |
| US2 Score híbrido | 7 |
| US3 Autoavaliação | 10 (+3 UI Phase 9) |
| US4 Indicadores | 8 |
| US5 Radar/timeline | 5 |
| US6 Planos de ação | 9 |
| US7 Jatobá | 3 |
| US8 Governança | 4 |
| Setup + Foundational + Polish | 34 |

**MVP sugerido**: T001–T069 (Setup → Foundational → US3 → US7 → US2 → US4 → US1)

**Format validation**: ✅ Todas as tasks usam `- [ ] T### [P?] [US?] Description with file path`
