# Feature Specification: Excluir Anexos de ManifestaÃ§Ã£o (Ouvidoria)

**Feature Branch**: `053-excluir-anexos-ouvidoria`

**Created**: 2026-10-08

**Status**: Completed

**Input**: User description: "Na tela de detalhe da manifestaÃ§Ã£o (Ouvidoria â†’ ManifestaÃ§Ãµes â†’ detalhe), card Anexos: apagar documentos anexados (armazenados no Wasabi), com total cuidado e seguranÃ§a. Qualquer dÃºvida ou Ã¡rea cinzenta deve ser perguntada obrigatoriamente."

**Relacionamento**: Complementa o fluxo de anexos da Ouvidoria (envio em rascunho, confirmaÃ§Ã£o e download jÃ¡ existentes) e o dossiÃª de detalhe ([040](../040-dossie-detalhe-ui/spec.md), norma de UI). Modelo de referÃªncia de remoÃ§Ã£o com rastro: [034 desentranhamento-tramitacao](../034-desentranhamento-tramitacao/spec.md) (outro mÃ³dulo, regras prÃ³prias â€” esta spec **nÃ£o** o reutiliza). Regra de acesso Ã  manifestaÃ§Ã£o: [047 acesso-ouvidoria-ageman](../047-acesso-ouvidoria-ageman/spec.md).

## Clarifications

### Session 2026-10-08

- Q: Escopo â€” funcionalidade permanente ou limpeza pontual de uma manifestaÃ§Ã£o? â†’ A: **Funcionalidade permanente**: botÃ£o "Excluir" em cada anexo no detalhe de qualquer manifestaÃ§Ã£o. NÃ£o hÃ¡ limpeza pontual em massa nesta spec.
- Q: Quem pode excluir? â†’ A: **Qualquer usuÃ¡rio com acesso Ã  manifestaÃ§Ã£o** (mesma regra que jÃ¡ vale hoje para enviar/confirmar anexo: administradores, chefe da Ouvidoria, dono/emissor e quem recebeu concessÃ£o de acesso).
- Q: Em quais status da manifestaÃ§Ã£o? â†’ A: **Qualquer status, exceto encerradas** â€” permitido em rascunho, em anÃ¡lise, em encaminhamento e respondida; **bloqueado** em encerrada, encerrada nÃ£o resolvida e encerrada por meio jurÃ­dico.
- Q: Tipo de exclusÃ£o? â†’ A: **Arquivo apagado definitivamente do armazenamento; registro mantido como "excluÃ­do"** (nome, quem excluiu, quando) e **evento na linha do tempo** da manifestaÃ§Ã£o.
- Q: Salvaguardas na interface? â†’ A: **Apenas diÃ¡logo de confirmaÃ§Ã£o** (sem motivo obrigatÃ³rio e sem digitar o nome do arquivo).
- Q: Anexos do tipo link externo? â†’ A: **Sim, mesma funcionalidade e mesmas regras** (remove sÃ³ o registro; nÃ£o hÃ¡ arquivo no armazenamento).
- Q: Em quais telas o botÃ£o "Excluir" Ã© oferecido? â†’ A: **No card Anexos do detalhe e nos anexos jÃ¡ salvos do assistente de manifestaÃ§Ã£o (ediÃ§Ã£o e revisÃ£o do rascunho)**, com a mesma regra de acesso/status e o mesmo diÃ¡logo de confirmaÃ§Ã£o. Arquivos ainda nÃ£o enviados (pendentes locais do rascunho) continuam sendo removidos pelo fluxo atual, sem passar por esta exclusÃ£o.
- Q: O anexo excluÃ­do continua visÃ­vel no card Anexos (linha esmaecida)? â†’ A: **NÃ£o**. O card (e a lista do assistente) mostra apenas anexos ativos; o rastro da exclusÃ£o fica na linha do tempo e no registro retido.
- Q: A carta-resposta oficial (anexada ao encerrar) pode ser excluÃ­da? â†’ A: **NÃ£o hÃ¡ regra extra**: ela sÃ³ Ã© anexada no encerramento, e manifestaÃ§Ã£o encerrada jÃ¡ bloqueia toda exclusÃ£o (FR-003).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Excluir um arquivo anexado com seguranÃ§a (Priority: P1)

