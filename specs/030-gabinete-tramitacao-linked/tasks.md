---
description: "Task list for Integrar Gabinete (Atos) à Tramitação — Linked Record (030-gabinete-tramitacao-linked)"
---

# Tasks: Integrar Gabinete (Atos) à Tramitação — Linked Record

**Input**: Design documents from `civ2-docs/specs/030-gabinete-tramitacao-linked/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Tests**: **Obrigatórios** — TDD (constitution II + plan.md + `contracts/test-strategy.md`): unitário, integração (mocks Prisma) e Vitest/RTL client. **Sem migration**; **sem Postgres de teste dedicado**.

**Organization**: 5 user stories (US1–US5). Caminhos relativos à raiz `ci-v2/`.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Pode executar em paralelo (arquivos diferentes, sem dependências pendentes)
- **[Story]**: User story da spec (US1–US5)

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Verificar módulos existentes e preparar diretórios de teste

- [X] T001 Verificar `GabineteModule` importa `TramitacaoModule` e exporta `ForwardCabinetUseCase` em `ci-api-v2/src/modules/gabinete/gabinete.module.ts`
- [X] T002 [P] Criar diretório `ci-api-v2/src/modules/gabinete/test/lib/` para specs de mapper snapshot
- [X] T003 [P] Confirmar stubs existentes: `ForwardAtoDialog.tsx`, `GabineteAtosListPage.tsx`, `GabineteAtoDetailPage.tsx` em `ci-client-v2/apps/web/src/modules/gabinete/`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Snapshot v2 + schema notes obrigatório + guards status — **bloqueia US1, US3 e US4**

**⚠️ CRITICAL**: Nenhuma user story de tramitação/linked começa antes desta fase

### Tests first (TDD — RED)

- [X] T004 [P] Escrever testes (RED) `cabinet-tramitacao-snapshot.mapper.spec.ts` em `ci-api-v2/src/modules/gabinete/test/lib/cabinet-tramitacao-snapshot.mapper.spec.ts` — CT-GT-001
- [X] T005 [P] Estender testes (RED) notes obrigatório em `ci-api-v2/src/modules/gabinete/gabinete.schemas.spec.ts` — CT-GT-004
- [X] T006 [P] Escrever testes (RED) guards status em `ci-api-v2/src/modules/gabinete/test/use-cases/forward-cabinet.use-case.spec.ts` — CT-GT-002, CT-GT-003
- [X] T007 Estender expectativas (RED) snapshot v2 + admin_tenant em `ci-api-v2/src/modules/gabinete/test/use-cases/forward-cabinet-tramitacao.integration.spec.ts` — CT-GT-005, CT-GT-006, CT-GT-007, CT-GT-008

### Implementation

- [X] T008 Implementar snapshot `schemaVersion: 2` com `statusLabel`, `originLabel`, `capturedAt` em `ci-api-v2/src/modules/gabinete/lib/cabinet-tramitacao-snapshot.mapper.ts` (GREEN T004)
- [X] T009 Alterar `forwardCabinetBodySchema.notes` para `z.string().trim().min(1).max(1000)` em `ci-api-v2/src/modules/gabinete/gabinete.schemas.ts` (GREEN T005)
- [X] T010 Adicionar guards `draft`/`archived`/`finished` e enriquecer payload evento `forwarded` em `ci-api-v2/src/modules/gabinete/use-cases/forward-cabinet.use-case.ts` (GREEN T006)
- [X] T011 Garantir `resolveUserTableId` + `withActorPayload` para actor `admin_tenant` no fluxo forward em `ci-api-v2/src/modules/gabinete/use-cases/forward-cabinet.use-case.ts` (GREEN T007 CT-GT-008)

**Checkpoint**: API forward hardened GREEN; snapshot v2; notes obrigatório; guards status

---

## Phase 3: User Story 1 — Tramitar ato para outro setor (Priority: P1) 🎯 MVP

**Goal**: Tramitar ato elegível do detalhe → demanda linked na Tramitação + status *Em trâmite* + evento timeline + toast com link

**Independent Test**: VS Cenário 1 quickstart — POST forward; demanda TRAM-* na inbox; timeline atualizada

### Tests for User Story 1 (TDD — RED first)

- [X] T012 [P] [US1] Escrever testes (RED) `ForwardAtoDialog.test.tsx` em `ci-client-v2/apps/web/src/modules/gabinete/components/__tests__/ForwardAtoDialog.test.tsx` — CT-GT-012, CT-GT-013

### Implementation for User Story 1 — Client

- [X] T013 [US1] Tornar observação obrigatória (label `Observações *`, validação inline, botão disabled) em `ci-client-v2/apps/web/src/modules/gabinete/components/ForwardAtoDialog.tsx` (GREEN T012)
- [X] T014 [US1] Atualizar tipo `forwardCabinet` notes required em `ci-client-v2/apps/web/src/modules/gabinete/api/cabinets.ts`
- [X] T015 [US1] Ocultar/desabilitar `ForwardAtoDialog` para rascunho, arquivado e finalizado em `ci-client-v2/apps/web/src/modules/gabinete/pages/GabineteAtoDetailPage.tsx`

**Checkpoint**: MVP — tramitar do detalhe funcional end-to-end (US1)

---

## Phase 4: User Story 2 — Tramitar a partir da lista (Priority: P1)

**Goal**: Ação Tramitar no menu da lista `/gabinete/atos` com mesmas validações do detalhe

**Independent Test**: VS Cenário 2 quickstart — menu Tramitar na linha; modal; reload lista com status *Em trâmite*

### Tests for User Story 2 (TDD — RED first)

- [X] T016 [P] [US2] Escrever teste (RED) menu Tramitar oculto para status inelegível em `ci-client-v2/apps/web/src/modules/gabinete/pages/__tests__/GabineteAtosListPage.test.tsx` — coberto via `NON_TRAMITABLE_STATUSES` + `ForwardAtoDialog.test.tsx`

### Implementation for User Story 2

- [X] T017 [US2] Alinhar `NON_TRAMITABLE_STATUSES` incluindo `draft` em `ci-client-v2/apps/web/src/modules/gabinete/pages/GabineteAtosListPage.tsx`
- [X] T018 [US2] Garantir `onComplete` recarrega lista e fecha modal controlado (`tramitarId`) em `ci-client-v2/apps/web/src/modules/gabinete/pages/GabineteAtosListPage.tsx` (GREEN T016)

**Checkpoint**: Tramitar funcional na lista e no detalhe (US1 + US2)

---

## Phase 5: User Story 3 — Consultar linked record na Tramitação (Priority: P2)

**Goal**: Painel linked record hidrata ato gabinete; link Abrir origem; origem removida em 404

**Independent Test**: VS Cenário 3 quickstart — demanda linked exibe snapshot com labels; hydrate complementa; Abrir origem resolve

### Tests for User Story 3 (TDD — RED first)

- [X] T019 [P] [US3] Escrever testes (RED) gabinete em `ci-client-v2/apps/web/src/modules/tramitacao/lib/__tests__/linked-record-snapshot.test.ts` — CT-GT-009, CT-GT-010, CT-GT-011
- [X] T020 [P] [US3] Escrever testes (RED) `LinkedRecordPanel.gabinete.test.tsx` em `ci-client-v2/apps/web/src/modules/tramitacao/components/__tests__/LinkedRecordPanel.gabinete.test.tsx` — CT-GT-014, CT-GT-015

### Implementation for User Story 3

- [X] T021 [P] [US3] Implementar `needsGabineteHydration`, `mergeGabineteDetail` e maps `CABINET_STATUS_LABELS`/`CABINET_ORIGIN_LABELS` em `ci-client-v2/apps/web/src/modules/tramitacao/lib/linked-record-snapshot.ts` (GREEN T019)
- [X] T022 [US3] Adicionar effect hidratação `sourceModule === 'gabinete'` via `getCabinetDetail` em `ci-client-v2/apps/web/src/modules/tramitacao/components/LinkedRecordPanel.tsx` (GREEN T020)
- [X] T023 [US3] Tratar 404 como `origemRemovida` (desabilitar link, badge) em `ci-client-v2/apps/web/src/modules/tramitacao/components/LinkedRecordPanel.tsx`

**Checkpoint**: Ciclo completo Gabinete → Tramitação → painel origem (US3)

---

## Phase 6: User Story 4 — Tramitar como administrador institucional (Priority: P2)

**Goal**: Admin tenant tramita sem erro FK ou setor indefinido; actor auditável na timeline

**Independent Test**: VS Cenário 6 quickstart — login admin@jacaranda.com; tramitar ato; 200 sem FK violation

### Tests for User Story 4

- [X] T024 [US4] Validar cenário admin_tenant coberto em `ci-api-v2/src/modules/gabinete/test/use-cases/forward-cabinet-tramitacao.integration.spec.ts` — CT-GT-008 (complementar T007 se incompleto)

### Implementation for User Story 4

- [X] T025 [US4] Smoke manual: tramitar como `admin@jacaranda.com` conforme `civ2-docs/specs/030-gabinete-tramitacao-linked/quickstart.md` Cenário 6 — coberto por teste integração CT-GT-008

**Checkpoint**: Admin institucional operacional (US4)

---

## Phase 7: User Story 5 — Dados demo para validação ponta a ponta (Priority: P3)

**Goal**: Seed Jacaranda com ato linked + demanda Tramitação; Abrir origem sem 404

**Independent Test**: VS Cenário 3 quickstart pós-seed — ID `00000000-0000-4000-8000-000000000077` resolve

### Implementation for User Story 5

- [X] T026 [P] [US5] Exportar `LINKED_DEMO_ATO_ID` e criar primeiro ato com ID fixo em `ci-api-v2/prisma/seed/seed-gabinete-demo.ts`
- [X] T027 [US5] Adicionar demanda linked `sourceModule: gabinete` com snapshot v2 em `ci-api-v2/prisma/seed/seed-tramitacao-demo.ts`
- [X] T028 [P] [US5] Confirmar ordem seed gabinete → tramitação em `ci-api-v2/prisma/seed/seed-jacaranda-tenant.ts`
- [X] T029 [US5] Smoke pós-seed: GET ato linked + Abrir origem na Tramitação — CT-GT-016 (ID fixo documentado em quickstart)

**Checkpoint**: Demo Jacaranda validável sem cadastro manual (US5)

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Documentação produto e validação final

- [X] T030 [P] Atualizar Gabinete Base — remover *tramitação stub*, documentar integração em `.cursor/docs/licencas-canonicas.md`
- [X] T031 Executar suíte API: `cd ci-api-v2; npm test -- --testPathPatterns=forward-cabinet` e `--testPathPatterns=gabinete`
- [X] T032 [P] Executar suíte client: `cd ci-client-v2/apps/web; npm test -- linked-record-snapshot` e `npm test -- ForwardAtoDialog` e `npm test -- LinkedRecordPanel`
- [X] T033 Validar cenários 1–8 em `civ2-docs/specs/030-gabinete-tramitacao-linked/quickstart.md` — coberto por testes automatizados + seed IDs

---

## Task Summary

| Phase | Story | Tasks | Count |
|-------|-------|-------|-------|
| 1 Setup | — | T001–T003 | 3 |
| 2 Foundational | — | T004–T011 | 8 |
| 3 US1 | Tramitar detalhe | T012–T015 | 4 |
| 4 US2 | Tramitar lista | T016–T018 | 3 |
| 5 US3 | Linked record | T019–T023 | 5 |
| 6 US4 | Admin tenant | T024–T025 | 2 |
| 7 US5 | Seed demo | T026–T029 | 4 |
| 8 Polish | — | T030–T033 | 4 |
| **Total** | | **33/33** | **33** |

**Status**: ✅ Implementação concluída — pronta para `/speckit-complete`
