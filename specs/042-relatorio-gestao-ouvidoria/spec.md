# Feature Specification: Relatório de Gestão da Ouvidoria

**Feature Branch**: `042-relatorio-gestao-ouvidoria`

**Created**: 2026-08-27

**Status**: Draft

**Input**: User description: "implementação da gestão e todos os relatórios que ainda não existem — a partir do banco de dados, substituindo o relatório de gestão que o cliente hoje monta à mão numa planilha Excel. Sem débito técnico, sem gambiarras, sem banco de dados gigantesco, evitar problemas comuns da v1."

## Clarifications

### Session 2026-08-27

- Q: As perguntas/indicadores da pesquisa de satisfação são um conjunto fixo (catálogo simples por tenant) ou configurável livremente pelo usuário final? → A: Catálogo fixo de perguntas por tenant (poucas linhas, cadastradas via seed/admin), igual à estrutura atual da planilha — não é um "form builder" configurável pelo usuário final.
- Q: O export em Excel deve replicar a estrutura de múltiplas abas com fórmulas/gráficos da planilha original, ou ser um arquivo mais simples/consolidado? → A: Arquivo consolidado e simples — uma aba por bloco do relatório, com os dados já agregados prontos, sem fórmulas nem gráficos nativos do Excel (evita recriar a planilha original).
- Q: Existe um limite de tempo aceitável para abrir o relatório/gerar export no pior caso ("acumulado geral" desde 2018)? → A: Sim — tela abre em até 5s, export completa em até 30s, mesmo no acumulado geral.
- Q: O bloco "quantitativo por tipo de reclamação/denúncia" deve usar a taxonomia já existente (`Manifestacao.type`) ou uma classificação nova equivalente à da planilha? → A: Usar a taxonomia já existente (`Manifestacao.type`) — sem criar categorização nova.
- Q: Se dois usuários editarem o lançamento de satisfação do mesmo mês/pergunta simultaneamente, "a última gravação vence" (sem trava) é aceitável? → A: Sim, aceitável — sem trava de conflito.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Visualizar o relatório de gestão da Ouvidoria no sistema (Priority: P1)

Como usuário com acesso ao módulo Ouvidoria, quero abrir um relatório de gestão dentro do próprio módulo Ouvidoria (sem depender do módulo Diretor) que reúna os indicadores que hoje só existem na planilha manual — demandas por mês/tipo/forma de atendimento, reclamações por zona e por bairro, quantitativo por tipo de manifestação, evolução da resolutividade e pesquisa de satisfação — para deixar de montar esse relatório à mão.

**Why this priority**: É o valor central do pedido do cliente — substituir o trabalho manual por uma tela que já existe no sistema, consumindo dados reais do banco.

**Independent Test**: Pode ser testado abrindo a tela do relatório de gestão para um tenant com dados de Ouvidoria carregados e confirmando que cada bloco (demandas, formas de atendimento, zona, bairro, tipo de manifestação, satisfação) aparece com números batendo com uma consulta direta ao banco para o mesmo período.

**Acceptance Scenarios**:

1. **Given** um tenant com manifestações registradas em diferentes meses, **When** o usuário abre o relatório de gestão e filtra por um período, **Then** os blocos de demandas, formas de atendimento e resolutividade exibem os números correspondentes a esse período, recalculados a partir do estado atual do banco.
2. **Given** manifestações com bairro e zona preenchidos, **When** o relatório exibe o bloco de reclamações por zona/bairro, **Then** os totais são agrupados corretamente por zona e por bairro, incluindo uma categoria "Não informado" para os registros sem esse dado preenchido.
3. **Given** um tenant sem nenhuma manifestação no período filtrado, **When** o usuário abre o relatório, **Then** o sistema exibe os blocos vazios com uma indicação clara de "sem dados no período", sem erro.

---

### User Story 2 - Registrar pesquisa de satisfação mensal (Priority: P1)

Como usuário com acesso ao módulo Ouvidoria, quero lançar manualmente os resultados mensais da pesquisa de satisfação (por pergunta/indicador), para que o relatório de gestão continue mostrando esse indicador depois que a planilha manual for descontinuada.

**Why this priority**: Sem uma forma de lançar esse dado no sistema, o bloco de satisfação do relatório fica congelado no histórico migrado (spec de migração) e nunca mais atualiza — quebra a promessa de "substituir a planilha".

**Independent Test**: Pode ser testado criando um lançamento de satisfação para o mês corrente e confirmando que ele aparece imediatamente no bloco de satisfação do relatório de gestão.

**Acceptance Scenarios**:

1. **Given** um usuário autorizado no módulo Ouvidoria, **When** ele lança os valores de satisfação de um mês/pergunta que ainda não tem registro, **Then** o sistema salva o lançamento e ele passa a aparecer no relatório de gestão para aquele mês.
2. **Given** um mês que já tem lançamento de satisfação, **When** o usuário tenta lançar novamente o mesmo mês/pergunta, **Then** o sistema impede duplicidade (edita o existente ou bloqueia com mensagem clara, a critério da modelagem).

