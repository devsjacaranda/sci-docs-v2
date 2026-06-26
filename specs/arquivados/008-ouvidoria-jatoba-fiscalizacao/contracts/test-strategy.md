# Contract: Test Strategy — Fiscalização Jatobá Ouvidoria

**Feature**: 008-ouvidoria-jatoba-fiscalizacao  
**References**: [plan.md](../plan.md) · constitution II · [rest-api-ouvidoria-fiscalizacao.md](./rest-api-ouvidoria-fiscalizacao.md) · [client-ouvidoria-fiscalizacao-ui.md](./client-ouvidoria-fiscalizacao-ui.md)

## Princípio: sem banco extra

Todos os testes rodam **sem Postgres de teste dedicado** (`ci_api_v2_test`). Persistência em testes usa:

- **API**: `jest.fn()` no `PrismaService` ou store in-memory em `*.integration-spec.ts`
- **Client**: MSW 2.x mockando `/ouvidoria/fiscalizacao*`
- **Fixtures JSON** compartilhadas entre contract, integration e E2E

Produção usa Postgres real via Prisma; testes **nunca** conectam a banco externo.

---

## Escopo de testes (5 camadas)

| Camada | Incluído | Excluído |
|--------|----------|----------|
| **Unitário** | ✅ | — |
| **Componente** | ✅ | — |
| **Contrato** | ✅ | — |
| **Integração** | ✅ (mocks/in-memory) | Postgres real, fetch real |
| **E2E** | ✅ (Supertest + RTL journey) | Playwright/Cypress, browser real |

---

## Infraestrutura

### API (`ci-api-v2`)

| Ferramenta | Uso |
|------------|-----|
| Jest | unit + integration + e2e |
| Supertest | E2E HTTP |
| `jest.useFakeTimers()` | throttle 1h, SLA deadline, cron job |

**Scripts**:

```powershell
cd ci-api-v2
npm test
npm run test:e2e -- --testPathPattern=ouvidoria-fiscalizacao
```

### Client (`ci-client-v2/apps/web`)

| Ferramenta | Uso |
|------------|-----|
| Vitest 3 | runner |
| `@testing-library/react` | component + E2E UI |
| `@testing-library/user-event` | cliques Fiscalizar, sheet, questionário |
| `msw` | mock API fiscalização |
| `jsdom` | DOM |

**Scripts**:

```powershell
cd ci-client-v2/apps/web
npm run test -- fiscalizacao
npm run typecheck
```

---

## Matriz por camada

### 1. Unitário — API

**Local**: `ci-api-v2/src/modules/ouvidoria-fiscalizacao/lib/**/*.spec.ts` e `test/use-cases/*.spec.ts`

| Arquivo | Funções / classes | Casos mínimos | ID |
|---------|-------------------|---------------|-----|
| `deadline.rules.spec.ts` | SLA + eventos | vencido → non_conforme; no prazo → conforme; ≤20% → partial | CT-FIS-PRZ-001…003 |
| `forwarding.rules.spec.ts` | tramitação | sem destino → non_conforme; gap → partial | CT-FIS-TRM-001 |
| `completeness.rules.spec.ts` | campos obrigatórios | completo → conforme | CT-FIS-CMP-001 |
| `contact.rules.spec.ts` | anônimo/contato | sem contato identificado → partial | CT-FIS-CNT-001 |
| `evidence.rules.spec.ts` | resposta sem evento | non_conforme | CT-FIS-EVD-001 |
| `aggregate-conformity.spec.ts` | pior status | non_conforme > partial | CT-FIS-AGG-001 |
| `sla-resolver.spec.ts` | defaults por tipo | complaint 30d | CT-FIS-SLA-001 |
| `throttle.spec.ts` | 1h on_demand | fake timers 429 | CT-FIS-THR-001 |
| `run-fiscalizacao.use-case.spec.ts` | orquestração | mock repos, no prisma | CT-FIS-UC-001 |
| `questionnaire-eligibility.spec.ts` | externo | anônimo blocked | CT-FIS-QEL-001 |

**Input**: fixtures `test/fixtures/manifestacoes-fiscalizacao-sample.json`.

---

### 2. Unitário — Client

**Local**: `modules/ouvidoria/__tests__/fiscalizacao-mappers.test.ts`

| Caso | ID |
|------|-----|
| `conformityStatus` API → label PT-BR (4 valores) | CT-FIS-MAP-001 |
| `origin` → label Agendada/Sob demanda/Por registro | CT-FIS-MAP-002 |
| `flowState` → label fluxo (≠ conformidade) | CT-FIS-MAP-003 |
| `emptyReason` → mensagem UI | CT-FIS-MAP-004 |
| `canExternal` mapper | CT-FIS-MAP-005 |

