# Research: Integrar Gabinete (Atos) à Tramitação — Linked Record

**Feature**: 030-gabinete-tramitacao-linked  
**Date**: 2026-07-01

## R1 — Gap analysis (estado atual vs spec)

**Decision**: Feature é **completar US2 da spec 014**, não greenfield.

**Findings**:

| Capacidade | API | Client |
|------------|-----|--------|
| POST forward (`/gabinete/cabinets/:id/forward`) | ✅ `ForwardCabinetUseCase` + linked | ✅ `ForwardAtoDialog` |
| Lista/detalhe atos | ✅ spec 012 | ✅ `GabineteAtosListPage`, `GabineteAtoDetailPage` |
| Snapshot linked v2 | ❌ v1 (4 campos crus) | parcial parse genérico |
| Guards status (draft/archived/finished) | ❌ ausente | parcial UI (`NON_TRAMITABLE_STATUSES`) |
| Notes obrigatório | ❌ optional Zod | ❌ optional UI |
| LinkedRecordPanel hydrate gabinete | N/A | ❌ só ouvidoria + jurídico |
| Seed linked gabinete | ❌ genérico sem ato real | — |
| licencas-canonicas | — | documenta *tramitação stub* |

**Rationale**: Foco em paridade Ouvidoria/Jurídico sem recriar CRUD gabinete.

**Alternatives considered**: Nova entidade junction Gabinete-Tramitação — rejeitado; `TramitacaoDemanda.sourceRecordId` já cobre.

---

## R2 — Resolução setor origem

**Decision**: Manter `ResolveGabineteSenderSectorUseCase` (já injetado em `ForwardCabinetUseCase`) com ordem: explicit sector → user setores → chief → modulo gabinete → primeiro setor tenant.

**Rationale**: Equivalente funcional ao `ResolveTramitacaoSectorUseCase` da spec 027; gabinete já tem use case dedicado desde spec 012.

**Alternatives considered**: Substituir por `ResolveTramitacaoSectorUseCase` unificado — rejeitado nesta feature; escopo mínimo, use case gabinete já testado.

**Nota controller**: `forwardCabinetHandler` passa `req.user.setorIds?.[0]` como hint; quando undefined, fallback do use case resolve admin_tenant.

---

## R3 — Snapshot schemaVersion 2

**Decision**: Estender `mapCabinetTramitacaoSnapshot`:

```typescript
{
  schemaVersion: 2,
  protocolNumber,
  subject,
  summary: subject,
  status,
  statusLabel,      // CABINET_STATUS_LABEL
  origin,             // enum code
  originLabel,        // CABINET_ORIGIN_LABEL
  description,        // preview ≤ 500 chars
  capturedAt: ISO8601,
}
```

**Rationale**: `needsOuvidoriaHydration` / `needsJuridicoHydration` checam `schemaVersion !== 2`; snapshots gabinete atuais não exibem labels legíveis no painel Tramitação.

**Alternatives considered**: Sempre hidratar via GET — rejeitado como única estratégia; snapshot deve ser autossuficiente para PDF export.

---

## R4 — Guards de elegibilidade

**Decision**: Validar em `ForwardCabinetUseCase` antes de persistir:

| Status | Resultado |
|--------|-----------|
| `draft` | 400 — "Apenas atos registrados podem ser tramitados" |
| `archived`, `finished` | 400 — "Ato arquivado/finalizado não pode ser tramitado" |
| demais | permitido |

**Rationale**: Client oculta ação para archived/finished; API deve enforce (FR-001, SC-005).

---

## R5 — Observação obrigatória

**Decision**: `forwardCabinetBodySchema.notes` → `z.string().trim().min(1).max(1000)`; UI `ForwardAtoDialog` label "Observações *".

**Rationale**: FR-002 spec 030; paridade jurídico (`tramitarProcessoBodySchema.observacao` min 1).

**Alternatives considered**: Manter optional — rejeitado; spec e regras-plataforma exigem motivo documentado.

---

## R6 — Linked record hidratação gabinete

**Decision**: Espelhar fluxo jurídico em `LinkedRecordPanel`:

1. `needsGabineteHydration(snapshot)` — true se `schemaVersion !== 2` ou faltam `statusLabel`/`originLabel`
2. `getCabinetDetail(sourceRecordId)` → `mergeGabineteDetail`
3. 404 → `origemRemovida: true`; desabilitar "Abrir origem"

**Campos merge**: protocolNumber, subject, statusLabel, originLabel, description, sector name (se disponível).

**Rationale**: FR-007–FR-009 spec 030.

---

## R7 — Seed demo

**Decision**: Exportar `LINKED_DEMO_ATO_ID = '00000000-0000-4000-8000-000000000077'` do primeiro ato seed (ou criar ato dedicado com ID fixo); atualizar `seed-tramitacao-demo.ts` com demanda linked gabinete.

**Rationale**: Lição spec 028 — phantom IDs causam 404 em "Abrir origem". Jacaranda já seeda ouvidoria + jurídico linked; falta gabinete.

**Alternatives considered**: Query dinâmica pós-seed — rejeitado; ID fixo facilita quickstart.

---

## R8 — Test strategy

**Decision**: 4 camadas:

1. Unit API snapshot v2 + guards status
2. Integration forward → linked demanda (update CT-TRAM-009)
3. Unit client mergeGabineteDetail / needsGabineteHydration
4. Component LinkedRecordPanel gabinete + ForwardAtoDialog notes required

**Rationale**: Constitution II; espelho CT-JT-* da spec 028 adaptado.
