---
description: "Task list for Maturidade Carvalho Compras (021-purchasing-maturidade)"
---

# Tasks: Maturidade Carvalho — Compras

**Input**: Design documents from `civ2-docs/specs/021-purchasing-maturidade/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md · **018 Purchasing CRUD** concluído · **019 Jatobá** recomendado (score híbrido Conformidade)

**Tests**: **Obrigatórios** — TDD (constitution II + plan.md + `contracts/test-strategy.md`): unitário, componente, contrato, integração (mocks/in-memory) e E2E. **Sem Postgres de teste dedicado**.

**Organization**: US1–US3 e US6 são P1; US4–US5 são P2. Caminhos relativos à raiz `ci-v2/`. Submódulo **`compras-maturidade` não existe** — criar espelhando `gabinete-maturidade/`.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Pode executar em paralelo (arquivos diferentes, sem dependências pendentes)
- **[Story]**: User story da spec (US1–US6)

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Fixtures, MSW, scaffolding do submódulo API e client

- [X] T001 [P] Criar fixtures API `ci-api-v2/src/modules/compras-maturidade/test/fixtures/maturidade-dashboard-full.json`, `maturidade-dashboard-empty.json` e `maturidade-dashboard-draft.json` conforme `contracts/rest-api-compras-maturidade.md`
- [X] T002 [P] Criar fixtures API `ci-api-v2/src/modules/compras-maturidade/test/fixtures/jatoba-checks-sample.json`, `self-assessment-questions.json` e `self-assessment-answers.json`
- [X] T003 [P] Criar fixtures client `ci-client-v2/apps/web/src/modules/compras/fixtures/maturidade-dashboard-full.json`, `maturidade-dashboard-empty.json` e `maturidade-dashboard-draft.json`
- [X] T004 [P] Adicionar handlers MSW em `ci-client-v2/apps/web/src/test/msw/handlers/compras-maturidade.ts` e registrar em `ci-client-v2/apps/web/src/test/msw/handlers.ts`
- [X] T005 Criar esqueleto `ci-api-v2/src/modules/compras-maturidade/compras-maturidade.module.ts` com pastas `lib/`, `lib/indicators/`, `repository/`, `use-cases/`, `test/`
- [X] T006 Registrar `ComprasMaturidadeModule` em `ci-api-v2/src/app.module.ts`
- [X] T007 [P] Criar seed stub `ci-api-v2/prisma/seed/seed-compras-maturidade-questions.ts` e registrar chamada em `ci-api-v2/prisma/seed/seed-jacaranda-tenant.ts`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Schema Prisma, libs puras, Zod, repositórios base, guards — **bloqueia todas as user stories**

**⚠️ CRITICAL**: Nenhuma user story começa antes desta fase

### Tests first (TDD — RED)

- [X] T008 [P] Escrever testes (RED) `hybrid-score.spec.ts` em `ci-api-v2/src/modules/compras-maturidade/lib/hybrid-score.spec.ts` — R-50 só Conformidade; partialSource quando Jatobá null
- [X] T009 [P] Escrever testes (RED) `self-assessment-score.spec.ts` em `ci-api-v2/src/modules/compras-maturidade/lib/self-assessment-score.spec.ts` — scale_1_5, yes_no, pesos por dimensão, exclude text
- [X] T010 [P] Escrever testes (RED) `maturity-alert.spec.ts` em `ci-api-v2/src/modules/compras-maturidade/lib/maturity-alert.spec.ts` — meta 80; critical &lt;70; attention 70–79
- [X] T011 [P] Escrever testes (RED) `period-utils.spec.ts` em `ci-api-v2/src/modules/compras-maturidade/lib/period-utils.spec.ts` — label trimestral `"2026 Q2"`, bounds UTC
- [X] T012 [P] Escrever testes (RED) `jatoba-dimension-map.spec.ts` em `ci-api-v2/src/modules/compras-maturidade/lib/jatoba-dimension-map.spec.ts` — 8 regras JAT-CMP-* documentadas
- [X] T013 [P] Escrever testes (RED) `conformity-rate.spec.ts` em `ci-api-v2/src/modules/compras-maturidade/lib/conformity-rate.spec.ts` — agregação worst-of por demanda; taxa global
- [X] T014 [P] Escrever testes (RED) `improvement-orientations.spec.ts` em `ci-api-v2/src/modules/compras-maturidade/lib/improvement-orientations.spec.ts` — patamar 60; bands low/adequate/strong; temas Jatobá agregados
- [X] T015 [P] Escrever testes de contrato (RED) em `ci-api-v2/src/modules/compras-maturidade/compras-maturidade.schemas.spec.ts` contra fixtures dashboard/self-assessment

### Schema & migration

- [X] T016 Criar `ci-api-v2/prisma/schema/compras-maturidade.prisma` — Config, Period, Question, Submission (draft/submitted), Answer, ScoreSnapshot + enums `ComprasMaturityDimension`, `ComprasMaturitySubmissionStatus` conforme `data-model.md`
- [X] T017 Registrar schema em `ci-api-v2/prisma/schema/schema.prisma`, relações Tenant e FK `jatobaRunId` → `ComprasFiscalizacaoRun`; gerar migration (`npx prisma migrate dev`)

### Implementation for Foundational

- [X] T018 [P] Implementar `hybrid-score.ts` em `ci-api-v2/src/modules/compras-maturidade/lib/hybrid-score.ts` (GREEN T008) — copiar/adaptar de `gabinete-maturidade/lib/hybrid-score.ts`
- [X] T019 [P] Implementar `self-assessment-score.ts` em `ci-api-v2/src/modules/compras-maturidade/lib/self-assessment-score.ts` (GREEN T009)
- [X] T020 [P] Implementar `maturity-alert.ts` em `ci-api-v2/src/modules/compras-maturidade/lib/maturity-alert.ts` (GREEN T010)
- [X] T021 [P] Implementar `period-utils.ts` em `ci-api-v2/src/modules/compras-maturidade/lib/period-utils.ts` (GREEN T011)
- [X] T022 [P] Implementar `jatoba-dimension-map.ts` em `ci-api-v2/src/modules/compras-maturidade/lib/jatoba-dimension-map.ts` (GREEN T012)
- [X] T023 [P] Implementar `conformity-rate.ts` em `ci-api-v2/src/modules/compras-maturidade/lib/conformity-rate.ts` (GREEN T013)
- [X] T024 [P] Implementar `improvement-orientations.ts` em `ci-api-v2/src/modules/compras-maturidade/lib/improvement-orientations.ts` (GREEN T014)
- [X] T025 Implementar Zod DTOs em `ci-api-v2/src/modules/compras-maturidade/compras-maturidade.schemas.ts` (GREEN T015)
- [X] T026 [P] Criar `compras-maturidade.types.ts` e mappers PT-BR em `ci-api-v2/src/modules/compras-maturidade/compras-maturidade.mapper.ts` — `dimensionLabel`, `alertLabel`, orientações, trace sem PII
- [X] T027 [P] Implementar repositórios período/perguntas — `find-current-period.repository.ts`, `ensure-current-period.repository.ts`, `list-maturidade-questions.repository.ts` + specs mock Prisma em `ci-api-v2/src/modules/compras-maturidade/test/repository/`
- [X] T028 [P] Implementar repositório read-only Jatobá — `fiscalizacao-read.repositories.ts` (último run completed + checks) + spec mock Prisma
- [X] T029 Implementar stub controller em `ci-api-v2/src/modules/compras-maturidade/compras-maturidade.controller.ts` com `@RequireModulo('compras')` e `@RequireLicenca('carvalho')`

**Checkpoint**: Schema migrado; libs score GREEN; repositórios mockados; controller com guards

---

## Phase 3: User Story 1 — Responder questionário de maturidade (Priority: P1) 🎯 MVP

**Goal**: Questionário 4 dimensões; GET/PUT/PATCH self-assessment; respostas parciais preservadas; validação obrigatórias

**Independent Test**: Autenticar com Carvalho → `/compras/maturidade` → responder parcial → sair/retornar → submeter → scores calculados (quickstart § Cenário 1)

**Depends on**: Phase 2

### Tests for User Story 1 (TDD — RED first)

- [X] T030 [P] [US1] Escrever testes (RED) `patch-self-assessment-answers.use-case.spec.ts` em `ci-api-v2/src/modules/compras-maturidade/test/use-cases/patch-self-assessment-answers.use-case.spec.ts` — draft criado; upsert answers; FR-008
- [X] T031 [P] [US1] Escrever testes (RED) `get-self-assessment.use-case.spec.ts` em `ci-api-v2/src/modules/compras-maturidade/test/use-cases/get-self-assessment.use-case.spec.ts` — 4 dimensões; pendingRequiredCount
- [X] T032 [US1] Escrever testes (RED) `submit-self-assessment.use-case.spec.ts` em `ci-api-v2/src/modules/compras-maturidade/test/use-cases/submit-self-assessment.use-case.spec.ts` — obrigatórias pendentes → erro; submitted + scores
- [X] T033 [US1] Escrever teste integração (RED) `submit-self-assessment.integration-spec.ts` em `ci-api-v2/src/modules/compras-maturidade/test/integration/submit-self-assessment.integration-spec.ts`

### Implementation for User Story 1

- [X] T034 [P] [US1] Implementar repositórios submissão — `upsert-submission.repository.ts`, `upsert-answer.repository.ts`, `find-submission-by-period.repository.ts` + specs mock Prisma
- [X] T035 [US1] Implementar `ensure-current-period.use-case.ts` em `ci-api-v2/src/modules/compras-maturidade/use-cases/ensure-current-period.use-case.ts`
- [X] T036 [US1] Implementar `get-self-assessment.use-case.ts` (GREEN T031)
- [X] T037 [US1] Implementar `patch-self-assessment-answers.use-case.ts` (GREEN T030)
- [X] T038 [US1] Implementar `submit-self-assessment.use-case.ts` — calcula scores 4 dimensões; status submitted; autor/data (GREEN T032)
- [X] T039 [US1] Implementar endpoints `GET /compras/maturidade/periods/current`, `GET /compras/maturidade/self-assessment`, `PATCH /compras/maturidade/self-assessment/answers`, `PUT /compras/maturidade/self-assessment` em `compras-maturidade.controller.ts`
- [X] T040 [US1] Completar seed `ci-api-v2/prisma/seed/seed-compras-maturidade-questions.ts` — ≥3 perguntas quantificáveis por dimensão (12–16 total) Lei 14.133
- [X] T041 [P] [US1] Implementar client API `ci-client-v2/apps/web/src/modules/compras/api/maturidade.ts` + Zod schemas espelhando contrato REST
- [X] T042 [P] [US1] Implementar `ci-client-v2/apps/web/src/modules/compras/api/maturidade-mappers.ts` — dimension labels, pending count, submission status
- [X] T043 [US1] Adaptar/reutilizar `SelfAssessmentDialog` de ouvidoria em `ComprasMaturidadePage` — PATCH debounced + PUT submit; agrupamento por dimensão
- [X] T044 [US1] Criar `ci-client-v2/apps/web/src/modules/compras/pages/ComprasMaturidadePage.tsx` — empty state + dialog questionário; registrar `LazyComprasMaturidadePage` e override `compras-maturidade` em `ci-client-v2/apps/web/src/modules/compras/index.ts`
- [X] T045 [US1] GREEN integração `submit-self-assessment.integration-spec.ts` (T033)

**Checkpoint**: Questionário funcional; parcial preservado; submissão calcula scores por dimensão

---

## Phase 4: User Story 2 — Score por dimensão e histórico (Priority: P1)

**Goal**: Dashboard GET `/compras/maturidade`; score híbrido Conformidade; histórico temporal; indicadores operacionais; trace sheet

**Independent Test**: Duas avaliações em períodos distintos → dashboard scores + timeline ≥2 pontos; Conformidade com componente Jatobá quando run existe (quickstart § Cenários 2–3 parcial)

**Depends on**: Phase 3 (submissão)

### Tests for User Story 2 (TDD — RED first)

- [X] T046 [US2] Escrever testes (RED) `compute-jatoba-conformity.use-case.spec.ts` em `ci-api-v2/src/modules/compras-maturidade/test/use-cases/compute-jatoba-conformity.use-case.spec.ts` — fixture `jatoba-checks-sample.json`; null graceful
- [X] T047 [US2] Escrever testes (RED) `compute-and-persist-score.use-case.spec.ts` em `ci-api-v2/src/modules/compras-maturidade/test/use-cases/compute-and-persist-score.use-case.spec.ts` — híbrido só Conformidade; overall ponderado; partialSource
- [X] T048 [P] [US2] Escrever testes (RED) `get-score-trace.use-case.spec.ts` em `ci-api-v2/src/modules/compras-maturidade/test/use-cases/get-score-trace.use-case.spec.ts` — sem PII
- [X] T049 [P] [US2] Escrever testes (RED) `get-maturidade-dashboard.use-case.spec.ts` em `ci-api-v2/src/modules/compras-maturidade/test/use-cases/get-maturidade-dashboard.use-case.spec.ts` — emptyReason; history; jatobaReference
- [X] T050 [P] [US2] Escrever testes (RED) `artefact-funnel.indicator.spec.ts` em `ci-api-v2/src/modules/compras-maturidade/lib/indicators/artefact-funnel.indicator.spec.ts`
- [X] T051 [P] [US2] Escrever testes (RED) `budget-inconsistency.indicator.spec.ts` em `ci-api-v2/src/modules/compras-maturidade/lib/indicators/budget-inconsistency.indicator.spec.ts`
- [X] T052 [P] [US2] Escrever testes (RED) `licitation-conformity.indicator.spec.ts` em `ci-api-v2/src/modules/compras-maturidade/lib/indicators/licitation-conformity.indicator.spec.ts`

### Implementation for User Story 2

- [X] T053 [P] [US2] Implementar repositórios snapshot — `upsert-score-snapshot.repository.ts`, `find-score-snapshot-by-period.repository.ts`, `list-score-history.repository.ts` + specs mock Prisma
- [X] T054 [US2] Implementar `compute-jatoba-conformity.use-case.ts` (GREEN T046)
- [X] T055 [US2] Implementar `compute-and-persist-score.use-case.ts` — orquestra self + jatoba Conformidade + hybrid + alert (GREEN T047)
- [X] T056 [US2] Implementar `get-score-trace.use-case.ts` (GREEN T048)
- [X] T057 [US2] Invocar `compute-and-persist-score` após `submit-self-assessment` e lazy refresh no GET dashboard quando run Jatobá &gt; snapshot
- [X] T058 [P] [US2] Implementar `artefact-funnel.indicator.ts`, `budget-inconsistency.indicator.ts`, `licitation-conformity.indicator.ts` em `ci-api-v2/src/modules/compras-maturidade/lib/indicators/` (GREEN T050–T052)
- [X] T059 [US2] Implementar `compute-indicators.use-case.ts` e `get-indicator-trace.use-case.ts`
- [X] T060 [US2] Implementar `get-maturidade-dashboard.use-case.ts` (GREEN T049)
- [X] T061 [US2] Implementar endpoints `GET /compras/maturidade`, `GET /compras/maturidade/score/trace`, `GET /compras/maturidade/indicators/:type/trace` em `compras-maturidade.controller.ts`
- [X] T062 [P] [US2] Implementar `ci-client-v2/apps/web/src/modules/compras/api/maturidade-chart-adapters.ts` — radar 4 dimensões + timeline history
- [X] T063 [US2] Integrar em `ComprasMaturidadePage.tsx` — `MaturidadeScoreCards`, `MaturidadeRadarChart`, `MaturidadeTimelineChart`, `MaturidadeTraceSheet`, `MaturidadeIndicatorsRow` (reuso ouvidoria com props dimensão Compras)

**Checkpoint**: Dashboard completo; histórico ≥2 períodos; híbrido Conformidade; indicadores operacionais

---

## Phase 5: User Story 3 — Orientações de melhoria (Priority: P1)

**Goal**: Orientações consultivas por dimensão abaixo patamar 60; reconhecimento ≥60; temas Jatobá agregados em Conformidade

**Independent Test**: Submeter com Instrução processual &lt;60 → ≥1 orientação imperativa; dimensão ≥60 → boa prática sem correção (quickstart § Cenário 3)

**Depends on**: Phase 4 (dashboard + scores)

### Tests for User Story 3 (TDD — RED first)

- [X] T064 [US3] Escrever testes (RED) `compras-maturidade.mapper.orientations.spec.ts` em `ci-api-v2/src/modules/compras-maturidade/test/compras-maturidade.mapper.orientations.spec.ts` — below/above adequate; jatobaThemes sem protocolo
- [X] T065 [P] [US3] Escrever testes componente (RED) `MaturidadeOrientationsPanel.test.tsx` em `ci-client-v2/apps/web/src/modules/compras/__tests__/MaturidadeOrientationsPanel.test.tsx`

### Implementation for User Story 3

- [X] T066 [US3] Enriquecer `compras-maturidade.mapper.ts` — mapear `orientations[]` no dashboard DTO a partir de scores + `improvement-orientations.ts` + temas Jatobá frequentes (GREEN T064)
- [X] T067 [US3] Criar `ci-client-v2/apps/web/src/modules/compras/components/maturidade/MaturidadeOrientationsPanel.tsx` (GREEN T065)
- [X] T068 [US3] Integrar `MaturidadeOrientationsPanel` em `ComprasMaturidadePage.tsx` abaixo dos score cards

**Checkpoint**: Orientações visíveis no dashboard; copy imperativo consultivo; Conformidade referencia temas agregados

---

## Phase 6: User Story 4 — Período de avaliação e recorrência (Priority: P2)

**Goal**: 1 avaliação por período; re-submit substitui; novo período convida nova autoavaliação; histórico consultável

**Independent Test**: Submeter Q2 → re-submit Q2 substitui; simular Q1 snapshot → histórico 2 entradas (quickstart § Cenário 4)

**Depends on**: Phase 3–4 (período + snapshot já existentes)

### Tests for User Story 4 (TDD — RED first)

- [X] T069 [US4] Escrever testes (RED) `period-recurrence.integration-spec.ts` em `ci-api-v2/src/modules/compras-maturidade/test/integration/period-recurrence.integration-spec.ts` — upsert mesmo periodId; history distinto por período
- [X] T070 [P] [US4] Escrever testes (RED) `ensure-current-period.use-case.spec.ts` em `ci-api-v2/src/modules/compras-maturidade/test/use-cases/ensure-current-period.use-case.spec.ts` — cria trimestre; convite novo período

### Implementation for User Story 4

- [X] T071 [US4] Refinar `submit-self-assessment.use-case.ts` — upsert submission/snapshot mesmo `periodId`; atualizar `submittedAt`/`submittedByUserId`; resposta conflito informativa (GREEN T069)
- [X] T072 [US4] Refinar `get-maturidade-dashboard.use-case.ts` — banner convite quando período corrente sem submission submitted; histórico períodos closed preservado
- [X] T073 [US4] Adicionar seed demo opcional período anterior + snapshot em `ci-api-v2/prisma/seed/seed-compras-maturidade-demo.ts` e registrar no Jacaranda
- [X] T074 [US4] GREEN `period-recurrence.integration-spec.ts` (T069)

**Checkpoint**: FR-009 atendido; evolução entre trimestres; re-submit sem duplicar

---

## Phase 7: User Story 5 — Exportar relatório (Priority: P2)

**Goal**: `GET /compras/maturidade/export` HTML imprimível com scores, orientações, histórico comparativo

**Independent Test**: Com avaliação → export HTML ≤30s; sem avaliação → mensagem orientadora (quickstart § Cenário 5)

**Depends on**: Phase 4–5 (dashboard + orientações)

### Tests for User Story 5 (TDD — RED first)

- [X] T075 [US5] Escrever testes (RED) `export-report.spec.ts` em `ci-api-v2/src/modules/compras-maturidade/lib/export-report.spec.ts` — HTML contém scores, orientações, autor/data; comparativo ≥2 períodos
- [X] T076 [US5] Escrever testes (RED) `export-maturidade-report.use-case.spec.ts` em `ci-api-v2/src/modules/compras-maturidade/test/use-cases/export-maturidade-report.use-case.spec.ts` — 400 sem submission

### Implementation for User Story 5

- [X] T077 [US5] Implementar `export-report.ts` em `ci-api-v2/src/modules/compras-maturidade/lib/export-report.ts` (GREEN T075)
- [X] T078 [US5] Implementar `export-maturidade-report.use-case.ts` + endpoint `GET /compras/maturidade/export` (GREEN T076)
- [X] T079 [US5] Criar `ci-client-v2/apps/web/src/modules/compras/components/maturidade/MaturidadeExportButton.tsx` — abre HTML nova aba / window.print
- [X] T080 [US5] Integrar export button em `ComprasMaturidadePage.tsx` — disabled sem submission submitted

**Checkpoint**: FR-010 atendido; export com evolução histórica quando ≥2 avaliações

---

## Phase 8: User Story 6 — Acesso, licença e governança (Priority: P1)

**Goal**: 403 sem módulo; alerta licença Carvalho; Carvalho read-only sobre demandas; rastreabilidade autor/data

**Independent Test**: Usuário sem compras → 403; sem Carvalho → alerta; submit não altera demanda (quickstart § Cenário 6)

**Depends on**: Phase 3+ (endpoints existentes)

### Tests for User Story 6 (TDD — RED first)

- [X] T081 [P] [US6] Escrever testes (RED) guards em `ci-api-v2/src/modules/compras-maturidade/test/compras-maturidade.guards.spec.ts` — 403 sem módulo; 403 sem licença Carvalho
- [X] T082 [US6] Escrever teste integração (RED) `read-only-operational.integration-spec.ts` em `ci-api-v2/src/modules/compras-maturidade/test/integration/read-only-operational.integration-spec.ts` — SC-005 demandas/artefatos inalterados após submit
- [X] T083 [P] [US6] Escrever testes (RED) `ComprasMaturidadePage.guards.test.tsx` em `ci-client-v2/apps/web/src/modules/compras/__tests__/ComprasMaturidadePage.guards.test.tsx` — alerta licença; histórico consultável expirado

### Implementation for User Story 6

- [X] T084 [US6] Validar guards em todos os endpoints `compras-maturidade.controller.ts` (GREEN T081)
- [X] T085 [US6] Garantir `submissionMeta` (autor, data) no dashboard DTO e mapper (FR-012 rastreabilidade)
- [X] T086 [US6] GREEN `read-only-operational.integration-spec.ts` — comparar fixture demanda before/after submit (T082)
- [X] T087 [US6] Implementar tratamento licença expirada no client — consulta histórico OK; submeter/export desabilitados (GREEN T083)

**Checkpoint**: Governança produção; SC-005 validado; copy 403 padronizada

---

## Phase 9: Polish & Cross-Cutting Concerns

**Purpose**: E2E, contrato client, demo seed, validação quickstart

- [X] T088 [P] Escrever `ci-api-v2/test/compras-maturidade.e2e-spec.ts` — jornada GET dashboard → PUT submit → GET trace → GET export (Supertest; deps mockadas)
- [X] T089 [P] Escrever `ci-client-v2/apps/web/src/modules/compras/__tests__/maturidade.contract.test.ts` — Zod client vs fixtures
- [X] T090 [P] Escrever `ComprasMaturidadePage.integration.test.tsx` e `ComprasMaturidadePage.e2e.test.tsx` em `ci-client-v2/apps/web/src/modules/compras/__tests__/`
- [X] T091 Executar `npm test -- --testPathPatterns=compras-maturidade` em `ci-api-v2` e `npm test -- compras-maturidade` em `ci-client-v2/apps/web` — suite verde *(client: 24 testes OK via `src/modules/compras/__tests__/ComprasMaturidadePage` + `maturidade.contract` + `MaturidadeOrientationsPanel`)*
- [X] T092 Validar manualmente cenários de `quickstart.md` (6 cenários) e documentar gaps em PR se houver

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Sem dependências
- **Foundational (Phase 2)**: Depende Setup — **BLOQUEIA** US1–US6
- **US1 (Phase 3)**: Depende Foundational — **MVP**
- **US2 (Phase 4)**: Depende US1 (submissão)
- **US3 (Phase 5)**: Depende US2 (scores no dashboard)
- **US4 (Phase 6)**: Depende US1–US2 (período + snapshot); pode paralelizar com US3 após US2
- **US5 (Phase 7)**: Depende US2–US3 (scores + orientações no export)
- **US6 (Phase 8)**: Guards parcialmente Foundational; testes read-only após US1
- **Polish (Phase 9)**: Depende fases desejadas completas

### User Story Dependencies

| Story | Depende de | Independente quando |
|-------|------------|---------------------|
| US1 | Phase 2 | Questionário + submit + parcial OK |
| US2 | US1 | Dashboard + histórico com 2 períodos seedados |
| US3 | US2 | Orientações com scores mockados |
| US4 | US1, US2 | Recorrência trimestral |
| US5 | US2, US3 | Export HTML |
| US6 | US1 | Guards testáveis cedo; read-only após submit |

### Parallel Opportunities

- **Phase 1**: T001–T004, T007 em paralelo
- **Phase 2**: T008–T014 (testes RED) em paralelo; T018–T024 (libs) em paralelo; T027–T028 repos em paralelo
- **Phase 3**: T030–T031, T041–T042 em paralelo
- **Phase 4**: T050–T052 indicators RED; T062 paralelo com API após T060
- **Phase 5–7**: US3/US4 podem rodar em paralelo após US2 completo
- **Phase 9**: T088–T090 em paralelo

---

## Parallel Example: User Story 1

```bash
# Testes RED em paralelo:
T030 patch-self-assessment-answers.use-case.spec.ts
T031 get-self-assessment.use-case.spec.ts

