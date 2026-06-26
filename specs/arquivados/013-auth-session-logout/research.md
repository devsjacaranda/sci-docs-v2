# Research: Auth Session Logout (013)

**Feature**: 013-auth-session-logout · **Date**: 2026-06-24

## R1 — Resolução de `userId` no AuditLog para AdminTenant

**Decision**: Antes de `auditLog.create`, verificar se `ctx.userId` existe na tabela `User` (query `findFirst` por `id` + `tenantId`). Se não existir, persistir `userId: null` e incluir no `payload` JSON os campos `actorId` (JWT `sub`) e `actorRole` (JWT `role`).

**Rationale**: Schema atual já permite `userId` nullable com FK opcional para `User`. Login `AdminTenant` emite `sub: adminTenant.id` ([`auth.service.ts`](../../../ci-api-v2/src/modules/auth/auth.service.ts) L45–51) — ID não existe em `User`, causando P2003 e crash do processo.

**Alternatives considered**:

| Alternativa | Motivo rejeição |
|-------------|-----------------|
| FK `AuditLog` → `AdminTenant` | Migration + relação duplicada; escopo maior que bugfix |
| Criar `User` shadow para AdminTenant | Anti-padrão auth-patterns (tabelas distintas) |
| Omitir audit para AdminTenant | Perda de trilha; spec FR-006 exige operação concluída com audit best-effort |

---

## R2 — Isolamento de falhas de auditoria

**Decision**: `AuditInterceptor` envolve `auditService.log` em `try/catch`; erros logados via Pino (`warn`) sem rethrow. Manter fire-and-forget (`void`) mas com `.catch()` interno no service ou interceptor.

**Rationale**: Rejeição não tratada em `void this.auditService.log(...)` derruba Node (evidência terminal). Spec FR-007.

**Alternatives considered**: Desabilitar audit globalmente — rejeitado; perda de compliance.

---

## R3 — Handler centralizado de sessão perdida no client

**Decision**: Estender `createApiClient` com `registerSessionLostHandler(handler)` e enum de motivo `{ unauthorized, network }`. Handler registrado uma vez em `AuthProvider` via `useEffect`.

**Rationale**: Todas as chamadas passam por `apiFetch`; evita duplicar 401/network em dezenas de módulos. Alinha com admin-saas `isAuthError` mas adiciona ação (logout + navigate).

**Alternatives considered**:

| Alternativa | Motivo rejeição |
|-------------|-----------------|
| React Query global `onError` | Nem todas as páginas usam RQ; gabinete usa fetch direto |
| Interceptor axios | Stack usa `fetch` nativo |
| Logout só em `fetchCurrentUser` | Não cobre mutações subsequentes com token inválido |

---

## R4 — Guard anti-loop em logout paralelo

**Decision**: Flag module-level `sessionLostHandled` resetada após navigate; requisições 401/network subsequentes no mesmo tick ignoram handler duplicado.

**Rationale**: Edge case spec — requisições paralelas com 401 não devem loop de redirect.

**Alternatives considered**: Debounce 500ms — rejeitado; flag síncrona é determinística em testes.

---

## R5 — Semântica `isAuthenticated`

**Decision**: `isAuthenticated = user !== null` após bootstrap; durante bootstrap inicial com token presente, `loading: true` bloqueia render de rotas protegidas até `fetchCurrentUser` resolver ou falhar (logout).

**Rationale**: Spec FR-011 — token sozinho não mantém acesso. `RequireAuth` passa a considerar `loading` do AuthContext.

**Alternatives considered**: Manter `|| Boolean(getAccessToken())` — rejeitado; causa exato do bug reportado.

---

## R6 — Feedback transversal de erros recuperáveis

**Decision**: Introduzir `ToastProvider` + `useApiAction(fn)` em `@ci/web` que: (a) executa async action; (b) em erro não-session (`status !== 401` e não network), chama `showToast(translateError(...))`; (c) sempre captura rejection.

**Rationale**: Spec P2/P3 + FR-008/FR-009; ouvidoria já usa feedback inline local — toast complementa padrão global sem reescrever cada módulo de imediato. Páginas gabinete (repro) migradas primeiro.

**Alternatives considered**: Error Boundary global — não cobre erros async; react-error-boundary não substitui toast.

---

## R7 — Copy de mensagens de sessão

**Decision**:

| Motivo | Copy login |
|--------|------------|
| `unauthorized` | `Sessão expirada. Entre novamente.` |
| `network` | `Não foi possível manter sua sessão. Entre novamente.` |

Passadas via `location.state.sessionMessage` no redirect; `LoginPage` exibe no `LoginForm` (`authError` ou prop dedicada).

**Rationale**: Spec FR-003; distinção stakeholder entre credencial vs comunicação.

**Alternatives considered**: Query string `?reason=expired` — rejeitado; state do router já usado para `from`.

---

## R8 — Distinção 403 vs logout

**Decision**: Apenas `response.status === 401` ou exceção de rede (`TypeError: Failed to fetch`, `NetworkError`) disparam `sessionLost`. Status 403 propaga `ApiError` normalmente — páginas/`AccessDenied403` inalteradas.

**Rationale**: Spec FR-005 e edge case explícito.

**Alternatives considered**: Logout em 403 — rejeitado pelo stakeholder na spec.
