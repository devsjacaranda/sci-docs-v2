---
description: "Task list for Identidade visual do tenant (025-tenant-branding-config)"
---

# Tasks: Identidade visual do tenant (foto e banner)

**Input**: Design documents from `sci-docs-v2/specs/025-tenant-branding-config/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Tests**: **Obrigatórios** — TDD (constitution II + plan.md + `contracts/test-strategy.md`): Jest use-cases/controller na API; Vitest + MSW no client.

**Organization**: US1 e US2 são P1; US3 é P2. Caminhos relativos à raiz `ci-v2-workspace/`. Módulo API `tenant/` existe mínimo; client `modules/tenant/` só tem README — criar do zero.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Pode executar em paralelo (arquivos diferentes, sem dependências pendentes)
- **[Story]**: User story da spec (US1–US3)

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Pastas, fixtures e handlers MSW para TDD

- [X] T001 [P] Criar estrutura API em `sci-api-v2/src/modules/tenant/repository/` e `sci-api-v2/src/modules/tenant/use-cases/test/` conforme plan.md
- [X] T002 [P] Criar estrutura client em `sci-client-monorepo/apps/web/src/modules/tenant/api/`, `hooks/`, `components/`, `lib/`, `__tests__/` e barrel `sci-client-monorepo/apps/web/src/modules/tenant/index.ts`
- [X] T003 [P] Criar fixture `sci-api-v2/src/modules/tenant/test/fixtures/tenant-branding-response.json` conforme `data-model.md`
- [X] T004 [P] Implementar handlers MSW em `sci-client-monorepo/apps/web/src/test/msw/handlers/tenant-branding.ts` (GET/PATCH/presign avatar/banner) e registrar em `sci-client-monorepo/apps/web/src/test/msw/handlers.ts`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Migration Prisma, schemas Zod, GET branding, wiring do módulo — **bloqueia todas as user stories**

**⚠️ CRITICAL**: Nenhuma user story começa antes desta fase

### Tests first (TDD — RED)

- [X] T005 [P] Escrever testes (RED) `tenant-branding.schemas.spec.ts` em `sci-api-v2/src/modules/tenant/tenant-branding.schemas.spec.ts` — PresignBrandingBody mimeType; UpdateTenantBrandingBody null|string
- [X] T006 [P] Escrever testes (RED) `get-tenant-branding.use-case.spec.ts` em `sci-api-v2/src/modules/tenant/use-cases/test/get-tenant-branding.use-case.spec.ts` — CT-TB-001, CT-TB-002
- [X] T007 [P] Escrever testes (RED) `tenant-branding.controller.spec.ts` em `sci-api-v2/src/modules/tenant/tenant-branding.controller.spec.ts` — GET `/tenant/branding` 200 autenticado (CT-TB-007)

### Database & schemas

- [X] T008 Adicionar `avatarStorageKey` e `bannerStorageKey` (nullable String) em `sci-api-v2/prisma/schema/tenant.prisma` e gerar migration via `npm run prisma:migrate:dev`
- [X] T009 Implementar Zod em `sci-api-v2/src/modules/tenant/tenant-branding.schemas.ts` — PresignBrandingBody, UpdateTenantBrandingBody, TenantBrandingResponse (GREEN T005)

### Repositories & read use-case

- [X] T010 [P] Implementar `find-tenant-branding.repository.ts` em `sci-api-v2/src/modules/tenant/repository/find-tenant-branding.repository.ts` — select id, name, avatarStorageKey, bannerStorageKey scoped ALS
- [X] T011 Implementar `get-tenant-branding.use-case.ts` em `sci-api-v2/src/modules/tenant/use-cases/get-tenant-branding.use-case.ts` — presign download URLs via StorageService (GREEN T006)
- [X] T012 Implementar `tenant-branding.controller.ts` em `sci-api-v2/src/modules/tenant/tenant-branding.controller.ts` — GET `/tenant/branding` (JWT any role)
- [X] T013 Atualizar `sci-api-v2/src/modules/tenant/tenant.module.ts` — import StorageModule, registrar controller, repositories e use-cases; exportar se necessário

**Checkpoint**: GET `/tenant/branding` GREEN; migration aplicada; testes T005–T007 passando

---

## Phase 3: User Story 1 — Administrador configura identidade institucional (Priority: P1) 🎯 MVP

**Goal**: Tela `/administracao/plataforma/config` — upload foto + banner com presign, preview e persistência

**Independent Test**: Admin plataforma envia foto e banner válidos → mensagem **Identidade visual atualizada.** → recarrega → previews persistem; non-admin vê AccessDenied403

### Tests for User Story 1 (TDD — RED first)

- [X] T014 [P] [US1] Escrever testes (RED) `presign-tenant-avatar.use-case.spec.ts` em `sci-api-v2/src/modules/tenant/use-cases/test/presign-tenant-avatar.use-case.spec.ts` — CT-TB-003
- [X] T015 [P] [US1] Escrever testes (RED) `presign-tenant-banner.use-case.spec.ts` em `sci-api-v2/src/modules/tenant/use-cases/test/presign-tenant-banner.use-case.spec.ts` — CT-TB-004
- [X] T016 [P] [US1] Escrever testes (RED) `update-tenant-branding.use-case.spec.ts` em `sci-api-v2/src/modules/tenant/use-cases/test/update-tenant-branding.use-case.spec.ts` — CT-TB-005 (reject foreign key)
- [X] T017 [P] [US1] Estender testes (RED) `tenant-branding.controller.spec.ts` — PATCH 403 `user`, PATCH 200 `admin_tenant`, POST presign 403 `chefe_setor` (CT-TB-008..010)
- [X] T018 [P] [US1] Escrever testes (RED) `branding-validation.test.ts` em `sci-client-monorepo/apps/web/src/modules/tenant/lib/__tests__/branding-validation.test.ts` — CT-UI-001, CT-UI-002
- [X] T019 [P] [US1] Escrever testes (RED) `PlatformTenantConfigPanel.test.tsx` em `sci-client-monorepo/apps/web/src/modules/tenant/__tests__/PlatformTenantConfigPanel.test.tsx` — CT-UI-003, CT-UI-004, CT-UI-005

### API implementation for User Story 1

- [X] T020 [P] [US1] Implementar `presign-tenant-avatar.use-case.ts` em `sci-api-v2/src/modules/tenant/use-cases/presign-tenant-avatar.use-case.ts` (GREEN T014)
- [X] T021 [P] [US1] Implementar `presign-tenant-banner.use-case.ts` em `sci-api-v2/src/modules/tenant/use-cases/presign-tenant-banner.use-case.ts` (GREEN T015)
- [X] T022 [US1] Implementar `update-tenant-branding.repository.ts` em `sci-api-v2/src/modules/tenant/repository/update-tenant-branding.repository.ts`
- [X] T023 [US1] Implementar `update-tenant-branding.use-case.ts` em `sci-api-v2/src/modules/tenant/use-cases/update-tenant-branding.use-case.ts` — validar prefix tenantId na key (GREEN T016)
- [X] T024 [US1] Estender `sci-api-v2/src/modules/tenant/tenant-branding.controller.ts` — PATCH `/tenant/branding` + POST presign avatar/banner com `@Roles(admin_plataforma, admin_tenant)` (GREEN T017)
- [X] T025 [US1] Registrar novos providers em `sci-api-v2/src/modules/tenant/tenant.module.ts`

### Client implementation for User Story 1

- [X] T026 [P] [US1] Implementar `branding-validation.ts` em `sci-client-monorepo/apps/web/src/modules/tenant/lib/branding-validation.ts` — MIME, 5 MB foto, 10 MB banner (GREEN T018)
- [X] T027 [P] [US1] Implementar `branding.ts` em `sci-client-monorepo/apps/web/src/modules/tenant/api/branding.ts` — getTenantBranding, updateTenantBranding, presign*, uploadToPresignedUrl
- [X] T028 [US1] Implementar `PlatformTenantConfigPanel.tsx` em `sci-client-monorepo/apps/web/src/modules/tenant/components/PlatformTenantConfigPanel.tsx` — preview circular + retangular; fluxo presign→PUT→PATCH; copy canônica (GREEN T019)
- [X] T029 [P] [US1] Registrar screen `admin-plataforma-config` em `sci-client-monorepo/apps/web/src/modules/shell/config/screens.ts` — path `/administracao/plataforma/config`, `customDashboard: platform-tenant-config`
- [X] T030 [P] [US1] Adicionar item **Configurações** em `sci-client-monorepo/apps/web/src/modules/shell/config/navigation.ts` — grupo Administrador Plataforma
- [X] T031 [US1] Adicionar `admin-plataforma-config` a `PLATFORM_SCREENS` em `sci-client-monorepo/apps/web/src/modules/permissao/lib/permissions.ts`
- [X] T032 [US1] Wire painel em `sci-client-monorepo/apps/web/src/modules/shell/pages/ScreenPage.tsx` — `platform-tenant-config` → `PlatformTenantConfigPanel`
- [X] T033 [US1] Exportar componentes em `sci-client-monorepo/apps/web/src/modules/tenant/index.ts`

**Checkpoint**: US1 — admin configura foto e banner end-to-end; non-admin bloqueado

---

## Phase 4: User Story 2 — Usuários veem identidade na boas-vindas global (Priority: P1)

**Goal**: `GlobalWelcomeDashboard` exibe branding do tenant (ou fallback neutro)

**Independent Test**: Usuário comum abre home global — vê banner/foto configurados ou fallback iniciais; sem imagens Careiro hardcoded

### Tests for User Story 2 (TDD — RED first)

- [X] T034 [P] [US2] Escrever testes (RED) `useTenantBranding.test.ts` em `sci-client-monorepo/apps/web/src/modules/tenant/hooks/__tests__/useTenantBranding.test.ts` — CT-UI-008
- [X] T035 [P] [US2] Escrever testes (RED) `GlobalWelcomeDashboard.branding.test.tsx` em `sci-client-monorepo/apps/web/src/modules/shell/components/mock/__tests__/GlobalWelcomeDashboard.branding.test.tsx` — CT-UI-006, CT-UI-007

### Implementation for User Story 2

- [X] T036 [US2] Implementar `useTenantBranding.ts` em `sci-client-monorepo/apps/web/src/modules/tenant/hooks/useTenantBranding.ts` — fetch GET, loading/error/refetch; mock mode fallback (GREEN T034)
- [X] T037 [US2] Refatorar `GlobalWelcomeDashboard.tsx` em `sci-client-monorepo/apps/web/src/modules/shell/components/mock/GlobalWelcomeDashboard.tsx` — consumir hook; substituir `/careiro-banner.png` e `/careiro-varzea-prefeitura.jpg`; fallback gradiente Mint + iniciais (GREEN T035)
- [X] T038 [P] [US2] Extrair helper `tenantInitials.ts` em `sci-client-monorepo/apps/web/src/modules/tenant/lib/tenant-initials.ts` se não reutilizar função existente de perfil

**Checkpoint**: US1 + US2 — identidade configurada visível para todos os usuários autenticados na boas-vindas

---

## Phase 5: User Story 3 — Administrador substitui ou remove imagens (Priority: P2)

**Goal**: Substituir foto/banner e remover com fallback correto em config + boas-vindas

**Independent Test**: Substituir só banner; remover foto — config e dashboard refletem estados distintos

### Tests for User Story 3 (TDD — RED first)

- [X] T039 [P] [US3] Estender testes (RED) `update-tenant-branding.use-case.spec.ts` — CT-TB-006: PATCH null remove key; deleteObject best-effort na key anterior
- [X] T040 [P] [US3] Estender testes (RED) `PlatformTenantConfigPanel.test.tsx` — fluxo remover banner; fluxo substituir foto
- [X] T041 [P] [US3] Estender testes (RED) `GlobalWelcomeDashboard.branding.test.tsx` — banner removido → gradiente; foto removida → iniciais

### Implementation for User Story 3

- [X] T042 [US3] Estender `update-tenant-branding.use-case.ts` — ao substituir/remover, `storage.deleteObject(oldKey)` try/catch + log (GREEN T039)
- [X] T043 [US3] Adicionar botões **Remover** foto/banner em `sci-client-monorepo/apps/web/src/modules/tenant/components/PlatformTenantConfigPanel.tsx` — PATCH `{ avatarStorageKey: null }` / `{ bannerStorageKey: null }` (GREEN T040)
- [X] T044 [US3] Garantir `useTenantBranding` refetch após update/remove para dashboard atualizar sem re-login (GREEN T041)

**Checkpoint**: US3 — ciclo completo substituir/remover com fallbacks corretos

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Refactor, typecheck e validação manual

- [X] T045 [P] Refatorar upload duplicado — extrair helper compartilhado em `sci-client-monorepo/apps/web/src/modules/tenant/lib/upload-branding-image.ts` se overlap > 10 linhas com `PlatformProfilePanel.tsx`
- [X] T046 [P] Executar `npm test -- tenant-branding` em `sci-api-v2/` e corrigir falhas
- [X] T047 [P] Executar `npm run test -- tenant` e `npm run typecheck` em `sci-client-monorepo/apps/web/` e corrigir falhas
- [X] T048 Validar manualmente cenários de `sci-docs-v2/specs/025-tenant-branding-config/quickstart.md` §3–§6
- [X] T049 [P] Atualizar `sci-client-monorepo/apps/web/src/modules/tenant/README.md` — documentar API module e hook

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Sem dependências — iniciar imediato
- **Foundational (Phase 2)**: Depende Phase 1 — **bloqueia** US1–US3
- **US1 (Phase 3)**: Depende Phase 2 — MVP admin config
- **US2 (Phase 4)**: Depende Phase 2 (GET); integração visual ideal após US1 ter dados, mas testável via MSW/fixture independente
- **US3 (Phase 5)**: Depende US1 (painel base) — estende update + UI remove
- **Polish (Phase 6)**: Depende US1–US3 desejados

### User Story Dependencies

| Story | Depende de | Independente quando |
|-------|------------|---------------------|
| US1 | Phase 2 | Admin configura e vê preview na tela config |
| US2 | Phase 2 (+ dados opcionais de US1) | MSW retorna branding — dashboard renderiza |
| US3 | US1 painel | Remove/substitui sem nova tela |

### Parallel Opportunities

- **Phase 1**: T001–T004 em paralelo
- **Phase 2 RED**: T005–T007 em paralelo
- **Phase 3 RED**: T014–T019 em paralelo
- **Phase 3 API**: T020–T021 em paralelo após repos
- **Phase 3 Client shell**: T029–T030 em paralelo
- **Phase 4**: T034–T035 RED em paralelo; T038 paralelo a T37
- **Phase 5**: T039–T041 RED em paralelo
- **Phase 6**: T045–T047, T049 em paralelo

### Parallel Example: User Story 1 (API)

```bash
# Tests RED em paralelo:
T014 presign-tenant-avatar.use-case.spec.ts
T015 presign-tenant-banner.use-case.spec.ts
T016 update-tenant-branding.use-case.spec.ts

