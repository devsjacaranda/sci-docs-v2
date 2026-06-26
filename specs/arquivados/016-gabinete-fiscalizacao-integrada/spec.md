# Feature Specification: Fiscalização de Gestão — Gabinete (Jatobá)

**Feature Branch**: `016-gabinete-fiscalizacao-integrada`

**Created**: 2026-06-24

**Status**: Completed

**Input**: User description: "Implementar Fiscalização de Gestão — Gabinete, integrando tudo — atos, protocolo, controle numérico, notificações e autos e documentos tramitados. Atualmente não funciona e não atende todo escopo. Paridade com Ouvidoria (008); fiscalizar atos e cadastros órfãos; questionários internos; banco de perguntas; rastreio; card no detalhe do ato."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Ver painel de Fiscalização no Gabinete (Priority: P1)

Como servidor autenticado com acesso ao módulo Gabinete, preciso abrir a tela **Fiscalização** (`/gabinete/auditoria`) e ver resultados reais de fiscalização Jatobá sobre atos e cadastros do meu órgão — conformidade agregada, checagens, achados e histórico — para monitorar prazos, completude e controles vinculados **sem** alterar registros operacionais.

**Why this priority**: É a entrega central da licença Jatobá no Gabinete; a tela atual não exibe painel funcional — apenas estado vazio e botão de disparo.

**Independent Test**: Autenticar usuário do setor Gabinete, navegar a `/gabinete/auditoria` em até três cliques; verificar título **Fiscalização de Gestão — Gabinete**, badge **Somente leitura**, stats nos quatro status canônicos, seções de checagem e achados, tabela histórica com colunas **Ato**, **Dados fiscalizados**, **Questionário**, **Destinatário**, **Canal**, **Conformidade** e **Problemas** — todos refletindo execução real do tenant.

**Acceptance Scenarios**:

1. **Given** usuário com permissão no módulo Gabinete, **When** acessa `/gabinete/auditoria`, **Then** vê **Fiscalização de Gestão — Gabinete** com resultados da execução mais recente, badge **Somente leitura** e copy que deixa claro que a Jatobá sinaliza achados — **não** altera atos nem cadastros.
2. **Given** execução concluída existente, **When** a tela carrega, **Then** stats exibem contagem por **Conforme**, **Não conforme**, **Parcial** e **Pendente** — **nunca** *Aguardando resposta*, *Crítico* ou *Vencendo* como status de conformidade.
3. **Given** tenant com atos e cadastros reais, **When** o painel exibe dados, **Then** identificadores (protocolo do ato, número do cadastro) e achados correspondem a registros reais — **não** linhas de demonstração fixas.
4. **Given** ações do painel, **When** o usuário lê os botões disponíveis, **Then** vê *Fiscalizar atos* e *Novo questionário* conforme licença Jatobá.

---

### User Story 2 - Checagens automáticas ampliadas (Priority: P1)

Como analista de controle interno do Gabinete, preciso que o sistema avalie automaticamente cada **ato** e cada **cadastro órfão** (protocolo, controle numérico, notificação, auto de infração, documento tramitado sem vínculo a ato) contra regras determinísticas de prazo, tramitação, completude, protocolo, controles e evidências, para classificar conformidade registro a registro sem intervenção manual.

**Why this priority**: Checagens automáticas são o núcleo operacional da Jatobá; a implementação atual cobre apenas prazo concessionária, tramitação e completude do ato — **não** integra protocolo nem controles.

**Independent Test**: Popular tenant com atos em estados distintos, controles vinculados e cadastros órfãos (notificação sem auto pareado, documento tramitado com prazo vencido); executar fiscalização e verificar checagens e conformidade agregada por registro.

**Acceptance Scenarios**:

