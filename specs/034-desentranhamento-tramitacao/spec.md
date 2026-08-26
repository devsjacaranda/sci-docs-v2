# Feature Specification: Desentranhamento de Documentos em Tramitação

**Feature Branch**: `034-desentranhamento-tramitacao`

**Created**: 2026-07-07

**Status**: Draft

**Input**: User description: "implementar desentranhamento em tramitação. Desentranhar documentos significa retirar fisicamente ou tornar indisponível no sistema peças ou arquivos juntados por engano, fora do prazo (intempestivos), ou que são considerados estranhos ao processo. Esse ato geralmente ocorre por determinação judicial ou mediante pedido das partes para preservar a organização e o andamento processual. Em algumas situações o usuário pode sem querer enviar um documento errado. Mas não podemos simplesmente apagar, deve-se solicitar desentranhamento à pessoa que enviou. Ação: o documento será marcado como desentranhado, mas ainda poderá ser acessado no histórico."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Solicitar desentranhamento de documento próprio enviado por engano (Priority: P1)

Um usuário que anexou um documento a uma demanda de tramitação percebe que enviou o arquivo errado (duplicado, fora de prazo, ou sem relação com o processo) e quer retirá-lo da visualização normal. Como ele mesmo é o autor do documento, ele abre a solicitação de desentranhamento; a outra parte da tramitação (quem está do lado receptor da demanda no momento) decide aprovar ou rejeitar o pedido.

**Why this priority**: É o caso de uso central descrito pelo negócio — o "engano no envio" é o gatilho mais comum e deve funcionar de ponta a ponta (solicitar → decidir → refletir no anexo) para o MVP ter valor.

**Independent Test**: Pode ser testado integralmente anexando um documento a uma demanda aberta, solicitando o desentranhamento como autor, aprovando como a contraparte, e confirmando que o anexo some da listagem normal mas continua acessível no histórico para quem já tinha acesso.

**Acceptance Scenarios**:

1. **Given** um anexo (arquivo ou link) juntado por um usuário em uma demanda de tramitação **não arquivada**, **When** esse mesmo usuário (autor do anexo) solicita o desentranhamento, **Then** o sistema cria um pedido de desentranhamento pendente vinculado ao anexo e registra um evento na timeline da demanda.
2. **Given** um pedido de desentranhamento pendente onde o solicitante é o autor do documento, **When** um usuário do lado receptor da demanda (contraparte) aprova o pedido, **Then** o anexo é marcado como desentranhado, deixa de aparecer na listagem normal de anexos, e um evento de aprovação é registrado na timeline.
3. **Given** um pedido de desentranhamento pendente, **When** a contraparte rejeita o pedido, **Then** o anexo permanece normalmente juntado e visível, e um evento de rejeição é registrado na timeline.
4. **Given** um anexo já marcado como desentranhado, **When** um usuário que tinha acesso original ao anexo (autor, ou participante com permissão de acesso quando o anexo era confidencial, ou admin_tenant/admin_saas) consulta o histórico da demanda, **Then** ele consegue visualizar e acessar o conteúdo do anexo desentranhado, com indicação visual de que foi desentranhado.

---

### User Story 2 - Solicitar desentranhamento de documento recebido considerado indevido (Priority: P2)

Um usuário do lado receptor de uma demanda recebe um documento que considera juntado por engano, fora de prazo, ou estranho ao processo (ex.: peça de outro assunto). Ele solicita o desentranhamento ao autor do documento, que decide aprovar ou rejeitar.

**Why this priority**: Espelha o mesmo mecanismo da User Story 1, mas com os papéis de solicitante/aprovador invertidos (fluxo bidirecional). É necessário para cobrir o cenário descrito no contexto de negócio ("por pedido das partes"), mas depende da mesma base técnica da P1.

**Independent Test**: Pode ser testado anexando um documento por um usuário, e solicitando o desentranhamento como um usuário do lado receptor (não autor); o autor original deve conseguir aprovar ou rejeitar o pedido.

