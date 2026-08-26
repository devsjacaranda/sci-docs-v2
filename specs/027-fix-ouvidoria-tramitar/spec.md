# Feature Specification: Corrigir tramitação de manifestações na Ouvidoria

**Feature Branch**: `027-fix-ouvidoria-tramitar`

**Created**: 2026-07-01

**Status**: Draft

**Tipo**: Bug

**Módulo**: Ouvidoria — manifestações

**Input**: User description: "Ao tramitar manifestação na Ouvidoria, o sistema retorna erro 'Setor ativo não definido' (400) mesmo com setor destino selecionado. Endpoint afetado: encaminhar manifestação. Manifestação de exemplo: protocolo interno 11111111-1111-1111-1111-000000000018."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Tramitar manifestação com sucesso (Priority: P1)

Como servidor com acesso ao módulo Ouvidoria, preciso **encaminhar uma manifestação** informando setor destino e observação, para que a demanda siga o fluxo operacional e uma demanda vinculada seja criada no módulo Tramitação.

**Why this priority**: Tramitação é ação central da licença Base da Ouvidoria (spec 003). Sem ela, manifestações ficam paradas em análise e o ciclo operacional quebra.

**Independent Test**: Abrir detalhe de manifestação em status *Em análise* ou *Tramitando*; acionar **Tramitar manifestação**; selecionar setor destino (ex.: Jurídico); preencher observação; confirmar. Verificar status atualizado, evento na timeline e demanda vinculada na Tramitação — **sem** mensagem de erro sobre setor ativo.

**Acceptance Scenarios**:

1. **Given** manifestação elegível para encaminhamento e usuário autenticado com permissão ao módulo Ouvidoria, **When** confirma tramitação com setor destino e observação válidos, **Then** a operação conclui com sucesso, status passa a *Tramitando*, evento de encaminhamento aparece na timeline e demanda vinculada é criada na Tramitação.
2. **Given** servidor vinculado a um ou mais setores operacionais, **When** tramita manifestação, **Then** o setor de origem da tramitação é determinado automaticamente a partir do contexto do usuário (vínculo direto ou equivalente operacional), sem exigir seleção manual de "setor ativo".
3. **Given** manifestação já encaminhada anteriormente, **When** servidor tramita novamente para outro setor destino, **Then** novo encaminhamento é registrado na timeline e nova demanda vinculada é criada, mantendo histórico anterior.

---

### User Story 2 - Tramitar como administrador institucional (Priority: P1)

Como administrador institucional (admin tenant) com acesso amplo aos módulos, preciso **tramitar manifestações** mesmo sem vínculo direto a um setor de usuário, para operar a ouvidoria em ambientes de demonstração e gestão centralizada.

**Why this priority**: Admins institucionais têm bypass de permissão por módulo, mas hoje falham na tramitação por ausência de setor no token — bloqueio observado em ambiente de desenvolvimento com tenant Jacaranda.

**Independent Test**: Autenticar como admin institucional do tenant; abrir manifestação; tramitar para setor destino. Verificar conclusão sem erro "Setor ativo não definido".

**Acceptance Scenarios**:

1. **Given** usuário admin institucional autenticado sem setores vinculados no perfil, **When** tramita manifestação informando setor destino e observação, **Then** a operação conclui com sucesso usando setor de origem resolvido automaticamente (setor da Ouvidoria do tenant ou equivalente operacional).
2. **Given** admin institucional que também é chefe de setor, **When** tramita manifestação, **Then** o setor de origem reflete o vínculo de chefia quando aplicável, antes de recorrer a fallbacks institucionais.

---

### User Story 3 - Feedback claro quando tramitação não é possível (Priority: P2)

Como servidor da Ouvidoria, preciso receber **mensagem acionável** quando a tramitação não puder ser concluída por falta de contexto de setor, para saber o que corrigir em vez de ver erro genérico após preencher o formulário.

**Why this priority**: O modal já exige setor destino; erro sobre "setor ativo" confunde porque o usuário acredita ter preenchido o campo correto. Mensagem clara reduz retrabalho e chamados de suporte.

**Independent Test**: Simular tenant sem setores cadastrados ou usuário sem nenhum contexto resolvível; tentar tramitar; verificar mensagem orientando cadastro de setores ou vínculo do usuário — não apenas código de erro técnico.

**Acceptance Scenarios**:

1. **Given** tenant sem nenhum setor operacional cadastrado, **When** usuário tenta tramitar manifestação, **Then** recebe mensagem explicando que é necessário cadastrar setores antes de tramitar, em linguagem operacional.
2. **Given** usuário comum sem vínculo a setor e sem fallback institucional disponível, **When** tenta tramitar, **Then** recebe orientação para solicitar vínculo a um setor autorizado na Ouvidoria, em vez de mensagem ambígua após confirmação do modal.
3. **Given** erro de validação ou impossibilidade de resolver setor de origem, **When** exibido no modal de tramitação, **Then** o formulário permanece preenchido para correção ou nova tentativa, sem perda dos dados informados.

---

### Edge Cases

