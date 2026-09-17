# Feature Specification: Recuperar último rascunho de manifestação (Ouvidoria)

**Feature Branch**: `045-rascunho-manifestacao-ouvidoria`

**Created**: 2026-09-14

**Status**: Draft

**Input**: User description: "criar acessar ultimo rascunho em cima da tabela manifestação — Se cair a API, internet ou der erro no token e deslogar o usuário, o sistema deve manter um rascunho do que foi feito na sessão de /ouvidoria/manifestacoes/nova. O backend deve ter boa validação e identificação para ver se aquilo foi enviado e ocultar o botão de rascunho. UI: acesso ao último rascunho acima da tabela na lista de manifestações."

## Clarifications

### Session 2026-09-14

- Q: Se a consulta de retomabilidade (FR-006) falhar por erro técnico (não por confirmação de envio), o que a interface deve fazer com o convite de último rascunho? → A: Ocultar o convite até conseguir confirmar a retomabilidade no servidor (postura conservadora — prioriza segurança contra reenvio duplicado sobre disponibilidade imediata do atalho).
- Q: Deve haver um limite explícito de tamanho/quantidade de anexos guardados no rascunho local? → A: Sim — limite explícito (valor exato definido em `/speckit-plan`); anexos excedentes não entram na cópia local e precisam ser reanexados ao retomar.
- Q: Qual deve ser a regra de gravação automática local (a US3 usava "periodicidade curta", vago)? → A: A cada mudança relevante de campo (on blur/change) OU no máximo a cada 5 segundos como salvaguarda, o que ocorrer primeiro — além de sempre gravar ao mudar de etapa.
- Q: Quando exigir confirmação explícita de descarte ao iniciar nova manifestação havendo rascunho recuperável? → A: Sempre que houver qualquer dado não vazio no rascunho local (qualquer campo preenchido).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Continuar preenchimento após perda de sessão (Priority: P1)

Um operador autenticado da ouvidoria começa a registrar uma nova manifestação no assistente em etapas (`/ouvidoria/manifestacoes/nova`). Antes de concluir o envio, a conexão cai, a API fica indisponível ou a sessão é encerrada (por exemplo, token inválido). O operador faz login novamente, abre a lista de manifestações e vê, **acima da tabela**, um convite claro para retomar o **último rascunho** daquele preenchimento. Ao aceitar, volta ao assistente com os campos já preenchidos na última etapa em que parou (ou na etapa salva), podendo seguir até confirmar o envio.

**Why this priority**: Evita retrabalho e perda de relatos sensíveis quando falhas externas interrompem o fluxo — o problema central descrito pelo usuário.

**Independent Test**: Simular preenchimento parcial no assistente, encerrar sessão ou bloquear comunicação com o servidor antes de qualquer confirmação final, autenticar de novo, abrir a lista e retomar o rascunho com os mesmos dados visíveis no formulário.

**Acceptance Scenarios**:

1. **Given** um operador preencheu ao menos um campo obrigatório parcial no assistente de nova manifestação e a sessão expirou sem confirmação final, **When** ele autentica novamente e abre a lista de manifestações, **Then** aparece um acesso ao último rascunho acima da tabela e, ao usá-lo, o assistente reabre com o conteúdo recuperado.
2. **Given** o operador estava na etapa 2 ou 3 do assistente quando a falha ocorreu, **When** ele retoma o rascunho, **Then** o assistente restaura a etapa e os valores dos campos conforme estavam no momento da última gravação local automática.
3. **Given** não houve nenhum dado digitado além do estado inicial vazio do formulário, **When** o operador abre a lista, **Then** nenhum convite de rascunho é exibido.

---

### User Story 2 - Ocultar convite quando o envio já foi concluído (Priority: P1)

Depois que uma manifestação deixa de ser rascunho (confirmação final / envio concluído no fluxo de negócio), o operador não deve mais ver o convite para “último rascunho” referente a esse trabalho, mesmo que ainda exista uma cópia local antiga no navegador.

**Why this priority**: Impede duplicidade, confusão e tentativa de reenviar algo já registrado — requisito explícito de validação no servidor.

**Independent Test**: Concluir o envio de uma manifestação a partir do assistente; na lista, confirmar que o convite de rascunho some. Tentar forçar retomada por meio do convite (se ainda visível por cache) e verificar que o sistema recusa ou redireciona de forma segura.

**Acceptance Scenarios**:

1. **Given** o operador confirmou o envio final de uma manifestação originada do rascunho recuperado, **When** ele volta à lista de manifestações, **Then** o convite de último rascunho **não** é exibido para esse registro.
2. **Given** existe identificador de rascunho vinculado a uma manifestação que já não está mais em estado editável de rascunho, **When** o sistema consulta a situação desse registro, **Then** responde de forma inequívoca que o envio já foi realizado (ou que o rascunho não é mais retomável) e a interface oculta o convite.
3. **Given** o operador descartou explicitamente o rascunho local ou apagou o rascunho correspondente no servidor, **When** ele abre a lista, **Then** o convite não aparece.

---

### User Story 3 - Gravação automática durante o preenchimento (Priority: P2)

Enquanto o operador preenche o assistente de nova manifestação, o sistema grava automaticamente o progresso localmente a cada mudança relevante de campo (ao perder o foco / alterar valor) **ou** no máximo a cada **5 segundos** como salvaguarda — o que ocorrer primeiro —, além de sempre gravar ao mudar de etapa; tudo isso **sem depender** de chamadas bem-sucedidas ao servidor, de modo que quedas de API ou offline não apaguem o que já foi digitado (perda máxima limitada a poucos segundos de digitação).

**Why this priority**: Sem persistência local contínua, a recuperação após logout só funcionaria para quem já tinha conseguido salvar no servidor — exatamente o cenário de falha descrito.

**Independent Test**: Preencher campos com a rede desligada ou API indisponível, recarregar a página ou reautenticar, e verificar que os dados permanecem recuperáveis pelo convite na lista.

**Acceptance Scenarios**:

1. **Given** o operador edita campos no assistente com o servidor inacessível, **When** ele fecha o navegador e reabre após login, **Then** o último rascunho local ainda contém essas edições.
2. **Given** o servidor volta a ficar disponível após um período offline, **When** o operador retoma pelo convite na lista, **Then** o fluxo permite sincronizar ou continuar até o envio final sem exigir redigitar os campos já salvos localmente.

---

### User Story 4 - Descartar ou substituir rascunho (Priority: P3)

O operador pode abandonar o rascunho recuperável (descartar) ou iniciar uma nova manifestação do zero. O sistema DEVE exigir confirmação explícita sempre que existir qualquer dado não vazio no rascunho local (qualquer campo preenchido), para evitar perda acidental de trabalho não enviado.

**Why this priority**: Evita ficar preso a um rascunho antigo e dá controle explícito sobre “último rascunho”.

**Independent Test**: Com rascunho disponível, escolher “Nova manifestação” e confirmar descarte; verificar que o convite some e o formulário abre limpo.

**Acceptance Scenarios**:

1. **Given** existe convite de último rascunho na lista com ao menos um campo preenchido, **When** o operador escolhe iniciar nova manifestação, **Then** o sistema exige confirmação explícita antes de descartar; ao confirmar, o convite deixa de aparecer e o assistente abre vazio.
2. **Given** o operador retoma o rascunho e conclui o envio, **When** o envio é bem-sucedido, **Then** a cópia local recuperável é removida automaticamente.

---

### Edge Cases

