# Feature Specification: Desmock Gabinete — Demandas, Protocolos e Licenças

**Feature Branch**: `012-desmock-gabinete`

**Created**: 2026-06-23

**Status**: Draft

**Input**: User description: "Desmock do módulo Gabinete do Presidente (`/gabinete`). Substituir mocks por dados reais multi-tenant. Entidade central: Demanda (ata). Vincular Protocolo opcional, controles opcionais (Controle Numérico, Notificações, Autos de Infração, Documentos Tramitados por Setor), anexos via armazenamento de objetos, stub de tramitação local, Dashboard Executivo e licenças Cedro (Insights), Jatobá (Fiscalização) e Carvalho (Maturidade). Campos herdados da v1 permanecem opcionais. Documentos Tramitados unificados por Setor — não replicar tabelas legadas por sigla de setor."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Registrar demanda (ata) com protocolo e anexos (Priority: P1)

Como servidor autenticado com acesso ao módulo Gabinete, preciso registrar uma **Demanda** — registro operacional central do Gabinete, também referido como *ata* — informando assunto e descrição, opcionalmente vinculando um **Protocolo** de entrada e anexando documentos, para formalizar a demanda com número rastreável e evidências associadas.

**Why this priority**: Sem registro estruturado de demanda e protocolo, não existe fila operacional nem base para controles, fiscalização ou insights.

**Independent Test**: Autenticar usuário do setor Gabinete, preencher formulário de nova demanda com dados mínimos (assunto + descrição), opcionalmente informar campos de protocolo e anexar arquivo válido; confirmar e verificar demanda na lista com número de protocolo único gerado.

**Acceptance Scenarios**:

1. **Given** servidor com permissão no módulo Gabinete, **When** preenche **Assunto** e **Descrição** (campos obrigatórios) e confirma o registro, **Then** o sistema cria a demanda com **Número de protocolo** único no tenant e exibe confirmação com identificador rastreável.
2. **Given** formulário de nova demanda, **When** o servidor informa campos opcionais de **Protocolo** (número interno, número SIGED, forma de entrada, remetente, data/hora de recebimento, assunto, tipo de documento, descrição resumida), **Then** protocolo é vinculado à demanda — **nenhum** campo de protocolo é obrigatório para concluir o registro.
3. **Given** etapa ou seção de anexos, **When** o servidor adiciona arquivo nos formatos aceitos (documentos, imagens, planilhas e multimídia), **Then** cada arquivo é listado com nome e tamanho; arquivos acima de 30 MB ou tipo não permitido são rejeitados com mensagem clara.
4. **Given** demanda confirmada com anexos, **When** a equipe abre o detalhe, **Then** consegue visualizar ou baixar cada anexo associado à demanda ou ao protocolo vinculado.
5. **Given** campos opcionais de fluxo (origem, setor atual, status, prazos), **When** não informados no cadastro, **Then** o sistema aplica valores padrão institucionais (ex.: setor Gabinete, status inicial de rascunho ou recebido conforme política do tenant) — **sem** bloquear o registro.

---

### User Story 2 - Listar e filtrar demandas do Gabinete (Priority: P1)

Como servidor do Gabinete, preciso consultar a lista de demandas com filtros e busca, para priorizar atendimentos e localizar registros por protocolo, assunto ou status.

**Why this priority**: A operação diária depende da fila visível substituindo linhas de demonstração fixas.

**Independent Test**: Registrar demandas em estados distintos, aplicar filtros na lista em `/gabinete/demandas` e verificar colunas e resultados coerentes com dados reais do tenant.

**Acceptance Scenarios**:

1. **Given** demandas registradas no tenant, **When** o servidor abre **Lista de Demandas** (`/gabinete/demandas`), **Then** vê colunas operacionais incluindo **Número de protocolo**, **Assunto**, **Status**, **Setor atual** e **Data de entrada**, com filtros por status, origem, setor e prazo quando aplicável.
2. **Given** busca por número de protocolo, **When** o servidor informa identificador existente, **Then** localiza o registro correspondente em no máximo uma interação adicional.
3. **Given** demanda com prazo operacional próximo ou vencido, **When** exibida na lista, **Then** status operacional reflete situação (*Pendente*, *Em análise*, *Crítico*, *Vencendo*, etc.) conforme regras da Base — **sem** misturar com conformidade Jatobá.
4. **Given** tenant sem demandas, **When** a lista carrega, **Then** exibe estado vazio orientando criação da primeira demanda — **sem** linhas fictícias de demonstração.

