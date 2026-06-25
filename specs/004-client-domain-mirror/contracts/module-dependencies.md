# Contract: Module Dependencies

**Feature**: 004-client-domain-mirror  
**Version**: 1.0.0  
**Scope**: Import graph between `apps/web/src/modules/*`

## Allowed dependency matrix

Rows = importer, Columns = importee. `✓` = allowed, `—` = not applicable, `✗` = forbidden, `(E)` = exception.

| Importer ↓ / Importee → | shell | shared | auth | address | ouvidoria | permissao | setor | tenant | audit | @ci/ui | @ci/domain |
|-------------------------|-------|--------|------|---------|-----------|-----------|-------|--------|-------|--------|------------|
| **app/router** | ✓ | ✓ | ✓ | — | ✓ | — | — | — | — | ✓ | ✓ |
| **shell** (general) | internal | ✓ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✓ | ✓ |
| **shell/ScreenPage** | internal | ✓ | ✗ | ✗ | ✗ | (E) ✓ | (E) ✓ | ✗ | (E) ✓ | ✓ | ✓ |
| **shared** | api only | internal | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✓ | ✓ |
| **auth** | api, lib | ✓ | internal | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | ✓ | ✓ |
| **address** | api | ✓ | ✗ | internal | ✗ | ✗ | ✗ | ✗ | ✗ | ✓ | ✓ |
| **ouvidoria** | api, lib | ✓ | barrel | barrel | internal | ✗ | ✗ | ✗ | ✗ | ✓ | ✓ |
| **permissao** | api | ✓ | barrel | ✗ | ✗ | internal | ✗ | ✗ | ✗ | ✓ | ✓ |
| **setor** | api | ✓ | barrel | ✗ | ✗ | ✗ | internal | ✗ | ✗ | ✓ | ✓ |
| **tenant** | — | — | — | — | — | — | — | internal | — | — | — |
| **audit** | api | ✓ | ✗ | ✗ | ✗ | ✗ | ✗ | ✗ | internal | ✓ | ✓ |

## Cross-domain rules

1. **Barrel-only**: Business → business imports MUST target `@/modules/<slug>` (index), never `@/modules/<slug>/components/...`
2. **Single explicit edge v1**: `ouvidoria` → `address` (municipios autocomplete)
3. **No back-edges**: `address` MUST NOT import `ouvidoria`
4. **Auth is upstream**: Domains needing user context MAY import `@/modules/auth` barrel (context/hooks exported)

## ESLint enforcement (v1)

Add to `apps/web/eslint.config.js`:

```javascript
{
  rules: {
    'no-restricted-imports': ['error', {
      patterns: [
        {
          group: ['@/pages/*', '@/components/*', '@/lib/*', '@/config/*', '@/context/*', '@/data/*', '@/hooks/*'],
          message: 'Legacy path — use @/modules/<domain>/...',
        },
        {
          group: ['@/modules/*/components/*', '@/modules/*/pages/*', '@/modules/*/api/*', '@/modules/*/hooks/*', '@/modules/*/lib/*'],
          message: 'Deep cross-module import — use @/modules/<slug> barrel',
        },
      ],
    }],
  },
}
```

**Exception handling**: ScreenPage deep imports are allowed within same module paths; cross-module deep imports blocked — ScreenPage uses barrels only.

## Verification script

`apps/web/scripts/verify-module-layout.ps1`:

1. Fail if any `.ts`/`.tsx` exists under legacy folders
2. Fail if `ci-api-v2/src/modules/*` slug missing in `apps/web/src/modules/` (except no frontend for pure infra API modules — all 7 current API domains must exist)
3. Print module file counts per slug

## Package dependencies (unchanged)

See [specs/001-client-turborepo/contracts/workspace-packages.md](../../001-client-turborepo/contracts/workspace-packages.md). This feature adds **intra-app** module graph only.
