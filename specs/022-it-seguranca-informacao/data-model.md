# Data Model: Módulo IT — Segurança da Informação

**Feature**: 022-it-seguranca-informacao · **Date**: 2026-06-25

> Campos Prisma/API em **inglês**; labels UI em **PT-BR** via mapper. Referência estrutural: [018-purchasing-crud/data-model.md](../arquivados/018-purchasing-crud/data-model.md), [019-purchasing-fiscalizacao/data-model.md](../019-purchasing-fiscalizacao/data-model.md).

## Schema: `it.prisma` (Base)

### Enums

```prisma
enum ItAssetType {
  server
  workstation
  software_license
  database
  system
}

enum ItAssetLinkType {
  hosts
  uses
  depends_on
}

enum ItIncidentSeverity {
  low
  moderate
  critical
}

enum ItIncidentStatus {
  open
  resolved
}

enum ItDefenseLine {
  antivirus_operator      // Linha 1
  internal_control        // Linha 2
  external_audit          // Linha 3
}

enum ItOperatorRole {
  controller
  operator
  sub_operator
}

enum ItBackupAuditStatus {
  ok
  alerta
  vermelho
}
```

### ItAsset

| Field EN | UI PT-BR | Required | Notes |
|----------|----------|----------|-------|
| `id` | — | yes | UUID |
| `tenantId` | — | yes | FK Tenant |
| `type` | Tipo | yes | `ItAssetType` |
| `name` | Nome | yes | |
| `identifier` | Identificador | yes | hostname, serial, etc. |
| `setorId` | Secretaria responsável | yes | FK Setor |
| `description` | Descrição | no | |
| `containsSensitiveData` | Contém dados sensíveis | yes | default `false` |
| `backupAuditStatus` | Status backup | no | só `server`; default `ok` |
| `createdByUserId` | — | yes | |
| `deletedAt` | — | no | soft delete |
| `createdAt` / `updatedAt` | — | yes | |

**Índices**: `(tenantId, type, deletedAt)`, `(tenantId, setorId)`, `(tenantId, name)`.

**Relations**: `tags`, `linksFrom`, `linksTo`, `incidents`, `dataDictionary`, `configAnalyses`.

---

### ItAssetTag

| Field EN | Required | Notes |
|----------|----------|-------|
| `id` | yes | UUID |
| `assetId` | yes | FK ItAsset |
| `label` | yes | ex.: `producao`, `legacy` |

**Unique**: `(assetId, label)`.

---

### ItAssetLink

| Field EN | Required | Notes |
|----------|----------|-------|
| `id` | yes | UUID |
| `tenantId` | yes | |
| `fromAssetId` | yes | ex.: servidor |
| `toAssetId` | yes | ex.: sistema |
| `linkType` | yes | `ItAssetLinkType` |

**Unique**: `(fromAssetId, toAssetId, linkType)`.

---

### ItIncident

| Field EN | UI PT-BR | Required | Notes |
|----------|----------|----------|-------|
| `id` | — | yes | UUID |
| `tenantId` | — | yes | |
| `occurredAt` | Data | yes | |
| `severity` | Criticidade | yes | `ItIncidentSeverity` |
| `threatType` | Tipo de ameaça | yes | string |
| `setorId` | Secretaria afetada | yes | FK Setor |
| `assetId` | Ativo vinculado | no | FK ItAsset |
| `description` | Descrição | yes | |
| `errorLogs` | Logs de erro | no | text |
| `status` | Status | yes | `open \| resolved` |
| `resolvedAt` | — | no | obrigatório se resolved |
| `resolvedByDefenseLine` | Resolvido por | no | `ItDefenseLine`; obrigatório se resolved |
| `createdByUserId` | — | yes | |
| `deletedAt` | — | no | soft delete |
| `createdAt` / `updatedAt` | — | yes | |

**Índices**: `(tenantId, status)`, `(tenantId, severity)`, `(tenantId, setorId)`.

---

