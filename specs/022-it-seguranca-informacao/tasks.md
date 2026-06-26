---
description: "Task list for Módulo IT Segurança da Informação (022-it-seguranca-informacao)"
---

# Tasks: Módulo IT — Segurança da Informação

**Input**: Design documents from `civ2-docs/specs/022-it-seguranca-informacao/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Tests**: **Obrigatórios** — TDD (constitution II + plan.md + `contracts/test-strategy.md`): unitário, contrato, integração (mocks) e E2E. **Sem Postgres de teste dedicado**.

**Organization**: 14 user stories (US1–US14). Caminhos relativos à raiz `ci-v2/`. Módulos **`it`**, **`it-insights`**, **`it-fiscalizacao`**, **`it-maturidade`** **não existem** — criar espelhando `compras*`.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Pode executar em paralelo (arquivos diferentes, sem dependências pendentes)
- **[Story]**: User story da spec (US1–US14)

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Dependências, fixtures, MSW, scaffolding dos 4 submódulos API e client

- [ ] T001 Instalar `pdf-lib` em `ci-api-v2/package.json` e `@nivo/pie` + `@nivo/bar` em `ci-client-v2/apps/web/package.json` se ausentes
- [X] T002 [P] Criar fixtures API base em `ci-api-v2/src/modules/it/test/fixtures/ativos-list.json`, `ativo-detail.json` e `dashboard-empty.json` conforme `contracts/rest-api-it-base.md`
- [ ] T003 [P] Criar fixtures API insights em `ci-api-v2/src/modules/it-insights/test/fixtures/insights-panel.json`, `config-scan-findings.json` e `lgpd-classify-result.json`
- [ ] T004 [P] Criar fixtures API fiscalização em `ci-api-v2/src/modules/it-fiscalizacao/test/fixtures/backup-audit-panel.json` e `audit-trail-sample.json`
- [ ] T005 [P] Criar fixtures API maturidade em `ci-api-v2/src/modules/it-maturidade/test/fixtures/maturidade-dashboard.json`
- [ ] T006 [P] Criar fixtures client em `ci-client-v2/apps/web/src/modules/it/fixtures/` espelhando fixtures API (dashboard, ativos, insights, fiscalizacao, maturidade)
- [X] T007 [P] Adicionar handlers MSW em `ci-client-v2/apps/web/src/test/msw/handlers/it.ts` e registrar em `ci-client-v2/apps/web/src/test/msw/handlers.ts`
- [X] T008 [P] Criar esqueletos de pastas `ci-api-v2/src/modules/it/`, `it-insights/`, `it-fiscalizacao/`, `it-maturidade/` com subpastas `lib/`, `repository/`, `use-cases/`, `test/` e `jobs/` onde aplicável
- [X] T009 [P] Criar esqueleto client `ci-client-v2/apps/web/src/modules/it/` com `pages/`, `components/`, `api/`, `__tests__/`, `fixtures/`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Registro do 9º módulo, schemas Prisma, guards, seeds, shell client — **bloqueia todas as user stories**

**⚠️ CRITICAL**: Nenhuma user story começa antes desta fase

### Registro módulo IT (US14 parcial)

- [X] T010 Adicionar slug `it` em `ci-api-v2/src/common/constants/modulos.ts` (`MODULO_SLUGS`, `MODULO_LABELS`)
- [X] T011 Adicionar `it` ao enum `ModuloSlug` em `ci-api-v2/prisma/schema/enums.prisma`
- [X] T012 Registrar relations IT em `ci-api-v2/prisma/schema/tenant.prisma` conforme `data-model.md`
- [X] T013 [P] Adicionar `it` ao array `modules` em `ci-client-v2/apps/web/src/modules/shell/config/license-screens.ts`
- [X] T014 [P] Adicionar bloco navegação IT em `ci-client-v2/apps/web/src/modules/shell/config/navigation.ts` (dashboard, ativos, incidentes, operadores, `licenseNav('it')`, fiscalização)
- [X] T015 [P] Registrar telas operacionais em `ci-client-v2/apps/web/src/modules/shell/config/screens.ts` (`it-dashboard`, `it-ativos`, `it-incidentes`, `it-operadores`)
- [X] T016 [P] Adicionar `moduleLicenseConfig.it` em `ci-client-v2/packages/domain/src/lib/licenses.ts` e `MODULE_PATHS.it` em `ci-client-v2/apps/web/src/modules/shell/lib/license-alerts.ts`
- [ ] T017 [P] Atualizar `.cursor/docs/regras-plataforma.md` §3 — incluir `it` | Segurança da Informação como 9º módulo
- [X] T018 Registrar `ModuloSetor` IT no seed `ci-api-v2/prisma/seed/seed-jacaranda-tenant.ts` (setor TI demo)

### Schema & migration

- [X] T019 Criar `ci-api-v2/prisma/schema/it.prisma` — ItAsset, ItAssetTag, ItAssetLink, ItIncident, ItDataDictionary, ItSensitiveDataCategory, ItOperatorTreatment, ItOperatorCategory + enums conforme `data-model.md`
- [X] T020 Criar `ci-api-v2/prisma/schema/it-insights.prisma` — ItInsightBatch, ItInsight, ItConfigAnalysis, ItSecurityPolicyPattern, ItLgpdSensitiveTerm, ItRiskMatrixEvaluation
- [X] T021 Criar `ci-api-v2/prisma/schema/it-fiscalizacao.prisma` — ItBackupAuditRun, ItBackupEvidence, ItAuditTrail, ItAnpdNotification
- [X] T022 Criar `ci-api-v2/prisma/schema/it-maturidade.prisma` — ItFrameworkControl, ItMaturidadeSnapshot
- [X] T023 Registrar schemas em `ci-api-v2/prisma/schema/schema.prisma` e gerar migration (`npx prisma migrate dev --name 022_it_module`)

### Seeds

- [X] T024 [P] Implementar `ci-api-v2/prisma/seed/seed-it-lgpd-terms.ts` — categorias sensíveis + termos (cpf, saude, salario, etc.)
- [X] T025 [P] Implementar `ci-api-v2/prisma/seed/seed-it-security-policy-patterns.ts` — regex port:21, allow_all, etc.
- [ ] T026 [P] Implementar `ci-api-v2/prisma/seed/seed-it-cis-controls.ts` — 20 controles (10 CIS + 10 LGPD)
- [X] T027 Registrar seeds IT em `ci-api-v2/prisma/seed/seed-jacaranda-tenant.ts` — ativos/incidentes demo opcionais

### Módulos Nest — registro

- [X] T028 Criar `ci-api-v2/src/modules/it/it.module.ts` com controller stub `@RequireModulo('it')`
- [X] T029 [P] Criar stubs `it-insights.module.ts`, `it-fiscalizacao.module.ts`, `it-maturidade.module.ts` com guards licença correspondentes
- [X] T030 Registrar `ItModule`, `ItInsightsModule`, `ItFiscalizacaoModule`, `ItMaturidadeModule` em `ci-api-v2/src/app.module.ts`
- [X] T031 Criar `ci-client-v2/apps/web/src/modules/it/index.ts` com `IT_OVERRIDES` lazy e registrar em `ci-client-v2/apps/web/src/app/router.tsx`

### Zod base & mapper

- [X] T032 [P] Implementar DTOs Zod iniciais em `ci-api-v2/src/modules/it/it.schemas.ts` — ItAssetListItem, ItAssetDetail, ItDashboardResponse
- [X] T033 [P] Implementar `ci-api-v2/src/modules/it/it.mapper.ts` — labels PT-BR tipos ativo, status incidente, linhas defesa
- [X] T034 [P] Escrever testes contrato (RED) `it.schemas.spec.ts` em `ci-api-v2/src/modules/it/test/it.schemas.spec.ts` contra fixtures T002

**Checkpoint**: Módulo `it` registrado API+client; schemas migrados; seeds stub; guards aplicados

---

## Phase 3: User Story 1 — Cadastrar e gerenciar ativos de TI (Priority: P1) 🎯 MVP

**Goal**: CRUD ativos 5 tipos; soft delete + restore; tags; vínculos entre ativos

**Independent Test**: Criar servidor/sistema/BD → vincular → soft delete → restaurar (`quickstart.md` § Cenário 1)

**Depends on**: Phase 2

### Tests for User Story 1 (TDD — RED first)

- [X] T035 [P] [US1] Escrever testes (RED) `create-ativo.use-case.spec.ts` em `ci-api-v2/src/modules/it/test/use-cases/create-ativo.use-case.spec.ts`
- [X] T036 [P] [US1] Escrever testes (RED) `soft-delete-restore-ativo.use-case.spec.ts` em `ci-api-v2/src/modules/it/test/use-cases/soft-delete-restore-ativo.use-case.spec.ts`
- [X] T037 [P] [US1] Escrever testes (RED) `link-ativos.use-case.spec.ts` em `ci-api-v2/src/modules/it/test/use-cases/link-ativos.use-case.spec.ts`
- [X] T038 [US1] Escrever teste integração (RED) `ativos-crud.integration-spec.ts` em `ci-api-v2/src/modules/it/test/integration/ativos-crud.integration-spec.ts`

### Implementation for User Story 1

- [X] T039 [P] [US1] Implementar repositórios ativo em `ci-api-v2/src/modules/it/repository/`
- [X] T040 [P] [US1] Implementar repositórios link/tags
- [X] T041 [US1] Implementar use-cases create/list/get/update/delete/restore/link
- [X] T042 [US1] Implementar endpoints CRUD `/it/ativos` + links + restore
- [X] T043 [P] [US1] Implementar client API `ci-client-v2/apps/web/src/modules/it/api/ativos.ts` + mappers
- [X] T044 [US1] Criar `ItAtivosListPage.tsx` em `ci-client-v2/apps/web/src/modules/it/pages/` — layout §4 regras-plataforma, menu ⋮, cards stats
- [X] T045 [US1] Criar `ItAtivoFormPage.tsx` e `ItAtivoDetailPage.tsx` — tags, painel vínculos `ItAssetLinksPanel.tsx`
- [X] T046 [US1] Registrar lazy routes `it-ativos`, `it-ativo-novo`, `it-ativo-detalhe` em `ci-client-v2/apps/web/src/modules/it/index.ts`
- [X] T047 [US1] GREEN integração `ativos-crud.integration-spec.ts` (T038)

**Checkpoint**: Inventário TI funcional — MVP entregável

---

## Phase 4: User Story 2 — Registrar incidentes de segurança (Priority: P1)

**Goal**: CRUD incidentes; campos estruturados; resolução com linha de defesa

**Independent Test**: Registrar incidente crítico → resolver com `resolvedByDefenseLine` (`quickstart.md` § Cenário 2)

**Depends on**: Phase 3 (ativo opcional vinculado)

### Tests for User Story 2 (TDD — RED first)

- [X] T048 [P] [US2] Escrever testes (RED) `create-incidente.use-case.spec.ts` em `ci-api-v2/src/modules/it/test/use-cases/create-incidente.use-case.spec.ts`
- [X] T049 [P] [US2] Escrever testes (RED) `resolve-incidente.use-case.spec.ts` em `ci-api-v2/src/modules/it/test/use-cases/resolve-incidente.use-case.spec.ts` — exige defense line
- [X] T050 [US2] Escrever teste integração (RED) `incidentes-crud.integration-spec.ts` em `ci-api-v2/src/modules/it/test/integration/incidentes-crud.integration-spec.ts`

### Implementation for User Story 2

- [X] T051 [P] [US2] Implementar repositórios incidente
- [X] T052 [US2] Implementar use-cases create/list/get/update/resolve
- [X] T053 [US2] Estender `it.schemas.ts` com ItIncident DTOs e endpoints `/it/incidentes`
- [X] T054 [P] [US2] Implementar client API `ci-client-v2/apps/web/src/modules/it/api/incidentes.ts`
- [X] T055 [US2] Criar `ItIncidentesListPage.tsx` e `ItIncidenteFormPage.tsx` — criticidade, logs, vínculo ativo
- [X] T056 [US2] Registrar routes `it-incidentes`, `it-incidente-novo` em `modules/it/index.ts`
- [X] T057 [US2] GREEN integração `incidentes-crud.integration-spec.ts` (T050)

**Checkpoint**: Incidentes registráveis e resolvíveis com linha de defesa

---

## Phase 5: User Story 3 — Mapear operadores e tratamento LGPD (Priority: P2)

**Goal**: Operador → sistema → categorias sensíveis; cálculo % LGPD

**Independent Test**: Vincular categorias a sistema → indicador LGPD reflete mapeamento (`quickstart.md` § Cenário 3)

**Depends on**: Phase 3 (ativos tipo system)

### Tests for User Story 3 (TDD — RED first)

- [X] T058 [P] [US3] Escrever testes (RED) `lgpd-compliance-percent.spec.ts` em `ci-api-v2/src/modules/it/lib/lgpd-compliance-percent.spec.ts`
- [X] T059 [P] [US3] Escrever testes (RED) `upsert-operador-treatment.use-case.spec.ts` em `ci-api-v2/src/modules/it/test/use-cases/upsert-operador-treatment.use-case.spec.ts`

### Implementation for User Story 3

- [X] T060 [P] [US3] Implementar `lgpd-compliance-percent.ts`
- [X] T061 [US3] Implementar repositórios operador/categorias
- [X] T062 [US3] Implementar use-cases operador CRUD + list categorias
- [X] T063 [US3] Endpoints `/it/operadores` e `/it/categorias-sensiveis`
- [X] T064 [US3] Criar `ItOperadoresPage.tsx` e `ItLgpdMappingForm.tsx` em `ci-client-v2/apps/web/src/modules/it/components/`
- [X] T065 [US3] Endpoint PUT `/it/ativos/:id/dicionario` para colunas BD

**Checkpoint**: Mapeamento LGPD operacional

---

## Phase 6: User Story 4 — Dashboard operacional (Priority: P2)

**Goal**: Volumetria ativos, incidentes abertos, % LGPD

**Independent Test**: Dashboard reflete cadastros reais; empty state sem números fabricados (`quickstart.md` § Cenário 3)

**Depends on**: Phase 3–5

### Tests for User Story 4 (TDD — RED first)

- [X] T066 [P] [US4] Escrever testes (RED) `get-dashboard.use-case.spec.ts` em `ci-api-v2/src/modules/it/test/use-cases/get-dashboard.use-case.spec.ts`

### Implementation for User Story 4

- [X] T067 [US4] Implementar `get-dashboard.use-case.ts` agregando stats (GREEN T066)
- [X] T068 [US4] Endpoint `GET /it/dashboard` em `it.controller.ts`
- [X] T069 [US4] Criar `ItDashboardPage.tsx` e `ItDashboardCards.tsx` — 3 indicadores principais + empty state
- [X] T070 [US4] Registrar route `it-dashboard` como default `/it` em `modules/it/index.ts`

**Checkpoint**: Dashboard operacional Base completo

---

## Phase 7: User Story 5 — Classificador LGPD Cedro (Priority: P3)

**Goal**: Varredura dicionário; insight read-only; *Aplicar classificação* na Base

**Independent Test**: Coluna `cpf_*` → insight → apply flag (`quickstart.md` § Cenário 4; SC-011)

**Depends on**: Phase 5 (dicionário); Phase 2 (it-insights module)

### Tests for User Story 5 (TDD — RED first)

- [X] T071 [P] [US5] Escrever testes (RED) `lgpd-classifier.spec.ts` em `ci-api-v2/src/modules/it-insights/lib/lgpd-classifier.spec.ts`
- [X] T072 [P] [US5] Escrever testes (RED) `apply-sensitive-flag.use-case.spec.ts` em `ci-api-v2/src/modules/it/test/use-cases/apply-sensitive-flag.use-case.spec.ts` — Cedro não altera flag sozinho
- [X] T073 [US5] Escrever testes (RED) `classify-lgpd.use-case.spec.ts` em `ci-api-v2/src/modules/it-insights/test/use-cases/classify-lgpd.use-case.spec.ts`

### Implementation for User Story 5

- [X] T074 [P] [US5] Implementar `lgpd-classifier.ts` em `ci-api-v2/src/modules/it-insights/lib/` (GREEN T071)
- [X] T075 [US5] Implementar `classify-lgpd.use-case.ts` + endpoint `POST /it/insights/lgpd/classify/:assetId` em `it-insights.controller.ts`
- [X] T076 [US5] Implementar `apply-sensitive-data-flag.use-case.ts` + `POST /it/ativos/:id/apply-sensitive-flag` em `it.controller.ts` (GREEN T072)
- [X] T077 [US5] Criar `ItLgpdInsightCard.tsx` — badge **Somente leitura**, CTA **Aplicar classificação**
- [X] T078 [US5] Integrar card no detalhe ativo BD e painel insights

**Checkpoint**: Classificador Cedro + confirmação Base (R-21 intacta)

---

## Phase 8: User Story 6 — Análise de configurações e portas (Priority: P3)

**Goal**: Upload presign; regex scan; alertas configuracao

**Independent Test**: Upload com `port: 21` → alerta ≤10s (`quickstart.md` § Cenário 5)

**Depends on**: Phase 3 (servidores); StorageModule

### Tests for User Story 6 (TDD — RED first)

- [X] T079 [P] [US6] Escrever testes (RED) `config-scan.spec.ts` em `ci-api-v2/src/modules/it-insights/lib/config-scan.spec.ts`
- [X] T080 [US6] Escrever testes (RED) `analyze-config.use-case.spec.ts` em `ci-api-v2/src/modules/it-insights/test/use-cases/analyze-config.use-case.spec.ts`

### Implementation for User Story 6

- [X] T081 [P] [US6] Implementar `config-scan.ts` em `ci-api-v2/src/modules/it-insights/lib/` (GREEN T079)
- [X] T082 [US6] Implementar presign + analyze use-cases reutilizando `StorageModule` — endpoints `/it/insights/config/presign` e `/analyze`
- [X] T083 [US6] Criar `ItConfigUploadPanel.tsx` e histórico análises na `ItInsightsPage.tsx`
- [X] T084 [US6] Endpoint `GET /it/insights` painel agregado em `it-insights.controller.ts`

**Checkpoint**: Análise de configurações Cedro funcional

---

## Phase 9: User Story 7 — Matriz de impacto de mudanças (Priority: P3)

**Goal**: Checklist condicional; nota risco instantânea

**Independent Test**: Externo + MFA Não + dados pessoais → Risco Alto (`quickstart.md` § Cenário 5)

**Depends on**: Phase 7 (it-insights controller)

### Tests for User Story 7 (TDD — RED first)

- [X] T085 [P] [US7] Escrever testes (RED) `risk-matrix-tree.spec.ts` em `ci-api-v2/src/modules/it-insights/lib/risk-matrix-tree.spec.ts`

### Implementation for User Story 7

- [X] T086 [US7] Implementar `risk-matrix-tree.ts` com árvore If/Else seed (GREEN T085)
- [X] T087 [US7] Implementar `evaluate-risk-matrix.use-case.ts` + `POST /it/insights/risk-matrix/evaluate`
- [X] T088 [US7] Criar `ItRiskMatrixForm.tsx` na `ItInsightsPage.tsx` — resultado instantâneo + trace sheet

**Checkpoint**: Matriz de risco Cedro completa; painel `/it/insights` funcional

---

## Phase 10: User Story 8 — Workflow auditoria de backup (Priority: P4)

**Goal**: Cron dia X; status alerta/vermelho; evidência backup

**Independent Test**: Simular cron → evidência válida → Conforme (`quickstart.md` § Cenário 6)

**Depends on**: Phase 3 (servidores); Phase 2 (it-fiscalizacao)

### Tests for User Story 8 (TDD — RED first)

- [X] T089 [P] [US8] Escrever testes (RED) `backup-validation.spec.ts` em `ci-api-v2/src/modules/it-fiscalizacao/lib/backup-validation.spec.ts`
- [X] T090 [P] [US8] Escrever testes (RED) `submit-backup-evidence.use-case.spec.ts` em `ci-api-v2/src/modules/it-fiscalizacao/test/use-cases/submit-backup-evidence.use-case.spec.ts`
- [X] T091 [P] [US8] Escrever testes (RED) `backup-audit-scheduled.job.spec.ts` em `ci-api-v2/src/modules/it-fiscalizacao/jobs/backup-audit-scheduled.job.spec.ts`

### Implementation for User Story 8

- [X] T092 [P] [US8] Implementar `backup-validation.ts` (GREEN T089)
- [X] T093 [US8] Implementar `run-backup-audit-cycle.use-case.ts`, `submit-backup-evidence.use-case.ts`, `notify-secretary.use-case.ts`
- [X] T094 [US8] Implementar jobs `backup-audit-scheduled.job.ts` e `backup-audit-overdue.job.ts` com `BACKUP_AUDIT_DAY` env
- [X] T095 [US8] Endpoints backup em `it-fiscalizacao.controller.ts` — pending, presign, evidence, run manual
- [ ] T096 [US8] Criar `ItBackupEvidenceForm.tsx` e seção backup em `ItFiscalizacaoPage.tsx` (reuso `FiscalizacaoPanel`)

**Checkpoint**: Workflow backup Jatobá operacional

---

## Phase 11: User Story 9 — Trilha de auditoria imutável (Priority: P4)

**Goal**: Append-only log; consulta paginada; sem delete

**Independent Test**: CRUD ativo → linha trilha; DELETE audit → impossível (`quickstart.md` § Cenário 7; SC-008)

**Depends on**: Phase 3 (use-cases emitem trail)

### Tests for User Story 9 (TDD — RED first)

- [X] T097 [P] [US9] Escrever testes (RED) `it-audit-trail.repository.spec.ts` em `ci-api-v2/src/modules/it-fiscalizacao/test/repository/it-audit-trail.repository.spec.ts` — rejeita delete/update
- [X] T098 [US9] Escrever testes (RED) `list-audit-trail.use-case.spec.ts` em `ci-api-v2/src/modules/it-fiscalizacao/test/use-cases/list-audit-trail.use-case.spec.ts`

### Implementation for User Story 9

- [X] T099 [US9] Implementar `it-audit-trail.repository.ts` append-only em `ci-api-v2/src/modules/it-fiscalizacao/repository/` (GREEN T097)
- [X] T100 [US9] Criar `append-it-audit-trail.use-case.ts` e invocar nos use-cases Base IT (create/update/delete/read sensível)
- [X] T101 [US9] Implementar `list-audit-trail.use-case.ts` + `GET /it/fiscalizacao/audit-trail`
- [X] T102 [US9] Criar `ItAuditTrailTable.tsx` read-only na `ItFiscalizacaoPage.tsx`

**Checkpoint**: Trilha imutável consultável

---

## Phase 12: User Story 10 — Gerador notificação ANPD (Priority: P4)

**Goal**: Template preenchido; PDF binário 1 clique (incidentes críticos)

**Independent Test**: Incidente crítico → PDF ≥90% preenchido (`quickstart.md` § Cenário 8; SC-009)

**Depends on**: Phase 4 (incidentes críticos)

### Tests for User Story 10 (TDD — RED first)

- [X] T103 [P] [US10] Escrever testes (RED) `anpd-pdf-template.spec.ts` em `ci-api-v2/src/modules/it-fiscalizacao/lib/anpd-pdf-template.spec.ts`
- [X] T104 [US10] Escrever testes (RED) `generate-anpd-notification.use-case.spec.ts` em `ci-api-v2/src/modules/it-fiscalizacao/test/use-cases/generate-anpd-notification.use-case.spec.ts`

### Implementation for User Story 10

- [X] T105 [P] [US10] Implementar `anpd-pdf-template.ts` com `pdf-lib` (GREEN T103)
- [X] T106 [US10] Implementar preview + generate use-cases — endpoints `/it/fiscalizacao/incidentes/:id/anpd/preview` e `/generate`
- [X] T107 [US10] Criar `ItAnpdGenerateButton.tsx` — oculto se severity ≠ critical (R-10)
- [X] T108 [US10] Persistir `ItAnpdNotification` + storage PDF via `StorageModule`

**Checkpoint**: Gerador ANPD completo

---

## Phase 13: User Story 11 — Linhas de defesa (Priority: P5)

**Goal**: Gráfico pizza % por linha; alerta linha 3 elevada

**Independent Test**: Incidentes resolvidos com linhas distintas → gráfico correto (`quickstart.md` § Cenário 9)

**Depends on**: Phase 4; Phase 2 (it-maturidade)

### Tests for User Story 11 (TDD — RED first)

- [X] T109 [P] [US11] Escrever testes (RED) `defense-lines.spec.ts` em `ci-api-v2/src/modules/it-maturidade/lib/defense-lines.spec.ts`

### Implementation for User Story 11

- [X] T110 [US11] Implementar `defense-lines.ts` (GREEN T109) — threshold linha 3 >40% alerta
- [X] T111 [US11] Implementar `get-maturidade-dashboard.use-case.ts` parcial (defense lines) + `GET /it/maturidade`
- [X] T112 [US11] Criar `ItDefenseLinesChart.tsx` (Nivo Pie) em `ItMaturidadePage.tsx` + trace sheet

**Checkpoint**: Linhas de defesa Carvalho visíveis

---

## Phase 14: User Story 12 — Aderência LGPD e CIS Controls (Priority: P5)

**Goal**: Score 0–100%; PATCH status controles

**Independent Test**: 15/20 concluídos → 75% (`quickstart.md` § Cenário 9)

**Depends on**: Phase 2 (seed controles)

### Tests for User Story 12 (TDD — RED first)

- [X] T113 [P] [US12] Escrever testes (RED) `framework-adherence.spec.ts` em `ci-api-v2/src/modules/it-maturidade/lib/framework-adherence.spec.ts`

### Implementation for User Story 12

- [X] T114 [US12] Implementar `framework-adherence.ts` (GREEN T113) — alertas R-64/R-65
- [X] T115 [US12] Endpoints `GET/PATCH /it/maturidade/controls` em `it-maturidade.controller.ts`
- [X] T116 [US12] Criar `ItFrameworkControlsList.tsx` na maturidade page

**Checkpoint**: Score aderência CIS/LGPD funcional

---

## Phase 15: User Story 13 — Índice vulnerabilidade por secretaria (Priority: P5)

**Goal**: Ranking por setor; fórmula spec; drill-down

**Independent Test**: Ativos/incidentes por secretaria → ranking (`quickstart.md` § Cenário 9)

**Depends on**: Phase 3–4

### Tests for User Story 13 (TDD — RED first)

- [X] T117 [P] [US13] Escrever testes (RED) `vulnerability-index.spec.ts` em `ci-api-v2/src/modules/it-maturidade/lib/vulnerability-index.spec.ts`

### Implementation for User Story 13

- [X] T118 [US13] Implementar `vulnerability-index.ts` (GREEN T117)
- [X] T119 [US13] Completar dashboard maturidade com ranking + `GET /it/maturidade/setores/:id/detail`
- [X] T120 [US13] Criar `ItVulnerabilityRanking.tsx` (Nivo Bar) + drill-down na `ItMaturidadePage.tsx`
- [X] T121 [US13] Registrar lazy `it-maturidade` e `it-insights`, `it-fiscalizacao` em `modules/it/index.ts`

**Checkpoint**: Painel Carvalho `/it/maturidade` completo

---

## Phase 16: User Story 14 — Governança licenças (Priority: P1)

**Goal**: Guards módulo + licença; UI condicional; 403 padronizado

**Independent Test**: Sem Cedro → `/it/insights` alerta; sem módulo → 403 (`quickstart.md` § Cenário 10)

**Depends on**: Todas rotas licenciadas implementadas

### Tests for User Story 14 (TDD — RED first)

- [X] T122 [P] [US14] Escrever testes e2e (RED) `it-guards.e2e-spec.ts` em `ci-api-v2/test/it-guards.e2e-spec.ts` — 403 módulo; 403 licença Cedro/Jatobá/Carvalho
- [X] T123 [P] [US14] Escrever testes (RED) `ItPages.guards.test.tsx` em `ci-client-v2/apps/web/src/modules/it/__tests__/ItPages.guards.test.tsx`

### Implementation for User Story 14

- [X] T124 [US14] Validar `@RequireModulo('it')` em todos controllers IT e `@RequireLicenca` por submódulo
- [X] T125 [US14] Aplicar `useModuleAccess('it')` + alertas licença em todas pages IT
- [X] T126 [US14] GREEN e2e guards API e client (T122–T123)

**Checkpoint**: Governança licenças conforme spec US14

---

## Phase 17: Polish & Cross-Cutting Concerns

**Purpose**: E2E, quickstart, documentação, performance

- [X] T127 [P] Escrever `it.e2e-spec.ts` em `ci-api-v2/test/it.e2e-spec.ts` — jornada CRUD + insights + backup + maturidade
- [X] T128 [P] Escrever `it.e2e.test.tsx` em `ci-client-v2/apps/web/src/modules/it/__tests__/it.e2e.test.tsx` — SC-012 ≤45min flow
- [X] T129 [P] Escrever `it.contract.test.ts` em `ci-client-v2/apps/web/src/modules/it/__tests__/it.contract.test.ts` — Zod vs fixtures
- [X] T130 Completar seeds demo Jacaranda — 5 ativos, 2 incidentes, 1 mapeamento LGPD, 1 insight config em `seed-jacaranda-tenant.ts`
- [X] T131 [P] Adicionar rastreabilidade sheets — insight, checagem backup, score maturidade (`TraceabilitySheet` reuse)
- [X] T132 Executar validação manual `quickstart.md` § Cenários 1–10 e documentar desvios em `civ2-docs/specs/022-it-seguranca-informacao/STATUS.md`
- [X] T133 [P] Atualizar `ci-api-v2/CONTEXT.md` — vocabulário domínio IT (ativo, incidente, linha defesa, trilha)

---

## Dependencies & Execution Order

### Phase Dependencies

| Fase | Depende de | Entrega |
|------|------------|---------|
| 1 Setup | — | Fixtures, MSW, scaffolds |
| 2 Foundational | 1 | Módulo registrado, schemas, guards |
| 3 US1 | 2 | **MVP** — CRUD ativos |
| 4 US2 | 3 | Incidentes |
| 5 US3 | 3 | LGPD mapping |
| 6 US4 | 3,4,5 | Dashboard |
| 7–9 US5–7 | 2,3,5 | Cedro insights |
| 10–12 US8–10 | 2,3,4 | Jatobá |
| 13–15 US11–13 | 2,4 | Carvalho |
| 16 US14 | 7–15 | Guards E2E |
| 17 Polish | 16 | E2E + quickstart |

### User Story Dependencies

- **US1**: Independente após Foundational — **MVP**
- **US2**: Independente; vínculo ativo opcional
- **US3**: Requer ativos tipo `system`
- **US4**: Agrega US1+US2+US3; parcialmente testável só com US1
- **US5**: Requer dicionário (US3/T065) + it-insights
- **US6–7**: Requer servidores (US1) + it-insights
- **US8–10**: Requer servidores/incidentes + it-fiscalizacao
- **US11–13**: Requer incidentes resolvidos (US2) + it-maturidade
- **US14**: Transversal — validação final

### Parallel Opportunities

- Phase 1: T002–T009 em paralelo
- Phase 2: T013–T018, T024–T026, T029, T032–T033 em paralelo
- US5–7 (Cedro): libs T071, T079, T085 em paralelo após Phase 2
- US11–13 (Carvalho): libs T109, T113, T117 em paralelo
- Polish: T127–T129, T131, T133 em paralelo

---

## Parallel Example: User Story 1

```bash
# Tests RED em paralelo:
T035 create-ativo.use-case.spec.ts
T036 soft-delete-restore-ativo.use-case.spec.ts
T037 link-ativos.use-case.spec.ts

