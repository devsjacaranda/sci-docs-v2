---
description: "Task list for Purchasing CRUD — Compras Lei 14.133 (018-purchasing-crud)"
---

# Tasks: Purchasing — CRUD de Demandas e Artefatos

**Input**: Design documents from `civ2-docs/specs/018-purchasing-crud/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Tests**: **Obrigatórios** — TDD (constitution II + plan.md + `contracts/test-strategy.md`): use-case specs Jest, contrato Supertest, componentes Vitest + MSW. Caminhos relativos à raiz `ci-v2/`. Módulo **greenfield** — zero código Compras hoje.

**Organization**: US1–US5 são P1; US6–US8 são P2. PCA API entra na fase Foundational (pré-requisito de US2). Ordem de fases: Setup → Foundational → US1 → US2 → US3 → US4 → US5 (client PCA) → US6 → US7 → US8 → Polish.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Pode executar em paralelo (arquivos diferentes, sem dependências pendentes)
- **[Story]**: User story da spec (US1–US8)

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Estrutura de pastas, fixtures e MSW para TDD

- [X] T001 [P] Criar `ci-api-v2/prisma/schema/compras.prisma` com enums `CompraPcaStatus` e models stub (CompraPca, CompraDemanda, CompraDemandaSequence, 7 artefatos) conforme `data-model.md`
- [X] T002 [P] Criar pastas `ci-api-v2/src/modules/compras/{repository,use-cases,test/use-cases}` e stubs `compras.module.ts`, `compras.controller.ts`, `compras.schemas.ts`, `compras.mapper.ts`
- [X] T003 [P] Criar pasta `ci-client-v2/apps/web/src/modules/compras/{api,components,pages/artefatos,lib,__tests__}` com barrel `index.ts`
- [X] T004 [P] Criar fixtures API `ci-api-v2/src/modules/compras/test/fixtures/{pca-list,demandas-list,demanda-detail,demanda-completed}.json`
- [X] T005 [P] Criar fixtures client `ci-client-v2/apps/web/src/modules/compras/fixtures/` espelhando fixtures API
- [X] T006 [P] Implementar handlers MSW em `ci-client-v2/apps/web/src/test/msw/handlers/compras.ts` (stubs GET/POST PCA, GET/POST demandas) e registrar em `ci-client-v2/apps/web/src/test/msw/handlers.ts`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Schema Prisma completo, migration, mapper derivado, schemas Zod, módulo NestJS wired, seed DEAE, API PCA — **bloqueia todas as user stories**

**⚠️ CRITICAL**: Nenhuma user story começa antes desta fase

### Tests first (TDD — RED)

- [X] T007 [P] Escrever testes (RED) `compras.mapper.spec.ts` em `ci-api-v2/src/modules/compras/test/compras.mapper.spec.ts` — progresso `3/7`, status draft/in_progress/completed, ETP waived satisfeito, riscos vazios pendente
- [X] T008 [P] Escrever testes (RED) `compras.schemas.spec.ts` em `ci-api-v2/src/modules/compras/test/compras.schemas.spec.ts` — ListDemandasQuery, CreateDemandaBody, UpsertEtpBody waived refine
- [X] T009 [P] Escrever testes (RED) `create-pca.use-case.spec.ts` em `ci-api-v2/src/modules/compras/test/use-cases/create-pca.use-case.spec.ts`
- [X] T010 [P] Escrever testes (RED) `list-pca.use-case.spec.ts` em `ci-api-v2/src/modules/compras/test/use-cases/list-pca.use-case.spec.ts`
- [X] T011 [P] Escrever testes (RED) `close-pca.use-case.spec.ts` em `ci-api-v2/src/modules/compras/test/use-cases/close-pca.use-case.spec.ts`
- [X] T012 [P] Escrever testes (RED) `compras.contract.spec.ts` — GET/POST `/compras/pca`, PATCH `/compras/pca/:id/close` em `ci-api-v2/src/modules/compras/test/compras.contract.spec.ts`

### Prisma & seed

- [X] T013 Completar `ci-api-v2/prisma/schema/compras.prisma` — campos finais, relations 1:1, unique `(tenantId, number)` em CompraDemanda, FK pcaId non-nullable
- [X] T014 Gerar e aplicar migration Prisma em `ci-api-v2/prisma/migrations/` (`npx prisma migrate dev`)
- [X] T015 Estender `ci-api-v2/prisma/seed/seed-jacaranda-tenant.ts` — vincular `ModuloSlug.compras` ao setor DEAE; seed 2 PCAs (1 ativo, 1 encerrado) + 3 demandas demo parciais

### API foundational

- [X] T016 Implementar `compras.mapper.ts` em `ci-api-v2/src/modules/compras/compras.mapper.ts` — `deriveDemandaStatus`, `deriveProgress`, `buildChecklist`, labels PT-BR (GREEN T007)
- [X] T017 Implementar Zod schemas em `ci-api-v2/src/modules/compras/compras.schemas.ts` — PCA, demandas query/body, responses (GREEN T008)
- [X] T018 [P] Implementar `pca.repositories.ts` em `ci-api-v2/src/modules/compras/repository/pca.repositories.ts`
- [X] T019 [P] Implementar `demanda-sequence.repository.ts` em `ci-api-v2/src/modules/compras/repository/demanda-sequence.repository.ts`
- [X] T020 Implementar use-cases `create-pca`, `list-pca`, `close-pca` em `ci-api-v2/src/modules/compras/use-cases/` (GREEN T009–T011)
- [X] T021 Wire rotas PCA em `ci-api-v2/src/modules/compras/compras.controller.ts` — `@RequireModulo('compras')` na classe; GET/POST `/compras/pca`, PATCH `/compras/pca/:pcaId/close` (GREEN T012)
- [X] T022 Registrar `ComprasModule` em `ci-api-v2/src/modules/compras/compras.module.ts` — providers, `StorageModule` import; importar em `ci-api-v2/src/app.module.ts`

**Checkpoint**: Migration aplicada; seed DEAE; PCA API GREEN; mapper derivado testado

---

## Phase 3: User Story 1 — Listar e filtrar demandas (Priority: P1) 🎯 MVP

**Goal**: GET `/compras/demandas` paginado com filtros PCA/status/progresso derivado + tela `/compras`

**Independent Test**: Autenticar usuário DEAE; abrir `/compras`; ver colunas Número, Título, Objeto, PCA, Status, Progresso; filtrar por PCA e status; dados reais da API

### Tests for User Story 1 (TDD — RED first)

- [X] T023 [P] [US1] Escrever testes (RED) `list-demandas.use-case.spec.ts` em `ci-api-v2/src/modules/compras/test/use-cases/list-demandas.use-case.spec.ts` — paginação, filtro pcaId, filtro status derivado, label progresso
- [X] T024 [P] [US1] Estender testes (RED) `compras.contract.spec.ts` — GET `/compras/demandas?page=1&limit=20&pcaId=&status=in_progress`
- [X] T025 [P] [US1] Escrever testes (RED) `DemandasListPage.test.tsx` em `ci-client-v2/apps/web/src/modules/compras/__tests__/DemandasListPage.test.tsx` — MSW + colunas + filtros
- [X] T026 [P] [US1] Escrever testes (RED) `DemandasTable.test.tsx` em `ci-client-v2/apps/web/src/modules/compras/__tests__/DemandasTable.test.tsx` — badge status e progresso `N/7`

### Implementation for User Story 1

- [X] T027 [P] [US1] Implementar `demanda.repositories.ts` — `listDemandasPaginated` com filtro status computado em `ci-api-v2/src/modules/compras/repository/demanda.repositories.ts`
- [X] T028 [US1] Implementar `list-demandas.use-case.ts` em `ci-api-v2/src/modules/compras/use-cases/list-demandas.use-case.ts` (GREEN T023)
- [X] T029 [US1] Wire GET `/compras/demandas` em `ci-api-v2/src/modules/compras/compras.controller.ts` (GREEN T024)
- [X] T030 [P] [US1] Criar `demandas.ts` em `ci-client-v2/apps/web/src/modules/compras/api/demandas.ts` — `fetchDemandas({ page, limit, pcaId, status })`
- [X] T031 [P] [US1] Criar `types.ts` em `ci-client-v2/apps/web/src/modules/compras/api/types.ts` — tipos response list/detail
- [X] T032 [P] [US1] Implementar `DemandasFilters.tsx` em `ci-client-v2/apps/web/src/modules/compras/components/DemandasFilters.tsx` — select PCA + select status
- [X] T033 [P] [US1] Implementar `DemandasTable.tsx` em `ci-client-v2/apps/web/src/modules/compras/components/DemandasTable.tsx`
- [X] T034 [P] [US1] Implementar `EmptyStateCompras.tsx` em `ci-client-v2/apps/web/src/modules/compras/components/EmptyStateCompras.tsx` — tenant sem demandas / sem PCA
- [X] T035 [US1] Implementar `DemandasListPage.tsx` em `ci-client-v2/apps/web/src/modules/compras/pages/DemandasListPage.tsx` — tabela + filtros + CTA Nova demanda (GREEN T025–T026)
- [X] T036 [US1] Registrar rota `/compras` em `ci-client-v2/apps/web/src/app/router.tsx` apontando para `DemandasListPage`

**Checkpoint**: US1 — listagem funcional; MVP list-only com seed

---

## Phase 4: User Story 2 — Criar nova demanda (Priority: P1)

**Goal**: POST `/compras/demandas` com numeração sequencial + tela `/compras/novo`

**Independent Test**: Selecionar PCA ativo; criar demanda; redirect `/compras/:id` com status Rascunho; validação sem PCA; PCA encerrado indisponível

### Tests for User Story 2 (TDD — RED first)

- [X] T037 [P] [US2] Escrever testes (RED) `create-demanda.use-case.spec.ts` em `ci-api-v2/src/modules/compras/test/use-cases/create-demanda.use-case.spec.ts` — reject sem pcaId, reject pca closed, número sequencial
- [X] T038 [P] [US2] Estender testes (RED) `compras.contract.spec.ts` — POST `/compras/demandas` 201
- [X] T039 [P] [US2] Escrever testes (RED) `DemandaCreatePage.test.tsx` em `ci-client-v2/apps/web/src/modules/compras/__tests__/DemandaCreatePage.test.tsx` — empty state sem PCA, redirect sucesso

### Implementation for User Story 2

- [X] T040 [P] [US2] Estender `demanda.repositories.ts` — `createDemanda` com sequence atômica
- [X] T041 [US2] Implementar `create-demanda.use-case.ts` em `ci-api-v2/src/modules/compras/use-cases/create-demanda.use-case.ts` (GREEN T037)
- [X] T042 [US2] Wire POST `/compras/demandas` em `ci-api-v2/src/modules/compras/compras.controller.ts` (GREEN T038)
- [X] T043 [P] [US2] Criar `pca.ts` em `ci-client-v2/apps/web/src/modules/compras/api/pca.ts` — `fetchPcas`, `createPca`, `closePca`
- [X] T044 [US2] Implementar `DemandaCreatePage.tsx` em `ci-client-v2/apps/web/src/modules/compras/pages/DemandaCreatePage.tsx` — select PCA ativos only, título, objeto, setor opcional (GREEN T039)
- [X] T045 [US2] Registrar rota `/compras/novo` em `ci-client-v2/apps/web/src/app/router.tsx`

**Checkpoint**: US2 — criação demanda + redirect hub stub

---

## Phase 5: User Story 3 — Hub quebra-cabeça da demanda (Priority: P1)

**Goal**: GET `/compras/demandas/:id` com checklist 7 artefatos + tela `/compras/:demandaId`

**Independent Test**: Abrir demanda; ver cabeçalho + 7 cards estados Preenchido/Pendente/Dispensado; click navega sub-rota; 404 cross-tenant

### Tests for User Story 3 (TDD — RED first)

- [X] T046 [P] [US3] Escrever testes (RED) `get-demanda-detail.use-case.spec.ts` em `ci-api-v2/src/modules/compras/test/use-cases/get-demanda-detail.use-case.spec.ts` — checklist 7 pending, estados mistos, 404 tenant
- [X] T047 [P] [US3] Estender testes (RED) `compras.contract.spec.ts` — GET `/compras/demandas/:id`
- [X] T048 [P] [US3] Escrever testes (RED) `DemandaHubPage.test.tsx` em `ci-client-v2/apps/web/src/modules/compras/__tests__/DemandaHubPage.test.tsx`
- [X] T049 [P] [US3] Escrever testes (RED) `ArtefactChecklist.test.tsx` em `ci-client-v2/apps/web/src/modules/compras/__tests__/ArtefactChecklist.test.tsx` — estados visuais

### Implementation for User Story 3

- [X] T050 [P] [US3] Estender `demanda.repositories.ts` — `findDemandaDetailById` com includes artefatos
- [X] T051 [US3] Implementar `get-demanda-detail.use-case.ts` em `ci-api-v2/src/modules/compras/use-cases/get-demanda-detail.use-case.ts` (GREEN T046)
- [X] T052 [US3] Wire GET `/compras/demandas/:demandaId` em `ci-api-v2/src/modules/compras/compras.controller.ts` (GREEN T047)
- [X] T053 [P] [US3] Criar `artefact-labels.ts` em `ci-client-v2/apps/web/src/modules/compras/lib/artefact-labels.ts` — 7 labels PT + routeSuffix
- [X] T054 [P] [US3] Implementar `ArtefactChecklist.tsx` em `ci-client-v2/apps/web/src/modules/compras/components/ArtefactChecklist.tsx` — grid cards clicáveis (GREEN T049)
- [X] T055 [US3] Implementar `DemandaHubPage.tsx` em `ci-client-v2/apps/web/src/modules/compras/pages/DemandaHubPage.tsx` — header + checklist; botão PDF disabled (GREEN T048)
- [X] T056 [US3] Registrar rota `/compras/:demandaId` em `ci-client-v2/apps/web/src/app/router.tsx`

**Checkpoint**: US3 — hub navegável; artefatos ainda vazios OK

---

## Phase 6: User Story 4 — Preencher e editar artefatos documentais (Priority: P1)

**Goal**: PUT/GET upsert 1:1 para 7 artefatos + 7 páginas sub-rota + upload comprovante opcional

**Independent Test**: Preencher DFD; dispensar ETP; preencher demais; hub reflete estados; upsert sem duplicar; valor ≤0 bloqueado em Pesquisa

### Tests for User Story 4 (TDD — RED first)

- [X] T057 [P] [US4] Escrever testes (RED) `upsert-dfd.use-case.spec.ts` em `ci-api-v2/src/modules/compras/test/use-cases/upsert-dfd.use-case.spec.ts`
- [X] T058 [P] [US4] Escrever testes (RED) `upsert-etp.use-case.spec.ts` em `ci-api-v2/src/modules/compras/test/use-cases/upsert-etp.use-case.spec.ts`
- [X] T059 [P] [US4] Escrever testes (RED) `upsert-analise-riscos.use-case.spec.ts` em `ci-api-v2/src/modules/compras/test/use-cases/upsert-analise-riscos.use-case.spec.ts`
- [X] T060 [P] [US4] Escrever testes (RED) `upsert-tr.use-case.spec.ts` em `ci-api-v2/src/modules/compras/test/use-cases/upsert-tr.use-case.spec.ts`
- [X] T061 [P] [US4] Escrever testes (RED) `upsert-pesquisa-precos.use-case.spec.ts` em `ci-api-v2/src/modules/compras/test/use-cases/upsert-pesquisa-precos.use-case.spec.ts`
- [X] T062 [P] [US4] Escrever testes (RED) `upsert-dotacao.use-case.spec.ts` em `ci-api-v2/src/modules/compras/test/use-cases/upsert-dotacao.use-case.spec.ts`
- [X] T063 [P] [US4] Escrever testes (RED) `upsert-parecer.use-case.spec.ts` em `ci-api-v2/src/modules/compras/test/use-cases/upsert-parecer.use-case.spec.ts`
- [X] T064 [P] [US4] Escrever testes (RED) `artefato-comprovante.use-case.spec.ts` em `ci-api-v2/src/modules/compras/test/use-cases/artefato-comprovante.use-case.spec.ts` — presign/confirm
- [X] T065 [P] [US4] Estender testes (RED) `compras.contract.spec.ts` — PUT/GET cada suffix artefato
- [X] T066 [P] [US4] Escrever testes (RED) `DfdPage.test.tsx` em `ci-client-v2/apps/web/src/modules/compras/__tests__/DfdPage.test.tsx` — save PUT MSW

### Implementation for User Story 4 — API

- [X] T067 [P] [US4] Implementar `artefatos.repositories.ts` em `ci-api-v2/src/modules/compras/repository/artefatos.repositories.ts` — upsert/get por tipo
- [X] T068 [P] [US4] Implementar use-cases `upsert-dfd`, `upsert-etp`, `upsert-analise-riscos`, `upsert-tr`, `upsert-pesquisa-precos`, `upsert-dotacao`, `upsert-parecer` em `ci-api-v2/src/modules/compras/use-cases/` (GREEN T057–T063)
- [X] T069 [US4] Implementar `artefato-comprovante.use-case.ts` em `ci-api-v2/src/modules/compras/use-cases/artefato-comprovante.use-case.ts` — presign/confirm via `StorageService` segmento `compras` (GREEN T064)
- [X] T070 [US4] Wire PUT/GET `/compras/demandas/:id/{dfd,etp,analise-riscos,tr,pesquisa-precos,dotacao-orcamentaria,parecer-juridico}` e rotas comprovante em `ci-api-v2/src/modules/compras/compras.controller.ts` (GREEN T065)

### Implementation for User Story 4 — Client

- [X] T071 [P] [US4] Criar `artefatos.ts` em `ci-client-v2/apps/web/src/modules/compras/api/artefatos.ts` — upsert/get/presign/confirm por suffix
- [X] T072 [P] [US4] Implementar `ComprovanteUpload.tsx` em `ci-client-v2/apps/web/src/modules/compras/components/ComprovanteUpload.tsx`
- [X] T073 [P] [US4] Implementar `DfdPage.tsx` em `ci-client-v2/apps/web/src/modules/compras/pages/artefatos/DfdPage.tsx` (GREEN T066)
- [X] T074 [P] [US4] Implementar `EtpPage.tsx` em `ci-client-v2/apps/web/src/modules/compras/pages/artefatos/EtpPage.tsx`
- [X] T075 [P] [US4] Implementar `AnaliseRiscosPage.tsx` em `ci-client-v2/apps/web/src/modules/compras/pages/artefatos/AnaliseRiscosPage.tsx` — lista editável riscos
- [X] T076 [P] [US4] Implementar `TrPage.tsx` em `ci-client-v2/apps/web/src/modules/compras/pages/artefatos/TrPage.tsx`
- [X] T077 [P] [US4] Implementar `PesquisaPrecosPage.tsx` em `ci-client-v2/apps/web/src/modules/compras/pages/artefatos/PesquisaPrecosPage.tsx`
- [X] T078 [P] [US4] Implementar `DotacaoPage.tsx` em `ci-client-v2/apps/web/src/modules/compras/pages/artefatos/DotacaoPage.tsx`
- [X] T079 [P] [US4] Implementar `ParecerPage.tsx` em `ci-client-v2/apps/web/src/modules/compras/pages/artefatos/ParecerPage.tsx`
- [X] T080 [US4] Registrar 7 sub-rotas `/compras/:demandaId/{dfd,etp,...}` em `ci-client-v2/apps/web/src/app/router.tsx`

**Checkpoint**: US4 — CRUD 7 artefatos end-to-end via API + páginas básicas

---

## Phase 7: User Story 5 — Gerenciar PCAs via modal (Priority: P1)

**Goal**: Sheet/modal na listagem — criar, listar, encerrar PCA; integrar filtro PCA

**Independent Test**: Abrir sheet em `/compras`; criar PCA; encerrar; PCA encerrado some do seletor `/compras/novo`; filtro listagem por PCA

### Tests for User Story 5 (TDD — RED first)

- [X] T081 [P] [US5] Escrever testes (RED) `PcaManageSheet.test.tsx` em `ci-client-v2/apps/web/src/modules/compras/__tests__/PcaManageSheet.test.tsx` — create, close, demandaCount
- [X] T082 [P] [US5] Estender MSW handlers em `ci-client-v2/apps/web/src/test/msw/handlers/compras.ts` — POST PCA, PATCH close, refresh list

### Implementation for User Story 5

- [X] T083 [US5] Implementar `PcaManageSheet.tsx` em `ci-client-v2/apps/web/src/modules/compras/components/PcaManageSheet.tsx` — lista + create + encerrar (GREEN T081)
- [X] T084 [US5] Integrar `PcaManageSheet` e filtro PCA em `DemandasListPage.tsx` — botão *Gerenciar PCAs*; refetch após mutação (GREEN T082)
- [X] T085 [US5] Integrar CTA criar PCA no empty state de `DemandaCreatePage.tsx` quando zero PCAs ativos

**Checkpoint**: US5 — gestão PCA inline sem rotas dedicadas

---

## Phase 8: User Story 6 — Dispensar ETP com justificativa (Priority: P2)

**Goal**: Fluxo ETP dispensado completo — motivo obrigatório, confirmação ao substituir dados técnicos, progresso satisfeito

**Independent Test**: Marcar dispensado + motivo; card Dispensado no hub; progresso conta ETP; salvar sem motivo → erro; toggle com dados prévios → dialog

### Tests for User Story 6 (TDD — RED first)

- [X] T086 [P] [US6] Estender testes (RED) `upsert-etp.use-case.spec.ts` — waived sem motivo 400; waived satisfeito no mapper
- [X] T087 [P] [US6] Escrever testes (RED) `EtpPage.waived.test.tsx` em `ci-client-v2/apps/web/src/modules/compras/__tests__/EtpPage.waived.test.tsx` — motivo required, confirm dialog

### Implementation for User Story 6

- [X] T088 [US6] Refinar Zod `UpsertEtpBody` e use-case em `ci-api-v2/src/modules/compras/use-cases/upsert-etp.use-case.ts` (GREEN T086)
- [X] T089 [US6] Completar `EtpPage.tsx` — toggle dispensado, motivo, dialog confirmação substituição (GREEN T087)

**Checkpoint**: US6 — dispensa ETP conforme Lei + spec

---

## Phase 9: User Story 7 — Acompanhar progresso derivado da demanda (Priority: P2)

**Goal**: Status Rascunho/Em andamento/Concluído automático em listagem, hub e pós-upsert artefato

**Independent Test**: Demanda nova → Rascunho; após 1 artefato → Em andamento; 7/7 (ou ETP waived + 6) → Concluído; sem PATCH manual de status

### Tests for User Story 7 (TDD — RED first)

- [X] T090 [P] [US7] Escrever testes integração (RED) `demanda-status-derivation.integration.spec.ts` em `ci-api-v2/src/modules/compras/test/demanda-status-derivation.integration.spec.ts` — fixtures draft → in_progress → completed
- [X] T091 [P] [US7] Escrever testes (RED) `demanda-progress.integration.test.tsx` em `ci-client-v2/apps/web/src/modules/compras/__tests__/demanda-progress.integration.test.tsx` — listagem Concluído após MSW fixture

### Implementation for User Story 7

- [X] T092 [US7] Garantir resposta upsert artefato inclui `demandaStatus` + `demandaProgress` atualizados em `ci-api-v2/src/modules/compras/compras.mapper.ts` e controller (GREEN T090)
- [X] T093 [US7] Invalidar React Query keys pós-save artefato em páginas `artefatos/*` para refrescar hub/listagem (GREEN T091)

**Checkpoint**: US7 — derivação automática validada API + client

---

## Phase 10: User Story 8 — Navegar entre artefatos com pendência (Priority: P2)

**Goal**: Layout compartilhado sub-rotas — breadcrumb, checklist lateral, voltar ao hub

**Independent Test**: Abrir `/compras/:id/dfd`; breadcrumb *Compras → Demanda #N → DFD*; checklist lateral clicável; *Voltar ao hub*

### Tests for User Story 8 (TDD — RED first)

- [X] T094 [P] [US8] Escrever testes (RED) `DemandaArtefactLayout.test.tsx` em `ci-client-v2/apps/web/src/modules/compras/__tests__/DemandaArtefactLayout.test.tsx` — breadcrumb, sidebar checklist, link hub

### Implementation for User Story 8

- [X] T095 [US8] Implementar `DemandaArtefactLayout.tsx` em `ci-client-v2/apps/web/src/modules/compras/components/DemandaArtefactLayout.tsx` (GREEN T094)
- [X] T096 [US8] Refatorar 7 páneas em `ci-client-v2/apps/web/src/modules/compras/pages/artefatos/` para usar `DemandaArtefactLayout` + `ArtefactChecklist` lateral

**Checkpoint**: US8 — navegação quebra-cabeça fluida

---

## Phase 11: Polish & Cross-Cutting Concerns

**Purpose**: Router shell, navegação, guards, soft delete, PDF 501, quickstart, isolamento tenant

- [X] T097 [P] Escrever testes (RED) modulo guard — usuário sem Compras 403 em `ci-api-v2/src/modules/compras/test/compras.modulo-guard.spec.ts`
- [X] T098 [P] Escrever testes (RED) `delete-demanda.use-case.spec.ts` em `ci-api-v2/src/modules/compras/test/use-cases/delete-demanda.use-case.spec.ts` — soft delete oculta listagem
- [X] T099 Implementar `delete-demanda.use-case.ts` e DELETE `/compras/demandas/:id` em `ci-api-v2/src/modules/compras/compras.controller.ts` (GREEN T098)
- [X] T100 Implementar GET `/compras/demandas/:id/relatorio` retornando 501 em `ci-api-v2/src/modules/compras/compras.controller.ts`
- [X] T101 Atualizar `ci-client-v2/apps/web/src/modules/shell/config/navigation.ts` — entrada Compras → `/compras`
- [X] T102 Deprecar/remover screens mock substituídos em `ci-client-v2/apps/web/src/modules/shell/config/screens.ts` (`compras-demandas-*`, `compras-pca-*`); manter stubs licenciados (auditoria) até specs 019+
- [X] T103 [P] Completar MSW handlers em `ci-client-v2/apps/web/src/test/msw/handlers/compras.ts` — cobertura contrato completo
- [X] T104 Executar validação manual `civ2-docs/specs/018-purchasing-crud/quickstart.md` e corrigir gaps
- [X] T105 [P] Rodar suíte: `cd ci-api-v2; npm test -- --testPathPattern=compras` e `cd ci-client-v2; npm test -- --filter=@ci/web -- compras`
- [X] T106 [P] Criar `civ2-docs/specs/018-purchasing-crud/STATUS.md` e arquivar com `/speckit-complete`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Sem dependências
- **Foundational (Phase 2)**: Depende Setup — **BLOQUEIA** US1–US8
- **US1 (Phase 3)**: Depende Foundational — **MVP listagem**
- **US2 (Phase 4)**: Depende Foundational (PCA API) — independente de US1 client
- **US3 (Phase 5)**: Depende US2 (demanda existente) ou seed
- **US4 (Phase 6)**: Depende US3 (hub/detail pattern)
- **US5 (Phase 7)**: Client PCA; API já em Foundational; integra com US1
- **US6 (Phase 8)**: Depende US4 ETP base
- **US7 (Phase 9)**: Depende US4 mapper integration
- **US8 (Phase 10)**: Depende US4 páginas artefato
- **Polish (Phase 11)**: Depende US1–US8 desejados

### User Story Dependencies

| Story | Depende de | Independente para teste |
|-------|------------|-------------------------|
| US1 | Foundational + seed | ✅ listagem com dados seed |
| US2 | Foundational (PCA) | ✅ create + redirect |
| US3 | US2 ou seed | ✅ hub read-only |
| US4 | US3 | ✅ upsert por artefato |
| US5 | Foundational PCA API | ✅ sheet isolado MSW |
| US6 | US4 ETP | ✅ waived flow |
| US7 | US4 | ✅ status fixtures |
| US8 | US4 pages | ✅ layout navigation |

### Parallel Opportunities

- T001–T006 (Setup) — todos [P]
- T007–T012 (RED Foundational) — todos [P]
- T057–T066 (RED US4) — todos [P]
- T073–T079 (7 páginas artefato) — todos [P] após T095 ou layout stub
- T068 use-cases paralelos após T067 repository

### Parallel Example: User Story 4

```bash
# Tests RED em paralelo:
upsert-dfd.use-case.spec.ts
upsert-etp.use-case.spec.ts
upsert-analise-riscos.use-case.spec.ts
# ... demais artefatos

# Páginas client em paralelo (após layout base):
DfdPage.tsx | EtpPage.tsx | TrPage.tsx | ...
```

---

## Implementation Strategy

### MVP First (User Story 1)

1. Phase 1 Setup
2. Phase 2 Foundational (CRITICAL)
3. Phase 3 US1 — listagem `/compras`
4. **STOP and VALIDATE** — quickstart §1

### Incremental Delivery

1. Foundational → PCA API + schema
2. US1 listagem → demo portfólio
3. US2 criação → fluxo iniciado
4. US3 hub → visão quebra-cabeça
5. US4 artefatos → valor operacional
6. US5 sheet PCA → gestão inline
7. US6–US8 → conformidade e UX
8. Polish → produção

### Suggested MVP Scope

**MVP mínimo**: Phase 1 + Phase 2 + **Phase 3 (US1)** — listagem real com filtros e seed.

**MVP operacional**: até **Phase 6 (US4)** parcial (DFD + ETP) — instrução processual iniciada.

**Feature complete**: Phase 11 — todas US + quickstart GREEN.

---

## Notes

- Prefixo Prisma `Compra*` evita colisão com `CabinetDemanda` (Gabinete)
- Status/progresso **nunca** persistidos em `CompraDemanda` — só via mapper
- Vocabulário UI: **demanda/demandas**, módulo **Compras**
- Sem `@RequireLicenca` — Base only (FR-024)
- Licenciados Jatobá/Cedro/Carvalho/Pau-Brasil — specs 019–021, fora deste tasks.md
