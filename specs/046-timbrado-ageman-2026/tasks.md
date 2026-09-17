---

description: "Task list for feature 046 — Timbrado oficial AGEMAN 2026"
---

# Tasks: Timbrado oficial AGEMAN 2026

**Input**: Design documents from `civ2-docs/specs/046-timbrado-ageman-2026/`

**Prerequisites**: [plan.md](./plan.md), [spec.md](./spec.md), [research.md](./research.md), [data-model.md](./data-model.md), [contracts/](./contracts/), [quickstart.md](./quickstart.md)

**Tests**: Constitution II (Test-First) é NON-NEGOTIABLE — testes abaixo são obrigatórios, RED antes de GREEN. IDs em [contracts/test-strategy.md](./contracts/test-strategy.md) (`CT-LH-*` / `CT-LH-CLIENT-*`).

**Organization**: Tarefas por user story (spec.md) para entrega e teste independentes.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Pode rodar em paralelo (arquivos diferentes, sem dependência pendente)
- **[Story]**: US1–US3, conforme spec.md
- Caminho de arquivo exato em cada descrição

## Path Conventions

- API: `ci-api-v2/src/common/letterhead/` + `ci-api-v2/src/modules/<dominio>/`
- Client: `ci-client-v2/apps/web/src/modules/shared/` e módulos de domínio

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Arte oficial no build e pasta do kernel — sem isso o FR-012 vira o caminho permanente.

- [x] T001 Extrair/cropar `header-faixa.png` e `marca-dagua-brasao.png` de `new-timbrado/Folha padrão 2026 - Vertical.docx` (`word/media/image2.png` e `image1.png`) para `ci-api-v2/src/common/letterhead/assets/`
- [x] T002 [P] Incluir `src/common/letterhead/assets/**/*` em `compilerOptions.assets` de `ci-api-v2/nest-cli.json` (hoje só `modules/ouvidoria/assets/**/*`)
- [x] T003 [P] Criar o tipo `LetterheadResult` em `ci-api-v2/src/common/letterhead/letterhead-result.ts` (`applied`, `reason`: `applied` | `not-ageman` | `assets-missing` | `embed-failed`)

**Checkpoint**: PNGs versionados e copiados no `dist` no próximo build.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Kernel transversal usado por **todas** as user stories. Nenhuma story começa antes.

**⚠️ CRITICAL**: Nenhuma user story pode iniciar antes desta fase estar completa.

### Tests (RED primeiro)

- [x] T004 [P] Teste `isAgemanTenant` — CT-LH-001 — em `ci-api-v2/src/common/letterhead/ageman-tenant.spec.ts`
- [x] T005 [P] Teste `official-page-metrics` (A4 + margens 40/17,5/22,5/22,5 mm) em `ci-api-v2/src/common/letterhead/official-page-metrics.spec.ts`
- [x] T006 [P] Teste `resolve-letterhead-assets` (ambos presentes vs um ausente → vazio) — CT-LH-002 — em `ci-api-v2/src/common/letterhead/resolve-letterhead-assets.spec.ts`
- [x] T007 [P] Teste `apply-letterhead-pdfkit` (AGEMAN+assets → applied; sem selo OUVIDORIA/`#E8F2FF`; 2 páginas carimbam as duas) — CT-LH-003 + CT-LH-015 — em `ci-api-v2/src/common/letterhead/apply-letterhead-pdfkit.spec.ts`
- [x] T008 [P] Teste `apply-letterhead-pdf-lib` — CT-LH-004 — em `ci-api-v2/src/common/letterhead/apply-letterhead-pdf-lib.spec.ts`
- [x] T009 [P] Teste `apply-letterhead-docx` (header + watermark, sem rodapé de paginação) — CT-LH-005 — em `ci-api-v2/src/common/letterhead/apply-letterhead-docx.spec.ts`
- [x] T010 [P] Teste arte ausente e tenant não-AGEMAN — CT-LH-006 + CT-LH-007 — em `ci-api-v2/src/common/letterhead/apply-letterhead-pdfkit.spec.ts` (bloco extra) ou `letterhead-fallback.spec.ts`

### Implementation

