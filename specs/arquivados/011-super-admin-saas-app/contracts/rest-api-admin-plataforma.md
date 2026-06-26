# Contract: REST API — Admin Plataforma (Super Admin SaaS)

**Feature**: 011-super-admin-saas-app  
**Version**: 1.0.0  
**Base URL**: `/` (Fastify, mesmo deploy `ci-api-v2`)  
**Auth**: Bearer JWT — **sem** header `X-Tenant-ID` em rotas `/admin/*`

## Headers

| Header | Rotas | Required | Description |
|--------|-------|----------|-------------|
| `Authorization` | Protegidas | Yes | `Bearer <accessToken>` — role `admin_saas` |
| `X-Tenant-ID` | `/admin/*` | **No** | Não enviar no client admin-saas |

## Error envelope

Padrão NestJS existente. Códigos de negócio em `details.code` quando aplicável:

| code | HTTP | Quando |
|------|------|--------|
| `LAST_ADMIN_ACTIVE` | 409 | Desativar único super admin ativo |
| `TENANT_SLUG_CONFLICT` | 409 | Slug duplicado |
| `ADMIN_EMAIL_CONFLICT` | 409 | E-mail admin duplicado |
| `USER_EMAIL_CONFLICT` | 409 | E-mail user duplicado no tenant |
| `INVALID_TENANT` | 404 | `:tenantId` inexistente |

---

## Auth

### POST `/admin/auth/login` (Public, SkipTenant)

**Body** (`AdminLoginBody`):

```json
{ "email": "saas@ci.com", "password": "password123" }
```

**Response 200**:

```json
{ "accessToken": "<jwt>" }
```

**JWT payload**: `{ sub, role: "admin_saas", tenantId: "platform" }`

**Errors**: 401 credenciais inválidas (mensagem genérica); 401 admin inativo

**Note**: Não autentica users tenant; não usa `X-Tenant-ID`.

---

### GET `/admin/auth/me` (SkipTenant, admin_saas)

**Response 200**:

```json
{
  "userId": "uuid",
  "email": "saas@ci.com",
  "role": "admin_saas",
  "tenantId": "platform",
  "isPlatformAdmin": true
}
```

---

### PATCH `/admin/auth/password` (SkipTenant, admin_saas)

**Body** (`ChangeOwnPasswordBody`):

```json
{ "currentPassword": "old", "newPassword": "newpass123" }
```

**Response 200**: `{ "ok": true }`

**Errors**: 401 senha atual incorreta

---

## Super Admins

### GET `/admin/admins`

**Response 200**:

```json
{
  "items": [
    { "id": "uuid", "email": "saas@ci.com", "active": true, "createdAt": "...", "updatedAt": "..." }
  ]
}
```

---

### POST `/admin/admins`

**Body** (`CreateAdminBody`):

```json
{ "email": "ops@ci.com", "password": "password123" }
```

**Response 201**: admin DTO (sem password)

---

### PATCH `/admin/admins/:id`

**Body** (`UpdateAdminBody`):

```json
{ "email": "ops@ci.com", "active": false }
```

**Response 200**: admin DTO

**Errors**: 409 `LAST_ADMIN_ACTIVE` ao desativar último ativo

---

### POST `/admin/admins/:id/reset-password`

**Body** (`ResetAdminPasswordBody`):

```json
{ "password": "newpass123" }
```

**Response 200**: `{ "ok": true }`

---

## Tenants

### GET `/admin/tenants`

**Response 200**:

```json
{
  "items": [
    { "id": "uuid", "name": "Demo", "slug": "demo", "active": true, "createdAt": "..." }
  ]
}
```

Inclui tenants inativos (indicador `active`).

---

### POST `/admin/tenants`

**Body** (`CreateTenantBody`):

```json
{ "name": "Prefeitura X", "slug": "prefeitura-x", "active": true }
```

**Response 201**: tenant DTO + licenças criadas

**Side-effect**: 4 `TenantLicenca` criadas (`active: true` default)

**Errors**: 409 `TENANT_SLUG_CONFLICT`

---

### GET `/admin/tenants/:tenantId`

**Response 200**:

```json
{
  "id": "uuid",
  "name": "Demo",
  "slug": "demo",
  "active": true,
  "createdAt": "...",
  "updatedAt": "...",
  "licencas": [
    { "licenca": "carvalho", "label": "Carvalho", "active": true },
    { "licenca": "pau_brasil", "label": "Pau-Brasil", "active": true },
    { "licenca": "jatoba", "label": "Jatobá", "active": true },
    { "licenca": "cedro", "label": "Cedro", "active": true }
  ]
}
```

`:tenantId` aceita UUID ou slug.

---

### PATCH `/admin/tenants/:tenantId`

**Body** (`UpdateTenantBody`):

```json
{ "name": "Demo Atualizado", "active": false }
```

**Response 200**: tenant DTO

---

## Licenças (por tenant)

### PATCH `/admin/tenants/:tenantId/licencas/:licencaSlug`

**Path `licencaSlug`**: `carvalho` | `pau-brasil` | `jatoba` | `cedro` (API slug)

**Body** (`ToggleLicencaBody`):

```json
{ "active": false }
```

**Response 200**: licença DTO atualizada

**Effect**: `LicencaGuard` no app tenant reflete na próxima request

---

## Setores (tenant-scoped via path)

> Interceptor ALS define `tenantId` a partir de `:tenantId`.

### GET `/admin/tenants/:tenantId/setores`

**Response 200** — paridade `GET /setores` tenant:

```json
{
  "items": [
    {
      "id": "uuid",
      "name": "Ouvidoria",
      "sigla": "OUV",
      "chefeUserId": "uuid",
      "chefeName": "Maria",
      "memberCount": 3
    }
  ]
}
```

---

### POST `/admin/tenants/:tenantId/setores`

**Body** — paridade `CreateSetorBody`:

```json
{ "name": "Jurídico", "sigla": "JUR", "chefeUserId": "uuid" }
```

---

### PATCH `/admin/tenants/:tenantId/setores/:id`

**Body** — paridade `UpdateSetorBody`

---

### DELETE `/admin/tenants/:tenantId/setores/:id`

Soft delete via Prisma extension.

---

## Usuários (tenant-scoped via path)

### GET `/admin/tenants/:tenantId/users`

**Response 200** — paridade `GET /users`:

```json
{
  "items": [
    {
      "id": "uuid",
      "email": "user@demo.com",
      "name": "User",
      "role": "admin_plataforma",
      "setorIds": ["uuid"],
      "isPlatformAdmin": true
    }
  ]
}
```

---

### POST `/admin/tenants/:tenantId/users`

**Body** — paridade `CreateUserBody`; `role` ∈ `user|chefe_setor|admin_plataforma`

```json
{
  "email": "admin@demo.com",
  "password": "password123",
  "name": "Admin Demo",
  "role": "admin_plataforma",
  "setorIds": ["uuid"]
}
```

---

### PATCH `/admin/tenants/:tenantId/users/:id`

**Body** — paridade `UpdateUserBody`

---

### POST `/admin/tenants/:tenantId/users/:id/reset-password`

**Body**:

```json
{ "password": "newpass123" }
```

---

### DELETE `/admin/tenants/:tenantId/users/:id`

Soft delete (desativar usuário).

---

## Guard stack (admin routes)

```
ThrottlerGuard → TenantGuard (@SkipTenant) → JwtAuthGuard → RolesGuard (admin_saas)
```

LicencaGuard e ModuloPermissaoGuard: pass-through (sem decorators).

Rotas `:tenantId/setores|users` adicionam `AdminTenantContextInterceptor` antes do handler.
