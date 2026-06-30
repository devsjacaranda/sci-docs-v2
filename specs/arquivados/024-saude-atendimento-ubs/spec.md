# Feature Specification: Módulo Saúde — Atendimento UBS / e-SUS

**Feature Branch**: `024-saude-atendimento-ubs`

**Created**: 2026-06-29

**Status**: Completed

**Arquivada**: 2026-06-29

**Input**: User description: "Contrato com prefeitura de Careiro da Várzea (AM). Módulo Saúde mock com DTOs modernos, CRUD das 6 dimensões da consulta (profissional/local, cidadão, atendimento, conteúdo clínico, procedimentos, medicamentos), controle interno (indicadores, conferência, tramitação, validação pública), relatórios de receitas e exames, fila de solicitações cidadão→UBS, cadastro de ~8 UBS, exportação no padrão e-SUS (FAI). Dados sintéticos — não consumir backup real. CRUD sob licença Base (sem nova licença-árvore)."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Registrar e consultar atendimentos na UBS (Priority: P1)

Como profissional de saúde ou servidor da secretaria municipal com licença **Base**, preciso listar, criar, editar e visualizar **consultas** na Atenção Primária, reunindo em um único registro as seis dimensões do atendimento (profissional e local, cidadão, dados do atendimento, conteúdo clínico, procedimentos e medicamentos/receitas), para operar o dia a dia da UBS sem depender do e-SUS enquanto a integração oficial tramita.

**Why this priority**: A consulta agregada é o núcleo operacional do módulo; sem ela não há valor para a prefeitura nem base para relatórios, conferência ou exportação.

**Independent Test**: Autenticar com licença Base; abrir lista de consultas; criar consulta preenchendo as seis dimensões com dados sintéticos; salvar; reabrir detalhe e verificar persistência em memória local; editar um campo clínico e confirmar atualização.

**Acceptance Scenarios**:

1. **Given** usuário autenticado com licença Base, **When** acessa o módulo Saúde, **Then** vê menu e telas de CRUD disponíveis — **sem** exigir licença adicional de árvore (Carvalho, Pau-Brasil, Jatobá ou Cedro).
2. **Given** formulário de nova consulta, **When** o profissional preenche identificação (profissional, UBS, equipe), cidadão, dados do atendimento (data, tipo, local, turno), conteúdo clínico (queixa, avaliação com CID ou CIAP, plano), procedimentos e itens de receita, **Then** o sistema persiste um registro único agregado consultável em detalhe.
3. **Given** consulta existente, **When** o usuário abre o detalhe, **Then** vê as seis dimensões organizadas de forma legível (ex.: abas ou seções) — profissional/local, cidadão, atendimento, clínico, procedimentos, medicamentos.
4. **Given** consulta existente, **When** o usuário edita campos permitidos e salva, **Then** alterações ficam disponíveis na listagem e no detalhe — **sem** perda das demais dimensões.
5. **Given** tentativa de salvar consulta sem campos obrigatórios mínimos (cidadão, profissional, UBS, data), **When** submete o formulário, **Then** recebe feedback claro indicando o que falta — **sem** gravar registro incompleto.

---

### User Story 2 - Cadastros de apoio: cidadãos, profissionais, UBS e medicamentos (Priority: P1)

Como servidor da secretaria, preciso manter cadastros de **cidadãos**, **profissionais**, **unidades de saúde (UBS)** e **medicamentos** de apoio, para vincular corretamente às consultas e relatórios do município de Careiro da Várzea.

**Why this priority**: Consultas e relatórios dependem de entidades mestras; as ~8 UBS do município são referência fixa para métricas e filtros.

**Independent Test**: Abrir cadastro de UBS; verificar ~8 unidades sintéticas de Careiro; criar cidadão e profissional; associar a uma consulta; confirmar exibição de CNES, CNS, CBO e demais identificadores nos detalhes.

**Acceptance Scenarios**:

1. **Given** tenant configurado para Careiro da Várzea, **When** o usuário abre Unidades (UBS), **Then** vê cadastro fixo de aproximadamente **8 UBS** com nome, CNES, equipe vinculada, horário de funcionamento e métricas agregadas resumidas (produção, consultas no período).
2. **Given** cadastro de cidadão, **When** criado ou editado, **Then** armazena identificadores essenciais (CNS ou CPF, nome, data de nascimento, sexo, contato) — dados **sintéticos**, nunca copiados do backup e-SUS real.
3. **Given** cadastro de profissional, **When** criado ou editado, **Then** armazena CNS, CBO, conselho de classe e vínculo com UBS/equipe.
4. **Given** cadastro de medicamento, **When** consultado na emissão de receita, **Then** exibe princípio ativo, concentração e forma farmacêutica para seleção na consulta.

---

### User Story 3 - Relatórios operacionais: receitas emitidas e exames solicitados (Priority: P2)

Como gestor da secretaria de saúde, preciso analisar **receitas emitidas** e **exames solicitados** em telas somente leitura, com filtros e agrupamentos, para acompanhar produção médica e demanda de complementares.

**Why this priority**: Volume conhecido (~400 receitas em 14 meses, ~100 solicitações de exame) sustenta demonstração contratual e validação de regras de negócio antes da integração e-SUS.

**Independent Test**: Abrir relatório de receitas; filtrar por médico e mês; verificar agrupamento; abrir relatório de exames; confirmar que apenas médicos aparecem como solicitantes e que cada item está marcado como rotina ou urgente.

**Acceptance Scenarios**:

1. **Given** base sintética com ~400 receitas distribuídas em ~14 meses, **When** o gestor abre o relatório de receitas emitidas, **Then** vê listagem **somente leitura** agrupável por médico, mês e período customizado.
2. **Given** receita no relatório, **When** o gestor expande ou abre detalhe resumido, **Then** vê medicamento, posologia, profissional prescritor, UBS e data — **sem** permitir edição nesta tela.
3. **Given** base sintética com ~100 solicitações de exame, **When** o gestor abre o relatório de exames solicitados, **Then** vê listagem **somente leitura** com procedimento, data, profissional solicitante e classificação **rotina** ou **urgente**.
4. **Given** relatório de exames, **When** exibido, **Then** solicitantes são **exclusivamente médicos** — enfermeiros **não** aparecem como solicitantes de exames complementares.
5. **Given** filtros aplicados sem resultados, **When** o gestor consulta, **Then** vê estado vazio informativo — **sem** erro genérico.

---

### User Story 4 - Fila de solicitações da população (cidadão → UBS) (Priority: P2)

Como servidor da recepção ou gestor de UBS, preciso gerenciar a **fila de solicitações** enviadas pela população à unidade (agendamento, medicamento, encaminhamento, etc.), editando status e observações, para organizar a demanda antes do atendimento presencial.

**Why this priority**: Representa canal alternativo de entrada paralelo ao prontuário; editável e distinto dos relatórios somente leitura.

**Independent Test**: Abrir fila de solicitações; criar solicitação; alterar status (ex.: pendente → em análise → concluída); filtrar por UBS; confirmar persistência local.

**Acceptance Scenarios**:

1. **Given** fila de solicitações da população, **When** o servidor abre a tela, **Then** vê pedidos com cidadão (ou identificação mínima), UBS destino, tipo de solicitação, data e status.
2. **Given** solicitação pendente, **When** o servidor edita status ou observação interna, **Then** alteração persiste e reflete na listagem.
3. **Given** nova solicitação, **When** registrada manualmente na fila, **Then** entra com status inicial coerente (ex.: pendente) e UBS selecionável entre as ~8 unidades.
4. **Given** solicitação vinculada a UBS específica, **When** filtro por unidade é aplicado, **Then** lista exibe apenas solicitações daquela UBS.

---

### User Story 5 - Validação pública de receita por código (Priority: P2)

Como cidadão ou farmácia, preciso acessar uma página pública **sem autenticação** em `/validar`, informar o **código da receita** e verificar se a assinatura é autêntica, para conferir prescrições emitidas pela rede municipal.

**Why this priority**: Requisito explícito de validação pública; diferencia-se do CRUD interno e deve funcionar fora do fluxo autenticado.

**Independent Test**: Acessar `/validar` sem login; informar código válido de receita sintética; ver confirmação de autenticidade com dados mínimos (médico, data, UBS); informar código inválido e ver mensagem clara.

**Acceptance Scenarios**:

