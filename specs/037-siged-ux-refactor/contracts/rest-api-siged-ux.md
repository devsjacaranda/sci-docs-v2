# REST API Contract — SIGED UX Refactor (037)

**Base path**: `/siged`  
**Auth**: JWT tenant + `@RequireModulo('gabinete')`  
**Validation**: Zod em `*.schemas.ts` + `ZodValidationPipe`

## Endpoints existentes (mantidos)

| Method | Path | Notas |
| --- | --- | --- |
| GET | `/siged/departamentos/hierarquia` | Árvore completa; client filtra topo/drill-down |
| GET | `/siged/protocolos` | Query: `orgaoAtualId`, paginação, filtros |
| GET | `/siged/protocolos/:protocoloId/tramitacoes` | |
| GET/PUT | `/siged/controle-interno` | Base — inalterado |
| POST | `/siged/export` | Excel |

**Side effect (novo)**: listagens de protocolos/tramitações disparam coleta assíncrona de snapshots (não altera response).

---

## Novos endpoints — Home

### `GET /siged/home`

**Licença**: Base (KPIs) + projeção condicional Jatobá/Cedro nos post-its  
**Response 200**:

```json
{
  "diretoriasTopLevelCount": 12,
  "protocolosMonitorados": 842,
  "lastCollectionAt": "2026-08-10T18:00:00.000Z",
  "sigedLiveAvailable": true,
  "postIts": [
    {
      "kind": "kpi",
      "title": "Diretorias de topo",
      "summary": "12 órgãos na hierarquia SIGED"
    },
    {
      "kind": "cedro",
      "title": "Gargalo em DEJUR",
      "summary": "Tempo médio de tramitação 4,2× acima da mediana",
      "impact": "Alto",
      "href": "/siged/insights",
      "insightId": "uuid"
    }
  ],
  "licenseAlerts": []
}
```

**Degradação**: `sigedLiveAvailable: false` — KPIs de live omitidos ou com flag; histórico local permanece.

---

## Novos endpoints — Fiscalização (`@RequireLicenca('jatoba')`)

Prefixo: `/siged/fiscalizacao`

| Method | Path | Body/Query | Response |
| --- | --- | --- | --- |
| GET | `/` | — | Painel (run latest + checksSummary + findings + historyRows) — shape compatível `FiscalizacaoPanel` |
| POST | `/run` | `{ "origin": "on_demand" }` | Run completo ou `{ status: "running", runId }` |
| GET | `/runs` | `page`, `limit` | Lista paginada |
| GET | `/findings/:findingId/trace` | — | Sheet payload — título UI: **Por que esta checagem deu este resultado** |
| GET | `/checks/:checkId/trace` | — | Idem |
| GET | `/questions` | — | Banco perguntas |
| POST | `/questions` | `{ text, answerType, ... }` | |
| GET | `/questionnaires` | filtros | |
| POST | `/questionnaires` | `{ sigedProtocoloId, sigedOrgaoId, ... }` | Somente interno |
| POST | `/questionnaires/:id/respostas` | respostas | |

**Panel response** (campos principais):

```json
{
  "run": { "id": "uuid", "status": "completed", "recordsAnalyzed": 120, "dataSourceSummary": { "live": 80, "historical": 40 } },
  "checksSummary": [{ "ruleId": "JAT-SIG-TRM-001", "label": "Prazo de tramitação", "count": 5, "worstStatus": "non_conforme" }],
  "findings": [{ "id": "uuid", "title": "...", "conformityStatus": "non_conforme", "protocol": "2026/12345", "sigedOrgaoId": 99 }],
  "historyRows": [],
  "emptyReason": null
}
```

---

## Novos endpoints — Insights (`@RequireLicenca('cedro')`)

Prefixo: `/siged/insights`

| Method | Path | Notas |
| --- | --- | --- |
| GET | `/` | Latest batch + insights + `emptyReason` |
| GET | `/batches` | Histórico |
| GET | `/batches/:batchId` | Detalhe lote |
| GET | `/:insightId/trace` | Sheet — **De onde veio este insight** |
| POST | `/generate` | `{ "origin": "on_demand" }` → `{ batch, insights, readOnly: true }` ou 429 throttle |

**Insight item**:

```json
{
  "id": "uuid",
  "slug": "siged_avg_tramitacao_days",
  "title": "DEJUR concentra maior tempo médio de tramitação",
  "summary": "...",
  "recommendation": "...",
  "impact": "Alto",
  "category": "siged_tramitacao",
  "readOnly": true
}
```

---

## Erros canônicos

| Status | Quando |
| --- | --- |
| 403 | Sem módulo gabinete ou licença |
| 404 | Run/insight/finding inexistente no tenant |
| 429 | Throttle insights/fiscalização |
| 503 | SIGED live indisponível — **somente** em endpoints que exigem live exclusivo; home/panel degradam |

Copy de erro em pt-BR, sem expor stack/credenciais SIGED.
