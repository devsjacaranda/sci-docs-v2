# Feature Specification: Insights IA Cedro â€” Purchasing

**Feature Branch**: `020-purchasing-insights`

**Created**: 2026-06-25

**Status**: Completed

**Input**: User description: "Insights IA Cedro para Compras em /compras/insights. Consulta simulada PNCP/COMPRASNET por objeto da demanda. SugestÃµes de preÃ§o de referÃªncia e fornecedores similares. Read-only, dados simulados em MVP. LicenÃ§a Cedro."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Painel Insights IA funcional em Compras (Priority: P1)

Como gestor institucional com acesso ao mÃ³dulo Compras e licenÃ§a Cedro, preciso abrir `/compras/insights` e ver insights consultivos Cedro derivados dos dados internos reais do meu Ã³rgÃ£o â€” demandas, objetos de contrataÃ§Ã£o, valores estimados e artefatos â€” complementados por consultas simuladas a bases externas (PNCP/COMPRASNET), para orientar decisÃµes estratÃ©gicas de compras **sem** alterar registros operacionais.

**Why this priority**: A rota serÃ¡ exposta na navegaÃ§Ã£o; sem painel funcional, a licenÃ§a Cedro nÃ£o produz valor no domÃ­nio Compras.

**Independent Test**: Autenticar usuÃ¡rio do setor de compras com licenÃ§a Cedro; popular tenant com demandas e Pesquisas de PreÃ§os; abrir `/compras/insights` em atÃ© trÃªs cliques; verificar lista com tÃ­tulo, resumo, impacto, recomendaÃ§Ã£o, fonte, badge **Somente leitura**, aÃ§Ã£o *De onde veio este insight?* e aÃ§Ã£o *Consultar IA*.

**Acceptance Scenarios**:

1. **Given** usuÃ¡rio com permissÃ£o no mÃ³dulo Compras e licenÃ§a Cedro, **When** acessa `/compras/insights`, **Then** vÃª painel Cedro com insights da geraÃ§Ã£o mais recente, branding **Insights IA** e copy consultiva que **nÃ£o** promete alteraÃ§Ã£o automÃ¡tica de dados.
2. **Given** insight exibido, **When** o usuÃ¡rio lÃª o card, **Then** vÃª impacto classificado como **CrÃ­tico**, **Alto** ou **MÃ©dio**, fonte identificada (interna, externa simulada ou hÃ­brida) e recomendaÃ§Ã£o em linguagem imperativa consultiva (orienta, nÃ£o executa).
3. **Given** tenant com demandas e valores estimados, **When** a tela carrega, **Then** os insights refletem agregaÃ§Ãµes sobre esses registros â€” **nÃ£o** conteÃºdo de demonstraÃ§Ã£o fixo.
4. **Given** geraÃ§Ã£o bem-sucedida, **When** o painel exibe stats de cabeÃ§alho, **Then** mostra quantidade de insights ativos, data da Ãºltima geraÃ§Ã£o e contagem de impacto alto/crÃ­tico quando aplicÃ¡vel.

---

### User Story 2 - Consulta simulada PNCP/COMPRASNET por objeto (Priority: P1)

Como gestor de compras, preciso que o sistema consulte (simuladamente, em MVP) bases externas PNCP e COMPRASNET a partir do **objeto** de contrataÃ§Ã£o das demandas, para obter referÃªncias de preÃ§o, fornecedores similares e histÃ³rico de contrataÃ§Ãµes comparÃ¡veis.

**Why this priority**: Consulta externa por objeto Ã© o diferencial Cedro no domÃ­nio Compras â€” complementa dados internos com benchmarks de mercado pÃºblico.

**Independent Test**: Criar demanda com objeto *AquisiÃ§Ã£o de equipamentos de informÃ¡tica*; acionar consulta via insight ou aÃ§Ã£o dedicada; verificar resultados simulados com preÃ§o de referÃªncia, quantidade de contratos similares e fornecedores â€” claramente rotulados como simulados.

**Acceptance Scenarios**:

1. **Given** demanda com objeto informado, **When** insights sÃ£o gerados ou consulta Ã© acionada, **Then** o sistema retorna resultados simulados de PNCP/COMPRASNET para aquele objeto â€” rotulados como *Dados simulados â€” MVP*.
2. **Given** resultado de consulta externa simulada, **When** exibido, **Then** inclui preÃ§o de referÃªncia mediano, faixa de valores e quantidade de contratos similares encontrados (simulados).
3. **Given** resultado de consulta externa simulada, **When** exibido, **Then** pode listar fornecedores similares (nome simulado, quantidade de contratos) â€” **sem** dados pessoais reais.
4. **Given** demanda **sem** objeto ou objeto genÃ©rico demais, **When** consulta Ã© tentada, **Then** insight orienta refinamento do objeto â€” **sem** resultados fabricados sem base mÃ­nima.
5. **Given** qualquer consulta externa simulada, **When** exibida, **Then** copy deixa explÃ­cito que integraÃ§Ã£o real com PNCP/COMPRASNET **nÃ£o** estÃ¡ ativa nesta entrega.

---

### User Story 3 - Insights operacionais de demandas e valores (Priority: P1)

Como gestor de compras, preciso que o sistema identifique padrÃµes operacionais nas **demandas** â€” volume por status, concentraÃ§Ã£o por PCA, valores estimados agregados, demandas com instruÃ§Ã£o incompleta e comparativo de preÃ§os internos vs. referÃªncia externa simulada â€” para priorizar aÃ§Ãµes de melhoria de processo e negociaÃ§Ã£o.

**Why this priority**: Insights internos sÃ£o base para valor Cedro mesmo sem integraÃ§Ã£o externa real; complementam consulta simulada.

**Independent Test**: Popular tenant com demandas em status, PCAs e valores distintos; gerar insights e verificar presenÃ§a de agregaÃ§Ãµes operacionais com evidÃªncias no rastreio.

**Acceptance Scenarios**:

1. **Given** demandas com status variados, **When** insights sÃ£o gerados, **Then** pelo menos um insight operacional resume volume ou concentraÃ§Ã£o por status de instruÃ§Ã£o.
2. **Given** demandas vinculadas a PCAs distintos, **When** insights sÃ£o gerados, **Then** o sistema pode destacar PCA com maior volume de demandas em andamento.
3. **Given** Pesquisas de PreÃ§os com valores estimados, **When** insights sÃ£o gerados, **Then** o sistema pode destacar demandas com valor acima da mediana do tenant ou divergÃªncia vs. referÃªncia externa simulada.
4. **Given** demandas com instruÃ§Ã£o incompleta (artefatos pendentes), **When** insights sÃ£o gerados, **Then** o sistema pode destacar backlog documental por quantidade de artefatos pendentes.
5. **Given** insight operacional interno, **When** exibido, **Then** impacto e recomendaÃ§Ã£o sÃ£o consultivos â€” **nÃ£o** alteram status operacional da demanda.

---

### User Story 4 - GeraÃ§Ã£o hÃ­brida, histÃ³rico e recÃ¡lculo (Priority: P1)

Como usuÃ¡rio da tela Insights IA, preciso que insights sejam gerados automaticamente em agenda institucional, persistidos com histÃ³rico consultÃ¡vel, exibidos da Ãºltima geraÃ§Ã£o ao abrir a tela e recalculÃ¡veis sob demanda via *Consultar IA*, para equilibrar atualidade e desempenho.

**Why this priority**: ExperiÃªncia completa Cedro exige agenda, histÃ³rico, throttling e estados vazios orientadores.

**Independent Test**: Executar geraÃ§Ã£o agendada; abrir tela (Ãºltima geraÃ§Ã£o); listar histÃ³rico com duas geraÃ§Ãµes anteriores; acionar *Consultar IA* e verificar throttling.

**Acceptance Scenarios**:

1. **Given** agenda institucional ativa (padrÃ£o: diÃ¡ria por tenant), **When** o job executa, **Then** um novo lote de insights Ã© persistido com data/hora, origem *agendada* e contagem de insights produzidos.
2. **Given** usuÃ¡rio abre `/compras/insights`, **When** existe geraÃ§Ã£o anterior, **Then** a tela exibe insights da geraÃ§Ã£o mais recente **sem** exigir recÃ¡lculo imediato.
3. **Given** mÃºltiplas geraÃ§Ãµes persistidas, **When** o usuÃ¡rio consulta histÃ³rico, **Then** vÃª lista com data, origem (agendada, sob demanda, ao abrir) e quantidade de insights â€” permitindo comparar pelo menos duas geraÃ§Ãµes anteriores Ã  atual.
4. **Given** usuÃ¡rio aciona *Consultar IA*, **When** nÃ£o hÃ¡ recÃ¡lculo na Ãºltima hora para o tenant, **Then** nova geraÃ§Ã£o Ã© executada e persistida com origem *sob demanda*.
5. **Given** recÃ¡lculo jÃ¡ executado na Ãºltima hora, **When** o usuÃ¡rio tenta novamente, **Then** recebe mensagem clara de limite de frequÃªncia e continua vendo a geraÃ§Ã£o mais recente â€” **sem** erro silencioso.

