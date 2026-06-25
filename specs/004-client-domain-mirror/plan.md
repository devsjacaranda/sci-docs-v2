# Implementation Plan: Arquitetura Modular Espelho da API (Client)

**Branch**: `004-client-domain-mirror` | **Date**: 2026-06-06 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/004-client-domain-mirror/spec.md`

## Summary

Reorganizar `ci-client-v2/apps/web/src` de layout por tipo técnico (`pages/`, `components/`, `lib/`) para **módulos por domínio** espelhando `ci-api-v2/src/modules/`, com camadas internas (`pages/`, `components/`, `api/`, `hooks/`, `lib/`, `context/`), mais `modules/shell/` (infraestrutura SPA) e `modules/shared/` (reuso entre domínios). Migração **big bang** em entrega única; pacotes Turborepo (`@ci/ui`, `@ci/domain`, `@ci/typescript-config`) inalterados. Stack mantida: React 19, Vite 8, Tailwind v4, shadcn/ui, Nivo.

## Technical Context

**Language/Version**: TypeScript 6.x, React 19, Node.js 20 LTS (mínimo)

**Primary Dependencies**: Vite 8, Turborepo 2.x (orquestrador monorepo — inalterado), react-router-dom 7, npm workspaces, Tailwind v4 (`@tailwindcss/vite`), shadcn/ui via `@ci/ui`, Nivo

**Storage**: N/A (SPA estática; mocks locais em `modules/shell/data/`)

**Testing**: Smoke manual pós-migração (fluxos spec 001 + 003); typecheck + lint + build como rede de segurança; script de verificação de pastas legadas vazias; sem suite E2E nesta feature

**Target Platform**: Browser (SPA estática); deploy inalterado (`apps/web/dist/`)

**Project Type**: Refatoração estrutural frontend — 1 app (`@ci/web`) + pacotes internos existentes; reorganização apenas em `apps/web/src/modules/`

**Performance Goals**: Build e HMR equivalentes ao setup atual; lazy routes preservados (`React.lazy` em `app/router.tsx`)

**Constraints**: Zero regressão visual/funcional; big bang (sem coexistência prolongada legado/modular); grafo acíclico de imports entre módulos; `ci-api-v2` fora de escopo; variáveis `VITE_*` inalteradas

**Scale/Scope**: ~92 arquivos TS/TSX em `apps/web/src`; 9 módulos frontend (shell, shared, auth, address, ouvidoria, permissao, setor, tenant, audit); split de 2 clients HTTP (`admin-api`, `ouvidoria-api`)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Princípio | Status | Notas |
|-----------|--------|-------|
| I. Spec-Driven | ✅ PASS | Spec 004 concluída; plano segue fluxo canônico |
| II. Test-First | ✅ PASS* | Refatoração estrutural: typecheck/lint/build + smoke manual; TDD aplicável a script de verificação de boundaries e imports legados |
| III. Stack fixa | ✅ PASS | React 19 + Vite 8 + Tailwind v4 + shadcn + Nivo; Turborepo packages inalterados |
| IV. Multi-tenant/licenças | ✅ PASS | Tenant header permanece em `shell/api/`; sem alteração de regras de produto |
| V. Modularidade | ⚠️ AMENDMENT | Adicionar espelho modular frontend (ver amendment abaixo) |

**Post-design re-check**: Estrutura `modules/{shell,shared,<dominio>}/` aprovada; exceção documentada para `ScreenPage` como composition root; pacotes `@ci/*` fora de escopo.

### Constitution Amendment (Principle V)

Adicionar após bullet de API:

```markdown
- Client: pastas modulares por domínio em `apps/web/src/modules/<slug>/` — espelho de `ci-api-v2/src/modules/`
- Camadas frontend: `pages/`, `components/`, `api/` (mínimo); `hooks/`, `lib/`, `context/` quando aplicável
- Infra SPA: `modules/shell/`; reuso cross-domain: `modules/shared/`; UI genérica: `@ci/ui`; tipos licença: `@ci/domain`
- Referência viva: `modules/ouvidoria/` + `modules/permissao/`; composition root: `modules/shell/pages/ScreenPage.tsx`
```

## Project Structure

### Documentation (this feature)

```text
specs/004-client-domain-mirror/
├── plan.md              # Este arquivo
├── research.md          # Decisões técnicas (Phase 0)
├── data-model.md        # Entidades modulares e grafo
├── quickstart.md        # Guia de validação pós-implementação
├── contracts/           # Layout, dependências, imports, split API
│   ├── module-layout.md
│   ├── module-dependencies.md
│   ├── import-map.md
│   └── api-client-split.md
└── tasks.md             # Phase 2 — gerado por /speckit-tasks
```

### Source Code (repository root)

```text
ci-client-v2/
├── package.json                 # inalterado (workspaces + turbo)
├── turbo.json                   # inalterado
├── apps/web/
│   ├── package.json
│   ├── vite.config.ts
│   ├── tsconfig.app.json        # @/* → ./src/*
│   ├── eslint.config.js         # + regras no-restricted-imports (boundaries)
│   └── src/
│       ├── main.tsx
│       ├── App.tsx
│       ├── index.css
│       ├── app/
│       │   └── router.tsx         # registro central de rotas
│       └── modules/
│           ├── shell/
│           │   ├── pages/         # ScreenPage
│           │   ├── components/
│           │   │   ├── layout/
│           │   │   └── mock/
│           │   ├── config/        # screens, navigation, license-screens
│           │   ├── context/       # Theme, LicenseFilter, RecentAccess
│           │   ├── api/           # api-client.ts (base + tenant header)
│           │   ├── hooks/         # use-viewport
│           │   ├── lib/           # breadcrumbs, theme, license-filter, mocks
│           │   └── data/          # mock-data, traceability-mock
│           ├── shared/
│           │   └── components/    # AccessDenied403
│           ├── auth/
│           │   ├── pages/         # LoginPage
│           │   ├── api/           # auth.ts
│           │   └── context/       # AuthContext
│           ├── address/
│           │   ├── api/           # searchMunicipios
│           │   └── index.ts       # barrel público
│           ├── ouvidoria/
│           │   ├── pages/
│           │   ├── components/
│           │   ├── api/           # ouvidoria-api (sem municipios)
│           │   └── index.ts       # lazy route helpers
│           ├── permissao/
│           │   ├── components/    # ModuleSectorBindings, AdminNotifications
│           │   ├── api/           # permissoes/* endpoints
│           │   ├── hooks/         # useModuleAccess
│           │   └── lib/           # permissions.ts
│           ├── setor/
│           │   ├── components/    # PlatformUsers, Sectors, Members, Profile
│           │   └── api/           # setores/*, users/*
│           ├── tenant/
│           │   └── README.md      # scaffold; tenant header em shell/api
│           └── audit/
│               ├── components/    # AuditLogsPanel (extraído de SpecialPanels)
│               └── index.ts
└── packages/                      # INALTERADO
    ├── ui/
    ├── domain/
    └── typescript-config/
```

**Structure Decision**: Módulos por slug idêntico à API; camadas internas espelham responsabilidades backend (api ≈ controller client, pages ≈ telas, components ≈ UI do domínio). `shell` concentra infra; `shared` concentra reuso entre domínios. Pacotes `@ci/*` permanecem fora de `modules/`.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| Constitution V sem frontend mirror | Feature explícita de paridade API↔client | Manter layout por tipo técnico impede onboarding e escala |
| `ScreenPage` importa barrels de domínio | Composition root config-driven (admin panels, audit mock) | Extrair cada tela admin para rota dedicada duplicaria config em `screens.ts` e quebraria UX atual |
| 9 pastas de módulo + camadas | Spec exige paridade 1:1 com API + shell/shared | Agrupamento flat em `features/` não espelha slugs Nest |
| ESLint `no-restricted-imports` | Enforce boundaries sem plugin extra na v1 | Confiança só em convenção falha em big bang com ~92 arquivos |

## Phase 0 — Research Summary

Ver [research.md](./research.md). Principais escolhas:

- **Big bang** com ordem interna: scaffold → shell/shared → domínios → split APIs → router → remover legado
- **Barrels públicos** (`index.ts`) por domínio para consumo cross-module
- **ScreenPage exception**: único arquivo shell autorizado a importar barrels de domínio
- **Boundaries**: ESLint `no-restricted-imports` + script `verify-module-layout.ps1`
- **admin-api split**: permissao (`/permissoes/*`) vs setor (`/setores/*`, `/users/*`)
- **ouvidoria-api split**: address (`searchMunicipios`) vs ouvidoria (resto)

## Phase 1 — Design Artifacts

| Artefato | Caminho | Conteúdo |
|----------|---------|----------|
| Data model | [data-model.md](./data-model.md) | Módulos, camadas, grafo, estados de migração |
| Module layout | [contracts/module-layout.md](./contracts/module-layout.md) | Estrutura de pastas e barrels |
| Dependencies | [contracts/module-dependencies.md](./contracts/module-dependencies.md) | Grafo permitido/proibido |
| Import map | [contracts/import-map.md](./contracts/import-map.md) | Origem → destino big bang |
| API split | [contracts/api-client-split.md](./contracts/api-client-split.md) | Divisão admin-api e ouvidoria-api |
| Quickstart | [quickstart.md](./quickstart.md) | Cenários de validação end-to-end |

## Implementation Strategy (for `/speckit-tasks`)

### Milestone 1 — Scaffold (foundation)

1. Criar árvore `modules/{shell,shared,auth,address,ouvidoria,permissao,setor,tenant,audit}/` com camadas vazias + `index.ts` onde aplicável
2. Adicionar `tenant/README.md` documentando defer de UI para feature futura
3. Configurar ESLint boundaries (`no-restricted-imports` patterns)

### Milestone 2 — Migrar shell + shared (P1 infra)

1. Mover `components/layout/*`, `components/mock/*`, `config/*`, `context/*` (exceto Auth), `data/*`, libs de plataforma → `modules/shell/`
2. Mover `api-client.ts` → `modules/shell/api/`
3. Mover `AccessDenied403` → `modules/shared/components/`
4. Mover `ScreenPage` → `modules/shell/pages/`
5. Mover `use-viewport` → `modules/shell/hooks/`

### Milestone 3 — Migrar domínios (P1 + P2)

1. **auth**: LoginPage, auth.ts, AuthContext
2. **ouvidoria**: pages + components + api (sem municipios)
3. **address**: extrair `searchMunicipios` + tipos; barrel público
4. **permissao**: admin panels (bindings, notifications), permissions, useModuleAccess, api permissoes
5. **setor**: admin panels (users, sectors, members, profile), api setores/users
6. **audit**: extrair `AuditLogsPanel` de `SpecialPanels.tsx`

### Milestone 4 — Router, imports, cleanup (P1)

1. Atualizar `app/router.tsx` imports para `@/modules/ouvidoria/...`, `@/modules/auth/...`, `@/modules/shell/...`
2. Atualizar todos os imports `@/components/*`, `@/pages/*`, `@/lib/*` → paths modulares
3. Remover pastas legadas vazias (`pages/`, `components/`, `lib/`, `config/`, `context/`, `data/`, `hooks/`)
4. Executar script de verificação: zero arquivos em pastas legadas

### Milestone 5 — Docs + constitution (P3)

1. Atualizar `ci-client-v2/README.md` com layout modular e checklist novo domínio
2. Amendment `.specify/memory/constitution.md` (Principle V frontend)
3. Atualizar `.cursor/rules/specify-rules.mdc` (plano ativo 004)
4. Executar [quickstart.md](./quickstart.md) completo

### Vite / TypeScript notes

- Alias `@/*` permanece em `tsconfig.app.json`; apenas paths internos mudam
- Lazy routes: exportar helpers de `modules/ouvidoria/index.ts` consumidos por `app/router.tsx`
- Tailwind `@source`: incluir `modules/**/*.{ts,tsx}` se necessário (paths relativos a `src/`)
- `vite.config.ts`: sem alteração de contrato; `dedupe: ['react', 'react-dom']` mantido
