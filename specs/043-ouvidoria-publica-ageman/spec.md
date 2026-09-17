# Feature Specification: Ouvidoria Pública AGEMAN (v2)

**Feature Branch**: `043-ouvidoria-publica-ageman`

**Created**: 2026-09-11

**Status**: Draft

**Input**: User description: "Recriar o portal público de ouvidoria da v1 (manifestation-public-client, tenant AGEMAN) dentro do monorepo v2 (ci-client-v2/apps/publico), mantendo o layout e o fluxo de navegação idênticos aos da v1 (landing institucional + assistente conversacional + revisão + confirmação), porém conectado aos endpoints da API v2. Fechar os gaps de paridade identificados: suportar as 6 categorias de assunto da v1 (água/saneamento, transporte coletivo, iluminação pública, coleta de resíduos, zona azul, assuntos institucionais da autarquia), permitir classificar a manifestação por tipo (reclamação/sugestão/elogio/denúncia/solicitação), coletar contato (e-mail obrigatório, telefones opcionais) e endereço do ocorrido, permitir anexar arquivos/links com upload real persistido, proteger o envio com verificação anti-robô real, e adicionar uma tela nova de consulta de protocolo (capacidade nova, inexistente na v1, já disponível na API v2). Escopo restrito ao tenant AGEMAN nesta etapa."

## Clarifications

### Session 2026-09-11

- Q: A spec coleta dados pessoais sensíveis (nome, CPF, endereço, contato) de cidadãos, muitos anônimos. Qual política de retenção/conformidade deve constar na spec? → A: Seguir a política já vigente no módulo de Ouvidoria (sem regra nova só para o portal público).
- Q: Internamente a manifestação passa por status granulares (rascunho/em análise/encaminhada/respondida/encerrada/encerrada sem solução). Quais status a tela de consulta deve exibir ao cidadão? → A: Conjunto simplificado e amigável (Recebida/Em análise/Respondida/Encerrada), igual à v1.
- Q: Se o serviço externo de verificação anti-robô estiver indisponível/lento no momento do envio, o que deve acontecer? → A: Bloquear o envio até a verificação ser bem-sucedida (falha fechada) — mais seguro contra abuso.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Registrar manifestação pelo assistente conversacional (Priority: P1)

Um cidadão acessa o portal público da AGEMAN, é recebido por uma página institucional e inicia uma conversa guiada com o assistente virtual para relatar um problema, sugestão, elogio, denúncia ou solicitação relacionada a um dos serviços fiscalizados (água/saneamento, transporte coletivo, iluminação pública, coleta de resíduos, zona azul) ou a assuntos institucionais da própria autarquia. Ao final, escolhe se identificar ou permanecer anônimo, informa um contato para receber atualizações, revisa tudo em uma tela de confirmação e envia. Recebe um número de protocolo e uma chave de consulta.

**Why this priority**: É a jornada central do produto — sem ela não há ouvidoria pública funcional. Substitui diretamente a funcionalidade já existente na v1.

**Independent Test**: Pode ser testado de ponta a ponta abrindo o portal, completando a conversa para cada uma das 6 categorias e confirmando que cada envio gera um protocolo e uma chave de consulta únicos.

**Acceptance Scenarios**:

1. **Given** o cidadão está na página inicial, **When** ele inicia uma nova manifestação e escolhe a categoria "água/saneamento", **Then** o assistente exige a matrícula do usuário antes de avançar para a descrição do problema.
2. **Given** o cidadão está preenchendo a categoria "iluminação pública", **When** ele avança sem informar o protocolo da concessionária e a identificação do poste, **Then** o sistema não permite avançar e explica o que falta.
3. **Given** o cidadão optou por permanecer anônimo, **When** chega à etapa de contato, **Then** o sistema ainda exige um e-mail válido (para envio de atualizações), sem revelar nome ou documento.
4. **Given** o cidadão revisou os dados na tela de confirmação, **When** ele confirma o envio, **Then** o sistema exibe um número de protocolo e uma chave de consulta que não se repetem entre manifestações.
5. **Given** um envio automatizado (robô) tenta se passar por um cidadão, **When** a prova anti-robô falha, **Then** a manifestação não é registrada.

---

### User Story 2 - Anexar evidências à manifestação (Priority: P2)

Durante o relato, o cidadão anexa arquivos (fotos, documentos) ou links externos (Drive, OneDrive, etc.) como evidência do problema relatado, antes de confirmar o envio.

