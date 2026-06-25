# Feature Specification: Sessão inválida sem logout e tratamento de erros

**Feature Branch**: `013-auth-session-logout`

**Created**: 2026-06-24

**Status**: Draft

**Input**: User description: "Bug auth — token invalidando e não desloga da conta. O sistema deve ter tratamento de erros forte no app tenant (@ci/web). Quando token expira, credencial é rejeitada ou comunicação com o servidor falha, o usuário deve ser deslogado, redirecionado ao login com mensagem, e erros não devem deixar a interface em estado inconsistente nem derrubar o serviço de backend tenant."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Sessão inválida encerra o acesso (Priority: P1)

Como servidor ou gestor autenticado no app tenant, preciso que, quando minha sessão deixar de ser válida (token expirado ou credencial rejeitada pelo servidor), o sistema me deslogue automaticamente e me leve de volta ao login com uma mensagem clara, para não continuar navegando achando que ainda estou autenticado.

**Why this priority**: É o núcleo do bug reportado — sessão inválida sem logout gera telas quebradas, dados ausentes e sensação de falha do produto.

**Independent Test**: Autenticar no app tenant, invalidar a sessão (expiração simulada ou credencial rejeitada) e acionar qualquer tela protegida; verificar logout, redirect para login, mensagem **"Sessão expirada. Entre novamente."** e preservação da rota de origem para retorno pós-login.

**Acceptance Scenarios**:

1. **Given** usuário logado em rota protegida, **When** o servidor rejeita a credencial por sessão inválida, **Then** o token local é removido, o estado de autenticação passa a falso e o usuário é redirecionado para a tela de login.
2. **Given** redirect por sessão inválida, **When** a tela de login é exibida, **Then** o usuário vê a mensagem **"Sessão expirada. Entre novamente."** de forma visível no card de login.
3. **Given** usuário deslogado por sessão inválida a partir de uma rota interna, **When** faz login com credenciais válidas, **Then** é redirecionado de volta à rota de origem quando aplicável.
4. **Given** usuário logado, **When** tenta acessar rota protegida após logout forçado, **Then** não acessa conteúdo autenticado sem novo login.

---

### User Story 2 - Falha de comunicação encerra a sessão (Priority: P1)

Como usuário do app tenant, preciso que falhas de comunicação com o servidor (indisponibilidade, conexão recusada ou interrupção durante a requisição) encerrem minha sessão local e me levem ao login com orientação clara, para não ficar preso em telas que falham silenciosamente.

**Why this priority**: Erros de rede ou queda do serviço hoje deixam token ativo e geram falhas não tratadas na interface — mesmo sintoma percebido pelo usuário que sessão inválida.

**Independent Test**: Com usuário autenticado, simular indisponibilidade do servidor durante uma ação em tela protegida (ex.: listagem ou cadastro); verificar logout, redirect ao login e mensagem orientando novo acesso.

**Acceptance Scenarios**:

1. **Given** usuário logado, **When** uma requisição autenticada falha por indisponibilidade do servidor ou erro de rede, **Then** a sessão local é encerrada e o usuário é redirecionado para login.
2. **Given** redirect por falha de comunicação, **When** a tela de login é exibida, **Then** o usuário vê mensagem clara (ex.: **"Não foi possível manter sua sessão. Entre novamente."**) sem jargão técnico.
3. **Given** falha de comunicação durante carregamento de página, **When** o logout automático ocorre, **Then** não há erro não tratado visível no console que interrompa a experiência do usuário.

---

### User Story 3 - Operações tenant não são interrompidas por auditoria (Priority: P1)

Como administrador institucional ou servidor que executa alterações no sistema, preciso que minhas ações (criar, editar, excluir) concluam com sucesso mesmo quando o registro de auditoria não puder ser gravado, para que o serviço continue disponível e previsível.

**Why this priority**: Falhas na gravação de auditoria estão derrubando o serviço tenant e provocando cascata de erros no app — bloqueio crítico de uso real.

**Independent Test**: Autenticar como administrador institucional do tenant, executar mutações repetidas em módulos tenant (ex.: gabinete) e verificar que todas concluem, o serviço permanece ativo e requisições subsequentes respondem normalmente.

