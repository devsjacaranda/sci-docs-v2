# Feature Specification: Download em Massa de Manifestações (Ouvidoria)

**Feature Branch**: `054-download-massa-manifestacoes`

**Created**: 2026-10-08

**Revisado**: 2026-10-09 (correção de formato: **PDF único**; ver "Session 2026-10-09")

**Status**: Draft

**Input**: User description: "Download em massa de manifestações — baixar PDF, incluso imagens, docs, etc. Ex.: selecionar várias manifestações, baixar em massa e gerar PDF delas. Cuidados e otimizações máximas para dividir a carga entre servidor e client side: caches, fracionamento em blocos (chunking), streaming em vez de download comum. Qualquer dúvida ou área cinzenta deve ser perguntada obrigatoriamente." **Correção (2026-10-09):** "é pra gerar um pdf só com todos os pdfs e imagens anexados nele; só pra gerar outros arquivos que não dá pra colocar em PDF, aí fica fora."

**Relacionamento**: Estende o PDF individual da manifestação (`documento/pdf`, com anexos embutidos e timbrado do tenant — [046 timbrado-ageman-2026](../046-timbrado-ageman-2026/spec.md)) para múltiplas manifestações em uma só entrega. Regra de acesso por manifestação: [047 acesso-ouvidoria-ageman](../047-acesso-ouvidoria-ageman/spec.md). Exclusão de anexos (afeta a invalidação do reuso): [053 excluir-anexos-ouvidoria](../arquivados/053-excluir-anexos-ouvidoria/STATUS.md). Norma de UI da lista/modais: [040 dossie-detalhe-ui](../040-dossie-detalhe-ui/spec.md).

## Clarifications

### Session 2026-10-08

- Q: Como o usuário seleciona as manifestações? → A: **Botão "Baixar em massa" na lista de manifestações abre um modal** com campo de seleção (dropdown de múltipla escolha com busca digitável). Itens identificados pelo **protocolo** (formato `2026-3-09-0003`) ou número personalizado; escolhidos viram "chips" removíveis. **A lista em si não ganha checkboxes por linha.**
- Q: Manifestações sem número personalizado entram na seleção? → A: **Sim**: a busca do dropdown encontra por número personalizado **ou** protocolo do sistema, exibindo o que existir.
- Q: Reuso (cache) de PDFs já gerados? → A: **Sim, persistente**: o PDF pronto de cada manifestação é guardado e reaproveitado por **até 24 horas** enquanto nada mudar. É invalidado em qualquer alteração da manifestação, de seus anexos (inclusive exclusão — 053) ou da tramitação.
- Q: Manifestações sem acesso (regra 047) no lote? → A: **Recusar o lote inteiro**, informando quais manifestações impedem o download. Nada é gerado.
- Q: Manifestação com anexos acima de 200MB (limite do PDF individual)? → A: **Sem limite por manifestação em massa**: vale apenas o teto do lote (~300 MB de anexos de arquivo, ver 2026-10-09). O limite de 200MB continua valendo só no PDF individual.
- Q: Carimbo "Documento gerado em" no PDF reaproveitado (cache de 24h)? → A: **Mantém o momento real da geração do conteúdo** (pode ser de até 24h antes do download). Data/hora e autor do **download** ficam na página-resumo final do lote e na auditoria.
- Q: O usuário navega para outra tela durante o download? → A: **O download continua** e um indicador de progresso discreto fica visível em qualquer tela, com botão Cancelar. Só cancela por ação explícita ou fechamento da aba.
- Q: Quem pode usar o "Baixar em massa"? → A: **Qualquer usuário do módulo Ouvidoria**; o controle real é a regra de acesso de cada manifestação (047) combinada com "recusar o lote inteiro".
- Q: O PDF guardado fica no armazenamento depois de expirar ou de ser invalidado? → A: **Não.** Com mais de 24 h ele deixa de ser servido e é apagado nesse acesso. Quando uma revisão nova é gravada, as anteriores da mesma manifestação são apagadas. Uma regra de ciclo de vida de 48 h no armazenamento é só rede de segurança se a exclusão falhar.

### Session 2026-10-09 (correção — substitui as respostas anteriores sobre formato, índice, limite e entrega)

