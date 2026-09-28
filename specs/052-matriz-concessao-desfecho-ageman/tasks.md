---
description: "Task list for 052 — Matriz Concessão × Desfecho e ajustes de status/encerramento (AGEMAN)"
---

# Tasks: Matriz Concessão × Desfecho e Ajustes de Status/Encerramento (AGEMAN)

**Input**: Design documents from `civ2-docs/specs/052-matriz-concessao-desfecho-ageman/`
**Prerequisites**: [plan.md](./plan.md), [spec.md](./spec.md), [research.md](./research.md), [data-model.md](./data-model.md), [contracts/relatorio-gestao-concessao-desfecho.md](./contracts/relatorio-gestao-concessao-desfecho.md), [quickstart.md](./quickstart.md)

**Tests**: incluídos — Constitution II (TDD, RED → GREEN → REFACTOR é obrigatório neste projeto).

**Organização**: uma fase por user story (US1–US4 da spec), em ordem de prioridade (P1, P1, P2, P2).

## Format: `[ID] [P?] [Story] Description`

- **[P]**: paralelizável (arquivos distintos, sem dependência de tasks incompletas)
- **[US1]..[US4]**: User Story 1–4 da spec

## Path Conventions

- Backend: `ci-api-v2/src/modules/ouvidoria/`
- Frontend: `ci-client-v2/apps/web/src/modules/ouvidoria/`

---

## Phase 1: Setup

**Purpose**: Confirmar baseline verde antes de qualquer alteração.

- [ ] T001 Confirmar branch `052-matriz-concessao-desfecho-ageman` e baseline verde: `npm test -- --testPathPatterns=ouvidoria` em `ci-api-v2/` e `npm test -- ouvidoria` em `ci-client-v2/apps/web/`

---

## Phase 2: Foundational (Blocking Prerequisites)

**1 tarefa fundacional bloqueante** — achado do `/speckit-analyze`: `sqlMapProgramaConcessaoCase` (`lib/map-programa-concessao.ts`) e `AGEMAN_PROGRAMA_LABEL` (`lib/ageman-catalog.ts`) usam hoje rótulos **diferentes** para o código de concessão `'5'` (`'Zona Azul'` vs `'Estacionamento Rotativo'`) — sem alinhar isso antes, a matriz (US1) e o filtro (US4) exibiriam rótulos divergentes para a mesma concessão, quebrando SC-003. Sem migration Prisma; nenhuma outra tarefa fundacional bloqueante (ver `research.md` §6/§7).

**Correção de escopo (achada em `/speckit-implement`)**: `AGEMAN_PROGRAMA_LABEL` também é usado por `ListProgramasPublicosUseCase` (endpoint público, spec 043, fora de escopo) e pelo catálogo client público equivalente — mutá-lo diretamente afetaria esse endpoint público. T001B cria um módulo novo e isolado em vez de alterar o catálogo compartilhado.

- [X] T001B ~~Atualizar RED em `ageman-catalog.spec.ts`... GREEN em `ageman-catalog.ts`~~ — **substituída**: criado `ci-api-v2/src/modules/ouvidoria/lib/concessao-label.ts` (+ `concessao-label.spec.ts`, RED→GREEN) com `resolveConcessaoMatrizLabel` (override `'5'` → `'Estacionamento Rotativo (Zona Azul)'` sobre `AGEMAN_PROGRAMA_LABEL`, sem mutá-lo) e `normalizeConcessaoSqlLabel` (reescreve a saída bruta `'Zona Azul'` do `CASE` SQL) — `AGEMAN_PROGRAMA_LABEL`/`ageman-catalog.spec.ts` permanecem inalterados, preservando `ListProgramasPublicosUseCase` (16/16 testes verdes: `concessao-label`, `ageman-catalog`, `list-programas-publicos`)

**Checkpoint**: Após T001B, pode iniciar qualquer User Story em paralelo.

---

