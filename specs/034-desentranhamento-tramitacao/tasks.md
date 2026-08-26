# Tasks: Desentranhamento de Documentos em Tramitação

**Input**: Design documents from `civ2-docs/specs/034-desentranhamento-tramitacao/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/desentranhamento-api.md, quickstart.md

**Tests**: TDD obrigatório (Constitution II — RED → GREEN → REFACTOR). Skills: `tdd`, `testing-conventions` (API), Vitest no client.

**Organization**: Tasks grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **API**: `ci-api-v2/src/modules/tramitacao/` (e `ci-api-v2/src/modules/notificacao/` para notificações)
- **Client**: `ci-client-v2/apps/web/src/modules/tramitacao/`
- **Schema**: `ci-api-v2/prisma/schema/`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Schema Prisma e migration — base de dados para todo o fluxo

- [x] T001 Adicionar campo `desentranhadoAt DateTime?` em `TramitacaoDemandaAnexo`, estender enum `TramitacaoDemandaEventType` com `desentranhamento_solicitado|aprovado|rejeitado`, criar enums `TramitacaoDesentranhamentoStatus`/`TramitacaoDesentranhamentoDirection` e model `TramitacaoDemandaAnexoDesentranhamento` com relations em `ci-api-v2/prisma/schema/tramitacao.prisma`
- [x] T002 Adicionar valores `tramitacao_desentranhamento_solicitado|aprovado|rejeitado` ao enum `NotificacaoType` em `ci-api-v2/prisma/schema/notificacao.prisma`
- [x] T003 Criar migration `ci-api-v2/prisma/migrations/<timestamp>_tramitacao_desentranhamento/migration.sql` incluindo índice único parcial `tramitacao_desentranhamento_pending_unique` (ver `data-model.md`) e rodar `npx prisma generate` em `ci-api-v2/`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Infraestrutura compartilhada que BLOQUEIA todas as user stories

**⚠️ CRITICAL**: Nenhuma user story pode começar antes desta fase

- [x] T004 [P] Implementar `resolveDesentranhamentoDirection` e `resolveDesentranhamentoApprovers` (reutilizando `ResolveTramitacaoRecipientsService.forPersonalOtherParticipant` / `forNovaDemanda` + `excludeActor`) em `ci-api-v2/src/modules/tramitacao/lib/resolve-desentranhamento-approvers.ts`
- [x] T005 [P] Escrever testes unitários RED para `resolve-desentranhamento-approvers` em `ci-api-v2/src/modules/tramitacao/lib/resolve-desentranhamento-approvers.spec.ts` (cenários setorial vs. caixa pessoal, `author_requests` vs. `recipient_requests`)
- [x] T006 [P] Estender `resolveAnexoAccessLevel` para considerar `desentranhadoAt` (gate adicional: `'full'` só para autor, ACL confidencial, `admin_tenant`/`admin_saas`) em `ci-api-v2/src/modules/tramitacao/lib/resolve-anexo-access.ts`
- [x] T007 [P] Escrever/atualizar testes RED para acesso pós-desentranhamento em `ci-api-v2/src/modules/tramitacao/lib/resolve-anexo-access.spec.ts`
- [x] T008 Implementar repositório de desentranhamento (`create`, `findPendingByAnexoId`, `findById`, `decide` com `updateMany` condicional `status=pending`) em `ci-api-v2/src/modules/tramitacao/repository/desentranhamento.repositories.ts`
- [x] T009 [P] Adicionar schemas Zod `requestDesentranhamentoBodySchema` e `decideDesentranhamentoBodySchema` + DTOs `createZodDto` em `ci-api-v2/src/modules/tramitacao/tramitacao.schemas.ts`
- [ ] T010 [P] Escrever testes de schema RED em `ci-api-v2/src/modules/tramitacao/tramitacao.schemas.spec.ts` (reason opcional, max 1000 chars)
- [x] T011 Estender `GetDemandaByIdRepository` / queries de anexo em `ci-api-v2/src/modules/tramitacao/repository/demanda.repositories.ts` para filtrar anexos normais (`desentranhadoAt: null`) e incluir anexos desentranhados + solicitações associadas na visão de histórico
- [x] T012 [P] Adicionar `forDesentranhamentoApprovers(demanda, requesterActor)` em `ci-api-v2/src/modules/notificacao/services/resolve-tramitacao-recipients.service.ts` (delegando para lib de approvers)
- [x] T013 Estender `EVENT_TYPE_LABELS` e helper de mapeamento de anexo (`desentranhamento` block: status, canApprove, canRequest) em `ci-api-v2/src/modules/tramitacao/tramitacao.mapper.ts`
- [x] T014 Registrar novos providers (repository + use-cases placeholder) em `ci-api-v2/src/modules/tramitacao/tramitacao.module.ts`

**Checkpoint**: Foundation ready — user story implementation can now begin

---

## Phase 3: User Story 1 — Autor solicita desentranhamento (Priority: P1) 🎯 MVP

**Goal**: Autor do anexo solicita; contraparte (setor atual ou outro usuário da caixa pessoal) aprova ou rejeita; anexo desaparece da listagem normal mas permanece no histórico para quem tinha acesso original

**Independent Test**: Anexar documento em demanda aberta → autor solicita → contraparte aprova → anexo some da listagem padrão mas aparece no histórico com badge "desentranhado" para quem tinha acesso (ver `quickstart.md` Cenário 1)

### Tests for User Story 1 ⚠️

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [x] T015 [P] [US1] Escrever teste de integração RED — fluxo autor solicita + contraparte aprova (evento timeline, `desentranhadoAt`, anexo omitido da listagem normal) em `ci-api-v2/src/modules/tramitacao/test/desentranhamento-author-approve.integration.spec.ts`
- [ ] T016 [P] [US1] Escrever teste de integração RED — fluxo autor solicita + contraparte rejeita (anexo inalterado, evento `desentranhamento_rejeitado`) em `ci-api-v2/src/modules/tramitacao/test/desentranhamento-author-reject.integration.spec.ts`
- [ ] T017 [P] [US1] Escrever teste de integração RED — histórico pós-aprovação respeita `resolveAnexoAccessLevel` (autor/admin veem conteúdo; terceiro vê placeholder) em `ci-api-v2/src/modules/tramitacao/test/desentranhamento-access.integration.spec.ts`

### Implementation for User Story 1

- [x] T018 [US1] Implementar `RequestDesentranhamentoUseCase` (validações FR-004/005/015, `direction=author_requests`, evento `desentranhamento_solicitado`, `resolveUserTableId`/`withActorPayload`) em `ci-api-v2/src/modules/tramitacao/use-cases/request-desentranhamento.use-case.ts`
- [x] T019 [US1] Implementar `ApproveDesentranhamentoUseCase` (verificar aprovador elegível, `updateMany` condicional, setar `desentranhadoAt`, evento `desentranhamento_aprovado`) em `ci-api-v2/src/modules/tramitacao/use-cases/approve-desentranhamento.use-case.ts`
- [x] T020 [US1] Implementar `RejectDesentranhamentoUseCase` (verificar aprovador elegível, `updateMany` condicional, evento `desentranhamento_rejeitado`) em `ci-api-v2/src/modules/tramitacao/use-cases/reject-desentranhamento.use-case.ts`
- [x] T021 [US1] Estender `GetDemandaDetailUseCase` para expor bloco `desentranhamento` por anexo via mapper em `ci-api-v2/src/modules/tramitacao/use-cases/get-demanda-detail.use-case.ts`
- [x] T022 [US1] Estender `DownloadAnexoUseCase` para negar download quando `resolveAnexoAccessLevel` retornar `'placeholder'` por desentranhamento em `ci-api-v2/src/modules/tramitacao/use-cases/download-anexo.use-case.ts`
- [x] T023 [US1] Adicionar rotas `POST .../anexos/:anexoId/desentranhamento`, `POST .../desentranhamento/:solicitacaoId/approve`, `POST .../desentranhamento/:solicitacaoId/reject` em `ci-api-v2/src/modules/tramitacao/tramitacao.controller.ts`
- [x] T024 [P] [US1] Adicionar funções API client `requestDesentranhamento`, `approveDesentranhamento`, `rejectDesentranhamento` em `ci-client-v2/apps/web/src/modules/tramitacao/api/anexos.ts`
- [x] T025 [P] [US1] Estender tipos Zod/view `TramitacaoAnexoView` com bloco `desentranhamento` em `ci-client-v2/apps/web/src/modules/tramitacao/lib/anexo-schemas.ts`
- [x] T026 [US1] Adicionar ações inline (solicitar / aprovar / rejeitar) e badge de status por anexo em `ci-client-v2/apps/web/src/modules/tramitacao/components/TramitacaoAnexoList.tsx`
- [x] T027 [US1] Exibir anexos desentranhados na seção de histórico com indicação visual clara em `ci-client-v2/apps/web/src/modules/tramitacao/components/TramitacaoInboxWorkspace.tsx`
- [ ] T028 [P] [US1] Escrever testes Vitest para componente de anexo (badge + botões condicionais `canApprove`/`canRequest`) em `ci-client-v2/apps/web/src/modules/tramitacao/components/__tests__/TramitacaoAnexoList.desentranhamento.test.tsx`

**Checkpoint**: User Story 1 funcional e testável de forma independente (MVP)

---

## Phase 4: User Story 2 — Contraparte solicita desentranhamento (Priority: P2)

**Goal**: Usuário do lado receptor (não autor) solicita; autor do anexo aprova ou rejeita (`direction=recipient_requests`)

**Independent Test**: Usuário B anexa → usuário A (receptor) solicita → B aprova/rejeita; pedido criado com `recipient_requests` (ver `quickstart.md` Cenário 2)

### Tests for User Story 2 ⚠️

- [ ] T029 [P] [US2] Escrever teste de integração RED — fluxo receptor solicita + autor aprova em `ci-api-v2/src/modules/tramitacao/test/desentranhamento-recipient-approve.integration.spec.ts`
- [ ] T030 [P] [US2] Escrever teste de integração RED — fluxo receptor solicita + autor rejeita em `ci-api-v2/src/modules/tramitacao/test/desentranhamento-recipient-reject.integration.spec.ts`

### Implementation for User Story 2

- [x] T031 [US2] Garantir que `RequestDesentranhamentoUseCase` resolve `direction=recipient_requests` quando solicitante ≠ autor do anexo e que aprovadores = autor do anexo (`uploadedByUserId`) em `ci-api-v2/src/modules/tramitacao/use-cases/request-desentranhamento.use-case.ts`
- [x] T032 [US2] Ajustar UI para exibir corretamente quem pode decidir quando `direction=recipient_requests` (autor vê botões aprovar/rejeitar) em `ci-client-v2/apps/web/src/modules/tramitacao/components/TramitacaoAnexoList.tsx`

**Checkpoint**: User Stories 1 e 2 funcionam de forma independente (fluxo bidirecional completo)

---

## Phase 5: User Story 3 — Notificações in-app (Priority: P3)

**Goal**: Aprovadores recebem notificação ao criar pedido; solicitante recebe notificação ao aprovar/rejeitar

**Independent Test**: Solicitar desentranhamento → verificar `GET /notificacoes` ou evento WebSocket `notification.created` para aprovadores; decidir → solicitante recebe notificação de resultado (ver `quickstart.md` + spec US3)

### Tests for User Story 3 ⚠️

- [ ] T033 [P] [US3] Escrever teste de integração RED — `notifyDesentranhamentoSolicitado` dispara para aprovadores elegíveis em `ci-api-v2/src/modules/tramitacao/test/desentranhamento-notificacao-solicitado.integration.spec.ts`
- [ ] T034 [P] [US3] Escrever teste de integração RED — `notifyDesentranhamentoAprovado`/`Rejeitado` dispara para solicitante em `ci-api-v2/src/modules/tramitacao/test/desentranhamento-notificacao-decisao.integration.spec.ts`

### Implementation for User Story 3

- [x] T035 [P] [US3] Adicionar labels em `TYPE_LABELS` para os 3 novos tipos em `ci-api-v2/src/modules/notificacao/notificacao.mapper.ts`
- [x] T036 [US3] Implementar `notifyDesentranhamentoSolicitado`, `notifyDesentranhamentoAprovado`, `notifyDesentranhamentoRejeitado` em `ci-api-v2/src/modules/notificacao/services/tramitacao-notificacao.service.ts` (reutilizar `sourceModule: 'tramitacao'`, `sourceRecordId: demandaId`)
- [x] T037 [US3] Integrar chamadas de notificação nos use-cases `request-desentranhamento`, `approve-desentranhamento` e `reject-desentranhamento` em `ci-api-v2/src/modules/tramitacao/use-cases/`
- [ ] T038 [P] [US3] Espelhar labels de notificação no client (se aplicável) em `ci-client-v2/apps/web/src/modules/notificacao/lib/notificacao-mappers.ts`

**Checkpoint**: Todas as user stories independentemente funcionais com notificações

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Edge cases, concorrência e validação final

- [ ] T039 [P] Escrever testes RED para edge cases — `PENDING_REQUEST_EXISTS`, `ANEXO_ALREADY_DESENTRANHADO`, `NO_APPROVER_AVAILABLE`, `DEMANDA_ARCHIVED`, decisão em demanda arquivada (FR-016) em `ci-api-v2/src/modules/tramitacao/test/desentranhamento-edge-cases.integration.spec.ts`
- [ ] T040 [P] Escrever teste RED de concorrência — duas decisões simultâneas, apenas uma vence (`ALREADY_DECIDED`) em `ci-api-v2/src/modules/tramitacao/test/desentranhamento-concurrency.integration.spec.ts`
- [ ] T041 Implementar tratamento de erros de negócio com códigos do contrato (`409`, `422`, `403`) nos use-cases em `ci-api-v2/src/modules/tramitacao/use-cases/request-desentranhamento.use-case.ts`, `approve-desentranhamento.use-case.ts`, `reject-desentranhamento.use-case.ts`
- [ ] T042 [P] Renderizar novos tipos de evento na timeline (labels + payload) em `ci-client-v2/apps/web/src/modules/tramitacao/components/TramitacaoInboxWorkspace.tsx` e/ou `TramitacaoConversationThread.tsx`
- [ ] T043 Executar roteiro de validação ponta a ponta descrito em `civ2-docs/specs/034-desentranhamento-tramitacao/quickstart.md` (Cenários 1–3)
- [ ] T044 Rodar suíte completa: `cd ci-api-v2; npm test -- --testPathPatterns=desentranhamento` e `cd ci-client-v2/apps/web; npm test -- TramitacaoAnexoList.desentranhamento`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Sem dependências — iniciar imediatamente
- **Foundational (Phase 2)**: Depende de Phase 1 — **BLOQUEIA** todas as user stories
- **User Stories (Phase 3–5)**: Dependem de Phase 2
  - US1 (P1) primeiro — MVP
  - US2 (P2) após ou em paralelo com US1 (mesmos use-cases; testes adicionais)
  - US3 (P3) após US1 (notificações dependem dos use-cases existentes)
- **Polish (Phase 6)**: Depende de US1–US3 desejadas

### User Story Dependencies

| Story | Depende de | Independente? |
|-------|-----------|---------------|
| **US1 (P1)** | Phase 2 | ✅ Sim — MVP completo sem US2/US3 |
| **US2 (P2)** | Phase 2 + US1 use-cases base | ✅ Testável isoladamente (direction invertido) |
| **US3 (P3)** | Phase 2 + use-cases de US1 | ✅ Testável isoladamente (notificações podem ser adicionadas depois) |

### Within Each User Story

1. Tests RED primeiro (T015–T017, T029–T030, T033–T034)
2. Use-cases / services
3. Controller / mapper
4. Client API + UI
5. Tests GREEN + REFACTOR

### Parallel Opportunities

- **Phase 1**: T001 e T002 em paralelo (arquivos Prisma distintos)
- **Phase 2**: T004+T005, T006+T007, T009+T010, T012 em paralelo após T003
- **US1 tests**: T015, T016, T017 em paralelo
- **US1 client**: T024, T025, T028 em paralelo após T023
- **US2 tests**: T029, T030 em paralelo
- **US3 tests**: T033, T034 em paralelo; T035 e T038 em paralelo
- **Polish**: T039, T040, T042 em paralelo

---

## Parallel Example: User Story 1

```bash
# 1. Tests RED em paralelo (Phase 3):
T015: desentranhamento-author-approve.integration.spec.ts
T016: desentranhamento-author-reject.integration.spec.ts
T017: desentranhamento-access.integration.spec.ts

