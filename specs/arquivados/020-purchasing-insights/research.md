# Research: Insights IA Cedro — Purchasing

**Feature**: 020-purchasing-insights · **Date**: 2026-06-25

## R1 — Escopo: novo submódulo vs mock

**Decision**: Criar submódulo **`compras-insights`** (API + Prisma + client page) — **substituir** mock `CedroModulePanel` na rota `compras-insights`.

**Rationale**: Zero implementação real hoje; spec 018 entrega fontes de dados (`CompraDemanda`, artefatos, `estimatedValue`); padrão estabelecido por Ouvidoria (007) e Gabinete (015).

**Alternatives considered**:

- Estender `compras.controller.ts` com rotas insights → rejeitado (licença Cedro exige submódulo isolado)
- Manter mock até integração PNCP real → rejeitado (spec exige agregações reais + simulação explícita)

---

## R2 — Fontes de dados internas

**Decision**: Loader `LoadComprasAnalysisDataRepository` retorna:

```typescript
interface ComprasAnalysisData {
  demandas: DemandaForAnalysis[];  // CompraDemanda + pca + artefatos + derived status/progress
  windowStart: Date;
  windowEnd: Date;
}
```

Cada `DemandaForAnalysis` inclui campos derivados via funções puras de `compras.mapper.ts` (`deriveDemandaStatus`, `deriveProgress`, `buildChecklist`, `countSatisfiedArtefacts`).

Filtro: `deletedAt IS NULL`, `createdAt` na janela de 90 dias (`ANALYSIS_WINDOW_DAYS`).

**Rationale**: FR-001; status não é coluna Prisma — reutilizar derivação existente evita divergência listagem ↔ insights.

**Alternatives considered**:

- Persistir status em coluna para insights → rejeitado (018 define derivação; duplicaria fonte de verdade)
- Janela ilimitada → rejeitado (padrão Cedro 90d; performance)

---

## R3 — Regras de agregação (determinísticas)

**Decision**: Arquivos em `lib/aggregation/`:

| Arquivo | Slugs | Fonte |
|---------|-------|-------|
| `operational.rules.ts` | `demand_volume_by_status`, `demand_concentration_by_pca`, `demand_artefact_backlog` | demandas + status derivado + PCA + checklist |
| `pricing.rules.ts` | `demand_value_above_median`, `demand_missing_price_survey` | `priceSurvey.estimatedValue` |
| `external.rules.ts` | `external_price_reference`, `external_value_divergence`, `external_similar_suppliers` | objeto + simulador PNCP + valor interno |

Orquestrador `aggregateComprasInsights(data, window)`; cada regra retorna `null` se volume &lt; `MIN_RECORDS_PER_DIMENSION` (5), exceto regras externas por objeto (≥ 1 demanda com objeto ≥ 10 chars).

**Rationale**: FR-001, FR-003, US-3; funções puras testáveis; sem LLM (Assumptions spec).

**Alternatives considered**:

- ML preditivo → rejeitado (out of scope)
- Uma regra monolítica → rejeitado (testabilidade)

---

## R4 — Simulador PNCP/COMPRASNET

**Decision**: `lib/external/pncp-simulator.ts` — função pura determinística:

```typescript
interface PncpSimulatedResult {
  objectQuery: string;
  medianReferencePrice: number;
  priceRangeMin: number;
  priceRangeMax: number;
  similarContractsCount: number;
  similarSuppliers: Array<{ name: string; contractCount: number }>;
  confidence: 'high' | 'low';
  simulated: true;
  sources: ['PNCP', 'COMPRASNET'];
}
```

- Seed: hash FNV-1a do objeto normalizado (trim, lowercase)
- Preço referência: se `estimatedValue` disponível, ±15–35% determinístico pelo hash; senão faixa absoluta por keywords (TI, serviços, obras)
- Fornecedores: lista fixa de 8 nomes fictícios institucionais (sem CPF/CNPJ reais)
- Objeto &lt; 10 chars ou vazio: `confidence: low` + insight orientando refinamento — **sem** fabricar contratos específicos (edge case spec)
- Sempre `simulated: true`; labels UI *Dados simulados — MVP*

**Rationale**: FR-002, FR-003, SC-002; repetível em testes; copy honesta sobre ausência de integração real.

**Alternatives considered**:

- HTTP mock server → rejeitado (complexidade desnecessária)
- Valores aleatórios não determinísticos → rejeitado (testes flaky)

---

## R5 — Categorias analíticas (enum)

