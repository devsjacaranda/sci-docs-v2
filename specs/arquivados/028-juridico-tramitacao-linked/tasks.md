---
description: "Task list for Integrar Jurídico à Tramitação — Linked Record (028-juridico-tramitacao-linked)"
---

# Tasks: Integrar Jurídico à Tramitação — Linked Record

**Input**: Design documents from `civ2-docs/specs/028-juridico-tramitacao-linked/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Tests**: **Obrigatórios** — TDD (constitution II + plan.md + `contracts/test-strategy.md`): unitário, integração (mocks Prisma) e Vitest/MSW client. **Sem migration**; **sem Postgres de teste dedicado**.

**Organization**: 4 user stories (US1–US4). Caminhos relativos à raiz `ci-v2/`.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Pode executar em paralelo (arquivos diferentes, sem dependências pendentes)
- **[Story]**: User story da spec (US1–US4)

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Verificar módulos existentes e preparar stubs de teste/client

- [X] T001 Verificar `TramitacaoModule` exporta `CreateLinkedDemandaUseCase` e `ResolveTramitacaoSectorUseCase` em `ci-api-v2/src/modules/tramitacao/tramitacao.module.ts`
- [X] T002 [P] Criar diretório `ci-api-v2/src/modules/juridico/test/lib/` para specs de mapper snapshot
- [X] T003 [P] Adicionar stubs GET list/detail em `ci-client-v2/apps/web/src/test/msw/handlers/juridico.ts`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Snapshot v2 + wiring setor origem — **bloqueia US1 (tramitar) e US3 (linked record)**

**⚠️ CRITICAL**: Nenhuma user story de tramitação/linked começa antes desta fase

### Tests first (TDD — RED)

- [X] T004 [P] Escrever testes (RED) `process-tramitacao-snapshot.mapper.spec.ts` em `ci-api-v2/src/modules/juridico/test/lib/process-tramitacao-snapshot.mapper.spec.ts` — CT-JT-001

### Implementation

- [X] T005 Implementar snapshot `schemaVersion: 2` com labels em `ci-api-v2/src/modules/juridico/lib/process-tramitacao-snapshot.mapper.ts` (GREEN T004)
- [X] T006 [P] Injetar `ResolveTramitacaoSectorUseCase` em `ci-api-v2/src/modules/juridico/juridico.module.ts` (import `TramitacaoModule` se necessário)
- [X] T007 [P] Adicionar helpers `mapListItem`, `mapDetailResponse`, `mapPartiesResumo` em `ci-api-v2/src/modules/juridico/juridico.mapper.ts`
- [X] T008 Atualizar expectativas snapshot v2 em `ci-api-v2/src/modules/juridico/test/use-cases/tramitar-processo-tramitacao.integration.spec.ts` — CT-JT-006

**Checkpoint**: Snapshot v2 GREEN; módulo jurídico pronto para resolver setor origem

---

## Phase 3: User Story 2 — Visualizar processos jurídicos reais (Priority: P1)

**Goal**: Lista paginada e detalhe de processos com dados persistidos; substituir mock em `/juridico/processos`

**Independent Test**: VS Cenário 1 quickstart — GET list/detail API; UI exibe processos do tenant (não mock shell)

### Tests for User Story 2 (TDD — RED first)

- [X] T009 [P] [US2] Escrever testes (RED) `list-processos.use-case.spec.ts` em `ci-api-v2/src/modules/juridico/test/use-cases/list-processos.use-case.spec.ts` — CT-JT-002
- [X] T010 [P] [US2] Escrever testes (RED) `get-processo-detail.use-case.spec.ts` em `ci-api-v2/src/modules/juridico/test/use-cases/get-processo-detail.use-case.spec.ts` — CT-JT-003, CT-JT-004
- [X] T011 [P] [US2] Estender testes contrato list/detail shape em `ci-api-v2/src/modules/juridico/test/juridico.contract.spec.ts` — CT-JT-017

### Implementation for User Story 2 — API

- [X] T012 [P] [US2] Implementar `ListProcessosRepository` em `ci-api-v2/src/modules/juridico/repository/process.repositories.ts`
- [X] T013 [P] [US2] Implementar `FindProcessDetailRepository` em `ci-api-v2/src/modules/juridico/repository/process.repositories.ts`
- [X] T014 [US2] Implementar `list-processos.use-case.ts` em `ci-api-v2/src/modules/juridico/use-cases/list-processos.use-case.ts` (GREEN T009)
- [X] T015 [US2] Implementar `get-processo-detail.use-case.ts` em `ci-api-v2/src/modules/juridico/use-cases/get-processo-detail.use-case.ts` (GREEN T010)
- [X] T016 [US2] Expor GET `/juridico/processos` e GET `/juridico/processos/:id` em `ci-api-v2/src/modules/juridico/juridico.controller.ts`
- [X] T017 [US2] Registrar use cases e repositories em `ci-api-v2/src/modules/juridico/juridico.module.ts`

### Implementation for User Story 2 — Client

- [X] T018 [P] [US2] Adicionar `listProcessos` e `getProcessoDetail` em `ci-client-v2/apps/web/src/modules/juridico/api/processos.ts`
- [X] T019 [P] [US2] Criar mappers API→UI em `ci-client-v2/apps/web/src/modules/juridico/lib/processos-mappers.ts`
- [X] T020 [P] [US2] Criar `ProcessoTimeline.tsx` em `ci-client-v2/apps/web/src/modules/juridico/components/ProcessoTimeline.tsx`
- [X] T021 [US2] Implementar `JuridicoProcessosListPage.tsx` em `ci-client-v2/apps/web/src/modules/juridico/pages/JuridicoProcessosListPage.tsx`
- [X] T022 [US2] Implementar `JuridicoProcessoDetailPage.tsx` em `ci-client-v2/apps/web/src/modules/juridico/pages/JuridicoProcessoDetailPage.tsx` (sem tramitar ainda)
- [X] T023 [US2] Registrar overrides `juridico-lista` e `juridico-detalhes` em `ci-client-v2/apps/web/src/app/router.tsx`
- [X] T024 [P] [US2] Exportar lazy pages em `ci-client-v2/apps/web/src/modules/juridico/index.ts`
- [X] T025 [P] [US2] Implementar handlers MSW GET list/detail em `ci-client-v2/apps/web/src/test/msw/handlers/juridico.ts`
- [X] T026 [P] [US2] Escrever teste `JuridicoProcessosListPage.test.tsx` em `ci-client-v2/apps/web/src/modules/juridico/pages/__tests__/JuridicoProcessosListPage.test.tsx` — CT-JT-015

**Checkpoint**: Lista e detalhe reais end-to-end; tramitar ainda ausente na UI

---

## Phase 4: User Story 1 — Tramitar processo jurídico (Priority: P1) 🎯 MVP

**Goal**: Ação Tramitar em processo confirmado → demanda linked na Tramitação + evento timeline + toast com link

**Independent Test**: VS Cenário 2 quickstart — POST tramitar; demanda TRAM-* na inbox; evento forwarding no processo

### Tests for User Story 1 (TDD — RED first)

- [X] T027 [P] [US1] Escrever testes (RED) `juridico.controller.spec.ts` em `ci-api-v2/src/modules/juridico/test/juridico.controller.spec.ts` — CT-JT-008
- [X] T028 [US1] Estender `tramitar-processo-tramitacao.integration.spec.ts` — CT-JT-005, CT-JT-007 (evento forwarding)

### Implementation for User Story 1 — API

- [X] T029 [US1] Substituir `setorIds?.[0]` por `ResolveTramitacaoSectorUseCase` com `preferredModuloSlug: juridico` em `ci-api-v2/src/modules/juridico/juridico.controller.ts` (GREEN T027)

### Implementation for User Story 1 — Client

- [X] T030 [P] [US1] Criar `ForwardProcessoDialog.tsx` em `ci-client-v2/apps/web/src/modules/juridico/components/ForwardProcessoDialog.tsx` (espelho `ForwardManifestacaoDialog.tsx`)
- [X] T031 [US1] Integrar botão Tramitar + `ForwardProcessoDialog` em `ci-client-v2/apps/web/src/modules/juridico/pages/JuridicoProcessoDetailPage.tsx` quando `acoesPermitidas` inclui `tramitar`
- [X] T032 [P] [US1] Escrever teste `ForwardProcessoDialog.test.tsx` em `ci-client-v2/apps/web/src/modules/juridico/components/__tests__/ForwardProcessoDialog.test.tsx` — CT-JT-012
- [X] T033 [P] [US1] Escrever teste detalhe rascunho sem botão Tramitar em `ci-client-v2/apps/web/src/modules/juridico/pages/__tests__/JuridicoProcessoDetailPage.test.tsx` — CT-JT-016

**Checkpoint**: MVP completo — lista, detalhe e tramitar funcionais (US1 + US2)

---

## Phase 5: User Story 3 — Consultar linked record na Tramitação (Priority: P2)

**Goal**: Painel linked record hidrata processo jurídico; link Abrir origem; origem removida em 404

**Independent Test**: VS Cenário 3 quickstart — demanda linked exibe snapshot; hydrate complementa; Abrir origem resolve

### Tests for User Story 3 (TDD — RED first)

- [X] T034 [P] [US3] Estender testes `linked-record-snapshot.test.ts` em `ci-client-v2/apps/web/src/modules/tramitacao/lib/__tests__/linked-record-snapshot.test.ts` — CT-JT-009, CT-JT-010, CT-JT-011
- [X] T035 [P] [US3] Escrever testes LinkedRecordPanel jurídico em `ci-client-v2/apps/web/src/modules/tramitacao/components/__tests__/LinkedRecordPanel.juridico.test.tsx` — CT-JT-013, CT-JT-014

### Implementation for User Story 3

- [X] T036 [US3] Implementar `needsJuridicoHydration` e `mergeJuridicoDetail` em `ci-client-v2/apps/web/src/modules/tramitacao/lib/linked-record-snapshot.ts` (GREEN T034)
- [X] T037 [US3] Adicionar branch hidratação `sourceModule === 'juridico'` e estado origem removida em `ci-client-v2/apps/web/src/modules/tramitacao/components/LinkedRecordPanel.tsx` (GREEN T035)

**Checkpoint**: Ciclo completo Jurídico ↔ Tramitação bidirecional na UI

---

## Phase 6: User Story 4 — Dados demo seed (Priority: P3)

**Goal**: Processo confirmado com ID fixo referenciado por demanda linked pós-seed

**Independent Test**: VS Cenário 3 quickstart — `GET /juridico/processos/00000000-0000-4000-8000-000000000088` 200; Abrir origem sem 404

### Implementation for User Story 4

- [X] T038 [P] [US4] Criar `seed-juridico-demo.ts` em `ci-api-v2/prisma/seed/seed-juridico-demo.ts` com processo linked ID `00000000-0000-4000-8000-000000000088`
- [X] T039 [US4] Atualizar demanda linked jurídico com `sourceRecordId` real e snapshot v2 em `ci-api-v2/prisma/seed/seed-tramitacao-demo.ts`
- [X] T040 [US4] Registrar `seedJuridicoDemo` antes de `seedTramitacaoDemo` em `ci-api-v2/prisma/seed/seed-jacaranda-tenant.ts`

**Checkpoint**: Demo ponta a ponta validável com `npm run prisma:seed`

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Validação final e regressão

- [X] T041 Executar cenários 1–6 de `civ2-docs/specs/028-juridico-tramitacao-linked/quickstart.md` e documentar desvios
- [X] T042 [P] Rodar suíte `npm test -- --testPathPatterns=juridico` em `ci-api-v2/` e `npm test -- linked-record-snapshot ForwardProcessoDialog` em `ci-client-v2/apps/web/`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Sem dependências
- **Foundational (Phase 2)**: Depende Setup — **bloqueia US1 e US3**
- **US2 (Phase 3)**: Depende Foundational — pode iniciar em paralelo com T005–T008 após T004 RED
- **US1 (Phase 4)**: Depende US2 (detalhe UI) + Foundational (snapshot v2, resolveSector)
- **US3 (Phase 5)**: Depende Foundational (snapshot v2); independente de US1/US2 client mas beneficia seed US4
- **US4 (Phase 6)**: Depende US1+US3 para validação completa; pode implementar após Foundational
- **Polish (Phase 7)**: Depende US1–US4 desejados

### User Story Dependencies

```text
Foundational (snapshot v2 + module wiring)
        │
        ├──► US2 (lista/detalhe) ──► US1 (tramitar UI)
        │
        ├──► US3 (linked record panel)
        │
        └──► US4 (seed demo) ── valida US1+US3
