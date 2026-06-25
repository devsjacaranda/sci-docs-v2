# Implementation Plan: Ouvidoria Interna

**Branch**: `003-ouvidoria` | **Date**: 2026-06-05 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/003-ouvidoria/spec.md`

## Summary

Implementar módulo **Ouvidoria Base** para servidores autenticados: registro multi-etapa (dados → anexos → revisão → protocolo), lista/filtros, detalhe com timeline, ações Encaminhar/Responder/Encerrar, anexos via **Wasabi** (S3 presigned), entidade global **Address** + catálogo **Municipio**, sigilo opcional do manifestante, e consulta pública por protocolo+chave (API only). Client substitui mock por REST com wizard shadcn. Depende de permissão por setor (spec 002).

## Technical Context

**Language/Version**: TypeScript 5.x; Node.js 20 LTS

**Primary Dependencies**:

| Pacote | Stack |
|--------|-------|
| **ci-api-v2** | NestJS 11, Fastify, Pino, Zod, Prisma 7, PostgreSQL, `@aws-sdk/client-s3`, bcrypt |
| **ci-client-v2** | React 19, Vite 8, Tailwind v4, shadcn/ui, react-router-dom 7, TanStack Query (recomendado) |

**Storage**: PostgreSQL — Address, Municipio, Manifestacao, ManifestacaoAnexo, ManifestacaoEvento, ManifestacaoSequence; object storage Wasabi para binários

**Testing**: Jest unit (use-cases) + e2e (API com StoragePort mock); client typecheck + smoke [quickstart.md](./quickstart.md)

**Target Platform**: API Linux/container; SPA browser

**Project Type**: Full-stack (API + monorepo client)

**Performance Goals**: Lista paginada < 500ms p95; consulta pública < 3s (SC-005); presigned upload direto ao storage

**Constraints**:

- TDD obrigatório (Constitution II)
- Zod only — sem class-validator
- Tenant via AsyncLocalStorage
- `@RequireModulo('ouvidoria')` em rotas internas
- Apenas licença Base — sem Carvalho/Pau-Brasil/Jatobá/Cedro nesta feature
- Copy UI conforme [regras-plataforma.md](../../.cursor/docs/regras-plataforma.md) e mint-palette

**Scale/Scope**: ~6 enums, 6 entidades Prisma, ~15 endpoints REST, 4 páginas client, seed municípios IBGE

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Princípio | Status | Notas |
|-----------|--------|-------|
| I. Spec-Driven | ✅ PASS | Spec 003 validada; plano segue fluxo |
| II. Test-First | ✅ PASS | Use-cases testados antes de controllers; e2e consulta + sigilo |
| III. Stack fixa | ✅ PASS | NestJS 11 + Prisma 7 + React 19 + Vite 8 |
| IV. Multi-tenant | ✅ PASS | Todas entidades com `tenantId`; consulta exige `X-Tenant-ID` |
| IV. Licenças | ✅ PASS | Base only; LicencaGuard mantido; sem features de licenças pagas |
| V. Escopo mínimo | ✅ PASS | Módulos `address` + `ouvidoria`; layout `permissao/` |

**Post-design re-check**: Dois módulos justificados (Address transversal R11); sem violações requiring Complexity Tracking.

## Project Structure

### Documentation (this feature)

```text
specs/003-ouvidoria/
├── plan.md              # Este arquivo
├── research.md          # Decisões técnicas (Phase 0)
├── data-model.md        # Entidades Prisma
├── quickstart.md        # Validação pós-implementação
├── contracts/
│   ├── rest-api-ouvidoria.md
│   └── client-ouvidoria-ui.md
└── tasks.md             # Phase 2 — /speckit-tasks
```

### Source Code (repository root)

```text
ci-api-v2/
├── prisma/
│   ├── schema/
│   │   ├── address.prisma           # NEW Address
│   │   ├── municipio.prisma         # NEW Municipio (IBGE)
│   │   └── manifestacao.prisma      # NEW Manifestacao + Anexo + Evento + Sequence + enums
│   ├── migrations/
│   └── seed/
│       └── municipios.ts            # NEW import IBGE
├── src/
│   └── modules/
│       ├── address/
│       │   ├── address.module.ts
│       │   ├── address.controller.ts
│       │   ├── address.schemas.ts
│       │   ├── use-cases/
│       │   └── repository/
│       └── ouvidoria/
│           ├── ouvidoria.module.ts
│           ├── ouvidoria.controller.ts
│           ├── ouvidoria.schemas.ts
│           ├── ouvidoria.types.ts
│           ├── use-cases/
│           │   ├── create-manifestacao-draft.use-case.ts
│           │   ├── update-manifestacao-draft.use-case.ts
│           │   ├── confirm-manifestacao.use-case.ts
│           │   ├── list-manifestacoes.use-case.ts
│           │   ├── get-manifestacao-detail.use-case.ts
│           │   ├── presign-anexo.use-case.ts
│           │   ├── confirm-anexo.use-case.ts
│           │   ├── encaminhar-manifestacao.use-case.ts
│           │   ├── responder-manifestacao.use-case.ts
│           │   ├── encerrar-manifestacao.use-case.ts
│           │   └── consulta-publica.use-case.ts
│           ├── repository/
│           └── services/
│               └── storage.service.ts   # Wasabi S3
└── test/
    └── ouvidoria.e2e-spec.ts

