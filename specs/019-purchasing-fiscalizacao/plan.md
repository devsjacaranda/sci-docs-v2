# Implementation Plan: Fiscalização de Compras — Purchasing (Jatobá)

**Branch**: `019-purchasing-fiscalizacao` | **Date**: 2026-06-25 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/019-purchasing-fiscalizacao/spec.md`

## Summary

Entregar **Fiscalização de Compras** (`/compras/fiscalizacao`) com licença Jatobá: checagens automáticas determinísticas sobre **demandas ativas** e **7 artefatos documentais** (Lei 14.133/2021), execuções persistidas, histórico, rastreio em sheet e card contextual no hub da demanda. **Somente leitura** — nenhuma ação Jatobá altera registros operacionais.

**Gap atual**: módulo `compras-fiscalizacao` **inexistente** na API; rota client `/compras/auditoria` é esqueleto mock em `shell/data/mock-data.ts`; CRUD Compras (018) já fornece demandas e artefatos reais.

**API** (`ci-api-v2`): novo submódulo `compras-fiscalizacao` espelhando `ouvidoria-fiscalizacao` — schema Prisma dedicado, regras puras em `lib/checks/`, job diário, throttle 1h, guards `@RequireModulo('compras')` + `@RequireLicenca('jatoba')`. **Sem** questionários internos nesta entrega.

**Client** (`ci-client-v2`): `ComprasFiscalizacaoPage` reutilizando componentes Jatobá de `modules/ouvidoria/components/` (sem banco de perguntas); API client em `modules/compras/api/fiscalizacao.ts`; `ComprasFiscalizacaoRecordCard` em `DemandaHubPage`; migrar rota de `/compras/auditoria` → `/compras/fiscalizacao`.

## Technical Context

**Language/Version**: TypeScript 5.x / 6.x; Node.js 20 LTS

**Primary Dependencies**:

| Pacote | Stack |
|--------|-------|
| **ci-api-v2** | NestJS 11, Fastify, Pino, Zod, Prisma 7, PostgreSQL, `@nestjs/schedule` |
| **ci-client-v2** | React 19, Vite 8, Tailwind v4, shadcn/ui, react-router-dom 7, Vitest 3, MSW 2 |

**Storage**: PostgreSQL — novo schema `compras-fiscalizacao.prisma`; leitura de `CompraDemanda` + 7 artefatos + `CompraPca` via `demanda.repositories.ts` (include existente)

**Testing** (sem Postgres de teste dedicado):

| Camada | API | Client |
|--------|-----|--------|
| Unitário | Jest — regras puras (8 checks), agregação worst-of, throttle | Vitest — mappers, labels demanda/PCA |
| Componente | — | Vitest + RTL — painel, trace sheet, card demanda |
| Contrato | Zod + fixtures JSON; Supertest | Zod response + MSW |
| Integração | Jest — use-cases + Prisma mock | Vitest — page + MSW |
| E2E | Supertest — guards, throttle, read-only | Vitest — jornada fiscalização Compras |

**Target Platform**: API Linux/container; SPA browser (`@ci/web`)

**Project Type**: Full-stack (API + client)

**Performance Goals**: Execução completa ≤ 30s para até 500 demandas ativas; GET painel < 500ms p95; card scoped refetch ≤ 5s percebidos (SC-008)

**Constraints**:

- TDD obrigatório RED → GREEN → REFACTOR
- Zod only — sem class-validator
- Tenant AsyncLocalStorage
- `@RequireModulo('compras')` + `@RequireLicenca('jatoba')`
- Jatobá read-only — nunca altera demandas/artefatos
- Conformidade ∈ {Conforme, Não conforme, Parcial, Pendente}
- Questionários Jatobá Compras — **fora de escopo** (spec Assumptions)
- Copy: [regras-plataforma.md](../../../.cursor/docs/regras-plataforma.md)
- Vocabulário UI: **demanda/demandas**; rota `/compras/fiscalizacao` (FR-019)

**Scale/Scope**: 1 migration Prisma, ~8 arquivos de checks, ~6 endpoints REST, 1 página client, 1 card hub, MSW handlers, ~35 arquivos de teste

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Princípio | Status | Notas |
|-----------|--------|-------|
| I. Spec-Driven | ✅ PASS | Spec 019 validada; plano segue fluxo |
| II. Test-First | ✅ PASS | Cinco camadas em test-strategy |
| III. Stack fixa | ✅ PASS | NestJS 11 + Prisma 7 + React 19 + Vite 8 |
| IV. Multi-tenant | ✅ PASS | Runs/results com `tenantId`; guards módulo + Jatobá |
| IV. Licenças | ✅ PASS | `@RequireLicenca('jatoba')`; read-only |
| V. Escopo mínimo | ✅ PASS | Novo módulo espelhando ouvidoria; client reutiliza UI Jatobá existente |

**Post-design re-check**: Reuso de `compras.mapper.ts` para satisfação de artefatos evita divergência CRUD vs fiscalização (Constitution V). Sem questionários — escopo menor que Gabinete 016. Sem Complexity Tracking necessário.

## Project Structure

### Documentation (this feature)

```text
specs/019-purchasing-fiscalizacao/
├── plan.md              # Este arquivo
├── research.md          # Decisões técnicas (Phase 0)
├── data-model.md        # Schema + DTOs fiscalização
├── quickstart.md        # Validação manual + testes
├── contracts/
│   ├── rest-api-compras-fiscalizacao.md
│   ├── client-compras-fiscalizacao-ui.md
│   └── test-strategy.md
└── tasks.md             # Phase 2 — /speckit-tasks
```

### Source Code (repository root)

```text
ci-api-v2/
├── prisma/schema/
│   └── compras-fiscalizacao.prisma          # NOVO — Run, Result, Check, Finding
├── prisma/migrations/
│   └── YYYYMMDD_compras_fiscalizacao/
├── src/modules/compras-fiscalizacao/
│   ├── compras-fiscalizacao.module.ts
│   ├── compras-fiscalizacao.controller.ts
│   ├── compras-fiscalizacao.schemas.ts
│   ├── compras-fiscalizacao.mapper.ts
│   ├── compras-fiscalizacao.types.ts
│   ├── lib/
│   │   ├── aggregate-conformity.ts          # reexport ou cópia mínima de ouvidoria
│   │   ├── throttle.ts
│   │   ├── run-checks-for-demanda.ts
│   │   └── checks/
│   │       ├── dfd-completeness.rules.ts
│   │       ├── etp-waiver.rules.ts
│   │       ├── risk-analysis.rules.ts
│   │       ├── tr-completeness.rules.ts
│   │       ├── price-survey.rules.ts
│   │       ├── budget-allocation.rules.ts
│   │       ├── legal-opinion.rules.ts
│   │       └── budget-consistency.rules.ts
│   ├── repository/
│   │   ├── load-demandas-for-fiscalizacao.repository.ts
│   │   ├── fiscalizacao-persistence.repositories.ts
│   │   └── fiscalizacao-query.repositories.ts
│   ├── use-cases/
│   │   ├── run-fiscalizacao.use-case.ts
│   │   ├── run-fiscalizacao-scoped.use-case.ts
│   │   ├── get-fiscalizacao-panel.use-case.ts
│   │   └── list-fiscalizacao-runs.use-case.ts
│   ├── jobs/
│   │   └── run-fiscalizacao-scheduled.job.ts
│   └── test/
└── test/
    └── compras-fiscalizacao.e2e-spec.ts

