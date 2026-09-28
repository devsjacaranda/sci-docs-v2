# Implementation Plan: Matriz Concessão × Desfecho e Ajustes de Status/Encerramento (AGEMAN)

**Branch**: `052-matriz-concessao-desfecho-ageman` · **Date**: 2026-09-28 · **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `civ2-docs/specs/052-matriz-concessao-desfecho-ageman/spec.md`

## Summary

Fechar o último gap do feedback pós-uso da AGEMAN (WhatsApp, ago/2026) sobre o relatório de gestão da Ouvidoria: (1) nova tabela **Concessão × Desfecho** no relatório, espelhando a aba `DEMANDAS_EMITIDAS CONC.` da planilha manual; (2) remover "Pendente" como opção de encerramento (bug de UX — encerrar não pode significar "ainda pendente"); (3) renomear o status pré-demanda `in_review` de "Em análise" para "Pendente"; (4) filtro por tipo de concessão na lista de demandas. Toda a agregação deriva de colunas já existentes (`status`, `programa`, `serviceMode`) — sem migration Prisma, sem tabela de cache.

## Technical Context

**Language/Version**: TypeScript 5.9 (Node 22, `ci-api-v2`) / TypeScript + React 19 (`ci-client-v2`)

**Primary Dependencies**: NestJS 11, Fastify, Pino, Zod (`nestjs-zod`), Prisma 7, PostgreSQL (API) · React 19, Vite 8, Tailwind v4, shadcn/ui, Nivo (client) — stack fixa da Constitution III, sem desvio.

**Storage**: PostgreSQL (Prisma) — nenhuma migration nesta feature; reaproveita colunas `Manifestacao.status`, `Manifestacao.programa`, `Manifestacao.serviceMode`.

**Testing**: Jest (`ci-api-v2`), Vitest + Testing Library (`ci-client-v2/apps/web`) — TDD RED→GREEN→REFACTOR (Constitution II).

**Target Platform**: Web (SPA `@ci/web`) + API REST multi-tenant.

**Project Type**: Web application (backend `ci-api-v2` + frontend `ci-client-v2/apps/web`, módulo `ouvidoria` em ambos).

**Performance Goals**: Herdado das specs 042/049/050 — relatório ≤ 5s (p95) tela, ≤ 30s exports.

**Constraints**: Sem tabela de cache/pré-cálculo persistente (FR-009, herdado de FR-013 da 042). Sem hardcode de tenant (concessão é mapa de constantes genérico, não flag AGEMAN).

**Scale/Scope**: 1 tenant produtivo com dado real relevante hoje (AGEMAN/Jacaranda, ~5k+ manifestações); demais tenants recebem o mesmo código de forma genérica (US2/US3 valem para todos; US1/US4 só têm dado relevante onde há `programa`/concessão mapeável).

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Princípio | Conformidade |
| --- | --- |
| I. Spec-Driven Development | Spec → Clarify → **Plan (este documento)** → Tasks → Implement, todos em `civ2-docs/specs/052-.../`. |
| II. Test-First (TDD) | Todas as tasks de implementação (fase de `/speckit-tasks`) exigem RED antes de GREEN — reaproveita specs Jest/Vitest já existentes como baseline (`dashboard-agregacoes.repository.spec.ts`, `ManifestacaoActionDialogs.test.tsx`, etc.). |
| III. Stack fixa | Zod puro (`ouvidoria.schemas.ts`), sem class-validator; nenhuma dependência nova. |
| IV. Multi-tenant e licenças | Todas as queries novas usam `tenantId` via `getRequestContext()` (padrão já usado em `dashboard.repositories.ts`); acesso segue `@RequireModulo('ouvidoria')` já existente nas rotas tocadas. |
| V. Clean code e modularidade | Novo bloco em arquivo de repository próprio (`get-relatorio-gestao-concessao-desfecho.repository.ts`), não amontoado em `dashboard.repositories.ts`; 1 arquivo = 1 operação, conforme `ci-api-arquitetura`. |

**Resultado**: PASS. Nenhuma violação a justificar em Complexity Tracking.

## Decisões de produto e técnicas

Ver [research.md](./research.md) para o levantamento completo do código real (que diverge dos drafts 050-desfecho/050-tipo-concessao em alguns pontos). Resumo:

### 1. Encerramento (FR-003)

- **Não** é um redesenho — é uma **restrição** do enum já implementado em produção (`manifestacaoDesfechoEncerramentoSchema`, `MANIFESTACAO_DESFECHO_ENCERRAMENTO`): de 3 valores (`resolvida`/`meio_juridico`/`pendente`) para 2 (`resolvida`/`meio_juridico`).
- `ManifestacaoStatus.closed_unresolved` permanece no enum Prisma (histórico), só deixa de ser alcançável via encerramento explícito com `desfecho: 'pendente'`.

