# Feature Specification: Identificação sem anônimo + e-mail

**Feature Branch**: `048-identificacao-sem-anonimo`

**Created**: 2026-09-17

**Status**: Draft

**Input**: User description: "titulo: Retirar opção de anônimo; incluir e-mail no formulário de identificação; tipo: feat. Contexto: print da etapa Identificação do assistente de nova manifestação (Ouvidoria) com cards «Permanecer anônimo» / «Quero me identificar» e formulário sem campo de e-mail; áudios de referência anexados (transcrição pendente)."

## Clarifications

### Session 2026-09-17

- Q: Em quais superfícies retirar a opção de anônimo? → A: **Apenas o assistente interno autenticado de Ouvidoria** (`ci-client-v2/apps/web`, tela do print). O portal público (`apps/publico`, AGEMAN — spec 043) fica **fora do escopo** desta feature e não é alterado. *(Decisão inicial havia considerado escopo máximo incluindo o portal público; corrigida nesta sessão de clarificação para restringir ao canal autenticado.)*
- Q: O que fazer com o e-mail (bloco Identificação vs «E-mail para resposta» existente)? → A: Unificar em um único campo de e-mail, dentro do bloco Identificação, **opcional** (validado quando preenchido). O campo solto «E-mail para resposta» deixa de existir separadamente.
- Q: Como fica a UI dos cards e os registros legados anônimos? → A: Remover os dois cards («Permanecer anônimo» e «Quero me identificar»); o formulário de dados do manifestante fica sempre visível, sem etapa de escolha. Manifestações/rascunhos já gravados como anônimos **antes** desta mudança permanecem como estão (sem migração retroativa nem bloqueio na edição).
- Q: A obrigatoriedade de nome completo (FR-009) vale também para denúncias (whistleblower), dado o risco de eliminar a possibilidade de relato sem identificação pessoal? → A: Nome completo continua **opcional** especificamente para o tipo **denúncia** — preserva a possibilidade de relato sem identificação pessoal mesmo sem o seletor explícito de "anônimo". Para os demais tipos (reclamação, sugestão, elogio, solicitação), nome completo permanece obrigatório.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Registrar manifestação sempre identificada no assistente interno (Priority: P1)

Um operador autenticado da ouvidoria inicia o cadastro de uma nova manifestação no assistente interno (`ci-client-v2/apps/web`). Na etapa **Identificação**, não existem mais os cards «Permanecer anônimo» / «Quero me identificar» — o formulário de dados do manifestante já aparece diretamente. O fluxo só avança quando os dados mínimos de identificação exigidos forem informados.

**Why this priority**: Elimina o canal de registro anônimo no assistente interno — requisito central do pedido e do print marcado.

**Independent Test**: Abrir o assistente de nova manifestação (interno), verificar ausência dos cards de escolha, preencher identificação e concluir (ou avançar) com sucesso; tentar avançar sem os mínimos e confirmar bloqueio com mensagem clara.

**Acceptance Scenarios**:

1. **Given** o operador está na etapa Identificação de uma nova manifestação no assistente interno, **When** a tela é exibida, **Then** não existem mais os cards «Permanecer anônimo» / «Quero me identificar» (nem controle equivalente).
2. **Given** a etapa Identificação está aberta, **When** o operador visualiza a seção, **Then** o formulário de dados do manifestante já está visível, sem etapa prévia de escolha.
3. **Given** os dados mínimos de identificação estão incompletos, **When** o operador tenta avançar ou confirmar, **Then** o sistema impede o avanço e indica o que falta.
4. **Given** o tipo da manifestação é **denúncia**, **When** o operador deixa o nome completo em branco, **Then** o sistema permite avançar e confirmar normalmente (nome completo é a única exceção de obrigatoriedade, aplicável apenas a denúncias).

---

### User Story 2 - Informar e-mail único no bloco de identificação (Priority: P1)

Na mesma etapa Identificação, o operador vê e preenche um único campo **E-mail**, opcional, junto aos demais dados do manifestante (nome, documento, telefones etc.). O campo solto «E-mail para resposta», que hoje existe fora desse bloco, deixa de existir separadamente — vira este mesmo campo, agora dentro de Identificação.

**Why this priority**: Completa o segundo requisito explícito do título e do print, unificando o conceito de e-mail de contato em um só lugar.

**Independent Test**: Abrir Identificação, localizar o campo E-mail único no formulário, informar um endereço válido e inválido e observar aceite/rejeição; confirmar que não existe mais um segundo campo de e-mail fora do bloco.

**Acceptance Scenarios**:

1. **Given** o operador está na etapa Identificação, **When** olha o formulário do manifestante, **Then** existe um único campo **E-mail** (opcional) no mesmo bloco dos demais dados de identificação.
2. **Given** o operador informa um e-mail em formato inválido, **When** tenta avançar ou validar, **Then** o sistema rejeita com mensagem compreensível.
3. **Given** o operador deixa o e-mail em branco, **When** avança, **Then** o sistema permite prosseguir normalmente (campo opcional).
4. **Given** um e-mail válido foi informado, **When** avança, **Then** o e-mail fica associado à manifestação como contato do manifestante / canal de retorno, e não existe mais um campo separado de «E-mail para resposta» na tela.

---

### User Story 3 - Consistência na leitura da manifestação (Priority: P2)

Um operador ou chefe que consulta uma manifestação criada após esta mudança vê a identificação do manifestante (não «manifestação anônima») e o e-mail informado, nos pontos da interface em que os dados do solicitante já são exibidos hoje.

**Why this priority**: Garante que a remoção do anônimo e o e-mail não fiquem só no formulário de entrada — a leitura operacional deve refletir o novo padrão.

**Independent Test**: Criar uma manifestação identificada com e-mail e abrir a tela de detalhe/revisão; confirmar que não aparece rótulo de anônimo e que o e-mail está visível onde o contato do solicitante é mostrado.

**Acceptance Scenarios**:

1. **Given** uma manifestação foi registrada após a mudança (sempre identificada), **When** um operador abre o detalhe, **Then** não é apresentada como «manifestação anônima».
2. **Given** o e-mail foi informado no formulário de identificação, **When** o detalhe/revisão é aberto, **Then** o e-mail aparece no conjunto de dados de contato/identificação do manifestante.

---

### Edge Cases

- Manifestação ou rascunho já gravado como anônimo **antes** desta mudança: permanece como está — sem migração retroativa, sem exigir complemento na edição. A regra de "sempre identificado" vale apenas para manifestações **criadas** após a mudança entrar em vigor, no assistente interno.
- E-mail vazio (permitido, campo opcional) vs inválido (rejeitado) vs igual a outro contato já existente no tenant (permitido — não é chave única).
- Operador tenta colar espaços ou e-mail só com domínio incompleto — tratado pela validação de formato padrão.
- Rascunhos locais (feature 045) iniciados antes da mudança, com `isAnonymous: true` salvo localmente: ao retomar, o formulário deve se comportar como o novo padrão (sem cards, identificação sempre visível), preservando os demais dados já digitados.
- Manifestante escolhe o tipo **denúncia** e não informa nome completo: o sistema **MUST NOT** bloquear o avanço/envio por falta desse campo (única exceção à obrigatoriedade de nome completo).
- Operador muda o tipo de denúncia para outro tipo (ex.: reclamação) depois de já ter avançado sem nome: o sistema deve então cobrar o nome completo antes de confirmar, já que a exceção deixa de se aplicar.
- Portal público (`apps/publico`, AGEMAN): permanece **inalterado** por esta feature — continua com sua própria opção de anônimo e fluxo definidos na spec 043.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: O assistente interno de cadastro de manifestação (`ci-client-v2/apps/web`, tela de nova manifestação) **MUST NOT** exibir os cards/controles «Permanecer anônimo» / «Quero me identificar», nem equivalente que permita omitir a identificação do manifestante.
- **FR-002**: A etapa Identificação do assistente interno **MUST** apresentar o formulário de dados do manifestante de forma direta e sempre visível, sem etapa de escolha prévia entre anônimo e identificado.
- **FR-003**: Toda manifestação criada no assistente interno a partir da entrada em vigor desta mudança **MUST** ser tratada como identificada (não anônima), respeitando a exceção de nome completo para o tipo denúncia (FR-009).
- **FR-004**: O formulário de Identificação **MUST** incluir um único campo **E-mail**, opcional, no mesmo bloco dos demais dados do manifestante.
- **FR-005**: O sistema **MUST** validar o formato do e-mail quando preenchido e impedir avanço/confirmação com e-mail inválido; **MUST** permitir avançar com o campo vazio.
- **FR-006**: O e-mail informado em Identificação **MUST** ser persistido e exibido nos pontos de leitura da manifestação onde o contato do solicitante já é mostrado, substituindo o uso do campo «E-mail para resposta» anterior.
- **FR-007**: O campo «E-mail para resposta», atualmente exibido fora do bloco Identificação, **MUST** ser removido como campo separado no assistente interno — seu papel é absorvido pelo campo único de e-mail dentro de Identificação (FR-004).
- **FR-008**: O escopo desta feature está **restrito ao assistente interno autenticado de Ouvidoria** (`ci-client-v2/apps/web`). O portal público (`apps/publico`, AGEMAN — spec 043) e qualquer outro canal **MUST NOT** ser alterado por esta feature.
- **FR-009**: Campos mínimos obrigatórios após a remoção do anônimo: nome completo é obrigatório para os tipos reclamação, solicitação, elogio e sugestão; para o tipo **denúncia** (whistleblower), nome completo permanece **opcional**, preservando a possibilidade de relato sem identificação pessoal. E-mail, CPF/CNPJ, titular, matrícula e telefones permanecem opcionais para todos os tipos.
- **FR-010**: Mensagens de validação e textos da seção Identificação **MUST** deixar de instruir a escolha entre anônimo e identificação (ex.: subtítulo atual «Escolha se o manifestante permanece anônimo…» deve ser reescrito para refletir que a identificação é sempre solicitada).
- **FR-011**: Manifestações e rascunhos já gravados como anônimos **antes** da entrada em vigor desta mudança **MUST** permanecer inalterados — sem migração retroativa, sem bloqueio de edição, sem exigência de complemento de identificação.

