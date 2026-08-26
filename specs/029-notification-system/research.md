# Research: Sistema de Notificações CI v2

**Feature**: 029-notification-system  
**Date**: 2026-07-01

## R1 — Transporte em tempo real: WebSockets (Socket.IO)

**Decision**: WebSockets via `@nestjs/websockets` + `@nestjs/platform-socket.io` + `socket.io` (API) e `socket.io-client` (client).

**Rationale**:

- Escolha explícita do produto na fase specify (bidirecional reservada para evoluções; v1 usa principalmente server→client).
- NestJS Gateway abstrai rooms, handshake auth e reconexão.
- Compatível com Fastify via `IoAdapter` customizado em `main.ts` (NestJS documenta adapter Socket.IO independente do HTTP adapter).
- v1 **sem Redis**: rooms em memória na instância única — suficiente para SC-001 (< 5s) em deploy single-node.

**Alternatives considered**:

| Opção | Motivo rejeição |
|-------|-----------------|
| SSE | Menor flexibilidade bidirecional; usuário escolheu WS |
| Long-polling | Latência e carga HTTP maiores |
| Redis pub/sub na v1 | Fora de escopo; adicionar quando escalar horizontalmente |

**Detalhes produção v1**:

- Namespace `/notifications`
- Handshake JWT (`auth.token` + `auth.tenantId`) — rejeitar socket não autenticado
- Room por destinatário: `tenant:{tenantId}:actor:{role}:{actorId}`
- Eventos emitidos: `notification.created`, `unread.count`
- Fallback: client faz `GET /notificacoes` no connect/reconnect para sincronizar perdidos

---

## R2 — Modelo de dados unificado vs legado

**Decision**: Nova entidade Prisma `Notificacao` em módulo transversal `notificacao/`; **não** migrar `NotificacaoPermissao` na v1.

**Rationale**:

- Spec declara consolidação opcional futura; `NotificacaoPermissao` é domínio de permissão (tipo fixo, chief-only).
- Evita migration destrutiva e regressão em fluxo admin existente (`AdminNotificationsPanel`).
- Sino no header consome apenas `Notificacao`; painel admin de permissões permanece separado.

**Alternatives considered**: Tabela única com `domain` enum — rejeitado na v1 por acoplamento e shapes distintos.

---

## R3 — Destinatário polimórfico (User vs AdminTenant)

**Decision**: Campos `recipientUserId?` (FK `User`) + `recipientAdminTenantId?` (FK `AdminTenant`) — exatamente um preenchido; índices separados para listagem.

**Rationale**: Alinha com rule `admin-tenant-user-fk.mdc` — `admin_tenant` não é linha em `User`. JWT `sub` aponta para tabela correta por role.

**Resolução de elegíveis (tramitação nova demanda)**:

1. Usuários ativos com `UserSetor.setorId = currentSectorId` (setor destinatário)
2. Filtrar por acesso ao módulo `tramitacao` via `CheckModuloAccessUseCase` ou query equivalente em `ModuloSetor` + permissões
3. Incluir `AdminTenant` ativos do tenant (acesso institucional amplo)
4. Excluir autor da ação (`excludeActorId` + `excludeActorRole`)

**Resposta / encaminhamento**:

- **Resposta**: notificar `demanda.createdByUserId` (ou `actorId`/`actorRole` do payload se admin criou) — excluir autor da resposta
- **Encaminhamento**: notificar criador original (tipo `tramitacao_encaminhamento`) + elegíveis do novo setor (tipo `tramitacao_nova_demanda`)

---

## R4 — Idempotência

**Decision**: Campo `dedupeKey` único por tenant: `{type}:{sourceModule}:{sourceRecordId}:{sourceEventId}:{recipientActorId}:{recipientRole}`.

**Rationale**: FR-016 exige evitar duplicatas; encaminhamentos/retries de use case não geram spam. `sourceEventId` = `TramitacaoDemandaEvento.id`.

**Alternatives considered**: Upsert silencioso sem chave — rejeitado; difícil testar e auditar.

