# Feature Specification: Níveis de Acesso Ouvidoria AGEMAN (403)

**Feature Branch**: `047-acesso-ouvidoria-ageman`

**Created**: 2026-09-16

**Status**: Draft

**Input**: User description: "tipo: feat / titulo: implementar niveis de acesso ouvidoria ageman - 403 / contexto: Ao realizar o login, cada usuário visualize somente os registros e informações correspondentes ao seu perfil. Não exibir dados de outros usuários. Usuário não deverá precisar selecionar manualmente o emissor e não alterar essa informação para outro usuário. Porém: eu não quero que nada fique invisível a um usuário que não tem permissão, e sim apenas receba que não tem acesso 403; chefes da ouvidoria conseguem ver todos; todos os admins podem ver todos; vai ser possível permitir um acesso a um outro usuário a uuid em 403; vai exibir todos quem tem acesso."

## Clarifications

### Session 2026-09-15/16

- Q: O que define o "dono" de uma demanda interna da Ouvidoria para fins de visibilidade? → A: Apenas o campo `emissorUserId` — já reflete quem criou o registro, graças à regra automática já implementada (spec 044); não é preciso combinar com o campo de criador.
- Q: Demandas vindas do canal público (cidadão), sem emissor institucional, entram na regra de "só o dono vê"? → A: Não. Continuam visíveis a qualquer usuário que já tenha o módulo Ouvidoria liberado — a nova restrição de "dono" vale apenas para demandas internas registradas por um operador (com `emissorUserId` preenchido).
- Q: Como identificar um "chefe da ouvidoria" que vê tudo? → A: Usuário com role `chefe_setor` cujo(s) setor(es) (via `chiefOfSetorIds`) estejam vinculados ao módulo `ouvidoria` — sem criar uma role nova no enum `UserRole`.
- Q: Quem pode conceder acesso extra (grant) a um registro que não é seu? → A: O próprio emissor (dono do registro), qualquer chefe da ouvidoria, ou qualquer admin (`admin_tenant`, `admin_plataforma`, `admin_saas`).
- Q: Em qual granularidade o acesso pode ser concedido? → A: Nas duas formas — concessão por demanda específica (UUID da demanda) e concessão "geral" por emissor (UUID do emissor, liberando todas as demandas atuais e futuras dele para o usuário indicado).
- Q: Como reconciliar "nada invisível" com uma listagem que mistura registros permitidos e não permitidos? → A: ~~A listagem mostra apenas o que o usuário pode ver, filtrada silenciosamente.~~ **Superseded** pela Session 2026-09-16 (correção PO): listagem não esconde; 403 só no acesso direto.
- Q: Dashboard, relatório de gestão, auditoria e pesquisa de satisfação entram nessa restrição de "ver só o meu"? → A: Não. Ficam fora do escopo — continuam agregados e visíveis a quem já tem o módulo Ouvidoria liberado, sem mudança.
- Q: A regra vale também para demandas já existentes (criadas antes desta feature)? → A: Sim. A checagem é feita em tempo de leitura, então passa a valer imediatamente para registros antigos e novos, sem necessidade de migração de dados.

### Session 2026-09-16 (rodada 2 — feature flag)

- Q: O toggle liga/desliga em qual nível? → A: Por tenant/instituição — cada instituição pode ter a feature ligada ou desligada independentemente, mesmo padrão já usado em `TenantLicenca.active`.
- Q: Quem pode ligar/desligar o flag? → A: `admin_saas`, para qualquer tenant, E `admin_tenant`, apenas para a própria instituição.
- Q: Quando o flag está desligado, o que acontece com toda a lógica desta feature (restrição por dono, 403 em ação direta, filtro de listagem, chefe/admin bypass, grant/revoke)? → A: Kill-switch completo — volta exatamente ao comportamento de antes desta feature: qualquer usuário com o módulo Ouvidoria liberado vê e acessa tudo, sem 403 por dono, sem filtro de listagem por emissor.
- Q: O que acontece com concessões de acesso já criadas se o flag for desligado e depois religado? → A: Os dados de concessão continuam guardados; desligar o flag só afeta a fiscalização (enforcement), nunca apaga dados — as concessões voltam a valer automaticamente quando o flag for religado.
- Q: Qual o estado padrão do flag ao nascer esta feature (deploy inicial), para tenants já existentes (incluindo AGEMAN) e para tenants novos? → A: Ligado por padrão em todos — o comportamento restrito já é o padrão; o flag existe como botão de emergência para desligar se necessário.
- Q: Onde esse toggle aparece na interface? → A: No app admin-saas, na tela já existente de gestão do tenant (perto de licenças/módulos), para `admin_saas`; e numa tela de configurações da instituição já existente no app web, para `admin_tenant` (que só vê/altera o flag da própria instituição).

