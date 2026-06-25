# Contract: UI — Tela 403 e Permissões (Client)

**Feature**: 002-auth-setor-permissao  
**Version**: 1.0.0  
**Component**: `ci-client-v2/apps/web/src/components/admin/AccessDenied403.tsx`

## When to render

`ScreenPage` (e rotas equivalentes) MUST:

1. Autenticar usuário (`RequireAuth`).
2. Chamar `checkModuleAccess(moduleSlug, user)` **ou** interpretar 403 da API.
3. Se `allowed === false` e `reason === 'no_sector_link'` → renderizar `AccessDenied403` variant `module`.
4. NUNCA ocultar item de navegação por setor (FR-005).

## Copy canônica (variant `module`)

| Elemento | Texto |
|----------|-------|
| Código | `403 · Acesso negado` |
| Título | `Sem permissão para {moduleLabel}` |
| Explicativo | `Este módulo está vinculado a setor(es) específico(s). Você precisa ser membro de um setor autorizado — módulos nunca ficam ocultos, apenas protegidos por permissão.` |
| Lista | Heading: `Setor(es) com acesso a este módulo` + nomes |
| Líderes | `Líder responsável:` — um nome OU lista `Setor — Nome` quando múltiplos |
| Ação secundária | `Voltar` → `navigate(-1)` |
| Ação primária | `Pedir permissão ao líder do setor` |

## Props contract

```typescript
interface AccessDenied403Props {
  moduleId: string           // ModuloSlug
  moduleLabel: string
  requiredSectorLabels: string[]
  sectorLeaders?: Array<{ sectorLabel: string; chiefName: string }>
  primaryChiefName?: string  // quando único chefe
  variant?: 'module' | 'admin'
  adminReason?: 'admin_only' | 'platform_only'
}
```

## Solicitação de permissão

`requestModulePermission(moduleId, moduleLabel)` MUST:

1. `POST /permissoes/solicitacoes` com `{ moduloSlug }`.
2. Exibir confirmação listando **todos** chefes notificados (FR-007).
3. Desabilitar reenvio na mesma sessão (edge case).

## Paleta (mint-palette rule)

- Botão primário: `#0F766E` (light) / `#2DD4BF` bg + `#090D16` text (dark)
- Card surface: `#E2E8F0` (light) / `#1E293B` (dark)

## Admin screens (unchanged behavior)

| screenId | Guard |
|----------|-------|
| `admin-plataforma-setores`, `admin-plataforma-usuarios`, `admin-vinculos` | `isPlatformAdmin` |
| `admin-membros`, `admin-notificacoes` | chefe OR platform admin |

403 variant `admin` para papéis insuficientes — não confundir com 403 de módulo.
