# Feature Specification: Tramitação — Demandas SIGED e Licenças

**Feature Branch**: `005-tramitacao-siged-licencas`

**Created**: 2026-06-17

**Status**: Completed

**Input**: User description: "Aplicar Insights IA (Cedro), Fiscalização (Jatobá) e Maturidade (Carvalho) ao módulo Tramitação em forma mock demonstração interativa. Receber demandas do SIGED da Prefeitura de Manaus (processos e documentos vinculados). Controle interno de documentos e processos tramitados entre setores. Rota principal /tramitacao/demandas. Somente mock no client, sem API nova. Todas as quatro licenças (incluindo Pau-Brasil). Todos os setores operam suas demandas com dashboard consolidado."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Receber e distinguir demandas SIGED na inbox (Priority: P1)

Como servidor de qualquer setor da instituição, preciso visualizar na caixa de entrada de Demandas as tramitações recebidas do SIGED da Prefeitura de Manaus — com processo administrativo e documentos vinculados claramente identificados — para dar continuidade ao controle interno sem confundir origem externa com tramitações internas entre setores.

**Why this priority**: A integração institucional com o SIGED é o diferencial desta entrega; sem distinção visual e metadados do processo/documento, o valor da demonstração para Manaus não se materializa.

**Independent Test**: Pode ser testado abrindo `/tramitacao/demandas`, localizando demandas com origem SIGED na lista e verificando protocolo externo, tipo de processo, secretaria de origem, documentos vinculados e setor destino — sem qualquer integração real com sistemas externos.

**Acceptance Scenarios**:

1. **Given** demandas mock na inbox incluindo origem SIGED e origem Interna, **When** o servidor abre a lista de recebidas, **Then** cada demanda SIGED exibe identificador visual obrigatório (ex.: badge **SIGED**) distinto das demandas internas.
2. **Given** uma demanda de origem SIGED, **When** o servidor abre o detalhe da thread, **Then** vê snapshot do **processo** (número/protocolo SIGED, tipo processual, secretaria de origem, assunto) e dos **documentos** vinculados (tipo documental, número, status de assinatura).
3. **Given** uma demanda SIGED destinada ao setor Jurídico, **When** servidor lotado no Jurídico acessa a pasta contextual do setor, **Then** a demanda aparece em recebidas; servidor de setor não destinatário não a vê na pasta ativa do próprio setor (salvo visão consolidada no dashboard institucional).
4. **Given** copy da interface, **When** o servidor lê metadados SIGED, **Then** vê rótulos institucionais da Prefeitura de Manaus (ex.: referência ao SIGED municipal) — sem expor credenciais ou URLs de integração real.

---

### User Story 2 - Operar tramitação inter-setorial na inbox (Priority: P1)

Como servidor autenticado, preciso compor, responder, encaminhar e arquivar demandas entre setores na caixa de entrada — com pastas recebidas, enviadas e arquivadas, prazos operacionais, histórico de encaminhamento e conversa — para transportar informações e documentos entre unidades da instituição.

**Why this priority**: Tramitação é o núcleo operacional da Base do módulo; a inbox já existe em protótipo e esta spec formaliza e estende o fluxo como transporte central entre setores.

**Independent Test**: Pode ser testado navegando pastas, abrindo uma demanda, respondendo na thread, encaminhando a outro setor com observação e verificando registro no histórico de encaminhamento e na conversa — sem depender de SIGED ou licenças.

**Acceptance Scenarios**:

1. **Given** a tela Demandas, **When** o servidor alterna entre pastas **Recebidas**, **Enviadas** e **Arquivadas**, **Then** cada pasta lista apenas demandas correspondentes ao contexto do setor ativo.
2. **Given** uma demanda em recebidas, **When** o servidor aciona **Responder** ou **Encaminhar** informando setor destino e texto, **Then** o evento aparece no histórico de conversa ou encaminhamento com autor, data e destinatários.
3. **Given** ação **Compor**, **When** o servidor preenche assunto, destinatários (um ou mais setores), corpo e prazo opcional, **Then** nova demanda aparece em enviadas do remetente e recebidas do destinatário.
4. **Given** demanda com prazo operacional definido, **When** exibida na lista ou detalhe, **Then** status operacional reflete situação (*Pendente*, *Tramitando*, *Crítico*, *Vencendo*) conforme regras da Base — **sem** misturar com conformidade Jatobá.
5. **Given** demanda vinculada a registro de outro módulo (ex.: manifestação OUV-2026-0142), **When** o servidor abre o detalhe, **Then** vê snapshot do registro vinculado com atalho para contexto — sem alterar o registro de origem.

