# Implementation Plan: Registros em Planilha (Ouvidoria)

**Branch**: `055-registros-controle-demandas` | **Date**: 2026-10-09 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `civ2-docs/specs/055-registros-controle-demandas/spec.md`

## Summary

O modal "Baixar em massa" (spec 054) ganha um seletor de saída: **"Gerar manifestações"** (PDF/ZIP já existente, inalterado) e **"Gerar registros"** (nova). "Gerar registros" pede só um período — mês (ano + mês) ou ano — e devolve uma planilha `.xlsx` no formato do controle manual `Controle de Demandas 2026.xlsx`: uma aba por concessão, cabeçalho fixo de 25 colunas, uma linha por manifestação. Diferente do PDF, não há seleção manifestação a manifestação, o que torna esta via leve o bastante para um mês ou um ano inteiro: sem sessão, sem fila, sem montagem em memória por item — uma única requisição, leitura em lotes, resposta em `exceljs` (já usado em `export-relatorio-gestao-excel.use-case.ts`).

Abordagem:

1. **Rota síncrona, sem sessão.** `GET /ouvidoria/manifestacoes/registros/excel?ano=&mes=` valida o período, lê os dados em lotes por cursor e devolve o `.xlsx` como `StreamableFile`, no mesmo padrão de `relatorio-gestao/excel`.
2. **Leitura paginada por cursor** (não um único `findMany` do período inteiro): página de 500 linhas por vez, ordenada por `createdAt, id`, usando o índice `@@index([tenantId, createdAt])` já existente.
3. **Agrupamento por concessão em memória**, com `resolveProgramaCode` (já existe em `ageman-catalog.ts`). Uma aba por concessão com dados, na ordem da planilha de referência; "Sem concessão" só se houver dados.
4. **Construtor do workbook isolado e testável**: cabeçalho, estilos (Calibri 11, negrito, centralizado, borda fina) e larguras em constantes, replicando a planilha de referência. Fórmula de numeração igual (`=ROW(A1)`).
5. **Teto de linhas e throttle** antes de gerar qualquer conteúdo. Período sem nenhuma linha é recusado com mensagem clara, sem workbook vazio.
6. **Auditoria** no mesmo `AuditLog`, ação `ouvidoria.manifestacao.registros_export`, sem dado pessoal no payload.

## Technical Context

**Language/Version**: TypeScript — NestJS 11 + Fastify na API; React 19 + Vite 8 no client

**Primary Dependencies**: `exceljs` (já instalado, usado em `export-relatorio-gestao-excel.use-case.ts`), Zod, Prisma, `@ci/ui` (RadioGroup/Tabs, Input)

**Storage**: Só leitura do Postgres via Prisma; sem migration. Auditoria no `AuditLog` já existente.

**Testing**: Jest (API) e Vitest + Testing Library (client). TDD RED → GREEN → REFACTOR.

**Target Platform**: API REST multi-tenant + SPA `@ci/web`

**Project Type**: web-service + web-application (`ci-api-v2` / `ci-client-v2`)

**Performance Goals**: resposta de um ano inteiro sem bloquear o event loop por mais que a leitura de uma página de 500 linhas por vez (SC-006); planilha de um mês típico em poucos segundos.

**Constraints**: teto operacional de linhas por planilha (definido em `ouvidoria-registros-export.constants.ts`, inicialmente 20 000, ajustável sem código ao medir o uso real); sem seleção manifestação a manifestação; sem sessão nem fila (diferente do PDF da 054); fail-closed na autorização (mesma regra de acesso ao módulo da lista).

**Scale/Scope**: 1 rota nova no controller de Ouvidoria já existente; 1 repositório novo paginado; 1 caso de uso novo; 1 construtor de workbook novo; ajuste no modal existente da 054 (seletor de saída + painel de período).

## Constitution Check

*GATE: passa antes da pesquisa e após o design.*

| Princípio | Verificação | Status |
|---|---|---|
| I. Spec-Driven | specify → plan (este) → tasks → implement | PASS |
| II. Test-First | tasks.md lista o teste RED antes de cada implementação | PASS |
| III. Stack fixa | NestJS, Fastify, Zod, Prisma, React, Tailwind, shadcn via `@ci/ui`, `exceljs` já em uso — nenhuma dependência nova | PASS |
| IV. Multi-tenant | `tenantId` do contexto em todas as consultas; sem licença nova (`@RequireModulo('ouvidoria')`) | PASS |
| V. Clean code / modularidade | 1 arquivo = 1 operação (repositório, caso de uso, construtor de workbook); schemas em `ouvidoria.schemas.ts`; client em `modules/ouvidoria/` | PASS |
| Regra `admin-tenant-user-fk` | Audit `userId` via `resolveUserTableId`; `admin_tenant`/`admin_saas` só em `withActorPayload` | PASS |
| OWASP (`owasp-security`) | Sem dado pessoal na auditoria (A09); teto de linhas e throttle contra exaustão (A05); tenant sempre do contexto, nunca da query (A01) | PASS |

**Re-check pós-design (Phase 1)**: nenhuma migration, nenhuma fila, nenhuma dependência nova. Gate segue PASS.

## Project Structure

### Documentation (this feature)

```text
civ2-docs/specs/055-registros-controle-demandas/
├── plan.md
├── spec.md
├── contracts/
│   └── rest-api-registros-excel.md
├── checklists/requirements.md
└── tasks.md
```

### Source Code (repository root)

```text
ci-api-v2/src/modules/ouvidoria/
├── ouvidoria.controller.ts                           # +1 handler GET registros/excel
├── ouvidoria.schemas.ts                              # query ano/mes do export de registros
├── ouvidoria-registros-export.constants.ts           # teto de linhas, throttle, nome do arquivo
├── lib/
│   ├── registros-controle-demandas-workbook.ts       # construtor do workbook (cabeçalho/estilos/abas)
│   └── map-manifestacao-registro-row.ts              # 1 manifestação -> 1 linha de 25 colunas
├── repository/
│   └── list-manifestacoes-registros.repository.ts    # leitura paginada por cursor (createdAt, id)
├── use-cases/
│   └── export-registros-manifestacoes-excel.use-case.ts
└── test/                                             # espelho Jest por arquivo acima

ci-client-v2/apps/web/src/modules/ouvidoria/
├── components/BulkDownloadDialog.tsx                 # + seletor "manifestações" / "registros"
├── api/registros-export.ts                           # 1 requisição, blob, nome do Content-Disposition
├── lib/bulk-download-messages.ts                      # + mensagens de registros
└── __tests__/
```

**Structure Decision**: Tudo no módulo Ouvidoria já existente, sem módulo novo. O único ponto compartilhado com a spec 054 é o `BulkDownloadDialog.tsx` (seletor de saída) — o fluxo PDF/ZIP e seus arquivos (`BulkDownloadProvider`, `BulkDownloadIndicator`, sessão) não são tocados.

## Complexity Tracking

Nenhuma dependência nova e nenhuma exceção à stack fixa. Tabela vazia.