- Q: Formato da entrega? → A: **Um único PDF** com todas as manifestações escolhidas. Anexos JPG/PNG/PDF ficam **embutidos nele**. Não há mais "1 PDF por manifestação dentro de um ZIP", nem `indice-do-lote.pdf`, nem `lote.txt`.
- Q: Estrutura do PDF único? → A: Para cada manifestação, em ordem da seleção: **uma página inteira de separação** + o **dossiê completo** (dados, tramitação, timbrado e anexos embutidos). No **fim** do PDF, uma **página-resumo do lote**.
- Q: Anexos que não cabem em PDF (Word, Excel, TXT, MP3, MP4…)? → A: Ficam **fora do PDF**. Se **não houver nenhum**, o usuário baixa só o `.pdf`. Se houver, baixa um `.zip` com o PDF único + os originais (pasta `<manifestação>/anexos/`). O nome do arquivo (extensão `.pdf` ou `.zip`) é definido pelo servidor.
- Q: Conteúdo da página de separação? → A: Protocolo/número personalizado e as listas de anexos **embutidos**, **fora do PDF** e **indisponíveis**.
- Q: Conteúdo da página-resumo final? → A: Data/hora do download, autor, manifestações incluídas, anexos fora do PDF e indisponíveis (com motivo), e por manifestação se o dossiê foi **gerado agora** ou **reaproveitado** (com o momento da geração original).
- Q: PDF/imagem anexado corrompido? → A: O **original vai para fora do PDF** (no ZIP) e é listado com motivo `pdf-invalido`. Se o armazenamento não devolve o arquivo: só listado como indisponível, motivo `armazenamento`.
- Q: Limites? → A: **50 manifestações** e **~300 MB** (300 MiB) de soma de anexos de arquivo (antes ~1 GB), porque a junção do PDF único é feita em memória no servidor.
- Q: Cache de 24 h do dossiê individual? → A: **Mantém.**
- Q: Como o arquivo chega ao navegador? → A: **Sempre pelo download nativo do navegador** (sem seletor de local de salvamento), porque o servidor só sabe se a entrega é `.pdf` ou `.zip` no fim. O **arquivo só começa a chegar depois da montagem completa** no servidor (build no GET, depois envio a partir de arquivos temporários). O indicador continua mostrando "N de total" e **Cancelar**.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Selecionar várias manifestações e baixar um PDF único (Priority: P1)

Como usuário da Ouvidoria, quero abrir um modal pelo botão "Baixar em massa" na lista de manifestações, buscar e escolher várias manifestações pelo protocolo e baixar tudo de uma vez em **um único PDF** com o dossiê completo de cada uma (dados, timbrado, imagens e PDFs anexados embutidos), para arquivar, auditar ou enviar sem baixar uma por uma.

**Why this priority**: É o núcleo do pedido. Hoje só existe o download individual; reunir dezenas de manifestações exige dezenas de cliques e arquivos soltos.

**Independent Test**: Na lista de manifestações, clicar em "Baixar em massa", selecionar 3 manifestações pelo protocolo (ex.: `2026-3-09-0003`), confirmar e verificar que o arquivo baixado é **um único `.pdf`** com 3 páginas de separação, cada uma seguida do dossiê da respectiva manifestação, e uma página-resumo no fim.

**Acceptance Scenarios**:

1. **Given** a lista de manifestações, **When** o usuário clica em "Baixar em massa", **Then** abre um modal com um campo de seleção múltipla com busca digitável, contador de itens escolhidos e botão de confirmar desabilitado enquanto nada estiver escolhido.
2. **Given** o modal aberto, **When** o usuário digita parte de um protocolo ou número personalizado, **Then** o dropdown mostra as manifestações correspondentes (inclusive as sem número personalizado, identificadas pelo protocolo) e permite escolher várias, que aparecem como chips removíveis.
3. **Given** 3 manifestações escolhidas e permitidas ao usuário e **sem** anexos fora do PDF, **When** ele confirma, **Then** o navegador baixa um único `.pdf` nomeado `manifestacoes-ouvidoria-AAAAMMDD-HHmm.pdf`, com, para cada manifestação na ordem escolhida, uma página de separação e o dossiê completo.
4. **Given** uma manifestação com imagens JPG/PNG e PDFs anexados, **When** o PDF único é gerado, **Then** esses anexos estão embutidos no dossiê dessa manifestação, com o mesmo conteúdo e timbrado do PDF individual.
5. **Given** a lista de manifestações, **When** o usuário não abre o modal, **Then** a lista continua exatamente como hoje (sem checkboxes por linha).
6. **Given** um lote concluído, **When** o usuário abre o PDF, **Then** a **última página** é o resumo do lote (data/hora do download, autor, manifestações, anexos fora do PDF e indisponíveis, gerado agora × reaproveitado).

---

### User Story 2 - Acompanhar a montagem com progresso e cancelamento, sem travar (Priority: P1)

