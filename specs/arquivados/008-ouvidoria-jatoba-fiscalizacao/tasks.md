---
description: "Task list for Fiscalização Jatobá Ouvidoria (008-ouvidoria-jatoba-fiscalizacao)"
---

# Tasks: Painel de Fiscalização — Ouvidoria (Jatobá)

**Input**: Design documents from `specs/008-ouvidoria-jatoba-fiscalizacao/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Tests**: **Obrigatórios** — TDD (constitution II + plan.md + `contracts/test-strategy.md`): unitário, componente, contrato, integração (mocks/in-memory) e E2E (Supertest + Vitest journey). **Sem banco Postgres de teste dedicado** — Prisma mock, fixtures JSON, MSW.

**Organization**: US1–US5 são P1; US6–US8 são P2. Caminhos relativos à raiz `ci-v2/`.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Pode executar em paralelo (arquivos diferentes, sem dependências pendentes)
- **[Story]**: User story da spec (US1–US8)

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Fixtures, MSW, env e scaffolding do submódulo

- [X] T001 Documentar `FISCALIZACAO_CRON` (opcional) em `ci-api-v2/.env.example`
- [X] T002 [P] Criar fixture `ci-api-v2/src/modules/ouvidoria-fiscalizacao/test/fixtures/manifestacoes-fiscalizacao-sample.json` conforme `data-model.md`
- [X] T003 [P] Criar fixtures `ci-api-v2/src/modules/ouvidoria-fiscalizacao/test/fixtures/fiscalizacao-run-completed.json` e `fiscalizacao-panel-empty.json`
- [X] T004 [P] Criar fixtures client `ci-client-v2/apps/web/src/modules/ouvidoria/fixtures/fiscalizacao-run-completed.json` e `fiscalizacao-panel-empty.json`
- [X] T005 [P] Adicionar handlers MSW em `ci-client-v2/apps/web/src/test/msw/handlers/ouvidoria-fiscalizacao.ts` e registrar em `ci-client-v2/apps/web/src/test/msw/handlers.ts`
- [X] T006 Criar esqueleto `ci-api-v2/src/modules/ouvidoria-fiscalizacao/ouvidoria-fiscalizacao.module.ts` com pastas `lib/`, `lib/checks/`, `repository/`, `use-cases/`, `jobs/`, `test/`
- [X] T007 Registrar `OuvidoriaFiscalizacaoModule` em `ci-api-v2/src/app.module.ts`
- [X] T008 [P] Criar seed stub `ci-api-v2/prisma/seed/seed-fiscalizacao-questions.ts` e registrar em `ci-api-v2/prisma/seed.ts`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Schema Prisma, SLA, agregação, tipos Zod, repositórios — **bloqueia todas as user stories**

**⚠️ CRITICAL**: Nenhuma user story começa antes desta fase

### Tests first (TDD — RED)

- [X] T009 [P] Escrever testes (RED) `sla-resolver.spec.ts` em `ci-api-v2/src/modules/ouvidoria-fiscalizacao/lib/sla-resolver.spec.ts` — CT-FIS-SLA-001 defaults por tipo
- [X] T010 [P] Escrever testes (RED) `aggregate-conformity.spec.ts` em `ci-api-v2/src/modules/ouvidoria-fiscalizacao/lib/aggregate-conformity.spec.ts` — CT-FIS-AGG-001 pior status
- [X] T011 [P] Escrever testes de contrato (RED) em `ci-api-v2/src/modules/ouvidoria-fiscalizacao/ouvidoria-fiscalizacao.schemas.spec.ts` — CT-FIS-001, CT-FIS-004, CT-FIS-006, CT-FIS-008 neg contra fixtures

### Schema & migration

- [X] T012 Criar `ci-api-v2/prisma/schema/ouvidoria-fiscalizacao.prisma` — Run, Result, Check, Finding, SlaConfig, Question, Questionnaire, QuestionnaireItem, Answer + enums conforme `data-model.md`
- [X] T013 Registrar schema em `ci-api-v2/prisma/schema/schema.prisma`, relações em `tenant.prisma` e gerar migration (`npx prisma migrate dev`)

### Implementation for Foundational

- [X] T014 [P] Implementar `sla-resolver.ts` em `ci-api-v2/src/modules/ouvidoria-fiscalizacao/lib/sla-resolver.ts` (GREEN T009)
- [X] T015 [P] Implementar `aggregate-conformity.ts` em `ci-api-v2/src/modules/ouvidoria-fiscalizacao/lib/aggregate-conformity.ts` (GREEN T010)
- [X] T016 Implementar Zod DTOs em `ci-api-v2/src/modules/ouvidoria-fiscalizacao/ouvidoria-fiscalizacao.schemas.ts` (GREEN T011)
- [X] T017 [P] Criar `ouvidoria-fiscalizacao.types.ts` e mappers PT-BR em `ci-api-v2/src/modules/ouvidoria-fiscalizacao/ouvidoria-fiscalizacao.mapper.ts` — `conformityLabel`, `originLabel`, `flowStateLabel` (≠ conformidade)
- [X] T018 [P] Implementar `load-manifestacoes-for-fiscalizacao.repository.ts` + spec Prisma mock em `ci-api-v2/src/modules/ouvidoria-fiscalizacao/repository/`
- [X] T019 [P] Implementar repositórios persistência run — `create-fiscalizacao-run.repository.ts`, `update-fiscalizacao-run-status.repository.ts`, `create-fiscalizacao-result.repository.ts`, `create-fiscalizacao-check.repository.ts`, `create-fiscalizacao-finding.repository.ts` + specs mock Prisma
- [X] T020 [P] Implementar repositórios query — `find-latest-fiscalizacao-run.repository.ts`, `list-fiscalizacao-runs.repository.ts`, `find-fiscalizacao-run-by-id.repository.ts`, `list-fiscalizacao-results-by-run.repository.ts`, `find-last-on-demand-run.repository.ts` + specs mock Prisma
- [X] T021 [P] Implementar `find-fiscalizacao-sla-config.repository.ts` e `upsert-fiscalizacao-sla-config.repository.ts` + specs em `ci-api-v2/src/modules/ouvidoria-fiscalizacao/test/repository/`
- [X] T022 Implementar stub controller em `ci-api-v2/src/modules/ouvidoria-fiscalizacao/ouvidoria-fiscalizacao.controller.ts` com `@RequireModulo('ouvidoria')` e `@RequireLicenca('jatoba')` em rotas autenticadas
- [X] T023 [P] Implementar stub `ouvidoria-fiscalizacao-public.controller.ts` com `@Public()` para rotas `/public/ouvidoria/fiscalizacao/responder/:token`

**Checkpoint**: Schema migrado; SLA + agregação GREEN; repositórios mockados; controllers com guards

---

## Phase 3: User Story 2 — Checagens automáticas (Priority: P1)

**Goal**: Regras determinísticas prazo, tramitação, completude, contato, evidências — conformidade agregada por manifestação

**Independent Test**: `npm test -- checks` passa CT-FIS-PRZ/TRM/CMP/CNT/EVD; fixture sample produz statuses esperados

> **Paralelo**: T024–T028 specs RED podem rodar em paralelo.

### Tests for User Story 2 (TDD — RED first)

- [X] T024 [P] [US2] Escrever testes (RED) `deadline.rules.spec.ts` em `ci-api-v2/src/modules/ouvidoria-fiscalizacao/lib/checks/deadline.rules.spec.ts` — CT-FIS-PRZ-001…003
- [X] T025 [P] [US2] Escrever testes (RED) `forwarding.rules.spec.ts` em `ci-api-v2/src/modules/ouvidoria-fiscalizacao/lib/checks/forwarding.rules.spec.ts` — CT-FIS-TRM-001
- [X] T026 [P] [US2] Escrever testes (RED) `completeness.rules.spec.ts` em `ci-api-v2/src/modules/ouvidoria-fiscalizacao/lib/checks/completeness.rules.spec.ts` — CT-FIS-CMP-001
- [X] T027 [P] [US2] Escrever testes (RED) `contact.rules.spec.ts` em `ci-api-v2/src/modules/ouvidoria-fiscalizacao/lib/checks/contact.rules.spec.ts` — CT-FIS-CNT-001
- [X] T028 [P] [US2] Escrever testes (RED) `evidence.rules.spec.ts` em `ci-api-v2/src/modules/ouvidoria-fiscalizacao/lib/checks/evidence.rules.spec.ts` — CT-FIS-EVD-001
- [X] T029 [P] [US2] Escrever testes (RED) `throttle.spec.ts` em `ci-api-v2/src/modules/ouvidoria-fiscalizacao/lib/throttle.spec.ts` — CT-FIS-THR-001 com fake timers

### Implementation for User Story 2

- [X] T030 [P] [US2] Implementar `deadline.rules.ts` em `ci-api-v2/src/modules/ouvidoria-fiscalizacao/lib/checks/deadline.rules.ts` (GREEN T024)
- [X] T031 [P] [US2] Implementar `forwarding.rules.ts` em `ci-api-v2/src/modules/ouvidoria-fiscalizacao/lib/checks/forwarding.rules.ts` (GREEN T025)
- [X] T032 [P] [US2] Implementar `completeness.rules.ts` em `ci-api-v2/src/modules/ouvidoria-fiscalizacao/lib/checks/completeness.rules.ts` (GREEN T026)
- [X] T033 [P] [US2] Implementar `contact.rules.ts` em `ci-api-v2/src/modules/ouvidoria-fiscalizacao/lib/checks/contact.rules.ts` (GREEN T027)
- [X] T034 [P] [US2] Implementar `evidence.rules.ts` em `ci-api-v2/src/modules/ouvidoria-fiscalizacao/lib/checks/evidence.rules.ts` (GREEN T028)
- [X] T035 [US2] Implementar `throttle.ts` em `ci-api-v2/src/modules/ouvidoria-fiscalizacao/lib/throttle.ts` (GREEN T029)
- [X] T036 [US2] Implementar orquestrador `run-checks-for-manifestacao.ts` em `ci-api-v2/src/modules/ouvidoria-fiscalizacao/lib/run-checks-for-manifestacao.ts` — aplica 5 regras + aggregate

**Checkpoint**: Checagens puras testáveis sem DB; agregação pior status

---

## Phase 4: User Story 3 — Execuções persistidas e histórico (Priority: P1)

**Goal**: Job diário, persistência de runs, GET painel, histórico, POST *Fiscalizar manifestações* com throttle 1h

**Independent Test**: `generate/run-fiscalizacao.integration-spec.ts` GREEN; E2E CT-FIS-001/003/005

**Depends on**: Phase 3 (checagens)

### Tests for User Story 3 (TDD — RED first)

- [ ] T037 [US3] Escrever testes (RED) `run-fiscalizacao.use-case.spec.ts` em `ci-api-v2/src/modules/ouvidoria-fiscalizacao/test/use-cases/run-fiscalizacao.use-case.spec.ts` — orquestra checks + persist mock
- [ ] T038 [P] [US3] Escrever testes (RED) `get-fiscalizacao-panel.use-case.spec.ts` e `list-fiscalizacao-runs.use-case.spec.ts` em `ci-api-v2/src/modules/ouvidoria-fiscalizacao/test/use-cases/`
- [ ] T039 [P] [US3] Escrever testes (RED) `run-fiscalizacao-scoped.use-case.spec.ts` em `ci-api-v2/src/modules/ouvidoria-fiscalizacao/test/use-cases/` — origin `on_record`
- [X] T040 [US3] Escrever teste integração (RED) `run-fiscalizacao.integration-spec.ts` em `ci-api-v2/src/modules/ouvidoria-fiscalizacao/test/integration/run-fiscalizacao.integration-spec.ts` — store in-memory INT-FIS-001

### Implementation for User Story 3

- [X] T041 [US3] Implementar `run-fiscalizacao.use-case.ts` — analisa 100% confirmadas, persiste run/results/checks/findings, status `running|completed|failed` (GREEN T037)
- [X] T042 [P] [US3] Implementar `get-fiscalizacao-panel.use-case.ts` e `list-fiscalizacao-runs.use-case.ts` (GREEN T038)
- [X] T043 [P] [US3] Implementar `run-fiscalizacao-scoped.use-case.ts` para POST por manifestação (GREEN T039)
- [X] T044 [US3] Implementar `run-fiscalizacao-scheduled.job.ts` em `ci-api-v2/src/modules/ouvidoria-fiscalizacao/jobs/` + spec fake timers
- [X] T045 [US3] Implementar endpoints em `ouvidoria-fiscalizacao.controller.ts`: `GET /ouvidoria/fiscalizacao`, `GET /ouvidoria/fiscalizacao/runs`, `GET /ouvidoria/fiscalizacao/runs/:runId`, `POST /ouvidoria/fiscalizacao/run`, `POST /ouvidoria/fiscalizacao/run/manifestacoes/:manifestacaoId` conforme `contracts/rest-api-ouvidoria-fiscalizacao.md`
- [X] T046 [US3] GREEN integração `run-fiscalizacao.integration-spec.ts` (INT-FIS-001…002)
- [X] T047 [US3] Escrever E2E (RED) `ci-api-v2/test/ouvidoria-fiscalizacao.e2e-spec.ts` — CT-FIS-001, CT-FIS-003, CT-FIS-005 com Prisma mock + `tenantLicenca` inclui `jatoba`
- [X] T048 [US3] GREEN E2E Supertest `ouvidoria-fiscalizacao.e2e-spec.ts` (E2E-FIS-001, E2E-FIS-003, E2E-FIS-005)

**Checkpoint**: API executa, persiste, lista e throttle sem alterar manifestações

---

## Phase 5: User Story 4 — Rastreabilidade Jatobá (Priority: P1)

**Goal**: Endpoints trace check/finding/record + sheet UI com títulos canônicos

**Independent Test**: CT-FIS-004; CMP-FIS-003/004 GREEN

**Depends on**: Phase 4 (checks/findings persistidos)

### Tests for User Story 4 (TDD — RED first)

- [ ] T049 [US4] Escrever testes (RED) `get-check-trace.use-case.spec.ts`, `get-finding-trace.use-case.spec.ts`, `get-record-trace.use-case.spec.ts` em `ci-api-v2/src/modules/ouvidoria-fiscalizacao/test/use-cases/` — sem PII
- [ ] T050 [P] [US4] Escrever testes componente (RED) `FiscalizacaoTraceSheet.test.tsx` em `ci-client-v2/apps/web/src/modules/ouvidoria/__tests__/FiscalizacaoTraceSheet.test.tsx` — CMP-FIS-003, CMP-FIS-004

### Implementation for User Story 4

- [ ] T051 [US4] Implementar use-cases trace + mapper payload Jatobá (GREEN T049)
- [ ] T052 [US4] Implementar `GET .../checks/:checkId/trace`, `GET .../findings/:findingId/trace`, `GET .../manifestacoes/:id/trace` em `ouvidoria-fiscalizacao.controller.ts`
- [ ] T053 [US4] Estender `ouvidoria-fiscalizacao.e2e-spec.ts` — CT-FIS-004, E2E-FIS-004 trace sem PII anônimo
- [ ] T054 [US4] Implementar `FiscalizacaoTraceSheet.tsx` em `ci-client-v2/apps/web/src/modules/ouvidoria/components/FiscalizacaoTraceSheet.tsx` (GREEN T050) — sheet ~85%, títulos canônicos por `traceType`

**Checkpoint**: Rastreio API + sheet sem rotas dedicadas

---

## Phase 6: User Story 1 — Ver painel de Fiscalização (Priority: P1) 🎯 MVP

**Goal**: Página `/ouvidoria/auditoria` real substituindo mock — stats 4 status, checagens, achados, histórico

**Independent Test**: CMP-FIS-001/002, E2E-FIS-UI-001; quickstart §2 manual

**Depends on**: Phase 4 GET panel API; Phase 5 trace opcional no MVP estendido

### Tests for User Story 1 (TDD — RED first)

- [X] T055 [P] [US1] Escrever testes (RED) `fiscalizacao-mappers.test.ts` em `ci-client-v2/apps/web/src/modules/ouvidoria/__tests__/fiscalizacao-mappers.test.ts` — CT-FIS-MAP-001…004
- [X] T056 [P] [US1] Escrever testes contrato (RED) `fiscalizacao.contract.test.ts` em `ci-client-v2/apps/web/src/modules/ouvidoria/__tests__/fiscalizacao.contract.test.ts` — CT-FIS-001, CT-FIS-HTTP-001
- [X] T057 [P] [US1] Escrever testes componente (RED) `FiscalizacaoPanel.test.tsx` e `FiscalizacaoStatsRow.test.tsx` em `ci-client-v2/apps/web/src/modules/ouvidoria/__tests__/` — CMP-FIS-001, CMP-FIS-002
- [X] T058 [P] [US1] Escrever testes componente (RED) `FiscalizacaoHistoryTable.test.tsx` em `ci-client-v2/apps/web/src/modules/ouvidoria/__tests__/FiscalizacaoHistoryTable.test.tsx` — CMP-FIS-005
- [X] T059 [US1] Escrever teste integração (RED) `OuvidoriaAuditoriaPage.integration.test.tsx` em `ci-client-v2/apps/web/src/modules/ouvidoria/__tests__/` — INT-FIS-001 com MSW
- [X] T060 [US1] Escrever teste E2E UI (RED) `OuvidoriaAuditoriaPage.e2e.test.tsx` — E2E-FIS-UI-001 jornada MemoryRouter + MSW

### Implementation for User Story 1

- [X] T061 [P] [US1] Implementar mappers client em `ci-client-v2/apps/web/src/modules/ouvidoria/api/fiscalizacao-mappers.ts` (GREEN T055)
- [X] T062 [US1] Implementar `ci-client-v2/apps/web/src/modules/ouvidoria/api/fiscalizacao.ts` — `fetchFiscalizacaoPanel`, `runFiscalizacao`, tipos Zod (GREEN T056)
- [X] T063 [P] [US1] Implementar `FiscalizacaoStatsRow.tsx`, `FiscalizacaoChecksCard.tsx`, `FiscalizacaoFindingsCard.tsx`, `FiscalizacaoPanel.tsx` em `ci-client-v2/apps/web/src/modules/ouvidoria/components/` (GREEN T057)
- [X] T064 [P] [US1] Implementar `FiscalizacaoHistoryTable.tsx` em `ci-client-v2/apps/web/src/modules/ouvidoria/components/` (GREEN T058)
- [X] T065 [US1] Implementar `OuvidoriaAuditoriaPage.tsx` em `ci-client-v2/apps/web/src/modules/ouvidoria/pages/OuvidoriaAuditoriaPage.tsx` — banner Jatobá, badge Somente leitura, empty states, ações toolbar
- [X] T066 [US1] Registrar lazy route `ouvidoria-auditoria` em `ci-client-v2/apps/web/src/app/router.tsx` OUVIDORIA_OVERRIDES e export em `ci-client-v2/apps/web/src/modules/ouvidoria/index.ts`
- [X] T067 [US1] Ajustar `ci-client-v2/apps/web/src/modules/shell/pages/ScreenPage.tsx` para **não** renderizar `JatobaFiscalPanel` quando `screenId === 'ouvidoria-auditoria'`
- [X] T068 [US1] GREEN `OuvidoriaAuditoriaPage.integration.test.tsx` e `OuvidoriaAuditoriaPage.e2e.test.tsx`

**Checkpoint**: MVP — painel Fiscalização com dados API; ≤3 cliques desde overview (SC-001)

---

## Phase 7: User Story 3 (UI) — Histórico e Fiscalizar (Priority: P1)

**Goal**: Painel histórico de execuções, ação *Fiscalizar manifestações*, throttle 429 na UI

**Independent Test**: CMP-FIS-009; INT-FIS-002/003; E2E-FIS-UI-003 GREEN

**Depends on**: Phase 6 (página base)

### Tests for User Story 3 UI (TDD — RED first)

- [ ] T069 [P] [US3] Escrever testes (RED) `FiscalizacaoRunsHistoryPanel.test.tsx` em `ci-client-v2/apps/web/src/modules/ouvidoria/__tests__/` — comparar ≥2 execuções anteriores
- [X] T070 [P] [US3] Estender `OuvidoriaAuditoriaPage.e2e.test.tsx` (RED) — Fiscalizar manifestações, throttle E2E-FIS-UI-003

### Implementation for User Story 3 UI

- [X] T071 [US3] Implementar `FiscalizacaoRunsHistoryPanel.tsx` em `ci-client-v2/apps/web/src/modules/ouvidoria/components/FiscalizacaoRunsHistoryPanel.tsx` (GREEN T069)
- [X] T072 [US3] Adicionar `runFiscalizacao()` na página com loading/toast throttle (GREEN T070)
- [X] T073 [US3] Completar MSW handlers POST run + 409 running + 429 throttle em `ci-client-v2/apps/web/src/test/msw/handlers/ouvidoria-fiscalizacao.ts`

**Checkpoint**: Histórico comparável (SC-009); execução sob demanda na UI

---

## Phase 8: User Story 5 — Governança e read-only (Priority: P1)

**Goal**: 403 sem setor; Jatobá obrigatório; zero PII; manifestação inalterada após fiscalização

**Independent Test**: E2E-FIS-002, SC-004/SC-006/SC-007

**Depends on**: Phase 4–6

### Tests for User Story 5 (TDD — RED first)

- [ ] T074 [US5] Estender `ouvidoria-fiscalizacao.e2e-spec.ts` (RED) — E2E-FIS-002 403 sem setor Ouvidoria
- [ ] T075 [P] [US5] Estender trace use-case specs (RED) — manifestação anônima sem campos `requester*` no trace (SC-006)
- [ ] T076 [P] [US5] Estender `run-fiscalizacao.use-case.spec.ts` (RED) — zero writes em `manifestacao.update` mock (SC-004)

### Implementation for User Story 5

- [ ] T077 [US5] Garantir `LicencaSlug.jatoba` no mock `tenantService.getActiveLicencas` em todos os testes e2e fiscalização (GREEN T074)
- [ ] T078 [US5] Auditar mappers/repos — filtrar PII ao montar `tracePayload` e listagens (GREEN T075)
- [ ] T079 [US5] Adicionar caso empty `never_run` / `no_data` em `get-fiscalizacao-panel.use-case.ts` + teste CT-FIS-002

**Checkpoint**: Segurança, licença e sigilo validados em testes automatizados

---

## Phase 9: User Story 6 — Questionários internos (Priority: P2)

**Goal**: Criar questionário interno, responder via portal, refletir no histórico do painel

**Independent Test**: INT-FIS-004; questionnaire-flow.integration-spec GREEN

**Depends on**: Phase 4 (manifestações fiscalizadas)

### Tests for User Story 6 (TDD — RED first)

- [ ] T080 [P] [US6] Escrever testes (RED) repositórios questionnaire em `ci-api-v2/src/modules/ouvidoria-fiscalizacao/test/repository/` — create/list/respond
- [ ] T081 [US6] Escrever testes (RED) `create-questionnaire.use-case.spec.ts` e `respond-questionnaire-internal.use-case.spec.ts` em `ci-api-v2/src/modules/ouvidoria-fiscalizacao/test/use-cases/`
- [ ] T082 [US6] Escrever teste integração (RED) `questionnaire-flow.integration-spec.ts` em `ci-api-v2/src/modules/ouvidoria-fiscalizacao/test/integration/` — INT-FIS-004
- [ ] T083 [P] [US6] Escrever testes componente (RED) `QuestionnaireDialog.test.tsx` em `ci-client-v2/apps/web/src/modules/ouvidoria/__tests__/QuestionnaireDialog.test.tsx` — CMP-FIS-007 fluxo interno

### Implementation for User Story 6

- [ ] T084 [US6] Implementar repositórios questionnaire/answer em `ci-api-v2/src/modules/ouvidoria-fiscalizacao/repository/` (GREEN T080)
- [ ] T085 [US6] Implementar use-cases create/respond internal + endpoints `GET/POST /ouvidoria/fiscalizacao/questionnaires`, `POST .../respond` (GREEN T081)
- [ ] T086 [US6] GREEN `questionnaire-flow.integration-spec.ts`
- [ ] T087 [US6] Implementar `QuestionnaireDialog.tsx` em `ci-client-v2/apps/web/src/modules/ouvidoria/components/` e integrar botão *Novo questionário* na página (GREEN T083)
- [ ] T088 [US6] Estender MSW handlers questionários em `ci-client-v2/apps/web/src/test/msw/handlers/ouvidoria-fiscalizacao.ts`

**Checkpoint**: Questionário interno ponta a ponta; fluxo ≠ conformidade badge

---

## Phase 10: User Story 7 — Questionários externos (Priority: P2)

**Goal**: Link/token para manifestante identificável; formulário público; omitir externo para anônimos

**Independent Test**: E2E-FIS-006/007; E2E-FIS-UI-005; external-respond.integration-spec GREEN

**Depends on**: Phase 9 (questionnaire base)

### Tests for User Story 7 (TDD — RED first)

- [ ] T089 [P] [US7] Escrever testes (RED) `questionnaire-eligibility.spec.ts` em `ci-api-v2/src/modules/ouvidoria-fiscalizacao/lib/questionnaire-eligibility.spec.ts` — CT-FIS-QEL-001 anônimo blocked
- [ ] T090 [US7] Escrever testes (RED) `create-external-questionnaire.use-case.spec.ts` e `respond-questionnaire-public.use-case.spec.ts` em `ci-api-v2/src/modules/ouvidoria-fiscalizacao/test/use-cases/`
- [ ] T091 [US7] Escrever teste integração (RED) `external-respond.integration-spec.ts` em `ci-api-v2/src/modules/ouvidoria-fiscalizacao/test/integration/` — token hash bcrypt mock
- [ ] T092 [P] [US7] Estender `QuestionnaireDialog.test.tsx` (RED) — omit externo quando `canExternal === false` (E2E-FIS-UI-005)

### Implementation for User Story 7

- [ ] T093 [US7] Implementar `questionnaire-eligibility.ts` em `ci-api-v2/src/modules/ouvidoria-fiscalizacao/lib/` (GREEN T089)
- [ ] T094 [US7] Implementar use-cases external + dispatch link + `ouvidoria-fiscalizacao-public.controller.ts` GET/POST responder (GREEN T090)
- [ ] T095 [US7] Estender `ouvidoria-fiscalizacao.e2e-spec.ts` — E2E-FIS-006 400 anônimo, E2E-FIS-007 public respond
- [ ] T096 [US7] GREEN `external-respond.integration-spec.ts`
- [ ] T097 [US7] Implementar `QuestionnairePublicRespondPage.tsx` em `ci-client-v2/apps/web/src/modules/ouvidoria/pages/` + rota pública em `ci-client-v2/apps/web/src/app/router.tsx`
- [ ] T098 [US7] UI: exibir `responseLink` copiável após criar externo; omit opção externa na dialog (GREEN T092)

**Checkpoint**: Externo só para identificável; link manual sem SMTP/WhatsApp real

---

## Phase 11: User Story 8 — Banco de perguntas e fiscalização no detalhe (Priority: P2)

**Goal**: CRUD banco perguntas; card *Fiscalização Jatobá deste registro*; *Fiscalizar dados* scoped

**Independent Test**: CMP-FIS-006/008; E2E-FIS-UI-004; E2E-FIS-008 scoped run

**Depends on**: Phase 4 scoped run; Phase 6 panel

### Tests for User Story 8 (TDD — RED first)

- [ ] T099 [P] [US8] Escrever testes (RED) use-cases question bank em `ci-api-v2/src/modules/ouvidoria-fiscalizacao/test/use-cases/list-questions.use-case.spec.ts`, `create-question.use-case.spec.ts`, `update-question.use-case.spec.ts`
- [ ] T100 [P] [US8] Escrever testes componente (RED) `FiscalizacaoRecordCard.test.tsx` e `QuestionBankPanel.test.tsx` em `ci-client-v2/apps/web/src/modules/ouvidoria/__tests__/`
- [ ] T101 [US8] Estender `OuvidoriaAuditoriaPage.e2e.test.tsx` (RED) — card detalhe wrapper E2E-FIS-UI-004

### Implementation for User Story 8

- [ ] T102 [US8] Implementar repositórios + use-cases CRUD questions + endpoints `GET/POST/PATCH /ouvidoria/fiscalizacao/questions` (GREEN T099)
- [ ] T103 [US8] Implementar seed perguntas default ouvidoria em `ci-api-v2/prisma/seed/seed-fiscalizacao-questions.ts` e wire no seed
- [ ] T104 [US8] Implementar `get-manifestacao-fiscalizacao-summary.use-case.ts` + `GET /ouvidoria/fiscalizacao/manifestacoes/:manifestacaoId` (GREEN T100)
- [ ] T105 [US8] Implementar `FiscalizacaoRecordCard.tsx` e `QuestionBankPanel.tsx` em `ci-client-v2/apps/web/src/modules/ouvidoria/components/` (GREEN T100)
- [ ] T106 [US8] Integrar `FiscalizacaoRecordCard` em `ci-client-v2/apps/web/src/modules/ouvidoria/pages/ManifestacaoDetailPage.tsx` — *Fiscalizar dados* + **Abrir tela**
- [ ] T107 [US8] Estender `ouvidoria-fiscalizacao.e2e-spec.ts` — E2E-FIS-008 scoped run
- [ ] T108 [US8] GREEN testes componente + e2e card detalhe (T101)

**Checkpoint**: Banco editável + fiscalização contextual no detalhe

---

## Phase 12: Polish & Cross-Cutting Concerns

**Purpose**: SLA config admin, copy, limpeza mocks, validação final

- [ ] T109 [P] Implementar `GET/PATCH /ouvidoria/fiscalizacao/sla-config` + use-cases em `ci-api-v2/src/modules/ouvidoria-fiscalizacao/` (opcional UI admin v1: documentar só API)
- [ ] T110 [P] Ajustar copy overview em `ci-client-v2/apps/web/src/modules/ouvidoria/pages/OuvidoriaOverviewPage.tsx` — link Fiscalização aponta para painel real
- [ ] T111 [P] Documentar que mocks `ouvidoria-auditoria` em `ci-client-v2/apps/web/src/modules/shell/data/mock-data.ts` permanecem para referência até migração global
- [ ] T112 Executar `cd ci-api-v2; npm test; npm run test:e2e -- --testPathPattern=ouvidoria-fiscalizacao` — exit 0
- [ ] T113 Executar `cd ci-client-v2/apps/web; npm run test -- fiscalizacao; npm run typecheck` — exit 0
- [ ] T114 Validar cenários manuais em `specs/008-ouvidoria-jatoba-fiscalizacao/quickstart.md` §2 e checklist SC

---

## Dependencies & Execution Order

### Phase Dependencies

```text
Phase 1 Setup
  → Phase 2 Foundational (BLOCKS ALL)
  → Phase 3 US2 Checks
  → Phase 4 US3 API runs
  → Phase 5 US4 Trace ║ Phase 7 US3 UI (após Phase 6)
  → Phase 6 US1 Client MVP
  → Phase 8 US5 Governance
  → Phase 9 US6 Internal Q ║ Phase 11 US8 Question bank (parcial paralelo após US6 base)
  → Phase 10 US7 External Q
  → Phase 11 US8 Record card (completa)
  → Phase 12 Polish
