# Contract: Test Strategy — Auth Session Logout

**Feature**: 013-auth-session-logout  
**References**: [plan.md](../plan.md) · constitution II · [client-auth-session.md](./client-auth-session.md) · [rest-api-audit-resilience.md](./rest-api-audit-resilience.md)

## Princípio

TDD RED → GREEN → REFACTOR. API: Jest + Supertest com Prisma mock. Client: Vitest + RTL + MSW 2.

## Scripts

```powershell
cd ci-api-v2
npm test -- audit
npm run test:e2e -- --testPathPattern=audit-resilience

cd ci-client-v2/packages/shared
npm test -- create-api-client

cd ci-client-v2/apps/web
npm run test -- session
npm run test -- auth
npm run typecheck
```

## Matriz mínima — API (audit)

| ID | Camada | Caso |
|----|--------|------|
| CT-AUD-001 | unit | `log()` sets userId when User exists |
| CT-AUD-002 | unit | `log()` sets userId null + actor payload for AdminTenant sub |
| CT-AUD-003 | unit | `log()` swallows Prisma error — no throw |
| CT-AUD-004 | unit | interceptor does not throw when service rejects |
| CT-AUD-005 | e2e | POST mutation as AdminTenant → 2xx + API process alive |
| CT-AUD-006 | e2e | 10 consecutive AdminTenant mutations → all 2xx |

## Matriz mínima — Shared (createApiClient)

| ID | Camada | Caso |
|----|--------|------|
| CT-CLI-001 | unit | 401 invokes handler once with `unauthorized` |
| CT-CLI-002 | unit | fetch throw invokes handler once with `network` |
| CT-CLI-003 | unit | 403 does NOT invoke handler |
| CT-CLI-004 | unit | parallel 401s invoke handler once (guard) |

## Matriz mínima — Web (auth session)

| ID | Camada | Caso |
|----|--------|------|
| CT-WEB-001 | integration | AuthContext: 401 MSW → token cleared, navigate login |
| CT-WEB-002 | integration | AuthContext: network MSW → token cleared + network message |
| CT-WEB-003 | integration | 403 MSW → user stays, no navigate login |
| CT-WEB-004 | e2e UI | LoginPage shows `sessionMessage` from location.state |
| CT-WEB-005 | e2e UI | RequireAuth blocks while loading |
| CT-WEB-006 | component | GabineteControleNumericoPage reload handles MSW 500 with toast, no unhandled |
| CT-WEB-007 | unit | `isAuthenticated` false when token exists but user null post-fail |

## TDD order (implementação)

1. **RED** API unit tests CT-AUD-001..004
2. **GREEN** `AuditService` + interceptor fix
3. **RED** API e2e CT-AUD-005..006
4. **GREEN** verify Supertest with AdminTenant JWT fixture
5. **RED** shared CT-CLI-001..004
6. **GREEN** extend `createApiClient`
7. **RED** web CT-WEB-001..005
8. **GREEN** AuthContext + LoginPage + RequireAuth
9. **RED** CT-WEB-006 + ToastProvider + useApiAction
10. **GREEN** migrate gabinete pages (controle numérico, autos infração priority)
11. Refactor: apply `useApiAction` to remaining pages incrementally (tasks.md)

## Fixtures

### AdminTenant JWT (e2e)

- Seed: `admin@jacaranda.com` from Jacaranda seed
- Login `POST /auth/login` + `X-Tenant-ID: jacaranda`
- Use token for `POST /gabinete/controles-numericos` or similar mutation

### MSW handlers (web)

```typescript
// 401 scenario
http.get('/gabinete/controles-numericos', () =>
  HttpResponse.json({ message: 'Unauthorized' }, { status: 401 }))

// network scenario — omit handler or http.get(..., () => HttpResponse.error())
```

## Regression guard

- Existing auth login UI tests (spec 010) MUST pass
- Mock mode tests MUST pass with `VITE_USE_API=false`