### Session 2026-09-16 (correção PO — listagem vs. 403)

- Q: A listagem (`GET /ouvidoria/manifestacoes`) deve esconder demandas de outro emissor? → A: **Não.** Interpretação anterior da US1 estava errada. Qualquer operador com módulo Ouvidoria vê **todas** as manifestações do tenant na lista (mesmo universo dos KPIs). Filtros de produto (tipo, status, protocolo, rascunho, etc.) continuam. A listagem **não** filtra por dono/emissor/grant.
- Q: Onde vale o 403 `OUVIDORIA_ACCESS_DENIED`? → A: Só em ação **direta** sobre um registro: GET detalhe, PATCH, DELETE, PDF/DOCX, anexos, encaminhar/responder/encerrar. Quem não é dono (e não tem grant / não é chefe/admin) vê a linha na lista; ao abrir detalhe/editar recebe 403. Sobrescreve o filtro silencioso de listagem da US1 original.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Operador comum vê todas as demandas na lista; 403 só no acesso direto (Priority: P1)

Um operador institucional comum da Ouvidoria (não é chefe, não é admin) faz login e abre a lista de demandas. Ele vê **todas** as manifestações do tenant — as próprias, as de colegas e as do canal público — com os filtros de UI normais (tipo, status, protocolo, etc.). A lista não esconde linha por dono. Ao abrir o detalhe (ou editar/baixar) de uma demanda da qual não é emissor e sem grant, recebe 403 explícito.

**Why this priority**: KPIs e tabela devem refletir o mesmo universo. Esconder na lista e mostrar total agregado (~3669 vs. 1 rascunho) é inconsistente. A restrição de dono vale no acesso direto, não na listagem.

**Independent Test**: Autenticar como dois operadores diferentes, cada um emissor de uma demanda interna; confirmar que a lista de ambos contém as duas linhas; `GET` detalhe da demanda alheia retorna 403.

**Acceptance Scenarios**:

1. **Given** dois operadores institucionais comuns, cada um emissor de uma demanda interna distinta, **When** cada um abre a lista de demandas, **Then** ambos veem as duas linhas (e as demais do tenant, sujeitos aos filtros de produto).
2. **Given** uma demanda vinda do canal público (cidadão, sem emissor institucional), **When** qualquer operador com o módulo Ouvidoria liberado abre a lista, **Then** essa demanda aparece normalmente para todos.
3. **Given** um operador comum sem concessão de acesso extra, **When** ele tenta abrir o detalhe/editar uma demanda interna de outro emissor, **Then** o sistema responde 403 `OUVIDORIA_ACCESS_DENIED` (a linha continua visível na lista).

---

### User Story 2 - Acesso direto a um registro sem permissão retorna 403 explícito (Priority: P1)

Um operador comum recebe (por link direto, protocolo informado por um colega, etc.) o identificador de uma demanda interna da qual não é o emissor e para a qual não tem concessão de acesso. Ao tentar abrir o detalhe, editar, ou baixar o documento (PDF/Word) dessa demanda, o sistema nunca finge que o dado não existe nem libera silenciosamente — ele recebe uma resposta clara de acesso negado (403), sem qualquer conteúdo da demanda vazando na resposta.

**Why this priority**: É a exigência explícita do cliente: "não quero que nada fique invisível... e sim que receba que não tem acesso 403" — a negação precisa ser explícita, nunca um esconderijo silencioso, nas ações diretas sobre um registro específico.

**Independent Test**: Autenticado como um operador sem vínculo com uma demanda específica, chamar diretamente o detalhe, a edição e o download do documento dessa demanda e confirmar 403 em todos os casos, sem dados da demanda no corpo da resposta.

**Acceptance Scenarios**:

1. **Given** um operador sem vínculo com a demanda X (não é emissor, sem concessão, não é chefe/admin), **When** ele solicita o detalhe da demanda X, **Then** o sistema responde 403, sem nenhum campo de conteúdo da demanda.
2. **Given** a mesma condição do cenário 1, **When** ele tenta editar/atualizar a demanda X, **Then** o sistema responde 403 e nenhuma alteração é persistida.
3. **Given** a mesma condição do cenário 1, **When** ele tenta baixar o documento em PDF ou Word da demanda X, **Then** o sistema responde 403 e nenhum arquivo é gerado/entregue.

