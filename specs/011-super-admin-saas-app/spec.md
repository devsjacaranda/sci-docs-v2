# Feature Specification: Super Admin SaaS App

**Feature Branch**: `011-super-admin-saas-app`

**Created**: 2026-06-23

**Status**: Draft

**Input**: User description: "Iniciar o super admin SaaS no monorepo — criar app separado para super admin com gerenciamento de admins da plataforma e gerenciamento de tenants (dados, licenças, setores, usuários). Login dedicado admin_saas sem tenant. Full-stack."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Login e shell do Super Admin (Priority: P1)

Como operador técnico da plataforma SaaS, preciso acessar um aplicativo dedicado, autenticar com e-mail e senha sem selecionar tenant, e ver um painel com navegação para as áreas de gestão, para operar a plataforma de forma segura e separada do app dos clientes.

**Why this priority**: Sem autenticação e shell navegável, nenhuma funcionalidade de gestão pode ser entregue; é o ponto de entrada obrigatório do produto SaaS.

**Independent Test**: Abrir o app super admin, fazer login com credenciais válidas de super admin e verificar redirecionamento para dashboard com menu de navegação (Admins, Tenants). Tentar acessar rota protegida sem login e confirmar redirecionamento para tela de login.

**Acceptance Scenarios**:

1. **Given** super admin não autenticado, **When** abre o app dedicado, **Then** é direcionado à tela de login sem campo ou seleção de tenant.
2. **Given** credenciais válidas de super admin ativo, **When** submete o formulário de login, **Then** autentica com sucesso e acessa o dashboard com navegação para Admins e Tenants.
3. **Given** credenciais inválidas ou super admin inativo, **When** submete o login, **Then** recebe mensagem de erro genérica sem revelar se o e-mail existe.
4. **Given** super admin autenticado, **When** tenta acessar rota protegida após logout ou expiração de sessão, **Then** é redirecionado à tela de login.
5. **Given** usuário com papel que não seja super admin, **When** tenta autenticar no app dedicado, **Then** o acesso é negado com mensagem clara.

---

### User Story 2 - Gerenciamento de super admins (Priority: P2)

Como super admin da plataforma, preciso listar, criar, editar e desativar outros super admins, redefinir senhas de colegas e alterar minha própria senha, para manter o time operacional da plataforma sem depender de acesso direto ao banco de dados.

**Why this priority**: A governança do próprio time SaaS é pré-requisito para operação segura; independe da gestão de tenants e entrega valor imediato ao time interno.

**Independent Test**: Autenticar como super admin, listar admins existentes, criar um novo, editar status, redefinir senha de outro admin e alterar a própria senha no perfil — tudo sem interagir com tenants.

**Acceptance Scenarios**:

1. **Given** super admin autenticado, **When** acessa a área de Admins, **Then** vê lista com e-mail e status (ativo/inativo) de cada super admin.
2. **Given** formulário de criação preenchido com e-mail único e senha válida, **When** confirma criação, **Then** novo super admin aparece na lista e pode autenticar no app dedicado.
3. **Given** super admin existente, **When** edita e-mail ou alterna status ativo/inativo, **Then** alterações persistem e refletem na listagem.
4. **Given** super admin autenticado, **When** redefine senha de outro super admin, **Then** o colega passa a autenticar com a nova senha; a senha nunca é exibida em texto claro após definição.
5. **Given** super admin autenticado, **When** altera a própria senha no perfil informando senha atual correta, **Then** passa a autenticar com a nova senha.
6. **Given** tentativa de desativar o único super admin ativo restante, **When** confirma a ação, **Then** operação é bloqueada com mensagem explicativa.

---

### User Story 3 - Gerenciamento de tenants — dados (Priority: P3)

Como super admin da plataforma, preciso listar, criar, visualizar e editar tenants (instituições clientes), incluindo nome, identificador único (slug) e status ativo/inativo, para provisionar e manter clientes na plataforma.

**Why this priority**: Tenants são a unidade central do modelo multi-tenant; sem CRUD de tenants, licenças, setores e usuários não têm contexto operacional.

**Independent Test**: Autenticar, listar tenants, criar um novo com slug único, visualizar detalhe, editar nome e desativar/reativar — sem alterar licenças, setores ou usuários.

