---

description: "Task list for feature 045 — Recuperar último rascunho de manifestação (Ouvidoria)"
---

# Tasks: Recuperar último rascunho de manifestação (Ouvidoria)

**Input**: Design documents from `civ2-docs/specs/045-rascunho-manifestacao-ouvidoria/`

**Prerequisites**: [plan.md](./plan.md), [spec.md](./spec.md), [research.md](./research.md), [data-model.md](./data-model.md), [contracts/](./contracts/), [quickstart.md](./quickstart.md) — todos já existentes.

**Tests**: Constitution II (Test-First) é NON-NEGOTIABLE neste monorepo — todas as tarefas de teste abaixo são obrigatórias, RED antes de GREEN. IDs seguem `contracts/test-strategy.md` (`CT-OUV-RASCUNHO-*` / `CT-OUV-RASCUNHO-CLIENT-*`).

**Organization**: Tarefas agrupadas por user story (spec.md) para entrega e teste independentes.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Pode rodar em paralelo (arquivos diferentes, sem dependência pendente)
- **[Story]**: US1–US4, conforme spec.md
- Caminhos de arquivo exatos em cada descrição

## Path Conventions

Monorepo já estruturado (sem novo pacote) — ver `plan.md` § Project Structure:

- API: `ci-api-v2/src/modules/ouvidoria/`
- Client: `ci-client-v2/apps/web/src/modules/ouvidoria/`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Dependências novas e o allowlist do guardrail de SC-010 — pré-requisito para qualquer arquivo tocar IndexedDB.

- [x] T001 Adicionar `idb` (dependencies) e `fake-indexeddb` (devDependencies) em `ci-client-v2/apps/web/package.json`; rodar `npm install`
- [x] T002 [P] Atualizar o guardrail `ci-client-v2/apps/web/src/modules/ouvidoria/__tests__/no-business-storage.test.ts`: estender a checagem para também detectar `indexedDB.open(`/`openDB(` fora de um allowlist explícito de `lib/rascunho-local/**`; adicionar comentário no topo do arquivo linkando esta spec (045) e a nota de exceção em `civ2-docs/specs/038-migracao-modulos-v1/spec.md` (SC-010). Rodar agora e confirmar que passa (nenhum arquivo em `lib/rascunho-local/**` existe ainda) — CT-OUV-RASCUNHO-CLIENT-008
- [x] T003 Registrar `fake-indexeddb/auto` no setup do Vitest de `ci-client-v2/apps/web` (novo `vitest.setup.rascunho-local.ts` importado em `vitest.config.ts`, ou arquivo de setup existente) — depende de T001

**Checkpoint**: Dependências instaladas, guardrail com allowlist pronto (ainda vazio) — seguro para começar a criar `lib/rascunho-local/**`.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Primitivas de armazenamento local usadas por **todas** as user stories (US1–US4) — nenhuma story começa antes disto.

**⚠️ CRITICAL**: Nenhuma user story pode iniciar antes desta fase estar completa.

- [x] T004 [P] Criar `rascunho-local-key.ts` (função pura: chave composta `` `${tenantId}:${userId}` ``) + teste em `ci-client-v2/apps/web/src/modules/ouvidoria/lib/rascunho-local/rascunho-local-key.ts` e `lib/rascunho-local/__tests__/rascunho-local-key.test.ts`
- [x] T005 [P] Criar `rascunho-local-db.ts` (abre o banco `ci-ouvidoria-rascunho` e o object store `rascunho-local` via `idb`) em `ci-client-v2/apps/web/src/modules/ouvidoria/lib/rascunho-local/rascunho-local-db.ts`
- [x] T006 Criar `rascunho-local-store.ts` (`put`/`get`/`delete` por chave) + teste com `fake-indexeddb` — CT-OUV-RASCUNHO-CLIENT-001 — em `lib/rascunho-local/rascunho-local-store.ts` e `lib/rascunho-local/__tests__/rascunho-local-store.test.ts` (depende de T004, T005)
- [x] T007 [P] Criar `rascunho-local-expiry.ts` (regra de 24h: elegível se `Date.now() - updatedAt <= 24h`, senão remove) + teste — CT-OUV-RASCUNHO-CLIENT-002 — em `lib/rascunho-local/rascunho-local-expiry.ts` e `lib/rascunho-local/__tests__/rascunho-local-expiry.test.ts`
- [x] T008 [P] Criar `rascunho-local-anexos-limit.ts` (regra de 30MB total / 5 arquivos; anexo excedente é descartado no momento da gravação) + teste — CT-OUV-RASCUNHO-CLIENT-003 — em `lib/rascunho-local/rascunho-local-anexos-limit.ts` e `lib/rascunho-local/__tests__/rascunho-local-anexos-limit.test.ts`

