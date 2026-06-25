# Feature Specification: Desmock Tramitação

**Feature Branch**: `014-desmock-tramitacao`

**Created**: 2026-06-24

**Status**: Draft

**Input**: Desmock completo do módulo Tramitação — entidade Demanda como linked record wrapper + composição genérica, inbox email-like, integração com Ouvidoria/Jurídico/Gabinete, e todas as telas de licença (Dashboard, Fiscalização, Insights, Maturidade) com API real.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Compor e receber demandas na inbox (Priority: P1)

O operador do setor abre a Tramitação e visualiza uma inbox no estilo email com três pastas: **Recebidas**, **Enviadas** e **Arquivadas**, filtradas pelo setor ativo. Pode compor uma nova demanda genérica (sem vínculo a registro de outro módulo) informando destinatário, assunto e corpo em texto simples. Demandas recebidas de outros módulos via linked record também aparecem na pasta Recebidas.

**Why this priority**: É a funcionalidade nuclear — sem inbox não há módulo. Toda operação subsequente depende deste fluxo.

**Independent Test**: Pode ser testada criando uma demanda genérica e verificando que aparece na pasta Enviadas do remetente e Recebidas do destinatário.

**Acceptance Scenarios**:

1. **Given** operador autenticado com setor ativo, **When** acessa Tramitação, **Then** visualiza inbox com pastas Recebidas/Enviadas/Arquivadas contendo demandas do setor
2. **Given** operador na inbox, **When** compõe nova demanda genérica com destinatário, assunto e corpo, **Then** demanda é criada com protocolo automático (TRAM-AAAA-NNNN) e aparece em Enviadas
3. **Given** módulo externo tramita registro para o setor, **When** demanda linked record é criada, **Then** aparece na pasta Recebidas com indicação do módulo de origem

---

### User Story 2 - Tramitar registro de módulo via linked record (Priority: P1)

Operador de Gabinete, Ouvidoria ou Jurídico executa a ação "Tramitar" / "Encaminhar setor" a partir de um registro do seu módulo. O sistema cria uma demanda no módulo Tramitação vinculada ao registro de origem (módulo + ID + snapshot imutável do momento da tramitação). O setor destinatário recebe a demanda com acesso ao contexto original.

**Why this priority**: É o diferencial da Tramitação — conectar módulos de forma rastreável. Sem isto, a Tramitação seria apenas um chat interno.

**Independent Test**: Pode ser testada executando "Tramitar" em um registro de gabinete e verificando que a demanda criada contém o snapshot e referência correta ao registro de origem.

**Acceptance Scenarios**:

1. **Given** operador do Gabinete com registro aberto, **When** executa ação "Tramitar" selecionando setor destino, **Then** demanda é criada no módulo Tramitação com linked record (módulo: gabinete, ID do registro, snapshot JSON)
2. **Given** operador da Ouvidoria com manifestação aberta, **When** executa "Encaminhar setor", **Then** demanda é criada com linked record referenciando a manifestação
3. **Given** operador do Jurídico com processo aberto, **When** executa ação análoga de tramitação, **Then** demanda é criada com linked record referenciando o processo
4. **Given** demanda com linked record recebida, **When** destinatário abre a demanda, **Then** visualiza snapshot do registro de origem sem precisar acessar o módulo original

---

### User Story 3 - Responder, encaminhar e arquivar demandas (Priority: P1)

O operador abre uma demanda recebida e pode: responder na thread de conversa, encaminhar para outro setor (mantendo histórico), ou arquivar. Cada ação gera evento na timeline da demanda. Encaminhamentos criam continuidade — o setor anterior mantém visibilidade no histórico.

**Why this priority**: Sem capacidade de resposta e encaminhamento, a inbox seria estática. Estes são os verbos essenciais de operação.

**Independent Test**: Pode ser testada respondendo a uma demanda e verificando que a resposta aparece na thread; encaminhando e verificando que o novo destinatário a recebe.

**Acceptance Scenarios**:

1. **Given** demanda aberta na inbox, **When** operador escreve resposta, **Then** resposta é adicionada à thread e remetente original é notificado
2. **Given** demanda recebida, **When** operador encaminha para outro setor com justificativa, **Then** demanda aparece na inbox do novo setor com histórico completo
3. **Given** demanda resolvida, **When** operador arquiva, **Then** demanda move para pasta Arquivadas e sai da lista ativa
4. **Given** qualquer ação na demanda, **When** evento ocorre, **Then** timeline registra tipo (resposta/encaminhamento/arquivamento), autor, data e conteúdo

---

### User Story 4 - Dashboard consolidado de demandas (Priority: P1)

