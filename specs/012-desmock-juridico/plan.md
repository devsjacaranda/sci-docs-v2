# Implementation Plan: Desmock Jurídico — Módulo Legal Completo

**Branch**: `012-desmock-juridico` | **Date**: 2026-06-23 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/012-desmock-juridico/spec.md`

## Summary

Substituir mocks do módulo **Jurídico** por operação real multi-tenant: **Base** (wizard dados → anexos → revisão → confirmação, `LegalProcess` + partes estruturadas + órgão/juízo, anexos **Wasabi**, lista/detalhe/timeline, dashboard KPIs) + licenças **Jatobá** (fiscalização + **Probabilidade de Perda** determinística), **Cedro** (insights risco processual) e **Carvalho** (maturidade híbrida) — espelhando Ouvidoria 003/007/008/009 e padrão de desmock 012-gabinete.

**API** (`ci-api-v2`): 4 módulos NestJS — `juridico`, `juridico-fiscalizacao`, `juridico-insights`, `juridico-maturidade`; rotas `/juridico/*`; `@RequireModulo('juridico')` + `@RequireLicenca` nas licenças.

**Client** (`ci-client-v2`): `modules/juridico/` com overrides em `router.tsx` para as 7 rotas reais; substituir `ScreenPage` + `mock-data.ts` para `juridico-*`.

## Technical Context

**Language/Version**: TypeScript 5.x / 6.x; Node.js 20 LTS

**Primary Dependencies**:

| Pacote | Stack |
|--------|-------|
| **ci-api-v2** | NestJS 11, Fastify, Pino, Zod, Prisma 7, PostgreSQL, `@aws-sdk/client-s3`, `@nestjs/schedule` |
| **ci-client-v2** | React 19, Vite 8, Tailwind v4, shadcn/ui, Nivo, react-router-dom 7, TanStack Query, Vitest 3, MSW 2 |

**Storage**: PostgreSQL — `juridico.prisma`, `juridico-fiscalizacao.prisma`, `juridico-maturidade.prisma`, `juridico-insights.prisma`; reutilização de `Address`; Wasabi/MinIO para anexos (mesma política 003)

**Testing**: Jest (API) + Vitest/RTL/MSW (client); sem Postgres de teste dedicado — [test-strategy.md](./contracts/test-strategy.md)

**Target Platform**: API Linux/container; SPA browser (`@ci/web`)

**Project Type**: Full-stack (API + client monorepo)

**Performance Goals**: Lista processos paginada < 500ms p95; dashboard < 500ms p95; fiscalização run ≤ 30s para 500 processos; presigned upload direto ao storage

**Constraints**:

- TDD obrigatório RED → GREEN → REFACTOR
- Zod only — sem class-validator
- Tenant AsyncLocalStorage — nunca passar `tenantId` manual
- `@RequireModulo('juridico')` + `@RequireLicenca` nas rotas de licença
- Jatobá/Cedro/Carvalho read-only sobre processos operacionais
- Conformidade Jatobá ∈ {Conforme, Não conforme, Parcial, Pendente} — distinto de status operacional
- Copy [regras-plataforma.md](../../.cursor/docs/regras-plataforma.md); paleta mint-palette
- Pau-Brasil permanece mock nesta entrega

**Scale/Scope**: ~18 entidades Prisma, 4 módulos NestJS, ~40 endpoints REST (+ 1 público token), 7 páginas client, seed DEJUR demo, ~45 arquivos de teste

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Princípio | Status | Notas |
|-----------|--------|-------|
| I. Spec-Driven | ✅ PASS | Spec 012-juridico + checklist validados |
| II. Test-First | ✅ PASS | test-strategy 5 camadas documentadas |
| III. Stack fixa | ✅ PASS | NestJS 11 + Prisma 7 + React 19 + Vite 8 |
| IV. Multi-tenant | ✅ PASS | Todas entidades `tenantId`; guards módulo/licença |
| IV. Licenças | ✅ PASS | Jatobá + Carvalho + Cedro + Base |
| V. Escopo mínimo | ✅ PASS | 4 módulos espelho ouvidoria; client `modules/juridico/` |

**Post-design re-check**: Quatro submódulos justificados por fronteiras de licença (R8). Reuso `StorageService` via extração compartilhada ou import ouvidoria (R4). Probabilidade de Perda em `lib/checks/loss-probability.rules.ts` — função pura testável. Sem Complexity Tracking necessário.

## Project Structure

### Documentation (this feature)

```text
specs/012-desmock-juridico/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   ├── rest-api-juridico.md
│   ├── rest-api-juridico-fiscalizacao.md
│   ├── rest-api-juridico-maturidade.md
│   ├── rest-api-juridico-insights.md
│   ├── client-juridico-ui.md
│   └── test-strategy.md
└── tasks.md             # Phase 2 — /speckit-tasks
```

### Source Code (repository root)

```text
ci-api-v2/
├── prisma/schema/
│   ├── juridico.prisma                    # LegalProcess, Party, Anexo, Evento, Sequence
│   ├── juridico-fiscalizacao.prisma
│   ├── juridico-maturidade.prisma
│   └── juridico-insights.prisma
├── prisma/seed/
│   ├── seed-juridico-demo.ts
│   ├── seed-fiscalizacao-questions-juridico.ts
│   └── seed-maturidade-questions-juridico.ts
├── src/modules/
│   ├── shared/storage/                    # StorageService (extrair de ouvidoria — R4)
│   │   └── storage.service.ts
│   ├── juridico/
│   │   ├── juridico.module.ts
│   │   ├── juridico.controller.ts
│   │   ├── juridico.schemas.ts
│   │   ├── juridico.types.ts
│   │   ├── juridico.mapper.ts
│   │   ├── use-cases/
│   │   │   ├── create-process-draft.use-case.ts
│   │   │   ├── update-process-draft.use-case.ts
│   │   │   ├── confirm-process.use-case.ts
│   │   │   ├── list-processes.use-case.ts
│   │   │   ├── get-process-detail.use-case.ts
│   │   │   ├── update-process.use-case.ts
│   │   │   ├── presign-anexo.use-case.ts
│   │   │   ├── confirm-anexo.use-case.ts
│   │   │   └── get-dashboard.use-case.ts
│   │   └── repository/
│   ├── juridico-fiscalizacao/
│   │   ├── lib/checks/
│   │   │   ├── deadline.rules.ts
│   │   │   ├── completeness.rules.ts
│   │   │   ├── judicial-id.rules.ts
│   │   │   ├── attachments.rules.ts
│   │   │   ├── parties.rules.ts
│   │   │   └── loss-probability.rules.ts   # Probabilidade de Perda
│   │   ├── jobs/run-fiscalizacao-scheduled.job.ts
│   │   └── … (espelho ouvidoria-fiscalizacao)
│   ├── juridico-insights/                 # espelho ouvidoria-insights
│   └── juridico-maturidade/               # espelho ouvidoria-maturidade
└── test/
    └── juridico.e2e-spec.ts

ci-client-v2/apps/web/src/modules/juridico/
├── index.ts
├── api/
│   ├── processos.ts
│   ├── dashboard.ts
│   ├── fiscalizacao.ts
│   ├── maturidade.ts
│   └── insights.ts
├── pages/
│   ├── JuridicoDashboardPage.tsx
│   ├── JuridicoProcessosListPage.tsx
│   ├── JuridicoProcessoWizardPage.tsx
│   ├── JuridicoProcessoDetailPage.tsx
│   ├── JuridicoAuditoriaPage.tsx
│   ├── JuridicoMaturidadePage.tsx
│   └── JuridicoInsightsPage.tsx
├── components/
│   ├── ProcessoWizard/                    # steps: dados, anexos, revisão
│   ├── ProcessoPartesForm.tsx
│   ├── ProcessoOrgaoForm.tsx
│   ├── ProcessoTimeline.tsx
│   ├── ProcessoDetailFiscalCard.tsx
│   └── … (fiscalizacao/maturidade/insights adaptados de ouvidoria)
└── fixtures/
```

**Structure Decision**: Quatro módulos API por domínio/licença (Constitution V); client único `juridico/` espelhando `ouvidoria/`. `JURIDICO_OVERRIDES` em `router.tsx` substitui mock para screenIds `juridico-*`.

## Phase 0 — Research

Concluída em [research.md](./research.md). Decisões R1–R16 (entidade, wizard, partes, Probabilidade de Perda, Wasabi, submódulos licença).

## Phase 1 — Design

| Artefato | Path |
|----------|------|
| Data model | [data-model.md](./data-model.md) |
| REST Base | [contracts/rest-api-juridico.md](./contracts/rest-api-juridico.md) |
| REST Jatobá | [contracts/rest-api-juridico-fiscalizacao.md](./contracts/rest-api-juridico-fiscalizacao.md) |
| REST Carvalho | [contracts/rest-api-juridico-maturidade.md](./contracts/rest-api-juridico-maturidade.md) |
| REST Cedro | [contracts/rest-api-juridico-insights.md](./contracts/rest-api-juridico-insights.md) |
| UI | [contracts/client-juridico-ui.md](./contracts/client-juridico-ui.md) |
| Tests | [contracts/test-strategy.md](./contracts/test-strategy.md) |
| Quickstart | [quickstart.md](./quickstart.md) |

## Implementation phases (for /speckit-tasks)

### Phase A — Schema & seed

1. Prisma `juridico.prisma` + enums + migration
2. Confirmar vínculo setor DEJUR ↔ módulo `juridico` (Jacaranda seed)
3. Seed demo processos + partes variadas

### Phase B — Storage compartilhado

1. Extrair `StorageService` de ouvidoria → `shared/storage` (se ainda não feito pelo 012-gabinete)
2. Refatorar ouvidoria para importar shared (regression tests)

### Phase C — Jurídico Base API

1. Draft CRUD + confirm (sequence `JUR-AAAA-NNNN`)
2. Partes nested + Address FK
3. Anexos presign/confirm
4. Lista/filtros + detalhe + timeline
5. Dashboard aggregations
6. e2e Base

### Phase D — Jurídico Fiscalização (Jatobá)

1. Schema fiscalizacao + seed perguntas
2. `lib/checks/*` incl. `loss-probability.rules.ts`
3. Runs persistidos + job + throttle
4. Painel + card detalhe + questionários
5. Coluna Probabilidade de Perda no painel

### Phase E — Jurídico Insights (Cedro)

1. Schema insights + agregadores determinísticos (risco, tipo, órgão, prazos)
2. Job híbrido + throttling Consultar IA
3. Página Insights IA

### Phase F — Jurídico Maturidade (Carvalho)

1. Schema maturidade + autoavaliação + planos ação
2. Score híbrido consumindo último run Jatobá
3. Página Maturidade + Nivo radar

### Phase G — Client integration

1. `modules/juridico/` páginas + wizard shadcn
2. `JURIDICO_OVERRIDES` no router
3. Remover dependência de mock para rotas jurídico

## Complexity Tracking

> Vazio — sem violações de constitution que exijam justificativa.

## Next Step

`/speckit-tasks` — TDD por camada conforme [test-strategy.md](./contracts/test-strategy.md).
