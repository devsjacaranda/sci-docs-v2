# Feature Specification: Insights Cedro — Gabinete (integração completa)

**Feature Branch**: `015-gabinete-cedro-insights-integrado`

**Created**: 2026-06-24

**Status**: Draft

**Input**: User description: "Implementar Insights com IA no Gabinete, integrando tudo — atos, protocolo, controle numérico, notificações e autos e documentos tramitados. Módulo Gabinete. Contexto: atualmente Insights Cedro — Gabinete não funciona e não atende todo escopo."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Painel Insights IA funcional no Gabinete (Priority: P1)

Como gestor institucional com acesso ao módulo Gabinete, preciso abrir a tela **Insights IA** (`/gabinete/insights`) e ver insights consultivos Cedro derivados dos dados internos reais do meu órgão — atos, protocolos, controles numéricos, notificações/autos e documentos tramitados — para orientar decisões estratégicas **sem** alterar registros operacionais.

**Why this priority**: A rota existe mas não entrega valor: a tela atual não reflete o padrão Cedro da Ouvidoria nem produz insights úteis a partir de todos os cadastros do Gabinete.

**Independent Test**: Autenticar usuário do setor Gabinete com licença Cedro; popular tenant com atos e cadastros vinculados ou standalone; abrir `/gabinete/insights` em até três cliques; verificar lista com título, resumo, impacto, recomendação, fonte *Dados internos — Gabinete*, badge **Somente leitura**, ação *De onde veio este insight?* e ação *Consultar IA* — todos refletindo agregações reais, não lista simplificada ou dados fictícios.

**Acceptance Scenarios**:

1. **Given** usuário com permissão no módulo Gabinete e licença Cedro, **When** acessa `/gabinete/insights`, **Then** vê painel Cedro com insights da geração mais recente, branding **Insights IA** e copy consultiva que **não** promete alteração automática de dados.
2. **Given** insight exibido, **When** o usuário lê o card, **Then** vê impacto classificado como **Crítico**, **Alto** ou **Médio**, fonte *Dados internos — Gabinete* e recomendação em linguagem imperativa consultiva (orienta, não executa).
3. **Given** tenant com atos confirmados e cadastros de protocolo/controles/documentos tramitados, **When** a tela carrega, **Then** os insights refletem agregações sobre esses registros — **não** conteúdo de demonstração fixo.
4. **Given** geração bem-sucedida, **When** o painel exibe stats de cabeçalho, **Then** mostra quantidade de insights ativos, data da última geração e contagem de impacto alto/crítico quando aplicável.

---

### User Story 2 - Insights operacionais de atos e encaminhamentos (Priority: P1)

Como gestor do Gabinete, preciso que o sistema identifique padrões operacionais nos **atos** (demandas) — volume por status, concentração por origem, backlog e aging, tempos entre eventos da linha do tempo e gargalos de encaminhamento por setor destino — para priorizar ações de melhoria de processo.

**Why this priority**: Atos são a entidade central do Gabinete; sem leitura operacional da fila, Cedro não entrega valor institucional.

**Independent Test**: Popular tenant com atos em status, origens e encaminhamentos distintos; gerar insights e verificar presença de agregações operacionais com exemplos de protocolo no rastreio.

**Acceptance Scenarios**:

1. **Given** atos com status variados, **When** insights são gerados, **Then** pelo menos um insight operacional resume volume ou concentração por status de fluxo.
2. **Given** atos com origens distintas (ex.: Ouvidoria, Gabinete, externo), **When** insights são gerados, **Then** o sistema pode destacar mix de origem acima da média no período.
3. **Given** atos não encerrados, **When** insights são gerados, **Then** o sistema pode destacar backlog e *aging* por faixas temporais (ex.: abertos há mais de 30 dias).
4. **Given** encaminhamentos a setores distintos, **When** insights são gerados, **Then** o sistema identifica setores destino com maior volume ou maior tempo em tramitação como gargalo consultivo.
5. **Given** atos com eventos de registro, encaminhamento e alteração de status, **When** insights são gerados, **Then** o sistema calcula tempos médios entre etapas da linha do tempo — derivados dos eventos, não de campo de prazo operacional inexistente.

---

### User Story 3 - Insights de protocolo e controle numérico (Priority: P1)

Como gestor do Gabinete, preciso consultar tendências sobre **protocolos** de entrada e **controles numéricos** (ofícios, portarias, memorandos, resoluções etc.), para entender concentração documental e possíveis gargalos de formalização.

