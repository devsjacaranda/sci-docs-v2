---
description: "Task list for Corrigir tramitação de manifestações na Ouvidoria (027-fix-ouvidoria-tramitar)"
---

# Tasks: Corrigir tramitação de manifestações na Ouvidoria

**Input**: Design documents from `civ2-docs/specs/027-fix-ouvidoria-tramitar/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Tests**: **Obrigatórios** — TDD (constitution II + FR-010 + `contracts/test-strategy.md`): Jest unit + integration em `ci-api-v2`; smoke manual client.

**Organization**: US1 e US2 são P1; US3 é P2. Caminhos relativos à raiz `ci-v2/`. **Sem migration Prisma.** Escopo API-only (client smoke manual).

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Pode executar em paralelo (arquivos diferentes, sem dependências pendentes)
- **[Story]**: User story da spec (US1–US3)

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Confirmar ambiente e artefatos de design antes do TDD

- [X] T001 Verificar docs da feature em `civ2-docs/specs/027-fix-ouvidoria-tramitar/` (plan, spec, contracts, quickstart) e seed Jacaranda (`admin@jacaranda.com`, setor OUV, manifestação `11111111-1111-1111-1111-000000000018`) via `cd ci-api-v2; npx prisma db seed`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Estender resolução de setor de origem compartilhada — **bloqueia US1, US2 e US3**

**⚠️ CRITICAL**: Nenhuma user story começa antes desta fase

### Tests first (TDD — RED)

- [X] T002 [P] Escrever testes (RED) `resolve-tramitacao-sector.use-case.spec.ts` em `ci-api-v2/src/modules/tramitacao/use-cases/resolve-tramitacao-sector.use-case.spec.ts` — CT-OT-001 (JWT setorIds), CT-OT-002 (DB userSetor), CT-OT-003 (chiefOfSetorIds), CT-OT-004 (admin fallback ModuloSetor ouvidoria), CT-OT-005 (ACTIVE_SECTOR_UNDEFINED), CT-OT-006 (multi-setor prefer ouvidoria)

### Implementation

- [X] T003 Estender `resolve-tramitacao-sector.use-case.ts` em `ci-api-v2/src/modules/tramitacao/use-cases/resolve-tramitacao-sector.use-case.ts` — parâmetro opcional `preferredModuloSlug`; priorizar setor do usuário vinculado ao módulo; fallback `ModuloSlug.ouvidoria` quando informado (GREEN T002)
- [X] T004 Exportar `ResolveTramitacaoSectorUseCase` em `ci-api-v2/src/modules/tramitacao/tramitacao.module.ts` — adicionar ao array `exports` junto a `CreateLinkedDemandaUseCase`

**Checkpoint**: Testes T002 passando; resolver exportado; Tramitação inalterada (default `tramitacao`)

---

## Phase 3: User Story 1 — Tramitar manifestação com sucesso (Priority: P1) 🎯 MVP

**Goal**: Servidor com setor vinculado tramita manifestação; setor origem resolvido automaticamente; demanda vinculada criada

**Independent Test**: Login servidor com `setorIds`; POST `/ouvidoria/manifestacoes/:id/encaminhar` → 200; timeline + demanda Tramitação; sem erro "Setor ativo não definido"

### Tests for User Story 1 (TDD — RED first)

- [X] T005 [US1] Escrever testes (RED) `ouvidoria.controller.spec.ts` em `ci-api-v2/src/modules/ouvidoria/ouvidoria.controller.spec.ts` — POST encaminhar usuário com `setorIds` → 200 + `EncaminharManifestacaoUseCase` chamado com `authorSectorId` resolvido (CT-OT-009)

### Implementation for User Story 1

- [X] T006 [US1] Refatorar rota `encaminharRoute` em `ci-api-v2/src/modules/ouvidoria/ouvidoria.controller.ts` — injetar `ResolveTramitacaoSectorUseCase`; remover check manual `setorIds?.[0]`; chamar `await resolveSector.execute(req.user, undefined, ModuloSlug.ouvidoria)` (GREEN T005)
- [X] T007 [US1] Verificar regressão CT-OT-007 em `ci-api-v2/src/modules/ouvidoria/test/use-cases/encaminhar-manifestacao-tramitacao.integration.spec.ts` — linked demanda com `senderSectorId` correto permanece verde

**Checkpoint**: US1 — servidor com setor tramita end-to-end via API

---

## Phase 4: User Story 2 — Tramitar como administrador institucional (Priority: P1)

**Goal**: Admin tenant sem `setorIds` no JWT tramita usando fallback setor Ouvidoria do tenant

**Independent Test**: Login `admin@jacaranda.com`; tramitar manifestação demo → 200; `senderSectorId` = setor OUV

### Tests for User Story 2 (TDD — RED first)

- [X] T008 [P] [US2] Estender testes (RED) `ouvidoria.controller.spec.ts` em `ci-api-v2/src/modules/ouvidoria/ouvidoria.controller.spec.ts` — POST encaminhar `admin_tenant` com `setorIds: []` → 200; `authorSectorId` = setor módulo ouvidoria (CT-OT-008)
- [X] T009 [P] [US2] Estender testes (RED) `ouvidoria.controller.spec.ts` — POST encaminhar manifestação `draft` → 409 `INVALID_STATUS_TRANSITION` (CT-OT-010)

### Implementation for User Story 2

- [X] T010 [US2] Confirmar wiring `ModuloSlug.ouvidoria` na rota encaminhar em `ci-api-v2/src/modules/ouvidoria/ouvidoria.controller.ts` cobre admin_tenant e chefe de setor (GREEN T008, T009)

**Checkpoint**: US1 + US2 — admin institucional e servidor tramitam sem erro de setor ativo

---

## Phase 5: User Story 3 — Feedback claro quando tramitação não é possível (Priority: P2)

**Goal**: Mensagem acionável quando nenhum setor de origem puder ser resolvido; modal preserva formulário

**Independent Test**: Tenant sem setores → 400 com copy orientativa (não ambígua com setor destino); modal mantém campos após erro

### Tests for User Story 3 (TDD — RED first)

- [X] T011 [US3] Estender teste CT-OT-005 em `ci-api-v2/src/modules/tramitacao/use-cases/resolve-tramitacao-sector.use-case.spec.ts` — assert mensagem PT-BR acionável conforme `contracts/rest-api-ouvidoria-encaminhar-fix.md`

### Implementation for User Story 3

- [X] T012 [US3] Atualizar copy de erro `ACTIVE_SECTOR_UNDEFINED` em `ci-api-v2/src/modules/tramitacao/use-cases/resolve-tramitacao-sector.use-case.ts` — *"Não foi possível identificar o setor de origem. Cadastre setores no tenant ou vincule seu usuário a um setor autorizado na Ouvidoria."* (GREEN T011)
- [X] T013 [US3] Smoke manual: validar `ci-client-v2/apps/web/src/modules/ouvidoria/components/ForwardManifestacaoDialog.tsx` exibe erro legível e preserva setor destino + observação após 400 (FR-009; sem diff obrigatório se já OK)

**Checkpoint**: US3 — erro acionável em cenário impossível; UX modal confirmada

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Validação final e regressão spec 003

- [X] T014 [P] Executar suite de testes em `ci-api-v2`: `npm test -- resolve-tramitacao-sector` + `npm test -- encaminhar-manifestacao` + `npm test -- ouvidoria.controller`
- [X] T015 Executar quickstart `civ2-docs/specs/027-fix-ouvidoria-tramitar/quickstart.md` — VS-027-001 (admin Jacaranda), VS-027-002 (servidor), VS-027-003 (regressão status inválido)

---

## Phase 7: Correções colaterais e UX Tramitação (pós-spec)

**Purpose**: Bugs e melhorias descobertos durante validação manual — fora do escopo original do bug de setor, entregues na mesma branch.

- [X] T016 Corrigir erro 500 `ManifestacaoEvento_autorUserId_fkey` em `encaminhar-manifestacao.use-case.ts` — padrão `resolveUserTableId` para `admin_tenant` (autorUserId/createdByUserId opcionais)
- [X] T017 Redirecionar pós-tramitar para `/tramitacao/demandas/:id` em `ForwardManifestacaoDialog.tsx` e `ManifestacaoActionDialogs.tsx`
- [X] T018 Expandir snapshot v2 em `manifestacao-tramitacao-snapshot.mapper.ts` — typeLabel, statusLabel, description, requesterSummary, addressSummary, capturedAt; usar `FindManifestacaoByIdRepository` com endereço
- [X] T019 Implementar `LinkedRecordPanel` na aba Vínculos (`TramitacaoInboxWorkspace.tsx`) — parser `linked-record-snapshot.ts`, hidratação ouvidoria para snapshots legados, grid de metadados + relato
- [X] T020 Export PDF client-side em `linked-record-pdf.ts` — HTML + `window.print()` sem endpoint API

**Checkpoint**: Tramitar → demanda TRAM → aba Vínculos exibe contrato completo + botão Baixar PDF

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Sem dependências — iniciar imediatamente
- **Foundational (Phase 2)**: Depende de T001 — **BLOQUEIA** US1, US2, US3
- **US1 (Phase 3)**: Depende de Phase 2 — MVP
- **US2 (Phase 4)**: Depende de Phase 3 (controller spec + wiring existentes)
- **US3 (Phase 5)**: Depende de Phase 2 (resolver); copy independente do controller
- **Polish (Phase 6)**: Depende de US1 + US2 (+ US3 se escopo completo)

### User Story Dependencies

| Story | Depende de | Independente quando |
|-------|------------|---------------------|
| US1 (P1) | Phase 2 | POST encaminhar 200 para user com setorIds |
| US2 (P1) | US1 wiring | POST encaminhar 200 para admin_tenant |
| US3 (P2) | Phase 2 | 400 com copy acionável; smoke modal |

### Within Each User Story

- Testes RED antes de implementação GREEN
- Resolver (Phase 2) antes de controller (Phase 3)
- Controller wiring antes de testes admin (Phase 4)

### Parallel Opportunities

```text
# Phase 2 — após T001:
T002 (spec resolver) → T003 + T004 sequencial

