# Test Strategy: Fiscalização Gabinete — Jatobá Integrada

**Feature**: 016-gabinete-fiscalizacao-integrada  
**Princípio**: TDD RED → GREEN → REFACTOR; **sem Postgres de teste dedicado**

## Camadas

| Camada | Pacote | Ferramenta | Escopo |
|--------|--------|------------|--------|
| Unitário API | `ci-api-v2` | Jest | Regras puras `lib/checks/*`, `aggregate-ato-with-links`, throttle, mappers |
| Unitário Client | `ci-client-v2` | Vitest | `fiscalizacao-mappers.ts`, labels órfãos |
| Integração API | `ci-api-v2` | Jest | Use-cases + repositories Prisma mock |
| E2E API | `ci-api-v2` | Jest Supertest | Guards 403, Jatobá 200, throttle 429, read-only SC-005 |
| Componente Client | `ci-client-v2` | Vitest + RTL | Painel, trace sheet títulos, card ato |
| Integração Client | `ci-client-v2` | Vitest + MSW | `GabineteAuditoriaPage` load + run |
| E2E Client | `ci-client-v2` | Vitest | Jornada completa auditoria |

---

## API — casos obrigatórios

### Unit (`lib/checks/`)

| Spec file | Cenários mínimos |
|-----------|------------------|
| `deadline.rules.spec.ts` | vencido → non_conforme; no prazo → conforme |
| `forwarding.rules.spec.ts` | gap > 5 dias → non_conforme/partial |
| `completeness.rules.spec.ts` | assunto vazio → partial |
| `evidence.rules.spec.ts` | anexo pending → partial |
| `protocol.rules.spec.ts` | status avançado sem protocolo; campos críticos vazios |
| `controle-numerico.rules.spec.ts` | sem número e data → partial |
| `notificacao.rules.spec.ts` | dueDate vencido; termo vazio |
| `auto-infracao.rules.spec.ts` | dueDate vencido; issuingSector vazio |
| `pairing.rules.spec.ts` | groupId sem par → partial; groupId null → skip |
| `documento-tramitado.rules.spec.ts` | prazo vencido |
| `aggregate-ato-with-links.spec.ts` | worst-of ato + protocolo + 2 controles |

### Integração use-cases

| Use-case | Assert |
|----------|--------|
| `RunFiscalizacaoUseCase` | persiste run + results atos + órfãos; counts corretos |
| `RunFiscalizacaoScopedUseCase` | só 1 ato; origin `on_record` |
| `GetFiscalizacaoPanelUseCase` | checksSummary agregado; historyRows |
| `CreateQuestionnaireUseCase` | internal only; flowState |
| `SubmitQuestionnaireAnswersUseCase` | respondedAt; flowState `responded` |

### E2E Supertest (`gabinete-fiscalizacao.e2e-spec.ts`)

1. GET panel sem licença → 403
2. POST run com licença → 202; segundo POST < 1h → 429
3. POST run não altera `CabinetDemanda.status` (snapshot before/after)
4. GET ato scoped retorna checks após run

**Mock**: PrismaService / repositories in-memory — padrão `ouvidoria-fiscalizacao.e2e-spec.ts`.

---

## Client — casos obrigatórios

### Mappers

- `entityTypeLabel('notificacao')` → `'Notificação'`
- `formatOrphanProtocolLabel(...)` → `'Cadastro órfão — Notificação'`
- conformity labels 4 status canônicos

### Componente

- `FiscalizacaoPanel` com props Gabinete — título, botão *Fiscalizar atos*
- `FiscalizacaoTraceSheet` — títulos canônicos §3 regras-plataforma
- `GabineteFiscalizacaoRecordCard` — empty state + ação

### Integração / E2E

1. Load panel empty → CTA fiscalizar
2. Run → refetch → stats visíveis
3. Click checagem → sheet título correto
4. Novo questionário interno → histórico atualiza

**MSW**: `handlers/gabinete-fiscalizacao.ts` registrado em `setupTests`.

---

## Fixtures JSON

```
ci-api-v2/src/modules/gabinete-fiscalizacao/test/fixtures/
├── ato-fiscalizacao-sample.json
├── orphan-notificacao-sample.json
├── fiscalizacao-run-completed-with-orphans.json
└── fiscalizacao-panel-completed.json

ci-client-v2/apps/web/src/modules/gabinete/fixtures/
├── fiscalizacao-panel-empty.json
├── fiscalizacao-panel-completed.json
└── fiscalizacao-record-partial.json
```

---

## Comandos CI

```powershell
# API
cd ci-api-v2
npm test -- --testPathPattern=gabinete-fiscalizacao
npm run test:e2e -- --testPathPattern=gabinete-fiscalizacao

# Client
cd ci-client-v2
npm test --workspace=@ci/web -- --run GabineteAuditoria
npm test --workspace=@ci/web -- --run fiscalizacao
npm run typecheck --workspace=@ci/web
```

---

## Ordem TDD sugerida (tasks.md)

1. Rules unit (RED) → implement checks (GREEN)
2. Migration + load repositories
3. Run use-case integration
4. Controller + e2e API
5. Client mappers + MSW
6. GabineteAuditoriaPage integration
7. Record card + scoped run
8. Questions/questionnaires
9. Polish + quickstart manual

---

## Fora do escopo de teste

- Questionário externo / rota pública
- Carvalho/Cedro consumo pós-run
- Performance load test (>500 registros) — manual quickstart apenas