**Why this priority**: Evidências aumentam a qualidade da manifestação e a capacidade de resolução, mas o registro básico (US1) já entrega valor sem anexos.

**Independent Test**: Pode ser testado anexando um arquivo dentro do limite permitido e confirmando que ele aparece vinculado à manifestação após o envio; e anexando um arquivo fora do limite/tipo permitido e confirmando que é rejeitado com mensagem clara.

**Acceptance Scenarios**:

1. **Given** o cidadão está na etapa de detalhes, **When** ele arrasta um arquivo dentro do limite de tamanho e tipo permitido, **Then** o arquivo é aceito e listado antes do envio final.
2. **Given** o cidadão tenta anexar um arquivo maior que o limite permitido ou de tipo não suportado, **When** ele tenta adicionar o arquivo, **Then** o sistema rejeita com uma mensagem explicando o motivo.
3. **Given** a manifestação foi enviada com anexos, **When** a equipe de ouvidoria consulta a manifestação internamente, **Then** os arquivos anexados estão de fato acessíveis (persistidos), não apenas referenciados temporariamente.

---

### User Story 3 - Consultar o andamento de uma manifestação (Priority: P2)

Um cidadão que já registrou uma manifestação retorna ao portal, informa o protocolo e a chave de consulta recebidos anteriormente, e visualiza o status atual, a resposta (se houver) e o histórico de andamento.

**Why this priority**: É uma capacidade nova em relação à v1 (que não tinha essa tela), mas de alto valor percebido pelo cidadão e já suportada pela plataforma.

**Independent Test**: Pode ser testado registrando uma manifestação, depois usando o protocolo e a chave retornados para consultar o status, e confirmando que uma chave incorreta não retorna dados de nenhuma manifestação.

**Acceptance Scenarios**:

1. **Given** o cidadão tem um protocolo e a chave de consulta corretos, **When** ele os informa na tela de consulta, **Then** vê o status atual, o assunto e o histórico de andamento da manifestação.
2. **Given** o cidadão informa um protocolo válido mas uma chave incorreta, **When** ele consulta, **Then** o sistema não revela nenhuma informação da manifestação.
3. **Given** a manifestação já foi respondida, **When** o cidadão consulta, **Then** a resposta da equipe de ouvidoria é exibida.

---

### User Story 4 - Usar o portal com recursos de acessibilidade (Priority: P3)

Um cidadão com baixa visão ou dificuldade de leitura ajusta o tamanho da fonte, ativa um modo de contraste adaptado a daltonismo, e usa a leitura em voz alta do conteúdo das telas e das mensagens do assistente.

**Why this priority**: Amplia o alcance do canal público a mais cidadãos, replicando um diferencial já existente na v1, mas não bloqueia o fluxo principal de registro.

**Independent Test**: Pode ser testado ativando cada recurso de acessibilidade isoladamente e confirmando que o conteúdo permanece legível e utilizável.

**Acceptance Scenarios**:

1. **Given** o cidadão aumenta o tamanho da fonte, **When** navega pelas telas, **Then** nenhum conteúdo ou botão fica cortado ou inacessível.
2. **Given** o cidadão ativa um modo de contraste para daltonismo, **When** navega pelo portal, **Then** as cores continuam distinguíveis e os elementos interativos continuam identificáveis.
3. **Given** o cidadão ativa a leitura em voz alta, **When** passa o foco sobre uma mensagem do assistente ou opção, **Then** o conteúdo é lido em voz alta em português.

---

### User Story 5 - Tirar dúvidas rápidas antes de registrar (Priority: P3)

Um cidadão em dúvida sobre quais serviços a AGEMAN fiscaliza, como funciona a ouvidoria, ou como obter o protocolo, conversa com um assistente de perguntas frequentes acessível a qualquer momento na página institucional.

**Why this priority**: Reduz abandono e dúvidas antes do registro, mas é um complemento — não bloqueia o fluxo principal.

**Independent Test**: Pode ser testado abrindo o widget de dúvidas e confirmando respostas coerentes para as perguntas mais comuns (serviços fiscalizados, contatos, como obter o protocolo).

**Acceptance Scenarios**:

1. **Given** o cidadão está na página inicial, **When** abre o assistente de dúvidas e pergunta sobre um serviço fiscalizado, **Then** recebe uma explicação clara sobre o que é fiscalizado e como registrar uma manifestação sobre aquele serviço.
2. **Given** o cidadão pergunta como acompanhar sua manifestação, **When** o assistente responde, **Then** a resposta menciona a nova tela de consulta por protocolo e chave.

