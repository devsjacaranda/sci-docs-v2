# Feature Specification: Desmock Jurídico — Módulo Legal Completo

**Feature Branch**: `012-desmock-juridico`

**Created**: 2026-06-23

**Status**: Draft

**Input**: User description: "Desmock do módulo Jurídico — substituir demonstrações mock por operação real em `/juridico/*`: Novo Processo (wizard), Lista de Processos, Detalhe, Dashboard Jurídico, Painel de Fiscalização Jurídica (Jatobá, incluindo Probabilidade de Perda por regras), Insights Cedro (jurisprudência e risco processual), Maturidade Carvalho. Anexos de documentos via object storage (Wasabi). Campos: tipo de processo, identificação e partes (estruturado, tudo opcional), órgão e juízo (estruturado opcional), observações. Número interno auto `JUR-AAAA-NNNN` + nº judicial/CNJ opcional. Fluxo wizard dados → anexos → revisão → confirmação."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Registrar processo jurídico via wizard (Priority: P1)

Como servidor autenticado com acesso ao módulo Jurídico, preciso registrar um processo preenchendo tipo, identificação, partes, órgão e juízo, observações e dados operacionais, revisando tudo antes de confirmar, para que o feito entre formalmente na fila institucional com número interno rastreável.

**Why this priority**: Sem registro estruturado e número interno, não existe fila operacional nem base para fiscalização, insights ou maturidade.

**Independent Test**: Autenticar usuário do setor jurídico (DEJUR), preencher o formulário em quatro etapas (dados → anexos → revisão → confirmação), confirmar o envio e verificar que o processo aparece na lista com número interno único gerado.

**Acceptance Scenarios**:

1. **Given** um servidor com permissão no módulo Jurídico, **When** preenche **Tipo de processo**, blocos **Identificação**, **Partes**, **Órgão e juízo**, **Observações**, **Prazo processual** e **Responsável interno** e avança até a revisão, **Then** vê resumo completo com instrução *"Revise os dados do processo. Caso queira alterar algum campo, retorne ao formulário."*
2. **Given** a etapa de revisão, **When** o servidor confirma o envio, **Then** o sistema gera número interno único no formato institucional (ex.: `JUR-2026-0047`) e exibe confirmação com esse identificador.
3. **Given** **Tipo** *Judicial*, **When** o servidor informa opcionalmente **Número judicial/CNJ**, **Then** o valor é associado ao processo sem substituir o número interno auto-gerado.
4. **Given** bloco **Partes**, **When** o servidor adiciona partes em polo ativo, passivo ou outros participantes com tipo de pessoa, nome, documento e endereço, **Then** cada parte é registrada — **nenhum** campo de parte é obrigatório para concluir o cadastro.
5. **Given** bloco **Órgão e juízo**, **When** o servidor informa esfera, tribunal/órgão, comarca/seção e vara/juízo, **Then** os dados são persistidos como campos estruturados opcionais — **sem** catálogo externo de tribunais.
6. **Given** processo sem partes, sem órgão e sem valor da causa, **When** o servidor confirma o envio, **Then** o cadastro é aceito sem bloqueio.
7. **Given** a etapa de revisão, **When** o servidor retorna ao formulário, **Then** os dados já preenchidos permanecem disponíveis para edição sem perda.

---

### User Story 2 - Anexar documentos ao processo (Priority: P1)

Como servidor registrando um processo, preciso anexar documentos (petições, pareceres, contratos, evidências) na etapa de anexos, para que a equipe jurídica analise evidências junto com o registro.

**Why this priority**: Anexos são requisito explícito do produto e alimentam checagens de fiscalização e Probabilidade de Perda.

**Independent Test**: Anexar arquivos válidos e inválidos na etapa de anexos; verificar aceitação/rejeição conforme regras de tipo e tamanho; confirmar visualização no detalhe.

**Acceptance Scenarios**:

1. **Given** a etapa de anexos, **When** o servidor adiciona arquivos nos formatos aceitos (documentos de texto, imagens, planilhas e multimídia), **Then** cada arquivo é listado com nome e tamanho antes da revisão.
2. **Given** um arquivo acima de 30 MB ou com extensão não permitida, **When** o servidor tenta anexá-lo, **Then** o sistema rejeita com mensagem clara indicando limite de tamanho ou tipo não aceito — sem avançar silenciosamente.
3. **Given** processo confirmado com anexos, **When** a equipe abre o detalhe, **Then** consegue visualizar ou baixar cada documento associado ao número interno.
4. **Given** upload de anexo, **When** o arquivo é enviado, **Then** o conteúdo binário **não** trafega pelo servidor de aplicação em condições normais de operação — upload direto ao serviço de object storage da plataforma.

