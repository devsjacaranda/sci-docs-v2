# Feature Specification: Corrigir tramitaÃ§Ã£o de manifestaÃ§Ãµes na Ouvidoria

**Feature Branch**: `027-fix-ouvidoria-tramitar`

**Created**: 2026-07-01

**Status**: Completed

**Tipo**: Bug

**MÃ³dulo**: Ouvidoria â€” manifestaÃ§Ãµes

**Input**: User description: "Ao tramitar manifestaÃ§Ã£o na Ouvidoria, o sistema retorna erro 'Setor ativo nÃ£o definido' (400) mesmo com setor destino selecionado. Endpoint afetado: encaminhar manifestaÃ§Ã£o. ManifestaÃ§Ã£o de exemplo: protocolo interno 11111111-1111-1111-1111-000000000018."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Tramitar manifestaÃ§Ã£o com sucesso (Priority: P1)

Como servidor com acesso ao mÃ³dulo Ouvidoria, preciso **encaminhar uma manifestaÃ§Ã£o** informando setor destino e observaÃ§Ã£o, para que a demanda siga o fluxo operacional e uma demanda vinculada seja criada no mÃ³dulo TramitaÃ§Ã£o.

**Why this priority**: TramitaÃ§Ã£o Ã© aÃ§Ã£o central da licenÃ§a Base da Ouvidoria (spec 003). Sem ela, manifestaÃ§Ãµes ficam paradas em anÃ¡lise e o ciclo operacional quebra.

**Independent Test**: Abrir detalhe de manifestaÃ§Ã£o em status *Em anÃ¡lise* ou *Tramitando*; acionar **Tramitar manifestaÃ§Ã£o**; selecionar setor destino (ex.: JurÃ­dico); preencher observaÃ§Ã£o; confirmar. Verificar status atualizado, evento na timeline e demanda vinculada na TramitaÃ§Ã£o â€” **sem** mensagem de erro sobre setor ativo.

**Acceptance Scenarios**:

1. **Given** manifestaÃ§Ã£o elegÃ­vel para encaminhamento e usuÃ¡rio autenticado com permissÃ£o ao mÃ³dulo Ouvidoria, **When** confirma tramitaÃ§Ã£o com setor destino e observaÃ§Ã£o vÃ¡lidos, **Then** a operaÃ§Ã£o conclui com sucesso, status passa a *Tramitando*, evento de encaminhamento aparece na timeline e demanda vinculada Ã© criada na TramitaÃ§Ã£o.
2. **Given** servidor vinculado a um ou mais setores operacionais, **When** tramita manifestaÃ§Ã£o, **Then** o setor de origem da tramitaÃ§Ã£o Ã© determinado automaticamente a partir do contexto do usuÃ¡rio (vÃ­nculo direto ou equivalente operacional), sem exigir seleÃ§Ã£o manual de "setor ativo".
3. **Given** manifestaÃ§Ã£o jÃ¡ encaminhada anteriormente, **When** servidor tramita novamente para outro setor destino, **Then** novo encaminhamento Ã© registrado na timeline e nova demanda vinculada Ã© criada, mantendo histÃ³rico anterior.

---

### User Story 2 - Tramitar como administrador institucional (Priority: P1)

Como administrador institucional (admin tenant) com acesso amplo aos mÃ³dulos, preciso **tramitar manifestaÃ§Ãµes** mesmo sem vÃ­nculo direto a um setor de usuÃ¡rio, para operar a ouvidoria em ambientes de demonstraÃ§Ã£o e gestÃ£o centralizada.

**Why this priority**: Admins institucionais tÃªm bypass de permissÃ£o por mÃ³dulo, mas hoje falham na tramitaÃ§Ã£o por ausÃªncia de setor no token â€” bloqueio observado em ambiente de desenvolvimento com tenant Jacaranda.

**Independent Test**: Autenticar como admin institucional do tenant; abrir manifestaÃ§Ã£o; tramitar para setor destino. Verificar conclusÃ£o sem erro "Setor ativo nÃ£o definido".

**Acceptance Scenarios**:

1. **Given** usuÃ¡rio admin institucional autenticado sem setores vinculados no perfil, **When** tramita manifestaÃ§Ã£o informando setor destino e observaÃ§Ã£o, **Then** a operaÃ§Ã£o conclui com sucesso usando setor de origem resolvido automaticamente (setor da Ouvidoria do tenant ou equivalente operacional).
2. **Given** admin institucional que tambÃ©m Ã© chefe de setor, **When** tramita manifestaÃ§Ã£o, **Then** o setor de origem reflete o vÃ­nculo de chefia quando aplicÃ¡vel, antes de recorrer a fallbacks institucionais.

---

### User Story 3 - Feedback claro quando tramitaÃ§Ã£o nÃ£o Ã© possÃ­vel (Priority: P2)

