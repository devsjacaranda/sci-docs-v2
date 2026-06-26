# Feature Specification: Módulo IT — Segurança da Informação

**Feature Branch**: `022-it-seguranca-informacao`

**Created**: 2026-06-25

**Status**: Draft

**Input**: User description: "Desenvolver módulo e setor Segurança da Informação (IT). Parte 1 — Gestão (Base): dashboard operacional, CRUD de ativos TI, incidentes de segurança, operadores e tratamento LGPD. Parte 2 — Controle Interno: Insights Cedro (análise de configurações, classificador LGPD, matriz de risco), Fiscalização Jatobá (workflow backup, trilha de auditoria, gerador ANPD), Maturidade Carvalho (linhas de defesa, aderência LGPD/CIS, índice de vulnerabilidade por secretaria)."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Cadastrar e gerenciar ativos de TI (Priority: P1)

Como gestor de TI ou CISO, preciso cadastrar, editar, consultar, excluir logicamente e restaurar **ativos de TI** (servidores, computadores, licenças de software, bancos de dados e sistemas), com **tags** e **vínculos entre ativos** (ex.: Servidor X roda Sistema Y que usa Banco de Dados Z), para manter inventário confiável da infraestrutura institucional.

**Why this priority**: Inventário de ativos é a fundação operacional do módulo; incidentes, LGPD, insights e maturidade dependem de registros de ativos existentes.

**Independent Test**: Autenticar usuário com permissão no módulo IT; criar ativos de tipos distintos; vincular servidor → sistema → banco de dados; aplicar soft delete e restaurar; verificar listagem e detalhe com vínculos.

**Acceptance Scenarios**:

1. **Given** usuário com permissão no módulo IT, **When** acessa a lista de ativos, **Then** vê tela operacional com cards de estatística (Total, por tipo), filtros e tabela com coluna **Ações** via menu ⋮.
2. **Given** formulário de novo ativo, **When** o usuário preenche campos obrigatórios (tipo, nome, identificador, secretaria responsável) e salva, **Then** ativo é persistido e aparece na listagem.
3. **Given** ativo existente, **When** o usuário edita atributos ou adiciona tags, **Then** alterações são salvas com registro de autor e data/hora.
4. **Given** ativo com vínculos configurados, **When** o usuário abre detalhe, **Then** vê grafo ou lista de dependências (ex.: *Este servidor hospeda o Sistema RH*).
5. **Given** ativo ativo, **When** o usuário aciona exclusão, **Then** ativo recebe soft delete — **não** aparece na listagem padrão, mas pode ser restaurado.
6. **Given** ativo excluído logicamente, **When** o usuário aciona restaurar, **Then** ativo volta à listagem com histórico preservado.

---

### User Story 2 - Registrar incidentes de segurança (Priority: P1)

Como analista de segurança ou gestor de TI, preciso registrar **incidentes de segurança** com campos estruturados (data, criticidade, tipo de ameaça, secretaria afetada, descrição e logs de erro), para documentar ocorrências e alimentar dashboards, fiscalização e maturidade.

**Why this priority**: Incidentes são evento central de segurança; alimentam linhas de defesa, índice por secretaria e gerador ANPD.

**Independent Test**: Criar incidente com todos os campos; vincular a ativo e secretaria; alterar status de aberto para resolvido informando linha de defesa; verificar persistência e exibição na listagem.

**Acceptance Scenarios**:

1. **Given** usuário autorizado, **When** registra incidente preenchendo data, criticidade (*Leve*, *Moderada*, *Crítica*), tipo de ameaça, secretaria afetada e descrição, **Then** incidente é persistido com status **Aberto**.
2. **Given** incidente em edição, **When** o usuário anexa ou cola logs de erro, **Then** conteúdo é armazenado vinculado ao incidente — consultável no detalhe.
3. **Given** incidente vinculado a ativo TI, **When** o detalhe do ativo é aberto, **Then** incidentes relacionados são listados — **sem** duplicar cadastro.
4. **Given** incidente resolvido, **When** o usuário informa data de resolução e campo **Resolvido por** (linha de defesa), **Then** status muda para **Resolvido** e alimenta indicadores Carvalho.
5. **Given** campos obrigatórios ausentes, **When** o usuário tenta salvar, **Then** validação impede envio com indicação dos campos pendentes.

---

### User Story 3 - Mapear operadores e tratamento de dados LGPD (Priority: P2)

Como gestor de TI ou encarregado de dados, preciso cadastrar **operadores de tratamento** vinculando cada **sistema operacional** às **categorias de dados sensíveis** que manipula (CPF, dados de saúde, relatórios financeiros etc.), para calcular conformidade LGPD e alimentar o classificador Cedro.

