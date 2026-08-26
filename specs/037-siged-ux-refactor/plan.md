# Implementation Plan: Refactor UX do SIGED — Diretorias Agrupadas, Home e Licenças Jatobá/Cedro

**Branch**: `037-siged-ux-refactor` | **Date**: 2026-08-10 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/037-siged-ux-refactor/spec.md`

## Summary

Refatorar o módulo `/siged` (consulta read-only ao SIGED municipal) de **exibição bruta achatada** para uma experiência hierárquica e orientada a controle interno:

1. **P1** — Diretorias de topo + drill-down de departamentos (substituir grade achatada)
2. **P2** — Home com post-its automáticos (KPIs + resumo Cedro)
3. **P3** — Fiscalização Jatobá dedicada (`/siged/auditoria`) com regras de tramitação/prazo/parado
4. **P4** — Insights Cedro dedicados (`/siged/insights`) com volume, tempo médio e gargalos

**Gap atual**: `/siged` abre grade com todos os órgãos (`flattenDepartamentosAtivos`); sem Home, sem fiscalização/insights SIGED; dados SIGED só live (cache minutos) — impossibilita tendências (FR-028).

**API** (`ci-api-v2`): estender `siged` + novos submódulos `siged-fiscalizacao`, `siged-insights`; Prisma snapshots históricos; coleta passiva em listagens existentes.

**Client** (`ci-client-v2/apps/web`): novas páginas Home/Drilldown/Auditoria/Insights; refatorar rotas e `departamentos-tree`; reutilizar `FiscalizacaoPanel` e componentes Cedro shared.

## Technical Context

**Language/Version**: TypeScript 5.x/6.x; Node.js 20 LTS

**Primary Dependencies**:

| Pacote | Stack |
| --- | --- |
| **ci-api-v2** | NestJS 11, Fastify, Pino, Zod (nestjs-zod), Prisma 7, PostgreSQL |
| **ci-client-v2** | React 19, Vite 8, Tailwind v4, shadcn/ui, react-router-dom 7, Vitest, MSW |

**Storage**: PostgreSQL — novos modelos em `siged.prisma`, `siged-fiscalizacao.prisma`, `siged-insights.prisma`; existentes `TenantSigedConfig`, `SigedControleInterno` inalterados

**Testing**:

| Camada | API | Client |
| --- | --- | --- |
| Unitário | Jest — regras JAT-SIG/Cedro, tree/recorder | Vitest — mappers, departamentos-tree |
| Contrato | fixtures + Zod | MSW handlers |
| Integração | use-cases + mocks | RTL páginas Home/Drilldown |

**Target Platform**: API Linux/container; SPA browser (`@ci/web`)

**Project Type**: Full-stack (API + client tenant)

**Performance Goals**:

- `GET /siged/home` < 500ms p95 (snapshots locais)
- Fiscalização v1: amostra até 500 protocolos/run (evitar timeout SIGED)
- Drill-down client: render instantâneo a partir de hierarquia cacheada (24h TTL existente)

**Constraints**:

- TDD obrigatório (Constitution II)
- Zod only — sem class-validator
- Tenant via AsyncLocalStorage
- SIGED externo permanece read-only; Jatobá/Cedro nunca alteram protocolo/tramitação
- Copy/navegação: [regras-plataforma.md](../../../.cursor/docs/regras-plataforma.md), [licencas-canonicas.md](../../../.cursor/docs/licencas-canonicas.md)
- Módulo permissão: `gabinete` (FR-026)
- Controle Interno Base inalterado (FR-025)

**Scale/Scope**: ~3 migrations, 2 submódulos API (~40 arquivos), refactor client siged (~25 arquivos), 4 user stories independentes

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Princípio | Status | Notas |
| --- | --- | --- |
| I. Spec-Driven | ✅ PASS | Spec 037 + checklist validados |
| II. Test-First | ✅ PASS | [contracts/test-strategy.md](./contracts/test-strategy.md) |
| III. Stack fixa | ✅ PASS | NestJS 11 + Prisma 7 + React 19 |
| IV. Multi-tenant | ✅ PASS | Snapshots/runs/insights com tenantId; guards `@RequireModulo('gabinete')` |
| IV. Licenças | ✅ PASS | `@RequireLicenca('jatoba'|'cedro')` nos controllers dedicados |
| V. Escopo mínimo | ✅ PASS | Reutiliza FiscalizacaoPanel + Cedro shared; padrão gabinete-* |

**Post-design re-check**: Migrations additive; coleta snapshot fire-and-forget não bloqueia UX; sem violações. Sem Complexity Tracking.

## Project Structure

### Documentation (this feature)

```text
civ2-docs/specs/037-siged-ux-refactor/
├── plan.md              # Este arquivo
├── research.md          # Phase 0
├── data-model.md        # Phase 1
├── quickstart.md        # Validação manual
├── contracts/
│   ├── rest-api-siged-ux.md
│   ├── client-siged-ux-ui.md
│   └── test-strategy.md
└── tasks.md             # Phase 2 — /speckit-tasks
```

### Source Code (repository root)

```text
ci-api-v2/
├── prisma/schema/
│   ├── siged.prisma                    # + SigedOrgaoDailyMetric, SigedProtocoloObservacao
│   ├── siged-fiscalizacao.prisma       # novo
│   └── siged-insights.prisma           # novo
├── prisma/migrations/20260810*_siged_ux_*/
└── src/modules/
    ├── siged/                          # existente — portal + recorder hook
    │   ├── use-cases/
    │   │   ├── get-siged-home.use-case.ts          # novo
    │   │   └── record-siged-snapshots.use-case.ts  # novo
    │   └── siged-portal.controller.ts              # + GET home
    ├── siged-fiscalizacao/             # novo (espelho gabinete-fiscalizacao)
    │   ├── lib/checks/                 # tramitacao-sla, stalled-orgao, no-movement
    │   ├── use-cases/
    │   ├── repository/
    │   └── siged-fiscalizacao.controller.ts
    └── siged-insights/                 # novo (espelho gabinete-insights)
        ├── lib/aggregation/
        ├── use-cases/
        ├── repository/
        └── siged-insights.controller.ts

