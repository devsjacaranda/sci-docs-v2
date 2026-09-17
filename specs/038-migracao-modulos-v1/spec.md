# Feature Specification: Migração de Módulos Inteiros v1 → v2 (Tenant AGEMAN)

**Feature Branch**: `038-migracao-modulos-v1`

**Created**: 2026-08-21

**Status**: Draft

**Input**: User description: "migrar modulos inteiros do v1 para v2 de forma organizada, refatorada e melhorada e sem debitos tecnicos. Modulos: ouvidoria, diagnostico, Gabinete, Protocolo, Diretorias, Documentos Tramitados, Notificações e Autos, Controle Numérico. Vamos usar e abusar de e2e com playwright e acesso direto ao banco via script para comparar se formato e dados estao corretos na migração. A migração não vai abranger fiscalização, insights com IA e maturidade."

## Contexto

O sistema legado (v1) está em produção em `https://ageman.controleinterno.org`, servido por `controle-interno-client` (React 19 + Vite 6) sobre `controle-interno-api` (Express 4 + Prisma + **MySQL**). O sistema novo (v2) é `ci-client-v2` (Turborepo, React 19, Vite 8, Tailwind v4, shadcn/ui) sobre `ci-api-v2` (NestJS 11 + Fastify + Prisma + **PostgreSQL**).

Parte dos módulos já existe parcialmente no v2 (Ouvidoria operacional, Gabinete com atos e cadastros) e parte não existe (Diagnóstico, portal público da Ouvidoria). Esta feature trata a migração como **encerramento de módulo**: ao final de cada módulo migrado, o v1 correspondente deixa de ser necessário para a AGEMAN.

Esta spec **absorve** o escopo de migração de dados anteriormente rascunhado em `036-migracao-agema-v1` — decisão confirmada com o usuário. A `036` passa a ser considerada substituída por esta.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Equipe de migração comprova, com evidência automatizada, que o v2 reproduz o v1 (Priority: P1)

A equipe responsável pela migração precisa, antes de liberar qualquer módulo para os servidores da AGEMAN, carregar os dados reais de produção do v1 no v2 e comprovar automaticamente — sem inspeção manual tela por tela — que cada registro migrado tem a mesma quantidade, o mesmo conteúdo e o mesmo formato de apresentação nos dois sistemas. Quando existe divergência, ela precisa aparecer num relatório que aponte o registro e o campo divergentes, não apenas um "falhou".

**Why this priority**: É a fundação de confiança de todo o resto. Sem dados reais no v2 e sem um mecanismo de comparação automatizada, nenhum módulo migrado pode ser declarado equivalente ao v1, e qualquer paridade alegada seria opinião. Todas as demais histórias usam esta base para se validar.

**Independent Test**: Pode ser testado de forma completa executando a carga de dados da AGEMAN no v2 e, em seguida, a rotina de comparação; ela deve produzir um relatório de correspondência por tipo de dado (contagem de origem, contagem de destino, divergências campo a campo) e falhar de forma explícita se algum registro real não tiver correspondente.

**Acceptance Scenarios**:

1. **Given** a base de produção do v1 restaurada a partir do dump mais recente, **When** a carga de dados da AGEMAN para o v2 é executada, **Then** para cada tipo de dado migrado é produzida uma contagem de origem e de destino, e as duas coincidem descontados os registros de teste/QA excluídos.
2. **Given** a carga concluída, **When** a rotina de comparação campo a campo é executada sobre uma amostra e sobre a totalidade dos registros, **Then** divergências de conteúdo (texto, data, valor, situação) são listadas identificando registro e campo, e a rotina termina em falha se houver divergência não justificada.
3. **Given** os dois sistemas em execução simultânea, **When** a verificação ponta a ponta navega a mesma tela nos dois (ex.: lista de manifestações filtrada por status), **Then** o conjunto de registros exibido e os valores de cada coluna equivalente conferem entre v1 e v2.
4. **Given** uma divergência introduzida de propósito no v2 (registro alterado ou ausente), **When** a rotina de comparação roda, **Then** ela detecta e reporta a divergência — comprovando que a verificação não passa em falso.
5. **Given** a rotina de comparação, **When** ela é executada novamente sem nenhuma alteração, **Then** produz o mesmo resultado (é repetível e não depende de estado acumulado de execuções anteriores).

---

### User Story 2 - Atendente da Ouvidoria opera o dia a dia inteiro no v2 (Priority: P2)

Um atendente da Ouvidoria da AGEMAN precisa abandonar o v1 e executar no v2 todo o seu trabalho: acompanhar o painel gerencial com os indicadores do período, localizar manifestações por status, prioridade, tipo, motivo e período, registrar e editar manifestações, responder o cidadão, encaminhar para setor, encerrar com carta resposta anexada, consultar respostas e arquivados, acompanhar os atendimentos e as formas de atendimento, e auditar o que foi feito em cada manifestação.

**Why this priority**: Ouvidoria é a maior superfície funcional dos módulos listados e tem obrigação legal de prazo e transparência no atendimento ao cidadão. É o módulo com mais uso diário e o que gera maior risco se ficar dividido entre dois sistemas.

**Independent Test**: Pode ser testado integralmente por um atendente que execute o ciclo completo de uma manifestação no v2 (registrar → responder → encaminhar → encerrar com carta) e confira o painel gerencial, comparando os indicadores e as listas com os mesmos filtros aplicados no v1.

**Acceptance Scenarios**:

1. **Given** o painel gerencial da Ouvidoria no v2 com um ano e mês selecionados, **When** o atendente compara com o v1 no mesmo período, **Then** os indicadores (total, pendentes, em análise, respondidas, arquivadas, arquivadas com resolução) e cada gráfico do período apresentam os mesmos números.
2. **Given** a lista de manifestações, **When** o atendente filtra por status, prioridade, tipo, motivo e período, **Then** o resultado é o mesmo obtido com os filtros equivalentes no v1, e a filtragem é aplicada sobre a totalidade dos registros — não apenas sobre a página carregada.
3. **Given** uma manifestação pendente, **When** o atendente registra a resposta ao cidadão, **Then** a manifestação passa a constar como respondida, a resposta fica registrada com autor e data, e o cidadão recebe o retorno pelo canal informado quando ele desejou resposta.
4. **Given** uma manifestação em análise, **When** o atendente a encaminha para um setor, **Then** o encaminhamento é registrado na linha do tempo com setor de destino, autor e data, e o setor de destino passa a vê-la.
5. **Given** uma manifestação a ser encerrada, **When** o atendente encerra anexando a carta resposta, **Then** o anexo fica vinculado à manifestação, disponível para download, e a manifestação passa a constar como encerrada.
6. **Given** qualquer manifestação, **When** o atendente solicita o documento da manifestação para uso externo, **Then** o arquivo é gerado com o mesmo conteúdo que o v1 gerava para o mesmo registro.
7. **Given** uma manifestação da AGEMAN com informação de concessionária e prazo de atendimento, **When** ela é listada e aberta no v2, **Then** esses campos aparecem preenchidos como no v1.
8. **Given** o histórico de auditoria de uma manifestação, **When** o atendente o consulta no v2, **Then** os eventos aparecem na mesma ordem cronológica e com o mesmo autor registrado no v1.

---

### User Story 3 - Servidor do Gabinete tramita demandas entre setores no v2 (Priority: P3)

Um servidor do Gabinete precisa conduzir no v2 o fluxo diário de demandas: localizar demandas por setor atual, situação, origem e período; receber uma demanda que chegou ao seu setor; encaminhar e reencaminhar para outro setor com anexos e justificativa; devolver ao setor de origem quando for o caso; acompanhar o histórico de encaminhamentos de cada demanda e extrair esse histórico como documento.

**Why this priority**: O Gabinete concentra o fluxo de trabalho entre setores da AGEMAN. Depende da fundação de dados (US1) e é o segundo maior volume de uso, mas o encerramento do módulo só faz sentido depois da Ouvidoria porque parte das demandas nasce de manifestações.

**Independent Test**: Pode ser testado por um servidor que receba uma demanda no seu setor, a encaminhe para outro setor, acompanhe a mudança de situação e extraia o histórico de encaminhamentos — comparando cada passo com o comportamento do v1 para a mesma demanda.

**Acceptance Scenarios**:

1. **Given** a lista de demandas do Gabinete, **When** o servidor filtra por setor atual, situação, origem e período, **Then** o resultado corresponde ao do v1 com os mesmos filtros, incluindo a identificação de demandas originadas na Ouvidoria.
2. **Given** uma demanda aguardando recebimento no setor do servidor, **When** ele a recebe, **Then** a situação avança e o recebimento fica registrado com autor e data.
3. **Given** uma demanda recebida, **When** o servidor a encaminha para outro setor anexando documentos, **Then** o setor atual muda, o encaminhamento entra no histórico com destino, autor, data e anexos, e o setor de destino passa a vê-la aguardando recebimento.
4. **Given** uma demanda já encaminhada, **When** o servidor a reencaminha ou a devolve ao setor de origem, **Then** a operação é registrada no histórico sem apagar os encaminhamentos anteriores.
5. **Given** uma demanda com vários encaminhamentos, **When** o servidor extrai o histórico como documento, **Then** o documento traz a sequência completa de movimentações, equivalente ao que o v1 produzia.
6. **Given** uma demanda vinculada a uma manifestação de ouvidoria ou a um protocolo, **When** o servidor a abre no v2, **Then** o vínculo é navegável até o registro de origem.

---

### User Story 4 - Servidor mantém os cadastros e controles do Gabinete no v2 (Priority: P3)

Um servidor do Gabinete precisa manter no v2 os cinco cadastros que hoje faz no v1: os **Protocolos** recebidos (com número interno, número SIGED, remetente, forma de entrada e anexos); as **Diretorias** da AGEMAN; os **Documentos Tramitados** de cada setor; as **Notificações à concessionária e os Autos de Infração** com seus prazos, valores e respostas; e o **Controle Numérico** de ofícios, ofícios circulares, portarias, memorandos, memorandos circulares e resoluções.

**Why this priority**: São cinco cadastros de estrutura homogênea e alto volume de digitação, essenciais para o controle administrativo e para a instrução dos processos, mas sem fluxo de tramitação próprio — dependem dos protocolos e demandas já migrados.

**Independent Test**: Pode ser testado por um servidor que crie, edite, consulte e remova um registro em cada um dos cinco cadastros e confira que a listagem, os campos e as buscas correspondem ao v1 — inclusive a separação por setor nos documentos tramitados e por tipo de documento no controle numérico.

**Acceptance Scenarios**:

1. **Given** o cadastro de Protocolos, **When** o servidor registra um protocolo informando remetente, data, assunto, tipo de documento, forma de entrada e número SIGED, **Then** ele passa a constar na listagem com os mesmos campos e buscas disponíveis no v1, e aceita anexos que ficam disponíveis para download.
2. **Given** o cadastro de Diretorias, **When** o servidor cria, renomeia, inativa e remove uma diretoria, **Then** a alteração reflete na listagem e nas telas que oferecem diretoria como opção de destino ou de vínculo.
3. **Given** os Documentos Tramitados, **When** o servidor seleciona um setor e registra um documento, **Then** ele fica vinculado àquele setor e aparece apenas na listagem daquele setor, com os mesmos campos do v1.
4. **Given** as Notificações à concessionária, **When** o servidor registra uma notificação com termo, destinatário, prazo, vencimento, situação e resposta, **Then** todos os campos são preservados e a listagem permite localizá-la como no v1.
5. **Given** os Autos de Infração, **When** o servidor registra um auto com documento, destinatário, setor emissor, assunto, valor, prazo, vencimento e resposta, **Then** o valor monetário é preservado sem perda de precisão e a listagem corresponde à do v1.
6. **Given** o Controle Numérico, **When** o servidor alterna entre os seis tipos de documento, **Then** cada tipo apresenta os campos que lhe são próprios e a numeração registrada é preservada.
7. **Given** qualquer um dos cinco cadastros, **When** o servidor tenta salvar um registro com dado inválido (data impossível, valor não numérico, campo obrigatório vazio), **Then** o sistema recusa com mensagem clara indicando o campo — sem gravar registro inconsistente.
8. **Given** qualquer um dos cinco cadastros, **When** o servidor busca ou filtra, **Then** a busca considera a totalidade dos registros do cadastro, e não apenas os já carregados na tela.

