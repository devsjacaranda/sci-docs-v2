# Contract: REST API — Gestão Institucional (Usuários e Setores)

**Feature**: 017-gabinete-usuarios-setores-crud  
**Version**: 1.0.0  
**Prefix**: `/users`, `/setores` (tenant-scoped)  
**Guards**: `JwtAuthGuard` + `InstitutionalAdminGuard` — **sem** `@RequireLicenca`  
**Modulo check**: operador `user`/`chefe_setor` deve ter acesso ao módulo `gabinete` via setor; bypass `admin_tenant` | `admin_plataforma`

## Headers

| Header | Obrigatório |
|--------|-------------|
| `Authorization: Bearer <jwt>` | Sim |
| `X-Tenant-ID` | Sim |

---

## GET `/users`

Lista paginada de usuários do tenant.

**Query** (Zod):

| Param | Type | Default | Notes |
|-------|------|---------|-------|
| `page` | int ≥1 | 1 | |
| `limit` | int 1–100 | 20 | |
| `q` | string | — | busca nome/email |
| `status` | enum | `active` | `active` \| `inactive` \| `all` |

**Response 200**:

```json
{
  "items": [
    {
      "id": "uuid",
      "email": "maria@org.gov.br",
      "name": "Maria Oliveira",
      "role": "chefe_setor",
      "roleLabel": "Chefe de setor",
      "setorIds": ["uuid-gab"],
      "setorLabels": [{ "id": "uuid-gab", "sigla": "GAB", "name": "Gabinete" }],
      "status": "active",
      "statusLabel": "Ativo",
      "isChiefOfSetorIds": ["uuid-gab"]
    }
  ],
  "page": 1,
  "limit": 20,
  "total": 42
}
```

---

## POST `/users`

Cria usuário servidor.

**Body**:

```json
{
  "email": "novo@org.gov.br",
  "name": "Novo Servidor",
  "password": "senha-inicial",
  "role": "user",
  "setorIds": ["uuid-gab"]
}
```

**Response 201**: `{ "id": "uuid", "email": "...", "setorIds": [...] }`

**Errors**: 400 validation; 409 email duplicate; 403 guard

---

## PATCH `/users/:id`

Atualiza usuário (sem senha).

**Body** (partial): `{ "name", "email", "role", "setorIds" }`

**Response 200**: `{ "id": "uuid" }`

---

## POST `/users/:id/reset-password`

**Body**: `{ "password": "nova-senha" }`

**Response 200**: `{ "ok": true }`

---

## DELETE `/users/:id`

Inativa usuário (soft delete).

**Response 200**: `{ "ok": true, "status": "inactive" }`

**Errors**: 403 self-inactivate; 403 last admin

---

## POST `/users/:id/restore`

Restaura usuário inativo.

**Response 200**: `{ "ok": true, "status": "active" }`

**Errors**: 409 email conflict

---

## GET `/setores`

Lista paginada de setores.

**Query**: same as `/users` (`page`, `limit`, `q`, `status`)

**Response 200**:

```json
{
  "items": [
    {
      "id": "uuid",
      "sigla": "GAB",
      "name": "Gabinete",
      "chefeUserId": "uuid-user",
      "chefeName": "Maria Oliveira",
      "memberCount": 5,
      "status": "active",
      "statusLabel": "Ativo"
    }
  ],
  "page": 1,
  "limit": 20,
  "total": 8
}
```

---

## POST `/setores`

**Body**: `{ "name": "Gabinete", "sigla": "GAB", "chefeUserId": "uuid?" }`

**Response 201**: setor created

---

## PATCH `/setores/:id`

**Body** (partial): `{ "name", "sigla", "chefeUserId" | null }`

---

## DELETE `/setores/:id`

Inativa setor (soft delete).

**Response 200**: `{ "ok": true, "status": "inactive" }`

---

## POST `/setores/:id/restore`

**Response 200**: `{ "ok": true, "status": "active" }`

---

## GET `/setores/:id/membros`

**Unchanged** — chefia ou admin; lista membros ativos do setor.

---

## Error envelope (padrão AllExceptionsFilter)

```json
{
  "statusCode": 403,
  "message": "Not authorized for institutional admin",
  "error": "Forbidden"
}
```

Login bloqueado (usuário inativo): `401` com message institucional *Acesso desabilitado. Contacte o gestor do Gabinete.*

---

## Auth matrix

| Role | GET/POST/PATCH/DELETE users/setores |
|------|-------------------------------------|
| `user` / `chefe_setor` com módulo gabinete | ✅ |
| `user` / `chefe_setor` sem módulo gabinete | ❌ 403 |
| `admin_tenant` | ✅ |
| `admin_plataforma` | ✅ |
| `admin_saas` | ❌ (tenant app only) |