## Phase 3: User Story 1 - Ver a matriz Concessão × Desfecho no relatório de gestão (Priority: P1) 🎯 MVP

**Goal**: Novo bloco `concessaoPorDesfecho` no `GET /ouvidoria/relatorio-gestao` (tela + PDF + Excel), cruzando tipo de concessão × Resolvida/Jurídico/Pendente.

**Independent Test**: Somar a linha de uma concessão (Resolvida + Jurídico + Pendente [+ Pendente legado]) e comparar com uma contagem SQL direta agrupada pelos mesmos critérios no mesmo período; conferir export PDF/Excel com os mesmos números da tela.

### Tests for User Story 1 (RED primeiro)

- [X] T002 [P] [US1] Criar RED em `ci-api-v2/src/modules/ouvidoria/test/repository/get-relatorio-gestao-concessao-desfecho.repository.spec.ts` — fixtures cobrindo as 5 concessões canônicas + "Não informado", com manifestações em `answered`/`closed`/`closed_meio_juridico`/`closed_unresolved`/abertas (`draft`/`in_review`/`forwarding`), asserindo `resolvidaPelaAgeman`/`meioJuridico`/`pendente`/`pendenteEncerradaLegado`/`total` por linha — incluir fixture do código `'5'` asserindo `concessao: 'Estacionamento Rotativo (Zona Azul)'` (não o valor bruto `'Zona Azul'` do `CASE`, ver `data-model.md` §3) (ver `data-model.md` §3)
- [X] T003 [P] [US1] Estender RED em `ci-api-v2/src/modules/ouvidoria/test/use-cases/get-relatorio-gestao.use-case.spec.ts` — payload inclui `concessaoPorDesfecho` com todas as concessões (mesmo com `total: 0`)
- [X] T004 [P] [US1] Estender RED em `ci-api-v2/src/modules/ouvidoria/lib/relatorio-gestao-pdf-sections.spec.ts` — nova seção "Concessão × Desfecho" com colunas do contrato: Concessão | Resolvida pela AGEMAN | Meio Jurídico | Pendente | Pendente (desfecho) | Total (rótulo da 4ª coluna igual ao já usado em `STATUS_OPTIONS` para `closed_unresolved` — não "Pendente (encerrada — legado)")
- [X] T005 [P] [US1] Estender RED em `ci-api-v2/src/modules/ouvidoria/test/use-cases/export-relatorio-gestao-excel.use-case.spec.ts` — nova aba "Concessão × Desfecho"
- [X] T006 [P] [US1] Criar RED em `ci-client-v2/apps/web/src/modules/ouvidoria/__tests__/relatorio-gestao-mappers.test.ts` — `mapConcessaoPorDesfechoChart` (novo) transforma a resposta em linhas de tabela/gráfico
- [X] T007 [P] [US1] Estender RED em `ci-client-v2/apps/web/src/modules/ouvidoria/__tests__/OuvidoriaRelatorioGestaoPage.test.tsx` — bloco "Concessão × Desfecho" renderizado com dados mock

### Implementation for User Story 1 (GREEN)

