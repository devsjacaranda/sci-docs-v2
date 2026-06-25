# Contract: REST API — Ouvidoria Fiscalização (Jatobá)

**Feature**: 008-ouvidoria-jatoba-fiscalizacao  
**Version**: 1.0.0  
**Base URL**: `/` (Fastify)  
**Guards**: `@RequireModulo('ouvidoria')` + `@RequireLicenca('jatoba')` em rotas autenticadas abaixo

## Headers (autenticadas)

| Header | Obrigatório |
|--------|-------------|
| `Authorization: Bearer <jwt>` | Sim |
| `X-Tenant-ID` | Sim |

---

## GET `/ouvidoria/fiscalizacao`

Painel — execução mais recente `completed` + stats + amostra de achados + linhas histórico.

**Response 200**:

```json
{
  "run": {
    "id": "uuid",
    "startedAt": "2026-06-19T03:00:00.000Z",
    "completedAt": "2026-06-19T03:00:05.000Z",
    "origin": "scheduled",
    "originLabel": "Agendada",
    "status": "completed",
    "recordsAnalyzed": 18,
    "stats": {
      "conforme": 10,
      "nonConforme": 3,
      "partial": 2,
      "pending": 3
    },
    "isStale": false
  },
  "checksSummary": [
    {
      "label": "Prazo de resposta",
      "ruleDescription": "Data limite conforme tipo de manifestação",
      "conformityStatus": "non_conforme",
      "conformityLabel": "Não conforme",
      "sampleCount": 4
    }
  ],
  "findings": [
    {
      "id": "uuid",
      "title": "Prazo de resposta vencido",
      "description": "Manifestação OUV-2026-0138 sem resposta formal",
      "conformityStatus": "non_conforme",
      "conformityLabel": "Não conforme",
      "protocol": "OUV-2026-0138",
      "flowStateLabel": "Aguardando resposta interna"
    }
  ],
  "historyRows": [
    {
      "resultId": "uuid",
      "protocol": "OUV-2026-0138",
      "fiscalizedData": "Prazo e qualidade da resposta",
      "questionnaireTitle": "Conformidade ouvidoria",
      "recipientLabel": "Interno",
      "channelLabel": "Portal interno",
      "conformityLabel": "Não conforme",
      "problems": "Prazo vencido"
    }
  ]
}
```

**Response 200 (sem execução)**:

```json
{
  "run": null,
  "checksSummary": [],
  "findings": [],
  "historyRows": [],
  "emptyReason": "never_run"
}
```

`emptyReason`: `never_run` | `no_data`

---

## GET `/ouvidoria/fiscalizacao/runs`

Histórico de execuções (paginado).

**Query**: `page` (default 1), `limit` (default 20, max 50)

**Response 200**:

```json
{
  "items": [
    {
      "id": "uuid",
      "startedAt": "2026-06-19T03:00:00.000Z",
      "origin": "on_demand",
      "originLabel": "Sob demanda",
      "status": "completed",
      "recordsAnalyzed": 18,
      "stats": { "conforme": 10, "nonConforme": 3, "partial": 2, "pending": 3 }
    }
  ],
  "page": 1,
  "limit": 20,
  "total": 3
}
```

---

## GET `/ouvidoria/fiscalizacao/runs/:runId`

Detalhe de execução com todos os results.

---

## POST `/ouvidoria/fiscalizacao/run`

Dispara execução completa (todas manifestações confirmadas).

**Body** (opcional):

```json
{ "origin": "on_demand" }
```

**Response 200**: mesmo shape de GET painel após conclusão.

**Response 429**:

```json
{
  "statusCode": 429,
  "code": "FISCALIZACAO_THROTTLED",
  "message": "Fiscalização disponível uma vez por hora. Tente novamente mais tarde.",
  "retryAfterSeconds": 2400
}
```

**Response 409**: execução em andamento (`FISCALIZACAO_RUNNING`).

---

## POST `/ouvidoria/fiscalizacao/run/manifestacoes/:manifestacaoId`

Execução scoped a um registro (`origin = on_record`). Conta no throttle horário.

---

## GET `/ouvidoria/fiscalizacao/manifestacoes/:manifestacaoId`

Card no detalhe — checagens da última execução para o protocolo.

**Response 200**:

```json
{
  "protocol": "OUV-2026-0138",
  "conformityLabel": "Não conforme",
  "checks": [
    {
      "id": "uuid",
      "label": "Prazo de resposta",
      "ruleDescription": "Data limite conforme tipo",
      "conformityLabel": "Não conforme"
    }
  ],
  "lastRunAt": "2026-06-19T03:00:00.000Z",
  "canRunScoped": true
}
```

---

## GET `/ouvidoria/fiscalizacao/checks/:checkId/trace`

**Response 200**:

```json
{
  "traceType": "check",
  "title": "Por que esta checagem deu este resultado",
  "ruleId": "JAT-OUV-PRZ-001",
  "label": "Prazo de resposta",
  "conformityLabel": "Não conforme",
  "steps": [
    "SLA Reclamação: 30 dias corridos",
    "Data limite: 2026-06-01",
    "Sem evento de resposta na linha do tempo"
  ],
  "fieldsEvaluated": ["type", "events", "status"],
  "protocol": "OUV-2026-0138",
  "manifestacaoId": "uuid"
}
```

Sem PII em manifestações anônimas.

---

## GET `/ouvidoria/fiscalizacao/findings/:findingId/trace`

Título sheet: **O que gerou este achado**.

---

## GET `/ouvidoria/fiscalizacao/manifestacoes/:manifestacaoId/trace`

Título sheet: **O que verificamos neste registro** — lista checagens da última execução.

---

## Banco de perguntas

### GET `/ouvidoria/fiscalizacao/questions`

Lista perguntas ativas + inativas (admin).

### POST `/ouvidoria/fiscalizacao/questions`

**Body**:

```json
{
  "text": "A manifestação foi respondida dentro do prazo legal?",
  "answerType": "yes_no",
  "allowedAudience": "internal",
  "sortOrder": 1
}
```

### PATCH `/ouvidoria/fiscalizacao/questions/:questionId`

Atualizar texto, tipo, audience, active, sortOrder.

---

## Questionários

### GET `/ouvidoria/fiscalizacao/questionnaires`

**Query**: `manifestacaoId` (opcional), `page`, `limit`

### POST `/ouvidoria/fiscalizacao/questionnaires`

**Body**:

```json
{
  "manifestacaoId": "uuid",
  "title": "Conformidade ouvidoria",
  "audience": "internal",
  "channel": "portal",
  "questionIds": ["uuid1", "uuid2"]
}
```

Para `audience: "external"`, `channel` ∈ `whatsapp` | `email`. Response inclui `responseLink` (URL com token plain once).

**Response 400**: manifestação anônima/sem contato — `EXTERNAL_QUESTIONNAIRE_NOT_ELIGIBLE`.

### POST `/ouvidoria/fiscalizacao/questionnaires/:questionnaireId/respond`

Resposta interna autenticada.

**Body**:

```json
{
  "answers": [{ "itemId": "uuid", "value": "sim" }]
}
```

---

## SLA config

### GET `/ouvidoria/fiscalizacao/sla-config`

Lista dias por tipo para o tenant.

### PATCH `/ouvidoria/fiscalizacao/sla-config`

**Body**:

```json
{
  "items": [{ "manifestacaoType": "complaint", "daysLimit": 30 }]
}
```

---

## Rotas públicas (sem JWT)

### GET `/public/ouvidoria/fiscalizacao/responder/:token`

Formulário externo — metadados do questionário + itens (sem PII manifestante além do necessário).

### POST `/public/ouvidoria/fiscalizacao/responder/:token`

Submissão de respostas externas.

**Response 410**: token expirado ou já respondido.

---

## Códigos de erro

| Code | HTTP | Quando |
|------|------|--------|
| `FISCALIZACAO_THROTTLED` | 429 | 2ª execução na hora |
| `FISCALIZACAO_RUNNING` | 409 | run em andamento |
| `EXTERNAL_QUESTIONNAIRE_NOT_ELIGIBLE` | 400 | anônimo/sem contato |
| `QUESTIONNAIRE_TOKEN_INVALID` | 404 | token inválido |

---

## Read-only guarantee

Nenhum endpoint acima altera `Manifestacao.status`, `Manifestacao.priority`, `ManifestacaoEvento` ou campos operacionais. Validar em E2E via mock call counts (SC-004).
