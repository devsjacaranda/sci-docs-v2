# Contract: REST API — Tramitação Maturidade (Carvalho)

**Feature**: 014-desmock-tramitacao  
**Version**: 1.0.0  
**Guards**: `@RequireModulo('tramitacao')` + `@RequireLicenca('carvalho')`

Espelho [009 ouvidoria maturidade](../../009-ouvidoria-carvalho-maturidade/contracts/rest-api-ouvidoria-maturidade.md).

## Headers

| Header | Obrigatório |
|--------|-------------|
| `Authorization: Bearer <jwt>` | Sim |
| `X-Tenant-ID` | Sim |

---

## GET `/tramitacao/maturidade`

Score atual + radar + planos de ação.

**Response 200**:

```json
{
  "period": {
    "id": "uuid",
    "label": "2026-S1",
    "startDate": "2026-01-01",
    "endDate": "2026-06-30"
  },
  "score": {
    "hybrid": 68,
    "selfAssessment": 72,
    "fiscalizacao": 62,
    "formula": "0.6 * self + 0.4 * fiscalizacao"
  },
  "axes": [
    {
      "code": "response_time",
      "label": "Tempo de resposta",
      "score": 65,
      "level": "intermediate"
    },
    {
      "code": "inter_sector_flow",
      "label": "Fluxo inter-setorial",
      "score": 58,
      "level": "basic"
    }
  ],
  "actionPlans": [
    {
      "id": "uuid",
      "axisCode": "inter_sector_flow",
      "title": "Reduzir pendências de encaminhamento",
      "responsible": "Coordenação DEJUR",
      "dueDate": "2026-09-30",
      "status": "open"
    }
  ],
  "selfAssessment": {
    "completed": true,
    "submittedAt": "2026-06-15T10:00:00.000Z"
  }
}
```

---

## GET `/tramitacao/maturidade/questionario`

Perguntas de autoavaliação do período ativo.

---

## POST `/tramitacao/maturidade/autoavaliacao`

Submete respostas.

**Body**: `{ "answers": [{ "questionId": "uuid", "value": 4 }] }`

---

## POST `/tramitacao/maturidade/planos-acao`

Cria plano de ação.

**Body**:

```json
{
  "axisCode": "inter_sector_flow",
  "title": "Reduzir pendências",
  "responsible": "Nome",
  "dueDate": "2026-09-30"
}
```

**Response 201**: `{ "id" }`

---

## PATCH `/tramitacao/maturidade/planos-acao/:id`

Atualiza status/título/prazo.

---

## Score híbrido

Fórmula canônica (R-50 ouvidoria):

```
hybrid = round(0.6 * selfAssessmentScore + 0.4 * fiscalizacaoScore)
```

`fiscalizacaoScore` derivado da última run Jatobá completada (% conforme normalizado).
