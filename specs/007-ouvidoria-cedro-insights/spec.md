# Feature Specification: Insights Cedro — Ouvidoria (análise interna)

**Feature Branch**: `007-ouvidoria-cedro-insights`

**Created**: 2026-06-19

**Status**: Draft

**Input**: User description: "Insights IA Cedro na rota /ouvidoria/insights — análise consultiva de dados internos de manifestações (sem modelo de IA, sem integrações externas). Geração híbrida: job agendado, histórico persistido e recálculo ao abrir a tela. Manter branding Insights IA Cedro. Escopo v2 completo: operacional, geográfico, padrões de texto simples e mix de prioridade/perfil."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Ver painel de Insights IA na Ouvidoria (Priority: P1)

Como servidor autenticado com acesso ao módulo Ouvidoria, preciso abrir a tela **Insights IA** (`/ouvidoria/insights`) e ver insights consultivos Cedro derivados dos dados internos de manifestações do meu órgão, para orientar decisões estratégicas sem alterar registros operacionais.

**Why this priority**: É a entrega central da licença Cedro no módulo; sem painel real substituindo mocks, a rota não entrega valor institucional.

**Independent Test**: Autenticar usuário do setor Ouvidoria, navegar ao overview e abrir Insights IA em até três cliques; verificar lista com título, resumo, impacto, recomendação, fonte *Dados internos — Ouvidoria*, badge **Somente leitura** e ação de rastreio — todos refletindo agregações reais do tenant, não dados fictícios.

**Acceptance Scenarios**:

1. **Given** usuário com permissão no módulo Ouvidoria, **When** acessa `/ouvidoria/insights`, **Then** vê painel Cedro com insights da geração mais recente, título da tela alinhado ao branding **Insights IA** e descrição consultiva que não promete alteração automática de dados.
2. **Given** insight exibido, **When** o usuário lê o card, **Then** vê impacto classificado como **Crítico**, **Alto** ou **Médio**, fonte *Dados internos — Ouvidoria* e recomendação em linguagem imperativa consultiva (orienta, não executa).
3. **Given** qualquer insight na lista, **When** o usuário aciona *De onde veio este insight?*, **Then** abre sheet inferior (~85% da viewport) com rastreabilidade — **sem** navegar a rota dedicada de rastreio.
4. **Given** tenant com manifestações confirmadas (fora de `draft`), **When** a tela carrega, **Then** os insights refletem agregações sobre esses registros — não conteúdo de demonstração fixo.

---

### User Story 2 - Insights operacionais de fila e fluxo (Priority: P1)

Como gestor da Ouvidoria, preciso que o sistema identifique padrões operacionais na fila de manifestações — volume por tipo, status, prioridade, assunto, forma de atendimento, backlog, tempo entre etapas da linha do tempo e gargalos de tramitação por setor — para priorizar ações de melhoria de processo.

**Why this priority**: A maior parte do valor consultivo Cedro para Ouvidoria está em entender fila, fluxo e gargalos institucionais.

**Independent Test**: Popular tenant com manifestações de tipos, status e eventos distintos; gerar insights e verificar presença de agregações operacionais com exemplos de protocolo no rastreio.

**Acceptance Scenarios**:

1. **Given** manifestações com tipos e status variados, **When** insights são gerados, **Then** pelo menos um insight operacional resume volume ou concentração por tipo, status, prioridade, categoria/assunto ou forma de atendimento.
2. **Given** manifestações não encerradas, **When** insights são gerados, **Then** o sistema pode destacar backlog e *aging* por faixas temporais (ex.: abertas há mais de 30 dias).
3. **Given** manifestações com eventos de registro, encaminhamento, resposta e encerramento, **When** insights são gerados, **Then** o sistema calcula tempos médios entre etapas da linha do tempo — derivados dos eventos, não de campo de prazo operacional inexistente no registro.
4. **Given** encaminhamentos a setores distintos, **When** insights são gerados, **Then** o sistema pode identificar setores destino com maior volume ou maior tempo em tramitação como gargalo consultivo.

---

### User Story 3 - Insights geográficos (Priority: P1)

Como gestor da Ouvidoria, preciso ver concentração geográfica de manifestações por município e bairro/zona quando houver endereço associado, para identificar áreas com demanda recorrente acima da média institucional.

**Why this priority**: O modelo canônico de endereço centralizado permite visão territorial estratégica sem duplicar campos por módulo.

