# Feature Specification: Matriz Concessão × Desfecho e Ajustes de Status/Encerramento — Relatório de Gestão (AGEMAN)

**Feature Branch**: `052-matriz-concessao-desfecho-ageman`

**Created**: 2026-09-28

**Status**: Draft

**Input**: User description: "Gap AGEMAN pós-uso (feedback WhatsApp, ago/2026) — 3 pontos: 1. Matriz \"Concessão × Desfecho\" no relatório de gestão (Coleta de Lixo/Estacionamento Rotativo/Água-Esgoto/Transporte Coletivo/Iluminação Pública × Resolvida/Jurídico/Pendente), espelhando a aba DEMANDAS_EMITIDAS CONC. da planilha AGEMAN — hoje fora de escopo de 050-tipo-concessao e 050-serie-historica. 2. Filtro/drill-down por tipo de concessão na lista de demandas (ex.: ver só demandas de água). 3. Ajuste no encerramento: remover \"Pendente\" de MANIFESTACAO_DESFECHO_ENCERRAMENTO no modal Encerrar — ao encerrar, só \"Resolvida pela AGEMAN\" ou \"Meio Jurídico\" (ambos contam como resolvido). \"Pendente\" deixa de ser desfecho de encerramento. 4. Renomear/reclassificar o status pré-demanda \"Em análise\" (in_review) para \"Pendente\" — a análise ocorre na solicitação, antes de virar demanda oficial. Atenção à colisão de nome com o \"pendente\" removido do item 3 — precisa distinguir status de workflow vs desfecho."

**Relacionamento**: Gap adicional identificado pós-uso real do relatório de gestão (spec [042](../042-relatorio-gestao-ouvidoria/spec.md)) e dos ajustes das specs [049](../049-ajustes-relatorio-gestao-ouvidoria/spec.md)/050 — feedback direto da AGEMAN (WhatsApp, análise das demandas de agosto/2026 comparando relatório exportado com planilha manual). Complementa, sem substituir, as specs [050-relatorio-gestao-tipo-concessao-ageman](../050-relatorio-gestao-tipo-concessao-ageman/spec.md) e [050-relatorio-gestao-desfecho-ageman](../050-relatorio-gestao-desfecho-ageman/spec.md), que documentam explicitamente esta matriz como fora de escopo (ver [coordination-orquestrador-gap3.md](../050-relatorio-gestao-tipo-concessao-ageman/coordination-orquestrador-gap3.md): *"Matriz desfecho×concessão, se existir, é outra spec/entrega"*).

## Clarifications

### Session 2026-09-28

- Q: O que a coluna "Pendente" da matriz Concessão × Desfecho (User Story 1) deve contar, já que hoje o código distingue duas coisas diferentes — demandas encerradas com o desfecho legado "pendente" (`closed_unresolved`, removido pela User Story 2) vs. demandas ainda não encerradas (abertas/em análise/tramitando)? → A: Demandas ainda NÃO encerradas — mesmo conceito de "não finalizadas" já usado no bloco `demandasPendentes` do dashboard hoje; a coluna é sempre recalculada a partir do status atual, nunca um valor "travado" ou histórico.
- Q: Com "Pendente" saindo do encerramento (User Story 2), o que fazer com as demandas HISTÓRICAS já encerradas com esse desfecho (status `closed_unresolved`) na matriz e nos relatórios? → A: Continuam contadas, mas em bucket próprio e visualmente distinto — não se misturam com a coluna "Pendente" (que agora significa "aberta", conceito diferente de "encerrada como pendente"); não recebem novas entradas dali em diante.
- Q: O rename "Em análise" → "Pendente" (User Story 3, status pré-demanda) vale para todos os tenants do módulo Ouvidoria ou só para AGEMAN? → A: Todos os tenants — é correção de vocabulário do produto, não uma regra específica de um cliente.
- Q: O filtro por tipo de concessão na lista de demandas (User Story 4) aparece para todos os tenants ou só para quem tem catálogo de concessões cadastrado? → A: Só para tenants com catálogo de tipos de concessão cadastrado — oculto/sem efeito para os demais, mesmo padrão condicional já usado em outros filtros dependentes de catálogo.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Ver a matriz Concessão × Desfecho no relatório de gestão (Priority: P1)

Como usuário do módulo Ouvidoria (AGEMAN), quero ver no relatório de gestão uma tabela cruzando cada tipo de concessão (Água/Saneamento, Transporte Coletivo, Iluminação Pública, Coleta de Lixo, Estacionamento Rotativo (Zona Azul)) com quatro colunas — Resolvida pela AGEMAN, Meio Jurídico, Pendente (demandas daquele tipo ainda não encerradas) e Pendente (desfecho) — no período filtrado, para comparar diretamente com a planilha manual sem precisar montar essa contagem à mão.