- [X] T008 [US1] Criar `ci-api-v2/src/modules/ouvidoria/repository/get-relatorio-gestao-concessao-desfecho.repository.ts` — agrupa por concessão (`sqlMapProgramaConcessaoCase`/fallback "Não informado") × 4 colunas de desfecho (ver `data-model.md` §3); reescrever o rótulo bruto `'Zona Azul'` (código `'5'`) via `normalizeConcessaoSqlLabel` (`lib/concessao-label.ts`) antes de montar a linha — depende de T001B, T002
- [X] T009 [US1] Estender `ci-api-v2/src/modules/ouvidoria/ouvidoria.types.ts` e schema Zod de resposta em `ouvidoria.schemas.ts` — tipo `ConcessaoPorDesfechoRow` — depende de T008
- [X] T010 [US1] Atualizar `ci-api-v2/src/modules/ouvidoria/use-cases/get-relatorio-gestao.use-case.ts` — incorporar `concessaoPorDesfecho` no payload, sem alterar blocos existentes — depende de T008, T009, T003
- [X] T011 [US1] Atualizar `ci-api-v2/src/modules/ouvidoria/lib/relatorio-gestao-pdf-sections.ts` — seção "Concessão × Desfecho", 4 colunas de desfecho + Total, rótulo "Pendente (desfecho)" na coluna legado — depende de T004, T010
- [X] T012 [US1] Atualizar `ci-api-v2/src/modules/ouvidoria/use-cases/export-relatorio-gestao-excel.use-case.ts` — aba "Concessão × Desfecho" — depende de T005, T010
- [X] T013 [US1] Atualizar `ci-client-v2/apps/web/src/modules/ouvidoria/api/relatorio-gestao.ts` — tipo `concessaoPorDesfecho` na response parseada — depende de T010
- [X] T014 [US1] Criar `mapConcessaoPorDesfechoChart` em `ci-client-v2/apps/web/src/modules/ouvidoria/lib/relatorio-gestao-mappers.ts` — depende de T006, T013
- [X] T015 [US1] Atualizar `ci-client-v2/apps/web/src/modules/ouvidoria/pages/OuvidoriaRelatorioGestaoPage.tsx` — renderizar tabela/bloco "Concessão × Desfecho" — depende de T007, T014

**Checkpoint**: User Story 1 completa e testável de forma independente (tela + PDF + Excel).

---

## Phase 4: User Story 2 - Encerrar demanda apenas com desfecho resolutivo (Priority: P1)

**Goal**: Remover "Pendente" como opção de desfecho no encerramento — só "Resolvida pela AGEMAN" e "Meio Jurídico" continuam disponíveis.

**Independent Test**: Abrir o modal de encerramento e confirmar 2 botões (não 3); enviar `desfecho: 'pendente'` via API e confirmar `400`.

### Tests for User Story 2 (RED primeiro)

- [X] T016 [P] [US2] Atualizar RED em `ci-api-v2/src/modules/ouvidoria/test/lib/manifestacao-desfecho.spec.ts` — `MANIFESTACAO_DESFECHO_ENCERRAMENTO` só tem 2 valores; `statusFromDesfechoEncerramento('pendente' as never)` não compila/não existe mais
- [X] T017 [P] [US2] Atualizar RED em `ci-api-v2/src/modules/ouvidoria/ouvidoria.schemas.spec.ts` — `manifestacaoDesfechoEncerramentoSchema` rejeita `'pendente'`
- [X] T018 [P] [US2] Atualizar RED em `ci-api-v2/src/modules/ouvidoria/test/use-cases/encerrar-manifestacao.use-case.spec.ts` — encerrar com `desfecho: 'pendente'` retorna erro de validação
- [X] T019 [P] [US2] Atualizar RED em `ci-client-v2/apps/web/src/modules/ouvidoria/lib/__tests__/manifestacao-desfecho-copy.test.ts` — `DESFECHO_ENCERRAMENTO_OPTIONS` tem exatamente 2 itens (`resolvida`, `meio_juridico`)
- [X] T020 [P] [US2] Atualizar RED em `ci-client-v2/apps/web/src/modules/ouvidoria/__tests__/ManifestacaoActionDialogs.test.tsx` — modal "Encerrar" renderiza só 2 botões de desfecho

### Implementation for User Story 2 (GREEN)