ci-client-v2/apps/web/src/
├── lib/
│   └── ouvidoria-api.ts             # NEW REST client
├── pages/ouvidoria/
│   ├── ManifestacoesListPage.tsx
│   ├── ManifestacaoWizardPage.tsx
│   └── ManifestacaoDetailPage.tsx
└── components/ouvidoria/
    ├── ManifestacaoWizardSteps.tsx
    ├── AnexoUploadZone.tsx
    ├── ManifestacaoTimeline.tsx
    └── ManifestacaoActionDialogs.tsx
```

**Structure Decision**: Módulo `address` transversal (municípios + CRUD mínimo). Módulo `ouvidoria` concentra domínio e storage. Client extrai páginas de `ScreenPage.tsx` mock para rotas lazy dedicadas — paths inalterados em `screens.ts`.

## Phase 0 — Research

Concluída em [research.md](./research.md). Decisões-chave:

- R1: `Address` global por tenant
- R2: `ManifestacaoSequence` atômica
- R3: Chave consulta com hash bcrypt
- R4: Wasabi presigned upload
- R5: `Municipio` seed IBGE
- R6: Status `rascunho` até confirmar
- R7: Badges critico/vencendo derivados
- R8: Sigilo via DTO filter
- R9: Consulta pública com `X-Tenant-ID`
- R10: Client wizard + React Query
- R11: Módulos `address` + `ouvidoria`
- R12: StoragePort para testes

## Phase 1 — Design

| Artefato | Path |
|----------|------|
| Data model | [data-model.md](./data-model.md) |
| REST contract | [contracts/rest-api-ouvidoria.md](./contracts/rest-api-ouvidoria.md) |
| UI contract | [contracts/client-ouvidoria-ui.md](./contracts/client-ouvidoria-ui.md) |
| Quickstart | [quickstart.md](./quickstart.md) |

## Implementation phases (for /speckit-tasks)

### Phase A — Schema & seed (API)

1. Prisma: Address, Municipio, Manifestacao (+ enums, Anexo, Evento, Sequence)
2. Migration + seed municípios IBGE
3. Seed demo: setor Ouvidoria vinculado ao módulo `ouvidoria`

### Phase B — Address module (API)

1. `GET /address/municipios` autocomplete
2. Repository create/find Address
3. Unit tests

### Phase C — Ouvidoria core (API)

1. Draft CRUD + confirm (protocolo + chave)
2. List/detail com sigilo filter e badges derivados
3. Unit tests RED→GREEN

### Phase D — Anexos & storage (API)

1. `StorageService` + env Wasabi
2. Presign / confirm flow
3. E2e com mock storage

### Phase E — Ações operacionais (API)

1. Encaminhar, responder, encerrar + timeline events
2. Status transition validation
3. E2e fluxo completo

### Phase F — Consulta pública (API)

1. `GET /ouvidoria/consulta` @Public + throttle
2. E2e segurança (chave errada, sigilo)

### Phase G — Client

1. `ouvidoria-api.ts`
2. Wizard 3 etapas + lista + detalhe
3. Wire lazy routes; `useModuleAccess('ouvidoria')`
4. Smoke per quickstart

## Complexity Tracking

> Nenhuma violação de constitution requiring justification.

| Item | Notes |
|------|-------|
| Módulo `address` separado | FR-006 entidade transversal; reuso futuro |
| Presigned upload | FR-007 30 MB; evita proxy binário |
| Dois módulos NestJS | Address reutilizável vs domínio ouvidoria (R11) |

## Risks

| Risk | Mitigation |
|------|------------|
| Wasabi indisponível em dev | MinIO local compatível S3; StoragePort mock em testes |
| Seed IBGE grande | Script incremental; índice nome+uf |
| Chave consulta perdida | Copy UI enfatiza anotação; não reexibir hash |
| Concorrência protocolo | Transaction + ManifestacaoSequence (R2) |

## Dependencies

- **002-auth-setor-permissao**: `ModuloPermissaoGuard`, `@RequireModulo`, seed setor Ouvidoria
- **CONTEXT.md**: entidade Address documentada

## Out of scope (reminder)

- SPA público envio
- UI consulta pública
- Licenças Carvalho, Pau-Brasil, Jatobá, Cedro
- Migração `controle-interno-api`

## Next step

Run **`/speckit-tasks`** to generate `tasks.md` with dependency-ordered implementation items.
