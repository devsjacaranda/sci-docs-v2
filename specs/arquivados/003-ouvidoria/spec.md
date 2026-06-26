# Feature Specification: Ouvidoria Interna

**Feature Branch**: `003-ouvidoria`

**Created**: 2026-06-05

**Status**: Completed

**Input**: User description: "Implementar ouvidoria interna (servidores autenticados) — Base completa com registro, lista, detalhe, tramitação, resposta, encerramento e timeline. Formulário com Relato, Tipo (Reclamação, Solicitação, Denúncia, Elogio, Sugestão, Simplifique), Esfera, Assunto, município/local opcionais via endereço centralizado, identificação opcional do manifestante, anexos, etapa de revisão, protocolo com consulta de andamento (API, sem UI pública nesta fase). Sigilo opcional em denúncias. SPA público de envio fora de escopo."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Registrar manifestação interna (Priority: P1)

Como servidor autenticado com acesso ao módulo Ouvidoria, preciso registrar uma manifestação em nome de um cidadão ou de forma interna, preenchendo os dados do fato, anexos e revisando tudo antes de confirmar, para que a demanda entre formalmente na fila institucional com protocolo rastreável.

**Why this priority**: Sem registro estruturado e protocolo, não existe fila operacional nem base para tramitação e resposta.

**Independent Test**: Pode ser testado autenticando um usuário do setor Ouvidoria, preenchendo o formulário em três etapas (dados → anexos → revisão), confirmando o envio e verificando que a manifestação aparece na lista com protocolo único gerado.

**Acceptance Scenarios**:

1. **Given** um servidor com permissão no módulo Ouvidoria, **When** preenche **Relato**, **Tipo**, **Esfera**, **Assunto**, **Origem**, **Canal de entrada** e **Prazo de resposta** e avança pelas etapas até a revisão, **Then** vê resumo completo dos dados com instrução *"Revise os dados da sua manifestação. Caso queira alterar algum campo, retorne ao formulário."*
2. **Given** a etapa de revisão, **When** o servidor confirma o envio, **Then** o sistema gera protocolo único no formato institucional (ex.: `OUV-2026-0138`) e exibe confirmação com número de protocolo e chave de consulta para repasse ao manifestante quando houver contato.
3. **Given** o formulário de registro, **When** o servidor seleciona **Tipo** *Denúncia*, **Then** pode marcar opcionalmente **Sigilo** para proteger identificação do manifestante.
4. **Given** campos opcionais de local, **When** o servidor informa município e descrição do local do fato, **Then** os dados são associados via entidade de endereço centralizada da plataforma (sem duplicar campos de logradouro em cada módulo).
5. **Given** identificação do manifestante, **When** o servidor opta por não informar nome, documento ou contato, **Then** a manifestação é registrada como anônima sem bloquear o envio.
6. **Given** a etapa de revisão, **When** o servidor escolhe retornar ao formulário, **Then** os dados já preenchidos permanecem disponíveis para edição sem perda.

---

### User Story 2 - Anexar documentos à manifestação (Priority: P1)

Como servidor registrando uma manifestação, preciso anexar arquivos que complementem o relato (prints, vídeos, fotos, documentos), para que a equipe analise evidências junto com a demanda.

**Why this priority**: Anexos são requisito explícito do canal de ouvidoria e impactam qualidade da análise desde o registro.

**Independent Test**: Pode ser testado anexando arquivos válidos e inválidos na etapa de anexos e verificando aceitação/rejeição conforme regras de tipo e tamanho.

**Acceptance Scenarios**:

1. **Given** a etapa de anexos, **When** o servidor adiciona arquivos nos formatos aceitos (documentos de texto, imagens, planilhas e multimídia), **Then** cada arquivo é listado com nome e tamanho antes da revisão.
2. **Given** um arquivo acima de 30 MB ou com extensão não permitida, **When** o servidor tenta anexá-lo, **Then** o sistema rejeita com mensagem clara indicando limite de tamanho ou tipo não aceito — sem avançar silenciosamente.
3. **Given** manifestação confirmada com anexos, **When** a equipe abre o detalhe, **Then** consegue visualizar ou baixar cada anexo associado ao protocolo.
4. **Given** copy da etapa de anexos, **When** o servidor lê a instrução, **Then** vê orientação de que pode adicionar arquivos que complementem ou documentem a demanda (prints de conversas, vídeos, fotos, etc.).

