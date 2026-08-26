# Feature Specification: Sistema de Notificações CI v2

**Feature Branch**: `029-notification-system`

**Created**: 2026-07-01

**Status**: Draft

**Input**: User description: "Desenvolver sistema de notificações CVv2 — adaptativo, suportando novos tipos de evento e linked records. Escopo inicial: apenas eventos de tramitação (nova demanda, resposta, encaminhamento). UI: sino com histórico + alerta temporário ao receber."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Receber alerta imediato de nova demanda na Tramitação (Priority: P1)

Como operador de um setor destinatário, quero ser avisado assim que uma nova demanda chegar ao inbox de Tramitação do meu setor, para responder sem depender de atualizar a página manualmente.

**Why this priority**: É o evento de maior impacto operacional — demandas paradas no inbox geram atraso institucional. Sem entrega em tempo real, o sistema de notificações não entrega valor central.

**Independent Test**: Pode ser validado enviando uma demanda para o setor do operador (genérica ou linked) e confirmando que o alerta aparece em segundos, com referência navegável à demanda, sem recarregar a aplicação.

**Acceptance Scenarios**:

1. **Given** operador autenticado com setor ativo e acesso ao módulo Tramitação, **When** uma nova demanda é endereçada ao seu setor, **Then** recebe alerta imediato com título, resumo e indicação de origem (tramitação).
2. **Given** alerta de nova demanda recebido, **When** o operador aciona o alerta ou a entrada correspondente no histórico, **Then** é direcionado ao detalhe da demanda na Tramitação.
3. **Given** operador sem permissão ao módulo Tramitação, **When** uma demanda é criada para seu setor, **Then** não recebe notificação relacionada à tramitação.

---

### User Story 2 - Consultar histórico no sino de notificações (Priority: P1)

Como operador institucional, quero ver no cabeçalho da aplicação um sino com contagem de não lidas e um painel com as notificações recentes, para retomar pendências que perdi enquanto estava ausente.

**Why this priority**: Complementa o alerta imediato — operadores precisam de memória persistente do que aconteceu, não apenas do último evento. É a superfície principal de consumo de notificações.

**Independent Test**: Pode ser validado gerando ao menos três notificações para o mesmo usuário, abrindo o sino e verificando badge, lista ordenada por recência, distinção lida/não lida e navegação ao clicar em um item.

**Acceptance Scenarios**:

1. **Given** notificações não lidas existentes, **When** o operador visualiza o cabeçalho, **Then** o sino exibe badge com a quantidade de não lidas (limitada visualmente quando acima de 99).
2. **Given** operador autenticado, **When** abre o painel do sino, **Then** vê lista das notificações mais recentes com título, texto resumido, horário relativo e indicador de lida/não lida.
3. **Given** painel do sino aberto, **When** seleciona uma notificação com registro vinculado, **Then** é direcionado ao contexto correto (ex.: detalhe da demanda na Tramitação) e a notificação passa a constar como lida.

---

### User Story 3 - Avisar remetente sobre resposta ou encaminhamento (Priority: P2)

Como operador que originou ou participou de uma demanda na Tramitação, quero ser notificado quando alguém responder ou encaminhar essa demanda, para acompanhar o andamento sem revisar o inbox constantemente.

**Why this priority**: Fecha o ciclo de comunicação inter-setorial — quem enviou precisa saber que houve movimentação. Menor urgência que nova demanda recebida, mas essencial para rastreabilidade operacional.

**Independent Test**: Pode ser validado respondendo ou encaminhando uma demanda existente e confirmando que o remetente original (exceto o próprio autor da ação) recebe notificação com referência à mesma demanda.

**Acceptance Scenarios**:

1. **Given** demanda criada pelo operador A, **When** operador B responde à demanda, **Then** operador A recebe notificação de resposta com referência à demanda.
2. **Given** demanda em tramitação, **When** operador B encaminha para outro setor, **Then** o remetente original recebe notificação de encaminhamento e operadores do novo setor destinatário recebem notificação de nova demanda (conforme US1).
3. **Given** operador A responde à própria demanda, **When** a resposta é registrada, **Then** operador A não recebe notificação redundante da própria ação.

---

### User Story 4 - Marcar notificações como lidas (Priority: P3)

Como operador com muitas notificações acumuladas, quero marcar uma notificação individual ou todas como lidas, para limpar o badge e focar apenas no que ainda exige atenção.

**Why this priority**: Higiene de inbox — necessário para uso contínuo, mas não bloqueia o valor inicial de receber e consultar alertas.

**Independent Test**: Pode ser validado gerando notificações não lidas, marcando uma como lida (badge decrementa) e usando "marcar todas como lidas" (badge zera).

**Acceptance Scenarios**:

1. **Given** notificação não lida, **When** o operador marca como lida sem navegar, **Then** o indicador de não lida desaparece e a contagem do badge é atualizada.
2. **Given** múltiplas notificações não lidas, **When** o operador aciona "marcar todas como lidas", **Then** todas passam a lidas e o badge zera.
3. **Given** notificação já lida, **When** o operador consulta o histórico, **Then** permanece lida e não incrementa novamente a contagem de não lidas.

---

### User Story 5 - Extensibilidade para novos módulos e tipos de evento (Priority: P4)

Como responsável de produto ou engenharia, quero que o sistema de notificações aceite novos tipos de evento e registros vinculados de qualquer módulo (ex.: futuro módulo "bolinhos de fubá"), sem redesenhar o modelo central, para escalar notificações além da Tramitação na v1.

**Why this priority**: Define a arquitetura de produto — garante que a v1 de tramitação seja um caso de uso do framework, não um acoplamento pontual. Prioridade menor porque o valor imediato vem das US1–US3.

**Independent Test**: Pode ser validado documentalmente e por contrato de dados: uma notificação de tramitação preenche os campos genéricos de origem (módulo, registro, tipo, snapshot) e um segundo tipo hipotético pode ser registrado sem alterar a entidade central.

**Acceptance Scenarios**:

1. **Given** evento de tramitação gerando notificação, **When** persistida, **Then** inclui identificação do módulo de origem, ID do registro, tipo do evento e snapshot resumido para exibição e navegação.
2. **Given** novo tipo de evento definido para outro módulo (fora do escopo v1), **When** registrado no catálogo de tipos, **Then** pode ser associado a notificações usando o mesmo modelo de registro vinculado, sem migração destrutiva do núcleo.
3. **Given** notificação com snapshot de origem, **When** o registro original for alterado ou removido depois, **Then** a notificação mantém os dados capturados no momento do evento para consulta histórica.

---

### Edge Cases

- Operador offline ou com sessão encerrada: notificações são persistidas e aparecem no sino ao reconectar ou no próximo login; alertas temporários não perdidos são recuperáveis via histórico.
- Perda momentânea de conexão em tempo real: ao restabelecer, o operador sincroniza notificações pendentes sem duplicar entradas visíveis.
- Operador pertencente a múltiplos setores: recebe notificações apenas dos eventos relevantes ao setor ativo ou aos setores aos quais tem acesso na Tramitação.
- Autor da ação não recebe notificação da própria ação (resposta, encaminhamento ou criação).
- Demanda ou registro de origem removido (soft delete): notificação permanece consultável com snapshot e indica limitação ao navegar para origem inexistente.
- Isolamento multi-tenant: operador de um tenant nunca visualiza notificações de outro tenant.
- Volume elevado de notificações: badge limita exibição (ex.: "99+"); painel do sino mostra lote recente sem degradar a experiência.
- Admin da instituição (`admin_tenant`) e operadores em tabela `User`: ambos podem ser destinatários quando atuam no fluxo institucional, respeitando permissões de módulo.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: O sistema DEVE entregar notificações em tempo real aos destinatários autenticados e autorizados, sem exigir atualização manual da página.
- **FR-002**: O sistema DEVE persistir cada notificação com: destinatário, tipo de evento, título, corpo/resumo, status lida/não lida, data de criação e metadados de registro vinculado quando aplicável.
- **FR-003**: O sistema DEVE exibir no cabeçalho um sino com badge de contagem de não lidas e painel dropdown com histórico recente.
- **FR-004**: O sistema DEVE exibir alerta temporário (toast) ao receber notificação em tempo real, com título e ação para abrir o contexto vinculado.
- **FR-005**: Ao criar demanda na Tramitação endereçada a um setor, o sistema DEVE notificar operadores elegíveis desse setor (tipo: nova demanda recebida).
- **FR-006**: Ao responder uma demanda na Tramitação, o sistema DEVE notificar o remetente original da thread, exceto quando o remetente é o próprio autor da resposta.
- **FR-007**: Ao encaminhar uma demanda na Tramitação, o sistema DEVE notificar o remetente original (encaminhamento) e operadores elegíveis do novo setor destinatário (nova demanda recebida).
- **FR-008**: Cada notificação de tramitação DEVE referenciar a demanda vinculada (módulo de origem `tramitacao`, identificador da demanda, tipo de evento e snapshot resumido para exibição).
- **FR-009**: O sistema DEVE permitir marcar notificação individual como lida e marcar todas as não lidas como lidas.
- **FR-010**: O sistema DEVE expor consulta de notificações do usuário autenticado (lista recente e contagem de não lidas) para suportar reconexão e carregamento inicial.
- **FR-011**: O sistema DEVE isolar notificações por tenant — nenhum destinatário acessa notificações de outra instituição.
- **FR-012**: O sistema DEVE respeitar permissões de módulo: destinatários sem acesso à Tramitação não recebem notificações de eventos de tramitação.
- **FR-013**: O modelo de notificação DEVE ser extensível por tipo de evento e registro vinculado polimórfico (`sourceModule`, `sourceRecordId`, `sourceType`, `sourceSnapshot`), permitindo que módulos futuros registrem novos eventos sem alterar o núcleo da entidade.
- **FR-014**: Tipos de evento na v1 DEVEM incluir, no mínimo: `tramitacao_nova_demanda`, `tramitacao_resposta`, `tramitacao_encaminhamento`.
- **FR-015**: Ao clicar em notificação com registro vinculado existente, o sistema DEVE navegar ao contexto correto (detalhe da demanda na Tramitação na v1).
- **FR-016**: Notificações duplicadas do mesmo evento para o mesmo destinatário DEVEM ser evitadas (idempotência por evento + destinatário).

