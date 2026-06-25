# Data Model: Fiscalização Jatobá — Ouvidoria

**Feature**: 008-ouvidoria-jatoba-fiscalizacao · **Date**: 2026-06-19

> Campos Prisma/API em **inglês**; labels UI em **PT-BR** via mapper. Fonte canônica de manifestações: [003-ouvidoria/data-model.md](../../003-ouvidoria/data-model.md).

## Entidades novas

### OuvidoriaFiscalizacaoRun (execução)

| Field EN | UI PT-BR | Required | Notes |
|----------|----------|----------|-------|
| `id` | — | yes | UUID PK |
| `tenantId` | — | yes | multi-tenant |
| `startedAt` | Início | yes | DateTime |
| `completedAt` | Conclusão | no | null while running |
| `origin` | Origem | yes | enum `FiscalizacaoRunOrigin` |
| `status` | Status | yes | enum `FiscalizacaoRunStatus` |
| `recordsAnalyzed` | Registros analisados | yes | Int ≥ 0 |
| `conformeCount` | Conformes | yes | Int |
| `nonConformeCount` | Não conformes | yes | Int |
| `partialCount` | Parciais | yes | Int |
| `pendingCount` | Pendentes | yes | Int |
| `scopedManifestacaoId` | — | no | set when `origin = on_record` |
| `errorMessage` | — | no | if failed |
| `createdAt` | — | yes | |

**Índices**: `(tenantId, startedAt DESC)`, `(tenantId, origin, startedAt)`

---

### OuvidoriaFiscalizacaoResult (resultado por manifestação)

| Field EN | UI PT-BR | Required | Notes |
|----------|----------|----------|-------|
| `id` | — | yes | UUID PK |
| `tenantId` | — | yes | |
| `runId` | — | yes | FK → Run |
| `manifestacaoId` | — | yes | FK → Manifestacao |
| `protocol` | Manifestação | yes | snapshot |
| `conformityStatus` | Conformidade | yes | enum `ConformityStatus` |
| `fiscalizedDataSummary` | Dados fiscalizados | yes | Text curto (ex.: "Prazo e qualidade da resposta") |
| `problemsSummary` | Problemas | no | Text — achados concatenados ou "—" |
| `createdAt` | — | yes | |

**Índices**: `(runId)`, `(tenantId, manifestacaoId, runId)`, `(protocol)`

**Unique**: `(runId, manifestacaoId)`

---

### OuvidoriaFiscalizacaoCheck (checagem automática)

| Field EN | UI PT-BR | Required | Notes |
|----------|----------|----------|-------|
| `id` | — | yes | UUID PK |
| `tenantId` | — | yes | |
| `resultId` | — | yes | FK → Result |
| `ruleId` | — | yes | ex.: `JAT-OUV-PRZ-001` |
| `label` | Campo | yes | ex.: "Prazo de resposta" |
| `ruleDescription` | Regra | yes | Text |
| `conformityStatus` | Resultado | yes | enum |
| `tracePayload` | — | yes | JSON — steps, fieldsEvaluated, slaDays, deadlineAt |
| `createdAt` | — | yes | |

**Índices**: `(resultId)`

---

### OuvidoriaFiscalizacaoFinding (achado)

| Field EN | UI PT-BR | Required | Notes |
|----------|----------|----------|-------|
| `id` | — | yes | UUID PK |
| `tenantId` | — | yes | |
| `resultId` | — | yes | FK → Result |
| `checkId` | — | no | FK opcional → Check |
| `title` | Título | yes | |
| `description` | Descrição | yes | Text |
| `conformityStatus` | Status | yes | enum |
| `tracePayload` | — | yes | JSON |
| `createdAt` | — | yes | |

**Índices**: `(resultId)`

---

### OuvidoriaFiscalizacaoSlaConfig

| Field EN | UI PT-BR | Required | Notes |
|----------|----------|----------|-------|
| `tenantId` | — | yes | FK |
| `manifestacaoType` | Tipo | yes | enum ManifestacaoTipo |
| `daysLimit` | Dias SLA | yes | Int > 0 |
| `updatedAt` | — | yes | |

**PK**: `(tenantId, manifestacaoType)`

**Defaults seed** (dias corridos):

| Type | daysLimit |
|------|-----------|
| `complaint` | 30 |
| `request` | 30 |
| `whistleblower` | 60 |
| `praise` | 15 |
| `suggestion` | 15 |
| `simplify` | 15 |

---

### OuvidoriaFiscalizacaoQuestion (banco de perguntas)

| Field EN | UI PT-BR | Required | Notes |
|----------|----------|----------|-------|
| `id` | — | yes | UUID PK |
| `tenantId` | — | yes | |
| `text` | Pergunta | yes | Text |
| `answerType` | Tipo | yes | enum `QuestionAnswerType` |
| `allowedAudience` | Destinatário | yes | enum `QuestionAudience` |
| `active` | Ativa | yes | Boolean default true |
| `sortOrder` | Ordem | yes | Int |
| `createdAt` | — | yes | |
| `updatedAt` | — | yes | |