- [X] T021 [US2] Atualizar `ci-api-v2/src/modules/ouvidoria/lib/manifestacao-desfecho.ts` — remover `'pendente'` de `MANIFESTACAO_DESFECHO_ENCERRAMENTO`; remover branch em `statusFromDesfechoEncerramento` — depende de T016
- [X] T022 [US2] Atualizar `ci-api-v2/src/modules/ouvidoria/ouvidoria.schemas.ts` — `manifestacaoDesfechoEncerramentoSchema` com 2 valores — depende de T017, T018
- [X] T023 [US2] Atualizar `ci-client-v2/apps/web/src/modules/ouvidoria/lib/manifestacao-desfecho-copy.ts` — `MANIFESTACAO_DESFECHO_ENCERRAMENTO`/`DESFECHO_ENCERRAMENTO_UI`/`DESFECHO_ENCERRAMENTO_OPTIONS` com 2 valores — depende de T019 — extra (não previsto no plano original): `DESFECHO_KEY_LABELS.pendentes` (usado nos relatórios, conceito distinto de encerramento) passou a usar novo `DESFECHO_PENDENTE_LABEL` em vez de `DESFECHO_ENCERRAMENTO_UI.pendente` (removido); ajustado também em `relatorio-gestao-mappers.ts`, `OuvidoriaRelatorioGestaoPage.tsx` e no tipo espelho `api/workflow.ts`
- [X] T024 [US2] Confirmar `ci-client-v2/apps/web/src/modules/ouvidoria/components/ManifestacaoActionDialogs.tsx` renderiza corretamente com a lista reduzida (ajustar só se necessário — o componente já itera `DESFECHO_ENCERRAMENTO_OPTIONS`) — depende de T020, T023 — confirmado sem alterações necessárias no componente

**Checkpoint**: User Story 2 completa — bug de UX corrigido, validado por API e UI.

---

## Phase 5: User Story 3 - Status "Pendente" consistente antes de virar demanda (Priority: P2)

**Goal**: Rótulo de `in_review` passa de "Em análise" para "Pendente" em todos os pontos (interno, público, KPIs, exports), para todos os tenants.

**Independent Test**: Criar solicitação nova → status exibido "Pendente" na lista interna e na consulta pública; nenhuma demanda formalizada usa esse rótulo para outro status.

### Tests for User Story 3 (RED primeiro)

- [X] T025 [P] [US3] Atualizar RED em `ci-api-v2/src/modules/ouvidoria/ouvidoria.mapper.spec.ts` — `MANIFESTACAO_STATUS_LABEL.in_review` e `PUBLIC_MANIFESTACAO_STATUS_LABEL.in_review` = `'Pendente'`
- [X] T026 [P] [US3] Atualizar RED em `ci-api-v2/src/modules/ouvidoria/test/use-cases/consulta-publica.use-case.spec.ts` — rótulo público `'Pendente'` para `in_review`/`forwarding`
- [X] T027 [P] [US3] Atualizar RED em `ci-client-v2/apps/web/src/modules/ouvidoria/pages/ManifestacoesListPage.tsx` (teste correspondente, se existir, ou criar) — `STATUS_OPTIONS` valor `in_review` com label `'Pendente'`; `closed_unresolved` mantém `'Pendente (desfecho)'`; KPI card renomeado — criado `pages/__tests__/ManifestacoesListPage.status-labels.test.tsx`; **achado durante implementação**: a KPI stats já tinha um card `'Pendente'` pré-existente para `kpis.desfechoPendentes` (bucket legado FR-004) — colidiria com o novo `'Pendente'` de `kpis.emAnalise`; resolvido renomeando esse card legado para `'Pendente (desfecho)'` (mesmo texto já usado no filtro `STATUS_OPTIONS`/matriz FR-004), preservando distinguibilidade exigida pela FR-006
- [X] T028 [P] [US3] Atualizar RED em `ci-client-v2/apps/web/src/modules/ouvidoria/lib/manifestacoes-list-stats.ts` (teste correspondente) — rótulo do KPI `'Pendente'`
- [X] T029 [P] [US3] Atualizar RED em `ci-client-v2/apps/web/src/modules/ouvidoria/__tests__/ManifestacaoIdentityCard.test.tsx` e `lib/__tests__/manifestacao-detail-view.test.ts` — `statusLabel: 'Pendente'` para `in_review`
- [X] T030 [P] [US3] Atualizar RED em `ci-client-v2/apps/web/src/modules/ouvidoria/__tests__/relatorio-gestao-mappers.test.ts` — `mapDemandasPendentesChart` usa rótulo `'Pendente'` na linha antes chamada "Em análise"
- [X] T031a [P] [US3] Atualizar RED em `ci-api-v2/src/modules/ouvidoria/lib/relatorio-gestao-pdf-sections.spec.ts` — KPI `'Pendente'` em vez de `'Em análise'`
- [X] T031b [P] [US3] Atualizar RED em `ci-api-v2/src/modules/ouvidoria/test/use-cases/export-relatorio-gestao-excel.use-case.spec.ts` — KPI `'Pendente'` em vez de `'Em análise'`

