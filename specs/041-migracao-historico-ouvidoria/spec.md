# Feature Specification: Migração de Dados Históricos da Ouvidoria (2018–2023)

**Feature Branch**: `041-migracao-historico-ouvidoria`

**Created**: 2026-08-27

**Status**: Draft

**Input**: User description: "migração de dados que não existem ainda desde 2018 da planilha 'PLANILHAS OUVIDORIA AGEMAN - 2026 - 06 e Consolidado.xlsx' — pesquisa de satisfação e orientações/encaminhamentos históricos que ainda não existem no banco de dados. Sem débito técnico, sem gambiarras, sem banco de dados gigantesco, evitar problemas comuns da v1."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Disponibilizar histórico de pesquisa de satisfação (Priority: P1)

Como gestor da Ouvidoria, quero que os resultados mensais da pesquisa de satisfação de 2018 a 2023 (hoje só existentes na planilha manual) estejam disponíveis no sistema, para que o relatório de gestão da Ouvidoria (spec de implementação em paralelo) possa exibi-los sem depender da planilha.

**Why this priority**: Sem esse dado migrado, o novo módulo de relatório não tem o que mostrar para os anos anteriores — é a base de tudo que a spec de implementação vai consumir.

**Independent Test**: Pode ser testado consultando os agregados mensais de satisfação migrados (por ano/mês/pergunta) e comparando com os valores da planilha original para o mesmo período, sem depender de nenhuma tela nova.

**Acceptance Scenarios**:

1. **Given** a aba "PESQUISA DE SATISFAÇÃO" da planilha com médias mensais por pergunta entre 01/2018 e 12/2023, **When** a migração é executada, **Then** cada agregado mensal (ano, mês, pergunta/indicador, valor médio) fica persistido no sistema, associado ao tenant AGEMAN.
2. **Given** um mês sem pesquisa registrada na planilha (célula vazia), **When** a migração processa esse mês, **Then** nenhum registro é criado para ele e ele não aparece como erro no relatório de exceções (ausência de dado é esperada, não é uma falha).

---

### User Story 2 - Vincular orientações/encaminhamentos históricos a manifestações existentes (Priority: P1)

Como gestor da Ouvidoria, quero que as orientações diversas e encaminhamentos para concessionárias registrados na planilha (2018–2023) sejam associados às manifestações (demandas) que já existem no banco, para enriquecer o histórico de acompanhamento por concessionária sem criar uma tabela solta desconectada do restante do domínio.

**Why this priority**: É o segundo maior bloco de dado histórico ausente e o que carrega mais risco de gerar modelagem solta/duplicada se malfeito — por isso tem a mesma prioridade da satisfação.

**Independent Test**: Pode ser testado escolhendo uma amostra de linhas da aba "ORIENTAÇÕES_ENCAMINH." com data e identificador (protocolo) reconhecíveis e confirmando que, após a migração, a manifestação correspondente no banco passa a refletir esse enriquecimento histórico.

**Acceptance Scenarios**:

1. **Given** uma linha de orientação com data e protocolo que correspondem exatamente a uma única `Manifestacao` já existente no banco, **When** a migração é executada, **Then** o registro histórico é vinculado a essa manifestação.
2. **Given** uma linha de orientação sem correspondência exata (nenhuma manifestação com data/protocolo compatível, ou mais de uma manifestação candidata), **When** a migração é executada, **Then** essa linha **não** é migrada como registro independente — ela é listada no relatório de exceções com o motivo da não-migração.

---

### User Story 3 - Revisar exceções de migração (Priority: P2)

Como responsável técnico pela migração, quero um relatório de exceções listando toda linha de origem (satisfação ou orientação) que não pôde ser migrada automaticamente, para revisar manualmente antes de considerar a planilha "aposentada".

**Why this priority**: Sustenta a confiabilidade das Histórias 1 e 2 (migração por melhor esforço), mas não é o dado em si — é a rede de segurança que evita perda silenciosa de informação.

**Independent Test**: Pode ser testado rodando a migração sobre um conjunto de dados com inconsistências propositais (célula de fórmula quebrada, orientação sem correspondência) e confirmando que cada uma aparece no relatório de exceções com um motivo claro.

**Acceptance Scenarios**:

1. **Given** uma célula com erro de fórmula (`#REF!`) na área de dados migrados, **When** a migração processa essa célula, **Then** ela é registrada no relatório de exceções com o motivo "fórmula com erro na origem", sem interromper o restante da migração.
2. **Given** o relatório de exceções gerado, **When** um responsável técnico o lê, **Then** ele entende, para cada item, o motivo da não-migração sem precisar reabrir a planilha original.

---

### User Story 4 - Confirmar integridade do período migrado (Priority: P3)

Como responsável técnico, quero comparar os totais migrados (satisfação por mês, orientações vinculadas) com os totais mostrados na planilha original para 2018–2023, para ter confiança de que a migração está correta antes de a planilha manual deixar de ser usada.

**Why this priority**: É uma validação de fechamento, útil mas não bloqueante para o valor entregue pelas Histórias 1–3.

**Independent Test**: Pode ser testado gerando uma contagem simples (nº de agregados de satisfação migrados, nº de orientações vinculadas) e comparando manualmente com a planilha, sem depender de nenhuma tela nova do sistema.

**Acceptance Scenarios**:

1. **Given** a migração concluída, **When** o total de meses com satisfação migrada é comparado com o total de meses preenchidos na planilha (2018–2023), **Then** os números conferem (ou a diferença está explicada no relatório de exceções).

---

### Edge Cases

- O que acontece se a mesma linha de origem for processada duas vezes (reexecução acidental da migração)? O sistema não deve criar duplicados.
- O que acontece se uma linha de orientação tiver data compatível com **mais de uma** manifestação (ambiguidade)? Deve ser tratada como não-conciliada e reportada, não vinculada "no palpite".
- O que acontece se a planilha mencionar uma concessionária/motivo que não corresponde a nenhum catálogo atual do tenant? O item é reportado no relatório de exceções, não inventa um novo valor de catálogo automaticamente.
- O que acontece com pesquisas de satisfação referentes a perguntas que não existem mais na formulação atual (a planilha mudou de formato ao longo dos anos)? O item é reportado e mantido fora do agregado padrão até revisão humana.
- O que acontece se o período 2018–2023 tiver meses fora da faixa (ex. dado residual de 2024 na mesma aba)? Esse dado é ignorado por esta migração — está fora do escopo temporal definido (2024 em diante é tratado na spec de implementação, via lançamento manual).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: A migração MUST importar os agregados mensais de pesquisa de satisfação (ano, mês, pergunta/indicador) exclusivamente para o período 01/2018–12/2023, a partir da planilha "PLANILHAS OUVIDORIA AGEMAN - 2026 - 06 e Consolidado.xlsx", persistindo no modelo de contagens Sim/Não (`consultados?`, `respostasSim`, `respostasNao`) introduzido pela spec [049-ajustes-relatorio-gestao-ouvidoria](../049-ajustes-relatorio-gestao-ouvidoria/spec.md) — **não** mais no campo único "valor" (0–10) da spec 042 original, que foi removido do schema. Como a planilha histórica só traz o percentual/valor médio já agregado por mês (sem as contagens brutas de Sim/Não), a estratégia exata de reconciliação (ex.: manter só o percentual e marcar `consultados`/`respostasSim`/`respostasNao` como indisponíveis vs. estimar contagens a partir do percentual) MUST ser definida no `/speckit-plan` desta spec 041, e não está decidida neste documento.
- **FR-002**: A migração MUST NOT importar respostas individuais de pesquisa de satisfação — apenas os valores já agregados por mês/pergunta, pois é o único nível de detalhe disponível na origem. Isso é ortogonal à mudança de FR-001: o dado de origem continua agregado; o que muda é apenas o formato de destino no banco (contagens Sim/Não em vez de um valor médio único).
- **FR-003**: A migração MUST vincular cada linha histórica de orientação/encaminhamento (01/2018–12/2023) a uma `Manifestacao` existente somente quando houver correspondência exata e não-ambígua (ex. combinação de data + protocolo/identificador).
- **FR-004**: A migração MUST NOT criar registros de orientação/encaminhamento como entidades independentes sem vínculo a uma manifestação — linhas sem correspondência exata são descartadas da persistência (não migradas).
- **FR-005**: A migração MUST gerar um relatório de exceções contendo toda linha de origem (satisfação ou orientação) que não foi migrada, com o motivo específico (ex. "sem manifestação correspondente", "correspondência ambígua", "erro de fórmula na origem", "fora do período 2018–2023").
- **FR-006**: A migração MUST ser seguro contra reexecução — processar a mesma origem mais de uma vez não deve duplicar nenhum registro já migrado.
- **FR-007**: A migração MUST restringir-se ao período 2018–2023; dados de 2024 em diante são explicitamente fora de escopo desta feature.
- **FR-008**: A migração MUST NOT introduzir uma modelagem de dados que espelhe a estrutura larga/desnormalizada de colunas da planilha de origem — a persistência de qualquer dado novo (ex. satisfação) MUST seguir modelagem relacional normalizada, consistente com o restante do domínio Ouvidoria.
- **FR-009**: O processo de migração MUST ser executável e auditável por um responsável técnico sem depender de conhecimento tácito de quem o desenvolveu (passos e decisões documentados).
- **FR-010**: A funcionalidade "Participação em Eventos" presente na planilha MUST ficar fora do escopo desta migração (não é migrada, não gera nenhuma entidade nova).

