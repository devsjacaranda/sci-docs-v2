# STATUS — 020 Purchasing Insights

**Data**: 2026-06-25 (arquivada) · **Pós-entrega**: 2026-06-25  
**Estado**: Concluída — 68/68 tasks em `tasks.md`

## Entregue

### API (`ci-api-v2`)
- Módulo `compras-insights/` — Prisma `CompraInsightBatch/Insight/Evidence`, enum `pricing`
- Regras operacionais, pricing e **insights por demanda individual** (`demand_single_*`) — sem mock PNCP
- Use-cases: generate, list latest, batches, trace, export HTML
- Controller `@Controller('compras/insights')` + `@RequireModulo('compras')` + `@RequireLicenca('cedro')`
- Job agendado diário, throttle desabilitado em dev, read-only (não altera `CompraDemanda`)
- Filtro `isDeprecatedMockInsight` oculta slugs legados `external_*` / PNCP simulado
- **102 testes** Jest (17 suites)

### Client (`ci-client-v2`)
- `ComprasInsightsPage` — stats, cards, histórico, *Consultar IA*, *Exportar relatório*
- `modules/compras/api/insights.ts` + `insights-mappers.ts`
- MSW + fixtures **somente dados internos**
- Shared Cedro: `InsightTraceSheet` com evidências linkando `/compras/:demandaId`
- **Sem** badge *Dados simulados — MVP*

### Seed Jacaranda (`npm run prisma:seed`)
- **10 demandas DEAE** com objetos, artefatos e pesquisas de preços realistas
- PCA 2026 ativo + PCA 2025 encerrado
- Demanda demo principal: `e7adc630-3113-4a46-a7f9-0dc2a3a3c807` (notebooks)
- **17 insights Cedro** pré-gerados no batch `on_open` (operacional + precificação + single)
- Login: `admin@jacaranda.com` / `password123` · setor DEAE vinculado ao módulo Compras

### Correções colaterais
- `listDemandasQuerySchema`: `limit` max 500
- `purge-demo-tenant.ts`: purge completo gabinete/tramitação/compras-insights + timeout 120s
- Loader insights: janela 90d por `createdAt` **ou** `updatedAt`

## Validação

```powershell
cd ci-api-v2; npm run prisma:seed
cd ci-api-v2; npm test -- --testPathPatterns=compras-insights
cd ci-client-v2/apps/web; npm test -- --run ComprasInsightsPage
cd ci-api-v2; npm run start:dev
cd ci-client-v2; npm run dev
# /compras/insights — insights já listados após seed
# /compras/e7adc630-3113-4a46-a7f9-0dc2a3a3c807 — demanda notebooks
```

## Critérios spec (ajustados pós-MVP)

| SC | Status |
|----|--------|
| SC-001 Painel funcional ≤3 cliques | OK |
| SC-002 Consulta PNCP simulada | **Removido** — apenas dados internos reais |
| SC-003 Read-only / Somente leitura | OK |
| SC-004 Demanda inalterada pós-generate | OK |
| SC-005 Rastreio com evidências demanda | OK |
| SC-006 Empty states orientadores | OK |
| SC-007 Export HTML | OK |
| SC-008 Demo ponta a ponta | OK (seed + quickstart) |

## Dívidas / futuro

- Integração real PNCP/COMPRASNET (quando API disponível)
- Spec 019 fiscalização Compras · Spec 021 maturidade Compras