Como servidor da Ouvidoria, preciso receber **mensagem acionÃ¡vel** quando a tramitaÃ§Ã£o nÃ£o puder ser concluÃ­da por falta de contexto de setor, para saber o que corrigir em vez de ver erro genÃ©rico apÃ³s preencher o formulÃ¡rio.

**Why this priority**: O modal jÃ¡ exige setor destino; erro sobre "setor ativo" confunde porque o usuÃ¡rio acredita ter preenchido o campo correto. Mensagem clara reduz retrabalho e chamados de suporte.

**Independent Test**: Simular tenant sem setores cadastrados ou usuÃ¡rio sem nenhum contexto resolvÃ­vel; tentar tramitar; verificar mensagem orientando cadastro de setores ou vÃ­nculo do usuÃ¡rio â€” nÃ£o apenas cÃ³digo de erro tÃ©cnico.

**Acceptance Scenarios**:

1. **Given** tenant sem nenhum setor operacional cadastrado, **When** usuÃ¡rio tenta tramitar manifestaÃ§Ã£o, **Then** recebe mensagem explicando que Ã© necessÃ¡rio cadastrar setores antes de tramitar, em linguagem operacional.
2. **Given** usuÃ¡rio comum sem vÃ­nculo a setor e sem fallback institucional disponÃ­vel, **When** tenta tramitar, **Then** recebe orientaÃ§Ã£o para solicitar vÃ­nculo a um setor autorizado na Ouvidoria, em vez de mensagem ambÃ­gua apÃ³s confirmaÃ§Ã£o do modal.
3. **Given** erro de validaÃ§Ã£o ou impossibilidade de resolver setor de origem, **When** exibido no modal de tramitaÃ§Ã£o, **Then** o formulÃ¡rio permanece preenchido para correÃ§Ã£o ou nova tentativa, sem perda dos dados informados.

---

### Edge Cases

- UsuÃ¡rio com mÃºltiplos setores vinculados: setor de origem deve ser o setor da Ouvidoria quando o usuÃ¡rio pertence a ele; caso contrÃ¡rio, primeiro setor operacional vÃ¡lido do usuÃ¡rio ou setor onde Ã© chefe.
- ManifestaÃ§Ã£o em status *Encerrado* ou *Rascunho*: tramitaÃ§Ã£o deve ser rejeitada com mensagem de status invÃ¡lido (comportamento existente preservado).
- Setor destino igual ao setor de origem resolvido: operaÃ§Ã£o permitida (encaminhamento interno) desde que observaÃ§Ã£o informada.
- Token de sessÃ£o desatualizado sem setores, mas usuÃ¡rio possui vÃ­nculos atualizados no banco: sistema deve resolver setor a partir do contexto atual do usuÃ¡rio, nÃ£o apenas do token.
- Tenant de demonstraÃ§Ã£o (Jacaranda): usuÃ¡rios seed e admin institucional devem conseguir tramitar manifestaÃ§Ãµes de exemplo, incluindo a manifestaÃ§Ã£o `11111111-1111-1111-1111-000000000018`.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: O sistema MUST permitir tramitar manifestaÃ§Ã£o elegÃ­vel quando o usuÃ¡rio possui permissÃ£o ao mÃ³dulo Ouvidoria e informa setor destino e observaÃ§Ã£o vÃ¡lidos.
- **FR-002**: O sistema MUST resolver automaticamente o **setor de origem** da tramitaÃ§Ã£o a partir do contexto do usuÃ¡rio autenticado, sem exigir campo adicional no formulÃ¡rio de encaminhamento.
- **FR-003**: A resoluÃ§Ã£o do setor de origem MUST seguir ordem de prioridade: (1) setor explicitamente definido na requisiÃ§Ã£o quando suportado; (2) setores vinculados ao usuÃ¡rio; (3) setores onde o usuÃ¡rio Ã© chefe; (4) setor vinculado ao mÃ³dulo Ouvidoria no tenant; (5) primeiro setor operacional vÃ¡lido do tenant.
- **FR-004**: O sistema MUST aplicar a mesma polÃ­tica de resoluÃ§Ã£o de setor de origem usada nas operaÃ§Ãµes de tramitaÃ§Ã£o do mÃ³dulo TramitaÃ§Ã£o, garantindo consistÃªncia entre mÃ³dulos.
- **FR-005**: UsuÃ¡rios admin institucional MUST conseguir tramitar manifestaÃ§Ãµes mesmo sem setores vinculados diretamente ao perfil, desde que exista setor operacional resolvÃ­vel no tenant.
- **FR-006**: Ao tramitar com sucesso, o sistema MUST: atualizar status da manifestaÃ§Ã£o para *Tramitando*; registrar evento na timeline com autor, data, setor destino e observaÃ§Ã£o; criar demanda vinculada no mÃ³dulo TramitaÃ§Ã£o com protocolo retornÃ¡vel ao client.
- **FR-007**: O sistema MUST rejeitar tramitaÃ§Ã£o de manifestaÃ§Ãµes em status *Rascunho* ou *Encerrado* com mensagem de transiÃ§Ã£o invÃ¡lida (sem alterar comportamento jÃ¡ especificado na spec 003).
- **FR-008**: Quando nenhum setor de origem puder ser resolvido, o sistema MUST retornar mensagem em portuguÃªs, acionÃ¡vel e distinta de erro de setor destino, orientando cadastro de setores ou vÃ­nculo do usuÃ¡rio.
- **FR-009**: O modal **Tramitar manifestaÃ§Ã£o** MUST exibir erros retornados pelo servidor de forma legÃ­vel, preservando os dados preenchidos pelo usuÃ¡rio.
- **FR-010**: O sistema MUST registrar testes automatizados cobrindo tramitaÃ§Ã£o bem-sucedida para usuÃ¡rio com setor vinculado e para admin institucional sem setor vinculado.