1. **Given** ato não rascunho com prazo da concessionária vencido e sem data de resposta registrada, **When** checagem de **Prazo concessionária** executa, **Then** resultado é **Não conforme** com achado descritivo.
2. **Given** ato em status operacional avançado (*Em análise*, *Em trâmite*, *Aguardando concessionária* ou equivalente) **sem** protocolo vinculado, **When** checagem de **Protocolo** executa, **Then** resultado é **Parcial** ou **Não conforme** conforme severidade da política institucional.
3. **Given** protocolo vinculado ao ato com campos críticos vazios (ex.: remetente, data de recebimento, assunto do protocolo), **When** checagem de **Completude do protocolo** executa, **Then** resultado reflete lacunas como **Parcial**.
4. **Given** controle numérico vinculado sem número ou data quando tipo documental exige identificação, **When** checagem de **Controle numérico** executa, **Then** resultado é **Parcial** com achado indicando campo crítico ausente.
5. **Given** notificação com prazo ou vencimento ultrapassado e sem resposta registrada, **When** checagem de **Prazo da notificação** executa, **Then** resultado é **Não conforme**.
6. **Given** notificação com `groupId` definido e **sem** auto de infração pareado no mesmo grupo, **When** checagem de **Pareamento notificação/auto** executa, **Then** resultado é **Parcial**; o inverso (auto sem notificação no grupo) aplica a mesma regra.
7. **Given** notificação ou auto com campos críticos vazios (termo, destinatário; ou setor emissor no auto), **When** checagem de **Completude do controle** executa, **Then** resultado é **Parcial**.
8. **Given** documento tramitado com prazo ou observação de vencimento ultrapassado, **When** checagem de **Prazo do documento tramitado** executa, **Then** resultado é **Não conforme** quando vencido sem tratamento registrado.
9. **Given** ato com encaminhamento pendente além do limite institucional de dias, **When** checagem de **Tramitação** executa, **Then** resultado reflete gap prolongado como **Não conforme** ou **Parcial**.
10. **Given** ato com anexo pendente de confirmação de upload quando política exige evidência, **When** checagem de **Evidências e anexos** executa, **Then** resultado sinaliza lacuna conforme regra.
11. **Given** múltiplas checagens no mesmo registro (ato ou cadastro), **When** conformidade agregada é calculada, **Then** prevalece o **pior** status entre {Conforme, Parcial, Pendente, Não conforme} — apenas esses quatro valores.
12. **Given** ato com múltiplos controles do mesmo tipo vinculados, **When** fiscalização executa, **Then** cada controle é checado individualmente e a conformidade agregada do ato reflete o pior resultado entre ato + controles vinculados + protocolo vinculado.

---

### User Story 3 - Execuções persistidas, histórico e disparo (Priority: P1)

Como gestor do Gabinete, preciso que cada rodada de fiscalização seja persistida com data, origem e resumo, consultável no painel e no histórico, com possibilidade de disparo manual e agenda institucional, para rastrear evolução da conformidade ao longo do tempo.

**Why this priority**: Persistência de execuções é requisito de produto; sem histórico comparável, não há accountability de controle interno institucional.

**Independent Test**: Executar fiscalização manual, verificar execução persistida com contagem de atos e cadastros órfãos analisados; listar histórico com duas execuções anteriores; tentar segunda execução manual dentro de uma hora e verificar throttling.

**Acceptance Scenarios**:

1. **Given** usuário aciona *Fiscalizar atos*, **When** não há execução em andamento e limite horário não foi atingido, **Then** nova **execução de fiscalização** é criada com origem *sob demanda*, analisa **100%** dos atos não rascunho **e** cadastros órfãos ativos do tenant e persiste resultados por registro.
2. **Given** agenda institucional ativa (padrão: diária por tenant), **When** o job executa, **Then** execução é persistida com origem *agendada* e contagem total de registros analisados (atos + cadastros órfãos).
3. **Given** múltiplas execuções persistidas, **When** o usuário consulta histórico no painel, **Then** vê lista com data/hora, origem (agendada, sob demanda, ao abrir painel, por registro) e resumo de conformidade — permitindo comparar pelo menos duas execuções anteriores quando existirem.
4. **Given** execução manual já realizada na última hora para o tenant, **When** o usuário tenta *Fiscalizar atos* novamente, **Then** recebe mensagem clara de limite de frequência e continua vendo a execução mais recente — sem erro silencioso.
5. **Given** execução em andamento, **When** segunda solicitação chega, **Then** sistema informa processamento em andamento ou aguarda conclusão — uma execução por tenant por vez.

---

### User Story 4 - Rastreabilidade Jatobá (Priority: P1)

