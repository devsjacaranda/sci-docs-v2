# Feature Specification: Autenticação e Permissão por Setor

**Feature Branch**: `002-auth-setor-permissao`

**Created**: 2026-06-05

**Status**: Completed

**Input**: User description: "Configurar novo auth e permissão do Controle Interno — permissão baseada em setores; vincular módulo a setor(es); vincular usuário a setor(es); nenhuma tela oculta — exibir 403 com opção de pedir permissão ao líder do setor. Exemplo de copy: 403 · Acesso negado / Sem permissão para Protocolo Virtual / módulo vinculado a setor(es) específico(s) / Setor(es) com acesso: Gabinete, Jurídico / Líder responsável: Maria Oliveira / Voltar / Pedir permissão ao líder do setor."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Acesso a módulo conforme setor do usuário (Priority: P1)

Como usuário autenticado do tenant, preciso acessar módulos de negócio apenas quando pelo menos um dos meus setores de lotação estiver autorizado para aquele módulo, para que o Controle Interno respeite a estrutura organizacional da instituição sem esconder funcionalidades da navegação.

**Why this priority**: É o núcleo da feature — sem verificação de setor por módulo, o restante (403, solicitação, administração) não tem propósito.

**Independent Test**: Pode ser testado autenticando um usuário cujos setores não intersectam os setores autorizados do módulo, navegando até um módulo restrito (ex.: Protocolo Virtual) e verificando que o acesso é bloqueado com tela 403 informativa, enquanto um usuário com setor autorizado entra normalmente.

**Acceptance Scenarios**:

1. **Given** um módulo de negócio vinculado ao setor Jurídico, **When** um usuário lotado no setor Jurídico tenta abrir o módulo, **Then** o conteúdo do módulo é exibido normalmente.
2. **Given** o módulo Protocolo Virtual vinculado aos setores Gabinete e Jurídico, **When** um usuário lotado apenas no setor Patrimônio tenta abrir o módulo, **Then** o sistema exibe a tela **403 · Acesso negado** com o nome do módulo, a lista de setores autorizados e os líderes responsáveis — sem ocultar o item na navegação.
3. **Given** o módulo Protocolo Virtual vinculado aos setores Gabinete e Jurídico, **When** um usuário lotado nos setores Gabinete e Ouvidoria tenta abrir o módulo, **Then** o acesso é permitido porque Gabinete está entre os setores autorizados do módulo.
4. **Given** um usuário autenticado como administrador da plataforma do tenant, **When** acessa qualquer módulo de negócio, **Then** o acesso é permitido independentemente do vínculo setor–módulo.
5. **Given** os módulos Global e Tramitação sem vínculo restritivo de setor, **When** qualquer usuário autenticado do tenant os abre, **Then** o acesso é permitido.

---

### User Story 2 - Tela 403 com solicitação ao líder do setor (Priority: P1)

Como usuário sem permissão para um módulo, preciso entender por que fui bloqueado e solicitar acesso aos líderes dos setores responsáveis, para resolver a barreira sem abrir chamado externo ou contato informal.

**Why this priority**: A experiência 403 e o fluxo de solicitação são requisitos explícitos de produto e diferenciam esta plataforma de ocultar menus.

**Independent Test**: Pode ser testado bloqueando um usuário em um módulo restrito, acionando **Pedir permissão ao líder do setor** e confirmando que todos os chefes dos setores vinculados ao módulo recebem notificação identificando solicitante, módulo e setor.

**Acceptance Scenarios**:

1. **Given** um usuário sem permissão para Protocolo Virtual (vinculado a Gabinete e Jurídico), **When** a tela 403 é exibida, **Then** ela apresenta: título **403 · Acesso negado**, mensagem **Sem permissão para Protocolo Virtual**, texto explicativo *"Este módulo está vinculado a setor(es) específico(s). Você precisa ser membro de um setor autorizado — módulos nunca ficam ocultos, apenas protegidos por permissão."*, lista **Setor(es) com acesso a este módulo** (ex.: Gabinete, Jurídico), **Líder responsável** listando todos os líderes correspondentes (ex.: Gabinete — Maria Oliveira; Jurídico — Paulo Ribeiro), botão **Voltar** e botão **Pedir permissão ao líder do setor**.
2. **Given** um módulo vinculado a um único setor com chefe designado, **When** a tela 403 é exibida, **Then** **Líder responsável** apresenta o nome do chefe daquele setor (ex.: Maria Oliveira).
3. **Given** a tela 403 de um módulo, **When** o usuário clica em **Voltar**, **Then** retorna à tela anterior sem perder a sessão.
4. **Given** a tela 403 de um módulo vinculado a dois ou mais setores, **When** o usuário clica em **Pedir permissão ao líder do setor**, **Then** o sistema registra a solicitação, notifica **todos os chefes** dos setores vinculados ao módulo e confirma ao solicitante que a solicitação foi enviada.
5. **Given** uma solicitação já enviada na mesma sessão, **When** o usuário permanece na tela 403, **Then** o botão de solicitar é substituído por confirmação de envio indicando que os líderes responsáveis foram notificados.

