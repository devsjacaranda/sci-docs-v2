# Feature Specification: Sistema de PermissÃ£o de Telas e De-mock NavegaÃ§Ã£o

**Feature Branch**: `032-permission-screen-visibility`

**Created**: 2026-07-02

**Status**: Completed

**Input**: Desenvolver sistema de permissÃ£o granular por tela, de-mockar a tela "Telas e agrupamentos", completar CRUD de membros do setor, e integrar tudo com API real.

## User Scenarios & Testing

### User Story 1 â€” Admin configura visibilidade de telas por setor (Priority: P1)

O admin do tenant (admin_tenant ou admin_plataforma) acessa a tela "Telas e agrupamentos" em `/administracao/plataforma/navegacao`. Ao selecionar um setor, vÃª a grade com todas as telas do sistema organizadas por seÃ§Ã£o (AdministraÃ§Ã£o, GestÃ£o, SaÃºde). Pode ativar ou desativar telas individualmente para aquele setor. As alteraÃ§Ãµes sÃ£o persistidas imediatamente via API.

**Why this priority**: Ã‰ o core da feature â€” sem o cadastro setorÃ—tela, as demais funcionalidades (overrides, conflitos) nÃ£o existem.

**Independent Test**: Pode ser testado criando um setor, configurando telas, e verificando que a sidebar do usuÃ¡rio vinculado reflete a configuraÃ§Ã£o.

**Acceptance Scenarios**:

1. **Given** um admin_tenant logado, **When** acessa "Telas e agrupamentos" e seleciona o setor OUV, **Then** vÃª a grade com todas as telas do sistema, com os olhos indicando quais estÃ£o habilitadas para o setor.
2. **Given** um setor sem configuraÃ§Ã£o prÃ©via, **When** o admin seleciona "Ouvidoria", **Then** o setor herda as telas dos mÃ³dulos vinculados (ModuloSetor) como baseline.
3. **Given** o admin habilita a tela "Contratos" para o setor OUV, **When** a alteraÃ§Ã£o Ã© salva, **Then** a API persiste o vÃ­nculo SetorTela e retorna 200.
4. **Given** o admin desabilita uma tela para o setor, **When** um usuÃ¡rio desse setor faz login, **Then** a tela nÃ£o aparece na sidebar dele.

---

### User Story 2 â€” Admin gerencia exceÃ§Ãµes por usuÃ¡rio (Priority: P1)

ApÃ³s configurar a visibilidade por setor, o admin pode alternar para o modo "Por usuÃ¡rio" e ver conflitos: telas que o usuÃ¡rio enxerga mas o setor nÃ£o cadastrou (exceeds_sector), ou telas que o setor cadastrou mas o usuÃ¡rio nÃ£o tem permissÃ£o base (below_sector). O admin confirma exceÃ§Ãµes individualmente ou em lote. ExceÃ§Ãµes sÃ£o persistidas como overrides no banco.

**Why this priority**: ExceÃ§Ãµes por usuÃ¡rio sÃ£o essenciais em instituiÃ§Ãµes reais â€” chefes veem telas que servidores nÃ£o veem, assessores especiais tÃªm acessos atÃ­picos.

**Independent Test**: Selecionar um usuÃ¡rio com conflitos, confirmar exceÃ§Ãµes, verificar persistÃªncia e que a sidebar reflete o override.

**Acceptance Scenarios**:

1. **Given** Maria (admin plataforma, OUV+GAB) selecionada no modo "Por usuÃ¡rio", **When** o sistema detecta 5 telas que ela vÃª e o setor nÃ£o cadastrou, **Then** aparece banner de conflitos + diÃ¡logo com a lista de divergÃªncias.
2. **Given** o admin confirma um override "exceeds_sector" para a tela "Auditoria" do usuÃ¡rio Maria, **When** a API persiste, **Then** o badge "ExceÃ§Ã£o" aparece permanentemente no nome de Maria na lista.
3. **Given** o admin confirma um override "below_sector" (libera tela extra), **When** o usuÃ¡rio faz login, **Then** a tela aparece na sidebar dele.
4. **Given** o admin quer RESTRINGIR â€” tirar uma tela que o setor daria ao usuÃ¡rio, **When** cria um override tipo "restrict", **Then** o usuÃ¡rio nÃ£o vÃª a tela mesmo que o setor a tenha.
5. **Given** exceÃ§Ãµes confirmadas, **When** o admin seleciona outro usuÃ¡rio e volta, **Then** as exceÃ§Ãµes anteriores permanecem persistidas.

---

### User Story 3 â€” CatÃ¡logo de telas na API (Priority: P1)

A API expÃµe um endpoint `GET /screens` que retorna o catÃ¡logo de telas conhecidas (id, tÃ­tulo, mÃ³dulo, seÃ§Ã£o). O client registra/sincroniza suas telas no boot ou seed. Isso permite que `SetorTela` e `UserTelaOverride` referenciem screenIds vÃ¡lidos.

