# Implementation Plan: Desmock Tramitação — Inbox, Linked Records e Licenças

**Branch**: `014-desmock-tramitacao` | **Date**: 2026-06-24 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/014-desmock-tramitacao/spec.md`

## Summary

Substituir mocks de **Tramitação** (`modules/shell/`) por operação real multi-tenant: **Base** (`TramitacaoDemanda` inbox email-like Recebidas/Enviadas/Arquivadas, composição genérica, linked records de Gabinete/Ouvidoria/Jurídico com snapshot imutável, thread de respostas, encaminhamento, dashboard KPIs) + licenças **Jatobá** (fiscalização SLA/completude/pendência), **Cedro** (insights gargalos/volume/tendências) e **Carvalho** (maturidade híbrida 60/40) — espelhando Ouvidoria 007/008/009 e desmocks 012-gabinete/jurídico.

**API** (`ci-api-v2`): 4 módulos NestJS — `tramitacao`, `tramitacao-fiscalizacao`, `tramitacao-insights`, `tramitacao-maturidade`; rotas `/tramitacao/*`; módulo aberto (`OPEN_MODULES`) — sem restrição por setor, tenant-scoped.

**Client** (`ci-client-v2`): `modules/tramitacao/` substitui mock em `shell/`; `ScreenPage` deixa de renderizar `tramitacao-*`; integrações em `gabinete/`, `ouvidoria/`, `juridico/`.

**SIGED** e **Pau-Brasil** operacional fora de escopo v1.

## Technical Context

**Language/Version**: TypeScript 5.x / 6.x; Node.js 20 LTS

**Primary Dependencies**:

| Pacote | Stack |
|--------|-------|
| **ci-api-v2** | NestJS 11, Fastify, Pino, Zod, Prisma 7, PostgreSQL, `@aws-sdk/client-s3`, `@nestjs/schedule` |
| **ci-client-v2** | React 19, Vite 8, Tailwind v4, shadcn/ui, Nivo, react-router-dom 7, TanStack Query, Vitest 3, MSW 2 |

**Storage**: PostgreSQL — `tramitacao.prisma`, `tramitacao-fiscalizacao.prisma`, `tramitacao-maturidade.prisma`, `tramitacao-insights.prisma`; Wasabi/MinIO para anexos (reuso `StorageService`)

**Testing**: Jest (API unit/integration/e2e) + Vitest/RTL/MSW (client); sem Postgres dedicado — [test-strategy.md](./contracts/test-strategy.md)

**Target Platform**: API Linux/container; SPA browser (`@ci/web`)

**Project Type**: Full-stack (API + client monorepo)

**Performance Goals**: Lista inbox paginada < 500ms p95; dashboard < 500ms p95; fiscalização run ≤ 30s para 500 demandas; criação linked record < 5s p95 (SC-002)

**Constraints**:

- TDD obrigatório RED → GREEN → REFACTOR
- Zod only — sem class-validator
- Tenant AsyncLocalStorage — nunca passar `tenantId` manual
- `@RequireModulo('tramitacao')` em rotas Base (módulo aberto — todos setores)
- `@RequireLicenca('jatoba'|'cedro'|'carvalho')` nas rotas de licença
- Jatobá/Cedro/Carvalho read-only sobre demandas operacionais
- Status operacional (Base) ≠ conformidade Jatobá — conjuntos fechados separados
- Copy [regras-plataforma.md](../../.cursor/docs/regras-plataforma.md); paleta mint-palette
- Composição v1: texto simples (sem rich text)
- `sourceSnapshot` imutável após criação (FR-025)

**Scale/Scope**: ~16 entidades Prisma, 4 módulos NestJS, ~38 endpoints REST, 7 páginas client, seed Jacaranda, 3 integrações cross-módulo, remoção mock shell

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Princípio | Status | Notas |
|-----------|--------|-------|
| I. Spec-Driven | ✅ PASS | Spec 014 + checklist validados |
| II. Test-First | ✅ PASS | test-strategy 5 camadas |
| III. Stack fixa | ✅ PASS | NestJS 11 + Prisma 7 + React 19 + Vite 8 |
| IV. Multi-tenant | ✅ PASS | Todas entidades `tenantId`; guards licença |
| IV. Licenças | ✅ PASS | Jatobá + Carvalho + Cedro + Base |
| V. Escopo mínimo | ✅ PASS | 4 módulos espelho ouvidoria; client `modules/tramitacao/` |

**Post-design re-check**: Quatro submódulos justificados por fronteiras de licença (R8). `CreateLinkedDemandaUseCase` compartilhado para integrações (R6). Migração mock→API justificada — spec 005 era frontend-only; esta feature é o desmock canônico. Sem Complexity Tracking necessário.

## Project Structure

### Documentation (this feature)

```text
specs/014-desmock-tramitacao/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   ├── rest-api-tramitacao.md
│   ├── rest-api-tramitacao-fiscalizacao.md
│   ├── rest-api-tramitacao-maturidade.md
│   ├── rest-api-tramitacao-insights.md
│   ├── client-tramitacao-ui.md
│   └── test-strategy.md
└── tasks.md             # Phase 2 — /speckit-tasks
```

### Source Code (repository root)

```text
ci-api-v2/
├── prisma/schema/
│   ├── tramitacao.prisma
│   ├── tramitacao-fiscalizacao.prisma
│   ├── tramitacao-maturidade.prisma
│   └── tramitacao-insights.prisma
├── prisma/seed/
│   ├── seed-tramitacao-demo.ts
│   ├── seed-fiscalizacao-questions-tramitacao.ts
│   └── seed-maturidade-questions-tramitacao.ts
├── src/modules/
│   ├── tramitacao/
│   │   ├── tramitacao.module.ts
│   │   ├── tramitacao.controller.ts
│   │   ├── tramitacao.schemas.ts
│   │   ├── tramitacao.mapper.ts
│   │   ├── use-cases/
│   │   │   ├── create-generic-demanda.use-case.ts
│   │   │   ├── create-linked-demanda.use-case.ts      # usado por gabinete/ouvidoria/juridico
│   │   │   ├── list-inbox.use-case.ts
│   │   │   ├── get-demanda-detail.use-case.ts
│   │   │   ├── reply-demanda.use-case.ts
│   │   │   ├── forward-demanda.use-case.ts
│   │   │   ├── archive-demanda.use-case.ts
│   │   │   ├── presign-anexo.use-case.ts
│   │   │   ├── confirm-anexo.use-case.ts
│   │   │   └── get-dashboard.use-case.ts
│   │   └── repository/
│   ├── tramitacao-fiscalizacao/
│   │   └── lib/checks/
│   │       ├── sla-deadline.rules.ts
│   │       ├── completeness.rules.ts
│   │       └── forwarding-pending.rules.ts
│   ├── tramitacao-insights/
│   └── tramitacao-maturidade/
└── test/
    └── tramitacao.e2e-spec.ts

ci-client-v2/apps/web/src/modules/
├── tramitacao/
│   ├── index.ts
│   ├── api/
│   │   ├── demandas.ts
│   │   ├── dashboard.ts
│   │   ├── fiscalizacao.ts
│   │   ├── maturidade.ts
│   │   └── insights.ts
│   ├── pages/
│   │   ├── TramitacaoInboxPage.tsx
│   │   ├── TramitacaoComposePage.tsx
│   │   ├── TramitacaoDemandaDetailPage.tsx
│   │   ├── TramitacaoDashboardPage.tsx
│   │   ├── TramitacaoAuditoriaPage.tsx
│   │   ├── TramitacaoMaturidadePage.tsx
│   │   └── TramitacaoInsightsPage.tsx
│   ├── components/
│   │   ├── InboxPanel.tsx              # evolução TramitacaoInboxPanel
│   │   ├── DemandaThread.tsx
│   │   ├── LinkedRecordPanel.tsx
│   │   ├── ForwardDemandaDialog.tsx
│   │   └── … (fiscalizacao/maturidade/insights clones adaptados)
│   └── fixtures/
├── gabinete/                           # + TramitarDialog → API tramitacao
├── ouvidoria/                          # + encaminhar → API tramitacao
├── juridico/                           # + tramitar → API tramitacao
└── shell/
    ├── config/screens.ts               # tramitacao-* → lazy modules/tramitacao
    └── components/mock/                # remover TramitacaoInboxPanel (após migração)
```

**Structure Decision**: Quatro módulos API por domínio/licença (Constitution V); client `modules/tramitacao/` espelhando `ouvidoria/` e `gabinete/`. Mock em `shell/` removido após paridade funcional.

## Phase 0 — Research

Concluída em [research.md](./research.md). Decisões R1–R15.

## Phase 1 — Design

| Artefato | Path |
|----------|------|
| Data model | [data-model.md](./data-model.md) |
| REST Base | [contracts/rest-api-tramitacao.md](./contracts/rest-api-tramitacao.md) |
| REST Jatobá | [contracts/rest-api-tramitacao-fiscalizacao.md](./contracts/rest-api-tramitacao-fiscalizacao.md) |
| REST Carvalho | [contracts/rest-api-tramitacao-maturidade.md](./contracts/rest-api-tramitacao-maturidade.md) |
| REST Cedro | [contracts/rest-api-tramitacao-insights.md](./contracts/rest-api-tramitacao-insights.md) |
| UI | [contracts/client-tramitacao-ui.md](./contracts/client-tramitacao-ui.md) |
| Tests | [contracts/test-strategy.md](./contracts/test-strategy.md) |
| Quickstart | [quickstart.md](./quickstart.md) |

## Implementation phases (for /speckit-tasks)

### Phase A — Schema & seed

1. Prisma `tramitacao.prisma` + enums + migration
2. Seed demandas demo Jacaranda (genéricas + linked records)
3. Seed perguntas fiscalização/maturidade

### Phase B — Tramitação Base API

1. Sequence `TRAM-{YYYY}-{NNNN}`
2. CRUD composição genérica + linked record interno
3. Inbox (recebidas/enviadas/arquivadas) por setor ativo
4. Reply, forward, archive + eventos timeline
5. Anexos presign/confirm (Wasabi)
6. Dashboard aggregations
7. e2e Base

### Phase C — Integrações cross-módulo

1. `CreateLinkedDemandaUseCase` exportado via `TramitacaoModule`
2. Gabinete: `POST /gabinete/cabinets/:id/forward` → cria demanda tramitacao
3. Ouvidoria: `POST /ouvidoria/manifestacoes/:id/encaminhar` → cria demanda
4. Jurídico: `POST /juridico/processos/:id/tramitar` → cria demanda
5. Testes integração cross-módulo

### Phase D — Tramitação Fiscalização (Jatobá)

1. Schema + checks (SLA, completude, pendência encaminhamento)
2. Job schedule + panel/history
3. Client `TramitacaoAuditoriaPage`

### Phase E — Tramitação Insights (Cedro)

1. Schema + aggregation rules (gargalos, volume módulo, tendências)
2. Client `TramitacaoInsightsPage`

### Phase F — Tramitação Maturidade (Carvalho)

1. Schema + score híbrido 60/40
2. Client `TramitacaoMaturidadePage`

### Phase G — Client desmock

1. `modules/tramitacao/` pages + API + MSW
2. Router overrides; remover mock shell
3. Alertas licença + traceability real
4. Smoke quickstart VS-001…VS-012

### Phase H — Produto

1. Atualizar `licencas-canonicas.md` seção Tramitação
2. Agent context / STATUS.md

## Complexity Tracking

> Nenhuma violação de constitution que exija justificativa.
