---

description: "Task list for feature 048 — Identificação sem anônimo + e-mail"
---

# Tasks: Identificação sem anônimo + e-mail

**Input**: Design documents from `civ2-docs/specs/048-identificacao-sem-anonimo/` (`plan.md`, `spec.md`, `research.md`, `data-model.md`, `contracts/`, `quickstart.md`)

**Tests**: Constitution §II (Test-First) é NON-NEGOTIABLE neste monorepo — skills `tdd` + `testing-conventions` (API) / `zod-validation-sanitization` + `ui-ux-pro-max` + `vite-react-best-practices` (client) aplicadas antes de cada implementação. Escrever/ajustar cada teste marcado abaixo e confirmar RED antes da tarefa de implementação correspondente.

**Organization**: Tarefas agrupadas por user story (spec.md) para permitir implementação e teste independentes de cada uma. A troca do gatilho da regra de nome obrigatório (`isAnonymous` → `type`) tem efeito colateral em várias suítes de teste já existentes que hoje dependem do default antigo (`isAnonymous: true` ⇒ nome nunca exigido) — esse levantamento foi feito arquivo a arquivo e está refletido nas tarefas da Fase 2 (Foundational).

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Pode rodar em paralelo (arquivos diferentes, sem dependência de tarefa incompleta)
- **[Story]**: US1–US3, mapeando para as user stories de `spec.md`
- Setup/Foundational/Polish: sem label de story

## Path Conventions (Web application — ver `plan.md`)

- API: `ci-api-v2/src/modules/ouvidoria/ouvidoria.schemas.ts` + `ouvidoria.schemas.spec.ts`
- Client: `ci-client-v2/apps/web/src/modules/ouvidoria/` (`schemas/`, `components/`, `pages/`, `__tests__/`, `lib/__tests__/`)
- **Fora de escopo (não tocar)**: `ci-client-v2/apps/publico/**`, `criarManifestacaoPublicaBodySchema` (API)

---

## Phase 1: Setup

Sem tarefas — zero dependência nova, zero migração de banco (ver `plan.md` § Constraints e § Technical Context). A feature cabe inteiramente na camada de validação (Zod) e apresentação (JSX) de um módulo já existente.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Trocar o gatilho da regra "nome do solicitante obrigatório" de `isAnonymous === false` para `type !== 'whistleblower'`, em API e client (espelhados), incluindo o novo default `isAnonymous: false`. Esta regra é a base de US1 e US3, e sua mudança **quebra várias suítes de teste já existentes** que hoje se apoiam no default antigo — o levantamento de cada arquivo afetado está nas tarefas abaixo.

**⚠️ CRITICAL**: Nenhuma user story pode começar antes desta fase estar completa e com a suíte de regressão listada 100% verde.

