# Feature Specification: Desmock do Dashboard Global

**Feature Branch**: `031-global-dashboard-demock`

**Created**: 2026-07-02

**Status**: Completed

**Input**: User description: "Desmock do mÃ¡ximo possÃ­vel de informaÃ§Ãµes de /global/dashboard â€” atualmente temos informaÃ§Ãµes mocks na home do dashboard global; vamos tentar desmockar o mÃ¡ximo que dÃ¡; o que continuar mock, marcar como mock."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Ver dados reais de identidade e perfil na home (Priority: P1)

Como operador institucional autenticado, quero que a tela inicial em `/global/dashboard` exiba meu nome, cargo, avatar e a identidade visual da minha instituiÃ§Ã£o com dados reais do sistema, para confiar que estou no ambiente correto e reconhecer minha sessÃ£o.

**Why this priority**: Ã‰ a primeira impressÃ£o ao entrar na plataforma. Dados fictÃ­cios de perfil (ex.: fallback de mock local) minam a credibilidade e podem exibir informaÃ§Ãµes erradas mesmo com sessÃ£o vÃ¡lida.

**Independent Test**: Autenticar com usuÃ¡rio real do tenant, acessar `/global/dashboard` e confirmar que nome, cargo, avatar e branding institucional correspondem ao cadastro â€” sem depender de dados seed ou perfil simulado em armazenamento local.

**Acceptance Scenarios**:

1. **Given** operador autenticado via sessÃ£o real, **When** acessa `/global/dashboard`, **Then** vÃª saudaÃ§Ã£o com seu primeiro nome e cargo obtidos da sessÃ£o autenticada.
2. **Given** tenant com branding configurado (nome, avatar e/ou banner), **When** a home carrega, **Then** exibe identidade institucional real do tenant.
3. **Given** tenant sem avatar ou banner configurado, **When** a home carrega, **Then** exibe fallback visual elegante (iniciais/nome) sem dados fictÃ­cios de outra instituiÃ§Ã£o.
4. **Given** operador com badges de papel (admin plataforma, chefe de setor, filtro de licenÃ§a ativo), **When** a home carrega, **Then** badges refletem permissÃµes reais da sessÃ£o.

---

### User Story 2 - KPIs e indicadores com dados operacionais reais (Priority: P1)

Como gestor ou operador com visÃ£o transversal, quero que os cartÃµes de indicadores na home mostrem nÃºmeros derivados de registros reais do tenant (ou estados vazios honestos), para tomar decisÃµes com base na operaÃ§Ã£o atual â€” nÃ£o em valores de demonstraÃ§Ã£o.

**Why this priority**: Os quatro KPIs atuais ("OcorrÃªncias CrÃ­ticas", "Registros Ativos", "MÃ³dulos Monitorados", "AtualizaÃ§Ãµes 24h") sÃ£o estÃ¡ticos e induzem falsa sensaÃ§Ã£o de operaÃ§Ã£o. SubstituÃ­-los por dados reais (ou ocultÃ¡-los) Ã© o maior ganho de confianÃ§a na home.

**Independent Test**: Com tenant contendo registros conhecidos (ex.: demandas de tramitaÃ§Ã£o, manifestaÃ§Ãµes), acessar a home e verificar que pelo menos os KPIs viÃ¡veis exibem contagens coerentes com o banco â€” ou estado vazio/zerado quando nÃ£o houver dados.

**Acceptance Scenarios**:

1. **Given** tenant com demandas e manifestaÃ§Ãµes registradas, **When** operador com acesso transversal abre a home, **Then** KPIs substituÃ­dos exibem valores consistentes com agregaÃ§Ãµes reais (ex.: pendÃªncias de tramitaÃ§Ã£o, volume recente).
2. **Given** tenant recÃ©m-provisionado sem registros, **When** a home carrega, **Then** KPIs reais exibem zero ou mensagem de "sem dados" â€” nunca valores de demonstraÃ§Ã£o fixos.
3. **Given** operador com filtro de licenÃ§a ativo (ex.: apenas Cedro), **When** KPIs dependem de mÃ³dulos licenciados, **Then** contagens respeitam mÃ³dulos acessÃ­veis ao operador.
4. **Given** KPI cujo dado ainda nÃ£o possui fonte confiÃ¡vel no produto, **When** a home carrega, **Then** o cartÃ£o permanece visÃ­vel com indicaÃ§Ã£o explÃ­cita de **Mock** (ver US4) em vez de nÃºmero fictÃ­cio disfarÃ§ado de real.

