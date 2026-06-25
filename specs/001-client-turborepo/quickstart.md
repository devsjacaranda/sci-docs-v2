# Quickstart: Validação do Monorepo Frontend

**Feature**: 001-client-turborepo  
**Prerequisites**: Node.js 20+, npm 10+  
**References**: [data-model.md](./data-model.md) · [contracts/](./contracts/)

> Executar **após** implementação (`/speckit-implement`). Cenários mapeiam VS-* do data model.

## Setup inicial

```powershell
cd ci-client-v2
npm install
```

**Expected**: `node_modules` na raiz + hoisting de deps; workspaces `@ci/web`, `@ci/ui`, `@ci/domain` linkados.

---

## VS-001 — Dev server (US1, SC-002)

```powershell
cd ci-client-v2
npm run dev
```

**Expected**:

- Vite inicia em `apps/web` (tipicamente `http://localhost:5173`)
- Sem erros de resolução `@ci/ui` ou `@ci/domain`
- Tempo setup clone→dev < 10 min (SC-002) seguindo README

---

## VS-002 — Fluxos principais (US1, SC-001)

Com dev server ativo, validar manualmente:

| Step | Action | Expected |
|------|--------|----------|
| 1 | Abrir `/login` | Tela de login renderiza |
| 2 | Autenticar (mock) | Redirect para dashboard |
| 3 | Navegar sidebar | Rotas carregam sem 404 client-side |
| 4 | Abrir telas admin | Painéis administrativos renderizam |

---

## VS-003 — Licenças e tema (US1, SC-001)

| Step | Action | Expected |
|------|--------|----------|
| 1 | Filtrar/navegar Carvalho | Alertas e breadcrumbs corretos |
| 2 | Repetir Pau-Brasil, Jatobá, Cedro | Comportamento equivalente ao pré-migração |
| 3 | Alternar tema claro/escuro | Tokens Mint aplicados; persistência visual OK |

---

## VS-004 — Pacotes compartilhados (US2, SC-005, SC-006)

```powershell
cd ci-client-v2
npm run typecheck
```

**Expected**: zero erros; imports de `@ci/ui` e `@ci/domain` resolvem.

**Smoke test de propagação**:

1. Alterar string exportada em `packages/domain/src/lib/licenses.ts`
2. `npm run build`
3. Verificar reflexo na UI (ex.: label de licença)

**Expected**: alteração visível após rebuild único (SC-006); sem cópia manual.

---

## VS-005 — Build produção (US1, SC-003)

```powershell
cd ci-client-v2
npm run build
```

**Expected**:

- Exit code 0
- Artefato em `apps/web/dist/index.html`
- Assets hashed em `apps/web/dist/assets/`

**Preview**:

```powershell
npm run preview --workspace=@ci/web
```

Navegar fluxos VS-002/VS-003 no build de produção.

---

## VS-006 — Cache Turbo (US3, SC-004)

```powershell
cd ci-client-v2
Measure-Command { npm run build }   # 1ª execução — anotar tempo
Measure-Command { npm run build }   # 2ª execução — sem alterações
```

**Expected**:

- 2ª execução reporta cache hits no log Turbo
- Tempo 2ª execução ≤ 50% da 1ª (SC-004)

Forçar rebuild limpo se necessário:

```powershell
npx turbo run build --force
```

---

## VS-007 — Lint e typecheck globais (US3, FR-005)

```powershell
cd ci-client-v2
npm run lint
npm run typecheck
```

**Expected**: todos os pacotes (`@ci/web`, `@ci/ui`, `@ci/domain`) executam; falha em qualquer um aborta com mensagem clara.

---

## VS-008 — Dependência circular (edge case, FR-012)

**Manual check**: confirmar que `@ci/domain` não importa `@ci/ui` (grep ou dependency review).

**Expected**: grafo acíclico conforme [data-model.md](./data-model.md).

---

## VS-009 — Deploy path (FR-009)

Confirmar documentação README aponta deploy para `apps/web/dist/`.

Se `.env.example` existir em `apps/web/`, variáveis `VITE_*` idênticas ao setup anterior.

---

## Checklist resumido

- [ ] VS-001 Dev server OK
- [ ] VS-002 Fluxos principais OK
- [ ] VS-003 Licenças + tema OK
- [ ] VS-004 Shared packages OK
- [ ] VS-005 Build + preview OK
- [ ] VS-006 Cache Turbo ≥50%
- [ ] VS-007 Lint + typecheck globais OK
- [ ] VS-008 Sem ciclos de dependência
- [ ] VS-009 Deploy path documentado

**All pass** → feature pronta para merge.
