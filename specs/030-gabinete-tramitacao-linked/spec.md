# Feature Specification: Integrar Gabinete (Atos) à Tramitação — Linked Record

**Feature Branch**: `030-gabinete-tramitacao-linked`

**Created**: 2026-07-01

**Status**: Draft

**Tipo**: Feature

**Módulo**: Gabinete — atos (`/gabinete/atos`); Tramitação — linked record

**Input**: User description: "Implementar tramitação no gabinete (atos - gabinete). Atualmente não existe. Módulo: tramitacao, cabinet. Rota: /gabinete/atos"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Tramitar ato para outro setor (Priority: P1)

Como operador do Gabinete do Presidente, quero abrir um ato registrado, escolher o setor destinatário e registrar uma observação de tramitação, para que o assunto siga formalmente pelo módulo Tramitação sem perder o vínculo com o ato de origem.

**Why this priority**: É o fluxo central da feature — sem tramitação a partir do Gabinete, a integração não entrega valor operacional. Corresponde ao gap reportado: a licença Base documenta tramitação como *stub* e o ciclo Gabinete → Tramitação não está completo como em Ouvidoria e Jurídico.

**Independent Test**: Pode ser validado abrindo um ato em status elegível em `/gabinete/atos`, executando "Tramitar", e verificando que uma demanda aparece na inbox Tramitação do setor destino com origem Gabinete.

**Acceptance Scenarios**:

1. **Given** um ato registrado (não rascunho) visível na lista ou detalhe em `/gabinete/atos`, **When** o operador aciona "Tramitar", informa setor destino e observação, **Then** o sistema cria uma demanda na Tramitação vinculada ao ato, atualiza o status operacional do ato para *Em trâmite*, registra evento na timeline e exibe confirmação com protocolo da demanda e atalho para abri-la.
2. **Given** um ato em status *Arquivado* ou *Finalizado*, **When** o operador tenta tramitar, **Then** o sistema impede a ação — a opção "Tramitar" não aparece ou retorna mensagem clara de status inelegível.
3. **Given** um ato em rascunho, **When** o operador tenta tramitar, **Then** o sistema impede a ação e informa que apenas atos registrados podem ser tramitados.
4. **Given** tramitação concluída com sucesso, **When** o operador consulta o histórico do ato, **Then** o evento de encaminhamento inter-setorial aparece na timeline com setor destino, observação e referência à demanda criada.

---

### User Story 2 - Tramitar a partir da lista de atos (Priority: P1)

Como operador do Gabinete, quero acionar "Tramitar" diretamente na lista de atos (`/gabinete/atos`), sem precisar abrir o detalhe, para agilizar encaminhamentos rotineiros.

**Why this priority**: A lista já expõe a ação na UI; a feature deve garantir que o fluxo modal funcione de ponta a ponta com os mesmos critérios do detalhe.

**Independent Test**: Na lista de atos, acionar menu "Tramitar" em linha elegível; confirmar tramitação; verificar demanda linked na Tramitação e atualização da linha (status *Em trâmite*) após recarregar.

**Acceptance Scenarios**:

1. **Given** ato elegível na tabela de `/gabinete/atos`, **When** operador seleciona "Tramitar" no menu de ações da linha, **Then** modal de tramitação abre com os mesmos campos e validações do detalhe.
2. **Given** tramitação concluída pela lista, **When** operador retorna à lista, **Then** o status do ato reflete *Em trâmite* e a ação "Tramitar" permanece disponível para novos encaminhamentos (cada tramitação gera nova demanda).

---

### User Story 3 - Consultar linked record na Tramitação (Priority: P2)

Como operador que recebeu uma demanda originada do Gabinete, quero visualizar no painel de registro de origem os dados essenciais do ato (protocolo, assunto, status, origem) e abrir o ato original, para entender o contexto sem alternar manualmente entre módulos.

**Why this priority**: Completa o ciclo da integração — quem recebe precisa enxergar o vínculo tão bem quanto quem enviou. Segue o padrão já estabelecido para Ouvidoria e Jurídico (specs 014 e 028).

**Independent Test**: Abrir demanda linked com origem Gabinete na inbox Tramitação; verificar painel formatado, snapshot com labels legíveis e link "Abrir origem" para `/gabinete/atos/:id`.

**Acceptance Scenarios**:

1. **Given** demanda na Tramitação com origem módulo Gabinete, **When** o destinatário abre o detalhe da demanda, **Then** o painel de registro de origem exibe protocolo, assunto, status operacional legível, origem do ato e descrição/resumo capturados no momento da tramitação.
2. **Given** demanda linked de Gabinete, **When** o destinatário clica em "Abrir origem", **Then** é direcionado ao detalhe do ato correspondente em `/gabinete/atos/:id`.
3. **Given** snapshot incompleto (registro legado ou dados mínimos), **When** o painel é exibido, **Then** o sistema tenta complementar com dados atuais do ato; se indisponível, mantém snapshot e informa limitação sem quebrar a tela.
4. **Given** ato de origem removido (soft delete), **When** painel linked record é exibido, **Then** indicador "Origem removida" aparece, link "Abrir origem" é desabilitado e snapshot permanece consultável.