### ItDataDictionary

Metadados de colunas para banco de dados (classificador LGPD).

| Field EN | Required | Notes |
|----------|----------|-------|
| `id` | yes | UUID |
| `assetId` | yes | FK ItAsset (`database`) |
| `tableName` | yes | |
| `columnName` | yes | |
| `description` | no | |

**Unique**: `(assetId, tableName, columnName)`.

---

### ItSensitiveDataCategory

| Field EN | UI PT-BR | Required | Notes |
|----------|----------|----------|-------|
| `id` | yes | UUID |
| `tenantId` | yes | |
| `code` | Código | yes | ex.: `cpf`, `health`, `financial` |
| `label` | Nome | yes | ex.: *CPF*, *Dados de saúde* |

**Unique**: `(tenantId, code)`.

---

### ItOperatorTreatment

| Field EN | Required | Notes |
|----------|----------|-------|
| `id` | yes | UUID |
| `tenantId` | yes | |
| `operatorName` | yes | interno ou terceiro |
| `operatorRole` | yes | `ItOperatorRole` |
| `isExternal` | yes | default false |
| `assetId` | yes | FK ItAsset (`system`) |

**Relations**: `categories ItOperatorCategory[]`.

---

### ItOperatorCategory

| Field EN | Required | Notes |
|----------|----------|-------|
| `id` | yes | UUID |
| `treatmentId` | yes | FK ItOperatorTreatment |
| `categoryId` | yes | FK ItSensitiveDataCategory |

**Unique**: `(treatmentId, categoryId)`.

---

## Schema: `it-insights.prisma` (Cedro)

Reutiliza padrão Run/Batch/Insight de Compras Insights onde aplicável.

### ItInsightBatch / ItInsight

| Model | Notes |
|-------|-------|
| `ItInsightBatch` | `tenantId`, `origin`, `startedAt`, `status` |
| `ItInsight` | `batchId`, `type` (`config_scan \| lgpd_classification \| risk_matrix`), `assetId?`, `impact`, `title`, `message`, `evidencePayload` JSON, `readOnly: true` |

### ItConfigAnalysis

| Field EN | Required | Notes |
|----------|----------|-------|
| `id` | yes | UUID |
| `tenantId` | yes | |
| `assetId` | yes | FK servidor |
| `storageKey` | yes | arquivo uploadado |
| `fileName` | yes | |
| `findingsCount` | yes | |
| `analyzedAt` | yes | |

### ItSecurityPolicyPattern (seed)

| Field EN | Required | Notes |
|----------|----------|-------|
| `id` | yes | |
| `tenantId` | yes | ou global seed |
| `pattern` | yes | regex string |
| `label` | yes | ex.: *Porta FTP aberta* |
| `impact` | yes | critical/high/medium |
| `messageTemplate` | yes | `{assetName}`, `{match}` |

### ItLgpdSensitiveTerm (seed)

| Field EN | Required | Notes |
|----------|----------|-------|
| `id` | yes | |
| `term` | yes | ex.: `cpf`, `salario`, `saude` |
| `categoryCode` | yes | FK lógica ItSensitiveDataCategory |

### ItRiskMatrixEvaluation (opcional histórico)

| Field EN | Required | Notes |
|----------|----------|-------|
| `id` | yes | |
| `tenantId` | yes | |
| `inputPayload` | yes | JSON |
| `resultPayload` | yes | JSON level/score/explanation |
| `evaluatedAt` | yes | |

---

## Schema: `it-fiscalizacao.prisma` (Jatobá)

### ItBackupAuditRun

| Field EN | Required | Notes |
|----------|----------|-------|
| `id` | yes | UUID |
| `tenantId` | yes | |
| `scheduledDay` | yes | dia do mês |
| `startedAt` | yes | |
| `status` | yes | running/completed |
| `serversAffected` | yes | count |

### ItBackupEvidence

