# Data Model: Níveis de Acesso Ouvidoria AGEMAN (403)

## Entidade nova: `OuvidoriaAcessoConcessao`

Representa uma concessão de acesso explícita (FR-004/FR-005), pontual ou geral.

```prisma
enum OuvidoriaAcessoScope {
  manifestacao
  emissor
}

model OuvidoriaAcessoConcessao {
  id              String               @id @default(uuid())
  tenantId        String
  scope           OuvidoriaAcessoScope
  manifestacaoId  String?              // preenchido quando scope = manifestacao
  emissorUserId   String?              // preenchido quando scope = emissor
  granteeUserId   String               // quem recebe o acesso
  grantedByUserId String?              // resolveUserTableId — null quando concedido por admin_tenant/admin_saas
  grantedByRole   UserRole
  createdAt       DateTime             @default(now())
  revokedAt       DateTime?
  revokedByUserId String?
  revokedByRole   UserRole?

  tenant       Tenant        @relation(fields: [tenantId], references: [id])
  manifestacao Manifestacao? @relation(fields: [manifestacaoId], references: [id], onDelete: Cascade)
  emissor      User?         @relation("OuvidoriaAcessoEmissor", fields: [emissorUserId], references: [id])
  grantee      User          @relation("OuvidoriaAcessoGrantee", fields: [granteeUserId], references: [id])
  grantedBy    User?         @relation("OuvidoriaAcessoGrantedBy", fields: [grantedByUserId], references: [id])
  revokedBy    User?         @relation("OuvidoriaAcessoRevokedBy", fields: [revokedByUserId], references: [id])

  @@index([tenantId, manifestacaoId])
  @@index([tenantId, emissorUserId])
  @@index([tenantId, granteeUserId])
}
```

**Regras de integridade (aplicadas em código, não em constraint de banco — ver `research.md` §2)**:
- `scope = manifestacao` ⇒ `manifestacaoId` obrigatório, `emissorUserId` deve ser `null`.
- `scope = emissor` ⇒ `emissorUserId` obrigatório, `manifestacaoId` deve ser `null`.
- Não permitir concessão duplicada ativa (mesmo `scope` + `manifestacaoId`/`emissorUserId` + `granteeUserId` + `revokedAt IS NULL`) — checagem via `exists()` antes de `create()`, retornando `OUVIDORIA_ACCESS_ALREADY_GRANTED` (400) se já existir.
- Não permitir conceder para o próprio emissor (`granteeUserId !== emissorUserId` quando aplicável) — no-op/erro de validação.
- `granteeUserId` deve existir e pertencer ao tenant (`FindUserInTenantRepository`, mesmo padrão de `reset-senha`).

**Enum novo em `ManifestacaoEventoTipo`** (auditoria — ver `research.md` §8):

```prisma
enum ManifestacaoEventoTipo {
  registration
  forwarding
  response
  closure
  note
  access_granted   // NOVO
  access_revoked   // NOVO
}
```

## Entidades existentes afetadas (sem alteração de schema)

- **`Manifestacao`**: `emissorUserId` (já existe) passa a ser o critério de "dono" para visibilidade (FR-001). Nenhum campo novo.
- **`User`**: sem alteração — apenas novas relações reversas (`OuvidoriaAcessoEmissor`, `OuvidoriaAcessoGrantee`, `OuvidoriaAcessoGrantedBy`, `OuvidoriaAcessoRevokedBy`).
- **`ModuloSetor`** / **`Setor`**: consultados (não alterados) para derivar "chefe da ouvidoria" (`FindModuloSetoresRepository.execute('ouvidoria')`).

## Tipos derivados (TypeScript — não persistidos)

```typescript
// lib/assert-manifestacao-access.ts
export type ManifestacaoAccessSubject = {
  id: string;
  emissorUserId: string | null;
};

export type ManifestacaoAccessActor = {
  userId: string;               // ator bruto (User.id, AdminTenant.id ou AdminPlataforma.id)
  userTableId: string | undefined; // resolveUserTableId(userId, role) — undefined para admin sem linha em User
  role: UserRole;
  chiefOfSetorIds: string[];
};

export type AccessReason =
  | 'no-owner'      // FR-002 — demanda sem emissor institucional
  | 'owner'         // FR-001 — é o próprio emissor
  | 'admin'         // FR-003 — bypass admin
  | 'chefe'         // FR-003 — chefe da ouvidoria
  | 'grant-record'  // FR-004
  | 'grant-emissor';// FR-005

export type AccessDecision =
  | { allowed: true; reason: AccessReason }
  | { allowed: false };
```