---

### User Story 3 - Operar lista e detalhe de processos (Priority: P1)

Como servidor do Jurídico, preciso consultar a lista de processos com filtros e abrir o detalhe com linha do tempo, para priorizar prazos e acompanhar o andamento de cada feito.

**Why this priority**: A operação diária da procuradoria/assessoria jurídica depende da fila visível e do histórico por registro.

**Independent Test**: Registrar processos de tipos e status distintos, aplicar filtros na lista e abrir detalhe com timeline de eventos.

**Acceptance Scenarios**:

1. **Given** processos registrados no tenant, **When** o servidor abre **Lista de Processos**, **Then** vê colunas **Número**, **Tipo**, **Partes** (resumo), **Status**, **Prazo** e **Responsável**, com filtros por tipo, status operacional e prazo.
2. **Given** um processo na lista, **When** o servidor abre o detalhe, **Then** vê dados completos do registro, partes (quando informadas), órgão e juízo, observações, anexos e **linha do tempo** de eventos (abertura, parecer, revisão, encaminhamento).
3. **Given** busca por número interno, **When** o servidor informa `JUR-2026-0047`, **Then** localiza o registro correspondente em menos de uma interação adicional.
4. **Given** processo com prazo próximo ou vencido, **When** exibido na lista, **Then** status operacional reflete situação (*Vencendo*, *Crítico*) conforme regras da Base — **sem** misturar com conformidade de fiscalização Jatobá.
5. **Given** processo confirmado, **When** o servidor edita campos permitidos, **Then** alterações são persistidas e evento de atualização **PODE** ser registrado na timeline.

---

### User Story 4 - Dashboard Jurídico com métricas reais (Priority: P1)

Como gestor do Jurídico, preciso abrir o **Dashboard Jurídico** (`/juridico/dashboard`) e ver indicadores consolidados do tenant — processos abertos, prazos críticos, produtividade de pareceres e conformidade legal — para visão executiva da operação.

**Why this priority**: O dashboard é ponto de entrada do módulo; métricas mock não sustentam decisão institucional.

**Independent Test**: Popular tenant com processos em estados distintos; abrir dashboard e verificar stats e gráficos refletindo contagens reais, não valores fixos de demonstração.

**Acceptance Scenarios**:

1. **Given** processos confirmados no tenant, **When** o servidor acessa `/juridico/dashboard`, **Then** vê cards **Processos Abertos**, **Prazos Críticos**, **Pareceres (mês)** e **Conformidade Legal** calculados a partir dos registros reais.
2. **Given** mix de status operacionais, **When** o gráfico de distribuição é exibido, **Then** reflete volume por status (ex.: Aberto, Crítico, Concluído) — **não** dados estáticos de mock.
3. **Given** indicador **Conformidade Legal**, **When** exibido, **Then** deriva da taxa de conformidade da execução Jatobá mais recente sobre processos confirmados — distinto de status operacional *Crítico*.
4. **Given** tenant sem processos confirmados, **When** o dashboard carrega, **Then** estado vazio orienta *registre processos para habilitar indicadores* — **sem** números fabricados.

---

### User Story 5 - Painel de Fiscalização Jurídica e Probabilidade de Perda (Priority: P1)

Como servidor autenticado com licença Jatobá, preciso abrir **Fiscalização** (`/juridico/auditoria`) e ver resultados reais de fiscalização sobre processos do meu órgão — conformidade, checagens, achados, **Probabilidade de Perda** calculada por regras e histórico — sem alterar registros operacionais.

**Why this priority**: Fiscalização Jatobá é licença distinta da Base; Probabilidade de Perda é métrica específica do domínio jurídico acordada para esta entrega.

**Independent Test**: Popular tenant com processos em estados distintos (prazo vencido, sem anexos, judicial sem CNJ, valor da causa alto); executar fiscalização; verificar checagens, conformidade agregada e coluna/indicador de Probabilidade de Perda por processo.

**Acceptance Scenarios**:

1. **Given** usuário com permissão no módulo Jurídico e licença Jatobá, **When** acessa `/juridico/auditoria`, **Then** vê **Painel de Fiscalização Jurídica** com resultados da execução mais recente, badge **Somente leitura** e copy que deixa claro que a Jatobá sinaliza achados — **não** altera processos.
2. **Given** execução concluída, **When** a tela carrega, **Then** stats exibem contagem por **Conforme**, **Não conforme**, **Parcial** e **Pendente** — **nunca** *Crítico* ou *Aguardando resposta* como status de conformidade.
3. **Given** processos confirmados, **When** fiscalização executa, **Then** tabela histórica exibe colunas **Processo**, **Dados fiscalizados**, **Questionário**, **Destinatário**, **Canal**, **Conformidade**, **Problemas** e **Probabilidade de Perda** — refletindo registros reais.
4. **Given** processo com dados suficientes (tipo, prazo, status, anexos, valor da causa), **When** checagem de **Probabilidade de Perda** executa, **Then** resultado é classificado em faixa **Baixa**, **Média** ou **Alta** conforme regras determinísticas documentadas nas Assumptions.
5. **Given** processo com dados insuficientes para calcular risco (ex.: sem prazo e sem tipo), **When** checagem executa, **Then** Probabilidade de Perda aparece como **Indeterminada** — **nunca** valor inventado.
6. **Given** processo **Judicial** sem número CNJ informado, **When** checagem de **Identificação judicial** executa, **Then** resultado **PODE** ser **Parcial** — cadastro permanece válido.
7. **Given** prazo processual vencido sem justificativa registrada, **When** checagem de **Prazos processuais** executa, **Then** resultado é **Não conforme** com achado descritivo.
8. **Given** múltiplas checagens no mesmo processo, **When** conformidade agregada é calculada, **Then** prevalece o **pior** status entre {Conforme, Parcial, Pendente, Não conforme}.
9. **Given** usuário aciona *Fiscalizar processos*, **When** limites de frequência permitem, **Then** nova execução analisa 100% dos processos confirmados do tenant e persiste resultados.

---

### User Story 6 - Insights Cedro — jurisprudência e risco processual (Priority: P1)

Como servidor autenticado com licença Cedro, preciso abrir **Insights IA** (`/juridico/insights`) e ver insights consultivos derivados dos dados internos de processos do meu órgão — tendências de risco processual, concentração por tipo e órgão, prazos críticos — para orientar decisões estratégicas sem alterar registros.

**Why this priority**: Cedro no Jurídico tem foco canônico *Jurisprudência e risco processual*; painel mock não entrega valor consultivo real.

**Independent Test**: Popular tenant com processos judiciais e administrativos variados; gerar insights; verificar cards com impacto, recomendação, fonte *Dados internos — Jurídico* e rastreio — sem linhas fixas de demonstração.

**Acceptance Scenarios**:

1. **Given** usuário com permissão no módulo Jurídico e licença Cedro, **When** acessa `/juridico/insights`, **Then** vê painel **Insights IA** com insights da geração mais recente, badge **Somente leitura** e descrição consultiva.
2. **Given** insight exibido, **When** o usuário lê o card, **Then** vê impacto **Crítico**, **Alto** ou **Médio**, fonte *Dados internos — Jurídico* e recomendação consultiva (orienta, não executa).
3. **Given** processos com tipos e Probabilidades de Perda variadas, **When** insights são gerados, **Then** pelo menos um insight operacional resume concentração de risco processual, prazos críticos ou volume por tipo/órgão.
4. **Given** qualquer insight, **When** o usuário aciona *De onde veio este insight?*, **Then** abre sheet inferior (~85% da viewport) com rastreabilidade — **sem** rota dedicada.
5. **Given** geração híbrida (agenda + recálculo ao abrir), **When** o usuário aciona *Consultar IA*, **Then** nova geração é disparada respeitando throttling institucional — resultados persistidos em histórico.

---

### User Story 7 - Maturidade Carvalho — Jurídico (Priority: P1)

Como servidor autenticado com licença Carvalho, preciso abrir **Maturidade** (`/juridico/maturidade`) e ver score de maturidade real do Jurídico — nota geral, três eixos, radar, evolução temporal e planos de ação — para diagnóstico institucional sem alterar processos.

**Why this priority**: Carvalho completa o desmock das seis telas listadas; score mock não sustenta gestão de capacidade jurídica.

