# Implementation Plan: Desmock do Dashboard Global

**Branch**: `031-global-dashboard-demock` | **Date**: 2026-07-02 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/031-global-dashboard-demock/spec.md`

## Summary

A home `/global/dashboard` (`GlobalWelcomeDashboard`) mistura dados reais (branding tenant, auth parcial, atalhos, histórico) com mocks estáticos (KPIs em `screens.ts`, `welcomeActivities`, gráfico inline, `loadProfile()`).

**Abordagem**: novo módulo API `global-dashboard` com `GET /global/dashboard` agregando tramitação + ouvidoria + notificações; client em `modules/global/` com hook, mappers e `MockDataBadge`; remover dependências mock na home; inventário final documentado em [data-model.md](./data-model.md).

**Escopo**: apenas home global — fora: dashboards de módulos, redesign layout, modo offline legacy.

## Technical Context

**Language/Version**: TypeScript 5.x / 6.x; Node.js 20 LTS

**Primary Dependencies**:

| Pacote | Stack |
| --- | --- |
| **ci-api-v2** | NestJS 11, Fastify, Pino, Zod, Prisma 7, PostgreSQL |
| **ci-client-v2** | React 19, Vite 8, Tailwind v4, shadcn/ui, Nivo, react-router-dom 7, Vitest 3 |

**Storage**: PostgreSQL — entidades existentes (`TramitacaoDemanda`, `TramitacaoDemandaEvento`, `Manifestacao`, `Notificacao`); **sem migration**

**Testing**: Jest unit + integration (`ci-api-v2`); Vitest/RTL (`ci-client-v2`) — [test-strategy.md](./contracts/test-strategy.md)

**Target Platform**: API Linux/container; SPA browser (`@ci/web`)

**Project Type**: Full-stack feature (novo endpoint BFF + wiring client)

**Performance Goals**: Home hero/branding < 2s percebido (SC-007); `GET /global/dashboard` < 500ms p95 em tenant demo

**Constraints**:

- TDD obrigatório RED → GREEN → REFACTOR
- Zod only — `globalDashboardQuerySchema`, response schema para fixtures
- Tenant AsyncLocalStorage — nunca passar `tenantId` manual
- Sem fallback silencioso para mock em erro de API (FR-012)
- Copy PT-BR [regras-plataforma.md](../../../.cursor/docs/regras-plataforma.md); paleta mint-palette
- `MockDataBadge` discreto mas legível (SC-005)
- Reuso labels `moduleLabel()` tramitação; notificações via repo existente

**Scale/Scope**: 1 endpoint novo; ~1 módulo API; domínio client `global/`; 1 componente refatorado; ~18 arquivos tocados

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Princípio | Status | Notas |
| --- | --- | --- |
| I. Spec-Driven | ✅ PASS | Spec 031 + checklist validados |
| II. Test-First | ✅ PASS | CT-GD-001..010, CT-GD-UI-001..007 |
| III. Stack fixa | ✅ PASS | NestJS 11 + Prisma 7 + React 19 + Vite 8 |
| IV. Multi-tenant | ✅ PASS | Queries tenant-scoped via Prisma extensions |
| IV. Licenças | ✅ PASS | Filtro licença client-side no gráfico; ouvidoria condicional na API |
| V. Escopo mínimo | ✅ PASS | BFF único; reuso repos tramitação/notificação |

**Post-design re-check**: Sem novas entidades Prisma. Módulo `global-dashboard` justificado vs. múltiplas chamadas client (research R1). Sem Complexity Tracking necessário.

## Project Structure

### Documentation (this feature)

```text
civ2-docs/specs/031-global-dashboard-demock/
├── plan.md              # This file
├── research.md          # Phase 0
├── data-model.md        # Phase 1
├── quickstart.md        # Phase 1
├── contracts/
│   ├── rest-api-global-dashboard.md
│   ├── client-global-dashboard-ui.md
│   └── test-strategy.md
└── tasks.md             # Phase 2 — /speckit-tasks
```

### Source Code (repository root)

```text
ci-api-v2/
├── src/app.module.ts                              # IMPORT GlobalDashboardModule
└── src/modules/global-dashboard/
    ├── global-dashboard.module.ts
    ├── global-dashboard.controller.ts
    ├── global-dashboard.schemas.ts
    ├── global-dashboard.mapper.ts
    ├── repository/get-global-dashboard.repository.ts
    ├── use-cases/get-global-dashboard.use-case.ts
    └── test/
        ├── global-dashboard.schemas.spec.ts
        ├── use-cases/get-global-dashboard.use-case.spec.ts
        └── fixtures/global-dashboard-empty.json

