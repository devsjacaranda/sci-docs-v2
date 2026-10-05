# Feature Specification: Ajustes internos da Ouvidoria AGEMAN

**Feature Branch**: `025-ageman-ouvidoria-ajustes`

**Created**: 2026-10-05

**Status**: Completed

**Input**: User description: "alteraÃ§Ãµes internas da AGEMAN: zona automÃ¡tica no formulÃ¡rio de nova manifestaÃ§Ã£o; mÃ©trica de desempenho, acumulado geral e atendimento por mÃªs com contas que nÃ£o batem (total 105, soma faltando 1, atendimento em 98); retirar demandas de demonstraÃ§Ã£o ou teste como ouv-demo-2026-0014 da pÃ¡gina de manifestaÃ§Ãµes; ao sair e voltar, reabrir a pÃ¡gina da lista que estava aberta (exemplo: pÃ¡gina 4, e nÃ£o a pÃ¡gina 1); filtro de status sÃ³ com Todos os status, Pendente, Resolvida pela AGEMAN e Meio jurÃ­dico; Quem tem acesso visÃ­vel sÃ³ para o super administrador AGEMAN Romulo Gabriel Pinheiro Pereira; retirar o bloco Pendente (desfecho) das manifestaÃ§Ãµes."

## Clarifications

### Session 2026-10-05

- Q: No perÃ­odo em que a mÃ©trica deu 105, a soma ficou 1 abaixo e o atendimento por mÃªs mostrou 98, o que vale quando as manifestaÃ§Ãµes ouv-demo saÃ­rem? â†’ A: ouv-demo sai da pÃ¡gina de manifestaÃ§Ãµes e das trÃªs contas. Se essas demonstraÃ§Ãµes faziam parte do 105, o total oficial deixa de ser 105. MÃ©trica, soma das partes e atendimento por mÃªs ficam iguais no nÃºmero que sobrar.
- Q: Quando o usuÃ¡rio estava na pÃ¡gina 4 e, ao sair sem querer, voltou para a pÃ¡gina 1, o que deve ser preservado? â†’ A: A pÃ¡gina 4 da lista de manifestaÃ§Ãµes. Ao abrir uma manifestaÃ§Ã£o e voltar, ou ao sair da lista e retornar na mesma visita, a lista reabre na pÃ¡gina 4, com os filtros.
- Q: No filtro da lista, o que entra em cada opÃ§Ã£o? â†’ A: Pendente reÃºne em anÃ¡lise, tramitaÃ§Ã£o e o antigo desfecho pendente. Resolvida pela AGEMAN reÃºne respondidas e encerradas com resoluÃ§Ã£o. Meio jurÃ­dico fica sÃ³ nesse desfecho. Rascunho continua de fora da lista oficial.
- Q: O que fazer com manifestaÃ§Ãµes como ouv-demo-2026-0014? â†’ A: Apagar de vez ouv-demo-2026-0014 e as demais com o marcador ouv-demo.
- Q: No formulÃ¡rio de nova manifestaÃ§Ã£o, como a zona automÃ¡tica deve se comportar? â†’ A: A zona Ã© preenchida sozinha a partir do endereÃ§o e o usuÃ¡rio nÃ£o a altera. Se estiver errada, corrige-se o endereÃ§o.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Os totais da Ouvidoria batem entre si (Priority: P1)

Como responsÃ¡vel pela Ouvidoria da AGEMAN, preciso que a mÃ©trica de desempenho do perÃ­odo, o acumulado geral e o atendimento por mÃªs contem o mesmo conjunto de manifestaÃ§Ãµes, para prestar contas sem explicar uma diferenÃ§a que o sistema mesmo criou.

**Why this priority**: No relato, a mÃ©trica mostrou 105, a soma das partes ficou 1 abaixo e o atendimento por mÃªs mostrou 98. NÃºmero que nÃ£o fecha tira a confianÃ§a do relatÃ³rio. O total oficial Ã© o que sobra sem demonstraÃ§Ã£o, e as trÃªs leituras tÃªm de mostrar esse mesmo nÃºmero.

**Independent Test**: Escolher um perÃ­odo conhecido, ler o total da mÃ©trica, somar as partes dessa mÃ©trica, somar os meses de atendimento e comparar com o acumulado do mesmo recorte. Os trÃªs resultados oficiais sÃ£o iguais.