---

### User Story 5 - Analista da AGEMAN usa o Diagnóstico no v2 (Priority: P4)

Um analista da AGEMAN precisa consultar no v2 a base de processos judiciais do diagnóstico: pesquisar processos por número, autor, requerido, juízo, objeto e resultado da reclamação; filtrar por categoria; navegar a listagem paginada; acompanhar o painel de indicadores e gráficos da carteira; marcar processos para acompanhamento; exportar o relatório do painel em documento timbrado; e trabalhar a aba de processos administrativos, incluindo os documentos institucionais (reservar número, preencher, emitir em PDF, cancelar e consultar histórico de acesso).

**Why this priority**: É o módulo que não existe no v2 (construção do zero), depende de acesso a uma base externa de processos alimentada por automação jurídica e traz consigo a emissão de documentos institucionais numerados. Alto esforço e menor frequência de uso diário que Ouvidoria e Gabinete.

**Independent Test**: Pode ser testado por um analista que reproduza no v2 uma consulta feita no v1 (mesmo termo, mesmo campo de busca, mesma categoria) e confira listagem, indicadores e exportação; e que emita um documento institucional do início ao fim, verificando a numeração reservada e o PDF gerado.

**Acceptance Scenarios**:

1. **Given** a consulta de processos do Diagnóstico no v2, **When** o analista pesquisa por um termo escolhendo o campo de busca e a categoria, **Then** o conjunto de processos retornado e os valores de cada coluna coincidem com a mesma consulta feita no v1.
2. **Given** a listagem de processos, **When** o analista altera a quantidade de itens por página e navega entre páginas, **Then** a paginação percorre a base completa sem repetir nem omitir processos.
3. **Given** o painel de indicadores do Diagnóstico, **When** o analista o abre no v2, **Then** os indicadores da carteira (total, procedências, improcedências, sentenças, petições iniciais) e os gráficos correspondem aos do v1 para a mesma base.
4. **Given** um processo na listagem, **When** o analista o marca para acompanhamento, **Then** a marcação é gravada no servidor e permanece após sair e voltar, em qualquer navegador ou dispositivo em que ele se autentique.
5. **Given** o painel do Diagnóstico, **When** o analista exporta o relatório em documento timbrado, com e sem a inclusão dos gráficos, **Then** o documento é gerado com o conteúdo correspondente ao do v1.
6. **Given** a aba de processos administrativos, **When** o analista inicia um documento institucional de um tipo disponível, **Then** o sistema reserva um número, permite preencher os campos do modelo, emitir o PDF, enviar e cancelar — e registra quem acessou o documento.
7. **Given** um número reservado para um documento institucional que não foi concluído, **When** o prazo de reserva se esgota, **Then** o número é liberado ou marcado como abandonado sem gerar buraco não rastreável na numeração.
8. **Given** a base externa de processos indisponível, **When** o analista abre o Diagnóstico, **Then** o sistema informa a indisponibilidade de forma clara e não apresenta a carteira como vazia nem quebra as demais telas.

---

### User Story 6 - Cidadão registra manifestação no portal público servido pelo v2 (Priority: P5)

Um cidadão sem cadastro no sistema precisa registrar uma manifestação de ouvidoria pelo portal público da AGEMAN, anexar arquivos, escolher permanecer anônimo se quiser, receber o número de protocolo, e depois consultar o andamento pelo protocolo — com o portal passando a ser servido pela plataforma v2 e reaproveitando os componentes visuais do v2.

**Why this priority**: O portal público continua funcionando no v1 enquanto não é migrado, então é o item de menor risco em ficar por último; mas é pré-requisito para desligar definitivamente o v1, porque é a porta de entrada do cidadão.

**Independent Test**: Pode ser testado por um cidadão (ou verificação automatizada sem sessão autenticada) que registre uma manifestação pelo portal, receba o protocolo, e a encontre em seguida na tela interna da Ouvidoria no v2 e na consulta pública pelo protocolo.

**Acceptance Scenarios**:

1. **Given** o portal público servido pelo v2, **When** o cidadão preenche e envia uma manifestação com anexos, **Then** ele recebe um número de protocolo e a manifestação aparece na tela interna da Ouvidoria identificada como de origem pública.
2. **Given** um cidadão que optou pelo anonimato, **When** a manifestação é registrada e depois consultada internamente, **Then** nome e documento do requerente não são expostos em nenhuma tela nem em documento gerado.
3. **Given** um número de protocolo emitido pelo portal, **When** o cidadão o consulta publicamente, **Then** ele vê a situação atual da manifestação e a resposta, quando houver, sem precisar se autenticar.
4. **Given** um envio automatizado em massa contra o portal público, **When** as tentativas ocorrem, **Then** o portal as barra sem impedir o cidadão legítimo de registrar sua manifestação.
5. **Given** o portal público atendendo a AGEMAN, **When** ele é carregado, **Then** apresenta a identidade visual da AGEMAN, e a mesma base de código pode atender outra instituição por configuração, sem duplicação de aplicação.

---

### Edge Cases

