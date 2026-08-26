# Feature Specification: TramitaÃ§Ã£o como Protocolo (refatoraÃ§Ã£o de mensagem â†’ protocolo)

**Feature Branch**: `035-tramitacao-protocolo`

**Created**: 2026-07-08

**Status**: Completed

**Input**: User description: "alterar tramitaÃ§Ã£o de mensagem para protocolo. Atualmente o UI/UX e a lÃ³gica dÃ£o a entender que tramitaÃ§Ã£o Ã© mais troca de mensagem do que um protocolo; a ideia Ã© refatorar para algo mais parecido com protocolo. Fluxos: (1) tramitar dados â€” abrir novo protocolo ou entranhar a um jÃ¡ existente; (2) iniciar tramitaÃ§Ã£o â€” abrir novo protocolo. VocÃª nÃ£o encaminha mais para setores, vocÃª inclui setores dentro do protocolo. Em recebidas/enviadas nÃ£o fica mais histÃ³rico, e sim atualizaÃ§Ãµes dentro de um protocolo. Assim como o pessoal â€” Ã© abertura interna. Ã‰ como se fosse um processo e vai anexando dados, mensagens, arquivos, e no final encerramos ou baixamos tudo."

## Contexto e mudanÃ§a de paradigma

Hoje a TramitaÃ§Ã£o funciona como uma **caixa de mensagens**: cada item Ã© uma "demanda" com assunto e corpo que trafega de um setor remetente para um setor atual, e "encaminhar" **move** a demanda entre setores. As pastas Recebidas/Enviadas/Arquivadas exibem esse trÃ¡fego como se fossem eâ€‘mails.

Esta feature refatora o mÃ³dulo para o modelo de **Protocolo** (processo administrativo): um contÃªiner persistente ao qual se **incluem setores participantes** e se **anexam atualizaÃ§Ãµes** (mensagens, arquivos, links, dados de outros mÃ³dulos) ao longo do tempo. NÃ£o hÃ¡ mais "encaminhamento que move" â€” todos os setores incluÃ­dos colaboram no mesmo protocolo. O protocolo pode ser **baixado** (exportado em PDF + ZIP) a qualquer momento e, opcionalmente, **encerrado** (fechado definitivamente em somenteâ€‘leitura).

> **Escopo de dados**: substituiÃ§Ã£o total. O Protocolo passa a ser o Ãºnico modelo do mÃ³dulo e os dados atuais de TramitaÃ§Ã£o serÃ£o **resetados no banco** (sem migraÃ§Ã£o de demandas antigas).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Abrir um novo protocolo interno (Priority: P1)

Um operador precisa iniciar uma tramitaÃ§Ã£o interna. Ele abre um **novo protocolo**, informa assunto/descriÃ§Ã£o e **inclui um ou mais setores** que devem participar. O protocolo passa a existir como um contÃªiner ao qual serÃ£o anexadas atualizaÃ§Ãµes.

**Why this priority**: Ã‰ a porta de entrada do novo modelo â€” sem criar protocolo, nada mais existe. Substitui o "compor nova tramitaÃ§Ã£o".

**Independent Test**: Abrir um protocolo com assunto e ao menos um setor incluÃ­do; confirmar que ele aparece na lista "Meus protocolos" do autor e dos membros dos setores incluÃ­dos, com nÃºmero de protocolo prÃ³prio e status "Aberto".

**Acceptance Scenarios**:

1. **Given** um operador autenticado, **When** ele abre um novo protocolo informando assunto e incluindo o Setor A, **Then** o sistema cria o protocolo com nÃºmero Ãºnico, status "Aberto", registra o autor e o Setor A como participante, e registra o evento de abertura na linha do tempo do protocolo.
2. **Given** o formulÃ¡rio de abertura, **When** o operador inclui mais de um setor (A e B), **Then** ambos os setores ficam registrados como participantes do mesmo protocolo desde a abertura.
3. **Given** o formulÃ¡rio de abertura, **When** o operador tenta abrir sem assunto, **Then** o sistema impede a criaÃ§Ã£o com mensagem clara.
4. **Given** um protocolo recÃ©mâ€‘aberto, **When** o autor ou qualquer membro de setor incluÃ­do consulta a lista de protocolos, **Then** o protocolo aparece com o assunto, nÃºmero, status e data da Ãºltima atualizaÃ§Ã£o.