- [x] T011 Implementar `isAgemanTenant` + UUID canônico em `ci-api-v2/src/common/letterhead/ageman-tenant.ts` (GREEN de T004); reexportar o UUID para a Ouvidoria deixar de duplicar `MANIFESTACAO_DOC_AGEMAN_TENANT_ID` em `ci-api-v2/src/modules/ouvidoria/lib/manifestacao-document-branding.ts`
- [x] T012 [P] Implementar métricas oficiais em `ci-api-v2/src/common/letterhead/official-page-metrics.ts` (GREEN de T005)
- [x] T013 Implementar `resolve-letterhead-assets.ts` (paths `__dirname` / `src` / `dist`; os dois PNGs ou nenhum) em `ci-api-v2/src/common/letterhead/resolve-letterhead-assets.ts` (GREEN de T006)
- [x] T014 Implementar carimbo PDFKit em `ci-api-v2/src/common/letterhead/apply-letterhead-pdfkit.ts` (GREEN de T007, T010)
- [x] T015 [P] Implementar carimbo pdf-lib em `ci-api-v2/src/common/letterhead/apply-letterhead-pdf-lib.ts` (GREEN de T008)
- [x] T016 [P] Implementar header+watermark `docx` em `ci-api-v2/src/common/letterhead/apply-letterhead-docx.ts` (GREEN de T009)
- [x] T017 Criar `set-letterhead-response-header.ts` (`X-Letterhead-Applied: 0|1` só se tenant AGEMAN; omitir senão) em `ci-api-v2/src/common/letterhead/set-letterhead-response-header.ts`

**Checkpoint**: Kernel testado. User stories podem carimbar qualquer renderer.

---

## Phase 3: User Story 1 - Operador emite documento com a folha 2026 (Priority: P1) 🎯 MVP

**Goal**: Dossiê de manifestação (PDF e Word) no tenant AGEMAN usa a folha 2026; arte ausente → miolo + aviso; sem selo/rodapé antigos.

**Independent Test**: Login AGEMAN, baixar PDF e Word de uma manifestação, comparar com `Folha padrão 2026 - Vertical.docx`. Esconder os PNGs e repetir: arquivo baixa, toast de aviso, sem timbrado antigo.

### Tests for User Story 1 ⚠️

- [x] T018 [P] [US1] Atualizar/estender `ci-api-v2/src/modules/ouvidoria/test/use-cases/generate-manifestacao-documento.use-case.spec.ts` e `lib/manifestacao-document-branding.spec.ts`: AGEMAN sem selo “OUVIDORIA” / título “AGEMAN — Ouvidoria”; fallback não-AGEMAN permanece — CT-LH-009
- [x] T019 [P] [US1] Teste do header HTTP no handler de documento PDF/DOCX — CT-LH-008 — em `ci-api-v2/src/modules/ouvidoria/ouvidoria.controller.spec.ts`
- [x] T020 [P] [US1] Teste `parseLetterheadAppliedHeader` — CT-LH-CLIENT-001 — em `ci-client-v2/apps/web/src/modules/shared/lib/__tests__/letterhead-download.test.ts`
- [x] T021 [P] [US1] Teste RTL de aviso em `ci-client-v2/apps/web/src/modules/ouvidoria/components/__tests__/ManifestacaoDownloadButtons.test.tsx` (ou arquivo novo) — CT-LH-CLIENT-006 no piloto da manifestação

### Implementation for User Story 1

- [x] T022 [US1] Ligar `apply-letterhead-pdfkit` em `ci-api-v2/src/modules/ouvidoria/lib/render-manifestacao-pdf.ts`: remover faixa azul, selo OUVIDORIA e rodapé de paginação no caminho AGEMAN; respeitar `official-page-metrics` (GREEN de T018)
- [x] T023 [US1] Ligar `apply-letterhead-docx` em `ci-api-v2/src/modules/ouvidoria/lib/render-manifestacao-docx.ts` no lugar de `letterheadLines` no tenant AGEMAN (GREEN de T018)
- [x] T024 [US1] Setar `X-Letterhead-Applied` em `documentoPdf` / `documentoDocx` de `ci-api-v2/src/modules/ouvidoria/ouvidoria.controller.ts` via `set-letterhead-response-header.ts` (GREEN de T019)
- [x] T025 [US1] Implementar `ci-client-v2/apps/web/src/modules/shared/lib/letterhead-download.ts` (ler header + copy canônica do toast) (GREEN de T020)
- [x] T026 [US1] Usar `letterhead-download` em `ci-client-v2/apps/web/src/modules/ouvidoria/components/ManifestacaoDownloadButtons.tsx` e no download da lista em `ci-client-v2/apps/web/src/modules/ouvidoria/pages/ManifestacoesListPage.tsx` (GREEN de T021)