---

### User Story 3 - Dashboard consolidado de demandas (Priority: P1)

Como servidor de qualquer setor, preciso consultar um dashboard institucional com volume, resolutividade, pendentes e distribuição por origem (SIGED vs interna), filtrável por setor, para acompanhar o controle interno do fluxo documental sem depender de relatórios manuais por unidade.

**Why this priority**: Todos os setores precisam de visão consolidada além da operação individual na inbox; o dashboard substitui múltiplos painéis dispersos por setor.

**Independent Test**: Pode ser testado abrindo `/tramitacao/dashboard`, aplicando filtro por setor e verificando KPIs e gráficos de volume e resolutividade com segregação SIGED/interna.

**Acceptance Scenarios**:

1. **Given** dados mock de tramitações do ano corrente, **When** o servidor abre o dashboard, **Then** vê cards operacionais: total de tramitações, pendentes, em análise, resolutividade percentual.
2. **Given** o dashboard, **When** o servidor aplica filtro por setor (ex.: Jurídico), **Then** KPIs e gráficos refletem apenas demandas daquele contexto setorial.
3. **Given** mix de demandas SIGED e internas, **When** o dashboard exibe indicadores, **Then** permite distinguir volume ou proporção por origem sem abrir cada demanda individualmente.
4. **Given** regras de prazo da Base (§7 regras-plataforma), **When** há demandas com prazo vencido ou crítico, **Then** o dashboard destaca volume de pendências — responsabilidade operacional da Base, não de Carvalho ou Cedro.

---

### User Story 4 - Fiscalizar demandas com Jatobá (Priority: P1)

Como servidor responsável pelo controle interno, preciso fiscalizar demandas de tramitação (incluindo as originadas no SIGED) quanto a prazos de tramitação, assinaturas pendentes e conformidade de encaminhamento, para identificar não conformidades registro a registro sem alterar os dados tramitados.

**Why this priority**: Jatobá é a camada de conformidade operacional; tramitação sem fiscalização não demonstra o valor do produto para controle interno institucional.

**Independent Test**: Pode ser testado abrindo `/tramitacao/auditoria`, listando checagens por demanda e abrindo sheet **Por que esta checagem deu este resultado** — verificando status ∈ {Conforme, Não conforme, Parcial, Pendente}.

**Acceptance Scenarios**:

1. **Given** painel **Fiscalização** do módulo Tramitação, **When** o servidor abre a lista, **Then** vê colunas: demanda/registro, dados fiscalizados, questionário, destinatário, canal, conformidade (badge), problemas.
2. **Given** demanda com prazo de tramitação acima da meta institucional (ex.: 2 dias úteis), **When** a checagem Jatobá é exibida, **Then** conformidade é **Não conforme** ou **Parcial** com achado descritivo — **nunca** altera a demanda na Base.
3. **Given** demanda SIGED com documento de assinatura pendente, **When** fiscalizada, **Then** achado referencia o documento vinculado e status de assinatura.
4. **Given** questionário Jatobá no módulo Tramitação, **When** disponível, **Then** respondente é **somente interno** (portal interno ou e-mail institucional) — sem canal externo WhatsApp para terceiros.
5. **Given** resultado de checagem, **When** o servidor aciona **Como chegamos aqui?**, **Then** abre sheet com título **Por que esta checagem deu este resultado** e passos de rastreabilidade mock.

---

### User Story 5 - Consultar insights Cedro sobre tramitação (Priority: P2)

Como gestor ou servidor, preciso consultar insights estratégicos read-only sobre eficiência do fluxo de demandas, gargalos entre setores e tendências SIGED versus tramitação interna, para apoiar decisões de melhoria sem que a IA altere registros.

**Why this priority**: Cedro complementa a operação com visão estratégica; secundário ao fluxo operacional mas necessário para demonstração completa das licenças.