---

### User Story 2 - Incluir setores e colaborar dentro do protocolo (Priority: P1)

Em vez de "encaminhar", o protocolo Ã© colaborativo: **todos os membros dos setores incluÃ­dos** podem visualizar o protocolo e **adicionar atualizaÃ§Ãµes** â€” mensagens, arquivos, links e dados. Novos setores podem ser **incluÃ­dos** ao longo da vida do protocolo (por quem tem permissÃ£o de gestÃ£o), passando a participar da mesma tramitaÃ§Ã£o.

**Why this priority**: Ã‰ o coraÃ§Ã£o do novo paradigma â€” a substituiÃ§Ã£o do "encaminhamento que move de setor" por "inclusÃ£o de setores que colaboram". Sem isso, o protocolo Ã© apenas uma caixa estÃ¡tica.

**Independent Test**: Com um protocolo aberto contendo o Setor A, incluir o Setor B; confirmar que membros de A e B veem o protocolo e ambos conseguem adicionar mensagens/anexos que ficam visÃ­veis para os demais participantes na linha do tempo Ãºnica do protocolo.

**Acceptance Scenarios**:

1. **Given** um protocolo aberto com o Setor A, **When** um membro do Setor A adiciona uma mensagem, **Then** a mensagem passa a compor a linha do tempo do protocolo, visÃ­vel a todos os participantes.
2. **Given** um protocolo aberto, **When** um participante com permissÃ£o de gestÃ£o inclui o Setor B, **Then** os membros do Setor B passam a ver o protocolo em "Meus protocolos" e podem adicionar atualizaÃ§Ãµes, e um evento de "setor incluÃ­do" Ã© registrado.
3. **Given** um protocolo com Setores A e B, **When** um membro do Setor B anexa um arquivo, **Then** o anexo fica vinculado ao protocolo e visÃ­vel aos participantes, respeitando as regras de confidencialidade por documento jÃ¡ existentes.
4. **Given** um participante que **nÃ£o** tem permissÃ£o de gestÃ£o, **When** ele tenta incluir um novo setor, **Then** o sistema impede a aÃ§Ã£o (ele ainda pode adicionar mensagens/anexos).
5. **Given** um protocolo encerrado, **When** qualquer participante tenta adicionar uma atualizaÃ§Ã£o ou incluir setor, **Then** o sistema impede a aÃ§Ã£o (somenteâ€‘leitura).

---

### User Story 3 - Lista Ãºnica "Meus protocolos" (Priority: P1)

O operador acompanha os protocolos em que participa por meio de uma **lista Ãºnica** (substituindo as pastas Recebidas/Enviadas/Arquivadas), ordenada pela **Ãºltima atualizaÃ§Ã£o**, com **filtros por status** (ex.: aberto, encerrado) e busca por assunto/nÃºmero. A lista mostra atualizaÃ§Ãµes do protocolo, nÃ£o um histÃ³rico de mensagens trafegadas.

**Why this priority**: Sem uma forma de encontrar e acompanhar protocolos, o modelo colaborativo nÃ£o Ã© utilizÃ¡vel no dia a dia. Substitui diretamente a inbox de mensagens atual.

**Independent Test**: Participar de dois protocolos; adicionar uma atualizaÃ§Ã£o no segundo; confirmar que ele sobe para o topo da lista "Meus protocolos" e que o filtro por status e a busca por nÃºmero/assunto retornam o protocolo correto.

**Acceptance Scenarios**:

