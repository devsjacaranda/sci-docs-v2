# Data Model: Corrigir tramitação Ouvidoria

**Feature**: 027-fix-ouvidoria-tramitar  
**Date**: 2026-07-01

> **Sem migration Prisma.** Bugfix de resolução de setor de origem; entidades existentes da spec 003 permanecem inalteradas.

## Entidades envolvidas (somente leitura/escrita existente)

### Manifestacao

| Campo | Tipo | Notas |
|-------|------|-------|
| `id` | UUID | PK |
| `status` | `ManifestacaoStatus` | Transição `in_review`/`forwarding` → `forwarding` no encaminhar |
| `subject` | string | Usado no assunto da demanda vinculada |
| `protocol` | string | Snapshot Tramitação |

**Transições relevantes**:

```text
in_review  ──encaminhar──► forwarding
forwarding ──encaminhar──► forwarding  (re-encaminhamento permitido)
draft      ──encaminhar──► ✗ 409 INVALID_STATUS_TRANSITION
closed     ──encaminhar──► ✗ 409 INVALID_STATUS_TRANSITION
```

### ManifestacaoEvento

| Campo | Tipo | Notas |
|-------|------|-------|
| `tipo` | `forwarding` | Evento de encaminhamento |
| `destinoSetorId` | UUID | Setor selecionado no modal |
| `descricao` | string | Observação informada |
| `autorUserId` | UUID | Usuário autenticado |

### Setor

| Campo | Tipo | Notas |
|-------|------|-------|
| `id` | UUID | Origem (resolvido) e destino (informado) |
| `sigla` | string | Ordenação em fallbacks |
| `deletedAt` | DateTime? | Setores soft-deleted ignorados |

### ModuloSetor

| Campo | Tipo | Notas |
|-------|------|-------|
| `moduloSlug` | `ModuloSlug` | Fallback: `ouvidoria` (esta feature) ou `tramitacao` (default) |
| `setorId` | UUID | Setor vinculado ao módulo |
| `tenantId` | UUID | Escopo tenant |

### UserSetor / Setor.chefeUserId

| Relação | Uso na resolução |
|---------|------------------|
| `UserSetor` | Setores vinculados ao usuário (JWT + refresh DB) |
| `Setor.chefeUserId` | Setores onde usuário é chefe |

### TramitacaoDemanda (criada via linked record)

| Campo | Tipo | Notas |
|-------|------|-------|
| `senderSectorId` | UUID | **Setor de origem resolvido** (campo corrigido) |
| `targetSectorId` | UUID | `destinoSetorId` do body |
| `sourceModule` | `'ouvidoria'` | Invariante |
| `sourceRecordId` | UUID | ID da manifestação |
| `protocolNumber` | string | Retornado ao client |

## Resolução de setor de origem (lógica de negócio)

Ordem de prioridade (implementação em `ResolveTramitacaoSectorUseCase` estendido):

```text
1. explicitSectorId (query/body — não usado em encaminhar ouvidoria v1)
2. user.setorIds[0] do JWT — ou, se preferredModuloSlug:
     primeiro setor do usuário vinculado a esse módulo
3. loadUserSetorContext(userId).setorIds — mesma priorização por módulo
4. loadUserSetorContext(userId).chiefOfSetorIds[0]
5. ModuloSetor where moduloSlug = preferredModuloSlug ?? tramitacao
6. primeiro Setor ativo do tenant (orderBy sigla)
7. ✗ ACTIVE_SECTOR_UNDEFINED
```

## Validação de entrada (Zod — inalterada)

`EncaminharBody`:

| Campo | Regra |
|-------|-------|
| `destinoSetorId` | UUID obrigatório |
| `observacao` | string min 1 |

## Invariantes preservados

- Tenant isolation via AsyncLocalStorage — sem `tenantId` manual nos use cases
- Soft delete em `Setor` respeitado em todas as queries de fallback
- `sourceSnapshot` imutável na demanda vinculada (spec 014)
- Permissão módulo ouvidoria inalterada (`@RequireModulo('ouvidoria')`)
