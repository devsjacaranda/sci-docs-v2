# Implementation Plan: Timbrado oficial AGEMAN 2026

**Branch**: `046-timbrado-ageman-2026` | **Date**: 2026-09-15 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `civ2-docs/specs/046-timbrado-ageman-2026/spec.md`

## Summary

Trocar o timbrado **geral** do tenant AGEMAN no CI v2: um único núcleo de folha padrão 2026 (faixa oficial + marca d’água, A4 vertical, sem selo de módulo e sem rodapé) aplicado a todas as emissões institucionais cobertas — PDF **e** Word. A arte vem da `Folha padrão 2026 - Vertical.docx` (PNGs oficiais carimbados, não reconstruídos). Outros tenants mantêm o fallback atual. Se a arte faltar, o miolo sai sem cabeçalho e o operador é avisado (`X-Letterhead-Applied: 0`). Insights/Maturidade **que já exportam** (Compras) ganham ofício PDF+Word como caminho de ofício e **mantêm HTML extra**.

Abordagem: kernel em `ci-api-v2/src/common/letterhead/` + três adaptadores (PDFKit, pdf-lib, `docx`) + use-cases/rotas Word onde hoje só existe PDF + botões de download compartilhados no client.

## Technical Context

**Language/Version**: TypeScript 5.9+ (Node 22 / NestJS 11 na API; React 19 / Vite 8 no client)

**Primary Dependencies**:
- API: NestJS 11, Fastify, Zod (`nestjs-zod`), **PDFKit** (já usado em Ouvidoria/Diagnóstico/Gabinete), **pdf-lib** (já usado em Tramitação/ANPD), **docx** (já usado no dossiê de manifestação)
- Client: React 19, Tailwind v4, shadcn/ui — sem lib nova de PDF
- Arte: PNGs extraídos de `new-timbrado/Folha padrão 2026 - Vertical.docx` (`word/media/image2.png` faixa; `word/media/image1.png` brasão)

**Storage**: arquivos estáticos no build (`common/letterhead/assets/`) via `nest-cli.json`. **Nenhum modelo Prisma novo.** Emissões continuam on-demand (não persistem o ofício gerado).

**Testing**: Jest (`ci-api-v2`) + Vitest (`apps/web`) — TDD RED→GREEN→REFACTOR. Contratos em `contracts/test-strategy.md`.

**Target Platform**: API Fastify + SPA autenticada `@ci/web` (tenant AGEMAN em produção `ageman.controleinterno.org`; seed `00000000-0000-0000-0000-000000000002`)

**Project Type**: Web application (backend `ci-api-v2` + frontend `ci-client-v2/apps/web`) — sem pacote novo

**Performance Goals**: carimbar faixa + marca d’água em cada página não deve adicionar mais que ~300 ms em um ofício de até 20 páginas no ambiente de dev; geração continua síncrona no request (mesmo modelo de hoje)

**Constraints**:
- Só A4 vertical (folha oficial fornecida)
- Só tenant AGEMAN recebe a arte 2026
- Sem rodapé de sistema e sem selo de módulo
- Arte ausente → miolo + aviso; **nunca** voltar ao timbrado antigo
- Planilhas (SIGED/Excel) fora
- Insights/Maturidade sem botão de exportar hoje ficam fora

**Scale/Scope**: 8 famílias de ofício no tenant AGEMAN (manifestação, relatório de gestão, Diagnóstico painel/seleção, documento institucional, histórico Gabinete, dossiê Tramitação, ANPD, Compras Insights/Maturidade) × 2 formatos (PDF+Word), mais HTML extra em Compras

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Princípio | Avaliação |
|---|---|
| I. Spec-Driven Development | ✅ specify → clarify → **plan** (aqui) → tasks → implement |
| II. Test-First | ✅ TDD em kernel, adaptadores, use-cases novos e UI de download; ver `contracts/test-strategy.md` |
| III. Stack fixa | ✅ NestJS 11 / Fastify / Zod / PDFKit / pdf-lib / docx já na API; React 19 / Vite 8 / shadcn no client — **sem dependência nova** |
| IV. Multi-tenant e licenças | ✅ Gate de tenant no kernel (`isAgemanTenant`); `getRequestContext()` / `X-Tenant-ID`; demais tenants não recebem a arte |
| V. Clean code e modularidade | ✅ Kernel em `common/letterhead/` (1 arquivo = 1 operação); use-cases Word novos 1:1; client reutiliza `modules/shared/` para o menu de ofício |