### Key Entities

- **Manifestação**: Registro de ouvidoria criado via assistente interno; deixa de poder nascer anônima a partir desta mudança (exceto ausência de nome em denúncias); passa a carregar identificação do solicitante. Registros anônimos anteriores à mudança e manifestações do portal público não são afetados.
- **Dados do manifestante (identificação)**: Nome (obrigatório, exceto denúncia), documento, titular, matrícula, telefones e **e-mail** (único, opcional) no bloco de Identificação do assistente interno.
- **Canal de retorno**: O e-mail único de Identificação passa a ser o único canal de contato por e-mail da manifestação no assistente interno, substituindo o antigo «E-mail para resposta».

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Em revisão de UI do assistente interno, 100% das sessões de nova manifestação não exibem os cards de escolha anônimo/identificar.
- **SC-002**: Em testes de aceitação do assistente interno, 100% das manifestações concluídas após a mudança ficam identificadas (nunca anônimas), exceto ausência de nome em denúncias.
- **SC-003**: Em teste de formulário, existe exatamente um campo E-mail no bloco Identificação do assistente interno (nenhum campo de e-mail duplicado fora dele); aceita endereço válido, rejeita inválido e aceita vazio em 100% dos casos cobertos pelo roteiro.
- **SC-004**: Operadores concluem o preenchimento da Identificação em uma única passagem pela seção, sem etapa intermediária de escolha anônimo/identificado.
- **SC-005**: Em amostragem de detalhes de manifestações criadas após a mudança no assistente interno, nenhuma é rotulada como anônima (exceto ausência pontual de nome em denúncias) e o e-mail informado aparece na leitura de contato quando preenchido; manifestações anteriores à mudança e do portal público continuam exibidas como estavam (sem alteração).

## Assumptions

- O print anexado refere-se ao assistente interno de nova manifestação da Ouvidoria (`ci-client-v2/apps/web`) — escopo final confirmado nesta sessão de clarificação, restrito a esse canal autenticado.
- O portal público (`apps/publico`, AGEMAN — spec 043) permanece com seu comportamento atual (incluindo a opção de anônimo já especificada na 043) e não é tocado por esta feature.
- Tipo da mudança: **feat** (comportamento de produto, não apenas cosmético).
- Conteúdo dos três áudios de WhatsApp não pôde ser transcrito automaticamente nesta sessão; as decisões acima (Clarifications) foram confirmadas diretamente pelo usuário e prevalecem sobre qualquer detalhe adicional eventualmente contido nos áudios. Caso os áudios tragam requisito adicional não coberto aqui, uma nova rodada de clarificação será necessária.
- "E-mail para resposta" e o novo campo único de Identificação representam o mesmo conceito de contato por e-mail da manifestação — não há necessidade de migração de dados históricos além do mapeamento natural de nome de campo, a ser detalhado em `/speckit-plan`.
- Política de retenção/LGPD de dados pessoais segue a já vigente no módulo de Ouvidoria (sem regra nova só para esta feature).
- Não há exigência de um mínimo de contato (e-mail ou telefone) quando o nome estiver em branco (denúncia): por ser um canal autenticado operado por servidores da ouvidoria (não autoatendimento público anônimo), o risco de perda total de rastreabilidade já presente na 043 não se aplica aqui da mesma forma.

## Out of Scope

- Portal público de manifestações (`ci-client-v2/apps/publico`, AGEMAN — spec 043) — permanece inalterado, mantendo sua própria opção de anônimo.
- Redesign completo do assistente de manifestações além da seção Identificação e do posicionamento/regra do e-mail.
- Mudança de categorias, tipos de manifestação, endereço, concessionária ou anexos.
- Política nova de retenção de dados pessoais.
- Migração em massa ou reprocessamento de manifestações históricas anônimas — permanecem como estão.
- Exigência de um canal mínimo de contato (e-mail/telefone) quando o nome estiver ausente em denúncias.