**Acceptance Scenarios**:

1. **Given** super admin autenticado, **When** acessa a área de Tenants, **Then** vê lista com nome, slug e status de cada tenant.
2. **Given** formulário de criação com nome e slug únicos, **When** confirma criação, **Then** tenant aparece na lista com status ativo por padrão (ou conforme seleção inicial).
3. **Given** tenant existente, **When** abre detalhe, **Then** vê nome, slug, status e data de criação.
4. **Given** tenant existente, **When** edita nome ou slug (mantendo unicidade), **Then** alterações persistem e refletem na listagem e no detalhe.
5. **Given** tenant ativo, **When** desativa o tenant, **Then** status muda para inativo e usuários desse tenant não conseguem autenticar no app dos clientes.
6. **Given** slug já utilizado por outro tenant, **When** tenta criar ou editar com slug duplicado, **Then** recebe erro claro indicando conflito de identificador.

---

### User Story 4 - Licenças por tenant (Priority: P4)

Como super admin da plataforma, preciso visualizar e ativar/desativar as quatro licenças canônicas (Carvalho, Pau-Brasil, Jatobá, Cedro) de cada tenant, para controlar quais funcionalidades de produto o cliente pode acessar.

**Why this priority**: Licenças determinam o escopo funcional visível ao tenant; complementa o CRUD de tenants e é necessária antes de operação completa do cliente.

**Independent Test**: Selecionar um tenant, visualizar estado das quatro licenças, alternar uma licença e verificar que o estado persiste no detalhe do tenant.

**Acceptance Scenarios**:

1. **Given** detalhe de um tenant, **When** super admin acessa seção de licenças, **Then** vê as quatro licenças canônicas com status ativo/inativo e nomenclatura correta (Carvalho, Pau-Brasil, Jatobá, Cedro).
2. **Given** licença ativa de um tenant, **When** super admin desativa a licença, **Then** status muda para inativo e funcionalidades associadas àquela licença deixam de estar disponíveis para usuários daquele tenant no app cliente.
3. **Given** licença inativa, **When** super admin reativa, **Then** funcionalidades associadas voltam a estar disponíveis conforme regras de produto.
4. **Given** tenant recém-criado, **When** super admin visualiza licenças, **Then** encontra as quatro licenças registradas com estado inicial definido (ativas ou inativas conforme política de provisionamento).

---

### User Story 5 - Setores do tenant selecionado (Priority: P5)

Como super admin da plataforma, preciso gerenciar setores (unidades organizacionais) dentro de um tenant selecionado — listar, criar, editar e desativar — incluindo sigla, nome, chefe e módulos vinculados, para configurar a estrutura organizacional do cliente sem acessar o app tenant.

**Why this priority**: Setores são pré-requisito para permissões e operação dos usuários; paridade com gestão existente no app tenant, operada cross-tenant pelo super admin.

**Independent Test**: Selecionar tenant, listar setores, criar setor com sigla e nome, editar chefe e módulos, desativar setor — ciclo completo sem alterar usuários.

**Acceptance Scenarios**:

1. **Given** tenant selecionado, **When** super admin acessa setores do tenant, **Then** vê lista de setores com sigla, nome e status.
2. **Given** formulário de criação válido, **When** confirma novo setor, **Then** setor aparece na lista do tenant selecionado.
3. **Given** setor existente, **When** edita nome, sigla, chefe ou módulos vinculados, **Then** alterações persistem e refletem na listagem.
4. **Given** setor ativo, **When** desativa o setor, **Then** deixa de aparecer como opção ativa para novos vínculos; registros históricos permanecem consultáveis conforme política de soft delete.
5. **Given** nenhum tenant selecionado, **When** tenta acessar gestão de setores, **Then** sistema exige seleção explícita de tenant antes de exibir ou alterar dados.

---

### User Story 6 - Usuários do tenant selecionado (Priority: P6)

Como super admin da plataforma, preciso gerenciar usuários dentro de um tenant selecionado — listar, criar, editar, desativar e redefinir senhas — atribuindo papéis (usuário, chefe de setor, administrador da plataforma) e vínculos de setor, para provisionar equipes dos clientes.

