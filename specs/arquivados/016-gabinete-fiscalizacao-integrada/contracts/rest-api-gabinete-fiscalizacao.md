# Contract: REST API — Gabinete Fiscalização (Jatobá) — Integrada

**Feature**: 016-gabinete-fiscalizacao-integrada  
**Version**: 2.0.0 (substitui/estende [012 rest-api-gabinete-fiscalizacao.md](../012-desmock-gabinete/contracts/rest-api-gabinete-fiscalizacao.md))  
**Prefix**: `/gabinete/fiscalizacao`  
**Guards**: `@RequireModulo('gabinete')` + `@RequireLicenca('jatoba')`

Espelha [008 rest-api-ouvidoria-fiscalizacao.md](../008-ouvidoria-jatoba-fiscalizacao/contracts/rest-api-ouvidoria-fiscalizacao.md) adaptado ao domínio Gabinete + cadastros órfãos. **Sem** rotas públicas.

## Headers

| Header | Obrigatório |
|--------|-------------|
| `Authorization: Bearer <jwt>` | Sim |
| `X-Tenant-ID` | Sim |

---

## GET `/gabinete/fiscalizacao`

Painel — execução mais recente + stats + achados + histórico (runs + questionários).

**Response 200**:

```json
{
  "run": {
    "id": "uuid",
    "startedAt": "2026-06-24T10:00:00Z",
    "status": "completed",
    "recordsAnalyzed": 42,
    "stats": {
      "conforme": 28,
      "nonConforme": 6,
      "partial": 5,
      "pending": 3
    }
  },
  "checksSummary": [
    {
      "label": "Prazo concessionária",
      "ruleDescription": "Prazo vencido sem resposta registrada",
      "conformityStatus": "non_conforme",
      "conformityLabel": "Não conforme",
      "sampleCount": 2
    },
    {
      "label": "Pareamento notificação/auto",
      "ruleDescription": "Notificação sem auto pareado no mesmo grupo",
      "conformityStatus": "partial",
      "conformityLabel": "Parcial",
      "sampleCount": 1
    }
  ],
  "findings": [
    {
      "id": "uuid",
      "title": "Prazo concessionária excedido",
      "protocol": "GAB-2026-0012",
      "entityType": "cabinet_demanda",
      "entityTypeLabel": "Ato",
      "conformityStatus": "non_conforme",
      "conformityLabel": "Não conforme",
      "flowStateLabel": "Em análise"
    },
    {
      "id": "uuid",
      "title": "Notificação sem auto pareado",
      "protocol": "Cadastro órfão — Notificação",
      "entityType": "notificacao",
      "entityTypeLabel": "Notificação",
      "conformityStatus": "partial",
      "conformityLabel": "Parcial"
    }
  ],
  "historyRows": [
    {
      "runId": "uuid",
      "startedAt": "2026-06-24T10:00:00Z",
      "origin": "on_demand",
      "originLabel": "Sob demanda",
      "protocol": "GAB-2026-0012",
      "entityType": "cabinet_demanda",
      "entityTypeLabel": "Ato",
      "fiscalizedDataSummary": "Prazo, tramitação, protocolo e controles",
      "questionnaireTitle": "—",
      "recipientLabel": "—",
      "channelLabel": "—",
      "conformityStatus": "non_conforme",
      "conformityLabel": "Não conforme",
      "problemsSummary": "Prazo concessionária excedido"
    }
  ],
  "emptyReason": null,
  "readOnly": true
}
```

`emptyReason`: `"never_run"` | `"no_data"` | null

---

## GET `/gabinete/fiscalizacao/runs`

Histórico paginado de execuções.

**Query**: `page` (default 1), `limit` (default 20, max 50)

**Response 200**: `{ "items": RunSummary[], "total": number, "page": number, "limit": number }`

---

## GET `/gabinete/fiscalizacao/runs/:runId`

Detalhe execução + resultados + checagens + achados (inclui `tracePayload` em GET detail).

---

## POST `/gabinete/fiscalizacao/run`

Dispara execução completa (atos + cadastros órfãos).

**Body**: `{ "origin": "on_demand" }` (optional, default `on_demand`)

**Response 202**: `{ "runId": "uuid", "status": "running" }`

**Response 429** (throttle):

```json
{
  "statusCode": 429,
  "code": "FISCALIZACAO_THROTTLED",
  "message": "Aguarde antes de executar nova fiscalização completa."
}
```