```

### User Story Dependencies

| Story | Depende de | Independente quando |
|-------|------------|---------------------|
| US2 | Phase 2 | Rules + unit tests |
| US3 | US2 | Run API + e2e mocks |
| US4 | US3 | Trace endpoint + sheet |
| US1 | US3 GET panel | Page + MSW |
| US5 | US3–US6 | e2e 403 + PII + read-only |
| US6 | US3 | Questionnaire internal flow |
| US7 | US6 | External + public |
| US8 | US3 scoped + US6 questions | Bank CRUD + record card |

### Parallel Opportunities

- **Phase 1**: T002–T005, T008 em paralelo
- **Phase 2**: T009–T011, T014–T015, T018–T021 em paralelo após T012–T013
- **Phase 3**: T024–T028 specs RED em paralelo; T030–T034 implementação em paralelo
- **Phase 6**: T055–T058 paralelo antes de T065
- **Phase 9 ∥ Phase 11 (partial)**: question bank API (T099–T103) pode iniciar após Phase 2 repos Question entity
- **Phase 12**: T109–T111 em paralelo

### Parallel Example: User Story 2

```bash
# Specs RED em paralelo:
Task T024 deadline.rules.spec.ts
Task T025 forwarding.rules.spec.ts
Task T026 completeness.rules.spec.ts
Task T027 contact.rules.spec.ts
Task T028 evidence.rules.spec.ts

