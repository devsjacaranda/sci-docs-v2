# Status: Insights Cedro — Gabinete (integração completa)

| Campo | Valor |
|-------|-------|
| **Status** | Concluída (merge-ready) |
| **Concluída em** | 2026-06-24 |
| **Spec** | [spec.md](./spec.md) |
| **Plano** | [plan.md](./plan.md) |
| **Tasks** | [tasks.md](./tasks.md) — T001–T064 |

## Entregas

### API (`ci-api-v2/src/modules/gabinete-insights/`)

- Loader unificado `LoadGabineteAnalysisDataRepository` — atos, protocolos, controles numéricos, notificações, autos, documentos tramitados
- 13 regras determinísticas em `lib/aggregation/` (operational, protocol, control-numeric, notifications, tramitados)
- Migration `20260624150000_gabinete_insight_categories` — enum `InsightCategory` estendido
- Mapper trace corrigido (`module: 'gabinete'`, omissão PII)
- Use-cases generate/list/trace + job agendado + contrato REST
- **60 testes** `npm test -- --testPathPatterns=gabinete-insights`

### Client (`ci-client-v2/apps/web/src/modules/`)

- Componentes Cedro shared em `shared/components/cedro/` (InsightCard, InsightsPanel, InsightsHistoryPanel, InsightTraceSheet)
- Ouvidoria refatorada para wrappers shared (regressão verde)
- `gabinete/pages/GabineteInsightsPage.tsx` — paridade Ouvidoria (stats, histórico, Consultar IA, sheet rastreio, emptyReason, stale banner)
- API client + mappers + fixtures + MSW `gabinete-insights.ts`
- Testes: `GabineteInsightsPage`, `insights-mappers`, `insights.contract`

## Validação

```powershell
cd ci-api-v2
npm test -- --testPathPatterns=gabinete-insights

cd ci-client-v2
npm run test --workspace=@ci/web -- --run GabineteInsights
npm run test --workspace=@ci/web -- --run OuvidoriaInsights
npm run typecheck --workspace=@ci/web
```

## Manual (quickstart)

`paulo@demo.com` → Gabinete → Insights IA → Consultar IA (ver [quickstart.md](./quickstart.md) VS-001…VS-004)

## Dívidas

- Validação manual VS-001…VS-004 não executada nesta sessão
- Seed demo pode ser enriquecido para garantir ≥3 categorias pós-generate em tenant Jacaranda
- Migration requer `npx prisma migrate deploy` em ambiente com DB

## Próximo passo Spec Kit

Plano ativo: [014 Desmock Tramitação](../014-desmock-tramitacao/plan.md). Nova feature: `/speckit-specify`.
