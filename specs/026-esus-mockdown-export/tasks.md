# Tasks: Exportação e-SUS — Dados Mockdown para Demonstração

**Input**: Design documents from `sci-docs-v2/specs/026-esus-mockdown-export/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Tests**: TDD obrigatório (constitution + plan) — testes RED antes de implementação.

**Organization**: Por user story (US1–US5 da spec.md). **US2 (validação) precede US1 (mapper FAI)** — export depende de `validateConsultaExportReady`.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Paralelizável (arquivos distintos, sem dependência de tarefas incompletas)
- **[Story]**: US1…US5 mapeados à spec

## Path Conventions

- Client: `sci-client-monorepo/apps/web/src/modules/saude/`
- Spec: `sci-docs-v2/specs/026-esus-mockdown-export/`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Stubs e arquivos novos do plano de export — módulo `saude/` já existe (spec 024).

- [X] T001 Criar stubs exportáveis em `sci-client-monorepo/apps/web/src/modules/saude/lib/esus-export.ts` (`exportConsultaToFai`, `validateConsultaExportReady`, `exportConsultasBatch` — throw ou retorno vazio)
- [X] T002 [P] Criar stub `sci-client-monorepo/apps/web/src/modules/saude/schemas/esus-fai.schema.ts` (`esusFaiSchema`, tipos `EsusFaiPayload`)
- [X] T003 [P] Criar stub `sci-client-monorepo/apps/web/src/modules/saude/lib/esus-download.ts` (`buildExportFilename`, `triggerJsonDownload`)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Schema Zod core, mapas enum e-SUS, helper download — **BLOCKS** US1–US5.

**⚠️ CRITICAL**: Nenhuma user story inicia antes desta fase.

- [X] T004 [P] Implementar mapas enum interno→FAI (tipoAtendimento, local, turno, sexo, conduta) em `sci-client-monorepo/apps/web/src/modules/saude/lib/esus-export.ts` conforme `research.md` R11
- [X] T005 [P] Implementar `esusFaiSchema` core (sem extensões) em `sci-client-monorepo/apps/web/src/modules/saude/schemas/esus-fai.schema.ts` conforme `contracts/esus-fai-export.md`
- [X] T006 [P] Testes RED schema round-trip em `sci-client-monorepo/apps/web/src/modules/saude/schemas/__tests__/esus-fai.schema.test.ts`
- [X] T007 Implementar `buildExportFilename` e `triggerJsonDownload` em `sci-client-monorepo/apps/web/src/modules/saude/lib/esus-download.ts`
- [X] T008 [P] Testes RED filename/download em `sci-client-monorepo/apps/web/src/modules/saude/lib/__tests__/esus-download.test.ts`
- [X] T009 Implementar helper `resolveConsultaExportRefs(consultaId)` em `sci-client-monorepo/apps/web/src/modules/saude/lib/esus-export.ts` (lookup cidadão/profissional/unidade/equipe via stores/api existentes)

**Checkpoint**: Foundation ready — user stories podem começar.

---

## Phase 3: User Story 2 — Validar prontidão antes da exportação (Priority: P1)

**Goal**: `validateConsultaExportReady` com lista `missing` PT-BR, gate `pronto_envio`, reutilização de `conferencia-rules`.

**Independent Test**: Consultas seed com CNES/CNS/avaliação ausentes → `{ ok: false, missing: [...] }`; consulta completa `pronto_envio` → `{ ok: true }`.

### Tests for User Story 2 ⚠️

- [X] T010 [P] [US2] Testes RED validate em `sci-client-monorepo/apps/web/src/modules/saude/lib/__tests__/esus-export.test.ts` (CNES ausente, cidadão sem id, avaliação vazia, status ≠ pronto_envio)

### Implementation for User Story 2

- [X] T011 [US2] Implementar `validateConsultaExportReady` em `sci-client-monorepo/apps/web/src/modules/saude/lib/esus-export.ts` integrando `detectInconsistencias` de `lib/conferencia-rules.ts`
- [X] T012 [US2] Mapear flags conferência → labels PT-BR operacionais (`getInconsistenciaLabel`) na lista `missing` em `lib/esus-export.ts`
- [X] T013 [US2] Adicionar impeditivo de status conferência ("Pronto para envio") quando `statusConferencia !== 'pronto_envio'` em `lib/esus-export.ts`
- [X] T014 [US2] Adicionar checks export-specific (data atendimento, data nascimento, CBO) e tipo `ExportValidationResult` com `warnings?` em `lib/esus-export.ts` conforme `data-model.md`

**Checkpoint**: Validação export testável isoladamente (sem UI).

---

## Phase 4: User Story 1 — Exportar consulta conferida no padrão FAI (Priority: P1) 🎯 MVP core

**Goal**: `exportConsultaToFai` gera JSON FAI legível mapeando 6 dimensões da consulta.

**Independent Test**: Consulta seed `pronto_envio` → payload com `headerTransport`, `identificacaoUsuarioCidadao`, `atendimentosIndividuais`; snapshot estável; `esusFaiSchema.parse` OK.

### Tests for User Story 1 ⚠️

- [X] T015 [P] [US1] Teste RED snapshot FAI em `sci-client-monorepo/apps/web/src/modules/saude/lib/__tests__/esus-export.test.ts` (consulta seed completa de `data/seed.ts`)

### Implementation for User Story 1

- [X] T016 [US1] Implementar `exportConsultaToFai(consulta, refs)` — top-level (`tipoFicha`, `uuidFicha`, `tpCdsOrigem`) em `sci-client-monorepo/apps/web/src/modules/saude/lib/esus-export.ts`
- [X] T017 [US1] Mapear `headerTransport` e `identificacaoUsuarioCidadao` em `lib/esus-export.ts` conforme `contracts/esus-fai-export.md`
- [X] T018 [US1] Mapear `atendimentosIndividuais[]` (tipo, local, problemasCondicoes, procedimentos SIGTAP, condutas, SOAP texto demo) em `lib/esus-export.ts`
- [X] T019 [US1] Garantir `exportConsultaToFai` só executa após `validateConsultaExportReady` OK — throw ou retorno tipado com erro em `lib/esus-export.ts`

**Checkpoint**: Mapper FAI + validação — núcleo técnico da feature (ainda sem UI).

---

## Phase 5: User Story 3 — Visualizar e baixar artefato (Priority: P2)

**Goal**: Substituir toast placeholder por Sheet preview + download JSON nomeado.

**Independent Test**: Detalhe consulta `pronto_envio` → Exportar → Sheet com JSON; Baixar → arquivo `fai-*.json`; consulta inválida → toast com `missing`.

### Tests for User Story 3 ⚠️

- [X] T020 [P] [US3] Testes RED `EsusExportButton` em `sci-client-monorepo/apps/web/src/modules/saude/components/__tests__/EsusExportButton.test.tsx` (ok/fail/status gate)
- [X] T021 [P] [US3] Testes RED `EsusExportSheet` em `sci-client-monorepo/apps/web/src/modules/saude/components/__tests__/EsusExportSheet.test.tsx` (tabs, download mock)

### Implementation for User Story 3

- [X] T022 [US3] Implementar `sci-client-monorepo/apps/web/src/modules/saude/components/EsusExportSheet.tsx` (tabs FAI + JSON completo, Copiar, Baixar) conforme `contracts/client-export-ui.md`
- [X] T023 [US3] Implementar `sci-client-monorepo/apps/web/src/modules/saude/components/EsusExportButton.tsx` (validate → toast missing / open sheet)
- [X] T024 [US3] Substituir toast placeholder por `EsusExportButton` em `sci-client-monorepo/apps/web/src/modules/saude/pages/ConsultaDetailPage.tsx`
- [X] T025 [US3] Adicionar `data-testid` (`esus-export-button`, `esus-export-sheet`, `esus-export-download`) nos componentes export

**Checkpoint**: **MVP demo** — export FAI utilizável pelo usuário (US2 + US1 + US3).

---

## Phase 6: User Story 4 — Extensões demo receitas/exames/solicitações (Priority: P2)

**Goal**: Bloco `_demoExtensions` separado visualmente; warning solicitante exame não médico.

**Independent Test**: Consulta com receita → extensão `medicamentosPrescritos`; exame enfermeiro → warning; FAI core inalterado vs snapshot US1.

### Tests for User Story 4 ⚠️

- [X] T026 [P] [US4] Estender testes RED extensões em `sci-client-monorepo/apps/web/src/modules/saude/lib/__tests__/esus-export.test.ts` (receita, exame médico, solicitante inconsistente)

### Implementation for User Story 4

- [X] T027 [US4] Estender `esusFaiSchema` com `_demoExtensions` opcional em `sci-client-monorepo/apps/web/src/modules/saude/schemas/esus-fai.schema.ts` conforme `contracts/esus-export-extensions.md`
- [X] T028 [US4] Implementar `buildDemoExtensions` (medicamentos de `itensReceita`) em `sci-client-monorepo/apps/web/src/modules/saude/lib/esus-export.ts`
- [X] T029 [US4] Enriquecer extensões com `examesSolicitados` (lookup `api/exames-relatorio.ts` por `consultaId`) em `lib/esus-export.ts`
- [X] T030 [US4] Implementar warning CBO solicitante exame (`225*`) em `validateConsultaExportReady` e flag `solicitanteInconsistente` na extensão em `lib/esus-export.ts`
- [X] T031 [US4] Adicionar aba **Extensões** + banner demo Mint em `sci-client-monorepo/apps/web/src/modules/saude/components/EsusExportSheet.tsx`

**Checkpoint**: Narrativa demo completa (receitas + exames) sem confundir campos MS.

---

## Phase 7: User Story 5 — Pacote cadastros e exportação em lote (Priority: P3)

**Goal**: Export cadastros demo + lote consultas prontas na conferência.

**Independent Test**: Cadastros → JSON `_demo` com 8 UBS; conferência lote → `{ exported, skipped }`; CNS/CNES consistentes com FAI (SC-005).

### Tests for User Story 5 ⚠️

- [X] T032 [P] [US5] Testes RED `exportCadastrosDemoPackage` em `sci-client-monorepo/apps/web/src/modules/saude/lib/__tests__/esus-cadastros-export.test.ts`
- [X] T033 [P] [US5] Testes RED `exportConsultasBatch` em `sci-client-monorepo/apps/web/src/modules/saude/lib/__tests__/esus-export.test.ts` (skipped com motivo)

### Implementation for User Story 5

- [X] T034 [US5] Implementar `exportCadastrosDemoPackage` em `sci-client-monorepo/apps/web/src/modules/saude/lib/esus-cadastros-export.ts` conforme `contracts/esus-cadastros-package.md`
- [X] T035 [US5] Implementar `exportConsultasBatch(ids)` em `sci-client-monorepo/apps/web/src/modules/saude/lib/esus-export.ts`
- [X] T036 [US5] Adicionar botão **Exportar cadastros demo** em `sci-client-monorepo/apps/web/src/modules/saude/pages/SaudeCadastrosDashboardPage.tsx`
- [X] T037 [US5] Adicionar export rápido por linha + **Exportar lote (prontas)** em `sci-client-monorepo/apps/web/src/modules/saude/pages/SaudeConferenciaPage.tsx`

**Checkpoint**: Workshop implantação + operação em massa na conferência.

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Integração, consistência cruzada, validação quickstart.

- [X] T038 [P] Teste integração fluxo export em `sci-client-monorepo/apps/web/src/modules/saude/__tests__/ConsultaDetailPage.export.test.tsx`
- [X] T039 [P] Teste consistência CNS/CNES cadastros vs FAI em `sci-client-monorepo/apps/web/src/modules/saude/lib/__tests__/esus-cadastros-export.test.ts`
- [X] T040 Executar cenários P1–P3 de `sci-docs-v2/specs/026-esus-mockdown-export/quickstart.md` e corrigir gaps
- [X] T041 [P] Re-exportar componentes export em `sci-client-monorepo/apps/web/src/modules/saude/index.tsx` se necessário para lazy routes

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)** → **Foundational (Phase 2)** → **US2 (Phase 3)** → **US1 (Phase 4)** → **US3 (Phase 5)** → **US4 (Phase 6)** → **US5 (Phase 7)** → **Polish (Phase 8)**
- **US3** depende de US1 + US2 (mapper + validate)
- **US4** depende de US1 (estende export)
- **US5** depende de US1 (batch reusa mapper); cadastros export independente de US4

### User Story Dependencies

| Story | Depende de | Independente após |
|-------|------------|-------------------|
| US2 | Phase 2 | Validate unit tests green |
| US1 | US2 | Snapshot FAI green |
| US3 | US1, US2 | Export na UI funcional |
| US4 | US1, US3 | Extensões na Sheet |
| US5 | US1 | Lote + pacote cadastros |

### Parallel Opportunities

- Phase 1: T002 ∥ T003
- Phase 2: T004 ∥ T005 ∥ T006 ∥ T008
- US2: T010 (RED) antes T011–T014 sequencial
- US1: T015 (RED) ∥ T016 prep; T017 ∥ T018 após T016
- US3: T020 ∥ T021; T022 ∥ T023 após tests RED
- US4: T026 ∥ T027; T028 ∥ T029
- US5: T032 ∥ T033; T034 ∥ T035; T036 ∥ T037
- Polish: T038 ∥ T039 ∥ T041

---

## Parallel Example: User Story 3

```bash
# Tests RED em paralelo:
cd sci-client-monorepo/apps/web
npm test -- EsusExportButton
npm test -- EsusExportSheet

