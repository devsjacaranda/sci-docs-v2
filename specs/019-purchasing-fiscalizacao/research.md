# Research: Fiscalização de Compras — Purchasing (Jatobá)

**Feature**: 019-purchasing-fiscalizacao · **Date**: 2026-06-25

## R1 — Unidade fiscalizada: somente demandas ativas

**Decision**: Execução completa analisa **100%** das `CompraDemanda` com `deletedAt IS NULL` do tenant. Cada demanda gera um `ComprasFiscalizacaoResult` com checagens sobre os 7 artefatos 1:1 + checagem transversal de consistência orçamentária.

**Rationale**: FR-001, FR-002, SC-002; spec Out of Scope exclui fiscalização de PCA como entidade independente.

**Alternatives considered**:

- Fiscalizar PCAs agregando demandas → rejeitado (fora de escopo)
- Só demandas com status derivado `completed` → rejeitado (edge case spec: rascunho também fiscalizado)

---

## R2 — Schema Prisma dedicado (espelho Ouvidoria)

**Decision**: Novo arquivo `compras-fiscalizacao.prisma` com modelos `ComprasFiscalizacaoRun`, `Result`, `Check`, `Finding`. Reutiliza enums globais existentes (`FiscalizacaoRunOrigin`, `FiscalizacaoRunStatus`, `ConformityStatus`) de `ouvidoria-fiscalizacao.prisma`.

**Campos-chave**:

- `Run.scopedDemandaId` — execução scoped (origem `on_record`)
- `Result.demandaId` — FK `CompraDemanda` (required)
- `Result.protocol` — snapshot `"DEM-{number}"` (ex.: `DEM-12`)
- `Result.pcaTitle` — snapshot título PCA para histórico
- `Result.fiscalizedDataSummary` — ex.: `"7 artefatos documentais + consistência orçamentária"`
- Unique `(runId, demandaId)`

**Rationale**: Paridade estrutural com 008/016; isolamento de domínio; futura spec 021 (maturidade) pode consumir runs via FK.

**Alternatives considered**:

- Tabela genérica multi-módulo → rejeitado (FKs e queries distintas)
- JSON blob único por run → rejeitado (histórico e rastreio exigem normalização)

---

## R3 — Regras de checagem (lib/checks/)

**Decision**: 8 funções puras; prefixo `JAT-CMP-*`:

| Arquivo | ruleId | Label UI | Lógica |
|---------|--------|----------|--------|
| `dfd-completeness.rules.ts` | JAT-CMP-DFD | Completude DFD | `isDfdSatisfied()` de `compras.mapper.ts` |
| `etp-waiver.rules.ts` | JAT-CMP-ETP | ETP dispensado | `waived` sem `waiverReason` → non_conforme; waived com motivo → conforme; !waived → `isEtpSatisfied()` |
| `risk-analysis.rules.ts` | JAT-CMP-RIS | Análise de Riscos | `isRiskAnalysisSatisfied()` — lista vazia → partial/non_conforme |
| `tr-completeness.rules.ts` | JAT-CMP-TR | Completude TR | `isTrSatisfied()` |
| `price-survey.rules.ts` | JAT-CMP-PRC | Pesquisa de Preços | `isPriceSurveySatisfied()` — valor ausente/inválido → partial |
| `budget-allocation.rules.ts` | JAT-CMP-DOT | Dotação Orçamentária | `isBudgetAllocationSatisfied()` |
| `legal-opinion.rules.ts` | JAT-CMP-PAR | Parecer Jurídico | `isLegalOpinionSatisfied()` |
| `budget-consistency.rules.ts` | JAT-CMP-VAL | Consistência orçamentária | Se ambos existem: `allocatedValue < estimatedValue` → partial + achado |

**Agregação**: `aggregateConformity()` — worst-of entre {conforme, partial, pending, non_conforme} (mesma severidade de ouvidoria).

**Status por artefato ausente**: checagem de completude → `pending` (demanda rascunho) ou `non_conforme`/`partial` conforme regra (spec US2 cenário 1).

**Rationale**: FR-010–FR-013; reutilizar mapper CRUD garante que status operativo derivado e fiscalização não divergem.

**Alternatives considered**:

- Duplicar lógica de satisfação em checks → rejeitado (drift vs 018)
- Uma checagem monolítica "Lei 14.133" → rejeitado (rastreio exige regra nomeada)

---

## R4 — Carga de dados para fiscalização