**Why this priority**: Protocolo e controle numérico são cadastros centrais do Gabinete solicitados na integração; hoje não entram na análise Cedro.

**Independent Test**: Registrar protocolos com formas de entrada distintas e controles numéricos por tipo documental; gerar insights e verificar agregações com evidências no rastreio.

**Acceptance Scenarios**:

1. **Given** protocolos cadastrados (vinculados ou standalone), **When** insights são gerados, **Then** o sistema pode destacar concentração por forma de entrada, tipo de documento ou volume de protocolos sem ato vinculado.
2. **Given** controles numéricos por tipo documental, **When** insights são gerados, **Then** o sistema pode identificar tipo dominante (ex.: memorandos vs. ofícios) ou aumento de volume em relação ao período anterior quando houver histórico suficiente.
3. **Given** controle numérico ou protocolo standalone posteriormente vinculado a ato, **When** insights são recalculados, **Then** agregações refletem o vínculo atual — **sem** duplicar contagem.
4. **Given** insight sobre protocolo ou controle numérico, **When** o usuário abre rastreio, **Then** vê período analisado, regra aplicada e exemplos identificadores (número de protocolo, tipo documental) — **sem** expor remetente ou dados sigilosos além do necessário para rastreabilidade agregada.

---

### User Story 4 - Insights de notificações, autos e documentos tramitados (Priority: P1)

Como gestor do Gabinete, preciso ver tendências consultivas sobre **notificações**, **autos de infração** e **documentos tramitados por setor**, para calibrar capacidade e identificar concentração institucional.

**Why this priority**: Controles de notificação/autos e documentos tramitados foram explicitamente solicitados na integração; compõem visão estratégica distinta da fila de atos.

**Independent Test**: Cadastrar notificações, autos e documentos tramitados em setores distintos; gerar insights e validar categorias consultivas com números coerentes no rastreio.

**Acceptance Scenarios**:

1. **Given** notificações e autos cadastrados no tenant, **When** insights são gerados, **Then** o sistema pode exibir tendência de volume (ex.: aumento de autos emitidos ou notificações pendentes de resposta no período).
2. **Given** documentos tramitados com setores distintos, **When** insights são gerados, **Then** o sistema destaca setores com maior volume tramitado ou crescimento relativo no período analisado.
3. **Given** notificação e auto agrupados no mesmo caso, **When** agregados, **Then** contam como um caso para fins consultivos — **sem** inflar volume artificialmente.
4. **Given** insight sobre controles ou documentos tramitados, **When** exibido, **Then** impacto e recomendação são consultivos — **não** alteram status operacional de ato, notificação ou documento.

---

### User Story 5 - Geração híbrida, histórico e recálculo (Priority: P1)

Como usuário da tela Insights IA, preciso que insights sejam gerados automaticamente em agenda institucional, persistidos com histórico consultável, exibidos da última geração ao abrir a tela e recalculáveis sob demanda via *Consultar IA*, para equilibrar atualidade e desempenho.

**Why this priority**: O módulo API existe parcialmente, mas a experiência completa (agenda, histórico, throttling, estados vazios) não está entregue nem validada ponta a ponta.

**Independent Test**: Executar geração agendada, abrir tela (última geração), listar histórico com duas gerações anteriores, acionar *Consultar IA* e verificar throttling e mensagens de erro claras.

**Acceptance Scenarios**:

1. **Given** agenda institucional ativa (padrão: diária por tenant), **When** o job executa, **Then** um novo lote de insights é persistido com data/hora, origem *agendada* e contagem de insights produzidos.
2. **Given** usuário abre `/gabinete/insights`, **When** existe geração anterior, **Then** a tela exibe insights da geração mais recente **sem** exigir recálculo imediato.
3. **Given** múltiplas gerações persistidas, **When** o usuário consulta histórico, **Then** vê lista com data, origem (agendada, sob demanda, ao abrir) e quantidade de insights — permitindo comparar pelo menos duas gerações anteriores à atual.
4. **Given** usuário aciona *Consultar IA*, **When** não há recálculo na última hora para o tenant, **Then** nova geração é executada e persistida com origem *sob demanda*.
5. **Given** recálculo já executado na última hora, **When** o usuário tenta novamente, **Then** recebe mensagem clara de limite de frequência e continua vendo a geração mais recente — **sem** erro silencioso.

---

### User Story 6 - Rastreabilidade Cedro somente com fontes internas (Priority: P1)

