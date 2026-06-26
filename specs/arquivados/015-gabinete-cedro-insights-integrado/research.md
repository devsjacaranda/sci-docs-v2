# Research: Insights Cedro — Gabinete (integração completa)

**Feature**: 015-gabinete-cedro-insights-integrado · **Date**: 2026-06-24

## R1 — Escopo: completar vs recriar

**Decision**: **Completar** o submódulo existente `gabinete-insights` (API) e a página `GabineteInsightsPage` (client) — **não** recriar entidades Prisma nem rotas base.

**Rationale**: 012 já entregou schema `GabineteInsightBatch/Insight/Evidence`, controller, use-cases, job agendado e testes parciais. Gap atual: agregadores incompletos (só `volume_by_status`), loader só lê `CabinetDemanda`, client sem paridade Ouvidoria, bugs (`buildTraceRecord` retorna `module: 'ouvidoria'`, client POST `origin: 'manual'` inválido).

**Alternatives considered**:

- Novo módulo do zero → rejeitado (duplica 012)
- Mover insights para dentro de `gabinete/` monolítico → rejeitado (padrão 007/012: submódulo licença Cedro)

---

## R2 — Fontes de dados integradas

**Decision**: Novo loader unificado `LoadGabineteAnalysisDataRepository` retorna struct tipada:

```typescript
interface GabineteAnalysisData {
  demandas: DemandaForAnalysis[];
  protocolos: ProtocoloForAnalysis[];
  controlesNumericos: ControleNumericoForAnalysis[];
  notificacoes: NotificacaoForAnalysis[];
  autos: AutoInfracaoForAnalysis[];
  documentosTramitados: DocumentoTramitadoForAnalysis[];
}
```

Queries paralelas Prisma na janela de 90 dias (`createdAt` ou `protocolDate`/`entryDate` conforme entidade), `deletedAt IS NULL`; atos com `status != draft`.

**Rationale**: FR-001 exige integração de todas as fontes; loader único evita N round-trips no use-case e facilita testes com fixture JSON única.

**Alternatives considered**:

- Continuar só `CabinetDemanda` → rejeitado (não atende spec)
- Join SQL monolítico → rejeitado (complexidade; entidades standalone com `cabinetId` opcional)

---

## R3 — Regras de agregação (determinísticas)

**Decision**: Um arquivo por domínio em `lib/aggregation/`:

| Arquivo | Slugs | Fonte |
|---------|-------|-------|
| `operational.rules.ts` | `volume_by_status`, `origin_mix`, `backlog_aging`, `forwarding_bottleneck`, `timeline_durations` | `CabinetDemanda` + eventos + `forwardings` JSON |
| `protocol.rules.ts` | `protocol_entry_mode`, `protocol_document_type`, `protocol_orphan` | `CabinetProtocolo` |
| `control-numeric.rules.ts` | `control_numeric_by_type` | `CabinetControleNumerico.documentType` |
| `notifications.rules.ts` | `notifications_trend`, `autos_trend`, `notification_auto_ratio` | `CabinetControleNotificacao` + `CabinetControleAutoInfracao`; dedup por `groupId` |
| `tramitados.rules.ts` | `tramitados_by_sector` | `CabinetDocumentoTramitado.sectorId` + join `Setor` |

Orquestrador `aggregateGabineteInsights(data, window)` compõe candidatos; cada regra retorna `null` se volume &lt; `MIN_RECORDS_PER_DIMENSION` (5).

**Rationale**: Alinhado a contrato 012 + spec 015; funções puras unit-testáveis; sem NLP/LLM (FR-016).

**Alternatives considered**:

- Um único `volume.rules.ts` → rejeitado (já insuficiente)
- LLM para recomendações → rejeitado (out of scope)

---

## R4 — Categorias analíticas (enum)

**Decision**: Estender enum Prisma `InsightCategory` com valores Gabinete:

| Value EN | UI PT-BR | Uso |
|----------|----------|-----|
| `protocol` | Protocolo | insights de protocolo |
| `control_numeric` | Controle numérico | tipos documentais |
| `enforcement` | Notificações e autos | notificações + autos |
| `tramitacao` | Documentos tramitados | volume por setor |

