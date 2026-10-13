# Tasks: Registros em Planilha (Ouvidoria)

**Input**: Design documents from `civ2-docs/specs/055-registros-controle-demandas/`

**Prerequisites**: plan.md, spec.md, contracts/rest-api-registros-excel.md

**Tests**: TDD obrigatório (Constitution II — RED → GREEN → REFACTOR). Skills: `tdd`, `testing-conventions` (API, Jest), Vitest no client.

**Organization**: Tasks agrupadas por user story. US2 e US3 estendem o caso de uso criado na US1.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Pode rodar em paralelo (arquivo diferente, sem depender de tarefa incompleta)
- **[Story]**: US1–US3

## Path Conventions

- **API**: `ci-api-v2/src/modules/ouvidoria/`
- **Client**: `ci-client-v2/apps/web/src/modules/ouvidoria/`
- **Sem migration**: só leitura do Postgres existente; auditoria no `AuditLog` já existente

---

## Phase 1: Setup

- [x] T001 [P] Criar `ci-api-v2/src/modules/ouvidoria/ouvidoria-registros-export.constants.ts`: `REGISTROS_EXPORT_MAX_ROWS = 20000`, `REGISTROS_EXPORT_THROTTLE_PER_MINUTE = 3`, `REGISTROS_EXPORT_PAGE_SIZE = 500`, nomes de aba por código de concessão (`'1'..'6'` + `Sem concessão`), nome do arquivo (`controle-de-demandas-{ano}[-{mes-com-2-digitos}].xlsx`)
- [x] T002 [P] Acrescentar em `ci-api-v2/src/modules/ouvidoria/lib/ouvidoria-errors.ts` os códigos `REGISTROS_PERIODO_VAZIO`, `REGISTROS_LIMITE_LINHAS`, `REGISTROS_THROTTLE` com mensagens em português (contrato §Erros)
- [x] T003 [P] Adicionar em `ci-api-v2/src/modules/ouvidoria/ouvidoria.schemas.ts` o schema `registrosExportQuerySchema` (`ano` obrigatório 2000–2100, `mes` opcional 1–12, `z.coerce.number()`)

**Checkpoint**: Constantes, erros e schema importáveis. Nenhuma rota ainda

---

## Phase 2: Foundational (Blocking Prerequisites)

**⚠️ CRITICAL**: nenhuma user story começa antes disto

- [x] T004 [P] Escrever teste RED em `ci-api-v2/src/modules/ouvidoria/lib/map-manifestacao-registro-row.spec.ts`: mapeia cada uma das 25 colunas (anônimo → `ANÔNIMO`; telefone com fallback celular→fixo→comercial→e-mail; `closed`→`RESOLVIDA`; `closed_meio_juridico`→`MEIO JURÍDICO`; `draft`/`in_review`/`forwarding`/`answered`/`closed_unresolved`→`PENDENTE`; `jaEntrouContato` true/false/null → `SIM`/`NÃO`/`''`; as 8 colunas sem fonte retornam `''`); motivo canônico sai em maiúsculas; motivo fora do catálogo sai em maiúsculas sem quebrar
- [x] T005 Implementar `mapManifestacaoRegistroRow` em `ci-api-v2/src/modules/ouvidoria/lib/map-manifestacao-registro-row.ts` até T004 passar
- [x] T006 [P] Escrever teste RED em `ci-api-v2/src/modules/ouvidoria/lib/registros-controle-demandas-workbook.spec.ts`: título (linha 1), legendas ND/NI (linhas 3–4) e cabeçalho de 25 colunas (linha 6) idênticos (nomes e ordem) ao da planilha de referência em cada aba criada, sem células mescladas e sem linha de período na aba; só cria aba para concessão com ao menos uma linha; coluna `#` é fórmula (`=ROW(A1)` na primeira linha de dados, `=ROW(A2)` na segunda etc.); cabeçalho em negrito/centralizado com borda fina; larguras de coluna idênticas às da referência
- [x] T007 Implementar `buildRegistrosControleDemandasWorkbook` em `ci-api-v2/src/modules/ouvidoria/lib/registros-controle-demandas-workbook.ts` (constantes de cabeçalho/estilo/largura; `exceljs`) até T006 passar
- [x] T008 [P] Escrever teste RED em `ci-api-v2/src/modules/ouvidoria/test/repository/list-manifestacoes-registros.repository.spec.ts`: `where` tem `tenantId` do contexto, `deletedAt: null`, `createdAt` dentro do intervalo do período; paginação por cursor (`createdAt`, `id` ascendentes, página de 500); id de outro tenant não entra; cada página só traz as colunas necessárias ao mapeamento (sem `description`)
- [x] T009 Implementar `ListManifestacoesRegistrosRepository` em `ci-api-v2/src/modules/ouvidoria/repository/list-manifestacoes-registros.repository.ts` (iterador assíncrono por página) até T008 passar

