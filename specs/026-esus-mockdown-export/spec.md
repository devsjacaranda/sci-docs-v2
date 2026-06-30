# Feature Specification: Exportação e-SUS — Dados Mockdown para Demonstração

**Feature Branch**: `026-esus-mockdown-export`

**Created**: 2026-06-29

**Status**: Draft

**Input**: User description: "Cidadãos, Unidades, Profissionais, Medicamentos, Consultas, Solicitações, Receitas, Exames, Conferência — exportar dados mockdown no padrão e-SUS para demonstração."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Exportar consulta conferida no padrão FAI (Priority: P1)

Como servidor responsável pela transição ao e-SUS APS, preciso **exportar uma consulta finalizada e conferida** no formato da **Ficha de Atendimento Individual (FAI)**, com nomes de campos compatíveis ao padrão nacional, para validar o mapeamento dos dados mockdown com a prefeitura antes de qualquer integração oficial.

**Why this priority**: A FAI é o artefato central de produção APS; sem exportação válida da consulta agregada não há demonstração contratual nem base para evolução da integração.

**Independent Test**: Abrir uma consulta com status de conferência "pronto para envio"; acionar exportação; obter artefato legível com identificação do profissional (CNS, CBO, INE, CNES), cidadão (CNS ou CPF, nascimento, sexo), dados do atendimento, avaliação clínica (CID-10 e/ou CIAP-2), procedimentos SIGTAP e conduta/desfecho nos nomes de campo e-SUS.

**Acceptance Scenarios**:

1. **Given** consulta finalizada com dimensões mínimas preenchidas e status de conferência "pronto para envio", **When** o usuário aciona exportação e-SUS no detalhe da consulta, **Then** gera payload estruturado no padrão FAI (formato legível para humanos) — **sem** envio real ao centralizador nacional.
2. **Given** consulta exportada, **When** revisada por gestor ou técnico e-SUS, **Then** campos espelham as dimensões cadastrais e clínicas existentes no mockdown: profissional e local, cidadão, atendimento, conteúdo clínico, procedimentos e conduta.
3. **Given** consulta com status de conferência diferente de "pronto para envio", **When** o usuário tenta exportar, **Then** o sistema informa que a exportação exige conferência prévia e indica o status atual.
4. **Given** consulta com dados insuficientes para exportação, **When** o usuário tenta exportar, **Then** recebe lista clara do que falta — **sem** gerar artefato incompleto silenciosamente.

---

### User Story 2 - Validar prontidão antes da exportação (Priority: P1)

Como conferente de registros APS, preciso que o sistema **valide automaticamente** se uma consulta atende aos requisitos mínimos do padrão e-SUS antes de permitir exportação, alinhado às regras já exibidas na tela de conferência, para evitar demonstrações com payloads inválidos perante a secretaria.

**Why this priority**: Exportação silenciosa de dados incompletos compromete a credibilidade da demonstração e contradiz o fluxo de conferência já operacional no módulo Saúde.

**Independent Test**: Tentar exportar consultas com CNS ausente, CNES inválido ou avaliação sem CID/CIAP; verificar que o sistema bloqueia a exportação e lista cada pendência em linguagem operacional (não técnica).

**Acceptance Scenarios**:

1. **Given** consulta sem CNS ou CPF do cidadão, **When** validação de exportação é executada, **Then** a pendência "identificação do cidadão" aparece na lista de impeditivos.
2. **Given** consulta sem CNS do profissional ou CNES da unidade, **When** validação é executada, **Then** pendências de transporte (profissional/local) aparecem antes de qualquer download.
3. **Given** consulta sem CID, CIAP ou texto de avaliação, **When** validação é executada, **Then** pendência de avaliação clínica é reportada.
4. **Given** consulta que passa em todas as validações, **When** status de conferência é atualizado para "pronto para envio", **Then** exportação fica habilitada na mesma sessão sem recarregar dados manualmente.

---

### User Story 3 - Visualizar e baixar artefato para demonstração (Priority: P2)

Como gestor municipal ou equipe de implantação e-SUS, preciso **visualizar e baixar** o payload exportado durante reuniões de demonstração, para compartilhar com técnicos da secretaria e comparar com a documentação nacional do e-SUS APS.

**Why this priority**: A demonstração contratual exige artefato tangível que stakeholders possam inspecionar fora do fluxo operacional diário.

