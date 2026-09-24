# Tasks: Relatório de Gestão — Tipo de concessão (AGEMAN gap 3)

**Input**: `civ2-docs/specs/050-relatorio-gestao-tipo-concessao-ageman/` — `spec.md`, `plan.md`, `research.md`, `contracts/relatorio-gestao-tipo-concessao.md`

**Tests**: incluídos — Constitution II (TDD).

**Organização**: uma user story (US1 = API + exports + UI); fases ordenadas por dependência.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: paralelizável (arquivos distintos, deps satisfeitas)
- **[US1]**: User Story 1–3 da spec (entrega única indivisível para AGEMAN)

## Path Conventions

- Backend: `ci-api-v2/src/modules/ouvidoria/`
- Frontend: `ci-client-v2/apps/web/src/modules/ouvidoria/`

---

## Phase 1: Setup

- [ ] T001 Confirmar branch `050-relatorio-gestao-tipo-concessao-ageman` e baseline verde: `npm test -- --testPathPatterns=get-relatorio-gestao` em `ci-api-v2/` e `npm test -- relatorio-gestao` em `ci-client-v2/apps/web/`

---

## Phase 2: Foundational — fragmento SQL (blocking)

**Purpose**: DRY do mapa programa → concessão (FR-006) antes de alterar queries.

- [ ] T002 [P] [US1] Criar `ci-api-v2/src/modules/ouvidoria/lib/relatorio-gestao-programa-concessao.sql.ts` exportando helper Prisma.sql para expressão `COALESCE(CASE TRIM(programa)…, NULLIF(TRIM(serviceMode), ''))` conforme `research.md`
- [ ] T003 [US1] Refatorar `ci-api-v2/src/modules/ouvidoria/repository/dashboard.repositories.ts` — usar helper em `porMotivo` (comportamento idêntico; testes existentes devem permanecer verdes) — depende de T002

**Checkpoint**: `dashboard-agregacoes` / `get-relatorio-gestao` specs ainda verdes após T003.

---

## Phase 3: User Story 1 — Bloco por tipo de concessão (API) 🎯

**Goal**: `porTipoManifestacao` agrega mês × concessão; paridade com rollup `porMotivo`.

**Independent Test**: Período com mix de `programa`; resposta sem `complaint`; soma por concessão = soma `porMotivo`.

### Tests (RED primeiro)

- [ ] T004 [P] [US1] Atualizar RED em `ci-api-v2/src/modules/ouvidoria/test/repository/get-relatorio-gestao-tipo-manifestacao.repository.spec.ts` — expectativas com `programa` `'agua'`, `'3'`, fallback `serviceMode`; sem `m.type`
- [ ] T005 [P] [US1] Atualizar RED em `ci-api-v2/src/modules/ouvidoria/test/use-cases/get-relatorio-gestao.use-case.spec.ts` — fixture `{ month, tipoConcessao, type, total }`; teste de paridade com mock `porMotivo`
- [ ] T006 [P] [US1] Atualizar RED em `ci-api-v2/src/modules/ouvidoria/lib/relatorio-gestao-pdf-sections.spec.ts` — título "Tipo de concessão"; linhas com rótulo de concessão
- [ ] T007 [P] [US1] Atualizar RED em `ci-api-v2/src/modules/ouvidoria/test/use-cases/export-relatorio-gestao-excel.use-case.spec.ts` — nome aba "Tipo de concessão"

### Implementation (GREEN)

