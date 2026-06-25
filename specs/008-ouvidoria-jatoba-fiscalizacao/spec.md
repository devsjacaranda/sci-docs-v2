# Feature Specification: Painel de Fiscalização — Ouvidoria (Jatobá)

**Feature Branch**: `008-ouvidoria-jatoba-fiscalizacao`

**Created**: 2026-06-19

**Status**: Draft

**Input**: User description: "Implementar realmente o Painel de Fiscalização — Ouvidoria em `/ouvidoria/auditoria` (licença Jatobá). Escopo completo: checagens automáticas registro-a-registro, execuções persistidas, questionários internos e externos (manifestante), banco de perguntas editável do domínio Ouvidoria e fiscalização contextual no detalhe da manifestação. Substituir mocks por dados reais do tenant. Prazo de resposta via SLA por tipo configurável; canais externos simulados (link/token, sem WhatsApp/SMTP real)."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Ver painel de Fiscalização na Ouvidoria (Priority: P1)

Como servidor autenticado com acesso ao módulo Ouvidoria, preciso abrir a tela **Fiscalização** (`/ouvidoria/auditoria`) e ver resultados reais de fiscalização Jatobá sobre manifestações do meu órgão — conformidade agregada, checagens, achados e histórico — para monitorar prazos e qualidade sem alterar registros operacionais.

**Why this priority**: É a entrega central da licença Jatobá no módulo; sem painel real substituindo mocks, a rota não entrega valor de controle interno institucional.

**Independent Test**: Autenticar usuário do setor Ouvidoria, navegar ao overview e abrir Fiscalização em até três cliques; verificar banner Jatobá, stats de conformidade nos quatro status canônicos, seções de checagem e achados, tabela histórica com colunas Manifestação, Dados fiscalizados, Questionário, Destinatário, Canal, Conformidade e Problemas — todos refletindo execução real do tenant, não dados fictícios.

**Acceptance Scenarios**:

1. **Given** usuário com permissão no módulo Ouvidoria, **When** acessa `/ouvidoria/auditoria`, **Then** vê **Painel de Fiscalização — Ouvidoria** com resultados da execução mais recente, badge **Somente leitura** e copy que deixa claro que a Jatobá sinaliza achados — **não** altera manifestações.
2. **Given** execução concluída existente, **When** a tela carrega, **Then** stats exibem contagem por **Conforme**, **Não conforme**, **Parcial** e **Pendente** — **nunca** *Aguardando resposta* ou *Problema detectado* como status de conformidade.
3. **Given** tenant com manifestações confirmadas, **When** o painel exibe dados, **Then** protocolos e achados correspondem a registros reais — **não** linhas de demonstração fixas.
4. **Given** ações do painel, **When** o usuário lê os botões disponíveis, **Then** vê *Fiscalizar manifestações* e *Novo questionário* conforme licença Jatobá.

---

### User Story 2 - Checagens automáticas registro-a-registro (Priority: P1)

Como analista de controle interno da Ouvidoria, preciso que o sistema avalie automaticamente cada manifestação confirmada contra regras determinísticas de prazo, tramitação, completude, anexos e contato do manifestante, para classificar conformidade registro a registro sem intervenção manual.

**Why this priority**: Checagens automáticas são o núcleo operacional da Jatobá; sem elas, o painel seria apenas formulário de questionários.

**Independent Test**: Popular tenant com manifestações em estados distintos (prazo vencido, tramitação incompleta, anônima, respondida no prazo); executar fiscalização e verificar checagens e conformidade agregada por protocolo.

**Acceptance Scenarios**:

1. **Given** manifestação confirmada com prazo de resposta vencido e sem evento de resposta na linha do tempo, **When** checagem de **Prazo de resposta** executa, **Then** resultado é **Não conforme** com achado descritivo (ex.: prazo vencido sem resposta formal).
2. **Given** prazo calculado por SLA do tipo (data de confirmação + dias configurados), **When** faltam ≤ 20% dos dias até o limite e ainda não há resposta, **Then** checagem de prazo **PODE** classificar **Parcial** como alerta antecipado.
3. **Given** manifestação em tramitação com encaminhamento sem setor destino registrado, **When** checagem de **Tramitação** executa, **Then** resultado reflete lacuna (ex.: **Parcial** ou **Não conforme** conforme severidade da regra).
4. **Given** manifestação com assunto, descrição e tipo preenchidos após confirmação, **When** checagem de **Completude** executa, **Then** resultado é **Conforme** para campos obrigatórios.
5. **Given** manifestação identificada sem e-mail nem telefone de retorno, **When** checagem de **Canal e contato** executa, **Then** sinaliza impedimento para questionário externo — **sem** expor PII na listagem agregada.
6. **Given** múltiplas checagens na mesma manifestação, **When** conformidade agregada é calculada, **Then** prevalece o **pior** status entre {Conforme, Parcial, Pendente, Não conforme} — apenas esses quatro valores.

