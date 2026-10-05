# Data Model: Ajustes internos da Ouvidoria AGEMAN

Não há entidade nova nem migration. Mudam regras de leitura, uma exclusão física e estado de tela.

## Manifestação oficial

Registro em `Manifestacao` que entra na lista, no painel e no relatório.

| Regra | Valor |
|-------|--------|
| Fora do conjunto | `deletedAt` preenchido, `status = draft`, `protocol` contendo `ouv-demo` (sem diferenciar maiúsculas) |
| Janela da métrica e do atendimento por mês | `createdAt` em `yearBounds(year, month)` |
| Janela do acumulado | `reportCountWindows(year, month).acumulado` — igual à métrica quando só o ano está escolhido; de 1º de janeiro ao fim do mês quando ano e mês estão escolhidos |
| Mês do gráfico | `EXTRACT(MONTH FROM "createdAt" AT TIME ZONE 'UTC')`, para o mês coincidir com a janela UTC |

### Grupos de situação

| Grupo na tela | Status |
|---------------|--------|
| Pendente | `in_review`, `forwarding`, `closed_unresolved` |
| Resolvida pela AGEMAN | `answered`, `closed` |
| Meio jurídico | `closed_meio_juridico` |

`desfechoPendentes` continua calculável como a contagem de `closed_unresolved` para a planilha. Na métrica, no acumulado e na lista, essa contagem já está dentro de Pendente. Total = Pendente + Resolvida pela AGEMAN + Meio jurídico.

## Manifestação de demonstração

| Campo | Regra |
|-------|--------|
| Identidade | `Manifestacao.protocol` contém `ouv-demo` |
| Exemplo | `OUV-DEMO-2026-0014` |
| Destino | Exclusão física do registro e das dependências que não cascateiam |
| Preservadas | Linhas cujo protocolo não tem o marcador, mesmo que o texto fale de teste ou treinamento |

## Zona

Campo `Address.zone` / `address.zone` do rascunho. No formulário de nova manifestação é derivado de `getZonaByBairro(neighborhood)` quando o município é Manaus. Sem bairro reconhecido, fica vazio. O usuário não grava outro valor nesse formulário. Na ficha já salva, o campo segue editável.

## Página da lista

Não é coluna. É a query da rota mais uma cópia em `sessionStorage` da visita:

| Dado | Onde |
|------|------|
| Página, situação, demais filtros já existentes | Query de `/ouvidoria/manifestacoes` |
| Cópia da mesma query | `sessionStorage`, chave da lista de manifestações |
| Vida | A cópia acaba com a sessão do navegador. Visita nova abre na página 1 |

## Quem tem acesso

Não muda tabela de concessão. A visão do bloco depende da sessão: `isSuperAdmin` e nome normalizado igual a `romulo gabriel pinheiro pereira`.
