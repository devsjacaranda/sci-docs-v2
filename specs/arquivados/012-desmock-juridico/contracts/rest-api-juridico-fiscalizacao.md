# Contract: REST API — Jurídico Fiscalização (Jatobá)

**Feature**: 012-desmock-juridico  
**Prefix**: `/juridico/fiscalizacao`  
**Guards**: `@RequireModulo('juridico')` + `@RequireLicenca('jatoba')`

Espelha [008 rest-api-ouvidoria-fiscalizacao.md](../../008-ouvidoria-jatoba-fiscalizacao/contracts/rest-api-ouvidoria-fiscalizacao.md) adaptado para `LegalProcess`.

## Endpoints principais

| Method | Path | Description |
|--------|------|-------------|
| GET | `/panel` | Painel agregado — stats 4 conformidades, última execução, tabela histórica |
| POST | `/runs` | Disparo manual (*Fiscalizar processos*) — throttle 1h/tenant |
| GET | `/runs` | Histórico execuções paginado |
| GET | `/runs/:runId` | Detalhe execução + resultados |
| GET | `/runs/:runId/results/:processId` | Checagens + achados por processo |
| POST | `/runs/scoped/:processId` | Fiscalização de um registro (detalhe) |
| GET | `/questions` | Banco perguntas Jurídico |
| POST | `/questions` | CRUD banco (create/update/deactivate) |
| POST | `/questionnaires` | Novo questionário interno/externo |
| GET | `/public/responder/:token` | Formulário resposta externa (@Public) |
| POST | `/public/responder/:token` | Submit resposta externa (@Public) |

## DTO resultado (extensão Probabilidade de Perda)

```json
{
  "processId": "uuid",
  "numeroInterno": "JUR-2026-0047",
  "conformidade": "parcial",
  "probabilidadePerda": "alta",
  "probabilidadePerdaScore": 62,
  "checks": [
    {
      "slug": "loss_probability",
      "label": "Probabilidade de Perda",
      "conformidade": "nao_conforme",
      "probabilidadePerda": "alta",
      "fatores": [
        { "fator": "Prazo vencido", "pontos": 35 },
        { "fator": "Tipo judicial", "pontos": 25 }
      ]
    },
    {
      "slug": "judicial_identification",
      "label": "Identificação judicial",
      "conformidade": "parcial",
      "finding": "Processo judicial sem número CNJ informado"
    }
  ]
}
```

Conformidade agregada ∈ `conforme` | `nao_conforme` | `parcial` | `pendente`.

`probabilidadePerda` ∈ `baixa` | `media` | `alta` | `indeterminada` — **métrica consultiva** distinta de conformidade, mas exibida na mesma linha do painel.

## Painel — colunas tabela histórica

| Coluna API | UI |
|------------|-----|
| `numeroInterno` | Processo |
| `dadosFiscalizados` | Dados fiscalizados |
| `questionario` | Questionário |
| `destinatario` | Destinatário |
| `canal` | Canal |
| `conformidade` | Conformidade |
| `problemas` | Problemas |
| `probabilidadePerda` | Probabilidade de Perda |

## Read-only

Nenhum endpoint altera `LegalProcess`, partes, anexos ou eventos.

## Throttle

`429` código `FISCALIZACAO_THROTTLED` — uma execução completa por tenant por hora (scoped conta no mesmo limite).
