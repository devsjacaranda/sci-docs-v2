# Arquivos impactados — gap 1 (desfecho)

## Backend (`ci-api-v2`)

| Arquivo | Papel gap 1 |
| --- | --- |
| `prisma/schema/manifestacao.prisma` | Enum `ManifestacaoDesfechoEncerramento` + coluna |
| `prisma/migrations/*` | Migration coluna nullable |
| `src/modules/ouvidoria/ouvidoria.schemas.ts` | `encerrarBodySchema`, `relatorioGestaoResponse` / Zod parse |
| `src/modules/ouvidoria/ouvidoria.types.ts` | Tipos KPI + `demandasPorDesfecho` |
| `src/modules/ouvidoria/use-cases/encerrar-manifestacao.use-case.ts` | Persistir desfecho |
| `src/modules/ouvidoria/repository/persist-encerramento.repository.ts` | Write `desfechoEncerramento` |
| `src/modules/ouvidoria/repository/dashboard.repositories.ts` | Queries agregação desfecho (substituir/paralelizar `demandasFinalizadas`) |
| `src/modules/ouvidoria/use-cases/get-dashboard-agregacoes.use-case.ts` | Expor raw desfecho |
| `src/modules/ouvidoria/use-cases/get-relatorio-gestao.use-case.ts` | Montar response relatório |
| `src/modules/ouvidoria/repository/get-relatorio-gestao-acumulado.repository.ts` | Acumulado por desfecho (se necessário) |
| `src/modules/ouvidoria/lib/relatorio-gestao-pdf-sections.ts` | Títulos/colunas PDF |
| `src/modules/ouvidoria/use-cases/export-relatorio-gestao-excel.use-case.ts` | Aba desfecho |
| `src/modules/ouvidoria/lib/*` (helper tenant AGEMAN default jurídico) | T108 |
| `src/modules/ouvidoria/test/use-cases/encerrar-manifestacao.use-case.spec.ts` | TDD encerramento |
| `src/modules/ouvidoria/test/use-cases/get-relatorio-gestao.use-case.spec.ts` | Contrato relatório |
| `src/modules/ouvidoria/test/use-cases/dashboard-agregacoes.use-case.spec.ts` | Agregações |
| `src/modules/ouvidoria/ouvidoria.schemas.spec.ts` | Zod encerrar |
| `scripts/` ou seed (opcional T110) | Backfill AGEMAN |

**Compartilhados com gaps 2–4** (coordenação obrigatória): ver [coordination-gaps-2-4.md](./coordination-gaps-2-4.md).

## Frontend (`ci-client-v2`)

| Arquivo | Papel gap 1 |
| --- | --- |
| `apps/web/src/modules/ouvidoria/api/workflow.ts` | Body encerrar + tipo desfecho |
| `apps/web/src/modules/ouvidoria/components/ManifestacaoActionDialogs.tsx` | UI três vias encerramento sem resolução |
| `apps/web/src/modules/ouvidoria/api/relatorio-gestao.ts` | Types response |
| `apps/web/src/modules/ouvidoria/lib/relatorio-gestao-mappers.ts` | Gráficos/KPI labels AGEMAN |
| `apps/web/src/modules/ouvidoria/pages/OuvidoriaRelatorioGestaoPage.tsx` | Cards + gráfico desfecho |
| `apps/web/src/modules/ouvidoria/__tests__/relatorio-gestao-mappers.test.ts` | |
| `apps/web/src/modules/ouvidoria/__tests__/OuvidoriaRelatorioGestaoPage.test.tsx` | |
| `apps/web/src/modules/ouvidoria/__tests__/ManifestacaoActionDialogs.test.tsx` | Encerrar jurídico |
| `apps/web/src/modules/ouvidoria/api/errors.ts` | Copy campo desfecho |

**Fora escopo gap 1 (dashboard operacional)** — alteração opcional fase 2:

- `apps/web/src/modules/ouvidoria/components/dashboard/OuvidoriaDashboardCharts.tsx`
- `apps/web/src/modules/ouvidoria/lib/dashboard-mappers.ts`
- `apps/web/src/modules/ouvidoria/pages/ManifestacoesListPage.tsx` (KPI cards)

## Docs

| Arquivo | |
| --- | --- |
| `civ2-docs/specs/050-relatorio-gestao-desfecho-ageman/*` | Esta spec |
| `civ2-docs/specs/README.md` | Entrada 050 (T119) |
