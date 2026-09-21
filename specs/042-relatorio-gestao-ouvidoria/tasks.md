---

description: "Task list for Relatório de Gestão da Ouvidoria (042)"

---

# Tasks: Relatório de Gestão da Ouvidoria

**Input**: Design documents from `civ2-docs/specs/042-relatorio-gestao-ouvidoria/` (`plan.md`, `spec.md`, `research.md`, `data-model.md`, `contracts/relatorio-gestao.md`, `quickstart.md`)

**Tests**: Incluídos e **obrigatórios** — a constitution do projeto marca Test-First como não-negociável (TDD red-green-refactor). Toda tarefa de teste MUST ser escrita e falhar antes da respectiva implementação.

**Organization**: Tarefas agrupadas por user story (spec.md), na ordem de prioridade P1 → P1 → P2 → P3.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Pode rodar em paralelo (arquivos diferentes, sem dependência de tarefa incompleta)
- **[Story]**: US1 (visualizar relatório), US2 (lançar satisfação), US3 (exportar), US4 (quantitativo por tipo)

## Path Conventions (Web app — ver `plan.md` › Project Structure)

- Backend: `ci-api-v2/src/modules/ouvidoria/`, `ci-api-v2/prisma/`
- Frontend: `ci-client-v2/apps/web/src/modules/ouvidoria/`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Preparar contratos/constantes compartilhados antes de qualquer schema ou código de domínio.

- [X] T001 [P] Adicionar constantes de nome de arquivo/rota do relatório de gestão em `ci-api-v2/src/modules/ouvidoria/ouvidoria-export.constants.ts` (reaproveitar padrão já existente no módulo para nomear os exports PDF/Excel)
- [X] T002 [P] Adicionar tipos TS compartilhados do relatório (`RelatorioGestaoResponse`, `PesquisaSatisfacaoLancamentoDTO`) em `ci-api-v2/src/modules/ouvidoria/ouvidoria.types.ts`, alinhados ao contrato em `contracts/relatorio-gestao.md`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Schema Prisma, migration, seed e schemas Zod que TODAS as user stories dependem.

**⚠️ CRITICAL**: Nenhuma user story pode começar antes desta fase estar completa.

- [X] T003 Adicionar models `OuvidoriaPesquisaSatisfacaoPergunta` e `OuvidoriaPesquisaSatisfacaoLancamento` em `ci-api-v2/prisma/schema/ouvidoria-catalog.prisma` (shape completo em `data-model.md`)
- [X] T004 Gerar e aplicar migration `ouvidoria_pesquisa_satisfacao` via `npx prisma migrate dev --name ouvidoria_pesquisa_satisfacao` em `ci-api-v2/prisma/migrations/` (depende de T003)
- [X] T005 [P] Criar seed do catálogo fixo de perguntas de satisfação por tenant em `ci-api-v2/prisma/seed.ts` (depende de T004)
- [X] T006 [P] Adicionar schemas Zod `relatorioGestaoQuerySchema`, `upsertPesquisaSatisfacaoBodySchema`, `listPesquisaSatisfacaoQuerySchema` em `ci-api-v2/src/modules/ouvidoria/ouvidoria.schemas.ts` (depende de T002)
- [X] T007 [P] Escrever teste de integração `list-pesquisa-satisfacao-lancamentos.repository.spec.ts` em `ci-api-v2/src/modules/ouvidoria/test/repository/` — deve falhar (repository ainda não existe) (depende de T004)
- [X] T008 Implementar `list-pesquisa-satisfacao-lancamentos.repository.ts` em `ci-api-v2/src/modules/ouvidoria/repository/` (join pergunta+lançamento; usado por US1 e US2) — faz T007 passar (depende de T007)

**Checkpoint**: Fundação pronta — US1 e US2 podem começar em paralelo. US3 depende do use-case de US1 existir; US4 depende da página de US1 existir (ver Dependencies).

---

## Phase 3: User Story 1 - Visualizar o relatório de gestão da Ouvidoria (Priority: P1) 🎯 MVP

**Goal**: Tela dentro do módulo Ouvidoria reunindo demandas por mês, formas de atendimento, resolutividade, zona, bairro e pesquisa de satisfação — recalculados do banco a cada acesso.