Como usuário que precisa confiar no insight, preciso entender como ele foi produzido — regras aplicadas, período analisado, filtros e exemplos de protocolo/ato — exclusivamente a partir de dados internos do Gabinete, para validar a recomendação antes de agir na operação.

**Why this priority**: Rastreabilidade é regra de plataforma (R-40); a tela atual não oferece sheet de rastreio nem evidências.

**Independent Test**: Abrir rastreio de qualquer insight e verificar passos de raciocínio, registros de exemplo e ausência de consultas externas.

**Acceptance Scenarios**:

1. **Given** insight exibido, **When** o usuário aciona *De onde veio este insight?*, **Then** abre sheet inferior (~85% da viewport) com passos de raciocínio em ordem legível — **sem** navegar a rota dedicada de rastreio.
2. **Given** rastreio aberto, **When** há evidências, **Then** protocolos ou identificadores de exemplo aparecem com campos agregados usados (status, origem, tipo documental, setor) — com link ao detalhe do ato quando permitido.
3. **Given** qualquer rastreio Cedro do Gabinete, **When** exibido, **Then** **não** há seção de consultas externas (Fala.BR, NLP, benchmarks nacionais, etc.).
4. **Given** insight Cedro, **When** exibido em qualquer contexto, **Then** badge **Somente leitura** está visível — **nunca** *Read-only* em UI pt-BR.

---

### User Story 7 - Acesso, licença e estados vazios orientadores (Priority: P1)

Como administrador de governança, preciso que apenas usuários autorizados ao módulo Gabinete com licença Cedro acessem insights, e que tenants sem dados suficientes vejam orientação clara — **sem** insights fabricados.

**Why this priority**: Segurança, conformidade e confiança institucional são bloqueadores; estado vazio atual não diferencia causas nem orienta operação.

**Independent Test**: Usuário sem módulo (403), tenant sem atos confirmados, tenant só com cadastros standalone; validar mensagens e CTAs.

**Acceptance Scenarios**:

1. **Given** usuário sem permissão no módulo Gabinete, **When** tenta acessar `/gabinete/insights`, **Then** recebe **403 · Acesso negado** com copy padronizada — item pode permanecer visível na navegação.
2. **Given** usuário autorizado, **When** consome insights, **Then** acesso está condicionado à licença Cedro ativa no tenant.
3. **Given** tenant sem atos confirmados e sem cadastros analisáveis no período, **When** a tela carrega, **Then** estado vazio orienta operação (*cadastre atos e controles para habilitar insights*) — **sem** insights simulados.
4. **Given** tenant com cadastros mas volume insuficiente para categoria analítica específica, **When** insights são gerados, **Then** categorias sem significado estatístico são omitidas — **nunca** inventam tendência.

---

### Edge Cases

