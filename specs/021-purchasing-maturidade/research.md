# Research: Maturidade Carvalho — Compras

**Feature**: 021-purchasing-maturidade · **Date**: 2026-06-25

## R1 — Dimensões de maturidade Compras (≠ CI/GOV/TI)

**Decision**: Novo enum Prisma `ComprasMaturityDimension` com 4 valores: `planejamento`, `instrucao_processual`, `conformidade`, `resultados`. Não reutilizar `MaturityAxis` (CI/GOV/TI) de Ouvidoria/Gabinete.

**Rationale**: FR-002 e spec exigem dimensões de domínio Lei 14.133; vocabulário distinto de maturidade transversal institucional.

**Alternatives considered**:

- Reutilizar `MaturityAxis` com labels PT diferentes → rejeitado (semântica incorreta; confunde Global Carvalho)
- Dimensões dinâmicas por tenant na v1 → rejeitado (Out of Scope — edição de banco de perguntas)

---

## R2 — Fórmula híbrida: só dimensão Conformidade

**Decision**: Reutilizar `computeHybridAxisScore()` de `lib/hybrid-score.ts` (R-50: `round(0.6 × self + 0.4 × jatoba)`) **apenas** na dimensão `conformidade`. Demais dimensões: score = autoavaliação pura (`partialSource: false`). Score global = média ponderada das 4 dimensões (pesos default 25/25/25/25 em `ComprasMaturidadeConfig`).

**Rationale**: FR-007 e spec US2.5 limitam híbrido Jatobá à Conformidade; Gabinete/Ouvidoria aplicam 60/40 em todos os eixos — Compras diverge por domínio.

**Alternatives considered**:

- Híbrido em todas as dimensões (paridade Gabinete) → rejeitado (contradiz spec 021)
- Jatobá substitui autoavaliação em Conformidade quando disponível → rejeitado (perde valor da autoavaliação institucional)

---

## R3 — Mapeamento Jatobá → taxa de conformidade (dimensão Conformidade)

**Decision**: Agregar **todas** as checagens `JAT-CMP-*` da última execução `ComprasFiscalizacaoRun` com `status=completed` em taxa única 0–100 para a dimensão Conformidade:

- Por demanda: pior status entre checks da demanda (`conforme=100`, `partial=50`, `pending|non_conforme=0`)
- Taxa global = média sobre demandas fiscalizadas no run

Mapa em `lib/jatoba-dimension-map.ts` documenta regra→tema (referência orientações), mas **não** split multi-dimensão para híbrido.

| ruleId | Tema (orientações) |
|--------|-------------------|
| `JAT-CMP-DFD` | Completude DFD |
| `JAT-CMP-ETP` | ETP / dispensa |
| `JAT-CMP-RIS` | Análise de riscos |
| `JAT-CMP-TR` | Termo de referência |
| `JAT-CMP-PRC` | Pesquisa de preços |
| `JAT-CMP-DOT` | Dotação orçamentária |
| `JAT-CMP-PAR` | Parecer jurídico |
| `JAT-CMP-VAL` | Consistência orçamentária |

Leitura cross-module via repositories `compras-fiscalizacao` (mesmo padrão `gabinete-maturidade/repository/fiscalizacao-read.repositories.ts`).

**Rationale**: Spec 019 preparou runs consumíveis via FK; achados agregados sem PII (FR-006 US3.4).

**Alternatives considered**:

- Mapear cada regra a dimensão diferente com híbrido parcial → rejeitado (complexidade; spec limita híbrido a Conformidade)
- Duplicar checks no módulo Carvalho → rejeitado (fronteira licenças)

---

## R4 — Patamar *Adequado* e alertas

**Decision**:

- Patamar *Adequado*: **≥ 60/100** por dimensão
- Meta institucional (alertas Carvalho): **80** (R-52, paridade Ouvidoria)
- `< 70` → alerta `critical`; `≥ 70` e `< 80` → `attention`; `≥ 80` → sem alerta

Orientações de melhoria geradas quando score dimensão **< 60**; score ≥ 60 exibe reconhecimento de boa prática (US3.3).

**Rationale**: Assumption spec (≥ 60/100); alertas institucionais mantêm paridade plataforma.

**Alternatives considered**:

- Patamar 70 (igual alerta crítico) → rejeitado (orientações e alertas colidem)
- Patamar único global → rejeitado (FR-006 exige por dimensão)

---

## R5 — Persistência de respostas parciais (FR-008)

**Decision**: Submissão com status `draft | submitted`. Ao salvar resposta parcial (`PATCH /self-assessment/answers`), upsert `ComprasMaturidadeSubmission` em `draft` + respostas individuais. `PUT /self-assessment` valida obrigatórias, transiciona para `submitted`, calcula scores e persiste snapshot. Dashboard só exibe scores quando `submitted`.

**Rationale**: Gap atual em Gabinete/Ouvidoria (só persiste no PUT completo); FR-008 e SC-007 exigem continuidade.

**Alternatives considered**:

- localStorage client-only → rejeitado (não multi-dispositivo; perde rastreabilidade tenant)
- Auto-save debounced sem status draft → rejeitado (score parcial ambíguo)