---

### User Story 3 - Atividade recente e grÃ¡fico transversal (Priority: P2)

Como operador institucional, quero ver na home um feed de atividade recente e um resumo visual por mÃ³dulo baseados em eventos reais quando disponÃ­veis, para retomar rapidamente o que aconteceu na operaÃ§Ã£o sem navegar mÃ³dulo a mÃ³dulo.

**Why this priority**: A lista "Atividade recente" e o grÃ¡fico "OcorrÃªncias crÃ­ticas por mÃ³dulo" sÃ£o hoje conteÃºdo 100% fictÃ­cio. ConectÃ¡-los a fontes reais (tramitaÃ§Ã£o, notificaÃ§Ãµes, auditoria) aumenta utilidade operacional; o que nÃ£o for viÃ¡vel deve ser claramente rotulado.

**Independent Test**: Gerar evento real (ex.: encaminhar demanda, receber notificaÃ§Ã£o) e confirmar apariÃ§Ã£o no feed ou no grÃ¡fico; alternativamente, confirmar rÃ³tulo **Mock** quando a fonte ainda nÃ£o existir.

**Acceptance Scenarios**:

1. **Given** eventos recentes de tramitaÃ§Ã£o no tenant, **When** operador com acesso abre a home, **Then** "Atividade recente" lista eventos reais ordenados por recÃªncia (limitados a quantidade definida, ex.: 5â€“10 itens).
2. **Given** item de atividade com registro vinculado, **When** operador clica no item, **Then** Ã© direcionado ao contexto correto (ex.: detalhe da demanda).
3. **Given** dados agregados por mÃ³dulo disponÃ­veis (ex.: volume de demandas por origem), **When** o grÃ¡fico transversal carrega, **Then** exibe barras proporcionais aos dados reais do perÃ­odo configurado.
4. **Given** seÃ§Ã£o sem fonte de dados viÃ¡vel nesta entrega, **When** a home carrega, **Then** a seÃ§Ã£o exibe rÃ³tulo **Mock** visÃ­vel e nÃ£o apresenta nÃºmeros como se fossem reais.

---

### User Story 4 - TransparÃªncia sobre o que ainda Ã© mock (Priority: P1)

Como operador ou administrador da plataforma, quero identificar visualmente quais blocos da home ainda usam dados simulados, para nÃ£o confundir demonstraÃ§Ã£o com operaÃ§Ã£o real durante demos, homologaÃ§Ã£o ou uso diÃ¡rio.

**Why this priority**: Quando desmock completo nÃ£o for possÃ­vel, a honestidade da interface Ã© requisito de produto â€” evita decisÃµes baseadas em nÃºmeros fictÃ­cios.

**Independent Test**: Inspecionar cada bloco da home e verificar presenÃ§a (ou ausÃªncia) de indicador **Mock** conforme inventÃ¡rio acordado; blocos com dados reais nÃ£o exibem o rÃ³tulo.

**Acceptance Scenarios**:

1. **Given** bloco da home alimentado por dados simulados, **When** renderizado, **Then** exibe badge ou rÃ³tulo discreto porÃ©m legÃ­vel **Mock** no tÃ­tulo ou canto do bloco.
2. **Given** bloco totalmente desmockado, **When** renderizado, **Then** nÃ£o exibe rÃ³tulo **Mock**.
3. **Given** bloco parcialmente desmockado (ex.: KPI real + tendÃªncia ainda simulada), **When** renderizado, **Then** apenas a parte simulada ou o bloco inteiro (se indivisÃ­vel) mantÃ©m rÃ³tulo **Mock** conforme regra documentada no plano.
4. **Given** modo de produÃ§Ã£o com tenant real, **When** usuÃ¡rio consulta a home, **Then** nunca vÃª valores estÃ¡ticos de seed apresentados como operacionais sem o rÃ³tulo **Mock**.

