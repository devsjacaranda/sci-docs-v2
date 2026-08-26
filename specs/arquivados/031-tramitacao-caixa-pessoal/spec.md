# Feature Specification: Caixa Pessoal na TramitaÃ§Ã£o

**Feature Branch**: `031-tramitacao-caixa-pessoal`

**Created**: 2026-07-02

**Status**: Completed

**Tipo**: Feature

**MÃ³dulo**: TramitaÃ§Ã£o

**Input**: User description: "Implementar caixa pessoal no mÃ³dulo tramitaÃ§Ã£o. Atualmente sÃ³ Ã© possÃ­vel mandar mensagem de setor para outro setor. Cliente solicitou uma caixa pessoal, onde user pode mandar mensagem para outro user, sem compartilhar com outros usuÃ¡rios de seu setor."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Alternar entre inbox setorial e caixa pessoal (Priority: P1)

Como operador da TramitaÃ§Ã£o, quero alternar entre a visÃ£o **Setor** (comportamento atual) e a visÃ£o **Pessoal**, para gerenciar mensagens diretas sem misturÃ¡-las com a caixa do meu setor.

**Why this priority**: Sem o toggle e a inbox pessoal separada, a feature nÃ£o existe na interface â€” Ã© o ponto de entrada de toda a experiÃªncia.

**Independent Test**: Acessar TramitaÃ§Ã£o, alternar para Pessoal, verificar pastas Recebidas/Enviadas/Arquivadas filtradas pelo usuÃ¡rio logado (nÃ£o pelo setor ativo). Alternar de volta para Setor e confirmar que a inbox setorial permanece inalterada.

**Acceptance Scenarios**:

1. **Given** operador autenticado na TramitaÃ§Ã£o, **When** acessa a workspace de demandas, **Then** visualiza alternÃ¢ncia **Setor / Pessoal** com Setor selecionado por padrÃ£o.
2. **Given** operador na visÃ£o Pessoal, **When** consulta a inbox, **Then** visualiza pastas Recebidas, Enviadas e Arquivadas referentes apenas Ã s demandas pessoais em que participa (como remetente ou destinatÃ¡rio).
3. **Given** operador na visÃ£o Setor, **When** consulta a inbox, **Then** visualiza apenas demandas setoriais (comportamento atual) â€” demandas pessoais nÃ£o aparecem.
4. **Given** colega de setor do remetente ou destinatÃ¡rio, **When** consulta a inbox setorial ou pessoal prÃ³pria, **Then** nÃ£o visualiza demandas pessoais de terceiros.

---

### User Story 2 - Compor mensagem pessoal para outro operador (Priority: P1)

Como operador, quero compor uma mensagem pessoal escolhendo outro operador da instituiÃ§Ã£o como destinatÃ¡rio (qualquer setor), informando assunto e corpo, para comunicar assuntos privados sem expor colegas do meu setor.

**Why this priority**: Ã‰ a aÃ§Ã£o central solicitada pelo cliente â€” envio usuÃ¡rio-a-usuÃ¡rio cross-setor.

**Independent Test**: Compor mensagem pessoal de Operador A para Operador B (setores diferentes); confirmar protocolo automÃ¡tico, apariÃ§Ã£o em Enviadas de A e Recebidas de B; confirmar que colegas de A e B nÃ£o veem a demanda.

**Acceptance Scenarios**:

1. **Given** operador na visÃ£o Pessoal, **When** compÃµe nova mensagem selecionando destinatÃ¡rio, assunto e corpo, **Then** demanda pessoal Ã© criada com protocolo automÃ¡tico (TRAM-AAAA-NNNN) e aparece em Enviadas do remetente e Recebidas do destinatÃ¡rio.
2. **Given** lista de destinatÃ¡rios, **When** operador abre o seletor, **Then** visualiza operadores ativos da instituiÃ§Ã£o (qualquer setor), excluindo a si mesmo.
3. **Given** operador tenta enviar mensagem para si mesmo, **When** confirma composiÃ§Ã£o, **Then** sistema impede a aÃ§Ã£o com mensagem clara.
4. **Given** destinatÃ¡rio inativo ou removido, **When** operador tenta compor para esse usuÃ¡rio, **Then** destinatÃ¡rio nÃ£o aparece no seletor ou composiÃ§Ã£o Ã© rejeitada com mensagem clara.