**Checkpoint**: Primitivas de storage local prontas e testadas — user stories podem começar.

---

## Phase 3: User Story 1 - Continuar preenchimento após perda de sessão (Priority: P1) 🎯 MVP

**Goal**: Operador com rascunho local elegível (já existente no IndexedDB) vê o convite acima da tabela e, ao retomar, o assistente reabre com os dados e a etapa restaurados.

**Independent Test**: Semear um registro no IndexedDB (via `rascunho-local-store` do Foundational) simulando preenchimento parcial; abrir a lista e confirmar o convite; clicar em retomar e confirmar que o assistente restaura os dados — **sem** depender ainda da gravação automática real (essa é a US3).

### Tests for User Story 1 ⚠️

- [x] T009 [P] [US1] Teste do hook `use-ultimo-rascunho-convite` (versão sem `manifestacaoId`): rascunho vazio → `hidden`; rascunho elegível não vazio → `visible-unchecked` (sem chamar API) — subconjunto de CT-OUV-RASCUNHO-CLIENT-005 — em `ci-client-v2/apps/web/src/modules/ouvidoria/lib/rascunho-local/__tests__/use-ultimo-rascunho-convite.test.ts`
- [x] T010 [P] [US1] Teste RTL de `UltimoRascunhoBanner`: renderiza convite quando `visible-*`, nada quando `hidden`, "Retomar" navega para `/ouvidoria/manifestacoes/nova` com estado de hidratação — subconjunto de CT-OUV-RASCUNHO-CLIENT-006 — em `ci-client-v2/apps/web/src/modules/ouvidoria/components/list/__tests__/UltimoRascunhoBanner.test.tsx`
- [x] T011 [P] [US1] Teste RTL de `ManifestacaoWizardPage`: ao montar sem `editId` e com estado de retomada, hidrata `form`/`step` a partir do IndexedDB, sem chamar `getManifestacaoDetail` — CT-OUV-RASCUNHO-CLIENT-007 — em `ci-client-v2/apps/web/src/modules/ouvidoria/__tests__/ManifestacaoWizardPage.rascunho-local.test.tsx`

### Implementation for User Story 1

- [x] T012 [US1] Implementar `use-ultimo-rascunho-convite.ts` (versão MVP: lê o store, aplica expiração + checagem de vazio, computa `hidden`/`visible-unchecked`; ainda sem chamada de API) em `ci-client-v2/apps/web/src/modules/ouvidoria/lib/rascunho-local/use-ultimo-rascunho-convite.ts` (depende de T006, T007; GREEN de T009)
- [x] T013 [US1] Implementar `UltimoRascunhoBanner.tsx` (consome o hook; ação "Retomar" navega para `/ouvidoria/manifestacoes/nova` passando estado de hidratação via `react-router` `state`) em `ci-client-v2/apps/web/src/modules/ouvidoria/components/list/UltimoRascunhoBanner.tsx` (depende de T012; GREEN de T010)
- [x] T014 [US1] Integrar `<UltimoRascunhoBanner />` acima de `InstitutionalTableCard` em `ci-client-v2/apps/web/src/modules/ouvidoria/pages/ManifestacoesListPage.tsx`
- [x] T015 [US1] Adicionar hidratação em `ci-client-v2/apps/web/src/modules/ouvidoria/pages/ManifestacaoWizardPage.tsx`: ao montar sem `editId` e com estado de retomada na navegação, ler o rascunho local via `rascunho-local-store` e popular `form`/`step` (depende de T006; GREEN de T011)
- [x] T016 [US1] Rodar `quickstart.md` §2 (parte de leitura/retomada, com registro semeado manualmente) e confirmar CT-OUV-RASCUNHO-CLIENT-005 (subconjunto)/006/007 verdes

**Checkpoint**: User Story 1 funcional e testável de forma independente — MVP entregável (ainda com gravação local semeada manualmente; a gravação automática real chega na US3).

---

## Phase 4: User Story 2 - Ocultar convite quando o envio já foi concluído (Priority: P1)

**Goal**: Backend valida se o rascunho referenciado ainda é retomável; a interface oculta o convite e invalida a cópia local quando o envio já foi confirmado (ou a consulta falha tecnicamente).