### Implementation for User Story 3 (GREEN)

- [X] T032 [US3] Atualizar `ci-api-v2/src/modules/ouvidoria/ouvidoria.mapper.ts` — `MANIFESTACAO_STATUS_LABEL` e `PUBLIC_MANIFESTACAO_STATUS_LABEL` — depende de T025, T026
- [X] T033 [US3] Atualizar `ci-client-v2/apps/web/src/modules/ouvidoria/pages/ManifestacoesListPage.tsx` — `STATUS_OPTIONS` + KPI card "Em análise" → "Pendente" — depende de T027 — extra: card `desfechoPendentes` renomeado "Pendente" → "Pendente (desfecho)" (ver nota T027)
- [X] T034 [US3] Atualizar `ci-client-v2/apps/web/src/modules/ouvidoria/lib/manifestacoes-list-stats.ts` — rótulo do KPI — depende de T028
- [X] T035 [US3] Atualizar `ci-client-v2/apps/web/src/modules/ouvidoria/lib/relatorio-gestao-mappers.ts` — `mapDemandasPendentesChart` — depende de T030
- [X] T036a [US3] Atualizar `ci-api-v2/src/modules/ouvidoria/lib/relatorio-gestao-pdf-sections.ts` — KPI "Pendente" — depende de T031a
- [X] T036b [US3] Atualizar `ci-api-v2/src/modules/ouvidoria/use-cases/export-relatorio-gestao-excel.use-case.ts` — KPI "Pendente" — depende de T031b

**Checkpoint**: User Story 3 completa — vocabulário consistente em todas as superfícies, para todos os tenants.

---

## Phase 6: User Story 4 - Filtrar a lista de demandas por tipo de concessão (Priority: P2)

**Goal**: Novo filtro `concessao` na lista de demandas, com opções carregadas dinamicamente a partir dos dados do tenant (sem catálogo/tabela nova).

**Independent Test**: Selecionar uma concessão no filtro → só demandas daquele tipo aparecem; contagem bate com a linha correspondente da matriz da US1 no mesmo período.

### Tests for User Story 4 (RED primeiro)

- [X] T037 [P] [US4] Atualizar RED em `ci-api-v2/src/modules/ouvidoria/repository/manifestacao.repositories.ts` (spec correspondente de `ListManifestacoesRepository`) — filtro `concessao` aplicado via `sqlMapProgramaConcessaoCase` — implementado via `PROGRAMA_RAW_VALUES_BY_CODE`/`codeForRawPrograma` (novo, em `lib/map-programa-concessao.ts`), fonte única de verdade derivada do mesmo CASE SQL, usada para montar `where.programa.in`/`notIn` no Prisma (Prisma ORM típico não aceita CASE bruto num `where` typed)
- [X] T038 [P] [US4] Atualizar RED em `ci-api-v2/src/modules/ouvidoria/use-cases/list-manifestacoes.use-case.spec.ts` — repassa filtro `concessao` ao repository
- [X] T039 [P] [US4] Atualizar RED em `ci-api-v2/src/modules/ouvidoria/ouvidoria.schemas.spec.ts` — `listManifestacoesQuerySchema` aceita `concessao` opcional
- [X] T040 [P] [US4] Criar RED em `ci-api-v2/src/modules/ouvidoria/use-cases/list-concessoes-disponiveis.use-case.spec.ts` — retorna concessões distintas do tenant (vazio quando tenant sem dado mapeável) — spec de repositório correspondente também criado em `repository/list-concessoes-disponiveis.repository.spec.ts`
- [X] T041 [P] [US4] Criar/atualizar RED em `ci-client-v2/apps/web/src/modules/ouvidoria/pages/ManifestacoesListPage.tsx` (teste) — filtro de concessão renderiza opções carregadas e aplica no request da lista

