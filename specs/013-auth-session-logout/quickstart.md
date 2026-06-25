# Quickstart: Validação Auth Session Logout

**Feature**: 013-auth-session-logout  
**Prerequisites**: Node.js 20+, PostgreSQL, `.env` em `ci-api-v2`, seed Jacaranda  
**References**: [data-model.md](./data-model.md) · [contracts/](./contracts/) · [spec.md](./spec.md)

> Executar **após** implementação (`/speckit-implement`).

## Setup

```powershell
cd ci-api-v2
npm install
npx prisma migrate dev
npm run prisma:seed

npm run start:dev
```

```powershell
cd ci-client-v2
npm install
npm run dev
```

**Expected**: API `:3000`; web `:5173`; tenant Jacaranda; admin `admin@jacaranda.com` e servidor `user@demo.com` no seed.

---

## VS-001 — AdminTenant mutation não derruba API (US3 / SC-003)

| Step | Action | Expected |
|------|--------|----------|
| 1 | Login `admin@jacaranda.com` via web ou `POST /auth/login` | 200 + token |
| 2 | POST `/gabinete/controles-numericos` `{ "documentType": "oficio" }` | 201 |
| 3 | Repetir step 2 dez vezes | Todas 201; API responde |
| 4 | GET `/gabinete/controles-numericos` | 200 lista |

**Fail repro (pré-fix)**: step 2 crash API com `AuditLog_userId_fkey`; step 4 `Failed to fetch`.

---

## VS-002 — Token inválido desloga (US1 / SC-001)

| Step | Action | Expected |
|------|--------|----------|
| 1 | Login servidor válido no web | Dashboard acessível |
| 2 | DevTools → Application → editar `ci-access-token` para valor inválido | — |
| 3 | Navegar para `/gabinete/controle-numerico` ou recarregar | Redirect `/login` ≤ 2s |
| 4 | Verificar tela login | Mensagem **"Sessão expirada. Entre novamente."** |
| 5 | Login novamente | Redirect rota de origem |

---

## VS-003 — API indisponível desloga (US2)

| Step | Action | Expected |
|------|--------|----------|
| 1 | Login válido | Autenticado |
| 2 | Parar API (`Ctrl+C` no terminal) | — |
| 3 | Acionar reload em página gabinete | Redirect login |
| 4 | Verificar mensagem | **"Não foi possível manter sua sessão. Entre novamente."** |

---

## VS-004 — 403 não desloga (FR-005)

| Step | Action | Expected |
|------|--------|----------|
| 1 | Login usuário sem setor Gabinete | Autenticado |
| 2 | Acessar rota módulo Gabinete | `AccessDenied403` |
| 3 | Verificar token | Ainda presente; menu usuário ativo |

---

## VS-005 — Erro recuperável com toast (US4)

| Step | Action | Expected |
|------|--------|----------|
| 1 | Login válido setor Gabinete | — |
| 2 | Provocar erro validação (ex.: submit incompleto) | Toast/feedback visível |
| 3 | Verificar sessão | Permanece logado |

---

## VS-006 — Automated tests

```powershell
cd ci-api-v2
npm test -- audit
npm run test:e2e -- --testPathPattern=audit-resilience

cd ci-client-v2/packages/shared
npm test

cd ci-client-v2/apps/web
npm run test -- session
npm run typecheck
```

**Expected**: All green; zero `Uncaught (in promise)` in browser console during VS-002/VS-003.

---

## VS-007 — Mock mode regression

```powershell
cd ci-client-v2/apps/web
# VITE_USE_API=false in .env.local
npm run dev
```

| Step | Action | Expected |
|------|--------|----------|
| 1 | Login mock demo account | Funciona |
| 2 | Navegar módulos | Sem redirect forçado ao login |