Como usuário que precisa confiar no achado ou na checagem, preciso entender como o resultado foi produzido — regra aplicada, campos avaliados, identificador do registro e tipo de entidade fiscalizada — para validar a classificação antes de agir na Base.

**Why this priority**: Rastreabilidade é regra de plataforma; títulos e comportamento de sheet são canônicos para Jatobá.

**Independent Test**: Abrir rastreio de checagem, achado e registro fiscalizado; verificar títulos obrigatórios e conteúdo descritivo sem alterar dados operacionais.

**Acceptance Scenarios**:

1. **Given** checagem automática exibida, **When** o usuário aciona explicação, **Then** abre sheet inferior (~85% da viewport) com título **Por que esta checagem deu este resultado** — **sem** rota dedicada de rastreio.
2. **Given** achado de inconformidade, **When** o usuário abre rastreio, **Then** sheet usa título **O que gerou este achado** com regra, evidências e identificador do registro (protocolo do ato ou identificador do cadastro).
3. **Given** fiscalização de um registro no detalhe do ato ou de cadastro, **When** o usuário abre rastreio consolidado, **Then** sheet usa título **O que verificamos neste registro** listando checagens aplicadas ao ato e controles vinculados.
4. **Given** pergunta de questionário enviada, **When** o usuário abre rastreio, **Then** sheet usa título **Por que esta pergunta foi enviada** com contexto do registro fiscalizado.

---

### User Story 5 - Governança: licença, permissão e read-only (Priority: P1)

Como administrador de governança, preciso que apenas usuários autorizados ao módulo Gabinete com licença Jatobá acessem fiscalização, e que nenhuma ação Jatobá altere dados operacionais de atos ou cadastros.

**Why this priority**: Segurança, separação de eixos (operacional vs conformidade) e contrato de licença são bloqueadores para produção.

**Independent Test**: Usuário sem módulo (403); fiscalizar ato e cadastros e verificar que status, campos e eventos permanecem idênticos.

**Acceptance Scenarios**:

1. **Given** usuário sem permissão no módulo Gabinete, **When** tenta acessar `/gabinete/auditoria`, **Then** recebe **403 · Acesso negado** com copy padronizada — item pode permanecer visível na navegação.
2. **Given** usuário autorizado, **When** consome fiscalização, **Then** acesso está condicionado à licença Jatobá ativa no tenant.
3. **Given** qualquer ação de fiscalização ou questionário, **When** executada, **Then** status operacional do ato (Recebido, Em análise, Em trâmite, etc.) e campos dos cadastros **permanecem inalterados** — conformidade Jatobá é eixo distinto.
4. **Given** tenant sem atos confirmados mas com cadastros órfãos, **When** fiscalização executa, **Then** analisa cadastros órfãos e exibe resultados — **sem** achados fabricados para atos inexistentes.
5. **Given** tenant sem atos nem cadastros, **When** a tela carrega, **Then** estado vazio orienta operação (*registre atos ou cadastros para habilitar fiscalização*) — **sem** achados fabricados.

---

### User Story 6 - Questionários internos (Priority: P2)

Como servidor do Gabinete, preciso criar questionários para a equipe interna sobre dados fiscalizados de um ato ou cadastro, coletar respostas via portal autenticado e acompanhar estado do fluxo, para complementar checagens automáticas com validação humana.

**Why this priority**: Questionários internos completam paridade com Ouvidoria (008); secundários às checagens automáticas mas necessários para conformidade operacional plena no Gabinete.

**Independent Test**: Criar questionário interno a partir do banco de perguntas Gabinete, responder autenticado, verificar atualização de estado *Respondido* e reflexo no histórico do painel.

**Acceptance Scenarios**:

1. **Given** ato ou cadastro fiscalizado, **When** o servidor aciona *Novo questionário* com destinatário **Interno**, **Then** questionário é criado vinculado ao registro com estado de fluxo *Aguardando resposta interna*.
2. **Given** questionário interno pendente, **When** servidor autorizado responde no portal, **Then** respostas são persistidas e estado passa a *Respondido* — **não** confundido com status de conformidade canônico.
3. **Given** questionário respondido, **When** exibido no histórico do painel, **Then** colunas Questionário, Destinatário (*Interno*) e Canal (*Portal interno*) refletem o registro real.
4. **Given** módulo Gabinete, **When** servidor tenta criar questionário externo, **Then** opção externa **não é exibida** — Gabinete opera **somente** questionários internos nesta entrega.