**Why this priority**: Mapeamento LGPD é pré-requisito para percentual de conformidade no dashboard e para insights de classificação; secundário ao inventário e incidentes.

**Independent Test**: Vincular sistema cadastrado a categorias de dados sensíveis; verificar cálculo de percentual LGPD no dashboard; editar mapeamento e confirmar atualização imediata do indicador.

**Acceptance Scenarios**:

1. **Given** sistema cadastrado como ativo TI, **When** o usuário abre mapeamento LGPD, **Then** pode selecionar uma ou mais categorias de dados sensíveis pré-cadastradas (ex.: CPF, saúde, financeiro).
2. **Given** mapeamento salvo, **When** o dashboard operacional carrega, **Then** percentual de conformidade LGPD reflete regras de campos preenchidos (sistemas com categorias mapeadas ÷ total de sistemas).
3. **Given** sistema sem categorias mapeadas, **When** exibido na listagem de conformidade, **Then** aparece como **Pendente** ou equivalente operacional — **não** como conforme.
4. **Given** operador externo (terceiro), **When** cadastrado, **Then** pode ser vinculado a sistemas com indicação de papel (*Controlador*, *Operador*, *Suboperador*) conforme vocabulário LGPD institucional.

---

### User Story 4 - Visualizar dashboard operacional (Priority: P2)

Como gestor de TI ou CISO, preciso de um **dashboard operacional** com volumetria de ativos cadastrados, total de incidentes com status **Aberto** e percentual de conformidade LGPD geral, para visão imediata da saúde operacional do setor.

**Why this priority**: Dashboard consolida valor da Base; depende de ativos, incidentes e mapeamento LGPD já cadastrados.

**Independent Test**: Popular tenant com ativos, incidentes abertos e mapeamentos LGPD parciais; abrir dashboard; verificar três indicadores principais e cards derivados.

**Acceptance Scenarios**:

1. **Given** tenant com ativos cadastrados, **When** o dashboard carrega, **Then** exibe contagem total e distribuição por tipo de ativo (servidor, computador, licença, banco de dados, sistema).
2. **Given** incidentes com status **Aberto**, **When** o dashboard carrega, **Then** exibe total de incidentes abertos e destaque para incidentes **Críticos**.
3. **Given** mapeamentos LGPD parciais, **When** o dashboard carrega, **Then** exibe percentual de conformidade LGPD calculado por regras de campos preenchidos — atualizado em tempo real conforme cadastros evoluem.
4. **Given** tenant sem registros, **When** o dashboard carrega, **Then** exibe estado orientador convidando ao primeiro cadastro — **sem** números fabricados.

---

### User Story 5 - Classificar dados sensíveis com recomendação Cedro (Priority: P3)

Como gestor de TI, preciso que o **Classificador Lógico de Dados Sensíveis** (Insights Cedro) varre o dicionário de dados (nomes de colunas e descrições de tabelas) cadastrados no módulo e, ao identificar termos sensíveis, **recomende** marcar o ativo como *Contém Dados Sensíveis* — cabendo a mim **confirmar** a classificação, para respeitar LGPD sem alteração automática de registros.

**Why this priority**: Insight Cedro de alto valor comercial; depende de ativos e dicionário de dados cadastrados na Base.

**Independent Test**: Cadastrar banco de dados com colunas contendo termos da lista (ex.: *cpf*, *salario*); executar classificador; verificar insight emitido; acionar *Aplicar classificação* e confirmar flag no ativo.

**Acceptance Scenarios**:

1. **Given** ativo tipo banco de dados com dicionário de colunas cadastrado, **When** classificador executa varredura por lista de termos sensíveis, **Then** emite insight consultivo: *Atenção, este banco de dados contém campos com dados sensíveis. Mova para pasta restrita ou aplique criptografia.*
2. **Given** insight de classificação exibido, **When** o usuário lê, **Then** vê badge **Somente leitura** e botão **Aplicar classificação** — **não** há alteração automática da flag do ativo.
3. **Given** usuário aciona **Aplicar classificação**, **When** confirma ação, **Then** flag *Contém Dados Sensíveis* é aplicada ao ativo na **Base** — ação explícita do usuário, **não** da Cedro.
4. **Given** nenhum termo sensível encontrado, **When** varredura conclui, **Then** **não** emite insight — conforme regra de UI condicional (R-10).
5. **Given** insight exibido, **When** o usuário aciona rastreabilidade, **Then** sheet usa título **De onde veio este insight** listando termos encontrados e colunas correspondentes.

---

### User Story 6 - Analisar configurações e portas abertas (Priority: P3)

