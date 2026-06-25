# Contract: Module Layout

**Feature**: 004-client-domain-mirror  
**Version**: 1.0.0  
**Scope**: `ci-client-v2/apps/web/src/modules/`

## Root structure

```text
src/
├── app/                    # bootstrap + router ONLY
├── main.tsx
├── App.tsx
├── index.css
└── modules/
    ├── shell/
    ├── shared/
    ├── auth/
    ├── address/
    ├── ouvidoria/
    ├── permissao/
    ├── setor/
    ├── tenant/
    └── audit/
```

## Layer rules per module kind

### Business module (`auth`, `address`, `ouvidoria`, `permissao`, `setor`, `tenant`, `audit`)

```text
modules/<slug>/
├── pages/          # optional — route screens
├── components/     # optional — domain UI
├── api/            # required if HTTP client exists
├── hooks/          # optional
├── lib/            # optional — pure utils
├── context/        # optional — React context
├── index.ts        # REQUIRED — public barrel
└── README.md       # optional — scaffold docs (tenant)
```

**Rules**:

- MUST have `index.ts` exporting public API
- MUST NOT import from another business module's internal paths
- MAY import from `@/modules/shell/api/*` (api-client), `@/modules/shared/*`, `@ci/ui`, `@ci/domain`
- Cross-domain MUST use `@/modules/<other>` barrel only

### Infrastructure module (`shell`)

```text
modules/shell/
├── pages/              # ScreenPage (composition root)
├── components/
│   ├── layout/
│   └── mock/
├── config/
├── context/
├── api/                # api-client.ts
├── hooks/
├── lib/
└── data/
```

**Rules**:

- MUST NOT import business module internals (deep paths)
- MAY import `@/modules/<business>` barrel **only from `pages/ScreenPage.tsx`**
- MUST house all mock catalog components and screen config

### Cross-domain module (`shared`)

```text
modules/shared/
├── components/
├── hooks/              # optional
├── pages/              # optional
└── ui/                 # optional — local compositions (not shadcn)
```

**Rules**:

- MUST contain only code used by 2+ business modules
- MUST NOT import business modules
- MAY import `@/modules/shell/api`, `@ci/ui`, `@ci/domain`

## Naming conventions

| Item | Pattern | Example |
|------|---------|---------|
| Module slug | kebab-case, = API module name | `ouvidoria`, `permissao` |
| Page file | PascalCase + `Page` suffix | `ManifestacoesListPage.tsx` |
| API file | kebab-case domain | `manifestacoes.ts`, `municipios.ts` |
| Component | PascalCase | `AccessDenied403.tsx` |
| Hook | `use` + PascalCase | `useModuleAccess.ts` |
| Barrel | `index.ts` at module root | `modules/ouvidoria/index.ts` |

## Decision tree: where does new code go?

```text
Is it generic shadcn/UI primitive?
  → @ci/ui (package)

Is it license type or screen type shared platform-wide?
  → @ci/domain (package)

Is it app infrastructure (layout, nav, mock catalog, theme)?
  → modules/shell/

Is it used by 2+ business domains?
  → modules/shared/

Does it map to an API domain module?
  → modules/<api-slug>/

Unsure which API domain?
  → STOP — clarify domain boundary first
```

## Adding a new domain (checklist)

1. Create module folder matching new API slug under `modules/`
2. Add layers needed (`pages/`, `components/`, `api/`, …)
3. Create `index.ts` barrel with public exports
4. Register routes in `app/router.tsx` (lazy via barrel helpers)
5. Update ESLint boundaries if new cross-domain edges needed
6. Document in `ci-client-v2/README.md`
