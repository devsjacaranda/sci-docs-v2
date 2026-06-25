# Contract: Test Strategy — Insights Cedro Ouvidoria

**Feature**: 007-ouvidoria-cedro-insights  
**References**: [plan.md](../plan.md) · constitution II · [rest-api-ouvidoria-insights.md](./rest-api-ouvidoria-insights.md) · [client-ouvidoria-insights-ui.md](./client-ouvidoria-insights-ui.md)

## Princípio: sem banco extra

Todos os testes rodam **sem Postgres de teste dedicado** (`ci_api_v2_test`). Persistência em testes usa:

- **API**: `jest.fn()` no `PrismaService` ou store in-memory em `*.integration-spec.ts`
- **Client**: MSW 2.x mockando `GET/POST /ouvidoria/insights*`
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

## Infraestrutura

### API (`ci-api-v2`)

| Ferramenta | Uso |
|------------|-----|
| Jest | unit + integration + e2e |
| Supertest | E2E HTTP |
| `jest.useFakeTimers()` | throttle 1h, janela 90d, cron job |

**Scripts**:

```powershell
cd ci-api-v2
npm test
npm run test:e2e
```

### Client (`ci-client-v2/apps/web`)

| Ferramenta | Uso |
|------------|-----|
| Vitest 3 | runner |
| `@testing-library/react` | component + E2E UI |
| `@testing-library/user-event` | cliques Consultar IA, sheet |
| `msw` | mock API insights |
| `jsdom` | DOM |

**Scripts**:

```powershell
cd ci-client-v2/apps/web
npm run test
npm run typecheck
```

---

## Matriz por camada

### 1. Unitário — API

**Local**: `ci-api-v2/src/modules/ouvidoria-insights/lib/**/*.spec.ts` e `test/use-cases/*.spec.ts`

| Arquivo | Funções / classes | Casos mínimos |
|---------|-------------------|---------------|
| `operational.rules.spec.ts` | volume, backlog, aging | CT-INS-OP-001…003 |
| `geographic.rules.spec.ts` | pico município/bairro | CT-INS-GEO-001 |
| `text-frequency.rules.spec.ts` | top-N termos, min volume | CT-INS-TXT-001, omit &lt; 5 |
| `profile.rules.spec.ts` | anônimas, tipo×prioridade | CT-INS-PRF-001 |
| `insight-impact.spec.ts` | critical/high/medium | thresholds |
| `analysis-window.spec.ts` | 90 dias | frozen date |
| `throttle.spec.ts` | 1h on_demand | fake timers |
| `generate-insights.use-case.spec.ts` | orquestração | mock repos, no prisma |

**Input**: fixtures `test/fixtures/manifestacoes-sample.json` (array in-memory).

### 2. Unitário — Client

**Local**: `modules/ouvidoria/__tests__/insights-mappers.test.ts`

| Caso | ID |
|------|-----|
| `impact` API → label PT-BR | CT-INS-MAP-001 |
| `origin` → label Agendada/Sob demanda | CT-INS-MAP-002 |
| `emptyReason` → mensagem UI | CT-INS-MAP-003 |

---

### 3. Componente — Client

**Local**: `modules/ouvidoria/__tests__/*.test.tsx`

| Arquivo | Componente | IDs |
|---------|------------|-----|
| `InsightCard.test.tsx` | `InsightCard` | CMP-INS-003 |
| `InsightTraceSheet.test.tsx` | sheet | CMP-INS-004, CMP-INS-005 |
| `InsightsHistoryPanel.test.tsx` | histórico | CMP-INS-006 |
| `InsightsPanel.test.tsx` | lista + empty | CMP-INS-001, CMP-INS-002 |

Setup: MSW handlers + `render` com providers mínimos.

---

### 4. Contrato

#### API — Zod + fixtures

**Local**: `ouvidoria-insights.schemas.spec.ts`

| Caso | ID |
|------|-----|
| Response list parse `insight-batch-completed.json` | CT-INS-001 |
| Trace parse sem `externalQueries` | CT-INS-004 |
| Generate 429 body | CT-INS-006 |
| Reject trace com `externalQueries` | CT-INS-004 neg |

#### API — Supertest (validação body vs schema)

Em `ouvidoria-insights.e2e-spec.ts` com mocks configurados para retornar fixtures — valida shape CT-INS-*.

