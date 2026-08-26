# Feature Specification: Migração de Dados v1 → v2 — Tenant AGEMAN (Agema)

**Feature Branch**: `036-migracao-agema-v1`

**Created**: 2026-08-10

**Status**: Superseded — substituída por [038-migracao-modulos-v1](../038-migracao-modulos-v1/spec.md)

> Esta spec cobria apenas a migração de **dados** do tenant AGEMAN. A spec 038 absorveu esse escopo e o ampliou para a migração dos **módulos inteiros** (código, telas e dados), por decisão do usuário em 21/08/2026. Não implementar a partir daqui — use a 038. O material de referência abaixo (mapeamento v1→v2, `data-model.md`, `contracts/`, `reconciliation/`) permanece válido como insumo do planejamento da 038.

**Input**: User description: "vamos migrar v1 para v2 finalmente! vamos os dados migrar o tenant agema (final 002). migre tudo referente a: auth, tenant, ouvidoria, gabinete (cabinet), siged. Referência: C:\ci-v2\integração-siged"

## User Scenarios & Testing *(mandatory)*

<!--
  IMPORTANT: User stories should be PRIORITIZED as user journeys ordered by importance.
  Each user story/journey must be INDEPENDENTLY TESTABLE - meaning if you implement just ONE of them,
  you should still have a viable MVP (Minimum Viable Product) that delivers value.
-->

### User Story 1 - Servidores da AGEMAN acessam o v2 com a identidade que já usavam (Priority: P1)

Um servidor da AGEMAN (ex.: usuário do setor DEAE, chefe de setor, ou administrador da instituição) que hoje acessa o sistema v1 precisa conseguir entrar no v2 com o mesmo e-mail/senha, ver os mesmos setores aos quais pertence e continuar tendo acesso aos módulos e telas que já tinha liberados — sem precisar de novo cadastro ou redefinição de senha.

**Why this priority**: É pré-requisito para qualquer outra migração — sem usuários, setores e permissões migrados corretamente, nenhum outro dado (ouvidoria, gabinete) pode ser operado por ninguém no v2.

**Independent Test**: Pode ser totalmente testado fazendo login no v2 com as credenciais de um usuário real da AGEMAN migrado e verificando que ele vê os mesmos setores/módulos que via no v1.

**Acceptance Scenarios**:

1. **Given** um usuário ativo do tenant AGEMAN no v1 (com senha já criptografada), **When** ele faz login no v2 com o mesmo e-mail e senha, **Then** o acesso é concedido sem necessidade de redefinir a senha.
2. **Given** um usuário que pertencia a um ou mais setores no v1 (ex.: DEAE, DEJUR, Gabinete), **When** o administrador da instituição consulta o cadastro desse usuário no v2, **Then** os mesmos setores aparecem vinculados a ele.
3. **Given** um usuário que era "Super Administrador" (isSuperAdmin) da AGEMAN no v1, **When** a migração é concluída, **Then** esse usuário consegue administrar o tenant no v2 com privilégios equivalentes aos que tinha.
4. **Given** um setor da AGEMAN com usuário marcado como gestor (`is_manager = 1` em `user_sectors` no v1), **When** a migração é concluída, **Then** esse usuário aparece como chefe do setor no v2 (`Setor.chefeUserId`) e com role `chefe_setor` quando aplicável.

---

### User Story 2 - Ouvidoria da AGEMAN mantém o histórico de manifestações dos cidadãos (Priority: P2)

Um atendente da Ouvidoria da AGEMAN precisa continuar vendo, no v2, todas as manifestações (reclamações, denúncias, elogios, sugestões) já registradas no v1, com seus dados do requerente, endereço, categoria, anexos e linha do tempo de eventos (registro, encaminhamento, resposta, encerramento) — preservando o número de protocolo original.

**Why this priority**: Ouvidoria é um módulo de atendimento ao cidadão com obrigações de prazo e transparência; perder histórico de manifestações compromete auditoria e continuidade do atendimento.

**Independent Test**: Pode ser testado buscando, no v2, uma manifestação da AGEMAN pelo número de protocolo original do v1 e confirmando que todos os dados (requerente, categoria, anexos, eventos) aparecem íntegros.

**Acceptance Scenarios**:

1. **Given** uma manifestação registrada no v1 para a AGEMAN, **When** um atendente busca pelo número de protocolo original no v2, **Then** a manifestação é encontrada com o mesmo assunto, descrição, categoria e status equivalente.
2. **Given** uma manifestação anônima no v1, **When** ela é migrada, **Then** o anonimato do requerente é preservado no v2.
3. **Given** uma manifestação com anexos (arquivos) no v1, **When** ela é visualizada no v2, **Then** os anexos continuam acessíveis para download.
4. **Given** uma manifestação com histórico de eventos (encaminhamentos entre setores, respostas, encerramento) no v1, **When** ela é visualizada no v2, **Then** a linha do tempo de eventos aparece na mesma ordem cronológica.

---

### User Story 3 - Gabinete da AGEMAN mantém protocolos, casos e controles em andamento (Priority: P2)

Um servidor do Gabinete (ou de um setor técnico como DEAE, DERET, DEGPLAN, DEJUR) precisa continuar vendo, no v2, os protocolos recebidos, os casos/demandas em tramitação entre setores, e os controles administrativos (ofícios, portarias, memorandos, resoluções, notificações à concessionária, autos de infração) que já existiam no v1, incluindo os documentos tramitados registrados por cada setor.

**Why this priority**: O Gabinete concentra o fluxo de trabalho diário entre setores da AGEMAN (recebimento, análise, resposta da concessionária, emissão de auto de infração); perder isso interrompe processos administrativos em andamento.

**Independent Test**: Pode ser testado localizando um protocolo específico do Gabinete da AGEMAN no v2 (pelo número interno ou número SIGED) e confirmando que os controles numéricos e documentos tramitados vinculados a ele aparecem corretamente.

**Acceptance Scenarios**:

1. **Given** um protocolo do Gabinete registrado no v1 para a AGEMAN, **When** ele é buscado no v2 pelo número interno, **Then** remetente, assunto, data e forma de entrada aparecem idênticos.
2. **Given** um controle numérico (ofício, portaria, memorando ou resolução) vinculado a um protocolo ou caso no v1, **When** migrado, **Then** ele aparece vinculado ao mesmo protocolo/caso no v2, com o mesmo número e conteúdo.
3. **Given** um auto de infração ou notificação à concessionária registrado no v1, **When** migrado, **Then** valor, prazo, situação e resposta aparecem preservados no v2.
4. **Given** um documento tramitado por um setor específico (ex.: DEAE, DEGPLAN, DEJUR) no v1, **When** migrado, **Then** ele aparece vinculado ao mesmo setor no v2.

---

### User Story 4 - Servidor consulta a tramitação real do SIGED direto no protocolo do Gabinete (Priority: P3)

Um servidor que abre um protocolo do Gabinete da AGEMAN no v2 precisa, além de ver o número SIGED migrado do v1, conseguir consultar a tramitação real daquele protocolo no sistema municipal SIGED (movimentações entre órgãos, datas, status de recebimento) diretamente pela tela do protocolo, sem precisar acessar outro sistema.

**Why this priority**: Depende da fundação de Auth/Tenant e do modelo de Protocolo do Gabinete já migrado (User Stories 1 e 3); entrega o valor adicional de tornar o SIGED uma fonte viva de dados dentro do v2, e não apenas um número de referência estático.

**Independent Test**: Pode ser testado abrindo, no v2, um protocolo do Gabinete da AGEMAN que possui número SIGED e confirmando que a tramitação retornada corresponde à consulta equivalente feita diretamente na API/sistema SIGED para o mesmo protocolo.

**Acceptance Scenarios**:

1. **Given** um protocolo do Gabinete da AGEMAN com número SIGED preenchido (migrado do v1), **When** o usuário abre a tela de detalhe do protocolo no v2, **Then** o sistema busca e exibe o histórico de tramitações daquele protocolo diretamente do sistema SIGED.
2. **Given** um protocolo do Gabinete cuja forma de entrada era "SIGED" no v1, **When** migrado, **Then** o modo de entrada do protocolo no v2 é registrado como originado do SIGED.
3. **Given** um protocolo sem número SIGED associado, **When** o usuário abre sua tela de detalhe, **Then** o sistema não tenta consultar o SIGED e informa claramente que não há tramitação SIGED vinculada.
4. **Given** o sistema SIGED está indisponível ou retorna erro no momento da consulta, **When** o usuário abre um protocolo com número SIGED, **Then** o v2 exibe uma mensagem de indisponibilidade sem quebrar a visualização dos demais dados do protocolo.
5. **Given** uma tramitação retornada pelo SIGED, **When** exibida no v2, **Then** fica claramente identificada como proveniente do sistema externo SIGED (e não como um evento registrado internamente pela AGEMAN).

---

### Edge Cases

