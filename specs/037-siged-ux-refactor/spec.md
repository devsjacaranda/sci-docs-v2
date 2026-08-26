# Feature Specification: Refactor UX do SIGED — Diretorias Agrupadas, Home e Licenças Jatobá/Cedro

**Feature Branch**: `037-siged-ux-refactor`

**Created**: 2026-08-10

**Status**: Draft

**Input**: User description: "planejar refact ui ux layout e fluxo das telas do /siged. atualmente as telas do siged so tem exibição de dados brutos, e é um modulo de read-only. quero organizar diretorias aglomerando seus departamentos. aplicar as licenças insigth, fiscalização, e criar uma home da tela, pensendo em post its, e claro, pegar insigts seus."

## User Scenarios & Testing *(mandatory)*

<!--
  IMPORTANT: User stories should be PRIORITIZED as user journeys ordered by importance.
  Each user story/journey must be INDEPENDENTLY TESTABLE - meaning if you implement just ONE of them,
  you should still have a viable MVP (Minimum Viable Product) that delivers value.
-->

### User Story 1 - Servidor navega pelas diretorias sem se perder na lista achatada de órgãos (Priority: P1)

Hoje, ao abrir `/siged`, o servidor vê uma grade única com **todos** os órgãos ativos da hierarquia do SIGED (diretorias e seus departamentos subordinados, em qualquer profundidade), diferenciados apenas por um texto secundário do tipo "Subordinado a X › Y". Isso obriga o servidor a ler cada card para entender a que diretoria um departamento pertence. O servidor precisa, em vez disso, ver primeiro apenas as diretorias de topo, e a partir de cada diretoria, abrir (drill-down) os departamentos subordinados a ela, até chegar ao órgão cujos protocolos quer consultar.

**Why this priority**: É a fundação de UX de todo o módulo — sem uma navegação hierárquica clara, a Home com post-its e as novas telas de licença herdam a mesma confusão visual. É também o item que o usuário priorizou explicitamente como P1.

**Independent Test**: Pode ser testado abrindo a lista principal de diretorias e verificando que aparecem apenas os órgãos de topo da hierarquia SIGED como cards; ao clicar em uma diretoria com departamentos subordinados, uma tela de drill-down lista apenas os departamentos filhos diretos, com breadcrumb voltando aos níveis superiores, até chegar à lista de protocolos do órgão escolhido.

**Acceptance Scenarios**:

1. **Given** a hierarquia de órgãos do SIGED com diretorias de topo e departamentos subordinados em múltiplos níveis, **When** o servidor abre a lista principal de diretorias, **Then** vê somente os órgãos de topo (sem órgão superior) como cards, sem misturar departamentos subordinados na mesma grade.
2. **Given** uma diretoria de topo com departamentos subordinados, **When** o servidor clica nela, **Then** navega para uma tela que lista apenas os departamentos filhos diretos dessa diretoria, mantendo breadcrumb com o caminho percorrido.
3. **Given** um departamento sem subordinados, **When** o servidor abre seu card, **Then** vai direto para a lista de protocolos desse órgão (sem uma tela de drill-down vazia).
4. **Given** uma diretoria que também possui protocolos próprios (além de departamentos subordinados), **When** o servidor está na tela de drill-down dessa diretoria, **Then** encontra uma ação clara para "Ver protocolos desta diretoria", além dos cards dos departamentos filhos.
5. **Given** o servidor está em qualquer nível de profundidade da hierarquia, **When** usa a busca por sigla/descrição, **Then** a busca encontra órgãos dentro do escopo atual (diretoria/departamento selecionado), sem voltar a misturar todos os níveis numa lista só.

---

### User Story 2 - Servidor abre a Home do SIGED e já entende o panorama antes de escolher uma diretoria (Priority: P2)

Hoje `/siged` abre direto na grade de diretorias, sem nenhum resumo ou destaque. O servidor precisa de uma tela inicial (Home) que aparece antes da lista de diretorias, mostrando um resumo do módulo em formato de "post-its" — cartões com KPIs agregados e insights automáticos (licença Cedro) — para entender rapidamente pontos de atenção antes de navegar às diretorias.

