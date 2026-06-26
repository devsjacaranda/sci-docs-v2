# Feature Specification: Fiscalização de Compras — Purchasing (Jatobá)

**Feature Branch**: `019-purchasing-fiscalizacao`

**Created**: 2026-06-25

**Status**: Draft

**Input**: User description: "Painel de Fiscalização Compras em /compras/fiscalizacao. Licença Jatobá. Checagens automáticas de conformidade por demanda e artefatos documentais da Lei 14.133/2021. Somente leitura — não altera dados operacionais."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Ver painel de Fiscalização de Compras (Priority: P1)

Como servidor autenticado com acesso ao módulo Compras e licença Jatobá, preciso abrir `/compras/fiscalizacao` e ver resultados reais de fiscalização sobre demandas e artefatos do meu órgão — conformidade agregada, checagens, achados e histórico — para monitorar completude documental e conformidade legal **sem** alterar registros operacionais.

**Why this priority**: É a entrega central da licença Jatobá no domínio Compras; sem painel funcional, a licença não produz valor institucional.

**Independent Test**: Autenticar usuário do setor de compras com licença Jatobá; popular tenant com demandas em estágios distintos de instrução; navegar a `/compras/fiscalizacao` em até três cliques; verificar título **Fiscalização de Compras**, badge **Somente leitura**, stats nos quatro status canônicos, seções de checagem e achados, tabela histórica com colunas **Demanda**, **PCA**, **Artefatos fiscalizados**, **Conformidade** e **Problemas**.

**Acceptance Scenarios**:

1. **Given** usuário com permissão no módulo Compras e licença Jatobá, **When** acessa `/compras/fiscalizacao`, **Then** vê **Fiscalização de Compras** com resultados da execução mais recente, badge **Somente leitura** e copy que deixa claro que a Jatobá sinaliza achados — **não** altera demandas nem artefatos.
2. **Given** execução concluída existente, **When** a tela carrega, **Then** stats exibem contagem por **Conforme**, **Não conforme**, **Parcial** e **Pendente** — **nunca** *Aguardando resposta*, *Crítico* ou *Vencendo* como status de conformidade.
3. **Given** tenant com demandas reais, **When** o painel exibe dados, **Then** números de demanda e achados correspondem a registros reais — **não** linhas de demonstração fixas.
4. **Given** ações do painel, **When** o usuário lê os botões disponíveis, **Then** vê *Fiscalizar demandas* conforme licença Jatobá.

---

### User Story 2 - Checagens automáticas por demanda (Priority: P1)

Como analista de controle interno de compras, preciso que o sistema avalie automaticamente cada **demanda** e seus **artefatos documentais** (DFD, ETP, Análise de Riscos, TR, Pesquisa de Preços, Dotação, Parecer) contra regras determinísticas de completude, dispensa de ETP e consistência de valores, para classificar conformidade registro a registro sem intervenção manual.

**Why this priority**: Checagens automáticas são o núcleo operacional da Jatobá no domínio Compras; substituem verificação manual planilhada de instrução processual.

**Independent Test**: Popular tenant com demandas em estados distintos (rascunho, parcialmente instruída, concluída, ETP dispensado sem motivo); executar fiscalização e verificar checagens e conformidade agregada por demanda.

**Acceptance Scenarios**:

1. **Given** demanda sem DFD preenchido, **When** checagem de **Completude DFD** executa, **Then** resultado é **Não conforme** ou **Parcial** com achado indicando artefato ausente.
2. **Given** ETP marcado dispensado **sem** motivo de dispensa, **When** checagem de **ETP dispensado** executa, **Then** resultado é **Não conforme** com achado descritivo.
3. **Given** ETP dispensado com motivo informado, **When** checagem de **ETP dispensado** executa, **Then** resultado é **Conforme** para este artefato — ETP **não** exigido como preenchido.
4. **Given** Pesquisa de Preços com valor estimado ausente ou inválido, **When** checagem de **Pesquisa de Preços** executa, **Then** resultado é **Parcial** ou **Não conforme**.
5. **Given** Dotação Orçamentária com valor dotado inferior ao valor estimado da Pesquisa de Preços, **When** checagem de **Consistência orçamentária** executa, **Then** resultado é **Parcial** com achado de divergência de valores.
6. **Given** Análise de Riscos com lista vazia, **When** checagem de **Análise de Riscos** executa, **Then** resultado é **Parcial** ou **Não conforme**.
7. **Given** demanda com status derivado **Concluído** (todos artefatos satisfeitos), **When** fiscalização executa, **Then** conformidade agregada reflete **Conforme** ou **Parcial** conforme checagens individuais — **não** assume conformidade automática pelo status operacional.
8. **Given** múltiplas checagens na mesma demanda, **When** conformidade agregada é calculada, **Then** prevalece o **pior** status entre {Conforme, Parcial, Pendente, Não conforme}.