### 2. Matriz Concessão × Desfecho (FR-001/001a/002/004)

- Novo repository `get-relatorio-gestao-concessao-desfecho.repository.ts`, reaproveitando `sqlMapProgramaConcessaoCase`/`mapProgramaConcessao` (`lib/map-programa-concessao.ts`) para a dimensão concessão e as mesmas regras de `resolutividade`/`demandasPendentes` (`dashboard.repositories.ts`) para as 4 colunas de desfecho — ver `data-model.md` §3.
- Campo novo `concessaoPorDesfecho` no payload de `GET /ouvidoria/relatorio-gestao` (não é rota dedicada — mesmo período/filtro do relatório principal).

### 3. Rename "Em análise" → "Pendente" (FR-005/006)

- Toca `MANIFESTACAO_STATUS_LABEL` e `PUBLIC_MANIFESTACAO_STATUS_LABEL` (`ouvidoria.mapper.ts`), `STATUS_OPTIONS`/KPI cards no client, exports PDF/Excel — lista completa em `data-model.md` §5 e `files-touch-list.md`.
- Reaproveita o padrão de desambiguação já existente (`closed_unresolved` → "Pendente (desfecho)") para `in_review` → "Pendente" sem sufixo.

### 4. Filtro de concessão (FR-007)

- Novo param `concessao` em `listManifestacoesQuerySchema` + `ListManifestacoesRepository`, resolvido pela mesma expressão SQL de concessão.
- Sem tabela de "catálogo" nova — opções do filtro vêm de uma agregação leve de concessões distintas do tenant; lista vazia ⇒ filtro oculto (ver `research.md` §4).

## Project Structure

### Documentation (this feature)

```text
civ2-docs/specs/052-matriz-concessao-desfecho-ageman/
├── spec.md                                          # /speckit-specify + /speckit-clarify
├── plan.md                                          # Este arquivo
├── research.md                                      # Fase 0
├── data-model.md                                    # Fase 1
├── quickstart.md                                    # Fase 1
├── files-touch-list.md                              # Fase 1 (coordenação de arquivos)
├── contracts/
│   └── relatorio-gestao-concessao-desfecho.md       # Fase 1
└── tasks.md                                         # /speckit-tasks (não criado por /speckit-plan)
```

### Source Code (repositório)

```text
ci-api-v2/src/modules/ouvidoria/
├── lib/
│   ├── manifestacao-desfecho.ts                     # FR-003: remover branch 'pendente'
│   └── map-programa-concessao.ts                    # reaproveitado (sem mudança)
├── repository/
│   ├── get-relatorio-gestao-concessao-desfecho.repository.ts   # NOVO — matriz FR-001
│   └── manifestacao.repositories.ts                 # ListManifestacoesRepository — filtro FR-007
├── use-cases/
│   ├── get-relatorio-gestao.use-case.ts              # incorpora concessaoPorDesfecho
│   └── list-manifestacoes.use-case.ts                # passa filtro concessao
├── ouvidoria.schemas.ts                              # enum desfecho restrito; query concessao
├── ouvidoria.mapper.ts                                # rótulos "Pendente" (FR-005/006)
└── lib/relatorio-gestao-pdf-sections.ts + use-cases/export-relatorio-gestao-excel.use-case.ts
                                                        # seção/aba nova + rótulos

ci-client-v2/apps/web/src/modules/ouvidoria/
├── lib/manifestacao-desfecho-copy.ts                 # FR-003: 2 opções
├── components/ManifestacaoActionDialogs.tsx          # 2 botões (sem código, deriva da lista)
├── pages/ManifestacoesListPage.tsx                   # STATUS_OPTIONS + filtro concessão (FR-005/007)
├── lib/manifestacoes-list-stats.ts                   # rótulo KPI (FR-005)
├── lib/relatorio-gestao-mappers.ts                   # mapConcessaoPorDesfechoChart (novo) + rename
└── pages/OuvidoriaRelatorioGestaoPage.tsx             # novo bloco/tabela + card renomeado
```

**Structure Decision**: modular por domínio (`modules/ouvidoria/` em ambos os pacotes), espelhando a estrutura já existente — nenhuma pasta nova de alto nível, apenas 1 repository novo (regra "1 arquivo = 1 operação").

## Complexity Tracking

*Sem violações da Constitution Check — seção não aplicável.*