**Independent Test**: Pode ser testado abrindo `/tramitacao/insights`, listando insights ativos e abrindo sheet **De onde veio este insight** — confirmando badge **Somente leitura** e ausência de ações que modifiquem demandas.

**Acceptance Scenarios**:

1. **Given** tela **Insights IA** do módulo Tramitação, **When** o servidor abre a lista, **Then** vê insights consultivos com impacto ∈ {Crítico, Alto, Médio} e descrição legível.
2. **Given** insight sobre gargalo entre setores, **When** o servidor abre o detalhe, **Then** vê cruzamento de dados internos (volume, tempos) com referências externas mock (benchmarks institucionais) — sem alterar demandas.
3. **Given** insight relacionado a volume SIGED, **When** exibido, **Then** distingue origem externa de tramitação interna na narrativa do insight.
4. **Given** qualquer ação Cedro, **When** o servidor interage, **Then** interface exibe **Somente leitura** — Cedro **nunca** substitui classificação de conformidade da Jatobá.

---

### User Story 6 - Avaliar maturidade Carvalho do módulo Tramitação (Priority: P2)

Como gestor institucional, preciso visualizar score de maturidade do fluxo de demandas nos eixos Controle Interno, Governança e TI — com contribuição dos indicadores Jatobá e planos de ação rastreáveis — para diagnóstico macro do transporte documental entre setores.

**Why this priority**: Carvalho agrega visão institucional; complementa Jatobá (micro) com maturidade (macro) exigida pelo modelo de produto.

**Independent Test**: Pode ser testado abrindo `/tramitacao/maturidade`, verificando score por eixo, radar ou cards e sheet **Como calculamos este score**.

**Acceptance Scenarios**:

1. **Given** tela **Maturidade** do módulo Tramitação, **When** o servidor abre o painel, **Then** vê score híbrido e decomposição nos eixos **Controle Interno**, **Governança** e **TI**.
2. **Given** indicadores de conformidade Jatobá no módulo, **When** o score Carvalho é calculado (mock), **Then** exibe contribuição percentual da camada Jatobá no score — Carvalho **nunca** fiscaliza registro a registro.
3. **Given** plano de ação de maturidade, **When** listado, **Then** inclui responsável, prazo e vínculo rastreável ao eixo — ação estratégica, não correção tática de demanda individual.
4. **Given** botão de explicação, **When** acionado, **Then** abre sheet **Como calculamos este score** com passos de rastreabilidade mock.

---

### User Story 7 - Produzir documentos com Pau-Brasil na composição (Priority: P2)

Como servidor ao compor ou responder uma demanda, preciso usar modelos normativos (ofício, memorando, despacho) e visualizar alertas de prazo de tramitação previstos em normas, para agilizar a produção documental sem confundir com fiscalização de conformidade.

**Why this priority**: Pau-Brasil completa o conjunto das quatro licenças no módulo; modelos contextualizam a composição de demandas inter-setoriais.

**Independent Test**: Pode ser testado na ação **Compor** ou painel Pau-Brasil, selecionando modelo de ofício/memorando e verificando pré-preenchimento contextual — Pau-Brasil **nunca** classifica conformidade.

**Acceptance Scenarios**:

1. **Given** fluxo de composição de demanda, **When** o servidor aciona **Usar modelo** (Pau-Brasil), **Then** pode escolher entre modelos institucionais: ofício, memorando, despacho — com campos pré-preenchidos a partir do contexto da demanda.
2. **Given** alerta normativo de prazo de tramitação (Pau-Brasil), **When** exibido na lista ou composição, **Then** descreve impacto documental/normativo imediato — **sem** substituir campo de prazo operacional da Base nem checagem SLA da Jatobá.
3. **Given** modelo aplicado, **When** confirmado, **Then** conteúdo compõe o corpo da demanda na Base — assinatura normativa Pau-Brasil permanece distinta da assinatura operacional da Base quando aplicável.

---

### User Story 8 - Alertas de licença e rastreabilidade na inbox (Priority: P2)