---

### User Story 3 - Execuções persistidas, histórico e disparo (Priority: P1)

Como gestor da Ouvidoria, preciso que cada rodada de fiscalização seja persistida com data, origem e resumo, consultável no painel e no histórico, com possibilidade de disparo manual e agenda institucional, para rastrear evolução da conformidade ao longo do tempo.

**Why this priority**: Persistência de execuções foi definida como requisito de produto (padrão lotes Cedro); sem histórico, não há accountability de controle interno.

**Independent Test**: Executar fiscalização manual, verificar execução persistida; listar histórico com duas execuções anteriores; tentar segunda execução manual dentro de uma hora e verificar throttling.

**Acceptance Scenarios**:

1. **Given** usuário aciona *Fiscalizar manifestações*, **When** não há execução em andamento e limite horário não foi atingido, **Then** nova **execução de fiscalização** é criada com origem *sob demanda*, analisa 100% das manifestações confirmadas do tenant e persiste resultados por protocolo.
2. **Given** agenda institucional ativa (padrão: diária por tenant), **When** o job executa, **Then** execução é persistida com origem *agendada* e contagem de registros analisados.
3. **Given** múltiplas execuções persistidas, **When** o usuário consulta histórico no painel, **Then** vê lista com data/hora, origem (agendada, sob demanda, ao abrir painel, por registro) e resumo de conformidade — permitindo comparar pelo menos duas execuções anteriores quando existirem.
4. **Given** execução manual já realizada na última hora para o tenant, **When** o usuário tenta *Fiscalizar manifestações* novamente, **Then** recebe mensagem clara de limite de frequência e continua vendo a execução mais recente — sem erro silencioso.
5. **Given** execução em andamento, **When** segunda solicitação chega, **Then** sistema informa processamento em andamento ou aguarda conclusão — uma execução por tenant por vez.

---

### User Story 4 - Rastreabilidade Jatobá (Priority: P1)

Como usuário que precisa confiar no achado ou na checagem, preciso entender como o resultado foi produzido — regra aplicada, campos avaliados, protocolo e período — para validar a classificação antes de agir na Base.

**Why this priority**: Rastreabilidade é regra de plataforma; títulos e comportamento de sheet são canônicos para Jatobá.

**Independent Test**: Abrir rastreio de checagem, achado e pergunta; verificar títulos obrigatórios e ausência de PII em manifestações anônimas.

**Acceptance Scenarios**:

1. **Given** checagem automática exibida, **When** o usuário aciona explicação, **Then** abre sheet inferior (~85% da viewport) com título **Por que esta checagem deu este resultado** — **sem** rota dedicada de rastreio.
2. **Given** achado de inconformidade, **When** o usuário abre rastreio, **Then** sheet usa título **O que gerou este achado** com regra, evidências e protocolo.
3. **Given** fiscalização de um registro no detalhe, **When** o usuário abre rastreio consolidado, **Then** sheet usa título **O que verificamos neste registro** listando checagens aplicadas.
4. **Given** manifestação anônima ou sujeita a sigilo, **When** rastreio é exibido, **Then** **não** revela nome, documento, e-mail ou telefone do manifestante — apenas protocolo, tipo, status operacional e datas.

---

### User Story 5 - Governança: licença, permissão e read-only (Priority: P1)

Como administrador de governança, preciso que apenas usuários autorizados ao módulo Ouvidoria com licença Jatobá acessem fiscalização, e que nenhuma ação Jatobá altere dados operacionais da manifestação.

**Why this priority**: Segurança, separação de eixos (operacional vs conformidade) e conformidade com contrato de licença são bloqueadores para produção.