Como analista de segurança, preciso fazer **upload de arquivos de configuração** (.txt, .json, .csv) de servidores ou relatórios e receber alertas quando padrões incompatíveis com a política de segurança cadastrada forem detectados (ex.: porta 21 aberta, `allow_all: true`), para identificar riscos de configuração rapidamente.

**Why this priority**: Insight Cedro de alto valor; complementa inventário de servidores.

**Independent Test**: Upload de arquivo com padrão proibido; verificar alerta em tela vinculado ao servidor; upload limpo sem alertas.

**Acceptance Scenarios**:

1. **Given** usuário com licença Cedro e arquivo .txt/.json/.csv válido, **When** faz upload vinculado a ativo servidor, **Then** sistema processa conteúdo buscando padrões pré-definidos da política de segurança.
2. **Given** padrão incompatível encontrado (ex.: `port: 21`), **When** análise conclui, **Then** exibe alerta: *A configuração do servidor X está com a porta Y aberta, gerando risco* — com impacto **Alto** ou **Crítico** conforme política.
3. **Given** arquivo sem incompatibilidades, **When** análise conclui, **Then** exibe confirmação de conformidade — **sem** alerta de risco.
4. **Given** insight de configuração, **When** exibido, **Then** badge **Somente leitura** visível; Cedro **não** altera configuração do servidor — apenas recomenda.
5. **Given** upload concluído, **When** o usuário consulta histórico de análises, **Then** vê lista com data, ativo vinculado, resultado e alertas gerados.

---

### User Story 7 - Calcular risco de mudanças via matriz condicional (Priority: P3)

Como gestor de TI, preciso preencher um **formulário de checklist condicional** informando variáveis de uma mudança planejada (ex.: Sistema: RH, Acesso: Externo, MFA: Não) e receber **nota de risco instantânea** com explicação, para decidir se a mudança deve prosseguir.

**Why this priority**: Ferramenta consultiva Cedro de alto valor; independente de inventário completo.

**Independent Test**: Preencher combinação de alto risco (acesso externo + MFA não + dados pessoais); verificar nota *Risco Alto* com explicação; alterar MFA para Sim e verificar redução de risco.

**Acceptance Scenarios**:

1. **Given** formulário de matriz de impacto aberto, **When** o usuário informa variáveis da mudança (sistema, tipo de acesso, MFA, natureza dos dados), **Then** nota de risco é calculada instantaneamente ao completar campos relevantes.
2. **Given** combinação de alto risco (ex.: dados pessoais + acesso externo + MFA ausente), **When** cálculo executa, **Then** exibe *Risco Alto. Esta ação expõe dados pessoais à rede pública sem autenticação de dois fatores (MFA)*.
3. **Given** combinação de baixo risco, **When** cálculo executa, **Then** exibe nota proporcional (*Baixo*, *Moderado*, *Alto*, *Crítico*) com recomendações consultivas — **sem** bloquear operação.
4. **Given** resultado exibido, **When** o usuário abre rastreabilidade, **Then** sheet explica árvore de decisão percorrida — **sem** alterar registros operacionais.

---

### User Story 8 - Executar workflow de auditoria de backup (Priority: P4)

Como técnico de TI, preciso cumprir o **workflow de auditoria de backup** quando o calendário institucional exigir evidência (dia X do mês), preenchendo formulário com tamanho do backup testado, data de restauração bem-sucedida e upload do log original, para comprovar proteção anti-ransomware.

**Why this priority**: Fiscalização Jatobá crítica; depende de servidores cadastrados na Base.

**Independent Test**: Simular dia de auditoria; verificar bloqueio de status do servidor para **Alerta**; preencher formulário válido e confirmar retorno a **Conforme**; simular prazo vencido e verificar status **Vermelho** com notificação ao Secretário.

**Acceptance Scenarios**:

1. **Given** calendário configurado (ex.: dia 5 de cada mês), **When** data corrente atinge dia programado, **Then** servidores elegíveis têm status operacional alterado para **Alerta** — exigindo evidência de backup.
2. **Given** servidor em **Alerta**, **When** o técnico preenche formulário com tamanho do backup testado (> 0), data de restauração bem-sucedida e faz upload do log original, **Then** evidência é validada e status retorna a operacional regular — conformidade **Conforme**.
3. **Given** formulário com tamanho zerado ou log ausente, **When** o técnico submete, **Then** validação rejeita envio com mensagem clara — status permanece **Alerta**.
4. **Given** prazo de evidência ultrapassado (D+1 após dia programado), **When** dados não foram validados, **Then** status vai para **Vermelho** e Secretário responsável é notificado.
5. **Given** auditoria concluída, **When** consultada no painel Jatobá, **Then** aparece no histórico com data, servidor, resultado e conformidade nos 4 status canônicos.

