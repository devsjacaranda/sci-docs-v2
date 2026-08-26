# Data Model: Integrar Jurídico à Tramitação — Linked Record

**Feature**: 028-juridico-tramitacao-linked  
**Date**: 2026-07-01

## Overview

Feature **não adiciona entidades Prisma**. Reutiliza modelos das specs 012 (Jurídico) e 014 (Tramitação). Alterações são comportamentais (endpoints, snapshot JSON, UI).

## Entities (existentes)

### LegalProcess

Registro principal de processo jurídico.

| Campo | Tipo | Notas |
|-------|------|-------|
| `id` | UUID | PK; referenciado em `TramitacaoDemanda.sourceRecordId` |
| `tenantId` | UUID | Multi-tenant |
| `internalNumber` | String? | `JUR-AAAA-NNNN` após confirm |
| `type` | `LegalProcessType` | administrative, judicial, advisory |
| `subject` | String? | Assunto (max 500) |
| `status` | `LegalProcessStatus` | draft → open/expiring/critical/completed |
| `deadlineAt` | DateTime? | Prazo processual |
| `confirmedAt` | DateTime? | null = rascunho |
| `deletedAt` | DateTime? | Soft delete |

**Status operacional (derivado)**: `deriveOperationalStatus(storedStatus, deadlineAt, confirmedAt)` — expõe `expiring`/`critical` na lista mesmo com `status=open` armazenado.

**Transições relevantes**:

```text
draft ──confirm──► open ──(deadline)──► expiring / critical
open ──complete──► completed
draft ──tramitar──► BLOCKED (400)
open|expiring|critical ──tramitar──► demanda linked + event forwarding
```

### LegalProcessParty

| Campo | Notas |
|-------|-------|
| `processId` | FK LegalProcess |
| `role` | active, passive, other |
| `name` | Usado em `partesResumo` e snapshot |
| `sortOrder` | Ordenação exibição |

### LegalProcessEvent

| Campo | Notas |
|-------|-------|
| `type` | registration, forwarding, opinion, … |
| `title`, `description` | Timeline detalhe |
| `authorUserId` | Autor evento tramitar |

**Novo evento na tramitação**: `type: forwarding`, `title: 'Tramitação inter-setorial'`.

### LegalProcessAttachment

Anexos confirmados no detalhe; presign download (fora escopo alteração schema).

### TramitacaoDemanda (linked)

| Campo | Valor jurídico |
|-------|----------------|
| `originType` | `linked` |
| `sourceModule` | `'juridico'` |
| `sourceRecordId` | `LegalProcess.id` |
| `sourceSnapshot` | JSON imutável v2 (ver abaixo) |
| `senderSectorId` | Setor jurídico resolvido |
| `currentSectorId` | Setor destino |
| `deadline` | Opcional — copiado de `LegalProcess.deadlineAt` |

## Snapshot JSON (sourceSnapshot)

**Formato v2** (imutável após criação):

```json
{
  "schemaVersion": 2,
  "protocolNumber": "JUR-2026-0047",
  "processType": "judicial",
  "typeLabel": "Judicial",
  "status": "open",
  "statusLabel": "Aberto",
  "summary": "Aditivo contratual — Fornecedor X",
  "partiesSummary": "Instituição; Fornecedor X",
  "capturedAt": "2026-07-01T12:00:00.000Z"
}
```

**Compatibilidade v1** (demandas antigas): campos `processType`, `status`, `subject`, `partiesSummary` sem labels — client hidrata via GET ou exibe via `mergeGenericSnapshotFields`.

## Validation Rules

| Regra | Onde |
|-------|------|
| Tramitar só se `status !== draft` | `TramitarProcessoUseCase` |
| `destinoSetorId` UUID válido | `tramitarProcessoBodySchema` |
| `observacao` min 1 char | `tramitarProcessoBodySchema` |
| Lista exclui soft-deleted | `where: { deletedAt: null }` |
| Detalhe 404 outro tenant | tenant extension Prisma |
| Setor origem resolvido | `ResolveTramitacaoSectorUseCase` |

## Seed Data (demo)

| Entidade | ID fixo | Propósito |
|----------|---------|-----------|
| LegalProcess linked | `00000000-0000-4000-8000-000000000088` | "Abrir origem" quickstart |
| TramitacaoDemanda linked | criada em seed-tramitacao | `sourceRecordId` = ID acima |

Processos adicionais (sem ID fixo): 1–2 registros para popular lista.

## Relationships

```text
LegalProcess 1──* LegalProcessParty
LegalProcess 1──* LegalProcessEvent
LegalProcess 1──* LegalProcessAttachment
LegalProcess 1──* TramitacaoDemanda (via sourceRecordId, lógico)
```

## Out of Scope (data)

- Sincronização status processo ↔ demanda
- Tabela junction explícita Jurídico-Tramitação
- Alteração enums Prisma