Como usuário baixando um lote grande, quero ver o andamento da montagem ("12 de 50 manifestações") e poder cancelar, para não ficar olhando uma tela parada, nem travar o navegador ou derrubar o servidor.

**Why this priority**: É o requisito de otimização do pedido (divisão de carga). Sem isso, lotes grandes estouram memória ou parecem "travados".

**Independent Test**: Baixar um lote de ~50 manifestações e verificar que (a) o indicador mostra o progresso avançando manifestação a manifestação, (b) o navegador permanece responsivo, (c) o servidor usa memória/disco de forma limitada (arquivos temporários removidos ao fim) e (d) cancelar interrompe o trabalho do servidor.

**Acceptance Scenarios**:

1. **Given** um lote válido confirmado, **When** o servidor começa a montar, **Then** o navegador dispara o download nativo imediatamente e o indicador mostra "0 de N manifestações" com aviso de que o arquivo é montado no servidor.
2. **Given** a montagem em andamento, **When** cada manifestação é concluída, **Then** o indicador mostra o progresso (ex.: "12 de 50 manifestações").
3. **Given** a montagem em andamento, **When** o usuário clica em "Cancelar" (ou fecha a aba), **Then** o servidor interrompe a geração, libera os recursos e remove os arquivos temporários.
4. **Given** um lote grande, **When** o PDF é montado, **Then** o servidor trabalha por manifestação (dossiê gravado em arquivo temporário), limita o volume de anexos a ~300 MB e **nunca** monta o lote em memória sem esse teto.
5. **Given** a conexão do usuário caiu no meio do download, **When** ele tenta de novo, **Then** o processo recomeça do zero e reaproveita o que já estiver pronto (US3), sem deixar lixo ou processamento órfão no servidor.
6. **Given** a montagem terminou, **When** o servidor começa a enviar, **Then** o arquivo é enviado a partir de arquivos temporários (stream) e o indicador mostra "Download concluído." ao término.

---

### User Story 3 - Reaproveitar dossiês já gerados sem mostrar dados desatualizados (Priority: P2)

Como usuário (e como operador da plataforma), quero que o dossiê de uma manifestação já gerado recentemente seja reaproveitado quando nada mudou nela, para que pedidos repetidos ou sobrepostos sejam muito mais rápidos e consumam menos servidor — sem nunca entregar conteúdo desatualizado.

**Why this priority**: Reduz muito a carga (gerar PDF com anexos embutidos é a parte mais cara) e acelera a segunda tentativa após falha/cancelamento. Vem depois do núcleo porque o download funciona sem ele.

**Independent Test**: Baixar o lote A; baixar de novo o mesmo lote e confirmar que o segundo é visivelmente mais rápido; alterar uma manifestação (ex.: tramitar, excluir um anexo, editar) e baixar de novo, confirmando que o dossiê dessa manifestação reflete a mudança.

**Acceptance Scenarios**:

1. **Given** um dossiê gerado há menos de 24 horas e sem alterações desde então, **When** a manifestação é incluída em um novo lote, **Then** o dossiê pronto é reaproveitado em vez de ser gerado de novo.
2. **Given** um dossiê guardado, **When** a manifestação, um anexo, a tramitação ou o encerramento sofrem qualquer alteração, **Then** o dossiê guardado deixa de ser usado e o próximo download gera um novo.
3. **Given** um anexo excluído conforme a spec 053, **When** o dossiê guardado dessa manifestação existia, **Then** ele é descartado e o conteúdo excluído não aparece em nenhum download posterior.
4. **Given** um dossiê guardado com mais de 24 horas, **When** a manifestação é incluída em um lote, **Then** ele é descartado/ignorado e gerado de novo.
5. **Given** o dossiê guardado de uma manifestação, **When** um usuário **sem** acesso a ela (regra 047) pede o download, **Then** o acesso é negado — o reuso nunca contorna a verificação de acesso.
6. **Given** manifestações de instituições (tenants) diferentes, **When** há dossiês guardados, **Then** um tenant nunca recebe o de outro.
7. **Given** um dossiê guardado cujas pendências de embutimento (anexo indisponível / `pdf-invalido`) foram registradas, **When** ele é reaproveitado, **Then** as mesmas pendências reaparecem no PDF único; dossiê guardado sem esse registro não é reaproveitado.

---

### User Story 4 - Recusar o lote inteiro quando houver manifestação sem acesso, ou quando passar do limite (Priority: P1)

Como responsável pela segurança dos dados da Ouvidoria, quero que o download em massa recuse o lote inteiro se qualquer manifestação escolhida for proibida ao usuário, ou se o lote ultrapassar o teto de 50 manifestações / ~300 MB, informando com clareza o motivo e quais itens causam o problema, para que nada vaze e ninguém seja surpreendido por um arquivo incompleto.