---

### User Story 3 - Administração de vínculos módulo–setor (Priority: P2)

Como administrador da plataforma do tenant, preciso configurar quais setores têm acesso a cada módulo de negócio, para refletir a organização institucional e controlar permissões de forma centralizada.

**Why this priority**: Sem gestão de vínculos, as regras de acesso não podem ser mantidas pelo cliente após o go-live.

**Independent Test**: Pode ser testado alterando os setores autorizados de um módulo (ex.: adicionar Gabinete a Jurídico) e verificando que usuários do novo setor passam a acessar e usuários cujos setores não intersectam os autorizados passam a receber 403.

**Acceptance Scenarios**:

1. **Given** um administrador da plataforma autenticado, **When** consulta a configuração de vínculos módulo–setor, **Then** vê cada módulo de negócio com a lista de setores autorizados e o(s) líder(es) correspondente(s).
2. **Given** um módulo sem setores vinculados, **When** qualquer usuário autenticado (exceto regras de administração) tenta acessá-lo, **Then** o acesso é permitido — módulo sem vínculo não restringe por setor.
3. **Given** um módulo com um ou mais setores vinculados, **When** o administrador atualiza os setores autorizados, **Then** a nova configuração passa a valer imediatamente para novas tentativas de acesso.
4. **Given** a área de administração de vínculos, **When** um usuário sem perfil de administrador da plataforma tenta acessá-la, **Then** recebe bloqueio com mensagem de permissão insuficiente (não oculta o item).

---

### User Story 4 - Cadastro de usuário vinculado a setor(es) (Priority: P2)

Como administrador da plataforma do tenant, preciso cadastrar usuários associados a um ou mais setores de lotação, para que as regras de permissão por módulo funcionem com base na lotação organizacional.

**Why this priority**: Usuário sem setor definido impede a avaliação correta de acesso; complementa a gestão de vínculos.

**Independent Test**: Pode ser testado criando um usuário nos setores Gabinete e Ouvidoria e confirmando acesso aos módulos cujo vínculo inclui qualquer um desses setores.

**Acceptance Scenarios**:

1. **Given** um administrador da plataforma, **When** cadastra um novo usuário, **Then** deve informar obrigatoriamente ao menos um setor de lotação ativo e o usuário recebe automaticamente acesso a todas as licenças do tenant (Carvalho, Pau-Brasil, Jatobá e Cedro).
2. **Given** um usuário existente, **When** o administrador altera seus setores de lotação, **Then** as permissões de módulo passam a refletir a nova combinação de setores nas próximas requisições.
3. **Given** um chefe de setor autenticado, **When** consulta membros do seu setor, **Then** vê apenas usuários lotados no(s) setor(es) sob sua chefia — sem acesso à gestão global de usuários da plataforma.

---

### User Story 5 - Chefia recebe solicitações de acesso (Priority: P3)

Como chefe de setor, preciso receber e reconhecer solicitações de acesso a módulos vinculados ao(s) meu(s) setor(es), para decidir concessão de acesso de forma rastreável fora do sistema.

**Why this priority**: Fecha o ciclo iniciado na tela 403; secundário à verificação e ao cadastro, mas necessário para operação autônoma do tenant.

**Independent Test**: Pode ser testado enviando uma solicitação como usuário bloqueado em módulo multi-setor e verificando que cada chefe dos setores vinculados vê a notificação com solicitante, módulo e data.

**Acceptance Scenarios**:

1. **Given** uma solicitação de permissão enviada por um usuário para um módulo vinculado a Gabinete e Jurídico, **When** cada chefe desses setores acessa notificações, **Then** vê item do tipo solicitação de acesso com nome do solicitante, e-mail, módulo e mensagem descritiva.
2. **Given** uma notificação de solicitação não lida, **When** o chefe a abre, **Then** consegue identificar qual módulo e qual setor motivaram a solicitação.
3. **Given** um usuário comum sem chefia, **When** tenta acessar a área de notificações de chefia, **Then** recebe bloqueio de permissão.

---

### Edge Cases

- Usuário autenticado cujos setores de lotação foram todos desativados ou removidos: deve perder acesso a módulos restritos e receber 403 até ser realocado a pelo menos um setor ativo.
- Usuário com múltiplos setores de lotação: acesso concedido se **qualquer** setor do usuário intersectar os setores autorizados do módulo.
- Módulo vinculado a múltiplos setores: na 403, todos os setores autorizados e todos os líderes correspondentes são listados.
- Módulo vinculado a múltiplos setores com chefes distintos: solicitação de permissão gera uma notificação para **cada** chefe dos setores vinculados.
- Módulo vinculado a setor sem chefe designado: solicitação de permissão ainda é registrada; mensagem de confirmação indica que a solicitação foi encaminhada ao setor responsável (sem nome de líder).
- Usuário chefe do setor A mas lotado no setor B: regras de chefia (notificações, membros) e regras de lotação (acesso a módulos) são independentes.
- Tentativa de acesso direto por endereço (deep link) a rota interna de módulo sem permissão: mesma tela 403, não redirecionamento silencioso para outra área.
- Administrador da plataforma altera vínculos enquanto usuário está dentro do módulo: na próxima navegação ou atualização de contexto, a permissão é reavaliada.
- Solicitações duplicadas na mesma sessão: segunda tentativa não gera notificações duplicadas; usuário vê estado de solicitação já enviada.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: O sistema MUST manter, por tenant, um cadastro de setores com nome identificável e líder responsável (chefe de setor) quando designado.
- **FR-002**: O sistema MUST associar cada usuário autenticado do tenant a um ou mais setores de lotação ativos.
- **FR-003**: O sistema MUST permitir configurar, por módulo de negócio, zero ou mais setores autorizados; módulo sem setores vinculados permanece acessível a todos os usuários autenticados do tenant (salvo outras regras de perfil).
- **FR-004**: O sistema MUST avaliar permissão de módulo comparando os setores de lotação do usuário com os setores autorizados do módulo; correspondência em **qualquer** setor autorizado concede acesso.
- **FR-005**: O sistema MUST NOT ocultar itens de navegação de módulos por falta de permissão de setor; itens permanecem visíveis e o bloqueio ocorre ao tentar acessar o conteúdo.
- **FR-006**: O sistema MUST exibir tela de **403 · Acesso negado** quando usuário autenticado sem setor autorizado tenta acessar módulo restrito, contendo: nome do módulo, texto explicativo, lista de setores autorizados, líder(es) responsável(is) quando existir(em), ação **Voltar** e ação **Pedir permissão ao líder do setor**.
- **FR-007**: O sistema MUST registrar solicitação de permissão vinculada ao solicitante, módulo, setores alvo e timestamp, e notificar **todos os chefes** dos setores vinculados ao módulo.
- **FR-008**: O sistema MUST conceder acesso irrestrito a módulos de negócio ao administrador da plataforma do tenant, independentemente de vínculos setor–módulo.
- **FR-009**: O sistema MUST tratar os módulos Global e Tramitação como abertos a todos os usuários autenticados do tenant, sem exigência de vínculo setor–módulo.
- **FR-010**: O sistema MUST restringir gestão de vínculos módulo–setor e cadastro global de usuários/setores ao administrador da plataforma do tenant.
- **FR-011**: O sistema MUST permitir ao chefe de setor consultar membros e notificações (incluindo solicitações de permissão) apenas dos setores sob sua chefia.
- **FR-012**: O sistema MUST aplicar verificação de permissão por setor tanto na interface quanto nas operações protegidas do backend, de forma consistente — tentativa de operação sem permissão retorna negação equivalente ao bloqueio da interface.
- **FR-013**: O sistema MUST preservar autenticação e sessão existentes; esta feature estende autorização por setor sem substituir login ou hierarquia de papéis (usuário, chefe de setor, administrador da plataforma).
- **FR-014**: O sistema MUST isolar configurações de setores, usuários e vínculos por tenant — nenhum dado de permissão de um tenant influencia outro.
- **FR-015**: O sistema MUST conceder automaticamente todas as licenças do tenant (Carvalho, Pau-Brasil, Jatobá e Cedro) a todo usuário no momento da criação — controle de acesso a módulos de negócio é feito por setor, não por licença.
- **FR-016**: O sistema MUST NOT alterar vínculos setor–módulo ou setores de lotação do usuário automaticamente ao registrar uma solicitação de permissão; concessão de acesso permanece ação manual do chefe ou administrador fora desta feature.

