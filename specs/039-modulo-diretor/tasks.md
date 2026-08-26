---
description: "Task list for Módulo Diretor (039-modulo-diretor)"
---

# Tasks: Módulo Diretor

**Input**: Design documents from `civ2-docs/specs/039-modulo-diretor/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Tests**: **Obrigatórios** — TDD (Constitution II + plan.md + `contracts/test-strategy.md`): RED → GREEN → REFACTOR. IDs `CT-DIR-NNN` na API.

**Organization**: 5 user stories (US1–US5). Caminhos relativos à raiz `ci-v2/`. Módulo **novo** `diretor` (API + client). Sem Redis; sem `ModuloSlug.diretor`.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Pode executar em paralelo (arquivos diferentes, sem dependências pendentes)
- **[Story]**: User story da spec (US1–US5)

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Fixtures, esqueleto de módulos API/client e barrel exports

- [X] T001 [P] Criar fixtures API `ci-api-v2/src/modules/diretor/test/fixtures/ouvidoria-kpis-response.json` e `diagnostico-kpis-response.json` conforme `contracts/rest-api-diretor.md`
- [X] T002 [P] Criar fixtures API `ci-api-v2/src/modules/diretor/test/fixtures/ouvidoria-acoes-page.json`, `diagnostico-acoes-page.json`, `audit-logs-page.json`, `atores-response.json`
- [X] T003 [P] Criar fixtures client `ci-client-v2/apps/web/src/modules/diretor/fixtures/ouvidoria-kpis.json`, `diagnostico-kpis.json`, `audit-logs-page.json`
- [X] T004 [P] Criar esqueleto `ci-api-v2/src/modules/diretor/diretor.module.ts`, `diretor.controller.ts`, `diretor.constants.ts`, `diretor.types.ts` (exports vazios / controller sem rotas)
- [X] T005 [P] Criar esqueleto client `ci-client-v2/apps/web/src/modules/diretor/index.ts` e pastas `pages/`, `components/`, `api/`, `hooks/`, `lib/`, `constants/`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Migration, schemas Zod, guard AGEMAN, cache, resolução de período, catálogo de telas — **bloqueia US1–US5**

**⚠️ CRITICAL**: Guard + schemas + migration devem estar GREEN antes de qualquer endpoint ou página

### Tests first (TDD — RED)

- [X] T006 [P] Escrever testes (RED) `ci-api-v2/src/modules/diretor/test/diretor.schemas.spec.ts` — CT-DIR-001: happy path; `presetDays` 3/7; inválidos; `limit` 51; default mês atual implícito
- [X] T007 [P] Escrever testes (RED) `ci-api-v2/src/modules/diretor/test/lib/resolve-diretor-period.spec.ts` — CT-DIR-002: calendário UTC; preset substitui calendário; defaults
- [X] T008 [P] Escrever testes (RED) `ci-api-v2/src/modules/diretor/test/guards/diretor-access.guard.spec.ts` — CT-DIR-003: 403 tenant Jacaranda; allow roles AGEMAN; allow e-mail nominado; 403 user comum
- [X] T009 [P] Escrever testes (RED) `ci-client-v2/apps/web/src/modules/diretor/lib/__tests__/can-access-diretor.test.ts` — roles allow; e-mail case-insensitive; user comum negado
- [X] T010 [P] Escrever testes (RED) `ci-client-v2/apps/web/src/modules/diretor/lib/__tests__/resolve-diretor-period.test.ts` — paridade com API

### Schema & migration

- [X] T011 Adicionar `@@index([tenantId, createdAt])` em `ci-api-v2/prisma/schema/audit-log.prisma`
- [X] T012 Gerar migration `ci-api-v2/prisma/migrations/*_diretor_audit_log_created_at/` e aplicar localmente (`npx prisma migrate dev`)

### Implementation for Foundational

- [X] T013 [P] Implementar `ci-api-v2/src/modules/diretor/diretor.constants.ts` — `DIRETOR_ALLOWED_EMAIL`, `AGEMAN_TENANT_ID`, TTL KPIs (90s) e listas (30s)
- [X] T014 [P] Implementar `ci-api-v2/src/modules/diretor/lib/resolve-diretor-period.ts` (GREEN T007)
- [X] T015 [P] Implementar `ci-api-v2/src/modules/diretor/lib/resolve-diretor-actor-email.ts` — lookup por role (`User` / `AdminTenant` / `AdminPlataforma`)
- [X] T016 Implementar `ci-api-v2/src/modules/diretor/diretor.schemas.ts` — query período, paginação, response DTOs Zod v4 + `createZodDto` (GREEN T006)
- [X] T017 Implementar `ci-api-v2/src/modules/diretor/services/diretor-cache.service.ts` — Map+TTL (contrato `SigedCacheService`: `buildKey`, `get`, `set`)
- [X] T018 Implementar `ci-api-v2/src/modules/diretor/guards/diretor-access.guard.ts` — tenant AGEMAN + role OU e-mail (GREEN T008)
- [X] T019 Registrar `DiretorModule` em `ci-api-v2/src/app.module.ts` (após `DiagnosticoModule`); `@UseGuards(DiretorAccessGuard)` no controller
- [X] T020 [P] Adicionar entrada `diretor-dashboard` em `ci-api-v2/src/common/constants/screens.ts` — `moduloSlug: 'global'`, `scope: 'platform'`, título **Visão do Diretor**
- [X] T021 [P] Adicionar `diretor-dashboard` em `ci-client-v2/apps/web/src/modules/shell/config/screens.ts` — path `/diretor`, `module: 'global'`, `type: 'dashboard'`, `licenses: ['base']`
- [X] T022 [P] Adicionar grupo **Diretoria** em `ci-client-v2/apps/web/src/modules/shell/config/navigation.ts` — `outsideModules: true`; item visível só se `canAccessDiretor && isAgemanTenant` (helper no sidebar ou filter)
- [X] T023 [P] Implementar `ci-client-v2/apps/web/src/modules/diretor/lib/can-access-diretor.ts` (GREEN T009)
- [X] T024 [P] Implementar `ci-client-v2/apps/web/src/modules/diretor/lib/resolve-diretor-period.ts` (GREEN T010)
- [X] T025 [P] Implementar `ci-client-v2/apps/web/src/modules/diretor/constants/diretor-cache.ts` — staleTime/gcTime alinhados ao TTL server (90s/30s)
- [X] T026 Registrar lazy override `DIRETOR_OVERRIDES` em `ci-client-v2/apps/web/src/app/router.tsx` → stub `DiretorPage` (403 ou placeholder até US1)

**Checkpoint**: Migration aplicada; guard GREEN; schemas GREEN; tela registrada; rota `/diretor` resolve (stub)

---

## Phase 3: User Story 1 — Panorama do mês corrente (Priority: P1) 🎯 MVP

**Goal**: Usuário autorizado no AGEMAN abre `/diretor` e vê KPIs de Ouvidoria e Diagnóstico do mês/ano atuais, somente leitura

**Independent Test**: Login autorizado AGEMAN → `/diretor` → 6 cards Ouvidoria + estoque Diagnóstico + 2 KPIs locais; zero ações de escrita; operador comum → 403 (`quickstart.md` §1)

### Tests for User Story 1 (TDD — RED first)

- [X] T027 [P] [US1] Escrever testes (RED) `ci-api-v2/src/modules/diretor/test/use-cases/get-ouvidoria-kpis.use-case.spec.ts` — CT-DIR-004: 6 KPIs mês corrente; cache hit; `fresh` bypass
- [X] T028 [P] [US1] Escrever testes (RED) `ci-api-v2/src/modules/diretor/test/use-cases/get-diagnostico-kpis.use-case.spec.ts` — CT-DIR-006: estoque + locais; MySQL down → `estoqueErro` e locais ok
- [X] T029 [P] [US1] Escrever testes (RED) `ci-client-v2/apps/web/src/modules/diretor/api/__tests__/diretor.schemas.test.ts` — parse fixtures KPIs
- [X] T030 [P] [US1] Escrever testes (RED) `ci-client-v2/apps/web/src/modules/diretor/pages/__tests__/DiretorPage.test.tsx` — render KPIs default mês atual; badge Somente leitura; 403 se `canAccessDiretor` false; zero botões de escrita

### Implementation for User Story 1

- [X] T031 [P] [US1] Implementar `ci-api-v2/src/modules/diretor/repository/get-ouvidoria-kpis.repository.ts` — reutilizar lógica de `dashboard.repositories.ts` com intervalo `resolve-diretor-period`
- [X] T032 [US1] Implementar `ci-api-v2/src/modules/diretor/use-cases/get-ouvidoria-kpis.use-case.ts` + cache (GREEN T027)
- [X] T033 [P] [US1] Implementar `ci-api-v2/src/modules/diretor/repository/get-diagnostico-kpis.repository.ts` — estoque via dashboard existente; locais via counts PG (`DiagnosticoProcessoMarcador`, `DocumentoInstitucional`)
- [X] T034 [US1] Implementar `ci-api-v2/src/modules/diretor/use-cases/get-diagnostico-kpis.use-case.ts` — falha MySQL isolada (GREEN T028)
- [X] T035 [US1] Expor `GET /diretor/ouvidoria/kpis` e `GET /diretor/diagnostico/kpis` em `ci-api-v2/src/modules/diretor/diretor.controller.ts`
- [X] T036 [P] [US1] Criar `ci-client-v2/apps/web/src/modules/diretor/api/diretor.schemas.ts` — espelho Zod v3 das responses (comentário de origem API)
- [X] T037 [P] [US1] Criar `ci-client-v2/apps/web/src/modules/diretor/api/diretor.ts` — fetch + parse KPIs
- [X] T038 [P] [US1] Criar hooks `ci-client-v2/apps/web/src/modules/diretor/hooks/use-diretor-ouvidoria-kpis.ts` e `use-diretor-diagnostico-kpis.ts` (React Query + `diretor-cache.ts`)
- [X] T039 [P] [US1] Criar `ci-client-v2/apps/web/src/modules/diretor/components/DiretorOuvidoriaKpiGrid.tsx` — reusar layout de `DashboardStatsCards` (6 cards)
- [X] T040 [P] [US1] Criar `ci-client-v2/apps/web/src/modules/diretor/components/DiretorDiagnosticoKpiGrid.tsx` — 4 estoque + 2 locais; badge **não recorta por data** no estoque
- [X] T041 [US1] Implementar `ci-client-v2/apps/web/src/modules/diretor/pages/DiretorPage.tsx` — header + badge Somente leitura + blocos KPI com loading isolado; `AccessDenied403` se não autorizado; default mês/ano atuais hardcoded (GREEN T030)
- [X] T042 [US1] Atualizar `DIRETOR_OVERRIDES` em `ci-client-v2/apps/web/src/app/router.tsx` com `DiretorPage` real
- [X] T043 [US1] GREEN testes T027–T030; validar contrato manual `curl` conforme `quickstart.md` §1

**Checkpoint**: MVP — `/diretor` funcional com KPIs do mês corrente; acesso bloqueado fora de AGEMAN/papel/e-mail

---

## Phase 4: User Story 2 — Filtro global ano/mês (Priority: P2)

**Goal**: Diretor troca ano/mês e blocos calendário atualizam sem reload total da página

**Independent Test**: Selecionar mês anterior → KPIs mudam; recarregar → volta ao mês atual (`quickstart.md` §2)

**Depends on**: US1 (página e endpoints KPI existem)

### Tests for User Story 2 (TDD — RED first)

- [X] T044 [P] [US2] Estender testes (RED) `get-ouvidoria-kpis.use-case.spec.ts` — KPIs de mês passado explícito (`year`/`month`)
- [X] T045 [P] [US2] Estender testes (RED) `DiretorPage.test.tsx` — troca de mês atualiza query keys; skeleton só no bloco afetado

### Implementation for User Story 2

- [X] T046 [P] [US2] Extrair/adaptar `YearMonthFilters` para `ci-client-v2/apps/web/src/modules/diretor/components/DiretorYearMonthFilters.tsx` (ou reusar de ouvidoria com props)
- [X] T047 [US2] Adicionar estado global ano/mês em `DiretorPage.tsx` — default atuais; passar para hooks KPI e futuro bloco auditoria
- [X] T048 [US2] Wire query keys `use-diretor-*-kpis` ao par `year`/`month`; invalidação ao mudar filtro (GREEN T045)
- [X] T049 [US2] Empty state quando mês sem movimento — cards zero sem erro

**Checkpoint**: Filtro calendário global funcional; presets ainda ausentes (US3)

---

## Phase 5: User Story 3 — Presets 7 / 3 dias por bloco (Priority: P2)

**Goal**: Cada bloco de módulo pode usar últimos 7 ou 3 dias, substituindo temporariamente o calendário **naquele bloco**

**Independent Test**: Preset só em Ouvidoria → Diagnóstico permanece no mês; desligar preset → volta ao calendário; estoque Diagnóstico não muda (`quickstart.md` §3)

**Depends on**: US2 (filtro global existe como fallback)

### Tests for User Story 3 (TDD — RED first)

- [X] T050 [P] [US3] Estender testes (RED) `get-ouvidoria-kpis.use-case.spec.ts` — janela 7 dias via `presetDays`
- [X] T051 [P] [US3] Estender testes (RED) `get-diagnostico-kpis.use-case.spec.ts` — `locais` recortados; `estoque` inalterado com preset
- [X] T052 [P] [US3] Estender testes (RED) `DiretorPage.test.tsx` — preset ativo só no bloco clicado; toggle desliga

### Implementation for User Story 3

- [X] T053 [P] [US3] Criar `ci-client-v2/apps/web/src/modules/diretor/components/DiretorPeriodPresetToggle.tsx` — toggles 7d / 3d / off (um ativo por bloco)
- [X] T054 [US3] Estado `presetDays` por bloco (`ouvidoria` | `diagnostico`) em `DiretorPage.tsx`; passar `presetDays` nas queries quando ativo (ignora calendário no client e server)
- [X] T055 [US3] Atualizar hooks KPI para incluir `presetDays` opcional na query key e params (GREEN T050–T052)
- [X] T056 [US3] Reforçar copy/badge no bloco Diagnóstico estoque quando preset ativo — **não recorta por data**

**Checkpoint**: Recortes operacionais 7/3 dias por bloco; auditoria ainda no calendário global

---

## Phase 6: User Story 4 — Ações por pessoa dentro do módulo (Priority: P3)

**Goal**: Filtrar e listar ações de usuários no período vigente de cada bloco (Ouvidoria + Diagnóstico local)

**Independent Test**: Select de pessoa → lista filtrada; empty se sem ações; preset + pessoa combinam (`quickstart.md` §4)

**Depends on**: US3 (período por bloco definido)

### Tests for User Story 4 (TDD — RED first)

- [X] T057 [P] [US4] Escrever testes (RED) `ci-api-v2/src/modules/diretor/test/use-cases/list-ouvidoria-acoes.use-case.spec.ts` — CT-DIR-005: paginação; `autorUserId`; vazio
- [X] T058 [P] [US4] Escrever testes (RED) `ci-api-v2/src/modules/diretor/test/use-cases/list-diagnostico-acoes.use-case.spec.ts` — CT-DIR-007: marcadores; filtro autor
- [X] T059 [P] [US4] Escrever testes (RED) `ci-api-v2/src/modules/diretor/test/use-cases/list-atores.use-case.spec.ts` — distinct autores no período
- [X] T060 [P] [US4] Estender testes (RED) `DiretorPage.test.tsx` — select pessoa filtra lista; empty state

### Implementation for User Story 4

- [X] T061 [P] [US4] Implementar `ci-api-v2/src/modules/diretor/repository/list-ouvidoria-acoes.repository.ts` — espelhar `list-auditoria.repository.ts` / `ManifestacaoEvento`
- [X] T062 [US4] Implementar `ci-api-v2/src/modules/diretor/use-cases/list-ouvidoria-acoes.use-case.ts` (GREEN T057)
- [X] T063 [P] [US4] Implementar `ci-api-v2/src/modules/diretor/repository/list-diagnostico-acoes.repository.ts` — `DiagnosticoProcessoMarcador`
- [X] T064 [US4] Implementar `ci-api-v2/src/modules/diretor/use-cases/list-diagnostico-acoes.use-case.ts` (GREEN T058)
- [X] T065 [US4] Implementar `ci-api-v2/src/modules/diretor/use-cases/list-atores.use-case.ts` + repository (GREEN T059)
- [X] T066 [US4] Expor `GET /diretor/ouvidoria/acoes`, `GET /diretor/diagnostico/acoes`, `GET /diretor/atores` em `diretor.controller.ts`
- [X] T067 [P] [US4] Estender `ci-client-v2/apps/web/src/modules/diretor/api/diretor.ts` e schemas — ações paginadas + atores
- [X] T068 [P] [US4] Criar hooks `use-diretor-ouvidoria-acoes.ts`, `use-diretor-diagnostico-acoes.ts`, `use-diretor-atores.ts`
- [X] T069 [P] [US4] Criar `ci-client-v2/apps/web/src/modules/diretor/components/DiretorActorSelect.tsx` — alimentado por `GET /diretor/atores?modulo=`
- [X] T070 [P] [US4] Criar `ci-client-v2/apps/web/src/modules/diretor/components/DiretorAcoesList.tsx` — tabela compacta paginada
- [X] T071 [US4] Integrar select + lista em cada bloco de módulo em `DiretorPage.tsx` (GREEN T060)

**Checkpoint**: Rastro operacional por pessoa nos dois módulos

---

## Phase 7: User Story 5 — Auditoria geral da plataforma (Priority: P3)

**Goal**: Bloco paginado de `AuditLog` recortado pelo ano/mês global; independente dos presets 7/3 dias

**Independent Test**: Bloco carrega após KPIs; paginar sem travar; preset em Ouvidoria não altera auditoria (`quickstart.md` §5)

**Depends on**: US2 (filtro calendário global); pode desenvolver API em paralelo após Phase 2

### Tests for User Story 5 (TDD — RED first)

- [X] T072 [P] [US5] Escrever testes (RED) `ci-api-v2/src/modules/diretor/test/use-cases/list-audit-logs.use-case.spec.ts` — CT-DIR-008: mês; paginação `{items,total,page,limit}`; actor via `userId` e `payload.actorId`; ignora `presetDays`
- [X] T073 [P] [US5] Estender testes (RED) `DiretorPage.test.tsx` — bloco auditoria lazy; paginação; sem controles de escrita

### Implementation for User Story 5

- [X] T074 [P] [US5] Implementar `ci-api-v2/src/modules/diretor/repository/list-audit-logs.repository.ts` — query `AuditLog` com índice `(tenantId, createdAt)`
- [X] T075 [US5] Implementar `ci-api-v2/src/modules/diretor/use-cases/list-audit-logs.use-case.ts` — resolver `actor` (GREEN T072)
- [X] T076 [US5] Expor `GET /diretor/audit-logs` em `diretor.controller.ts`
- [X] T077 [P] [US5] Estender `ci-client-v2/apps/web/src/modules/diretor/api/diretor.ts` e schemas — audit logs paginados
- [X] T078 [P] [US5] Criar hook `ci-client-v2/apps/web/src/modules/diretor/hooks/use-diretor-audit-logs.ts`
- [X] T079 [US5] Criar `ci-client-v2/apps/web/src/modules/diretor/components/DiretorAuditLogBlock.tsx` — lazy/chunk após KPIs; paginação; **somente** `year`/`month` global
- [X] T080 [US5] Integrar bloco em `DiretorPage.tsx` (GREEN T073)

**Checkpoint**: Visão completa spec — KPIs + ações + auditoria geral

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Performance, refresh, E2E opcional, validação final

- [X] T081 [P] Adicionar botão **Atualizar** em `DiretorPage.tsx` — `fresh=1` + `queryClient.invalidateQueries` para todos os blocos
- [X] T082 [P] Assert `diretor.controller.ts` expõe **somente** métodos GET — teste em `ci-api-v2/src/modules/diretor/test/diretor.controller.spec.ts`
- [X] T083 [P] Filtrar item nav Diretoria para não-AGEMAN em `AppSidebar.tsx` (ou helper dedicado) — evitar item visível + 403
- [X] T084 Executar suíte completa: `cd ci-api-v2; npm test -- --testPathPatterns=diretor` e `cd ci-client-v2/apps/web; npm test -- diretor`
- [ ] T085 Validar manualmente `quickstart.md` end-to-end no tenant AGEMAN
- [ ] T086 [P] (Opcional) E2E Playwright `ci-client-v2/e2e/specs/diretor-ageman.e2e.spec.ts` — login autorizado vs operador comum

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Sem dependências — pode iniciar imediatamente
- **Foundational (Phase 2)**: Depende de Setup — **BLOQUEIA** US1–US5
- **US1 (Phase 3)**: Depende de Foundational — **MVP**
- **US2 (Phase 4)**: Depende de US1 (página + KPIs)
- **US3 (Phase 5)**: Depende de US2 (calendário como fallback)
- **US4 (Phase 6)**: Depende de US3 (período por bloco)
- **US5 (Phase 7)**: API após Foundational; UI após US2 (precisa filtro global). Pode paralelizar backend US5 com US3/US4
- **Polish (Phase 8)**: Depois de US1–US5 desejadas

### User Story Dependencies

| Story | Depende de | Independente quando |
| --- | --- | --- |
| US1 | Phase 2 | KPIs mês corrente + 403 |
| US2 | US1 | Filtro ano/mês |
| US3 | US2 | Presets por bloco |
| US4 | US3 | Ações + filtro pessoa |
| US5 | US2 (UI); Phase 2 (API) | Auditoria paginada |

### Parallel Opportunities

- **Phase 1**: T001–T005 todos [P]
- **Phase 2 RED**: T006–T010 [P]; depois T013–T015 [P]; T020–T025 [P]
- **US1**: T027–T029 [P] RED; T031+T033 [P] repos; T036–T040 [P] client
- **US4**: T057–T059 [P]; T061+T063 [P] repos; T067–T070 [P] client
- **US5 backend** pode rodar em paralelo com US3/US4 client após Phase 2

### Parallel Example: User Story 1

```bash
# RED tests em paralelo:
T027 get-ouvidoria-kpis.use-case.spec.ts
T028 get-diagnostico-kpis.use-case.spec.ts
T029 diretor.schemas.test.ts
T030 DiretorPage.test.tsx

# Repos + componentes client em paralelo (após use-cases):
T039 DiretorOuvidoriaKpiGrid.tsx
T040 DiretorDiagnosticoKpiGrid.tsx
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Phase 1: Setup
2. Phase 2: Foundational (**crítico**)
3. Phase 3: US1
4. **STOP and VALIDATE** — `quickstart.md` §1
5. Demo para diretor AGEMAN

### Incremental Delivery

1. Setup + Foundational → infra pronta
2. US1 → MVP KPIs mês corrente
3. US2 → filtro histórico mensal
4. US3 → recortes 7/3 dias
5. US4 → accountability por pessoa
6. US5 → auditoria plataforma
7. Polish → refresh, E2E, sidebar

### Parallel Team Strategy

| Dev | Fase | Entrega |
| --- | --- | --- |
| A | Phase 2 + US1 API | Endpoints KPI + guard |
| B | Phase 2 client + US1 UI | Página + cards |
| C | US5 API (após Phase 2) | Audit logs |
| — | US2–US4 sequencial ou B continua | Filtros e listas |

---

## Notes

- **Não** adicionar `diretor` a `MODULO_SLUGS` nem `ModuloPermissaoGuard`
- E-mail nominado só em `diretor.constants.ts` — lookup no guard, não no JWT
- `admin_saas` na API: aceito com header AGEMAN; sem tela em `admin-saas` (research R2)
- Reusar agregações existentes — não inventar fórmulas KPI novas (FR-006)
- Commit após cada task ou grupo lógico; parar em qualquer checkpoint para validar story independente