---

### User Story 7 - Banco de perguntas do domínio Gabinete (Priority: P2)

Como responsável pelo módulo Gabinete, preciso gerenciar o banco de perguntas específico do domínio Gabinete (distinto de Ouvidoria), para compor questionários internos alinhados à operação de atos e controles.

**Why this priority**: Banco editável é parte do escopo Jatobá completo acordado; depende das checagens e execuções (P1).

**Independent Test**: Listar perguntas seed do tenant Gabinete; criar pergunta nova; desativar pergunta; verificar que perguntas de Ouvidoria **não** aparecem no banco Gabinete.

**Acceptance Scenarios**:

1. **Given** usuário com licença Jatobá no Gabinete, **When** acessa gestão do banco de perguntas, **Then** pode listar, criar, editar e desativar perguntas com texto, tipo (Sim/Não, escala, descritiva, checklist) e destinatário **Interno**.
2. **Given** tenant provisionado, **When** banco é consultado pela primeira vez, **Then** perguntas padrão do domínio Gabinete estão disponíveis (ex.: conformidade de prazo da concessionária; completude de controles vinculados; pareamento notificação/auto).
3. **Given** pergunta desativada, **When** servidor cria novo questionário, **Then** pergunta inativa **não** aparece na seleção — **sem** opção desabilitada sem explicação.

---

### User Story 8 - Fiscalização contextual no detalhe do ato (Priority: P2)

Como servidor do Gabinete, preciso ver o resultado da fiscalização Jatobá no detalhe de um ato e disparar fiscalização scoped àquele registro, para operar conformidade no dia a dia sem depender só do painel agregado.

**Why this priority**: Ação contextual completa paridade com Ouvidoria (008 US8); depende de checagens ampliadas (US2).

**Independent Test**: Abrir detalhe de ato em `/gabinete/atos/:id` → ver card **Fiscalização Jatobá deste registro** → acionar *Fiscalizar dados* → ver checagens atualizadas para ato + controles vinculados.

**Acceptance Scenarios**:

1. **Given** detalhe de ato não rascunho, **When** o servidor abre a página, **Then** vê card **Fiscalização Jatobá deste registro** com checagens da última execução para aquele ato (incluindo protocolo e controles vinculados) e link **Abrir tela** para o painel.
2. **Given** card no detalhe, **When** o servidor aciona *Fiscalizar dados*, **Then** execução scoped ao ato é disparada com origem *por registro* e resultados atualizados — ato e cadastros operacionais **inalterados**.
3. **Given** ato sem execução prévia, **When** card carrega, **Then** exibe estado orientador (*Nenhuma fiscalização registrada — fiscalize este ato*) com ação disponível.

---

### User Story 9 - Fiscalizar cadastros órfãos (Priority: P2)

Como analista de controle interno, preciso que cadastros cadastrados **sem** vínculo a ato (protocolo standalone, controle numérico, notificação, auto de infração, documento tramitado) entrem na execução de fiscalização e apareçam no painel com tipo de entidade identificado, para cobrir toda a operação documental do Gabinete — não apenas atos.

**Why this priority**: Decisão de produto: unidade fiscalizada inclui cadastros órfãos; hoje a fiscalização analisa apenas atos.

**Independent Test**: Cadastrar notificação standalone sem ato; executar fiscalização; verificar resultado no painel com coluna **Dados fiscalizados** indicando tipo *Notificação* e identificador; checagens de prazo e pareamento aplicadas.

**Acceptance Scenarios**:

1. **Given** protocolo cadastrado sem `cabinetId`, **When** fiscalização executa, **Then** protocolo entra como registro fiscalizado independente com checagens de completude aplicáveis.
2. **Given** notificação órfã com prazo vencido, **When** fiscalização executa, **Then** resultado aparece no painel com conformidade **Não conforme** e achado de prazo — identificador visível na coluna **Ato** ou equivalente (*Cadastro órfão — Notificação*).
3. **Given** cadastro órfão posteriormente vinculado a ato, **When** próxima fiscalização executa, **Then** registro é fiscalizado **no contexto do ato** (vinculado) — **sem** duplicar resultado como órfão e vinculado na mesma execução.
4. **Given** cadastro órfão excluído logicamente, **When** fiscalização executa, **Then** registro **não** entra na análise; resultados históricos permanecem consultáveis.

