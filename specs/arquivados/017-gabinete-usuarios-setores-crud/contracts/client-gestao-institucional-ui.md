# Contract: Client UI — Gestão Institucional (Usuários e Setores)

**Feature**: 017-gabinete-usuarios-setores-crud  
**App**: `@ci/web` (`ci-client-v2/apps/web`)  
**Skills**: [ui-ux-pro-max](../../../.cursor/skills/ui-ux-pro-max/SKILL.md), [vite-react-best-practices](../../../.cursor/skills/vite-react-best-practices/SKILL.md), [mint-palette.mdc](../../../.cursor/rules/mint-palette.mdc)

## Rotas

| Rota | Page | Gate |
|------|------|------|
| `/gabinete/usuarios` | `GabineteUsuariosPage` | módulo gabinete + GAB setor **or** admin bypass |
| `/gabinete/setores` | `GabineteSetoresPage` | idem |
| `/administracao/plataforma/usuarios` | `ScreenPage` → `UsersAdminPanel` | `canAccessPlatformAdmin` |
| `/administracao/plataforma/setores` | `ScreenPage` → `SetoresAdminPanel` | idem |

Navegação Gabinete (`navigation.ts`):

```text
Gabinete (Administração)
├── … (dashboard, atos, etc.)
└── Gestão institucional
    ├── Usuários   → gabinete-usuarios
    └── Setores    → gabinete-setores
```

---

## Layout stack (design system obrigatório)

Cada página/painel **DEVE** compor nesta ordem vertical (`space-y-6`):

```
InstitutionalListLayout          ← breadcrumb (ScreenBreadcrumb)
  InstitutionalListHeader        ← título, descrição, contador, botão criar (Plus)
  InstitutionalStatGrid          ← 4 KPI cards Base (sm:2 xl:4)
  InstitutionalFiltersCard       ← filtros inline (status, busca)
  InstitutionalTableCard         ← tabela desktop + MobileDataCard
  InstitutionalPagination        ← API-driven page/limit/total
```

### Breadcrumb

- Usar `getBreadcrumbs(screen)` + `ScreenBreadcrumb`
- Exemplo Usuários Gabinete: `Início → Gabinete → Usuários`

### KPI cards (`InstitutionalStatGrid`)

- Reutilizar estilo `GabineteStatGrid`: Card com `border-[#1E293B]/10`, valor `text-2xl font-semibold`
- **Usuários**: Total | Ativos | Inativos | Chefias
- **Setores**: Total | Ativos | Inativos | Sem chefe
- Skeleton loading enquanto fetch stats/list
- **Proibido**: badges Carvalho/Cedro/Jatobá/Pau-Brasil

### Botão criar

- Primary CTA: `bg-[#0F766E] text-white dark:bg-[#2DD4BF] dark:text-[#090D16]`
- Ícone `Plus` + label *Novo usuário* / *Novo setor*
- Abre `Dialog` (não rota separada) — padrão admin existente

### Filtros (`InstitutionalFiltersCard`)

| Controle | Usuários | Setores |
|----------|----------|---------|
| Status | Select: Ativos / Inativos / Todos | idem |
| Busca | Input + botão Buscar (submit) | Input sigla/nome |
| Debounce | 300ms optional on type; submit on Buscar | idem |

Mudança de filtro → reset `page` to 1 → refetch API.

### Tabela (`InstitutionalTableCard`)

**Usuários** — colunas:

| Coluna | Content |
|--------|---------|
| Usuário | Avatar + nome + email |
| Setores | Badges sigla |
| Perfil | Badge Servidor / Chefe de setor |
| Status | Badge Ativo / Inativo |
| Ações | Menu: Editar, Resetar senha, Inativar/Restaurar |

**Setores** — colunas:

| Coluna | Content |
|--------|---------|
| Sigla | text |
| Nome | text |
| Chefe | nome ou *Sem chefe designado* |
| Membros | count |
| Status | Badge |
| Ações | Editar, Inativar/Restaurar |

Mobile: `DataViewCards` + `MobileDataCard` (existing `@ci/ui` pattern).

### Paginação

- **Produção**: `InstitutionalPagination` props from API `{ page, limit, total }`
- onPageChange → fetch with new page
- Hide when `totalPages <= 1`
- Copy: `{from}–{to} de {total}` · *Anterior* / *Próxima*

---

## Shared panels

`UsersAdminPanel` e `SetoresAdminPanel` props:

```typescript
type AdminPanelContext = 'gabinete' | 'plataforma';

interface UsersAdminPanelProps {
  context: AdminPanelContext;
  screenId: string;
}
```

- **gabinete**: full layout stack inside `GabineteModuleGate` or institutional gate
- **plataforma**: embedded in `ScreenPage` with `hideDefaultHeader` / custom layout wrapper

Paridade FR-004: **mesmo componente**, diferença só breadcrumb labels e gate.

---

## Dialogs

| Dialog | Campos |
|--------|--------|
| Criar/editar usuário | email, name, password (create only), role select, setores multi-select (ativos) |
| Resetar senha | password + confirm |
| Criar/editar setor | sigla, name, chefe select (usuários ativos) |
| Confirmar inativar | AlertDialog copy institucional |

Copy ações: **Inativar** / **Restaurar** — nunca *Excluir* como label principal.

---

## Access denied

- Componente existente `AccessDenied403` / module gate pattern
- Copy: **403 · Acesso negado** padronizada
- Nav items podem permanecer visíveis (FR-007)

---

## License filter immunity

- `checkAdminScreenAccess` + new `GABINETE_INSTITUTIONAL_SCREENS` set
- `navItemMatchesFilter`: always true for `gabinete-usuarios`, `gabinete-setores`, platform admin screens
- `ScreenPageLayout showStats={false}` for admin custom dashboards

---

## API client (`modules/setor/api/`)

```typescript
// users-admin.ts
fetchUsers(params: ListUsersQuery): Promise<PaginatedResponse<UserListItem>>
createUser(body): Promise<void>
updateUser(id, body): Promise<void>
inactivateUser(id): Promise<void>
restoreUser(id): Promise<void>
resetUserPassword(id, password): Promise<void>

// setores-admin.ts — mirror
```

React Query optional per [vite-react-best-practices]; mínimo: `useEffect` + state como Gabinete list pages.

---

## File map (implementação)

| File | Purpose |
|------|---------|
| `pages/GabineteUsuariosPage.tsx` | route page |
| `pages/GabineteSetoresPage.tsx` | route page |
| `components/institutional/*` | design system primitives |
| `components/UsersAdminPanel.tsx` | shared CRUD users |
| `components/SetoresAdminPanel.tsx` | shared CRUD setores |
| `lib/institutional-list-stats.ts` | KPI mappers |
| `shell/config/screens.ts` | register screens |
| `shell/config/navigation.ts` | Gestão institucional section |
| `permissao/lib/permissions.ts` | access checks |

---

## Lazy routes ([vite-react-best-practices])

```typescript
const GabineteUsuariosPage = lazy(() => import('@/modules/setor/pages/GabineteUsuariosPage'));
const GabineteSetoresPage = lazy(() => import('@/modules/setor/pages/GabineteSetoresPage'));
```

Register in shell router alongside existing gabinete routes.