**Checkpoint**: US1 entregável — ofício de manifestação oficial no AGEMAN.

---

## Phase 4: User Story 2 - Mesmo timbrado em todos os módulos + PDF e Word (Priority: P1)

**Goal**: Todas as famílias do inventário compartilham o kernel; famílias só-PDF ganham Word; Compras Insights/Maturidade ganham ofício PDF+Word e **mantêm HTML extra**.

**Independent Test**: Emitir PDF e Word de cada família no AGEMAN e confirmar a mesma folha. Em Compras, HTML extra ainda baixa. Planilha SIGED/Excel de gestão inalterados.

### Tests for User Story 2 ⚠️

- [x] T027 [P] [US2] Teste relatório de gestão PDF (kernel, sem arte antiga) + use-case DOCX novo — CT-LH-010 — em `ci-api-v2/src/modules/ouvidoria/lib/render-relatorio-gestao-pdf.spec.ts` e `test/use-cases/export-relatorio-gestao-docx.use-case.spec.ts`
- [x] T028 [P] [US2] Testes Diagnóstico painel/seleção + documento institucional (PDF kernel + DOCX novos) — CT-LH-011 — em `ci-api-v2/src/modules/diagnostico/` e `documento-institucional/` (`*.spec.ts` dos use-cases novos)
- [x] T029 [P] [US2] Teste histórico Gabinete PDF+DOCX — CT-LH-012 — em `ci-api-v2/src/modules/gabinete/test/use-cases/generate-historico-pdf.use-case.spec.ts` e `generate-historico-docx.use-case.spec.ts`
- [x] T030 [P] [US2] Teste Tramitação + ANPD (pdf-lib + rotas DOCX) — CT-LH-013 — em `ci-api-v2/src/modules/tramitacao/` e `it-fiscalizacao/` specs
- [x] T031 [P] [US2] Teste Compras: `GET export` continua HTML; `export/pdf` e `export/docx` são ofício — CT-LH-014 — em `ci-api-v2/src/modules/compras-insights/` e `compras-maturidade/` specs
- [x] T032 [P] [US2] Teste RTL `OficioExportMenu` (PDF+Word; HTML só com `htmlExtra`) — CT-LH-CLIENT-002 — em `ci-client-v2/apps/web/src/modules/shared/components/__tests__/OficioExportMenu.test.tsx`
- [x] T033 [P] [US2] Testes Compras Insights/Maturidade UI (menu, HTML extra) — CT-LH-CLIENT-003/004 — em `ci-client-v2/apps/web/src/modules/compras/__tests__/ComprasInsightsPage.test.tsx` e `ComprasMaturidadePage.*.test.tsx`

### Implementation for User Story 2