**Acceptance Scenarios**:

1. **Given** um perÃ­odo em que a mÃ©trica mostra um total oficial, **When** o responsÃ¡vel soma as situaÃ§Ãµes exibidas nessa mÃ©trica, **Then** a soma Ã© igual ao total, sem faltar nem sobrar manifestaÃ§Ã£o.
2. **Given** o mesmo perÃ­odo, **When** o responsÃ¡vel soma os meses de atendimento por mÃªs, **Then** o resultado Ã© o mesmo total da mÃ©trica, e nÃ£o um nÃºmero menor.
3. **Given** o mesmo perÃ­odo, **When** o responsÃ¡vel lÃª o acumulado geral atÃ© o fim desse perÃ­odo, **Then** o acumulado usa as mesmas manifestaÃ§Ãµes oficiais da mÃ©trica e do atendimento por mÃªs.
4. **Given** o caso relatado em que a mÃ©trica mostrou 105, a soma das partes faltava 1 e o atendimento mostrou 98, **When** o mesmo perÃ­odo Ã© consultado de novo, sem manifestaÃ§Ãµes ouv-demo, **Then** mÃ©trica, soma das partes e atendimento por mÃªs mostram o mesmo total. Se o 105 incluÃ­a demonstraÃ§Ã£o, esse total oficial Ã© menor que 105.

---

### User Story 2 - DemonstraÃ§Ãµes e testes sÃ£o apagados (Priority: P1)

Como operador da Ouvidoria, preciso que manifestaÃ§Ãµes de demonstraÃ§Ã£o ou criadas em teste, como ouv-demo-2026-0014, sejam apagadas, para a lista e o relatÃ³rio refletirem sÃ³ a demanda real.

**Why this priority**: Registro de demonstraÃ§Ã£o misturado com demanda real altera a lista e pode ser justamente a diferenÃ§a entre os totais. Ocultar nÃ£o basta: o registro sai de vez.

**Independent Test**: Procurar ouv-demo-2026-0014 e qualquer outro protocolo com o marcador ouv-demo na lista, na busca, no painel e nos arquivos do perÃ­odo. Nenhum deles existe mais, e os totais nÃ£o os incluem.

**Acceptance Scenarios**:

1. **Given** a manifestaÃ§Ã£o ouv-demo-2026-0014 existente, **When** a limpeza Ã© aplicada, **Then** ela deixa de existir: nÃ£o aparece na lista, na busca, nos totais nem ao tentar abrir o registro antigo.
2. **Given** outras manifestaÃ§Ãµes identificadas pelo marcador ouv-demo, **When** a limpeza Ã© aplicada, **Then** todas sÃ£o apagadas e nÃ£o entram na lista, no painel nem nos arquivos baixados.
3. **Given** uma manifestaÃ§Ã£o real salva no mesmo perÃ­odo, sem o marcador ouv-demo, **When** as demonstraÃ§Ãµes sÃ£o apagadas, **Then** a manifestaÃ§Ã£o real continua visÃ­vel e contada.

---

### User Story 3 - A zona volta a ser preenchida sozinha (Priority: P2)

Como quem registra uma nova manifestaÃ§Ã£o, preciso que a zona seja preenchida automaticamente a partir do endereÃ§o e que eu nÃ£o possa alterÃ¡-la Ã  mÃ£o, para o dado ficar alinhado ao bairro informado.

**Why this priority**: O formulÃ¡rio deixou de preencher a zona sozinho. O registro diÃ¡rio fica mais lento e a zona passa a divergir do endereÃ§o.

**Independent Test**: Abrir nova manifestaÃ§Ã£o, informar um endereÃ§o com bairro que pertence a uma zona conhecida e conferir que a zona aparece preenchida sem digitaÃ§Ã£o. Trocar o bairro e ver a zona acompanhar o novo endereÃ§o.

**Acceptance Scenarios**:

1. **Given** o formulÃ¡rio de nova manifestaÃ§Ã£o, **When** o usuÃ¡rio informa um endereÃ§o cujo bairro determina uma zona, **Then** a zona Ã© preenchida sozinha e o campo nÃ£o aceita alteraÃ§Ã£o manual.
2. **Given** uma zona jÃ¡ preenchida, **When** o usuÃ¡rio altera o endereÃ§o para outro bairro de outra zona, **Then** a zona acompanha o novo endereÃ§o. Corrigir a zona errada Ã© corrigir o endereÃ§o, nÃ£o o campo de zona.
3. **Given** um endereÃ§o que nÃ£o determina zona, **When** o usuÃ¡rio segue o registro, **Then** a zona fica como nÃ£o informada e o salvamento da manifestaÃ§Ã£o nÃ£o Ã© bloqueado por isso.

---

### User Story 4 - Voltar para a pÃ¡gina da lista em que se estava (Priority: P2)

Como operador que percorre a lista de manifestaÃ§Ãµes, preciso voltar para a mesma pÃ¡gina em que estava quando saio sem querer, para nÃ£o recomeÃ§ar da primeira pÃ¡gina.

**Why this priority**: Quem estÃ¡ na pÃ¡gina 4 da lista perde o lugar ao clicar para sair e retorna na pÃ¡gina 1. A busca do caso em andamento recomeÃ§a. A etapa interna de uma manifestaÃ§Ã£o aberta nÃ£o entra nesta correÃ§Ã£o.

**Independent Test**: Ir atÃ© a pÃ¡gina 4 da lista, abrir uma manifestaÃ§Ã£o ou sair da lista e voltar na mesma visita. A lista reabre na pÃ¡gina 4, com os filtros que estavam em uso.

**Acceptance Scenarios**:

1. **Given** o operador na pÃ¡gina 4 da lista de manifestaÃ§Ãµes, **When** abre uma manifestaÃ§Ã£o e volta para a lista, **Then** a lista reabre na pÃ¡gina 4.
2. **Given** o operador na pÃ¡gina 4, **When** sai da lista sem querer e retorna a ela na mesma visita, **Then** a lista reabre na pÃ¡gina 4, e nÃ£o na pÃ¡gina 1.
3. **Given** filtros jÃ¡ aplicados na pÃ¡gina 4, **When** o operador volta para a lista, **Then** os mesmos filtros continuam aplicados.
4. **Given** uma visita nova, **When** o operador abre a lista pela primeira vez, **Then** a lista comeÃ§a na pÃ¡gina 1.

---

### User Story 5 - Filtro de status enxuto e sem Pendente (desfecho) (Priority: P2)

Como operador da AGEMAN, preciso filtrar manifestaÃ§Ãµes sÃ³ por Todos os status, Pendente, Resolvida pela AGEMAN e Meio jurÃ­dico, e nÃ£o ver mais o bloco Pendente (desfecho), para a lista usar as mesmas situaÃ§Ãµes que a equipe acompanha.

**Why this priority**: O filtro atual oferece situaÃ§Ãµes a mais, inclusive Pendente (desfecho), e a pÃ¡gina ainda mostra um bloco com esse nome. A equipe pediu para ficar sÃ³ com as trÃªs situaÃ§Ãµes oficiais mais a opÃ§Ã£o de ver todas.

**Independent Test**: Abrir o filtro de status da lista e a faixa de totais da pÃ¡gina. As opÃ§Ãµes sÃ£o exatamente as quatro pedidas, e nÃ£o existe bloco nem opÃ§Ã£o com o texto Pendente (desfecho).

**Acceptance Scenarios**:

1. **Given** a lista de manifestaÃ§Ãµes, **When** o operador abre o filtro de status, **Then** as opÃ§Ãµes sÃ£o somente Todos os status, Pendente, Resolvida pela AGEMAN e Meio jurÃ­dico.
2. **Given** a mesma lista, **When** a pÃ¡gina mostra os totais, **Then** nÃ£o existe bloco Pendente (desfecho).
3. **Given** o filtro Pendente, **When** o operador aplica, **Then** a lista mostra as manifestaÃ§Ãµes em anÃ¡lise, em tramitaÃ§Ã£o e as do antigo desfecho pendente, e nÃ£o mostra meio jurÃ­dico nem rascunho.
4. **Given** o filtro Resolvida pela AGEMAN, **When** o operador aplica, **Then** a lista mostra as manifestaÃ§Ãµes respondidas e as encerradas com resoluÃ§Ã£o, e nÃ£o mostra pendente nem meio jurÃ­dico.
5. **Given** o filtro Meio jurÃ­dico, **When** o operador aplica, **Then** a lista mostra sÃ³ as manifestaÃ§Ãµes nesse desfecho.
6. **Given** o filtro Todos os status, **When** o operador aplica, **Then** a lista mostra todas as manifestaÃ§Ãµes oficiais, sem demonstraÃ§Ã£o e sem rascunho nÃ£o salvo como manifestaÃ§Ã£o.