```typescript
// ouvidoria.schemas.ts — corpo da concessão (discriminated union, zod v4)
export const createOuvidoriaAcessoBodySchema = z.discriminatedUnion('scope', [
  z.object({
    scope: z.literal('manifestacao'),
    manifestacaoId: z.uuid(),
    granteeUserId: z.uuid(),
  }),
  z.object({
    scope: z.literal('emissor'),
    emissorUserId: z.uuid(),
    granteeUserId: z.uuid(),
  }),
]);
export type CreateOuvidoriaAcessoInput = z.infer<typeof createOuvidoriaAcessoBodySchema>;
```

```typescript
// ViewModel de "quem tem acesso" (GET /ouvidoria/manifestacoes/:id/acessos)
export type OuvidoriaAcessoViewModel = {
  emissor: { userId: string; name: string } | null; // null quando FR-002 (sem dono)
  grupoChefeAdminTemAcesso: boolean; // sempre true — apenas informativo
  concessoes: Array<{
    id: string;
    granteeUserId: string;
    granteeName: string;
    scope: 'manifestacao' | 'emissor';
    grantedAt: string; // ISO
  }>;
  efetivos: Array<{
    actorId: string;
    name: string;
    origem: 'admin' | 'chefe' | 'emissor' | 'concedido';
    implicit: boolean;
    revogavel: boolean;
    actorKind: 'user' | 'admin_tenant';
    concessaoId?: string;
    scope?: 'manifestacao' | 'emissor';
  }>;
};
```

## Entidade nova: `OuvidoriaAcessoFeatureFlag`

Controla se toda a restrição de acesso desta feature (FR-001 a FR-009) está em vigor para um tenant (FR-014 a FR-020).

```prisma
model OuvidoriaAcessoFeatureFlag {
  id              String    @id @default(uuid())
  tenantId        String    @unique
  enabled         Boolean   @default(true)
  updatedAt       DateTime  @updatedAt
  updatedByUserId String?   // resolveUserTableId — null quando alterado por admin_tenant/admin_saas
  updatedByRole   UserRole?

  tenant Tenant @relation(fields: [tenantId], references: [id])

  @@index([tenantId])
}
```

**Regra de leitura (ausência de linha = ligado — FR-018)**: se não existir linha para um `tenantId`, o flag é tratado como `enabled = true`. Isso evita qualquer migração/backfill para tenants já existentes no deploy desta feature — eles nascem ligados só por não terem linha. Uma linha só é criada na primeira vez que alguém (admin_saas ou admin_tenant) altera o flag daquele tenant (seja para desligar, seja para religar explicitamente depois de desligar).

**Regra de escrita**: `upsert` por `tenantId` — nunca `delete`, mesmo ao religar (`enabled = true` de novo), para preservar `updatedAt`/`updatedByUserId`/`updatedByRole` como o registro de "última alteração conhecida" (a auditoria completa de todas as alterações, não só a última, fica na tabela `AuditLog` — ver abaixo).

**Auditoria (FR-020)**: cada alteração grava uma linha em `AuditLog` (já existente):

```typescript
{
  tenantId,
  userId: resolveUserTableId(actor.userId, actor.role), // undefined para admin_tenant/admin_saas → grava null
  action: 'ouvidoria_acesso_flag_toggled',
  entity: 'Tenant',
  entityId: tenantId,
  payload: { enabled, actorId: actor.userId, actorRole: actor.role }, // withActorPayload quando userId resolvido é undefined
}
```

## Tipos derivados (flag — TypeScript, não persistidos)

```typescript
// lib/get-ouvidoria-acesso-flag.ts
export type OuvidoriaAcessoFlagState = {
  tenantId: string;
  enabled: boolean; // true quando não há linha em OuvidoriaAcessoFeatureFlag
  updatedAt: string | null;
  updatedBy: { userId: string | undefined; role: UserRole } | null;
};
```

`AccessReason` (ver acima) ganha um novo valor possível para refletir o bypass do flag:

```typescript
export type AccessReason =
  | 'flag-disabled' // NOVO — flag do tenant desligado, acesso liberado independente de dono/chefe/grant
  | 'no-owner'
  | 'owner'
  | 'admin'
  | 'chefe'
  | 'grant-record'
  | 'grant-emissor';
```

## Relacionamentos (visão geral)

```text
Manifestacao (1) ──< OuvidoriaAcessoConcessao (scope=manifestacao) >── User (grantee)
User (emissor) (1) ──< OuvidoriaAcessoConcessao (scope=emissor) >── User (grantee)
Manifestacao.emissorUserId ──> User   (já existente — "dono" para FR-001)
Setor ──< ModuloSetor >── ModuloSlug.ouvidoria   (já existente — deriva "chefe da ouvidoria")
Tenant (1) ──0..1── OuvidoriaAcessoFeatureFlag   (ausência de linha = enabled=true)
```
