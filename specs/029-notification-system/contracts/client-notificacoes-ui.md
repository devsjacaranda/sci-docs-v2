# Contract: Client UI — Sistema de Notificações

**Feature**: 029-notification-system  
**Version**: 1.0.0  
**App**: `@ci/web` (`ci-client-v2/apps/web`)

## Surfaces

| Superfície | Local | Comportamento |
|------------|-------|---------------|
| `NotificationBell` | `DesktopHeader`, `MobileAppHeader` | Ícone Bell + badge |
| `NotificationDropdown` | Popover abaixo do sino | Lista scrollável, mark all read |
| Toast ação | `ToastContext` estendido | Título + corpo + botão "Abrir" |

## NotificationBell

**Props**: nenhuma (consome `useNotifications()`)

**Estados**:

| Estado | UI |
|--------|-----|
| loading | skeleton badge oculto |
| unreadCount = 0 | sino sem badge |
| unreadCount 1–99 | badge numérico mint |
| unreadCount > 99 | badge `99+` |
| WS disconnected | sino ativo; polling `unread-count` a cada 60s (fallback) |

**Acessibilidade**: `aria-label="Notificações, N não lidas"`; teclado abre popover.

---

## NotificationDropdown

**Item row**:

```
[●] Nova demanda na Tramitação          há 2 min
    TRM-2026-0042 — Assunto truncado…
```

- `●` = não lida (mint dot); ausente se lida
- Click row → `markRead(id)` + `navigate(navigationPath)`
- Footer: botão "Marcar todas como lidas" (disabled se unreadCount=0)

**Empty state**: "Nenhuma notificação recente"

---

## Toast (real-time)

Trigger: evento WS `notification.created`

```typescript
showToast({
  title: 'Nova demanda na Tramitação',
  body: 'TRM-2026-0042 — Assunto…',
  actionLabel: 'Abrir',
  onAction: () => navigate(navigationPath),
})
```

Auto-dismiss: 5s (não crítico). Persist on hover.

**Stack**: máximo 3 toasts visíveis (queue interna).

---

## Module structure

```text
apps/web/src/modules/notificacao/
├── index.ts
├── api/notificacoes.ts
├── hooks/useNotifications.ts      # REST + WS lifecycle
├── hooks/useNotificationSocket.ts
├── lib/notificacao-mappers.ts     # API→UI, navigation registry
├── components/
│   ├── NotificationBell.tsx
│   └── NotificationDropdown.tsx
└── __tests__/
    ├── notificacao-mappers.test.ts
    └── NotificationBell.test.tsx
```

---

## Navigation registry (extensível)

```typescript
const NAVIGATION_REGISTRY: Record<string, (recordId: string) => string> = {
  tramitacao: (id) => `/tramitacao/demandas/${id}`,
  // futuro: bolinhos: (id) => `/bolinhos/${id}`,
};
```

Fallback: `#` + toast "Origem indisponível" se módulo desconhecido.

---

## Provider wiring

Em `App.tsx` ou shell root (dentro `AuthProvider`):

```typescript
<NotificationProvider>
  …
</NotificationProvider>
```

`NotificationProvider`:

- Conecta WS quando `user` autenticado
- Desconecta on logout
- Expõe context: `{ items, unreadCount, refresh, markRead, markAllRead }`

---

## Design tokens (mint-palette)

| Elemento | Light | Dark |
|----------|-------|------|
| Badge fundo | `#0F766E` | `#2DD4BF` |
| Badge texto | `#F8FAFC` | `#090D16` |
| Dot não lida | `#0F766E` | `#2DD4BF` |
| Popover superfície | `#E2E8F0` | `#1E293B` |

---

## Out of scope UI v1

- Página `/notificacoes` dedicada
- Merge `AdminNotificationsPanel` (permissão) no sino
- Sons / browser Notification API
