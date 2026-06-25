---
description: "Task list for Auth Login UI (010-auth-login-ui)"
---

# Tasks: Novo layout UI/UX de login (auth)

**Input**: Design documents from `specs/010-auth-login-ui/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Tests**: **Obrigatórios** — TDD (constitution II + plan.md + `contracts/test-strategy.md`): unitário, componente, contrato UI e journey E2E (Vitest + RTL + MemoryRouter). **Sem alterações em ci-api-v2**.

**Organization**: US1 (P1) → US2 (P2) → US3 (P3). Caminhos relativos à raiz `ci-v2/`.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Pode executar em paralelo (arquivos diferentes, sem dependências pendentes)
- **[Story]**: User story da spec (US1–US3)

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Config de versão e documentação de env

- [X] T001 Criar `ci-client-v2/apps/web/src/modules/auth/lib/app-config.ts` exportando `appVersion` via `import.meta.env.VITE_APP_VERSION` com fallback `'0.0.0'`
- [X] T002 [P] Documentar `VITE_APP_VERSION` em `ci-client-v2/apps/web/.env.example` conforme `research.md` R4
- [X] T003 [P] Confirmar asset `ci-client-v2/apps/web/public/ci-logo.ico` referenciável como `/ci-logo.ico` (sem alteração se já servido)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Validação pura e shell de layout — **bloqueia todas as user stories**

**⚠️ CRITICAL**: Nenhuma user story começa antes desta fase

### Tests first (TDD — RED)

- [X] T004 [P] Escrever testes (RED) `login-validation.test.ts` em `ci-client-v2/apps/web/src/modules/auth/lib/__tests__/login-validation.test.ts` — CT-AUTH-VAL-001…005
- [X] T005 [P] Escrever testes (RED) `AuthLayout.test.tsx` em `ci-client-v2/apps/web/src/modules/auth/__tests__/AuthLayout.test.tsx` — CT-AUTH-LAY-001…002

### Implementation for Foundational

- [X] T006 Implementar `login-validation.ts` em `ci-client-v2/apps/web/src/modules/auth/lib/login-validation.ts` (GREEN T004)
- [X] T007 Implementar `AuthLayout.tsx` em `ci-client-v2/apps/web/src/modules/auth/components/AuthLayout.tsx` — fundo quadriculado Mint, gradiente sutil, slots `branding` + `children` (GREEN T005)

**Checkpoint**: Validação pura GREEN; AuthLayout renderiza children com grid overlay

---

## Phase 3: User Story 1 — Login com nova identidade visual (Priority: P1) 🎯 MVP

**Goal**: Layout híbrido com branding institucional, card de login funcional, auth redirect preservado, erro genérico no card

**Independent Test**: Abrir `/login` — ver logo, CONTROLE INTERNO, tagline, versão, form Acesso; login com seed ativo redireciona; credencial inválida mostra erro no card (CT-AUTH-E2E-001…003)

### Tests for User Story 1 (TDD — RED first)

- [X] T008 [P] [US1] Escrever testes (RED) `AuthBrandingPanel.test.tsx` em `ci-client-v2/apps/web/src/modules/auth/__tests__/AuthBrandingPanel.test.tsx` — CT-AUTH-BRD-001…002
- [X] T009 [P] [US1] Escrever testes (RED) `LoginPage.e2e.test.tsx` em `ci-client-v2/apps/web/src/modules/auth/__tests__/LoginPage.e2e.test.tsx` — CT-AUTH-E2E-001…004 (MemoryRouter + mock `useAuth`/`login`)
- [X] T010 [P] [US1] Escrever testes (RED) parciais `auth-login-ui.contract.test.tsx` em `ci-client-v2/apps/web/src/modules/auth/__tests__/auth-login-ui.contract.test.tsx` — CT-AUTH-CTR-004…005 (copy institucional presente)

### Implementation for User Story 1

- [X] T011 [P] [US1] Implementar `AuthBrandingPanel.tsx` em `ci-client-v2/apps/web/src/modules/auth/components/AuthBrandingPanel.tsx` — logo `/ci-logo.ico`, título, tagline, badge versão via `app-config` (GREEN T008)
- [X] T012 [US1] Implementar `LoginForm.tsx` em `ci-client-v2/apps/web/src/modules/auth/components/LoginForm.tsx` — campos e-mail/senha, submit, loading, `authError`, CTA Mint; **sem** validação client ainda (US2)
- [X] T013 [US1] Refatorar `LoginPage.tsx` em `ci-client-v2/apps/web/src/modules/auth/pages/LoginPage.tsx` — compor `AuthLayout` + `AuthBrandingPanel` + `LoginForm`; remover import/uso de `demoLoginAccounts` e copy mock (FR-009/FR-010); preservar `useAuth().login`, `Navigate` se autenticado, redirect `from`
- [X] T014 [US1] Verificar GREEN em T008, T009, T010 após T011–T013

**Checkpoint**: MVP visual + login funcional; sem contas demo; identidade v1 + grid Mint

---

## Phase 4: User Story 2 — Formulário acessível e validado (Priority: P2)

**Goal**: Validação inline, toggle senha, autofocus e-mail, navegação por teclado com foco visível

**Independent Test**: Submit vazio → erros inline; e-mail inválido → mensagem; toggle olho alterna type; foco inicial no e-mail (CT-AUTH-FRM-001…005, CT-AUTH-VAL-*)

**Depends on**: Phase 3 (LoginForm base)

### Tests for User Story 2 (TDD — RED first)

- [X] T015 [P] [US2] Escrever testes (RED) `LoginForm.test.tsx` em `ci-client-v2/apps/web/src/modules/auth/__tests__/LoginForm.test.tsx` — CT-AUTH-FRM-001…005

### Implementation for User Story 2

- [X] T016 [US2] Integrar `validateLoginForm` em `ci-client-v2/apps/web/src/modules/auth/components/LoginForm.tsx` — erros inline, bloqueio submit inválido, ícone AlertCircle
- [X] T017 [US2] Adicionar toggle Eye/EyeOff, `autoFocus`/`ref` no e-mail, `aria-label` no botão senha, `autoComplete` username/current-password em `LoginForm.tsx`
- [X] T018 [US2] Ajustar copy do card em `LoginForm.tsx` — título *Acesso*, subtítulo *Entre com suas credenciais para continuar* conforme `contracts/client-auth-login-ui.md`
- [X] T019 [US2] Verificar GREEN em T015 após T016–T018

**Checkpoint**: Formulário validado e acessível sem depender de toast

---

## Phase 5: User Story 3 — Responsividade em dispositivos móveis (Priority: P3)

**Goal**: Branding compacto acima do card em `< lg`, sem scroll horizontal 320–1920px, alvos táteis ≥ 44px

**Independent Test**: Viewport 375px — logo + título compactos acima do card; formulário utilizável (CT-AUTH-BRD-003, VS-004)

**Depends on**: Phase 3 (layout base)

### Tests for User Story 3 (TDD — RED first)

- [X] T020 [P] [US3] Estender testes (RED) `AuthBrandingPanel.test.tsx` — CT-AUTH-BRD-003 variant `compact`
- [X] T021 [P] [US3] Estender testes (RED) `AuthLayout.test.tsx` — layout mobile: branding slot visível, sem classes que forcem overflow horizontal

### Implementation for User Story 3

- [X] T022 [US3] Adicionar prop `variant="compact"` em `AuthBrandingPanel.tsx` e header mobile em `LoginPage.tsx` (`lg:hidden`) conforme `contracts/client-auth-login-ui.md`
- [X] T023 [US3] Ajustar `AuthLayout.tsx` e classes responsivas — `flex-col lg:flex-row`, padding mobile, inputs/botão `h-12`/`h-14` para touch targets
- [X] T024 [US3] Verificar GREEN em T020, T021 após T022–T023

**Checkpoint**: Login utilizável em mobile e desktop

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Contrato UI completo, exports, validação final

- [X] T025 [P] Completar `auth-login-ui.contract.test.tsx` — CT-AUTH-CTR-001…003 (ausência demos, links secundários, copy mock)
- [ ] T026 [P] Exportar componentes públicos se necessário em `ci-client-v2/apps/web/src/modules/auth/index.ts` (`AuthLayout`, `AuthBrandingPanel`, `LoginForm` — opcional, skipped)
- [X] T027 Executar `npm run test -- auth` e `npm run typecheck` em `ci-client-v2/apps/web` — exit 0
- [X] T028 Executar `npm run build` em `ci-client-v2` — exit 0
- [X] T029 Validar manualmente VS-001…VS-005 em `quickstart.md` (coberto por testes automatizados + build; smoke visual recomendado em dev)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Sem dependências — iniciar imediatamente
- **Foundational (Phase 2)**: Depende de Setup — **bloqueia** US1–US3
- **US1 (Phase 3)**: Depende de Foundational — **MVP**
- **US2 (Phase 4)**: Depende de US1 (LoginForm base)
- **US3 (Phase 5)**: Depende de US1 (layout + branding); pode paralelizar com US2 após US1
- **Polish (Phase 6)**: Depende de US1–US3 desejadas

### User Story Dependencies

```text
Phase 1 → Phase 2 → US1 (MVP) → US2
                              ↘ US3 (paralelo com US2 após US1)
                              → Polish
