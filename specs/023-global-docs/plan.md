# Implementation Plan: Desmockar Central de Documentação

**Branch**: `023-global-docs` | **Date**: 2026-06-26 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/023-global-docs/spec.md`

## Summary

Substituir a **Central de Documentação** mockada (`/global/documentacao`) por catálogo **persistido por tenant** com API read-only e UI conectada.

| Camada | Entrega |
|--------|---------|
| **API** | Módulo Nest `global-docs` — `GET /global/docs`, `GET /global/docs/:id` |
| **DB** | `global-docs.prisma` — artigos, passos ordenados, referências |
| **Seed** | ≥ 2 documentos por módulo mockado (6 módulos = 12+ artigos); guia ETP Compras com passos |
| **Client** | `modules/global-docs/` — hooks + páginas; refatorar `GlobalDocsPanel` / `ModuleDocsPanel`; remover `globalUsageDocs` e `moduleProcessGuides` |

Escopo **leitura + seed** — sem CRUD administrativo na UI (spec Assumptions).

## Technical Context

**Language/Version**: TypeScript 5.x / 6.x; Node.js 20 LTS

**Primary Dependencies**:

| Pacote | Stack |
|--------|-------|
| **ci-api-v2** | NestJS 11, Fastify, Pino, Zod, Prisma 7, PostgreSQL |
| **ci-client-v2** | React 19, Vite 8, Tailwind v4, shadcn/ui, react-router-dom 7, Vitest 3, MSW 2 |

**Storage**: PostgreSQL — `global-docs.prisma`; artigos tenant-scoped; passos e referências normalizados

**Testing**:

| Camada | API | Client |
|--------|-----|--------|
| Unitário | Jest — mapper PT-BR, filtros list | Vitest — mappers, filter state |
| Contrato | Zod round-trip + fixtures JSON | Zod + MSW handlers |
| Integração | Use-cases + Prisma mock | Page + MSW |
| E2E | Supertest list/detail/filters | RTL central + detalhe + ModuleDocsPanel |

**Target Platform**: API Linux/container; SPA browser

**Project Type**: Full-stack (API + client)

**Performance Goals**: Listagem GET &lt; 300ms p95 com ≤ 50 artigos/tenant; busca/filtro percebida instantânea (&lt; 1s)

**Constraints**:

- TDD obrigatório (Constitution II)
- Zod only — sem class-validator
- Tenant via AsyncLocalStorage — nunca `tenantId` manual
- Licença **Base** obrigatória (`@RequireLicenca('base')`); **sem** `@RequireModulo` (escopo global transversal)
- Read-only na API v1 — conteúdo via seed
- Vocabulário UI: [regras-plataforma.md](../../../.cursor/docs/regras-plataforma.md)
- Distinção semântica Base (manuais) vs Pau-Brasil vs Cedro vs Jatobá preservada no copy
- Remover dependência de `mock-data.ts` para documentação após implementação

**Scale/Scope**: 3 entidades Prisma, 2 endpoints REST, 2 páginas client (+ refator 2 painéis shell), seed ~14 artigos, ~25 arquivos estimados

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Princípio | Status | Notas |
|-----------|--------|-------|
| I. Spec-Driven | ✅ PASS | Spec 023 validada; plano segue fluxo |
| II. Test-First | ✅ PASS | test-strategy.md; TDD por slice vertical |
| III. Stack fixa | ✅ PASS | NestJS 11 + Prisma 7 + React 19 + Vite 8 |
| IV. Multi-tenant | ✅ PASS | `tenantId` em `GlobalDocArticle`; soft delete opcional |
| IV. Licenças | ✅ PASS | Base only; sem confundir com Pau-Brasil |
| V. Escopo mínimo | ✅ PASS | 1 módulo API read-only; client `modules/global-docs/` |

**Post-design re-check**: Tabela filha `GlobalDocStep` justificada — ordenação explícita e queries de detalhe; alternativa JSON única rejeitada (validação de ordem e testes). Sem Complexity Tracking necessário.

## Project Structure

### Documentation (this feature)

```text
specs/023-global-docs/
├── plan.md              # Este arquivo
├── research.md          # Decisões técnicas (Phase 0)
├── data-model.md        # Entidades Prisma
├── quickstart.md        # Validação manual + comandos
├── contracts/
│   ├── rest-api-global-docs.md
│   ├── client-global-docs-ui.md
│   └── test-strategy.md
└── tasks.md             # Phase 2 — /speckit-tasks
```

### Source Code (repository root)

```text
ci-api-v2/
├── prisma/schema/
│   └── global-docs.prisma
├── prisma/seed/
│   └── seed-global-docs.ts          # ≥2 docs × 6 módulos
└── src/modules/global-docs/
    ├── global-docs.module.ts
    ├── global-docs.controller.ts
    ├── global-docs.schemas.ts
    ├── global-docs.mapper.ts
    ├── repository/
    │   ├── list-global-docs.repository.ts
    │   └── find-global-doc-by-id.repository.ts
    └── use-cases/
        ├── list-global-docs.use-case.ts
        └── get-global-doc.use-case.ts

ci-client-v2/apps/web/src/
├── modules/global-docs/
│   ├── index.ts                       # GLOBAL_DOCS_OVERRIDES
│   ├── api/
│   │   ├── global-docs.api.ts
│   │   └── global-docs.schemas.ts
│   ├── hooks/
│   │   ├── useGlobalDocsList.ts
│   │   └── useGlobalDocDetail.ts
│   ├── pages/
│   │   ├── GlobalDocumentacaoPage.tsx   # substitui GlobalDocsPanel inline
│   │   └── GlobalDocDetailPage.tsx
│   └── components/
│       ├── DocArticleCard.tsx
│       ├── DocStepList.tsx
│       └── DocFiltersBar.tsx
└── modules/shell/
    ├── pages/ScreenPage.tsx             # remover import mock DocsPanel
    └── components/mock/DocsPanel.tsx  # refatorar ModuleDocsPanel ou deprecar
```

**Structure Decision**: API em `global-docs` espelhando slug da spec; client em `modules/global-docs/` com override de rota em `router.tsx` para `/global/documentacao` e `/global/documentacao/:docId`. Shell mantém screen config; composição migra para páginas do módulo.

## Complexity Tracking

> Nenhuma violação da Constitution — seção não aplicável.

## Phase 0 → research.md

Decisões consolidadas em [research.md](./research.md).

## Phase 1 → Design artifacts

- [data-model.md](./data-model.md)
- [contracts/rest-api-global-docs.md](./contracts/rest-api-global-docs.md)
- [contracts/client-global-docs-ui.md](./contracts/client-global-docs-ui.md)
- [contracts/test-strategy.md](./contracts/test-strategy.md)
- [quickstart.md](./quickstart.md)

## Implementation Notes (for /speckit-tasks)

1. **Ordem sugerida**: schema + migration → repositories + use-cases (TDD) → controller → seed → client API/hooks → páginas → remover mock → e2e.
2. **Seed modules**: `ouvidoria`, `juridico`, `compras`, `contratos`, `patrimonio`, `protocolo` — migrar copy dos mocks existentes + expandir para 2º documento por módulo.
3. **ModuleDocsPanel**: buscar `GET /global/docs?moduleSlug=compras&type=process_guide` — exibir guia principal ou lista se múltiplos.
4. **Stats da screen** `global-documentacao`: calcular a partir da API (contagem manuais/guias) ou remover stats estáticos mock.
5. **Rota compras-guia-etp** (`/compras/guia/etp`): redirecionar para doc seed ETP ou linkar `docId` fixo no seed.