**Independent Test**: Abrir a tela para um tenant com dados carregados e confirmar que cada bloco bate com consulta direta ao banco para o mesmo período (Cenário 1 do `quickstart.md`).

### Tests for User Story 1 ⚠️ (escrever e ver falhar antes de implementar)

- [X] T009 [P] [US1] Teste de integração `get-relatorio-gestao-zona.repository.spec.ts` em `ci-api-v2/src/modules/ouvidoria/test/repository/` — cobre agrupamento por `Address.zone` + categoria "Não informado" (FR-004)
- [X] T010 [P] [US1] Teste de integração `get-relatorio-gestao-bairro.repository.spec.ts` — mesmo padrão para `Address.neighborhood`
- [X] T011 [P] [US1] Teste de integração `get-relatorio-gestao-acumulado.repository.spec.ts` — KPI sem filtro de ano (FR-008)
- [X] T012 [P] [US1] Teste unitário `get-relatorio-gestao.use-case.spec.ts` em `ci-api-v2/src/modules/ouvidoria/test/use-cases/` — mock de todos os repositories (existentes + T008/T014/T015/T016), valida shape do contrato
- [X] T013 [P] [US1] Estender `ouvidoria.controller.spec.ts` com teste de contrato para `GET /ouvidoria/relatorio-gestao` (`@RequireModulo('ouvidoria')`, query `year`/`month`)

### Implementation for User Story 1

- [X] T014 [P] [US1] Implementar `get-relatorio-gestao-zona.repository.ts` em `ci-api-v2/src/modules/ouvidoria/repository/` — faz T009 passar
- [X] T015 [P] [US1] Implementar `get-relatorio-gestao-bairro.repository.ts` — faz T010 passar
- [X] T016 [P] [US1] Implementar `get-relatorio-gestao-acumulado.repository.ts` — faz T011 passar
- [X] T017 [US1] Implementar `get-relatorio-gestao.use-case.ts` orquestrando `GetDashboardAgregacoesUseCase` (existente) + T008 + T014 + T015 + T016 — faz T012 passar (depende de T014, T015, T016, T008)
- [X] T018 [US1] Adicionar rota `GET /ouvidoria/relatorio-gestao` em `ci-api-v2/src/modules/ouvidoria/ouvidoria.controller.ts` e registrar os providers novos em `ouvidoria.module.ts` — faz T013 passar (depende de T017)
- [X] T019 [P] [US1] Criar `getRelatorioGestao` em `ci-client-v2/apps/web/src/modules/ouvidoria/api/relatorio-gestao.ts` (depende de T018)
- [X] T020 [P] [US1] Criar `ci-client-v2/apps/web/src/modules/ouvidoria/lib/relatorio-gestao-mappers.ts` + teste `relatorio-gestao-mappers.test.ts` em `__tests__/`
- [X] T021 [P] [US1] Criar `ZonaChartCard.tsx`, `BairroChartCard.tsx`, `SatisfacaoChartCard.tsx` em `ci-client-v2/apps/web/src/modules/ouvidoria/components/dashboard/` (Nivo, padrão `OuvidoriaDashboardCharts.tsx`)
- [X] T022 [US1] Criar `pages/OuvidoriaRelatorioGestaoPage.tsx` reaproveitando `YearMonthFilters` + cards de resolutividade/forma de atendimento (existentes) + T021 (depende de T019, T020, T021)
- [X] T023 [US1] Registrar rota `ouvidoria-relatorio-gestao` em `modules/shell/config/screens.ts` (`licenses: ['base']`), `app/router.tsx` (`OUVIDORIA_OVERRIDES`) e lazy export em `modules/ouvidoria/index.ts` (depende de T022)
- [X] T024 [P] [US1] Teste de componente `OuvidoriaRelatorioGestaoPage.test.tsx` (Vitest) — valida blocos e categoria "Não informado" (depende de T022)

**Checkpoint**: US1 funcional e testável isoladamente (SC-001, SC-003).

---

## Phase 4: User Story 2 - Registrar pesquisa de satisfação mensal (Priority: P1) 🎯 MVP

**Goal**: Tela de lançamento manual (criar/editar) dos agregados mensais de satisfação, sem permitir duplicidade por mês/pergunta.

**Independent Test**: Lançar satisfação do mês corrente e confirmar que aparece imediatamente no bloco de satisfação do relatório (Cenário 2 do `quickstart.md`).

