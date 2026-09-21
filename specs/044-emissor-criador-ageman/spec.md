# Feature Specification: Emissor automático ao criar demanda AGEMAN

**Feature Branch**: `044-emissor-criador-ageman`

**Created**: 2026-09-14

**Status**: Draft

**Input**: User description: "tipo: refact — refatorar logica emissor criar demanda ageman. atualmente há um select para selecionar o emissor ageman. o cliente pediu para sempre colocar a pessoa que criou como emissor, retirando a obrigatoriedade de clique e selecionar quem é."

## Clarifications

### Session 2026-09-14

- Q: Quando o criador não é um usuário institucional cadastrado (ex.: administrador da instituição), o que deve acontecer com o emissor? → A: O campo de emissor continua aparecendo no formulário, mas já vem com o nome do próprio criador pré-selecionado/marcado como opção padrão no form data — sem exigir clique para enviar assim, podendo ser trocado se necessário.
- Q: Depois de gravada, o emissor pode ser alterado (ex.: na edição)? → A: Não — o emissor é imutável após a criação, sem mecanismo de edição posterior.
- Q: Como o emissor aparece no formulário de criação para um operador institucional comum? → A: Somente leitura, mostrando o nome de quem está autenticado, sem opção de escolha.
- Q: O fluxo de criação salva rascunho e permite atualizações parciais antes da confirmação final — quando exatamente o emissor passa a ser imutável? → A: Só após a confirmação final. Durante as atualizações intermediárias do rascunho, o emissor ainda pode ser recalculado (segue automaticamente quem está tocando o rascunho, sem seleção manual).
- Q: O administrador da instituição não é um usuário cadastrado no quadro de operadores — o que deve ser de fato gravado como emissor quando ele cria a demanda? → A: O emissor fica vazio; a identidade real do administrador é registrada apenas em auditoria interna (não como emissor visível). No formulário, a opção padrão pré-marcada é visual (representa "eu mesmo", sem corresponder a um usuário cadastrado); se ele confirmar sem trocar, o sistema grava emissor vazio. Se ele trocar para um operador institucional real da lista, esse operador é gravado como emissor.
- Q: Se uma requisição de um operador institucional trouxer um emissor diferente do autenticado, o que o sistema deve fazer? → A: Ignorar o valor enviado e sempre gravar o autenticado, sem retornar erro de validação (defesa em profundidade silenciosa, já que a interface não expõe outro valor para esse ator).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Operador institucional cria demanda sem selecionar emissor (Priority: P1)

Um operador institucional da AGEMAN (usuário cadastrado no quadro de usuários) abre o fluxo de criação de uma nova demanda/manifestação interna. Ele preenche os dados do caso (tipo, assunto, texto, etc.) e conclui o registro. O campo Emissor aparece somente leitura, já mostrando o nome de quem está autenticado — não há lista para clicar e escolher outra pessoa.

**Why this priority**: É o pedido explícito do cliente — eliminar o clique obrigatório de seleção e garantir que o emissor seja sempre quem criou, para o caso mais comum (operador institucional).

**Independent Test**: Um operador autenticado cria uma demanda sem interagir com qualquer controle de emissor; ao abrir o detalhe, o emissor exibido é o próprio operador.

**Acceptance Scenarios**:

1. **Given** um operador institucional autenticado no fluxo de criação de demanda interna AGEMAN, **When** ele conclui o registro, **Then** a demanda fica com o próprio operador como emissor, sem que ele tenha clicado em nenhum seletor.
2. **Given** o operador está no formulário de criação, **When** ele visualiza o campo Emissor, **Then** o campo é somente leitura e mostra o nome de quem está autenticado — nenhuma lista de opções é aberta.
3. **Given** a demanda foi criada, **When** qualquer usuário autorizado abre o detalhe, **Then** o campo Emissor mostra o nome da pessoa que criou o registro.

---

### User Story 2 - Administrador da instituição cria demanda com emissor pré-selecionado (Priority: P2)

Um administrador da instituição, que não é um usuário cadastrado no quadro de operadores institucionais, também pode criar demandas AGEMAN. Como ele não tem vínculo de usuário real, o campo Emissor continua aparecendo como uma seleção — mas já chega com uma opção padrão pré-marcada ("eu mesmo", visual, sem corresponder a um usuário cadastrado), dispensando qualquer clique para enviar assim. Se ele confirmar sem trocar, o emissor é gravado vazio (a identidade real do administrador fica registrada apenas por auditoria interna). Se necessário, ele ainda pode trocar a seleção por um operador institucional real da lista antes de enviar.

**Why this priority**: Cobre o ator que cria demandas sem ter registro de operador institucional — sem essa regra, o formulário exigiria um clique obrigatório também para ele, contrariando o pedido do cliente.

**Independent Test**: Autenticado como administrador da instituição, abrir o formulário de criação e confirmar que o campo Emissor já está pré-marcado com a opção padrão "eu mesmo", permitindo enviar sem qualquer clique nesse campo; confirmar que o registro resultante fica com emissor vazio e a identidade real preservada em auditoria.

**Acceptance Scenarios**:

1. **Given** um administrador da instituição autenticado no fluxo de criação, **When** ele abre o formulário, **Then** o campo Emissor já aparece com a opção padrão "eu mesmo" pré-selecionada.
2. **Given** o campo Emissor está com a opção padrão pré-marcada, **When** ele conclui o envio sem alterar nada, **Then** a demanda é gravada com o emissor vazio, e a identidade real do administrador é registrada apenas por auditoria (não aparece como emissor no detalhe).
3. **Given** o administrador decide indicar um operador institucional real, **When** ele troca a seleção antes de enviar, **Then** a demanda é gravada com esse operador como emissor.

---

### User Story 3 - Consultar o emissor no detalhe (Priority: P2)

Quem abre o detalhe de uma demanda AGEMAN continua vendo quem é o emissor, agora correspondente à pessoa que criou o registro (para demandas novas após esta mudança), sem possibilidade de alteração posterior.

**Why this priority**: O valor operacional do campo permanece (auditoria / identificação de quem registrou); só muda a forma de preenchimento e a impossibilidade de edição depois.

**Independent Test**: Abrir o detalhe de uma demanda criada após a mudança e confirmar que o emissor visível é o criador, e que não há ação de edição disponível para esse campo.

**Acceptance Scenarios**:

1. **Given** uma demanda criada após esta mudança por um operador institucional, **When** o detalhe é aberto, **Then** o Emissor exibe o nome do criador (não vazio e não outra pessoa).
2. **Given** uma demanda **confirmada** (registro finalizado) após esta mudança, **When** o usuário procura uma forma de editar o emissor, **Then** não existe tal ação disponível — o campo é imutável a partir da confirmação.
3. **Given** uma demanda antiga cujo emissor já estava preenchido (possivelmente outra pessoa, escolhida manualmente antes desta mudança), **When** o detalhe é aberto, **Then** o emissor histórico permanece como estava — esta feature não reescreve registros existentes.

---

### Edge Cases

- Demandas já existentes com emissor diferente do criador **não** são alteradas por esta mudança.
- Manifestação originada pelo **canal público** (cidadão) está fora desta mudança: o cidadão não é "emissor institucional"; o fluxo interno de criação é o alvo.
- Se a sessão expirar no meio da criação, o registro não é gravado e portanto não há emissor órfão.
- Para o administrador da instituição, se ele trocar a seleção padrão para outra pessoa e depois quiser desfazer, ele precisa selecionar novamente a si próprio antes de enviar — o sistema não impede a troca nesse caso específico (ver User Story 2).
- Durante o rascunho (antes da confirmação final do formulário em etapas), o emissor pode ser recalculado a cada atualização intermediária — não é considerado "edição manual", apenas a mesma regra automática (FR-002/FR-004) reaplicada.
- A partir da confirmação final, não existe fluxo de edição que permita trocar o emissor — nem para o próprio criador, nem para administradores.
- Quando o administrador da instituição confirma sem trocar a opção padrão, o emissor fica **vazio** no detalhe (diferente do caso do operador institucional, que sempre tem emissor preenchido) — a identidade real permanece disponível apenas via auditoria interna, não como emissor visível.
- Se uma tentativa fora do fluxo normal de interface enviar, para um operador institucional, um emissor diferente do autenticado, o sistema ignora esse valor e grava o autenticado — sem retornar erro de validação por esse motivo.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Ao criar uma demanda/manifestação interna AGEMAN, o sistema DEVE atribuir automaticamente como emissor a pessoa autenticada que está criando o registro, salvo troca explícita no caso do FR-004.
- **FR-002**: Quando o criador for um operador institucional (usuário cadastrado no quadro de operadores), o campo Emissor DEVE ser exibido somente leitura, com o nome de quem está autenticado, sem lista para clicar e escolher outra pessoa.
- **FR-003**: Para um operador institucional, o sistema DEVE ignorar/sobrescrever silenciosamente qualquer emissor informado na requisição que seja diferente do autenticado, sempre gravando o autenticado — sem retornar erro de validação por esse motivo.
- **FR-004**: Quando o criador não for um operador institucional cadastrado (ex.: administrador da instituição), o campo Emissor DEVE ser exibido como seleção, com uma opção padrão pré-marcada representando "eu mesmo" (visual, sem corresponder a um usuário cadastrado), permitindo concluir o envio sem nenhum clique nesse campo. Se confirmado sem troca, o sistema DEVE gravar o emissor vazio e registrar a identidade real do criador apenas em auditoria interna (não como emissor visível). Se o criador trocar a seleção para um operador institucional real, o emissor DEVE ser gravado com essa pessoa.
- **FR-005**: O detalhe da demanda DEVE continuar exibindo o emissor quando houver um vinculado.
- **FR-006**: Enquanto a demanda estiver em rascunho (formulário em etapas não confirmado), o emissor PODE ser recalculado automaticamente a cada atualização intermediária (sempre seguindo a regra de FR-002/FR-004, nunca por seleção manual livre). A partir da confirmação final, o emissor DEVE se tornar imutável — não deve existir nenhum mecanismo de edição do emissor em telas de atualização de demanda já confirmada.
- **FR-007**: Demandas já existentes NÃO DEVEM ter o emissor recalculado ou sobrescrito por esta mudança.
- **FR-008**: O canal público de ouvidoria (cidadão) está fora do escopo — esta regra vale apenas para a criação interna de demanda AGEMAN.