---

### Edge Cases

- Tenant sem atos confirmados mas com cadastros órfãos: fiscalização executável; painel exibe resultados dos cadastros.
- Ato em rascunho: **excluído** da execução; cadastros vinculados a rascunho seguem política da Base (se vinculados, checados no contexto do ato quando ato deixa de ser rascunho).
- Múltiplos controles do mesmo tipo no ato: checagem por registro de controle; agregação worst-of no ato.
- `groupId` nulo em notificação/auto: pareamento **não** exigido; checagens de prazo e completude aplicam-se individualmente.
- Execução manual durante job agendado: uma execução por tenant em andamento — segunda solicitação informada.
- Throttling (1 execução completa por hora por tenant): mensagem clara; leitura e histórico não contam no limite.
- Falha do job agendado: última execução bem-sucedida permanece visível; usuário informado se desatualizada além de 48h.
- Ato excluído logicamente após fiscalização: resultados históricos permanecem com indicação de registro indisponível.
- Protocolo vinculado a múltiplos atos (se aplicável na Base): fiscalizado no contexto de cada ato vinculado — **sem** duplicar achados conflitantes no painel agregado (pior status prevalece por instância).
- Campos opcionais v1 deixados em branco quando regra **não** os classifica como críticos: checagem **Conforme** ou **Pendente** — **nunca** **Não conforme** só por campo opcional vazio.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: O sistema **DEVE** fiscalizar o Gabinete usando dados internos do tenant: atos não rascunho, protocolos (vinculados e órfãos), controles numéricos, notificações, autos de infração, documentos tramitados, eventos de linha do tempo e anexos confirmados.
- **FR-002**: Fiscalização **DEVE** ser **somente leitura** — nenhuma ação Jatobá **DEVE** alterar status operacional, campos de ato/cadastro ou eventos da timeline.
- **FR-003**: Classificação de conformidade **DEVE** usar **somente** os quatro status canônicos: **Conforme**, **Não conforme**, **Parcial**, **Pendente**.
- **FR-004**: Estados de fluxo de questionário (*Aguardando resposta interna*, *Respondido*, *Não iniciado*) **DEVEM** ser distintos de status de conformidade.
- **FR-005**: O sistema **DEVE** persistir **execuções de fiscalização** com data/hora, origem (agendada, sob demanda, ao abrir painel, por registro), tenant, quantidade de registros analisados e resumo de conformidade.
- **FR-006**: Cada execução **DEVE** persistir **resultados por registro** com tipo de entidade fiscalizada (ato, protocolo, controle_numerico, notificacao, auto_infracao, documento_tramitado), identificador, conformidade agregada, checagens e achados.
- **FR-007**: O sistema **DEVE** executar fiscalização **agendada periódica** por tenant (padrão: diária).
- **FR-008**: Ao abrir `/gabinete/auditoria`, o sistema **DEVE** exibir resultados da execução mais recente concluída.
- **FR-009**: O sistema **DEVE** permitir disparo manual (*Fiscalizar atos*) com limite de **uma execução completa por hora por tenant**.
- **FR-010**: O sistema **DEVE** permitir consultar **histórico** de execuções com data, origem e resumo — suportando comparação de pelo menos duas execuções anteriores.
- **FR-011**: Checagens do **ato** **DEVEM** incluir: prazo concessionária, tramitação/encaminhamento, completude (assunto/descrição), evidências/anexos quando aplicável.
- **FR-012**: Checagem de **protocolo** **DEVE** exigir vínculo quando ato está em status operacional avançado (Em análise, Em trâmite, Aguardando concessionária, Finalizado ou equivalentes documentados nas Assumptions).
- **FR-013**: Checagem de **protocolo** **DEVE** avaliar completude de campos críticos quando protocolo existe (remetente, data de recebimento, assunto).
- **FR-014**: Checagem de **controle numérico** **DEVE** avaliar presença de tipo, número e data conforme tipo documental.
- **FR-015**: Checagem de **notificação/auto** **DEVE** classificar prazo ou vencimento ultrapassado sem resposta como **Não conforme**.
- **FR-016**: Checagem de **pareamento notificação/auto** **DEVE** classificar **Parcial** quando `groupId` está definido e falta registro pareado no mesmo grupo.
- **FR-017**: Checagem de **completude de controles** **DEVE** classificar **Parcial** quando campos críticos estão vazios: termo e destinatário (notificação); setor emissor (auto).
- **FR-018**: Checagem de **documento tramitado** **DEVE** respeitar setor obrigatório (Base) e sinalizar prazo/observação vencidos.
- **FR-019**: Conformidade agregada por registro **DEVE** refletir o **pior** resultado entre checagens da execução.
- **FR-020**: Conformidade agregada de **ato com vínculos** **DEVE** incluir checagens do ato, protocolo vinculado e controles vinculados — worst-of global.
- **FR-021**: **Cadastros órfãos** (sem vínculo a ato) **DEVEM** entrar em toda execução completa como registros fiscalizados independentes.
- **FR-022**: Rastreio **DEVE** abrir em **sheet inferior** (~85% da viewport) com títulos canônicos — **NUNCA** em rota dedicada.
- **FR-023**: Acesso **DEVE** exigir permissão no módulo Gabinete; consumo **DEVE** estar sob licença Jatobá.
- **FR-024**: O sistema **DEVE** permitir **CRUD** de perguntas no banco do domínio Gabinete (texto, tipo, destinatário interno, ativo/inativo).
- **FR-025**: O sistema **DEVE** permitir criar **questionários internos** vinculados a ato ou cadastro fiscalizado — **SEM** questionário externo no Gabinete.
- **FR-026**: Respostas a questionários **DEVEM** ser persistidas e refletidas no histórico do painel.
- **FR-027**: Detalhe do ato **DEVE** exibir card **Fiscalização Jatobá deste registro** com checagens da última execução e ação *Fiscalizar dados* scoped ao registro.
- **FR-028**: UI **DEVE** exibir badge **Somente leitura** no contexto Jatobá — **NUNCA** *Read-only* em UI pt-BR.
- **FR-029**: Vocabulário UI **DEVE** usar **ato/atos** (não *demanda*) conforme operação atual do Gabinete.
- **FR-030**: Escopo **limita-se** ao módulo Gabinete (`/gabinete/auditoria`, detalhe do ato, cadastros órfãos) — **NÃO** inclui Central global, Carvalho, Cedro ou Pau-Brasil.

