# Contract: REST API — Ouvidoria Insights (Cedro)

**Feature**: 007-ouvidoria-cedro-insights  
**Version**: 1.0.0  
**Base URL**: `/` (Fastify)  
**Guards**: `@RequireModulo('ouvidoria')` + `@RequireLicenca('cedro')` em todas as rotas abaixo

## Headers (autenticadas)

| Header | Obrigatório |
|--------|-------------|
| `Authorization: Bearer <jwt>` | Sim |
| `X-Tenant-ID` | Sim |

---

## GET `/ouvidoria/insights`

Retorna insights da **geração mais recente** `completed` do tenant.

**Response 200**:

```json
{
  "batch": {
    "id": "uuid",
    "generatedAt": "2026-06-19T02:00:00.000Z",
    "origin": "scheduled",
    "originLabel": "Agendada",
    "insightCount": 4,
    "analysisWindowStart": "2026-03-21T00:00:00.000Z",
    "analysisWindowEnd": "2026-06-19T23:59:59.999Z",
    "isStale": false
  },
  "insights": [
    {
      "id": "uuid",
      "slug": "operational-backlog-aging",
      "title": "Backlog elevado em manifestações abertas",
      "summary": "32% das manifestações do período permanecem sem encerramento há mais de 30 dias.",
      "recommendation": "Priorizar fila de manifestações em tramitação prolongada.",
      "impact": "high",
      "impactLabel": "Alto",
      "category": "operational",
      "categoryLabel": "Operacional",
      "sourceLabel": "Dados internos — Ouvidoria"
    }
  ]
}
```

**Response 200 (sem geração)**:

```json
{
  "batch": null,
  "insights": [],
  "emptyReason": "no_data"
}
```

`emptyReason`: `no_data` | `insufficient_volume` | `never_generated`

---

## GET `/ouvidoria/insights/batches`

Histórico de lotes (paginado).

**Query**: `page` (default 1), `limit` (default 20, max 50)

**Response 200**:

```json
{
  "items": [
    {
      "id": "uuid",
      "generatedAt": "2026-06-19T02:00:00.000Z",
      "origin": "on_demand",
      "originLabel": "Sob demanda",
      "insightCount": 5,
      "status": "completed"
    }
  ],
  "total": 3,
  "page": 1,
  "limit": 20
}
```

---

## GET `/ouvidoria/insights/batches/:batchId`

Detalhe de um lote com todos os insights (comparação histórica).

**Response 200**: mesmo shape de `insights[]` + `batch` completo.

**Response 404**: `INSIGHT_BATCH_NOT_FOUND`

---

## GET `/ouvidoria/insights/:insightId/trace`

Payload de rastreio para sheet inferior.

**Response 200**:

```json
{
  "kind": "cedro-insight",
  "license": "cedro",
  "insightId": "uuid",
  "title": "Backlog elevado em manifestações abertas",
  "summary": "...",
  "impact": "Alto",
  "recommendation": "...",
  "generatedAt": "2026-06-19T02:00:00.000Z",
  "readOnly": true,
  "analysisWindow": {
    "start": "2026-03-21T00:00:00.000Z",
    "end": "2026-06-19T23:59:59.999Z"
  },
  "reasoningSteps": [
    "Filtrou manifestações confirmadas nos últimos 90 dias.",
    "Calculou proporção com status diferente de encerrado há mais de 30 dias.",
    "Comparou com volume total do período."
  ],
  "records": [
    {
      "module": "ouvidoria",
      "protocol": "OUV-2026-0138",
      "label": "Denúncia em tramitação",
      "fields": [
        { "field": "tipo", "value": "Denúncia" },
        { "field": "status", "value": "Tramitando" },
        { "field": "dias_abertos", "value": "45" }
      ]
    }
  ]
}
```

**Proibido**: campo `externalQueries` — contrato MUST NOT incluir consultas externas.

**Response 404**: `INSIGHT_NOT_FOUND`

---

## POST `/ouvidoria/insights/generate`

Recálculo sob demanda (*Consultar IA*).

**Body** (opcional):

```json
{
  "origin": "on_demand"
}
```

**Response 202**:

```json
{
  "batchId": "uuid",
  "status": "running",
  "message": "Geração iniciada."
}
```

**Response 200** (se geração síncrona &lt; 30s — implementação pode escolher sync ou async):

```json
{
  "batch": { "...": "completed batch" },
  "insights": [ "..."]
}
```

**Response 429**:

```json
{
  "statusCode": 429,
  "code": "INSIGHTS_THROTTLED",
  "message": "Recálculo disponível uma vez por hora. Tente novamente mais tarde.",
  "retryAfterSeconds": 1800
}
```

**Response 409**: `INSIGHTS_GENERATION_IN_PROGRESS` — job já em execução para o tenant.

---

## Erros comuns

| Code | HTTP | Quando |
|------|------|--------|
| `MODULO_SETOR_DENIED` | 403 | Sem permissão ouvidoria |
| `LICENCA_DENIED` | 403 | Cedro (guard global) |
| `INSIGHTS_THROTTLED` | 429 | Throttle 1h |
| `INSIGHTS_GENERATION_IN_PROGRESS` | 409 | Geração concorrente |
| `INSIGHT_NOT_FOUND` | 404 | Insight inválido |
| `INSIGHT_BATCH_NOT_FOUND` | 404 | Lote inválido |

---

## IDs de contrato (testes)

| ID | Endpoint | Caso |
|----|----------|------|
| CT-INS-001 | GET list | 200 com batch + insights |
| CT-INS-002 | GET list | 200 empty `no_data` |
| CT-INS-003 | GET batches | paginação |
| CT-INS-004 | GET trace | payload sem `externalQueries` |
| CT-INS-005 | POST generate | 202/200 sucesso |
| CT-INS-006 | POST generate | 429 throttle |
| CT-INS-007 | GET * | 403 sem módulo |
| CT-INS-008 | trace records | sem campos PII |