**Índices**: `(tenantId, active, sortOrder)`

---

### OuvidoriaFiscalizacaoQuestionnaire

| Field EN | UI PT-BR | Required | Notes |
|----------|----------|----------|-------|
| `id` | — | yes | UUID PK |
| `tenantId` | — | yes | |
| `manifestacaoId` | — | yes | FK |
| `protocol` | — | yes | snapshot |
| `title` | Questionário | yes | |
| `audience` | Destinatário | yes | `internal` \| `external` |
| `channel` | Canal | yes | enum `QuestionnaireChannel` |
| `flowState` | Fluxo | yes | enum `QuestionnaireFlowState` |
| `responseTokenHash` | — | no | bcrypt — só external |
| `dispatchedAt` | — | no | when link generated |
| `createdByUserId` | — | yes | FK User |
| `createdAt` | — | yes | |
| `respondedAt` | — | no | |

**Índices**: `(tenantId, manifestacaoId)`, `(responseTokenHash)` sparse

---

### OuvidoriaFiscalizacaoQuestionnaireItem

| Field EN | UI PT-BR | Required | Notes |
|----------|----------|----------|-------|
| `id` | — | yes | UUID PK |
| `questionnaireId` | — | yes | FK |
| `questionId` | — | no | FK nullable (ad hoc) |
| `text` | Pergunta | yes | snapshot |
| `answerType` | Tipo | yes | enum |
| `sortOrder` | — | yes | Int |

---

### OuvidoriaFiscalizacaoAnswer

| Field EN | UI PT-BR | Required | Notes |
|----------|----------|----------|-------|
| `id` | — | yes | UUID PK |
| `questionnaireId` | — | yes | FK |
| `itemId` | — | yes | FK → Item |
| `value` | Resposta | yes | Text ou JSON |
| `respondedByUserId` | — | no | internal |
| `respondedAt` | — | yes | DateTime |

---

## Enums

### FiscalizacaoRunOrigin

| Value EN | UI PT-BR |
|----------|----------|
| `scheduled` | Agendada |
| `on_demand` | Sob demanda |
| `on_open` | Ao abrir |
| `on_record` | Por registro |

### FiscalizacaoRunStatus

| Value EN | UI PT-BR |
|----------|----------|
| `running` | Em processamento |
| `completed` | Concluída |
| `failed` | Falhou |

### ConformityStatus

| Value EN | UI PT-BR |
|----------|----------|
| `conforme` | Conforme |
| `non_conforme` | Não conforme |
| `partial` | Parcial |
| `pending` | Pendente |

### QuestionAnswerType

| Value EN | UI PT-BR |
|----------|----------|
| `yes_no` | Sim/Não |
| `scale_1_5` | Escala 1-5 |
| `text` | Descritiva |
| `checklist` | Checklist |

### QuestionAudience

| Value EN | UI PT-BR |
|----------|----------|
| `internal` | Interno |
| `external` | Externo |
| `both` | Ambos |

### QuestionnaireChannel

| Value EN | UI PT-BR |
|----------|----------|
| `portal` | Portal interno |
| `whatsapp` | WhatsApp |
| `email` | E-mail |

### QuestionnaireFlowState

| Value EN | UI PT-BR |
|----------|----------|
| `not_started` | Não iniciado |
| `awaiting_internal` | Aguardando resposta interna |
| `awaiting_external` | Aguardando resposta externa |
| `responded` | Respondido |

> **Nota**: labels UI de fluxo **nunca** usados como badge de conformidade (FR-004).

---

## Entidades lidas (sem alteração)

- `Manifestacao`, `ManifestacaoEvento`, `ManifestacaoAnexo`, `Address`, `User`, `Setor`

**Filtro de fiscalização**: `status != draft`, `deletedAt IS NULL`.

---

## Relacionamentos (diagrama)

```text
Run 1──* Result 1──* Check
              └──* Finding
Manifestacao 1──* Result (via run snapshots)
Manifestacao 1──* Questionnaire 1──* Item 1──* Answer
Question *── optional ── QuestionnaireItem
Tenant 1──* SlaConfig
Tenant 1──* Question (bank)
```

---

## Regras de validação

- Run `completed` exige `completedAt` e soma de counts = `recordsAnalyzed`
- Result.conformityStatus = aggregate(checks) na mesma execução
- Questionnaire `external` exige manifestação identificável com contato
- Questionnaire `external` exige `responseTokenHash` após dispatch
- Answers só quando `flowState` permite (not responded yet)
- Fiscalização **nunca** escreve em `Manifestacao` / `ManifestacaoEvento`

---

## Histórico do painel (tabela UI)

Cada linha do histórico combina **Result** + **Questionnaire** mais recente (left join):

| Coluna UI | Fonte |
|-----------|-------|
| Manifestação | `result.protocol` |
| Dados fiscalizados | `result.fiscalizedDataSummary` |
| Questionário | `questionnaire.title` ou "—" |
| Destinatário | `audience` → Interno/Externo |
| Canal | `channel` label |
| Conformidade | `result.conformityStatus` badge |
| Problemas | `result.problemsSummary` |
