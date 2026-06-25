# Contract: REST API — Gabinete Fiscalização (Jatobá)

**Feature**: 012-desmock-gabinete  
**Prefix**: `/gabinete/fiscalizacao`  
**Guards**: `@RequireModulo('gabinete')` + `@RequireLicenca('jatoba')`

Espelha [008 rest-api-ouvidoria-fiscalizacao.md](../../008-ouvidoria-jatoba-fiscalizacao/contracts/rest-api-ouvidoria-fiscalizacao.md) adaptado para `CabinetDemanda`.

## Endpoints principais

| Method | Path | Description |
|--------|------|-------------|
| GET | `/panel` | Painel agregado — stats 4 conformidades, última execução |
| POST | `/runs` | Disparo manual (*Fiscalizar demandas*) — throttle 1h/tenant |
| GET | `/runs` | Histórico execuções paginado |
| GET | `/runs/:runId` | Detalhe execução + resultados |
| GET | `/runs/:runId/results/:demandaId` | Checagens + achados por demanda |
| GET | `/questions` | Banco perguntas Gabinete |
| POST | `/questionnaires` | Novo questionário interno |
| POST | `/public/responder/:token` | Resposta externa (se habilitado futuro — Gabinete: **somente interno** v1) |

## DTO resultado

```json
{
  "demandaId": "uuid",
  "protocolNumber": "GAB-2026-0001",
  "conformity": "partial",
  "checks": [
    {
      "slug": "deadline",
      "label": "Prazo concessionária",
      "conformity": "non_conforme",
      "finding": "Prazo vencido sem resposta registrada"
    }
  ]
}
```

Conformidade agregada ∈ `conforme` \| `nao_conforme` \| `parcial` \| `pendente` — mapper UI PT-BR.

## Read-only

Nenhum endpoint altera `CabinetDemanda`, eventos ou controles.
