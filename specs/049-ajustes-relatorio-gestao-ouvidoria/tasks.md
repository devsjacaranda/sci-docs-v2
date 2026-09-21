# Tasks: Ajustes na Pesquisa de Satisfação e no Relatório de Gestão da Ouvidoria

**Input**: Design documents de `civ2-docs/specs/049-ajustes-relatorio-gestao-ouvidoria/` — `plan.md`, `spec.md`, `research.md`, `data-model.md`, `contracts/ajustes-relatorio-gestao.md`, `quickstart.md`

**Tests**: incluídos — Constitution v1.3.0, Princípio II (Test-First, NON-NEGOTIABLE) exige TDD para todo código de produção; não é opcional neste projeto.

**Organização**: tarefas agrupadas por user story (spec.md). Cada história é implementável e testável isoladamente.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: pode rodar em paralelo (arquivos diferentes, sem dependência pendente)
- **[Story]**: US1 (satisfação Sim/Não), US2 (fix overlap PDF), US3 (orientações/encaminhamentos detalhado), US4 (participação em eventos)
- Caminhos de arquivo exatos em cada descrição

## Path Conventions

Monorepo existente — sem novo projeto:
- Backend: `ci-api-v2/src/modules/ouvidoria/` (+ `prisma/schema/ouvidoria-catalog.prisma`)
- Frontend: `ci-client-v2/apps/web/src/modules/ouvidoria/`

---

## Phase 1: Setup

**Purpose**: Confirmar ambiente antes de tocar código

- [X] T001 Confirmar `ci-api-v2` e `ci-client-v2` rodando localmente (`npm run start:dev` / `npm run dev`) e Prisma Client atualizado com o schema atual, conforme `civ2-docs/specs/049-ajustes-relatorio-gestao-ouvidoria/quickstart.md` § Pré-requisitos/Setup

---

## Phase 2: Foundational (Blocking Prerequisites)

**Nenhuma tarefa fundacional bloqueante nesta feature.** O módulo `ouvidoria` já está maduro (spec 042 entregue); cada história abaixo altera/cria arquivos isolados, sem infraestrutura nova compartilhada entre todas as histórias (diferente do FR-013 — sem tabela de cache — que já é respeitado por design). US1 e US4 têm cada uma sua própria migration Prisma independente (ver Phase 3 e Phase 6) — deliberadamente **não** combinadas na migration única sugerida em `data-model.md`, para que cada história permaneça implementável/testável de forma isolada (refinamento desta fase de tasks sobre o plano).

**Checkpoint**: pode iniciar qualquer história (US1 e US2 são P1; podem rodar em paralelo entre si).

---

## Phase 3: User Story 1 - Lançar pesquisa de satisfação no modelo Sim/Não (Priority: P1) 🎯 MVP

**Goal**: Substituir o campo único "valor" (0–10) por contagens (consultados/Sim/Não), com percentual derivado em leitura.

**Independent Test**: Lançar consultados/Sim/Não de uma pergunta/mês e confirmar que o relatório de gestão exibe o percentual `Sim ÷ (Sim+Não)` correto para esse mês (ou "sem dados" quando a soma é zero).

### Tests for User Story 1 ⚠️ (escrever e ver falhar antes de implementar)

- [X] T002 [P] [US1] Atualizar teste de repository em `ci-api-v2/src/modules/ouvidoria/test/repository/upsert-pesquisa-satisfacao-lancamento.repository.spec.ts` para cobrir `consultados`/`respostasSim`/`respostasNao` (sem `valor`)
- [X] T003 [P] [US1] Atualizar teste de repository em `ci-api-v2/src/modules/ouvidoria/test/repository/list-pesquisa-satisfacao-lancamentos.repository.spec.ts` cobrindo `percentual` derivado e `null` quando `respostasSim + respostasNao === 0`
- [X] T004 [P] [US1] Atualizar teste de use-case em `ci-api-v2/src/modules/ouvidoria/test/use-cases/upsert-pesquisa-satisfacao.use-case.spec.ts` para o novo input
- [X] T005 [P] [US1] Atualizar teste de use-case em `ci-api-v2/src/modules/ouvidoria/test/use-cases/get-relatorio-gestao.use-case.spec.ts` cobrindo o novo shape do bloco `pesquisaSatisfacao`
- [X] T006 [P] [US1] Atualizar teste de mapper em `ci-client-v2/apps/web/src/modules/ouvidoria/__tests__/relatorio-gestao-mappers.test.ts` (percentual em vez de `valor`, "sem dados")