---

### User Story 3 - Execuções persistidas e histórico (Priority: P1)

Como gestor de compras, preciso que cada rodada de fiscalização seja persistida com data, origem e resumo, consultável no painel e no histórico, com possibilidade de disparo manual e agenda institucional, para rastrear evolução da conformidade documental ao longo do tempo.

**Why this priority**: Persistência de execuções é requisito de produto Jatobá; sem histórico comparável, não há accountability de controle interno.

**Independent Test**: Executar fiscalização manual; verificar execução persistida com contagem de demandas analisadas; listar histórico com duas execuções anteriores; tentar segunda execução manual dentro de uma hora e verificar throttling.

**Acceptance Scenarios**:

1. **Given** usuário aciona *Fiscalizar demandas*, **When** não há execução em andamento e limite horário não foi atingido, **Then** nova **execução de fiscalização** é criada com origem *sob demanda*, analisa **100%** das demandas ativas do tenant e persiste resultados por demanda.
2. **Given** agenda institucional ativa (padrão: diária por tenant), **When** o job executa, **Then** execução é persistida com origem *agendada* e contagem total de demandas analisadas.
3. **Given** múltiplas execuções persistidas, **When** o usuário consulta histórico no painel, **Then** vê lista com data/hora, origem (agendada, sob demanda, ao abrir painel, por registro) e resumo de conformidade — permitindo comparar pelo menos duas execuções anteriores quando existirem.
4. **Given** execução manual já realizada na última hora para o tenant, **When** o usuário tenta *Fiscalizar demandas* novamente, **Then** recebe mensagem clara de limite de frequência e continua vendo a execução mais recente — **sem** erro silencioso.
5. **Given** execução em andamento, **When** segunda solicitação chega, **Then** sistema informa processamento em andamento — uma execução por tenant por vez.

---

### User Story 4 - Rastreabilidade Jatobá (Priority: P1)

Como usuário que precisa confiar no achado ou na checagem, preciso entender como o resultado foi produzido — regra aplicada, campos avaliados, identificador da demanda e artefato fiscalizado — para validar a classificação antes de agir na operação.

**Why this priority**: Rastreabilidade é regra de plataforma; títulos e comportamento de sheet são canônicos para Jatobá.

**Independent Test**: Abrir rastreio de checagem, achado e demanda fiscalizada; verificar títulos obrigatórios e conteúdo descritivo sem alterar dados operacionais.

**Acceptance Scenarios**:

1. **Given** checagem automática exibida, **When** o usuário aciona explicação, **Then** abre sheet inferior (~85% da viewport) com título **Por que esta checagem deu este resultado** — **sem** rota dedicada de rastreio.
2. **Given** achado de inconformidade, **When** o usuário abre rastreio, **Then** sheet usa título **O que gerou este achado** com regra, evidências e número da demanda.
3. **Given** fiscalização de uma demanda no detalhe, **When** o usuário abre rastreio consolidado, **Then** sheet usa título **O que verificamos nesta demanda** listando checagens aplicadas à demanda e artefatos.
4. **Given** qualquer rastreio Jatobá de Compras, **When** exibido, **Then** badge **Somente leitura** está visível — **nunca** *Read-only* em UI pt-BR.

---

### User Story 5 - Governança: licença, permissão e read-only (Priority: P1)

Como administrador de governança, preciso que apenas usuários autorizados ao módulo Compras com licença Jatobá acessem fiscalização, e que nenhuma ação Jatobá altere dados operacionais de demandas ou artefatos.

**Why this priority**: Segurança, separação de eixos (operacional vs conformidade) e contrato de licença são bloqueadores para produção.

**Independent Test**: Usuário sem módulo (403); usuário sem licença Jatobá (alerta de licença); fiscalizar demandas e verificar que campos e status permanecem idênticos.

**Acceptance Scenarios**:

1. **Given** usuário sem permissão no módulo Compras, **When** tenta acessar `/compras/fiscalizacao`, **Then** recebe **403 · Acesso negado** com copy padronizada — item pode permanecer visível na navegação.
2. **Given** usuário autorizado ao módulo **sem** licença Jatobá, **When** tenta acessar fiscalização, **Then** recebe alerta de licença conforme regras de plataforma — **não** vê resultados de conformidade.
3. **Given** usuário autorizado com licença Jatobá, **When** consome fiscalização, **Then** acesso está condicionado à licença ativa no tenant.
4. **Given** qualquer ação de fiscalização, **When** executada, **Then** status operacional da demanda (Rascunho, Em andamento, Concluído) e campos dos artefatos **permanecem inalterados**.
5. **Given** tenant sem demandas, **When** a tela carrega, **Then** estado vazio orienta operação (*registre demandas para habilitar fiscalização*) — **sem** achados fabricados.