---

### 3. Componente — Client

**Local**: `modules/ouvidoria/__tests__/*.test.tsx`

| Arquivo | Componente | IDs |
|---------|------------|-----|
| `FiscalizacaoPanel.test.tsx` | painel + stats 4 badges | CMP-FIS-001, CMP-FIS-002 |
| `FiscalizacaoTraceSheet.test.tsx` | títulos canônicos por traceType | CMP-FIS-003, CMP-FIS-004 |
| `FiscalizacaoHistoryTable.test.tsx` | colunas histórico | CMP-FIS-005 |
| `FiscalizacaoRecordCard.test.tsx` | card detalhe + Fiscalizar dados | CMP-FIS-006 |
| `QuestionnaireDialog.test.tsx` | omit externo anônimo | CMP-FIS-007 |
| `QuestionBankPanel.test.tsx` | CRUD lista | CMP-FIS-008 |

Setup: MSW handlers + `render` com providers mínimos.

---

### 4. Contrato

#### API — Zod + fixtures

**Local**: `ouvidoria-fiscalizacao.schemas.spec.ts`

| Caso | ID |
|------|-----|
| Response panel parse `fiscalizacao-run-completed.json` | CT-FIS-001 |
| Trace check parse steps + sem PII | CT-FIS-004 |
| Run throttle 429 body | CT-FIS-006 |
| Questionnaire create external responseLink | CT-FIS-007 |
| Reject conformity enum inválido (5º status) | CT-FIS-008 neg |

#### API — Supertest (validação body vs schema)

Em `ouvidoria-fiscalizacao.e2e-spec.ts` com mocks — valida shape CT-FIS-*.

#### Client — Zod + fixtures

**Local**: `fiscalizacao.contract.test.ts`

| Caso | ID |
|------|-----|
| Parse fixtures JSON client | CT-FIS-001 |
| MSW handler URL paths match contract | CT-FIS-HTTP-001 |
| Public respond schema | CT-FIS-HTTP-002 |

Fixtures: `modules/ouvidoria/fixtures/fiscalizacao-*.json`

---

### 5. Integração (sem DB)

#### API — use-case + repository mock

**Local**: `test/integration/*.integration-spec.ts`

| Arquivo | O que integra | Estratégia |
|---------|---------------|------------|
| `run-fiscalizacao.integration-spec.ts` | fixtures → rules → persist mock | `Map` in-memory simula run store |
| `list-fiscalizacao-panel.integration-spec.ts` | último run + history rows | seed Map no beforeEach |
| `questionnaire-flow.integration-spec.ts` | create → respond internal | in-memory questionnaire store |
| `external-respond.integration-spec.ts` | token hash → public respond | bcrypt mock |

**Não** usar `AppModule` completo se lento — preferir TestingModule só com use-cases + mock repos.

#### Client — api + MSW

**Local**: `OuvidoriaAuditoriaPage.integration.test.tsx`

| Caso | ID |
|------|-----|
| `fetchFiscalizacaoPanel()` + render stats | INT-FIS-001 |
| run → refetch painel | INT-FIS-002 |
| histórico runs ≥ 3 items | INT-FIS-003 |
| criar questionário interno | INT-FIS-004 |

MSW intercepta; sem `VITE_API_URL` real.

---

### 6. E2E (sem browser automation)

#### API E2E — Supertest

**Local**: `ci-api-v2/test/ouvidoria-fiscalizacao.e2e-spec.ts`

Padrão [`ouvidoria-insights.e2e-spec.ts`](../../../ci-api-v2/test/ouvidoria-insights.e2e-spec.ts):

- `FastifyAdapter` + módulo isolado ou `AppModule`
- `PrismaService` mock + `tenantLicenca` inclui **jatoba**
- `moduloSetor` ouvidoria habilitado

| Caso | ID |
|------|-----|
| GET panel 200 + Jatobá licença | E2E-FIS-001 |
| GET panel 403 sem setor | E2E-FIS-002 |
| POST run throttle 429 | E2E-FIS-003 |
| GET check trace sem PII anônimo | E2E-FIS-004 |
| POST run não altera manifestacao mock | E2E-FIS-005 (SC-004) |
| POST questionnaire external 400 anônimo | E2E-FIS-006 |
| GET public respond 200 token válido | E2E-FIS-007 |
| POST scoped run manifestacao | E2E-FIS-008 |

#### Client E2E — Vitest journey

**Local**: `OuvidoriaAuditoriaPage.e2e.test.tsx`

Jornada completa em jsdom:

1. MemoryRouter initial `/ouvidoria/auditoria`
2. MSW retorna run + findings + history
3. User clica rastreio checagem → sheet título **Por que esta checagem deu este resultado** (CMP-FIS-004)
4. User clica *Fiscalizar manifestações* → MSW POST → stats atualizados (CMP-FIS-009)
5. User abre *Novo questionário* interno → submit → histórico atualizado
6. Verifica ≤ 3 cliques desde wrapper overview (E2E-FIS-UI-001)

| Caso | ID |
|------|-----|
| Jornada painel + trace + fiscalizar | E2E-FIS-UI-001 |
| Empty state + CTA | E2E-FIS-UI-002 |
| Throttle toast | E2E-FIS-UI-003 |
| Card detalhe Fiscalizar dados (wrapper route) | E2E-FIS-UI-004 |
| Externo omitido para anônimo | E2E-FIS-UI-005 |

---

## MSW handlers (client test only)

```typescript
// handlers/ouvidoria-fiscalizacao.ts
http.get('*/ouvidoria/fiscalizacao', ...)
http.get('*/ouvidoria/fiscalizacao/runs', ...)
http.get('*/ouvidoria/fiscalizacao/runs/:runId', ...)
http.post('*/ouvidoria/fiscalizacao/run', ...)
http.post('*/ouvidoria/fiscalizacao/run/manifestacoes/:id', ...)
http.get('*/ouvidoria/fiscalizacao/checks/:checkId/trace', ...)
http.get('*/ouvidoria/fiscalizacao/findings/:findingId/trace', ...)
http.get('*/ouvidoria/fiscalizacao/manifestacoes/:id', ...)
http.get('*/ouvidoria/fiscalizacao/manifestacoes/:id/trace', ...)
http.get('*/ouvidoria/fiscalizacao/questions', ...)
http.post('*/ouvidoria/fiscalizacao/questions', ...)
http.patch('*/ouvidoria/fiscalizacao/questions/:id', ...)
http.get('*/ouvidoria/fiscalizacao/questionnaires', ...)
http.post('*/ouvidoria/fiscalizacao/questionnaires', ...)
http.post('*/ouvidoria/fiscalizacao/questionnaires/:id/respond', ...)
http.get('*/public/ouvidoria/fiscalizacao/responder/:token', ...)
http.post('*/public/ouvidoria/fiscalizacao/responder/:token', ...)
```

---

## TDD workflow (implementação)

Ordem obrigatória:

```text
API lib checks.spec (RED) → checks/*.ts (GREEN)
API schemas.spec → schemas.ts
API use-case.spec → use-case + repository mock
API integration-spec → wire repos in-memory
API e2e-spec → Supertest guards + CT IDs
Client contract.test → api/fiscalizacao.ts types
Client mappers.test → fiscalizacao-mappers.ts
Client component tests → components
Client integration.test → page + MSW
Client e2e.test → full journey
ManifestacaoDetailPage + FiscalizacaoRecordCard (component + integration)
```

Cada user story P1 deve ter ≥ 1 teste E2E ou integration cobrindo acceptance scenario principal.

---

## CI gate (sem banco extra)

```powershell
cd ci-api-v2; npm test; npm run test:e2e -- --testPathPattern=ouvidoria-fiscalizacao
cd ci-client-v2/apps/web; npm run test -- fiscalizacao; npm run typecheck
```

**Expected**: exit 0; todos IDs CT-FIS / CMP-FIS / INT-FIS / E2E-FIS MUST pass.

---

## Cobertura mínima por FR crítico

| FR | Camada de teste |
|----|-----------------|
| FR-003 (4 status) | unit aggregate + CMP-FIS-002 |
| FR-004 (fluxo ≠ conformidade) | unit mapper + CMP-FIS-007 |
| FR-009 (throttle) | unit throttle + E2E-FIS-003 + E2E-FIS-UI-003 |
| FR-011 (SLA) | unit deadline + sla-resolver |
| FR-015 (sheet) | CMP-FIS-003/004 + E2E-FIS-UI-001 |
| FR-016 (PII) | E2E-FIS-004 + trace contract |
| FR-020 (link externo) | integration questionnaire + E2E-FIS-007 |
| FR-021 (omit externo) | unit eligibility + E2E-FIS-UI-005 |
| FR-002/SC-004 (read-only) | E2E-FIS-005 |

---

## O que NÃO testar

- Postgres real ou Neon de teste
- Job cron com wait real (fake timers + unit)
- Playwright / Cypress
- WhatsApp Business API / SMTP
- Hub global `/global/auditoria`
- Alteração de manifestações após fiscalização (mock call counts only)
- Score Carvalho
