# Contract: Test Strategy — Insights Cedro Gabinete

**Feature**: 015-gabinete-cedro-insights-integrado  
**References**: [plan.md](../plan.md) · constitution II · [rest-api-gabinete-insights.md](./rest-api-gabinete-insights.md) · [client-gabinete-insights-ui.md](./client-gabinete-insights-ui.md)

## Princípio: sem banco extra

Idêntico a 007 — mocks Prisma, fixtures JSON, MSW; **sem** `ci_api_v2_test` Postgres.

---

## Escopo

| Camada | API | Client |
|--------|-----|--------|
| Unitário | ✅ regras + throttle + mappers | ✅ mappers |
| Componente | — | ✅ shared cedro + page |
| Contrato | ✅ fixtures ↔ Zod schemas | ✅ MSW ↔ types |
| Integração | ✅ use-cases mock Prisma | ✅ api + MSW |
| E2E | ✅ Supertest | ✅ Vitest journey |

---

## Casos de teste mínimos (API unit)

| ID | Regra | Assert |
|----|-------|--------|
| CT-GAB-INS-001 | `volume_by_status` | insight operational, evidências ≤ 5 |
| CT-GAB-INS-002 | `origin_mix` | null se &lt; 5 atos |
| CT-GAB-INS-003 | `forwarding_bottleneck` | setor destino dominante |
| CT-GAB-INS-004 | `protocol_orphan` | count protocolos sem ato |
| CT-GAB-INS-005 | `control_numeric_by_type` | tipo dominante |
| CT-GAB-INS-006 | `notifications_trend` | category enforcement |
| CT-GAB-INS-007 | `tramitados_by_sector` | category tramitacao |
| CT-GAB-INS-008 | `groupId` dedup | notificação+auto = 1 caso |
| CT-GAB-INS-009 | trace payload | `module: 'gabinete'`, sem PII |
| CT-GAB-INS-010 | throttle | 429 2º on_demand &lt; 1h |
| CT-GAB-INS-011 | generate standalone | insights sem atos se protocolos ≥ 5 |
| CT-GAB-INS-012 | emptyReason | never_generated / insufficient_volume |

---

## Casos de teste mínimos (Client)

| ID | Cenário |
|----|---------|
| CT-GAB-UI-001 | Render cards com impacto + fonte Gabinete |
| CT-GAB-UI-002 | Consultar IA → loading → lista atualizada |
| CT-GAB-UI-003 | 429 → toast throttle, lista preservada |
| CT-GAB-UI-004 | Sheet rastreio abre ~85%, link ato |
| CT-GAB-UI-005 | Histórico 3 lotes → compara 2 anteriores |
| CT-GAB-UI-006 | emptyReason never_generated + CTA |
| CT-GAB-UI-007 | 403 AccessDenied403 |

---

## Scripts

```powershell
cd ci-api-v2
npm test -- --testPathPatterns=gabinete-insights

cd ci-client-v2
npm run test --workspace=@ci/web -- --run GabineteInsights
npm run test --workspace=@ci/web -- --run InsightsPanel
npm run typecheck --workspace=@ci/web
```

---

## Regressão Ouvidoria

Após extrair shared Cedro:

```powershell
cd ci-client-v2
npm run test --workspace=@ci/web -- --run OuvidoriaInsights
npm run test --workspace=@ci/web -- --run InsightsPanel
```

Ouvidoria insights **deve** permanecer verde.

---

## Fixtures

| Path | Uso |
|------|-----|
| `ci-api-v2/.../fixtures/gabinete-analysis-sample.json` | unit aggregation |
| `ci-api-v2/.../fixtures/insight-batch-completed.json` | contract + e2e |
| `ci-client-v2/.../gabinete/fixtures/insights-*.json` | MSW |