ci-client-v2/apps/web/src/modules/compras/
├── api/
│   ├── fiscalizacao.ts
│   └── fiscalizacao-mappers.ts
├── pages/
│   └── ComprasFiscalizacaoPage.tsx
├── components/
│   └── ComprasFiscalizacaoRecordCard.tsx
├── fixtures/
│   └── fiscalizacao-*.json
└── __tests__/
    ├── ComprasFiscalizacaoPage.integration.test.tsx
    ├── ComprasFiscalizacaoPage.e2e.test.tsx
    └── ComprasFiscalizacaoRecordCard.test.tsx

# Reuso cross-module (sem mover nesta entrega):
ci-client-v2/apps/web/src/modules/ouvidoria/components/
├── FiscalizacaoPanel.tsx
├── FiscalizacaoStatsRow.tsx
├── FiscalizacaoChecksCard.tsx
├── FiscalizacaoFindingsCard.tsx
├── FiscalizacaoHistoryTable.tsx
└── FiscalizacaoTraceSheet.tsx
```

**Structure Decision**: Módulo API **novo** (não existe stub como Gabinete 012). Padrão de código copiado/adaptado de `ouvidoria-fiscalizacao` com domínio Compras. Regras de completude **importam** funções de `compras.mapper.ts` (`isDfdSatisfied`, `isEtpSatisfied`, etc.) para paridade com status derivado do CRUD. Client Compras importa componentes ouvidoria com props de copy (`entityColumnLabel="Demanda"`, `runButtonLabel="Fiscalizar demandas"`).

## Complexity Tracking

> Vazio — sem violações de constitution que exijam justificativa.

## Phase Artifacts

| Artefato | Caminho |
|----------|---------|
| Research | [research.md](./research.md) |
| Data model | [data-model.md](./data-model.md) |
| REST contract | [contracts/rest-api-compras-fiscalizacao.md](./contracts/rest-api-compras-fiscalizacao.md) |
| UI contract | [contracts/client-compras-fiscalizacao-ui.md](./contracts/client-compras-fiscalizacao-ui.md) |
| Test strategy | [contracts/test-strategy.md](./contracts/test-strategy.md) |
| Quickstart | [quickstart.md](./quickstart.md) |

## Next Step

`/speckit-tasks` — TDD por camada conforme [test-strategy.md](./contracts/test-strategy.md).