### Fronteiras entre licenças (obrigatório)

| Licença | O que faz neste contexto | O que **NÃO** faz |
| --- | --- | --- |
| **Base** | CRUD de atos, protocolos, controles, documentos tramitados; tramitação stub; status operacional | Classificar conformidade; enviar questionários Jatobá |
| **Jatobá (esta feature)** | Checagens registro-a-registro; achados; questionários internos; banco de perguntas Gabinete; fiscalização de cadastros órfãos | Alterar registros; score Carvalho; insights Cedro |
| **Carvalho** | Score de maturidade macro (consome conformidade Jatobá) | Fiscalizar registro a registro nesta entrega |
| **Cedro** | Insights estratégicos read-only | Conformidade operacional; questionários; achados táticos |

### Key Entities

- **Execução de fiscalização**: rodada de análise com instante, origem, tenant, quantidade de registros analisados (atos + cadastros órfãos), resumo de conformidade e referência aos resultados filhos.
- **Resultado de fiscalização (por registro)**: vínculo registro ↔ execução; tipo de entidade fiscalizada; identificador (protocolo do ato ou id legível do cadastro); conformidade agregada; lista de checagens e achados.
- **Checagem automática**: regra nomeada (ex.: Prazo concessionária, Pareamento notificação/auto), descrição, campos avaliados, status de conformidade e metadados para rastreio.
- **Achado**: problema detectado; título, descrição, checagem de origem, status, registro afetado.
- **Pergunta do banco (Gabinete)**: texto, tipo de resposta, destinatário interno, flag ativo — **distinta** do banco Ouvidoria.
- **Questionário interno**: conjunto de perguntas aplicadas a ato ou cadastro; estado de fluxo; canal *Portal interno*.
- **Resposta de questionário**: respostas por pergunta; autor interno autenticado; data/hora.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Usuário autorizado alcança o painel Fiscalização em **≤ 3 cliques** a partir do overview do Gabinete.
- **SC-002**: Execução manual completa analisa **100%** dos atos não rascunho **e** cadastros órfãos ativos do tenant.
- **SC-003**: Checagens cobrem os **seis domínios** (ato, protocolo, controle numérico, notificação, auto, documento tramitado) com status ∈ {Conforme, Não conforme, Parcial, Pendente}.
- **SC-004**: **100%** dos achados e checagens exibidos possuem rastreio explicativo acessível via sheet.
- **SC-005**: **Nenhuma** ação de fiscalização ou questionário altera status operacional ou campos de ato/cadastro — validável comparando registro antes e depois.
- **SC-006**: Segunda execução manual dentro de **1 hora** retorna mensagem de throttle clara — **zero** erros silenciosos.
- **SC-007**: Questionário interno criado e respondido reflete no histórico do painel em **≤ 1 interação** após resposta.
- **SC-008**: Demonstração ponta a ponta (cadastrar ato + controles → fiscalizar → ver achado de pareamento → questionário interno → responder) concluída em **≤ 15 minutos** por usuário sem treinamento prévio.
- **SC-009**: Quando existem ≥ 3 execuções persistidas, o usuário **DEVE** poder visualizar e comparar pelo menos **2 execuções anteriores** à mais recente no histórico.
- **SC-010**: Card no detalhe do ato exibe checagens atualizadas após *Fiscalizar dados* scoped em **≤ 5 segundos** percebidos pelo usuário.