---

### User Story 9 - Consultar trilha de auditoria imutável (Priority: P4)

Como auditor ou CISO, preciso consultar a **trilha de auditoria imutável** que registra toda ação de criar, ler, editar ou excluir sobre ativos TI, incidentes e dados sensíveis deste módulo, com registro append-only que **não pode ser apagado**, para fins de fé pública e accountability.

**Why this priority**: Requisito jurídico de alto valor; escopo limitado ao módulo IT conforme decisão de produto.

**Independent Test**: Executar CRUD em ativo; verificar linha na trilha com user_id, timestamp, action, ip_address; tentar exclusão de log e confirmar impossibilidade.

**Acceptance Scenarios**:

1. **Given** ação de criar, editar, excluir ou consultar dado sensível no módulo IT, **When** a operação conclui, **Then** trilha registra linha com identificador do usuário, data/hora, tipo de ação, endereço de origem, tipo e identificador da entidade afetada.
2. **Given** trilha consultada, **When** o auditor filtra por período, usuário ou entidade, **Then** vê lista cronológica imutável — **sem** opção de editar ou excluir registros.
3. **Given** tentativa de exclusão de registro de trilha por qualquer perfil, **When** executada, **Then** operação é **impossibilitada** — trilha é append-only.
4. **Given** painel de Fiscalização Jatobá, **When** o usuário acessa seção de trilha, **Then** vê interface de consulta com badge **Somente leitura** e filtros por entidade do módulo IT.

---

### User Story 10 - Gerar notificação de incidente para ANPD (Priority: P4)

Como encarregado de dados ou CISO, preciso que, ao registrar incidente **grave**, o sistema preencha automaticamente o **template de notificação ANPD** com dados do incidente (nome do sistema, dados vazados, data) e gere **PDF pronto para assinatura digital** em um clique, para cumprir obrigação regulatória com agilidade.

**Why this priority**: Valor jurídico alto; depende de incidentes cadastrados (US2).

**Independent Test**: Registrar incidente grave; acionar geração ANPD; verificar PDF preenchido com tags dinâmicas; confirmar que campos editáveis permitem ajuste antes da exportação.

**Acceptance Scenarios**:

1. **Given** incidente com criticidade **Crítica** registrado, **When** o usuário aciona *Gerar notificação ANPD*, **Then** sistema preenche template com nome do sistema afetado, categorias de dados envolvidos, data do incidente e descrição resumida.
2. **Given** template preenchido, **When** o usuário revisa e confirma, **Then** PDF é gerado em um clique — pronto para assinatura digital externa.
3. **Given** incidente de criticidade **Leve** ou **Moderada**, **When** o usuário consulta ações disponíveis, **Then** geração ANPD **não** é exibida — conforme UI condicional (R-10).
4. **Given** PDF gerado, **When** consultado no histórico do incidente, **Then** registro indica data de geração e autor — **sem** alterar dados do incidente original.

---

### User Story 11 - Visualizar linhas de defesa de TI (Priority: P5)

Como CISO, preciso visualizar o **mapeamento de linhas de defesa** em gráfico de distribuição percentual, baseado no campo **Resolvido por** dos incidentes resolvidos (1-Antivírus/Operador, 2-Controle Interno/Filtro, 3-Auditoria Externa), para identificar se incidentes estão sendo retidos na ponta ou escapando para auditoria externa.

**Why this priority**: Indicador Carvalho estratégico; depende de incidentes resolvidos com linha de defesa informada.

**Independent Test**: Resolver incidentes com linhas distintas; abrir `/it/maturidade`; verificar gráfico de pizza com percentuais corretos; confirmar alerta quando linha 3 predomina.

**Acceptance Scenarios**:

1. **Given** incidentes resolvidos com campo **Resolvido por** preenchido, **When** painel Carvalho carrega, **Then** exibe gráfico com percentual por linha de defesa calculado como: *(Incidentes retidos na Linha N ÷ Total de Incidentes) × 100*.
2. **Given** linha 3 (Auditoria Externa) com percentual elevado (threshold definido na fase plan), **When** painel exibe resultado, **Then** alerta de **Atenção** ou **Crítico** indica possível falta de treinamento na ponta.
3. **Given** tenant sem incidentes resolvidos, **When** painel carrega, **Then** exibe estado orientador — **sem** percentuais fabricados.
4. **Given** painel exibido, **When** o usuário aciona rastreabilidade, **Then** sheet usa título **Como calculamos este score** explicando fonte (incidentes resolvidos) e fórmula em linguagem clara.

