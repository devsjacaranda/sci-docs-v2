# Tasks: Módulo Saúde — Atendimento UBS / e-SUS

**Input**: Design documents from `sci-docs-v2/specs/024-saude-atendimento-ubs/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Tests**: TDD obrigatório (constitution + plan) — testes RED antes de implementação.

**Organization**: Por user story (US1–US7 da spec.md). US2 (cadastros) precede US1 (consultas) por dependência de FKs.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Paralelizável (arquivos distintos, sem dependência de tarefas incompletas)
- **[Story]**: US1…US7 mapeados à spec

## Path Conventions

- Client: `sci-client-monorepo/apps/web/src/modules/saude/`
- Shell: `sci-client-monorepo/apps/web/src/modules/shell/config/`
- Router: `sci-client-monorepo/apps/web/src/app/router.tsx`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Scaffold do módulo e wiring mínimo no monorepo.

- [X] T001 Criar estrutura de pastas do módulo em `sci-client-monorepo/apps/web/src/modules/saude/` conforme plan.md (`api/`, `schemas/`, `lib/`, `data/`, `pages/`, `components/`, `__tests__/`)
- [X] T002 Criar barrel `sci-client-monorepo/apps/web/src/modules/saude/index.tsx` com export vazio de `SAUDE_OVERRIDES` (placeholder)
- [X] T003 [P] Registrar grupo **Saúde** em `sci-client-monorepo/apps/web/src/modules/shell/config/navigation.ts` (ícone, ordem, licença `base`)
- [X] T004 [P] Adicionar entradas placeholder `saude-*` em `sci-client-monorepo/apps/web/src/modules/shell/config/screens.ts` (licença `base`, paths conforme `contracts/client-saude-ui.md`)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Tipos, persistência local, helpers compartilhados — **BLOCKS** todas as user stories.

**⚠️ CRITICAL**: Nenhuma US inicia antes desta fase.

- [X] T005 [P] Definir enums e DTOs base em `sci-client-monorepo/apps/web/src/modules/saude/api/types.ts` (CodigoClinico, Sexo, status enums — ver data-model.md)
- [X] T006 [P] Implementar helper de persistência `sci-client-monorepo/apps/web/src/modules/saude/lib/storage.ts` (`ci:saude:v1:{tenantId}:{entity}`, get/set, tenant fallback `demo-careiro`)
- [X] T007 [P] Criar `sci-client-monorepo/apps/web/src/modules/saude/schemas/shared.schema.ts` com `codigoClinicoSchema` e reexports
- [X] T008 Implementar `ensureSaudeSeed(tenantId)` stub em `sci-client-monorepo/apps/web/src/modules/saude/data/seed.ts` (idempotente, no-op inicial)
- [X] T009 Integrar `SAUDE_OVERRIDES` em `sci-client-monorepo/apps/web/src/app/router.tsx` (import de `modules/saude/index.tsx`, merge em `screenElement`)
- [X] T010 [P] Teste unitário helper storage em `sci-client-monorepo/apps/web/src/modules/saude/lib/__tests__/storage.test.ts`

**Checkpoint**: Foundation ready — user stories podem começar.

---

## Phase 3: User Story 2 — Cadastros de apoio (Priority: P1)

**Goal**: Cidadãos, profissionais, ~8 UBS Careiro, medicamentos — base para consultas e relatórios.

**Independent Test**: Abrir Unidades → ver 8 UBS; CRUD cidadão/profissional; medicamento listável.

### Tests for User Story 2 ⚠️

- [X] T011 [P] [US2] Testes Zod round-trip cidadão em `sci-client-monorepo/apps/web/src/modules/saude/schemas/__tests__/cidadao.schema.test.ts`
- [X] T012 [P] [US2] Testes Zod round-trip profissional/unidade em `sci-client-monorepo/apps/web/src/modules/saude/schemas/__tests__/profissional-unidade.schema.test.ts`
- [X] T013 [P] [US2] Testes store unidades seed Careiro em `sci-client-monorepo/apps/web/src/modules/saude/lib/__tests__/unidades-store.test.ts`

### Implementation for User Story 2

- [X] T014 [P] [US2] Dados fixos 8 UBS em `sci-client-monorepo/apps/web/src/modules/saude/data/careiro-unidades.ts`
- [X] T015 [P] [US2] Schemas Zod em `sci-client-monorepo/apps/web/src/modules/saude/schemas/cidadao.schema.ts`, `profissional.schema.ts`, `unidade.schema.ts`, `medicamento.schema.ts`
- [X] T016 [P] [US2] Stores CRUD em `sci-client-monorepo/apps/web/src/modules/saude/lib/cidadaos-store.ts`, `profissionais-store.ts`, `unidades-store.ts`, `medicamentos-store.ts`
- [X] T017 [US2] Facades API em `sci-client-monorepo/apps/web/src/modules/saude/api/cidadaos.ts`, `profissionais.ts`, `unidades.ts`, `medicamentos.ts`
- [X] T018 [US2] Seed cadastros sintéticos em `sci-client-monorepo/apps/web/src/modules/saude/data/seed.ts` (8 UBS, profissionais médico/enfermeiro CBO 225*/2235*, cidadãos, medicamentos)
- [X] T019 [P] [US2] Página `sci-client-monorepo/apps/web/src/modules/saude/pages/UnidadesPage.tsx` com `UnidadeStatsCard` placeholder
- [X] T020 [P] [US2] Telas list/form cidadãos e profissionais via `ScreenPage` config ou páginas dedicadas — registrar fields/columns em `sci-client-monorepo/apps/web/src/modules/shell/config/screens.ts` (`saude-cidadaos`, `saude-profissionais`, `saude-medicamentos`)
- [X] T021 [US2] Wire lazy overrides US2 em `sci-client-monorepo/apps/web/src/modules/saude/index.tsx` (`saude-unidades`, cadastros)
- [X] T022 [US2] Implementar `sci-client-monorepo/apps/web/src/modules/saude/lib/unidades-stats.ts` (totais zerados OK nesta fase)

**Checkpoint**: Cadastros seedados e navegáveis.

---

## Phase 4: User Story 1 — CRUD Consulta agregada (Priority: P1) 🎯 MVP

**Goal**: Listar, criar, editar, detalhar consulta com 6 dimensões (profissional/local, cidadão, atendimento, clínico, procedimentos, receitas).

**Independent Test**: Criar consulta completa → reabrir detalhe com abas → editar campo clínico → persistência após refresh.

### Tests for User Story 1 ⚠️

- [X] T023 [P] [US1] Testes schema consulta em `sci-client-monorepo/apps/web/src/modules/saude/schemas/__tests__/consulta.schema.test.ts` (campos obrigatórios, listas vazias)
- [X] T024 [P] [US1] Testes store consultas CRUD em `sci-client-monorepo/apps/web/src/modules/saude/lib/__tests__/consultas-store.test.ts`
- [X] T025 [P] [US1] Teste integração página lista em `sci-client-monorepo/apps/web/src/modules/saude/__tests__/ConsultasListPage.test.tsx`

### Implementation for User Story 1

- [X] T026 [P] [US1] Schema Zod `sci-client-monorepo/apps/web/src/modules/saude/schemas/consulta.schema.ts` (ConteudoClinico, Procedimento, ItemReceita, create/update)
- [X] T027 [US1] Store `sci-client-monorepo/apps/web/src/modules/saude/lib/consultas-store.ts` (list/get/create/update/delete, bloqueio UBS inativa)
- [X] T028 [US1] Facade `sci-client-monorepo/apps/web/src/modules/saude/api/consultas.ts`
- [X] T029 [P] [US1] Componente `sci-client-monorepo/apps/web/src/modules/saude/components/ConsultaSoapTabs.tsx`
- [X] T030 [P] [US1] Componentes `sci-client-monorepo/apps/web/src/modules/saude/components/ConsultaProcedimentosList.tsx` e `ConsultaReceitasList.tsx`
- [X] T031 [US1] Página `sci-client-monorepo/apps/web/src/modules/saude/pages/ConsultasListPage.tsx`
- [X] T032 [US1] Página `sci-client-monorepo/apps/web/src/modules/saude/pages/ConsultaFormPage.tsx` (create + edit, validação Zod, selects FK cidadão/profissional/UBS)
- [X] T033 [US1] Página `sci-client-monorepo/apps/web/src/modules/saude/pages/ConsultaDetailPage.tsx` (6 seções/abas, ações Editar)
- [X] T034 [US1] Registrar screens consultas em `sci-client-monorepo/apps/web/src/modules/shell/config/screens.ts` e overrides em `sci-client-monorepo/apps/web/src/modules/saude/index.tsx`
- [X] T035 [US1] Seed ~40 consultas sintéticas derivadas em `sci-client-monorepo/apps/web/src/modules/saude/data/seed.ts`

**Checkpoint**: MVP operacional — consulta CRUD funcional (US1 + US2).

---

## Phase 5: User Story 3 — Relatórios receitas e exames (Priority: P2)

**Goal**: Somente leitura — ~400 receitas agrupáveis; ~100 exames rotina/urgente, só médicos.

**Independent Test**: Filtrar receitas por médico/mês; confirmar exames sem enfermeiros solicitantes.

### Tests for User Story 3 ⚠️

- [X] T036 [P] [US3] Testes projeção receitas em `sci-client-monorepo/apps/web/src/modules/saude/api/__tests__/receitas-relatorio.test.ts` (~400, agrupamento)
- [X] T037 [P] [US3] Testes filtro exames só médicos em `sci-client-monorepo/apps/web/src/modules/saude/api/__tests__/exames-relatorio.test.ts` (CBO 225*, zero 2235*)

### Implementation for User Story 3

- [X] T038 [P] [US3] Schemas `sci-client-monorepo/apps/web/src/modules/saude/schemas/receita.schema.ts` e `exame.schema.ts` (projeções relatório)
- [X] T039 [US3] Facades `sci-client-monorepo/apps/web/src/modules/saude/api/receitas-relatorio.ts` e `exames-relatorio.ts`
- [X] T040 [US3] Seed ~400 linhas receita + ~100 exames em `sci-client-monorepo/apps/web/src/modules/saude/data/seed.ts` (14 meses, médicos only para exames)
- [X] T041 [P] [US3] Página `sci-client-monorepo/apps/web/src/modules/saude/pages/ReceitasRelatorioPage.tsx` (filtros, agrupamento, read-only)
- [X] T042 [P] [US3] Página `sci-client-monorepo/apps/web/src/modules/saude/pages/ExamesRelatorioPage.tsx` (badge rotina/urgente, read-only)
- [X] T043 [US3] Screens + overrides `saude-receitas-relatorio`, `saude-exames-relatorio` em `screens.ts` e `index.tsx`

**Checkpoint**: Relatórios demonstráveis para gestão.

---

## Phase 6: User Story 4 — Fila solicitações cidadão→UBS (Priority: P2)

**Goal**: Fila editável com status e observações, filtro por UBS.

**Independent Test**: Criar solicitação → alterar status → filtrar por UBS.

### Tests for User Story 4 ⚠️

- [X] T044 [P] [US4] Testes store solicitações em `sci-client-monorepo/apps/web/src/modules/saude/lib/__tests__/solicitacoes-store.test.ts`
- [X] T045 [P] [US4] Teste schema em `sci-client-monorepo/apps/web/src/modules/saude/schemas/__tests__/solicitacao.schema.test.ts`

### Implementation for User Story 4

- [X] T046 [US4] Schema `sci-client-monorepo/apps/web/src/modules/saude/schemas/solicitacao.schema.ts`
- [X] T047 [US4] Store `sci-client-monorepo/apps/web/src/modules/saude/lib/solicitacoes-store.ts`
- [X] T048 [US4] Facade `sci-client-monorepo/apps/web/src/modules/saude/api/solicitacoes.ts`
- [X] T049 [US4] Página `sci-client-monorepo/apps/web/src/modules/saude/pages/SolicitacoesPage.tsx` (CRUD inline/dialog, filtros UBS/status)
- [X] T050 [US4] Seed fila inicial em `sci-client-monorepo/apps/web/src/modules/saude/data/seed.ts`
- [X] T051 [US4] Screen + override `saude-solicitacoes` em `screens.ts` e `index.tsx`

**Checkpoint**: Fila operacional independente dos relatórios.

---

## Phase 7: User Story 5 — Validação pública `/validar` (Priority: P2)

**Goal**: Rota pública sem auth — validar código de receita.

**Independent Test**: Acessar `/validar` sem login; código seed válido vs inválido.

### Tests for User Story 5 ⚠️

- [X] T052 [P] [US5] Testes `sci-client-monorepo/apps/web/src/modules/saude/lib/__tests__/receita-signature.test.ts` (determinístico, válido, inválido, revogada)
- [X] T053 [P] [US5] Teste página pública em `sci-client-monorepo/apps/web/src/modules/saude/__tests__/ValidarReceitaPage.test.tsx`

### Implementation for User Story 5

- [X] T054 [US5] Implementar `sci-client-monorepo/apps/web/src/modules/saude/lib/receita-signature.ts` (`generateReceitaCodigo`, `validateReceitaCodigo`)
- [X] T055 [US5] Gerar `codigoValidacao` nos itens receita seed/form em `consultas-store.ts` / seed (integrar T054)
- [X] T056 [US5] Página `sci-client-monorepo/apps/web/src/modules/saude/pages/ValidarReceitaPage.tsx` (layout público, sem AppShell)
- [X] T057 [US5] Registrar rota pública `/validar` **fora** de `RequireAuth` em `sci-client-monorepo/apps/web/src/app/router.tsx`

**Checkpoint**: Validação pública funcional.

---

## Phase 8: User Story 6 — Controle interno (Priority: P2)

**Goal**: Indicadores por médico/UBS/mês; conferência com flags; tramitação integrada.

**Independent Test**: Dashboard filtra UBS; conferência altera status; Tramitar abre compose com draft saude.

### Tests for User Story 6 ⚠️

- [X] T058 [P] [US6] Testes `sci-client-monorepo/apps/web/src/modules/saude/lib/__tests__/conferencia-rules.test.ts`
- [X] T059 [P] [US6] Testes `sci-client-monorepo/apps/web/src/modules/saude/lib/__tests__/indicadores.test.ts` e `unidades-stats.test.ts`
- [X] T060 [P] [US6] Teste integração dashboard em `sci-client-monorepo/apps/web/src/modules/saude/__tests__/SaudeDashboardPage.test.tsx`

### Implementation for User Story 6

- [X] T061 [US6] Implementar `sci-client-monorepo/apps/web/src/modules/saude/lib/conferencia-rules.ts` (`detectInconsistencias`)
- [X] T062 [US6] Implementar `sci-client-monorepo/apps/web/src/modules/saude/lib/indicadores.ts` (agregações consultas/receitas/exames)
- [X] T063 [US6] Completar `sci-client-monorepo/apps/web/src/modules/saude/lib/unidades-stats.ts` com período custom
- [X] T064 [P] [US6] Componente `sci-client-monorepo/apps/web/src/modules/saude/components/SaudeIndicadoresCharts.tsx` (Nivo bar/line)
- [X] T065 [US6] Página `sci-client-monorepo/apps/web/src/modules/saude/pages/SaudeDashboardPage.tsx` (filtros UBS/médico/mês/período)
- [X] T066 [US6] Página `sci-client-monorepo/apps/web/src/modules/saude/pages/SaudeConferenciaPage.tsx` (flags, status pendente/conferido/pronto_envio, update via consultas API)
- [X] T067 [US6] Integrar `TramitarButton` em `ConsultaDetailPage.tsx` e `SolicitacoesPage.tsx` (`module="saude"`, snapshot JSON)
- [X] T068 [US6] Screens + overrides `saude-dashboard`, `saude-conferencia` em `screens.ts` e `index.tsx`
- [X] T069 [US6] Atalhos Saúde em `sci-client-monorepo/apps/web/src/modules/shell/lib/welcome-shortcuts.ts`

**Checkpoint**: Governança interna antes de export e-SUS.

---

## Phase 9: User Story 7 — Export e-SUS FAI (Priority: P3)

**Goal**: Exportar consulta conferida para JSON FAI compatível e-SUS.

**Independent Test**: Consulta completa → Exportar → JSON com headerTransport, cidadão, procedimentos; consulta incompleta → lista missing.

### Tests for User Story 7 ⚠️

- [X] T070 [P] [US7] Testes export snapshot em `sci-client-monorepo/apps/web/src/modules/saude/lib/__tests__/esus-export.test.ts`
- [X] T071 [P] [US7] Testes schema FAI em `sci-client-monorepo/apps/web/src/modules/saude/schemas/__tests__/esus-fai.schema.test.ts`

### Implementation for User Story 7

- [X] T072 [US7] Schema `sci-client-monorepo/apps/web/src/modules/saude/schemas/esus-fai.schema.ts` (conforme `contracts/esus-fai-export.md`)
- [X] T073 [US7] Mapper `sci-client-monorepo/apps/web/src/modules/saude/lib/esus-export.ts` (`exportConsultaToFai`, `validateConsultaExportReady`)
- [X] T074 [US7] Ação **Exportar e-SUS** em `ConsultaDetailPage.tsx` (preview/download JSON, erro se missing)
- [X] T075 [US7] Habilitar export apenas para consultas `pronto_envio` ou warning em conferência pendente (regra UX)

**Checkpoint**: Export FAI validável contratualmente.

---

## Phase 10: Polish & Cross-Cutting Concerns

**Purpose**: E2E, docs, validação final.

- [X] T076 [P] E2E leve jornadas em `sci-client-monorepo/apps/web/src/modules/saude/__tests__/saude.e2e.test.tsx` (consulta P1, validar, relatório exames)
- [X] T077 [P] Atualizar `sci-client-monorepo/apps/web/src/modules/shell/config/navigation-meta.ts` se metadados módulo saude necessários
- [X] T078 Executar cenários de `sci-docs-v2/specs/024-saude-atendimento-ubs/quickstart.md` e corrigir gaps
- [X] T079 [P] Remover artefatos de pesquisa `_schema.sql` e `_toc.txt` da raiz `ci-v2-workspace/` se ainda existirem
- [X] T080 Revisar copy PT-BR e licença `base` em todas telas saude (`screens.ts`, alertas)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)** → **Foundational (Phase 2)** → **US2 (Phase 3)** → **US1 (Phase 4)** → demais US em paralelo parcial
- **US3** depende de seed receitas/exames (consultas US1 ajuda)
- **US5** depende de `codigoValidacao` em receitas (US1)
- **US6** depende de consultas (US1) e stats (US3 seed)
- **US7** depende de US1 + US6 conferência

### User Story Dependencies

| Story | Depende de | Independente após |
|-------|------------|-------------------|
| US2 | Phase 2 | Cadastros seed |
| US1 | US2 | Consulta CRUD |
| US3 | US1 seed | Relatórios |
| US4 | Phase 2 + UBS US2 | Fila |
| US5 | US1 receitas | `/validar` |
| US6 | US1, US3 | Dashboard/conferência |
| US7 | US1, US6 | Export FAI |

### Parallel Opportunities

- Phase 1: T003 ∥ T004
- Phase 2: T005 ∥ T006 ∥ T007 ∥ T010
- US2: T011 ∥ T012 ∥ T013; T014 ∥ T015; T019 ∥ T020
- US1: T023 ∥ T024 ∥ T025; T029 ∥ T030
- US3: T036 ∥ T037; T041 ∥ T042
- US5: T052 ∥ T053
- US6: T058 ∥ T059 ∥ T060; T064 paralelo após T062
- US7: T070 ∥ T071
- Polish: T076 ∥ T077 ∥ T079

---

## Parallel Example: User Story 1

```bash
# Tests RED em paralelo:
npm test -- consulta.schema consultas-store ConsultasListPage

