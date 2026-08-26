# Implementation Plan: Integrar Jurídico à Tramitação — Linked Record

**Branch**: `028-juridico-tramitacao-linked` | **Date**: 2026-07-01 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/028-juridico-tramitacao-linked/spec.md`

## Summary

Completar a integração **Jurídico → Tramitação** iniciada na spec 014 (US11): backend de tramitar já existe, mas **lista/detalhe de processos ainda mock**, **UI sem ação Tramitar**, **snapshot v1** e **LinkedRecordPanel sem hidratação jurídica**.

**Abordagem**: espelhar padrão Ouvidoria (lista + detalhe API, páginas reais, dialog encaminhar, toast com link Tramitação); estender snapshot para `schemaVersion: 2`; hidratar linked record na Tramitação; corrigir resolução de setor origem no controller jurídico (mesmo fix 027); seed demo com processo confirmado + demanda linked.

**Escopo**: lista, detalhe, tramitar, linked record, seed — **fora**: dashboard/auditoria/insights/maturidade jurídicos.

## Technical Context

**Language/Version**: TypeScript 5.x / 6.x; Node.js 20 LTS

**Primary Dependencies**:

| Pacote | Stack |
|--------|-------|
| **ci-api-v2** | NestJS 11, Fastify, Pino, Zod, Prisma 7, PostgreSQL |
| **ci-client-v2** | React 19, Vite 8, Tailwind v4, shadcn/ui, react-router-dom 7, Vitest 3, MSW 2 |

**Storage**: PostgreSQL — entidades existentes (`LegalProcess`, `LegalProcessParty`, `LegalProcessEvent`, `LegalProcessAttachment`, `TramitacaoDemanda`); **sem migration** (schema 012 + 014 já cobrem)

**Testing**: Jest unit + integration (`ci-api-v2`); Vitest/RTL/MSW (`ci-client-v2`) — [test-strategy.md](./contracts/test-strategy.md)

**Target Platform**: API Linux/container; SPA browser (`@ci/web`)

**Project Type**: Full-stack feature (extensão módulos existentes)

**Performance Goals**: Lista processos paginada < 500ms p95; detalhe < 400ms p95; tramitar linked < 5s p95 (SC-001)

**Constraints**:

- TDD obrigatório RED → GREEN → REFACTOR
- Zod only — sem class-validator
- Tenant AsyncLocalStorage — nunca passar `tenantId` manual
- `@RequireModulo('juridico')` em rotas jurídico; Tramitação módulo aberto
- Reuso `CreateLinkedDemandaUseCase` + `ResolveTramitacaoSectorUseCase` (preferredModuloSlug: `juridico`)
- Snapshot imutável pós-criação; `schemaVersion: 2` alinhado ouvidoria
- Copy PT-BR [regras-plataforma.md](../../../.cursor/docs/regras-plataforma.md); paleta mint-palette
- Escopo mínimo: **não** desmock dashboard/auditoria jurídico nesta feature

**Scale/Scope**: ~6 endpoints REST novos (GET list/detail + mappers); 2 páginas client + 2 componentes; 1 seed; extensões LinkedRecordPanel; ~15 arquivos alterados

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Princípio | Status | Notas |
|-----------|--------|-------|
| I. Spec-Driven | ✅ PASS | Spec 028 + checklist validados |
| II. Test-First | ✅ PASS | test-strategy CT-JT-001..018 |
| III. Stack fixa | ✅ PASS | NestJS 11 + Prisma 7 + React 19 + Vite 8 |
| IV. Multi-tenant | ✅ PASS | Repositories tenant-scoped via Prisma extensions |
| IV. Licenças | ✅ PASS | Base only; sem Jatobá/Cedro/Carvalho |
| V. Escopo mínimo | ✅ PASS | Reuso infra 014; páginas espelho ouvidoria |

**Post-design re-check**: Sem novas entidades Prisma; extensão de mapper/snapshot e páginas client justificada por gap US11 incompleto (T101 spec 014). Import `TramitacaoModule` já existe em `JuridicoModule`. Sem Complexity Tracking necessário.

## Project Structure

### Documentation (this feature)

```text
civ2-docs/specs/028-juridico-tramitacao-linked/
├── plan.md              # This file
├── research.md          # Phase 0
├── data-model.md        # Phase 1
├── quickstart.md        # Phase 1
├── contracts/
│   ├── rest-api-juridico-tramitacao-linked.md
│   ├── client-juridico-tramitacao-ui.md
│   └── test-strategy.md
└── tasks.md             # Phase 2 — /speckit-tasks
```

### Source Code (repository root)

```text
ci-api-v2/
├── prisma/seed/
│   ├── seed-juridico-demo.ts              # NEW — processos confirmados demo
│   └── seed-tramitacao-demo.ts            # UPDATE — linked juridico com ID real
├── src/modules/juridico/
│   ├── juridico.controller.ts               # + GET list/detail; tramitar usa resolveSector
│   ├── juridico.mapper.ts                   # + mapListItem, mapDetailResponse
│   ├── juridico.schemas.ts                  # (existente — ListProcessosQuery)
│   ├── lib/
│   │   └── process-tramitacao-snapshot.mapper.ts  # schemaVersion 2 + labels
│   ├── use-cases/
│   │   ├── list-processos.use-case.ts       # NEW
│   │   ├── get-processo-detail.use-case.ts  # NEW
│   │   └── tramitar-processo.use-case.ts    # (existente)
│   ├── repository/
│   │   └── process.repositories.ts          # + ListProcessosRepository, FindProcessDetailRepository
│   └── test/
│       ├── use-cases/list-get-processos.spec.ts           # NEW
│       └── use-cases/tramitar-processo-tramitacao.integration.spec.ts  # UPDATE snapshot v2

