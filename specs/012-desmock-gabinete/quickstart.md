# Quickstart: Validação Desmock Gabinete

**Feature**: 012-desmock-gabinete  
**Prerequisites**: Node.js 20+, PostgreSQL, Wasabi/MinIO, `.env` em `ci-api-v2`  
**References**: [data-model.md](./data-model.md) · [contracts/](./contracts/) · [spec.md](./spec.md)

> Executar **após** implementação (`/speckit-implement`).

## Setup

```powershell
cd ci-api-v2
npm install
npx prisma migrate dev
npx prisma db seed   # inclui setor Gabinete + demandas demo Jacaranda

npm run start:dev
```

```powershell
cd ci-client-v2
npm install
npm run dev
```

**Expected**: API `:3000`; client `:5173`; tenant Jacaranda com módulo `gabinete` vinculado ao setor Gabinete; seed ≥10 demandas demo.

---

## VS-001 — Permissão módulo (US5)

| Step | Action | Expected |
|------|--------|----------|
| 1 | Login usuário setor Gabinete | JWT OK |
| 2 | GET `/gabinete/demandas` | 200 |
| 3 | Login usuário sem vínculo | JWT OK |
| 4 | GET `/gabinete/demandas` | 403 `MODULO_SETOR_DENIED` |

---

## VS-002 — Criar demanda com protocolo e anexo (US1)

| Step | Action | Expected |
|------|--------|----------|
| 1 | POST `/gabinete/demandas` subject+description | 201 `protocolNumber` |
| 2 | POST presign anexo PDF | 200 uploadUrl |
| 3 | PUT storage + confirm | 200 |
| 4 | GET `/gabinete/demandas/:id` | anexo listado |

Client: `/gabinete/demandas/novo` — fluxo completo.

---

## VS-003 — Lista e filtros (US2)

| Step | Action | Expected |
|------|--------|----------|
| 1 | GET `/gabinete/demandas?status=in_analysis` | só matching |
| 2 | GET `?q=GAB-2026` | localiza protocolo |
| 3 | Client lista | zero linhas mock PORT-142 |

---

## VS-004 — Tramitar stub (US4)

| Step | Action | Expected |
|------|--------|----------|
| 1 | POST `/gabinete/demandas/:id/forward` | 200 |
| 2 | GET detalhe | forwarding + timeline |
| 3 | GET `/tramitacao/demandas` | **sem** novo item |

---

## VS-005 — Controles opcionais (US6–US8)

| Step | Action | Expected |
|------|--------|----------|
| 1 | POST controle numérico tipo portaria | 201 |
| 2 | POST notificação + auto mesmo groupId | 201 |
| 3 | POST documento tramitado **sem** setorId | 400 |
| 4 | POST documento tramitado com setorId | 201 |

---

## VS-006 — Dashboard (US9)

| Step | Action | Expected |
|------|--------|----------|
| 1 | GET `/gabinete/dashboard` | totals match DB count |
| 2 | Client `/gabinete/dashboard` | cards ≠ mock "86 atos" |

---

## VS-007 — Jatobá (US10)

| Step | Action | Expected |
|------|--------|----------|
| 1 | POST `/gabinete/fiscalizacao/runs` | 201 run |
| 2 | GET `/gabinete/fiscalizacao/panel` | conformidades 4 valores |
| 3 | Client auditoria | badge Somente leitura |

---

## VS-008 — Carvalho (US11)

| Step | Action | Expected |
|------|--------|----------|
| 1 | POST self-assessment período | 200 |
| 2 | GET `/gabinete/maturidade/dashboard` | scores ≠ mock 76% fixo |
| 3 | Sheet *Como calculamos* | duas fontes híbrido |

---

## VS-009 — Cedro (US12)

| Step | Action | Expected |
|------|--------|----------|
| 1 | POST `/gabinete/insights/runs` | batch completed |
| 2 | GET `/gabinete/insights/latest` | ≥1 insight fonte Gabinete |
| 3 | Trace sheet | regras determinísticas |

---

## Testes automatizados

```powershell
cd ci-api-v2; npm test -- gabinete
cd ci-client-v2/apps/web; npm run test -- gabinete
```

Ver [contracts/test-strategy.md](./contracts/test-strategy.md).
