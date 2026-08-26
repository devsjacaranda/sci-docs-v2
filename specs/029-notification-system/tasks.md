---
description: "Task list for Sistema de Notificações CI v2 (029-notification-system)"
---

# Tasks: Sistema de Notificações CI v2

**Input**: Design documents from `civ2-docs/specs/029-notification-system/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Tests**: **Obrigatórios** — TDD (constitution II + plan.md + `contracts/test-strategy.md`): Jest API (unit + integration + gateway); Vitest/RTL/MSW client. Skills: `tdd`, `testing-conventions`, `js-ts-data-transforms`, `vite-react-best-practices`, `ui-ux-pro-max`.

**Organization**: 5 user stories (US1–US5). Caminhos relativos à raiz `ci-v2/`.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Pode executar em paralelo (arquivos diferentes, sem dependências pendentes)
- **[Story]**: User story da spec (US1–US5)

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Dependências WebSocket e scaffold de módulos API/client

- [X] T001 Instalar `@nestjs/websockets`, `@nestjs/platform-socket.io`, `socket.io` em `ci-api-v2/package.json`
- [X] T002 [P] Instalar `socket.io-client` em `ci-client-v2/apps/web/package.json`
- [X] T003 [P] Criar estrutura de pastas do módulo em `ci-api-v2/src/modules/notificacao/` (repository, use-cases, services, lib)
- [X] T004 [P] Criar estrutura de pastas do módulo em `ci-client-v2/apps/web/src/modules/notificacao/` (api, hooks, context, components, lib, __tests__)
- [X] T005 [P] Adicionar `VITE_WS_URL` documentado em `ci-client-v2/apps/web/.env.example` (fallback `VITE_API_URL`)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Schema Prisma, repositories, libs puras, mapper — **bloqueia todas as user stories**

**⚠️ CRITICAL**: Nenhuma user story começa antes desta fase

### Tests first (TDD — RED)

- [X] T006 [P] Escrever testes (RED) `create-notificacao.repository.spec.ts` em `ci-api-v2/src/modules/notificacao/repository/create-notificacao.repository.spec.ts` — NT-001, NT-002
- [X] T007 [P] Escrever testes (RED) `list-notificacoes.repository.spec.ts` em `ci-api-v2/src/modules/notificacao/repository/list-notificacoes.repository.spec.ts` — NT-003, NT-004
- [X] T008 [P] Escrever testes (RED) `count-unread-notificacoes.repository.spec.ts` em `ci-api-v2/src/modules/notificacao/repository/count-unread-notificacoes.repository.spec.ts` — NT-005
- [X] T009 [P] Escrever testes (RED) `mark-notificacao-read.repository.spec.ts` em `ci-api-v2/src/modules/notificacao/repository/mark-notificacao-read.repository.spec.ts` — NT-006
- [X] T010 [P] Escrever testes (RED) `build-dedupe-key.spec.ts` em `ci-api-v2/src/modules/notificacao/lib/build-dedupe-key.spec.ts`
- [X] T011 [P] Escrever testes (RED) `notificacao.mapper.spec.ts` em `ci-api-v2/src/modules/notificacao/notificacao.mapper.spec.ts` — NT-010

### Implementation

- [X] T012 Criar schema Prisma `Notificacao` + enums em `ci-api-v2/prisma/schema/notificacao.prisma` conforme `data-model.md`
- [X] T013 Gerar migration em `ci-api-v2/prisma/migrations/` e registrar `Notificacao` em `ci-api-v2/src/infrastructure/prisma/prisma.constants.ts`
- [X] T014 [P] Implementar `build-dedupe-key.ts` em `ci-api-v2/src/modules/notificacao/lib/build-dedupe-key.ts` (GREEN T010)
- [X] T015 [P] Implementar `navigation-registry.ts` em `ci-api-v2/src/modules/notificacao/lib/navigation-registry.ts` (v1: `tramitacao` only)
- [X] T016 [P] Implementar `notificacao.types.ts` e `notificacao.schemas.ts` (Zod) em `ci-api-v2/src/modules/notificacao/`
- [X] T017 Implementar `notificacao.mapper.ts` com labels PT-BR e `navigationPath` (GREEN T011)
- [X] T018 [P] Implementar `create-notificacao.repository.ts` com dedupe (GREEN T006)
- [X] T019 [P] Implementar `list-notificacoes.repository.ts` (GREEN T007)
- [X] T020 [P] Implementar `count-unread-notificacoes.repository.ts` (GREEN T008)
- [X] T021 Implementar `mark-notificacao-read.repository.ts` incluindo batch read-all (GREEN T009)
- [X] T022 Registrar `NotificacaoModule` skeleton em `ci-api-v2/src/modules/notificacao/notificacao.module.ts` e importar em `ci-api-v2/src/app.module.ts`

**Checkpoint**: Repositories GREEN; schema migrado; módulo registrado

---

## Phase 3: User Story 1 — Alerta imediato nova demanda (Priority: P1) 🎯 MVP

**Goal**: Operador recebe toast + evento WS em ≤5s quando demanda chega ao seu setor

**Independent Test**: quickstart Cenário 1 — Operador B recebe toast ao Operador A criar demanda; clicar abre `/tramitacao/demandas/:id`

### Tests for User Story 1 (TDD — RED first)

- [X] T023 [P] [US1] Escrever testes (RED) `resolve-tramitacao-recipients.service.spec.ts` em `ci-api-v2/src/modules/notificacao/services/resolve-tramitacao-recipients.service.spec.ts` — NT-007, NT-008
- [X] T024 [P] [US1] Escrever testes (RED) `dispatch-notificacao.service.spec.ts` em `ci-api-v2/src/modules/notificacao/services/dispatch-notificacao.service.spec.ts` — NT-009
- [X] T025 [P] [US1] Escrever testes (RED) `notificacao.gateway.spec.ts` em `ci-api-v2/src/modules/notificacao/notificacao.gateway.spec.ts` — NT-018, NT-019, NT-020
- [X] T026 [P] [US1] Escrever testes (RED) `create-demanda-notificacao.integration.spec.ts` em `ci-api-v2/src/modules/tramitacao/test/create-demanda-notificacao.integration.spec.ts` — NT-015

### Implementation for User Story 1 — API

- [X] T027 [US1] Implementar `resolve-tramitacao-recipients.service.ts` em `ci-api-v2/src/modules/notificacao/services/` (GREEN T023; usar Map/Set — skill `js-ts-performance-readability`)
- [X] T028 [US1] Implementar `dispatch-notificacao.service.ts` persist + emit gateway (GREEN T024)
- [X] T029 [US1] Implementar `notificacao.gateway.ts` namespace `/notifications` com JWT handshake e rooms (GREEN T025)
- [X] T030 [US1] Configurar `IoAdapter` Socket.IO em `ci-api-v2/src/main.ts`
- [X] T031 [US1] Exportar `DispatchNotificacaoService` em `ci-api-v2/src/modules/notificacao/notificacao.module.ts`; importar `NotificacaoModule` em `ci-api-v2/src/modules/tramitacao/tramitacao.module.ts`
- [X] T032 [US1] Hook dispatch `tramitacao_nova_demanda` em `ci-api-v2/src/modules/tramitacao/use-cases/create-generic-demanda.use-case.ts` (GREEN T026)
- [X] T033 [US1] Hook dispatch `tramitacao_nova_demanda` em `ci-api-v2/src/modules/tramitacao/use-cases/create-linked-demanda.use-case.ts`

### Implementation for User Story 1 — Client

- [X] T034 [P] [US1] Estender `ToastContext` com overload `{ title, body, actionLabel, onAction }` em `ci-client-v2/apps/web/src/modules/shared/context/ToastContext.tsx` — NT-025
- [X] T035 [P] [US1] Escrever testes (RED) `ToastContext.test.tsx` em `ci-client-v2/apps/web/src/modules/shared/context/__tests__/ToastContext.test.tsx`
- [X] T036 [US1] Implementar `useNotificationSocket.ts` em `ci-client-v2/apps/web/src/modules/notificacao/hooks/useNotificationSocket.ts` (auth token + reconnect)
- [X] T037 [US1] Implementar `NotificationProvider.tsx` em `ci-client-v2/apps/web/src/modules/notificacao/context/NotificationProvider.tsx` — montar provider no root autenticado (`vite-react-best-practices`: colocation, single WS connection)
- [X] T038 [US1] Wire WS `notification.created` → `showToast` com ação navegar em `NotificationProvider.tsx`
- [X] T039 [US1] Registrar `NotificationProvider` no layout autenticado em `ci-client-v2/apps/web/src/app/router.tsx` (dentro de `RequireAuth`, para `useNavigate` funcionar)

**Checkpoint**: MVP US1 — criar demanda dispara toast em tempo real no destinatário

---

## Phase 4: User Story 2 — Sino e histórico (Priority: P1)

**Goal**: Badge no header + dropdown com lista recente, navegação e sync REST

**Independent Test**: quickstart Cenário 2 — 3 notificações visíveis no sino; badge correto; click navega e marca lida

### Tests for User Story 2 (TDD — RED first)

- [X] T040 [P] [US2] Escrever testes (RED) `notificacao.controller.spec.ts` em `ci-api-v2/src/modules/notificacao/notificacao.controller.spec.ts` — NT-011, NT-012
- [X] T041 [P] [US2] Escrever testes (RED) `notificacao-mappers.test.ts` em `ci-client-v2/apps/web/src/modules/notificacao/lib/__tests__/notificacao-mappers.test.ts` — NT-021
- [X] T042 [P] [US2] Escrever testes (RED) `NotificationBell.test.tsx` em `ci-client-v2/apps/web/src/modules/notificacao/components/__tests__/NotificationBell.test.tsx` — NT-022, NT-023
- [X] T043 [P] [US2] Escrever testes (RED) `useNotificationSocket.test.ts` em `ci-client-v2/apps/web/src/modules/notificacao/hooks/__tests__/useNotificationSocket.test.ts` — NT-024

### Implementation for User Story 2 — API

- [X] T044 [P] [US2] Implementar `list-notificacoes.use-case.ts` em `ci-api-v2/src/modules/notificacao/use-cases/list-notificacoes.use-case.ts`
- [X] T045 [P] [US2] Implementar `get-unread-count.use-case.ts` em `ci-api-v2/src/modules/notificacao/use-cases/get-unread-count.use-case.ts`
- [X] T046 [US2] Implementar `notificacao.controller.ts` GET `/notificacoes` e GET `/notificacoes/unread-count` (GREEN T040)

### Implementation for User Story 2 — Client

- [X] T047 [P] [US2] Implementar API client em `ci-client-v2/apps/web/src/modules/notificacao/api/notificacoes.ts`
- [X] T048 [P] [US2] Implementar mappers API→UI em `ci-client-v2/apps/web/src/modules/notificacao/lib/notificacao-mappers.ts` (GREEN T041; skill `js-ts-data-transforms`)
- [X] T049 [US2] Estado REST + unread consolidado em `NotificationProvider.tsx` (equivalente a hook dedicado)
- [X] T050 [US2] Dropdown integrado em `NotificationBell.tsx` (DropdownMenu + ScrollArea — skill `ui-ux-pro-max`, paleta mint)
- [X] T051 [US2] Implementar `NotificationBell.tsx` com badge `99+` em `ci-client-v2/apps/web/src/modules/notificacao/components/NotificationBell.tsx` (GREEN T042)
- [X] T052 [US2] Integrar `NotificationBell` em `ci-client-v2/apps/web/src/modules/shell/components/layout/AppShell.tsx` (DesktopHeader)
- [X] T053 [US2] Integrar `NotificationBell` em `ci-client-v2/apps/web/src/modules/shell/components/layout/MobileAppHeader.tsx`
- [X] T054 [P] [US2] Criar MSW handlers em `ci-client-v2/apps/web/src/test/msw/handlers/notificacoes.ts` e registrar em handlers index
- [X] T055 [US2] Exportar módulo em `ci-client-v2/apps/web/src/modules/notificacao/index.ts`

**Checkpoint**: US1 + US2 — tempo real + sino funcional ponta a ponta

---

## Phase 5: User Story 3 — Resposta e encaminhamento (Priority: P2)

**Goal**: Remetente original notificado em resposta/encaminhamento; novo setor recebe nova demanda

**Independent Test**: quickstart Cenários 3 e 4 — autor da ação não recebe notificação redundante

### Tests for User Story 3 (TDD — RED first)

- [X] T056 [P] [US3] Escrever testes (RED) `reply-demanda-notificacao.integration.spec.ts` em `ci-api-v2/src/modules/tramitacao/test/reply-demanda-notificacao.integration.spec.ts` — NT-016
- [X] T057 [P] [US3] Escrever testes (RED) `forward-demanda-notificacao.integration.spec.ts` em `ci-api-v2/src/modules/tramitacao/test/forward-demanda-notificacao.integration.spec.ts` — NT-017

### Implementation for User Story 3

- [X] T058 [US3] Hook dispatch `tramitacao_resposta` em `ci-api-v2/src/modules/tramitacao/use-cases/reply-demanda.use-case.ts` (GREEN T056; excluir autor)
- [X] T059 [US3] Hook dispatch `tramitacao_encaminhamento` + `tramitacao_nova_demanda` em `ci-api-v2/src/modules/tramitacao/use-cases/forward-demanda.use-case.ts` (GREEN T057)

**Checkpoint**: Ciclo completo tramitação notifica todos os atores relevantes

---

## Phase 6: User Story 4 — Marcar como lidas (Priority: P3)

**Goal**: Marcar individual ou todas; badge sincroniza via REST e WS

**Independent Test**: quickstart Cenário 6 — marcar todas zera badge

### Tests for User Story 4 (TDD — RED first)

- [X] T060 [P] [US4] Estender testes (RED) PATCH read e read-all em `ci-api-v2/src/modules/notificacao/notificacao.controller.spec.ts` — NT-013, NT-014

### Implementation for User Story 4 — API

- [X] T061 [P] [US4] Implementar `mark-notificacao-read.use-case.ts` em `ci-api-v2/src/modules/notificacao/use-cases/mark-notificacao-read.use-case.ts`
- [X] T062 [P] [US4] Implementar `mark-all-notificacoes-read.use-case.ts` em `ci-api-v2/src/modules/notificacao/use-cases/mark-all-notificacoes-read.use-case.ts`
- [X] T063 [US4] Expor PATCH `/notificacoes/:id/read` e PATCH `/notificacoes/read-all` em `notificacao.controller.ts` (GREEN T060)
- [X] T064 [US4] Emitir `unread.count` via gateway após mark read em `dispatch-notificacao.service.ts` ou use cases

### Implementation for User Story 4 — Client

- [X] T065 [US4] Adicionar `markRead` e `markAllRead` em `ci-client-v2/apps/web/src/modules/notificacao/api/notificacoes.ts`
- [X] T066 [US4] Wire mark read on item click e botão "Marcar todas como lidas" em `NotificationBell.tsx`
- [X] T067 [US4] Sincronizar badge no `NotificationProvider.tsx` após mark read e evento WS `unread.count`

**Checkpoint**: Higiene de inbox completa

---

## Phase 7: User Story 5 — Extensibilidade linked records (Priority: P4)

**Goal**: Modelo polimórfico validado; registry aceita novo módulo sem migration destrutiva

**Independent Test**: quickstart Cenário 7 + unit test módulo hipotético `bolinhos`

### Tests for User Story 5 (TDD — RED first)

- [X] T068 [P] [US5] Escrever teste (RED) registry extensível para módulo `bolinhos` em `ci-client-v2/apps/web/src/modules/notificacao/lib/__tests__/notificacao-mappers.test.ts`
- [X] T069 [P] [US5] Escrever teste (RED) snapshot persistido com campos linked em `create-demanda-notificacao.integration.spec.ts` — validar `sourceModule`, `sourceSnapshot`

### Implementation for User Story 5

- [X] T070 [US5] Documentar contrato de extensão em comentário JSDoc em `ci-api-v2/src/modules/notificacao/lib/navigation-registry.ts` e `ci-client-v2/apps/web/src/modules/notificacao/lib/notificacao-mappers.ts`
- [X] T071 [US5] Adicionar entrada hipotética `bolinhos` no client registry apenas para teste (GREEN T068); confirmar API registry espelhado
- [X] T072 [US5] Garantir `sourceSnapshot` tramitação preenchido no dispatch em `dispatch-notificacao.service.ts` (GREEN T069)

**Checkpoint**: US5 validada por contrato + testes; v1 tramitação como consumer do framework

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Seed demo, validação manual, exports finais

- [ ] T073 [P] Criar seed opcional em `ci-api-v2/prisma/seed/seed-notificacao-demo.ts` e chamar de `ci-api-v2/prisma/seed.ts`
- [ ] T074 Executar validação manual `quickstart.md` Cenários 1–7 (dois usuários / duas abas)
- [X] T075 [P] Rodar `npm test -- --testPathPatterns=notificacao` em `ci-api-v2` e `npm test -- notificacao` em `ci-client-v2/apps/web`
- [X] T076 Revisar acessibilidade sino (`aria-label`, foco teclado) em `NotificationBell.tsx` — skill `ui-ux-pro-max`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Sem dependências
- **Foundational (Phase 2)**: Depende Setup — **BLOQUEIA** US1–US5
- **US1 (Phase 3)**: Depende Foundational — **MVP**
- **US2 (Phase 4)**: Depende Foundational; integra com US1 (provider/sino + WS já ativo)
- **US3 (Phase 5)**: Depende US1 dispatch service
- **US4 (Phase 6)**: Depende US2 REST + gateway (mark read endpoints)
- **US5 (Phase 7)**: Pode iniciar após Foundational; validação completa após US1
- **Polish (Phase 8)**: Depende US1–US5 desejadas

### User Story Dependencies

| Story | Depende de | Independente quando |
|-------|-----------|---------------------|
| US1 | Phase 2 | Toast + WS + create demanda |
| US2 | Phase 2 (+ US1 provider ideal) | REST list + sino sem toast |
| US3 | US1 dispatch | Reply/forward integration tests |
| US4 | US2 UI + mark repos | Mark read flows |
| US5 | Phase 2 schema | Registry + snapshot tests |

### Parallel Opportunities

- **Phase 1**: T002, T003, T004, T005 em paralelo
- **Phase 2**: T006–T011 (tests RED) em paralelo; T014–T020 (repos) em paralelo após schema
- **Phase 3**: T023–T026 (tests) em paralelo; T034–T035 (client tests) em paralelo
- **Phase 4**: T040–T043 em paralelo; T044–T045 + T047–T048 em paralelo
- **Phase 5**: T056–T057 em paralelo
- **Phase 6**: T061–T062 em paralelo
- **Phase 7**: T068–T069 em paralelo

---

## Parallel Example: User Story 1

```bash
# Tests RED em paralelo:
T023 resolve-tramitacao-recipients.service.spec.ts
T024 dispatch-notificacao.service.spec.ts
T025 notificacao.gateway.spec.ts
T026 create-demanda-notificacao.integration.spec.ts

