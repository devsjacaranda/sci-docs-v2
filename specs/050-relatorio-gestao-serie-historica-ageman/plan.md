# Implementation Plan: Série histórica mês×ano — Relatório de Gestão

**Branch**: `050-relatorio-gestao-serie-historica-ageman` | **Date**: 2026-09-24 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `civ2-docs/specs/050-relatorio-gestao-serie-historica-ageman/spec.md`

## Summary

Fechar o **gap 4** (orquestrador AGEMAN): expor grades estilo planilha **RESUMO GERAL DEMAND.** / **MENSAL_DEMAND._GRAF.** — principalmente **12 meses × colunas por ano (2018–ano corrente)** com total acumulado por mês e percentual — via **endpoint dedicado** lazy-loaded na UI, sem mudar o contrato do relatório por período (042/049). MVP = grade de **atendimentos**; P2 = **resolutividade anual** e **concessão anual** + export Excel; **forma de atendimento** mês×canal×ano fica fora (research.md §4). Performance: agregação SQL on-demand, índices se necessário, **sem cache persistente** (FR-013).

## Technical Context

**Language/Version**: TypeScript — NestJS 11 (API) / React 19 (client)

**Primary Dependencies**: NestJS, Fastify, Zod, Prisma 7, PostgreSQL · React, Vite 8, shadcn/ui, Tailwind v4 · `exceljs` (export) — já no módulo ouvidoria

**Storage**: PostgreSQL — **nenhuma** tabela nova; leitura de `Manifestacao` (+ joins existentes para resolutividade/concessão)

**Testing**: Jest — repositories `$queryRaw` / Prisma aggregate (padrão 042); Vitest — mappers grade + página aba histórica

**Target Platform**: Web SPA `ci-client-v2/apps/web`

**Performance Goals**: `GET .../serie-historica` p95 ≤ 5s (SC-003); Excel ≤ 30s; GET relatório por período inalterado ≤ 5s (SC-002)

**Constraints**: FR-013 — sem cache/pré-cálculo; FR-005 — não alterar response do GET principal; exports wide só na rota histórica

**Scale/Scope**: Multi-tenant; referência AGEMAN ~5,3k manifestações, ~9 colunas de ano no MVP

## Constitution Check

| Princípio | Avaliação | Status |
|-----------|-----------|--------|
| I. Spec-Driven | Spec 050 Draft + research + contrato antes de implement | ✅ PASS |
| II. Test-First | Repositories agregados com testes RED antes do use-case | ✅ PASS (a garantir em implement) |
| III. Stack fixa | Sem libs novas | ✅ PASS |
| IV. Multi-tenant | `tenantId` via ALS; `@RequireModulo('ouvidoria')` | ✅ PASS |
| V. Modularidade | 1 repository por grade; use-case fino; UI colocated em `modules/ouvidoria/` | ✅ PASS |

## Project Structure

### Documentation (this feature)

```text
civ2-docs/specs/050-relatorio-gestao-serie-historica-ageman/
├── spec.md
├── plan.md
├── research.md
├── contracts/
│   └── serie-historica-relatorio-gestao.md
└── tasks.md
```

### Source Code (repository root)

```text
ci-api-v2/src/modules/ouvidoria/
├── ouvidoria.schemas.ts                    # + serieHistoricaQuerySchema
├── ouvidoria.controller.ts                 # + GET serie-historica, GET serie-historica/excel
├── use-cases/
│   └── get-relatorio-gestao-serie-historica.use-case.ts
├── repository/
│   ├── get-serie-historica-atendimentos.repository.ts      # MVP
│   ├── get-serie-historica-resolutividade-anual.repository.ts   # P2
│   └── get-serie-historica-concessao-anual.repository.ts        # P2
├── lib/
│   └── build-grade-mes-ano.ts              # pure: preenche 12×N, totais, %
└── test/repository/                          # specs RED

ci-client-v2/apps/web/src/modules/ouvidoria/
├── pages/RelatorioGestaoPage.tsx             # aba ou rota filha "Série histórica"
├── components/relatorio-gestao/
│   ├── SerieHistoricaAtendimentosTable.tsx
│   ├── SerieHistoricaResolutividadeTable.tsx   # P2
│   └── SerieHistoricaConcessaoTable.tsx        # P2
├── hooks/useRelatorioGestaoSerieHistorica.ts
└── lib/relatorio-gestao-serie-historica-mappers.ts
```

## Design Notes

### Orquestração API

- Novo use-case **não** estende `get-relatorio-gestao.use-case.ts` por padrão (evita merge conflict com 049); pode compartilhar helpers de classificação de resolutividade importados de `lib/` existente.
- Response única JSON com chaves opcionais progressivas: MVP só popula `atendimentosMesAno`; P2 adiciona `resolutividadeAnual`, `concessaoAnual`.

### UI

- Aba **“Série histórica”** na página do relatório de gestão; fetch ao montar aba (React Query `enabled: abaAtiva`).
- Tabela horizontal scroll + primeira coluna sticky (mês); linha TOTAL em `TableFooter`.
- Percentual: exibir como `%` com 2 casas (planilha usa fração interna).

### Excel

- Cabeçalho linha 1: anos; coluna A: nomes dos meses; últimas colunas: Total acumulado, % — espelho visual da planilha, sem fórmulas.

## MVP Scope Recap (produto)

| Bloco planilha | Entrega 050 | Formato |
|----------------|-------------|---------|
| ATENDIMENTOS POR MÊS (RESUMO / MENSAL_DEMAND) | **MVP P1** | mês × ano + acum. + % |
| DEMANDAS E RESOLUTIVIDADE (totais anuais) | **P2** | métrica × ano + acum. + % |
| TIPO DE CONCESSÃO (totais anuais) | **P2** | concessão × ano + acum. + % |
| FORMAS_ATENDIMENTO (mês × canal × ano) | **Fora MVP** | spec futura |
| QUANT_MENSAL resolutividade mês a mês | **P3** | fora MVP |
| Pesquisa satisfação / eventos / orientações | **Outras specs** | — |

## Complexity Tracking

Nenhuma violação de constitution — tabela omitida.