| Field EN | Required | Notes |
|----------|----------|-------|
| `id` | yes | UUID |
| `tenantId` | yes | |
| `assetId` | yes | FK servidor |
| `runId` | yes | FK ItBackupAuditRun |
| `backupSizeBytes` | yes | > 0 |
| `restoreDate` | yes | |
| `logStorageKey` | yes | presign confirmado |
| `submittedByUserId` | yes | |
| `submittedAt` | yes | |
| `conformityStatus` | yes | 4 status Jatobá |

### ItAuditTrail (append-only)

| Field EN | Required | Notes |
|----------|----------|-------|
| `id` | yes | UUID |
| `tenantId` | yes | |
| `userId` | yes | |
| `action` | yes | create/read/update/delete |
| `ipAddress` | yes | |
| `entityType` | yes | asset/incident/treatment/... |
| `entityId` | yes | |
| `summary` | no | JSON redacted |
| `createdAt` | yes | **sem** updatedAt/deletedAt |

**Regra**: repository **não expõe** delete/update.

### ItAnpdNotification

| Field EN | Required | Notes |
|----------|----------|-------|
| `id` | yes | UUID |
| `tenantId` | yes | |
| `incidentId` | yes | FK ItIncident critical |
| `generatedByUserId` | yes | |
| `pdfStorageKey` | yes | |
| `generatedAt` | yes | |

---

## Schema: `it-maturidade.prisma` (Carvalho)

### ItFrameworkControl

| Field EN | UI PT-BR | Required | Notes |
|----------|----------|----------|-------|
| `id` | yes | UUID |
| `tenantId` | yes | |
| `framework` | Framework | yes | `cis \| lgpd` |
| `code` | Código | yes | ex.: `CIS-01`, `LGPD-03` |
| `title` | Título | yes | |
| `status` | Status | yes | pending/active/completed |
| `sortOrder` | — | yes | |

**Unique**: `(tenantId, framework, code)`.

### ItMaturidadeSnapshot (cache dashboard)

| Field EN | Required | Notes |
|----------|----------|-------|
| `id` | yes | |
| `tenantId` | yes | |
| `frameworkAdherenceScore` | yes | 0–100 |
| `defenseLinesPayload` | yes | JSON % por linha |
| `vulnerabilityRankingPayload` | yes | JSON por setor |
| `computedAt` | yes | |

---

## Entidades derivadas (não persistidas)

### Dashboard operacional

| Campo | Fonte |
|-------|-------|
| `assetCountByType` | groupBy ItAsset.type |
| `openIncidentsCount` | ItIncident status=open |
| `criticalOpenCount` | severity=critical |
| `lgpdCompliancePercent` | R11 research |

### Linha de defesa %

```
linePercent(N) = (resolved incidents where resolvedByDefenseLine=N) / total resolved × 100
```

### Índice vulnerabilidade

Ver R13 research — calculado em runtime ou snapshot.

---

## State transitions

### ItAsset.backupAuditStatus (servidor)

```text
ok → alerta (cron dia X)
alerta → ok (evidência válida)
alerta → vermelho (D+1 sem evidência)
vermelho → ok (evidência válida tardia)
```

### ItIncident.status

```text
open → resolved (requires resolvedAt + resolvedByDefenseLine)
```

### ItFrameworkControl.status

```text
pending → active → completed
(completed pode reverter para active via PATCH gestor)
```

---

## Tenant relations (`tenant.prisma`)

Adicionar:

```prisma
itAssets              ItAsset[]
itIncidents           ItIncident[]
itInsightBatches      ItInsightBatch[]
itBackupAuditRuns     ItBackupAuditRun[]
itFrameworkControls   ItFrameworkControl[]
itAuditTrails         ItAuditTrail[]
```

---

## Migration notes

1. Migration única `022_it_module` ou split por schema file (padrão repo multi-file)
2. Seed: categorias sensíveis, termos LGPD, padrões regex, 20 controles CIS/LGPD
3. Seed Jacaranda: `ModuloSetor` IT + ativos/incidentes demo