O gestor acessa um dashboard com visão consolidada das demandas do setor: volume total, pendentes, resolutividade, distribuição por módulo de origem, com filtros por período e setor. KPIs são calculados com dados reais da API.

**Why this priority**: Gestores precisam de visibilidade operacional para tomar decisões. Dashboard é a porta de entrada para licenças superiores.

**Independent Test**: Pode ser testada criando demandas com diferentes status e verificando que os KPIs refletem corretamente os dados.

**Acceptance Scenarios**:

1. **Given** setor com demandas em diversos status, **When** gestor acessa dashboard, **Then** visualiza KPIs: total, pendentes, respondidas, taxa de resolutividade
2. **Given** demandas originadas de múltiplos módulos, **When** visualiza distribuição, **Then** gráfico mostra proporção por módulo de origem (Gabinete, Ouvidoria, Jurídico, Genérica)
3. **Given** filtro de período aplicado, **When** seleciona intervalo de datas, **Then** todos os KPIs são recalculados para o período

---

### User Story 5 - Fiscalização Jatobá (Priority: P1)

Com licença Jatobá ativa, o sistema executa checagens automáticas por demanda: prazo SLA, completude de dados, encaminhamento pendente. Cada checagem gera achados com status de conformidade nos 4 status canônicos. Execuções são persistidas com histórico.

**Why this priority**: Fiscalização é o primeiro upgrade de licença — traz accountability e rastreabilidade regulatória.

**Independent Test**: Pode ser testada criando demanda com prazo vencido e verificando que a checagem SLA gera achado de não-conformidade.

**Acceptance Scenarios**:

1. **Given** licença Jatobá ativa e demanda com prazo expirado, **When** fiscalização é executada, **Then** achado "prazo SLA excedido" é gerado com status não-conforme
2. **Given** demanda com dados incompletos, **When** checagem de completude roda, **Then** achado identifica campos faltantes
3. **Given** demanda encaminhada sem resposta há X dias, **When** checagem de pendência roda, **Then** achado "encaminhamento pendente" é registrado
4. **Given** múltiplas execuções ao longo do tempo, **When** operador consulta histórico, **Then** visualiza timeline de execuções com evolução dos achados

---

### User Story 6 - Insights Cedro (Priority: P1)

Com licença Cedro ativa, o sistema apresenta agregações determinísticas read-only sobre as demandas: gargalos entre setores, volume por módulo de origem, tendências temporais. Não altera demandas, apenas analisa.

**Why this priority**: Insights complementa o dashboard com análise aprofundada para gestão estratégica.

**Independent Test**: Pode ser testada verificando que os insights exibidos correspondem exatamente às agregações calculáveis a partir dos dados existentes.

**Acceptance Scenarios**:

1. **Given** licença Cedro ativa e histórico de demandas, **When** acessa Insights, **Then** visualiza gargalos (setores com maior tempo médio de resposta)
2. **Given** demandas de múltiplos módulos, **When** consulta volume, **Then** exibe distribuição por módulo com tendência (crescente/estável/decrescente)
3. **Given** período selecionado, **When** análise temporal é exibida, **Then** gráfico mostra evolução de volume e resolutividade ao longo do tempo

---

### User Story 7 - Maturidade Carvalho (Priority: P1)

Com licença Carvalho ativa, o sistema calcula score de maturidade híbrido (60% autoavaliação + 40% Jatobá), exibe radar por eixo e permite criação de planos de ação vinculados aos eixos deficientes.

**Why this priority**: Maturidade é o topo da pirâmide de licenças — transforma dados em governança acionável.

**Independent Test**: Pode ser testada preenchendo autoavaliação e verificando que o score combina corretamente com os dados do Jatobá.

**Acceptance Scenarios**:

1. **Given** licença Carvalho ativa e Jatobá com execuções, **When** acessa Maturidade, **Then** visualiza score híbrido calculado (60% autoavaliação + 40% Jatobá)
2. **Given** score calculado, **When** visualiza radar, **Then** eixos mostram nível de maturidade por dimensão avaliada
3. **Given** eixo com score baixo, **When** cria plano de ação, **Then** plano é vinculado ao eixo com prazo e responsável

---

### User Story 8 - Alertas de licença e rastreabilidade na inbox (Priority: P2)

Na inbox, o sistema exibe barra de alertas canônica informando funcionalidades disponíveis/bloqueadas por licença. Sheets de rastreabilidade mostram qual licença habilita cada funcionalidade.

**Why this priority**: Orienta o usuário sobre o que pode/não pode fazer sem frustração; guia upgrade comercial.

**Independent Test**: Pode ser testada acessando com licença Base e verificando que alertas informam sobre funcionalidades de Jatobá/Cedro/Carvalho bloqueadas.

**Acceptance Scenarios**:

1. **Given** usuário com licença Base apenas, **When** acessa inbox, **Then** barra de alertas informa sobre Fiscalização, Insights e Maturidade disponíveis para upgrade
2. **Given** funcionalidade bloqueada por licença, **When** usuário tenta acessar, **Then** sheet explicativo mostra qual licença é necessária

---

### User Story 9 - Integração Gabinete → Tramitação (Priority: P2)

No módulo Gabinete, ao visualizar uma CabinetDemanda, operador pode executar ação "Tramitar" que cria automaticamente uma demanda no módulo Tramitação com linked record referenciando o registro de gabinete.

**Why this priority**: Gabinete é o módulo mais recente com dados reais; validar integração aqui pavimenta as demais.

**Independent Test**: Pode ser testada executando "Tramitar" em um registro do Gabinete e verificando a demanda criada no módulo Tramitação.

**Acceptance Scenarios**:

1. **Given** registro de CabinetDemanda no Gabinete, **When** operador clica "Tramitar" e seleciona setor destino, **Then** demanda é criada na Tramitação com sourceModule=gabinete
2. **Given** demanda criada via Gabinete, **When** destinatário abre, **Then** visualiza snapshot dos dados da CabinetDemanda no momento da tramitação

---

### User Story 10 - Integração Ouvidoria → Tramitação (Priority: P2)

No módulo Ouvidoria, ao visualizar uma Manifestação, operador pode executar "Encaminhar setor" que cria demanda no módulo Tramitação com linked record referenciando a manifestação.

**Why this priority**: Ouvidoria é o módulo com maior volume de dados; integração essencial para fluxo real.

**Independent Test**: Pode ser testada encaminhando uma manifestação e verificando a demanda criada.

**Acceptance Scenarios**:

1. **Given** manifestação na Ouvidoria, **When** operador executa "Encaminhar setor", **Then** demanda criada na Tramitação com sourceModule=ouvidoria e snapshot da manifestação
2. **Given** demanda criada via Ouvidoria, **When** destinatário visualiza, **Then** dados da manifestação original estão acessíveis no snapshot

---

### User Story 11 - Integração Jurídico → Tramitação (Priority: P2)

No módulo Jurídico, ao visualizar um Processo, operador pode executar ação de tramitação que cria demanda no módulo Tramitação com linked record referenciando o processo jurídico.

**Why this priority**: Completa o trio de módulos conectados planejados para v1.

**Independent Test**: Pode ser testada tramitando um processo jurídico e verificando a demanda criada.

**Acceptance Scenarios**:

1. **Given** processo no módulo Jurídico, **When** operador executa ação de tramitação, **Then** demanda criada na Tramitação com sourceModule=juridico e snapshot do processo
2. **Given** demanda criada via Jurídico, **When** destinatário visualiza, **Then** dados do processo original estão acessíveis no snapshot

---

### Edge Cases

