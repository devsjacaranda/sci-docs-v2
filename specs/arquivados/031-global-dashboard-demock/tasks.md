---
description: "Task list for Desmock do Dashboard Global (031-global-dashboard-demock)"
---

# Tasks: Desmock do Dashboard Global

**Input**: Design documents from `civ2-docs/specs/031-global-dashboard-demock/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Tests**: **Obrigatórios** — TDD (constitution II + plan.md + `contracts/test-strategy.md`): Jest unit API, Vitest/RTL client. **Sem migration**; **sem Postgres de teste dedicado**.

**Organization**: 5 user stories (US1–US5). Caminhos relativos à raiz `ci-v2/`.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Pode executar em paralelo (arquivos diferentes, sem dependências pendentes)
- **[Story]**: User story da spec (US1–US5)

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Verificar artefatos existentes e preparar estrutura de módulos

- [X] T001 Verificar componente mock atual em `ci-client-v2/apps/web/src/modules/shell/components/mock/GlobalWelcomeDashboard.tsx` e KPIs estáticos em `ci-client-v2/apps/web/src/modules/shell/config/screens.ts` (`global-dashboard.stats`)
- [X] T002 [P] Criar estrutura de diretórios API em `ci-api-v2/src/modules/global-dashboard/` (controller, schemas, mapper, repository, use-cases, test/fixtures)
- [X] T003 [P] Criar estrutura de diretórios client em `ci-client-v2/apps/web/src/modules/global/` (api, hooks, lib, components, index.ts)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: BFF `GET /global/dashboard` + infra client compartilhada — **bloqueia US2 e US3**

**⚠️ CRITICAL**: KPIs, feed e gráfico dependem desta fase; US1 (perfil) pode iniciar em paralelo após Phase 1

### Tests first — API (TDD RED)

- [X] T004 [P] Escrever testes (RED) `global-dashboard.schemas.spec.ts` em `ci-api-v2/src/modules/global-dashboard/test/global-dashboard.schemas.spec.ts` — CT-GD-001, CT-GD-002
- [X] T005 [P] Criar fixture `global-dashboard-empty.json` em `ci-api-v2/src/modules/global-dashboard/test/fixtures/global-dashboard-empty.json` — CT-GD-010
- [X] T006 Escrever testes (RED) `get-global-dashboard.use-case.spec.ts` em `ci-api-v2/src/modules/global-dashboard/test/use-cases/get-global-dashboard.use-case.spec.ts` — CT-GD-003..009

### Implementation — API (GREEN)

- [X] T007 Implementar `globalDashboardQuerySchema` e tipos de response em `ci-api-v2/src/modules/global-dashboard/global-dashboard.schemas.ts` (GREEN T004, T005)
- [X] T008 Implementar agregações Prisma paralelas em `ci-api-v2/src/modules/global-dashboard/repository/get-global-dashboard.repository.ts` (pendentes, atrasadas, ouvidoria high/urgent, eventos 24h, feed, bySourceModule)
- [X] T009 Implementar mapeamento evento→activity e KPI mock fixo em `ci-api-v2/src/modules/global-dashboard/global-dashboard.mapper.ts`
- [X] T010 Implementar `GetGlobalDashboardUseCase` com flag `meta.includesOuvidoria` em `ci-api-v2/src/modules/global-dashboard/use-cases/get-global-dashboard.use-case.ts` (GREEN T006)
- [X] T011 Implementar controller `GET /global/dashboard` e module em `ci-api-v2/src/modules/global-dashboard/global-dashboard.controller.ts` e `global-dashboard.module.ts`
- [X] T012 Registrar `GlobalDashboardModule` em `ci-api-v2/src/app.module.ts` e confirmar testes API GREEN

### Tests first — Client infra (TDD RED)

- [X] T013 [P] Escrever testes (RED) mappers em `ci-client-v2/apps/web/src/modules/global/lib/__tests__/global-dashboard-mappers.test.ts` — CT-GD-UI-006

### Implementation — Client infra (GREEN)

- [X] T014 [P] Implementar `MockDataBadge` em `ci-client-v2/apps/web/src/modules/shared/components/MockDataBadge.tsx` (tooltip PT-BR, variant outline)
- [X] T015 [P] Implementar client API `getGlobalDashboard` em `ci-client-v2/apps/web/src/modules/global/api/global-dashboard.ts` alinhado a `contracts/rest-api-global-dashboard.md`
- [X] T016 Implementar mappers (`isMock`, `timeLabel`, filtro licença barras) em `ci-client-v2/apps/web/src/modules/global/lib/global-dashboard-mappers.ts` (GREEN T013)
- [X] T017 Implementar hook `useGlobalDashboard` (loading, error, refetch) em `ci-client-v2/apps/web/src/modules/global/hooks/useGlobalDashboard.ts`

**Checkpoint**: `GET /global/dashboard` retorna KPIs + feed + chart; client hook fetch funcional; MockDataBadge pronto

---

## Phase 3: User Story 1 — Perfil e identidade real (Priority: P1) 🎯 MVP

**Goal**: Hero da home exibe nome, cargo e avatar exclusivamente da sessão autenticada — sem `loadProfile()` / admin-mock

**Independent Test**: Login com usuários distintos; `/global/dashboard` reflete `/auth/me`; branding tenant inalterado (CT-UI-006/007)

### Tests for User Story 1 (TDD — RED first)

- [X] T018 [P] [US1] Escrever/migrar testes (RED) em `ci-client-v2/apps/web/src/modules/global/components/__tests__/GlobalWelcomeDashboard.test.tsx` — CT-GD-UI-001 + branding CT-UI-006/007 (sem `loadProfile`)

### Implementation for User Story 1

- [X] T019 [P] [US1] Mover componente para `ci-client-v2/apps/web/src/modules/global/components/GlobalWelcomeDashboard.tsx` (copiar de shell/mock e ajustar imports)
- [X] T020 [US1] Remover `loadProfile()` e usar apenas `useAuth().user` para nome, cargo e avatar em `ci-client-v2/apps/web/src/modules/global/components/GlobalWelcomeDashboard.tsx` (GREEN T018)
- [X] T021 [US1] Atualizar import em `ci-client-v2/apps/web/src/modules/shell/pages/ScreenPage.tsx` para `@/modules/global/components/GlobalWelcomeDashboard`
- [X] T022 [US1] Exportar barrel em `ci-client-v2/apps/web/src/modules/global/index.ts`

**Checkpoint**: MVP client — hero + branding reais; KPIs/feed ainda podem ser estáticos até US2/US3

---

## Phase 4: User Story 4 — Transparência Mock (Priority: P1)

**Goal**: Badge **Mock** visível em blocos com `source: 'mock'`; blocos reais sem badge

**Independent Test**: Inspecionar home — KPI mock rotulado; KPIs reais sem badge (SC-005)

### Tests for User Story 4 (TDD — RED first)

- [X] T023 [P] [US4] Estender testes (RED) badge mock vs real em `ci-client-v2/apps/web/src/modules/global/components/__tests__/GlobalWelcomeDashboard.test.tsx` — CT-GD-UI-002, CT-GD-UI-003

### Implementation for User Story 4

- [X] T024 [US4] Integrar `MockDataBadge` no header de KPI quando `kpi.source === 'mock'` em `ci-client-v2/apps/web/src/modules/global/components/GlobalWelcomeDashboard.tsx` (GREEN T023)

**Checkpoint**: Padrão visual Mock documentado e testado (US4 parcial — gráfico mock badge em US3 se aplicável)

---

## Phase 5: User Story 2 — KPIs operacionais reais (Priority: P1)

**Goal**: Substituir 4 KPIs estáticos por dados de `GET /global/dashboard`; empty state honesto; 1 KPI mock rotulado

**Independent Test**: Tenant com seed — pendentes/prioritárias/24h coerentes; tenant vazio → zeros; "Registros ativos" com badge Mock

### Tests for User Story 2 (TDD — RED first)

- [X] T025 [P] [US2] Estender testes (RED) render KPIs da API e empty state em `ci-client-v2/apps/web/src/modules/global/components/__tests__/GlobalWelcomeDashboard.test.tsx` — CT-GD-UI-002, CT-GD-UI-003, CT-GD-UI-005

### Implementation for User Story 2

- [X] T026 [US2] Substituir loop `screens['global-dashboard'].stats` por `dashboard.kpis` do hook em `ci-client-v2/apps/web/src/modules/global/components/GlobalWelcomeDashboard.tsx` (GREEN T025)
- [X] T027 [US2] Remover array `stats` de `global-dashboard` em `ci-client-v2/apps/web/src/modules/shell/config/screens.ts`
- [X] T028 [US2] Adicionar skeleton loading e error state nos KPIs (sem fallback mock) em `ci-client-v2/apps/web/src/modules/global/components/GlobalWelcomeDashboard.tsx`

**Checkpoint**: 3 KPIs reais + 1 mock rotulado; nenhum número seed fixo (FR-003, SC-003)

---

## Phase 6: User Story 3 — Atividade recente e gráfico (Priority: P2)

**Goal**: Feed de eventos reais com links; gráfico "Demandas linked por módulo de origem" com dados API

**Independent Test**: Encaminhar demanda → item no feed com link; gráfico com barras do seed; filtro licença filtra barras

### Tests for User Story 3 (TDD — RED first)

- [X] T029 [P] [US3] Escrever testes (RED) feed com link e error sem mock em `ci-client-v2/apps/web/src/modules/global/components/__tests__/GlobalWelcomeDashboard.test.tsx` — CT-GD-UI-004, CT-GD-UI-005
- [X] T030 [P] [US3] Escrever teste (RED) filtro licença no gráfico em `ci-client-v2/apps/web/src/modules/global/lib/__tests__/global-dashboard-mappers.test.ts` — CT-GD-UI-007

### Implementation for User Story 3

- [X] T031 [US3] Substituir `welcomeActivities` por `dashboard.recentActivity` com `<Link>` quando `navigationPath` em `ci-client-v2/apps/web/src/modules/global/components/GlobalWelcomeDashboard.tsx` (GREEN T029)
- [X] T032 [US3] Substituir dados inline do `GenericBarChart` por `chart.data` + título dinâmico + filtro licença em `ci-client-v2/apps/web/src/modules/global/components/GlobalWelcomeDashboard.tsx` (GREEN T030)
- [X] T033 [US3] Remover export/uso de `welcomeActivities` da home (manter `getGreeting` e atalhos) em `ci-client-v2/apps/web/src/modules/shell/lib/welcome-shortcuts.ts`

**Checkpoint**: Feed + gráfico desmockados; atividade clicável (FR-005, FR-006, FR-007)

---

## Phase 7: User Story 5 — Atalhos e continuidade (Priority: P3)

**Goal**: Atalhos e "Continuar no módulo" inalterados; sem regressão de permissões/licença

**Independent Test**: Navegar módulo → voltar home → continuar; filtro restritivo → empty state atalhos

### Implementation for User Story 5

- [X] T034 [P] [US5] Adicionar teste de regressão atalhos filtrados por permissão em `ci-client-v2/apps/web/src/modules/global/components/__tests__/GlobalWelcomeDashboard.test.tsx`
- [X] T035 [US5] Validar manualmente atalhos + `RecentAccessContext` conforme cenários US5 em `civ2-docs/specs/031-global-dashboard-demock/quickstart.md`

**Checkpoint**: Nenhuma regressão em navegação rápida (FR-013)

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Limpeza, validação end-to-end e inventário final

- [X] T036 [P] Remover arquivo legado `ci-client-v2/apps/web/src/modules/shell/components/mock/GlobalWelcomeDashboard.tsx` após migração confirmada
- [X] T037 [P] Remover ou redirecionar teste legado `ci-client-v2/apps/web/src/modules/shell/components/mock/__tests__/GlobalWelcomeDashboard.branding.test.tsx`
- [X] T038 Executar `npm test -- --testPathPatterns=global-dashboard` em `ci-api-v2/` e `npm test -- global-dashboard` em `ci-client-v2/apps/web/`
- [X] T039 Executar checklist completo em `civ2-docs/specs/031-global-dashboard-demock/quickstart.md` e confirmar inventário em `civ2-docs/specs/031-global-dashboard-demock/data-model.md`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Sem dependências — iniciar imediatamente
- **Foundational (Phase 2)**: Depende Setup — **bloqueia US2 e US3**
- **US1 (Phase 3)**: Depende Setup — **pode paralelizar com Phase 2** (MVP client-only)
- **US4 (Phase 4)**: Depende T014 (MockDataBadge) + T019 (componente movido)
- **US2 (Phase 5)**: Depende Phase 2 completa + US4 T024
- **US3 (Phase 6)**: Depende Phase 2 + US2 recomendado (mesmo componente)
- **US5 (Phase 7)**: Depende US1 (componente estável)
- **Polish (Phase 8)**: Depende US1–US5 desejados

### User Story Dependencies

| Story | Depende de | Independente quando |
| --- | --- | --- |
| US1 | Phase 1 | Hero/branding sem API |
| US2 | Phase 2, US4 | KPIs via API |
| US3 | Phase 2 | Feed + gráfico via API |
| US4 | T014, US1 move | Badge isolado testável |
| US5 | US1 | Regressão atalhos |

### Parallel Opportunities

```text
# Após Phase 1 — trilha MVP (US1) vs trilha API (Phase 2):
T018–T022 [US1]  ||  T004–T012 [API Foundational]