**Independent Test**: Rascunho local com `manifestacaoId` vinculado a uma manifestação já não mais em `draft` → convite não aparece e cópia local é removida; consulta ao endpoint falhando tecnicamente → convite oculto, cópia local preservada (FR-016).

### Tests for User Story 2 ⚠️

- [x] T017 [P] [US2] Teste de `GetManifestacaoRetomabilidadeUseCase`: `draft` + dono/tenant correto → `{ retomavel: true }`; demais status → `{ retomavel: false }`; outro operador do mesmo tenant → `{ retomavel: false }` sem erro; id inexistente → `NotFoundException`; outro tenant → `NotFoundException` — CT-OUV-RASCUNHO-001 — em `ci-api-v2/src/modules/ouvidoria/test/use-cases/get-manifestacao-retomabilidade.use-case.spec.ts`
- [x] T018 [P] [US2] Teste do handler `OuvidoriaController.retomabilidade`: passa `{ userId, role }` de `req.user` ao use-case; exige `@RequireModulo('ouvidoria')` — CT-OUV-RASCUNHO-002 — em `ci-api-v2/src/modules/ouvidoria/ouvidoria.controller.spec.ts`
- [x] T019 [P] [US2] Teste de isolamento multi-tenant no endpoint de retomabilidade (espelha SC-009 da 038) — CT-OUV-RASCUNHO-003 — em `ci-api-v2/src/modules/ouvidoria/ouvidoria.controller.spec.ts`
- [x] T020 [P] [US2] Teste do hook `use-ultimo-rascunho-convite` (branch com `manifestacaoId`): `retomavel: true` → `visible-checked`; `retomavel: false` → `hidden` + remove registro local; falha de rede/timeout → `hidden`, registro local preservado — CT-OUV-RASCUNHO-CLIENT-005 (completo) — em `lib/rascunho-local/__tests__/use-ultimo-rascunho-convite.test.ts`

### Implementation for User Story 2

- [x] T021 [US2] Implementar `GetManifestacaoRetomabilidadeUseCase` reaproveitando `RequireManifestacaoRepository` + `resolveUserTableId` (regra `admin-tenant-user-fk`) em `ci-api-v2/src/modules/ouvidoria/use-cases/get-manifestacao-retomabilidade.use-case.ts` (depende de T017)
- [x] T022 [US2] Adicionar rota `GET manifestacoes/:id/retomabilidade` em `ci-api-v2/src/modules/ouvidoria/ouvidoria.controller.ts` (depende de T021, T018, T019)
- [x] T023 [P] [US2] Adicionar `getManifestacaoRetomabilidade(id)` em `ci-client-v2/apps/web/src/modules/ouvidoria/api/manifestacoes.ts`
- [x] T024 [US2] Estender `use-ultimo-rascunho-convite.ts`: quando houver `manifestacaoId`, chamar o endpoint; `retomavel: false` → apagar registro local + `hidden`; falha técnica → `hidden` mantendo o registro local (FR-016) (depende de T023, T012; GREEN de T020)
- [x] T025 [US2] Gravar o `manifestacaoId` retornado por `createManifestacaoDraft`/`updateManifestacaoDraft` no registro local (link institucional ↔ local, FR-014) em `ci-client-v2/apps/web/src/modules/ouvidoria/pages/ManifestacaoWizardPage.tsx`
- [x] T026 [US2] Ao concluir `confirmManifestacao` com sucesso, remover o registro local (FR-008) em `ManifestacaoWizardPage.tsx`
- [x] T027 [US2] Rodar `quickstart.md` §3 e §4; confirmar CT-OUV-RASCUNHO-001/002/003 e CLIENT-005 verdes

**Checkpoint**: User Stories 1 e 2 funcionam de forma independente.

---

## Phase 5: User Story 3 - Gravação automática durante o preenchimento (Priority: P2)

**Goal**: O assistente grava o progresso localmente em tempo real (por campo com debounce, salvaguarda de 5s, e por etapa), sem depender do servidor — substitui a semeadura manual usada nos testes de US1/US2 pelo caminho de produção real.

**Independent Test**: Preencher campos no assistente com rede desligada/API indisponível; recarregar ou reautenticar; confirmar que os dados permanecem no IndexedDB e recuperáveis pelo convite.

### Tests for User Story 3 ⚠️

