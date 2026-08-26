# Feature Specification: Marcar documentos como confidenciais em tramitação

**Feature Branch**: `033-tramitacao-docs-confidenciais`

**Created**: 2026-07-03

**Status**: Completed

**Tipo**: Feature

**Módulo**: Tramitação

**Input**: User description: "Hoje ao enviar para um setor ou setores todos podem ver a mensagem, registro e documentos anexados. A ideia é isso continuar, com exceção dos documentos. Caso seja marcado como confidencial, apenas as pessoas selecionadas poderão ver. Deve ter suporte a mais de um setor. Ex.: anexou documento, marcou um setor, apareceu a opção de marcar usuário daquele setor, marcou mais um, aparece dos outros."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Anexar documentos na tramitação (Priority: P1)

Como operador da Tramitação, quero anexar arquivos ou links ao criar uma nova demanda, responder na thread ou encaminhar para outro setor, para compartilhar evidências e documentos de apoio junto com a mensagem.

**Why this priority**: Sem a capacidade de anexar documentos, a confidencialidade por anexo não existe — é a base funcional desta feature.

**Independent Test**: Criar demanda setorial com um arquivo anexado; responder em thread existente com outro anexo; encaminhar com anexo opcional. Confirmar que anexos aparecem na timeline do evento correspondente e permanecem vinculados à demanda.

**Acceptance Scenarios**:

1. **Given** operador compondo nova tramitação setorial, **When** adiciona arquivo ou link externo e confirma envio, **Then** demanda é criada com anexo visível na timeline do evento de criação.
2. **Given** demanda aberta em andamento, **When** operador responde na thread com anexo, **Then** resposta e anexo aparecem no evento de resposta sem alterar anexos anteriores.
3. **Given** demanda setorial aberta, **When** operador encaminha para outro setor com anexo e observação, **Then** evento de encaminhamento registra anexo vinculado ao encaminhamento.
4. **Given** demanda arquivada, **When** operador tenta anexar documento, **Then** sistema impede a ação com mensagem clara.

---

### User Story 2 - Marcar anexo como confidencial com autorização por setor e usuário (Priority: P1)

Como operador remetente, quero marcar um documento anexado como confidencial e escolher, para cada setor selecionado, quais usuários daquele setor podem visualizá-lo, para restringir o acesso ao conteúdo sem ocultar a mensagem ou o registro vinculado.

**Why this priority**: Ã‰ o requisito central do cliente — granularidade de visibilidade por documento, com suporte a múltiplos setores e usuários específicos.

**Independent Test**: Anexar documento em tramitação setorial; marcar como confidencial; selecionar Setor A e dois usuários de A; adicionar Setor B e um usuário de B; enviar. Confirmar que apenas os três usuários selecionados (além do autor) têm acesso ao conteúdo.

**Acceptance Scenarios**:

1. **Given** operador anexou documento antes de enviar, **When** marca o anexo como confidencial, **Then** interface exibe fluxo para adicionar setor e, para cada setor adicionado, lista de usuários ativos daquele setor para seleção.
2. **Given** operador adicionou Setor A na confidencialidade, **When** seleciona ao menos um usuário de A e adiciona Setor B, **Then** lista de usuários de B é exibida independentemente, permitindo autorizar pessoas de setores distintos para o mesmo documento.
3. **Given** anexo marcado confidencial com setor adicionado, **When** operador tenta enviar sem selecionar nenhum usuário naquele setor, **Then** sistema impede envio com mensagem orientando a selecionar ao menos um usuário por setor marcado.
4. **Given** anexo não marcado como confidencial, **When** demanda é enviada, **Then** todos os operadores com acesso normal à demanda podem visualizar e baixar o documento.
5. **Given** operador marcou anexo como confidencial, **When** adiciona setor sem membros ativos, **Then** sistema impede a seleção ou orienta remoção do setor antes do envio.

---

### User Story 3 - Visualização diferenciada para autorizados e não autorizados (Priority: P1)