ci-client-v2/apps/web/src/
├── app/router.tsx                           # + juridico-lista, juridico-detalhes overrides
├── modules/juridico/
│   ├── index.ts                             # lazy exports list + detail
│   ├── api/processos.ts                     # + listProcessos, getProcessoDetail
│   ├── lib/processos-mappers.ts             # NEW — API→UI row/detail
│   ├── pages/
│   │   ├── JuridicoProcessosListPage.tsx    # NEW
│   │   └── JuridicoProcessoDetailPage.tsx   # NEW
│   └── components/
│       ├── ForwardProcessoDialog.tsx        # NEW — espelho ForwardManifestacaoDialog
│       └── ProcessoTimeline.tsx             # NEW
├── modules/tramitacao/
│   ├── components/LinkedRecordPanel.tsx     # + hydration juridico
│   └── lib/
│       ├── linked-record-snapshot.ts        # + mergeJuridicoDetail, labels processType
│       └── __tests__/linked-record-snapshot.test.ts  # UPDATE
└── test/msw/handlers/juridico.ts             # + GET list/detail handlers
```

**Structure Decision**: Extensão incremental em módulos `juridico/` e `tramitacao/` já existentes; router overrides seguem padrão ouvidoria/gabinete. Wizard (`juridico-novo`/`editar`) permanece inalterado.

## Implementation Phases

### Phase A — API lista/detalhe (P1 US2)

1. Repositories + use cases `ListProcessos`, `GetProcessoDetail`
2. Mappers PT-BR (`tipo`, `status` operacional derivado, `partesResumo`)
3. Controller GET `/juridico/processos`, GET `/juridico/processos/:id`
4. TDD contract + integration specs

### Phase B — API tramitar hardening (P1 US1)

1. Controller: substituir `setorIds?.[0]` por `ResolveTramitacaoSectorUseCase` com `preferredModuloSlug: juridico`
2. Upgrade `mapProcessTramitacaoSnapshot` → `schemaVersion: 2` + typeLabel/statusLabel
3. Estender integration spec snapshot v2

### Phase C — Client lista/detalhe + tramitar (P1 US1+US2)

1. `JuridicoProcessosListPage` — DataTable, filtros, badge prazo crítico
2. `JuridicoProcessoDetailPage` — seções + timeline + `ForwardProcessoDialog`
3. Router overrides `juridico-lista`, `juridico-detalhes`
4. Toast pós-tramitar com link `/tramitacao/demandas/:id`

### Phase D — Linked record Tramitação (P2 US3)

1. `getProcessoDetail` API client
2. `mergeJuridicoDetail` + `needsJuridicoHydration` em `linked-record-snapshot.ts`
3. `LinkedRecordPanel` effect para `sourceModule === 'juridico'`
4. Estado "Origem removida" quando GET 404

### Phase E — Seed demo (P3 US4)

1. `seed-juridico-demo.ts` — 2–3 processos confirmados (1 linked ID fixo)
2. Atualizar `seed-tramitacao-demo.ts` linked juridico com `sourceRecordId` real + snapshot v2
3. Registrar em `seed-jacaranda-tenant.ts` (antes de tramitacao demo)

## Risk & Mitigation

| Risco | Mitigação |
|-------|-----------|
| Spec 012 contrato PT-BR vs EN interno | Manter EN Prisma; mapper PT-BR na resposta REST (padrão ouvidoria) |
| Admin sem setor (400 tramitar) | `ResolveTramitacaoSectorUseCase` + fallback modulo juridico |
| Snapshot v1 em demandas antigas | `parseLinkedRecordSnapshot` já tolera campos legados; hidratação complementa |
| Lista vazia pós-seed | Seed jurídico roda antes tramitação; IDs fixos documentados em quickstart |

## References

- Spec 014 US11 (T097–T101) — backend parcial, UI pendente
- Spec 012 — contratos REST/UI jurídico base
- Spec 027 — padrão `ResolveTramitacaoSectorUseCase`
- Spec 028 ouvidoria linked fix — seed ID consistente (lição aprendida)
