# Data Model: Desmock Gabinete (012)

**Feature**: 012-desmock-gabinete · **Date**: 2026-06-23

> Campos Prisma/API em **inglês**; labels UI em **PT-BR** via mapper. Soft delete via extension Prisma (`deletedAt`).

## CabinetProtocolo

Documento protocolado de entrada (v1 `Protocolo`).

| Field EN | UI PT-BR | Required | Notes |
|----------|----------|----------|-------|
| `id` | — | yes | UUID |
| `tenantId` | — | yes | |
| `internalNumber` | N.º Gabinete | no | v1 `numero` |
| `sigedNumber` | N.º SIGED | no | v1 `numeroSiged` |
| `entryMode` | Forma de entrada | no | enum `CabinetEntryMode` |
| `sender` | Remetente | no | v1 `remetente` |
| `protocolDate` | Data de protocolo | no | DateTime |
| `receiptTime` | Hora de recebimento | no | String "HH:mm" |
| `subject` | Assunto | no | VarChar 500 |
| `documentType` | Tipo de documento | no | |
| `summary` | Descrição resumida | no | Text |
| audit | criado/atualizado/deletado | yes | padrão plataforma |

**Relations**: `demandas CabinetDemanda[]`; anexos; controles opcionais.

**Wasabi**: anexos via `CabinetProtocoloAnexo` (`entityType=cabinet_protocolo`).

---

## CabinetDemanda

Registro central — *ata* (v1 `Demanda`).

| Field EN | UI PT-BR | Required | Notes |
|----------|----------|----------|-------|
| `id` | — | yes | UUID |
| `tenantId` | — | yes | |
| `protocolNumber` | N.º protocolo | yes | gerado; unique `(tenantId, protocolNumber)` |
| `subject` | Assunto | yes | |
| `description` | Descrição | yes | Text |
| `origin` | Origem | no | enum `CabinetDemandaOrigin`, default `internal` |
| `currentSector` | Setor atual | no | enum `CabinetDemandaSector`, default `gabinete` |
| `sectorId` | Setor (cadastro) | no | FK → `Setor` |
| `status` | Status | yes | enum `CabinetDemandaStatus` |
| `sourceModule` | Módulo origem | no | ex. `ouvidoria` |
| `manifestationId` | Manifestação vinculada | no | FK opcional → `Manifestacao` |
| `protocoloId` | Protocolo vinculado | no | FK → `CabinetProtocolo` |
| `entryDate` | Data de entrada | yes | default now |
| `concessionaireDeadline` | Prazo concessionária | no | |
| `concessionaireResponseDate` | Data resposta concessionária | no | |
| `forwardings` | Encaminhamentos | no | JSON array `{sectorId, userId, at, notes}` |
| audit | — | yes | |

**Relations**: eventos, anexos, controles, documentos tramitados.

---

## CabinetDemandaSequence

| Field EN | Required |
|----------|----------|
| `tenantId` | yes |
| `year` | yes |
| `nextNumber` | yes |

Unique `(tenantId, year)`.

---

## CabinetDemandaEvento

Timeline (padrão `ManifestacaoEvento`).

| Field EN | UI PT-BR | Required |
|----------|----------|----------|
| `demandaId` | — | yes |
| `type` | Tipo evento | yes | enum `CabinetDemandaEventType` |
| `payload` | — | no | JSON |
| `authorUserId` | Autor | no | |
| `createdAt` | Data | yes | |

Types: `created`, `updated`, `forwarded`, `status_changed`, `attachment_added`.

---

## CabinetDemandaAnexo / CabinetProtocoloAnexo

| Field EN | Required | Notes |
|----------|----------|-------|
| `demandaId` / `protocoloId` | yes | |
| `kind` | yes | `file` \| `link` |
| `fileName`, `mimeType`, `sizeBytes`, `storageKey` | if file | |
| `url`, `title` | if link | |
| `attachedAt` | yes | |

---

## CabinetDocumentoTramitado

Unificado (v1 N tabelas por setor).

| Field EN | UI PT-BR | Required | Notes |
|----------|----------|----------|-------|
| `setorId` | Setor | **yes** | FK Setor |
| `demandaId` | Demanda | no | |
| `protocoloId` | Protocolo | no | |
| `groupId` | Grupo | no | UUID sem FK |
| `quantity` | Qtde | no | |
| `protocolDate` | Data prot. | no | |
| `protocolNumber` | N.º protocolo | no | |
| `protocolType` | Tipo protocolo | no | |
| `sigedNumber` | N.º SIGED | no | |
| `dispatchDate` | Data despacho | no | |
| `document` | Documento | no | Text |
| `requester` | Requerente | no | |
| `subject` | Assunto | no | |
| `deadline` | Prazo | no | String |
| `notes` | Observação | no | Text |

---

## CabinetControleNumerico

