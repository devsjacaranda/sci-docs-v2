# Contract: REST API — Gabinete Insights (Cedro)

**Feature**: 012-desmock-gabinete  
**Prefix**: `/gabinete/insights`  
**Guards**: `@RequireModulo('gabinete')` + `@RequireLicenca('cedro')`

Espelha [007 rest-api-ouvidoria-insights.md](../../007-ouvidoria-cedro-insights/contracts/rest-api-ouvidoria-insights.md).

## Endpoints principais

| Method | Path | Description |
|--------|------|-------------|
| GET | `/latest` | Insights da geração mais recente |
| POST | `/runs` | Recálculo sob demanda (*Consultar IA*) |
| GET | `/runs` | Histórico batches |
| GET | `/runs/:batchId` | Detalhe batch + insights |
| GET | `/insights/:id/trace` | Rastreio *De onde veio este insight?* |

## Insight DTO

```json
{
  "id": "uuid",
  "title": "Concentração de demandas em trâmite no Jurídico",
  "summary": "…",
  "recommendation": "Priorize revisão dos encaminhamentos pendentes…",
  "impact": "high",
  "category": "operational",
  "sourceLabel": "Dados internos — Gabinete",
  "generatedAt": "2026-06-23T12:00:00.000Z"
}
```

## Regras de agregação (determinísticas)

| Slug | Fonte |
|------|-------|
| `volume_by_status` | CabinetDemanda.status |
| `forwarding_bottleneck` | forwardings + sectorId destino |
| `origin_mix` | CabinetDemanda.origin |
| `notifications_trend` | CabinetControleNotificacao |
| `tramitados_by_sector` | CabinetDocumentoTramitado.setorId |

Sem LLM/NLP; job `@nestjs/schedule` diário + recálculo on_open.