**Independent Test**: Registrar manifestações com endereços em municípios/bairros distintos; verificar insight geográfico com pico identificado e evidências no rastreio.

**Acceptance Scenarios**:

1. **Given** manifestações com endereço e município informado, **When** insights são gerados, **Then** o sistema pode destacar municípios ou bairros/zonas com volume acima da média do tenant no período analisado.
2. **Given** manifestação sem endereço, **When** insights geográficos são calculados, **Then** esses registros entram apenas em totais gerais — não forçam localização fictícia.
3. **Given** insight geográfico exibido, **When** o usuário abre rastreio, **Then** vê período analisado, regra de comparação (ex.: vs. média institucional) e exemplos de protocolos na área destacada — sem expor dados identificáveis do manifestante.

---

### User Story 4 - Padrões de texto por agregação simples (Priority: P2)

Como analista da Ouvidoria, preciso identificar assuntos e termos mais frequentes nos relatos, via contagem estatística determinística, para antecipar demandas recorrentes sem depender de modelo de linguagem ou análise de sentimento.

**Why this priority**: Complementa visão operacional com leitura temática; secundário à fila mas valioso para planejamento institucional.

**Independent Test**: Registrar manifestações com assuntos/descrições repetindo termos específicos; verificar insight de top termos/assuntos sem invocar serviço externo de NLP.

**Acceptance Scenarios**:

1. **Given** corpus de assuntos e descrições no tenant, **When** insights são gerados, **Then** o sistema produz insight com termos ou assuntos mais frequentes (top-N) por contagem simples.
2. **Given** análise de texto, **When** o insight é produzido, **Then** a fonte permanece *Dados internos — Ouvidoria* e o rastreio descreve regras de tokenização/agrupamento — **sem** referência a NLP, embeddings ou IA generativa.
3. **Given** descrições muito curtas ou homogêneas, **When** não há padrão significativo, **Then** o sistema omite insight de texto ou declara ausência de padrão — **nunca** inventa tendência.

---

### User Story 5 - Mix de prioridade e perfil das manifestações (Priority: P2)

Como gestor da Ouvidoria, preciso consultar proporções consultivas — taxa de manifestações anônimas, relação denúncias vs. elogios, picos de prioridade urgente/alta e correlações tipo × prioridade — para calibrar políticas de atendimento.

**Why this priority**: Perfil da demanda orienta capacidade e priorização institucional sem substituir alarmes operacionais da Base ou Jatobá.

**Independent Test**: Criar mix conhecido de tipos, prioridades e anonimato; validar insight de perfil com números coerentes no rastreio.

**Acceptance Scenarios**:

1. **Given** manifestações com mix de `isAnonymous`, tipos e prioridades, **When** insights são gerados, **Then** o sistema pode exibir insight de perfil (ex.: aumento de denúncias urgentes ou alta taxa de anônimas no período).
2. **Given** insight de perfil, **When** exibido, **Then** impacto e recomendação são consultivos — não alteram prioridade nem status de registros.
3. **Given** manifestação anônima usada como evidência no rastreio, **When** o usuário abre o rastreio, **Then** vê apenas protocolo, tipo, status e datas — **nunca** nome, documento ou contato do manifestante.

---

### User Story 6 - Geração híbrida, histórico e recálculo (Priority: P1)

Como usuário da tela Insights IA, preciso que insights sejam gerados automaticamente em agenda institucional, persistidos com histórico consultável, exibidos da última geração ao abrir a tela e recalculáveis sob demanda via ação equivalente a *Consultar IA*, para equilibrar atualidade e desempenho.

**Why this priority**: Modelo híbrido foi definido como requisito de produto v2; sem persistência e agenda, a tela depende só de cálculo ao vivo ou só de batch.

**Independent Test**: Executar geração agendada, abrir tela (última geração), listar histórico com duas gerações anteriores, acionar recálculo e verificar throttling.

**Acceptance Scenarios**:

1. **Given** agenda institucional ativa (padrão: diária por tenant), **When** o job executa, **Then** um novo lote de insights é persistido com data/hora, origem *agendada* e contagem de insights produzidos.
2. **Given** usuário abre `/ouvidoria/insights`, **When** existe geração anterior, **Then** a tela exibe insights da geração mais recente sem exigir recálculo imediato.
3. **Given** múltiplas gerações persistidas, **When** o usuário consulta histórico, **Then** vê lista com data, origem (agendada, sob demanda, ao abrir) e quantidade de insights — permitindo comparar pelo menos duas gerações anteriores à atual.
4. **Given** usuário aciona *Consultar IA* / *Recalcular agora*, **When** não há recálculo na última hora para o tenant, **Then** nova geração é executada e persistida com origem *sob demanda*.
5. **Given** recálculo já executado na última hora, **When** o usuário tenta novamente, **Then** recebe mensagem clara de limite de frequência e continua vendendo a geração mais recente — sem erro silencioso.

