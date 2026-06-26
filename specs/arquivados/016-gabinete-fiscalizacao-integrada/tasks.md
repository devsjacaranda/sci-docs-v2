---
description: "Task list for Fiscalização Gabinete integrada (016-gabinete-fiscalizacao-integrada)"
---

# Tasks: Fiscalização de Gestão — Gabinete (Jatobá)

**Input**: Design documents from `civ2-docs/specs/016-gabinete-fiscalizacao-integrada/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Tests**: **Obrigatórios** — TDD (constitution II + plan.md + `contracts/test-strategy.md`): unitário, componente, contrato, integração (mocks/in-memory) e E2E. **Sem Postgres de teste dedicado**.

**Organization**: US1–US5 são P1; US6–US9 são P2. Caminhos relativos à raiz `ci-v2/`. Submódulo API `gabinete-fiscalizacao` e página client **já existem parcialmente** (012) — tasks **completam** checagens, órfãos, painel, questionários e rastreio.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Pode executar em paralelo (arquivos diferentes, sem dependências pendentes)
- **[Story]**: User story da spec (US1–US9)

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Fixtures, MSW, samples para TDD

- [X] T001 [P] Criar fixture `ci-api-v2/src/modules/gabinete-fiscalizacao/test/fixtures/ato-fiscalizacao-sample.json` — ato com protocolo, controles vinculados, eventos e anexos
- [X] T002 [P] Criar fixture `ci-api-v2/src/modules/gabinete-fiscalizacao/test/fixtures/orphan-notificacao-sample.json` — notificação órfã com groupId sem auto pareado
- [X] T003 [P] Atualizar `ci-api-v2/src/modules/gabinete-fiscalizacao/test/fixtures/fiscalizacao-run-completed.json` e `fiscalizacao-panel-empty.json` — incluir `entityType`, achados órfãos e stats
- [X] T004 [P] Criar fixtures client `ci-client-v2/apps/web/src/modules/gabinete/fixtures/fiscalizacao-panel-completed.json` e `fiscalizacao-record-partial.json` conforme `contracts/client-gabinete-fiscalizacao-ui.md`
- [X] T005 [P] Implementar handlers MSW em `ci-client-v2/apps/web/src/test/msw/handlers/gabinete-fiscalizacao.ts` e registrar em `ci-client-v2/apps/web/src/test/msw/handlers.ts`
- [X] T006 [P] Documentar `FISCALIZACAO_CRON` (opcional) em `ci-api-v2/.env.example` se ausente

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Migration `entityType`, loaders ampliados, persistência e schemas — **bloqueia todas as user stories**

**⚠️ CRITICAL**: Nenhuma user story começa antes desta fase

### Tests first (TDD — RED)

- [X] T007 [P] Escrever testes (RED) `aggregate-ato-with-links.spec.ts` em `ci-api-v2/src/modules/gabinete-fiscalizacao/lib/aggregate-ato-with-links.spec.ts` — worst-of ato + protocolo + controles vinculados
- [X] T008 [P] Escrever testes (RED) `load-atos-for-fiscalizacao.repository.spec.ts`
- [X] T009 [P] Escrever testes (RED) `load-orphan-cadastros-for-fiscalizacao.repository.spec.ts`
- [X] T010 [P] Escrever testes de contrato (RED) em `ci-api-v2/src/modules/gabinete-fiscalizacao/gabinete-fiscalizacao.schemas.spec.ts` — panel response com `entityType`, `entityTypeLabel`, historyRows

### Schema & types

- [X] T011 Adicionar enum `FiscalizedEntityType` e alterar `GabineteFiscalizacaoResult` + `GabineteFiscalizacaoQuestionnaire` em `ci-api-v2/prisma/schema/gabinete-fiscalizacao.prisma` — `entityType`, `entityId`, `demandaId` opcional; unique `(runId, entityType, entityId)`; gerar migration em `ci-api-v2/prisma/migrations/`
- [X] T012 [P] Estender `ci-api-v2/src/modules/gabinete-fiscalizacao/gabinete-fiscalizacao.types.ts` — DTOs `AtoForFiscalizacao`, `OrphanCadastroForFiscalizacao`, `PairingContext`; constantes `CHECK_LABEL`/`CHECK_RULE_DESCRIPTION` novas regras
- [X] T013 [P] Estender `ci-api-v2/src/modules/gabinete-fiscalizacao/gabinete-fiscalizacao.mapper.ts` — `entityTypeLabel()`, `formatOrphanProtocolLabel()`, `FISCALIZED_DATA_SUMMARY` ampliado

### Implementation for Foundational

- [X] T014 Renomear/refatorar `ci-api-v2/src/modules/gabinete-fiscalizacao/repository/load-demandas-for-fiscalizacao.repository.ts` → `load-atos-for-fiscalizacao.repository.ts` com includes protocolo, controles, documentos (GREEN T008)
- [X] T015 [P] Implementar `ci-api-v2/src/modules/gabinete-fiscalizacao/repository/load-orphan-cadastros-for-fiscalizacao.repository.ts` (GREEN T009)
- [X] T016 [P] Implementar `ci-api-v2/src/modules/gabinete-fiscalizacao/lib/aggregate-ato-with-links.ts` (GREEN T007)
- [X] T017 Atualizar repositórios persistência em `ci-api-v2/src/modules/gabinete-fiscalizacao/repository/fiscalizacao-persistence.repositories.ts` — persistir `entityType`, `entityId`, `demandaId` opcional
- [X] T018 [P] Atualizar repositórios query em `ci-api-v2/src/modules/gabinete-fiscalizacao/repository/fiscalizacao-query.repositories.ts` — list results por entityType; history rows
- [X] T019 Estender Zod DTOs em `ci-api-v2/src/modules/gabinete-fiscalizacao/gabinete-fiscalizacao.schemas.ts` (GREEN T010)
- [X] T020 Refatorar `ci-api-v2/src/modules/gabinete-fiscalizacao/lib/run-checks-for-demanda.ts` → `run-checks-for-ato.ts`; atualizar imports no módulo e specs existentes
- [X] T021 [P] Registrar novos repositories em `ci-api-v2/src/modules/gabinete-fiscalizacao/gabinete-fiscalizacao.module.ts`

**Checkpoint**: Migration aplicada; loaders atos+órfãos GREEN; persistência aceita entityType; schemas validam panel estendido

---

## Phase 3: User Story 2 — Checagens automáticas ampliadas (Priority: P1)

**Goal**: Regras determinísticas ato + protocolo + controles vinculados — 6 domínios, worst-of agregado

**Independent Test**: `npm test -- --testPathPattern=gabinete-fiscalizacao/lib/checks` passa; fixture ato produz checagens protocolo/controles

> **Paralelo**: T022–T028 specs RED podem rodar em paralelo.

### Tests for User Story 2 (TDD — RED first)

- [X] T022 [P] [US2] Escrever testes (RED) `evidence.rules.spec.ts`
- [X] T023 [P] [US2] Escrever testes (RED) `protocol.rules.spec.ts` em `ci-api-v2/src/modules/gabinete-fiscalizacao/lib/checks/protocol.rules.spec.ts` — vínculo status avançado + completude campos críticos
- [X] T024 [P] [US2] Escrever testes (RED) `controle-numerico.rules.spec.ts` em `ci-api-v2/src/modules/gabinete-fiscalizacao/lib/checks/controle-numerico.rules.spec.ts`
- [X] T025 [P] [US2] Escrever testes (RED) `notificacao.rules.spec.ts` em `ci-api-v2/src/modules/gabinete-fiscalizacao/lib/checks/notificacao.rules.spec.ts` — prazo + completude
- [X] T026 [P] [US2] Escrever testes (RED) `auto-infracao.rules.spec.ts` em `ci-api-v2/src/modules/gabinete-fiscalizacao/lib/checks/auto-infracao.rules.spec.ts`
- [X] T027 [P] [US2] Escrever testes (RED) `pairing.rules.spec.ts` em `ci-api-v2/src/modules/gabinete-fiscalizacao/lib/checks/pairing.rules.spec.ts` — groupId com/sem par
- [X] T028 [P] [US2] Escrever testes (RED) `documento-tramitado.rules.spec.ts` em `ci-api-v2/src/modules/gabinete-fiscalizacao/lib/checks/documento-tramitado.rules.spec.ts`
- [X] T029 [P] [US2] Atualizar testes existentes `deadline.rules.spec.ts`, `forwarding.rules.spec.ts`, `completeness.rules.spec.ts`

### Implementation for User Story 2

- [X] T030 [P] [US2] Implementar `evidence.rules.ts` em `ci-api-v2/src/modules/gabinete-fiscalizacao/lib/checks/evidence.rules.ts` (GREEN T022)
- [X] T031 [P] [US2] Implementar `protocol.rules.ts` em `ci-api-v2/src/modules/gabinete-fiscalizacao/lib/checks/protocol.rules.ts` (GREEN T023)
- [X] T032 [P] [US2] Implementar `controle-numerico.rules.ts` em `ci-api-v2/src/modules/gabinete-fiscalizacao/lib/checks/controle-numerico.rules.ts` (GREEN T024)
- [X] T033 [P] [US2] Implementar `notificacao.rules.ts` em `ci-api-v2/src/modules/gabinete-fiscalizacao/lib/checks/notificacao.rules.ts` (GREEN T025)
- [X] T034 [P] [US2] Implementar `auto-infracao.rules.ts` em `ci-api-v2/src/modules/gabinete-fiscalizacao/lib/checks/auto-infracao.rules.ts` (GREEN T026)
- [X] T035 [P] [US2] Implementar `pairing.rules.ts` em `ci-api-v2/src/modules/gabinete-fiscalizacao/lib/checks/pairing.rules.ts` (GREEN T027)
- [X] T036 [P] [US2] Implementar `documento-tramitado.rules.ts` em `ci-api-v2/src/modules/gabinete-fiscalizacao/lib/checks/documento-tramitado.rules.ts` (GREEN T028)
- [X] T037 [US2] Completar `run-checks-for-ato.ts` em `ci-api-v2/src/modules/gabinete-fiscalizacao/lib/run-checks-for-ato.ts` — orquestra checagens ato + protocolo + controles vinculados via `aggregate-ato-with-links.ts`

**Checkpoint**: 10+ rule specs GREEN; orquestrador ato integra 6 domínios vinculados

---

## Phase 4: User Story 9 — Fiscalizar cadastros órfãos (Priority: P2)

**Goal**: Execução inclui registros standalone; painel exibe tipo e identificador órfão

**Independent Test**: Fixture órfã + run persiste result com `entityType=notificacao`; painel lista *Cadastro órfão — Notificação*

### Tests for User Story 9 (TDD — RED first)

- [X] T038 [P] [US9] Escrever testes (RED) `run-checks-for-orphan.spec.ts`
- [X] T039 [P] [US9] Escrever testes (RED) `run-fiscalizacao.use-case.spec.ts`

### Implementation for User Story 9

- [X] T040 [US9] Implementar `run-checks-for-orphan.ts` em `ci-api-v2/src/modules/gabinete-fiscalizacao/lib/run-checks-for-ato.ts` (GREEN T038)
- [X] T041 [US9] Estender `ci-api-v2/src/modules/gabinete-fiscalizacao/use-cases/run-fiscalizacao.use-case.ts` — carregar órfãos, PairingContext, persistir results por entityType (GREEN T039)
- [X] T042 [US9] Estender `ci-api-v2/src/modules/gabinete-fiscalizacao/use-cases/get-fiscalizacao-panel.use-case.ts` — findings/history com `entityTypeLabel` para órfãos
- [X] T043 [P] [US9] Estender `run-fiscalizacao-scoped.use-case.ts` — scoped ato (`on_record`) com `includeOrphans=false`

**Checkpoint**: Run completo analisa 100% atos + órfãos (SC-002); labels órfãos no panel DTO

---

## Phase 5: User Story 3 — Execuções persistidas, histórico e disparo (Priority: P1)

**Goal**: Throttle 1h, job agendado, histórico comparável, origens canônicas

**Independent Test**: Duas execuções persistidas; segunda manual < 1h → 429; histórico lista origem e resumo

### Tests for User Story 3 (TDD — RED first)

- [X] T044 [P] [US3] Escrever testes (RED) `list-fiscalizacao-runs.use-case.spec.ts`
- [X] T045 [P] [US3] Escrever testes (RED) `get-fiscalizacao-panel.use-case.spec.ts`
- [X] T046 [P] [US3] Escrever testes (RED) `throttle.spec.ts`

### Implementation for User Story 3

- [X] T047 [US3] Completar `list-fiscalizacao-runs.use-case.ts` e wiring controller `GET runs`
- [X] T048 [US3] Completar `get-fiscalizacao-panel.use-case.ts`
- [X] T049 [US3] Garantir `throttle.ts` + tratamento 429 `FISCALIZACAO_THROTTLED` no use case POST run
- [X] T050 [P] [US3] Verificar/completar `run-fiscalizacao-scheduled.job.ts`
- [X] T051 [US3] Estender `find-run-by-id` response no controller — checagens com tracePayload

**Checkpoint**: POST run persiste execução completa; GET panel/history/runs conforme contrato REST v2

---

## Phase 6: User Story 1 — Ver painel de Fiscalização no Gabinete (Priority: P1) 🎯 MVP

**Goal**: `/gabinete/auditoria` com stats, checagens, achados, histórico — substituir esqueleto

**Independent Test**: VS-001 quickstart — painel exibe dados reais após *Fiscalizar atos*; badge **Somente leitura**

### Tests for User Story 1 (TDD — RED first)

- [X] T052 [P] [US1] Escrever testes (RED) `fiscalizacao-mappers.spec.ts`
- [X] T053 [P] [US1] Escrever testes (RED) `GabineteAuditoriaPage.integration.test.tsx`

### Implementation for User Story 1

- [X] T054 [P] [US1] Estender `ci-client-v2/apps/web/src/modules/ouvidoria/components/FiscalizacaoPanel.tsx` — props configuráveis `moduleConfig` (título, botão *Fiscalizar atos*, coluna *Ato*) sem quebrar Ouvidoria
- [X] T055 [P] [US1] Implementar `ci-client-v2/apps/web/src/modules/gabinete/api/fiscalizacao-mappers.ts` — paridade ouvidoria + labels Gabinete (GREEN T052)
- [X] T056 [US1] Completar `ci-client-v2/apps/web/src/modules/gabinete/api/fiscalizacao.ts` — fetchPanel, fetchRunDetail, runFiscalizacao, tipos alinhados ao contrato REST v2
- [X] T057 [US1] Refatorar `ci-client-v2/apps/web/src/modules/gabinete/pages/GabineteAuditoriaPage.tsx` — reutilizar `FiscalizacaoPanel`, `FiscalizacaoRunsHistoryPanel`, feedback throttle (GREEN T053)
- [X] T058 [P] [US1] Exportar tipos em `ci-client-v2/apps/web/src/modules/gabinete/index.ts`

**Checkpoint**: Painel Gabinete funcional ponta a ponta com API real ou MSW — MVP demonstrável

---

## Phase 7: User Story 4 — Rastreabilidade Jatobá (Priority: P1)

**Goal**: Sheets com títulos canônicos; endpoints trace; tracePayload nos checks/findings

**Independent Test**: Click checagem → sheet **Por que esta checagem deu este resultado** (~85% viewport)

### Tests for User Story 4 (TDD — RED first)

- [X] T059 [P] [US4] Escrever testes (RED) `get-check-trace.use-case.spec.ts` e finding trace
- [X] T060 [P] [US4] Escrever testes (RED) `FiscalizacaoTraceSheet.test.tsx`

### Implementation for User Story 4

- [X] T061 [P] [US4] Implementar use-cases trace (`get-check-trace`, `get-finding-trace`, `get-result-trace`)
- [X] T062 [US4] Adicionar rotas trace no controller
- [X] T063 [US4] Wire `FiscalizacaoTraceSheet` em `GabineteAuditoriaPage.tsx`
- [X] T064 [P] [US4] Estender client API `fiscalizacao.ts` — fetch trace endpoints

**Checkpoint**: 100% checagens/achados com rastreio sheet (SC-004)

---

## Phase 8: User Story 5 — Governança read-only (Priority: P1)

**Goal**: Guards módulo + Jatobá; fiscalização não altera atos/cadastros

**Independent Test**: Usuário sem módulo → 403; snapshot ato idêntico pós-run (SC-005)

### Tests for User Story 5 (TDD — RED first)

- [X] T065 [P] [US5] Escrever testes E2E (RED) `ci-api-v2/test/gabinete-fiscalizacao.e2e-spec.ts` — guards 403, throttle 429, read-only SC-005
- [X] T066 [P] [US5] Escrever testes (RED) `GabineteAuditoriaPage.e2e.test.tsx` em `ci-client-v2/apps/web/src/modules/gabinete/__tests__/GabineteAuditoriaPage.e2e.test.tsx` — AccessDenied403 sem permissão

### Implementation for User Story 5

- [X] T067 [US5] Completar E2E API `ci-api-v2/test/gabinete-fiscalizacao.e2e-spec.ts` — Supertest com deps mockadas (GREEN T065)
- [X] T068 [US5] Completar E2E client `GabineteAuditoriaPage.e2e.test.tsx` — jornada autorizado vs 403 (GREEN T066)
- [X] T069 [P] [US5] Verificar guards `@RequireModulo('gabinete')` + `@RequireLicenca('jatoba')` em todas as rotas novas do controller

**Checkpoint**: Governança e read-only validados automatizados

---

## Phase 9: User Story 7 — Banco de perguntas Gabinete (Priority: P2)

**Goal**: CRUD perguntas domínio Gabinete; seed Jacaranda; distinto de Ouvidoria

**Independent Test**: GET questions retorna seed Gabinete; POST cria pergunta internal-only

> **Nota**: US7 antes de US6 — questionários dependem do banco.

### Tests for User Story 7 (TDD — RED first)

- [X] T070 [P] [US7] Escrever testes (RED) `list-questions.use-case.spec.ts` e `upsert-question.use-case.spec.ts` em `ci-api-v2/src/modules/gabinete-fiscalizacao/test/use-cases/`

### Implementation for User Story 7

- [X] T071 [P] [US7] Implementar use-cases questions em `ci-api-v2/src/modules/gabinete-fiscalizacao/use-cases/list-fiscalizacao-questions.use-case.ts`, `create-fiscalizacao-question.use-case.ts`, `update-fiscalizacao-question.use-case.ts` (GREEN T070)
- [X] T072 [US7] Adicionar rotas `GET/POST/PATCH /gabinete/fiscalizacao/questions` no controller
- [X] T073 [P] [US7] Criar `ci-api-v2/prisma/seed/seed-fiscalizacao-questions-gabinete.ts` — 4–6 perguntas internal; registrar em `ci-api-v2/prisma/seed/seed-jacaranda-tenant.ts`
- [X] T074 [US7] Wire `QuestionBankPanel` em `GabineteAuditoriaPage.tsx` — API Gabinete questions; ocultar opção externa

**Checkpoint**: Banco perguntas Gabinete operacional com seed demo

---

## Phase 10: User Story 6 — Questionários internos (Priority: P2)

**Goal**: Criar/responder questionários internos; histórico reflete Destinatário *Interno*

**Independent Test**: VS-007 quickstart — questionário criado, respondido, histórico atualizado

### Tests for User Story 6 (TDD — RED first)

- [X] T075 [P] [US6] Escrever testes (RED) `create-questionnaire.use-case.spec.ts` e `submit-questionnaire-answers.use-case.spec.ts` em `ci-api-v2/src/modules/gabinete-fiscalizacao/test/use-cases/`

### Implementation for User Story 6

- [X] T076 [US6] Implementar use-cases questionnaires em `ci-api-v2/src/modules/gabinete-fiscalizacao/use-cases/create-fiscalizacao-questionnaire.use-case.ts`, `list-fiscalizacao-questionnaires.use-case.ts`, `submit-fiscalizacao-questionnaire-answers.use-case.ts` (GREEN T075) — internal only; entityType+entityId para órfãos
- [X] T077 [US6] Adicionar rotas questionnaires no controller conforme `contracts/rest-api-gabinete-fiscalizacao.md`
- [X] T078 [US6] Integrar `QuestionnaireDialog` em `GabineteAuditoriaPage.tsx` — somente destinatário Interno; sem opção externa
- [X] T079 [US6] Atualizar `get-fiscalizacao-panel.use-case.ts` — historyRows com questionnaireTitle, recipientLabel, channelLabel reais

**Checkpoint**: Questionário interno ponta a ponta (SC-007)

---

## Phase 11: User Story 8 — Fiscalização contextual no detalhe do ato (Priority: P2)

**Goal**: Card **Fiscalização Jatobá deste registro** + *Fiscalizar dados* scoped

**Independent Test**: VS-006 quickstart — card no detalhe; scoped run atualiza checagens ≤ 5s

### Tests for User Story 8 (TDD — RED first)

- [X] T080 [P] [US8] Escrever testes (RED) `get-fiscalizacao-record.use-case.spec.ts` em `ci-api-v2/src/modules/gabinete-fiscalizacao/test/use-cases/get-fiscalizacao-record.use-case.spec.ts`
- [X] T081 [P] [US8] Escrever testes (RED) `GabineteFiscalizacaoRecordCard.test.tsx` em `ci-client-v2/apps/web/src/modules/gabinete/__tests__/GabineteFiscalizacaoRecordCard.test.tsx`

### Implementation for User Story 8

- [X] T082 [US8] Implementar `get-fiscalizacao-record.use-case.ts` + rota `GET /gabinete/fiscalizacao/atos/:cabinetId`
- [X] T083 [US8] Criar `GabineteFiscalizacaoRecordCard.tsx`
- [X] T084 [US8] Integrar card na página detalhe do ato + client API `fetchGabineteFiscalizacaoRecord`
- [X] T085 [P] [US8] Adicionar rota `POST /gabinete/fiscalizacao/run/atos/:cabinetId`

**Checkpoint**: Card detalhe operacional com scoped run (SC-010)

---

## Phase 12: Polish & Cross-Cutting Concerns

**Purpose**: Validação final, docs, regressão Ouvidoria

- [X] T086 [P] Atualizar `ci-api-v2/src/modules/gabinete-fiscalizacao/test/fixtures/` — cobrir todos entityTypes em run completed
- [X] T087 [P] Regression: `npm test -- --testPathPattern=ouvidoria-fiscalizacao` — componentes ouvidoria intactos após props `moduleConfig`
- [X] T088 Executar suíte completa conforme `quickstart.md` §1 — API + client GREEN
- [X] T089 Validar manualmente VS-001…VS-009 em `civ2-docs/specs/016-gabinete-fiscalizacao-integrada/quickstart.md`
- [X] T090 Criar `civ2-docs/specs/016-gabinete-fiscalizacao-integrada/STATUS.md` — entregas, comandos validação, dívidas

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Sem dependências — iniciar imediatamente
- **Foundational (Phase 2)**: Depende Setup — **BLOQUEIA** todas as user stories
- **US2 (Phase 3)**: Depende Foundational — bloqueia US9 parcialmente e US1 (dados reais)
- **US9 (Phase 4)**: Depende US2 (regras órfãos) + Foundational
- **US3 (Phase 5)**: Depende US2/US9 (run completo); pode overlap com US9
- **US1 (Phase 6)**: Depende US3 (panel API estável) — **MVP UI**
- **US4 (Phase 7)**: Depende US1 (painel com checagens clicáveis)
- **US5 (Phase 8)**: Depende US3 (run) — pode paralelizar com US1 após US3
- **US7 (Phase 9)**: Depende Foundational — independente de US1
- **US6 (Phase 10)**: Depende US7 (banco perguntas) + US3 (histórico)
- **US8 (Phase 11)**: Depende US2/US3 (record use-case + scoped run)
- **Polish (Phase 12)**: Depende stories desejadas completas

### User Story Dependencies

| Story | Depende de | Independente quando |
|-------|------------|---------------------|
| US2 | Foundational | Rules unit sem DB |
| US9 | US2, Foundational | Run com órfãos |
| US3 | US2, US9 | Throttle/history API |
| US1 | US3 | Painel client MSW/API |
| US4 | US1 | Trace sheets |
| US5 | US3 | E2E guards/read-only |
| US7 | Foundational | Questions CRUD |
| US6 | US7, US3 | Questionários + histórico |
| US8 | US2, US3 | Card detalhe |

### Parallel Opportunities

- **Phase 1**: T001–T006 todos [P]
- **Phase 2 RED**: T007–T010 [P]
- **Phase 3 RED**: T022–T029 [P]; **GREEN rules**: T030–T036 [P]
- **Phase 6 + 7**: Após US3, client US1 (T052–T058) paralelo a trace API US4 (T059–T062)
- **Phase 9 US7**: Paralelo a US1/US4 após Foundational

### Parallel Example: User Story 2

```bash
# RED em paralelo:
T022 evidence.rules.spec.ts
T023 protocol.rules.spec.ts
T024 controle-numerico.rules.spec.ts
T025 notificacao.rules.spec.ts
T026 auto-infracao.rules.spec.ts
T027 pairing.rules.spec.ts
T028 documento-tramitado.rules.spec.ts

