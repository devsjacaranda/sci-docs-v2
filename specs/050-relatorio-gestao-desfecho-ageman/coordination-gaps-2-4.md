# Coordenação — gaps 2–4 vs gap 1 (desfecho)

Orquestração multi-agente: **gap 1** é owner de desfecho + substituição `demandasFinalizadas` → `demandasPorDesfecho` + encerramento.

## Mapa inferido de gaps (alinhamento planilha)

| Gap | Foco planilha | Owner provável |
| --- | --- | --- |
| **1** | RESUMO GERAL — três linhas desfecho + série mensal global | Spec 050 (este) |
| **2** | RESUMO GERAL — bloco "DEMANDAS E RESOLUTIVIDADE" / `%` resolutividade; possível refactor `resolutividade[]` | Agente relatório KPI |
| **3** | ACOMPANHAMENTO_MENSAL — matriz mês × concessão × (RESOLVIDA\|JURÍDICO\|PENDENTE) | Agente agregação concessionária |
| **4** | Demais divergências RESUMO (rótulos tipo concessão, KPI "Resolvidas" vs atendimentos, forma vs canal) | Agente UI/copy + SQL `porMotivo` |

## Arquivo quente: `get-relatorio-gestao.use-case.ts`

**Todos os gaps** montam o payload final aqui. Regras de merge:

1. **Gap 1** adiciona `demandasPorDesfecho`, estende `kpis`, remove `demandasFinalizadas` do return.
2. **Gap 2** altera `resolutividade[]` e/ou adiciona `demandasEResolutividade` — **não** remover campos gap 1; composição na mesma `execute()`.
3. **Gap 3** adiciona bloco novo `acompanhamentoMensalPorConcessao[]` — arquivo separado de repository; use-case só concatena.
4. **Gap 4** pode alterar `porMotivo`, `porFormaAtendimento`, labels PDF — **não** tocar queries desfecho sem sync.

**Ordem de implementação recomendada**: gap 1 (schema + encerramento) → gap 3 (reusa enum) → gap 2 (percentuais) → gap 4 (cosmético/SQL).

## Outros arquivos compartilhados (conflito Git provável)

| Arquivo | Gap 1 | Gap 2 | Gap 3 | Gap 4 |
| --- | --- | --- | --- | --- |
| `get-relatorio-gestao.use-case.ts` | ● | ● | ● | ○ |
| `ouvidoria.types.ts` | ● | ● | ● | ○ |
| `ouvidoria.schemas.ts` | ● | ○ | ● | ○ |
| `dashboard.repositories.ts` | ● | ● | ● | ● |
| `relatorio-gestao-pdf-sections.ts` | ● | ● | ○ | ● |
| `export-relatorio-gestao-excel.use-case.ts` | ● | ○ | ● | ○ |
| `OuvidoriaRelatorioGestaoPage.tsx` | ● | ● | ● | ● |
| `relatorio-gestao-mappers.ts` | ● | ● | ● | ● |
| `get-relatorio-gestao.use-case.spec.ts` | ● | ● | ● | ○ |

Legenda: ● = edição esperada.

## Contratos

- Gap 1 publica [contracts/desfecho-relatorio-gestao.md](./contracts/desfecho-relatorio-gestao.md).
- Gaps 2–4 MUST append seções no mesmo arquivo ou `contracts/acompanhamento-mensal.md` — **não** reintroduzir `demandasFinalizadas`.

## Flag de integração

Branch sugerida: `050-desfecho-ageman` baseada em `main` pós-049; gaps 2–4 em branches `050-resolutividade`, `050-acompanhamento-mensal`, `050-resumo-labels` com rebase sequencial ou PR empilhado.
