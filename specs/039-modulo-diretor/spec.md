# Feature Specification: Módulo Diretor

**Feature Branch**: `039-modulo-diretor`

**Created**: 2026-08-25

**Status**: Draft

**Input**: User description: "Vamos criar o modulo diretor. tela que so vai ser exibida para ebenezer.bezerra@ageman.am.gov.br, admin tenant e plataform. basicamente a tela vai ser um aglomerado de dashboard, cards kpi. filtragem: ano e mes (com mes e ano atual ja selecionados por padrao); modulos: somente ouvidoria e diagnostico por enquanto; dentro de modulos: filtragem dos ultimos 7 dias e 3 dias; filtragem por ações de usuarios dentro dos modulos. fora de modulos, vamos ter auditoria tambem. a tela vai ser somente um read only gigantesco. endpoints especificos com cache e paginação pesada para desempenho, frontend com cache e chunking e paginação. sem redis."

## Contexto

A Diretoria-Presidência da AGEMAN precisa de uma única tela de acompanhamento — somente leitura — que reúna, num só lugar, o panorama dos módulos que já estão em operação na instituição (nesta entrega: Ouvidoria e Diagnóstico) e o rastro de auditoria da plataforma.

Hoje cada módulo tem o próprio painel. O diretor (e os administradores institucionais/plataforma) precisam cruzar volume, prazos e ações de pessoas sem entrar em cada módulo operacional, e sem poder alterar nenhum dado a partir desta tela.

O destinatário nominal é Ebenezer Albuquerque Bezerra (`ebenezer.bezerra@ageman.am.gov.br`), Diretor-Presidente. A mesma tela também fica disponível para administradores do tenant, administradores da plataforma institucional e superadministradores da plataforma (SaaS), sempre no contexto do tenant AGEMAN.

Esta feature **não** é o cadastro organizacional de “Diretorias” do Gabinete (spec 038). É um módulo novo de visão executiva.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Diretor abre a tela e vê o panorama do mês corrente (Priority: P1)

O diretor autenticado, com permissão, abre a tela do Módulo Diretor e imediatamente vê um aglomerado de cartões de indicadores (KPIs) dos módulos habilitados — nesta entrega, Ouvidoria e Diagnóstico — já filtrados para o **mês e o ano atuais**, sem precisar escolher período. A tela é somente leitura: não há botão, formulário ou ação que altere manifestações, processos, marcadores ou registros de auditoria.

**Why this priority**: Sem a visão consolidada do período corrente a tela não entrega o valor prometido. É o recorte mínimo utilizável (MVP): acesso + KPIs do mês atual + bloqueio de escrita.

**Independent Test**: Pode ser testado autenticando um usuário autorizado no tenant AGEMAN, abrindo a tela do diretor e verificando que os cartões de Ouvidoria e Diagnóstico aparecem com o mês/ano atuais pré-selecionados, e que nenhuma ação de escrita é oferecida.

**Acceptance Scenarios**:

1. **Given** um usuário autorizado no tenant AGEMAN (administrador do tenant, administrador da plataforma institucional, superadministrador SaaS, ou o e-mail `ebenezer.bezerra@ageman.am.gov.br`), **When** abre a tela do Módulo Diretor, **Then** vê os blocos de Ouvidoria e Diagnóstico com cartões de KPI do mês e ano correntes já selecionados.
2. **Given** a tela carregada, **When** o diretor examina qualquer bloco, **Then** encontra somente informações de consulta — nenhum controle cria, edita, encaminha, arquiva ou exclui dados.
3. **Given** um usuário autenticado sem o papel autorizado e sem o e-mail nominado, **When** tenta abrir a tela, **Then** é impedido de vê-la (acesso negado) e não recebe nenhum indicador.
4. **Given** um usuário autorizado em um tenant que não é a AGEMAN, **When** tenta abrir a tela, **Then** a tela não é oferecida — o módulo é exclusivo da AGEMAN nesta entrega.
5. **Given** os cartões de KPI, **When** exibidos, **Then** reutilizam os mesmos indicadores já existentes nos painéis de Ouvidoria e de Diagnóstico — sem métricas novas nesta entrega.

