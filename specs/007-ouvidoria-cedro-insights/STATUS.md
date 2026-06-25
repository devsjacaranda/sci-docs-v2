# Status: Insights Cedro — Ouvidoria

| Campo | Valor |
|-------|-------|
| **Status** | Arquivada (implementada) |
| **Concluída em** | 2026-06-19 |
| **Spec** | [spec.md](./spec.md) |
| **Plano** | [plan.md](./plan.md) |
| **Tasks** | [tasks.md](./tasks.md) — T001–T077 `[X]` |

## Entregas

- **API** (`ci-api-v2/src/modules/ouvidoria-insights/`): agregadores, use-cases, Prisma, job agendado, REST `/ouvidoria/insights`
- **Client** (`ci-client-v2/apps/web/src/modules/ouvidoria/`): página `/ouvidoria/insights`, componentes Cedro, MSW
- **Seed demo**: `prisma/seed/seed-manifestacoes-insights.ts` — 18 manifestações + lote inicial de insights (tenant `demo`)

## Validação

- API: `npm test`, `npm run test:e2e -- --testPathPatterns=ouvidoria-insights`
- Client: `npm run test -- Insight`, `npm run typecheck`
- Manual: `ouvidoria@demo.com` → `/ouvidoria/insights` (ver [quickstart.md](./quickstart.md))

## Próximo passo Spec Kit

Nenhuma feature ativa. Para nova feature: `/speckit-specify`.