Manter `operational` para atos/encaminhamentos. **Não** usar `geographic`/`text` no Gabinete v1.

**Rationale**: SC-007 exige ≥ 3 categorias distintas; labels UI claros; enum compartilhado Ouvidoria+Gabinete (migration additive).

**Alternatives considered**:

- Reutilizar só `operational` para tudo → rejeitado (SC-007 e UX de categoria)
- String livre em JSON → rejeitado (mapper e filtros inconsistentes)

---

## R5 — Evidências e rastreio

**Decision**: Manter schema `GabineteInsightEvidence` atual; enriquecer `snapshotFields` com `entityType`, `entityId`, `sectorName`, `documentType`, etc.; `demandaId` opcional; `protocol` = identificador legível (número protocolo ato ou `internalNumber`/`sigedNumber`).

Corrigir `buildTraceRecord` → `module: 'gabinete'`, labels PT para status/origem de ato, **omitir** `sender`, `addressee`, `requester` de protocolos/controles.

**Rationale**: FR-018; schema migration mínima; rastreio R-40 via sheet.

**Alternatives considered**:

- Novas FKs `protocoloId`, `controleId` na evidence → rejeitado (escopo; JSON snapshot suficiente)

---

## R6 — Mínimo estatístico e geração vazia

**Decision**:

- `MIN_RECORDS_PER_DIMENSION = 5` por regra/slug
- Geração de lote **permitida** se qualquer fonte tiver ≥ 1 registro analisável; `insightCount` pode ser 0 com `emptyReason: insufficient_volume`
- Alinhar `MIN_DEMANDAS_FOR_INSIGHTS` (hoje 3) → remover gate global por atos; substituir por “pelo menos uma fonte com dados no período”

**Rationale**: Spec Assumptions: standalone cadastros geram insights sem atos; categorias omitidas individualmente.

---

## R7 — Job, throttle e geração ao abrir

**Decision**: Reutilizar implementação 012/007:

- Job `@Cron` diário em `generate-insights-scheduled.job.ts` (já existe)
- Throttle 1h `on_demand` via último lote (já existe)
- `ListLatestInsightsUseCase` + hook client: se `never_generated` e carga ≤ 10k registros, **opcional** POST `on_open` (espelhar Ouvidoria)

**Rationale**: FR-005–FR-009; código base presente — falta wiring client e testes E2E.

---

## R8 — Client: paridade Ouvidoria

**Decision**: Extrair componentes Cedro genéricos para `modules/shared/components/cedro/`:

- `InsightCard`, `InsightsPanel`, `InsightsHistoryPanel`, `InsightTraceSheet`
- Props: `moduleId`, `sourceLabel`, `detailPathPrefix` (`/gabinete/atos` vs `/ouvidoria/manifestacoes`)

Refatorar `OuvidoriaInsightsPage` para usar shared; reescrever `GabineteInsightsPage` no mesmo padrão.

API client em `modules/gabinete/api/insights.ts` + `insights-mappers.ts` espelhando ouvidoria (tipos Zod, `InsightsApiError`, throttle 429).

**Rationale**: FR-022 paridade; DRY; testes RTL reutilizáveis com props.

**Alternatives considered**:

- Copiar 4 componentes só em gabinete → rejeitado (duplicação ~400 LOC)
- Manter página simplificada → rejeitado (não atende spec)

---

## R9 — Estratégia de testes

**Decision**: Matriz idêntica a 007 — unit (regras puras), use-cases (Prisma mock), contract (fixtures JSON), E2E Supertest + Vitest/MSW; **sem** Postgres de teste dedicado.

Novos CTs: `CT-GAB-INS-001…015` cobrindo cada slug + trace gabinete + throttle + emptyReason.

**Rationale**: Constitution II; padrão repo.

---

## R10 — Seed demo

**Decision**: Estender `seed-gabinete-demo.ts` (ou seed dedicado) para garantir tenant demo com atos + protocolos + controles + notificações/autos + docs tramitados suficientes para ≥ 3 categorias após generate.

**Rationale**: quickstart manual SC-007; dev experience.

**Alternatives considered**:

- Só seed manual via UI → rejeitado (lento para QA)