Como operador que recebeu uma tramitação com documento confidencial, quero ver o conteúdo completo apenas se fui autorizado; caso contrário, quero saber que existe um documento restrito sem conseguir abri-lo, para entender o contexto da demanda sem violar o sigilo.

**Why this priority**: Garante o valor da confidencialidade na prática — mensagem e registro permanecem acessíveis, mas o documento fica protegido com feedback claro.

**Independent Test**: Enviar demanda com documento confidencial autorizando apenas Usuário X do setor destino. Usuário X baixa o arquivo; colega do mesmo setor não autorizado vê placeholder sem link de download.

**Acceptance Scenarios**:

1. **Given** demanda com anexo confidencial e operador listado como autorizado, **When** abre detalhe da demanda, **Then** visualiza documento com acesso completo (visualizar/baixar conforme tipo).
2. **Given** demanda com anexo confidencial e operador do setor destino não autorizado, **When** abre detalhe da demanda, **Then** visualiza placeholder indicando documento confidencial, sem URL, preview ou download do conteúdo.
3. **Given** demanda com anexos públicos e confidenciais na mesma thread, **When** operador não autorizado consulta detalhe, **Then** vê anexos públicos normalmente e placeholders apenas nos confidenciais.
4. **Given** demanda encaminhada para setor, **When** qualquer membro do setor abre a demanda, **Then** assunto, corpo da mensagem, timeline e registro vinculado (quando houver) permanecem totalmente visíveis independentemente da confidencialidade dos anexos.
5. **Given** autor do anexo confidencial, **When** consulta demanda após envio, **Then** mantém acesso completo ao documento que anexou.

---

### User Story 4 - Anexos confidenciais na caixa pessoal (Priority: P2)

Como operador na caixa pessoal, quero anexar documentos confidenciais usando o mesmo fluxo de seleção por setor e usuário, para proteger conteúdo sensível mesmo em mensagens diretas entre operadores.

**Why this priority**: O cliente incluiu caixa pessoal no escopo; a confidencialidade deve ser consistente entre canais setorial e pessoal.

**Independent Test**: Operador A envia mensagem pessoal para B com anexo confidencial autorizando apenas C (de outro setor). B vê placeholder; C vê documento; colegas de A e B não veem a demanda (regra pessoal existente).

**Acceptance Scenarios**:

1. **Given** operador compondo mensagem pessoal, **When** anexa documento e marca como confidencial, **Then** fluxo setorâ†’usuários está disponível (não limitado ao destinatário da mensagem).
2. **Given** mensagem pessoal com anexo confidencial, **When** destinatário não está na lista de autorizados, **Then** destinatário vê placeholder do documento, mas continua participando da thread pessoal normalmente.
3. **Given** mensagem pessoal com anexo confidencial autorizando terceiro operador, **When** terceiro autorizado acessa a demanda (se tiver acesso à thread), **Then** visualiza documento completo.

---

### User Story 5 - Preservar confidencialidade ao encaminhar (Priority: P2)

Como operador que encaminha uma demanda para outro setor, quero que documentos já marcados como confidenciais mantenham sua lista de autorizados, e que novos anexos possam ter regras próprias, para não expandir sigilo inadvertidamente nem perder restrições anteriores.

**Why this priority**: Encaminhamento é fluxo frequente; perder ou expandir ACL automaticamente quebraria a confiança no sigilo documental.

**Independent Test**: Criar demanda com anexo confidencial autorizando Usuário X; encaminhar para Setor Y; confirmar que X ainda acessa, membros de Y não autorizados veem placeholder; adicionar novo anexo público no encaminhamento e confirmar visibilidade ampla apenas do novo.

**Acceptance Scenarios**:

1. **Given** demanda com anexo confidencial e ACL definida, **When** operador encaminha para outro setor, **Then** ACL do anexo permanece inalterada — novos membros do setor destino não ganham acesso automaticamente.
2. **Given** encaminhamento com novo anexo, **When** operador define confidencialidade apenas no novo anexo, **Then** anexos anteriores mantêm ACL original; novo anexo segue regras definidas no encaminhamento.
3. **Given** usuário previamente autorizado em anexo confidencial, **When** demanda é encaminhada, **Then** usuário autorizado continua com acesso ao documento.