Como usuÃ¡rio com acesso a uma manifestaÃ§Ã£o ainda nÃ£o encerrada, quero excluir um arquivo anexado por engano ou indevido (por exemplo, documento errado, duplicado ou com dado que nÃ£o deveria estar ali), de forma que ele deixe de aparecer, deixe de poder ser baixado e seja realmente apagado do armazenamento â€” com um passo de confirmaÃ§Ã£o para evitar cliques acidentais.

**Why this priority**: Ã‰ o nÃºcleo do pedido. Hoje nÃ£o existe nenhuma forma de remover um anexo pela aplicaÃ§Ã£o; o arquivo errado fica para sempre na manifestaÃ§Ã£o e no armazenamento.

**Independent Test**: Em uma manifestaÃ§Ã£o aberta com um anexo de arquivo, clicar em "Excluir", confirmar, e verificar que (a) o anexo some da lista de anexos ativos, (b) o link de download deixa de funcionar, (c) o arquivo nÃ£o existe mais no armazenamento, e (d) a linha do tempo registra a exclusÃ£o.

**Acceptance Scenarios**:

1. **Given** uma manifestaÃ§Ã£o em status aberto (rascunho, em anÃ¡lise, encaminhamento ou respondida) com um anexo de arquivo confirmado, **When** o usuÃ¡rio com acesso clica em "Excluir" no anexo, **Then** o sistema exibe um diÃ¡logo de confirmaÃ§Ã£o identificando o arquivo pelo nome e sÃ³ prossegue apÃ³s confirmaÃ§Ã£o explÃ­cita.
2. **Given** o diÃ¡logo de confirmaÃ§Ã£o aberto, **When** o usuÃ¡rio cancela (botÃ£o Cancelar, tecla Esc ou clique fora), **Then** nada Ã© alterado e o arquivo continua disponÃ­vel.
3. **Given** a exclusÃ£o confirmada com sucesso, **When** a tela Ã© atualizada, **Then** o anexo nÃ£o aparece mais na lista de anexos ativos, nÃ£o pode mais ser baixado e a linha do tempo mostra "anexo excluÃ­do" com nome do arquivo, autor da aÃ§Ã£o e data/hora.
4. **Given** a exclusÃ£o confirmada, **When** o arquivo Ã© apagado, **Then** o conteÃºdo deixa de existir no armazenamento (nÃ£o apenas "escondido" na interface).
5. **Given** um usuÃ¡rio sem acesso Ã  manifestaÃ§Ã£o, **When** tenta excluir um anexo (inclusive por chamada direta ao serviÃ§o), **Then** a aÃ§Ã£o Ã© negada e nada Ã© alterado.

---

### User Story 2 - Proteger manifestaÃ§Ãµes encerradas e o isolamento entre instituiÃ§Ãµes (Priority: P1)

Como responsÃ¡vel pela integridade do acervo da Ouvidoria, quero que a exclusÃ£o nunca ocorra em manifestaÃ§Ã£o encerrada nem atinja anexo de outra manifestaÃ§Ã£o ou de outra instituiÃ§Ã£o, para que registros finalizados e dados de terceiros fiquem protegidos contra erro ou abuso.

**Why this priority**: Ã‰ o que torna a exclusÃ£o "segura". Sem estes bloqueios, a funcionalidade permitiria adulterar o histÃ³rico de manifestaÃ§Ãµes jÃ¡ respondidas e encerradas.

**Independent Test**: Tentar excluir um anexo (a) de manifestaÃ§Ã£o encerrada, (b) usando o identificador de um anexo que pertence a outra manifestaÃ§Ã£o, (c) de outra instituiÃ§Ã£o. Todas as tentativas devem ser recusadas, sem apagar nada.

**Acceptance Scenarios**:

1. **Given** manifestaÃ§Ã£o em qualquer status de encerramento (encerrada, encerrada nÃ£o resolvida, encerrada por meio jurÃ­dico), **When** o usuÃ¡rio abre o detalhe, **Then** o botÃ£o "Excluir" nÃ£o Ã© oferecido nos anexos.
2. **Given** manifestaÃ§Ã£o encerrada, **When** alguÃ©m tenta excluir um anexo por chamada direta ao serviÃ§o, **Then** a aÃ§Ã£o Ã© recusada com mensagem clara e o arquivo permanece intacto.
3. **Given** um identificador de anexo que pertence a outra manifestaÃ§Ã£o (ou a outra instituiÃ§Ã£o), **When** usado na rota de uma manifestaÃ§Ã£o diferente, **Then** o sistema responde "anexo nÃ£o encontrado" e nenhum arquivo Ã© apagado.
4. **Given** uma manifestaÃ§Ã£o removida (exclusÃ£o lÃ³gica da manifestaÃ§Ã£o), **When** se tenta excluir seus anexos, **Then** a aÃ§Ã£o Ã© recusada como "nÃ£o encontrado".

