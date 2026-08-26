# Tasks: Tramitação como Protocolo

**Input**: Design documents from `civ2-docs/specs/035-tramitacao-protocolo/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/protocolo-api.md, quickstart.md

**Tests**: TDD obrigatório (Constitution II — RED → GREEN → REFACTOR). Skills: `tdd`, `testing-conventions` (API), Vitest no client.

**Organization**: Tasks agrupadas por user story (spec.md) para permitir implementação e teste independentes de cada uma. Reconciliação da feature 034 (desentranhamento) tratada como fase própria, cross-cutting, por não ser uma US desta spec.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Pode rodar em paralelo (arquivos diferentes, sem dependência)
- **[Story]**: US1–US8 conforme spec.md. Setup/Foundational/Desentranhamento/Polish não levam label.

## Path Conventions

- **API**: `ci-api-v2/src/modules/tramitacao/` (e `ci-api-v2/src/modules/notificacao/`, `ci-api-v2/src/modules/shared/storage/`)
- **Client**: `ci-client-v2/apps/web/src/modules/tramitacao/`
- **Schema**: `ci-api-v2/prisma/schema/`

---

## Phase 1: Setup

**Purpose**: Preparar dependências e remover artefatos obsoletos do modelo antigo antes do reset de schema

- [X] T001 Adicionar dependência `jszip` em `ci-api-v2/package.json` e rodar `npm install` (research.md §8)
- [X] T002 [P] Remover diretório obsoleto `ci-client-v2/apps/web/src/modules/tramitacao/mockdown/` e suas referências em `pages/TramitacaoProcessosMockdownPage.tsx` + rota `/tramitacao/processos-mockdown` em `router.tsx` (research.md §12)
- [X] T003 [P] Remover hook obsoleto `ci-client-v2/apps/web/src/modules/tramitacao/hooks/useTramitacaoInboxMode.ts` (conceito de `inboxMode`/pastas não existe mais) — removido junto com `TramitacaoInboxWorkspace`, `api/demandas.ts` e páginas legadas; redirects `/tramitacao/demandas*` mantidos em `router.tsx`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Schema Prisma, migration de reset, libs/repositories base e esqueletos de contrato — bloqueia todas as user stories

**⚠️ CRITICAL**: Nenhuma user story pode começar antes desta fase

### Schema e migration

- [X] T004 Reescrever `ci-api-v2/prisma/schema/tramitacao.prisma` com `TramitacaoProtocolo`, `TramitacaoProtocoloSetor`, `TramitacaoProtocoloGestor`, `TramitacaoProtocoloEvento` (+ enum `TramitacaoProtocoloEventoTipo`), `TramitacaoProtocoloAnexo`, `TramitacaoProtocoloAnexoAccess`, `TramitacaoProtocoloAnexoDesentranhamento` (+ enum `TramitacaoDesentranhamentoDirection` renomeado) conforme `data-model.md`
- [X] T005 [P] Atualizar enum `NotificacaoType` em `ci-api-v2/prisma/schema/notificacao.prisma` conforme research.md §7 (novos tipos `tramitacao_protocolo_*`, remoção de `tramitacao_pessoal_encaminhada`)
- [X] T006 Gerar migration `tramitacao_protocolo_reset` (DROP das tabelas/enums antigos de `TramitacaoDemanda*` + CREATE das novas entidades) em `ci-api-v2/prisma/migrations/` e rodar `npx prisma generate` em `ci-api-v2/`

### Libs compartilhadas

- [X] T007 [P] Implementar `canManageProtocolo(protocolo, gestores, actor)` em `ci-api-v2/src/modules/tramitacao/lib/can-manage-protocolo.ts` (research.md §3)
- [X] T008 [P] Escrever testes unitários RED para `can-manage-protocolo.spec.ts` (autor implícito, gestor concedido, participante sem gestão)
- [X] T009 [P] Adaptar `resolve-desentranhamento-approvers.ts` para o modelo N-participantes (aprovadores = todos os demais participantes quando solicitante é autor do anexo; autor do anexo quando solicitante é outro participante) em `ci-api-v2/src/modules/tramitacao/lib/resolve-desentranhamento-approvers.ts` (research.md §6)
- [X] T010 [P] Atualizar testes RED de `resolve-desentranhamento-approvers.spec.ts` para os novos cenários (setorial N-participantes, pessoal 1:1)
- [X] T011 [P] Ajustar `resolve-anexo-access.ts` apenas na FK pai (`protocoloId`), preservando 100% a lógica de confidencialidade/desentranhamento (033/034) em `ci-api-v2/src/modules/tramitacao/lib/resolve-anexo-access.ts`
- [X] T012 [P] Validar que `generate-protocol-number.ts` continua válido sem mudanças (apenas a tabela de sequence é renomeada) — atualizar apenas o nome do repository consumidor

### Repositories

- [X] T013 Implementar `ProtocoloRepository` (`create`, `findById`, `update`) em `ci-api-v2/src/modules/tramitacao/repository/protocolo.repositories.ts`
- [X] T014 [P] Implementar `SetorParticipanteRepository` (`create`, `listByProtocolo`, `exists`) em `ci-api-v2/src/modules/tramitacao/repository/setor-participante.repositories.ts`
- [X] T015 [P] Implementar `GestorRepository` (`create`, `listByProtocolo`, `exists`) em `ci-api-v2/src/modules/tramitacao/repository/gestor.repositories.ts`
- [X] T016 Implementar `EventoRepository` (`create`, `listByProtocolo`) em `ci-api-v2/src/modules/tramitacao/repository/evento.repositories.ts`
- [X] T017 [P] Adaptar `anexo.repositories.ts` e `desentranhamento.repositories.ts` para a FK `protocoloId` (renome de `demandaId`), sem mudança de lógica — concluído na Fase 11; rotas presign/confirm/link/download adicionadas na Fase 12

### Storage e notificações

- [X] T018 Adicionar `getObjectBuffer(storageKey)` em `ci-api-v2/src/modules/shared/storage/storage.service.ts` (+ interface em `storage.port.ts`), análogo ao `getObjectText` já existente (research.md §8)
- [X] T019 [P] Adaptar `ResolveTramitacaoRecipientsService` para resolver destinatários por N-setores participantes e por protocolo pessoal em `ci-api-v2/src/modules/notificacao/services/resolve-tramitacao-recipients.service.ts`
- [X] T020 [P] Adaptar `TramitacaoNotificacaoService` com os novos métodos/tipos (`notifySetorIncluido`, `notifyAtualizacao`, `notifyEncerrado`, `notifyPessoalAberto`, `notifyPessoalAtualizacao`) em `ci-api-v2/src/modules/notificacao/services/tramitacao-notificacao.service.ts`
- [X] T021 [P] Atualizar `TYPE_LABELS` em `ci-api-v2/src/modules/notificacao/notificacao.mapper.ts` para os novos tipos de notificação

### Esqueletos de contrato

- [X] T022 Reescrever `ci-api-v2/src/modules/tramitacao/tramitacao.schemas.ts` com `createProtocoloBodySchema`, `addAtualizacaoBodySchema`, `incluirSetorBodySchema`, `concederGestorBodySchema`, `entranharBodySchema`, `encerrarBodySchema` + DTOs `createZodDto`
- [X] T023 Reescrever `ci-api-v2/src/modules/tramitacao/tramitacao.mapper.ts` com `mapProtocoloListItem`, `mapProtocoloDetail`, `mapProtocoloTimelineEvent` (contracts/protocolo-api.md)
- [X] T024 Registrar os novos repositories/use-cases (a implementar por fase) em `ci-api-v2/src/modules/tramitacao/tramitacao.module.ts`
- [X] T025 [P] Reescrever esqueleto de `ci-client-v2/apps/web/src/modules/tramitacao/api/protocolos.ts` (tipos `ProtocoloListItem`/`ProtocoloDetail`/`ProtocoloTimelineEvent`, substitui `api/demandas.ts`)
- [X] T026 [P] Ajustar `ci-client-v2/apps/web/src/modules/tramitacao/lib/tramitacao-routes.ts` para `/tramitacao/protocolos` (remove `folder`/`inboxMode`, mantém `q`/`status`/`sectorId`)

**Checkpoint**: Fundação pronta — implementação das user stories pode começar

---

## Phase 3: User Story 1 — Abrir um novo protocolo interno (Priority: P1) 🎯 MVP

**Goal**: Operador abre um protocolo (setorial ou pessoal) informando assunto e participantes; protocolo aparece em "Meus protocolos" com número único e status "Aberto"

**Independent Test**: Abrir um protocolo setorial com 2 setores e um protocolo pessoal 1:1; confirmar número único, status "Aberto" e evento `aberto` na timeline de ambos (ver quickstart.md Cenário 1, passos 1–3)

### Tests for User Story 1 ⚠️

- [X] T027 [P] [US1] Teste de integração RED — abrir protocolo setorial com múltiplos setores em `ci-api-v2/src/modules/tramitacao/test/abrir-protocolo-setorial.integration.spec.ts`
- [X] T028 [P] [US1] Teste de integração RED — validações de abertura (`SUBJECT_REQUIRED`, `AT_LEAST_ONE_SECTOR_REQUIRED`) em `ci-api-v2/src/modules/tramitacao/test/abrir-protocolo-validacao.integration.spec.ts`

### Implementation for User Story 1

- [X] T029 [US1] Implementar `OpenProtocoloUseCase` (branch setorial: `FindSectorRepository` + `AllocateProtocolNumberRepository` + `ProtocoloRepository.create` + `SetorParticipanteRepository.create` (N) + `EventoRepository.create('aberto')`) em `ci-api-v2/src/modules/tramitacao/use-cases/open-protocolo.use-case.ts`
- [X] T030 [US1] Implementar rota `POST /tramitacao/protocolos` em `tramitacao.controller.ts`
- [X] T031 [P] [US1] Disparar notificação `tramitacao_protocolo_setor_incluido` na abertura setorial via `TramitacaoNotificacaoService`
- [X] T032 [P] [US1] Implementar `createProtocolo` em `ci-client-v2/apps/web/src/modules/tramitacao/api/protocolos.ts`
- [X] T033 [US1] Implementar `TramitacaoAbrirProtocoloForm.tsx` (assunto, seleção de setores, anexos staged) em `ci-client-v2/apps/web/src/modules/tramitacao/components/`
- [X] T034 [US1] Implementar `TramitacaoAbrirProtocoloPage.tsx` e registrar rota `/tramitacao/protocolos/novo` em `pages/` e `router.tsx`
- [X] T035 [P] [US1] Teste Vitest de `TramitacaoAbrirProtocoloForm` (validação de assunto/setor obrigatórios) em `components/__tests__/TramitacaoAbrirProtocoloForm.test.tsx`

**Checkpoint**: User Story 1 funcional e testável de forma independente (MVP)

---

## Phase 4: User Story 2 — Incluir setores e colaborar dentro do protocolo (Priority: P1)

**Goal**: Participantes de setores incluídos veem o protocolo e adicionam atualizações; gestores incluem novos setores; protocolo encerrado bloqueia escrita

**Independent Test**: Com protocolo do US1, incluir Setor B; membro de A e B adicionam mensagens visíveis a todos (quickstart.md Cenário 1, passos 4–6 + Cenário 2)

### Tests for User Story 2 ⚠️

- [X] T036 [P] [US2] Teste de integração RED — atualização adicionada por qualquer participante fica visível a todos em `ci-api-v2/src/modules/tramitacao/test/adicionar-atualizacao.integration.spec.ts`
- [X] T037 [P] [US2] Teste de integração RED — incluir setor por gestor vs. `403 FORBIDDEN_NOT_MANAGER` para não-gestor em `ci-api-v2/src/modules/tramitacao/test/incluir-setor.integration.spec.ts`
- [X] T038 [P] [US2] Teste de integração RED — atualização/inclusão de setor bloqueada em protocolo encerrado (`409 PROTOCOLO_ENCERRADO`) em `ci-api-v2/src/modules/tramitacao/test/protocolo-encerrado-bloqueia-escrita.integration.spec.ts`

### Implementation for User Story 2

- [X] T039 [US2] Implementar `AddAtualizacaoUseCase` em `ci-api-v2/src/modules/tramitacao/use-cases/add-atualizacao.use-case.ts`
- [X] T040 [US2] Implementar `IncluirSetorUseCase` (valida `canManageProtocolo`, `tipo=setorial`, `status=aberto`, `SECTOR_ALREADY_INCLUDED`) em `ci-api-v2/src/modules/tramitacao/use-cases/incluir-setor.use-case.ts`
- [X] T041 [US2] Implementar `GetProtocoloDetailUseCase` (timeline completa, `canManage`, participantes) em `ci-api-v2/src/modules/tramitacao/use-cases/get-protocolo-detail.use-case.ts`
- [X] T042 [US2] Implementar rotas `POST /tramitacao/protocolos/:id/atualizacoes`, `POST /tramitacao/protocolos/:id/setores` e `GET /tramitacao/protocolos/:id` em `tramitacao.controller.ts`
- [X] T043 [P] [US2] Disparar notificações `tramitacao_protocolo_atualizacao` e `tramitacao_protocolo_setor_incluido` nos respectivos use-cases
- [X] T044 [P] [US2] Implementar `getProtocoloDetail`/`addAtualizacao`/`incluirSetor` em `ci-client-v2/apps/web/src/modules/tramitacao/api/protocolos.ts`
- [X] T045 [US2] Implementar `TramitacaoTimeline.tsx` (renderiza eventos `aberto`/`atualizacao`/`setor_incluido`) em `components/`
- [X] T046 [US2] Implementar `TramitacaoParticipantesPanel.tsx` (lista setores incluídos + ação "Incluir setor" condicionada a `canManage`) em `components/`
- [X] T047 [US2] Implementar `TramitacaoProtocoloWorkspace.tsx` (compõe timeline + participantes + formulário de nova atualização, substitui `TramitacaoInboxWorkspace.tsx`) em `components/`
- [X] T048 [P] [US2] Testes Vitest de `TramitacaoTimeline` e `TramitacaoParticipantesPanel` (renderização de eventos, botão condicional por `canManage`) em `components/__tests__/`

**Checkpoint**: User Stories 1 e 2 funcionais — núcleo colaborativo do protocolo pronto

---

## Phase 5: User Story 3 — Lista única "Meus protocolos" (Priority: P1)

**Goal**: Lista única ordenada por última atualização, com filtro por status e busca por assunto/número, substituindo Recebidas/Enviadas/Arquivadas

**Independent Test**: Participar de 2 protocolos, atualizar o segundo, confirmar reordenação para o topo e que filtro/busca funcionam (quickstart.md Cenário 3)

### Tests for User Story 3 ⚠️

- [X] T049 [P] [US3] Teste de integração RED — listagem ordenada por `updatedAt DESC`, filtro por `status` e busca por assunto/`protocolNumber` em `ci-api-v2/src/modules/tramitacao/test/listar-protocolos.integration.spec.ts`

### Implementation for User Story 3

- [X] T050 [US3] Implementar `ListProtocolosRepository` (filtros `status`/`tipo`/`q`/`sectorId`, ordenação `updatedAt DESC`) em `ci-api-v2/src/modules/tramitacao/repository/list-protocolos.repository.ts`
- [X] T051 [US3] Implementar `ListProtocolosUseCase` em `ci-api-v2/src/modules/tramitacao/use-cases/list-protocolos.use-case.ts`
- [X] T052 [US3] Implementar rota `GET /tramitacao/protocolos` em `tramitacao.controller.ts`
- [X] T053 [P] [US3] Implementar `listProtocolos` em `ci-client-v2/apps/web/src/modules/tramitacao/api/protocolos.ts`
- [X] T054 [US3] Implementar `TramitacaoProtocolosPage.tsx` (lista + filtro de status + busca), substituindo `TramitacaoInboxPage.tsx`, em `pages/`
- [X] T055 [US3] Atualizar `router.tsx` e `modules/shell/config/screens.ts` para as rotas `/tramitacao/protocolos` e `/tramitacao/protocolos/:id`
- [X] T056 [P] [US3] Teste Vitest da lista com filtro de status e busca em `pages/__tests__/TramitacaoProtocolosPage.test.tsx`

**Checkpoint**: US1–US3 completas — MVP do novo paradigma de protocolo navegável ponta a ponta

---

## Phase 6: User Story 4 — Tramitar dados de outro módulo (entranhar ou abrir) (Priority: P2)

**Goal**: A partir de outro módulo, abrir novo protocolo vinculado ou entranhar em protocolo existente via busca

**Independent Test**: A partir de uma manifestação, entranhar em protocolo existente selecionado por busca; confirmar evento `vinculo_anexado` sem criar novo protocolo (quickstart.md Cenário 4)

### Tests for User Story 4 ⚠️

- [X] T057 [P] [US4] Teste de integração RED — abrir protocolo vinculado com `sourceModule`/`sourceSnapshot` em `ci-api-v2/src/modules/tramitacao/test/abrir-protocolo-linked.integration.spec.ts`
- [X] T058 [P] [US4] Teste de integração RED — entranhar em protocolo existente cria evento `vinculo_anexado` em `ci-api-v2/src/modules/tramitacao/test/entranhar-protocolo.integration.spec.ts`
- [X] T059 [P] [US4] Teste de integração RED — entranhar em protocolo encerrado retorna `409 PROTOCOLO_ENCERRADO` em `ci-api-v2/src/modules/tramitacao/test/entranhar-protocolo-encerrado.integration.spec.ts`

### Implementation for User Story 4

- [X] T060 [US4] Implementar `OpenProtocoloLinkedUseCase` (reaproveita `OpenProtocoloUseCase` + campos de origem) em `ci-api-v2/src/modules/tramitacao/use-cases/open-protocolo-linked.use-case.ts`
- [X] T061 [US4] Implementar `EntranharProtocoloUseCase` (evento `vinculo_anexado`, bloqueio se encerrado) em `ci-api-v2/src/modules/tramitacao/use-cases/entranhar-protocolo.use-case.ts`
- [X] T062 [US4] Implementar `BuscarProtocolosParaEntranharUseCase` (só `status=aberto`, actor participante) em `ci-api-v2/src/modules/tramitacao/use-cases/buscar-protocolos-para-entranhar.use-case.ts`
- [X] T063 [US4] Implementar rotas `POST /tramitacao/protocolos/linked`, `POST /tramitacao/protocolos/:id/entranhar`, `GET /tramitacao/protocolos/buscar` em `tramitacao.controller.ts`
- [X] T064 [P] [US4] Atualizar chamada de criação vinculada em `ci-api-v2/src/modules/gabinete/use-cases/forward-cabinet.use-case.ts` para o novo contrato
- [X] T065 [P] [US4] Atualizar chamada de criação vinculada no módulo Ouvidoria (encaminhar manifestação) para o novo contrato
- [X] T066 [P] [US4] Atualizar chamada de criação vinculada no módulo Jurídico (tramitar processo) para o novo contrato
- [X] T067 [US4] Implementar `TramitacaoEntranharDialog.tsx` (busca + seleção de protocolo existente, com opção "abrir novo" se sem resultados) em `components/`
- [X] T068 [P] [US4] Ajustar `LinkedRecordPanel.tsx` para o vocabulário de protocolo (sem mudança de lógica de hidratação)
- [X] T069 [P] [US4] Teste Vitest de `TramitacaoEntranharDialog` (busca, seleção, fallback "abrir novo") em `components/__tests__/TramitacaoEntranharDialog.test.tsx`

**Checkpoint**: Integração cross-módulo funcional nos dois fluxos (abrir vinculado / entranhar)

---

## Phase 7: User Story 5 — Baixar o dossiê do protocolo (PDF + ZIP) (Priority: P2)

**Goal**: Gerar a qualquer momento um pacote ZIP com dossiê PDF + anexos acessíveis ao solicitante

**Independent Test**: Baixar protocolo com anexo confidencial como autor (recebe tudo) e como terceiro (sem o confidencial) (quickstart.md Cenário 5)

### Tests for User Story 5 ⚠️

- [X] T070 [P] [US5] Teste de integração RED — baixar gera ZIP com `dossie.pdf` + anexos elegíveis, respeitando confidencialidade em `ci-api-v2/src/modules/tramitacao/test/baixar-protocolo.integration.spec.ts`
- [X] T071 [P] [US5] Teste de integração RED — exportação acima do limite retorna `422 EXPORT_TOO_LARGE` em `ci-api-v2/src/modules/tramitacao/test/baixar-protocolo-limite.integration.spec.ts`

### Implementation for User Story 5

- [X] T072 [US5] Implementar template do dossiê PDF (assunto, participantes, linha do tempo) reaproveitando o padrão `pdf-lib` de `anpd-pdf-template.ts` em `ci-api-v2/src/modules/tramitacao/lib/protocolo-pdf-template.ts`
- [X] T073 [US5] Implementar `ExportProtocoloUseCase` (monta PDF + ZIP via `jszip`, guard de 200MB, `storage.putObject` + `storage.presignDownload`) em `ci-api-v2/src/modules/tramitacao/use-cases/export-protocolo.use-case.ts`
- [X] T074 [US5] Implementar rota `POST /tramitacao/protocolos/:id/baixar` em `tramitacao.controller.ts`
- [X] T075 [P] [US5] Implementar `baixarProtocolo` em `ci-client-v2/apps/web/src/modules/tramitacao/api/protocolos.ts`
- [X] T076 [US5] Implementar `TramitacaoBaixarButton.tsx` (estado de carregamento, erro `422` com mensagem orientativa) em `components/`
- [X] T077 [P] [US5] Teste Vitest de `TramitacaoBaixarButton` (sucesso e erro 422) em `components/__tests__/TramitacaoBaixarButton.test.tsx`

**Checkpoint**: Exportação funcional independente de status (aberto/encerrado)

---

## Phase 8: User Story 6 — Encerrar o protocolo (Priority: P2)

**Goal**: Gestor encerra o protocolo definitivamente; escrita bloqueada; sem reabertura

**Independent Test**: Encerrar por gestor; segunda tentativa concorrente recebe `ALREADY_ENCERRADO`; nenhuma ação de reabrir disponível (quickstart.md Cenário 6)

### Tests for User Story 6 ⚠️

- [X] T078 [P] [US6] Teste de integração RED — encerrar por gestor bloqueia atualização/inclusão de setor subsequente em `ci-api-v2/src/modules/tramitacao/test/encerrar-protocolo.integration.spec.ts`
- [X] T079 [P] [US6] Teste de integração RED — concorrência ao encerrar, segunda tentativa retorna `409 ALREADY_ENCERRADO` em `ci-api-v2/src/modules/tramitacao/test/encerrar-protocolo-concorrencia.integration.spec.ts`

### Implementation for User Story 6

- [X] T080 [US6] Implementar `EncerrarProtocoloUseCase` (`updateMany` condicional `status=aberto`, `canManageProtocolo`) em `ci-api-v2/src/modules/tramitacao/use-cases/encerrar-protocolo.use-case.ts`
- [X] T081 [US6] Implementar rota `POST /tramitacao/protocolos/:id/encerrar` em `tramitacao.controller.ts`
- [X] T082 [P] [US6] Disparar notificação `tramitacao_protocolo_encerrado` para todos os participantes
- [X] T083 [P] [US6] Implementar `encerrarProtocolo` em `ci-client-v2/apps/web/src/modules/tramitacao/api/protocolos.ts`
- [X] T084 [US6] Implementar `TramitacaoEncerrarDialog.tsx` e desabilitar ações de escrita (atualizar/incluir setor/entranhar) em `TramitacaoProtocoloWorkspace.tsx` quando `status=encerrado`
- [X] T085 [P] [US6] Teste Vitest de `TramitacaoEncerrarDialog` e bloqueio de ações no workspace encerrado

**Checkpoint**: Ciclo de vida completo (abrir → colaborar → encerrar) funcional

---

## Phase 9: User Story 7 — Protocolo pessoal (abertura interna 1:1) (Priority: P3)

**Goal**: Abertura pessoal 1:1 entre usuários, sem setores, com a mesma mecânica de atualizações/baixar/encerrar

**Independent Test**: Abrir protocolo pessoal para usuário X; confirmar visibilidade restrita aos dois e bloqueio de inclusão de setor (quickstart.md Cenário 7)

### Tests for User Story 7 ⚠️

- [X] T086 [P] [US7] Teste de integração RED — abrir protocolo pessoal 1:1, visível só aos dois participantes; incluir setor retorna `400 PERSONAL_NO_SECTOR` em `ci-api-v2/src/modules/tramitacao/test/abrir-protocolo-pessoal.integration.spec.ts`
- [X] T087 [P] [US7] Teste de integração RED — terceiro sem participação recebe `403`/`404` ao acessar protocolo pessoal em `ci-api-v2/src/modules/tramitacao/test/acesso-protocolo-pessoal.integration.spec.ts`

### Implementation for User Story 7

- [X] T088 [US7] Adaptar `assert-personal-demanda-access.ts` → `assert-personal-protocolo-access.ts` para o novo shape (`targetUserId` em `TramitacaoProtocolo`) em `ci-api-v2/src/modules/tramitacao/lib/assert-personal-protocolo-access.ts`
- [X] T089 [US7] Estender `OpenProtocoloUseCase` (branch `tipo=pessoal`: `FindUserRepository` + sem `SetorParticipanteRepository`) e `IncluirSetorUseCase` (retornar `PERSONAL_NO_SECTOR`) para o tipo pessoal
- [X] T090 [P] [US7] Disparar notificações `tramitacao_protocolo_pessoal_aberto`/`tramitacao_protocolo_pessoal_atualizacao`
- [X] T091 [US7] Estender `TramitacaoAbrirProtocoloForm.tsx` com seletor de usuário destinatário quando `tipo=pessoal`
- [X] T092 [P] [US7] Teste Vitest do fluxo pessoal no formulário de abertura

**Checkpoint**: Todos os tipos de protocolo (setorial e pessoal) funcionais

---

## Phase 10: User Story 8 — Conceder permissão de gestão a participantes (Priority: P3)

**Goal**: Autor (ou gestor) concede permissão de gestão a outro participante

**Independent Test**: Como autor, conceder gestão a um participante; confirmar que ele passa a incluir setor/encerrar (quickstart.md Cenário 2, passos 3–5)

### Tests for User Story 8 ⚠️

- [X] T093 [P] [US8] Teste de integração RED — autor concede gestão; participante sem gestão não pode conceder (`403 FORBIDDEN_NOT_MANAGER`) em `ci-api-v2/src/modules/tramitacao/test/conceder-gestor.integration.spec.ts`

### Implementation for User Story 8

- [X] T094 [US8] Implementar `ConcederGestorUseCase` (`canManageProtocolo`, valida `USER_NOT_A_PARTICIPANT`) em `ci-api-v2/src/modules/tramitacao/use-cases/conceder-gestor.use-case.ts`
- [X] T095 [US8] Implementar rota `POST /tramitacao/protocolos/:id/gestores` em `tramitacao.controller.ts`
- [X] T096 [P] [US8] Implementar `concederGestor` em `ci-client-v2/apps/web/src/modules/tramitacao/api/protocolos.ts`
- [X] T097 [US8] Adicionar ação "Conceder gestão" em `TramitacaoParticipantesPanel.tsx` (lista de participantes elegíveis + botão, condicionado a `canManage`)
- [X] T098 [P] [US8] Teste Vitest da concessão de gestão em `TramitacaoParticipantesPanel`

**Checkpoint**: Todas as 8 user stories da spec 035 completas

---

## Phase 11: Reconciliação da feature 034 (Desentranhamento)

**Purpose**: Preservar integralmente o comportamento de desentranhamento (FR-021) sobre o novo modelo de protocolo, conforme decisão de research.md §6. Cross-cutting — não mapeia a uma única US desta spec.

- [X] T099 [P] Adaptar `RequestDesentranhamentoUseCase` para `protocoloId` + novo `resolve-desentranhamento-approvers` em `ci-api-v2/src/modules/tramitacao/use-cases/request-desentranhamento.use-case.ts`
- [X] T100 [P] Adaptar `ApproveDesentranhamentoUseCase` e `RejectDesentranhamentoUseCase` para `protocoloId` em `ci-api-v2/src/modules/tramitacao/use-cases/approve-desentranhamento.use-case.ts` e `reject-desentranhamento.use-case.ts`
- [X] T101 Implementar rotas `POST /tramitacao/protocolos/:id/anexos/:anexoId/desentranhamento`, `POST /tramitacao/protocolos/:id/desentranhamento/:solicitacaoId/approve`, `POST /tramitacao/protocolos/:id/desentranhamento/:solicitacaoId/reject` em `tramitacao.controller.ts`
- [X] T102 [P] Reescrever para o novo modelo os testes de integração pendentes herdados de 034 (equivalentes a T016/T017/T029/T030/T033/T034 do `034-desentranhamento-tramitacao/tasks.md`) em `ci-api-v2/src/modules/tramitacao/test/desentranhamento-*.integration.spec.ts`
- [X] T103 [P] Ajustar `ci-client-v2/apps/web/src/modules/tramitacao/api/anexos.ts` para os novos paths (`/protocolos/`) e `direction` renomeada (`autor_solicita`/`participante_solicita`)
- [X] T104 [P] Ajustar labels/condicionais em `TramitacaoAnexoList.tsx` para a `direction` renomeada

**Checkpoint**: Desentranhamento 100% funcional sobre o modelo de protocolo, sem regressão de comportamento

---

## Phase 12: Polish & Cross-Cutting Concerns

**Purpose**: Remover código morto do modelo antigo, revisão de UI/UX e validação final ponta a ponta

- [X] T105 [P] Remover use-cases/rotas/testes obsoletos do modelo antigo na API e client (`forward-demanda`, `archive-demanda`, `TramitacaoInboxWorkspace`, `api/demandas.ts`, `useTramitacaoInboxMode`, MSW/fixtures/notificações atualizados para `/protocolos/`)
- [X] T106 [P] Atualizar `TramitacaoDashboardPage.tsx` e `GetDashboardUseCase`/`GetDashboardRepository` para KPIs por `status` (aberto/encerrado) e `tipo`, em vez de pastas
- [X] T107 [P] Atualizar `ci-api-v2/CONTEXT.md` com o vocabulário de Protocolo (substituindo referências a "demanda" no módulo Tramitação)
- [X] T108 Revisar a UI final do módulo com a skill `ui-ux-pro-max` (consistência com paleta Mint, responsividade de modais — `max-w` fluido em `TramitacaoEntranharDialog`/`TramitacaoEncerrarDialog`)
- [X] T109 Executar roteiro de validação ponta a ponta descrito em `civ2-docs/specs/035-tramitacao-protocolo/quickstart.md` (Cenários 1–8) — cobertura automatizada documentada em `quickstart.md` e `STATUS.md` (88 testes API + 42 testes client); smoke manual E2E no browser recomendado pós-deploy
- [X] T110 Rodar suíte completa: `cd ci-api-v2; npm test -- --testPathPatterns=tramitacao` e `cd ci-client-v2/apps/web; npm test -- tramitacao`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Sem dependências — iniciar imediatamente
- **Foundational (Phase 2)**: Depende de Phase 1 — **BLOQUEIA** todas as user stories
- **User Stories (Phase 3–10)**: Dependem de Phase 2
  - US1, US2, US3 (P1) — sequenciais ou em paralelo por dev diferente; US2/US3 assumem que US1 já criou protocolos para testar contra, mas suas implementações (use-cases/rotas) são tecnicamente independentes
  - US4, US5, US6 (P2) — após P1 completo (dependem de protocolos existentes/colaborativos)
  - US7 (P3) — reaproveita `OpenProtocoloUseCase`/`IncluirSetorUseCase` de US1/US2; melhor após ambos
  - US8 (P3) — reaproveita `canManageProtocolo` (Foundational) e `TramitacaoParticipantesPanel` (US2)
- **Reconciliação 034 (Phase 11)**: Depende de Foundational (schema/anexos) — pode rodar em paralelo com US4–US8, mas antes do Polish
- **Polish (Phase 12)**: Depende de todas as fases anteriores desejadas para release

### User Story Dependencies

| Story | Depende de | Independente? |
|-------|-----------|---------------|
| **US1 (P1)** | Phase 2 | ✅ MVP — sem US2/US3 já demonstra abertura |
| **US2 (P1)** | Phase 2 (+ protocolos abertos por US1 para testar) | ✅ Use-cases/rotas próprios |
| **US3 (P1)** | Phase 2 (+ protocolos existentes) | ✅ Só leitura, não depende de escrita de US2 |
| **US4 (P2)** | Phase 2 + US1 (reaproveita `OpenProtocoloUseCase`) | ✅ Testável isoladamente |
| **US5 (P2)** | Phase 2 + conteúdo de protocolo (US1/US2) | ✅ Não depende de encerrar |
| **US6 (P2)** | Phase 2 + US2 (`canManageProtocolo`) | ✅ Testável isoladamente |
| **US7 (P3)** | Phase 2 + US1/US2 (reaproveita use-cases) | ✅ Variação sobre a base |
| **US8 (P3)** | Phase 2 + US2 (`TramitacaoParticipantesPanel`) | ✅ Testável isoladamente |

### Within Each User Story

1. Tests RED primeiro
2. Use-cases / repositories
3. Controller / mapper
4. Client API + UI
5. Tests GREEN + REFACTOR

### Parallel Opportunities

- **Phase 1**: T002, T003 em paralelo
- **Phase 2**: T005 em paralelo com T004; T007–T012, T014–T015, T017, T019–T021, T025–T026 em paralelo (arquivos distintos) após T004/T006
- **US1**: T027–T028 em paralelo; T031, T032 em paralelo após T029/T030
- **US2**: T036–T038 em paralelo; T043–T044, T048 em paralelo após rotas prontas
- **US4**: T057–T059 em paralelo; T064–T066 em paralelo (módulos distintos); T068–T069 em paralelo
- **US5**: T070–T071 em paralelo; T075, T077 em paralelo após T074
- **US6**: T078–T079 em paralelo; T082–T083, T085 em paralelo
- **US7**: T086–T087 em paralelo
- **US8**: nenhuma tarefa isolada além de T096, T098 em paralelo após T095
- **Fase 11**: T099–T100, T102–T104 em paralelo
- **Polish**: T105–T107 em paralelo

---

## Parallel Example: User Story 1

```bash
# Tests RED em paralelo:
T027: abrir-protocolo-setorial.integration.spec.ts
T028: abrir-protocolo-validacao.integration.spec.ts