**Acceptance Scenarios**:

1. **Given** um anexo juntado por um usuário A em uma demanda não arquivada, **When** um usuário do lado receptor da demanda (que não é o autor do anexo) solicita o desentranhamento, **Then** o sistema cria um pedido pendente e notifica o autor do anexo (usuário A).
2. **Given** esse pedido pendente, **When** o autor do anexo (usuário A) aprova, **Then** o anexo é marcado como desentranhado.
3. **Given** esse pedido pendente, **When** o autor do anexo (usuário A) rejeita, **Then** o anexo permanece normalmente juntado.

---

### User Story 3 - Ser notificado sobre pedidos de desentranhamento (Priority: P3)

Qualquer usuário que precise decidir sobre um pedido de desentranhamento (seja o autor do documento, seja um membro do setor receptor da demanda) recebe uma notificação in-app avisando que há um pedido pendente aguardando sua decisão, podendo navegar diretamente até a demanda/anexo em questão.

**Why this priority**: Sem notificação, os pedidos ficam "escondidos" dentro da demanda e dependem do usuário abrir a tela manualmente — é uma melhoria de usabilidade sobre o fluxo básico das User Stories 1 e 2, que já funcionam sem ela.

**Independent Test**: Pode ser testado solicitando um desentranhamento e verificando que o(s) usuário(s) aptos a decidir recebem uma notificação in-app com link para a demanda.

**Acceptance Scenarios**:

1. **Given** um pedido de desentranhamento recém-criado, **When** o sistema processa a solicitação, **Then** todo usuário apto a decidir (autor do documento ou membros do setor/contraparte atual, conforme o caso) recebe uma notificação in-app referenciando a demanda e o anexo.
2. **Given** um pedido de desentranhamento decidido (aprovado ou rejeitado), **When** a decisão é registrada, **Then** o usuário que solicitou o pedido recebe uma notificação in-app informando o resultado.

### Edge Cases

- O que ocorre se o usuário solicitar o desentranhamento de um anexo que já possui um pedido pendente? O sistema deve bloquear a criação de um novo pedido enquanto houver um pedido pendente para o mesmo anexo, informando que já existe solicitação em aberto.
- O que ocorre se a demanda for arquivada enquanto um pedido de desentranhamento está pendente? A decisão sobre pedidos já abertos antes do arquivamento continua permitida (para não deixar pedidos "travados"), mas nenhuma nova solicitação pode ser aberta em demandas arquivadas.
- O que ocorre se mais de uma pessoa do lado aprovador tentar decidir o mesmo pedido ao mesmo tempo (ex.: dois membros do setor receptor)? A primeira decisão registrada (aprovação ou rejeição) resolve o pedido; tentativas de decisão subsequentes sobre o mesmo pedido devem ser rejeitadas pelo sistema com uma mensagem indicando que o pedido já foi decidido.
- O que ocorre se o autor do documento solicitar o desentranhamento, mas não houver nenhum outro participante do lado receptor no momento (ex.: demanda ainda não encaminhada a nenhum setor/usuário)? A solicitação não pode ser criada nesse caso, pois não há contraparte apta a decidir; o sistema deve informar essa restrição ao usuário.
- O que ocorre com um pedido de desentranhamento pendente para um anexo que é excluído por outro fluxo (soft-delete already existente, se algum dia implementado)? Fora de escopo desta feature — não existe hoje endpoint de exclusão de anexo; se vier a existir, deve invalidar pedidos pendentes associados.
- O que ocorre com anexos confidenciais (feature 033) que são desentranhados? A regra de acesso por confidencialidade (ACL) continua valendo — o desentranhamento apenas soma uma condição adicional de visibilidate (ver FR-011); não amplia nem reduz quem tinha acesso ao conteúdo confidencial antes do pedido.
- O que ocorre se o solicitante tentar solicitar desentranhamento do próprio pedido já rejeitado anteriormente? Um novo pedido pode ser aberto normalmente após uma rejeição (não há limite de tentativas nesta versão).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: O sistema DEVE permitir que qualquer usuário com acesso a uma demanda de tramitação (não arquivada) solicite o desentranhamento de um anexo (arquivo ou link) dessa demanda, seja ele o autor do documento ou um participante do lado receptor.
- **FR-002**: Ao solicitar o desentranhamento, o sistema DEVE aceitar um motivo/justificativa em texto livre, sendo esse campo **opcional**.
- **FR-003**: O sistema DEVE determinar automaticamente quem pode decidir (aprovar/rejeitar) cada pedido, com base em quem é o solicitante:
  - Se o solicitante é o **autor** do anexo, os aptos a decidir são os usuários do **lado receptor atual** da demanda no momento do pedido (qualquer membro do setor destinatário atual, em demandas setoriais; o outro usuário da conversa, em caixa pessoal).
  - Se o solicitante **não é** o autor do anexo, o apto a decidir é o **próprio autor** do anexo.
