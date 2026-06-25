# Data Model: Insights Cedro — Ouvidoria

**Feature**: 007-ouvidoria-cedro-insights · **Date**: 2026-06-19

> Campos Prisma/API em **inglês**; labels UI em **PT-BR** via mapper. Fonte canônica de manifestações: [003-ouvidoria/data-model.md](../../003-ouvidoria/data-model.md).

## Entidades novas

### OuvidoriaInsightBatch (lote de geração)

| Field EN | UI PT-BR | Required | Notes |
|----------|----------|----------|-------|
| `id` | — | yes | UUID PK |
| `tenantId` | — | yes | multi-tenant |
| `generatedAt` | Data da geração | yes | DateTime |
| `origin` | Origem | yes | enum `InsightBatchOrigin` |
| `insightCount` | Quantidade | yes | Int ≥ 0 |
| `analysisWindowStart` | Início do período | yes | DateTime |
| `analysisWindowEnd` | Fim do período | yes | DateTime |
| `status` | Status | yes | enum `InsightBatchStatus` |
| `errorMessage` | — | no | se `status = failed` |
| `createdAt` | — | yes | |

**Índices**: `(tenantId, generatedAt DESC)`, `(tenantId, origin, generatedAt)`

### OuvidoriaInsight

| Field EN | UI PT-BR | Required | Notes |
|----------|----------|----------|-------|
| `id` | — | yes | UUID PK |
| `tenantId` | — | yes | |
| `batchId` | — | yes | FK → Batch |
| `slug` | — | yes | identificador estável para rastreio |
| `title` | Título | yes | |
| `summary` | Resumo | yes | Text |
| `recommendation` | Recomendação | yes | Text |
| `impact` | Impacto | yes | enum `InsightImpact` |
| `category` | Categoria | yes | enum `InsightCategory` |
| `sourceLabel` | Fonte | yes | default fixo API: `internal_ouvidoria` → UI *Dados internos — Ouvidoria* |
| `rulesApplied` | — | yes | JSON array string[] |
| `createdAt` | — | yes | |

**Índices**: `(batchId)`, `(tenantId, batchId)`

### OuvidoriaInsightEvidence

| Field EN | UI PT-BR | Required | Notes |
|----------|----------|----------|-------|
| `id` | — | yes | UUID PK |
| `tenantId` | — | yes | |
| `insightId` | — | yes | FK → Insight |
| `manifestacaoId` | — | no | FK opcional |
| `protocol` | Protocolo | yes | snapshot |
| `manifestacaoType` | Tipo | no | enum snapshot |
| `manifestacaoStatus` | Status | no | enum snapshot |
| `snapshotFields` | — | yes | JSON — campos agregados (datas, bairro, etc.) **sem PII** |
| `createdAt` | — | yes | |

**Índices**: `(insightId)`

---

## Enums

### InsightBatchOrigin

| Value EN | UI PT-BR |
|----------|----------|
| `scheduled` | Agendada |
| `on_demand` | Sob demanda |
| `on_open` | Ao abrir |

### InsightBatchStatus

| Value EN | UI PT-BR |
|----------|----------|
| `running` | Em processamento |
| `completed` | Concluída |
| `failed` | Falhou |

### InsightImpact

| Value EN | UI PT-BR |
|----------|----------|
| `critical` | Crítico |
| `high` | Alto |
| `medium` | Médio |

### InsightCategory

| Value EN | UI PT-BR |
|----------|----------|
| `operational` | Operacional |
| `geographic` | Geográfico |
| `text` | Padrões de texto |
| `profile` | Perfil da demanda |

---

## Entidades lidas (sem alteração)

### Manifestacao + ManifestacaoEvento

Usadas como **fonte de agregação** — não modificadas por Cedro.

| Uso | Campos / relações |
|-----|-------------------|
| Filtro base | `status != draft`, `deletedAt null`, janela 90d em `createdAt` |
| Operacional | `type`, `status`, `priority`, `category`, `subject`, `serviceMode` |
| Timeline | `eventos.tipo`, `eventos.createdAt`, `eventos.destinoSetorId` |
| Perfil | `isAnonymous`, `type`, `priority` |
| Texto | `subject`, `description` |
| Sigilo | **Nunca** ler `requester*` para evidências |

### Address + Municipio

| Uso | Campos |
|-----|--------|
| Geográfico | `municipioIbge`, `neighborhood`, `zone`; `municipio.nome`, `municipio.uf` |

---

## Rastreio (payload API → sheet UI)

Não persistido como entidade separada — composto na resposta:

```typescript
interface InsightTracePayload {
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
    module: 'ouvidoria';
    protocol: string;
    label: string;
    fields: Array<{ field: string; value: string }>;
  }>;
  // SEM externalQueries
}
```

---

## State transitions

### Batch

```text
(running) --success--> (completed)
(running) --error--> (failed)
```

Apenas um `running` por tenant — segunda geração retorna conflito ou aguarda (edge case spec).

### Insight

Imutável após criação no lote — read-only Cedro.

---

## Fixtures de teste (sem DB)

Arquivos JSON em `ci-api-v2/src/modules/ouvidoria-insights/test/fixtures/` e `ci-client-v2/.../fixtures/`:

- `manifestacoes-sample.json` — 15–30 manifestações com eventos e endereços variados
- `insight-batch-completed.json` — lote + insights + evidências
- `insight-list-empty.json` — estado vazio

Usados em unit, contract, integration e E2E mockados.