## Assumptions

- **Atos fiscalizados**: registros com status **diferente de rascunho** e não excluídos logicamente.
- **Cadastros órfãos**: protocolo, controle numérico, notificação, auto ou documento tramitado **sem** vínculo ativo a ato (`cabinetId` nulo) e não excluídos.
- **Status avançados que exigem protocolo**: *Em análise*, *Em trâmite*, *Aguardando concessionária*, *Finalizado*, *Arquivado* — atos em *Recebido* ou equivalente inicial **não** exigem protocolo vinculado.
- **Limite de encaminhamento pendente**: default **5 dias** corridos sem resposta posterior — configurável por tenant na fase plan.
- **Campos críticos por tipo documental (controle numérico)**: número e data para todos os tipos; assunto recomendado mas **Parcial** apenas quando número **e** data ausentes simultaneamente.
- **Pareamento notificação/auto**: usa `groupId` quando informado; quando nulo, registros fiscalizados isoladamente.
- **Agenda**: execução diária por tenant; falha não apaga histórico anterior.
- **Throttling**: uma execução manual completa por tenant por hora; execução scoped a um registro conta no mesmo limite horário.
- **Questionários Gabinete**: **somente internos** — sem canal externo, WhatsApp ou formulário público nesta entrega.
- **Vocabulário UI**: **ato** (rotas `/gabinete/atos/*`); tela de fiscalização em `/gabinete/auditoria`.
- **Dependências**: entregas 012-desmock-gabinete (atos, cadastros, schema fiscalização) e 015-gabinete-cedro-insights-integrado concluídas; esta spec **complementa** e **corrige** lacunas Jatobá sem reimplementar CRUD Base.
- **Paridade estrutural**: comportamento alinhado à spec 008-ouvidoria-jatoba-fiscalizacao, adaptado ao domínio Gabinete e cadastros órfãos.

## Out of Scope

- Questionários externos, WhatsApp, e-mail transacional ou formulário público tokenizado no Gabinete.
- Alteração operacional de atos ou cadastros a partir de achados ou respostas de questionário.
- Score Carvalho, Insights Cedro e Pau-Brasil do Gabinete.
- Tramitação inter-setorial real (feature 014).
- Central global de Fiscalização e banco de perguntas TI transversal.
- Exportação PDF de relatório de fiscalização.
- Reimplementação de CRUD Base de atos, protocolos ou controles (já entregue em 012).
