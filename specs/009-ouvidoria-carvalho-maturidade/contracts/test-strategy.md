# Contract: Test Strategy — Maturidade Carvalho Ouvidoria

**Feature**: 009-ouvidoria-carvalho-maturidade  
**References**: [plan.md](../plan.md) · constitution II · [rest-api-ouvidoria-maturidade.md](./rest-api-ouvidoria-maturidade.md) · [client-ouvidoria-maturidade-ui.md](./client-ouvidoria-maturidade-ui.md)

## Princípio: sem banco extra

Todos os testes rodam **sem Postgres de teste dedicado**. Persistência em testes usa:

- **API**: `jest.fn()` no `PrismaService` ou store in-memory em `*.integration-spec.ts`
- **Client**: MSW 2.x mockando `/ouvidoria/maturidade*`
- **Fixtures JSON** compartilhadas entre contract, integration e E2E

Produção usa Postgres real via Prisma; testes **nunca** conectam a banco externo.

---

## Escopo de testes

| Camada | Incluído | Excluído |
|--------|----------|----------|
| Unitário | ✅ | — |
| Componente | ✅ | — |
| Contrato | ✅ | — |
| Integração | ✅ (mocks/in-memory) | Postgres real, fetch real |
| E2E | ✅ (Supertest + RTL journey) | Playwright/Cypress, browser real |

---

## Matriz por camada

### 1. Unitário — API

**Local**: `ci-api-v2/src/modules/ouvidoria-maturidade/lib/**/*.spec.ts`

| Arquivo | Funções | Casos mínimos |
|---------|---------|---------------|
| `hybrid-score.spec.ts` | R-50, partialSource | CT-MAT-SCR-001…004 |
| `jatoba-axis-map.spec.ts` | ruleId → axis | CT-MAT-MAP-001 |
| `conformity-rate-by-axis.spec.ts` | partial=50%, NC=0 | CT-MAT-JAT-001 |
| `self-assessment-score.spec.ts` | weighted avg | CT-MAT-SELF-001 |
| `maturity-alert.spec.ts` | &lt;70 critical, 70–79 attention | CT-MAT-ALR-001 |
| `volume.indicator.spec.ts` | count | CT-MAT-IND-VOL |
| `response-time.indicator.spec.ts` | avg days | CT-MAT-IND-RT |
| `overdue-rate.indicator.spec.ts` | % PRZ non_conforme | CT-MAT-IND-OD |
| `resolution-rate.indicator.spec.ts` | closed/total | CT-MAT-IND-RES |
| `satisfaction.indicator.spec.ts` | hybrid 50/50, partial | CT-MAT-IND-SAT |

**Input**: fixtures `test/fixtures/jatoba-checks-sample.json`, `self-assessment-answers.json`

### 2. Unitário — Client

**Local**: `modules/ouvidoria/__tests__/maturidade-mappers.test.ts`

| Caso | ID |
|------|-----|
| `overallAlert` → label Crítico/Atenção | CT-MAT-MAP-001 |
| axis enum → label PT-BR | CT-MAT-MAP-002 |
| `partialSource` → badge copy | CT-MAT-MAP-003 |
| Nivo radar adapter 3 eixos | CT-MAT-MAP-004 |
| Timeline adapter history | CT-MAT-MAP-005 |

---

### 3. Componente — Client

| Arquivo | Componente | IDs |
|---------|------------|-----|
| `MaturidadeScoreCards.test.tsx` | score + empty | CMP-MAT-001, CMP-MAT-002 |
| `MaturidadeRadarChart.test.tsx` | radar + meta 80 | CMP-MAT-003 |
| `MaturidadeTimelineChart.test.tsx` | 1 vs 2+ points | CMP-MAT-004 |
| `MaturidadeIndicatorsRow.test.tsx` | 5 indicadores | CMP-MAT-005 |
| `MaturidadeTraceSheet.test.tsx` | sheet 85%, título | CMP-MAT-006 |
| `SelfAssessmentDialog.test.tsx` | submit PUT | CMP-MAT-007 |
| `ActionPlansPanel.test.tsx` | filtros + nota | CMP-MAT-008 |

---

### 4. Contrato

#### API — Zod + fixtures

