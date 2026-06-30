# Feature Specification: Identidade visual do tenant (foto e banner)

**Feature Branch**: `025-tenant-branding-config`

**Created**: 2026-06-29

**Status**: Draft

**Input**: User description: "administracao/plataforma/config — colocar o foto de perfil e banner do tenant; criar api e frontend"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Administrador configura a identidade institucional (Priority: P1)

Como administrador da plataforma do tenant, preciso acessar **Configurações da instituição** em `/administracao/plataforma/config` para enviar, visualizar e salvar a **foto de perfil institucional** (logotipo ou brasão) e o **banner** da minha instituição, para que a plataforma reflita a identidade visual oficial do órgão.

**Why this priority**: Sem esta capacidade, a identidade do tenant permanece genérica ou hardcoded; é o núcleo funcional pedido e desbloqueia personalização institucional centralizada.

**Independent Test**: Autenticar como administrador da plataforma do tenant, abrir a tela de configuração, enviar uma foto e um banner válidos, salvar e verificar que ambos aparecem na pré-visualização da mesma tela após recarregar.

**Acceptance Scenarios**:

1. **Given** um administrador da plataforma autenticado no tenant, **When** acessa `/administracao/plataforma/config`, **Then** vê a configuração atual da instituição (foto e banner existentes ou estado vazio com orientação para envio).
2. **Given** a tela de configuração aberta, **When** o administrador seleciona uma imagem JPEG ou PNG dentro do limite de tamanho para a foto institucional, **Then** vê pré-visualização imediata antes de confirmar o envio.
3. **Given** a tela de configuração aberta, **When** o administrador seleciona uma imagem JPEG ou PNG dentro do limite de tamanho para o banner, **Then** vê pré-visualização imediata antes de confirmar o envio.
4. **Given** foto e banner válidos selecionados, **When** o administrador confirma o salvamento, **Then** recebe confirmação de sucesso e as imagens permanecem associadas ao tenant após recarregar a página.
5. **Given** um usuário sem perfil de administrador da plataforma, **When** tenta acessar `/administracao/plataforma/config`, **Then** vê mensagem de acesso negado e não consegue alterar as imagens.

---

### User Story 2 - Usuários veem a identidade do tenant na experiência global (Priority: P1)

Como servidor ou gestor autenticado no tenant, preciso ver a foto institucional e o banner configurados pelo administrador na área de boas-vindas global, para reconhecer imediatamente em qual instituição estou operando.

**Why this priority**: A configuração só gera valor quando visível no produto; hoje a identidade aparece com imagens fixas de demonstração.

**Independent Test**: Com foto e banner já configurados para o tenant, autenticar como qualquer usuário ativo do mesmo tenant, abrir a tela global de boas-vindas e verificar exibição das imagens institucionais junto ao nome do tenant.

**Acceptance Scenarios**:

1. **Given** tenant com foto e banner configurados, **When** um usuário autenticado abre a tela global de boas-vindas, **Then** vê o banner institucional e a foto de perfil do tenant (não imagens genéricas de demonstração).
2. **Given** tenant sem foto ou banner configurados, **When** um usuário autenticado abre a tela global de boas-vindas, **Then** vê fallback visual coerente (nome da instituição e placeholder neutro) sem quebra de layout.
3. **Given** administrador alterou foto ou banner, **When** usuário recarrega a tela global de boas-vindas, **Then** vê a identidade atualizada.

---

### User Story 3 - Administrador substitui ou remove imagens (Priority: P2)

Como administrador da plataforma do tenant, preciso substituir ou remover a foto institucional e o banner quando a identidade visual mudar, para manter a plataforma alinhada à comunicação oficial do órgão.

**Why this priority**: Manutenção contínua da identidade visual; complementa o cadastro inicial sem bloquear o MVP.

**Independent Test**: Com imagens já configuradas, substituir apenas o banner, remover a foto institucional e verificar estados distintos na configuração e na tela global.

**Acceptance Scenarios**:

1. **Given** tenant com foto institucional existente, **When** o administrador envia uma nova foto válida, **Then** a imagem anterior deixa de ser exibida e a nova passa a valer em configuração e boas-vindas.
2. **Given** tenant com banner existente, **When** o administrador remove o banner, **Then** a tela global de boas-vindas exibe fallback neutro no lugar do banner removido.
3. **Given** tenant com foto institucional existente, **When** o administrador remove a foto, **Then** a tela global exibe placeholder com iniciais ou símbolo neutro derivado do nome da instituição.

---

### Edge Cases