**Why this priority**: É a barreira de segurança e de proteção do servidor. Sem ela, o botão viraria um atalho para extrair volume de dados sensíveis ou para derrubar o servidor.

**Independent Test**: Escolher 4 manifestações, sendo 1 sem acesso: o modal recusa e indica qual é, sem baixar nada. Escolher 51 manifestações: o modal recusa antes de começar. Escolher um lote cujo total de anexos passa de ~300 MB: recusa informando o excesso.

**Acceptance Scenarios**:

1. **Given** uma seleção em que ao menos uma manifestação não é permitida ao usuário (regra 047, inclusive por chamada direta ao serviço), **When** ele confirma, **Then** nenhum arquivo é gerado, o sistema retorna acesso negado (403) e o modal lista as manifestações que impedem o download.
2. **Given** uma seleção com mais de 50 manifestações, **When** ele tenta confirmar (ou quando a escolha ultrapassa 50 no dropdown), **Then** a seleção é impedida/recusada com mensagem clara do limite.
3. **Given** uma seleção cuja soma dos anexos de arquivo excede ~300 MB, **When** ele confirma, **Then** o lote é recusado **antes** de qualquer geração, com mensagem indicando o excesso e orientando a reduzir a seleção.
4. **Given** um identificador que não existe, pertence a outro tenant ou a manifestação removida (exclusão lógica), **When** aparece na seleção (inclusive por chamada direta), **Then** o lote é recusado como "não encontrada", sem revelar dados de outro tenant.
5. **Given** uma recusa por qualquer motivo acima, **When** o modal mostra o erro, **Then** o usuário pode ajustar a seleção e tentar de novo sem fechar o modal.

---

### User Story 5 - Anexos fora do PDF e falhas parciais ficam transparentes (Priority: P2)

Como usuário, quero que os anexos que não cabem em PDF (Word, Excel, TXT, MP3, MP4) venham como arquivos originais **fora do PDF** (num ZIP junto com o PDF único), e que qualquer falha na leitura de um anexo seja informada no próprio PDF, para que eu nunca receba um dossiê incompleto sem saber.

**Why this priority**: Hoje, no PDF individual, anexos que falham ao ser lidos são silenciosamente omitidos; em massa isso esconderia perda de informação em dezenas de dossiês.

**Independent Test**: Baixar um lote com manifestações que têm anexo `.docx`, `.xlsx` e `.mp4`, e com um anexo cujo arquivo não está mais disponível. Verificar que o ZIP traz o PDF único e os originais em `<manifestação>/anexos/`, que a página de separação e a página-resumo listam os "fora do PDF" e o anexo indisponível. Baixar um lote só com JPG/PNG/PDF: o download é só o `.pdf`.

**Acceptance Scenarios**:

1. **Given** uma manifestação com anexos Word/Excel/TXT/MP3/MP4, **When** o lote é gerado, **Then** o download é um `.zip` com o PDF único + esses originais em `<manifestação>/anexos/`, e a página de separação e a página-resumo os listam como "fora do PDF".
2. **Given** um lote sem nenhum anexo fora do PDF, **When** o lote é gerado, **Then** o download é apenas o `.pdf` (sem ZIP).
3. **Given** anexos do tipo link externo, **When** o PDF é gerado, **Then** eles aparecem listados como referência (sem arquivo), como no PDF individual.
4. **Given** um anexo cujo arquivo não pôde ser lido do armazenamento, **When** o lote é gerado, **Then** ele consta como **indisponível** (manifestação, nome do arquivo, motivo `armazenamento`) na página de separação e na página-resumo, e o download conclui com os demais conteúdos.
5. **Given** um PDF ou imagem anexado cujos bytes foram lidos mas não foi possível embutir, **When** o lote é gerado, **Then** o original vai para fora do PDF (ZIP) e é listado com motivo `pdf-invalido`.
6. **Given** uma falha irrecuperável **durante** a geração de uma manifestação (não de um anexo isolado), **When** isso ocorre, **Then** o download é encerrado como falha clara (sem entregar arquivo corrompido/incompleto como se estivesse completo) e o usuário pode tentar de novo.

---

### User Story 6 - Rastro de quem baixou o quê (Priority: P3)

Como auditor, quero que cada download em massa fique registrado (quem, quando, quais manifestações, resultado), para investigar vazamentos ou provar quem teve acesso a quais dossiês.

**Why this priority**: Importante para governança, mas não bloqueia o uso. Download em volume de dados sensíveis exige rastreabilidade.

