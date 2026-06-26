---
description: "Task list for tramitação SIGED + licenças mock (005-tramitacao-siged-licencas)"
---

# Tasks: Tramitação — Demandas SIGED e Licenças

**Input**: Design documents from `specs/005-tramitacao-siged-licencas/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Tests**: Opcionais — spec mock client-only; validação via `npm run build` + smoke manual ([quickstart.md](./quickstart.md)). Teste unitário opcional para `tramitacao-status.ts` (plan.md R10).

**Organization**: US1–US4 são P1; US5–US8 são P2; US9 é P3. Escopo **somente** `ci-client-v2` — `ci-api-v2` fora de escopo (FR-021).

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Pode executar em paralelo (arquivos diferentes, sem dependências pendentes)
- **[Story]**: User story da spec (US1–US9)
- Caminhos relativos à raiz do repositório `ci-v2/`

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Configuração de domínio e alertas — base para todas as telas de licença

- [X] T001 Confirmar leitura de `specs/005-tramitacao-siged-licencas/contracts/client-tramitacao-ui.md` e `contracts/mock-data-layout.md` antes de codificar
- [X] T002 [P] Adicionar `moduleLicenseConfig.tramitacao` em `ci-client-v2/packages/domain/src/lib/licenses.ts` conforme `contracts/mock-data-layout.md`
- [X] T003 [P] Registrar `tramitacao: '/tramitacao'` em `MODULE_PATHS` em `ci-client-v2/apps/web/src/modules/shell/lib/license-alerts.ts`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Tipos mock, telas de licença, navegação e status operacional — **bloqueia todas as user stories**

**⚠️ CRITICAL**: Nenhuma user story começa antes desta fase

- [X] T004 Estender tipos `ProcessoSigedSnapshot`, `DocumentoSigedSnapshot` e campo `origem: 'interna' | 'siged'` em `ci-client-v2/apps/web/src/modules/shell/data/tramitacao-mock.ts` conforme `data-model.md`
- [X] T005 Implementar `deriveOperationalStatus()` em `ci-client-v2/apps/web/src/modules/shell/lib/tramitacao-status.ts` conforme `data-model.md` transições operacionais
- [X] T006 Adicionar `tramitacao` ao array `modules` em `ci-client-v2/apps/web/src/modules/shell/config/license-screens.ts` para gerar `tramitacao-maturidade` e `tramitacao-insights`
- [X] T007 Adicionar screen `tramitacao-auditoria` em `ci-client-v2/apps/web/src/modules/shell/config/screens.ts` (colunas e ações espelhando `protocolo-auditoria`, módulo `tramitacao`)
- [X] T008 Atualizar `ci-client-v2/apps/web/src/modules/shell/config/navigation.ts` com `...licenseNav('tramitacao')` e item **Fiscalização** (`tramitacao-auditoria`)
- [X] T009 [P] Adicionar `maturityByModule.tramitacao` baseline em `ci-client-v2/apps/web/src/modules/shell/data/mock-data.ts` conforme `contracts/mock-data-layout.md`
- [X] T010 Garantir merge de `buildLicenseScreens()` com `screens.ts` em `ci-client-v2/apps/web/src/modules/shell/config/screens.ts` (ou ponto de composição existente) para rotas `/tramitacao/maturidade` e `/tramitacao/insights`

**Checkpoint**: Foundation ready — rotas de licença navegáveis; tipos SIGED definidos; status operacional extraível

---

## Phase 3: User Story 1 — Receber e distinguir demandas SIGED (Priority: P1) 🎯 MVP

**Goal**: Demandas SIGED visíveis na inbox com processo administrativo e documentos vinculados (mock Prefeitura de Manaus)

**Independent Test**: VS-001 e VS-002 em `quickstart.md` — badge SIGED em &lt; 5s; painel processo/documentos no detalhe

### Implementation for User Story 1

- [X] T011 [P] [US1] Adicionar fixtures `msg-sig-1`, `msg-sig-2`, `msg-sig-3` em `ci-client-v2/apps/web/src/modules/shell/data/tramitacao-mock.ts` conforme `contracts/mock-data-layout.md`
- [X] T012 [P] [US1] Marcar `msg-1`, `msg-2`, `msg-3` com `origem: 'interna'` em `ci-client-v2/apps/web/src/modules/shell/data/tramitacao-mock.ts`
- [X] T013 [US1] Renderizar badge **SIGED** (tooltip *SIGED — Prefeitura de Manaus*) nos cards da lista em `ci-client-v2/apps/web/src/modules/shell/components/mock/TramitacaoInboxPanel.tsx`
- [X] T014 [US1] Adicionar painel **Processo SIGED** no detalhe da demanda em `ci-client-v2/apps/web/src/modules/shell/components/mock/TramitacaoInboxPanel.tsx` quando `origem === 'siged'`
- [X] T015 [US1] Adicionar tabela **Documentos vinculados** com estado vazio em `ci-client-v2/apps/web/src/modules/shell/components/mock/TramitacaoInboxPanel.tsx`

**Checkpoint**: MVP — demandas SIGED distinguíveis e detalhadas sem API

---

## Phase 4: User Story 2 — Operar tramitação inter-setorial (Priority: P1)

**Goal**: Compor, responder, encaminhar e arquivar demandas com histórico e status operacional da Base

**Independent Test**: VS-003 em `quickstart.md` — pastas, encaminhamento, resposta, composição interna

### Implementation for User Story 2

- [X] T016 [US2] Exibir status operacional derivado via `deriveOperationalStatus()` na lista/detalhe em `ci-client-v2/apps/web/src/modules/shell/components/mock/TramitacaoInboxPanel.tsx`
- [X] T017 [US2] Garantir fluxo **Compor** cria demanda `origem: 'interna'` visível em enviadas/recebidas em `ci-client-v2/apps/web/src/modules/shell/components/mock/TramitacaoInboxPanel.tsx`
- [X] T018 [US2] Implementar **Responder** adicionando entrada `kind: 'resposta'` em `conversationHistory` em `ci-client-v2/apps/web/src/modules/shell/components/mock/TramitacaoInboxPanel.tsx`
- [X] T019 [US2] Implementar **Encaminhar** adicionando entrada `kind: 'encaminhamento'` em `forwardingHistory` em `ci-client-v2/apps/web/src/modules/shell/components/mock/TramitacaoInboxPanel.tsx`
- [X] T020 [US2] Implementar **Arquivar** movendo demanda para pasta `arquivadas` em `ci-client-v2/apps/web/src/modules/shell/components/mock/TramitacaoInboxPanel.tsx`
- [X] T021 [P] [US2] Estender `tramitacao-demandas` com `licenses: ['base', 'pau-brasil']` em `ci-client-v2/apps/web/src/modules/shell/config/screens.ts`

**Checkpoint**: Fluxo operacional Base completo na inbox

---

## Phase 5: User Story 3 — Dashboard consolidado (Priority: P1)

**Goal**: KPIs institucionais com segregação SIGED vs interna e filtro por setor

**Independent Test**: VS-004 em `quickstart.md` — cards, gráfico origem, filtro DEJUR

### Implementation for User Story 3

- [X] T022 [P] [US3] Estender `tramitacaoDashboardStats` com `sigedCount`, `internaCount`, `sigedPercent` em `ci-client-v2/apps/web/src/modules/shell/data/tramitacao-mock.ts`
- [X] T023 [P] [US3] Adicionar dataset `tramitacaoOrigemPorMes` em `ci-client-v2/apps/web/src/modules/shell/data/tramitacao-mock.ts`
- [X] T024 [US3] Adicionar gráfico SIGED vs Interna e filtro por setor no case `tramitacao` em `ci-client-v2/apps/web/src/modules/shell/components/mock/DashboardCharts.tsx`
- [X] T025 [US3] Atualizar stats cards de `tramitacao-dashboard` (incl. origem SIGED) em `ci-client-v2/apps/web/src/modules/shell/config/screens.ts`

**Checkpoint**: Dashboard reflete mix SIGED/interno e filtro setorial

---

## Phase 6: User Story 4 — Fiscalizar demandas com Jatobá (Priority: P1)

**Goal**: Painel Fiscalização com checagens de SLA e assinaturas SIGED; read-only sobre demandas

**Independent Test**: VS-005 em `quickstart.md` — conformidade ∈ 4 status; sheet rastreabilidade; demanda inalterada

### Implementation for User Story 4

- [X] T026 [P] [US4] Adicionar `mockTableRows['tramitacao-auditoria']` (≥ 3 linhas) em `ci-client-v2/apps/web/src/modules/shell/data/mock-data.ts`
- [X] T027 [P] [US4] Adicionar `jatobaProblems.tramitacao` (≥ 1 Não conforme) em `ci-client-v2/apps/web/src/modules/shell/data/mock-data.ts`
- [X] T028 [P] [US4] Adicionar traces `JAT-TRAM-SLA-001` e `JAT-TRAM-SIG-002` em `ci-client-v2/apps/web/src/modules/shell/data/traceability-mock.ts`
- [X] T029 [US4] Garantir resolução de traces tramitacao em `ci-client-v2/apps/web/src/modules/shell/lib/traceability.ts` (getProblemTrace)
- [X] T030 [US4] Validar renderização de `/tramitacao/auditoria` via `ScreenPage` + `MockDataTable` com colunas do contrato UI

**Checkpoint**: Jatobá operacional no módulo Tramitação

---

## Phase 7: User Story 5 — Consultar insights Cedro (Priority: P2)

**Goal**: Insights read-only sobre gargalos e tendência SIGED

**Independent Test**: VS-006 em `quickstart.md` — badge Somente leitura; sheet *De onde veio este insight*

### Implementation for User Story 5

- [X] T031 [P] [US5] Adicionar `cedroInsightsByModule.tramitacao` (`tram-ins-001`, `tram-ins-002`) em `ci-client-v2/apps/web/src/modules/shell/data/mock-data.ts`
- [X] T032 [P] [US5] Adicionar traces Cedro em `ci-client-v2/apps/web/src/modules/shell/data/traceability-mock.ts` para `tram-ins-001` e `tram-ins-002`
- [X] T033 [US5] Validar tela `/tramitacao/insights` lista insights com impacto e badge **Somente leitura** (layout insights existente)

**Checkpoint**: Cedro consultivo sem alterar demandas

---

## Phase 8: User Story 6 — Avaliar maturidade Carvalho (Priority: P2)

**Goal**: Score híbrido por eixo com contribuição Jatobá e plano de ação rastreável

**Independent Test**: VS-007 em `quickstart.md` — eixos CI/GOV/TI; sheet *Como calculamos este score*

### Implementation for User Story 6

- [X] T034 [P] [US6] Adicionar trace `carvalho-tram-001` em `ci-client-v2/apps/web/src/modules/shell/data/traceability-mock.ts`
- [X] T035 [US6] Garantir `getMaturityTrace('tramitacao', ...)` em `ci-client-v2/apps/web/src/modules/shell/lib/traceability.ts`
- [X] T036 [US6] Validar tela `/tramitacao/maturidade` exibe stats de `maturityByModule.tramitacao` e botão explicação score

**Checkpoint**: Carvalho macro do módulo Tramitação

---

## Phase 9: User Story 7 — Produzir documentos com Pau-Brasil (Priority: P2)

**Goal**: Modelos ofício/memorando/despacho na composição e alerta normativo de prazo

**Independent Test**: VS-008 em `quickstart.md` — preset Pau-Brasil no Compor; alerta não substitui prazo Base

### Implementation for User Story 7

- [X] T037 [US7] Adicionar botões **Usar modelo — Ofício/Memorando/Despacho** no sheet Compor via `MockInlineActionButton` e `getLicenseActionPreset` em `ci-client-v2/apps/web/src/modules/shell/components/mock/TramitacaoInboxPanel.tsx`
- [X] T038 [US7] Adicionar card de alerta normativo de prazo de tramitação (Pau-Brasil) no sheet Compor em `ci-client-v2/apps/web/src/modules/shell/components/mock/TramitacaoInboxPanel.tsx`

**Checkpoint**: Pau-Brasil contextual na composição

---

## Phase 10: User Story 8 — Alertas de licença e rastreabilidade (Priority: P2)

**Goal**: Barra de alertas na inbox com atalhos para telas de licença; copy canônica nos sheets

**Independent Test**: VS-009 em `quickstart.md` — barra ativa; sem chips de licença na tabela

### Implementation for User Story 8

- [X] T039 [US8] Renderizar `ListLicenseAlertBar` no topo de `/tramitacao/demandas` quando `getModuleWorstStatus('tramitacao') !== 'ok'` em `ci-client-v2/apps/web/src/modules/shell/components/mock/TramitacaoInboxPanel.tsx`
- [X] T040 [US8] Auditar títulos de sheets de rastreabilidade tramitacao contra `ci-client-v2/apps/web/src/modules/shell/lib/traceability-copy.ts` e `.cursor/docs/regras-plataforma.md` §1.7

**Checkpoint**: Paridade de alertas com outros módulos mock

---

## Phase 11: User Story 9 — Ações de licença no detalhe (Priority: P3)

**Goal**: Atalhos contextuais Jatobá e Cedro no detalhe da demanda; ocultar quando filtro não aplica

**Independent Test**: VS-009 passo final — fiscalizar/consultar IA no detalhe sem sair da inbox

### Implementation for User Story 9

- [X] T041 [P] [US9] Integrar `JatobaRecordCheck` com `module="tramitacao"` no painel de detalhe em `ci-client-v2/apps/web/src/modules/shell/components/mock/TramitacaoInboxPanel.tsx`
- [X] T042 [P] [US9] Integrar `CedroModulePanel` read-only no painel de detalhe em `ci-client-v2/apps/web/src/modules/shell/components/mock/TramitacaoInboxPanel.tsx`
- [X] T043 [US9] Respeitar `LicenseFilter` — ocultar painéis de licença não aplicáveis (nunca `disabled`) em `ci-client-v2/apps/web/src/modules/shell/components/mock/TramitacaoInboxPanel.tsx`

**Checkpoint**: Demo ponta a ponta na inbox

---

## Phase 12: Polish & Cross-Cutting Concerns

**Purpose**: Build, testes opcionais e validação final

- [X] T044 [P] Adicionar testes unitários opcionais para `deriveOperationalStatus` em `ci-client-v2/apps/web/src/modules/shell/lib/tramitacao-status.test.ts`
- [X] T045 Executar `npm run build` em `ci-client-v2` e corrigir erros de tipo
- [X] T046 Executar checklist VS-001–VS-010 em `specs/005-tramitacao-siged-licencas/quickstart.md` e §8 de `.cursor/docs/regras-plataforma.md`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Sem dependências — iniciar imediatamente
- **Foundational (Phase 2)**: Depende de Phase 1 — **BLOQUEIA** todas as user stories
- **User Stories (Phase 3–11)**: Dependem de Phase 2 completa
  - P1 (US1–US4) recomendado antes de P2/P3
  - US5–US8 podem paralelizar após US4 (arquivos mock distintos)
- **Polish (Phase 12)**: Depende das user stories desejadas para release

### User Story Dependencies

| Story | Depende de | Notas |
|-------|------------|-------|
| US1 SIGED | Foundational | MVP isolável |
| US2 Inbox ops | Foundational; beneficia US1 | Status + ações |
| US3 Dashboard | Foundational; beneficia US1 fixtures | Dados SIGED/interna |
| US4 Jatobá | Foundational | Independente da inbox |
| US5 Cedro | Foundational | Independente |
| US6 Carvalho | Foundational; beneficia US4 indicadores | |
| US7 Pau-Brasil | US2 Compor sheet | |
| US8 Alertas | US4–US6 dados mock | Barra precisa problems/insights |
| US9 Detalhe licenças | US4–US5 painéis | P3 refinamento |

### Parallel Opportunities

- **Phase 1**: T002 ∥ T003
- **Phase 2**: T009 ∥ T004–T008 (após T004 tipos)
- **US1**: T011 ∥ T012; depois T013–T015 sequencial (mesmo arquivo UI)
- **US3**: T022 ∥ T023; depois T024–T025
- **US4**: T026 ∥ T027 ∥ T028
- **US5**: T031 ∥ T032
- **US9**: T041 ∥ T042
- **Polish**: T044 ∥ T045 (após implementação)

---

## Parallel Example: User Story 4

```bash
# Mock data em paralelo:
Task T026: mockTableRows tramitacao-auditoria em mock-data.ts
Task T027: jatobaProblems.tramitacao em mock-data.ts
Task T028: traces JAT-TRAM-* em traceability-mock.ts

