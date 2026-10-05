# Contract: Lista de manifestações

## Limpeza

Script operacional, sem rota de tela: apaga manifestações do tenant cujo protocolo contém `ouv-demo`. Depois da limpeza, buscar ou abrir `OUV-DEMO-2026-0014` não retorna o registro. Um protocolo real no mesmo período permanece.

## Listagem

`GET` da lista aceita `situacao` opcional:

| `situacao` | Status incluídos |
|------------|------------------|
| ausente (Todos os status) | todos, exceto `draft` e exceto protocolo `ouv-demo` |
| `pendente` | `in_review`, `forwarding`, `closed_unresolved` |
| `resolvida_ageman` | `answered`, `closed` |
| `meio_juridico` | `closed_meio_juridico` |

Valor de `situacao` fora dessa lista é rejeitado. A tela não envia mais o `status` unitário (rascunho, tramitando, respondida, encerrada, pendente de desfecho).

## Faixa de totais da página

Mostra Total, Pendente, Resolvida pela AGEMAN e Meio jurídico, com os mesmos grupos. Não mostra “Pendente (desfecho)”.

## Página da visita

| Ação | Resultado |
|------|-----------|
| Abrir a lista pela primeira vez na visita | página 1 |
| Ir à página 4, abrir uma manifestação, voltar | página 4 e os mesmos filtros |
| Sair da lista e abrir Manifestações de novo na mesma visita | página 4 e os mesmos filtros |
| Mudar um filtro | página 1 |
| Nova sessão do navegador | página 1 |

A query da rota carrega a página e os filtros. O link de volta do detalhe usa essa query.