- [X] T001 [P] **RED (API)** — Em `ci-api-v2/src/modules/ouvidoria/ouvidoria.schemas.spec.ts`:
  - Substituir o trio de testes `'PATCH rejeita isAnonymous false sem nome do solicitante'` / `'PATCH rejeita nome do solicitante só com espaços quando identificada'` / `'PATCH aceita isAnonymous false com nome válido'` (dentro de `describe('ouvidoria.schemas mensagens PT-BR (CT-OUV-ERR)', ...)`) por um novo bloco `describe('ouvidoria.schemas identificação — nome obrigatório exceto denúncia (spec 048)', ...)` com os casos: PATCH `{ type: 'complaint' }` → falha em `requesterFullName` (mensagem `/nome do solicitante/i`); PATCH `{ type: 'complaint', requesterFullName: '   ' }` → falha; PATCH `{ type: 'complaint', requesterFullName: 'Maria Silva' }` → sucesso; PATCH `{ type: 'whistleblower' }` → sucesso (exceção denúncia); CREATE `{ type: 'whistleblower', subject: 'Relato', description: 'Descrição' }` → sucesso; CREATE `{ type: 'complaint', subject: 'Relato', description: 'Descrição' }` → falha em `requesterFullName`; CREATE `{ type: 'complaint', subject: 'Relato', description: 'Descrição', requesterFullName: 'Maria Silva' }` → sucesso **e** `parsed.data.isAnonymous === false` (novo default).
  - Corrigir os fixtures que quebram como efeito colateral do novo gatilho (adicionar `requesterFullName: 'Maria Silva'`): `base` em `describe('ouvidoria.schemas replyEmail opcional ...')` (usa `type: 'complaint'`); `base` em `describe('ouvidoria.schemas emissorUserId ...')`; o literal do teste `'aceita emissorUserId também na atualização parcial'` (PATCH só com `emissorUserId`); o literal do teste `'rascunho normaliza assunto e descrição com trim'`; os literais dos testes `'rascunho aceita prazoInicio/prazoFim ISO date na concessionária'` e `'rascunho aceita contato prévio com a concessionária'`; o literal do teste `'PATCH aceita edição do protocolo gerado e do número institucional'` (`describe('ouvidoria.schemas protocolo institucional', ...)`).
  - **Não** mexer nos testes que já esperam `success === false` por outro motivo (assunto/descrição vazios, tipo inválido, prazoInicio/prazoFim inválidos) — eles continuam falhando pelo motivo original, a mensagem específica pesquisada por `firstMessage(...)` não é afetada por uma issue extra em `requesterFullName`.
  - Confirmar RED: os novos casos de denúncia/whistleblower falham contra a implementação atual (que ainda usa `isAnonymous` como gatilho).

- [X] T002 **GREEN (API)** — Em `ci-api-v2/src/modules/ouvidoria/ouvidoria.schemas.ts`: renomear `refineIdentifiedManifestacaoRequiresName` para `refineRequesterNameRequiredUnlessWhistleblower`, trocando o predicado de `data.isAnonymous === false` para `data.type !== 'whistleblower'` (assinatura passa a receber `{ type?: string; requesterFullName?: string }`); trocar `isAnonymous: z.boolean(...).optional().default(true)` para `.default(false)` em `draftFieldsSchema`; manter as duas aplicações em `createManifestacaoDraftBodySchema`/`updateManifestacaoDraftBodySchema` apontando para a função renomeada. **Não tocar** `criarManifestacaoPublicaBodySchema` (schema totalmente separado, fora de escopo — FR-008). Rodar `ouvidoria.schemas.spec.ts` e confirmar GREEN (depende de T001).

- [X] T003 [P] **RED (Client)** — Em `ci-client-v2/apps/web/src/modules/ouvidoria/__tests__/manifestacao-draft.schema.test.ts`:
  - Adicionar `requesterFullName: 'Maria Silva'` ao objeto `validBase` (linha ~7) — corrige de uma vez a maioria dos `expectPass` colaterais (min/max length, telefones, endereço, concessionária, emissorUserId, prioridade) que hoje só passam porque o nome nunca era exigido por padrão.
  - Substituir `describe('identificação — condicional isAnonymous', ...)` por `describe('identificação — nome obrigatório exceto denúncia (spec 048)', ...)` com casos equivalentes aos da API (T001): tipo não-denúncia sem nome → fail (path `requesterFullName`, mensagem `'Informe o nome do solicitante.'`); tipo não-denúncia com nome só espaços → fail; tipo não-denúncia com nome válido → pass; `type: 'whistleblower'` sem nome → pass; `type: 'whistleblower'` com nome → pass.
  - Reescrever `describe('tipo de manifestação — campos condicionais', ...)`: o teste atual `'todos os tipos aceitam payload mínimo (tipo não altera campos obrigatórios)'` fica **falso** como regra de negócio pós-mudança — substituir por dois testes: tipos não-denúncia (`complaint`, `request`, `praise`, `suggestion`, `simplify`) exigem `requesterFullName` (payload mínimo sem nome falha para cada um); `whistleblower` aceita payload mínimo sem nome.
  - Em `describe('mensagens em português (sem Invalid input)', ...)`, no array `cases`, trocar a entrada `{ ...validBase, isAnonymous: false }` (que passaria a ter sucesso com `validBase` agora incluindo nome) por `{ ...validBase, requesterFullName: '' }`, preservando a intenção de um caso que deve continuar falhando.
  - Confirmar RED nos novos casos de denúncia contra a implementação atual do client.