**Acceptance Scenarios**:

1. **Given** usuário autenticado como administrador institucional do tenant, **When** executa uma operação de alteração de dados, **Then** a operação de negócio conclui com sucesso independentemente de quem assina a sessão (servidor ou admin institucional).
2. **Given** falha ao registrar auditoria de uma mutação, **When** a operação principal já foi concluída, **Then** o serviço tenant continua respondendo e não encerra o processo por causa da auditoria.
3. **Given** dez mutações consecutivas por administrador institucional, **When** todas são executadas, **Then** o serviço permanece disponível para novas requisições autenticadas.

---

### User Story 4 - Erros recuperáveis com feedback padronizado (Priority: P2)

Como usuário do app tenant, preciso ver feedback consistente quando uma operação falha por motivo recuperável (validação, limite de uso, permissão insuficiente sem invalidar sessão), para entender o que aconteceu sem tela em branco ou falha silenciosa.

**Why this priority**: Complementa o logout automático — nem todo erro deve deslogar; erros de negócio precisam de tratamento transversal e previsível.

**Independent Test**: Provocar erro recuperável (ex.: validação ou limite) em telas de ouvidoria/gabinete e verificar mensagem padronizada ao usuário, sem logout e sem promise não tratada.

**Acceptance Scenarios**:

1. **Given** usuário autenticado com sessão válida, **When** uma operação retorna erro de validação ou limite de uso, **Then** o usuário permanece logado e vê mensagem de erro compreensível.
2. **Given** usuário sem permissão para módulo (acesso negado por regra de setor ou licença), **When** tenta acessar conteúdo restrito, **Then** vê tela ou mensagem de acesso negado **sem** ser deslogado.
3. **Given** qualquer tela do app tenant que consome dados remotos, **When** ocorre erro recuperável, **Then** a interface não fica em estado indefinido (loading infinito ou conteúdo vazio sem explicação).

---

### User Story 5 - Estado autenticado coerente (Priority: P3)

Como usuário do app tenant, preciso que o indicador de “estou logado” reflita a realidade após falha de validação da sessão, para que rotas protegidas e menus não me enganem com acesso aparente.

**Why this priority**: Corrige inconsistência onde token armazenado localmente mantém `isAuthenticated` verdadeiro mesmo sem usuário válido carregado.

**Independent Test**: Invalidar sessão, recarregar app tenant e tentar navegar — `RequireAuth` e menus devem tratar usuário como não autenticado até novo login bem-sucedido.

**Acceptance Scenarios**:

1. **Given** token local removido ou invalidado, **When** o app avalia autenticação, **Then** rotas protegidas redirecionam ao login.
2. **Given** falha ao carregar perfil do usuário na abertura do app, **When** a sessão não pôde ser validada, **Then** o usuário não é considerado autenticado apenas por existir token residual.

---

### Edge Cases

