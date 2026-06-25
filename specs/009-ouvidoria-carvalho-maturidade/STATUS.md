# Status: Maturidade Carvalho — Ouvidoria

| Campo | Valor |
|-------|-------|
| **Status** | Concluída (merge-ready) |
| **Concluída em** | 2026-06-19 |
| **Spec** | [spec.md](./spec.md) |
| **Plano** | [plan.md](./plan.md) |
| **Tasks** | [tasks.md](./tasks.md) — T001–T096 `[X]` |

## Entregas

- **API** (`ci-api-v2/src/modules/ouvidoria-maturidade/`): score híbrido R-50, autoavaliação, indicadores, planos de ação, dashboard, guards `@RequireLicenca('carvalho')`
- **Prisma**: migration `20260619211418_ouvidoria_maturidade` + seeds perguntas e demo (`seed-maturidade-questions.ts`, `seed-maturidade-demo.ts`)
- **Client** (`ci-client-v2/apps/web/src/modules/ouvidoria/`): página `/ouvidoria/maturidade` real — radar/timeline Nivo, rastreio, autoavaliação, planos de ação, alertas Carvalho via cache API

## Dívidas técnicas resolvidas

- Repositórios legados e migrations duplicadas removidos
- `license-alerts.ts` consome `score.overallAlert` da API (cache populado no dashboard)
- MSW estendido para self-assessment, action-plans e indicator trace

## Validação (quickstart §1)

```powershell
cd ci-api-v2
npm test -- ouvidoria-maturidade          # 39 testes
npm run test:e2e -- --testPathPatterns=ouvidoria-maturidade  # 7 testes
npm run build

cd ci-client-v2/apps/web
npm run test -- maturidade                # 19 testes
npm run test -- ActionPlansPanel SelfAssessmentDialog  # +2 testes componente
npm run typecheck
```

## Manual

`ouvidoria@demo.com` → `/ouvidoria/maturidade` (ver [quickstart.md](./quickstart.md) §2)

## Próximo passo Spec Kit

Nenhuma feature ativa. Para nova feature: `/speckit-specify`.