# Componentes em paralelo:
# ConsultaSoapTabs.tsx + ConsultaProcedimentosList.tsx + ConsultaReceitasList.tsx
```

---

## Implementation Strategy

### MVP First (US2 + US1)

1. Phase 1 Setup
2. Phase 2 Foundational
3. Phase 3 US2 (cadastros)
4. Phase 4 US1 (consultas)
5. **STOP** — demo CRUD consulta Careiro

### Incremental Delivery

1. US2 + US1 → MVP
2. + US3 relatórios → demo gestão
3. + US4 fila + US5 validar → canal cidadão
4. + US6 controle → governança
5. + US7 export → transição e-SUS

### Suggested MVP Scope

**T001–T035** (Setup + Foundational + US2 + US1) — consulta agregada operacional com 8 UBS Careiro.

---

## Notes

- Licença **`base`** em todas as telas — sem nova licença-árvore
- Dados 100% sintéticos — nunca importar backup e-SUS
- TDD: confirmar testes RED antes de GREEN em cada fase
- Total: **80 tasks** | US1: 13 | US2: 12 | US3: 8 | US4: 8 | US5: 6 | US6: 12 | US7: 6 | Setup+Foundation+Polish: 15

---

## Phase 11: Pós-implement (UX, navegação e licenças)

**Purpose**: Entregas após MVP implement — reorganização UX, design system e telas de licença mock.

- [X] T081 Reorganizar sidebar: seção **Saúde** separada de Administração/Gestão
- [X] T082 Quatro agrupamentos internos: **Atendimento**, **Cadastros**, **Acompanhamento**, **Controle** — cada um com dashboard dedicado
- [X] T083 Design system institucional: breadcrumb, KPI cards, botão criar, filtros, tabela, paginação (`SaudePageHeader`, `SaudeKpiGrid`, `SaudeFiltersBar`, `InstitutionalListLayout`)
- [X] T084 Design system detalhe: `CopyableField` + `SaudeDetailPageLayout` com ícone copiar em todo dado (`ConsultaDetailPage`)
- [X] T085 Tela **Insights IA** mock (licença Cedro) — 6 insights e-SUS/APS em `/saude/insights`
- [X] T086 Tela **Fiscalização** mock (licença Jatobá) — 7 achados em `/saude/fiscalizacao`
- [X] T087 Tela **Maturidade** mock (licença Carvalho) — 5 dimensões + ranking 8 UBS em `/saude/maturidade`
- [X] T088 Correções integração: UUID seed medicamentos, imports institucionais, constantes licença local

**Nota US7**: Export FAI (`esus-export.ts`) permanece **placeholder** (toast no detalhe) — adiado para feature futura.
