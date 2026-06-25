# Quickstart: Auth Login UI

**Feature**: 010-auth-login-ui  
**Prerequisites**: Node.js 20+  
**References**: [data-model.md](./data-model.md) · [contracts/](./contracts/) · [spec.md](./spec.md)

> Executar **após** implementação (`/speckit-implement`). Inclui validação automatizada e smoke manual.

## Setup

```powershell
cd ci-client-v2
npm install
```

Opcional — versão customizada na tela:

```powershell
# ci-client-v2/apps/web/.env.local
VITE_APP_VERSION=2.0.0
```

## Testes automatizados (obrigatório)

```powershell
cd ci-client-v2/apps/web
npm run test -- auth
npm run typecheck
```

**Expected**: exit 0; suites em `modules/auth/__tests__/` e `lib/__tests__/`.

Build:

```powershell
cd ci-client-v2
npm run build
```

**Expected**: exit 0; artefato em `apps/web/dist/`.

---

## Dev server

```powershell
cd ci-client-v2
npm run dev
```

Abrir `http://localhost:5173/login` (porta pode variar).

---

## VS-001 — Identidade visual desktop (US1, SC-005)

| Step | Action | Expected |
|------|--------|----------|
| 1 | Viewport ≥ 1024px, abrir `/login` | Fundo quadriculado Mint visível |
| 2 | Verificar coluna esquerda | Logo CI, **CONTROLE INTERNO**, tagline institucional |
| 3 | Verificar badge | *Versão {x}* com indicador verde |
| 4 | Verificar coluna direita | Card *Acesso* com campos e-mail e senha |
| 5 | Confirmar ausências | Sem contas demo, sem links secundários |

---

## VS-002 — Login bem-sucedido (US1, SC-001)

| Step | Action | Expected |
|------|--------|----------|
| 1 | Informar e-mail de usuário ativo do seed demo | Campo aceita input |
| 2 | Informar senha qualquer não vazia (modo mock) | Campo mascarado |
| 3 | Clicar **Entrar** | Loading breve → redirect dashboard |
| 4 | Tempo total | < 30 segundos |

---

## VS-003 — Validação e erros (US2, SC-004)

| Step | Action | Expected |
|------|--------|----------|
| 1 | Submit com campos vazios | Mensagens inline nos campos |
| 2 | E-mail `not-an-email` + submit | *E-mail inválido.* |
| 3 | E-mail inexistente + submit | Erro genérico no card |
| 4 | Toggle olho na senha | Caracteres visíveis/ocultos |

---

## VS-004 — Responsividade mobile (US3, SC-002)

| Step | Action | Expected |
|------|--------|----------|
| 1 | Viewport 375px | Branding compacto acima do card |
| 2 | Preencher e submeter login | Formulário utilizável sem scroll horizontal |
| 3 | Viewport 320px | Layout não quebra |

---

## VS-005 — Modo escuro (FR-006, SC-003)

| Step | Action | Expected |
|------|--------|----------|
| 1 | Ativar dark mode do app | Fundo `#090D16`, card `#1E293B` |
| 2 | Verificar botão Entrar | Mint `#2DD4BF` com texto escuro legível |
| 3 | Inspeção visual | Contraste AA em título e CTA |

---

## Checklist pós-implementação

- [ ] VS-001 a VS-005 passam manualmente
- [ ] `npm run test -- auth` exit 0
- [ ] `npm run build` exit 0
- [ ] Nenhum elemento FR-009 visível (ver [client-auth-login-ui.md](./contracts/client-auth-login-ui.md))