- Troca de usuário no mesmo navegador: rascunho local de um operador **não** deve ser oferecido a outro operador após login (escopo por identidade autenticada e instituição/tenant).
- Troca de instituição (tenant) na mesma sessão ou após login: rascunho de outro tenant **não** aparece.
- Dois rascunhos: apenas o **último** trabalho não enviado é promovido no convite da lista (não histórico de múltiplos rascunhos locais na v1).
- Rascunho já persistido no servidor (linha “Rascunho” na tabela) **e** cópia local mais recente: a cópia local **sempre prevalece** como fonte de retomada pelo convite — ela é gravada com frequência maior que o rascunho institucional e reflete o estado mais próximo do momento da falha. Ao retomar, o conteúdo local é exibido no assistente e, no envio final, atualiza o mesmo registro institucional (quando existir referência), sem criar duplicata.
- Manifestação confirmada enquanto o operador ainda tinha aba antiga do assistente: ao tentar continuar, o sistema informa que o envio já foi feito e não permite novo envio duplicado.
- Campos inválidos após mudança de catálogo (assunto/forma removidos): retomada exibe aviso e exige correção antes do envio.
- Limite de retenção: o último rascunho local expira automaticamente **24 horas** após a última gravação; passado esse prazo, deixa de ser oferecido pelo convite e a cópia é descartada.
- Anexos adicionados no assistente: o rascunho recuperável **inclui** os arquivos já anexados no dispositivo, mesmo que ainda não tenham sido enviados ao servidor no momento da falha, para que fiquem disponíveis novamente ao retomar — sujeito a um **limite explícito** de tamanho/quantidade (valor exato definido em `/speckit-plan`); anexos que excedam o limite não entram na cópia local e precisam ser reanexados manualmente ao retomar.
- Falha técnica na consulta de retomabilidade (ex.: instabilidade pontual da API, mesmo com o operador já autenticado) — **não** é a mesma coisa que "envio já confirmado": o sistema trata a falha de forma conservadora, ocultando o convite até uma verificação bem-sucedida em oportunidade subsequente (ex.: próxima carga da lista), sem exigir ação manual além de recarregar a página.
- Canal público de ouvidoria (cidadão) permanece **fora** do escopo — apenas fluxo autenticado interno em `/ouvidoria/manifestacoes/nova`.
- Edição de manifestação existente (`/manifestacoes/:id/editar`) **fora** do escopo inicial — foco em **criação** nova interrompida.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Durante o preenchimento do assistente de **nova** manifestação ouvidoria, o sistema DEVE persistir automaticamente o estado recuperável do formulário (campos e etapa atual) no dispositivo do operador a cada mudança relevante de campo **ou** no máximo a cada **5 segundos** como salvaguarda (o que ocorrer primeiro), além de sempre ao mudar de etapa — independentemente de sucesso das operações remotas de gravação.
- **FR-002**: O estado recuperável DEVE estar associado à identidade do operador autenticado e à instituição (tenant) ativa, e NÃO DEVE ser exposto a outros operadores ou tenants.
- **FR-003**: Na lista de manifestações (`/ouvidoria/manifestacoes`), quando existir um último rascunho local elegível, o sistema DEVE exibir um acesso dedicado **acima da tabela** (antes das linhas de dados), com texto que deixe claro que há trabalho não enviado e ação para retomar.
- **FR-004**: Ao acionar o acesso da lista, o operador DEVE ser levado ao assistente de nova manifestação com campos e etapa restaurados conforme a última gravação local automática.
- **FR-005**: O sistema DEVE oferecer apenas **um** último rascunho recuperável por operador e tenant na interface da lista (o mais recente localmente); iniciar novo preenchimento substitui o anterior ou exige confirmação explícita quando houver risco de perda de trabalho não enviado.
- **FR-006**: O backend DEVE expor uma forma autorizada de consultar, para o operador autenticado, se um rascunho referenciado (por identificador opaco vinculado ao registro quando existir) ainda está em estado **retomável** (rascunho não confirmado) ou se o envio final já ocorreu / o registro não existe mais / não pertence ao operador ou tenant.
- **FR-007**: Quando a consulta do FR-006 indicar que o envio já foi concluído ou que não há rascunho retomável no servidor, a interface DEVE **ocultar** o convite de último rascunho e DEVE remover ou invalidar a cópia local associada.
- **FR-008**: Após confirmação final bem-sucedida do envio no assistente, o sistema DEVE eliminar o rascunho local recuperável relacionado a esse trabalho.
- **FR-009**: O operador DEVE poder descartar explicitamente o último rascunho recuperável; após descarte, o convite na lista DEVE desaparecer. Ao iniciar uma nova manifestação havendo qualquer dado não vazio no rascunho local (qualquer campo preenchido), o sistema DEVE exigir confirmação explícita antes de descartá-lo.
- **FR-010**: Se o operador tentar retomar um rascunho cujo envio já foi confirmado (inconsistência entre cópia local e estado real), o sistema DEVE impedir reenvio duplicado e orientar o operador (mensagem clara, sem expor detalhes técnicos).
- **FR-011**: A recuperação DEVE cobrir os mesmos campos de negócio já coletados no assistente de criação (tipo, assunto, relato, dados do manifestante, endereço, prioridade, emissor quando aplicável, etapa do assistente) **e** os arquivos já anexados no dispositivo, incluindo os que ainda não haviam sido enviados ao servidor no momento da falha.
- **FR-012**: Enquanto o servidor estiver disponível após retomada, o fluxo DEVE permitir sincronizar o conteúdo recuperado (incluindo anexos pendentes de envio) com o registro de rascunho institucional existente ou criar um novo registro de rascunho, antes ou durante a confirmação final, sem perda dos dados já digitados.
- **FR-013**: O canal público de manifestação do cidadão e fluxos de edição de manifestação já existente (fora de “nova”) estão **fora** do escopo desta feature na v1.
- **FR-014**: Quando existir simultaneamente um rascunho institucional já persistido no servidor e uma cópia local do mesmo trabalho, o sistema DEVE priorizar a cópia local como fonte de retomada (ela é a mais atual), atualizando o registro institucional correspondente no envio final em vez de criar um registro duplicado.
- **FR-015**: O último rascunho local DEVE expirar automaticamente **24 horas** após a última gravação; passado esse prazo, o convite na lista NÃO DEVE mais oferecer sua retomada, e a cópia expirada DEVE ser descartada.
- **FR-016**: Se a consulta de retomabilidade (FR-006) falhar por erro técnico (timeout, indisponibilidade momentânea, etc.) sem confirmar de forma clara que o rascunho ainda é retomável, o sistema DEVE tratar o resultado como não confirmado e **ocultar** o convite de último rascunho até que uma verificação subsequente seja concluída com sucesso, sem exigir ação manual do operador além de recarregar a lista.
- **FR-017**: O rascunho local DEVE aplicar um limite explícito de tamanho/quantidade de anexos armazenados localmente (valor exato a ser definido em `/speckit-plan`, considerando limites práticos de armazenamento do navegador); anexos que excedam o limite NÃO DEVEM ser incluídos na cópia local recuperável, e o operador DEVE ser avisado de que precisará reanexá-los manualmente ao retomar.

