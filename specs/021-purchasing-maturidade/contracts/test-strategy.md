# Test Strategy: Maturidade Carvalho — Compras

**Feature**: 021-purchasing-maturidade  
**Princípio**: TDD obrigatório (Constitution II). **Sem** Postgres de teste dedicado.

---

## Camadas

| Camada | API (`ci-api-v2`) | Client (`ci-client-v2/apps/web`) |
|--------|-------------------|----------------------------------|
| **Unitário** | Jest — `hybrid-score`, `self-assessment-score`, `improvement-orientations`, `jatoba-dimension-map`, `period-utils`, `maturity-alert`, `indicators/*` | Vitest — mappers, chart adapters, orientation panel |
| **Contrato** | Zod schemas + fixtures JSON; Supertest valida shape | Zod response + MSW handlers |
| **Integração** | Use-cases + repositories Prisma **mock** | API client + page + MSW |
| **E2E** | Supertest Nest — deps mockadas | Vitest RTL — MemoryRouter + MSW jornada completa |

---

## API — casos prioritários

### lib/

| Arquivo | Casos RED mínimos |
|---------|-------------------|
| `hybrid-score.spec.ts` | Conformidade com/sem Jatobá; partialSource |
| `self-assessment-score.spec.ts` | scale_1_5, yes_no, pesos, exclude text |
| `improvement-orientations.spec.ts` | below/above adequate; Conformidade + temas Jatobá |
| `jatoba-dimension-map.spec.ts` | agregação 8 regras JAT-CMP-* |
| `indicators/artefact-funnel.spec.ts` | progresso N/7 via mapper mock |

### use-cases/

| Use case | Casos |
|----------|-------|
| `submit-self-assessment` | obrigatórias pendentes → 400; sucesso → snapshot |
| `patch-self-assessment-answers` | draft criado; respostas upsert; FR-008 |
| `get-maturidade-dashboard` | empty, submitted, history ≥2, partialSource |
| `compute-and-persist-score` | híbrido só Conformidade; overall ponderado |
| `ensure-current-period` | trimestre corrente criado |

### Guard / licença

- Sem Carvalho → 403
- Sem módulo compras → 403
- Carvalho expirado: GET ok; PUT/PATCH bloqueados

### Read-only Base (SC-005)

- Integration: submit avaliação → assert demandas/artefatos inalterados (fixture before/after)

---

## Client — casos prioritários

| Teste | Assert |
|-------|--------|
| Empty state | CTA questionário; sem radar scores |
| Draft banner | pendingRequiredCount; continuar dialog |
| Dashboard submitted | 4 score cards + radar + timeline se history≥2 |
| Orientations panel | dimensão <60 mostra ações; ≥60 reconhecimento |
| SelfAssessmentDialog | PATCH debounced; PUT validação pendentes |
| Export | disabled sem submission; HTML abre |
| Licença | alerta Carvalho; histórico visível expirado |

---

## Fixtures

**API** (`compras-maturidade/test/fixtures/`):

- `dashboard-full.json`, `dashboard-empty.json`, `dashboard-draft.json`
- `self-assessment-questions.json`
- `jatoba-checks-sample.json` (8 JAT-CMP-*)

**Client** (`modules/compras/fixtures/`):

- Espelho dashboard + MSW handlers

---

## Comandos

```powershell
cd ci-api-v2; npm test -- --testPathPatterns=compras-maturidade
cd ci-client-v2/apps/web; npm test -- compras-maturidade
cd ci-api-v2; npm test -- --testPathPatterns=compras-maturidade.e2e
```

---

## Cobertura mínima antes de merge

- [ ] Todos os FR-001–FR-015 com ≥1 teste automatizado
- [ ] SC-005 read-only validado integration API
- [ ] SC-007 draft persistência PATCH integration
- [ ] Contrato REST validado Supertest + Zod client
