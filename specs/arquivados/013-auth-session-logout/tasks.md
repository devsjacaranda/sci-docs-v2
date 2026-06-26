---
description: "Task list for Auth Session Logout (013-auth-session-logout)"
---

# Tasks: Sessão inválida sem logout e tratamento de erros

**Input**: Design documents from `civ2-docs/specs/013-auth-session-logout/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Tests**: **Obrigatórios** — TDD (constitution II + plan.md + `contracts/test-strategy.md`): unitário, integração (MSW), E2E API (Supertest) e E2E UI (Vitest + RTL). **Sem Postgres de teste dedicado** — Prisma mock na API.

**Organization**: 5 user stories (US1–US5). Caminhos relativos à raiz `ci-v2/`.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Pode executar em paralelo (arquivos diferentes, sem dependências pendentes)
- **[Story]**: User story da spec (US1–US5)

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Constantes, handlers MSW e config de teste shared

- [X] T001 [P] Criar constantes de copy em `ci-client-v2/apps/web/src/modules/auth/lib/session-messages.ts` (`SESSION_EXPIRED_MESSAGE`, `SESSION_NETWORK_MESSAGE`)
- [X] T002 [P] Criar handlers MSW stub 401/403/network em `ci-client-v2/apps/web/src/test/msw/handlers/session-auth.ts` e registrar em `ci-client-v2/apps/web/src/test/msw/handlers.ts`
- [X] T003 [P] Garantir script `test` Vitest em `ci-client-v2/packages/shared/package.json` apontando para `src/**/*.test.ts`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Extensão `createApiClient` com session-lost handler — **bloqueia US1 e US2**

**⚠️ CRITICAL**: Nenhuma user story client (US1/US2/US4/US5) começa antes desta fase

### Tests first (TDD — RED)

- [X] T004 [P] Escrever testes (RED) CT-CLI-001..004 em `ci-client-v2/packages/shared/src/api/create-api-client.test.ts` — 401, network, 403 sem handler, guard paralelo

### Implementation

- [X] T005 Implementar `registerSessionLostHandler`, `clearSessionLostHandler`, `SessionLostReason` e detecção 401/rede com anti-loop em `ci-client-v2/packages/shared/src/api/create-api-client.ts` (GREEN T004)
- [X] T006 Exportar novos tipos/funções em `ci-client-v2/packages/shared/src/index.ts`

**Checkpoint**: `npm test` em `packages/shared` passa CT-CLI-001..004

---

## Phase 3: User Story 3 — Operações tenant não interrompidas por auditoria (Priority: P1)

**Goal**: Mutações AdminTenant concluem sem crash; audit best-effort com `userId` null + metadados de ator

**Independent Test**: VS-001 quickstart — 10× POST `/gabinete/controles-numericos` como `admin@jacaranda.com`; API permanece viva

### Tests for User Story 3 (TDD — RED first)

- [X] T007 [P] [US3] Escrever testes (RED) CT-AUD-001..003 em `ci-api-v2/src/modules/audit/audit.service.spec.ts`
- [X] T008 [P] [US3] Escrever testes (RED) CT-AUD-004 em `ci-api-v2/src/common/interceptors/audit.interceptor.spec.ts`
- [X] T009 [P] [US3] Escrever testes (RED) CT-AUD-005..006 em `ci-api-v2/test/audit-resilience.e2e-spec.ts` — Supertest AdminTenant JWT

### Implementation for User Story 3

- [X] T010 [US3] Implementar resolução `userId` + `actorId`/`actorRole` em payload e swallow de erros em `ci-api-v2/src/modules/audit/audit.service.ts` (GREEN T007)
- [X] T011 [US3] Tornar fire-and-forget seguro (`.catch` ou try/catch) em `ci-api-v2/src/common/interceptors/audit.interceptor.ts` (GREEN T008)
- [X] T012 [US3] Validar GREEN e2e CT-AUD-005..006 em `ci-api-v2/test/audit-resilience.e2e-spec.ts`

**Checkpoint**: Mutação AdminTenant não derruba processo; SC-003 atendido

---

## Phase 4: User Story 1 — Sessão inválida encerra o acesso (Priority: P1) 🎯 MVP client

**Goal**: 401 → logout, redirect `/login`, mensagem **"Sessão expirada. Entre novamente."**, preservar `from`

**Independent Test**: VS-002 quickstart — token inválido → redirect login com mensagem em ≤ 2s

### Tests for User Story 1 (TDD — RED first)

- [X] T013 [P] [US1] Escrever testes (RED) CT-WEB-001 e CT-WEB-004 em `ci-client-v2/apps/web/src/modules/auth/__tests__/session-logout.e2e.test.tsx` — 401 MSW + LoginPage sessionMessage
- [X] T014 [P] [US1] Escrever testes (RED) CT-WEB-007 em `ci-client-v2/apps/web/src/modules/auth/__tests__/auth-context.test.tsx` — `isAuthenticated` false pós-falha

### Implementation for User Story 1

- [X] T015 [US1] Registrar session-lost handler em `ci-client-v2/apps/web/src/modules/auth/context/AuthContext.tsx` — logout, `navigate('/login', { state: { from, sessionMessage } })`, guard USE_API
- [X] T016 [US1] Ajustar bootstrap: `loading`, `isAuthenticated = user !== null` em `ci-client-v2/apps/web/src/modules/auth/context/AuthContext.tsx` (GREEN T014)
- [X] T017 [US1] Exibir `location.state.sessionMessage` no card de login em `ci-client-v2/apps/web/src/modules/auth/pages/LoginPage.tsx` (GREEN T013)
- [X] T018 [US1] Propagar `sessionMessage` opcional para `LoginForm` via `@ci/shared` ou prop local em `ci-client-v2/packages/shared/src/auth/LoginForm.tsx` se necessário
- [X] T019 [US1] Limpar `fetchCurrentUser` catch para não duplicar logout — delegar 401 ao handler central em `ci-client-v2/apps/web/src/modules/auth/api/auth.ts`

**Checkpoint**: 401 desloga e exibe mensagem de sessão expirada; retorno pós-login preserva `from`

---

## Phase 5: User Story 2 — Falha de comunicação encerra a sessão (Priority: P1)

**Goal**: Erro de rede → logout + mensagem **"Não foi possível manter sua sessão. Entre novamente."**

**Independent Test**: VS-003 quickstart — API parada → redirect login com copy de rede

### Tests for User Story 2 (TDD — RED first)

- [X] T020 [P] [US2] Escrever testes (RED) CT-WEB-002 em `ci-client-v2/apps/web/src/modules/auth/__tests__/session-logout.e2e.test.tsx` — MSW network error → network message

### Implementation for User Story 2

- [X] T021 [US2] Mapear `SessionLostReason.network` para `SESSION_NETWORK_MESSAGE` no handler de `ci-client-v2/apps/web/src/modules/auth/context/AuthContext.tsx` (GREEN T020)
- [X] T022 [P] [US2] Estender MSW handler `network` em `ci-client-v2/apps/web/src/test/msw/handlers/session-auth.ts` para rotas gabinete (`/gabinete/controles-numericos`)

**Checkpoint**: Falha de fetch desloga com copy distinta; sem `Uncaught (in promise)` no fluxo auth

---

## Phase 6: User Story 5 — Estado autenticado coerente (Priority: P3)

**Goal**: `RequireAuth` respeita `loading`; token residual não mantém rotas protegidas

**Independent Test**: Recarregar app com token inválido → redirect login antes de render children

### Tests for User Story 5 (TDD — RED first)

- [X] T023 [P] [US5] Escrever testes (RED) CT-WEB-005 em `ci-client-v2/apps/web/src/modules/auth/__tests__/RequireAuth.test.tsx`

### Implementation for User Story 5

- [X] T024 [US5] Consumir `loading` do AuthContext em `ci-client-v2/apps/web/src/modules/auth/components/RequireAuth.tsx` — skeleton/spinner enquanto bootstrap (GREEN T023)
- [X] T025 [US5] Garantir `UserMenu` e shell não exibem usuário quando `user === null` em `ci-client-v2/apps/web/src/modules/shell/components/layout/UserMenu.tsx`

**Checkpoint**: SC-004 — rotas protegidas inacessíveis sem usuário validado

---

## Phase 7: User Story 4 — Erros recuperáveis com feedback padronizado (Priority: P2)

**Goal**: Toast transversal + `useApiAction`; 403/4xx/5xx negócio não deslogam; gabinete sem promises não tratadas

**Independent Test**: VS-004 (403 sem logout) + VS-005 (toast em erro recuperável) + CT-WEB-006

### Tests for User Story 4 (TDD — RED first)

- [X] T026 [P] [US4] Escrever testes (RED) CT-WEB-003 em `ci-client-v2/apps/web/src/modules/auth/__tests__/session-logout.e2e.test.tsx` — 403 não navega login
- [X] T027 [P] [US4] Escrever testes (RED) CT-WEB-006 em `ci-client-v2/apps/web/src/modules/gabinete/__tests__/GabineteControleNumericoPage.test.tsx` — erro 500 + toast, sem unhandled
- [X] T028 [P] [US4] Escrever testes unitários (RED) `useApiAction.test.ts` em `ci-client-v2/apps/web/src/modules/shared/hooks/__tests__/useApiAction.test.ts`

### Implementation for User Story 4

- [X] T029 [P] [US4] Criar `ToastProvider` + `useToast` em `ci-client-v2/apps/web/src/modules/shared/context/ToastContext.tsx` (espelhar admin-saas)
- [X] T030 [US4] Montar `ToastProvider` em `ci-client-v2/apps/web/src/App.tsx`
- [X] T031 [US4] Implementar `useApiAction` em `ci-client-v2/apps/web/src/modules/shared/hooks/useApiAction.ts` — catch, toast, não engole session-lost (GREEN T028)
- [X] T032 [US4] Migrar `reload` e ações em `ci-client-v2/apps/web/src/modules/gabinete/pages/GabineteControleNumericoPage.tsx` para `useApiAction` (GREEN T027)
- [X] T033 [P] [US4] Migrar páginas gabinete prioritárias (autos infração, cadastros) em `ci-client-v2/apps/web/src/modules/gabinete/pages/GabineteAutosInfracaoPage.tsx` e similares com listagem API
- [X] T034 [P] [US4] Adicionar helper `isAuthError` / `isNetworkError` em `ci-client-v2/apps/web/src/modules/auth/api/auth.ts` para uso em hooks e páginas

**Checkpoint**: Erros recuperáveis com toast; 403 mantém sessão; gabinete reproduzido sem crash UI

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Cobertura transversal, regressão e validação manual

- [X] T035 [P] Migrar páginas restantes com `reload()` sem catch para `useApiAction` — ouvidoria insights/fiscalizacao em `ci-client-v2/apps/web/src/modules/ouvidoria/pages/`
- [X] T036 [P] Rodar regressão spec 010 — `ci-client-v2/apps/web/src/modules/auth/__tests__/LoginPage.e2e.test.tsx` e `auth-login-ui.contract.test.tsx`
- [X] T037 [P] Rodar regressão mock mode `VITE_USE_API=false` — ajustar testes se necessário em `ci-client-v2/apps/web/src/modules/auth/__tests__/`
- [X] T038 Executar quickstart VS-001..VS-007 em `civ2-docs/specs/013-auth-session-logout/quickstart.md` e documentar desvios em PR
- [X] T039 [P] Rodar suíte completa: `npm test -- audit` (api), `npm test` (shared), `npm run test -- session` (web), `npm run typecheck` (web)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Sem dependências — iniciar imediatamente
- **Foundational (Phase 2)**: Depende Setup — **bloqueia US1, US2, US4, US5**
- **US3 (Phase 3)**: Independente do client — pode executar **em paralelo** com Phase 2 após Setup
- **US1 (Phase 4)**: Depende Phase 2 — MVP client
- **US2 (Phase 5)**: Depende US1 (handler AuthContext) — incremental fino
- **US5 (Phase 6)**: Depende US1 (AuthContext loading/isAuthenticated) — pode merge com US1 se preferir
- **US4 (Phase 7)**: Depende US1/US2 (session-lost distinto de toast) — Toast/useApiAction
- **Polish (Phase 8)**: Depende fases desejadas completas

### User Story Dependencies

| Story | Depende de | Independente para teste |
|-------|------------|-------------------------|
| US3 | Setup | ✅ API Supertest isolado |
| US1 | Foundational | ✅ MSW 401 + LoginPage |
| US2 | US1 handler | ✅ MSW network |
| US5 | US1 AuthContext | ✅ RequireAuth loading |
| US4 | US1/US2 | ✅ 403 + toast gabinete |

### Parallel Opportunities

```text
# Após Setup (Phase 1):
Track A: T004→T005→T006 (shared client)     → US1/US2/US4/US5
Track B: T007→T010→T011→T012 (API audit)   → US3

