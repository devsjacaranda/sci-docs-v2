# Data Model: Arquitetura Modular Espelho da API (Client)

**Feature**: 004-client-domain-mirror  
**Date**: 2026-06-06

> Modelo de entidades **estruturais** do frontend modular (não persistência). Representa módulos, camadas, barrels e relações governadas pelos contratos em `contracts/`.

## Entity: FrontendModule

Unidade de organização em `apps/web/src/modules/<slug>/`.

| Field | Type | Description | Validation |
|-------|------|-------------|------------|
| `slug` | string | Identificador espelho API | Um de: `shell`, `shared`, `auth`, `address`, `ouvidoria`, `permissao`, `setor`, `tenant`, `audit` |
| `kind` | enum | Papel | `infrastructure` \| `cross_domain` \| `business` |
| `path` | path | Diretório | `modules/<slug>/` |
| `layers` | string[] | Subpastas ativas | Subset de `pages`, `components`, `api`, `hooks`, `lib`, `context`, `data`, `config` |
| `publicBarrel` | path \| null | Export controlado | `index.ts` obrigatório em business + shared; opcional em shell |

### Module instances (v1)

| slug | kind | layers principais | UI v1 |
|------|------|-------------------|-------|
| `shell` | infrastructure | pages, components, config, context, api, hooks, lib, data | Sim (layout, mocks, ScreenPage) |
| `shared` | cross_domain | components, hooks, pages, ui | Sim (AccessDenied403) |
| `auth` | business | pages, api, context | Sim (Login) |
| `address` | business | api | Parcial (client municipios) |
| `ouvidoria` | business | pages, components, api | Sim |
| `permissao` | business | components, api, hooks, lib | Sim (admin permissões) |
| `setor` | business | components, api | Sim (admin setores/usuários) |
| `tenant` | business | README only | Scaffold |
| `audit` | business | components | Parcial (AuditLogsPanel mock) |

**State transitions**:

```text
[scaffold] → pastas de camada criadas
[migrated] → arquivos movidos, imports atualizados
[validated] → typecheck + lint + build passam; pastas legadas vazias
```

---

## Entity: ModuleLayer

Subpasta com responsabilidade fixa dentro de um FrontendModule.

| Field | Type | Description | Validation |
|-------|------|-------------|------------|
| `name` | enum | Camada | `pages` \| `components` \| `api` \| `hooks` \| `lib` \| `context` \| `data` \| `config` |
| `module` | ref | Módulo pai | FrontendModule.slug |
| `allowedImports` | ref[] | De onde pode importar | Ver ModuleDependency |

### Layer semantics

| Layer | Responsibility | API mirror |
|-------|----------------|------------|
| `pages` | Route-level screens | — (frontend-specific) |
| `components` | UI do domínio | — |
| `api` | HTTP clients | controller (client side) |
| `hooks` | React hooks do domínio | — |
| `lib` | Utilitários puros do domínio | helpers |
| `context` | Estado React do domínio | — |
| `config` | Registros estáticos (shell only) | — |
| `data` | Fixtures/mock data (shell only) | — |

---

## Entity: ModuleDependency

Aresta direcional no grafo de imports entre módulos.

| Field | Type | Description | Validation |
|-------|------|-------------|------------|
| `from` | ref | Módulo importador | FrontendModule.slug |
| `to` | ref | Módulo importado | FrontendModule.slug ou `@ci/*` |
| `via` | enum | Forma de import | `barrel` \| `shared_path` \| `shell_internal` \| `package` |

### Grafo permitido (v1)

| from | to | via | Notas |
|------|-----|-----|-------|
| `app/router` | `shell`, `auth`, `ouvidoria` | barrel / direct pages | Registro de rotas |
| `shell` | `shared` | shared_path | Infra usa shared |
| `shell` | `permissao`, `setor`, `audit` | barrel | **Exceção**: ScreenPage only |
| `auth` | `shell` | shell_internal | api-client base |
| `auth` | `shared` | shared_path | AccessDenied403 se necessário |
| `ouvidoria` | `shell`, `shared`, `address`, `auth` | barrel/shell | address via barrel |
| `permissao` | `shell`, `shared`, `auth` | — | — |
| `setor` | `shell`, `shared`, `auth` | — | — |
| `address` | `shell` | api-client | — |
| `audit` | `shell`, `shared` | — | — |
| `tenant` | — | — | Sem imports v1 |
| `*` | `@ci/ui`, `@ci/domain` | package | UI genérica / tipos licença |

### Regras proibidas (FR-008)

- PROIBIDO: `shell` → business domain (exceto ScreenPage → barrels permissao/setor/audit)
- PROIBIDO: business A → internals de business B (deep path)
- PROIBIDO: business → `shell/components/mock` internals (usar exports shell se necessário)
- PROIBIDO: qualquer → pastas legadas `@/pages`, `@/components`, `@/lib`
- PROIBIDO: ciclo entre business modules

---

## Entity: PublicBarrel

Ponto de exportação `index.ts` de um módulo.

| Field | Type | Description | Validation |
|-------|------|-------------|------------|
| `module` | ref | FrontendModule.slug | — |
| `exports` | string[] | Símbolos públicos | Apenas API estável |
| `consumers` | ref[] | Quem importa | Cross-domain MUST use this |

---

## Entity: LegacyFolder

Pastas top-level pré-migração em `apps/web/src/`.

| Field | Type | Description | Validation |
|-------|------|-------------|------------|
| `path` | path | Pasta legada | `pages`, `components`, `lib`, `config`, `context`, `data`, `hooks` |
| `allowedFileCount` | number | Após migração | MUST be `0` |

---

## Entity: WorkspacePackage (unchanged)

Pacotes Turborepo **fora** de `modules/` — sem alteração nesta feature.

| name | path | role |
|------|------|------|
| `@ci/web` | `apps/web` | SPA deployável |
| `@ci/ui` | `packages/ui` | shadcn/ui |
| `@ci/domain` | `packages/domain` | licenças e tipos |
| `@ci/typescript-config` | `packages/typescript-config` | tsconfig bases |

---

## Validation Scenarios (VS)

| ID | Validates | Command / Action |
|----|-----------|------------------|
| VS-001 | Zero legado | Script: nenhum `.ts`/`.tsx` em pastas LegacyFolder |
| VS-002 | Paridade slugs | Lista `ci-api-v2/src/modules/*` ⊆ `apps/web/src/modules/*` (exceto shell/shared) |
| VS-003 | Build | `npm run build` em `ci-client-v2` |
| VS-004 | Typecheck | `npm run typecheck` |
| VS-005 | Smoke ouvidoria | Fluxos spec 003 |
| VS-006 | Smoke admin | Telas platform-sectors, platform-users, bindings, notifications |
| VS-007 | Boundaries | ESLint pass sem restricted-import violations |
