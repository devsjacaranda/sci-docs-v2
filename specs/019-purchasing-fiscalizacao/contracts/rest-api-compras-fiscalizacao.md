# Contract: REST API — Compras Fiscalização (Jatobá)

**Feature**: 019-purchasing-fiscalizacao  
**Version**: 1.0.0  
**Prefix**: `/compras/fiscalizacao`  
**Guards**: `@RequireModulo('compras')` + `@RequireLicenca('jatoba')`

Espelha [008 rest-api-ouvidoria-fiscalizacao.md](../arquivados/008-ouvidoria-jatoba-fiscalizacao/contracts/rest-api-ouvidoria-fiscalizacao.md) adaptado ao domínio Compras. **Sem** rotas de questionários.

## Headers

| Header | Obrigatório |
|--------|-------------|
| `Authorization: Bearer <jwt>` | Sim |
| `X-Tenant-ID` | Sim |

---

## GET `/compras/fiscalizacao`

Painel — execução mais recente concluída + stats + achados + histórico.

**Response 200**:

```json
{
  "run": {
    "id": "uuid",
    "startedAt": "2026-06-25T10:00:00Z",
    "status": "completed",
    "recordsAnalyzed": 18,
    "stats": {
      "conforme": 4,
      "nonConforme": 6,
      "partial": 5,
      "pending": 3
    }
  },
  "checksSummary": [
    {
      "label": "Completude DFD",
      "ruleDescription": "Campos obrigatórios do DFD preenchidos",
      "conformityStatus": "non_conforme",
      "conformityLabel": "Não conforme",
      "sampleCount": 3
    },
    {
      "label": "Consistência orçamentária",
      "ruleDescription": "Valor dotado inferior ao valor estimado da pesquisa de preços",
      "conformityStatus": "partial",
      "conformityLabel": "Parcial",
      "sampleCount": 2
    }
  ],
  "findings": [
    {
      "id": "uuid",
      "title": "DFD incompleto",
      "protocol": "DEM-12",
      "pcaTitle": "PCA 2026 — DEAE",
      "conformityStatus": "non_conforme",
      "conformityLabel": "Não conforme",
      "artefactKey": "dfd"
    }
  ],
  "historyRows": [
    {
      "runId": "uuid",
      "startedAt": "2026-06-25T10:00:00Z",
      "origin": "on_demand",
      "originLabel": "Sob demanda",
      "protocol": "DEM-12",
      "pcaTitle": "PCA 2026 — DEAE",
      "artefactsSummary": "3/7 preenchidos",
      "conformityStatus": "non_conforme",
      "conformityLabel": "Não conforme",
      "problemsSummary": "DFD incompleto"
    }
  ],
  "emptyReason": null,
  "readOnly": true
}
```

`emptyReason`: `"never_run"` | `"no_data"` | null

`no_data`: tenant sem demandas ativas.

---

## GET `/compras/fiscalizacao/runs`

Histórico paginado de execuções.

**Query**: `page` (default 1), `limit` (default 20, max 50)

**Response 200**: `{ "items": RunSummary[], "total": number, "page": number, "limit": number }`

---

## GET `/compras/fiscalizacao/runs/:runId`

Detalhe execução + resultados por demanda + checagens + achados (inclui `tracePayload`).

**Response 200**:

```json
{
  "run": { "id": "uuid", "startedAt": "...", "origin": "scheduled", "recordsAnalyzed": 18 },
  "results": [
    {
      "id": "uuid",
      "protocol": "DEM-12",
      "pcaTitle": "PCA 2026 — DEAE",
      "artefactsSummary": "3/7 preenchidos",
      "conformityStatus": "non_conforme",
      "conformityLabel": "Não conforme",
      "fiscalizedDataSummary": "7 artefatos documentais + consistência orçamentária",
      "problemsSummary": "DFD incompleto",
      "demandaUnavailable": false,
      "checks": [
        {
          "id": "uuid",
          "ruleId": "JAT-CMP-DFD",
          "label": "Completude DFD",
          "artefactKey": "dfd",
          "conformityStatus": "non_conforme",
          "conformityLabel": "Não conforme",
          "tracePayload": {}
        }
      ],
      "findings": [
        {
          "id": "uuid",
          "title": "DFD incompleto",
          "description": "Campos obrigatórios ausentes.",
          "conformityStatus": "non_conforme",
          "conformityLabel": "Não conforme",
          "tracePayload": {}
        }
      ]
    }
  ]
}
```