# Repositories em paralelo:
T039 create/find/update/delete repos
T040 link/tags repos
```

---

## Parallel Example: Cedro (US5–7)

```bash
# Libs puras RED em paralelo:
T071 lgpd-classifier.spec.ts
T079 config-scan.spec.ts
T085 risk-matrix-tree.spec.ts
```

---

## Implementation Strategy

### MVP First (User Story 1)

1. Phase 1: Setup
2. Phase 2: Foundational
3. Phase 3: US1 — CRUD ativos + páginas lista/detalhe
4. **STOP e VALIDAR**: `quickstart.md` § Cenário 1

### Incremental Delivery

1. Setup + Foundational → infra pronta
2. US1 → MVP inventário TI
3. US2 → incidentes + linhas defesa (dados para Carvalho)
4. US3 + US4 → LGPD + dashboard
5. US5–7 → Cedro insights (valor comercial)
6. US8–10 → Jatobá fiscalização
7. US11–13 → Carvalho maturidade
8. US14 + Polish → governança + E2E

### Parallel Team Strategy

- **Dev A**: API Base (US1–4) + audit trail hooks
- **Dev B**: Client Base pages + dashboard
- **Dev C**: it-insights (US5–7) após Foundational
- **Dev D**: it-fiscalizacao (US8–10) após US1
- **Dev E**: it-maturidade (US11–13) após US2

---

## Notes

- **Cedro read-only**: insight nunca PATCH ativo — só `apply-sensitive-flag` na Base (research R6)
- **Trilha IT**: repository sem delete — teste T097 obrigatório antes merge
- **PDF ANPD**: primeira dependência `pdf-lib` no monorepo
- Vocabulário UI: **Segurança da Informação**; rotas `/it/*`
- Referência viva: `ci-api-v2/src/modules/compras/` + submódulos; UI: `modules/compras/pages/`
- Commit após cada task ou grupo lógico; RED antes de GREEN

---

## Task Summary

| Métrica | Valor |
|---------|-------|
| **Total tasks** | 133 |
| **Phase 1 Setup** | 9 |
| **Phase 2 Foundational** | 25 |
| **US1** | 13 |
| **US2** | 10 |
| **US3** | 8 |
| **US4** | 5 |
| **US5** | 8 |
| **US6** | 6 |
| **US7** | 4 |
| **US8** | 8 |
| **US9** | 6 |
| **US10** | 6 |
| **US11** | 4 |
| **US12** | 4 |
| **US13** | 5 |
| **US14** | 5 |
| **Polish** | 7 |
| **MVP scope** | Phase 1–3 (T001–T047) |