**Why this priority**: É o núcleo do feedback do cliente (print da planilha "ACOMPANHAMENTO DE MASSA DE DEMANDAS") e a única visão que falta para o relatório substituir de fato a planilha nesse ponto — sem ela, a AGEMAN continua conferindo manualmente.

**Independent Test**: Para um mês/ano fixo, somar a linha de uma concessão (Resolvida + Jurídico + Pendente) e comparar com o total de demandas daquela concessão no mesmo período; comparar célula a célula com uma contagem manual/SQL agrupada por concessão × desfecho.

**Acceptance Scenarios**:

1. **Given** demandas com concessão e desfecho conhecidos, **When** o usuário abre o bloco no relatório, **Then** vê uma linha por tipo de concessão com colunas Resolvida/Jurídico/Pendente/Pendente (desfecho) e o total da linha.
2. **Given** um tipo de concessão sem nenhuma demanda no período, **When** a tabela é exibida, **Then** a linha aparece com zeros em todas as colunas, sem erro nem omissão da linha.
3. **Given** export PDF ou Excel do relatório, **When** o usuário exporta, **Then** a mesma tabela aparece com os mesmos números exibidos em tela.

---

### User Story 2 - Encerrar demanda apenas com desfecho resolutivo (Priority: P1)

Como operador que encerra uma demanda, quero que a tela de encerramento ofereça somente "Resolvida pela AGEMAN" e "Meio Jurídico" como desfecho, para que toda demanda encerrada tenha, de fato, uma resolução registrada — hoje a tela oferece um terceiro botão "Pendente" que não faz sentido no momento de encerrar algo (encerrar como "pendente" é contraditório).

**Why this priority**: Bug de UX apontado diretamente pelo cliente; uma demanda encerrada como "pendente" gera dado contraditório e prejudica a confiabilidade da própria matriz da User Story 1.

**Independent Test**: Abrir o modal de encerramento de uma demanda e confirmar que apenas as 2 opções resolutivas aparecem; confirmar que o encerramento exige a escolha de uma delas.

**Acceptance Scenarios**:

1. **Given** uma demanda em tramitação, **When** o operador abre a tela de encerramento, **Then** vê somente as opções "Resolvida pela AGEMAN" e "Meio Jurídico" como desfecho.
2. **Given** uma demanda encerrada antes desta feature com desfecho "Pendente" (dado legado), **When** o relatório ou a matriz da User Story 1 exibe essa demanda, **Then** ela continua sendo contabilizada normalmente, sem quebrar totais ou gerar erro.

---

### User Story 3 - Status "Pendente" consistente antes de virar demanda (Priority: P2)

Como usuário da Ouvidoria, quero que o status usado enquanto uma solicitação aguarda análise para se tornar (ou não) uma demanda oficial se chame "Pendente" (em vez de "Em análise"), para que o vocabulário do sistema reflita o processo real da AGEMAN: a análise ocorre antes de a demanda existir, então uma demanda já criada nunca deveria aparecer como "em análise".

**Why this priority**: Alinhamento de vocabulário pedido explicitamente pelo cliente; prioridade menor que as User Stories 1 e 2 porque é renomeação/reclassificação de rótulo, não uma correção que afeta a integridade dos números do relatório.

**Independent Test**: Criar uma solicitação nova e confirmar que ela aparece como "Pendente" antes de virar demanda; confirmar que esse "Pendente" de pré-demanda nunca aparece como rótulo de uma demanda já formalizada, evitando colisão de sentido com o desfecho "Pendente" removido na User Story 2.

**Acceptance Scenarios**:

1. **Given** uma solicitação recém-criada aguardando análise, **When** o usuário vê a lista, **Then** o status exibido é "Pendente".
2. **Given** uma demanda já formalizada (passou da fase de solicitação), **When** o usuário vê seu status, **Then** ela nunca aparece com o rótulo "Pendente" de pré-análise — segue os status de workflow normais (tramitando, respondida, encerrada).

---

### User Story 4 - Filtrar a lista de demandas por tipo de concessão (Priority: P2)

Como usuário do módulo Ouvidoria, quero filtrar a lista de demandas por tipo de concessão (ex.: só Água/Saneamento), para conferir manualmente quais demandas específicas compõem um total exibido no relatório ou na matriz — hoje só é possível ver o total agregado, sem chegar à lista de demandas por trás dele.

