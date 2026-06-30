# Implementation Plan: Exportação e-SUS — Dados Mockdown para Demonstração

**Branch**: `026-esus-mockdown-export` (feature.json pinned; git em `main`) | **Date**: 2026-06-29 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/026-esus-mockdown-export/spec.md`

## Summary

Implementar exportação **e-SUS APS** no módulo Saúde mockdown (`@ci/web`): mapper **FAI JSON legível** a partir da `Consulta` agregada, validação de prontidão alinhada à conferência, preview/download na UI e blocos de **extensão demo** (receitas, exames, solicitações). Complementos P3: pacote de cadastros de referência e exportação em lote. **100% client-side** — substitui placeholder toast em `ConsultaDetailPage`; **sem** API NestJS, Thrift/XML LEDI ou envio SISAB. Licença **`base`**; dados sintéticos Careiro.

**Gap atual**: `lib/esus-export.ts` e `schemas/esus-fai.schema.ts` **não existem**; botão "Exportar e-SUS" exibe toast placeholder.

**Abordagem**: TDD Vitest — `validateConsultaExportReady` → `exportConsultaToFai` → Zod round-trip → UI Sheet + download Blob; reutilizar `conferencia-rules.ts` e contrato arquivado 024; estender payload com namespace `_demoExtensions` documentado.

## Technical Context

**Language/Version**: TypeScript 5.x / 6.x; Node.js 20 LTS

**Primary Dependencies**:

| Pacote | Stack |
|--------|-------|
| **sci-client-monorepo** (`@ci/web`) | React 19, Vite 8, Tailwind v4, shadcn/ui, react-router-dom 7, Zod 3, Vitest 3 |
| **sci-api-v2** | **Fora de escopo** |

**Storage**: Leitura de stores existentes (`consultas-store`, cadastros seed/localStorage `ci:saude:v1:*`); export **não persiste** — artefato efêmero (Blob download / preview em memória)

**Testing**:

| Camada | Client |
|--------|--------|
| Unitário | Vitest — `esus-export`, `esus-fai.schema`, `esus-cadastros-export`, flags exame solicitante |
| Componente | Vitest + RTL — `EsusExportSheet`, botão export em `ConsultaDetailPage`, ação conferência |
| Contrato | Snapshot FAI + Zod parse round-trip + lista `missing` |
| Integração | Vitest — jornada conferência → export → download filename |

**Target Platform**: SPA browser (`sci-client-monorepo/apps/web`)

**Project Type**: Frontend-only (extensão módulo `saude/` existente)

**Performance Goals**: Validação + geração payload < 500ms; download imediato; lote até ~50 consultas < 3s

**Constraints**:

- TDD obrigatório RED → GREEN → REFACTOR
- Referência layout: **LEDI APS 7.4.2** (subset legível — não transmissão completa)
- Gate conferência: `statusConferencia === 'pronto_envio'`
- Regra APS: solicitante exame complementar — CBO médico (`225*`)
- Extensões demo claramente rotuladas — nunca confundir com campo MS oficial
- Dados **100% sintéticos** — zero PII backup PEC
- Copy: `.cursor/docs/regras-plataforma.md` · Paleta Mint: `mint-palette.mdc`
- Skill domínio: `.cursor/skills/esus-aps/SKILL.md`

**Scale/Scope**: ~8 arquivos novos/alterados em `lib/` + `schemas/` + `components/` + 2 páginas; ~12 arquivos de teste; 0 migrations

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Princípio | Status | Notas |
|-----------|--------|-------|
| I. Spec-Driven | ✅ PASS | Spec 026 validada; plano segue fluxo |
| II. Test-First | ✅ PASS | Vitest snapshot + validate antes de UI |
| III. Stack fixa | ✅ PASS | React 19 + Vite 8 + Zod; sem desvio |
| IV. Multi-tenant | ✅ N/A mock | Stores namespaced `ci:saude:v1:{tenantId}` |
| IV. Licenças | ✅ PASS | Export sob licença `base` (módulo Saúde) |
| V. Escopo mínimo | ✅ PASS | Extensão colocated em `modules/saude/lib/`; sem backend |

**Post-design re-check**: Lógica export isolada em `lib/esus-export.ts` + `lib/esus-cadastros-export.ts`; UI fina em `EsusExportSheet`; validação compartilhada evita duplicar `conferencia-rules`. Sem Complexity Tracking.

## Project Structure

### Documentation (this feature)

```text
sci-docs-v2/specs/026-esus-mockdown-export/
├── plan.md              # Este arquivo
├── research.md          # Decisões técnicas (Phase 0)
├── data-model.md        # Payload export + validação + extensões
├── quickstart.md        # Validação manual + testes
├── contracts/
│   ├── esus-fai-export.md
│   ├── esus-export-extensions.md
│   ├── esus-cadastros-package.md
│   ├── client-export-ui.md
│   └── test-strategy.md
└── tasks.md             # Phase 2 — /speckit-tasks
```

### Source Code (repository root)

```text
sci-client-monorepo/apps/web/src/modules/saude/
├── lib/
│   ├── esus-export.ts              # NEW — exportConsultaToFai, validateConsultaExportReady
│   ├── esus-cadastros-export.ts    # NEW — exportCadastrosDemoPackage (P3)
│   ├── esus-download.ts            # NEW — buildFilename, triggerJsonDownload
│   ├── conferencia-rules.ts        # EXISTING — reutilizar detectInconsistencias
│   └── __tests__/
│       ├── esus-export.test.ts     # NEW
│       └── esus-cadastros-export.test.ts
├── schemas/
│   ├── esus-fai.schema.ts          # NEW — Zod EsusFaiPayload + extensions
│   └── __tests__/esus-fai.schema.test.ts
├── components/
│   ├── EsusExportSheet.tsx         # NEW — preview JSON + download + missing list
│   └── EsusExportButton.tsx        # NEW — gate status + open sheet
├── api/
│   ├── exames-relatorio.ts         # READ — lookup exames por consultaId
│   └── types.ts                    # EXISTING — ConsultaExportRefs
├── pages/
│   ├── ConsultaDetailPage.tsx      # MODIFY — substituir toast por EsusExportButton
│   └── SaudeConferenciaPage.tsx    # MODIFY (P2) — ação export rápida se pronto_envio
└── data/seed.ts                    # READ — consulta seed completa para snapshot
```

**Structure Decision**: Extensão incremental do módulo `saude/` entregue na spec 024. Nenhum novo módulo NestJS. Contratos espelham arquivado `024/.../esus-fai-export.md` com extensões documentadas em artefato próprio.

## Complexity Tracking

> Nenhuma violação constitucional que exija justificativa.

## Phase Summary

| Phase | Entregável | Status |
|-------|------------|--------|
| 0 | `research.md` — 10 decisões (mapper, UI, gate, extensões, lote) | ✅ |
| 1 | `data-model.md`, `contracts/*`, `quickstart.md` | ✅ |
| 2 | `tasks.md` via `/speckit-tasks` | Pendente |
