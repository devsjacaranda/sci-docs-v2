# Test Strategy: Sistema de Notificações CI v2

**Feature**: 029-notification-system  
**Date**: 2026-07-01

## Approach

TDD obrigatório (Constitution II). Ordem: repository → dispatch → gateway → tramitação integration → client.

---

## API Unit Tests (Jest)

| ID | Arquivo | Cenário |
|----|---------|---------|
| NT-001 | `create-notificacao.repository.spec.ts` | Persiste notificação tenant-scoped |
| NT-002 | `create-notificacao.repository.spec.ts` | DedupeKey duplicate → skip/unique violation handled |
| NT-003 | `list-notificacoes.repository.spec.ts` | Lista por recipientUserId ordenada desc |
| NT-004 | `list-notificacoes.repository.spec.ts` | Lista por recipientAdminTenantId |
| NT-005 | `count-unread.repository.spec.ts` | Contagem exclui readAt preenchido |
| NT-006 | `mark-notificacao-read.repository.spec.ts` | Marca lida idempotente |
| NT-007 | `resolve-tramitacao-recipients.service.spec.ts` | Nova demanda → users do setor + admin_tenant |
| NT-008 | `resolve-tramitacao-recipients.service.spec.ts` | Exclui autor da ação |
| NT-009 | `dispatch-notificacao.service.spec.ts` | Cria N notificações + emite WS mock |
| NT-010 | `notificacao.mapper.spec.ts` | typeLabel PT-BR, navigationPath tramitacao |

---

## API Integration Tests (Jest)

| ID | Arquivo | Cenário |
|----|---------|---------|
| NT-011 | `notificacao.controller.spec.ts` | GET /notificacoes 401 sem JWT |
| NT-012 | `notificacao.controller.spec.ts` | GET /notificacoes 200 isolamento tenant |
| NT-013 | `notificacao.controller.spec.ts` | PATCH read decrementa unreadCount |
| NT-014 | `notificacao.controller.spec.ts` | PATCH read-all |
| NT-015 | `create-demanda-notificacao.integration.spec.ts` | POST demanda → notificação persistida destinatário setor |
| NT-016 | `reply-demanda-notificacao.integration.spec.ts` | Reply → notifica criador, não autor |
| NT-017 | `forward-demanda-notificacao.integration.spec.ts` | Forward → encaminhamento + nova demanda novo setor |

---

## Gateway Tests (Jest)

| ID | Arquivo | Cenário |
|----|---------|---------|
| NT-018 | `notifications.gateway.spec.ts` | Reject connection sem token |
| NT-019 | `notifications.gateway.spec.ts` | Join room correto após auth |
| NT-020 | `notifications.gateway.spec.ts` | Emit notification.created só destinatário |

---

## Client Tests (Vitest + RTL)

| ID | Arquivo | Cenário |
|----|---------|---------|
| NT-021 | `notificacao-mappers.test.ts` | navigationPath tramitacao |
| NT-022 | `NotificationBell.test.tsx` | Badge unreadCount |
| NT-023 | `NotificationBell.test.tsx` | Click item mark read + navigate mock |
| NT-024 | `useNotificationSocket.test.ts` | Reconnect triggers refresh |
| NT-025 | `ToastContext.test.tsx` | showToast with action callback |

---

## MSW Handlers

Adicionar em `apps/web/src/test/msw/handlers/notificacoes.ts`:

- GET `/notificacoes`
- GET `/notificacoes/unread-count`
- PATCH `/notificacoes/:id/read`
- PATCH `/notificacoes/read-all`

---

## Manual QA (quickstart)

Ver [quickstart.md](../quickstart.md) — cenários US1–US4 ponta a ponta com dois browsers/usuários.

---

## Coverage targets

- Dispatch + recipient resolver: 100% branches críticos
- Gateway auth: 100%
- Client mappers: 100%
- Integration tramitação: happy path + self-exclude