# Dentro Phase 2:
T004, T005, T013, T014, T015 em paralelo

# Após Phase 2 GREEN:
T025 [US2] || T029 [US3] (mesmo arquivo — sequencial preferível)

# Polish:
T036, T037 em paralelo
```

---

## Parallel Example: MVP (US1 + API)

```bash
# Dev A — MVP hero real (sem esperar API):
T019 → T020 → T021 → T022 → T018 (TDD)

# Dev B — BFF dashboard:
T004 → T007 → T008 → T009 → T010 → T011 → T012

# Dev C — Client infra:
T014 → T015 → T016 → T017 → T013
```

---

## Implementation Strategy

### MVP First (User Story 1)

1. Phase 1: Setup
2. Phase 3: US1 — perfil 100% sessão
3. **STOP and VALIDATE**: quickstart §1 (perfil + branding)
4. Continuar Phase 2 → US2 → US4 → US3

### Incremental Delivery

1. Setup + US1 → hero confiável (demo parcial)
2. + Phase 2 + US2 + US4 → KPIs reais + mock honesto
3. + US3 → feed + gráfico operacionais
4. + US5 + Polish → regressão + limpeza

### Suggested MVP Scope

**US1 apenas** entrega valor imediato (credibilidade da sessão). **US1 + US2 + US4** entrega critérios SC-002, SC-003, SC-006 da spec.

---

## Task Summary

| Fase | Tasks | Story |
| --- | --- | --- |
| Setup | T001–T003 (3) | — |
| Foundational | T004–T017 (14) | — |
| US1 Perfil | T018–T022 (5) | US1 |
| US4 Mock badge | T023–T024 (2) | US4 |
| US2 KPIs | T025–T028 (4) | US2 |
| US3 Feed/gráfico | T029–T033 (5) | US3 |
| US5 Atalhos | T034–T035 (2) | US5 |
| Polish | T036–T039 (4) | — |
| **Total** | **39 tasks** | |

---

## Notes

- TDD: testes RED antes de implementação em cada fase
- Nunca fallback silencioso para mock em erro de API (FR-012)
- `active_records_cross` permanece `source: 'mock'` até spec futura
- Notificações no feed: best-effort se `ListNotificacoesRepository` disponível
- Commit sugerido após cada checkpoint de fase