---

### User Story 3 - Falhas e repetiÃ§Ãµes nÃ£o deixam estado inconsistente (Priority: P1)

Como usuÃ¡rio, quero que, se algo falhar no meio da exclusÃ£o (por exemplo, indisponibilidade do armazenamento), eu seja avisado com clareza e possa tentar de novo, sem que o sistema diga que apagou algo que nÃ£o apagou â€” nem esconda um arquivo que ainda existe.

**Why this priority**: A exclusÃ£o envolve dois lugares (registro no sistema e arquivo no armazenamento). Qualquer divergÃªncia entre eles Ã© um problema de seguranÃ§a (arquivo "fantasma" ainda acessÃ­vel) ou de integridade (registro sem arquivo).

**Independent Test**: Simular falha do armazenamento durante a exclusÃ£o e verificar que o usuÃ¡rio recebe erro, o anexo continua listado e acessÃ­vel, e uma nova tentativa conclui a exclusÃ£o. Repetir a exclusÃ£o de um anexo jÃ¡ excluÃ­do e verificar que nÃ£o gera erro nem evento duplicado.

**Acceptance Scenarios**:

1. **Given** o armazenamento indisponÃ­vel no momento da exclusÃ£o, **When** o usuÃ¡rio confirma, **Then** o sistema informa que nÃ£o foi possÃ­vel excluir, o anexo continua listado como ativo e nenhum evento de exclusÃ£o Ã© registrado.
2. **Given** uma falha anterior, **When** o usuÃ¡rio tenta novamente e o armazenamento responde, **Then** a exclusÃ£o conclui normalmente.
3. **Given** um anexo cujo arquivo jÃ¡ nÃ£o existe no armazenamento (ex.: envio nunca concluÃ­do ou arquivo removido por fora), **When** o usuÃ¡rio exclui, **Then** a exclusÃ£o Ã© concluÃ­da com sucesso (o resultado desejado â€” arquivo inexistente â€” jÃ¡ Ã© verdadeiro).
4. **Given** um anexo jÃ¡ excluÃ­do, **When** a exclusÃ£o Ã© solicitada de novo (duplo clique, duas abas, retentativa), **Then** nÃ£o hÃ¡ erro para o usuÃ¡rio, nÃ£o se cria registro nem evento duplicado e nada alÃ©m do jÃ¡ excluÃ­do Ã© afetado.

---

### User Story 4 - Excluir anexo do tipo link externo (Priority: P2)

Como usuÃ¡rio com acesso a uma manifestaÃ§Ã£o aberta, quero tambÃ©m remover um anexo que Ã© apenas um link externo, com as mesmas regras e a mesma confirmaÃ§Ã£o, para que a lista de anexos reflita sÃ³ o que deve permanecer.

**Why this priority**: MantÃ©m a experiÃªncia consistente (um Ãºnico botÃ£o "Excluir" para todo anexo), mas o risco Ã© menor, pois nÃ£o hÃ¡ arquivo no armazenamento a apagar.

**Independent Test**: Em manifestaÃ§Ã£o aberta com um anexo do tipo link, excluir e verificar que o link some da lista, que o evento aparece na linha do tempo e que nenhuma operaÃ§Ã£o de apagar arquivo foi tentada no armazenamento.

**Acceptance Scenarios**:

1. **Given** manifestaÃ§Ã£o aberta com anexo do tipo link, **When** o usuÃ¡rio confirma a exclusÃ£o, **Then** o link deixa de aparecer, a exclusÃ£o Ã© registrada na linha do tempo e nenhum arquivo Ã© tocado no armazenamento.
2. **Given** manifestaÃ§Ã£o encerrada, **When** o usuÃ¡rio abre o detalhe, **Then** o link continua exibido sem opÃ§Ã£o de excluir (mesma regra dos arquivos).

