# Implementation Plan: Download em Massa de Manifestações (Ouvidoria)

**Branch**: `054-download-massa-manifestacoes` | **Date**: 2026-10-08 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `civ2-docs/specs/054-download-massa-manifestacoes/spec.md`

## Summary

> **Revisão 2026-10-09 (correção de formato).** A primeira entrega (ZIP com 1 PDF por manifestação + `indice-do-lote.pdf` + `lote.txt`, streaming progressivo, seletor de local no Chromium) foi **substituída** pelo desenho abaixo, conforme a spec revisada. Onde [research.md](./research.md) ou outros documentos ainda descreverem o ZIP-stream, vale este plano e o "Addendum 2026-10-09" do research.

O usuário escolhe manifestações num modal (busca por protocolo ou número personalizado) e recebe **um único PDF**: para cada manifestação, uma página inteira de separação + o dossiê completo (o mesmo do detalhe, com timbrado e JPG/PNG/PDF embutidos), e no fim uma página-resumo do lote. Só os anexos que não cabem em PDF (Word, Excel, TXT, MP3, MP4…) ficam fora; quando existirem, a entrega vira um **ZIP** com o PDF único + os originais. O lote recusa por completo se alguma manifestação estiver fora do acesso da spec 047 ou se passar de 50 itens / ~300 MB.

Abordagem (detalhe em [research.md](./research.md), ameaças em [security.md](./security.md)):

1. **Preflight separado da entrega.** `POST` valida tudo e responde JSON (inclusive `fileName` **sem extensão**). Só então o `GET` monta e entrega. Recusa nunca viaja disfarçada de arquivo.
2. **Montagem por manifestação em arquivos temporários.** O `GET` cria um diretório temporário próprio; cada dossiê é gravado em arquivo (cache hit ou geração nova), os originais fora do PDF são copiados em stream para arquivos. `assembleLotePdf` (pdf-lib) junta separador + dossiê de cada manifestação e a página-resumo final. Temporários são removidos em `dispose()` (sucesso, falha ou cancelamento).
3. **Entrega decidida no fim.** `resolveLoteDeliverable`: sem originais → `application/pdf` (`createReadStream`, com `Content-Length`); com originais → `application/zip` via `yazl` `addFile` (PDF + originais). O servidor define `Content-Disposition` com `.pdf` ou `.zip`. O arquivo só começa a chegar **depois** da montagem completa.
4. **Cache no Wasabi do dossiê individual, chave = revisão do conteúdo, TTL 24 h**, mais um sidecar `{revision}.report.json` com as pendências de embutimento (indisponível / `pdf-invalido`). PDF sem sidecar conta como miss. Revisões anteriores são apagadas **antes** de gravar a nova.
5. **Cliente: download nativo para todos.** Sem `showSaveFilePicker`. O provider dispara o download nativo com ticket (60 s, uso único) e acompanha o progresso por polling (`N de total`, Cancelar → `POST …/cancelar`). Indicador em `App.tsx`: fechar o modal ou mudar de tela não cancela.
6. **Teto de volume 300 MiB** porque pdf-lib junta em memória (heap do Node em 3 GB via `NODE_OPTIONS`).

## Technical Context

**Language/Version**: TypeScript — NestJS 11 + Fastify na API; React 19 + Vite 8 no client

**Primary Dependencies**: `yazl` (ZIP condicional com `addFile` de arquivos temporários; versão travada no lockfile), `pdfkit` + `pdf-lib` (PDF individual e junção do PDF único), `@aws-sdk/client-s3` (métodos novos de stream e `HeadObject`), Zod, Prisma 7, `@ci/ui` (Dialog, Button, Combobox/Command)

**Storage**: PostgreSQL só via `AuditLog` já existente (sem migration). Wasabi para o PDF de cache no prefixo `ouvidoria/pdf-cache/`. Sessão do lote e ticket ficam na memória do processo

**Testing**: Jest (API) e Vitest + Testing Library (client). TDD RED → GREEN → REFACTOR. Casos em [quickstart.md](./quickstart.md)

**Target Platform**: API REST multi-tenant + SPA `@ci/web`

**Project Type**: web-service + web-application (`ci-api-v2` / `ci-client-v2`)

**Performance Goals**: indicador de progresso em até 2 s e entrega assim que a montagem termina (SC-002); segundo download do mesmo lote pelo menos 3× mais rápido (SC-004); memória do processo limitada pelo teto de 300 MiB de anexos (SC-003); dossiês individuais ficam em disco temporário

**Constraints**: 50 manifestações e 314 572 800 bytes (300 MiB) de anexos por lote; PDF único montado em memória por pdf-lib (heap 3 GB); arquivo só chega após a montagem completa; 1 transmissão por usuário; 2 transmissões no processo; abortar em até 5 s após cancelar (SC-008); fail-closed na autorização; sem `class-validator`; uma instância da API (não há store compartilhado de sessão)

**Scale/Scope**: 4 rotas novas + 1 busca, no controller de Ouvidoria já existente; cache e stream no storage compartilhado; modal na lista e o indicador montado em `App.tsx`

## Constitution Check

*GATE: passa antes da pesquisa e após o design.*

