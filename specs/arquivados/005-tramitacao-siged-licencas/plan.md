# Implementation Plan: Tramitação — Demandas SIGED e Licenças

**Branch**: `005-tramitacao-siged-licencas` | **Date**: 2026-06-17 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/005-tramitacao-siged-licencas/spec.md`

## Summary

Estender o módulo **Tramitação** (mock interativo no client) com recebimento simulado de demandas **SIGED** (Prefeitura de Manaus — processo + documentos vinculados), controle operacional inter-setorial na inbox `/tramitacao/demandas`, dashboard consolidado e **quatro licenças** (Jatobá, Cedro, Carvalho, Pau-Brasil) com barra de alertas e rastreabilidade. **Sem API nova** — dados em `modules/shell/data/`, telas em `screens.ts` + `license-screens.ts`, UI existente `TramitacaoInboxPanel` estendida. `ci-api-v2` fora de escopo.

## Technical Context

**Language/Version**: TypeScript 5.x / 6.x, React 19, Node.js 20 LTS

**Primary Dependencies**: Vite 8, react-router-dom 7, Tailwind v4, shadcn/ui via `@ci/ui`, Nivo (gráficos dashboard), `@ci/domain` (tipos licença e `ScreenConfig`)

**Storage**: Mock estático em TS (`tramitacao-mock.ts`, `mock-data.ts`, `traceability-mock.ts`); rascunho de composição em `localStorage` (`tramitacao-draft.ts`) — sem persistência server-side

**Testing**: Typecheck + lint + build (`npm run build` em `ci-client-v2`); smoke manual via [quickstart.md](./quickstart.md); sem endpoints API — TDD aplicável a funções puras de derivação (status operacional, filtros setor, agregação dashboard) se extraídas para `lib/`

**Target Platform**: Browser SPA (`@ci/web`)

**Project Type**: Frontend-only — extensão de infra mock em `modules/shell/`

**Performance Goals**: Inbox e dashboard renderizam &lt; 100 ms com dataset mock (~30 demandas); identificação SIGED visível sem scroll extra na lista

**Constraints**:

- FR-021/FR-022: **nenhum** módulo NestJS, migration Prisma ou integração SIGED real
- Copy e UX: [regras-plataforma.md](../../.cursor/docs/regras-plataforma.md), [licencas-canonicas.md](../../.cursor/docs/licencas-canonicas.md), [traceability-mock.md](../../.cursor/docs/traceability-mock.md), `mint-palette`
- Skills: `ui-ux-pro-max` (inbox, badges SIGED, sheets), `vite-react-best-practices` (rotas lazy inalteradas)
- Módulo `tramitacao` permanece `OPEN_MODULES` — sem `@RequireModulo` novo
- Status operacional (Base) ≠ conformidade Jatobá — conjuntos fechados separados
- Protocolo Virtual **inalterado**

**Scale/Scope**: ~15 arquivos TS/TSX tocados; 5 telas novas (maturidade, insights, auditoria + extensões dashboard/demandas); ~8 demandas mock SIGED; 4 entradas rastreabilidade; 1 entrada `moduleLicenseConfig`

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Princípio | Status | Notas |
|-----------|--------|-------|
| I. Spec-Driven | ✅ PASS | Spec 005 validada; plano segue fluxo |
| II. Test-First | ✅ PASS* | Mock UI: smoke + typecheck/build; funções puras de status/filtro com testes unitários opcionais em `shell/lib/__tests__/` — sem API TDD |
| III. Stack fixa | ✅ PASS | React 19 + Vite 8 + Tailwind v4 + shadcn + Nivo |
| IV. Multi-tenant/licenças | ✅ PASS | Mock tenant Manaus; quatro licenças + Base no módulo Tramitação |
| V. Modularidade | ✅ PASS | Extensão em `modules/shell/` (padrão mock atual); `modules/tramitacao/` reservado para fase API futura |

**Post-design re-check**: Sem violações; Complexity Tracking vazio. Decisão de manter mock em `shell/` alinhada à spec (FR-022) e ao estado atual do repositório.

## Project Structure

### Documentation (this feature)

```text
specs/005-tramitacao-siged-licencas/
├── plan.md              # Este arquivo
├── research.md          # Decisões técnicas (Phase 0)
├── data-model.md        # Entidades mock e transições
├── quickstart.md        # Validação pós-implementação
├── contracts/
│   ├── client-tramitacao-ui.md
│   └── mock-data-layout.md
└── tasks.md             # Phase 2 — /speckit-tasks
```

### Source Code (repository root)

```text
ci-client-v2/
├── packages/domain/src/lib/
│   └── licenses.ts                    # + moduleLicenseConfig.tramitacao
└── apps/web/src/modules/shell/
    ├── config/
    │   ├── screens.ts                 # + tramitacao-auditoria; estender dashboard/demandas
    │   ├── license-screens.ts         # + tramitacao em modules[]; maturidade/insights
    │   └── navigation.ts              # + licenseNav('tramitacao') + Fiscalização
    ├── data/
    │   ├── tramitacao-mock.ts         # + origem SIGED, processo, documentos, demandas SIGED
    │   ├── mock-data.ts               # + maturityByModule.tramitacao, mockTableRows, jatoba, cedro
    │   └── traceability-mock.ts       # + traces tramitacao (jatoba/cedro/carvalho)
    ├── lib/
    │   ├── license-alerts.ts          # + MODULE_PATHS.tramitacao
    │   ├── traceability.ts            # + getters tramitacao
    │   └── tramitacao-draft.ts        # (inalterado ou + origem interna)
    └── components/mock/
        ├── TramitacaoInboxPanel.tsx   # badge SIGED, painel processo/doc, license bar, Pau-Brasil compose
        ├── DashboardCharts.tsx        # + série origem SIGED vs interna
        ├── LicensePanels.tsx          # (reuso JatobaRecordCheck / CedroModulePanel se inbox detalhe)
        └── ScreenPageLayout.tsx       # (reuso ListLicenseAlertBar em type inbox se aplicável)