- Usuário com múltiplos setores vinculados: setor de origem deve ser o setor da Ouvidoria quando o usuário pertence a ele; caso contrário, primeiro setor operacional válido do usuário ou setor onde é chefe.
- Manifestação em status *Encerrado* ou *Rascunho*: tramitação deve ser rejeitada com mensagem de status inválido (comportamento existente preservado).
- Setor destino igual ao setor de origem resolvido: operação permitida (encaminhamento interno) desde que observação informada.
- Token de sessão desatualizado sem setores, mas usuário possui vínculos atualizados no banco: sistema deve resolver setor a partir do contexto atual do usuário, não apenas do token.
- Tenant de demonstração (Jacaranda): usuários seed e admin institucional devem conseguir tramitar manifestações de exemplo, incluindo a manifestação `11111111-1111-1111-1111-000000000018`.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: O sistema MUST permitir tramitar manifestação elegível quando o usuário possui permissão ao módulo Ouvidoria e informa setor destino e observação válidos.
- **FR-002**: O sistema MUST resolver automaticamente o **setor de origem** da tramitação a partir do contexto do usuário autenticado, sem exigir campo adicional no formulário de encaminhamento.
- **FR-003**: A resolução do setor de origem MUST seguir ordem de prioridade: (1) setor explicitamente definido na requisição quando suportado; (2) setores vinculados ao usuário; (3) setores onde o usuário é chefe; (4) setor vinculado ao módulo Ouvidoria no tenant; (5) primeiro setor operacional válido do tenant.
- **FR-004**: O sistema MUST aplicar a mesma política de resolução de setor de origem usada nas operações de tramitação do módulo Tramitação, garantindo consistência entre módulos.
- **FR-005**: Usuários admin institucional MUST conseguir tramitar manifestações mesmo sem setores vinculados diretamente ao perfil, desde que exista setor operacional resolvível no tenant.
- **FR-006**: Ao tramitar com sucesso, o sistema MUST: atualizar status da manifestação para *Tramitando*; registrar evento na timeline com autor, data, setor destino e observação; criar demanda vinculada no módulo Tramitação com protocolo retornável ao client.
- **FR-007**: O sistema MUST rejeitar tramitação de manifestações em status *Rascunho* ou *Encerrado* com mensagem de transição inválida (sem alterar comportamento já especificado na spec 003).
- **FR-008**: Quando nenhum setor de origem puder ser resolvido, o sistema MUST retornar mensagem em português, acionável e distinta de erro de setor destino, orientando cadastro de setores ou vínculo do usuário.
- **FR-009**: O modal **Tramitar manifestação** MUST exibir erros retornados pelo servidor de forma legível, preservando os dados preenchidos pelo usuário.
- **FR-010**: O sistema MUST registrar testes automatizados cobrindo tramitação bem-sucedida para usuário com setor vinculado e para admin institucional sem setor vinculado.

### Key Entities

- **Manifestação**: registro da ouvidoria com status operacional, timeline de eventos e elegibilidade para encaminhamento.
- **Setor**: unidade organizacional de origem (quem tramita) e destino (para quem encaminha); vinculado a módulos via permissão por setor.
- **Evento de timeline**: registro auditável de encaminhamento com observação, autor e setor destino.
- **Demanda vinculada (Tramitação)**: demanda criada automaticamente ao encaminhar, com referência à manifestação de origem e protocolo próprio.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% das tentativas de tramitação por usuários com permissão ao módulo Ouvidoria e tenant com setores cadastrados concluem com sucesso, sem erro "Setor ativo não definido".
- **SC-002**: Admin institucional consegue tramitar manifestação de demonstração Jacaranda em menos de 1 minuto, do clique em **Confirmar tramitação** até exibição de protocolo da demanda vinculada.
- **SC-003**: 0 ocorrências do erro "Setor ativo não definido" em cenários onde o tenant possui setor da Ouvidoria cadastrado e usuário tem permissão ao módulo.
- **SC-004**: Em cenários genuinamente impossíveis (tenant sem setores), 100% dos usuários recebem mensagem orientativa compreensível, avaliável por revisão de copy sem conhecimento técnico.
- **SC-005**: Fluxo completo encaminhar → timeline atualizada → demanda na Tramitação permanece funcional conforme critérios da spec 003 (regressão zero).

## Assumptions

- O bug afeta principalmente usuários cujo token não carrega `setorIds` (ex.: admin institucional) ou sessões desatualizadas; a correção alinha Ouvidoria ao comportamento já existente no módulo Tramitação para resolução de setor.
- Setor destino continua sendo selecionado manualmente no modal; apenas o setor de **origem** é resolvido automaticamente.
- Escopo limitado à ação **Encaminhar/Tramitar**; ações **Responder** e **Encerrar** permanecem inalteradas nesta correção.
- Tenant Jacaranda (demonstração) possui setor Ouvidoria (OUV) cadastrado e vinculado ao módulo — conforme seed existente.
- Não há mudança de regras de licença ou permissão por módulo; apenas correção da resolução de setor de origem na tramitação.

## Escopo ampliado (entregue na mesma feature)

Durante validação manual pós-fix, foram corrigidos e entregues:

- **Erro 500 pós-tramitar** para `admin_tenant`: FK `ManifestacaoEvento_autorUserId_fkey` — resolução de `userTableId` opcional (padrão Gabinete/IT).
- **Navegação pós-tramitar**: redirect automático para detalhe da demanda na Tramitação.
- **Aba Vínculos (TRAM)**: `LinkedRecordPanel` com snapshot v2 da manifestação, hidratação para registros legados e export PDF client-side (contrato spec 014).

## Referências

- Spec original Ouvidoria Base: `civ2-docs/specs/arquivados/003-ouvidoria/spec.md` (User Story 4 — Tramitar, responder e encerrar)
- Contrato API encaminhar: `civ2-docs/specs/arquivados/003-ouvidoria/contracts/rest-api-ouvidoria.md`