---

### User Story 3 - Operar fila e detalhe de manifestações (Priority: P1)

Como servidor da Ouvidoria, preciso consultar a lista de manifestações com filtros e abrir o detalhe com linha do tempo, para priorizar atendimentos e acompanhar o andamento de cada protocolo.

**Why this priority**: A operação diária da ouvidoria depende da fila visível e do histórico por registro.

**Independent Test**: Pode ser testado registrando manifestações de tipos e status distintos, aplicando filtros na lista e abrindo detalhe com timeline de eventos.

**Acceptance Scenarios**:

1. **Given** manifestações registradas no tenant, **When** o servidor abre **Lista de Manifestações**, **Then** vê colunas **Protocolo**, **Tipo**, **Status**, **Prazo** e **Origem**, com filtros por tipo, status operacional, prazo e origem.
2. **Given** uma manifestação na lista, **When** o servidor abre o detalhe, **Then** vê dados completos do registro, manifestante (quando identificado e permitido), local do fato, anexos e **linha do tempo** de eventos (registro, triagem, encaminhamento, resposta, encerramento).
3. **Given** busca por protocolo, **When** o servidor informa `OUV-2026-0138`, **Then** localiza o registro correspondente em menos de uma interação adicional.
4. **Given** manifestação com prazo próximo ou vencido, **When** exibida na lista, **Then** status operacional reflete situação (*Vencendo*, *Crítico*) conforme regras da Base — sem misturar com conformidade de fiscalização.

---

### User Story 4 - Tramitar, responder e encerrar manifestação (Priority: P1)

Como servidor da Ouvidoria, preciso encaminhar manifestações a setores responsáveis, registrar respostas oficiais e encerrar demandas concluídas, para cumprir o ciclo operacional da Base do módulo.

**Why this priority**: Tramitação, resposta e encerramento compõem o núcleo operacional documentado para Ouvidoria na licença Base.

**Independent Test**: Pode ser testado abrindo detalhe de manifestação em análise, executando **Encaminhar**, **Responder** e **Encerrar** em sequência e verificando eventos na timeline e mudanças de status.

**Acceptance Scenarios**:

1. **Given** manifestação em status *Em análise*, **When** o servidor aciona **Encaminhar** informando setor ou unidade destino e observação, **Then** status passa a *Tramitando*, evento aparece na timeline e destino fica registrado.
2. **Given** manifestação em tramitação, **When** o servidor aciona **Responder** com texto de resposta oficial, **Then** resposta fica registrada na timeline com autor e data; status operacional reflete resposta emitida.
3. **Given** manifestação respondida ou sem pendência, **When** o servidor aciona **Encerrar** com motivo, **Then** status passa a *Encerrado* e nenhuma ação operacional adicional é permitida sem reabertura explícita (fora de escopo nesta feature).
4. **Given** tentativa de encerrar sem resposta quando política institucional exige resposta, **When** o servidor confirma encerramento, **Then** sistema solicita confirmação explícita ou bloqueia conforme regra configurável do tenant (padrão: permitir encerramento com motivo registrado).

---

### User Story 5 - Acesso ao módulo conforme setor (Priority: P1)

Como usuário autenticado, preciso acessar o módulo Ouvidoria apenas quando meu setor estiver autorizado, para respeitar a governança organizacional já definida na plataforma.

**Why this priority**: Ouvidoria é módulo de negócio sujeito a permissão por setor; operação interna depende dessa regra.

**Independent Test**: Pode ser testado com usuário lotado no setor Ouvidoria (acesso permitido) e usuário de outro setor sem vínculo (tela 403 conforme spec de permissão por setor).

**Acceptance Scenarios**:

1. **Given** módulo Ouvidoria vinculado ao setor Ouvidoria, **When** usuário lotado nesse setor navega ao módulo, **Then** acessa lista, registro e detalhe normalmente.
2. **Given** usuário sem setor autorizado, **When** tenta acessar rota interna de Ouvidoria, **Then** recebe **403 · Acesso negado** com copy padronizada — item permanece visível na navegação.
3. **Given** administrador da plataforma do tenant, **When** acessa Ouvidoria, **Then** tem acesso irrestrito independentemente de lotação.

---

### User Story 6 - Sigilo em denúncias (Priority: P2)

Como servidor registrando ou analisando uma denúncia, preciso marcar sigilo opcional para ocultar dados identificáveis do manifestante de quem não tem permissão específica, para proteger o denunciante conforme política institucional.

**Why this priority**: Sigilo é requisito sensível em denúncias; secundário ao fluxo principal mas necessário antes de produção em órgãos públicos.

**Independent Test**: Pode ser testado registrando denúncia com sigilo ativo e verificando que usuário comum vê manifestação sem PII do manifestante, enquanto perfil autorizado vê dados completos.

**Acceptance Scenarios**:

1. **Given** manifestação tipo *Denúncia* com **Sigilo** ativado, **When** usuário sem permissão de ouvidor/sigilo abre o detalhe, **Then** dados identificáveis do manifestante (nome, documento, contato) não são exibidos — relato, protocolo e andamento permanecem visíveis conforme lotação.
2. **Given** mesma manifestação sigilosa, **When** servidor com permissão de ouvidor/sigilo abre o detalhe, **Then** vê todos os dados do manifestante.
3. **Given** tipo diferente de *Denúncia*, **When** servidor registra manifestação, **Then** flag **Sigilo** permanece disponível mas não é obrigatória.

---

### User Story 7 - Consulta de andamento por protocolo (Priority: P2)

Como manifestante (ou servidor repassando informação), preciso que exista consulta de andamento por protocolo e chave de acesso, para acompanhar a demanda sem autenticação — mesmo que a interface pública de consulta seja entregue em fase futura.

**Why this priority**: Protocolo com chave de consulta foi definido como entrega desta spec; a API permite integração futura com canal público.

**Independent Test**: Pode ser testado consultando andamento informando protocolo e chave válidos (retorno com status e marcos) e combinação inválida (negação sem revelar existência indevida de dados).

**Acceptance Scenarios**:

1. **Given** manifestação registrada com protocolo `OUV-2026-0138` e chave de consulta gerada no envio, **When** consulta pública informa protocolo e chave corretos, **Then** retorna status operacional atual e marcos resumidos da timeline (sem dados sigilosos do manifestante).
2. **Given** protocolo inexistente ou chave incorreta, **When** consulta é realizada, **Then** retorna mensagem genérica de não encontrado — sem expor se o protocolo existe com chave errada.
3. **Given** manifestação com sigilo ativo, **When** consulta pública por protocolo+chave, **Then** retorna apenas andamento e status — nunca identificação do manifestante.

---

### Edge Cases