---

### User Story 3 - Responder na thread privada (Priority: P1)

Como remetente ou destinatÃ¡rio de uma demanda pessoal, quero responder na thread de conversa, para manter diÃ¡logo privado entre nÃ³s dois sem visibilidade para o restante do setor.

**Why this priority**: Mensagem sem resposta Ã© unidirecional; a thread privada completa o ciclo de comunicaÃ§Ã£o pessoal.

**Independent Test**: Operador B responde demanda recebida de A; resposta aparece na timeline; A recebe alerta; colegas de A e B nÃ£o veem a demanda nem a resposta.

**Acceptance Scenarios**:

1. **Given** demanda pessoal aberta por participante (remetente ou destinatÃ¡rio), **When** escreve resposta, **Then** resposta Ã© adicionada Ã  thread e o outro participante Ã© notificado.
2. **Given** resposta registrada, **When** colega de setor de qualquer participante consulta inbox setorial ou pessoal prÃ³pria, **Then** nÃ£o visualiza a demanda nem eventos da thread.
3. **Given** terceiro tenta acessar demanda pessoal por identificador direto, **When** nÃ£o Ã© participante nem admin da instituiÃ§Ã£o, **Then** acesso Ã© negado sem revelar conteÃºdo ou metadados sensÃ­veis.

---

### User Story 4 - Encaminhar mensagem pessoal para outro operador (Priority: P2)

Como participante de uma demanda pessoal, quero encaminhar a conversa para outro operador da instituiÃ§Ã£o, para transferir a custÃ³dia pessoal mantendo o histÃ³rico na timeline.

**Why this priority**: Permite continuidade quando o assunto deve passar a outra pessoa, sem promover imediatamente a tramitaÃ§Ã£o setorial.

**Independent Test**: Participante encaminha demanda pessoal de B para C; C passa a ser destinatÃ¡rio; B deixa de ver a demanda nas pastas ativas; histÃ³rico de encaminhamento visÃ­vel na timeline para participantes atuais e admin da instituiÃ§Ã£o.

**Acceptance Scenarios**:

1. **Given** demanda pessoal aberta por participante, **When** encaminha para outro operador ativo com observaÃ§Ã£o opcional, **Then** novo destinatÃ¡rio recebe a demanda em Recebidas e evento de encaminhamento registra autor, destinatÃ¡rio anterior e novo destinatÃ¡rio.
2. **Given** encaminhamento concluÃ­do, **When** participante anterior consulta inbox pessoal, **Then** demanda nÃ£o aparece em Recebidas/Enviadas ativas (perde custÃ³dia pessoal).
3. **Given** encaminhamento concluÃ­do, **When** novo destinatÃ¡rio responde, **Then** apenas remetente original e novo destinatÃ¡rio participam da thread (participante intermediÃ¡rio sem acesso futuro).

---

### User Story 5 - Encaminhar mensagem pessoal para setor (Priority: P2)

Como participante de uma demanda pessoal, quero promover a conversa para tramitaÃ§Ã£o setorial escolhendo setor destino, para que o assunto passe a ser tratado formalmente pelo setor sem perder o histÃ³rico.

**Why this priority**: Ponte entre comunicaÃ§Ã£o privada e fluxo institucional setorial â€” requisito explÃ­cito do cliente.

**Independent Test**: Participante encaminha demanda pessoal para Setor X; demanda aparece na inbox setorial Recebidas de X; colegas de X veem a demanda; privacidade pessoal anterior deixa de se aplicar.

**Acceptance Scenarios**:

1. **Given** demanda pessoal aberta, **When** participante executa "Encaminhar para setor" informando setor destino e observaÃ§Ã£o opcional, **Then** demanda passa a seguir regras setoriais (visÃ­vel ao setor destino) e timeline registra transiÃ§Ã£o pessoal â†’ setorial.
2. **Given** promoÃ§Ã£o setorial concluÃ­da, **When** setor destino consulta inbox setorial, **Then** demanda aparece em Recebidas com histÃ³rico completo da fase pessoal.
3. **Given** promoÃ§Ã£o setorial concluÃ­da, **When** participante pessoal anterior consulta inbox pessoal, **Then** demanda nÃ£o permanece como conversa privada ativa â€” passa a ser demanda setorial.
4. **Given** promoÃ§Ã£o setorial, **When** concluÃ­da, **Then** reversÃ£o para modo pessoal privado nÃ£o Ã© permitida.

---

### User Story 6 - Vincular registro de outro mÃ³dulo em mensagem pessoal (Priority: P2)

Como operador, quero iniciar ou referenciar uma mensagem pessoal vinculada a um registro de origem (Gabinete, Ouvidoria ou JurÃ­dico), para dar contexto ao destinatÃ¡rio sem expor o assunto ao setor.

**Why this priority**: Estende o padrÃ£o linked record jÃ¡ existente na TramitaÃ§Ã£o ao canal pessoal, mantendo rastreabilidade.

**Independent Test**: Criar demanda pessoal com vÃ­nculo a registro de Gabinete; destinatÃ¡rio abre painel de origem com snapshot; visibilidade permanece restrita aos dois participantes atÃ© promoÃ§Ã£o setorial.

**Acceptance Scenarios**:

1. **Given** operador compÃµe mensagem pessoal, **When** associa registro elegÃ­vel de mÃ³dulo integrado (Gabinete, Ouvidoria ou JurÃ­dico), **Then** demanda pessoal Ã© criada com vÃ­nculo de origem e snapshot imutÃ¡vel do momento da associaÃ§Ã£o.
2. **Given** demanda pessoal com vÃ­nculo, **When** destinatÃ¡rio abre detalhe, **Then** visualiza painel de registro de origem com dados essenciais capturados no snapshot, sem precisar acessar o mÃ³dulo original.
3. **Given** registro de origem posteriormente arquivado no mÃ³dulo fonte, **When** participante abre demanda pessoal vinculada, **Then** snapshot imutÃ¡vel permanece visÃ­vel na demanda.

---

### User Story 7 - Auditoria pela administraÃ§Ã£o da instituiÃ§Ã£o (Priority: P2)

Como administrador da instituiÃ§Ã£o (admin_tenant), quero listar e consultar qualquer demanda pessoal do tenant em modo somente leitura, para fins de compliance e auditoria.

**Why this priority**: Visibilidade institucional acordada â€” participantes mantÃªm privacidade operacional, mas a gestÃ£o pode auditar.

**Independent Test**: admin_tenant acessa listagem de auditoria de demandas pessoais, abre demanda entre dois operadores, visualiza thread completa; operador comum nÃ£o acessa demandas pessoais de terceiros.

**Acceptance Scenarios**:

1. **Given** admin_tenant autenticado, **When** acessa visÃ£o de auditoria de demandas pessoais, **Then** visualiza listagem de todas as demandas pessoais do tenant com busca/filtros bÃ¡sicos.
2. **Given** admin_tenant abre demanda pessoal de terceiros, **When** consulta detalhe, **Then** visualiza thread e timeline completas em modo somente leitura (sem compor, responder, encaminhar ou arquivar em nome dos participantes).
3. **Given** operador comum (nÃ£o admin_tenant), **When** tenta acessar demanda pessoal de terceiros, **Then** acesso Ã© negado.

---

### Edge Cases

