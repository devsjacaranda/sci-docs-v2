# API Contracts: Sistema de Permissão de Telas

**Feature**: [spec.md](../spec.md) · **Data model**: [data-model.md](../data-model.md)

Todas as rotas exigem JWT válido (`JwtAuthGuard` global) e tenant resolvido (`TenantGuard`), salvo indicação contrária. `AuthenticatedUser` = `{ userId, role, setorIds, chiefOfSetorIds }` (já populado pelo `JwtStrategy` existente).

## Catálogo de telas

### `GET /screens`

Retorna o catálogo completo de telas conhecidas pela API.

**Auth**: qualquer usuário autenticado.

**Response 200**:

```json
{
  "items": [
    { "id": "admin-membros", "title": "Membros do Setor", "moduloSlug": "administracao", "scope": "chefia" },
    { "id": "ouvidoria-manifestacoes", "title": "Manifestações", "moduloSlug": "ouvidoria" }
  ]
}
```

## Visibilidade por setor

### `GET /setores/:id/telas`

Lista os screenIds cadastrados para o setor. Se vazio, retorna baseline derivada de `ModuloSetor` com `source: "baseline"`.

**Auth**: `@Roles(admin_tenant)` (cobre `admin_tenant`, `admin_plataforma`, `admin_saas` via `hasMinimumRole`).

**Response 200**:

```json
{ "setorId": "uuid", "screenIds": ["ouvidoria-manifestacoes", "global-dashboard"], "source": "explicit" }
```

`source`: `"explicit"` (há linhas em `SetorTela`) ou `"baseline"` (derivado de módulos, nenhuma configuração salva ainda).

### `PUT /setores/:id/telas`

Substitui a lista completa de telas habilitadas do setor.

**Auth**: `@Roles(admin_tenant)`.

**Request body**:

```json
{ "screenIds": ["ouvidoria-manifestacoes", "global-dashboard", "admin-membros"] }
```

**Validação**: cada `screenId` DEVE existir no catálogo (`isScreenId`) → 400 `{ "invalidScreenIds": [...] }` caso contrário.

**Response 200**: mesmo formato de `GET /setores/:id/telas` (`source: "explicit"`).

## Overrides por usuário

### `GET /users/:id/tela-overrides`

**Auth**: `@Roles(admin_tenant)`.

**Response 200**:

```json
{
  "items": [
    { "screenId": "gabinete-demandas", "kind": "deny", "createdAt": "2026-07-01T12:00:00Z" },
    { "screenId": "global-auditoria", "kind": "grant", "createdAt": "2026-07-01T12:05:00Z" }
  ]
}
```

### `PUT /users/:id/tela-overrides`

Substitui a lista completa de overrides do usuário (upsert por `screenId`).

**Auth**: `@Roles(admin_tenant)`.

**Request body**:

```json
{ "overrides": [{ "screenId": "global-auditoria", "kind": "grant" }] }
```

**Validação**:
- `screenId` deve existir no catálogo → 400 se não.
- `kind: "grant"` em tela com `scope: "platform"` → 400 `{ "code": "PLATFORM_SCREEN_NOT_OVERRIDABLE" }` (FR não permite contornar bypass de plataforma).

**Response 200**: mesmo formato de `GET /users/:id/tela-overrides`.

### `GET /users/:id/tela-conflicts`

Retorna divergências pendentes (sem override que as resolva) entre a visibilidade natural do usuário (role/chefia) e o cadastro do(s) setor(es) vinculados.

**Auth**: `@Roles(admin_tenant)`.

**Response 200**:

```json
{
  "items": [
    {
      "screenId": "global-auditoria",
      "kind": "exceeds_sector",
      "userVisible": true,
      "sectorVisible": false
    },
    {
      "screenId": "ouvidoria-relatorios",
      "kind": "below_sector",
      "userVisible": false,
      "sectorVisible": true
    }
  ]
}
```

## Visibilidade efetiva (sidebar)

### `GET /me/screens`

Retorna os screenIds visíveis para o usuário autenticado — usado pelo client para montar a sidebar.

**Auth**: qualquer usuário autenticado (usa o próprio JWT, sem `:id`).

**Response 200**:

```json
{ "screenIds": ["global-dashboard", "ouvidoria-manifestacoes", "admin-membros"] }
```

## CRUD de membros do setor (extensão de `SetorController`)

### `POST /setores/:id/membros`

Vincula um usuário existente ao setor (idempotente — se já vinculado, retorna 200 sem duplicar).

**Auth**: chefe do setor `:id` OU `admin_tenant`/`admin_plataforma` (`assertChefiaOrAdmin`, já existe no controller).

**Request body**: `{ "userId": "uuid" }`

**Response 201**: `{ "setorId": "uuid", "userId": "uuid" }`

### `DELETE /setores/:id/membros/:userId`

Desvincula o usuário do setor (remove `UserSetor`; **não** deleta `User`).

**Auth**: idem acima.

**Response 204**

**Edge case**: se `userId` for o `chefeUserId` do setor → 400 `{ "code": "CANNOT_UNLINK_CHIEF" }` (deve trocar o chefe antes).

### `POST /setores/:id/membros/create-user`

Cria um novo `User` já vinculado ao setor `:id` (delega para `CreateUserUseCase` com `setorIds: [id]` fixo, ignorando qualquer `setorIds` enviado no body).

**Auth**: idem acima.

**Request body**: `{ "email": "...", "password": "...", "name": "...", "role": "user" | "chefe_setor", "cargo"?: "..." }`

**Response 201**: `ApiUser` (mesmo shape de `POST /users` existente).

## Resumo de rotas novas

| Método | Rota | Módulo | Auth |
|--------|------|--------|------|
| GET | `/screens` | `tela-permissao` | qualquer autenticado |
| GET | `/setores/:id/telas` | `tela-permissao` | admin_tenant+ |
| PUT | `/setores/:id/telas` | `tela-permissao` | admin_tenant+ |
| GET | `/users/:id/tela-overrides` | `tela-permissao` | admin_tenant+ |
| PUT | `/users/:id/tela-overrides` | `tela-permissao` | admin_tenant+ |
| GET | `/users/:id/tela-conflicts` | `tela-permissao` | admin_tenant+ |
| GET | `/me/screens` | `tela-permissao` | qualquer autenticado |
| POST | `/setores/:id/membros` | `setor` (extensão) | chefia do setor OU admin_tenant+ |
| DELETE | `/setores/:id/membros/:userId` | `setor` (extensão) | idem |
| POST | `/setores/:id/membros/create-user` | `setor` (extensão) | idem |
