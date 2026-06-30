# Implementation Plan: Identidade visual do tenant (foto e banner)

**Branch**: `025-tenant-branding-config` | **Date**: 2026-06-29 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/025-tenant-branding-config/spec.md`

## Summary

Permitir que o **administrador da plataforma do tenant** configure **foto institucional** e **banner** em `/administracao/plataforma/config`, persistindo por tenant e exibindo na **tela global de boas-vindas** (`GlobalWelcomeDashboard`), substituindo imagens fixas de demonstração.

**Abordagem**:

1. **API** (`sci-api-v2`) — migration Prisma em `Tenant` (`avatarStorageKey`, `bannerStorageKey`); estender módulo `tenant/` com controller, schemas Zod, use-cases e reutilizar `StorageService` (presign upload/download, mesmo fluxo de `auth/me/avatar/presign`).
2. **Client** (`sci-client-monorepo/apps/web`) — novo painel `PlatformTenantConfigPanel` espelhando UX de `PlatformProfilePanel`; hook `useTenantBranding`; consumo na `GlobalWelcomeDashboard`; screen + nav + guard client (`PLATFORM_SCREENS`).
3. **Escopo mínimo** — leitura pública no tenant (JWT); escrita restrita a `admin_plataforma` | `admin_tenant`; **sem** `@RequireLicenca`; **fora de escopo** `@ci/admin-saas`.

## Technical Context

**Language/Version**: TypeScript 5.x / 6.x; Node.js 20 LTS

**Primary Dependencies**:

| Pacote | Stack |
|--------|-------|
| **sci-api-v2** | NestJS 11, Fastify, Pino, Zod (nestjs-zod), Prisma 7, PostgreSQL, AWS SDK S3 (Wasabi) |
| **sci-client-monorepo** | React 19, Vite 8, Tailwind v4, shadcn/ui (`@ci/ui`), react-router-dom 7, Vitest 3, MSW 2 |

**Storage**: PostgreSQL — campos nullable em `Tenant`; blobs em Wasabi/S3 via `StorageService` (`tenantId/branding/avatar|banner.{ext}`)

**Testing**:

| Camada | API | Client |
|--------|-----|--------|
| Unitário | Jest — use-cases (presign, update, remove, guard) | Vitest — hook, upload helper, fallback initials |
| Integração | Supertest — GET branding autenticado; PATCH 403 non-admin | Vitest + MSW — painel config + dashboard |
| Contrato | Zod schemas + fixtures | MSW handlers espelhando REST contract |

**Target Platform**: API Linux/container; SPA browser (`@ci/web`)

**Project Type**: Full-stack (API tenant + client tenant)

**Performance Goals**: GET branding < 200ms p95 (presign download em paralelo); upload presign + PUT client-side sem bloquear UI

**Constraints**:

- TDD obrigatório RED → GREEN → REFACTOR
- Zod only — sem class-validator
- Tenant via AsyncLocalStorage — use-cases/repositories **nunca** recebem `tenantId` explícito
- Skills: `nestjs-module-scaffold`, `testing-conventions`, `tdd`, `auth-patterns`, `prisma-schema-workflow`, `ui-ux-pro-max`, `vite-react-best-practices`
- Copy PT-BR ([regras-plataforma.md](../../../.cursor/docs/regras-plataforma.md)); paleta Mint
- Limites spec: JPEG/PNG; 5 MB foto; 10 MB banner (validação client + presign metadata)

**Scale/Scope**: 1 migration, ~8 use-cases/repos API, 1 controller, ~10 arquivos client, 1 painel novo, 1 dashboard alterado

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Princípio | Status | Notas |
|-----------|--------|-------|
| I. Spec-Driven | ✅ PASS | Spec 025 + checklist validados |
| II. Test-First | ✅ PASS | [contracts/test-strategy.md](./contracts/test-strategy.md) |
| III. Stack fixa | ✅ PASS | NestJS 11 + Prisma 7 + React 19 + Vite 8 + Zod |
| IV. Multi-tenant | ✅ PASS | Branding scoped por tenant ALS; storage keys prefixadas |
| IV. Licenças | ✅ PASS | Base only; **sem** `@RequireLicenca` |
| V. Escopo mínimo | ✅ PASS | Estende `tenant/` existente; client em `modules/tenant/`; reutiliza StorageService |

**Post-design re-check**: Campos no model `Tenant` (1:1) evitam tabela auxiliar. Presign espelha avatar pessoal — zero novo adapter de storage. Guard `@Roles(admin_plataforma, admin_tenant)` alinhado a `isPlatformAdmin` no client. Sem Complexity Tracking.

## Project Structure

### Documentation (this feature)

```text
sci-docs-v2/specs/025-tenant-branding-config/
├── plan.md              # Este arquivo
├── research.md          # Decisões técnicas (Phase 0)
├── data-model.md        # Tenant + branding DTOs
├── quickstart.md        # Validação manual pós-implement
├── contracts/
│   ├── rest-api-tenant-branding.md
│   ├── client-tenant-branding-ui.md
│   └── test-strategy.md
└── tasks.md             # Phase 2 — /speckit-tasks
```

### Source Code (repository root)

```text
sci-api-v2/
├── prisma/
│   ├── schema/tenant.prisma              # + avatarStorageKey, bannerStorageKey
│   └── migrations/...                    # nova migration
└── src/modules/tenant/
    ├── tenant.module.ts                  # + controller, use-cases, StorageModule import
    ├── tenant-branding.controller.ts
    ├── tenant-branding.schemas.ts
    ├── repository/
    │   ├── find-tenant-branding.repository.ts
    │   └── update-tenant-branding.repository.ts
    └── use-cases/
        ├── get-tenant-branding.use-case.ts
        ├── update-tenant-branding.use-case.ts
        ├── presign-tenant-avatar.use-case.ts
        ├── presign-tenant-banner.use-case.ts
        └── test/                         # *.spec.ts por use-case

sci-client-monorepo/apps/web/src/
├── modules/tenant/
│   ├── api/branding.ts
│   ├── hooks/useTenantBranding.ts
│   ├── components/PlatformTenantConfigPanel.tsx
│   └── __tests__/                        # panel + hook Vitest
└── modules/shell/
    ├── config/screens.ts                 # admin-plataforma-config
    ├── config/navigation.ts              # item Configurações
    ├── pages/ScreenPage.tsx              # render painel
    └── components/mock/GlobalWelcomeDashboard.tsx  # consome branding

sci-client-monorepo/apps/web/src/modules/permissao/lib/permissions.ts  # PLATFORM_SCREENS
```

**Structure Decision**: Domínio `tenant/` na API e client (identidade institucional ≠ `setor/` usuários). Upload UX copia padrão de `PlatformProfilePanel` + `auth/api/auth.ts` (presign → PUT → PATCH).

## Phase 0 — Research

Ver [research.md](./research.md) — todas as decisões resolvidas; nenhum NEEDS CLARIFICATION pendente.

## Phase 1 — Design

| Artefato | Caminho |
|----------|---------|
| Data model | [data-model.md](./data-model.md) |
| REST contract | [contracts/rest-api-tenant-branding.md](./contracts/rest-api-tenant-branding.md) |
| UI contract | [contracts/client-tenant-branding-ui.md](./contracts/client-tenant-branding-ui.md) |
| Test strategy | [contracts/test-strategy.md](./contracts/test-strategy.md) |
| Quickstart | [quickstart.md](./quickstart.md) |

**Próximo passo**: `/speckit-tasks`