**Checkpoint**: Mapeamento de linha, construtor de workbook e repositório paginado testados. Caso de uso ainda não existe

---

## Phase 3: User Story 1 — Baixar a planilha de um mês ou de um ano (Priority: P1) 🎯 MVP

**Goal**: `GET /ouvidoria/manifestacoes/registros/excel?ano=&mes=` devolve o `.xlsx` com uma aba por concessão e 25 colunas, igual à planilha de referência.

**Independent Test**: Mês com manifestações em 2 concessões → a planilha baixada tem 2 abas com cabeçalho idêntico e uma linha por manifestação daquele mês.

### Tests for User Story 1 ⚠️

- [x] T010 [P] [US1] Escrever teste RED em `ci-api-v2/src/modules/ouvidoria/test/use-cases/export-registros-manifestacoes-excel.use-case.spec.ts`: caminho feliz com mês (lê em páginas via T009, mapeia cada linha via T005, agrupa por `resolveProgramaCode`, monta o workbook via T007, devolve `{ buffer, fileName, mimeType, totalLinhas }`); caminho feliz com ano inteiro (sem `mes`); manifestação sem concessão identificável cai na aba `Sem concessão`
- [x] T011 [P] [US1] Escrever teste RED (mesmo arquivo T010) cobrindo o nome do arquivo: `controle-de-demandas-2026.xlsx` para ano; `controle-de-demandas-2026-03.xlsx` para mês
- [x] T012 [P] [US1] Escrever teste RED em `ci-client-v2/apps/web/src/modules/ouvidoria/__tests__/BulkDownloadDialog.test.tsx` (estender): seletor "Gerar manifestações" / "Gerar registros"; ao escolher "Gerar registros", aparece painel de período (mês/ano) com o mês atual pré-selecionado; o fluxo "Gerar manifestações" (contador N de 50, busca, chips) continua intacto e inalterado

### Implementation for User Story 1

- [x] T013 [US1] Implementar `ExportRegistrosManifestacoesExcelUseCase` em `ci-api-v2/src/modules/ouvidoria/use-cases/export-registros-manifestacoes-excel.use-case.ts` só com o caminho feliz de T010/T011. Recusas ficam para a US2
- [x] T014 [US1] Registrar repositório e caso de uso em `ci-api-v2/src/modules/ouvidoria/ouvidoria.module.ts`. Expor `GET manifestacoes/registros/excel` em `ci-api-v2/src/modules/ouvidoria/ouvidoria.controller.ts` com `@RequireModulo('ouvidoria')`, parse de `registrosExportQuerySchema`, resposta `StreamableFile` com `Content-Disposition`
- [x] T015 [US1] Criar `ci-client-v2/apps/web/src/modules/ouvidoria/api/registros-export.ts` (uma requisição autenticada, blob, nome via `Content-Disposition`; extrair o helper de salvar blob hoje embutido em `triggerNativeBulkDownload` de `api/bulk-download.ts` para os dois arquivos reutilizarem). Em `ci-client-v2/apps/web/src/modules/ouvidoria/components/BulkDownloadDialog.tsx`, adicionar o seletor de saída e o painel "Gerar registros" (mês/ano, botão "Gerar planilha") sem alterar o fluxo "Gerar manifestações" existente, até T012 passar

**Checkpoint**: Um mês com dados em duas concessões gera uma planilha de 2 abas igual à referência. O fluxo PDF/ZIP da 054 continua passando sem alteração

---

## Phase 4: User Story 2 — Recusar período vazio ou grande demais (Priority: P2)

**Goal**: Período sem manifestação ou acima do teto de linhas é recusado antes de qualquer geração, com mensagem clara; throttle por usuário.

**Independent Test**: Mês sem nenhuma manifestação → 404 com mensagem clara, nenhum arquivo. Período com mais linhas que o teto → 422 informando o teto, nenhum arquivo.

### Tests for User Story 2 ⚠️

- [x] T016 [P] [US2] Estender `ci-api-v2/src/modules/ouvidoria/test/use-cases/export-registros-manifestacoes-excel.use-case.spec.ts` com RED: período sem nenhuma linha → `REGISTROS_PERIODO_VAZIO`, nenhum workbook construído; total de linhas acima de `REGISTROS_EXPORT_MAX_ROWS` → `REGISTROS_LIMITE_LINHAS` com `{ totalLinhas, limiteLinhas }`, geração interrompida ao atingir o teto durante a paginação (sem ler o período inteiro antes de recusar)
- [x] T017 [P] [US2] Estender `ci-client-v2/apps/web/src/modules/ouvidoria/__tests__/BulkDownloadDialog.test.tsx` com RED: resposta 404/422 do endpoint de registros mostra a mensagem no painel, sem fechar o modal e sem afetar o fluxo "Gerar manifestações"

### Implementation for User Story 2

