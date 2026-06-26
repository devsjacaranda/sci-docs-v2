# Contract: REST API — Compras (Base)

**Feature**: 018-purchasing-crud  
**Version**: 1.0.0  
**Base URL**: `/` (Fastify)  
**Module guard**: `@RequireModulo('compras')` em todas as rotas deste contrato  
**Licença**: nenhuma (`Base` only — sem `@RequireLicenca`)

## Headers

| Header | Required |
|--------|----------|
| `Authorization: Bearer <jwt>` | yes |
| `X-Tenant-ID` | yes |

---

## PCA

### GET `/compras/pca`

Lista PCAs do tenant (modal + filtros).

**Query**: `status` (`active` | `closed` | `all`, default `all`)

**Response 200**:

```json
{
  "items": [
    {
      "id": "uuid",
      "title": "PCA 2026",
      "description": "Plano anual",
      "status": "active",
      "demandaCount": 12
    }
  ]
}
```

---

### POST `/compras/pca`

**Body**:

```json
{
  "title": "PCA 2026",
  "description": "Opcional"
}
```

**Response 201**: PCA criado com `status: "active"`.

---

### PATCH `/compras/pca/:pcaId/close`

Encerra PCA (`status → closed`). Demandas existentes permanecem vinculadas.

**Response 200**: PCA atualizado.

**Errors**: 404 tenant-scoped; 409 se já encerrado (opcional).

---

## Demandas

### GET `/compras/demandas`

Listagem paginada (FR-001, FR-002).

**Query**: `page`, `limit`, `pcaId?`, `status?` (`draft` | `in_progress` | `completed`)

**Response 200**:

```json
{
  "items": [
    {
      "id": "uuid",
      "number": 42,
      "title": "Aquisição de notebooks",
      "object": "Contratação de equipamentos...",
      "pca": { "id": "uuid", "title": "PCA 2026" },
      "status": "in_progress",
      "progress": { "satisfied": 3, "total": 7, "label": "3/7 preenchidos" }
    }
  ],
  "page": 1,
  "limit": 20,
  "total": 87
}
```

---

### POST `/compras/demandas`

**Body**:

```json
{
  "title": "string",
  "object": "string",
  "pcaId": "uuid",
  "sectorId": "uuid?"
}
```

**Validation**: `pcaId` obrigatório; PCA deve estar `active`.

**Response 201**:

```json
{
  "id": "uuid",
  "number": 43,
  "status": "draft",
  "progress": { "satisfied": 0, "total": 7, "label": "0/7 preenchidos" }
}
```

---

### GET `/compras/demandas/:demandaId`

Detalhe + hub checklist (FR-006).

**Response 200**:

```json
{
  "id": "uuid",
  "number": 43,
  "title": "...",
  "object": "...",
  "pca": { "id": "uuid", "title": "PCA 2026", "status": "active" },
  "sector": { "id": "uuid", "name": "DEAE" },
  "status": "in_progress",
  "progress": { "satisfied": 3, "total": 7, "label": "3/7 preenchidos" },
  "checklist": [
    { "key": "dfd", "label": "DFD", "state": "filled", "routeSuffix": "dfd" },
    { "key": "etp", "label": "ETP", "state": "waived", "routeSuffix": "etp" }
  ],
  "artefacts": {
    "dfd": { "...": "payload or null" },
    "etp": null
  }
}
```

**Errors**: 404 se inexistente ou outro tenant.

---

### DELETE `/compras/demandas/:demandaId`

Soft delete — some da listagem.

**Response 204**

---

## Artefatos (upsert 1:1)

Base: `/compras/demandas/:demandaId/{suffix}`

| Suffix | Métodos | Body schema |
|--------|---------|-------------|
| `dfd` | PUT, GET | `UpsertDfdBody` |
| `etp` | PUT, GET | `UpsertEtpBody` |
| `analise-riscos` | PUT, GET | `UpsertAnaliseRiscosBody` |
| `tr` | PUT, GET | `UpsertTrBody` |
| `pesquisa-precos` | PUT, GET | `UpsertPesquisaPrecosBody` |
| `dotacao-orcamentaria` | PUT, GET | `UpsertDotacaoBody` |
| `parecer-juridico` | PUT, GET | `UpsertParecerBody` |

**PUT** — upsert; recalcula status/progresso derivados na resposta.

**Response 200**: payload do artefato + `demandaStatus` + `demandaProgress` atualizados.

### Exemplo `UpsertEtpBody`

```json
{
  "waived": true,
  "waiverReason": "Dispensa legal art. X"
}
```

ou (não dispensado):

```json
{
  "waived": false,
  "solutionDescription": "...",
  "viabilityAnalysis": "...",
  "costEstimate": 150000.00
}
```

### Exemplo `UpsertAnaliseRiscosBody`

```json
{
  "risks": [
    {
      "description": "Atraso na entrega",
      "probability": "media",
      "impact": "alto",
      "mitigation": "Penalidades contratuais"
    }
  ]
}
```

---

## Comprovante (por artefato)

### POST `/compras/demandas/:demandaId/{suffix}/comprovante/presign`

**Body**: `{ "fileName": "doc.pdf", "mimeType": "application/pdf", "sizeBytes": 1024 }`

**Response 200**: `{ "uploadUrl": "...", "storageKey": "..." }`

Limites: 30 MB, MIME allowlist (mesmo padrão Gabinete).

### POST `/compras/demandas/:demandaId/{suffix}/comprovante/confirm`

**Response 200**: artefato com metadados de comprovante.

Falha de upload: campos estruturados permanecem — client re-tenta anexo.

---

## Relatório PDF (indisponível)

### GET `/compras/demandas/:demandaId/relatorio`

**Response 501**:

```json
{
  "message": "Exportação PDF não disponível nesta versão.",
  "code": "NOT_IMPLEMENTED"
}
```

---

## Errors (padrão plataforma)

| Code | Quando |
|------|--------|
| 400 | Validação Zod (PCA ausente, valor ≤ 0, ETP dispensado sem motivo) |
| 403 | Sem acesso ao módulo Compras |
| 404 | Recurso inexistente ou outro tenant |
| 409 | Conflito opcional (PCA encerrado em create) |

Schemas Zod completos: `ci-api-v2/src/modules/compras/compras.schemas.ts` (implementação).