### Implementation for User Story 1

- [X] T007 [US1] Alterar model `OuvidoriaPesquisaSatisfacaoLancamento` em `ci-api-v2/prisma/schema/ouvidoria-catalog.prisma` — remover `valor`, adicionar `consultados Int?`, `respostasSim Int @default(0)`, `respostasNao Int @default(0)`
- [X] T008 [US1] Gerar e aplicar migration `ouvidoria_satisfacao_sim_nao` (`npx prisma migrate dev` em `ci-api-v2/`) — depende de T007
- [X] T009 [US1] Atualizar `ci-api-v2/src/modules/ouvidoria/repository/upsert-pesquisa-satisfacao-lancamento.repository.ts` para o novo shape — depende de T008
- [X] T010 [US1] Atualizar `upsertPesquisaSatisfacaoBodySchema`/`UpsertPesquisaSatisfacaoBody` em `ci-api-v2/src/modules/ouvidoria/ouvidoria.schemas.ts` (remove `valor`, adiciona `consultados?`/`respostasSim`/`respostasNao`)
- [X] T011 [US1] Atualizar `PesquisaSatisfacaoLancamentoDTO`/`PesquisaSatisfacaoLancamentoComPergunta` em `ci-api-v2/src/modules/ouvidoria/ouvidoria.types.ts` (novos campos + `percentual`)
- [X] T012 [US1] Atualizar `ci-api-v2/src/modules/ouvidoria/use-cases/upsert-pesquisa-satisfacao.use-case.ts` para o novo input — depende de T009, T010
- [X] T013 [US1] Atualizar `ci-api-v2/src/modules/ouvidoria/repository/list-pesquisa-satisfacao-lancamentos.repository.ts` — mapper calcula `percentual` derivado (`null` quando soma zero)
- [X] T014 [US1] Atualizar `ci-api-v2/src/modules/ouvidoria/use-cases/get-relatorio-gestao.use-case.ts` — bloco `pesquisaSatisfacao` usa o novo shape (depende de T011, T013)
- [X] T015 [US1] Atualizar seção `pesquisaSatisfacao` em `ci-api-v2/src/modules/ouvidoria/lib/relatorio-gestao-pdf-sections.ts` (colunas Consultados/Sim/Não/%)
- [X] T016 [US1] Atualizar aba "Pesquisa de satisfação" em `ci-api-v2/src/modules/ouvidoria/use-cases/export-relatorio-gestao-excel.use-case.ts` (mesmas colunas novas)
- [X] T017 [US1] Atualizar `ci-client-v2/apps/web/src/modules/ouvidoria/api/pesquisa-satisfacao.ts` — `upsertLancamento` com o novo body
- [X] T018 [US1] Atualizar `ci-client-v2/apps/web/src/modules/ouvidoria/pages/OuvidoriaPesquisaSatisfacaoPage.tsx` — formulário com campos Consultados/Sim/Não em vez de "valor" 0–10
- [X] T019 [US1] Atualizar `ci-client-v2/apps/web/src/modules/ouvidoria/lib/relatorio-gestao-mappers.ts` — mapear `percentual`/"sem dados"
- [X] T020 [US1] Atualizar `ci-client-v2/apps/web/src/modules/ouvidoria/components/dashboard/SatisfacaoChartCard.tsx` — exibir percentual em vez do score 0–10

**Checkpoint**: US1 completa — testável isoladamente via `quickstart.md` Cenário 1.

---

## Phase 4: User Story 2 - Corrigir sobreposição de texto no PDF exportado (Priority: P1) 🎯 MVP

**Goal**: Nenhuma linha da tabela do PDF sobrepõe outra, independente do tamanho do texto.

**Independent Test**: Exportar o PDF para um período com motivos longos e confirmar visualmente que cada linha de "Manifestações por motivo" é legível, sem sobreposição, em qualquer página.

### Tests for User Story 2 ⚠️