---

### User Story 2 - Diretor troca o mês e o ano da visão consolidada (Priority: P2)

O diretor precisa olhar um mês passado (ou outro ano) sem sair da tela. Ao alterar o filtro global de ano e/ou mês, os blocos que respeitam período calendário atualizam os cartões para aquele recorte. O filtro começa sempre no mês/ano atuais; o diretor só muda se quiser.

**Why this priority**: A comparação mensal é o segundo uso mais natural depois de “como estamos neste mês”. Não depende dos presets de 7/3 dias nem do filtro por pessoa.

**Independent Test**: Pode ser testado abrindo a tela (mês/ano atuais), escolhendo outro mês ou ano e verificando que os blocos calendário passam a refletir o novo período, sem recarregar a experiência inteira de forma bloqueante.

**Acceptance Scenarios**:

1. **Given** a tela aberta no mês/ano atuais, **When** o diretor seleciona outro mês do mesmo ano, **Then** os blocos que usam o filtro calendário passam a mostrar os indicadores daquele mês, e o filtro global exibe a nova seleção.
2. **Given** a tela aberta, **When** o diretor seleciona outro ano, **Then** os indicadores calendário passam a usar o ano escolhido (com o mês ainda selecionado, salvo se o diretor também o alterar).
3. **Given** um mês/ano sem movimento no módulo, **When** o filtro é aplicado, **Then** os cartões mostram zero ou estado vazio compreensível — a tela não quebra.
4. **Given** o diretor alterou o período, **When** recarrega a tela, **Then** volta ao padrão mês/ano atuais (a seleção não precisa ser lembrada entre sessões nesta entrega).

---

### User Story 3 - Diretor recorta um bloco para os últimos 7 ou 3 dias (Priority: P2)

Dentro de cada bloco de módulo, o diretor pode pedir o recorte dos **últimos 7 dias** ou dos **últimos 3 dias**. Esse preset **substitui temporariamente** o filtro global de ano/mês **somente naquele bloco**. Os demais blocos continuam no período calendário escolhido. Ao desligar o preset, o bloco volta ao ano/mês globais.

**Why this priority**: É o recorte operacional de “o que aconteceu nesta semana / nestes três dias”, complementar ao calendário mensal, e já foi definido como comportamento de substituição (não de filtro empilhado).

**Independent Test**: Pode ser testado aplicando “últimos 7 dias” só no bloco de Ouvidoria e verificando que Diagnóstico (e a auditoria geral) permanecem no mês/ano globais; ao limpar o preset, Ouvidoria volta ao calendário.

**Acceptance Scenarios**:

1. **Given** a tela no mês/ano atuais, **When** o diretor aplica “últimos 7 dias” no bloco de Ouvidoria, **Then** os indicadores daquele bloco passam a considerar apenas os últimos 7 dias, e o bloco de Diagnóstico permanece no mês/ano globais.
2. **Given** um bloco com preset de 3 dias ativo, **When** o diretor aplica “últimos 7 dias” no mesmo bloco, **Then** o recorte passa a ser 7 dias (um preset por vez por bloco).
3. **Given** um bloco com preset ativo, **When** o diretor desliga o preset, **Then** aquele bloco volta a obedecer o filtro global de ano/mês.
4. **Given** o bloco de Diagnóstico, **When** um preset de 7 ou 3 dias é aplicado, **Then** o recorte vale **somente** para dados locais já migrados (marcadores e documentos institucionais). Os indicadores de estoque que vêm da base externa de processos **não** mudam com data — continuam mostrando o panorama atual, com indicação visual de que aquele conjunto não é recortado por período.

---

### User Story 4 - Diretor filtra as ações de pessoas dentro de um módulo (Priority: P3)

Dentro de cada bloco de módulo, o diretor precisa ver **quem fez o quê** no período vigente daquele bloco (ano/mês ou o preset 7/3 dias ativo). O filtro por pessoa restringe a lista/resumo de ações àquele autor, sem permitir editar a ação.

