# Data Model: Insights Cedro — Gabinete (integração completa)

**Feature**: 015-gabinete-cedro-insights-integrado · **Date**: 2026-06-24

> Entidades Prisma **já existem** (012). Esta feature **estende enum** e **enriquece payloads** — sem novas tabelas. Fonte canônica Gabinete Base: [012-desmock-gabinete/data-model.md](../012-desmock-gabinete/data-model.md).

## Entidades persistidas (existentes)

### GabineteInsightBatch

Sem alteração de colunas. Índices: `(tenantId, generatedAt DESC)`, `(tenantId, origin, generatedAt)`.

### GabineteInsight

Sem alteração de colunas. Campo `category` passa a aceitar novos valores enum (ver abaixo).

### GabineteInsightEvidence

Sem alteração de colunas. Convenção `snapshotFields`:

| Key | Quando |
|-----|--------|
| `entityType` | `ato` \| `protocolo` \| `controle_numerico` \| `notificacao` \| `auto` \| `documento_tramitado` |
| `entityId` | UUID do registro fonte |
| `sectorName` | docs tramitados / encaminhamento |
| `documentType` | controle numérico / protocolo |
| `entryMode` | protocolo |
| `groupId` | notificação+auto agrupados |
| `status` / `origin` | ato (redundante com colunas enum quando aplicável) |

**Sigilo**: **NUNCA** persistir `sender`, `addressee`, `requester`, `issuedBy` completos — só agregados ou omitidos.

---

## Migration: extensão `InsightCategory`

Valores **adicionados** (additive migration):

| Value EN | UI PT-BR | Módulo |
|----------|----------|--------|
| `protocol` | Protocolo | Gabinete |
| `control_numeric` | Controle numérico | Gabinete |
| `enforcement` | Notificações e autos | Gabinete |
| `tramitacao` | Documentos tramitados | Gabinete |

Valores existentes (`operational`, `geographic`, `text`, `profile`) inalterados — Ouvidoria continua usando subset.

Atualizar `CATEGORY_LABEL` em `gabinete-insights.types.ts`.

---

## Enums compartilhados (sem alteração)

### InsightBatchOrigin

| Value EN | UI PT-BR |
|----------|----------|
| `scheduled` | Agendada |
| `on_demand` | Sob demanda |
| `on_open` | Ao abrir |

### InsightImpact

| Value EN | UI PT-BR |
|----------|----------|
| `critical` | Crítico |
| `high` | Alto |
| `medium` | Médio |

---

## Entidades lidas (fontes de agregação)

### CabinetDemanda + CabinetDemandaEvento

| Uso | Campos / relações |
|-----|-------------------|
| Filtro | `status != draft`, `deletedAt null`, `createdAt` na janela 90d |
| Operacional | `status`, `origin`, `currentSector`, `sectorId`, `forwardings` JSON |
| Timeline | `eventos.type`, `eventos.createdAt`, `eventos.payload` |
| Vínculo | `protocoloId`, `protocolNumber` |

### CabinetProtocolo

| Uso | Campos |
|-----|--------|
| Protocolo | `entryMode`, `documentType`, `internalNumber`, `sigedNumber`, `protocolDate` |
| Órfãos | protocolos sem `demandas` vinculadas (`cabinetId` null nos controles ou count demandas = 0) |
| Sigilo | **Não** expor `sender` em evidências |

### CabinetControleNumerico

| Uso | Campos |
|-----|--------|
| Tipo documental | `documentType` enum (`oficio`, `portaria`, `memorando`, …) |
| Vínculo | `cabinetId`, `protocoloId` — contagem única por `id` |
| Janela | `createdAt` |

### CabinetControleNotificacao + CabinetControleAutoInfracao

| Uso | Campos |
|-----|--------|
| Volume | count por período |
| Agrupamento | `groupId` — um caso = um par notificação+auto |
| Tendência | comparar count período atual vs anterior (quando ≥ 2 janelas de histórico de lotes) |
| Sigilo | omitir `addressee`, `response` completos |

### CabinetDocumentoTramitado + Setor

| Uso | Campos |
|-----|--------|
| Por setor | `sectorId`, `sector.nome` |
| Volume | `quantity` opcional (default 1 se null) |
| Janela | `createdAt` ou `protocolDate` |

---

## Slugs estáveis (identificadores de regra)

| Slug | Categoria | Fonte principal |
|------|-----------|-----------------|
| `volume_by_status` | operational | atos |
| `origin_mix` | operational | atos.origin |
| `backlog_aging` | operational | atos status ≠ finished/archived |
| `forwarding_bottleneck` | operational | forwardings JSON |
| `timeline_durations` | operational | eventos |
| `protocol_entry_mode` | protocol | protocolos.entryMode |
| `protocol_document_type` | protocol | protocolos.documentType |
| `protocol_orphan` | protocol | protocolos sem ato |
| `control_numeric_by_type` | control_numeric | controles numéricos |
| `notifications_trend` | enforcement | notificações |
| `autos_trend` | enforcement | autos |
| `notification_auto_ratio` | enforcement | groupId |
| `tramitados_by_sector` | tramitacao | documentos tramitados |

---

## Rastreio (payload API → sheet UI)

```typescript
interface GabineteInsightTracePayload {
  kind: 'cedro-insight';
  license: 'cedro';
  insightId: string;
  title: string;
  summary: string;
  impact: 'Crítico' | 'Alto' | 'Médio';
  recommendation: string;
  generatedAt: string;
  readOnly: true;
  analysisWindow: { start: string; end: string };
  reasoningSteps: string[];
  records: Array<{
    module: 'gabinete';
    protocol: string;
    label: string;
    entityType?: string;
    demandaId?: string;
    fields: Array<{ field: string; value: string }>;
  }>;
  // SEM externalQueries
}
```

Link detalhe ato: `/gabinete/atos/:demandaId` quando `demandaId` presente.

---

## State transitions

### Batch

```text
(running) --success--> (completed)
(running) --error--> (failed)
```

Apenas um `running` por tenant.

### Insight

Imutável após criação — read-only Cedro.

---

## Fixtures de teste (sem DB)

`ci-api-v2/src/modules/gabinete-insights/test/fixtures/`:

| Arquivo | Conteúdo |
|---------|----------|
| `gabinete-analysis-sample.json` | atos + protocolos + controles + notificações + autos + tramitados |
| `insight-batch-completed.json` | lote multi-categoria + evidências |
| `insight-list-empty.json` | emptyReason variants |

Client: espelhar em `modules/gabinete/fixtures/insights-*.json`.