---

## R5 — Integração com Tramitação (emissores v1)

**Decision**: Serviço `DispatchNotificacaoService` injetado nos use cases de tramitação **após** persistência bem-sucedida:

| Use case | Eventos disparados |
|----------|-------------------|
| `CreateGenericDemandaUseCase` | `tramitacao_nova_demanda` → setor destino |
| `CreateLinkedDemandaUseCase` | idem (usado por ouvidoria/jurídico/gabinete) |
| `ReplyDemandaUseCase` | `tramitacao_resposta` → criador original |
| `ForwardDemandaUseCase` | `tramitacao_encaminhamento` → criador + `tramitacao_nova_demanda` → novo setor |

**Rationale**: Side-effect após commit transacional; falha de notificação não reverte demanda (log + retry manual futuro). v1: try/catch com Pino warn.

**Alternatives considered**: Nest EventEmitter desacoplado — válido, mas over-engineering para 4 call sites; service direto mantém traceabilidade TDD.

---

## R6 — Linked record na notificação

**Decision**: Reutilizar shape polimórfico da Tramitação:

```typescript
{
  sourceModule: 'tramitacao',
  sourceRecordId: demandaId,
  sourceType: 'tramitacao_nova_demanda' | ...,
  sourceSnapshot: {
    schemaVersion: 1,
    protocolNumber,
    subject,
    originType,
    linkedSourceModule?,  // ouvidoria/juridico/gabinete quando linked
    capturedAt: ISO8601
  }
}
```

**Rationale**: US5 extensibilidade — futuro módulo "bolinhos" preenche `sourceModule: 'bolinhos'` sem alterar tabela. Client mapeia `sourceModule` → rota (`tramitacao` → `/tramitacao/demandas/:id`).

**Alternatives considered**: Snapshot completo da demanda — rejeitado; payload grande; campos essenciais bastam para toast + dropdown.

---

## R7 — UI: sino + toast

**Decision**:

- Componente `NotificationBell` em `DesktopHeader` e `MobileAppHeader` (entre ThemeToggle e UserMenu)
- Dropdown shadcn (`Popover` + `ScrollArea`) — últimas 50 notificações
- Toast: **estender** `ToastContext` existente com overload `showToast({ title, body, actionLabel, onAction })` — evita introduzir Sonner (não está no monorepo)

**Rationale**: Constitution stack shadcn; ToastContext já usado em ouvidoria/jurídico; extensão mínima atende FR-004.

**Alternatives considered**: Sonner — rejeitado na v1 para evitar nova dependência; pode migrar depois.

---

## R8 — Fastify + Socket.IO bootstrap

**Decision**: Adicionar em `main.ts`:

```typescript
import { IoAdapter } from '@nestjs/platform-socket.io';
app.useWebSocketAdapter(new IoAdapter(app));
```

Validar CORS credentials para handshake WS (mesma origem dev/prod).

**Rationale**: Padrão NestJS 11; Fastify permanece HTTP adapter; WS em servidor paralelo Socket.IO (porta compartilhada).

---

## R9 — Testes

**Decision**:

| Camada | Ferramenta | Foco |
|--------|------------|------|
| API unit | Jest | Dispatch service, dedupe, recipient resolver, mappers |
| API integration | Jest + supertest | REST list/mark read; tramitação → notificação persistida |
| Gateway | Jest | Mock socket server — handshake JWT, room join, emit |
| Client unit | Vitest + RTL | NotificationBell, hook reconnect, toast action |
| Client integration | MSW + Vitest | REST handlers; mock socket client |

**Rationale**: Constitution TDD; gateway testado isolado sem browser E2E na v1.

---

## R10 — Performance e limites v1

**Decision**:

- Lista REST default `limit=50`, max 100
- Badge cap UI `99+`
- Entrega WS best-effort; persistência garante SC-004
- Target: emit < 500ms após commit (dentro SC-001 5s)

**Alternatives considered**: Fila BullMQ — fora de escopo v1 (spec Out of Scope).
