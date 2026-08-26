# Implementation Plan: Sistema de Notificações CI v2

**Branch**: `029-notification-system` | **Date**: 2026-07-01 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/029-notification-system/spec.md`

## Summary

Implementar **sistema transversal de notificações in-app** com entrega em tempo real (WebSockets/Socket.IO), persistência PostgreSQL, modelo polimórfico de linked records e UI sino+toast no shell. **Escopo v1**: emissores apenas do módulo Tramitação (nova demanda, resposta, encaminhamento). Arquitetura extensível para futuros módulos sem alterar núcleo `Notificacao`.

**Abordagem**: novo módulo `notificacao/` na API (repository + use-cases + gateway + dispatch service); hooks nos use cases existentes de tramitação; módulo espelho `notificacao/` no client com `NotificationBell` no header.

## Technical Context

**Language/Version**: TypeScript 5.x / 6.x; Node.js 20 LTS

**Primary Dependencies**:

| Pacote | Stack / novos pacotes |
|--------|----------------------|
| **ci-api-v2** | NestJS 11, Fastify, Pino, Zod, Prisma 7, PostgreSQL |
| **ci-api-v2 (novo)** | `@nestjs/websockets`, `@nestjs/platform-socket.io`, `socket.io` |
| **ci-client-v2** | React 19, Vite 8, Tailwind v4, shadcn/ui, `socket.io-client` |

**Storage**: PostgreSQL — nova entidade `Notificacao` (+ enums); migration em `prisma/schema/notificacao.prisma`

**Testing**: Jest (API unit + integration + gateway); Vitest/RTL/MSW (client) — [test-strategy.md](./contracts/test-strategy.md)

**Target Platform**: API Linux/container single-instance; SPA browser (`@ci/web`)

**Project Type**: Full-stack feature (novo módulo transversal + integração tramitação)

**Performance Goals**: Entrega WS < 500ms pós-commit; lista REST < 300ms p95; SC-001 alerta ≤ 5s

**Constraints**:

- TDD RED → GREEN → REFACTOR
- Zod only — sem class-validator
- Tenant AsyncLocalStorage — Prisma extension tenant-scoped
- Destinatário polimórfico: `User` vs `AdminTenant` (rule admin-tenant-user-fk)
- v1 **sem Redis** — rooms in-memory; documentar limitação multi-instância
- Idempotência `dedupeKey` por evento+destinatário
- Toast via extensão `ToastContext` existente (sem Sonner na v1)
- `NotificacaoPermissao` permanece separada

**Scale/Scope**: ~1 migration; módulo API ~25 arquivos; módulo client ~12 arquivos; 4 hooks tramitação; ~30 testes NT-*

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Princípio | Status | Notas |
|-----------|--------|-------|
| I. Spec-Driven | ✅ PASS | Spec 029 + checklist validados |
| II. Test-First | ✅ PASS | test-strategy NT-001..025 |
| III. Stack fixa | ✅ PASS | NestJS 11 + Prisma 7 + React 19 + Vite 8; deps WS alinhadas Nest |
| IV. Multi-tenant | ✅ PASS | Notificacao tenant-scoped; WS room inclui tenantId |
| IV. Licenças | ✅ PASS | Tramitação módulo aberto (Base) |
| V. Escopo mínimo | ✅ PASS | Módulo dedicado; dispatch injetado; sem migrar legado permissão |

**Post-design re-check**: Nova entidade justificada — não existe modelo transversal (research R2). WebSocket Gateway é requisito spec (tempo real FR-001). Dependências `@nestjs/websockets` + `socket.io` são extensão padrão Nest, não desvio de stack. Sem Complexity Tracking necessário.

## Project Structure

### Documentation (this feature)

```text
civ2-docs/specs/029-notification-system/
├── plan.md              # This file
├── research.md          # Phase 0
├── data-model.md        # Phase 1
├── quickstart.md        # Phase 1
├── contracts/
│   ├── rest-api-notificacoes.md
│   ├── websocket-notificacoes.md
│   ├── client-notificacoes-ui.md
│   └── test-strategy.md
└── tasks.md             # Phase 2 — /speckit-tasks
```

### Source Code (repository root)

```text
ci-api-v2/
├── prisma/schema/
│   └── notificacao.prisma                    # NEW
├── prisma/migrations/                        # NEW migration
├── prisma/seed/
│   └── seed-notificacao-demo.ts              # NEW (opcional)
├── src/modules/notificacao/
│   ├── notificacao.module.ts
│   ├── notificacao.controller.ts             # GET list, unread-count, PATCH read
│   ├── notificacao.gateway.ts                # Socket.IO namespace /notifications
│   ├── notificacao.schemas.ts
│   ├── notificacao.mapper.ts
│   ├── notificacao.types.ts
│   ├── lib/
│   │   ├── build-dedupe-key.ts
│   │   └── navigation-registry.ts
│   ├── services/
│   │   ├── dispatch-notificacao.service.ts   # persist + WS emit
│   │   └── resolve-tramitacao-recipients.service.ts
│   ├── repository/
│   │   ├── create-notificacao.repository.ts
│   │   ├── list-notificacoes.repository.ts
│   │   ├── count-unread-notificacoes.repository.ts
│   │   └── mark-notificacao-read.repository.ts
│   └── use-cases/
│       ├── list-notificacoes.use-case.ts
│       ├── get-unread-count.use-case.ts
│       ├── mark-notificacao-read.use-case.ts
│       └── mark-all-notificacoes-read.use-case.ts
├── src/modules/tramitacao/
│   ├── tramitacao.module.ts                  # import NotificacaoModule
│   └── use-cases/
│       ├── create-generic-demanda.use-case.ts    # + dispatch nova_demanda
│       ├── create-linked-demanda.use-case.ts     # + dispatch nova_demanda
│       ├── reply-demanda.use-case.ts             # + dispatch resposta
│       └── forward-demanda.use-case.ts           # + dispatch encaminhamento
├── src/main.ts                               # IoAdapter Socket.IO
└── src/infrastructure/prisma/prisma.constants.ts  # + Notificacao