---

### User Story 12 - Acompanhar aderência LGPD e CIS Controls (Priority: P5)

Como CISO ou gestor de governança, preciso visualizar **score de aderência** (0–100%) a frameworks mandatórios (controles CIS e requisitos LGPD), calculado pela proporção de controles marcados como *Ativo/Concluído* sobre o total possível, para medir progresso de conformidade institucional.

**Why this priority**: Painel Carvalho de maturidade; pode ser alimentado incrementalmente conforme controles são marcados.

**Independent Test**: Marcar subset de controles CIS/LGPD como concluídos; verificar score = (concluídos ÷ total) × 100; desmarcar e confirmar recálculo imediato.

**Acceptance Scenarios**:

1. **Given** catálogo de controles CIS e requisitos LGPD cadastrados, **When** o gestor marca controles como *Ativo* ou *Concluído*, **Then** score de aderência é recalculado em tempo real.
2. **Given** 20 controles possíveis com 15 concluídos, **When** score exibido, **Then** mostra **75%** de aderência — atualizado em **≤ 2 segundos** após alteração.
3. **Given** score abaixo de 70%, **When** exibido no contexto Carvalho, **Then** alerta de licença **Crítico** conforme R-64; entre 70% e 80% = **Atenção** (R-65).
4. **Given** painel exibido, **When** o usuário expande detalhe, **Then** vê lista de controles pendentes com orientação consultiva — **sem** alterar registros operacionais da Base.

---

### User Story 13 - Analisar índice de vulnerabilidade por secretaria (Priority: P5)

Como CISO ou Secretário, preciso visualizar **ranking de secretarias** por índice de vulnerabilidade, calculado como média ponderada entre peso dos ativos e incidentes abertos vinculados, para priorizar ações corretivas por unidade organizacional.

**Why this priority**: Visão gerencial Carvalho; depende de ativos e incidentes distribuídos por secretaria.

**Independent Test**: Cadastrar ativos e incidentes em secretarias distintas; verificar score por secretaria; confirmar fórmula: *10 − ((Incidentes Críticos × 3) + (Incidentes Leves × 1)) ÷ Total de Ativos da Secretaria*.

**Acceptance Scenarios**:

1. **Given** ativos e incidentes vinculados a secretarias, **When** painel Carvalho carrega, **Then** exibe ranking ordenado por índice de vulnerabilidade (menor score = maior risco).
2. **Given** secretaria com incidentes críticos e poucos ativos, **When** índice calculado, **Then** score reflete penalização proporcional conforme fórmula definida.
3. **Given** secretaria sem incidentes abertos, **When** exibida, **Then** índice tende a valor próximo de 10 — **sem** ocultar a secretaria se possui ativos.
4. **Given** painel exibido, **When** o usuário seleciona secretaria, **Then** vê detalhamento: ativos, incidentes abertos por criticidade e recomendação consultiva Carvalho.

---

### User Story 14 - Governança: licenças, permissões e separação de eixos (Priority: P1)

Como administrador de governança, preciso que o módulo IT respeite o modelo de licenciamento canônico (Base + Carvalho, Pau-Brasil, Jatobá, Cedro), com rotas, permissões e separação operacional vs conformidade vs maturidade vs insights, para garantir conformidade de produto.

**Why this priority**: Bloqueador de produção; transversal a todas as histórias.

**Independent Test**: Validar rotas `/it`, `/it/insights`, `/it/fiscalizacao`, `/it/maturidade`; usuário sem licença Cedro não vê insights; Jatobá não altera ativos; Cedro não altera flags sem confirmação.

**Acceptance Scenarios**:

1. **Given** usuário sem permissão no módulo IT, **When** tenta acessar qualquer rota `/it/*`, **Then** recebe **403 · Acesso negado** com copy padronizada.
2. **Given** usuário autorizado **sem** licença Cedro, **When** acessa `/it/insights`, **Then** recebe alerta de licença — insights **não** exibidos.
3. **Given** usuário autorizado **sem** licença Jatobá, **When** acessa `/it/fiscalizacao`, **Then** recebe alerta de licença — fiscalização **não** exibida.
4. **Given** usuário autorizado **sem** licença Carvalho, **When** acessa `/it/maturidade`, **Then** recebe alerta de licença — maturidade **não** exibida.
5. **Given** qualquer insight Cedro, **When** exibido, **Then** badge **Somente leitura** visível; Cedro **nunca** altera registros sem ação explícita do usuário na Base.
6. **Given** qualquer achado Jatobá, **When** produzido, **Then** sinaliza conformidade — **não** altera ativos, incidentes ou mapeamentos LGPD.

---