---

### User Story 5 - Rastreabilidade: ver que um anexo foi excluÃ­do (Priority: P2)

Como auditor ou responsÃ¡vel da Ouvidoria, quero poder ver, depois, que um anexo existiu e foi excluÃ­do â€” qual era o nome, quem excluiu e quando â€” sem que o conteÃºdo continue disponÃ­vel, para manter a trilha de responsabilidade sobre o dossiÃª.

**Why this priority**: Como a exclusÃ£o nÃ£o exige justificativa, o registro de quem e quando Ã© a Ãºnica proteÃ§Ã£o contra exclusÃ£o indevida. NÃ£o bloqueia o MVP da exclusÃ£o em si, mas Ã© parte do "total cuidado" pedido.

**Independent Test**: Excluir um anexo e verificar na linha do tempo e no registro retido: nome do arquivo, autor da exclusÃ£o (inclusive quando for administrador da instituiÃ§Ã£o) e data/hora; confirmar que o conteÃºdo nÃ£o Ã© recuperÃ¡vel por nenhum caminho da aplicaÃ§Ã£o.

**Acceptance Scenarios**:

1. **Given** um anexo excluÃ­do, **When** qualquer usuÃ¡rio com acesso consulta a linha do tempo, **Then** vÃª o evento com nome do arquivo, quem excluiu e quando.
2. **Given** a exclusÃ£o feita por administrador da instituiÃ§Ã£o, **When** o evento Ã© exibido, **Then** o autor Ã© identificado corretamente (sem erro por nÃ£o ser usuÃ¡rio operacional comum).
3. **Given** um anexo excluÃ­do, **When** se tenta obter seu link de download ou abri-lo por qualquer caminho, **Then** o acesso Ã© negado/inexistente.

---

### Edge Cases

- **Upload nunca confirmado** (arquivo enviado pela metade, registro criado mas envio nÃ£o concluÃ­do): deve poder ser excluÃ­do como qualquer outro anexo; se o arquivo nem chegou ao armazenamento, a exclusÃ£o ainda conclui com sucesso.
- **Link de download jÃ¡ emitido antes da exclusÃ£o**: expira por conta prÃ³pria em atÃ© 15 minutos; apÃ³s a exclusÃ£o confirmada nenhum link novo Ã© emitido e o arquivo deixa de existir no armazenamento.
- **ExclusÃ£o concorrente** (duas pessoas ou duas abas ao mesmo tempo): apenas uma exclusÃ£o efetiva e um Ãºnico evento na linha do tempo; a outra recebe resultado de sucesso/idempotente ou "jÃ¡ excluÃ­do".
- **ManifestaÃ§Ã£o encerrada enquanto o usuÃ¡rio estÃ¡ com o diÃ¡logo aberto**: a confirmaÃ§Ã£o Ã© recusada (o status Ã© verificado no momento da exclusÃ£o, nÃ£o sÃ³ ao abrir a tela).
- **Anexo originado do formulÃ¡rio pÃºblico** (enviado pelo cidadÃ£o e vinculado na criaÃ§Ã£o): tratado como qualquer outro anexo da manifestaÃ§Ã£o, sujeito Ã s mesmas regras de acesso e status.
- **Arquivo pendente local do rascunho** (selecionado no assistente, ainda nÃ£o enviado): nÃ£o Ã© um anexo salvo; sua remoÃ§Ã£o segue o fluxo atual e nÃ£o gera evento nem registro "excluÃ­do".
- **ExclusÃ£o feita no assistente**: a lista de anexos do assistente Ã© atualizada ao concluir, sem perder o restante dos dados do rascunho em ediÃ§Ã£o.
- **ManifestaÃ§Ã£o com um Ãºnico anexo**: pode ser excluÃ­do; a lista volta ao estado "Nenhum arquivo anexado".
- **ExportaÃ§Ãµes (PDF/DOCX) e listas de anexos**: anexos excluÃ­dos nÃ£o sÃ£o incluÃ­dos como conteÃºdo nem como link.
- **Anexo de outra manifestaÃ§Ã£o/instituiÃ§Ã£o**: tratado como nÃ£o encontrado, sem revelar que existe.
- **PermissÃ£o por concessÃ£o de acesso**: usuÃ¡rio com acesso concedido sobre a manifestaÃ§Ã£o pode excluir, igual a quem tem acesso por papel â€” nÃ£o existe hoje acesso "somente leitura" nesse mÃ³dulo.

