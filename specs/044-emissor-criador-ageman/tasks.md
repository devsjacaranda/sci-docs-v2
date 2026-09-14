---
description: "Task list for Emissor automático ao criar demanda AGEMAN (044-emissor-criador-ageman)"
---

# Tasks: Emissor automático ao criar demanda AGEMAN

**Input**: Design documents from `civ2-docs/specs/044-emissor-criador-ageman/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Tests**: **Obrigatórios** — TDD (Constitution II + `contracts/test-strategy.md`): RED → GREEN → REFACTOR. IDs `CT-OUV-EMISSOR-*` / `CT-OUV-EMISSOR-CLIENT-*`.

**Organization**: 3 user stories (US1–US3). Caminhos relativos à raiz `ci-v2/`. Refatoração do módulo `ouvidoria` existente (API + `apps/web`). Sem projeto, migration ou dependência nova.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Pode executar em paralelo (arquivos diferentes, sem dependências pendentes)
- **[Story]**: User story da spec (US1–US3)

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Confirmar que o refactor cabe no módulo existente — zero instalação, zero pasta nova de produto

- [x] T001 Conferir que `ci-api-v2/package.json` e `ci-client-v2/apps/web/package.json` não precisam de dependência nova; nenhum `npx shadcn add` — reusa `Field`, `Input`, `Combobox` em `@ci/ui`

**Checkpoint**: Nenhuma instalação; artefatos da spec 044 já em `civ2-docs/specs/044-emissor-criador-ageman/`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Função pura de resolução do emissor + sanitização da sentinela no schema do client — **bloqueia US1–US3**

**⚠️ CRITICAL**: `resolveEmissorUserId` GREEN e schema client transformando `__self__` antes de ligar use-cases ou UI

### Tests first (TDD — RED)

- [x] T002 [P] Escrever testes RED `CT-OUV-EMISSOR-016` em `ci-api-v2/src/modules/ouvidoria/lib/resolve-emissor-user-id.spec.ts`: operador + request de outro id → autenticado; operador sem request → autenticado; admin_tenant/admin_saas + uuid → uuid; admin sem request → `undefined`; `phase: 'confirmed'` → sinal de não aplicar (ex.: `{ apply: false }`)
- [x] T003 [P] Escrever testes RED `CT-OUV-EMISSOR-CLIENT-002` em `ci-client-v2/apps/web/src/modules/ouvidoria/__tests__/manifestacao-draft.schema.test.ts`: uuid válido passa; omitido passa; `''` e `__self__` saem **sem** `emissorUserId` no output; uuid inválido falha

### Implementation for Foundational

- [x] T004 Implementar `resolveEmissorUserId` em `ci-api-v2/src/modules/ouvidoria/lib/resolve-emissor-user-id.ts` usando `resolveUserTableId` de `ci-api-v2/src/common/lib/resolve-user-table-id.ts` — sem I/O, sem Nest (GREEN T002)
- [x] T005 Atualizar `emissorUserId` em `ci-client-v2/apps/web/src/modules/ouvidoria/schemas/manifestacao-draft.schema.ts` para aceitar `uuid | '' | '__self__'` e `transform` de `''`/`__self__` → `undefined` (GREEN T003). API `ci-api-v2/src/modules/ouvidoria/ouvidoria.schemas.ts` **não** aceita `__self__`

**Checkpoint**: `npm test -- --testPathPatterns=resolve-emissor` verde na API; schema draft client verde; nenhum use-case/UI ainda alterado

---

## Phase 3: User Story 1 — Operador institucional cria demanda sem selecionar emissor (Priority: P1) 🎯 MVP

**Goal**: Operador (`user` / `chefe_setor` / `admin_plataforma`) vê Emissor somente leitura com o próprio nome, conclui sem clicar, e o backend grava sempre o autenticado (ignora id no body)

**Independent Test**: Login operador → Nova manifestação → campo readonly → avançar sem tocar Emissor → detalhe mostra o próprio nome. POST com `emissorUserId` de outra pessoa ainda grava o autenticado, sem 400 (`quickstart.md` §2; SC-001/SC-002/SC-004)

### Tests for User Story 1 (TDD — RED first)

- [x] T006 [P] [US1] Reescrever RED `CT-OUV-EMISSOR-007`/`008` e adicionar `CT-OUV-EMISSOR-017` em `ci-api-v2/src/modules/ouvidoria/test/use-cases/create-manifestacao-draft.use-case.spec.ts`: operador + `emissorUserId` de B → persiste A; operador sem id → persiste A; operador + uuid de outro tenant → persiste A **sem** chamar `FindEmissorUserRepository`
- [x] T007 [P] [US1] Reescrever RED `CT-OUV-EMISSOR-CLIENT-005` (operador) em `ci-client-v2/apps/web/src/modules/ouvidoria/__tests__/ManifestacaoStepOneForm.validation.test.tsx`: **sem** `combobox` Emissor; input readonly com o nome recebido
- [x] T008 [P] [US1] Reescrever RED `CT-OUV-EMISSOR-CLIENT-006` (operador) em `ci-client-v2/apps/web/src/modules/ouvidoria/__tests__/ManifestacaoWizardPage.emissor.test.tsx`: `user.role = 'user'` (não `isPlatformAdmin`); continuar sem clicar Emissor; `createManifestacaoDraft` **sem** `emissorUserId` no body; **não** chama `fetchOuvidoriaEmissores`

### Implementation for User Story 1

- [x] T009 [US1] Em `ci-api-v2/src/modules/ouvidoria/use-cases/create-manifestacao-draft.use-case.ts`, resolver emissor com `resolveEmissorUserId({ actor, requestedEmissorUserId: input.emissorUserId, phase: 'draft' })` e persistir o retorno (não o body cru). Só chamar `FindEmissorUserRepository` quando o ator **não** tem linha em `User` e há uuid pedido (GREEN T006). Operador: nunca 400 por divergência de emissor
- [x] T010 [US1] Em `ci-client-v2/apps/web/src/modules/ouvidoria/components/ManifestacaoStepOneForm.tsx`, modo `readonly` quando `role` não é `admin_tenant`/`admin_saas`: `Field` + `Input` `readOnly`/`disabled` com o nome do autenticado; hint “Emissor atribuído automaticamente a quem está registrando.”; sem Combobox (GREEN T007). Paleta Mint / tokens semânticos
- [x] T011 [US1] Em `ci-client-v2/apps/web/src/modules/ouvidoria/pages/ManifestacaoWizardPage.tsx`: passar `user`/`role` ao form; omitir `emissorUserId` no body do save para operador; **não** chamar `fetchOuvidoriaEmissores` nesse ramo (GREEN T008)

**Checkpoint**: US1 independente — operador cria sem select; API força autenticado; lista de emissores não carrega

---

## Phase 4: User Story 2 — Administrador da instituição cria com emissor pré-selecionado (Priority: P2)

**Goal**: `admin_tenant`/`admin_saas` vê Combobox com “eu mesmo” (`__self__`) pré-marcado; enviar sem trocar → emissor `null` + `actorId`/`actorRole` em `dadosAdicionais`; trocar para operador real → grava esse UUID (400 se o uuid não for User do tenant)

**Independent Test**: Login admin → Nova manifestação → opção do próprio nome já marcada → avançar sem clique → detalhe Emissor “—”. Repetir trocando para um operador → detalhe mostra esse nome (`quickstart.md` §3; SC-003)

### Tests for User Story 2 (TDD — RED first)

- [x] T012 [P] [US2] Estender RED `CT-OUV-EMISSOR-017` em `ci-api-v2/src/modules/ouvidoria/test/use-cases/create-manifestacao-draft.use-case.spec.ts`: `admin_tenant` sem id → create **sem** `emissorUserId` e com `dadosAdicionais` contendo `actorId`/`actorRole` (merge, sem apagar outras chaves); `admin_tenant` + uuid válido → persiste uuid e ainda valida tenant; uuid de outro tenant → `EMISSOR_INVALID`
- [x] T013 [P] [US2] Estender RED `CT-OUV-EMISSOR-003` se o create repository passar a receber `dadosAdicionais` em `ci-api-v2/src/modules/ouvidoria/test/repository/manifestacao.repositories.spec.ts`: merge `withActorPayload` sem sobrescrever chaves existentes
- [x] T014 [P] [US2] Estender RED `CT-OUV-EMISSOR-CLIENT-005`/`006` (admin) em `ci-client-v2/apps/web/src/modules/ouvidoria/__tests__/ManifestacaoStepOneForm.validation.test.tsx` e `ManifestacaoWizardPage.emissor.test.tsx`: `role: 'admin_tenant'` → Combobox presente; opção do nome do admin pré-marcada; submit sem troca → body **sem** `emissorUserId`; troca para Fulano → envia uuid; **chama** `fetchOuvidoriaEmissores`

### Implementation for User Story 2

- [x] T015 [US2] Em `ci-api-v2/src/modules/ouvidoria/repository/manifestacao.repositories.ts` (`CreateManifestacaoRepository`), persistir `emissorUserId` já resolvido e fazer merge não destrutivo de `dadosAdicionais` com `withActorPayload` quando o ator não for operador institucional (GREEN T012/T013)
- [x] T016 [US2] Completar o ramo admin em `ci-api-v2/src/modules/ouvidoria/use-cases/create-manifestacao-draft.use-case.ts`: validar tenant só se `resolveEmissorUserId` devolver o uuid pedido; passar actor ao repository para o merge de auditoria (GREEN T012)
- [x] T017 [US2] Em `ManifestacaoStepOneForm.tsx` + `ManifestacaoWizardPage.tsx`: modo `select` para `admin_tenant`/`admin_saas` em criação/rascunho; opção `{ value: '__self__', label }` primeira e pré-marcada; hint “Padrão: você. Pode escolher um operador do tenant.”; fetch de `ci-client-v2/apps/web/src/modules/ouvidoria/api/emissores.ts` só neste ramo (GREEN T014)

**Checkpoint**: US1 intacta; admin envia sem clique (emissor vazio + auditoria) ou escolhe operador real

---

## Phase 5: User Story 3 — Consultar emissor no detalhe e congelar após confirmar (Priority: P2)

**Goal**: Detalhe continua mostrando Emissor (ou “—”); após `status !== draft` nenhum PATCH altera o campo; rascunho ainda recalcula pela mesma regra; histórico não é reescrito

**Independent Test**: Demanda confirmada — detalhe sem edição de Emissor; PATCH com outro `emissorUserId` não muda o valor. Demanda antiga com emissor de outra pessoa permanece (`quickstart.md` §4–5; SC-005/SC-006/SC-007)

### Tests for User Story 3 (TDD — RED first)

- [x] T018 [P] [US3] Escrever RED `CT-OUV-EMISSOR-018` e reescrever `009`/`010` em `ci-api-v2/src/modules/ouvidoria/test/use-cases/update-manifestacao-draft.use-case.spec.ts`: `execute` agora recebe `actor`; draft + operador → recálculo (ignora body); draft + admin troca → uuid (valida tenant); `in_review` + qualquer `emissorUserId` no body → update **sem** `emissor.connect`/`disconnect`
- [x] T019 [P] [US3] Escrever RED `CT-OUV-EMISSOR-019` em `ci-api-v2/src/modules/ouvidoria/ouvidoria.controller.spec.ts`: `update` passa `{ userId, role }` de `req.user` ao use-case
- [x] T020 [P] [US3] Confirmar/estender `CT-OUV-EMISSOR-CLIENT-007` em `ci-client-v2/apps/web/src/modules/ouvidoria/__tests__/ManifestacaoIdentityCard.test.tsx`: Emissor via `ManifestacaoMetaItem` (não inline edit); “—” quando `emissorLabel` null
- [x] T021 [P] [US3] Estender RED wizard em `ci-client-v2/apps/web/src/modules/ouvidoria/__tests__/ManifestacaoWizardPage.emissor.test.tsx`: `editId` com `status: 'in_review'` + `admin_tenant` → **sem** Combobox (readonly com label da API)

### Implementation for User Story 3

- [x] T022 [US3] Atualizar `ci-api-v2/src/modules/ouvidoria/use-cases/update-manifestacao-draft.use-case.ts`: assinar `actor`; se `current.status !== 'draft'`, omitir `emissorUserId` do patch; se draft, recalcular com `resolveEmissorUserId` (GREEN T018). Não alterar `isManifestacaoEditable` em `ci-api-v2/src/modules/ouvidoria/ouvidoria-status.helper.ts`
- [x] T023 [US3] Em `ci-api-v2/src/modules/ouvidoria/ouvidoria.controller.ts`, `PATCH manifestacoes/:id` passar `{ userId: req.user.userId, role: req.user.role }` (GREEN T019)
- [x] T024 [US3] Em `ManifestacaoWizardPage.tsx` + `ManifestacaoStepOneForm.tsx`, forçar modo `readonly` quando `manifestacaoStatus !== 'draft'` (mesmo admin); valor = `emissorLabel` ou “—” (GREEN T021). `ConfirmManifestacaoUseCase` em `ci-api-v2/src/modules/ouvidoria/use-cases/confirm-manifestacao.use-case.ts` **não** toca emissor
- [x] T025 [P] [US3] Garantir que `ci-client-v2/apps/web/src/modules/ouvidoria/components/ManifestacaoIdentityCard.tsx` permanece `ManifestacaoMetaItem` para Emissor (GREEN T020) — sem edição inline

**Checkpoint**: US1+US2 intactas; emissor imutável após confirmar; detalhe só leitura; histórico intocado

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Suíte completa + guia de validação

- [x] T026 Rodar `cd ci-api-v2; npm test -- --testPathPatterns=emissor` e `cd ci-client-v2/apps/web; npm test -- emissor` — todos `CT-OUV-EMISSOR-*` / `CT-OUV-EMISSOR-CLIENT-*` verdes; nenhum `CT-OUV-PUB-*` quebrado
- [x] T027 Percorrer [quickstart.md](./quickstart.md) §§2–5 (operador, admin, imutável, histórico) contra API+web locais

**Checkpoint**: Feature pronta para `/speckit-implement` (já listada) ou demo

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: imediato
- **Foundational (Phase 2)**: depende do Setup — **bloqueia** US1–US3
- **US1 (Phase 3)**: após Phase 2 — MVP
- **US2 (Phase 4)**: após Phase 2; idealmente após US1 (mesmo form/wizard) para evitar conflito de arquivo
- **US3 (Phase 5)**: após Phase 2; após US1 no client (wizard); API update pode começar em paralelo com US2 se outra pessoa pegar só `update-*.ts` + controller
- **Polish (Phase 6)**: após as stories desejadas

### User Story Dependencies

- **US1 (P1)**: sem dependência de US2/US3
- **US2 (P2)**: reusa `resolveEmissorUserId` e o form da US1 (mesmo arquivo no client)
- **US3 (P2)**: reusa a mesma regra no PATCH; detalhe já era readonly

### Within Each User Story

- Testes RED e falhando **antes** da implementação
- Use-case/API antes (ou em paralelo de arquivos distintos) da UI
- Story completa e testável antes de subir prioridade

### Parallel Opportunities

- T002 ∥ T003 (API spec vs client spec)
- T006 ∥ T007 ∥ T008 (três arquivos de teste US1)
- T012 ∥ T013 ∥ T014 (testes US2)
- T018 ∥ T019 ∥ T020 ∥ T021 (testes US3)
- Depois da Phase 2, um dev pode fazer API US1 (T006/T009) enquanto outro esboça os testes de UI (T007/T008)

---

## Parallel Example: User Story 1

```bash
# Testes RED em paralelo:
Task: "RED create-manifestacao-draft.use-case.spec.ts (T006)"
Task: "RED ManifestacaoStepOneForm.validation.test.tsx (T007)"
Task: "RED ManifestacaoWizardPage.emissor.test.tsx (T008)"

