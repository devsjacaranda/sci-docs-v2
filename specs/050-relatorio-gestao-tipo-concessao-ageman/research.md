# Research: Tipo de concessão no relatório de gestão (gap 3)

**Date**: 2026-09-24 · **Spec**: [spec.md](./spec.md)

## Evidência AGEMAN (planilha vs sistema hoje)

| Fonte | Conteúdo esperado |
|-------|-------------------|
| DOCX / `ajustes-extraido-2.txt` § "Tipo de manifestação" | Nota de rodapé: *"Abastecimento/saneamento; transporte coletivo…"* — mas linhas exportadas hoje: `complaint`, `request`, … |
| Planilha aba **RESUMO GERAL DEMAND.** | Seção **TIPO DE CONCESSÃO**: ABASTECIMENTO/COLETA DE ESGOTO, ILUMINAÇÃO, TRANSPORTE, ZONA AZUL, COLETA DE LIXO |
| Planilha **SHEET 7: DEMANDAS_EMITIDAS CONC.** | Matriz mês × concessão (quantidades por ano) — validação de totais por mês/concessão |
| Bloco `porMotivo` (já correto) | Coluna "Tipo concessionária": Água / Saneamento, etc. |

**Conclusão**: O nome "Tipo de manifestação" no relatório CI v2 foi implementado conforme Clarification Q4 da 042 (`Manifestacao.type`). O artefato AGEMAN usa **concessão/programa**, não taxonomia processual.

## Mapa programa → concessão (canônico)

Fonte de verdade hoje (duplicada 3× no código):

```216:228:ci-api-v2/src/modules/ouvidoria/repository/dashboard.repositories.ts
              COALESCE(
                CASE TRIM(programa)
                  WHEN '1' THEN 'Água / Saneamento'
                  WHEN 'agua' THEN 'Água / Saneamento'
                  WHEN '2' THEN 'Transporte Coletivo'
                  WHEN '3' THEN 'Iluminação Pública'
                  WHEN 'iluminacao' THEN 'Iluminação Pública'
                  WHEN '4' THEN 'Coleta de Lixo'
                  WHEN '5' THEN 'Zona Azul'
                  ELSE NULL
                END,
                NULLIF(TRIM("serviceMode"), '')
              ) AS "tipoConcessionaria",
```

Labels alinhados a `AGEMAN_PROGRAMA_LABEL` em `lib/ageman-catalog.ts` (Transporte Coletivo, Iluminação Pública, …).

### Equivalência planilha ↔ API (validação manual)

| Planilha RESUMO GERAL | API (após 050) |
|----------------------|----------------|
| ABASTECIMENTO/COLETA DE ESGOTO | Água / Saneamento |
| ILUMINAÇÃO | Iluminação Pública |
| TRANSPORTE | Transporte Coletivo |
| COLETA DE LIXO | Coleta de Lixo |
| ESTACIONAMENTO ROTATIVO / ZONA AZUL | Zona Azul |

## Decisão: compatibilidade API

| Elemento | Decisão | Motivo |
|----------|---------|--------|
| Chave JSON `porTipoManifestacao` | **Manter** | Enum Zod de resposta, PDF `bloco=`, testes e fixtures já amarrados |
| Campo `type` na linha | **Manter**, valor = concessão | Parsers que só leem `type` não quebram estruturalmente; semântica muda (breaking de conteúdo documentado) |
| Campo `tipoConcessao` | **Adicionar** | Nome canônico para client novo |
| Query `bloco=porTipoManifestacao` | **Manter** | Bookmarks / automação |
| Repository class `GetRelatorioGestaoTipoManifestacaoRepository` | **Renomear opcional** em refactor posterior; não bloqueante | Evitar diff grande na 050 se não necessário |

## Decisão: UI

- Título card/PDF/Excel: **"Tipo de concessão"**
- Descrição: referir formulário/programa AGEMAN, remover menção a `Manifestacao.type`
- Mapper client: **remover** `labelTipoManifestacao` / `TYPE_OPTIONS` neste bloco; usar string da API diretamente (com trim e "Não informado")

## Decisão: agregação SQL

Substituir query atual (`GROUP BY m.type`) em `get-relatorio-gestao-tipo-manifestacao.repository.ts` por:

- `GROUP BY month, tipoConcessao` onde `tipoConcessao = COALESCE(CASE programa…, serviceMode, 'Não informado')` — último COALESCE apenas para **exibição**; preferir alinhar exatamente ao `porMotivo` (null permitido no SQL) e normalizar null → "Não informado" no use-case, igual zona/bairro.

**Paridade**: `SUM(total) GROUP BY tipoConcessao` no bloco = `SUM(total) GROUP BY tipoConcessionaria` em `porMotivo` (mesmo filtro de datas).

## Decisão: DRY (FR-006)

Extrair fragmento SQL reutilizável, ex.: `programaToTipoConcessaoSql(column: 'programa')` retornando `Prisma.sql` para embed em `$queryRaw`, usado por:

1. `dashboard.repositories.ts` (`porMotivo`)
2. `get-relatorio-gestao-tipo-manifestacao.repository.ts`

Refatorar `get-relatorio-gestao-orientacoes-encaminhamentos.repository.ts` para o mesmo fragmento fica **recomendado** na mesma PR se o diff for mecânico; não é critério de aceite da US1.

## Código atual (anti-pattern)

```21:32:ci-api-v2/src/modules/ouvidoria/repository/get-relatorio-gestao-tipo-manifestacao.repository.ts
      SELECT
        EXTRACT(MONTH FROM m."createdAt")::int AS month,
        m.type AS type,
        COUNT(*)::int AS total
      ...
      GROUP BY 1, 2
```

## Referências cruzadas

- Spec base: [042-relatorio-gestao-ouvidoria](../042-relatorio-gestao-ouvidoria/spec.md)
- Ajustes paralelos: [049-ajustes-relatorio-gestao-ouvidoria](../049-ajustes-relatorio-gestao-ouvidoria/spec.md) (não colide — blocos distintos)
