# Implementation Plan: Novo layout UI/UX de login (auth)

**Branch**: `010-auth-login-ui` | **Date**: 2026-06-23 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/010-auth-login-ui/spec.md`

## Summary

Redesenhar a **LoginPage** do CI v2 com layout híbrido inspirado no v1: fundo quadriculado em tela cheia, branding institucional à esquerda (logo `ci-logo.ico`, título, tagline, versão) e card de formulário à direita com validação inline, toggle de senha e paleta Mint (claro/escuro). **Somente client** — sem alterações em `ci-api-v2`; auth existente (`useAuth().login`, redirect `from`) permanece intacta. Remover contas demo e copy de mock da UI.

**Abordagem**: extrair `AuthLayout` + `AuthBrandingPanel` + `LoginForm` em `modules/auth/components/`; validação pura em `lib/login-validation.ts`; testes Vitest + RTL (unit, component, contract UI, journey E2E com MemoryRouter).

## Technical Context

**Language/Version**: TypeScript 6.x; Node.js 20 LTS

**Primary Dependencies**:

| Pacote | Stack |
|--------|-------|
| **ci-client-v2** | React 19, Vite 8, Tailwind v4, shadcn/ui (`@ci/ui`), react-router-dom 7, lucide-react, Vitest 3, MSW 2 |

**Storage**: N/A (UI only; sessão mock em `sessionStorage` ou JWT via API — comportamento existente)

**Testing** (client-only):

| Camada | Local | Ferramentas |
|--------|-------|-------------|
| Unitário | `modules/auth/lib/__tests__/` | Vitest — validação e-mail/senha |
| Componente | `modules/auth/__tests__/` | Vitest + RTL — LoginForm, AuthBrandingPanel, AuthLayout |
| Contrato UI | `modules/auth/__tests__/auth-login-ui.contract.test.ts` | Vitest — labels, copy, ausência de demos/links |
| Journey E2E UI | `modules/auth/__tests__/LoginPage.e2e.test.tsx` | Vitest + MemoryRouter + AuthProvider mock — login sucesso/erro/redirect |

**Target Platform**: SPA browser (desktop + mobile)

**Project Type**: Client-only (frontend)

**Performance Goals**: First paint login ≤ 1s em dev; sem assets adicionais além de `ci-logo.ico` já em `public/`

**Constraints**:

- TDD obrigatório (Constitution II); RED → GREEN → REFACTOR
- Paleta Mint — rule `mint-palette.mdc`; CTA escuro `#0F766E` (light) / `#2DD4BF` com texto `#090D16` (dark)
- Sem alteração de contratos API auth
- FR-009/FR-010: sem contas demo, links secundários, copy mock
- Skills: `ui-ux-pro-max`, `vite-react-best-practices`, `test-driven-development`
- Logo roxo (`ci-logo.ico`) como acento de marca — **não** reintroduzir azul primário v1

**Scale/Scope**: 1 página, ~4 componentes novos/refatorados, 1 config de versão, ~8 arquivos de teste, 0 migrations

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Princípio | Status | Notas |
|-----------|--------|-------|
| I. Spec-Driven | ✅ PASS | Spec 010 validada; plano segue fluxo |
| II. Test-First | ✅ PASS | Estratégia em [contracts/test-strategy.md](./contracts/test-strategy.md) |
| III. Stack fixa | ✅ PASS | React 19 + Vite 8 + Tailwind v4 + shadcn |
| IV. Multi-tenant | ✅ N/A | Sem mudança backend; login público existente |
| IV. Licenças | ✅ N/A | Auth não exige licença de produto |
| V. Escopo mínimo | ✅ PASS | Apenas `modules/auth/` + config versão mínima |

**Post-design re-check**: Componentização em 3 peças (`AuthLayout`, `AuthBrandingPanel`, `LoginForm`) evita duplicação futura sem criar abstrações prematuras para register (out of scope). Config de versão via `VITE_APP_VERSION` + fallback package — escopo mínimo. Sem Complexity Tracking necessário.

## Project Structure

### Documentation (this feature)

```text
specs/010-auth-login-ui/
├── plan.md              # Este arquivo
├── research.md          # Decisões técnicas (Phase 0)
├── data-model.md        # Estado UI e validação client
├── quickstart.md        # Validação manual + comandos de teste
├── contracts/
│   ├── client-auth-login-ui.md
│   └── test-strategy.md
└── tasks.md             # Phase 2 — /speckit-tasks
```

### Source Code (repository root)

```text
ci-client-v2/apps/web/
├── public/
│   └── ci-logo.ico                    # existente — logo branding
├── src/
│   ├── app/
│   │   └── router.tsx                 # rota /login — sem mudança estrutural
│   └── modules/auth/
│       ├── pages/
│       │   └── LoginPage.tsx          # refactor — compõe layout + form
│       ├── components/
│       │   ├── AuthLayout.tsx         # grid + split responsivo
│       │   ├── AuthBrandingPanel.tsx  # logo, título, tagline, versão
│       │   └── LoginForm.tsx          # campos, validação, submit
│       ├── lib/
│       │   ├── login-validation.ts    # funções puras
│       │   └── app-config.ts          # versão exibida (VITE_APP_VERSION)
│       ├── context/
│       │   └── AuthContext.tsx        # inalterado
│       ├── api/
│       │   └── auth.ts                # inalterado (remover import demo na page)
│       └── __tests__/
│           ├── login-validation.test.ts
│           ├── LoginForm.test.tsx
│           ├── AuthBrandingPanel.test.tsx
│           ├── AuthLayout.test.tsx
│           ├── auth-login-ui.contract.test.ts
│           └── LoginPage.e2e.test.tsx
```

**Structure Decision**: Feature client-only em `modules/auth/` conforme Constitution V. Config de versão colocada em `modules/auth/lib/app-config.ts` (escopo auth) em vez de `shell/` — evita acoplamento global; pode migrar depois se outras telas públicas reutilizarem.

## Complexity Tracking

> Nenhuma violação de constitution que exija justificativa.