---

## POST `/compras/fiscalizacao/run`

Dispara execução completa (100% demandas ativas).

**Body**: `{ "origin": "on_demand" }` (optional, default `on_demand`)

**Response 202**: `{ "runId": "uuid", "status": "running" }`

**Response 409** (execução em andamento):

```json
{
  "statusCode": 409,
  "code": "FISCALIZACAO_RUNNING",
  "message": "Fiscalização já em andamento."
}
```

**Response 429** (throttle):

```json
{
  "statusCode": 429,
  "code": "FISCALIZACAO_THROTTLED",
  "message": "Fiscalização disponível uma vez por hora. Tente novamente mais tarde.",
  "retryAfterSeconds": 2400
}
```

---

## POST `/compras/fiscalizacao/run/demandas/:demandaId`

Execução scoped à demanda (origem `on_record`).

**Response 202**: `{ "runId": "uuid", "status": "running" }`

**Response 404**: demanda inexistente ou soft-deleted.

---

## GET `/compras/fiscalizacao/demandas/:demandaId`

Checagens da última execução para a demanda (card hub).

**Response 200**:

```json
{
  "demandaId": "uuid",
  "protocol": "DEM-12",
  "lastRunAt": "2026-06-25T10:00:00Z",
  "overallConformityStatus": "partial",
  "overallConformityLabel": "Parcial",
  "checks": [
    {
      "id": "uuid",
      "ruleId": "JAT-CMP-ETP",
      "label": "ETP dispensado",
      "conformityStatus": "conforme",
      "conformityLabel": "Conforme"
    }
  ],
  "findings": [],
  "readOnly": true
}
```

**Response 200** (sem execução prévia): `{ "demandaId": "uuid", "lastRunAt": null, "checks": [], "findings": [] }`

---

## GET `/compras/fiscalizacao/checks/:checkId/trace`

Rastreio checagem — payload para sheet.

**Response 200**: `{ "titleKey": "check", "trace": { ...tracePayload, reasoningSteps } }`

---

## GET `/compras/fiscalizacao/findings/:findingId/trace`

Rastreio achado.

**Response 200**: `{ "titleKey": "finding", "trace": { ... } }`

---

## GET `/compras/fiscalizacao/demandas/:demandaId/trace`

Rastreio consolidado demanda (todas checagens última execução).

**Response 200**: `{ "titleKey": "record", "trace": { checks[], findings[], demandaNumber } }`

---

## Erros comuns

| Status | Código | Quando |
|--------|--------|--------|
| 403 | — | Sem módulo Compras ou sem licença Jatobá |
| 404 | — | Demanda/run inexistente |
| 409 | `FISCALIZACAO_RUNNING` | Segunda execução paralela |
| 429 | `FISCALIZACAO_THROTTLED` | Manual/scoped < 1h desde última on_demand/on_record |

---

## Zod schemas (`compras-fiscalizacao.schemas.ts`)

- `ListFiscalizacaoRunsQuery` — page, limit
- `RunFiscalizacaoBody` — origin optional
- Response DTOs espelham shapes acima — validação em testes contrato

---

## Registro no AppModule

```typescript
import { ComprasFiscalizacaoModule } from './modules/compras-fiscalizacao/compras-fiscalizacao.module';
// imports[] após ComprasModule
```
