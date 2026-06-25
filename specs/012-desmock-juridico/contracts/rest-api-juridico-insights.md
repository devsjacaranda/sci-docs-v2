# Contract: REST API — Jurídico Insights (Cedro)

**Feature**: 012-desmock-juridico  
**Prefix**: `/juridico/insights`  
**Guards**: `@RequireModulo('juridico')` + `@RequireLicenca('cedro')`

Espelha [007 rest-api-ouvidoria-insights.md](../../007-ouvidoria-cedro-insights/contracts/rest-api-ouvidoria-insights.md).

## Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/panel` | Insights da geração mais recente |
| POST | `/batches` | Disparo *Consultar IA* (throttle 15min/tenant) |
| GET | `/batches` | Histórico lotes |
| GET | `/batches/:batchId` | Detalhe lote + insights |
| GET | `/insights/:insightId/trace` | Payload rastreio (ou embutido no panel) |

## Insight card DTO

```json
{
  "id": "uuid",
  "titulo": "Concentração de risco em processos judiciais",
  "resumo": "42% dos processos abertos são judiciais; 18% com Probabilidade de Perda alta.",
  "impacto": "alto",
  "recomendacao": "Priorizar pareceres nos 6 processos com prazo crítico e risco alto.",
  "fonte": "Dados internos — Jurídico",
  "categoria": "operacional"
}
```

Categorias: `operational`, `risk`, `organizational` (mapeamento interno EN).

## Agregadores v1 (determinísticos)

1. Volume por tipo e esfera
2. Backlog prazos críticos
3. Distribuição Probabilidade de Perda (última fiscalização)
4. Top tribunais/órgãos por volume
5. Processos abertos > 30 dias

## Read-only

Nenhum endpoint altera processos.
