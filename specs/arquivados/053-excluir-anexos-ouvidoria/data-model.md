# Data Model — 053 Excluir Anexos de Manifestação

## Alterações no schema Prisma

### `ManifestacaoAnexo` (`prisma/schema/manifestacao.prisma`)

| Campo | Tipo | Nulo | Descrição |
|---|---|---|---|
| `deletedAt` | `DateTime?` | sim | Momento da exclusão. `NULL` = anexo ativo |
| `deletedByUserId` | `String?` | sim | FK → `User.id` (`onDelete: SetNull`). Somente quando o autor é linha de `User` |
| `deletedByActorId` | `String?` | sim | Id do autor quando **não** é linha de `User` (`AdminTenant.id` / `AdminPlataforma.id`) |
| `deletedByActorRole` | `UserRole?` | sim | Papel do autor (`admin_tenant` / `admin_saas`) quando não há FK |

Regras:

- Relações para `User` ficam **nomeadas**: `uploadedBy` → `"ManifestacaoAnexoUploadedBy"`, novo `deletedBy` → `"ManifestacaoAnexoDeletedBy"`; em `User`: `manifestacaoAnexos` (upload) e `manifestacaoAnexosExcluidos` (exclusão). Renomear a relação existente não altera o banco.
- `@@index([manifestacaoId, deletedAt])` para a leitura de anexos ativos por manifestação.
- Sem `@@unique` em `storageKey` (chaves podem repetir em dados legados — ver R8).

### Invariante em SQL (fora do Prisma)

```sql
ALTER TABLE "ManifestacaoAnexo"
  ADD CONSTRAINT "ManifestacaoAnexo_tombstone_sem_conteudo"
  CHECK ("deletedAt" IS NULL OR ("storageKey" IS NULL AND "externalUrl" IS NULL));
```

### Enum `ManifestacaoEventoTipo`

Novo valor: `attachment_deleted` (migration separada, padrão `20260924160000_manifestacao_closed_meio_juridico`).

### Migrations

1. `20261008120000_manifestacao_anexo_tombstone` — colunas, FK `deletedByUserId` (`ON DELETE SET NULL`), índice, `CHECK`.
2. `20261008120100_manifestacao_evento_attachment_deleted` — `ALTER TYPE "ManifestacaoEventoTipo" ADD VALUE 'attachment_deleted';`

Compatibilidade: colunas nulas ⇒ linhas existentes continuam ativas; sem backfill; migração reversível manualmente (drop das colunas/constraint) enquanto nenhum anexo tiver sido excluído.

## Estados do anexo

```text
ATIVO (deletedAt NULL)
  ├─ storageKey/externalUrl preenchidos; uploadConfirmed true|false
  └─ DELETE (autorizado, manifestação não encerrada)
        │  1. file: apaga objeto + versões no Wasabi  (falhou? permanece ATIVO)
        ▼  2. transação: tombstone + evento
EXCLUÍDO (deletedAt preenchido)
  ├─ storageKey = NULL, externalUrl = NULL
  ├─ mantém fileName, kind, mimeType, sizeBytes, uploadedByUserId, createdAt
  └─ terminal — sem restauração; DELETE repetido ⇒ idempotente
```

## Evento `ManifestacaoEvento` (`attachment_deleted`)

| Campo | Valor |
|---|---|
| `tipo` | `attachment_deleted` |
| `titulo` | `Anexo excluído` (constante; único campo exposto em marcos — nunca contém nome de arquivo) |
| `descricao` | `Arquivo "<fileName>" excluído.` + (` Por <rótulo>.` se autor sem FK) |
| `autorUserId` | `resolveUserTableId(userId, role)` (`undefined` p/ `admin_tenant`/`admin_saas`) |
| `manifestacaoId`, `tenantId` | da manifestação |

Imutável pelo fluxo normal: não existe rota que edite/remova `ManifestacaoEvento`.

## Consultas

| Operação | `where` (obrigatório) |
|---|---|
| Manifestação p/ exclusão | `{ id, tenantId, deletedAt: null }` |
| Anexo (inclui excluídos) | `{ id: anexoId, manifestacaoId, tenantId }` |
| Chave compartilhada | `{ tenantId, storageKey, deletedAt: null, id: { not: anexoId } }` (count) |
| Tombstone | `updateMany({ where: { id, manifestacaoId, tenantId, deletedAt: null }, data: { deletedAt, deletedBy…, storageKey: null, externalUrl: null } })` |
| Leitura de anexos ativos | `include: { anexos: { where: { deletedAt: null } } }` |
| Rótulo de AdminTenant | `{ id, tenantId }` → `name ?? email` |

## DTOs afetados (API)

- `GET /ouvidoria/manifestacoes/:id` e revisão: novo campo `anexosExcluiveis: boolean` (= `canDeleteAnexos(status)`); `anexos[]` **sem** itens excluídos (contrato do item inalterado).
- `DELETE …/anexos/:anexoId`: resposta `{ ok: true, alreadyDeleted: boolean }` (ver [contrato](./contracts/delete-manifestacao-anexo.md)).
