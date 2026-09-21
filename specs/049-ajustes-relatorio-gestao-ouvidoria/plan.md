# Implementation Plan: Ajustes na Pesquisa de Satisfação e no Relatório de Gestão da Ouvidoria

**Branch**: `049-ajustes-relatorio-gestao-ouvidoria` | **Date**: 2026-09-21 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `civ2-docs/specs/049-ajustes-relatorio-gestao-ouvidoria/spec.md`

## Summary

Corrigir e enriquecer o Relatório de Gestão da Ouvidoria (spec 042, já implementado e em uso) com base no feedback real da AGEMAN após o fechamento de agosto/2026: (1) migrar a Pesquisa de Satisfação do campo único "valor" (0–10) para o modelo real Sim/Não com contagens; (2) corrigir um bug de sobreposição de texto no PDF exportado (causa raiz: altura de linha fixa em `addTable()`, não acompanha texto longo com quebra de linha); (3) detalhar o bloco Orientações/Encaminhamentos por concessão × canal de atendimento × ano (histórico completo, independente do filtro do resto do relatório); (4) adicionar um bloco novo "Participação em Eventos", com catálogo de eventos gerenciado livremente pelo usuário final (diferente do catálogo fixo de perguntas de satisfação). Abordagem técnica: reaproveitar 100% dos padrões já existentes no mesmo módulo — nenhuma dependência nova, nenhuma tabela de cache, uma migration alterando/criando 3 tabelas (todas em `ouvidoria-catalog.prisma`).

## Technical Context

**Language/Version**: TypeScript (Node.js ≥ 20) — NestJS 11 (API) / React 19 + TypeScript (client)

**Primary Dependencies**: NestJS 11, Fastify, Pino, Zod (`nestjs-zod`), Prisma 7 · React 19, Vite 8, Tailwind v4, shadcn/ui, `@nivo/bar`. Reaproveitadas sem nova instalação: `exceljs` ^4.4.0, `pdfkit` ^0.19.1 (incluindo sua API nativa `heightOfString`, usada na correção do bug de PDF).

**Storage**: PostgreSQL via Prisma 7 (Neon gerenciado). Uma migration alterando `OuvidoriaPesquisaSatisfacaoLancamento` (troca de colunas) e criando 2 tabelas novas (`OuvidoriaEvento`, `OuvidoriaEventoParticipacaoLancamento`) — ver `data-model.md`. Nenhuma alteração em `Manifestacao`/`Address`.

**Testing**: Jest (ci-api-v2) — TDD com mock de repository nos use-cases + testes de integração para as novas queries `$queryRaw` (mesmo padrão da spec 042). Vitest (ci-client-v2) — component/mapper/contract em `__tests__/`.

**Target Platform**: Web — API REST (Fastify) + SPA (Vite build, `apps/web`).

**Project Type**: Web application (monorepo existente: `ci-api-v2` + `ci-client-v2`, domínio `ouvidoria` já espelhado nos dois).

**Performance Goals**: Mesmos alvos da spec 042 — tela ≤ 5s, exports (PDF/Excel) ≤ 30s, mesmo no "acumulado geral", mesmo após os blocos novos/alterados (SC-005).

**Constraints**: Sem tabelas de cache/pré-cálculo persistentes (FR-013, herdado da constitution/spec 042); sem nova dependência de biblioteca (research.md § "Resumo de dependências"); o bloco de Orientações/Encaminhamentos ignora deliberadamente o filtro `year`/`month` do resto do relatório (research.md §3); a migration de satisfação é destrutiva na coluna `valor` (descarta o único registro de transição já existente — decisão de produto documentada em `spec.md` § Assumptions).