---

### User Story 3 - Chefes da ouvidoria e admins veem tudo (Priority: P1)

Um chefe de setor cujo setor está vinculado ao módulo Ouvidoria ("chefe da ouvidoria"), ou qualquer administrador (da instituição ou da plataforma), faz login e abre a lista e o detalhe de qualquer demanda — interna de qualquer emissor ou do canal público — sem nenhuma restrição de dono. Nenhuma ação (detalhe, edição, download) retorna 403 para esses perfis por motivo de "dono".

**Why this priority**: Sem essa regra, a gestão da ouvidoria ficaria paralisada — chefes e admins precisam de visão completa para supervisionar e administrar.

**Independent Test**: Autenticar como chefe da ouvidoria e como admin, cada um abrindo demandas emitidas por operadores diferentes, confirmando acesso total ao detalhe, edição e download em todas elas.

**Acceptance Scenarios**:

1. **Given** um chefe da ouvidoria autenticado, **When** ele lista ou abre qualquer demanda interna de qualquer emissor, **Then** o acesso é sempre permitido.
2. **Given** um admin (`admin_tenant`, `admin_plataforma` ou `admin_saas`) autenticado, **When** ele lista ou abre qualquer demanda, **Then** o acesso é sempre permitido.
3. **Given** um chefe de setor cujo setor NÃO está vinculado ao módulo Ouvidoria, **When** ele tenta abrir uma demanda da qual não é emissor, **Then** ele NÃO tem o bypass de "chefe da ouvidoria" — segue as mesmas regras de um operador comum.

---

### User Story 4 - Conceder acesso a um colega para um registro específico (Priority: P2)

O emissor de uma demanda (ou um chefe da ouvidoria, ou um admin) decide que outro usuário específico precisa acompanhar aquela demanda pontual. Ele concede, via o identificador (UUID) da demanda e o identificador (UUID) do usuário destinatário, acesso de visualização àquele registro específico. A partir dessa concessão, o usuário destinatário passa a conseguir ver o detalhe, editar (quando aplicável) e baixar o documento daquela demanda, sem virar dono nem afetar as demais demandas.

**Why this priority**: Cobre o pedido explícito "vai ser possível permitir um acesso a um outro usuário [para] a uuid [que estava em] 403" — colaboração pontual sem abrir mão da regra padrão de restrição.

**Independent Test**: Como emissor de uma demanda, conceder acesso a um segundo usuário para essa demanda específica; autenticar como o segundo usuário e confirmar que ele agora acessa aquela demanda (e continua sem acesso a outras demandas do mesmo emissor).

**Acceptance Scenarios**:

1. **Given** o emissor de uma demanda concede acesso a essa demanda para o usuário B, **When** o usuário B tenta abrir o detalhe dessa demanda, **Then** o acesso é permitido.
2. **Given** a concessão foi feita apenas para a demanda X, **When** o usuário B tenta abrir uma outra demanda Y do mesmo emissor sem concessão própria, **Then** o acesso a Y continua negado (403).
3. **Given** um chefe da ouvidoria ou admin concede acesso a uma demanda em nome do fluxo de gestão, **When** o usuário destinatário acessa, **Then** o acesso é permitido do mesmo jeito que se o próprio emissor tivesse concedido.

---

### User Story 5 - Conceder acesso a todas as demandas de um emissor (Priority: P2)

O emissor (ou chefe da ouvidoria, ou admin) concede a outro usuário específico acesso a TODAS as demandas daquele emissor — atuais e futuras — de uma só vez, identificando o destinatário pelo UUID do usuário, sem precisar repetir a concessão demanda por demanda.

**Why this priority**: Cobre o caso de colaboração contínua (ex.: substituição temporária, apoio permanente de outro colega) sem exigir uma concessão manual para cada nova demanda criada.

**Independent Test**: Conceder acesso "geral" de um emissor A para um usuário B; confirmar que B vê tanto as demandas já existentes de A quanto uma nova demanda criada por A depois da concessão, sem nova ação manual.

**Acceptance Scenarios**:

1. **Given** uma concessão geral do emissor A para o usuário B, **When** B lista ou abre qualquer demanda já existente de A, **Then** o acesso é permitido.
2. **Given** a mesma concessão geral ativa, **When** A cria uma nova demanda depois da concessão, **Then** B também consegue acessar essa nova demanda sem ação adicional.
3. **Given** a concessão geral é revogada, **When** B tenta acessar qualquer demanda de A (antiga ou nova) depois da revogação, **Then** o acesso volta a ser negado (403), exceto se outra concessão específica ainda cobrir algum registro pontual.

---

### User Story 6 - Ver quem tem acesso a uma demanda (Priority: P2)

Qualquer pessoa autorizada a ver uma demanda (o próprio emissor, um chefe da ouvidoria, um admin, ou alguém com concessão) consegue visualizar, na própria tela da demanda, a lista de todos os que atualmente têm acesso a ela: o emissor, os chefes da ouvidoria e admins (como grupo, já que têm acesso a tudo) e cada usuário com concessão explícita (pontual ou geral) — sem precisar consultar outra tela ou pedir para o suporte.

**Why this priority**: Atende ao pedido "vai exibir todos quem tem acesso" — dá transparência sobre quem pode ver aquele registro, essencial para auditoria e confiança no controle de acesso.

**Independent Test**: Com concessões pontuais e gerais ativas sobre uma demanda, abrir o detalhe dela e confirmar que a lista de "quem tem acesso" reflete corretamente o emissor, o grupo de chefes/admins e cada usuário com concessão vigente.

**Acceptance Scenarios**:

1. **Given** uma demanda com o emissor A e uma concessão pontual para B, **When** qualquer autorizado abre o detalhe, **Then** a lista de acesso mostra A (emissor) e B (concessão pontual), além da indicação de que chefes da ouvidoria e admins também têm acesso.
2. **Given** uma concessão geral do emissor A para C, **When** o detalhe de qualquer demanda de A é aberto, **Then** C aparece na lista de quem tem acesso àquela demanda.
3. **Given** uma concessão (pontual ou geral) é revogada, **When** o detalhe é aberto novamente, **Then** o usuário revogado não aparece mais na lista de quem tem acesso.

---

### User Story 7 - Ativar/desativar toda a restrição de acesso por tenant (feature flag) (Priority: P3)

Um `admin_saas` (para qualquer tenant) ou um `admin_tenant` (apenas para a própria instituição) precisa de um botão de emergência para desligar toda a restrição de acesso desta feature — por exemplo, se algo se comportar de forma inesperada em produção — sem precisar de um deploy. Ao desligar o flag daquele tenant, todos os usuários com o módulo Ouvidoria liberado voltam a ver e acessar todas as demandas, exatamente como funcionava antes desta feature existir. Ao religar, a restrição (incluindo concessões já feitas) volta a valer imediatamente.

**Why this priority**: É um mecanismo de segurança operacional, não o valor central pedido pelo cliente — o flag nasce ligado por padrão (US1-6 já valem sem nenhuma ação manual); esta história cobre apenas a capacidade de desligar/religar quando necessário.

**Independent Test**: Com dois operadores cada um emissor de uma demanda distinta (cenário da US1), desligar o flag do tenant e confirmar que o GET detalhe da demanda alheia passa a 200; religar o flag e confirmar que o detalhe alheio volta a 403 (e qualquer concessão feita antes) sem necessidade de novo login. A listagem já mostra todas as linhas com o flag ligado ou desligado.

**Acceptance Scenarios**:

1. **Given** um `admin_saas` autenticado, **When** ele desliga o flag de um tenant específico, **Then** todos os usuários daquele tenant com módulo Ouvidoria liberado passam a ver/acessar todas as demandas, internas e públicas, sem 403 por dono.
2. **Given** um `admin_tenant` autenticado, **When** ele desliga o flag da própria instituição, **Then** o efeito é idêntico ao cenário 1, restrito ao seu tenant; **When** ele tenta alterar o flag de outro tenant (ex.: chamando a rota de outro tenant), **Then** o sistema responde 403.
3. **Given** o flag de um tenant está desligado, **When** um usuário lista ou abre qualquer demanda daquele tenant, **Then** nenhuma checagem de dono/concessão/chefe é aplicada — acesso total enquanto o módulo Ouvidoria estiver liberado.
4. **Given** existem concessões de acesso (pontuais ou gerais) criadas antes do flag ser desligado, **When** o flag é desligado e depois religado, **Then** essas concessões voltam a valer automaticamente, sem necessidade de recriação.
5. **Given** um tenant nunca teve o flag alterado (nenhuma configuração explícita registrada), **When** qualquer usuário daquele tenant acessa a Ouvidoria, **Then** o comportamento é o de flag LIGADO (restrição em vigor) — ausência de configuração nunca equivale a desligado.
6. **Given** o flag de um tenant é desligado enquanto usuários já têm sessão/token ativo, **When** esses usuários fazem qualquer requisição após a mudança, **Then** o novo estado (sem restrição) já se aplica imediatamente, sem exigir novo login.