**Why this priority**: PrÃ©-requisito para as Stories 1 e 2 â€” sem catÃ¡logo, a API nÃ£o pode validar os screenIds recebidos.

**Independent Test**: Chamar `GET /screens` e verificar que retorna todas as telas esperadas com metadados corretos.

**Acceptance Scenarios**:

1. **Given** a API rodando com seed, **When** chamo `GET /screens`, **Then** recebo lista com todas as telas registradas (id, title, module, section).
2. **Given** um screenId invÃ¡lido enviado em `PUT /setores/:id/telas`, **When** a API valida, **Then** retorna 400 com detalhes do screenId invÃ¡lido.
3. **Given** o client faz boot, **When** carrega a tela "Telas e agrupamentos", **Then** usa o catÃ¡logo da API para montar a grade (nÃ£o mais de `screens.ts` local para metadados de visibilidade).

---

### User Story 4 â€” CRUD completo de membros do setor (Priority: P2)

O chefe do setor ou admin acessa "Membros do Setor" em `/administracao/membros`. Pode vincular um usuÃ¡rio existente ao setor, desvincular, criar novo usuÃ¡rio jÃ¡ vinculado, e editar dados do membro. Tudo via API real, removendo o estado mock local.

**Why this priority**: A tela jÃ¡ existe com leitura via API; falta completar a escrita. Ã‰ dependÃªncia direta para a visibilidade â€” vincular um membro a um setor define quais telas ele pode ver.

**Independent Test**: Vincular um usuÃ¡rio a um setor e verificar que `GET /setores/:id/membros` retorna o novo membro; desvincular e verificar remoÃ§Ã£o.

**Acceptance Scenarios**:

1. **Given** chefe do setor GAB acessa "Membros do Setor", **When** clica "Adicionar membro" e seleciona um usuÃ¡rio existente, **Then** a API cria UserSetor e o membro aparece na lista.
2. **Given** chefe do setor GAB, **When** clica "Criar novo usuÃ¡rio" preenche nome/email/cargo, **Then** a API cria User + UserSetor e o membro aparece na lista.
3. **Given** chefe do setor GAB com membro "Roberto", **When** clica "Desvincular", **Then** a API deleta UserSetor (nÃ£o deleta o User) e Roberto some da lista.
4. **Given** admin_plataforma acessa "Membros do Setor", **When** seleciona qualquer setor, **Then** pode gerenciar membros de todos os setores (nÃ£o restrito a setores que chefia).
5. **Given** chefe do setor OUV, **When** tenta acessar membros do setor GAB, **Then** recebe 403.

---

### User Story 5 â€” Sidebar reflete permissÃµes reais (Priority: P2)

Quando o usuÃ¡rio faz login, a sidebar exibe apenas telas que ele pode ver, calculadas a partir de: (1) telas cadastradas nos setores vinculados, (2) overrides individuais, (3) role hierarchy. MÃ³dulos abertos (global, tramitaÃ§Ã£o) permanecem visÃ­veis para todos.

**Why this priority**: Ã‰ o efeito visÃ­vel de toda a configuraÃ§Ã£o â€” o usuÃ¡rio final vÃª a sidebar correta.

**Independent Test**: Logar com diferentes perfis e verificar que a sidebar mostra exatamente as telas configuradas.

**Acceptance Scenarios**:

1. **Given** setor OUV com telas de Ouvidoria habilitadas, **When** Carlos (ouvidor, setor OUV) faz login, **Then** sidebar mostra: mÃ³dulos abertos (global, tramitaÃ§Ã£o) + telas de Ouvidoria + telas de chefia (admin-membros, admin-notificacoes).
2. **Given** Roberto (assessor GAB, sem chefia) com override "restrict" na tela "Demandas Gabinete", **When** faz login, **Then** nÃ£o vÃª "Demandas Gabinete" na sidebar.
3. **Given** Maria (admin plataforma), **When** faz login, **Then** vÃª todas as telas (admin plataforma bypassa restriÃ§Ãµes de setor).

---

### User Story 6 â€” DiagnÃ³stico de visibilidade no painel (Priority: P3)

O painel "Telas e agrupamentos" exibe contadores e indicadores visuais: quantas telas o setor/usuÃ¡rio vÃª, quantos conflitos pendentes, quais telas tÃªm exceÃ§Ã£o confirmada. Serve como ferramenta de auditoria para o admin entender o estado atual das permissÃµes.

**Why this priority**: UX de qualidade para o admin; nÃ£o bloqueia funcionalidade core.

**Independent Test**: Selecionar um usuÃ¡rio com exceÃ§Ãµes e verificar badges, contadores e hints.