```

### Parallel Opportunities

**Phase 2** (após T004 RED):

```text
T005 snapshot mapper  ||  T006 module wiring  ||  T007 juridico.mapper helpers
```

**Phase 3 US2** (após T009–T011 RED):

```text
T012 ListProcessosRepository  ||  T013 FindProcessDetailRepository
T018 api/processos.ts         ||  T019 processos-mappers.ts  ||  T020 ProcessoTimeline.tsx
T024 index.ts lazy            ||  T025 MSW handlers          ||  T026 list page test
```

**Phase 4 US1**:

```text
T027 controller spec (RED)  ||  T030 ForwardProcessoDialog.tsx
T032 dialog test            ||  T033 detail page test
```

**Phase 5 US3**:

```text
T034 linked-record-snapshot tests  ||  T035 LinkedRecordPanel tests
```

---

## Parallel Example: User Story 2

```bash
# RED tests em paralelo:
T009 list-processos.use-case.spec.ts
T010 get-processo-detail.use-case.spec.ts
T011 juridico.contract.spec.ts

# Repositories em paralelo:
T012 ListProcessosRepository
T013 FindProcessDetailRepository

# Client stubs em paralelo (após API GREEN):
T018 api/processos.ts + T019 processos-mappers.ts + T020 ProcessoTimeline.tsx
```

---

## Implementation Strategy

### MVP First (US2 + US1)

1. Phase 1: Setup
2. Phase 2: Foundational (snapshot v2 + resolveSector wiring)
3. Phase 3: US2 — lista e detalhe reais
4. Phase 4: US1 — tramitar com toast + link Tramitação
5. **STOP and VALIDATE**: quickstart Cenários 1–2
6. Phase 5–6: US3 linked record + US4 seed
7. Phase 7: Polish

### Incremental Delivery

| Incremento | Entrega | Valor |
|------------|---------|-------|
| Foundational | Snapshot v2 | Linked records futuros consistentes |
| US2 | Lista + detalhe | Substitui mock; base operacional |
| US1 | Tramitar | Fluxo principal da feature |
| US3 | Linked panel | Destinatário vê origem |
| US4 | Seed | QA/demo sem setup manual |

### Suggested MVP Scope

**US2 + US1** (Phases 1–4) — operador lista processos, abre detalhe, tramita para Tramitação.

US3 e US4 completam o ciclo destinatário e demo seeded.

---

## Notes

- TDD: RED antes de GREEN em cada fase de testes
- Sem migration Prisma nesta feature
- Wizard `juridico-novo`/`editar` permanece inalterado
- Dashboard/auditoria jurídico permanecem mock — fora de escopo
- ID demo fixo: `00000000-0000-4000-8000-000000000088` (lição spec 027 ouvidoria seed)
- Commit sugerido após cada checkpoint de fase
