---
description: "Task list for ouvidoria interna (003-ouvidoria)"
---

# Tasks: Ouvidoria Interna

**Input**: Design documents from `specs/003-ouvidoria/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Tests**: TDD obrigatório (Constitution II + plan.md) — Jest unit/e2e na API; client typecheck + smoke manual (quickstart.md).

**Organization**: US1–US4 e US5 são P1; US6–US7 são P2. Fases após setup e fundação.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Pode executar em paralelo (arquivos diferentes, sem dependências pendentes)
- **[Story]**: User story da spec (US1–US7)
- Caminhos relativos à raiz do repositório `ci-v2/`

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Dependências, variáveis de ambiente e scaffolding de módulos

- [X] T001 Adicionar `@aws-sdk/client-s3` e `@aws-sdk/s3-request-presigner` em `ci-api-v2/package.json` e instalar
- [X] T002 [P] Documentar variáveis Wasabi/MinIO em `ci-api-v2/.env.example` (`WASABI_ENDPOINT`, `WASABI_REGION`, `WASABI_BUCKET`, `WASABI_ACCESS_KEY`, `WASABI_SECRET_KEY`, `WASABI_PREFIX`)
- [X] T003 [P] Criar esqueleto `AddressModule` em `ci-api-v2/src/modules/address/address.module.ts` (controller, schemas, pastas `use-cases/` e `repository/`)
- [X] T004 [P] Criar esqueleto `OuvidoriaModule` em `ci-api-v2/src/modules/ouvidoria/ouvidoria.module.ts` (controller, schemas, `use-cases/`, `repository/`, `services/`)
- [X] T005 Registrar `AddressModule` e `OuvidoriaModule` em `ci-api-v2/src/app.module.ts`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Schema Prisma, seed IBGE, repositórios base, storage port — **bloqueia todas as user stories**

**⚠️ CRITICAL**: Nenhuma user story começa antes desta fase

### Tests first (RED)

- [X] T006 [P] Escrever testes falhando para helper de badges derivados (`critico`/`vencendo`) em `ci-api-v2/src/modules/ouvidoria/ouvidoria-status.helper.spec.ts` conforme `data-model.md` R7

### Schema & migration

- [X] T007 Criar `ci-api-v2/prisma/schema/municipio.prisma` (`codigoIbge`, `nome`, `uf`) conforme `data-model.md`
- [X] T008 [P] Criar `ci-api-v2/prisma/schema/address.prisma` (`Address` com `tenantId`, FK `municipioIbge`, campos logradouro/CEP/`descricaoLocal`)
- [X] T009 Criar `ci-api-v2/prisma/schema/manifestacao.prisma` (enums `ManifestacaoStatus`, `ManifestacaoTipo`, `ManifestacaoEsfera`, `ManifestacaoOrigem`, `ManifestacaoCanal`, `ManifestacaoEventoTipo`; modelos `Manifestacao`, `ManifestacaoAnexo`, `ManifestacaoEvento`, `ManifestacaoSequence`)
- [X] T010 Registrar novos schemas em `ci-api-v2/prisma/schema/schema.prisma` e gerar migration (`npx prisma migrate dev`)
- [X] T011 Criar script `ci-api-v2/prisma/seed/municipios.ts` (import IBGE) e invocar em `ci-api-v2/prisma/seed.ts`
- [X] T012 Estender `ci-api-v2/prisma/seed.ts` com `ModuloSetor` vinculando módulo `ouvidoria` ao setor Ouvidoria demo
- [X] T013 [P] Estender soft-delete handlers em `ci-api-v2/src/infrastructure/prisma/prisma.extensions.ts` para `Address` e `Manifestacao` se aplicável

### Address module (foundation)

- [X] T014 [P] Implementar `create-address.repository.ts` e `find-address-by-id.repository.ts` em `ci-api-v2/src/modules/address/repository/`
- [X] T015 Implementar `list-municipios.use-case.ts` + Zod query em `ci-api-v2/src/modules/address/address.schemas.ts`
- [X] T016 Implementar `GET /address/municipios` em `ci-api-v2/src/modules/address/address.controller.ts` conforme `contracts/rest-api-ouvidoria.md`

### Storage port (foundation)

- [X] T017 [P] Definir interface `StoragePort` em `ci-api-v2/src/modules/ouvidoria/services/storage.port.ts` (presign upload, presign download, delete)
- [X] T018 [P] Implementar `StorageService` stub/mock em `ci-api-v2/src/modules/ouvidoria/services/storage.service.ts` registrado no module (implementação Wasabi na US2)
- [ ] T019 Executar migration + seed e confirmar municípios carregados (`cd ci-api-v2; npx prisma db seed`)

**Checkpoint**: Foundation ready — schema migrado; municípios seed; módulos registrados; storage port injetável

---

## Phase 3: User Story 1 — Registrar manifestação interna (Priority: P1) 🎯 MVP

**Goal**: Servidor registra manifestação em 3 etapas (dados → anexos placeholder → revisão → confirmar) com protocolo e chave de consulta

**Independent Test**: POST rascunho → revisão → confirmar → protocolo `OUV-AAAA-NNNN` + chave exibida (quickstart VS-002)

### Tests for User Story 1

- [X] T020 [P] [US1] Testes falhando `create-manifestacao-draft.use-case.spec.ts` em `ci-api-v2/src/modules/ouvidoria/test/use-cases/`
- [X] T021 [P] [US1] Testes falhando `update-manifestacao-draft.use-case.spec.ts` (preserva rascunho, valida enums FR-002/FR-003)
- [X] T022 [P] [US1] Testes falhando `confirm-manifestacao.use-case.spec.ts` (sequência atômica, protocolo único, evento `registro`, hash chave R3)

### Implementation for User Story 1 (API)

- [X] T023 [P] [US1] Implementar repositories em `ci-api-v2/src/modules/ouvidoria/repository/`: `create-manifestacao.repository.ts`, `update-manifestacao.repository.ts`, `find-manifestacao-by-id.repository.ts`, `increment-manifestacao-sequence.repository.ts`, `create-manifestacao-evento.repository.ts`
- [X] T024 [US1] Implementar Zod schemas em `ci-api-v2/src/modules/ouvidoria/ouvidoria.schemas.ts` (`CreateManifestacaoDraftBody`, `UpdateManifestacaoDraftBody`, enums mapeados)
- [X] T025 [US1] Implementar `create-manifestacao-draft.use-case.ts` (cria `Address` inline se body.address presente)
- [X] T026 [US1] Implementar `update-manifestacao-draft.use-case.ts`
- [X] T027 [US1] Implementar `confirm-manifestacao.use-case.ts` (transação: sequence → protocolo → bcrypt chave → status `em_analise` → evento registro)
- [X] T028 [US1] Implementar `get-manifestacao-revisao.use-case.ts` (DTO completo para etapa revisão)
- [X] T029 [US1] Wire rotas em `ci-api-v2/src/modules/ouvidoria/ouvidoria.controller.ts`: `POST /ouvidoria/manifestacoes`, `PATCH /ouvidoria/manifestacoes/:id`, `GET /ouvidoria/manifestacoes/:id/revisao`, `POST /ouvidoria/manifestacoes/:id/confirmar` com `@RequireModulo('ouvidoria')`

### Implementation for User Story 1 (Client)

- [X] T030 [P] [US1] Criar `ci-client-v2/apps/web/src/lib/ouvidoria-api.ts` (createDraft, updateDraft, getRevisao, confirmar)
- [X] T031 [US1] Criar `ci-client-v2/apps/web/src/components/ouvidoria/ManifestacaoWizardSteps.tsx` (step 1: campos FR-001; copy revisão FR-004)
- [X] T032 [US1] Criar `ci-client-v2/apps/web/src/pages/ouvidoria/ManifestacaoWizardPage.tsx` (state multi-step; step 3 confirmação com protocolo+chave)
- [X] T033 [US1] Registrar lazy route `/ouvidoria/manifestacoes/nova` em router (`apps/web/src/main.tsx` ou arquivo de rotas) apontando para `ManifestacaoWizardPage`
- [X] T034 [US1] E2e em `ci-api-v2/test/ouvidoria.e2e-spec.ts`: fluxo rascunho → confirmar retorna protocolo

**Checkpoint**: MVP — registro interno com protocolo funcional (API + wizard client)

---

## Phase 4: User Story 2 — Anexar documentos (Priority: P1)

**Goal**: Upload presigned Wasabi; validação MIME/tamanho 30 MB; anexos na revisão e detalhe

**Independent Test**: presign PDF OK; `.exe` rejeitado; anexo listado na revisão (quickstart VS-003)

### Tests for User Story 2

- [X] T035 [P] [US2] Testes falhando `presign-anexo.use-case.spec.ts` (whitelist FR-007, `FILE_TOO_LARGE`, `FILE_TYPE_NOT_ALLOWED`)
- [X] T036 [P] [US2] Testes falhando `confirm-anexo.use-case.spec.ts`

### Implementation for User Story 2 (API)

- [X] T037 [US2] Implementar `StorageService` Wasabi real em `ci-api-v2/src/modules/ouvidoria/services/storage.service.ts` usando env vars (R4)
- [X] T038 [US2] Implementar `presign-anexo.use-case.ts` e `confirm-anexo.use-case.ts` + repository `create-manifestacao-anexo.repository.ts`
- [X] T039 [US2] Wire `POST /ouvidoria/manifestacoes/:id/anexos/presign` e `POST .../anexos/:anexoId/confirm` em `ouvidoria.controller.ts`
- [X] T040 [US2] Estender `get-manifestacao-revisao.use-case.ts` para incluir anexos

### Implementation for User Story 2 (Client)

- [X] T041 [US2] Criar `ci-client-v2/apps/web/src/components/ouvidoria/AnexoUploadZone.tsx` (presign → PUT storage → confirm; copy anexos spec)
- [X] T042 [US2] Integrar step 2 do wizard em `ManifestacaoWizardPage.tsx` com `AnexoUploadZone`
- [X] T043 [US2] E2e: tipo inválido retorna 400 `FILE_TYPE_NOT_ALLOWED` em `ci-api-v2/test/ouvidoria.e2e-spec.ts`

**Checkpoint**: Anexos end-to-end no wizard

---

## Phase 5: User Story 3 — Operar fila e detalhe (Priority: P1)

**Goal**: Lista paginada com filtros e badges; detalhe com timeline, anexos download, manifestante

**Independent Test**: Lista colunas Protocolo/Tipo/Status/Prazo/Origem; busca por protocolo; detalhe completo (quickstart VS-002 step 7, VS-004 parcial)

### Tests for User Story 3

- [X] T044 [P] [US3] Testes falhando `list-manifestacoes.use-case.spec.ts` (filtros, badges `vencendo`/`critico`)
- [X] T045 [P] [US3] Testes falhando `get-manifestacao-detail.use-case.ts` (timeline ordenada, download URLs)

### Implementation for User Story 3 (API)

- [X] T046 [US3] Implementar `list-manifestacoes.repository.ts` e `list-manifestacoes.use-case.ts` com paginação e filtros conforme contract
- [X] T047 [US3] Implementar `get-manifestacao-detail.use-case.ts` (eventos, anexos presigned download via `StoragePort`)
- [X] T048 [US3] Wire `GET /ouvidoria/manifestacoes` e `GET /ouvidoria/manifestacoes/:id` em `ouvidoria.controller.ts`
- [X] T049 [P] [US3] Implementar helper labels PT-BR em `ci-api-v2/src/modules/ouvidoria/ouvidoria.types.ts` (`tipoLabel`, `statusLabel`, `origemLabel`)

### Implementation for User Story 3 (Client)

- [X] T050 [US3] Estender `ci-client-v2/apps/web/src/lib/ouvidoria-api.ts` (list, getDetail)
- [X] T051 [US3] Criar `ci-client-v2/apps/web/src/pages/ouvidoria/ManifestacoesListPage.tsx` (tabela, filtros, link nova manifestação)
- [X] T052 [P] [US3] Criar `ci-client-v2/apps/web/src/components/ouvidoria/ManifestacaoTimeline.tsx`
- [X] T053 [US3] Criar `ci-client-v2/apps/web/src/pages/ouvidoria/ManifestacaoDetailPage.tsx` (dados, anexos, timeline read-only)
- [X] T054 [US3] Registrar lazy routes `/ouvidoria/manifestacoes` e `/ouvidoria/manifestacoes/:id` no router

**Checkpoint**: Fila operacional visível; detalhe navegável

---

## Phase 6: User Story 4 — Tramitar, responder e encerrar (Priority: P1)

**Goal**: Ações Encaminhar/Responder/Encerrar com transições de status e eventos timeline

**Independent Test**: Fluxo em_analise → tramitando → respondida → encerrada (quickstart VS-004)

### Tests for User Story 4

- [X] T055 [P] [US4] Testes falhando `encaminhar-manifestacao.use-case.spec.ts` (status `tramitando`, evento, `destinoSetorId`)
- [X] T056 [P] [US4] Testes falhando `responder-manifestacao.use-case.spec.ts` e `encerrar-manifestacao.use-case.spec.ts` (`INVALID_STATUS_TRANSITION`)

### Implementation for User Story 4 (API)

- [X] T057 [US4] Implementar `encaminhar-manifestacao.use-case.ts`, `responder-manifestacao.use-case.ts`, `encerrar-manifestacao.use-case.ts`
- [X] T058 [US4] Wire `POST /ouvidoria/manifestacoes/:id/encaminhar`, `/responder`, `/encerrar` em `ouvidoria.controller.ts`
- [X] T059 [US4] Estender `get-manifestacao-detail.use-case.ts` com `acoesPermitidas[]` conforme status

### Implementation for User Story 4 (Client)

- [X] T060 [US4] Criar `ci-client-v2/apps/web/src/components/ouvidoria/ManifestacaoActionDialogs.tsx` (Encaminhar/Responder/Encerrar)
- [X] T061 [US4] Integrar ações em `ManifestacaoDetailPage.tsx` chamando `ouvidoria-api.ts`
- [X] T062 [US4] E2e fluxo completo encaminhar→responder→encerrar em `ci-api-v2/test/ouvidoria.e2e-spec.ts`

**Checkpoint**: Ciclo operacional Base completo

---

## Phase 7: User Story 5 — Acesso ao módulo conforme setor (Priority: P1)

**Goal**: Rotas ouvidoria protegidas por `@RequireModulo('ouvidoria')`; client gate 403; sidebar visível

**Independent Test**: User Patrimônio → 403; user Ouvidoria → OK (quickstart VS-001)

### Tests for User Story 5

- [X] T063 [P] [US5] E2e em `ci-api-v2/test/ouvidoria.e2e-spec.ts`: user sem setor Ouvidoria recebe 403 `MODULO_SETOR_DENIED` em `GET /ouvidoria/manifestacoes`

### Implementation for User Story 5

- [X] T064 [US5] Auditar todas rotas em `ci-api-v2/src/modules/ouvidoria/ouvidoria.controller.ts` — garantir `@RequireModulo('ouvidoria')` exceto consulta pública (US7)
- [X] T065 [US5] Aplicar `useModuleAccess('ouvidoria')` em `ManifestacoesListPage.tsx`, `ManifestacaoWizardPage.tsx`, `ManifestacaoDetailPage.tsx` renderizando `AccessDenied403` quando negado
- [ ] T066 [US5] Smoke manual VS-001: sidebar Ouvidoria visível; conteúdo bloqueado sem setor

**Checkpoint**: Permissão setor consistente API + client

---

## Phase 8: User Story 6 — Sigilo em denúncias (Priority: P2)

**Goal**: Flag sigilo oculta PII manifestante para viewers não autorizados

**Independent Test**: Denúncia sigilosa — user sem permissão vê `manifestante: null`; admin vê completo (quickstart VS-005)

### Tests for User Story 6

- [X] T067 [P] [US6] Testes falhando filtro sigilo em `get-manifestacao-detail.use-case.spec.ts` (R8: `canViewSigilo`)

### Implementation for User Story 6

- [X] T068 [US6] Implementar `canViewSigilo(user)` em `ci-api-v2/src/modules/ouvidoria/ouvidoria.types.ts` (admin_plataforma OR setor ouvidoria)
- [X] T069 [US6] Aplicar omissão manifestante em `get-manifestacao-detail.use-case.ts` e `get-manifestacao-revisao.use-case.ts` quando `sigilo && !canViewSigilo`
- [X] T070 [US6] Atualizar `ManifestacaoDetailPage.tsx` para estados *Manifestação anônima* / *Dados sob sigilo* conforme `contracts/client-ouvidoria-ui.md`

**Checkpoint**: Sigilo funcional API + UI

---

## Phase 9: User Story 7 — Consulta pública por protocolo (Priority: P2)

**Goal**: `GET /ouvidoria/consulta` @Public com throttle; sem PII; mensagem genérica em erro

**Independent Test**: protocolo+chave válidos → andamento; chave errada → 404 genérico (quickstart VS-006)

### Tests for User Story 7

- [X] T071 [P] [US7] Testes falhando `consulta-publica.use-case.spec.ts` (chave bcrypt compare, sem PII sigilo, 404 uniforme)

### Implementation for User Story 7

- [X] T072 [US7] Implementar `consulta-publica.use-case.ts` + repository `find-manifestacao-by-protocolo.repository.ts`
- [X] T073 [US7] Implementar `GET /ouvidoria/consulta` com `@Public()`, `@Throttle(10, 60)` em `ouvidoria.controller.ts` — exige `X-Tenant-ID` (R9)
- [X] T074 [US7] E2e consulta válida/inválida e sigilo sem PII em `ci-api-v2/test/ouvidoria.e2e-spec.ts`

**Checkpoint**: API consulta pronta para SPA público futuro

---

## Phase 10: Polish & Cross-Cutting Concerns

**Purpose**: FR-020 edição bloqueada, validação final, quickstart

- [X] T075 [P] Testes `update-manifestacao-draft.use-case.spec.ts` — rejeita edição substantiva após evento `encaminhamento` (FR-020)
- [X] T076 Implementar guard FR-020 em `update-manifestacao-draft.use-case.ts` retornando `MANIFESTACAO_NOT_EDITABLE`
- [X] T077 [P] Criar rota edição wizard `/ouvidoria/manifestacoes/:id/editar` reutilizando `ManifestacaoWizardPage.tsx` (modo rascunho/pré-encaminhamento)
- [X] T078 [P] Confirmar `ci-api-v2/CONTEXT.md` inclui `Address` e referência módulo ouvidoria
- [X] T079 Executar `cd ci-api-v2; npm test` — suite completa verde
- [X] T080 Executar `cd ci-client-v2; npm run typecheck` — zero erros
- [ ] T081 Executar cenários `specs/003-ouvidoria/quickstart.md` VS-001 a VS-008 e registrar resultados

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Sem dependências — iniciar imediatamente
- **Foundational (Phase 2)**: Depende Setup — **BLOQUEIA** todas user stories
- **US1 (Phase 3)**: Depende Foundational — **MVP**
- **US2 (Phase 4)**: Depende US1 (precisa `manifestacaoId` rascunho)
- **US3 (Phase 5)**: Depende US1 (manifestações confirmadas); detalhe enriquecido por US4 timeline
- **US4 (Phase 6)**: Depende US3 (detalhe page)
- **US5 (Phase 7)**: Pode iniciar após Foundational (guard existe); fechar após rotas US1–US4
- **US6 (Phase 8)**: Depende US3 (detail DTO)
- **US7 (Phase 9)**: Depende US1 (protocolo+chave)
- **Polish (Phase 10)**: Depende US1–US7 desejados

### User Story Dependencies

| Story | Depende de | Independente quando |
|-------|------------|---------------------|
| US1 | Foundational | Confirmar gera protocolo |
| US2 | US1 | Upload sem lista |
| US3 | US1 | Lista/detalhe read-only |
| US4 | US3 | Ações operacionais |
| US5 | Foundational + rotas | 403 vs 200 |
| US6 | US3 | Sigilo no detail |
| US7 | US1 | Consulta API |

### Parallel Opportunities

**Phase 2** (após T007):

```text
T008 address.prisma ∥ T006 status helper tests
T014 address repositories ∥ T017 StoragePort
```

**Phase 3 US1**:

```text
T020 ∥ T021 ∥ T022 (test files)
T030 ouvidoria-api.ts ∥ T023 repositories (após tests RED)
```

**Phase 5 US3**:

```text
T044 list tests ∥ T045 detail tests
T051 ListPage ∥ T052 Timeline component
```

**Cross-story** (com equipe):

- Dev A: US1 → US2 → US7
- Dev B: US3 → US4 → US6
- Dev C: US5 + Polish

---

## Parallel Example: User Story 1

```bash
# Tests RED em paralelo:
T020 create-manifestacao-draft.use-case.spec.ts
T021 update-manifestacao-draft.use-case.spec.ts
T022 confirm-manifestacao.use-case.spec.ts

