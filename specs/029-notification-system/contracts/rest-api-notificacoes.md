# Contract: REST API — Sistema de Notificações

**Feature**: 029-notification-system  
**Version**: 1.0.0  
**Base URL**: `/` (Fastify)  
**Module guard**: autenticado (JWT global); sem `@RequireModulo` específico — notificações cross-module

## Headers

| Header | Obrigatório |
|--------|-------------|
| `Authorization: Bearer <jwt>` | sim |
| `X-Tenant-ID` | sim |

---

## GET `/notificacoes`

Lista notificações do destinatário autenticado (mais recentes primeiro).

**Query** (`ListNotificacoesQuery` — Zod):

| Param | Tipo | Default |
|-------|------|---------|
| `unreadOnly` | boolean | false |
| `limit` | int 1–100 | 50 |

**Response 200**:

```json
{
  "items": [
    {
      "id": "uuid",
      "type": "tramitacao_nova_demanda",
      "typeLabel": "Nova demanda",
      "title": "Nova demanda na Tramitação",
      "body": "TRM-2026-0042 — Encaminhamento manifestação",
      "readAt": null,
      "createdAt": "2026-07-01T18:00:00.000Z",
      "sourceModule": "tramitacao",
      "sourceRecordId": "demanda-uuid",
      "sourceType": "tramitacao_nova_demanda",
      "sourceSnapshot": {
        "schemaVersion": 1,
        "protocolNumber": "TRM-2026-0042",
        "subject": "Encaminhamento manifestação #123"
      },
      "navigationPath": "/tramitacao/demandas/demanda-uuid"
    }
  ],
  "unreadCount": 3
}
```

**Notas**:

- `navigationPath` calculado server-side por registry de módulos (v1: só `tramitacao`)
- Destinatário resolvido por JWT (`sub` + `role`) — user vs admin_tenant
- Tenant isolation automático via Prisma extension

---

## GET `/notificacoes/unread-count`

Contagem leve para badge (polling fallback quando WS offline).

**Response 200**:

```json
{ "unreadCount": 3 }
```

---

## PATCH `/notificacoes/:id/read`

Marca notificação como lida.

**Response 200**:

```json
{
  "id": "uuid",
  "readAt": "2026-07-01T18:05:00.000Z",
  "unreadCount": 2
}
```

**Errors**:

| Status | Código | Quando |
|--------|--------|--------|
| 404 | — | ID inexistente ou não pertence ao destinatário |
| 403 | — | Outro tenant |

---

## PATCH `/notificacoes/read-all`

Marca todas as não lidas do destinatário como lidas.

**Response 200**:

```json
{ "updatedCount": 5, "unreadCount": 0 }
```

---

## Error envelope (padrão CI v2)

```json
{
  "statusCode": 400,
  "message": "…",
  "code": "INVALID_LIMIT"
}
```

---

## Internal (não exposto REST)

`DispatchNotificacaoService.dispatch(input)` — chamado pelos use cases de Tramitação:

```typescript
interface DispatchNotificacaoInput {
  type: NotificacaoType;
  title: string;
  body: string;
  sourceModule: string;
  sourceRecordId: string;
  sourceType: string;
  sourceSnapshot?: Record<string, unknown>;
  sourceEventId: string;
  recipients: Array<{
    recipientUserId?: string;
    recipientAdminTenantId?: string;
    recipientRole: NotificacaoRecipientRole;
  }>;
}
```

Retorno: `{ created: number; skipped: number }` (skipped = dedupe hit).