ci-api-v2/                             # FORA DE ESCOPO — nenhuma alteração
```

**Structure Decision**: Mock de Tramitação permanece colocated em `modules/shell/` (config + data + componentes mock), consistente com `TramitacaoInboxPanel` e `screens.ts` existentes. Pacote `@ci/domain` recebe apenas `moduleLicenseConfig.tramitacao`. Pasta `modules/tramitacao/` **não** é criada nesta feature — reservada para espelho API quando houver backend.

## Complexity Tracking

> Nenhuma violação de constitution que exija justificativa.

## Phase 0 → research.md

Decisões consolidadas:

| ID | Tópico | Decisão |
|----|--------|---------|
| R1 | Origem SIGED no mock | Campo `origem: 'interna' \| 'siged'` em `TramitacaoMessage` + objetos aninhados `processoSiged` / `documentosSiged[]` |
| R2 | Telas de licença | Geradas via `buildLicenseScreens()` + entradas manuais `tramitacao-auditoria` em `screens.ts` (padrão ouvidoria/protocolo) |
| R3 | Alertas na inbox | `ListLicenseAlertBar` + `getModuleLicenseTraffic('tramitacao')` após dados em `mock-data.ts` |
| R4 | Pau-Brasil na composição | `MockInlineActionButton` + `getLicenseActionPreset('pau-brasil')` no sheet Compor de `TramitacaoInboxPanel` |
| R5 | Dashboard SIGED vs interna | Novo dataset `tramitacaoOrigemData` em `tramitacao-mock.ts`; gráfico em `DashboardCharts` case `tramitacao` |
| R6 | Persistência | Apenas `localStorage` para draft cross-módulo; demandas SIGED são fixtures — sem simular webhook |

## Phase 1 → artefatos

- [data-model.md](./data-model.md) — tipos mock, enums, transições de status
- [contracts/client-tramitacao-ui.md](./contracts/client-tramitacao-ui.md) — rotas, layout inbox, licenças
- [contracts/mock-data-layout.md](./contracts/mock-data-layout.md) — fixtures e IDs canônicos
- [quickstart.md](./quickstart.md) — cenários VS-001…VS-009

## Implementation Notes (para /speckit-tasks)

1. **Ordem sugerida**: domain config → mock data → screens/navigation → license-screens → inbox UI → dashboard → traceability → alert bar → detalhe licenças (P3)
2. **Paridade Protocolo**: Jatobá tramitação SLA 2 dias úteis; Cedro gargalos; Pau-Brasil ofício/memorando — adaptados ao domínio transporte inter-setorial
3. **Copy SIGED**: usar "SIGED — Prefeitura de Manaus" em badge; protocolos fictícios `SIGED-2026-NNNNN`
4. **Não tocar**: `ci-api-v2`, rotas `/protocolo/*`, `modules/ouvidoria/`