**Independent Test**: Responder autoavaliação Carvalho do período vigente; executar fiscalização Jatobá; abrir maturidade e verificar score híbrido por eixo com rastreio *Como calculamos este score?*.

**Acceptance Scenarios**:

1. **Given** usuário com permissão no módulo Jurídico e licença Carvalho, **When** acessa `/juridico/maturidade`, **Then** vê **Maturidade — Jurídico** com score calculado, badge **Somente leitura** e três eixos: **Controle Interno**, **Governança**, **Tecnologia da Informação**.
2. **Given** autoavaliação respondida e execução Jatobá disponível, **When** score por eixo é calculado, **Then** nota = combinação híbrida de autoavaliação da equipe e taxa de conformidade Jatobá conforme fórmula institucional (Assumptions).
3. **Given** indicadores operacionais canônicos do Jurídico, **When** exibidos no dashboard, **Then** incluem volume de processos, prazos críticos, taxa de conformidade legal e produtividade de pareceres — derivados de registros reais.
4. **Given** score geral abaixo de 70%, **When** exibido, **Then** alerta **Crítico**; entre 70% e 80% **Atenção**; ≥ 80% sem alerta de maturidade.
5. **Given** usuário autorizado, **When** cria plano de ação vinculado a eixo com déficit, **Then** plano é persistido com responsável, prazo e status — **única** operação de escrita da tela Maturidade além da autoavaliação.

---

### User Story 8 - Rastreabilidade Cedro, Jatobá e Carvalho (Priority: P1)

Como usuário que precisa confiar em achados, insights ou scores, preciso entender como cada resultado foi produzido — regra aplicada, campos avaliados, processos de exemplo e período — para validar antes de agir na Base.

**Why this priority**: Rastreabilidade é regra de plataforma; títulos e comportamento de sheet são canônicos.

**Independent Test**: Abrir rastreio de checagem Jatobá (incl. Probabilidade de Perda), insight Cedro e score Carvalho; verificar títulos obrigatórios.

**Acceptance Scenarios**:

1. **Given** checagem automática Jatobá, **When** o usuário aciona explicação, **Then** sheet usa título **Por que esta checagem deu este resultado** — incluindo fatores da Probabilidade de Perda quando aplicável.
2. **Given** achado de inconformidade, **When** o usuário abre rastreio, **Then** sheet usa título **O que gerou este achado** com regra, evidências e número interno do processo.
3. **Given** fiscalização no detalhe do processo, **When** o usuário abre rastreio consolidado, **Then** sheet usa título **O que verificamos neste registro**.
4. **Given** insight Cedro, **When** o usuário aciona *De onde veio este insight?*, **Then** sheet explica agregação, período e exemplos de processos — **sem** expor documentos de partes além do necessário.
5. **Given** score Carvalho, **When** o usuário aciona *Como calculamos este score?*, **Then** sheet usa título **Como calculamos este score** com autoavaliação e conformidade Jatobá por eixo.

---

### User Story 9 - Governança: módulo, licenças e separação de eixos (Priority: P1)

Como administrador de governança, preciso que apenas usuários autorizados ao módulo Jurídico acessem operações e licenças correspondentes, e que Jatobá/Cedro/Carvalho **nunca** alterem dados operacionais do processo.

**Why this priority**: Segurança multi-tenant, permissão por setor e contratos de licença são bloqueadores para produção.

**Independent Test**: Usuário sem setor DEJUR (403); fiscalizar processo e verificar campos operacionais idênticos antes e depois.

**Acceptance Scenarios**:

1. **Given** usuário sem permissão no módulo Jurídico, **When** tenta acessar rotas `/juridico/*`, **Then** recebe **403 · Acesso negado** com copy padronizada — item pode permanecer visível na navegação.
2. **Given** usuário autorizado à Base, **When** acessa CRUD e dashboard, **Then** opera normalmente **sem** exigir licenças analíticas.
3. **Given** rota de licença (Fiscalização, Insights IA, Maturidade), **When** tenant não possui licença ativa, **Then** exibe alerta de licença conforme regras de plataforma — **nunca** dados mock como fallback.
4. **Given** qualquer ação Jatobá, Cedro ou Carvalho, **When** executada, **Then** status operacional, prazo, partes, anexos e eventos da timeline do processo **permanecem inalterados**.
5. **Given** tenant sem processos confirmados, **When** telas analíticas carregam, **Then** estados vazios orientam operação — **sem** achados ou insights fabricados.