---

### User Story 5 - Rastreabilidade Cedro (Priority: P1)

Como usuÃ¡rio que precisa confiar no insight, preciso entender como ele foi produzido â€” regras aplicadas, perÃ­odo analisado, filtros, exemplos de demanda e indicaÃ§Ã£o de fonte interna vs. externa simulada â€” para validar a recomendaÃ§Ã£o antes de agir na operaÃ§Ã£o.

**Why this priority**: Rastreabilidade Ã© regra de plataforma (R-40); Cedro exige sheet de rastreio com passos legÃ­veis.

**Independent Test**: Abrir rastreio de insight interno e de insight com consulta externa simulada; verificar passos, registros de exemplo e rotulagem de dados simulados.

**Acceptance Scenarios**:

1. **Given** insight exibido, **When** o usuÃ¡rio aciona *De onde veio este insight?*, **Then** abre sheet inferior (~85% da viewport) com passos de raciocÃ­nio em ordem legÃ­vel â€” **sem** navegar a rota dedicada de rastreio.
2. **Given** rastreio de insight com consulta externa simulada, **When** exibido, **Then** seÃ§Ã£o identifica fonte como *PNCP/COMPRASNET â€” simulado* com parÃ¢metros de busca (objeto utilizado).
3. **Given** rastreio de insight interno, **When** hÃ¡ evidÃªncias, **Then** nÃºmeros de demanda ou identificadores aparecem com campos agregados usados (status, valor estimado, PCA) â€” com link ao detalhe da demanda quando permitido.
4. **Given** insight Cedro, **When** exibido em qualquer contexto, **Then** badge **Somente leitura** estÃ¡ visÃ­vel â€” **nunca** *Read-only* em UI pt-BR.

---

### User Story 6 - Acesso, licenÃ§a e estados vazios (Priority: P1)

Como administrador de governanÃ§a, preciso que apenas usuÃ¡rios autorizados ao mÃ³dulo Compras com licenÃ§a Cedro acessem insights, e que tenants sem dados suficientes vejam orientaÃ§Ã£o clara â€” **sem** insights fabricados.

**Why this priority**: GovernanÃ§a de licenÃ§a e honestidade de dados vazios sÃ£o bloqueadores de produÃ§Ã£o.

**Independent Test**: UsuÃ¡rio sem mÃ³dulo (403); usuÃ¡rio sem licenÃ§a Cedro (alerta); tenant sem demandas (estado vazio orientador).

**Acceptance Scenarios**:

1. **Given** usuÃ¡rio sem permissÃ£o no mÃ³dulo Compras, **When** tenta acessar `/compras/insights`, **Then** recebe **403 Â· Acesso negado** com copy padronizada.
2. **Given** usuÃ¡rio autorizado ao mÃ³dulo **sem** licenÃ§a Cedro, **When** tenta acessar insights, **Then** recebe alerta de licenÃ§a conforme regras de plataforma.
3. **Given** tenant sem demandas cadastradas, **When** a tela carrega, **Then** estado vazio orienta operaÃ§Ã£o (*registre demandas para habilitar insights*) â€” **sem** insights fabricados.
4. **Given** qualquer aÃ§Ã£o Cedro, **When** executada, **Then** status operacional e campos de demandas/artefatos **permanecem inalterados**.

---

### User Story 7 - Exportar relatÃ³rio de insights (Priority: P2)

Como gestor de compras, preciso exportar um relatÃ³rio resumido dos insights ativos da geraÃ§Ã£o mais recente, para compartilhar orientaÃ§Ãµes estratÃ©gicas em reuniÃµes de planejamento sem acesso direto ao sistema.

**Why this priority**: ExportaÃ§Ã£o complementa valor consultivo; secundÃ¡ria ao painel funcional.

