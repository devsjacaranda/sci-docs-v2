# Data Model: Desmock Tramitação (014)

**Feature**: 014-desmock-tramitacao · **Date**: 2026-06-24

> Campos Prisma/API em **inglês**; labels UI em **PT-BR** via mapper. Soft delete via extension Prisma (`deletedAt`).

## TramitacaoDemanda

Unidade central — inbox thread inter-setorial.

| Field EN | UI PT-BR | Required | Notes |
|----------|----------|----------|-------|
| `id` | — | yes | UUID |
| `tenantId` | — | yes | |
| `protocolNumber` | N.º protocolo | yes | `TRAM-{YYYY}-{NNNN}`; unique `(tenantId, protocolNumber)` |
| `subject` | Assunto | yes | VarChar 500 |
| `body` | Corpo | yes | Text — mensagem inicial |
| `originType` | Origem | yes | enum `TramitacaoDemandaOriginType` |
| `sourceModule` | Módulo origem | no | `ModuloSlug` quando linked |
| `sourceRecordId` | ID registro origem | no | UUID |
| `sourceSnapshot` | Snapshot origem | no | JSON imutável após create |
| `senderSectorId` | Setor remetente | yes | FK → `Setor` |
| `currentSectorId` | Setor atual | yes | FK → `Setor` — dono inbox Recebidas |
| `status` | Status operacional | yes | enum `TramitacaoDemandaStatus` |
| `deadline` | Prazo | no | DateTime |
| `archivedAt` | Arquivada em | no | set when archived |
| `createdByUserId` | Criador | no | |
| audit | — | yes | padrão plataforma |

**Relations**: `eventos`, `anexos`, `senderSector`, `currentSector`.

**originType values**:

- `generic` — composição sem linked record (`sourceModule` null)
- `linked` — criada por módulo externo ou com referência (`sourceModule` + `sourceRecordId` + `sourceSnapshot` obrigatórios)

---

## TramitacaoDemandaSequence

| Field EN | Required |
|----------|----------|
| `tenantId` | yes |
| `year` | yes |
| `nextNumber` | yes |

Unique `(tenantId, year)`.

---

## TramitacaoDemandaEvento

Timeline / thread.

| Field EN | UI PT-BR | Required |
|----------|----------|----------|
| `demandaId` | — | yes |
| `type` | Tipo | yes | enum `TramitacaoDemandaEventType` |
| `payload` | — | no | JSON — body reply, forward notes, status delta |
| `authorUserId` | Autor | no | |
| `authorSectorId` | Setor autor | no | FK Setor |
| `createdAt` | Data | yes | |

**Types**: `created`, `reply`, `forwarded`, `status_changed`, `archived`.

**Payload examples**:

```json
// reply
{ "body": "Texto da resposta" }

// forwarded
{ "fromSectorId": "uuid", "toSectorId": "uuid", "notes": "Justificativa" }

// status_changed
{ "from": "open", "to": "in_progress" }
```

---

## TramitacaoDemandaAnexo

| Field EN | Required | Notes |
|----------|----------|-------|
| `demandaId` | yes | |
| `eventoId` | no | vincula a resposta específica |
| `kind` | yes | `file` \| `link` |
| `fileName`, `mimeType`, `sizeBytes`, `storageKey` | if file | Wasabi |
| `url`, `title` | if link | |
| `attachedAt` | yes | |

`entityType` storage: `tramitacao_demanda`.

---

## Enums principais

### TramitacaoDemandaOriginType

`generic`, `linked`

### TramitacaoDemandaStatus (operacional Base)

`open`, `in_progress`, `answered`, `archived`

> Distinto de conformidade Jatobá. Transições validadas em use-case.

### TramitacaoDemandaEventType

`created`, `reply`, `forwarded`, `status_changed`, `archived`

### sourceModule (linked)

Valores v1: `gabinete`, `ouvidoria`, `juridico` (+ `generic` implícito quando null)

---

## Inbox query derivation (não persistido)

Parâmetro API: `folder` ∈ `received` | `sent` | `archived`; `sectorId` do setor ativo (header ou query).

| folder | Filtro Prisma |
|--------|---------------|
| `received` | `currentSectorId = sectorId` AND `status != archived` |
| `sent` | `senderSectorId = sectorId` AND `status != archived` AND `currentSectorId != sectorId` |
| `archived` | `status = archived` AND (`currentSectorId = sectorId` OR `senderSectorId = sectorId`) |

---

## Licenças — entidades (espelho Ouvidoria/Gabinete)

### Fiscalização (`tramitacao-fiscalizacao.prisma`)

- `TramitacaoFiscalizacaoRun`, `TramitacaoFiscalizacaoResult`, `TramitacaoFiscalizacaoCheck`, `TramitacaoFiscalizacaoFinding`
- `TramitacaoFiscalizacaoQuestion`, `TramitacaoFiscalizacaoQuestionnaire`, `TramitacaoFiscalizacaoAnswer`
- FK leitura: `TramitacaoDemanda`, eventos

### Maturidade (`tramitacao-maturidade.prisma`)

- `TramitacaoMaturidadePeriod`, `TramitacaoMaturidadeQuestion`, `TramitacaoMaturidadeSelfAssessment`, `TramitacaoMaturidadeScore`, `TramitacaoMaturidadeActionPlan`, …

### Insights (`tramitacao-insights.prisma`)

- `TramitacaoInsightBatch`, `TramitacaoInsight`, `TramitacaoInsightEvidence`

---

## Índices recomendados

- `TramitacaoDemanda`: `(tenantId, currentSectorId, status)`, `(tenantId, senderSectorId)`, `(tenantId, protocolNumber)`, `(tenantId, createdAt)`, `(sourceModule, sourceRecordId)`
- `TramitacaoDemandaEvento`: `(demandaId, createdAt)`

---

## State transitions (operacional — resumo)

```text
open → in_progress → answered → archived
  ↘ forwarded (event) → currentSectorId changes; status may stay in_progress
archived — terminal (no forward/reply without unarchive P2)
```

Validação em `forward-demanda.use-case.ts`, `archive-demanda.use-case.ts`.

---

## Snapshot schema (por módulo origem)

Snapshots são JSON livre mas com chaves mínimas para UI:

| sourceModule | Campos mínimos snapshot |
|--------------|-------------------------|
| `gabinete` | `protocolNumber`, `subject`, `status`, `description` |
| `ouvidoria` | `protocolNumber`, `type`, `status`, `summary` |
| `juridico` | `protocolNumber`, `processType`, `status`, `partiesSummary` |

Construídos por mapper no módulo origem no momento da tramitação.
