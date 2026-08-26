# Contract: REST API — Tramitação Caixa Pessoal

**Feature**: 031-tramitacao-caixa-pessoal  
**Version**: 1.0.0  
**Base URL**: `/` (Fastify)  
**Module guard**: `@RequireModulo('tramitacao')`

Extensão do contrato [014 rest-api-tramitacao](../../arquivados/014-desmock-tramitacao/contracts/rest-api-tramitacao.md).

## Headers

| Header | Rotas autenticadas |
|--------|-------------------|
| `Authorization: Bearer <jwt>` | Obrigatório |
| `X-Tenant-ID` | Obrigatório |

---

## GET `/tramitacao/demandas` (ALTERADO)

Lista inbox setorial **ou** pessoal.

**Query** (`ListInboxQuery`):

| Param | Tipo | Default | Notas |
|-------|------|---------|-------|
| `folder` | `received \| sent \| archived` | obrigatório | |
| `inboxMode` | `sector \| personal \| audit` | `sector` | `audit` só `admin_tenant` |
| `sectorId` | UUID | opcional | Obrigatório lógico quando `inboxMode=sector` |
| `page`, `limit`, `q` | | | Igual contrato 014 |

**Comportamento**:

- `inboxMode=sector`: filtro setorial existente **excluindo** pessoais ativas
- `inboxMode=personal`: filtro por participante JWT (`createdByUserId` / `targetUserId`); ignora `sectorId`
- `inboxMode=audit`: todas demandas `originType=personal` do tenant; **403** se role ≠ `admin_tenant`

**Response 200** (item estendido):

```json
{
  "items": [
    {
      "id": "uuid",
      "protocolNumber": "TRAM-2026-0042",
      "subject": "Alinhamento reservado",
      "originType": "personal",
      "personalActive": true,
      "status": "open",
      "targetUser": { "id": "uuid", "name": "Maria Silva" },
      "senderUser": { "id": "uuid", "name": "João Santos" },
      "updatedAt": "2026-07-02T14:00:00.000Z"
    }
  ],
  "page": 1,
  "limit": 20,
  "total": 1
}
```

---

## POST `/tramitacao/demandas/personal` (NOVO)

Cria demanda pessoal genérica.

**Body** (`CreatePersonalDemandaBody`):

```json
{
  "targetUserId": "uuid-destinatario",
  "subject": "Assunto privado",
  "body": "Corpo da mensagem"
}
```

| Campo | Tipo | Obrigatório |
|-------|------|-------------|
| `targetUserId` | UUID | sim |
| `subject` | string 1–500 | sim |
| `body` | string min 1 | sim |

**Response 201**: detalhe demanda (mesmo shape GET detail).

**Response 400**:

| Code | Quando |
|------|--------|
| `SAME_RECIPIENT` | Remetente = destinatário |
| `TARGET_USER_INACTIVE` | Destinatário inexistente/inativo |
| Zod validation | Campos inválidos |

---

## POST `/tramitacao/demandas/personal/linked` (NOVO)

Cria demanda pessoal com vínculo de origem.

**Body** (`CreatePersonalLinkedDemandaBody`):

```json
{
  "targetUserId": "uuid",
  "subject": "Contexto do ato",
  "body": "Veja registro anexo",
  "sourceModule": "gabinete",
  "sourceRecordId": "uuid-registro",
  "sourceSnapshot": { "schemaVersion": 2, "protocolNumber": "GAB-2026-0001" }
}
```

Validação `sourceModule` ∈ `{ gabinete, ouvidoria, juridico }`.

---

## GET `/tramitacao/demandas/:id` (ALTERADO)

**Guard**: `AssertPersonalDemandaAccess` — participante ou `admin_tenant`.

**Response 200** estendido:

```json
{
  "id": "uuid",
  "originType": "personal",
  "personalActive": true,
  "permissions": {
    "canReply": true,
    "canArchive": true,
    "canForwardToUser": true,
    "canPromoteToSector": true,
    "isReadOnlyAudit": false
  },
  "targetUser": { "id": "uuid", "name": "Maria Silva" },
  "eventos": []
}
```

**Response 404**: ID inexistente **ou** sem acesso (opaco).

---

## POST `/tramitacao/demandas/:id/reply` (ALTERADO)

Inalterado body; use case valida participação pessoal antes de responder.

Notificação: `tramitacao_pessoal_resposta` → outro participante.

---

## POST `/tramitacao/demandas/:id/forward-user` (NOVO)

Encaminha custódia pessoal para outro operador.

**Body**:

```json
{
  "targetUserId": "uuid-novo-destinatario",
  "notes": "Encaminhando para você tratar"
}
```

**Response 200**: demanda atualizada.

**Response 400**: `NOT_PERSONAL`, `SAME_RECIPIENT`, `TARGET_USER_INACTIVE`.

---

## POST `/tramitacao/demandas/:id/promote-sector` (NOVO)

Promove demanda pessoal a tramitação setorial (irreversível).

**Body**:

```json
{
  "targetSectorId": "uuid-setor",
  "notes": "Assunto requer tratamento do setor"
}
```

**Efeitos**:

1. `personalActive=false`, `targetUserId=null`
2. `currentSectorId=targetSectorId`
3. Evento `forwarded` com `targetKind: sector`
4. Notifica setor destino (`tramitacao_nova_demanda`)

**Response 400**: `NOT_PERSONAL`, `ALREADY_PROMOTED`, `SAME_SECTOR` (se aplicável).

---

## POST `/tramitacao/demandas/:id/archive` (ALTERADO)

Participante pessoal ou fluxo setorial existente; arquivamento simétrico para ambos participantes.

---

## POST `/tramitacao/demandas` (ALTERADO — setorial only)

Create genérica setorial inalterada; documentar que **não** aceita `targetUserId` — usar `/personal`.

---

## Erros canônicos

| Code | HTTP | Quando |
|------|------|--------|
| `MODULO_SETOR_DENIED` | 403 | Sem módulo tramitação |
| `AUDIT_ACCESS_DENIED` | 403 | `inboxMode=audit` sem admin_tenant |
| `NOT_PERSONAL` | 400 | Ação pessoal em demanda setorial |
| `ALREADY_PROMOTED` | 400 | Promote em demanda já setorial |
| `SAME_RECIPIENT` | 400 | Auto-envio |
| `TARGET_USER_INACTIVE` | 400 | Destinatário inválido |

---

## Endpoints inalterados nesta feature

- `GET /tramitacao/dashboard` (exclui pessoais ativas dos KPIs v1)
- Rotas fiscalização/insights/maturidade tramitação