**Independent Test**: Usuário sem módulo (403); fiscalizar manifestação e verificar que status, prioridade, eventos e campos permanecem idênticos.

**Acceptance Scenarios**:

1. **Given** usuário sem permissão no módulo Ouvidoria, **When** tenta acessar `/ouvidoria/auditoria`, **Then** recebe **403 · Acesso negado** com copy padronizada — item pode permanecer visível na navegação.
2. **Given** usuário autorizado, **When** consome fiscalização, **Then** acesso está condicionado à licença Jatobá ativa no tenant (conjunto fixo de quatro licenças na plataforma).
3. **Given** qualquer ação de fiscalização ou questionário, **When** executada, **Then** status operacional da manifestação (Em análise, Tramitando, Respondida, Encerrada, etc.) **permanece inalterado** — conformidade Jatobá é eixo distinto.
4. **Given** tenant sem manifestações confirmadas, **When** a tela carrega, **Then** estado vazio orienta operação (*registre e confirme manifestações para habilitar fiscalização*) — **sem** achados fabricados.

---

### User Story 6 - Questionários internos (Priority: P2)

Como servidor da Ouvidoria, preciso criar questionários para a equipe interna sobre dados fiscalizados de uma manifestação, coletar respostas via portal autenticado e acompanhar estado do fluxo, para complementar checagens automáticas com validação humana.

**Why this priority**: Questionários internos são parte do escopo Jatobá completo; secundários às checagens automáticas mas necessários para conformidade operacional plena.

**Independent Test**: Criar questionário interno a partir do banco de perguntas, responder autenticado, verificar atualização de estado *Respondido* e reflexo no histórico do painel.

**Acceptance Scenarios**:

1. **Given** manifestação fiscalizada, **When** o servidor aciona *Novo questionário* com destinatário **Interno**, **Then** questionário é criado vinculado ao protocolo com estado de fluxo *Aguardando resposta interna*.
2. **Given** questionário interno pendente, **When** servidor autorizado responde no portal, **Then** respostas são persistidas e estado passa a *Respondido* — **não** confundido com status de conformidade canônico.
3. **Given** questionário respondido, **When** exibido no histórico do painel, **Then** colunas Questionário, Destinatário (*Interno*) e Canal (*Portal interno*) refletem o registro real.

---

### User Story 7 - Questionários externos (manifestante) (Priority: P2)

Como servidor da Ouvidoria, preciso enviar questionários de satisfação ou qualidade ao manifestante identificável, registrando canal (WhatsApp ou E-mail) e coletando resposta via link seguro, para fechar o ciclo de fiscalização com feedback externo quando aplicável.

**Why this priority**: Ouvidoria prevê respondente externo (manifestante) na matriz canônica de licenças; entrega completa exige esse fluxo, com canal simulado na v1.

**Independent Test**: Manifestação identificada com contato → criar questionário externo → obter link/token → responder via formulário público → verificar registro; manifestação anônima → opção externa omitida.

**Acceptance Scenarios**:

1. **Given** manifestação **identificada** com e-mail ou telefone de retorno, **When** o servidor cria questionário com destinatário **Externo**, **Then** sistema registra canal escolhido (WhatsApp ou E-mail), gera **link/token de resposta** e estado *Aguardando resposta externa* — **sem** envio automático por provedor real na v1.
2. **Given** link de resposta externa gerado, **When** o manifestante acessa e submete respostas, **Then** respostas são persistidas e questionário passa a *Respondido*.
3. **Given** manifestação **anônima** ou sem contato utilizável, **When** o servidor tenta criar questionário externo, **Then** opção externa **não é exibida** (UI condicional) — conforme regra de plataforma para elementos indisponíveis.
4. **Given** questionário externo, **When** exibido no painel, **Then** destinatário aparece como *Externo* e canal como *WhatsApp* ou *E-mail* conforme selecionado.

---

### User Story 8 - Banco de perguntas e fiscalização no detalhe (Priority: P2)

Como responsável pelo módulo Ouvidoria, preciso gerenciar o banco de perguntas do domínio e fiscalizar uma manifestação específica a partir do detalhe, para operar conformidade no dia a dia sem depender só do painel agregado.

**Why this priority**: Banco editável e ação contextual completam o escopo Jatobá completo acordado; dependem das checagens e execuções (P1).