- Tenant sem atos confirmados (apenas rascunho ou zero registros) mas com protocolos/controles standalone: insights **podem** ser gerados a partir de cadastros standalone; estado vazio só quando **nenhuma** fonte interna tem volume no período.
- Ato sem protocolo vinculado: entra em agregações de atos; insight de protocolo pode destacar protocolos órfãos ou atos sem formalização documental.
- Controles vinculados vs. standalone: contagem única por registro; vínculo posterior atualiza próxima geração.
- Falha do job agendado: última geração bem-sucedida permanece visível; usuário informado se geração está desatualizada além de 48h.
- Recálculo sob demanda durante job agendado: uma geração por tenant em execução — segunda solicitação retorna mensagem de processamento em andamento.
- Throttling de recálculo (1x por hora): mensagem clara; não bloqueia leitura do histórico.
- Volume muito baixo no período (ex.: &lt; 5 registros na dimensão): insights de correlação ou texto podem ser omitidos por insuficiência estatística.
- Usuário abre tela sem geração prévia: exibe estado vazio com CTA *Consultar IA* ou dispara geração com origem *ao abrir* conforme carga estimada (ver Assumptions).
- Comparação histórica quando só existe uma geração: histórico mostra entrada única sem erro.
- Exclusão lógica de ato ou cadastro: registros excluídos **não** entram em agregações futuras.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: O sistema **DEVE** produzir insights Cedro do Gabinete usando **exclusivamente** dados internos do tenant: **atos** confirmados, **protocolos**, **controles numéricos**, **notificações**, **autos de infração**, **documentos tramitados**, eventos da linha do tempo e encaminhamentos.
- **FR-002**: Insights **DEVEM** ser **somente leitura** — nenhuma ação na tela ou via API de insights **DEVE** alterar atos, protocolos, controles, status operacional ou conformidade Jatobá.
- **FR-003**: Cada insight **DEVE** classificar impacto como **Crítico**, **Alto** ou **Médio**, alinhado ao vocabulário canônico Cedro da plataforma.
- **FR-004**: Cada insight **DEVE** exibir fonte *Dados internos — Gabinete* — **NUNCA** citar integração externa ou serviço de terceiros como origem.
- **FR-005**: O sistema **DEVE** persistir **lotes de geração** com data/hora, origem (agendada, sob demanda, ao abrir), tenant, janela de análise e quantidade de insights produzidos.
- **FR-006**: O sistema **DEVE** executar geração **agendada periódica** por tenant (padrão: diária).
- **FR-007**: Ao abrir `/gabinete/insights`, o sistema **DEVE** exibir insights da geração mais recente disponível.
- **FR-008**: O sistema **DEVE** permitir **recálculo sob demanda** (ação *Consultar IA*) com limite de **uma execução por hora por tenant**.
- **FR-009**: O sistema **DEVE** permitir consultar **histórico** de gerações com data, origem e contagem — suportando comparação de pelo menos duas gerações anteriores quando existirem.
- **FR-010**: Insights operacionais sobre **atos** **DEVEM** cobrir, quando dados permitirem: volume por status; mix de origem; backlog e aging; tempos entre eventos da linha do tempo; gargalos de encaminhamento por setor destino.
- **FR-011**: Insights sobre **protocolo** **DEVEM** poder incluir volume por forma de entrada, tipo de documento e protocolos sem ato vinculado.
- **FR-012**: Insights sobre **controle numérico** **DEVEM** poder incluir concentração por tipo documental (ofício, portaria, memorando, resolução etc.).
- **FR-013**: Insights sobre **notificações e autos** **DEVEM** poder incluir tendência de volume e relação notificação/auto no período.
- **FR-014**: Insights sobre **documentos tramitados** **DEVEM** poder incluir concentração e tendência por setor tramitador.
- **FR-015**: Métricas de tempo **DEVEM** derivar de **eventos** da linha do tempo e encaminhamentos — **NUNCA** de campo de prazo operacional inexistente no registro.
- **FR-016**: Análise **DEVE** usar apenas agregação determinística (contagem, proporção, top-N, médias temporais) — **NUNCA** invocar modelo de linguagem, NLP, embeddings ou análise de sentimento automatizada.
- **FR-017**: Rastreio **DEVE** abrir em **sheet inferior** (~85% da viewport) — **NUNCA** em rota dedicada `/rastreio/:id`.
- **FR-018**: Rastreio **DEVE** incluir passos de raciocínio, período analisado, regras/filtros e exemplos identificadores — **SEM** seção de consultas externas.
- **FR-019**: Acesso **DEVE** exigir permissão no módulo Gabinete; consumo **DEVE** estar sob licença Cedro.
- **FR-020**: Tenant sem dados suficientes **DEVE** ver estado vazio orientativo com causa distinguível (`no_data`, `insufficient_volume`, `never_generated`) — **NUNCA** insights simulados ou cards fixos de demonstração.
- **FR-021**: UI **DEVE** manter branding **Insights IA** e ação *Consultar IA* — copy **DEVE** deixar claro que o resultado é consultivo e não altera registros (*NUNCA* prometer “a IA corrigirá…”).
- **FR-022**: UI **DEVE** atingir paridade funcional com a tela Cedro da Ouvidoria: cards de insight completos, stats de cabeçalho, histórico de gerações, sheet de rastreio, estados vazios e tratamento de throttle — adaptados ao vocabulário **ato** do Gabinete.
- **FR-023**: Escopo **limita-se** ao módulo Gabinete (`/gabinete/insights`) — **NÃO** inclui Painel global de Dados & IA nem consolidação cross-módulo.

### Fronteiras entre licenças (obrigatório)

| Licença | O que faz neste contexto | O que **NÃO** faz |
| --- | --- | --- |
| **Base** | CRUD de atos, protocolos, controles, tramitação stub, status operacional | Score Cedro, insights, conformidade |
| **Jatobá** | Alerta conformidade por registro; achados de prazo/completude | Insights estratégicos agregados |
| **Carvalho** | Score de maturidade macro; planos de ação institucionais | Insights Cedro; alarme por registro |
| **Cedro (esta feature)** | Tendências e padrões agregados read-only; recomendações consultivas | Alterar registros; SLA operacional; conformidade Jatobá |

