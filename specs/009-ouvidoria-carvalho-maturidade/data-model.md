# Data Model: Maturidade Carvalho — Ouvidoria

**Feature**: 009-ouvidoria-carvalho-maturidade · **Date**: 2026-06-19

> Campos Prisma/API em **inglês**; labels UI em **PT-BR** via mapper. Fontes lidas: [003-ouvidoria](../../003-ouvidoria/data-model.md), [008 fiscalização](../../008-ouvidoria-jatoba-fiscalizacao/data-model.md).

## Entidades novas

### OuvidoriaMaturidadeConfig (config por tenant)

| Field EN | UI PT-BR | Required | Notes |
|----------|----------|----------|-------|
| `tenantId` | — | yes | PK |
| `assessmentFrequency` | Periodicidade | yes | enum, default `quarterly` |
| `axisWeightCi` | Peso CI | yes | Int, default 33 |
| `axisWeightGov` | Peso GOV | yes | Int, default 33 |
| `axisWeightTi` | Peso TI | yes | Int, default 34 |
| `updatedAt` | — | yes | |

---

### OuvidoriaMaturidadePeriod

| Field EN | UI PT-BR | Required | Notes |
|----------|----------|----------|-------|
| `id` | — | yes | UUID PK |
| `tenantId` | — | yes | |
| `label` | Período | yes | ex. *2026 Q2* |
| `startsAt` | Início | yes | DateTime |
| `endsAt` | Fim | yes | DateTime |
| `status` | Status | yes | enum `open` \| `closed` |
| `createdAt` | — | yes | |

**Índices**: `(tenantId, startsAt DESC)`, `(tenantId, status)`

---

### OuvidoriaMaturidadeQuestion

| Field EN | UI PT-BR | Required | Notes |
|----------|----------|----------|-------|
| `id` | — | yes | UUID PK |
| `tenantId` | — | yes | |
| `axis` | Eixo | yes | enum `MaturityAxis` |
| `text` | Pergunta | yes | Text |
| `answerType` | Tipo | yes | enum `MaturityQuestionType` |
| `weight` | Peso | yes | Int 1–100 |
| `isSatisfaction` | Satisfação | yes | Boolean default false |
| `active` | Ativa | yes | Boolean default true |
| `sortOrder` | Ordem | yes | Int |
| `createdAt` | — | yes | |
| `updatedAt` | — | yes | |

**Índices**: `(tenantId, axis, active, sortOrder)`

---

### OuvidoriaMaturidadeSubmission

| Field EN | UI PT-BR | Required | Notes |
|----------|----------|----------|-------|
| `id` | — | yes | UUID PK |
| `tenantId` | — | yes | |
| `periodId` | — | yes | FK → Period |
| `submittedByUserId` | Respondente | yes | FK → User |
| `submittedAt` | Data submissão | yes | DateTime |
| `scoreCi` | Nota CI | no | Int 0–100 calculado |
| `scoreGov` | Nota GOV | no | Int 0–100 |
| `scoreTi` | Nota TI | no | Int 0–100 |
| `createdAt` | — | yes | |
| `updatedAt` | — | yes | |

**Unique**: `(periodId)` — uma submissão por período (atualizável enquanto open)

---

### OuvidoriaMaturidadeAnswer

| Field EN | UI PT-BR | Required | Notes |
|----------|----------|----------|-------|
| `id` | — | yes | UUID PK |
| `submissionId` | — | yes | FK |
| `questionId` | — | yes | FK |
| `value` | Resposta | yes | Text (JSON string para checklist) |
| `numericValue` | Valor numérico | no | Int normalizado para score |
| `createdAt` | — | yes | |

**Índices**: `(submissionId)`

---

### OuvidoriaMaturidadeScoreSnapshot

| Field EN | UI PT-BR | Required | Notes |
|----------|----------|----------|-------|
| `id` | — | yes | UUID PK |
| `tenantId` | — | yes | |
| `periodId` | — | yes | FK |
| `overallScore` | Nota geral | no | Int 0–100 ou null |
| `scoreCi` | Nota CI | no | Int ou null |
| `scoreGov` | Nota GOV | no | Int ou null |
| `scoreTi` | Nota TI | no | Int ou null |
| `selfCi` | Autoavaliação CI | no | componente |
| `selfGov` | Autoavaliação GOV | no | |
| `selfTi` | Autoavaliação TI | no | |
| `jatobaCi` | Conformidade CI | no | componente |
| `jatobaGov` | Conformidade GOV | no | |
| `jatobaTi` | Conformidade TI | no | |
| `partialSource` | Fonte parcial | yes | Boolean |
| `jatobaRunId` | Execução Jatobá | no | FK opcional snapshot |
| `computedAt` | Calculado em | yes | DateTime |
| `tracePayload` | — | yes | JSON rastreio |

**Unique**: `(periodId)` — um snapshot vigente por período

---

