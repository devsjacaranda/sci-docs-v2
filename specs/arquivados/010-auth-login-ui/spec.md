# Feature Specification: Novo layout UI/UX de login (auth)

**Feature Branch**: `010-auth-login-ui`

**Created**: 2026-06-23

**Status**: Completed

**Input**: User description: "Criar UI/UX layout novo do CI v2 para o módulo auth. Redesenhar a tela de login aproximada ao v1 (login.tsx de referência), mantendo layout separado com fundo quadriculado, logo ci-logo.ico, paleta Mint do CI v2. Escopo: somente login — sem contas de demonstração, sem links de registro, esqueci senha ou política de privacidade."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Login com nova identidade visual (Priority: P1)

Como servidor ou gestor público, preciso acessar a tela de login e reconhecer imediatamente o produto Controle Interno, com apresentação institucional profissional, para confiar que estou no sistema correto antes de inserir minhas credenciais.

**Why this priority**: É a primeira impressão do produto e o ponto de entrada obrigatório; sem identidade visual clara, usuários hesitam ou confundem ambientes.

**Independent Test**: Abrir `/login` sem estar autenticado e verificar layout split (branding + formulário), fundo quadriculado, logo, título "CONTROLE INTERNO", tagline institucional, badge de versão e fluxo de login funcional com redirecionamento após credenciais válidas.

**Acceptance Scenarios**:

1. **Given** usuário não autenticado, **When** abre `/login`, **Then** vê layout responsivo em duas áreas: branding à esquerda (em telas grandes) e formulário em card à direita.
2. **Given** viewport desktop, **When** a página carrega, **Then** o fundo exibe padrão quadriculado sutil sobre a base de cores Mint, legível nos modos claro e escuro.
3. **Given** área de branding, **When** o usuário lê o conteúdo, **Then** vê o logo do Controle Interno, o título **CONTROLE INTERNO**, a tagline **Gestão pública moderna, transparente e eficiente.** e um indicador de versão do sistema.
4. **Given** formulário preenchido com credenciais válidas, **When** submete, **Then** autentica com sucesso e redireciona para a rota de origem ou destino padrão após login — preservando o comportamento atual de autenticação.
5. **Given** credenciais inválidas ou usuário inativo, **When** submete, **Then** uma mensagem de erro clara permanece visível no card do formulário, sem expor detalhes sensíveis de segurança.

---

### User Story 2 - Formulário acessível e validado (Priority: P2)

Como usuário que acessa o sistema diariamente, preciso de um formulário de login com validação imediata, toggle de visibilidade da senha e navegação por teclado, para entrar com rapidez e confiança sem erros evitáveis.

**Why this priority**: Validação e acessibilidade reduzem fricção e erros de digitação; complementam o layout sem alterar a lógica de autenticação.

**Independent Test**: Carregar `/login`, verificar foco inicial no e-mail, alternar visibilidade da senha, tentar enviar com campos vazios ou e-mail malformado e confirmar feedback inline antes do envio; navegar por Tab e verificar ordem e estados de foco.

**Acceptance Scenarios**:

1. **Given** página de login carregada, **When** o usuário interage pela primeira vez, **Then** o foco inicial está no campo de e-mail institucional.
2. **Given** senha digitada, **When** o usuário aciona o controle de visibilidade, **Then** a senha alterna entre oculta e visível, com rótulo acessível que descreve a ação.
3. **Given** e-mail vazio, formato inválido ou senha vazia, **When** o usuário tenta enviar, **Then** feedback inline impede ou sinaliza o erro antes ou no momento do envio — **sem** depender exclusivamente de notificações flutuantes.
4. **Given** navegação por teclado, **When** o usuário percorre os campos e o botão de envio, **Then** a ordem de foco é lógica e os estados de foco são claramente visíveis.

---

### User Story 3 - Responsividade em dispositivos móveis (Priority: P3)

Como servidor que acessa o sistema pelo celular ou tablet, preciso que a tela de login se adapte a telas menores sem perder identidade nem usabilidade, para autenticar em qualquer dispositivo.

**Why this priority**: Acesso móvel é comum em órgãos públicos; garante inclusão sem bloquear a entrega principal do P1.

**Independent Test**: Abrir `/login` em viewport abaixo do breakpoint desktop e verificar branding compacto acima do card, formulário utilizável e ausência de scroll horizontal.

**Acceptance Scenarios**:

1. **Given** viewport menor que telas desktop, **When** o usuário abre `/login`, **Then** branding compacto (logo e título) aparece acima do card de formulário.
2. **Given** dispositivo móvel, **When** o usuário interage com campos e botão, **Then** áreas clicáveis respeitam alvo mínimo de aproximadamente 44×44 pixels.
3. **Given** viewport entre 320px e 1920px de largura, **When** a página é exibida, **Then** não há scroll horizontal indesejado e o conteúdo permanece legível.

