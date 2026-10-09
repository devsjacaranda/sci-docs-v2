# Tasks: Download em Massa de Manifestações (Ouvidoria)

**Input**: Design documents from `civ2-docs/specs/054-download-massa-manifestacoes/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/rest-api-download-massa.md, security.md, quickstart.md

**Tests**: TDD obrigatório (Constitution II — RED → GREEN → REFACTOR). Cada tarefa de teste deve falhar antes da implementação correspondente. Skills: `tdd`, `testing-conventions` (API, Jest), Vitest no client.

**Organization**: Tasks grouped by user story. US4, US2, US3, US5 e US6 estendem os use cases criados na US1; não são entregas paralelas dos mesmos arquivos.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks)
- **[Story]**: Which user story this task belongs to (US1–US6)
- Include exact file paths in descriptions

## Path Conventions

- **API**: `ci-api-v2/src/modules/ouvidoria/` e `ci-api-v2/src/modules/shared/storage/`
- **Client**: `ci-client-v2/apps/web/src/modules/ouvidoria/` e o provider em `ci-client-v2/apps/web/src/App.tsx`
- **Sem migration**: sessão em memória, cache no Wasabi, rastro no `AuditLog` existente

---

## Phase 1: Setup

**Purpose**: Dependência de ZIP em stream e constantes do lote

- [x] T001 Adicionar `yazl` em `ci-api-v2/package.json` (instalar e travar no `ci-api-v2/package-lock.json`). Não usar `jszip` neste fluxo
- [x] T002 [P] Criar `ci-api-v2/src/modules/ouvidoria/ouvidoria-bulk-download.constants.ts` com os tetos de `research.md`: 50 manifestações, 1 073 741 824 bytes, TTL de sessão 60 s, cache 24 h, 1 transmissão por usuário, 2 no processo, `PDF_RENDER_REVISION = 1`, throttle 5/min. Comentário no inteiro: subir no mesmo PR que mudar o código do renderer. Trocar o arquivo de timbrado invalida pelo fingerprint (T007), sem subir o inteiro

**Checkpoint**: Pacote instalado e constantes importáveis. Nenhuma rota ainda

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Peças usadas por todas as histórias. Nenhuma user story começa antes disto.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T003 [P] Escrever teste RED em `ci-api-v2/src/modules/ouvidoria/lib/sanitize-zip-entry-name.spec.ts`: remove `\`, `/`, `..`, caracteres de controle; trunca; colisão ganha sufixo ` (2)`; `../../etc/passwd` e `a\\b` permanecem um único segmento sem sair da pasta
- [x] T004 Implementar `sanitizeZipEntryName` em `ci-api-v2/src/modules/ouvidoria/lib/sanitize-zip-entry-name.ts` até T003 passar
- [x] T005 [P] Escrever teste RED em `ci-api-v2/src/modules/ouvidoria/lib/bulk-download-session.spec.ts`: cria sessão com ticket de 32 bytes; lookup de outro `userId` ou outro `tenantId` devolve ausente; segunda sessão do mesmo usuário é recusada enquanto a primeira está `preparada` ou `transmitindo`; TTL 60 s marca `expirada`; `abort` muda status para `cancelada`; comparação de ticket não usa `===` em cima de strings de tamanho diferente sem normalizar (tempo constante)
- [x] T006 Implementar o mapa em memória em `ci-api-v2/src/modules/ouvidoria/lib/bulk-download-session.ts` (`crypto.randomBytes(32)` base64url, um por usuário, teto global 2) até T005 passar
- [x] T007 [P] Escrever teste RED em `ci-api-v2/src/modules/ouvidoria/lib/manifestacao-pdf-revision.spec.ts`: o mesmo input gera a mesma revisão; `deletedAt` de anexo, `updatedAt` da manifestação, `evento.createdAt` mais novo, `PDF_RENDER_REVISION` diferente ou a data de alteração dos arquivos de timbrado (`resolveLetterheadAssets`) mudam o hash; a função não recebe caminho livre do cliente
- [x] T008 Implementar `manifestacaoPdfRevision` em `ci-api-v2/src/modules/ouvidoria/lib/manifestacao-pdf-revision.ts` (SHA-256, prefixo de 16 hex, incluindo `mtime` dos PNG de timbrado quando existirem) conforme `data-model.md`, até T007 passar
- [x] T009 [P] Escrever teste RED em `ci-api-v2/src/modules/shared/storage/storage.service.stream.spec.ts`: `getObjectStream` e `headContentLength` chamam `validateTenantPath`; chave de outro tenant recusa; modo stub devolve o arquivo local como stream e o tamanho; objeto ausente rejeita. Não alterar o comportamento de `getObjectBuffer`
- [x] T010 Acrescentar `getObjectStream` e `headContentLength` em `ci-api-v2/src/modules/shared/storage/storage.port.ts` e implementar em `ci-api-v2/src/modules/shared/storage/storage.service.ts` até T009 passar
- [x] T011 [P] Escrever teste RED em `ci-api-v2/src/modules/ouvidoria/test/repository/find-manifestacoes-for-bulk.repository.spec.ts`: o `where` tem `id in`, `tenantId` do contexto e `deletedAt: null`; id de outro tenant não volta; o resultado traz `updatedAt`, concessionária, anexos (inclusive tombstone) e o maior `evento.createdAt` para o fingerprint
- [x] T012 Implementar `FindManifestacoesForBulkRepository` em `ci-api-v2/src/modules/ouvidoria/repository/find-manifestacoes-for-bulk.repository.ts` com `this.prisma` (client base) e filtros explícitos — não reutilizar `FindManifestacaoByIdRepository` — até T011 passar
- [x] T013 [P] Acrescentar em `ci-api-v2/src/modules/ouvidoria/lib/ouvidoria-errors.ts` os códigos e as mensagens em português de `contracts/rest-api-download-massa.md`: `LOTE_ACESSO_NEGADO`, `LOTE_NAO_ENCONTRADA`, `LOTE_LIMITE_QUANTIDADE`, `LOTE_LIMITE_VOLUME`, `LOTE_TAMANHO_DESCONHECIDO`, `LOTE_JA_EM_ANDAMENTO`, `LOTE_SERVIDOR_OCUPADO`, `LOTE_EXPIRADO`
- [x] T014 [P] Adicionar em `ci-api-v2/src/modules/ouvidoria/ouvidoria.schemas.ts` o body `{ manifestacaoIds }` (UUID, 1 a 50, no estilo `z.uuid()` já usado no arquivo) e a query `q` da busca (trim, 2–80)

**Checkpoint**: Sanitização, sessão, revisão, stream de storage, repository e contratos de erro testados. Use case de lote ainda não existe.

---

## Phase 3: User Story 1 — Selecionar e baixar o ZIP com os PDFs (Priority: P1) 🎯 MVP

**Goal**: Modal na lista, busca por protocolo ou número personalizado, ZIP com um PDF por manifestação (timbrado e JPG/PNG/PDF embutidos), igual ao PDF individual.

**Independent Test**: Três manifestações permitidas → confirmar → o ZIP contém três PDFs com o mesmo conteúdo do PDF individual (quickstart cenário 1, sem exigir índice nem progresso). A lista não ganha checkbox.

### Tests for User Story 1 ⚠️

- [x] T015 [P] [US1] Escrever teste RED em `ci-api-v2/src/modules/ouvidoria/test/use-cases/prepare-bulk-download.use-case.spec.ts` para o caminho feliz: 3 ids com acesso, duplicata conta uma, `assertForUser` é chamado para cada uma, resposta traz `sessionId`, `ticket`, `fileName`, `total` e `expiresAt` cerca de 60 s à frente, e nenhum byte de ZIP é produzido
- [x] T016 [P] [US1] Escrever teste RED em `ci-api-v2/src/modules/ouvidoria/test/use-cases/stream-bulk-download.use-case.spec.ts`: o ZIP (yazl) tem um PDF por id, na ordem pedida; o teto de 200 MB (`assertManifestacaoExportSizeWithinLimit`) não é chamado; sessão de outro usuário não abre stream
- [x] T017 [P] [US1] Escrever teste RED em `ci-api-v2/src/modules/ouvidoria/test/repository/search-manifestacoes-download.repository.spec.ts` e `ci-api-v2/src/modules/ouvidoria/test/use-cases/search-manifestacoes-download.use-case.spec.ts`: `tenantId` + `deletedAt: null`, `protocol` ou `numeroPersonalizado` contém `q`, no máximo 20, sem descrição e sem dados do solicitante
- [x] T018 [P] [US1] Escrever teste RED em `ci-client-v2/apps/web/src/modules/ouvidoria/__tests__/BulkDownloadDialog.test.tsx`: o botão abre o modal, a busca preenche chips removíveis, o contador mostra "N de 50", confirmar fica desabilitado com zero itens e também acima de 50, Esc fecha o modal, o foco inicial cai no campo de busca, chips e botões têm nome acessível, e a tabela da lista não renderiza checkbox por linha

### Implementation for User Story 1

- [x] T019 [US1] Extrair a montagem do PDF (render + merge de anexos embutíveis + timbrado) para `ci-api-v2/src/modules/ouvidoria/lib/build-manifestacao-pdf-buffer.ts`, com opção de não aplicar o teto de 200 MB. `GenerateManifestacaoPdfUseCase` em `ci-api-v2/src/modules/ouvidoria/use-cases/generate-manifestacao-pdf.use-case.ts` continua aplicando o teto. Os testes já existentes desse use case permanecem verdes
- [x] T020 [US1] Implementar `SearchManifestacoesDownloadRepository` em `ci-api-v2/src/modules/ouvidoria/repository/search-manifestacoes-download.repository.ts` e `SearchManifestacoesDownloadUseCase` em `ci-api-v2/src/modules/ouvidoria/use-cases/search-manifestacoes-download.use-case.ts` até T017 passar
- [x] T021 [US1] Implementar `PrepareBulkDownloadUseCase` em `ci-api-v2/src/modules/ouvidoria/use-cases/prepare-bulk-download.use-case.ts` só com o caminho feliz de T015 (dedupe, carga via T012, `assertForUser` em todas, cria sessão). Recusas ficam para a US4
- [x] T022 [US1] Implementar `StreamBulkDownloadUseCase` em `ci-api-v2/src/modules/ouvidoria/use-cases/stream-bulk-download.use-case.ts`: gera um PDF por vez com T019, acrescenta ao `yazl` e finaliza. Libera o buffer antes da próxima. Até T016 passar
- [x] T023 [US1] Registrar repositories e use cases novos em `ci-api-v2/src/modules/ouvidoria/ouvidoria.module.ts`. Em `ci-api-v2/src/modules/ouvidoria/ouvidoria.controller.ts` expor `GET manifestacoes/busca-download`, `POST manifestacoes/documento/massa` e `GET manifestacoes/documento/massa/:sessionId/arquivo` (Bearer do dono), todos com `@RequireModulo('ouvidoria')`. O GET de arquivo responde `application/zip` sem `Content-Length`, `Cache-Control: no-store` e `Referrer-Policy: no-referrer`
- [x] T024 [US1] Criar `ci-client-v2/apps/web/src/modules/ouvidoria/api/bulk-download.ts` (preflight + download com Bearer) e `ci-client-v2/apps/web/src/modules/ouvidoria/components/BulkDownloadDialog.tsx` (contador "N de 50", foco no campo de busca, Esc fecha, nomes acessíveis, paleta já usada na lista). Ligar o botão "Baixar em massa" em `ci-client-v2/apps/web/src/modules/ouvidoria/pages/ManifestacoesListPage.tsx` sem checkbox na tabela, até T018 passar

**Checkpoint**: Três manifestações permitidas geram um ZIP com três PDFs. Sem progresso, sem cache, sem recusa rica

---

## Phase 4: User Story 4 — Recusar o lote inteiro (Priority: P1)

**Goal**: Qualquer manifestação sem acesso, inexistente, acima de 50 ou acima de ~300 MB (antes ~1 GB; ver Phase 10) recusa o lote antes do primeiro byte, com a lista dos ids que o próprio usuário enviou.

**Independent Test**: quickstart cenário 3 — 403, 404, 422 de quantidade, 422 de volume, 409 da segunda aba. Nenhum arquivo é baixado. O modal mantém a seleção.

### Tests for User Story 4 ⚠️

- [x] T025 [P] [US4] Estender `ci-api-v2/src/modules/ouvidoria/test/use-cases/prepare-bulk-download.use-case.spec.ts` com RED: um id sem acesso → 403 `LOTE_ACESSO_NEGADO` e `semAcesso`, zero sessão; id de outro tenant → 404 `LOTE_NAO_ENCONTRADA` e `naoEncontradas` sem outro campo da manifestação; 51 ids → 422 `LOTE_LIMITE_QUANTIDADE`; soma de `sizeBytes` acima de 1 073 741 824 → 422 `LOTE_LIMITE_VOLUME`; `sizeBytes` nulo e `headContentLength` ausente → 422 `LOTE_TAMANHO_DESCONHECIDO`; segunda sessão do usuário → 409; duas transmissões já no processo → 429 `LOTE_SERVIDOR_OCUPADO`. Erro lançado por `assertForUser` recusa o lote (fail-closed), não segue
- [x] T026 [P] [US4] Estender `ci-client-v2/apps/web/src/modules/ouvidoria/__tests__/BulkDownloadDialog.test.tsx` com RED: resposta 403 mostra a mensagem e os protocolos dos chips citados, a seleção não é limpa, e nada dispara o download

### Implementation for User Story 4

- [x] T027 [US4] Completar os ramos de recusa em `ci-api-v2/src/modules/ouvidoria/use-cases/prepare-bulk-download.use-case.ts` na ordem do contrato (forma → quantidade → carga no tenant → 404 ou 403 → volume com `headContentLength` quando `sizeBytes` for nulo → concorrência). Nenhum ramo abre stream. Até T025 passar
- [x] T028 [US4] Aplicar `@Throttle` de 5/min no POST em `ci-api-v2/src/modules/ouvidoria/ouvidoria.controller.ts` e mostrar o erro no modal em `ci-client-v2/apps/web/src/modules/ouvidoria/components/BulkDownloadDialog.tsx` até T026 passar

**Checkpoint**: Lote misto ou grande não gera arquivo. US1 continua passando

---

## Phase 5: User Story 2 — Stream, progresso e cancelar (Priority: P1)

**Goal**: O download começa em segundos, mostra "N de total", sobrevive à navegação e cancela no servidor quando o usuário cancela ou a conexão cai.

**Independent Test**: quickstart cenários 4 e 5 — primeiro byte antes do PDF ficar pronto, cancelar para a leitura, indicador ao trocar de rota, fallback sem `showSaveFilePicker` usa o ticket e o segundo GET falha.

### Tests for User Story 2 ⚠️

- [x] T029 [P] [US2] Estender `ci-api-v2/src/modules/ouvidoria/test/use-cases/stream-bulk-download.use-case.spec.ts` com RED: `lote.txt` (protocolos/números, um por linha) é escrito antes de `buildManifestacaoPdfBuffer` ser chamado; `abort` no meio não chama `yazl.end()`; contadores `concluidas` e `bytesEnviados` sobem a cada manifestação
- [x] T030 [P] [US2] Escrever teste RED em `ci-api-v2/src/modules/ouvidoria/test/use-cases/bulk-download-progress-cancel.spec.ts`: progresso só com Bearer do dono (ticket não autoriza; alheio → 404); cancelar dispara abort e é idempotente; segundo GET do arquivo → 409; sessão `preparada` após 60 s → 410 `LOTE_EXPIRADO`; GET com ticket certo e sem Bearer abre o stream uma vez
- [x] T031 [P] [US2] Escrever teste RED em `ci-client-v2/apps/web/src/modules/ouvidoria/__tests__/BulkDownloadIndicator.test.tsx`: com `showSaveFilePicker` o corpo é gravado por stream (não `Blob` do ZIP inteiro) e Cancelar aborta; sem a API o href leva `ticket` e o texto avisa que o progresso detalhado não está disponível; desmontar o modal não aborta; falha fatal na geração mostra frase de falha na geração; armazenamento indisponível no lote mostra outra frase, distinta da de acesso negado

### Implementation for User Story 2

- [x] T032 [US2] Em `ci-api-v2/src/modules/ouvidoria/use-cases/stream-bulk-download.use-case.ts`, gravar `lote.txt` primeiro, atualizar a sessão a cada manifestação e, no abort, destruir a saída sem `end()`. Até T029 passar
- [x] T033 [US2] Implementar `GetBulkDownloadProgressUseCase` e `CancelBulkDownloadUseCase` em `ci-api-v2/src/modules/ouvidoria/use-cases/get-bulk-download-progress.use-case.ts` e `ci-api-v2/src/modules/ouvidoria/use-cases/cancel-bulk-download.use-case.ts`. No GET de arquivo, aceitar Bearer do dono ou `ticket` (uso único, 410 se expirado). Rotas `GET .../progresso` e `POST .../cancelar` em `ci-api-v2/src/modules/ouvidoria/ouvidoria.controller.ts`, mais o `close` do socket ligando o abort. Até T030 passar
- [x] T034 [US2] Criar `ci-client-v2/apps/web/src/modules/ouvidoria/components/BulkDownloadProvider.tsx` e `BulkDownloadIndicator.tsx`. Montar o provider em `ci-client-v2/apps/web/src/App.tsx` dentro de `AuthProvider`, por fora do `RouterProvider`, para sobreviver à troca de rota. Poll ~1 s só enquanto `transmitindo`. Frases distintas para falha na geração e para armazenamento indisponível, em português. Até T031 passar

**Checkpoint**: Cancelar e navegar se comportam como a spec. O ZIP de US1 ainda fecha com os PDFs

---

## Phase 6: User Story 3 — Reaproveitar PDF por 24 h (Priority: P2)

**Goal**: Segunda geração da mesma manifestação não renderiza de novo, e qualquer mudança (inclusive anexo excluído) invalida o arquivo guardado. O carimbo "Documento gerado em" continua o da geração original.

**Independent Test**: quickstart cenário 2 — o segundo lote marca reaproveitado no fluxo de cache; depois de mudar a manifestação, aquela peça é gerada de novo. Acesso negado não lê o objeto.

### Tests for User Story 3 ⚠️

- [x] T035 [P] [US3] Estender `ci-api-v2/src/modules/ouvidoria/test/use-cases/stream-bulk-download.use-case.spec.ts` com RED: hit com `generatedAt` < 24 h usa `getObjectStream` e não chama `buildManifestacaoPdfBuffer`; esse hit segue valendo até o fim daquela manifestação no lote mesmo se as 24 h completarem no meio; miss gera, chama `putObject` na chave `buildStorageKey(tenantId, 'ouvidoria', 'pdf-cache', id, revision + '.pdf')`, apaga as outras revisões do mesmo prefixo e segue o ZIP mesmo se `putObject` ou o apagar falharem; objeto com mais de 24 h é apagado e tratado como miss; `assertForUser` falhando não chama storage de cache

### Implementation for User Story 3

- [x] T036 [US3] Incluir leitura e gravação do cache em `ci-api-v2/src/modules/ouvidoria/use-cases/stream-bulk-download.use-case.ts` usando `manifestacaoPdfRevision` e a metadata `generatedAt`. Chave só via `buildStorageKey`. Ao passar de 24 h, apagar o objeto e gerar de novo. Depois de gravar a revisão nova, apagar as outras chaves do prefixo `ouvidoria/pdf-cache/{manifestacaoId}/` (método novo em `ci-api-v2/src/modules/shared/storage/storage.service.ts`, com `validateTenantPath`; falha ao apagar só gera log). Contar `cacheHits` na sessão. Até T035 passar

**Checkpoint**: Repetir o lote não renderiza PDF de manifestação estável. US1 e US2 seguem verdes

---

## Phase 7: User Story 5 — Originais não embutíveis e índice (Priority: P2)

**Goal**: Word, Excel, TXT, MP3 e MP4 vão no ZIP como arquivo original; o PDF lista "Anexos não embutidos"; falha de um anexo aparece no índice; erro fatal não entrega ZIP íntegro.

**Independent Test**: quickstart cenários 1 (originais + índice) e 4 (anexo ausente conclui; erro fatal não finaliza o ZIP).

### Tests for User Story 5 ⚠️

- [x] T037 [P] [US5] Estender `ci-api-v2/src/modules/ouvidoria/lib/render-manifestacao-pdf.spec.ts` e `ci-api-v2/src/modules/ouvidoria/lib/render-manifestacao-pdf-ageman.spec.ts` com RED: anexo docx/xlsx/txt/mp3/mp4 aparece como "Anexos não embutidos" (nome e tamanho) e não é embutido; link externo continua só referência
- [x] T038 [P] [US5] Estender `ci-api-v2/src/modules/ouvidoria/test/use-cases/stream-bulk-download.use-case.spec.ts` com RED: original não embutível sai em `{slug}/anexos/{nome}` via `getObjectStream` (não `getObjectBuffer`); nome `../` não sai da pasta; PDF ou imagem cujos bytes foram lidos mas não embutiram também entram em `anexos/` e em `indisponiveis` com motivo `pdf-invalido`; anexo que o armazenamento não devolve não cria entrada e entra em `indisponiveis` com motivo `armazenamento`; `indice-do-lote.pdf` é a última entrada e só existe se `end()` rodou; erro fatal na renderização não chama `end()`

### Implementation for User Story 5

- [x] T039 [US5] Listar anexos não embutíveis em `ci-api-v2/src/modules/ouvidoria/lib/render-manifestacao-pdf.ts` e `ci-api-v2/src/modules/ouvidoria/lib/render-manifestacao-pdf-ageman.ts` (a mesma lista nos dois, para o PDF individual e o do lote coincidirem). Até T037 passar. Subir `PDF_RENDER_REVISION` em `ci-api-v2/src/modules/ouvidoria/ouvidoria-bulk-download.constants.ts`
- [x] T040 [US5] Em `ci-api-v2/src/modules/ouvidoria/use-cases/stream-bulk-download.use-case.ts`, acrescentar os originais sanitizados e, no fim, `indice-do-lote.pdf` gerado por `ci-api-v2/src/modules/ouvidoria/lib/render-lote-indice-pdf.ts` (autor, data/hora do download, gerado agora ou reaproveitado com o instante do carimbo, indisponíveis com motivo `armazenamento` ou `pdf-invalido`). Erro fatal destrói o stream sem `end()`. Até T038 passar

**Checkpoint**: ZIP completo tem `lote.txt`, pastas, originais e índice. ZIP de falha fatal não abre

---

## Phase 8: User Story 6 — Auditoria do lote (Priority: P3)

**Goal**: Todo desfecho (recusado, concluído, cancelado, falho) fica no `AuditLog`, com autor certo quando não há linha em `User`, sem ticket e sem conteúdo.

**Independent Test**: Cada desfecho do quickstart gera uma linha `ouvidoria.manifestacao.bulk_download`. `admin_tenant` grava `actorId`/`actorRole` e `userId` nulo. O ticket não aparece no payload nem no log HTTP.

### Tests for User Story 6 ⚠️

- [x] T041 [P] [US6] Escrever teste RED em `ci-api-v2/src/modules/ouvidoria/test/use-cases/bulk-download-audit.spec.ts`: recusa no preflight, conclusão, cancelamento e falha chamam `CreateAuditLogRepository` com `action` `ouvidoria.manifestacao.bulk_download`, `entity` `Manifestacao`, `entityId` nulo; `userId` vem de `resolveUserTableId`; papel `admin_tenant` leva `withActorPayload` (`actorId`, `actorRole`) e `userId` nulo; payload não tem ticket, `storageKey` nem bytes de PDF
- [x] T042 [P] [US6] Escrever teste RED em `ci-api-v2/src/infrastructure/config/http-logger-options.spec.ts`: as opções de redact incluem a query `ticket`

### Implementation for User Story 6

- [x] T043 [US6] Gravar o audit nos desfechos de `ci-api-v2/src/modules/ouvidoria/use-cases/prepare-bulk-download.use-case.ts` e `ci-api-v2/src/modules/ouvidoria/use-cases/stream-bulk-download.use-case.ts` até T041 passar. Log Pino `bulk_download.refused|started|completed|failed` com ids, ator e papel, sem ticket e sem conteúdo
- [x] T044 [US6] Criar `httpLoggerOptions` em `ci-api-v2/src/infrastructure/config/http-logger-options.ts` redigindo `req.query.ticket` e usar em `ci-api-v2/src/main.ts` no `FastifyAdapter` (dev e produção) até T042 passar

**Checkpoint**: Os quatro desfechos deixam rastro consultável. Nenhum teste anterior quebrou

---

## Phase 9: Polish & Cross-Cutting Concerns

**Purpose**: Fechar a verificação do quickstart e a regressão do PDF individual

- [x] T045 Rodar `npm test -- --testPathPatterns=bulk-download` em `ci-api-v2/` e `npm test -- BulkDownload` em `ci-client-v2/apps/web/` (Vitest filtra pelo nome do arquivo), mais os testes já existentes de `generate-manifestacao-pdf` e `render-manifestacao-pdf`. Corrigir regressão sem alargar escopo
- [ ] T046 [P] Conferir no código os testes mínimos de `civ2-docs/specs/054-download-massa-manifestacoes/security.md` (outro tenant, acesso 047, sessionId alheio, ticket repetido, zip slip, cache com acesso negado, log sem ticket) e o cenário manual 1 de `civ2-docs/specs/054-download-massa-manifestacoes/quickstart.md` quando a API de dev estiver no ar. Lifecycle de 48 h no prefixo `ouvidoria/pdf-cache/` fica como rede de segurança de operação, não como migration: a app já apaga expirado e revisão substituída (T036)

---

## Phase 10: Correção 2026-10-09 — PDF único (substitui o formato ZIP por manifestação)

**Purpose**: Entregar **um único PDF** (separador + dossiê por manifestação + página-resumo final); ZIP só quando há anexos que não cabem em PDF; download nativo para todos; teto 300 MiB. Substitui os formatos de T016–T018/T031–T040 onde conflitarem (ZIP por manifestação, `indice-do-lote.pdf`, `lote.txt`, `showSaveFilePicker`).

**API (`ci-api-v2/src/modules/ouvidoria/`)**

- [x] T047 [P] RED→GREEN `lib/lote-pdf-text.ts` (+ spec): `LotePdfWriter` (wrap e paginação), `winAnsiSafeText`
- [x] T048 [P] RED→GREEN `lib/assemble-lote-pdf.ts` (+ spec): separador de página inteira + dossiê + página-resumo final; dossiê ilegível = erro fatal; abort
- [x] T049 [P] RED→GREEN `lib/lote-deliverable.ts` (+ spec): sem originais = PDF; com originais = ZIP (`yazl` `addFile`)
- [x] T050 RED→GREEN `lib/compose-manifestacao-export-anexos.ts` e `build-manifestacao-pdf-buffer.ts`: callback de pendências (`armazenamento`/`pdf-invalido`); imagem embutida antes de `addPage`
- [x] T051 RED→GREEN `ouvidoria-bulk-download.constants.ts` + `prepare-bulk-download.use-case.ts`: teto 300 MiB; `fileName` sem extensão
- [x] T052 RED→GREEN `use-cases/stream-bulk-download.use-case.ts`: build em diretório temporário, cache com sidecar `.report.json`, exclusão das revisões antigas antes do `putObject`, `dispose()`, cabeçalhos por tipo (`pdf` com `Content-Length`; `zip` sem), auditoria concluído/cancelado/falho
- [x] T053 Remover `lib/render-lote-indice-pdf.ts` (+ spec). `winAnsiSafeText` vive em `lote-pdf-text.ts`

**Client (`ci-client-v2/apps/web/src/modules/ouvidoria/`)**

- [x] T054 RED→GREEN `__tests__/BulkDownloadIndicator.test.tsx`: sempre download nativo (sem seletor/fetch do corpo), "N de total" + Cancelar, concluída pelo servidor, falhas distintas, poll limitado
- [x] T055 `api/bulk-download.ts`: remover `showSaveFilePicker`/`streamBulkDownloadToFile`/`waitForBulkDownloadTerminalProgress`/`resolveBulkDownloadStreamError`; `triggerNativeBulkDownload(sessionId, ticket)` com `download=''`; poll até ~10 min
- [x] T056 `BulkDownloadProvider.tsx` / `BulkDownloadIndicator.tsx` / `bulk-download-context.ts`: remover `mode`, `nativeHint`, link "Baixar arquivo ZIP"; aviso de montagem no servidor
- [x] T057 `BulkDownloadDialog.tsx` e `lib/bulk-download-messages.ts`: texto do PDF único (+ ZIP quando há anexos fora do PDF); "cerca de 300 MB"
- [x] T058 `e2e/specs/054-bulk-download-massa.e2e.spec.ts`: espera o evento `download` (`.pdf` ou `.zip`)

**Docs / validação**

- [x] T059 Atualizar spec/plan/research (addendum)/data-model/contract/quickstart/security/checklist
- [ ] T060 Validação manual do quickstart 1 e 5 com API e SPA no ar (PDF único; ZIP com Word/Excel; cancelar durante a montagem; proxy com timeout ≥ 10 min)

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: começa imediato
- **Foundational (Phase 2)**: depende da Phase 1 e bloqueia todas as histórias
- **US1 (Phase 3)**: depende da Phase 2. Primeira entrega utilizável
- **US4 (Phase 4)**: depende da US1 (`PrepareBulkDownloadUseCase` e o modal)
- **US2 (Phase 5)**: depende da US1 e da US4 (os dois editam `ouvidoria.controller.ts`; US4 vai antes)
- **US3 (Phase 6)**: depende da US2 (o stream já aborta e conta progresso)
- **US5 (Phase 7)**: depende da US3 (o mesmo `stream-bulk-download.use-case.ts`)
- **US6 (Phase 8)**: depende de US4 e US5, para cobrir recusa, sucesso, cancelamento e falha
- **Polish (Phase 9)**: depende das histórias desejadas

### User Story Dependencies

- **US1 (P1)**: só a fundação. Não depende das outras
- **US4 (P1)**: estende o preflight da US1. Testável sem progresso e sem cache
- **US2 (P1)**: estende o stream da US1. Não depende de cache nem de índice
- **US3 (P2)**: só o caminho de cache no stream. O carimbo "gerado em" não é reescrito
- **US5 (P2)**: originais e índice em cima do stream. Sobe `PDF_RENDER_REVISION`
- **US6 (P3)**: audit nos use cases já existentes. Não muda o ZIP

### Within Each User Story

- Teste RED antes do código que o faz passar
- Repository antes do use case, use case antes da rota, rota antes do client que a chama
- História verde antes da próxima

### Parallel Opportunities

- Phase 1: T002 em paralelo com T001
- Phase 2: T003, T005, T007, T009, T011, T013 e T014 juntos; cada implementação espera só o seu teste
- US1: T015, T016, T017 e T018 juntos
- US4 e US2 **não** em paralelo: ambos alteram `ouvidoria.controller.ts`
- US3, US5 e US6 **não** em paralelo: US3 e US5 alteram `stream-bulk-download.use-case.ts`; US6 altera prepare e stream

---

## Parallel Example: User Story 1

```text
# Testes RED juntos, arquivos diferentes:
T015 prepare-bulk-download.use-case.spec.ts
T016 stream-bulk-download.use-case.spec.ts
T017 search-manifestacoes-download.repository.spec.ts
T018 BulkDownloadDialog.test.tsx