**Gate**: ✅ Sem violações. Sem Complexity Tracking.

## Project Structure

### Documentation (this feature)

```text
civ2-docs/specs/046-timbrado-ageman-2026/
├── spec.md
├── plan.md              # este arquivo
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   ├── rest-api-letterhead.md
│   └── test-strategy.md
└── tasks.md             # /speckit-tasks — não criado aqui
```

### Source Code (repository root)

```text
ci-api-v2/src/common/letterhead/
├── ageman-tenant.ts                 # UUID canônico + isAgemanTenant()
├── official-page-metrics.ts         # A4 + margens da folha 2026
├── resolve-letterhead-assets.ts     # localiza faixa + brasão (src/dist)
├── apply-letterhead-pdfkit.ts       # carimbo PDFKit (todas as páginas)
├── apply-letterhead-pdf-lib.ts      # carimbo pdf-lib
├── apply-letterhead-docx.ts         # header + watermark no pacote docx
├── letterhead-result.ts             # { applied: boolean }
└── assets/
    ├── header-faixa.png             # crop oficial da faixa
    └── marca-dagua-brasao.png       # brasão

ci-api-v2/nest-cli.json              # + assets common/letterhead/assets/**

# Renderers existentes passam a chamar o kernel (AGEMAN) e removem arte antiga
ci-api-v2/src/modules/ouvidoria/lib/render-manifestacao-pdf.ts
ci-api-v2/src/modules/ouvidoria/lib/render-manifestacao-docx.ts
ci-api-v2/src/modules/ouvidoria/lib/render-relatorio-gestao-pdf.ts
ci-api-v2/src/modules/diagnostico/pdf/letterhead.service.ts
ci-api-v2/src/modules/gabinete/services/compose-historico-pdf.service.ts
ci-api-v2/src/modules/tramitacao/lib/protocolo-pdf-template.ts
ci-api-v2/src/modules/it-fiscalizacao/lib/anpd-pdf-template.ts

# Use-cases Word novos (1 arquivo = 1 operação) + rotas irmãs
ci-api-v2/src/modules/ouvidoria/use-cases/export-relatorio-gestao-docx.use-case.ts
ci-api-v2/src/modules/diagnostico/use-cases/generate-dashboard-docx.use-case.ts
ci-api-v2/src/modules/diagnostico/use-cases/generate-selecao-docx.use-case.ts
ci-api-v2/src/modules/documento-institucional/use-cases/generate-documento-docx.use-case.ts
ci-api-v2/src/modules/gabinete/use-cases/generate-historico-docx.use-case.ts
ci-api-v2/src/modules/tramitacao/use-cases/export-protocolo-docx.use-case.ts
ci-api-v2/src/modules/it-fiscalizacao/use-cases/generate-anpd-docx.use-case.ts
ci-api-v2/src/modules/compras-insights/use-cases/export-insights-oficio-pdf.use-case.ts
ci-api-v2/src/modules/compras-insights/use-cases/export-insights-oficio-docx.use-case.ts
ci-api-v2/src/modules/compras-maturidade/use-cases/export-maturidade-oficio-pdf.use-case.ts
ci-api-v2/src/modules/compras-maturidade/use-cases/export-maturidade-oficio-docx.use-case.ts

ci-client-v2/apps/web/src/modules/shared/lib/letterhead-download.ts
ci-client-v2/apps/web/src/modules/shared/components/OficioExportMenu.tsx
# Telas que hoje baixam PDF/HTML passam a usar o menu (PDF + Word [+ HTML extra])
```

**Structure Decision**: o timbrado é **transversal**, não um domínio — vive em `common/letterhead/` (mesmo papel de `resolve-user-table-id`). Cada módulo de domínio só orquestra miolo + chama o kernel. Word novo = use-case novo (constitution V). UI de download compartilhada em `modules/shared/` para um único aviso de arte ausente.

## Complexity Tracking

> Nenhum item — Constitution Check passou sem violações.

## Post-Phase 1 Constitution Check (re-avaliação)

✅ Sem violações novas. O desenho (`common/letterhead/`, adaptadores nas stacks já usadas, use-cases Word 1:1, zero Prisma, header HTTP em vez de envelope JSON) respeita stack fixa, tenant via ALS e “1 arquivo = 1 operação”. A arte fica em assets de build, não em storage de negócio no navegador.