1. **Given** visitante não autenticado, **When** acessa `/validar`, **Then** consegue usar a ferramenta de validação — **sem** redirecionamento forçado para login.
2. **Given** código de receita válido e não expirado/revogado, **When** informado na validação, **Then** exibe confirmação de autenticidade com identificação resumida do prescritor, data e UBS — **sem** expor dados clínicos sensíveis além do necessário.
3. **Given** código inexistente ou inválido, **When** informado, **Then** exibe mensagem clara de não encontrado ou inválido — **sem** vazar se o código existiu em outro contexto.
4. **Given** receita revogada ou fora da validade (quando aplicável na regra de negócio), **When** validada, **Then** informa status não válido com motivo compreensível.

---

### User Story 6 - Controle interno: indicadores, conferência e tramitação (Priority: P2)

Como gestor da secretaria ou coordenador de APS, preciso acompanhar **indicadores** de produção (por médico, UBS, mês e período), **conferir** registros com flags de inconsistência e status (pendente, conferido, pronto para envio) e **encaminhar** casos via tramitação interna, para governar a qualidade dos dados antes da exportação ao e-SUS.

**Why this priority**: Diferencia o produto de um CRUD simples; atende controle interno solicitado no contrato; tramitação reutiliza capacidade já existente na plataforma Base.

**Independent Test**: Abrir dashboard de indicadores; filtrar por UBS e mês; abrir tela de conferência; marcar consulta como conferida; acionar encaminhamento para outro setor via tramitação; verificar protocolo gerado ou referência cruzada.

**Acceptance Scenarios**:

1. **Given** consultas sintéticas registradas, **When** o gestor abre indicadores, **Then** vê métricas agregadas por médico, UBS, mês e período selecionável — incluindo totais de consultas, receitas e exames quando aplicável.
2. **Given** tela de conferência, **When** o gestor revisa uma consulta, **Then** vê flags de inconsistência (ex.: CID ausente, procedimento sem vínculo, cidadão sem CNS) e pode alterar status para pendente, conferido ou pronto para envio.
3. **Given** consulta ou solicitação elegível, **When** o usuário aciona encaminhar, **Then** integra ao fluxo de **tramitação** existente da plataforma (Base), gerando demanda rastreável entre setores.
4. **Given** UBS selecionada no filtro de indicadores, **When** métricas são calculadas, **Then** refletem apenas produção daquela unidade.

---

### User Story 7 - Exportar consulta no padrão e-SUS (Ficha de Atendimento Individual) (Priority: P3)

Como servidor responsável pela transição ao e-SUS, preciso **exportar** uma consulta concluída no **formato da Ficha de Atendimento Individual (FAI)**, com nomes de campos compatíveis ao padrão nacional, para validar mapeamento antes da integração oficial.

**Why this priority**: Exportação é entregável contratual de médio prazo; depende do CRUD estável; não bloqueia operação mock diária.

**Independent Test**: Abrir consulta conferida; acionar exportar e-SUS; obter artefato (visualização ou download) com CNS do profissional, CBO, INE, CNES, CNS/CPF do cidadão, CID/CIAP, procedimentos SIGTAP e conduta/desfecho nos nomes de campo e-SUS.

**Acceptance Scenarios**:

1. **Given** consulta com dimensões mínimas preenchidas, **When** o usuário aciona exportação e-SUS, **Then** gera payload estruturado no padrão FAI (JSON legível) — **não** exige envio real ao centralizador nesta fase.
2. **Given** consulta exportada, **When** revisada, **Then** campos espelham identificação profissional (CNS, CBO, INE, CNES), cidadão (CNS/CPF, nascimento, sexo), atendimento (data, tipo, local, turno), avaliação (CID-10 e/ou CIAP-2), procedimentos (SIGTAP), conduta/desfecho e encaminhamentos quando existirem.
3. **Given** consulta com dados insuficientes para exportação, **When** usuário tenta exportar, **Then** recebe lista do que falta — **sem** gerar arquivo incompleto silenciosamente.

---

### Edge Cases

