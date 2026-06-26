# Feature Specification: Gerenciamento de Usuários e Setores — Gabinete

**Feature Branch**: `017-gabinete-usuarios-setores-crud`

**Created**: 2026-06-25

**Status**: Completed

**Input**: User description: "Criar telas completas no web para gerenciamento de usuário (ler, criar, atualizar, inativar acesso, resetar senha) e gerenciamento de setores (ler, criar, atualizar, inativar, restaurar). Ambos dentro das permissões do setor Gabinete, no agrupamento Gabinete, sem entrar nas estáticas das licenças. Componente compartilhado com telas de Plataforma; acesso Gabinete para membros do setor GAB + bypass admin_tenant e admin_plataforma."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Listar e buscar usuários no Gabinete (Priority: P1)

Como servidor autenticado com acesso ao módulo Gabinete (membro do setor Gabinete), preciso abrir a tela **Usuários** (`/gabinete/usuarios`) e ver a lista completa de servidores do meu órgão — com busca por nome ou e-mail e filtro por status (Ativos, Inativos, Todos) — para localizar rapidamente quem precisa de cadastro ou manutenção.

**Why this priority**: A listagem é o ponto de entrada de toda a gestão de pessoas; sem ela, criar e manter usuários não é operável.

**Independent Test**: Autenticar membro do setor Gabinete, navegar a `/gabinete/usuarios` em até três cliques; verificar título **Usuários**, campo de busca, filtro de status e tabela com nome, e-mail, setores vinculados, perfil (Servidor ou Chefe de setor) e status (Ativo ou Inativo).

**Acceptance Scenarios**:

1. **Given** usuário membro do setor Gabinete com acesso ao módulo, **When** acessa `/gabinete/usuarios`, **Then** vê listagem de usuários do tenant com busca e filtro **Ativos / Inativos / Todos**.
2. **Given** lista com usuários ativos e inativos, **When** filtra por **Ativos**, **Then** apenas usuários com acesso habilitado aparecem.
3. **Given** termo de busca digitado, **When** o usuário pesquisa por nome ou e-mail parcial, **Then** a lista filtra em tempo perceptível sem recarregar a página inteira.
4. **Given** tenant sem usuários além do operador, **When** a tela carrega, **Then** exibe estado vazio orientador com ação **Novo usuário** — **sem** dados de demonstração fixos quando integrado ao ambiente real.

---

### User Story 2 - CRUD completo de usuários (Priority: P1)

Como gestor do Gabinete, preciso **criar**, **editar**, **inativar**, **restaurar** e **resetar senha** de servidores do tenant, vinculando-os a um ou mais setores e definindo perfil **Servidor** ou **Chefe de setor**, para manter o quadro de pessoas alinhado à estrutura organizacional **sem** depender do administrador de plataforma legado.

**Why this priority**: É o núcleo operacional da feature — cadastro e ciclo de vida de contas de servidor.

**Independent Test**: Criar usuário novo com e-mail único, senha inicial e setor; editar nome e setores; inativar e confirmar que login falha; restaurar e confirmar que login volta a funcionar; resetar senha com nova credencial definida pelo gestor.

**Acceptance Scenarios**:

1. **Given** gestor autorizado na tela Usuários, **When** aciona **Novo usuário** e preenche e-mail, nome, senha inicial, pelo menos um setor e perfil **Servidor** ou **Chefe de setor**, **Then** o usuário é criado e aparece na listagem como **Ativo**.
2. **Given** usuário existente, **When** o gestor edita nome, e-mail, setores ou perfil, **Then** alterações persistem e refletem na listagem imediatamente após confirmação.
3. **Given** usuário ativo, **When** o gestor aciona **Inativar acesso**, **Then** o status passa a **Inativo** e o usuário **não consegue autenticar** — recebendo mensagem clara de acesso desabilitado.
4. **Given** usuário inativo, **When** o gestor aciona **Restaurar**, **Then** o status volta a **Ativo** e o usuário **pode autenticar** novamente.
5. **Given** usuário ativo, **When** o gestor aciona **Resetar senha** e informa nova senha, **Then** a credencial é atualizada **sem** exigir a senha anterior do alvo; o usuário autentica com a nova senha na próxima tentativa.
6. **Given** tentativa de criar usuário, **When** o e-mail já existe no tenant, **Then** o sistema impede duplicidade com mensagem clara — **sem** sobrescrever conta existente silenciosamente.
7. **Given** formulário de criação ou edição, **When** o gestor consulta opções de perfil, **Then** vê apenas **Servidor** e **Chefe de setor** — **nunca** opção de administrador de plataforma ou administrador institucional (`AdminTenant`).

