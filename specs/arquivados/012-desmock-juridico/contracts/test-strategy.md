# Contract: Test Strategy — Desmock Jurídico

**Feature**: 012-desmock-juridico  
**References**: [plan.md](../plan.md) · constitution II · contracts REST/UI

## Princípio: sem banco extra

Idêntico [008 test-strategy](../../008-ouvidoria-jatoba-fiscalizacao/contracts/test-strategy.md):

- API: Prisma mock / in-memory store
- Client: MSW 2.x mockando `/juridico/*`
- Fixtures JSON em `modules/juridico/fixtures/`

## Escopo (5 camadas)

| Camada | API | Client |
|--------|-----|--------|
| Unitário | ✅ checks, loss-probability, mappers | ✅ mappers, wizard state |
| Componente | — | ✅ wizard steps, panels, trace sheet |
| Contrato | ✅ Zod + fixtures | ✅ Zod response |
| Integração | ✅ use-cases mock Prisma | ✅ page + MSW |
| E2E | ✅ Supertest juridico.e2e-spec.ts | ✅ Vitest journey |

## Scripts

```powershell
cd ci-api-v2
npm test -- juridico
npm run test:e2e -- --testPathPattern=juridico

cd ci-client-v2/apps/web
npm run test -- juridico
npm run typecheck
```

## Matriz mínima — Base

| ID | Camada | Caso |
|----|--------|------|
| CT-JUR-001 | unit | confirm gera JUR-YYYY-NNNN único |
| CT-JUR-002 | unit | draft aceita zero partes |
| CT-JUR-003 | unit | status critical quando prazo vencido |
| CT-JUR-004 | unit | anexo rejeita > 30MB |
| CT-JUR-005 | e2e | POST draft → confirm → GET list 200 |
| CT-JUR-006 | e2e | 403 módulo negado (sem DEJUR) |
| CT-JUR-007 | component | Lista empty state sem mock rows |
| CT-JUR-008 | integration | Wizard 4 steps persiste draft |

## Matriz mínima — Jatobá + Probabilidade de Perda

| ID | Camada | Caso |
|----|--------|------|
| CT-JUR-FIS-001 | unit | loss-probability judicial vencido → alta |
| CT-JUR-FIS-002 | unit | loss-probability sem tipo e prazo → indeterminada |
| CT-JUR-FIS-003 | unit | judicial sem CNJ → partial identification check |
| CT-JUR-FIS-004 | unit | aggregate worst conformity |
| CT-JUR-FIS-005 | e2e | POST run persiste lossProbabilityBand |
| CT-JUR-FIS-006 | e2e | fiscalização não altera processo |

## Matriz mínima — Cedro / Carvalho

| ID | Camada | Caso |
|----|--------|------|
| CT-JUR-INS-001 | unit | aggregation risk distribution |
| CT-JUR-INS-002 | e2e | GET insights tenant-scoped |
| CT-JUR-MAT-001 | unit | hybrid score 0.6/0.4 |
| CT-JUR-MAT-002 | component | radar 3 eixos |

## TDD order (implementação)

1. Schema + unit `loss-probability.rules.ts`
2. Use-cases Base (draft, confirm, list, detail)
3. Controller e2e Base + Wasabi stub
4. `juridico-fiscalizacao` (checks + runs)
5. `juridico-insights` + `juridico-maturidade`
6. Client wizard + overrides + MSW
7. Dashboard + remover mocks shell