# Implementação sequencial no mesmo form/wizard:
Task: "create-manifestacao-draft.use-case.ts (T009)"
Task: "ManifestacaoStepOneForm.tsx (T010)"
Task: "ManifestacaoWizardPage.tsx (T011)"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Phase 1 Setup
2. Phase 2 Foundational (`resolveEmissorUserId` + schema client)
3. Phase 3 US1 (operador readonly + backend força autenticado)
4. **STOP e validar** `quickstart.md` §2
5. Demo ao cliente (o pedido principal)

### Incremental Delivery

1. Setup + Foundational
2. US1 → demo MVP
3. US2 → admin / “eu mesmo”
4. US3 → freeze pós-confirmação
5. Polish (T026–T027)

### Parallel Team Strategy

1. Juntos: Phase 1–2
2. Depois: Dev A US1 API+UI; Dev B testes US2/US3 em arquivos de spec; merge UI do wizard só com uma pessoa por vez (`ManifestacaoWizardPage.tsx` / `ManifestacaoStepOneForm.tsx`)

---

## Notes

- [P] = arquivos diferentes, sem dependência pendente
- Sem migration, sem rota nova, sem `class-validator`
- Nunca persistir `AdminTenant.id` / `AdminPlataforma.id` em `emissorUserId`
- `isPlatformAdmin` **não** decide o modo da UI — usar `user.role`
- Commit após cada task ou grupo lógico
- Próximo comando após esta lista: `/speckit-implement`
