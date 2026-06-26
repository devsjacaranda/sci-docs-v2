# Contract: Client UI — Admin SaaS App

**Feature**: 011-super-admin-saas-app  
**App**: `@ci/admin-saas` (`ci-client-v2/apps/admin-saas`)  
**References**: [rest-api-admin-plataforma.md](./rest-api-admin-plataforma.md) · [data-model.md](../data-model.md) · `mint-palette.mdc` · `regras-plataforma.md`

## App identity

| Item | Valor |
|------|-------|
| Package | `@ci/admin-saas` |
| Dev port | `5174` |
| API base | `VITE_API_URL` (sem `X-Tenant-ID`) |
| Público | Operadores super admin SaaS apenas |

## Rotas

| Rota | Página | Auth | Descrição |
|------|--------|------|-----------|
| `/login` | `LoginPage` | Public | E-mail + senha; sem tenant |
| `/` | `DashboardPage` | Protected | Resumo + links rápidos |
| `/admins` | `AdminsListPage` | Protected | Lista super admins |
| `/admins/new` | `AdminFormPage` | Protected | Criar admin |
| `/admins/:id/edit` | `AdminFormPage` | Protected | Editar admin + reset senha |
| `/profile` | `ProfilePage` | Protected | Alterar própria senha |
| `/tenants` | `TenantsListPage` | Protected | Lista tenants |
| `/tenants/new` | `TenantFormPage` | Protected | Criar tenant |
| `/tenants/:tenantId` | `TenantDetailPage` | Protected | Detalhe + abas |
| `/tenants/:tenantId/edit` | `TenantFormPage` | Protected | Editar dados tenant |
| `/tenants/:tenantId/setores` | `TenantSetoresPage` | Protected | CRUD setores |
| `/tenants/:tenantId/users` | `TenantUsersPage` | Protected | CRUD usuários |

**Redirect**: não autenticado → `/login`; autenticado em `/login` → `/`

## Shell layout

- **Sidebar** (desktop): logo CI, nav Admins, Tenants, Perfil, Logout
- **Header**: título da seção + breadcrumb tenant quando aplicável
- **Content**: card surface `#E2E8F0` (light) / `#1E293B` (dark)
- **CTA primário**: `#0F766E` (light) / `#2DD4BF` texto `#090D16` (dark)

## Login page

| Elemento | Regra |
|----------|-------|
| Campos | E-mail, Senha (toggle visibilidade) |
| Sem tenant | NUNCA exibir seletor ou campo tenant |
| Erro auth | Mensagem genérica: *Credenciais inválidas ou conta inativa.* |
| Loading | Botão *Entrando…* disabled |

## Admins list

| Coluna | Conteúdo |
|--------|----------|
| E-mail | `email` |
| Status | Badge Ativo / Inativo |
| Ações | Editar, Resetar senha (confirmação dialog) |

**CTA**: *Novo super admin*

## Tenants list

| Coluna | Conteúdo |
|--------|----------|
| Nome | `name` |
| Slug | `slug` (mono) |
| Status | Badge Ativo / Inativo |
| Ações | Ver detalhe, Editar |

**CTA**: *Novo tenant*

## Tenant detail — abas

| Aba | Conteúdo |
|-----|----------|
| **Dados** | Nome, slug, status, datas |
| **Licenças** | 4 toggles: Carvalho, Pau-Brasil, Jatobá, Cedro |
| **Setores** | Link → `/tenants/:id/setores` ou embed list |
| **Usuários** | Link → `/tenants/:id/users` ou embed list |

**Licença inativa**: tooltip/copy — *Funcionalidades desta licença ficam indisponíveis para usuários deste tenant.*

## Setores / Usuários pages

- Header com nome do tenant (contexto explícito)
- Paridade funcional com telas `admin-plataforma-setores/usuarios` do `@ci/web` (labels PT-BR)
- Roles user (select fechado): Usuário, Chefe de setor, Administrador da plataforma
- NUNCA exibir opção super admin SaaS

## Copy canônico (vocabulário)

| Usar | Nunca |
|------|-------|
| Carvalho, Pau-Brasil, Jatobá, Cedro | variantes sem acento |
| Super admin | admin SaaS (UI secundária ok) |
| Tenant | cliente (UI) — preferir *Instituição* ou *Tenant* consistente |
| Administrador da plataforma | admin_plataforma (raw enum) |

## Auth context (client)

```typescript
interface AdminAuthState {
  accessToken: string | null;
  user: { userId: string; email: string; role: 'admin_saas' } | null;
  login(email: string, password: string): Promise<void>;
  logout(): void;
}
```

- Token: `sessionStorage` key `ci-admin-saas-token`
- API client: `Authorization: Bearer` only — **no** `X-Tenant-ID`

## Feedback UX

| Ação | Feedback |
|------|----------|
| CRUD sucesso | Toast *Operação concluída* |
| 409 conflito | Inline message com code traduzido |
| Submit | Button disabled + spinner |
| Reset senha | Dialog confirmação antes de enviar |

## Out of scope (UI v1)

- Impersonation / login as tenant user
- Billing, analytics dashboard
- Audit log viewer
- Recuperação senha por e-mail
- Dark/light toggle manual (respeitar `prefers-color-scheme` + class strategy existente em `@ci/ui`)
