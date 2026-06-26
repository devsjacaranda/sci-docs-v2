# Contract: REST API — Compras Insights (Cedro)

**Feature**: 020-purchasing-insights  
**Version**: 1.0.0  
**Base URL**: `/` (Fastify)  
**Guards**: `@RequireModulo('compras')` + `@RequireLicenca('cedro')` em todas as rotas

Espelha [015 rest-api-gabinete-insights.md](../../arquivados/015-gabinete-cedro-insights-integrado/contracts/rest-api-gabinete-insights.md) — paths `/compras/insights/*`, com extensões PNCP simulado e export.

## Headers (autenticadas)

| Header | Obrigatório |
|--------|-------------|
| `Authorization: Bearer <jwt>` | Sim |
| `X-Tenant-ID` | Sim |

---

## GET `/compras/insights`

Insights da geração **mais recente** `completed`.

**Response 200**:

```json
{
  "batch": {
    "id": "uuid",
    "generatedAt": "2026-06-25T02:00:00.000Z",
    "origin": "scheduled",
    "originLabel": "Agendada",
    "insightCount": 5,
    "analysisWindowStart": "2026-03-27T00:00:00.000Z",
    "analysisWindowEnd": "2026-06-25T23:59:59.999Z",
    "isStale": false
  },
  "insights": [
    {
      "id": "uuid",
      "slug": "external_price_reference",
      "title": "Referência de preço simulada — equipamentos de informática",
      "summary": "Consulta simulada PNCP/COMPRASNET encontrou mediana de R$ 45.200,00 para objeto similar.",
      "recommendation": "Compare o valor estimado da demanda com a referência simulada antes de publicar o edital.",
      "impact": "high",
      "impactLabel": "Alto",
      "category": "external_benchmark",
      "categoryLabel": "Referência externa (simulada)",
      "sourceLabel": "PNCP/COMPRASNET — simulado"
    }
  ]
}
```

**Response 200 (sem geração)**:

```json
{
  "batch": null,
  "insights": [],
  "emptyReason": "never_generated"
}
```

`emptyReason`: `no_data` | `insufficient_volume` | `never_generated`

---

## GET `/compras/insights/batches`

Histórico paginado.

**Query**: `page` (default 1), `limit` (default 20, max 50)

**Response 200**:

```json
{
  "items": [
    {
      "id": "uuid",
      "generatedAt": "2026-06-25T10:30:00.000Z",
      "origin": "on_demand",
      "originLabel": "Sob demanda",
      "insightCount": 4,
      "status": "completed"
    }
  ],
  "page": 1,
  "limit": 20,
  "total": 3
}
```

---

## GET `/compras/insights/batches/:batchId`

Detalhe de lote + insights do batch.

**Response 200**: mesmo shape de `GET /compras/insights` com `batch` fixo.

**Response 404**: lote inexistente ou outro tenant.

---

## GET `/compras/insights/:insightId/trace`

Rastreio *De onde veio este insight?*

**Response 200 (insight interno)**:

```json
{
  "kind": "cedro-insight",
  "license": "cedro",
  "insightId": "uuid",
  "title": "Concentração de demandas no PCA 2026 — DEAE",
  "summary": "…",
  "impact": "Alto",
  "recommendation": "…",
  "generatedAt": "2026-06-25T02:00:00.000Z",
  "readOnly": true,
  "analysisWindow": {
    "start": "2026-03-27T00:00:00.000Z",
    "end": "2026-06-25T23:59:59.999Z"
  },
  "reasoningSteps": [
    "Agregou demandas de Compras na janela de 90 dias.",
    "PCA dominante: 2026 — DEAE (8 demandas em andamento, 62%)."
  ],
  "records": [
    {
      "module": "compras",
      "protocol": "DEM-2026-00008",
      "label": "Demanda em andamento",
      "demandaId": "uuid",
      "fields": [
        { "field": "status", "value": "Em andamento" },
        { "field": "PCA", "value": "2026 — DEAE" },
        { "field": "objeto", "value": "Aquisição de equipamentos…" }
      ]
    }
  ]
}
```

