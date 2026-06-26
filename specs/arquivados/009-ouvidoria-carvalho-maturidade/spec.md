# Feature Specification: Maturidade Carvalho — Ouvidoria

**Feature Branch**: `009-ouvidoria-carvalho-maturidade`

**Created**: 2026-06-19

**Status**: Completed

**Input**: User description: "Criar funções lógicas e funcionalidades importantes para calcular maturidade da Ouvidoria (Licença Carvalho). Rota `/ouvidoria/maturidade`. Score híbrido nos 3 eixos (Controle Interno, Governança, TI), dashboard com radar e evolução temporal, autoavaliação da equipe, indicadores operacionais canônicos, consumo de conformidade Jatobá e planos de ação rastreáveis com CRUD completo. Substituir mocks por dados reais do tenant."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Ver dashboard de Maturidade na Ouvidoria (Priority: P1)

Como servidor autenticado com acesso ao módulo Ouvidoria, preciso abrir a tela **Maturidade** (`/ouvidoria/maturidade`) e ver o score de maturidade Carvalho real do meu órgão — nota geral, três eixos, alerta institucional e indicadores operacionais — para acompanhar evolução macro sem alterar registros operacionais.

**Why this priority**: É a entrega central da licença Carvalho no módulo; sem dashboard real substituindo mocks, a rota não entrega valor de diagnóstico institucional.

**Independent Test**: Autenticar usuário do setor Ouvidoria, navegar ao overview e abrir Maturidade em até três cliques; verificar badge **Somente leitura**, nota geral de maturidade, três eixos (Controle Interno, Governança, TI), gráfico radar, comparativo com meta institucional (80%) e ação *Como calculamos este score?* — todos refletindo cálculo real do tenant, não dados fictícios de demonstração.

**Acceptance Scenarios**:

1. **Given** usuário com permissão no módulo Ouvidoria, **When** acessa `/ouvidoria/maturidade`, **Then** vê **Maturidade — Ouvidoria** com score de maturidade calculado, badge **Somente leitura** e copy que deixa claro que Carvalho mede capacidade institucional — **não** altera manifestações nem classifica conformidade registro a registro.
2. **Given** score calculado disponível, **When** a tela carrega, **Then** exibe nota geral (0–100%) e nota por eixo nos três valores canônicos: **Controle Interno**, **Governança** e **Tecnologia da Informação**.
3. **Given** score geral abaixo de 70%, **When** exibido, **Then** alerta aparece como **Crítico**; entre 70% e 80% como **Atenção**; ≥ 80% sem alerta de maturidade.
4. **Given** qualquer nota exibida, **When** o usuário aciona *Como calculamos este score?*, **Then** abre sheet inferior (~85% da viewport) com título **Como calculamos este score** — **sem** navegar a rota dedicada de rastreio.
5. **Given** tenant com dados suficientes, **When** o painel exibe números, **Then** reflete cálculo real — **não** valores fixos de mock (ex.: 72% estático).

---

### User Story 2 - Score híbrido por eixo (Priority: P1)

Como gestor de controle interno, preciso que o score de maturidade combine autoavaliação da equipe e taxa de conformidade operacional da Jatobá em cada eixo, conforme fórmula institucional, para obter diagnóstico equilibrado entre percepção interna e evidência fiscalizada.

**Why this priority**: A fórmula híbrida é regra de plataforma canônica (R-50); sem ela, Carvalho perde credibilidade institucional.

**Independent Test**: Provisionar tenant com autoavaliação respondida e execução Jatobá concluída; verificar score por eixo = `round(0,6 × nota_autoavaliação + 0,4 × taxa_conformidade_jatoba)` e rastreio explicando ambas as fontes.

**Acceptance Scenarios**:

1. **Given** autoavaliação respondida e dados Jatobá disponíveis para um eixo, **When** score é calculado, **Then** nota do eixo = `round(0,6 × nota_autoavaliação_eixo + 0,4 × taxa_conformidade_jatoba_eixo)` — arredondada para inteiro 0–100.
2. **Given** rastreio de score, **When** o usuário abre explicação, **Then** vê as duas fontes em linguagem clara: *autoavaliação da equipe* e *registros verificados pela fiscalização* — com valores numéricos de cada componente.
3. **Given** autoavaliação **não** respondida para o período vigente, **When** score é solicitado, **Then** nota do eixo aparece como **indisponível** — **nunca** fabricada a partir só de Jatobá ou indicadores operacionais.
4. **Given** autoavaliação respondida mas **sem** execução Jatobá concluída, **When** score é calculado, **Then** nota usa **100%** do peso da autoavaliação e interface sinaliza fonte **parcial** (Jatobá ausente).
5. **Given** notas dos três eixos disponíveis, **When** score geral é calculado, **Then** é média ponderada dos eixos (pesos iguais por padrão, configurável por tenant).