---

### User Story 6 - Quem tem acesso sÃ³ para o super administrador nomeado (Priority: P2)

Como super administrador da AGEMAN, Romulo Gabriel Pinheiro Pereira precisa ver quem tem acesso Ã s informaÃ§Ãµes do formulÃ¡rio. UsuÃ¡rios comuns, administradores e qualquer outra conta nÃ£o devem ver esse bloco.

**Why this priority**: A visÃ£o de quem acessa o formulÃ¡rio expÃµe informaÃ§Ã£o de controle. A equipe pediu para restringir Ã  conta do super administrador da AGEMAN.

**Independent Test**: Entrar com a conta do super administrador AGEMAN Romulo Gabriel Pinheiro Pereira e ver o bloco Quem tem acesso. Entrar com um administrador e com um usuÃ¡rio comum e confirmar que o bloco nÃ£o aparece.

**Acceptance Scenarios**:

1. **Given** a conta do super administrador AGEMAN Romulo Gabriel Pinheiro Pereira, **When** abre uma manifestaÃ§Ã£o em que existe o bloco Quem tem acesso, **Then** o bloco Ã© exibido.
2. **Given** um usuÃ¡rio comum ou um administrador, **When** abre a mesma manifestaÃ§Ã£o, **Then** o bloco Quem tem acesso nÃ£o aparece.
3. **Given** outra conta, ainda que com papel de super administrador, **When** abre a mesma manifestaÃ§Ã£o, **Then** o bloco Quem tem acesso nÃ£o aparece.

---

### Edge Cases

