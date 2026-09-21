# Quickstart: Validar os Ajustes na Pesquisa de Satisfação e no Relatório de Gestão

## Pré-requisitos

- `ci-api-v2` rodando localmente com a migration `ouvidoria_ajustes_satisfacao_eventos` aplicada.
- Tenant com módulo `ouvidoria` habilitado, com manifestações que tenham `motivo` longo (ex.: "Recomposição asfáltica (concessionária abriu buraco e não fechou)") e `serviceMode` preenchido em parte dos registros (para validar canal de atendimento no bloco de Orientações/Encaminhamentos).
- Catálogo de perguntas de satisfação já seedado (herdado da spec 042 — inalterado por esta feature).
- Usuário autenticado com acesso ao módulo Ouvidoria (qualquer role — FR-012).

## Setup

```powershell
cd ci-api-v2
npm run prisma:migrate   # aplica a migration desta feature
npm run start:dev
```

```powershell
cd ci-client-v2
npm install
npm run dev   # turbo → @ci/web
```

## Cenário 1 — Lançar satisfação no modelo Sim/Não (US1)

1. Acessar `/ouvidoria/pesquisa-satisfacao`.
2. Lançar, para o mês corrente e uma pergunta do catálogo, `consultados = 25`, `respostasSim = 22`, `respostasNao = 3`.
3. **Esperado**: o formulário não pede mais um "valor" 0–10; salva com sucesso.
4. Abrir `/ouvidoria/relatorio-gestao` no mesmo mês. **Esperado**: bloco de satisfação exibe `88%` (22 ÷ (22+3), arredondado) para essa pergunta.
5. Relançar o mesmo mês/pergunta com `respostasSim = 0`, `respostasNao = 0`. **Esperado**: relatório exibe "sem dados" para essa pergunta/mês (não erro, não `0%`).
6. Relançar novamente com novos números. **Esperado**: sobrescreve o lançamento anterior (sem duplicar — GET lista continua com 1 registro por mês/pergunta).

## Cenário 2 — PDF sem sobreposição de texto (US2)

1. Garantir que existam manifestações com `motivo` longo no período de teste.
2. No relatório de gestão, exportar em PDF para esse período.
3. Abrir o PDF e localizar a tabela "Manifestações por motivo". **Esperado**: cada linha é totalmente legível, sem texto de uma linha sobrepondo a linha vizinha, mesmo quando o motivo ocupa 3–4 linhas dentro da coluna.
4. Repetir a exportação com o filtro "acumulado geral" (maior volume/variedade de motivos). **Esperado**: mesmo resultado, do início ao fim do documento, mesmo com quebras de página.

## Cenário 3 — Orientações/Encaminhamentos detalhado (US3)

1. Garantir manifestações com `programa` (concessão) e `serviceMode` (canal) preenchidos em anos diferentes.
2. Abrir o bloco "Orientações e Encaminhamentos" no relatório de gestão — qualquer filtro de `year`/`month` aplicado à tela.
3. **Esperado**: o bloco mostra o histórico completo multi-ano (concessão × canal × ano), independente do filtro escolhido para o resto da tela.
4. Comparar os totais com uma contagem manual de `Manifestacao` agrupada por `EXTRACT(YEAR FROM "createdAt")`, mapeamento de `programa` (concessão) e `serviceMode` (canal). **Esperado**: números idênticos (SC-003).
5. Exportar em PDF/Excel. **Esperado**: os mesmos números aparecem na seção/aba correspondente.

## Cenário 4 — Participação em Eventos (US4)

1. Acessar a tela de eventos (dentro do módulo Ouvidoria) e cadastrar um evento novo (ex.: "Manaus Cidadã").
2. Lançar `participacoes = 6` para esse evento no mês corrente.
3. Abrir o relatório de gestão filtrando o ano corrente. **Esperado**: bloco "Participação em Eventos" mostra o evento com `6` no mês lançado e `0` nos demais meses do ano, com total do ano correto.
4. Relançar o mesmo evento/mês com `participacoes = 10`. **Esperado**: sobrescreve para `10` (não soma para `16`).
5. Inativar o evento. **Esperado**: participações já lançadas continuam aparecendo no relatório (soft delete não apaga histórico).

## Regressão a checar

- Tenant sem nenhum evento cadastrado: bloco "Participação em Eventos" vazio, com "sem dados", sem erro.
- Reexportar PDF/Excel após qualquer lançamento novo (satisfação ou evento): reflete o estado atual, sem cache (FR-003 herdado da spec 042).
- Tempo de abertura da tela (≤5s) e de export (≤30s) mantidos no "acumulado geral" mesmo com os três blocos novos/alterados (SC-005).
- Usuário sem módulo Ouvidoria habilitado: todas as rotas novas (`/ouvidoria/eventos*`) continuam bloqueadas com `403`, mesma regra das demais.
