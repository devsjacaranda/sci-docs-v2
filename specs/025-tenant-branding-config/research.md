# Research: Identidade visual do tenant

**Feature**: 025-tenant-branding-config · **Date**: 2026-06-29

## R1 — Onde persistir foto e banner

**Decision**: Campos nullable `avatarStorageKey` e `bannerStorageKey` no model Prisma `Tenant`.

**Rationale**: Relação 1:1 com a instituição; sem entidade extra; alinhado a `User.avatarStorageKey`; leitura simples para boas-vindas global.

**Alternatives considered**:

| Alternativa | Rejeitada porque |
|-------------|------------------|
| Tabela `TenantBranding` separada | Over-engineering para dois campos opcionais |
| JSON `metadata` genérico em Tenant | Menos tipado; pior para queries e contratos |
| URLs públicas fixas no banco | Presign expiring URLs já são padrão do projeto |

---

## R2 — Padrão de upload

**Decision**: Presign S3/Wasabi idêntico ao avatar pessoal (`auth.service.presignAvatarUpload`).

**Fluxo**:

1. `POST /tenant/branding/avatar/presign` ou `.../banner/presign` → `{ uploadUrl, storageKey, expiresIn }`
2. Client `PUT` binário para `uploadUrl`
3. `PATCH /tenant/branding` com `{ avatarStorageKey }` ou `{ bannerStorageKey }`
4. Remoção: `PATCH` com `avatarStorageKey: null` ou `bannerStorageKey: null`

**Rationale**: Infraestrutura `StorageService` madura; testes stub mode; isolamento por `buildStorageKey(tenantId, 'branding', ...)`.

**Alternatives considered**:

| Alternativa | Rejeitada porque |
|-------------|------------------|
| Multipart direto no Nest | Não é padrão atual; aumenta carga API |
| Base64 no PATCH | Limite de payload; anti-pattern para 10 MB banner |

---

## R3 — Autorização API

**Decision**:

| Operação | Guard |
|----------|-------|
| `GET /tenant/branding` | JWT autenticado (qualquer role do tenant) |
| `PATCH /tenant/branding` | `@Roles(UserRole.admin_plataforma, UserRole.admin_tenant)` |
| `POST .../presign` | `@Roles(UserRole.admin_plataforma, UserRole.admin_tenant)` |

**Rationale**: Espelha `isPlatformAdmin` no client (`admin_plataforma`, `admin_tenant`, legado); FR-011 da spec.

**Alternatives considered**:

| Alternativa | Rejeitada porque |
|-------------|------------------|
| `InstitutionalAdminGuard` (Gabinete) | Escopo errado — chefia de setor não edita identidade |
| Apenas `admin_plataforma` | Exclui `AdminTenant`, principal admin institucional |
| Endpoint público sem auth | Viola isolamento multi-tenant |

---

## R4 — Limpeza de objeto antigo

**Decision**: Ao substituir ou remover, chamar `storage.deleteObject(oldKey)` em best-effort (try/catch + log Pino); falha de delete não bloqueia PATCH.

**Rationale**: Evita lixo no bucket; padrão tolerante a falha semelhante a audit fire-and-forget.

**Alternatives considered**:

| Alternativa | Rejeitada porque |
|-------------|------------------|
| Nunca deletar | Acúmulo de objetos órfãos |
| Delete síncrono obrigatório | PATCH falharia por problema transitório S3 |

---

## R5 — Módulo e rotas client

**Decision**:

- Screen id: `admin-plataforma-config`
- Path: `/administracao/plataforma/config`
- Title UI: **Configurações da instituição**
- Nav: grupo **Administrador Plataforma**, após Usuários
- `customDashboard`: `platform-tenant-config`
- Hook compartilhado `useTenantBranding` para painel config + `GlobalWelcomeDashboard`

**Rationale**: Rota pedida pelo stakeholder; separação clara de **Meu perfil**; reuso de dados sem duplicar fetch.

**Alternatives considered**:

| Alternativa | Rejeitada porque |
|-------------|------------------|
| Mesma tela de Meu perfil | Spec distingue instituição vs usuário |
| Módulo `shell/` only | Constitution V — domínio espelha API em `modules/tenant/` |

---

## R6 — Fallback visual (client)

**Decision**:

- Sem foto: círculo com iniciais do `tenant.name` (mesma função `initials()` de perfil)
- Sem banner: gradiente neutro Mint (sem `background-image` quebrada)
- Nome institucional sempre visível a partir de `GET /tenant/branding`

**Rationale**: FR spec + SC-002; evita regressão de layout em tenants novos.

---

## R7 — Validação MIME e tamanho

**Decision**: Client valida antes do presign (JPEG/PNG; 5 MB / 10 MB). API valida MIME no presign body (`image/jpeg` | `image/png`); rejeita outros com 400.

**Rationale**: Dupla camada — UX imediata no client, segurança no server.