- O que acontece quando o administrador tenta enviar arquivo que não seja JPEG ou PNG? O sistema rejeita com mensagem clara e não altera a imagem atual.
- O que acontece quando o arquivo excede o tamanho máximo permitido? O sistema informa o limite e não inicia o envio.
- O que acontece quando o envio é interrompido (rede ou cancelamento)? A imagem anterior permanece; o usuário vê erro compreensível e pode tentar novamente.
- O que acontece quando dois administradores alteram a identidade em sequência? A última alteração confirmada prevalece para todos os usuários.
- O que acontece quando usuário de outro tenant acessa dados da instituição? Nunca vê nem altera identidade visual de tenant diferente do seu.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: O sistema DEVE disponibilizar a tela **Configurações da instituição** em `/administracao/plataforma/config`, acessível somente a administradores da plataforma do tenant.
- **FR-002**: O sistema DEVE permitir que o administrador da plataforma envie uma **foto de perfil institucional** (logotipo ou brasão) por tenant.
- **FR-003**: O sistema DEVE permitir que o administrador da plataforma envie um **banner institucional** por tenant.
- **FR-004**: O sistema DEVE aceitar somente imagens nos formatos **JPEG** e **PNG** para foto e banner.
- **FR-005**: O sistema DEVE impor limite máximo de **5 MB** para a foto institucional e **10 MB** para o banner, rejeitando arquivos maiores com mensagem clara.
- **FR-006**: O sistema DEVE exibir pré-visualização das imagens selecionadas na tela de configuração antes da confirmação final.
- **FR-007**: O sistema DEVE persistir foto e banner associados exclusivamente ao tenant autenticado.
- **FR-008**: O sistema DEVE permitir substituir foto ou banner existentes por novas imagens válidas.
- **FR-009**: O sistema DEVE permitir remover foto institucional ou banner, retornando ao estado vazio com fallback visual adequado.
- **FR-009a**: O sistema DEVE expor a identidade visual configurada para leitura por todos os usuários autenticados do mesmo tenant (sem expor dados de outros tenants).
- **FR-010**: A tela global de boas-vindas DEVE exibir banner e foto institucional do tenant quando configurados, substituindo imagens fixas de demonstração.
- **FR-011**: Usuários sem perfil de administrador da plataforma NUNCA DEVEM conseguir alterar foto ou banner institucional.
- **FR-012**: Mensagens de sucesso e erro na configuração DEVEM ser compreensíveis, sem jargão técnico (ex.: **"Identidade visual atualizada."**, **"Apenas arquivos JPEG ou PNG são permitidos."**).

### Key Entities

- **Tenant (instituição)**: Órgão cliente da plataforma; possui nome oficial e, opcionalmente, foto institucional e banner de identidade visual.
- **Identidade visual do tenant**: Conjunto da foto institucional e do banner associados a um tenant; visível para usuários do tenant; editável apenas pelo administrador da plataforma.
- **Administrador da plataforma**: Perfil institucional responsável por setores, usuários e configurações do tenant (distinto de **Meu perfil**, que trata dados pessoais do usuário logado).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Administrador da plataforma consegue configurar foto e banner institucionais em uma única sessão de até **5 minutos**, incluindo pré-visualização e confirmação.
- **SC-002**: **100%** dos usuários autenticados do tenant veem a identidade visual configurada na tela global de boas-vindas após publicação (ou fallback neutro quando não houver imagem).
- **SC-003**: **95%** das tentativas de envio com arquivos válidos (formato e tamanho corretos) concluem com confirmação de sucesso percebida pelo administrador na primeira tentativa.
- **SC-004**: Tentativas de acesso à configuração por usuários sem perfil de administrador da plataforma resultam em **0%** de alterações bem-sucedidas de identidade visual.
- **SC-005**: Após alteração da identidade, usuários do tenant passam a ver a versão atualizada na tela global de boas-vindas sem necessidade de novo login.

## Assumptions

- **Escopo de ator**: Apenas **administrador da plataforma do tenant** edita identidade visual; super admin SaaS (`@ci/admin-saas`) fica fora do escopo desta spec (gestão de tenants permanece no app SaaS sem esta tela).
- **Distinção de perfis**: **Meu perfil** (`/administracao/plataforma/perfil`) continua tratando dados pessoais do usuário; esta feature trata identidade da **instituição**, não do indivíduo.
- **Formatos e limites**: JPEG/PNG e limites de 5 MB (foto) e 10 MB (banner) seguem padrão já adotado para foto de perfil pessoal na plataforma.
- **Exibição inicial**: A tela global de boas-vindas é o primeiro ponto de consumo da identidade; outros pontos do shell podem reutilizar os mesmos dados em fases posteriores sem expandir escopo agora.
- **Fallback visual**: Sem foto configurada, exibir iniciais ou placeholder neutro derivado do nome da instituição; sem banner, exibir faixa neutra sem imagem quebrada.
- **Dependência**: Reutiliza capacidade existente de armazenamento seguro de imagens por tenant (mesmo modelo conceitual já usado para anexos e avatar pessoal), sem duplicar regras de isolamento multi-tenant.
- **Navegação**: Novo item **Configurações** (ou equivalente) no grupo **Administrador Plataforma**, junto a Setores, Usuários e Meu perfil.
