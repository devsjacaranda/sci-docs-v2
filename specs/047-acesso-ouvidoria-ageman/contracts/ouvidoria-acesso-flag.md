# Contract: Feature Flag de Acesso — Ouvidoria (FR-014 a FR-020)

Controla se toda a restrição de acesso desta feature (FR-001 a FR-009) está em vigor para um tenant. Ligado por padrão (ausência de configuração explícita = ligado — FR-018).

## GET `/ouvidoria/acesso-flag`

Self-service — lê o estado do próprio tenant.

**Guard**: autenticado, role `admin_tenant` (ou `admin_plataforma`, tratado como equivalente institucional legado). `tenantId` sempre resolvido por `getRequestContext().tenantId!` — nunca por parâmetro de rota ou body, para impedir qualquer tentativa de ler/alterar o flag de outro tenant (FR-017).

**Resposta 200**:

```json
{
  "enabled": true,
  "updatedAt": null,
  "updatedBy": null
}
```

Quando já houve alteração:

```json
{
  "enabled": false,
  "updatedAt": "2026-09-16T12:00:00.000Z",
  "updatedBy": { "role": "admin_tenant" }
}
```

## PATCH `/ouvidoria/acesso-flag`

Self-service — liga/desliga o flag do próprio tenant.

**Guard**: mesmo de `GET` acima.

**Body**:

```json
{ "enabled": false }
```

**Efeito**: `upsert` em `OuvidoriaAcessoFeatureFlag` (nunca `delete`, mesmo religando) + linha em `AuditLog` (`action: 'ouvidoria_acesso_flag_toggled'`, FR-020). Efeito imediato na requisição seguinte de qualquer usuário do tenant (SC-009/SC-010) — não depende de novo login.

**Respostas**:
- `200`: mesmo formato do `GET`, refletindo o novo estado.
- `403`: ator sem role permitida (guard de rota, não `assertManifestacaoAccess` — esta rota é tenant-level, não record-level).
- `400 VALIDATION_FAILED`: `enabled` ausente ou não booleano.

## PATCH `/admin/tenants/:tenantId/feature-flags/ouvidoria-acesso`

Cross-tenant — módulo `admin-plataforma` (app admin-saas), mesmo padrão de `PATCH /admin/tenants/:tenantId/licencas/:licencaSlug` (`toggle-tenant-licenca.use-case.ts`).

**Guard**: autenticado, role `admin_saas`. `:tenantId` vem da rota (exceção documentada em `plan.md` — Constitution Check §IV — pois `admin_saas` opera cross-tenant por definição).

**Body**: `{ "enabled": boolean }` — mesmo schema do self-service.

**Efeito**: idêntico ao `PATCH /ouvidoria/acesso-flag`, apenas com `tenantId` explícito e `updatedByRole: 'admin_saas'` na auditoria.

**Respostas**: mesmo formato acima; `404` se `:tenantId` não existir.

O estado do flag (`enabled`) também passa a ser incluído na resposta de `GET /admin/tenants/:tenantId` (`GetTenantDetailUseCase`), do mesmo jeito que as licenças do tenant já aparecem lá — evita uma chamada extra na tela `TenantDetailPage.tsx`.

## Uso interno (não é rota) — `getOuvidoriaAcessoFlag(tenantId)`

Função pura usada como Passo 0 por `assertManifestacaoAccess` e pelo filtro de `list-manifestacoes` (ver `contracts/ouvidoria-visibilidade-listagem-e-403.md`). Lê `OuvidoriaAcessoFeatureFlag` por `tenantId`; retorna `true` quando não há linha.