---

### User Story 6 - Fiscalização contextual no detalhe da demanda (Priority: P2)

Como servidor de compras, preciso ver o resultado da fiscalização Jatobá no hub `/compras/:id` e disparar fiscalização scoped àquela demanda, para operar conformidade no dia a dia sem depender só do painel agregado.

**Why this priority**: Ação contextual completa paridade com Gabinete (016 US8); depende de checagens automáticas (US2).

**Independent Test**: Abrir detalhe de demanda → ver card **Fiscalização Jatobá desta demanda** → acionar *Fiscalizar demanda* → ver checagens atualizadas para demanda e artefatos.

**Acceptance Scenarios**:

1. **Given** detalhe de demanda em `/compras/:id` com licença Jatobá, **When** o servidor abre a página, **Then** vê card **Fiscalização Jatobá desta demanda** com checagens da última execução e link **Abrir tela** para o painel.
2. **Given** card no detalhe, **When** o servidor aciona *Fiscalizar demanda*, **Then** execução scoped à demanda é disparada com origem *por registro* e resultados atualizados — demanda e artefatos **inalterados**.
3. **Given** demanda sem execução prévia, **When** card carrega, **Then** exibe estado orientador (*Nenhuma fiscalização registrada — fiscalize esta demanda*) com ação disponível.
4. **Given** usuário **sem** licença Jatobá, **When** abre detalhe da demanda, **Then** card de fiscalização **não** é exibido ou exibe call-to-action de licença — **sem** dados de conformidade.

---

### Edge Cases

- Tenant sem demandas: painel exibe estado vazio orientador; execução manual permitida mas produz zero resultados — **sem** achados fabricados.
- Demanda em Rascunho sem artefatos: checagens de completude classificam **Não conforme** ou **Pendente** por artefato ausente.
- ETP dispensado com motivo vs. ETP preenchido: checagens distintas; ambos satisfazem requisito de ETP.
- Demanda excluída logicamente após fiscalização: resultados históricos permanecem com indicação de registro indisponível.
- Execução manual durante job agendado: uma execução por tenant em andamento — segunda solicitação informada.
- Throttling (1 execução completa por hora por tenant): mensagem clara; leitura e histórico não contam no limite.
- Falha do job agendado: última execução bem-sucedida permanece visível; usuário informado se desatualizada além de 48h.
- Valores monetários inconsistentes entre Pesquisa de Preços e Dotação: achado de **Consistência orçamentária** — **não** bloqueia operação.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: O sistema **DEVE** fiscalizar Compras usando dados internos do tenant: demandas ativas, PCAs vinculados e 7 artefatos documentais por demanda.
- **FR-002**: Fiscalização **DEVE** ser **somente leitura** — nenhuma ação Jatobá **DEVE** alterar status operacional, campos de demanda/artefato ou anexos.
- **FR-003**: Classificação de conformidade **DEVE** usar **somente** os quatro status canônicos: **Conforme**, **Não conforme**, **Parcial**, **Pendente**.
- **FR-004**: O sistema **DEVE** persistir **execuções de fiscalização** com data/hora, origem (agendada, sob demanda, ao abrir painel, por registro), tenant, quantidade de demandas analisadas e resumo de conformidade.
- **FR-005**: Cada execução **DEVE** persistir **resultados por demanda** com identificador, PCA vinculado, conformidade agregada, checagens por artefato e achados.
- **FR-006**: O sistema **DEVE** executar fiscalização **agendada periódica** por tenant (padrão: diária).
- **FR-007**: Ao abrir `/compras/fiscalizacao`, o sistema **DEVE** exibir resultados da execução mais recente concluída.
- **FR-008**: O sistema **DEVE** permitir disparo manual (*Fiscalizar demandas*) com limite de **uma execução completa por hora por tenant**.
- **FR-009**: O sistema **DEVE** permitir consultar **histórico** de execuções com data, origem e resumo — suportando comparação de pelo menos duas execuções anteriores.
- **FR-010**: Checagens **DEVEM** incluir completude de cada artefato obrigatório (DFD, ETP ou dispensa, Análise de Riscos, TR, Pesquisa de Preços, Dotação, Parecer).
- **FR-011**: Checagem de **ETP dispensado** **DEVE** exigir motivo de dispensa quando flag dispensado está ativa.
- **FR-012**: Checagem de **Consistência orçamentária** **DEVE** comparar valor estimado (Pesquisa de Preços) com valor dotado (Dotação) quando ambos existem.
- **FR-013**: Conformidade agregada por demanda **DEVE** refletir o **pior** resultado entre checagens da execução.
- **FR-014**: Rastreio **DEVE** abrir em **sheet inferior** (~85% da viewport) com títulos canônicos — **NUNCA** em rota dedicada.
- **FR-015**: Acesso **DEVE** exigir permissão no módulo Compras **e** licença Jatobá ativa no tenant.
- **FR-016**: Hub da demanda (`/compras/:id`) **DEVE** exibir card **Fiscalização Jatobá desta demanda** quando licença Jatobá ativa.
- **FR-017**: UI **DEVE** exibir badge **Somente leitura** no contexto Jatobá — **NUNCA** *Read-only* em UI pt-BR.
- **FR-018**: Vocabulário UI **DEVE** usar **demanda/demandas** no domínio Compras.
- **FR-019**: Rota pública **DEVE** ser `/compras/fiscalizacao` — vocabulário *Fiscalização*, **não** *Auditoria* na UI.
- **FR-020**: Escopo **limita-se** ao módulo Compras — **NÃO** inclui Central global, Carvalho, Cedro ou Pau-Brasil.

