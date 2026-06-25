# Contract: Client Auth Session (@ci/web)

**Feature**: 013-auth-session-logout  
**References**: [spec.md](../spec.md) · [data-model.md](../data-model.md) · [research.md](../research.md)

## Scope

App tenant `@ci/web` + pacote `@ci/shared` (`createApiClient`). **Fora de escopo**: `@ci/admin-saas`.

## Session lost triggers

| Trigger | HTTP / condition | Action |
|---------|------------------|--------|
| Credencial inválida | `response.status === 401` | Logout + redirect `/login` |
| Falha de rede | `fetch` throws (ex.: Failed to fetch) | Logout + redirect `/login` |
| Acesso negado | `response.status === 403` | **No logout** — propagate error |
| Erro de negócio | 400, 404, 409, 429, 5xx | **No logout** — toast/local feedback |

## createApiClient extension

### Config (additive)

```typescript
interface ApiClientConfig {
  tokenKey: string
  apiBase?: string
  tenantId?: string
  // unchanged fields above
}

// New exports
type SessionLostReason = 'unauthorized' | 'network'
function registerSessionLostHandler(handler: (reason: SessionLostReason) => void): void
function clearSessionLostHandler(): void  // for tests
```

### apiFetch behavior

1. Attach headers (`X-Tenant-ID`, `Authorization`) — unchanged
2. On network error → invoke handler(`network`) once → rethrow `ApiError` or wrapped Error
3. On `!response.ok`:
   - If `401` → handler(`unauthorized`) once → throw `ApiError` with status 401
   - Else → throw `ApiError` (no handler)
4. Guard: module flag prevents duplicate handler calls per page lifecycle until navigation

## AuthContext contract

### State

```typescript
interface AuthContextValue {
  user: MockCurrentUser | null
  isAuthenticated: boolean  // true ONLY when user !== null
  loading: boolean          // true during bootstrap with token
  login: (email, password) => Promise<MockCurrentUser | null>
  logout: () => void
}
```

### Bootstrap sequence

1. If no token → `loading=false`, `user=null`
2. If token → `loading=true` → `fetchCurrentUser()` → success: set user; fail: logout + `loading=false`
3. Register `sessionLostHandler` on mount; clear on unmount

### Session lost handler

1. `setAccessToken(null)` + clear mock session key
2. `setUser(null)`
3. `navigate('/login', { replace: true, state: { from: currentPath, sessionMessage } })`

## RequireAuth contract

- While `loading === true` → render loading skeleton (or null spinner)
- When `!loading && !isAuthenticated` → `<Navigate to="/login" state={{ from }} />`
- When authenticated → render children

## LoginPage contract

- Read `location.state.sessionMessage` — display above form (distinct from credential `authError`)
- On successful login → navigate to `from`; session message cleared
- Copy constants in `session-messages.ts`:
  - `SESSION_EXPIRED_MESSAGE = 'Sessão expirada. Entre novamente.'`
  - `SESSION_NETWORK_MESSAGE = 'Não foi possível manter sua sessão. Entre novamente.'`

## useApiAction hook

```typescript
function useApiAction<TArgs extends unknown[], TResult>(
  action: (...args: TArgs) => Promise<TResult>,
  options?: { errorMessage?: string }
): {
  run: (...args: TArgs) => Promise<TResult | undefined>
  loading: boolean
  error: string | null
}
```

- Catches non-session errors → `showToast(options.errorMessage ?? default)`
- Session errors bubble to `apiFetch` handler (no duplicate toast)
- Never leaves unhandled rejection from `run()`

## ToastProvider

- Fixed bottom-right banner, 3s auto-dismiss (mirror admin-saas)
- Mounted in `App.tsx` above `RouterProvider`

## Mock mode (`VITE_USE_API=false`)

- `registerSessionLostHandler` registered but `apiFetch` not used for auth paths
- Existing mock login/logout unchanged
- No regression in demo flows
