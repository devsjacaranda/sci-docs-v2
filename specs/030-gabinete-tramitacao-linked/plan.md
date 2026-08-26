# Implementation Plan: Integrar Gabinete (Atos) à Tramitação — Linked Record

**Branch**: `030-gabinete-tramitacao-linked` | **Date**: 2026-07-01 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/030-gabinete-tramitacao-linked/spec.md`

## Summary

Completar a integração **Gabinete → Tramitação** iniciada na spec 014 (US2): backend de encaminhar (`ForwardCabinetUseCase` + `CreateLinkedDemandaUseCase`) e UI stub (`ForwardAtoDialog`) já existem, mas **snapshot v1**, **observação opcional**, **sem guards de elegibilidade**, **LinkedRecordPanel sem hidratação gabinete** e **seed linked sem ato real** impedem paridade com Ouvidoria (027) e Jurídico (028).

**Abordagem**: hardening API (snapshot v2, notes obrigatório, guards status, setor origem); completar client (`ForwardAtoDialog`, labels status); estender `LinkedRecordPanel` + `mergeGabineteDetail`; seed demo com ID fixo; atualizar `licencas-canonicas.md` (stub → integrado).

**Escopo**: tramitar atos (lista + detalhe), linked record, seed — **fora**: dashboard/fiscalização/insights/maturidade gabinete.

## Technical Context

**Language/Version**: TypeScript 5.x / 6.x; Node.js 20 LTS

**Primary Dependencies**:

| Pacote | Stack |
|--------|-------|
| **ci-api-v2** | NestJS 11, Fastify, Pino, Zod, Prisma 7, PostgreSQL |
| **ci-client-v2** | React 19, Vite 8, Tailwind v4, shadcn/ui, react-router-dom 7, Vitest 3 |

**Storage**: PostgreSQL — entidades existentes (`CabinetDemanda`, `CabinetDemandaEvento`, `TramitacaoDemanda`); **sem migration**

**Testing**: Jest unit + integration (`ci-api-v2`); Vitest/RTL (`ci-client-v2`) — [test-strategy.md](./contracts/test-strategy.md)

**Target Platform**: API Linux/container; SPA browser (`@ci/web`)

**Project Type**: Full-stack feature (extensão módulos existentes)

**Performance Goals**: Tramitar linked < 5s p95 (SC-001); detalhe ato já existente < 400ms p95

**Constraints**:

- TDD obrigatório RED → GREEN → REFACTOR
- Zod only — `forwardCabinetBodySchema.notes` min 1 char
- Tenant AsyncLocalStorage — nunca passar `tenantId` manual
- `@RequireModulo('gabinete')` em rotas gabinete
- Reuso `CreateLinkedDemandaUseCase` + `ResolveGabineteSenderSectorUseCase`
- `resolveUserTableId` + `withActorPayload` para admin_tenant (FK User nullable)
- Snapshot imutável `schemaVersion: 2` alinhado ouvidoria/jurídico
- Copy PT-BR [regras-plataforma.md](../../../.cursor/docs/regras-plataforma.md); paleta mint-palette
- Vocabulário UI: **ato/atos**; rotas `/gabinete/atos/*`

**Scale/Scope**: ~0 endpoints novos; 1 endpoint alterado (POST forward); 2 componentes client alterados; 1 seed update; extensões LinkedRecordPanel; ~12 arquivos alterados

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Princípio | Status | Notas |
|-----------|--------|-------|
| I. Spec-Driven | ✅ PASS | Spec 030 + checklist validados |
| II. Test-First | ✅ PASS | test-strategy CT-GT-001..016 |
| III. Stack fixa | ✅ PASS | NestJS 11 + Prisma 7 + React 19 + Vite 8 |
| IV. Multi-tenant | ✅ PASS | Repositories tenant-scoped via Prisma extensions |
| IV. Licenças | ✅ PASS | Base only; Gabinete + Tramitação |
| V. Escopo mínimo | ✅ PASS | Reuso infra 014; hardening stub existente |

**Post-design re-check**: Sem novas entidades Prisma; extensão snapshot/mapper e LinkedRecordPanel justificada por gap US2 spec 014 incompleto. `GabineteModule` já importa `TramitacaoModule`. Sem Complexity Tracking necessário.

## Project Structure

### Documentation (this feature)

```text
civ2-docs/specs/030-gabinete-tramitacao-linked/
├── plan.md              # This file
├── research.md          # Phase 0
├── data-model.md        # Phase 1
├── quickstart.md        # Phase 1
├── contracts/
│   ├── rest-api-gabinete-tramitacao-linked.md
│   ├── client-gabinete-tramitacao-ui.md
│   └── test-strategy.md
└── tasks.md             # Phase 2 — /speckit-tasks
```

### Source Code (repository root)

```text
ci-api-v2/
├── prisma/seed/
│   ├── seed-gabinete-demo.ts              # UPDATE — export LINKED_DEMO_ATO_ID fixo
│   └── seed-tramitacao-demo.ts            # UPDATE — linked gabinete com ID real + snapshot v2
├── src/modules/gabinete/
│   ├── gabinete.controller.ts               # forward: resolveSector via use case (já parcial)
│   ├── gabinete.schemas.ts                  # notes min(1) obrigatório
│   ├── lib/
│   │   └── cabinet-tramitacao-snapshot.mapper.ts  # schemaVersion 2 + labels
│   ├── use-cases/
│   │   └── forward-cabinet.use-case.ts      # guards status + snapshot v2
│   └── test/
│       ├── use-cases/forward-cabinet-tramitacao.integration.spec.ts  # UPDATE
│       └── lib/cabinet-tramitacao-snapshot.mapper.spec.ts              # NEW

ci-client-v2/apps/web/src/
├── modules/gabinete/
│   ├── components/ForwardAtoDialog.tsx      # notes required; UX paridade jurídico
│   └── pages/GabineteAtosListPage.tsx       # (já tem Tramitar — validar reload)
├── modules/tramitacao/
│   ├── components/
│   │   ├── LinkedRecordPanel.tsx            # + hydration gabinete
│   │   └── __tests__/LinkedRecordPanel.gabinete.test.tsx  # NEW
│   └── lib/
│       ├── linked-record-snapshot.ts        # + mergeGabineteDetail, CABINET status labels
│       └── __tests__/linked-record-snapshot.test.ts  # UPDATE gabinete cases
```

**Structure Decision**: Extensão incremental em `gabinete/` e `tramitacao/`; páginas lista/detalhe já reais (spec 012) — **não** recriar CRUD.

## Implementation Phases

### Phase A — API hardening (P1 US1, US4)

1. `forwardCabinetBodySchema`: `notes` → `z.string().min(1).max(1000)`
2. `ForwardCabinetUseCase`: rejeitar `draft`, `archived`, `finished` (400 + copy PT-BR)
3. Upgrade `mapCabinetTramitacaoSnapshot` → v2 (`statusLabel`, `originLabel`, `capturedAt`)
4. Incluir `tramitacaoDemandaId`/`protocol` no payload evento `forwarded` (opcional, audit trail)
5. TDD: snapshot mapper spec + integration spec update

### Phase B — Client tramitar (P1 US1, US2)

1. `ForwardAtoDialog`: observação obrigatória; validação inline; manter toast + navigate
2. Confirmar `NON_TRAMITABLE_STATUSES` alinhado API (draft se exposto)
3. Lista: reload após `onComplete` (já existe — regressão test)

### Phase C — Linked record Tramitação (P2 US3)

1. `needsGabineteHydration` + `mergeGabineteDetail` em `linked-record-snapshot.ts`
2. Labels `CabinetDemandaStatus` / `CabinetDemandaOrigin` no client (espelho `gabinete.mapper.ts`)
3. `LinkedRecordPanel` effect `sourceModule === 'gabinete'` → `getCabinetDetail`
4. 404 → origem removida (padrão jurídico)

### Phase D — Seed demo (P3 US5)

1. `LINKED_DEMO_ATO_ID` fixo em `seed-gabinete-demo.ts` (primeiro ato ou constante exportada)
2. `seed-tramitacao-demo.ts`: demanda linked `sourceModule: gabinete` com snapshot v2
3. Ordem seed Jacaranda: gabinete antes tramitação (já é)

### Phase E — Docs produto

1. Atualizar `.cursor/docs/licencas-canonicas.md`: Gabinete Base — tramitação integrada (remover *stub*)

## Risk & Mitigation

| Risco | Mitigação |
|-------|-----------|
| Stub já em produção com notes opcional | Breaking change controlado; client + schema alinhados na mesma PR |
| Snapshot v1 em demandas antigas | Hidratação gabinete + `mergeGenericSnapshotFields` fallback |
| Admin tenant FK violation | Já usa `resolveUserTableId`; teste explícito CT-GT-008 |
| Seed phantom ID | ID fixo documentado em quickstart (lição 028) |

## References

- Spec 014 US2 — gabinete linked record (T097–T101 parcial)
- Spec 012 — Gabinete desmock + forward stub
- Spec 027 — resolução setor origem ouvidoria
- Spec 028 — padrão linked record jurídico (espelho desta feature)
