# Quickstart: Validar o Relatório de Gestão da Ouvidoria

## Pré-requisitos

- `ci-api-v2` rodando localmente com migrations aplicadas (inclui a migration `ouvidoria_pesquisa_satisfacao` desta feature).
- Um tenant com módulo `ouvidoria` habilitado e ao menos algumas `Manifestacao` com `Address` (zona/bairro preenchidos em parte, vazios em outra parte — para validar o bloco "Não informado").
- Catálogo de perguntas de satisfação seedado para o tenant (ver `data-model.md` — `OuvidoriaPesquisaSatisfacaoPergunta`).
- Usuário autenticado com acesso ao módulo Ouvidoria (qualquer role — FR-011).

## Setup

```powershell
cd ci-api-v2
npm run prisma:migrate   # aplica a migration nova
npm run start:dev
```

```powershell
cd ci-client-v2
npm install
npm run dev   # turbo → @ci/web
```

## Cenário 1 — Ver o relatório consolidado (História 1)

1. Login como usuário com módulo Ouvidoria.
2. Acessar `/ouvidoria/relatorio-gestao`.
3. Filtrar por um ano/mês com dados conhecidos.
4. **Esperado**: blocos de demandas, formas de atendimento, resolutividade, zona, bairro, tipo de manifestação e satisfação aparecem preenchidos; registros sem zona/bairro aparecem agrupados em "Não informado", sem serem excluídos do total.
5. Trocar o filtro para "acumulado geral" (sem ano). **Esperado**: tela responde em até ~5s.

## Cenário 2 — Lançar pesquisa de satisfação (História 2)

1. Acessar `/ouvidoria/pesquisa-satisfacao`.
2. Lançar um valor para o mês corrente numa pergunta do catálogo.
3. Voltar ao relatório de gestão filtrando o mesmo mês. **Esperado**: o valor lançado aparece no bloco de satisfação imediatamente (sem cache).
4. Repetir o lançamento para o mesmo mês/pergunta com valor diferente. **Esperado**: o valor é atualizado (upsert), não duplicado.

## Cenário 3 — Exportar (História 3)

1. No relatório de gestão, clicar em "Exportar PDF". **Esperado**: download de um PDF com todos os blocos, em até ~30s mesmo no acumulado geral.
2. Clicar em "Exportar Excel". **Esperado**: download de um `.xlsx` com uma aba por bloco, valores já calculados (sem fórmulas).
3. Comparar um número de qualquer bloco entre tela, PDF e Excel — devem ser idênticos (SC-003).

## Cenário 4 — Quantitativo por tipo de manifestação (História 4)

1. No relatório, localizar o bloco "Tipo de Manifestação".
2. Comparar os totais com uma contagem manual de `Manifestacao` agrupada por `type` para o mesmo período (ex. via Prisma Studio ou query direta).
3. **Esperado**: números idênticos.

## Regressão a checar

- Tenant sem nenhuma manifestação no período: blocos vazios, sem erro (Edge Case).
- Usuário sem módulo Ouvidoria habilitado: acesso bloqueado com `403`.
- Reexportar após novo lançamento de satisfação: o export reflete o novo valor (sem cache/snapshot — FR-003).
