# Contract: REST API — IT Maturidade (Carvalho)

**Feature**: 022-it-seguranca-informacao  
**Version**: 1.0.0  
**Prefix**: `/it/maturidade`  
**Guards**: `@RequireModulo('it')` + `@RequireLicenca('carvalho')`

Carvalho **somente leitura** sobre operação (FR-028).

## Headers

| Header | Obrigatório |
|--------|-------------|
| `Authorization: Bearer <jwt>` | Sim |
| `X-Tenant-ID` | Sim |

---

## GET `/it/maturidade`

Dashboard consolidado.

**Response 200**:

```json
{
  "defenseLines": {
    "lines": [
      { "line": "antivirus_operator", "label": "Antivírus/Operador", "percent": 45 },
      { "line": "internal_control", "label": "Controle Interno/Filtro", "percent": 35 },
      { "line": "external_audit", "label": "Auditoria Externa", "percent": 20 }
    ],
    "totalResolvedIncidents": 20,
    "alert": {
      "level": "attention",
      "message": "Percentual elevado na linha 3 pode indicar falta de treinamento na ponta."
    }
  },
  "frameworkAdherence": {
    "score": 75,
    "totalControls": 20,
    "completedControls": 15,
    "alertLevel": "attention"
  },
  "vulnerabilityBySetor": [
    {
      "setorId": "uuid",
      "setorName": "Secretaria de Finanças",
      "score": 4.2,
      "assetCount": 10,
      "openCriticalIncidents": 2,
      "openLowIncidents": 1
    }
  ],
  "readOnly": true,
  "emptyState": false
}
```

Threshold linha 3 alerta: **> 40%** (configurável tenant).

---

## Controles CIS/LGPD

### GET `/it/maturidade/controls`

Lista controles com status.

### PATCH `/it/maturidade/controls/:id`

**Body**: `{ status: "pending"|"active"|"completed" }`  
Recalcula score aderência.

---

## Rastreabilidade

### GET `/it/maturidade/trace/defense-lines`

Sheet *Como calculamos este score* — fórmula + incidentes agregados (sem PII).

### GET `/it/maturidade/trace/framework`

Detalhe controles pendentes/concluídos.

### GET `/it/maturidade/trace/vulnerability/:setorId`

Detalhe setor: ativos, incidentes abertos, recomendação consultiva.

---

## GET `/it/maturidade/setores/:setorId/detail`

Drill-down ranking vulnerabilidade (US13).

---

## Alertas licença (client-side + API metadata)

| Score aderência | Alert |
|-----------------|-------|
| < 70% | critical (R-64) |
| 70–79% | attention (R-65) |
| ≥ 80% | ok |

---

## Erros

| Code | Quando |
|------|--------|
| 403 | Sem licença Carvalho |
| 404 | Setor sem ativos |

## Notas

- Sem questionário autoavaliação nesta entrega IT — Carvalho IT é **indicadores derivados** de operação + controles framework (diferente Compras/Ouvidoria)
- Export HTML relatório: opcional v2 (Out of Scope spec 022)
