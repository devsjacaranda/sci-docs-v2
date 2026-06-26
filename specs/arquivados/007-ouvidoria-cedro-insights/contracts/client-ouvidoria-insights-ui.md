# Contract: Client UI — Ouvidoria Insights Cedro

**Feature**: 007-ouvidoria-cedro-insights  
**Route**: `/ouvidoria/insights`  
**Screen ID**: `ouvidoria-insights`  
**Licença**: Cedro — badge **Somente leitura**

## Navegação

| Origem | Destino | Cliques (SC-001) |
|--------|---------|------------------|
| `/ouvidoria` overview | Card *Insights & IA* | 1 |
| Shell nav | *Insights IA* | 1–2 |

Registrar lazy route em `app/router.tsx` — **substituir** render mock `ScreenPage` + `CedroModulePanel` para este screenId.

---

## Layout da página

### Header

| Elemento | Conteúdo |
|----------|----------|
| Título | Insights Cedro — Sentimento, benchmark de satisfação *(cedroFocus ouvidoria)* |
| Subtítulo | Licença Cedro: insights estratégicos consultivos (read-only) — análise de dados internos de manifestações. |
| Badge | **Somente leitura** (nunca *Read-only*) |

### Stats row (opcional)

| Label | Fonte |
|-------|-------|
| Insights ativos | `insights.length` do batch atual |
| Última geração | `batch.generatedAt` formatado |
| Impacto alto | count `impact === high \| critical` |
| Natureza | Read-only / Cedro |

### Seção principal — lista de insights

Componente `InsightCard` para cada item:

| Campo UI | API field |
|----------|-----------|
| Título | `title` |
| Impacto chip | `impactLabel` (Crítico/Alto/Médio) |
| Fonte | `sourceLabel` — sempre *Dados internos — Ouvidoria* |
| Resumo | `summary` |
| Recomendação | `recommendation` (itálico, muted) |
| Ação | *De onde veio este insight?* → abre sheet |

### Ação primária Cedro

| Label | Comportamento |
|-------|---------------|
| **Consultar IA** | `POST /ouvidoria/insights/generate`; loading state; toast sucesso ou throttle 429 |

Copy do diálogo: *Análise consultiva de dados internos — nenhum registro será alterado.*

### Histórico

`InsightsHistoryPanel`: lista de `GET /ouvidoria/insights/batches`; clique abre comparação (batch detail). Mínimo 2 gerações anteriores visíveis quando existirem (SC-004).

### Estado vazio

| `emptyReason` | Mensagem |
|---------------|----------|
| `no_data` | Registre manifestações confirmadas para habilitar insights. |
| `insufficient_volume` | Dados insuficientes no período — continue operando a ouvidoria. |
| `never_generated` | Acione *Consultar IA* para a primeira análise. |

CTA: **Consultar IA** quando aplicável.

---

## Sheet de rastreio (`InsightTraceSheet`)

- Abertura: ~85% viewport height (R-40)
- Título sheet: **De onde veio este insight**
- Conteúdo: `GET /ouvidoria/insights/:id/trace`
- Seções: passos de raciocínio (lista ordenada), período analisado, protocolos de exemplo com link a `/ouvidoria/manifestacoes/:id` quando `manifestacaoId` presente
- **Sem** seção de integrações externas
- Badge **Somente leitura** no header do sheet

---

## IDs de contrato UI (testes componente/E2E)

| ID | Componente | Caso |
|----|------------|------|
| CMP-INS-001 | Page | render com insights mock MSW |
| CMP-INS-002 | Page | estado vazio `no_data` |
| CMP-INS-003 | InsightCard | impacto + fonte interna |
| CMP-INS-004 | TraceSheet | abre com reasoningSteps |
| CMP-INS-005 | TraceSheet | sem externalQueries no DOM |
| CMP-INS-006 | History | lista ≥ 2 batches |
| CMP-INS-007 | Consultar IA | POST generate + refresh |
| CMP-INS-008 | Consultar IA | 429 mostra mensagem throttle |
| CMP-INS-009 | Page | badge Somente leitura visível |

---

## Copy a ajustar (overview)

[`OuvidoriaOverviewPage.tsx`](../../../ci-client-v2/apps/web/src/modules/ouvidoria/pages/OuvidoriaOverviewPage.tsx): evitar prometer “IA generativa”; manter *Insights IA* como branding Cedro.

---

## Dependências UI

- `@ci/ui` — Card, Badge, Button, Sheet
- `modules/shell/components/TraceabilityTrigger` ou sheet dedicado com mesmo layout
- Paleta mint — rule `mint-palette.mdc`