---

### User Story 4 - Tramitar como administrador institucional (Priority: P2)

Como administrador institucional (admin tenant) com acesso ao Gabinete, quero tramitar atos mesmo sem vínculo direto a um setor de usuário, para operar em ambientes de demonstração e gestão centralizada.

**Why this priority**: Admins institucionais operam como usuários do produto mas não possuem linha em `User`; tramitações que gravam FK ou eventos devem respeitar o padrão de actor auditável já aplicado em Ouvidoria e Jurídico.

**Independent Test**: Autenticar como admin institucional; tramitar ato demo; verificar conclusão sem erro de FK ou "setor ativo não definido".

**Acceptance Scenarios**:

1. **Given** admin institucional autenticado sem setores vinculados no perfil, **When** tramita ato informando setor destino e observação, **Then** a operação conclui com sucesso usando setor de origem resolvido automaticamente (setor do Gabinete no tenant ou equivalente operacional).
2. **Given** tramitação por admin institucional, **When** evento é registrado na timeline do ato, **Then** autor auditável reflete o actor real (admin tenant) mesmo quando FK para `User` é nula.

---

### User Story 5 - Dados demo para validação ponta a ponta (Priority: P3)

Como desenvolvedor ou analista de produto em ambiente de demonstração, quero ao menos um ato do Gabinete vinculado a uma demanda de tramitação no seed, para validar o fluxo completo sem cadastro manual.

**Why this priority**: Acelera QA e demos; tenant Jacaranda já possui atos seed e demandas linked para Ouvidoria e Jurídico — falta paridade para Gabinete.

**Independent Test**: Após seed do tenant demo, existe ato cujo ID corresponde a demanda linked visível na Tramitação com origem Gabinete; "Abrir origem" resolve sem erro.

**Acceptance Scenarios**:

1. **Given** tenant demo recém-semeado, **When** operador abre Tramitação → demanda linked Gabinete, **Then** "Abrir origem" resolve para ato existente (sem erro de registro não encontrado).
2. **Given** demanda linked demo Gabinete, **When** painel de origem é exibido, **Then** snapshot contém protocolo, assunto, status e origem com labels legíveis em português.

---

### Edge Cases

- Setor destinatário igual ao setor de origem resolvido: operação bloqueada com mensagem clara ("Não é possível tramitar ao mesmo setor").
- Setor destinatário desativado após tramitação: demanda permanece consultável; novos encaminhamentos devem bloquear setores inválidos.
- Tramitação duplicada do mesmo ato para o mesmo setor: permitida — cada ação gera nova demanda linked e evento distinto na timeline.
- Operador sem permissão no módulo Gabinete tenta abrir origem a partir da Tramitação: acesso negado com mensagem institucional, sem vazar dados sensíveis.
- Ato com controles vinculados (protocolo, numérico, notificação): tramitação encaminha contexto do ato; controles não são duplicados na demanda — snapshot referencia o ato agregador.
- Token de sessão sem setores, mas usuário possui vínculos atualizados: setor de origem resolvido a partir do contexto atual, não apenas do token.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: O sistema DEVE oferecer ação "Tramitar" na lista (`/gabinete/atos`) e no detalhe (`/gabinete/atos/:id`) para atos elegíveis, excluindo rascunhos, arquivados e finalizados.
- **FR-002**: Ao tramitar, o operador DEVE informar setor destinatário (obrigatório) e observação (obrigatória, texto livre descrevendo o motivo do encaminhamento).
- **FR-003**: Cada tramitação bem-sucedida DEVE criar demanda no módulo Tramitação com origem `gabinete`, referência ao ID do ato e snapshot imutável contendo no mínimo: protocolo do ato, assunto, status operacional (código e label legível), origem do ato (quando disponível), descrição/resumo e timestamp de captura.
- **FR-004**: O sistema DEVE atualizar o status do ato para *Em trâmite* após tramitação bem-sucedida e registrar evento `forwarded` na timeline do ato com setor destino, observação e referência auditável ao actor.
- **FR-005**: O sistema DEVE resolver automaticamente o setor de origem da tramitação a partir do contexto do usuário (setor do ato, vínculos do usuário, setor do módulo Gabinete no tenant ou fallback operacional), sem exigir campo adicional no formulário.
- **FR-006**: Após tramitar, o sistema DEVE informar protocolo da demanda criada e oferecer atalho para visualizá-la na Tramitação (detalhe da demanda ou inbox do setor destino).
- **FR-007**: Na Tramitação, demandas com origem Gabinete DEVEM exibir painel de registro de origem formatado (badges de status/origem, campos essenciais, descrição quando houver).
- **FR-008**: O painel linked record DEVE oferecer link "Abrir origem" para `/gabinete/atos/:id` quando o ato ainda existir e o operador tiver permissão ao Gabinete.
- **FR-009**: Quando o ato de origem não existir mais, o painel DEVE exibir indicador "Origem removida" e manter dados do snapshot.
- **FR-010**: O sistema DEVE respeitar permissões de módulo e setor: apenas operadores autorizados ao Gabinete tramitam atos; apenas operadores com acesso ao Gabinete abrem a origem.
- **FR-011**: Tramitações por admin institucional e super admin DEVEM concluir sem violação de FK para `User`, registrando actor auditável nos eventos quando FK for nula.
- **FR-012**: O seed demo DEVE incluir ao menos um ato do Gabinete referenciado por demanda linked na Tramitação, com IDs consistentes entre origem e snapshot.
- **FR-013**: O sistema DEVE bloquear tramitação para o mesmo setor de origem com mensagem compreensível em português.
- **FR-014**: Erros de tramitação DEVEM ser exibidos no modal de forma legível, preservando dados preenchidos pelo operador.