---

### Edge Cases

- Envio simultâneo de dois processos no mesmo tenant: cada um recebe número interno único sem colisão de sequência.
- Anexo removido antes da confirmação: não persiste após cancelamento ou retorno ao formulário.
- Processo **Consultivo** interno sem órgão judiciário: cadastro válido; checagens de identificação judicial não aplicáveis.
- Processo **Judicial** com CNJ informado em formato inválido: sistema alerta na validação mas **PODE** permitir confirmação com flag de revisão pendente (política padrão: alerta, não bloqueio).
- Prazo processual no passado na criação: sistema alerta servidor mas permite registro com confirmação.
- Usuário perde permissão de setor durante sessão: próxima operação retorna 403.
- Execução fiscalização manual dentro do limite horário: mensagem clara; leitura e histórico não contam no limite.
- Parte com endereço parcial via entidade centralizada: cadastro válido; checagem de completude **Parcial** ou **Pendente**.
- Processo excluído logicamente após fiscalização: resultados históricos permanecem consultáveis com indicação de registro indisponível.
- Valor da causa zero ou não informado: Probabilidade de Perda ignora fator monetário; demais fatores ainda aplicam.

## Requirements *(mandatory)*

### Functional Requirements

#### Base — registro e operação

- **FR-001**: O sistema **DEVE** permitir a servidores autenticados com permissão no módulo Jurídico registrar processos via wizard em etapas: **dados** → **anexos** → **revisão** → **confirmação**, com copy de revisão *"Revise os dados do processo. Caso queira alterar algum campo, retorne ao formulário."*
- **FR-002**: O sistema **DEVE** restringir **Tipo de processo** ao conjunto fechado: **Administrativo**, **Judicial**, **Consultivo**.
- **FR-003**: O sistema **DEVE** gerar **número interno** único por processo na confirmação, formato legível institucional (ex.: `JUR-AAAA-NNNN`) — imutável após criação.
- **FR-004**: O sistema **DEVE** permitir **Número judicial/CNJ** opcional, distinto do número interno, aplicável principalmente a processos **Judiciais**.
- **FR-005**: O sistema **DEVE** permitir **Assunto/título** opcional na identificação do processo.
- **FR-006**: O sistema **DEVE** suportar **Partes** estruturadas em polos (**Ativo**, **Passivo**, **Outros participantes**), cada uma com tipo de pessoa (**Física**, **Jurídica**, **Ente ou autoridade**), nome, documento (CPF/CNPJ) e endereço via entidade **Address** centralizada — **todos** os campos de parte **opcionais**.
- **FR-007**: O sistema **DEVE** permitir **Responsável interno** (servidor/advogado institucional) opcional vinculado ao processo.
- **FR-008**: O sistema **DEVE** suportar bloco **Órgão e juízo** com campos estruturados opcionais: **Esfera** (Federal, Estadual, Municipal, Administrativo interno), **Tribunal/órgão**, **Comarca/seção**, **Varna/juízo** — **sem** catálogo externo de tribunais.
- **FR-009**: O sistema **DEVE** permitir **Observações** em texto livre.
- **FR-010**: O sistema **DEVE** permitir **Prazo processual** e **Valor da causa** opcionais; valor da causa alimenta cálculo de Probabilidade de Perda quando informado.
- **FR-011**: O sistema **DEVE** aceitar anexos nos formatos: `.pdf`, `.doc`, `.docx`, `.txt`, `.jpeg`, `.jpg`, `.png`, `.bmp`, `.xls`, `.xlsx`, `.mp3`, `.mp4`, com limite de **30 MB** por arquivo.
- **FR-012**: O sistema **DEVE** rejeitar anexos fora dos tipos ou acima do limite com mensagem clara antes da confirmação.
- **FR-013**: O sistema **DEVE** armazenar binários de anexos em serviço de **object storage** gerenciado pela plataforma; o registro do processo persiste apenas metadados e referência ao conteúdo.
- **FR-014**: O sistema **DEVE** exibir **Lista de Processos** com colunas Número, Tipo, Partes (resumo), Status, Prazo e Responsável, e filtros por tipo, status operacional e prazo.
- **FR-015**: O sistema **DEVE** exibir detalhe com dados do registro, partes, órgão e juízo, observações, anexos e **linha do tempo** de eventos.
- **FR-016**: O sistema **DEVE** manter status operacionais da Base em conjunto fechado distinto de conformidade Jatobá: *Aberto*, *Crítico*, *Vencendo*, *Concluído* (e estados derivados de tramitação interna quando aplicável).
- **FR-017**: O sistema **DEVE** calcular e exibir *Crítico* ou *Vencendo* com base no **Prazo processual** e data corrente — responsabilidade operacional da Base.
- **FR-018**: O sistema **DEVE** aplicar permissão por setor ao módulo Jurídico conforme regras de vínculo módulo–setor existentes, incluindo tela **403 · Acesso negado** padronizada.
- **FR-019**: O sistema **DEVE** isolar processos, partes, endereços e anexos por tenant.