| Field EN | UI PT-BR | Required |
|----------|----------|----------|
| `documentType` | Tipo | yes | enum 6 tipos |
| `demandaId`, `protocoloId` | Vínculos | no | |
| `groupId` | Grupo | no | |
| `number` | Número | no | Int |
| `date` | Data | no | |
| `agency` | Órgão | no | |
| `addressee` | Endereçado | no | |
| `history` | Histórico | no | Text |
| `subject` | Assunto | no | |
| `requester` | Solicitante | no | |
| `formalizedBy` | Formalizado por | no | |
| `draftedBy` | Minutado por | no | |

---

## CabinetControleNotificacao

| Field EN | UI PT-BR | Required |
|----------|----------|----------|
| `demandaId`, `protocoloId` | — | no | |
| `groupId` | Grupo notif/auto | no | |
| `order` | Ord | no | |
| `notificationTerm` | Termo de notificação | no | |
| `addressee` | Destinatário | no | |
| `issuedBy` | Emitido por | no | |
| `technicalReport` | Relatório/parecer técnico | no | |
| `triggeringFact` | Fato gerador | no | |
| `agemanProcess` | Processo AGEMAN | no | |
| `concessionaireProtocolDate` | Data prot. concessionária | no | |
| `deadline` | Prazo | no | |
| `dueDate` | Vencimento | no | |
| `response` | Resposta | no | Text |
| `situation` | Situação | no | |

---

## CabinetControleAutoInfracao

| Field EN | UI PT-BR | Required |
|----------|----------|----------|
| `demandaId`, `protocoloId` | — | no | |
| `groupId` | Grupo | no | |
| `order` | Ord | no | |
| `document` | Documento | no | Text |
| `addressee` | Destinatário | no | |
| `issuingSector` | Setor emissor | no | |
| `opinionDispatch` | Parecer/despacho | no | Text |
| `subject` | Assunto | no | |
| `amount` | Valor | no | Decimal |
| `agemanProcess` | Processo AGEMAN | no | |
| `protocolNumber` | N.º protocolo | no | |
| `deadline` | Prazo | no | |
| `dueDate` | Vencimento | no | |
| `response` | Resposta | no | Text |

---

## Enums principais

### CabinetEntryMode

`in_person`, `email`, `siged`

### CabinetDemandaOrigin

`email`, `in_person`, `internal`, `phone`, `whatsapp`, `official_letter`, `virtual_protocol`

### CabinetDemandaSector

`gabinete`, `ouvidoria`, `dejur`, `technical_support`, `economy_directorate`, `technical_directorate`, `concessionaire`

### CabinetDemandaStatus

`draft`, `awaiting_receipt`, `received`, `in_analysis`, `awaiting_concessionaire`, `concessionaire_responded_on_time`, `concessionaire_responded_late`, `concessionaire_no_response`, `awaiting_report`, `report_completed`, `awaiting_dosimetry`, `dosimetry_completed`, `awaiting_infraction_notice`, `infraction_notice_issued`, `in_transit`, `finished`, `archived`, `returned_ouvidoria`, `returned_gabinete`

### CabinetControleNumericoTipo

`oficio`, `oficio_circular`, `portaria`, `memorando`, `memorando_circular`, `resolucao`

---

## Licenças — entidades (espelho Ouvidoria)

### Fiscalização (`gabinete-fiscalizacao.prisma`)

- `GabineteFiscalizacaoRun`, `GabineteFiscalizacaoResult`, `GabineteFiscalizacaoCheck`, `GabineteFiscalizacaoFinding`
- `GabineteFiscalizacaoQuestion`, `GabineteFiscalizacaoQuestionnaire`, `GabineteFiscalizacaoAnswer`
- `GabineteFiscalizacaoSlaConfig` (opcional v1 — prazos por status/tipo demanda)

FK leitura: `CabinetDemanda`, eventos, controles.

### Maturidade (`gabinete-maturidade.prisma`)

- `GabineteMaturidadePeriod`, `GabineteMaturidadeQuestion`, `GabineteMaturidadeSelfAssessment`, `GabineteMaturidadeScore`, `GabineteMaturidadeActionPlan`, …

### Insights (`gabinete-insights.prisma`)

- `GabineteInsightBatch`, `GabineteInsight`, `GabineteInsightEvidence`

---

## Índices recomendados

- `CabinetDemanda`: `(tenantId, status)`, `(tenantId, protocolNumber)`, `(tenantId, entryDate)`, `(sectorId)`
- `CabinetProtocolo`: `(tenantId, protocolDate)`
- `CabinetDocumentoTramitado`: `(tenantId, setorId)`, `(demandaId)`, `(groupId)`
- Controles: `(tenantId, demandaId)`, `(tenantId, protocoloId)`

---

## State transitions (Demanda — resumo)

```text
draft → received → in_analysis ⇄ in_transit → finished → archived
         ↘ awaiting_concessionaire → … → in_transit
```

Validação em `transition-demanda-status.use-case.ts`; **Tramitar** força `in_transit` se permitido.
