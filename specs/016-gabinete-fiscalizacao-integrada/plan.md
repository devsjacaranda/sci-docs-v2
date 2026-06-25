# Implementation Plan: Fiscalização de Gestão — Gabinete (Jatobá)

**Branch**: `016-gabinete-fiscalizacao-integrada` | **Date**: 2026-06-24 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/016-gabinete-fiscalizacao-integrada/spec.md`

## Summary

Completar **Fiscalização de Gestão — Gabinete** (`/gabinete/auditoria`) com paridade estrutural à Ouvidoria (008): checagens automáticas ampliadas sobre **atos**, **protocolo**, **controles numéricos**, **notificações/autos** e **documentos tramitados**, incluindo **cadastros órfãos**; execuções persistidas; questionários **internos**; banco de perguntas Gabinete; rastreio sheet; card contextual no detalhe do ato. **Somente leitura** — Jatobá sinaliza achados, não altera registros operacionais.

**Gap corrigido**: API `gabinete-fiscalizacao` hoje tem 3 checagens e não carrega controles; client `GabineteAuditoriaPage` é esqueleto; questionários/perguntas/seed ausentes.

**API** (`ci-api-v2`): estender `gabinete-fiscalizacao` — novas regras em `lib/checks/`, repositórios de carga ampliados, migration em `GabineteFiscalizacaoResult` para entidades órfãs, endpoints questionários/perguntas espelhando 008 (sem rota pública), seed `seed-fiscalizacao-questions-gabinete.ts`.

**Client** (`ci-client-v2`): `GabineteAuditoriaPage` reutilizando componentes Jatobá de `modules/ouvidoria/components/`; API client completo; card `FiscalizacaoRecordCard` no detalhe do ato; MSW handlers Gabinete.

## Technical Context

**Language/Version**: TypeScript 5.x / 6.x; Node.js 20 LTS

**Primary Dependencies**:

| Pacote | Stack |
|--------|-------|
| **ci-api-v2** | NestJS 11, Fastify, Pino, Zod, Prisma 7, PostgreSQL, `@nestjs/schedule` |
| **ci-client-v2** | React 19, Vite 8, Tailwind v4, shadcn/ui, react-router-dom 7, Vitest 3, MSW 2 |

**Storage**: PostgreSQL — schema existente `gabinete-fiscalizacao.prisma` + **migration** para `entityType`/`entityId` em Result e Questionnaire; leitura de `CabinetDemanda`, `CabinetProtocolo`, controles, anexos, eventos

**Testing** (sem Postgres de teste dedicado):

| Camada | API | Client |
|--------|-----|--------|
| Unitário | Jest — regras puras (ato, protocolo, controles, órfãos), agregação, throttle | Vitest — mappers, labels ato |
| Componente | — | Vitest + RTL — painel, trace sheet, card ato |
| Contrato | Zod + fixtures JSON; Supertest | Zod response + MSW |
| Integração | Jest — use-cases + Prisma mock | Vitest — page + MSW |
| E2E | Supertest — guards, throttle, read-only | Vitest — jornada auditoria Gabinete |

**Target Platform**: API Linux/container; SPA browser (`@ci/web`)

**Project Type**: Full-stack (API + client)

**Performance Goals**: Execução completa ≤ 30s para até 500 atos + 200 cadastros órfãos; GET painel < 500ms p95

**Constraints**:

- TDD obrigatório RED → GREEN → REFACTOR
- Zod only — sem class-validator
- Tenant AsyncLocalStorage
- `@RequireModulo('gabinete')` + `@RequireLicenca('jatoba')`
- Jatobá read-only — nunca altera atos/cadastros
- Conformidade ∈ {Conforme, Não conforme, Parcial, Pendente}
- Gabinete **sem** questionário externo / rota pública
- Copy: [regras-plataforma.md](../../../.cursor/docs/regras-plataforma.md)
- Vocabulário UI: **ato/atos**; rotas `/gabinete/atos/*`, fiscalização `/gabinete/auditoria`

**Scale/Scope**: 1 migration Prisma, ~8 novos arquivos de checks, ~12 endpoints REST novos/estendidos, 1 página client refatorada, ~6 componentes reutilizados, card detalhe, seed perguntas, ~40 arquivos de teste

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Princípio | Status | Notas |
|-----------|--------|-------|
| I. Spec-Driven | ✅ PASS | Spec 016 validada; plano segue fluxo |
| II. Test-First | ✅ PASS | Cinco camadas em test-strategy |
| III. Stack fixa | ✅ PASS | NestJS 11 + Prisma 7 + React 19 + Vite 8 |
| IV. Multi-tenant | ✅ PASS | Runs/results com `tenantId`; guards módulo + Jatobá |
| IV. Licenças | ✅ PASS | `@RequireLicenca('jatoba')`; read-only |
| V. Escopo mínimo | ✅ PASS | Estende `gabinete-fiscalizacao` existente; client em `modules/gabinete/` reutilizando UI ouvidoria |

**Post-design re-check**: Migration `entityType` justificada por FR-006/FR-021 (cadastros órfãos). Reuso de componentes ouvidoria evita duplicação de sheet/stats (Constitution V). Sem Complexity Tracking necessário.

## Project Structure

### Documentation (this feature)

```text
specs/016-gabinete-fiscalizacao-integrada/
├── plan.md              # Este arquivo
├── research.md          # Decisões técnicas (Phase 0)
├── data-model.md        # Extensão schema + DTOs fiscalização
├── quickstart.md        # Validação manual + testes
├── contracts/
│   ├── rest-api-gabinete-fiscalizacao.md
│   ├── client-gabinete-fiscalizacao-ui.md
│   └── test-strategy.md
└── tasks.md             # Phase 2 — /speckit-tasks
```

### Source Code (repository root)

```text
ci-api-v2/
├── prisma/schema/
│   └── gabinete-fiscalizacao.prisma     # + enum FiscalizedEntityType, entityId optional demandaId
├── prisma/migrations/
│   └── YYYYMMDD_gabinete_fiscalizacao_entity_types/
├── prisma/seed/
│   └── seed-fiscalizacao-questions-gabinete.ts
├── src/modules/gabinete-fiscalizacao/
│   ├── gabinete-fiscalizacao.controller.ts      # + questions, questionnaires, trace
│   ├── gabinete-fiscalizacao.schemas.ts
│   ├── lib/
│   │   ├── checks/
│   │   │   ├── deadline.rules.ts          # existente — ajustar
│   │   │   ├── forwarding.rules.ts
│   │   │   ├── completeness.rules.ts
│   │   │   ├── evidence.rules.ts          # NOVO
│   │   │   ├── protocol.rules.ts          # NOVO
│   │   │   ├── controle-numerico.rules.ts # NOVO
│   │   │   ├── notificacao.rules.ts       # NOVO
│   │   │   ├── auto-infracao.rules.ts     # NOVO
│   │   │   ├── pairing.rules.ts           # NOVO — pareamento groupId
│   │   │   └── documento-tramitado.rules.ts
│   │   ├── run-checks-for-ato.ts          # refator de run-checks-for-demanda
│   │   ├── run-checks-for-orphan.ts
│   │   └── aggregate-ato-with-links.ts    # worst-of ato + protocolo + controles
│   ├── repository/
│   │   ├── load-atos-for-fiscalizacao.repository.ts      # rename + include relations
│   │   └── load-orphan-cadastros-for-fiscalizacao.repository.ts
│   ├── use-cases/
│   │   ├── run-fiscalizacao.use-case.ts   # atos + órfãos
│   │   ├── questions/*.use-case.ts
│   │   └── questionnaires/*.use-case.ts
│   └── test/
└── test/
    └── gabinete-fiscalizacao.e2e-spec.ts

ci-client-v2/apps/web/src/modules/gabinete/
├── api/
│   ├── fiscalizacao.ts                    # paridade ouvidoria client
│   └── fiscalizacao-mappers.ts
├── pages/
│   ├── GabineteAuditoriaPage.tsx          # reutiliza FiscalizacaoPanel
│   └── GabineteAtoDetailPage.tsx          # + FiscalizacaoRecordCard
├── components/
│   └── GabineteFiscalizacaoRecordCard.tsx # wrapper copy ato
├── fixtures/
│   └── fiscalizacao-*.json
└── __tests__/
    ├── GabineteAuditoriaPage.integration.test.tsx
    └── GabineteAuditoriaPage.e2e.test.tsx

# Reuso cross-module (sem mover nesta entrega):
ci-client-v2/apps/web/src/modules/ouvidoria/components/
├── FiscalizacaoPanel.tsx
├── FiscalizacaoStatsRow.tsx
├── FiscalizacaoChecksCard.tsx
├── FiscalizacaoFindingsCard.tsx
├── FiscalizacaoHistoryTable.tsx
├── FiscalizacaoTraceSheet.tsx
├── QuestionBankPanel.tsx
└── QuestionnaireDialog.tsx
```

**Structure Decision**: Estender submódulo API existente (012 R8) em vez de criar novo módulo. Regras puras em `lib/checks/` sem Prisma. Client Gabinete importa componentes Jatobá de ouvidoria com props de copy (`entityLabel="Ato"`, `runActionLabel="Fiscalizar atos"`).

## Complexity Tracking

> Vazio — sem violações de constitution que exijam justificativa.

## Phase Artifacts

| Artefato | Caminho |
|----------|---------|
| Research | [research.md](./research.md) |
| Data model | [data-model.md](./data-model.md) |
| REST contract | [contracts/rest-api-gabinete-fiscalizacao.md](./contracts/rest-api-gabinete-fiscalizacao.md) |
| UI contract | [contracts/client-gabinete-fiscalizacao-ui.md](./contracts/client-gabinete-fiscalizacao-ui.md) |
| Test strategy | [contracts/test-strategy.md](./contracts/test-strategy.md) |
| Quickstart | [quickstart.md](./quickstart.md) |

## Next Step

`/speckit-tasks` — TDD por camada conforme [test-strategy.md](./contracts/test-strategy.md).
