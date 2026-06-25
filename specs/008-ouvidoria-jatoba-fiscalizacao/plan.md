# Implementation Plan: Painel de Fiscalização — Ouvidoria (Jatobá)

**Branch**: `008-ouvidoria-jatoba-fiscalizacao` | **Date**: 2026-06-19 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/008-ouvidoria-jatoba-fiscalizacao/spec.md`

## Summary

Implementar **Painel de Fiscalização Jatobá** em `/ouvidoria/auditoria`: checagens automáticas determinísticas registro-a-registro sobre manifestações confirmadas (prazo SLA por tipo, tramitação, completude, canal/contato, anexos), execuções persistidas com histórico, questionários interno/externo, banco de perguntas editável e card contextual no detalhe da manifestação. **Somente leitura** sobre dados operacionais — Jatobá sinaliza achados, não altera registros.

**API** (`ci-api-v2`): submódulo `ouvidoria-fiscalizacao` — regras puras em `lib/checks/`, use-cases, repositories Prisma, job diário `@nestjs/schedule`, REST sob `/ouvidoria/fiscalizacao/*`, rota pública tokenizada para resposta externa, `@RequireModulo('ouvidoria')` + `@RequireLicenca('jatoba')`.

**Client** (`ci-client-v2`): `OuvidoriaAuditoriaPage` + componentes Jatobá em `modules/ouvidoria/`; substituir mock `JatobaFiscalPanel` / `ScreenPage` para `ouvidoria-auditoria`; card no `ManifestacaoDetailPage`.

**Testes (sem banco extra)**: unitário, componente, contrato, integração (mocks/in-memory) e E2E (Supertest + RTL journey com MSW) — ver [contracts/test-strategy.md](./contracts/test-strategy.md).

## Technical Context

**Language/Version**: TypeScript 5.x / 6.x; Node.js 20 LTS

**Primary Dependencies**:

| Pacote | Stack |
|--------|-------|
| **ci-api-v2** | NestJS 11, Fastify, Pino, Zod, Prisma 7, PostgreSQL, `@nestjs/schedule` |
| **ci-client-v2** | React 19, Vite 8, Tailwind v4, shadcn/ui, react-router-dom 7, Vitest 3, MSW 2 |

**Storage**: PostgreSQL — novas entidades de execução, resultado, checagem, achado, banco de perguntas, questionário, resposta, config SLA; leitura de `Manifestacao`, `ManifestacaoEvento`, `ManifestacaoAnexo`, `Address`

**Testing** (sem Postgres de teste dedicado):

| Camada | API | Client |
|--------|-----|--------|
| Unitário | Jest — regras puras SLA/tramitação/completude, agregação conformidade, throttling, mappers | Vitest — mappers conformidade, fluxo questionário |
| Componente | — | Vitest + RTL — painel, stats, trace sheet, histórico, card detalhe |
| Contrato | Zod + fixtures JSON; Supertest valida body | Zod response + MSW handlers |
| Integração | Jest — use-cases + repositories com **Prisma mock** ou store in-memory | Vitest — api client + page + MSW |
| E2E | Supertest app Nest — **deps mockadas** (padrão `ouvidoria-insights.e2e-spec.ts`) | Vitest — página completa + MemoryRouter + MSW (jornada UI) |

**Target Platform**: API Linux/container; SPA browser

**Project Type**: Full-stack (API + client)

**Performance Goals**: Execução completa ≤ 30s para até 500 manifestações (SC-002); GET painel &lt; 500ms p95

**Constraints**:

- TDD obrigatório (Constitution II); RED → GREEN → REFACTOR
- Zod only — sem class-validator
- Tenant via AsyncLocalStorage
- Jatobá read-only — nunca altera `Manifestacao` / eventos
- Conformidade ∈ {Conforme, Não conforme, Parcial, Pendente} — fluxo questionário separado
- SLA derivado de confirmação + dias por tipo — sem campo `prazoResposta` manual
- Copy: [regras-plataforma.md](../../.cursor/docs/regras-plataforma.md) — Fiscalização, Somente leitura, títulos de sheet canônicos
- Canais externos v1: link/token + dispatch metadata — sem WhatsApp/SMTP real
- **Testes**: **NUNCA** exigir banco Postgres separado — mocks Prisma, fixtures in-memory, MSW

**Scale/Scope**: ~8 entidades Prisma novas, ~15 endpoints REST (+ 2 públicos token), 1 job agendado, 1 página client + ~8 componentes, card detalhe, ~35 arquivos de teste

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Princípio | Status | Notas |
|-----------|--------|-------|
| I. Spec-Driven | ✅ PASS | Spec 008 validada; plano segue fluxo |
| II. Test-First | ✅ PASS | Cinco camadas documentadas em test-strategy; sem banco extra |
| III. Stack fixa | ✅ PASS | NestJS 11 + Prisma 7 + React 19 + Vite 8 |
| IV. Multi-tenant | ✅ PASS | Runs/results com `tenantId`; guards módulo + Jatobá |
| IV. Licenças | ✅ PASS | `@RequireLicenca('jatoba')`; read-only Jatobá |
| V. Escopo mínimo | ✅ PASS | Submódulo `ouvidoria-fiscalizacao`; client em `modules/ouvidoria/` |

**Post-design re-check**: Reutiliza `@nestjs/schedule` já adotado em 007. Persistência de execuções justificada por FR-005/FR-010. Rota pública limitada a resposta de questionário (padrão `ConsultaPublicaUseCase`). Sem Complexity Tracking necessário.

## Project Structure

### Documentation (this feature)

```text
specs/008-ouvidoria-jatoba-fiscalizacao/
├── plan.md              # Este arquivo
├── research.md          # Decisões técnicas (Phase 0)
├── data-model.md        # Entidades Prisma fiscalização
├── quickstart.md        # Validação manual + comandos de teste
├── contracts/
│   ├── rest-api-ouvidoria-fiscalizacao.md
│   ├── client-ouvidoria-fiscalizacao-ui.md
│   └── test-strategy.md
└── tasks.md             # Phase 2 — /speckit-tasks
```

### Source Code (repository root)

```text
ci-api-v2/
├── prisma/schema/
│   └── ouvidoria-fiscalizacao.prisma   # Run, Result, Check, Finding, Question*, SlaConfig
├── prisma/seed/
│   └── seed-fiscalizacao-questions.ts  # perguntas ouvidoria default
├── src/modules/ouvidoria-fiscalizacao/
│   ├── ouvidoria-fiscalizacao.module.ts
│   ├── ouvidoria-fiscalizacao.controller.ts
│   ├── ouvidoria-fiscalizacao-public.controller.ts  # @Public responder/:token
│   ├── ouvidoria-fiscalizacao.schemas.ts
│   ├── ouvidoria-fiscalizacao.types.ts
│   ├── ouvidoria-fiscalizacao.mapper.ts
│   ├── lib/
│   │   ├── checks/                     # regras PUROS (unit-testáveis)
│   │   │   ├── deadline.rules.ts
│   │   │   ├── forwarding.rules.ts
│   │   │   ├── completeness.rules.ts
│   │   │   ├── contact.rules.ts
│   │   │   └── evidence.rules.ts
│   │   ├── aggregate-conformity.ts
│   │   ├── sla-resolver.ts
│   │   └── throttle.ts
│   ├── repository/
│   ├── use-cases/
│   ├── jobs/
│   │   └── run-fiscalizacao-scheduled.job.ts
│   └── test/
│       ├── lib/
│       ├── use-cases/
│       └── integration/
└── test/
    └── ouvidoria-fiscalizacao.e2e-spec.ts

ci-client-v2/apps/web/src/modules/ouvidoria/
├── api/
│   ├── fiscalizacao.ts
│   └── fiscalizacao-mappers.ts
├── components/
│   ├── FiscalizacaoPanel.tsx
│   ├── FiscalizacaoStatsRow.tsx
│   ├── FiscalizacaoChecksCard.tsx
│   ├── FiscalizacaoFindingsCard.tsx
│   ├── FiscalizacaoHistoryTable.tsx
│   ├── FiscalizacaoTraceSheet.tsx
│   ├── FiscalizacaoRecordCard.tsx      # detalhe manifestação
│   ├── QuestionBankPanel.tsx
│   └── QuestionnaireDialog.tsx
├── pages/
│   ├── OuvidoriaAuditoriaPage.tsx
│   └── QuestionnairePublicRespondPage.tsx  # rota pública token
├── fixtures/
│   └── fiscalizacao-*.json
└── __tests__/
    ├── fiscalizacao.contract.test.ts
    ├── fiscalizacao-mappers.test.ts
    ├── FiscalizacaoPanel.test.tsx
    ├── FiscalizacaoTraceSheet.test.tsx
    ├── FiscalizacaoRecordCard.test.tsx
    ├── OuvidoriaAuditoriaPage.integration.test.tsx
    └── OuvidoriaAuditoriaPage.e2e.test.tsx
```

**Structure Decision**: Submódulo API dedicado espelhando `ouvidoria-insights` (execução + persistência isolada da CRUD ouvidoria). Regras em `lib/checks/` sem Prisma para maximizar unit tests. Client colocated em `ouvidoria/` com override de rota em `router.tsx`.

## Complexity Tracking

> Vazio — sem violações de constitution que exijam justificativa.

## Phase Artifacts

| Artefato | Caminho |
|----------|---------|
| Research | [research.md](./research.md) |
| Data model | [data-model.md](./data-model.md) |
| REST contract | [contracts/rest-api-ouvidoria-fiscalizacao.md](./contracts/rest-api-ouvidoria-fiscalizacao.md) |
| UI contract | [contracts/client-ouvidoria-fiscalizacao-ui.md](./contracts/client-ouvidoria-fiscalizacao-ui.md) |
| Test strategy | [contracts/test-strategy.md](./contracts/test-strategy.md) |
| Quickstart | [quickstart.md](./quickstart.md) |

## Next Step

`/speckit-tasks` — TDD por camada conforme [test-strategy.md](./contracts/test-strategy.md).