**Independent Test**: Realizar um download em massa bem-sucedido, um recusado e um cancelado; verificar que os três aparecem no registro de auditoria com autor, data/hora, quantidade e lista de manifestações.

**Acceptance Scenarios**:

1. **Given** um download em massa concluído, **When** o auditor consulta o registro, **Then** vê o autor (inclusive quando é `admin_tenant`/`admin_saas`, registrado com seu papel), data/hora, quantidade de manifestações, quais manifestações e tamanho total.
2. **Given** um pedido recusado (sem acesso ou acima do limite) ou cancelado/falho, **When** consulta o registro, **Then** o resultado e o motivo constam.
3. **Given** o registro, **When** ele é exibido, **Then** ele não contém o conteúdo dos PDFs nem dados pessoais além do identificador das manifestações.

---

### Edge Cases

- **Mesmo protocolo escolhido duas vezes / duplicado na seleção**: o dropdown não permite escolher o mesmo item duas vezes; se chegar duplicado por chamada direta, é tratado como um só.
- **Manifestação sem nenhum anexo**: entra no PDF normalmente (separador + dossiê com os dados).
- **Manifestação em qualquer status (rascunho, em análise, encaminhamento, respondida, encerrada)**: pode ser incluída; a única barreira é a regra de acesso (047).
- **Manifestação alterada durante a geração do lote**: o dossiê reflete o estado no momento em que aquela manifestação é lida; a alteração posterior invalida o reuso, mas não corrompe o lote em andamento.
- **Anexo excluído (053) durante a geração**: o conteúdo excluído não deve aparecer; se a exclusão ocorrer depois de lido, vale o estado lido (sem falha).
- **Nomes de arquivo repetidos ou com caracteres inválidos (originais fora do PDF)**: o ZIP nunca sobrescreve um arquivo por outro nem gera caminhos inseguros; nomes são normalizados preservando o nome original sempre que possível.
- **Dois downloads em massa simultâneos do mesmo usuário (duas abas)**: o segundo é recusado com mensagem clara, para proteger o servidor (há um limite de downloads em massa simultâneos por usuário).
- **Muitos usuários baixando ao mesmo tempo**: acima de um número de downloads em massa simultâneos no servidor, novos pedidos são recusados com mensagem para tentar novamente em instantes, em vez de degradar o sistema.
- **Armazenamento de anexos indisponível durante o lote**: anexos afetados são listados como indisponíveis (US5); se o armazenamento inteiro cair, o download falha com mensagem clara.
- **Usuário fecha o modal durante o download**: fechar o modal ou navegar para outra tela **não** cancela; o progresso permanece visível de forma discreta (indicador global com Cancelar) até concluir ou ser cancelado. Fechar a **aba** cancela (ver US2).
- **Montagem demorada**: o arquivo só começa a chegar depois da montagem completa; o indicador deixa isso explícito. Um proxy reverso com timeout curto pode interromper o pedido — a falha é reportada como falha na geração, e o usuário pode tentar de novo (reaproveitando o cache).
- **Relógio / expiração do reuso durante o lote**: o dossiê reutilizado no início do lote vale até o fim dele, mesmo se passar de 24 horas no meio do processo.
- **Sessão expira no meio do download**: o download já iniciado termina; novos pedidos exigem login.

## Requirements *(mandatory)*

### Functional Requirements

**Entrada e seleção**

- **FR-001**: A lista de manifestações da Ouvidoria MUST oferecer um botão "Baixar em massa" que abre um modal de seleção; a lista NÃO ganha checkboxes por linha.
- **FR-002**: O modal MUST oferecer um campo de seleção múltipla com busca digitável que encontre manifestações por **número personalizado** ou **protocolo** (ex.: `2026-3-09-0003`), exibindo o que existir para cada manifestação (inclusive as sem número personalizado).
- **FR-003**: Os itens escolhidos MUST aparecer como chips removíveis, com contador "N de 50", e o botão de confirmar MUST ficar desabilitado sem itens escolhidos ou acima do limite.
- **FR-004**: O botão "Baixar em massa" MUST estar disponível a qualquer usuário com acesso ao módulo Ouvidoria; o resultado do pedido continua sujeito à regra de acesso de cada manifestação (FR-010).
- **FR-005**: A busca do dropdown MUST respeitar o isolamento por tenant, nunca listando manifestações de outra instituição, e MUST ser eficiente o bastante para responder enquanto o usuário digita (sem carregar todas as manifestações de uma vez).

**Conteúdo da entrega**