---

### User Story 5 - Atalhos e continuidade de navegaÃ§Ã£o (Priority: P3)

Como operador, quero que atalhos rÃ¡pidos e o link "Continuar no mÃ³dulo" continuem funcionando com base em permissÃµes reais e histÃ³rico de navegaÃ§Ã£o, para acessar rapidamente telas relevantes sem dados fictÃ­cios adicionais.

**Why this priority**: Atalhos jÃ¡ sÃ£o configuraÃ§Ã£o estÃ¡tica filtrada por permissÃ£o â€” nÃ£o sÃ£o mock de dados operacionais. O histÃ³rico recente jÃ¡ Ã© real (cliente). Validar que nada reintroduz mock desnecessÃ¡rio.

**Independent Test**: Navegar para mÃ³dulo, voltar Ã  home e confirmar "Continuar no mÃ³dulo"; verificar que atalhos respeitam licenÃ§a e permissÃ£o do usuÃ¡rio.

**Acceptance Scenarios**:

1. **Given** operador com acesso parcial a mÃ³dulos, **When** visualiza atalhos, **Then** vÃª apenas telas permitidas pelo perfil e filtro de licenÃ§a.
2. **Given** histÃ³rico de navegaÃ§Ã£o registrado, **When** retorna Ã  home, **Then** "Continuar no mÃ³dulo" aponta para Ãºltima tela acessada com horÃ¡rio relativo correto.
3. **Given** filtro de licenÃ§a restritivo sem atalhos compatÃ­veis, **When** a home carrega, **Then** exibe estado vazio orientando ajuste do filtro â€” sem atalhos fictÃ­cios.

---

### Edge Cases

- Tenant sem branding configurado: fallback visual sem quebrar layout nem exibir instituiÃ§Ã£o genÃ©rica enganosa.
- Tenant vazio (zero registros em todos os mÃ³dulos): KPIs e grÃ¡ficos em zero ou empty state â€” nunca seed fixo.
- Operador sem permissÃ£o a mÃ³dulos com dados agregados: KPIs e feed respeitam escopo visÃ­vel; nÃ£o vazam totais de mÃ³dulos bloqueados.
- Falha ao carregar dados reais (rede, timeout): bloco exibe erro recuperÃ¡vel ou skeleton â€” nÃ£o fallback silencioso para mock.
- SessÃ£o expirada durante carregamento: redirecionamento/login conforme fluxo auth existente.
- Admin tenant vs user operacional: agregaÃ§Ãµes respeitam tenant e permissÃµes sem expor dados cross-tenant.

## Requirements *(mandatory)*

### InventÃ¡rio de blocos da home (`/global/dashboard`)

| Bloco | SituaÃ§Ã£o atual | Meta desta feature |
| --- | --- | --- |
| Identidade institucional (banner, nome, avatar tenant) | Real (`/tenant/branding`) | Manter real |
| Hero â€” saudaÃ§Ã£o, nome, cargo, avatar usuÃ¡rio | Parcial (auth real + `loadProfile` mock) | Desmock: perfil 100% da sessÃ£o autenticada |
| Badges (admin, chefe setor, filtro licenÃ§a) | Real (sessÃ£o + contexto) | Manter real |
| KPIs (4 cartÃµes em `screens.global-dashboard.stats`) | Mock estÃ¡tico | Desmock parcial: substituir por agregaÃ§Ãµes reais onde existir fonte; restante â†’ rÃ³tulo **Mock** |
| Atalhos rÃ¡pidos (3 grupos) | Config estÃ¡tica + permissÃµes | Manter (nÃ£o Ã© mock operacional); sem rÃ³tulo Mock |
| Continuar no mÃ³dulo | Real (histÃ³rico cliente) | Manter real |
| Atividade recente (`welcomeActivities`) | Mock estÃ¡tico | Desmock: eventos reais (tramitaÃ§Ã£o, notificaÃ§Ãµes quando disponÃ­vel); senÃ£o â†’ rÃ³tulo **Mock** |
| GrÃ¡fico "OcorrÃªncias crÃ­ticas por mÃ³dulo" | Mock inline | Desmock parcial via agregaÃ§Ãµes reais por mÃ³dulo; senÃ£o â†’ rÃ³tulo **Mock** |