### Key Entities

- **Último rascunho local**: Cópia recuperável do trabalho em andamento no assistente de nova manifestação, gravada no dispositivo, com carimbo de atualização, etapa do assistente, identidade do operador, tenant e, quando existir, referência opaca ao registro institucional de rascunho no servidor.
- **Registro de manifestação em rascunho (institucional)**: Manifestação já criada no sistema com status de rascunho, editável pelo fluxo atual — distinto da cópia local, mas pode ser vinculada por referência opaca.
- **Estado de retomabilidade**: Resultado da validação no servidor que indica se um rascunho referenciado ainda pode ser continuado ou se o envio final já encerrou essa possibilidade.
- **Convite na lista**: Elemento de interface acima da tabela de manifestações que agrega último rascunho local elegível e ações retomar / descartar (ou equivalente).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Em testes de aceitação simulando queda de sessão ou indisponibilidade remota **antes** da confirmação final, 100% dos casos com dados preenchidos recuperam o conteúdo essencial do formulário via convite na lista, sem redigitar do zero.
- **SC-002**: Em 100% dos casos em que a manifestação já foi confirmada/enviada, o convite de último rascunho **não** aparece na lista após a próxima carga autorizada da página.
- **SC-003**: Operadores concluem retomada (lista → assistente com dados restaurados) em menos de 1 minuto em condições normais de uso.
- **SC-004**: Zero casos de teste em que um operador B visualiza ou retoma rascunho local gravado pelo operador A no mesmo dispositivo.
- **SC-005**: Redução mensurável (baseline a definir no plano) de relatos refeitos do zero por “perdi o que estava digitando” no módulo ouvidoria, medida por feedback interno ou proxy de abandono no assistente — meta aspiracional documentada no acompanhamento pós-implantação.

## Assumptions

- O fluxo alvo é o assistente autenticado de **nova** manifestação interna (`/ouvidoria/manifestacoes/nova`), já existente no produto, que hoje pode gravar rascunho institucional quando a comunicação com o servidor funciona; esta feature **complementa** essa gravação remota com resiliência local.
- “Envio concluído” significa a confirmação final do registro no fluxo de negócio (manifestação deixa de ser rascunho editável), não apenas salvar etapas intermediárias.
- Um único slot de “último rascunho” por operador e tenant é suficiente na v1; histórico de vários rascunhos abandonados fica fora de escopo.
- A persistência local é **por navegador/dispositivo**; sincronização entre dispositivos diferentes do mesmo operador não é exigida na v1.
- Permissões de acesso ao módulo ouvidoria e à criação de manifestações permanecem as mesmas; operadores sem permissão não veem o convite.
- Textos e padrões de alerta seguem vocabulário institucional da plataforma (imperativo claro, sem jargão técnico de “token” ou “localStorage” na interface).
- Conflito local vs. institucional: a cópia local sempre prevalece como fonte de retomada (decisão validada com o usuário em `/speckit-specify`).
- Retenção do rascunho local: 24 horas após a última gravação (decisão validada com o usuário em `/speckit-specify`).
- Anexos: incluídos integralmente no rascunho recuperável, mesmo os ainda não enviados ao servidor (decisão validada com o usuário em `/speckit-specify`); o mecanismo de armazenamento local desses arquivos é detalhe de implementação a resolver em `/speckit-plan`.