- Uma manifestação, demanda ou protocolo real do v1 referencia um usuário que foi excluído da migração por ser conta de teste/QA — o registro real não pode ficar órfão nem deixar de ser migrado.
- Registros marcados como excluídos (soft delete) no v1 precisam continuar existindo no v2 como excluídos, para manter o histórico auditável, sem aparecer nas listagens normais.
- O v1 mantém, no mesmo banco, duas implementações concorrentes de Ouvidoria e duas de Demandas (legada e refatorada) — a migração precisa definir qual é a fonte de verdade por registro e não pode gerar duplicidade no v2.
- Os Documentos Tramitados existem no v1 em treze tabelas separadas (uma por setor) e o Controle Numérico em seis (uma por tipo); ao consolidar em uma estrutura única no v2, dois registros de setores/tipos diferentes que tinham o mesmo identificador não podem colidir.
- Um Documento Tramitado, Controle Numérico, Notificação ou Auto de Infração pode não estar vinculado a nenhum protocolo nem demanda — deve continuar existindo como registro solto.
- O valor monetário de um auto de infração não pode sofrer arredondamento na travessia entre os dois bancos.
- Datas e horas gravadas no v1 sem informação de fuso não podem deslizar de um dia ao serem migradas para o v2.
- Uma manifestação pública e uma interna podem ter o mesmo número de protocolo em bases diferentes do v1 — a unificação no v2 precisa evitar colisão de protocolo.
- Um número reservado para documento institucional pode ficar pendente indefinidamente se o usuário abandonar o preenchimento.
- A base externa de processos do Diagnóstico pode estar indisponível, lenta, ou ter registros com campos vazios/inconsistentes vindos da automação.
- O arquivo físico de um anexo pode não existir mais no armazenamento, embora o metadado exista no v1 — o v2 precisa deixar isso evidente em vez de oferecer um download que falha silenciosamente.
- A verificação automatizada de paridade compara dois sistemas vivos: se um deles tiver dado alterado durante a execução da comparação, o resultado pode acusar divergência falsa.
- Durante a migração, o mesmo módulo pode receber escrita nos dois sistemas (v1 ainda em uso e v2 já liberado), gerando divergência que nenhuma comparação consegue reconciliar.

## Requirements *(mandatory)*

### Functional Requirements

#### Migração de dados e verificação de fidelidade

- **FR-001**: O sistema DEVE carregar no v2 os dados reais do tenant AGEMAN existentes no v1, cobrindo os módulos desta migração e as entidades de que eles dependem (instituição, usuários, setores/diretorias, manifestações, demandas, protocolos, documentos tramitados, notificações, autos de infração, controles numéricos, documentos institucionais e marcações do diagnóstico).
- **FR-002**: O sistema DEVE preservar, para cada registro migrado, o identificador de negócio pelo qual o usuário o localiza no v1 (número de protocolo da manifestação, número do protocolo do gabinete, número do documento no controle numérico, número do processo no diagnóstico), de modo que uma busca por esse número no v2 encontre o mesmo registro.
- **FR-003**: O sistema DEVE excluir da migração os registros e usuários identificados como teste, QA ou preenchimento de exemplo, a partir de uma lista de exclusão revisada e aprovada antes da execução.
- **FR-004**: O sistema DEVE preservar a integridade dos registros reais mesmo quando um registro relacionado foi excluído por ser dado de teste — nenhum dado real pode ficar órfão, inacessível ou sem autor rastreável em consequência dessa exclusão.
- **FR-005**: O sistema DEVE preservar, no v2, a marcação de exclusão dos registros que estavam excluídos (soft delete) no v1, mantendo-os fora das listagens normais mas disponíveis para auditoria.
- **FR-006**: O sistema DEVE produzir, ao final da carga, um relatório de correspondência por tipo de dado contendo a quantidade de origem no v1, a quantidade de destino no v2, e a quantidade de registros deliberadamente excluídos — permitindo confirmar que nenhum registro real se perdeu.
- **FR-007**: O sistema DEVE oferecer uma verificação automatizada que compare o conteúdo dos registros entre v1 e v2 campo a campo, e que reporte cada divergência identificando o registro e o campo divergente.
- **FR-008**: A verificação de conteúdo DEVE tratar como equivalentes as diferenças de representação esperadas entre os dois sistemas (formato de data, precisão numérica, nomenclatura de situação/tipo), a partir de um mapa de equivalência explícito e revisável — e DEVE acusar como divergência qualquer diferença fora desse mapa.
- **FR-009**: O sistema DEVE oferecer uma verificação automatizada de interface que percorra, nos dois sistemas em execução, as telas equivalentes de cada módulo migrado e compare os registros listados e os valores exibidos em cada coluna correspondente.
- **FR-010**: As verificações automatizadas DEVEM ser repetíveis: executadas duas vezes sobre o mesmo estado, produzem o mesmo resultado, sem depender de execuções anteriores nem de dados criados manualmente.
- **FR-011**: As verificações automatizadas DEVEM ser comprovadamente capazes de reprovar: uma divergência introduzida de propósito precisa ser detectada e reportada.
- **FR-012**: O sistema DEVE tornar os anexos migrados acessíveis para download no v2 com o mesmo conteúdo do v1, reaproveitando os arquivos já existentes no armazenamento compartilhado entre os dois sistemas em vez de exigir novo envio pelo usuário.
- **FR-013**: O sistema DEVE informar de forma explícita, ao usuário e no relatório de migração, os anexos cujo arquivo físico não foi localizado no armazenamento — em vez de oferecer um download que falha em silêncio.

#### Ouvidoria