# Depois sequencial:
Task T029: traceability.ts getters
Task T030: validar tela auditoria
```

---

## Parallel Example: User Story 1 (MVP)

```bash
# Fixtures em paralelo:
Task T011: msg-sig-* em tramitacao-mock.ts
Task T012: origem interna em msg-1..3

# UI sequencial (TramitacaoInboxPanel.tsx):
Task T013 → T014 → T015
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational
3. Complete Phase 3: User Story 1 (SIGED na inbox)
4. **STOP and VALIDATE**: VS-001, VS-002
5. Demo para stakeholders Manaus

### Entrega P1 completa (recomendado antes de demo institucional)

1. Setup + Foundational
2. US1 → US2 → US3 → US4
3. Validar VS-001–VS-005
4. Adicionar US5–US8 para demo licenças completa

### Incremental Delivery

| Incremento | Fases | Valor |
|------------|-------|-------|
| MVP SIGED | 1–3 | Badge + metadados processo/doc |
| Operação | 4 | Tramitação inter-setorial |
| Gestão | 5 | Dashboard consolidado |
| Conformidade | 6 | Jatobá |
| Estratégia | 7–8 | Cedro + Carvalho |
| Documentos | 9 | Pau-Brasil |
| UX licenças | 10–11 | Alertas + detalhe |
| Release | 12 | Build + quickstart |

### Parallel Team Strategy

Com 2+ desenvolvedores após Foundational:

- **Dev A**: US1 + US2 (TramitacaoInboxPanel.tsx)
- **Dev B**: US3 + US4 (DashboardCharts + mock-data auditoria)
- **Dev C**: US5 + US6 + US8 (mock-data insights/maturidade + alert bar)

---

## Notes

- **Não alterar** `ci-api-v2/`, rotas `/protocolo/*`, nem `modules/ouvidoria/`
- Paleta Mint em badges SIGED e CTAs — rule `mint-palette`
- Skills: `ui-ux-pro-max` para inbox/SIGED; `vite-react-best-practices` para rotas lazy
- Commit sugerido após cada checkpoint de user story
- Total: **46 tasks** — 3 setup, 7 foundational, 5+6+4+5+3+3+2+2+3+3 polish por story
