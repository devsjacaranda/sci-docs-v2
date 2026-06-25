# Data Model: Auth Session Logout (013)

**Feature**: 013-auth-session-logout · **Date**: 2026-06-24

> Sem novas tabelas Prisma obrigatórias. Alterações comportamentais em entidades existentes + estado client.

## AuditLog (existente — comportamento estendido)

Trilha de mutações tenant. Schema inalterado em colunas; semântica de preenchimento ajustada.

| Field | Required | Notes |
|-------|----------|-------|
| `id` | yes | UUID |
| `tenantId` | yes | Do request context |
| `userId` | no | FK → `User.id` **somente** se ator existir em `User`; `null` para `AdminTenant` |
| `action` | yes | HTTP method (POST, PATCH, …) |
| `entity` | yes | Path sem query |
| `entityId` | no | Opcional futuro |
| `payload` | no | Body da request + metadados de ator quando `userId` null |
| `createdAt` | yes | Auto |

### Payload extension (JSON, quando `userId` null)

| Field | Type | Description |
|-------|------|-------------|
| `actorId` | string | JWT `sub` (pode ser AdminTenant.id) |
| `actorRole` | string | JWT `role` (ex.: `admin_tenant`) |
| `…requestBody` | object | Campos originais do body da mutação |

**Validation rules**:

- MUST NOT inserir `userId` que não exista em `User` para o tenant
- Falha na gravação MUST NOT propagar para resposta HTTP da mutação
- `tenantId` MUST vir do AsyncLocalStorage (nunca manual)

---

## Sessão client (@ci/web)

Estado em memória + `sessionStorage`. Não persiste entidade server-side nova.

| Concept | Storage | Lifecycle |
|---------|---------|-----------|
| Access token | `sessionStorage['ci-access-token']` | Set no login; remove no logout/session lost |
| Mock session key | `sessionStorage['ci-mock-session']` | Modo `VITE_USE_API=false` only |
| User profile | React state `AuthContext.user` | Hydrate via `/auth/me` on boot |
| Auth loading | React state `AuthContext.loading` | true until bootstrap completes |
| Session lost reason | `location.state.sessionMessage` | Ephemeral — login page only |

### State transitions

```text
[anonymous]
  → login success → [authenticated] (user set, token set)

[authenticated]
  → 401 / network on apiFetch → [session lost] → navigate /login + message
  → manual logout → [anonymous]
  → fetchCurrentUser fail on boot → [anonymous]

[authenticated]
  → 403 on module → [authenticated] (sem logout; AccessDenied403)
  → 4xx/5xx business error → [authenticated] + toast
```

### SessionLostReason (client enum)

| Value | Trigger | Login message |
|-------|---------|---------------|
| `unauthorized` | HTTP 401 | Sessão expirada. Entre novamente. |
| `network` | fetch rejection / unreachable | Não foi possível manter sua sessão. Entre novamente. |

---

## Login redirect state (react-router)

| Field | Type | Purpose |
|-------|------|---------|
| `from` | string | Rota protegida de origem (existente) |
| `sessionMessage` | string | Copy exibida no card de login pós session lost |

**Validation**: `sessionMessage` opcional; quando ausente, login sem banner de sessão.