### Fronteiras entre licenças (obrigatório)

| Licença | O que faz neste contexto | O que **NÃO** faz |
| --- | --- | --- |
| **Base** | CRUD de demandas e artefatos (spec 018) | Classificar conformidade; fiscalizar |
| **Jatobá (esta feature)** | Checagens por demanda; achados; execuções; histórico; rastreio | Alterar registros; score Carvalho; insights Cedro |
| **Carvalho** | Score de maturidade macro (consome conformidade Jatobá) | Fiscalizar registro a registro nesta entrega |
| **Cedro** | Insights estratégicos read-only | Conformidade operacional; achados táticos |

### Key Entities

- **Execução de fiscalização**: rodada de análise com instante, origem, tenant, quantidade de demandas analisadas, resumo de conformidade e referência aos resultados filhos.
- **Resultado de fiscalização (por demanda)**: vínculo demanda ↔ execução; identificador da demanda; PCA vinculado; conformidade agregada; lista de checagens por artefato e achados.
- **Checagem automática**: regra nomeada (ex.: Completude DFD, ETP dispensado, Consistência orçamentária), descrição, campos avaliados, status de conformidade e metadados para rastreio.
- **Achado**: problema detectado; título, descrição, checagem de origem, status, demanda e artefato afetados.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Usuário autorizado alcança o painel Fiscalização em **≤ 3 cliques** a partir do overview de Compras.
- **SC-002**: Execução manual completa analisa **100%** das demandas ativas do tenant.
- **SC-003**: Checagens cobrem os **7 artefatos documentais** + consistência orçamentária com status ∈ {Conforme, Não conforme, Parcial, Pendente}.
- **SC-004**: **100%** dos achados e checagens exibidos possuem rastreio explicativo acessível via sheet.
- **SC-005**: **Nenhuma** ação de fiscalização altera status operacional ou campos de demanda/artefato — validável comparando registro antes e depois.
- **SC-006**: Segunda execução manual dentro de **1 hora** retorna mensagem de throttle clara — **zero** erros silenciosos.
- **SC-007**: Demonstração ponta a ponta (criar demanda incompleta → fiscalizar → ver achado de DFD ausente → completar DFD → refiscalizar → achado resolvido) concluída em **≤ 10 minutos** por usuário sem treinamento prévio.
- **SC-008**: Card no detalhe da demanda exibe checagens atualizadas após *Fiscalizar demanda* scoped em **≤ 5 segundos** percebidos pelo usuário.

## Assumptions

- **Dependência**: spec 018 (CRUD de demandas e artefatos) concluída ou em paralelo — fiscalização consome dados reais de demandas e artefatos.
- **Demandas fiscalizadas**: registros ativos (não excluídos logicamente) do tenant.
- **Agenda**: execução diária por tenant; falha não apaga histórico anterior.
- **Throttling**: uma execução manual completa por tenant por hora; execução scoped a uma demanda conta no mesmo limite horário.
- **Vocabulário UI**: **demanda** (rotas `/compras/*`); tela de fiscalização em `/compras/fiscalizacao`.
- **Paridade estrutural**: comportamento alinhado à spec 016-gabinete-fiscalizacao-integrada, adaptado ao domínio Compras e artefatos Lei 14.133.
- **Questionários internos Jatobá**: fora de escopo nesta entrega — apenas checagens automáticas.

## Out of Scope

- Questionários internos, banco de perguntas e respostas Jatobá no domínio Compras.
- Alteração operacional de demandas ou artefatos a partir de achados.
- Score Carvalho, Insights Cedro e Pau-Brasil de Compras.
- Exportação PDF de relatório de fiscalização.
- Fiscalização de PCAs como entidade independente (apenas demandas e artefatos).
