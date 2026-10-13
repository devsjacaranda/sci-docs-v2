# Feature Specification: Registros em Planilha (Ouvidoria)

**Feature Branch**: `055-registros-controle-demandas`

**Created**: 2026-10-09

**Status**: Draft

**Input**: User description: "na vdt entendi errado, era pra gerar essa planilha" (anexo `Controle de Demandas 2026.xlsx`). "vamos aproveitar e dar a opção pras duas coisas: ao clicar em gerar massa, clica em gerar manifestação (o que já fizemos) e gerar registros". "a nova coisa tem que aceitar filtro por mês ou ano, porque é bem mais leve."

**Relacionamento**: Convive com [054 download-massa-manifestacoes](../054-download-massa-manifestacoes/spec.md) no mesmo modal "Baixar em massa" — a saída "Gerar manifestações" (PDF/ZIP) não muda. Esta spec adiciona a saída "Gerar registros" (planilha). Usa o mesmo catálogo de concessões e motivos de [046 timbrado-ageman-2026](../046-timbrado-ageman-2026/spec.md) e da lista de manifestações.

## Clarifications

### Session 2026-10-09

- Q: O que é "gerar registros"? → A: Uma planilha `.xlsx` com o mesmo layout do controle manual que a equipe já mantém (`Controle de Demandas 2026.xlsx`): uma aba por concessão, cabeçalho fixo de 25 colunas, uma linha por manifestação.
- Q: Qual filtro? → A: **Mês** (ano + mês) ou **ano inteiro**. Sem seleção manifestação a manifestação — é o oposto do PDF, que é leve justamente por isso.
- Q: Colunas que não existem no sistema hoje (data de recebimento da resposta da concessionária, responsável pela entrega, quando, como, quem recebeu, satisfação com a resposta, satisfação com o atendimento, observação)? → A: Mantêm o mesmo cabeçalho da planilha de referência e ficam **em branco**, para a equipe preencher manualmente no Excel depois de baixar.
- Q: Quem pode gerar? → A: **Qualquer usuário com acesso ao módulo Ouvidoria** — a mesma regra de quem vê a lista de manifestações, sem o filtro adicional de dono/concessão que o PDF individual aplica em outras ações diretas.
- Q: Onde fica o botão? → A: No mesmo modal "Baixar em massa" da spec 054, com um seletor entre **"Gerar manifestações"** (o PDF/ZIP já existente) e **"Gerar registros"** (esta planilha).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Baixar a planilha de um mês ou de um ano (Priority: P1)

Como usuário da Ouvidoria, quero abrir o modal "Baixar em massa", escolher "Gerar registros", informar um mês ou um ano e baixar uma planilha `.xlsx` no mesmo formato do controle manual, para não precisar copiar dados linha a linha para a planilha que a equipe já usa.

**Why this priority**: É o pedido direto do cliente — ele já mantém esse controle manualmente; a plataforma deve produzi-lo automaticamente, sem exigir seleção manual de cada manifestação (que seria inviável para um volume mensal/anual).

**Independent Test**: No modal, escolher "Gerar registros", informar março/2026, confirmar e verificar que a planilha baixada tem uma aba por concessão com manifestações naquele mês, cabeçalho idêntico ao da planilha de referência e uma linha por manifestação.

**Acceptance Scenarios**:

1. **Given** o modal "Baixar em massa" aberto, **When** o usuário escolhe "Gerar registros", **Then** aparece a opção de filtrar por **mês** (ano + mês) ou por **ano**, com o mês atual pré-selecionado.
2. **Given** um mês com manifestações em duas concessões, **When** o usuário confirma, **Then** a planilha baixada tem uma aba para cada concessão com manifestações naquele mês, cada uma com cabeçalho de 25 colunas igual ao da planilha de referência e uma linha por manifestação daquela concessão.
3. **Given** um ano inteiro, **When** o usuário confirma, **Then** a planilha contém todas as manifestações daquele ano, agrupadas por concessão do mesmo jeito.
4. **Given** uma manifestação sem concessão identificável, **When** a planilha é gerada, **Then** ela aparece em uma aba "Sem concessão" ao final, em vez de desaparecer silenciosamente.
5. **Given** uma coluna sem fonte de dados no sistema (ex.: satisfação com o atendimento), **When** a planilha é gerada, **Then** a coluna existe com o mesmo cabeçalho da planilha de referência e a célula fica em branco.

---

### User Story 2 - Nada aparece quando o período não tem dados (Priority: P2)

Como usuário, quero uma mensagem clara quando o mês ou ano escolhido não tem nenhuma manifestação, para não receber um arquivo vazio ou confuso sem entender o motivo.

**Why this priority**: Evita confusão e chamados de suporte por "a planilha veio vazia".

**Independent Test**: Escolher um mês sem nenhuma manifestação e confirmar: o modal mostra mensagem informando que não há registros no período, sem gerar arquivo.

**Acceptance Scenarios**:

1. **Given** um período sem nenhuma manifestação, **When** o usuário confirma, **Then** nenhum arquivo é baixado e o modal mostra mensagem clara ("Não há manifestações em [período]").
2. **Given** um período com volume muito grande (acima do teto operacional), **When** o usuário confirma, **Then** o pedido é recusado com mensagem orientando a escolher um período menor (ex.: um mês em vez de um ano), sem gerar arquivo parcial.

---

### User Story 3 - Rastro de quem gerou a planilha (Priority: P3)

Como auditor, quero que cada planilha gerada fique registrada (quem, quando, qual período, quantas linhas), para investigar o uso de um relatório que reúne dados pessoais de muitas pessoas de uma vez.

**Why this priority**: A planilha concentra nome, telefone e endereço de centenas de pessoas por período; governança exige saber quem gerou.

**Independent Test**: Gerar uma planilha e verificar o registro de auditoria com autor, data/hora, período e total de linhas, sem dados pessoais no registro.

**Acceptance Scenarios**:

1. **Given** uma planilha gerada com sucesso, **When** o auditor consulta o registro, **Then** vê autor, data/hora, período (mês/ano) e total de linhas por aba.
2. **Given** um pedido recusado (período vazio ou acima do teto), **When** consulta o registro, **Then** o resultado e o motivo da recusa constam.
3. **Given** o registro de auditoria, **When** ele é exibido, **Then** não contém nome, telefone, endereço nem qualquer dado pessoal das manifestações — só identificadores agregados.

---

### Edge Cases

- **Concessão sem nenhuma manifestação no período**: a aba simplesmente não existe nessa planilha (a planilha de referência também só tem abas com dado).
- **Manifestação anônima**: a coluna "Nome do reclamante" mostra "ANÔNIMO"; "Nome do titular" fica em branco se não houver.
- **Motivo fora do catálogo canônico (texto livre antigo)**: aparece como o texto salvo, em maiúsculas, sem quebrar a geração.
- **Dois pedidos simultâneos do mesmo usuário**: cada pedido é uma única requisição sem estado; não há limite de "um por vez" como no PDF (FR-010), mas vale o limite de pedidos por minuto (FR-009).
- **Usuário sem acesso ao módulo Ouvidoria**: não vê o botão "Baixar em massa" nem a opção "Gerar registros" (mesma regra de hoje).

## Requirements *(mandatory)*

### Functional Requirements

**Entrada e seleção**

- **FR-001**: O modal "Baixar em massa" MUST oferecer um seletor entre **"Gerar manifestações"** (fluxo PDF/ZIP da spec 054, inalterado) e **"Gerar registros"** (esta spec).
- **FR-002**: Ao escolher "Gerar registros", o modal MUST oferecer filtro por **mês** (ano + mês) ou por **ano**, sem seleção manifestação a manifestação.
- **FR-003**: "Gerar registros" MUST estar disponível para qualquer usuário com acesso ao módulo Ouvidoria.

**Conteúdo da planilha**

- **FR-004**: A planilha gerada MUST ter uma aba por concessão que tiver ao menos uma manifestação no período, usando os mesmos nomes de aba da planilha de referência (`1 - Água e Esgoto`, `3 - Iluminação Pública`, `4 - Coleta de Lixo`, `5 - Estacionamento Rotativo`), mais `2 - Transporte Coletivo`, `6 - Assuntos Institucionais` e `Sem concessão` quando houver dados nesses grupos.
- **FR-005**: Cada aba MUST ter o mesmo cabeçalho de 25 colunas da planilha de referência, na mesma ordem: `#`, `ANO`, `PROTOCOLO`, `DATA DA EMISSÃO`, `FORMA DE ATENDIMENTO`, `MOTIVO DA RECLAMAÇÃO`, `NOME DO RECLAMANTE`, `NOME DO TITULAR`, `MATRÍCULA/NÚMERO DO CLIENTE`, `CONTATO`, `RUA`, `NÚMERO DO IMÓVEL`, `BAIRRO`, `ZONA`, `TINHA PROTOCOLO NA CONCESSIONÁRIA?`, `ATENDENTE`, `PENDENTE OU RESOLVIDA?`, `DATA DE RECEBIMENTO DA RESPOSTA DA CONCESSIONÁRIA`, `RESPONSÁVEL PELA ENTREGA DA RESPOSTA`, `QUANDO?`, `COMO?`, `QUEM RECEBEU A RESPOSTA?`, `SATISFAÇÃO COM RESPOSTA?`, `SATISFAÇÃO COM ATENDIMENTO?`, `OBSERVAÇÃO`.
- **FR-006**: A coluna `#` MUST ser uma fórmula de numeração sequencial (equivalente a `=ROW(A1)` na primeira linha de dados), não um número fixo.
- **FR-007**: As colunas `DATA DE RECEBIMENTO DA RESPOSTA DA CONCESSIONÁRIA`, `RESPONSÁVEL PELA ENTREGA`, `QUANDO?`, `COMO?`, `QUEM RECEBEU A RESPOSTA?`, `SATISFAÇÃO COM RESPOSTA?`, `SATISFAÇÃO COM ATENDIMENTO?` e `OBSERVAÇÃO` MUST existir com o cabeçalho da planilha de referência e MUST ficar em branco, por não terem fonte de dado estruturado no sistema hoje.
- **FR-008**: Cada linha MUST trazer, quando disponível na manifestação: ano e protocolo institucional, data de emissão, forma de atendimento, motivo da reclamação (rótulo canônico em maiúsculas), nome do reclamante (ou "ANÔNIMO"), nome do titular, matrícula/número do cliente, contato, endereço (rua, número, bairro, zona), se já havia protocolo na concessionária, atendente (emissor) e a situação (RESOLVIDA, MEIO JURÍDICO ou PENDENTE).

