# Data Model: Sistema de Notificações CI v2

**Feature**: 029-notification-system  
**Date**: 2026-07-01

## Overview

Introduz entidade transversal **`Notificacao`** tenant-scoped, polimórfica em destinatário e registro vinculado. Migration Prisma nova em `prisma/schema/notificacao.prisma`. Emissores v1: módulo Tramitação apenas.

## New Prisma Types

### NotificacaoType (enum)

| Valor | Descrição |
|-------|-----------|
| `tramitacao_nova_demanda` | Demanda endereçada ao setor do destinatário |
| `tramitacao_resposta` | Resposta registrada na demanda |
| `tramitacao_encaminhamento` | Demanda encaminhada a outro setor (aviso ao remetente original) |

Extensível: novos valores via migration sem alterar colunas.

### NotificacaoRecipientRole (enum)

| Valor | Tabela destino |
|-------|----------------|
| `user` | `User.id` |
| `chefe_setor` | `User.id` |
| `admin_tenant` | `AdminTenant.id` |
| `admin_plataforma` | reservado futuro |

## Entity: Notificacao

| Campo | Tipo | Obrigatório | Notas |
|-------|------|-------------|-------|
| `id` | UUID | sim | PK |
| `tenantId` | UUID | sim | FK Tenant; tenant-scoped extension |
| `type` | NotificacaoType | sim | Tipo de evento |
| `title` | String(200) | sim | Ex.: "Nova demanda na Tramitação" |
| `body` | String(500) | sim | Resumo: protocolo + assunto truncado |
| `readAt` | DateTime? | não | null = não lida |
| `recipientUserId` | UUID? | condicional | FK User; XOR com admin |
| `recipientAdminTenantId` | UUID? | condicional | FK AdminTenant |
| `recipientRole` | NotificacaoRecipientRole | sim | Role JWT do destinatário |
| `sourceModule` | String(64) | sim | Ex.: `tramitacao`, futuro `bolinhos` |
| `sourceRecordId` | String | sim | ID do registro vinculado |
| `sourceType` | String(64) | sim | Redundante com `type` ou subtipo |
| `sourceSnapshot` | Json? | não | Snapshot imutável para UI |
| `sourceEventId` | String? | não | ID evento origem (idempotência) |
| `dedupeKey` | String(256) | sim | Unique `[tenantId, dedupeKey]` |
| `deletedAt` | DateTime? | não | Soft delete (extension) |
| `createdAt` | DateTime | sim | Ordenação lista |

**Constraints**:

- `(recipientUserId IS NOT NULL) XOR (recipientAdminTenantId IS NOT NULL)`
- `@@unique([tenantId, dedupeKey])`
- `@@index([tenantId, recipientUserId, readAt, createdAt])`
- `@@index([tenantId, recipientAdminTenantId, readAt, createdAt])`
- `@@index([sourceModule, sourceRecordId])`

## sourceSnapshot JSON (tramitação v1)

```json
{
  "schemaVersion": 1,
  "protocolNumber": "TRM-2026-0042",
  "subject": "Encaminhamento manifestação #123",
  "originType": "linked",
  "linkedSourceModule": "ouvidoria",
  "senderSectorSigla": "OUV",
  "capturedAt": "2026-07-01T18:00:00.000Z"
}
```

Imutável após insert. UI usa snapshot quando registro soft-deleted.

## State Transitions

```text
(created) ──read──► readAt set
(created) ──read-all──► readAt set (batch)
```

Sem delete físico na v1; soft delete apenas via extension global.

## Relationships

```text
Tenant 1──* Notificacao
User 1──* Notificacao (recipientUserId)
AdminTenant 1──* Notificacao (recipientAdminTenantId)
TramitacaoDemanda (via sourceModule+sourceRecordId, sem FK Prisma)
TramitacaoDemandaEvento (via sourceEventId, sem FK Prisma)
```

Sem FK Prisma para `sourceRecordId` — polimorfismo cross-módulo (US5).

## Recipient Resolution Rules

### tramitacao_nova_demanda

**Input**: `targetSectorId`, `demandaId`, `eventId`, `authorUserId?`, `authorRole`

**Output**: lista de `{ recipientUserId | recipientAdminTenantId, recipientRole }`

1. Query users com `UserSetor.setorId = targetSectorId`, `User.deletedAt = null`
2. Filtrar users com acesso módulo `tramitacao` (setor autorizado em `ModuloSetor` ou admin bypass)
3. Adicionar todos `AdminTenant` ativos do tenant
4. Remover par cujo actorId+role = autor da ação
5. Gerar uma `Notificacao` por destinatário

### tramitacao_resposta

**Input**: `demanda.createdByUserId` ou actor payload, `eventId`, excluir autor resposta

**Output**: 0–1 notificação (criador original)

### tramitacao_encaminhamento

**Input**: demanda + novo setor + `eventId`

**Output**: combinação regras resposta (tipo encaminhamento) + nova demanda (novo setor)

## dedupeKey Format

```text
{type}:{sourceModule}:{sourceRecordId}:{sourceEventId}:{recipientActorId}:{recipientRole}
```

Exemplo:

```text
tramitacao_nova_demanda:tramitacao:dem-uuid:evt-uuid:user-uuid:user
```

## Existing Entities (unchanged)

- `NotificacaoPermissao` — permanece; fora do sino v1
- `TramitacaoDemanda`, `TramitacaoDemandaEvento` — emissores; sem alteração schema

## Migration Notes

- Adicionar `notificacao.prisma` ao bundle schema
- Registrar `Notificacao` em `prisma.constants.ts` tenant-scoped models
- Seed opcional: 2–3 notificações demo para tenant Jacaranda (validação quickstart)
