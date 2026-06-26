---
description: "Task list for auth e permissão por setor (002-auth-setor-permissao)"
---

# Tasks: Autenticação e Permissão por Setor

**Input**: Design documents from `specs/002-auth-setor-permissao/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Tests**: TDD obrigatório (Constitution II + plan.md) — Jest unit/e2e na API; client typecheck + smoke manual (quickstart.md).

**Organization**: US1 e US2 são P1; US3 e US4 são P2; US5 é P3. Fases após setup e fundação.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Pode executar em paralelo (arquivos diferentes, sem dependências pendentes)
- **[Story]**: User story da spec (US1–US5)
- Caminhos relativos à raiz do repositório `ci-v2/`

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Scaffolding de módulos e constantes compartilhadas

- [X] T001 Criar enum `ModuloSlug` e constantes `OPEN_MODULES` em `ci-api-v2/src/common/constants/modulos.ts` conforme `contracts/modulo-slugs.md`
- [X] T002 [P] Criar decorator `@RequireModulo()` em `ci-api-v2/src/common/decorators/require-modulo.decorator.ts`
- [X] T003 [P] Criar esqueleto `SetorModule` em `ci-api-v2/src/modules/setor/setor.module.ts` (controller/service/schemas vazios exportáveis)
- [X] T004 [P] Criar esqueleto `PermissaoModule` em `ci-api-v2/src/modules/permissao/permissao.module.ts` (controller/service/schemas vazios exportáveis)
- [X] T005 Registrar `SetorModule` e `PermissaoModule` em `ci-api-v2/src/app.module.ts`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Schema Prisma, auth estendido, guard de módulo — **bloqueia todas as user stories**

**⚠️ CRITICAL**: Nenhuma user story começa antes desta fase

### Tests first (RED)

- [X] T006 [P] Escrever testes falhando para `ModuloPermissaoGuard` em `ci-api-v2/src/common/guards/modulo-permissao.guard.spec.ts` (bypass admin, OPEN_MODULES, interseção setor, 403 payload)
- [X] T007 [P] Escrever testes falhando para extensão JWT/login em `ci-api-v2/src/modules/auth/auth.service.spec.ts` (`setorIds[]`, `chiefOfSetorIds[]`)

### Schema & migration

- [X] T008 Adicionar `sigla` e `chefeUserId` em `ci-api-v2/prisma/schema/setor.prisma`
- [X] T009 [P] Criar `ci-api-v2/prisma/schema/user-setor.prisma` (N:N lotação)
- [X] T010 [P] Criar `ci-api-v2/prisma/schema/modulo-setor.prisma` com enum `ModuloSlug` em `ci-api-v2/prisma/schema/enums.prisma`
- [X] T011 [P] Criar `ci-api-v2/prisma/schema/permissao.prisma` (`SolicitacaoPermissao`, `NotificacaoPermissao`)
- [X] T012 Remover `setorId` de `ci-api-v2/prisma/schema/user.prisma`; adicionar relações `userSetores` e `setoresComoChefe`
- [X] T013 Registrar novos schemas em `ci-api-v2/prisma/schema/schema.prisma` e gerar migration com data migration `User.setorId` → `UserSetor`
- [X] T014 Estender soft-delete handlers em `ci-api-v2/src/infrastructure/prisma/prisma.extensions.ts` para novos modelos se aplicável

### Auth & guard (GREEN)

- [X] T015 Implementar helper `loadUserSetorContext(userId)` em `ci-api-v2/src/modules/auth/auth.service.ts` (setorIds + chiefOfSetorIds)
- [X] T016 Estender payload JWT e `JwtStrategy` em `ci-api-v2/src/modules/auth/jwt.strategy.ts` com `setorIds[]` e `chiefOfSetorIds[]`
- [X] T017 Estender `GET /auth/me` em `ci-api-v2/src/modules/auth/auth.controller.ts` e schemas Zod em `ci-api-v2/src/modules/auth/auth.schemas.ts`
- [X] T018 Implementar `ModuloPermissaoService` em `ci-api-v2/src/modules/permissao/modulo-permissao.service.ts` (regra `canAccessModulo` do data-model.md)
- [X] T019 Implementar `ModuloPermissaoGuard` em `ci-api-v2/src/common/guards/modulo-permissao.guard.ts` com payload 403 `MODULO_SETOR_DENIED` conforme `contracts/rest-api-permissions.md`
- [X] T020 Registrar `ModuloPermissaoGuard` global após `LicencaGuard` em `ci-api-v2/src/app.module.ts`
- [X] T021 Expandir `ci-api-v2/prisma/seed.ts` com setores demo (Gabinete, Jurídico, Ouvidoria…), `UserSetor` multi-setor, `ModuloSetor` (protocolo → Gabinete+Jurídico) conforme `contracts/modulo-slugs.md`
- [X] T022 Executar migration + seed e confirmar testes T006–T007 passando (`cd ci-api-v2; npm test`)

**Checkpoint**: Foundation ready — JWT com setorIds; guard funcional; seed demo

---

## Phase 3: User Story 1 — Acesso a módulo conforme setor (Priority: P1) 🎯 MVP

**Goal**: Usuário acessa módulo apenas se setor de lotação intersecta setores autorizados; admin bypass; Global/Tramitação abertos; navegação nunca oculta

**Independent Test**: Login user Patrimônio → `/protocolo/*` = 403; login user Gabinete → acesso OK; sidebar sempre mostra Protocolo (quickstart VS-002)

### Tests for User Story 1

- [X] T023 [P] [US1] Adicionar e2e em `ci-api-v2/test/app.e2e-spec.ts`: user sem setor autorizado recebe 403 com `MODULO_SETOR_DENIED` em rota `@RequireModulo('protocolo')`
- [X] T024 [P] [US1] Adicionar e2e: `admin_plataforma` bypassa restrição de setor

### Implementation for User Story 1 (API)

- [X] T025 [US1] Criar rota de exemplo protegida `@RequireModulo('protocolo')` em controller de domínio ou `ci-api-v2/src/modules/permissao/permissao.controller.ts` (`GET /permissoes/check/:moduloSlug`) para testes
- [X] T026 [US1] Implementar `GET /permissoes/modulos/:moduloSlug/access` retornando `{ allowed, authorizedSetores? }` em `ci-api-v2/src/modules/permissao/permissao.controller.ts` + Zod schemas

### Implementation for User Story 1 (Client)

- [X] T027 [P] [US1] Criar client API helper em `ci-client-v2/apps/web/src/lib/api-client.ts` (fetch com JWT + `X-Tenant-ID`)
- [X] T028 [US1] Substituir `mockLogin` por login REST em `ci-client-v2/apps/web/src/lib/auth.ts` chamando `POST /auth/login`
- [X] T029 [US1] Atualizar `AuthContext` em `ci-client-v2/apps/web/src/context/AuthContext.tsx` para carregar `setorIds[]`, `chiefOfSetorIds[]`, `isPlatformAdmin` de `/auth/me`
- [X] T030 [US1] Refatorar `checkModuleAccess` em `ci-client-v2/apps/web/src/lib/permissions.ts` para usar dados do user API (interseção OR multi-setor) mantendo `OPEN_MODULES`
- [X] T031 [US1] Garantir `ScreenPage` em `ci-client-v2/apps/web/src/pages/ScreenPage.tsx` renderiza conteúdo quando `allowed` e **não** oculta rotas na sidebar (`AppSidebar` / `apps/web/src/components/layout/AppSidebar.tsx`)
- [ ] T032 [US1] Smoke manual VS-002: user Patrimônio 403 vs user Gabinete OK em Protocolo Virtual

**Checkpoint**: MVP — controle de acesso por setor funcional end-to-end (API + client gate)

---

## Phase 4: User Story 2 — Tela 403 com solicitação ao líder (Priority: P1)

**Goal**: Copy canônica 403; botão **Pedir permissão**; notify **todos** os chefes; deduplicação na sessão

**Independent Test**: User bloqueado vê 403 com Gabinete/Jurídico e líderes; solicitação cria 2 notificações (quickstart VS-003, VS-004)

### Tests for User Story 2

- [X] T033 [P] [US2] Testes unitários `PermissaoSolicitacaoService` em `ci-api-v2/src/modules/permissao/permissao-solicitacao.service.spec.ts` (N notificações, dedup, sem alterar vínculos FR-016)
- [X] T034 [P] [US2] E2e `POST /permissoes/solicitacoes` em `ci-api-v2/test/app.e2e-spec.ts` retorna `notificacoesCriadas: 2` para protocolo

### Implementation for User Story 2 (API)

- [X] T035 [US2] Implementar `PermissaoSolicitacaoService` em `ci-api-v2/src/modules/permissao/permissao-solicitacao.service.ts` (criar SolicitacaoPermissao + NotificacaoPermissao por setor vinculado)
- [X] T036 [US2] Implementar `POST /permissoes/solicitacoes` com Zod body em `ci-api-v2/src/modules/permissao/permissao.schemas.ts` e `permissao.controller.ts`
- [X] T037 [US2] Enriquecer resposta 403 do guard com `authorizedSetores[{ id, name, chiefName }]` via `ModuloPermissaoService`

### Implementation for User Story 2 (Client)

- [X] T038 [US2] Atualizar `AccessDenied403` em `ci-client-v2/apps/web/src/components/admin/AccessDenied403.tsx` para copy canônica e lista multi-líder (`sectorLeaders`) conforme `contracts/client-permission-ui.md`
- [X] T039 [US2] Refatorar `requestModulePermission` em `ci-client-v2/apps/web/src/lib/permissions.ts` para `POST /permissoes/solicitacoes` e exibir **todos** chefes notificados
- [X] T040 [US2] Implementar estado sessão "solicitação já enviada" em `AccessDenied403.tsx` (sem reenvio duplicado)
- [X] T041 [US2] Wire `ScreenPage.tsx` para passar `requiredSectorLabels` e `sectorLeaders` do payload 403 ou endpoint access check

**Checkpoint**: Fluxo 403 + solicitação multi-chefe completo

---

## Phase 5: User Story 3 — Administração vínculos módulo–setor (Priority: P2)

**Goal**: Admin plataforma configura setores autorizados por módulo; módulo sem vínculo = aberto; Global/Tramitação não configuráveis

**Independent Test**: Admin altera vínculos Protocolo → user Patrimônio passa a acessar (quickstart VS-006)

### Tests for User Story 3

- [X] T042 [P] [US3] Testes `PermissaoVinculoService` em `ci-api-v2/src/modules/permissao/permissao-vinculo.service.spec.ts` (PUT substitui lista, empty = aberto, reject global/tramitacao)

### Implementation for User Story 3 (API)

- [X] T043 [US3] Implementar `PermissaoVinculoService` em `ci-api-v2/src/modules/permissao/permissao-vinculo.service.ts`
- [X] T044 [US3] Implementar `GET /permissoes/modulos` e `PUT /permissoes/modulos/:moduloSlug` em `ci-api-v2/src/modules/permissao/permissao.controller.ts` com `@Roles(admin_plataforma)`
- [X] T045 [US3] E2e: user comum recebe 403 em `PUT /permissoes/modulos/protocolo`

### Implementation for User Story 3 (Client)

- [X] T046 [US3] Conectar `ModuleSectorBindingsPanel` em `ci-client-v2/apps/web/src/components/admin/ModuleSectorBindingsPanel.tsx` à API `GET/PUT /permissoes/modulos`
- [X] T047 [US3] Garantir tela admin vínculos visível mas 403 para não-admin (`checkAdminScreenAccess` + `AccessDenied403` variant admin)

**Checkpoint**: Gestão de vínculos módulo–setor operacional

---

## Phase 6: User Story 4 — Cadastro usuário vinculado a setor(es) (Priority: P2)

**Goal**: Admin cadastra/edita usuários com ≥1 setor; permissões refletem nova lotação; chefe vê membros do setor

**Independent Test**: Criar user em Gabinete+Ouvidoria → acesso a módulos de ambos setores (spec US4)

### Tests for User Story 4

- [X] T048 [P] [US4] Testes `SetorService` e `UserAdminService` em `ci-api-v2/src/modules/setor/setor.service.spec.ts` e `ci-api-v2/src/modules/setor/user-admin.service.spec.ts` (≥1 setor, tenant isolation)

### Implementation for User Story 4 (API)

- [X] T049 [US4] Implementar `SetorService` CRUD em `ci-api-v2/src/modules/setor/setor.service.ts` + Zod schemas em `ci-api-v2/src/modules/setor/setor.schemas.ts`
- [X] T050 [US4] Implementar `GET/POST/PATCH/DELETE /setores` em `ci-api-v2/src/modules/setor/setor.controller.ts` (`@Roles(admin_plataforma)`)
- [X] T051 [US4] Implementar `UserAdminService` em `ci-api-v2/src/modules/setor/user-admin.service.ts` (create/update com `setorIds[]`, validar ≥1 setor FR-002)
- [X] T052 [US4] Implementar `GET/POST/PATCH /users` em `ci-api-v2/src/modules/setor/user-admin.controller.ts` ou sub-rotas em `setor.controller.ts`
- [X] T053 [US4] Implementar `GET /setores/:id/membros` filtrado por lotação (`@Roles` chefe do setor ou admin)

### Implementation for User Story 4 (Client)

- [X] T054 [P] [US4] Conectar `PlatformSectorsPanel` em `ci-client-v2/apps/web/src/components/admin/PlatformSectorsPanel.tsx` à API `/setores`
- [X] T055 [P] [US4] Conectar `PlatformUsersPanel` em `ci-client-v2/apps/web/src/components/admin/PlatformUsersPanel.tsx` à API `/users` com seleção multi-setor
- [X] T056 [US4] Conectar `SectorMembersPanel` em `ci-client-v2/apps/web/src/components/admin/SectorMembersPanel.tsx` à API `/setores/:id/membros`

**Checkpoint**: CRUD setores e usuários multi-setor integrado

---

## Phase 7: User Story 5 — Chefia recebe solicitações (Priority: P3)

**Goal**: Chefe vê notificações de solicitação dos setores que lidera; marca como lida; user comum bloqueado

**Independent Test**: Após solicitação US2, cada chefe vê notificação com solicitante+módulo (quickstart VS-004 step 2-3)

### Tests for User Story 5

- [X] T057 [P] [US5] Testes `NotificacaoService` em `ci-api-v2/src/modules/permissao/notificacao.service.spec.ts` (filtro por chiefOfSetorIds, mark read)

### Implementation for User Story 5 (API)

- [X] T058 [US5] Implementar `NotificacaoService` em `ci-api-v2/src/modules/permissao/notificacao.service.ts`
- [X] T059 [US5] Implementar `GET /permissoes/notificacoes` e `PATCH /permissoes/notificacoes/:id/read` em `ci-api-v2/src/modules/permissao/permissao.controller.ts`
- [X] T060 [US5] E2e: chefe Gabinete vê notificação; user comum recebe 403 em `GET /permissoes/notificacoes`

### Implementation for User Story 5 (Client)

- [X] T061 [US5] Conectar `AdminNotificationsPanel` em `ci-client-v2/apps/web/src/components/admin/AdminNotificationsPanel.tsx` à API de notificações (substituir `sessionStorage` de `admin-mock.ts`)
- [X] T062 [US5] Remover ou deprecar fluxos de notificação em `ci-client-v2/apps/web/src/data/admin-mock.ts` (`appendNotification`, `loadNotifications`) mantendo tipos até migração completa

**Checkpoint**: Ciclo notify-only fechado para chefia

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Validação final, limpeza mock, documentação

- [X] T063 [P] Atualizar `ci-api-v2/CONTEXT.md` com vocabulário setor, ModuloSlug, pipeline guard `ModuloPermissaoGuard`
- [X] T064 [P] Adicionar `VITE_API_URL` em `ci-client-v2/apps/web/.env.example` se ausente e documentar em plan/contracts
- [X] T065 Executar `cd ci-api-v2; npm test` — suite completa verde
- [X] T066 Executar `cd ci-client-v2; npm run typecheck` — zero erros
- [ ] T067 Executar cenários `specs/002-auth-setor-permissao/quickstart.md` VS-001 a VS-008 e registrar resultados
- [ ] T068 Remover dependências restantes de mock auth em `ci-client-v2/apps/web/src/lib/auth.ts` e `LoginPage.tsx` (credenciais demo apontando para seed)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Sem dependências — iniciar imediatamente
- **Foundational (Phase 2)**: Depende de Phase 1 — **BLOQUEIA** todas as user stories
- **US1 (Phase 3)**: Depende de Phase 2 — MVP
- **US2 (Phase 4)**: Depende de US1 (403 pressupõe bloqueio funcionando)
- **US3 (Phase 5)**: Depende de Phase 2; integração client pode paralelizar com US1/US2 após T044
- **US4 (Phase 6)**: Depende de Phase 2 (schema Setor/UserSetor); client panels após T050
- **US5 (Phase 7)**: Depende de US2 (notificações criadas por solicitação)
- **Polish (Phase 8)**: Depende de US1–US5 desejadas

### User Story Dependencies

| Story | Depende de | Independente quando |
|-------|------------|---------------------|
| US1 | Foundational | Guard + client gate validados |
| US2 | US1 | 403 + POST solicitação |
| US3 | Foundational | API vínculos testável sem US2 |
| US4 | Foundational | CRUD users/setores testável via API |
| US5 | US2 | Notificações existem no banco |

### Parallel Opportunities

- **Phase 1**: T002, T003, T004 em paralelo
- **Phase 2**: T006+T007 paralelo; T009+T010+T011 paralelo após T008
- **US1 client**: T027 paralelo enquanto API T025–T026
- **US3 + US4 API**: Após Foundational, equipes diferentes podem trabalhar em paralelo
- **Polish**: T063+T064 paralelo

---

## Parallel Example: User Story 1

```bash
# Testes e2e em paralelo com setup client:
T023: app.e2e-spec.ts — 403 MODULO_SETOR_DENIED
T024: app.e2e-spec.ts — admin bypass
T027: api-client.ts — helper fetch

# Após T026 (endpoint access check):
T030: permissions.ts — checkModuleAccess API-driven
T031: ScreenPage.tsx — gate sem ocultar sidebar
```

---

## Parallel Example: User Story 4 + US3

```bash
# Após Phase 2 completa, duas frentes:
Dev A — US3: T042→T047 (vínculos módulo–setor)
Dev B — US4: T048→T056 (CRUD setores/usuários)
```

---

## Implementation Strategy

### MVP First (User Story 1 only)

1. Phase 1: Setup (T001–T005)
2. Phase 2: Foundational (T006–T022)
3. Phase 3: US1 (T023–T032)
4. **STOP and VALIDATE**: quickstart VS-002
5. Demo: acesso por setor sem solicitação ainda

### Incremental Delivery

1. Setup + Foundational → base pronta
2. US1 → MVP acesso por setor
3. US2 → 403 + solicitação multi-chefe
4. US3 + US4 → administração completa (paralelo possível)
5. US5 → notificações chefia
6. Polish → quickstart completo

### Suggested MVP Scope

**User Story 1** (Phase 3) após Foundational — atende FR-004, FR-005, FR-008, FR-009, FR-012 parcial (guard + client).

---

## Notes

- TDD: T006–T007 antes de T015–T019; testes US2–US5 antes de services correspondentes
- Nunca passar `tenantId` manualmente nos services — usar AsyncLocalStorage
- Validação só Zod em `*.schemas.ts`
- `chefe_setor` role ≠ chefia: notificações usam `Setor.chefeUserId`
- Commit sugerido após cada checkpoint de fase
