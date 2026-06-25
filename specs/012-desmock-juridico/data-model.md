# Data Model: Desmock Jurídico (012)

**Feature**: 012-desmock-juridico · **Date**: 2026-06-23

> Campos Prisma/API em **inglês**; labels UI em **PT-BR** via mapper. Soft delete via extension Prisma (`deletedAt`).

## LegalProcess

Registro central do módulo Jurídico.

| Field EN | UI PT-BR | Required | Notes |
|----------|----------|----------|-------|
| `id` | — | yes | UUID |
| `tenantId` | — | yes | |
| `internalNumber` | Número | no until confirm | unique `(tenantId, internalNumber)`; gerado na confirmação |
| `type` | Tipo | yes | enum `LegalProcessType` |
| `subject` | Assunto/título | no | |
| `judicialNumber` | Número judicial/CNJ | no | |
| `judicialNumberNeedsReview` | — | no | default false; true se CNJ inválido |
| `observations` | Observações | no | Text |
| `deadlineAt` | Prazo processual | no | DateTime |
| `causeValue` | Valor da causa | no | Decimal(15,2) |
| `internalResponsible` | Responsável interno | no | texto livre ou FK User futuro |
| `sphere` | Esfera | no | enum `LegalProcessSphere` |
| `courtOrAgency` | Tribunal/órgão | no | |
| `districtOrSection` | Comarca/seção | no | |
| `courtUnit` | Vara/juízo | no | |
| `status` | Status | yes | enum `LegalProcessStatus`; default `draft` |
| `confirmedAt` | — | no | set on confirm |
| `createdByUserId` | — | yes | FK User |
| audit | — | yes | createdAt, updatedAt, deletedAt |

**Relations**: `parties LegalProcessParty[]`, `attachments LegalProcessAttachment[]`, `events LegalProcessEvent[]`, fiscalizacao results, questionnaires.

---

## LegalProcessSequence

| Field EN | Required |
|----------|----------|
| `tenantId` | yes |
| `year` | yes |
| `lastNumber` | yes | default 0 |

PK `(tenantId, year)`.

---

## LegalProcessParty

| Field EN | UI PT-BR | Required | Notes |
|----------|----------|----------|-------|
| `processId` | — | yes | FK |
| `role` | Polo | yes | enum `LegalProcessPartyRole` |
| `personType` | Tipo pessoa | no | enum `LegalProcessPersonType` |
| `name` | Nome | no | |
| `document` | CPF/CNPJ | no | |
| `email` | E-mail | no | questionário externo |
| `phone` | Telefone | no | questionário externo |
| `addressId` | Endereço | no | FK → Address |
| `sortOrder` | — | yes | Int default 0 |

Todos os campos de identificação **opcionais** — pelo menos `role` obrigatório para linha existir.

---

## LegalProcessAttachment

| Field EN | Required | Notes |
|----------|----------|-------|
| `processId` | yes | |
| `kind` | yes | `file` \| `link` (v1: só file) |
| `fileName` | yes | |
| `mimeType` | no | |
| `sizeBytes` | no | max 30 MB |
| `storageKey` | no | Wasabi |
| `uploadConfirmed` | yes | default false |
| `uploadedByUserId` | yes | |

---

## LegalProcessEvent

Timeline (padrão `ManifestacaoEvento`).

| Field EN | UI PT-BR | Required |
|----------|----------|----------|
| `processId` | — | yes |
| `type` | Tipo | yes | enum `LegalProcessEventType` |
| `title` | Título | yes | |
| `description` | Descrição | yes | Text |
| `authorUserId` | Autor | no | |
| `createdAt` | Data | yes | |

Types: `registration`, `opinion`, `revision`, `forwarding`, `justification`, `note`, `update`.

Evento `opinion` alimenta KPI **Pareceres (mês)** no dashboard.

---

## Enums principais

### LegalProcessType

| Value EN | UI PT-BR |
|----------|----------|
| `administrative` | Administrativo |
| `judicial` | Judicial |
| `advisory` | Consultivo |

### LegalProcessStatus

| Value EN | UI PT-BR (operacional) |
|----------|------------------------|
| `draft` | Rascunho |
| `open` | Aberto |
| `expiring` | Vencendo |
| `critical` | Crítico |
| `completed` | Concluído |

Nota: `expiring`/`critical` podem ser calculados na camada API/mapper além do persistido.

### LegalProcessSphere

`federal`, `state`, `municipal`, `internal_administrative`

### LegalProcessPartyRole

`active`, `passive`, `other`

### LegalProcessPersonType

`individual`, `legal_entity`, `government_entity`

### LossProbabilityBand

`low`, `medium`, `high`, `undetermined` — UI: Baixa, Média, Alta, Indeterminada

---

## Jurídico Fiscalização (espelho 008)

Prefixo tabelas `JuridicoFiscalizacao*`:

- **Run** — execução (origin, startedAt, finishedAt, recordsAnalyzed, summary JSON)
- **Result** — por processo: `processId`, `conformity`, **`lossProbabilityBand`**, **`lossProbabilityScore`**
- **Check** — ruleSlug, conformity, tracePayload JSON
- **Finding** — título, descrição, checkId
- **Question**, **Questionnaire**, **Answer** — banco + instâncias

Sem SLA por tipo (Ouvidoria) — prazo manual `deadlineAt` no processo.

---

## Jurídico Insights (espelho 007)

- **JuridicoInsightBatch** — lote geração
- **JuridicoInsight** — title, summary, recommendation, impact, category, rulesApplied
- **JuridicoInsightEvidence** — processId opcional, internalNumber snapshot, snapshotFields JSON sem PII excessivo

---

## Jurídico Maturidade (espelho 009)

- **JuridicoMaturidadePeriod**, **SelfAssessment**, **SelfAssessmentAnswer**
- **JuridicoMaturidadeScore** — eixo CI/GOV/TI + overall
- **JuridicoActionPlan**, **JuridicoActionPlanNote**

---

## Relacionamentos cross-module

| Entidade | Relação |
|----------|---------|
| `Address` | FK opcional em `LegalProcessParty` |
| `User` | createdBy, event author, uploadedBy |
| `Tenant` | isolamento |
| `Setor` | permissão via ModuloSetor (DEJUR) — sem FK direta no processo v1 |

---

## Índices recomendados

- `LegalProcess`: `(tenantId, status)`, `(tenantId, type)`, `(tenantId, internalNumber)` unique
- `LegalProcessEvent`: `(processId, createdAt)`
- `JuridicoFiscalizacaoResult`: `(runId, processId)`

---

## Seed demo (Jacaranda)

Mínimo 6 processos confirmados:

| internalNumber | type | status derivado | loss band esperado |
|----------------|------|-----------------|-------------------|
| JUR-2026-0001 | judicial | critical | alta |
| JUR-2026-0002 | administrative | open | média |
| JUR-2026-0003 | advisory | completed | baixa |
| JUR-2026-0004 | judicial | expiring | média |
| JUR-2026-0005 | administrative | open | indeterminada (sem prazo) |
| JUR-2026-0006 | judicial | open | alta (sem CNJ, sem anexo) |