### Key Entities

- **Ato (Gabinete)**: Registro operacional do Gabinete do Presidente com protocolo, assunto, descrição, status, origem, timeline de eventos e encaminhamentos inter-setoriais.
- **Demanda de Tramitação (linked)**: Mensagem inter-setorial com protocolo próprio, vinculada a registro de origem via módulo + ID + snapshot imutável.
- **Snapshot de Origem**: Captura pontual dos metadados do ato no momento da tramitação, preservada mesmo se o ato for alterado ou removido depois.
- **Evento de Ato**: Entrada na timeline (registro, atualização, encaminhamento, mudança de status) com título, descrição, autor e data.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Operador consegue tramitar um ato elegível e localizar a demanda correspondente na Tramitação em menos de 2 minutos, sem suporte técnico.
- **SC-002**: 100% das tramitações bem-sucedidas a partir do Gabinete geram demanda linked com snapshot contendo protocolo, assunto, status legível e origem quando aplicável.
- **SC-003**: Destinatário identifica origem Gabinete e dados essenciais do ato no painel linked record em uma única tela, sem navegar manualmente para outro módulo.
- **SC-004**: Link "Abrir origem" a partir de demanda demo seeded resolve para ato existente em 100% dos casos de validação pós-seed.
- **SC-005**: Tentativas de tramitar ato inelegível (rascunho, arquivado, finalizado) ou para o mesmo setor resultam em mensagem compreensível em 100% dos cenários de teste, sem erro genérico.
- **SC-006**: Admin institucional consegue tramitar ato demo Jacaranda sem erro de FK ou setor ativo indefinido.

## Assumptions

- O padrão de UX e fluxo segue o já estabelecido para Ouvidoria → Tramitação e Jurídico → Tramitação (encaminhar setor + painel linked record + toast com atalho).
- Existe implementação parcial (*stub*) de tramitação no Gabinete; esta feature completa a integração end-to-end, não reinventa o módulo Tramitação.
- Escopo limitado a tramitar atos e linked record — dashboard Gabinete, fiscalização Jatobá, insights Cedro e maturidade Carvalho permanecem fora desta entrega.
- Apenas atos registrados (status ≠ rascunho) são elegíveis; arquivados e finalizados permanecem bloqueados.
- Operadores utilizam setor ativo na sessão ou resolução automática para determinar remetente, conforme demais módulos integrados (spec 027).
- Soft delete do ato não remove demandas já criadas; snapshot garante rastreabilidade histórica.
- Licença base do tenant inclui módulos Gabinete e Tramitação; sub-recursos premium não são pré-requisito desta integração.
- Vocabulário UI permanece **ato/atos**; rotas públicas em `/gabinete/atos/*`.

## Dependencies

- Módulo Tramitação operacional com suporte a demandas linked (origem módulo + ID + snapshot) — spec 014.
- Módulo Gabinete desmockado com CRUD de atos, timeline e API de encaminhamento — spec 012.
- Padrão linked record com hidratação e export PDF — specs 014, 027 e 028.
- Permissões multi-setor e licença de módulo Gabinete configuradas no tenant.

## Out of Scope

- Sincronização bidirecional de status entre Tramitação e Gabinete (ex.: arquivar demanda atualiza ato automaticamente).
- Tramitação em lote de múltiplos atos.
- Notificações por e-mail ou push ao receber demanda linked (coberto pela spec 029 quando disponível).
- Tramitação de cadastros auxiliares isolados (protocolo, controle numérico, documento tramitado) sem passar pelo ato agregador.
- Alteração do vocabulário ou rotas do Gabinete.