Como servidor na tela Demandas, preciso ver barra de alertas das licenças quando houver pontos críticos ou de atenção, com atalhos para Fiscalização, Insights IA e Maturidade deste módulo, e explicar qualquer resultado via sheets de rastreabilidade padronizados.

**Why this priority**: Paridade com outros módulos mock; garante que a demonstração interativa respeita vocabulário e UX normativos da plataforma.

**Independent Test**: Pode ser testado abrindo Demandas com dados mock que gerem alerta Jatobá crítico, verificando barra **Alertas ativos nas licenças** e navegação para telas de licença — sem chips na tabela principal.

**Acceptance Scenarios**:

1. **Given** demandas com achados Jatobá críticos no módulo, **When** o servidor abre `/tramitacao/demandas`, **Then** exibe barra **Alertas ativos nas licenças** com subtítulo *Atalhos para Fiscalização, Insights IA e Maturidade deste módulo.* — chips somente para licenças em estado warning ou critical.
2. **Given** nenhum alerta de licença ativo, **When** a inbox carrega, **Then** a barra de alertas **não** é exibida.
3. **Given** qualquer resultado de licença na demonstração, **When** o usuário solicita explicação, **Then** títulos de sheet seguem §1.7 de regras-plataforma (ex.: **De onde veio este insight**, **Como calculamos este score**).
4. **Given** lista de demandas, **When** exibida, **Then** alertas de licença **não** aparecem como colunas ou chips na tabela — apenas na barra superior conforme §4 regras-plataforma.

---

### User Story 9 - Ações de licença no detalhe da demanda (Priority: P3)

Como servidor analisando uma demanda específica, preciso acionar atalhos contextuais de fiscalização, consulta IA e visualização de impacto na maturidade a partir do detalhe da thread, para demonstração interativa ponta a ponta sem sair do fluxo operacional.

**Why this priority**: Refinamento de UX para demo; depende das telas de licença (P1/P2) estarem definidas.

**Independent Test**: Pode ser testado abrindo detalhe de demanda com achado aberto, acionando **Fiscalizar dados** ou **Consultar IA** e verificando painéis contextuais read-only ou sheets — sem persistência real além do mock.

**Acceptance Scenarios**:

1. **Given** detalhe de demanda com registro fiscalizável, **When** o servidor aciona checagem Jatobá contextual, **Then** exibe resultado de conformidade e link para painel de Fiscalização — sem alterar a demanda.
2. **Given** detalhe de demanda, **When** o servidor aciona consulta Cedro contextual, **Then** exibe insight read-only relacionado à thread — badge **Somente leitura**.
3. **Given** filtro de licença ativo na UI, **When** ação de licença não se aplica ao contexto, **Then** o elemento **não é exibido** — nunca aparece desabilitado só para indicar indisponibilidade.

---

### Edge Cases