---

## R6 — Períodos trimestrais e unicidade

**Decision**: Reutilizar padrão `EnsureCurrentPeriodUseCase` + `period-utils.ts` (label `"2026 Q2"`, bounds UTC trimestrais). `@@unique([periodId])` em submission; re-submit no mesmo período faz upsert (FR-009). Conflito multi-usuário: última submissão prevalece — resposta inclui `submittedBy` + `submittedAt` no dashboard (edge case spec).

**Rationale**: Paridade estrutural Gabinete; FR-004/FR-009/US4.

**Alternatives considered**:

- Semestral default → rejeitado (Assumption spec: trimestral)
- Múltiplas submissões por período (histórico interno) → rejeitado (FR-009)

---

## R7 — Orientações de melhoria (feature nova)

**Decision**: Catálogo estático versionado em `lib/improvement-orientations.ts`:

- Chave: `(dimension, scoreBand)` onde `scoreBand` ∈ `low (<60)` | `adequate (60–79)` | `strong (≥80)`
- Cada entrada: `{ title, actions: string[] }` — linguagem imperativa consultiva (regras-plataforma)
- Dimensão Conformidade com Jatobá: enriquecer orientação `low` com temas frequentes agregados (ex.: *Revise completude de DFD e pesquisa de preços*) — **sem** protocolo/demanda individual

**Rationale**: FR-006; Out of Scope action plans — orientações consultivas substituem planos nesta entrega.

**Alternatives considered**:

- LLM-generated orientations → rejeitado (Out of Scope; determinismo TDD)
- Reutilizar ActionPlansPanel → rejeitado (FR-015)

---

## R8 — Indicadores operacionais Compras

**Decision**: Três indicadores read-only no dashboard (licencas-canonicas §Compras Carvalho):

| type | Fonte | Descrição |
|------|-------|-----------|
| `artefact_funnel` | `compras.mapper.ts` | Média progresso `N/7` artefatos satisfeitos |
| `budget_inconsistency_rate` | Checks `JAT-CMP-VAL` último run | % demandas com inconsistência orçamentária |
| `licitation_conformity_rate` | Agregado checks último run | % demandas conformes (worst-of checks) |

Indicadores **não** compõem score de dimensões (exceto conformidade via híbrido R2). Trace sheet por indicador (paridade Ouvidoria).

**Rationale**: licencas-canonicas — funil, inconsistências, conformidade licitatória; read-only sobre Base/Jatobá.

**Alternatives considered**:

- Copiar indicadores Ouvidoria (volume, satisfação) → rejeitado (domínio Compras distinto)
- Omitir indicadores → rejeitado (dashboard Carvalho esperado na licença)

---

## R9 — Exportação de relatório

**Decision**: `GET /compras/maturidade/export` retorna **HTML** imprimível (mesmo padrão `GET /compras/insights/export` spec 020): score global, dimensões, orientações, histórico (≥2 períodos), data/autor. Client aciona *Imprimir / Salvar como PDF* do browser. Meta SC-006: ≤ 30s.

**Rationale**: Stack existente sem Puppeteer; PDF via print-to-PDF atende FR-010.

**Alternatives considered**:

- PDF server-side (Puppeteer) → rejeitado (dependência nova; stub 018 já usa 501 para PDF)
- CSV → rejeitado (spec pede relatório executivo)

---

## R10 — Snapshots e histórico temporal

**Decision**: Persistir `ComprasMaturidadeScoreSnapshot` ao submeter autoavaliação; recalcular se run Jatobá mais recente que snapshot (GET dashboard lazy refresh — padrão R3 spec 009). Histórico: snapshots ordenados por período; gráfico evolução quando ≥ 2 (SC-003).

**Rationale**: Performance SC-002 (≤ 3s); evolução temporal sem recalcular tudo.

**Alternatives considered**:

- On-the-fly only → rejeitado (histórico + performance)

---

## R11 — Seed de questionário

**Decision**: `prisma/seed/seed-compras-maturidade-questions.ts` — ~3–4 perguntas por dimensão (12–16 total), tipos `scale_1_5` e `yes_no`, pesos default 1, ordenação `sortOrder`. Invocado no seed Jacaranda (`seed-jacaranda-tenant.ts`) para tenant demo com licença Carvalho + demandas Compras.

**Rationale**: Assumption spec — perguntas padrão provisionadas; editáveis em evolução futura.

**Alternatives considered**:

- Perguntas hardcoded só em código (sem DB) → rejeitado (multi-tenant; pesos por pergunta)

---

## R12 — Estrutura de módulo e guards

**Decision**: Submódulo isolado `ci-api-v2/src/modules/compras-maturidade/` registrado em `app.module.ts`. Guards: `@RequireModulo('compras')` + `@RequireLicenca('carvalho')`. Prefix REST `/compras/maturidade`. **Sem** endpoints action-plans.

**Rationale**: Paridade 018/019/020 (licença = submódulo); FR-011/FR-012/FR-015.

**Alternatives considered**:

- Estender `compras.controller.ts` → rejeitado (padrão estabelecido 019/020)