- **FR-014**: O sistema DEVE apresentar o painel gerencial da Ouvidoria com filtro por ano e mês, os indicadores do período (total, pendentes, em análise, respondidas, arquivadas e arquivadas com resolução) e os gráficos de resolutividade, atendimentos por mês, demandas finalizadas, demandas pendentes, distribuição por tipo, distribuição por forma de atendimento e distribuição por motivo — com os mesmos números que o v1 apresenta para o mesmo período.
- **FR-015**: Usuários DEVEM ser capazes de imprimir ou exportar o painel gerencial da Ouvidoria do período selecionado.
- **FR-016**: O sistema DEVE permitir localizar manifestações por texto livre, situação, prioridade, tipo, motivo e período, aplicando os filtros sobre a totalidade dos registros do tenant.
- **FR-017**: O sistema DEVE apresentar, na listagem de manifestações, o número de protocolo, o motivo, a situação, a prioridade e a data, além da identificação de origem pública quando aplicável, e — para a AGEMAN — a concessionária e o prazo de atendimento.
- **FR-018**: Usuários DEVEM ser capazes de registrar e editar manifestações informando tipo, categoria, motivo, prioridade, assunto, descrição, dados do requerente, endereço e anexos, respeitando a opção de anonimato.
- **FR-019**: Usuários DEVEM ser capazes de responder uma manifestação, registrando a resposta com autor e data, e de encaminhá-la a um setor, registrando destino, autor e data.
- **FR-020**: Usuários DEVEM ser capazes de encerrar uma manifestação anexando a carta resposta, que fica vinculada ao registro e disponível para download.
- **FR-021**: Usuários DEVEM ser capazes de arquivar e de consultar separadamente as manifestações respondidas e as arquivadas.
- **FR-022**: O sistema DEVE permitir gerar o documento da manifestação para uso externo, com conteúdo equivalente ao que o v1 gerava para o mesmo registro.
- **FR-023**: O sistema DEVE manter os catálogos de apoio da Ouvidoria (tipos de manifestação, categorias, formas de atendimento e serviços internos) administráveis pelo próprio usuário responsável.
- **FR-024**: O sistema DEVE registrar e exibir a linha do tempo de eventos de cada manifestação (registro, encaminhamento, resposta, encerramento, arquivamento e anotações) em ordem cronológica, com o autor de cada evento.
- **FR-025**: O sistema DEVE apresentar as manifestações de origem pública e as de origem interna numa única listagem unificada, sem exigir que o usuário consulte duas telas distintas.

#### Gabinete — demandas

- **FR-026**: O sistema DEVE permitir localizar demandas do Gabinete por texto livre, setor atual, situação, origem e período, aplicando os filtros sobre a totalidade dos registros do tenant.
- **FR-027**: O sistema DEVE apresentar, na listagem de demandas, o número de protocolo, o assunto, a origem, o setor atual, a situação e a data de entrada, sinalizando quando a demanda se originou de uma manifestação de ouvidoria.
- **FR-028**: Usuários DEVEM ser capazes de registrar, editar e remover demandas, informando origem, assunto, descrição, setor de destino, prazos da concessionária e anexos.
- **FR-029**: Usuários DEVEM ser capazes de receber uma demanda destinada ao seu setor, com o recebimento registrado com autor e data.
- **FR-030**: Usuários DEVEM ser capazes de encaminhar, reencaminhar e devolver uma demanda, com anexos e justificativa, sem que os encaminhamentos anteriores sejam apagados.
- **FR-031**: O sistema DEVE manter o histórico completo de encaminhamentos de cada demanda e permitir extraí-lo como documento.
- **FR-032**: O sistema DEVE manter navegável o vínculo entre uma demanda e o registro que a originou (manifestação de ouvidoria ou protocolo), quando existir.
- **FR-033**: O sistema DEVE atribuir automaticamente o número de protocolo de novas demandas, sem gerar duplicidade e sem colidir com os números migrados do v1.

#### Gabinete — Protocolo

- **FR-034**: Usuários DEVEM ser capazes de registrar, consultar, editar e remover protocolos do Gabinete informando número interno, número SIGED, remetente, data e hora de recebimento, forma de entrada, assunto, tipo de documento e descrição resumida.
- **FR-035**: O sistema DEVE permitir localizar protocolos por número, remetente, assunto e intervalo de datas, aplicando os filtros sobre a totalidade dos registros.
- **FR-036**: Usuários DEVEM ser capazes de anexar documentos a um protocolo e baixá-los posteriormente.
- **FR-037**: O sistema DEVE preservar o número SIGED e a informação de que a entrada se deu via SIGED, quando registrados.

#### Gabinete — Diretorias

- **FR-038**: Usuários DEVEM ser capazes de registrar, editar, ativar/inativar e remover as diretorias da AGEMAN, com sigla, nome e nome completo.
- **FR-039**: O sistema DEVE oferecer as diretorias ativas como opção nas telas que dependem delas (destino de encaminhamento, vínculo de documento tramitado e filtros por setor).

#### Gabinete — Documentos Tramitados

- **FR-040**: Usuários DEVEM ser capazes de registrar, consultar, editar e remover documentos tramitados vinculados a um setor específico, com os campos de controle usados no v1 (quantidade, data de protocolo, número de protocolo, tipo, número SIGED, data de despacho, documento, requerente, assunto, prazo e observações).
- **FR-041**: O sistema DEVE apresentar os documentos tramitados de um setor apenas na listagem daquele setor, mantendo a separação por setor que o v1 oferecia.
- **FR-042**: O sistema DEVE manter os documentos tramitados numa estrutura de dados única com o setor como atributo, em vez de replicar a divisão do v1 em uma estrutura por setor, sem que isso cause colisão entre registros de setores diferentes.
- **FR-043**: O sistema DEVE permitir vincular um documento tramitado a um protocolo ou a uma demanda, e também mantê-lo sem vínculo.

#### Gabinete — Notificações e Autos

- **FR-044**: Usuários DEVEM ser capazes de registrar, consultar, editar e remover notificações à concessionária com termo de notificação, destinatário, emissor, laudo técnico, fato gerador, processo de referência, data de protocolo na concessionária, prazo, vencimento, resposta e situação.
- **FR-045**: Usuários DEVEM ser capazes de registrar, consultar, editar e remover autos de infração com documento, destinatário, setor emissor, parecer/despacho, assunto, valor, processo de referência, número de protocolo, prazo, vencimento e resposta.
- **FR-046**: O sistema DEVE preservar o valor monetário do auto de infração sem perda de precisão em qualquer ponto (gravação, listagem, edição e exportação).
- **FR-047**: O sistema DEVE permitir localizar notificações e autos por texto livre e apresentar seus vencimentos e situações, aplicando a busca sobre a totalidade dos registros.