- [X] T021 [P] [US2] Criar teste em `ci-api-v2/src/modules/ouvidoria/test/lib/render-relatorio-gestao-pdf.spec.ts` cobrindo uma linha com célula de texto longo (força quebra em 3–4 linhas dentro da coluna) seguida de outra linha — validar que a segunda linha só é desenhada após a altura real da primeira (mock/spy em `doc.heightOfString`/posições Y), reproduzindo o bug antes do fix

### Implementation for User Story 2

- [X] T022 [US2] Alterar `addTable()` em `ci-api-v2/src/modules/ouvidoria/lib/render-relatorio-gestao-pdf.ts` — calcular `rowHeight = Math.max(16, ...cells.map(c => doc.heightOfString(c, { width: colW - 4 })))` por linha, usar em `ensureSpace(rowHeight)` e no avanço `y += rowHeight` (em vez do `16` fixo atual) — depende de T021 (teste deve falhar antes, passar depois)

**Checkpoint**: US2 completa — testável isoladamente via `quickstart.md` Cenário 2. Independente de US1/US3/US4.

---

## Phase 5: User Story 3 - Orientações/Encaminhamentos detalhado por concessão/canal/ano (Priority: P2)

**Goal**: Bloco existente (spec 042) passa a agrupar por concessão × canal (`serviceMode`) × ano, sempre com histórico multi-ano completo (ignora filtro `year`/`month` do resto do relatório).

**Independent Test**: Comparar o bloco exibido com uma contagem manual de `Manifestacao` agrupada por ano/`programa`(concessão)/`serviceMode`(canal) para o mesmo tenant.

### Tests for User Story 3 ⚠️

- [X] T023 [P] [US3] Criar teste em `ci-api-v2/src/modules/ouvidoria/test/repository/get-relatorio-gestao-orientacoes-encaminhamentos.repository.spec.ts` — cobre agrupamento por ano/concessão(`programa`)/canal(`serviceMode`), fallback `'Não informado'`, ignora filtro `year`/`month`
- [X] T024 [P] [US3] Atualizar teste em `ci-api-v2/src/modules/ouvidoria/test/use-cases/get-relatorio-gestao.use-case.spec.ts` cobrindo o novo bloco `orientacoesEncaminhamentos` no retorno (sempre multi-ano)

### Implementation for User Story 3

- [X] T025 [US3] Criar `ci-api-v2/src/modules/ouvidoria/repository/get-relatorio-gestao-orientacoes-encaminhamentos.repository.ts` — `$queryRaw` `GROUP BY EXTRACT(YEAR FROM "createdAt")`, mapeamento `programa`→concessão (reaproveitar de `dashboard.repositories.ts`), `serviceMode`→canal com `COALESCE(NULLIF(TRIM(...)), 'Não informado')` — depende de T023
- [X] T026 [US3] Atualizar `ci-api-v2/src/modules/ouvidoria/use-cases/get-relatorio-gestao.use-case.ts` — orquestrar bloco `orientacoesEncaminhamentos` (chama T025, ignorando `year`/`month` da query) — depende de T025
- [X] T027 [US3] Atualizar `RelatorioGestaoResponse` em `ci-api-v2/src/modules/ouvidoria/ouvidoria.types.ts` — adicionar `orientacoesEncaminhamentos: Array<{ ano; concessao; canal; total }>`
- [X] T028 [US3] Adicionar seção `orientacoesEncaminhamentos` em `ci-api-v2/src/modules/ouvidoria/lib/relatorio-gestao-pdf-sections.ts`
- [X] T029 [US3] Adicionar aba "Orientações e Encaminhamentos" em `ci-api-v2/src/modules/ouvidoria/use-cases/export-relatorio-gestao-excel.use-case.ts`
- [X] T030 [US3] Atualizar `ci-client-v2/apps/web/src/modules/ouvidoria/lib/relatorio-gestao-mappers.ts` — mapear o novo bloco
- [X] T031 [US3] Criar `ci-client-v2/apps/web/src/modules/ouvidoria/components/dashboard/OrientacoesEncaminhamentosChartCard.tsx`
- [X] T032 [US3] Integrar `OrientacoesEncaminhamentosChartCard` em `ci-client-v2/apps/web/src/modules/ouvidoria/pages/OuvidoriaRelatorioGestaoPage.tsx` — depende de T031

**Checkpoint**: US3 completa — testável isoladamente via `quickstart.md` Cenário 3. Independente de US1/US2/US4.

