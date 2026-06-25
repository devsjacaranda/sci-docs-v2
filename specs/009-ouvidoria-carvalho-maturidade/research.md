# Research: Maturidade Carvalho — Ouvidoria

**Feature**: 009-ouvidoria-carvalho-maturidade · **Date**: 2026-06-19

## R1 — Fórmula híbrida R-50

**Decision**: Função pura `computeHybridAxisScore(selfAssessment: number, jatobaConformity: number | null): HybridScoreResult` em `lib/hybrid-score.ts`. Quando `jatobaConformity === null`, retorna `{ score: selfAssessment, partialSource: true }`. Caso contrário `round(0.6 * self + 0.4 * jatoba)`.

**Rationale**: Regra de plataforma canônica (R-50); testável sem DB; FR-003 proíbe score sem autoavaliação — caller valida presença de submissão antes de invocar.

**Alternatives considered**:

- Score só com indicadores operacionais → rejeitado (FR-003, FR-008)
- Peso configurável na v1 → rejeitado (Out of Scope spec)

---

## R2 — Mapeamento Jatobá → eixos Carvalho

**Decision**: Mapa fixo em `lib/jatoba-axis-map.ts`:

| ruleId | Eixo |
|--------|------|
| `JAT-OUV-PRZ-001` | `controle_interno` |
| `JAT-OUV-TRM-001` | `controle_interno` |
| `JAT-OUV-CMP-001` | `controle_interno` |
| `JAT-OUV-CNT-001` | `governanca` |
| `JAT-OUV-EVD-001` | `tecnologia_informacao` |

Taxa por eixo: por manifestação, pior status entre checagens do eixo; `conforme=100%`, `partial=50%`, `pending|non_conforme=0%`; média sobre manifestações fiscalizadas.

**Rationale**: Alinhado a Assumptions da spec; ruleIds já existem em `ouvidoria-fiscalizacao.types.ts`.

**Alternatives considered**:

- Usar contadores agregados do Run (conformeCount etc.) → rejeitado (não discrimina por eixo)
- Duplicar checagens Jatobá no módulo Carvalho → rejeitado (viola fronteira licenças)

---

## R3 — Persistência de snapshots vs cálculo on-the-fly

**Decision**: Persistir `OuvidoriaMaturidadeScoreSnapshot` ao **submeter/atualizar autoavaliação** e ao **detectar nova execução Jatobá completed** (hook leve no GET dashboard: se run mais recente > snapshot, recalcular e upsert). Histórico temporal lê snapshots ordenados por período.

**Rationale**: SC-009 exige ≥ 2 pontos no gráfico; evita recalcular histórico inteiro a cada GET; snapshots imutáveis por período após encerramento.

**Alternatives considered**:

- Só on-the-fly sem persistir → rejeitado (performance + histórico)
- Snapshot diário via cron → rejeitado (desnecessário na v1; event-driven suficiente)

---

## R4 — Períodos de autoavaliação

**Decision**: Entidade `OuvidoriaMaturidadePeriod` com `startsAt`, `endsAt`, `status` (`open` | `closed`). Job ou use-case `EnsureCurrentPeriodUseCase` cria trimestre corrente se ausente (Jan–Mar, Abr–Jun, Jul–Set, Out–Dez). Config tenant `assessmentFrequency` enum (default `quarterly`).

**Rationale**: FR-009 periodicidade trimestral; histórico por período; permite encerrar período sem resposta (score indisponível).

**Alternatives considered**:

- Período rolling 90 dias → rejeitado (spec diz trimestral)
- Sem entidade período (só timestamp submissão) → rejeitado (evolução temporal imprecisa)

---

## R5 — Nota de autoavaliação por eixo

**Decision**: Perguntas quantificáveis (`scale_1_5`, `yes_no` → 0/100) com `weight` Int; nota eixo = média ponderada normalizada 0–100. Perguntas `text` não entram no score (só qualitativo no rastreio).

**Rationale**: Tipos alinhados a Jatobá (`QuestionAnswerType`); pesos permitem perguntas de satisfação com peso distinto.

**Alternatives considered**:

