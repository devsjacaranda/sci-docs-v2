# Contract: Test Strategy — Desmock Gabinete

**Feature**: 012-desmock-gabinete  
**References**: [plan.md](../plan.md) · constitution II · contracts REST/UI

## Princípio: sem banco extra

Idêntico [008 test-strategy](../../008-ouvidoria-jatoba-fiscalizacao/contracts/test-strategy.md):

- API: Prisma mock / in-memory store
- Client: MSW 2.x mockando `/gabinete/*`
- Fixtures JSON compartilhadas

## Escopo (5 camadas)

| Camada | API | Client |
|--------|-----|--------|
| Unitário | ✅ checks, mappers, transitions | ✅ mappers, hooks |
| Componente | — | ✅ forms, tabs, panels |
| Contrato | ✅ Zod + fixtures | ✅ Zod response |
| Integração | ✅ use-cases mock Prisma | ✅ page + MSW |
| E2E | ✅ Supertest gabinete.e2e-spec.ts | ✅ Vitest journey |

## Scripts

```powershell
cd ci-api-v2
npm test -- gabinete
npm run test:e2e -- --testPathPattern=gabinete

cd ci-client-v2/apps/web
npm run test -- gabinete
npm run typecheck
```

## Matriz mínima — Base

| ID | Camada | Caso |
|----|--------|------|
| CT-GAB-001 | unit | CreateDemanda exige subject+description |
| CT-GAB-002 | unit | protocolNumber unique per tenant |
| CT-GAB-003 | unit | Forward stub append forwardings + event |
| CT-GAB-004 | unit | DocumentoTramitado requires setorId |
| CT-GAB-005 | e2e | POST demanda → GET list 200 |
| CT-GAB-006 | e2e | 403 módulo negado |
| CT-GAB-007 | component | Lista empty state sem mock rows |
| CT-GAB-008 | integration | Detail tabs load controles |

## Matriz mínima — Jatobá

| ID | Camada | Caso |
|----|--------|------|
| CT-GAB-FIS-001 | unit | deadline.rules vencido → non_conforme |
| CT-GAB-FIS-002 | unit | aggregate worst conformity |
| CT-GAB-FIS-003 | e2e | POST run persiste results read-only |

## Matriz mínima — Carvalho / Cedro

| ID | Camada | Caso |
|----|--------|------|
| CT-GAB-MAT-001 | unit | hybrid score formula R-50 |
| CT-GAB-INS-001 | unit | aggregation volume_by_status |
| CT-GAB-INS-002 | e2e | GET latest insights tenant-scoped |

## TDD order (implementação)

1. Schema + unit repositories (mock)
2. Use-cases Base RED→GREEN
3. Controller e2e Base
4. Submódulos licença (fiscalizacao → insights → maturidade)
5. Client pages + MSW