---

### Edge Cases

- O que acontece quando o cidadão fecha o navegador no meio da conversa? O progresso da conversa em andamento não precisa ser recuperado entre sessões diferentes.
- O que acontece quando o CEP informado não é encontrado? O sistema deve permitir que o cidadão prossiga informando o endereço manualmente.
- O que acontece quando o cidadão excede o número de tentativas de envio em um curto intervalo de tempo? O sistema deve bloquear novos envios temporariamente e informar quando poderá tentar novamente.
- O que acontece quando o cidadão tenta consultar um protocolo que nunca existiu? O sistema deve responder de forma idêntica a uma chave incorreta (sem revelar se o protocolo existe ou não).
- O que acontece quando um anexo enviado nunca chega a ser vinculado a uma manifestação (o cidadão abandona antes de confirmar)? O anexo temporário deve expirar e deixar de ser acessível após um período curto.
- O que acontece em telas pequenas (celular) durante a conversa com o assistente? Toda a interação (opções, campos, anexos) deve permanecer utilizável sem cortes ou rolagem quebrada.
- O que acontece quando o serviço externo de verificação anti-robô está indisponível ou não responde a tempo? O envio deve ser bloqueado (falha fechada) e o cidadão deve ser informado para tentar novamente, em vez de a manifestação ser registrada sem essa validação.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: O sistema DEVE permitir que qualquer cidadão, sem necessidade de login, registre uma manifestação através de um assistente conversacional guiado.
- **FR-002**: O sistema DEVE oferecer 6 categorias de assunto: água/saneamento, transporte coletivo, iluminação pública, coleta de resíduos, zona azul (estacionamento rotativo) e assuntos institucionais da autarquia.
- **FR-003**: O sistema DEVE permitir classificar a manifestação por tipo: reclamação, sugestão, elogio, denúncia ou solicitação.
- **FR-004**: O sistema DEVE permitir que o cidadão escolha entre se identificar (nome e documento) ou permanecer anônimo.
- **FR-005**: O sistema DEVE exigir ao menos um e-mail de contato válido, mesmo em manifestações anônimas, para envio de atualizações; telefones são opcionais.
- **FR-006**: O sistema DEVE exigir a matrícula do usuário para manifestações da categoria água/saneamento.
- **FR-007**: O sistema DEVE exigir o número de protocolo da concessionária e a identificação do poste para manifestações da categoria iluminação pública.
- **FR-008**: O sistema DEVE permitir informar o endereço do ocorrido (CEP com preenchimento automático de logradouro/bairro, número, complemento, ponto de referência e zona da cidade).
- **FR-009**: O sistema DEVE permitir anexar arquivos ou links externos como evidência, respeitando limites de tamanho e tipo de arquivo, e rejeitando com mensagem clara o que exceder esses limites.
- **FR-010**: O sistema DEVE persistir de forma real e acessível os arquivos anexados vinculados à manifestação confirmada (não apenas uma referência temporária).
- **FR-011**: O sistema DEVE validar que o envio não é automatizado (proteção anti-robô) antes de registrar a manifestação; se a verificação anti-robô não puder ser concluída (ex.: serviço externo indisponível), o sistema DEVE bloquear o envio (falha fechada) em vez de registrar a manifestação sem essa validação.
- **FR-012**: O sistema DEVE limitar a quantidade de envios e de consultas por cidadão em um curto intervalo de tempo, para prevenir abuso.
- **FR-013**: O sistema DEVE gerar, ao concluir o registro, um número de protocolo único e uma chave de consulta, exibidos ao cidadão apenas nesse momento.
- **FR-014**: O sistema DEVE permitir consultar o status de uma manifestação previamente registrada informando o protocolo e a chave de consulta.
- **FR-015**: O sistema DEVE exibir, na consulta, o status atual em um conjunto simplificado e amigável ao cidadão (Recebida / Em análise / Respondida / Encerrada — equivalente ao já usado na versão anterior do portal, sem expor os status internos granulares usados pela equipe de ouvidoria), além do assunto, a resposta (quando houver) e um histórico de marcos/eventos da manifestação.
- **FR-016**: O sistema NÃO DEVE revelar nenhuma informação de uma manifestação quando a chave de consulta informada não corresponder ao protocolo, nem indicar se o protocolo existe.
- **FR-017**: O sistema DEVE oferecer recursos de acessibilidade: ajuste de tamanho de fonte, modos de contraste voltados a daltonismo, e leitura em voz alta do conteúdo das telas e das mensagens do assistente.
- **FR-018**: O sistema DEVE oferecer um assistente de dúvidas frequentes sobre os serviços fiscalizados e sobre o funcionamento do portal, disponível a qualquer momento na página institucional.
- **FR-019**: O sistema DEVE preservar a identidade visual, o texto e o fluxo de navegação já validados na versão anterior do portal (página institucional → assistente conversacional → revisão final → confirmação com protocolo).
- **FR-020**: O sistema DEVE permanecer totalmente funcional e legível em smartphones comuns, sem elementos cortados ou inacessíveis.