- [X] T004 **GREEN (Client)** — Em `ci-client-v2/apps/web/src/modules/ouvidoria/schemas/manifestacao-draft.schema.ts`: trocar o predicado do `.superRefine` de `data.isAnonymous === false` para `data.type !== 'whistleblower'` e a mensagem para `'Informe o nome do solicitante.'` (mesma redação da API); `isAnonymous` permanece `z.boolean().optional()` no `z.object` (tipo inalterado). Rodar `manifestacao-draft.schema.test.ts` e confirmar GREEN (depende de T003).

- [X] T005 [P] Corrigir suítes de fluxo do assistente que quebram só pela mudança de regra (independem da remoção dos cards, que é escopo de US1):
  - `ci-client-v2/apps/web/src/modules/ouvidoria/__tests__/ManifestacaoWizardPage.emissor.test.tsx` — no teste `'continua sem clicar em Emissor e cria rascunho sem emissorUserId no body'`, preencher "Nome completo" (`fireEvent`/`user.type`) antes de clicar em "Continuar para anexos".
  - `ci-client-v2/apps/web/src/modules/ouvidoria/__tests__/ManifestacaoWizardPage.emissor-admin.test.tsx` — mesmo ajuste nos dois testes que clicam "Continuar para anexos" (`'admin_tenant continua sem trocar emissor...'` e `'admin_tenant troca para Fulano...'`).
  - `ci-client-v2/apps/web/src/modules/ouvidoria/__tests__/ManifestacaoWizardPage.save-draft.test.tsx` — nos testes `'cliques rápidos em Continuar disparam no máximo um createManifestacaoDraft'` e `'segunda chamada saveDraft após create usa updateManifestacaoDraft'`, preencher "Nome completo" junto com Assunto/Descrição antes de clicar Continuar (**não** alterar aqui o teste `'ao continuar com form inválido...'` — ele pertence à T009, na fase US1, porque depende da remoção do card).
  - Confirmar as suítes GREEN (depende de T004).

- [X] T006 [P] Atualizar fixtures compartilhadas de manifestações com `type` não-denúncia e sem `requesterFullName`, hoje inválidas pela nova regra:
  - `ci-client-v2/apps/web/src/test/msw/handlers/ouvidoria-manifestacoes.ts` — adicionar `requesterFullName: 'Fulano de Tal'` às linhas `man-draft-1`, `man-review-1` e `man-closed-1`, tanto no array `rows` inicial quanto dentro de `resetManifestacoesHandlersState()`.
  - `ci-client-v2/apps/web/src/modules/ouvidoria/__tests__/ManifestacaoWizardPage.edit-mode.test.tsx` — no teste `'no passo 2 lista anexos já persistidos no GET de detalhe'`, adicionar `requesterFullName: 'Fulano de Tal'` ao mock inline de `getManifestacaoDetail`.
  - Confirmar que `'em análise exibe Salvar alterações e não chama confirmar'` (mesmo arquivo) continua GREEN após o ajuste da fixture MSW (depende de T004).

- [X] T007 Rodar as suítes afetadas pela Foundational e confirmar GREEN antes de iniciar as user stories:
  ```powershell
  cd ci-api-v2; npm test -- --testPathPatterns=ouvidoria.schemas
  cd ci-client-v2/apps/web; npm test -- manifestacao-draft.schema ManifestacaoWizardPage.emissor ManifestacaoWizardPage.save-draft ManifestacaoWizardPage.edit-mode
  ```