**Why this priority**: Entrega o recorte de responsabilidade operacional, mas só faz sentido depois que o período do bloco já está definido (US1–US3).

**Independent Test**: Pode ser testado escolhendo um servidor que tenha ações no período e verificando que o bloco mostra apenas as ações dessa pessoa; ao limpar o filtro, o bloco volta ao total do período.

**Acceptance Scenarios**:

1. **Given** o bloco de Ouvidoria com período definido, **When** o diretor escolhe um servidor na filtragem de ações, **Then** o bloco passa a mostrar somente as ações daquela pessoa no período vigente do bloco (encaminhamentos, respostas, encerramentos e demais eventos já registrados no módulo).
2. **Given** um servidor sem nenhuma ação no período, **When** o diretor o seleciona, **Then** o bloco mostra estado vazio compreensível, sem erro.
3. **Given** um filtro de pessoa ativo e um preset de 7 ou 3 dias no mesmo bloco, **When** ambos estão aplicados, **Then** as ações listadas respeitam os dois recortes (pessoa **e** janela do preset).
4. **Given** o bloco de Diagnóstico, **When** o diretor filtra por pessoa, **Then** o recorte aplica-se às ações locais já migradas (por exemplo, marcadores feitos por aquele usuário) — não inventa histórico de ações na base externa de processos.

---

### User Story 5 - Diretor consulta a auditoria geral da plataforma (Priority: P3)

Fora dos blocos de módulo, a tela oferece um bloco de **auditoria geral**: o rastro de alterações feitas na plataforma (quem, o quê, quando, em qual registro). Essa lista é somente leitura, paginada, e independente dos presets 7/3 dias dos módulos. O filtro global de ano/mês recorta a auditoria pelo momento do evento.

**Why this priority**: Fecha a visão “fora dos módulos” pedida pelo diretor, mas não bloqueia o MVP de KPIs. Pode ser entregue depois das user stories de módulo.

**Independent Test**: Pode ser testado abrindo o bloco de auditoria no mês corrente e avançando páginas; um usuário sem permissão jamais vê essa lista.

**Acceptance Scenarios**:

1. **Given** um usuário autorizado na tela do diretor, **When** examina o bloco de auditoria geral, **Then** vê uma lista paginada de eventos da plataforma no ano/mês selecionados, com autor, ação, alvo e momento.
2. **Given** milhares de eventos no período, **When** o diretor avança para a página seguinte, **Then** recebe a próxima fatia sem a tela travar ou tentar carregar o histórico inteiro de uma vez.
3. **Given** um preset de 7 ou 3 dias ativo em Ouvidoria, **When** o diretor olha a auditoria geral, **Then** a auditoria **não** herda esse preset — continua no ano/mês globais.
4. **Given** a lista de auditoria, **When** o diretor tenta qualquer alteração, **Then** não encontra ação de escrita — o bloco é exclusivamente consulta.

---

### Edge Cases