### Functional Requirements

- **FR-001**: A home em `/global/dashboard` DEVE obter nome, cargo e avatar do operador exclusivamente da sessÃ£o autenticada, eliminando dependÃªncia de perfil simulado (`admin-mock` / seed local) para exibiÃ§Ã£o.
- **FR-002**: A identidade institucional DEVE continuar obtida do branding real do tenant, com fallback visual quando campos opcionais estiverem ausentes.
- **FR-003**: Os KPIs estÃ¡ticos em configuraÃ§Ã£o de tela (`stats` hardcoded) DEVEM ser removidos ou substituÃ­dos por indicadores calculados a partir de dados reais do tenant.
- **FR-004**: Para cada KPI, o sistema DEVE definir uma fonte de verdade (agregaÃ§Ã£o existente ou nova) ou mantÃª-lo explicitamente como mock com rÃ³tulo **Mock** visÃ­vel.
- **FR-005**: A seÃ§Ã£o "Atividade recente" DEVE listar eventos reais ordenados por data quando houver fonte disponÃ­vel (prioridade: tramitaÃ§Ã£o; complementar: notificaÃ§Ãµes quando spec 029 estiver disponÃ­vel).
- **FR-006**: Itens de atividade com registro vinculado DEVEM ser clicÃ¡veis e levar ao contexto correto do registro.
- **FR-007**: O grÃ¡fico transversal por mÃ³dulo DEVE usar agregaÃ§Ãµes reais quando disponÃ­veis; caso contrÃ¡rio, DEVE exibir rÃ³tulo **Mock** e nÃ£o valores fictÃ­cios sem indicaÃ§Ã£o.
- **FR-008**: Todo bloco que permanecer com dados simulados DEVE exibir indicador visual **Mock** (badge ou equivalente) conforme padrÃ£o Ãºnico de produto.
- **FR-009**: Blocos com dados reais NÃƒO DEVEM exibir rÃ³tulo **Mock**.
- **FR-010**: AgregaÃ§Ãµes e feeds DEVEM respeitar tenant, permissÃµes de mÃ³dulo e filtro de licenÃ§a ativo do operador.
- **FR-011**: Estados vazios DEVEM ser honestos (zero registros, mensagem clara) â€” nunca substituÃ­dos por nÃºmeros de demonstraÃ§Ã£o.
- **FR-012**: Falhas de carregamento DEVEM ser tratadas sem fallback silencioso para dados mock.
- **FR-013**: Atalhos e histÃ³rico de navegaÃ§Ã£o DEVEM continuar filtrados por permissÃ£o e licenÃ§a, sem alteraÃ§Ã£o de comportamento regressiva.
- **FR-014**: A entrega DEVE documentar inventÃ¡rio final bloco a bloco: Real | Parcial (detalhar) | Mock rotulado.

### Key Entities

