# Contract: REST API — Tramitação Insights (Cedro)

**Feature**: 014-desmock-tramitacao  
**Version**: 1.0.0  
**Guards**: `@RequireModulo('tramitacao')` + `@RequireLicenca('cedro')`

Espelho [007 ouvidoria insights](../../007-ouvidoria-cedro-insights/contracts/rest-api-ouvidoria-insights.md) — read-only, agregações determinísticas.

## Headers

| Header | Obrigatório |
|--------|-------------|
| `Authorization: Bearer <jwt>` | Sim |
| `X-Tenant-ID` | Sim |

---

## GET `/tramitacao/insights`

Último batch de insights + evidências.

**Query**: `periodDays` (optional, default 90)

**Response 200**:

```json
{
  "batch": {
    "id": "uuid",
    "generatedAt": "2026-06-24T03:00:00.000Z",
    "periodStart": "2026-03-24T00:00:00.000Z",
    "periodEnd": "2026-06-24T23:59:59.999Z",
    "status": "completed"
  },
  "insights": [
    {
      "id": "uuid",
      "category": "bottleneck_sectors",
      "title": "Gargalos entre setores",
      "summary": "Jurídico com tempo médio de resposta 4,2 dias",
      "severity": "high",
      "trend": "increasing",
      "evidenceCount": 12
    },
    {
      "id": "uuid",
      "category": "volume_by_module",
      "title": "Volume por módulo de origem",
      "summary": "Ouvidoria representa 38% das demandas",
      "severity": "medium",
      "trend": "stable",
      "evidenceCount": 58
    },
    {
      "id": "uuid",
      "category": "temporal_trend",
      "title": "Tendência de resolutividade",
      "summary": "Taxa subiu de 65% a 72% no período",
      "severity": "low",
      "trend": "decreasing",
      "evidenceCount": 90
    }
  ],
  "aggregations": {
    "bottleneckSectors": [
      { "sectorId": "uuid", "sigla": "DEJUR", "avgResponseDays": 4.2, "count": 18 }
    ],
    "volumeByModule": [
      { "module": "ouvidoria", "count": 22, "trend": "stable" }
    ],
    "volumeSeries": [
      { "date": "2026-06-01", "total": 5, "answered": 3 }
    ]
  }
}
```

---

## GET `/tramitacao/insights/batches`

Histórico de batches (paginado).

---

## POST `/tramitacao/insights/runs`

Dispara geração manual (read-only sobre demandas — não altera registros).

**Response 202**: `{ "batchId", "status": "running" }`

---

## GET `/tramitacao/insights/:insightId/evidence`

Evidências de um insight (demandas/protocolos referenciados).

**Response 200**:

```json
{
  "items": [
    {
      "demandaId": "uuid",
      "protocolNumber": "TRAM-2026-0008",
      "metric": "responseDays",
      "value": 7,
      "sectorSigla": "DEJUR"
    }
  ]
}
```

---

## Regras de agregação (referência)

| category | Cálculo |
|----------|---------|
| `bottleneck_sectors` | média dias entre `created`/`forwarded` e primeira `reply` por `currentSectorId` |
| `volume_by_module` | count por `sourceModule` (null → `generic`); tendência vs período anterior |
| `temporal_trend` | série diária volume + taxa answered/total |

Determinístico — mesma entrada produz mesma saída (SC-007).
