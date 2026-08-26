# Research: Sistema de Permissão de Telas

**Feature**: [spec.md](./spec.md) · **Date**: 2026-07-02

Todas as incertezas técnicas da spec foram resolvidas com base nos padrões já estabelecidos em `ci-api-v2/src/modules/permissao/` e `ci-api-v2/src/modules/setor/`.

## 1. Onde vive o catálogo de telas (Screen)

**Decision**: Catálogo estático em `ci-api-v2/src/common/constants/screens.ts` — array `SCREEN_CATALOG: ScreenCatalogEntry[]` com `{ id, title, moduloSlug, scope? }`, análogo a `common/constants/modulos.ts` (MODULO_SLUGS/MODULO_LABELS). **Não** é uma tabela Prisma.

**Rationale**:
- O catálogo já existe no client (`apps/web/src/modules/shell/config/screens.ts`, ~80-100 entradas) com metadados ricos de UI (columns, fields, actions) que são client-only.
- A API só precisa da fração relevante para autorização: id, título, módulo dono, e `scope` (`'platform' | 'chefia'` — herdado do padrão `NavGroup.adminScope` já usado em `navigation.ts` do client).
- `ModuloSlug` já é enum Prisma porque muda raramente (11 valores). Telas mudam a cada feature nova — usar enum Prisma exigiria migration por tela nova. Constante TS versionada no código evita esse atrito, seguindo o mesmo raciocínio de `MODULO_SLUGS`.
- `GET /screens` expõe esse catálogo; `SetorTela.screenId` e `UserTelaOverride.screenId` são `String` livres, validados em runtime contra o catálogo (`isScreenId()`, mesmo padrão de `isModuloSlug()`).

**Alternatives considered**:
- *Prisma enum `ScreenSlug`*: rejeitado — exigiria migration a cada tela nova, alto atrito.
- *Tabela `Screen` no banco com CRUD*: rejeitado — não há requisito de admin criar telas dinamicamente; telas nascem no código (nova rota, novo componente).
- *Pacote `@ci/domain` compartilhado client+API*: rejeitado nas perguntas ao usuário em favor do endpoint `GET /screens` (api-catalog) — evita acoplar build da API a um pacote TS do monorepo do client.

## 2. Modelagem de SetorTela e UserTelaOverride

**Decision**:

```prisma
model SetorTela {
  id        String   @id @default(uuid())
  tenantId  String
  setorId   String
  screenId  String
  createdAt DateTime @default(now())
  tenant    Tenant   @relation(fields: [tenantId], references: [id])
  setor     Setor    @relation(fields: [setorId], references: [id], onDelete: Cascade)

  @@unique([tenantId, setorId, screenId])
  @@index([tenantId, setorId])
}

enum TelaOverrideKind {
  grant
  deny
}

model UserTelaOverride {
  id              String            @id @default(uuid())
  tenantId        String
  userId          String
  screenId        String
  kind            TelaOverrideKind
  createdByUserId String?
  createdAt       DateTime          @default(now())
  tenant          Tenant            @relation(fields: [tenantId], references: [id])
  user            User              @relation("UserTelaOverrideTarget", fields: [userId], references: [id], onDelete: Cascade)
  createdBy       User?             @relation("UserTelaOverrideCreatedBy", fields: [createdByUserId], references: [id])

  @@unique([tenantId, userId, screenId])
  @@index([tenantId, userId])
}
```

**Rationale**:
- Espelha exatamente `ModuloSetor` (setor×módulo) e `UserSetor` (user×setor) — mesmo estilo de junction table com `@@unique`/`@@index` por tenant.
- `screenId: String` (não FK) porque o catálogo não é uma tabela — ver decisão 1.
- `kind: grant | deny` cobre os dois sentidos de override pedidos (US2, FR-008): liberar OU restringir.
- `createdByUserId String?` nullable — segue a regra `admin-tenant-user-fk`: `admin_tenant` não tem linha em `User`, então usar `resolveUserTableId()` ao gravar.
- `onDelete: Cascade` em `setorId`/`userId` — consistente com `UserSetor`/`ModuloSetor` (remove vínculo quando setor ou usuário é removido).

**Alternatives considered**:
- *Single table `TelaPermissao` com polimorfismo (setorId nullable + userId nullable)*: rejeitado — mistura dois conceitos com semânticas diferentes (baseline vs. exceção), dificulta índices e queries.
- *Override sem `kind`, sempre "grant" e setor nunca restringe*: rejeitado pela resposta do usuário (override bidirecional é requisito).

## 3. Baseline de visibilidade quando SetorTela está vazio

**Decision**: Quando um setor não tem nenhuma linha em `SetorTela`, a baseline é derivada de `ModuloSetor` — todas as telas cujo `moduloSlug` está vinculado ao setor (reuso do padrão já usado por `CheckModuloAccessUseCase`).

**Rationale**: Evita exigir que o admin configure manualmente todo setor recém-criado; reaproveita o vínculo módulo×setor que já existe (FR-007). Consistente com o mock atual (`getSectorPresetScreenIds` deriva de `moduleSectorLinks`).

## 4. Cálculo de visibilidade efetiva (`GET /me/screens`)

**Decision**: Novo `GetEffectiveScreensUseCase` compõe:

1. Bypass total se `role` ∈ `{admin_plataforma, admin_tenant, admin_saas}` → todas as telas do catálogo.
2. `setorScreens` = união, para cada `setorId` do usuário, de `SetorTela` (se existir) ou baseline derivada de `ModuloSetor` (decisão 3).
3. `openScreens` = telas cujo `moduloSlug` ∈ `OPEN_MODULES` (`global`, `tramitacao`) — sempre incluídas.
4. `chefiaScreens` = telas com `scope: 'chefia'` no catálogo, incluídas apenas se `chiefOfSetorIds.length > 0`.
5. Aplicar overrides do usuário: `resultado = (setorScreens ∪ openScreens ∪ chefiaScreens ∪ grants) \ denies`.

**Rationale**: Generaliza a lógica hoje hardcoded no client (`PLATFORM_SCREENS`, `CHEFIA_SCREENS`, `OPEN_MODULES` em `permissions.ts`) para o backend, tornando-a a fonte de verdade única. O atributo `scope` no catálogo substitui os `Set<string>` fixos do client.

**Alternatives considered**: Calcular no client a partir de `GET /screens` + `GET /setores/:id/telas` + overrides separadamente — rejeitado porque duplica lógica de composição em dois lugares (API já precisa disso para proteger rotas no futuro).

## 5. Local do novo módulo NestJS

**Decision**: Novo módulo `ci-api-v2/src/modules/tela-permissao/`, importando `PermissaoModule` (reuso de `CheckModuloAccessUseCase` para baseline) e sendo importado por `SetorModule` seria invertido — em vez disso, `TelaPermissaoModule` importa `SetorModule`? **Evitar dependência circular**: `TelaPermissaoModule` importa apenas repositórios Prisma diretos (não `SetorModule`), replicando o padrão de `FindModuloSetores` (query direta). `AppModule` registra `TelaPermissaoModule` no nível raiz.

**Rationale**: Segue a convenção 1 domínio = 1 módulo (`permissao/`, `setor/`) da constitution V. Mantém `SetorController` como está (só ganha 3 rotas novas de membros, sem novo módulo).

## 6. CRUD de membros — vincular/desvincular

**Decision**: 3 novas rotas em `SetorController` existente (não módulo novo):
- `POST /setores/:id/membros` `{ userId }` → `LinkUserToSetorUseCase` (upsert idempotente em `UserSetor`)
- `DELETE /setores/:id/membros/:userId` → `UnlinkUserFromSetorUseCase` (delete da linha `UserSetor`)
- `POST /setores/:id/membros/create-user` → delega para `CreateUserUseCase.execute({ ...body, setorIds: [id] })` já existente

**Rationale**: `CreateUserUseCase`/`UpdateUserUseCase` existentes trabalham com "replace array completo de setorIds" — inadequado para uma operação atômica de "adicionar/remover 1 vínculo" que pode ser concorrente (dois chefes vinculando membros simultaneamente). Novo par de use-cases opera direto na linha `UserSetor`, idempotente e sem race condition de replace-array.

**Autorização**: Reutiliza `assertChefiaOrAdmin()` já existente no controller (chefe do setor-alvo OU admin_tenant/admin_plataforma) — FR-018, FR-019.

## 7. De-mock do client — estratégia de migração

**Decision**: Seguir o padrão já estabelecido em `setor/api/*.ts` (`USE_API` flag + `apiFetch`):
- `admin-mock.ts` (`platformUsersSeed`, `adminSectors`, `moduleSectorLinks`, `sectorMembersSeed`) é substituído por chamadas a `fetchUsers()`, `fetchSetores()`, novo `fetchSetorTelas()`, `fetchScreenCatalog()`.
- `navigation-sector-presets.ts` e `navigation-user-access.ts` deixam de calcular localmente e passam a consumir `GET /me/screens` (para o usuário logado) e `GET /setores/:id/telas` + `GET /screens` (para o painel admin).
- `NavigationVisibilityPanel.tsx`, `MockUserPicker.tsx`, `MockSectorPicker.tsx` são renomeados sem prefixo `Mock*` (`UserPicker`, `SectorPicker`) e passam dados vindos de hooks (`useUsers`, `useSetores`) em vez de seeds importados diretamente.
- `UserSectorConflictDialog.tsx` é mantido e adaptado para consumir `GET /users/:id/tela-conflicts` em vez de `detectSectorUserConflicts()` local.
- `SectorMembersPanel.tsx` ganha `linkMember`, `unlinkMember`, `createMemberUser` chamando as 3 rotas novas, removendo `useState<SectorMember[]>` como fonte de verdade (vira apenas cache local pós-fetch).

**Rationale**: Minimiza reescrita de UI — a árvore de componentes do mock já foi desenhada para ser "WYSIWYG" (clone da sidebar real); só a camada de dados troca. Reduz risco de regressão visual.

## 8. Testes

**Decision**: Seguir `testing-conventions` (Jest, API) e Vitest (client) já em uso:
- Use-cases novos: spec unitário com Prisma mockado (`*.use-case.spec.ts`, padrão de `check-modulo-access.use-case.spec.ts` — nenhum arquivo desse nome existe ainda, seguir `replace-modulo-vinculos.use-case.spec.ts` como referência mais próxima).
- Repository: spec com Prisma test client, padrão `list-users-paginated.repository.spec.ts`.
- Controller: `setor.controller.spec.ts` estendido com os 3 novos endpoints.
- Client: Vitest com fixtures JSON para `navigation-user-access.ts`/`navigation-sector-presets.ts` (mappers), conforme skill `js-ts-data-transforms`.