1. **Given** um operador que participa de vÃ¡rios protocolos, **When** ele abre "Meus protocolos", **Then** vÃª a lista de protocolos em que Ã© autor ou membro de setor incluÃ­do, ordenada pela Ãºltima atualizaÃ§Ã£o (mais recente primeiro).
2. **Given** a lista de protocolos, **When** uma nova atualizaÃ§Ã£o Ã© adicionada a um protocolo, **Then** esse protocolo passa a exibir a data/hora da Ãºltima atualizaÃ§Ã£o e reordena para o topo.
3. **Given** a lista com filtro por status, **When** o operador filtra por "Encerrado", **Then** apenas protocolos encerrados sÃ£o exibidos.
4. **Given** a lista, **When** o operador busca por nÃºmero de protocolo ou assunto, **Then** os resultados correspondentes sÃ£o exibidos.

---

### User Story 4 - Tramitar dados de outro mÃ³dulo (entranhar ou abrir) (Priority: P2)

A partir de outro mÃ³dulo (Gabinete, Ouvidoria, JurÃ­dico, Compras, etc.), o operador escolhe **tramitar dados**. Ele pode **abrir um novo protocolo** jÃ¡ vinculado ao registro de origem, ou **entranhar** (anexar) esses dados a um **protocolo existente**, buscando e selecionando o protocolo destino.

**Why this priority**: Integra a TramitaÃ§Ã£o ao restante da plataforma e materializa o fluxo (1) descrito pelo negÃ³cio. Depende do modelo de protocolo jÃ¡ existir (P1), por isso P2.

**Independent Test**: A partir de um registro de outro mÃ³dulo, entranhar os dados em um protocolo existente selecionado por busca; confirmar que o protocolo recebe uma atualizaÃ§Ã£o com o vÃ­nculo/dados de origem e aparece na linha do tempo, sem criar um novo protocolo.

**Acceptance Scenarios**:

1. **Given** um registro em outro mÃ³dulo, **When** o operador escolhe "tramitar dados" e opta por abrir novo protocolo, **Then** um protocolo Ã© criado vinculado ao registro de origem (com snapshot dos dados) e uma atualizaÃ§Ã£o de origem Ã© registrada.
2. **Given** um registro em outro mÃ³dulo, **When** o operador escolhe "tramitar dados" e opta por entranhar em protocolo existente, **Then** ele busca protocolos disponÃ­veis, seleciona um, e os dados sÃ£o anexados como uma nova atualizaÃ§Ã£o daquele protocolo.
3. **Given** a busca de protocolo destino para entranhar, **When** o operador seleciona um protocolo **encerrado**, **Then** o sistema impede o entranhamento (somente protocolos nÃ£o encerrados aceitam novas atualizaÃ§Ãµes).

---

### User Story 5 - Baixar o dossiÃª do protocolo (PDF + ZIP) (Priority: P2)

A qualquer momento â€” mesmo com o protocolo em aberto â€” um participante pode **baixar** o protocolo, gerando um pacote com o dossiÃª em **PDF** (linha do tempo/atualizaÃ§Ãµes) e um **ZIP** com os arquivos anexados que ele tem permissÃ£o de acessar.

**Why this priority**: Entrega o valor de "processo baixÃ¡vel" citado pelo negÃ³cio e Ã© independente do encerramento. P2 por depender do conteÃºdo do protocolo (P1).

**Independent Test**: Em um protocolo aberto com mensagens e anexos, acionar "Baixar"; confirmar a geraÃ§Ã£o de um PDF com o histÃ³rico e um ZIP com os arquivos acessÃ­veis ao solicitante, respeitando confidencialidade.

**Acceptance Scenarios**:

1. **Given** um protocolo aberto com atualizaÃ§Ãµes e anexos, **When** um participante aciona "Baixar", **Then** o sistema gera um PDF do dossiÃª (assunto, participantes, linha do tempo/atualizaÃ§Ãµes) e um ZIP com os anexos que o solicitante pode acessar.
2. **Given** um protocolo com anexos confidenciais, **When** um participante **sem** acesso a um anexo confidencial baixa o dossiÃª, **Then** o conteÃºdo desse anexo nÃ£o Ã© incluÃ­do no ZIP (respeitando a ACL existente), embora sua existÃªncia possa ser indicada no PDF conforme regras de confidencialidade.
3. **Given** um protocolo encerrado, **When** um participante aciona "Baixar", **Then** o dossiÃª Ã© gerado normalmente (baixar independe de encerramento).

---

### User Story 6 - Encerrar o protocolo (Priority: P2)

Quando a tramitaÃ§Ã£o termina, um participante **com permissÃ£o de gestÃ£o** pode **encerrar** o protocolo. O encerramento Ã© **definitivo**: o protocolo fica em **somenteâ€‘leitura permanente** (nÃ£o aceita novas atualizaÃ§Ãµes, inclusÃ£o de setores, nem reabertura). O conteÃºdo continua consultÃ¡vel e baixÃ¡vel.

**Why this priority**: Fecha o ciclo de vida do processo. P2 por ser o passo final e depender do fluxo colaborativo (P1).

**Independent Test**: Encerrar um protocolo como participante com permissÃ£o; confirmar que novas atualizaÃ§Ãµes/inclusÃµes sÃ£o bloqueadas, que o status muda para "Encerrado", e que nÃ£o hÃ¡ aÃ§Ã£o de reabrir.

**Acceptance Scenarios**:

1. **Given** um protocolo aberto, **When** um participante com permissÃ£o de gestÃ£o o encerra, **Then** o status muda para "Encerrado", um evento de encerramento Ã© registrado (autor, data/hora, motivo opcional) e o protocolo entra em somenteâ€‘leitura.
2. **Given** um protocolo encerrado, **When** qualquer usuÃ¡rio tenta reabriâ€‘lo, **Then** nÃ£o existe aÃ§Ã£o de reabertura disponÃ­vel e o sistema mantÃ©m o estado encerrado.
3. **Given** um participante **sem** permissÃ£o de gestÃ£o, **When** ele tenta encerrar, **Then** o sistema impede a aÃ§Ã£o.

---

### User Story 7 - Protocolo pessoal (abertura interna 1:1) (Priority: P3)

O operador pode abrir um **protocolo pessoal** â€” uma abertura interna direcionada a **outro usuÃ¡rio** (1:1), sem incluir setores. Ã‰ um tipo separado de protocolo, com a mesma mecÃ¢nica de atualizaÃ§Ãµes, baixar e encerrar, mas com participantes pessoais em vez de setores.

**Why this priority**: Preserva o caso de uso "pessoal" jÃ¡ existente no modelo atual, adaptado ao protocolo. P3 por ser uma variaÃ§Ã£o sobre a base colaborativa (P1/P2).

**Independent Test**: Abrir um protocolo pessoal para outro usuÃ¡rio; confirmar que apenas os dois participantes o veem em "Meus protocolos" e que ambos podem adicionar atualizaÃ§Ãµes; validar baixar e encerrar.

**Acceptance Scenarios**:

1. **Given** um operador, **When** ele abre um protocolo pessoal para o usuÃ¡rio X, **Then** o protocolo Ã© criado como tipo "pessoal", visÃ­vel apenas ao autor e ao usuÃ¡rio X, e registra o evento de abertura.
2. **Given** um protocolo pessoal, **When** o usuÃ¡rio X adiciona uma mensagem/anexo, **Then** a atualizaÃ§Ã£o aparece na linha do tempo visÃ­vel aos dois participantes.
3. **Given** um protocolo pessoal, **When** o autor tenta incluir um setor, **Then** o sistema nÃ£o oferece/permite inclusÃ£o de setor (protocolo pessoal Ã© 1:1 entre usuÃ¡rios).

---

### User Story 8 - Conceder permissÃ£o de gestÃ£o a participantes (Priority: P3)