---

### User Story 3 - Detalhe, edição e linha do tempo da demanda (Priority: P1)

Como servidor do Gabinete, preciso abrir o detalhe de uma demanda, editar campos permitidos, visualizar protocolo vinculado, encaminhamentos, anexos e abas de controles opcionais, para acompanhar o ciclo completo do registro.

**Why this priority**: O detalhe concentra protocolo, controles e histórico — núcleo da operação além da lista.

**Independent Test**: Abrir detalhe de demanda existente em `/gabinete/demandas/:id`; verificar seções de protocolo, timeline, anexos e abas de controles; editar campo permitido e confirmar persistência.

**Acceptance Scenarios**:

1. **Given** demanda existente, **When** o servidor abre o detalhe, **Then** vê dados completos da demanda, protocolo vinculado (quando houver), anexos e **linha do tempo** de eventos (registro, encaminhamentos, alterações de status).
2. **Given** demanda em edição, **When** o servidor altera campos editáveis e salva, **Then** alterações persistem com registro de autor e data na linha do tempo — respeitando campos somente leitura após estados finais quando aplicável.
3. **Given** demanda com controles vinculados, **When** o detalhe carrega, **Then** exibe abas ou seções para **Controle Numérico**, **Notificações**, **Autos de Infração** e **Documentos Tramitados** — cada uma listando registros reais vinculados ou estado vazio orientador.
4. **Given** copy da tela, **When** o servidor lê o cabeçalho, **Then** vê vocabulário **Demanda** / **Gabinete** — **não** rótulos de demonstração de atos normativos fictícios (Portaria/Resolução mock).

---

### User Story 4 - Tramitar demanda (stub local) (Priority: P1)

Como servidor do Gabinete, preciso encaminhar uma demanda a outro setor registrando observação e destino, para registrar intenção de tramitação interna **sem** integrar o módulo Tramitação (ainda inexistente).

**Why this priority**: Fluxo operacional básico de encaminhamento foi solicitado; stub local preserva valor até módulo Tramitação existir.

**Independent Test**: Abrir detalhe de demanda, acionar **Tramitar**, informar setor destino e observação; verificar evento no histórico de encaminhamentos e ausência de registro no módulo Tramitação.

**Acceptance Scenarios**:

1. **Given** demanda em status operacional que permite encaminhamento, **When** o servidor aciona **Tramitar** informando setor destino e observação, **Then** evento é registrado no histórico de encaminhamentos com setor, usuário, data e observação.
2. **Given** encaminhamento registrado, **When** o detalhe é reaberto, **Then** linha do tempo exibe o encaminhamento — status operacional da demanda reflete tramitação interna (ex.: *Em trâmite*) conforme regras da Base.
3. **Given** ação **Tramitar**, **When** executada, **Then** **nenhum** registro é criado ou alterado no módulo Tramitação — copy deixa claro que tramitação inter-setorial completa será entregue em feature futura.
4. **Given** tentativa de tramitar sem setor destino, **When** o servidor confirma, **Then** sistema solicita setor destino — **não** persiste encaminhamento incompleto.

---

### User Story 5 - Acesso ao módulo conforme setor e licença Base (Priority: P1)

Como usuário autenticado, preciso acessar rotas do Gabinete apenas quando meu setor estiver autorizado ao módulo, para respeitar governança organizacional da plataforma.

**Why this priority**: Gabinete é módulo de negócio sujeito a permissão por setor; operação depende dessa regra.

**Independent Test**: Usuário lotado no setor Gabinete acessa rotas normalmente; usuário de setor não vinculado recebe 403 padronizado.

**Acceptance Scenarios**:

1. **Given** módulo Gabinete vinculado ao setor Gabinete, **When** usuário lotado nesse setor navega ao módulo, **Then** acessa lista, registro e detalhe normalmente.
2. **Given** usuário sem setor autorizado, **When** tenta acessar rota interna do Gabinete, **Then** recebe **403 · Acesso negado** com copy padronizada — item pode permanecer visível na navegação.
3. **Given** administrador da plataforma do tenant, **When** acessa Gabinete, **Then** tem acesso irrestrito independentemente de lotação.

---

### User Story 6 - Gerenciar Controle Numérico vinculado (Priority: P1)