---

### User Story 6 - Promover mensagem pessoal para setor mantendo ACL (Priority: P2)

Como participante de demanda pessoal promovida a tramitação setorial, quero que a thread inteira fique visível ao setor destino, mas documentos confidenciais continuem restritos aos autorizados, para formalizar o assunto sem expor anexos sensíveis ao setor todo.

**Why this priority**: Ponte entre caixa pessoal e fluxo setorial — sem esta regra, promoção setorial anularia a confidencialidade documental.

**Independent Test**: Criar mensagem pessoal com anexo confidencial (autorizando usuário específico); promover para Setor X; colegas de X veem mensagem e timeline, mas não o anexo; usuário autorizado continua vendo.

**Acceptance Scenarios**:

1. **Given** demanda pessoal com anexo confidencial, **When** participante promove para setor destino, **Then** demanda aparece na inbox setorial de X com histórico completo da fase pessoal.
2. **Given** promoção concluída, **When** membro do setor destino não autorizado abre demanda, **Then** visualiza mensagem, registro vinculado e timeline, mas anexos confidenciais aparecem como placeholder.
3. **Given** promoção concluída, **When** usuário previamente autorizado no anexo abre demanda, **Then** mantém acesso completo ao documento confidencial.

---

### User Story 7 - Auditoria de documentos confidenciais pelo administrador institucional (Priority: P2)

Como administrador da instituição (admin_tenant), quero consultar documentos confidenciais em modo somente leitura, para fins de compliance e auditoria, alinhado ao acesso já existente na caixa pessoal.

**Why this priority**: Visibilidade institucional acordada em spec anterior — participantes operacionais mantêm sigilo entre si, mas gestão pode auditar.

**Independent Test**: Autenticar como admin_tenant; abrir demanda com anexo confidencial em modo auditoria; confirmar visualização/download do documento; tentar mutação e confirmar bloqueio read-only.

**Acceptance Scenarios**:

1. **Given** admin_tenant em modo auditoria, **When** abre demanda com anexos confidenciais, **Then** visualiza e acessa conteúdo completo de todos os anexos, inclusive confidenciais.
2. **Given** admin_tenant consultando anexo confidencial, **When** tenta responder, encaminhar ou anexar, **Then** sistema impede mutação (somente leitura), conforme padrão de auditoria existente.

---

### Edge Cases