---

### Edge Cases

- Uma demanda sem `emissorUserId` preenchido (canal público, ou criada por admin sem operador vinculado, conforme spec 044) não é considerada "de dono" — permanece visível a todos com o módulo Ouvidoria, sem concessão necessária.
- Um chefe de setor perde a chefia do setor vinculado à Ouvidoria (ou o setor deixa de estar vinculado ao módulo) — ele imediatamente deixa de ter o bypass de "chefe da ouvidoria" na próxima requisição (checagem em tempo real, sem cache indevido).
- Um usuário concede acesso (pontual ou geral) e depois é inativado/desligado — a concessão feita por ele permanece válida para quem a recebeu (a concessão vale entre concedente→destinatário no momento em que foi criada; a validade da concessão não depende do concedente continuar ativo), salvo revogação explícita por um chefe/admin.
- Tentativa de conceder acesso para um usuário que não existe no tenant, ou para si mesmo (o próprio emissor), ou duplicar uma concessão já existente — deve ser rejeitada ou tratada como no-op, sem erro grave.
- Uma concessão pontual e uma concessão geral podem coexistir para o mesmo par emissor/destinatário — revogar uma não afeta a outra.
- Um usuário com concessão pontual sobre a demanda X não ganha nenhum privilégio sobre outras demandas do mesmo emissor além de X.
- As ações de encaminhar, responder, encerrar e gerenciar anexos de uma demanda específica seguem a mesma regra de acesso das ações citadas explicitamente (detalhe, edição, download de documento), já que operam sobre o mesmo registro identificado por UUID.
- O portal público (consulta de protocolo, criação de manifestação pelo cidadão) não é afetado — permanece sem autenticação e fora deste modelo de controle de acesso.
- Um tenant sem nenhuma configuração explícita de flag (nunca foi alterado por ninguém) DEVE se comportar como flag LIGADO — a ausência de registro nunca é interpretada como desligado.
- Um `admin_tenant` tenta alterar o flag de um tenant que não é o seu (ex.: manipulando a URL/rota) — o sistema DEVE responder 403, independentemente da rota usada.
- Desligar o flag NÃO desliga as telas de Dashboard/Relatório/Auditoria/Pesquisa de Satisfação, pois elas já estavam fora do escopo desta feature (FR-010) antes mesmo de existir o flag — não há nada a "restaurar" nelas.
- Enquanto o flag está desligado, os endpoints de conceder/revogar acesso (FR-004/FR-005/FR-006) continuam funcionando normalmente sobre os dados (não retornam erro por causa do flag) — eles simplesmente não têm efeito prático na decisão de acesso até o flag ser religado.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: O sistema DEVE restringir, por padrão, a visibilidade de uma demanda interna da Ouvidoria (aquela com `emissorUserId` preenchido) a quem é o próprio emissor — exceto quando as regras de FR-003 (chefes/admins) ou FR-004/FR-005 (concessão) se aplicarem.
- **FR-002**: Demandas originadas do canal público (sem `emissorUserId` institucional preenchido) NÃO ENTRAM na restrição de dono — permanecem visíveis a qualquer usuário autenticado que já tenha o módulo Ouvidoria liberado, como hoje.
- **FR-003**: Usuários com role `chefe_setor` cujo(s) setor(es) (via vínculo de chefia) estejam associados ao módulo Ouvidoria ("chefes da ouvidoria"), e usuários com qualquer role administrativa (`admin_tenant`, `admin_plataforma`, `admin_saas`), DEVEM ter acesso irrestrito a todas as demandas (internas e do canal público), sem depender de concessão.
- **FR-004**: O sistema DEVE permitir que o emissor de uma demanda, um chefe da ouvidoria, ou um admin, conceda a outro usuário específico (identificado por UUID) acesso de visualização/edição a UMA demanda específica (identificada por seu UUID).
- **FR-005**: O sistema DEVE permitir que o emissor, um chefe da ouvidoria, ou um admin, conceda a outro usuário específico (identificado por UUID) acesso a TODAS as demandas de um emissor (identificado pelo UUID do emissor) — cobrindo automaticamente demandas futuras desse emissor enquanto a concessão estiver ativa.
- **FR-006**: O sistema DEVE permitir revogar, a qualquer momento, uma concessão de acesso (pontual ou geral) previamente feita — pelos mesmos perfis que podem concedê-la (emissor do registro/dos registros, chefe da ouvidoria, admin).
- **FR-007**: Quando um usuário sem acesso (não é emissor, não é chefe/admin, sem concessão vigente) tentar visualizar o detalhe, editar/atualizar, ou baixar o documento (PDF/Word) de uma demanda específica, o sistema DEVE responder com HTTP 403 e uma mensagem clara de acesso negado, sem incluir nenhum dado de conteúdo da demanda na resposta.
- **FR-008**: A listagem de demandas (`GET /ouvidoria/manifestacoes`) DEVE retornar **todas** as manifestações visíveis do tenant para qualquer operador com módulo Ouvidoria — sem filtro por dono/emissor/grant. Filtros de produto (tipo, status, protocolo, rascunho, período, etc.) continuam. A listagem NUNCA omite linha por falta de permissão de dono e NUNCA retorna 403 por esse motivo. O 403 (`OUVIDORIA_ACCESS_DENIED`) aplica-se somente em ação direta sobre um registro (FR-007).
- **FR-009**: A tela/endpoint de detalhe de uma demanda DEVE exibir, para quem tem acesso a ela, a lista nominativa de quem atualmente tem acesso (`efetivos`): o emissor, cada admin institucional (`admin_tenant` / `admin_plataforma` do tenant) e cada chefe da ouvidoria (chefe de setor vinculado ao módulo Ouvidoria — não chefes de outros setores), e cada usuário com concessão explícita vigente (pontual ou geral), com origem (Admin / Chefe de setor / Emissor / Concedido) e se o acesso é implícito (não revogável por grant) ou concedido. O diálogo **Conceder acesso** (detalhe e listagem) DEVE mostrar essa lista antes do formulário e NÃO oferecer no select quem já está em `efetivos`.
- **FR-010**: Esta restrição de acesso NÃO DEVE se aplicar às telas/endpoints de Dashboard, Relatório de Gestão, Auditoria e Pesquisa de Satisfação da Ouvidoria — esses continuam regidos apenas pela permissão de módulo (Ouvidoria) já existente, sem alteração.
- **FR-011**: A restrição de acesso DEVE valer imediatamente para demandas já existentes (criadas antes desta feature), avaliada em tempo de leitura — sem necessidade de migração ou correção em lote de dados históricos.
- **FR-012**: O portal público de Ouvidoria (consulta de protocolo, criação de manifestação pelo cidadão) NÃO DEVE ser afetado por esta feature — continua público/sem autenticação.
- **FR-013**: O sistema NÃO DEVE ocultar silenciosamente uma ação (botão/opção) de forma que o usuário fique sem retorno algum sobre a negação — ao tentar a ação sobre um registro específico sem permissão, o usuário deve sempre poder chegar até a resposta explícita de 403 (não é permitido "fingir sucesso" nem falhar silenciosamente sem mensagem).
- **FR-014**: O sistema DEVE ter um controle (feature flag) por tenant que ativa/desativa, de uma só vez, toda a restrição de acesso desta feature (FR-001 a FR-009).
- **FR-015**: Quando o flag estiver DESLIGADO para um tenant, todo usuário autenticado com o módulo Ouvidoria liberado DEVE ver e acessar (listar, detalhar, editar, baixar documento) qualquer demanda daquele tenant — interna ou pública — sem 403 por "dono" e sem filtro de listagem por emissor, exatamente o comportamento anterior a esta feature.
- **FR-016**: Desligar o flag NÃO DEVE apagar, revogar ou invalidar concessões de acesso (FR-004/FR-005) já registradas — elas permanecem persistidas e retomam efeito automaticamente quando o flag for religado, sem necessidade de recriação.
- **FR-017**: Um `admin_saas` DEVE poder ligar/desligar o flag de qualquer tenant; um `admin_tenant` DEVE poder ligar/desligar apenas o flag da própria instituição — tentativa de alterar o flag de outro tenant por um `admin_tenant` DEVE ser negada (403).
- **FR-018**: O flag DEVE nascer LIGADO por padrão — tanto para tenants já existentes no momento do deploy desta feature (incluindo AGEMAN) quanto para tenants criados depois — sem exigir nenhuma ação manual para a restrição de acesso já valer; ausência de configuração explícita do flag para um tenant NUNCA equivale a desligado.
- **FR-019**: O toggle do flag DEVE estar disponível na tela de gestão do tenant já existente no app admin-saas (perto de licenças/módulos) para `admin_saas`, e numa tela de configurações da instituição já existente no app web para `admin_tenant`.
- **FR-020**: Toda alteração do flag (ligar/desligar) DEVE ser registrada em auditoria, identificando quem alterou (`admin_saas` ou `admin_tenant`, com seu identificador), quando, e o novo estado resultante.
- **FR-021**: Nas superfícies de 403 de registro (detalhe, editar e ações da listagem: tramitar/download), o sistema DEVE oferecer CTA **Solicitar acesso** ao ator sem permissão, e CTA **Conceder acesso** quando o ator puder conceder (emissor, chefe da ouvidoria ou admin). A listagem DEVE expor a ação "Conceder acesso" nesses mesmos perfis, para liberar colegas que tomariam 403.

