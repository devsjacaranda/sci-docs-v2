# Feature Specification: Purchasing ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â CRUD de Demandas e Artefatos (Lei 14.133/2021)

**Feature Branch**: `018-purchasing-crud`

**Created**: 2026-06-25

**Status**: Completed

**Input**: User description: "Desenvolver mÃƒÆ’Ã‚Â³dulo de compras (domÃƒÆ’Ã‚Â­nio purchasing). Spec 1: tela tabela, tela criar, tela detalhes/editar em /compras e /compras/novo. Inclui hub quebra-cabeÃƒÆ’Ã‚Â§a da demanda e 7 artefatos documentais (DFD, ETP, AnÃƒÆ’Ã‚Â¡lise de Riscos, TR, Pesquisa de PreÃƒÆ’Ã‚Â§os, DotaÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Â£o, Parecer). PCA gerenciado via modal/sheet na listagem. Demanda vinculada obrigatoriamente a PCA."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Listar e filtrar demandas (Priority: P1)

Como servidor autenticado com acesso ao mÃƒÆ’Ã‚Â³dulo Compras, preciso abrir `/compras` e ver uma tabela de **demandas** do meu ÃƒÆ’Ã‚Â³rgÃƒÆ’Ã‚Â£o com filtros por PCA e status, para localizar processos de contrataÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Â£o em andamento e acompanhar o portfÃƒÆ’Ã‚Â³lio do exercÃƒÆ’Ã‚Â­cio.

**Why this priority**: A listagem ÃƒÆ’Ã‚Â© o ponto de entrada operacional do mÃƒÆ’Ã‚Â³dulo; sem ela, nenhum fluxo de instruÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Â£o processual ÃƒÆ’Ã‚Â© acessÃƒÆ’Ã‚Â­vel.

**Independent Test**: Autenticar usuÃƒÆ’Ã‚Â¡rio do setor de compras; popular tenant com pelo menos dois PCAs e cinco demandas em status distintos; abrir `/compras` em atÃƒÆ’Ã‚Â© trÃƒÆ’Ã‚Âªs cliques; verificar colunas **NÃƒÆ’Ã‚Âºmero**, **TÃƒÆ’Ã‚Â­tulo**, **Objeto**, **PCA**, **Status** e **Progresso**; aplicar filtro por PCA e por status e confirmar que a tabela reflete apenas os registros correspondentes.

**Acceptance Scenarios**:

1. **Given** usuÃƒÆ’Ã‚Â¡rio com permissÃƒÆ’Ã‚Â£o no mÃƒÆ’Ã‚Â³dulo Compras, **When** acessa `/compras`, **Then** vÃƒÆ’Ã‚Âª tabela paginada de demandas do tenant com identificadores reais ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â **nÃƒÆ’Ã‚Â£o** dados de demonstraÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Â£o fixos.
2. **Given** demandas vinculadas a PCAs distintos, **When** o usuÃƒÆ’Ã‚Â¡rio filtra por um PCA, **Then** a tabela exibe **somente** demandas daquele PCA.
3. **Given** demandas em status distintos (Rascunho, Em andamento, ConcluÃƒÆ’Ã‚Â­do), **When** o usuÃƒÆ’Ã‚Â¡rio filtra por status, **Then** a tabela reflete o filtro aplicado.
4. **Given** coluna **Progresso**, **When** a tabela carrega, **Then** cada linha exibe indicador visual derivado dos artefatos preenchidos (ex.: *3/7 preenchidos*) ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â **sem** campo manual de progresso.
5. **Given** aÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Â£o *Nova demanda*, **When** o usuÃƒÆ’Ã‚Â¡rio clica, **Then** navega para `/compras/novo`.

---

### User Story 2 - Criar nova demanda (Priority: P1)

Como servidor de compras, preciso criar uma nova **demanda** em `/compras/novo`, selecionando um PCA ativo existente e informando tÃƒÆ’Ã‚Â­tulo, objeto e setor responsÃƒÆ’Ã‚Â¡vel, para iniciar a instruÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Â£o processual conforme a Lei 14.133/2021.

**Why this priority**: CriaÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Â£o de demanda ÃƒÆ’Ã‚Â© o gatilho do fluxo documental; sem ela, o mÃƒÆ’Ã‚Â³dulo nÃƒÆ’Ã‚Â£o produz valor operacional.

**Independent Test**: Criar demanda selecionando PCA ativo; verificar numeraÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Â£o sequencial automÃƒÆ’Ã‚Â¡tica; confirmar redirecionamento ao hub `/compras/:id` com status **Rascunho** e checklist de artefatos vazio.

**Acceptance Scenarios**:

1. **Given** usuÃƒÆ’Ã‚Â¡rio em `/compras/novo`, **When** preenche tÃƒÆ’Ã‚Â­tulo, objeto, seleciona PCA **ativo** e submete, **Then** demanda ÃƒÆ’Ã‚Â© criada com nÃƒÆ’Ã‚Âºmero sequencial do tenant e status **Rascunho**.
2. **Given** formulÃƒÆ’Ã‚Â¡rio de criaÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Â£o, **When** o usuÃƒÆ’Ã‚Â¡rio tenta submeter sem PCA selecionado, **Then** recebe validaÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Â£o clara ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â demanda **nÃƒÆ’Ã‚Â£o** pode existir sem PCA.
3. **Given** demanda criada com sucesso, **When** o sistema confirma, **Then** redireciona para `/compras/:id` (hub quebra-cabeÃƒÆ’Ã‚Â§a).
4. **Given** PCA com status **Encerrado**, **When** o usuÃƒÆ’Ã‚Â¡rio tenta selecionÃƒÆ’Ã‚Â¡-lo no formulÃƒÆ’Ã‚Â¡rio, **Then** PCA **nÃƒÆ’Ã‚Â£o** aparece como opÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Â£o selecionÃƒÆ’Ã‚Â¡vel ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â **sem** opÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Â£o desabilitada sem explicaÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Â£o.
5. **Given** tenant sem PCA ativo, **When** o usuÃƒÆ’Ã‚Â¡rio acessa `/compras/novo`, **Then** vÃƒÆ’Ã‚Âª orientaÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Â£o para criar PCA primeiro (via gestÃƒÆ’Ã‚Â£o na listagem) ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â formulÃƒÆ’Ã‚Â¡rio bloqueado ou com call-to-action explÃƒÆ’Ã‚Â­cito.

---

### User Story 3 - Hub quebra-cabeÃƒÆ’Ã‚Â§a da demanda (Priority: P1)

Como servidor de compras, preciso abrir `/compras/:id` e ver o detalhe da demanda com um **checklist visual** dos 7 artefatos documentais (DFD, ETP, AnÃƒÆ’Ã‚Â¡lise de Riscos, TR, Pesquisa de PreÃƒÆ’Ã‚Â§os, DotaÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Â£o OrÃƒÆ’Ã‚Â§amentÃƒÆ’Ã‚Â¡ria, Parecer JurÃƒÆ’Ã‚Â­dico), para entender o que falta completar sem ordem fixa obrigatÃƒÆ’Ã‚Â³ria de preenchimento.

**Why this priority**: O hub quebra-cabeÃƒÆ’Ã‚Â§a ÃƒÆ’Ã‚Â© a experiÃƒÆ’Ã‚Âªncia central de instruÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Â£o processual; concentra visÃƒÆ’Ã‚Â£o de progresso e acesso a todos os documentos.

**Independent Test**: Abrir demanda com DFD preenchido e ETP dispensado; verificar cards com estados **Preenchido**, **Pendente** e **Dispensado**; clicar em card pendente e navegar ÃƒÆ’Ã‚Â  sub-rota correspondente.

**Acceptance Scenarios**:

1. **Given** detalhe de demanda em `/compras/:id`, **When** a pÃƒÆ’Ã‚Â¡gina carrega, **Then** exibe cabeÃƒÆ’Ã‚Â§alho com nÃƒÆ’Ã‚Âºmero, tÃƒÆ’Ã‚Â­tulo, objeto, PCA vinculado, setor e status derivado.
2. **Given** checklist de artefatos, **When** exibido, **Then** cada card mostra nome do documento e estado: **Preenchido**, **Pendente** ou **Dispensado** (apenas ETP).
3. **Given** artefato preenchido, **When** o card ÃƒÆ’Ã‚Â© exibido, **Then** estado ÃƒÆ’Ã‚Â© **Preenchido** ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â derivado da existÃƒÆ’Ã‚Âªncia do registro com campos obrigatÃƒÆ’Ã‚Â³rios completos.
4. **Given** ETP com flag *dispensado* e motivo informado, **When** o card ETP ÃƒÆ’Ã‚Â© exibido, **Then** estado ÃƒÆ’Ã‚Â© **Dispensado** ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â **nÃƒÆ’Ã‚Â£o** **Pendente**.
5. **Given** card de artefato, **When** o usuÃƒÆ’Ã‚Â¡rio clica, **Then** navega ÃƒÆ’Ã‚Â  sub-rota correspondente (ex.: `/compras/:id/dfd`).
6. **Given** demanda inexistente ou de outro tenant, **When** o usuÃƒÆ’Ã‚Â¡rio acessa `/compras/:id`, **Then** recebe **404** ou mensagem de registro indisponÃƒÆ’Ã‚Â­vel ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â **sem** dados de outro ÃƒÆ’Ã‚Â³rgÃƒÆ’Ã‚Â£o.

---

### User Story 4 - Preencher e editar artefatos documentais (Priority: P1)

Como servidor de compras, preciso preencher e editar cada um dos 7 artefatos em sub-rotas dedicadas (`/compras/:id/dfd`, `/compras/:id/etp`, etc.), com campos estruturados e opÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Â£o de anexar comprovante, para compor a instruÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Â£o processual exigida pela Lei 14.133/2021.