**Why this priority**: Item explícito do feedback do cliente ("não tem no relatório a opção pra ver quais são as demandas só de água"); prioridade menor que a matriz em si porque é um complemento de navegação/conferência, não o dado agregado principal.

**Independent Test**: Aplicar o filtro de concessão na lista de demandas e confirmar que a contagem de resultados bate com o total daquela concessão no relatório/matriz do mesmo período.

**Acceptance Scenarios**:

1. **Given** a lista de demandas, **When** o usuário seleciona um tipo de concessão no filtro, **Then** somente demandas daquele tipo aparecem na lista.
2. **Given** o filtro de concessão combinado com os filtros já existentes (status, período), **When** aplicados juntos, **Then** o resultado respeita todos os filtros simultaneamente.

---

### Edge Cases

- Demandas com concessão desconhecida/não mapeada entram na matriz como "Não informado", em vez de somar em nenhuma linha existente ou desaparecer.
- Demandas encerradas antes desta feature com o desfecho legado "Pendente" (status `closed_unresolved`, dado histórico) permanecem visíveis no histórico e nos relatórios, contadas num bucket próprio e visualmente distinto da coluna "Pendente" da matriz (que passa a significar "ainda não encerrada") — sem reclassificação automática e sem novas entradas nesse bucket a partir desta feature (ver Assumptions).
- Uma solicitação pode ser rejeitada antes de virar demanda — esse fluxo de decisão não muda nesta feature, apenas o rótulo do status intermediário de espera.
- Filtro de concessão sem nenhum resultado no período exibe lista vazia com indicação clara de "sem dados", mesmo padrão dos demais filtros já existentes.
- Tentativa de encerrar uma demanda sem escolher um dos dois desfechos disponíveis (User Story 2) é bloqueada, com mensagem clara indicando a escolha obrigatória.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: O relatório de gestão MUST exibir uma tabela cruzando tipo de concessão × quatro colunas — "Resolvida pela AGEMAN", "Meio Jurídico", "Pendente" e "Pendente (desfecho)" (bucket legado, ver FR-004) — com total por linha, para o período filtrado (mês/ano ou acumulado geral).
- **FR-001a**: A coluna "Pendente" da tabela FR-001 MUST representar demandas daquele tipo de concessão que ainda NÃO foram encerradas (status aberto/aguardando análise, tramitando ou aguardando fechamento) — recalculada sempre a partir do status atual, nunca um valor histórico travado.
- **FR-002**: A tabela MUST incluir todos os tipos de concessão conhecidos do tenant, mesmo quando o total no período for zero para algum deles.
- **FR-003**: A tela de encerramento de demandas MUST oferecer apenas os desfechos "Resolvida pela AGEMAN" e "Meio Jurídico"; a opção "Pendente" MUST NOT aparecer como desfecho de encerramento a partir desta feature.
- **FR-004**: Demandas já encerradas anteriormente com o desfecho legado "Pendente" MUST continuar sendo exibidas e contabilizadas em relatórios e histórico sem erro, em uma coluna própria da tabela FR-001 rotulada "Pendente (desfecho)" — mesmo texto já usado hoje no filtro de status da lista de demandas para o mesmo status `closed_unresolved` (sem introduzir um terceiro rótulo para o mesmo conceito) — visualmente distinta da coluna "Pendente" da FR-001a (que passa a significar "ainda não encerrada") — sem receber novas entradas a partir desta feature.
- **FR-005**: O status usado para solicitações que aguardam análise antes de se tornarem demanda MUST ser rotulado "Pendente" em vez de "Em análise", para todos os tenants do módulo Ouvidoria.
- **FR-006**: Uma demanda já formalizada (que passou da fase de solicitação) MUST NOT usar o status "Pendente" de pré-análise da FR-005 — os três conceitos hoje potencialmente confundíveis sob o rótulo "pendente" (pré-demanda da FR-005, coluna "ainda não encerrada" da FR-001a, e o bucket legado da FR-004) MUST permanecer distinguíveis, sem ambiguidade de rótulo, em qualquer tela ou relatório onde apareçam.
- **FR-007**: A lista de demandas MUST oferecer um filtro por tipo de concessão, combinável com os filtros já existentes (status, período), visível apenas para tenants com catálogo de tipos de concessão cadastrado.
- **FR-008**: As exportações em PDF e Excel do relatório de gestão MUST incluir a tabela concessão × desfecho (FR-001) com os mesmos valores exibidos em tela.
- **FR-009**: Nenhuma agregação introduzida por esta feature MUST depender de tabela de cache/pré-cálculo persistente (mesma restrição herdada das specs 042/049/050).