- ManifestaÃ§Ã£o real sem o marcador ouv-demo permanece, mesmo que tenha sido usada em treinamento informal. SÃ³ o marcador ouv-demo autoriza a exclusÃ£o.
- Se apagar ouv-demo reduzir o antigo total de 105, mÃ©trica, soma das partes e atendimento por mÃªs mostram o nÃºmero menor. Nenhuma das trÃªs permanece em 105 sÃ³ para nÃ£o baixar o total.
- A exclusÃ£o nÃ£o tem desfazer na tela. Um protocolo apagado por engano sÃ³ volta por recuperaÃ§Ã£o operacional fora desta entrega.
- Rascunho ainda nÃ£o salvo como manifestaÃ§Ã£o continua guardado para o autor retomar, mas nÃ£o entra na mÃ©trica, no acumulado, no atendimento por mÃªs nem na lista oficial.
- Se o perÃ­odo nÃ£o tem manifestaÃ§Ãµes oficiais, as trÃªs leituras mostram zero e continuam iguais entre si.
- Atendimento por mÃªs nÃ£o cria mÃªs inexistente nem conta manifestaÃ§Ã£o fora do perÃ­odo selecionado para fechar a soma.
- Troca de filtro de status ou de outro filtro da lista volta para a pÃ¡gina 1, porque o resultado mudou. Sair e voltar sem mudar o filtro preserva a pÃ¡gina.
- EndereÃ§o incompleto nÃ£o inventa zona: fica nÃ£o informada atÃ© o bairro permitir o preenchimento.
- Se a conta nomeada nÃ£o estiver disponÃ­vel, ninguÃ©m vÃª Quem tem acesso. O restante do formulÃ¡rio continua visÃ­vel para quem jÃ¡ tinha acesso Ã  manifestaÃ§Ã£o.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: A mÃ©trica de desempenho do perÃ­odo, o acumulado geral e o atendimento por mÃªs MUST contar o mesmo conjunto de manifestaÃ§Ãµes oficiais do recorte consultado.
- **FR-002**: A soma das situaÃ§Ãµes mostradas na mÃ©trica de desempenho do perÃ­odo MUST ser igual ao total dessa mÃ©trica.
- **FR-003**: A soma dos meses em atendimento por mÃªs MUST ser igual ao total da mÃ©trica de desempenho do mesmo perÃ­odo.
- **FR-004**: O acumulado geral MUST usar as mesmas manifestaÃ§Ãµes oficiais consideradas na mÃ©trica e no atendimento por mÃªs, no recorte acumulado correspondente.
- **FR-005**: ManifestaÃ§Ãµes identificadas pelo marcador ouv-demo, incluindo ouv-demo-2026-0014, MUST ser apagadas de vez, e nÃ£o apenas ocultadas. Depois da exclusÃ£o, MUST NOT aparecer na lista, na busca, no painel, nas contas oficiais nem nos arquivos baixados.
- **FR-006**: Apagar demonstraÃ§Ã£o e teste MUST preservar as manifestaÃ§Ãµes reais do mesmo perÃ­odo, isto Ã©, as que nÃ£o tÃªm o marcador ouv-demo.
- **FR-007**: No formulÃ¡rio de nova manifestaÃ§Ã£o, a zona MUST ser preenchida automaticamente a partir do endereÃ§o informado. O usuÃ¡rio MUST NOT alterar a zona Ã  mÃ£o.
- **FR-008**: Quando o endereÃ§o muda para um bairro de outra zona, a zona MUST ser atualizada automaticamente. Zona errada corrige-se pelo endereÃ§o. Quando o endereÃ§o nÃ£o determina zona, a zona MUST ficar como nÃ£o informada e MUST NOT impedir o registro.
- **FR-009**: Na mesma visita, ao abrir uma manifestaÃ§Ã£o e voltar para a lista, ou ao sair da lista e retornar, o sistema MUST reabrir a lista de manifestaÃ§Ãµes na mesma pÃ¡gina e com os mesmos filtros. Esta regra vale para a paginaÃ§Ã£o da lista, nÃ£o para uma etapa dentro da manifestaÃ§Ã£o aberta.
- **FR-010**: Uma visita nova Ã  lista MUST comeÃ§ar na pÃ¡gina 1. Alterar um filtro MUST voltar para a pÃ¡gina 1.
- **FR-011**: O filtro de status da lista de manifestaÃ§Ãµes MUST oferecer somente: Todos os status, Pendente, Resolvida pela AGEMAN e Meio jurÃ­dico.
- **FR-012**: Pendente MUST reunir em anÃ¡lise, tramitaÃ§Ã£o e o antigo desfecho pendente. Resolvida pela AGEMAN MUST reunir respondidas e encerradas com resoluÃ§Ã£o. Meio jurÃ­dico MUST reunir sÃ³ esse desfecho. Rascunho MUST permanecer de fora desses trÃªs filtros e da lista oficial.
- **FR-013**: A pÃ¡gina de manifestaÃ§Ãµes MUST NOT exibir o bloco Pendente (desfecho).
- **FR-014**: O bloco Quem tem acesso MUST ser exibido somente para a conta do super administrador AGEMAN Romulo Gabriel Pinheiro Pereira.
- **FR-015**: UsuÃ¡rios comuns, administradores e qualquer outra conta MUST NOT ver o bloco Quem tem acesso.
- **FR-016**: Rascunhos ainda nÃ£o confirmados como manifestaÃ§Ã£o MUST permanecer recuperÃ¡veis pelo autor e MUST NOT entrar na lista oficial nem nas trÃªs contas do relatÃ³rio.

### Key Entities