## Requirements *(mandatory)*

### Functional Requirements

**ExclusÃ£o e permissÃµes**

- **FR-001**: O sistema MUST oferecer uma aÃ§Ã£o "Excluir" em cada anexo jÃ¡ salvo exibido (a) no card "Anexos" do detalhe da manifestaÃ§Ã£o e (b) na lista de anexos do assistente de manifestaÃ§Ã£o (ediÃ§Ã£o e revisÃ£o do rascunho), visÃ­vel apenas quando o usuÃ¡rio tiver acesso Ã  manifestaÃ§Ã£o e ela estiver em status aberto; as duas telas MUST usar a mesma regra, o mesmo diÃ¡logo de confirmaÃ§Ã£o (FR-006) e o mesmo resultado.
- **FR-002**: O sistema MUST aplicar, no momento da exclusÃ£o, as mesmas regras de acesso Ã  manifestaÃ§Ã£o jÃ¡ vigentes para enviar/confirmar anexos (administradores, chefe da Ouvidoria, dono/emissor, concessÃµes de acesso); a verificaÃ§Ã£o MUST ocorrer no servidor, independentemente do que a interface mostre.
- **FR-003**: O sistema MUST permitir a exclusÃ£o apenas quando o status da manifestaÃ§Ã£o for rascunho, em anÃ¡lise, em encaminhamento ou respondida, e MUST recusar a exclusÃ£o em encerrada, encerrada nÃ£o resolvida e encerrada por meio jurÃ­dico, com mensagem clara ao usuÃ¡rio.
- **FR-004**: O sistema MUST verificar o status da manifestaÃ§Ã£o no instante da exclusÃ£o (nÃ£o confiar em estado carregado antes na tela).
- **FR-005**: O sistema MUST garantir que o anexo a excluir pertence Ã  manifestaÃ§Ã£o indicada e Ã  instituiÃ§Ã£o do usuÃ¡rio; caso contrÃ¡rio MUST responder "anexo nÃ£o encontrado" sem apagar nada nem revelar a existÃªncia do anexo.

**ConfirmaÃ§Ã£o na interface**

- **FR-006**: A interface MUST exibir diÃ¡logo de confirmaÃ§Ã£o antes de qualquer exclusÃ£o, informando o nome do arquivo e que a aÃ§Ã£o Ã© **irreversÃ­vel**; a exclusÃ£o sÃ³ prossegue apÃ³s confirmaÃ§Ã£o explÃ­cita e o diÃ¡logo MUST permitir cancelar sem efeitos.
- **FR-007**: Enquanto a exclusÃ£o estiver em andamento, a interface MUST impedir novos cliques (evitar disparos duplicados) e MUST mostrar o resultado (sucesso ou erro) ao usuÃ¡rio; o botÃ£o de exclusÃ£o MUST ser acessÃ­vel por teclado e ter rÃ³tulo identificando qual arquivo serÃ¡ excluÃ­do.

**Efeito sobre o arquivo e o registro**

- **FR-008**: Para anexo do tipo arquivo, o sistema MUST apagar definitivamente o arquivo do armazenamento (nenhuma cÃ³pia recuperÃ¡vel pela aplicaÃ§Ã£o).
- **FR-009**: Para anexo do tipo link externo, o sistema MUST remover apenas o registro (sem operaÃ§Ã£o no armazenamento).
- **FR-010**: O sistema MUST manter, apÃ³s a exclusÃ£o, um registro do anexo marcado como excluÃ­do contendo ao menos: nome, tipo (arquivo/link), tamanho (quando houver), data do envio, quem enviou, quem excluiu e quando excluiu; o conteÃºdo do arquivo (e a URL de um link) MUST NOT ser mantido ou exposto.
- **FR-011**: O sistema MUST registrar na linha do tempo da manifestaÃ§Ã£o um evento de exclusÃ£o de anexo, com nome do arquivo, autor e data/hora.
- **FR-012**: O sistema MUST identificar corretamente o autor da exclusÃ£o, inclusive quando for administrador da instituiÃ§Ã£o ou administrador da plataforma (que nÃ£o sÃ£o usuÃ¡rios operacionais comuns), sem causar erro por vÃ­nculo de usuÃ¡rio inexistente.
- **FR-013**: Anexos excluÃ­dos MUST NOT aparecer â€” nem como linha esmaecida â€” no card Anexos do detalhe, na lista de anexos do assistente, nas exportaÃ§Ãµes (PDF/DOCX) nem nas contagens/listagens de anexos, e MUST NOT gerar novo link de download; a Ãºnica exibiÃ§Ã£o da exclusÃ£o Ã© o evento na linha do tempo (FR-011).

