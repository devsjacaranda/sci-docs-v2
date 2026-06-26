# Data Model: Auth Login UI (Client)

**Feature**: 010-auth-login-ui  
**Storage**: Estado React local na LoginPage/LoginForm; sessão via mecanismos existentes (`sessionStorage` mock ou JWT)  
**Backend**: Inalterado — ver [auth.ts](../../../ci-client-v2/apps/web/src/modules/auth/api/auth.ts)

## Entidades de apresentação

### LoginFormState

Estado controlado do formulário na UI (não persistido).

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `email` | `string` | E-mail institucional digitado |
| `password` | `string` | Senha (mascarada por padrão) |
| `showPassword` | `boolean` | Toggle visibilidade senha |
| `fieldErrors` | `LoginFieldErrors` | Erros de validação client |
| `authError` | `string \| null` | Erro genérico pós-submit |
| `loading` | `boolean` | Submit em andamento |

### LoginFieldErrors

```typescript
interface LoginFieldErrors {
  email?: string
  password?: string
}
```

| Chave | Condição | Mensagem (PT-BR) |
|-------|----------|-------------------|
| `email` | vazio | Informe o e-mail institucional. |
| `email` | formato inválido | E-mail inválido. |
| `password` | vazio após trim | Informe a senha. |

### LoginValidationResult

Saída de `validateLoginForm()` — função pura, sem side effects.

```typescript
interface LoginValidationInput {
  email: string
  password: string
}

interface LoginValidationResult {
  valid: boolean
  errors: LoginFieldErrors
}
```

---

## Identidade visual (AuthBrandingPanel)

Props de apresentação — sem estado de negócio.

| Prop / dado | Tipo | Origem | Regra |
|-------------|------|--------|-------|
| `variant` | `'default' \| 'compact'` | AuthLayout breakpoint | compact em `< lg` |
| `logoSrc` | `string` | constante `/ci-logo.ico` | FR-002 |
| `title` | `string` | constante `CONTROLE INTERNO` | FR-002 |
| `tagline` | `string` | constante institucional | FR-002 |
| `version` | `string \| undefined` | `appConfig.appVersion` | FR-003; ocultar se falsy |

---

## Fluxo de estados (LoginPage)

```text
                    ┌─────────────┐
                    │  Anonymous  │
                    └──────┬──────┘
                           │ load /login
                           ▼
                    ┌─────────────┐
         ┌─────────│   Editing   │◄────────┐
         │         └──────┬──────┘         │
         │ invalid        │ submit valid    │ retry
         ▼                ▼                 │
  ┌─────────────┐  ┌─────────────┐          │
  │ FieldError  │  │  Submitting │          │
  └─────────────┘  └──────┬──────┘          │
                          │                 │
              ┌───────────┼───────────┐     │
              ▼           ▼           ▼     │
       ┌──────────┐ ┌──────────┐ ┌─────────┴──┐
       │ AuthFail │ │ Redirect │ │ AlreadyAuth │
       └──────────┘ └──────────┘ └─────────────┘
            │              │            │
            │              │            └──► Navigate to `from` or `/global/dashboard`
            │              └──► login OK → navigate
            └──► authError set, loading false
```

### Transições

| De | Evento | Para | Efeito |
|----|--------|------|--------|
| Anonymous | `isAuthenticated === true` | AlreadyAuth | `<Navigate to={from} />` |
| Editing | submit + invalid client | FieldError | `fieldErrors` preenchido; sem API call |
| Editing | submit + valid | Submitting | `loading=true`; chama `login()` |
| Submitting | `login()` null | AuthFail | `authError` genérico; `loading=false` |
| Submitting | `login()` user | Redirect | `navigate(from, replace)` |

---

## Contrato com auth existente

| Operação | Entrada | Saída | Invariante |
|----------|---------|-------|------------|
| `useAuth().login` | `(email, password)` | `Promise<MockCurrentUser \| null>` | Sem alteração |
| Redirect | `location.state.from` | string path | Default `/global/dashboard` |
| Mock login | email ∈ `platformUsersSeed` ativo | user | Senha ignorada no mock |
| API login | `POST /auth/login` | JWT + `/auth/me` | Quando `VITE_USE_API !== 'false'` |

---

## Elementos proibidos na UI (FR-009)

Estes **não** fazem parte do modelo de UI desta feature:

- `demoLoginAccounts` cards
- Links `/register`, `/forgot-password`, `/privacy`
- Copy mock / instruções de senha demo