# Componentes em paralelo (após RED):
# EsusExportSheet.tsx + EsusExportButton.tsx
```

---

## Implementation Strategy

### MVP First (US2 + US1 + US3)

1. Phase 1 Setup
2. Phase 2 Foundational
3. Phase 3 US2 (validação)
4. Phase 4 US1 (mapper FAI)
5. Phase 5 US3 (UI preview/download)
6. **STOP** — demo export FAI na consulta Careiro (`/speckit-implement` checkpoint)

### Incremental Delivery

1. US2 + US1 + US3 → MVP export demonstrável
2. + US4 → extensões receita/exame na narrativa demo
3. + US5 → pacote cadastros + lote conferência
4. Polish → quickstart + testes integração

### Suggested MVP Scope

**T001–T025** (Setup + Foundational + US2 + US1 + US3) — export FAI com validação e download no detalhe da consulta.

---

## Notes

- Substituir placeholder US7 adiado na spec 024 (`ConsultaDetailPage` toast)
- Dados 100% sintéticos — referência LEDI 7.4.2 subset only
- TDD: confirmar testes RED antes de GREEN em cada fase
- **Total: 41 tasks** | Setup+Foundation: 9 | US2: 5 | US1: 5 | US3: 6 | US4: 6 | US5: 6 | Polish: 4
