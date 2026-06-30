# Contract: Client UI — Identidade visual do tenant

**Feature**: 025-tenant-branding-config  
**App**: `@ci/web` (`sci-client-monorepo/apps/web`)  
**References**: [rest-api-tenant-branding.md](./rest-api-tenant-branding.md) · [data-model.md](../data-model.md)

## Screen registry

| Campo | Valor |
|-------|-------|
| `screenId` | `admin-plataforma-config` |
| `path` | `/administracao/plataforma/config` |
| `title` | Configurações da instituição |
| `module` | `administracao` |
| `type` | `admin` |
| `customDashboard` | `platform-tenant-config` |
| `licenses` | `['base']` |

## Navigation

Grupo **Administrador Plataforma** (`adminScope: 'platform'`):

```text
Setores → Usuários → Configurações → Meu perfil
```

## Access control (client)

- Adicionar `admin-plataforma-config` a `PLATFORM_SCREENS` em `permissions.ts`
- `checkAdminScreenAccess` → `canAccessPlatformAdmin` (mesmo que setores/usuários)
- `AccessDenied403` variant `admin` + `platform_only` quando negado

## Component: `PlatformTenantConfigPanel`

**Local**: `modules/tenant/components/PlatformTenantConfigPanel.tsx`

### Layout

| Seção | Conteúdo |
|-------|----------|
| Header | Título + descrição curta (“Identidade visual exibida na área global”) |
| Foto institucional | Preview circular; botão alterar; botão remover (se existir) |
| Banner | Preview retangular (~aspect 4:1); botão alterar; botão remover |
| Status | Banner sucesso/erro (padrão `PlatformProfilePanel`) |
| Ações | Salvar implícito por upload (presign flow) ou botão “Aplicar” após preview |

### Upload UX (espelho `PlatformProfilePanel`)

| Constante | Valor |
|-----------|-------|
| `ACCEPTED_TYPES` | `image/jpeg`, `image/png` |
| `MAX_AVATAR_BYTES` | 5 × 1024 × 1024 |
| `MAX_BANNER_BYTES` | 10 × 1024 × 1024 |

**Mensagens canônicas**:

| Situação | Copy |
|----------|------|
| Sucesso | Identidade visual atualizada. |
| MIME inválido | Apenas arquivos JPEG ou PNG são permitidos. |
| Tamanho foto | A imagem não pode ultrapassar 5 MB. |
| Tamanho banner | O banner não pode ultrapassar 10 MB. |
| Erro rede | Não foi possível enviar a imagem. Tente novamente. |

### API module

`modules/tenant/api/branding.ts`:

```typescript
getTenantBranding(): Promise<TenantBranding>
updateTenantBranding(body: Partial<{ avatarStorageKey: string | null; bannerStorageKey: string | null }>): Promise<TenantBranding>
presignTenantAvatar(mimeType: string): Promise<PresignResult>
presignTenantBanner(mimeType: string): Promise<PresignResult>
uploadToPresignedUrl(uploadUrl: string, file: File): Promise<void>
```

## Hook: `useTenantBranding`

**Local**: `modules/tenant/hooks/useTenantBranding.ts`

| Retorno | Descrição |
|---------|-----------|
| `branding` | `TenantBranding \| undefined` |
| `loading` | boolean |
| `error` | string \| undefined |
| `refetch` | () => void |

- Usado em `PlatformTenantConfigPanel` e `GlobalWelcomeDashboard`
- Mock mode (`VITE_USE_API=false`): retornar fallback estático ou localStorage opcional — **mínimo**: placeholders sem imagens hardcoded externas

## `GlobalWelcomeDashboard` changes

Substituir:

```tsx
style={{ backgroundImage: "url('/careiro-banner.png')" }}
src="/careiro-varzea-prefeitura.jpg"
```

Por:

- `branding.bannerUrl` com fallback gradiente Mint
- `branding.avatarUrl` com fallback iniciais de `branding.name`
- Texto do nome: `branding.name`

Manter gradient overlay e accent line existentes.

## `ScreenPage` wiring

```tsx
screen.customDashboard === 'platform-tenant-config' && <PlatformTenantConfigPanel />
```

## Design tokens

Seguir `mint-palette.mdc` e skill `ui-ux-pro-max` — preview banner com `rounded-2xl`, borda `border-border/60`, accent `#2DD4BF`.

## Fora de escopo

- Crop/recorte interativo de imagem (v2)
- Upload via `@ci/admin-saas`
- Sidebar logo global (reuso futuro do mesmo hook)
