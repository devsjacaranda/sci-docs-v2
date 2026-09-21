---

description: "Task list for 047-acesso-ouvidoria-ageman"
---

# Tasks: Níveis de Acesso Ouvidoria AGEMAN (403)

**Input**: Design documents from `civ2-docs/specs/047-acesso-ouvidoria-ageman/` (`plan.md`, `spec.md`, `research.md`, `data-model.md`, `contracts/`, `quickstart.md`)

**Tests**: Incluídos em todas as fases — Constitution §II (Test-First) é NON-NEGOTIABLE neste monorepo (skills `tdd` + `testing-conventions` sempre aplicadas antes de código novo). Escrever cada teste marcado abaixo e confirmar RED antes da tarefa de implementação correspondente.

**Organization**: Tarefas agrupadas por user story (spec.md) para permitir implementação e teste independentes de cada uma.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Pode rodar em paralelo (arquivos diferentes, sem dependência de tarefa incompleta)
- **[Story]**: US1–US7, mapeando para as user stories de `spec.md`
- Setup/Foundational/Polish: sem label de story

## Path Conventions (Web application — ver `plan.md`)

- API: `ci-api-v2/src/modules/ouvidoria/` (+ `ci-api-v2/src/modules/admin-plataforma/` para o flag cross-tenant), Prisma em `ci-api-v2/prisma/schema/`, e2e em `ci-api-v2/test/`
- Client: `ci-client-v2/apps/web/src/modules/ouvidoria/` (+ `ci-client-v2/apps/web/src/modules/tenant/` e `ci-client-v2/apps/admin-saas/src/modules/admin-plataforma/` para o flag)

---

## Phase 1: Setup

**Purpose**: Schema Prisma das duas entidades novas (nenhum pacote/dependência nova — reaproveita stack fixa)

- [x] T001 [P] Criar `ci-api-v2/prisma/schema/ouvidoria-acesso.prisma` com `enum OuvidoriaAcessoScope { manifestacao emissor }` e `model OuvidoriaAcessoConcessao` (campos e índices per `data-model.md`)
- [x] T002 [P] Criar `ci-api-v2/prisma/schema/ouvidoria-acesso-flag.prisma` com `model OuvidoriaAcessoFeatureFlag` (`tenantId @unique`, `enabled Boolean @default(true)`, `updatedByUserId`, `updatedByRole`) per `data-model.md`
- [x] T003 [P] Adicionar `access_granted` e `access_revoked` a `enum ManifestacaoEventoTipo` em `ci-api-v2/prisma/schema/manifestacao.prisma`
- [x] T004 Adicionar campos de relação reversa para as duas novas entidades em `model User` (`ci-api-v2/prisma/schema/user.prisma`) e `model Tenant` (`ci-api-v2/prisma/schema/tenant.prisma`) (depende de T001, T002)
- [x] T005 Rodar `cd ci-api-v2; npx prisma migrate dev --name ouvidoria_acesso_controle; npx prisma generate` (depende de T001–T004)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Núcleo de decisão de acesso (`assertManifestacaoAccess`) e leitura do flag — usados por TODAS as user stories (US1–US7)

**⚠️ CRITICAL**: Nenhuma user story pode começar antes desta fase estar completa