### Edge Cases

- Tenant sem ativos cadastrados: dashboard operacional exibe estado vazio; insights de configuração e classificador LGPD orientam cadastro prévio — **sem** alertas fabricados.
- Ativo excluído logicamente com incidentes abertos: incidentes permanecem consultáveis; vínculo exibe ativo como *Inativo*.
- Upload de configuração corrompido ou formato inválido: rejeição com mensagem clara — **sem** processamento parcial silencioso.
- Dois técnicos submetendo evidência de backup simultaneamente: última evidência válida prevalece — conflito informado.
- Incidente crítico sem sistema vinculado: geração ANPD permite preenchimento manual de campos ausentes antes do PDF.
- Secretaria sem ativos cadastrados: **não** aparece no ranking de vulnerabilidade.
- Classificador LGPD encontra termo ambíguo (ex.: *salario* em coluna *salario_minimo_legal*): insight indica revisão humana recomendada — **não** aplica flag automaticamente.
- Trilha de auditoria: volume elevado de leituras — consulta paginada; retenção conforme política institucional (detalhe na fase plan).

## Requirements *(mandatory)*

### Functional Requirements

#### Base — Gestão operacional

- **FR-001**: O sistema **DEVE** disponibilizar o **9º módulo de negócio** *Segurança da Informação* (slug `it`) na navegação principal, submetido à matriz módulo × licença padrão.
- **FR-002**: O sistema **DEVE** permitir CRUD completo de **ativos de TI** nos tipos: servidor, computador, licença de software, banco de dados e sistema.
- **FR-003**: Exclusão de ativos **DEVE** usar **soft delete** com possibilidade de **restaurar**.
- **FR-004**: Ativos **DEVEM** suportar **tags** livres e **vínculos** entre si (dependência hospedagem/uso).
- **FR-005**: O sistema **DEVE** permitir registro de **incidentes de segurança** com campos: data, criticidade, tipo de ameaça, secretaria afetada, descrição, logs de erro e vínculo opcional a ativo.
- **FR-006**: Incidentes resolvidos **DEVEM** exigir campo **Resolvido por** (linha de defesa: 1-Antivírus/Operador, 2-Controle Interno/Filtro, 3-Auditoria Externa).
- **FR-007**: O sistema **DEVE** permitir mapeamento **operador/sistema → categorias de dados sensíveis** para conformidade LGPD.
- **FR-008**: Dashboard operacional **DEVE** exibir: volumetria de ativos, total de incidentes **Abertos** e percentual de conformidade LGPD (regras de campos preenchidos).
- **FR-009**: Listas operacionais **DEVEM** seguir ordem canônica de plataforma (§4 regras-plataforma): breadcrumb, cabeçalho, barra de alertas de licença, cards de estatística, filtros, tabela, paginação.
- **FR-010**: Coluna **Ações** **DEVE** usar menu ⋮ (`MoreVertical`) — **nunca** botões inline na linha.

#### Cedro — Insights IA (`/it/insights`)

- **FR-011**: O sistema **DEVE** permitir upload de arquivos `.txt`, `.json` e `.csv` vinculados a ativo servidor para **análise de configurações e portas**.
- **FR-012**: Análise **DEVE** detectar padrões incompatíveis com política de segurança cadastrada e emitir alertas consultivos com impacto (*Crítico*, *Alto*, *Médio*).
- **FR-013**: **Classificador Lógico LGPD** **DEVE** varrer dicionário de dados (colunas e descrições) por lista de termos sensíveis e emitir insight consultivo — **sem** alterar flag do ativo automaticamente.
- **FR-014**: Usuário **DEVE** poder confirmar classificação via ação explícita **Aplicar classificação** na Base — preservando R-21 (Cedro somente leitura).
- **FR-015**: **Matriz de Impacto de Mudanças** **DEVE** calcular nota de risco instantaneamente a partir de checklist condicional (If/Else parametrizado).
- **FR-016**: Insights Cedro **DEVEM** exibir badge **Somente leitura** e rastreabilidade via sheet (*De onde veio este insight*).

#### Jatobá — Fiscalização (`/it/fiscalizacao`)