- **FR-006**: O resultado MUST ser **um único PDF** contendo, para cada manifestação escolhida (na ordem da seleção), uma **página inteira de separação** seguida do **dossiê completo**: dados da manifestação, tramitação/respostas conforme o PDF atual, timbrado do tenant e anexos JPG/PNG/PDF **embutidos**.
- **FR-007**: Anexos que não podem ser embutidos em PDF (Word, Excel, TXT, MP3, MP4 etc.) MUST ficar **fora do PDF**. Quando houver ao menos um, a entrega MUST ser um **ZIP** contendo o PDF único e os originais em `<manifestação>/anexos/`; quando não houver nenhum, a entrega MUST ser **somente o PDF**. O servidor MUST definir o nome e a extensão (`.pdf` ou `.zip`) do arquivo entregue.
- **FR-008**: Anexos do tipo link externo MUST aparecer listados como referência no dossiê da manifestação, sem arquivo correspondente na entrega.
- **FR-009**: A página de separação de cada manifestação MUST exibir o protocolo/número personalizado e as listas de anexos **embutidos**, **fora do PDF** e **indisponíveis**. O PDF MUST terminar com uma **página-resumo do lote** contendo: data/hora e autor do download, manifestações incluídas, anexos fora do PDF e indisponíveis (manifestação, nome do arquivo, motivo) e, por manifestação, se o dossiê foi gerado agora ou reaproveitado. Nenhuma omissão de anexo pode ser silenciosa. NÃO MUST existir `indice-do-lote.pdf` nem `lote.txt` separados.
- **FR-009a**: PDF ou imagem anexado que não puder ser embutido (bytes lidos, mas inválidos) MUST ir para fora do PDF (ZIP) e ser listado com motivo `pdf-invalido`; arquivo que o armazenamento não devolve MUST ser listado como indisponível com motivo `armazenamento`.

**Segurança e limites**

- **FR-010**: Antes de gerar qualquer conteúdo, o sistema MUST validar, para **todas** as manifestações escolhidas, a existência, o tenant e a regra de acesso da spec 047; se qualquer uma falhar, MUST **recusar o lote inteiro** (nada é gerado) e informar quais manifestações impedem o download, sem revelar dados da manifestação proibida além do identificador que o próprio usuário informou.
- **FR-011**: A validação de acesso MUST ocorrer no servidor, em toda chamada, incluindo chamadas diretas ao serviço e incluindo manifestações cujo dossiê já esteja guardado para reuso.
- **FR-012**: O sistema MUST limitar cada download em massa a **50 manifestações** e a **~300 MB** (300 MiB) de soma de anexos de arquivo, recusando o lote **antes** de qualquer geração, com mensagem clara indicando o limite excedido. O teto de volume existe porque a junção do PDF único é feita em memória no servidor. Não há fracionamento automático em múltiplas partes.
- **FR-013**: Não há limite de volume **por manifestação** em massa (o limite de 200MB do PDF individual continua apenas no PDF individual); vale somente o teto do lote.
- **FR-014**: O sistema MUST limitar o número de downloads em massa simultâneos por usuário e no servidor, recusando excedentes com mensagem para tentar mais tarde.
- **FR-015**: Nomes de arquivos e pastas dentro do ZIP (originais fora do PDF) MUST ser normalizados de forma segura (sem caminhos fora do pacote, sem sobrescrita entre arquivos de mesmo nome, sem caracteres inválidos).

**Montagem, entrega e divisão de carga**

- **FR-016**: O sistema MUST montar o lote no servidor **por manifestação**, gravando cada dossiê e cada original em **arquivos temporários** (diretório próprio do download), juntando o PDF único ao final e entregando a partir desses arquivos. O arquivo final **só começa a chegar ao navegador depois da montagem completa**. Os temporários MUST ser removidos ao fim (sucesso, falha ou cancelamento).
- **FR-017**: O consumo de memória do servidor por download MUST ser limitado pelo teto do lote (FR-012), com os dossiês individuais em disco; o navegador MUST receber o arquivo por download nativo (sem manter o lote em memória no cliente).
- **FR-018**: A carga MUST ser dividida de forma que o servidor não bloqueie outros usuários (processamento contido por download, sem monopolizar o servidor) e o navegador não congele a interface durante o download (a UI permanece responsiva).
- **FR-019**: O cliente MUST disparar **sempre o download nativo do navegador** (sem seletor de local de salvamento) e MUST acompanhar o andamento por consulta de progresso, mostrando "N de total manifestações" e o botão **Cancelar**. Se o usuário fechar o modal ou navegar para outra tela do sistema, o download MUST continuar e o indicador discreto com **Cancelar** MUST permanecer visível em qualquer tela até o fim ou cancelamento.
- **FR-019a**: O indicador MUST avisar que o arquivo é montado no servidor e que o download do navegador começa quando estiver pronto. O cliente MUST NOT oferecer link "Baixar arquivo ZIP" nem texto fixo "ZIP" na descrição do modal que sugira formato único.
- **FR-020**: Ao cancelar, fechar a aba ou perder a conexão, o servidor MUST interromper o trabalho daquele download, liberar os recursos e remover os temporários; o arquivo parcial MUST ser descartado pelo cliente.
- **FR-021**: Se uma falha irrecuperável ocorrer durante a geração, o download MUST terminar como **falha explícita** — nunca como se fosse um arquivo completo — e o usuário MUST poder tentar novamente.