#### Gabinete — Controle Numérico

- **FR-048**: Usuários DEVEM ser capazes de registrar, consultar, editar e remover documentos de controle numérico nos seis tipos usados pela AGEMAN (ofício, ofício circular, portaria, memorando, memorando circular e resolução).
- **FR-049**: O sistema DEVE apresentar, para cada tipo de documento, os campos que lhe são próprios (número, data, órgão, endereçado, assunto, solicitante, formalizado por, minutado por e histórico, conforme o tipo).
- **FR-050**: O sistema DEVE preservar a numeração registrada no v1 e permitir vincular o documento a um protocolo ou demanda, ou mantê-lo sem vínculo.
- **FR-051**: O sistema DEVE manter o controle numérico numa estrutura de dados única com o tipo de documento como atributo, em vez de replicar a divisão do v1 em uma estrutura por tipo, sem colisão entre registros de tipos diferentes.

#### Diagnóstico

- **FR-052**: O sistema DEVE apresentar a listagem paginada de processos do diagnóstico com número do processo, autor, requerido, juízo, objeto da reclamação e resultado da reclamação.
- **FR-053**: O sistema DEVE permitir pesquisar processos por texto livre, com escolha do campo de busca (todos, número do processo, autor, requerido, juízo, objeto ou resultado) e filtro por categoria do documento.
- **FR-054**: O sistema DEVE permitir ao usuário escolher a quantidade de processos por página e navegar a base completa sem repetir nem omitir registros.
- **FR-055**: O sistema DEVE apresentar o painel de indicadores do diagnóstico com os totais da carteira (processos, procedências, improcedências, sentenças e petições iniciais) e os gráficos de distribuição, permitindo abrir o detalhe dos processos por trás de cada segmento.
- **FR-056**: Usuários DEVEM ser capazes de marcar e desmarcar processos para acompanhamento, com a marcação gravada no servidor e vinculada ao usuário — disponível em qualquer navegador ou dispositivo em que ele se autentique.
- **FR-057**: O sistema DEVE permitir exportar o relatório do painel e o relatório da seleção de processos em documento timbrado da instituição, com opção de incluir ou não os gráficos.
- **FR-058**: O sistema DEVE consumir os processos do diagnóstico da base externa alimentada pela automação jurídica, em modo somente leitura, sem alterá-la.
- **FR-059**: O sistema DEVE informar de forma clara ao usuário quando a base externa de processos estiver indisponível ou responder com erro, sem apresentar a carteira como vazia e sem impedir o uso das demais telas do módulo.
- **FR-060**: O sistema DEVE tolerar processos com campos ausentes ou inconsistentes vindos da automação, exibindo-os de forma legível em vez de falhar na listagem.

#### Diagnóstico — processos administrativos e documentos institucionais

- **FR-061**: O sistema DEVE apresentar a área de processos administrativos do diagnóstico com a listagem de documentos institucionais e a listagem de processos administrativos.
- **FR-062**: Usuários DEVEM ser capazes de iniciar um documento institucional a partir de um modelo do tipo aplicável, obtendo um número reservado para ele.
- **FR-063**: Usuários DEVEM ser capazes de preencher os campos do documento institucional, emitir o PDF, registrar o envio e cancelar o documento.
- **FR-064**: O sistema DEVE registrar e permitir consultar quem acessou cada documento institucional e quando.
- **FR-065**: O sistema DEVE liberar ou marcar como abandonado o número reservado de um documento institucional que não foi concluído dentro do prazo de reserva, mantendo rastreável o motivo da lacuna na numeração.
- **FR-066**: O sistema DEVE impedir que dois documentos institucionais recebam o mesmo número, inclusive sob emissão simultânea por usuários diferentes.

#### Portal público da Ouvidoria

- **FR-067**: O sistema DEVE oferecer um portal público, servido pela plataforma v2, em que o cidadão registre uma manifestação sem se autenticar, informando tipo, assunto, descrição, dados de contato e anexos.
- **FR-068**: O portal público DEVE permitir ao cidadão optar pelo anonimato, e nesse caso o sistema NÃO DEVE expor nome nem documento do requerente em nenhuma tela interna ou documento gerado.
- **FR-069**: O portal público DEVE informar ao cidadão o número de protocolo da manifestação registrada.
- **FR-070**: O portal público DEVE permitir consultar, pelo número de protocolo e sem autenticação, a situação da manifestação e a resposta quando houver.
- **FR-071**: O portal público DEVE proteger-se contra envio automatizado em massa, sem impedir o registro por parte do cidadão legítimo.
- **FR-072**: O portal público DEVE apresentar a identidade visual da instituição atendida e DEVE ser capaz de atender mais de uma instituição por configuração, a partir de uma única aplicação.
- **FR-073**: As manifestações registradas pelo portal público DEVEM aparecer nas telas internas da Ouvidoria identificadas como de origem pública, no mesmo fluxo de atendimento das internas.

#### Qualidade e ausência de débito técnico

