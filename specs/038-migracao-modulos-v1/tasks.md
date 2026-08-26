# Tasks: Migração de Módulos Inteiros v1 → v2 (Tenant AGEMAN)

**Input**: Design documents from `civ2-docs/specs/038-migracao-modulos-v1/`

**Prerequisites**: [plan.md](./plan.md), [spec.md](./spec.md), [research.md](./research.md), [data-model.md](./data-model.md), [contracts/](./contracts/README.md), [quickstart.md](./quickstart.md)

**Tests**: TDD obrigatório (Constitution II + FR-080 + SC-020). Playwright e comparação de bancos são exigência explícita da spec (FR-007, FR-009, FR-011). Escrever o teste, confirmar que falha, depois implementar.

**Organization**: Tarefas agrupadas por história de usuário para implementação e teste independentes.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: pode rodar em paralelo (arquivos diferentes, sem depender de tarefa incompleta)
- **[Story]**: US1–US6 conforme [spec.md](./spec.md)
- Toda descrição inclui caminho de arquivo

## Path Conventions

- API: `ci-api-v2/src/modules/`, `ci-api-v2/prisma/schema/`, `ci-api-v2/scripts/migracao-agema-v1/`
- Client tenant: `ci-client-v2/apps/web/src/modules/`
- Portal: `ci-client-v2/apps/publico/`
- E2E: `ci-client-v2/e2e/`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Corrigir o armazenamento silencioso, fixar portas e criar o workspace de comparação ponta a ponta.

- [x] T001 Add `WASABI_ENDPOINT`, `WASABI_REGION`, `WASABI_BUCKET`, `WASABI_ACCESS_KEY`, `WASABI_SECRET_KEY` as coherent optional fields in `ci-api-v2/src/infrastructure/config/env.schema.ts` so boot fails instead of falling into local stub when production config is incomplete
- [x] T002 [P] Document `WASABI_*`, `MYSQL_V1_URL`, `DIAGNOSTICO_DATABASE_URL`, `DIAGNOSTICO_PROCESSO_TABLE`, `DIAGNOSTICO_DB_POOL_SIZE`, `DIAGNOSTICO_QUERY_CACHE_TTL_MS` and `DIAGNOSTICO_QUERY_CACHE_MAX_ENTRIES` (names only) in `ci-api-v2/.env.example`; keep `WASABI_PREFIX` empty and documented as must-stay-empty
- [x] T003 [P] Pin `@ci/web` to port 5173 with `strictPort: true` in `ci-client-v2/apps/web/vite.config.ts` so Vite never silently lands on the admin-saas port 5174
- [x] T004 Create Playwright workspace `@ci/e2e` with `package.json` declaring `@playwright/test` 1.62.1 in `ci-client-v2/e2e/package.json`
- [x] T005 [P] Add `e2e` to workspaces and `test:e2e` script in `ci-client-v2/package.json`; add `e2e` task with `cache: false` in `ci-client-v2/turbo.json`; ignore `e2e/test-results/`, `e2e/playwright-report/` and `e2e/playwright/.auth/` in `ci-client-v2/.gitignore`
- [x] T006 Add `pdfkit` and `docx` dependencies in `ci-api-v2/package.json` (server-side letterhead PDF and manifestation DOCX per research R8/R16)
- [x] T007 [P] Add `DIAGNOSTICO_*` env names to `ci-api-v2/src/infrastructure/config/env.schema.ts` as coherent optionals so Diagnóstico answers explicit unavailability instead of crashing

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Schema, rastreabilidade, storage e sessão E2E — **bloqueia todas as histórias**. A carga (US1) precisa gravar em todos os modelos novos.

**⚠️ CRITICAL**: Nenhuma história começa antes desta fase terminar.