**Limites e proteção do servidor**

- **FR-009**: O sistema MUST limitar o número de planilhas geradas por usuário por minuto, recusando excedentes com mensagem para tentar mais tarde.
- **FR-010**: O sistema MUST limitar o total de linhas por planilha a um teto operacional; períodos que excedem esse teto MUST ser recusados antes de gerar qualquer conteúdo, com mensagem orientando a escolher um período menor.
- **FR-011**: Um período sem nenhuma manifestação MUST ser recusado com mensagem clara, sem gerar arquivo vazio.
- **FR-012**: A geração MUST ler os dados em lotes (sem carregar o período inteiro em uma única consulta nem segurar todas as linhas de uma vez na montagem), para não travar o servidor em períodos grandes.

**Auditoria**

- **FR-013**: Cada pedido de planilha de registros (concluído ou recusado) MUST ser registrado em auditoria com autor (com papel quando `admin_tenant`/`admin_saas`), data/hora, período solicitado, resultado e total de linhas; sem nomes, telefones, endereços ou qualquer dado pessoal das manifestações no registro.

**Interface**

- **FR-014**: Mensagens de erro MUST ser claras e em português, distinguindo: período sem dados, período acima do limite de linhas e muitos pedidos em pouco tempo.
- **FR-015**: O seletor "Gerar manifestações" / "Gerar registros" e o painel de filtro MUST ser acessíveis (foco, teclado, leitores de tela) e seguir a paleta do produto.

### Key Entities

- **Planilha de registros**: arquivo `.xlsx` gerado para um período (mês ou ano), com uma aba por concessão e uma linha por manifestação daquele período.
- **Linha de registro**: a projeção de uma manifestação para o formato de 25 colunas da planilha de referência.
- **Registro de auditoria da planilha**: autor, data/hora, período, resultado e total de linhas — sem dado pessoal.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Um usuário consegue baixar a planilha de um mês inteiro em menos de 30 segundos de interação (abrir modal, escolher "Gerar registros", informar o mês, confirmar).
- **SC-002**: 100% das planilhas geradas têm cabeçalho idêntico (nomes e ordem das 25 colunas) ao da planilha de referência em cada aba.
- **SC-003**: 100% dos períodos sem nenhuma manifestação são recusados com mensagem clara, sem gerar arquivo.
- **SC-004**: 100% dos períodos acima do teto operacional de linhas são recusados antes de qualquer geração.
- **SC-005**: 100% das planilhas geradas (sucesso ou recusa) deixam registro de auditoria consultável, sem dado pessoal.
- **SC-006**: Gerar a planilha de um período grande (um ano) não aumenta perceptivelmente o tempo de resposta de outras telas da Ouvidoria durante a geração (leitura em lotes, sem bloquear o processo).

## Assumptions

- **Formato de referência**: `Controle de Demandas 2026.xlsx`, lido como amostra somente leitura para fixar cabeçalho, nomes de aba, estilos (Calibri 11, cabeçalho em negrito e centralizado, bordas finas) e a fórmula de numeração.
- **Mapeamento de "TINHA PROTOCOLO NA CONCESSIONÁRIA?"**: usa o campo já existente de contato prévio com a concessionária (`ManifestacaoConcessionaria.jaEntrouContato`), que é a aproximação mais próxima disponível hoje — não é um campo capturado com essa pergunta literal.
- **"PENDENTE OU RESOLVIDA?"**: usa a mesma classificação de situação do relatório de gestão (resolvida pela AGEMAN, meio jurídico, pendente); "meio jurídico" é um valor adicional à planilha de referência original, mantido explícito em vez de forçado em "pendente" ou "resolvida".
- **Sem seleção manual**: diferente do PDF da spec 054, aqui não há escolha manifestação a manifestação — só período. Isso é o que torna esta via leve o bastante para cobrir um mês ou um ano inteiro.
- **Sem limite de simultaneidade** por usuário/servidor como no PDF: a geração não monta um documento pesado em memória por manifestação; o teto é por linhas (FR-010) e por frequência de pedidos (FR-009).
- **Dependências**: catálogo de concessões/motivos (`ageman-catalog.ts`), regra de acesso ao módulo Ouvidoria, auditoria existente.
- **Fora de escopo**: preencher as colunas sem fonte no sistema; editar a planilha depois de gerada; enviar por e-mail; agendamento; qualquer alteração no fluxo "Gerar manifestações" (PDF/ZIP) da spec 054.