- **FR-017**: **Workflow de Auditoria de Backup** **DEVE** disparar automaticamente no dia X configurado do mês, alterando status operacional de servidores elegíveis para **Alerta**.
- **FR-018**: Evidência de backup **DEVE** exigir: tamanho do backup testado (> 0), data de restauração bem-sucedida e upload de log original.
- **FR-019**: Prazo vencido sem evidência válida **DEVE** elevar status para **Vermelho** e **notificar Secretário** responsável.
- **FR-020**: **Trilha de auditoria imutável** **DEVE** registrar ações CRUD sobre ativos TI, incidentes e dados sensíveis **deste módulo** — append-only, **sem** exclusão lógica ou física.
- **FR-021**: Trilha **DEVE** registrar: identificador do usuário, data/hora, tipo de ação, endereço de origem, tipo e identificador da entidade.
- **FR-022**: **Gerador de Notificação ANPD** **DEVE** preencher template com tags dinâmicas a partir de incidentes **Críticos** e gerar PDF em um clique.
- **FR-023**: Conformidade de backup **DEVE** usar os 4 status canônicos Jatobá: *Conforme*, *Não conforme*, *Parcial*, *Pendente*.

#### Carvalho — Maturidade (`/it/maturidade`)

- **FR-024**: Painel **DEVE** exibir gráfico de **linhas de defesa** com percentual por linha calculado sobre incidentes resolvidos.
- **FR-025**: Percentual elevado na linha 3 (Auditoria Externa) **DEVE** disparar alerta consultivo de possível falta de treinamento na ponta.
- **FR-026**: **Score de aderência LGPD e CIS Controls** **DEVE** calcular: *(controles Ativo/Concluído ÷ total de controles) × 100*.
- **FR-027**: **Índice de vulnerabilidade por secretaria** **DEVE** calcular: *10 − ((Incidentes Críticos × 3) + (Incidentes Leves × 1)) ÷ Total de Ativos da Secretaria*.
- **FR-028**: Carvalho **DEVE** ser **somente leitura** em relação a ativos, incidentes e mapeamentos LGPD — **não** altera operação.
- **FR-029**: Score Carvalho **DEVE** permitir rastreabilidade (*Como calculamos este score?*).

#### Governança transversal

- **FR-030**: Rotas públicas **DEVEM** ser: `/it` (gestão), `/it/insights`, `/it/fiscalizacao`, `/it/maturidade`.
- **FR-031**: Acesso a cada tela de licença **DEVE** exigir permissão no módulo IT **e** licença correspondente ativa.
- **FR-032**: Vocabulário UI **DEVE** usar nomes canônicos de licença: **Carvalho**, **Pau-Brasil**, **Jatobá**, **Cedro** — com acento e hífen.
- **FR-033**: Pau-Brasil **PODE** ser omitida nesta entrega (sem expressão documental específica em IT) — UI condicional conforme R-10; **não** bloqueia módulo.

### Fronteiras entre licenças (obrigatório)

| Licença | O que faz neste contexto | O que **NÃO** faz |
| --- | --- | --- |
| **Base** | CRUD ativos TI, incidentes, mapeamento LGPD, dashboard operacional | Calcular maturidade; emitir insights; fiscalizar conformidade |
| **Cedro** | Análise de configurações; classificador LGPD (recomendação); matriz de risco | Alterar registros sem confirmação do usuário; classificar conformidade Jatobá |
| **Jatobá** | Workflow backup; trilha auditoria (consulta); gerador ANPD; conformidade backup | Alterar ativos ou incidentes; calcular score Carvalho |
| **Carvalho** | Linhas de defesa; aderência LGPD/CIS; índice vulnerabilidade por secretaria | Fiscalizar registro a registro; alterar ativos ou incidentes |
| **Pau-Brasil** | *(Fora de escopo nesta entrega)* — sem biblioteca normativa IT específica | Classificar conformidade; insights estratégicos |

### Key Entities