### Key Entities *(include if feature involves data)*

- **Matriz Concessão × Desfecho**: não é uma entidade persistida — composição em tempo de consulta das demandas já existentes, agrupadas por tipo de concessão e por quatro colunas: "Resolvida pela AGEMAN" e "Meio Jurídico" (demandas encerradas com esses desfechos), "Pendente" (demandas ainda não encerradas, ver FR-001a) e "Pendente (desfecho)" (bucket legado, ver FR-004), no período filtrado.
- **Desfecho de Encerramento**: valor já existente hoje com três opções (Resolvida pela AGEMAN, Meio Jurídico, Pendente); esta feature restringe as opções disponíveis para *novos* encerramentos a apenas duas (Resolvida pela AGEMAN, Meio Jurídico). O valor legado "Pendente" persistido em encerramentos anteriores não é alterado, mas passa a ser contabilizado separadamente da coluna "Pendente" da matriz (ver FR-004).
- **Status de pré-demanda ("Pendente")**: novo rótulo, para todos os tenants, do status hoje chamado "Em análise", usado enquanto uma solicitação aguarda decisão sobre se vira ou não uma demanda oficial — conceito distinto tanto do desfecho de encerramento quanto da coluna "Pendente" da matriz (ver FR-006).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A tabela concessão × desfecho do relatório confere exatamente com uma contagem manual/direta das demandas do mesmo período, agrupadas pelos mesmos critérios.
- **SC-002**: Nenhuma demanda nova pode ser encerrada com desfecho "Pendente" após esta feature entrar em produção.
- **SC-003**: Um usuário consegue filtrar a lista de demandas por tipo de concessão e obter uma contagem que bate exatamente com o total exibido no relatório/matriz para o mesmo período.
- **SC-004**: O relatório completo (tela e exports) mantém os mesmos limites de performance já estabelecidos nas specs anteriores (≤ 5s tela, ≤ 30s export), mesmo com a nova tabela.

## Assumptions

- Demandas legadas com desfecho "Pendente" (persistidas antes desta feature) não são migradas ou reclassificadas automaticamente por esta feature — permanecem no histórico e nos relatórios, contabilizadas num bucket próprio distinto da coluna "Pendente" da matriz (FR-004); uma eventual reclassificação manual é decisão operacional futura, fora deste escopo.
- O status de pré-demanda ("Pendente" após o rename da FR-005), a coluna "Pendente" da matriz (demandas ainda não encerradas, FR-001a) e o desfecho legado "Pendente" de encerramento (FR-004) são três conceitos distintos que compartilham o mesmo rótulo textual — a UI e os relatórios MUST deixar essa distinção clara pelo contexto (tela de solicitação vs. matriz de desfecho vs. histórico legado), sem introduzir três palavras diferentes só para desambiguar.
- Os tipos canônicos de concessão usados na matriz (User Story 1) são os mesmos já adotados no bloco "Tipo de concessão" (spec [050-tipo-concessao-ageman](../050-relatorio-gestao-tipo-concessao-ageman/spec.md)): Água/Saneamento, Transporte Coletivo, Iluminação Pública, Coleta de Lixo, Estacionamento Rotativo (Zona Azul) — este último rótulo reaproveita o texto já usado em `AGEMAN_TIPO_MANIFESTACAO_OPTIONS` (gráfico "Manifestações por Motivo" existente), único ponto do código atual que já unificava as duas grafias ("Zona Azul" no SQL legado, "Estacionamento Rotativo" no catálogo de motivos) — ver `research.md` §5 para o levantamento completo da divergência encontrada.
- Esta feature não altera o fluxo de decisão de transformar (ou não) uma solicitação em demanda — apenas o rótulo do status intermediário de espera.
- Todos os tenants (não só AGEMAN) que usam o mesmo fluxo de encerramento e status são afetados pelas User Stories 2 e 3; o filtro por concessão (User Story 4) só aparece para tenants com catálogo de tipos de concessão cadastrado (FR-007).

## Out of Scope

- Migração ou reclassificação retroativa de demandas com desfecho "Pendente" legado.
- Qualquer alteração na tabela mês×ano de série histórica (spec [050-serie-historica-ageman](../050-relatorio-gestao-serie-historica-ageman/spec.md)).
- Alteração do módulo Diretor.
- Alteração do fluxo de decisão solicitação→demanda além do rótulo do status intermediário.
