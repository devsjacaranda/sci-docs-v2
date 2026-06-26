# Data Model: Insights IA Cedro — Purchasing

**Feature**: 020-purchasing-insights · **Date**: 2026-06-25

> **Novas entidades Prisma** para Compras Cedro. Fonte operacional: [018 Purchasing CRUD](../arquivados/018-purchasing-crud/spec.md). Padrão batch/insight/evidence espelha Gabinete/Ouvidoria.

## Entidades persistidas (novas)

### CompraInsightBatch

| Campo | Tipo | Notas |
|-------|------|-------|
| `id` | UUID | PK |
| `tenantId` | String | FK Tenant |
| `generatedAt` | DateTime | instante da geração |
| `origin` | `InsightBatchOrigin` | scheduled \| on_demand \| on_open |
| `insightCount` | Int | default 0 |
| `analysisWindowStart` | DateTime | início janela 90d |
| `analysisWindowEnd` | DateTime | fim janela |
| `status` | `InsightBatchStatus` | running \| completed \| failed |
| `errorMessage` | String? | se failed |
| `createdAt` | DateTime | |

Índices: `(tenantId, generatedAt DESC)`, `(tenantId, origin, generatedAt)`.

### CompraInsight

| Campo | Tipo | Notas |
|-------|------|-------|
| `id` | UUID | PK |
| `tenantId` | String | |
| `batchId` | String | FK batch |
| `slug` | String | identificador estável da regra |
| `title` | String | |
| `summary` | Text | |
| `recommendation` | Text | imperativo consultivo |
| `impact` | `InsightImpact` | critical \| high \| medium |
| `category` | `InsightCategory` | operational \| pricing \| external_benchmark |
| `sourceLabel` | String | default `internal_compras`; externo: `external_pncp_simulated` |
| `rulesApplied` | Json | metadados da regra + snapshot simulação quando aplicável |
| `createdAt` | DateTime | |

Índices: `(batchId)`, `(tenantId, batchId)`.

### CompraInsightEvidence

| Campo | Tipo | Notas |
|-------|------|-------|
| `id` | UUID | PK |
| `tenantId` | String | |
| `insightId` | String | FK insight |
| `demandaId` | String? | FK lógica CompraDemanda |
| `protocol` | String | ex.: `DEM-2026-00012` (número formatado) |
| `demandaStatus` | String? | status derivado PT ou enum serializado |
| `snapshotFields` | Json | campos agregados (PCA, objeto, valor, artefatos pendentes) |
| `createdAt` | DateTime | |

Índices: `(insightId)`.

**Sigilo**: **NUNCA** persistir dados pessoais reais de fornecedores — apenas nomes fictícios do simulador.

---

## Migration: extensão `InsightCategory`

Valores **adicionados** (additive migration):

| Value EN | UI PT-BR | Módulo |
|----------|----------|--------|
| `pricing` | Valores e preços | Compras |
| `external_benchmark` | Referência externa (simulada) | Compras |

Valores existentes inalterados. Atualizar `CATEGORY_LABEL` em `compras-insights.types.ts`.

---

## Enums compartilhados (sem alteração de valores)

### InsightBatchOrigin

| Value EN | UI PT-BR |
|----------|----------|
| `scheduled` | Agendada |
| `on_demand` | Sob demanda |
| `on_open` | Ao abrir |

### InsightImpact

| Value EN | UI PT-BR |
|----------|----------|
| `critical` | Crítico |
| `high` | Alto |
| `medium` | Médio |

---

## Entidades lidas (fontes de agregação — spec 018)

### CompraDemanda + relações

| Uso | Campos / relações |
|-----|-------------------|
| Identificação | `number`, `title`, **`object`**, `pcaId`, `sectorId` |
| Filtro | `deletedAt null`, `createdAt` na janela 90d |
| Status | **derivado** via artefatos — `draft` \| `in_progress` \| `completed` |
| Progresso | `countSatisfiedArtefacts` / 7 — funções em `compras.mapper.ts` |
| PCA | `pca.title`, `pca.status` |

### CompraPesquisaPrecos