**Decision**: Estender enum Prisma `InsightCategory`:

| Value EN | UI PT-BR | Uso Compras |
|----------|----------|-------------|
| `operational` | Operacional | status, PCA, backlog |
| `pricing` | Valores e preços | mediana, pesquisa ausente |
| `external_benchmark` | Referência externa (simulada) | PNCP/COMPRASNET |

**Rationale**: FR-005 fonte interna/externa/híbrida; filtros e badges consistentes; migration additive.

**Alternatives considered**:

- Reutilizar só `operational` → rejeitado (UX de categoria e SC de fonte)
- String livre → rejeitado (mapper inconsistente)

---

## R6 — Rastreio com consultas externas

**Decision**: Estender payload trace com `externalQueries` **opcional** (Compras only):

```typescript
externalQueries?: Array<{
  source: 'PNCP/COMPRASNET — simulado';
  objectQuery: string;
  medianReferencePrice: number;
  priceRange: { min: number; max: number };
  similarContractsCount: number;
  similarSuppliers: Array<{ name: string; contractCount: number }>;
  disclaimer: 'Dados simulados — MVP. Integração real não está ativa.';
}>;
```

Client: estender `InsightTraceSheet` + `CedroInsightTraceResponse` — seção renderizada apenas quando presente. Gabinete/Ouvidoria inalterados.

**Rationale**: FR-011, FR-012, US-5; backward-compatible.

---

## R7 — Job, throttle e geração ao abrir

**Decision**: Copiar padrão 007/015:

- Job `@Cron` diário `generate-insights-scheduled.job.ts`
- Throttle 1h só para `origin: on_demand` (`THROTTLE_MS = 3600000`)
- `on_open` opcional no client se `never_generated` (espelhar Gabinete)
- Conflito batch `running` → 409

**Rationale**: FR-006–FR-009; código referência maduro.

---

## R8 — Exportação de relatório (P2)

**Decision**: `GET /compras/insights/export` → `Content-Type: text/html; charset=utf-8` + `Content-Disposition: attachment; filename="insights-compras-{date}.html"`.

HTML print-friendly com: título, data geração, badge *Somente consultivo*, lista insights (impacto, recomendação, fonte), disclaimer PNCP simulado quando aplicável. Client: botão *Exportar relatório* → download blob.

**Rationale**: FR-015, SC-007; spec aceita *PDF ou equivalente*; repo não tem pdfkit; HTML imprimível como PDF via browser.

**Alternatives considered**:

- Adicionar pdfkit → rejeitado (nova dependência; escopo P2)
- JSON download → rejeitado (UX inferior para reuniões)

---

## R9 — Client: paridade Cedro shared

**Decision**: `ComprasInsightsPage` espelha `GabineteInsightsPage`:

| Prop shared | Valor Compras |
|-------------|---------------|
| `moduleId` | `compras` |
| `sourceLabel` interno | *Dados internos — Compras* |
| `sourceLabel` externo | *PNCP/COMPRASNET — simulado* |
| `detailPathPrefix` | `/compras` (demanda `/:id`) |
| `cedroFocus` | `moduleLicenseConfig.compras.cedroFocus` → *PNCP, preços de mercado* |

Router: override `'compras-insights'` → lazy `ComprasInsightsPage`.

**Rationale**: FR-016, SC-001; DRY; regressão Gabinete/Ouvidoria obrigatória.

---

## R10 — Mínimo estatístico e estados vazios

**Decision**:

- `MIN_RECORDS_PER_DIMENSION = 5` para agregações operacionais/pricing
- Tenant **sem demandas** → `emptyReason: no_data`; CTA orientador; **zero** insights fabricados
- Geração permitida com ≥ 1 demanda; `insightCount` pode ser 0 com `insufficient_volume`
- Demanda sem Pesquisa de Preços: regras de valor omitidas — **não** inventam `estimatedValue`

**Rationale**: FR edge cases; Assumptions spec.

---

## R11 — Estratégia de testes

**Decision**: Matriz idêntica a 015 — CT-COM-INS-001…012 (API), CT-COM-UI-001…008 (client); simulador PNCP com casos objeto curto/longo/sem valor.

**Rationale**: Constitution II.

---

## R12 — Seed demo

**Decision**: Estender seed Jacaranda (018) — demandas DEAE com objetos variados, Pesquisas de Preços preenchidas, status mistos — suficientes para ≥ 3 categorias após generate.

**Rationale**: quickstart manual; dev experience.
