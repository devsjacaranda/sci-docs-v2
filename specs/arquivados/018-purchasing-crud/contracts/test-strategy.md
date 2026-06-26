# Test Strategy: Purchasing — CRUD de Demandas e Artefatos

**Feature**: 018-purchasing-crud  
**Process**: TDD vertical slices ([tdd](../../../.cursor/skills/tdd/SKILL.md), [testing-conventions](../../../.cursor/skills/testing-conventions/SKILL.md))

## Princípios

- **Vertical slices**: RED → GREEN → REFACTOR por jornada de usuário
- API: Jest + Supertest + use-case specs isolados
- Client: Vitest + RTL + MSW handlers espelhando [rest-api-compras.md](./rest-api-compras.md)
- Tenant isolation testado com dois fixtures de tenant

---

## API — ordem TDD sugerida

### Slice 1 — PCA CRUD mínimo (US-5)

| RED | GREEN |
|-----|-------|
| `create-pca.use-case.spec.ts` — cria ativo | `CreatePcaUseCase` + repo |
| `list-pca.use-case.spec.ts` — conta demandas | `ListPcaUseCase` |
| `close-pca.use-case.spec.ts` — status closed | `ClosePcaUseCase` |
| contract GET/POST/PATCH `/compras/pca` | controller wire |

### Slice 2 — Create demanda (US-2)

| RED | GREEN |
|-----|-------|
| reject sem pcaId | Zod 400 |
| reject pca closed | 400/409 |
| assign sequential number | sequence repo + use-case |
| POST `/compras/demandas` 201 | `CreateDemandaUseCase` |

### Slice 3 — List demandas + filtros (US-1)

| RED | GREEN |
|-----|-------|
| pagination page/limit/total | `ListDemandasUseCase` |
| filter pcaId | repository where |
| filter status derivado | repository computed filter |
| progress label `3/7` | mapper |

### Slice 4 — Demanda detail + checklist (US-3)

| RED | GREEN |
|-----|-------|
| checklist 7 items all pending | `GetDemandaDetailUseCase` |
| 404 cross-tenant | tenant scope |
| GET `/compras/demandas/:id` | controller |

### Slice 5 — Upsert DFD (US-4)

| RED | GREEN |
|-----|-------|
| PUT dfd creates | `UpsertDfdUseCase` |
| PUT dfd updates (no duplicate) | unique demandaId |
| status → in_progress after first artefact | mapper integration |

### Slice 6 — ETP dispensado (US-6)

| RED | GREEN |
|-----|-------|
| waived without reason → 400 | Zod |
| waived counts satisfied | mapper |
| full ETP fields when not waived | Zod refine |

### Slice 7 — Demais artefatos (US-4)

Um slice por artefato ou agrupado:

| Artefato | RED focus |
|----------|-----------|
| analise-riscos | empty risks → pending |
| pesquisa-precos | value ≤ 0 → 400 |
| dotacao | required fields |
| tr | 2 required text fields |
| parecer | opinionText required |

### Slice 8 — Status concluído (US-7)

| RED | GREEN |
|-----|-------|
| 7/7 satisfied → completed | mapper e2e fixture |
| ETP waived + 6 filled → completed | combined fixture |

### Slice 9 — Comprovante presign (FR-16)

| RED | GREEN |
|-----|-------|
| presign returns uploadUrl | reuse StorageService mock |
| structured save without confirm OK | use-case |

### Slice 10 — Modulo guard (FR-24)

| RED | GREEN |
|-----|-------|
| user without compras module → 403 | `@RequireModulo('compras')` |
| user DEAE seeded → 200 | seed integration |

### Slice 11 — Soft delete demanda

| RED | GREEN |
|-----|-------|
| DELETE hides from list | soft delete extension |
| GET by id → 404 | deleted filter |

---

## Client — ordem TDD sugerida

### Slice C1 — API clients + MSW

MSW handlers para PCA, demandas list, detail.

### Slice C2 — DemandasListPage (US-1)

| RED | GREEN |
|-----|-------|
| renders columns from API | page + table |
| filter by PCA | user event |
| navigate nova demanda | router |

### Slice C3 — PcaManageSheet (US-5)

| RED | GREEN |
|-----|-------|
| create PCA refreshes list | sheet + mutation |
| close PCA | PATCH mock |

### Slice C4 — DemandaCreatePage (US-2)

| RED | GREEN |
|-----|-------|
| blocks without active PCA | empty state |
| redirect on success | navigate mock |

### Slice C5 — DemandaHubPage (US-3)

| RED | GREEN |
|-----|-------|
| 7 cards with states | checklist component |
| click navigates | router |

### Slice C6 — ArtefactLayout + DfdPage (US-4, US-8)

| RED | GREEN |
|-----|-------|
| breadcrumb | layout test |
| lateral checklist | sidebar |
| save calls PUT | MSW assert |

### Slice C7 — EtpPage waived flow (US-6)

| RED | GREEN |
|-----|-------|
| motivo required | validation message |
| confirm dialog on switch | dialog RTL |

### Slice C8 — Progress/status integration (US-7)

| RED | GREEN |
|-----|-------|
| list shows Concluído after MSW fixture | integration |

---

## Fixtures de teste

| Fixture | Conteúdo |
|---------|----------|
| `tenantA` | 2 PCAs (1 active, 1 closed), 5 demandas mixed status |
| `tenantB` | vazio — isolation |
| `demandaDraft` | zero artefatos |
| `demandaAlmostDone` | 6/7 + ETP waived |
| `demandaCompleted` | 7/7 satisfied |

Seed Jacaranda deve aproximar `tenantA` pós-implementação.

---

## Comandos

```powershell
cd ci-api-v2; npm test -- --testPathPattern=compras
cd ci-client-v2; npm test -- --filter=@ci/web -- compras
```

Contrato completo: [rest-api-compras.md](./rest-api-compras.md) · UI: [client-compras-ui.md](./client-compras-ui.md)