**Checkpoint**: Regra "nome obrigatório exceto denúncia" funciona em API e client; toda a suíte de regressão impactada pela troca de default está verde. US1–US3 podem começar.

---

## Phase 3: User Story 1 - Registrar manifestação sempre identificada no assistente interno (Priority: P1) 🎯 MVP

**Goal**: Remover os cards «Permanecer anônimo» / «Quero me identificar» — o formulário de dados do manifestante fica sempre visível; a exceção de nome para denúncia funciona ponta a ponta na UI.

**Independent Test**: Abrir o assistente de nova manifestação, confirmar ausência dos cards e presença direta do grid de identificação; tentar avançar sem nome (tipo ≠ denúncia) e ver o bloqueio; escolher denúncia sem nome e avançar com sucesso.

### Tests for User Story 1

- [X] T008 [P] [US1] **RED** — Em `ci-client-v2/apps/web/src/modules/ouvidoria/__tests__/ManifestacaoStepOneForm.validation.test.tsx`:
  - Substituir o teste `'modo identificado exibe campos de identificação'` por um teste que confirma o novo comportamento sempre-visível: `renderForm()`; `expect(screen.getByText('Nome completo')).toBeInTheDocument()` (sem clique prévio); `expect(screen.queryByRole('button', { name: /Permanecer anônimo/i })).not.toBeInTheDocument()`; `expect(screen.queryByRole('button', { name: /Quero me identificar/i })).not.toBeInTheDocument()`; `expect(screen.getByText('Dados do manifestante.')).toBeInTheDocument()` (novo texto do `SectionHeader`, substitui "Escolha se o manifestante permanece anônimo ou deseja se identificar.").
  - Simplificar os dois testes que hoje usam `renderForm({ form: { ...emptyForm, isAnonymous: false } })` / `renderForm({ form: { isAnonymous: false } })` (`'modo identificado renderiza campos CPF e telefones'` e `'CPF/CNPJ não aplica máscara (input livre)'`) para `renderForm()` simples — a visibilidade do grid deixa de depender de `isAnonymous`.
  - Confirmar RED (os testes falham contra a implementação atual, que ainda tem os cards e o wrapper condicional).

- [X] T009 [US1] **RED** — Em `ci-client-v2/apps/web/src/modules/ouvidoria/__tests__/ManifestacaoWizardPage.save-draft.test.tsx`, no teste `'ao continuar com form inválido, destaca e foca o primeiro campo com erro'`: remover a linha `await user.click(screen.getByRole('button', { name: /quero me identificar/i }))` (o botão deixa de existir); o restante do teste continua válido (nome em branco por padrão → mesmo erro de validação). Confirmar RED (o `getByRole` do botão removido quebra o teste atual assim que os cards saírem do componente — por isso este ajuste faz parte do RED desta story, não da Foundational).

### Implementation for User Story 1

- [X] T010 [US1] Em `ci-client-v2/apps/web/src/modules/ouvidoria/components/ManifestacaoStepOneForm.tsx`, dentro do `<Card>` "Identificação": remover o bloco `<div className="grid gap-3 sm:grid-cols-2">` com os dois `<button>` («Permanecer anônimo» / «Quero me identificar», incluindo os ícones `Shield`/`UserCircle2`); remover o wrapper condicional `{!form.isAnonymous && ( ... )}` ao redor do grid de campos do manifestante — o grid passa a renderizar sempre (sem a condição); trocar a `description` do `SectionHeader` de "Escolha se o manifestante permanece anônimo ou deseja se identificar." para "Dados do manifestante."; remover os imports agora não usados `Shield` e `UserCircle2` de `lucide-react`. (GREEN de T008/T009)

- [X] T011 [US1] No mesmo arquivo, no `Field` "Nome completo" dentro do grid de identificação: adicionar `required={form.type !== 'whistleblower'}` (mesma convenção de asterisco já usada em "Tipo"/"Assunto"/"Descrição" — comunica visualmente a exceção da FR-009).