**Independent Test**: CRUD de pergunta no banco; abrir detalhe de manifestação → ver card *Fiscalização Jatobá deste registro* → acionar *Fiscalizar dados* → ver checagens atualizadas.

**Acceptance Scenarios**:

1. **Given** usuário com licença Jatobá, **When** acessa gestão do banco de perguntas do módulo Ouvidoria, **Then** pode listar, criar, editar e desativar perguntas com texto, tipo (Sim/Não, escala, descritiva, checklist) e destinatário permitido (interno, externo ou ambos).
2. **Given** banco inicial, **When** tenant é provisionado, **Then** perguntas padrão de ouvidoria estão disponíveis (ex.: conformidade de prazo; satisfação do manifestante).
3. **Given** detalhe de manifestação confirmada, **When** o servidor abre a página, **Then** vê card **Fiscalização Jatobá deste registro** com checagens da última execução para aquele protocolo e link **Abrir tela** para o painel.
4. **Given** card no detalhe, **When** o servidor aciona *Fiscalizar dados*, **Then** execução scoped à manifestação é disparada e resultados atualizados — manifestação operacional **inalterada**.

---

### Edge Cases

- Tenant sem manifestações confirmadas (apenas rascunho ou zero registros): estado vazio; job agendado não cria achados fictícios.
- Manifestação confirmada e encerrada no prazo: checagem de prazo **Conforme**; achados de prazo vencido não aplicáveis.
- SLA por tipo não configurado para um tipo: usar default documentado na spec (Assumptions); registrar no rastreio qual default foi aplicado.
- Falha do job agendado: última execução bem-sucedida permanece visível; usuário informado se execução está desatualizada além de 48h.
- Throttling de execução manual (1x por hora por tenant): mensagem clara; leitura e histórico não contam no limite.
- Execução manual durante job agendado: uma execução por tenant em andamento — segunda solicitação aguarda ou informa processamento.
- Questionário externo expirado ou token inválido: mensagem clara ao manifestante; servidor pode reemitir link.
- Manifestação excluída logicamente após fiscalização: resultados históricos permanecem consultáveis com indicação de registro indisponível.
- Sigilo em denúncias: rastreio e listagens seguem mesma regra de PII que detalhe operacional.
- Categoria TI transversal do banco global: **fora de escopo** — perguntas TI não aparecem neste módulo nesta entrega.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: O sistema **DEVE** fiscalizar manifestações de Ouvidoria usando **exclusivamente** dados internos do tenant (manifestações confirmadas, eventos da linha do tempo, endereços vinculados, anexos e catálogos de assunto/forma de atendimento).
- **FR-002**: Fiscalização **DEVE** ser **somente leitura** em relação ao registro operacional — nenhuma ação Jatobá **DEVE** alterar status operacional, prioridade, campos da manifestação ou eventos da timeline.
- **FR-003**: Classificação de conformidade **DEVE** usar **somente** os quatro status canônicos: **Conforme**, **Não conforme**, **Parcial**, **Pendente**.
- **FR-004**: Estados de fluxo de questionário (*Aguardando resposta interna*, *Aguardando resposta externa*, *Respondido*, *Não iniciado*) **DEVEM** ser distintos de status de conformidade — **NUNCA** exibidos como badge de conformidade.
- **FR-005**: O sistema **DEVE** persistir **execuções de fiscalização** com data/hora, origem (agendada, sob demanda, ao abrir painel, por registro), tenant, quantidade de registros analisados e resumo de conformidade.
- **FR-006**: Cada execução **DEVE** persistir **resultados por manifestação** (protocolo, conformidade agregada, checagens, achados vinculados).
- **FR-007**: O sistema **DEVE** executar fiscalização **agendada periódica** por tenant (padrão: diária).
- **FR-008**: Ao abrir `/ouvidoria/auditoria`, o sistema **DEVE** exibir resultados da execução mais recente concluída.
- **FR-009**: O sistema **DEVE** permitir disparo manual (*Fiscalizar manifestações*) com limite de **uma execução completa por hora por tenant**.
- **FR-010**: O sistema **DEVE** permitir consultar **histórico** de execuções com data, origem e resumo — suportando comparação de pelo menos duas execuções anteriores quando existirem.
- **FR-011**: Checagem de **Prazo de resposta** **DEVE** calcular data limite como data de confirmação da manifestação + dias SLA do **tipo**, conforme configuração do tenant com defaults documentados (Assumptions) — **SEM** campo manual de prazo por registro.
- **FR-012**: Checagem de prazo **DEVE** comparar data limite com eventos de **resposta** e **encerramento** na linha do tempo e status operacional.
- **FR-013**: Checagens **DEVEM** incluir, quando aplicável: **Prazo de resposta**, **Tramitação**, **Completude**, **Canal e contato**, **Anexos e evidências** (resposta formal sem evidência na timeline quando política institucional exige).
- **FR-014**: Conformidade agregada por manifestação **DEVE** refletir o **pior** resultado entre checagens automáticas da execução.
- **FR-015**: Rastreio **DEVE** abrir em **sheet inferior** (~85% da viewport) com títulos canônicos por contexto (checagem, achado, pergunta, registro) — **NUNCA** em rota dedicada.
- **FR-016**: Rastreio e listagens **NÃO DEVEM** expor PII de manifestante anônimo ou sigiloso.
- **FR-017**: Acesso **DEVE** exigir permissão no módulo Ouvidoria; consumo **DEVE** estar sob licença Jatobá.
- **FR-018**: O sistema **DEVE** permitir **CRUD** de perguntas no banco do domínio Ouvidoria (texto, tipo, destinatário permitido, ativo/inativo).
- **FR-019**: O sistema **DEVE** permitir criar **questionários** vinculados a manifestação fiscalizada, com destinatário interno ou externo conforme elegibilidade.
- **FR-020**: Questionários externos **DEVEM** gerar link/token de resposta e registrar canal (WhatsApp ou E-mail) — **SEM** integração real com provedores na v1; equipe repassa link manualmente.
- **FR-021**: Questionário externo **DEVE** ser **omitido** da interface quando manifestante for anônimo ou sem contato utilizável — **NUNCA** exibido desabilitado.
- **FR-022**: Respostas a questionários **DEVEM** ser persistidas e refletidas no histórico do painel (colunas Questionário, Destinatário, Canal, Problemas/conformidade relacionada quando aplicável).
- **FR-023**: Detalhe da manifestação **DEVE** exibir card **Fiscalização Jatobá deste registro** com checagens da última execução e ação *Fiscalizar dados* scoped ao registro.
- **FR-024**: UI **DEVE** exibir badge **Somente leitura** no contexto Jatobá — **NUNCA** *Read-only* em UI pt-BR.
- **FR-025**: Escopo **limita-se** ao módulo Ouvidoria (`/ouvidoria/auditoria` + detalhe de manifestação) — **NÃO** inclui Central global de Fiscalização, score Carvalho, Insights Cedro ou Pau-Brasil.