---

## POST `/gabinete/fiscalizacao/run/atos/:cabinetId`

Execução scoped ao ato (origem `on_record`). Alias legado: `run/demandas/:demandaId`.

**Response 202**: `{ "runId": "uuid", "status": "running" }`

---

## GET `/gabinete/fiscalizacao/atos/:cabinetId`

Checagens da última execução para o ato (card detalhe). Inclui checagens agregadas de protocolo/controles vinculados.

**Response 200**:

```json
{
  "cabinetId": "uuid",
  "protocolNumber": "GAB-2026-0012",
  "overallConformity": "partial",
  "overallConformityLabel": "Parcial",
  "lastRunAt": "2026-06-24T10:00:00Z",
  "checks": [
    {
      "id": "uuid",
      "code": "JAT-GAB-PRT-001",
      "label": "Protocolo",
      "conformityStatus": "partial",
      "conformityLabel": "Parcial",
      "tracePayload": { "steps": [], "fieldsEvaluated": [] }
    }
  ],
  "findings": []
}
```

---

## GET `/gabinete/fiscalizacao/runs/:runId/results/:resultId/trace`

Rastreio consolidado do registro (sheet *O que verificamos neste registro*).

---

## GET `/gabinete/fiscalizacao/checks/:checkId/trace`

Rastreio checagem (*Por que esta checagem deu este resultado*).

---

## GET `/gabinete/fiscalizacao/findings/:findingId/trace`

Rastreio achado (*O que gerou este achado*).

---

## Banco de perguntas

| Method | Path | Description |
|--------|------|-------------|
| GET | `/gabinete/fiscalizacao/questions` | Lista perguntas ativas/inativas |
| POST | `/gabinete/fiscalizacao/questions` | Criar pergunta (audience `internal` only) |
| PATCH | `/gabinete/fiscalizacao/questions/:id` | Editar/desativar |

---

## Questionários internos

| Method | Path | Description |
|--------|------|-------------|
| GET | `/gabinete/fiscalizacao/questionnaires` | Lista por ato ou órfão (`?entityType=&entityId=`) |
| POST | `/gabinete/fiscalizacao/questionnaires` | Criar questionário interno |
| GET | `/gabinete/fiscalizacao/questionnaires/:id` | Detalhe + itens |
| POST | `/gabinete/fiscalizacao/questionnaires/:id/respostas` | Submissão autenticada |

**POST body criar questionário**:

```json
{
  "title": "Conformidade ato GAB-2026-0012",
  "entityType": "cabinet_demanda",
  "entityId": "uuid",
  "questionIds": ["uuid1", "uuid2"]
}
```

Para órfão: `entityType` ∈ `protocolo|controle_numerico|notificacao|auto_infracao|documento_tramitado`, sem `demandaId`.

---

## Regras de checagem (referência implementação)

| code | Fonte | non_conforme / partial quando |
|------|-------|-------------------------------|
| `JAT-GAB-PRZ-001` | ato | deadline vencido sem `concessionaireResponseDate` |
| `JAT-GAB-TRM-001` | ato | encaminhamento pendente > N dias (default 5) |
| `JAT-GAB-CMP-001` | ato | assunto ou descrição vazio |
| `JAT-GAB-EVD-001` | ato | anexo não confirmado quando exigido |
| `JAT-GAB-PRT-001` | ato+protocolo | status avançado sem protocolo → partial/non_conforme |
| `JAT-GAB-PRT-002` | protocolo | remetente/recebimento/assunto vazios |
| `JAT-GAB-CNU-001` | controle numérico | número e data ausentes |
| `JAT-GAB-NOT-001` | notificação | prazo/vencimento vencido sem resposta |
| `JAT-GAB-NOT-002` | notificação | termo ou destinatário vazio |
| `JAT-GAB-AUT-001` | auto | prazo/vencimento vencido sem resposta |
| `JAT-GAB-AUT-002` | auto | setor emissor vazio |
| `JAT-GAB-PAR-001` | notif/auto | groupId definido sem par |
| `JAT-GAB-DTR-001` | doc tramitado | prazo/observação vencidos |

Conformidade agregada: worst-of (`aggregate-conformity`).

---

## Read-only

Nenhum endpoint altera `CabinetDemanda`, `CabinetProtocolo`, controles ou eventos.