- **FR-074**: O sistema DEVE ter, para cada módulo migrado, uma única implementação de cada capacidade — as implementações concorrentes que existem no v1 (duas de Ouvidoria e duas de Demandas) NÃO DEVEM ser reproduzidas no v2.
- **FR-075**: O sistema DEVE validar todo dado recebido de fora (formulário do usuário, requisição, base externa de processos e resposta de sistema de terceiro) rejeitando entrada inválida com mensagem que identifique o campo, antes de qualquer gravação.
- **FR-076**: O sistema DEVE aplicar filtros, buscas, ordenação e paginação sobre a totalidade dos registros, e NÃO DEVE depender de carregar grandes volumes na tela do usuário para depois filtrar localmente.
- **FR-077**: O sistema NÃO DEVE guardar em armazenamento local do navegador dado de negócio que precise sobreviver a troca de dispositivo ou ser auditável — em particular as marcações de acompanhamento do diagnóstico.
- **FR-078**: Toda tela dos módulos migrados DEVE apresentar estado de carregamento, estado vazio e estado de erro com possibilidade de nova tentativa, sem falha silenciosa.
- **FR-079**: O sistema DEVE restringir todo acesso aos dados dos módulos migrados à instituição do usuário autenticado, e ao seu nível de acesso e setor, sem que nenhuma tela ou consulta permita alcançar dados de outra instituição.
- **FR-080**: Cada módulo migrado DEVE ter cobertura de teste automatizada dos seus fluxos de uso e das suas regras de validação, executável sem intervenção manual, como condição para ser considerado concluído.
- **FR-081**: O sistema DEVE registrar em trilha de auditoria as operações de criação, alteração e remoção nos módulos migrados, identificando autor, data e registro afetado.

### Key Entities *(include if feature involves data)*

- **Instituição (AGEMAN)**: Órgão cujos módulos e dados estão sendo migrados; define o escopo de todo acesso e de toda contagem de verificação.
- **Usuário e Diretoria/Setor**: Servidor que opera os módulos e a unidade organizacional a que pertence; determinam o que ele vê e para onde pode encaminhar.
- **Manifestação**: Registro de reclamação, solicitação, denúncia, elogio, sugestão ou simplificação feito por um cidadão; tem protocolo, tipo, categoria, motivo, prioridade, situação, requerente (possivelmente anônimo), endereço, anexos, resposta e linha do tempo de eventos; pode ser de origem interna ou pública.
- **Catálogo da Ouvidoria**: Tipos de manifestação, categorias, formas de atendimento e serviços internos que alimentam o registro e os relatórios.
- **Demanda do Gabinete**: Assunto em tramitação entre setores, com origem, setor atual, situação, prazos de concessionária, histórico de encaminhamentos, anexos e vínculo opcional a manifestação ou protocolo.
- **Protocolo do Gabinete**: Documento de entrada registrado pelo Gabinete, com número interno, número SIGED, remetente, forma de entrada, data e hora de recebimento, assunto, tipo de documento e anexos.
- **Documento Tramitado**: Registro de controle de um documento em trâmite dentro de um setor específico, opcionalmente vinculado a protocolo ou demanda.
- **Notificação à Concessionária**: Notificação formal dirigida à concessionária regulada, com termo, destinatário, laudo, fato gerador, prazo, vencimento, situação e resposta.
- **Auto de Infração**: Autuação dirigida à concessionária, com documento, destinatário, setor emissor, assunto, valor monetário, prazo, vencimento e resposta.
- **Documento de Controle Numérico**: Ofício, ofício circular, portaria, memorando, memorando circular ou resolução emitido pela instituição, com numeração controlada e vínculo opcional a protocolo ou demanda.
- **Processo do Diagnóstico**: Processo judicial da carteira, proveniente da base externa alimentada por automação, com número, autor, requerido, juízo, objeto e resultado da reclamação; consumido somente para leitura.
- **Marcação de Acompanhamento**: Indicação, por usuário, de que um processo do diagnóstico está sob acompanhamento.
- **Documento Institucional**: Documento administrativo emitido a partir de modelo, com número reservado, campos preenchidos, situação (reservado, enviado, cancelado, abandonado), PDF gerado e histórico de acessos.
- **Anexo**: Arquivo vinculado a manifestação, demanda, protocolo ou documento institucional, com nome, tipo, tamanho e localização no armazenamento compartilhado.
- **Evento de Auditoria**: Registro de criação, alteração, remoção ou movimentação, com autor, data e registro afetado.
- **Relatório de Correspondência da Migração**: Resultado da verificação entre v1 e v2, com contagem de origem, contagem de destino, exclusões deliberadas e divergências identificadas por registro e campo.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% dos registros reais da AGEMAN nos módulos migrados estão presentes no v2, comprovado por relatório de correspondência em que a contagem de origem menos as exclusões aprovadas é igual à contagem de destino, para cada tipo de dado.
- **SC-002**: A verificação de conteúdo campo a campo entre v1 e v2 conclui com zero divergências não justificadas em 100% dos registros comparados.
- **SC-003**: Um registro localizado no v1 pelo seu identificador de negócio é encontrado no v2 pelo mesmo identificador em 100% dos casos amostrados.
- **SC-004**: A verificação automatizada de interface cobre todas as telas dos módulos migrados e, quando uma divergência é introduzida de propósito, ela é detectada em 100% das tentativas — comprovando que a verificação não aprova em falso.
- **SC-005**: As verificações automatizadas rodam do início ao fim sem intervenção manual e produzem resultado idêntico em execuções consecutivas sobre o mesmo estado.
- **SC-006**: Nenhuma capacidade que o servidor da AGEMAN tinha no v1 nos módulos migrados deixa de existir no v2, verificado por checklist de capacidades assinado pelos responsáveis de cada módulo antes da liberação.
- **SC-007**: 100% dos anexos migrados cujo arquivo existe no armazenamento abrem para download no v2; os que não existem estão listados no relatório de migração e sinalizados na tela.
- **SC-008**: Nenhum servidor da AGEMAN relata perda de acesso a dado ou operação que possuía no v1, nos primeiros 15 dias após a liberação de cada módulo.
- **SC-009**: 100% das tentativas de acessar dado de outra instituição, por qualquer tela ou consulta dos módulos migrados, são recusadas.
- **SC-010**: Nenhum dado de negócio dos módulos migrados depende de armazenamento local do navegador para persistir — verificável limpando o navegador e reabrindo o sistema. **Exceção documentada (2026-09-14, decidida com o usuário em `/speckit-plan` da feature [045-rascunho-manifestacao-ouvidoria](../045-rascunho-manifestacao-ouvidoria/plan.md))**: o rascunho local recuperável do assistente de nova manifestação da Ouvidoria pode usar armazenamento do navegador (IndexedDB) como mecanismo de resiliência a queda de API/sessão — restrito a um único registro por operador+tenant, expiração automática de 24h, sempre revalidado no servidor antes de oferecer retomada, e nunca usado como fallback silencioso de indisponibilidade (ver `research.md` da 045 para o racional completo e a distinção em relação ao anti-padrão do v1 descrito em R15 abaixo).
- **SC-011**: Nenhuma capacidade dos módulos migrados existe em duas implementações concorrentes no v2.
- **SC-012**: Nenhuma tela dos módulos migrados carrega mais registros do que exibe para filtrar localmente; filtro, busca e paginação refletem a base completa, verificável com um filtro cujo resultado esteja fora da primeira página.
- **SC-013**: Um servidor consegue concluir o ciclo completo de atendimento de uma manifestação no v2 (registrar, responder, encaminhar, encerrar com carta) sem recorrer ao v1.
- **SC-014**: Um servidor consegue concluir o ciclo completo de tramitação de uma demanda no v2 (receber, encaminhar, reencaminhar, devolver, extrair histórico) sem recorrer ao v1.
- **SC-015**: Os indicadores e gráficos do painel da Ouvidoria e do painel do Diagnóstico apresentam, para o mesmo período e a mesma base, exatamente os mesmos números que o v1.
- **SC-016**: Nenhum número de documento institucional é emitido em duplicidade, inclusive sob emissão simultânea; toda lacuna de numeração tem motivo registrado.
- **SC-017**: O cidadão consegue registrar uma manifestação pelo portal público, receber o protocolo e consultar o andamento por ele, sem autenticação, e o registro aparece imediatamente na tela interna da Ouvidoria.
- **SC-018**: Uma única aplicação de portal público atende a AGEMAN e é capaz de atender outra instituição apenas por configuração, sem cópia de código.
- **SC-019**: Toda entrada inválida submetida aos módulos migrados é recusada com mensagem que identifica o campo, e nenhum registro inconsistente é gravado.
- **SC-020**: Cada módulo é declarado concluído apenas com sua cobertura de teste automatizada passando integralmente.

