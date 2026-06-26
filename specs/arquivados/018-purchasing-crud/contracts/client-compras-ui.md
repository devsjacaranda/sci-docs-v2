# Contract: Client UI — Compras (Base)

**Feature**: 018-purchasing-crud  
**App**: `@ci/web` (`ci-client-v2/apps/web`)  
**Module slug**: `compras`  
**Licenses**: `['base']` only — sem gates Jatobá/Cedro/Carvalho/Pau-Brasil nesta entrega

## Rotas

| Path | Component | Descrição |
|------|-----------|-----------|
| `/compras` | `DemandasListPage` | Tabela + filtros PCA/status + botão *Gerenciar PCAs* + *Nova demanda* |
| `/compras/novo` | `DemandaCreatePage` | Form PCA (ativos only) + título + objeto + setor opcional |
| `/compras/:demandaId` | `DemandaHubPage` | Cabeçalho + checklist 7 cards quebra-cabeça |
| `/compras/:demandaId/dfd` | `DfdPage` | Form DFD |
| `/compras/:demandaId/etp` | `EtpPage` | Form ETP + toggle dispensado |
| `/compras/:demandaId/analise-riscos` | `AnaliseRiscosPage` | Lista editável de riscos |
| `/compras/:demandaId/tr` | `TrPage` | Form TR |
| `/compras/:demandaId/pesquisa-precos` | `PesquisaPrecosPage` | Valor + fonte |
| `/compras/:demandaId/dotacao` | `DotacaoPage` | Dotação orçamentária |
| `/compras/:demandaId/parecer` | `ParecerPage` | Parecer jurídico |

Registrar em `router.tsx` — **substituir** entradas mock `compras-*` de `ScreenPage` para estas rotas.

---

## Layout compartilhado

### `ComprasLayout` (opcional wrapper)

- Breadcrumb padrão: **Compras** → contexto
- Paleta Mint ([mint-palette.mdc](../../../.cursor/rules/mint-palette.mdc))

### `DemandaArtefactLayout`

Usado em todas as sub-rotas de artefato (US-8):

- Breadcrumb: **Compras → Demanda #{number} → {artefato}**
- Checklist lateral `ArtefactChecklist` — 7 itens clicáveis com estados visuais
- Link **Voltar ao hub** → `/compras/:demandaId`
- Ações: **Salvar** (primary teal/mint) + upload comprovante opcional

---

## Componentes

| Componente | Responsabilidade |
|------------|------------------|
| `DemandasTable` | Colunas Número, Título, Objeto, PCA, Status, Progresso |
| `DemandasFilters` | Select PCA + select Status |
| `PcaManageSheet` | List/create/close PCA — modal/sheet na listagem |
| `DemandaProgressBadge` | Badge status derivado |
| `ArtefactChecklist` | Cards ou lista lateral — estados Preenchido/Pendente/Dispensado |
| `ComprovanteUpload` | Presign flow; erro não bloqueia save estruturado |
| `EmptyStateCompras` | Tenant sem PCA / sem demandas — CTAs orientadores |

---

## Vocabulário UI (obrigatório)

| Usar | Nunca |
|------|-------|
| demanda / demandas | ato |
| Compras (módulo) | Purchasing |
| PCA | — |
| Rascunho / Em andamento / Concluído | draft labels em inglês na UI |

Copy: [regras-plataforma.md](../../../.cursor/docs/regras-plataforma.md)

---

## Estados visuais checklist

| State API | Cor/ícone sugerido |
|-----------|-------------------|
| `filled` | Mint/teal — check |
| `pending` | Slate muted — círculo vazio |
| `waived` | Badge "Dispensado" — ETP only |

Progresso listagem: texto `3/7 preenchidos` — **sem** input manual.

---

## Fluxos UX

### Listagem (`/compras`)

1. Carregar demandas paginadas da API
2. Filtros debounced 300ms (pcaId, status)
3. *Gerenciar PCAs* → `PcaManageSheet`
4. *Nova demanda* → `/compras/novo`

### Criar demanda (`/compras/novo`)

1. Se zero PCAs ativos → empty state + CTA abrir sheet PCAs
2. Select PCA — apenas `active`
3. Submit → redirect `/compras/:id`

### Hub (`/compras/:id`)

1. Header: número, título, objeto, PCA, setor, status badge, progresso
2. Grid 7 cards — click navega sub-rota
3. PDF export: botão disabled + tooltip FR-028

### ETP dispensado

1. Toggle *Dispensado* → exige motivo
2. Se dados técnicos existentes → dialog confirmação antes de salvar

---

## API client layer

```
modules/compras/api/
├── pca.ts          # list, create, close
├── demandas.ts     # list, create, get, delete
├── artefatos.ts    # upsert/get por suffix + presign/confirm
└── types.ts        # espelho response Zod
```

React Query keys: `['compras', 'demandas', filters]`, `['compras', 'demanda', id]`.

---

## Navegação shell

Atualizar `navigation.ts`:

- Entrada **Compras** → `/compras` (remover sub-itens mock PCA/demandas separados se existirem)

Remover ou marcar deprecated screens mock em `screens.ts` substituídos por rotas reais.

---

## Fora de escopo (UI desabilitada ou ausente)

| Rota mock existente | Tratamento |
|---------------------|------------|
| `/compras/auditoria` | Mantida mock ou stub até spec 019 |
| `/compras/insights` | Idem spec 020 |
| `/compras/maturidade` | Idem spec 021 |
| `/compras/dashboard` | Remover ou redirect `/compras` |
| `/compras/demandas/*` | Substituída por rotas canônicas |
| `/compras/pca/*` | Substituída por modal |

---

## Acessibilidade

- Cards checklist: `role="link"` ou botões com `aria-label` incluindo estado
- Filtros: labels associados
- Contraste CTA Mint conforme rule mint-palette (texto escuro em fundo mint no dark mode)