Como servidor do Gabinete, preciso cadastrar e editar registros de **Controle Numérico** (ofício, ofício circular, portaria, memorando, memorando circular, resolução) vinculados opcionalmente a uma demanda ou protocolo, para substituir controle antes feito em planilha.

**Why this priority**: Controle Numérico é um dos três blocos de controles opcionais solicitados; campos v1 devem estar disponíveis no detalhe da demanda.

**Independent Test**: No detalhe de demanda, criar registro de Controle Numérico com tipo *Portaria* e campos opcionais; listar, editar e excluir (soft delete) verificando vínculo com a demanda.

**Acceptance Scenarios**:

1. **Given** detalhe de demanda, **When** o servidor aciona **Novo controle numérico** e seleciona tipo documental (ofício, ofício circular, portaria, memorando, memorando circular, resolução), **Then** formulário exibe campos opcionais conforme tipo (número, data, órgão, endereçado, histórico, assunto, solicitante, formalizado por, minutado por — conforme aplicável ao tipo).
2. **Given** controle numérico salvo, **When** listado na aba correspondente, **Then** exibe tipo, número e data quando informados — vinculado à demanda e/ou protocolo.
3. **Given** múltiplos controles do mesmo tipo, **When** agrupados por identificador de grupo opcional, **Then** interface permite associar registros relacionados ao mesmo fluxo documental — **sem** exigir preenchimento do agrupador.
4. **Given** qualquer campo de controle numérico, **When** deixado em branco, **Then** registro é aceito — espelhando regra v1 de campos opcionais.

---

### User Story 7 - Gerenciar Notificações e Autos de Infração (Priority: P1)

Como servidor do Gabinete, preciso cadastrar registros de **Notificação** e **Auto de Infração** vinculados opcionalmente a demanda ou protocolo, para controlar termos, destinatários, prazos e situações conforme planilhas institucionais.

**Why this priority**: Par notificação/auto é controle operacional crítico do Gabinete AGEMAN; deve ser persistido e consultável no detalhe.

**Independent Test**: Criar notificação vinculada à demanda com campos opcionais (termo, destinatário, prazo, situação); criar auto de infração no mesmo grupo; verificar listagem e edição.

**Acceptance Scenarios**:

1. **Given** detalhe de demanda, **When** o servidor cadastra **Notificação** com campos opcionais (ordem, termo, destinatário, emitido por, relatório/parecer técnico, fato gerador, processo, datas, prazo, vencimento, resposta, situação), **Then** registro persiste vinculado à demanda e/ou protocolo.
2. **Given** notificação existente, **When** o servidor cadastra **Auto de Infração** associado (mesmo grupo opcional), **Then** auto persiste com campos opcionais (documento, destinatário, setor emissor, parecer/despacho, assunto, valor, processo, número de protocolo, prazo, vencimento, resposta).
3. **Given** registros de notificação e auto, **When** listados na aba de controles, **Then** exibem situação e prazos quando informados — **sem** alterar status operacional da demanda na Base.
4. **Given** exclusão lógica de registro de controle, **When** confirmada, **Then** registro deixa de aparecer na listagem ativa — histórico de auditoria preservado conforme política de soft delete da plataforma.

---

### User Story 8 - Gerenciar Documentos Tramitados por Setor (Priority: P1)

Como servidor do Gabinete, preciso registrar **Documentos Tramitados** vinculados a uma demanda ou protocolo e a um **Setor** cadastrado, para controlar tramitação documental por unidade **sem** replicar tabelas legadas por sigla de setor (DEGPLAN, DEAE, etc.).

**Why this priority**: Unificação por Setor é decisão arquitetural v2; substitui débito técnico da v1 e alimenta detalhe da demanda.

**Independent Test**: Criar documento tramitado informando setor obrigatório e campos opcionais comuns; verificar listagem filtrada por setor no detalhe da demanda.

**Acceptance Scenarios**:

1. **Given** detalhe de demanda, **When** o servidor cadastra **Documento Tramitado** selecionando **Setor** (obrigatório) e preenchendo campos opcionais (quantidade, data de protocolo, número/tipo de protocolo, número SIGED, data de despacho, documento, requerente, assunto, prazo ou observação), **Then** registro persiste vinculado à demanda e/ou protocolo e ao setor escolhido.
2. **Given** documentos tramitados de setores distintos, **When** listados na aba correspondente, **Then** interface exibe setor (nome ou sigla) de cada registro — **nunca** rótulo de tabela legada v1.
3. **Given** identificador de grupo opcional para documento tramitado, **When** informado em múltiplos registros, **Then** interface pode agrupar linhas que representam o mesmo documento em contextos distintos — **sem** FK rígida entre registros.
4. **Given** setor inexistente ou deletado, **When** tentativa de vínculo, **Then** sistema impede associação inválida com mensagem clara.

