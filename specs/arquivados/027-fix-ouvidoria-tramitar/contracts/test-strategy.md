# Contract: Test Strategy — Fix tramitação Ouvidoria

**Feature**: 027-fix-ouvidoria-tramitar  
**References**: [plan.md](../plan.md) · constitution II · [rest-api-ouvidoria-encaminhar-fix.md](./rest-api-ouvidoria-encaminhar-fix.md)

## Princípio

TDD RED → GREEN → REFACTOR. Escopo mínimo: API only (bug server-side). Client: smoke manual via quickstart.

## Scripts

```powershell
cd ci-api-v2
npm test -- resolve-tramitacao-sector
npm test -- encaminhar-manifestacao
npm test -- ouvidoria.controller

# suite completa ouvidoria (se existir)
npm test -- ouvidoria
```

## Matriz mínima — API

| ID | Camada | Arquivo alvo | Caso |
|----|--------|--------------|------|
| CT-OT-001 | unit | `resolve-tramitacao-sector.use-case.spec.ts` | JWT com setorIds → retorna setor |
| CT-OT-002 | unit | idem | JWT vazio, userSetor no DB → retorna do banco |
| CT-OT-003 | unit | idem | Apenas chiefOfSetorIds → retorna chefe |
| CT-OT-004 | unit | idem | Admin sem vínculo + ModuloSetor ouvidoria → fallback OUV |
| CT-OT-005 | unit | idem | Tenant sem setores → `ACTIVE_SECTOR_UNDEFINED` |
| CT-OT-006 | unit | idem | Usuário multi-setor + preferredModuloSlug ouvidoria → prefer OUV |
| CT-OT-007 | unit | `encaminhar-manifestacao-tramitacao.integration.spec.ts` | Regressão: linked demanda com senderSectorId (existente) |
| CT-OT-008 | integration | `ouvidoria.controller.spec.ts` ou e2e | POST encaminhar admin_tenant → 200 |
| CT-OT-009 | integration | idem | POST encaminhar user com setorIds → 200 |
| CT-OT-010 | integration | idem | POST encaminhar manifestação draft → 409 |

## TDD order (implementação)

1. **RED** CT-OT-004, CT-OT-005, CT-OT-006 (resolver estendido)
2. **GREEN** `resolve-tramitacao-sector.use-case.ts` + export module
3. **RED** CT-OT-008, CT-OT-009 (controller)
4. **GREEN** `ouvidoria.controller.ts` wiring
5. **REFACTOR** copy erro FR-008; verificar CT-OT-007 regressão
6. **Smoke** quickstart VS-027-001 manual

## Fixtures de teste

| Actor | setorIds JWT | ModuloSetor ouvidoria | Resultado |
|-------|--------------|----------------------|-----------|
| admin_tenant | `[]` | OUV vinculado | 200, sender = OUV |
| chefe_setor (Paulo seed) | `['DEJUR', ...]` | OUV não vinculado ao user | 200, sender = DEJUR |
| user sem setor, sem fallback | `[]` | nenhum setor tenant | 400 ACTIVE_SECTOR_UNDEFINED |

## Client

Sem testes Vitest obrigatórios nesta feature. Validar manualmente:

- Modal exibe erro legível em 400
- Campos destino/observação preservados após erro
- Toast + link demanda após 200

## Seed (dev)

Tenant Jacaranda (`npx prisma db seed`):

- Admin: `admin@jacaranda.com` / `password123`
- Setor OUV vinculado a `ModuloSlug.ouvidoria`
- Manifestação demo: `11111111-1111-1111-1111-000000000018`