#### Dashboard

- **FR-020**: O sistema **DEVE** exibir **Dashboard Jurídico** em `/juridico/dashboard` com indicadores **Processos Abertos**, **Prazos Críticos**, **Pareceres (mês)** e **Conformidade Legal** derivados de registros reais do tenant.
- **FR-021**: O indicador **Conformidade Legal** **DEVE** refletir taxa de conformidade da execução Jatobá mais recente — **não** confundir com status operacional.

#### Jatobá — Fiscalização

- **FR-022**: Fiscalização Jurídica **DEVE** usar **exclusivamente** dados internos do tenant (processos confirmados, eventos, partes, anexos, órgão/juízo, valor da causa).
- **FR-023**: Fiscalização **DEVE** ser **somente leitura** em relação ao registro operacional — nenhuma ação Jatobá **DEVE** alterar status, prazo, campos ou eventos do processo.
- **FR-024**: Classificação de conformidade **DEVE** usar **somente** os quatro status canônicos: **Conforme**, **Não conforme**, **Parcial**, **Pendente**.
- **FR-025**: O sistema **DEVE** calcular **Probabilidade de Perda** por processo via **regras determinísticas** sobre: tipo, proximidade/vencimento de prazo, status operacional, presença e quantidade de anexos, valor da causa (quando informado) — produzindo faixa **Baixa**, **Média**, **Alta** ou **Indeterminada**.
- **FR-026**: **Probabilidade de Perda** **DEVE** ser exibida no painel de Fiscalização por processo e **DEVE** ser explicável no rastreio da checagem correspondente; **PODE** aparecer como badge consultivo no detalhe do processo.
- **FR-027**: Checagens automáticas **DEVEM** incluir, quando aplicável: **Probabilidade de Perda**, **Prazos processuais**, **Completude cadastral**, **Identificação judicial**, **Anexos e evidências**, **Consistência de partes**.
- **FR-028**: O sistema **DEVE** persistir **execuções de fiscalização** com data/hora, origem, tenant, quantidade de registros analisados e resumo de conformidade — padrão equivalente ao módulo Ouvidoria.
- **FR-029**: O sistema **DEVE** permitir disparo manual (*Fiscalizar processos*) com limite de frequência institucional por tenant e execução agendada periódica (padrão: diária).
- **FR-030**: O sistema **DEVE** suportar questionários internos e externos (destinatário **Parte externa** quando parte identificável com contato), banco de perguntas editável do domínio Jurídico e fiscalização contextual no detalhe — canais externos simulados (link/token) na v1.
- **FR-031**: Detalhe do processo **DEVE** exibir card **Fiscalização Jatobá deste registro** com checagens da última execução e ação *Fiscalizar dados* scoped ao registro.

#### Cedro — Insights

- **FR-032**: Insights Cedro **DEVEM** ser **somente leitura** e derivados de agregações determinísticas sobre processos confirmados — **sem** modelo de IA generativa ou integrações externas de jurisprudência.
- **FR-033**: Foco consultivo **DEVE** refletir *Jurisprudência e risco processual*: concentração por tipo, órgão, prazos críticos, distribuição de Probabilidade de Perda e volume operacional.
- **FR-034**: O sistema **DEVE** persistir lotes de insights com geração híbrida: agenda institucional, histórico consultável, exibição da geração mais recente ao abrir a tela e recálculo sob demanda (*Consultar IA*) com throttling.
- **FR-035**: Cada insight **DEVE** exibir impacto **Crítico**, **Alto** ou **Médio**, fonte *Dados internos — Jurídico* e recomendação consultiva.

#### Carvalho — Maturidade

