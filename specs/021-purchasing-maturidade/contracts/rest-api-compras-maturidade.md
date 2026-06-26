# Contract: REST API — Compras Maturidade (Carvalho)

**Feature**: 021-purchasing-maturidade  
**Version**: 1.0.0  
**Base URL**: `/` (Fastify)  
**Guards**: `@RequireModulo('compras')` + `@RequireLicenca('carvalho')` em todas as rotas abaixo

Espelha [009 rest-api-ouvidoria-maturidade.md](../../arquivados/009-ouvidoria-carvalho-maturidade/contracts/rest-api-ouvidoria-maturidade.md) com adaptações: **4 dimensões Compras**, híbrido Jatobá **só em Conformidade**, **sem action-plans**, **+ orientações** e **+ export**.

## Headers (autenticadas)

| Header | Obrigatório |
|--------|-------------|
| `Authorization: Bearer <jwt>` | Sim |
| `X-Tenant-ID` | Sim |

---

## GET `/compras/maturidade`

Dashboard consolidado: score vigente, dimensões, indicadores operacionais, orientações, histórico, metadados Jatobá.

**Response 200**:

```json
{
  "period": {
    "id": "uuid",
    "label": "2026 Q2",
    "startsAt": "2026-04-01T00:00:00.000Z",
    "endsAt": "2026-06-30T23:59:59.999Z",
    "status": "open",
    "hasSubmission": true,
    "submissionStatus": "submitted"
  },
  "score": {
    "overall": 68,
    "overallLabel": "Score de maturidade",
    "overallAvailable": true,
    "overallAlert": "attention",
    "overallAlertLabel": "Atenção",
    "institutionalTarget": 80,
    "adequateThreshold": 60,
    "partialSource": false,
    "dimensions": [
      {
        "dimension": "planejamento",
        "dimensionLabel": "Planejamento",
        "score": 72,
        "available": true,
        "selfAssessmentComponent": 72,
        "jatobaConformityComponent": null,
        "alert": "attention",
        "isBelowAdequate": false
      },
      {
        "dimension": "instrucao_processual",
        "dimensionLabel": "Instrução processual",
        "score": 55,
        "available": true,
        "selfAssessmentComponent": 55,
        "jatobaConformityComponent": null,
        "alert": "critical",
        "isBelowAdequate": true
      },
      {
        "dimension": "conformidade",
        "dimensionLabel": "Conformidade",
        "score": 61,
        "available": true,
        "selfAssessmentComponent": 58,
        "jatobaConformityComponent": 65,
        "alert": "attention",
        "isBelowAdequate": false
      },
      {
        "dimension": "resultados",
        "dimensionLabel": "Resultados",
        "score": 78,
        "available": true,
        "selfAssessmentComponent": 78,
        "jatobaConformityComponent": null,
        "alert": "attention",
        "isBelowAdequate": false
      }
    ]
  },
  "indicators": [
    {
      "type": "artefact_funnel",
      "label": "Funil de artefatos",
      "value": 57,
      "unit": "percent",
      "periodLabel": "Demandas ativas"
    },
    {
      "type": "budget_inconsistency_rate",
      "label": "Inconsistências orçamentárias",
      "value": 20,
      "unit": "percent",
      "periodLabel": "Última fiscalização Jatobá"
    },
    {
      "type": "licitation_conformity_rate",
      "label": "Conformidade licitatória",
      "value": 65,
      "unit": "percent",
      "periodLabel": "Última fiscalização Jatobá"
    }
  ],
  "orientations": [
    {
      "dimension": "instrucao_processual",
      "dimensionLabel": "Instrução processual",
      "score": 55,
      "isBelowAdequate": true,
      "title": "Fortaleça a instrução processual",
      "actions": [
        "Implemente pesquisa de preços sistemática antes da abertura de processos.",
        "Padronize o termo de referência com critérios de julgamento explícitos."
      ]
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
      "overallScore": 62,
      "scorePlanejamento": 60,
      "scoreInstrucao": 52,
      "scoreConformidade": 58,
      "scoreResultados": 70,
      "computedAt": "2026-03-31T12:00:00.000Z"
    }
  ],
  "submissionMeta": {
    "submittedByName": "Maria Silva",
    "submittedAt": "2026-06-20T14:30:00.000Z"
  },
  "emptyReason": null
}
```

**Response 200 (sem autoavaliação submetida)**:

```json
{
  "period": { "id": "uuid", "label": "2026 Q2", "status": "open", "hasSubmission": false, "submissionStatus": null },
  "score": {
    "overall": null,
    "overallAvailable": false,
    "dimensions": [
      { "dimension": "planejamento", "score": null, "available": false }
    ]
  },
  "indicators": [],
  "orientations": [],
  "emptyReason": "no_self_assessment"
}
```