### Key Entities

- **Notificação**: Aviso persistido entregue a um destinatário institucional. Atributos: destinatário, tenant, tipo, título, corpo, lida em (opcional), criada em, metadados de registro vinculado.
- **Tipo de Notificação**: Identificador extensível do evento de negócio (ex.: nova demanda, resposta, encaminhamento). Catálogo evolui sem quebrar notificações históricas.
- **Registro Vinculado (Linked Record)**: Referência polimórfica ao objeto de origem — módulo, ID do registro, subtipo do evento e snapshot imutável para exibição e navegação mesmo se o registro original mudar ou for removido.
- **Destinatário**: Operador institucional ou admin da instituição elegível pelo tenant, setor ativo e permissões de módulo.
- **Evento de Tramitação**: Ocorrência no módulo Tramitação que dispara notificação na v1 — criação de demanda, resposta ou encaminhamento.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Operador recebe alerta de nova demanda em até 5 segundos após a ação de criação/encaminhamento, em condições normais de conectividade.
- **SC-002**: 100% das notificações de tramitação na v1 incluem referência navegável à demanda correspondente quando o registro ainda existe.
- **SC-003**: Operador consegue identificar quantas notificações não lidas possui e abrir o histórico em no máximo 2 cliques a partir de qualquer tela autenticada.
- **SC-004**: Após reconexão ou novo login, 100% das notificações geradas enquanto offline permanecem visíveis no sino, sem perda de histórico recente.
- **SC-005**: Autor de uma ação de tramitação não recebe notificação redundante da própria ação em 100% dos cenários de teste definidos.
- **SC-006**: Adição de um novo tipo de evento (simulado em validação de contrato) não exige alteração destrutiva do modelo central de Notificação — apenas registro de novo tipo e integração do módulo emissor.

## Assumptions

- Escopo v1 limita **emissores** de notificação ao módulo Tramitação; a **arquitetura** suporta módulos futuros via registro vinculado polimórfico.
- Destinatários de "nova demanda" são operadores com acesso ao módulo Tramitação vinculados ao setor destinatário (ou regra equivalente já usada na inbox de Tramitação).
- Alerta temporário segue padrão visual da plataforma (toast não bloqueante, auto-dismiss para eventos não críticos).
- Painel do sino exibe lote recente (ex.: últimas 20–50 notificações); paginação completa ou página dedicada fica fora da v1.
- Entrega em tempo real na v1 opera em instância única; escalabilidade horizontal com broker compartilhado é evolução futura.
- Notificações existentes em domínios isolados (ex.: solicitações de permissão em `NotificacaoPermissao`) permanecem separadas — esta feature introduz sistema transversal unificado, com migração/consolidação opcional em fase posterior.
- Soft delete e isolamento multi-tenant seguem padrões já estabelecidos na plataforma CI v2.
- Idioma das notificações: português institucional, alinhado ao vocabulário de Tramitação já existente.

## Dependencies

- Módulo Tramitação operacional com criação de demanda, resposta e encaminhamento (specs anteriores, incluindo demandas linked).
- Autenticação e autorização multi-tenant, multi-setor e por módulo já disponíveis.
- Shell autenticado do client com cabeçalho global onde o sino será integrado.
- Permissões de módulo `tramitacao` configuradas nos tenants de validação.

## Out of Scope

- Notificações por e-mail, SMS ou push nativo mobile.
- Notificações emitidas por outros módulos na v1 (Ouvidoria, Jurídico, Gabinete, IT, etc.) — apenas arquitetura preparada.
- Evento de arquivamento de demanda como gatilho de notificação.
- Página dedicada de notificações com filtros avançados e paginação completa.
- Consolidação/migração imediata de `NotificacaoPermissao` e demais notificações legadas por domínio.
- Escalabilidade multi-instância com broker Redis ou fila de mensagens na v1.
- Preferências granulares por usuário (silenciar tipos, horários, canais).
- Sons, vibração ou integração com API de Notifications do navegador para alertas fora da aba.
