---
description: "Task list for Desmock Jurídico (012-desmock-juridico)"
---

# Tasks: Desmock Jurídico — Módulo Legal Completo

**Input**: Design documents from `civ2-docs/specs/012-desmock-juridico/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Tests**: **Obrigatórios** — TDD (constitution II + plan.md + `contracts/test-strategy.md`): unitário, componente, contrato, integração (mocks/in-memory) e E2E. **Sem Postgres de teste dedicado**.

**Organization**: 9 user stories P1 (US1–US9). Caminhos relativos à raiz `ci-v2/`.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Pode executar em paralelo (arquivos diferentes, sem dependências pendentes)
- **[Story]**: User story da spec (US1–US9)

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Scaffolding módulos, fixtures, MSW, env Wasabi

- [X] T001 [P] Documentar vars Wasabi em `ci-api-v2/.env.example` se ausentes (reuso 003-ouvidoria; prefixo `juridico` em storageKey)
- [X] T002 [P] Criar esqueleto `ci-api-v2/src/modules/juridico/` com pastas `repository/`, `use-cases/`, `lib/`, `test/`
- [X] T003 [P] Criar esqueleto `ci-api-v2/src/modules/juridico-fiscalizacao/` espelhando `ouvidoria-fiscalizacao/` (`lib/checks/`, `repository/`, `use-cases/`, `jobs/`, `test/`)
- [X] T004 [P] Criar esqueleto `ci-api-v2/src/modules/juridico-insights/` espelhando `ouvidoria-insights/`
- [X] T005 [P] Criar esqueleto `ci-api-v2/src/modules/juridico-maturidade/` espelhando `ouvidoria-maturidade/`
- [X] T006 [P] Criar esqueleto client `ci-client-v2/apps/web/src/modules/juridico/` com `api/`, `pages/`, `components/`, `fixtures/`, `__tests__/`
- [X] T007 [P] Criar fixtures client `ci-client-v2/apps/web/src/modules/juridico/fixtures/processo-detail-empty.json` e `fiscalizacao-panel-empty.json`
- [X] T008 [P] Adicionar handlers MSW stub em `ci-client-v2/apps/web/src/test/msw/handlers/juridico.ts` e registrar em `ci-client-v2/apps/web/src/test/msw/handlers.ts`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Schema Base, Storage compartilhado, módulo registrado — **bloqueia todas as user stories**

**⚠️ CRITICAL**: Nenhuma user story começa antes desta fase

### Tests first (TDD — RED)

- [X] T009 [P] Escrever testes (RED) `generate-internal-number.spec.ts` em `ci-api-v2/src/modules/juridico/test/lib/generate-internal-number.spec.ts` — CT-JUR-001
- [X] T010 [P] Escrever testes (RED) `juridico.schemas.spec.ts` em `ci-api-v2/src/modules/juridico/juridico.schemas.spec.ts` — validação draft/confirm
- [X] T011 [P] Escrever testes (RED) `derive-operational-status.spec.ts` em `ci-api-v2/src/modules/juridico/test/lib/derive-operational-status.spec.ts` — CT-JUR-003

### Schema & migration (Base)

- [X] T012 Criar enums Jurídico em `ci-api-v2/prisma/schema/juridico.prisma` — LegalProcessType, Status, Sphere, PartyRole, PersonType, EventType conforme `data-model.md`
- [X] T013 Criar modelos Base em `ci-api-v2/prisma/schema/juridico.prisma` — LegalProcess, LegalProcessSequence, LegalProcessParty, LegalProcessAttachment, LegalProcessEvent
- [X] T014 Registrar schema em `ci-api-v2/prisma/schema/schema.prisma`, relações em `ci-api-v2/prisma/schema/tenant.prisma` e gerar migration (`npx prisma migrate dev`)

### Storage compartilhado (R4/R7)

- [X] T015 Extrair ou reutilizar `StorageService` em `ci-api-v2/src/modules/shared/storage/storage.service.ts` (se já existir por 012-gabinete, importar; senão extrair de `ouvidoria/services/storage.service.ts`)
- [X] T016 Refatorar `ci-api-v2/src/modules/ouvidoria/ouvidoria.module.ts` para `StorageModule` shared se T015 extraiu; rodar testes ouvidoria (regressão)

### Module registration & seed

- [X] T017 Implementar Zod DTOs base em `ci-api-v2/src/modules/juridico/juridico.schemas.ts` (GREEN T010)
- [X] T018 [P] Implementar `generate-internal-number.ts` em `ci-api-v2/src/modules/juridico/lib/generate-internal-number.ts` (GREEN T009)
- [X] T019 [P] Implementar `derive-operational-status.ts` em `ci-api-v2/src/modules/juridico/lib/derive-operational-status.ts` (GREEN T011)
- [X] T020 [P] Criar repositórios stub — `allocate-internal-number.repository.ts`, `create-process-draft.repository.ts` em `ci-api-v2/src/modules/juridico/repository/` + specs mock Prisma
- [X] T021 Registrar `JuridicoModule` em `ci-api-v2/src/app.module.ts` com controller stub e `@RequireModulo('juridico')`
- [X] T022 [P] Garantir vínculo módulo↔setor DEJUR em `ci-api-v2/prisma/seed/seed-jacaranda-tenant.ts` (ModuloSlug.juridico)

**Checkpoint**: Migration Base aplicada; Storage disponível; JuridicoModule registrado; libs GREEN

---

## Phase 3: User Story 1 — Registrar processo via wizard (Priority: P1) 🎯 MVP

**Goal**: Draft → revisão → confirm; número `JUR-AAAA-NNNN`; partes e órgão estruturados (tudo opcional)

**Independent Test**: VS-002 quickstart (sem anexo); client `/juridico/processos/novo` steps dados + revisão + confirm

### Tests for User Story 1 (TDD — RED first)

- [X] T023 [P] [US1] Escrever testes (RED) `create-process-draft.use-case.spec.ts` em `ci-api-v2/src/modules/juridico/test/use-cases/create-process-draft.use-case.spec.ts` — CT-JUR-002 zero partes OK
- [X] T024 [P] [US1] Escrever testes (RED) `confirm-process.use-case.spec.ts` em `ci-api-v2/src/modules/juridico/test/use-cases/confirm-process.use-case.spec.ts` — CT-JUR-001
- [X] T025 [P] [US1] Escrever teste contrato (RED) `juridico.contract.spec.ts` em `ci-api-v2/src/modules/juridico/test/juridico.contract.spec.ts` — POST/PATCH/confirm

### Implementation for User Story 1

- [X] T026 [US1] Implementar `create-process-draft.use-case.ts` e `update-process-draft.use-case.ts` em `ci-api-v2/src/modules/juridico/use-cases/` (GREEN T023)
- [X] T027 [P] [US1] Implementar repositórios partes/endereço — `upsert-process-parties.repository.ts`, `link-party-address.repository.ts` em `ci-api-v2/src/modules/juridico/repository/`
- [X] T028 [US1] Implementar `confirm-process.use-case.ts` — sequence, evento `registration`, status `open` (GREEN T024)
- [X] T029 [US1] Expor POST `/juridico/processos`, PATCH `/juridico/processos/:id`, POST `.../confirm` em `ci-api-v2/src/modules/juridico/juridico.controller.ts` conforme `contracts/rest-api-juridico.md`
- [X] T030 [P] [US1] Implementar `juridico.mapper.ts` PT-BR ↔ EN em `ci-api-v2/src/modules/juridico/juridico.mapper.ts`
- [X] T031 [P] [US1] Criar API client `ci-client-v2/apps/web/src/modules/juridico/api/processos.ts` — createDraft, updateDraft, confirm
- [X] T032 [US1] Implementar wizard steps Dados + Revisão — `ProcessoWizard/DadosStep.tsx`, `RevisaoStep.tsx`, `ProcessoPartesForm.tsx`, `ProcessoOrgaoForm.tsx` em `ci-client-v2/apps/web/src/modules/juridico/components/`
- [X] T033 [US1] Implementar `JuridicoProcessoWizardPage.tsx` em `ci-client-v2/apps/web/src/modules/juridico/pages/` com copy revisão canônica

**Checkpoint**: Confirmar processo gera JUR-AAAA-NNNN; partes/orgão opcionais persistidos

---

## Phase 4: User Story 2 — Anexar documentos Wasabi (Priority: P1)

**Goal**: Etapa anexos wizard; presign → upload direto → confirm; rejeição 30MB/MIME

**Independent Test**: VS-002 passos presign/confirm; CT-JUR-004

### Tests for User Story 2 (TDD — RED first)

- [ ] T034 [P] [US2] Escrever testes (RED) `presign-process-anexo.use-case.spec.ts` em `ci-api-v2/src/modules/juridico/test/use-cases/presign-process-anexo.use-case.spec.ts`
- [ ] T035 [P] [US2] Escrever testes (RED) `attachment-validation.spec.ts` em `ci-api-v2/src/modules/juridico/test/lib/attachment-validation.spec.ts` — CT-JUR-004

### Implementation for User Story 2

- [ ] T036 [US2] Implementar `presign-process-anexo.use-case.ts` e `confirm-process-anexo.use-case.ts` em `ci-api-v2/src/modules/juridico/use-cases/` (GREEN T034)
- [ ] T037 [US2] Expor POST presign/confirm anexos em `ci-api-v2/src/modules/juridico/juridico.controller.ts`
- [ ] T038 [P] [US2] Estender `ci-client-v2/apps/web/src/modules/juridico/api/processos.ts` — presignAnexo, confirmAnexo
- [ ] T039 [US2] Implementar `ProcessoWizard/AnexosStep.tsx` reutilizando padrão upload ouvidoria em `ci-client-v2/apps/web/src/modules/juridico/components/`
- [ ] T040 [US2] Integrar step Anexos + Confirmação final no `JuridicoProcessoWizardPage.tsx`

**Checkpoint**: Wizard 4 etapas completo com anexo Wasabi

---

## Phase 5: User Story 3 — Lista e detalhe de processos (Priority: P1)

**Goal**: GET lista filtros; GET detalhe + timeline; PATCH pós-confirmação; badge operacional

**Independent Test**: VS-003 quickstart; zero linhas mock `juridico-lista`

### Tests for User Story 3 (TDD — RED first)

- [ ] T041 [P] [US3] Escrever testes (RED) `list-processes.use-case.spec.ts` em `ci-api-v2/src/modules/juridico/test/use-cases/list-processes.use-case.spec.ts`
- [ ] T042 [P] [US3] Escrever testes (RED) `get-process-detail.use-case.spec.ts` em `ci-api-v2/src/modules/juridico/test/use-cases/get-process-detail.use-case.spec.ts`
- [ ] T043 [P] [US3] Escrever teste componente (RED) `JuridicoProcessosListPage.test.tsx` em `ci-client-v2/apps/web/src/modules/juridico/__tests__/` — CT-JUR-007

### Implementation for User Story 3

- [ ] T044 [US3] Implementar `list-processes.repository.ts` e `list-processes.use-case.ts` com filtros e `partesResumo` (GREEN T041)
- [ ] T045 [US3] Implementar `get-process-detail.use-case.ts` e `update-process.use-case.ts` com timeline (GREEN T042)
- [ ] T046 [US3] Expor GET `/juridico/processos`, GET/PATCH `/juridico/processos/:id` em `juridico.controller.ts`
- [ ] T047 [P] [US3] Estender `ci-client-v2/apps/web/src/modules/juridico/api/processos.ts` — list, getById, update
- [ ] T048 [US3] Implementar `JuridicoProcessosListPage.tsx` com DataTable, filtros, badge crítico operacional
- [ ] T049 [US3] Implementar `ProcessoTimeline.tsx` e `JuridicoProcessoDetailPage.tsx` em `ci-client-v2/apps/web/src/modules/juridico/`
- [ ] T050 [US3] Registrar `JURIDICO_OVERRIDES` para `juridico-lista`, `juridico-detalhes`, `juridico-editar` em `ci-client-v2/apps/web/src/app/router.tsx`

**Checkpoint**: Lista e detalhe substituem mock; timeline visível

---

## Phase 6: User Story 4 — Dashboard Jurídico (Priority: P1)

**Goal**: KPIs reais + gráfico distribuição status; conformidade legal do último run Jatobá (0 se ausente)

**Independent Test**: VS-004 quickstart

### Tests for User Story 4 (TDD — RED first)

- [ ] T051 [P] [US4] Escrever testes (RED) `get-juridico-dashboard.use-case.spec.ts` em `ci-api-v2/src/modules/juridico/test/use-cases/get-juridico-dashboard.use-case.spec.ts`

### Implementation for User Story 4

- [ ] T052 [US4] Implementar `get-juridico-dashboard.use-case.ts` — agregações processos + pareceres/mês via eventos `opinion` (GREEN T051)
- [ ] T053 [US4] Expor GET `/juridico/dashboard` em `juridico.controller.ts`
- [ ] T054 [P] [US4] Criar `ci-client-v2/apps/web/src/modules/juridico/api/dashboard.ts`
- [ ] T055 [US4] Implementar `JuridicoDashboardPage.tsx` com cards KPI + Nivo bar chart
- [ ] T056 [US4] Registrar override `juridico-dashboard` em `router.tsx`; remover case `'juridico'` mock de `ci-client-v2/apps/web/src/modules/shell/components/mock/DashboardCharts.tsx` para rota real

**Checkpoint**: Dashboard sem números estáticos 47/6/23/82%

---

## Phase 7: User Story 5 — Fiscalização Jatobá + Probabilidade de Perda (Priority: P1)

**Goal**: Painel `/juridico/auditoria`; checks determinísticos; coluna Probabilidade de Perda; runs persistidos; card detalhe

**Independent Test**: VS-005 quickstart; CT-JUR-FIS-*

### Tests for User Story 5 (TDD — RED first)

- [ ] T057 [P] [US5] Escrever testes (RED) `loss-probability.rules.spec.ts` em `ci-api-v2/src/modules/juridico-fiscalizacao/lib/checks/loss-probability.rules.spec.ts` — CT-JUR-FIS-001/002
- [ ] T058 [P] [US5] Escrever testes (RED) `deadline.rules.spec.ts`, `judicial-id.rules.spec.ts`, `attachments.rules.spec.ts` em `ci-api-v2/src/modules/juridico-fiscalizacao/lib/checks/`
- [ ] T059 [P] [US5] Escrever testes (RED) `aggregate-conformity.spec.ts` em `ci-api-v2/src/modules/juridico-fiscalizacao/lib/aggregate-conformity.spec.ts` — CT-JUR-FIS-004
- [ ] T060 [P] [US5] Escrever testes (RED) `run-fiscalizacao.use-case.spec.ts` em `ci-api-v2/src/modules/juridico-fiscalizacao/test/use-cases/`

### Schema fiscalização

- [ ] T061 [US5] Criar `ci-api-v2/prisma/schema/juridico-fiscalizacao.prisma` — Run, Result (com `lossProbabilityBand`, `lossProbabilityScore`), Check, Finding, Question*, Questionnaire, Answer
- [ ] T062 [US5] Migration fiscalização + seed `ci-api-v2/prisma/seed/seed-fiscalizacao-questions-juridico.ts`

### Implementation for User Story 5

- [ ] T063 [US5] Implementar checks puros em `ci-api-v2/src/modules/juridico-fiscalizacao/lib/checks/` incl. `loss-probability.rules.ts` (GREEN T057–T058)
- [ ] T064 [US5] Implementar `run-fiscalizacao.use-case.ts`, `run-fiscalizacao-scoped.use-case.ts`, `get-fiscalizacao-panel.use-case.ts` em `use-cases/` (GREEN T060)
- [ ] T065 [US5] Implementar job `run-fiscalizacao-scheduled.job.ts` e throttle em `lib/throttle.ts`
- [ ] T066 [US5] Expor rotas `/juridico/fiscalizacao/*` em `juridico-fiscalizacao.controller.ts` + public responder em `juridico-fiscalizacao-public.controller.ts` conforme `contracts/rest-api-juridico-fiscalizacao.md`
- [ ] T067 [US5] Registrar `JuridicoFiscalizacaoModule` em `app.module.ts` com `@RequireLicenca('jatoba')`
- [ ] T068 [P] [US5] Criar `ci-client-v2/apps/web/src/modules/juridico/api/fiscalizacao.ts` + mappers
- [ ] T069 [US5] Implementar `JuridicoAuditoriaPage.tsx` e componentes Fiscalização (clone ouvidoria) com coluna **Probabilidade de Perda**
- [ ] T070 [US5] Implementar `ProcessoDetailFiscalCard.tsx` e integrar em `JuridicoProcessoDetailPage.tsx`
- [ ] T071 [US5] Registrar override `juridico-auditoria` em `router.tsx`
- [ ] T072 [P] [US5] Escrever e2e (RED→GREEN) `juridico-fiscalizacao.e2e-spec.ts` em `ci-api-v2/test/` — CT-JUR-FIS-005/006

**Checkpoint**: Fiscalizar processos; loss band explicável; read-only sobre processo

---

## Phase 8: User Story 6 — Insights Cedro (Priority: P1)

**Goal**: Painel `/juridico/insights`; agregadores risco processual; geração híbrida; trace sheet

**Independent Test**: VS-006 quickstart; CT-JUR-INS-*

### Tests for User Story 6 (TDD — RED first)

- [ ] T073 [P] [US6] Escrever testes (RED) agregadores em `ci-api-v2/src/modules/juridico-insights/lib/aggregation/*.spec.ts` — CT-JUR-INS-001
- [ ] T074 [P] [US6] Escrever testes (RED) `generate-insights-batch.use-case.spec.ts` em `ci-api-v2/src/modules/juridico-insights/test/use-cases/`

### Schema insights

- [ ] T075 [US6] Criar `ci-api-v2/prisma/schema/juridico-insights.prisma` — Batch, Insight, Evidence; migration

### Implementation for User Story 6

- [ ] T076 [US6] Implementar agregadores determinísticos em `ci-api-v2/src/modules/juridico-insights/lib/aggregation/` (GREEN T073)
- [ ] T077 [US6] Implementar use-cases batch/panel/throttle + job scheduled em `juridico-insights/`
- [ ] T078 [US6] Expor `/juridico/insights/*` em `juridico-insights.controller.ts` conforme `contracts/rest-api-juridico-insights.md`
- [ ] T079 [US6] Registrar `JuridicoInsightsModule` em `app.module.ts` com `@RequireLicenca('cedro')`
- [ ] T080 [P] [US6] Criar `ci-client-v2/apps/web/src/modules/juridico/api/insights.ts`
- [ ] T081 [US6] Implementar `JuridicoInsightsPage.tsx` + `InsightsTraceSheet.tsx` (título *De onde veio este insight?*)
- [ ] T082 [US6] Registrar override `juridico-insights` em `router.tsx`

**Checkpoint**: Insights reais; zero cards mock `jur-ins-001`

---

## Phase 9: User Story 7 — Maturidade Carvalho (Priority: P1)

**Goal**: Dashboard `/juridico/maturidade`; score híbrido; autoavaliação; planos ação; Nivo radar

**Independent Test**: VS-007 quickstart; CT-JUR-MAT-*

### Tests for User Story 7 (TDD — RED first)

- [ ] T083 [P] [US7] Escrever testes (RED) `compute-hybrid-score.spec.ts` em `ci-api-v2/src/modules/juridico-maturidade/lib/compute-hybrid-score.spec.ts` — CT-JUR-MAT-001
- [ ] T084 [P] [US7] Escrever testes (RED) `get-maturidade-dashboard.use-case.spec.ts` em `ci-api-v2/src/modules/juridico-maturidade/test/use-cases/`

### Schema maturidade

- [ ] T085 [US7] Criar `ci-api-v2/prisma/schema/juridico-maturidade.prisma` — Period, SelfAssessment, Score, ActionPlan; migration + seed perguntas Carvalho jurídico

### Implementation for User Story 7

- [ ] T086 [US7] Implementar score híbrido e indicadores operacionais jurídicos em `juridico-maturidade/lib/` (GREEN T083)
- [ ] T087 [US7] Implementar use-cases dashboard, self-assessment, action-plans CRUD
- [ ] T088 [US7] Expor `/juridico/maturidade/*` em `juridico-maturidade.controller.ts` conforme `contracts/rest-api-juridico-maturidade.md`
- [ ] T089 [US7] Registrar `JuridicoMaturidadeModule` em `app.module.ts` com `@RequireLicenca('carvalho')`
- [ ] T090 [P] [US7] Criar `ci-client-v2/apps/web/src/modules/juridico/api/maturidade.ts`
- [ ] T091 [US7] Implementar `JuridicoMaturidadePage.tsx` — radar Nivo, evolução temporal, planos ação
- [ ] T092 [US7] Registrar override `juridico-maturidade` em `router.tsx`

**Checkpoint**: Maturidade com score explicável via sheet *Como calculamos este score*

---

## Phase 10: User Story 8 — Rastreabilidade (Priority: P1)

**Goal**: Sheets canônicos Jatobá/Cedro/Carvalho (~85% viewport); fatores Probabilidade de Perda no trace

**Independent Test**: Títulos canônicos em fiscalização, insights e maturidade — SC-005 parcial

### Tests for User Story 8 (TDD — RED first)

- [ ] T093 [P] [US8] Escrever testes componente (RED) `FiscalizacaoTraceSheet.test.tsx` em `ci-client-v2/apps/web/src/modules/juridico/__tests__/` — títulos canônicos + fatores loss
- [ ] T094 [P] [US8] Escrever testes componente (RED) `MaturidadeScoreTraceSheet.test.tsx` e `InsightsTraceSheet.test.tsx` em `__tests__/`

### Implementation for User Story 8

- [ ] T095 [US8] Implementar `FiscalizacaoTraceSheet.tsx` com payloads API incl. `fatores` Probabilidade de Perda (GREEN T093)
- [ ] T096 [P] [US8] Garantir títulos sheet em `InsightsTraceSheet.tsx` e trace maturidade conforme `regras-plataforma.md` (GREEN T094)
- [ ] T097 [US8] Validar que nenhuma rota dedicada `/rastreio/*` foi criada — apenas Sheet

**Checkpoint**: 100% achados/insights/scores com trace via sheet

---

## Phase 11: User Story 9 — Governança e isolamento (Priority: P1)

**Goal**: 403 módulo/setor; licenças; tenant isolation; estados vazios sem mock fallback

**Independent Test**: VS-001 + VS-008 quickstart; CT-JUR-006

### Tests for User Story 9 (TDD — RED first)

- [ ] T098 [P] [US9] Escrever e2e (RED) `juridico.e2e-spec.ts` em `ci-api-v2/test/` — 403 MODULO_SETOR_DENIED, tenant isolation CT-JUR-006
- [ ] T099 [P] [US9] Escrever teste (RED) `license-guard-juridico.spec.ts` — rotas licença sem fallback mock

### Implementation for User Story 9

- [ ] T100 [US9] Auditar guards `@RequireModulo('juridico')` e `@RequireLicenca` em todos controllers jurídico* (GREEN T098)
- [ ] T101 [US9] Implementar empty states orientativos em pages jurídico (sem dados fabricados) — `JuridicoAuditoriaPage`, `JuridicoInsightsPage`, `JuridicoMaturidadePage`, `JuridicoDashboardPage`
- [ ] T102 [US9] Integrar `useModuleAccess('juridico')` e alertas licença em pages conforme `license-alerts.ts`

**Checkpoint**: Governança validada e2e; licença ausente → alerta, não mock

---

## Phase 12: Polish & Cross-Cutting

**Purpose**: Seed demo, exports client, quickstart, documentação CONTEXT

- [ ] T103 [P] Implementar `ci-api-v2/prisma/seed/seed-juridico-demo.ts` — ≥6 processos conforme `data-model.md` seed table; wire em `prisma/seed.ts`
- [ ] T104 [P] Criar barrel `ci-client-v2/apps/web/src/modules/juridico/index.ts` com lazy exports para router
- [ ] T105 Executar cenários VS-001–VS-008 de `quickstart.md` e corrigir gaps
- [ ] T106 [P] Atualizar vocabulário `LegalProcess` em `ci-api-v2/CONTEXT.md` (entrada Processo jurídico)
- [ ] T107 [P] Escrever teste integração (GREEN) `JuridicoProcessoWizardPage.integration.test.tsx` — CT-JUR-008 wizard 4 steps
- [ ] T108 Remover entradas `juridico-*` de `ci-client-v2/apps/web/src/modules/shell/data/mock-data.ts` usadas pelas rotas substituídas (ou guard flag `USE_MOCK` off)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Sem dependências
- **Foundational (Phase 2)**: Depende Phase 1 — **BLOQUEIA** todas as stories
- **US1 (Phase 3)**: Depende Phase 2 — **MVP**
- **US2 (Phase 4)**: Depende US1 (processo draft/confirm existe)
- **US3 (Phase 5)**: Depende US1; integra anexos US2 no detalhe
- **US4 (Phase 6)**: Depende US1; conformidade legal melhor após US5 (pode exibir 0 até lá)
- **US5 (Phase 7)**: Depende US1 (processos confirmados)
- **US6 (Phase 8)**: Depende US1; beneficia US5 (loss band nos agregadores)
- **US7 (Phase 9)**: Depende US5 (conformidade Jatobá no score híbrido)
- **US8 (Phase 10)**: Depende US5–US7 (sheets)
- **US9 (Phase 11)**: Paralelo após Phase 2; validação final após US5–US7
- **Polish (Phase 12)**: Depende stories desejadas completas

### User Story Dependency Graph

```text
Phase 2 (Foundation)
       │
       ▼
      US1 ──► US2
       │
       ├──► US3 ──► US4
       │
       └──► US5 ──► US6
              │
              └──► US7
                     │
         US8 ◄───────┘
         US9 (cross-cutting, finalize after US5+)
```

### Parallel Opportunities

- Phase 1: T001–T008 todos [P]
- Phase 2: T009–T011, T018, T022 [P] após T012 iniciado
- US5: T057–T059, T068, T072 [P] antes de T064
- US6 ∥ US7: após US5, equipes diferentes
- Polish: T103, T104, T106, T107 [P]

### Parallel Example: User Story 5

```bash
# Checks em paralelo (RED):
loss-probability.rules.spec.ts
deadline.rules.spec.ts
judicial-id.rules.spec.ts

# Client paralelo enquanto API GREEN:
api/fiscalizacao.ts + fixtures MSW
```

---

## Implementation Strategy

### MVP First (User Story 1 + 2 + 3)

1. Phase 1–2: Setup + Foundation
2. Phase 3–5: US1 wizard + US2 anexos + US3 lista/detalhe
3. **STOP**: VS-002 + VS-003 quickstart
4. Demo operacional Jurídico Base

### Incremental Delivery

1. Foundation → US1 → US2 → US3 (Base operacional)
2. US4 Dashboard
3. US5 Fiscalização + Probabilidade de Perda
4. US6 Cedro + US7 Carvalho (paralelo)
5. US8 Trace + US9 Governança + Polish

### Suggested MVP Scope

**US1 apenas** (Phase 3) após Foundation — confirm processo com número interno, sem anexos nem lista dedicada ainda.  
**MVP produto**: US1 + US2 + US3 (wizard completo + fila + detalhe).

---

## Notes

- Total tasks: **108** (T001–T108)
- US1: 11 tasks | US2: 7 | US3: 10 | US4: 6 | US5: 16 | US6: 10 | US7: 10 | US8: 5 | US9: 5 | Setup 8 | Foundation 14 | Polish 6
- Todos os tasks incluem caminho de arquivo explícito
- Commit após cada checkpoint de user story
- `/speckit-implement` segue ordem T001→T108
