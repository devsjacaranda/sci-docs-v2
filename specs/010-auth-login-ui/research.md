# Research: Novo layout UI/UX de login (auth)

**Feature**: 010-auth-login-ui  
**Date**: 2026-06-23

## R1 — Escopo técnico: client-only

**Decision**: Implementar **apenas** em `ci-client-v2/apps/web`; zero alterações em `ci-api-v2`.

**Rationale**: Spec Out of Scope explicita backend auth; FR-007 exige comportamento equivalente ao atual — `auth.ts` + `AuthContext` já cobrem mock e API JWT.

**Alternatives considered**:

| Alternativa | Motivo de rejeição |
|-------------|-------------------|
| Endpoint novo de branding/config | Over-engineering; versão é estática client |
| Refatorar auth API | Fora de escopo |

---

## R2 — Componentização do layout

**Decision**: Três componentes em `modules/auth/components/`:

| Componente | Responsabilidade |
|------------|------------------|
| `AuthLayout` | Fundo quadriculado Mint + gradiente sutil + split `lg:flex` (branding \| form) |
| `AuthBrandingPanel` | Logo, título, tagline, badge versão; variantes `default` (desktop) e `compact` (mobile) |
| `LoginForm` | Campos, validação inline, toggle senha, erro auth, submit loading |

`LoginPage` orquestra redirect autenticado, `useAuth().login`, `useNavigate`, `useLocation`.

**Rationale**: Separa layout (reutilizável se register entrar depois) de lógica de página; alinha Constitution V (pages + components).

**Alternatives considered**:

| Alternativa | Motivo de rejeição |
|-------------|-------------------|
| Monolito em LoginPage.tsx | Dificulta testes isolados de form vs branding |
| Layout em `modules/shell/` | Login é domínio auth, não shell autenticado |
| Shared em `modules/shared/` | Específico demais para auth público |

---

## R3 — Fundo quadriculado + paleta Mint

**Decision**: Reutilizar padrão CSS do v1 adaptado à paleta Mint:

- **Fundo base**: `#F8FAFC` (light) / `#090D16` (dark)
- **Grid overlay**: linhas 1px com opacidade 2% (light) / 3% (light on dark) — `bg-[size:50px_50px]`
- **Gradiente sutil**: radial ou linear com primary Mint em baixa opacidade (sem pulse animado agressivo)
- **Card formulário**: superfície `#E2E8F0` (light) / `#1E293B` (dark) com `backdrop-blur`, borda semântica 10%/15%
- **CTA**: `#0F766E` + texto `#F8FAFC` (light); `#2DD4BF` + texto `#090D16` (dark)

**Rationale**: FR-001, FR-006; rule `mint-palette.mdc`; híbrido v1 grid + identidade CI v2.

**Alternatives considered**:

| Alternativa | Motivo de rejeição |
|-------------|-------------------|
| Painel esquerdo teal sólido (v2 atual) | Usuário escolheu híbrido com grid v1 |
| Azul/roxo primário v1 | Usuário escolheu paleta Mint |
| Imagem de fundo | Performance e manutenção piores |

---

## R4 — Logo e versão

**Decision**:

- Logo: `<img src="/ci-logo.ico" alt="Controle Interno" />` em branding desktop e compact mobile
- Versão: `modules/auth/lib/app-config.ts` exporta `appVersion` = `import.meta.env.VITE_APP_VERSION ?? '0.0.0'` (fallback package `@ci/web`)
- Badge: ponto verde pulsante + texto `Versão {appVersion}`; ocultar badge se versão vazia (edge case spec)

**Rationale**: FR-002, FR-003; asset já em `apps/web/public/`; v1 usava `appConfig.version` — v2 não tinha equivalente.

**Alternatives considered**:

| Alternativa | Motivo de rejeição |
|-------------|-------------------|
| Converter .ico para SVG | Escopo extra; .ico funciona em `<img>` |
| Fetch versão da API | Sem endpoint; over-engineering |
| Hardcode "2.0.0" | Viola FR-003 e assumption de config |

---

## R5 — Validação client-side

**Decision**: Funções puras em `login-validation.ts`:

```typescript
validateLoginForm({ email, password }) → { valid: boolean; errors: { email?: string; password?: string } }
```

Regras:

| Campo | Regra | Mensagem |
|-------|-------|----------|
| email | obrigatório | *Informe o e-mail institucional.* |
| email | regex RFC5322 simplificado | *E-mail inválido.* |
| password | obrigatório (trim) | *Informe a senha.* |

Erro de auth server/mock: mensagem única genérica *E-mail não encontrado ou usuário inativo.* (comportamento atual).

**Rationale**: FR-004, FR-005, FR-008; testável sem DOM; alinha v1 (validação inline) sem toast-only.

**Alternatives considered**:

| Alternativa | Motivo de rejeição |
|-------------|-------------------|
| Zod schema compartilhado | Overkill para 2 campos; pode adicionar depois |
| Validação só no submit sem inline | FR-005 exige feedback inline |
| Mensagens diferentes por campo auth | FR-008 — segurança |

---

## R6 — Remoção de contas demo e copy mock

**Decision**: Remover de `LoginPage.tsx` import/uso de `demoLoginAccounts` e toda UI associada. Manter export em `auth.ts` (pode ser usado em dev/docs). Substituir copy:

| Antes | Depois |
|-------|--------|
| *Sistema V2 · Mockdown* | *(removido)* |
| *Use um e-mail de demonstração…* | *Entre com suas credenciais para continuar* |
| *© Mock · sem autenticação real* | *(removido)* |
| Título form *Entrar* | *Acesso* (desktop) / *Acesso ao Sistema* (mobile compact) |

**Rationale**: FR-009, FR-010; decisão explícita do usuário na specify.

---

## R7 — Estratégia de testes

**Decision**: Vitest 3 + RTL + user-event; MSW opcional apenas se testar path `VITE_USE_API=true`. Padrão mock: `AuthProvider` real + `platformUsersSeed` ou mock de `useAuth`.

Camadas: unit (validation), component (form, branding, layout), contract (copy/structure), e2e UI journey (login redirect).

**Rationale**: Constitution II; infra Vitest já existe (`vitest.config.ts`, ouvidoria e2e como referência).

**Alternatives considered**:

| Alternativa | Motivo de rejeição |
|-------------|-------------------|
| Playwright | Fora do padrão estabelecido em 006/008 |
| Sem testes | Viola constitution |
| Snapshot-only | Não valida comportamento FR |

---

## R8 — Acessibilidade e responsividade

**Decision**:

- Breakpoint split: `lg` (1024px) — alinhado v1
- Foco inicial: `autoFocus` ou `useRef` + `useEffect` no email
- Toggle senha: `button type="button"` + `aria-label` *Mostrar senha* / *Ocultar senha*
- Inputs: `autoComplete="username"` / `current-password`; labels associados via `htmlFor`
- Touch targets: inputs `h-12`/`h-14`, botão toggle ≥ 44px área clicável

**Rationale**: User Story 2 e 3; SC-002, SC-003.

**Alternatives considered**:

| Alternativa | Motivo de rejeição |
|-------------|-------------------|
| `md` breakpoint | v1 usa `lg`; melhor para tablets em layout compact |
| Ícone Shield no lugar do logo | FR-002 exige logo institucional |
