# Research: Ajustes internos da Ouvidoria AGEMAN

## 1. Por que a soma falta 1 e o atendimento mostra menos

**Decision:** As três leituras passam a contar o mesmo conjunto: manifestações do tenant, não apagadas, com status diferente de `draft`, sem protocolo `ouv-demo`, na janela do recorte. Na métrica e no acumulado exibidos, Pendentes = `in_review` + `forwarding` + `closed_unresolved`. Resolvidas = `answered` + `closed`. Meio jurídico = `closed_meio_juridico`. Esses três números somam o total. A soma dos meses de atendimento por mês, na mesma janela da métrica, é igual a esse total.

**Rationale:** `kpisFromStatusGroups` hoje guarda `closed_unresolved` só em `desfechoPendentes`. A métrica na tela mostra Total, Pendentes e Resolvidas, e o acumulado mostra Total, Pendentes, Resolvidas e Meio jurídico, sem o desfecho pendente. Uma manifestação `closed_unresolved` explica o “faltando 1”. O atendimento por mês já conta criação no período (`createdAt`), mas o mês é `EXTRACT(MONTH FROM "createdAt")` no fuso do banco, enquanto a janela da métrica é meia-noite UTC (`yearBounds`). Registro na virada do mês entra no total e sai do mês que o operador soma. O acumulado geral hoje ignora o ano selecionado e conta o histórico inteiro (`GetRelatorioGestaoAcumuladoRepository.execute` sem filtro). O contrato da spec 024 já define a janela em `reportCountWindows`: ano cheio igual ao período; ano e mês, de 1º de janeiro até o fim daquele mês.

**Alternatives considered:** Subir a soma e o gráfico até 105 deixando `ouv-demo` dentro do total. Rejeitado no clarify (opção B): se a demonstração está no 105, o total oficial cai nas três leituras juntas. Manter o acumulado como histórico de todos os anos. Rejeitado: a spec exige o recorte acumulado correspondente, não a vida inteira do tenant.

## 2. Apagar ouv-demo

**Decision:** Um use case apaga de vez as manifestações cujo `protocol` contém `ouv-demo`, sem diferenciar maiúsculas. O seed de insights grava `OUV-DEMO-2026-NNNN` nesse campo (`seed-manifestacoes-insights.ts`), então `OUV-DEMO-2026-0014` entra. A exclusão é física, numa transação, depois de remover dependências sem `ON DELETE CASCADE` (fiscalização da ouvidoria e demandas de gabinete ligadas à manifestação). Anexos, eventos, concessionária e concessões de acesso já cascateiam. Consultas da lista, do painel e do relatório também ignoram esse marcador, para um seed rodado de novo não recolocar a demonstração nas contas antes da próxima limpeza. Manifestação sem o marcador não é apagada. Não há botão de desfazer.

**Rationale:** O clarify escolheu apagar, não ocultar. Soft delete foi recusado. O protocolo é a chave estável; `numeroPersonalizado` não é o formato `ouv-demo`.

**Alternatives considered:** Só filtrar a lista. Rejeitado: a busca e a abertura do registro antigo continuariam encontrando a demonstração. Apagar também quem tem `ouv-demo` só no assunto. Rejeitado: o marcador acordado é o protocolo.

## 3. Página 4 da lista

**Decision:** A página e os filtros da lista ficam na query da rota `/ouvidoria/manifestacoes` e numa cópia em `sessionStorage`. Abrir uma manifestação guarda essa query. “Voltar à lista” e o voltar do navegador reabrem a mesma página e os mesmos filtros. Se o operador sai pelo menu e a rota volta sem query, a lista recupera a cópia da visita. Visita nova (storage vazio) começa na página 1. Mudar filtro grava página 1. Não se guarda etapa do formulário da manifestação.

**Rationale:** `ManifestacoesListPage` guarda `page` em `useState(1)` e o efeito dos filtros chama `setPage(1)`. O detalhe volta com `Link to="/ouvidoria/manifestacoes"`, sem a query. Ao desmontar, o estado some. A spec fechou que “página 4” é a lista, não uma etapa interna.

**Alternatives considered:** Só `navigate(-1)`. Rejeitado: o menu “Manifestações” abre a rota limpa e cairia de novo na página 1. Guardar a etapa do wizard. Rejeitado no clarify (opção A).

## 4. Filtro de status e bloco Pendente (desfecho)

**Decision:** A lista oferece só Todos os status, Pendente, Resolvida pela AGEMAN e Meio jurídico. A API recebe `situacao=pendente|resolvida_ageman|meio_juridico`. Pendente filtra `in_review`, `forwarding` e `closed_unresolved`. Resolvida pela AGEMAN filtra `answered` e `closed`. Meio jurídico filtra `closed_meio_juridico`. Todos os status não envia situação e exclui `draft`. O card “Pendente (desfecho)” sai da faixa de totais da lista. O parâmetro `status` de um único valor permanece para chamadas antigas, mas a tela não o usa.

**Rationale:** O filtro atual lista rascunho, tramitando, respondida, encerrada e pendente (desfecho) em `STATUS_OPTIONS`. O clarify (opção A) juntou os grupos e tirou o rascunho da lista oficial.

**Alternatives considered:** Pendente só como `in_review`. Rejeitado no clarify (opção B). Sumir com `closed_unresolved` da lista. Rejeitado (opção C).

## 5. Quem tem acesso

**Decision:** O bloco só é montado quando o usuário da sessão é super administrador (`role === 'admin_saas'` / `isSuperAdmin`) e o nome normalizado (sem acento, minúsculas, espaços simples) é `romulo gabriel pinheiro pereira`. Administrador de tenant, usuário comum, chefe de setor e outro `admin_saas` não veem o bloco e a tela não pede a lista de acessos. Conceder e revogar no servidor não mudam: quem não vê o bloco não chega na ação.

**Rationale:** `ManifestacaoDetailPage` renderiza `ManifestacaoAcessoCard` para quem tem acesso ao módulo. `canShowOuvidoriaAcessoGrant` ainda libera plataforma, admin e emissor. A spec restringe a visão à conta nomeada, não a todo super administrador.

**Alternatives considered:** Qualquer `isSuperAdmin`. Rejeitado: o terceiro cenário da história 6 exclui outra conta com o mesmo papel. Travar também a API de leitura de acessos. Adiado: o aceite é a visão do bloco; o servidor já exige permissão para conceder.

## 6. Zona automática

**Decision:** No formulário de nova manifestação, `ZoneField` fica somente leitura. Ao mudar o bairro em Manaus, `getZonaByBairro` preenche a zona. Se o bairro não determina zona, o campo fica vazio (não informado) e o registro segue. Não se conserva a zona anterior. Fora desse formulário, o campo continua editável, inclusive o endereço na ficha já salva.

**Rationale:** `NeighborhoodField` já grava a zona pelo bairro, mas `ZoneField` ainda tem `onChange`, e o fallback `zona ?? value.zone` segura a zona velha. A spec limita a trava ao formulário de nova manifestação.

**Alternatives considered:** Zona somente leitura em todo endereço do sistema. Rejeitado: a spec não manda alterar a ficha. Esconder o campo. Rejeitado no clarify (opção C).