- [x] T008 [P] Create `MigracaoRegistroOrigem` (tenantId, entidade, idV2, tabelaV1, idV1, migradoEm; unique tenant+entidade+idV1 and tenant+entidade+idV2) in `ci-api-v2/prisma/schema/migracao.prisma`
- [x] T009 [P] Extend `Manifestacao` in `ci-api-v2/prisma/schema/manifestacao.prisma` with new close-without-resolution status, `numeroPersonalizado`, `motivo`, `programa`, `foiAtendido`, `medidasResolucao`, `desejaResposta`, `arquivadoEm`, `arquivadoPorId`, `respondidoEm`, `respondidoPorId`, `origem`, `dadosAdicionais`, `tipoId`; add `ManifestacaoConcessionaria` 1:1 and `ManifestacaoNumeroPersonalizadoSequence`; make `ManifestacaoAnexo.uploadedByUserId` nullable
- [x] T010 [P] Add tenant scope (`tenantId`) to `OuvidoriaAssunto` and `OuvidoriaFormaAtendimento`, and create `OuvidoriaTipoManifestacao` plus `OuvidoriaAtendimentoInterno` in `ci-api-v2/prisma/schema/ouvidoria-catalog.prisma`
- [x] T011 [P] Add `order` to `CabinetDocumentoTramitado`, `recebidoEm`/`recebidoPorId` to `CabinetDemanda`, and new event kinds (recebimento, devolucao, resposta) in `ci-api-v2/prisma/schema/gabinete.prisma`; make demand/protocolo anexo `uploadedByUserId` nullable
- [x] T012 [P] Add `nomeCompleto`, `descricao` and `active` to `Setor` in `ci-api-v2/prisma/schema/setor.prisma`
- [x] T013 [P] Create `DiagnosticoProcessoMarcador` (unique tenant+user+numeroProcesso) in `ci-api-v2/prisma/schema/diagnostico.prisma`
- [x] T014 [P] Create `DocumentoInstitucionalModelo`, `DocumentoInstitucional`, `DocumentoInstitucionalSequence` and `DocumentoInstitucionalAuditoria` in `ci-api-v2/prisma/schema/documento-institucional.prisma`
- [x] T015 Generate and apply Prisma migration covering T008–T014 via `ci-api-v2/prisma/migrations/`
- [x] T016 [P] Port tenant-path validation so download keys must start with the requesting tenant in `ci-api-v2/src/modules/shared/storage/storage.service.ts`
- [x] T017 Create Playwright config with two `webServer` entries (v1 `:8080`, v2 `:5173`), `reuseExistingServer: !CI`, and no production baseURL in `ci-client-v2/e2e/playwright.config.ts`
- [x] T018 Implement dual-session fixtures: v1 via `storageState` on `localStorage` keys, v2 via `context.addInitScript` seeding `sessionStorage['ci-access-token']` before any `goto`, guarded by `window.location.port`, in `ci-client-v2/e2e/fixtures/auth.fixture.ts`
- [x] T019 [P] Implement API-only login helper with credentials from env (no hardcoded defaults) writing `e2e/playwright/.auth/session-ageman.json` in `ci-client-v2/e2e/fixtures/login-via-api.ts`
- [x] T020 Register `diagnostico` as a module slug (no extra license) in `ci-api-v2/prisma/schema/enums.prisma` and `ci-api-v2/src/modules/permissao/` so gating is module permission, never a hardcoded tenant UUID

**Checkpoint**: Schema no ar, storage falha cedo se mal configurado, E2E autentica nos dois clientes, Diagnóstico é módulo e não constante de instituição.

---

## Phase 3: User Story 1 — Equipe comprova paridade de dados (Priority: P1) 🎯 MVP

**Goal**: Carga idempotente dos dados reais da AGEMAN e relatório de reconciliação que conta, compara campo a campo e é capaz de reprovar.

**Independent Test**: Restaurar o dump, rodar ensaio → carga → comparação. Relatório com origem − exclusões = destino em todas as entidades; divergência introduzida de propósito falha o comparador (SC-001, SC-002, SC-004, SC-005).

### Tests for User Story 1 ⚠️

> Escrever primeiro; confirmar que falham antes de implementar.

- [x] T021 [P] [US1] Write failing tests for the declared equivalence map (PT→EN enums, UTC dates, Decimal(15,2) as fixed-scale string, trim/NULL-empty) in `ci-api-v2/scripts/migracao-agema-v1/reconciliation/__tests__/equivalence-map.spec.ts`
- [x] T022 [P] [US1] Write failing test that injects a deliberate v2 divergence and asserts the comparator exits non-zero listing entity, record and field in `ci-api-v2/scripts/migracao-agema-v1/reconciliation/__tests__/compare-detects-divergence.spec.ts`
- [x] T023 [P] [US1] Write failing tests for address + concessionaria + origem mapping in `ci-api-v2/scripts/migracao-agema-v1/mappers/__tests__/ouvidoria.mapper.spec.ts`
- [x] T024 [P] [US1] Write failing tests for `ord`→`order` (not quantity), SIGED tri-alias, DEJUR minimal rows, and all 13 source tables in `ci-api-v2/scripts/migracao-agema-v1/mappers/__tests__/documentos-tramitados.mapper.spec.ts`
- [x] T025 [P] [US1] Write failing tests for anexo mapping (`caminho_arquivo` verbatim → `storageKey`, `nome_original` → `fileName`, `uploadConfirmed=true`, nullable uploader) in `ci-api-v2/scripts/migracao-agema-v1/mappers/__tests__/anexo.mapper.spec.ts`
- [x] T026 [P] [US1] Write failing idempotency tests: second load of anexos, eventos and gabinete controles must not duplicate in `ci-api-v2/scripts/migracao-agema-v1/load/__tests__/idempotency.spec.ts`

### Implementation for User Story 1

