# Feature Specification: Maturidade — Purchasing (Carvalho)

**Feature Branch**: `021-purchasing-maturidade`

**Created**: 2026-06-25

**Status**: Draft

**Input**: User description: "Maturidade Carvalho para Compras em /compras/maturidade. Self-assessment por questionário de maturidade em compras públicas (Lei 14.133). Score por dimensão. Histórico de avaliações. Orientações de melhoria. Licença Carvalho."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Responder questionário de maturidade (Priority: P1)

Como gestor de compras com licença Carvalho, preciso acessar `/compras/maturidade` e responder um **questionário de autoavaliação** sobre práticas de compras públicas conforme a Lei 14.133/2021, para medir o nível de maturidade institucional do meu órgão em compras.

**Why this priority**: Self-assessment é a entrada do produto Carvalho; sem questionário funcional, não há score nem plano de melhoria.

**Independent Test**: Autenticar usuário com licença Carvalho; abrir `/compras/maturidade`; responder questionário completo por dimensões; submeter e verificar score calculado.

**Acceptance Scenarios**:

1. **Given** usuário com permissão no módulo Compras e licença Carvalho, **When** acessa `/compras/maturidade`, **Then** vê questionário de autoavaliação organizado por dimensões de maturidade em compras públicas.
2. **Given** questionário exibido, **When** o usuário responde todas as perguntas obrigatórias e submete, **Then** respostas são persistidas e score é calculado por dimensão e global.
3. **Given** pergunta obrigatória não respondida, **When** o usuário tenta submeter, **Then** validação impede envio com indicação das perguntas pendentes.
4. **Given** questionário parcialmente respondido, **When** o usuário sai e retorna, **Then** respostas parciais são preservadas para continuidade — **sem** perda de progresso.
5. **Given** dimensões do questionário, **When** exibidas, **Then** cobrem pelo menos: **Planejamento**, **Instrução processual**, **Conformidade** e **Resultados** — adaptadas ao domínio Compras.

---

### User Story 2 - Ver score por dimensão e histórico (Priority: P1)

Como gestor de compras, preciso visualizar o **score de maturidade** por dimensão e o score global, além do **histórico de avaliações** anteriores do tenant, para acompanhar evolução institucional ao longo do tempo.

**Why this priority**: Score e histórico são o valor central Carvalho — transformam autoavaliação pontual em indicador de gestão.

**Independent Test**: Submeter duas avaliações em períodos distintos; verificar dashboard com scores por dimensão, score global, gráfico de evolução e lista histórica com datas.

**Acceptance Scenarios**:

1. **Given** avaliação submetida, **When** o dashboard carrega, **Then** exibe score global (0–100 ou escala equivalente) e score individual por dimensão.
2. **Given** múltiplas avaliações persistidas, **When** o usuário consulta histórico, **Then** vê lista com data, score global e scores por dimensão — permitindo comparar evolução entre pelo menos duas avaliações.
3. **Given** dashboard de maturidade, **When** exibido, **Then** inclui visualização gráfica da evolução do score global ao longo do tempo quando houver ≥ 2 avaliações.
4. **Given** tenant sem avaliação prévia, **When** o dashboard carrega, **Then** exibe estado orientador convidando à primeira autoavaliação — **sem** scores fabricados.
5. **Given** conformidade Jatobá disponível (spec 019), **When** score híbrido é calculado, **Then** dimensão **Conformidade** pode incorporar taxa de conformidade das fiscalizações recentes — complementando autoavaliação.

---

### User Story 3 - Orientações de melhoria por dimensão (Priority: P1)

Como gestor de compras, preciso receber **orientações de melhoria** personalizadas por dimensão com score abaixo do patamar desejado, para saber quais ações priorizar no plano de desenvolvimento institucional.

**Why this priority**: Orientações transformam score em ação — sem elas, Carvalho é apenas indicador numérico.

**Independent Test**: Submeter avaliação com scores baixos em *Instrução processual*; verificar orientações específicas para aquela dimensão com ações recomendadas.

**Acceptance Scenarios**:

1. **Given** dimensão com score abaixo do patamar *Adequado* (threshold definido na fase plan), **When** o dashboard exibe resultados, **Then** lista orientações de melhoria específicas para aquela dimensão.
2. **Given** orientação exibida, **When** o usuário lê, **Then** vê ação recomendada em linguagem imperativa consultiva (ex.: *Implemente pesquisa de preços sistemática antes da abertura de processos*).
3. **Given** dimensão com score *Adequado* ou superior, **When** exibida, **Then** orientação reconhece boa prática — **sem** recomendar ação corretiva desnecessária.
4. **Given** score híbrido com conformidade Jatobá, **When** dimensão Conformidade tem score baixo, **Then** orientação pode referenciar achados frequentes da fiscalização — **sem** expor dados individuais de demanda.