---

### Edge Cases

- O que acontece quando o usuário já está autenticado e acessa `/login`? Deve redirecionar para o destino padrão ou rota de origem, como hoje.
- Como o sistema trata tentativa de login com e-mail válido mas usuário inativo ou inexistente? Mensagem genérica de falha, sem revelar se o e-mail existe.
- Como a tela se comporta durante o envio do formulário? Botão desabilitado ou indicador de carregamento; campos não editáveis enquanto processa.
- Como o layout se adapta quando o teclado virtual ocupa metade da tela no mobile? Formulário permanece acessível com scroll vertical se necessário.
- O que acontece se a versão do sistema não estiver configurada? Badge de versão oculto ou exibe fallback neutro (ex.: "Versão —") — **nunca** quebra o layout.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: A tela de login MUST apresentar layout híbrido: fundo quadriculado em tela cheia + divisão branding à esquerda / formulário em card à direita em telas grandes.
- **FR-002**: A área de branding MUST exibir o logo institucional do Controle Interno, o título **CONTROLE INTERNO** e a tagline **Gestão pública moderna, transparente e eficiente.**
- **FR-003**: A área de branding MUST exibir indicador de versão do sistema quando a versão estiver disponível na configuração do produto.
- **FR-004**: O formulário MUST conter campos de e-mail institucional e senha, com controle para alternar visibilidade da senha.
- **FR-005**: O sistema MUST validar campos obrigatórios e formato de e-mail antes ou no momento do envio, exibindo feedback inline no card.
- **FR-006**: A paleta visual MUST seguir a identidade Mint do CI v2 (modo claro e escuro), com contraste adequado para texto e ações primárias.
- **FR-007**: O comportamento de autenticação MUST permanecer equivalente ao atual: login por e-mail e senha, redirecionamento pós-sucesso para rota de origem ou destino padrão.
- **FR-008**: Em caso de falha de autenticação, o sistema MUST exibir mensagem de erro clara no card, sem expor se o e-mail existe ou qual campo falhou por razões de segurança.
- **FR-009**: A interface MUST NOT exibir seção de contas de demonstração, links de registro, esqueci senha ou política de privacidade nesta entrega.
- **FR-010**: Copy de mock ou instruções de ambiente simulado (ex.: "qualquer senha não vazia", "Sistema V2 · Mockdown") MUST ser removida e substituída por copy institucional genérica.

### Key Entities

- **Sessão de login**: Tentativa de autenticação com e-mail institucional e senha; resulta em acesso concedido (redirecionamento) ou mensagem de erro.
- **Identidade visual de auth**: Conjunto de elementos de marca na tela pública de login — logo, título, tagline, versão e fundo quadriculado — independente da lógica de credenciais.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Usuários com credenciais válidas completam o login em menos de 30 segundos na primeira tentativa, medido em teste moderado com participantes representativos.
- **SC-002**: Layout permanece legível e utilizável em viewports de 320px a 1920px de largura, sem scroll horizontal obrigatório para concluir o login.
- **SC-003**: Contraste de texto principal e botão de ação primária atende WCAG AA nos modos claro e escuro.
- **SC-004**: 100% dos fluxos de erro atuais de autenticação (credenciais inválidas, usuário inativo) permanecem funcionais após o redesign visual.
- **SC-005**: Pelo menos 90% dos participantes de teste de usabilidade identificam corretamente o produto como "Controle Interno" ao ver apenas a tela de login por 5 segundos.

## Assumptions

- A versão exibida na tela provém de configuração existente do produto (equivalente ao indicador de versão do v1).
- O logo institucional (`ci-logo.ico`) está disponível como ativo estático servido pela aplicação.
- A lógica de autenticação (mock local ou API com token) permanece inalterada; apenas a camada de apresentação é redesenhada.
- Modo claro e escuro seguem o comportamento já suportado pela aplicação; a tela de login respeita a preferência ativa do usuário.
- Validação de senha no cliente segue regras mínimas já adotadas pelo produto (campo obrigatório; demais regras de negócio permanecem no backend quando API ativa).
- Testes automatizados e detalhes de componentização serão definidos na fase de plano técnico (`/speckit-plan`).

## Out of Scope

- Página de registro de novos usuários.
- Fluxo de recuperação de senha ("Esqueci senha").
- Página ou link de política de privacidade.
- Seção "Contas de demonstração" com cards clicáveis.
- Alterações no backend de autenticação ou contratos de API.
- Novos métodos de autenticação (SSO, MFA, certificado digital).
- Tela de primeiro acesso ou onboarding pós-login.
