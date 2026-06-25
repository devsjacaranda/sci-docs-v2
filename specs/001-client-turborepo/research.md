# Research: Monorepo Frontend com Turborepo

**Feature**: 001-client-turborepo  
**Date**: 2026-06-05

## R1 — Gerenciador de pacotes e workspaces

**Decision**: npm workspaces na raiz de `ci-client-v2` (`"workspaces": ["apps/*", "packages/*"]`).

**Rationale**: O repositório CI v2 já usa npm (`package-lock.json` em `ci-api-v2` e `ci-client-v2`). A spec assume npm sem migração para pnpm/yarn. npm 10+ suporta workspaces estáveis e integra com Turborepo sem configuração extra.

**Alternatives considered**:

| Alternativa | Motivo de rejeição |
|-------------|-------------------|
| pnpm workspaces | Melhor dedupe, mas migração de lockfile fora do escopo da spec |
| Yarn Berry | Mesmo problema; equipe não usa hoje |
| Workspaces na raiz `ci-v2/` | Spec limita escopo a `ci-client-v2`; API permanece independente |

---

## R2 — Orquestrador de tarefas

**Decision**: Turborepo 2.x como devDependency na raiz de `ci-client-v2`.

**Rationale**: Requisito explícito da feature (FR-006, FR-007). Turbo oferece cache local, grafo de dependências (`^task`), e integração nativa com npm workspaces. Versão 2.x é estável e recomendada pela documentação oficial.

**Alternatives considered**:

| Alternativa | Motivo de rejeição |
|-------------|-------------------|
| nx | Mais pesado; curva de aprendizado maior para equipe pequena |
| lerna | Menos foco em cache de build moderno |
| Scripts npm manuais (`npm run -w`) | Sem cache incremental; não atende SC-004 |

---

## R3 — Layout de diretórios

**Decision**: `apps/web` (SPA) + `packages/ui` + `packages/domain` + `packages/typescript-config`.

**Rationale**:

- **`apps/web`**: convenção Turborepo para aplicações deployáveis; isola código de produto (rotas, mocks, layouts).
- **`packages/ui`**: 21 componentes shadcn em `src/components/ui/` são candidatos naturais a reuso; shadcn recomenda pacote UI em monorepos.
- **`packages/domain`**: `lib/licenses.ts` + `types/screen.ts` satisfazem SC-005 com código real já usado em múltiplas telas.
- **`packages/typescript-config`**: evita duplicação de `compilerOptions` entre app e libs.

**Alternatives considered**:

| Alternativa | Motivo de rejeição |
|-------------|-------------------|
| Flat `packages/web` only | Não atende FR-003 (pacote compartilhado) |
| `@ci/eslint-config` na v1 | Escopo extra; ESLint flat config pode ficar no app por ora |
| Extrair Nivo/charts para pacote | Baixo reuso imediato; adiar para feature futura |

---

## R4 — Estratégia de build dos pacotes internos

**Decision**: Pacotes `@ci/ui` e `@ci/domain` exportam **source TypeScript** via `package.json#exports`; apenas `@ci/web` executa `vite build`.

**Rationale**: Vite 8 transpila dependências workspace em dev e build. Evita pipeline dual (tsup + vite) na migração inicial, reduzindo risco de regressão. Turbo `build` depende de `^typecheck` upstream, não de `^build` em libs.

**Alternatives considered**:

| Alternativa | Motivo de rejeição |
|-------------|-------------------|
| tsup para cada package | Mais correto para publish externo; desnecessário (FR-004: sem registry) |
| Vite library mode | Complexidade de CSS/Tailwind compartilhado entre libs |

**Export pattern**:

```json
{
  "name": "@ci/ui",
  "exports": {
    ".": "./src/index.ts",
    "./styles.css": "./src/styles.css"
  }
}
```

---

## R5 — Tailwind v4 em monorepo

**Decision**: Manter `@tailwindcss/vite` no app; adicionar `@source` directives no CSS do app apontando para `../../packages/ui/src/**/*.{ts,tsx}`.

**Rationale**: Tailwind v4 usa detecção de conteúdo via `@source` em CSS, não `tailwind.config.js`. Sem `@source` cross-package, classes usadas em `@ci/ui` seriam purgadas no build de produção.