Por padrÃ£o, apenas o **autor** do protocolo pode incluir setores e encerrar. O autor (ou quem jÃ¡ tem gestÃ£o) pode **conceder permissÃ£o de gestÃ£o** a outros participantes incluÃ­dos, ampliando quem pode gerenciar o protocolo.

**Why this priority**: Refinamento das permissÃµes; o MVP funciona apenas com o autor gerenciando. P3.

**Independent Test**: Como autor, conceder gestÃ£o a um participante; confirmar que esse participante passa a poder incluir setores e encerrar, e que outros participantes sem a permissÃ£o continuam sem essas aÃ§Ãµes.

**Acceptance Scenarios**:

1. **Given** um protocolo com autor e participantes, **When** o autor concede permissÃ£o de gestÃ£o ao participante Y, **Then** Y passa a poder incluir setores e encerrar o protocolo.
2. **Given** um participante sem permissÃ£o de gestÃ£o, **When** ele tenta conceder gestÃ£o a alguÃ©m, **Then** o sistema impede a aÃ§Ã£o.

---

### Edge Cases

- **Sem setor na abertura (protocolo setorial)**: se o operador tenta abrir um protocolo setorial sem incluir nenhum setor, o sistema deve exigir ao menos um participante (setor) â€” exceto no tipo pessoal, que exige um usuÃ¡rio destinatÃ¡rio.
- **Remover setor incluÃ­do**: fora de escopo desta versÃ£o â€” a inclusÃ£o de setores nÃ£o Ã© revogÃ¡vel (nÃ£o hÃ¡ "excluir setor" de um protocolo); definir como melhoria futura se necessÃ¡rio.
- **Entranhar em protocolo encerrado**: bloqueado â€” somente protocolos nÃ£o encerrados aceitam novas atualizaÃ§Ãµes/entranhamento.
- **Atualizar/incluir apÃ³s encerramento**: bloqueado (somenteâ€‘leitura permanente).
- **Anexo confidencial e desentranhamento**: as regras das features 033 (confidencialidade por documento) e 034 (desentranhamento) continuam valendo integralmente dentro do protocolo; um documento confidencial ou desentranhado mantÃ©m seu comportamento de visibilidade/ACL.
- **Baixar com anexos confidenciais/desentranhados**: o pacote (ZIP) inclui apenas o que o solicitante tem permissÃ£o de acessar; documentos desentranhados seguem as regras de acesso ao histÃ³rico jÃ¡ definidas.
- **Ãšltimo participante / autor sem setor**: se o autor abre um protocolo pessoal, o destinatÃ¡rio 1:1 Ã© obrigatÃ³rio (nÃ£o hÃ¡ protocolo pessoal sem contraparte).
- **ConcorrÃªncia ao encerrar**: se dois gestores tentam encerrar simultaneamente, a primeira aÃ§Ã£o encerra e a segunda Ã© informada de que o protocolo jÃ¡ estÃ¡ encerrado.
- **Busca para entranhar sem resultados**: se nÃ£o houver protocolos elegÃ­veis, o operador pode optar por abrir um novo protocolo em vez de entranhar.

## Requirements *(mandatory)*

### Functional Requirements

**Modelo e abertura**

- **FR-001**: O sistema DEVE tratar o **Protocolo** como a entidade central do mÃ³dulo de TramitaÃ§Ã£o, substituindo o modelo de "demanda/mensagem" atual.
- **FR-002**: O sistema DEVE permitir abrir um **novo protocolo** informando assunto/descriÃ§Ã£o e incluindo ao menos um participante (um ou mais **setores**, no protocolo setorial; um **usuÃ¡rio destinatÃ¡rio**, no protocolo pessoal).
- **FR-003**: O sistema DEVE atribuir a cada protocolo um **nÃºmero Ãºnico** por tenant e registrar o **autor** e a **data de abertura**.
- **FR-004**: O sistema DEVE suportar dois **tipos de protocolo**: **setorial** (participaÃ§Ã£o por setores) e **pessoal** (abertura interna 1:1 entre usuÃ¡rios), mantidos como tipos distintos.