- [x] T006 [P] Estender `AuthenticatedOuvidoriaUser` em `ci-api-v2/src/modules/ouvidoria/ouvidoria.types.ts` com `chiefOfSetorIds: string[]` (hoje só tem `userId`/`role`/`setorIds` — necessário para o bypass de "chefe da ouvidoria")
- [x] T007 [P] Atualizar `toOuvidoriaUser()` em `ci-api-v2/src/modules/ouvidoria/ouvidoria.controller.ts` para mapear `req.user.chiefOfSetorIds ?? []` (depende de T006)
- [x] T008 [P] Teste unitário (RED) `ci-api-v2/src/modules/ouvidoria/lib/is-chefe-da-ouvidoria.spec.ts`
- [x] T009 Implementar `ci-api-v2/src/modules/ouvidoria/lib/is-chefe-da-ouvidoria.ts` usando `FindModuloSetoresRepository` (`modules/permissao/repository/find-modulo-setores.repository.ts`) (GREEN de T008)
- [x] T010 [P] Repository `ci-api-v2/src/modules/ouvidoria/repository/ouvidoria-acesso-flag.repository.ts` — método `findByTenantId` (leitura; `upsert` chega em US7)
- [x] T011 [P] Teste unitário (RED) `ci-api-v2/src/modules/ouvidoria/lib/get-ouvidoria-acesso-flag.spec.ts`
- [x] T012 Implementar `ci-api-v2/src/modules/ouvidoria/lib/get-ouvidoria-acesso-flag.ts` (GREEN de T011, depende de T010)
- [x] T013 [P] Repository `ci-api-v2/src/modules/ouvidoria/repository/ouvidoria-acesso.repositories.ts` — métodos de leitura `findActiveGranteeIdsForManifestacao`, `findActiveGranteeIdsForEmissor` (create/revoke chegam em US4)
- [x] T014 [P] Testes unitários (RED) `ci-api-v2/src/modules/ouvidoria/lib/assert-manifestacao-access.spec.ts`
- [x] T015 Implementar `ci-api-v2/src/modules/ouvidoria/lib/assert-manifestacao-access.ts` — tipos `ManifestacaoAccessSubject`/`ManifestacaoAccessActor`/`AccessReason`/`AccessDecision` + função pura com Passo 0 = flag (GREEN de T014, depende de T009, T012, T013)
- [x] T016 [P] Adicionar `createOuvidoriaAcessoBodySchema` (discriminated union `manifestacao`/`emissor`) e `setOuvidoriaAcessoFlagBodySchema` em `ci-api-v2/src/modules/ouvidoria/ouvidoria.schemas.ts`
- [x] T017 Registrar os novos repositories/libs como providers em `ci-api-v2/src/modules/ouvidoria/ouvidoria.module.ts` (depende de T010, T013)

**Checkpoint**: `assertManifestacaoAccess` funciona isoladamente (com as tabelas de concessão/flag vazias ⇒ comportamento correto de dono/chefe/admin, sem concessões ainda). US1–US7 podem começar.

---

## Phase 3: User Story 1 - Lista mostra todas; 403 só no acesso direto (Priority: P1) 🎯 MVP

**Goal**: A listagem devolve o universo do tenant (sem filtro por dono/grant). 403 só em ação direta sobre um registro.

**Independent Test**: Dois operadores, cada um emissor de uma demanda distinta — ambas as listas mostram as duas linhas; GET detalhe da demanda alheia → 403.

### Tests for User Story 1

- [x] T018 [P] [US1] Teste de integração (RED) `ci-api-v2/src/modules/ouvidoria/use-cases/list-manifestacoes.use-case.spec.ts` — A e B veem o universo do tenant (sem filtro por dono); filtros de produto seguem; 403 só no detalhe (correção PO 2026-09-16)
- [x] T019 [P] [US1] Teste e2e (RED) `ci-api-v2/test/ouvidoria-acesso-controle.e2e-spec.ts` — Cenário 1 do `quickstart.md`

### Implementation for User Story 1

- [x] T020 [US1] Estender `ListManifestacoesRepository.execute()` — filtro de visibilidade
- [x] T021 [US1] Atualizar `ListManifestacoesUseCase.execute()` — monta filtro a partir do actor
- [x] T022 [US1] Rota `GET /ouvidoria/manifestacoes` passa `toOuvidoriaUser(req)`

**Checkpoint**: US1 completo e testável isoladamente (SC-001).

---

## Phase 4: User Story 2 - Acesso direto sem permissão retorna 403 explícito (Priority: P1) 🎯 MVP

**Goal**: Toda ação direta sobre um registro específico (detalhe, edição, exclusão, download, fluxo, anexos) sem permissão retorna 403 explícito, sem vazar conteúdo.

**Independent Test**: Operador sem vínculo chama diretamente detalhe/edição/download de uma demanda de outro emissor → 403 nos 3 casos, sem dado de conteúdo no corpo.

### Tests for User Story 2

- [x] T023 [P] [US2] Teste e2e (RED) — Cenário 2 do `quickstart.md`: 403 em `GET/PATCH .../:id`, `GET .../documento/pdf`, sem `subject`/`description` no corpo

### Implementation for User Story 2