- [x] T034 [US2] Ligar kernel em `ci-api-v2/src/modules/ouvidoria/lib/render-relatorio-gestao-pdf.ts`; criar `export-relatorio-gestao-docx.use-case.ts` + rota `GET relatorio-gestao/docx` em `ouvidoria.controller.ts` / `ouvidoria.module.ts` (GREEN de T027)
- [x] T035 [P] [US2] Ligar kernel em `ci-api-v2/src/modules/diagnostico/pdf/letterhead.service.ts` (só AGEMAN; outros tenants no fallback atual); criar `generate-dashboard-docx.use-case.ts` e `generate-selecao-docx.use-case.ts` + rotas em `diagnostico.controller.ts` (GREEN de T028)
- [x] T036 [P] [US2] Criar `generate-documento-docx.use-case.ts` + rota `GET documentos/:id/docx` em `ci-api-v2/src/modules/diagnostico/diagnostico.controller.ts` e `documento-institucional.module.ts` (GREEN de T028)
- [x] T037 [P] [US2] Ligar kernel em `ci-api-v2/src/modules/gabinete/services/compose-historico-pdf.service.ts`; criar `generate-historico-docx.use-case.ts` + rota `historico.docx` em `gabinete.controller.ts` (GREEN de T029)
- [x] T038 [P] [US2] Ligar `apply-letterhead-pdf-lib` em `ci-api-v2/src/modules/tramitacao/lib/protocolo-pdf-template.ts`; criar `export-protocolo-docx.use-case.ts` + `POST protocolos/:id/baixar-docx` em `tramitacao.controller.ts` (GREEN de T030)
- [x] T039 [P] [US2] Ligar pdf-lib em `ci-api-v2/src/modules/it-fiscalizacao/lib/anpd-pdf-template.ts`; criar `generate-anpd-docx.use-case.ts` + `POST incidentes/:id/anpd/generate-docx` em `it-fiscalizacao.controller.ts` (GREEN de T030)
- [x] T040 [P] [US2] Criar `export-insights-oficio-pdf.use-case.ts` e `export-insights-oficio-docx.use-case.ts` + rotas `GET export/pdf` e `GET export/docx` em `ci-api-v2/src/modules/compras-insights/`; **não** alterar o body HTML de `GET export` (GREEN de T031)
- [x] T041 [P] [US2] Criar `export-maturidade-oficio-pdf.use-case.ts` e `export-maturidade-oficio-docx.use-case.ts` + rotas em `ci-api-v2/src/modules/compras-maturidade/`; HTML `GET export` permanece (GREEN de T031)
- [x] T042 [US2] Implementar `OficioExportMenu.tsx` em `ci-client-v2/apps/web/src/modules/shared/components/OficioExportMenu.tsx` usando `letterhead-download.ts` (GREEN de T032)
- [x] T043 [US2] Trocar botões de exportação nas telas cobertas para `OficioExportMenu` (PDF+Word; HTML extra só em Compras) em: `ci-client-v2/apps/web/src/modules/ouvidoria/pages/OuvidoriaRelatorioGestaoPage.tsx`, páginas Diagnóstico/documento institucional, `GabineteAtoDetailPage.tsx`, tramitação (`linked-record-pdf` / painel de protocolo), UI ANPD, `ComprasInsightsPage.tsx`, `MaturidadeExportButton.tsx` (GREEN de T033 + CT-LH-CLIENT-005) — **exceções:** `ManifestacaoDownloadButtons` (layout `stack` no modal); Tramitação ZIP + Word em botões separados (sem rota PDF ofício); `linked-record-pdf` client-side; documento institucional sem UI de export ainda; seleção de processos sem botão no client

**Checkpoint**: US1 + US2 — um único timbrado, PDF e Word em todas as famílias cobertas.

---

## Phase 5: User Story 3 - Destinatário reconhece o ofício oficial (Priority: P2)

**Goal**: Arte 2026 só no AGEMAN; fallback dos outros tenants intacto; zero resquício do timbrado antigo nas emissões AGEMAN; arquivos já baixados não são reescritos (já verdade por geração on-demand).

**Independent Test**: Jacaranda emite sem faixa/brasão 2026. Diff visual AGEMAN vs `Folha padrão 2026 - Vertical.docx` (quickstart). Grep não acha selo/faixa antiga nos renderers do caminho AGEMAN.

### Tests for User Story 3 ⚠️

- [x] T044 [P] [US3] Teste de isolamento: tenant não-AGEMAN não embute PNGs 2026 e omite `X-Letterhead-Applied` num handler piloto + num pdf-lib — reforço CT-LH-007/008 em `ci-api-v2/src/common/letterhead/letterhead-fallback.spec.ts` e `ouvidoria.controller.spec.ts`
- [x] T045 [P] [US3] Guardrail de regressão: strings/cores do timbrado antigo (`#E8F2FF`, selo `OUVIDORIA` de cabeçalho, “Diagnóstico — documento institucional”) não aparecem no caminho AGEMAN — teste em `ci-api-v2/src/common/letterhead/letterhead-no-legacy-art.spec.ts`

### Implementation for User Story 3

- [x] T046 [US3] Confirmar fallback explícito nos renderers não-AGEMAN (Ouvidoria branding default; Diagnóstico textual atual **sem** vazar arte 2026) em `render-manifestacao-pdf.ts` e `diagnostico/pdf/letterhead.service.ts` (GREEN de T044)
- [x] T047 [US3] Remover arte morta do caminho AGEMAN: `ci-api-v2/src/modules/ouvidoria/assets/pdf-letterhead/README.md` e usos órfãos de `logo-ageman.png` / `letterheadLines` no tenant AGEMAN (GREEN de T045) — README reescrito (legado só não-AGEMAN); `logo-ageman.png` mantido para fallback Jacaranda
- [x] T048 [US3] Documentar o kernel e o UUID AGEMAN em `ci-api-v2/CONTEXT.md` (parágrafo “Folha padrão AGEMAN 2026”)