ci-client-v2/apps/web/src/
├── modules/notificacao/
│   ├── index.ts
│   ├── api/notificacoes.ts
│   ├── hooks/useNotifications.ts
│   ├── hooks/useNotificationSocket.ts
│   ├── context/NotificationProvider.tsx
│   ├── lib/notificacao-mappers.ts
│   ├── components/
│   │   ├── NotificationBell.tsx
│   │   └── NotificationDropdown.tsx
│   └── __tests__/…
├── modules/shared/context/ToastContext.tsx   # extend action toast
├── modules/shell/components/layout/
│   ├── AppShell.tsx                          # + NotificationBell desktop
│   └── MobileAppHeader.tsx                   # + NotificationBell mobile
└── test/msw/handlers/notificacoes.ts         # NEW
```

**Structure Decision**: Módulo transversal `notificacao/` espelha padrão `permissao/` (repository + use-cases). Tramitação permanece emissor via `DispatchNotificacaoService` — sem acoplar Prisma de Notificacao dentro de repositories de demanda. Client coloca sino no shell, não em ScreenPage.

## Implementation Phases

### Phase A — Schema + repositories (P1 foundation)

1. Prisma schema `Notificacao` + migration
2. Repositories CRUD + dedupe
3. TDD NT-001..NT-006

### Phase B — Dispatch + tramitação recipients (P1 US1)

1. `ResolveTramitacaoRecipientsService`
2. `DispatchNotificacaoService` (persist batch + gateway emit)
3. Hook create-generic + create-linked + reply + forward
4. TDD NT-007..NT-010, NT-015..NT-017

### Phase C — REST + Gateway (P1 US1–US4)

1. Controller REST + Zod schemas
2. `NotificationsGateway` JWT handshake + rooms
3. `main.ts` IoAdapter
4. TDD NT-011..NT-014, NT-018..NT-020

### Phase D — Client sino + WS (P1 US2)

1. `NotificationProvider` + socket hook
2. `NotificationBell` + dropdown
3. Integrar AppShell headers
4. MSW handlers + TDD NT-021..NT-024

### Phase E — Toast + polish (P1/P2)

1. Estender `ToastContext` com action
2. Wire WS → toast
3. Mark read on navigate
4. Seed demo opcional + quickstart manual

### Phase F — Extensibility validation (P4 US5)

1. Navigation registry documentado
2. Unit test segundo módulo hipotético no registry (sem emissor real)
3. Contract review data-model snapshot fields

## Dependencies Between Phases

```text
A → B → C → D → E
         └──────→ F (paralelo após D)
```

## Risks & Mitigations

| Risco | Mitigação |
|-------|-----------|
| Fastify + Socket.IO bootstrap | Spike em Phase C; IoAdapter em main.ts |
| Recipient explosion (setor grande) | Batch insert; limite razoável; log count |
| admin_tenant sem setor | Incluir todos admin_tenant ativos (research R3) |
| WS auth token expiry | Reconnect + REST sync on focus |

## Out of Scope (plan confirms spec)

- E-mail, SMS, push mobile
- Redis / multi-instance
- Emissores fora tramitação
- Migração NotificacaoPermissao
- Página dedicada notificações

## Generated Artifacts

| Artifact | Path |
|----------|------|
| Research | [research.md](./research.md) |
| Data model | [data-model.md](./data-model.md) |
| REST contract | [contracts/rest-api-notificacoes.md](./contracts/rest-api-notificacoes.md) |
| WebSocket contract | [contracts/websocket-notificacoes.md](./contracts/websocket-notificacoes.md) |
| Client UI contract | [contracts/client-notificacoes-ui.md](./contracts/client-notificacoes-ui.md) |
| Test strategy | [contracts/test-strategy.md](./contracts/test-strategy.md) |
| Quickstart | [quickstart.md](./quickstart.md) |

**Next command**: `/speckit-tasks`