# Use-cases GREEN em paralelo:
T020 presign-tenant-avatar.use-case.ts
T021 presign-tenant-banner.use-case.ts
```

### Parallel Example: User Story 1 (Client)

```bash
# Após T027 api/branding.ts:
T029 screens.ts
T030 navigation.ts
T031 permissions.ts
```

---

## Implementation Strategy

### MVP First (US1 + US2 — ambos P1)

1. Phase 1 Setup
2. Phase 2 Foundational (CRITICAL)
3. Phase 3 US1 — admin configura identidade
4. Phase 4 US2 — boas-vindas consome branding
5. **STOP and VALIDATE** — quickstart §3–§4
6. Phase 5 US3 — substituir/remover
7. Phase 6 Polish

### Incremental Delivery

1. Foundation → GET branding disponível
2. US1 → admin configura (valor interno)
3. US2 → todos veem identidade (valor produto)
4. US3 → manutenção contínua

### Suggested MVP scope

**Mínimo demoável**: Phase 1 + 2 + **US1** (admin configura).  
**MVP completo spec P1**: incluir **US2** (visibilidade na boas-vindas).  
**US3** pode shippar logo após MVP sem bloquear release.

---

## Notes

- TDD: RED confirmado antes de GREEN em cada use-case/componente
- Nunca passar `tenantId` manual em use-cases — ALS + repositories
- Sem `@RequireLicenca` — Base only
- Copy UI: **Identidade visual atualizada.**, **Apenas arquivos JPEG ou PNG são permitidos.**
- Fora de escopo: `@ci/admin-saas`, crop interativo, sidebar logo global

---

## Task Summary

| Phase | Tasks | Story |
|-------|-------|-------|
| 1 Setup | T001–T004 (4) | — |
| 2 Foundational | T005–T013 (9) | — |
| 3 US1 | T014–T033 (20) | US1 |
| 4 US2 | T034–T038 (5) | US2 |
| 5 US3 | T039–T044 (6) | US3 |
| 6 Polish | T045–T049 (5) | — |
| **Total** | **49** | |

**Format validation**: ✅ Todas as tasks usam `- [X]`, ID `T###`, paths absolutos de arquivo, label `[USn]` nas fases de user story.