- **FR-036**: Score de maturidade **DEVE** combinar autoavaliação da equipe e conformidade Jatobá por eixo conforme fórmula híbrida institucional — score indisponível quando autoavaliação do período não respondida.
- **FR-037**: Dashboard **DEVE** exibir radar dos três eixos, evolução temporal, indicadores operacionais canônicos do Jurídico e planos de ação com CRUD.
- **FR-038**: Planos de ação **DEVEM** ser a principal operação de escrita da tela Maturidade além da autoavaliação — scores permanecem somente leitura.

#### Rastreabilidade e UI

- **FR-039**: Rastreio **DEVE** abrir em **sheet inferior** (~85% da viewport) com títulos canônicos por contexto — **NUNCA** em rota dedicada.
- **FR-040**: UI **DEVE** usar vocabulário normativo: módulo **Jurídico**, licença **Jatobá** (tela **Fiscalização**), **Cedro** (**Insights IA**), **Carvalho** (**Maturidade**), badge **Somente leitura** — **NUNCA** *Read-only* em UI pt-BR.
- **FR-041**: O sistema **DEVE** substituir dados mock das rotas `/juridico/*` listadas por páginas e dados reais do tenant — **zero** linhas fixas de demonstração após implementação.

### Fronteiras entre licenças (obrigatório)

| Licença | O que faz neste contexto | O que **NÃO** faz |
| --- | --- | --- |
| **Base** | Wizard CRUD, lista, detalhe, dashboard, timeline, status operacional, anexos | Classificar conformidade; calcular Probabilidade de Perda; gerar insights; score Carvalho |
| **Jatobá** | Checagens registro-a-registro; Probabilidade de Perda; achados; questionários; banco de perguntas do domínio Jurídico | Alterar registros operacionais; insights estratégicos Cedro |
| **Cedro** | Insights consultivos read-only sobre risco processual e padrões agregados | Conformidade operacional; questionários; alterar processos |
| **Carvalho** | Score de maturidade macro; autoavaliação; planos de ação; indicadores executivos | Fiscalizar registro a registro; CRUD de processos |
| **Pau-Brasil** | *(fora desta spec)* botões contextuais permanecem mock | — |

### Key Entities

- **Processo**: Registro central jurídico; tipo, número interno, número judicial/CNJ opcional, assunto, observações, prazo, valor da causa, status operacional, responsável interno, referências a órgão/juízo estruturado e timeline.
- **Parte do processo**: Vínculo a polo (ativo, passivo, outro); tipo de pessoa; nome; documento; referência opcional a **Address** centralizado.
- **Órgão e juízo**: Esfera, tribunal/órgão, comarca/seção, vara/juízo — atributos opcionais do processo.
- **Anexo do processo**: Metadados de documento (nome, tipo, tamanho, referência ao conteúdo armazenado); vinculado ao processo.
- **Evento de timeline**: Marco auditável (abertura, parecer, revisão, encaminhamento, observação) com timestamp, autor e descrição.
- **Número interno**: Identificador institucional único legível (`JUR-AAAA-NNNN`) gerado na confirmação; imutável.
- **Execução de fiscalização**: Rodada de análise Jatobá com instante, origem, tenant, resumo de conformidade e resultados por processo.
- **Probabilidade de Perda**: Métrica derivada por regras determinísticas; faixa Baixa/Média/Alta/Indeterminada; explicável no rastreio.
- **Checagem automática / Achado**: Regra nomeada, campos avaliados, status de conformidade, processo afetado.
- **Lote de insights / Insight Cedro**: Agregação persistida; título, resumo, impacto, recomendação, fonte interna.
- **Score de maturidade / Plano de ação Carvalho**: Diagnóstico por eixo; planos rastreáveis com responsável e prazo.
- **Address**: Endereço normalizado global da plataforma, escopo tenant; reutilizado por partes — **sem** duplicação de estrutura de logradouro em tabelas do módulo Jurídico.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Servidor consegue registrar processo completo (dados, anexos, revisão) em **menos de 5 minutos** em testes de aceitação com usuário treinado.
- **SC-002**: **100%** dos envios confirmados recebem número interno único — zero colisões em testes de carga moderada por tenant.
- **SC-003**: **100%** dos anexos inválidos (tipo ou tamanho) são rejeitados antes da confirmação, com mensagem compreensível.
- **SC-004**: Equipe localiza processo por número ou filtros na lista em **menos de 30 segundos** em 95% dos casos medidos.
- **SC-005**: Fiscalização manual analisa **100%** dos processos confirmados do tenant e exibe **Probabilidade de Perda** para cada registro analisado.
- **SC-006**: **Nenhuma** ação Jatobá, Cedro ou Carvalho altera status operacional ou eventos do processo — validável comparando registro antes e depois.
- **SC-007**: Insights Cedro refletem **zero** conteúdo de demonstração fixo quando tenant possui processos confirmados.
- **SC-008**: Score Carvalho exibe fórmula híbrida explicável via rastreio quando autoavaliação e Jatobá estão disponíveis.
- **SC-009**: Usuário autorizado alcança Fiscalização, Insights IA e Maturidade em **≤ 3 cliques** a partir do overview do Jurídico.
- **SC-010**: Zero casos em testes de aceitação em que usuário de tenant A visualiza processos ou anexos de tenant B.

