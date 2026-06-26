# Contract: Client UI — Compras Maturidade (Carvalho)

**Feature**: 021-purchasing-maturidade  
**Route**: `/compras/maturidade`  
**Screen ID**: `compras-maturidade`  
**Licença**: Carvalho · **Badge**: Somente leitura (scores/indicadores)

Espelha [009 client-ouvidoria-maturidade-ui.md](../../arquivados/009-ouvidoria-carvalho-maturidade/contracts/client-ouvidoria-maturidade-ui.md) com adaptações Compras. Referência visual: `OuvidoriaMaturidadePage` — **sem** `ActionPlansPanel`.

---

## Roteamento

| Item | Valor |
|------|-------|
| Path | `/compras/maturidade` |
| Lazy | `LazyComprasMaturidadePage` |
| Override | `COMPRAS_OVERRIDES` em `modules/compras/index.ts` |
| Guard módulo | `useModuleAccess('compras')` |
| Guard licença | Carvalho — alerta padrão plataforma se ausente |

Substituir placeholder gerado em `license-screens.ts` / `ScreenPage` mock.

---

## Layout da página

### Header

- Título: **Maturidade**
- Subtítulo: *Autoavaliação de práticas de compras públicas*
- Badge: **Somente leitura**
- Ações: **Responder questionário** | **Exportar relatório** (disabled sem submission)

### Estados

| Estado | UI |
|--------|-----|
| `emptyReason: no_self_assessment` | Empty state convidando primeira autoavaliação — **sem** scores fabricados |
| Draft parcial | Banner *Continuar autoavaliação* + contador pendentes |
| Submitted | Dashboard completo |
| Licença expirada | Histórico consultável; botões submeter/export desabilitados + alerta licença |

---

## Componentes (reuso + novos)

### Reutilizar de `modules/ouvidoria/components/` (adaptar props dimensão)

| Componente | Adaptação |
|------------|-----------|
| `MaturidadeScoreCards` | 4 dimensões Compras + score global |
| `MaturidadeRadarChart` | Nivo radar — eixos PT-BR |
| `MaturidadeTimelineChart` | Evolução quando `history.length ≥ 2` |
| `MaturidadeTraceSheet` | Fórmula Conformidade híbrida |
| `MaturidadeIndicatorsRow` | 3 indicadores Compras |
| `SelfAssessmentDialog` | PATCH parcial + PUT submit; agrupado por dimensão |

### Novos em `modules/compras/components/maturidade/`

| Componente | Função |
|------------|--------|
| `MaturidadeOrientationsPanel` | Lista orientações por dimensão abaixo do patamar |
| `MaturidadeExportButton` | Abre HTML export em nova aba / print |

### **Não** incluir

- `ActionPlansPanel`, `ActionPlanDialog` — Out of Scope FR-015

---

## Copy e vocabulário (regras-plataforma)

| Contexto | Copy |
|----------|------|
| Domínio | **demanda/demandas** — nunca "processo" genérico |
| Sheet trace | **Como calculamos este score** |
| Intro trace | *Esta consulta não altera demandas nem artefatos.* |
| Orientações | Imperativo consultivo: *Implemente…*, *Padronize…*, *Revise…* |
| Export vazio | *Complete a autoavaliação antes de exportar o relatório.* |
| Conflito período | *Outra avaliação foi registrada neste período. A submissão mais recente prevalece.* |

---

## API client (`modules/compras/api/maturidade.ts`)

Funções espelhando REST:

- `fetchComprasMaturidadeDashboard()`
- `fetchComprasMaturidadeScoreTrace(periodId?)`
- `fetchComprasMaturidadeIndicatorTrace(type)`
- `fetchComprasMaturidadeSelfAssessment()`
- `patchComprasMaturidadeAnswers(answers)`
- `submitComprasMaturidadeSelfAssessment(answers)`
- `exportComprasMaturidadeReport(periodId?)` → blob HTML

Schemas Zod espelhando [rest-api-compras-maturidade.md](./rest-api-compras-maturidade.md).

Mappers: `maturidade-mappers.ts`, `maturidade-chart-adapters.ts` (paridade ouvidoria).

---

## Paleta e acessibilidade

Seguir `mint-palette.mdc`:

- Fundo/cards conforme tema claro/escuro
- CTA primário: Deep Teal (claro) / Mint (escuro)
- Alertas: `critical` / `attention` com contraste WCAG
- Gráficos Nivo: cores da paleta Mint

---

## MSW e fixtures

- Handler: `test/msw/handlers/compras-maturidade.ts`
- Fixtures: `fixtures/maturidade-dashboard-{full,empty,draft}.json`
- Registrar em `test/msw/handlers/index.ts`

---

## Testes client (ver test-strategy.md)

- `ComprasMaturidadePage.integration.test.tsx` — estados empty/submitted/draft
- `ComprasMaturidadePage.e2e.test.tsx` — jornada questionário → score → orientações
- `maturidade.contract.test.ts` — Zod vs fixtures