- Usuário autenticado sem papel autorizado e sem o e-mail nominado tenta a URL direta da tela: recebe acesso negado e nenhum indicador é calculado.
- Superadministrador SaaS está em sessão fora do tenant AGEMAN: a tela não é oferecida; o acesso só existe no contexto AGEMAN.
- O e-mail nominado pertence a um usuário que também já é administrador da plataforma institucional: o acesso continua válido (a checagem de e-mail é salvaguarda explícita, não exclusão).
- Mês/ano futuro ou período sem movimento: cartões e listas mostram zero/vazio compreensível, sem erro.
- Bloco de Diagnóstico: indicadores de estoque da base externa de processos **ignoram** ano/mês e presets; apenas dados locais migrados respeitam período. A tela deixa isso explícito no bloco, para o diretor não achar que o estoque “mudou de mês”.
- A consulta do bloco de Diagnóstico falha (base externa indisponível): Ouvidoria e auditoria continuam visíveis; só o bloco de Diagnóstico mostra aviso de indisponibilidade.
- Volume muito alto de eventos de auditoria ou de ações de usuário: a tela nunca tenta desenhar o conjunto inteiro — sempre páginas (e o restante da tela carrega por blocos, para um bloco lento não impedir os outros).
- Resumos recentemente consultados podem estar alguns instantes defasados em relação ao último evento recém-registrado: a tela privilegia rapidez; ao mudar filtro ou pedir atualização, busca de novo.
- Filtro de pessoa apontando para alguém que não existe mais ou está inativo: estado vazio, sem quebrar o bloco.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: O sistema DEVE exibir a tela do Módulo Diretor somente a usuários autenticados que sejam administrador do tenant, administrador da plataforma institucional, superadministrador SaaS, **ou** cujo e-mail seja exatamente `ebenezer.bezerra@ageman.am.gov.br`.
- **FR-002**: O sistema DEVE recusar o acesso (sem vazar indicadores) a qualquer outro usuário autenticado, inclusive se a pessoa souber o endereço da tela.
- **FR-003**: O módulo DEVE existir somente no tenant AGEMAN nesta entrega. Em qualquer outro tenant a tela não é oferecida.
- **FR-004**: A tela DEVE abrir com o filtro global de **ano e mês iguais ao mês/ano correntes** já selecionados.
- **FR-005**: A tela DEVE apresentar, nesta entrega, exatamente dois blocos de módulo — Ouvidoria e Diagnóstico — de forma que novos módulos possam ser acrescentados em entregas futuras sem redesenhar o acesso ou o filtro global.
- **FR-006**: Os cartões de KPI de cada bloco DEEM reutilizar os indicadores já existentes no painel daquele módulo. Esta entrega NÃO introduz métricas novas.
- **FR-007**: Dentro de cada bloco de módulo, o diretor DEVE poder aplicar o recorte “últimos 7 dias” ou “últimos 3 dias”. O preset substitui temporariamente o filtro global de ano/mês **somente naquele bloco**.
- **FR-008**: Dentro de cada bloco de módulo, o diretor DEVE poder filtrar as ações pelo servidor que as realizou, no período vigente daquele bloco (calendário ou preset).
- **FR-009**: Fora dos blocos de módulo, a tela DEVE oferecer um bloco de auditoria geral da plataforma (autor, ação, alvo, momento), recortado pelo ano/mês globais, independente dos presets 7/3 dias.
- **FR-010**: Toda a tela DEVE ser somente leitura. Nenhuma ação a partir do Módulo Diretor cria, altera ou apaga dados operacionais ou de auditoria.
- **FR-011**: Listas longas (ações de usuário e auditoria geral) DEVEM ser servidas em páginas. A tela DEVE carregar os blocos de forma independente, para que um bloco lento não impeça a leitura dos demais.
- **FR-012**: Resumos e páginas recentemente consultados DEVEM ser reaproveitados por um período curto para manter a tela rápida, sem depender de um serviço externo de cache dedicado. Ao mudar filtro ou pedir atualização, o sistema busca de novo.
- **FR-013**: No bloco de Diagnóstico, o filtro de período (ano/mês ou preset 7/3 dias) DEVE aplicar-se somente aos dados locais já migrados (marcadores e documentos institucionais). Os indicadores de estoque da base externa de processos permanecem no panorama atual e DEVEM ser identificados como não recortáveis por data.
- **FR-014**: A tela DEVE viver somente no aplicativo web institucional do tenant. Não há tela equivalente no aplicativo separado de superadministração SaaS nesta entrega. Superadministrador SaaS acessa no contexto do tenant AGEMAN.

### Key Entities