- [x] T027 [P] [US1] Implement the revisable equivalence map in `ci-api-v2/scripts/migracao-agema-v1/reconciliation/equivalence-map.ts`
- [x] T028 [US1] Persist `MigracaoRegistroOrigem` on every upsert (not only `.cache/` JSON) in `ci-api-v2/scripts/migracao-agema-v1/reconciliation/id-map-store.ts`
- [x] T029 [US1] Investigate how v1 public uploads (`entityType=public`, `entityId=temp-…`) bind to manifestations; document the join in `ci-api-v2/scripts/migracao-agema-v1/research-anexos-publicos.md` — this precedes anexo load (research R20)
- [x] T030 [US1] Reconcile 12 vs 13 `documentos_tramitados_*` tables before load; list the exact table names in `ci-api-v2/scripts/migracao-agema-v1/constants.ts`
- [x] T031 [US1] Extend ouvidoria mapper for address, concessionaria, `ARQUIVADO`/`ARQUIVADO_OK`, `numeroPersonalizado`, `extra_fields`→motivo/programa/`dadosAdicionais`, and `origem` in `ci-api-v2/scripts/migracao-agema-v1/mappers/ouvidoria.mapper.ts`
- [x] T032 [P] [US1] Implement anexo mapper (verbatim key, original filename, skip soft-deleted, report missing objects) in `ci-api-v2/scripts/migracao-agema-v1/mappers/anexo.mapper.ts`
- [x] T033 [P] [US1] Extend gabinete mapper: `ord`→`order`, SIGED aliases, memorando `destino`→`addressee`, DEJUR minimal rows, multiple `is_manager`→one `chefeUserId` plus leftover report in `ci-api-v2/scripts/migracao-agema-v1/mappers/gabinete.mapper.ts`
- [x] T034 [US1] Change ouvidoria/gabinete loaders from bare `create` to natural-key upsert for anexos, eventos and controles in `ci-api-v2/scripts/migracao-agema-v1/load/ouvidoria.load.ts` and `ci-api-v2/scripts/migracao-agema-v1/load/gabinete.load.ts`
- [x] T035 [US1] Implement address + concessionaria + sequence seed (parse max v1 number; keep legacy numbers) in `ci-api-v2/scripts/migracao-agema-v1/load/ouvidoria.load.ts`
- [x] T036 [US1] Add `demandas` phase (do not assume zero rows) and seed `CabinetDemandaSequence` in `ci-api-v2/scripts/migracao-agema-v1/load/gabinete.load.ts`
- [x] T037 [P] [US1] Add diagnostico markers + institutional-documents loaders in `ci-api-v2/scripts/migracao-agema-v1/load/diagnostico.load.ts`
- [x] T038 [US1] Wire new phases and keep `--dry-run` walking the same mapping as real load in `ci-api-v2/scripts/migracao-agema-v1/run-migration.ts`
- [x] T039 [US1] Make `--source-only` subtract the approved exclusion list and `--compare` cover every migrated entity in `ci-api-v2/scripts/migracao-agema-v1/reconciliation/count-report.ts`
- [x] T040 [US1] Implement field-by-field compare using the equivalence map, exiting 1 on undeclared diffs, in `ci-api-v2/scripts/migracao-agema-v1/reconciliation/field-compare.ts`
- [x] T041 [US1] Implement missing-attachment report (referenced / linked / not found) in `ci-api-v2/scripts/migracao-agema-v1/reconciliation/anexo-report.ts`
- [x] T042 [US1] Add `migracao:compare-fields` and `migracao:anexos` scripts in `ci-api-v2/package.json`
- [x] T043 [US1] Run dry-run then load twice; assert second run does not change counts; interrupt mid-run and resume without partial/duplicate rows — record the result in `civ2-docs/specs/038-migracao-modulos-v1/reconciliation/staging-run.md`

**Checkpoint**: US1 independente — carga idempotente, três contagens por entidade, comparador capaz de reprovar, anexos órfãos listados.

---

## Phase 4: User Story 2 — Atendente opera Ouvidoria no v2 (Priority: P2)

**Goal**: Painel real (7 agregações), catálogos por tenant, atendimentos internos, dois status de encerramento, carta-resposta, documentos no servidor e listagem unificada com filtros no servidor.

**Independent Test**: Ciclo registrar → responder → encaminhar → encerrar com carta; painel do mesmo período bate com o v1, salvo as duas correções declaradas (em análise real; respondidas só respondidas) — SC-013, SC-015.

### Tests for User Story 2 ⚠️

- [x] T044 [P] [US2] Write failing tests for the seven dashboard aggregations (year/month, full 12-month series, resolutivity from the two close statuses) in `ci-api-v2/src/modules/ouvidoria/test/use-cases/dashboard-agregacoes.use-case.spec.ts`
- [x] T045 [P] [US2] Write failing tests for close-with/without-resolution and letter attachment in `ci-api-v2/src/modules/ouvidoria/test/use-cases/encerrar-manifestacao.use-case.spec.ts`
- [x] T046 [P] [US2] Write failing tests for tenant catalog CRUD (inactivate-not-delete when referenced) in `ci-api-v2/src/modules/ouvidoria/test/use-cases/catalogos.use-case.spec.ts`
- [x] T047 [P] [US2] Write failing contract tests for dashboard + document + audit list endpoints in `ci-api-v2/src/modules/ouvidoria/ouvidoria.controller.spec.ts`