- [x] T024 [US2] Adicionar `OUVIDORIA_ACCESS_DENIED` a `ouvidoria-errors.ts`
- [x] T025 [P] [US2] `get-manifestacao-detail.use-case.ts`
- [x] T026 [P] [US2] `update-manifestacao-draft.use-case.ts`
- [x] T027 [P] [US2] `delete-manifestacao.use-case.ts`
- [x] T028 [P] [US2] `get-manifestacao-revisao.use-case.ts`
- [x] T029 [P] [US2] `get-manifestacao-retomabilidade.use-case.ts`
- [x] T030 [P] [US2] `confirm-manifestacao.use-case.ts`
- [x] T031 [P] [US2] `encaminhar-manifestacao.use-case.ts`
- [x] T032 [P] [US2] `responder-manifestacao.use-case.ts`
- [x] T033 [P] [US2] `encerrar-manifestacao.use-case.ts`
- [x] T034 [P] [US2] `generate-manifestacao-docx.use-case.ts`
- [x] T035 [P] [US2] `generate-manifestacao-pdf.use-case.ts`
- [x] T036 [P] [US2] `presign-anexo.use-case.ts`
- [x] T037 [P] [US2] `add-link-anexo.use-case.ts`
- [x] T038 [P] [US2] `confirm-anexo.use-case.ts`
  > T025–T038 dependem de T015/T024; cada tarefa toca um arquivo diferente → paralelizáveis entre si; GREEN de T023 só é alcançado com todas completas.
- [x] T039 [US2] [Client] Adicionar `CODE_SPECS.OUVIDORIA_ACCESS_DENIED` (`kind: 'permission'`, `surface: 'page'`) em `ci-client-v2/apps/web/src/modules/ouvidoria/api/errors.ts` (mensagem per `research.md` §7)
- [x] T040 [P] [US2] [Client] Teste (Vitest) do novo mapeamento de erro em `ci-client-v2/apps/web/src/modules/ouvidoria/api/errors.ts` (arquivo de spec já existente do módulo)

**Checkpoint**: US2 completo e testável isoladamente (SC-002).

---

## Phase 5: User Story 3 - Chefes da ouvidoria e admins veem tudo (Priority: P1) 🎯 MVP

**Goal**: Confirmar (e ajustar se necessário) que o bypass de chefe/admin já embutido em `assertManifestacaoAccess`/filtro de listagem funciona ponta a ponta com dados reais do JWT.

**Independent Test**: Chefe da ouvidoria e admin abrem demandas de emissores diferentes — acesso total; chefe de setor não vinculado ao módulo não ganha bypass.

### Tests for User Story 3

- [x] T041 [P] [US3] Teste e2e (RED→GREEN) — Cenário 3 do `quickstart.md`, cenários 1–2 (chefe da ouvidoria e admin veem tudo)
- [x] T042 [P] [US3] Teste e2e (RED→GREEN) — Cenário 3 do `quickstart.md`, cenário 3 (chefe de setor NÃO vinculado ao módulo não ganha bypass)

### Implementation for User Story 3

- [x] T043 [US3] Revisar wiring `chiefOfSetorIds` / assert / listagem

**Checkpoint**: US3 completo (SC-003) — nenhuma implementação nova de regra, apenas verificação/correção de wiring do mecanismo já construído nas fases anteriores.

---

## Phase 6: User Story 4 - Conceder acesso a um colega para um registro específico (Priority: P2)

**Goal**: Emissor/chefe/admin concede acesso pontual (por UUID da demanda) a outro usuário; a concessão pode ser revogada.

**Independent Test**: Emissor concede acesso pontual a B; B acessa aquela demanda mas não outra do mesmo emissor sem concessão.

### Tests for User Story 4

- [x] T044 [P] [US4] Teste unitário `grant-ouvidoria-acesso.use-case.spec.ts`
- [x] T045 [P] [US4] Teste unitário `revoke-ouvidoria-acesso.use-case.spec.ts`

### Implementation for User Story 4

- [x] T046 [US4] `create`/`existsActive`/`revoke` em `ouvidoria-acesso.repositories.ts`
- [x] T047 [US4] `grant-ouvidoria-acesso.use-case.ts`
- [x] T048 [US4] `revoke-ouvidoria-acesso.use-case.ts`
- [x] T049 [US4] Rotas POST/DELETE `/ouvidoria/acessos` + module
- [x] T050 [US4] Teste e2e (RED→GREEN) — Cenário 4 do `quickstart.md`