**Local**: `ouvidoria-maturidade.schemas.spec.ts`

| Caso | ID |
|------|-----|
| Dashboard parse `maturidade-dashboard-full.json` | CT-MAT-001 |
| Dashboard empty `no_self_assessment` | CT-MAT-002 |
| Score trace sem PII fields | CT-MAT-003 |
| Action plan body validation | CT-MAT-004 |

#### Client — contract.test.ts + MSW paths

Fixtures: `modules/ouvidoria/fixtures/maturidade-*.json`

---

### 5. Integração (sem DB)

#### API

| Arquivo | Estratégia |
|---------|------------|
| `submit-self-assessment.integration-spec.ts` | Map in-memory submission + snapshot |
| `get-dashboard.integration-spec.ts` | mock fiscalização run + manifestações |
| `action-plans.integration-spec.ts` | CRUD Map |

#### Client

**Local**: `OuvidoriaMaturidadePage.integration.test.tsx`

| Caso | ID |
|------|-----|
| fetch dashboard + render score | INT-MAT-001 |
| submit autoavaliação → refetch | INT-MAT-002 |
| criar plano de ação | INT-MAT-003 |

---

### 6. E2E (sem browser automation)

#### API E2E — Supertest

**Local**: `ci-api-v2/test/ouvidoria-maturidade.e2e-spec.ts`

| Caso | ID |
|------|-----|
| GET maturidade 200 + licença carvalho | E2E-MAT-001 |
| GET 403 sem setor ouvidoria | E2E-MAT-002 |
| PUT self-assessment → snapshot | E2E-MAT-003 |
| Score indisponível sem submission (SC-006) | E2E-MAT-004 |
| POST action-plan 403 não-gestor | E2E-MAT-005 |
| Operações não alteram manifestacao (SC-004) | E2E-MAT-006 |
| Hybrid formula 60/40 (SC-002) | E2E-MAT-007 |

#### Client E2E — Vitest journey

**Local**: `OuvidoriaMaturidadePage.e2e.test.tsx`

1. MemoryRouter `/ouvidoria/maturidade`
2. MSW dashboard full fixture
3. Clicar *Como calculamos este score?* → sheet (CMP-MAT-006)
4. Responder autoavaliação → score atualiza (CMP-MAT-007)
5. Gestor cria plano → lista (CMP-MAT-008)
6. ≤ 3 cliques desde overview wrapper (SC-001)

---

## MSW handlers (client test only)

```typescript
http.get('*/ouvidoria/maturidade', ...)
http.get('*/ouvidoria/maturidade/score/trace', ...)
http.get('*/ouvidoria/maturidade/indicators/:type/trace', ...)
http.get('*/ouvidoria/maturidade/self-assessment', ...)
http.put('*/ouvidoria/maturidade/self-assessment', ...)
http.get('*/ouvidoria/maturidade/action-plans', ...)
http.post('*/ouvidoria/maturidade/action-plans', ...)
http.patch('*/ouvidoria/maturidade/action-plans/:id', ...)
http.post('*/ouvidoria/maturidade/action-plans/:id/notes', ...)
```

---

## TDD workflow (implementação)

```text
API lib hybrid-score.spec (RED) → hybrid-score.ts (GREEN)
API lib indicators/*.spec → indicators/*.ts
API schemas.spec → schemas.ts
API use-case.spec → use-case + repository mock
API integration-spec → wire in-memory
API e2e-spec → Supertest guards
Client contract.test → api/maturidade.ts
Client component tests → components
Client integration.test → page + MSW
Client e2e.test → full journey
```

---

## CI gate (sem banco extra)

```powershell
cd ci-api-v2; npm test; npm run test:e2e -- --testPathPattern=ouvidoria-maturidade
cd ci-client-v2/apps/web; npm run test -- maturidade; npm run typecheck
```

**Expected**: exit 0; todos IDs CT-MAT / CMP-MAT / E2E-MAT MUST pass.

---

## O que NÃO testar

- Postgres real ou Neon de teste
- Export PDF (out of scope)
- Dashboard Global Carvalho
- Playwright / Cypress
- Alteração de manifestações/achados após uso maturidade (validar mock call counts)
- Fórmula editável pelo usuário (v1 fixa)