### Implementation for User Story 2

- [x] T048 [US2] Implement the seven aggregations as server-side queries (never client-side over a page) in `ci-api-v2/src/modules/ouvidoria/use-cases/get-dashboard-agregacoes.use-case.ts` and `ci-api-v2/src/modules/ouvidoria/repository/dashboard.repositories.ts`
- [x] T049 [US2] Extend `encerrar` to require resolution flag, set the matching status, persist `arquivadoEm`/`medidasResolucao`, and attach optional letter in `ci-api-v2/src/modules/ouvidoria/use-cases/encerrar-manifestacao.use-case.ts`
- [x] T050 [P] [US2] Implement tenant catalog use-cases (tipos, formas, assuntos, atendimentos internos) in `ci-api-v2/src/modules/ouvidoria/use-cases/` (`create-tipo-manifestacao.use-case.ts`, `update-forma-atendimento.use-case.ts`, `create-atendimento-interno.use-case.ts` and siblings)
- [x] T051 [P] [US2] Implement global audit list (period, author, event type, manifestation) in `ci-api-v2/src/modules/ouvidoria/use-cases/list-auditoria.use-case.ts`
- [x] T052 [US2] Implement server DOCX (`docx`) and PDF (PDFKit, decomposed letterhead/header/tables) in `ci-api-v2/src/modules/ouvidoria/use-cases/generate-manifestacao-docx.use-case.ts` and `ci-api-v2/src/modules/ouvidoria/use-cases/generate-manifestacao-pdf.use-case.ts`
- [x] T053 [US2] Extend Zod schemas and routes for dashboard, catalogs, internals, documents, close-with-letter in `ci-api-v2/src/modules/ouvidoria/ouvidoria.schemas.ts` and `ci-api-v2/src/modules/ouvidoria/ouvidoria.controller.ts`
- [x] T054 [US2] Extend list filters (status, priority, type, motivo, channel, period) to run on the full tenant set and return concessionaria + prazo + origem in `ci-api-v2/src/modules/ouvidoria/use-cases/list-manifestacoes.use-case.ts`
- [x] T055 [P] [US2] Replace mock dashboard with Nivo charts bound to the seven endpoints in `ci-client-v2/apps/web/src/modules/ouvidoria/pages/OuvidoriaDashboardPage.tsx` (create if the current page only renders `DashboardCharts` mock)
- [x] T056 [P] [US2] Add server-side filters (motivo, channel, period, origem) and KPI cards with real values in `ci-client-v2/apps/web/src/modules/ouvidoria/pages/ManifestacoesListPage.tsx` and `ci-client-v2/apps/web/src/modules/ouvidoria/components/list/OuvidoriaFiltersCard.tsx`
- [x] T057 [US2] Add close-with-letter dialog and document download actions in `ci-client-v2/apps/web/src/modules/ouvidoria/components/ManifestacaoActionDialogs.tsx`
- [x] T058 [P] [US2] Build catalog + internal-attendance admin pages in `ci-client-v2/apps/web/src/modules/ouvidoria/pages/OuvidoriaCatalogosPage.tsx` and `ci-client-v2/apps/web/src/modules/ouvidoria/pages/OuvidoriaAtendimentosPage.tsx`
- [x] T059 [US2] Add concessionaria, prazo, numeroPersonalizado and AGEMAN motivo fields to create/edit flow in `ci-client-v2/apps/web/src/modules/ouvidoria/components/ManifestacaoStepOneForm.tsx`
- [x] T060 [US2] Wire new screens in `ci-client-v2/apps/web/src/modules/ouvidoria/index.ts` and the shell router; add API client methods in `ci-client-v2/apps/web/src/modules/ouvidoria/api/manifestacoes.ts` and `ci-client-v2/apps/web/src/modules/ouvidoria/api/dashboard.ts`
- [x] T061 [US2] Write Playwright comparative spec for list+filters+dashboard numbers in `ci-client-v2/e2e/specs/ouvidoria-paridade.e2e.spec.ts`

**Checkpoint**: Atendente fecha o ciclo no v2 sem o v1; painel e listas conferem.

---

## Phase 5: User Story 3 — Servidor tramita demandas no v2 (Priority: P3)

**Goal**: Receber, devolver, reencaminhar; `currentSector`/`sectorId` atualizados em toda transição; histórico extraível em PDF.

**Independent Test**: Receber → encaminhar → reencaminhar → devolver → PDF do histórico na mesma demanda, comparando com o v1 (SC-014).

### Tests for User Story 3 ⚠️

- [x] T062 [P] [US3] Write failing tests that forward updates `currentSector` and `sectorId` and sets awaiting-receipt in `ci-api-v2/src/modules/gabinete/test/use-cases/forward-cabinet.use-case.spec.ts`
- [x] T063 [P] [US3] Write failing tests for receive / return (DEJUR-only, destination Ouvidoria|Gabinete) / reforward in `ci-api-v2/src/modules/gabinete/test/use-cases/receber-demanda.use-case.spec.ts`, `devolver-demanda.use-case.spec.ts` and `reencaminhar-demanda.use-case.spec.ts`
- [x] T064 [P] [US3] Write failing test for historico PDF containing chronological events with author and sectors in `ci-api-v2/src/modules/gabinete/test/use-cases/generate-historico-pdf.use-case.spec.ts`

