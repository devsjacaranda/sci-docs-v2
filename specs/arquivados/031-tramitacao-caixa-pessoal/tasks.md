---
description: "Task list for Caixa Pessoal na Tramitação (031-tramitacao-caixa-pessoal)"
---

# Tasks: Caixa Pessoal na Tramitação

**Input**: Design documents from `civ2-docs/specs/031-tramitacao-caixa-pessoal/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Tests**: **Obrigatórios** — TDD (constitution II + plan.md + `contracts/test-strategy.md`): unitário, integração (mocks Prisma) e Vitest/RTL client. **1 migration** Prisma; Postgres dev via seed Jacaranda.

**Organization**: 7 user stories (US1–US7). Caminhos relativos à raiz `ci-v2/`.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Pode executar em paralelo (arquivos diferentes, sem dependências pendentes)
- **[Story]**: User story da spec (US1–US7)

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Verificar módulos existentes e preparar diretórios de teste

- [X] T001 Verificar `TramitacaoModule` importa `NotificacaoModule` e exporta use cases em `ci-api-v2/src/modules/tramitacao/tramitacao.module.ts`
- [X] T002 [P] Criar/confirmar diretório `ci-api-v2/src/modules/tramitacao/test/` para specs pessoais
- [X] T003 [P] Confirmar componentes existentes: `TramitacaoInboxWorkspace.tsx`, `api/demandas.ts` em `ci-client-v2/apps/web/src/modules/tramitacao/`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Migration Prisma + filtros inbox + guards de acesso + schemas Zod — **bloqueia US1–US7**

**⚠️ CRITICAL**: Nenhuma user story começa antes desta fase

### Tests first (TDD — RED)

- [X] T004 [P] Escrever testes (RED) `personal-inbox-folder-filter.spec.ts` em `ci-api-v2/src/modules/tramitacao/lib/personal-inbox-folder-filter.spec.ts` — CT-CP-U01
- [X] T005 [P] Escrever testes (RED) `assert-personal-demanda-access.spec.ts` em `ci-api-v2/src/modules/tramitacao/lib/assert-personal-demanda-access.spec.ts` — CT-CP-U02
- [X] T006 [P] Estender testes (RED) exclusão pessoal setorial em `ci-api-v2/src/modules/tramitacao/lib/inbox-folder-filter.spec.ts` — CT-CP-004

### Schema & migration

- [X] T007 Adicionar `personal` em `TramitacaoDemandaOriginType`, campos `targetUserId`, `personalActive` e índices em `ci-api-v2/prisma/schema/tramitacao.prisma` conforme `data-model.md`
- [X] T008 Gerar e aplicar migration em `ci-api-v2/prisma/migrations/` (`npx prisma migrate dev`)

### Implementation

- [X] T009 Implementar `buildPersonalInboxWhere` e `buildPersonalAuditWhere` em `ci-api-v2/src/modules/tramitacao/lib/personal-inbox-folder-filter.ts` (GREEN T004)
- [X] T010 Implementar `assertPersonalDemandaAccess` e helper `isPersonalDemandaActive` em `ci-api-v2/src/modules/tramitacao/lib/assert-personal-demanda-access.ts` (GREEN T005)
- [X] T011 Atualizar `buildInboxWhere` para excluir `originType=personal AND personalActive=true` em `ci-api-v2/src/modules/tramitacao/lib/inbox-folder-filter.ts` (GREEN T006)
- [X] T012 Estender Zod: `inboxMode`, `createPersonalDemandaBodySchema`, `createPersonalLinkedDemandaBodySchema`, `forwardPersonalToUserBodySchema`, `promotePersonalToSectorBodySchema` em `ci-api-v2/src/modules/tramitacao/tramitacao.schemas.ts`
- [X] T013 Estender DTOs (`targetUser`, `senderUser`, `personalActive`, `permissions`) em `ci-api-v2/src/modules/tramitacao/tramitacao.mapper.ts`
- [X] T014 Registrar stubs/providers dos novos use cases em `ci-api-v2/src/modules/tramitacao/tramitacao.module.ts`

**Checkpoint**: Schema migrado; filtros e guards unitários GREEN; inbox setorial exclui pessoais ativas

---

## Phase 3: User Story 1 — Alternar Setor / Pessoal e inbox pessoal (Priority: P1) 🎯 MVP

**Goal**: Toggle **Setor / Pessoal** na workspace; listar pastas Recebidas/Enviadas/Arquivadas filtradas por participante

**Independent Test**: VS Cenário 1 parcial quickstart — toggle Pessoal; lista vazia ou seed; toggle Setor inalterado; colega não vê pessoais (CT-CP-003, CT-CP-004, CT-CP-017)

### Tests for User Story 1 (TDD — RED first)

- [X] T015 [P] [US1] Escrever testes (RED) `personal-inbox.integration.spec.ts` em `ci-api-v2/src/modules/tramitacao/test/personal-inbox.integration.spec.ts` — CT-CP-003, CT-CP-004
- [X] T016 [P] [US1] Escrever testes (RED) toggle UI em `ci-client-v2/apps/web/src/modules/tramitacao/components/__tests__/TramitacaoInboxWorkspace.personal.test.tsx` — CT-CP-017

### Implementation for User Story 1 — API

- [X] T017 [US1] Implementar `ListPersonalInboxUseCase` em `ci-api-v2/src/modules/tramitacao/use-cases/list-personal-inbox.use-case.ts` (GREEN T015)
- [X] T018 [US1] Estender `ListInboxUseCase` ou controller para rotear `inboxMode=personal|sector` em `ci-api-v2/src/modules/tramitacao/use-cases/list-inbox.use-case.ts` e `ci-api-v2/src/modules/tramitacao/tramitacao.controller.ts` (GREEN T015)

### Implementation for User Story 1 — Client

- [X] T019 [P] [US1] Criar hook `useTramitacaoInboxMode.ts` (URL + sessionStorage) em `ci-client-v2/apps/web/src/modules/tramitacao/hooks/useTramitacaoInboxMode.ts`
- [X] T020 [US1] Estender `listInbox` com param `inboxMode` em `ci-client-v2/apps/web/src/modules/tramitacao/api/demandas.ts`
- [X] T021 [US1] Adicionar segmented control Setor/Pessoal e listagem modo pessoal (ocultar pills setor) em `ci-client-v2/apps/web/src/modules/tramitacao/components/TramitacaoInboxWorkspace.tsx` (GREEN T016)

**Checkpoint**: MVP parcial — toggle e inbox pessoal listável (US1)

---

## Phase 4: User Story 2 — Compor mensagem pessoal (Priority: P1)

**Goal**: Operador compõe mensagem para outro operador cross-setor com protocolo TRAM-*

**Independent Test**: VS Cenário 1 quickstart — POST personal A→B; Enviadas/Recebidas; SAME_RECIPIENT bloqueado (CT-CP-001, CT-CP-002, CT-CP-008, CT-CP-018)

### Tests for User Story 2 (TDD — RED first)

- [X] T022 [P] [US2] Estender testes (RED) compose em `ci-api-v2/src/modules/tramitacao/test/personal-inbox.integration.spec.ts` — CT-CP-001, CT-CP-002, CT-CP-008
- [X] T023 [P] [US2] Escrever testes (RED) compose UI em `ci-client-v2/apps/web/src/modules/tramitacao/components/__tests__/TramitacaoInboxWorkspace.personal.test.tsx` — CT-CP-018

### Implementation for User Story 2 — API

- [X] T024 [US2] Implementar `CreatePersonalDemandaUseCase` com `resolveUserTableId` em `ci-api-v2/src/modules/tramitacao/use-cases/create-personal-demanda.use-case.ts` (GREEN T022)
- [X] T025 [US2] Adicionar `POST /tramitacao/demandas/personal` em `ci-api-v2/src/modules/tramitacao/tramitacao.controller.ts` (GREEN T022)

### Implementation for User Story 2 — Notificações

- [X] T026 [P] [US2] Estender testes (RED) `forPersonalParticipant` em `ci-api-v2/src/modules/notificacao/services/resolve-tramitacao-recipients.service.spec.ts` — CT-CP-U03
- [X] T027 [US2] Implementar `forPersonalParticipant` e `notifyPersonalNova` em `ci-api-v2/src/modules/notificacao/services/resolve-tramitacao-recipients.service.ts` e `ci-api-v2/src/modules/notificacao/services/tramitacao-notificacao.service.ts` (GREEN T026)

### Implementation for User Story 2 — Client

- [X] T028 [US2] Implementar `createPersonalDemanda` em `ci-client-v2/apps/web/src/modules/tramitacao/api/demandas.ts`
- [X] T029 [US2] Compose pessoal: seletor destinatário (`fetchUsers` active, excluir self), assunto, corpo em `ci-client-v2/apps/web/src/modules/tramitacao/components/TramitacaoInboxWorkspace.tsx` (GREEN T023)

**Checkpoint**: Compor e receber mensagem pessoal end-to-end (US1 + US2)

---

## Phase 5: User Story 3 — Responder na thread privada (Priority: P1)

**Goal**: Participantes respondem/arquivam; terceiros recebem 404 opaco; notificação ao outro participante

**Independent Test**: VS Cenários 2–3 quickstart — reply B→A; colega negado; archive simétrico (CT-CP-005, CT-CP-006, CT-CP-007)

### Tests for User Story 3 (TDD — RED first)

- [X] T030 [P] [US3] Escrever testes (RED) `personal-access.integration.spec.ts` em `ci-api-v2/src/modules/tramitacao/test/personal-access.integration.spec.ts` — CT-CP-005, CT-CP-006, CT-CP-007

### Implementation for User Story 3 — API

- [X] T031 [US3] Aplicar `assertPersonalDemandaAccess` e flag `permissions` read-only audit em `ci-api-v2/src/modules/tramitacao/use-cases/get-demanda-detail.use-case.ts` (GREEN T030)
- [X] T032 [US3] Branch pessoal + guard participante em `ci-api-v2/src/modules/tramitacao/use-cases/reply-demanda.use-case.ts` (GREEN T030)
- [X] T033 [US3] Branch pessoal + arquivamento simétrico em `ci-api-v2/src/modules/tramitacao/use-cases/archive-demanda.use-case.ts` (GREEN T030)
- [X] T034 [US3] Hook `notifyPersonalResposta` no reply pessoal em `ci-api-v2/src/modules/notificacao/services/tramitacao-notificacao.service.ts` (GREEN CT-CP-006)
- [X] T035 [US3] Garantir reply/archive UI respeitam `permissions` no detalhe em `ci-client-v2/apps/web/src/modules/tramitacao/components/TramitacaoInboxWorkspace.tsx`

**Checkpoint**: Ciclo P1 completo — compor, listar, responder, arquivar com privacidade (US1–US3) 🎯 **MVP produto**

---

## Phase 6: User Story 4 — Encaminhar para outro operador (Priority: P2)

**Goal**: Transferir custódia pessoal para outro User; intermediário perde acesso

**Independent Test**: VS Cenário 5 quickstart — forward B→C; B sem acesso; A+C thread (CT-CP-009, CT-CP-010)

### Tests for User Story 4 (TDD — RED first)

- [X] T036 [P] [US4] Estender testes (RED) forward-user em `ci-api-v2/src/modules/tramitacao/test/personal-inbox.integration.spec.ts` — CT-CP-009, CT-CP-010

### Implementation for User Story 4

- [X] T037 [US4] Implementar `ForwardPersonalToUserUseCase` em `ci-api-v2/src/modules/tramitacao/use-cases/forward-personal-to-user.use-case.ts` (GREEN T036)
- [X] T038 [US4] Adicionar `POST /tramitacao/demandas/:id/forward-user` em `ci-api-v2/src/modules/tramitacao/tramitacao.controller.ts` (GREEN T036)
- [X] T039 [US4] Implementar `notifyPersonalEncaminhada` em `ci-api-v2/src/modules/notificacao/services/tramitacao-notificacao.service.ts`
- [X] T040 [US4] Dialog encaminhar usuário (select operador + notes) em `ci-client-v2/apps/web/src/modules/tramitacao/components/TramitacaoInboxWorkspace.tsx`
- [X] T041 [US4] Adicionar `forwardPersonalToUser` em `ci-client-v2/apps/web/src/modules/tramitacao/api/demandas.ts`

**Checkpoint**: Encaminhamento pessoal usuário→usuário (US4)

---

## Phase 7: User Story 5 — Encaminhar para setor (Priority: P2)

**Goal**: Promover demanda pessoal a setorial irreversível; visível na inbox setor destino

**Independent Test**: VS Cenário 4 quickstart — promote; setor Recebidas; ALREADY_PROMOTED (CT-CP-011, CT-CP-012, CT-CP-019)

### Tests for User Story 5 (TDD — RED first)

- [X] T042 [P] [US5] Escrever testes (RED) `promote-personal-sector.integration.spec.ts` em `ci-api-v2/src/modules/tramitacao/test/promote-personal-sector.integration.spec.ts` — CT-CP-011, CT-CP-012
- [X] T043 [P] [US5] Escrever testes (RED) dialog promote irreversível em `ci-client-v2/apps/web/src/modules/tramitacao/components/__tests__/TramitacaoInboxWorkspace.personal.test.tsx` — CT-CP-019

### Implementation for User Story 5

- [X] T044 [US5] Implementar `PromotePersonalToSectorUseCase` em `ci-api-v2/src/modules/tramitacao/use-cases/promote-personal-to-sector.use-case.ts` (GREEN T042)
- [X] T045 [US5] Adicionar `POST /tramitacao/demandas/:id/promote-sector` em `ci-api-v2/src/modules/tramitacao/tramitacao.controller.ts` (GREEN T042)
- [X] T046 [US5] Disparar `tramitacao_nova_demanda` pós-promoção em `ci-api-v2/src/modules/notificacao/services/tramitacao-notificacao.service.ts`
- [X] T047 [US5] Dialog promote setor + confirmação irreversível em `ci-client-v2/apps/web/src/modules/tramitacao/components/TramitacaoInboxWorkspace.tsx` (GREEN T043)
- [X] T048 [US5] Adicionar `promotePersonalToSector` em `ci-client-v2/apps/web/src/modules/tramitacao/api/demandas.ts`

**Checkpoint**: Ponte pessoal → setorial funcional (US5)

---

## Phase 8: User Story 6 — Vincular registro de outro módulo (Priority: P2)

**Goal**: Demanda pessoal linked (gabinete/ouvidoria/juridico) com snapshot imutável; visibilidade privada

**Independent Test**: VS Cenário 7 quickstart — personal linked; painel origem; terceiro 404 (CT-CP-013, CT-CP-014)

### Tests for User Story 6 (TDD — RED first)

- [X] T049 [P] [US6] Estender testes (RED) linked personal em `ci-api-v2/src/modules/tramitacao/test/personal-access.integration.spec.ts` — CT-CP-013, CT-CP-014

### Implementation for User Story 6

- [X] T050 [US6] Implementar `CreatePersonalLinkedDemandaUseCase` em `ci-api-v2/src/modules/tramitacao/use-cases/create-personal-linked-demanda.use-case.ts` (GREEN T049)
- [X] T051 [US6] Adicionar `POST /tramitacao/demandas/personal/linked` em `ci-api-v2/src/modules/tramitacao/tramitacao.controller.ts` (GREEN T049)
- [X] T052 [US6] Seção opcional vínculo origem no compose pessoal + `createPersonalLinkedDemanda` em `ci-client-v2/apps/web/src/modules/tramitacao/api/demandas.ts` e `TramitacaoInboxWorkspace.tsx`
- [X] T053 [US6] Confirmar `LinkedRecordPanel` renderiza para `originType=personal` em `ci-client-v2/apps/web/src/modules/tramitacao/components/LinkedRecordPanel.tsx`

**Checkpoint**: Linked record pessoal com snapshot (US6)

---

## Phase 9: User Story 7 — Auditoria admin_tenant (Priority: P2)

**Goal**: admin_tenant lista e consulta todas demandas pessoais read-only

**Independent Test**: VS Cenário 6 quickstart — audit list; read-only detail; operador 403 (CT-CP-015, CT-CP-016, CT-CP-020)

### Tests for User Story 7 (TDD — RED first)

- [X] T054 [P] [US7] Estender testes (RED) audit em `ci-api-v2/src/modules/tramitacao/test/personal-inbox.integration.spec.ts` — CT-CP-015, CT-CP-016
- [X] T055 [P] [US7] Escrever testes (RED) audit read-only UI em `ci-client-v2/apps/web/src/modules/tramitacao/components/__tests__/TramitacaoInboxWorkspace.personal.test.tsx` — CT-CP-020

### Implementation for User Story 7

- [X] T056 [US7] Implementar `ListPersonalAuditUseCase` em `ci-api-v2/src/modules/tramitacao/use-cases/list-personal-audit.use-case.ts` (GREEN T054)
- [X] T057 [US7] Rotear `inboxMode=audit` com guard `admin_tenant` em `ci-api-v2/src/modules/tramitacao/tramitacao.controller.ts` (GREEN T054)
- [X] T058 [US7] Tab/modo Auditoria + banner somente leitura + ocultar ações em `ci-client-v2/apps/web/src/modules/tramitacao/components/TramitacaoInboxWorkspace.tsx` (GREEN T055)
- [X] T059 [US7] Estender `useTramitacaoInboxMode` e navegação deep link `?inboxMode=audit` em `ci-client-v2/apps/web/src/modules/tramitacao/hooks/useTramitacaoInboxMode.ts`

**Checkpoint**: Compliance admin_tenant operacional (US7)

---

## Phase 10: Polish & Cross-Cutting Concerns

**Purpose**: Seed demo, dashboard, MSW, regressão e quickstart

- [X] T060 [P] Adicionar demandas pessoais demo (A→B, opcional linked) em `ci-api-v2/prisma/seed/seed-tramitacao-demo.ts`
- [X] T061 Excluir demandas pessoais ativas dos KPIs em `ci-api-v2/src/modules/tramitacao/use-cases/get-dashboard.use-case.ts`
- [X] T062 [P] Estender handlers MSW personal inbox/compose em `ci-client-v2/apps/web/src/test/msw/handlers/tramitacao.ts`
- [X] T063 [P] Registrar tipos `tramitacao_pessoal_*` em navigation registry se necessário em `ci-api-v2/src/modules/notificacao/lib/navigation-registry.ts`
- [X] T064 Executar suíte API: `cd ci-api-v2; npm test -- --testPathPatterns=personal`
- [X] T065 [P] Executar suíte client: `cd ci-client-v2/apps/web; npm test -- TramitacaoInboxWorkspace.personal`
- [X] T066 Executar regressão: `cd ci-api-v2; npm test -- --testPathPatterns=tramitacao` e `--testPathPatterns=resolve-tramitacao-recipients`
- [X] T067 Validar cenários 1–7 em `civ2-docs/specs/031-tramitacao-caixa-pessoal/quickstart.md`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Sem dependências
- **Foundational (Phase 2)**: Depende Setup — **BLOQUEIA** US1–US7
- **US1 (Phase 3)**: Depende Foundational
- **US2 (Phase 4)**: Depende US1 (lista para validar compose)
- **US3 (Phase 5)**: Depende US2 (demanda existente para reply)
- **US4 (Phase 6)**: Depende US3 (participantes + guards)
- **US5 (Phase 7)**: Depende US3 (demanda pessoal ativa)
- **US6 (Phase 8)**: Depende US2 (compose estendido)
- **US7 (Phase 9)**: Depende US2 (demandas pessoais no tenant)
- **Polish (Phase 10)**: Depende US1–US7 desejados

### User Story Dependencies

```text
Foundational ──► US1 ──► US2 ──► US3 ──┬──► US4
                                       ├──► US5
                                       ├──► US6 (após US2)
                                       └──► US7 (após US2)