| Uso | Campos |
|-----|--------|
| Valor | **`estimatedValue`** (Decimal) |
| Fonte | `surveySource` |
| Satisfação | `estimatedValue > 0` + `surveySource` não vazio |

### Artefatos (checklist backlog)

| Artefato | Satisfação (018) |
|----------|------------------|
| DFD | campos obrigatórios preenchidos |
| ETP | preenchido **ou** `waived` + `waiverReason` |
| Análise Riscos | lista `risks` não vazia |
| TR, Dotação, Parecer | campos obrigatórios |
| Pesquisa Preços | ver acima |

---

## Slugs estáveis (identificadores de regra)

| Slug | Categoria | Fonte | sourceLabel |
|------|-----------|-------|-------------|
| `demand_volume_by_status` | operational | status derivado | Dados internos — Compras |
| `demand_concentration_by_pca` | operational | volume por PCA | Dados internos — Compras |
| `demand_artefact_backlog` | operational | artefatos pendentes | Dados internos — Compras |
| `demand_value_above_median` | pricing | estimatedValue vs mediana tenant | Dados internos — Compras |
| `demand_missing_price_survey` | pricing | demandas sem pesquisa | Dados internos — Compras |
| `external_price_reference` | external_benchmark | simulador PNCP por objeto | PNCP/COMPRASNET — simulado |
| `external_value_divergence` | external_benchmark | valor interno vs referência simulada | Híbrido — interno + simulado |
| `external_similar_suppliers` | external_benchmark | fornecedores simulados | PNCP/COMPRASNET — simulado |

Mínimo **5** demandas por dimensão agregada; regras externas por objeto exigem objeto ≥ 10 caracteres.

---

## Simulador PNCP (não persistido como entidade)

Resultado computado em runtime, snapshot parcial em `rulesApplied` + `externalQueries` no trace:

```typescript
interface PncpSimulatedResult {
  objectQuery: string;
  medianReferencePrice: number;
  priceRangeMin: number;
  priceRangeMax: number;
  similarContractsCount: number;
  similarSuppliers: Array<{ name: string; contractCount: number }>;
  confidence: 'high' | 'low';
  simulated: true;
}
```

---

## Rastreio (payload API → sheet UI)

```typescript
interface ComprasInsightTracePayload {
  kind: 'cedro-insight';
  license: 'cedro';
  insightId: string;
  title: string;
  summary: string;
  impact: 'Crítico' | 'Alto' | 'Médio';
  recommendation: string;
  generatedAt: string;
  readOnly: true;
  analysisWindow: { start: string; end: string };
  reasoningSteps: string[];
  records: Array<{
    module: 'compras';
    protocol: string;       // DEM-2026-NNNNN
    label: string;
    demandaId?: string;
    fields: Array<{ field: string; value: string }>;
  }>;
  externalQueries?: Array<{
    source: 'PNCP/COMPRASNET — simulado';
    objectQuery: string;
    medianReferencePrice: number;
    priceRange: { min: number; max: number };
    similarContractsCount: number;
    similarSuppliers: Array<{ name: string; contractCount: number }>;
    disclaimer: string;
  }>;
}
```

Link detalhe demanda: `/compras/:demandaId` quando `demandaId` presente. Demanda excluída → registro indica *Indisponível* — insight permanece consultável.

---

## State transitions

### Batch

```text
(running) --success--> (completed)
(running) --error--> (failed)
```

Apenas um `running` por tenant.

### Insight

Imutável após criação — read-only Cedro.

---

## Fixtures de teste (sem DB)

`ci-api-v2/src/modules/compras-insights/test/fixtures/`:

| Arquivo | Conteúdo |
|---------|----------|
| `compras-analysis-sample.json` | demandas multi-status + PCAs + valores + objetos |
| `pncp-simulator-cases.json` | objeto curto/longo/com valor/sem valor |
| `insight-batch-completed.json` | lote multi-categoria + externalQueries |
| `insight-list-empty.json` | emptyReason variants |

Client: espelhar em `modules/compras/fixtures/insights-*.json`.