- Consulta sem procedimentos ou sem receita: exportação e relatórios tratam listas vazias sem erro.
- Cidadão identificado apenas por CPF (sem CNS): consulta permanece válida se regra mínima atendida.
- Profissional enfermeiro registrando consulta: permitido no CRUD; relatório de exames continua excluindo enfermeiros como solicitantes.
- UBS inativa ou sem equipe cadastrada: impede nova consulta naquela unidade com mensagem clara.
- Validação pública com tentativas repetidas de código inválido: resposta consistente, sem diferencial de tempo que revele existência de códigos.
- Fila de solicitações com alto volume: listagem permanece utilizável com filtros por UBS e status.
- Dados 100% sintéticos: nenhum nome, CNS ou CPF real do backup e-SUS de Careiro aparece na demonstração.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: O sistema **DEVE** disponibilizar módulo **Saúde** (Atenção Primária / UBS) acessível a usuários com licença **Base**.
- **FR-002**: O CRUD operacional (consultas, cidadãos, profissionais, UBS, medicamentos, fila de solicitações) **DEVE** exigir **somente** licença **Base** — **NUNCA** criar nova licença-árvore para este escopo.
- **FR-003**: A entidade **Consulta** **DEVE** agregar as seis dimensões do atendimento: (1) profissional e local, (2) cidadão, (3) dados do atendimento, (4) conteúdo clínico, (5) procedimentos realizados, (6) medicamentos/receitas.
- **FR-004**: O conteúdo clínico **DEVE** suportar registro estruturado de queixa/subjetivo, objetivo, avaliação, plano, problemas/condições (CID-10 e/ou CIAP-2), conduta/desfecho e encaminhamentos.
- **FR-005**: Procedimentos **DEVEM** referenciar códigos SIGTAP com descrição legível.
- **FR-006**: Receitas **DEVEM** vincular medicamento, posologia, dose, frequência, uso contínuo quando aplicável, e código de prescrição/assinatura para validação pública.
- **FR-007**: Cadastro de **UBS** **DEVE** incluir ~8 unidades sintéticas do município de **Careiro da Várzea (AM)**, cada uma com CNES, equipe, horário e métricas agregadas resumidas.
- **FR-008**: Relatório de **receitas emitidas** **DEVE** ser somente leitura, com ~400 registros sintéticos distribuídos em ~14 meses, agrupáveis por médico, mês e período.
- **FR-009**: Relatório de **exames solicitados** **DEVE** ser somente leitura, com ~100 registros sintéticos, classificação **rotina** ou **urgente**, solicitantes **exclusivamente médicos**.
- **FR-010**: **Fila de solicitações da população** **DEVE** ser editável (criar, atualizar status e observações), com destino UBS selecionável.
- **FR-011**: Rota pública **`/validar`** **DEVE** permitir validação de assinatura de receita por código **sem autenticação**.
- **FR-012**: **Indicadores** **DEVEM** consolidar produção por médico, UBS, mês e período customizado.
- **FR-013**: **Conferência** **DEVE** exibir flags de inconsistência e permitir status pendente, conferido e pronto para envio.
- **FR-014**: **Encaminhamento** **DEVE** integrar ao fluxo de tramitação existente da plataforma (Base).
- **FR-015**: **Exportação e-SUS** **DEVE** gerar payload FAI (JSON) com nomes de campo compatíveis ao padrão nacional, mapeando o modelo interno moderno — **sem** envio real ao SISAB nesta fase.
- **FR-016**: Todos os dados de demonstração **DEVEM** ser **sintéticos** — **NUNCA** importar ou exibir PII real do backup e-SUS recebido.
- **FR-017**: Camadas opcionais de governança avançada (ex.: painéis analíticos Cedro, fiscalização Jatobá) **PODEM** complementar telas específicas — **sem** bloquear o CRUD Base.

### Key Entities *(include if feature involves data)*

