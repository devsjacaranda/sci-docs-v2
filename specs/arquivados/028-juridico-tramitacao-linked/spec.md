# Feature Specification: Integrar JurÃ­dico Ã  TramitaÃ§Ã£o â€” Linked Record

**Feature Branch**: `028-juridico-tramitacao-linked`

**Created**: 2026-07-01

**Status**: Completed

**Input**: User description: "Integrar mÃ³dulo jurÃ­dico a tramitaÃ§Ã£o â€” linked record. Atualmente /juridico/processos nÃ£o estÃ¡ integrado ao tramitaÃ§Ã£o e nÃ£o dÃ¡ pra tramitar seus dados."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Tramitar processo jurÃ­dico para outro setor (Priority: P1)

Como operador do setor jurÃ­dico, quero abrir um processo confirmado, escolher o setor destinatÃ¡rio e registrar uma observaÃ§Ã£o de tramitaÃ§Ã£o, para que o assunto siga formalmente pelo mÃ³dulo TramitaÃ§Ã£o sem perder o vÃ­nculo com o processo de origem.

**Why this priority**: Ã‰ o fluxo central da feature â€” sem tramitaÃ§Ã£o a partir do JurÃ­dico, a integraÃ§Ã£o nÃ£o entrega valor. Corresponde ao gap reportado pelo usuÃ¡rio.

**Independent Test**: Pode ser validado criando/abrindo um processo confirmado, executando "Tramitar", e verificando que uma demanda aparece na inbox TramitaÃ§Ã£o do setor destino com origem JurÃ­dico.

**Acceptance Scenarios**:

1. **Given** um processo jurÃ­dico confirmado (nÃ£o rascunho) visÃ­vel na lista de processos, **When** o operador aciona "Tramitar", informa setor destino e observaÃ§Ã£o, **Then** o sistema cria uma demanda na TramitaÃ§Ã£o vinculada ao processo e exibe confirmaÃ§Ã£o com protocolo da demanda e atalho para abri-la.
2. **Given** um processo em rascunho, **When** o operador tenta tramitar, **Then** o sistema impede a aÃ§Ã£o e informa que apenas processos confirmados podem ser tramitados.
3. **Given** tramitaÃ§Ã£o concluÃ­da com sucesso, **When** o operador consulta o histÃ³rico do processo, **Then** o evento de tramitaÃ§Ã£o inter-setorial aparece na linha do tempo do processo.

---

### User Story 2 - Visualizar processos jurÃ­dicos reais (lista e detalhe) (Priority: P1)

Como operador autorizado ao mÃ³dulo JurÃ­dico, quero consultar a lista de processos e abrir o detalhe de um processo especÃ­fico com dados reais do tenant, para poder localizar o registro correto antes de tramitar.

**Why this priority**: A rota `/juridico/processos` hoje exibe dados fictÃ­cios; sem lista e detalhe reais, a aÃ§Ã£o de tramitar nÃ£o tem superfÃ­cie utilizÃ¡vel no produto.

**Independent Test**: Pode ser validado acessando a lista de processos e o detalhe de um ID existente, confirmando que protocolo, tipo, partes, status e prazo refletem dados persistidos â€” nÃ£o placeholders de demonstraÃ§Ã£o.

**Acceptance Scenarios**:

1. **Given** processos cadastrados no tenant, **When** o operador acessa a lista de processos jurÃ­dicos, **Then** vÃª tabela paginada com nÃºmero interno, tipo, partes resumidas, status e prazo.
2. **Given** um processo existente, **When** o operador abre o detalhe pelo ID, **Then** vÃª assunto, observaÃ§Ãµes, partes, Ã³rgÃ£o/vara, prazo, status e linha do tempo de eventos.
3. **Given** um ID inexistente, **When** o operador tenta abrir o detalhe, **Then** o sistema exibe mensagem clara de processo nÃ£o encontrado.

---

### User Story 3 - Consultar linked record na TramitaÃ§Ã£o (Priority: P2)

Como operador que recebeu uma demanda originada do JurÃ­dico, quero visualizar no painel de registro de origem os dados essenciais do processo (protocolo, tipo, status, partes, assunto) e abrir o processo original, para entender o contexto sem alternar manualmente entre mÃ³dulos.

**Why this priority**: Completa o ciclo da integraÃ§Ã£o â€” quem recebe precisa enxergar o vÃ­nculo tÃ£o bem quanto quem enviou. Segue o padrÃ£o jÃ¡ estabelecido para Ouvidoria.

**Independent Test**: Pode ser validado abrindo uma demanda linked com origem JurÃ­dico na inbox TramitaÃ§Ã£o e verificando painel, snapshot e link "Abrir origem".

**Acceptance Scenarios**:

1. **Given** demanda na TramitaÃ§Ã£o com origem mÃ³dulo JurÃ­dico, **When** o destinatÃ¡rio abre o detalhe da demanda, **Then** o painel de registro de origem exibe protocolo, tipo, status, assunto e resumo das partes capturados no momento da tramitaÃ§Ã£o.
2. **Given** demanda linked de JurÃ­dico, **When** o destinatÃ¡rio clica em "Abrir origem", **Then** Ã© direcionado ao detalhe do processo correspondente.
3. **Given** snapshot incompleto (dados mÃ­nimos), **When** o painel Ã© exibido, **Then** o sistema tenta complementar com dados atuais do processo; se indisponÃ­vel, mantÃ©m snapshot e informa limitaÃ§Ã£o sem quebrar a tela.

---

### User Story 4 - Dados demo para validaÃ§Ã£o ponta a ponta (Priority: P3)

Como desenvolvedor ou analista de produto em ambiente de demonstraÃ§Ã£o, quero ao menos um processo jurÃ­dico confirmado vinculado a uma demanda de tramitaÃ§Ã£o no seed, para validar o fluxo completo sem cadastro manual.

**Why this priority**: Acelera QA e demos; nÃ£o bloqueia uso em produÃ§Ã£o, mas reduz fricÃ§Ã£o de validaÃ§Ã£o.

**Independent Test**: ApÃ³s seed do tenant demo, existe processo jurÃ­dico confirmado cujo ID corresponde a uma demanda linked visÃ­vel na TramitaÃ§Ã£o.

**Acceptance Scenarios**:

1. **Given** tenant demo recÃ©m-semeado, **When** o operador abre TramitaÃ§Ã£o â†’ demanda linked JurÃ­dico, **Then** "Abrir origem" resolve para processo existente (sem erro de registro nÃ£o encontrado).

---

### Edge Cases

- O que acontece quando o setor destinatÃ¡rio foi desativado apÃ³s a tramitaÃ§Ã£o? A demanda permanece consultÃ¡vel; encaminhamentos futuros devem bloquear setores invÃ¡lidos com mensagem clara.
- Como o sistema se comporta quando o processo de origem foi excluÃ­do (soft delete) apÃ³s a tramitaÃ§Ã£o? A demanda mantÃ©m snapshot imutÃ¡vel; painel indica "Origem removida" e desabilita link ativo.
- Operador sem permissÃ£o no mÃ³dulo JurÃ­dico tenta abrir origem a partir da TramitaÃ§Ã£o: acesso negado com mensagem institucional, sem vazar dados sensÃ­veis.
- TramitaÃ§Ã£o duplicada do mesmo processo para o mesmo setor: permitida (cada aÃ§Ã£o gera nova demanda), com eventos distintos no histÃ³rico do processo.
- Processo com prazo vencido ou status crÃ­tico: tramitaÃ§Ã£o permanece permitida se confirmado; badges visuais de urgÃªncia preservadas na lista e no snapshot.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: O sistema DEVE exibir lista paginada de processos jurÃ­dicos do tenant com colunas: nÃºmero interno, tipo, partes (resumo), status operacional e prazo.
- **FR-002**: O sistema DEVE permitir abrir detalhe de processo por identificador, exibindo dados cadastrais, partes, Ã³rgÃ£o/vara, anexos confirmados, status e linha do tempo de eventos.
- **FR-003**: O sistema DEVE oferecer aÃ§Ã£o "Tramitar" no detalhe de processos confirmados, excluindo rascunhos.
- **FR-004**: Ao tramitar, o operador DEVE informar setor destinatÃ¡rio (obrigatÃ³rio) e observaÃ§Ã£o (obrigatÃ³ria, texto livre).
- **FR-005**: Cada tramitaÃ§Ã£o bem-sucedida DEVE criar demanda no mÃ³dulo TramitaÃ§Ã£o com origem `juridico`, referÃªncia ao ID do processo e snapshot imutÃ¡vel contendo no mÃ­nimo: protocolo/nÃºmero interno, tipo de processo, status, assunto e resumo das partes.
- **FR-006**: O sistema DEVE registrar evento de tramitaÃ§Ã£o inter-setorial na linha do tempo do processo jurÃ­dico.
- **FR-007**: ApÃ³s tramitar, o sistema DEVE informar protocolo da demanda criada e oferecer atalho para visualizÃ¡-la na TramitaÃ§Ã£o.
- **FR-008**: Na TramitaÃ§Ã£o, demandas com origem JurÃ­dico DEVEM exibir painel de registro de origem formatado (badges de tipo/status, campos essenciais, descriÃ§Ã£o quando houver).
- **FR-009**: O painel linked record DEVE oferecer link "Abrir origem" para `/juridico/processos/:id` quando o processo ainda existir.
- **FR-010**: Quando o processo de origem nÃ£o existir mais, o painel DEVE exibir indicador "Origem removida" e manter dados do snapshot.
- **FR-011**: O sistema DEVE respeitar permissÃµes de mÃ³dulo e setor: apenas operadores autorizados ao JurÃ­dico tramitam processos; apenas operadores com acesso ao JurÃ­dico abrem a origem.
- **FR-012**: O seed demo DEVE incluir ao menos um processo jurÃ­dico confirmado referenciado por demanda linked na TramitaÃ§Ã£o, com IDs consistentes entre origem e snapshot.
- **FR-013**: A lista e o detalhe de processos DEVEM substituir dados fictÃ­cios atualmente exibidos na rota `/juridico/processos` por dados persistidos do tenant.