---

## Phase 6: User Story 4 - Registrar participação em eventos institucionais (Priority: P2)

**Goal**: Catálogo de eventos gerenciado livremente pelo usuário final (CRUD) + lançamento mensal de participações (upsert) + novo bloco no relatório.

**Independent Test**: Cadastrar um evento, lançar participações em 1+ meses, confirmar que o bloco "Participação em Eventos" do relatório exibe os totais corretos por mês/ano; relançar o mesmo mês sobrescreve (não soma).

### Tests for User Story 4 ⚠️

- [X] T033 [P] [US4] Criar teste em `ci-api-v2/src/modules/ouvidoria/test/use-cases/create-evento.use-case.spec.ts`
- [X] T034 [P] [US4] Criar teste em `ci-api-v2/src/modules/ouvidoria/test/use-cases/upsert-evento-participacao.use-case.spec.ts` — cobre sobrescrever (não somar) no mesmo evento/mês/ano
- [X] T035 [P] [US4] Criar teste em `ci-api-v2/src/modules/ouvidoria/test/repository/list-evento-participacoes.repository.spec.ts` — cobre preenchimento dos 12 meses com zero quando não há lançamento
- [X] T036 [P] [US4] Criar teste em `ci-client-v2/apps/web/src/modules/ouvidoria/__tests__/OuvidoriaEventosPage.test.tsx` — cadastro de evento + lançamento de participação pela UI

### Implementation for User Story 4 — Schema

- [X] T037 [US4] Criar models `OuvidoriaEvento` e `OuvidoriaEventoParticipacaoLancamento` em `ci-api-v2/prisma/schema/ouvidoria-catalog.prisma` (ver `data-model.md`)
- [X] T038 [US4] Gerar e aplicar migration `ouvidoria_eventos_participacao` (`npx prisma migrate dev` em `ci-api-v2/`) — depende de T037

### Implementation for User Story 4 — Backend (repository)

- [X] T039 [P] [US4] Criar `ci-api-v2/src/modules/ouvidoria/repository/create-evento.repository.ts` — depende de T038
- [X] T040 [P] [US4] Criar `ci-api-v2/src/modules/ouvidoria/repository/update-evento.repository.ts` — depende de T038
- [X] T041 [P] [US4] Criar `ci-api-v2/src/modules/ouvidoria/repository/inactivate-evento.repository.ts` — depende de T038
- [X] T042 [P] [US4] Criar `ci-api-v2/src/modules/ouvidoria/repository/list-eventos.repository.ts` — depende de T038
- [X] T043 [P] [US4] Criar `ci-api-v2/src/modules/ouvidoria/repository/upsert-evento-participacao-lancamento.repository.ts` — depende de T038
- [X] T044 [P] [US4] Criar `ci-api-v2/src/modules/ouvidoria/repository/list-evento-participacoes.repository.ts` — depende de T038 (implementa fill de 12 meses cobrindo T035)

### Implementation for User Story 4 — Backend (use-cases, schemas, rotas)

- [X] T045 [US4] Criar `ci-api-v2/src/modules/ouvidoria/use-cases/create-evento.use-case.ts` — depende de T039
- [X] T046 [US4] Criar `ci-api-v2/src/modules/ouvidoria/use-cases/update-evento.use-case.ts` — depende de T040
- [X] T047 [US4] Criar `ci-api-v2/src/modules/ouvidoria/use-cases/inactivate-evento.use-case.ts` — depende de T041
- [X] T048 [US4] Criar `ci-api-v2/src/modules/ouvidoria/use-cases/list-eventos.use-case.ts` — depende de T042
- [X] T049 [US4] Criar `ci-api-v2/src/modules/ouvidoria/use-cases/upsert-evento-participacao.use-case.ts` — usa `resolveUserTableId` (regra `admin-tenant-user-fk`) — depende de T043
- [X] T050 [US4] Criar schemas Zod (`createEventoBodySchema`, `updateEventoBodySchema`, `upsertEventoParticipacaoBodySchema`) + DTOs em `ci-api-v2/src/modules/ouvidoria/ouvidoria.schemas.ts`
- [X] T051 [US4] Adicionar tipos `EventoDTO`/`EventoParticipacaoLancamentoDTO` em `ci-api-v2/src/modules/ouvidoria/ouvidoria.types.ts`
- [X] T052 [US4] Adicionar rotas em `ci-api-v2/src/modules/ouvidoria/ouvidoria.controller.ts`: `POST /eventos`, `PATCH /eventos/:id`, `POST /eventos/:id/inativar`, `GET /eventos`, `GET /eventos/participacoes`, `POST /eventos/participacoes` — todas `@RequireModulo('ouvidoria')` — depende de T045–T050
- [X] T053 [US4] Registrar os 6 novos providers (repositories + use-cases) em `ci-api-v2/src/modules/ouvidoria/ouvidoria.module.ts`