**Why this priority**: Depende de dados agregados que fazem mais sentido depois que a navegação por diretorias (US1) já organiza a base de dados; e antecede logicamente a exploração dos painéis dedicados de Fiscalização e Insights (US3/US4), pois é a porta de entrada do módulo.

**Independent Test**: Pode ser testado abrindo `/siged` e verificando que a primeira tela é a Home, com post-its de KPIs/insights, e uma ação clara para prosseguir à lista de diretorias.

**Acceptance Scenarios**:

1. **Given** o servidor autenticado acessa `/siged`, **When** a tela carrega, **Then** vê a Home do módulo antes de qualquer lista de diretorias, com um conjunto de "post-its" (cartões) exibindo KPIs operacionais agregados (ex.: total de diretorias, volume de protocolos recentes) e insights automáticos gerados pela licença Cedro.
2. **Given** a Home exibida, **When** o servidor quer consultar protocolos, **Then** encontra uma ação explícita (ex.: "Ver diretorias") que o leva à tela de navegação hierárquica (US1).
3. **Given** um post-it de insight Cedro na Home, **When** o servidor clica nele, **Then** é levado ao painel de Insights do SIGED (US4) com o insight completo e sua rastreabilidade — a Home nunca exibe o texto integral de raciocínio, apenas o resumo.
4. **Given** nenhum insight Cedro foi gerado ainda para o tenant, **When** a Home carrega, **Then** exibe um post-it de estado vazio orientando a acionar a geração de insights, em vez de esconder a seção ou quebrar a tela.
5. **Given** a consulta ao vivo ao sistema SIGED está indisponível no momento em que a Home carrega, **When** a Home tenta montar os post-its, **Then** os post-its baseados em histórico local (já coletado) continuam aparecendo normalmente, e apenas os KPIs que dependem da consulta ao vivo exibem um aviso de indisponibilidade — a Home não quebra por completo.
6. **Given** os post-its da Home, **When** exibidos, **Then** são somente leitura (não podem ser criados, editados ou fixados manualmente pelo usuário nesta entrega).

---

### User Story 3 - Servidor fiscaliza tramitações e prazos do SIGED com a licença Jatobá (Priority: P3)

O servidor responsável por controle interno precisa de um painel de Fiscalização dedicado ao SIGED (`/siged/auditoria`), que aplique regras próprias sobre os dados de tramitação consultados (prazo de tramitação estourado, protocolo parado há muito tempo em um órgão, ausência de movimentação/resposta), classificando cada achado nos quatro status canônicos de conformidade — sem nunca alterar os dados do protocolo ou da tramitação.

**Why this priority**: Depende da navegação por diretorias (US1) para contextualizar os achados por órgão, e se beneficia do panorama da Home (US2) como ponto de entrada, mas entrega valor por si só mesmo antes dos Insights Cedro (US4).

**Independent Test**: Pode ser testado abrindo `/siged/auditoria`, disparando uma fiscalização e verificando achados com conformidade ∈ {Conforme, Não conforme, Parcial, Pendente}, cada um explicável via sheet de rastreabilidade, sem qualquer alteração nos dados do protocolo/tramitação originais.

**Acceptance Scenarios**:

1. **Given** o painel de Fiscalização do SIGED, **When** o servidor aciona a fiscalização, **Then** o sistema avalia os protocolos/tramitações disponíveis (consulta ao vivo e/ou histórico local já coletado) segundo regras de prazo de tramitação, tempo parado em um órgão e ausência de movimentação, produzindo achados com conformidade nos quatro status canônicos.
2. **Given** um protocolo cuja tramitação entre órgãos ultrapassou a meta institucional de prazo, **When** fiscalizado, **Then** recebe conformidade **Não conforme** (ou **Parcial**/**Pendente** conforme o grau de desvio), com achado descritivo referenciando o protocolo e a diretoria envolvida.
3. **Given** um achado de fiscalização, **When** o servidor aciona a explicação, **Then** abre um sheet de rastreabilidade com o título **"Por que esta checagem deu este resultado"**, sem expor jargão técnico fora de uma seção "Ver detalhe técnico".
4. **Given** o módulo SIGED, **When** um questionário de fiscalização é oferecido, **Then** o respondente é **somente interno** (equipe/portal interno) — sem canal externo, pois o SIGED não tem terceiro identificável equivalente ao de outros módulos.
5. **Given** qualquer achado de fiscalização, **When** exibido em qualquer tela, **Then** o dado original do protocolo/tramitação no SIGED permanece inalterado — a Jatobá apenas sinaliza.
6. **Given** existem achados críticos (Não conforme) no SIGED, **When** o servidor está na Home, na lista de diretorias ou na lista de protocolos, **Then** vê a barra **"Alertas ativos nas licenças"** com atalho para o painel de Fiscalização, seguindo o mesmo padrão usado nos demais módulos da plataforma.

---

### User Story 4 - Gestor consulta insights estratégicos sobre o fluxo entre diretorias do SIGED com a licença Cedro (Priority: P4)

O gestor precisa de um painel de Insights dedicado ao SIGED (`/siged/insights`), com recomendações consultivas e somente leitura sobre volume de protocolos por diretoria, tempo médio de tramitação entre órgãos, gargalos e comparação entre diretorias — para apoiar decisões estratégicas sem substituir a classificação de conformidade da Fiscalização.

**Why this priority**: É o mais estratégico e o que mais depende de dados agregados/históricos consolidados pelas demais frentes (diretorias organizadas, dados de fiscalização); por isso vem por último na priorização definida.

**Independent Test**: Pode ser testado abrindo `/siged/insights`, acionando a geração de insights e verificando que cada insight é claramente identificado como somente leitura, com rastreabilidade própria, e não reclassifica a conformidade de nenhum protocolo.

**Acceptance Scenarios**:

1. **Given** o painel de Insights do SIGED, **When** o gestor aciona "Consultar IA", **Then** o sistema gera insights consultivos (ex.: diretoria com maior volume de protocolos, diretorias com maior tempo médio de tramitação entre órgãos, comparação de gargalos entre diretorias), cada um com impacto ∈ {Crítico, Alto, Médio}.
2. **Given** um insight gerado, **When** o gestor aciona a explicação, **Then** abre um sheet de rastreabilidade com o título **"De onde veio este insight"**, mostrando as evidências (protocolos/diretorias envolvidos) sem alterar nenhum dado.
3. **Given** qualquer insight do SIGED, **When** exibido em qualquer tela (Home ou painel de Insights), **Then** exibe o badge **"Somente leitura"** e nunca apresenta um status de conformidade Jatobá dentro do próprio insight.
4. **Given** o painel de Insights, **When** dados insuficientes ainda foram coletados para uma análise (ex.: tenant recém-configurado, sem histórico), **Then** o sistema informa claramente o motivo (dados insuficientes / nunca gerado) em vez de exibir uma tela vazia sem explicação.

---

### Edge Cases

- Diretoria de topo sem nenhum departamento subordinado e sem protocolos: o card aparece normalmente na lista de topo; ao abrir, mostra a lista de protocolos (vazia, se for o caso) sem tentar exibir uma grade de subordinados vazia.
- Hierarquia com profundidade maior que dois níveis (diretoria → departamento → sub-departamento): a navegação em drill-down deve suportar qualquer profundidade, sempre com breadcrumb atualizado.
- Consulta ao vivo ao SIGED indisponível: KPIs/post-its que dependem de dado ao vivo mostram aviso de indisponibilidade; post-its e achados baseados em histórico local já coletado continuam disponíveis.
- Protocolo sem nenhuma movimentação/tramitação registrada até o momento: a Fiscalização não pode concluir se o prazo foi cumprido — deve classificar como **Pendente** com achado explicando a ausência de dado, nunca travar ou omitir o protocolo da fiscalização.
- Tenant recém-configurado no SIGED, sem histórico local suficiente: Fiscalização e Insights informam "dados insuficientes"/"nunca gerado" em vez de gráficos ou achados vazios sem explicação.
- Diretoria com centenas de protocolos: a busca e a paginação já existentes na lista de protocolos por órgão continuam funcionando após o refactor de navegação — o agrupamento por diretoria não deve reduzir a capacidade de filtrar/paginar dentro de um órgão.
- Um mesmo achado de Fiscalização e um insight de Cedro tratam do mesmo protocolo/diretoria com propósitos diferentes (conformidade operacional vs. estratégico): as duas telas coexistem sem que uma contradiga o texto da outra.
- Usuário sem nenhum alerta ativo (Jatobá/Cedro) no SIGED: a barra de alertas não é exibida em nenhuma tela do módulo (Home, diretorias, protocolos).

## Requirements *(mandatory)*

### Functional Requirements

**Home do módulo**

- **FR-001**: O sistema DEVE exibir, ao acessar `/siged`, uma tela de Home que antecede a navegação por diretorias, mostrando um conjunto de "post-its" (cartões) com KPIs agregados do módulo e insights automáticos da licença Cedro.
- **FR-002**: Os post-its da Home DEVEM ser somente leitura nesta entrega — não é permitido ao usuário criar, editar ou fixar notas manuais.
- **FR-003**: A Home DEVE oferecer uma ação explícita para avançar à navegação hierárquica de diretorias.
- **FR-004**: Quando não houver insights Cedro gerados para o tenant, a Home DEVE exibir um post-it de estado vazio orientando a geração, em vez de omitir a seção.
- **FR-005**: Quando a consulta ao vivo ao sistema SIGED estiver indisponível, a Home DEVE continuar exibindo os post-its baseados em histórico local já coletado, sinalizando separadamente apenas os KPIs que dependem da consulta ao vivo.

**Navegação e agrupamento de diretorias/departamentos**

- **FR-006**: O sistema DEVE exibir, na tela principal de navegação, somente os órgãos de topo (sem órgão superior) da hierarquia SIGED como cards agrupadores — não DEVE misturar departamentos subordinados de diferentes níveis na mesma grade.
- **FR-007**: Ao selecionar uma diretoria com departamentos subordinados, o sistema DEVE navegar para uma tela de drill-down listando apenas os departamentos filhos diretos dessa diretoria, com breadcrumb do caminho percorrido.
- **FR-008**: Ao selecionar um órgão sem subordinados, o sistema DEVE navegar diretamente à lista de protocolos desse órgão.
- **FR-009**: Quando uma diretoria possuir tanto departamentos subordinados quanto protocolos próprios, a tela de drill-down DEVE oferecer uma ação explícita para ver os protocolos da própria diretoria, além dos cards dos departamentos filhos.
- **FR-010**: A busca por sigla/descrição DEVE operar dentro do escopo do nível de navegação atual (diretoria/departamento selecionado), preservando a organização hierárquica.
- **FR-011**: A lista de protocolos por órgão (já existente) DEVE manter suas capacidades atuais de filtro, paginação e exportação após o refactor de navegação.

**Fiscalização SIGED (Jatobá)**

- **FR-012**: O sistema DEVE oferecer um painel de Fiscalização dedicado ao SIGED em `/siged/auditoria`, aplicando regras próprias de conformidade sobre dados de tramitação: prazo de tramitação entre órgãos, tempo parado em um órgão acima de um limite institucional, e ausência de movimentação/resposta.
- **FR-013**: Cada achado de fiscalização DEVE ser classificado em exatamente um dos quatro status canônicos: Conforme, Não conforme, Parcial ou Pendente.
- **FR-014**: A Fiscalização SIGED NÃO DEVE, em nenhuma circunstância, alterar os dados do protocolo ou da tramitação consultados — apenas sinalizar achados.
- **FR-015**: Quando o módulo oferecer questionário de fiscalização, o respondente DEVE ser somente interno (equipe/portal interno) — sem canal externo para terceiros.
- **FR-016**: Cada achado de fiscalização DEVE oferecer rastreabilidade via sheet com o título "Por que esta checagem deu este resultado", incluindo referência ao protocolo e à diretoria/órgão envolvido.
- **FR-017**: Quando não houver movimentação/tramitação registrada para um protocolo, a Fiscalização DEVE classificá-lo como Pendente com achado explicativo, em vez de omiti-lo ou falhar.

**Insights SIGED (Cedro)**

- **FR-018**: O sistema DEVE oferecer um painel de Insights dedicado ao SIGED em `/siged/insights`, com recomendações consultivas sobre volume de protocolos por diretoria, tempo médio de tramitação entre órgãos, gargalos e comparação entre diretorias.
- **FR-019**: Todo insight do SIGED DEVE ser exibido com o badge "Somente leitura" e NÃO DEVE alterar dados de protocolo, tramitação ou dos achados de Fiscalização.
- **FR-020**: Cada insight DEVE oferecer rastreabilidade via sheet com o título "De onde veio este insight", incluindo as evidências (protocolos/diretorias) usadas.
- **FR-021**: Quando não houver dados suficientes para gerar uma análise consultiva, o painel DEVE informar o motivo (dados insuficientes / nunca gerado) em vez de exibir uma tela vazia sem explicação.
- **FR-022**: Os insights do SIGED NÃO DEVEM reclassificar nem contradizer a conformidade já atribuída pela Fiscalização a um mesmo protocolo.

**Alertas de licença e consistência de plataforma**

- **FR-023**: A Home, a lista de diretorias e a lista de protocolos DEVEM exibir a barra "Alertas ativos nas licenças" (crítico) ou "Pontos de atenção nas licenças" (atenção) sempre que houver achados Jatobá ou insights Cedro pendentes de atenção no módulo, com atalhos para Fiscalização e Insights — e NÃO DEVEM exibir essa barra quando não houver pendências.
- **FR-024**: Nenhuma tela de listagem do SIGED DEVE exibir coluna, chip ou legenda de semáforo de conformidade por linha da tabela — indicação de conformidade fica restrita à barra de alertas e ao painel de Fiscalização.
- **FR-025**: A anotação local "Controle Interno" por protocolo (status de fluxo Pendente/Em análise/Revisado/Arquivado + nota + responsável + tags) DEVE continuar como funcionalidade da Base, sem se misturar com a classificação de conformidade Jatobá nem com os status operacionais existentes.
- **FR-026**: O módulo SIGED DEVE continuar vinculado ao controle de acesso e à licença do módulo "Gabinete do Presidente" para fins de navegação e permissão — nenhuma tela nova desta entrega DEVE criar um módulo de negócio independente.
- **FR-027**: Todo vocabulário, nomes de tela, status canônicos, badges e copy de botões introduzidos por esta entrega DEVEM seguir literalmente `licencas-canonicas.md` e `regras-plataforma.md` (ex.: "Fiscalização", "Insights IA"/"Insights Cedro", "Somente leitura", "Como chegamos aqui?").

**Dados e histórico**

- **FR-028**: O sistema DEVE manter um histórico local de indicadores de tramitação do SIGED (ex.: volume por diretoria, tempo entre movimentações) coletado ao longo do tempo, suficiente para que a Fiscalização e os Insights calculem médias e tendências, e não apenas o instante da consulta.
- **FR-029**: Achados de Fiscalização e insights de Cedro do SIGED DEVEM indicar de forma clara quando derivam de consulta ao vivo versus de histórico local já coletado.

### Key Entities *(include if feature involves data)*

- **Diretoria/Departamento SIGED**: Órgão da hierarquia externa do SIGED (já existente); possui sigla, descrição, situação ativa/inativa e subordinados; agora também um papel explícito de "nível de topo" vs. "subordinado" para fins de agrupamento visual.
- **Protocolo SIGED**: Documento consultado no sistema externo (já existente), vinculado a um órgão.
- **Tramitação SIGED**: Movimentação entre órgãos de um protocolo, consultada ao vivo (já existente).
- **Controle Interno**: Anotação local por protocolo (status de fluxo, nota, responsável, tags) — inalterada por esta entrega, permanece Base.
- **Post-it da Home**: Representação visual resumida de um KPI agregado ou de um insight Cedro, exibida na Home do módulo; somente leitura.
- **Achado de Fiscalização SIGED**: Resultado de uma checagem Jatobá sobre um protocolo/diretoria; possui conformidade (um dos quatro status canônicos), descrição, regra aplicada e rastreabilidade.
- **Insight SIGED**: Recomendação consultiva Cedro sobre o conjunto de diretorias/protocolos do SIGED; possui impacto, categoria, evidências e rastreabilidade.
- **Snapshot Histórico do SIGED**: Registro periódico de indicadores agregados (volume, tempos de tramitação por diretoria) usado como base para o cálculo de tendências pela Fiscalização e pelos Insights.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A partir da Home, o servidor chega à lista de protocolos de qualquer órgão da hierarquia SIGED em no máximo 4 cliques, independentemente da profundidade da diretoria.
- **SC-002**: A tela principal de navegação exibe apenas os órgãos de topo como cards — uma redução mensurável frente ao estado atual, em que todos os órgãos ativos de qualquer profundidade aparecem juntos na mesma grade.
- **SC-003**: 100% dos achados exibidos no painel de Fiscalização do SIGED pertencem ao conjunto canônico {Conforme, Não conforme, Parcial, Pendente}.
- **SC-004**: 100% dos insights exibidos no painel de Insights (e nos post-its da Home) trazem o badge "Somente leitura" e nenhum deles altera dado de protocolo, tramitação ou achado de Fiscalização em testes de aceitação.
- **SC-005**: O servidor identifica, em menos de 5 segundos ao abrir qualquer tela do módulo SIGED, se há alertas críticos ou de atenção pendentes, via barra de alertas — sem precisar abrir cada painel individualmente.
- **SC-006**: Um gestor consegue responder "quais diretorias concentram o maior tempo médio de tramitação" a partir do painel de Insights, sem precisar abrir protocolos individualmente.
- **SC-007**: Quando a consulta ao vivo ao SIGED falha, a Home e os painéis de Fiscalização/Insights continuam utilizáveis (com os dados de histórico local disponíveis), em vez de apresentarem tela quebrada ou em branco.

## Assumptions

- **Home é uma tela nova, adicional, que antecede a lista de diretorias** — não substitui a navegação existente, apenas passa a ser o primeiro ponto de entrada de `/siged` (decisão confirmada com o usuário).
- **Post-its da Home são somente automáticos** (insights Cedro + KPIs agregados), sem funcionalidade de notas manuais fixadas pelo usuário nesta entrega (decisão confirmada com o usuário).
- **Agrupamento de diretorias é feito por nível de topo + drill-down**: a tela principal mostra só diretorias de topo; departamentos subordinados aparecem em telas de drill-down subsequentes, com profundidade arbitrária suportada via breadcrumb (decisão confirmada com o usuário).
- **Fiscalização (Jatobá) do SIGED é um painel dedicado**, com regras próprias de prazo de tramitação, tempo parado em órgão e ausência de movimentação — não é apenas um link para a Fiscalização já existente do Gabinete (decisão confirmada com o usuário). Segue o mesmo padrão de questionário **somente interno** já usado no domínio de tramitação/protocolo da plataforma (não há terceiro externo identificável em dados do SIGED).
- **Insights (Cedro) do SIGED são dedicados**, focados em volume, tempo médio de tramitação e gargalos entre diretorias — não é apenas um link para os Insights já existentes do Gabinete (decisão confirmada com o usuário).
- **É necessário introduzir histórico local leve dos indicadores consultados no SIGED** para que Fiscalização e Insights consigam calcular tendências reais (ex.: tempo médio nos últimos 30 dias), já que hoje o SIGED só é consultado ao vivo, sem persistência (decisão confirmada com o usuário). O desenho técnico exato dessa persistência (schema, frequência de coleta, retenção) é decidido na fase de `/speckit-plan`, não nesta spec.
- **A anotação "Controle Interno" existente permanece como está**, licenciada como Base, sem absorver nem ser absorvida pela classificação de conformidade Jatobá (decisão confirmada com o usuário).
- **O SIGED continua parte do módulo "Gabinete do Presidente"** para fins de controle de acesso e licenciamento — não se torna um módulo de negócio independente (decisão confirmada com o usuário).
- **Prioridade de entrega (MVP) confirmada com o usuário**: 1) Agrupamento de diretorias (US1), 2) Home com post-its (US2), 3) Fiscalização Jatobá (US3), 4) Insights Cedro (US4) — cada uma independentemente testável e entregável.
- Esta entrega cobre apenas o app tenant (`ci-client-v2/apps/web`) e os endpoints/casos de uso necessários em `ci-api-v2` para suportar as novas telas; não inclui o app `admin-saas`.
- A integração de autenticação/consulta ao sistema SIGED em si (credenciais por tenant, endpoints externos) não muda nesta entrega — o refactor é de UX, navegação e aplicação de licenças sobre os dados já consultados.
- Vocabulário, status canônicos, badges e padrões de rastreabilidade seguem literalmente `licencas-canonicas.md` e `regras-plataforma.md`.
