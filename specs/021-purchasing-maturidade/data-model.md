# Data Model: Maturidade Carvalho — Compras

**Feature**: 021-purchasing-maturidade · **Date**: 2026-06-25

> Campos Prisma/API em **inglês**; labels UI em **PT-BR** via mapper. Base operacional: [018-purchasing-crud/data-model.md](../arquivados/018-purchasing-crud/data-model.md). Fiscalização Jatobá: [019-purchasing-fiscalizacao/data-model.md](../019-purchasing-fiscalizacao/data-model.md).

## Schema novo: `compras-maturidade.prisma`

### Enums novos

```prisma
enum ComprasMaturityDimension {
  planejamento
  instrucao_processual
  conformidade
  resultados
}

enum ComprasMaturitySubmissionStatus {
  draft
  submitted
}
```

Reutiliza enums globais de `ouvidoria-maturidade.prisma`:

- `MaturityAssessmentFrequency` — default `quarterly`
- `MaturityQuestionType` — `scale_1_5 | yes_no | text`
- `MaturityPeriodStatus` — `open | closed`

---

### ComprasMaturidadeConfig

| Field EN | UI PT-BR | Required | Notes |
|----------|----------|----------|-------|
| `tenantId` | — | yes | PK |
| `assessmentFrequency` | Frequência | yes | default `quarterly` |
| `weightPlanejamento` | Peso Planejamento | yes | default 25 |
| `weightInstrucao` | Peso Instrução processual | yes | default 25 |
| `weightConformidade` | Peso Conformidade | yes | default 25 |
| `weightResultados` | Peso Resultados | yes | default 25 |
| `adequateThreshold` | Patamar Adequado | yes | default **60** (0–100) |
| `updatedAt` | — | yes | |

---

### ComprasMaturidadePeriod

| Field EN | Required | Notes |
|----------|----------|-------|
| `id` | yes | UUID |
| `tenantId` | yes | FK Tenant |
| `label` | yes | ex.: `"2026 Q2"` |
| `startsAt` | yes | UTC início trimestre |
| `endsAt` | yes | UTC fim trimestre |
| `status` | yes | `open \| closed` |
| `createdAt` | yes | |

**Índices**: `(tenantId, startsAt DESC)`, `(tenantId, status)`.

**Relations**: `submissions`, `snapshots`.

---

### ComprasMaturidadeQuestion

| Field EN | Required | Notes |
|----------|----------|-------|
| `id` | yes | UUID |
| `tenantId` | yes | |
| `dimension` | yes | `ComprasMaturityDimension` |
| `text` | yes | Text pergunta |
| `answerType` | yes | `MaturityQuestionType` |
| `weight` | yes | Int ≥ 1 |
| `required` | yes | default `true` |
| `active` | yes | default `true` |
| `sortOrder` | yes | ordem na dimensão |
| `createdAt` / `updatedAt` | yes | |

**Índices**: `(tenantId, dimension, active, sortOrder)`.

---

### ComprasMaturidadeSubmission

| Field EN | Required | Notes |
|----------|----------|-------|
| `id` | yes | UUID |
| `tenantId` | yes | |
| `periodId` | yes | FK Period |
| `status` | yes | `draft \| submitted` |
| `submittedByUserId` | no | null em draft inicial |
| `submittedAt` | no | null em draft |
| `scorePlanejamento` | no | 0–100; null se draft |
| `scoreInstrucao` | no | |
| `scoreConformidade` | no | híbrido quando Jatobá |
| `scoreResultados` | no | |
| `createdAt` / `updatedAt` | yes | |

**Unique**: `(periodId)` — 1 submission por período (draft ou submitted).

**Índices**: `(tenantId, periodId)`, `(tenantId, status)`.

---

### ComprasMaturidadeAnswer

| Field EN | Required | Notes |
|----------|----------|-------|
| `id` | yes | UUID |
| `submissionId` | yes | FK Submission |
| `questionId` | yes | FK Question |
| `value` | yes | Text raw (`"3"`, `"yes"`, texto livre) |
| `numericValue` | no | normalizado 0–100 para score |
| `createdAt` / `updatedAt` | yes | |

**Unique**: `(submissionId, questionId)`.

---

### ComprasMaturidadeScoreSnapshot

| Field EN | Required | Notes |
|----------|----------|-------|
| `id` | yes | UUID |
| `tenantId` | yes | |
| `periodId` | yes | FK Period |
| `submissionId` | yes | FK Submission submitted |
| `overallScore` | yes | 0–100 |
| `scorePlanejamento` | yes | |
| `scoreInstrucao` | yes | |
| `scoreConformidade` | yes | |
| `scoreResultados` | yes | |
| `partialSource` | yes | true se Jatobá ausente na Conformidade |
| `jatobaRunId` | no | FK `ComprasFiscalizacaoRun` quando usado |
| `tracePayload` | yes | JSON rastreio (fórmulas, checks agregados) |
| `computedAt` | yes | |

**Unique**: `(periodId)` — 1 snapshot vigente por período.

**Relation**: `jatobaRun ComprasFiscalizacaoRun?` — on delete **SetNull** (histórico preservado).

---

## Entidades derivadas (não persistidas)

### Orientação de melhoria

| Campo | Tipo | Notes |
|-------|------|-------|
| `dimension` | enum | |
| `dimensionLabel` | string | PT-BR |
| `score` | number | score dimensão |
| `adequateThreshold` | number | 60 default |
| `isBelowAdequate` | boolean | score < threshold |
| `title` | string | |
| `actions` | string[] | imperativo consultivo |
| `jatobaThemes` | string[]? | só Conformidade + Jatobá; agregado |

Gerada em runtime por `lib/improvement-orientations.ts` + mapper.

### Indicador operacional

| Campo | Tipo |
|-------|------|
| `type` | `artefact_funnel \| budget_inconsistency_rate \| licitation_conformity_rate` |
| `label` | string PT-BR |
| `value` | number |
| `unit` | `percent \| ratio` |
| `periodLabel` | string |

---

## State transitions

### Submission

```text
(none) → draft          PATCH answers (primeira resposta parcial)
draft → draft           PATCH answers (continuação)
draft → submitted       PUT self-assessment (validação OK)
submitted → submitted   PUT self-assessment (re-submit mesmo período — upsert scores)
```

### Period

```text
(open) criado por EnsureCurrentPeriod
open → closed           job futuro ou fim trimestre (v1: manual opcional; default open)
```

---

## Validações de negócio

| Regra | Enforcement |
|-------|-------------|
| Score global só com submission `submitted` | use-case compute |
| Perguntas `required=true` obrigatórias no PUT | Zod + use-case |
| `text` answers não entram no score numérico | self-assessment-score |
| Carvalho read-only sobre `Compra*` | sem FK write para demandas |
| Licença Carvalho expirada | guard bloqueia PUT/PATCH; GET histórico permitido |
| Re-submit mesmo período | upsert submission + snapshot; `submittedAt` atualizado |

---

## Relacionamentos cross-module (read-only)

```text
ComprasMaturidadeScoreSnapshot.jatobaRunId → ComprasFiscalizacaoRun
Compute indicators / hybrid → ComprasFiscalizacaoCheck (via run)
artefact_funnel → CompraDemanda + artefatos (compras.mapper.ts)
```

**Não** integrar com `CompraInsight*` (Cedro spec 020).