- Envio simultâneo de duas manifestações no mesmo tenant: cada uma recebe protocolo único sem colisão de sequência.
- Anexo removido antes da confirmação na etapa de revisão: não persiste após envio cancelado ou retorno ao formulário.
- Manifestação anônima com sigilo desligado: relato e metadados operacionais visíveis; ausência de manifestante indicada explicitamente no detalhe.
- Edição de manifestação já tramitada: apenas campos operacionais permitidos pela política do tenant (padrão: bloquear edição de relato após primeiro encaminhamento; permitir notas na timeline).
- Prazo de resposta no passado na criação: sistema alerta servidor mas permite registro com confirmação.
- Usuário perde permissão de setor durante sessão: próxima operação no módulo retorna 403.
- Consulta por protocolo com rate limiting abusivo: respostas degradadas sem vazamento de informação.
- Município não informado: manifestação válida; campo local do fato permanece opcional.
- Manifestação origem *Pública* registrada internamente (servidor lança demanda recebida por outro canal): origem e canal de entrada refletem fonte real.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: O sistema MUST permitir a servidores autenticados com permissão no módulo Ouvidoria registrar manifestações com campos obrigatórios: **Relato**, **Tipo**, **Esfera**, **Assunto**, **Origem** (*Interna* ou *Pública*), **Canal de entrada** e **Prazo de resposta**.
- **FR-002**: O sistema MUST restringir **Tipo** ao conjunto fechado: Reclamação, Solicitação, Denúncia, Elogio, Sugestão, Simplifique.
- **FR-003**: O sistema MUST restringir **Esfera** ao conjunto fechado: Federal, Estadual, Municipal, Serviços Autónomos ou Conselhos Profissionais, Judiciário Federal.
- **FR-004**: O sistema MUST implementar fluxo de registro em etapas: dados da manifestação → anexos → revisão → confirmação, com copy de revisão *"Revise os dados da sua manifestação. Caso queira alterar algum campo, retorne ao formulário."*
- **FR-005**: O sistema MUST permitir identificação **opcional** do manifestante (nome, documento, contato); ausência de todos os campos registra manifestação anônima.
- **FR-006**: O sistema MUST associar local do fato opcionalmente via entidade **Address** centralizada da plataforma, escopo tenant — incluindo município selecionável e descrição livre do local; módulos MUST NOT duplicar estrutura completa de endereço em tabelas próprias.
- **FR-007**: O sistema MUST aceitar anexos nos formatos: `.pdf`, `.doc`, `.docx`, `.txt`, `.jpeg`, `.jpg`, `.png`, `.bmp`, `.xls`, `.xlsx`, `.mp3`, `.mp4`, com limite de 30 MB por arquivo.
- **FR-008**: O sistema MUST rejeitar anexos fora dos tipos ou acima do limite com mensagem clara antes da confirmação do registro.
- **FR-009**: O sistema MUST gerar protocolo único por manifestação no envio confirmado, formato legível institucional (ex.: `OUV-AAAA-NNNN`), e chave de consulta associada.
- **FR-010**: O sistema MUST exibir lista de manifestações com colunas Protocolo, Tipo, Status, Prazo e Origem, e filtros por tipo, status operacional, prazo e origem.
- **FR-011**: O sistema MUST exibir detalhe com dados do registro, anexos, manifestante (quando permitido), local do fato e timeline de eventos.
- **FR-012**: O sistema MUST permitir ações operacionais **Encaminhar**, **Responder** e **Encerrar** no detalhe, registrando cada ação na timeline com autor, data e descrição.
- **FR-013**: O sistema MUST manter status operacionais da Base em conjunto fechado distinto de conformidade de fiscalização: *Em análise*, *Tramitando*, *Crítico*, *Vencendo*, *Encerrado* (e estados derivados de resposta emitida conforme operação).
- **FR-014**: O sistema MUST calcular e exibir *Crítico* ou *Vencendo* com base no campo **Prazo de resposta** e data corrente — responsabilidade operacional da Base, não de licenças analíticas.
- **FR-015**: O sistema MUST aplicar permissão por setor ao módulo Ouvidoria conforme regras de vínculo módulo–setor existentes, incluindo tela 403 padronizada para acesso negado.
- **FR-016**: O sistema MUST oferecer flag opcional **Sigilo** em manifestações; quando ativa, ocultar PII do manifestante para usuários sem permissão de ouvidor/sigilo.
- **FR-017**: O sistema MUST disponibilizar consulta de andamento por protocolo e chave **sem autenticação**, retornando status e marcos resumidos — sem expor PII em manifestações sigilosas.
- **FR-018**: O sistema MUST isolar manifestações, endereços e anexos por tenant — nenhum dado de um tenant acessível por outro.
- **FR-019**: O sistema MUST NOT incluir nesta entrega: SPA público de envio, interface pública de consulta, dashboards Carvalho, modelos Pau-Brasil, fiscalização Jatobá, insights Cedro, migração de dados legados.
- **FR-020**: O sistema MUST permitir editar manifestação em rascunho ou antes do primeiro encaminhamento; após encaminhamento, edição de relato e campos substantivos MUST ser bloqueada (notas via timeline permanecem permitidas).