### Implementation for User Story 3

- [x] T065 [US3] Fix `ForwardCabinetUseCase` to persist `currentSector` + `sectorId` and set awaiting-receipt in `ci-api-v2/src/modules/gabinete/use-cases/forward-cabinet.use-case.ts` and `ci-api-v2/src/modules/gabinete/repository/forward-cabinet.repository.ts`
- [x] T066 [P] [US3] Implement receive (status received, `recebidoEm`/`recebidoPorId`, notify sender) in `ci-api-v2/src/modules/gabinete/use-cases/receber-demanda.use-case.ts`
- [x] T067 [P] [US3] Implement return (DEJUR only; destination Ouvidoria or Gabinete) in `ci-api-v2/src/modules/gabinete/use-cases/devolver-demanda.use-case.ts`
- [x] T068 [P] [US3] Implement reforward as distinct event that reuses forward rules in `ci-api-v2/src/modules/gabinete/use-cases/reencaminhar-demanda.use-case.ts`
- [x] T069 [US3] Implement response-attachment event that does not change status or sector in `ci-api-v2/src/modules/gabinete/use-cases/anexar-resposta-demanda.use-case.ts`
- [x] T070 [US3] Implement historico PDF (decomposed letterhead services, never a 1000-line file) in `ci-api-v2/src/modules/gabinete/use-cases/generate-historico-pdf.use-case.ts`
- [x] T071 [US3] Add Zod + routes for the new actions in `ci-api-v2/src/modules/gabinete/gabinete.schemas.ts` and `ci-api-v2/src/modules/gabinete/gabinete.controller.ts`
- [x] T072 [US3] Add receive / return / reforward / historico-PDF actions and sector/status/origin/period filters (server-side) on `ci-client-v2/apps/web/src/modules/gabinete/` list and detail pages
- [x] T073 [US3] Keep ouvidoria/protocolo origin links navigable on the demand detail page in `ci-client-v2/apps/web/src/modules/gabinete/`
- [x] T074 [US3] Write Playwright comparative spec for the demand flow in `ci-client-v2/e2e/specs/gabinete-demandas-paridade.e2e.spec.ts`

**Checkpoint**: Fluxo de demanda completo no v2; setor atual muda de verdade.

---

## Phase 6: User Story 4 — Servidor mantém cadastros do Gabinete (Priority: P3)

**Goal**: Protocolos, Diretorias, Documentos Tramitados, Notificações/Autos e Controle Numérico com validação Zod, busca no servidor e campos próprios por tipo/setor.

**Independent Test**: CRUD em cada um dos cinco cadastros; busca cujo resultado está fora da primeira página; valor do auto com duas casas (SC-019, SC-012).

### Tests for User Story 4 ⚠️

- [x] T075 [P] [US4] Write failing tests for `order` vs `quantity` and type-specific controle-numerico fields rejected when inapplicable in `ci-api-v2/src/modules/gabinete/gabinete.schemas.spec.ts`
- [x] T076 [P] [US4] Write failing tests for Setor `active` (inactive hidden from forward destinations, visible in admin) in `ci-api-v2/src/modules/setor/` (new `inactivate-setor.use-case.spec.ts`)
- [x] T077 [P] [US4] Write failing tests for Decimal(15,2) amount on autos (no float) in `ci-api-v2/src/modules/gabinete/test/use-cases/cadastros.use-case.spec.ts`

### Implementation for User Story 4

- [x] T078 [US4] Extend documento-tramitado schema/use-case with `order` and per-sector field rules in `ci-api-v2/src/modules/gabinete/gabinete.schemas.ts` and `ci-api-v2/src/modules/gabinete/use-cases/cadastros.use-case.ts`
- [x] T079 [US4] Reject inapplicable controle-numerico fields per `documentType` in `ci-api-v2/src/modules/gabinete/gabinete.schemas.ts` (superRefine) instead of silently dropping them
- [x] T080 [US4] Implement Setor `nomeCompleto`/`descricao`/`active` and inactivate-not-delete in `ci-api-v2/src/modules/setor/`
- [x] T081 [US4] Add Diretorias page inside Gabinete (user vocabulary) wrapping Setor in `ci-client-v2/apps/web/src/modules/gabinete/pages/GabineteDiretoriasPage.tsx`
- [x] T082 [US4] Ensure protocolos / documentos / notificacoes / autos / controle-numerico list filters and pagination are server-side in the existing Gabinete list pages under `ci-client-v2/apps/web/src/modules/gabinete/`
- [x] T083 [US4] Surface `order` and type-specific fields (memorando destino, ofício circular assunto) in the cadastro forms under `ci-client-v2/apps/web/src/modules/gabinete/`
- [x] T084 [US4] Write Playwright comparative spec covering the five registries in `ci-client-v2/e2e/specs/gabinete-cadastros-paridade.e2e.spec.ts`