**Independent Test**: Gerar insights; acionar *Exportar relatÃ³rio*; verificar documento com lista de insights, impactos e recomendaÃ§Ãµes da geraÃ§Ã£o atual.

**Acceptance Scenarios**:

1. **Given** geraÃ§Ã£o de insights existente, **When** o usuÃ¡rio aciona *Exportar relatÃ³rio*, **Then** recebe documento (PDF ou equivalente) com insights da geraÃ§Ã£o mais recente, data de geraÃ§Ã£o e badge *Somente consultivo*.
2. **Given** exportaÃ§Ã£o, **When** insight inclui consulta externa simulada, **Then** relatÃ³rio indica claramente *Dados simulados â€” MVP*.
3. **Given** tenant sem insights gerados, **When** o usuÃ¡rio tenta exportar, **Then** recebe orientaÃ§Ã£o para gerar insights primeiro â€” **sem** documento vazio ou fabricado.

---

### Edge Cases

- Tenant sem demandas: estado vazio orientador; *Consultar IA* permitido mas produz zero insights â€” **sem** conteÃºdo fabricado.
- Demanda sem Pesquisa de PreÃ§os: insights de valor usam apenas dados disponÃ­veis â€” **nÃ£o** inventam valor estimado.
- Objeto de demanda muito curto (< 10 caracteres): consulta externa simulada pode retornar resultados genÃ©ricos com aviso de baixa confianÃ§a.
- RecÃ¡lculo durante geraÃ§Ã£o agendada: uma geraÃ§Ã£o por tenant em andamento â€” segunda solicitaÃ§Ã£o informada.
- Throttling (1 recÃ¡lculo por hora por tenant): mensagem clara; leitura e histÃ³rico nÃ£o contam no limite.
- Insight com link a demanda excluÃ­da: rastreio indica registro indisponÃ­vel â€” insight permanece consultÃ¡vel.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: O sistema **DEVE** gerar insights Cedro a partir de dados internos do tenant: demandas, PCAs, objetos, valores estimados, status de instruÃ§Ã£o e artefatos.
- **FR-002**: O sistema **DEVE** simular consultas a PNCP/COMPRASNET por objeto de contrataÃ§Ã£o â€” rotuladas como *Dados simulados â€” MVP*.
- **FR-003**: Consulta simulada **DEVE** retornar preÃ§o de referÃªncia, faixa de valores, quantidade de contratos similares e fornecedores similares (simulados).
- **FR-004**: Insights **DEVEM** ser **somente leitura** â€” nenhuma aÃ§Ã£o Cedro **DEVE** alterar demandas, artefatos ou valores.
- **FR-005**: Cada insight **DEVE** exibir impacto (**CrÃ­tico**, **Alto**, **MÃ©dio**), resumo, recomendaÃ§Ã£o consultiva e fonte (interna, externa simulada ou hÃ­brida).
- **FR-006**: O sistema **DEVE** persistir **geraÃ§Ãµes de insights** com data/hora, origem (agendada, sob demanda, ao abrir), tenant e contagem de insights.
- **FR-007**: O sistema **DEVE** executar geraÃ§Ã£o **agendada periÃ³dica** por tenant (padrÃ£o: diÃ¡ria).
- **FR-008**: Ao abrir `/compras/insights`, o sistema **DEVE** exibir insights da geraÃ§Ã£o mais recente.
- **FR-009**: O sistema **DEVE** permitir recÃ¡lculo via *Consultar IA* com limite de **uma geraÃ§Ã£o por hora por tenant**.
- **FR-010**: O sistema **DEVE** permitir consultar **histÃ³rico** de geraÃ§Ãµes â€” comparando pelo menos duas geraÃ§Ãµes anteriores.
- **FR-011**: Rastreio **DEVE** abrir em **sheet inferior** (~85% da viewport) via *De onde veio este insight?* â€” **NUNCA** em rota dedicada.
- **FR-012**: Rastreio de consulta externa simulada **DEVE** identificar fonte e parÃ¢metros de busca (objeto).
- **FR-013**: Acesso **DEVE** exigir permissÃ£o no mÃ³dulo Compras **e** licenÃ§a Cedro ativa.
- **FR-014**: UI **DEVE** exibir badge **Somente leitura** â€” **NUNCA** *Read-only* em UI pt-BR.
- **FR-015**: ExportaÃ§Ã£o de relatÃ³rio **DEVE** incluir insights da geraÃ§Ã£o atual com indicaÃ§Ã£o de dados simulados quando aplicÃ¡vel.
- **FR-016**: VocabulÃ¡rio UI **DEVE** usar **demanda/demandas** no domÃ­nio Compras.
- **FR-017**: Escopo **limita-se** a `/compras/insights` â€” **NÃƒO** inclui Central global, JatobÃ¡, Carvalho ou Pau-Brasil.

