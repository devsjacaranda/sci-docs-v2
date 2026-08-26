# REST API Contract: Global Dashboard

**Feature**: 031-global-dashboard-demock  
**Base path**: `/global/dashboard`

## GET /global/dashboard

Retorna agregação read-only para a home global do tenant.

### Auth

- Bearer JWT obrigatório
- Tenant via `X-Tenant-ID` + AsyncLocalStorage
- Sem `@RequireModulo` — rota aberta a qualquer usuário autenticado do tenant (global é módulo base)

### Query

| Param | Tipo | Default | Descrição |
| --- | --- | --- | --- |
| `periodDays` | int 1–90 | `30` | Janela para KPIs e gráfico |

Validação Zod: `globalDashboardQuerySchema` em `global-dashboard.schemas.ts`.

### Response 200

```json
{
  "periodDays": 30,
  "periodStart": "2026-06-02T00:00:00.000Z",
  "periodEnd": "2026-07-02T23:59:59.999Z",
  "kpis": [
    {
      "id": "priority_occurrences",
      "label": "Ocorrências prioritárias",
      "value": 5,
      "trend": "3 manifestações · 2 demandas atrasadas",
      "source": "real"
    },
    {
      "id": "pending_demands",
      "label": "Demandas pendentes",
      "value": 12,
      "trend": "últimos 30 dias",
      "source": "real"
    },
    {
      "id": "updates_24h",
      "label": "Atualizações (24h)",
      "value": 18,
      "trend": "eventos de tramitação",
      "source": "real"
    },
    {
      "id": "active_records_cross",
      "label": "Registros ativos (transversal)",
      "value": "—",
      "trend": "agregação cross-módulo pendente",
      "source": "mock"
    }
  ],
  "recentActivity": [
    {
      "id": "evt-uuid",
      "title": "Demanda #1842 encaminhada ao Jurídico",
      "moduleLabel": "Tramitação",
      "kind": "tramitacao",
      "createdAt": "2026-07-02T14:12:00.000Z",
      "navigationPath": "/tramitacao/demandas/uuid",
      "source": "real"
    }
  ],
  "chart": {
    "id": "linked_demands_by_module",
    "title": "Demandas linked por módulo de origem",
    "source": "real",
    "periodStart": "2026-06-02T00:00:00.000Z",
    "periodEnd": "2026-07-02T23:59:59.999Z",
    "data": [
      { "module": "ouvidoria", "label": "Ouvidoria", "count": 8 },
      { "module": "gabinete", "label": "Gabinete", "count": 4 }
    ]
  },
  "meta": {
    "includesOuvidoria": true,
    "generatedAt": "2026-07-02T15:00:00.000Z"
  }
}
```

### Errors

| Status | Quando |
| --- | --- |
| 401 | Token ausente/inválido |
| 400 | Query inválida (Zod) |
| 500 | Erro interno — client NÃO faz fallback para mock |

### Implementação

```
ci-api-v2/src/modules/global-dashboard/
├── global-dashboard.module.ts
├── global-dashboard.controller.ts
├── global-dashboard.schemas.ts
├── global-dashboard.mapper.ts
├── repository/
│   └── get-global-dashboard.repository.ts
├── use-cases/
│   └── get-global-dashboard.use-case.ts
└── test/
    ├── global-dashboard.schemas.spec.ts
    ├── use-cases/get-global-dashboard.use-case.spec.ts
    └── fixtures/global-dashboard-empty.json
```

### Reuso interno

- Lógica de período alinhada a `GetDashboardUseCase` (tramitação)
- Labels de módulo via `moduleLabel()` de `tramitacao.mapper.ts`
- Feed de notificações: injetar `ListNotificacoesRepository` ou query direta limitada

### Registro

Importar `GlobalDashboardModule` em `app.module.ts`.