**ParticipaÃ§Ã£o e colaboraÃ§Ã£o (substitui "encaminhar")**

- **FR-005**: O sistema NÃƒO DEVE oferecer a aÃ§Ã£o de "encaminhar que move de setor"; em vez disso, DEVE permitir **incluir setores** como participantes do protocolo.
- **FR-006**: O sistema DEVE conceder a **todos os membros dos setores incluÃ­dos** a capacidade de **visualizar** o protocolo e **adicionar atualizaÃ§Ãµes** (mensagens, arquivos, links, dados).
- **FR-007**: O sistema DEVE registrar todas as atualizaÃ§Ãµes em uma **linha do tempo Ãºnica** do protocolo, visÃ­vel a todos os participantes (respeitando confidencialidade por documento).
- **FR-008**: O sistema DEVE permitir **incluir novos setores** ao longo da vida do protocolo, restrito a participantes com **permissÃ£o de gestÃ£o**, registrando o evento de inclusÃ£o.
- **FR-009**: O sistema DEVE, por padrÃ£o, atribuir a **permissÃ£o de gestÃ£o** (incluir setores e encerrar) apenas ao **autor** do protocolo, permitindo que o autor (ou quem jÃ¡ tem gestÃ£o) a **conceda** a outros participantes.

**Lista e navegaÃ§Ã£o (substitui Recebidas/Enviadas)**

- **FR-010**: O sistema DEVE apresentar uma **lista Ãºnica de "Meus protocolos"** contendo os protocolos em que o usuÃ¡rio Ã© autor ou membro de setor incluÃ­do (ou participante pessoal), substituindo as pastas Recebidas/Enviadas/Arquivadas.
- **FR-011**: A lista DEVE ser ordenada pela **Ãºltima atualizaÃ§Ã£o** (mais recente primeiro) e oferecer **filtro por status** e **busca** por assunto e nÃºmero de protocolo.

**Tramitar dados / entranhar (crossâ€‘mÃ³dulo)**

- **FR-012**: O sistema DEVE permitir, a partir de outros mÃ³dulos, **tramitar dados** com duas opÃ§Ãµes: **abrir novo protocolo** vinculado ao registro de origem, ou **entranhar** os dados em um **protocolo existente** selecionado por busca.
- **FR-013**: Ao abrir protocolo a partir de outro mÃ³dulo, o sistema DEVE registrar o **vÃ­nculo e um snapshot** dos dados de origem como uma atualizaÃ§Ã£o do protocolo.
- **FR-014**: O sistema DEVE impedir o entranhamento de dados em protocolos **encerrados**.

**Baixar (exportaÃ§Ã£o)**

- **FR-015**: O sistema DEVE permitir **baixar** o protocolo a qualquer momento (independente de estar encerrado), gerando um **PDF** do dossiÃª (assunto, participantes e linha do tempo de atualizaÃ§Ãµes) e um **ZIP** com os anexos que o solicitante tem permissÃ£o de acessar.
- **FR-016**: A exportaÃ§Ã£o DEVE respeitar as regras de **confidencialidade** e **desentranhamento** existentes â€” incluindo no ZIP apenas conteÃºdos acessÃ­veis ao solicitante.

**Encerrar (ciclo de vida)**

- **FR-017**: O sistema DEVE permitir **encerrar** um protocolo, restrito a participantes com **permissÃ£o de gestÃ£o**, registrando autor, data/hora e motivo (opcional) do encerramento.
- **FR-018**: Um protocolo **encerrado** DEVE ficar em **somenteâ€‘leitura permanente**: nÃ£o aceita novas atualizaÃ§Ãµes, inclusÃ£o de setores, entranhamento, nem **reabertura**.
- **FR-019**: O conteÃºdo de um protocolo encerrado DEVE permanecer **consultÃ¡vel e baixÃ¡vel**.
- **FR-020**: O sistema DEVE aplicar a regra de "primeira aÃ§Ã£o vale" ao encerrar: se o protocolo jÃ¡ estiver encerrado, novas tentativas de encerramento DEVEM ser informadas de que jÃ¡ estÃ¡ encerrado.