### OuvidoriaMaturidadeActionPlan

| Field EN | UI PT-BR | Required | Notes |
|----------|----------|----------|-------|
| `id` | — | yes | UUID PK |
| `tenantId` | — | yes | |
| `title` | Título | yes | |
| `description` | Descrição | yes | Text |
| `axis` | Eixo | yes | enum `MaturityAxis` |
| `assigneeUserId` | Responsável | yes | FK → User |
| `dueDate` | Prazo | yes | DateTime |
| `status` | Status | yes | enum `ActionPlanStatus` |
| `criticality` | Criticidade | yes | enum `ActionPlanCriticality` |
| `linkedIndicator` | Indicador | no | enum opcional |
| `linkedFindingId` | Achado Jatobá | no | UUID opcional |
| `createdByUserId` | Criado por | yes | FK |
| `createdAt` | — | yes | |
| `updatedAt` | — | yes | |
| `statusChangedAt` | Status alterado | no | DateTime |

**Índices**: `(tenantId, status)`, `(tenantId, axis)`, `(tenantId, dueDate)`

---

### OuvidoriaMaturidadeActionPlanNote

| Field EN | UI PT-BR | Required | Notes |
|----------|----------|----------|-------|
| `id` | — | yes | UUID PK |
| `actionPlanId` | — | yes | FK |
| `text` | Nota | yes | Text |
| `authorUserId` | Autor | yes | FK |
| `createdAt` | Data | yes | DateTime |

**Índices**: `(actionPlanId, createdAt DESC)`

---

## Enums

### MaturityAxis

| Value EN | UI PT-BR |
|----------|----------|
| `controle_interno` | Controle Interno |
| `governanca` | Governança |
| `tecnologia_informacao` | Tecnologia da Informação |

### MaturityQuestionType

| Value EN | UI PT-BR |
|----------|----------|
| `scale_1_5` | Escala 1–5 |
| `yes_no` | Sim/Não |
| `text` | Descritiva |

### MaturityPeriodStatus

| Value EN | UI PT-BR |
|----------|----------|
| `open` | Aberto |
| `closed` | Encerrado |

### ActionPlanStatus

| Value EN | UI PT-BR |
|----------|----------|
| `pending` | Pendente |
| `in_progress` | Em andamento |
| `completed` | Concluído |
| `cancelled` | Cancelado |

### ActionPlanCriticality

| Value EN | UI PT-BR |
|----------|----------|
| `high` | Alta |
| `medium` | Média |
| `low` | Baixa |

### MaturityIndicatorType (API only, não persistido)

| Value EN | UI PT-BR |
|----------|----------|
| `volume` | Volume de manifestações |
| `avg_response_time` | Tempo médio de resposta |
| `overdue_rate` | Prazos vencidos |
| `resolution_rate` | Taxa de resolução |
| `satisfaction` | Satisfação |

---

## Entidades lidas (sem alteração)

| Entidade | Uso Carvalho |
|----------|--------------|
| `Manifestacao` | volume, taxa resolução, janela temporal |
| `ManifestacaoEvento` | tempo médio resposta (`response`) |
| `OuvidoriaFiscalizacaoRun` | última execução completed |
| `OuvidoriaFiscalizacaoResult` | base conformidade |
| `OuvidoriaFiscalizacaoCheck` | taxa por eixo, prazos vencidos |
| `OuvidoriaFiscalizacaoAnswer` | satisfação externa (quando existir) |
| `User` | responsável plano, respondente autoavaliação |

---

## State transitions

### ActionPlanStatus

```text
pending → in_progress → completed
pending → in_progress → cancelled
pending → cancelled
in_progress → cancelled
```

`completed` e `cancelled` são terminais.

### MaturityPeriodStatus

```text
open → closed (automático após endsAt ou manual admin v2)
```

Submissão permitida apenas em `open`.

---

## Validações de negócio

| Regra | Enforcement |
|-------|-------------|
| Score eixo indisponível sem submissão | use-case |
| Score geral null se &lt; 3 eixos válidos | `hybrid-score.ts` |
| `partialSource=true` sem jatobaRunId | mapper |
| Plano: `dueDate` ≥ hoje na criação | Zod + use-case |
| Achado link: finding deve existir no tenant | repository |
| PII: tracePayload nunca inclui requester fields | mapper + tests |

---

## Seed default (perguntas Carvalho Ouvidoria)

Mínimo 2 perguntas quantificáveis por eixo + 1 pergunta satisfação (`isSatisfaction=true`, eixo GOV ou CI):

- **CI**: aderência a processos internos; cumprimento de prazos institucionais
- **GOV**: transparência das respostas; clareza de comunicação com manifestante
- **TI**: uso de sistemas; qualidade de evidências digitais
- **Satisfação**: percepção geral de satisfação do cidadão (escala 1–5)

Ver `prisma/seed/seed-maturidade-questions.ts`.