---

### User Story 4 - Período de avaliação e recorrência (Priority: P2)

Como gestor de compras, preciso que avaliações sejam organizadas por **período** (ex.: trimestre, semestre), para comparar maturidade entre ciclos de gestão e acompanhar metas institucionais.

**Why this priority**: Periodicidade estrutura o uso recorrente de Carvalho; secundária ao questionário e score inicial.

**Independent Test**: Submeter avaliação no período atual; verificar que nova avaliação no mesmo período atualiza a existente; avaliação em período diferente cria novo registro histórico.

**Acceptance Scenarios**:

1. **Given** período de avaliação corrente (ex.: Q2/2026), **When** o usuário submete autoavaliação, **Then** avaliação é vinculada ao período corrente.
2. **Given** avaliação já existente no período corrente, **When** o usuário submete novamente, **Then** avaliação anterior do período é substituída — **sem** duplicar registros no mesmo período.
3. **Given** novo período iniciado, **When** o usuário acessa maturidade, **Then** sistema convida a nova autoavaliação do período — histórico de períodos anteriores permanece consultável.

---

### User Story 5 - Exportar relatório de maturidade (Priority: P2)

Como gestor de compras, preciso exportar um **relatório de maturidade** com scores, evolução histórica e orientações de melhoria, para apresentar resultados em reuniões de gestão e prestação de contas.

**Why this priority**: Exportação complementa valor institucional; secundária ao dashboard funcional.

**Independent Test**: Com avaliação submetida; acionar *Exportar relatório*; verificar documento com scores, dimensões, orientações e data.

**Acceptance Scenarios**:

1. **Given** avaliação existente, **When** o usuário aciona *Exportar relatório*, **Then** recebe documento (PDF ou equivalente) com score global, scores por dimensão, orientações e data da avaliação.
2. **Given** histórico com ≥ 2 avaliações, **When** exportação inclui evolução, **Then** documento exibe comparativo entre períodos.
3. **Given** tenant sem avaliação, **When** o usuário tenta exportar, **Then** recebe orientação para completar autoavaliação primeiro.

---

### User Story 6 - Acesso, licença e governança (Priority: P1)

Como administrador de governança, preciso que apenas usuários autorizados ao módulo Compras com licença Carvalho acessem maturidade, e que autoavaliação **não** altere dados operacionais de demandas ou artefatos.

**Why this priority**: Governança de licença e separação de eixos são bloqueadores de produção.

**Independent Test**: Usuário sem módulo (403); usuário sem licença Carvalho (alerta); submeter avaliação e verificar que demandas permanecem inalteradas.

**Acceptance Scenarios**:

1. **Given** usuário sem permissão no módulo Compras, **When** tenta acessar `/compras/maturidade`, **Then** recebe **403 · Acesso negado** com copy padronizada.
2. **Given** usuário autorizado ao módulo **sem** licença Carvalho, **When** tenta acessar maturidade, **Then** recebe alerta de licença conforme regras de plataforma.
3. **Given** qualquer ação Carvalho, **When** executada, **Then** demandas, artefatos e status operacionais **permanecem inalterados**.
4. **Given** autoavaliação submetida, **When** persistida, **Then** registra autor e data/hora da submissão para rastreabilidade.

---

### Edge Cases