**Acceptance Scenarios**:

1. **Given** setor OUV com 45/83 telas habilitadas, **When** selecionado no modo "Por setor", **Then** a grade mostra contadores corretos e telas desabilitadas em opacidade reduzida.
2. **Given** Maria com 3 exceÃ§Ãµes confirmadas, **When** selecionada no modo "Por usuÃ¡rio", **Then** nome dela tem badge "ExceÃ§Ã£o", telas com override tÃªm indicador visual diferenciado (ring teal).
3. **Given** Paulo com 2 conflitos pendentes, **When** selecionado, **Then** banner "2 conflito(s)" aparece com botÃ£o "Revisar conflitos".

---

### Edge Cases

- **Setor sem mÃ³dulos vinculados**: SetorTela fica vazio; usuÃ¡rios do setor sÃ³ veem mÃ³dulos abertos (global, tramitaÃ§Ã£o).
- **UsuÃ¡rio em mÃºltiplos setores**: Visibilidade Ã© a UNIÃƒO das telas de todos os setores + overrides individuais.
- **UsuÃ¡rio inativo**: NÃ£o aparece na seleÃ§Ã£o; sidebar ignorada; overrides preservados para reativaÃ§Ã£o.
- **Admin_tenant Ã© ator (nÃ£o Ã© User)**: FK para User Ã© nullable; resolver via `resolveUserTableId()` em campos `createdByUserId`.
- **Tela removida do catÃ¡logo (deploy)**: SetorTela e overrides com screenId Ã³rfÃ£o sÃ£o ignorados (soft cleanup).
- **Chefe de setor removido**: Perde acesso ao CRUD de membros do seu setor; overrides dele como alvo permanecem.
- **Conflito em lote**: Admin importa configuraÃ§Ã£o de setor e mÃºltiplos usuÃ¡rios ganham conflitos simultaneamente.

## Requirements

### Functional Requirements

**CatÃ¡logo de telas (API)**

- **FR-001**: Sistema DEVE expor endpoint `GET /screens` que retorna o catÃ¡logo completo de telas registradas com id, tÃ­tulo, mÃ³dulo e seÃ§Ã£o.
- **FR-002**: Sistema DEVE permitir que o client sincronize telas via seed ou endpoint de registro, garantindo que screenIds usados em SetorTela e UserTelaOverride sejam vÃ¡lidos.
- **FR-003**: Sistema DEVE rejeitar (400) operaÃ§Ãµes de visibilidade com screenIds nÃ£o registrados no catÃ¡logo.

**Visibilidade por setor (SetorTela)**

- **FR-004**: Sistema DEVE permitir que admin_tenant ou admin_plataforma configure quais telas cada setor pode ver, persistindo em tabela SetorTela.
- **FR-005**: Sistema DEVE expor endpoint `GET /setores/:id/telas` que retorna a lista de screenIds habilitados para o setor.
- **FR-006**: Sistema DEVE expor endpoint `PUT /setores/:id/telas` que substitui a configuraÃ§Ã£o de telas do setor (lista de screenIds).
- **FR-007**: Quando um setor nÃ£o tem configuraÃ§Ã£o de telas, sistema DEVE derivar uma baseline a partir dos mÃ³dulos vinculados (ModuloSetor â†’ telas dos mÃ³dulos).

**ExceÃ§Ãµes por usuÃ¡rio (UserTelaOverride)**

- **FR-008**: Sistema DEVE permitir que admin crie overrides por usuÃ¡rio â€” tanto para LIBERAR (grant) quanto para RESTRINGIR (deny) acesso a telas especÃ­ficas.
- **FR-009**: Sistema DEVE expor endpoint `GET /users/:id/tela-overrides` que retorna a lista de overrides do usuÃ¡rio.
- **FR-010**: Sistema DEVE expor endpoint `PUT /users/:id/tela-overrides` que substitui os overrides do usuÃ¡rio (lista de {screenId, kind: 'grant' | 'deny'}).
- **FR-011**: Sistema DEVE detectar conflitos entre visibilidade do usuÃ¡rio (derivada de role + setores) e cadastro SetorTela, retornando-os no endpoint `GET /users/:id/tela-conflicts`.

**Visibilidade efetiva (sidebar)**

- **FR-012**: Sistema DEVE expor endpoint `GET /me/screens` que retorna a lista de telas visÃ­veis para o usuÃ¡rio autenticado, calculada como: UNIÃƒO(telas dos setores do usuÃ¡rio) + overrides grant - overrides deny + mÃ³dulos abertos.
- **FR-013**: Admin_plataforma e admin_tenant DEVEM ver todas as telas (bypass de restriÃ§Ãµes de setor).
- **FR-014**: MÃ³dulos abertos (global, tramitaÃ§Ã£o) DEVEM ser visÃ­veis para todos os usuÃ¡rios independente de SetorTela.

