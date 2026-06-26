# Implementation Plan: Módulo IT — Segurança da Informação

**Branch**: `022-it-seguranca-informacao` | **Date**: 2026-06-25 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/022-it-seguranca-informacao/spec.md`

## Summary

Implementar o **9º módulo de negócio** *Segurança da Informação* (slug `it`) com quatro camadas NestJS espelhando Compras/Gabinete:

| Camada | API module | Rota client | Licença |
|--------|------------|-------------|---------|
| **Base** | `it` | `/it/*` | Base (módulo) |
| **Insights** | `it-insights` | `/it/insights` | Cedro |
| **Fiscalização** | `it-fiscalizacao` | `/it/fiscalizacao` | Jatobá |
| **Maturidade** | `it-maturidade` | `/it/maturidade` | Carvalho |

**Base**: CRUD ativos TI (5 tipos), incidentes, operadores/tratamento LGPD, dashboard operacional, soft delete + restore, tags e vínculos entre ativos.

**Cedro**: upload/análise de configurações (regex), classificador LGPD (recomendação read-only + *Aplicar classificação* na Base), matriz de impacto de mudanças (árvore If/Else).

**Jatobá**: workflow mensal de auditoria de backup (cron dia X), trilha de auditoria **append-only** escopada ao módulo IT, gerador de notificação ANPD (PDF via `pdf-lib`).

**Carvalho**: linhas de defesa (gráfico pizza Nivo), aderência CIS/LGPD (score 0–100%), índice de vulnerabilidade por secretaria.

**API** (`ci-api-v2`): 4 módulos Nest + 4 schemas Prisma; guards `@RequireModulo('it')` + licença por submódulo.

**Client** (`ci-client-v2`): `modules/it/` espelhando `modules/compras/`; `IT_OVERRIDES` no router; atualizar `regras-plataforma.md` §3 (9º módulo).

## Technical Context

**Language/Version**: TypeScript 5.x / 6.x; Node.js 20 LTS

**Primary Dependencies**:

| Pacote | Stack |
|--------|-------|
| **ci-api-v2** | NestJS 11, Fastify, Pino, Zod, Prisma 7, PostgreSQL, `@nestjs/schedule`, `pdf-lib` |
| **ci-client-v2** | React 19, Vite 8, Tailwind v4, shadcn/ui, Nivo (`@nivo/pie`, `@nivo/bar`), react-router-dom 7, Vitest 3, MSW 2 |

**Storage**: PostgreSQL — `it.prisma`, `it-insights.prisma`, `it-fiscalizacao.prisma`, `it-maturidade.prisma`; S3/Wasabi via `StorageModule` para logs backup, configs Cedro e PDFs ANPD

**Testing** (sem Postgres de teste dedicado):

| Camada | API | Client |
|--------|-----|--------|
| Unitário | Jest — regex scan, LGPD classifier, risk matrix tree, defense lines %, vulnerability index, backup validation | Vitest — mappers, chart adapters, form validation |
| Contrato | Zod + fixtures JSON; Supertest | Zod + MSW |
| Integração | Use-cases + Prisma mock | Page + MSW |
| E2E | Supertest Nest mock deps | RTL jornada completa |

**Target Platform**: API Linux/container; SPA browser

**Project Type**: Full-stack (API + client)

**Performance Goals**: Dashboard GET &lt; 500ms p95; classificador LGPD ≤ 5s (SC-005); análise config ≤ 10s (SC-004); matriz risco ≤ 1s percebido (SC-006); score Carvalho ≤ 2s (SC-010)

**Constraints**:

- TDD obrigatório (Constitution II); RED → GREEN → REFACTOR
- Zod only — sem class-validator
- Tenant via AsyncLocalStorage — nunca `tenantId` manual
- Cedro **somente leitura** — classificador recomenda; flag aplicada via endpoint Base (FR-014, R-21)
- Jatobá **não altera** ativos/incidentes — sinaliza conformidade backup
- Carvalho **somente leitura** sobre operação
- Trilha IT **append-only** — sem DELETE no repository; escopo módulo IT only (FR-020)
- Pau-Brasil omitida nesta entrega (FR-033)
- Vocabulário UI: [regras-plataforma.md](../../../.cursor/docs/regras-plataforma.md), [licencas-canonicas.md](../../../.cursor/docs/licencas-canonicas.md)
- Rotas: `/it`, `/it/insights`, `/it/fiscalizacao`, `/it/maturidade`

**Scale/Scope**: ~25 entidades Prisma novas, ~35 endpoints REST, 8+ páginas client, seed CIS (20 controles) + termos LGPD + política regex, ~80 arquivos de teste estimados

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Princípio | Status | Notas |
|-----------|--------|-------|
| I. Spec-Driven | ✅ PASS | Spec 022 validada; plano segue fluxo |
| II. Test-First | ✅ PASS | test-strategy.md; TDD por vertical slice |
| III. Stack fixa | ✅ PASS | NestJS 11 + Prisma 7 + React 19 + Vite 8 + Nivo; `pdf-lib` adicionado (primeiro PDF binário) |
| IV. Multi-tenant | ✅ PASS | `tenantId` em todas entidades; guards módulo + licença |
| IV. Licenças | ✅ PASS | Separação Base/Cedro/Jatobá/Carvalho; Cedro read-only |
| V. Escopo mínimo | ✅ PASS | 4 submódulos API espelhando Compras; client `modules/it/` |

**Post-design re-check**: `ItAuditTrail` dedicado justificado — interceptor global não cobre read, IP, append-only nem escopo IT. `pdf-lib` justificado — spec exige PDF ANPD real (SC-009). Job mensal backup estende padrão `@Cron` existente. Sem Complexity Tracking necessário.

## Project Structure

### Documentation (this feature)

```text
specs/022-it-seguranca-informacao/
├── plan.md              # Este arquivo
├── research.md          # Decisões técnicas (Phase 0)
├── data-model.md        # Entidades Prisma IT
├── quickstart.md        # Validação manual + comandos
├── contracts/
│   ├── rest-api-it-base.md
│   ├── rest-api-it-insights.md
│   ├── rest-api-it-fiscalizacao.md
│   ├── rest-api-it-maturidade.md
│   ├── client-it-ui.md
│   └── test-strategy.md
└── tasks.md             # Phase 2 — /speckit-tasks
```

### Source Code (repository root)

```text
ci-api-v2/
├── prisma/schema/
│   ├── it.prisma
│   ├── it-insights.prisma
│   ├── it-fiscalizacao.prisma
│   └── it-maturidade.prisma
├── prisma/seed/
│   ├── seed-it-cis-controls.ts
│   ├── seed-it-lgpd-terms.ts
│   └── seed-it-security-policy-patterns.ts
├── src/common/constants/modulos.ts          # + it
├── src/modules/it/
│   ├── it.module.ts
│   ├── it.controller.ts
│   ├── it.schemas.ts
│   ├── it.mapper.ts
│   ├── repository/
│   ├── use-cases/
│   │   ├── ativo-*.use-case.ts
│   │   ├── incidente-*.use-case.ts
│   │   ├── operador-*.use-case.ts
│   │   ├── apply-sensitive-data-flag.use-case.ts
│   │   └── get-dashboard.use-case.ts
│   └── test/
├── src/modules/it-insights/
│   ├── it-insights.module.ts
│   ├── it-insights.controller.ts
│   ├── lib/
│   │   ├── config-scan.ts
│   │   ├── lgpd-classifier.ts
│   │   └── risk-matrix-tree.ts
│   ├── use-cases/
│   └── jobs/generate-insights-scheduled.job.ts
├── src/modules/it-fiscalizacao/
│   ├── it-fiscalizacao.module.ts
│   ├── lib/backup-validation.ts
│   ├── repository/it-audit-trail.repository.ts   # append-only
│   ├── use-cases/
│   │   ├── run-backup-audit-cycle.use-case.ts
│   │   ├── submit-backup-evidence.use-case.ts
│   │   ├── list-audit-trail.use-case.ts
│   │   └── generate-anpd-notification.use-case.ts
│   └── jobs/backup-audit-scheduled.job.ts
└── src/modules/it-maturidade/
    ├── it-maturidade.module.ts
    ├── lib/
    │   ├── defense-lines.ts
    │   ├── framework-adherence.ts
    │   └── vulnerability-index.ts
    └── use-cases/

ci-client-v2/
├── apps/web/src/modules/it/
│   ├── index.ts                    # IT_OVERRIDES
│   ├── pages/
│   │   ├── ItDashboardPage.tsx
│   │   ├── ItAtivosListPage.tsx
│   │   ├── ItAtivoDetailPage.tsx
│   │   ├── ItIncidentesListPage.tsx
│   │   ├── ItOperadoresPage.tsx
│   │   ├── ItInsightsPage.tsx
│   │   ├── ItFiscalizacaoPage.tsx
│   │   └── ItMaturidadePage.tsx
│   ├── components/
│   ├── api/
│   └── __tests__/
├── apps/web/src/modules/shell/config/
│   ├── navigation.ts               # + bloco it
│   ├── screens.ts                  # + telas it
│   └── license-screens.ts          # + it em modules[]
└── packages/domain/src/lib/licenses.ts   # moduleLicenseConfig.it
```

**Structure Decision**: Paridade estrutural com Compras (4 módulos API + client colocated). Reuso de `FiscalizacaoPanel`, `TraceabilitySheet`, `TableRowActionsMenu`, `useModuleAccess`. Trilha IT e PDF ANPD são extensões novas documentadas em research.md.

## Phase 0 Output

Ver [research.md](./research.md) — 14 decisões resolvidas (registro módulo, trilha append-only, PDF ANPD, cron backup, classificador Cedro, CIS seed, presign upload, etc.).

## Phase 1 Output

| Artefato | Path |
|----------|------|
| Data model | [data-model.md](./data-model.md) |
| REST Base | [contracts/rest-api-it-base.md](./contracts/rest-api-it-base.md) |
| REST Insights | [contracts/rest-api-it-insights.md](./contracts/rest-api-it-insights.md) |
| REST Fiscalização | [contracts/rest-api-it-fiscalizacao.md](./contracts/rest-api-it-fiscalizacao.md) |
| REST Maturidade | [contracts/rest-api-it-maturidade.md](./contracts/rest-api-it-maturidade.md) |
| Client contract | [contracts/client-it-ui.md](./contracts/client-it-ui.md) |
| Test strategy | [contracts/test-strategy.md](./contracts/test-strategy.md) |
| Quickstart | [quickstart.md](./quickstart.md) |

## Complexity Tracking

> Nenhuma violação de constitution que exija justificativa formal.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| `pdf-lib` (nova dep) | SC-009 exige PDF binário ANPD | HTML+print não cumpre "PDF em 1 clique" |
| `ItAuditTrail` dedicado | FR-020 append-only escopado IT | `AuditInterceptor` global não é imutável nem cobre reads |

## Next Step

Executar `/speckit-tasks` para gerar `tasks.md` acionável com vertical slices (registro módulo → Base CRUD → incidentes → LGPD → Cedro → Jatobá → Carvalho → seed → e2e).