### Fronteiras entre licenças (obrigatório)

| Licença | O que faz neste contexto | O que **NÃO** faz |
| --- | --- | --- |
| **Base** | CRUD, tramitação, resposta, encerramento, status operacional, timeline | Classificar conformidade; enviar questionários Jatobá |
| **Jatobá (esta feature)** | Checagens registro-a-registro; achados; questionários; banco de perguntas do domínio; SLA/prazo por registro | Alterar registros; score Carvalho; insights Cedro |
| **Carvalho** | Score de maturidade macro; planos de ação (consome indicadores Jatobá em feature futura) | Fiscalizar registro a registro nesta entrega |
| **Cedro** | Insights estratégicos read-only (feature 007) | Conformidade operacional; questionários; achados táticos |

### Key Entities

- **Execução de fiscalização**: rodada de análise com instante, origem, tenant, quantidade de registros analisados, resumo de conformidade (contagens por status) e referência aos resultados filhos.
- **Resultado de fiscalização (por manifestação)**: vínculo protocolo ↔ execução; conformidade agregada; lista de checagens e achados daquele registro na execução.
- **Checagem automática**: regra nomeada (ex.: Prazo de resposta), descrição da regra, campos avaliados, status de conformidade resultante e metadados para rastreio.
- **Achado**: problema ou inconformidade detectada; título, descrição, checagem de origem, status de conformidade, protocolo afetado.
- **Configuração SLA**: dias de prazo por tipo de manifestação por tenant; defaults institucionais quando não configurado.
- **Pergunta do banco (Ouvidoria)**: texto, tipo de resposta esperada, destinatários permitidos (interno/externo/ambos), flag ativo.
- **Questionário**: conjunto de perguntas aplicadas a uma manifestação; destinatário (interno/externo); canal; estado de fluxo; vínculo à execução ou achado quando aplicável.
- **Resposta de questionário**: respostas por pergunta; autor (interno autenticado ou externo via token); data/hora.
- **Dispatch externo (v1)**: registro de canal escolhido, token/link gerado, data de criação — sem confirmação de entrega por provedor.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Usuário autorizado alcança o painel Fiscalização em **≤ 3 cliques** a partir do overview de Ouvidoria.
- **SC-002**: Execução manual completa analisa **100%** das manifestações confirmadas do tenant em **≤ 30 segundos** para até **500** registros confirmados.
- **SC-003**: **100%** dos achados e checagens exibidos possuem rastreio explicativo acessível via sheet.
- **SC-004**: **Nenhuma** ação de fiscalização ou questionário altera status operacional, prioridade ou eventos da manifestação — validável comparando registro antes e depois.
- **SC-005**: **100%** dos rastreios abrem em sheet inferior — **zero** navegação a rota dedicada de rastreio.
- **SC-006**: Em teste com manifestações anônimas, **zero** exposição de PII em achados, checagens agregadas e rastreio.
- **SC-007**: Questionário externo **só** é oferecido quando manifestante identificável com contato — **zero** tentativas externas para anônimos na UI.
- **SC-008**: Demonstração ponta a ponta (registrar → confirmar → fiscalizar → ver achado → questionário interno → responder) concluída em **≤ 15 minutos** por usuário sem treinamento prévio.
- **SC-009**: Quando existem ≥ 3 execuções persistidas, o usuário **DEVE** poder visualizar e comparar pelo menos **2 execuções anteriores** à mais recente no histórico.