- [X] T012 [US1] Em `ci-client-v2/apps/web/src/modules/ouvidoria/pages/ManifestacaoWizardPage.tsx`: trocar `emptyForm.isAnonymous: true` para `false` (reflete FR-003 — a manifestação nasce sempre tratada como identificada; sem efeito na validação, que agora depende de `type`).

- [X] T013 [P] [US1] Novo teste de integração em `ManifestacaoStepOneForm.validation.test.tsx` (ou describe dedicado) cobrindo o edge case da spec ponta a ponta via `ManifestacaoWizardPage`: escolher `type = denúncia`, deixar "Nome completo" em branco, clicar Continuar → avança sem erro; no mesmo rascunho, trocar o tipo para "reclamação" e tentar Continuar novamente sem preencher o nome → bloqueado com a mensagem de nome obrigatório (Edge Case "Operador muda o tipo de denúncia para outro tipo depois de já ter avançado sem nome").

- [X] T014 [US1] Rodar `quickstart.md` Cenário 1 e Cenário 2 e confirmar SC-001/SC-002.

**Checkpoint**: US1 completa e testável de forma independente — cards removidos, identificação sempre visível, exceção de denúncia funcional ponta a ponta.

---

## Phase 4: User Story 2 - Informar e-mail único no bloco de identificação (Priority: P1)

**Goal**: Um único campo **E-mail** (opcional) vive dentro do bloco "Identificação"; o campo solto «E-mail para resposta» deixa de existir.

**Independent Test**: Abrir Identificação, confirmar exatamente um campo "E-mail" dentro do bloco (não em card separado); testar e-mail inválido/vazio/válido.

### Tests for User Story 2

- [X] T015 [P] [US2] **RED** — Em `ManifestacaoStepOneForm.validation.test.tsx`, novo teste: `expect(screen.getAllByLabelText(/^E-mail$/i)).toHaveLength(1)`; o campo deve estar dentro do mesmo container do "Nome completo" (ex.: `screen.getByText('Nome completo').closest('[class*=grid]')` também contém o input de e-mail, ou asserção equivalente via `data-field`); `expect(screen.queryByText('E-mail para resposta')).not.toBeInTheDocument()`. Confirmar RED.

### Implementation for User Story 2

- [X] T016 [US2] Em `ManifestacaoStepOneForm.tsx`: remover o `Field label="E-mail para resposta"` que hoje fica em um `<Card>` isolado logo antes do `<Card>` "Identificação" (bloco com o ícone `Mail` e `Input type="text" inputMode="email"`); mover esse mesmo `Field`/`Input` para dentro do grid de campos do manifestante, como **primeiro campo** (antes de "Nome completo"), com `className="sm:col-span-2"`, label renomeado para "E-mail" (mantém o `hint` "Opcional — canal de retorno ao manifestante"); **não renomear** a prop/estado `replyEmail` (permanece o mesmo campo — FR-006/FR-007, decisão de `research.md` §3). (GREEN de T015)

- [X] T017 [US2] No wrapper do grid de campos do manifestante, remover as classes de revelação condicional que não fazem mais sentido agora que o grid é sempre renderizado: `animate-in fade-in slide-in-from-top-2`, `border-dashed`, `bg-[#F8FAFC]/80 dark:bg-[#1E293B]/20` — manter apenas `grid gap-4 sm:grid-cols-2` (skill `ui-ux-pro-max`).

- [X] T018 [US2] Rodar `quickstart.md` Cenário 3 e confirmar SC-003.

**Checkpoint**: US1 e US2 completas — único campo E-mail, dentro de Identificação, sempre visível.

---

## Phase 5: User Story 3 - Consistência na leitura da manifestação (Priority: P2)

**Goal**: Manifestações criadas após a mudança aparecem identificadas (não "anônimas") na leitura, com o e-mail visível quando informado; registros legados continuam intocados.

