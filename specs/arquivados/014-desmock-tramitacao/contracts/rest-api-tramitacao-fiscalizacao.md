# Contract: REST API — Tramitação Fiscalização (Jatobá)

**Feature**: 014-desmock-tramitacao  
**Version**: 1.0.0  
**Guards**: `@RequireModulo('tramitacao')` + `@RequireLicenca('jatoba')`

Espelho [008 ouvidoria fiscalização](../../008-ouvidoria-jatoba-fiscalizacao/contracts/rest-api-ouvidoria-fiscalizacao.md) adaptado ao domínio Tramitação.

## Headers

| Header | Obrigatório |
|--------|-------------|
| `Authorization: Bearer <jwt>` | Sim |
| `X-Tenant-ID` | Sim |

---

## GET `/tramitacao/fiscalizacao`

Painel — execução mais recente + stats + achados + histórico.

**Response 200** (estrutura idêntica ouvidoria; labels Tramitação):

```json
{
  "run": {
    "id": "uuid",
    "status": "completed",
    "recordsAnalyzed": 24,
    "stats": {
      "conforme": 14,
      "nonConforme": 5,
      "partial": 3,
      "pending": 2
    }
  },
  "checksSummary": [
    {
      "label": "Prazo SLA",
      "ruleDescription": "Demanda com prazo vencido sem resposta",
      "conformityStatus": "non_conforme",
      "conformityLabel": "Não conforme",
      "sampleCount": 3
    },
    {
      "label": "Completude",
      "ruleDescription": "Assunto, corpo e setor destino obrigatórios",
      "conformityStatus": "partial",
      "conformityLabel": "Parcial",
      "sampleCount": 1
    },
    {
      "label": "Encaminhamento pendente",
      "ruleDescription": "Encaminhado sem resposta há mais de X dias",
      "conformityStatus": "non_conforme",
      "conformityLabel": "Não conforme",
      "sampleCount": 2
    }
  ],
  "findings": [
    {
      "id": "uuid",
      "title": "Prazo SLA excedido",
      "protocol": "TRAM-2026-0012",
      "conformityStatus": "non_conforme",
      "conformityLabel": "Não conforme",
      "flowStateLabel": "Em andamento"
    }
  ],
  "historyRows": []
}
```

---

## GET `/tramitacao/fiscalizacao/runs`

Histórico paginado de execuções.

**Query**: `page`, `limit`

---

## POST `/tramitacao/fiscalizacao/runs`

Dispara execução manual.

**Body**: `{ "origin": "manual" }` (optional)

**Response 202**: `{ "runId", "status": "running" }`

---

## GET `/tramitacao/fiscalizacao/demandas/:demandaId`

Checagens por demanda (read-only).

**Response 200**:

```json
{
  "demandaId": "uuid",
  "protocolNumber": "TRAM-2026-0012",
  "overallConformity": "non_conforme",
  "checks": [
    {
      "code": "sla_deadline",
      "label": "Prazo SLA",
      "conformityStatus": "non_conforme",
      "detail": "Prazo 2026-06-01 vencido"
    }
  ]
}
```

---

## Questionários internos

| Method | Path | Notes |
|--------|------|-------|
| GET | `/tramitacao/fiscalizacao/questionarios` | Lista |
| GET | `/tramitacao/fiscalizacao/questionarios/:id` | Detalhe |
| POST | `/tramitacao/fiscalizacao/questionarios/:id/respostas` | Submissão |

Padrão ouvidoria-fiscalizacao; perguntas seed `tramitacao`.

---

## Regras de checagem (referência implementação)

| code | Fonte | non_conforme quando |
|------|-------|---------------------|
| `sla_deadline` | `deadline`, `status` | deadline < now AND status ∉ {answered, archived} |
| `completeness` | subject, body, sectors | campo obrigatório vazio |
| `forwarding_pending` | último evento forwarded | sem reply posterior em > N dias (config default 5) |

Conformidade agregada: worst-of checks (padrão `aggregate-conformity`).