ci-client-v2/apps/web/src/modules/siged/
├── pages/
│   ├── siged-home-page.tsx             # novo
│   ├── siged-diretorias-page.tsx       # refator — só topo
│   ├── siged-orgao-drilldown-page.tsx  # novo
│   ├── siged-auditoria-page.tsx        # novo
│   └── siged-insights-page.tsx         # novo
├── components/
│   ├── siged-post-it-grid.tsx          # novo
│   └── siged-diretorias-grid.tsx       # refator
├── api/
│   ├── siged-home.service.ts
│   ├── fiscalizacao.ts
│   └── insights.ts
├── utils/departamentos-tree.ts         # refator
├── siged-routes.tsx                    # rotas ampliadas
└── constants/siged-routes.ts

ci-client-v2/apps/web/src/modules/shell/config/
├── navigation.ts                       # SIGED: 4 itens
└── screens.ts                          # siged-home, siged-diretorias, siged-auditoria, siged-insights
```

**Structure Decision**: Monorepo CI v2 — API independente + client Turborepo; feature espelha padrão `gabinete-fiscalizacao` / `gabinete-insights` já validado em produção.

## Phase 0 — Research (concluído)

Artefato: [research.md](./research.md)

Decisões-chave:

- Drill-down por árvore SIGED (nós raiz = diretorias)
- Rotas `/siged` = Home; `/siged/diretorias` = topo
- Snapshots passivos + retenção 90 dias
- Submódulos dedicados fiscalização/insights (não reutilizar runs Gabinete)
- Regras v1 determinísticas (sem LLM)

## Phase 1 — Design (concluído)

Artefatos:

- [data-model.md](./data-model.md)
- [contracts/rest-api-siged-ux.md](./contracts/rest-api-siged-ux.md)
- [contracts/client-siged-ux-ui.md](./contracts/client-siged-ux-ui.md)
- [contracts/test-strategy.md](./contracts/test-strategy.md)
- [quickstart.md](./quickstart.md)

## Phase 2 — Implementation order (/speckit-tasks)

Entregas independentes por user story:

| Ordem | Story | API | Client |
| --- | --- | --- | --- |
| 1 | US1 Diretorias | (opcional snapshot hook) | drill-down + rotas + tree utils |
| 2 | US2 Home | GET /siged/home + snapshots | SigedHomePage + post-its |
| 3 | US3 Jatobá | siged-fiscalizacao module | SigedAuditoriaPage + alert bar |
| 4 | US4 Cedro | siged-insights module | SigedInsightsPage + post-its link |

Cada fatia: tests RED → implement GREEN → shell/navigation → quickstart checkpoint.

## Risks & Mitigations

| Risco | Mitigação |
| --- | --- |
| Rate limit API SIGED | Amostra 500 protocolos/run; cache TTL existente; coleta async |
| Tenant sem histórico | emptyReason + orientação UI; popular snapshots ao navegar |
| Duplicação com Gabinete insights | Domínio SIGED separado; evidências por sigedProtocoloId |
| Profundidade hierárquica variável | Testes fixture 3+ níveis; breadcrumb genérico |

## Complexity Tracking

> Nenhuma violação da Constitution que exija justificativa formal.