ci-client-v2/apps/web/src/
├── modules/global/
│   ├── api/global-dashboard.ts
│   ├── hooks/useGlobalDashboard.ts
│   ├── lib/global-dashboard-mappers.ts
│   ├── lib/__tests__/global-dashboard-mappers.test.ts
│   ├── components/GlobalWelcomeDashboard.tsx      # MOVIDO de shell/mock
│   ├── components/__tests__/GlobalWelcomeDashboard.test.tsx
│   └── index.ts
├── modules/shared/components/MockDataBadge.tsx
├── modules/shell/
│   ├── config/screens.ts                          # REMOVE stats global-dashboard
│   └── pages/ScreenPage.tsx                         # UPDATE import path
└── modules/shell/lib/welcome-shortcuts.ts           # REMOVE welcomeActivities export usage (manter getGreeting)
```

**Structure Decision**: Domínio espelho `global/` no client; API isolada em `global-dashboard/` (distinto de `global-docs/`). Componente sai de `shell/components/mock/`.

## Implementation Phases

### Phase A — API BFF (P1 US2, US3)

1. Scaffold `global-dashboard` module (controller, schemas, repository, use case)
2. Agregações Prisma paralelas:
   - Pendentes / atrasadas (tramitação)
   - Manifestações high/urgent (ouvidoria, se permitido)
   - Eventos 24h + últimos 8 eventos (feed)
   - `bySourceModule` (gráfico)
3. KPI `active_records_cross` fixo `source: 'mock'`
4. Mapper evento → activity item com `navigationPath`
5. Registrar módulo; testes CT-GD-001..010

### Phase B — Client perfil + infra (P1 US1)

1. Criar `modules/global/api` + hook `useGlobalDashboard`
2. Mappers + testes CT-GD-UI-006
3. `MockDataBadge` em shared
4. Mover/refatorar `GlobalWelcomeDashboard`:
   - Remover `loadProfile()`
   - Hero 100% `useAuth().user`
5. Atualizar `ScreenPage` import

### Phase C — Wiring KPIs, feed, gráfico (P1 US2–4, P2 US3)

1. Substituir KPI loop por dados API + badges mock
2. Substituir `welcomeActivities` por feed API com links
3. Gráfico com `chart.data` + título API; filtro licença
4. Remover `stats` de `screens.ts`
5. Loading skeleton + error state (sem mock fallback)
6. Testes CT-GD-UI-001..005; migrar branding tests

### Phase D — Validação

1. Executar [quickstart.md](./quickstart.md)
2. Confirmar inventário final (data-model § Inventário)
3. `/speckit-tasks` → implementação

## Artifact Index

| Artefato | Path |
| --- | --- |
| Research | [research.md](./research.md) |
| Data model | [data-model.md](./data-model.md) |
| REST contract | [contracts/rest-api-global-dashboard.md](./contracts/rest-api-global-dashboard.md) |
| Client contract | [contracts/client-global-dashboard-ui.md](./contracts/client-global-dashboard-ui.md) |
| Test strategy | [contracts/test-strategy.md](./contracts/test-strategy.md) |
| Quickstart | [quickstart.md](./quickstart.md) |

## Risks & Mitigations

| Risco | Mitigação |
| --- | --- |
| Latência agregação | Queries paralelas `Promise.all`; índices existentes em eventos |
| Notificações spec 029 incompleta | Feed primário = eventos tramitação; notificações best-effort |
| Permissão ouvidoria heterogênea | Flag `meta.includesOuvidoria`; KPI degradado gracefully |
| Regressão atalhos | Não alterar `welcomeShortcuts` / filtros existentes |