---

### User Story 9 - Dashboard Executivo com KPIs reais (Priority: P1)

Como gestor do Gabinete, preciso consultar o **Dashboard Executivo** (`/gabinete/dashboard`) com indicadores derivados das demandas reais do tenant — volume, status, pendências e andamento — para visão macro sem dados fictícios.

**Why this priority**: Dashboard substitui cards mock (*86 atos*, *72% publicados*) por valor operacional imediato.

**Independent Test**: Popular tenant com demandas em status distintos; abrir dashboard e verificar KPIs e gráficos coerentes com contagens reais.

**Acceptance Scenarios**:

1. **Given** demandas registradas no tenant no período analisado, **When** o servidor abre `/gabinete/dashboard`, **Then** vê cards operacionais (ex.: total no período, em análise, finalizadas, pendências) calculados a partir dos registros — **não** valores fixos de demonstração.
2. **Given** mix de status de fluxo, **When** o dashboard exibe distribuição, **Then** gráficos ou indicadores refletem proporções reais por status.
3. **Given** tenant sem demandas confirmadas, **When** o dashboard carrega, **Then** exibe estado vazio ou zeros explícitos — **sem** inventar tendências.
4. **Given** regras de prazo da Base, **When** há demandas com prazo crítico ou vencido, **Then** dashboard destaca volume de pendências operacionais — responsabilidade da Base, não de Carvalho ou Cedro.

---

### User Story 10 - Fiscalizar demandas com Jatobá (Priority: P1)

Como servidor responsável pelo controle interno, preciso fiscalizar demandas do Gabinete quanto a prazos, completude de cadastro, encaminhamentos e controles vinculados, via painel **Fiscalização** (`/gabinete/auditoria`), para identificar não conformidades registro a registro **sem** alterar os dados operacionais.

**Why this priority**: Jatobá é camada de conformidade; Gabinete sem fiscalização real não demonstra valor de controle interno institucional.

**Independent Test**: Popular tenant com demandas em estados distintos; abrir `/gabinete/auditoria`; executar fiscalização e verificar checagens com status ∈ {Conforme, Não conforme, Parcial, Pendente} e sheet *Por que esta checagem deu este resultado*.

**Acceptance Scenarios**:

1. **Given** usuário com permissão no módulo Gabinete, **When** acessa `/gabinete/auditoria`, **Then** vê **Painel de Fiscalização — Gabinete** com badge **Somente leitura** e copy que deixa claro que Jatobá sinaliza achados — **não** altera demandas.
2. **Given** demandas confirmadas no tenant, **When** fiscalização executa checagens automáticas (prazo, completude de campos críticos, encaminhamento pendente, controles obrigatórios por política do tenant), **Then** cada demanda recebe conformidade agregada nos quatro status canônicos — prevalecendo o pior status entre checagens.
3. **Given** execução de fiscalização, **When** concluída, **Then** resultados persistem com data, origem (agendada, sob demanda) e histórico consultável — padrão institucional alinhado à Ouvidoria.
4. **Given** resultado de checagem, **When** o usuário aciona rastreio, **Then** abre sheet com título **Por que esta checagem deu este resultado** — **sem** rota dedicada de rastreio.
5. **Given** questionário Jatobá no módulo Gabinete, **When** disponível, **Then** respondente é **somente interno** — conforme configuração canônica do módulo (sem canal externo WhatsApp).

---

### User Story 11 - Maturidade Carvalho do Gabinete (Priority: P1)

Como gestor de controle interno, preciso consultar **Maturidade** (`/gabinete/maturidade`) com score híbrido real nos três eixos (Controle Interno, Governança, Tecnologia da Informação), autoavaliação da equipe e indicadores operacionais do Gabinete, para diagnóstico institucional sem alterar demandas.

**Why this priority**: Carvalho entrega valor de maturidade macro; tela hoje exibe mocks estáticos.