- Anexo marcado confidencial sem usuário selecionado em algum setor marcado â†’ bloqueio com mensagem clara antes do envio.
- Setor adicionado sem membros ativos â†’ impedir seleção ou exigir remoção do setor.
- Autor do anexo sempre mantém acesso, mesmo não estando explicitamente na lista de autorizados.
- Mesma thread com mistura de anexos públicos e confidenciais â†’ cada anexo segue sua própria regra de visibilidade.
- Demanda arquivada â†’ nenhum novo anexo permitido.
- Usuário autorizado removido ou inativado â†’ perde acesso; placeholder para demais não autorizados do setor.
- Reencaminhamento â†’ anexos antigos mantêm ACL; novos anexos podem ter ACL independente.
- Link externo anexado â†’ mesmas regras de confidencialidade que arquivo (placeholder sem URL para não autorizados).
- Encaminhar demanda para múltiplos setores destino simultaneamente â†’ fora de escopo v1 (um setor destino por encaminhamento).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Sistema DEVE permitir anexar arquivos e links externos ao criar demanda setorial, responder na thread e encaminhar para outro setor.
- **FR-002**: Sistema DEVE permitir anexar arquivos e links externos ao criar, responder e encaminhar demandas na caixa pessoal.
- **FR-003**: Sistema DEVE vincular cada anexo ao evento da timeline em que foi adicionado (criação, resposta ou encaminhamento).
- **FR-004**: Sistema DEVE oferecer opção de marcar cada anexo individualmente como confidencial antes do envio.
- **FR-005**: Para anexo confidencial, sistema DEVE permitir adicionar um ou mais setores e, para cada setor, selecionar um ou mais usuários ativos — exigindo ao menos um usuário por setor marcado.
- **FR-006**: Sistema DEVE impedir envio de anexo confidencial sem ao menos um setor com ao menos um usuário selecionado.
- **FR-007**: Sistema DEVE manter assunto, corpo, timeline e registro vinculado visíveis a todos com acesso normal à demanda, independentemente da confidencialidade dos anexos.
- **FR-008**: Usuários autorizados em anexo confidencial DEVEM poder visualizar e baixar (ou acessar link) o conteúdo completo.
- **FR-009**: Usuários não autorizados DEVEM ver placeholder indicando documento confidencial, sem URL, preview ou download do conteúdo.
- **FR-010**: Autor do anexo DEVE manter acesso completo ao documento que anexou, independentemente da lista de autorizados.
- **FR-011**: ACL de anexo confidencial DEVE persistir inalterada quando demanda é encaminhada para outro setor.
- **FR-012**: Novos anexos adicionados em encaminhamento ou resposta DEVEM poder ter ACL própria (pública ou confidencial) sem alterar ACL de anexos anteriores.
- **FR-013**: Ao promover demanda pessoal para setor, sistema DEVE tornar thread visível ao setor destino mas DEVE manter ACL dos anexos confidenciais sem expansão automática ao setor.
- **FR-014**: admin_tenant em modo auditoria DEVE visualizar e acessar conteúdo de anexos confidenciais em somente leitura.
- **FR-015**: Sistema DEVE impedir anexação em demandas arquivadas.
- **FR-016**: Usuários inativos ou removidos da lista de autorizados DEVEM perder acesso a anexos confidenciais.
- **FR-017**: Links externos anexados DEVEM seguir as mesmas regras de confidencialidade e placeholder que arquivos.

### Key Entities

- **Documento anexado**: Representa arquivo ou link vinculado a uma demanda e a um evento da timeline; possui indicador de confidencialidade e metadados de identificação (nome, tipo, tamanho ou título de link).
- **Autorização de visualização**: Representa permissão concedida a um usuário específico de um setor para acessar um documento confidencial; múltiplas autorizações por documento, podendo abranger vários setores.
- **Demanda de tramitação**: Thread de comunicação (setorial ou pessoal) que permanece visível conforme regras existentes do módulo; confidencialidade aplica-se apenas aos anexos, não à demanda como um todo.
- **Evento da timeline**: Registro de criação, resposta, encaminhamento ou mudança de status; contexto em que anexos são adicionados.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Operador consegue anexar documento e configurar confidencialidade (setor + usuários) em menos de 2 minutos em 90% dos fluxos testados.
- **SC-002**: 100% dos usuários não autorizados visualizam apenas placeholder — nunca conteúdo, URL ou preview de documento confidencial.
- **SC-003**: 100% dos usuários autorizados e admin_tenant acessam documento confidencial na primeira tentativa, sem erro.
- **SC-004**: Mensagem, timeline e registro vinculado permanecem visíveis a 100% dos membros do setor destino em testes de encaminhamento com anexo confidencial.
- **SC-005**: Em testes de promoção pessoalâ†’setor, 0% de expansão involuntária de acesso a anexos confidenciais para membros do setor não autorizados.

## Assumptions

- Limites de tamanho, tipos de arquivo permitidos e fluxo de upload seguirão o padrão já estabelecido em outros módulos da plataforma (Gabinete, Ouvidoria) — detalhes técnicos serão definidos no plan.
- Confidencialidade é por anexo individual, não por demanda inteira — uma thread pode misturar anexos públicos e confidenciais.
- admin_tenant mantém padrão somente leitura para mutações, alinhado à caixa pessoal (spec 031).
- Autor do anexo é sempre considerado autorizado, mesmo sem entrada explícita na lista.
- Encaminhamento setorial continua com um único setor destino por ação (fora de escopo v1: múltiplos destinos simultâneos).
- Caixa pessoal na confidencialidade usa fluxo setorâ†’usuários (não limitado aos participantes da thread).
- Depende do módulo Tramitação existente, incluindo caixa pessoal (031) e registro vinculado (014/028/030).