- [ ] T008 [US1] Alterar `ci-api-v2/src/modules/ouvidoria/repository/get-relatorio-gestao-tipo-manifestacao.repository.ts` — SELECT mês + expressão concessão (helper T002), `GROUP BY 1, 2` — depende de T002, T004
- [ ] T009 [US1] Estender `RelatorioGestaoResponse` / row type em `ci-api-v2/src/modules/ouvidoria/ouvidoria.types.ts` — adicionar `tipoConcessao: string`
- [ ] T010 [US1] Atualizar schema Zod da resposta em `ci-api-v2/src/modules/ouvidoria/ouvidoria.schemas.ts` — `tipoConcessao` + `type` — depende de T009
- [ ] T011 [US1] Atualizar `ci-api-v2/src/modules/ouvidoria/use-cases/get-relatorio-gestao.use-case.ts` — mapear rows: normalizar null → `"Não informado"`; setar `type = tipoConcessao`; `omitZeroSeries` inalterado — depende de T008, T010
- [ ] T012 [US1] Atualizar `ci-api-v2/src/modules/ouvidoria/lib/relatorio-gestao-pdf-sections.ts` — `TITLES.porTipoManifestacao = 'Tipo de concessão'`; coluna Concessão — depende de T006
- [ ] T013 [US1] Atualizar `ci-api-v2/src/modules/ouvidoria/use-cases/export-relatorio-gestao-excel.use-case.ts` — aba e headers "Tipo de concessão" / "Concessão" — depende de T007, T011

**Checkpoint**: T004–T007 GREEN; paridade test T005 passando.

---

## Phase 4: User Story 1 — Client

### Tests (RED)

- [ ] T014 [P] [US1] Atualizar RED `ci-client-v2/apps/web/src/modules/ouvidoria/__tests__/relatorio-gestao-mappers.test.ts` — agregação por "Água / Saneamento", não "Reclamação"
- [ ] T015 [P] [US1] Atualizar RED `ci-client-v2/apps/web/src/modules/ouvidoria/__tests__/TipoManifestacaoChartCard.test.tsx` — título "Tipo de concessão"
- [ ] T016 [P] [US1] Atualizar fixtures em `relatorio-gestao-api.test.ts`, `OuvidoriaRelatorioGestaoPage.test.tsx`, `MotivoChartCard.test.tsx` — shape com `tipoConcessao`

### Implementation (GREEN)

- [ ] T017 [US1] Atualizar `ci-client-v2/apps/web/src/modules/ouvidoria/api/relatorio-gestao.ts` — tipo da linha com `tipoConcessao`
- [ ] T018 [US1] Atualizar `ci-client-v2/apps/web/src/modules/ouvidoria/lib/relatorio-gestao-mappers.ts` — `mapTipoManifestacaoChart` usa `tipoConcessao ?? type`; remover `labelTipoManifestacao`/`TYPE_OPTIONS` deste fluxo — depende de T017, T014
- [ ] T019 [US1] Atualizar `ci-client-v2/apps/web/src/modules/ouvidoria/components/dashboard/TipoManifestacaoChartCard.tsx` — copy "Tipo de concessão" (descrição formulário/programa) — depende de T015

**Checkpoint**: Vitest ouvidoria relatorio verde.

---

## Phase 5: Validação AGEMAN & docs

- [ ] T020 [US1] Roteiro manual: comparar totais 2026-acumulado tenant AGEMAN — bloco vs aba **RESUMO GERAL → TIPO DE CONCESSÃO** e amostra mensal vs **aba 7** (`new-demanda/extracted-sheets.txt`); registrar desvios de rótulo aceitos em `research.md` se houver
- [ ] T021 [P] [US1] Adicionar nota de supersessão no exemplo JSON de `civ2-docs/specs/042-relatorio-gestao-ouvidoria/contracts/relatorio-gestao.md` apontando para `050/.../relatorio-gestao-tipo-concessao.md`
- [ ] T022 [US1] Executar suite completa: `npm test -- --testPathPatterns=relatorio-gestao` (API) + `npm test -- relatorio-gestao` (web)

---

## Dependencies & Execution Order

```text
T002 → T003
T002 → T008 → T011 → T012, T013
T011 → T017 → T018
T004–T007 RED paralelo antes de T008–T013
T020 após T022 (validação manual)
```

## Parallel Example (Phase 3 tests)

```text
T004, T005, T006, T007 em paralelo → T008+
```

---

## Implementation Strategy

**MVP**: Phase 2 + Phase 3 (API + exports) — AGEMAN já valida via Excel/PDF.  
**Completo**: Phase 4 (tela) + T020 planilha.

**Sem escopo nesta feature**: renomear arquivo `TipoManifestacaoChartCard.tsx`; unificar fallback orientações; matriz multi-ano aba 7 no Excel export.