# Depois, em ordem:
T019 build-manifestacao-pdf-buffer.ts
T020 search use case
T021 prepare use case
T022 stream use case
T023 controller
T024 dialog + lista
```

---

## Implementation Strategy

### MVP First (User Story 1 + recusa da US4)

1. Phase 1 e Phase 2
2. Phase 3 (US1) — ZIP feliz com três PDFs
3. Phase 4 (US4) — sem isto o botão extrai lote sem barrar acesso nem tamanho
4. Parar e validar os cenários 1 e 3 do quickstart
5. Só então progresso (US2), cache (US3), originais/índice (US5) e audit (US6)

US1 sozinha demonstra o download, mas não deve ir a usuário real sem a US4.

### Incremental Delivery

1. Fundação → US1 → US4 (lote seguro, ainda sem barra de progresso rica)
2. US2 → cancelar e navegação
3. US3 → segundo download mais rápido
4. US5 → dossiê completo (originais + índice)
5. US6 → rastro de auditoria
6. Phase 9

### Parallel Team Strategy

Não dividir US2/US3/US5/US6 entre pessoas ao mesmo tempo: o arquivo `stream-bulk-download.use-case.ts` é compartilhado. Dá para paralelizar só os testes RED de arquivos distintos dentro da fase corrente.

---

## Notes

- [P] = outro arquivo, sem depender de tarefa incompleta
- Sessão e ticket não vão para o banco; não criar migration
- `admin_tenant` / `admin_saas`: `resolveUserTableId` + `withActorPayload` (tarefa T043)
- Falha ao gravar cache não falha o download; falha de acesso não lê cache
- Commit ao fechar cada história, não no meio de um RED
