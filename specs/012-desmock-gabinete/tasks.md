---
description: "Task list for Desmock Gabinete (012-desmock-gabinete)"
---

# Tasks: Desmock Gabinete — Demandas, Protocolos e Licenças

**Input**: Design documents from `civ2-docs/specs/012-desmock-gabinete/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Tests**: **Obrigatórios** — TDD (constitution II + plan.md + `contracts/test-strategy.md`): unitário, componente, contrato, integração (mocks/in-memory) e E2E. **Sem Postgres de teste dedicado**.

**Organization**: 12 user stories P1 (US1–US12). Caminhos relativos à raiz `ci-v2/`.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Pode executar em paralelo (arquivos diferentes, sem dependências pendentes)
- **[Story]**: User story da spec (US1–US12)

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Scaffolding módulos, fixtures, MSW, env Wasabi

- [X] T001 [P] Documentar vars Wasabi em `ci-api-v2/.env.example` se ausentes (reuso 003-ouvidoria)
- [X] T002 [P] Criar esqueleto `ci-api-v2/src/modules/gabinete/` com pastas `repository/`, `use-cases/`, `use-cases/controles/`, `test/`
- [X] T003 [P] Criar esqueleto `ci-api-v2/src/modules/gabinete-fiscalizacao/` espelhando `ouvidoria-fiscalizacao/` (lib/checks/, repository/, use-cases/, jobs/, test/)
- [X] T004 [P] Criar esqueleto `ci-api-v2/src/modules/gabinete-maturidade/` espelhando `ouvidoria-maturidade/`
- [X] T005 [P] Criar esqueleto `ci-api-v2/src/modules/gabinete-insights/` espelhando `ouvidoria-insights/`
- [X] T006 [P] Criar esqueleto client `ci-client-v2/apps/web/src/modules/gabinete/` com `api/`, `pages/`, `components/`, `fixtures/`, `__tests__/`
- [X] T007 [P] Criar fixtures client vazias `ci-client-v2/apps/web/src/modules/gabinete/fixtures/demanda-detail-empty.json` e `fiscalizacao-panel-empty.json`
- [X] T008 [P] Adicionar handlers MSW stub em `ci-client-v2/apps/web/src/test/msw/handlers/gabinete.ts` e registrar em `ci-client-v2/apps/web/src/test/msw/handlers.ts`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Schema Base, Storage compartilhado, módulo registrado — **bloqueia todas as user stories**

**⚠️ CRITICAL**: Nenhuma user story começa antes desta fase

### Tests first (TDD — RED)

- [X] T009 [P] Escrever testes (RED) `generate-protocol-number.spec.ts` em `ci-api-v2/src/modules/gabinete/test/lib/generate-protocol-number.spec.ts` — CT-GAB-002
- [X] T010 [P] Escrever testes (RED) `gabinete.schemas.spec.ts` em `ci-api-v2/src/modules/gabinete/gabinete.schemas.spec.ts` — validação CreateDemanda (subject+description obrigatórios)

### Schema & migration (Base)

- [X] T011 Criar enums Gabinete em `ci-api-v2/prisma/schema/gabinete.prisma` — EntryMode, DemandaOrigin, DemandaSector, DemandaStatus, ControleNumericoTipo, EventType conforme `data-model.md`
- [X] T012 Criar modelos Base em `ci-api-v2/prisma/schema/gabinete.prisma` — CabinetProtocolo, CabinetDemanda, CabinetDemandaSequence, CabinetDemandaEvento, CabinetDemandaAnexo, CabinetProtocoloAnexo
- [X] T013 Registrar schema em `ci-api-v2/prisma/schema/schema.prisma`, relações em `ci-api-v2/prisma/schema/tenant.prisma` e gerar migration (`npx prisma migrate dev`)

### Storage compartilhado (R4)

- [X] T014 Extrair `StorageService` para `ci-api-v2/src/modules/shared/storage/storage.service.ts` e `storage.module.ts` a partir de `ci-api-v2/src/modules/ouvidoria/services/storage.service.ts`
- [X] T015 Refatorar `ci-api-v2/src/modules/ouvidoria/ouvidoria.module.ts` para importar `StorageModule` shared; rodar testes ouvidoria existentes (regressão)

### Module registration

- [X] T016 Implementar Zod DTOs base em `ci-api-v2/src/modules/gabinete/gabinete.schemas.ts` (GREEN T010)
- [X] T017 [P] Implementar `generate-protocol-number.ts` em `ci-api-v2/src/modules/gabinete/lib/generate-protocol-number.ts` (GREEN T009)
- [X] T018 [P] Criar repositórios stub — `allocate-protocol-number.repository.ts`, `create-demanda.repository.ts` em `ci-api-v2/src/modules/gabinete/repository/` + specs mock Prisma
- [X] T019 Registrar `GabineteModule` em `ci-api-v2/src/app.module.ts` com `@RequireModulo('gabinete')` no controller stub
- [X] T020 [P] Garantir vínculo módulo↔setor Gabinete em `ci-api-v2/prisma/seed/seed-jacaranda-tenant.ts` (ModuloSlug.gabinete)

**Checkpoint**: Migration Base aplicada; Storage shared; GabineteModule registrado; libs GREEN

---

## Phase 3: User Story 1 — Registrar demanda com protocolo e anexos (Priority: P1) 🎯 MVP

**Goal**: POST demanda com assunto+descrição, protocolo opcional, anexos Wasabi, protocolNumber gerado

**Independent Test**: VS-002 quickstart — POST demanda + presign/confirm anexo; client `/gabinete/demandas/novo`

### Tests for User Story 1 (TDD — RED first)

- [X] T021 [P] [US1] Escrever testes (RED) `create-demanda.use-case.spec.ts` em `ci-api-v2/src/modules/gabinete/test/use-cases/create-demanda.use-case.spec.ts` — CT-GAB-001
- [X] T022 [P] [US1] Escrever testes (RED) `presign-demanda-anexo.use-case.spec.ts` em `ci-api-v2/src/modules/gabinete/test/use-cases/presign-demanda-anexo.use-case.spec.ts`
- [X] T023 [P] [US1] Escrever teste contrato (RED) `gabinete.contract.spec.ts` em `ci-api-v2/src/modules/gabinete/test/gabinete.contract.spec.ts` — POST `/gabinete/demandas`

### Implementation for User Story 1

- [X] T024 [US1] Implementar `create-demanda.use-case.ts` em `ci-api-v2/src/modules/gabinete/use-cases/create-demanda.use-case.ts` (GREEN T021)
- [X] T025 [P] [US1] Implementar repositórios protocolo — `create-protocolo.repository.ts`, `link-protocolo-demanda.repository.ts` em `ci-api-v2/src/modules/gabinete/repository/`
- [X] T026 [P] [US1] Implementar `presign-demanda-anexo.use-case.ts` e `confirm-demanda-anexo.use-case.ts` em `ci-api-v2/src/modules/gabinete/use-cases/` (GREEN T022)
- [X] T027 [P] [US1] Implementar presign/confirm protocolo anexo — `presign-protocolo-anexo.use-case.ts`, `confirm-protocolo-anexo.use-case.ts`
- [X] T028 [US1] Expor rotas POST `/gabinete/cabinets` (alias `/demandas`) e anexos em `gabinete.controller.ts`
- [X] T029 [P] [US1] Criar API client `ci-client-v2/apps/web/src/modules/gabinete/api/cabinets.ts` — create, presign, confirm
- [X] T030 [US1] Implementar `GabineteDemandaCreatePage.tsx` e `DemandaForm.tsx` em `ci-client-v2/apps/web/src/modules/gabinete/pages/` e `components/` — seções demanda, protocolo opcional, anexos
- [X] T031 [US1] Registrar rota lazy `/gabinete/demandas/novo` em `ci-client-v2/apps/web/src/App.tsx` (ou router equivalente)

**Checkpoint**: Criar demanda + anexo end-to-end (API + UI)

---

## Phase 4: User Story 2 — Listar e filtrar demandas (Priority: P1)

**Goal**: GET lista paginada com filtros status/origem/setor e busca q

**Independent Test**: VS-003 quickstart — filtros e zero linhas mock

### Tests for User Story 2 (TDD — RED first)

- [X] T032 [P] [US2] Escrever testes (RED) `list-demandas.use-case.spec.ts` em `ci-api-v2/src/modules/gabinete/test/use-cases/list-demandas.use-case.spec.ts`
- [X] T033 [P] [US2] Escrever teste componente (RED) `GabineteDemandasListPage.test.tsx` em `ci-client-v2/apps/web/src/modules/gabinete/__tests__/GabineteDemandasListPage.test.tsx` — CT-GAB-007 empty state

### Implementation for User Story 2

- [X] T034 [US2] Implementar `list-demandas.repository.ts` e `list-demandas.use-case.ts` com filtros e badge operacional derivado (GREEN T032)
- [X] T035 [US2] Expor GET `/gabinete/demandas` em `ci-api-v2/src/modules/gabinete/gabinete.controller.ts`
- [X] T036 [P] [US2] Estender `ci-client-v2/apps/web/src/modules/gabinete/api/demandas.ts` — list com query params
- [X] T037 [US2] Implementar `GabineteDemandasListPage.tsx` com DataTable shadcn, filtros e empty state
- [X] T038 [US2] Registrar rota `/gabinete/demandas` e redirect `/gabinete/atos` → `/gabinete/demandas` em router client

**Checkpoint**: Lista real substitui mock `gabinete-lista`

---

## Phase 5: User Story 3 — Detalhe, edição e linha do tempo (Priority: P1)

**Goal**: GET/PATCH detalhe, timeline eventos, abas controles (shell vazias)

**Independent Test**: VS-003 detalhe — protocolo, timeline, tabs

### Tests for User Story 3 (TDD — RED first)

- [ ] T039 [P] [US3] Escrever testes (RED) `get-cabinet-detail.use-case.spec.ts` e `update-cabinet.use-case.spec.ts` em `ci-api-v2/src/modules/gabinete/test/use-cases/`
- [X] T039 [P] [US3] Escrever testes `get-cabinet-detail.use-case.spec.ts` em `ci-api-v2/src/modules/gabinete/test/use-cases/`
- [ ] T040 [P] [US3] Escrever teste integração (RED) `GabineteAtoDetailPage.integration.test.tsx` em `ci-client-v2/apps/web/src/modules/gabinete/__tests__/`

### Implementation for User Story 3

- [X] T041 [US3] Implementar `get-cabinet-detail.use-case.ts` com timeline + counts controles (GREEN T039)
- [X] T042 [US3] Implementar `update-cabinet.use-case.ts` emitindo evento `updated`
- [X] T043 [US3] Expor GET/PATCH `/gabinete/cabinets/:cabinetId` em `gabinete.controller.ts`
- [X] T044 [P] [US3] Abas de controles em `GabineteAtoDetailPage.tsx` (tabs integradas)
- [X] T045 [US3] Implementar `GabineteAtoDetailPage.tsx` em `ci-client-v2/apps/web/src/modules/gabinete/pages/`
- [X] T046 [US3] Registrar rota `/gabinete/atos/:id` via router override `gabinete-detalhes`

**Checkpoint**: Detalhe completo com timeline; edição persistida

---

## Phase 6: User Story 4 — Tramitar demanda stub (Priority: P1)

**Goal**: POST forward grava encaminhamento + evento; não toca Tramitação

**Independent Test**: VS-004 quickstart

### Tests for User Story 4 (TDD — RED first)

- [X] T047 [P] [US4] Escrever testes (RED) `forward-demanda.use-case.spec.ts` em `ci-api-v2/src/modules/gabinete/test/use-cases/forward-demanda.use-case.spec.ts` — CT-GAB-003

### Implementation for User Story 4

- [X] T048 [US4] Implementar `forward-demanda.use-case.ts` — append forwardings JSON + evento + status `in_transit` (GREEN T047)
- [X] T049 [US4] Expor POST `/gabinete/demandas/:id/forward` em `gabinete.controller.ts`
- [X] T050 [US4] Implementar `ForwardDemandaDialog.tsx` com banner stub e integrar em `GabineteDemandaDetailPage.tsx`

**Checkpoint**: Tramitar visível na timeline; módulo Tramitação inalterado

---

## Phase 7: User Story 5 — Acesso por setor (Priority: P1)

**Goal**: 403 padronizado sem vínculo setor; admin bypass

**Independent Test**: VS-001 quickstart

### Tests for User Story 5 (TDD — RED first)

- [ ] T051 [P] [US5] Escrever e2e (RED) casos 403/200 em `ci-api-v2/test/gabinete.e2e-spec.ts` — CT-GAB-006

### Implementation for User Story 5

- [ ] T052 [US5] Validar `@RequireModulo('gabinete')` em todas rotas `gabinete*.controller.ts` (GREEN T051)
- [ ] T053 [P] [US5] Integrar `useModuleAccess('gabinete')` nas pages em `ci-client-v2/apps/web/src/modules/gabinete/pages/`
- [ ] T054 [US5] Atualizar `ci-client-v2/apps/web/src/modules/shell/config/navigation.ts` — labels Demandas/Nova demanda

**Checkpoint**: Governança setor+módulo verificada API e client

---

## Phase 8: User Story 6 — Controle Numérico (Priority: P1)

**Goal**: CRUD controles numéricos nested na demanda

**Independent Test**: VS-005 passo 1 quickstart

### Tests for User Story 6 (TDD — RED first)

- [X] T055 [P] [US6] Escrever testes CRUD em `ci-api-v2/src/modules/gabinete/test/use-cases/controles-numericos.use-case.spec.ts`

### Implementation for User Story 6

- [X] T056 [US6] Adicionar modelo `CabinetControleNumerico` em `ci-api-v2/prisma/schema/gabinete.prisma` + migration
- [X] T057 [P] [US6] Implementar repositórios e use-cases CRUD em `use-cases/controles/` e `repository/controles.repositories.ts`
- [X] T058 [US6] Expor rotas `/gabinete/cabinets/:cabinetId/controles-numericos` em `gabinete.controller.ts`
- [X] T059 [US6] Implementar aba Controle Numérico em `GabineteAtoDetailPage.tsx`

**Checkpoint**: CRUD controle numérico no detalhe da demanda

---

## Phase 9: User Story 7 — Notificações e Autos de Infração (Priority: P1)

**Goal**: CRUD notificação + auto com groupId opcional

**Independent Test**: VS-005 passos 2 quickstart

### Tests for User Story 7 (TDD — RED first)

- [ ] T060 [P] [US7] Escrever testes (RED) em `ci-api-v2/src/modules/gabinete/test/use-cases/controles-notificacao-auto.use-case.spec.ts`

### Implementation for User Story 7

- [X] T061 [US7] Adicionar `CabinetControleNotificacao` e `CabinetControleAutoInfracao` em `gabinete.prisma` + migration
- [X] T062 [P] [US7] Implementar use-cases e repositórios CRUD em `use-cases/controles/` e `repository/controles.repositories.ts`
- [X] T063 [US7] Expor rotas `/notificacoes` e `/autos-infracao` nested em `gabinete.controller.ts`
- [X] T064 [US7] Implementar aba Notificações e Autos em `GabineteAtoDetailPage.tsx`

**Checkpoint**: Par notificação/auto persistido e listado

---

## Phase 10: User Story 8 — Documentos Tramitados por Setor (Priority: P1)

**Goal**: CRUD documento tramitado com setorId obrigatório

**Independent Test**: VS-005 passos 3–4 quickstart

### Tests for User Story 8 (TDD — RED first)

- [X] T065 [P] [US8] Escrever testes (RED) em `documentos-tramitados.use-case.spec.ts` — CT-GAB-004

### Implementation for User Story 8

- [X] T066 [US8] Adicionar `CabinetDocumentoTramitado` em `gabinete.prisma` + migration
- [X] T067 [US8] Implementar use-cases CRUD `documentos-tramitados.*`
- [X] T068 [US8] Expor rotas `/documentos-tramitados` nested
- [X] T069 [US8] Aba Documentos Tramitados em `GabineteAtoDetailPage.tsx` com coluna Setor + filtro API

**Checkpoint**: Documento tramitado unificado por Setor (sem siglas v1)

---

## Phase 11: User Story 9 — Dashboard Executivo (Priority: P1)

**Goal**: KPIs reais substituindo mock dashboard

**Independent Test**: VS-006 quickstart

### Tests for User Story 9 (TDD — RED first)

- [X] T070 [P] [US9] Escrever testes (RED) `get-dashboard.use-case.spec.ts` em `ci-api-v2/src/modules/gabinete/test/use-cases/get-dashboard.use-case.spec.ts`

### Implementation for User Story 9

- [X] T071 [US9] Implementar `get-dashboard.use-case.ts` com agregações por status (GREEN T070)
- [X] T072 [US9] Expor GET `/gabinete/dashboard` em `gabinete.controller.ts`
- [X] T073 [P] [US9] Criar `ci-client-v2/apps/web/src/modules/gabinete/api/dashboard.ts`
- [X] T074 [US9] Implementar `GabineteDashboardPage.tsx` com cards KPI + gráfico Nivo status; remover dependência mock `DashboardCharts` case gabinete

**Checkpoint**: Dashboard exibe contagens reais do tenant

---

## Phase 12: User Story 10 — Fiscalização Jatobá (Priority: P1)

**Goal**: Painel `/gabinete/auditoria` com checagens persistidas read-only

**Independent Test**: VS-007 quickstart

**Depends on**: US1+ (demandas seed); Phase 2

### Tests for User Story 10 (TDD — RED first)

- [X] T075 [P] [US10] Escrever testes (RED) rules em `ci-api-v2/src/modules/gabinete-fiscalizacao/lib/checks/deadline.rules.spec.ts`, `completeness.rules.spec.ts`, `forwarding.rules.spec.ts`
- [ ] T076 [P] [US10] Escrever testes (RED) `aggregate-conformity.spec.ts` em `gabinete-fiscalizacao/lib/`
- [ ] T077 [P] [US10] Escrever teste e2e (RED) POST run em `ci-api-v2/test/gabinete-fiscalizacao.e2e-spec.ts` — CT-GAB-FIS-003

### Schema & implementation

- [X] T078 [US10] Criar `ci-api-v2/prisma/schema/gabinete-fiscalizacao.prisma` — Run, Result, Check, Finding, Question*, SlaConfig + migration
- [X] T079 [P] [US10] Implementar checks puras e `run-checks-for-demanda.ts` em `gabinete-fiscalizacao/lib/`
- [X] T080 [US10] Implementar use-cases `run-fiscalizacao.use-case.ts`, `get-fiscalizacao-panel.use-case.ts` + repositories
- [X] T081 [US10] Implementar controller `gabinete-fiscalizacao.controller.ts` com `@RequireLicenca('jatoba')` conforme `contracts/rest-api-gabinete-fiscalizacao.md`
- [ ] T082 [P] [US10] Criar seed `ci-api-v2/prisma/seed/seed-fiscalizacao-questions-gabinete.ts`
- [X] T083 [US10] Implementar job `run-fiscalizacao-scheduled.job.ts` e registrar módulo em `app.module.ts`
- [X] T084 [P] [US10] Criar `ci-client-v2/apps/web/src/modules/gabinete/api/fiscalizacao.ts` + MSW handlers completos
- [X] T085 [US10] Implementar `GabineteAuditoriaPage.tsx` clonando padrão `OuvidoriaAuditoriaPage.tsx`; wire `ScreenPage` → page real

**Checkpoint**: Fiscalização Jatobá Gabinete operacional

---

## Phase 13: User Story 11 — Maturidade Carvalho (Priority: P1)

**Goal**: `/gabinete/maturidade` score híbrido R-50 + autoavaliação

**Independent Test**: VS-008 quickstart

**Depends on**: US10 (Jatobá feed parcial)

### Tests for User Story 11 (TDD — RED first)

- [X] T086 [P] [US11] Escrever testes (RED) `hybrid-score.spec.ts` em `ci-api-v2/src/modules/gabinete-maturidade/lib/` — CT-GAB-MAT-001
- [ ] T087 [P] [US11] Escrever testes integração (RED) `get-dashboard.integration-spec.ts` em `gabinete-maturidade/test/integration/`

### Schema & implementation

- [X] T088 [US11] Criar `ci-api-v2/prisma/schema/gabinete-maturidade.prisma` + migration conforme `data-model.md`
- [X] T089 [P] [US11] Implementar libs score, indicators operacionais Gabinete em `gabinete-maturidade/lib/` e `lib/indicators/`
- [X] T090 [US11] Implementar use-cases dashboard, self-assessment, action-plans espelhando `ouvidoria-maturidade`
- [X] T091 [US11] Implementar `gabinete-maturidade.controller.ts` com `@RequireLicenca('carvalho')`
- [ ] T092 [P] [US11] Criar seed `ci-api-v2/prisma/seed/seed-maturidade-questions-gabinete.ts`
- [X] T093 [P] [US11] Criar `ci-client-v2/apps/web/src/modules/gabinete/api/maturidade.ts`
- [X] T094 [US11] Implementar `GabineteMaturidadePage.tsx` clonando `OuvidoriaMaturidadePage.tsx`

**Checkpoint**: Maturidade Carvalho Gabinete com score real

---

## Phase 14: User Story 12 — Insights Cedro (Priority: P1)

**Goal**: `/gabinete/insights` agregações determinísticas + histórico batches

**Independent Test**: VS-009 quickstart

**Depends on**: US1+ (demandas); US6–8 (controles para regras extras)

### Tests for User Story 12 (TDD — RED first)

- [X] T095 [P] [US12] Escrever testes (RED) aggregation rules em `ci-api-v2/src/modules/gabinete-insights/lib/aggregation/volume.rules.spec.ts`
- [X] T096 [P] [US12] Escrever teste e2e (RED) GET latest em `ci-api-v2/src/modules/gabinete-insights/test/use-cases/list-latest-insights.gab.spec.ts` — CT-GAB-INS-002

### Schema & implementation

- [X] T097 [US12] Criar `ci-api-v2/prisma/schema/gabinete-insights.prisma` — Batch, Insight, Evidence + migration
- [X] T098 [P] [US12] Implementar regras agregação em `gabinete-insights/lib/aggregation/` conforme `contracts/rest-api-gabinete-insights.md`
- [X] T099 [US12] Implementar use-cases `generate-insights.use-case.ts`, `list-latest-insights.use-case.ts` + job schedule
- [X] T100 [US12] Implementar `gabinete-insights.controller.ts` com `@RequireLicenca('cedro')`
- [X] T101 [P] [US12] Criar `ci-client-v2/apps/web/src/modules/gabinete/api/insights.ts` + MSW
- [X] T102 [US12] Implementar `GabineteInsightsPage.tsx` clonando `OuvidoriaInsightsPage.tsx`

**Checkpoint**: Insights Cedro Gabinete com rastreio Somente leitura

---

## Phase 15: Polish & Cross-Cutting Concerns

**Purpose**: Seed demo, shell cleanup, docs produto, validação final

- [X] T103 [P] Implementar `ci-api-v2/prisma/seed/seed-gabinete-demo.ts` — ≥10 demandas + controles; registrar em `prisma/seed.ts`
- [X] T104 [P] Remover/desativar mocks gabinete em `ci-client-v2/apps/web/src/modules/shell/data/mock-data.ts` e `screens.ts` (rotas atos legacy)
- [X] T105 Atualizar seção Base Gabinete em `.cursor/docs/licencas-canonicas.md` — atos/protocolos e rotas licença
- [X] T106 [P] Export barrel `ci-client-v2/apps/web/src/modules/gabinete/index.ts` e wire todas rotas lazy; redirects `/gabinete/atos/*`
- [X] T107 [P] Completar MSW handlers gabinete para todas páginas em `ci-client-v2/apps/web/src/test/msw/handlers/gabinete.ts`
- [ ] T108 Executar validação manual `quickstart.md` VS-001…VS-009 e corrigir gaps *(shell polish concluído; VS manual pendente)*
- [~] T109 [P] Rodar suíte: `npm test -- gabinete` (API) + `npm run test -- gabinete` (client) + typecheck *(client: typecheck OK + 1 test gabinete OK; API não executada neste polish)*

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 Setup** → sem dependências
- **Phase 2 Foundational** → Phase 1 — **BLOQUEIA US1–US12**
- **Phase 3–11 (US1–US9 Base)** → Phase 2; ordem recomendada US1→US2→US3→US4; US5 paralelo cedo; US6–US8 após US3; US9 após US1
- **Phase 12–14 (US10–US12 Licenças)** → Phase 2 + demandas seed (US1); US11 beneficia US10; US12 após US6–8 ideal
- **Phase 15 Polish** → US1–US12 desejadas

### User Story Dependencies

| Story | Depende de | Independente após |
|-------|------------|-------------------|
| US1 | Phase 2 | MVP criar demanda |
| US2 | US1 (dados) | Lista própria |
| US3 | US1 | Detalhe próprio |
| US4 | US3 | Forward próprio |
| US5 | Phase 2 | Guards |
| US6–US8 | US3 (detail tabs) | CRUD controles |
| US9 | US1 | Dashboard |
| US10 | US1 + seed | Fiscalização |
| US11 | US10 parcial | Maturidade |
| US12 | US1, US6–8 ideal | Insights |

### Parallel Opportunities

- T001–T008 (Setup) em paralelo
- T009–T010, T017–T018, T021–T023 (tests) em paralelo por arquivo
- US6, US7, US8 API schemas (T056, T061, T066) sequenciais migration mas use-cases [P] após schema
- US10, US11, US12 **podem** paralelizar entre devs após Base+seed (T103)

### Parallel Example: User Story 1

```bash
# Tests RED em paralelo:
T021 create-demanda.use-case.spec.ts
T022 presign-demanda-anexo.use-case.spec.ts
T023 gabinete.contract.spec.ts

# Repositórios em paralelo após GREEN use-case core:
T025 create-protocolo.repository.ts
T027 presign/confirm protocolo anexo
```

---

## Implementation Strategy

### MVP First (User Story 1 only)

1. Phase 1 + Phase 2
2. Phase 3 (US1) — criar demanda + anexo
3. **STOP** — validar VS-002 quickstart

### Incremental Delivery (recomendado)

1. Setup + Foundational
2. US1 → US2 → US3 → US4 → US5 (Base operacional)
3. US6 → US7 → US8 (controles)
4. US9 (dashboard)
5. US10 → US12 → US11 (licenças; maturidade após Jatobá)
6. Polish

### Suggested MVP scope

**US1 apenas** (Phase 1–3): primeira demanda real com protocolo opcional e anexo — desbloqueia todo o resto.

---

## Notes

- Total tasks: **109**
- TDD: escrever testes RED antes de implementação em cada fase de story
- Commit após cada task ou grupo lógico
- Não commitar `.env` com credenciais Wasabi