---

### User Story 3 - Exportar o relatório de gestão (Priority: P2)

Como usuário com acesso ao módulo Ouvidoria, quero exportar o relatório de gestão em PDF e em Excel, para arquivar/enviar por e-mail (PDF) ou continuar conferindo/analisando os números fora do sistema (Excel), como o cliente faz hoje.

**Why this priority**: É o formato final que o cliente efetivamente usa para "entregar" o relatório de gestão — sem export, o valor de negócio do pedido original não está completo, mas a visualização em tela (História 1) já entrega valor por si só.

**Independent Test**: Pode ser testado gerando os dois exports para um período com dados e confirmando que os números em cada arquivo conferem com os exibidos na tela do relatório para o mesmo período.

**Acceptance Scenarios**:

1. **Given** o relatório de gestão aberto para um período, **When** o usuário solicita exportação em PDF, **Then** recebe um arquivo com todos os blocos do relatório (KPIs, gráficos, tabelas) formatados para leitura/impressão.
2. **Given** o relatório de gestão aberto para um período, **When** o usuário solicita exportação em Excel, **Then** recebe um arquivo com os dados tabulares dos blocos do relatório, permitindo conferência/análise adicional.

---

### User Story 4 - Enriquecer o quantitativo por tipo de manifestação (Priority: P3)

Como usuário com acesso ao módulo Ouvidoria, quero ver a quebra de manifestações por tipo (usando a taxonomia já existente no sistema — reclamação, solicitação, denúncia, elogio, sugestão, simplifique) dentro do relatório de gestão, complementando a visão por motivo/concessionária que já existe no painel atual.

**Why this priority**: É um refinamento sobre uma agregação parcialmente existente (`porMotivo`) — agrega valor, mas o sistema já mostra uma visão equivalente hoje; a prioridade menor reflete que não é um bloco totalmente ausente como zona/bairro/satisfação.

**Independent Test**: Pode ser testado comparando a quebra por tipo exibida no relatório com uma contagem manual de manifestações agrupadas pelo mesmo critério para um período de referência.

**Acceptance Scenarios**:

1. **Given** manifestações de diferentes tipos num período, **When** o relatório exibe o bloco de quantitativo por tipo, **Then** os totais por tipo conferem com uma contagem direta das manifestações desse período.

---

### Edge Cases

- O que acontece quando o usuário filtra um período anterior a qualquer dado migrado (ex. antes de 2018)? O relatório mostra zero/vazio, sem erro.
- O que acontece se um usuário sem o módulo Ouvidoria habilitado tentar acessar o relatório? Acesso deve ser bloqueado como qualquer outra tela do módulo.
- O que acontece se o volume de manifestações no período filtrado for muito grande (ex. o "acumulado geral desde 2018")? O relatório MUST abrir em até 5s e o export MUST completar em até 30s mesmo nesse cenário, sem exigir pré-cálculo/duplicação de dados como solução padrão.
- O que acontece se o usuário exportar o relatório e, no meio do processo, novos dados forem lançados no sistema? O export reflete o estado do banco no momento da geração (sem necessidade de trava/lock).
- O que acontece se um lançamento de pesquisa de satisfação for feito para um mês que também tem dado migrado da planilha histórica (spec de migração)? A modelagem deve deixar claro qual registro prevalece (não pode haver dois valores conflitantes para o mesmo mês/pergunta sem explicação).
- O que acontece se dois usuários editarem o mesmo lançamento de satisfação (mesmo mês/pergunta) simultaneamente? A última gravação prevalece ("last write wins"); não há trava de conflito nem aviso de concorrência.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: O sistema MUST exibir, dentro do módulo Ouvidoria (não do módulo Diretor), um relatório de gestão que reúna: demandas por mês, formas de atendimento, demandas por tipo de concessão, evolução da resolutividade, quantitativo por tipo de manifestação (usando a taxonomia já existente `Manifestacao.type`, sem criar categorização nova), reclamações por zona, reclamações por bairro e pesquisa de satisfação.
- **FR-002**: O relatório MUST ser genérico por tenant — qualquer tenant com o módulo Ouvidoria habilitado MUST poder acessá-lo, não apenas o tenant AGEMAN.
- **FR-003**: Todos os blocos do relatório MUST ser recalculados a partir do estado atual do banco de dados a cada acesso (sem snapshot congelado/fechamento mensal).
- **FR-004**: O bloco de reclamações por zona e por bairro MUST agrupar manifestações sem esse dado preenchido numa categoria "Não informado", sem excluí-las do total geral.
- **FR-005**: O sistema MUST fornecer uma tela de lançamento manual (criar/editar) para os agregados mensais de pesquisa de satisfação (mês, ano, pergunta/indicador, valor), para uso contínuo após a planilha manual ser descontinuada. As perguntas/indicadores disponíveis MUST vir de um catálogo fixo por tenant (poucas linhas, cadastradas via seed/admin) — o usuário final NÃO pode criar ou remover perguntas livremente pela UI.
- **FR-006**: O sistema MUST impedir lançamento duplicado de satisfação para a mesma combinação mês/ano/pergunta/tenant (edição do existente em vez de duplicar).
- **FR-007**: O bloco de orientações/encaminhamentos do relatório MUST ser derivado exclusivamente de dados de encaminhamento já existentes vinculados a manifestações (não requer nova entidade nem tela de lançamento avulso).
- **FR-008**: O sistema MUST oferecer um KPI de "acumulado geral" (sem filtro de ano), além dos KPIs filtráveis por ano/mês já existentes no painel atual.
- **FR-009**: O sistema MUST permitir exportar o relatório de gestão em formato PDF, com todos os blocos formatados para leitura/impressão.
- **FR-010**: O sistema MUST permitir exportar o relatório de gestão em formato Excel, com os dados tabulares dos blocos para conferência/análise adicional. O arquivo MUST ser consolidado e simples — uma aba por bloco do relatório, com valores já agregados/calculados; o arquivo MUST NOT replicar fórmulas nem gráficos nativos do Excel, nem a estrutura de 20 abas da planilha original.
- **FR-011**: O acesso ao relatório de gestão MUST seguir a mesma regra de autorização já usada para as demais telas do módulo Ouvidoria (qualquer usuário com o módulo habilitado, sem exigir papel gerencial adicional).
- **FR-012**: A funcionalidade "Participação em Eventos" presente na planilha original MUST permanecer fora de escopo (não é implementada nesta feature).
- **FR-013**: Nenhuma agregação nova MUST introduzir tabelas de cache/pré-cálculo persistentes como solução padrão — otimizações de performance, se necessárias, MUST ser tratadas na fase de planejamento técnico (`/speckit-plan`), priorizando índices e consultas eficientes antes de duplicar dados.