- **Indicador da home (KPI)**: RÃ³tulo, valor numÃ©rico ou textual, texto de tendÃªncia/contexto, origem (real ou mock), mÃ³dulos/licenÃ§as associados.
- **Evento de atividade**: TÃ­tulo, mÃ³dulo de origem, timestamp, tipo (tramitaÃ§Ã£o, alerta, documento, permissÃ£o), referÃªncia opcional a registro navegÃ¡vel.
- **AgregaÃ§Ã£o por mÃ³dulo**: Nome do mÃ³dulo, contagem no perÃ­odo, critÃ©rio de inclusÃ£o (ex.: demandas pendentes, ocorrÃªncias crÃ­ticas).
- **Bloco da home**: Identificador semÃ¢ntico, fonte de dados, estado (real / mock rotulado / empty), visibilidade condicionada a permissÃ£o.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% dos blocos da home estÃ£o classificados no inventÃ¡rio final como Real, Parcial documentado ou Mock rotulado â€” nenhum bloco ambÃ­guo.
- **SC-002**: Perfil do operador na home (nome, cargo, avatar) corresponde Ã  sessÃ£o autenticada em 100% dos casos de teste com usuÃ¡rios distintos (user, chefe de setor, admin tenant).
- **SC-003**: Pelo menos 50% dos KPIs originais substituÃ­dos por valores derivados de dados reais ou removidos/substituÃ­dos por empty state â€” os restantes com rÃ³tulo **Mock** visÃ­vel.
- **SC-004**: SeÃ§Ã£o "Atividade recente" exibe ao menos um evento real em tenant com operaÃ§Ã£o de tramitaÃ§Ã£o nos Ãºltimos 7 dias, ou rÃ³tulo **Mock** se indisponÃ­vel.
- **SC-005**: Operadores identificam blocos mock em teste moderado (â‰¥ 90% acertam quais blocos sÃ£o mock vs. real sem documentaÃ§Ã£o auxiliar).
- **SC-006**: Nenhum valor numÃ©rico de seed/demo permanece apresentado como operacional sem rÃ³tulo **Mock**.
- **SC-007**: Tempo de carregamento percebido da home permanece aceitÃ¡vel: operador vÃª conteÃºdo principal (hero + branding) em atÃ© 2 segundos em conexÃ£o tÃ­pica; blocos assÃ­ncronos exibem loading explÃ­cito.

## Assumptions

- Escopo limitado Ã  rota `/global/dashboard` (componente de boas-vindas global); outras telas do mÃ³dulo Global (auditoria, biblioteca, maturidade, etc.) ficam fora desta feature.
- Fontes de dados existentes por mÃ³dulo (ex.: dashboard de tramitaÃ§Ã£o com totais e `bySourceModule`) podem ser reutilizadas via agregaÃ§Ã£o no plano tÃ©cnico, sem exigir novo endpoint global nesta spec.
- Spec 029 (notificaÃ§Ãµes) pode complementar o feed de atividade; se ainda nÃ£o implementada, tramitaÃ§Ã£o Ã© fonte primÃ¡ria e notificaÃ§Ãµes ficam como stretch ou mock rotulado.
- "OcorrÃªncias crÃ­ticas" serÃ¡ mapeado no plano para critÃ©rio operacional existente (ex.: manifestaÃ§Ãµes crÃ­ticas, demandas urgentes) ou permanecerÃ¡ mock rotulado se nÃ£o houver definiÃ§Ã£o canÃ´nica transversal.
- Atalhos estÃ¡ticos nÃ£o sÃ£o considerados "mock operacional" â€” nÃ£o recebem rÃ³tulo Mock.
- RÃ³tulo **Mock** seguirÃ¡ vocabulÃ¡rio e padrÃ£o visual de `.cursor/docs/regras-plataforma.md` (definido no plano/implementaÃ§Ã£o).
- Ambiente alvo usa API real (`VITE_USE_API`); modo offline/demo legado nÃ£o Ã© prioridade desta entrega.

## Out of Scope

- Redesign visual completo da home (layout permanece; foco em veracidade dos dados).
- CriaÃ§Ã£o de novos mÃ³dulos ou licenÃ§as.
- Desmock de dashboards especÃ­ficos de outros mÃ³dulos (tramitaÃ§Ã£o, gabinete, IT, etc.) â€” apenas consumo/agregaÃ§Ã£o na home global.
- HistÃ³rico de atividade cross-tenant ou relatÃ³rios analÃ­ticos avanÃ§ados.
