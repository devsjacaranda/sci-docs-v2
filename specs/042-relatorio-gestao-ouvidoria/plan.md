# Implementation Plan: Relatório de Gestão da Ouvidoria

**Branch**: `042-relatorio-gestao-ouvidoria` | **Date**: 2026-08-27 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `civ2-docs/specs/042-relatorio-gestao-ouvidoria/spec.md`

## Summary

Substituir o relatório de gestão que a AGEMAN hoje monta à mão numa planilha Excel por uma tela dentro do módulo Ouvidoria (genérica para qualquer tenant), consumindo dados reais do banco: demandas por mês, formas de atendimento, resolutividade, tipo de manifestação, reclamações por zona/bairro e pesquisa de satisfação — com export em PDF e Excel e uma tela de lançamento manual para satisfação. Abordagem técnica: reaproveitar 100% dos padrões já existentes no módulo (`$queryRaw` agregado por mês, PDFKit, ExcelJS, `@RequireModulo`, fetch manual no frontend) — nenhuma dependência nova, nenhuma tabela de cache, dois models Prisma novos (catálogo de perguntas + lançamentos mensais de satisfação, compartilhados com a spec 041 de migração histórica).

## Technical Context

**Language/Version**: TypeScript (Node.js ≥ 20) — NestJS 11 (API) / React 19 + TypeScript (client)

**Primary Dependencies**: NestJS 11, Fastify, Pino, Zod (`nestjs-zod`), Prisma 7 · React 19, Vite 8, Tailwind v4, shadcn/ui, `@nivo/bar`. Reaproveitadas sem nova instalação: `exceljs` ^4.4.0 (export Excel), `pdfkit` ^0.19.1 (export PDF).

**Storage**: PostgreSQL via Prisma 7 (Neon gerenciado em produção). Duas tabelas novas (ver `data-model.md`); nenhuma alteração em `Manifestacao`/`Address`.

**Testing**: Jest (ci-api-v2) — TDD com mock de repository nos use-cases, seguindo `test/use-cases/*.spec.ts`. Vitest (ci-client-v2) — component/mapper/contract em `__tests__/`.

**Target Platform**: Web — API REST (Fastify) + SPA (Vite build, `apps/web`).

**Project Type**: Web application (monorepo: backend `ci-api-v2` + frontend `ci-client-v2`, domínio `ouvidoria` espelhado nos dois).

**Performance Goals**: Tela do relatório abre em ≤ 5s; exports (PDF/Excel) completam em ≤ 30s — mesmo no filtro "acumulado geral" (maior volume possível por tenant) (SC-005).

**Constraints**: Sem tabelas de cache/pré-cálculo persistentes como padrão (FR-013); sem replicar a estrutura larga/desnormalizada da planilha original (nenhuma tabela nova além das duas de satisfação); sem nova dependência de biblioteca (research.md §"Resumo de dependências"); relatório sempre recalculado on-demand, sem snapshot (FR-003).

**Scale/Scope**: Multi-tenant (qualquer tenant com módulo Ouvidoria habilitado — FR-002). Maior volume conhecido hoje: ~5.160 manifestações acumuladas (tenant AGEMAN, 2018–2026). 8 blocos de relatório, 2 formatos de export, 1 tela de CRUD nova (satisfação).

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Princípio | Avaliação | Status |
|---|---|---|
| I. Spec-Driven Development | Spec 042 escrita e clarificada (`/speckit-specify` → `/speckit-clarify`, 5 perguntas resolvidas) antes deste plano | ✅ PASS |
| II. Test-First (NON-NEGOTIABLE) | Cada use-case novo (7 repositories + 5 use-cases + 2 export use-cases) exige teste antes do código, seguindo `test/use-cases/*.spec.ts` (mock de repository); frontend com Vitest para páginas/mappers novos | ✅ PASS (a garantir na fase `/speckit-tasks`/`/speckit-implement`) |
| III. Stack fixa | Nenhuma dependência nova — reuso de NestJS/Fastify/Zod/Prisma (API) e React/Vite/Tailwind/shadcn/Nivo (client); ExcelJS e PDFKit já instalados e usados no mesmo módulo/domínio | ✅ PASS |
| IV. Multi-tenant e licenças | `tenantId` via AsyncLocalStorage (nenhum código novo passa tenantId manualmente); `@RequireModulo('ouvidoria')` reaproveitado; sem licença premium nova (decisão justificada em `research.md` §6) | ✅ PASS |
| V. Clean code e modularidade | 1 repository = 1 operação, 1 use-case fino por operação (padrão já usado); PDF/Excel renderizados localmente em `ouvidoria/lib/` (sem import cross-módulo de `diagnostico/`); frontend em `modules/ouvidoria/` espelhando a API | ✅ PASS |

**Nenhuma violação identificada — Complexity Tracking não se aplica (tabela omitida).**

*Re-check pós Phase 1 (design)*: Confirmado — `data-model.md` adiciona apenas 2 tabelas novas, ambas justificadas por dado que hoje não existe (satisfação); nenhum novo padrão arquitetural introduzido além do já existente no módulo. Gates permanecem ✅ PASS.

## Project Structure

### Documentation (this feature)