---

### User Story 7 - Rastreabilidade Cedro somente com fontes internas (Priority: P1)

Como usuário que precisa confiar no insight, preciso entender como ele foi produzido — regras aplicadas, período analisado, filtros e protocolos de exemplo — exclusivamente a partir de dados internos, para validar a recomendação antes de agir na Base.

**Why this priority**: Rastreabilidade é regra de plataforma (R-40) e diferencia Cedro consultivo de “caixa-preta”.

**Independent Test**: Abrir rastreio de qualquer insight e verificar passos de raciocínio, registros de exemplo e ausência de consultas externas.

**Acceptance Scenarios**:

1. **Given** insight exibido, **When** o usuário abre *De onde veio este insight?*, **Then** o sheet lista passos de raciocínio (regras, período, filtros) em ordem legível.
2. **Given** rastreio aberto, **When** há evidências, **Then** protocolos de exemplo aparecem com campos agregados usados (tipo, status, datas) — link ou navegação ao detalhe da manifestação quando permitido.
3. **Given** qualquer rastreio Cedro de Ouvidoria, **When** exibido, **Then** **não** há seção de consultas externas (Fala.BR, NLP, benchmarks nacionais, etc.).
4. **Given** insight Cedro, **When** exibido em qualquer contexto, **Then** badge **Somente leitura** está visível — nunca *Read-only* em UI pt-BR.

---

### User Story 8 - Acesso, licença e sigilo (Priority: P1)

Como administrador de governança, preciso que apenas usuários autorizados ao módulo Ouvidoria com licença Cedro acessem insights, e que agregações respeitem anonimato e sigilo — sem expor PII em listagens ou rastreio.

**Why this priority**: Segurança e conformidade são bloqueadores para produção em órgão público.

**Independent Test**: Usuário sem módulo (403), usuário com módulo sem Cedro (conforme política de licença global), manifestação anônima em evidência.

**Acceptance Scenarios**:

1. **Given** usuário sem permissão no módulo Ouvidoria, **When** tenta acessar `/ouvidoria/insights`, **Then** recebe **403 · Acesso negado** com copy padronizada — item pode permanecer visível na navegação.
2. **Given** usuário autorizado, **When** consome insights, **Then** acesso está condicionado à licença Cedro ativa no tenant (conjunto fixo de quatro licenças na plataforma).
3. **Given** manifestações anônimas ou com restrição de identificação, **When** insights e rastreio são exibidos, **Then** agregações não revelam nome, documento, e-mail ou telefone do manifestante.
4. **Given** tenant sem manifestações confirmadas suficientes para análise (ver Assumptions), **When** a tela carrega, **Then** estado vazio orienta operação (*registre manifestações para habilitar insights*) — **sem** insights fabricados.

---

### Edge Cases