- DestinatÃ¡rio desativado ou removido apÃ³s envio mas antes de leitura â€” demanda permanece acessÃ­vel ao remetente; destinatÃ¡rio inativo nÃ£o recebe novas notificaÃ§Ãµes; encaminhar para outro operador continua disponÃ­vel.
- admin_tenant como remetente ou destinatÃ¡rio â€” participa logicamente da thread (envio/recebimento) mesmo sem perfil de operador institucional; auditoria permanece disponÃ­vel para compliance.
- Arquivamento por um participante â€” demanda move para Arquivadas para ambos os participantes de forma simÃ©trica.
- Tentativa de acesso por colega de setor, chefe de setor ou operador nÃ£o participante â€” negado; resposta nÃ£o revela assunto, remetente ou destinatÃ¡rio.
- Encaminhamento pessoal para o remetente original â€” permitido apenas se remetente nÃ£o for o destinatÃ¡rio atual (regra anti auto-envio mantida).
- PromoÃ§Ã£o setorial irreversÃ­vel â€” apÃ³s encaminhar para setor, privacidade pessoal nÃ£o pode ser restaurada.
- VÃ­nculo de origem com registro excluÃ­do ou arquivado â€” snapshot imutÃ¡vel na demanda permanece consultÃ¡vel pelos participantes e admin_tenant.
- Demanda pessoal encaminhada em cadeia (A â†’ B â†’ C) â€” apenas remetente original e destinatÃ¡rio atual mantÃªm custÃ³dia ativa; intermediÃ¡rios perdem acesso apÃ³s encaminhamento.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: O sistema DEVE distinguir demandas **pessoais** de demandas setoriais (genÃ©ricas ou linked setoriais) por tipo de origem identificÃ¡vel.
- **FR-002**: Toda demanda pessoal DEVE ter destinatÃ¡rio obrigatÃ³rio â€” operador ativo da instituiÃ§Ã£o (qualquer setor).
- **FR-003**: Visibilidade de demanda pessoal DEVE restringir-se a: remetente, destinatÃ¡rio atual, e admin_tenant (auditoria); nenhum outro usuÃ¡rio DEVE visualizar conteÃºdo, metadados ou existÃªncia da demanda.
- **FR-004**: A interface DEVE oferecer alternÃ¢ncia **Setor / Pessoal** na workspace TramitaÃ§Ã£o; inbox pessoal DEVE ser independente da inbox setorial.
- **FR-005**: Inbox pessoal DEVE espelhar pastas Recebidas, Enviadas e Arquivadas filtradas pelo usuÃ¡rio logado (nÃ£o pelo setor ativo).
- **FR-006**: Operadores DEVEM poder compor demanda pessoal com destinatÃ¡rio, assunto e corpo; protocolo automÃ¡tico no padrÃ£o TRAM-AAAA-NNNN.
- **FR-007**: O sistema DEVE impedir composiÃ§Ã£o com remetente igual ao destinatÃ¡rio.
- **FR-008**: Participantes DEVEM poder responder na thread; cada resposta DEVE registrar autor e data na timeline.
- **FR-009**: Participantes DEVEM poder arquivar demanda pessoal; arquivamento DEVE refletir simetricamente para ambos os participantes.
- **FR-010**: Participantes DEVEM poder encaminhar demanda pessoal para outro operador ativo; custÃ³dia DEVE transferir ao novo destinatÃ¡rio preservando histÃ³rico.
- **FR-011**: Participantes DEVEM poder encaminhar demanda pessoal para setor destino, convertendo-a em demanda setorial com visibilidade ao setor; transiÃ§Ã£o DEVE ser registrada na timeline e irreversÃ­vel quanto Ã  privacidade.
- **FR-012**: Operadores DEVEM poder associar vÃ­nculo de origem (Gabinete, Ouvidoria, JurÃ­dico) a demanda pessoal, com snapshot imutÃ¡vel capturado no momento da associaÃ§Ã£o.
- **FR-013**: NotificaÃ§Ãµes de eventos pessoais DEVEM direcionar-se apenas ao participante relevante (destinatÃ¡rio ou remetente); NUNCA broadcast ao setor inteiro em fluxo pessoal.
- **FR-014**: admin_tenant DEVE acessar listagem e detalhe de todas as demandas pessoais do tenant em modo somente leitura.
- **FR-015**: chefe_setor NÃƒO DEVE ter visibilidade adicional sobre demandas pessoais de membros do seu setor.
- **FR-016**: Demandas pessoais NÃƒO DEVEM aparecer na inbox setorial de nenhum setor enquanto permanecerem no modo pessoal.

### Key Entities

