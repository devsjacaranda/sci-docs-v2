# Test Strategy — 037 Refactor UX do SIGED

**Princípio**: TDD obrigatório (Constitution II) — RED → GREEN → REFACTOR por fatia (US1 → US4).

## Pirâmide

| Camada | API (Jest) | Client (Vitest) |
| --- | --- | --- |
| Unit | Regras JAT-SIG-*, slugs Cedro, tree utils, mappers | `departamentos-tree`, mappers home/insights |
| Integration | Use-cases + Prisma mock + SIGED client mock | API modules + MSW |
| Component | — | RTL Home, Drilldown, alert bar |
| Contract | `*.contract.spec.ts` fixtures JSON | Zod parse responses MSW |

Sem Postgres dedicado em CI — Prisma mock/repositories test doubles (padrão `gabinete-insights`).

---

## US1 — Diretorias agrupadas (P1)

### API
- N/A crítico (hierarquia já testada); opcional teste de coleta snapshot no list protocolos.

### Client
- `listTopLevelOrgaos` retorna só raiz
- `getDirectChildren` retorna filhos diretos
- Leaf navega para protocolos (router test)
- Busca não inclui órgãos fora do escopo

**Gate**: `npm test -- departamentos-tree` + `navigation.siged.test.ts` verde.

---

## US2 — Home post-its (P2)

### API
- `get-siged-home.use-case.spec.ts`: KPIs from snapshots; degraded live; empty cedro post-it
- Snapshot recorder: upsert idempotente `SigedOrgaoDailyMetric`

### Client
- `SigedHomePage`: post-its render; CTA diretorias; alert bar condicional
- Mapper: `never_generated` → post-it empty

**Gate**: contract `GET /siged/home` fixture validado Zod.

---

## US3 — Fiscalização Jatobá (P3)

### API
| Spec | Cenário |
| --- | --- |
| `tramitacao-sla.rules.spec.ts` | >2 dias úteis → non_conforme |
| `stalled-orgao.rules.spec.ts` | >5 dias parado → non_conforme/partial |
| `no-movement.rules.spec.ts` | zero tramitações → pendente |
| `run-fiscalizacao.use-case.spec.ts` | run completed, dataSourceSummary |
| `get-finding-trace.use-case.spec.ts` | trace payload steps |

### Client
- Panel render com run mock
- Trace sheet título correto
- Questionnaire dialog sem canal externo

**Gate**: 100% achados ∈ {Conforme, Não conforme, Parcial, Pendente} (SC-003).

---

## US4 — Insights Cedro (P4)

### API
| Spec | Cenário |
| --- | --- |
| `volume-by-orgao.rules.spec.ts` | MIN_RECORDS threshold |
| `avg-tramitacao.rules.spec.ts` | impacto Alto/Crítico |
| `generate-insights.use-case.spec.ts` | throttle 429, emptyReason |
| `get-insight-trace.use-case.spec.ts` | evidências sigedProtocoloId |

### Client
- Paridade generate/list/trace com Gabinete (MSW)
- Badge Somente leitura presente

**Gate**: nenhuma ação altera protocolo (mock assert) — SC-004.

---

## Regressão

- `siged-portal.controller` endpoints existentes
- `SigedControleInternoForm` submit inalterado
- `navigation.siged.test.ts` — SIGED fora do menu Gabinete
- Export Excel protocolos

---

## Comandos

```powershell
cd ci-api-v2; npm test -- --testPathPatterns=siged
cd ci-client-v2/apps/web; npm test -- siged
```

E2E manual: [quickstart.md](../quickstart.md).

---

## Fixtures

| Arquivo | Uso |
| --- | --- |
| `test/fixtures/siged-hierarquia-sample.json` | Árvore 3 níveis |
| `test/fixtures/siged-home-degraded.json` | live false |
| `test/fixtures/siged-fiscalizacao-run-completed.json` | panel |
| `test/fixtures/siged-insights-batch-completed.json` | insights |