#### Client — Zod + fixtures

**Local**: `insights.contract.test.ts`

| Caso | ID |
|------|-----|
| Parse fixtures JSON client | CT-INS-001 |
| MSW handler URL paths match contract | CT-INS-HTTP-001 |

Fixtures: `modules/ouvidoria/fixtures/insights-*.json`

---

### 5. Integração (sem DB)

#### API — use-case + repository mock

**Local**: `*.integration-spec.ts` (suffix ou pasta `test/integration/`)

| Arquivo | O que integra | Estratégia |
|---------|---------------|------------|
| `generate-insights.integration-spec.ts` | Load fixtures → rules → persist mock | `Map` in-memory simula batch store |
| `list-insights.integration-spec.ts` | último batch + insights | seed Map no beforeEach |

**Não** usar `AppModule` completo se lento — preferir TestingModule só com use-cases + mock repos.

#### Client — api + MSW

**Local**: `OuvidoriaInsightsPage.integration.test.tsx`

| Caso | ID |
|------|-----|
| `fetchInsights()` + render lista | INT-INS-001 |
| generate → refetch lista | INT-INS-002 |
| histórico batches | INT-INS-003 |

MSW intercepta; sem `VITE_API_URL` real.

---

### 6. E2E (sem browser automation)

#### API E2E — Supertest

**Local**: `ci-api-v2/test/ouvidoria-insights.e2e-spec.ts`

Padrão [`ouvidoria.e2e-spec.ts`](../../../ci-api-v2/test/ouvidoria.e2e-spec.ts):

- `FastifyAdapter` + `AppModule` ou módulo isolado
- `PrismaService` mock + `tenantLicenca` inclui **cedro**
- `moduloSetor` ouvidoria habilitado

| Caso | ID |
|------|-----|
| GET insights 200 + Cedro licença | E2E-INS-001 |
| GET insights 403 sem setor | E2E-INS-002 |
| POST generate throttle 429 | E2E-INS-003 |
| GET trace sem PII | E2E-INS-004 |
| POST generate não altera manifestacao mock | E2E-INS-005 (SC-005) |

#### Client E2E — Vitest journey

**Local**: `OuvidoriaInsightsPage.e2e.test.tsx`

Jornada completa em jsdom (não Playwright):

1. MemoryRouter initial `/ouvidoria/insights`
2. MSW retorna batch + 4 insights
3. User clica *De onde veio este insight?* → sheet visível (CMP-INS-004)
4. User clica *Consultar IA* → MSW POST → lista atualizada (CMP-INS-007)
5. Verifica ≤ 3 cliques simulados desde wrapper overview (E2E-INS-UI-001)

| Caso | ID |
|------|-----|
| Jornada insight + trace + consultar | E2E-INS-UI-001 |
| Empty state + CTA | E2E-INS-UI-002 |
| Throttle toast | E2E-INS-UI-003 |

---

## MSW handlers (client test only)

```typescript
// handlers/ouvidoria-insights.ts
http.get('*/ouvidoria/insights', ...)
http.get('*/ouvidoria/insights/batches', ...)
http.get('*/ouvidoria/insights/batches/:id', ...)
http.get('*/ouvidoria/insights/:id/trace', ...)
http.post('*/ouvidoria/insights/generate', ...)
```

---

## TDD workflow (implementação)

Ordem obrigatória:

```text
API lib rules.spec (RED) → rules.ts (GREEN)
API schemas.spec → schemas.ts
API use-case.spec → use-case + repository mock
API integration-spec → wire repos in-memory
API e2e-spec → Supertest guards + CT IDs
Client contract.test → api/insights.ts types
Client component tests → components
Client integration.test → page + MSW
Client e2e.test → full journey
```

---

## CI gate (sem banco extra)

```powershell
cd ci-api-v2; npm test; npm run test:e2e
cd ci-client-v2/apps/web; npm run test; npm run typecheck
```

**Expected**: exit 0; todos IDs CT-INS / CMP-INS / E2E-INS MUST pass.

---

## O que NÃO testar

- Postgres real ou Neon de teste
- Job cron disparando em CI com wait real (usar fake timers + unit)
- Playwright / Cypress
- Integrações externas (Fala.BR, NLP)
- Alteração de manifestações após insights (validar só via mock call counts)