# Dentro US4:
T029 + T031 em paralelo (ToastContext vs useApiAction test)
T032 + T033 em paralelo (páginas gabinete diferentes)
```

---

## Parallel Example: User Story 3 (API)

```bash
# RED em paralelo:
T007 audit.service.spec.ts
T008 audit.interceptor.spec.ts
T009 audit-resilience.e2e-spec.ts

# GREEN sequencial:
T010 → T011 → T012
```

---

## Parallel Example: User Story 1 (Client MVP)

```bash
# RED em paralelo:
T013 session-logout.e2e.test.tsx
T014 auth-context.test.tsx

# GREEN sequencial:
T015 → T016 → T017 → T18 → T19
```

---

## Implementation Strategy

### MVP First (recomendado)

1. Phase 1 Setup
2. **Phase 3 US3** (API audit — desbloqueia uso real AdminTenant) **em paralelo com** Phase 2
3. Phase 2 Foundational (`createApiClient`)
4. Phase 4 US1 (401 logout + mensagem login)
5. **STOP e VALIDAR** VS-001 + VS-002
6. Phase 5 US2 → Phase 6 US5 → Phase 7 US4 → Phase 8 Polish

### Entrega incremental

| Incremento | Fases | Valor entregue |
|------------|-------|----------------|
| Hotfix API | 1 + 3 | Servidor não cai em mutação AdminTenant |
| MVP Auth | 1 + 2 + 4 | 401 desloga com mensagem |
| Resiliência rede | 5 | API down desloga gracefully |
| UX erros | 7 + 8 | Toast transversal; zero unhandled promises |

### Suggested MVP scope

**US3 + US1** — corrige crash em cadeia (audit → Failed to fetch) e sintoma principal (token inválido sem logout).

---

## Notes

- TDD: RED confirmado antes de GREEN em cada fase de testes
- 403 **nunca** dispara session-lost (FR-005) — validar em T026
- Modo mock (`VITE_USE_API=false`) não registra handler de rede real — T037
- `[P]` = arquivos distintos; evitar editar `AuthContext.tsx` em paralelo (T015/T016/T021 sequenciais)
- Total: **39 tasks** — US3: 6 | US1: 7 | US2: 3 | US5: 3 | US4: 9 | Setup: 3 | Foundational: 3 | Polish: 5
