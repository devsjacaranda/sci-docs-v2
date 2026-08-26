# Data Model: Documentos confidenciais na Tramitação

**Feature**: 033-tramitacao-docs-confidenciais  
**Date**: 2026-07-03

## Overview

Estende `TramitacaoDemandaAnexo` para suportar upload confirmado (Wasabi), autor do anexo e confidencialidade por documento. Nova entidade `TramitacaoDemandaAnexoAccess` materializa ACL (setor + usuário). Anexos vinculados a `eventoId` para exibição na timeline.

## Schema Changes (Prisma)

### TramitacaoDemandaAnexo (alterações)

| Campo | Tipo | Notas |
|-------|------|-------|
| `uploadConfirmed` | `Boolean` | `@default(false)` — só listar após confirm |
| `uploadedByUserId` | `String?` | FK `User` nullable (admin_tenant) |
| `isConfidential` | `Boolean` | `@default(false)` |

Campos existentes reutilizados: `demandaId`, `eventoId`, `kind` (`file` \| `link`), `fileName`, `mimeType`, `sizeBytes`, `storageKey`, `url`, `title`, `attachedAt`, `deletedAt`.

Índice novo:

```prisma
@@index([demandaId, eventoId])
@@index([demandaId, uploadConfirmed])
```

### TramitacaoDemandaAnexoAccess (NOVO)

| Campo | Tipo | Notas |
|-------|------|-------|
| `id` | `String` | PK uuid |
| `tenantId` | `String` | FK Tenant |
| `anexoId` | `String` | FK `TramitacaoDemandaAnexo` ON DELETE CASCADE |
| `userId` | `String` | FK `User` — usuário autorizado |
| `sectorId` | `String` | FK `Setor` — setor pelo qual foi autorizado |
| `createdAt` | `DateTime` | |

```prisma
@@unique([anexoId, userId])
@@index([anexoId])
@@index([userId])
```

Relações em `TramitacaoDemandaAnexo`:

```prisma
accessGrants TramitacaoDemandaAnexoAccess[]
uploadedBy     User? @relation(...)
```

## ACL Evaluation (runtime)

Ordem de decisão para `resolveAnexoAccessLevel(actor, anexo)`:

```text
1. anexo.uploadConfirmed = false        → omitir da lista pública
2. anexo.isConfidential = false         → full (quem acessa demanda)
3. actor.role = admin_tenant            → full (auditoria)
4. actor.userId = anexo.uploadedByUserId → full (autor)
5. exists Access(anexoId, actor.userId)  → full
6. else                                   → placeholder
```

**Nota**: Usuário inativo perde acesso — validar `User.ativo` (ou equivalente) no check; grants órfãos permanecem mas não concedem acesso.

## State Transitions

### Anexo arquivo (file)

```text
[presign]
  uploadConfirmed=false, storageKey set, eventoId opcional
  uploadedByUserId = resolveUserTableId(actor)

[client upload Wasabi]

[confirm + optional ACL]
  uploadConfirmed=true
  isConfidential=true → insert N Access rows (validar user∈sector)
  isConfidential=false → sem Access rows

[soft delete] deletedAt set — omitir listagens
```

### Anexo link (link)

```text
[add-link] uploadConfirmed=true imediato
  url + title; mesma ACL opcional
```

### Encaminhar / promover pessoal→setor

```text
[forward sector] / [promote personal]
  Access rows INALTERADAS
  novos anexos no evento forwarded seguem fluxo próprio
```

## API DTO Shapes (mapper)

### AnexoFull

```json
{
  "id": "uuid",
  "kind": "file",
  "fileName": "parecer.pdf",
  "mimeType": "application/pdf",
  "sizeBytes": 204800,
  "isConfidential": true,
  "accessLevel": "full",
  "attachedAt": "2026-07-03T12:00:00.000Z",
  "eventoId": "uuid"
}
```

### AnexoPlaceholder

```json
{
  "id": "uuid",
  "kind": "file",
  "fileName": "Documento confidencial",
  "isConfidential": true,
  "accessLevel": "placeholder",
  "attachedAt": "2026-07-03T12:00:00.000Z",
  "eventoId": "uuid"
}
```

Timeline estendida: cada evento inclui `anexos: AnexoFull | AnexoPlaceholder[]`.

## Validation Rules

| Regra | Onde |
|-------|------|
| `isConfidential=true` ⇒ `access[]` com ≥1 setor, cada setor ≥1 userId | Zod confirm/add-link |
| Cada `userId` pertence ao `sectorId` e está ativo | Use case confirm |
| Demanda `archived` ⇒ presign/confirm/add-link → 409 | Use cases |
| `MAX_ANEXO_BYTES` 30 MB, MIME allowlist | Presign use case |
| Autor sempre full access | Mapper + download guard |
| Link confidencial: placeholder omite `url` | Mapper |

## Migration Notes

1. `ALTER TramitacaoDemandaAnexo` ADD columns `uploadConfirmed`, `uploadedByUserId`, `isConfidential`
2. CREATE TABLE `TramitacaoDemandaAnexoAccess`
3. Backfill: registros existentes (se houver) → `uploadConfirmed=true`, `isConfidential=false`
4. FK `uploadedByUserId` nullable; `ON DELETE SET NULL`

## Dependencies

- `TramitacaoDemanda`, `TramitacaoDemandaEvento` (014/031)
- `StorageModule` / `StorageService`
- `resolveUserTableId`, `assertPersonalDemandaAccess` (031)
- `fetchSetores`, `fetchUsers` (client setor module)
