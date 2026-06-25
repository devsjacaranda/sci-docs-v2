# Contract: Vite Environment & Deploy

**Feature**: 001-client-turborepo  
**Version**: 1.0.0  
**Scope**: Variáveis de ambiente e artefato de deploy de `@ci/web`

## Environment files

| Location | Purpose |
|----------|---------|
| `apps/web/.env` | Variáveis locais (gitignored) |
| `apps/web/.env.example` | Template documentado |
| `apps/web/.env.production` | Overrides produção (se existir) |

**Rules (FR-009)**:

- Prefixo MUST remain **`VITE_`** for client-exposed variables
- Vite loads env from **`apps/web/`** cwd (not monorepo root)
- NO renaming of existing variables during migration
- Secrets MUST NOT use `VITE_` prefix

## Current variables (preserve)

Migrar `.env` e `.env.example` existentes de `ci-client-v2/` para `apps/web/` sem alterar keys.

Example pattern (if present):

```env
VITE_API_URL=http://localhost:3000
```

## Build output

| Field | Value |
|-------|-------|
| Package | `@ci/web` |
| Output directory | `apps/web/dist/` |
| Entry | `apps/web/index.html` |
| Assets | `apps/web/dist/assets/` |

**Deploy contract**:

- Host MUST serve `index.html` for SPA rewrites (unchanged from pre-migration)
- Static files from `dist/assets/` with immutable cache headers
- `index.html` with no-cache (per vite-react-best-practices)

## Turbo build path

From monorepo root:

```bash
cd ci-client-v2
npm run build
# artifact: apps/web/dist/
```

CI/CD scripts referencing `ci-client-v2/dist/` MUST update to `ci-client-v2/apps/web/dist/` — document in README migration notes.

## Preview

```bash
cd ci-client-v2
npm run build
npm run preview --workspace=@ci/web
# or: cd apps/web && npm run preview
```

Preview MUST serve the same routes as pre-migration dev server.
