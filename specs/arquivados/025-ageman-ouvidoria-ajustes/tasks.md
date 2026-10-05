# Tasks: Ajustes internos da Ouvidoria AGEMAN

**Input**: Design documents from `/specs/025-ageman-ouvidoria-ajustes/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Tests**: Incluídos. A constitution e o pedido desta sessão exigem TDD: o teste nasce falhando e só então entra o código de produção.

**Organization**: US1 e US2 são P1. US3 a US6 são P2. O MVP é a User Story 1 (contas que fecham). A limpeza `ouv-demo` (US2) usa o mesmo filtro oficial.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Pode rodar em paralelo (arquivos diferentes, sem depender de tarefa incompleta)
- **[Story]**: História da spec (`[US1]` … `[US6]`)
- Cada tarefa cita o caminho do arquivo

## Path Conventions

- API: `sci-api-v2/src/modules/ouvidoria/`
- Client: `sci-client-v2/sci-client-monorepo/apps/web/src/modules/`
- Planilha fora: não editar `sci-api-v2/src/modules/ouvidoria/use-cases/export-relatorio-gestao-excel.use-case.ts`
- Ficha PDF/DOCX fora: não editar os renderizadores da ficha

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Predicado único de manifestação oficial, usado pelas contas e pela lista.

- [X] T001 Criar `manifestacaoOficialWhere` e o texto SQL de exclusão de `draft` e de protocolo `ouv-demo` em `sci-api-v2/src/modules/ouvidoria/lib/manifestacao-oficial.ts`, com teste em `sci-api-v2/src/modules/ouvidoria/lib/manifestacao-oficial.spec.ts`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: As agregações do relatório deixam de contar rascunho e `ouv-demo`. Bloqueia US1 e US2.

**⚠️ CRITICAL**: US1 só fecha depois desta fase.

- [X] T002 Aplicar o filtro oficial e o mês em UTC nas consultas de `sci-api-v2/src/modules/ouvidoria/repository/dashboard.repositories.ts`, `get-relatorio-gestao-acumulado.repository.ts`, `get-relatorio-gestao-zona.repository.ts`, `get-relatorio-gestao-bairro.repository.ts`, `get-relatorio-gestao-tipo-manifestacao.repository.ts`, `get-relatorio-gestao-orientacoes-encaminhamentos.repository.ts`, `get-relatorio-gestao-concessao-desfecho.repository.ts` e `get-relatorio-gestao-serie-historica.repository.ts`
- [X] T003 Incluir `closed_unresolved` em Pendentes dentro de `kpisFromStatusGroups` em `sci-api-v2/src/modules/ouvidoria/repository/dashboard.repositories.ts`, mantendo `desfechoPendentes` para a planilha
- [X] T004 Passar ano e mês do recorte para o acumulado em `sci-api-v2/src/modules/ouvidoria/use-cases/get-relatorio-gestao.use-case.ts` e `sci-api-v2/src/modules/ouvidoria/repository/get-relatorio-gestao-acumulado.repository.ts`

**Checkpoint**: Pendentes + Resolvidas + Meio jurídico = Total, e a soma dos meses usa a mesma janela.

---

## Phase 3: User Story 1 - Os totais batem (Priority: P1) 🎯 MVP

**Goal**: Métrica, acumulado e atendimento por mês contam o mesmo conjunto oficial.

**Independent Test**: Um `closed_unresolved`, um `OUV-DEMO-2026-0014` e um `createdAt` na virada UTC não quebram a igualdade Total = grupos = soma dos meses.

### Tests for User Story 1

- [X] T005 [P] [US1] Atualizar expectativas de Pendentes, filtro oficial e mês UTC em `sci-api-v2/src/modules/ouvidoria/test/repository/dashboard-agregacoes.repository.spec.ts` e `sci-api-v2/src/modules/ouvidoria/test/repository/get-relatorio-gestao-acumulado.repository.spec.ts`
- [X] T006 [P] [US1] Exigir Meio jurídico na métrica do período em `sci-client-v2/sci-client-monorepo/apps/web/src/modules/ouvidoria/__tests__/relatorio-gestao-mappers.test.ts` e `sci-client-v2/sci-client-monorepo/apps/web/src/modules/ouvidoria/__tests__/OuvidoriaRelatorioGestaoPage.test.tsx`

### Implementation for User Story 1

- [X] T007 [US1] Mostrar Meio jurídico e tirar a menção a rascunho em `sci-client-v2/sci-client-monorepo/apps/web/src/modules/ouvidoria/components/dashboard/DashboardStatsCards.tsx` e `sci-client-v2/sci-client-monorepo/apps/web/src/modules/ouvidoria/lib/relatorio-gestao-mappers.ts`

**Checkpoint**: A User Story 1 funciona sozinha na tela e na API.

---

## Phase 4: User Story 2 - Apagar demonstrações (Priority: P1)

**Goal**: Protocolos com `ouv-demo` são apagados de vez e não voltam nas contas.

**Independent Test**: Depois do purge, `OUV-DEMO-2026-0014` não é encontrada. Manifestação sem o marcador permanece.

### Tests for User Story 2

- [X] T008 [US2] Escrever teste que falha do purge em `sci-api-v2/src/modules/ouvidoria/use-cases/purge-manifestacoes-demo.use-case.spec.ts`

### Implementation for User Story 2

- [X] T009 [US2] Implementar exclusão física em `sci-api-v2/src/modules/ouvidoria/use-cases/purge-manifestacoes-demo.use-case.ts` e o script `sci-api-v2/src/modules/ouvidoria/scripts/purge-manifestacoes-demo.ts`, com o atalho em `sci-api-v2/package.json`

**Checkpoint**: A User Story 2 apaga só o marcador `ouv-demo`.

---

## Phase 5: User Story 5 - Filtro de status (Priority: P2)

**Goal**: A lista filtra por Todos os status, Pendente, Resolvida pela AGEMAN e Meio jurídico, sem o bloco Pendente (desfecho).

**Independent Test**: O filtro tem quatro opções. Pendente reúne análise, tramitação e desfecho pendente. Rascunho não entra.

### Tests for User Story 5

- [X] T010 [P] [US5] Cobrir `situacao` em `sci-api-v2/src/modules/ouvidoria/ouvidoria.schemas.spec.ts` e `sci-api-v2/src/modules/ouvidoria/use-cases/list-manifestacoes.use-case.spec.ts`
- [X] T011 [P] [US5] Trocar o teste do filtro em `sci-client-v2/sci-client-monorepo/apps/web/src/modules/ouvidoria/pages/__tests__/ManifestacoesListPage.status-labels.test.tsx`

### Implementation for User Story 5

- [X] T012 [US5] Aceitar `situacao` e excluir rascunho e `ouv-demo` da lista padrão em `sci-api-v2/src/modules/ouvidoria/ouvidoria.schemas.ts`, `sci-api-v2/src/modules/ouvidoria/use-cases/list-manifestacoes.use-case.ts` e `sci-api-v2/src/modules/ouvidoria/repository/manifestacao.repositories.ts`
- [X] T013 [US5] Enviar `situacao` e remover o bloco Pendente (desfecho) em `sci-client-v2/sci-client-monorepo/apps/web/src/modules/ouvidoria/api/manifestacoes.ts` e `sci-client-v2/sci-client-monorepo/apps/web/src/modules/ouvidoria/pages/ManifestacoesListPage.tsx`

**Checkpoint**: A lista oficial usa só os três grupos mais Todos os status.

---

## Phase 6: User Story 4 - Voltar para a página 4 (Priority: P2)

**Goal**: Na mesma visita, a lista reabre na página e nos filtros em que o operador estava.

**Independent Test**: Página 4 gravada na visita volta a abrir na página 4. Visita vazia começa na página 1. Mudar filtro volta à página 1.

### Tests for User Story 4

- [X] T014 [US4] Testar leitura e gravação da visita em `sci-client-v2/sci-client-monorepo/apps/web/src/modules/ouvidoria/lib/__tests__/manifestacao-lista-visita.test.ts`

### Implementation for User Story 4

- [X] T015 [US4] Persistir a visita em `sci-client-v2/sci-client-monorepo/apps/web/src/modules/ouvidoria/lib/manifestacao-lista-visita.ts`, `sci-client-v2/sci-client-monorepo/apps/web/src/modules/ouvidoria/pages/ManifestacoesListPage.tsx` e `sci-client-v2/sci-client-monorepo/apps/web/src/modules/ouvidoria/pages/ManifestacaoDetailPage.tsx`

**Checkpoint**: Sair e voltar na mesma visita não cai na página 1.

---

## Phase 7: User Story 3 - Zona automática (Priority: P2)

**Goal**: No formulário de nova manifestação a zona sai do bairro e não é digitável.

**Independent Test**: Com `zoneLocked`, o campo Zona é somente leitura e acompanha o bairro. Sem a trava, o campo continua editável.

### Tests for User Story 3

- [X] T016 [US3] Cobrir zona travada em `sci-client-v2/sci-client-monorepo/apps/web/src/modules/shared/components/__tests__/AddressForm.test.tsx`

### Implementation for User Story 3

- [X] T017 [US3] Travar a zona só na nova manifestação em `sci-client-v2/sci-client-monorepo/apps/web/src/modules/shared/components/AddressForm.tsx`, `AddressFields.tsx`, `AddressFieldsContext.tsx`, `fields/index.tsx` e `sci-client-v2/sci-client-monorepo/apps/web/src/modules/ouvidoria/components/ManifestacaoStepOneForm.tsx`

**Checkpoint**: A ficha já salva continua com zona editável.

---

## Phase 8: User Story 6 - Quem tem acesso (Priority: P2)

**Goal**: Só o super administrador Romulo Gabriel Pinheiro Pereira vê o bloco.

**Independent Test**: Esse nome com `isSuperAdmin` vê o bloco. Administrador, usuário comum e outro super administrador não veem e a tela não pede a lista de acessos.

### Tests for User Story 6

- [X] T018 [P] [US6] Testar o predicado em `sci-client-v2/sci-client-monorepo/apps/web/src/modules/ouvidoria/lib/__tests__/can-view-quem-tem-acesso.test.ts`
- [X] T019 [P] [US6] Esconder o cartão para quem não é a conta nomeada em `sci-client-v2/sci-client-monorepo/apps/web/src/modules/ouvidoria/components/__tests__/ManifestacaoAcessoCard.test.tsx`

### Implementation for User Story 6

- [X] T020 [US6] Implementar o predicado e o corte visual em `sci-client-v2/sci-client-monorepo/apps/web/src/modules/ouvidoria/lib/can-view-quem-tem-acesso.ts`, `sci-client-v2/sci-client-monorepo/apps/web/src/modules/ouvidoria/components/ManifestacaoAcessoCard.tsx` e `sci-client-v2/sci-client-monorepo/apps/web/src/modules/ouvidoria/pages/ManifestacoesListPage.tsx`

**Checkpoint**: A User Story 6 não altera a regra de conceder acesso no servidor.

---

## Phase 9: Polish

**Purpose**: Os testes do quickstart passam juntos.

- [X] T021 Rodar os Jest citados em `specs/025-ageman-ouvidoria-ajustes/quickstart.md` a partir de `sci-api-v2`
- [X] T022 Rodar os Vitest citados em `specs/025-ageman-ouvidoria-ajustes/quickstart.md` a partir de `sci-client-v2/sci-client-monorepo/apps/web`

---

## Dependencies & Execution Order

- T001 antes de T002–T004
- T005 pode nascer junto de T002; o código de T002–T004 faz T005 passar
- T006 antes de T007
- T008 antes de T009
- T010–T011 antes de T012–T013
- T014 antes de T015
- T016 antes de T017
- T018–T019 antes de T020
- T021 e T022 por último

## Parallel Opportunities

- T005 e T006 (arquivos de teste diferentes) depois que o comportamento da API estiver definido
- T010 e T011
- T018 e T019
- US3 (zona) não depende de US4 (página) nem de US6 (acesso)

## Implementation Strategy

MVP é a User Story 1: contas iguais, sem `ouv-demo` e sem rascunho, com Pendentes incluindo o antigo desfecho. Em seguida a exclusão física (US2), o filtro da lista (US5), a página da visita (US4), a zona (US3) e o bloco de acesso (US6).

## Notes

- Não criar migration nem chamar `npm run prisma:generate`
- Exclusão de `ouv-demo` é `DELETE` SQL, porque o Prisma de `Manifestacao` só faz soft delete