**Why this priority**: Os artefatos sÃƒÆ’Ã‚Â£o o nÃƒÆ’Ã‚Âºcleo de conformidade legal; sem CRUD funcional, o mÃƒÆ’Ã‚Â³dulo nÃƒÆ’Ã‚Â£o substitui planilhas e documentos avulsos.

**Independent Test**: Para uma demanda, preencher DFD completo, dispensar ETP com motivo, preencher Pesquisa de PreÃƒÆ’Ã‚Â§os com valor estimado; retornar ao hub e verificar estados atualizados.

**Acceptance Scenarios**:

1. **Given** sub-rota `/compras/:id/dfd`, **When** o usuÃƒÆ’Ã‚Â¡rio preenche campos obrigatÃƒÆ’Ã‚Â³rios (necessidade, justificativa, objeto da contrataÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Â£o, estimativa de demanda, prazo de necessidade) e salva, **Then** registro DFD ÃƒÆ’Ã‚Â© persistido e vinculado 1:1 ÃƒÆ’Ã‚Â  demanda.
2. **Given** sub-rota `/compras/:id/etp`, **When** o usuÃƒÆ’Ã‚Â¡rio marca *dispensado* e informa motivo, **Then** ETP ÃƒÆ’Ã‚Â© salvo como dispensado ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â campos tÃƒÆ’Ã‚Â©cnicos do ETP **nÃƒÆ’Ã‚Â£o** sÃƒÆ’Ã‚Â£o exigidos.
3. **Given** sub-rota `/compras/:id/etp` **sem** dispensar, **When** o usuÃƒÆ’Ã‚Â¡rio preenche campos tÃƒÆ’Ã‚Â©cnicos e salva, **Then** ETP ÃƒÆ’Ã‚Â© salvo como preenchido.
4. **Given** sub-rota `/compras/:id/analise-riscos`, **When** o usuÃƒÆ’Ã‚Â¡rio adiciona riscos (descriÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Â£o, probabilidade, impacto, mitigaÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Â£o) e salva, **Then** lista de riscos ÃƒÆ’Ã‚Â© persistida.
5. **Given** sub-rota `/compras/:id/pesquisa-precos`, **When** o usuÃƒÆ’Ã‚Â¡rio informa valor estimado e fonte da pesquisa, **Then** registro ÃƒÆ’Ã‚Â© persistido com valor monetÃƒÆ’Ã‚Â¡rio.
6. **Given** qualquer artefato, **When** o usuÃƒÆ’Ã‚Â¡rio anexa comprovante, **Then** arquivo ÃƒÆ’Ã‚Â© associado ao registro ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â upload opcional, **nÃƒÆ’Ã‚Â£o** bloqueia salvamento dos campos estruturados.
7. **Given** artefato jÃƒÆ’Ã‚Â¡ preenchido, **When** o usuÃƒÆ’Ã‚Â¡rio edita e salva novamente, **Then** registro ÃƒÆ’Ã‚Â© atualizado (upsert) ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â **sem** duplicar registros.
8. **Given** sub-rotas de artefatos, **When** o usuÃƒÆ’Ã‚Â¡rio navega entre elas, **Then** breadcrumb indica demanda ÃƒÂ¢Ã¢â‚¬Â Ã¢â‚¬â„¢ artefato atual.

---

### User Story 5 - Gerenciar PCAs via modal (Priority: P1)

Como responsÃƒÆ’Ã‚Â¡vel pelo planejamento de compras, preciso criar, listar e encerrar **PCAs** (Planos de ContrataÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Âµes Anuais) via modal/sheet acessÃƒÆ’Ã‚Â­vel em `/compras`, para agrupar demandas por exercÃƒÆ’Ã‚Â­cio sem rota dedicada.

**Why this priority**: PCA ÃƒÆ’Ã‚Â© prÃƒÆ’Ã‚Â©-requisito obrigatÃƒÆ’Ã‚Â³rio de toda demanda; gestÃƒÆ’Ã‚Â£o inline evita fragmentaÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Â£o de navegaÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Â£o.

**Independent Test**: Abrir modal de PCAs em `/compras`; criar PCA com tÃƒÆ’Ã‚Â­tulo; listar PCAs ativos e encerrados; encerrar PCA ativo; verificar que demandas existentes permanecem vinculadas e novas demandas **nÃƒÆ’Ã‚Â£o** podem usar PCA encerrado.

**Acceptance Scenarios**:

1. **Given** usuÃƒÆ’Ã‚Â¡rio em `/compras`, **When** aciona *Gerenciar PCAs*, **Then** modal/sheet exibe lista de PCAs do tenant com tÃƒÆ’Ã‚Â­tulo, status (**Ativo** / **Encerrado**) e quantidade de demandas vinculadas.
2. **Given** modal de PCAs, **When** o usuÃƒÆ’Ã‚Â¡rio cria novo PCA informando tÃƒÆ’Ã‚Â­tulo e descriÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Â£o, **Then** PCA ÃƒÆ’Ã‚Â© persistido com status **Ativo** e aparece na lista e no seletor de `/compras/novo`.
3. **Given** PCA ativo sem demandas ou com demandas, **When** o usuÃƒÆ’Ã‚Â¡rio aciona *Encerrar*, **Then** status passa a **Encerrado** ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â demandas existentes **permanecem** vinculadas.
4. **Given** PCA encerrado, **When** listado no modal, **Then** aparece com indicaÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Â£o visual de encerrado ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â **nÃƒÆ’Ã‚Â£o** pode ser reativado nesta entrega.
5. **Given** filtro por PCA na listagem, **When** o usuÃƒÆ’Ã‚Â¡rio seleciona PCA no modal ou filtro, **Then** tabela de demandas reflete o PCA selecionado.

---

### User Story 6 - Dispensar ETP com justificativa (Priority: P2)

Como servidor de compras, preciso registrar a dispensa do Estudo TÃƒÆ’Ã‚Â©cnico Preliminar (ETP) com motivo documentado, para cumprir exceÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Âµes previstas na Lei 14.133/2021 sem bloquear o progresso da demanda.

**Why this priority**: Dispensa de ETP ÃƒÆ’Ã‚Â© caso de uso legal frequente; tratamento incorreto bloqueia falsamente o progresso ou mascara pendÃƒÆ’Ã‚Âªncias reais.

**Independent Test**: Abrir `/compras/:id/etp`; marcar dispensado; informar motivo; salvar; verificar card ETP como **Dispensado** no hub e progresso da demanda considerando ETP como satisfeito.

**Acceptance Scenarios**:

1. **Given** ETP nÃƒÆ’Ã‚Â£o preenchido, **When** o usuÃƒÆ’Ã‚Â¡rio marca *dispensado* e informa motivo, **Then** ETP ÃƒÆ’Ã‚Â© salvo com flag dispensado e motivo ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â campos tÃƒÆ’Ã‚Â©cnicos **nÃƒÆ’Ã‚Â£o** exigidos.
2. **Given** ETP dispensado, **When** o usuÃƒÆ’Ã‚Â¡rio tenta salvar **sem** motivo, **Then** validaÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Â£o impede salvamento com mensagem clara.
3. **Given** ETP preenchido anteriormente, **When** o usuÃƒÆ’Ã‚Â¡rio marca *dispensado*, **Then** sistema solicita confirmaÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Â£o ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â dados tÃƒÆ’Ã‚Â©cnicos preenchidos podem ser substituÃƒÆ’Ã‚Â­dos pela dispensa.
4. **Given** ETP dispensado, **When** progresso da demanda ÃƒÆ’Ã‚Â© calculado, **Then** ETP conta como artefato satisfeito ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â equivalente a **Preenchido** para fins de conclusÃƒÆ’Ã‚Â£o.

---

### User Story 7 - Acompanhar progresso derivado da demanda (Priority: P2)

Como gestor de compras, preciso que o **status** da demanda (Rascunho, Em andamento, ConcluÃƒÆ’Ã‚Â­do) seja derivado automaticamente dos artefatos preenchidos, para ter visÃƒÆ’Ã‚Â£o confiÃƒÆ’Ã‚Â¡vel do estÃƒÆ’Ã‚Â¡gio de instruÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Â£o sem atualizaÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Â£o manual de status.

**Why this priority**: Status manual diverge da realidade documental; derivaÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Â£o automÃƒÆ’Ã‚Â¡tica garante consistÃƒÆ’Ã‚Âªncia entre listagem, hub e relatÃƒÆ’Ã‚Â³rios futuros.

**Independent Test**: Criar demanda (Rascunho); preencher DFD (Em andamento); preencher todos os artefatos obrigatÃƒÆ’Ã‚Â³rios incluindo ETP ou dispensa (ConcluÃƒÆ’Ã‚Â­do); verificar transiÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Âµes em listagem e hub.

**Acceptance Scenarios**:

1. **Given** demanda recÃƒÆ’Ã‚Â©m-criada sem artefatos, **When** status ÃƒÆ’Ã‚Â© consultado, **Then** exibe **Rascunho**.
2. **Given** demanda com pelo menos um artefato preenchido ou ETP dispensado, **When** status ÃƒÆ’Ã‚Â© consultado, **Then** exibe **Em andamento**.
3. **Given** demanda com todos os artefatos satisfeitos (preenchidos ou ETP dispensado), **When** status ÃƒÆ’Ã‚Â© consultado, **Then** exibe **ConcluÃƒÆ’Ã‚Â­do**.
4. **Given** transiÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Â£o de status, **When** ocorre, **Then** **nÃƒÆ’Ã‚Â£o** exige aÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Â£o manual do usuÃƒÆ’Ã‚Â¡rio ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â derivaÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Â£o ÃƒÆ’Ã‚Â© automÃƒÆ’Ã‚Â¡tica a cada salvamento de artefato.

