# STATUS — 028 Jurídico Tramitação Linked

**Data**: 2026-07-01 (arquivada)  
**Estado**: Concluída — 42/42 tasks em `tasks.md`

## Entregue (spec)

### API (`ci-api-v2`)

- Snapshot v2 `mapProcessTramitacaoSnapshot` — labels PT, `capturedAt`, `partiesSummary`
- GET `/juridico/processos` (lista paginada) + GET `/juridico/processos/:id` (detalhe)
- POST tramitar com `ResolveTramitacaoSectorUseCase` (`preferredModuloSlug: juridico`)
- `CreateLinkedDemandaUseCase` — demanda linked + evento `forwarding` na timeline
- Seed demo: `seed-juridico-demo.ts` + demanda linked ID `00000000-0000-4000-8000-000000000088`

### Client (`ci-client-v2/apps/web`)

- `JuridicoProcessosListPage` + `JuridicoProcessoDetailPage` (substituem mock shell)
- `ForwardProcessoDialog` — tramitar com toast + redirect Tramitação
- `LinkedRecordPanel` — branch `juridico` com hidratação + origem removida (404)
- MSW handlers GET list/detail/tramitar

### Testes

- **API**: 30 testes Jest (`--testPathPatterns=juridico`)
- **Client**: 9 testes Vitest (snapshot, dialog, list, detail, linked panel)

---

## Pós-spec (fora do plano original)

### 1. Admin tenant — FK `LegalProcess_createdByUserId` (500 ao criar processo)

**Problema:** login `admin@jacaranda.com` usa `AdminTenant.id` no JWT; `POST /juridico/processos` gravava FK inválida em `User`.

**Correção:**
- Migration `20260701190300_legal_process_created_by_nullable` — `createdByUserId` nullable
- Controller + use cases usam `resolveUserTableId()` (padrão Gabinete/Tramitação)
- `TramitarProcessoUseCase` recebe `AuthenticatedUser`; `createdByUserId` / `authorUserId` opcionais para admin
- Rule permanente: `.cursor/rules/admin-tenant-user-fk.mdc`

### 2. Lista de processos — design system institucional

**Problema:** lista sem menu ⋮, sem tramitar inline, layout fora do padrão Ouvidoria/Gabinete.

**Correção:**
- `TableRowActionsMenu` — Ver detalhes + Tramitar (oculto em rascunho)
- Layout: `SaudeHeroHeader`, banner, `InstitutionalStatGrid`, `SaudeFiltersBar`
- `ForwardProcessoDialog` aberto da lista via `tramitarId`
- `processos-list-stats.ts` — KPIs da lista
- Fix client API: query param `type` (antes `tipo`, ignorado pela API)

---

## Validação

```powershell
cd ci-api-v2; npm run prisma:seed
cd ci-api-v2; npm test -- --testPathPatterns=juridico
cd ci-client-v2/apps/web; npm test -- linked-record-snapshot ForwardProcessoDialog JuridicoProcessosListPage

# Smoke API
# Login admin@jacaranda.com / password123 + X-Tenant-ID: jacaranda
# GET /juridico/processos → 200
# POST /juridico/processos { type: judicial } → 201 (admin tenant)
# GET .../00000000-0000-4000-8000-000000000088 → 200

# UI: /juridico/processos → KPIs, filtros, menu ⋮ Tramitar
# Tramitação → demanda linked → Abrir origem sem 404
```

## Critérios spec

| US | Status |
|----|--------|
| US1 Tramitar processo | OK |
| US2 Lista/detalhe reais | OK |
| US3 Linked record panel | OK |
| US4 Seed demo | OK |

## Dívidas / futuro

- Wizard `juridico-novo` / dashboard auditoria permanecem mock (fora de escopo)
- Consultar IA na lista jurídico (opcional — presente em Ouvidoria/Gabinete)
- `uploadedByUserId` em anexos jurídico — revisar mesmo padrão admin se exposto na UI