# GREEN em paralelo (após RED):
T030–T036 implementação das rules
```

---

## Implementation Strategy

### MVP First (User Story 1 via US2 + US3)

1. Phase 1: Setup
2. Phase 2: Foundational (**crítico**)
3. Phase 3: US2 — checagens ampliadas
4. Phase 4: US9 — órfãos no run
5. Phase 5: US3 — execuções/histórico
6. Phase 6: US1 — **painel funcional (MVP demonstrável)**
7. **STOP and VALIDATE** VS-001…VS-004 quickstart

### Incremental Delivery

1. Setup + Foundational → base schema/loaders
2. US2 + US9 + US3 → API fiscalização completa
3. US1 → painel client (MVP!)
4. US4 + US5 → rastreio + governança
5. US7 + US6 → questionários
6. US8 → card detalhe
7. Polish → VS completo + STATUS

### Suggested MVP Scope

**MVP mínimo**: Phase 1–6 (T001–T058) — painel Gabinete com checagens reais (atos + órfãos), execuções e histórico.

**MVP completo Jatobá (spec)**: + Phase 7–11 (rastreio, governança, questionários, card detalhe).

---

## Notes

- Total: **90 tasks** (T001–T090)
- US1: 7 tasks | US2: 16 | US3: 8 | US4: 6 | US5: 5 | US6: 5 | US7: 5 | US8: 6 | US9: 6 | Setup: 6 | Foundational: 15 | Polish: 5
- Verificar RED antes de GREEN em cada fase TDD
- Não reimplementar CRUD Base Gabinete (012) — apenas consumir leitura
- Gabinete **sem** questionário externo — omitir rotas public controller