**Scale/Scope**: Multi-tenant (qualquer tenant com módulo Ouvidoria habilitado). Mesmo maior volume conhecido da spec 042 (~5.160 manifestações acumuladas, tenant AGEMAN). 2 blocos do relatório alterados (satisfação, orientações/encaminhamentos) + 1 bloco novo (participação em eventos) + 1 bug de renderização corrigido + 2 exports atualizados + 1 catálogo novo com CRUD completo (eventos).

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Princípio | Avaliação | Status |
|---|---|---|
| I. Spec-Driven Development | Spec 049 escrita e clarificada (`/speckit-specify` → `/speckit-clarify`, 3 perguntas resolvidas + 1 contradição adicional resolvida no início deste `/speckit-plan`) antes deste plano | ✅ PASS |
| II. Test-First (NON-NEGOTIABLE) | Cada mudança (1 fix de renderização + 3 repositories novos/alterados + 2 use-cases alterados + 1 CRUD de catálogo + 1 lançamento upsert) exige teste antes do código, seguindo `test/use-cases/*.spec.ts` e `test/repository/*.spec.ts` já usados na spec 042; frontend com Vitest para páginas/mappers alterados | ✅ PASS (a garantir em `/speckit-tasks`/`/speckit-implement`) |
| III. Stack fixa | Nenhuma dependência nova — reuso de PDFKit (`heightOfString`), ExcelJS, `$queryRaw`, Prisma, Zod, React/Vite/shadcn já em uso no mesmo módulo | ✅ PASS |
| IV. Multi-tenant e licenças | `tenantId` via `AsyncLocalStorage` (nenhum código novo passa tenantId manualmente); `@RequireModulo('ouvidoria')` reaproveitado em todas as rotas novas/alteradas; sem licença premium nova | ✅ PASS |
| V. Clean code e modularidade | 1 repository = 1 operação; catálogo de eventos replica exatamente `formas-atendimento` (create/update/inativar); lançamento de participação replica exatamente `pesquisa-satisfacao` (upsert); nenhum import cross-módulo novo; frontend em `modules/ouvidoria/` | ✅ PASS |

**Nenhuma violação identificada — Complexity Tracking não se aplica (tabela omitida).**

*Re-check pós Phase 1 (design)*: Confirmado — `data-model.md` altera 1 tabela existente (troca de colunas, sem nova entidade "paralela") e adiciona apenas 2 tabelas novas, ambas justificadas por dado que hoje não existe (eventos) e ambas reaproveitando padrões já validados no mesmo arquivo Prisma. Nenhum novo padrão arquitetural introduzido. Gates permanecem ✅ PASS.

## Project Structure

### Documentation (this feature)

```text
civ2-docs/specs/049-ajustes-relatorio-gestao-ouvidoria/
├── spec.md                          # Requisitos (com Clarifications)
├── plan.md                          # Este arquivo
├── research.md                      # Decisões técnicas (Phase 0)
├── data-model.md                    # Entidades alteradas/novas (Phase 1)
├── contracts/
│   └── ajustes-relatorio-gestao.md  # Contrato — o que muda vs. spec 042 (Phase 1)
├── quickstart.md                    # Roteiro de validação manual (Phase 1)
└── checklists/
    └── requirements.md              # Checklist de qualidade da spec
```

### Source Code (repository root)