## Assumptions

- **Escopo de instituição**: a migração cobre exclusivamente o tenant AGEMAN (decisão confirmada com o usuário). Os demais tenants do v1 (SEDEL, ARSEPAM, SEJUSC) permanecem no v1 e não são afetados.
- **Nível de fidelidade**: a meta é **paridade de capacidade**, não paridade de layout (decisão confirmada com o usuário) — nenhuma funcionalidade ou dado se perde, mas a estrutura de dados consolidada e a experiência de uso do v2 prevalecem sobre a organização de telas do v1. Diferenças de disposição visual não são consideradas divergência; ausência de capacidade é.
- **Migração de dados dentro desta spec**: a carga de dados da AGEMAN faz parte deste ciclo (decisão confirmada com o usuário) e **substitui** a spec `036-migracao-agema-v1`, que deve ser marcada como superseded.
- **Fonte dos dados do v1**: a comparação e a carga usam o dump de produção mais recente (`controleinterno_prod_ci (14).sql`, gerado em 21/08/2026), restaurado num banco MySQL local — evitando qualquer escrita ou carga sobre a produção.
- **Ferramentas de verificação**: a verificação de interface usa Playwright contra os dois sistemas em execução, e a verificação de dados usa scripts com acesso direto aos dois bancos (decisão confirmada com o usuário). A definição de como os cenários são organizados e onde os scripts vivem é tratada no plano técnico.
- **Diagnóstico consome base externa**: o v2 conecta diretamente na mesma base externa somente-leitura de processos usada pelo v1 (decisão confirmada com o usuário), sem criar pipeline de sincronização e sem alterar a base de origem.
- **Documentos institucionais entram no escopo**: a aba de processos administrativos do Diagnóstico depende do recurso de documentos institucionais do v1; ele é migrado no que é consumido pelo Diagnóstico (modelos dos tipos aplicáveis, reserva de número, preenchimento, emissão de PDF, envio, cancelamento e histórico de acessos), e não como módulo independente para outros fins.
- **Portal público entra no escopo**: o portal público de manifestações passa a viver dentro do monorepo do v2, reaproveitando os componentes de interface já existentes (decisão confirmada com o usuário), em vez de continuar como aplicação separada.
- **Anexos reaproveitam o armazenamento existente**: os dois sistemas usam o mesmo armazenamento de arquivos e as mesmas credenciais (informação confirmada com o usuário); a migração define a lógica de correspondência entre a referência antiga e a do v2 para que os arquivos continuem acessíveis, sem novo envio pelo usuário.
- **Senhas e identidade**: usuários migram com a senha já criptografada e continuam autenticando com as mesmas credenciais, sem redefinição obrigatória.
- **Fora de escopo por decisão explícita**: fiscalização, insights com IA e maturidade **não** fazem parte desta migração. Onde esses recursos já existem no v2, permanecem intocados; onde existem no v1, não são migrados.
- **Fora de escopo — outros módulos do v1**: Protocolo Virtual (portal de solicitações SEDEL), compras, patrimônio, contratos, saúde, jurídico, prestação de contas e demais módulos do v1 não fazem parte deste ciclo. "Protocolo" nesta spec significa exclusivamente o Protocolo do Gabinete, e "Diretorias" significa exclusivamente as diretorias do Gabinete (decisões confirmadas com o usuário).
- **Estratégia de virada de produção fora de escopo**: a decisão de quando desligar o v1 para a AGEMAN, e como conduzir o período de coexistência, será tratada separadamente após a validação dos módulos migrados. Enquanto houver coexistência, assume-se que cada módulo tem um único sistema de escrita autoritativo por vez, para não gerar divergência irreconciliável.
- **Ambiente de trabalho**: durante o desenvolvimento, os quatro serviços rodam simultaneamente em portas distintas (v2 API, v2 cliente, v1 API, v1 cliente), permitindo a comparação lado a lado exigida pela verificação de interface.