- Tenant sem manifestações confirmadas (apenas `draft` ou zero registros): estado vazio; job agendado não cria insights fictícios.
- Manifestações sem endereço: insights geográficos omitidos ou limitados a totais sem localização.
- Falha do job agendado: última geração bem-sucedida permanece visível; usuário informado se geração está desatualizada além de 48h.
- Recálculo sob demanda durante job agendado: uma geração por tenant em execução — segunda solicitação aguarda ou retorna mensagem de processamento em andamento.
- Throttling de recálculo (1x por hora): mensagem clara; não bloqueia leitura do histórico.
- Volume muito baixo no período (ex.: &lt; 5 manifestações): insights de texto e correlação podem ser omitidos por insuficiência estatística.
- Sigilo em denúncias: evidências no rastreio seguem mesma regra de PII que manifestações anônimas.
- Usuário abre tela sem geração prévia e sem recálculo recente: sistema pode disparar geração com origem *ao abrir* ou exibir estado vazio com CTA *Consultar IA* — conforme desempenho (ver Assumptions).
- Comparação histórica quando só existe uma geração: histórico mostra entrada única sem erro.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: O sistema **DEVE** produzir insights Cedro de Ouvidoria usando **exclusivamente** dados internos do tenant (manifestações confirmadas, eventos da linha do tempo, endereços vinculados, catálogos de assunto e forma de atendimento).
- **FR-002**: Insights **DEVEM** ser **somente leitura** — nenhuma ação na tela ou via API de insights **DEVE** alterar manifestações, eventos, status operacional ou classificação de conformidade.
- **FR-003**: Cada insight **DEVE** classificar impacto como **Crítico**, **Alto** ou **Médio**, alinhado ao vocabulário canônico Cedro da plataforma.
- **FR-004**: Cada insight **DEVE** exibir fonte *Dados internos — Ouvidoria* — **NUNCA** citar integração externa ou serviço de terceiros como origem.
- **FR-005**: O sistema **DEVE** persistir **lotes de geração** com data/hora, origem (agendada, sob demanda, ao abrir), tenant e quantidade de insights produzidos.
- **FR-006**: O sistema **DEVE** executar geração **agendada periódica** por tenant (padrão: diária).
- **FR-007**: Ao abrir `/ouvidoria/insights`, o sistema **DEVE** exibir insights da geração mais recente disponível.
- **FR-008**: O sistema **DEVE** permitir **recálculo sob demanda** (ação *Consultar IA*) com limite de **uma execução por hora por tenant**.
- **FR-009**: O sistema **DEVE** permitir consultar **histórico** de gerações com data, origem e contagem — suportando comparação de pelo menos duas gerações anteriores quando existirem.
- **FR-010**: Insights operacionais **DEVEM** cobrir, quando dados permitirem: volume por tipo, status, prioridade, categoria/assunto, forma de atendimento; backlog e aging; tempos entre eventos da linha do tempo; gargalos de tramitação por setor destino.
- **FR-011**: Métricas de tempo de resposta ou tramitação **DEVEM** derivar de **eventos** (registro, encaminhamento, resposta, encerramento) — **NUNCA** de campo de prazo operacional no registro (não existente na modelagem atual de manifestação).
- **FR-012**: Insights geográficos **DEVEM** usar município (código IBGE) e bairro/zona do endereço canônico quando presente.
- **FR-013**: Análise de texto **DEVE** usar apenas agregação determinística (contagem, top-N, co-ocorrência simples) — **NUNCA** invocar modelo de linguagem, NLP, embeddings ou análise de sentimento automatizada.
- **FR-014**: Insights de perfil **DEVEM** poder incluir taxa de anônimas, proporções por tipo e prioridade e correlações consultivas tipo × prioridade.
- **FR-015**: Cedro **PODE** apontar **tendências** relacionadas a prazos ou tempo de resposta (ex.: aumento de reclamações associadas a demora) — **NUNCA** contar dias de SLA, disparar alerta operacional por registro nem classificar conformidade Jatobá.
- **FR-016**: Rastreio **DEVE** abrir em **sheet inferior** (~85% da viewport) — **NUNCA** em rota dedicada `/rastreio/:id`.
- **FR-017**: Rastreio **DEVE** incluir passos de raciocínio, período analisado, regras/filtros e protocolos de exemplo — **SEM** seção de consultas externas.
- **FR-018**: Agregações e evidências **NÃO DEVEM** expor PII de manifestante (nome, documento, e-mail, telefone) — inclusive em manifestações anônimas ou sujeitas a sigilo.
- **FR-019**: Acesso **DEVE** exigir permissão no módulo Ouvidoria; consumo **DEVE** estar sob licença Cedro.
- **FR-020**: Tenant sem dados suficientes **DEVE** ver estado vazio orientativo — **NUNCA** insights simulados ou de demonstração fixa em produção.
- **FR-021**: UI **DEVE** manter branding **Insights IA** e ação *Consultar IA* como nomenclatura Cedro — copy **DEVE** deixar claro que o resultado é consultivo e não altera registros (*NUNCA* prometer “a IA corrigirá…”).
- **FR-022**: Escopo **limita-se** ao módulo Ouvidoria (`/ouvidoria/insights`) — **NÃO** inclui Painel global de Dados & IA nem novas capacidades Carvalho, Pau-Brasil ou Jatobá.

### Fronteiras entre licenças (obrigatório)

| Licença | O que faz neste contexto | O que **NÃO** faz |
| --- | --- | --- |
| **Base** | CRUD, tramitação, status operacional, linha do tempo, contagem de dias no registro | Score Cedro, insights, conformidade |
| **Jatobá** | Alerta conformidade de SLA/prazo por registro; achados *Prazo vencido* | Insights estratégicos; tendência agregada read-only |
| **Carvalho** | Score de maturidade macro; planos de ação institucionais | Insights Cedro; alarme por registro |
| **Cedro (esta feature)** | Tendências e padrões agregados read-only; recomendações consultivas | Alterar registros; SLA operacional; conformidade Jatobá |

