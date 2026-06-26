---
description: "Task list for Fiscalização de Compras — Purchasing Jatobá (019-purchasing-fiscalizacao)"
---

# Tasks: Fiscalização de Compras — Purchasing (Jatobá)

**Input**: Design documents from `civ2-docs/specs/019-purchasing-fiscalizacao/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Tests**: **Obrigatórios** — TDD (constitution II + plan.md + `contracts/test-strategy.md`): unitário, componente, contrato, integração (mocks/in-memory) e E2E. **Sem Postgres de teste dedicado**.

**Organization**: US1–US5 são P1; US6 é P2. Caminhos relativos à raiz `ci-v2/`. Módulo API `compras-fiscalizacao` **não existe** — criar do zero espelhando `ouvidoria-fiscalizacao`. Client substitui esqueleto mock `/compras/auditoria` por `/compras/fiscalizacao`.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Pode executar em paralelo (arquivos diferentes, sem dependências pendentes)
- **[Story]**: User story da spec (US1–US6)

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Fixtures, MSW e samples para TDD

- [X] T001 [P] Criar fixture `ci-api-v2/src/modules/compras-fiscalizacao/test/fixtures/demanda-fiscalizacao-sample.json` — demanda parcialmente instruída com PCA e 7 artefatos nullable
- [X] T002 [P] Criar fixtures `ci-api-v2/src/modules/compras-fiscalizacao/test/fixtures/demanda-etp-waived-sample.json` e `demanda-budget-mismatch-sample.json` conforme `research.md` R3
- [X] T003 [P] Criar fixtures `ci-api-v2/src/modules/compras-fiscalizacao/test/fixtures/fiscalizacao-run-completed.json` e `fiscalizacao-panel-completed.json` alinhados ao contrato REST
- [X] T004 [P] Criar fixtures client `ci-client-v2/apps/web/src/modules/compras/fixtures/fiscalizacao-panel-empty.json`, `fiscalizacao-panel-completed.json` e `fiscalizacao-record-partial.json`
- [X] T005 [P] Implementar handlers MSW em `ci-client-v2/apps/web/src/test/msw/handlers/compras-fiscalizacao.ts` e registrar em `ci-client-v2/apps/web/src/test/msw/handlers.ts`
- [X] T006 [P] Documentar `FISCALIZACAO_CRON` (opcional) em `ci-api-v2/.env.example` se ausente

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Schema Prisma, módulo NestJS, loaders, persistência e schemas — **bloqueia todas as user stories**

**⚠️ CRITICAL**: Nenhuma user story começa antes desta fase

### Tests first (TDD — RED)

- [X] T007 [P] Escrever testes (RED) `aggregate-conformity.spec.ts` em `ci-api-v2/src/modules/compras-fiscalizacao/lib/aggregate-conformity.spec.ts` — worst-of 4 status
- [X] T008 [P] Escrever testes (RED) `load-demandas-for-fiscalizacao.repository.spec.ts` em `ci-api-v2/src/modules/compras-fiscalizacao/repository/load-demandas-for-fiscalizacao.repository.spec.ts`
- [X] T009 [P] Escrever testes (RED) `compras-fiscalizacao.schemas.spec.ts` em `ci-api-v2/src/modules/compras-fiscalizacao/compras-fiscalizacao.schemas.spec.ts` — panel response com colunas Demanda/PCA/Artefatos
- [X] T010 [P] Escrever testes (RED) `throttle.spec.ts` em `ci-api-v2/src/modules/compras-fiscalizacao/lib/throttle.spec.ts`

### Schema & module scaffold

- [X] T011 Criar `ci-api-v2/prisma/schema/compras-fiscalizacao.prisma` — `ComprasFiscalizacaoRun`, `Result`, `Check`, `Finding`; adicionar relations em `tenant.prisma` e `compras.prisma`; gerar migration em `ci-api-v2/prisma/migrations/`
- [X] T012 [P] Criar `ci-api-v2/src/modules/compras-fiscalizacao/compras-fiscalizacao.types.ts` — `DemandaForFiscalizacao`, `CheckCandidate`, `FindingCandidate`, `RunChecksResult`, constantes `CHECK_LABEL`/`CHECK_RULE_DESCRIPTION`
- [X] T013 [P] Criar `ci-api-v2/src/modules/compras-fiscalizacao/compras-fiscalizacao.mapper.ts` — `conformityLabel()`, `formatDemandaProtocol()`, `originLabel()`, `artefactsSummaryLabel()`, `toPanelResponse()`
- [X] T014 [P] Criar `ci-api-v2/src/modules/compras-fiscalizacao/lib/aggregate-conformity.ts` e `ci-api-v2/src/modules/compras-fiscalizacao/lib/throttle.ts` — espelhar `ouvidoria-fiscalizacao/lib/` (GREEN T007, T010)

### Repositories & schemas

- [X] T015 Implementar `ci-api-v2/src/modules/compras-fiscalizacao/repository/load-demandas-for-fiscalizacao.repository.ts` — demandas ativas + `demandaArtefactsInclude` + PCA (GREEN T008)
- [X] T016 [P] Implementar `ci-api-v2/src/modules/compras-fiscalizacao/repository/fiscalizacao-persistence.repositories.ts` — create run/result/check/finding
- [X] T017 [P] Implementar `ci-api-v2/src/modules/compras-fiscalizacao/repository/fiscalizacao-query.repositories.ts` — find running, last on-demand, panel queries, history rows
- [X] T018 Criar Zod DTOs em `ci-api-v2/src/modules/compras-fiscalizacao/compras-fiscalizacao.schemas.ts` (GREEN T009)
- [X] T019 Criar `ci-api-v2/src/modules/compras-fiscalizacao/compras-fiscalizacao.module.ts` e registrar `ComprasFiscalizacaoModule` em `ci-api-v2/src/app.module.ts`

**Checkpoint**: Migration aplicada; loader demandas GREEN; persistência/query registrados; módulo importável

---

## Phase 3: User Story 2 — Checagens automáticas por demanda (Priority: P1)

**Goal**: 8 regras determinísticas (7 artefatos + consistência orçamentária); agregação worst-of; reutiliza `compras.mapper.ts`

**Independent Test**: `npm test -- --testPathPattern=compras-fiscalizacao/lib/checks` passa; fixture ETP waived sem motivo → `non_conforme`; dotado < estimado → `partial`

> **Paralelo**: T020–T027 specs RED podem rodar em paralelo.

### Tests for User Story 2 (TDD — RED first)

- [X] T020 [P] [US2] Escrever testes (RED) `dfd-completeness.rules.spec.ts` em `ci-api-v2/src/modules/compras-fiscalizacao/lib/checks/dfd-completeness.rules.spec.ts`
- [X] T021 [P] [US2] Escrever testes (RED) `etp-waiver.rules.spec.ts` em `ci-api-v2/src/modules/compras-fiscalizacao/lib/checks/etp-waiver.rules.spec.ts`
- [X] T022 [P] [US2] Escrever testes (RED) `risk-analysis.rules.spec.ts` em `ci-api-v2/src/modules/compras-fiscalizacao/lib/checks/risk-analysis.rules.spec.ts`
- [X] T023 [P] [US2] Escrever testes (RED) `tr-completeness.rules.spec.ts` em `ci-api-v2/src/modules/compras-fiscalizacao/lib/checks/tr-completeness.rules.spec.ts`
- [X] T024 [P] [US2] Escrever testes (RED) `price-survey.rules.spec.ts` em `ci-api-v2/src/modules/compras-fiscalizacao/lib/checks/price-survey.rules.spec.ts`
- [X] T025 [P] [US2] Escrever testes (RED) `budget-allocation.rules.spec.ts` em `ci-api-v2/src/modules/compras-fiscalizacao/lib/checks/budget-allocation.rules.spec.ts`
- [X] T026 [P] [US2] Escrever testes (RED) `legal-opinion.rules.spec.ts` em `ci-api-v2/src/modules/compras-fiscalizacao/lib/checks/legal-opinion.rules.spec.ts`
- [X] T027 [P] [US2] Escrever testes (RED) `budget-consistency.rules.spec.ts` em `ci-api-v2/src/modules/compras-fiscalizacao/lib/checks/budget-consistency.rules.spec.ts`
- [X] T028 [P] [US2] Escrever testes (RED) `run-checks-for-demanda.spec.ts` em `ci-api-v2/src/modules/compras-fiscalizacao/lib/run-checks-for-demanda.spec.ts` — orquestra 8 checks + findings

### Implementation for User Story 2

- [X] T029 [P] [US2] Implementar `dfd-completeness.rules.ts` em `ci-api-v2/src/modules/compras-fiscalizacao/lib/checks/dfd-completeness.rules.ts` — importa `isDfdSatisfied` de `compras.mapper.ts` (GREEN T020)
- [X] T030 [P] [US2] Implementar `etp-waiver.rules.ts` em `ci-api-v2/src/modules/compras-fiscalizacao/lib/checks/etp-waiver.rules.ts` (GREEN T021)
- [X] T031 [P] [US2] Implementar `risk-analysis.rules.ts` em `ci-api-v2/src/modules/compras-fiscalizacao/lib/checks/risk-analysis.rules.ts` (GREEN T022)
- [X] T032 [P] [US2] Implementar `tr-completeness.rules.ts` em `ci-api-v2/src/modules/compras-fiscalizacao/lib/checks/tr-completeness.rules.ts` (GREEN T023)
- [X] T033 [P] [US2] Implementar `price-survey.rules.ts` em `ci-api-v2/src/modules/compras-fiscalizacao/lib/checks/price-survey.rules.ts` (GREEN T024)
- [X] T034 [P] [US2] Implementar `budget-allocation.rules.ts` em `ci-api-v2/src/modules/compras-fiscalizacao/lib/checks/budget-allocation.rules.ts` (GREEN T025)
- [X] T035 [P] [US2] Implementar `legal-opinion.rules.ts` em `ci-api-v2/src/modules/compras-fiscalizacao/lib/checks/legal-opinion.rules.ts` (GREEN T026)
- [X] T036 [P] [US2] Implementar `budget-consistency.rules.ts` em `ci-api-v2/src/modules/compras-fiscalizacao/lib/checks/budget-consistency.rules.ts` (GREEN T027)
- [X] T037 [US2] Implementar `run-checks-for-demanda.ts` em `ci-api-v2/src/modules/compras-fiscalizacao/lib/run-checks-for-demanda.ts` — orquestra checks + `aggregateConformity` (GREEN T028)

**Checkpoint**: 8 rule specs + orquestrador GREEN; conformidade agregada worst-of (FR-013)

---

## Phase 4: User Story 3 — Execuções persistidas e histórico (Priority: P1)

**Goal**: Run completo/scoped, throttle 1h, job diário, GET panel/runs/history

**Independent Test**: Duas execuções persistidas; segunda manual < 1h → 429; histórico com origem e resumo; job `scheduled`

### Tests for User Story 3 (TDD — RED first)

- [X] T038 [P] [US3] Escrever testes (RED) `run-fiscalizacao.use-case.spec.ts` em `ci-api-v2/src/modules/compras-fiscalizacao/use-cases/run-fiscalizacao.use-case.spec.ts`
- [X] T039 [P] [US3] Escrever testes (RED) `run-fiscalizacao-scoped.use-case.spec.ts` em `ci-api-v2/src/modules/compras-fiscalizacao/use-cases/run-fiscalizacao-scoped.use-case.spec.ts`
- [X] T040 [P] [US3] Escrever testes (RED) `get-fiscalizacao-panel.use-case.spec.ts` em `ci-api-v2/src/modules/compras-fiscalizacao/use-cases/get-fiscalizacao-panel.use-case.spec.ts`
- [X] T041 [P] [US3] Escrever testes (RED) `list-fiscalizacao-runs.use-case.spec.ts` em `ci-api-v2/src/modules/compras-fiscalizacao/use-cases/list-fiscalizacao-runs.use-case.spec.ts`

### Implementation for User Story 3

- [X] T042 [US3] Implementar `run-fiscalizacao.use-case.ts` em `ci-api-v2/src/modules/compras-fiscalizacao/use-cases/run-fiscalizacao.use-case.ts` — 100% demandas ativas, persistência, throttle, conflito running (GREEN T038)
- [X] T043 [US3] Implementar `run-fiscalizacao-scoped.use-case.ts` em `ci-api-v2/src/modules/compras-fiscalizacao/use-cases/run-fiscalizacao-scoped.use-case.ts` — origin `on_record` (GREEN T039)
- [X] T044 [US3] Implementar `get-fiscalizacao-panel.use-case.ts` em `ci-api-v2/src/modules/compras-fiscalizacao/use-cases/get-fiscalizacao-panel.use-case.ts` — última execução, checksSummary, historyRows Compras (GREEN T040)
- [X] T045 [US3] Implementar `list-fiscalizacao-runs.use-case.ts` em `ci-api-v2/src/modules/compras-fiscalizacao/use-cases/list-fiscalizacao-runs.use-case.ts` (GREEN T041)
- [X] T046 [P] [US3] Implementar `run-fiscalizacao-scheduled.job.ts` em `ci-api-v2/src/modules/compras-fiscalizacao/jobs/run-fiscalizacao-scheduled.job.ts` — origin `scheduled`, cron diário
- [X] T047 [US3] Implementar `compras-fiscalizacao.controller.ts` em `ci-api-v2/src/modules/compras-fiscalizacao/compras-fiscalizacao.controller.ts` — `GET /`, `POST /run`, `GET /runs`, `GET /runs/:runId`, guards módulo + Jatobá
- [X] T048 [US3] Wire providers use-cases + repositories em `ci-api-v2/src/modules/compras-fiscalizacao/compras-fiscalizacao.module.ts`

**Checkpoint**: POST run persiste execução; GET panel/history conforme contrato REST; throttle 429

---

## Phase 5: User Story 1 — Ver painel de Fiscalização de Compras (Priority: P1) 🎯 MVP

**Goal**: `/compras/fiscalizacao` com stats, checagens, achados, histórico — substituir mock

**Independent Test**: VS-001 quickstart — painel exibe dados reais após *Fiscalizar demandas*; badge **Somente leitura**; colunas Demanda/PCA/Artefatos

### Tests for User Story 1 (TDD — RED first)

- [X] T049 [P] [US1] Escrever testes (RED) `fiscalizacao-mappers.test.ts` em `ci-client-v2/apps/web/src/modules/compras/__tests__/fiscalizacao-mappers.test.ts`
- [X] T050 [P] [US1] Escrever testes (RED) `ComprasFiscalizacaoPage.integration.test.tsx` em `ci-client-v2/apps/web/src/modules/compras/__tests__/ComprasFiscalizacaoPage.integration.test.tsx`

### Implementation for User Story 1

- [X] T051 [P] [US1] Estender `ci-client-v2/apps/web/src/modules/ouvidoria/components/FiscalizacaoPanel.tsx` — props `moduleConfig` (título, botão *Fiscalizar demandas*, ocultar questionários) sem quebrar Ouvidoria/Gabinete
- [X] T052 [P] [US1] Estender `ci-client-v2/apps/web/src/modules/ouvidoria/components/FiscalizacaoHistoryTable.tsx` — props colunas Compras (Demanda, PCA, Artefatos fiscalizados, Conformidade, Problemas)
- [X] T053 [P] [US1] Implementar `ci-client-v2/apps/web/src/modules/compras/api/fiscalizacao-mappers.ts` (GREEN T049)
- [X] T054 [US1] Implementar `ci-client-v2/apps/web/src/modules/compras/api/fiscalizacao.ts` — fetchPanel, fetchRunDetail, runFiscalizacao, tipos alinhados ao contrato REST
- [X] T055 [US1] Implementar `ci-client-v2/apps/web/src/modules/compras/pages/ComprasFiscalizacaoPage.tsx` — reutiliza `FiscalizacaoPanel`, stats, achados, histórico, feedback throttle (GREEN T050)
- [X] T056 [US1] Atualizar `ci-client-v2/apps/web/src/modules/shell/config/screens.ts`, `navigation.ts` e `ci-client-v2/apps/web/src/app/router.tsx` — rota `/compras/fiscalizacao`, screenId `compras-fiscalizacao`, redirect `/compras/auditoria`
- [X] T057 [P] [US1] Exportar página e tipos em `ci-client-v2/apps/web/src/modules/compras/index.ts`

**Checkpoint**: Painel Compras funcional ponta a ponta com API real ou MSW — MVP demonstrável (SC-001)

---

## Phase 6: User Story 4 — Rastreabilidade Jatobá (Priority: P1)

**Goal**: Sheets com títulos canônicos; endpoints trace; tracePayload nos checks/findings

**Independent Test**: Click checagem → sheet **Por que esta checagem deu este resultado** (~85% viewport); badge **Somente leitura**

### Tests for User Story 4 (TDD — RED first)

- [X] T058 [P] [US4] Escrever testes (RED) `get-check-trace.use-case.spec.ts` e `get-finding-trace.use-case.spec.ts` em `ci-api-v2/src/modules/compras-fiscalizacao/use-cases/`
- [X] T059 [P] [US4] Escrever testes (RED) `get-demanda-trace.use-case.spec.ts` em `ci-api-v2/src/modules/compras-fiscalizacao/use-cases/get-demanda-trace.use-case.spec.ts`
- [X] T060 [P] [US4] Escrever testes (RED) títulos Compras em `ci-client-v2/apps/web/src/modules/compras/__tests__/FiscalizacaoTraceSheet.compras.test.tsx`

### Implementation for User Story 4

- [X] T061 [P] [US4] Implementar `get-check-trace.use-case.ts`, `get-finding-trace.use-case.ts` e `get-demanda-trace.use-case.ts` em `ci-api-v2/src/modules/compras-fiscalizacao/use-cases/` (GREEN T058–T059)
- [X] T062 [US4] Adicionar rotas trace em `ci-api-v2/src/modules/compras-fiscalizacao/compras-fiscalizacao.controller.ts` — `GET checks/:id/trace`, `findings/:id/trace`, `demandas/:id/trace`
- [X] T063 [US4] Wire `FiscalizacaoTraceSheet` em `ci-client-v2/apps/web/src/modules/compras/pages/ComprasFiscalizacaoPage.tsx` (GREEN T060)
- [X] T064 [P] [US4] Estender `ci-client-v2/apps/web/src/modules/compras/api/fiscalizacao.ts` — fetchCheckTrace, fetchFindingTrace, fetchDemandaTrace

**Checkpoint**: 100% checagens/achados com rastreio sheet (SC-004)

---

## Phase 7: User Story 5 — Governança: licença, permissão e read-only (Priority: P1)

**Goal**: Guards módulo + Jatobá; fiscalização não altera demandas/artefatos; empty state sem demandas

**Independent Test**: Usuário sem módulo → 403; sem licença → alerta; snapshot demanda idêntico pós-run (SC-005)

### Tests for User Story 5 (TDD — RED first)

- [X] T065 [P] [US5] Escrever testes (RED) `ci-api-v2/test/compras-fiscalizacao.e2e-spec.ts` — guards 403, throttle 429, `emptyReason: no_data`
- [X] T066 [P] [US5] Escrever testes (RED) read-only em `ci-api-v2/test/compras-fiscalizacao.e2e-spec.ts` — snapshot CompraDemanda/artefatos before/after run (SC-005)
- [X] T067 [P] [US5] Escrever testes (RED) acesso client em `ci-client-v2/apps/web/src/modules/compras/__tests__/ComprasFiscalizacaoPage.access.test.tsx` — 403, alerta licença, empty state

### Implementation for User Story 5

- [X] T068 [US5] Garantir `@RequireModulo('compras')` + `@RequireLicenca('jatoba')` em `ci-api-v2/src/modules/compras-fiscalizacao/compras-fiscalizacao.controller.ts` (GREEN T065)
- [X] T069 [US5] Implementar `emptyReason: no_data` em `get-fiscalizacao-panel.use-case.ts` e copy client via `fiscalizacao-mappers.ts` (GREEN T067)
- [X] T070 [US5] GREEN suite E2E read-only + guards em `ci-api-v2/test/compras-fiscalizacao.e2e-spec.ts` (GREEN T066)

**Checkpoint**: SC-005 e FR-015 validados; tenant vazio orienta operação

---

## Phase 8: User Story 6 — Fiscalização contextual no detalhe da demanda (Priority: P2)

**Goal**: Card **Fiscalização Jatobá desta demanda** no hub; execução scoped; link painel

**Independent Test**: VS-008 quickstart — card + *Fiscalizar demanda* → checagens atualizadas ≤ 5s (SC-008)

### Tests for User Story 6 (TDD — RED first)

- [X] T071 [P] [US6] Escrever testes (RED) `get-fiscalizacao-record.use-case.spec.ts` em `ci-api-v2/src/modules/compras-fiscalizacao/use-cases/get-fiscalizacao-record.use-case.spec.ts`
- [X] T072 [P] [US6] Escrever testes (RED) `ComprasFiscalizacaoRecordCard.test.tsx` em `ci-client-v2/apps/web/src/modules/compras/__tests__/ComprasFiscalizacaoRecordCard.test.tsx`
- [X] T073 [P] [US6] Escrever testes (RED) card no hub em `ci-client-v2/apps/web/src/modules/compras/__tests__/DemandaHubPage.fiscalizacao.test.tsx`

### Implementation for User Story 6

- [X] T074 [US6] Implementar `get-fiscalizacao-record.use-case.ts` em `ci-api-v2/src/modules/compras-fiscalizacao/use-cases/get-fiscalizacao-record.use-case.ts` (GREEN T071)
- [X] T075 [US6] Adicionar `GET /demandas/:demandaId` e `POST /run/demandas/:demandaId` wiring completo em `compras-fiscalizacao.controller.ts`
- [X] T076 [US6] Implementar `ComprasFiscalizacaoRecordCard.tsx` em `ci-client-v2/apps/web/src/modules/compras/components/ComprasFiscalizacaoRecordCard.tsx` (GREEN T072)
- [X] T077 [US6] Integrar card em `ci-client-v2/apps/web/src/modules/compras/pages/DemandaHubPage.tsx` — ocultar sem licença Jatobá (GREEN T073)
- [X] T078 [P] [US6] Estender `ci-client-v2/apps/web/src/modules/compras/api/fiscalizacao.ts` — fetchRecord, runScoped

**Checkpoint**: Hub demanda com fiscalização scoped; paridade Gabinete US8

---

## Phase 9: Polish & Cross-Cutting Concerns

**Purpose**: Integração final, remoção de mocks legados, validação quickstart

- [X] T079 [P] Escrever testes (RED) `ComprasFiscalizacaoPage.e2e.test.tsx` em `ci-client-v2/apps/web/src/modules/compras/__tests__/ComprasFiscalizacaoPage.e2e.test.tsx` — jornada SC-007 ponta a ponta
- [X] T080 [P] Escrever testes (RED) `run-fiscalizacao.integration.spec.ts` em `ci-api-v2/src/modules/compras-fiscalizacao/test/integration/run-fiscalizacao.integration.spec.ts`
- [X] T081 [P] Escrever testes (RED) `fiscalizacao.contract.test.ts` em `ci-client-v2/apps/web/src/modules/compras/__tests__/fiscalizacao.contract.test.ts` — Zod panel response
- [X] T082 Remover mock `compras-auditoria` de `ci-client-v2/apps/web/src/modules/shell/data/mock-data.ts` e referências obsoletas em `screens.ts` actions (questionário)
- [ ] T083 Executar cenários VS-001–VS-008 de `quickstart.md` e corrigir gaps encontrados
- [X] T084 Rodar suíte completa: `npm test -- --testPathPatterns=compras-fiscalizacao` (API) + `npm test --workspace=@ci/web -- --run ComprasFiscalizacao` (client)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Sem dependências — iniciar imediatamente
- **Foundational (Phase 2)**: Depende de Phase 1 — **BLOQUEIA** todas as user stories
- **US2 (Phase 3)**: Depende de Foundational — **BLOQUEIA** US3 (persistência precisa de checks)
- **US3 (Phase 4)**: Depende de US2 — **BLOQUEIA** US1, US4, US6 (API panel/run)
- **US1 (Phase 5)**: Depende de US3 — MVP client
- **US4 (Phase 6)**: Depende de US3 — trace precisa de checks persistidos
- **US5 (Phase 7)**: Depende de US3 — e2e API; client access pode paralelizar com US1 após US3
- **US6 (Phase 8)**: Depende de US3 + US4 (opcional trace no card)
- **Polish (Phase 9)**: Depende de US1–US6 desejadas

### User Story Dependencies

| Story | Depende de | Independente quando |
|-------|------------|---------------------|
| US2 | Foundational | Rules specs GREEN isoladamente |
| US3 | US2 | Run persiste + panel API testável via Supertest |
| US1 | US3 | Painel client com MSW ou API |
| US4 | US3 | Trace endpoints após checks persistidos |
| US5 | US3 | E2E guards/read-only na API |
| US6 | US3 | Card + scoped run |

### Parallel Opportunities

- **Phase 1**: T001–T006 em paralelo
- **Phase 2 RED**: T007–T010 em paralelo
- **Phase 3**: T020–T028 RED em paralelo; T029–T036 GREEN em paralelo
- **Phase 4 RED**: T038–T041 em paralelo
- **Phase 5**: T049–T052 em paralelo; T051–T052 refactor componentes ouvidoria
- **Phase 6–8**: specs RED marcados [P] em paralelo por story
- **Cross-team**: Após US3, US1 (client) e US5 (e2e) podem avançar em paralelo

---

## Parallel Example: User Story 2

```bash
# Specs RED em paralelo:
Task T020: dfd-completeness.rules.spec.ts
Task T021: etp-waiver.rules.spec.ts
Task T022: risk-analysis.rules.spec.ts
# ... T023–T027