**Reuso (cache)**

- **FR-022**: O **dossiê individual** (PDF) de cada manifestação MUST ser guardado e reaproveitado por **até 24 horas** em novos downloads, enquanto nada tiver mudado, junto com o registro das pendências de embutimento (anexos indisponíveis e `pdf-invalido`). Dossiê guardado sem esse registro MUST ser tratado como não reaproveitável.
- **FR-023**: O dossiê guardado MUST ser invalidado em **qualquer** alteração da manifestação (dados, status, tramitação, resposta, encerramento, concessão de acesso quando refletida no PDF), de seus anexos (inclusão e **exclusão** — spec 053) e do timbrado aplicado (mudança no arquivo do carimbo, não só no código); o usuário nunca MUST receber conteúdo desatualizado.
- **FR-024**: Os dossiês guardados MUST ser isolados por tenant. Objeto com mais de 24 horas MUST deixar de ser servido e MUST ser apagado nesse acesso. Quando uma revisão nova é gravada, as revisões anteriores da mesma manifestação MUST ser apagadas **antes** de gravar a nova. Falha ao apagar não serve conteúdo velho nem impede o download. Uma regra de ciclo de vida de 48 horas no armazenamento é só rede de segurança.
- **FR-025**: O reuso MUST NOT contornar autorização (FR-011) nem exibir conteúdo a quem não teria acesso à manifestação.
- **FR-026**: Reutilizar dossiês MUST ser transparente ao usuário (sem opção na tela); o conteúdo MUST ser idêntico ao de uma geração nova feita no instante em que o dossiê guardado foi criado. O carimbo "Documento gerado em" do dossiê reaproveitado MUST mostrar o momento real dessa geração (até 24h antes do download), nunca a hora do download.
- **FR-026a**: A página-resumo final MUST registrar a data/hora do download, o autor do download e, por manifestação, se o dossiê foi gerado agora ou reaproveitado (com o momento da geração original).

**Auditoria**

- **FR-027**: Cada pedido de download em massa MUST ser registrado em auditoria com: autor (com papel quando `admin_tenant`/`admin_saas`, conforme a regra de FK de `AdminTenant`), data/hora, manifestações solicitadas, resultado (concluído, recusado — com motivo, cancelado, falho) e volume entregue; sem conteúdo dos documentos.

**Interface e mensagens**

- **FR-028**: Mensagens de erro MUST ser claras e em português, distinguindo: sem acesso, não encontrada, acima do limite de quantidade, acima do limite de volume (~300 MB), muitos downloads simultâneos, armazenamento indisponível e falha na geração.
- **FR-029**: O modal MUST ser acessível (foco, teclado, leitores de tela) e responsivo, seguindo a norma de UI do dossiê (040) e a paleta do produto.

### Key Entities