```text
civ2-docs/specs/042-relatorio-gestao-ouvidoria/
├── spec.md                          # Requisitos (com Clarifications)
├── plan.md                          # Este arquivo
├── research.md                      # Decisões técnicas (Phase 0)
├── data-model.md                    # Entidades (Phase 1)
├── contracts/
│   └── relatorio-gestao.md          # Contrato das rotas novas (Phase 1)
├── quickstart.md                    # Roteiro de validação manual (Phase 1)
└── checklists/
    └── requirements.md              # Checklist de qualidade da spec
```

### Source Code (repository root)

```text
ci-api-v2/
├── prisma/schema/
│   └── ouvidoria-catalog.prisma          # + OuvidoriaPesquisaSatisfacaoPergunta, OuvidoriaPesquisaSatisfacaoLancamento
├── prisma/migrations/
│   └── <timestamp>_ouvidoria_pesquisa_satisfacao/
└── src/modules/ouvidoria/
    ├── repository/
    │   ├── get-relatorio-gestao-acumulado.repository.ts      # KPI sem filtro de ano
    │   ├── get-relatorio-gestao-zona.repository.ts            # GROUP BY Address.zone + "Não informado"
    │   ├── get-relatorio-gestao-bairro.repository.ts           # GROUP BY Address.neighborhood + "Não informado"
    │   ├── get-relatorio-gestao-tipo-manifestacao.repository.ts # GROUP BY Manifestacao.type
    │   ├── list-pesquisa-satisfacao-perguntas.repository.ts
    │   ├── list-pesquisa-satisfacao-lancamentos.repository.ts
    │   └── upsert-pesquisa-satisfacao-lancamento.repository.ts
    ├── use-cases/
    │   ├── get-relatorio-gestao.use-case.ts        # orquestra dashboard existente + agregações novas + satisfação
    │   ├── export-relatorio-gestao-pdf.use-case.ts # PDFKit local (sem import de diagnostico/)
    │   ├── export-relatorio-gestao-excel.use-case.ts # ExcelJS, 1 aba por bloco
    │   ├── list-pesquisa-satisfacao.use-case.ts
    │   └── upsert-pesquisa-satisfacao.use-case.ts
    ├── lib/
    │   └── render-relatorio-gestao-pdf.ts          # header/footer/tabelas locais (espelha render-manifestacao-pdf.ts)
    ├── ouvidoria.controller.ts                     # + 6 rotas novas (ver contracts/relatorio-gestao.md)
    ├── ouvidoria.schemas.ts                        # + RelatorioGestaoQuery, UpsertPesquisaSatisfacaoBody
    ├── ouvidoria.module.ts                         # registrar novos providers
    └── test/use-cases/
        ├── get-relatorio-gestao.use-case.spec.ts
        ├── export-relatorio-gestao-pdf.use-case.spec.ts
        ├── export-relatorio-gestao-excel.use-case.spec.ts
        └── upsert-pesquisa-satisfacao.use-case.spec.ts

ci-client-v2/apps/web/src/modules/ouvidoria/
├── api/
│   ├── relatorio-gestao.ts                     # getRelatorioGestao, exportPdf/Excel (fetch + blob, como workflow.ts)
│   └── pesquisa-satisfacao.ts                  # listPerguntas, listLancamentos, upsertLancamento
├── components/dashboard/
│   ├── ZonaChartCard.tsx
│   ├── BairroChartCard.tsx
│   ├── TipoManifestacaoChartCard.tsx
│   └── SatisfacaoChartCard.tsx
├── lib/
│   └── relatorio-gestao-mappers.ts             # API → view model dos gráficos Nivo novos
├── pages/
│   ├── OuvidoriaRelatorioGestaoPage.tsx         # reusa YearMonthFilters + novos ChartCards + botões export
│   └── OuvidoriaPesquisaSatisfacaoPage.tsx      # CRUD manual, padrão OuvidoriaAtendimentosPage.tsx
├── index.ts                                     # + lazy exports das 2 páginas novas
└── __tests__/
    ├── OuvidoriaRelatorioGestaoPage.test.tsx
    ├── OuvidoriaPesquisaSatisfacaoPage.test.tsx
    └── relatorio-gestao-mappers.test.ts

# Registro de rotas (arquivos existentes, editados — não criados)
ci-client-v2/apps/web/src/app/router.tsx              # + entradas OUVIDORIA_OVERRIDES
ci-client-v2/apps/web/src/modules/shell/config/screens.ts  # + 'ouvidoria-relatorio-gestao', 'ouvidoria-pesquisa-satisfacao' (licenses: ['base'])
```

**Structure Decision**: Web application monorepo existente (`ci-api-v2` + `ci-client-v2`, Opção 2 do template, já adotada no projeto). Toda a feature vive dentro do domínio `ouvidoria` já existente em ambos os pacotes — nenhum módulo novo é criado, apenas arquivos novos dentro da estrutura atual (`repository/`, `use-cases/`, `lib/` no backend; `api/`, `components/`, `pages/`, `lib/` no frontend), seguindo a convenção "1 arquivo = 1 operação" da constitution (§V).

## Complexity Tracking

> Nenhuma violação do Constitution Check — tabela não se aplica.