**CRUD de membros**

- **FR-015**: Sistema DEVE expor endpoint `POST /setores/:id/membros` para vincular usuÃ¡rio existente ao setor (criar UserSetor).
- **FR-016**: Sistema DEVE expor endpoint `DELETE /setores/:id/membros/:userId` para desvincular usuÃ¡rio do setor (remover UserSetor, sem deletar User).
- **FR-017**: Sistema DEVE expor endpoint `POST /setores/:id/membros/create-user` para criar novo usuÃ¡rio jÃ¡ vinculado ao setor (User + UserSetor).
- **FR-018**: Endpoints de membros DEVEM ser acessÃ­veis por chefe do setor (chiefOfSetorIds) OU admin_plataforma/admin_tenant.
- **FR-019**: Chefe do setor DEVE ser restrito aos setores que chefia; admin pode gerenciar qualquer setor.

**AutorizaÃ§Ã£o**

- **FR-020**: Tela "Telas e agrupamentos" DEVE ser acessÃ­vel apenas por admin_tenant ou admin_plataforma.
- **FR-021**: Tela "Membros do Setor" DEVE ser acessÃ­vel por chefe de setor, admin_tenant ou admin_plataforma.
- **FR-022**: Toda operaÃ§Ã£o de escrita DEVE auditar o ator (userId + role) via `resolveUserTableId` e `withActorPayload` conforme regra admin-tenant-user-fk.

### Key Entities

- **Screen (catÃ¡logo)**: Registro de tela conhecida pelo sistema â€” id (slug), tÃ­tulo, mÃ³dulo, seÃ§Ã£o. Fonte de verdade para validaÃ§Ã£o de screenIds.
- **SetorTela**: VÃ­nculo N:N entre Setor e Screen â€” representa quais telas o setor pode ver. Se vazio, usa baseline de ModuloSetor.
- **UserTelaOverride**: ExceÃ§Ã£o individual â€” {userId, screenId, kind: 'grant' | 'deny'}. Override Ã© aplicado SOBRE a visibilidade derivada do setor.
- **UserSetor**: VÃ­nculo N:N existente entre User e Setor â€” base para cÃ¡lculo de visibilidade.
- **ModuloSetor**: VÃ­nculo existente entre mÃ³dulo e setor â€” usado para derivar baseline de telas quando SetorTela estÃ¡ vazio.

## Success Criteria

### Measurable Outcomes

- **SC-001**: Admin configura visibilidade de telas de um setor em menos de 1 minuto (selecionar setor, toggle telas, salvar).
- **SC-002**: Conflitos entre usuÃ¡rio e setor sÃ£o detectados e apresentados em menos de 2 segundos apÃ³s seleÃ§Ã£o do usuÃ¡rio.
- **SC-003**: Sidebar do usuÃ¡rio reflete corretamente as permissÃµes configuradas sem necessidade de limpar cache â€” login retorna telas atualizadas.
- **SC-004**: 100% dos dados mock (platformUsersSeed, adminSectors, sectorMembersSeed, moduleSectorLinks) sÃ£o substituÃ­dos por chamadas API reais.
- **SC-005**: CRUD de membros (vincular, desvincular, criar vinculado) funciona via API real com persistÃªncia no banco.
- **SC-006**: Nenhum usuÃ¡rio sem setor vÃª telas alÃ©m dos mÃ³dulos abertos (global, tramitaÃ§Ã£o) e telas administrativas permitidas pelo seu role.
- **SC-007**: Todas as operaÃ§Ãµes de escrita registram auditoria com ator correto (admin_tenant resolve para nullable FK).

## Assumptions

- CatÃ¡logo de telas Ã© finito (~80-100 telas) e muda apenas em deploys â€” pode ser cacheado agressivamente.
- MÃ³dulos abertos (global, tramitaÃ§Ã£o) sÃ£o constantes do sistema, nÃ£o configurÃ¡veis por tenant.
- A hierarquia de roles existente (user < chefe_setor < admin_plataforma) Ã© mantida; esta feature NÃƒO introduz roles novos.
- Admin_tenant e admin_plataforma tÃªm poder equivalente na configuraÃ§Ã£o de visibilidade dentro do tenant.
- O `SectorMembersPanel` existente jÃ¡ tem UI funcional; apenas a camada de dados precisa ser substituÃ­da (mock â†’ API).
- Overrides de usuÃ¡rio sÃ£o gerenciados pelo admin, nÃ£o pelo prÃ³prio usuÃ¡rio.
- Soft delete de setor/user preserva SetorTela e overrides (para possÃ­vel reativaÃ§Ã£o).
- O `UserSectorConflictDialog` existente no client pode ser reutilizado/evoluÃ­do para a versÃ£o real.