### Key Entities *(include if feature involves data)*

- **Agregado Mensal de Pesquisa de Satisfação**: representa o resultado consolidado de um mês/pergunta da pesquisa de satisfação (tenant, ano, mês, indicador/pergunta). Desde a spec 049, o campo de destino é o modelo de contagens `consultados?`/`respostasSim`/`respostasNao` (percentual derivado em leitura, não persistido) — não mais um "valor médio ou percentual" único. Não representa respostas individuais.
- **Vínculo Histórico de Orientação/Encaminhamento**: representa o enriquecimento de uma `Manifestacao` já existente com o dado histórico de orientação/encaminhamento presente na planilha (concessionária, data do encaminhamento, situação). Não é uma entidade autônoma — só existe associada a uma manifestação.
- **Relatório de Exceções de Migração**: lista de itens de origem que não foram migrados, com motivo. É um artefato de auditoria da execução, não um dado de produto consumido pelos usuários finais da Ouvidoria.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% dos meses com dado de satisfação preenchido na planilha entre 2018 e 2023 estão disponíveis no sistema após a migração, ou têm um motivo documentado de exclusão.
- **SC-002**: 100% das linhas de orientação/encaminhamento (2018–2023) foram processadas: cada uma está vinculada a uma manifestação existente ou aparece no relatório de exceções com motivo.
- **SC-003**: Um responsável técnico consegue, a partir apenas do relatório de exceções, entender o motivo de cada item não migrado, sem reabrir a planilha original.
- **SC-004**: Reexecutar a migração sobre a mesma origem não altera a contagem de registros já migrados (zero duplicação).
- **SC-005**: Revisão técnica do modelo de dados criado confirma ausência de tabelas largas/desnormalizadas espelhando a planilha — nenhuma tabela nova tem finalidade única de "guardar uma aba do Excel".

## Assumptions

- **[2026-09-21]** A spec [049-ajustes-relatorio-gestao-ouvidoria](../049-ajustes-relatorio-gestao-ouvidoria/spec.md) alterou o schema de destino da pesquisa de satisfação: o campo único `valor` (0–10) foi removido e substituído por `consultados?`/`respostasSim`/`respostasNao` (percentual `Sim ÷ (Sim+Não)` derivado em leitura). Como esta spec 041 ainda está em Draft e nenhum dado histórico real foi migrado até esta data, não há retrabalho — apenas a modelagem de destino descrita em FR-001/Key Entities acima precisa ser seguida quando a implementação desta migração for planejada.
- A migração de manifestações, endereços (zona/bairro) e demais dados operacionais desde 2018 já foi realizada em iniciativa anterior (migração AGEMAN v1→v2); esta spec **não** remigra esse dado, apenas complementa com satisfação e orientações vinculadas.
- "Participação em Eventos" está definitivamente fora de escopo — decisão de produto, não é migrada nem implementada em nenhuma spec relacionada a este relatório de gestão.
- O período de 2024 em diante será tratado por lançamento manual no módulo de implementação do relatório de gestão (spec separada), não por esta migração — isso evita conflito com dados que já estão sendo operados ativamente no sistema.
- A planilha "Consolidado 2026-06" anexada é a fonte única e suficiente; não é necessário localizar ou conciliar versões anteriores da planilha.
- Um responsável técnico humano estará disponível para revisar o relatório de exceções após a execução da migração.
- A migração é uma execução pontual (não recorrente); não há requisito de suportar reenvio de planilhas corrigidas pelo cliente no futuro.