**Compatibilidade com features existentes**

- **FR-021**: O sistema DEVE **preservar** o comportamento de **anexos confidenciais** (feature 033) e de **desentranhamento de documentos** (feature 034) dentro do protocolo, sem alterar quem tem acesso a cada anexo.
- **FR-022**: O sistema DEVE **notificar** os participantes relevantes (via canal de notificaÃ§Ã£o inâ€‘app existente) nos eventosâ€‘chave: inclusÃ£o em protocolo/setor, novas atualizaÃ§Ãµes e encerramento. *(Detalhamento de quais eventos geram notificaÃ§Ã£o serÃ¡ refinado no planejamento.)*

**Dados/migraÃ§Ã£o**

- **FR-023**: O sistema NÃƒO precisa migrar demandas antigas: os dados atuais de TramitaÃ§Ã£o serÃ£o **resetados**, e o Protocolo inicia como o Ãºnico modelo do mÃ³dulo.

### Key Entities *(include if feature involves data)*

- **Protocolo**: contÃªiner central da tramitaÃ§Ã£o. Atributos principais: nÃºmero Ãºnico por tenant, assunto/descriÃ§Ã£o, tipo (setorial | pessoal), autor, status (aberto | encerrado), data de abertura, data/motivo de encerramento (quando aplicÃ¡vel), data da Ãºltima atualizaÃ§Ã£o. Relacionaâ€‘se com participantes, atualizaÃ§Ãµes (linha do tempo) e anexos.
- **Participante do Protocolo**: representa quem participa â€” um **setor** incluÃ­do (protocolo setorial) ou um **usuÃ¡rio** (protocolo pessoal / concessÃ£o de gestÃ£o). Atributos: referÃªncia ao setor ou usuÃ¡rio, indicaÃ§Ã£o de **permissÃ£o de gestÃ£o**, data de inclusÃ£o.
- **AtualizaÃ§Ã£o (evento da linha do tempo)**: entrada cronolÃ³gica no protocolo â€” mensagem, inclusÃ£o de setor, anexaÃ§Ã£o de arquivo/link, vÃ­nculo/entranhamento de dados de outro mÃ³dulo, encerramento. Atributos: tipo, autor, data/hora, conteÃºdo/payload, anexos vinculados (quando houver).
- **Anexo do Protocolo**: arquivo ou link juntado a uma atualizaÃ§Ã£o; mantÃ©m os atributos e comportamentos jÃ¡ existentes de **confidencialidade** (033) e **desentranhamento** (034).
- **VÃ­nculo de origem (crossâ€‘mÃ³dulo)**: referÃªncia a um registro de outro mÃ³dulo (Gabinete/Ouvidoria/JurÃ­dico/Compras) e snapshot dos dados, associado ao protocolo quando os dados sÃ£o tramitados/entranhados.
- **DossiÃª exportado**: pacote gerado sob demanda (PDF do histÃ³rico + ZIP dos anexos acessÃ­veis) representando o estado do protocolo no momento da exportaÃ§Ã£o.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Um operador consegue abrir um novo protocolo e incluir ao menos um setor em menos de **1 minuto**, sem apoio tÃ©cnico.
- **SC-002**: **100%** das atualizaÃ§Ãµes (mensagens, anexos, inclusÃµes de setor) adicionadas por qualquer participante ficam visÃ­veis aos demais participantes na linha do tempo Ãºnica do protocolo.
- **SC-003**: A lista "Meus protocolos" reflete a **Ãºltima atualizaÃ§Ã£o** de um protocolo em segundos apÃ³s a atualizaÃ§Ã£o e o reordena para o topo.
- **SC-004**: **100%** dos protocolos podem ser baixados (PDF + ZIP) a qualquer momento, estejam abertos ou encerrados, incluindo no ZIP apenas conteÃºdos acessÃ­veis ao solicitante.
- **SC-005**: **100%** dos protocolos encerrados rejeitam novas atualizaÃ§Ãµes, inclusÃµes de setor e entranhamento, e nÃ£o oferecem reabertura.
- **SC-006**: **0** casos de acesso indevido a anexos confidenciais/desentranhados por meio do protocolo ou de sua exportaÃ§Ã£o (as ACLs existentes permanecem Ã­ntegras).
- **SC-007**: Nenhum documento ou atualizaÃ§Ã£o Ã© removido definitivamente pelo fluxo de encerramento â€” **100%** do conteÃºdo permanece consultÃ¡vel e exportÃ¡vel apÃ³s encerrar.

