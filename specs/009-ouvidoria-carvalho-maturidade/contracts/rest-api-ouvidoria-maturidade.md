# Contract: REST API — Ouvidoria Maturidade (Carvalho)

**Feature**: 009-ouvidoria-carvalho-maturidade  
**Version**: 1.0.0  
**Base URL**: `/` (Fastify)  
**Guards**: `@RequireModulo('ouvidoria')` + `@RequireLicenca('carvalho')` em todas as rotas abaixo

## Headers (autenticadas)

| Header | Obrigatório |
|--------|-------------|
| `Authorization: Bearer <jwt>` | Sim |
| `X-Tenant-ID` | Sim |

---

## GET `/ouvidoria/maturidade`

Dashboard consolidado: score vigente, indicadores, alerta, flags de fonte parcial e metadados Jatobá.

**Response 200**:

```json
{
  "period": {
    "id": "uuid",
    "label": "2026 Q2",
    "startsAt": "2026-04-01T00:00:00.000Z",
    "endsAt": "2026-06-30T23:59:59.999Z",
    "status": "open",
    "hasSubmission": true
  },
  "score": {
    "overall": 72,
    "overallLabel": "Score de maturidade",
    "overallAvailable": true,
    "overallAlert": "attention",
    "overallAlertLabel": "Atenção",
    "institutionalTarget": 80,
    "partialSource": false,
    "axes": [
      {
        "axis": "controle_interno",
        "axisLabel": "Controle Interno",
        "score": 68,
        "available": true,
        "selfAssessmentComponent": 65,
        "jatobaConformityComponent": 74,
        "alert": "attention"
      },
      {
        "axis": "governanca",
        "axisLabel": "Governança",
        "score": 75,
        "available": true,
        "selfAssessmentComponent": 70,
        "jatobaConformityComponent": 82,
        "alert": "attention"
      },
      {
        "axis": "tecnologia_informacao",
        "axisLabel": "Tecnologia da Informação",
        "score": 74,
        "available": true,
        "selfAssessmentComponent": 72,
        "jatobaConformityComponent": 77,
        "alert": "attention"
      }
    ]
  },
  "indicators": [
    {
      "type": "volume",
      "label": "Volume de manifestações",
      "value": 42,
      "unit": "count",
      "periodLabel": "Últimos 90 dias"
    },
    {
      "type": "avg_response_time",
      "label": "Tempo médio de resposta",
      "value": 18,
      "unit": "days",
      "periodLabel": "Últimos 90 dias"
    },
    {
      "type": "overdue_rate",
      "label": "Prazos vencidos",
      "value": 12,
      "unit": "percent",
      "periodLabel": "Última fiscalização Jatobá"
    },
    {
      "type": "resolution_rate",
      "label": "Taxa de resolução",
      "value": 67,
      "unit": "percent",
      "periodLabel": "Últimos 90 dias"
    },
    {
      "type": "satisfaction",
      "label": "Satisfação",
      "value": 71,
      "unit": "percent",
      "partialSource": true,
      "periodLabel": "Período vigente"
    }
  ],
  "jatobaReference": {
    "runId": "uuid",
    "completedAt": "2026-06-18T03:00:00.000Z",
    "isStale": false
  },
  "history": [
    {
      "periodId": "uuid",
      "periodLabel": "2026 Q1",
      "overallScore": 69,
      "scoreCi": 66,
      "scoreGov": 70,
      "scoreTi": 71,
      "computedAt": "2026-03-31T12:00:00.000Z"
    }
  ],
  "emptyReason": null
}
```

**Response 200 (sem autoavaliação)**:

```json
{
  "period": { "id": "uuid", "label": "2026 Q2", "status": "open", "hasSubmission": false },
  "score": {
    "overall": null,
    "overallAvailable": false,
    "overallAlert": null,
    "axes": [
      { "axis": "controle_interno", "score": null, "available": false }
    ]
  },
  "indicators": [],
  "emptyReason": "no_self_assessment"
}
```

`emptyReason` enum: `no_self_assessment` | `no_data` | null

---

## GET `/ouvidoria/maturidade/score/trace`

Rastreio do score vigente (sheet **Como calculamos este score**).

**Query**: `periodId` (opcional; default período vigente)

**Response 200**:

```json
{
  "title": "Como calculamos este score",
  "intro": "Esta consulta não altera dados operacionais.",
  "institutionalTarget": 80,
  "formulaDescription": "Nota do eixo = 60% autoavaliação da equipe + 40% conformidade dos registros fiscalizados.",
  "periodLabel": "2026 Q2",
  "overallScore": 72,
  "partialSource": false,
  "axes": [
    {
      "axisLabel": "Controle Interno",
      "score": 68,
      "selfAssessment": { "value": 65, "description": "Média das respostas da equipe no período." },
      "jatobaConformity": {
        "value": 74,
        "runCompletedAt": "2026-06-18T03:00:00.000Z",
        "checksIncluded": ["Prazo de resposta", "Tramitação", "Completude"],
        "manifestacoesAnalyzed": 38
      }
    }
  ],
  "technicalDetail": {
    "jatobaRunId": "uuid",
    "ruleMappingVersion": "v1"
  }
}
```