- **Lote de download em massa**: pedido do usuário contendo as manifestações escolhidas, com resultado (concluído, recusado, cancelado, falho), volume total, autor e data/hora.
- **Manifestação (seleção)**: registro da Ouvidoria identificado por protocolo e por número personalizado (este opcional), com seus anexos (arquivo, link externo, ativo/excluído).
- **Dossiê guardado da manifestação**: PDF individual pronto, com validade de 24 horas e relatório de pendências de embutimento, vinculado a uma manifestação e a um tenant, invalidado por qualquer alteração relevante.
- **PDF único do lote**: entrega padrão — separador + dossiê por manifestação e página-resumo no fim.
- **Pacote ZIP (condicional)**: entregue só quando há anexos fora do PDF; contém o PDF único e os originais em `<manifestação>/anexos/`.
- **Registro de auditoria do download em massa**: autor, data/hora, manifestações, resultado e volume.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Um usuário consegue baixar o PDF único de 10 manifestações em menos de 1 minuto de interação (abrir modal, escolher, confirmar), em contraste com 10 downloads individuais.
- **SC-002**: Em um lote com até 50 manifestações e ~300 MB, o indicador de progresso aparece em até 2 segundos após a confirmação e avança manifestação a manifestação; o arquivo é entregue assim que a montagem termina.
- **SC-003**: O consumo de memória do servidor por download em massa é limitado pelo teto de ~300 MB de anexos, e o disco temporário é liberado ao fim em 100% dos casos (sucesso, falha, cancelamento).
- **SC-004**: Um segundo download do mesmo lote (sem alterações) é pelo menos 3x mais rápido para concluir do que o primeiro.
- **SC-005**: 100% das tentativas com manifestação sem acesso, de outro tenant ou inexistente resultam em recusa do lote inteiro, sem nenhum byte do conteúdo entregue.
- **SC-006**: 100% dos lotes acima de 50 manifestações ou ~300 MB são recusados antes de iniciar a geração.
- **SC-007**: Em 100% dos casos, nenhum conteúdo desatualizado é entregue após alteração da manifestação, de seus anexos ou exclusão de anexo (053) — verificado por teste de invalidação.
- **SC-008**: Cancelar um download interrompe o processamento no servidor em até 5 segundos, sem trabalho órfão remanescente.
- **SC-009**: 100% dos anexos indisponíveis ou fora do PDF de um lote aparecem registrados na página de separação e na página-resumo — nenhuma omissão silenciosa.
- **SC-010**: Enquanto um lote de 50 manifestações é montado, a interface do sistema permanece responsiva (sem travamentos perceptíveis) e outros usuários não sentem degradação perceptível.
- **SC-011**: 100% dos downloads em massa (concluídos, recusados, cancelados, falhos) deixam registro de auditoria consultável.
- **SC-012**: Lote só com anexos embutíveis entrega **um único `.pdf`**; lote com ao menos um anexo fora do PDF entrega **um `.zip`** com o PDF único e os originais — em 100% dos casos.

## Assumptions

- **Escopo**: "Manifestações" refere-se exclusivamente às manifestações do módulo Ouvidoria; demandas de outros módulos (Gabinete, Jurídico, Compras, Tramitação) estão fora de escopo.
- **Formato**: o dossiê de cada manifestação é o mesmo gerado hoje pelo PDF de detalhe (dados, timbrado do tenant, anexos JPG/PNG/PDF embutidos). Esta spec não altera o conteúdo do PDF individual.
- **PDF único como padrão; ZIP só quando necessário**: sem DOCX em massa; sem `indice-do-lote.pdf`/`lote.txt`. Word/DOCX em massa fica fora de escopo.
- **Sem job em segundo plano**: o download exige a aba aberta durante a geração; não há notificação "pronto" nem arquivo guardado para baixar depois. Se isso se tornar necessário para lotes maiores, será outra spec.
- **Sem checkboxes na lista**: a seleção é exclusivamente pelo modal. Seleção por intervalo, por filtro (período/status) ou por colar lista de números está fora de escopo.
- **Acesso**: qualquer usuário do módulo Ouvidoria vê o botão; cada manifestação segue a regra 047 (chefe da Ouvidoria e admins veem todas; operador comum vê as suas e as concedidas). Manifestações de todos os status podem ser baixadas por quem tem acesso.
- **Limite de 50 / ~300 MB** vale por download; o usuário que precisar de mais faz vários downloads. A soma considera os anexos de arquivo (não links externos) das manifestações escolhidas. O autor exibido na página-resumo é o identificador do usuário.
- **Reuso (cache)**: duração máxima de 24 horas; o conteúdo guardado fica no mesmo nível de proteção dos anexos (isolado por tenant). Ao passar de 24 horas ou ao mudar o conteúdo, o dossiê deixa de ser servido e é apagado (FR-024).
- **Concorrência**: limite de 1 download em massa simultâneo por usuário e um teto global no servidor — os valores exatos são definidos no plano, com o comportamento (recusar com mensagem) fixado aqui.
- **Proxy/timeout**: como o arquivo só chega após a montagem completa, infraestrutura com timeout curto de requisição pode cortar lotes grandes; o plano documenta o tempo esperado e a configuração recomendada.
- **Dependências**: PDF individual existente (e seu timbrado), regra de acesso 047, armazenamento de anexos, exclusão de anexos 053 (invalidação do reuso) e auditoria existente da Ouvidoria.
- **Fora de escopo**: seleção em lote de outras entidades, envio por e-mail, agendamento, histórico de downloads na interface (a auditoria é só para consulta administrativa) e retomada de download interrompido (o processo recomeça do zero).