## Assumptions

- **SubstituiÃ§Ã£o total e reset de dados**: o Protocolo substitui integralmente o modelo de demanda/mensagem, e os dados atuais de TramitaÃ§Ã£o serÃ£o apagados/resetados no banco (ambiente ainda em desenvolvimento); nÃ£o hÃ¡ requisito de migraÃ§Ã£o de demandas antigas.
- **Terminologia canÃ´nica**: a entidade central chamaâ€‘se **Protocolo** na UI e na linguagem de produto (PTâ€‘BR). O prefixo/format exato do nÃºmero de protocolo (ex.: manter `TRAM-AAAA-NNNN` ou adotar novo prefixo) serÃ¡ decidido no planejamento.
- **Acesso setorial**: todos os membros ativos de um setor incluÃ­do tÃªm acesso de leitura e de adicionar atualizaÃ§Ãµes; nÃ£o hÃ¡, nesta versÃ£o, granularidade de "apenas alguns usuÃ¡rios do setor" (exceto pela confidencialidade por documento jÃ¡ existente).
- **PermissÃ£o de gestÃ£o**: por padrÃ£o pertence ao autor; incluir setores e encerrar exigem essa permissÃ£o; concedÃªâ€‘la a outros participantes Ã© um refinamento (US8/P3), e o MVP pode operar apenas com o autor gerenciando.
- **Encerramento definitivo**: nÃ£o hÃ¡ reabertura nesta versÃ£o; se for necessÃ¡rio no futuro, serÃ¡ tratado como nova feature.
- **Baixar independe de encerrar**: a exportaÃ§Ã£o (PDF + ZIP) estÃ¡ disponÃ­vel a qualquer momento.
- **Modo pessoal preservado**: o protocolo pessoal Ã© 1:1 entre usuÃ¡rios, sem inclusÃ£o de setores, e reaproveita a mecÃ¢nica de atualizaÃ§Ãµes/baixar/encerrar.
- **NotificaÃ§Ãµes**: reaproveita o canal inâ€‘app existente (feature 029); o conjunto exato de eventos notificados serÃ¡ refinado no planejamento.
- **Features 033/034 preservadas**: confidencialidade por documento e desentranhamento continuam vÃ¡lidos dentro do protocolo, sem alteraÃ§Ã£o de quem tem acesso.
- **RelaÃ§Ã£o com o plano ativo 034**: como 034 (desentranhamento) atua sobre a mesma entidade e estÃ¡ em curso, a sequÃªncia de implementaÃ§Ã£o (concluir 034 antes, ou reconciliar durante) serÃ¡ decidida no `/speckit-plan`; esta spec assume que o comportamento de desentranhamento Ã© **preservado**.
- **RemoÃ§Ã£o de participantes**: nÃ£o hÃ¡ revogaÃ§Ã£o/remoÃ§Ã£o de setores de um protocolo nesta versÃ£o.
- **ExportaÃ§Ã£o**: o formato do dossiÃª Ã© PDF (histÃ³rico) + ZIP (arquivos); layout e detalhes de composiÃ§Ã£o serÃ£o definidos no planejamento.