---

### User Story 3 - Listar setores no Gabinete (Priority: P1)

Como gestor do Gabinete, preciso abrir a tela **Setores** (`/gabinete/setores`) e ver todos os setores do tenant — com sigla, nome, chefe designado, quantidade de membros e filtro por status (Ativos, Inativos, Todos) — para entender a estrutura organizacional antes de vincular usuários.

**Why this priority**: Setores são pré-requisito para vincular usuários; a listagem deve estar disponível no mesmo agrupamento Gabinete.

**Independent Test**: Autenticar membro GAB, navegar a `/gabinete/setores`; verificar colunas sigla, nome, chefe e contagem de membros; alternar filtro Ativos/Inativos.

**Acceptance Scenarios**:

1. **Given** usuário autorizado ao Gabinete, **When** acessa `/gabinete/setores`, **Then** vê listagem de setores com busca ou filtro de status **Ativos / Inativos / Todos**.
2. **Given** setor com chefe designado, **When** exibido na tabela, **Then** mostra nome do chefe; setor sem chefe exibe indicação clara (*Sem chefe designado* ou equivalente institucional).
3. **Given** setor inativo, **When** filtro **Inativos** está ativo, **Then** o setor aparece com status **Inativo**; **When** filtro **Ativos**, **Then** **não** aparece na lista padrão.

---

### User Story 4 - CRUD completo de setores (Priority: P2)

Como gestor do Gabinete, preciso **criar**, **editar**, **inativar** e **restaurar** setores informando sigla, nome e chefe opcional, para manter a estrutura organizacional do órgão atualizada.

**Why this priority**: Complementa a gestão de usuários; secundário à listagem e ao CRUD de pessoas, mas necessário para operação autônoma do Gabinete.

**Independent Test**: Criar setor com sigla e nome; editar chefe; inativar e verificar sumiço da lista ativa; restaurar e verificar retorno; tentar inativar setor com membros ativos e verificar comportamento documentado nos edge cases.

**Acceptance Scenarios**:

1. **Given** gestor autorizado, **When** aciona **Novo setor** e informa nome e sigla (chefe opcional), **Then** o setor é criado e aparece na listagem como **Ativo**.
2. **Given** setor existente, **When** o gestor edita nome, sigla ou chefe, **Then** alterações persistem e refletem na listagem.
3. **Given** setor ativo, **When** o gestor aciona **Inativar**, **Then** o setor passa a **Inativo**, some da listagem de ativos e **não** pode ser selecionado em novos vínculos de usuário.
4. **Given** setor inativo, **When** o gestor aciona **Restaurar**, **Then** o setor volta a **Ativo** e reaparece na listagem de ativos.
5. **Given** tentativa de criar setor, **When** sigla duplicada no tenant (política institucional), **Then** o sistema impede com mensagem clara.

---

### User Story 5 - Paridade com telas de Plataforma (Priority: P2)

Como administrador institucional (`admin_plataforma` ou `admin_tenant`), preciso acessar as mesmas funcionalidades de usuários e setores nas rotas existentes de **Administração → Plataforma** (`/administracao/plataforma/usuarios` e `/administracao/plataforma/setores`), com a **mesma experiência visual e operacional** das telas do Gabinete, para que admins institucionais e gestores do Gabinete operem sobre a mesma base de dados sem duplicar manutenção de interface.

**Why this priority**: Decisão de produto — componente compartilhado; garante consistência entre dois pontos de entrada com regras de acesso distintas.

**Independent Test**: Autenticar como `admin_plataforma`; abrir `/administracao/plataforma/usuarios` e `/administracao/plataforma/setores`; executar criar/editar/inativar/restaurar e confirmar paridade de campos e ações com as telas Gabinete.

**Acceptance Scenarios**:

1. **Given** administrador institucional autorizado, **When** acessa `/administracao/plataforma/usuarios`, **Then** vê o mesmo painel de gestão de usuários disponível em `/gabinete/usuarios` — mesmas colunas, filtros e ações.
2. **Given** administrador institucional autorizado, **When** acessa `/administracao/plataforma/setores`, **Then** vê o mesmo painel de gestão de setores disponível em `/gabinete/setores`.
3. **Given** alteração feita via rota Plataforma, **When** gestor Gabinete abre a rota Gabinete, **Then** vê os mesmos dados atualizados — uma única fonte de verdade por tenant.

---

### User Story 6 - Navegação e ausência de licenças premium (Priority: P2)

Como usuário do sistema, preciso encontrar **Usuários** e **Setores** dentro do agrupamento **Gabinete** na seção **Administração** da sidebar, e **não** ver cards ou estatísticas condicionadas às licenças Carvalho, Pau-Brasil, Jatobá ou Cedro nessas telas, pois são funcionalidades de **Base** — núcleo operacional sempre presente.

**Why this priority**: Posicionamento de produto e separação Base vs licenças; evita confusão com funcionalidades premium.

**Independent Test**: Abrir sidebar → Administração → Gabinete → subseção **Gestão institucional** (ou equivalente); acessar Usuários e Setores; confirmar ausência de badges/stats de licenças e que filtro global de licença **não** oculta essas telas.

**Acceptance Scenarios**:

1. **Given** sidebar expandida, **When** o usuário localiza o grupo Gabinete em Administração, **Then** encontra entradas **Usuários** e **Setores** agrupadas (subseção **Gestão institucional** ou equivalente).
2. **Given** telas de Usuários ou Setores (Gabinete ou Plataforma), **When** carregam, **Then** **não** exibem cards de maturidade, insights, fiscalização ou outros elementos exclusivos de licenças premium.
3. **Given** filtro global de licença ativo no tenant (ex.: ocultar funcionalidades Cedro), **When** o usuário acessa Usuários ou Setores, **Then** as telas permanecem acessíveis e visíveis — **fora** do escopo do filtro de licenças.

---

### User Story 7 - Controle de acesso e 403 padronizado (Priority: P3)

Como administrador de governança, preciso que apenas quem tem permissão legítima acesse as telas de gestão — membro do setor Gabinete com módulo, ou administrador institucional — e que demais usuários recebam **403 · Acesso negado** com copy institucional padronizada.

**Why this priority**: Segurança e separação de papéis; bloqueador para produção, mas secundário à entrega funcional do CRUD.

**Independent Test**: Autenticar usuário de setor sem vínculo ao módulo Gabinete; tentar `/gabinete/usuarios` e `/gabinete/setores`; verificar 403. Repetir para usuário sem `admin_plataforma`/`admin_tenant` em rotas Plataforma.

**Acceptance Scenarios**:

1. **Given** usuário **sem** membro do setor Gabinete **e sem** bypass institucional, **When** tenta acessar `/gabinete/usuarios` ou `/gabinete/setores`, **Then** recebe **403 · Acesso negado** com copy padronizada — itens podem permanecer visíveis na navegação Gabinete.
2. **Given** membro do setor Gabinete vinculado ao módulo Gabinete, **When** acessa rotas Gabinete, **Then** acesso permitido **independente** de licenças premium.
3. **Given** `admin_tenant` ou `admin_plataforma`, **When** acessa rotas Gabinete **ou** Plataforma, **Then** acesso permitido (bypass).
4. **Given** usuário sem perfil Plataforma, **When** tenta `/administracao/plataforma/usuarios`, **Then** recebe **403 · Acesso negado**.

---

### Edge Cases