**Independent Test**: Responder autoavaliação do período vigente; executar fiscalização Jatobá; abrir maturidade e verificar score por eixo = `round(0,6 × autoavaliação + 0,4 × conformidade Jatobá)` e badge **Somente leitura**.

**Acceptance Scenarios**:

1. **Given** usuário autorizado, **When** acessa `/gabinete/maturidade`, **Then** vê **Maturidade — Gabinete** com nota geral e três eixos calculados — **não** percentuais fixos de demonstração.
2. **Given** autoavaliação respondida e dados Jatobá disponíveis, **When** score por eixo é calculado, **Then** aplica fórmula híbrida institucional (60% autoavaliação + 40% conformidade Jatobá), arredondada 0–100.
3. **Given** autoavaliação **não** respondida no período vigente, **When** score é solicitado, **Then** nota do eixo aparece como **indisponível** — **nunca** fabricada só com Jatobá.
4. **Given** score geral abaixo de 70%, **When** exibido, **Then** alerta **Crítico**; entre 70% e 80% **Atenção**; ≥ 80% sem alerta de maturidade.
5. **Given** ação *Como calculamos este score?*, **When** acionada, **Then** abre sheet **Como calculamos este score** explicando fontes em linguagem clara.

---

### User Story 12 - Insights Cedro estratégicos do Gabinete (Priority: P1)

Como gestor institucional, preciso consultar **Insights IA** (`/gabinete/insights`) com análises consultivas Cedro derivadas dos dados internos de demandas, protocolos e controles do Gabinete, para orientar decisões estratégicas **sem** alterar registros operacionais.

**Why this priority**: Cedro completa a tríade de licenças solicitada no desmock; foco canônico: *Insights estratégicos institucionais*.

**Independent Test**: Popular tenant com demandas e controles; abrir `/gabinete/insights`; verificar insights com fonte *Dados internos — Gabinete*, impacto, recomendação consultiva, badge **Somente leitura** e rastreio *De onde veio este insight?*.

**Acceptance Scenarios**:

1. **Given** usuário autorizado, **When** acessa `/gabinete/insights`, **Then** vê painel Cedro com insights da geração mais recente — **não** cards fixos de demonstração.
2. **Given** demandas e controles no tenant, **When** insights são gerados, **Then** incluem agregações operacionais (volume por status, gargalos de encaminhamento, concentração por origem) e consultivas estratégicas (ex.: volume de notificações/autos, tendência de documentos tramitados por setor).
3. **Given** insight exibido, **When** o usuário aciona *De onde veio este insight?*, **Then** abre sheet inferior com rastreabilidade — **sem** prometer alteração automática de dados.
4. **Given** geração híbrida (agenda + recálculo sob demanda), **When** usuário aciona ação equivalente a *Consultar IA*, **Then** nova execução é persistida com histórico consultável — padrão alinhado à Ouvidoria Cedro.

---

### Edge Cases

