# Contract: REST API — IT Insights (Cedro)

**Feature**: 022-it-seguranca-informacao  
**Version**: 1.0.0  
**Prefix**: `/it/insights`  
**Guards**: `@RequireModulo('it')` + `@RequireLicenca('cedro')`

Badge UI: **Somente leitura** (R-21). Insights **não** alteram ativos — exceto fluxo *Aplicar classificação* via Base.

## Headers

| Header | Obrigatório |
|--------|-------------|
| `Authorization: Bearer <jwt>` | Sim |
| `X-Tenant-ID` | Sim |

---

## GET `/it/insights`

Painel — insights recentes + stats por impacto.

**Response 200**:

```json
{
  "stats": { "critical": 2, "high": 5, "medium": 3 },
  "insights": [
    {
      "id": "uuid",
      "type": "config_scan",
      "impact": "critical",
      "impactLabel": "Crítico",
      "title": "Porta 21 aberta",
      "message": "A configuração do servidor SRV-RH-01 está com a porta 21 aberta, gerando risco.",
      "assetId": "uuid",
      "assetName": "SRV-RH-01",
      "createdAt": "2026-06-25T10:00:00Z",
      "readOnly": true
    }
  ],
  "emptyReason": null
}
```

---

## Análise de configurações

### POST `/it/insights/config/presign`

**Body**: `{ assetId, fileName, contentType, sizeBytes }`  
**Response 200**: `{ uploadUrl, storageKey, expiresIn }`

### POST `/it/insights/config/analyze`

**Body**: `{ assetId, storageKey, fileName }`  
Processa regex → persiste `ItConfigAnalysis` + insights.  
**Response 200**: `{ analysisId, findings: Finding[], insights: Insight[] }`

### GET `/it/insights/config/history`

Lista análises anteriores por tenant.

---

## Classificador LGPD

### POST `/it/insights/lgpd/classify/:assetId`

Varre dicionário do ativo `database`. Emite insight se termos encontrados — **não** altera flag.

**Response 200**:

```json
{
  "classified": true,
  "insight": {
    "id": "uuid",
    "impact": "high",
    "title": "Dados sensíveis detectados",
    "message": "Atenção, este banco de dados contém campos com dados sensíveis. Mova para a pasta restrita ou aplique criptografia.",
    "matches": [
      { "columnName": "cpf_funcionario", "term": "cpf" }
    ],
    "readOnly": true,
    "applyAction": {
      "label": "Aplicar classificação",
      "endpoint": "POST /it/ativos/:id/apply-sensitive-flag"
    }
  }
}
```

Se nenhum termo: `{ "classified": false, "insight": null }`.

---

## Matriz de impacto

### POST `/it/insights/risk-matrix/evaluate`

Stateless (FR-015).

**Body**:

```json
{
  "systemName": "RH",
  "accessType": "external",
  "mfaEnabled": false,
  "dataNature": "personal"
}
```

**Response 200**:

```json
{
  "level": "high",
  "levelLabel": "Risco Alto",
  "score": 82,
  "explanation": "Esta ação expõe dados pessoais à rede pública sem autenticação de dois fatores (MFA).",
  "path": ["accessType=external", "mfaEnabled=false", "dataNature=personal"],
  "readOnly": true
}
```

---

## Rastreabilidade

### GET `/it/insights/:id/trace`

Payload para sheet *De onde veio este insight*.

---

## Throttle / Cron

- Manual classify/analyze: max 1/min por asset (paridade Compras Insights)
- Cron diário opcional: `INSIGHTS_CRON` reutilizado

## Erros

| Code | Quando |
|------|--------|
| 403 | Sem licença Cedro |
| 422 | Arquivo inválido / asset type incorreto |