`emptyReason`: `no_self_assessment` | `no_data` | null

---

## GET `/compras/maturidade/score/trace`

Rastreio do score vigente (sheet **Como calculamos este score**).

**Query**: `periodId` (opcional; default período vigente)

**Response 200**:

```json
{
  "title": "Como calculamos este score",
  "intro": "Esta consulta não altera demandas nem artefatos.",
  "institutionalTarget": 80,
  "adequateThreshold": 60,
  "formulaDescription": "Dimensão Conformidade = 60% autoavaliação + 40% conformidade fiscalizada. Demais dimensões = autoavaliação.",
  "periodLabel": "2026 Q2",
  "overallScore": 68,
  "partialSource": false,
  "dimensions": [
    {
      "dimensionLabel": "Conformidade",
      "score": 61,
      "selfAssessment": { "value": 58, "description": "Média ponderada das respostas da equipe." },
      "jatobaConformity": {
        "value": 65,
        "runCompletedAt": "2026-06-18T03:00:00.000Z",
        "demandasAnalyzed": 10,
        "checksIncluded": ["Completude DFD", "Pesquisa de preços", "Consistência orçamentária"]
      }
    }
  ],
  "technicalDetail": {
    "jatobaRunId": "uuid",
    "ruleMappingVersion": "v1-compras"
  }
}
```

**Sem PII** — nenhum protocolo de demanda individual.

---

## GET `/compras/maturidade/indicators/:type/trace`

Rastreio de indicador operacional.

`:type` ∈ `artefact_funnel` | `budget_inconsistency_rate` | `licitation_conformity_rate`

**Response 200**: `{ "title", "intro", "indicatorLabel", "value", "unit", "periodLabel", "formulaDescription", "totals": {} }`

---

## GET `/compras/maturidade/periods/current`

Período de avaliação corrente (cria se ausente).

**Response 200**: `{ "id", "label", "startsAt", "endsAt", "status", "hasSubmission", "submissionStatus" }`

---

## GET `/compras/maturidade/self-assessment`

Questionário do período vigente + respostas existentes (draft ou submitted).

**Response 200**:

```json
{
  "period": { "id": "uuid", "label": "2026 Q2" },
  "submissionStatus": "draft",
  "dimensions": [
    {
      "dimension": "planejamento",
      "dimensionLabel": "Planejamento",
      "questions": [
        {
          "id": "uuid",
          "text": "O PCA consolida demandas com estimativa orçamentária?",
          "answerType": "yes_no",
          "required": true,
          "weight": 1,
          "answer": { "value": "yes", "numericValue": 100 }
        }
      ]
    }
  ],
  "pendingRequiredCount": 2
}
```

---

## PATCH `/compras/maturidade/self-assessment/answers`

Salva respostas parciais (FR-008). Cria submission `draft` se necessário.

**Body**:

```json
{
  "answers": [
    { "questionId": "uuid", "value": "4" },
    { "questionId": "uuid", "value": "yes" }
  ]
}
```

**Response 200**: `{ "submissionStatus": "draft", "savedCount": 2, "pendingRequiredCount": 5 }`

**Response 400**: `{ "message": "...", "invalidQuestionIds": [] }`

---

## PUT `/compras/maturidade/self-assessment`

Submete autoavaliação completa. Valida obrigatórias; calcula scores; persiste snapshot.

**Body**:

```json
{
  "answers": [
    { "questionId": "uuid", "value": "4" }
  ]
}
```

**Response 200**: dashboard resumido `{ "period", "score", "orientations", "submissionMeta" }`

**Response 400**: `{ "message": "Perguntas obrigatórias pendentes", "pendingQuestionIds": ["uuid"] }`

**Response 409**: `{ "message": "Outro gestor submeteu avaliação neste período", "submittedAt": "..." }` — informativo; última submissão prevalece após PUT bem-sucedido.

---

## GET `/compras/maturidade/export`

Relatório HTML imprimível (FR-010).

**Query**: `periodId` (opcional; default vigente)

**Response 200**: `Content-Type: text/html` — documento com score, dimensões, orientações, histórico (se ≥2), autor/data.

**Response 400**: `{ "message": "Complete a autoavaliação antes de exportar" }` quando sem submission submitted.

---

## Erros comuns

| Status | Condição |
|--------|----------|
| 401 | JWT ausente/inválido |
| 403 | Sem módulo Compras ou sem licença Carvalho |
| 404 | `periodId` inválido cross-tenant |
| 400 | Validação Zod / perguntas pendentes |

## Endpoints **NÃO** incluídos (Out of Scope 021)

- `/action-plans/*` — planos de ação detalhados (Carvalho futuro)
- CRUD de perguntas pelo usuário