**Independent Test**: Exportar consulta válida; visualizar conteúdo estruturado na interface; baixar arquivo nomeado de forma identificável (consulta, cidadão, data); reabrir arquivo e confirmar legibilidade.

**Acceptance Scenarios**:

1. **Given** exportação bem-sucedida, **When** o usuário escolhe visualizar, **Then** vê o payload formatado de forma legível, agrupado por seções equivalentes à FAI (transporte, cidadão, atendimento, procedimentos, conduta).
2. **Given** exportação bem-sucedida, **When** o usuário escolhe baixar, **Then** recebe arquivo único por consulta, identificável por data e cidadão, pronto para anexar em ata ou e-mail de demonstração.
3. **Given** exportação com blocos de extensão (receitas, exames ou solicitações), **When** visualizada, **Then** extensões aparecem claramente separadas dos campos clássicos FAI, sinalizadas como complemento de demonstração — não como campo oficial MS.

---

### User Story 4 - Incluir dimensões complementares como extensão de demonstração (Priority: P2)

Como profissional de saúde ou farmácia municipal, preciso que **receitas, exames e solicitações** vinculados à consulta apareçam no pacote exportado como **bloco de extensão documentado**, já que medicamentos e encaminhamentos complementares não fazem parte da FAI clássica, mas são essenciais para a narrativa completa do mockdown Careiro.

**Why this priority**: O mockdown cobre oito áreas operacionais; omitir receitas/exames/solicitações tornaria a demonstração incompleta perante volumes conhecidos (~400 receitas, ~100 solicitações de exame).

**Independent Test**: Exportar consulta com receita prescrita por médico, solicitação de exame e procedimentos SIGTAP; verificar bloco principal FAI + extensões nomeadas com dados sintéticos coerentes (posologia, código de validação de receita, solicitante médico para exames).

**Acceptance Scenarios**:

1. **Given** consulta com receita vinculada, **When** exportada, **Then** bloco `medicamentosPrescritos` (ou equivalente semântico) lista princípio ativo, posologia, uso contínuo e código de validação pública — **sem** expor dados clínicos sensíveis além do necessário à demo.
2. **Given** solicitação de exame vinculada registrada por **médico** (CBO 225*), **When** exportada, **Then** extensão de exames inclui procedimento solicitado, data e identificação do solicitante conforme regra de negócio APS.
3. **Given** solicitação de exame registrada por enfermeiro, **When** exportada ou validada, **Then** sistema sinaliza inconsistência de solicitante — alinhado à regra "enfermeiro registra consulta; médico solicita exame complementar".
4. **Given** consulta sem receita, exame ou solicitação, **When** exportada, **Then** blocos de extensão são omitidos ou vazios — exportação principal FAI permanece válida.

---

### User Story 5 - Pacote demonstrativo dos cadastros de referência (Priority: P3)

Como coordenador de APS preparando workshop de implantação, preciso exportar um **pacote de referência** com amostra dos cadastros mockdown — cidadãos, unidades (UBS), profissionais e medicamentos — em estrutura compatível com identificadores e-SUS (CNS, CNES, CBO, CATMAT), para contextualizar a origem dos dados que alimentam as fichas de atendimento.

**Why this priority**: Stakeholders frequentemente pedem visão dos cadastros base antes de analisar fichas individuais; é complementar à exportação por consulta.

**Independent Test**: Acionar exportação de pacote demonstrativo; receber conjunto estruturado com subconjunto dos ~8 UBS, profissionais com CNS/CBO, cidadãos sintéticos e catálogo de medicamentos — todos claramente marcados como dados de demonstração.

**Acceptance Scenarios**:

1. **Given** tenant de demonstração ativo, **When** usuário solicita pacote de cadastros, **Then** recebe arquivo agregado ou conjunto de arquivos com cidadãos (CNS/CPF, nascimento, sexo), unidades (CNES, nome), profissionais (CNS, CBO, vínculo UBS/equipe) e medicamentos (princípio ativo, referência CATMAT quando aplicável).
2. **Given** pacote exportado, **When** inspecionado, **Then** **nenhum** dado real de backup e-SUS ou PII de produção aparece — apenas registros sintéticos do mockdown.
3. **Given** pacote de cadastros, **When** comparado a uma FAI exportada, **Then** identificadores cruzados (CNS cidadão, CNES unidade, CNS profissional) são consistentes entre cadastro e ficha.

---

### Edge Cases