## Assumptions

- Escopo cobre **substituição integral do mock** nas seis rotas operacionais/analíticas do Jurídico listadas; **Pau-Brasil** (modelos de parecer/petição) permanece mock nesta entrega.
- **Processos fiscalizados / analisados**: apenas registros **confirmados** (não rascunho, não excluídos logicamente) entram em fiscalização Cedro e Carvalho.
- **Probabilidade de Perda — fatores e faixas** (regras numéricas detalhadas na fase plan):
  - **Tipo**: processos **Judiciais** elevam peso base vs. **Administrativo**/**Consultivo**.
  - **Prazo**: vencido aumenta risco; ≤ 3 dias úteis sem justificativa eleva para **Alta**; faixa intermediária para proximidade (≤ 20% do tempo restante desde abertura).
  - **Status operacional**: *Crítico* contribui para elevação; *Concluído* reduz.
  - **Anexos**: ausência de anexo em processo **Judicial** ou **Administrativo** com parecer esperado eleva risco; presença de PDF assinado reduz.
  - **Valor da causa**: acima de limiar institucional configurável eleva risco (limiar default definido no plano).
  - **Indeterminada**: quando tipo **e** prazo estiverem ausentes, ou dados conflitantes insuficientes.
- **Defaults de limiar** e pesos exatos ficam para `/speckit-plan` (research.md); esta spec fixa fatores e pontos de exibição.
- Armazenamento de anexos reutiliza política de object storage da Ouvidoria (presigned upload, metadados por tenant/processo).
- Permissão de módulo segue spec **002-auth-setor-permissao**; Jurídico vinculado ao setor DEJUR no seed de demonstração.
- Questionários externos Jatobá: canal WhatsApp ou E-mail registrado como metadado; link/token copiável — **sem** integração real com provedores na v1.
- Score Carvalho: fórmula híbrida `round(0,6 × autoavaliação + 0,4 × conformidade Jatobá)` por eixo; autoavaliação trimestral padrão; indicadores operacionais canônicos incluem volume, prazos críticos, taxa de conformidade legal e pareceres no mês.
- Cedro: agregações determinísticas apenas — branding **Insights IA** mantido sem prometer IA generativa.
- Tramitação cross-module (`LEGAL_PROCESS`) e integração PJe/Receita/OAB/CNJ em tempo real estão **fora de escopo** v1.
- Copy de interface segue [regras-plataforma.md](../../.cursor/docs/regras-plataforma.md) e [licencas-canonicas.md](../../.cursor/docs/licencas-canonicas.md).
- Comportamento de fiscalização, insights e maturidade **espelha** padrões validados nas specs **007**, **008** e **009** de Ouvidoria, adaptados ao domínio Jurídico e prefixo `/juridico/`.

## Out of Scope

- Integração em tempo real com PJe, Receita Federal, OAB ou bases CNJ.
- Pau-Brasil operacional (geração de pareceres/petições a partir de modelos).
- WhatsApp Business API, SMS ou SMTP transacional para questionários externos.
- Admin SaaS (spec 011) e Central global de Fiscalização (`/global/auditoria`).
- Tramitação cross-module com Protocolo, Contratos ou Compras.
- Consulta pública de andamento de processo sem autenticação (exceto formulário tokenizado de resposta a questionário externo).
- Reabertura automática de processo concluído; workflow de aprovação multinível.
- Migração de dados legados de sistemas anteriores.
