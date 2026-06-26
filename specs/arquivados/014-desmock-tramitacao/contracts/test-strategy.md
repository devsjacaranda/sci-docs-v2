# Contract: Test Strategy — Desmock Tramitação

**Feature**: 014-desmock-tramitacao  
**References**: [plan.md](../plan.md) · constitution II · contracts REST/UI

## Princípio: sem banco extra

Idêntico [012-gabinete test-strategy](../../012-desmock-gabinete/contracts/test-strategy.md):

- API: Prisma mock / in-memory store
- Client: MSW 2.x mockando `/tramitacao/*`
- Fixtures JSON compartilhadas

## Escopo (5 camadas)

| Camada | API | Client |
|--------|-----|--------|
| Unitário | ✅ checks, mappers, inbox filters | ✅ mappers, hooks |
| Componente | — | ✅ inbox, thread, linked panel |
| Contrato | ✅ Zod + fixtures | ✅ Zod response |
| Integração | ✅ use-cases mock Prisma | ✅ page + MSW |
| E2E | ✅ Supertest tramitacao.e2e-spec.ts | ✅ Vitest journey |

## Scripts

```powershell
cd ci-api-v2
npm test -- tramitacao
npm run test:e2e -- --testPathPattern=tramitacao

cd ci-client-v2/apps/web
npm run test -- tramitacao
npm run typecheck
npm run build
```

## Matriz mínima — Base

| ID | Camada | Caso |
|----|--------|------|
| CT-TRAM-001 | unit | CreateGeneric exige subject+body+targetSector |
| CT-TRAM-002 | unit | protocolNumber TRAM-YYYY-NNNN unique tenant |
| CT-TRAM-003 | unit | inbox received filter currentSectorId |
| CT-TRAM-004 | unit | sourceSnapshot imutável no update |
| CT-TRAM-005 | unit | forward atualiza currentSectorId + event |
| CT-TRAM-006 | unit | archive bloqueia reply/forward |
| CT-TRAM-007 | e2e | POST demanda → GET inbox received 200 |
| CT-TRAM-008 | e2e | OPEN_MODULES — setor sem vínculo tramitacao OK |
| CT-TRAM-009 | integration | gabinete forward cria demanda tramitacao |
| CT-TRAM-010 | component | Inbox pastas Recebidas/Enviadas/Arquivadas |

## Matriz mínima — Jatobá

| ID | Camada | Caso |
|----|--------|------|
| CT-TRAM-FIS-001 | unit | sla_deadline vencido → non_conforme |
| CT-TRAM-FIS-002 | unit | forwarding_pending sem reply X dias |
| CT-TRAM-FIS-003 | unit | aggregate worst conformity |
| CT-TRAM-FIS-004 | e2e | POST run persiste results read-only |

## Matriz mínima — Cedro / Carvalho

| ID | Camada | Caso |
|----|--------|------|
| CT-TRAM-INS-001 | unit | bottleneck_sectors determinístico |
| CT-TRAM-INS-002 | unit | volume_by_module inclui generic |
| CT-TRAM-MAT-001 | unit | hybrid score 60/40 |
| CT-TRAM-MAT-002 | e2e | POST plano-acao vinculado eixo |

## TDD order (implementação)

1. Schema + unit repositories (mock)
2. Use-cases Base RED→GREEN
3. Controller e2e Base
4. Integrações cross-módulo (gabinete → tramitacao)
5. Submódulos licença (fiscalizacao → insights → maturidade)
6. Client pages + MSW
7. Remoção mock shell + regression build