**ConsistÃªncia e falhas**

- **FR-014**: Se o armazenamento falhar ao apagar o arquivo, o sistema MUST informar o usuÃ¡rio, MUST manter o anexo ativo e acessÃ­vel e MUST NOT registrar evento de exclusÃ£o nem marcar o anexo como excluÃ­do; o usuÃ¡rio MUST poder tentar de novo.
- **FR-015**: O sistema MUST NOT informar sucesso de exclusÃ£o se o arquivo ainda existir no armazenamento.
- **FR-016**: Se o arquivo jÃ¡ nÃ£o existir no armazenamento, a exclusÃ£o MUST ser considerada bem-sucedida e concluir o registro do anexo como excluÃ­do.
- **FR-017**: A exclusÃ£o MUST ser idempotente: repetir a exclusÃ£o de um anexo jÃ¡ excluÃ­do MUST NOT gerar erro ao usuÃ¡rio, evento duplicado ou efeito em outros anexos.
- **FR-018**: A exclusÃ£o MUST afetar exclusivamente o anexo solicitado â€” nunca outros anexos da mesma manifestaÃ§Ã£o, nem arquivos de outras manifestaÃ§Ãµes ou instituiÃ§Ãµes, nem o restante do armazenamento.

**SeguranÃ§a e auditoria**

- **FR-019**: O sistema MUST negar a exclusÃ£o a usuÃ¡rios nÃ£o autenticados, de outra instituiÃ§Ã£o ou sem acesso Ã  manifestaÃ§Ã£o, tanto pela interface quanto por chamada direta ao serviÃ§o.
- **FR-020**: As mensagens de erro MUST ser claras e em portuguÃªs, sem expor detalhes internos (caminho de armazenamento, credenciais, identificadores tÃ©cnicos).
- **FR-021**: O registro de auditoria da exclusÃ£o MUST estar disponÃ­vel para consulta posterior por quem tem acesso Ã  manifestaÃ§Ã£o (via linha do tempo) e MUST NOT poder ser alterado ou apagado pelo fluxo normal da aplicaÃ§Ã£o.

### Key Entities *(include if feature involves data)*

- **Anexo da manifestaÃ§Ã£o**: arquivo (guardado no armazenamento) ou link externo vinculado a uma manifestaÃ§Ã£o. Passa a ter um estado adicional **excluÃ­do**, com quem excluiu e quando; quando excluÃ­do, perde o conteÃºdo/URL mas mantÃ©m nome, tipo, tamanho, data e autor do envio.
- **Evento da linha do tempo â€” anexo excluÃ­do**: registro imutÃ¡vel na linha do tempo da manifestaÃ§Ã£o com nome do arquivo, autor da exclusÃ£o e data/hora.
- **ManifestaÃ§Ã£o**: dona dos anexos; seu status (aberto vs. encerrado) determina se a exclusÃ£o Ã© permitida.
- **Arquivo no armazenamento**: objeto de armazenamento em nuvem associado a um anexo do tipo arquivo; Ã© apagado definitivamente na exclusÃ£o.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Um usuÃ¡rio com acesso consegue excluir um anexo de manifestaÃ§Ã£o aberta em atÃ© 3 interaÃ§Ãµes (abrir aÃ§Ã£o "Excluir", confirmar, ver resultado) e em menos de 10 segundos em condiÃ§Ãµes normais.
- **SC-002**: Em 100% das exclusÃµes concluÃ­das com sucesso, o arquivo deixa de existir no armazenamento â€” verificÃ¡vel por conferÃªncia amostral entre registros excluÃ­dos e o armazenamento (zero arquivos "fantasma").
- **SC-003**: Em 100% das tentativas em manifestaÃ§Ã£o encerrada, por usuÃ¡rio sem acesso ou usando anexo de outra manifestaÃ§Ã£o/instituiÃ§Ã£o, nenhum arquivo Ã© apagado e nenhum registro Ã© alterado.
- **SC-004**: Em 100% das falhas simuladas do armazenamento, o anexo permanece ativo e acessÃ­vel e nenhum evento de exclusÃ£o Ã© registrado; a nova tentativa conclui.
- **SC-005**: Em 100% das exclusÃµes concluÃ­das existe um evento visÃ­vel na linha do tempo com nome do arquivo, autor e data/hora, inclusive quando o autor Ã© administrador da instituiÃ§Ã£o.
- **SC-006**: Repetir a mesma exclusÃ£o N vezes (duplo clique, retentativa, duas abas) resulta em exatamente 1 evento na linha do tempo e nenhum erro exibido ao usuÃ¡rio.
- **SC-007**: Nenhum anexo excluÃ­do aparece nas listas de anexos (detalhe e assistente) nem nas exportaÃ§Ãµes PDF/DOCX da manifestaÃ§Ã£o; a exclusÃ£o sÃ³ Ã© visÃ­vel na linha do tempo.