**Checkpoint**: Cinco cadastros administráveis no v2; validação recusa campo inválido.

---

## Phase 7: User Story 5 — Analista usa o Diagnóstico no v2 (Priority: P4)

**Goal**: Módulo novo — consulta à base externa, painel, marcadores só no servidor, PDF timbrado e documentos institucionais com reserva transacional.

**Independent Test**: Mesma busca v1/v2 confere; marcar sobrevive a outro navegador; reservar em duas sessões gera números distintos; base caída mostra erro explícito (SC-015, SC-016, SC-010).

### Tests for User Story 5 ⚠️

- [x] T085 [P] [US5] Write failing tests for dedup CTE semantics and category/result-type cascade in `ci-api-v2/src/modules/diagnostico/lib/__tests__/classificacao-processo.spec.ts`
- [x] T086 [P] [US5] Write failing tests for all seven `buscaPor` fields applied server-side in `ci-api-v2/src/modules/diagnostico/test/use-cases/list-processos.use-case.spec.ts`
- [x] T087 [P] [US5] Write failing tests for markers (idempotent upsert, no localStorage fallback path) in `ci-api-v2/src/modules/diagnostico/test/use-cases/toggle-marcador.use-case.spec.ts`
- [x] T088 [P] [US5] Write failing tests for transactional number reserve and concurrent uniqueness in `ci-api-v2/src/modules/documento-institucional/test/use-cases/reservar-numero.use-case.spec.ts`
- [x] T089 [P] [US5] Write failing tests for abandon-job writing audit (v1 gap) in `ci-api-v2/src/modules/documento-institucional/test/jobs/abandonar-reservados.job.spec.ts`
- [x] T090 [P] [US5] Write failing tests for explicit unavailability (never empty list) in `ci-api-v2/src/modules/diagnostico/test/use-cases/list-processos.unavailable.spec.ts`

### Implementation for User Story 5

- [x] T091 [US5] Implement read-only `mysql2` pool (`DIAGNOSTICO_DATABASE_URL`) in `ci-api-v2/src/modules/diagnostico/services/automacao-db.service.ts`
- [x] T092 [P] [US5] Implement classification helpers (SENTENCA / PETICAO_INICIAL / OUTROS and result-type cascade) in `ci-api-v2/src/modules/diagnostico/lib/classificacao-processo.ts`
- [x] T093 [US5] Implement processo repository with dedup CTE, seven search fields, in-memory TTL cache, coherent count+list in `ci-api-v2/src/modules/diagnostico/repository/processo.repository.ts`
- [x] T094 [P] [US5] Implement list / dashboard / toggle-marcador use-cases in `ci-api-v2/src/modules/diagnostico/use-cases/`
- [x] T095 [US5] Implement dashboard + selection PDF (PDFKit decomposed: letterhead, header, tables, charts) in `ci-api-v2/src/modules/diagnostico/use-cases/generate-dashboard-pdf.use-case.ts` and `generate-selecao-pdf.use-case.ts`
- [x] T096 [US5] Scaffold Diagnóstico module (schemas, controller, module, permission guard — no tenant UUID) in `ci-api-v2/src/modules/diagnostico/diagnostico.schemas.ts`, `diagnostico.controller.ts`, `diagnostico.module.ts`
- [x] T097 [P] [US5] Implement reserve / save / send / cancel / list / access-history / PDF use-cases (one file each) in `ci-api-v2/src/modules/documento-institucional/use-cases/`
- [x] T098 [US5] Implement abandon job (6h, reserved > 24h → abandoned **with audit event**) in `ci-api-v2/src/modules/documento-institucional/jobs/abandonar-reservados.job.ts`
- [x] T099 [US5] Wire documento-institucional module + Diagnóstico institutional routes (setor membership) in `ci-api-v2/src/modules/documento-institucional/` and `ci-api-v2/src/modules/diagnostico/diagnostico.controller.ts`
- [x] T100 [US5] Build the three client views (`relatorios`, `dashboard`, `processos-administrativos`) in `ci-client-v2/apps/web/src/modules/diagnostico/pages/`
- [x] T101 [US5] Implement marker hook that talks only to the API (no `localStorage` fallback) in `ci-client-v2/apps/web/src/modules/diagnostico/hooks/use-diagnostico-marcadores.ts`
- [x] T102 [US5] Render dashboard charts in Nivo (not Recharts) in `ci-client-v2/apps/web/src/modules/diagnostico/components/DiagnosticoDashboardGraficos.tsx`
- [x] T103 [US5] Register Diagnóstico routes and module gate (permission, not tenant name) in `ci-client-v2/apps/web/src/modules/diagnostico/` and the shell router
- [x] T104 [US5] Write Playwright comparative spec for search + dashboard + markers + institutional reserve in `ci-client-v2/e2e/specs/diagnostico-paridade.e2e.spec.ts`