**Checkpoint**: US4 completo e testável isoladamente (SC-004).

---

## Phase 7: User Story 5 - Conceder acesso a todas as demandas de um emissor (Priority: P2)

**Goal**: Estender a concessão para escopo "todas as demandas de um emissor", cobrindo demandas futuras automaticamente.

**Independent Test**: Concessão geral de A para B; B vê demandas existentes e uma nova demanda criada por A depois da concessão; revogação bloqueia ambas.

### Tests for User Story 5

- [x] T051 [P] [US5] Casos `scope=emissor` em `grant-ouvidoria-acesso.use-case.spec.ts`

### Implementation for User Story 5

- [x] T052 [US5] `grant-ouvidoria-acesso.use-case.ts` scope emissor
- [x] T053 [US5] Teste e2e (RED→GREEN) — Cenário 5 do `quickstart.md`, incluindo a revogação via `revoke-ouvidoria-acesso.use-case.ts` (T048, reaproveitado sem alteração — genérico para os dois escopos)

**Checkpoint**: US5 completo e testável isoladamente (SC-004/SC-005 aplicados ao escopo emissor).

---

## Phase 8: User Story 6 - Ver quem tem acesso a uma demanda (Priority: P2)

**Goal**: Endpoint + UI mostrando emissor, grupo chefe/admin e concessões ativas de uma demanda.

**Independent Test**: Com concessões pontual e geral ativas, o detalhe da demanda mostra a lista correta de quem tem acesso.

### Tests for User Story 6

- [x] T054 [P] [US6] Teste unitário `list-ouvidoria-acessos.use-case.spec.ts`

### Implementation for User Story 6

- [x] T055 [US6] `list-ouvidoria-acessos.use-case.ts`
- [x] T056 [US6] `mapAcessoConcessao` em `ouvidoria.mapper.ts`
- [x] T057 [US6] Rota `GET /ouvidoria/manifestacoes/:id/acessos`
- [x] T058 [P] [US6] [Client] Criar `ci-client-v2/apps/web/src/modules/ouvidoria/api/acessos.ts` — `grantAcesso`/`revokeAcesso`/`listAcessos` + schema Zod v3 de resposta
- [x] T059 [P] [US6] [Client] Criar `ci-client-v2/apps/web/src/modules/ouvidoria/components/ManifestacaoAcessoCard.tsx`
- [x] T060 [P] [US6] [Client] Criar `ci-client-v2/apps/web/src/modules/ouvidoria/components/ManifestacaoAcessoGrantDialog.tsx`
- [x] T061 [P] [US6] [Client] Criar `ci-client-v2/apps/web/src/modules/ouvidoria/components/ManifestacaoAcessoRevokeButton.tsx`
- [x] T062 [US6] [Client] Estender `ci-client-v2/apps/web/src/modules/ouvidoria/lib/manifestacao-detail-view.ts` com o campo `acesso` no ViewModel (+ teste Vitest)
- [x] T063 [US6] [Client] Renderizar `ManifestacaoAcessoCard` em `ci-client-v2/apps/web/src/modules/ouvidoria/pages/ManifestacaoDetailPage.tsx` (depende de T058–T062)
- [x] T064 [P] [US6] Teste e2e (RED→GREEN) — Cenário 6 do `quickstart.md`

**Checkpoint**: US6 completo e testável isoladamente (SC-006).

---

## Phase 9: User Story 7 - Ativar/desativar toda a restrição por tenant (feature flag) (Priority: P3)

**Goal**: Kill-switch por tenant (FR-014 a FR-020) — `admin_saas` (qualquer tenant) ou `admin_tenant` (próprio tenant) ligam/desligam; leitura já existe desde a Foundational (T010/T012/T015).

**Independent Test**: Desligar o flag do tenant → operador B passa a ver a demanda de A; religar → restrição (e concessões já feitas) voltam a valer, sem novo login.

### Tests for User Story 7

- [x] T065 [P] [US7] Teste unitário `set-ouvidoria-acesso-flag.use-case.spec.ts`

