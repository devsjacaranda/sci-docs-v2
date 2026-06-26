# Contract: Test Strategy — Auth Login UI

**Feature**: 010-auth-login-ui  
**References**: [plan.md](../plan.md) · constitution II · [client-auth-login-ui.md](./client-auth-login-ui.md) · [data-model.md](../data-model.md)

## Princípio: client-only, sem API real

Testes rodam **sem** backend NestJS. Auth mockada via:

- **Modo padrão**: `AuthProvider` + seed `platformUsersSeed` ou mock de `useAuth`
- **Modo API** (opcional): MSW handlers para `POST /auth/login` e `GET /auth/me`

Produção continua usando mock local ou API conforme `VITE_USE_API`.

---

## Escopo de testes (4 camadas)

| Camada | Incluído | Excluído |
|--------|----------|----------|
| **Unitário** | ✅ `login-validation.ts` | — |
| **Componente** | ✅ LoginForm, AuthBrandingPanel, AuthLayout | — |
| **Contrato UI** | ✅ copy, labels, ausência FR-009 | — |
| **Journey E2E UI** | ✅ LoginPage + MemoryRouter | Playwright, browser real |
| **API** | — | ci-api-v2 (out of scope) |

---

## Infraestrutura

### Client (`ci-client-v2/apps/web`)

| Ferramenta | Uso |
|------------|-----|
| Vitest 3 | runner |
| `@testing-library/react` | render + queries |
| `@testing-library/user-event` | type, click, tab |
| `jsdom` | DOM |
| `msw` | opcional — path API |

**Scripts**:

```powershell
cd ci-client-v2/apps/web
npm run test -- auth
npm run typecheck
```

**Setup existente**: `vitest.config.ts`, `vitest.setup.ts`

---

## Matriz por camada

### 1. Unitário — `login-validation.test.ts`

**Local**: `modules/auth/lib/__tests__/login-validation.test.ts`

| Caso | Input | Expected |
|------|-------|----------|
| CT-AUTH-VAL-001 | email vazio | `errors.email` = *Informe o e-mail institucional.* |
| CT-AUTH-VAL-002 | email `invalid` | `errors.email` = *E-mail inválido.* |
| CT-AUTH-VAL-003 | password vazio | `errors.password` = *Informe a senha.* |
| CT-AUTH-VAL-004 | email + password válidos | `valid: true`, errors vazio |
| CT-AUTH-VAL-005 | email com espaços trim | aceita após trim no caller |

---

### 2. Componente — `LoginForm.test.tsx`

| ID | Cenário | Assert |
|----|---------|--------|
| CT-AUTH-FRM-001 | render | labels E-mail institucional, Senha |
| CT-AUTH-FRM-002 | toggle senha | type alterna password/text |
| CT-AUTH-FRM-003 | submit vazio | mensagens inline; login não chamado |
| CT-AUTH-FRM-004 | submit loading | botão disabled + *Entrando…* |
| CT-AUTH-FRM-005 | authError prop | banner visível com copy genérica |

---

### 3. Componente — `AuthBrandingPanel.test.tsx`

| ID | Cenário | Assert |
|----|---------|--------|
| CT-AUTH-BRD-001 | default | título CONTROLE INTERNO, tagline, img logo |
| CT-AUTH-BRD-002 | version prop | *Versão 1.0.0* visível |
| CT-AUTH-BRD-003 | compact | logo + título; layout mobile |

---

### 4. Componente — `AuthLayout.test.tsx`

| ID | Cenário | Assert |
|----|---------|--------|
| CT-AUTH-LAY-001 | children render | branding + form slots |
| CT-AUTH-LAY-002 | grid class | elemento overlay grid presente |

---

### 5. Contrato UI — `auth-login-ui.contract.test.ts`

| ID | Assert |
|----|--------|
| CT-AUTH-CTR-001 | texto *Contas de demonstração* ausente |
| CT-AUTH-CTR-002 | links register/forgot/privacy ausentes |
| CT-AUTH-CTR-003 | copy mock *Mockdown* ausente |
| CT-AUTH-CTR-004 | subtítulo *Entre com suas credenciais* presente |
| CT-AUTH-CTR-005 | CTA *Entrar* presente |

---

### 6. Journey E2E UI — `LoginPage.e2e.test.tsx`

Wrapper: `MemoryRouter initialEntries={['/login']}` + `AuthProvider` (ou mock controlado).

| ID | Cenário | Steps | Expected |
|----|---------|-------|----------|
| CT-AUTH-E2E-001 | login sucesso mock | type email seed ativo + senha → submit | navigate mock called com `/global/dashboard` ou `from` |
| CT-AUTH-E2E-002 | login falha | email desconhecido → submit | auth error visível; permanece em /login |
| CT-AUTH-E2E-003 | já autenticado | render com user set | Navigate away |
| CT-AUTH-E2E-004 | redirect from | state.from `/ouvidoria` + login ok | navigate to `/ouvidoria` |

---

## Ordem TDD recomendada

1. RED: `login-validation.test.ts` → GREEN: `login-validation.ts`
2. RED: `LoginForm.test.tsx` → GREEN: `LoginForm.tsx`
3. RED: `AuthBrandingPanel.test.tsx` → GREEN: `AuthBrandingPanel.tsx`
4. RED: `AuthLayout.test.tsx` → GREEN: `AuthLayout.tsx`
5. RED: contract + e2e → GREEN: refactor `LoginPage.tsx`

---

## Critérios de done (testes)

- [ ] `npm run test -- auth` exit 0
- [ ] `npm run typecheck` exit 0
- [ ] Cobertura manual quickstart VS-001…VS-004 pass
