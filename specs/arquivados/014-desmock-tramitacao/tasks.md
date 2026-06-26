---
description: "Task list for Desmock Tramitação (014-desmock-tramitacao)"
---

# Tasks: Desmock Tramitação — Inbox, Linked Records e Licenças

**Input**: Design documents from `civ2-docs/specs/014-desmock-tramitacao/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Tests**: **Obrigatórios** — TDD (constitution II + plan.md + `contracts/test-strategy.md`): unitário, componente, contrato, integração (mocks/in-memory) e E2E. **Sem Postgres de teste dedicado**.

**Organization**: 11 user stories (US1–US11). Caminhos relativos à raiz `ci-v2/`.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Pode executar em paralelo (arquivos diferentes, sem dependências pendentes)
- **[Story]**: User story da spec (US1–US11)

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Scaffolding módulos API/client, fixtures, MSW

- [X] T001 [P] Criar esqueleto `ci-api-v2/src/modules/tramitacao/` com pastas `repository/`, `use-cases/`, `lib/`, `test/`
- [X] T002 [P] Criar esqueleto `ci-api-v2/src/modules/tramitacao-fiscalizacao/` espelhando `gabinete-fiscalizacao/` (`lib/checks/`, `repository/`, `use-cases/`, `jobs/`, `test/`)
- [X] T003 [P] Criar esqueleto `ci-api-v2/src/modules/tramitacao-insights/` espelhando `gabinete-insights/`
- [X] T004 [P] Criar esqueleto `ci-api-v2/src/modules/tramitacao-maturidade/` espelhando `gabinete-maturidade/`
- [X] T005 [P] Criar esqueleto client `ci-client-v2/apps/web/src/modules/tramitacao/` com `api/`, `pages/`, `components/`, `fixtures/`, `__tests__/`
- [X] T006 [P] Criar fixtures vazias `ci-client-v2/apps/web/src/modules/tramitacao/fixtures/inbox-empty.json` e `demanda-detail-empty.json`
- [X] T007 [P] Adicionar handlers MSW stub em `ci-client-v2/apps/web/src/test/msw/handlers/tramitacao.ts` e registrar em `ci-client-v2/apps/web/src/test/msw/handlers.ts`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Schema Base, módulo registrado, protocolo TRAM, linked record use-case — **bloqueia todas as user stories**

**⚠️ CRITICAL**: Nenhuma user story começa antes desta fase

### Tests first (TDD — RED)

- [X] T008 [P] Escrever testes (RED) `generate-protocol-number.spec.ts` em `ci-api-v2/src/modules/tramitacao/test/lib/generate-protocol-number.spec.ts` — CT-TRAM-002
- [X] T009 [P] Escrever testes (RED) `tramitacao.schemas.spec.ts` em `ci-api-v2/src/modules/tramitacao/tramitacao.schemas.spec.ts` — validação compose (subject+body+targetSector)
- [X] T010 [P] Escrever testes (RED) `inbox-folder-filter.spec.ts` em `ci-api-v2/src/modules/tramitacao/test/lib/inbox-folder-filter.spec.ts` — CT-TRAM-003
- [X] T011 [P] Escrever testes (RED) `create-linked-demanda.use-case.spec.ts` em `ci-api-v2/src/modules/tramitacao/test/use-cases/create-linked-demanda.use-case.spec.ts`

### Schema & migration (Base)

- [X] T012 Criar enums em `ci-api-v2/prisma/schema/tramitacao.prisma` — `TramitacaoDemandaOriginType`, `TramitacaoDemandaStatus`, `TramitacaoDemandaEventType` conforme `data-model.md`
- [X] T013 Criar modelos Base em `ci-api-v2/prisma/schema/tramitacao.prisma` — `TramitacaoDemanda`, `TramitacaoDemandaSequence`, `TramitacaoDemandaEvento`, `TramitacaoDemandaAnexo`
- [X] T014 Registrar schema em `ci-api-v2/prisma/schema/schema.prisma`, relações em `ci-api-v2/prisma/schema/tenant.prisma` e gerar migration (`npx prisma migrate dev`)

### Module registration & libs

- [X] T015 Implementar Zod DTOs base em `ci-api-v2/src/modules/tramitacao/tramitacao.schemas.ts` (GREEN T009)
- [X] T016 [P] Implementar `generate-protocol-number.ts` em `ci-api-v2/src/modules/tramitacao/lib/generate-protocol-number.ts` (GREEN T008)
- [X] T017 [P] Implementar `inbox-folder-filter.ts` em `ci-api-v2/src/modules/tramitacao/lib/inbox-folder-filter.ts` (GREEN T010)
- [X] T018 [P] Criar repositórios stub — `allocate-protocol-number.repository.ts`, `create-demanda.repository.ts` em `ci-api-v2/src/modules/tramitacao/repository/` + specs mock Prisma
- [X] T019 Implementar `create-linked-demanda.use-case.ts` em `ci-api-v2/src/modules/tramitacao/use-cases/create-linked-demanda.use-case.ts` (GREEN T011) — snapshot imutável
- [X] T020 Registrar `TramitacaoModule` em `ci-api-v2/src/app.module.ts` exportando `CreateLinkedDemandaUseCase` para integrações
- [X] T021 [P] Criar `tramitacao.mapper.ts` em `ci-api-v2/src/modules/tramitacao/tramitacao.mapper.ts` — labels PT-BR, origin badges
- [X] T022 [P] Seed demo em `ci-api-v2/prisma/seed/seed-tramitacao-demo.ts` — demandas genéricas + linked (gabinete/ouvidoria/juridico); registrar em `ci-api-v2/prisma/seed.ts`

**Checkpoint**: Migration Base aplicada; TramitacaoModule registrado; libs GREEN; seed com inbox populada

---

## Phase 3: User Story 1 — Compor e receber demandas na inbox (Priority: P1) 🎯 MVP

**Goal**: Inbox Recebidas/Enviadas/Arquivadas por setor ativo; compor demanda genérica; listar linked records do seed

**Independent Test**: VS-001, VS-002 quickstart — POST genérica; pastas inbox; protocolo TRAM-AAAA-NNNN

### Tests for User Story 1 (TDD — RED first)

- [X] T023 [P] [US1] Escrever testes (RED) `create-generic-demanda.use-case.spec.ts`
- [ ] T024 [P] [US1] Escrever testes (RED) `list-inbox.use-case.spec.ts`
- [ ] T025 [P] [US1] Escrever teste contrato (RED) `tramitacao.contract.spec.ts`

### Implementation for User Story 1

- [X] T026 [US1] Implementar `create-generic-demanda.use-case.ts`
- [X] T027 [US1] Implementar `list-inbox.use-case.ts` e `list-inbox.repository.ts`
- [X] T028 [US1] Expor GET/POST `/tramitacao/demandas` em `tramitacao.controller.ts`
- [X] T029 [P] [US1] Criar API client `demandas.ts`
- [X] T030 [US1] Implementar `TramitacaoInboxPage.tsx`
- [ ] T031 [P] [US1] Implementar `InboxList.tsx` e `InboxFolderTabs.tsx` (inline na page v1)
- [X] T032 [US1] Implementar `TramitacaoComposePage.tsx`
- [X] T033 [US1] Registrar rotas em `router.tsx`

**Checkpoint**: Inbox real + composição genérica end-to-end (API + UI)

---

## Phase 4: User Story 2 — Tramitar registro via linked record (Priority: P1)

**Goal**: Detalhe exibe linked record + snapshot; validação snapshot imutável; badge módulo origem

**Independent Test**: VS-003 quickstart — GET demanda linked com snapshot; alterar origem não altera snapshot

### Tests for User Story 2 (TDD — RED first)

- [ ] T034 [P] [US2] Escrever testes (RED) `get-demanda-detail.use-case.spec.ts` em `ci-api-v2/src/modules/tramitacao/test/use-cases/get-demanda-detail.use-case.spec.ts`
- [ ] T035 [P] [US2] Escrever testes (RED) `source-snapshot-immutable.spec.ts` em `ci-api-v2/src/modules/tramitacao/test/lib/source-snapshot-immutable.spec.ts` — CT-TRAM-004

### Implementation for User Story 2

- [X] T036 [US2] Implementar `get-demanda-detail.use-case.ts`
- [X] T037 [US2] Expor GET `/tramitacao/demandas/:id`
- [ ] T038 [P] [US2] Implementar `LinkedRecordPanel.tsx` (snapshot inline na page v1)
- [X] T039 [US2] Implementar `TramitacaoDemandaDetailPage.tsx`
- [X] T040 [US2] Registrar rota `/tramitacao/demandas/:id`

**Checkpoint**: Linked record visível no detalhe; snapshot imutável verificado

---

## Phase 5: User Story 3 — Responder, encaminhar e arquivar (Priority: P1)

**Goal**: Thread respostas; encaminhar inter-setorial; arquivar; timeline completa

**Independent Test**: VS-004 quickstart — reply, forward, archive; histórico preservado

### Tests for User Story 3 (TDD — RED first)

- [ ] T041 [P] [US3] Escrever testes (RED) `reply-demanda.use-case.spec.ts` em `ci-api-v2/src/modules/tramitacao/test/use-cases/reply-demanda.use-case.spec.ts`
- [ ] T042 [P] [US3] Escrever testes (RED) `forward-demanda.use-case.spec.ts` em `ci-api-v2/src/modules/tramitacao/test/use-cases/forward-demanda.use-case.spec.ts` — CT-TRAM-005
- [ ] T043 [P] [US3] Escrever testes (RED) `archive-demanda.use-case.spec.ts` em `ci-api-v2/src/modules/tramitacao/test/use-cases/archive-demanda.use-case.spec.ts` — CT-TRAM-006

### Implementation for User Story 3

- [X] T044 [US3] Implementar `reply-demanda.use-case.ts`
- [X] T045 [US3] Implementar `forward-demanda.use-case.ts`
- [X] T046 [US3] Implementar `archive-demanda.use-case.ts`
- [X] T047 [US3] Expor POST `/reply`, `/forward`, `/archive`
- [ ] T048 [P] [US3] Implementar `DemandaThread.tsx` (timeline inline na page v1)
- [ ] T049 [P] [US3] Implementar `ForwardDemandaDialog.tsx` (inline na page v1)
- [X] T050 [US3] Integrar ações reply/forward/archive em `TramitacaoDemandaDetailPage.tsx`

**Checkpoint**: Thread operacional completa; encaminhamento preserva histórico (SC-010)

---

## Phase 6: User Story 4 — Dashboard consolidado (Priority: P1)

**Goal**: KPIs reais volume, pendentes, resolutividade, bySourceModule; filtros período/setor

**Independent Test**: VS-005 quickstart — GET dashboard + gráfico client

### Tests for User Story 4 (TDD — RED first)

- [X] T051 [P] [US4] Escrever testes (RED) `get-dashboard.use-case.spec.ts` em `ci-api-v2/src/modules/tramitacao/test/use-cases/get-dashboard.use-case.spec.ts`

### Implementation for User Story 4

- [X] T052 [US4] Implementar `get-dashboard.use-case.ts` e `get-dashboard.repository.ts` (GREEN T051)
- [X] T053 [US4] Expor GET `/tramitacao/dashboard` em `tramitacao.controller.ts`
- [X] T054 [P] [US4] Criar `ci-client-v2/apps/web/src/modules/tramitacao/api/dashboard.ts`
- [X] T055 [US4] Implementar `TramitacaoDashboardPage.tsx` — KPI cards + Nivo donut `bySourceModule`
- [X] T056 [US4] Registrar rota `/tramitacao/dashboard` em router client

**Checkpoint**: Dashboard com dados API reais

---

## Phase 7: User Story 5 — Fiscalização Jatobá (Priority: P1)

**Goal**: Checagens SLA, completude, encaminhamento pendente; panel + histórico execuções

**Independent Test**: VS-006 quickstart — demanda prazo vencido → achado non_conforme

### Tests for User Story 5 (TDD — RED first)

- [ ] T057 [P] [US5] Escrever testes (RED) `sla-deadline.rules.spec.ts` em `ci-api-v2/src/modules/tramitacao-fiscalizacao/test/lib/checks/sla-deadline.rules.spec.ts` — CT-TRAM-FIS-001
- [ ] T058 [P] [US5] Escrever testes (RED) `completeness.rules.spec.ts` e `forwarding-pending.rules.spec.ts` em `ci-api-v2/src/modules/tramitacao-fiscalizacao/test/lib/checks/`
- [ ] T059 [P] [US5] Escrever testes (RED) `aggregate-conformity.spec.ts` em `ci-api-v2/src/modules/tramitacao-fiscalizacao/test/lib/aggregate-conformity.spec.ts` — CT-TRAM-FIS-003

### Schema & module

- [ ] T060 [US5] Criar `ci-api-v2/prisma/schema/tramitacao-fiscalizacao.prisma` — Run, Result, Check, Finding, Question, Questionnaire, Answer; migration
- [ ] T061 [P] [US5] Seed perguntas em `ci-api-v2/prisma/seed/seed-fiscalizacao-questions-tramitacao.ts`

### Implementation for User Story 5

- [ ] T062 [US5] Implementar rules em `ci-api-v2/src/modules/tramitacao-fiscalizacao/lib/checks/` (GREEN T057–T059)
- [ ] T063 [US5] Implementar run/panel use-cases espelhando `gabinete-fiscalizacao/` em `tramitacao-fiscalizacao/use-cases/`
- [ ] T064 [US5] Registrar `TramitacaoFiscalizacaoModule` em `app.module.ts`; controller com `@RequireLicenca('jatoba')`
- [ ] T065 [P] [US5] Criar `ci-client-v2/apps/web/src/modules/tramitacao/api/fiscalizacao.ts`
- [ ] T066 [US5] Implementar `TramitacaoAuditoriaPage.tsx` clone adaptado de `GabineteAuditoriaPage.tsx`
- [ ] T067 [US5] Registrar rota `/tramitacao/auditoria` em router client

**Checkpoint**: Fiscalização Jatobá operacional read-only

---

## Phase 8: User Story 6 — Insights Cedro (Priority: P1)

**Goal**: Gargalos setores, volume por módulo, tendências temporais determinísticas

**Independent Test**: VS-007 quickstart — insights determinísticos reprodutíveis

### Tests for User Story 6 (TDD — RED first)

- [ ] T068 [P] [US6] Escrever testes (RED) `bottleneck-sectors.rules.spec.ts` e `volume-by-module.rules.spec.ts` em `ci-api-v2/src/modules/tramitacao-insights/test/lib/aggregation/` — CT-TRAM-INS-001, CT-TRAM-INS-002

### Schema & implementation

- [ ] T069 [US6] Criar `ci-api-v2/prisma/schema/tramitacao-insights.prisma` — Batch, Insight, Evidence; migration
- [ ] T070 [US6] Implementar aggregation rules e run use-cases em `tramitacao-insights/`
- [ ] T071 [US6] Registrar `TramitacaoInsightsModule` com `@RequireLicenca('cedro')`
- [ ] T072 [P] [US6] Criar `ci-client-v2/apps/web/src/modules/tramitacao/api/insights.ts`
- [ ] T073 [US6] Implementar `TramitacaoInsightsPage.tsx` — gargalos + volume módulo + série temporal
- [ ] T074 [US6] Registrar rota `/tramitacao/insights` em router client

**Checkpoint**: Insights Cedro read-only operacional

---

## Phase 9: User Story 7 — Maturidade Carvalho (Priority: P1)

**Goal**: Score híbrido 60/40, radar eixos, planos de ação

**Independent Test**: VS-008 quickstart — autoavaliação + score hybrid

### Tests for User Story 7 (TDD — RED first)

- [ ] T075 [P] [US7] Escrever testes (RED) `hybrid-score.spec.ts` em `ci-api-v2/src/modules/tramitacao-maturidade/test/lib/hybrid-score.spec.ts` — CT-TRAM-MAT-001

### Schema & implementation

- [ ] T076 [US7] Criar `ci-api-v2/prisma/schema/tramitacao-maturidade.prisma` — Period, Question, SelfAssessment, Score, ActionPlan; migration
- [ ] T077 [P] [US7] Seed perguntas em `ci-api-v2/prisma/seed/seed-maturidade-questions-tramitacao.ts`
- [ ] T078 [US7] Implementar use-cases maturidade espelhando `gabinete-maturidade/` (GREEN T075)
- [ ] T079 [US7] Registrar `TramitacaoMaturidadeModule` com `@RequireLicenca('carvalho')`
- [ ] T080 [P] [US7] Criar `ci-client-v2/apps/web/src/modules/tramitacao/api/maturidade.ts`
- [ ] T081 [US7] Implementar `TramitacaoMaturidadePage.tsx` — radar + planos de ação
- [ ] T082 [US7] Registrar rota `/tramitacao/maturidade` em router client

**Checkpoint**: Maturidade Carvalho operacional

---

## Phase 10: User Story 8 — Alertas de licença na inbox (Priority: P2)

**Goal**: Barra alertas canônica; sheets bloqueio licença; rastreabilidade real

**Independent Test**: VS-009 quickstart — Base only → alertas upgrade

### Implementation for User Story 8

- [ ] T083 [P] [US8] Integrar `ListLicenseAlertBar` em `TramitacaoInboxPage.tsx` com `getModuleLicenseTraffic('tramitacao')`
- [ ] T084 [US8] Adicionar sheets licença bloqueada em páginas auditoria/insights/maturidade em `ci-client-v2/apps/web/src/modules/tramitacao/pages/`
- [ ] T085 [P] [US8] Atualizar `ci-client-v2/apps/web/src/modules/shell/config/navigation.ts` — `licenseNav('tramitacao')` + Fiscalização
- [ ] T086 [US8] Remover entradas mock tramitacao de `ci-client-v2/apps/web/src/modules/shell/data/traceability-mock.ts`; usar rastreabilidade canônica licenças

**Checkpoint**: Alertas e bloqueios licença conformes regras-plataforma

---

## Phase 11: User Story 9 — Integração Gabinete → Tramitação (Priority: P2)

**Goal**: Ação Tramitar no gabinete cria demanda tramitacao com linked record

**Independent Test**: VS-003 quickstart — forward gabinete → demanda tramitacao

### Tests for User Story 9 (TDD — RED first)

- [X] T087 [P] [US9] Escrever teste integração (RED) `gabinete-forward-tramitacao.spec.ts` em `ci-api-v2/src/modules/gabinete/test/use-cases/forward-cabinet-tramitacao.integration.spec.ts` — CT-TRAM-009

### Implementation for User Story 9

- [X] T088 [US9] Implementar mapper snapshot gabinete em `ci-api-v2/src/modules/gabinete/lib/cabinet-tramitacao-snapshot.mapper.ts`
- [X] T089 [US9] Refatorar `forward-demanda.use-case.ts` (ou `forward-cabinet.use-case.ts`) em `gabinete/` para chamar `CreateLinkedDemandaUseCase` (GREEN T087)
- [X] T090 [US9] Importar `TramitacaoModule` em `gabinete.module.ts`
- [X] T091 [P] [US9] Atualizar `ForwardDemandaDialog.tsx` em `gabinete/components/` — toast + link "Ver na Tramitação"

**Checkpoint**: Gabinete → Tramitação end-to-end

---

## Phase 12: User Story 10 — Integração Ouvidoria → Tramitação (Priority: P2)

**Goal**: Encaminhar setor na manifestação cria demanda tramitacao

**Independent Test**: VS-010 quickstart

### Tests for User Story 10 (TDD — RED first)

- [X] T092 [P] [US10] Escrever teste integração (RED) `encaminhar-manifestacao-tramitacao.spec.ts` em `ci-api-v2/src/modules/ouvidoria/test/use-cases/`

### Implementation for User Story 10

- [X] T093 [US10] Implementar mapper snapshot em `ci-api-v2/src/modules/ouvidoria/lib/manifestacao-tramitacao-snapshot.mapper.ts`
- [X] T094 [US10] Refatorar `encaminhar-manifestacao.use-case.ts` para chamar `CreateLinkedDemandaUseCase` (GREEN T092)
- [X] T095 [US10] Importar `TramitacaoModule` em `ouvidoria.module.ts`
- [X] T096 [P] [US10] Atualizar UI encaminhar em `ci-client-v2/apps/web/src/modules/ouvidoria/` — link tramitacao

**Checkpoint**: Ouvidoria → Tramitação end-to-end

---

## Phase 13: User Story 11 — Integração Jurídico → Tramitação (Priority: P2)

**Goal**: Tramitar processo jurídico cria demanda tramitacao

**Independent Test**: VS-011 quickstart

### Tests for User Story 11 (TDD — RED first)

- [X] T097 [P] [US11] Escrever teste integração (RED) `tramitar-processo-tramitacao.spec.ts` em `ci-api-v2/src/modules/juridico/test/use-cases/`

### Implementation for User Story 11

- [X] T098 [US11] Implementar mapper snapshot em `ci-api-v2/src/modules/juridico/lib/process-tramitacao-snapshot.mapper.ts`
- [X] T099 [US11] Implementar `tramitar-processo.use-case.ts` em `juridico/use-cases/` chamando `CreateLinkedDemandaUseCase` (GREEN T097)
- [X] T100 [US11] Expor POST `/juridico/processos/:id/tramitar` em `juridico.controller.ts`; importar `TramitacaoModule`
- [ ] T101 [P] [US11] Adicionar ação Tramitar na UI detalhe processo em `ci-client-v2/apps/web/src/modules/juridico/`

**Checkpoint**: Jurídico → Tramitação end-to-end; trio integrações completo

---

## Phase 14: Polish & Cross-Cutting Concerns

**Purpose**: Anexos, desmock shell, e2e, produto, validação final

### Anexos Wasabi (cross-cutting Base)

- [ ] T102 [P] Escrever testes (RED) `presign-anexo.use-case.spec.ts` em `ci-api-v2/src/modules/tramitacao/test/use-cases/`
- [ ] T103 Implementar `presign-anexo.use-case.ts` e `confirm-anexo.use-case.ts` em `tramitacao/use-cases/` (reuso `StorageModule`)
- [ ] T104 Expor rotas anexos presign/confirm em `tramitacao.controller.ts`

### Desmock client shell

- [ ] T105 Remover render mock `tramitacao-*` de `ci-client-v2/apps/web/src/modules/shell/pages/ScreenPage.tsx` (ou equivalente)
- [ ] T106 [P] Remover `ci-client-v2/apps/web/src/modules/shell/data/tramitacao-mock.ts` e `TramitacaoInboxPanel.tsx` após paridade
- [ ] T107 [P] Limpar entradas tramitacao mock em `ci-client-v2/apps/web/src/modules/shell/data/mock-data.ts` e `tramitacao-status.ts`
- [ ] T108 Atualizar `ci-client-v2/apps/web/src/modules/shell/config/screens.ts` — metadados tramitacao apontando a módulo real

### E2E & validação

- [ ] T109 Implementar `ci-api-v2/test/tramitacao.e2e-spec.ts` — CT-TRAM-007, CT-TRAM-008, edge cases VS-012
- [ ] T110 [P] Completar MSW handlers em `tramitacao.ts` para journeys client Vitest
- [ ] T111 Executar quickstart VS-001…VS-012 em `civ2-docs/specs/014-desmock-tramitacao/quickstart.md`
- [ ] T112 [P] Atualizar seção Tramitação em `.cursor/docs/licencas-canonicas.md` — Base inbox + licenças Jatobá/Cedro/Carvalho
- [ ] T113 [P] Criar `civ2-docs/specs/014-desmock-tramitacao/STATUS.md` com checklist de entrega

**Checkpoint**: Zero mock shell ativo; testes verdes; quickstart passando

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Sem dependências
- **Foundational (Phase 2)**: Depende Setup — **BLOQUEIA** todas user stories
- **US1–US4 (Phases 3–6)**: Dependem Foundational; sequência US1 → US2 → US3 recomendada; US4 paralelo após US1
- **US5–US7 (Phases 7–9)**: Dependem Foundational + demandas seed; paralelos entre si após US1
- **US8 (Phase 10)**: Depende client tramitacao pages existentes
- **US9–US11 (Phases 11–13)**: Dependem `CreateLinkedDemandaUseCase` (Phase 2) + US2 detalhe; paralelos entre si
- **Polish (Phase 14)**: Depende stories desejadas completas

### User Story Dependencies

| Story | Depende de | Independente quando |
|-------|------------|---------------------|
| US1 | Phase 2 | Inbox + compose genérica |
| US2 | US1 list/detail routes | Snapshot panel no detalhe |
| US3 | US2 detalhe | Reply/forward/archive |
| US4 | US1 dados | Dashboard KPIs |
| US5 | US1 demandas | Fiscalização runs |
| US6 | US1 demandas | Insights batches |
| US7 | US5 runs (score 40%) | Maturidade híbrida |
| US8 | US1–US7 pages | Alertas licença |
| US9 | Phase 2 linked use-case | Gabinete forward |
| US10 | Phase 2 linked use-case | Ouvidoria encaminhar |
| US11 | Phase 2 linked use-case | Jurídico tramitar |

### Parallel Opportunities

- **Phase 1**: T001–T007 todos [P]
- **Phase 2**: T008–T011, T016–T018, T021–T022 [P] após T012–T014
- **US5 / US6 / US7**: Fases 7–9 em paralelo (módulos API distintos)
- **US9 / US10 / US11**: Fases 11–13 em paralelo após Phase 2
- **Polish**: T106–T107, T110–T113 [P]

---

## Parallel Example: User Story 1

```bash
# Testes RED em paralelo:
T023 create-generic-demanda.use-case.spec.ts
T024 list-inbox.use-case.spec.ts
T025 tramitacao.contract.spec.ts

