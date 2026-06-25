# Contract: Client UI — Gabinete Insights Cedro

**Feature**: 015-gabinete-cedro-insights-integrado  
**Route**: `/gabinete/insights`  
**Screen ID**: `gabinete-insights`  
**Licença**: Cedro — badge **Somente leitura**

Espelha [007 client-ouvidoria-insights-ui.md](../../007-ouvidoria-cedro-insights/contracts/client-ouvidoria-insights-ui.md).

## Navegação

| Origem | Destino | Cliques (SC-001) |
|--------|---------|------------------|
| `/gabinete` overview | Card *Insights & IA* | 1 |
| Shell nav | *Insights IA* / *Insights Cedro* | 1–2 |

Rota lazy já registrada — **substituir** implementação simplificada atual.

---

## Layout da página

### Header

| Elemento | Conteúdo |
|----------|----------|
| Título | Insights Cedro — Gabinete *(cedroFocus gabinete)* |
| Subtítulo | Licença Cedro: insights estratégicos consultivos (read-only) — análise integrada de atos, protocolos e controles do Gabinete. |
| Badge | **Somente leitura** |

### Stats row

| Label | Fonte |
|-------|-------|
| Insights ativos | `insights.length` |
| Última geração | `batch.generatedAt` formatado |
| Impacto alto | count `impact === high \| critical` |
| Natureza | Read-only / Cedro |

### Seção principal — `InsightsPanel` (shared)

Componente `InsightCard` por item:

| Campo UI | API field |
|----------|-----------|
| Título | `title` |
| Impacto chip | `impactLabel` |
| Categoria | `categoryLabel` |
| Fonte | `sourceLabel` — *Dados internos — Gabinete* |
| Resumo | `summary` |
| Recomendação | `recommendation` |
| Ação | *De onde veio este insight?* |

### Ação primária

| Label | Comportamento |
|-------|---------------|
| **Consultar IA** | `POST /gabinete/insights/generate` body `{ origin: 'on_demand' }`; dialog confirmação; toast sucesso ou 429 |

Copy: *Análise consultiva de dados internos — nenhum registro será alterado.*

**NUNCA** label *Gerar insights* — usar *Consultar IA* (regras-plataforma).

### Histórico — `InsightsHistoryPanel` (shared)

`GET /gabinete/insights/batches`; seleção carrega `GET /batches/:id`. Mínimo 2 gerações anteriores visíveis (SC-004).

### Estado vazio

| `emptyReason` | Mensagem |
|---------------|----------|
| `no_data` | Cadastre atos e controles para habilitar insights. |
| `insufficient_volume` | Dados insuficientes no período — continue operando o Gabinete. |
| `never_generated` | Acione *Consultar IA* para a primeira análise. |

CTA: **Consultar IA** quando aplicável.

### Banner stale

Se `batch.isStale === true` (&gt; 7 dias): aviso *Geração desatualizada* + CTA Consultar IA.

---

## Sheet de rastreio — `InsightTraceSheet` (shared)

- Abertura: ~85% viewport (R-40)
- Título: **De onde veio este insight**
- Fetch: `GET /gabinete/insights/:id/trace`
- Link ato: `/gabinete/atos/:demandaId` quando presente
- **Sem** seção consultas externas

---

## API client (`modules/gabinete/api/insights.ts`)

Funções espelhando ouvidoria:

| Função | Endpoint |
|--------|----------|
| `fetchGabineteInsights()` | GET `/gabinete/insights` |
| `fetchGabineteInsightBatches(page, limit)` | GET `/gabinete/insights/batches` |
| `fetchGabineteInsightBatchDetail(id)` | GET `/gabinete/insights/batches/:id` |
| `fetchGabineteInsightTrace(id)` | GET `/gabinete/insights/:id/trace` |
| `generateGabineteInsights(origin?)` | POST `/gabinete/insights/generate` |

Tipos + mappers em `insights-mappers.ts`; erro `InsightsApiError` com `code` throttle.

---

## Componentes shared (`modules/shared/components/cedro/`)

Extraídos de ouvidoria e parametrizados:

| Prop | Gabinete | Ouvidoria |
|------|----------|-----------|
| `moduleId` | `gabinete` | `ouvidoria` |
| `sourceLabel` | Dados internos — Gabinete | Dados internos — Ouvidoria |
| `detailPathPrefix` | `/gabinete/atos` | `/ouvidoria/manifestacoes` |
| `fetchTrace` | gabinete API | ouvidoria API |

Refatorar `OuvidoriaInsightsPage` para consumir shared (regressão coberta por testes existentes).

---

## Acessibilidade e copy

- Vocabulário UI: **ato/atos** (nunca *demanda* na interface)
- Badge **Somente leitura** — nunca *Read-only*
- Impacto: **Crítico** / **Alto** / **Médio**
- Paleta Mint (`mint-palette.mdc`)

---

## MSW handlers (testes)

Registrar handlers em `modules/gabinete/__tests__/msw/gabinete-insights.handlers.ts` espelhando fixtures JSON.