### Key Entities

- **Insight do Gabinete**: recomendação consultiva Cedro com título, resumo, recomendação, impacto (Crítico/Alto/Médio), categoria analítica (operacional, protocolo, controle numérico, notificações/autos, documentos tramitados), período analisado e descrição das regras aplicadas.
- **Lote de geração de insights**: instante de produção, origem (agendada, sob demanda, ao abrir), tenant, janela de análise, quantidade de insights e referência ao conjunto de insights filhos.
- **Evidência de insight**: vínculo a ato, protocolo ou cadastro de controle por identificador rastreável com campos agregados usados (status, origem, tipo documental, setor, datas) — sem expor dados sigilosos além do necessário para rastreabilidade agregada.
- **Histórico de gerações**: sequência ordenada de lotes consultável pelo usuário para comparação temporal.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Usuário alcança a tela Insights IA do Gabinete em **≤ 3 cliques** a partir do overview do módulo.
- **SC-002**: **100%** dos insights exibidos citam fonte interna — **zero** referência a integração externa na lista ou no rastreio.
- **SC-003**: Recálculo sob demanda completa em **≤ 30 segundos** para tenants com até **10.000** atos confirmados e cadastros associados.
- **SC-004**: Quando existem ≥ 3 gerações persistidas, o usuário **DEVE** poder visualizar e comparar pelo menos **2 gerações anteriores** à mais recente no histórico.
- **SC-005**: **Nenhuma** ação na tela de insights altera status, encaminhamento, protocolo ou conformidade de registros — validável por auditoria de que dados permanecem idênticos antes e depois do uso.
- **SC-006**: **100%** dos rastreios abrem em sheet inferior — **zero** navegação a rota dedicada de rastreio.
- **SC-007**: Tenant com atos **e** cadastros de protocolo/controles/documentos tramitados **DEVE** receber insights de **pelo menos 3 categorias analíticas distintas** quando volume estatístico mínimo for atingido em cada dimensão.
- **SC-008**: **100%** dos cenários de estado vazio exibem mensagem orientadora coerente com a causa — **zero** tela em branco ou erro genérico sem CTA.

## Assumptions

- **Registros analisados**: atos em status diferente de rascunho e não excluídos logicamente; cadastros de protocolo, controle numérico, notificação, auto e documento tramitado não excluídos — vinculados ou standalone.
- **Período padrão de análise**: últimos **90 dias** corridos; janela documentada no rastreio.
- **Mínimo estatístico**: categorias analíticas exigem pelo menos **5** registros na dimensão no período; abaixo disso, categoria omitida — geração global **pode** ocorrer com cadastros standalone mesmo sem atos confirmados.
- **Agenda**: geração diária por tenant; falha não apaga histórico anterior.
- **Throttling**: um recálculo sob demanda por tenant por hora; leitura e histórico não contam no limite.
- **Geração ao abrir**: se não há lote recente (&lt; 24h) e carga estimada ≤ 10.000 registros analisáveis, o sistema **PODE** disparar geração com origem *ao abrir*; se carga maior, exibe último lote ou estado vazio com CTA.
- **Branding IA**: *Insights IA* e *Consultar IA* são nomenclatura de produto Cedro; execução é análise estatística interna — **sem** modelo de linguagem.
- **Vocabulário UI**: *ato/atos* no Gabinete (não *demanda* na interface); spec usa ambos onde necessário para clareza de domínio.
- **Dependências**: módulo Gabinete Base operacional ([012-desmock-gabinete](../012-desmock-gabinete/spec.md)) já entregue — esta feature **completa** Cedro, não recria CRUD.
- **Referência de paridade**: padrão funcional e de copy da Ouvidoria Cedro ([007-ouvidoria-cedro-insights](../007-ouvidoria-cedro-insights/spec.md)), adaptado ao domínio Gabinete.

## Out of Scope

- Modelos de linguagem, NLP, embeddings, análise de sentimento automatizada.
- Integrações Cedro externas (Fala.BR, CGU, PNCP, Portal Legislativo, NLP externo, etc.).
- Painel global `/global/painel-ia` e consolidação cross-módulo.
- Novas funcionalidades Carvalho, Pau-Brasil ou Jatobá.
- Exportação PDF de insights.
- Alteração de registros ou fluxos operacionais a partir de recomendações Cedro.
- Tramitação inter-setorial real (módulo Tramitação) — encaminhamentos stub permanecem apenas como fonte de eventos para agregação.