# Client API em paralelo após use-cases GREEN:
T041 maturidade.ts
T042 maturidade-mappers.ts
```

---

## Parallel Example: User Story 2

```bash
# Indicadores RED em paralelo:
T050 artefact-funnel.indicator.spec.ts
T051 budget-inconsistency.indicator.spec.ts
T052 licitation-conformity.indicator.spec.ts
```

---

## Implementation Strategy

### MVP First (User Story 1)

1. Phase 1: Setup
2. Phase 2: Foundational
3. Phase 3: US1 — questionário + submit + página empty/dialog
4. **STOP e VALIDAR**: quickstart § Cenário 1

### Incremental Delivery (P1 core)

1. Setup + Foundational → base pronta
2. US1 → MVP questionário
3. US2 → dashboard + histórico + híbrido Conformidade
4. US3 → orientações
5. US6 → governança read-only
6. US4 → recorrência trimestral (P2)
7. US5 → export (P2)
8. Polish → E2E + quickstart

### Parallel Team Strategy

- Dev A: API use-cases US1 → US2
- Dev B: Client page + componentes reuso ouvidoria
- Dev C: Indicadores + Jatobá conformity + export (após US2)

---

## Notes

- **Sem action plans** — não portar use-cases/repos de `ActionPlan*` (FR-015)
- **Híbrido só Conformidade** — não aplicar 60/40 nas outras 3 dimensões (research R2)
- Vocabulário UI: **demanda/demandas**; rota `/compras/maturidade`
- Referência viva API: `ci-api-v2/src/modules/gabinete-maturidade/`; UI: `modules/ouvidoria/pages/OuvidoriaMaturidadePage.tsx`
- Commit após cada task ou grupo lógico; RED antes de GREEN