**Why this priority**: Completa o ciclo de onboarding de um tenant (dados → licenças → estrutura → pessoas); permite operação autônoma da plataforma SaaS.

**Independent Test**: Selecionar tenant, listar usuários, criar usuário com papel e setores, editar, redefinir senha e desativar — ciclo completo.

**Acceptance Scenarios**:

1. **Given** tenant selecionado, **When** super admin acessa usuários do tenant, **Then** vê lista com nome, e-mail, papel e status de cada usuário.
2. **Given** formulário de criação com e-mail único no tenant, senha e papel válidos, **When** confirma criação, **Then** usuário aparece na lista e pode autenticar no app cliente daquele tenant.
3. **Given** usuário existente, **When** edita nome, papel ou vínculos de setor, **Then** alterações persistem e refletem na listagem e no detalhe.
4. **Given** usuário ativo, **When** super admin desativa o usuário, **Then** usuário não consegue autenticar no app cliente.
5. **Given** usuário existente, **When** super admin redefine senha, **Then** usuário passa a autenticar com nova senha; senha nunca exibida em texto claro.
6. **Given** e-mail já cadastrado no mesmo tenant, **When** tenta criar ou editar para e-mail duplicado, **Then** recebe erro claro de conflito.

---

### Edge Cases

- O que acontece quando super admin tenta autenticar no app cliente com credenciais SaaS? Acesso negado — credenciais SaaS são válidas apenas no app dedicado.
- O que acontece quando usuário tenant tenta autenticar no app super admin? Acesso negado — apenas super admins autenticam no app dedicado.
- Como o sistema trata slug de tenant duplicado na criação ou edição? Erro claro; operação não persiste.
- Como o sistema trata desativação do último super admin ativo? Operação bloqueada com mensagem explicativa.
- Como o sistema trata tenant desativado? Visível na listagem com indicador de status; usuários desse tenant não autenticam no app cliente.
- Como o sistema trata operações de setores/usuários sem tenant selecionado? Exige seleção explícita de tenant antes de exibir ou alterar dados.
- Como o sistema trata redefinição de senha? Exige confirmação da ação; senha nunca exibida em texto claro após definição.
- Como o sistema trata super admin editando a si mesmo? Pode alterar própria senha; desativar a si mesmo segue mesma regra de não deixar plataforma sem admin ativo.
- Como o sistema se comporta durante submissão de formulários? Botão desabilitado ou indicador de carregamento; feedback de sucesso ou erro ao concluir.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: O produto MUST disponibilizar aplicativo dedicado, separado do app dos clientes (tenant), exclusivo para super admins da plataforma SaaS.
- **FR-002**: O login do app dedicado MUST autenticar super admins por e-mail e senha sem exigir identificação ou seleção de tenant.
- **FR-003**: Apenas usuários com papel de super admin da plataforma MUST acessar o app dedicado; demais papéis MUST ser rejeitados.
- **FR-004**: Super admin autenticado MUST poder listar todos os super admins da plataforma com e-mail e status ativo/inativo.
- **FR-005**: Super admin autenticado MUST poder criar novo super admin informando e-mail único e senha inicial.
- **FR-006**: Super admin autenticado MUST poder editar e-mail e status (ativo/inativo) de outro super admin.
- **FR-007**: Super admin autenticado MUST poder redefinir senha de outro super admin, com confirmação da ação.
- **FR-008**: Super admin autenticado MUST poder alterar a própria senha no perfil, informando senha atual.
- **FR-009**: O sistema MUST impedir desativação do único super admin ativo restante.
- **FR-010**: Super admin autenticado MUST poder listar todos os tenants com nome, slug e status.
- **FR-011**: Super admin autenticado MUST poder criar tenant com nome e slug únicos.
- **FR-012**: Super admin autenticado MUST poder visualizar detalhe de um tenant (nome, slug, status, datas relevantes).
- **FR-013**: Super admin autenticado MUST poder editar nome, slug e status (ativar/desativar) de um tenant.
- **FR-014**: O sistema MUST rejeitar slug duplicado na criação ou edição de tenant com mensagem clara.
- **FR-015**: Tenant desativado MUST impedir autenticação de usuários desse tenant no app cliente.
- **FR-016**: No detalhe do tenant, super admin MUST visualizar as quatro licenças canônicas (Carvalho, Pau-Brasil, Jatobá, Cedro) com status ativo/inativo.
- **FR-017**: Super admin MUST poder ativar ou desativar cada licença individualmente por tenant.
- **FR-018**: Alteração de status de licença MUST refletir na disponibilidade das funcionalidades associadas para usuários daquele tenant no app cliente.
- **FR-019**: Gestão de setores MUST exigir tenant selecionado explicitamente.
- **FR-020**: Super admin MUST poder listar, criar, editar e desativar setores do tenant selecionado (sigla, nome, chefe, módulos vinculados).
- **FR-021**: Gestão de usuários MUST exigir tenant selecionado explicitamente.
- **FR-022**: Super admin MUST poder listar, criar, editar e desativar usuários do tenant selecionado.
- **FR-023**: Super admin MUST poder atribuir papéis de usuário, chefe de setor e administrador da plataforma a usuários do tenant.
- **FR-024**: Super admin MUST poder vincular usuários a setores e redefinir senha de usuários do tenant.
- **FR-025**: O sistema MUST rejeitar e-mail duplicado dentro do mesmo tenant com mensagem clara.
- **FR-026**: Senhas MUST ser armazenadas de forma segura e NUNCA exibidas em texto claro após definição.
- **FR-027**: Rotas e áreas protegidas MUST redirecionar usuários não autenticados para a tela de login.
- **FR-028**: O app tenant existente e suas telas de administração por tenant (administrador da plataforma) MUST permanecer inalterados em escopo e público-alvo.