# Phase 4 — após T006:
T008 ∥ T009 (mesmo arquivo spec, casos independentes)

# Phase 6:
T014 ∥ preparação ambiente quickstart
```

---

## Parallel Example: User Story 2

```bash
# Após T006 (controller wired), adicionar casos de teste em paralelo:
Task T008: "admin_tenant encaminhar → 200 em ouvidoria.controller.spec.ts"
Task T009: "manifestação draft → 409 em ouvidoria.controller.spec.ts"
```

---

## Implementation Strategy

### MVP First (User Story 1 only)

1. T001 Setup
2. T002–T004 Foundational (resolver)
3. T005–T007 US1 (controller + regressão)
4. **STOP**: validar CT-OT-009 + quickstart VS-027-002

### Entrega completa (US1 + US2)

5. T008–T010 US2 (admin tenant — reproduz bug reportado)
6. T014–T015 quickstart VS-027-001

### Escopo total (+ US3)

7. T011–T013 copy erro + smoke modal
8. T015 VS-027-004 (edge tenant sem setores)

---

## Notes

- **Não alterar** `ci-api-v2/src/modules/juridico/juridico.controller.ts` nesta feature (mesmo anti-pattern, issue separada)
- **Sem migration** — entidades existentes da spec 003
- **Sem testes Vitest** obrigatórios no client (research R3)
- Commit sugerido após cada checkpoint de fase
- Task IDs sequenciais T001–T020; formato checklist validado
- **T016–T020**: escopo ampliado pós-validação (FK admin, redirect TRAM, LinkedRecordPanel spec 014)
