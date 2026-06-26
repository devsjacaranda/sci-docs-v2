# Contract: Test Strategy — Insights Cedro Compras

**Feature**: 020-purchasing-insights  
**References**: [plan.md](../plan.md) · constitution II · [rest-api-compras-insights.md](./rest-api-compras-insights.md) · [client-compras-insights-ui.md](./client-compras-insights-ui.md)

## Princípio: sem banco extra

Idêntico a 007/015 — mocks Prisma, fixtures JSON, MSW; **sem** `ci_api_v2_test` Postgres.

---

## Escopo

| Camada | API | Client |
|--------|-----|--------|
| Unitário | ✅ regras + simulador PNCP + throttle + mappers | ✅ mappers |
| Componente | — | ✅ shared cedro + ComprasInsightsPage |
| Contrato | ✅ fixtures ↔ Zod schemas | ✅ MSW ↔ types |
| Integração | ✅ use-cases mock Prisma | ✅ api + MSW |
| E2E | ✅ Supertest | ✅ Vitest journey |

---

## Casos de teste mínimos (API unit)

| ID | Regra / módulo | Assert |
|----|----------------|--------|
| CT-COM-INS-001 | `demand_volume_by_status` | insight operational, evidências ≤ 5 |
| CT-COM-INS-002 | `demand_concentration_by_pca` | null se &lt; 5 demandas |
| CT-COM-INS-003 | `demand_artefact_backlog` | count artefatos pendentes |
| CT-COM-INS-004 | `demand_value_above_median` | category pricing |
| CT-COM-INS-005 | `demand_missing_price_survey` | não inventa valor |
| CT-COM-INS-006 | `pncp-simulator` objeto ≥ 10 chars | median + suppliers determinísticos |
| CT-COM-INS-007 | `pncp-simulator` objeto &lt; 10 chars | confidence low, sem contratos fabricados |
| CT-COM-INS-008 | `external_value_divergence` | híbrido interno + simulado |
| CT-COM-INS-009 | trace payload | `module: 'compras'`, externalQueries quando slug externo |
| CT-COM-INS-010 | throttle | 429 2º on_demand &lt; 1h |
| CT-COM-INS-011 | read-only | generate não altera CompraDemanda |
| CT-COM-INS-012 | emptyReason | no_data tenant sem demandas |
| CT-COM-INS-013 | export | HTML contém disclaimer simulado |

---

## Casos de teste mínimos (Client)

| ID | Cenário |
|----|---------|
| CT-COM-UI-001 | Render cards com impacto + fonte Compras/PNCP simulado |
| CT-COM-UI-002 | Consultar IA → loading → lista atualizada |
| CT-COM-UI-003 | 429 → toast throttle, lista preservada |
| CT-COM-UI-004 | Sheet rastreio ~85%, link demanda + seção PNCP simulado |
| CT-COM-UI-005 | Histórico 3 lotes → compara 2 anteriores |
| CT-COM-UI-006 | emptyReason no_data + CTA orientador |
| CT-COM-UI-007 | 403 AccessDenied403 |
| CT-COM-UI-008 | Exportar relatório → download HTML |

---

## Scripts

```powershell
cd ci-api-v2
npm test -- --testPathPatterns=compras-insights

cd ci-client-v2
npm run test --workspace=@ci/web -- --run ComprasInsights
npm run test --workspace=@ci/web -- --run InsightsPanel
npm run typecheck --workspace=@ci/web
```

---

## Regressão shared Cedro

Após extender `InsightTraceSheet`:

```powershell
cd ci-client-v2
npm run test --workspace=@ci/web -- --run GabineteInsights
npm run test --workspace=@ci/web -- --run OuvidoriaInsights
npm run test --workspace=@ci/web -- --run InsightsPanel
```

---

## Guard de licença (API)

Contract spec Supertest:

- `GET /compras/insights` sem Cedro → 403
- `GET /compras/insights` sem módulo compras → 403
- `GET /compras/demandas` (CRUD base) → 200 sem Cedro (regressão 018)