- **Demanda pessoal**: Thread usuÃ¡rio-a-usuÃ¡rio dentro do mÃ³dulo TramitaÃ§Ã£o; atributos: protocolo, assunto, corpo inicial, remetente, destinatÃ¡rio atual, status operacional, datas de criaÃ§Ã£o/arquivamento; distinta de demanda setorial enquanto nÃ£o promovida.
- **Participante**: Remetente original ou destinatÃ¡rio atual com custÃ³dia pessoal; apenas participantes ativos interagem na thread.
- **Evento da demanda**: Entrada na timeline â€” criaÃ§Ã£o, resposta, encaminhamento (usuÃ¡rio ou setor), arquivamento, transiÃ§Ã£o pessoal â†’ setorial; cada evento registra autor, data e conteÃºdo/observaÃ§Ã£o quando aplicÃ¡vel.
- **VÃ­nculo de origem**: ReferÃªncia opcional a registro externo (mÃ³dulo + identificador + snapshot imutÃ¡vel) associada Ã  demanda pessoal; visÃ­vel aos participantes e admin_tenant.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Operador compÃµe e envia mensagem pessoal em menos de 2 minutos em teste de usabilidade com fluxo guiado.
- **SC-002**: 100% das demandas pessoais permanecem invisÃ­veis a usuÃ¡rios fora do par remetente/destinatÃ¡rio (exceto admin_tenant em auditoria), validado por cenÃ¡rios de teste de aceitaÃ§Ã£o.
- **SC-003**: DestinatÃ¡rio recebe alerta de nova mensagem pessoal em atÃ© 30 segundos apÃ³s envio quando sessÃ£o ativa.
- **SC-004**: admin_tenant localiza qualquer demanda pessoal do tenant via listagem ou busca de auditoria em menos de 1 minuto.
- **SC-005**: 100% dos encaminhamentos pessoais para setor resultam em demanda visÃ­vel na inbox Recebidas do setor destino.

## Assumptions

- LicenÃ§a **Base** de TramitaÃ§Ã£o cobre caixa pessoal â€” sem licenÃ§a adicional (JatobÃ¡, Cedro, Carvalho).
- Protocolo TRAM-AAAA-NNNN e UX de pastas espelham a inbox setorial existente para reduzir curva de aprendizado.
- Sistema de notificaÃ§Ãµes existente (spec 029) serÃ¡ estendido com tipos de evento para fluxo pessoal; notificaÃ§Ãµes permanecem por usuÃ¡rio.
- Encaminhar para setor exige setor destino vÃ¡lido; observaÃ§Ã£o opcional segue padrÃ£o da tramitaÃ§Ã£o setorial.
- VinculaÃ§Ã£o a origem limita-se aos mÃ³dulos jÃ¡ integrados (Gabinete, Ouvidoria, JurÃ­dico); novos mÃ³dulos ficam fora de escopo v1.
- admin_tenant em auditoria opera em somente leitura â€” nÃ£o compÃµe, responde, encaminha ou arquiva em nome de participantes.
- Demanda pessoal reutiliza a mesma entidade Demanda da TramitaÃ§Ã£o com tipo/origem distinta â€” sem entidade paralela de mensagens.

## Dependencies

- TramitaÃ§Ã£o desmock (spec 014 arquivada) â€” inbox setorial, demandas, timeline, protocolo.
- Sistema de notificaÃ§Ãµes (spec 029) â€” alertas direcionados por usuÃ¡rio.
- PadrÃ£o linked record (specs 028 JurÃ­dico e 030 Gabinete arquivadas/em curso) â€” vÃ­nculo e snapshot de origem.

## Out of Scope (v1)

- Mensagens para grupos ou mÃºltiplos destinatÃ¡rios simultÃ¢neos.
- Visibilidade de demandas pessoais para chefe_setor.
- Caixa pessoal fora do mÃ³dulo TramitaÃ§Ã£o (Ã­cone ou mÃ³dulo global separado).
- Novos mÃ³dulos de origem alÃ©m de Gabinete, Ouvidoria e JurÃ­dico.
- Anexos especÃ­ficos da caixa pessoal â€” follow-up se necessÃ¡rio apÃ³s avaliar anexos existentes na TramitaÃ§Ã£o setorial.