### Implementation for User Story 4 — Bloco no relatório e exports

- [X] T054 [US4] Atualizar `ci-api-v2/src/modules/ouvidoria/use-cases/get-relatorio-gestao.use-case.ts` — orquestrar bloco `participacaoEventos` — depende de T048, T044
- [X] T055 [US4] Adicionar seção `participacaoEventos` em `ci-api-v2/src/modules/ouvidoria/lib/relatorio-gestao-pdf-sections.ts`
- [X] T056 [US4] Adicionar aba "Participação em Eventos" em `ci-api-v2/src/modules/ouvidoria/use-cases/export-relatorio-gestao-excel.use-case.ts`

### Implementation for User Story 4 — Frontend

- [X] T057 [US4] Criar `ci-client-v2/apps/web/src/modules/ouvidoria/api/eventos.ts` — `listEventos`, `createEvento`, `updateEvento`, `inactivateEvento`, `listParticipacoes`, `upsertParticipacao`
- [X] T058 [US4] Criar `ci-client-v2/apps/web/src/modules/ouvidoria/pages/OuvidoriaEventosPage.tsx` — CRUD de eventos + lançamento de participações — depende de T057, T036
- [X] T059 [US4] Registrar rota `ouvidoria-eventos` em `ci-client-v2/apps/web/src/app/router.tsx` (`OUVIDORIA_OVERRIDES`) e em `ci-client-v2/apps/web/src/modules/shell/config/screens.ts` (`licenses: ['base']`)
- [X] T060 [US4] Adicionar export lazy da página em `ci-client-v2/apps/web/src/modules/ouvidoria/index.ts`
- [X] T061 [US4] Atualizar `ci-client-v2/apps/web/src/modules/ouvidoria/lib/relatorio-gestao-mappers.ts` — mapear bloco `participacaoEventos`
- [X] T062 [US4] Criar `ci-client-v2/apps/web/src/modules/ouvidoria/components/dashboard/ParticipacaoEventosChartCard.tsx`
- [X] T063 [US4] Integrar `ParticipacaoEventosChartCard` em `ci-client-v2/apps/web/src/modules/ouvidoria/pages/OuvidoriaRelatorioGestaoPage.tsx` — depende de T062

**Checkpoint**: US4 completa — testável isoladamente via `quickstart.md` Cenário 4. Independente de US1/US2/US3.

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Validação final entre histórias

- [X] T064 [P] Rodar os 4 cenários de `civ2-docs/specs/049-ajustes-relatorio-gestao-ouvidoria/quickstart.md` de ponta a ponta (US1–US4 já implementadas)
- [X] T065 [P] Validar SC-005 — tela ≤ 5s e exports (PDF/Excel) ≤ 30s no filtro "acumulado geral" com os 3 blocos alterados/novos ativos
- [X] T066 Revisar `civ2-docs/specs/049-ajustes-relatorio-gestao-ouvidoria/checklists/requirements.md` contra a implementação final entregue
- [X] T067 [P] Atualizar `civ2-docs/specs/041-migracao-historico-ouvidoria/spec.md` (ainda Draft) para refletir o novo modelo de contagens Sim/Não em vez do campo "valor" único (Assumption do `spec.md` desta feature — nenhum dado histórico real migrado ainda, sem retrabalho)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: sem dependências
- **Foundational (Phase 2)**: sem tarefas — nada bloqueia o início das histórias
- **User Stories (Phase 3–6)**: todas podem começar após Setup; **US1 e US2 (ambas P1) são a MVP** e não dependem uma da outra; US3 e US4 (P2) também são independentes entre si e das P1 — todas as 4 podem ser trabalhadas em paralelo por pessoas diferentes
- **Polish (Phase 7)**: depende de todas as histórias desejadas estarem completas