**Sem PII** em qualquer campo.

---

## GET `/ouvidoria/maturidade/indicators/:type/trace`

Rastreio de indicador operacional. `:type` ∈ `volume` | `avg_response_time` | `overdue_rate` | `resolution_rate` | `satisfaction`

**Response 200**: `{ "title", "intro", "indicatorLabel", "value", "unit", "periodLabel", "formulaDescription", "totals": {} }`

---

## GET `/ouvidoria/maturidade/periods/current`

Período de autoavaliação vigente (cria trimestre se ausente).

**Response 200**: `{ "id", "label", "startsAt", "endsAt", "status", "hasSubmission" }`

---

## GET `/ouvidoria/maturidade/self-assessment`

Perguntas ativas agrupadas por eixo + submissão existente do período vigente.

**Response 200**:

```json
{
  "period": { "id": "uuid", "label": "2026 Q2", "status": "open" },
  "questionsByAxis": [
    {
      "axis": "controle_interno",
      "axisLabel": "Controle Interno",
      "questions": [
        {
          "id": "uuid",
          "text": "A equipe segue os processos internos de ouvidoria?",
          "answerType": "scale_1_5",
          "weight": 50
        }
      ]
    }
  ],
  "submission": {
    "id": "uuid",
    "submittedAt": "2026-06-10T14:00:00.000Z",
    "answers": [{ "questionId": "uuid", "value": "4" }]
  }
}
```

`submission` null se não respondido.

---

## PUT `/ouvidoria/maturidade/self-assessment`

Submeter ou atualizar autoavaliação do período vigente.

**Body**:

```json
{
  "answers": [
    { "questionId": "uuid", "value": "4" },
    { "questionId": "uuid", "value": "yes" }
  ]
}
```

**Response 200**: `{ "submissionId", "scores": { "ci": 68, "gov": 75, "ti": 74 }, "snapshotUpdated": true }`

**Response 409**: período `closed`

---

## GET `/ouvidoria/maturidade/action-plans`

**Query**: `axis?`, `status?`, `criticality?`, `page`, `pageSize`

**Response 200**:

```json
{
  "items": [
    {
      "id": "uuid",
      "title": "Reduzir prazos vencidos",
      "axis": "controle_interno",
      "axisLabel": "Controle Interno",
      "assigneeName": "Maria Silva",
      "dueDate": "2026-07-15T00:00:00.000Z",
      "status": "in_progress",
      "statusLabel": "Em andamento",
      "criticality": "high",
      "criticalityLabel": "Alta",
      "isOverdue": false
    }
  ],
  "total": 1,
  "page": 1,
  "pageSize": 20
}
```

---

## POST `/ouvidoria/maturidade/action-plans`

**Body**:

```json
{
  "title": "Reduzir prazos vencidos",
  "description": "Implementar revisão semanal da fila.",
  "axis": "controle_interno",
  "assigneeUserId": "uuid",
  "dueDate": "2026-07-15",
  "criticality": "high",
  "linkedIndicator": "overdue_rate",
  "linkedFindingId": null
}
```

**Response 201**: plano criado com `status: pending`

**Response 403**: usuário sem perfil gestor

---

## GET `/ouvidoria/maturidade/action-plans/:id`

Detalhe com notas de progresso ordenadas DESC.

---

## PATCH `/ouvidoria/maturidade/action-plans/:id`

Atualizar campos editáveis + `status` (transições válidas).

---

## POST `/ouvidoria/maturidade/action-plans/:id/notes`

**Body**: `{ "text": "Reunião com equipe realizada." }`

**Response 201**: nota criada

---

## Erros comuns

| HTTP | Code | Quando |
|------|------|--------|
| 403 | `FORBIDDEN` | Sem módulo ou licença Carvalho |
| 403 | `ACTION_PLAN_FORBIDDEN` | CRUD plano sem perfil gestor |
| 404 | `NOT_FOUND` | Plano/período inexistente |
| 409 | `PERIOD_CLOSED` | Autoavaliação em período encerrado |

---

## Zod schemas (referência implementação)

Arquivo: `ouvidoria-maturidade.schemas.ts`

- `MaturidadeDashboardResponseSchema`
- `ScoreTraceResponseSchema`
- `SubmitSelfAssessmentBodySchema`
- `ActionPlanBodySchema`
- `ActionPlanNoteBodySchema`

Fixtures: `test/fixtures/maturidade-dashboard-full.json`, `maturidade-dashboard-empty.json`
