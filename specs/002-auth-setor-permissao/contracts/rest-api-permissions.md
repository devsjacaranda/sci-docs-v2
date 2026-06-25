# Contract: REST API — Permissões por Setor

**Feature**: 002-auth-setor-permissao  
**Version**: 1.0.0  
**Base URL**: `/` (Fastify, prefix global conforme deploy)  
**Auth**: Bearer JWT + header `X-Tenant-ID`

## Headers (all protected routes)

| Header | Required | Description |
|--------|----------|-------------|
| `Authorization` | Yes | `Bearer <accessToken>` |
| `X-Tenant-ID` | Yes | UUID ou slug resolvido pelo middleware |

## Error envelope (403 módulo)

Quando `ModuloPermissaoGuard` nega acesso:

```json
{
  "statusCode": 403,
  "error": "Forbidden",
  "message": "Modulo access denied",
  "details": {
    "code": "MODULO_SETOR_DENIED",
    "moduloSlug": "protocolo",
    "moduloLabel": "Protocolo Virtual",
    "authorizedSetores": [
      { "id": "uuid", "name": "Gabinete", "chiefName": "Maria Oliveira" },
      { "id": "uuid", "name": "Jurídico", "chiefName": "Paulo Ribeiro" }
    ]
  }
}
```

Client MUST mapear `details` para `AccessDenied403`.

---

## Auth (extend existing)

### POST `/auth/login` (Public)

**Body** (Zod `LoginBody`):

```json
{ "email": "user@demo.com", "password": "password123" }
```

**Response 200**:

```json
{
  "accessToken": "<jwt>"
}
```

**JWT payload (extended)**:

```json
{
  "sub": "user-uuid",
  "tenantId": "tenant-uuid",
  "role": "user",
  "setorIds": ["uuid-gab", "uuid-ouv"],
  "chiefOfSetorIds": []
}
```

### GET `/auth/me`

**Response 200**:

```json
{
  "userId": "uuid",
  "tenantId": "uuid",
  "role": "user",
  "email": "user@demo.com",
  "name": "Nome",
  "setorIds": ["uuid"],
  "chiefOfSetorIds": [],
  "isPlatformAdmin": false
}
```

---

## Setores (admin plataforma)

**Guard**: `@Roles(admin_plataforma)` (+ tenant isolation)

### GET `/setores`

Lista setores do tenant com chefe.

**Response 200**:

```json
{
  "items": [
    {
      "id": "uuid",
      "name": "Gabinete",
      "sigla": "GAB",
      "chefeUserId": "uuid",
      "chefeName": "Maria Oliveira",
      "memberCount": 12
    }
  ]
}
```

### POST `/setores`

**Body**:

```json
{ "name": "Gabinete", "sigla": "GAB", "chefeUserId": "uuid?" }
```

### PATCH `/setores/:id`

Atualiza nome, sigla, chefe.

### DELETE `/setores/:id`

Soft delete.

---

## Usuários (admin plataforma)

### GET `/users`

### POST `/users`

**Body**:

```json
{
  "email": "novo@instituicao.gov.br",
  "password": "string",
  "name": "Nome",
  "role": "user",
  "setorIds": ["uuid-gab", "uuid-ouv"]
}
```

**Rules**:

- MUST include ≥1 `setorId` (FR-002).
- Licenças NOT in body — implicit via tenant (FR-015).

### PATCH `/users/:id`

Permite alterar `setorIds`, `role`, `name`.

---

## Vínculos módulo–setor (admin plataforma)

### GET `/permissoes/modulos`

Retorna todos os slugs canônicos com setores autorizados.

**Response 200**:

```json
{
  "items": [
    {
      "moduloSlug": "protocolo",
      "moduloLabel": "Protocolo Virtual",
      "setorIds": ["uuid-gab", "uuid-dejur"],
      "setores": [
        { "id": "uuid-gab", "name": "Gabinete", "chiefName": "Maria Oliveira" }
      ]
    }
  ]
}
```

### PUT `/permissoes/modulos/:moduloSlug`

Substitui lista de setores autorizados.

**Body**:

```json
{ "setorIds": ["uuid-gab", "uuid-dejur"] }
```

**Rules**:

- `moduloSlug` MUST NOT be `global` or `tramitacao` (400).
- Empty `setorIds` ⇒ módulo aberto (FR-003).

---

## Solicitações de permissão

### POST `/permissoes/solicitacoes`

Usuário autenticado solicita acesso (notify-only).

**Body**:

```json
{ "moduloSlug": "protocolo" }
```

**Response 201**:

```json
{
  "solicitacaoId": "uuid",
  "notificacoesCriadas": 2,
  "chefesNotificados": [
    { "setorName": "Gabinete", "chiefName": "Maria Oliveira" },
    { "setorName": "Jurídico", "chiefName": "Paulo Ribeiro" }
  ]
}
```

**Rules**:

- MUST create one `NotificacaoPermissao` per authorized setor of module (FR-007).
- MUST NOT mutate `UserSetor` or `ModuloSetor` (FR-016).
- Idempotent within session window — return 200 with existing if duplicate (edge case).

---

## Notificações (chefe / admin)

### GET `/permissoes/notificacoes`

**Guard**: chefe de ≥1 setor OR `admin_plataforma`.

**Query**: `?unreadOnly=true`

**Response 200**:

```json
{
  "items": [
    {
      "id": "uuid",
      "type": "permission_request",
      "moduloSlug": "protocolo",
      "moduloLabel": "Protocolo Virtual",
      "setorId": "uuid-gab",
      "setorName": "Gabinete",
      "requesterName": "Roberto Alves",
      "requesterEmail": "roberto@...",
      "message": "Roberto Alves solicitou acesso ao módulo Protocolo Virtual.",
      "createdAt": "2026-06-05T12:00:00Z",
      "readAt": null
    }
  ]
}
```

### PATCH `/permissoes/notificacoes/:id/read`

Marca como lida (FR-011).

---

## Membros do setor (chefe)

### GET `/setores/:id/membros`

**Guard**: chefe do setor OR `admin_plataforma`.

**Response 200**: lista usuários com lotação naquele setor.

---

## Module guard usage (controllers)

Rotas de domínio futuras MUST use:

```typescript
@RequireModulo('protocolo')
@Get('...')
```

Pipeline order unchanged: `TenantGuard → JwtAuthGuard → RolesGuard → LicencaGuard → ModuloPermissaoGuard`.