```text
ci-api-v2/
├── prisma/schema/
│   └── ouvidoria-catalog.prisma          # ALTERA OuvidoriaPesquisaSatisfacaoLancamento (troca valor→consultados/respostasSim/respostasNao)
│                                          # + OuvidoriaEvento, OuvidoriaEventoParticipacaoLancamento (novos)
├── prisma/migrations/
│   └── <timestamp>_ouvidoria_ajustes_satisfacao_eventos/
└── src/modules/ouvidoria/
    ├── repository/
    │   ├── upsert-pesquisa-satisfacao-lancamento.repository.ts     # ALTERA: valor → consultados/respostasSim/respostasNao
    │   ├── list-pesquisa-satisfacao-lancamentos.repository.ts       # ALTERA: mapper inclui percentual derivado
    │   ├── get-relatorio-gestao-orientacoes-encaminhamentos.repository.ts  # NOVO — GROUP BY ano/concessão/canal
    │   ├── create-evento.repository.ts                             # NOVO
    │   ├── update-evento.repository.ts                             # NOVO
    │   ├── inactivate-evento.repository.ts                         # NOVO
    │   ├── list-eventos.repository.ts                              # NOVO
    │   ├── upsert-evento-participacao-lancamento.repository.ts     # NOVO
    │   └── list-evento-participacoes.repository.ts                 # NOVO
    ├── use-cases/
    │   ├── upsert-pesquisa-satisfacao.use-case.ts        # ALTERA: input novo (consultados/respostasSim/respostasNao)
    │   ├── list-pesquisa-satisfacao.use-case.ts          # ALTERA: percentual derivado no retorno
    │   ├── get-relatorio-gestao.use-case.ts              # ALTERA: orquestra os 2 blocos novos
    │   ├── export-relatorio-gestao-pdf.use-case.ts       # inalterado (usa lib corrigida)
    │   ├── export-relatorio-gestao-excel.use-case.ts     # ALTERA: 2 abas novas + aba satisfação atualizada
    │   ├── create-evento.use-case.ts                     # NOVO
    │   ├── update-evento.use-case.ts                     # NOVO
    │   ├── inactivate-evento.use-case.ts                 # NOVO
    │   ├── list-eventos.use-case.ts                      # NOVO
    │   └── upsert-evento-participacao.use-case.ts        # NOVO
    ├── lib/
    │   ├── render-relatorio-gestao-pdf.ts                # ALTERA: addTable() usa heightOfString (fix do bug)
    │   └── relatorio-gestao-pdf-sections.ts              # ALTERA: seção satisfação + 2 seções novas
    ├── ouvidoria.controller.ts                # + 6 rotas novas (eventos + participações), altera POST pesquisa-satisfacao
    ├── ouvidoria.schemas.ts                   # altera upsertPesquisaSatisfacaoBodySchema; + createEventoBodySchema etc.
    ├── ouvidoria.types.ts                     # altera PesquisaSatisfacaoLancamentoDTO; + tipos de evento
    ├── ouvidoria.module.ts                    # registrar providers novos
    └── test/
        ├── repository/
        │   └── get-relatorio-gestao-orientacoes-encaminhamentos.repository.spec.ts   # NOVO
        └── use-cases/
            ├── upsert-pesquisa-satisfacao.use-case.spec.ts        # ALTERA
            ├── get-relatorio-gestao.use-case.spec.ts              # ALTERA
            ├── export-relatorio-gestao-excel.use-case.spec.ts     # ALTERA
            ├── render-relatorio-gestao-pdf.spec.ts (lib)          # ALTERA — cobre não-overlap com motivo longo
            ├── create-evento.use-case.spec.ts                     # NOVO
            └── upsert-evento-participacao.use-case.spec.ts        # NOVO

ci-client-v2/apps/web/src/modules/ouvidoria/
├── api/
│   ├── pesquisa-satisfacao.ts             # ALTERA: upsertLancamento (novo body)
│   └── eventos.ts                         # NOVO — listEventos, createEvento, updateEvento, inactivateEvento, listParticipacoes, upsertParticipacao
├── components/dashboard/
│   ├── SatisfacaoChartCard.tsx            # ALTERA: exibe % em vez de score 0–10
│   ├── OrientacoesEncaminhamentosChartCard.tsx  # NOVO
│   └── ParticipacaoEventosChartCard.tsx   # NOVO
├── lib/
│   └── relatorio-gestao-mappers.ts        # ALTERA: mapeia percentual + 2 blocos novos
├── pages/
│   ├── OuvidoriaRelatorioGestaoPage.tsx   # ALTERA: + 2 ChartCards novos
│   ├── OuvidoriaPesquisaSatisfacaoPage.tsx # ALTERA: formulário Sim/Não em vez de "valor"
│   └── OuvidoriaEventosPage.tsx           # NOVO — CRUD de eventos + lançamento de participações
├── index.ts                               # + lazy export da página de eventos
└── __tests__/
    ├── relatorio-gestao-mappers.test.ts           # ALTERA
    ├── OuvidoriaPesquisaSatisfacaoPage.test.tsx    # ALTERA
    └── OuvidoriaEventosPage.test.tsx               # NOVO

# Registro de rotas (arquivos existentes, editados — não criados)
ci-client-v2/apps/web/src/app/router.tsx              # + entrada 'ouvidoria-eventos' em OUVIDORIA_OVERRIDES
ci-client-v2/apps/web/src/modules/shell/config/screens.ts  # + 'ouvidoria-eventos' (licenses: ['base'])
```

**Structure Decision**: Web application monorepo existente (`ci-api-v2` + `ci-client-v2`), mesma decisão da spec 042. Toda a feature vive dentro do domínio `ouvidoria` já existente em ambos os pacotes — nenhum módulo novo é criado; a maior parte do trabalho é **alteração** de arquivos já entregues pela spec 042 (satisfação, PDF, Excel, orquestrador do relatório), mais um conjunto de arquivos novos que replicam exatamente dois padrões já existentes (`formas-atendimento` para o catálogo de eventos; `pesquisa-satisfacao` para o lançamento de participações).

## Complexity Tracking

> Nenhuma violação do Constitution Check — tabela não se aplica.
