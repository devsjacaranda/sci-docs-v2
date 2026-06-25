# Data Model: Monorepo Frontend com Turborepo

**Feature**: 001-client-turborepo  
**Date**: 2026-06-05

> Este modelo descreve entidades **estruturais** do monorepo (não persistência de banco). Representa pacotes, tarefas e relações governadas pelos contratos em `contracts/`.

## Entity: WorkspaceRoot

Raiz do monorepo frontend (`ci-client-v2/`).

| Field | Type | Description | Validation |
|-------|------|-------------|------------|
| `name` | string | Identificador do workspace | `"ci-client-v2"` |
| `packageManager` | enum | Gerenciador | `"npm"` |
| `workspaces` | string[] | Globs de pacotes | `["apps/*", "packages/*"]` |
| `turboConfig` | path | Arquivo pipeline | `turbo.json` |

**Relationships**: contém 1..N `WorkspacePackage`

---

## Entity: WorkspacePackage

Pacote npm interno (app ou lib).

| Field | Type | Description | Validation |
|-------|------|-------------|------------|
| `name` | string | Nome npm scoped | Padrão `@ci/<slug>` |
| `path` | path | Diretório relativo à raiz | `apps/web` ou `packages/<name>` |
| `type` | enum | Papel no monorepo | `app` \| `library` \| `config` |
| `private` | boolean | Não publicável | Sempre `true` na v1 |
| `exports` | map | Entry points | Obrigatório em `library` |
| `scripts` | map | Tarefas locais | Deve incluir tasks do pipeline Turbo |

### Package instances (v1)

| name | type | path | exports principais |
|------|------|------|-------------------|
| `@ci/web` | app | `apps/web` | N/A (build → `dist/`) |
| `@ci/ui` | library | `packages/ui` | `.`, `./styles.css` |
| `@ci/domain` | library | `packages/domain` | `.` |
| `@ci/typescript-config` | config | `packages/typescript-config` | `./base.json`, etc. |

**State transitions**:

```text
[scaffold] → package.json criado, sem código
[migrated] → código movido, imports atualizados
[validated] → typecheck + lint + build (se app) passam
```

---

## Entity: PackageDependency

Aresta direcional no grafo de dependências internas.

| Field | Type | Description | Validation |
|-------|------|-------------|------------|
| `from` | ref | Pacote consumidor | WorkspacePackage.name |
| `to` | ref | Pacote fornecedor | WorkspacePackage.name |
| `kind` | enum | Tipo de dependência | `runtime` \| `dev` \| `peer` |

### Grafo v1 (permitido)

| from | to | kind |
|------|-----|------|
| `@ci/web` | `@ci/ui` | runtime |
| `@ci/web` | `@ci/domain` | runtime |
| `@ci/ui` | `@ci/typescript-config` | dev |
| `@ci/domain` | `@ci/typescript-config` | dev |
| `@ci/web` | `@ci/typescript-config` | dev |
| `@ci/ui` | `react`, `react-dom` | peer |

**Validation rules (FR-012)**:

- PROIBIDO: `@ci/domain` → `@ci/ui`
- PROIBIDO: `@ci/ui` → `@ci/web`
- PROIBIDO: qualquer ciclo no grafo
- `@ci/typescript-config` é leaf (não depende de outros `@ci/*`)

---

## Entity: TurboTask

Tarefa orquestrada pelo Turborepo.

| Field | Type | Description | Validation |
|-------|------|-------------|------------|
| `name` | string | Nome do script | `build`, `dev`, `lint`, `typecheck` |
| `cache` | boolean | Cache habilitado | `false` apenas para `dev` |
| `persistent` | boolean | Processo long-running | `true` apenas para `dev` |
| `dependsOn` | string[] | Dependências upstream | Ex.: `["^typecheck"]` |
| `outputs` | string[] | Artefatos cacheáveis | `["dist/**"]` para `build` |

### Task matrix (v1)

| Task | Packages with script | dependsOn | outputs |
|------|---------------------|-----------|---------|
| `build` | `@ci/web` only | `^typecheck` | `dist/**` |
| `dev` | `@ci/web` only | — | — |
| `lint` | all | — | — |
| `typecheck` | all | `^typecheck` | — |

---

## Entity: SharedModule

Módulo de código dentro de um pacote `library`.

| Field | Type | Description | Validation |
|-------|------|-------------|------------|
| `package` | ref | Pacote hospedeiro | `@ci/ui` ou `@ci/domain` |
| `modulePath` | path | Caminho source | Sob `src/` |
| `publicApi` | boolean | Re-exportado em index | Se `true`, estável para consumo |

### Shared modules (migração v1)

| package | modulePath | publicApi | Origem atual |
|---------|------------|-----------|--------------|
| `@ci/ui` | `src/lib/utils.ts` | yes | `apps/web/src/lib/utils.ts` |
| `@ci/ui` | `src/components/ui/*` | yes | 21 arquivos shadcn |
| `@ci/domain` | `src/types/screen.ts` | yes | `apps/web/src/types/screen.ts` |
| `@ci/domain` | `src/lib/licenses.ts` | yes | `apps/web/src/lib/licenses.ts` |

**Validation rules (FR-003, SC-005)**:

- Pelo menos 1 SharedModule em pacote `library` após migração
- Nenhum SharedModule duplicado entre app e package
- Alteração em SharedModule exige apenas rebuild/typecheck de dependentes (SC-006)

---

## Entity: DeployArtifact

Saída implantável da aplicação.

| Field | Type | Description | Validation |
|-------|------|-------------|------------|
| `app` | ref | Pacote gerador | `@ci/web` |
| `outputDir` | path | Diretório build | `apps/web/dist/` |
| `envPrefix` | string | Prefixo variáveis | `VITE_` (inalterado) |
| `spaRewrites` | boolean | Client-side routing | `true` (requer rewrites no host) |

**Relationships**: produzido por `TurboTask` `build` em `@ci/web`

---

## Entity: ValidationScenario

Cenário de aceite mapeado da spec (referência para quickstart).

| id | userStory | flows |
|----|-----------|-------|
| VS-001 | US1 P1 | login, dashboard, navegação |
| VS-002 | US1 P1 | telas por licença (4 licenças) |
| VS-003 | US1 P1 | tema claro/escuro |
| VS-004 | US2 P2 | import `@ci/ui` + `@ci/domain` compila |
| VS-005 | US3 P3 | `turbo run build` 2x (cache) |