### Implementation for User Story 4 (GREEN)

- [X] T042 [US4] Atualizar `ci-api-v2/src/modules/ouvidoria/ouvidoria.schemas.ts` — `concessao` em `listManifestacoesQuerySchema` — depende de T039
- [X] T043 [US4] Atualizar `ci-api-v2/src/modules/ouvidoria/repository/manifestacao.repositories.ts` (`ListManifestacoesRepository`) — where clause de concessão — depende de T037
- [X] T044 [US4] Atualizar `ci-api-v2/src/modules/ouvidoria/use-cases/list-manifestacoes.use-case.ts` — repassar filtro — depende de T038, T043
- [X] T045 [US4] Criar `ci-api-v2/src/modules/ouvidoria/use-cases/list-concessoes-disponiveis.use-case.ts` + repository correspondente + rota `GET manifestacoes/concessoes-disponiveis` no `ouvidoria.controller.ts` — rota MUST usar `@RequireModulo('ouvidoria')` + escopo por `tenantId` (mesmo padrão das demais rotas do módulo, Constitution IV); opções retornadas usam `resolveConcessaoMatrizLabel`/`normalizeConcessaoSqlLabel` (`lib/concessao-label.ts`, código `'5'` = `'Estacionamento Rotativo (Zona Azul)'`, consistente com a matriz da US1) — depende de T001B, T040 — extra: novo parâmetro do construtor do `OuvidoriaController` foi adicionado ao **final** da lista (não em ordem lógica) para não deslocar os índices posicionais fixos usados por `ouvidoria.controller.spec.ts` (`CONTROLLER_ARITY`, atualizado 59→60); rota estática `manifestacoes/concessoes-disponiveis` registrada antes de `manifestacoes/:id` para evitar colisão de rota
- [X] T046 [US4] Atualizar `ci-client-v2/apps/web/src/modules/ouvidoria/api/manifestacoes.ts` — param `concessao` na listagem + chamada ao novo endpoint de opções — depende de T044, T045
- [X] T047 [US4] Atualizar `ci-client-v2/apps/web/src/modules/ouvidoria/pages/ManifestacoesListPage.tsx` — novo `Select` de concessão, oculto quando opções vazias — depende de T041, T046

**Checkpoint**: User Story 4 completa — filtro funcional, sem tabela/catálogo novo.

---

## Phase 7: Polish & Cross-Cutting Concerns