# Client em paralelo após API GREEN:
T029 api/demandas.ts
T031 InboxList.tsx + InboxFolderTabs.tsx
```

---

## Parallel Example: Integrações (US9–US11)

```bash
# Após Phase 2 completa — três devs em paralelo:
Developer A: T087–T091 Gabinete forward
Developer B: T092–T096 Ouvidoria encaminhar
Developer C: T097–T101 Jurídico tramitar
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Phase 1: Setup
2. Phase 2: Foundational
3. Phase 3: US1 — inbox + compose
4. **STOP e VALIDAR**: VS-001, VS-002 quickstart

### Incremental Delivery (P1 core)

1. Setup + Foundational
2. US1 + US2 + US3 → inbox operacional completa
3. US4 → dashboard
4. US5 + US6 + US7 → licenças (paralelo)
5. US8 → alertas
6. US9 + US10 + US11 → integrações (paralelo)
7. Polish → desmock shell + quickstart

### Suggested MVP Scope

**MVP mínimo**: Phase 1 + 2 + US1 (T001–T033) — inbox com composição genérica e pastas.

**MVP operacional**: até US3 (T001–T050) — thread completa sem licenças.

**Release v1**: todas P1 (US1–US7) + integrações P2 (US9–US11) + Polish.

---

## Notes

- Constitution II: sempre RED antes de implementação
- `tramitacao` é `OPEN_MODULES` — CT-TRAM-008 valida acesso sem vínculo setor específico
- Não reintroduzir mock SIGED — fora de escopo v1
- Pau-Brasil operacional fora de escopo — não criar tasks
- Commit após cada checkpoint ou grupo lógico de tasks