**Checkpoint**: Diagnóstico usável no v2; marcador não vive no navegador; números institucionais únicos.

---

## Phase 8: User Story 6 — Cidadão registra no portal público do v2 (Priority: P5)

**Goal**: Endpoints públicos na API + app `apps/publico` (só fluxo AGEMAN, formulário guiado sem LLM, Tailwind v4 / paleta Mint).

**Independent Test**: Cidadão anônimo envia, recebe protocolo, consulta pelo protocolo; registro aparece interno como origem pública; envio sem desafio é recusado (SC-017, SC-018).

### Tests for User Story 6 ⚠️

- [x] T105 [P] [US6] Write failing tests for public create (identified vs anonymous, per-program required fields, automation challenge) in `ci-api-v2/src/modules/ouvidoria/test/use-cases/criar-manifestacao-publica.use-case.spec.ts`
- [x] T106 [P] [US6] Write failing tests for public upload temp-id expiry and consulta that does not leak existence on wrong key in `ci-api-v2/src/modules/ouvidoria/test/use-cases/upload-publico.use-case.spec.ts` and `consulta-publica.use-case.spec.ts`
- [x] T107 [P] [US6] Write failing Zod tests for AGEMAN public fields (água matrícula, iluminação poste) in `ci-api-v2/src/modules/ouvidoria/ouvidoria.schemas.ts` companion spec

### Implementation for User Story 6

- [x] T108 [US6] Implement public create / public upload / public catalogs endpoints (`@Public()`, tenant header, rate limit, challenge) in `ci-api-v2/src/modules/ouvidoria/use-cases/criar-manifestacao-publica.use-case.ts` and `upload-anexo-publico.use-case.ts`; register in `ouvidoria.controller.ts`
- [x] T109 [US6] Extend public consulta to hide requester PII and treat wrong key like unknown protocol in `ci-api-v2/src/modules/ouvidoria/use-cases/consulta-publica.use-case.ts`
- [x] T110 [US6] Scaffold `@ci/publico` following `apps/admin-saas` (local `envDir`, Vite `--mode ageman`) in `ci-client-v2/apps/publico/`
- [x] T111 [P] [US6] Add toast and stepper to `@ci/ui` in `ci-client-v2/packages/ui/src/`
- [x] T112 [US6] Port accessibility (font, color-blind modes, speech) including SVG `feColorMatrix` filters in `ci-client-v2/apps/publico/index.html` and `ci-client-v2/apps/publico/src/`
- [x] T113 [US6] Implement guided form as React state (no `window` events, no LLM) in `ci-client-v2/apps/publico/src/modules/manifestacao/`
- [x] T114 [US6] Apply Mint palette via `@theme inline` (not the v1 institutional blue) in `ci-client-v2/apps/publico/src/index.css`
- [x] T115 [US6] Add `dev:publico` script in `ci-client-v2/package.json`; do **not** copy env files over the monorepo root `.env`
- [x] T116 [US6] Write Playwright spec for public submit → protocol → internal appearance + consulta in `ci-client-v2/e2e/specs/portal-publico.e2e.spec.ts`

**Checkpoint**: Portal AGEMAN no monorepo; cidadão completa o fluxo sem login.

---

## Phase 9: Polish & Cross-Cutting Concerns

**Purpose**: Critérios que atravessam histórias e o encerramento de módulo.

- [x] T117 [P] Confirm no business data is written to `localStorage`/`sessionStorage` in Diagnóstico or Ouvidoria client modules (SC-010) — grep + test in `ci-client-v2/apps/web/src/modules/diagnostico/` and `ci-client-v2/apps/web/src/modules/ouvidoria/`
- [x] T118 [P] Confirm every new list/filter/sort/page runs on the server (SC-012) in the new use-cases under `ci-api-v2/src/modules/ouvidoria/`, `gabinete/`, `diagnostico/`
- [x] T119 [P] Confirm tenant isolation: cross-tenant request is rejected (SC-009) with tests in `ci-api-v2/src/modules/ouvidoria/ouvidoria.controller.spec.ts` and `ci-api-v2/src/modules/diagnostico/`
- [x] T120 Add loading / empty / error-with-retry states on every new screen (FR-078) under `ci-client-v2/apps/web/src/modules/{ouvidoria,gabinete,diagnostico}/` and `ci-client-v2/apps/publico/`
- [x] T121 [P] Capability checklist per module (signed off before release) in `civ2-docs/specs/038-migracao-modulos-v1/checklists/capacidades.md` (SC-006)
- [x] T122 Run the full [quickstart.md](./quickstart.md) validation path (count → dry-run → migrate → compare → e2e → unit/build) and record outcomes in `civ2-docs/specs/038-migracao-modulos-v1/STATUS.md`
- [x] T123 Confirm fiscalização / insights / maturidade files were not modified (out of scope) by reviewing the diff of `ci-api-v2/src/modules/*-fiscalizacao/`, `*-insights/`, `*-maturidade/` and the matching client pages

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: sem dependência — começa agora
- **Foundational (Phase 2)**: depende do Setup — **bloqueia todas as histórias**
- **US1 (Phase 3)**: depende do Foundational — MVP
- **US2 (Phase 4)**: depende do Foundational + dados da US1 para validar números reais
- **US3 (Phase 5)**: depende do Foundational + US1; ganha se US2 já encaminha manifestação→demanda, mas o fluxo de demanda testa sozinho
- **US4 (Phase 6)**: depende do Foundational + US1; independente de US3
- **US5 (Phase 7)**: depende do Foundational; a carga de marcadores/documentos institucionais da US1 é desejável mas o módulo funciona contra a base externa mesmo sem ela
- **US6 (Phase 8)**: depende de US2 (endpoints públicos estendem a Ouvidoria)
- **Polish (Phase 9)**: depois das histórias que se pretende entregar

