# Tasks: Arquitetura Modular Espelho da API (Client)

**Input**: Design documents from `/specs/004-client-domain-mirror/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Tests**: Não incluídos — spec define validação via typecheck, lint, build e smoke manual (quickstart.md). Sem suite E2E nesta feature.

**Organization**: Tarefas agrupadas por user story. Big bang: US1 concentra migração funcional; US2 valida paridade estrutural; US3 documentação.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Pode executar em paralelo (arquivos diferentes, sem dependências pendentes)
- **[Story]**: US1, US2, US3 — mapeia user stories da spec
- Paths relativos a `ci-client-v2/apps/web/` salvo indicação contrária

## Path Conventions

- **App root**: `ci-client-v2/apps/web/src/`
- **Módulos**: `src/modules/<slug>/`
- **Router**: `src/app/router.tsx`
- **Contratos**: `specs/004-client-domain-mirror/contracts/import-map.md`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Scaffold da árvore modular, boundaries ESLint e script de verificação

- [x] T001 Criar árvore de pastas `src/modules/{shell,shared,auth,address,ouvidoria,permissao,setor,tenant,audit}/` com subpastas de camada conforme `contracts/module-layout.md`
- [x] T002 Criar `src/modules/tenant/README.md` documentando defer de UI (tenant header permanece em `shell/api/`)
- [x] T003 Adicionar regras `no-restricted-imports` em `eslint.config.js` conforme `contracts/module-dependencies.md`
- [x] T004 Criar `scripts/verify-module-layout.ps1` validando zero arquivos em pastas legadas e paridade de slugs API
- [x] T005 [P] Revisar `src/index.css` e adicionar `@source` para `modules/**/*.{ts,tsx}` se classes Tailwind não forem detectadas após migração

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Migrar infra shell + shared — BLOQUEIA domínios e US1

**⚠️ CRITICAL**: Nenhuma migração de domínio até shell/api e layout estarem funcionais

- [x] T006 Mover `src/lib/api-client.ts` → `src/modules/shell/api/api-client.ts` e atualizar imports internos
- [x] T007 [P] Mover `src/components/layout/*.tsx` → `src/modules/shell/components/layout/` (exceto `RequireAuth.tsx` → auth na Phase 3)
- [x] T008 [P] Mover `src/components/mock/*.tsx` → `src/modules/shell/components/mock/`
- [x] T009 [P] Mover `src/config/*` → `src/modules/shell/config/`
- [x] T010 [P] Mover `src/context/ThemeContext.tsx`, `LicenseFilterContext.tsx`, `RecentAccessContext.tsx` → `src/modules/shell/context/`
- [x] T011 [P] Mover `src/data/*` → `src/modules/shell/data/`
- [x] T012 [P] Mover libs de plataforma para `src/modules/shell/lib/` conforme `contracts/import-map.md` (breadcrumbs, theme, license-filter, license-alerts, current-screen, welcome-shortcuts, navigation-links, list-page, mock-action-presets, traceability, traceability-copy, jatoba, recent-access, tramitacao-draft)
- [x] T013 Mover `src/pages/ScreenPage.tsx` → `src/modules/shell/pages/ScreenPage.tsx`
- [x] T014 [P] Mover `src/hooks/use-viewport.ts` → `src/modules/shell/hooks/use-viewport.ts`
- [x] T015 Mover `src/components/admin/AccessDenied403.tsx` → `src/modules/shared/components/AccessDenied403.tsx`
- [x] T016 Atualizar imports em arquivos movidos da Phase 2 para usar `@/modules/shell/...` e `@/modules/shared/...`
- [x] T017 Atualizar `src/App.tsx` e `src/main.tsx` para importar contextos e layout de `@/modules/shell/`

**Checkpoint**: `npm run typecheck` passa com shell/shared migrados (domínios ainda podem estar no legado temporariamente até Phase 3)

---

## Phase 3: User Story 1 — Continuidade do produto (Priority: P1) 🎯 MVP

**Goal**: SPA funciona identicamente após big bang — login, licenças, ouvidoria, admin, mocks, build

**Independent Test**: Executar quickstart VS-003, VS-004, VS-005, VS-006, VS-008 — zero regressões visuais/funcionais

### Implementation for User Story 1

- [x] T018 [P] [US1] Mover `src/pages/LoginPage.tsx` → `src/modules/auth/pages/LoginPage.tsx`
- [x] T019 [P] [US1] Mover `src/lib/auth.ts` → `src/modules/auth/api/auth.ts`
- [x] T020 [P] [US1] Mover `src/context/AuthContext.tsx` → `src/modules/auth/context/AuthContext.tsx`
- [x] T021 [P] [US1] Mover `src/components/layout/RequireAuth.tsx` → `src/modules/auth/components/RequireAuth.tsx`
- [x] T022 [P] [US1] Criar `src/modules/address/api/types.ts` e `municipios.ts` extraindo `searchMunicipios` de `src/lib/ouvidoria-api.ts` conforme `contracts/api-client-split.md`
- [x] T023 [P] [US1] Criar `src/modules/ouvidoria/api/` (manifestacoes.ts, anexos.ts, workflow.ts, constants.ts, types.ts) sem `searchMunicipios` conforme `contracts/api-client-split.md`
- [x] T024 [P] [US1] Mover `src/pages/ouvidoria/*.tsx` → `src/modules/ouvidoria/pages/`
- [x] T025 [P] [US1] Mover `src/components/ouvidoria/*` → `src/modules/ouvidoria/components/`
- [x] T026 [P] [US1] Criar `src/modules/permissao/api/` (types.ts, permissoes.ts) extraindo endpoints `/permissoes/*` de `src/lib/admin-api.ts`
- [x] T027 [P] [US1] Mover `src/components/admin/ModuleSectorBindingsPanel.tsx` e `AdminNotificationsPanel.tsx` → `src/modules/permissao/components/`
- [x] T028 [P] [US1] Mover `src/lib/permissions.ts` → `src/modules/permissao/lib/permissions.ts` e `src/hooks/useModuleAccess.ts` → `src/modules/permissao/hooks/useModuleAccess.ts`
- [x] T029 [P] [US1] Criar `src/modules/setor/api/` (types.ts, setores.ts, users.ts) extraindo endpoints `/setores/*` e `/users/*` de `src/lib/admin-api.ts`
- [x] T030 [P] [US1] Mover painéis admin de setor (`PlatformUsersPanel`, `PlatformSectorsPanel`, `SectorMembersPanel`, `PlatformProfilePanel`) → `src/modules/setor/components/`
- [x] T031 [P] [US1] Extrair `AuditLogsPanel` de `src/modules/shell/components/mock/SpecialPanels.tsx` → `src/modules/audit/components/AuditLogsPanel.tsx` e reimportar em SpecialPanels
- [x] T032 [US1] Atualizar `ManifestacaoStepOneForm.tsx` e demais consumidores para importar `searchMunicipios` via `@/modules/address`
- [x] T033 [US1] Atualizar `src/modules/shell/pages/ScreenPage.tsx` imports para painéis admin via paths modulares (`permissao`, `setor`, `audit`, `shared`)
- [x] T034 [US1] Atualizar `src/app/router.tsx` — lazy imports de `@/modules/ouvidoria/pages/*`, `LoginPage` de `@/modules/auth/pages/`, layout de `@/modules/shell/components/layout/`
- [x] T035 [US1] Varredura global: substituir imports legados `@/pages/*`, `@/components/*`, `@/lib/*`, `@/config/*`, `@/context/*`, `@/data/*`, `@/hooks/*` por paths `@/modules/...`
- [x] T036 [US1] Remover arquivos vazios/legados: deletar `src/lib/admin-api.ts`, `src/lib/ouvidoria-api.ts`, `src/lib/api-client.ts`, `src/lib/auth.ts` após split confirmado
- [x] T037 [US1] Remover diretórios legados vazios `src/pages/`, `src/components/`, `src/lib/`, `src/config/`, `src/context/`, `src/data/`, `src/hooks/`
- [x] T038 [US1] Executar `npm run typecheck` na raiz `ci-client-v2/` — zero erros
- [x] T039 [US1] Executar `npm run lint` na raiz `ci-client-v2/` — zero erros
- [x] T040 [US1] Executar `npm run build` na raiz `ci-client-v2/` — artefato em `apps/web/dist/`

**Checkpoint**: US1 completo — app deployável, fluxos ouvidoria + admin + mocks funcionais (SC-001, SC-005)

---

## Phase 4: User Story 2 — Navegabilidade espelho da API (Priority: P2)

**Goal**: Slugs e camadas espelham API; barrels públicos; paridade verificável em < 2 min

**Independent Test**: quickstart VS-002 — revisor mapeia 7 slugs API → `modules/`; VS-001 script passa

### Implementation for User Story 2

- [x] T041 [P] [US2] Criar `src/modules/address/index.ts` exportando `searchMunicipios` e tipos públicos
- [x] T042 [P] [US2] Criar `src/modules/ouvidoria/index.ts` com exports de pages e lazy helpers para `app/router.tsx`
- [x] T043 [P] [US2] Criar `src/modules/auth/index.ts` exportando LoginPage, AuthContext, RequireAuth e auth API
- [x] T044 [P] [US2] Criar `src/modules/permissao/index.ts` exportando componentes admin, hooks e API públicos
- [x] T045 [P] [US2] Criar `src/modules/setor/index.ts` exportando componentes admin e API públicos
- [x] T046 [P] [US2] Criar `src/modules/audit/index.ts` exportando `AuditLogsPanel`
- [x] T047 [US2] Refatorar `ScreenPage.tsx` para importar painéis admin/audit exclusivamente via barrels `@/modules/permissao`, `@/modules/setor`, `@/modules/audit`
- [x] T048 [US2] Refatorar `app/router.tsx` para consumir lazy helpers do barrel `@/modules/ouvidoria` onde aplicável
- [x] T049 [US2] Executar `scripts/verify-module-layout.ps1` — confirmar paridade slugs e zero legado (VS-001, VS-002, SC-003)
- [x] T050 [US2] Confirmar grep zero: `lib/admin-api`, `lib/ouvidoria-api`, `lib/api-client` em `apps/web/src/` conforme `contracts/api-client-split.md`

**Checkpoint**: US2 completo — estrutura espelho API navegável sem mapa externo (SC-002, SC-004, SC-007)

---

## Phase 5: User Story 3 — Convenção documentada (Priority: P3)

**Goal**: README e docs permitem classificar shell/shared/domínio e adicionar novo módulo

**Independent Test**: quickstart VS-010 — par classifica 3 exemplos corretamente (SC-006)

### Implementation for User Story 3

- [x] T051 [US3] Atualizar `ci-client-v2/README.md` — seção estrutura `src/modules/` com tabela shell/shared/domínios
- [x] T052 [US3] Adicionar decision tree shell vs shared vs domínio vs `@ci/*` em `ci-client-v2/README.md` (copiar/adaptar de `contracts/module-layout.md`)
- [x] T053 [US3] Adicionar checklist "novo domínio espelhando API" em `ci-client-v2/README.md`
- [x] T054 [US3] Documentar grafo de dependências resumido e exceção ScreenPage em `ci-client-v2/README.md`
- [x] T055 [US3] Executar validação completa `specs/004-client-domain-mirror/quickstart.md` (VS-001 a VS-010) e registrar resultados

**Checkpoint**: US3 completo — documentação validada (FR-009, SC-006)

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Garantias finais pós big bang

- [x] T056 [P] Confirmar pacotes `packages/ui`, `packages/domain`, `packages/typescript-config` inalterados (FR-005)
- [x] T057 Executar `npm run dev` e smoke manual login → dashboard → ouvidoria → admin → tema (VS-004)
- [x] T058 [P] Revisar `vite.config.ts` — confirmar `dedupe: ['react', 'react-dom']` e resolução workspace sem alteração de contrato

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Sem dependências — iniciar imediatamente
- **Foundational (Phase 2)**: Depende de Phase 1 — **BLOQUEIA** Phase 3–5
- **US1 (Phase 3)**: Depende de Phase 2 — entrega MVP funcional
- **US2 (Phase 4)**: Depende de Phase 3 (código já migrado; adiciona barrels e validação estrutural)
- **US3 (Phase 5)**: Depende de Phase 3 (docs descrevem estrutura real); pode paralelizar com Phase 4 após T040
- **Polish (Phase 6)**: Depende de Phase 3–5

### User Story Dependencies

| Story | Depende de | Entrega independente |
|-------|------------|----------------------|
| **US1 (P1)** | Phase 2 | App funcional pós big bang |
| **US2 (P2)** | US1 | Paridade slugs + barrels + script verificação |
| **US3 (P3)** | US1 | README + quickstart documentado |

### Within Phase 3 (US1)

1. Auth, address API, ouvidoria (T018–T025) — paralelo [P]
2. Permissao + setor split admin-api (T026–T030) — paralelo [P] após T006 (api-client no shell)
3. Audit extract (T031) — após T008 (mock em shell)
4. Integração ScreenPage + router + varredura (T032–T037) — sequencial
5. Validação build (T038–T040) — sequencial final

### Parallel Opportunities

**Phase 1**: T005 paralelo a T001–T004

**Phase 2**: T007–T012, T014, T015 paralelos após T006

**Phase 3**: T018–T031 em paralelo (domínios independentes) antes de T032

**Phase 4**: T041–T046 barrels em paralelo

**Phase 6**: T056, T058 paralelos

---

## Parallel Example: User Story 1 (domínios)

```bash
# Após Phase 2 completa, migrar domínios em paralelo:
Task T018: auth/pages, auth/api, auth/context, auth/components
Task T022: address/api/types.ts + municipios.ts
Task T023–T025: ouvidoria api + pages + components
Task T026–T028: permissao api + components + hooks/lib
Task T029–T030: setor api + components
Task T031: audit AuditLogsPanel extract

# Depois, sequencial:
Task T032–T037: integração imports + cleanup legado
Task T038–T040: typecheck + lint + build
```

---

## Parallel Example: User Story 2 (barrels)

```bash
# Barrels independentes:
Task T041: modules/address/index.ts
Task T042: modules/ouvidoria/index.ts
Task T043: modules/auth/index.ts
Task T044: modules/permissao/index.ts
Task T045: modules/setor/index.ts
Task T046: modules/audit/index.ts

# Sequencial após barrels:
Task T047–T050: refatorar imports + verify script
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (shell + shared)
3. Complete Phase 3: User Story 1 (migração completa + build)
4. **STOP and VALIDATE**: quickstart VS-003–VS-006, VS-008
5. Merge se zero regressão

### Incremental Delivery (pós-MVP)

1. Phase 4 (US2): barrels + verify script → merge ou mesmo PR se big bang único
2. Phase 5 (US3): README + quickstart completo
3. Phase 6: polish final

### Big Bang Single PR (recomendado pela spec)

Executar Phase 1 → 6 em sequência na mesma branch `004-client-domain-mirror` antes de merge. Checkpoints T017, T040, T050, T055 como gates locais.

---

## Notes

- [P] = arquivos diferentes, sem conflito de merge esperado
- Não alterar `ci-api-v2/` (FR-010)
- Não criar pacotes npm por domínio (FR-005)
- Constitution Principle V já amendada em `.specify/memory/constitution.md` v1.1.0
- Referência de movimentação: `specs/004-client-domain-mirror/contracts/import-map.md`
- Referência split HTTP: `specs/004-client-domain-mirror/contracts/api-client-split.md`
