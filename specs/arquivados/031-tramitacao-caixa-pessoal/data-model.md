# Data Model: Caixa Pessoal na Tramitação

**Feature**: 031-tramitacao-caixa-pessoal  
**Date**: 2026-07-02

## Overview

Estende `TramitacaoDemanda` e eventos existentes para suportar mensagens **usuário-a-usuário** com visibilidade restrita, promoção setorial irreversível e auditoria `admin_tenant`. Uma migration Prisma adiciona enum value, campos e índices.

## Schema Changes (Prisma)

### TramitacaoDemandaOriginType (enum)

```prisma
enum TramitacaoDemandaOriginType {
  generic
  linked
  personal   // NEW
}
```

### TramitacaoDemanda (alterações)

| Campo | Tipo | Notas |
|-------|------|-------|
| `targetUserId` | `String?` | FK `User` — destinatário atual (obrigatório quando `originType=personal` AND `personalActive=true`) |
| `personalActive` | `Boolean` | `@default(true)` — `false` após promoção setorial |

Relação:

```prisma
targetUser User? @relation("TramitacaoPersonalTarget", fields: [targetUserId], references: [id])
```

Índices novos:

```prisma
@@index([tenantId, targetUserId, personalActive, status])
@@index([tenantId, createdByUserId, originType, personalActive])
```

**Campos inalterados mas relevantes**:

| Campo | Uso pessoal |
|-------|-------------|
| `createdByUserId` | Remetente original (User FK nullable) |
| `senderSectorId` | Setor resolvido do remetente (placeholder NOT NULL) |
| `currentSectorId` | = `senderSectorId` enquanto pessoal ativo; = setor destino após promoção |
| `sourceModule` / `sourceRecordId` / `sourceSnapshot` | Opcional — linked pessoal (US6) |
| `status` | Mesmo enum (`open`, `in_progress`, `archived`, …) |

### TramitacaoDemandaEvento (payload JSON)

Sem novo enum type v1 — estender payload de `forwarded`:

```json
{
  "targetKind": "user",
  "fromUserId": "uuid",
  "toUserId": "uuid",
  "notes": "Transferindo para Maria"
}
```

```json
{
  "targetKind": "sector",
  "fromSectorId": "uuid-remetente-setor",
  "toSectorId": "uuid-destino",
  "notes": "Promover para tratamento formal"
}
```

Eventos `created`, `reply`, `archived` inalterados; admin remetente usa `withActorPayload` no payload quando `createdByUserId` null.

## State Transitions

### Demanda pessoal ativa

```text
[compose personal]
  originType=personal, personalActive=true
  createdByUserId=sender, targetUserId=recipient
  senderSectorId=currentSectorId=sender sector

[reply] ──► status open→in_progress (opcional)

[forward to user] ──► targetUserId=newRecipient
  (intermediário perde acesso)

[archive] ──► status=archived, archivedAt set

[promote to sector] ──► personalActive=false, targetUserId=null
  currentSectorId=targetSector
  ──► passa a regras setoriais (inbox setor Recebidas)
```

### Visibilidade

```text
personalActive=true:
  visible → createdByUserId OR targetUserId OR admin_tenant (audit read-only)
  hidden  → demais users (incl. chefe_setor, colegas de setor)

personalActive=false:
  visible → regras setoriais existentes (buildInboxWhere)
  history   → fase pessoal permanece na timeline
```

## Inbox Filters

### Setorial (`buildInboxWhere` — UPDATE)

Adicionar a `base`:

```text
NOT (originType = personal AND personalActive = true)
```

### Pessoal (`buildPersonalInboxWhere` — NEW)

| folder | where |
|--------|-------|
| `received` | `originType=personal`, `personalActive=true`, `targetUserId=actorUserId`, `status≠archived` |
| `sent` | `originType=personal`, `personalActive=true`, `createdByUserId=actorUserId`, `status≠archived` |
| `archived` | `originType=personal`, `status=archived`, OR participante (createdBy OR target) |

### Auditoria admin (`buildPersonalAuditWhere` — NEW)

```text
originType = personal
(deletedAt null)
+ search q on subject/protocol
```

## Validation Rules

| Regra | Onde |
|-------|------|
| `targetUserId` UUID ativo, ≠ remetente | `CreatePersonalDemandaUseCase` |
| `originType=personal` ⇒ `targetUserId` required while active | schema + use case |
| Reply/archive/forward só participante | `AssertPersonalDemandaAccess` |
| admin_tenant detail read-only | controller flag / use case |
| Promoção setorial irreversível | `PromotePersonalToSectorUseCase` rejeita se `!personalActive` |
| Linked snapshot v2 modules | `CreatePersonalLinkedDemandaUseCase` |
| FK User nullable create | `resolveUserTableId` |

## API DTO Extensions

`TramitacaoDemandaListItem` / `Detail`:

```typescript
{
  originType: 'personal' | 'generic' | 'linked';
  personalActive: boolean;
  targetUser?: { id: string; name: string };
  senderUser?: { id: string; name: string };
  canReply: boolean;      // computed from access
  canPromoteToSector: boolean;
  isReadOnlyAudit: boolean;
}
```

## Notificacao (extensão spec 029)

Novos `sourceType` values:

- `tramitacao_pessoal_nova`
- `tramitacao_pessoal_resposta`
- `tramitacao_pessoal_encaminhada`

`navigationPath`: `/tramitacao/demandas/:id?inboxMode=personal`

## Seed Data (demo — opcional Phase F)

| Entidade | Propósito |
|----------|-----------|
| Demanda pessoal A→B | Quickstart cenário 1 |
| Demanda pessoal linked gabinete | Quickstart cenário 4 |

Inserir em `seed-tramitacao-demo.ts` após operadores Jacaranda conhecidos.

## Relationships

```text
User 1──* TramitacaoDemanda (createdBy)
User 1──* TramitacaoDemanda (targetUser, personal)
TramitacaoDemanda 1──* TramitacaoDemandaEvento
TramitacaoDemanda ──optional──► source record (linked personal)
```

## Out of Scope (data)

- Tabela `TramitacaoDemandaParticipante` (histórico de intermediários — timeline basta)
- `targetAdminTenantId` (follow-up)
- Read receipts por usuário (`readAt`)
- Sincronização status origem ↔ demanda pessoal