### Key Entities *(include if feature involves data)*

- **Super Admin (AdminPlataforma)**: Operador técnico da plataforma SaaS; identificado por e-mail único; possui status ativo/inativo; autentica apenas no app dedicado.
- **Tenant**: Instituição cliente da plataforma; possui nome, slug único e status ativo/inativo; agrega licenças, setores e usuários.
- **Licença do Tenant**: Vínculo entre tenant e licença canônica (Carvalho, Pau-Brasil, Jatobá, Cedro); possui status ativo/inativo que controla funcionalidades disponíveis.
- **Setor**: Unidade organizacional dentro de um tenant; possui sigla, nome, chefe opcional e módulos vinculados.
- **Usuário do Tenant**: Servidor ou gestor vinculado a um tenant; possui e-mail único por tenant, nome, papel hierárquico e vínculos a setores.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Super admin completa login no app dedicado em menos de 30 segundos, sem etapa de seleção de tenant.
- **SC-002**: Super admin provisiona tenant completo (dados, quatro licenças, primeiro usuário administrador da plataforma) em menos de 5 minutos.
- **SC-003**: 100% das operações CRUD definidas nesta spec retornam feedback de sucesso ou erro compreensível ao operador.
- **SC-004**: Zero acesso ao app dedicado por usuários cujo papel não seja super admin da plataforma.
- **SC-005**: Super admin localiza e abre detalhe de qualquer tenant em no máximo 3 interações a partir do dashboard.
- **SC-006**: Após desativar tenant ou licença, usuários afetados percebem indisponibilidade correspondente na próxima tentativa de uso no app cliente.

## Assumptions

- O app dos clientes (tenant) e as telas de administração existentes para o papel administrador da plataforma permanecem dedicadas à gestão **dentro** de um tenant; não são substituídas pelo app super admin.
- O app super admin é implantável separadamente (URL ou porta distinta em desenvolvimento e produção).
- Vocabulário de licenças e nomenclatura de produto seguem documentação canônica de produto (Carvalho, Pau-Brasil, Jatobá, Cedro; Base não é licença).
- Copy e alertas de interface seguem regras normativas de produto da plataforma CI.
- Super admins são poucos operadores internos da equipe SaaS; não há self-service de registro público.
- Provisionamento inicial de tenant inclui registro das quatro licenças canônicas; super admin controla status ativo/inativo de cada uma.
- Paridade funcional de setores e usuários com gestão tenant-scoped existente, operada pelo super admin em contexto cross-tenant.
- **Fora de escopo v1**: impersonation (entrar como usuário tenant), billing/faturamento, métricas e analytics da plataforma, interface de audit log, SSO/OAuth externo, recuperação de senha por e-mail.
