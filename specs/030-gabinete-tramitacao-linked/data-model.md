# Data Model: Integrar Gabinete (Atos) à Tramitação — Linked Record

**Feature**: 030-gabinete-tramitacao-linked  
**Date**: 2026-07-01

## Overview

Feature **não adiciona entidades Prisma**. Reutiliza modelos das specs 012 (Gabinete) e 014 (Tramitação). Alterações são comportamentais (validação, snapshot JSON, UI linked record, seed).

## Entities (existentes)

### CabinetDemanda (Ato)

Registro principal do Gabinete do Presidente.

| Campo | Tipo | Notas |
|-------|------|-------|
| `id` | UUID | PK; referenciado em `TramitacaoDemanda.sourceRecordId` |
| `tenantId` | UUID | Multi-tenant |
| `protocolNumber` | String | `GAB-AAAA-NNNN` |
| `subject` | String | Assunto (max 500) |
| `description` | Text | Corpo/descrição |
| `origin` | `CabinetDemandaOrigin` | email, internal, phone, … |
| `status` | `CabinetDemandaStatus` | workflow operacional |
| `sectorId` | UUID? | Setor atual/custódia |
| `forwardings` | JSON | Array histórico encaminhamentos |
| `deletedAt` | DateTime? | Soft delete |

**Status elegíveis para tramitar**: qualquer status **exceto** `draft`, `archived`, `finished`.

**Transição na tramitação**:

```text
{received|in_analysis|in_transit|…} ──forward──► in_transit
  + TramitacaoDemanda linked criada
  + CabinetDemandaEvento type forwarded
```

### CabinetDemandaEvento

| Campo | Notas |
|-------|-------|
| `demandaId` | FK CabinetDemanda |
| `type` | `forwarded` na tramitação |
| `authorUserId` | String? — nullable para admin_tenant |
| `payload` | JSON com `withActorPayload` + sectorId, notes, tramitacao refs |

### TramitacaoDemanda (linked)

| Campo | Valor gabinete |
|-------|----------------|
| `originType` | `linked` |
| `sourceModule` | `'gabinete'` |
| `sourceRecordId` | `CabinetDemanda.id` |
| `sourceSnapshot` | JSON imutável v2 |
| `senderSectorId` | Setor gabinete resolvido |
| `currentSectorId` | Setor destino |
| `subject` | `Tramitação: {cabinet.subject}` |
| `body` | notes ou description preview |

## Snapshot JSON (sourceSnapshot)

**Formato v2** (imutável após criação):

```json
{
  "schemaVersion": 2,
  "protocolNumber": "GAB-2026-0003",
  "subject": "Parecer sobre contrato de concessão",
  "summary": "Parecer sobre contrato de concessão",
  "status": "in_analysis",
  "statusLabel": "Em análise",
  "origin": "internal",
  "originLabel": "Interno",
  "description": "Descrição demo do ato…",
  "capturedAt": "2026-07-01T12:00:00.000Z"
}
```

**Compatibilidade v1** (demandas antigas / stub): campos `protocolNumber`, `subject`, `status`, `description` sem labels — client hidrata via GET ou exibe via `mergeGenericSnapshotFields`.

## Validation Rules

| Regra | Onde |
|-------|------|
| Tramitar só se status ∉ {draft, archived, finished} | `ForwardCabinetUseCase` |
| `sectorId` destino UUID válido | `forwardCabinetBodySchema` |
| `notes` min 1 char | `forwardCabinetBodySchema` |
| Setor origem ≠ setor destino | `ForwardCabinetUseCase` (SAME_SECTOR) |
| Setor origem resolvido | `ResolveGabineteSenderSectorUseCase` |
| FK User nullable em eventos | `resolveUserTableId` + `withActorPayload` |
| Soft delete excluído de GET detail | Prisma extension |

## Seed Data (demo)

| Entidade | ID fixo | Propósito |
|----------|---------|-----------|
| CabinetDemanda linked | `00000000-0000-4000-8000-000000000077` | "Abrir origem" quickstart |
| TramitacaoDemanda linked | criada em seed-tramitacao | `sourceRecordId` = ID acima |

Protocolo demo esperado: `GAB-2026-0001` (primeiro ato seed Jacaranda).

## Relationships

```text
CabinetDemanda 1──* CabinetDemandaEvento
CabinetDemanda 1──* CabinetProtocolo / Controles (opcional, não duplicados na demanda)
CabinetDemanda 1──* TramitacaoDemanda (via sourceRecordId, lógico)
```

## Out of Scope (data)

- Sincronização status ato ↔ demanda
- Tabela junction explícita Gabinete-Tramitação
- Alteração enums Prisma
- Duplicar controles vinculados no snapshot