- **Visão do Diretor**: a tela consolidada, sempre somente leitura, composta por blocos de módulo + bloco de auditoria geral, com um filtro global de ano/mês.
- **Bloco de módulo**: recorte visual de um módulo operacional (Ouvidoria ou Diagnóstico) contendo cartões de KPI, preset local de 7/3 dias e filtro de ações por pessoa.
- **Indicador (KPI)**: número ou cartão já existente no painel do módulo de origem, reapresentado na Visão do Diretor sem recálculo de fórmula nova.
- **Ação de usuário**: evento já registrado no módulo (quem fez, o quê, quando) — por exemplo, encaminhar, responder ou encerrar uma manifestação; ou marcar um processo no Diagnóstico.
- **Evento de auditoria geral**: rastro transversal da plataforma sobre alterações (quem, ação, alvo, momento), independente do bloco de módulo.
- **Pessoa autorizada**: administrador do tenant, administrador da plataforma institucional, superadministrador SaaS, ou o usuário nominado pelo e-mail do Diretor-Presidente.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Um usuário autorizado no tenant AGEMAN abre a tela e vê os cartões do mês corrente dos dois módulos em menos de 5 segundos na primeira carga, e em menos de 2 segundos quando revisita o mesmo período ainda “quente”.
- **SC-002**: Em 100% das tentativas, um usuário sem autorização (incluindo URL direta) não vê a tela nem qualquer indicador; um usuário autorizado fora da AGEMAN também não.
- **SC-003**: Trocar ano/mês ou aplicar um preset 7/3 dias atualiza o bloco correspondente sem exigir que o diretor recarregue a página inteira, e sem que os outros blocos “sumam” enquanto o bloco alvo atualiza.
- **SC-004**: A tela não oferece nenhuma ação de escrita. Em revisão de aceite, zero controles de criar/editar/excluir/encaminhar são encontrados no Módulo Diretor.
- **SC-005**: Com um volume grande de eventos de auditoria (milhares no período), o diretor consegue avançar página a página e a lista permanece utilizável — a tela não tenta carregar o histórico inteiro de uma vez.

## Assumptions

- O usuário nominado `ebenezer.bezerra@ageman.am.gov.br` já existe no tenant AGEMAN. A checagem explícita de e-mail é salvaguarda de produto mesmo que essa pessoa já possua papel de administrador da plataforma institucional.
- “Admin tenant e plataforma” significa os três papéis: administrador do tenant, administrador da plataforma institucional e superadministrador SaaS — além do e-mail nominado.
- Superadministrador SaaS acessa esta tela autenticado no aplicativo web institucional, no contexto do tenant AGEMAN. Não haverá tela espelhada no aplicativo de superadministração. Se o fluxo atual de autenticação SaaS não permitir essa sessão no app institucional, isso é um achado do planejamento técnico — não muda o requisito de negócio.
- Os indicadores exibidos são os já oferecidos pelos painéis atuais de Ouvidoria e Diagnóstico. Não há lista nova de KPIs nesta entrega.
- Diagnóstico mistura estoque de processos numa base externa (sem recorte por data nesta tela) com dados locais já migrados (marcadores e documentos institucionais), que **aceitam** recorte por período.
- A auditoria “fora dos módulos” é o rastro geral de alterações da plataforma, hoje apenas gravado e ainda sem tela de consulta — esta feature passa a oferecê-lo como lista paginada, somente leitura, no bloco de auditoria.
- Presets de 7 e 3 dias **substituem** o ano/mês dentro do bloco; não se somam a ele. A auditoria geral não herda esses presets.
- A seleção de ano/mês não precisa persistir entre sessões; cada abertura volta ao mês/ano correntes.
- Novos módulos (Gabinete, SIGED, etc.) ficam de fora desta entrega; a estrutura da tela deve apenas permitir acrescentá-los depois.
- Desempenho: não haverá serviço externo dedicado de cache. A rapidez vem de reaproveitar por pouco tempo os resumos já consultados e de paginar listas longas, carregando a tela por blocos.
- Nome exato da rota e o rótulo no menu/catálogo de telas serão definidos no planejamento técnico; o requisito de negócio é “uma tela exclusiva, facilmente reconhecível como visão do diretor”.
- Esta feature é independente da spec 038 (migração de módulos v1). Consome dados já existentes/migrados; não altera o escopo da 038.
- Vocabulário: “Diretorias” do Gabinete continua sendo cadastro organizacional. “Módulo Diretor” é esta visão executiva.
