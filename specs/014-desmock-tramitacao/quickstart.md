# Quickstart: Validação Desmock Tramitação

**Feature**: 014-desmock-tramitacao  
**Prerequisites**: Node.js 20+, PostgreSQL, Wasabi/MinIO, `.env` em `ci-api-v2`  
**References**: [data-model.md](./data-model.md) · [contracts/](./contracts/) · [spec.md](./spec.md)

> Executar **após** implementação (`/speckit-implement`).

## Setup

```powershell
cd ci-api-v2
npm install
npx prisma migrate dev
npx prisma db seed   # demandas tramitacao demo + perguntas fiscalização/maturidade

npm run start:dev
```

```powershell
cd ci-client-v2
npm install
npm run dev
```

**Expected**: API `:3000`; client `:5173`; tenant Jacaranda com módulo `tramitacao` (OPEN); seed ≥8 demandas demo (genéricas + linked).

---

## VS-001 — Módulo aberto (US1)

| Step | Action | Expected |
|------|--------|----------|
| 1 | Login usuário qualquer setor autenticado | JWT OK |
| 2 | GET `/tramitacao/demandas?folder=received` | 200 |
| 3 | Client `/tramitacao/demandas` | inbox sem dados mock shell |

---

## VS-002 — Compor demanda genérica (US1)

| Step | Action | Expected |
|------|--------|----------|
| 1 | POST `/tramitacao/demandas` targetSector+subject+body | 201 `TRAM-2026-NNNN` |
| 2 | GET `?folder=sent` setor remetente | demanda listada |
| 3 | GET `?folder=received` setor destino | demanda listada |
| 4 | Client `/tramitacao/demandas/novo` | fluxo completo < 60s |

---

## VS-003 — Linked record Gabinete (US2, US9)

| Step | Action | Expected |
|------|--------|----------|
| 1 | POST `/gabinete/cabinets/:id/forward` com setor destino | 200 |
| 2 | GET `/tramitacao/demandas/:tramitacaoId` | `sourceModule=gabinete`, snapshot presente |
| 3 | Alterar ato gabinete original | snapshot tramitacao **inalterado** |

---

## VS-004 — Responder e encaminhar (US3)

| Step | Action | Expected |
|------|--------|----------|
| 1 | POST `/tramitacao/demandas/:id/reply` | evento reply na timeline |
| 2 | POST `/tramitacao/demandas/:id/forward` | novo setor em received; histórico completo |
| 3 | POST `/tramitacao/demandas/:id/archive` | folder archived |

---

## VS-005 — Dashboard (US4)

| Step | Action | Expected |
|------|--------|----------|
| 1 | GET `/tramitacao/dashboard` | KPIs reais |
| 2 | GET `?periodDays=30` | KPIs recalculados |
| 3 | Client `/tramitacao/dashboard` | gráfico bySourceModule |

---

## VS-006 — Fiscalização Jatobá (US5)

| Step | Action | Expected |
|------|--------|----------|
| 1 | Criar demanda prazo vencido | — |
| 2 | POST `/tramitacao/fiscalizacao/runs` | 202 |
| 3 | GET `/tramitacao/fiscalizacao` | achado SLA non_conforme |
| 4 | Client `/tramitacao/auditoria` | panel sem licença → 403 sheet |

---

## VS-007 — Insights Cedro (US6)

| Step | Action | Expected |
|------|--------|----------|
| 1 | POST `/tramitacao/insights/runs` | batch completed |
| 2 | GET `/tramitacao/insights` | gargalos + volume módulo |
| 3 | Repetir run | resultados determinísticos |

---

## VS-008 — Maturidade Carvalho (US7)

| Step | Action | Expected |
|------|--------|----------|
| 1 | POST autoavaliacao | 200 |
| 2 | GET `/tramitacao/maturidade` | score hybrid 60/40 |
| 3 | POST plano-acao eixo deficiente | 201 |

---

## VS-009 — Alertas licença (US8)

| Step | Action | Expected |
|------|--------|----------|
| 1 | Tenant só Base tramitacao | alert bar upgrade Jatobá/Cedro/Carvalho |
| 2 | Clicar auditoria bloqueada | sheet licença necessária |

---

## VS-010 — Integração Ouvidoria (US10)

| Step | Action | Expected |
|------|--------|----------|
| 1 | POST `/ouvidoria/manifestacoes/:id/encaminhar` | 200 |
| 2 | GET tramitacao demanda | `sourceModule=ouvidoria` |

---

## VS-011 — Integração Jurídico (US11)

| Step | Action | Expected |
|------|--------|----------|
| 1 | POST `/juridico/processos/:id/tramitar` | 200 |
| 2 | GET tramitacao demanda | `sourceModule=juridico` |

---

## VS-012 — Edge cases

| Step | Action | Expected |
|------|--------|----------|
| 1 | POST compose same sector | 400 `SAME_SECTOR` |
| 2 | POST forward archived | 409 `DEMANDA_ARCHIVED` |
| 3 | POST compose invalid sector | 400 |

---

## Build gate

```powershell
cd ci-api-v2; npm test -- tramitacao; npm run test:e2e -- --testPathPattern=tramitacao
cd ci-client-v2; npm run build
```

**Expected**: todos testes verdes; build sem erro; zero referência `tramitacao-mock.ts` em rotas ativas.