```

### Parallel Opportunities

```bash
# Foundational — unit tests em paralelo:
T004 personal-inbox-folder-filter.spec.ts
T005 assert-personal-demanda-access.spec.ts
T006 inbox-folder-filter.spec.ts

# US1 — API test + client test em paralelo:
T015 personal-inbox.integration.spec.ts
T016 TramitacaoInboxWorkspace.personal.test.tsx

# US2 — notificação unit test paralelo ao compose API:
T026 resolve-tramitacao-recipients.service.spec.ts
T022 personal-inbox.integration.spec.ts (compose)
```

---

## Implementation Strategy

### MVP First (US1 + US2 + US3)

1. Phase 1 Setup
2. Phase 2 Foundational (**crítico**)
3. Phase 3 US1 → Phase 4 US2 → Phase 5 US3
4. **STOP e VALIDAR** quickstart Cenários 1–3
5. Demo/deploy caixa pessoal básica

### Incremental Delivery

| Incremento | Stories | Valor entregue |
|------------|---------|----------------|
| MVP | US1–US3 | Mensagem privada bidirecional |
| v1.1 | US4–US5 | Encaminhar usuário e promover setor |
| v1.2 | US6–US7 | Linked pessoal + auditoria admin |

### Parallel Team Strategy

- **Dev A**: Foundational + API use cases (US1–US5)
- **Dev B**: Notificações (T026–T027, T034, T039, T046) após T024
- **Dev C**: Client workspace (T019–T021, T029, T035, T040, T047, T058) após T012

---

## Task Summary

| Phase | Story | Tasks | Count |
|-------|-------|-------|-------|
| 1 Setup | — | T001–T003 | 3 |
| 2 Foundational | — | T004–T014 | 11 |
| 3 US1 | Toggle + inbox pessoal | T015–T021 | 7 |
| 4 US2 | Compor pessoal | T022–T029 | 8 |
| 5 US3 | Reply privado | T030–T035 | 6 |
| 6 US4 | Forward usuário | T036–T041 | 6 |
| 7 US5 | Promote setor | T042–T048 | 7 |
| 8 US6 | Linked pessoal | T049–T053 | 5 |
| 9 US7 | Auditoria admin | T054–T059 | 6 |
| 10 Polish | — | T060–T067 | 8 |
| **Total** | | **T001–T067** | **67** |

**Suggested MVP scope**: T001–T035 (Setup + Foundational + US1 + US2 + US3)

**Status**: Draft — pronto para `/speckit-implement`