- [x] T028 [P] [US3] Teste de `use-rascunho-local-autosave`: mudança de campo → grava (debounce); sem mudança por 5s → não grava de novo; mudança de etapa → grava imediatamente mesmo sem mudança de campo — CT-OUV-RASCUNHO-CLIENT-004 — em `ci-client-v2/apps/web/src/modules/ouvidoria/lib/rascunho-local/__tests__/use-rascunho-local-autosave.test.ts`

### Implementation for User Story 3

- [x] T029 [US3] Implementar `use-rascunho-local-autosave.ts` (debounce por campo + `setInterval` de salvaguarda 5s + gravação imediata por etapa, usando `rascunho-local-store`) em `ci-client-v2/apps/web/src/modules/ouvidoria/lib/rascunho-local/use-rascunho-local-autosave.ts` (depende de T006; GREEN de T028)
- [x] T030 [US3] Conectar o hook em `ManifestacaoWizardPage.tsx`: chamar a cada mudança relevante de `form`/`step` (substitui a semeadura manual da US1/US2 pelo fluxo real de produção)
- [x] T031 [US3] Aplicar `rascunho-local-anexos-limit.ts` (T008) ao adicionar anexos no assistente (etapa 2 / `AnexoUploadZone`): anexo que excede o limite não é persistido localmente e exibe aviso de reanexar ao retomar
- [x] T032 [US3] Rodar `quickstart.md` §2 (fluxo completo, agora com autosave real) e §5 (limite de anexos); confirmar CT-OUV-RASCUNHO-CLIENT-004 e 003 verdes ponta a ponta

**Checkpoint**: User Stories 1, 2 e 3 funcionam de forma independente; gravação automática real está no ar.

---

## Phase 6: User Story 4 - Descartar ou substituir rascunho (Priority: P3)

**Goal**: Operador pode descartar explicitamente o rascunho recuperável, com confirmação obrigatória sempre que houver dado não vazio.

**Independent Test**: Com rascunho disponível, escolher "Nova manifestação", confirmar descarte, verificar que o convite some e o formulário abre limpo.

### Tests for User Story 4 ⚠️

- [x] T033 [P] [US4] Teste RTL: botão "Descartar" do `UltimoRascunhoBanner` exige confirmação antes de remover — subconjunto de CT-OUV-RASCUNHO-CLIENT-006 — em `components/list/__tests__/UltimoRascunhoBanner.test.tsx`
- [x] T034 [P] [US4] Teste: iniciar "Nova manifestação" com rascunho local não vazio exige confirmação explícita (FR-009) antes de navegar/limpar — em `ci-client-v2/apps/web/src/modules/ouvidoria/pages/__tests__/ManifestacoesListPage.rascunho-local.test.tsx`

### Implementation for User Story 4

- [x] T035 [US4] Adicionar ação "Descartar" + diálogo de confirmação (padrão shadcn `AlertDialog`, mesmo espírito de `ForwardManifestacaoDialog`) em `UltimoRascunhoBanner.tsx` (depende de T013; GREEN de T033)
- [x] T036 [US4] No(s) ponto(s) de entrada de "Nova manifestação" (botão da lista e ação do próprio convite), checar rascunho local não vazio e exigir confirmação antes de navegar para um assistente limpo (GREEN de T034)
- [x] T037 [US4] Ao confirmar descarte, remover o registro local via `rascunho-local-store` (chamado pelos dois pontos acima)
- [x] T038 [US4] Rodar `quickstart.md` §6 e confirmar testes verdes

**Checkpoint**: Todas as 4 user stories funcionam de forma independente.

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Validações finais que atravessam as 4 stories.

- [x] T039 [P] Rodar `quickstart.md` §7 (isolamento por operador/tenant no mesmo navegador) — confirma SC-004
- [x] T040 [P] Revisão de acessibilidade/UX do `UltimoRascunhoBanner` (contraste paleta Mint, foco por teclado nos botões, `aria-live` ao aparecer) — skill `ui-ux-pro-max`
- [x] T041 Revisar textos de UI do convite/confirmações contra `.cursor/docs/regras-plataforma.md` — vocabulário institucional, sem jargão técnico ("token", "IndexedDB", "cache") nas mensagens ao operador (Assumption da spec.md)
- [x] T042 Rodar as suítes completas e registrar resultado:
  ```powershell
  cd ci-api-v2; npm test -- --testPathPatterns=rascunho
  cd ci-client-v2/apps/web; npm test -- rascunho-local no-business-storage ManifestacaoWizardPage ManifestacoesListPage
  ```

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: sem dependências — pode começar imediatamente
- **Foundational (Phase 2)**: depende de Setup (T001/T003) — **bloqueia** todas as user stories
- **User Stories (Phase 3–6)**: todas dependem de Foundational completo
  - US1 e US2 são **P1** — priorizar ambas antes de US3/US4
  - US2 pode começar em paralelo a US1 (não depende do UI da US1, só reutiliza `UltimoRascunhoBanner` na integração final — T024 depende de T012, não de T013/T014)
  - US3 depende apenas do Foundational (T006) — pode ser feita em paralelo a US1/US2, mas faz mais sentido sequencialmente pois valida o caminho real de produção que US1/US2 assumiram semeado
  - US4 depende de `UltimoRascunhoBanner` existir (T013, da US1)