### Key Entities

- **Manifestação**: Registro central da ouvidoria; contém relato, tipo, esfera, assunto, origem, canal, prazo, status operacional, flag sigilo, referência opcional a manifestante e endereço do fato, protocolo e chave de consulta.
- **Address**: Endereço normalizado **global da plataforma**, escopo tenant; reutilizável por Ouvidoria e demais módulos via referência; atributos incluem município, logradouro, complemento, CEP, descrição livre do local e demais campos padronizados definidos na modelagem — sem duplicação por módulo.
- **Manifestante**: Dados opcionais de identificação (nome, documento, e-mail, telefone); ausência total indica manifestação anônima.
- **Anexo**: Metadados de arquivo complementar (nome, tipo, tamanho, referência ao conteúdo armazenado); vinculado à manifestação.
- **Protocolo**: Identificador institucional único legível (`OUV-AAAA-NNNN`) gerado na confirmação; imutável após criação.
- **Chave de consulta**: Código secundário gerado com o protocolo para consulta pública de andamento sem login.
- **Evento de timeline**: Marco auditável (registro, encaminhamento, resposta, encerramento, observação) com timestamp, autor e descrição.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Servidor consegue registrar manifestação completa (dados, anexos, revisão) em menos de 5 minutos em testes de aceitação com usuário treinado.
- **SC-002**: 100% dos envios confirmados recebem protocolo único — zero colisões em testes de carga moderada (centenas de registros simultâneos por tenant).
- **SC-003**: 100% dos anexos inválidos (tipo ou tamanho) são rejeitados antes da confirmação, com mensagem compreensível em testes de aceitação.
- **SC-004**: Equipe localiza manifestação por protocolo ou filtros na lista em menos de 30 segundos em 95% dos casos medidos em testes de aceitação.
- **SC-005**: Consulta por protocolo e chave válidos retorna andamento em menos de 3 segundos do ponto de vista do manifestante em condições normais de operação.
- **SC-006**: Manifestações com sigilo ativo não expõem PII do manifestante em nenhum teste de aceitação com perfil sem permissão de ouvidor/sigilo.
- **SC-007**: Zero casos em testes de aceitação em que usuário de tenant A visualiza manifestações, endereços ou anexos de tenant B.

## Assumptions

- Escopo limitado à **licença Base** do módulo Ouvidoria: CRUD, tramitação, resposta, encerramento e timeline. Demais licenças (Carvalho, Pau-Brasil, Jatobá, Cedro) permanecem fora desta spec.
- SPA público de envio de manifestações e interface pública de consulta serão tratados em spec futura; esta entrega inclui registro interno e **API de consulta** de andamento.
- Catálogo de municípios provém de base institucional ou referência geográfica nacional gerenciada por tenant; detalhe de origem dos dados fica para fase de plano.
- Armazenamento de arquivos anexos utiliza serviço externo de object storage gerenciado pela plataforma; manifestação persiste apenas metadados e referência ao conteúdo.
- Permissão de módulo segue spec **002-auth-setor-permissao**; Ouvidoria é módulo de negócio sujeito a vínculo setor–módulo.
- Perfis com permissão de ouvidor/sigilo incluem servidores lotados no setor Ouvidoria e administrador da plataforma do tenant; detalhamento de papel fica para plano de implementação.
- Canais de entrada padrão: Presencial, Telefone, E-mail, Portal — alinhado ao produto existente; extensível pelo tenant em fase futura.
- Reabertura de manifestação encerrada e workflow automatizado de aprovação estão fora de escopo.
- Copy de interface segue vocabulário normativo: módulo **Ouvidoria**, status operacionais da Base (§7 regras-plataforma), **403 · Acesso negado** quando aplicável.
- Implementação legada em `controle-interno-api` serve apenas como referência conceitual; **nenhuma migração ou refatoração** de sistemas antigos faz parte desta feature.
- Entidade **Address** passa a integrar o vocabulário canônico da plataforma (CONTEXT e specs subsequentes referenciam endereço centralizado por tenant).
