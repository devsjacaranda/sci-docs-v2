# Data Model: Central de Documentação (global-docs)

**Feature**: 023-global-docs · **Date**: 2026-06-26

> Campos Prisma/API em **inglês**; labels UI em **PT-BR** via mapper.

## Schema: `global-docs.prisma`

### Enums

```prisma
enum GlobalDocType {
  module_usage    // UI: "Uso do módulo"
  process_guide   // UI: "Guia de processo"
}
```

### GlobalDocArticle

| Field EN | UI PT-BR | Required | Notes |
|----------|----------|----------|-------|
| `id` | — | yes | UUID |
| `tenantId` | — | yes | FK Tenant |
| `slug` | — | yes | único por tenant |
| `title` | Título | yes | |
| `type` | Tipo | yes | `GlobalDocType` |
| `moduleSlug` | Módulo | yes | `ModuloSlug` |
| `summary` | Resumo | yes | |
| `deletedAt` | — | no | soft delete |
| `createdAt` | — | yes | |
| `updatedAt` | Data de atualização | yes | |

**Índices**: `(tenantId, moduleSlug, type, deletedAt)`, `(tenantId, slug)` UNIQUE.

**Relations**: `steps`, `references`, `tenant`.

### GlobalDocStep

| Field EN | Required | Notes |
|----------|----------|-------|
| `id` | yes | UUID |
| `articleId` | yes | FK CASCADE |
| `sortOrder` | yes | ≥ 1 |
| `title` | yes | |
| `description` | yes | |
| `tip` | no | |

### GlobalDocReference

| Field EN | Required | Notes |
|----------|----------|-------|
| `id` | yes | UUID |
| `articleId` | yes | FK CASCADE |
| `sortOrder` | yes | |
| `label` | yes | texto livre |

## Seed mínimo (FR-010)

| moduleSlug | Doc 1 | Doc 2 |
|------------|-------|-------|
| ouvidoria | module_usage | module_usage |
| juridico | module_usage | module_usage |
| compras | module_usage | process_guide ETP |
| contratos | module_usage | module_usage |
| patrimonio | module_usage | module_usage |
| protocolo | module_usage | module_usage |

Total: **12 artigos**; **1** com passos.