# Client em paralelo após T034:
T035 ToastContext.test.tsx
T036 useNotificationSocket.ts
```

---

## Implementation Strategy

### MVP First (User Story 1 only)

1. Phase 1 Setup
2. Phase 2 Foundational (**crítico**)
3. Phase 3 User Story 1
4. **STOP** — validar quickstart Cenário 1
5. Demo: toast em tempo real ao criar demanda

### Incremental Delivery

1. Setup + Foundational → base persistida
2. US1 → toast tempo real (**MVP**)
3. US2 → sino + histórico (UX completa P1)
4. US3 → resposta/encaminhamento
5. US4 → marcar lidas
6. US5 → extensibilidade validada
7. Polish → seed + QA manual

### Parallel Team Strategy

- Dev A: API Foundational + US1 gateway/dispatch
- Dev B: Client US1 toast + US2 sino (após T037)
- Dev C: US3 hooks tramitação (após T028)

---

## Notes

- TDD: RED → GREEN → REFACTOR em cada task de teste
- `NotificacaoPermissao` **não** migrar — sino v1 só `Notificacao`
- Destinatário admin_tenant: FK `recipientAdminTenantId`, nunca `User.id` direto do JWT admin
- v1 sem Redis — documentar em README/comentário gateway
- Paleta mint: badge `#0F766E` / `#2DD4BF` (rule `mint-palette.mdc`)
- Total: **76 tasks** | US1: 17 | US2: 16 | US3: 4 | US4: 8 | US5: 5 | Setup: 5 | Foundational: 17 | Polish: 4
