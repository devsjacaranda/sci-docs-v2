# Research: Insights Cedro — Ouvidoria

**Feature**: 007-ouvidoria-cedro-insights · **Date**: 2026-06-19

## R1 — Agregação sem IA

**Decision**: Regras determinísticas em `lib/aggregation/` — SQL/Prisma para volume e joins; TypeScript puro para top-N de termos (split whitespace, lowercase, stopwords mínimas PT, min length 3).

**Rationale**: Spec exige sem NLP/ML/embeddings (FR-013). Funções puras facilitam unit tests sem DB.

**Alternatives considered**:

- LLM para resumos → rejeitado (out of scope)
- Full-text search PostgreSQL → rejeitado na v2 (complexidade; contagem simples suficiente)

---

## R2 — Persistência de lotes e histórico

**Decision**: Três tabelas Prisma (`OuvidoriaInsightBatch`, `OuvidoriaInsight`, `OuvidoriaInsightEvidence`) com JSON para `reasoningSteps` e metadados de rastreio.

**Rationale**: FR-005, FR-009 exigem histórico consultável e comparação de gerações. JSON evita schema rígido para passos de raciocínio.

**Alternatives considered**:

- Calcular sempre on-the-fly sem persistir → rejeitado (spec exige híbrido + histórico)
- Event sourcing → rejeitado (over-engineering)

---

## R3 — Job agendado

**Decision**: `@nestjs/schedule` com `@Cron` diário (default 02:00 UTC, configurável via env `INSIGHTS_CRON`).

**Rationale**: FR-006; padrão NestJS; sem infra extra (Redis/Bull) na v2.

**Alternatives considered**:

- BullMQ + Redis → rejeitado (infra extra)
- Trigger só manual → rejeitado (spec exige agenda)

**Teste sem banco extra**: job testado com unit mock de `GenerateInsightsUseCase`; integração com `SchedulerRegistry` mockado.

---

## R4 — Throttling recálculo (1h/tenant)

**Decision**: Consultar último lote com `origin = on_demand` nas últimas 60 min; se existe, retornar `429` com código `INSIGHTS_THROTTLED` e body com `retryAfterSeconds`.

**Rationale**: FR-008; implementação simples sem Redis.

**Alternatives considered**:

- Throttle em memória → rejeitado (multi-instance inconsistente); persistência de lotes já resolve

---

## R5 — Fonte de dados para agregação

**Decision**: Query manifestações `status != draft`, `deletedAt IS NULL`, `createdAt` na janela de 90 dias; incluir `eventos`, `address` + `municipio` via join.

**Rationale**: Alinhado a Assumptions da spec; tempos entre eventos `registration` → `forwarding` → `response` → `closure`.

**Alternatives considered**:

- Incluir drafts → rejeitado (spec: apenas confirmadas)

---

## R6 — Submódulo vs extensão de `ouvidoria`

**Decision**: `modules/ouvidoria-insights/` importado em `OuvidoriaModule` ou `AppModule` — controller separado, rotas `/ouvidoria/insights/*`.

**Rationale**: Agregação + job + persistência são domínio distinto da CRUD; mantém use-cases ouvidoria pequenos.

**Alternatives considered**:

- Tudo em `ouvidoria.service.ts` legado → rejeitado (viola arquitetura use-case/repository)

---

## R7 — Client: página vs ScreenPage mock

**Decision**: `OuvidoriaInsightsPage` lazy em `modules/ouvidoria`; registrar em `router.tsx` para `ouvidoria-insights` screenId; remover render mock de `CedroModulePanel` nessa rota.

**Rationale**: Feature substitui mock Cedro para ouvidoria (plan spec).

---

## R8 — Estratégia de testes sem banco extra

**Decision**: Matriz completa com mocks — Prisma `jest.fn()`, fixtures JSON, MSW, store in-memory em `*.integration-spec.ts`; **sem** `ci_api_v2_test` Postgres.

**Rationale**: Requisito explícito do usuário; alinhado ao padrão atual `ouvidoria.e2e-spec.ts`.

**Alternatives considered**:

- Postgres de teste → rejeitado pelo usuário
- Playwright browser E2E → rejeitado na v2 (sem tooling); jornada UI via Vitest + RTL documentada como E2E simulado

---

## R9 — Rastreabilidade UI

**Decision**: Reutilizar padrão `TraceabilityTrigger` / sheet do shell; payload Cedro sem `externalQueries` — só `reasoningSteps`, `records`, `analysisWindow`.

**Rationale**: R-40 regras-plataforma; traceability-mock ouvidoria será substituído por payload API.

---

## R10 — Impacto Crítico / Alto / Médio

**Decision**: Heurísticas em `insight-impact.ts` — ex.: backlog &gt; 30% do volume → Alto; termo “prazo” em top-5 com crescimento &gt; 20% vs período anterior → Médio; denúncias urgentes &gt; 2× média → Crítico.

**Rationale**: FR-003; thresholds ajustáveis; testados em unit.

**Alternatives considered**:

- Impacto fixo por categoria → rejeitado (menos útil para gestor)