- Demanda SIGED chega sem documentos vinculados: exibe processo com indicador de ausência de anexos documentais — não bloqueia recebimento na inbox.
- Encaminhamento para múltiplos setores: todos os destinatários veem em recebidas; resposta pode ser direcionada a subconjunto com registro na conversa.
- Composição interrompida: rascunho local (sessão) pode ser recuperado conforme comportamento mock existente; sem persistência em servidor.
- Demanda arquivada: permanece consultável em **Arquivadas**; novas respostas exigem desarquivar ou regra mock de bloqueio com mensagem clara.
- Setor não membro tenta compor em nome de outro setor: composição usa contexto do setor ativo do usuário.
- Prazo operacional no passado na composição: sistema alerta com confirmação explícita antes de enviar.
- Insight Cedro e achado Jatobá sobre mesma demanda: coexistem com propósitos distintos — operacional vs estratégico; UI não contradiz classificação Jatobá com texto Cedro.
- Filtro de licença restringe painéis visíveis mas **não** remove navegação Base (Demandas, Dashboard) da sidebar.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: O sistema MUST exibir inbox de Demandas em `/tramitacao/demandas` com pastas **Recebidas**, **Enviadas** e **Arquivadas**, contextualizadas por setor ativo do usuário.
- **FR-002**: O sistema MUST permitir **Compor**, **Responder**, **Encaminhar** e **Arquivar** demandas, registrando eventos em histórico de conversa e/ou encaminhamento com autor, data, destinatários e texto.
- **FR-003**: O sistema MUST distinguir origem da demanda ∈ {**Interna**, **SIGED**} com identificador visual obrigatório para origem SIGED em lista e detalhe.
- **FR-004**: Demandas de origem SIGED MUST incluir snapshot de **processo administrativo** (protocolo/número SIGED, tipo processual, secretaria de origem, assunto, status) e de **documentos vinculados** (tipo, número, status de assinatura) — demonstração mock sem integração real.
- **FR-005**: O sistema MUST exibir dashboard consolidado em `/tramitacao/dashboard` com KPIs operacionais (volume, pendentes, em análise, resolutividade) e segregação SIGED vs interna, filtrável por setor.
- **FR-006**: O sistema MUST manter status operacionais da Base distintos de conformidade Jatobá: operacionais incluem *Pendente*, *Tramitando*, *Crítico*, *Vencendo*, *Respondido*, *Arquivado*; conformidade Jatobá ∈ {Conforme, Não conforme, Parcial, Pendente} apenas em telas de fiscalização.
- **FR-007**: O sistema MUST calcular *Crítico* e *Vencendo* com base em prazo operacional da demanda e data corrente — responsabilidade da Base (§7 regras-plataforma).
- **FR-008**: O sistema MUST exibir painel **Fiscalização** em `/tramitacao/auditoria` (Jatobá) com fiscalização de tramitação inter-setorial, prazos (meta SLA institucional mock, ex.: 2 dias úteis) e assinaturas pendentes em documentos SIGED.
- **FR-009**: Questionários Jatobá no módulo Tramitação MUST ser **somente internos** — sem canal externo para terceiros.
- **FR-010**: Jatobá MUST sinalizar achados e conformidade **sem alterar** registros de demanda na Base.
- **FR-011**: O sistema MUST exibir tela **Insights IA** em `/tramitacao/insights` (Cedro) com insights consultivos read-only sobre eficiência, gargalos e tendências SIGED×interno.
- **FR-012**: Cedro MUST operar em modo **somente leitura** e MUST NOT substituir classificação de conformidade da Jatobá.
- **FR-013**: O sistema MUST exibir tela **Maturidade** em `/tramitacao/maturidade` (Carvalho) com score híbrido nos eixos Controle Interno, Governança e TI, contribuição Jatobá e planos de ação rastreáveis.
- **FR-014**: Carvalho MUST agregar visão macro e MUST NOT fiscalizar demanda a demanda nem alterar status operacional de registros.
- **FR-015**: O sistema MUST oferecer modelos Pau-Brasil (ofício, memorando, despacho) na composição de demandas e alertas normativos de prazo de tramitação — Pau-Brasil MUST NOT classificar conformidade.
- **FR-016**: O sistema MUST exibir barra de alertas de licenças na inbox quando houver alertas warning ou critical, com copy e comportamento conforme §1.9 e §4 regras-plataforma.
- **FR-017**: O sistema MUST oferecer sheets de rastreabilidade com títulos canônicos (§1.7 regras-plataforma) para resultados Jatobá, Cedro e Carvalho no módulo.
- **FR-018**: O sistema MUST permitir vincular demandas a registros de outros módulos (snapshot read-only, ex.: protocolo de manifestação) sem alterar o registro de origem.
- **FR-019**: O módulo Tramitação MUST permanecer **aberto** a todos os setores autenticados — sem restrição por vínculo módulo–setor.
- **FR-020**: O sistema MUST usar vocabulário canônico: **Insights IA** ou **Insights Cedro**, **Fiscalização**, **Maturidade**, **Pau-Brasil**, **Base**, status e copy conforme regras-plataforma e licencas-canonicas.
- **FR-021**: O sistema MUST NOT incluir nesta entrega: integração real com SIGED (API, webhook, autenticação), endpoints novos de tramitação no backend, alterações ao módulo Protocolo Virtual, persistência server-side de demandas, SPA pública de consulta.
- **FR-022**: Dados da demonstração MUST ser mock interativo no client, podendo usar armazenamento local de sessão para rascunhos de composição — sem exigir API de tramitação.

### Key Entities