### Implementation for User Story 7

- [x] T066 [US7] `upsert` em `ouvidoria-acesso-flag.repository.ts`
- [x] T067 [US7] `set-ouvidoria-acesso-flag.use-case.ts`
- [x] T068 [P] [US7] `ouvidoria-acesso-flag.guard.ts`
- [x] T069 [US7] Rotas GET/PATCH `/ouvidoria/acesso-flag` + module export
- [x] T070 [US7] `AdminPlataformaModule` importa `SetOuvidoriaAcessoFlagUseCase`
- [x] T071 [US7] Rota PATCH `/admin/tenants/:tenantId/feature-flags/ouvidoria-acesso`
- [x] T072 [US7] Flag em `get-tenant-detail.use-case.ts`
- [x] T073 [P] [US7] [Client] Criar `ci-client-v2/apps/web/src/modules/ouvidoria/api/acesso-flag.ts` — `getAcessoFlag`/`setAcessoFlag`
- [x] T074 [US7] [Client] Estender `ci-client-v2/apps/web/src/modules/tenant/components/PlatformTenantConfigPanel.tsx` com o toggle do flag (visível só para `admin_tenant`, mesmo padrão `Status`/`StatusBanner` já usado no painel)
- [x] T075 [P] [US7] [Client] Estender `ci-client-v2/apps/admin-saas/src/modules/admin-plataforma/api/tenants.ts` — `toggleOuvidoriaAcessoFlag` + campo no `TenantDetailDto`
- [x] T076 [US7] [Client] Estender `ci-client-v2/apps/admin-saas/src/modules/admin-plataforma/pages/TenantDetailPage.tsx` com seção "Recursos" + toggle (mesmo componente visual de `LicencaToggle`) (depende de T075)
- [x] T077 [P] [US7] Teste e2e (RED→GREEN) — Cenário 8 do `quickstart.md`: desligar → confirmar bypass total → religar → confirmar restauração de restrições e concessões, sem novo login

**Checkpoint**: US7 completo e testável isoladamente (SC-009/SC-010).

---

## Phase 10: Polish & Cross-Cutting Concerns

**Purpose**: Qualidade final, revisão de segurança e validação de ponta a ponta

- [x] T078 [P] Rodar `ReadLints` nos arquivos alterados/criados em `ci-api-v2` e `ci-client-v2/apps/web`/`apps/admin-saas`
- [x] T079 [P] Revisão OWASP A01 (Broken Access Control) e A09 (Security Logging) — confirmar deny-by-default, ausência de IDOR, ausência de vazamento de conteúdo em 403, auditoria completa de concessão/revogação/flag (skill `owasp-security`) — ver `owasp-review-T079.md`
- [ ] T080 Executar toda a checklist do `quickstart.md` (Cenários 1–8) de ponta a ponta
- [x] T081 [P] Rodar `cd ci-api-v2; npm test -- --testPathPatterns=ouvidoria` e `cd ci-client-v2/apps/web; npm test -- ouvidoria` — suíte completa verde antes de considerar a feature pronta para `/speckit-implement` → `/speckit-complete`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: sem dependências — pode começar imediatamente
- **Foundational (Phase 2)**: depende de Setup — BLOQUEIA todas as user stories
- **US1, US2, US3 (Phase 3–5, todas P1)**: dependem só de Foundational; podem rodar em paralelo entre si (times diferentes), mas US3 é essencialmente uma verificação do mecanismo que US1/US2 constroem — na prática, terminar US2 antes de validar US3 reduz retrabalho
- **US4 (Phase 6, P2)**: depende de Foundational (T013/T015); independente de US1/US2/US3
- **US5 (Phase 7, P2)**: depende de US4 (estende o mesmo `grant-ouvidoria-acesso.use-case.ts` e reaproveita o `revoke` de US4)
- **US6 (Phase 8, P2)**: depende de US4 (reaproveita `ouvidoria-acesso.repositories.ts` com `create`/`revoke` já existentes — T046)
- **US7 (Phase 9, P3)**: depende só de Foundational (a leitura do flag, T010/T012/T015, já existe) — independente de US4/US5/US6
- **Polish (Phase 10)**: depende de todas as user stories que forem entregues

