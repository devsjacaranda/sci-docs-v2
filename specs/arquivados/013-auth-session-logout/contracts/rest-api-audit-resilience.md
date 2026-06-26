# Contract: REST API Audit Resilience (tenant)

**Feature**: 013-auth-session-logout  
**References**: [spec.md](../spec.md) · [data-model.md](../data-model.md) · auth-patterns skill

## Scope

Mutations tenant autenticadas (POST/PUT/PATCH/DELETE) passando por `AuditInterceptor` global. Endpoints públicos (`@Public()`) sem tenant skip audit — unchanged.

## Actor types (JWT)

| Role | JWT `sub` | Maps to `AuditLog.userId` |
|------|-----------|---------------------------|
| `user`, `chefe_setor`, `admin_plataforma` (legado) | `User.id` | `User.id` (FK valid) |
| `admin_tenant` | `AdminTenant.id` | `null` + payload actor metadata |
| `admin_saas` | N/A on tenant routes | Out of scope (tenant app) |

## AuditService.log contract

### Input (AuditEntry)

| Field | Required | Notes |
|-------|----------|-------|
| `tenantId` | yes | From request context |
| `userId` | no | Resolved server-side — see below |
| `action` | yes | HTTP method |
| `entity` | yes | URL path |
| `entityId` | no | Optional |
| `payload` | no | Request body + optional actor fields |

### Resolution algorithm

```
resolvedUserId = null
if entry.userId:
  user = User.findFirst({ id: entry.userId, tenantId, deletedAt: null })
  if user: resolvedUserId = user.id

payload = merge(entry.payload, {
  actorId: entry.userId,      // JWT sub when userId not resolved
  actorRole: ctx.role,         // from request context
}) when resolvedUserId is null and entry.userId present

auditLog.create({ tenantId, userId: resolvedUserId, action, entity, entityId, payload })
```

### Error handling

- Any Prisma/DB error → catch, log Pino `warn` with `{ tenantId, action, entity }`, **return void** (no throw)
- Caller (interceptor) MUST NOT await in request critical path beyond fire-and-forget with internal catch

## AuditInterceptor contract

- Unchanged: only `MUTATION_METHODS`
- Unchanged: skip when `!ctx.tenantId`
- Changed: `void this.auditService.log(...).catch(() => undefined)` OR service never throws

## HTTP response contract (mutations)

| Scenario | Mutation HTTP | Audit persisted |
|----------|---------------|-----------------|
| User actor, audit OK | 2xx | yes, userId set |
| AdminTenant actor, audit OK | 2xx | yes, userId null + actor in payload |
| Audit DB failure | 2xx | no (logged server-side) |
| Business validation fail | 4xx | no audit (interceptor runs on success tap only) |

## Observability

- Pino warn on audit failure — MUST NOT log JWT, passwords, or full payload with PII
- Include: `tenantId`, `action`, `entity`, `err.code`

## Non-goals

- New REST endpoints for audit
- Schema migration adding `AdminTenant` FK (deferred; payload JSON sufficient for v1 fix)
- Changing JWT payload shape