**Checkpoint**: US3 — reconhecimento institucional e isolamento de tenant verificáveis.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Validação ponta a ponta e higiene.

- [x] T049 Rodar a conferência do [quickstart.md](./quickstart.md) (AGEMAN vs Jacaranda + cenário de assets ausentes) e anotar o resultado no próprio `civ2-docs/specs/046-timbrado-ageman-2026/quickstart.md` (checklist no final, se ainda não houver) — checklist parcial; smoke visual manual pendente
- [x] T050 [P] Garantir que todos os handlers novos setam `X-Letterhead-Applied` via `set-letterhead-response-header.ts` (varredura em `ouvidoria.controller.ts`, `diagnostico.controller.ts`, `gabinete.controller.ts`, `tramitacao.controller.ts`, `it-fiscalizacao.controller.ts`, `compras-insights.controller.ts`, `compras-maturidade.controller.ts`) — **exceção:** `POST incidentes/:id/anpd/generate` (JSON + URL assinada, sem StreamableFile)
- [x] T051 [P] Atualizar o índice de specs ativas se ainda faltar a linha 046 em `civ2-docs/specs/README.md`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: sem dependências
- **Foundational (Phase 2)**: depende do Setup — **bloqueia** todas as stories
- **US1 (Phase 3)**: depende da Phase 2 — MVP
- **US2 (Phase 4)**: depende da Phase 2; reusa o header/toast da US1 (`letterhead-download`) mas pode começar os use-cases API em paralelo após T017
- **US3 (Phase 5)**: depende de US1+US2 (precisa dos renderers já migrados para o guardrail de arte antiga)
- **Polish (Phase 6)**: depende das stories desejadas

### User Story Dependencies

- **US1 (P1)**: após Phase 2 — sem dependência de outras stories
- **US2 (P1)**: após Phase 2; client do menu reusa T025; famílias API são independentes entre si
- **US3 (P2)**: após US1+US2 (isolamento e varredura de arte antiga)

### Within Each User Story

- Testes RED antes do GREEN
- Kernel (Phase 2) antes de ligar renderers
- Use-case antes da rota
- Rota antes do botão no client

### Parallel Opportunities

- T002/T003 no Setup
- T004–T010 (testes do kernel) em paralelo
- T015/T016 após T013
- T018–T021 (testes US1) em paralelo
- T027–T033 (testes US2) em paralelo
- T035–T041 (impl API por família) em paralelo depois da Phase 2
- T044/T045 em paralelo

---

## Parallel Example: User Story 2 (API por família)

```text
Task: "T035 Diagnóstico PDF kernel + DOCX em ci-api-v2/src/modules/diagnostico/"
Task: "T037 Gabinete histórico PDF+DOCX em ci-api-v2/src/modules/gabinete/"
Task: "T038 Tramitação pdf-lib + baixar-docx em ci-api-v2/src/modules/tramitacao/"
Task: "T039 ANPD pdf-lib + generate-docx em ci-api-v2/src/modules/it-fiscalizacao/"
Task: "T040 Compras Insights ofício em ci-api-v2/src/modules/compras-insights/"
Task: "T041 Compras Maturidade ofício em ci-api-v2/src/modules/compras-maturidade/"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Phase 1 + Phase 2 (kernel)
2. Phase 3 (manifestação PDF/Word + aviso)
3. **STOP and VALIDATE** com o DOCX oficial
4. Demo interno da folha 2026

### Incremental Delivery

1. Setup + Foundational → kernel pronto
2. US1 → ofício de manifestação (MVP)
3. US2 → demais módulos + Word + Compras
4. US3 → isolamento + higiene da arte antiga
5. Polish → quickstart

### Parallel Team Strategy

1. Time fecha Phase 1–2 junto
2. Dev A: US1 (Ouvidoria manifestação + client shared)
3. Dev B–D: famílias US2 em paralelo (Diagnóstico, Gabinete/Tramitação, Compras)
4. Alguém fecha US3 + T050 (headers em todos os controllers)

---

## Notes

- [P] = arquivos diferentes, sem dependência pendente
- Não criar exportação nova em Insights/Maturidade de Ouvidoria, Gabinete, TI ou SIGED
- Não converter Excel/SIGED em ofício
- Não voltar ao timbrado antigo se a arte faltar
- Commit por tarefa ou grupo lógico (só se o usuário pedir)
