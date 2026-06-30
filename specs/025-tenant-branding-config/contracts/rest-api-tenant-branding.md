# Contract: REST API — Identidade visual do tenant

**Feature**: 025-tenant-branding-config  
**Version**: 1.0.0  
**Prefix**: `/tenant/branding` (tenant-scoped via ALS + `X-Tenant-ID`)  
**Guards**: `JwtAuthGuard` global; mutações `@Roles(admin_plataforma, admin_tenant)`  
**Licença**: nenhuma — Base

## Headers

| Header | Obrigatório |
|--------|-------------|
| `Authorization: Bearer <jwt>` | Sim |
| `X-Tenant-ID` | Sim |

---

## GET `/tenant/branding`

Retorna identidade visual do tenant atual com URLs de download presignadas.

**Auth**: qualquer usuário autenticado do tenant.

**Response 200**:

```json
{
  "tenantId": "uuid",
  "name": "Prefeitura Municipal de Careiro da Várzea",
  "avatarUrl": "https://storage.../avatar.jpg?...",
  "bannerUrl": "https://storage.../banner.jpg?..."
}
```

- `avatarUrl` / `bannerUrl` omitidos quando não configurados.

**Errors**: 401 unauthenticated; 404 tenant inactive/not found

---

## PATCH `/tenant/branding`

Confirma storage keys após upload ou remove imagens.

**Auth**: `admin_plataforma` | `admin_tenant` only.

**Body** (Zod — campos opcionais):

```json
{
  "avatarStorageKey": "prefix/tenant-id/branding/avatar.jpg",
  "bannerStorageKey": null
}
```

| Field | Type | Notes |
|-------|------|-------|
| `avatarStorageKey` | string \| null | null remove foto |
| `bannerStorageKey` | string \| null | null remove banner |

**Response 200**: mesmo shape de GET `/tenant/branding`.

**Errors**:

| Code | Condição |
|------|----------|
| 400 | key não pertence ao tenant atual |
| 403 | role insuficiente |
| 404 | tenant não encontrado |

---

## POST `/tenant/branding/avatar/presign`

Gera URL de upload para foto institucional.

**Auth**: `admin_plataforma` | `admin_tenant`.

**Body**:

```json
{
  "mimeType": "image/jpeg"
}
```

| mimeType | Extensão key |
|----------|--------------|
| `image/jpeg` | `.jpg` |
| `image/png` | `.png` |

**Response 200**:

```json
{
  "uploadUrl": "https://...",
  "storageKey": "tenant-id/branding/avatar.jpg",
  "expiresIn": 900
}
```

**Errors**: 400 invalid mimeType; 403 forbidden

---

## POST `/tenant/branding/banner/presign`

Idêntico ao avatar presign, com key `{tenantId}/branding/banner.{ext}`.

---

## Upload flow (client)

```text
1. POST presign → uploadUrl + storageKey
2. PUT uploadUrl (Content-Type = mimeType, body = file bytes)
3. PATCH /tenant/branding { avatarStorageKey: storageKey }
4. GET /tenant/branding (ou usar response do PATCH) para URLs de exibição
```

---

## Audit (opcional v1)

Registrar `tenant.branding.update` em audit log com actorId/actorRole no payload — **não bloqueante** (padrão 013).