- O que acontece quando o setor destinatário não existe ou foi desativado?
- Como o sistema se comporta quando o registro de origem (linked record) é excluído no módulo original após a tramitação?
- O que acontece ao tentar encaminhar uma demanda já arquivada?
- Como o sistema lida com demandas encaminhadas circularmente (A→B→A)?
- O que acontece quando um operador tenta compor demanda para seu próprio setor?
- Como o sistema exibe o snapshot quando o formato do registro de origem muda entre versões?
- O que acontece quando a licença é rebaixada e dados de Jatobá/Cedro/Carvalho já existem?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Sistema DEVE permitir que operadores componham demandas genéricas (sem linked record) informando setor destinatário, assunto e corpo em texto simples
- **FR-002**: Sistema DEVE gerar protocolo único automático no formato TRAM-AAAA-NNNN para cada demanda criada
- **FR-003**: Sistema DEVE exibir inbox com três pastas (Recebidas, Enviadas, Arquivadas) filtradas pelo setor ativo do operador
- **FR-004**: Sistema DEVE suportar criação de demandas via linked record quando módulos externos (Gabinete, Ouvidoria, Jurídico) tramitam registros
- **FR-005**: Sistema DEVE armazenar snapshot imutável (JSON) do registro de origem no momento da tramitação
- **FR-006**: Sistema DEVE permitir respostas em thread dentro de cada demanda, mantendo ordem cronológica
- **FR-007**: Sistema DEVE permitir encaminhamento de demandas para outro setor, preservando histórico completo de interações anteriores
- **FR-008**: Sistema DEVE permitir arquivamento de demandas, movendo-as para pasta Arquivadas
- **FR-009**: Sistema DEVE registrar todos os eventos (criação, resposta, encaminhamento, mudança de status, arquivamento) em timeline rastreável
- **FR-010**: Sistema DEVE exibir dashboard com KPIs reais: volume total, pendentes, resolutividade, distribuição por módulo de origem
- **FR-011**: Sistema DEVE suportar filtros por período e setor no dashboard
- **FR-012**: Sistema DEVE executar checagens automáticas de fiscalização (prazo SLA, completude, encaminhamento pendente) quando licença Jatobá estiver ativa
- **FR-013**: Sistema DEVE classificar achados de fiscalização nos 4 status canônicos de conformidade
- **FR-014**: Sistema DEVE persistir histórico de execuções de fiscalização por demanda
- **FR-015**: Sistema DEVE calcular e exibir agregações determinísticas (gargalos, volume por módulo, tendências) quando licença Cedro estiver ativa
- **FR-016**: Sistema DEVE calcular score de maturidade híbrido (60% autoavaliação + 40% Jatobá) quando licença Carvalho estiver ativa
- **FR-017**: Sistema DEVE exibir gráfico radar por eixo de maturidade
- **FR-018**: Sistema DEVE permitir criação de planos de ação vinculados a eixos de maturidade deficientes
- **FR-019**: Sistema DEVE exibir alertas de licença informando funcionalidades disponíveis e bloqueadas por nível de licença
- **FR-020**: Sistema DEVE disponibilizar ação "Tramitar" no módulo Gabinete para criar demanda no módulo Tramitação
- **FR-021**: Sistema DEVE disponibilizar ação "Encaminhar setor" no módulo Ouvidoria para criar demanda no módulo Tramitação
- **FR-022**: Sistema DEVE disponibilizar ação de tramitação no módulo Jurídico para criar demanda no módulo Tramitação
- **FR-023**: Sistema DEVE suportar prazo (deadline) opcional por demanda
- **FR-024**: Sistema DEVE permitir que o módulo Tramitação funcione sem restrição por setor (módulo aberto)
- **FR-025**: Sistema NÃO DEVE permitir alteração do snapshot do linked record após criação da demanda

### Key Entities

- **Demanda**: Unidade central do módulo — representa uma solicitação inter-setorial. Contém assunto, corpo, origem (genérica ou linked record), módulo e registro de origem quando aplicável, snapshot imutável, setor remetente, setor(es) destinatário(s), status operacional, prazo, protocolo único
- **Evento de Demanda**: Registro imutável na timeline — tipo (criação, resposta, encaminhamento, mudança de status, arquivamento), autor, data, conteúdo
- **Anexo de Demanda**: Arquivo vinculado a uma demanda ou resposta, com metadados descritivos
- **Linked Record**: Referência polimórfica ao registro de origem — identifica módulo de origem, ID do registro e snapshot JSON capturado no momento da tramitação

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Operadores conseguem compor e enviar uma demanda genérica em menos de 60 segundos
- **SC-002**: Demandas tramitadas de módulos externos aparecem na inbox do destinatário em menos de 5 segundos após ação
- **SC-003**: 100% das demandas criadas via linked record contêm snapshot verificável do registro de origem
- **SC-004**: Thread de conversa suporta ao menos 50 respostas por demanda sem degradação perceptível de usabilidade
- **SC-005**: Dashboard exibe KPIs calculados sobre dados reais com atualização em tempo de carregamento normal de página
- **SC-006**: Checagens de fiscalização (Jatobá) executam para todas as demandas pendentes dentro do prazo configurado
- **SC-007**: Insights (Cedro) exibem agregações consistentes com os dados brutos — resultados determinísticos e reprodutíveis
- **SC-008**: Score de maturidade (Carvalho) reflete corretamente a composição 60%/40% entre autoavaliação e fiscalização
- **SC-009**: Funcionalidades bloqueadas por licença são claramente sinalizadas ao usuário antes de qualquer tentativa de uso
- **SC-010**: Encaminhamentos preservam 100% do histórico de interações anteriores visível ao novo destinatário

## Assumptions

- Módulo Tramitação é aberto (`OPEN_MODULES`) — todo setor pode acessar sem restrição adicional por licença Base
- Composição genérica v1 utiliza texto simples (sem rich text / editor WYSIWYG)
- Integração SIGED (API real, webhook, autenticação) está fora de escopo desta entrega
- Licença Pau-Brasil (modelos de documento) está fora de escopo v1
- Admin SaaS e Central global não são afetados por esta feature
- Migração de dados legados não faz parte desta entrega
- WhatsApp e email transacional para questionários estão fora de escopo
- Os módulos Gabinete, Ouvidoria e Jurídico já existem e possuem registros operacionais que podem ser referenciados
- O snapshot do linked record é imutável — captura o estado do registro no momento da tramitação e não se atualiza se o registro original mudar
- Setores são entidades já existentes no sistema, gerenciados pelo módulo de permissões