## Assumptions

- As telas-alvo sÃ£o o card "Anexos" do detalhe da manifestaÃ§Ã£o e a lista de anexos salvos do assistente (ediÃ§Ã£o/revisÃ£o do rascunho); o pedido original cita o detalhe de uma manifestaÃ§Ã£o especÃ­fica como exemplo, mas o escopo Ã© toda manifestaÃ§Ã£o (decisÃµes de 2026-10-08).
- "Wasabi" Ã© o armazenamento de arquivos em nuvem hoje utilizado; a spec trata-o como "armazenamento", sem prender a tecnologia. Em ambiente de desenvolvimento/stub, a exclusÃ£o deve se comportar igualmente do ponto de vista do usuÃ¡rio.
- NÃ£o Ã© exigido motivo de exclusÃ£o nem digitaÃ§Ã£o do nome do arquivo (decisÃ£o de 2026-10-08). Como a aÃ§Ã£o Ã© irreversÃ­vel e permitida a qualquer usuÃ¡rio com acesso, a trilha (quem/quando/qual arquivo) Ã© a principal salvaguarda â€” por isso FR-010, FR-011 e FR-021 sÃ£o obrigatÃ³rios.
- O papel "acesso" inclui concessÃµes pontuais e por emissor definidas pela spec 047; nÃ£o existe hoje permissÃ£o somente leitura nesse mÃ³dulo, entÃ£o todo usuÃ¡rio com acesso Ã  manifestaÃ§Ã£o pode excluir. Se no futuro surgir acesso somente leitura, ele nÃ£o deve excluir.
- Para anexos do tipo link, mantÃ©m-se apenas o nome no registro retido; a URL Ã© descartada (pode conter parÃ¢metros sensÃ­veis). RevisÃ¡vel no `/speckit-plan`.
- NÃ£o hÃ¡ prazo de carÃªncia nem restauraÃ§Ã£o: a exclusÃ£o Ã© definitiva para o conteÃºdo do arquivo. O registro mantÃ©m apenas metadados para auditoria.
- Se o bucket do armazenamento tiver versionamento ou retenÃ§Ã£o (object lock) ativo, "apagar definitivamente" MUST considerar todas as versÃµes â€” a verificaÃ§Ã£o desse comportamento do provedor Ã© pendÃªncia do `/speckit-plan` e requisito para marcar a feature como concluÃ­da.
- Fora de escopo: exclusÃ£o em massa; limpeza automÃ¡tica de uploads Ã³rfÃ£os e dos anexos temporÃ¡rios do formulÃ¡rio pÃºblico; exclusÃ£o de anexos em outros mÃ³dulos (Gabinete, TramitaÃ§Ã£o, TI); restauraÃ§Ã£o de anexos excluÃ­dos; reabrir manifestaÃ§Ã£o encerrada para permitir exclusÃ£o; justificativa/aprovaÃ§Ã£o em duas etapas.
- Os dados de produÃ§Ã£o (ex.: a manifestaÃ§Ã£o citada no pedido) nÃ£o sÃ£o alterados por esta spec; a exclusÃ£o ocorre somente quando um usuÃ¡rio a executar pela aplicaÃ§Ã£o, apÃ³s a implementaÃ§Ã£o.
