# Implementation Plan: Relatório de Gestão — Tipo de concessão (AGEMAN gap 3)

**Branch**: `050-relatorio-gestao-tipo-concessao-ageman` | **Date**: 2026-09-24 | **Spec**: [spec.md](./spec.md)

**Input**: ORQUESTRADOR gap 3 — corrigir bloco `porTipoManifestacao` para agregação por concessão (programa), alinhado à planilha RESUMO GERAL + aba 7 e ao DOCX AGEMAN.

## Summary

Trocar a query do bloco `porTipoManifestacao` de `GROUP BY Manifestacao.type` para `GROUP BY mês + tipo de concessão`, reutilizando o mapa SQL de `porMotivo` (`dashboard.repositories.ts`). Atualizar copy UI e exports (PDF/Excel) para **"Tipo de concessão"**. Estender contrato JSON com `tipoConcessao` mantendo `type` espelhado e chave/bloco `porTipoManifestacao` inalterados. Sem migration; escopo limitado ao módulo `ouvidoria` (API + `@ci/web`).

## Technical Context

**Language/Version**: TypeScript — NestJS 11 (API), React 19 (client)

**Primary Dependencies**: Prisma `$queryRaw`, Zod (`nestjs-zod`), PDFKit, ExcelJS — já em uso na spec 042/049

**Storage**: PostgreSQL — apenas leitura em `Manifestacao.programa`, `Manifestacao.serviceMode`, `Manifestacao.createdAt`

**Testing**: Jest — `test/repository/get-relatorio-gestao-tipo-manifestacao.repository.spec.ts`, `get-relatorio-gestao.use-case.spec.ts`, PDF/Excel section specs; Vitest — `relatorio-gestao-mappers.test.ts`, `TipoManifestacaoChartCard.test.tsx`

**Target Platform**: Web SPA + REST

**Performance Goals**: Idênticos à 042 (≤ 5s / ≤ 30s)

**Constraints**: FR-006 DRY do CASE `programa`; paridade numérica com rollup `porMotivo`

**Scale/Scope**: 1 repository alterado + 1 lib SQL nova + tipos/schemas + 2 export paths + 1 card React + mappers

## Constitution Check

| Princípio | Avaliação | Status |
|-----------|-----------|--------|
| I. Spec-Driven | Spec 050 Draft antes de implement | ✅ PASS |
| II. Test-First | Repository + use-case + mapper RED→GREEN | ✅ PASS (tasks) |
| III. Stack fixa | Sem deps novas | ✅ PASS |
| IV. Multi-tenant | `tenantId` via context; `@RequireModulo('ouvidoria')` inalterado | ✅ PASS |
| V. Modularidade | Fragmento SQL em `lib/`; repository único | ✅ PASS |

## Project Structure

### Documentation (this feature)

```text
civ2-docs/specs/050-relatorio-gestao-tipo-concessao-ageman/
├── spec.md
├── plan.md
├── research.md
├── contracts/
│   └── relatorio-gestao-tipo-concessao.md
└── tasks.md
```

### Source Code (repository root)

```text
ci-api-v2/src/modules/ouvidoria/
├── lib/
│   └── relatorio-gestao-programa-concessao.sql.ts   # NOVO — CASE TRIM(programa) + fallback serviceMode
├── repository/
│   ├── dashboard.repositories.ts                    # ALTERA — usar fragmento em porMotivo
│   └── get-relatorio-gestao-tipo-manifestacao.repository.ts  # ALTERA — GROUP BY concessão
├── use-cases/
│   └── get-relatorio-gestao.use-case.ts             # ALTERA — normalizar null → Não informado; preencher type=tipoConcessao
├── ouvidoria.types.ts                               # ALTERA — tipoConcessao na linha
├── ouvidoria.schemas.ts                             # ALTERA — Zod relatorio gestao row
├── lib/
│   └── relatorio-gestao-pdf-sections.ts             # ALTERA — título + coluna
└── use-cases/
    └── export-relatorio-gestao-excel.use-case.ts    # ALTERA — nome aba + header

ci-client-v2/apps/web/src/modules/ouvidoria/
├── api/relatorio-gestao.ts                          # ALTERA — tipo TS
├── lib/relatorio-gestao-mappers.ts                  # ALTERA — mapTipoManifestacaoChart
├── components/dashboard/TipoManifestacaoChartCard.tsx  # ALTERA — copy (rename arquivo opcional)
└── __tests__/                                       # ALTERA — fixtures complaint → concessão
```

## Implementation Phases

1. **Lib SQL** — extrair CASE; teste unitário opcional do builder Prisma.sql
2. **Repository** — nova query; teste repository com fixtures `programa`/`serviceMode`
3. **Use-case + types + Zod** — shape `{ month, tipoConcessao, type, total }`; teste paridade com `porMotivo` mock
4. **Exports** — PDF title, Excel sheet "Tipo de concessão"
5. **Client** — card + mapper + tipos; remover TYPE_OPTIONS neste bloco

## Risks

| Risco | Mitigação |
|-------|-----------|
| Rótulos planilha ≠ API | Tabela equivalência em `research.md`; validação manual SC-001 |
| `type` deprecated confunde integradores | Documentar em contrato; espelhar valor |
| Divergência orientações vs dashboard fallback | Escopo 050 só dashboard map; follow-up unificar orientações |

## Post-merge

- Atualizar [042 contracts](../042-relatorio-gestao-ouvidoria/contracts/relatorio-gestao.md) com nota "supersedido por 050" no exemplo `porTipoManifestacao` (opcional na implementação ou doc-only).
- `/speckit-complete` após implement + quickstart manual contra planilha.
