# Test Strategy: Central de Documentação (global-docs)

**Feature**: 023-global-docs · **Date**: 2026-06-26

TDD obrigatório (Constitution II): RED → GREEN → REFACTOR.

## Pirâmide

| Camada | Ferramenta | Foco |
|--------|------------|------|
| Unitário API | Jest | mapper typeLabel/moduleLabel, order steps |
| Unitário Client | Vitest | mappers, filter debounce |
| Contrato | Zod round-trip | schemas ↔ fixtures contracts/ |
| Integração API | Jest + Prisma mock | list filters, get detail |
| Integração Client | Vitest + MSW | pages + ModuleDocsPanel |
| E2E API | Supertest | list/detail/404 |
| E2E Client | RTL | US1–US5 jornadas |

## Suites API (`ci-api-v2`)

| Arquivo | Cobre |
|---------|-------|
| `global-docs/global-docs.mapper.spec.ts` | typeLabel, moduleLabel |
| `global-docs/use-cases/list-global-docs.use-case.spec.ts` | FR-008, FR-009 |
| `global-docs/use-cases/get-global-doc.use-case.spec.ts` | FR-007, steps order |
| `test/global-docs.e2e-spec.ts` | auth, tenant, 404 |

## Suites Client (`ci-client-v2/apps/web`)

| Arquivo | Cobre |
|---------|-------|
| `global-docs/api/global-docs.schemas.spec.ts` | contrato Zod |
| `global-docs/pages/GlobalDocumentacaoPage.test.tsx` | US1, US3, empty state |
| `global-docs/pages/GlobalDocDetailPage.test.tsx` | US2, steps |
| `global-docs/components/ModuleDocsPanel.test.tsx` | US5, no mock fallback |
| MSW `handlers/global-docs.ts` | fixtures seed |

## Cenários críticos

1. List sem filtros → retorna seed Jacaranda ≥ 12
2. Filtro `moduleSlug=compras` → ≥ 2 itens
3. GET detail ETP → 7 passos ordenados
4. Tenant vazio → items `[]`, UI empty state
5. ID inválido → 404, UI feedback
6. `mock-data.ts` sem `globalUsageDocs` após implementação
