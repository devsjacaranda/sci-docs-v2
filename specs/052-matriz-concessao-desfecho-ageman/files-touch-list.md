# Arquivos impactados — 052 (Matriz Concessão × Desfecho + ajustes status/encerramento)

## Backend (`ci-api-v2`)

| Arquivo | Papel |
| --- | --- |
| `src/modules/ouvidoria/ouvidoria.schemas.ts` | Restringir `manifestacaoDesfechoEncerramentoSchema` (FR-003); adicionar `concessao` a `listManifestacoesQuerySchema` (FR-007) |
| `src/modules/ouvidoria/lib/manifestacao-desfecho.ts` | Remover `'pendente'` de `MANIFESTACAO_DESFECHO_ENCERRAMENTO`; ajustar `statusFromDesfechoEncerramento` |
| `src/modules/ouvidoria/repository/get-relatorio-gestao-concessao-desfecho.repository.ts` | **Novo** — matriz concessão × desfecho (FR-001/001a/002/004) |
| `src/modules/ouvidoria/repository/manifestacao.repositories.ts` (`ListManifestacoesRepository`) | Filtro `concessao` (FR-007) |
| `src/modules/ouvidoria/use-cases/get-relatorio-gestao.use-case.ts` | Incluir `concessaoPorDesfecho` no payload |
| `src/modules/ouvidoria/use-cases/list-manifestacoes.use-case.ts` | Repassar filtro `concessao` |
| `src/modules/ouvidoria/ouvidoria.mapper.ts` | `MANIFESTACAO_STATUS_LABEL.in_review`, `PUBLIC_MANIFESTACAO_STATUS_LABEL.in_review` → "Pendente" (FR-005/006) |
| `src/modules/ouvidoria/lib/relatorio-gestao-pdf-sections.ts` | Seção "Concessão × Desfecho"; rótulo "Em análise" → "Pendente" nos KPIs |
| `src/modules/ouvidoria/use-cases/export-relatorio-gestao-excel.use-case.ts` | Aba "Concessão × Desfecho"; rótulo KPI |
| `src/modules/ouvidoria/lib/map-programa-concessao.ts` | Reaproveitado sem mudança (referência) |
| `src/modules/ouvidoria/lib/ageman-catalog.ts` | Reaproveitado sem mudança (fonte de `AGEMAN_PROGRAMA_LABEL`) |
| **Testes** | `test/use-cases/encerrar-manifestacao.use-case.spec.ts`, `test/lib/manifestacao-desfecho.spec.ts`, `ouvidoria.schemas.spec.ts`, `test/repository/get-relatorio-gestao-concessao-desfecho.repository.spec.ts` (novo), `test/use-cases/get-relatorio-gestao.use-case.spec.ts`, `test/use-cases/list-manifestacoes.use-case.spec.ts`/`.repository.spec.ts`, `ouvidoria.mapper.spec.ts`, `test/use-cases/consulta-publica.use-case.spec.ts`, `test/use-cases/export-relatorio-gestao-excel.use-case.spec.ts`, `lib/render-relatorio-gestao-pdf.spec.ts` |

## Frontend (`ci-client-v2`)

| Arquivo | Papel |
| --- | --- |
| `apps/web/src/modules/ouvidoria/lib/manifestacao-desfecho-copy.ts` | 2 opções de desfecho (FR-003) |
| `apps/web/src/modules/ouvidoria/pages/ManifestacoesListPage.tsx` | `STATUS_OPTIONS.in_review` → "Pendente"; KPI card; novo filtro de concessão (FR-005/007) |
| `apps/web/src/modules/ouvidoria/lib/manifestacoes-list-stats.ts` | Rótulo KPI "Em análise" → "Pendente" |
| `apps/web/src/modules/ouvidoria/api/manifestacoes.ts` | Param `concessao` na chamada de listagem |
| `apps/web/src/modules/ouvidoria/api/relatorio-gestao.ts` | Tipo `concessaoPorDesfecho` na response |
| `apps/web/src/modules/ouvidoria/lib/relatorio-gestao-mappers.ts` | `mapConcessaoPorDesfechoChart` (novo); rename linha "Em análise" em `mapDemandasPendentesChart` |
| `apps/web/src/modules/ouvidoria/pages/OuvidoriaRelatorioGestaoPage.tsx` | Novo bloco/tabela "Concessão × Desfecho"; card "Demandas pendentes" com rótulo atualizado |
| `apps/web/src/modules/ouvidoria/lib/manifestacao-detail-view.ts` (e afins) | Se exibir `statusLabel` derivado de `in_review`, herda o rename automaticamente (mapper único) |
| **Testes** | `__tests__/ManifestacaoActionDialogs.test.tsx`, `lib/__tests__/manifestacao-desfecho-copy.test.ts`, `__tests__/relatorio-gestao-mappers.test.ts`, `__tests__/OuvidoriaRelatorioGestaoPage.test.tsx`, `lib/__tests__/manifestacao-detail-view.test.ts`, `__tests__/ManifestacaoIdentityCard.test.tsx`, testes de `ManifestacoesListPage` (filtro + KPI) |

## Não tocar (fora de escopo, confirmar em code review)

- `civ2-docs/specs/050-relatorio-gestao-desfecho-ageman/*` e `050-relatorio-gestao-tipo-concessao-ageman/*` — specs desalinhadas com o código real (ver `research.md` §1), correção é tarefa separada.
- `050-relatorio-gestao-serie-historica-ageman` (matriz mês×ano) e `050-relatorio-gestao-forma-atendimento-ageman` — blocos distintos, não tocados por esta feature.
- Módulo Diretor.

## Docs

| Arquivo | |
| --- | --- |
| `civ2-docs/specs/052-matriz-concessao-desfecho-ageman/*` | Esta spec |
| `civ2-docs/specs/README.md` | Entrada 052 (task de docs em `tasks.md`) |
