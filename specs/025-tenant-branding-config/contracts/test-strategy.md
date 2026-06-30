# Contract: Test Strategy — Tenant Branding

**Feature**: 025-tenant-branding-config  
**References**: [plan.md](../plan.md) · constitution II · [rest-api-tenant-branding.md](./rest-api-tenant-branding.md)

## Princípio

TDD RED → GREEN → REFACTOR. API: Jest + Supertest. Client: Vitest + RTL + MSW 2.

## Scripts

```powershell
cd sci-api-v2
npm test -- tenant-branding
npm run prisma:migrate:dev   # aplicar migration local

cd sci-client-monorepo/apps/web
npm run test -- tenant
npm run typecheck
```

## Matriz mínima — API

| ID | Camada | Caso |
|----|--------|------|
| CT-TB-001 | unit | `get-tenant-branding` retorna URLs quando keys existem |
| CT-TB-002 | unit | `get-tenant-branding` omite URLs quando keys null |
| CT-TB-003 | unit | `presign-tenant-avatar` gera key `{tenantId}/branding/avatar.jpg` |
| CT-TB-004 | unit | `presign-tenant-banner` rejeita mimeType inválido |
| CT-TB-005 | unit | `update-tenant-branding` rejeita storageKey de outro tenant |
| CT-TB-006 | unit | `update-tenant-branding` null remove key e chama deleteObject |
| CT-TB-007 | integration | GET `/tenant/branding` 200 como `user` |
| CT-TB-008 | integration | PATCH `/tenant/branding` 403 como `user` |
| CT-TB-009 | integration | PATCH 200 como `admin_tenant` |
| CT-TB-010 | integration | POST presign 403 como `chefe_setor` |

## Matriz mínima — Client

| ID | Camada | Caso |
|----|--------|------|
| CT-UI-001 | unit | validação MIME rejeita GIF |
| CT-UI-002 | unit | validação tamanho banner > 10 MB |
| CT-UI-003 | component | `PlatformTenantConfigPanel` preview após file select |
| CT-UI-004 | component | mensagem sucesso após fluxo MSW completo |
| CT-UI-005 | component | `AccessDenied403` para non-platform-admin |
| CT-UI-006 | component | `GlobalWelcomeDashboard` exibe `bannerUrl` do hook |
| CT-UI-007 | component | fallback iniciais quando sem `avatarUrl` |
| CT-UI-008 | hook | `useTenantBranding` refetch após update |

## MSW handlers

| Método | Rota | Comportamento |
|--------|------|---------------|
| GET | `/tenant/branding` | fixture com/sem URLs |
| PATCH | `/tenant/branding` | 403 se header role mock ≠ admin |
| POST | `/tenant/branding/avatar/presign` | retorna uploadUrl stub |
| POST | `/tenant/branding/banner/presign` | idem |

## TDD order (implementação)

1. **RED** CT-TB-003, CT-TB-005 (presign + update validation)
2. **GREEN** use-cases + repository + migration
3. **RED** CT-TB-007..010 (controller integration)
4. **GREEN** controller + module wiring
5. **RED** CT-UI-001..003 (panel validation)
6. **GREEN** `PlatformTenantConfigPanel` + api module
7. **RED** CT-UI-006..007 (dashboard)
8. **GREEN** `useTenantBranding` + dashboard integration
9. **REFACTOR** extrair helper upload compartilhado com avatar pessoal se duplicação > 10 linhas

## Seed (dev)

Estender seed do tenant Jacaranda (ou equivalente) com keys stub opcionais — **não obrigatório** para passar testes.