### Key Entities

- **Setor**: Unidade organizacional do tenant; possui nome, estado ativo/inativo e chefe designado (usuário responsável pela chefia daquele setor).
- **Usuário**: Pessoa autenticada do tenant; possui e-mail, papel hierárquico, um ou mais setores de lotação, chefia sobre zero ou mais setores, todas as licenças do tenant e estado ativo/inativo.
- **Módulo de negócio**: Unidade funcional da plataforma (ex.: Protocolo Virtual, Jurídico, Global); identificador estável usado em navegação e autorização.
- **Vínculo módulo–setor**: Associação configurável entre um módulo de negócio e um ou mais setores autorizados; ausência de vínculos significa módulo aberto.
- **Solicitação de permissão**: Pedido de um usuário para acessar módulo restrito; referencia solicitante, módulo, setores alvo, data e estado (enviada/lida); não altera permissões automaticamente.
- **Notificação de chefia**: Alerta destinado ao chefe de setor, incluindo solicitações de acesso a módulos vinculados ao seu setor.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% das tentativas de acesso a módulo restrito por usuário cujos setores não intersectam os autorizados resultam em tela 403 padronizada — nunca em menu oculto ou erro genérico sem contexto.
- **SC-002**: Usuários com setor autorizado acessam o módulo correspondente na primeira tentativa em pelo menos 95% dos casos medidos em testes de aceitação.
- **SC-003**: Solicitações de permissão enviadas pela tela 403 chegam a todos os chefes responsáveis dos setores vinculados ao módulo em menos de 1 minuto em condições normais de operação.
- **SC-004**: Administrador da plataforma consegue configurar vínculos de todos os módulos de negócio do tenant em uma única sessão de até 15 minutos.
- **SC-005**: Redução de pelo menos 50% em pedidos informais de liberação de acesso (e-mail/chat) nos primeiros 30 dias após adoção, medida por amostragem com gestores piloto.
- **SC-006**: Zero casos em testes de aceitação em que usuário de tenant A visualiza setores, vínculos ou notificações de tenant B.

## Assumptions

- A hierarquia de papéis existente (usuário → chefe de setor → administrador da plataforma) permanece; permissão por setor complementa — não substitui — papéis administrativos.
- Cada usuário possui um ou mais setores de lotação ativos; alteração de lotação é feita pelo administrador da plataforma.
- Um módulo pode estar vinculado a múltiplos setores; basta o usuário pertencer a **qualquer** setor autorizado para obter acesso.
- Licenças Carvalho, Pau-Brasil, Jatobá e Cedro são **sempre** concedidas a todo usuário do tenant na criação; controle de acesso a módulos de negócio é exclusivamente por setor, não por licença.
- Global e Tramitação permanecem abertos a todos os usuários autenticados, alinhado ao comportamento já demonstrado no produto.
- Administração de plataforma permanece restrita por papel (chefe de setor ou administrador da plataforma), não por vínculo setor–módulo.
- Administrador da plataforma do tenant ignora restrições de setor para módulos de negócio.
- Aprovação formal da solicitação (conceder acesso alterando setores de lotação do usuário ou vínculo do módulo) é ação manual do chefe ou administrador — fora do escopo desta feature está workflow automatizado de aprovação/rejeição in-app.
- Os oito módulos de negócio canônicos do Controle Interno (Global, Ouvidoria, Jurídico, Protocolo Virtual, Patrimônio, Gabinete, Compras, Contratos) mais Tramitação e Administração compõem o universo de módulos sujeitos a esta regra.
- Copy de interface segue vocabulário normativo da plataforma: **403 · Acesso negado**, **Pedir permissão ao líder do setor**, **Setor(es) com acesso a este módulo**, **Líder responsável**.