- **Consulta**: Registro agregado central; data/hora, tipo e local de atendimento, turno, status operacional e de conferência; vínculos com profissional, cidadão, UBS e equipe.
- **Profissional**: Identificação por CNS, CBO, conselho de classe; lotação em UBS/equipe.
- **Cidadão**: CNS e/ou CPF, nome, nascimento, sexo, contato, endereço resumido.
- **UnidadeSaude (UBS)**: CNES, nome, tipo, equipe, horário, métricas agregadas.
- **Equipe**: INE, profissionais vinculados, UBS de referência.
- **ConteudoClinico**: Subjetivo, objetivo, avaliação, plano; CID/CIAP; conduta; encaminhamentos.
- **Procedimento**: Código SIGTAP, descrição, CID principal quando aplicável.
- **Receita / ItemReceita**: Medicamento, posologia, dose, frequência, uso contínuo, código de validação/assinatura.
- **ExameSolicitado**: Procedimento, datas de solicitação/resultado, prioridade rotina/urgente, solicitante (médico).
- **SolicitacaoCidadao**: Pedido cidadão→UBS, tipo, status, observações, datas.
- **ExportacaoEsus**: Representação FAI derivada de Consulta para interoperabilidade futura.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Usuário com licença Base consegue criar uma consulta completa (seis dimensões) e reabri-la em **menos de 5 minutos** em demonstração guiada.
- **SC-002**: Relatório de receitas exibe e agrupa ~400 registros sintéticos por médico/mês **sem** edição acidental (somente leitura).
- **SC-003**: Relatório de exames exibe ~100 solicitações com **100%** dos solicitantes identificados como médicos e classificação rotina/urgente visível.
- **SC-004**: Validação pública em `/validar` confirma ou rejeita código de receita em **até 2 interações** (informar código + ver resultado).
- **SC-005**: Exportação e-SUS de consulta conferida produz payload FAI com **todos** os grupos obrigatórios (profissional, cidadão, atendimento, avaliação, procedimentos, conduta) preenchidos quando dados existem no registro.
- **SC-006**: Gestor filtra indicadores por UBS e mês e obtém totais coerentes com consultas sintéticas seedadas — divergência **zero** em ambiente de demonstração controlado.
- **SC-007**: Encaminhamento a partir de consulta ou solicitação gera demanda rastreável na tramitação Base em **100%** dos casos de teste de aceitação.

## Assumptions

- Município piloto: **Careiro da Várzea (AM)**; ~8 UBS como referência fixa de seed sintético.
- Fase atual é **mock operacional** no cliente: persistência local/em memória; integração API/e-SUS real fica fora desta spec.
- Backup PostgreSQL e-SUS recebido serve **apenas** como referência de modelo de dados para exportação — **não** como fonte de carga.
- Modelo interno usa nomenclatura moderna legível; exportação traduz para nomes de campo e-SUS (FAI).
- CRUD e operação diária ficam na licença **Base**; Cedro/Jatobá/Carvalho/Pau-Brasil permanecem opcionais para camadas analíticas ou fiscalização futura.
- Enfermeiros registram consultas no CRUD, mas **não** solicitam exames complementares no relatório — alinhado à regra de negócio informada.
- Assinatura de receita na validação pública é verificável por código determinístico derivado dos dados sintéticos (detalhe de algoritmo fica para fase de plano/implementação).

## Entregas pós-implement (2026-06-29)

Além do escopo original de implement, foram entregues:

### Navegação e UX

- Sidebar com seção **Saúde** independente (Administração · Gestão · **Saúde**).
- Quatro domínios operacionais, cada um com dashboard:
  - **Atendimento** — fila, consultas, solicitações (`/saude/atendimento`)
  - **Cadastros** — cidadãos, unidades, profissionais, medicamentos (`/saude/cadastros`)
  - **Acompanhamento** — receitas, exames (`/saude/acompanhamento`)
  - **Controle** — indicadores municipais, conferência (`/saude/controle`)
- Design system institucional (breadcrumb, KPI, filtros, tabela, paginação) alinhado a compras/setor.
- Design system de **detalhe** com `CopyableField` — ícone copiar em todo dado exibido.

### Telas de licença (mock client-side)

| Tela | Licença | Rota |
|------|---------|------|
| Insights IA | Cedro | `/saude/insights` |
| Fiscalização | Jatobá | `/saude/fiscalizacao` |
| Maturidade | Carvalho | `/saude/maturidade` |

CRUD operacional permanece em licença **Base**; telas acima exigem a licença correspondente no filtro do shell.

### Dívida técnica consciente

- **Export e-SUS FAI** (US7): botão no detalhe da consulta exibe placeholder; mapper `esus-export.ts` **não** implementado nesta entrega.
- Atalhos Saúde em `welcome-shortcuts.ts` — pendente.
- E2E Vitest leve (`saude.e2e.test.tsx`) — pendente.
- Artefato `_schema.sql` na raiz do workspace — remover em housekeeping.
