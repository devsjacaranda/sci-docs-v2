# Contract: Client UI — Central de Documentação

**Feature**: 023-global-docs  
**App**: `ci-client-v2/apps/web`  
**Module path**: `apps/web/src/modules/global-docs/`

## Rotas

| Screen ID | Path | Page | Licença |
|-----------|------|------|---------|
| `global-documentacao` | `/global/documentacao` | `GlobalDocumentacaoPage` | Base |
| — | `/global/documentacao/:docId` | `GlobalDocDetailPage` | Base |
| `compras-guia-etp` | `/compras/guia/etp` | redirect → doc ETP seed | Base |

Registro: `GLOBAL_DOCS_OVERRIDES` em `modules/global-docs/index.ts` + `router.tsx`.

## Navegação (`navigation.ts`)

Sem alteração — item existente em **Gestão › Global › Documentação**.

## Layout Central (`GlobalDocumentacaoPage`)

Ordem obrigatória:

1. Breadcrumb: *Global › Documentação*
2. Card introdutório — copy Base (distinto Pau-Brasil / Cedro)
3. **DocFiltersBar** — filtros Módulo, Tipo, Busca (funcionais)
4. Grid de **DocArticleCard** (2–3 colunas responsivas)
5. Estado vazio orientativo quando `total === 0`
6. Paginação se `total > pageSize`

## Layout Detalhe (`GlobalDocDetailPage`)

1. Breadcrumb: *Global › Documentação › {título}*
2. Header: título + badge tipo + módulo + resumo
3. Card contexto — copy consultivo Base
4. Badges de referências (se houver)
5. **DocStepList** — somente se `type === process_guide` e `steps.length > 0`
6. Botão *Voltar* preservando filtros

## ModuleDocsPanel (contextual)

Usado em `ScreenPage` para telas `docs` de módulo ≠ global (ex.: Compras).

- Hook: `useGlobalDocsList({ moduleSlug, type: 'process_guide' })`
- Se 1 resultado → render guia completo (passos)
- Se 0 → mensagem orientativa (sem mock fallback)
- Se N > 1 → lista compacta para seleção

## Componentes

| Componente | Responsabilidade |
|------------|------------------|
| `DocArticleCard` | Card clicável — navega para detalhe |
| `DocFiltersBar` | Select módulo, select tipo, input busca |
| `DocStepList` | Lista numerada Mint (migrar de DocsPanel mock) |
| `ModuleDocsPanel` | Guia contextual por módulo |

## API client

```typescript
// global-docs.api.ts
listGlobalDocs(params: ListGlobalDocsParams): Promise<PaginatedGlobalDocs>
getGlobalDoc(id: string): Promise<GlobalDocDetail>
```

Schemas Zod espelham [rest-api-global-docs.md](./rest-api-global-docs.md).

## Remoções pós-implementação

| Arquivo | Ação |
|---------|------|
| `mock-data.ts` → `globalUsageDocs` | Remover |
| `mock-data.ts` → `moduleProcessGuides` | Remover |
| `shell/components/mock/DocsPanel.tsx` | Remover ou reduzir a re-export |
| Stats estáticos `global-documentacao` em `screens.ts` | Dinamizar ou remover |

## Copy obrigatório (regras-plataforma)

- Título da tela: **Central de Documentação**
- Badge tipos: *Uso do módulo* | *Guia de processo*
- **NUNCA** rotular como Biblioteca Normativa (Pau-Brasil) ou Insights (Cedro)
- Referências consultivas são informativas — sem CTA de download normativo