**Independent Test**: Confirmar uma manifestação identificada com e-mail e abrir o detalhe — sem rótulo de anônima, e-mail visível; abrir um registro legado `isAnonymous: true` e confirmar que continua exibido como antes.

- [X] T019 [P] [US3] Verificar `ci-client-v2/apps/web/src/modules/ouvidoria/lib/__tests__/manifestacao-detail-view.test.ts`: confirmar que já existe (ou adicionar) um caso com `isAnonymous: false` + `requester` preenchido + `replyEmail` setado, validando que o card de detalhe **não** aciona o branch "Manifestação anônima" e exibe o e-mail — sem alterar `ManifestacaoRequesterCard.tsx`/`manifestacao-detail-view.ts` (o branch `if (view.isAnonymous)` permanece intacto para os registros legados, `research.md` §"Entidades não afetadas").

- [X] T020 [US3] Rodar `quickstart.md` Cenário 4 (leitura consistente) e Cenário 5 (registros legados intocados); confirmar SC-005 e FR-011.

**Checkpoint**: US1, US2 e US3 funcionam de forma independente.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Validações finais que atravessam as 3 stories e confirmam que o portal público permanece intocado.

- [X] T021 [P] Rodar `quickstart.md` Cenário 6 — smoke check em `ci-client-v2/apps/publico` confirmando que nenhum arquivo desse pacote foi tocado e que o fluxo de anonimato da spec 043 segue igual (FR-008).
- [X] T022 [P] Revisão de acessibilidade/UX do bloco Identificação (skill `ui-ux-pro-max`): contraste do asterisco condicional em "Nome completo", ordem de foco/tab (E-mail → Nome completo → demais campos), `aria-invalid`/mensagens continuam funcionando sem os cards.
- [X] T023 Limpeza opcional de testes: em `manifestacao-draft.schema.test.ts`, remover o `isAnonymous: false` redundante dos casos de CPF/telefone/titular que já enviam `requesterFullName` explícito (campo não influencia mais a regra); em `ManifestacaoStepOneForm.validation.test.tsx`, atualizar o texto da mensagem injetada manualmente em `fieldErrors.requesterFullName` nos testes `'exibe mensagens de erro por campo vindas do schema'` e `'foca o primeiro campo inválido...'` de `'Informe o nome do solicitante em manifestação identificada.'` para `'Informe o nome do solicitante.'` (mensagem real pós-mudança).
- [X] T024 Rodar as suítes completas e registrar resultado:
  ```powershell
  cd ci-api-v2; npm test -- --testPathPatterns=ouvidoria
  cd ci-client-v2/apps/web; npm test -- ouvidoria ManifestacaoStepOneForm ManifestacaoWizardPage manifestacao-draft manifestacao-detail-view
  ```

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: sem tarefas — nada bloqueia o início da Foundational.
- **Foundational (Phase 2)**: bloqueia **todas** as user stories — a troca de gatilho (`isAnonymous`→`type`) e o novo default afetam diretamente as três stories e uma quantidade grande de testes pré-existentes (T001–T007).
- **User Stories (Phase 3–5)**: todas dependem de Foundational completo.
  - US1 e US2 são **P1** — priorizar ambas antes de US3.
  - US2 (T015–T018) toca o **mesmo arquivo** que US1 (T008/T010, `ManifestacaoStepOneForm.tsx` e seu teste) — por isso, embora funcionalmente independentes, US2 deve ser feita **depois** de US1 estar mergeada para evitar conflito de edição simultânea no mesmo arquivo.
  - US3 (T019–T020) é independente de arquivo — pode ser feita em paralelo a US1/US2 por outra pessoa/sessão.
- **Polish (Phase 6)**: depende de todas as stories desejadas estarem completas.

### Within Each User Story

- Testes escritos e **FALHANDO** antes da implementação (RED → GREEN → REFACTOR, Constitution II).
- Story completa (checkpoint) antes de avançar para a próxima prioridade.

