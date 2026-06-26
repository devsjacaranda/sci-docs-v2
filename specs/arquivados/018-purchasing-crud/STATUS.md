# STATUS — 018 Purchasing CRUD

**Data**: 2026-06-25  
**Estado**: Concluída — 105/105 tasks em `tasks.md`

## Entregue

### API (`ci-api-v2`)
- Módulo `modules/compras/` — PCA, demandas CRUD, 7 artefatos PUT/GET, comprovante presign/confirm
- Prisma `compras.prisma` + migration + seed DEAE (Jacaranda)
- Status/progresso derivados no mapper (sem coluna persistida)
- DELETE demanda, relatório PDF **501 Not Implemented**
- Schemas Zod, use-cases, repositórios tenant-scoped, `@RequireModulo('compras')`
- **59 testes** Jest (20 suites): mapper, schemas, use-cases, contract, integração status

### Client (`ci-client-v2`)
- `modules/compras/` — listagem institucional, criar demanda, hub quebra-cabeça, 7 páginas de artefato
- Rotas canônicas `/compras`, `/compras/novo`, `/compras/:id`, `/compras/:id/editar`, sub-rotas artefatos
- `PcaManageSheet`, KPIs, filtros, paginação, menu ⋮ (ver/editar)
- MSW handlers + fixtures espelhando API
- **11 testes** Vitest (10 files): listagem, hub, DFD, ETP waived, create, MSW

## Validação

```powershell
cd ci-api-v2; npm test -- --testPathPatterns=compras
cd ci-client-v2/apps/web; npm test -- compras
cd ci-api-v2; npm run prisma:seed; npm run start:dev
cd ci-client-v2; npm run dev
```

Quickstart manual (SC-007): `quickstart.md` §1–10 com seed Jacaranda — jornada PCA → demanda → 7 artefatos em ≤20 min.

## Critérios spec

| SC | Status |
|----|--------|
| SC-001 Listagem paginada com progresso derivado | OK |
| SC-002 Criar demanda ≤2 min | OK (automated + manual timing) |
| SC-003 Hub quebra-cabeça 7 artefatos | OK |
| SC-004 ETP dispensado conta como satisfeito | OK |
| SC-005 Status Concluído com 7/7 | OK |
| SC-006 Gestão PCA via sheet | OK |
| SC-007 Demo ponta a ponta ≤20 min | OK (quickstart) |

## Notas

- Specs **019** (fiscalização), **020** (insights) e **021** (maturidade) dependem desta entrega.
- PDF relatório demanda retorna 501 — escopo futuro.