- Todas perguntas iguais → rejeitado (satisfação vs processo têm pesos diferentes)
- Escala 0–10 → rejeitado (inconsistente com Jatobá 1–5)

---

## R6 — Indicadores operacionais

**Decision**: Calculados on-the-fly em `GetMaturidadeDashboardUseCase` via funções puras + repositories read-only. Janela padrão 90 dias ou alinhada ao período vigente (o que for mais amplo).

| Indicador | Implementação |
|-----------|---------------|
| Volume | `count(manifestacao)` confirmadas no período |
| Tempo médio resposta | média dias entre confirmação e primeiro evento `response` |
| Prazos vencidos | % results com check `JAT-OUV-PRZ-001` = `non_conforme` / total último run |
| Taxa resolução | `closed` / confirmadas × 100 |
| Satisfação | `round(0.5 * jatobaExt + 0.5 * carvalhoSat)` ou fonte única |

**Rationale**: FR-008 — indicadores contextualizam, não compõem score; reutiliza dados existentes.

**Alternatives considered**:

- Persistir indicadores → rejeitado (over-engineering; deriváveis)

---

## R7 — Satisfação híbrida e Jatobá externo

**Decision**: Query `OuvidoriaFiscalizacaoAnswer` join questionnaire onde `channel IN (whatsapp, email)` e `answerType = scale_1_5` no período. Se questionários externos **não implementados** (stub 008), retorna `null` para componente Jatobá — indicador usa só autoavaliação com `partialSource: true` (graceful degradation).

**Rationale**: Spec assume Jatobá implementada mas questionários externos ainda stub; não bloqueia entrega Carvalho.

**Alternatives considered**:

- Mock satisfação Jatobá → rejeitado (FR-022 substituir mocks)
- Bloquear feature até questionários → rejeitado (usuário confirmou degradação elegante)

---

## R8 — Submódulo vs extensão

**Decision**: `modules/ouvidoria-maturidade/` registrado em `AppModule` — controller `/ouvidoria/maturidade/*`, separado de `ouvidoria`, `ouvidoria-insights`, `ouvidoria-fiscalizacao`.

**Rationale**: Domínio distinto (score + autoavaliação + planos); espelha padrão 007/008.

**Alternatives considered**:

- Dentro de `ouvidoria.module` → rejeitado (viola SRP use-case/repository)

---

## R9 — Planos de ação e autorização

**Decision**: CRUD restrito a mesma role que `ResponderManifestacaoUseCase` / `EncerrarManifestacaoUseCase` (gestor ouvidoria) — reutilizar guard ou decorator `@RequireOuvidoriaGestor()` se existir; senão `@Roles('gestor')` + módulo ouvidoria.

**Rationale**: Assumptions spec; demais usuários leem dashboard.

**Alternatives considered**:

- CRUD para todos autenticados → rejeitado (Assumptions)

---

## R10 — Client: Nivo radar + line

**Decision**: `@nivo/radar` para 3 eixos; `@nivo/line` para evolução temporal. Lazy import nos componentes chart (padrão `DashboardCharts.tsx`). Meta 80% como `ReferenceLine` / custom layer.

**Rationale**: Stack canônica Nivo; skill ui-ux-pro-max; evita mock `CarvalhoMaturityPanel`.

**Alternatives considered**:

- Recharts → rejeitado (projeto usa Nivo)
- Manter barras CSS do mock → rejeitado (spec exige radar)

---

## R11 — Integração alertas licença

**Decision**: `GET /ouvidoria/maturidade` retorna `overallAlert: 'critical' | 'warning' | null`; client `license-alerts.ts` consome endpoint leve ou campo embutido no dashboard fetch para chip Carvalho (R-64/R-65).

**Rationale**: SC-010; substituir mock `maturityByModule`.

**Alternatives considered**:

- Calcular alerta só no client → rejeitado (fonte única API)

---

## R12 — Testes sem banco extra

**Decision**: Mesmo padrão 007/008 — Prisma mock, fixtures JSON, MSW, Supertest e2e com deps mockadas.

**Rationale**: Constitution II; quickstart reproduzível em CI.

**Alternatives considered**:

- Testcontainers Postgres → rejeitado (proibido pelo projeto)