- **Polish (Phase 7)**: depende de todas as stories desejadas estarem completas

### Within Each User Story

- Testes escritos e **FALHANDO** antes da implementação (RED → GREEN → REFACTOR, Constitution II)
- Primitivas/serviços antes de hooks; hooks antes de componentes; componentes antes de integração nas páginas
- Story completa (checkpoint) antes de avançar para a próxima prioridade

### Parallel Opportunities

- Setup: T002 pode rodar em paralelo a T001 (T003 depende de T001)
- Foundational: T004, T005, T007, T008 em paralelo entre si (T006 depende de T004+T005)
- Testes de uma mesma story marcados [P] podem rodar em paralelo (arquivos diferentes)
- US2 (API: T017–T019, T021–T022) pode ser trabalhada em paralelo à US1 (client: T009–T016) por pessoas/sessões diferentes — convergem em T024

---

## Parallel Example: Foundational (Phase 2)

```bash
# Após T001 (deps instaladas):
Task: "Criar rascunho-local-key.ts + teste (T004)"
Task: "Criar rascunho-local-db.ts (T005)"
Task: "Criar rascunho-local-expiry.ts + teste (T007)"
Task: "Criar rascunho-local-anexos-limit.ts + teste (T008)"
# T006 (store) só depois de T004+T005
```

## Parallel Example: User Story 1 (Phase 3)

```bash
# Testes primeiro, em paralelo (arquivos diferentes):
Task: "Teste use-ultimo-rascunho-convite (T009)"
Task: "Teste UltimoRascunhoBanner (T010)"
Task: "Teste ManifestacaoWizardPage hidratação (T011)"
```

---

## Implementation Strategy

### MVP First (User Story 1 apenas)

1. Completar Phase 1: Setup
2. Completar Phase 2: Foundational (bloqueia todas as stories)
3. Completar Phase 3: User Story 1
4. **PARAR e VALIDAR**: testar US1 de forma independente (com registro semeado manualmente) — `quickstart.md` §2 parcial
5. Deploy/demo se pronto — já entrega valor de "existe um jeito de retomar", mesmo antes da gravação automática real (US3)

### Incremental Delivery

1. Setup + Foundational → base pronta
2. US1 → testar independentemente → demo (MVP! ainda com semeadura manual)
3. US2 → testar independentemente → demo (agora com validação server-side e ocultação segura)
4. US3 → testar independentemente → demo (agora a gravação é real, sem semeadura manual — feature completa ponta a ponta)
5. US4 → testar independentemente → demo (controle explícito de descarte)
6. Cada story adiciona valor sem quebrar as anteriores

### Parallel Team Strategy

Com múltiplos desenvolvedores:

1. Time completa Setup + Foundational junto
2. Depois do Foundational:
   - Dev A: US1 (client — banner + hidratação)
   - Dev B: US2 (API — endpoint de retomabilidade) — converge com A em T024
   - Dev C: US3 (hook de autosave) — pode iniciar em paralelo, converge em T030
3. US4 depende de US1 (`UltimoRascunhoBanner` precisa existir)

---

## Notes

- [P] = arquivos diferentes, sem dependência pendente
- [Story] mapeia a tarefa à user story correspondente (rastreabilidade com `spec.md`)
- IDs de teste (`CT-OUV-RASCUNHO-*`) rastreiam `contracts/test-strategy.md`
- Verificar que os testes falham (RED) antes de implementar (GREEN) — Constitution II, non-negotiable
- Commit após cada tarefa ou grupo lógico
- Parar em qualquer checkpoint para validar a story isoladamente
- T002 (guardrail SC-010) deve existir **antes** de qualquer arquivo em `lib/rascunho-local/**` — prova que o allowlist é necessário, não decorativo