**Decision**: `LoadDemandasForFiscalizacaoRepository` — `findMany` demandas ativas com `include` idêntico a `demandaArtefactsInclude` de `demanda.repositories.ts` + `pca: { select: { id, title } }`.

**Rationale**: FR-001; uma query por execução; escala SC-002 (≤500 demandas).

**Alternatives considered**:

- N+1 por artefato → rejeitado (performance)

---

## R5 — Persistência, job, throttle

**Decision**: Copiar padrão `ouvidoria-fiscalizacao` inalterado:

- Job `@Cron` diário (`0 3 * * *`), origin `scheduled`
- Throttle 1h por tenant para `on_demand` e `on_record` (`shouldThrottleOrigin`)
- Conflito execução em andamento → 409 `FISCALIZACAO_RUNNING`
- Throttle → 429 `FISCALIZACAO_THROTTLED`
- `on_open` — **não** dispara execução automática nesta entrega (spec FR-007: exibe última concluída; job + manual cobrem refresh)

**Rationale**: Assumptions spec; paridade 016 R5.

---

## R6 — Questionários internos

**Decision**: **Não implementar** — fora de escopo explícito (spec Assumptions, Out of Scope). UI Compras **não** exibe `QuestionBankPanel` nem `QuestionnaireDialog`.

**Rationale**: Escopo limitado a checagens automáticas; reduz ~40% do surface Gabinete 016.

---

## R7 — Client: reutilizar componentes Ouvidoria

**Decision**: `ComprasFiscalizacaoPage` importa componentes Jatobá de `modules/ouvidoria/components/` com config:

```typescript
type ComprasFiscalizacaoConfig = {
  moduleId: 'compras';
  title: 'Fiscalização de Compras';
  entityColumnLabel: 'Demanda';
  pcaColumnLabel: 'PCA';
  artefactsColumnLabel: 'Artefatos fiscalizados';
  runButtonLabel: 'Fiscalizar demandas';
  apiBasePath: '/compras/fiscalizacao';
};
```

**Refactor mínimo** em `FiscalizacaoHistoryTable`: suportar colunas Compras (Demanda, PCA, Artefatos fiscalizados, Conformidade, Problemas) via props — **sem** colunas Questionário/Destinatário/Canal.

**Rationale**: Constitution V; ~800 LOC já provadas em ouvidoria/gabinete.

**Alternatives considered**:

- Mover para `modules/shared/` → adiado pós-MVP
- Copiar componentes → rejeitado

---

## R8 — Rota client: `/compras/fiscalizacao`

**Decision**: Migrar `screens.ts` de `/compras/auditoria` → `/compras/fiscalizacao`; redirect 301 client-side de `/compras/auditoria` → `/compras/fiscalizacao` por compatibilidade bookmarks.

**Rationale**: FR-019; checklist requirements confirma rota canônica.

**Alternatives considered**:

- Manter `/compras/auditoria` → rejeitado (conflito spec)

---

## R9 — Card contextual no hub da demanda

**Decision**: `ComprasFiscalizacaoRecordCard` em `DemandaHubPage` (`/compras/:demandaId`). Consome `GET /compras/fiscalizacao/demandas/:demandaId`. Título card: **Fiscalização Jatobá desta demanda** (spec US6). Ação scoped: `POST /compras/fiscalizacao/run/demandas/:demandaId`.

**Rationale**: FR-016; paridade Gabinete US8.

---

## R10 — Demanda excluída após fiscalização

**Decision**: Resultados históricos permanecem; painel/histórico exibe indicador *Registro indisponível* quando `demanda.deletedAt != null` na join ou demanda ausente — conformidade preservada do snapshot.

**Rationale**: Edge case spec.

---

## R11 — Testes sem Postgres dedicado

**Decision**: Mesma estratégia 008/016 — Jest unit para rules; fixtures JSON; Supertest e2e com deps mockadas; Vitest + MSW `handlers/compras-fiscalizacao.ts`.

**Rationale**: Constitution II; CI sem banco extra.

---

## Referências

- [008 research](../arquivados/008-ouvidoria-jatoba-fiscalizacao/research.md) — padrões base
- [016 research](../arquivados/016-gabinete-fiscalizacao-integrada/research.md) — paridade Jatobá
- [018 data-model](../arquivados/018-purchasing-crud/data-model.md) — artefatos e satisfação
- Código vivo: `ci-api-v2/src/modules/ouvidoria-fiscalizacao/`, `ci-api-v2/src/modules/compras/compras.mapper.ts`