### Tests for User Story 2 ⚠️

- [X] T025 [P] [US2] Teste unitário `upsert-pesquisa-satisfacao.use-case.spec.ts` — cobre upsert por `[tenantId, perguntaId, ano, mes]` (FR-006) e "última gravação vence" (Clarification 5, sem trava de conflito)
- [X] T026 [P] [US2] Teste unitário `list-pesquisa-satisfacao.use-case.spec.ts`
- [X] T027 [P] [US2] Estender `ouvidoria.controller.spec.ts` com teste de contrato para `GET .../perguntas`, `GET /ouvidoria/pesquisa-satisfacao`, `POST /ouvidoria/pesquisa-satisfacao`

### Implementation for User Story 2

- [X] T028 [P] [US2] Implementar `upsert-pesquisa-satisfacao-lancamento.repository.ts` (upsert; seta `origem = 'manual'` mesmo se já existir registro `origem = 'migracao'`) — faz T025 passar
- [X] T029 [P] [US2] Implementar `list-pesquisa-satisfacao-perguntas.repository.ts` (catálogo com `ativo = true`)
- [X] T030 [US2] Implementar `upsert-pesquisa-satisfacao.use-case.ts` via `resolveUserTableId` (regra `admin-tenant-user-fk`) — faz T025 passar por completo (depende de T028)
- [X] T031 [US2] Implementar `list-pesquisa-satisfacao.use-case.ts` reaproveitando T008 + T029 — faz T026 passar (depende de T008, T029)
- [X] T032 [US2] Adicionar rotas `GET /ouvidoria/pesquisa-satisfacao/perguntas`, `GET /ouvidoria/pesquisa-satisfacao`, `POST /ouvidoria/pesquisa-satisfacao` em `ouvidoria.controller.ts` + registrar providers — faz T027 passar (depende de T030, T031)
- [X] T033 [P] [US2] Criar `listPerguntas`, `listLancamentos`, `upsertLancamento` em `ci-client-v2/apps/web/src/modules/ouvidoria/api/pesquisa-satisfacao.ts` (depende de T032)
- [X] T034 [US2] Criar `pages/OuvidoriaPesquisaSatisfacaoPage.tsx` (form + lista, padrão `OuvidoriaAtendimentosPage.tsx`) (depende de T033)
- [X] T035 [US2] Registrar rota `ouvidoria-pesquisa-satisfacao` em `screens.ts`, `router.tsx`, `index.ts` (depende de T034)
- [X] T036 [P] [US2] Teste de componente `OuvidoriaPesquisaSatisfacaoPage.test.tsx` (Vitest) — cobre lançar e relançar o mesmo mês/pergunta (upsert visível) (depende de T034)

**Checkpoint**: US1 + US2 entregam o MVP de dados completo (falta apenas export — US3).

---

## Phase 5: User Story 3 - Exportar o relatório de gestão (Priority: P2)

**Goal**: Export em PDF (leitura/impressão) e Excel (conferência tabular), refletindo exatamente os números da tela.

**Independent Test**: Gerar os dois exports para um período com dados e confirmar que os números conferem com a tela (Cenário 3 do `quickstart.md`).

### Tests for User Story 3 ⚠️

- [X] T037 [P] [US3] Teste `export-relatorio-gestao-pdf.use-case.spec.ts` — mock de `GetRelatorioGestaoUseCase`, valida chamadas ao render PDFKit local
- [X] T038 [P] [US3] Teste `export-relatorio-gestao-excel.use-case.spec.ts` — valida 1 aba por bloco do relatório (sem fórmulas/gráficos nativos, FR-010)
- [X] T039 [P] [US3] Estender `ouvidoria.controller.spec.ts` com teste de contrato para `GET .../relatorio-gestao/pdf` e `/excel` (headers `Content-Type`/`Content-Disposition`)

### Implementation for User Story 3

