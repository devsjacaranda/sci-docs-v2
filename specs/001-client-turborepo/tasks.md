---
description: "Task list for monorepo frontend com Turborepo (001-client-turborepo)"
---

# Tasks: Monorepo Frontend com Turborepo

**Input**: Design documents from `spec-kit/specs/001-client-turborepo/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Tests**: Smoke manual conforme quickstart.md — sem suite automatizada nesta feature (spec + plan).

**Organization**: Tarefas agrupadas por user story (US1 P1 → US2 P2 → US3 P3) após setup e fundação.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Pode executar em paralelo (arquivos diferentes, sem dependências pendentes)
- **[Story]**: User story da spec (US1, US2, US3)
- Caminhos relativos à raiz do repositório `ci-v2/`

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Scaffold inicial do monorepo frontend sem mover código ainda

- [x] T001 Criar diretórios `ci-client-v2/apps/web/` e `ci-client-v2/packages/{ui,domain,typescript-config}/` conforme plan.md
- [x] T002 Criar `ci-client-v2/package.json` raiz com `"private": true`, `"workspaces": ["apps/*", "packages/*"]` e `"name": "ci-client-v2"`
- [x] T003 Adicionar `turbo` (^2.x) como devDependency em `ci-client-v2/package.json`
- [x] T004 Criar `ci-client-v2/turbo.json` com tasks `build`, `dev`, `lint`, `typecheck` conforme `contracts/turbo-pipeline.md`
- [x] T005 Atualizar `ci-client-v2/.gitignore` com `.turbo/`, `**/dist/`, `node_modules/`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Infraestrutura que bloqueia todas as user stories — migrar SPA para `apps/web` e tsconfig compartilhado

**⚠️ CRITICAL**: Nenhuma user story começa antes desta fase

- [x] T006 [P] Criar `ci-client-v2/packages/typescript-config/package.json` (`@ci/typescript-config`) com exports de `base.json`, `react-library.json`, `vite-app.json`
- [x] T007 [P] Criar `ci-client-v2/packages/typescript-config/base.json` com compilerOptions compartilhados extraídos de `ci-client-v2/tsconfig.app.json` atual
- [x] T008 [P] Criar `ci-client-v2/packages/typescript-config/react-library.json` estendendo `base.json` para pacotes lib
- [x] T009 [P] Criar `ci-client-v2/packages/typescript-config/vite-app.json` estendendo `base.json` para apps Vite
- [x] T010 Mover conteúdo atual de `ci-client-v2/src/`, `ci-client-v2/index.html`, `ci-client-v2/public/` (se existir), configs Vite/ESLint/tsconfig para `ci-client-v2/apps/web/`
- [x] T011 Criar `ci-client-v2/apps/web/package.json` com `"name": "@ci/web"`, scripts `dev`, `build`, `preview`, `lint`, `typecheck` e deps migradas do `ci-client-v2/package.json` antigo
- [x] T012 Atualizar `ci-client-v2/apps/web/tsconfig.json` e `ci-client-v2/apps/web/tsconfig.app.json` para estender `@ci/typescript-config/vite-app.json`
- [x] T013 Atualizar `ci-client-v2/apps/web/vite.config.ts` com `resolve.dedupe`, `server.fs.allow` e paths `@/` apontando para `apps/web/src/`
- [x] T014 Mover `ci-client-v2/.env` e `ci-client-v2/.env.example` (se existirem) para `ci-client-v2/apps/web/` sem alterar keys `VITE_*` (contrato `contracts/vite-env.md`)
- [x] T015 Adicionar scripts raiz em `ci-client-v2/package.json`: `dev`, `build`, `lint`, `typecheck` via `turbo run` conforme `contracts/turbo-pipeline.md`
- [x] T016 Remover `ci-client-v2/package.json` legado duplicado (deps migradas para `@ci/web`); manter apenas root workspace + devDeps turbo
- [x] T017 Executar `npm install` na raiz `ci-client-v2/` e resolver conflitos de lockfile

**Checkpoint**: Monorepo instala; `@ci/web` existe em `apps/web/` com código migrado

---

## Phase 3: User Story 1 — Continuidade do produto após migração (Priority: P1) 🎯 MVP

**Goal**: SPA funciona identicamente após migração estrutural — zero regressão visível

**Independent Test**: `npm run dev` na raiz → login, dashboard, navegação, 4 licenças, tema claro/escuro (quickstart VS-001 a VS-003)

### Implementation for User Story 1

- [x] T018 [US1] Ajustar `ci-client-v2/apps/web/vite.config.ts` para garantir alias `@/` → `./src` e base path correto pós-migração
- [x] T019 [US1] Verificar `ci-client-v2/apps/web/index.html` referencia entry script correto (`/src/main.tsx` ou equivalente)
- [x] T020 [US1] Executar `npm run dev` em `ci-client-v2/` e corrigir erros de import/path até SPA carregar (VS-001)
- [x] T021 [US1] Executar `npm run build` em `ci-client-v2/` e confirmar artefato em `ci-client-v2/apps/web/dist/index.html` (VS-005 parcial)
- [x] T022 [US1] Executar `npm run preview --workspace=@ci/web` e validar rotas client-side (SPA rewrites)
- [x] T023 [US1] Smoke manual: fluxo login → dashboard em dev (quickstart VS-002 steps 1-4)
- [x] T024 [US1] Smoke manual: navegação Carvalho, Pau-Brasil, Jatobá, Cedro — breadcrumbs e alertas de licença (quickstart VS-003)
- [x] T025 [US1] Smoke manual: alternância tema claro/escuro persiste visualmente (quickstart VS-003 step 3)

**Checkpoint**: MVP entregue — app migrada funciona; deploy path `apps/web/dist/`

---

## Phase 4: User Story 2 — Código compartilhado entre pacotes (Priority: P2)

**Goal**: Extrair `@ci/ui` e `@ci/domain`; app consome via workspace sem duplicação

**Independent Test**: `npm run typecheck` passa; imports `@ci/ui` e `@ci/domain` compilam; alteração em `packages/domain` reflete no rebuild (quickstart VS-004)

### Implementation for User Story 2

- [x] T026 [P] [US2] Criar `ci-client-v2/packages/ui/package.json` (`@ci/ui`) com `exports`, `peerDependencies` react/react-dom e scripts `typecheck`/`lint` conforme `contracts/workspace-packages.md`
- [x] T027 [P] [US2] Criar `ci-client-v2/packages/ui/tsconfig.json` estendendo `@ci/typescript-config/react-library.json`
- [x] T028 [P] [US2] Criar `ci-client-v2/packages/domain/package.json` (`@ci/domain`) com `exports` e scripts `typecheck`/`lint`
- [x] T029 [P] [US2] Criar `ci-client-v2/packages/domain/tsconfig.json` estendendo `@ci/typescript-config/react-library.json`
- [x] T030 [US2] Mover `ci-client-v2/apps/web/src/components/ui/*.tsx` (21 arquivos) para `ci-client-v2/packages/ui/src/components/ui/`
- [x] T031 [US2] Mover `ci-client-v2/apps/web/src/lib/utils.ts` para `ci-client-v2/packages/ui/src/lib/utils.ts`
- [x] T032 [US2] Criar `ci-client-v2/packages/ui/src/index.ts` re-exportando todos os componentes UI e `cn` de `lib/utils.ts`
- [x] T033 [US2] Criar `ci-client-v2/packages/ui/components.json` com aliases shadcn apontando para paths internos do pacote
- [x] T034 [US2] Mover `ci-client-v2/apps/web/src/types/screen.ts` para `ci-client-v2/packages/domain/src/types/screen.ts`
- [x] T035 [US2] Mover `ci-client-v2/apps/web/src/lib/licenses.ts` para `ci-client-v2/packages/domain/src/lib/licenses.ts`
- [x] T036 [US2] Criar `ci-client-v2/packages/domain/src/index.ts` re-exportando tipos e utilitários de licença
- [x] T037 [US2] Adicionar `"@ci/ui": "*"` e `"@ci/domain": "*"` em `ci-client-v2/apps/web/package.json` dependencies
- [x] T038 [US2] Atualizar imports em `ci-client-v2/apps/web/src/**/*.tsx` de `@/components/ui/*` para `@ci/ui` (codemod ou busca/substituição)
- [x] T039 [US2] Atualizar imports em `ci-client-v2/apps/web/src/**/*.ts` de `@/lib/utils` para `@ci/ui` e de `@/types/screen`/`@/lib/licenses` para `@ci/domain`
- [x] T040 [US2] Adicionar `@source` em `ci-client-v2/apps/web/src/index.css` apontando para `../../packages/ui/src/**/*.{ts,tsx}` (research R5)
- [x] T041 [US2] Atualizar `ci-client-v2/apps/web/vite.config.ts` com `optimizeDeps.include: ['@ci/ui', '@ci/domain']`
- [x] T042 [US2] Atualizar `ci-client-v2/apps/web/components.json` para adicionar componentes futuros via `@ci/ui`
- [x] T043 [US2] Remover arquivos duplicados em `ci-client-v2/apps/web/src/` após migração (ui/, utils.ts, licenses.ts, types/screen.ts)
- [x] T044 [US2] Executar `npm run typecheck` em `ci-client-v2/` — corrigir erros até zero (VS-004)
- [x] T045 [US2] Smoke: alterar string em `ci-client-v2/packages/domain/src/lib/licenses.ts`, rebuild e confirmar reflexo na UI (SC-006)

**Checkpoint**: Pacotes compartilhados ativos; grafo acíclico `@ci/web` → `@ci/ui`, `@ci/domain` (sem `@ci/domain` → `@ci/ui`)

---

## Phase 5: User Story 3 — Orquestração de tarefas na raiz (Priority: P3)

**Goal**: Comandos unificados na raiz com pipeline Turbo, ordem de deps e cache incremental

**Independent Test**: `npm run dev|build|lint|typecheck` na raiz; 2º build ≥50% mais rápido (quickstart VS-005 a VS-007)

### Implementation for User Story 3

- [x] T046 [P] [US3] Adicionar script `typecheck` (`tsc --noEmit`) em `ci-client-v2/packages/ui/package.json` e `ci-client-v2/packages/domain/package.json`
- [x] T047 [P] [US3] Adicionar script `lint` (`eslint src/`) em `ci-client-v2/packages/ui/package.json` e `ci-client-v2/packages/domain/package.json` com config mínima ou eslint flat compartilhado
- [x] T048 [US3] Validar `ci-client-v2/turbo.json`: task `build` com `dependsOn: ["^typecheck"]` e `outputs: ["dist/**"]` conforme contrato
- [x] T049 [US3] Executar `npm run build` em `ci-client-v2/` e confirmar ordem: typecheck upstream antes de build `@ci/web` (log Turbo)
- [x] T050 [US3] Executar `npm run lint` e `npm run typecheck` na raiz — todos os pacotes executam; falha identifica pacote (VS-007)
- [x] T051 [US3] Medir dois `npm run build` consecutivos sem alterações — confirmar cache hits e redução ≥50% no tempo (VS-006, SC-004)
- [x] T052 [US3] Documentar comando `npx turbo run build --force` em `ci-client-v2/README.md` para invalidar cache

**Checkpoint**: Pipeline Turbo completo; cache validado

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Documentação, governance e validação final

- [x] T053 [P] Escrever `ci-client-v2/README.md` com estrutura de pacotes, comandos (`dev`, `build`, `lint`, `typecheck`), path deploy `apps/web/dist/` e guia "adicionar pacote" (FR-008, SC-007)
- [x] T054 [P] Atualizar `README.md` raiz do repo se referenciar `cd ci-client-v2; npm run dev` ou path `ci-client-v2/dist/`
- [x] T055 Amend `spec-kit/.specify/memory/constitution.md` seção III: Turborepo frontend em `ci-client-v2` **adotado** (remover "fora de escopo")
- [x] T056 Executar checklist completo de `spec-kit/specs/001-client-turborepo/quickstart.md` (VS-001 a VS-009) e registrar resultados
- [x] T057 [P] Verificar ausência de dependências circulares entre `@ci/*` via grep/review (FR-012, VS-008)
- [x] T058 Remover artefatos legados na raiz `ci-client-v2/` (`src/` vazio, `dist/` antigo, configs duplicados) se ainda existirem

---

## Dependencies & Execution Order

### Phase Dependencies

```text
Phase 1 (Setup)
    ↓
Phase 2 (Foundational) — BLOCKS all user stories
    ↓
Phase 3 (US1 P1) — MVP: app funcional em apps/web
    ↓
Phase 4 (US2 P2) — requer US1 estável antes de extrair pacotes
    ↓
Phase 5 (US3 P3) — pipeline completo após pacotes existirem
    ↓
Phase 6 (Polish)
```

### User Story Dependencies

| Story | Depende de | Independente quando |
|-------|------------|---------------------|
| US1 (P1) | Phase 2 completa | Dev + build + smoke passam na raiz |
| US2 (P2) | US1 checkpoint | typecheck + imports `@ci/*` OK |
| US3 (P3) | US2 checkpoint | Todos pacotes com scripts lint/typecheck |

### Parallel Opportunities

**Phase 1**: T001–T005 sequenciais (mesma área raiz)

**Phase 2 paralelo**:
```text
T006 + T007 + T008 + T009  (typescript-config — arquivos distintos)
```

**Phase 4 paralelo (início US2)**:
```text
T026 + T027  (@ci/ui scaffold)
T028 + T029  (@ci/domain scaffold)
```

**Phase 5 paralelo**:
```text
T046 + T047  (scripts em ui e domain)
```

**Phase 6 paralelo**:
```text
T053 + T054 + T057  (docs e verificação)
```

---

## Parallel Example: User Story 2

```bash
# Scaffold dos dois pacotes em paralelo:
T026: ci-client-v2/packages/ui/package.json
T028: ci-client-v2/packages/domain/package.json
T027: ci-client-v2/packages/ui/tsconfig.json
T029: ci-client-v2/packages/domain/tsconfig.json

# Após T030-T036 (migração), atualizar imports (T038-T039) antes de T044 typecheck
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Completar Phase 1 + Phase 2 (fundamental)
2. Completar Phase 3 (US1)
3. **STOP e VALIDAR**: quickstart VS-001 a VS-003 + build VS-005
4. Demo/deploy com `apps/web/dist/` se aprovado

### Incremental Delivery

1. Setup + Foundational → estrutura monorepo
2. US1 → app funcional (MVP)
3. US2 → pacotes `@ci/ui` + `@ci/domain`
4. US3 → cache Turbo + lint/typecheck globais
5. Polish → docs + constitution + quickstart completo

### Parallel Team Strategy

| Dev | Fase | Foco |
|-----|------|------|
| A | Phase 2 | Migração `apps/web` + tsconfig |
| B | Phase 4 (após US1) | Extração `@ci/ui` |
| C | Phase 4 (após US1) | Extração `@ci/domain` |
| A | Phase 5 | Pipeline Turbo + cache |

---

## Notes

- Total: **58 tasks** (T001–T058)
- US1: 8 tasks (T018–T025)
- US2: 20 tasks (T026–T045)
- US3: 7 tasks (T046–T052)
- Setup: 5 | Foundational: 12 | Polish: 6
- Sem tasks de teste automatizado — validação via quickstart.md (smoke manual)
- Commit sugerido após cada checkpoint de fase
- Não alterar `ci-api-v2/` (FR-010)
