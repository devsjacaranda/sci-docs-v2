# Research: Desmockar Central de Documentação

**Feature**: 023-global-docs · **Date**: 2026-06-26

## R1 — Módulo API e prefixo REST

**Decision**: Novo módulo Nest `global-docs` com prefixo `/global/docs`. Guards: JWT + Tenant + `@RequireLicenca('base')`. **Sem** `@RequireModulo` — escopo transversal Base, paridade com telas globais (`/global/dashboard`, `/global/licencas`).

**Rationale**: FR-014; documentação não pertence a um módulo operacional único; `ModuloSlug.global` existe mas não exige guard de módulo.

**Alternatives considered**:

- Sub-rota em `TenantModule` → rejeitado (domínio distinto, viola modularidade)
- CRUD completo na v1 → rejeitado (spec limita a leitura + seed)

---

## R2 — Modelo de dados: artigo + passos + referências

**Decision**: Três entidades em `global-docs.prisma`:

- `GlobalDocArticle` — catálogo (título, tipo, `moduleSlug`, resumo, `tenantId`, timestamps, soft delete)
- `GlobalDocStep` — FK `articleId`, `sortOrder`, título, descrição, dica opcional
- `GlobalDocReference` — FK `articleId`, `sortOrder`, `label` (texto livre)

Enums Prisma:

- `GlobalDocType`: `module_usage` | `process_guide` (API mapper → *Uso do módulo* | *Guia de processo*)

**Rationale**: FR-002–004; passos ordenados exigem tabela filha; referências consultivas separadas facilitam seed e testes.

**Alternatives considered**:

- JSON blob único (`content Json`) → rejeitado (ordenação frágil, difícil validar Zod)
- Tabela global sem tenant → rejeitado (Constitution IV — isolamento por órgão)

---

## R3 — Endpoints read-only

**Decision**:

| Método | Rota | Uso |
|--------|------|-----|
| GET | `/global/docs` | Lista paginada; query: `moduleSlug`, `type`, `search`, `page`, `pageSize` |
| GET | `/global/docs/:id` | Detalhe com `steps[]` e `references[]` |

Sem POST/PATCH/DELETE na v1.

**Rationale**: FR-005–009, FR-012; escopo spec Assumptions.

**Alternatives considered**:

- GraphQL → rejeitado (stack REST fixa)
- Incluir CRUD admin plataforma → rejeitado (fora de escopo)

---

## R4 — Seed e migração de conteúdo mock

**Decision**: `seed-global-docs.ts` invocado em `seed-jacaranda-tenant.ts`:

- **6 módulos** alvo (FR-010): ouvidoria, juridico, compras, contratos, patrimonio, protocolo
- **≥ 2 artigos** cada (12+ total)
- Compras: 1× `process_guide` com 7 passos ETP (migrar `moduleProcessGuides.compras`)
- Demais: migrar títulos/resumos de `globalUsageDocs` + criar 2º artigo complementar por módulo
- `moduleSlug` usa enum `ModuloSlug` existente

**Rationale**: FR-010–011; SC-002; reutiliza copy validado em produto.

**Alternatives considered**:

- Seed global cross-tenant → rejeitado (tenant Jacaranda demo é referência)
- Markdown files no repo servidos pela API → rejeitado (persistência inconsistente com multi-tenant)

---

## R5 — Client: módulo vs shell inline

**Decision**: Criar `modules/global-docs/` com:

- `GlobalDocumentacaoPage` — lista + filtros (substitui lógica de `GlobalDocsPanel`)
- `GlobalDocDetailPage` — rota `/global/documentacao/:docId`
- `ModuleDocsPanel` movido/refatorado para `modules/global-docs/components/ModuleDocsPanel.tsx` consumindo API filtrada por `moduleSlug`
- Registrar `GLOBAL_DOCS_OVERRIDES` em `router.tsx`
- Remover `globalUsageDocs` e `moduleProcessGuides` de `mock-data.ts`

**Rationale**: Constitution V — espelho API; shell permanece composition root mínimo.

**Alternatives considered**:

- Manter tudo em `shell/components/mock/` → rejeitado (nome mock incorreto pós-desmock; viola espelho modular)
- React Query sem módulo dedicado → rejeitado (colocation com API schemas)

---

## R6 — Filtros e busca

**Decision**: Filtros server-side na listagem (`moduleSlug`, `type`, `search` ILIKE em título/resumo). Client debounce 300ms na busca. Filtros UI reutilizam badges existentes (*Módulo*, *Tipo*, *Busca*) — agora funcionais.

**Rationale**: FR-008–009, SC-003; volume pequeno mas padrão consistente com listas operacionais.

**Alternatives considered**:

- Filtro só client-side → rejeitado (não escala; inconsistente com API-first)

---

## R7 — Detalhe e navegação

**Decision**: Cards na central são clicáveis → navegam para `/global/documentacao/:docId`. Breadcrumb: *Global › Documentação › {título}*. Botão voltar preserva filtros via `location.state` ou query string.

**Rationale**: FR-007; US2 acceptance scenarios.

**Alternatives considered**:

- Sheet lateral sem rota → rejeitado (sem URL compartilhável; pior deep-link)

---

## R8 — Stats da screen config

**Decision**: Remover stats hardcoded mock em `screens.ts` para `global-documentacao` **ou** popular via hook que conta tipos após load da API (preferível: stats dinâmicos no page header).

**Rationale**: SC-001; evita números fabricados (*6 manuais / 8 módulos*).

**Alternatives considered**:

- Manter stats estáticos → rejeitado (contradiz desmock)