- Gestor tenta **inativar a si mesmo**: ação **bloqueada** com mensagem clara — operador não pode remover o próprio acesso.
- Gestor tenta **inativar o único administrador institucional** restante com bypass: ação **bloqueada** ou exige confirmação reforçada conforme política — tenant **nunca** fica sem admin bypass involuntariamente.
- Usuário inativo com sessão aberta: na próxima requisição autenticada ou tentativa de renovação, acesso **negado** — sessão **não** permanece válida indefinidamente.
- Setor inativo com membros ainda vinculados: membros **permanecem** vinculados historicamente; setor **não** aparece para **novos** vínculos; edição de usuário existente **não** pode adicionar setor inativo.
- Chefe designado de setor é inativado: setor exibe chefe como indisponível ou exige redesignação na próxima edição — **sem** erro silencioso na listagem.
- E-mail duplicado no tenant (ativo ou inativo): criação **impedida**; restaurar usuário inativo com e-mail conflitante **impedido** até resolver conflito.
- Sigla de setor duplicada: criação/edição **impedida** com mensagem clara.
- Listagem vazia após filtro: estado vazio contextual (*Nenhum usuário inativo encontrado*) — **não** confundir com erro de carregamento.
- Operação em rede instável: mensagem de falha clara; dados **não** exibem sucesso falso — listagem permanece consistente com último estado confirmado pelo servidor.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: O sistema **DEVE** disponibilizar tela **Usuários** em `/gabinete/usuarios` dentro do agrupamento Gabinete na seção Administração da navegação.
- **FR-002**: O sistema **DEVE** disponibilizar tela **Setores** em `/gabinete/setores` dentro do agrupamento Gabinete na seção Administração da navegação.
- **FR-003**: Telas de Usuários e Setores (Gabinete e Plataforma) **DEVEM** pertencer exclusivamente à camada **Base** — **NUNCA** exibir stats, badges ou cards condicionados às licenças Carvalho, Pau-Brasil, Jatobá ou Cedro; **NUNCA** ser ocultadas pelo filtro global de licenças.
- **FR-004**: O sistema **DEVE** reutilizar a **mesma experiência de interface** (componente compartilhado) nas rotas Gabinete e Plataforma, diferenciando apenas regras de acesso por rota.
- **FR-005**: Acesso às rotas `/gabinete/usuarios` e `/gabinete/setores` **DEVE** ser permitido a: (a) membros do setor vinculado ao módulo Gabinete; (b) `admin_tenant`; (c) `admin_plataforma`.
- **FR-006**: Acesso às rotas `/administracao/plataforma/usuarios` e `/administracao/plataforma/setores` **DEVE** ser permitido a `admin_tenant` e `admin_plataforma`.
- **FR-007**: Usuários sem permissão **DEVEM** receber **403 · Acesso negado** com copy institucional padronizada; itens de navegação **PODEM** permanecer visíveis.
- **FR-008**: Listagem de usuários **DEVE** suportar busca por nome ou e-mail e filtro **Ativos / Inativos / Todos**.
- **FR-009**: Criação de usuário **DEVE** exigir e-mail único no tenant, nome, senha inicial, pelo menos um setor ativo e perfil **Servidor** (`user`) ou **Chefe de setor** (`chefe_setor`).
- **FR-010**: Criação e edição de usuário **NUNCA DEVEM** permitir perfil `admin_plataforma` nem gerenciar contas `AdminTenant`.
- **FR-011**: Edição de usuário **DEVE** permitir alterar nome, e-mail, setores vinculados e perfil (Servidor ou Chefe de setor).
- **FR-012**: Inativar usuário **DEVE** desabilitar autenticação; restaurar **DEVE** reabilitar autenticação.
- **FR-013**: Resetar senha **DEVE** ser ação dedicada que define nova credencial **sem** exigir senha anterior do usuário alvo.
- **FR-014**: O sistema **NÃO DEVE** expor ação genérica "resetar" além de **resetar senha** — inativar/restaurar cobrem o ciclo de acesso.
- **FR-015**: Listagem de setores **DEVE** suportar filtro **Ativos / Inativos / Todos** e exibir sigla, nome, chefe (se houver) e quantidade de membros.
- **FR-016**: Criação de setor **DEVE** exigir nome e sigla; chefe **PODE** ser opcional.
- **FR-017**: Inativar setor **DEVE** ocultá-lo da listagem de ativos e impedir seleção em novos vínculos de usuário; restaurar **DEVE** reverter inativação.
- **FR-018**: Inativar e restaurar usuário e setor **DEVEM** ser operações explícitas na interface — copy **Inativar** / **Restaurar**, **nunca** "Excluir" como termo principal.
- **FR-019**: O sistema **DEVE** impedir que o operador inative a **própria** conta.
- **FR-020**: O sistema **DEVE** impedir inativação que deixe o tenant **sem** administrador institucional com bypass (`admin_tenant` ou `admin_plataforma`).
- **FR-021**: Dados de usuários e setores **DEVEM** ser escopo de **tenant** — gestor vê e altera **somente** registros do próprio órgão.
- **FR-022**: Vínculos módulo×setor **PERMANECEM** fora desta feature — gerenciados em telas existentes de Plataforma (`admin-vinculos`).

