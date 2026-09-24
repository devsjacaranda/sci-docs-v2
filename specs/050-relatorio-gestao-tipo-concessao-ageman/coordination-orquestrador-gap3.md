# Coordenação — ORQUESTRADOR gap 3 (tipo de concessão)

**Owner**: [050-relatorio-gestao-tipo-concessao-ageman](./spec.md)

## Escopo deste gap (canônico para o orquestrador)

Corrigir o bloco existente **`porTipoManifestacao`**: de `GROUP BY Manifestacao.type` para **mês × tipo de concessão** (mapa `programa` = `porMotivo` em `dashboard.repositories.ts`). UI/exports: **"Tipo de concessão"**.

Referência planilha: aba **RESUMO GERAL DEMAND.** (seção TIPO DE CONCESSÃO) + aba **7 — DEMANDAS_EMITIDAS CONC.**

> **Nota**: O arquivo [coordination-gaps-2-4.md](../050-relatorio-gestao-desfecho-ageman/coordination-gaps-2-4.md) do gap 1 usa numeração diferente para "gap 3" (matriz ACOMPANHAMENTO_MENSAL). Tratar **este diretório** como fonte para o gap 3 do orquestrador (*tipo manifestação → concessão*). Matriz desfecho×concessão, se existir, é outra spec/entrega.

## Overlap gap 4 (rótulos)

Parte do gap 4 (rótulos tipo concessão no RESUMO) **absorvida** aqui para o bloco `porTipoManifestacao`. `porMotivo` permanece detalhe por motivo; não duplicar card na UI.

## Arquivos quentes (merge)

| Arquivo | Edição |
|---------|--------|
| `get-relatorio-gestao-tipo-manifestacao.repository.ts` | ● query |
| `dashboard.repositories.ts` | ● DRY CASE programa |
| `get-relatorio-gestao.use-case.ts` | ● map rows + `type` espelho |
| `ouvidoria.types.ts` / `ouvidoria.schemas.ts` | ● `tipoConcessao` |
| `relatorio-gestao-pdf-sections.ts` | ● título |
| `export-relatorio-gestao-excel.use-case.ts` | ● aba |
| `relatorio-gestao-mappers.ts` / `TipoManifestacaoChartCard.tsx` | ● copy |

**Ordem sugerida vs gap 1 desfecho**: pode implementar em paralelo se gap 1 não alterar o mesmo repository de tipo-manifestacao; **rebase** antes de merge se ambos tocarem `get-relatorio-gestao.use-case.ts`.

## Contrato

[contracts/relatorio-gestao-tipo-concessao.md](./contracts/relatorio-gestao-tipo-concessao.md)