- [x] T018 [US2] Completar os ramos de recusa em `ci-api-v2/src/modules/ouvidoria/use-cases/export-registros-manifestacoes-excel.use-case.ts` (conta linhas durante a paginação; para e recusa ao estourar o teto, sem continuar lendo) até T016 passar
- [x] T019 [US2] Aplicar `@Throttle` (`REGISTROS_EXPORT_THROTTLE_PER_MINUTE`) no `GET` em `ci-api-v2/src/modules/ouvidoria/ouvidoria.controller.ts`; mostrar os três erros (período vazio, limite de linhas, throttle) no painel em `ci-client-v2/apps/web/src/modules/ouvidoria/components/BulkDownloadDialog.tsx` via `ci-client-v2/apps/web/src/modules/ouvidoria/lib/bulk-download-messages.ts` até T017 passar

**Checkpoint**: Período vazio ou grande demais nunca gera arquivo. US1 continua passando

---

## Phase 5: User Story 3 — Auditoria da planilha (Priority: P3)

**Goal**: Sucesso e recusa de "Gerar registros" ficam no `AuditLog`, sem dado pessoal, com autor correto quando não há linha em `User`.

**Independent Test**: Gerar uma planilha e recusar um período vazio; os dois aparecem no `AuditLog` com `action: 'ouvidoria.manifestacao.registros_export'`, sem nome/telefone/endereço no payload.

### Tests for User Story 3 ⚠️

- [x] T020 [P] [US3] Escrever teste RED em `ci-api-v2/src/modules/ouvidoria/test/use-cases/registros-export-audit.spec.ts`: sucesso e cada recusa chamam `CreateAuditLogRepository` com `action: 'ouvidoria.manifestacao.registros_export'`, `entity: 'Manifestacao'`, `entityId: null`; `userId` via `resolveUserTableId`; papel `admin_tenant`/`admin_saas` usa `withActorPayload` (`actorId`/`actorRole`, `userId` nulo); payload tem `periodo`, `totalLinhas`, `resultado` e lista de abas com contagem — nunca nome, telefone, endereço ou protocolo individual

### Implementation for User Story 3

- [x] T021 [US3] Gravar o audit nos desfechos (sucesso e cada recusa) de `ci-api-v2/src/modules/ouvidoria/use-cases/export-registros-manifestacoes-excel.use-case.ts` até T020 passar

**Checkpoint**: Sucesso e recusa deixam rastro consultável sem dado pessoal

---

## Phase 6: Polish & Cross-Cutting Concerns

- [x] T022 Rodar `npm test -- --testPathPatterns=registros` em `ci-api-v2/` e `npm test -- -t registros` (ou filtro equivalente) em `ci-client-v2/apps/web/`, mais a suíte completa de `bulk-download` para confirmar que o fluxo PDF/ZIP da 054 não regrediu
- [ ] T023 [P] Gerar uma planilha de teste (fixture ou ambiente local) e comparar com `Controle de Demandas 2026.xlsx` usando `openpyxl` (cabeçalho, fonte, bordas, largura) e `scripts/recalc.py` da skill `xlsx` (zero erros de fórmula na coluna `#`)
- [ ] T024 Rodar `npm run typecheck` e `npm run build` em `ci-api-v2/` e `ci-client-v2/`
- [ ] T025 Atualizar `civ2-docs/specs/README.md` com a linha da spec 055

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: começa imediato
- **Foundational (Phase 2)**: depende da Phase 1 e bloqueia todas as histórias
- **US1 (Phase 3)**: depende da Phase 2. Primeira entrega utilizável
- **US2 (Phase 4)**: depende da US1 (mesmo caso de uso)
- **US3 (Phase 5)**: depende da US2 (cobre sucesso e as duas recusas)
- **Polish (Phase 6)**: depende das histórias desejadas

### Within Each User Story

- Teste RED antes do código que o faz passar
- Repositório e construtor de workbook antes do caso de uso; caso de uso antes da rota; rota antes do client que a chama

### Parallel Opportunities

- Phase 1: T001, T002, T003 juntos
- Phase 2: T004/T005, T006/T007, T008/T009 em paralelo entre pares (arquivos diferentes)
- US1: T010/T011 e T012 juntos (arquivos diferentes); T013 depois de T010/T011, T015 depois de T012

---

## Implementation Strategy

### MVP First (User Story 1)

1. Phase 1 e Phase 2
2. Phase 3 (US1) — planilha feliz com mês e ano
3. Parar e validar contra a planilha de referência (T023 adiantado, se útil)
4. Só então recusas (US2) e auditoria (US3)

### Notes

- `admin_tenant`/`admin_saas`: `resolveUserTableId` + `withActorPayload` (tarefa T021)
- Nenhuma tarefa toca `BulkDownloadProvider.tsx`, `BulkDownloadIndicator.tsx` nem a sessão do PDF/ZIP — só `BulkDownloadDialog.tsx` ganha o seletor de saída
- Sem migration; sem sessão; sem fila