---

### User Story 8 - Navegar entre artefatos com indicaÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Â£o de pendÃƒÆ’Ã‚Âªncia (Priority: P2)

Como servidor de compras, preciso navegar entre artefatos a partir do hub ou de qualquer sub-rota, com breadcrumb e checklist lateral indicando pendÃƒÆ’Ã‚Âªncias, para completar a instruÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Â£o processual de forma eficiente sem perder contexto.

**Why this priority**: Fluxo quebra-cabeÃƒÆ’Ã‚Â§a exige navegaÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Â£o fluida; sem indicadores de pendÃƒÆ’Ã‚Âªncia, usuÃƒÆ’Ã‚Â¡rios perdem tempo retornando ao hub repetidamente.

**Independent Test**: Abrir `/compras/:id/dfd`; verificar checklist lateral com estados; navegar para TR via checklist; confirmar breadcrumb *Compras ÃƒÂ¢Ã¢â‚¬Â Ã¢â‚¬â„¢ Demanda #N ÃƒÂ¢Ã¢â‚¬Â Ã¢â‚¬â„¢ Termo de ReferÃƒÆ’Ã‚Âªncia*.

**Acceptance Scenarios**:

1. **Given** qualquer sub-rota de artefato, **When** a pÃƒÆ’Ã‚Â¡gina carrega, **Then** exibe breadcrumb com demanda e artefato atual.
2. **Given** checklist lateral ou componente equivalente, **When** exibido em sub-rota, **Then** mostra os 7 artefatos com estados atualizados ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â clicÃƒÆ’Ã‚Â¡veis para navegaÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Â£o.
3. **Given** artefato pendente no checklist, **When** exibido, **Then** indicaÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Â£o visual distingue **Pendente** de **Preenchido** e **Dispensado**.
4. **Given** link *Voltar ao hub*, **When** acionado de qualquer sub-rota, **Then** retorna a `/compras/:id`.

---

### Edge Cases

