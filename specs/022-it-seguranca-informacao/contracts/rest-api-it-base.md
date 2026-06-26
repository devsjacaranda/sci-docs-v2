# Contract: REST API — IT Base (Gestão)

**Feature**: 022-it-seguranca-informacao  
**Version**: 1.0.0  
**Prefix**: `/it`  
**Guards**: `@RequireModulo('it')`

## Headers

| Header | Obrigatório |
|--------|-------------|
| `Authorization: Bearer <jwt>` | Sim |
| `X-Tenant-ID` | Sim |

---

## GET `/it/dashboard`

Dashboard operacional (FR-008).

**Response 200**:

```json
{
  "assetCountByType": {
    "server": 12,
    "workstation": 45,
    "software_license": 8,
    "database": 6,
    "system": 15
  },
  "openIncidentsCount": 3,
  "criticalOpenIncidentsCount": 1,
  "lgpdCompliancePercent": 73,
  "emptyState": false
}
```

---

## Ativos TI

### GET `/it/ativos`

Lista paginada. Query: `type`, `setorId`, `search`, `includeDeleted=false`, `page`, `pageSize`.

**Response 200**: `{ items: ItAssetListItem[], total, page, pageSize }`

### POST `/it/ativos`

**Body**:

```json
{
  "type": "server",
  "name": "SRV-RH-01",
  "identifier": "10.0.1.50",
  "setorId": "uuid",
  "description": "Servidor RH",
  "tags": ["producao"]
}
```

**Response 201**: `ItAssetDetail`

### GET `/it/ativos/:id`

Detalhe com tags, links, incidentes relacionados.

### PATCH `/it/ativos/:id`

Atualização parcial.

### DELETE `/it/ativos/:id`

Soft delete → `204`.

### POST `/it/ativos/:id/restore`

Restaura soft delete → `200 ItAssetDetail`.

### POST `/it/ativos/:id/links`

**Body**: `{ toAssetId, linkType: "hosts"|"uses"|"depends_on" }`

### DELETE `/it/ativos/:id/links/:linkId`

### POST `/it/ativos/:id/apply-sensitive-flag`

Confirma classificação Cedro (FR-014). **Body**: `{ insightId?: string }`. Seta `containsSensitiveData=true`. Registra audit trail.

---

## Incidentes

### GET `/it/incidentes`

Query: `status`, `severity`, `setorId`, `page`, `pageSize`.

### POST `/it/incidentes`

**Body**:

```json
{
  "occurredAt": "2026-06-25T14:00:00Z",
  "severity": "critical",
  "threatType": "Ransomware",
  "setorId": "uuid",
  "assetId": "uuid",
  "description": "...",
  "errorLogs": "..."
}
```

### PATCH `/it/incidentes/:id`

### POST `/it/incidentes/:id/resolve`

**Body**: `{ resolvedAt, resolvedByDefenseLine: "antivirus_operator"|"internal_control"|"external_audit" }`

---

## Operadores / LGPD

### GET `/it/operadores`

Lista mapeamentos operador → sistema → categorias.

### POST `/it/operadores`

**Body**:

```json
{
  "operatorName": "Empresa XYZ",
  "operatorRole": "operator",
  "isExternal": true,
  "assetId": "uuid-system",
  "categoryIds": ["uuid-cpf", "uuid-health"]
}
```

### PATCH `/it/operadores/:id`

### DELETE `/it/operadores/:id`

---

## Dicionário de dados (banco)

### PUT `/it/ativos/:id/dicionario`

Substitui colunas do ativo tipo `database`.

**Body**: `{ entries: [{ tableName, columnName, description? }] }`

---

## Categorias sensíveis

### GET `/it/categorias-sensiveis`

Lista seed + tenant.

---

## Erros padrão

| Code | Quando |
|------|--------|
| 403 | Sem módulo IT |
| 404 | Ativo/incidente não encontrado |
| 422 | Zod validation |

## DTOs (Zod schemas em `it.schemas.ts`)

- `ItAssetListItem`, `ItAssetDetail`, `ItIncidentListItem`, `ItIncidentDetail`, `ItOperatorTreatmentDetail`, `ItDashboardResponse`