| Princípio | Verificação | Status |
|---|---|---|
| I. Spec-Driven | specify → clarify → plan (este) → tasks → implement → complete | PASS |
| II. Test-First | Quickstart e security.md listam os testes que nascem vermelhos; nenhum código de produção sem teste | PASS |
| III. Stack fixa | NestJS, Fastify, Zod, Prisma, React, Tailwind, shadcn via `@ci/ui`. `yazl` é biblioteca de ZIP, não troca de stack — ver Complexity Tracking | PASS |
| IV. Multi-tenant | `tenantId` no `where` dos repositories novos; chave de cache via `buildStorageKey`; sem licença nova (`@RequireModulo('ouvidoria')`) | PASS |
| V. Clean code / modularidade | 1 arquivo = 1 operação em repository e use-case; schemas continuam no `ouvidoria.schemas.ts`; client em `modules/ouvidoria/` + provider em `App.tsx` porque o indicador atravessa rotas | PASS |
| Regra `admin-tenant-user-fk` | Audit `userId` = `resolveUserTableId`; `admin_tenant` / `admin_saas` só em `withActorPayload` | PASS |
| OWASP (`owasp-security`) | [security.md](./security.md): A01, A05, A06, A09, A10 endereçados; ticket na URL e pico de um PDF são residuais aceitos (R-1, R-4) | PASS (com residuais) |

**Re-check pós-design (Phase 1)**: contratos, modelo e quickstart não introduzem migration, fila nem segunda base. Complexity Tracking permanece só com `yazl`. Gate segue PASS.

## Project Structure

### Documentation (this feature)

```text
civ2-docs/specs/054-download-massa-manifestacoes/
├── plan.md
├── research.md
├── data-model.md
├── security.md
├── quickstart.md
├── contracts/
│   └── rest-api-download-massa.md
├── checklists/requirements.md
└── tasks.md                          # /speckit-tasks — não criado aqui
```

### Source Code (repository root)

```text
ci-api-v2/src/modules/ouvidoria/
├── ouvidoria.controller.ts                         # +5 handlers
├── ouvidoria.schemas.ts                            # body do lote + query da busca
├── ouvidoria-bulk-download.constants.ts            # 50, 300 MiB, TTL, concorrência, PDF_RENDER_REVISION
├── lib/
│   ├── bulk-download-session.ts                    # mapa em memória + abort
│   ├── manifestacao-pdf-revision.ts                # fingerprint SHA-256
│   ├── sanitize-zip-entry-name.ts
│   ├── lote-pdf-text.ts                            # LotePdfWriter (texto com wrap/paginação)
│   ├── assemble-lote-pdf.ts                        # separador + dossiê + página-resumo (pdf-lib)
│   ├── lote-deliverable.ts                         # pdf puro ou zip (yazl addFile)
│   └── compose-manifestacao-export-anexos.ts       # lista "não embutidos"; lote não aplica o teto de 200 MB
├── repository/
│   ├── find-manifestacoes-for-bulk.repository.ts   # tenantId + deletedAt no where
│   └── search-manifestacoes-download.repository.ts
├── use-cases/
│   ├── prepare-bulk-download.use-case.ts
│   ├── stream-bulk-download.use-case.ts
│   ├── get-bulk-download-progress.use-case.ts
│   ├── cancel-bulk-download.use-case.ts
│   └── search-manifestacoes-download.use-case.ts
└── test/                                           # espelho Jest por arquivo acima

ci-api-v2/src/modules/shared/storage/storage.service.ts
    # + getObjectStream, + headContentLength (mesma validateTenantPath)

ci-client-v2/apps/web/src/modules/ouvidoria/
├── pages/ManifestacoesListPage.tsx                 # botão, sem checkbox
├── components/BulkDownloadDialog.tsx
├── components/BulkDownloadIndicator.tsx
├── api/bulk-download.ts
└── __tests__/

ci-client-v2/apps/web/src/App.tsx          # monta BulkDownloadProvider (sobrevive à navegação)
```

**Structure Decision**: Tudo no módulo Ouvidoria da API e do `@ci/web`, com dois encaixes fora dele — stream/HEAD no `StorageService` compartilhado (o PDF individual continua no buffer) e o provider em `App.tsx` (FR-019: o indicador existe em qualquer tela). Sem módulo novo, sem migration, sem app admin-saas.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|---|---|---|
| Dependência `yazl` | O ZIP (só quando há originais fora do PDF) é escrito a partir de arquivos temporários, sem carregar originais em RAM | `jszip`, já instalado, segura os originais na RAM e quebra FR-017. Escrever o formato ZIP na mão aumenta zip slip e pacote corrompido |

## Notas para `/speckit-tasks`

- Extrair a montagem do PDF (render + merge + timbrado) para os dois use cases chamarem, sem o assert de 200 MB no caminho do lote.
- O renderer passa a listar anexos não embutidos; isso altera o PDF individual de propósito (spec: os dois documentos ficam iguais).
- Não reutilizar `FindManifestacaoByIdRepository` no preflight (security F1).
- Não usar `getObjectBuffer` para originais nem para hit de cache (security F2).
- Subir `PDF_RENDER_REVISION` no mesmo PR que mudar layout ou timbrado.