## Assumptions

- **Manifestações fiscalizadas**: apenas registros **confirmados** (status diferente de rascunho e não excluídos logicamente) entram nas execuções.
- **Data base do SLA**: data/hora de confirmação da manifestação (momento em que deixa de ser rascunho).
- **Defaults SLA por tipo** (dias corridos, ajustáveis por tenant):

  | Tipo (UI) | Dias default |
  | --- | --- |
  | Reclamação | 30 |
  | Solicitação | 30 |
  | Denúncia | 60 |
  | Elogio | 15 |
  | Sugestão | 15 |
  | Simplifique | 15 |

- **Proximidade de prazo**: checagem **Parcial** quando restam ≤ 20% dos dias do SLA sem evento de resposta.
- **Agenda**: execução diária por tenant; falha não apaga histórico anterior.
- **Throttling**: uma execução manual completa por tenant por hora; execução scoped a um registro **PODE** contar no mesmo limite ou ter limite separado — decisão na fase plan (padrão: mesmo limite horário por tenant).
- **Canais externos v1**: WhatsApp e E-mail registrados como metadado; link/token copiável pela equipe; formulário público tokenizado para resposta — **sem** Twilio, WhatsApp Business API ou SMTP transacional.
- **Sigilo e anonimato**: mesmas regras de visibilidade de PII do módulo Base e feature Cedro aplicam-se a rastreio e questionários.
- **Dependências**: módulo Ouvidoria Base (003-ouvidoria), endereço canônico (006) e catálogos de assunto/forma de atendimento disponíveis para leitura.
- **Conjunto de licenças**: tenant possui as quatro licenças fixas; Jatobá sempre presente quando feature visível.

## Out of Scope

- Central global de Fiscalização (`/global/auditoria`) e banco de perguntas TI transversal.
- Integração real WhatsApp Business, SMS ou SMTP transacional.
- Score Carvalho, planos de ação de maturidade e alimentação automática de indicadores.
- Insights Cedro (feature 007) e Pau-Brasil (modelos de resposta).
- Campo manual `prazoResposta` por manifestação; reintrodução de `esfera`, `origem`, `canal` ou `sigilo` persistidos da spec 003 v1.
- SPA pública de envio de manifestação e consulta de andamento sem autenticação (exceto formulário tokenizado de resposta a questionário externo).
- Alteração de registros operacionais a partir de achados ou respostas de questionário.
- Exportação PDF de relatório de fiscalização.