- O que acontece com usuários cujo e-mail já existe em outro tenant do v2 (ex.: contas de desenvolvimento reaproveitadas entre tenants no v1)? A unicidade de e-mail no v2 é por tenant, então isso não deve gerar conflito, mas deve ser validado.
- Como tratar registros com `deletedAt`/`deletado_em` preenchido (soft-deleted) no v1 — eles devem existir no v2 marcados como excluídos, preservando o histórico?
- Como tratar usuários e registros nitidamente de teste/QA (ex.: e-mails "QA@AGEMAN.com", "teste@teste.com", registros com assunto "teste", "asdasd") presentes no tenant AGEMAN de produção do v1?
- Manifestações com requerente anônimo (`isAnonymous`) não devem expor nome/documento do requerente após a migração.
- Um mesmo usuário pode ser chefe de mais de um setor, ou um setor pode não ter chefe definido — ambos os casos devem ser suportados.
- Anexos (arquivos) de manifestações, demandas e protocolos estão armazenados fisicamente em um storage do v1 — a migração de metadados sem migrar o arquivo físico correspondente deixaria links quebrados.
- Protocolos/controles numéricos sem vínculo a nenhuma demanda/caso (`demanda_id` nulo) devem ser migrados como registros "soltos", tal como estão no v1.
- Contas de "Super Administrador" (isSuperAdmin=1) da AGEMAN não são linhas de `User` no modelo do v2 — são administradores da instituição (tabela separada) — a migração precisa direcioná-las corretamente.
- A consulta ao sistema SIGED pode ficar temporariamente indisponível, lenta, ou sem autorização para um determinado protocolo — o v2 precisa lidar com isso sem impedir a visualização do restante dos dados do protocolo.
- Um protocolo pode ter número SIGED preenchido no v1 mas esse número não existir (ou não pertencer à AGEMAN) no sistema SIGED real — a consulta deve falhar de forma clara em vez de exibir dados incorretos.
- Dados de teste/QA podem estar referenciados por dados reais (ex.: uma manifestação real anexada por um usuário de teste) — a exclusão de um registro de teste não deve quebrar a integridade referencial dos dados reais que dependem dele.

## Requirements *(mandatory)*

### Functional Requirements

**Tenant**

- **FR-001**: O sistema DEVE migrar o registro do tenant AGEMAN (nome oficial, status ativo/inativo, identidade visual/branding e configurações de menu) do v1 para o v2, preservando seu identificador de forma que todos os demais dados migrados continuem associados a ele.

**Auth (usuários, setores e permissões)**

- **FR-002**: O sistema DEVE migrar todos os usuários do tenant AGEMAN (nome, e-mail, CPF, senha criptografada, status ativo/inativo) de forma que cada um consiga autenticar no v2 com a mesma senha que usava no v1.
- **FR-003**: O sistema DEVE migrar todos os setores (departamentos) da AGEMAN, incluindo nome, sigla, descrição e setor pai/chefe, quando aplicável.
- **FR-004**: O sistema DEVE migrar o vínculo entre cada usuário e o(s) setor(es) a que pertence, preservando a mesma associação existente no v1.
- **FR-005**: O sistema DEVE preservar, para cada usuário migrado, o nível de acesso equivalente ao que ele tinha no v1 (usuário comum, chefe de setor, ou administrador da instituição), traduzindo o modelo de papéis/permissões granulares do v1 para o modelo de papéis e acesso por setor/módulo do v2.
- **FR-006**: O sistema DEVE direcionar usuários marcados como "Super Administrador" (isSuperAdmin) da AGEMAN no v1 para o papel de administrador da instituição no v2, e não para uma conta de usuário comum.

**Ouvidoria**

- **FR-007**: O sistema DEVE migrar todas as manifestações da AGEMAN (reclamação, solicitação, denúncia, elogio, sugestão, simplifique), preservando número de protocolo, tipo, categoria, prioridade, status, assunto e descrição.
- **FR-008**: O sistema DEVE migrar os dados do requerente de cada manifestação (nome, documento, contatos, endereço), respeitando o sinalizador de anonimato quando presente.
- **FR-009**: O sistema DEVE migrar os anexos de cada manifestação, incluindo o arquivo físico correspondente, de forma que continuem disponíveis para download no v2.
- **FR-010**: O sistema DEVE migrar o histórico de eventos de cada manifestação (registro, encaminhamento entre setores, resposta, encerramento, notas), preservando a ordem cronológica e o setor/usuário responsável por cada evento.

**Gabinete (Cabinet)**