# 2. Após API pronta (T023), client em paralelo:
T024: api/anexos.ts
T025: lib/anexo-schemas.ts
T028: TramitacaoAnexoList.desentranhamento.test.tsx
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001–T003)
2. Complete Phase 2: Foundational (T004–T014)
3. Complete Phase 3: User Story 1 (T015–T028)
4. **STOP and VALIDATE**: `quickstart.md` Cenário 1
5. Demo/deploy se pronto

### Incremental Delivery

1. Setup + Foundational → base pronta
2. US1 → MVP (solicitar/aprovar/rejeitar autor→contraparte + histórico)
3. US2 → fluxo bidirecional (contraparte→autor)
4. US3 → notificações in-app
5. Polish → edge cases + concorrência

### Parallel Team Strategy

1. Dev A: Phase 1 + Phase 2 (schema + lib + repository)
2. Após Phase 2:
   - Dev A: US1 API (use-cases + controller)
   - Dev B: US1 Client (api + UI)
   - Dev C: US3 notificações (após use-cases base de US1)

---

## Notes

- FK `User`: sempre `resolveUserTableId` + `withActorPayload` para `admin_tenant`/`admin_saas` (rule `admin-tenant-user-fk`)
- Não alterar regras de confidencialidade (033) — desentranhamento compõe, não substitui ACL
- Anexo nunca é apagado — apenas `desentranhadoAt` preenchido
- `[P]` = arquivos diferentes, sem dependência de tarefa incompleta no mesmo arquivo
- Commit após cada task ou grupo lógico (RED test → GREEN impl → REFACTOR)
