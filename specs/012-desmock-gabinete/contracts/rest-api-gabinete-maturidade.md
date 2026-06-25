# Contract: REST API — Gabinete Maturidade (Carvalho)

**Feature**: 012-desmock-gabinete  
**Prefix**: `/gabinete/maturidade`  
**Guards**: `@RequireModulo('gabinete')` + `@RequireLicenca('carvalho')`

Espelha [009 rest-api-ouvidoria-maturidade.md](../../009-ouvidoria-carvalho-maturidade/contracts/rest-api-ouvidoria-maturidade.md).

## Endpoints principais

| Method | Path | Description |
|--------|------|-------------|
| GET | `/dashboard` | Score híbrido, eixos, alertas, indicadores operacionais |
| GET | `/dashboard/trace` | Payload rastreio *Como calculamos este score* |
| GET | `/self-assessment` | Perguntas período vigente |
| POST | `/self-assessment` | Submeter/atualizar respostas |
| GET | `/action-plans` | Planos de ação CRUD list |
| POST | `/action-plans` | Criar plano |
| PATCH | `/action-plans/:id` | Atualizar |
| POST | `/action-plans/:id/notes` | Nota rastreável |

## Score híbrido

Por eixo: `round(0.6 * selfAssessment + 0.4 * jatobaConformityRate)` — R-50.

Indicadores operacionais Gabinete (exemplos):

- Volume demandas (90d)
- Tempo médio em trâmite (eventos)
- Prazos concessionária vencidos (checagem Jatobá)
- Taxa finalizadas / total