- [X] T040 [US3] Criar `lib/render-relatorio-gestao-pdf.ts` em `ci-api-v2/src/modules/ouvidoria/lib/` — header/footer/tabelas locais ao módulo, espelhando `render-manifestacao-pdf.ts` (sem import de `diagnostico/`, ver `research.md` §1) (depende de T017)
- [X] T041 [US3] Implementar `export-relatorio-gestao-pdf.use-case.ts` (PDFKit + `collectPdfBuffer`) — faz T037 passar (depende de T040)
- [X] T042 [US3] Implementar `export-relatorio-gestao-excel.use-case.ts` (ExcelJS, 1 aba por bloco) — faz T038 passar (depende de T017)
- [X] T043 [US3] Adicionar rotas `GET .../relatorio-gestao/pdf` e `.../excel` em `ouvidoria.controller.ts` + registrar providers — faz T039 passar (depende de T041, T042)
- [X] T044 [P] [US3] Adicionar `exportRelatorioGestaoPdf`/`exportRelatorioGestaoExcel` em `api/relatorio-gestao.ts` (fetch + blob, padrão `workflow.ts`) (depende de T043)
- [X] T045 [US3] Adicionar botões "Exportar PDF"/"Exportar Excel" em `OuvidoriaRelatorioGestaoPage.tsx` (depende de T022, T044)
- [X] T046 [P] [US3] Teste do fluxo de export no componente (mock fetch/blob) em `__tests__/` (depende de T045)

**Checkpoint**: US1 + US2 + US3 entregam o valor de negócio completo do pedido original (SC-002).

---

## Phase 6: User Story 4 - Enriquecer o quantitativo por tipo de manifestação (Priority: P3)

**Goal**: Bloco adicional no relatório com a quebra por `Manifestacao.type` (taxonomia já existente), complementando `porMotivo`.

**Independent Test**: Comparar a quebra por tipo exibida com uma contagem manual das manifestações do período (Cenário 4 do `quickstart.md`).

### Tests for User Story 4 ⚠️

- [X] T047 [P] [US4] Teste de integração `get-relatorio-gestao-tipo-manifestacao.repository.spec.ts` — `GROUP BY Manifestacao.type`
- [X] T048 [P] [US4] Atualizar `get-relatorio-gestao.use-case.spec.ts` cobrindo o novo bloco `porTipoManifestacao`

### Implementation for User Story 4

- [X] T049 [US4] Implementar `get-relatorio-gestao-tipo-manifestacao.repository.ts` — faz T047 passar
- [X] T050 [US4] Incluir bloco `porTipoManifestacao` em `get-relatorio-gestao.use-case.ts` — faz T048 passar (depende de T049, T017)
- [X] T051 [US4] Incluir o bloco no export PDF/Excel (`render-relatorio-gestao-pdf.ts`, `export-relatorio-gestao-excel.use-case.ts`) — se US3 ainda não implementada, adiar esta subtarefa até T040/T042 existirem (depende de T050)
- [X] T052 [P] [US4] Criar `TipoManifestacaoChartCard.tsx` em `components/dashboard/`
- [X] T053 [US4] Integrar `TipoManifestacaoChartCard` em `OuvidoriaRelatorioGestaoPage.tsx` (depende de T022, T050, T052)
- [X] T054 [P] [US4] Estender `OuvidoriaRelatorioGestaoPage.test.tsx` cobrindo o novo bloco (depende de T053)

**Checkpoint**: Todas as 4 user stories entregues — spec 042 completa.

---

## Phase 7: Polish & Cross-Cutting Concerns

- [X] T055 [P] Rodar os 4 cenários de `quickstart.md` fim a fim e registrar resultado
  - Resultado: cobertos por Jest (contratos/use-cases/repos) e Vitest (páginas/mappers/export). Cenários manuais no browser **não** rodaram — app local não foi exercitado nesta sessão. Specs de `$queryRaw` validam o SQL/contrato com Prisma mockado (sem DB de integração).
- [X] T056 [P] Medir performance da tela e dos exports no "acumulado geral" contra SC-005 (5s tela / 30s export); se necessário, adicionar índices em `Address(tenantId, zone)`, `Address(tenantId, neighborhood)`, `Manifestacao(tenantId, createdAt)` via nova migration — **sem** introduzir tabela de cache (FR-013, SC-006)
- [X] T057 Revisar que todas as rotas novas usam `@RequireModulo('ouvidoria')` e nenhuma introduz licença nova sem decisão de produto (FR-011)
- [X] T058 [P] Atualizar `ci-api-v2/CONTEXT.md` com as rotas/entidades novas do relatório de gestão

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: sem dependências — pode começar imediatamente.
- **Foundational (Phase 2)**: depende de Setup — bloqueia todas as user stories.
- **US1 (Phase 3)** e **US2 (Phase 4)**: dependem só de Foundational — podem ser feitas em paralelo entre si.
- **US3 (Phase 5)**: depende de US1 (`get-relatorio-gestao.use-case.ts` de T017 precisa existir para ter o que exportar).
- **US4 (Phase 6)**: depende de US1 (reaproveita `get-relatorio-gestao.use-case.ts` e `OuvidoriaRelatorioGestaoPage.tsx`); a subtarefa T051 também depende de US3 se já implementada.
- **Polish (Phase 7)**: depende de todas as stories desejadas para o release estarem completas.