# Após repositories (T023):
T030 ouvidoria-api.ts  # client
T024 ouvidoria.schemas.ts  # se arquivo separado do use-case
```

---

## Implementation Strategy

### MVP First (User Story 1 only)

1. Phase 1: Setup
2. Phase 2: Foundational
3. Phase 3: US1 (registro + protocolo + wizard sem anexos reais)
4. **STOP and VALIDATE**: quickstart VS-002 parcial (sem anexos)
5. Demo interno

### Incremental Delivery

1. Setup + Foundational → base de dados pronta
2. US1 → registro com protocolo (MVP)
3. US2 → anexos Wasabi
4. US3 → fila e detalhe
5. US4 → tramitação completa
6. US5 → harden permissões
7. US6 + US7 → sigilo e consulta API
8. Polish → FR-020 + quickstart completo

### Suggested MVP Scope

**US1 + Foundational** entrega valor mínimo: servidor registra manifestação com protocolo e chave via wizard interno. US2–US7 incrementam sem quebrar US1.

---

## Notes

- Layout canônico API: copiar padrão `ci-api-v2/src/modules/permissao/` (1 use-case = 1 arquivo, 1 repository = 1 operação)
- Consulta pública (US7) é API only — sem página client nesta feature
- Licenças Carvalho/Pau-Brasil/Jatobá/Cedro **fora de escopo** — não criar tasks de dashboard/fiscalização
- Total: **81 tasks** | US1: 15 | US2: 9 | US3: 11 | US4: 8 | US5: 4 | US6: 4 | US7: 4 | Setup: 5 | Foundational: 14 | Polish: 7