- **FR-011**: O sistema DEVE migrar todos os protocolos do Gabinete da AGEMAN (número interno, número SIGED, remetente, data e forma de entrada, assunto, tipo de documento).
- **FR-012**: O sistema DEVE migrar todos os casos/demandas do Gabinete da AGEMAN, preservando número de protocolo, origem, setor atual, status do fluxo e vínculos com manifestação de ouvidoria ou protocolo de origem, quando existentes.
- **FR-013**: O sistema DEVE migrar os controles numéricos (ofícios, ofícios circulares, portarias, memorandos, memorandos circulares e resoluções) da AGEMAN, preservando número, data, órgão, destinatário e conteúdo, e o vínculo com o protocolo/caso de origem.
- **FR-014**: O sistema DEVE migrar os registros de controle de notificação à concessionária e de autos de infração da AGEMAN, preservando prazos, valores, situação e resposta.
- **FR-015**: O sistema DEVE migrar os documentos tramitados por cada setor da AGEMAN (ex.: DEAE, DEGPLAN, DEJUR, DERES), preservando o vínculo com o setor responsável e com o protocolo/caso de origem.

**SIGED**

- **FR-016**: O sistema DEVE preservar, em cada protocolo do Gabinete migrado, o número SIGED originalmente registrado no v1, quando existente.
- **FR-017**: O sistema DEVE preservar a informação de que um protocolo teve entrada via SIGED, quando essa era a forma de entrada registrada no v1.
- **FR-020**: O sistema DEVE permitir consultar, para um protocolo do Gabinete da AGEMAN com número SIGED associado, o histórico de tramitações (movimentações entre órgãos) registrado no sistema SIGED, usando esse número como referência.
- **FR-021**: O sistema DEVE autenticar-se no sistema SIGED com credenciais próprias da AGEMAN, de forma consistente com o modelo multi-tenant (uma instituição não pode consultar dados de outra através dessa integração).
- **FR-022**: O sistema DEVE identificar visualmente, para o usuário, quais dados de tramitação exibidos vêm do sistema externo SIGED (em oposição a eventos registrados internamente pela AGEMAN).
- **FR-023**: O sistema DEVE informar de forma clara quando a consulta ao SIGED falhar (indisponibilidade, erro, ou protocolo não encontrado), sem impedir a visualização dos demais dados do protocolo.

**Transversal**

- **FR-018**: O sistema DEVE migrar apenas os dados cujo tenant no v1 seja o tenant AGEMAN (identificador terminado em "002"), sem afetar dados de outros tenants (SEDEL, ARSEPAM, SEJUSC, tenants de teste).
- **FR-019**: O sistema DEVE permitir verificar, ao final da migração, que a quantidade de registros migrados de cada tipo (usuários, setores, manifestações, protocolos, demandas, controles) corresponde à quantidade esperada — ou seja, a quantidade existente no v1 para a AGEMAN **menos** os registros excluídos por serem de teste/QA (FR-024).
- **FR-024**: O sistema DEVE excluir da migração usuários e registros identificados como dados de teste/QA/placeholder do tenant AGEMAN (ex.: contas como "QA@AGEMAN.com", "teste@teste.com", registros com conteúdo de teste como "asdasd"), a partir de uma lista de exclusão revisada e aprovada pela equipe da AGEMAN antes da execução da migração.
- **FR-025**: O sistema DEVE preservar a integridade referencial dos dados reais mesmo quando um registro relacionado (ex.: usuário que criou o registro) tenha sido excluído por ser dado de teste/QA — nenhum dado real migrado pode ficar órfão ou quebrado por causa dessa exclusão.

### Key Entities *(include if feature involves data)*