### Key Entities

- **ManifestaÃ§Ã£o**: registro da ouvidoria com status operacional, timeline de eventos e elegibilidade para encaminhamento.
- **Setor**: unidade organizacional de origem (quem tramita) e destino (para quem encaminha); vinculado a mÃ³dulos via permissÃ£o por setor.
- **Evento de timeline**: registro auditÃ¡vel de encaminhamento com observaÃ§Ã£o, autor e setor destino.
- **Demanda vinculada (TramitaÃ§Ã£o)**: demanda criada automaticamente ao encaminhar, com referÃªncia Ã  manifestaÃ§Ã£o de origem e protocolo prÃ³prio.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% das tentativas de tramitaÃ§Ã£o por usuÃ¡rios com permissÃ£o ao mÃ³dulo Ouvidoria e tenant com setores cadastrados concluem com sucesso, sem erro "Setor ativo nÃ£o definido".
- **SC-002**: Admin institucional consegue tramitar manifestaÃ§Ã£o de demonstraÃ§Ã£o Jacaranda em menos de 1 minuto, do clique em **Confirmar tramitaÃ§Ã£o** atÃ© exibiÃ§Ã£o de protocolo da demanda vinculada.
- **SC-003**: 0 ocorrÃªncias do erro "Setor ativo nÃ£o definido" em cenÃ¡rios onde o tenant possui setor da Ouvidoria cadastrado e usuÃ¡rio tem permissÃ£o ao mÃ³dulo.
- **SC-004**: Em cenÃ¡rios genuinamente impossÃ­veis (tenant sem setores), 100% dos usuÃ¡rios recebem mensagem orientativa compreensÃ­vel, avaliÃ¡vel por revisÃ£o de copy sem conhecimento tÃ©cnico.
- **SC-005**: Fluxo completo encaminhar â†’ timeline atualizada â†’ demanda na TramitaÃ§Ã£o permanece funcional conforme critÃ©rios da spec 003 (regressÃ£o zero).

## Assumptions

- O bug afeta principalmente usuÃ¡rios cujo token nÃ£o carrega `setorIds` (ex.: admin institucional) ou sessÃµes desatualizadas; a correÃ§Ã£o alinha Ouvidoria ao comportamento jÃ¡ existente no mÃ³dulo TramitaÃ§Ã£o para resoluÃ§Ã£o de setor.
- Setor destino continua sendo selecionado manualmente no modal; apenas o setor de **origem** Ã© resolvido automaticamente.
- Escopo limitado Ã  aÃ§Ã£o **Encaminhar/Tramitar**; aÃ§Ãµes **Responder** e **Encerrar** permanecem inalteradas nesta correÃ§Ã£o.
- Tenant Jacaranda (demonstraÃ§Ã£o) possui setor Ouvidoria (OUV) cadastrado e vinculado ao mÃ³dulo â€” conforme seed existente.
- NÃ£o hÃ¡ mudanÃ§a de regras de licenÃ§a ou permissÃ£o por mÃ³dulo; apenas correÃ§Ã£o da resoluÃ§Ã£o de setor de origem na tramitaÃ§Ã£o.

## Escopo ampliado (entregue na mesma feature)

Durante validação manual pós-fix:

- **Erro 500 pós-tramitar** para `admin_tenant`: FK `ManifestacaoEvento_autorUserId_fkey` — `resolveUserTableId` opcional.
- **Navegação pós-tramitar**: redirect para detalhe da demanda na Tramitação.
- **Aba Vínculos (TRAM)**: `LinkedRecordPanel` com snapshot v2, hidratação para registros legados e export PDF client-side (contrato spec 014).

## ReferÃªncias

- Spec original Ouvidoria Base: `civ2-docs/specs/arquivados/003-ouvidoria/spec.md` (User Story 4 â€” Tramitar, responder e encerrar)
- Contrato API encaminhar: `civ2-docs/specs/arquivados/003-ouvidoria/contracts/rest-api-ouvidoria.md`