### Key Entities

- **Demanda / Manifestação AGEMAN**: Registro interno criado pela equipe, com um estágio de **rascunho** (formulário em etapas em andamento, aceita atualizações parciais) antes da **confirmação final**. Possui um **emissor** (quem registrou institucionalmente, em nome do manifestante) e um **criador** (quem autenticou a ação de criar). Após esta mudança, coincidem por padrão; o emissor pode ser recalculado automaticamente durante o rascunho, mas se torna imutável a partir da confirmação final.
- **Emissor**: Pessoa institucional associada à demanda como quem a emitiu/registrou (pode ficar vazio quando o criador não é um operador institucional cadastrado). Recalculado automaticamente durante o rascunho; imutável a partir da confirmação final.
- **Operador institucional**: Usuário autenticado da equipe (operador, chefe de setor, etc.), cadastrado no quadro de usuários. Para ele, o emissor é sempre e automaticamente ele próprio, sem seleção.
- **Administrador da instituição**: Ator autenticado que pode operar o tenant, mas não está cadastrado no mesmo quadro de operadores institucionais. Para ele, o campo Emissor vem com uma opção padrão pré-marcada ("eu mesmo", visual); se confirmado sem troca, o emissor é gravado vazio e a identidade real fica registrada apenas em auditoria interna; se ele trocar para um operador real, esse operador é gravado como emissor.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Em 100% das novas demandas internas AGEMAN criadas por operador institucional, o emissor gravado é a pessoa que criou — sem nenhum clique no campo Emissor.
- **SC-002**: Um operador institucional consegue concluir a criação sem interagir com qualquer controle de escolha de emissor (zero cliques nesse campo).
- **SC-003**: Um administrador da instituição consegue concluir a criação sem interagir com o campo Emissor (aceitando o padrão pré-marcado, que resulta em emissor vazio + registro de auditoria da identidade real), e também consegue selecionar um operador institucional real quando desejar, antes de enviar.
- **SC-004**: Nenhum teste de aceitação da criação consegue gravar, para um operador institucional, emissor diferente do criador autenticado — mesmo enviando outro valor diretamente na requisição, o resultado gravado é sempre o autenticado, sem erro de validação retornado por esse motivo.
- **SC-005**: Nenhuma tela de edição de demanda já **confirmada** (registro finalizado) expõe uma forma de alterar o emissor; antes da confirmação, o emissor segue sendo recalculado automaticamente pela mesma regra da criação.
- **SC-006**: Demandas criadas antes da mudança mantêm o emissor que já tinham (0 registros históricos alterados).
- **SC-007**: Quem abre o detalhe de uma demanda nova criada por operador institucional identifica o emissor (nome da pessoa) sem consultar outra tela; quando criada por administrador da instituição sem troca de seleção, o emissor aparece vazio, e a identidade real do criador permanece disponível via auditoria interna (não nesta tela).

## Assumptions

- O pedido refere-se ao fluxo **interno** de criação de demanda/manifestação AGEMAN (equipe autenticada), não ao portal público do cidadão.
- "Pessoa que criou" = a pessoa autenticada no momento da criação (não o manifestante/cidadão relatado no caso).
- O campo Emissor continua existindo como informação de negócio/auditoria no detalhe; o que muda é a forma de preenchimento na criação (automático para operador institucional; pré-selecionado e ainda editável para administrador da instituição) e a impossibilidade de edição depois de gravado.
- Registros históricos não entram em migração nem correção em lote.
- Outros módulos (Gabinete, Autos, notificações) não são afetados.
- A lista de possíveis emissores (hoje usada pelo seletor) deixa de ser necessária em qualquer fluxo de **edição pós-confirmação** (o emissor é imutável a partir daí), mas continua sendo necessária na **criação** para o caso do administrador da instituição escolher um operador real, caso não queira deixar o emissor vazio (FR-004).
- Não há mudança na natureza do vínculo de emissor nesta feature: ele continua associado exclusivamente a operadores institucionais cadastrados. Quando o criador não se qualifica como tal (ex.: administrador da instituição), o emissor fica vazio e a identidade real é preservada apenas por auditoria interna, seguindo o padrão de rastreabilidade já existente no projeto para atores sem cadastro de operador.

## Out of Scope

- Recalcular ou corrigir emissor de demandas já existentes.
- Portal público de ouvidoria (cidadão).
- Alterar o significado de "manifestante" (cidadão/parte) — só o emissor institucional.
- Relatórios de gestão, listagens e filtros que já exibem emissor: permanecem; apenas a origem do valor na criação muda.
- Qualquer fluxo de edição manual do emissor após a confirmação final (removido/inexistente por definição desta feature) — o recálculo automático durante o rascunho não é considerado edição manual.
- Alterar a estrutura de dados do emissor para suportar administradores da instituição como vínculo direto — o emissor continua associado exclusivamente a operadores institucionais cadastrados.
