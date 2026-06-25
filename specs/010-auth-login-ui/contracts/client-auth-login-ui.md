# Contract: Client UI — Auth Login

**Feature**: 010-auth-login-ui  
**Route**: `/login`  
**Module**: `modules/auth/`  
**References**: [data-model.md](../data-model.md) · [research.md](../research.md) · mint-palette · [spec.md](../spec.md)

## Navegação

| Origem | Comportamento |
|--------|---------------|
| Rota protegida sem sessão | `RequireAuth` → `/login` com `state.from` |
| `/login` autenticado | Redirect imediato para `from` ou `/global/dashboard` |
| Logout (`UserMenu`) | `navigate('/login', { replace: true })` |

Rota já registrada em `app/router.tsx` — **sem nova rota**.

---

## Layout (`AuthLayout`)

### Estrutura desktop (`≥ lg`)

```text
┌──────────────────────────────────────────────────────────────┐
│ ░░░░░░░░░░░░░░░ GRID BACKGROUND (full viewport) ░░░░░░░░░░░░░ │
│  ┌─────────────────────┐    ┌─────────────────────────────┐  │
│  │   BRANDING PANEL    │    │      LOGIN CARD             │  │
│  │   [logo]            │    │  Acesso                     │  │
│  │   CONTROLE INTERNO  │    │  Entre com suas credenciais │  │
│  │   tagline           │    │  ┌─────────────────────┐    │  │
│  │   ● Versão x.y.z    │    │  │ Email               │    │  │
│  │                     │    │  │ Senha        [eye]  │    │  │
│  │                     │    │  │ [ erro inline ]     │    │  │
│  │                     │    │  │ [ Entrar → ]        │    │  │
│  └─────────────────────┘    └─────────────────────────────┘  │
└──────────────────────────────────────────────────────────────┘
```

### Estrutura mobile (`< lg`)

```text
┌────────────────────────┐
│ ░ GRID BACKGROUND ░░░░ │
│  [logo] compact        │
│  CONTROLE INTERNO      │
│  ┌──────────────────┐  │
│  │ LOGIN CARD       │  │
│  │ (mesmo conteúdo) │  │
│  └──────────────────┘  │
└────────────────────────┘
```

- Split: `flex-col lg:flex-row`; branding `hidden lg:flex lg:w-1/2`; form `w-full lg:w-1/2`
- Grid: overlay absoluto `inset-0` sobre gradiente Mint base
- Sem scroll horizontal em 320px–1920px

---

## AuthBrandingPanel

| Elemento | Conteúdo | Estilo |
|----------|----------|--------|
| Logo | `/ci-logo.ico` alt *Controle Interno* | ~96–120px desktop; ~64px compact |
| Título | **CONTROLE INTERNO** | uppercase, bold, foreground |
| Tagline | Gestão pública moderna, transparente e eficiente. | muted-foreground, centered desktop |
| Versão | `Versão {appVersion}` | dot verde + texto sm muted |

**Variant `compact`**: logo + título centralizados acima do card; tagline e versão opcionais (versão pode ficar abaixo do card em mobile).

---

## LoginForm (card)

### Header

| Viewport | Título | Subtítulo |
|----------|--------|-----------|
| `≥ lg` | Acesso | Entre com suas credenciais para continuar |
| `< lg` | Acesso ao Sistema | Entre com suas credenciais |

### Campos

| Campo | Label | Input | Notas |
|-------|-------|-------|-------|
| email | E-mail institucional | `type="email"` | placeholder `nome@instituicao.gov.br`; autofocus |
| password | Senha | `type="password"` \| `text` | toggle Eye/EyeOff; `aria-label` acessível |

### Botão primário

| Estado | Label |
|--------|-------|
| idle | Entrar + ícone ArrowRight |
| loading | Entrando… + Loader2 spin |
| disabled | loading ou submit bloqueado |

Classes CTA Mint: light `bg-[#0F766E] text-[#F8FAFC]`; dark `bg-[#2DD4BF] text-[#090D16]`.

### Mensagens de erro

| Tipo | Local | Copy |
|------|-------|------|
| Validação email | abaixo do campo | ver [data-model.md](../data-model.md) |
| Validação senha | abaixo do campo | ver data-model |
| Auth failure | banner no card | E-mail não encontrado ou usuário inativo. |

Ícone AlertCircle opcional em erros (padrão v1).

---

## Elementos ausentes (obrigatório — FR-009)

A página **NÃO DEVE** renderizar:

- Seção "Contas de demonstração"
- Botões/cards `demoLoginAccounts`
- Link "Esqueceu?"
- Link "Criar conta" / "Primeiro acesso?"
- Link "Política de Privacidade"
- Copy "Mockdown", "qualquer senha não vazia", "© Mock"

Teste de contrato deve falhar se qualquer um aparecer no DOM.

---

## Tokens Mint (referência)

| Elemento | Light | Dark |
|----------|-------|------|
| Fundo | `#F8FAFC` | `#090D16` |
| Card | `#E2E8F0` / white overlay | `#1E293B` |
| Texto principal | `#090D16` | `#F8FAFC` |
| Borda | `#1E293B` @ 10% | `#E2E8F0` @ 15% |
| CTA | `#0F766E` | `#2DD4BF` |

---

## Exports do módulo

| Export | Alteração |
|--------|-----------|
| `LoginPage` | refactor — usa novos components |
| `demoLoginAccounts` | mantido em `api/auth.ts`; **não** usado na page |
