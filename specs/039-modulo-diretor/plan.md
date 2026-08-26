# Implementation Plan: Módulo Diretor

**Branch**: `039-modulo-diretor` | **Date**: 2026-08-25 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/039-modulo-diretor/spec.md`

## Summary

Tela **somente leitura** no `apps/web` (`/diretor`) que aglomera KPIs já existentes de Ouvidoria e Diagnóstico, recortes de período (ano/mês global + presets 7/3 dias por bloco), ações por usuário e auditoria geral da plataforma (`AuditLog`).

**API** (`ci-api-v2`): novo módulo de domínio `diretor` — endpoints GET dedicados sob `/diretor/*`, `DiretorAccessGuard` (papel **ou** e-mail nominado + tenant AGEMAN), cache in-process Map+TTL (sem Redis), paginação `{ items, total, page, limit }`. Sem tabelas novas; índice `(tenantId, createdAt)` em `AuditLog`.

**Client** (`ci-client-v2/apps/web`): módulo `diretor/` com React Query (padrão SIGED), carga independente por bloco, listas paginadas e chunking do bloco de auditoria. Sem tela em `apps/admin-saas`.

## Technical Context

**Language/Version**: TypeScript 5.x; Node.js 20+ LTS

**Primary Dependencies**:

| Pacote | Stack |
| --- | --- |
| **ci-api-v2** | NestJS 11, Fastify, Pino, Zod v4 (nestjs-zod), Prisma 7, PostgreSQL |
| **ci-client-v2** | React 19, Vite 8, Tailwind v4, shadcn/ui, React Query 5, Zod v3, Vitest |

**Storage**: PostgreSQL existente — `Manifestacao` / `ManifestacaoEvento`, `DiagnosticoProcessoMarcador`, `DocumentoInstitucional`, `AuditLog`. Sem modelo novo. Migration: índice `AuditLog(tenantId, createdAt)`.

**Testing**:

| Camada | API | Client |
| --- | --- | --- |
| Unitário | Jest — guard, schemas, resolução de período, use-cases | Vitest — `can-access-diretor`, period resolver, mappers |
| Contrato | fixtures + Zod `safeParse` | parse de response schemas |
| Integração | use-cases + Prisma mock | RTL da página (filtros, 403, estados vazios) |

**Target Platform**: API Linux/container; SPA tenant (`@ci/web`) com `VITE_TENANT_ID=ageman`

**Project Type**: Full-stack (API + client tenant)

**Performance Goals**:

- Primeira carga dos dois blocos de KPI < 5s percebidos (SC-001)
- Revisita do mesmo recorte ainda no TTL: < 2s (SC-001)
- `GET /diretor/*/kpis` p95 < 400ms com cache hit; miss limitado a agregações já usadas pelos dashboards
- Listas: `limit` default 20, max 50; nunca retornar o histórico inteiro

**Constraints**:

- TDD obrigatório (Constitution II)
- Zod only — sem class-validator
- Tenant via AsyncLocalStorage — nunca passar `tenantId` manual nos services
- Sem Redis / sem `cache-manager` — Map+TTL in-process (padrão `SigedCacheService`)
- Sem licença nova — tela Base
- Sem `ModuloSlug` `diretor` — evita `ModuloSetor` / `ModuloPermissaoGuard`
- E-mail **não** está no JWT — guard faz lookup
- `admin_saas` não autentica em `apps/web` hoje (ver [research.md](./research.md) R2)
- Copy/UI: [regras-plataforma.md](../../../.cursor/docs/regras-plataforma.md); paleta Mint

**Scale/Scope**: 1 módulo API novo (~20 arquivos), 1 migration de índice, 1 página client + hooks/api, 5 user stories; 2 blocos de módulo nesta entrega (extensível)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Princípio | Status | Notas |
| --- | --- | --- |
| I. Spec-Driven | PASS | Spec 039 + checklist validados |
| II. Test-First | PASS | [contracts/test-strategy.md](./contracts/test-strategy.md) — RED antes de guard/schemas/use-cases |
| III. Stack fixa | PASS | NestJS 11 + Prisma 7 + React 19 + Zod; sem Redis |
| IV. Multi-tenant | PASS | Guard recusa tenant ≠ AGEMAN; Prisma injeta `tenantId` |
| IV. Licenças | PASS | Sem `@RequireLicenca` — tela Base; não cria slug de licença |
| V. Escopo mínimo | PASS | Reusa agregações/KPIs existentes; 1 controller + 1 schemas; pastas `repository/` + `use-cases/` |

**Post-design re-check**: sem tabelas novas; índice additive; guard local (não `APP_GUARD`); frontend só em `apps/web`. Sem violações. Sem Complexity Tracking.

## Project Structure

### Documentation (this feature)

```text
civ2-docs/specs/039-modulo-diretor/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   ├── rest-api-diretor.md
│   ├── client-diretor-ui.md
│   └── test-strategy.md
└── tasks.md             # Phase 2 — /speckit-tasks
```

### Source Code (repository root)

```text
ci-api-v2/
├── prisma/schema/audit-log.prisma          # + @@index([tenantId, createdAt])
├── prisma/migrations/20260825*_diretor_audit_log_created_at/
└── src/modules/diretor/
    ├── diretor.module.ts
    ├── diretor.controller.ts
    ├── diretor.schemas.ts
    ├── diretor.constants.ts                # e-mail nominado + TTL + AGEMAN ids
    ├── diretor.types.ts
    ├── guards/diretor-access.guard.ts
    ├── services/diretor-cache.service.ts
    ├── lib/resolve-diretor-period.ts
    ├── lib/resolve-diretor-actor-email.ts
    ├── repository/
    │   ├── get-ouvidoria-kpis.repository.ts
    │   ├── list-ouvidoria-acoes.repository.ts
    │   ├── get-diagnostico-kpis.repository.ts
    │   ├── list-diagnostico-acoes.repository.ts
    │   └── list-audit-logs.repository.ts
    └── use-cases/
        ├── get-ouvidoria-kpis.use-case.ts
        ├── list-ouvidoria-acoes.use-case.ts
        ├── get-diagnostico-kpis.use-case.ts
        ├── list-diagnostico-acoes.use-case.ts
        └── list-audit-logs.use-case.ts

ci-client-v2/apps/web/src/
├── app/router.tsx                          # DIRETOR_OVERRIDES
├── modules/shell/config/
│   ├── screens.ts                          # diretor-dashboard
│   └── navigation.ts                       # grupo Diretoria (AGEMAN)
└── modules/diretor/
    ├── pages/DiretorPage.tsx
    ├── components/                         # blocos KPI, filtros, listas
    ├── api/diretor.ts
    ├── api/diretor.schemas.ts
    ├── hooks/use-diretor-*.ts
    ├── lib/can-access-diretor.ts
    ├── lib/resolve-diretor-period.ts
    └── constants/diretor-cache.ts
```

**Structure Decision**: módulo de domínio novo `diretor` (espelho API ↔ client), registrado em `app.module.ts` após `DiagnosticoModule`. Não adicionar `diretor` a `MODULO_SLUGS`. Tela no catálogo com `moduloSlug: 'global'` + filtro de nav no client (AGEMAN + papel/e-mail).

## Complexity Tracking

Nenhuma violação constitucional. O e-mail hardcoded é decisão de produto (spec FR-001), isolado em `diretor.constants.ts`.