### Key Entities

- **Insight de Ouvidoria**: recomendação consultiva Cedro com título, resumo, recomendação, impacto (Crítico/Alto/Médio), categoria analítica (operacional, geográfico, texto, perfil), período analisado e descrição das regras aplicadas.
- **Lote de geração de insights**: instante de produção, origem (agendada, sob demanda, ao abrir), tenant, quantidade de insights e referência ao conjunto de insights filhos.
- **Evidência de insight**: vínculo a manifestação por protocolo com campos agregados usados (tipo, status, datas, localização quando aplicável) — sem PII do manifestante.
- **Histórico de gerações**: sequência ordenada de lotes consultável pelo usuário para comparação temporal.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Usuário alcança a tela Insights IA em **≤ 3 cliques** a partir do overview de Ouvidoria.
- **SC-002**: **100%** dos insights exibidos citam fonte interna — **zero** referência a integração externa na lista ou no rastreio.
- **SC-003**: Recálculo sob demanda completa em **≤ 30 segundos** para tenants com até **10.000** manifestações confirmadas.
- **SC-004**: Quando existem ≥ 3 gerações persistidas, o usuário **DEVE** poder visualizar e comparar pelo menos **2 gerações anteriores** à mais recente no histórico.
- **SC-005**: **Nenhuma** ação na tela de insights altera status, prioridade, prazo operacional ou conformidade de registros — validável por auditoria de que manifestações e eventos permanecem idênticos antes e depois do uso.
- **SC-006**: **100%** dos rastreios abrem em sheet inferior — **zero** navegação a rota dedicada de rastreio.
- **SC-007**: Em teste com manifestações anônimas, **zero** exposição de PII em cards agregados e em evidências do rastreio.

## Assumptions

- **Manifestações analisadas**: apenas registros **confirmados** (status diferente de `draft` e não excluídos logicamente) entram nas agregações.
- **Período padrão de análise**: últimos **90 dias** corridos, configurável em fase futura; v2 usa janela fixa documentada no rastreio.
- **Mínimo estatístico**: insights de texto e correlação exigem pelo menos **5** manifestações no período para a dimensão analisada; abaixo disso, categoria omitida.
- **Agenda**: geração diária por tenant, horário configurável em implementação; falha não apaga histórico anterior.
- **Throttling**: uma recálculo sob demanda por tenant por hora; leitura e histórico não contam no limite.
- **Geração ao abrir**: se não há lote recente (&lt; 24h) e carga estimada ≤ 10.000 manifestações, o sistema **PODE** disparar geração com origem *ao abrir*; se carga maior, exibe último lote ou estado vazio com CTA.
- **Tempo de resposta**: derivado de diferença entre eventos `registration` → `response` ou `closure`; manifestações sem evento de resposta usam apenas encerramento ou são excluídas da média com contagem explícita no rastreio.
- **Prazo operacional**: campo `prazo` no registro de manifestação **não existe** na modelagem v1/v2 ouvidoria — esta feature **não** introduz esse campo; Cedro não substitui contagem da Base quando prazo for adicionado em feature futura.
- **Branding IA**: *Insights IA* e *Consultar IA* são nomenclatura de produto Cedro; por baixo, execução é análise estatística interna — sem modelo de linguagem.
- **Sigilo**: regras de visibilidade de PII no detalhe de manifestação aplicam-se igualmente às evidências Cedro.
- **Dependências**: módulo Ouvidoria Base operacional (003-ouvidoria) e endereço canônico (006-shared-address-hooks) já disponíveis para leitura de `Address` e município IBGE.

## Out of Scope

- Modelos de linguagem, NLP, embeddings, análise de sentimento automatizada.
- Integrações Cedro externas (Fala.BR, CGU, PNCP, Portal Legislativo, NLP externo, etc.).
- Painel global `/global/painel-ia` e consolidação cross-módulo.
- Novas funcionalidades Carvalho, Pau-Brasil ou Jatobá.
- Introdução de campo `prazo` operacional na manifestação.
- Exportação PDF de insights.
- Alteração de registros ou fluxos operacionais a partir de recomendações Cedro.
- Canal público de ouvidoria e consulta de andamento sem autenticação.