### User Story Dependencies

- **US1 (P1)**: sem dependência de outra história
- **US2 (P1)**: sem dependência de outra história — arquivo isolado (`render-relatorio-gestao-pdf.ts`)
- **US3 (P2)**: sem dependência de outra história (soma um bloco novo ao mesmo orquestrador que US1/US4 também tocam — `get-relatorio-gestao.use-case.ts` — ver nota de conflito de arquivo abaixo)
- **US4 (P2)**: sem dependência de outra história

**Nota de arquivo compartilhado**: `get-relatorio-gestao.use-case.ts`, `relatorio-gestao-pdf-sections.ts`, `export-relatorio-gestao-excel.use-case.ts` e `ouvidoria.types.ts` são tocados por US1, US3 e US4 (cada uma adiciona/altera seu próprio bloco). Não é uma dependência lógica entre histórias, mas evite editar esses 4 arquivos em paralelo sem sincronizar — mesclar sequencialmente (ex.: T014/T015/T016 antes de T026/T028/T029, antes de T054/T055/T056) evita conflito de merge.

### Within Each User Story

- Testes escritos e falhando antes da implementação (Constitution II)
- Schema/migration antes de repository
- Repository antes de use-case
- Use-case antes de rota/controller
- Backend antes de frontend consumir

### Parallel Opportunities

- Todas as tarefas `[P]` de uma mesma fase podem rodar em paralelo (arquivos diferentes)
- US1 e US2 podem ser feitas totalmente em paralelo (nenhum arquivo em comum)
- Dentro de US4: T039–T044 (6 repositories) em paralelo; depois T045–T049 (5 use-cases) em paralelo
- US3 e US4 podem rodar em paralelo entre si; ambas só precisam sincronizar com US1 nos 4 arquivos compartilhados citados acima

---

## Parallel Example: User Story 4 (repositories)

```bash
Task: "Criar create-evento.repository.ts em ci-api-v2/src/modules/ouvidoria/repository/create-evento.repository.ts"
Task: "Criar update-evento.repository.ts em ci-api-v2/src/modules/ouvidoria/repository/update-evento.repository.ts"
Task: "Criar inactivate-evento.repository.ts em ci-api-v2/src/modules/ouvidoria/repository/inactivate-evento.repository.ts"
Task: "Criar list-eventos.repository.ts em ci-api-v2/src/modules/ouvidoria/repository/list-eventos.repository.ts"
Task: "Criar upsert-evento-participacao-lancamento.repository.ts em ci-api-v2/src/modules/ouvidoria/repository/upsert-evento-participacao-lancamento.repository.ts"
Task: "Criar list-evento-participacoes.repository.ts em ci-api-v2/src/modules/ouvidoria/repository/list-evento-participacoes.repository.ts"
```

---

## Implementation Strategy

### MVP First (US1 + US2, ambas P1)

1. Completar Phase 1 (Setup)
2. Completar Phase 3 (US1 — satisfação Sim/Não) e Phase 4 (US2 — fix PDF), em paralelo se houver 2 devs
3. **STOP and VALIDATE**: rodar `quickstart.md` Cenários 1 e 2
4. Deploy/demo do MVP — resolve os dois problemas mais urgentes (modelo de dados incorreto + bug de usabilidade)

### Incremental Delivery

1. Setup → MVP (US1 + US2) → validar → deploy
2. Adicionar US3 (orientações/encaminhamentos detalhado) → validar Cenário 3 → deploy
3. Adicionar US4 (participação em eventos) → validar Cenário 4 → deploy
4. Phase 7 (Polish) ao final, cobrindo as 4 histórias já entregues

### Parallel Team Strategy

Com 4 desenvolvedores: cada um pega uma história (US1, US2, US3, US4) após o Setup; sincronizar apenas nos 4 arquivos compartilhados (nota acima) antes de mergear US1/US3/US4.

---

## Notes

- `[P]` = arquivos diferentes, sem dependência pendente
- `[Story]` mapeia a tarefa à história correspondente (rastreabilidade com `spec.md`)
- Verificar que os testes falham antes de implementar (RED → GREEN → REFACTOR, Constitution II)
- Cada história permanece entregável e testável isoladamente — mesmo com os 4 arquivos compartilhados citados
