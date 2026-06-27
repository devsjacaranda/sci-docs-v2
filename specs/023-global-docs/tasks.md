# Tasks: Desmockar Central de Documentação

**Input**: Design documents from `/specs/023-global-docs/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

**Tests**: TDD obrigatório (Constitution II) — testes RED antes de implementação em cada slice.

**Organization**: Tasks grouped by user story for independent implementation and testing.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: User story label (US1–US5)

## Path Conventions

- **API**: `ci-api-v2/src/modules/global-docs/`, `ci-api-v2/prisma/`
- **Client**: `ci-client-v2/apps/web/src/modules/global-docs/`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Scaffold de módulos API e client

- [X] T001 Create Prisma schema file `ci-api-v2/prisma/schema/global-docs.prisma` with enums `GlobalDocType`, models `GlobalDocArticle`, `GlobalDocStep`, `GlobalDocReference` per data-model.md
- [X] T002 [P] Scaffold Nest module folder `ci-api-v2/src/modules/global-docs/` (module, controller, schemas, mapper, repository/, use-cases/)
- [X] T003 [P] Scaffold client module folder `ci-client-v2/apps/web/src/modules/global-docs/` (index.ts, api/, hooks/, pages/, components/)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Schema, API read-only, seed e client API layer — **BLOCKS all user stories**

**⚠️ CRITICAL**: No user story UI work until this phase completes

- [X] T004 Add `globalDocArticles GlobalDocArticle[]` relation in `ci-api-v2/prisma/schema/tenant.prisma`
- [X] T005 Run Prisma migration for global-docs schema (`ci-api-v2/prisma/migrations/`)
- [X] T006 [P] Implement Zod schemas in `ci-api-v2/src/modules/global-docs/global-docs.schemas.ts` (list query, list item, detail response) per contracts/rest-api-global-docs.md
- [X] T007 [P] RED: Write `ci-api-v2/src/modules/global-docs/global-docs.mapper.spec.ts` (typeLabel, moduleLabel, steps order)
- [X] T008 Implement `ci-api-v2/src/modules/global-docs/global-docs.mapper.ts` — GREEN mapper tests
- [X] T009 [P] RED: Write `ci-api-v2/src/modules/global-docs/use-cases/list-global-docs.use-case.spec.ts` (pagination, moduleSlug, type, search filters)
- [X] T010 Implement `ci-api-v2/src/modules/global-docs/repository/list-global-docs.repository.ts`
- [X] T011 Implement `ci-api-v2/src/modules/global-docs/use-cases/list-global-docs.use-case.ts` — GREEN list use-case tests
- [X] T012 [P] RED: Write `ci-api-v2/src/modules/global-docs/use-cases/get-global-doc.use-case.spec.ts` (detail with steps/references, 404)
- [X] T013 Implement `ci-api-v2/src/modules/global-docs/repository/find-global-doc-by-id.repository.ts`
- [X] T014 Implement `ci-api-v2/src/modules/global-docs/use-cases/get-global-doc.use-case.ts` — GREEN detail use-case tests
- [X] T015 Implement `ci-api-v2/src/modules/global-docs/global-docs.controller.ts` (`GET /global/docs`, `GET /global/docs/:id`, `@RequireLicenca('base')`)
- [X] T016 Register `GlobalDocsModule` in `ci-api-v2/src/modules/global-docs/global-docs.module.ts` and `ci-api-v2/src/app.module.ts`
- [X] T017 RED: Write `ci-api-v2/test/global-docs.e2e-spec.ts` (auth, tenant isolation, list, detail, 404)
- [X] T018 GREEN: Fix e2e until passing against seeded tenant
- [X] T019 Implement `ci-api-v2/prisma/seed/seed-global-docs.ts` — migrate copy from `mock-data.ts` (`globalUsageDocs`, `moduleProcessGuides.compras`); ≥2 docs per module (ouvidoria, juridico, compras, contratos, patrimonio, protocolo); ETP guide with 7 steps
- [X] T020 Wire `seedGlobalDocs()` in `ci-api-v2/prisma/seed/seed-jacaranda-tenant.ts`
- [X] T021 [P] RED: Write `ci-client-v2/apps/web/src/modules/global-docs/api/global-docs.schemas.spec.ts` (Zod round-trip vs contract fixtures)
- [X] T022 [P] Implement `ci-client-v2/apps/web/src/modules/global-docs/api/global-docs.schemas.ts` and `global-docs.api.ts`
- [X] T023 [P] Add MSW handlers in `ci-client-v2/apps/web/src/test/msw/handlers/global-docs.ts` and register in handlers index

**Checkpoint**: API list/detail functional; seed Jacaranda ≥12 artigos; client API + MSW ready

---

## Phase 3: User Story 1 — Consultar Central Global (Priority: P1) 🎯 MVP

**Goal**: `/global/documentacao` exibe cards reais da API — sem `globalUsageDocs` mock

**Independent Test**: Autenticar Jacaranda → `/global/documentacao` → cards com título, tipo, módulo, resumo, data do backend; tenant vazio → estado orientativo

### Tests for User Story 1

- [X] T024 [P] [US1] RED: Write `ci-client-v2/apps/web/src/modules/global-docs/pages/GlobalDocumentacaoPage.test.tsx` (list render, empty state, module labels)

### Implementation for User Story 1

- [X] T025 [P] [US1] Create `ci-client-v2/apps/web/src/modules/global-docs/components/DocArticleCard.tsx` (card clicável, badge tipo, módulo, resumo, data)
- [X] T026 [P] [US1] Create `ci-client-v2/apps/web/src/modules/global-docs/hooks/useGlobalDocsList.ts` (React Query → `listGlobalDocs`)
- [X] T027 [US1] Create `ci-client-v2/apps/web/src/modules/global-docs/pages/GlobalDocumentacaoPage.tsx` (intro Base card, grid cards, empty state, loading/error)
- [X] T028 [US1] Export `GLOBAL_DOCS_OVERRIDES` in `ci-client-v2/apps/web/src/modules/global-docs/index.ts` mapping `global-documentacao` → `GlobalDocumentacaoPage`
- [X] T029 [US1] Register route overrides in `ci-client-v2/apps/web/src/app/router.tsx` for `/global/documentacao`
- [X] T030 [US1] Update `ci-client-v2/apps/web/src/modules/shell/pages/ScreenPage.tsx` — remove inline `GlobalDocsPanel` mock rendering for `global-documentacao`
- [X] T031 [US1] GREEN: Fix `GlobalDocumentacaoPage.test.tsx` until passing

**Checkpoint**: US1 independently testable — central lista artigos seedados

---

## Phase 4: User Story 2 — Detalhe com passo a passo (Priority: P1)

**Goal**: Detalhe de documento com passos ordenados, dicas, referências e 404 claro

**Independent Test**: Abrir guia ETP Compras → 7 passos numerados; abrir *Uso do módulo* → sem passos; ID inválido → feedback

### Tests for User Story 2

- [X] T032 [P] [US2] RED: Write `ci-client-v2/apps/web/src/modules/global-docs/pages/GlobalDocDetailPage.test.tsx` (steps render, references badges, 404 state)

### Implementation for User Story 2

- [X] T033 [P] [US2] Create `ci-client-v2/apps/web/src/modules/global-docs/components/DocStepList.tsx` (migrate step UI from `shell/components/mock/DocsPanel.tsx`)
- [X] T034 [P] [US2] Create `ci-client-v2/apps/web/src/modules/global-docs/hooks/useGlobalDocDetail.ts`
- [X] T035 [US2] Create `ci-client-v2/apps/web/src/modules/global-docs/pages/GlobalDocDetailPage.tsx` (breadcrumb, header, references, steps conditional)
- [X] T036 [US2] Add route `/global/documentacao/:docId` in `ci-client-v2/apps/web/src/modules/global-docs/index.ts` and `router.tsx`
- [X] T037 [US2] Wire `DocArticleCard` navigation to detail route in `DocArticleCard.tsx`
- [X] T038 [US2] GREEN: Fix `GlobalDocDetailPage.test.tsx` until passing

**Checkpoint**: US1 + US2 — browse + read full guide independently

---

## Phase 5: User Story 4 — Seed mínimo por módulo (Priority: P1)

**Goal**: Validar FR-010/FR-011 — ≥2 docs × 6 módulos; guia ETP Compras com passos

**Independent Test**: Após `prisma:seed`, contar por `moduleSlug`; API list retorna ≥12 total; Compras tem `process_guide` com 7 steps

### Tests for User Story 4

- [X] T039 [P] [US4] Add seed assertion test in `ci-api-v2/prisma/seed/seed-global-docs.spec.ts` or extend `global-docs.e2e-spec.ts` — ≥2 per moduleSlug, ETP steps count = 7

### Implementation for User Story 4

- [X] T040 [US4] Review and complete seed content in `ci-api-v2/prisma/seed/seed-global-docs.ts` — 2º documento complementar por módulo (copy PT-BR, vocabulário regras-plataforma)
- [X] T041 [US4] GREEN: Run seed assertion test; fix seed gaps until passing

**Checkpoint**: Demo tenant always has minimum catalog content

---

## Phase 6: User Story 3 — Filtros e busca (Priority: P2)

**Goal**: Filtrar por módulo/tipo e buscar por termo — server-side + UI funcional

**Independent Test**: Filtrar Compras → só Compras; filtrar *Guia de processo* → só guias; buscar "ETP" → resultados; combo vazia → empty state

### Tests for User Story 3

- [X] T042 [P] [US3] Extend `GlobalDocumentacaoPage.test.tsx` with filter/search scenarios (module, type, search, empty combo)

### Implementation for User Story 3

- [X] T043 [P] [US3] Create `ci-client-v2/apps/web/src/modules/global-docs/components/DocFiltersBar.tsx` (select módulo, select tipo, input busca debounced 300ms)
- [X] T044 [US3] Integrate `DocFiltersBar` into `GlobalDocumentacaoPage.tsx` passing params to `useGlobalDocsList`
- [X] T045 [US3] Add empty-state copy for zero filter results in `GlobalDocumentacaoPage.tsx`
- [X] T046 [US3] GREEN: Fix filter tests in `GlobalDocumentacaoPage.test.tsx`

**Checkpoint**: US3 adds discoverability without breaking US1/US2

---

## Phase 7: User Story 5 — Painel contextual por módulo (Priority: P2)

**Goal**: `ModuleDocsPanel` consome API — sem `moduleProcessGuides` estático

**Independent Test**: Tela docs Compras → guia ETP da API; módulo sem guia → mensagem orientativa

### Tests for User Story 5

- [X] T047 [P] [US5] RED: Write `ci-client-v2/apps/web/src/modules/global-docs/components/ModuleDocsPanel.test.tsx` (loads guide, empty module, no mock fallback)

### Implementation for User Story 5

- [X] T048 [US5] Move/refactor `ModuleDocsPanel` to `ci-client-v2/apps/web/src/modules/global-docs/components/ModuleDocsPanel.tsx` using `useGlobalDocsList({ moduleSlug, type: 'process_guide' })`
- [X] T049 [US5] Update `ci-client-v2/apps/web/src/modules/shell/pages/ScreenPage.tsx` — import `ModuleDocsPanel` from `@/modules/global-docs`
- [X] T050 [US5] Add redirect or link for `/compras/guia/etp` to seed ETP doc in `router.tsx` or `modules/global-docs/index.ts`
- [X] T051 [US5] GREEN: Fix `ModuleDocsPanel.test.tsx` until passing

**Checkpoint**: All five user stories independently functional

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Remover mocks, stats estáticos, validação final

- [X] T052 [P] Remove `globalUsageDocs` and `moduleProcessGuides` from `ci-client-v2/apps/web/src/modules/shell/data/mock-data.ts`
- [X] T053 [P] Remove or deprecate `ci-client-v2/apps/web/src/modules/shell/components/mock/DocsPanel.tsx` (re-export from global-docs if needed temporarily)
- [X] T054 Remove static mock stats from `global-documentacao` entry in `ci-client-v2/apps/web/src/modules/shell/config/screens.ts` (dynamic counts or omit)
- [X] T055 Run `npm test -- --testPathPatterns=global-docs` in `ci-api-v2` and `npm test -- global-docs` in `ci-client-v2/apps/web`
- [X] T056 Validate all scenarios in `civ2-docs/specs/023-global-docs/quickstart.md`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **Foundational (Phase 2)**: Depends on Setup — **BLOCKS all user stories**
- **US1 (Phase 3)**: Depends on Foundational (API list + seed + client API)
- **US2 (Phase 4)**: Depends on Foundational; integrates with US1 navigation
- **US4 (Phase 5)**: Depends on Foundational seed file; validates before demo
- **US3 (Phase 6)**: Depends on US1 page existing
- **US5 (Phase 7)**: Depends on US2 `DocStepList` + Foundational API
- **Polish (Phase 8)**: Depends on US1–US5 complete

### User Story Dependencies

| Story | Depends on | Independent test |
|-------|------------|------------------|
| US1 | Foundational | List central from API |
| US2 | Foundational | Detail + steps |
| US4 | Foundational (seed) | Count ≥2/module |
| US3 | US1 | Filters on list page |
| US5 | US2 components + API | Module contextual panel |

### Parallel Opportunities

**Phase 2** (after T005 migration):

```text
T006 schemas ∥ T007 mapper spec ∥ T021 client schemas spec
T010 repository list ∥ T013 repository find ∥ T023 MSW handlers
```

**Phase 3 US1**:

```text
T025 DocArticleCard ∥ T026 useGlobalDocsList ∥ T024 page test RED
```

**Phase 4 US2**:

```text
T033 DocStepList ∥ T034 useGlobalDocDetail ∥ T032 detail test RED
```

**Cross-story** (after Phase 2):

```text
Developer A: Phase 3 US1 (list UI)
Developer B: Phase 4 US2 (detail UI) — after T027 or in parallel if routes separated
Developer C: Phase 5 US4 (seed validation)
```

---

## Parallel Example: User Story 1

```bash
# RED tests + components in parallel:
T024 GlobalDocumentacaoPage.test.tsx
T025 DocArticleCard.tsx
T026 useGlobalDocsList.ts

# Then integrate:
T027 GlobalDocumentacaoPage.tsx → T028 router → T031 GREEN
```

---

## Implementation Strategy

### MVP First (US1 + Foundational)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (schema, API, seed, client API)
3. Complete Phase 3: US1 — central lista artigos reais
4. **STOP and VALIDATE**: quickstart Cenário 1
5. Demo MVP

### Incremental Delivery

1. Foundational → API + seed ready
2. US1 → list central (MVP)
3. US2 → detail + steps
4. US4 → seed validation locked
5. US3 → filters/search
6. US5 → ModuleDocsPanel
7. Polish → remove all mocks

### Suggested MVP Scope

**US1 only** after Foundational — delivers core desmock value (central real). US2 is co-P1 and should follow immediately for ETP guide value.

---

## Notes

- Total tasks: **56**
- TDD: RED specs before implementation in Phases 2–7
- `[P]` tasks touch different files — safe to parallelize
- Seed (T019–T020) in Foundational enables US1 demo; US4 (T039–T041) validates completeness
- Do not reintroduce `globalUsageDocs` / `moduleProcessGuides` after T052
