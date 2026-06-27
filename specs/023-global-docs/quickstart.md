# Quickstart: Central de Documentação (global-docs)

**Feature**: 023-global-docs · **Branch**: `023-global-docs`

Guia de validação ponta a ponta. Contratos: [contracts/](./contracts/) · modelo: [data-model.md](./data-model.md).

---

## Pré-requisitos

- Node.js 20 LTS
- PostgreSQL rodando (dev)
- Tenant Jacaranda seedado

```powershell
cd ci-api-v2
npm install
npm run prisma:migrate
npm run prisma:seed
npm run start:dev

# Terminal separado
cd ci-client-v2
npm install
npm run dev
```

Credenciais: `admin@jacaranda.com` (ver seed Jacaranda).

---

## Cenário 1 — Central carrega dados reais (P1)

**Objetivo**: FR-005, SC-001, US1

1. Autenticar no tenant Jacaranda
2. Navegar `/global/documentacao`
3. **Esperado**: grid com ≥ 12 artigos de módulos distintos
4. **Esperado**: nenhum dado de `globalUsageDocs` em memória (verificar Network → `GET /global/docs`)

---

## Cenário 2 — Detalhe guia ETP Compras (P1)

**Objetivo**: FR-003, FR-007, SC-004, US2

1. Filtrar módulo **Compras**
2. Abrir *Como elaborar um ETP*
3. **Esperado**: 7 passos numerados com dicas onde seed define
4. **Esperado**: referências Pau-Brasil/Cedro/Jatobá como rótulos consultivos

---

## Cenário 3 — Filtros e busca (P2)

**Objetivo**: FR-008, FR-009, SC-003, US3

1. Filtrar tipo *Guia de processo* → somente guias
2. Buscar *manifestação* → artigos Ouvidoria
3. Combinar filtro + busca sem resultado → estado vazio claro

**API**:

```powershell
curl -H "Authorization: Bearer $TOKEN" -H "X-Tenant-ID: jacaranda" "http://localhost:3000/global/docs?moduleSlug=compras"
```

---

## Cenário 4 — Seed mínimo por módulo (P1)

**Objetivo**: FR-010, FR-011, SC-002, US4

```powershell
cd ci-api-v2
npm run prisma:seed
# Verificar contagem por moduleSlug no banco ou via API
```

**Esperado**: ouvidoria, juridico, compras, contratos, patrimonio, protocolo — cada um ≥ 2 documentos.

---

## Cenário 5 — ModuleDocsPanel desmockado (P2)

**Objetivo**: FR-012, US5

1. Navegar tela docs contextual Compras (`/compras/guia/etp` ou equivalente)
2. **Esperado**: guia ETP da API — **não** `moduleProcessGuides` estático

---

## Cenário 6 — Tenant vazio (edge)

**Objetivo**: SC-006

1. Tenant novo sem seed global-docs
2. `/global/documentacao`
3. **Esperado**: estado vazio orientativo — zero cards fabricados

---

## Testes automatizados

```powershell
cd ci-api-v2
npm test -- --testPathPatterns=global-docs

cd ci-client-v2/apps/web
npm test -- global-docs
```