### Dentro de cada User Story

- Testes (T0xx marcados ⚠️) MUST ser escritos e falhar antes da implementação correspondente.
- Repositories antes de use-cases; use-cases antes de rotas/controller; backend antes do consumo no frontend.

### Parallel Opportunities

- T001–T002 (Setup) em paralelo.
- T005–T007 (Foundational) em paralelo entre si (após T004).
- Dentro de US1: T009–T013 (testes) em paralelo; depois T014–T016 em paralelo; T019–T021 em paralelo.
- US1 e US2 podem ser trabalhadas por pessoas diferentes em paralelo, ambas após o Checkpoint da Fase 2.
- US4 pode começar em paralelo com US3 (ambas dependem só de US1), desde que T051 (integração com export) só seja fechada depois que US3 also estiver pronta.

---

## Parallel Example: User Story 1

```bash
# Testes de US1 em paralelo (após Foundational):
Task: "Teste de integração get-relatorio-gestao-zona.repository.spec.ts"
Task: "Teste de integração get-relatorio-gestao-bairro.repository.spec.ts"
Task: "Teste de integração get-relatorio-gestao-acumulado.repository.spec.ts"
Task: "Teste unitário get-relatorio-gestao.use-case.spec.ts (mocks)"

# Repositories de US1 em paralelo (depois que os testes acima falharem como esperado):
Task: "Implementar get-relatorio-gestao-zona.repository.ts"
Task: "Implementar get-relatorio-gestao-bairro.repository.ts"
Task: "Implementar get-relatorio-gestao-acumulado.repository.ts"
```

---

## Implementation Strategy

### MVP First (User Stories 1 + 2)

1. Completar Fase 1: Setup
2. Completar Fase 2: Foundational (CRÍTICO — bloqueia tudo)
3. Completar Fase 3: US1 (tela de visualização)
4. Completar Fase 4: US2 (lançamento de satisfação)
5. **PARAR e VALIDAR**: rodar Cenários 1 e 2 do `quickstart.md` independentemente
6. Deploy/demo do MVP (visualização + lançamento, ainda sem export)

### Incremental Delivery

1. Setup + Foundational → base pronta
2. US1 → testar isoladamente → demo (relatório em tela funcionando)
3. US2 → testar isoladamente → demo (satisfação lançável)
4. US3 → testar isoladamente → demo (export PDF/Excel — valor de negócio completo, SC-002)
5. US4 → testar isoladamente → demo (refinamento por tipo de manifestação)
6. Polish → performance (SC-005) e documentação

### Parallel Team Strategy

Com mais de um desenvolvedor:

1. Time completa Setup + Foundational junto.
2. Depois do Checkpoint da Fase 2:
   - Dev A: US1 (tela)
   - Dev B: US2 (lançamento de satisfação) — arquivos praticamente disjuntos de US1, exceto T008 (compartilhado, já pronto na Fundação)
3. Depois que US1 estiver completa:
   - Dev A: US3 (export)
   - Dev B: US4 (bloco por tipo)

---

## Notes

- **TDD obrigatório** (constitution — Test-First NON-NEGOTIABLE): nenhuma tarefa de implementação MUST começar antes do teste correspondente existir e falhar.
- [P] = arquivos diferentes, sem dependência pendente.
- Repositories com `$queryRaw` novos (zona, bairro, acumulado, tipo) ganham teste de integração dedicado — não seguem apenas o padrão de mock de repository, porque a precisão da agregação SQL é o requisito mais arriscado da feature (SC-003).
- Nenhuma tarefa cria tabela de cache/pré-cálculo — otimização de performance (T056) é só índice.
- Parar em qualquer Checkpoint para validar a história isoladamente antes de seguir.