- Múltiplas abas abertas: logout em uma aba invalida sessão nas demais na próxima requisição autenticada.
- Requisições paralelas com sessão inválida: logout e redirect ocorrem uma única vez, sem loop de redirecionamento.
- Tela de login exibindo mensagem de sessão encerrada e usuário submetendo credenciais válidas: mensagem de sessão some ou é substituída pelo resultado do login.
- Modo de demonstração local sem servidor remoto: comportamento mock existente permanece inalterado.
- Erro de acesso negado por setor ou licença (403): **não** deslogar — distinguir claramente de sessão inválida (401) e de falha de rede.
- Administrador institucional vs servidor comum: ambos devem ter sessão encerrada pelas mesmas regras de invalidação; auditoria não deve assumir que todo ator autenticado é um “servidor” cadastrado na mesma tabela.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: O app tenant MUST encerrar a sessão local quando o servidor rejeitar a credencial por sessão inválida ou expirada.
- **FR-002**: O app tenant MUST encerrar a sessão local quando uma requisição autenticada falhar por indisponibilidade do servidor ou erro de comunicação.
- **FR-003**: Após encerramento automático de sessão, o usuário MUST ser redirecionado para a tela de login com mensagem visível — **"Sessão expirada. Entre novamente."** para credencial inválida, ou equivalente claro para falha de comunicação.
- **FR-004**: O redirect pós-logout MUST preservar a rota de origem para retorno após login bem-sucedido, quando aplicável.
- **FR-005**: Erros de acesso negado por permissão de módulo, setor ou licença MUST NOT encerrar a sessão — MUST exibir fluxo de acesso negado existente.
- **FR-006**: Registro de auditoria de mutações tenant MUST NOT impedir a conclusão da operação de negócio quando o ator autenticado não corresponder ao modelo de “servidor” usado historicamente na trilha de auditoria.
- **FR-007**: Falhas ao gravar auditoria MUST ser isoladas — MUST NOT encerrar o serviço tenant nem tornar o sistema indisponível para outros usuários.
- **FR-008**: Todas as telas do app tenant que consomem dados remotos MUST tratar erros sem deixar promises não tratadas que quebrem a experiência (sem falhas silenciosas no fluxo principal).
- **FR-009**: Erros recuperáveis (validação, limites, conflitos de negócio) MUST exibir feedback padronizado ao usuário, mantendo a sessão ativa.
- **FR-010**: Mensagens em falhas de segurança MUST ser genéricas — MUST NOT revelar se credencial, e-mail ou token específico existe ou é válido.
- **FR-011**: O estado “autenticado” exibido ao usuário MUST refletir validação real da sessão — token armazenado localmente sozinho MUST NOT manter acesso a rotas protegidas após falha de validação.

### Key Entities

- **Sessão tenant**: Credencial local associada ao usuário autenticado no app institucional; pode ser invalidada por expiração, rejeição pelo servidor ou falha de comunicação.
- **Registro de auditoria**: Trilha de mutações no tenant, vinculada opcionalmente ao ator que executou a ação; falha na gravação não deve bloquear a operação principal.
- **Mensagem de sessão encerrada**: Feedback exibido na tela de login informando que o usuário deve entrar novamente, com copy distinta para credencial inválida vs falha de comunicação.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% dos cenários testados de sessão inválida redirecionam o usuário ao login em até 2 segundos, com mensagem visível na tela de login.
- **SC-002**: Zero ocorrências de falhas não tratadas no fluxo principal em cenários reproduzidos de gabinete (controle numérico, autos de infração) e validação inicial de sessão ao abrir o app.
- **SC-003**: Dez mutações consecutivas autenticadas como administrador institucional do tenant concluem sem indisponibilizar o serviço para requisições seguintes.
- **SC-004**: Após logout forçado (sessão inválida ou falha de comunicação), 100% das tentativas de acessar rotas protegidas sem novo login resultam em redirect ao login.
- **SC-005**: Em erros recuperáveis testados (validação, limite, acesso negado por setor), 100% mantêm o usuário logado e exibem feedback compreensível.

## Assumptions

- Escopo limitado ao app tenant institucional e aos endpoints de backend que esse app consome; o app super admin SaaS fica fora desta entrega.
- Login por e-mail e senha com sessão baseada em credencial emitida pelo servidor tenant permanece o mecanismo atual — sem novos métodos de autenticação.
- A tela de login existente (spec 010) será reutilizada para exibir mensagens de sessão encerrada, sem redesign visual nesta entrega.
- Modo mock local (`VITE_USE_API=false`) preserva fluxos de demonstração atuais; regras de logout automático aplicam-se quando o app opera contra servidor remoto.
- Erros HTTP 403 por licença ou setor continuam no fluxo de acesso negado já existente, distinto do encerramento de sessão.
- Detalhes de implementação (interceptores, hooks, contratos de API) serão definidos na fase de plano técnico (`/speckit-plan`).

## Out of Scope

- App super admin SaaS (`@ci/admin-saas`) — logout, toast e tratamento de erros desse app.
- Novos métodos de autenticação (SSO, MFA, certificado digital).
- Refresh token ou renovação silenciosa de sessão sem interação do usuário.
- Redesign visual da tela de login além da exibição de mensagens de sessão encerrada.
- Política de retenção ou visualização histórica de registros de auditoria para o usuário final.
- Alteração de regras de permissão por setor ou licença — apenas distinção de quando deslogar vs exibir acesso negado.