- Tenant sem PCA: `/compras/novo` orienta criaÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Â£o via modal; listagem de demandas exibe estado vazio orientador.
- Tenant sem demandas: tabela exibe estado vazio com call-to-action *Nova demanda*.
- Demanda excluÃƒÆ’Ã‚Â­da logicamente: **nÃƒÆ’Ã‚Â£o** aparece na listagem; acesso direto por URL retorna registro indisponÃƒÆ’Ã‚Â­vel.
- PCA encerrado com demandas em andamento: demandas permanecem editÃƒÆ’Ã‚Â¡veis; novas demandas **nÃƒÆ’Ã‚Â£o** podem ser criadas para aquele PCA.
- Upload de comprovante falha: campos estruturados salvos permanecem; usuÃƒÆ’Ã‚Â¡rio informado para tentar anexo novamente.
- Dois usuÃƒÆ’Ã‚Â¡rios editando o mesmo artefato: ÃƒÆ’Ã‚Âºltimo salvamento prevalece ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â conflito informado se versÃƒÆ’Ã‚Â£o divergir (comportamento padrÃƒÆ’Ã‚Â£o de upsert).
- Valor estimado zero ou negativo em Pesquisa de PreÃƒÆ’Ã‚Â§os: validaÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Â£o impede salvamento.
- AnÃƒÆ’Ã‚Â¡lise de Riscos com lista vazia: artefato considerado **Pendente** ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â **nÃƒÆ’Ã‚Â£o** **Preenchido**.
- ETP dispensado sem demais artefatos: demanda permanece **Em andamento** ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â dispensa de ETP **nÃƒÆ’Ã‚Â£o** conclui sozinha a demanda.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: O sistema **DEVE** exibir em `/compras` tabela paginada de demandas do tenant com colunas **NÃƒÆ’Ã‚Âºmero**, **TÃƒÆ’Ã‚Â­tulo**, **Objeto**, **PCA**, **Status** e **Progresso**.
- **FR-002**: O sistema **DEVE** permitir filtrar demandas por PCA e por status (Rascunho, Em andamento, ConcluÃƒÆ’Ã‚Â­do).
- **FR-003**: O sistema **DEVE** permitir criar demanda em `/compras/novo` com tÃƒÆ’Ã‚Â­tulo, objeto, PCA obrigatÃƒÆ’Ã‚Â³rio e setor opcional.
- **FR-004**: Toda demanda **DEVE** estar vinculada a exatamente um PCA ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â FK nÃƒÆ’Ã‚Â£o anulÃƒÆ’Ã‚Â¡vel.
- **FR-005**: O sistema **DEVE** atribuir nÃƒÆ’Ã‚Âºmero sequencial automÃƒÆ’Ã‚Â¡tico por tenant a cada nova demanda.
- **FR-006**: O sistema **DEVE** exibir hub quebra-cabeÃƒÆ’Ã‚Â§a em `/compras/:id` com checklist dos 7 artefatos e estados derivados.
- **FR-007**: Checklist **DEVE** distinguir trÃƒÆ’Ã‚Âªs estados por artefato: **Preenchido**, **Pendente**, **Dispensado** (apenas ETP).
- **FR-008**: O sistema **DEVE** disponibilizar sub-rotas dedicadas para cada artefato: `/compras/:id/dfd`, `/compras/:id/etp`, `/compras/:id/analise-riscos`, `/compras/:id/tr`, `/compras/:id/pesquisa-precos`, `/compras/:id/dotacao`, `/compras/:id/parecer`.
- **FR-009**: Cada artefato **DEVE** ter relaÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Â£o 1:1 com a demanda ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â upsert, **nunca** duplicar.
- **FR-010**: DFD **DEVE** exigir: necessidade, justificativa, objeto da contrataÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Â£o, estimativa de demanda, prazo de necessidade.
- **FR-011**: ETP **DEVE** permitir flag *dispensado* com motivo obrigatÃƒÆ’Ã‚Â³rio quando dispensado; campos tÃƒÆ’Ã‚Â©cnicos exigidos apenas quando **nÃƒÆ’Ã‚Â£o** dispensado.
- **FR-012**: AnÃƒÆ’Ã‚Â¡lise de Riscos **DEVE** persistir lista de riscos com descriÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Â£o, probabilidade, impacto e mitigaÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Â£o.
- **FR-013**: Pesquisa de PreÃƒÆ’Ã‚Â§os **DEVE** exigir valor estimado (positivo) e fonte da pesquisa.
- **FR-014**: DotaÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Â£o OrÃƒÆ’Ã‚Â§amentÃƒÆ’Ã‚Â¡ria **DEVE** exigir natureza de despesa, programa de trabalho, fonte de recurso e valor dotado.
- **FR-015**: Parecer JurÃƒÆ’Ã‚Â­dico **DEVE** exigir texto do parecer; nÃƒÆ’Ã‚Âºmero do documento e data de emissÃƒÆ’Ã‚Â£o opcionais.
- **FR-016**: Todos os artefatos **DEVEM** aceitar anexo de comprovante opcional ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â upload **nÃƒÆ’Ã‚Â£o** bloqueia salvamento de campos estruturados.
- **FR-017**: Progresso da demanda **DEVE** ser derivado da existÃƒÆ’Ã‚Âªncia e completude dos artefatos ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â **sem** flags boolean na entidade demanda.
- **FR-018**: Status da demanda **DEVE** ser derivado: **Rascunho** (nenhum artefato), **Em andamento** (ÃƒÂ¢Ã¢â‚¬Â°Ã‚Â¥1 satisfeito, nem todos), **ConcluÃƒÆ’Ã‚Â­do** (todos satisfeitos).
- **FR-019**: ETP dispensado com motivo **DEVE** contar como artefato satisfeito para progresso e conclusÃƒÆ’Ã‚Â£o.
- **FR-020**: GestÃƒÆ’Ã‚Â£o de PCAs **DEVE** ocorrer via modal/sheet em `/compras` ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â **sem** rota dedicada de PCA.
- **FR-021**: PCA **DEVE** ter tÃƒÆ’Ã‚Â­tulo, descriÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Â£o opcional e status (**Ativo** / **Encerrado**).
- **FR-022**: PCA encerrado **NÃƒÆ’Ã†â€™O DEVE** aparecer como opÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Â£o em `/compras/novo`.
- **FR-023**: Encerrar PCA **NÃƒÆ’Ã†â€™O DEVE** desvincular ou bloquear ediÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Â£o de demandas existentes.
- **FR-024**: Acesso **DEVE** exigir permissÃƒÆ’Ã‚Â£o no mÃƒÆ’Ã‚Â³dulo Compras ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â **sem** licenÃƒÆ’Ã‚Â§a adicional (Base).
- **FR-025**: VocabulÃƒÆ’Ã‚Â¡rio UI **DEVE** usar **demanda/demandas** (nÃƒÆ’Ã‚Â£o *ato*) no domÃƒÆ’Ã‚Â­nio Compras.
- **FR-026**: VocabulÃƒÆ’Ã‚Â¡rio UI **DEVE** usar **Compras** como nome do mÃƒÆ’Ã‚Â³dulo na navegaÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Â£o.
- **FR-027**: Sub-rotas de artefatos **DEVEM** exibir breadcrumb e navegaÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Â£o de retorno ao hub.
- **FR-028**: ExportaÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Â£o PDF do processo completo **NÃƒÆ’Ã†â€™O** faz parte desta entrega ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â aÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Â£o desabilitada ou indisponÃƒÆ’Ã‚Â­vel com mensagem orientadora.
- **FR-029**: Escopo **limita-se** ao CRUD operacional de PCAs, demandas e artefatos ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â **NÃƒÆ’Ã†â€™O** inclui FiscalizaÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Â£o (JatobÃƒÆ’Ã‚Â¡), Insights (Cedro), Maturidade (Carvalho) ou Modelos IA (Pau-Brasil).
- **FR-030**: Dados **DEVEM** respeitar isolamento por tenant ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â usuÃƒÆ’Ã‚Â¡rio **nunca** vÃƒÆ’Ã‚Âª registros de outro ÃƒÆ’Ã‚Â³rgÃƒÆ’Ã‚Â£o.