- **ManifestaÃ§Ã£o oficial**: demanda salva da Ouvidoria, que entra na lista e nas contas. NÃ£o inclui rascunho nÃ£o confirmado nem demonstraÃ§Ã£o ou teste.
- **ManifestaÃ§Ã£o de demonstraÃ§Ã£o ou teste**: registro criado para amostra ou ensaio, reconhecido pelo marcador ouv-demo no protocolo, como ouv-demo-2026-0014. Esta entrega apaga esses registros.
- **Zona**: regiÃ£o do endereÃ§o da manifestaÃ§Ã£o, derivada do bairro informado e nÃ£o editÃ¡vel Ã  mÃ£o, ou nÃ£o informada quando o endereÃ§o nÃ£o permite determinar.
- **PÃ¡gina da lista**: posiÃ§Ã£o atual da lista de manifestaÃ§Ãµes, junto com os filtros aplicados naquela visita.
- **Quem tem acesso**: bloco do formulÃ¡rio que mostra quem pode ver as informaÃ§Ãµes da manifestaÃ§Ã£o. VisÃ­vel sÃ³ para a conta nomeada do super administrador AGEMAN.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Em qualquer perÃ­odo consultado, a soma das partes da mÃ©trica, a soma do atendimento por mÃªs e o acumulado correspondente sÃ£o o mesmo nÃºmero, com diferenÃ§a zero.
- **SC-002**: No perÃ­odo do relato, mÃ©trica, soma das partes e atendimento por mÃªs passam a mostrar o mesmo total, sem ouv-demo. Se o 105 antigo incluÃ­a demonstraÃ§Ã£o, o total oficial Ã© menor que 105 e ainda assim igual nas trÃªs leituras.
- **SC-003**: Nenhuma manifestaÃ§Ã£o com marcador ouv-demo, inclusive ouv-demo-2026-0014, continua existindo. Busca, lista, painel, totais e arquivos baixados nÃ£o as encontram.
- **SC-004**: Em 10 tentativas de informar um endereÃ§o com zona conhecida, a zona vem preenchida sem digitaÃ§Ã£o em todas, e em nenhuma dessas tentativas o campo aceita um valor digitado Ã  mÃ£o.
- **SC-005**: Em 10 saÃ­das acidentais a partir da pÃ¡gina 4 da lista, com retorno na mesma visita, a lista reabre na pÃ¡gina 4 nas 10 vezes. A etapa interna de uma manifestaÃ§Ã£o aberta pode recomeÃ§ar na primeira.
- **SC-006**: O filtro de status mostra exatamente 4 opÃ§Ãµes, e a pÃ¡gina de manifestaÃ§Ãµes nÃ£o exibe o texto Pendente (desfecho).
- **SC-007**: Somente a conta do super administrador AGEMAN Romulo Gabriel Pinheiro Pereira vÃª Quem tem acesso. Nas demais contas verificadas, o bloco estÃ¡ ausente.

## Assumptions

- O total oficial do perÃ­odo Ã© a contagem das manifestaÃ§Ãµes reais, sem ouv-demo e sem rascunho nÃ£o confirmado. O 105 do relato nÃ£o Ã© preservado se parte dele for demonstraÃ§Ã£o. DemonstraÃ§Ã£o sai das trÃªs leituras juntas, para mÃ©trica, acumulado e atendimento por mÃªs continuarem iguais.
- O marcador de demonstraÃ§Ã£o ou teste Ã© o trecho ouv-demo no protocolo, sem diferenciar maiÃºsculas. Esses registros sÃ£o apagados de vez. ManifestaÃ§Ã£o sem esse marcador nÃ£o Ã© apagada.
- Pendente reÃºne em anÃ¡lise, tramitaÃ§Ã£o e o antigo desfecho pendente. Resolvida pela AGEMAN reÃºne respondidas e encerradas com resoluÃ§Ã£o. O bloco Pendente (desfecho) deixa de existir; esses registros passam a aparecer em Pendente.
- A zona automÃ¡tica usa o bairro do endereÃ§o jÃ¡ informado no formulÃ¡rio. O usuÃ¡rio vÃª o valor e nÃ£o o edita. Se a zona estiver errada, a correÃ§Ã£o Ã© no endereÃ§o.
- Preservar a pÃ¡gina vale para a paginaÃ§Ã£o da lista de manifestaÃ§Ãµes na mesma visita de trabalho. Fechar a visita e entrar de novo comeÃ§a na pÃ¡gina 1. NÃ£o se preserva a etapa dentro de uma manifestaÃ§Ã£o aberta.
- Quem tem acesso fica restrito Ã  pessoa nomeada, Romulo Gabriel Pinheiro Pereira, na conta de super administrador da AGEMAN, e nÃ£o a todo mundo que tenha um papel amplo.
- Esta entrega nÃ£o redesenha a ficha da manifestaÃ§Ã£o nem o conteÃºdo dos blocos do relatÃ³rio que jÃ¡ fecham, alÃ©m de fazer as trÃªs contas usarem o mesmo conjunto oficial e de tirar demonstraÃ§Ã£o e teste.