- [X] T048 [P] Atualizar `civ2-docs/specs/README.md` com a entrada da feature 052
- [X] T049 Executar roteiro manual de [quickstart.md](./quickstart.md) (4 cenários, tenant AGEMAN) — **executado de fato** contra `ci-api-v2`/`ci-client-v2` locais (`npm run start:dev` + `npm run dev --workspace=@ci/web`) e o Neon Postgres real de dev, autenticado via UI de login como `superadmin@ageman.am.gov.br` (JWT real, `X-Tenant-ID: ageman`). Verificação por chamadas HTTP reais (não mock) com o token obtido:
  - Cenário 1: `GET /ouvidoria/relatorio-gestao` real retorna `concessaoPorDesfecho` com as 6 linhas esperadas e rótulos canônicos exatos (ex.: "Estacionamento Rotativo (Zona Azul)", "Meio Jurídico", "Pendente (desfecho)"); consistência cruzada conferida (Água/Saneamento soma 81 em `porTipoManifestacao` e em `concessaoPorDesfecho`).
  - Cenário 2: `POST /ouvidoria/manifestacoes/:id/encerrar` com `desfecho: "pendente"` retorna 400 (Zod) sem gravar nada — opção "Pendente" de fato não existe mais no encerramento (US2).
  - Cenário 3: manifestação real em `in_review` retorna `statusLabel: "Pendente"` (não mais "Em análise") tanto na lista quanto no detalhe (US3).
  - Cenário 4: `GET /ouvidoria/manifestacoes/concessoes-disponiveis` retorna as opções dinâmicas reais do tenant; `GET /ouvidoria/manifestacoes?concessao=1` filtra corretamente para 337 itens reais de "Água / Saneamento" (US4).
  - Também foi escrito um spec Playwright real de UI (`ci-client-v2/e2e/specs/052-matriz-concessao-desfecho.e2e.spec.ts`, seguindo a skill `playwright-e2e`) cobrindo os mesmos 4 cenários via navegador. Em execução local ele expôs uma instabilidade **pré-existente e não relacionada à 052** no bootstrap de autenticação da SPA em modo dev (`vite dev`): navegações completas (`page.goto`) subsequentes ao login às vezes perdem a sessão de forma não-determinística (token presente/ausente em `sessionStorage` sem erro de console ou chamada de rede correspondente) — reproduzido também em script isolado mínimo, portanto não é um bug do teste em si. Registrado como possível item de tech debt para investigar separadamente (fora do escopo da 052); a validação funcional acima, via API real, não depende dessa instabilidade e é suficiente para fechar T049.
  - Bônus: essa investigação encontrou e corrigiu uma asserção obsoleta pré-existente em `ci-client-v2/e2e/specs/ouvidoria-paridade.e2e.spec.ts` (esperava "Em análise" no dashboard; agora "Pendente", pós-rename da US3).
- [X] T050 Executar suite completa: `npm test -- --testPathPatterns=ouvidoria` (`ci-api-v2/`) e `npm test -- ouvidoria` (`ci-client-v2/apps/web/`) — API 655/655; client 406/407 (1 falha pré-existente `ManifestacaoAcesso.e2e.test.tsx`, não relacionada, mesma baseline do T001)
- [X] T051 Medir tempo de resposta de `GET /ouvidoria/relatorio-gestao` (tela) e dos exports PDF/Excel com o bloco `concessaoPorDesfecho` habilitado, no tenant AGEMAN com dados reais — confirmar ≤5s (p95, tela) / ≤30s (export), SC-004 — **executado**: medição real (não simulada) contra o servidor local + Neon Postgres real de dev, tenant AGEMAN, com JWT real. Resultados: tela (`GET /ouvidoria/relatorio-gestao`) **2,11s** (≤5s ✅); export Excel **2,09s** (≤30s ✅); export PDF **1,72s** (≤30s ✅). Todos os três dentro da margem de SC-004 com folga considerável.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: sem dependências — pode começar imediatamente.
- **Foundational (Phase 2)**: T001B (alinhamento de rótulo do código de concessão `'5'`) — bloqueia T008 (US1) e T045 (US4), que dependem do rótulo `AGEMAN_PROGRAMA_LABEL['5']` já corrigido.
- **User Stories (Phase 3–6)**: podem começar após o Setup; US1 e US4 aguardam T001B (Foundational) antes de suas tasks de rótulo de concessão (T008/T045) — as demais tasks de US1/US4 e todo US2/US3 são independentes entre si (arquivos majoritariamente distintos — únicos pontos de toque comum são `ouvidoria.schemas.ts` e `ManifestacoesListPage.tsx`/`relatorio-gestao-mappers.ts`, editados em seções distintas por story; coordenar merge se paralelizado por mais de um agente/dev).
- **Polish (Phase 7)**: depende de todas as User Stories desejadas estarem completas.