### Fronteiras entre licenÃƒÆ’Ã‚Â§as (obrigatÃƒÆ’Ã‚Â³rio)

| LicenÃƒÆ’Ã‚Â§a | O que faz neste contexto | O que **NÃƒÆ’Ã†â€™O** faz |
| --- | --- | --- |
| **Base (esta feature)** | CRUD de PCAs, demandas e 7 artefatos; progresso derivado; upload de comprovante | Fiscalizar conformidade; gerar insights; calcular maturidade; templates IA |
| **JatobÃƒÆ’Ã‚Â¡** | FiscalizaÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Â£o de conformidade por demanda (spec 019) | Alterar demandas ou artefatos |
| **Cedro** | Insights estratÃƒÆ’Ã‚Â©gicos read-only (spec 020) | CRUD operacional; conformidade registro a registro |
| **Carvalho** | Score de maturidade macro (spec 021) | InstruÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Â£o processual |
| **Pau-Brasil** | Templates de texto para DFD/ETP/TR | CRUD de demandas |

### Key Entities

- **PCA (Plano de ContrataÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Âµes Anual)**: agrupador de demandas por exercÃƒÆ’Ã‚Â­cio; tÃƒÆ’Ã‚Â­tulo, descriÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Â£o, status (Ativo/Encerrado); 1:N com Demandas.
- **Demanda**: unidade de instruÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Â£o processual; nÃƒÆ’Ã‚Âºmero sequencial, tÃƒÆ’Ã‚Â­tulo, objeto, vÃƒÆ’Ã‚Â­nculo obrigatÃƒÆ’Ã‚Â³rio a PCA, setor opcional, status derivado (Rascunho/Em andamento/ConcluÃƒÆ’Ã‚Â­do).
- **DFD (Documento de FormalizaÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Â£o de Demanda)**: 1:1 com Demanda; necessidade, justificativa, objeto da contrataÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Â£o, estimativa de demanda, prazo de necessidade; comprovante opcional.
- **ETP (Estudo TÃƒÆ’Ã‚Â©cnico Preliminar)**: 1:1 com Demanda; flag dispensado, motivo de dispensa, campos tÃƒÆ’Ã‚Â©cnicos; comprovante opcional.
- **AnÃƒÆ’Ã‚Â¡lise de Riscos**: 1:1 com Demanda; lista de riscos (descriÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Â£o, probabilidade, impacto, mitigaÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Â£o); comprovante opcional.
- **Termo de ReferÃƒÆ’Ã‚Âªncia (TR)**: 1:1 com Demanda; campos do TR conforme Lei 14.133; comprovante opcional.
- **Pesquisa de PreÃƒÆ’Ã‚Â§os**: 1:1 com Demanda; valor estimado, fonte da pesquisa; comprovante opcional.
- **DotaÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Â£o OrÃƒÆ’Ã‚Â§amentÃƒÆ’Ã‚Â¡ria**: 1:1 com Demanda; natureza de despesa, programa de trabalho, fonte de recurso, valor dotado; comprovante opcional.
- **Parecer JurÃƒÆ’Ã‚Â­dico**: 1:1 com Demanda; parecer, nÃƒÆ’Ã‚Âºmero do documento, data de emissÃƒÆ’Ã‚Â£o; comprovante opcional.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: UsuÃƒÆ’Ã‚Â¡rio autorizado alcanÃƒÆ’Ã‚Â§a a listagem de demandas em **ÃƒÂ¢Ã¢â‚¬Â°Ã‚Â¤ 3 cliques** a partir da navegaÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Â£o principal.
- **SC-002**: CriaÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Â£o de demanda (formulÃƒÆ’Ã‚Â¡rio ÃƒÂ¢Ã¢â‚¬Â Ã¢â‚¬â„¢ hub) concluÃƒÆ’Ã‚Â­da em **ÃƒÂ¢Ã¢â‚¬Â°Ã‚Â¤ 2 minutos** por usuÃƒÆ’Ã‚Â¡rio sem treinamento prÃƒÆ’Ã‚Â©vio.
- **SC-003**: **100%** dos estados de artefato no hub refletem dados persistidos ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â **zero** inconsistÃƒÆ’Ã‚Âªncia entre sub-rota e checklist.
- **SC-004**: Preenchimento completo dos 7 artefatos (ou ETP dispensado) atualiza status para **ConcluÃƒÆ’Ã‚Â­do** automaticamente ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â **sem** aÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Â£o manual de status.
- **SC-005**: Filtro por PCA retorna resultados corretos em **ÃƒÂ¢Ã¢â‚¬Â°Ã‚Â¤ 2 segundos** percebidos pelo usuÃƒÆ’Ã‚Â¡rio com atÃƒÆ’Ã‚Â© 500 demandas no tenant.
- **SC-006**: GestÃƒÆ’Ã‚Â£o de PCA (criar + encerrar) via modal concluÃƒÆ’Ã‚Â­da em **ÃƒÂ¢Ã¢â‚¬Â°Ã‚Â¤ 1 minuto**.
- **SC-007**: DemonstraÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Â£o ponta a ponta (criar PCA ÃƒÂ¢Ã¢â‚¬Â Ã¢â‚¬â„¢ criar demanda ÃƒÂ¢Ã¢â‚¬Â Ã¢â‚¬â„¢ preencher DFD ÃƒÂ¢Ã¢â‚¬Â Ã¢â‚¬â„¢ dispensar ETP ÃƒÂ¢Ã¢â‚¬Â Ã¢â‚¬â„¢ preencher demais artefatos ÃƒÂ¢Ã¢â‚¬Â Ã¢â‚¬â„¢ status ConcluÃƒÆ’Ã‚Â­do) concluÃƒÆ’Ã‚Â­da em **ÃƒÂ¢Ã¢â‚¬Â°Ã‚Â¤ 20 minutos** por usuÃƒÆ’Ã‚Â¡rio sem treinamento prÃƒÆ’Ã‚Â©vio.
- **SC-008**: **Nenhum** registro de outro tenant visÃƒÆ’Ã‚Â­vel em listagem, hub ou sub-rotas ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â validÃƒÆ’Ã‚Â¡vel com dois tenants de teste.
- **SC-009**: NavegaÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Â£o entre os 7 artefatos a partir do hub exige **ÃƒÂ¢Ã¢â‚¬Â°Ã‚Â¤ 2 cliques** por transiÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Â£o.

