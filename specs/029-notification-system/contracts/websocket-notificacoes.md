# Contract: WebSocket — Sistema de Notificações

**Feature**: 029-notification-system  
**Version**: 1.0.0  
**Namespace**: `/notifications`  
**Transport**: Socket.IO (WebSocket)

## Connection

**URL dev**: `ws://localhost:3000/notifications` (mesma origem/porta da API)

**Handshake auth** (client `io()` options):

```typescript
{
  auth: {
    token: '<jwt access token>',
    tenantId: '<X-Tenant-ID>'
  }
}
```

**Server validation**:

1. Verificar JWT (mesmo secret/guard que REST)
2. Extrair `sub` → actorId, `role` → recipientRole
3. Validar `tenantId` handshake = JWT tenant
4. Join room: `tenant:{tenantId}:actor:{role}:{actorId}`
5. Emit `connection.ready` com `{ unreadCount }`

**Rejection**: disconnect imediato se token inválido/expirado.

---

## Server → Client Events

### `notification.created`

Emitido após persistência + dispatch para destinatários online.

**Payload**:

```json
{
  "id": "uuid",
  "type": "tramitacao_nova_demanda",
  "typeLabel": "Nova demanda",
  "title": "Nova demanda na Tramitação",
  "body": "TRM-2026-0042 — Assunto resumido",
  "createdAt": "2026-07-01T18:00:00.000Z",
  "sourceModule": "tramitacao",
  "sourceRecordId": "demanda-uuid",
  "navigationPath": "/tramitacao/demandas/demanda-uuid",
  "unreadCount": 4
}
```

**Client behavior**: increment badge; show toast with action → navigate `navigationPath`.

---

### `unread.count`

Emitido após mark read / read-all (sync badge).

**Payload**:

```json
{ "unreadCount": 2 }
```

---

### `connection.ready`

**Payload**:

```json
{ "unreadCount": 3 }
```

---

## Client → Server Events (v1 mínimo)

Nenhum evento client→server obrigatório na v1 (mark read via REST).

Reservado v2: `ping`, `subscribe.sector`.

---

## Reconnection

1. Socket.IO auto-reconnect (default)
2. On reconnect: server re-joins room após auth
3. Client additionally: `GET /notificacoes?unreadOnly=false&limit=50` para merge sem duplicatas (dedupe by `id`)

---

## Security

- Nunca broadcast global — apenas room do destinatário
- Não emitir payload de outro tenant
- Não incluir dados sensíveis além do snapshot resumido

---

## v1 Limitations

- Single instance — sem Redis adapter
- Multi-tab: mesmo room recebe duplicata (aceitável; UI dedupe por id)
- Escalar horizontal: evolução futura com `@socket.io/redis-adapter`
