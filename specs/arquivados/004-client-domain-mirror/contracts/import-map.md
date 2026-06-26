# Contract: Import Map (Big Bang Migration)

**Feature**: 004-client-domain-mirror  
**Version**: 1.0.0  
**Scope**: File relocation `apps/web/src/` → `modules/`

## Admin components

| Source | Target |
|--------|--------|
| `components/admin/AccessDenied403.tsx` | `modules/shared/components/AccessDenied403.tsx` |
| `components/admin/ModuleSectorBindingsPanel.tsx` | `modules/permissao/components/ModuleSectorBindingsPanel.tsx` |
| `components/admin/AdminNotificationsPanel.tsx` | `modules/permissao/components/AdminNotificationsPanel.tsx` |
| `components/admin/PlatformUsersPanel.tsx` | `modules/setor/components/PlatformUsersPanel.tsx` |
| `components/admin/PlatformSectorsPanel.tsx` | `modules/setor/components/PlatformSectorsPanel.tsx` |
| `components/admin/SectorMembersPanel.tsx` | `modules/setor/components/SectorMembersPanel.tsx` |
| `components/admin/PlatformProfilePanel.tsx` | `modules/setor/components/PlatformProfilePanel.tsx` |

## Ouvidoria

| Source | Target |
|--------|--------|
| `pages/ouvidoria/ManifestacoesListPage.tsx` | `modules/ouvidoria/pages/ManifestacoesListPage.tsx` |
| `pages/ouvidoria/ManifestacaoWizardPage.tsx` | `modules/ouvidoria/pages/ManifestacaoWizardPage.tsx` |
| `pages/ouvidoria/ManifestacaoDetailPage.tsx` | `modules/ouvidoria/pages/ManifestacaoDetailPage.tsx` |
| `components/ouvidoria/*` | `modules/ouvidoria/components/*` |

## Auth

| Source | Target |
|--------|--------|
| `pages/LoginPage.tsx` | `modules/auth/pages/LoginPage.tsx` |
| `lib/auth.ts` | `modules/auth/api/auth.ts` |
| `context/AuthContext.tsx` | `modules/auth/context/AuthContext.tsx` |
| `components/layout/RequireAuth.tsx` | `modules/auth/components/RequireAuth.tsx` |

## Shell — layout

| Source | Target |
|--------|--------|
| `components/layout/AppShell.tsx` | `modules/shell/components/layout/AppShell.tsx` |
| `components/layout/AppSidebar.tsx` | `modules/shell/components/layout/AppSidebar.tsx` |
| `components/layout/MobileAppHeader.tsx` | `modules/shell/components/layout/MobileAppHeader.tsx` |
| `components/layout/MobileBottomNav.tsx` | `modules/shell/components/layout/MobileBottomNav.tsx` |
| `components/layout/MobileNavSheet.tsx` | `modules/shell/components/layout/MobileNavSheet.tsx` |
| `components/layout/UserMenu.tsx` | `modules/shell/components/layout/UserMenu.tsx` |
| `components/layout/ThemeToggle.tsx` | `modules/shell/components/layout/ThemeToggle.tsx` |
| `components/layout/LicenseFilterFab.tsx` | `modules/shell/components/layout/LicenseFilterFab.tsx` |

## Shell — mock (all files)

| Source | Target |
|--------|--------|
| `components/mock/*` | `modules/shell/components/mock/*` |

**Exception**: Extract `AuditLogsPanel` from `components/mock/SpecialPanels.tsx` → `modules/audit/components/AuditLogsPanel.tsx`; re-export or import in remaining `SpecialPanels.tsx`.

## Shell — config, context, data, pages, hooks

| Source | Target |
|--------|--------|
| `config/*` | `modules/shell/config/*` |
| `context/ThemeContext.tsx` | `modules/shell/context/ThemeContext.tsx` |
| `context/LicenseFilterContext.tsx` | `modules/shell/context/LicenseFilterContext.tsx` |
| `context/RecentAccessContext.tsx` | `modules/shell/context/RecentAccessContext.tsx` |
| `data/*` | `modules/shell/data/*` |
| `pages/ScreenPage.tsx` | `modules/shell/pages/ScreenPage.tsx` |
| `hooks/use-viewport.ts` | `modules/shell/hooks/use-viewport.ts` |

## Shell — lib

| Source | Target |
|--------|--------|
| `lib/api-client.ts` | `modules/shell/api/api-client.ts` |
| `lib/breadcrumbs.ts` | `modules/shell/lib/breadcrumbs.ts` |
| `lib/theme.ts` | `modules/shell/lib/theme.ts` |
| `lib/license-filter.ts` | `modules/shell/lib/license-filter.ts` |
| `lib/license-alerts.ts` | `modules/shell/lib/license-alerts.ts` |
| `lib/current-screen.ts` | `modules/shell/lib/current-screen.ts` |
| `lib/welcome-shortcuts.ts` | `modules/shell/lib/welcome-shortcuts.ts` |
| `lib/navigation-links.ts` | `modules/shell/lib/navigation-links.ts` |
| `lib/list-page.ts` | `modules/shell/lib/list-page.ts` |
| `lib/mock-action-presets.ts` | `modules/shell/lib/mock-action-presets.ts` |
| `lib/traceability.ts` | `modules/shell/lib/traceability.ts` |
| `lib/traceability-copy.ts` | `modules/shell/lib/traceability-copy.ts` |
| `lib/jatoba.ts` | `modules/shell/lib/jatoba.ts` |
| `lib/recent-access.ts` | `modules/shell/lib/recent-access.ts` |
| `lib/tramitacao-draft.ts` | `modules/shell/lib/tramitacao-draft.ts` |

## Permissao — lib + hooks

| Source | Target |
|--------|--------|
| `lib/permissions.ts` | `modules/permissao/lib/permissions.ts` |
| `hooks/useModuleAccess.ts` | `modules/permissao/hooks/useModuleAccess.ts` |

## HTTP clients (see api-client-split.md)

| Source | Target |
|--------|--------|
| `lib/admin-api.ts` | split → `modules/permissao/api/`, `modules/setor/api/` |
| `lib/ouvidoria-api.ts` | split → `modules/ouvidoria/api/`, `modules/address/api/` |

## Router (imports only)

| File | Change |
|------|--------|
| `app/router.tsx` | Update lazy imports to `@/modules/ouvidoria`, `@/modules/auth/pages/LoginPage`, `@/modules/shell/components/layout/AppShell`, etc. |

## Unchanged at src root

| File | Notes |
|------|-------|
| `main.tsx` | Update App/shell imports if needed |
| `App.tsx` | Update context/router imports |
| `index.css` | Update `@source` if paths change |
| `app/router.tsx` | Stays in `app/` |

## Post-migration: DELETE empty legacy dirs

```text
src/pages/
src/components/
src/lib/
src/config/
src/context/
src/data/
src/hooks/
```

Must contain **zero** `.ts`/`.tsx` files after migration (FR-006, SC-003).