### Parallel Opportunities

- Foundational: T001 (API) e T003 (client) em paralelo (arquivos/pacotes diferentes); T005 e T006 em paralelo entre si (arquivos diferentes), ambos após T004.
- US1: T008 (`ManifestacaoStepOneForm.validation.test.tsx`) e T009 (`ManifestacaoWizardPage.save-draft.test.tsx`) em paralelo (arquivos diferentes).
- US3 (T019) pode ser feita em paralelo a US1/US2, por não compartilhar arquivo.
- Polish: T021 e T022 em paralelo entre si.

---

## Parallel Example: Foundational (Phase 2)

```bash
# Em paralelo (pacotes diferentes):
Task: "RED API — ouvidoria.schemas.spec.ts (T001)"
Task: "RED Client — manifestacao-draft.schema.test.ts (T003)"

# Depois de T002/T004 (GREEN), em paralelo (arquivos diferentes):
Task: "Corrigir fluxo emissor/save-draft (T005)"
Task: "Corrigir fixtures MSW + edit-mode (T006)"
```

## Parallel Example: User Story 1 (Phase 3)

```bash
# RED em paralelo (arquivos diferentes):
Task: "ManifestacaoStepOneForm.validation.test.tsx — cards removidos (T008)"
Task: "ManifestacaoWizardPage.save-draft.test.tsx — remove clique no card (T009)"
```

---

## Implementation Strategy

### MVP First (User Story 1 apenas)

1. Completar Phase 1 (N/A) + Phase 2: Foundational — regra de nome + suíte de regressão verde.
2. Completar Phase 3: User Story 1 — cards removidos, identificação sempre visível, exceção de denúncia.
3. **PARAR e VALIDAR**: `quickstart.md` Cenários 1 e 2.
4. Deploy/demo se pronto — já entrega o requisito central do pedido (fim do canal anônimo no assistente interno).

### Incremental Delivery

1. Foundational → regra pronta e testada nos dois lados (API + client), regressão intacta.
2. US1 → testar independentemente → demo (MVP! cards fora, exceção de denúncia funcional).
3. US2 → testar independentemente → demo (e-mail único dentro de Identificação).
4. US3 → testar independentemente → demo (leitura consistente confirmada, legados intocados).
5. Cada story adiciona valor sem quebrar as anteriores.

### Parallel Team Strategy

Com múltiplos desenvolvedores:

1. Time completa Foundational junto (schema é compartilhado por todas as stories).
2. Depois do Foundational:
   - Dev A: US1 (remoção dos cards)
   - Dev B: US3 (verificação de leitura — não compartilha arquivo com A)
   - US2 aguarda US1 mergear (mesmo arquivo `ManifestacaoStepOneForm.tsx`)
3. Polish depende de todas as stories desejadas estarem prontas.

---

## Notes

- [P] = arquivos diferentes, sem dependência pendente.
- [Story] mapeia a tarefa à user story correspondente (rastreabilidade com `spec.md`).
- A Fase 2 (Foundational) é incomumente grande para uma mudança "pequena" porque o gatilho antigo (`isAnonymous`) tinha default permissivo (`true` ⇒ nome nunca exigido) usado implicitamente por dezenas de fixtures de teste em ambos os lados (API e client) que nunca preenchiam `requesterFullName`; o novo gatilho (`type !== 'whistleblower'`) é exigente por padrão, então cada fixture que usa um tipo não-denúncia sem nome precisa ser corrigida uma única vez nesta fase — depois disso, US1/US2/US3 são cirúrgicas.
- Verificar que os testes falham (RED) antes de implementar (GREEN) — Constitution II, non-negotiable.
- Commit após cada tarefa ou grupo lógico.
- Parar em qualquer checkpoint para validar a story isoladamente.
- `apps/publico` e `criarManifestacaoPublicaBodySchema` **nunca** aparecem como alvo de edição em nenhuma tarefa acima — isso é intencional (FR-008).