- Demanda criada sem protocolo vinculado: protocolo pode ser associado posteriormente no detalhe; número de protocolo da demanda permanece único no tenant.
- Múltiplas demandas vinculadas ao mesmo protocolo: permitido (relação v1 — um protocolo pode originar várias demandas).
- Anexo órfão após falha de confirmação: metadados não confirmados não aparecem no detalhe; limpeza periódica de objetos não referenciados (política operacional padrão).
- Tramitar para setor igual ao setor atual: sistema registra encaminhamento com confirmação explícita ou aviso — não bloqueia silenciosamente.
- Controles com todos os campos vazios exceto vínculo: registro aceito; fiscalização Jatobá pode sinalizar incompletude como achado — **sem** impedir salvamento na Base.
- Tenant sem licença Cedro/Jatobá/Carvalho ativa: rotas de licença respeitam contrato de produto (403 ou estado orientador conforme regra existente da plataforma).
- Documento tramitado sem demanda mas com protocolo: permitido quando apenas protocolo informado.
- Exclusão lógica de demanda com controles vinculados: controles permanecem consultáveis em contexto de auditoria ou ocultos conforme política de soft delete do tenant (padrão: ocultar da operação ativa).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Sistema **DEVE** permitir que servidor autorizado crie **Demanda** informando **Assunto** e **Descrição** como únicos campos obrigatórios de cadastro.
- **FR-002**: Sistema **DEVE** gerar **Número de protocolo** único por tenant para cada Demanda confirmada.
- **FR-003**: Sistema **DEVE** permitir vincular **Protocolo** à Demanda no mesmo fluxo de criação ou posteriormente no detalhe; todos os demais campos de Protocolo **DEVEM** ser opcionais.
- **FR-004**: Sistema **DEVE** suportar anexos em Demanda e Protocolo via upload direto a armazenamento de objetos institucional; limite **30 MB** por arquivo; tipos aceitos alinhados ao módulo Ouvidoria (documentos, imagens, planilhas, multimídia).
- **FR-005**: Sistema **DEVE** listar demandas em `/gabinete/demandas` com filtros por status de fluxo, origem, setor atual e busca por número de protocolo ou assunto.
- **FR-006**: Sistema **DEVE** exibir detalhe da demanda com linha do tempo, protocolo vinculado, anexos e abas de controles opcionais.
- **FR-007**: Ação **Tramitar** **DEVE** registrar encaminhamento (setor destino, usuário, data, observação) no histórico da demanda **SEM** criar ou alterar registros no módulo Tramitação.
- **FR-008**: Sistema **DEVE** expor CRUD de **Controle Numérico** vinculado a demanda e/ou protocolo, com tipo documental ∈ {ofício, ofício circular, portaria, memorando, memorando circular, resolução} e campos opcionais por tipo.
- **FR-009**: Sistema **DEVE** expor CRUD de **Notificação** e **Auto de Infração** vinculados a demanda e/ou protocolo, com agrupador opcional entre notificação e auto do mesmo caso.
- **FR-010**: Sistema **DEVE** expor CRUD de **Documento Tramitado** com **Setor** obrigatório e campos opcionais unificados — **NUNCA** modelo separado por sigla legada v1.
- **FR-011**: Dashboard Executivo **DEVE** calcular KPIs exclusivamente a partir de demandas (e controles quando aplicável) do tenant autenticado.
- **FR-012**: Fiscalização Jatobá **DEVE** executar checagens automáticas sobre demandas reais, persistir execuções e classificar conformidade ∈ {Conforme, Não conforme, Parcial, Pendente}; **NUNCA** alterar dados operacionais da demanda.
- **FR-013**: Maturidade Carvalho **DEVE** calcular score híbrido por eixo conforme fórmula institucional (60% autoavaliação + 40% conformidade Jatobá); **NUNCA** alterar demandas.
- **FR-014**: Insights Cedro **DEVEM** ser derivados de agregações determinísticas sobre demandas, protocolos e controles do tenant; **NUNCA** alterar registros; **NUNCA** substituir classificação Jatobá.
- **FR-015**: Rotas do Gabinete **DEVEM** respeitar permissão por setor e licença conforme governança existente da plataforma.
- **FR-016**: Interface **DEVE** migrar vocabulário e rotas de *Atos normativos* mock (`/gabinete/atos/*`) para **Demandas** (`/gabinete/demandas/*`).
- **FR-017**: Soft delete **DEVE** aplicar-se a demandas, protocolos e controles conforme padrão multi-tenant da plataforma.
- **FR-018**: Badge **Somente leitura** **DEVE** aparecer em telas Cedro, Jatobá (fiscalização) e Carvalho (score) do Gabinete.

### Key Entities

- **Demanda (ata)**: Registro operacional central do Gabinete. Atributos principais: número de protocolo (gerado), assunto, descrição, origem, setor atual, status de fluxo, datas de entrada e prazos, histórico de encaminhamentos, referência opcional a manifestação ou protocolo virtual de origem, vínculo opcional a Protocolo. Relaciona-se com todos os controles opcionais.

- **Protocolo**: Documento protocolado de entrada, vinculável a uma ou mais demandas. Atributos opcionais: número interno Gabinete, número SIGED, forma de entrada (presencial, e-mail, SIGED), remetente, data/hora de recebimento, assunto, tipo de documento, descrição resumida. Anexos via armazenamento de objetos.

- **Documento Tramitado**: Registro unificado de documento em tramitação por **Setor**. Atributos opcionais: quantidade, datas, números/tipos de protocolo, número SIGED, despacho, texto do documento, requerente, assunto, prazo ou observação; agrupador opcional para linhas relacionadas. Setor é obrigatório.

- **Controle Numérico**: Registro de numeração documental por tipo (ofício, ofício circular, portaria, memorando, memorando circular, resolução). Campos opcionais variam por tipo (número, data, órgão, endereçado, histórico, assunto, solicitante, formalizado por, minutado por). Agrupador opcional entre registros do mesmo fluxo.