### Key Entities

- **Manifestação**: relato de uma ocorrência feito pelo cidadão. Atributos principais: categoria de assunto, tipo (reclamação/sugestão/elogio/denúncia/solicitação), descrição, dados de identificação/anonimato, contato, endereço do ocorrido, status (internamente granular; exibido ao cidadão em versão simplificada: Recebida/Em análise/Respondida/Encerrada), protocolo, chave de consulta, resposta e histórico de eventos.
- **Categoria de assunto (programa)**: classificação da manifestação por serviço fiscalizado (água/saneamento, transporte coletivo, iluminação pública, coleta de resíduos, zona azul) ou institucional; determina quais dados adicionais são exigidos.
- **Anexo**: arquivo ou link vinculado a uma manifestação como evidência complementar.
- **Consulta**: operação pela qual um cidadão recupera o status e o histórico de uma manifestação usando protocolo + chave de consulta.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Um cidadão consegue concluir o registro de uma manifestação, do início ao recebimento do protocolo, em menos de 5 minutos usando o assistente conversacional.
- **SC-002**: 100% das manifestações registradas geram um protocolo e uma chave de consulta únicos e recuperáveis posteriormente.
- **SC-003**: Um cidadão consegue consultar o status de uma manifestação existente em menos de 30 segundos, sem precisar de atendimento humano.
- **SC-004**: O portal permanece 100% navegável e com todo o conteúdo legível com os três recursos de acessibilidade (fonte ampliada, contraste para daltonismo, leitura em voz alta) ativados individualmente ou em conjunto.
- **SC-005**: Tentativas de envio automatizado (robôs) são bloqueadas antes de gerar qualquer manifestação válida no sistema.
- **SC-006**: 100% dos anexos vinculados a uma manifestação confirmada permanecem acessíveis para consulta posterior pela equipe de ouvidoria.
- **SC-007**: O fluxo completo de registro é utilizável em smartphones comuns sem necessidade de zoom ou rolagem horizontal.

## Assumptions

- Escopo restrito ao tenant AGEMAN nesta etapa; os tenants SEDEL e ARSEPAM (com fluxos e visuais próprios na v1) ficam para uma iteração futura.
- O layout visual, os textos e o fluxo de navegação seguem fielmente a versão anterior do portal público da AGEMAN (mesma identidade visual e mesma experiência conversacional).
- O e-mail informado pelo cidadão é o canal de referência para futuras notificações de atualização da manifestação; o disparo efetivo dessas notificações é tratado por outra capacidade já existente da plataforma, fora do escopo desta feature.
- A tela de consulta de protocolo é uma capacidade adicional em relação à versão anterior do portal, habilitada por uma capacidade de consulta já disponível na plataforma.
- Os limites de tamanho e tipo de arquivo para anexos seguem o mesmo padrão já adotado internamente na plataforma para anexos de manifestações (mais conservador do que a versão anterior do portal).
- A categoria "assuntos institucionais da autarquia" não possui uma lista fixa de motivos pré-definidos; o cidadão descreve livremente o assunto nessa categoria.
- O conteúdo do assistente de dúvidas frequentes é institucional e fixo, sem depender de serviços externos de inteligência artificial.
- Cidadãos possuem acesso à internet e um navegador atualizado, sem exigências de acessibilidade além dos três recursos citados (fonte, contraste, leitura em voz alta).
- A retenção e o tratamento dos dados pessoais coletados (nome, CPF, endereço, contato) seguem a política já vigente para o módulo de Ouvidoria na plataforma; esta feature não introduz uma regra de retenção nova ou mais curta exclusiva para o portal público.