---

### User Story 3 - Autoavaliação Carvalho da equipe (Priority: P1)

Como responsável pelo módulo Ouvidoria, preciso aplicar questionários de autoavaliação Carvalho organizados por eixo, com periodicidade institucional, para que a equipe registre percepção de maturidade e alimente o componente de autoavaliação do score híbrido.

**Why this priority**: Sem autoavaliação, score fica indisponível (regra de produto); é pré-requisito do cálculo híbrido.

**Independent Test**: Abrir formulário de autoavaliação do período vigente, responder perguntas dos três eixos, submeter e verificar notas por eixo refletidas no dashboard e no rastreio.

**Acceptance Scenarios**:

1. **Given** período de autoavaliação aberto (padrão: trimestral), **When** servidor autorizado acessa *Responder autoavaliação*, **Then** vê perguntas Carvalho agrupadas por eixo (CI, GOV, TI) — **distintas** das perguntas Jatobá de fiscalização.
2. **Given** perguntas com tipos variados (escala, Sim/Não, descritiva), **When** o servidor responde e submete, **Then** respostas são persistidas com respondente, data/hora e período; nota 0–100 é calculada por eixo a partir das respostas quantificáveis.
3. **Given** autoavaliação já submetida no período, **When** o mesmo usuário tenta responder novamente, **Then** sistema permite revisão/atualização da submissão do período ou informa que período está encerrado — conforme política configurada (padrão: permite atualizar enquanto período aberto).
4. **Given** tenant provisionado, **When** autoavaliação é acessada pela primeira vez, **Then** perguntas padrão Carvalho para Ouvidoria estão disponíveis por eixo (ex.: aderência a processos internos, transparência de respostas, uso de sistemas).
5. **Given** múltiplos períodos respondidos, **When** dashboard exibe evolução temporal, **Then** histórico de notas por eixo reflete cada período concluído.

---

### User Story 4 - Indicadores operacionais canônicos (Priority: P1)

Como gestor da Ouvidoria, preciso visualizar indicadores operacionais agregados — volume, tempo médio de resposta, prazos vencidos, taxa de resolução e satisfação — no contexto de maturidade, para contextualizar o score e identificar áreas de melhoria sem substituir alarmes operacionais da Base ou Jatobá.

**Why this priority**: Indicadores canônicos de Carvalho para Ouvidoria (licencas-canonicas.md) orientam leitura executiva do dashboard; complementam o score sem calculá-lo diretamente.

**Independent Test**: Popular tenant com manifestações em estados distintos e execução Jatobá; abrir dashboard e verificar cinco indicadores com valores coerentes e rastreio explicativo.

**Acceptance Scenarios**:

1. **Given** manifestações confirmadas no tenant, **When** indicadores são calculados, **Then** **Volume de manifestações** exibe contagem no período analisado (padrão: últimos 90 dias ou período da autoavaliação vigente).
2. **Given** manifestações com eventos de resposta na linha do tempo, **When** indicador **Tempo médio de resposta** é calculado, **Then** reflete diferença média entre confirmação e primeiro evento de resposta — derivado de eventos, não de campo manual de prazo.
3. **Given** execução Jatobá com checagens de prazo, **When** indicador **Prazos vencidos** é calculado, **Then** exibe percentual de manifestações com checagem de prazo **Não conforme** sobre total fiscalizado na execução mais recente — **não** substitui status operacional *Crítico*/*Vencendo* da Base.
4. **Given** manifestações confirmadas, **When** **Taxa de resolução** é calculada, **Then** exibe proporção encerradas (`closed`) sobre total confirmadas no período.
5. **Given** fontes de satisfação, **When** indicador **Satisfação** é calculado, **Then** usa modelo **híbrido**: média de respostas de questionários externos Jatobá (escala) quando existirem **mais** componente de autoavaliação Carvalho sobre percepção de satisfação; quando Jatobá externo indisponível, usa autoavaliação com sinalização de fonte parcial.
6. **Given** qualquer indicador exibido, **When** o usuário abre rastreio, **Then** vê período, fórmula em linguagem clara e totais — **sem** expor PII de manifestantes anônimos.

---

### User Story 5 - Radar e evolução temporal (Priority: P1)

Como gestor institucional, preciso visualizar radar dos três eixos e evolução do score ao longo do tempo, comparando com a meta de 80%, para comunicar diagnóstico e tendência a stakeholders.

**Why this priority**: Visualização radar e temporal são entregáveis centrais da Carvalho canônica; transformam números em leitura executiva.

**Independent Test**: Com ≥ 2 períodos de autoavaliação e scores calculados, verificar radar atual e gráfico de linha com evolução por eixo e geral.

**Acceptance Scenarios**:

1. **Given** scores dos três eixos disponíveis, **When** dashboard carrega, **Then** exibe gráfico radar com eixos **Controle Interno**, **Governança** e **Tecnologia da Informação** e linha de referência da meta institucional (80%).
2. **Given** histórico de ≥ 2 períodos, **When** usuário consulta evolução temporal, **Then** gráfico de linha exibe score geral e/ou por eixo ao longo dos períodos — com datas identificáveis.
3. **Given** apenas um período disponível, **When** evolução temporal é exibida, **Then** mostra ponto único ou mensagem orientando que histórico se formará após próximas autoavaliações — **sem** curva fictícia.
4. **Given** eixo abaixo da meta, **When** radar é renderizado, **Then** destaque visual (cor semântica) diferencia eixos em atenção/crítico conforme limiares R-52.

---

### User Story 6 - Planos de ação rastreáveis (Priority: P2)

Como gestor da Ouvidoria, preciso criar e acompanhar planos de ação vinculados a eixos ou indicadores com déficit, com responsável, prazo, status, criticidade e notas de progresso, para transformar diagnóstico de maturidade em melhoria institucional rastreável.

**Why this priority**: Planos de ação são capacidade distintiva da Carvalho; secundários ao score mas essenciais para valor executivo completo.

**Independent Test**: Criar plano vinculado a eixo com nota baixa, atribuir responsável e prazo, registrar nota de progresso, alterar status e verificar listagem com filtros.

**Acceptance Scenarios**:

1. **Given** usuário autorizado, **When** aciona *Novo plano de ação*, **Then** pode informar título, descrição, eixo vinculado (CI/GOV/TI), responsável, prazo, criticidade (**Alta**, **Média**, **Baixa**) e status inicial **Pendente**.
2. **Given** plano criado, **When** gestor atualiza status, **Then** transições permitidas: **Pendente** → **Em andamento** → **Concluído** ou **Cancelado** — com registro de data da mudança.
3. **Given** plano em andamento, **When** responsável adiciona nota de progresso, **Then** nota é persistida com texto, autor e data/hora — visível no detalhe do plano.
4. **Given** lista de planos, **When** usuário filtra por eixo, status ou criticidade, **Then** resultados refletem filtros aplicados.
5. **Given** achado Jatobá ou indicador com déficit, **When** usuário cria plano, **Then** **PODE** vincular referência opcional (eixo, indicador ou achado) — plano **não** altera manifestação nem achado.
6. **Given** plano de ação, **When** executado, **Then** é a **única** operação de escrita da tela Maturidade — scores e indicadores permanecem somente leitura.

---

### User Story 7 - Consumo de conformidade Jatobá (Priority: P1)

Como sistema Carvalho, preciso agregar taxa de conformidade da fiscalização Jatobá por eixo temático, mapeando checagens e achados da Ouvidoria para alimentar 40% do score híbrido, sem duplicar fiscalização registro a registro.

**Why this priority**: Jatobá alimenta Carvalho no modelo canônico; dados já existem via módulo de fiscalização implementado.

**Independent Test**: Com execução Jatobá concluída, verificar taxa de conformidade por eixo usada no score e explicada no rastreio com referência à execução fiscal mais recente.

**Acceptance Scenarios**:

1. **Given** execução Jatobá concluída, **When** Carvalho calcula conformidade, **Then** usa resultados da execução mais recente do tenant — mapeando checagens para eixos: prazo/tramitação/completude → **Controle Interno**; canal/contato/transparência → **Governança**; anexos/evidências/sistemas → **Tecnologia da Informação**.
2. **Given** taxa por eixo, **When** calculada, **Then** = percentual de manifestações **Conforme** naquele eixo sobre total fiscalizado — checagens **Não conforme** e **Parcial** reduzem a taxa conforme regra documentada.
3. **Given** rastreio de score, **When** componente Jatobá é exibido, **Then** referencia data da execução fiscal e totais por status — **sem** listar PII.
4. **Given** nenhuma execução Jatobá concluída, **When** score é calculado, **Then** componente Jatobá ausente; score usa autoavaliação com peso 100% e badge de fonte parcial.

---

### User Story 8 - Governança: licença, permissão e fronteiras (Priority: P1)

Como administrador de governança, preciso que apenas usuários autorizados ao módulo Ouvidoria acessem maturidade Carvalho, que scores nunca alterem dados operacionais ou Jatobá, e que fronteiras entre licenças sejam respeitadas na interface.

**Why this priority**: Separação de eixos (operacional vs maturidade vs conformidade) é bloqueador para produção.

**Independent Test**: Usuário sem módulo (403); verificar que ações Carvalho não alteram manifestações; links para Fiscalização Jatobá e Insights Cedro permanecem distintos.

**Acceptance Scenarios**:

1. **Given** usuário sem permissão no módulo Ouvidoria, **When** tenta acessar `/ouvidoria/maturidade`, **Then** recebe **403 · Acesso negado** com copy padronizada.
2. **Given** usuário autorizado, **When** consome maturidade, **Then** acesso condicionado à licença Carvalho ativa (conjunto fixo de quatro licenças).
3. **Given** qualquer cálculo ou exibição de score, **When** executado, **Then** status operacional, prioridade, eventos e achados Jatobá **permanecem inalterados**.
4. **Given** tenant sem autoavaliação e sem Jatobá, **When** tela carrega, **Then** estado orienta (*responda a autoavaliação do período e execute fiscalização Jatobá para habilitar score completo*) — **sem** scores fabricados.
5. **Given** barra de alertas de licença, **When** score Carvalho < 70%, **Then** chip Carvalho aponta para `/ouvidoria/maturidade` com severidade **Crítico**; entre 70% e 80% **Atenção**.

---

### Edge Cases

- Tenant novo sem manifestações: indicadores operacionais zerados ou indisponíveis; score indisponível até autoavaliação; mensagem orientativa clara.
- Autoavaliação parcial (só um eixo respondido): eixos incompletos marcados indisponíveis; score geral calculado só sobre eixos completos ou indisponível se nenhum completo — decisão: score geral indisponível se < 3 eixos (Assumptions).
- Execução Jatobá desatualizada (> 48h): score calculado com dados existentes; banner informa que conformidade pode estar desatualizada com link para Fiscalização.
- Questionários externos Jatobá sem respostas: indicador Satisfação usa só autoavaliação Carvalho com fonte parcial.
- Plano de ação com prazo vencido: exibido com destaque de atraso; **não** altera score automaticamente.
- Período de autoavaliação encerrado sem resposta: score do período indisponível; período anterior permanece no histórico.
- Manifestações excluídas logicamente: indicadores recalculam excluindo soft-deleted; histórico de score preservado.
- Usuário sem permissão para criar plano de ação: pode visualizar scores; CRUD de planos restrito a perfis gestores (Assumptions).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: O sistema **DEVE** calcular score de maturidade Carvalho para Ouvidoria usando fórmula híbrida por eixo: `round(0,6 × nota_autoavaliacao_eixo + 0,4 × taxa_conformidade_jatoba_eixo)` — conforme R-50.
- **FR-002**: Eixos **DEVEM** ser exclusivamente **Controle Interno**, **Governança** e **Tecnologia da Informação** — conjunto fechado; **NUNCA** eixos ad hoc.
- **FR-003**: Quando autoavaliação do período vigente **não** existir, score do eixo **DEVE** aparecer como **indisponível** — **NUNCA** calculado só com Jatobá ou indicadores operacionais.
- **FR-004**: Quando execução Jatobá **não** existir, score **DEVE** usar autoavaliação com peso 100% e sinalizar fonte **parcial**.
- **FR-005**: Score geral **DEVE** ser média ponderada dos três eixos (pesos iguais por padrão); indisponível se nenhum eixo tiver nota válida.
- **FR-006**: O sistema **DEVE** exibir dashboard em `/ouvidoria/maturidade` com nota geral, notas por eixo, alerta (Crítico < 70%, Atenção ≥ 70% e < 80%), gráfico radar e evolução temporal.
- **FR-007**: O sistema **DEVE** calcular e exibir indicadores operacionais canônicos: volume de manifestações, tempo médio de resposta, percentual de prazos vencidos (via Jatobá), taxa de resolução e satisfação (híbrida).
- **FR-008**: Indicadores operacionais **DEVEM** contextualizar o dashboard — **NUNCA** substituir componentes da fórmula híbrida diretamente.
- **FR-009**: O sistema **DEVE** oferecer autoavaliação Carvalho com perguntas por eixo, tipos de resposta (escala, Sim/Não, descritiva), periodicidade configurável (padrão trimestral) e histórico por período.
- **FR-010**: Perguntas Carvalho **DEVEM** ser distintas das perguntas Jatobá — bancos separados, propósitos distintos (maturidade macro vs conformidade operacional).
- **FR-011**: O sistema **DEVE** mapear checagens Jatobá da execução mais recente para eixos Carvalho e calcular taxa de conformidade por eixo para o componente de 40% do score.
- **FR-012**: Rastreabilidade **DEVE** abrir em sheet inferior (~85% viewport) com título **Como calculamos este score** — explicando autoavaliação, conformidade Jatobá, fórmula e meta de 80% — **NUNCA** em rota dedicada.
- **FR-013**: O sistema **DEVE** permitir CRUD completo de planos de ação: título, descrição, eixo, responsável, prazo, status (Pendente, Em andamento, Concluído, Cancelado), criticidade (Alta, Média, Baixa), vínculo opcional a indicador/achado.
- **FR-014**: Planos de ação **DEVEM** suportar notas de progresso com texto, autor e data — listagem com filtros por eixo, status e criticidade.
- **FR-015**: Scores, indicadores e conformidade agregada **DEVEM** ser **somente leitura** — badge **Somente leitura**; planos de ação são a exceção de escrita gerencial.
- **FR-016**: Carvalho **NUNCA** **DEVE** alterar manifestações, eventos, achados Jatobá ou status operacional — R-23.
- **FR-017**: Carvalho **NUNCA** **DEVE** fiscalizar registro a registro — **SEMPRE** visão macro agregada.
- **FR-018**: Acesso **DEVE** exigir permissão no módulo Ouvidoria e licença Carvalho ativa.
- **FR-019**: Rastreio e indicadores **NÃO DEVEM** expor PII de manifestante anônimo ou sigiloso.
- **FR-020**: UI **DEVE** usar *nota* ou *score de maturidade* com contexto — **NUNCA** *score* isolado na primeira menção (R-81).
- **FR-021**: Escopo **limita-se** ao módulo Ouvidoria (`/ouvidoria/maturidade`) — **NÃO** inclui Dashboard Global Carvalho, Fiscalização Jatobá, Insights Cedro ou Pau-Brasil.
- **FR-022**: O sistema **DEVE** substituir mocks atuais da rota por dados reais persistidos do tenant.
- **FR-023**: Tenant provisionado **DEVE** receber perguntas padrão Carvalho para Ouvidoria por eixo.
- **FR-024**: Satisfação **DEVE** combinar questionários externos Jatobá (quando houver respostas em escala) com perguntas de autoavaliação Carvalho sobre percepção de satisfação — com sinalização quando uma fonte estiver ausente.

### Fronteiras entre licenças (obrigatório)

| Licença | O que faz neste contexto | O que **NÃO** faz |
| --- | --- | --- |
| **Base** | CRUD manifestações, tramitação, prazos operacionais, status *Crítico*/*Vencendo* | Calcular score de maturidade; planos de ação Carvalho |
| **Carvalho (esta feature)** | Score híbrido macro; radar; indicadores agregados; autoavaliação; planos de ação | Fiscalizar registro a registro; alterar registros; insights externos |
| **Jatobá** | Fornece taxa de conformidade operacional (40% do score); prazos vencidos como indicador | Calcular maturidade; gerenciar planos de ação Carvalho |
| **Cedro** | Insights estratégicos read-only (feature 007) | Compor score de maturidade; planos de ação |
| **Pau-Brasil** | Modelos de resposta e alertas normativos | Score ou indicadores de maturidade |

