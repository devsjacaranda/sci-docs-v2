# Contract: Client UI — Compras Insights Cedro

**Feature**: 020-purchasing-insights  
**Route**: `/compras/insights`  
**Screen ID**: `compras-insights`  
**Licença**: Cedro — badge **Somente leitura**

Espelha [015 client-gabinete-insights-ui.md](../../arquivados/015-gabinete-cedro-insights-integrado/contracts/client-gabinete-insights-ui.md), com extensões PNCP simulado e export.

## Navegação

| Origem | Destino | Cliques (SC-001) |
|--------|---------|------------------|
| `/compras` overview | Card *Insights IA* / nav Compras | 1–2 |
| Shell nav | *Insights IA* | 1–2 |

**Substituir** mock `ScreenPage` → `CedroModulePanel` por página real via router override.

---

## Layout da página

### Header

| Elemento | Conteúdo |
|----------|----------|
| Título | Insights IA — Compras |
| Subtítulo | Licença Cedro: insights consultivos sobre demandas e referências simuladas PNCP/COMPRASNET — **nenhum registro será alterado**. |
| Badge | **Somente leitura** |

### Stats row

| Label | Fonte |
|-------|-------|
| Insights ativos | `insights.length` |
| Última geração | `batch.generatedAt` formatado |
| Impacto alto/crítico | count `impact === high \| critical` |
| Natureza | Somente leitura / Cedro |

### Seção principal — `InsightsPanel` (shared)

Componente `InsightCard` por item:

| Campo UI | API field |
|----------|-----------|
| Título | `title` |
| Impacto chip | `impactLabel` |
| Categoria | `categoryLabel` |
| Fonte | `sourceLabel` — interno ou *PNCP/COMPRASNET — simulado* |
| Resumo | `summary` |
| Recomendação | `recommendation` |
| Badge simulado | quando `category === external_benchmark` → chip *Dados simulados — MVP* |
| Ação | *De onde veio este insight?* |

### Ações primárias

| Label | Comportamento |
|-------|---------------|
| **Consultar IA** | `POST /compras/insights/generate` body `{ origin: 'on_demand' }`; dialog confirmação; toast sucesso ou 429 |
| **Exportar relatório** | `GET /compras/insights/export` → download HTML; desabilitado se sem geração |

Copy Consultar IA: *Análise consultiva — demandas e referências simuladas; nenhum registro será alterado.*

**NUNCA** label *Gerar insights* — usar *Consultar IA* (regras-plataforma).

### Histórico — `InsightsHistoryPanel` (shared)

`GET /compras/insights/batches`; seleção carrega `GET /batches/:id`. Mínimo 2 gerações anteriores visíveis (FR-010).

### Estado vazio

| `emptyReason` | Mensagem |
|---------------|----------|
| `no_data` | Registre demandas para habilitar insights. |
| `insufficient_volume` | Dados insuficientes no período — continue operando Compras. |
| `never_generated` | Acione *Consultar IA* para a primeira análise. |

CTA: **Consultar IA** quando aplicável.

### Banner stale

Se `batch.isStale === true` (&gt; 7 dias): aviso *Geração desatualizada* + CTA Consultar IA.

---

## Sheet de rastreio — `InsightTraceSheet` (shared, estendido)

- Abertura: ~85% viewport (R-40)
- Título: **De onde veio este insight**
- Fetch: `GET /compras/insights/:id/trace`
- Link demanda: `/compras/:demandaId` quando presente
- **Seção consultas externas** (quando `externalQueries` presente):
  - Título: *PNCP/COMPRASNET — simulado*
  - Objeto consultado, mediana, faixa, contratos similares, fornecedores fictícios
  - Disclaimer: *Dados simulados — MVP. Integração real não está ativa.*

---

## API client (`modules/compras/api/insights.ts`)

| Função | Endpoint |
|--------|----------|
| `fetchComprasInsights()` | GET `/compras/insights` |
| `fetchComprasInsightBatches(page, limit)` | GET `/compras/insights/batches` |
| `fetchComprasInsightBatchDetail(id)` | GET `/compras/insights/batches/:id` |
| `fetchComprasInsightTrace(id)` | GET `/compras/insights/:id/trace` |
| `generateComprasInsights(origin?)` | POST `/compras/insights/generate` |
| `exportComprasInsightsReport()` | GET `/compras/insights/export` |

Tipos + mappers em `insights-mappers.ts`; erro `InsightsApiError` com `code` throttle/export.

---

## Componentes shared (`modules/shared/components/cedro/`)

Props parametrizadas (backward-compatible):

| Prop | Compras | Gabinete | Ouvidoria |
|------|---------|----------|-----------|
| `moduleId` | `compras` | `gabinete` | `ouvidoria` |
| `detailPathPrefix` | `/compras` | `/gabinete/atos` | `/ouvidoria/manifestacoes` |
| `fetchTrace` | compras API | gabinete API | ouvidoria API |

Extensão trace: `externalQueries?: CedroExternalQuery[]` — render condicional.

---

## Acesso negado

| Cenário | Comportamento |
|---------|---------------|
| Sem módulo Compras | `AccessDenied403` — copy padronizada |
| Sem licença Cedro | Rota oculta na nav; acesso direto → alerta licença (shell) |

---

## Vocabulário UI (obrigatório)

- **demanda/demandas** — nunca *ato* neste módulo
- **Somente leitura** — nunca *Read-only*
- **Consultar IA** — nunca *Gerar insights*
- **Dados simulados — MVP** — em insights PNCP

Referência: [regras-plataforma.md](../../../../.cursor/docs/regras-plataforma.md)