- **Controle Notificação**: Registro de termo de notificação vinculado a demanda/protocolo. Campos opcionais: ordem, termo, destinatário, emitido por, parecer técnico, fato gerador, processo, datas, prazo, vencimento, resposta, situação.

- **Controle Auto de Infração**: Registro de auto vinculado a demanda/protocolo, associável a notificação via agrupador. Campos opcionais: documento, destinatário, setor emissor, parecer, assunto, valor, processo, prazos, resposta.

- **Anexo**: Metadado de arquivo (nome, tamanho, tipo, data) vinculado a Demanda ou Protocolo; binário em armazenamento de objetos externo ao registro transacional.

- **Encaminhamento**: Entrada no histórico da demanda — setor destino, usuário, data, observações — produzida pela ação Tramitar (stub).

- **Setor**: Unidade organizacional cadastrada no tenant (nome, sigla); referência obrigatória em Documento Tramitado e destino em encaminhamentos.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Servidor autorizado completa registro de demanda com protocolo opcional e pelo menos um anexo em **≤ 5 minutos** em teste de usabilidade guiado.
- **SC-002**: **100%** das telas listadas (`/gabinete/dashboard`, `/gabinete/demandas`, `/gabinete/demandas/novo`, `/gabinete/demandas/:id`, `/gabinete/auditoria`, `/gabinete/maturidade`, `/gabinete/insights`) exibem dados do tenant autenticado — **zero** linhas ou cards de demonstração fixa após conclusão da feature.
- **SC-003**: Fiscalização Jatobá classifica **≥ 1** demanda real com checagens automáticas persistidas e histórico consultável de execução.
- **SC-004**: Score Carvalho por eixo reflete fórmula híbrida verificável quando autoavaliação e Jatobá estão disponíveis — desvio de cálculo **0** em teste de aceitação documentado.
- **SC-005**: **≥ 3** insights Cedro distintos são gerados a partir de tenant com **≥ 10** demandas em estados variados, cada um com rastreio consultável.
- **SC-006**: Ação **Tramitar** registra encaminhamento visível na linha do tempo em **≤ 3 segundos** percebidos pelo usuário, sem efeito colateral no módulo Tramitação.
- **SC-007**: **95%** dos servidores de teste localizam demanda por número de protocolo na primeira busca, em cenário com até 500 registros no tenant.

## Assumptions

- **Demanda = ata**: Vocabulário de negócio unificado; interface adota *Demanda* como rótulo principal, podendo mencionar *ata* em copy de ajuda quando útil ao usuário AGEMAN.
- **Campos opcionais**: Herança da v1 — controle antes em planilha; apenas assunto e descrição são obrigatórios na Demanda; Setor é obrigatório apenas em Documento Tramitado.
- **Simplificação v2**: Documentos Tramitados unificados por Setor; Controle Numérico unificado por tipo documental; agrupadores (`documentoTramitadoGrupoId`, `notificacaoAutosGrupoId`, `controleNumericoGrupoId`) preservados como UUIDs opcionais sem FK rígida.
- **Tramitação real**: Fora de escopo — módulo Tramitação (spec 005) permanece mock/independente; stub local grava apenas encaminhamentos na demanda.
- **Pau-Brasil**: Modelos de portaria/resolução e assinatura **não** entram nesta feature; item de navegação pode permanecer com comportamento existente até feature dedicada.
- **Migração de dados v1 → v2**: Fora de escopo; seed de demonstração para tenant Jacaranda será entregue na fase de implementação.
- **Consulta pública**: Fora de escopo.
- **Dependências**: Autenticação e permissão por setor (spec 002); entidade Setor existente; padrão de anexos e armazenamento de objetos do módulo Ouvidoria reutilizado ou extraído como serviço compartilhado.
- **Produto**: Definição canônica de Base do Gabinete em `licencas-canonicas.md` será atualizada na fase `/speckit-plan` de *atos normativos* para *demandas e protocolos* — alinhamento explícito com decisão do stakeholder.
- **Status de fluxo**: Enum de status herdado da v1 (rascunho, recebido, em análise, em trâmite, finalizado, arquivado, etc.) será preservado em essência; transições detalhadas definidas no plano técnico.
- **Integração Ouvidoria**: Demanda pode referenciar manifestação de origem via campos opcionais de módulo de origem — sem duplicar fluxo de Ouvidoria nesta feature.
