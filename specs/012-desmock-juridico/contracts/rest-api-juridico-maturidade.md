# Contract: REST API — Jurídico Maturidade (Carvalho)

**Feature**: 012-desmock-juridico  
**Prefix**: `/juridico/maturidade`  
**Guards**: `@RequireModulo('juridico')` + `@RequireLicenca('carvalho')`

Espelha [009 rest-api-ouvidoria-maturidade.md](../../009-ouvidoria-carvalho-maturidade/contracts/rest-api-ouvidoria-maturidade.md).

## Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/dashboard` | Score geral, eixos, radar, indicadores, alertas |
| GET | `/score/trace` | Payload rastreio *Como calculamos este score* |
| GET | `/self-assessment/current` | Questionário período vigente |
| POST | `/self-assessment` | Submeter/atualizar autoavaliação |
| GET | `/action-plans` | Listar planos |
| POST | `/action-plans` | Criar plano |
| PATCH | `/action-plans/:id` | Atualizar status/notas |
| POST | `/action-plans/:id/notes` | Nota de progresso |

## Score DTO

```json
{
  "overall": 81,
  "eixos": {
    "controleInterno": 84,
    "governanca": 79,
    "tecnologiaInformacao": 76
  },
  "alerta": null,
  "formula": "0,6 × autoavaliação + 0,4 × conformidade Jatobá",
  "fonteParcial": false
}
```

## Indicadores operacionais Jurídico

| Indicador | Fonte |
|-----------|-------|
| Volume de processos | count confirmados 90d |
| Prazos críticos | % status critical |
| Conformidade legal | último run Jatobá |
| Pareceres no mês | eventos `opinion` 30d |

## Escrita permitida

Autoavaliação e planos de ação — scores somente leitura.