- **AtivoTI**: inventário de infraestrutura; tipos (servidor, computador, licença, banco de dados, sistema); tags; vínculos; flag *Contém Dados Sensíveis*; secretaria responsável; soft delete.
- **IncidenteSeguranca**: ocorrência de segurança; data; criticidade; tipo de ameaça; secretaria afetada; logs; status (Aberto, Resolvido); **Resolvido por** (linha de defesa); vínculo opcional a AtivoTI.
- **OperadorTratamento**: operador de dados (interno ou terceiro); papel LGPD; vínculo a sistemas e categorias de dados sensíveis.
- **CategoriaDadoSensivel**: taxonomia institucional (CPF, saúde, financeiro etc.); usada em mapeamento LGPD e classificador Cedro.
- **DicionarioDados**: metadados de colunas/tabelas de banco de dados cadastrado; insumo do classificador LGPD.
- **ConfiguracaoAnalisada**: registro de upload e resultado de scan de configuração; alertas vinculados a AtivoTI servidor.
- **PoliticaSeguranca**: padrões proibidos/obrigatórios para análise de configurações (ex.: portas, flags inseguras).
- **MatrizMudanca**: submissão de checklist condicional; variáveis informadas; nota de risco calculada.
- **AuditoriaBackup**: ciclo de evidência por servidor; data programada; status operacional; evidência (tamanho, data restauração, log).
- **AuditLogIT**: registro imutável append-only de ações CRUD no módulo IT; usuário, timestamp, ação, IP, entidade.
- **NotificacaoANPD**: template preenchido; PDF gerado; vínculo a IncidenteSeguranca crítico.
- **ControleFramework**: item de controle CIS ou requisito LGPD; status (Pendente, Ativo, Concluído); alimenta score Carvalho.
- **Secretaria**: unidade organizacional; agrega ativos e incidentes para índice de vulnerabilidade.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Gestor cadastra **100 ativos TI** com vínculos em **≤ 1 hora** sem treinamento prévio.
- **SC-002**: Incidente de segurança registrado com todos os campos obrigatórios em **≤ 3 minutos**.
- **SC-003**: Percentual de conformidade LGPD no dashboard atualiza em tempo real (**≤ 2 segundos**) após alteração de mapeamento.
- **SC-004**: Análise de configuração entrega alertas em **≤ 10 segundos** após upload de arquivo válido.
- **SC-005**: Classificador LGPD emite recomendação em **≤ 5 segundos** por sistema analisado.
- **SC-006**: Matriz de Impacto exibe nota de risco **instantaneamente** (percebida em **≤ 1 segundo**) após preenchimento dos campos condicionais.
- **SC-007**: Backup não evidenciado em **D+1** após dia programado altera status para **Vermelho** e dispara notificação ao Secretário em **≤ 5 minutos**.
- **SC-008**: Registros da trilha de auditoria **não podem ser excluídos** por nenhum perfil — validável por tentativa de exclusão em **100%** dos casos.
- **SC-009**: PDF de notificação ANPD gerado em **1 clique** com **≥ 90%** dos campos preenchidos automaticamente a partir do incidente.
- **SC-010**: Score CIS/LGPD e índice de vulnerabilidade refletem alterações em **≤ 2 segundos** no painel Carvalho.
- **SC-011**: **Nenhuma** ação Cedro ou Carvalho altera ativos ou incidentes sem ação explícita do usuário na Base — validável comparando registro antes e depois.
- **SC-012**: Demonstração ponta a ponta (cadastrar ativo → registrar incidente → receber insight → fiscalizar backup → consultar maturidade) concluída em **≤ 45 minutos** por usuário sem treinamento prévio.

## Assumptions

- **Novo módulo**: *Segurança da Informação* é o **9º módulo de negócio** (slug `it`); lista fechada de módulos em regras-plataforma será atualizada na fase plan/implement.
- **Setor IT**: usuários do setor de TI recebem permissão ao módulo via estrutura existente de setores/permissões — detalhe na fase plan.
- **Secretarias**: reutiliza cadastro institucional de secretarias/setores já existente na plataforma.
- **Cedro read-only**: classificador LGPD **recomenda** flag; usuário **confirma** via *Aplicar classificação* — R-21 preservada.
- **Trilha de auditoria**: escopo **limitado ao módulo IT** (ativos, incidentes, dados sensíveis deste domínio) — **não** plataforma inteira nesta entrega.
- **Política de segurança**: padrões de configuração (regex/lista) provisionados como seed institucional — editáveis pelo gestor em evolução futura.
- **Framework CIS**: catálogo inicial com **20 controles** representativos — expansível na fase plan.
- **Calendário backup**: dia X configurável por tenant (padrão: dia 5) — detalhe na fase plan.
- **Notificação Secretário**: canal de notificação reutiliza infra existente (in-app ou e-mail) — detalhe na fase plan.
- **Pau-Brasil**: sem entrega específica nesta feature; módulo IT funciona com Base + Jatobá + Cedro + Carvalho.
- **Paridade estrutural**: rotas e UX alinhadas aos módulos existentes (ex.: `/compras/insights`, `/gabinete/fiscalizacao`, `/compras/maturidade`).

## Out of Scope

- Trilha de auditoria imutável para **todos os módulos** da plataforma (apenas IT nesta entrega).
- Integração com scanners de vulnerabilidade externos (Nessus, OpenVAS etc.).
- Assinatura digital embarcada no PDF ANPD — PDF preparado para assinatura **externa**.
- Biblioteca normativa Pau-Brasil específica de TI (políticas, minutas).
- Alteração automática de flags ou registros por Cedro/Jatobá/Carvalho sem ação do usuário na Base.
- Monitoramento em tempo real de portas/rede (agentes instalados em servidores).
- Gestão de identidade e acesso (IAM/SSO) como produto separado.
- Benchmarking de maturidade entre tenants ou órgãos.
