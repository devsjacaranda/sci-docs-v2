# Quickstart: Validação Desmock Jurídico

**Feature**: 012-desmock-juridico  
**Prerequisites**: Node.js 20+, PostgreSQL, Wasabi/MinIO, `.env` em `ci-api-v2`  
**References**: [data-model.md](./data-model.md) · [contracts/](./contracts/) · [spec.md](./spec.md)

> Executar **após** implementação (`/speckit-implement`).

## Setup

```powershell
cd ci-api-v2
npm install
npx prisma migrate dev
npx prisma db seed   # inclui setor DEJUR + processos demo Jacaranda

npm run start:dev
```

```powershell
cd ci-client-v2
npm install
npm run dev
```

**Expected**: API `:3000`; client `:5173`; tenant Jacaranda com módulo `juridico` vinculado ao setor DEJUR; seed ≥6 processos demo.

### Env Wasabi (dev)

```env
WASABI_ENDPOINT=http://127.0.0.1:9000
WASABI_REGION=us-east-1
WASABI_BUCKET=ci-anexos
WASABI_ACCESS_KEY=minioadmin
WASABI_SECRET_KEY=minioadmin
```

---

## VS-001 — Permissão módulo (US9)

| Step | Action | Expected |
|------|--------|----------|
| 1 | Login usuário setor DEJUR | JWT OK |
| 2 | GET `/juridico/processos` | 200 |
| 3 | Login usuário sem vínculo jurídico | JWT OK |
| 4 | GET `/juridico/processos` | 403 `MODULO_SETOR_DENIED` |

---

## VS-002 — Wizard + confirm (US1)

| Step | Action | Expected |
|------|--------|----------|
| 1 | POST `/juridico/processos` tipo judicial + partes | 201 rascunho |
| 2 | PATCH adicionar orgao + prazo | 200 |
| 3 | POST presign anexo PDF | 200 uploadUrl |
| 4 | PUT storage + confirm anexo | 200 |
| 5 | POST `/juridico/processos/:id/confirm` | 200 `numeroInterno` JUR-2026-NNNN |

Client: `/juridico/processos/novo` — fluxo 4 etapas completo.

---

## VS-003 — Lista e detalhe (US3)

| Step | Action | Expected |
|------|--------|----------|
| 1 | GET `/juridico/processos?status=critico` | só matching |
| 2 | GET `?q=JUR-2026` | localiza número |
| 3 | GET `/juridico/processos/:id` | timeline + partes |
| 4 | Client lista | **zero** linhas mock fixas |

---

## VS-004 — Dashboard (US4)

| Step | Action | Expected |
|------|--------|----------|
| 1 | GET `/juridico/dashboard` | KPIs numéricos reais |
| 2 | Client `/juridico/dashboard` | gráfico ≠ valores estáticos 47/6/23/82% |

---

## VS-005 — Fiscalização + Probabilidade de Perda (US5)

| Step | Action | Expected |
|------|--------|----------|
| 1 | POST `/juridico/fiscalizacao/runs` | 201 run completed |
| 2 | GET `/juridico/fiscalizacao/panel` | coluna probabilidadePerda |
| 3 | Processo judicial vencido sem CNJ | band **alta** + check identification **parcial** |
| 4 | GET processo antes/depois run | campos operacionais **idênticos** |

---

## VS-006 — Insights Cedro (US6)

| Step | Action | Expected |
|------|--------|----------|
| 1 | GET `/juridico/insights/panel` | insights reais, fonte *Dados internos — Jurídico* |
| 2 | POST batches (Consultar IA) | novo lote ou throttle 429 |
| 3 | Trace sheet | sem rota dedicada |

---

## VS-007 — Maturidade Carvalho (US7)

| Step | Action | Expected |
|------|--------|----------|
| 1 | POST self-assessment trimestre vigente | 201 |
| 2 | GET `/juridico/maturidade/dashboard` | score híbrido 3 eixos |
| 3 | POST action-plan | 201 — única escrita além autoavaliação |

---

## VS-008 — Tenant isolation (SC-010)

| Step | Action | Expected |
|------|--------|----------|
| 1 | Tenant A cria processo | OK |
| 2 | Tenant B GET id processo A | 404 |

---

## Comandos teste automatizado

```powershell
cd ci-api-v2
npm test -- juridico
npm run test:e2e -- --testPathPattern=juridico

cd ci-client-v2/apps/web
npm run test -- juridico
```

**Gate release**: todos CT-JUR-* da [test-strategy.md](./contracts/test-strategy.md) verdes.
