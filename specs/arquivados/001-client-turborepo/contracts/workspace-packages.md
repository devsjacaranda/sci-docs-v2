# Contract: Workspace Packages

**Feature**: 001-client-turborepo  
**Version**: 1.0.0  
**Scope**: Pacotes internos sob `ci-client-v2/`

## Naming

- Todo pacote interno usa scope **`@ci/`**
- Apps: `@ci/<app-name>` em `apps/<app-name>/`
- Libraries: `@ci/<lib-name>` em `packages/<lib-name>/`
- Config: `@ci/typescript-config` em `packages/typescript-config/`

## package.json requirements

### All packages

```json
{
  "private": true,
  "name": "@ci/<slug>",
  "version": "0.0.0",
  "type": "module"
}
```

### Library packages (`@ci/ui`, `@ci/domain`)

```json
{
  "exports": {
    ".": "./src/index.ts"
  },
  "scripts": {
    "typecheck": "tsc --noEmit",
    "lint": "eslint src/"
  }
}
```

**Rules**:

- MUST export via `exports` field (não deep-import de paths internos instáveis)
- MUST re-export API pública em `src/index.ts`
- MUST NOT depend on `@ci/web`
- MUST NOT create circular dependencies (FR-012)

### App package (`@ci/web`)

```json
{
  "dependencies": {
    "@ci/ui": "*",
    "@ci/domain": "*"
  },
  "scripts": {
    "dev": "vite",
    "build": "tsc -b && vite build",
    "preview": "vite preview",
    "typecheck": "tsc -b --noEmit",
    "lint": "eslint ."
  }
}
```

**Rules**:

- MUST be the only package producing `dist/` deploy artifact
- MUST resolve workspace deps via `"*"` (npm workspaces)
- MAY import from `@ci/ui` and `@ci/domain` only via package exports

## Import conventions

| Context | Pattern | Example |
|---------|---------|---------|
| App → UI | Named import from `@ci/ui` | `import { Button } from '@ci/ui'` |
| App → domain | Named import from `@ci/domain` | `import { moduleLicenseConfig } from '@ci/domain'` |
| UI internal | Relative within package | `import { cn } from '../lib/utils'` |
| App-specific | `@/` alias local | `import { AppShell } from '@/components/layout/AppShell'` |

**Prohibited**:

- `import ... from '../../../packages/ui/src/...'` (bypass exports)
- `@ci/domain` importing `@ci/ui`
- Duplicating SharedModules listed in data-model.md

## Adding a new package (convention)

1. Criar `packages/<name>/` com `package.json` `@ci/<name>`
2. Adicionar scripts `lint` e `typecheck`
3. Registrar dependência no consumidor via workspace `"*"`
4. Atualizar grafo em data-model.md se necessário
5. Documentar em `ci-client-v2/README.md`

## Peer dependencies (`@ci/ui`)

React e React DOM são **peerDependencies** de `@ci/ui`:

```json
{
  "peerDependencies": {
    "react": "^19.0.0",
    "react-dom": "^19.0.0"
  }
}
```

O app `@ci/web` fornece as versões concretas.