- **FR-004**: O sistema DEVE impedir a criação de uma nova solicitação de desentranhamento para um anexo que já possua uma solicitação com status pendente.
- **FR-005**: O sistema DEVE impedir a criação de uma solicitação de desentranhamento quando não houver nenhum usuário apto a decidir (ex.: autor solicitando sem contraparte definida na demanda).
- **FR-006**: O sistema DEVE permitir que um usuário apto a decidir aprove ou rejeite um pedido pendente, podendo informar um motivo, sendo esse campo **opcional** em ambos os casos.
- **FR-007**: Quando um pedido é **aprovado**, o sistema DEVE marcar o anexo correspondente como **desentranhado**, e esse anexo DEVE deixar de aparecer nas listagens normais de anexos da demanda.
- **FR-008**: Quando um pedido é **rejeitado**, o anexo DEVE permanecer normalmente juntado e visível, sem qualquer alteração de estado.
- **FR-009**: Quando mais de um usuário está apto a decidir o mesmo pedido, o sistema DEVE aplicar a regra de "primeira decisão vale": a primeira decisão registrada (aprovação ou rejeição) resolve definitivamente o pedido, e qualquer tentativa posterior de decidir o mesmo pedido DEVE ser rejeitada com uma mensagem informando que já foi decidido.
- **FR-010**: O sistema DEVE registrar cada etapa do fluxo (solicitação, aprovação, rejeição) como um evento na timeline da demanda, incluindo autor da ação, data/hora e motivo informado (se houver).
- **FR-011**: Um anexo marcado como desentranhado DEVE continuar acessível — fora das listagens normais, em uma visualização de histórico — apenas para usuários que já teriam acesso ao seu conteúdo antes do desentranhamento: o autor do anexo, participantes com permissão de acesso concedida (quando o anexo é confidencial, conforme regras da feature de confidencialidade já existente), e usuários com papel `admin_tenant` ou `admin_saas`.
- **FR-012**: Usuários sem acesso original ao conteúdo do anexo (ex.: usuários sem permissão em anexo confidencial) NÃO DEVEM conseguir visualizar o conteúdo do anexo desentranhado no histórico, mesmo sabendo que ele existiu.
- **FR-013**: O sistema DEVE notificar (via canal de notificação in-app já existente) todo usuário apto a decidir, no momento em que um pedido de desentranhamento é criado.
- **FR-014**: O sistema DEVE notificar (via canal de notificação in-app já existente) o usuário que criou a solicitação, no momento em que o pedido é aprovado ou rejeitado.
- **FR-015**: O sistema DEVE restringir a criação de solicitações de desentranhamento a anexos pertencentes a demandas com status diferente de arquivada.
- **FR-016**: Decisões (aprovação/rejeição) sobre pedidos que já estavam pendentes antes de uma demanda ser arquivada DEVEM continuar permitidas.
- **FR-017**: O sistema DEVE exibir de forma clara, na interface de listagem e no histórico, que um anexo foi desentranhado, incluindo a informação de quando e por quem foi solicitado e decidido.