- **Tenant (AGEMAN)**: A instituição cujos dados estão sendo migrados; possui nome, status e configurações de aparência/menu.
- **Usuário**: Pessoa que acessa o sistema; pertence a um ou mais Setores; possui um nível de acesso (usuário, chefe de setor, administrador da instituição).
- **Administrador da Instituição**: Usuário com privilégios administrativos sobre o tenant AGEMAN (distinto de usuário comum).
- **Setor**: Unidade organizacional da AGEMAN (ex.: DEAE, DEJUR, Gabinete, Ouvidoria); pode ter um usuário como chefe.
- **Manifestação (Ouvidoria)**: Registro de reclamação/solicitação/denúncia/elogio/sugestão de um cidadão; possui requerente, categoria, anexos e histórico de eventos.
- **Protocolo (Gabinete)**: Documento de entrada registrado pelo Gabinete; possui número interno, número SIGED, remetente e forma de entrada.
- **Caso/Demanda (Gabinete)**: Fluxo de tramitação de um assunto entre setores da AGEMAN, com origem, setor atual e status.
- **Controle Numérico**: Ofício, portaria, memorando ou resolução emitido, vinculado a um protocolo/caso.
- **Controle de Notificação / Auto de Infração**: Registro de notificação formal ou autuação dirigida à concessionária regulada, com prazos e respostas.
- **Documento Tramitado por Setor**: Registro de um documento em trâmite dentro de um setor específico da AGEMAN.
- **Tramitação SIGED**: Movimentação entre órgãos de um protocolo, consultada em tempo real no sistema municipal SIGED a partir do número SIGED associado a um Protocolo do Gabinete.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% dos usuários ativos e não identificados como teste/QA da AGEMAN conseguem fazer login no v2 com as mesmas credenciais que usavam no v1, sem precisar redefinir senha.
- **SC-002**: 100% dos setores da AGEMAN e das associações usuário-setor existentes no v1 (excluindo dados de teste/QA) estão presentes e corretas no v2, verificável por contagem e amostragem.
- **SC-003**: 100% das manifestações de ouvidoria reais da AGEMAN registradas no v1 estão disponíveis no v2, localizáveis pelo número de protocolo original, com anexos acessíveis.
- **SC-004**: 100% dos protocolos, casos, controles numéricos, notificações e autos de infração reais do Gabinete da AGEMAN registrados no v1 estão disponíveis no v2, sem perda de registros (contagem v1 real = contagem v2 por tipo de dado).
- **SC-005**: Nenhum usuário da AGEMAN relata perda de acesso a um setor ou módulo que possuía no v1, avaliado nos primeiros 7 dias após a virada para o v2.
- **SC-006**: A migração é auditável — para cada tipo de dado migrado, existe uma contagem de registros de origem (v1, já descontados os registros de teste/QA excluídos) e destino (v2) que podem ser comparadas para confirmar 100% de correspondência.
- **SC-007**: Para uma amostra de protocolos do Gabinete da AGEMAN com número SIGED, a tramitação exibida no v2 corresponde à tramitação real consultada diretamente no sistema SIGED, no momento da consulta.
- **SC-008**: Nenhum dado real migrado (manifestação, protocolo, demanda, controle) fica órfão, quebrado ou inacessível em consequência da exclusão de dados de teste/QA.

## Assumptions

- O identificador do tenant AGEMAN no v1 (`00000000-0000-0000-0000-000000000002`) é o critério único usado para filtrar todos os dados a migrar; nenhum dado de outro tenant é incluído.
- Senhas migram como hash (mesmo algoritmo de criptografia usado no v1), sem exigir que os usuários redefinam senha no primeiro acesso ao v2.
- Registros soft-deleted (`deletedAt`/`deletado_em` preenchido) no v1 — que não sejam dados de teste/QA — são migrados preservando essa marcação de exclusão no v2, para manter o histórico auditável, em vez de serem descartados.
- O modelo de papéis e permissões granulares do v1 (roles, permissions, role_permissions) é traduzido para o modelo de papel + setor + acesso por módulo/tela do v2, priorizando preservar o **acesso efetivo** de cada usuário (quais setores e módulos ele consegue ver/editar) em vez de replicar nomes de papéis internos do v1 um a um.
- Arquivos anexados (manifestações, demandas, protocolos) são migrados junto com seus metadados, para que os links de download continuem funcionando no v2.
- **Dados de teste/QA são excluídos da migração** (decisão confirmada com o usuário): a equipe da AGEMAN/CI revisa e aprova, antes da execução, uma lista de usuários e registros a excluir por serem teste/QA/placeholder (ex.: contas "QA@AGEMAN.com", "teste@teste.com", registros com conteúdo como "asdasd", contas "SIGED Test User"); a definição exata dos critérios de identificação (curadoria manual vs. padrões automáticos) é detalhada na fase de planejamento.
- **A integração SIGED é construída como consulta viva** (decisão confirmada com o usuário): além de migrar o número SIGED já registrado no v1, o v2 passa a consultar o sistema SIGED da Prefeitura de Manaus em tempo real (contrato de referência em `integração-siged/openapi.json`) para exibir a tramitação de protocolos do Gabinete da AGEMAN que possuam número SIGED.
- **A estratégia de corte v1 → v2 fica fora do escopo desta spec** (decisão confirmada com o usuário): este ciclo cobre somente a migração dos dados e a habilitação da consulta SIGED; a decisão sobre desativar o v1, mantê-lo em paralelo, ou outra estratégia de virada de produção para a AGEMAN será tratada separadamente, após a validação dos dados migrados.