### User Story Dependencies

- **US1 (P1)**: depois da Phase 2 — nenhuma outra história
- **US2 (P2)**: depois da Phase 2; validação numérica usa US1
- **US3 (P3)**: depois da Phase 2; validação de dados usa US1
- **US4 (P3)**: depois da Phase 2; **paralela a US3** (arquivos distintos)
- **US5 (P4)**: depois da Phase 2; **paralela a US2/US3/US4** (módulo novo)
- **US6 (P5)**: depois de US2

### Within Each User Story

- Testes RED antes da implementação
- Schema (já na Phase 2) → mappers/use-cases → endpoints → UI → E2E
- História completa e testável antes de avançar prioridade, salvo paralelismo explícito

### Parallel Opportunities

- T001–T007 (Setup) em paralelo quando os arquivos não colidem (`env.schema.ts` é T001 depois T007)
- T008–T014 (schemas Prisma) em paralelo — arquivos distintos
- T016, T017–T019, T020 em paralelo após T015
- T021–T026 (testes US1) em paralelo
- T032 / T033 / T037 em paralelo
- Após Phase 2: US3 e US4 em paralelo; US5 em paralelo com US2
- T044–T047, T062–T064, T075–T077, T085–T090, T105–T107 em paralelo dentro da respectiva história

---

## Parallel Example: User Story 1

```text
# Testes RED em paralelo:
Task: T021 equivalence-map.spec.ts
Task: T022 compare-detects-divergence.spec.ts
Task: T023 ouvidoria.mapper.spec.ts
Task: T024 documentos-tramitados.mapper.spec.ts
Task: T025 anexo.mapper.spec.ts
Task: T026 idempotency.spec.ts

# Depois, mappers em paralelo:
Task: T032 anexo.mapper.ts
Task: T033 gabinete.mapper.ts
```

## Parallel Example: After Foundational

```text
Developer A: Phase 3 US1 (pipeline + reconciliação)
Developer B: Phase 7 US5 (Diagnóstico — módulo novo, arquivos isolados)
Developer C: Phase 1 leftovers + E2E fixtures já na Phase 2
# US2 espera US1 para validar números reais, mas a API do painel pode começar após Phase 2
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Phase 1 Setup — sobretudo T001 (storage) e T003 (porta)
2. Phase 2 Foundational — schema + E2E session
3. Phase 3 US1 — carga + comparador
4. **PARAR E VALIDAR**: [quickstart.md](./quickstart.md) §3 (count → dry-run → migrate → compare, inclusive a segunda execução)
5. Só então abrir Ouvidoria / Gabinete / Diagnóstico

### Incremental Delivery

1. Setup + Foundational → fundação pronta
2. US1 → dados reais no v2 + evidência automatizada (**MVP**)
3. US2 → Ouvidoria operável; checklist de capacidades
4. US3 + US4 em paralelo → Gabinete encerrado
5. US5 → Diagnóstico encerrado
6. US6 → portal público; v1 deixa de ser necessário para a AGEMAN nestes módulos

### Parallel Team Strategy

1. Time fecha Setup + Foundational junto
2. Depois:
   - Pessoa A: US1 (caminho crítico)
   - Pessoa B: US5 (módulo novo, pouca colisão)
   - Pessoa C: US3 ou US4 após US1 ter carregado os cadastros
3. US2 depois de US1 para os números do painel serem reais
4. US6 por último, em cima da US2

---

## Notes

- [P] = arquivos diferentes, sem depender de tarefa incompleta
- [USx] rastreia a história; Setup / Foundational / Polish não levam label de história
- Constitution: uma operação por arquivo em repository e use-cases; Zod only; tenant via ALS; `resolveUserTableId` em toda FK para `User`
- Não portar: filtro no cliente sobre página carregada, KPI hardcoded, `localStorage` de negócio, gating por UUID de tenant, arquivos monolíticos de PDF, senha hardcoded em E2E, apontar teste para produção
- Fora de escopo: fiscalização, insights com IA, maturidade, sub-app SEDEL, LLM no portal
- Commit por tarefa ou grupo lógico; parar em qualquer checkpoint e validar a história sozinha
