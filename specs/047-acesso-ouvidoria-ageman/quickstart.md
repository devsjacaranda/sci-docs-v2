# Quickstart: Validar Níveis de Acesso Ouvidoria AGEMAN (403)

## Pré-requisitos

```powershell
cd ci-api-v2; npm run prisma:seed  # garante tenant/usuários/setores de teste (Jacaranda)
cd ci-api-v2; npm run start:dev
cd ci-client-v2; npm run dev       # turbo → @ci/web
```

Usuários de teste necessários (ajustar seed se preciso — ver `tasks.md` na fase `/speckit-tasks`):
- **Operador A** (`role: user`, sem chefia) — cria uma demanda interna (emissor = A)
- **Operador B** (`role: user`, sem chefia) — cria outra demanda interna (emissor = B)
- **Chefe da Ouvidoria** (`role: chefe_setor`, setor vinculado ao módulo `ouvidoria` via `ModuloSetor`)
- **Admin tenant** (`role: admin_tenant`)
- **Admin SaaS** (`role: admin_saas`, app admin-saas) — para o Cenário 8

## Cenário 1 — Lista mostra todas; 403 só no detalhe (US1 / SC-001)

1. Login como Operador A → criar demanda interna → confirmar.
2. Login como Operador B → criar outra demanda interna → confirmar.
3. Como A e como B: `GET /ouvidoria/manifestacoes` → **ambos** veem as duas linhas (e o restante do tenant, com filtros de produto).
4. Como B: `GET /ouvidoria/manifestacoes/{idDeA}` → `403 OUVIDORIA_ACCESS_DENIED` (sem conteúdo).
5. Verificar que uma demanda do canal público aparece para ambos na lista.

**Esperado**: listas iguais no universo do tenant; 403 só ao abrir/editar a demanda alheia.

## Cenário 2 — 403 explícito em ação direta (US2 / SC-002)

1. Como Operador B, chamar diretamente:
   - `GET /ouvidoria/manifestacoes/{idDeA}` → `403 OUVIDORIA_ACCESS_DENIED`, corpo sem `subject`/`description`.
   - `PATCH /ouvidoria/manifestacoes/{idDeA}` → `403`, nenhuma alteração persistida (confirmar com novo `GET` como Operador A).
   - `GET /ouvidoria/manifestacoes/{idDeA}/documento/pdf` → `403`, nenhum arquivo retornado.

**Esperado**: 3/3 chamadas retornam 403 com o mesmo `code`.

## Cenário 3 — Chefe e admin veem tudo (US3 / SC-003)

1. Login como Chefe da Ouvidoria → `GET /ouvidoria/manifestacoes/{idDeA}` e `{idDeB}` → ambos `200`.
2. Login como Admin tenant → idem → ambos `200`.
3. Login como um chefe de setor **não** vinculado ao módulo Ouvidoria → `GET /ouvidoria/manifestacoes/{idDeA}` → `403` (não ganha o bypass).

## Cenário 4 — Conceder acesso pontual (US4 / SC-004)

1. Como Operador A: `POST /ouvidoria/acessos { "scope": "manifestacao", "manifestacaoId": "{idDeA}", "granteeUserId": "{idDeB}" }` → `201`.
2. Como Operador B: `GET /ouvidoria/manifestacoes/{idDeA}` → agora `200`.
3. Como Operador B: `GET /ouvidoria/manifestacoes/{outraDemandaDeA}` (sem concessão) → ainda `403`.

## Cenário 5 — Conceder acesso geral por emissor (US5)

1. Como Operador A: `POST /ouvidoria/acessos { "scope": "emissor", "emissorUserId": "{idDeA}", "granteeUserId": "{idDeB}" }` → `201`.
2. Como Operador B: `GET` em qualquer demanda existente de A → `200`.
3. Como Operador A: criar **nova** demanda depois da concessão.
4. Como Operador B: `GET` na nova demanda de A → `200` sem nenhuma ação adicional.
5. `DELETE /ouvidoria/acessos/{idDaConcessao}` (como A, chefe, ou admin) → `200`.
6. Como Operador B: `GET` em qualquer demanda de A (antiga ou nova) → volta a `403`.

## Cenário 6 — "Quem tem acesso" (US6 / SC-006)