# Implementação GREEN em paralelo:
Task T030 deadline.rules.ts
Task T031 forwarding.rules.ts
Task T032 completeness.rules.ts
Task T033 contact.rules.ts
Task T034 evidence.rules.ts
```

---

## Implementation Strategy

### MVP First (User Story 1 via US2 → US3 → US6 client)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational
3. Complete Phase 3: US2 Checagens
4. Complete Phase 4: US3 Execuções API
5. Complete Phase 6: US1 Painel client (+ Phase 5 trace básico)
6. **STOP and VALIDATE**: Painel real com fiscalização manual — quickstart §2
7. Continue US5, US6–US8, Polish

### Incremental Delivery

| Incremento | Fases | Valor entregue |
|------------|-------|----------------|
| MVP | 1–4, 6 | Painel + fiscalizar + stats reais |
| +Trace | 5 | Rastreio sheets |
| +Governança | 8 | 403, PII, read-only audit |
| +Questionários | 9–10 | Interno + externo |
| +Operação diária | 11 | Banco + detalhe manifestação |
| +Polish | 12 | SLA config, CI green |

### Parallel Team Strategy

| Dev | Foco |
|-----|------|
| A | Phase 2–4 API (checks + runs) |
| B | Phase 6–7 Client painel |
| C | Phase 9–11 Questionários + detalhe (após Phase 4) |

---

## Notes

- `@nestjs/schedule` já presente via feature 007 — reutilizar `ScheduleModule`
- Manifestações `draft` excluídas em `load-manifestacoes-for-fiscalizacao.repository.ts`
- Confirmar `confirmedAt` via evento `registration` (research R13)
- IDs de teste: CT-FIS / CMP-FIS / INT-FIS / E2E-FIS — ver `contracts/test-strategy.md`
- Commit após cada task ou grupo lógico; parar em checkpoints para validar story independente
