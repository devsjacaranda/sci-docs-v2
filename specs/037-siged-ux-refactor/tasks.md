---
description: "Task list for SIGED UX Refactor (037-siged-ux-refactor)"
---

# Tasks: Refactor UX do SIGED — Diretorias Agrupadas, Home e Licenças Jatobá/Cedro

**Input**: Design documents from `civ2-docs/specs/037-siged-ux-refactor/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Tests**: **Obrigatórios** — TDD (Constitution II + plan.md + `contracts/test-strategy.md`): unitário, contrato, componente (Vitest/RTL), integração com mocks. **Sem Postgres de teste dedicado**.

**Organization**: 4 user stories (US1–US4). Caminhos relativos à raiz `ci-v2/`. Módulo SIGED **já existe** (portal read-only) — tasks **estendem** com UX hierárquica, Home, fiscalização e insights dedicados.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Pode executar em paralelo (arquivos diferentes, sem dependências pendentes)
- **[Story]**: User story da spec (US1–US4)

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Fixtures, MSW e esqueleto de rotas compartilhadas

- [X] T001 [P] Criar fixture `ci-api-v2/src/modules/siged/test/fixtures/siged-hierarquia-sample.json` — árvore 3 níveis (topo → dept → sub-dept) com órgãos ativos/inativos
- [X] T002 [P] Criar fixtures `ci-api-v2/src/modules/siged/test/fixtures/siged-home-response.json` e `siged-home-degraded.json` conforme `contracts/rest-api-siged-ux.md`
- [X] T003 [P] Criar fixtures `ci-api-v2/src/modules/siged-fiscalizacao/test/fixtures/siged-fiscalizacao-run-completed.json` e `ci-api-v2/src/modules/siged-insights/test/fixtures/siged-insights-batch-completed.json`
- [X] T004 [P] Criar fixtures client `ci-client-v2/apps/web/src/modules/siged/fixtures/hierarquia-sample.json`, `home-response.json`, `fiscalizacao-panel.json`, `insights-batch.json`
- [X] T005 [P] Criar handlers MSW `ci-client-v2/apps/web/src/modules/siged/__tests__/handlers/siged-ux.handlers.ts` e registrar em setup de testes do módulo siged
- [X] T006 [P] Estender `ci-client-v2/apps/web/src/modules/siged/constants/siged-routes.ts` com `diretorias`, `orgao(orgaoId)`, `auditoria`, `insights` (rotas definidas; páginas stub até cada fase)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Schema Prisma histórico + coleta passiva + shell/navigation base — **bloqueia US2–US4; US1 pode iniciar após Phase 1**

**⚠️ CRITICAL**: Migrations e recorder devem estar GREEN antes de Home/Fiscalização/Insights

### Tests first (TDD — RED)

- [ ] T007 [P] Escrever testes (RED) `record-siged-snapshots.use-case.spec.ts` em `ci-api-v2/src/modules/siged/use-cases/record-siged-snapshots.use-case.spec.ts` — upsert idempotente `SigedOrgaoDailyMetric` + `SigedProtocoloObservacao`; falha de persistência não propaga erro
- [ ] T008 [P] Escrever testes (RED) `siged-home.schemas.spec.ts` em `ci-api-v2/src/modules/siged/siged-home.schemas.spec.ts` — parse `SigedHomeDto` conforme contrato REST

### Schema & migrations

- [ ] T009 Estender `ci-api-v2/prisma/schema/siged.prisma` — enum `SigedMetricSource`; models `SigedOrgaoDailyMetric`, `SigedProtocoloObservacao`; relação `Tenant`
- [ ] T010 [P] Criar `ci-api-v2/prisma/schema/siged-fiscalizacao.prisma` — Run/Result/Check/Finding/Question* espelhando `gabinete-fiscalizacao.prisma` com `siged_protocolo` e `SigedFiscalizacaoSlaConfig`
- [ ] T011 [P] Criar `ci-api-v2/prisma/schema/siged-insights.prisma` — Batch/Insight/Evidence espelhando `gabinete-insights.prisma`
- [ ] T012 Gerar migration em `ci-api-v2/prisma/migrations/` (history + fiscalizacao + insights); aplicar localmente; atualizar `tenant.prisma` relations se necessário

### Implementation for Foundational

- [ ] T013 [P] Implementar `ci-api-v2/src/modules/siged/repository/siged-snapshot.repository.ts` — upsert métricas diárias e observações por protocolo (GREEN T007)
- [ ] T014 Implementar `ci-api-v2/src/modules/siged/use-cases/record-siged-snapshots.use-case.ts` — cálculo `daysInCurrentOrgao`, `stalledProtocolCount`; retenção 90 dias (purge job ou delete on write)
- [ ] T015 Integrar coleta fire-and-forget em `ci-api-v2/src/modules/siged/use-cases/list-siged-protocolos.use-case.ts` e `list-siged-tramitacoes.use-case.ts` via `RecordSigedSnapshotsUseCase`
- [ ] T016 [P] Criar `ci-api-v2/src/modules/siged/siged-home.schemas.ts` com DTOs Zod (`SigedHomeDto`, post-it, licenseAlerts) (GREEN T008)
- [ ] T017 [P] Registrar módulos vazios `ci-api-v2/src/modules/siged-fiscalizacao/siged-fiscalizacao.module.ts` e `ci-api-v2/src/modules/siged-insights/siged-insights.module.ts`; importar em `ci-api-v2/src/app.module.ts`
- [ ] T018 [P] Adicionar screenIds em `ci-client-v2/apps/web/src/modules/shell/config/screens.ts` — `siged-home`, `siged-diretorias`, `siged-protocolos`, `siged-auditoria`, `siged-insights` (paths conforme `contracts/client-siged-ux-ui.md`)
- [ ] T019 Atualizar `ci-client-v2/apps/web/src/modules/shell/config/navigation.ts` — grupo SIGED com 4 itens (Início, Diretorias, Fiscalização, Insights IA)
- [ ] T020 [P] Atualizar catálogo `ci-api-v2/src/modules/tela-permissao/test/fixtures/screen-catalog.json` e `ci-api-v2/src/common/constants/screens.ts` com novas telas SIGED

**Checkpoint**: Migration aplicada; recorder GREEN; shell/navigation preparado; rotas stub registradas

---

## Phase 3: User Story 1 — Diretorias agrupadas + drill-down (Priority: P1) 🎯 MVP

**Goal**: Substituir grade achatada por diretorias de topo + drill-down recursivo até protocolos

**Independent Test**: Abrir `/siged/diretorias` → só cards de topo; drill-down com breadcrumb; leaf → lista de protocolos; busca escopada ao nível atual (`quickstart.md` §1)

### Tests for User Story 1 (TDD — RED first)

- [X] T021 [P] [US1] Escrever testes (RED) `ci-client-v2/apps/web/src/modules/siged/utils/__tests__/departamentos-tree.test.ts` — `listTopLevelOrgaos`, `getDirectChildren`, `isLeafOrgao`, `findDepartamentoWithAncestors` com fixture hierarquia 3 níveis
- [X] T022 [P] [US1] Atualizar testes (RED) `ci-client-v2/apps/web/src/modules/shell/config/__tests__/navigation.siged.test.ts` — incluir `siged-diretorias`; SIGED permanece fora do menu Gabinete
- [X] T023 [P] [US1] Escrever testes (RED) `ci-client-v2/apps/web/src/modules/siged/pages/__tests__/siged-orgao-drilldown-page.test.tsx` — breadcrumb, CTA "Ver protocolos desta diretoria", navegação para filhos

### Implementation for User Story 1

- [X] T024 [P] [US1] Refatorar `ci-client-v2/apps/web/src/modules/siged/utils/departamentos-tree.ts` — adicionar `listTopLevelOrgaos`, `getDirectChildren`, `isLeafOrgao`; manter helpers existentes; deprecar uso de `listDiretoriasCards` achatado na página topo (GREEN T021)
- [X] T025 [US1] Refatorar `ci-client-v2/apps/web/src/modules/siged/pages/siged-diretorias-page.tsx` — consumir só `listTopLevelOrgaos`; subtítulo/copy hierárquico; rota `/siged/diretorias`
- [X] T026 [US1] Refatorar `ci-client-v2/apps/web/src/modules/siged/components/siged-diretorias-grid.tsx` — navegar para `SIGED_ROUTES.orgao(id)` se tem filhos; para `SIGED_ROUTES.protocolos(id)` se leaf; busca escopada via prop `nodes`
- [X] T027 [US1] Criar `ci-client-v2/apps/web/src/modules/siged/pages/siged-orgao-drilldown-page.tsx` — filhos diretos + banner "Ver protocolos desta diretoria" quando aplicável (FR-009)
- [X] T028 [US1] Atualizar `ci-client-v2/apps/web/src/modules/siged/components/siged-breadcrumb.tsx` e consumo em drill-down/protocolos — path `SIGED › … › Diretoria › Protocolos`
- [X] T029 [US1] Atualizar `ci-client-v2/apps/web/src/modules/siged/siged-routes.tsx` — `/siged/diretorias`, `/siged/diretorias/:orgaoId`, redirect temporário `/siged` → `/siged/diretorias` até US2; manter rotas protocolo existentes
- [X] T030 [US1] Atualizar `ci-client-v2/apps/web/src/app/router.tsx` se lazy imports do módulo siged exigirem novos chunks para drill-down
- [X] T031 [US1] GREEN testes T021–T023; validar regressão filtros/paginação/export em `siged-protocolos-page.tsx` inalterados

**Checkpoint**: MVP navegável — hierarquia SIGED clara sem Home/licenças ainda

---

## Phase 4: User Story 2 — Home com post-its (Priority: P2)

**Goal**: `/siged` exibe Home com KPIs + resumo Cedro + degradação graciosa se SIGED live indisponível

**Independent Test**: Abrir `/siged` → post-its + CTA "Ver diretorias"; API `GET /siged/home` conforme contrato (`quickstart.md` §2)

**Depends on**: Phase 2 (snapshots + schemas)

### Tests for User Story 2 (TDD — RED first)

- [ ] T032 [P] [US2] Escrever testes (RED) `ci-api-v2/src/modules/siged/use-cases/get-siged-home.use-case.spec.ts` — KPIs from snapshots; post-it empty Cedro; `sigedLiveAvailable: false`
- [ ] T033 [P] [US2] Escrever testes (RED) `ci-client-v2/apps/web/src/modules/siged/api/__tests__/siged-home-mappers.test.ts` — map post-its, emptyReason, degraded banner
- [ ] T034 [P] [US2] Escrever testes (RED) `ci-client-v2/apps/web/src/modules/siged/pages/__tests__/siged-home-page.test.tsx` — render grid, CTA diretorias, sem edição manual

### Implementation for User Story 2

- [ ] T035 [US2] Implementar `ci-api-v2/src/modules/siged/use-cases/get-siged-home.use-case.ts` — agrega métricas locais + últimos insights Cedro (stub vazio OK até US4); probe live via config SIGED (GREEN T032)
- [ ] T036 [US2] Adicionar `GET /siged/home` em `ci-api-v2/src/modules/siged/siged-portal.controller.ts` com `@RequireModulo('gabinete')`
- [ ] T037 [P] [US2] Criar `ci-client-v2/apps/web/src/modules/siged/api/siged-home.service.ts` e `ci-client-v2/apps/web/src/modules/siged/api/siged-home-mappers.ts` (GREEN T033)
- [ ] T038 [P] [US2] Criar hook `ci-client-v2/apps/web/src/modules/siged/hooks/use-siged-home.ts`
- [ ] T039 [US2] Criar `ci-client-v2/apps/web/src/modules/siged/components/siged-post-it-grid.tsx` — layout post-it Mint, somente leitura, links para insights/fiscalização
- [ ] T040 [US2] Criar `ci-client-v2/apps/web/src/modules/siged/pages/siged-home-page.tsx` (GREEN T034)
- [ ] T041 [US2] Atualizar `ci-client-v2/apps/web/src/modules/siged/siged-routes.tsx` — index `/siged` → `SigedHomePage`; remover redirect temporário para diretorias
- [ ] T042 [US2] Atualizar `screens.ts` entry `siged-home` — `type: 'dashboard'`, descrição Home post-its

**Checkpoint**: Porta de entrada SIGED funcional com KPIs locais

---

## Phase 5: User Story 3 — Fiscalização Jatobá dedicada (Priority: P3)

**Goal**: Painel `/siged/auditoria` com regras TRM-001..003, trace sheets, questionário somente interno

**Independent Test**: Fiscalizar → achados ∈ {Conforme, Não conforme, Parcial, Pendente}; trace "Por que esta checagem deu este resultado" (`quickstart.md` §3)

**Depends on**: Phase 2 (schema fiscalizacao + snapshots)

### Tests for User Story 3 (TDD — RED first)

- [ ] T043 [P] [US3] Escrever testes (RED) `ci-api-v2/src/modules/siged-fiscalizacao/lib/checks/tramitacao-sla.rules.spec.ts` — JAT-SIG-TRM-001 (>2 dias úteis)
- [ ] T044 [P] [US3] Escrever testes (RED) `ci-api-v2/src/modules/siged-fiscalizacao/lib/checks/stalled-orgao.rules.spec.ts` — JAT-SIG-TRM-002 (>5 dias)
- [ ] T045 [P] [US3] Escrever testes (RED) `ci-api-v2/src/modules/siged-fiscalizacao/lib/checks/no-movement.rules.spec.ts` — JAT-SIG-TRM-003 → Pendente
- [ ] T046 [P] [US3] Escrever testes (RED) `ci-api-v2/src/modules/siged-fiscalizacao/test/use-cases/run-fiscalizacao.use-case.spec.ts` — amostra ≤500, `dataSourceSummary`, persist run
- [ ] T047 [P] [US3] Escrever testes (RED) `ci-api-v2/src/modules/siged-fiscalizacao/test/use-cases/get-fiscalizacao-panel.use-case.spec.ts` — panel shape compatível `FiscalizacaoPanel`

### Implementation for User Story 3 — API

- [ ] T048 [P] [US3] Implementar regras em `ci-api-v2/src/modules/siged-fiscalizacao/lib/checks/tramitacao-sla.rules.ts`, `stalled-orgao.rules.ts`, `no-movement.rules.ts` (GREEN T043–T045)
- [ ] T049 [US3] Criar `ci-api-v2/src/modules/siged-fiscalizacao/lib/run-checks-for-protocolo.ts` — orquestra checks; `siged-fiscalizacao.types.ts` + `CHECK_LABEL`/`RULE_DESCRIPTION`
- [ ] T050 [P] [US3] Criar repositories em `ci-api-v2/src/modules/siged-fiscalizacao/repository/` — persistence + query + `load-protocolos-for-fiscalizacao.repository.ts` (snapshots + amostra live)
- [ ] T051 [US3] Implementar use-cases `run-fiscalizacao.use-case.ts`, `get-fiscalizacao-panel.use-case.ts`, `get-finding-trace.use-case.ts`, `get-check-trace.use-case.ts` (GREEN T046–T047)
- [ ] T052 [P] [US3] Implementar question bank use-cases espelhando `gabinete-fiscalizacao` — `allowExternal: false` em schemas
- [ ] T053 [US3] Criar `ci-api-v2/src/modules/siged-fiscalizacao/siged-fiscalizacao.schemas.ts` e `siged-fiscalizacao.controller.ts` — prefixo `/siged/fiscalizacao`, `@RequireLicenca('jatoba')` conforme `contracts/rest-api-siged-ux.md`
- [ ] T054 [US3] Wire completo `ci-api-v2/src/modules/siged-fiscalizacao/siged-fiscalizacao.module.ts`

### Implementation for User Story 3 — Client

- [ ] T055 [P] [US3] Criar `ci-client-v2/apps/web/src/modules/siged/api/fiscalizacao.ts` e `fiscalizacao-mappers.ts` espelhando `gabinete/api/fiscalizacao.ts`
- [ ] T056 [US3] Criar `ci-client-v2/apps/web/src/modules/siged/pages/siged-auditoria-page.tsx` — reutilizar `FiscalizacaoPanel`, `QuestionBankPanel`, `QuestionnaireDialog`, `FiscalizacaoTraceSheet`; copy SIGED; badge **Somente leitura**
- [ ] T057 [US3] Registrar rota `/siged/auditoria` em `ci-client-v2/apps/web/src/modules/siged/siged-routes.tsx`

**Checkpoint**: Fiscalização SIGED operacional; achados canônicos; dados SIGED inalterados

---

## Phase 6: User Story 4 — Insights Cedro dedicados (Priority: P4)

**Goal**: Painel `/siged/insights` com volume, tempo médio, gargalos; geração *Consultar IA* read-only

**Independent Test**: Gerar insights → badge Somente leitura; trace "De onde veio este insight"; post-it Home linka insight (`quickstart.md` §4)

**Depends on**: Phase 2 (schema insights + snapshots); integração Home (US2) para post-its Cedro

### Tests for User Story 4 (TDD — RED first)

- [ ] T058 [P] [US4] Escrever testes (RED) `ci-api-v2/src/modules/siged-insights/lib/aggregation/volume-by-orgao.rules.spec.ts` — slug `siged_volume_by_orgao`, MIN_RECORDS
- [ ] T059 [P] [US4] Escrever testes (RED) `ci-api-v2/src/modules/siged-insights/lib/aggregation/avg-tramitacao.rules.spec.ts` — slug `siged_avg_tramitacao_days`
- [ ] T060 [P] [US4] Escrever testes (RED) `ci-api-v2/src/modules/siged-insights/lib/aggregation/stalled-orgaos.rules.spec.ts` e `orgao-comparison.rules.spec.ts`
- [ ] T061 [P] [US4] Escrever testes (RED) `ci-api-v2/src/modules/siged-insights/test/use-cases/generate-insights.use-case.spec.ts` — throttle 429, emptyReason
- [ ] T062 [P] [US4] Escrever testes (RED) `ci-api-v2/src/modules/siged-insights/test/use-cases/list-latest-insights.use-case.spec.ts`

### Implementation for User Story 4 — API

- [ ] T063 [P] [US4] Implementar regras em `ci-api-v2/src/modules/siged-insights/lib/aggregation/*.rules.ts` + `index.ts` `aggregateSigedInsights` (GREEN T058–T060)
- [ ] T064 [US4] Criar `ci-api-v2/src/modules/siged-insights/repository/load-siged-analysis-data.repository.ts` — lê snapshots + observações (janela 90d)
- [ ] T065 [US4] Implementar use-cases `generate-insights.use-case.ts`, `list-latest-insights.use-case.ts`, `list-insight-batches.use-case.ts`, `get-insight-batch-detail.use-case.ts`, `get-insight-trace.use-case.ts` (GREEN T061–T062)
- [ ] T066 [US4] Criar `ci-api-v2/src/modules/siged-insights/siged-insights.schemas.ts`, `siged-insights.mapper.ts`, `siged-insights.controller.ts` — prefixo `/siged/insights`, `@RequireLicenca('cedro')`
- [ ] T067 [US4] Wire `ci-api-v2/src/modules/siged-insights/siged-insights.module.ts`; opcional job diário espelhando `gabinete-insights/jobs/`

### Implementation for User Story 4 — Client

- [ ] T068 [P] [US4] Criar `ci-client-v2/apps/web/src/modules/siged/api/insights.ts` e `insights-mappers.ts` espelhando Gabinete
- [ ] T069 [US4] Criar `ci-client-v2/apps/web/src/modules/siged/pages/siged-insights-page.tsx` — reutilizar `@/modules/shared/components/cedro`; `InsightTraceSheet` resolve path protocolo SIGED
- [ ] T070 [US4] Registrar rota `/siged/insights` em `ci-client-v2/apps/web/src/modules/siged/siged-routes.tsx`
- [ ] T071 [US4] Conectar `get-siged-home.use-case.ts` a insights reais (substituir stub US2) — post-its Cedro top 3 impacto
- [ ] T072 [US4] Atualizar `SigedPostItGrid` — click insight → `/siged/insights` com foco/highlight opcional

**Checkpoint**: Insights SIGED end-to-end; Home exibe resumo Cedro

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Alertas de licença, contratos, regressão Controle Interno, validação quickstart

- [ ] T073 [P] Implementar `ci-client-v2/apps/web/src/modules/siged/lib/siged-license-alerts.ts` + integrar `ListLicenseAlertBar` em `siged-home-page.tsx`, `siged-diretorias-page.tsx`, `siged-orgao-drilldown-page.tsx`, `siged-protocolos-page.tsx` (FR-023, FR-024)
- [ ] T074 [P] Escrever teste contrato (RED→GREEN) `ci-api-v2/src/modules/siged/test/siged-home.contract.spec.ts` contra fixture T002
- [ ] T075 [P] Escrever teste contrato `ci-api-v2/src/modules/siged-fiscalizacao/test/siged-fiscalizacao.contract.spec.ts` e `ci-api-v2/src/modules/siged-insights/test/siged-insights.contract.spec.ts`
- [ ] T076 Validar regressão `SigedControleInternoForm` inalterado em `ci-client-v2/apps/web/src/modules/siged/pages/siged-protocolo-detail-page.tsx` — teste existente ou snapshot mínimo
- [ ] T077 [P] Atualizar exports `ci-client-v2/apps/web/src/modules/siged/index.ts` — novas páginas/hooks
- [ ] T078 Executar validação manual `civ2-docs/specs/037-siged-ux-refactor/quickstart.md` §1–6; corrigir gaps encontrados
- [ ] T079 [P] Atualizar testes MSW T005 com handlers completos fiscalização/insights/home

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: Sem dependências — iniciar imediatamente
- **Phase 2 (Foundational)**: Depende de Phase 1 — **bloqueia US2, US3, US4**
- **Phase 3 (US1)**: Depende de Phase 1 (T006 rotas); **não** exige Phase 2 completa
- **Phase 4 (US2)**: Depende de Phase 2
- **Phase 5 (US3)**: Depende de Phase 2
- **Phase 6 (US4)**: Depende de Phase 2; integração Home (T071) depois de US2+US4 API
- **Phase 7 (Polish)**: Depende das user stories desejadas entregues

### User Story Dependencies

| Story | Pode iniciar após | Depende de outras stories |
| --- | --- | --- |
| **US1** (P1) | Phase 1 | Nenhuma — **MVP** |
| **US2** (P2) | Phase 2 | US1 recomendado (rotas diretorias estáveis) |
| **US3** (P3) | Phase 2 | Snapshots populados ajudam; funcional sem US2/US4 |
| **US4** (P4) | Phase 2 | T071 integra Home (US2) após API insights GREEN |

### Within Each User Story

1. Tests RED
2. API/domain GREEN
3. Client GREEN
4. Checkpoint quickstart da story

### Parallel Opportunities

**Phase 1**: T001–T006 todos [P]

**Phase 2**: T007–T008 ∥ T009–T011; após T012: T013–T020 largamente [P]

**US1**: T021–T023 ∥; T024–T026 ∥ após T024

**US3 API**: T043–T045 ∥; T048–T050 ∥ após T049

**US4 API**: T058–T060 ∥

**Cross-team**: Após Phase 2, US3 e US4 API podem rodar em paralelo; US1 client pode avançar em paralelo com Phase 2 migrations

---

## Parallel Example: User Story 1

```bash
# Tests RED em paralelo:
T021 departamentos-tree.test.ts
T022 navigation.siged.test.ts
T023 siged-orgao-drilldown-page.test.tsx

# Implementação paralela após T024:
T026 siged-orgao-drilldown-page.tsx
T027 siged-diretorias-grid.tsx (coordenar mesma PR)
```

---

## Parallel Example: User Story 3 + 4 (API)

```bash
# Após Phase 2 completa, dois devs:
Dev A: T043–T054 siged-fiscalizacao
Dev B: T058–T067 siged-insights
# Client sequencial ou paralelo T055–T057 vs T068–T070
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Phase 1: Setup
2. Phase 3: US1 (drill-down) — **ignorar Phase 2 se aceitar Home/fiscalização depois**
3. **VALIDAR**: `quickstart.md` §1 + testes tree/navigation
4. Demo navegação hierárquica

### Incremental Delivery (recomendado)

1. Setup + **US1** → MVP navegação
2. **Phase 2** + **US2** → Home + snapshots
3. **US3** → Fiscalização + alert bar parcial
4. **US4** + T071 → Insights + post-its Cedro completos
5. **Phase 7** → polish + contratos

### Suggested MVP Scope

**User Story 1 (P1)** — 11 tasks (T021–T031) após Setup T001–T006: entrega valor imediato sem migrations.

---

## Notes

- `[P]` = arquivos diferentes; coordenar T025+T026+T027 na mesma PR US1
- Commit sugerido: por task ou por checkpoint de story
- Copy/nomes: `regras-plataforma.md` — nunca "Read-only" em UI pt-BR
- Amostra fiscalização: cap 500 protocolos/run (plan.md)
- Retenção snapshots: 90 dias (research.md R3)

---

## Task Summary

| Phase | Tasks | Story |
| --- | --- | --- |
| Phase 1 Setup | T001–T006 (6) | — |
| Phase 2 Foundational | T007–T020 (14) | — |
| Phase 3 US1 | T021–T031 (11) | P1 🎯 MVP |
| Phase 4 US2 | T032–T042 (11) | P2 |
| Phase 5 US3 | T043–T057 (15) | P3 |
| Phase 6 US4 | T058–T072 (15) | P4 |
| Phase 7 Polish | T073–T079 (7) | — |
| **Total** | **79 tasks** | |

**Format validation**: Todas as tasks usam `- [ ]`, ID `T###`, labels `[P]`/`[US#]` quando aplicável, e caminhos de arquivo explícitos.