### User Story Dependencies

- **US1 (P1)**: sem dependência de outras stories.
- **US2 (P1)**: sem dependência de outras stories.
- **US3 (P2)**: sem dependência de outras stories (toca arquivos compartilhados com US1/US2 em pontos diferentes).
- **US4 (P2)**: sem dependência dura de US1, mas reaproveita conceitualmente a mesma expressão SQL de concessão — pode ser feita em paralelo.

### Within Each User Story

- Tests (RED) antes da implementação (GREEN), sempre.
- Repository/lib antes de use-case; use-case antes de PDF/Excel/UI.

### Parallel Opportunities

- Todos os RED de uma mesma story marcados `[P]` podem ser escritos em paralelo.
- US1, US2, US3 e US4 podem ser trabalhadas em paralelo por agentes/devs diferentes após o Setup (Phase 1) — coordenar apenas os arquivos compartilhados citados acima.

---

## Parallel Example: User Story 1

```bash
# RED em paralelo (arquivos distintos):
Task: "RED get-relatorio-gestao-concessao-desfecho.repository.spec.ts"
Task: "RED get-relatorio-gestao.use-case.spec.ts (concessaoPorDesfecho)"
Task: "RED relatorio-gestao-pdf-sections.spec.ts (seção nova)"
Task: "RED export-relatorio-gestao-excel.use-case.spec.ts (aba nova)"
Task: "RED relatorio-gestao-mappers.test.ts (mapConcessaoPorDesfechoChart)"
Task: "RED OuvidoriaRelatorioGestaoPage.test.tsx (bloco novo)"
```

---

## Implementation Strategy

### MVP First (User Stories 1 + 2 — ambas P1)

1. Completar Phase 1: Setup.
2. Completar Phase 3: US1 (matriz Concessão × Desfecho).
3. Completar Phase 4: US2 (remover "Pendente" do encerramento).
4. **PARE e VALIDE**: rodar cenários 1 e 2 do `quickstart.md` — matriz correta + encerramento sem bug.
5. Deploy/demo — já resolve os dois pontos mais visíveis do feedback AGEMAN (imagens 2 e 3).

### Incremental Delivery

1. Setup → Foundation (T001B, rótulo de concessão) pronta.
2. US1 → validar independente → deploy/demo (MVP parte 1).
3. US2 → validar independente → deploy/demo (MVP parte 2, bug de UX corrigido).
4. US3 → validar independente → deploy/demo (vocabulário consistente).
5. US4 → validar independente → deploy/demo (filtro de conferência).

### Parallel Team Strategy

Com múltiplos agentes/devs:

1. Setup em conjunto (T001).
2. Foundational em conjunto (T001B) — rápida, desbloqueia T008 (US1) e T045 (US4). Depois, dividir direto:
   - Agente/Dev A: US1 (T002–T015)
   - Agente/Dev B: US2 (T016–T024)
   - Agente/Dev C: US3 (T025–T036)
   - Agente/Dev D: US4 (T037–T047)
3. Coordenar merge em `ouvidoria.schemas.ts`, `ManifestacoesListPage.tsx` e `relatorio-gestao-mappers.ts` (editados por mais de uma story, em seções diferentes).
4. Phase 7 (Polish) após todas as stories desejadas estarem prontas.

---

## Notes

- `[P]` = arquivos diferentes, sem dependência de tasks incompletas.
- `[USx]` mapeia a task à user story correspondente da spec, para rastreabilidade.
- TDD obrigatório (Constitution II): confirmar RED falhando antes de implementar GREEN.
- Nenhuma migration Prisma nesta feature — todas as agregações derivam de colunas/enum já existentes (ver `research.md` §6).
- Evitar tocar `civ2-docs/specs/050-relatorio-gestao-desfecho-ageman/*` e `050-relatorio-gestao-tipo-concessao-ageman/*` (fora de escopo — ver `files-touch-list.md`).