### Key Entities

- **Usuário (User)**: Servidor ou chefe de setor do tenant. Atributos visíveis: nome, e-mail, perfil (Servidor ou Chefe de setor), setores vinculados, status (Ativo/Inativo). Relaciona-se a um ou mais setores.
- **Setor**: Unidade organizacional do tenant. Atributos: sigla, nome, chefe opcional (referência a usuário), contagem de membros, status (Ativo/Inativo). Relaciona-se a usuários via vínculo membro-setor.
- **Permissão de acesso (Gabinete)**: Critério derivado de membro do setor vinculado ao módulo Gabinete, com bypass para administradores institucionais — distinto de licenças premium.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Gestor do Gabinete completa cadastro de novo servidor (criar usuário com setor e senha inicial) em **menos de 3 minutos** em teste moderado com usuário treinado.
- **SC-002**: **100%** das ações CRUD confirmadas pelo servidor (criar, editar, inativar, restaurar, resetar senha) refletem na listagem em **até 2 segundos perceptíveis** após confirmação.
- **SC-003**: Usuário inativado que tenta login recebe feedback claro de acesso desabilitado em **100%** das tentativas — **nunca** autentica com sucesso.
- **SC-004**: Usuário restaurado autentica com sucesso na **primeira** tentativa após restauração, usando credencial válida (existente ou recém-resetada).
- **SC-005**: **Zero** telas desta feature exibem badges, cards ou estatísticas de licenças Carvalho, Pau-Brasil, Jatobá ou Cedro em auditoria de interface.
- **SC-006**: Paridade visual entre rotas Gabinete e Plataforma: **mesmas** colunas, filtros e ações principais verificáveis por checklist de QA em ambas as rotas.

## Assumptions

- Campos de usuário alinhados ao modelo operacional atual: e-mail, nome, perfil, setores vinculados; campo **cargo** permanece apenas na interface até existir no domínio persistente.
- Inativação de usuário e setor equivale a desativação lógica (registro permanece recuperável via **Restaurar**).
- Administradores institucionais (`admin_tenant`, `admin_plataforma`) mantêm bypass total às telas Gabinete e Plataforma desta feature.
- Copy em português brasileiro, tom institucional acessível, conforme regras de plataforma.
- Telas existentes em Plataforma (`PlatformUsersPanel`, `PlatformSectorsPanel`) servem como base visual; esta feature exige comportamento de **produção** completo (inativar, restaurar, resetar senha via servidor real — não apenas estado local ou senha fixa de demonstração).
- Seed de tenant demo (ex.: Jacaranda) inclui setor Gabinete (GAB) vinculado ao módulo — ambiente de teste independente disponível.

## Out of Scope

- CRUD de contas **AdminTenant** (administrador institucional canônico).
- Criação, promoção ou gestão de usuários com perfil **admin_plataforma** (legado).
- Gestão de vínculos **módulo × setor** (permanece em `admin-vinculos` / Plataforma).
- Telas no aplicativo **admin-saas** (super admin SaaS).
- Importação em massa de usuários ou setores (CSV, LDAP, Active Directory).
- Auditoria detalhada de quem alterou cada registro (log de admin) — pode ser feature futura.
- Autogestão de perfil pelo próprio usuário (permanece em **Meu perfil**).
- Ação "resetar" genérica além de **resetar senha** e ciclo inativar/restaurar.

## Dependencies

- Módulo de autenticação tenant existente (login com e-mail/senha e escopo por tenant).
- Modelo de permissão módulo↔setor existente (membro do setor Gabinete obtém acesso ao módulo Gabinete).
- Telas parciais de Plataforma e endpoints tenant de setores/usuários existentes — esta feature completa lacunas de autorização, ciclo de vida e paridade Gabinete.
