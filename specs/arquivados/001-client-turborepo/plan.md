# Implementation Plan: Monorepo Frontend com Turborepo

**Branch**: `001-client-turborepo` | **Date**: 2026-06-05 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/001-client-turborepo/spec.md`

## Summary

Reorganizar `ci-client-v2` de SPA única para monorepo npm workspaces orquestrado por Turborepo 2.x, preservando a aplicação web existente em `apps/web` e extraindo código reutilizável para pacotes internos `@ci/ui` (componentes shadcn) e `@ci/domain` (tipos e utilitários de licença). Comandos unificados na raiz do frontend (`dev`, `build`, `lint`, `typecheck`) com cache incremental. Stack inalterada: React 19, Vite 8, Tailwind v4, shadcn/ui, Nivo.

## Technical Context

**Language/Version**: TypeScript 6.x, React 19, Node.js 20 LTS (mínimo)

**Primary Dependencies**: Vite 8, Turborepo 2.x, npm workspaces, Tailwind CSS v4 (`@tailwindcss/vite`), shadcn/ui (Radix), Nivo, react-router-dom 7

**Storage**: N/A (SPA estática; mocks locais permanecem no app)

**Testing**: Smoke manual pós-migração (fluxos da spec); opcional Vitest no app na fase de implementação para regressão de imports — sem suite E2E nesta feature

**Target Platform**: Browser (SPA estática); deploy inalterado (artefato `dist/` de `apps/web`)

**Project Type**: Frontend monorepo (1 app + N pacotes internos)

**Performance Goals**: Build repetido com cache Turbo ≥50% mais rápido (SC-004); HMR dev equivalente ao setup atual

**Constraints**: Zero regressão visual/funcional; `ci-api-v2` fora de escopo; variáveis `VITE_*` e contrato de deploy preservados; dependências circulares proibidas

**Scale/Scope**: ~1 app, 2 pacotes compartilhados iniciais, 21 componentes UI, dezenas de telas mock existentes

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Princípio | Status | Notas |
|-----------|--------|-------|
| I. Spec-Driven | ✅ PASS | Spec 001 concluída; plano segue fluxo canônico |
| II. Test-First | ✅ PASS* | Refatoração estrutural: smoke tests + typecheck/lint como rede de segurança; TDD aplicável a scripts de validação e testes de importação |
| III. Stack fixa | ✅ PASS | React 19 + Vite 8 + Tailwind v4 + shadcn + Nivo mantidos; Turborepo é orquestrador, não substitui stack |
| III. Turborepo "fora de escopo" | ⚠️ AMENDMENT | Esta feature **implementa** o monorepo Turborepo frontend previsto na constituição — requer amendment na implementação (remover "fora de escopo") |
| IV. Multi-tenant/licenças | ✅ PASS | Sem alteração de regras de produto; pacote `@ci/domain` preserva vocabulário de licenças |
| V. Escopo mínimo | ✅ PASS | Apenas `ci-client-v2`; sem mudanças em API ou spec-kit além de docs desta feature |

**Post-design re-check**: Estrutura `apps/` + `packages/` aprovada; pacotes limitados a UI + domain evitam over-engineering.

## Project Structure

### Documentation (this feature)

```text
spec-kit/specs/001-client-turborepo/
├── plan.md              # Este arquivo
├── research.md          # Decisões técnicas (Phase 0)
├── data-model.md        # Entidades estruturais do monorepo
├── quickstart.md        # Guia de validação pós-implementação
├── contracts/           # Contratos de workspace, pipeline e env
│   ├── workspace-packages.md
│   ├── turbo-pipeline.md
│   └── vite-env.md
└── tasks.md             # Phase 2 — gerado por /speckit-tasks
```

### Source Code (repository root)

```text
ci-client-v2/
├── package.json                 # workspaces + scripts turbo na raiz
├── turbo.json
├── README.md                    # estrutura, comandos, como adicionar pacote
├── apps/
│   └── web/                     # SPA principal (código atual migrado)
│       ├── package.json         # name: @ci/web
│       ├── vite.config.ts
│       ├── index.html
│       ├── components.json      # shadcn apontando para @ci/ui
│       ├── tsconfig.json
│       ├── tsconfig.app.json
│       ├── eslint.config.js
│       └── src/
│           ├── app/
│           ├── components/      # layout, mock, admin (app-specific)
│           ├── config/
│           ├── context/
│           ├── data/
│           ├── hooks/
│           ├── pages/
│           └── index.css        # @import tailwind + tokens; @source packages
├── packages/
│   ├── typescript-config/       # name: @ci/typescript-config
│   │   ├── package.json
│   │   ├── base.json
│   │   ├── react-library.json
│   │   └── vite-app.json
│   ├── ui/                      # name: @ci/ui
│   │   ├── package.json
│   │   ├── tsconfig.json
│   │   ├── components.json
│   │   └── src/
│   │       ├── index.ts         # re-exports
│   │       ├── lib/utils.ts     # cn()
│   │       └── components/ui/   # 21 componentes shadcn migrados
│   └── domain/                  # name: @ci/domain
│       ├── package.json
│       ├── tsconfig.json
│       └── src/
│           ├── index.ts
│           ├── types/screen.ts
│           └── lib/licenses.ts  # utilitários de licença (SC-005)
└── .gitignore                   # node_modules, dist, .turbo
```

**Structure Decision**: Layout `apps/web` + `packages/{ui,domain,typescript-config}` segue convenção Turborepo. Pacotes compartilhados exportam **source TypeScript** consumida diretamente pelo Vite (sem build separado de libs na v1), reduzindo complexidade da migração. `@ci/ui` recebe componentes shadcn genéricos; `@ci/domain` recebe tipos e `licenses.ts` como primeira extração de domínio real.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| Constituição: Turborepo "fora de escopo" | Feature explícita do produto para padronizar frontends | Manter SPA flat impede reuso e cache CI prometidos na spec |
| 3 pacotes internos + 1 app | Separar UI shadcn, domínio de licenças e tsconfig compartilhado | Monolito em `apps/web` não atende FR-003/SC-005 |
| Source packages (sem tsup) | Vite 8 resolve workspaces nativamente com `optimizeDeps` | Build dual (lib + app) aumenta risco de regressão na migração inicial |

## Phase 0 — Research Summary

Ver [research.md](./research.md) para decisões detalhadas. Principais escolhas:

- **npm workspaces** na raiz de `ci-client-v2` (alinhado ao ecossistema npm do repo)
- **Turborepo 2.x** com pipeline `build`, `dev`, `lint`, `typecheck`
- **Source-first packages** — libs sem `dist/` próprio; app `@ci/web` produz artefato deployável
- **Tailwind v4 `@source`** no CSS do app incluindo paths de `packages/ui`
- **Migração incremental**: mover app → extrair `@ci/ui` → extrair `@ci/domain` → atualizar imports → validar

## Phase 1 — Design Artifacts

| Artefato | Caminho | Conteúdo |
|----------|---------|----------|
| Data model | [data-model.md](./data-model.md) | Pacotes, tarefas, grafo de dependências |
| Workspace contract | [contracts/workspace-packages.md](./contracts/workspace-packages.md) | Exports, naming, dependências permitidas |
| Pipeline contract | [contracts/turbo-pipeline.md](./contracts/turbo-pipeline.md) | Tasks Turbo e ordem de execução |
| Env contract | [contracts/vite-env.md](./contracts/vite-env.md) | Variáveis `VITE_*` inalteradas |
| Quickstart | [quickstart.md](./quickstart.md) | Cenários de validação end-to-end |

## Implementation Strategy (for `/speckit-tasks`)

### Milestone 1 — Scaffold (P3 foundation)

1. Criar `package.json` raiz com `workspaces: ["apps/*", "packages/*"]`
2. Adicionar `turbo.json`, `.gitignore` (`.turbo/`, `dist/`)
3. Criar `@ci/typescript-config` e propagar tsconfigs
4. Mover código atual para `apps/web/` sem alterar comportamento
5. Scripts raiz: `dev`, `build`, `lint`, `typecheck` via `turbo run`

### Milestone 2 — Extração `@ci/ui` (P2)

1. Migrar `src/components/ui/*` e `lib/utils.ts` para `packages/ui`
2. Configurar `components.json` em ambos os pacotes
3. Atualizar imports no app: `@ci/ui/button`, etc.
4. Ajustar `index.css` com `@source` para classes em `packages/ui`

### Milestone 3 — Extração `@ci/domain` (P2 + SC-005)

1. Migrar `types/screen.ts` e `lib/licenses.ts` para `packages/domain`
2. App importa `@ci/domain` — remover duplicatas
3. Validar telas por licença (Carvalho, Pau-Brasil, Jatobá, Cedro)

### Milestone 4 — Validação e docs (P1 + FR-008)

1. Executar quickstart.md completo
2. Medir cache Turbo (2 builds consecutivos)
3. Atualizar `ci-client-v2/README.md`
4. Amendment constituição: Turborepo frontend **adotado**
5. Atualizar `specify-rules.mdc` / agent context (comandos monorepo)

### Vite configuration notes (`apps/web/vite.config.ts`)

```typescript
// Resolução de workspaces + HMR cross-package
resolve: {
  dedupe: ['react', 'react-dom'],
},
server: {
  fs: { allow: ['../..'] },
},
optimizeDeps: {
  include: ['@ci/ui', '@ci/domain'],
},
```

### Root `turbo.json` (referência)

```json
{
  "$schema": "https://turbo.build/schema.json",
  "tasks": {
    "build": {
      "dependsOn": ["^typecheck"],
      "outputs": ["dist/**"]
    },
    "dev": {
      "cache": false,
      "persistent": true
    },
    "lint": {},
    "typecheck": {
      "dependsOn": ["^typecheck"]
    }
  }
}
```

## Risks & Mitigations

| Risco | Mitigação |
|-------|-----------|
| Tailwind não gera classes de pacotes | `@source` explícito em `apps/web/src/index.css` |
| HMR quebrado entre packages | `server.fs.allow` + dedupe React |
| Imports `@/` quebrados pós-migração | Codemod incremental; typecheck como gate |
| shadcn CLI paths | `components.json` por pacote com aliases corretos |
| Cache Turbo inválido | `outputs` corretos; documentar `turbo run build --force` |

## Next Step

Executar **`/speckit-tasks`** para gerar `tasks.md` acionável a partir deste plano.
