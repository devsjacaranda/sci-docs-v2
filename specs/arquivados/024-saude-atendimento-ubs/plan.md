# Implementation Plan: Módulo Saúde — Atendimento UBS / e-SUS

**Branch**: `024-saude-atendimento-ubs` (feature.json pinned; git em `main`) | **Date**: 2026-06-29 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/024-saude-atendimento-ubs/spec.md`

## Summary

Entregar módulo **Saúde** (`@ci/web`) para Careiro da Várzea (AM): CRUD mock da **Consulta agregada** (6 dimensões e-SUS), cadastros de apoio, relatórios somente leitura (~400 receitas / ~100 exames), fila editável cidadão→UBS, controle interno (indicadores, conferência, tramitação), validação pública `/validar` e exportação **FAI e-SUS** (JSON). **100% client-side** — dados sintéticos, persistência em store local; **sem API NestJS nesta entrega**. CRUD e operação diária sob licença **`base`** (sem nova licença-árvore).

**Gap atual**: módulo `saude` inexistente; backup e-SUS serve só de referência de mapeamento export.

**Abordagem**: novo `modules/saude/` espelhando padrão `modules/it/` + `modules/tramitacao/` — páginas dedicadas via `SAUDE_OVERRIDES` em `router.tsx`; entidades simples podem usar `ScreenConfig` genérico onde couber; stores editáveis em `lib/*-store.ts`; Zod DTOs em `schemas/`; seed determinístico Careiro (~8 UBS).

## Technical Context

**Language/Version**: TypeScript 5.x / 6.x; Node.js 20 LTS

**Primary Dependencies**:

| Pacote | Stack |
|--------|-------|
| **sci-client-monorepo** (`@ci/web`) | React 19, Vite 8, Tailwind v4, shadcn/ui, react-router-dom 7, Zod 3, Vitest 3 |
| **sci-api-v2** | **Fora de escopo** nesta feature |

**Storage**: In-memory + `localStorage` (namespace `ci:saude:v1:*`) via stores modulares; seed idempotente em `data/seed.ts`

**Testing**:

| Camada | Client |
|--------|--------|
| Unitário | Vitest — mappers, `esus-export`, `receita-signature`, `conferencia-rules`, `unidades-stats` |
| Componente | Vitest + RTL — formulário consulta, relatórios, validação pública |
| Contrato | Zod parse round-trip nos DTOs + snapshot FAI export |
| Integração | Vitest — páginas com MemoryRouter + store seed |
| E2E leve | Vitest — jornadas P1 (criar consulta, validar receita, filtrar indicadores) |

**Target Platform**: SPA browser (`apps/web`)

**Project Type**: Frontend-only (mock operacional)

**Performance Goals**: Listagens ~500 itens renderizáveis com filtros client-side < 300ms percebidos; export FAI < 1s

**Constraints**:

- TDD obrigatório RED → GREEN → REFACTOR (Vitest)
- Licença **`base`** para CRUD, relatórios operacionais, fila, conferência base, indicadores base, `/validar`
- Camadas Cedro/Jatobá/Carvalho **opcionais** em telas futuras — **não** bloqueiam escopo P1
- Dados **100% sintéticos** — zero PII do backup e-SUS
- Export e-SUS = JSON FAI legível — **sem** thrift/LEDI/SISAB nesta fase
- Tramitação via `TramitarButton` + draft existente (`tramitacao-draft.ts`)
- Copy: [.cursor/docs/regras-plataforma.md](../../../.cursor/docs/regras-plataforma.md)
- Paleta Mint: rule `mint-palette.mdc`

**Scale/Scope**: ~1 módulo novo, ~15 rotas, ~12 páginas, ~8 libs, seed ~500 registros derivados, ~25 arquivos de teste

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Princípio | Status | Notas |
|-----------|--------|-------|
| I. Spec-Driven | ✅ PASS | Spec 024 validada; plano segue fluxo |
| II. Test-First | ✅ PASS | Vitest em stores, export, páginas críticas |
| III. Stack fixa | ✅ PASS | React 19 + Vite 8 + Zod; sem desvio |
| IV. Multi-tenant | ✅ N/A mock | Store namespaced por tenantId quando auth disponível; fallback `demo-careiro` |
| IV. Licenças | ✅ PASS | CRUD `base` only; sem nova licença |
| V. Escopo mínimo | ✅ PASS | Client-only; espelha `it/` + `tramitacao/` |

**Post-design re-check**: Agregado `Consulta` único evita 6 CRUDs desconectados (Constitution V). Export isolado em `lib/esus-export.ts`. Sem Complexity Tracking.

## Project Structure

### Documentation (this feature)

```text
specs/024-saude-atendimento-ubs/
├── plan.md              # Este arquivo
├── research.md          # Decisões técnicas (Phase 0)
├── data-model.md        # Entidades + Zod + estados
├── quickstart.md        # Validação manual + testes
├── contracts/
│   ├── client-saude-ui.md
│   ├── client-saude-dtos.md
│   ├── esus-fai-export.md
│   └── test-strategy.md
└── tasks.md             # Phase 2 — /speckit-tasks
```

### Source Code (repository root)

```text
sci-client-monorepo/apps/web/src/modules/saude/
├── index.tsx                    # SAUDE_OVERRIDES + lazy exports
├── api/
│   ├── types.ts                 # DTOs TypeScript (camelCase)
│   ├── consultas.ts             # CRUD facade → store
│   ├── cidadaos.ts
│   ├── profissionais.ts
│   ├── unidades.ts
│   ├── medicamentos.ts
│   ├── receitas-relatorio.ts
│   ├── exames-relatorio.ts
│   └── solicitacoes.ts
├── schemas/
│   ├── consulta.schema.ts
│   ├── cidadao.schema.ts
│   ├── profissional.schema.ts
│   ├── unidade.schema.ts
│   ├── receita.schema.ts
│   ├── exame.schema.ts
│   ├── solicitacao.schema.ts
│   └── esus-fai.schema.ts       # shape export e-SUS
├── lib/
│   ├── consultas-store.ts
│   ├── solicitacoes-store.ts
│   ├── receita-signature.ts
│   ├── unidades-stats.ts
│   ├── conferencia-rules.ts
│   ├── esus-export.ts
│   └── indicadores.ts
├── data/
│   ├── seed.ts                  # Careiro ~8 UBS, ~400 receitas, ~100 exames
│   └── careiro-unidades.ts
├── pages/
│   ├── SaudeDashboardPage.tsx
│   ├── ConsultasListPage.tsx
│   ├── ConsultaFormPage.tsx
│   ├── ConsultaDetailPage.tsx
│   ├── SaudeConferenciaPage.tsx
│   ├── ReceitasRelatorioPage.tsx
│   ├── ExamesRelatorioPage.tsx
│   ├── SolicitacoesPage.tsx
│   ├── UnidadesPage.tsx
│   └── ValidarReceitaPage.tsx   # rota pública
├── components/
│   ├── ConsultaSoapTabs.tsx
│   ├── ConsultaProcedimentosList.tsx
│   ├── ConsultaReceitasList.tsx
│   ├── UnidadeStatsCard.tsx
│   └── SaudeIndicadoresCharts.tsx
└── __tests__/

sci-client-monorepo/apps/web/src/
├── app/router.tsx               # SAUDE_OVERRIDES + /validar público
└── modules/shell/config/
    ├── screens.ts               # metadados saude-*
    ├── navigation.ts
    └── welcome-shortcuts.ts
```

**Structure Decision**: Frontend-only em `sci-client-monorepo/apps/web`. Padrão híbrido: páginas ricas para Consulta/indicadores/conferência/relatórios; cadastros secundários (medicamentos) podem iniciar via `ScreenPage` + store até evoluir.

## Complexity Tracking

> Nenhuma violação constitucional que exija justificativa.

## Pós-implement (2026-06-29)

| Área | Entrega |
|------|---------|
| Navegação | Seção Saúde na sidebar; 4 subgrupos (Atendimento, Cadastros, Acompanhamento, Controle) |
| Dashboards | `SaudeAtendimentoDashboardPage`, `SaudeCadastrosDashboardPage`, `SaudeAcompanhamentoDashboardPage`, `SaudeControleDashboardPage` |
| Design system | `SaudePageHeader`, `SaudeKpiGrid`, `SaudeFiltersBar`, `InstitutionalListLayout` |
| Detalhe | `components/detail/CopyableField`, `SaudeDetailPageLayout` |
| Licenças mock | Insights (Cedro), Fiscalização (Jatobá), Maturidade (Carvalho) |
| Testes | **114** testes Vitest (`npm test -- saude navigation`) |

**Adiado**: `lib/esus-export.ts` (US7) — placeholder toast em `ConsultaDetailPage`.