### Fronteiras entre licenÃ§as (obrigatÃ³rio)

| LicenÃ§a | O que faz neste contexto | O que **NÃƒO** faz |
| --- | --- | --- |
| **Base** | CRUD de demandas e artefatos (spec 018) | Gerar insights; consultar bases externas |
| **JatobÃ¡** | FiscalizaÃ§Ã£o de conformidade (spec 019) | Insights estratÃ©gicos; benchmarks de mercado |
| **Cedro (esta feature)** | Insights consultivos; consulta simulada PNCP/COMPRASNET; exportaÃ§Ã£o | Alterar registros; conformidade registro a registro |
| **Carvalho** | Score de maturidade macro | Insights operacionais tÃ¡ticos |

### Key Entities

- **GeraÃ§Ã£o de insights**: lote de anÃ¡lise com instante, origem, tenant, contagem de insights produzidos.
- **Insight**: recomendaÃ§Ã£o consultiva; tÃ­tulo, resumo, impacto, recomendaÃ§Ã£o, fonte, metadados de rastreio e vÃ­nculos a demandas exemplificativas.
- **Consulta externa simulada**: resultado fictÃ­cio de PNCP/COMPRASNET por objeto; preÃ§o de referÃªncia, faixa, contratos similares, fornecedores similares â€” rotulado como simulado.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: UsuÃ¡rio autorizado alcanÃ§a o painel Insights IA em **â‰¤ 3 cliques** a partir do overview de Compras.
- **SC-002**: Consulta simulada por objeto retorna resultados em **â‰¤ 5 segundos** percebidos pelo usuÃ¡rio.
- **SC-003**: **100%** dos insights exibidos possuem rastreio acessÃ­vel via sheet.
- **SC-004**: **Nenhuma** aÃ§Ã£o Cedro altera demandas ou artefatos â€” validÃ¡vel comparando registro antes e depois.
- **SC-005**: Segundo recÃ¡lculo dentro de **1 hora** retorna mensagem de throttle clara â€” **zero** erros silenciosos.
- **SC-006**: Tenant sem demandas vÃª estado vazio orientador â€” **zero** insights fabricados.
- **SC-007**: ExportaÃ§Ã£o de relatÃ³rio concluÃ­da em **â‰¤ 30 segundos** com atÃ© 20 insights.
- **SC-008**: DemonstraÃ§Ã£o ponta a ponta (criar demanda â†’ gerar insights â†’ consultar PNCP simulado â†’ rastrear â†’ exportar) concluÃ­da em **â‰¤ 10 minutos** por usuÃ¡rio sem treinamento prÃ©vio.

## Assumptions

- **DependÃªncia**: spec 018 (CRUD) fornece demandas e valores estimados para alimentar insights.
- **IntegraÃ§Ã£o externa**: PNCP/COMPRASNET retornam dados **simulados** nesta entrega â€” integraÃ§Ã£o real Ã© evoluÃ§Ã£o futura.
- **Agenda**: geraÃ§Ã£o diÃ¡ria por tenant; falha nÃ£o apaga histÃ³rico anterior.
- **Throttling**: uma geraÃ§Ã£o por tenant por hora via *Consultar IA*.
- **Paridade estrutural**: comportamento alinhado Ã  spec 015-gabinete-cedro-insights-integrado, adaptado ao domÃ­nio Compras.
- **VocabulÃ¡rio UI**: **demanda**; rota `/compras/insights`; branding **Insights IA**.

## Out of Scope

- IntegraÃ§Ã£o real com PNCP, COMPRASNET ou outras bases externas.
- AlteraÃ§Ã£o operacional de demandas ou artefatos a partir de insights.
- FiscalizaÃ§Ã£o JatobÃ¡ e score Carvalho.
- Modelos IA Pau-Brasil para redaÃ§Ã£o de artefatos.
- Insights preditivos com machine learning real â€” regras determinÃ­sticas e simulaÃ§Ã£o nesta entrega.
