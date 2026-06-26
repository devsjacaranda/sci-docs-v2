# Research: Gerenciamento de Usuários e Setores — Gabinete

**Feature**: 017-gabinete-usuarios-setores-crud · **Date**: 2026-06-25

## R1 — Autorização API (Gabinete vs Plataforma)

**Decision**: Guard único `InstitutionalAdminGuard` aplicado em rotas `/users` e `/setores` com duas políticas derivadas do path ou metadata:

| Contexto | Permitido |
|----------|-----------|
| Gabinete (default tenant routes) | Membro de setor autorizado em `ModuloSetor` para `gabinete` **OU** `admin_tenant` **OU** `admin_plataforma` |
| Plataforma (mesmas rotas, bypass via role) | `admin_tenant` **OU** `admin_plataforma` |

Implementação: reutilizar `CheckModuloAccessUseCase` com `moduloSlug = gabinete` para usuários `user`/`chefe_setor`; bypass em `isBypassRole` já existente para admins.

**Rationale**: Alinha FR-005/FR-006 à pipeline existente (`ModuloPermissaoGuard` pattern) sem duplicar lógica de setor↔módulo.

**Alternatives considered**:

- Rotas separadas `/gabinete/users` — rejeitado: duplicaria CRUD e divergiria da Plataforma
- `@Roles(admin_plataforma)` only — rejeitado: não atende FR-005

---

## R2 — Licenças e Base

**Decision**: Rotas **sem** `@RequireLicenca`. Client: `licenses: ['base']` nos screens; `showStats` do shell **desligado** para type `admin` custom panels; KPI cards **locais** (contagens operacionais), nunca stats de Carvalho/Cedro/Jatobá/Pau-Brasil.

**Rationale**: [licenca-contracts](../../../.cursor/skills/licenca-contracts/SKILL.md) — Base não é licença; FR-003 proíbe badges premium.

**Alternatives considered**:

- Reutilizar `StatGrid` global do screen config — rejeitado: pode puxar licenças do screen metadata

---

## R3 — Soft delete e restaurar

**Decision**:

- **Inativar** = `prisma.*.delete()` (extension grava `deletedAt`)
- **Restaurar** = `prisma.*.update({ data: { deletedAt: null } })` em repository dedicado com `findFirst({ where: { id, deletedAt: { not: null } } })` (filtro explícito bypassa default `deletedAt: null`)

**Rationale**: Extension já implementada em [`prisma.extensions.ts`](../../../ci-api-v2/src/infrastructure/prisma/prisma.extensions.ts); login já exige `deletedAt: null` ([`auth.service.ts`](../../../ci-api-v2/src/modules/auth/auth.service.ts)).

**Alternatives considered**:

- Campo `active: boolean` em User — rejeitado: schema já usa soft delete canônico

---

## R4 — Paginação (API + client)

**Decision**: Paginação **server-side** espelhando Ouvidoria:

- Query: `page` (default 1), `limit` (default 20, max 100), `q` (busca), `status` (`active` | `inactive` | `all`)
- Response: `{ items, page, limit, total }`
- Client: `InstitutionalPagination` (clone de `GabinetePagination` / `OuvidoriaPagination`) bound à resposta API
- **Client-side slice** (`paginateClient`) apenas em testes ou fallback MSW mock offline — produção sempre API paginada

**Rationale**: SC-002 e tenants com centenas de usuários; padrão já provado em [`list-manifestacoes.use-case.ts`](../../../ci-api-v2/src/modules/ouvidoria/use-cases/list-manifestacoes.use-case.ts).

**Alternatives considered**:

- Só client-side — rejeitado: não escala; user pediu API e client
- Cursor-based — rejeitado: desnecessário para volume esperado (< 2k users/tenant)

---

## R5 — UI / Design system

**Decision**: Extrair padrão Gabinete cadastro para `modules/setor/components/institutional/`:

| Elemento | Componente | Referência existente |
|----------|------------|---------------------|
| Breadcrumb | `InstitutionalListLayout` + `ScreenBreadcrumb` | `GabineteCadastroLayout` |
| KPI cards | `InstitutionalStatGrid` | `GabineteStatGrid` |
| Botão criar | `InstitutionalListHeader` | `GabineteListPageHeader` (dialog mode: `onCreateClick`) |
| Filtros | `InstitutionalFiltersCard` | `GabineteFiltersCard` |
| Tabela | `InstitutionalTableCard` | `GabineteTableCard` + `DataViewShell` mobile |
| Paginação | `InstitutionalPagination` | `GabinetePagination` |

Paleta Mint: CTA `#0F766E` / dark `#2DD4BF`; cards `border-[#1E293B]/10` / dark `bg-[#1E293B]/40`.

**Rationale**: User request + paridade visual com listas Gabinete/Ouvidoria; [ui-ux-pro-max](../../../.cursor/skills/ui-ux-pro-max/SKILL.md).

**Alternatives considered**:

- Manter `PlatformUsersPanel` monolítico — rejeitado: não atende design system completo nem rotas Gabinete

---

## R6 — Migração arquitetura API

**Decision**: Novos fluxos em `repository/` + `use-cases/`; `UserAdminService` / `SetorService` delegam ou migram incrementalmente (Constitution V + [ci-api-arquitetura](../../../.cursor/skills/ci-api-arquitetura/SKILL.md)).

**Rationale**: Módulo `setor` é legado; feature 017 adiciona operações sem big-bang refactor.

**Alternatives considered**:

- Novo módulo `institutional-admin` — rejeitado: User/Setor já vivem em `setor`

---

## R7 — Reset senha

**Decision**: `POST /users/:id/reset-password` body `{ password }` — use-case com bcrypt; separado de PATCH genérico (FR-013).

**Rationale**: Ação dedicada na UI e auditoria futura; espelha [`AdminTenantUserController`](../../../ci-api-v2/src/modules/admin-plataforma/admin-tenant-user.controller.ts) SaaS pattern.

---

## R8 — Regras de negócio críticas

**Decision**:

- Role allowlist em create/update: `user` | `chefe_setor` only (Zod `.refine`)
- Inativar self → `ForbiddenException`
- Inativar último `admin_tenant`/`admin_plataforma` → `ForbiddenException`
- Sigla setor unique per tenant (case-insensitive) — validação use-case
- E-mail unique per tenant including soft-deleted check on create

**Rationale**: Edge cases da spec; testáveis em use-cases isolados (TDD).