## Assumptions

- **DomÃƒÆ’Ã‚Â­nio de cÃƒÆ’Ã‚Â³digo**: mÃƒÆ’Ã‚Â³dulo identificado como `purchasing` / `compras`; rotas pÃƒÆ’Ã‚Âºblicas em `/compras/*`.
- **Lei aplicÃƒÆ’Ã‚Â¡vel**: Lei 14.133/2021 ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â campos dos artefatos seguem estrutura mÃƒÆ’Ã‚Â­nima para instruÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Â£o processual; detalhamento normativo fino fica para fase plan.
- **NumeraÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Â£o de demanda**: sequencial por tenant, sem reinÃƒÆ’Ã‚Â­cio por exercÃƒÆ’Ã‚Â­cio nesta entrega.
- **NumeraÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Â£o de PCA**: sem campo exercÃƒÆ’Ã‚Â­cio/ano dedicado nesta entrega ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â tÃƒÆ’Ã‚Â­tulo livre identifica o PCA.
- **Setor**: vÃƒÆ’Ã‚Â­nculo opcional a setor existente do tenant (ex.: DEAE no seed Jacaranda).
- **Upload**: comprovante opcional via storage interno; falha de upload nÃƒÆ’Ã‚Â£o reverte campos salvos.
- **Ordem de preenchimento**: livre (quebra-cabeÃƒÆ’Ã‚Â§a) ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â **nÃƒÆ’Ã‚Â£o** hÃƒÆ’Ã‚Â¡ bloqueio sequencial entre artefatos.
- **ReativaÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Â£o de PCA encerrado**: fora de escopo nesta entrega.
- **DependÃƒÆ’Ã‚Âªncia**: mÃƒÆ’Ã‚Â³dulo Compras provisionado no tenant via seed/admin; usuÃƒÆ’Ã‚Â¡rio com permissÃƒÆ’Ã‚Â£o no mÃƒÆ’Ã‚Â³dulo.
- **Mocks existentes**: telas mock em `shell/config/screens.ts` serÃƒÆ’Ã‚Â£o substituÃƒÆ’Ã‚Â­das por pÃƒÆ’Ã‚Â¡ginas reais nesta entrega.

## Out of Scope

- Painel de FiscalizaÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Â£o JatobÃƒÆ’Ã‚Â¡ (`/compras/fiscalizacao`) ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â spec 019.
- Insights IA Cedro (`/compras/insights`) ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â spec 020.
- Maturidade Carvalho (`/compras/maturidade`) ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â spec 021.
- Modelos IA Pau-Brasil para DFD/ETP/TR.
- ExportaÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Â£o PDF do processo completo (rota retorna indisponÃƒÆ’Ã‚Â­vel).
- IntegraÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Â£o real com PNCP/COMPRASNET.
- TramitaÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Â£o inter-setorial de demandas.
- Workflow de aprovaÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Â£o multi-nÃƒÆ’Ã‚Â­vel entre setores.
- NumeraÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Â£o de PCA por exercÃƒÆ’Ã‚Â­cio fiscal.
