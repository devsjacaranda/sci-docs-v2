---
description: "Task list for Série histórica — Relatório de Gestão (050)"
---

# Tasks: Série histórica mês×ano — Relatório de Gestão

**Input**: `civ2-docs/specs/050-relatorio-gestao-serie-historica-ageman/` (`spec.md`, `plan.md`, `research.md`, `contracts/serie-historica-relatorio-gestao.md`)

**Tests**: Obrigatórios (constitution) — RED antes de implementação nos repositories e use-case.

**Organization**: US1 (P1 MVP) → US2 (P2 grades anuais) → US3 (P2 Excel). US4 forma = fora do escopo.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: paralelo se arquivos diferentes
- **[Story]**: US1, US2, US3

**Paths**: `ci-api-v2/src/modules/ouvidoria/`, `ci-client-v2/apps/web/src/modules/ouvidoria/`

---

## Phase 1: Setup

**Purpose**: Schema Zod, tipos e helper puro da grade.

- [ ] T001 [P] Adicionar `serieHistoricaQuerySchema` e tipos `GradeMesAno`, `GradeMetricaAnual` em `ci-api-v2/src/modules/ouvidoria/ouvidoria.schemas.ts` / `ouvidoria.types.ts` alinhados a `contracts/serie-historica-relatorio-gestao.md`
- [ ] T002 [P] Implementar `build-grade-mes-ano.ts` em `ci-api-v2/src/modules/ouvidoria/lib/` + testes Vitest/Jest em `ci-api-v2/src/modules/ouvidoria/test/lib/build-grade-mes-ano.spec.ts` (preenche zeros, totais, percentuais)
- [ ] T003 [P] Fixture JSON amostra AGEMAN (1 mês×ano conhecido da planilha) em `ci-api-v2/src/modules/ouvidoria/test/fixtures/serie-historica-atendimentos.json`

---

## Phase 2: Foundational

**Purpose**: Repository atendimentos + use-case + rota (MVP backend).

- [ ] T004 Escrever teste RED `get-serie-historica-atendimentos.repository.spec.ts` em `ci-api-v2/src/modules/ouvidoria/test/repository/` — GROUP BY year/month, tenant scoped
- [ ] T005 Implementar `get-serie-historica-atendimentos.repository.ts` — reutilizar helper de timezone/recorte de datas do relatório 042
- [ ] T006 Escrever teste RED `get-relatorio-gestao-serie-historica.use-case.spec.ts` em `ci-api-v2/src/modules/ouvidoria/test/use-cases/`
- [ ] T007 Implementar `get-relatorio-gestao-serie-historica.use-case.ts` — compõe `atendimentosMesAno` via T002+T005; `resolutividadeAnual`/`concessaoAnual` null no MVP
- [ ] T008 Registrar `GET /ouvidoria/relatorio-gestao/serie-historica` em `ouvidoria.controller.ts` + teste e2e/controller spec mínimo

**Checkpoint**: MVP API US1 — JSON conferível via curl/Postman.

---

## Phase 3: User Story 1 — Tela atendimentos mês×ano (P1)

- [ ] T009 [P] [US1] Hook `useRelatorioGestaoSerieHistorica.ts` com React Query `enabled` quando aba ativa
- [ ] T010 [US1] Componente `SerieHistoricaAtendimentosTable.tsx` — scroll horizontal, coluna mês sticky, linha TOTAL, % formatado
- [ ] T011 [US1] Integrar aba **Série histórica** em `RelatorioGestaoPage.tsx` (ou rota filha lazy) — **não** alterar fetch do relatório por período
- [ ] T012 [P] [US1] Testes Vitest mapper/UI em `ci-client-v2/apps/web/src/modules/ouvidoria/__tests__/serie-historica-atendimentos.spec.tsx`
- [ ] T013 [US1] Validar manualmente ≥3 células contra planilha / SQL (quickstart mental: agosto/2025, totais linha, grand total) — documentar em PR

**Checkpoint**: US1 entregável independente.

---

## Phase 4: User Story 2 — Resolutividade e concessão anual (P2)

- [ ] T014 [P] [US2] RED tests + `get-serie-historica-resolutividade-anual.repository.ts` — mesmas regras de classificação do bloco resolutividade 042
- [ ] T015 [P] [US2] RED tests + `get-serie-historica-concessao-anual.repository.ts`
- [ ] T016 [US2] Estender use-case T007 para preencher `resolutividadeAnual` e `concessaoAnual`
- [ ] T017 [P] [US2] `SerieHistoricaResolutividadeTable.tsx` + `SerieHistoricaConcessaoTable.tsx`
- [ ] T018 [US2] Testes de paridade: coluna ano Y vs. `GET /ouvidoria/relatorio-gestao?year=Y` KPIs/blocos relacionados

---

## Phase 5: User Story 3 — Export Excel (P2)

- [ ] T019 [US3] RED test export handler `export-relatorio-gestao-serie-historica-excel.use-case.spec.ts`
- [ ] T020 [US3] Implementar use-case + `GET .../serie-historica/excel` (ExcelJS, abas conforme contrato)
- [ ] T021 [US3] Botão export na aba Série histórica + teste Vitest do nome de arquivo

---

## Phase 6: Performance & FR-013 (transversal)

- [ ] T022 Medir p95 de `GET .../serie-historica` no tenant AGEMAN (acumulado 2018–ano corrente) contra SC-003 (5s) e Excel 30s; se falhar, migration índice `(tenantId, createdAt)` **sem** tabela de cache (mesmo padrão T056 da 042)
- [ ] T023 Confirmar que `GET /ouvidoria/relatorio-gestao` (modo período) permanece ≤ 5s com aba histórica **não** montada (SC-002)

---

## Dependencies

```text
Phase 1 → Phase 2 → Phase 3 (MVP)
Phase 2 → Phase 4 → Phase 5
Phase 6 após Phase 3 (mínimo) e novamente após Phase 5
```

**Conflito de arquivo**: `get-relatorio-gestao.use-case.ts` (049) — **não editar**; série histórica fica em use-case separado (plan.md).

---

## Out of scope (não criar tasks)

- Grade forma de atendimento mês×canal×ano (US4 / spec futura)
- Resolutividade mês×ano QUANT_MENSAL (P3)
- Export PDF série histórica (P3)
- Query `modo=historico` no GET principal
