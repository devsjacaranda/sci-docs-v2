# Contract: REST API — Tramitação (Base)

**Feature**: 014-desmock-tramitacao  
**Version**: 1.0.0  
**Base URL**: `/` (Fastify)  
**Module guard**: `@RequireModulo('tramitacao')` — módulo aberto (`OPEN_MODULES`)

## Headers

| Header | Required |
|--------|----------|
| `Authorization: Bearer <jwt>` | yes |
| `X-Tenant-ID` | yes |

Setor ativo: derivado do JWT (`activeSectorId`) ou query `sectorId` quando usuário tem múltiplos setores.

---

## Dashboard

### GET `/tramitacao/dashboard`

**Query**: `periodDays` (optional, default 365), `sectorId` (optional)

**Response 200**:

```json
{
  "total": 58,
  "pending": 12,
  "answered": 34,
  "resolutivityRate": 0.72,
  "bySourceModule": [
    { "module": "gabinete", "label": "Gabinete", "count": 15 },
    { "module": "ouvidoria", "label": "Ouvidoria", "count": 22 },
    { "module": "juridico", "label": "Jurídico", "count": 8 },
    { "module": "generic", "label": "Genérica", "count": 3 }
  ],
  "periodStart": "2025-06-24T00:00:00.000Z",
  "periodEnd": "2026-06-24T23:59:59.999Z"
}
```

---

## Inbox

### GET `/tramitacao/demandas`

Lista paginada por pasta inbox.

**Query**:

| Param | Required | Notes |
|-------|----------|-------|
| `folder` | yes | `received` \| `sent` \| `archived` |
| `sectorId` | no | default JWT active sector |
| `page` | no | default 1 |
| `limit` | no | default 20, max 50 |
| `q` | no | busca assunto/protocolo |

**Response 200**:

```json
{
  "items": [
    {
      "id": "uuid",
      "protocolNumber": "TRAM-2026-0001",
      "subject": "Encaminhamento manifestação",
      "preview": "Primeiros 120 chars…",
      "originType": "linked",
      "sourceModule": "ouvidoria",
      "sourceModuleLabel": "Ouvidoria",
      "status": "open",
      "statusLabel": "Aberta",
      "senderSector": { "id": "uuid", "sigla": "OUV", "name": "Ouvidoria" },
      "currentSector": { "id": "uuid", "sigla": "DEJUR", "name": "Jurídico" },
      "deadline": "2026-07-01T00:00:00.000Z",
      "hasDeadline": true,
      "createdAt": "2026-06-20T10:00:00.000Z",
      "updatedAt": "2026-06-21T14:30:00.000Z"
    }
  ],
  "page": 1,
  "limit": 20,
  "total": 42
}
```

---

## Compor genérica

### POST `/tramitacao/demandas`

**Body**:

```json
{
  "targetSectorId": "uuid",
  "subject": "Assunto",
  "body": "Corpo texto simples",
  "deadline": "2026-07-15T00:00:00.000Z"
}
```

**Response 201**: `{ "id", "protocolNumber", "status" }`

**Errors**: 400 `SAME_SECTOR`, `INVALID_TARGET_SECTOR`

---

## Detalhe

### GET `/tramitacao/demandas/:id`

**Response 200**: demanda completa + `timeline[]` + `linkedRecord` (quando aplicável) + counts anexos.

```json
{
  "id": "uuid",
  "protocolNumber": "TRAM-2026-0001",
  "subject": "…",
  "body": "…",
  "originType": "linked",
  "sourceModule": "gabinete",
  "sourceRecordId": "uuid",
  "sourceSnapshot": { "protocolNumber": "GAB-2026-0042", "subject": "…", "status": "in_transit" },
  "senderSector": { "id": "…", "sigla": "GAB", "name": "Gabinete" },
  "currentSector": { "id": "…", "sigla": "DEJUR", "name": "Jurídico" },
  "status": "in_progress",
  "deadline": null,
  "timeline": [
    {
      "id": "uuid",
      "type": "created",
      "typeLabel": "Criação",
      "payload": {},
      "author": { "name": "Maria", "sectorSigla": "GAB" },
      "createdAt": "2026-06-20T10:00:00.000Z"
    }
  ],
  "actions": ["reply", "forward", "archive"]
}
```

---

## Responder

### POST `/tramitacao/demandas/:id/reply`

**Body**: `{ "body": "Texto resposta" }`

**Response 200**: `{ "eventId", "status" }`

**Errors**: 409 `DEMANDA_ARCHIVED`

---

## Encaminhar

### POST `/tramitacao/demandas/:id/forward`

**Body**:

```json
{
  "targetSectorId": "uuid",
  "notes": "Justificativa opcional"
}
```

**Response 200**: `{ "currentSectorId", "eventId" }`

**Errors**: 409 `DEMANDA_ARCHIVED`, 400 `SAME_SECTOR`

---

## Arquivar

### POST `/tramitacao/demandas/:id/archive`

**Response 200**: `{ "status": "archived", "archivedAt" }`

---

## Anexos

### POST `/tramitacao/demandas/:id/anexos/presign`

### POST `/tramitacao/demandas/:id/anexos/:anexoId/confirm`

Mesmo contrato ouvidoria/gabinete: 30 MB, MIME allowlist, Wasabi presigned.

---

## Linked record (interno — não exposto como rota pública v1)

`CreateLinkedDemandaUseCase` invocado por:

- `gabinete` forward
- `ouvidoria` encaminhar
- `juridico` tramitar

DTO interno documentado em integrações dos contratos de origem.

---

## Erros padrão

```json
{
  "statusCode": 403,
  "code": "LICENCA_REQUIRED",
  "licenca": "jatoba"
}
```

```json
{
  "statusCode": 409,
  "code": "DEMANDA_ARCHIVED",
  "message": "Demanda arquivada não aceita alterações"
}
```