### User Story Dependencies (resumo)

| Story | Depende de | Pode rodar em paralelo com |
|---|---|---|
| US1 (P1) | Foundational | US2, US3, US4, US7 |
| US2 (P1) | Foundational | US1, US3, US4, US7 |
| US3 (P1) | Foundational (+ conclusão lógica de US2) | US4, US7 |
| US4 (P2) | Foundational | US1, US2, US3, US7 |
| US5 (P2) | US4 | US1, US2, US3, US7 |
| US6 (P2) | US4 | US1, US2, US3, US7 |
| US7 (P3) | Foundational | US1, US2, US3, US4, US5, US6 |

### Within Each User Story

- Testes (RED) antes da tarefa de implementação correspondente (GREEN)
- Repository antes de use-case; use-case antes de controller/rota
- Client depende do contrato de API já implementado na mesma story

### Parallel Opportunities

- Todas as tarefas `[P]` de Setup (T001–T003) e Foundational podem rodar em paralelo entre si (arquivos diferentes)
- Todas as 13 tarefas de wiring de US2 (T025–T038) tocam arquivos diferentes → totalmente paralelizáveis
- US1, US2, US4 e US7 podem ser implementadas por pessoas diferentes em paralelo assim que Foundational terminar
- US5 e US6 só podem começar depois de US4 (dependem de `create`/`revoke` em `ouvidoria-acesso.repositories.ts`)

---

## Parallel Example: User Story 2 (wiring do 403)

```bash
# Depois de T024 (código de erro OUVIDORIA_ACCESS_DENIED), lançar em paralelo:
Task: "Wire assertManifestacaoAccess em get-manifestacao-detail.use-case.ts"
Task: "Wire assertManifestacaoAccess em update-manifestacao-draft.use-case.ts"
Task: "Wire assertManifestacaoAccess em delete-manifestacao.use-case.ts"
Task: "Wire assertManifestacaoAccess em generate-manifestacao-docx.use-case.ts"
Task: "Wire assertManifestacaoAccess em generate-manifestacao-pdf.use-case.ts"
# ... (T028-T038, mesmo padrão, 1 arquivo por tarefa)
```

---

## Implementation Strategy

### MVP First (User Stories 1 + 2 + 3 — todas P1)

O pedido central do cliente ("ver só o meu" + "403 explícito" + "chefe/admin veem tudo") só faz sentido como um conjunto — entregar só US1 sem US2 deixaria ações diretas sem 403; entregar só US1+US2 sem US3 quebraria o acesso de chefes/admins que hoje já têm acesso total. Portanto:

1. Completar Phase 1: Setup
2. Completar Phase 2: Foundational (CRÍTICO — bloqueia tudo)
3. Completar Phase 3 (US1) + Phase 4 (US2) + Phase 5 (US3)
4. **PARAR e VALIDAR**: rodar Cenários 1–3 do `quickstart.md`
5. Deploy/demo — este é o MVP real do pedido original

### Incremental Delivery (pós-MVP)

1. MVP (US1+US2+US3) → deploy
2. US4 (conceder pontual) → testar independentemente → deploy
3. US5 (conceder geral por emissor, estende US4) → testar → deploy
4. US6 ("quem tem acesso", estende US4) → testar → deploy
5. US7 (feature flag — kill switch) → testar → deploy final

### Parallel Team Strategy

Com múltiplos desenvolvedores, após Foundational:
- Dev A: US1 → depois US7 (ambas leem, não escrevem, sobre a mesma base)
- Dev B: US2 (maior volume de tarefas — 13 wirings paralelos)
- Dev C: US3 (verificação, rápida) → depois US4 → US5 → US6 (cadeia sequencial, mesmo arquivo de repository)

---

## Notes

- [P] tasks = arquivos diferentes, sem dependência entre si
- [Story] mapeia a tarefa à user story correspondente de `spec.md` para rastreabilidade
- Verificar que cada teste falha (RED) antes de implementar (GREEN) — Constitution §II
- Nenhuma tarefa de US2 (403) pode ser considerada concluída sem confirmar ausência de campos de conteúdo no corpo da resposta 403 (FR-007)
- Commit por tarefa ou grupo lógico; parar em qualquer checkpoint para validar a story isoladamente