### Key Entities *(include if feature involves data)*

- **Agregado Mensal de Pesquisa de Satisfação**: mesma entidade descrita na spec de migração histórica (041); esta feature adiciona a capacidade de criar/editar esses agregados diretamente no sistema, para os meses correntes e futuros. A pergunta/indicador referenciada MUST pertencer a um catálogo fixo por tenant (não configurável livremente pelo usuário final).
- **Relatório de Gestão (visão consolidada)**: não é uma entidade persistida — é uma composição, em tempo de consulta, de dados já existentes (`Manifestacao`, `Address`, catálogos de forma de atendimento/concessionária) mais o novo agregado de satisfação.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Um usuário do módulo Ouvidoria consegue obter, em uma única tela, todos os blocos que hoje exigem montagem manual na planilha, sem precisar consultar nenhuma outra fonte.
- **SC-002**: O tempo para "fechar" o relatório de gestão mensal (hoje feito à mão, levando horas) cai para o tempo de abrir a tela e exportar o arquivo.
- **SC-003**: Os números de qualquer bloco do relatório conferem com uma consulta direta ao banco de dados para o mesmo período, sem divergência.
- **SC-004**: O relatório funciona igualmente para qualquer tenant com o módulo Ouvidoria habilitado, não apenas para o tenant de origem deste pedido (AGEMAN).
- **SC-005**: A tela do relatório abre em até 5 segundos e a exportação em PDF/Excel completa em até 30 segundos, mesmo para o período "acumulado geral" (maior volume de dados possível).
- **SC-006**: Revisão técnica confirma que nenhuma nova tabela de cache/duplicação de dados foi criada sem justificativa explícita de performance documentada no plano técnico.

## Assumptions

- Esta feature depende dos dados históricos de satisfação e orientações vinculadas terem sido migrados pela spec "041 — Migração de Dados Históricos da Ouvidoria (2018–2023)"; para tenants/períodos sem essa migração, os blocos correspondentes simplesmente aparecem vazios (sem erro).
- "Participação em Eventos" está definitivamente fora de escopo — mesma decisão de produto da spec de migração.
- O módulo Diretor (visão executiva AGEMAN) não é alterado por esta feature; o relatório de gestão vive inteiramente dentro do módulo Ouvidoria.
- Dados de 2024 em diante que não vieram da migração histórica (041) são considerados corretos como já estão no banco (operação normal do sistema) ou serão completados via o lançamento manual de satisfação introduzido por esta feature.
- Qualquer usuário com o módulo Ouvidoria habilitado pode ver e gerar o relatório — não há um novo nível de permissão "gerencial" introduzido por esta feature.