### Key Entities *(include if feature involves data)*

- **Solicitação de Desentranhamento**: Representa um pedido para retirar um documento/anexo da visualização normal de uma demanda de tramitação. Atributos principais: anexo referenciado, demanda referenciada, usuário solicitante, motivo (opcional), status (pendente, aprovado, rejeitado), usuário decisor, motivo da decisão (opcional), datas de criação e decisão.
- **Anexo (documento/peça já existente no domínio de Tramitação)**: Ganha um novo estado "desentranhado", que o remove das listagens padrão sem apagar seu conteúdo, preservando-o para consulta no histórico por quem já tinha acesso.
- **Evento de Timeline (já existente no domínio de Tramitação)**: Ganha novos tipos de evento para registrar solicitação, aprovação e rejeição de desentranhamento, mantendo o histórico auditável da demanda.
- **Notificação (já existente no domínio de Notificações)**: Ganha novos tipos para avisar sobre pedido pendente de desentranhamento e sobre o resultado da decisão.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Um usuário consegue solicitar o desentranhamento de um documento próprio enviado por engano em menos de 30 segundos, sem precisar contatar um administrador ou suporte técnico.
- **SC-002**: 100% dos anexos desentranhados deixam de aparecer nas listagens normais de anexos imediatamente após a aprovação do pedido, mas continuam recuperáveis no histórico por quem tinha acesso original.
- **SC-003**: 100% das decisões de desentranhamento (aprovação ou rejeição) ficam registradas de forma auditável na timeline da demanda, com autor e data/hora.
- **SC-004**: Usuários aptos a decidir um pedido de desentranhamento são notificados em até poucos segundos após a criação da solicitação, sem precisar checar manualmente cada demanda.
- **SC-005**: Nenhum documento é removido definitivamente do sistema por meio deste fluxo — 100% dos documentos desentranhados permanecem acessíveis a quem tinha acesso original, preservando o histórico do processo.

## Assumptions

- O fluxo de desentranhamento é **bidirecional**: tanto o autor de um documento quanto a contraparte da tramitação podem iniciar a solicitação; quem decide é sempre "o outro lado" em relação a quem solicitou.
- Em demandas setoriais, "o lado receptor atual" é definido como qualquer usuário membro do setor destinatário/atual da demanda no momento da solicitação (mesma lógica hoje usada para resolver quem recebe notificações de nova demanda/resposta).
- Em conversas de caixa pessoal (1:1), a contraparte é sempre o outro usuário participante da conversa.
- Não há necessidade de consenso entre múltiplos aprovadores: a primeira decisão registrada encerra o pedido, evitando decisões conflitantes.
- Motivo/justificativa é sempre opcional, tanto na solicitação quanto na decisão — o negócio não exige comprovação formal nesta versão.
- O desentranhamento se aplica tanto a anexos do tipo arquivo quanto do tipo link, mas apenas em demandas com status diferente de arquivada.
- O desentranhamento é uma ação reversível apenas no sentido de que o conteúdo nunca é apagado (fica acessível no histórico); esta versão não inclui um fluxo de "reverter" um desentranhamento já aprovado (fora de escopo — se necessário, pode ser tratado como uma nova feature).
- As regras de confidencialidade/ACL já existentes (feature de documentos confidenciais em tramitação) continuam sendo respeitadas integralmente; o desentranhamento não altera quem tem permissão de acesso a um anexo confidencial, apenas adiciona a condição de "documento desentranhado" às listagens.
- O canal de notificação in-app/WebSocket já existente no sistema será reaproveitado; não há requisito de notificação por e-mail nesta versão.
- Um documento "estranho ao processo" ou "juntado por engano" citado no contexto de negócio é tratado, no sistema, de forma genérica como qualquer anexo elegível a desentranhamento — o sistema não distingue automaticamente o motivo (engano, intempestividade, etc.), cabendo ao solicitante descrever isso no motivo opcional.