- **Demanda**: Thread de tramitação inter-setorial; atributos: assunto, corpo, origem (Interna | SIGED), pasta (recebidas | enviadas | arquivadas), setor contexto, remetente, destinatários, tags, prazo operacional, status operacional, anexos (contagem), identificador de mensagem.
- **ProcessoSIGED**: Snapshot externo vinculado à demanda SIGED; protocolo SIGED, tipo processual, secretaria de origem, assunto, status processual, data de recebimento mock.
- **DocumentoSIGED**: Snapshot documental vinculado ao processo; tipo (ofício, memorando, despacho, etc.), número, status de assinatura (pendente, concluída), referência ao processo.
- **Encaminhamento**: Evento no histórico de encaminhamento; origem, destino, assunto, corpo, data, tags, prazo opcional.
- **MensagemConversa**: Evento no histórico de conversa; resposta em thread com mesmos metadados de encaminhamento quando aplicável.
- **RegistroVinculado**: Snapshot opcional de registro de outro módulo (tipo, número, status, data do snapshot) — ligação informativa sem sincronização bidirecional.
- **ChecagemJatoba**: Resultado de fiscalização por demanda; conformidade, achados, questionário, canal interno, rastreabilidade.
- **InsightCedro**: Recomendação estratégica read-only; impacto, fontes internas e externas mock, passos de raciocínio, rastreabilidade.
- **ScoreCarvalho**: Maturidade do módulo Tramitação; scores por eixo, contribuição Jatobá, planos de ação, rastreabilidade.
- **ModeloPauBrasil**: Modelo normativo aplicável na composição; tipo documental, campos pré-preenchidos, alertas legislativos associados.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Servidor de qualquer setor identifica demanda SIGED vs interna em menos de 5 segundos na inbox em 100% dos casos de teste de aceitação.
- **SC-002**: Demonstração completa do fluxo (receber SIGED → encaminhar → fiscalizar → consultar insight → ver maturidade) concluída em menos de 10 minutos por usuário sem treinamento prévio.
- **SC-003**: 100% dos status de conformidade Jatobá exibidos no módulo pertencem ao conjunto {Conforme, Não conforme, Parcial, Pendente}.
- **SC-004**: Zero violações das regras **NUNCA** de regras-plataforma §2 em revisão de copy e comportamento da demonstração mock.
- **SC-005**: 95% dos participantes de teste de usabilidade localizam atalhos para Fiscalização, Insights IA e Maturidade a partir da barra de alertas ou navegação do módulo em uma única tentativa.
- **SC-006**: 100% das ações Cedro na demonstração são claramente read-only — nenhuma altera conteúdo ou status de demanda em testes de aceitação.
- **SC-007**: Dashboard reflete filtro por setor corretamente em 100% dos cenários mock com demandas multi-setoriais.

## Assumptions

- Tenant de demonstração configurado para contexto **Prefeitura de Manaus**; rótulos SIGED são institucionais e fictícios para mock — sem credenciais ou endpoints reais.
- Módulo `tramitacao` permanece em `OPEN_MODULES` (acesso irrestrito por setor) conforme spec 002-auth-setor-permissao.
- Tramitação é o **transporte** de informações entre setores; Protocolo Virtual permanece módulo separado e fora desta entrega.
- SIGED envia processos administrativos **e** documentos vinculados; simulação visual na inbox substitui integração real nesta fase.
- Todos os setores operam suas demandas; dashboard oferece visão consolidada institucional filtrável.
- As quatro licenças (Carvalho, Pau-Brasil, Jatobá, Cedro) mais Base aplicam-se ao módulo Tramitação conforme modelo de produto universal (R-03 regras-plataforma).
- Meta SLA de tramitação para Jatobá mock: 2 dias úteis — alinhada ao exemplo canônico do módulo Protocolo em regras-plataforma §7.5, adaptada ao domínio Tramitação.
- Implementação futura com API real e pasta `modules/tramitacao/` espelhando backend será tratada em plano separado; esta spec define apenas demonstração interativa mock.
- Copy e rastreabilidade seguem traceability-mock.md e regras-plataforma.md literalmente.
- Rascunhos de composição podem reutilizar mecanismo local existente de tramitação entre módulos; sem novos requisitos de persistência server-side.