**Response 200 (insight com consulta externa simulada)** — inclui `externalQueries`:

```json
{
  "kind": "cedro-insight",
  "license": "cedro",
  "insightId": "uuid",
  "title": "Referência de preço simulada — equipamentos de informática",
  "summary": "…",
  "impact": "Alto",
  "recommendation": "…",
  "generatedAt": "2026-06-25T02:00:00.000Z",
  "readOnly": true,
  "analysisWindow": { "start": "…", "end": "…" },
  "reasoningSteps": [
    "Consultou simulador PNCP/COMPRASNET com objeto da demanda.",
    "Mediana simulada: R$ 45.200,00; 23 contratos similares (dados fictícios)."
  ],
  "records": [],
  "externalQueries": [
    {
      "source": "PNCP/COMPRASNET — simulado",
      "objectQuery": "Aquisição de equipamentos de informática",
      "medianReferencePrice": 45200,
      "priceRange": { "min": 38500, "max": 52800 },
      "similarContractsCount": 23,
      "similarSuppliers": [
        { "name": "Fornecedor Alpha Ltda. (simulado)", "contractCount": 5 }
      ],
      "disclaimer": "Dados simulados — MVP. Integração real com PNCP/COMPRASNET não está ativa."
    }
  ]
}
```

---

## POST `/compras/insights/generate`

Recálculo (*Consultar IA*).

**Body**:

```json
{
  "origin": "on_demand"
}
```

Valores: `on_demand` | `on_open`

**Response 200 (completed)**:

```json
{
  "batch": { "id": "uuid", "insightCount": 5, "origin": "on_demand" },
  "insights": [],
  "readOnly": true
}
```

**Response 429 (throttle)**:

```json
{
  "code": "INSIGHTS_THROTTLED",
  "message": "Recálculo disponível uma vez por hora. Tente novamente mais tarde.",
  "retryAfterSeconds": 2400
}
```

**Response 409 (geração em andamento)**:

```json
{
  "code": "INSIGHTS_GENERATION_IN_PROGRESS",
  "message": "Geração de insights já em andamento."
}
```

---

## GET `/compras/insights/export`

Exporta relatório HTML da geração mais recente (P2).

**Response 200**:

- `Content-Type: text/html; charset=utf-8`
- `Content-Disposition: attachment; filename="insights-compras-2026-06-25.html"`

Corpo: HTML print-friendly com insights, impactos, recomendações, data de geração, badge *Somente consultivo*, disclaimers PNCP quando aplicável.

**Response 404**: sem geração completed.

**Response 422**:

```json
{
  "code": "INSIGHTS_EXPORT_EMPTY",
  "message": "Gere insights antes de exportar o relatório."
}
```

---

## Regras de agregação (determinísticas)

| Slug | Fonte | Categoria |
|------|-------|-----------|
| `demand_volume_by_status` | status derivado | operational |
| `demand_concentration_by_pca` | volume por PCA | operational |
| `demand_artefact_backlog` | artefatos pendentes | operational |
| `demand_value_above_median` | estimatedValue | pricing |
| `demand_missing_price_survey` | ausência pesquisa | pricing |
| `external_price_reference` | simulador PNCP | external_benchmark |
| `external_value_divergence` | interno vs simulado | external_benchmark |
| `external_similar_suppliers` | simulador PNCP | external_benchmark |

Mínimo **5** demandas por dimensão agregada; simulador PNCP determinístico; sem LLM.

Job `@nestjs/schedule` diário + recálculo `on_demand` / `on_open`.

---

## Códigos de erro

| HTTP | code | Quando |
|------|------|--------|
| 403 | — | Sem módulo Compras ou licença Cedro |
| 404 | — | batch/insight inexistente |
| 409 | `INSIGHTS_GENERATION_IN_PROGRESS` | lote `running` |
| 422 | `INSIGHTS_EXPORT_EMPTY` | export sem geração |
| 429 | `INSIGHTS_THROTTLED` | 2º `on_demand` &lt; 1h |
