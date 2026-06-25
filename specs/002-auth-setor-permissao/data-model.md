# Data Model: Autenticação e Permissão por Setor

**Feature**: 002-auth-setor-permissao  
**Date**: 2026-06-05

> Modelo de persistência PostgreSQL via Prisma 7. Soft delete via extensions existentes onde aplicável.

## Entity: Setor

Unidade organizacional do tenant.

| Field | Type | Description | Validation |
|-------|------|-------------|------------|
| `id` | UUID | PK | `@default(uuid())` |
| `tenantId` | UUID | FK Tenant | Obrigatório; index |
| `name` | string | Nome exibível (ex.: Jurídico) | Não vazio; único por tenant (recomendado) |
| `sigla` | string? | Sigla opcional (ex.: DEJUR) | Max 10 chars |
| `chefeUserId` | UUID? | FK User — líder do setor | Nullable; mesmo tenant |
| `deletedAt` | datetime? | Soft delete | Extension Prisma |
| `createdAt` | datetime | Auditoria | Auto |
| `updatedAt` | datetime | Auditoria | Auto |

**Relationships**:

- `tenant` → Tenant (N:1)
- `chefe` → User? (N:1)
- `userSetores` → UserSetor[] (lotação)
- `moduloSetores` → ModuloSetor[] (autorização de módulo)

**Business rules (FR-001)**:

- Setor inativo (`deletedAt` set) não concede acesso a módulos restritos.
- Chefe opcional; solicitações ainda registradas se ausente.

---

## Entity: User (extensão)

Usuário autenticado do tenant (existente, estendido).

| Field | Type | Description | Validation |
|-------|------|-------------|------------|
| `id` | UUID | PK | Existente |
| `tenantId` | UUID | FK Tenant | Existente |
| `email` | string | Login | Unique `[tenantId, email]` |
| `passwordHash` | string | Credencial | Existente |
| `role` | UserRole | Hierarquia | `user` \| `chefe_setor` \| `admin_plataforma` |
| `deletedAt` | datetime? | Soft delete | Existente |

**Removed**: `setorId` (substituído por `UserSetor`).

**Relationships**:

- `userSetores` → UserSetor[] (lotação — FR-002)
- `setoresComoChefe` → Setor[] (via `Setor.chefeUserId`)

**Business rules**:

- Usuário MUST ter ≥1 setor ativo de lotação (FR-002).
- `admin_plataforma` bypassa restrição de módulo (FR-008).
- Licenças: implícitas via tenant (FR-015) — sem entidade `UserLicenca`.

---

## Entity: UserSetor

Junção lotação usuário ↔ setor (N:N).

| Field | Type | Description | Validation |
|-------|------|-------------|------------|
| `userId` | UUID | FK User | PK composta |
| `setorId` | UUID | FK Setor | PK composta |
| `createdAt` | datetime | Auditoria | Auto |

**Validation rules**:

- `user.tenantId` MUST equal `setor.tenantId`.
- Unique `[userId, setorId]`.

---

## Entity: ModuloSetor

Vínculo módulo de negócio ↔ setor autorizado.

| Field | Type | Description | Validation |
|-------|------|-------------|------------|
| `id` | UUID | PK | `@default(uuid())` |
| `tenantId` | UUID | FK Tenant | Obrigatório |
| `moduloSlug` | ModuloSlug | Identificador canônico | Enum |
| `setorId` | UUID | FK Setor | Obrigatório |
| `createdAt` | datetime | Auditoria | Auto |

**Unique**: `[tenantId, moduloSlug, setorId]`

**Business rules (FR-003)**:

- Zero registros para `(tenantId, moduloSlug)` ⇒ módulo **aberto**.
- Módulos `global` e `tramitacao` MUST NOT ter vínculos (FR-009) — enforced na aplicação.

### Enum: ModuloSlug

```
global | ouvidoria | juridico | protocolo | patrimonio | gabinete | compras | contratos | tramitacao | administracao
```

> Slugs alinhados a `ci-api-v2/CONTEXT.md` + `tramitacao` + `administracao`.

---

## Entity: SolicitacaoPermissao

Pedido notify-only de acesso a módulo (FR-007, FR-016).

| Field | Type | Description | Validation |
|-------|------|-------------|------------|
| `id` | UUID | PK | `@default(uuid())` |
| `tenantId` | UUID | FK Tenant | Obrigatório |
| `requesterUserId` | UUID | FK User solicitante | Obrigatório |
| `moduloSlug` | ModuloSlug | Módulo alvo | Obrigatório |
| `createdAt` | datetime | Timestamp | Auto |

**State**: `enviada` (único estado v1; sem aprovação in-app).

**Deduplicação**: índice ou check `(requesterUserId, moduloSlug, createdAt > now()-session)` para edge case spec.

---

## Entity: NotificacaoPermissao

Alerta para chefe de setor (FR-007, FR-011).

| Field | Type | Description | Validation |
|-------|------|-------------|------------|
| `id` | UUID | PK | `@default(uuid())` |
| `tenantId` | UUID | FK Tenant | Obrigatório |
| `solicitacaoId` | UUID | FK SolicitacaoPermissao | Obrigatório |
| `setorId` | UUID | FK Setor notificado | Obrigatório |
| `chiefUserId` | UUID? | FK User chefe destinatário | Nullable se setor sem chefe |
| `readAt` | datetime? | Leitura | Null = não lida |
| `createdAt` | datetime | Auditoria | Auto |

**Business rules**:

- Uma solicitação para módulo com N setores gera **N** notificações (uma por setor vinculado).
- Chefe só consulta notificações onde `setorId IN chiefOfSetorIds` (FR-011).

---

## Access evaluation (runtime, não persistido)

Função lógica `canAccessModulo(user, moduloSlug)`:

```text
IF user.role IN (admin_plataforma, admin_saas) → ALLOW
IF moduloSlug IN (global, tramitacao) → ALLOW
IF count(ModuloSetor WHERE tenant AND moduloSlug) = 0 → ALLOW
IF exists intersection(user.setorIds, modulo.authorizedSetorIds) → ALLOW
ELSE → DENY (403 payload)
```

---

## State transitions

### SolicitacaoPermissao

```text
[none] --(user clicks Pedir permissão)--> [enviada + N NotificacaoPermissao]
```

Sem transição para `aprovada`/`rejeitada` in-app (fora de escopo).

### NotificacaoPermissao

```text
[unread] --(chefe abre)--> [read]
```

---

## Seed demo (referência)

Expandir `ci-api-v2/prisma/seed.ts`:

- Setores: Gabinete, Jurídico, Ouvidoria, etc. (espelhar mock)
- Users com múltiplos `UserSetor`
- `ModuloSetor`: protocolo → [gabinete, juridico]
- Chefes designados em `Setor.chefeUserId`