### Key Entities

- **Período de autoavaliação**: intervalo institucional (ex.: trimestre); data início/fim; tenant; flag aberto/encerrado.
- **Pergunta Carvalho (Ouvidoria)**: texto; eixo (CI/GOV/TI); tipo de resposta; peso na nota do eixo; flag ativa; ordem.
- **Submissão de autoavaliação**: período; respondente; data submissão; notas calculadas por eixo.
- **Resposta de autoavaliação**: valor; pergunta; submissão; data.
- **Snapshot de score**: período; nota geral; notas por eixo; componentes autoavaliação e Jatobá; flag fonte parcial; data cálculo.
- **Mapeamento checagem→eixo**: regra de domínio que associa ruleIds Jatobá a eixos Carvalho (documentado, não editável pelo usuário na v1).
- **Indicador operacional**: tipo (volume, tempo_resposta, prazos_vencidos, taxa_resolucao, satisfacao); valor; período; metadados de rastreio.
- **Plano de ação**: título; descrição; eixo; responsável; prazo; status; criticidade; vínculo opcional; tenant; datas criação/atualização.
- **Nota de progresso do plano**: texto; autor; data; plano pai.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Usuário autorizado alcança dashboard Maturidade em **≤ 3 cliques** a partir do overview de Ouvidoria.
- **SC-002**: Com autoavaliação e Jatobá disponíveis, score por eixo reflete fórmula híbrida em **100%** dos casos de teste documentados.
- **SC-003**: **100%** das notas exibidas possuem rastreio *Como calculamos este score?* acessível via sheet.
- **SC-004**: **Nenhuma** operação Carvalho altera manifestação, evento ou achado Jatobá — validável comparando registro antes e depois.
- **SC-005**: **100%** dos rastreios abrem em sheet inferior — **zero** navegação a rota dedicada.
- **SC-006**: Tenant sem autoavaliação vê score **indisponível** — **zero** scores fabricados em teste de estado vazio.
- **SC-007**: Cinco indicadores canônicos exibidos com valores coerentes quando dados existem — **zero** valores mock fixos após implementação.
- **SC-008**: CRUD de plano de ação (criar → progresso → concluir) concluído em **≤ 10 minutos** por gestor sem treinamento prévio.
- **SC-009**: Com ≥ 2 períodos de autoavaliação, evolução temporal exibe **≥ 2 pontos** no gráfico de linha.
- **SC-010**: Alertas Carvalho na barra de licenças disparam corretamente: **Crítico** < 70%; **Atenção** ≥ 70% e < 80%.