- Tenant sem demandas cadastradas: autoavaliação permitida — maturidade mede práticas institucionais, **não** exige demandas existentes.
- Tenant sem fiscalização Jatobá: score híbrido usa **somente** autoavaliação — **não** bloqueia Carvalho.
- Respostas inconsistentes (todas máximas): score alto com orientações de manutenção — **não** bloqueia submissão.
- Dois gestores submetendo no mesmo período: última submissão prevalece — conflito informado.
- Licença Carvalho expirada após avaliação: histórico permanece consultável; nova avaliação bloqueada.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: O sistema **DEVE** disponibilizar questionário de autoavaliação de maturidade em compras públicas organizado por dimensões.
- **FR-002**: Dimensões **DEVEM** incluir pelo menos: **Planejamento**, **Instrução processual**, **Conformidade** e **Resultados**.
- **FR-003**: O sistema **DEVE** calcular score por dimensão e score global a partir das respostas submetidas.
- **FR-004**: O sistema **DEVE** persistir avaliações com autor, data/hora e vínculo a período de avaliação.
- **FR-005**: O sistema **DEVE** exibir histórico de avaliações do tenant com scores e datas — comparável entre períodos.
- **FR-006**: O sistema **DEVE** gerar orientações de melhoria por dimensão com score abaixo do patamar *Adequado*.
- **FR-007**: Score híbrido **PODE** incorporar taxa de conformidade Jatobá na dimensão **Conformidade** quando fiscalização disponível (spec 019).
- **FR-008**: Autoavaliação parcial **DEVE** ser preservada para continuidade — **sem** perda ao sair da tela.
- **FR-009**: Uma avaliação por período por tenant — re-submissão substitui avaliação do período corrente.
- **FR-010**: O sistema **DEVE** permitir exportação de relatório de maturidade com scores e orientações.
- **FR-011**: Acesso **DEVE** exigir permissão no módulo Compras **e** licença Carvalho ativa.
- **FR-012**: Carvalho **DEVE** ser **somente leitura** em relação a demandas e artefatos — autoavaliação **não** altera operação.
- **FR-013**: Vocabulário UI **DEVE** usar **demanda/demandas** no domínio Compras.
- **FR-014**: Rota pública **DEVE** ser `/compras/maturidade`.
- **FR-015**: Escopo **limita-se** a maturidade de Compras — **NÃO** inclui plano de ação detalhado (action plans), Central global ou maturidade de outros módulos.

### Fronteiras entre licenças (obrigatório)

| Licença | O que faz neste contexto | O que **NÃO** faz |
| --- | --- | --- |
| **Base** | CRUD de demandas e artefatos (spec 018) | Calcular maturidade |
| **Jatobá** | Fiscalização de conformidade (spec 019) | Score de maturidade macro |
| **Carvalho (esta feature)** | Self-assessment; score por dimensão; histórico; orientações; exportação | Fiscalizar registro a registro; alterar demandas |
| **Cedro** | Insights estratégicos read-only (spec 020) | Score de maturidade |

### Key Entities

- **Período de avaliação**: ciclo temporal (ex.: trimestre) que agrupa avaliações; 1 avaliação ativa por período por tenant.
- **Questionário de maturidade**: conjunto de perguntas organizadas por dimensão; tipos de resposta (escala, sim/não, descritiva).
- **Avaliação (submissão)**: respostas completas de um período; autor, data, scores calculados.
- **Score por dimensão**: valor numérico derivado das respostas da dimensão; pode incorporar conformidade Jatobá na dimensão Conformidade.
- **Orientação de melhoria**: recomendação consultiva vinculada a dimensão com score abaixo do patamar.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Usuário autorizado completa autoavaliação e vê score em **≤ 15 minutos** sem treinamento prévio.
- **SC-002**: Score global e por dimensão calculados imediatamente após submissão — **≤ 3 segundos** percebidos pelo usuário.
- **SC-003**: Histórico exibe evolução comparável entre **≥ 2** avaliações de períodos distintos.
- **SC-004**: Dimensões com score abaixo do patamar exibem **≥ 1** orientação de melhoria específica.
- **SC-005**: **Nenhuma** ação Carvalho altera demandas ou artefatos — validável comparando registro antes e depois.
- **SC-006**: Exportação de relatório concluída em **≤ 30 segundos**.
- **SC-007**: Respostas parciais preservadas em **100%** dos casos de saída e retorno à tela.
- **SC-008**: Demonstração ponta a ponta (responder questionário → ver score → ler orientações → exportar relatório) concluída em **≤ 20 minutos** por usuário sem treinamento prévio.

## Assumptions

- **Dependência opcional**: spec 019 (Jatobá) enriquece dimensão Conformidade via score híbrido — Carvalho funciona **sem** Jatobá.
- **Paridade estrutural**: comportamento alinhado ao módulo `gabinete-maturidade` existente, adaptado ao domínio Compras e Lei 14.133.
- **Período padrão**: trimestral — configurável na fase plan.
- **Patamar *Adequado***: threshold por dimensão definido na fase plan (ex.: ≥ 60/100).
- **Questionário seed**: perguntas padrão do domínio Compras provisionadas no tenant — editáveis em evolução futura.
- **Plano de ação (action plans)**: fora de escopo nesta entrega — apenas orientações consultivas.
- **Vocabulário UI**: **demanda**; rota `/compras/maturidade`; branding **Maturidade**.

## Out of Scope

- Plano de ação detalhado com tarefas, responsáveis e prazos (action plans).
- Edição do banco de perguntas pelo usuário nesta entrega.
- Maturidade transversal (Central global) ou de outros módulos.
- Alteração operacional de demandas ou artefatos a partir de scores.
- Benchmarking entre tenants ou comparação anonimizada entre órgãos.