### Key Entities

- **Demanda/Manifestação Ouvidoria (AGEMAN)**: Registro já existente no domínio Ouvidoria. Passa a ter um significado de controle de acesso vinculado ao campo `emissorUserId`: quando preenchido (demanda interna), define o "dono" padrão da visibilidade; quando vazio (canal público ou caso do administrador sem vínculo, conforme spec 044), a demanda não tem dono e segue a regra atual (visível a quem tem o módulo).
- **Concessão de Acesso (Grant)**: Nova associação entre quem concede (emissor do registro, chefe da ouvidoria ou admin) e um usuário destinatário (por UUID), com um escopo: (a) uma demanda específica (por UUID da demanda), ou (b) todas as demandas de um emissor específico (por UUID do emissor). Possui data de concessão e pode ser revogada (data de revogação).
- **Chefe da Ouvidoria**: Não é uma entidade nova de dados — é a combinação já existente de role `chefe_setor` + vínculo de chefia a um setor que esteja associado ao módulo Ouvidoria. Concede acesso irrestrito a todas as demandas.
- **Admin (bypass)**: `admin_tenant`, `admin_plataforma`, `admin_saas` — perfis administrativos já existentes que, por esta feature, passam a ter bypass explícito e documentado de acesso irrestrito às demandas da Ouvidoria.
- **Flag de Acesso da Ouvidoria (por tenant)**: Nova configuração booleana por tenant que ativa (padrão) ou desativa toda a restrição de acesso desta feature (FR-001 a FR-009). Ausência de configuração explícita equivale a LIGADO. Alterável por `admin_saas` (qualquer tenant) ou `admin_tenant` (própria instituição). Não afeta a persistência das concessões de acesso — apenas se elas são fiscalizadas ou não.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Em 100% dos casos, a lista de demandas de um operador comum com módulo Ouvidoria mostra o mesmo universo do tenant que os KPIs (todas as manifestações visíveis, com filtros de produto), incluindo demandas internas de outros emissores — a restrição de dono não esconde linha na lista.
- **SC-002**: Em 100% das tentativas de um usuário sem acesso de ver detalhe, editar ou baixar documento de uma demanda que não é sua, o sistema responde 403 sem nenhum dado de conteúdo da demanda na resposta.
- **SC-003**: Chefes da ouvidoria e admins acessam 100% das demandas (listagem e detalhe), sem nenhum bloqueio relacionado a "dono".
- **SC-004**: Uma concessão de acesso (pontual ou geral), uma vez criada, libera o acesso do destinatário imediatamente (já na requisição seguinte), sem necessidade de novo login ou processamento em lote.
- **SC-005**: Uma revogação de acesso, uma vez feita, bloqueia o destinatário imediatamente (já na requisição seguinte) — 403 volta a ocorrer se não houver outra concessão ou condição de acesso vigente.
- **SC-006**: A lista de "quem tem acesso" de qualquer demanda reflete corretamente, em qualquer momento, o emissor, o grupo de chefes/admins e todas as concessões vigentes (pontuais e gerais) — sem exigir consulta a outra tela.
- **SC-007**: 100% das demandas já existentes antes desta feature passam a respeitar as mesmas regras de acesso, sem qualquer migração manual de dados.
- **SC-008**: Dashboard, Relatório de Gestão, Auditoria e Pesquisa de Satisfação da Ouvidoria continuam funcionando exatamente como antes desta feature, sem qualquer regressão de acesso.
- **SC-009**: Com o flag de um tenant desligado, 100% dos usuários daquele tenant com módulo Ouvidoria liberado acessam qualquer demanda (listagem e detalhe) sem 403 por dono, já na requisição seguinte à mudança, sem necessidade de novo login.
- **SC-010**: Religar o flag de um tenant restaura, já na requisição seguinte, a aplicação de 100% das restrições e concessões vigentes antes de ele ter sido desligado, sem qualquer recriação manual de dados.

