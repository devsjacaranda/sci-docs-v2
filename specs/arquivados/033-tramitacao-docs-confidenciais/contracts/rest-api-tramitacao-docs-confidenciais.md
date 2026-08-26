# Contract: REST API — Tramitação Documentos Confidenciais

**Feature**: 033-tramitacao-docs-confidenciais  
**Version**: 1.0.0  
**Base URL**: `/` (Fastify)  
**Module guard**: `@RequireModulo('tramitacao')`

Extensão dos contratos [014 rest-api-tramitacao](../../arquivados/014-desmock-tramitacao/contracts/rest-api-tramitacao.md) e [031 caixa pessoal](../../arquivados/031-tramitacao-caixa-pessoal/contracts/rest-api-tramitacao-caixa-pessoal.md).

## Headers

| Header | Obrigatório |
|--------|-------------|
| `Authorization: Bearer <jwt>` | sim |
| `X-Tenant-ID` | sim |

---

## GET `/tramitacao/demandas/:id` (ALTERADO)

**Response 200** — timeline inclui anexos por evento com `accessLevel`:

```json
{
  "id": "uuid",
  "protocolNumber": "TRAM-2026-0100",
  "subject": "Encaminhamento com anexo restrito",
  "body": "Corpo visível a todos do setor",
  "timeline": [
    {
      "id": "event-uuid",
      "type": "created",
      "typeLabel": "Criação",
      "payload": {},
      "anexos": [
        {
          "id": "anexo-uuid",
          "kind": "file",
          "fileName": "parecer.pdf",
          "mimeType": "application/pdf",
          "sizeBytes": 102400,
          "isConfidential": true,
          "accessLevel": "full",
          "attachedAt": "2026-07-03T10:00:00.000Z"
        },
        {
          "id": "anexo-uuid-2",
          "kind": "file",
          "fileName": "Documento confidencial",
          "isConfidential": true,
          "accessLevel": "placeholder",
          "attachedAt": "2026-07-03T10:00:00.000Z"
        }
      ],
      "createdAt": "2026-07-03T10:00:00.000Z"
    }
  ],
  "anexoCounts": { "total": 2, "confidential": 1, "visible": 1 }
}
```

Regras:
- `accessLevel=placeholder` — **sem** `url`, `storageKey`, `downloadUrl`
- `admin_tenant` (audit ou detail) — todos `full`
- Autor do anexo — sempre `full`

---

## POST `/tramitacao/demandas/:id/anexos/presign` (NOVO)

**Body** (`PresignTramitacaoAnexoBody`):

```json
{
  "fileName": "relatorio.pdf",
  "mimeType": "application/pdf",
  "sizeBytes": 204800,
  "eventoId": "uuid-opcional"
}
```

**Response 200**:

```json
{
  "anexoId": "uuid",
  "uploadUrl": "https://...",
  "expiresIn": 900
}
```

**Errors**: 400 `FILE_TOO_LARGE`, `FILE_TYPE_NOT_ALLOWED`; 409 `DEMANDA_ARCHIVED`

---

## POST `/tramitacao/demandas/:id/anexos/:anexoId/confirm` (NOVO)

**Body** (`ConfirmTramitacaoAnexoBody`):

```json
{
  "isConfidential": true,
  "access": [
    { "sectorId": "uuid-setor-a", "userIds": ["uuid-user-1", "uuid-user-2"] },
    { "sectorId": "uuid-setor-b", "userIds": ["uuid-user-3"] }
  ]
}
```

| Campo | Tipo | Obrigatório |
|-------|------|-------------|
| `isConfidential` | boolean | não (default false) |
| `access` | array | sim se `isConfidential=true` |
| `access[].sectorId` | UUID | sim |
| `access[].userIds` | UUID[] min 1 | sim |

**Response 200**: `{ "id": "uuid", "uploadConfirmed": true, "isConfidential": true }`

**Errors**:
- 400 `CONFIDENTIAL_ACCESS_REQUIRED`
- 400 `EMPTY_SECTOR_USERS`
- 400 `USER_NOT_IN_SECTOR`
- 409 `DEMANDA_ARCHIVED`
- 409 `ANEXO_ALREADY_CONFIRMED`

---

## POST `/tramitacao/demandas/:id/anexos/link` (NOVO)

**Body** (`AddTramitacaoLinkAnexoBody`):

```json
{
  "title": "Documento externo",
  "url": "https://example.com/doc",
  "eventoId": "uuid-opcional",
  "isConfidential": false
}
```

Mesmo schema `access` quando `isConfidential=true`.

**Response 201**: anexo link confirmado.

---

## GET `/tramitacao/demandas/:id/anexos/:anexoId/download` (NOVO)

Gera URL presigned de download (arquivos) ou redireciona URL (links) **somente** se autorizado.

**Response 200**:

```json
{
  "downloadUrl": "https://...",
  "expiresIn": 900,
  "fileName": "parecer.pdf"
}
```

**Errors**: 403 `ANEXO_ACCESS_DENIED`; 404 anexo/demanda; 409 placeholder (confidencial sem acesso)

---

## POST `/tramitacao/demandas/:id/reply` (ALTERADO)

**Body** estendido:

```json
{
  "body": "Texto resposta",
  "pendingAnexoIds": ["uuid-1"]
}
```

`pendingAnexoIds` opcional — anexos já confirmados no evento `reply` criado na mesma transação ou vinculados via `eventoId` no confirm após reply.

Fluxo client recomendado:
1. `POST reply` → obtém `eventId`
2. presign/confirm cada anexo com `eventoId=eventId`

---

## POST `/tramitacao/demandas/:id/forward` (ALTERADO)

Mesmo padrão de reply — anexos opcionais no encaminhamento via presign/confirm pós-evento `forwarded`. ACL de anexos pré-existentes **não** enviada no body — imutável.

---

## Fluxos pessoais (031)

Rotas `POST /demandas/personal`, `POST .../reply`, `POST .../forward-user`, `POST .../promote-sector` aceitam mesma sequência presign/confirm/link com guards `assertPersonalDemandaAccess`.

---

## Erros adicionais

```json
{
  "statusCode": 400,
  "code": "CONFIDENTIAL_ACCESS_REQUIRED",
  "message": "Selecione ao menos um usuário por setor para documento confidencial"
}
```

```json
{
  "statusCode": 403,
  "code": "ANEXO_ACCESS_DENIED",
  "message": "Você não tem permissão para acessar este documento"
}
```