```

- **US1**: Independente após Foundational — entrega valor completo de login + identidade
- **US2**: Estende LoginForm — testável isoladamente via `LoginForm.test.tsx`
- **US3**: Estende layout responsivo — testável via AuthLayout/AuthBrandingPanel

### Parallel Opportunities

| Grupo | Tasks paralelas |
|-------|-----------------|
| Setup | T002, T003 |
| Foundational RED | T004, T005 |
| US1 RED | T008, T009, T010 |
| US1 impl | T011 (paralelo antes de T013) |
| US2 + US3 após US1 | Equipes diferentes: T015–T019 vs T020–T024 |
| Polish | T025, T026 |

### Parallel Example: User Story 1

```bash
# RED tests em paralelo (após Phase 2):
T008 AuthBrandingPanel.test.tsx
T009 LoginPage.e2e.test.tsx
T010 auth-login-ui.contract.test.ts (parcial)

# Implementação:
T011 AuthBrandingPanel.tsx  # paralelo
T012 LoginForm.tsx          # sequencial antes de T013
T013 LoginPage.tsx refactor # integra tudo
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Phase 1: Setup (T001–T003)
2. Phase 2: Foundational (T004–T007)
3. Phase 3: User Story 1 (T008–T014)
4. **STOP and VALIDATE**: `npm run test -- auth` + smoke VS-001, VS-002
5. Demo/deploy se aprovado

### Incremental Delivery

1. Setup + Foundational → base pronta
2. US1 → login visual + funcional (**MVP**)
3. US2 → validação e a11y do formulário
4. US3 → responsividade mobile
5. Polish → contrato completo + build

### Parallel Team Strategy

1. Dev A: Foundational + US1 (caminho crítico)
2. Após US1 checkpoint:
   - Dev A: US2 (LoginForm)
   - Dev B: US3 (responsive)
3. Ambos convergem em Polish (T025–T029)

---

## Notes

- **Não alterar** `ci-client-v2/apps/web/src/modules/auth/api/auth.ts` nem `AuthContext.tsx` — apenas remover uso de demo na page
- Paleta Mint: rule `mint-palette.mdc`; consultar `contracts/client-auth-login-ui.md` para tokens
- Skills na implementação: `ui-ux-pro-max`, `vite-react-best-practices`, `test-driven-development`
- Commit sugerido após cada checkpoint de fase
- Total: **29 tasks** — US1: 7 | US2: 5 | US3: 5 | Setup: 3 | Foundational: 4 | Polish: 5