- Consulta finalizada mas ainda "pendente" ou "conferida" (sem "pronto para envio"): exportação bloqueada com orientação para atualizar status na tela de conferência.
- Consulta com apenas CPF (sem CNS) do cidadão: exportação permitida se demais campos obrigatórios OK; conferência pode manter alerta informativo (já existente no mockdown).
- Consulta sem procedimentos ou sem receita: listas vazias no payload — **sem** erro; extensões omitidas.
- Unidade inativa vinculada à consulta: exportação bloqueada com pendência explícita.
- Tentativa de exportação em lote de consultas com pendências mistas: apenas registros válidos e "prontos para envio" entram no lote; demais listados com motivo de exclusão.
- Dados corrompidos ou entidade referenciada ausente (ex.: profissional excluído): exportação falha com mensagem clara — **sem** payload parcial silencioso.
- Demonstração offline: download deve funcionar sem dependência de envio externo ou conectividade com sistemas MS.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: O sistema **DEVE** permitir exportar consulta individual no padrão **Ficha de Atendimento Individual (FAI)** do e-SUS APS, usando nomenclatura de campos compatível com o layout nacional legível (formato estruturado para humanos).
- **FR-002**: Exportação **DEVE** mapear as seis dimensões internas da consulta mockdown: profissional e local, cidadão, dados do atendimento, conteúdo clínico, procedimentos SIGTAP e conduta/desfecho.
- **FR-003**: Exportação **DEVE** exigir status de conferência **"pronto para envio"** antes de gerar artefato.
- **FR-004**: Antes de exportar, o sistema **DEVE** validar campos obrigatórios mínimos: CNS do profissional, CBO, CNES da unidade, identificação do cidadão (CNS ou CPF), data de nascimento do cidadão, data do atendimento e pelo menos uma condição clínica (CID-10, CIAP-2 ou texto de avaliação).
- **FR-005**: Quando validação falhar, o sistema **DEVE** apresentar lista de pendências em linguagem operacional — **NUNCA** gerar exportação incompleta sem aviso.
- **FR-006**: O sistema **DEVE** oferecer visualização e download do payload exportado por consulta, identificável por cidadão e data do atendimento.
- **FR-007**: Receitas, exames e solicitações vinculados **DEVEM** aparecer em bloco de **extensão de demonstração**, claramente separado dos campos clássicos FAI e rotulado como complemento não oficial MS.
- **FR-008**: Regra de negócio APS **DEVE** ser respeitada na extensão de exames: solicitante **DEVE** ser médico (ocupação compatível com solicitação complementar); registros por enfermeiro **DEVEM** ser sinalizados como inconsistência.
- **FR-009**: Medicamentos prescritos na extensão **DEVEM** incluir princípio ativo, posologia, indicação de uso contínuo quando aplicável e código de validação pública da receita mockdown — **sem** expor informação clínica sensível além do necessário à demonstração.
- **FR-010**: O sistema **DEVE** oferecer exportação opcional de **pacote demonstrativo de cadastros** (cidadãos, unidades, profissionais, medicamentos) com identificadores e-SUS canônicos e marcação explícita de dados sintéticos.
- **FR-011**: Todos os artefatos exportados **DEVEM** conter apenas dados **sintéticos** do mockdown — **NUNCA** dados reais de backup PEC/e-SUS ou PII de produção.
- **FR-012**: Exportação nesta fase **NÃO DEVE** transmitir dados ao centralizador nacional, SISAB ou PEC real — escopo limitado a geração local para demonstração e validação de mapeamento.
- **FR-013**: A ação de exportação **DEVE** estar acessível a usuários com permissão ao módulo Saúde (licença Base) a partir do detalhe da consulta e, opcionalmente, a partir da tela de conferência para registros elegíveis.
- **FR-014**: Exportação em lote (múltiplas consultas "prontas para envio") **PODE** ser oferecida como complemento; registros inelegíveis **DEVEM** ser listados com motivo, sem interromper exportação dos demais.

### Key Entities *(include if feature involves data)*

