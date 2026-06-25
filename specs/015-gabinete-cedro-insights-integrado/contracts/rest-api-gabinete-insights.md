# Contract: REST API — Gabinete Insights (Cedro)

**Feature**: 015-gabinete-cedro-insights-integrado  
**Version**: 1.0.0  
**Base URL**: `/` (Fastify)  
**Guards**: `@RequireModulo('gabinete')` + `@RequireLicenca('cedro')` em todas as rotas

Espelha [007 rest-api-ouvidoria-insights.md](../../007-ouvidoria-cedro-insights/contracts/rest-api-ouvidoria-insights.md) — paths `/gabinete/insights/*`.

## Headers (autenticadas)

| Header | Obrigatório |
|--------|-------------|
| `Authorization: Bearer <jwt>` | Sim |
| `X-Tenant-ID` | Sim |

---

## GET `/gabinete/insights`

Insights da geração **mais recente** `completed`.

**Response 200**:

```json
{
  "batch": {
    "id": "uuid",
    "generatedAt": "2026-06-24T02:00:00.000Z",
    "origin": "scheduled",
    "originLabel": "Agendada",
    "insightCount": 6,
    "analysisWindowStart": "2026-03-26T00:00:00.000Z",
    "analysisWindowEnd": "2026-06-24T23:59:59.999Z",
    "isStale": false
  },
  "insights": [
    {
      "id": "uuid",
      "slug": "tramitados_by_sector",
      "title": "Concentração de documentos tramitados no Jurídico",
      "summary": "42% dos documentos tramitados no período foram direcionados ao setor Jurídico.",
      "recommendation": "Revise capacidade e filas do setor com maior volume tramitado.",
      "impact": "high",
      "impactLabel": "Alto",
      "category": "tramitacao",
      "categoryLabel": "Documentos tramitados",
      "sourceLabel": "Dados internos — Gabinete"
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

## GET `/gabinete/insights/batches`

Histórico paginado.

**Query**: `page` (default 1), `limit` (default 20, max 50)

**Response 200**:

```json
{
  "items": [
    {
      "id": "uuid",
      "generatedAt": "2026-06-24T02:00:00.000Z",
      "origin": "on_demand",
      "originLabel": "Sob demanda",
      "insightCount": 5,
      "status": "completed"
    }
  ],
  "page": 1,
  "limit": 20,
  "total": 3
}
```

---

## GET `/gabinete/insights/batches/:batchId`

Detalhe de lote + insights do batch.

**Response 200**: mesmo shape de `GET /gabinete/insights` com `batch` fixo.

**Response 404**: lote inexistente ou outro tenant.

---

## GET `/gabinete/insights/:insightId/trace`

Rastreio *De onde veio este insight?*

**Response 200**:

```json
{
  "kind": "cedro-insight",
  "license": "cedro",
  "insightId": "uuid",
  "title": "Concentração em status «Em trâmite»",
  "summary": "…",
  "impact": "Alto",
  "recommendation": "…",
  "generatedAt": "2026-06-24T02:00:00.000Z",
  "readOnly": true,
  "analysisWindow": {
    "start": "2026-03-26T00:00:00.000Z",
    "end": "2026-06-24T23:59:59.999Z"
  },
  "reasoningSteps": [
    "Agregou atos do Gabinete na janela de 90 dias.",
    "Status dominante: in_transit (12 registros, 38%)."
  ],
  "records": [
    {
      "module": "gabinete",
      "protocol": "GAB-2026-00042",
      "label": "Ato em trâmite",
      "demandaId": "uuid",
      "entityType": "ato",
      "fields": [
        { "field": "status", "value": "Em trâmite" },
        { "field": "origem", "value": "Gabinete" }
      ]
    }
  ]
}
```

**SEM** `externalQueries`.

---

## POST `/gabinete/insights/generate`

Recálculo sob demanda (*Consultar IA*).

**Body**:

```json
{
  "origin": "on_demand"
}
```

Valores: `on_demand` | `on_open` (default implícito: `on_demand`)

**Response 200 (completed)**:

```json
{
  "batch": { "id": "uuid", "insightCount": 6, "origin": "on_demand" },
  "insights": [ "…InsightListItem[]" ],
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

## Regras de agregação (determinísticas)

| Slug | Fonte | Categoria |
|------|-------|-----------|
| `volume_by_status` | `CabinetDemanda.status` | operational |
| `origin_mix` | `CabinetDemanda.origin` | operational |
| `backlog_aging` | atos abertos &gt; 30d | operational |
| `forwarding_bottleneck` | `forwardings` + setor destino | operational |
| `timeline_durations` | `CabinetDemandaEvento` | operational |
| `protocol_entry_mode` | `CabinetProtocolo.entryMode` | protocol |
| `protocol_document_type` | `CabinetProtocolo.documentType` | protocol |
| `protocol_orphan` | protocolos sem ato | protocol |
| `control_numeric_by_type` | `CabinetControleNumerico.documentType` | control_numeric |
| `notifications_trend` | `CabinetControleNotificacao` | enforcement |
| `autos_trend` | `CabinetControleAutoInfracao` | enforcement |
| `notification_auto_ratio` | `groupId` | enforcement |
| `tramitados_by_sector` | `CabinetDocumentoTramitado.sectorId` | tramitacao |

Mínimo **5** registros por dimensão analisada; sem LLM/NLP.

Job `@nestjs/schedule` diário + recálculo `on_demand` / `on_open`.

---

## Códigos de erro

| HTTP | code | Quando |
|------|------|--------|
| 403 | — | Sem módulo Gabinete ou licença Cedro |
| 404 | — | batch/insight inexistente |
| 409 | `INSIGHTS_GENERATION_IN_PROGRESS` | lote `running` |
| 429 | `INSIGHTS_THROTTLED` | 2º `on_demand` &lt; 1h |