## Assumptions

- **Dependências**: módulo Ouvidoria Base (003), endereço (006), fiscalização Jatobá Ouvidoria (008) implementada — dados de conformidade disponíveis.
- **Periodicidade autoavaliação**: trimestral por padrão; configurável por tenant (mensal, semestral, anual).
- **Score geral**: indisponível se menos de 3 eixos com nota válida no período.
- **Mapeamento Jatobá→eixos** (v1, fixo):
  - **Controle Interno**: checagens Prazo de resposta, Tramitação, Completude
  - **Governança**: checagem Canal e contato
  - **Tecnologia da Informação**: checagem Anexos e evidências
- **Taxa conformidade por eixo**: % manifestações com pior status do eixo = Conforme; Parcial conta como 50%; Pendente/Não conforme = 0% na parcela.
- **Período indicadores**: últimos 90 dias corridos, alinhado ao trimestre da autoavaliação quando possível.
- **Tempo médio resposta**: diferença em dias entre confirmação da manifestação e primeiro evento tipo `response`.
- **Taxa resolução**: manifestações `closed` / confirmadas no período × 100.
- **Satisfação Jatobá**: média respostas escala 1–5 de questionários externos respondidos no período; normalizada 0–100.
- **Satisfação Carvalho**: média respostas escala das perguntas de satisfação na autoavaliação.
- **Satisfação combinada**: `round(0,5 × satisfacao_jatoba + 0,5 × satisfacao_carvalho)` quando ambas existem; fonte única com peso 100% quando uma ausente.
- **Planos de ação**: CRUD restrito a usuários com perfil gestor no módulo Ouvidoria (mesma regra de encerramento/resposta de manifestação).
- **Conjunto de licenças**: tenant possui quatro licenças fixas; Carvalho sempre presente quando feature visível.
- **Meta institucional**: 80% (referência visual); abaixo de 70% = crítico (R-52).

## Out of Scope

- Dashboard Global Carvalho (`/global/maturidade`) e radar consolidado multi-módulo.
- Fiscalização registro a registro, questionários Jatobá e Central de Fiscalização (feature 008).
- Insights Cedro, Pau-Brasil e alteração de registros operacionais.
- Exportação PDF de relatório executivo de maturidade.
- Configuração editável pelo usuário da fórmula híbrida (60/40) ou pesos por eixo na v1.
- Integração com benchmarks externos ou dados Cedro no cálculo do score.
- Notificações push/e-mail de planos de ação vencidos.
- Autoavaliação por respondentes externos (somente equipe interna na v1).