- **Consulta**: Registro agregado de atendimento APS — origem principal da FAI exportada; status de conferência governa elegibilidade.
- **Cidadão**: Titular do atendimento; identificação por CNS ou CPF, nascimento e sexo alimentam `identificacaoUsuarioCidadao`.
- **Unidade (UBS)**: Estabelecimento com CNES; origem de `nuCnes` no transporte da ficha.
- **Profissional**: Executor do atendimento; CNS, CBO e vínculo com equipe (INE) alimentam `headerTransport`.
- **Medicamento**: Item de catálogo e de receita; na FAI clássica não tem campo oficial — entra como extensão `medicamentosPrescritos`.
- **Procedimento (SIGTAP)**: Produção procedimental vinculada à consulta; mapeado para lista de procedimentos da FAI.
- **Receita**: Prescrição vinculada à consulta; extensão demo com validação pública.
- **Solicitação / Exame**: Demanda cidadão→UBS ou encaminhamento clínico; extensão demo com regra de solicitante médico.
- **Conferência**: Estado operacional (`pendente`, `conferido`, `pronto para envio`) e flags de inconsistência — gate de qualidade antes da exportação.
- **Exportação e-SUS**: Artefato derivado (FAI + extensões opcionais + pacote cadastros) para demonstração; não persiste como entidade operacional independente.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Usuário consegue exportar consulta "pronta para envio" e obter artefato legível em **menos de 1 minuto** a partir do detalhe da consulta.
- **SC-002**: **100%** das tentativas de exportação com campos obrigatórios ausentes resultam em lista de pendências — **zero** exportações silenciosamente incompletas em testes de aceitação.
- **SC-003**: **95%** dos registros seed completos do mockdown Careiro (consultas finalizadas e conferidas) produzem payload FAI com todos os grupos obrigatórios preenchidos quando os dados existem no registro interno.
- **SC-004**: Gestores conseguem baixar e abrir arquivo exportado em reunião de demonstração **sem** ferramentas proprietárias — formato legível por humanos e analisável por equipe e-SUS.
- **SC-005**: Identificadores cruzados (CNS cidadão/profissional, CNES unidade) são **consistentes** entre pacote de cadastros e FAI exportada da mesma consulta em **100%** dos casos testados.
- **SC-006**: Extensões de receita, exame e solicitação aparecem claramente rotuladas como demonstração em **100%** dos exports que as incluem — revisores distinguem campos oficiais FAI de complementos mockdown.
- **SC-007**: Nenhum dado real de backup e-SUS ou PII de produção aparece em artefatos exportados durante auditoria de demonstração.

## Assumptions

- Módulo Saúde mockdown (spec 024) já entregue: CRUD operacional, conferência, cadastros sintéticos e placeholder de exportação no detalhe da consulta.
- Versão de referência para campos e validações: **LEDI APS 7.4.2** (layout nacional); PEC operacional e LEDI são versionados independentemente — esta feature cobre **subset legível** para demo, não transmissão Thrift/XML completa.
- Persistência permanece local ao mockdown (demonstração); integração API NestJS e envio real ao PEC ficam **fora** desta spec.
- Backup PostgreSQL e-SUS de Careiro serve **apenas** como referência de modelo — **nunca** como fonte de carga ou exportação.
- Licença **Base** cobre exportação; licenças Cedro/Jatobá/Carvalho não alteram o contrato de exportação nesta fase.
- Exportação individual por consulta é entrega mínima (MVP); pacote agregado de cadastros e lote de consultas são incrementos compatíveis dentro desta mesma feature, priorizados após MVP.
- Campos SOAP (subjetivo, avaliação, plano) sem equivalente FAI clássico podem constar como extensão de rastreio demo, seguindo precedente do contrato arquivado 024.
- Receitas já possuem rota pública de validação (`/validar`); exportação reutiliza código de validação existente sem ampliar exposição de dados clínicos.

## Dependencies

- Feature arquivada **024-saude-atendimento-ubs**: modelo de consulta agregada, stores mockdown, tela de conferência, contrato FAI de referência.
- Skill de domínio **e-SUS APS**: mapeamento CI → FAI, identificadores canônicos (CNS, CNES, CBO, INE, SIGTAP), regras de extensão demo.
- Documentação de produto: vocabulário imperativo em `.cursor/docs/regras-plataforma.md`; licença Base em `.cursor/docs/licencas-canonicas.md`.

## Out of Scope

- Transmissão real ao centralizador e-SUS, SISAB ou API de transmissão PEC.
- Geração de arquivos Thrift ou XML LEDI completos para importação automática no PEC.
- Sincronização de competência SIGTAP ou catálogo nacional em tempo real.
- Exportação analítica DW (relatórios gerenciais, indicadores quadrimestrais).
- Backend NestJS ou persistência PostgreSQL para exportação — escopo cliente mockdown nesta entrega.