### Key Entities

- **Processo JurÃ­dico**: Registro formal de assunto jurÃ­dico (administrativo, judicial ou consultivo) com nÃºmero interno, partes, prazo, status operacional e histÃ³rico de eventos.
- **Demanda de TramitaÃ§Ã£o (linked)**: Mensagem inter-setorial com protocolo prÃ³prio, vinculada a registro de origem via mÃ³dulo + ID + snapshot imutÃ¡vel.
- **Snapshot de Origem**: Captura pontual dos metadados do processo no momento da tramitaÃ§Ã£o, preservada mesmo se o processo for alterado ou removido depois.
- **Evento de Processo**: Entrada na linha do tempo (ex.: registro, parecer, tramitaÃ§Ã£o) com tÃ­tulo, descriÃ§Ã£o, autor e data.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Operador consegue tramitar um processo confirmado e localizar a demanda correspondente na TramitaÃ§Ã£o em menos de 2 minutos, sem suporte tÃ©cnico.
- **SC-002**: 100% das tramitaÃ§Ãµes bem-sucedidas a partir do JurÃ­dico geram demanda linked com snapshot contendo protocolo, tipo, status e assunto.
- **SC-003**: DestinatÃ¡rio identifica origem JurÃ­dico e dados essenciais do processo no painel linked record em uma Ãºnica tela, sem navegar manualmente para outro mÃ³dulo.
- **SC-004**: Link "Abrir origem" a partir de demanda demo seeded resolve para processo existente em 100% dos casos de validaÃ§Ã£o pÃ³s-seed.
- **SC-005**: Tentativas de tramitar rascunho ou abrir processo inexistente resultam em mensagem compreensÃ­vel em 100% dos cenÃ¡rios de teste, sem erro genÃ©rico.

## Assumptions

- O padrÃ£o de UX e fluxo segue o jÃ¡ estabelecido para Ouvidoria â†’ TramitaÃ§Ã£o (encaminhar setor + painel linked record + toast com atalho).
- Escopo limitado a lista, detalhe, tramitar e linked record â€” dashboard jurÃ­dico, fiscalizaÃ§Ã£o JatobÃ¡, insights Cedro e maturidade Carvalho permanecem fora desta entrega.
- Apenas processos confirmados sÃ£o elegÃ­veis Ã  tramitaÃ§Ã£o; rascunhos continuam exigindo confirmaÃ§Ã£o prÃ©via via fluxo existente de wizard.
- Operadores utilizam setor ativo na sessÃ£o para determinar remetente da tramitaÃ§Ã£o, conforme demais mÃ³dulos integrados.
- Soft delete do processo nÃ£o remove demandas jÃ¡ criadas; snapshot garante rastreabilidade histÃ³rica.
- LicenÃ§a base do tenant inclui mÃ³dulos JurÃ­dico e TramitaÃ§Ã£o; sub-recursos premium (JatobÃ¡/Cedro/Carvalho) nÃ£o sÃ£o prÃ©-requisito desta integraÃ§Ã£o.

## Dependencies

- MÃ³dulo TramitaÃ§Ã£o operacional com suporte a demandas linked (origem mÃ³dulo + ID + snapshot).
- PermissÃµes multi-setor e licenÃ§a de mÃ³dulo JurÃ­dico configuradas no tenant.
- Fluxo de criaÃ§Ã£o/confirmaÃ§Ã£o de processo jurÃ­dico (wizard) jÃ¡ disponÃ­vel para gerar registros tramitÃ¡veis.

## Out of Scope

- RefatoraÃ§Ã£o completa de todas as telas mock do JurÃ­dico (dashboard, auditoria, alertas legislativos).
- SincronizaÃ§Ã£o bidirecional de status entre TramitaÃ§Ã£o e JurÃ­dico (ex.: encerrar demanda atualiza processo automaticamente).
- TramitaÃ§Ã£o em lote de mÃºltiplos processos.
- NotificaÃ§Ãµes por e-mail ou push ao receber demanda linked.