**Alternatives considered**:

| Alternativa | Motivo de rejeição |
|-------------|-------------------|
| Tailwind config compartilhado v3-style | Projeto usa Tailwind v4 sem config JS |
| Duplicar tokens CSS em cada pacote | Viola DRY; tokens Mint devem ser únicos |

---

## R6 — shadcn/ui em monorepo

**Decision**: Dois `components.json` — um em `packages/ui` (destino padrão do CLI) e um em `apps/web` (componentes app-specific se necessário). Aliases do pacote UI: `@ci/ui` paths internos.

**Rationale**: Documentação shadcn suporta monorepos com pacote UI dedicado. Novos componentes genéricos vão para `@ci/ui`; componentes de domínio (mock, layout) permanecem no app.

**Alternatives considered**:

| Alternativa | Motivo de rejeição |
|-------------|-------------------|
| Manter shadcn só no app | Impede FR-003; extração posterior seria segunda migração |
| Publicar `@ci/ui` no npm | Fora de escopo (spec assumption) |

---

## R7 — Naming e escopo de pacotes

**Decision**: Scope `@ci/*` para todos os pacotes internos.

**Rationale**: Alinhado ao nome do produto (CI v2); evita colisão com pacotes npm públicos; padrão comum em monorepos corporativos.

**Pacotes v1**:

| Pacote | Responsabilidade |
|--------|------------------|
| `@ci/web` | SPA deployável |
| `@ci/ui` | Componentes shadcn + `cn()` |
| `@ci/domain` | Tipos de tela, utilitários de licença |
| `@ci/typescript-config` | Bases TS compartilhadas |

**Grafo de dependências (acyclic)**:

```text
@ci/typescript-config  (leaf)
        ↑
   @ci/domain          (leaf de runtime deps)
        ↑
     @ci/ui            (depende de react, radix — peer)
        ↑
     @ci/web           (depende de ui + domain)
```

---

## R8 — Comandos raiz e DX

**Decision**:

```json
{
  "scripts": {
    "dev": "turbo run dev --filter=@ci/web",
    "build": "turbo run build",
    "lint": "turbo run lint",
    "typecheck": "turbo run typecheck",
    "clean": "turbo run clean && rimraf node_modules/.cache"
  }
}
```

**Rationale**: Atende FR-005 e SC-002 (onboarding simples). `--filter=@ci/web` no dev evita subir tarefas persistentes desnecessárias em pacotes sem servidor.

---

## R9 — Variáveis de ambiente e deploy

**Decision**: `.env` permanece em `apps/web/`; prefixo `VITE_*` inalterado; artefato em `apps/web/dist/`.

**Rationale**: FR-009 exige contrato de deploy preservado. Hospedagem estática aponta para `dist/` — path relativo ao app, não à raiz do monorepo frontend.

**Alternatives considered**:

| Alternativa | Motivo de rejeição |
|-------------|-------------------|
| `.env` na raiz de `ci-client-v2` | Vite carrega env do cwd do app por padrão; mudança quebra DX |
| Renomear para `CI_PUBLIC_*` | Viola FR-009 |

---

## R10 — Detecção de dependências circulares

**Decision**: Validar manualmente grafo documentado + falha de typecheck/build se ciclo introduzido; opcionalmente script `depcruise` na fase de implementação.

**Rationale**: FR-012 exige bloqueio explícito. Grafo v1 tem 3 níveis sem ciclos; `@ci/domain` não importa `@ci/ui`.

**Alternatives considered**:

| Alternativa | Motivo de rejeição |
|-------------|-------------------|
| dependency-cruiser obrigatório na v1 | Pode ser tarefa opcional em tasks.md se tempo permitir |

---

## R11 — Amendment da constituição

**Decision**: Na implementação, alterar seção III de `constitution.md`:

- De: `Monorepo com Turborepo (apenas frontends) — **fora de escopo até padronização futura**.`
- Para: `Monorepo Turborepo em ci-client-v2 (apps/web + packages/*) — **adotado**; ci-api-v2 permanece pacote independente.`

**Rationale**: Feature explicitamente realiza o que a constituição adiava; amendment evita conflito governance vs implementação.