1. Com as concessões do Cenário 4 e 5 ativas sobre a demanda de A: `GET /ouvidoria/manifestacoes/{idDeA}/acessos` (como A, chefe, admin, ou B) → `200` com `emissor.userId = A`, `concessoes` contendo a entrada `scope: "manifestacao"` para B.
2. No client: abrir `/ouvidoria/manifestacoes/{idDeA}` → o card "Quem tem acesso" reflete a mesma lista.
3. Revogar uma concessão → recarregar → a entrada desaparece da lista e de `GET .../acessos`.

## Cenário 7 — Fora de escopo permanece igual (SC-008)

1. `GET /ouvidoria/dashboard`, `GET /ouvidoria/relatorio-gestao`, `GET /ouvidoria/auditoria`, `GET /ouvidoria/pesquisa-satisfacao` — como Operador B (sem nenhuma concessão) → continuam `200` com dados agregados de todo o tenant, sem filtro por emissor.

## Cenário 8 — Feature flag: desligar/religar por tenant (US7 / SC-009 / SC-010)

1. Confirmar estado inicial: `GET /ouvidoria/acesso-flag` (como Admin tenant) → `200 { "enabled": true, ... }` (nasce ligado, sem configuração explícita — FR-018).
2. Repetir o Cenário 1 (Operador A e B, cada um com sua demanda) para confirmar que a restrição está em vigor antes de desligar.
3. Como Admin tenant: `PATCH /ouvidoria/acesso-flag { "enabled": false }` → `200 { "enabled": false, ... }`.
4. Como Operador B (mesmo token, sem novo login): `GET /ouvidoria/manifestacoes` → **agora contém** a demanda de A; `GET /ouvidoria/manifestacoes/{idDeA}` → `200` (antes era `403`).
5. Como Admin SaaS (app admin-saas): `GET /admin/tenants/{tenantId}` → resposta inclui o estado do flag (`enabled: false`); confirmar que a tela `TenantDetailPage.tsx` mostra o toggle desligado.
6. Repetir o Cenário 4 (conceder acesso pontual) enquanto o flag está desligado → `POST /ouvidoria/acessos` ainda retorna `201` normalmente (grants continuam funcionando sobre os dados, ver `research.md` §9), mesmo sem efeito prático na decisão de acesso.
7. Religar: como Admin SaaS, `PATCH /admin/tenants/{tenantId}/feature-flags/ouvidoria-acesso { "enabled": true }` → `200`.
8. Como Operador B (sem novo login): `GET /ouvidoria/manifestacoes/{idDeA}` → volta a `403` (restrição religada); a concessão feita no passo 6 (se foi para a demanda de A→B) já vale imediatamente sem recriação.
9. Como Admin tenant de **outro** tenant, tentar `PATCH /admin/tenants/{tenantIdDeOutroTenant}/feature-flags/ouvidoria-acesso` via a rota self-service (`/ouvidoria/acesso-flag`) → deve alterar apenas o próprio tenant (tenantId resolvido pelo `getRequestContext()`, nunca pelo body/rota) — não há como um `admin_tenant` atingir outro tenant por esta rota.

## Testes automatizados equivalentes (referência para `/speckit-tasks`)

- `assert-manifestacao-access.spec.ts` (unit, Jest) — todas as combinações de `AccessReason` de `data-model.md`, incluindo `flag-disabled`.
- `ouvidoria-acesso.repositories.spec.ts` — idempotência de concessão, revogação.
- `get-ouvidoria-acesso-flag.spec.ts` (unit, Jest) — ausência de linha ⇒ `enabled: true`; leitura após upsert.
- `set-ouvidoria-acesso-flag.use-case.spec.ts` (unit, Jest) — guard de role/tenant (FR-017), grava `AuditLog` (FR-020).
- `ouvidoria-acesso-controle.e2e-spec.ts` (novo, `ci-api-v2/test/`) — cobre os Cenários 1–5 fim a fim.
- `ouvidoria-acesso-flag.e2e-spec.ts` (novo, `ci-api-v2/test/`) — cobre o Cenário 8 fim a fim (desligar → verificar bypass → religar → verificar restauração).
- `manifestacao-detail-view.test.ts` (Vitest, client) — mapeamento do novo campo `acesso` no ViewModel.
