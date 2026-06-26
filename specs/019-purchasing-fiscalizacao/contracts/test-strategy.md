# Test Strategy: Fiscalização Compras — Jatobá

**Feature**: 019-purchasing-fiscalizacao  
**Princípio**: TDD RED → GREEN → REFACTOR; **sem Postgres de teste dedicado**

## Camadas

| Camada | Pacote | Ferramenta | Escopo |
|--------|--------|------------|--------|
| Unitário API | `ci-api-v2` | Jest | Regras puras `lib/checks/*`, `aggregate-conformity`, throttle, mappers |
| Unitário Client | `ci-client-v2` | Vitest | `fiscalizacao-mappers.ts`, labels demanda/PCA |
| Integração API | `ci-api-v2` | Jest | Use-cases + repositories Prisma mock |
| E2E API | `ci-api-v2` | Jest Supertest | Guards 403, Jatobá 200, throttle 429, read-only SC-005 |
| Componente Client | `ci-client-v2` | Vitest + RTL | Painel, trace sheet títulos, card demanda |
| Integração Client | `ci-client-v2` | Vitest + MSW | `ComprasFiscalizacaoPage` load + run |
| E2E Client | `ci-client-v2` | Vitest | Jornada SC-007 ponta a ponta |

---

## API — casos obrigatórios

### Unit (`lib/checks/`)

| Spec file | Cenários mínimos |
|-----------|------------------|
| `dfd-completeness.rules.spec.ts` | DFD ausente → pending; campos vazios → non_conforme/partial; completo → conforme |
| `etp-waiver.rules.spec.ts` | waived sem motivo → non_conforme; waived com motivo → conforme; preenchido → conforme |
| `risk-analysis.rules.spec.ts` | risks vazio → partial/non_conforme; ≥1 risco → conforme |
| `tr-completeness.rules.spec.ts` | TR ausente → pending; incompleto → partial |
| `price-survey.rules.spec.ts` | estimatedValue null/0 → partial; válido → conforme |
| `budget-allocation.rules.spec.ts` | campos obrigatórios ausentes → partial |
| `legal-opinion.rules.spec.ts` | opinionText vazio → partial |
| `budget-consistency.rules.spec.ts` | dotado < estimado → partial + achado; dotado ≥ estimado → conforme; um ausente → skip/pending |
| `aggregate-conformity.spec.ts` | worst-of 8 statuses |
| `run-checks-for-demanda.spec.ts` | integração rules + findings count |

### Integração use-cases

| Use-case | Assert |
|----------|--------|
| `RunFiscalizacaoUseCase` | persiste run + 1 result/demanda; counts stats; 100% demandas ativas |
| `RunFiscalizacaoScopedUseCase` | só 1 demanda; origin `on_record`; throttle compartilhado |
| `GetFiscalizacaoPanelUseCase` | checksSummary; historyRows colunas Compras |
| `ListFiscalizacaoRunsUseCase` | paginação |

### E2E Supertest (`compras-fiscalizacao.e2e-spec.ts`)

1. GET panel sem licença Jatobá → 403
2. GET panel sem módulo compras → 403
3. POST run com licença → 202; segundo POST < 1h → 429
4. POST run **não** altera campos `CompraDemanda` / artefatos (snapshot before/after)
5. GET demanda scoped retorna checks após run
6. Tenant sem demandas → panel `emptyReason: no_data`

**Mock**: PrismaService / repositories — padrão `ouvidoria-fiscalizacao.e2e-spec.ts`.

---

## Client — casos obrigatórios

### Mappers

- `formatDemandaProtocol(12)` → `'DEM-12'`
- `conformityLabel('non_conforme')` → `'Não conforme'`
- `emptyReasonMessage('no_data')` → copy orientador spec

### Componente

- `ComprasFiscalizacaoPage` — título **Fiscalização de Compras**, badge **Somente leitura**, botão *Fiscalizar demandas*
- `FiscalizacaoTraceSheet` — 3 títulos canônicos Compras
- `ComprasFiscalizacaoRecordCard` — empty state + scoped action
- `FiscalizacaoHistoryTable` — colunas Demanda/PCA/Artefatos (sem questionário)

### Integração / E2E

1. Load panel empty → CTA fiscalizar
2. Run → refetch → stats 4 conformidades visíveis
3. Click checagem → sheet título **Por que esta checagem deu este resultado**
4. Hub demanda → card → fiscalizar scoped → checagens atualizadas (SC-008)

**MSW**: `handlers/compras-fiscalizacao.ts` em `setupTests`.

---

## Fixtures JSON

```text
ci-api-v2/src/modules/compras-fiscalizacao/test/fixtures/
├── demanda-fiscalizacao-sample.json
├── demanda-etp-waived-sample.json
├── demanda-budget-mismatch-sample.json
├── fiscalizacao-run-completed.json
└── fiscalizacao-panel-completed.json

ci-client-v2/apps/web/src/modules/compras/fixtures/
├── fiscalizacao-panel-empty.json
├── fiscalizacao-panel-completed.json
└── fiscalizacao-record-partial.json
```

---

## Ordem TDD recomendada (tasks)

1. Migration + schema Prisma
2. Rules unit specs (RED) → rules implementation (GREEN)
3. Repositories + use-cases integration
4. Controller + Zod contract spec
5. E2E API read-only + throttle
6. Client mappers + MSW
7. ComprasFiscalizacaoPage integration
8. ComprasFiscalizacaoRecordCard + DemandaHubPage
9. E2E client SC-007

---

## Comandos verificação

```powershell
cd c:\ci-v2\ci-api-v2
npm test -- --testPathPattern=compras-fiscalizacao

cd c:\ci-v2\ci-client-v2
npm test --workspace=@ci/web -- --run ComprasFiscalizacao
npm test --workspace=@ci/web -- --run fiscalizacao-mappers
```