# Implementações GREEN em paralelo (após RED):
Task T029: dfd-completeness.rules.ts
Task T030: etp-waiver.rules.ts
# ... T031–T036
```

---

## Implementation Strategy

### MVP First (US1 via US2 + US3)

1. Phase 1: Setup
2. Phase 2: Foundational
3. Phase 3: US2 — checagens (núcleo)
4. Phase 4: US3 — execuções + API panel
5. Phase 5: US1 — painel client 🎯
6. **STOP and VALIDATE**: VS-001 quickstart

### Incremental Delivery

1. Setup + Foundational → base Prisma + módulo
2. US2 → rules GREEN isoladas
3. US3 → API completa testável
4. US1 → MVP painel (deploy/demo)
5. US4 → rastreio sheet
6. US5 → governança produção
7. US6 → card hub (P2)
8. Polish → SC-007 e quickstart

### Suggested MVP Scope

**Mínimo demonstrável**: Phase 1 + 2 + 3 + 4 + 5 (US2 + US3 + US1) — painel funcional com fiscalização real, sem card hub nem trace completo.

**Produção Jatobá Compras**: incluir US4 + US5 antes de merge.

---

## Notes

- Reutilizar `compras.mapper.ts` — **nunca** duplicar lógica de satisfação de artefatos
- **Sem** questionários — não portar `QuestionBankPanel` / seed perguntas
- Rota canônica `/compras/fiscalizacao` — não `/compras/auditoria`
- Hub demanda: `/compras/:demandaId` (router atual)
- Commit após cada task ou grupo lógico; parar em checkpoints para validar story

---

## Task Summary

| Phase | Story | Tasks | IDs |
|-------|-------|-------|-----|
| 1 Setup | — | 6 | T001–T006 |
| 2 Foundational | — | 13 | T007–T019 |
| 3 US2 Checagens | US2 | 18 | T020–T037 |
| 4 US3 Execuções | US3 | 11 | T038–T048 |
| 5 US1 Painel 🎯 | US1 | 9 | T049–T057 |
| 6 US4 Rastreio | US4 | 7 | T058–T064 |
| 7 US5 Governança | US5 | 6 | T065–T070 |
| 8 US6 Card hub | US6 | 8 | T071–T078 |
| 9 Polish | — | 6 | T079–T084 |
| **Total** | | **84** | T001–T084 |