## Assumptions

- `emissorUserId` é o único critério de "dono" para demandas internas — não é combinado com o campo de criador (`createdByUserId`), já que a spec 044 garante que ambos coincidem para operadores institucionais.
- "Chefe da ouvidoria" é derivado da combinação já existente entre role `chefe_setor` e vínculo de chefia a um setor associado ao módulo Ouvidoria — não é adicionada nenhuma role nova ao enum `UserRole`.
- A revogação de concessão segue os mesmos perfis autorizados a conceder (emissor, chefe da ouvidoria, admin) — modelo espelhado em padrões de concessão/revogação já existentes no projeto (ex.: reset de senha, gestor de protocolo), mesmo que não tenha sido pedido explicitamente, por ser inconsistente ter concessão sem revogação equivalente.
- O escopo do 403 obrigatório (FR-007) cobre, no mínimo, as ações de ver detalhe, editar/atualizar e baixar documento (PDF/Word) de uma demanda específica — outras ações diretas sobre um registro específico (encaminhar, responder, encerrar, gerenciar anexos) seguem a mesma regra por extensão, já que operam sobre o mesmo registro identificado por UUID; caso o cliente queira comportamento diferente para alguma dessas ações, isso deve ser levantado no `/speckit-plan` ou em uma nova rodada de clarificação.
- Esta feature é implementada de forma genérica no módulo Ouvidoria da plataforma (não é um hack específico do tenant AGEMAN), ainda que o pedido tenha vindo no contexto do uso interno da Ouvidoria da AGEMAN.
- A concessão geral por emissor (FR-005) cobre demandas futuras automaticamente enquanto estiver ativa, por ser um vínculo entre pessoas (emissor → destinatário), não uma lista fixa de IDs de demandas.
- Usuários inativados/desligados não recebem nem exercem novas concessões, mas concessões já feitas por/para eles não são automaticamente revogadas por esta feature (fora de escopo tratar ciclo de vida de usuário inativo aqui).
- O flag é específico desta feature (restrição de acesso da Ouvidoria) — não é a criação de um mecanismo genérico de feature flags reutilizável por outras features da plataforma, ainda que a implementação (tabela por tenant, ausência = ligado) sirva de referência para um mecanismo genérico futuro, se pedido.
- A checagem do flag é feita no servidor a cada requisição relevante (assert de acesso e filtro de listagem) — não fica embutida/cacheada no JWT, exatamente para que ligar/desligar tenha efeito imediato sem exigir novo login (conforme SC-009/SC-010).

## Out of Scope

- Recalcular ou alterar a lógica de quem é o `emissorUserId` de uma demanda — já coberto pela spec 044 (Emissor automático ao criar demanda AGEMAN).
- Portal público de Ouvidoria (cidadão) — consulta de protocolo e criação de manifestação pública continuam sem autenticação e sem esta restrição.
- Restringir por dono o Dashboard, Relatório de Gestão, Auditoria e Pesquisa de Satisfação da Ouvidoria.
- Criar uma role nova (ex.: `chefe_ouvidoria`) no enum `UserRole` — "chefe da ouvidoria" é derivado de role + setor existentes.
- Qualquer mudança em outros módulos (Gabinete, Compras, Jurídico, IT, Protocolo/Tramitação) — esta feature é restrita ao módulo Ouvidoria.
- Um framework genérico de feature flags reutilizável por qualquer feature futura da plataforma — o flag desta feature é específico da restrição de acesso da Ouvidoria.
- Tela de histórico/auditoria dedicada às alterações do flag — o evento é registrado (FR-020), mas exibir um histórico visual de "quem ligou/desligou quando" não é pedido nesta feature (fica disponível via auditoria já existente, se necessário consultar depois).