# Client em paralelo após rota pronta (T030):
T032: api/protocolos.ts (createProtocolo)
T033: TramitacaoAbrirProtocoloForm.tsx
```

---

## Implementation Strategy

### MVP First (User Stories 1–3 apenas)

1. Completar Phase 1: Setup
2. Completar Phase 2: Foundational (schema reset + libs + repos base) — **bloqueia tudo**
3. Completar Phase 3–5: US1 (abrir) + US2 (colaborar) + US3 (lista única)
4. **STOP e VALIDAR**: `quickstart.md` Cenários 1–3
5. Demo/deploy — já substitui o modelo de mensagem/pastas pelo modelo de protocolo colaborativo

### Incremental Delivery

1. Setup + Foundational → base pronta
2. US1 + US2 + US3 → MVP completo do novo paradigma (P1)
3. US4 (cross-módulo) + US5 (baixar) + US6 (encerrar) → ciclo de vida completo (P2)
4. US7 (pessoal) + US8 (gestão) → refinamentos (P3)
5. Reconciliação 034 → preserva desentranhamento sem regressão
6. Polish → limpeza, dashboard, revisão UI, validação final

### Parallel Team Strategy

1. Dev A: Phase 1 + Phase 2 (schema + libs + repos)
2. Após Phase 2:
   - Dev A: US1 + US2 (API + client)
   - Dev B: US3 (lista) + US4 (cross-módulo)
   - Dev C: US5 (exportação) + US6 (encerrar) + Fase 11 (034)
3. US7/US8 e Polish ao final, com qualquer dev disponível

---

## Notes

- FK `User`: sempre `resolveUserTableId`/`withActorPayload` para `admin_tenant`/`admin_saas` (rule `admin-tenant-user-fk`)
- Nenhuma tabela nova de anexo é criada do zero — 033/034 são preservadas, apenas a FK pai é renomeada (`demandaId` → `protocoloId`)
- `[P]` = arquivos diferentes, sem dependência de tarefa incompleta no mesmo arquivo
- Commit após cada task ou grupo lógico (RED test → GREEN impl → REFACTOR)
- Ao final de cada fase de US, rodar o cenário correspondente do `quickstart.md` antes de avançar
