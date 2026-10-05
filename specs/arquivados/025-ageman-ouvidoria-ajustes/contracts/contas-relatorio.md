# Contract: Contas do relatório de gestão

Leitura existente do relatório. Não há endpoint novo. A população e os grupos mudam.

## População

Toda agregação da métrica, do acumulado, do atendimento por mês e dos arquivos gerados a partir dessa resposta conta manifestação do tenant que:

- não está apagada;
- não está em `draft`;
- não tem `ouv-demo` no protocolo.

## Métrica de desempenho do período

Para o ano, ou para o ano e mês selecionados:

| Indicador | Conta |
|-----------|--------|
| Total | tamanho da população na janela da métrica |
| Pendentes | `in_review` + `forwarding` + `closed_unresolved` |
| Resolvidas pela AGEMAN | `answered` + `closed` |
| Meio jurídico | `closed_meio_juridico` |

Pendentes + Resolvidas pela AGEMAN + Meio jurídico = Total.

A tela da métrica mostra os quatro indicadores. O texto de Pendentes não cita rascunho.

## Acumulado geral

Mesmos quatro indicadores, na janela `reportCountWindows.acumulado`. Com só o ano selecionado, o total do acumulado é igual ao total da métrica. Com ano e mês, o acumulado vai de 1º de janeiro até o fim desse mês e pode ser maior que a métrica daquele mês. Os três grupos continuam somando o total daquela janela.

## Atendimentos por mês

Uma linha por mês civil (1–12) com total > 0, mês extraído em UTC. A soma dos totais das linhas é igual ao Total da métrica do mesmo recorte. Mês fora de 1–12 não existe.

## Invariante de teste

Dado um conjunto com um `closed_unresolved`, um protocolo `OUV-DEMO-2026-0014` e um `createdAt` na virada UTC do mês:

- o demo não entra em nenhum total;
- Pendentes inclui o `closed_unresolved`;
- a soma dos três grupos é o total;
- a soma dos meses é o total da métrica.
