# Contract: Concessão/Revogação/Listagem de Acesso — Ouvidoria

Base: `/ouvidoria` (mesmo controller `OuvidoriaController`, `@RequireModulo('ouvidoria')` em todas as rotas abaixo — autenticado, com módulo Ouvidoria liberado; a checagem de **dono/chefe/admin/concessão** é adicional, feita dentro de cada use-case).

## POST `/ouvidoria/acessos`

Concede acesso (FR-004 ou FR-005, conforme `scope`).

**Body** (`createOuvidoriaAcessoBodySchema`, discriminated union):

```jsonc
// scope = manifestacao (FR-004)
{ "scope": "manifestacao", "manifestacaoId": "<uuid>", "granteeUserId": "<uuid>" }

// scope = emissor (FR-005)
{ "scope": "emissor", "emissorUserId": "<uuid>", "granteeUserId": "<uuid>" }
```

**Autorização** (dentro do use-case, não no controller):
- `scope = manifestacao`: o ator deve ser o emissor daquela manifestação, chefe da ouvidoria, ou admin — senão `403 OUVIDORIA_ACCESS_DENIED`.
- `scope = emissor`: o ator deve ser o próprio `emissorUserId`, chefe da ouvidoria, ou admin — senão `403 OUVIDORIA_ACCESS_DENIED`.

**Respostas**:
- `201`: `{ "id": "<uuid>", "scope": "...", "granteeUserId": "...", "grantedAt": "<iso>" }`
- `400 OUVIDORIA_ACCESS_ALREADY_GRANTED`: já existe concessão ativa idêntica.
- `400 VALIDATION_FAILED`: `granteeUserId` inválido, não pertence ao tenant, ou é igual ao emissor.
- `403 OUVIDORIA_ACCESS_DENIED`: ator sem permissão para conceder.
- `404 OUVIDORIA_NOT_FOUND`: `manifestacaoId` (scope=manifestacao) não existe.

## DELETE `/ouvidoria/acessos/:id`

Revoga uma concessão (FR-006). `:id` é o `id` da própria concessão (`OuvidoriaAcessoConcessao.id`).

**Autorização**: mesmos perfis que podem conceder para aquele registro/emissor (emissor, chefe da ouvidoria, admin) — não é necessário ser quem concedeu originalmente.

**Respostas**:
- `200`: `{ "id": "<uuid>", "revokedAt": "<iso>" }`
- `403 OUVIDORIA_ACCESS_DENIED`
- `404 OUVIDORIA_ACCESS_NOT_FOUND`: concessão não existe ou já revogada.

## GET `/ouvidoria/manifestacoes/:id/acessos`

Lista "quem tem acesso" a uma demanda específica (FR-009/US6).

**Autorização**: qualquer ator que já tenha acesso à manifestação (mesmo `assertManifestacaoAccess` do detalhe) — senão `403 OUVIDORIA_ACCESS_DENIED`.

**Resposta 200** (`OuvidoriaAcessoViewModel`, ver `data-model.md`):

```json
{
  "emissor": { "userId": "<uuid>", "name": "Maria Silva" },
  "grupoChefeAdminTemAcesso": true,
  "concessoes": [
    {
      "id": "<uuid>",
      "granteeUserId": "<uuid>",
      "granteeName": "João Souza",
      "scope": "manifestacao",
      "grantedAt": "2026-09-16T12:00:00.000Z"
    }
  ],
  "efetivos": [
    {
      "actorId": "<uuid>",
      "name": "Maria Silva",
      "origem": "emissor",
      "implicit": false,
      "revogavel": false,
      "actorKind": "user"
    },
    {
      "actorId": "<uuid-admin-tenant>",
      "name": "Admin da instituição",
      "origem": "admin",
      "implicit": true,
      "revogavel": false,
      "actorKind": "admin_tenant"
    },
    {
      "actorId": "<uuid>",
      "name": "Chefe Ouvidoria",
      "origem": "chefe",
      "implicit": true,
      "revogavel": false,
      "actorKind": "user"
    },
    {
      "actorId": "<uuid>",
      "name": "João Souza",
      "origem": "concedido",
      "implicit": false,
      "revogavel": true,
      "actorKind": "user",
      "concessaoId": "<uuid>",
      "scope": "manifestacao"
    }
  ]
}
```

`efetivos` é a lista nominativa de quem já acessa o registro (US6 / diálogo Conceder acesso):

- `origem = admin`: `AdminTenant` ativos do tenant e `User` com role `admin_plataforma` / `admin_tenant`. **Não** inclui `admin_saas` (operador da plataforma).
- `origem = chefe`: somente o chefe de setor cujo setor está vinculado ao módulo Ouvidoria (`FindModuloSetores(ouvidoria)`). Chefe de outro setor **não** entra.
- `origem = emissor`: dono da demanda (`emissorUserId`).
- `origem = concedido`: grantee de concessão pontual ou geral vigente.

Deduplicação por `actorId` (prioridade: emissor > admin > chefe > concedido). Implícitos (`admin`/`chefe`) não são revogáveis por grant.

Quando a demanda não tem dono (FR-002, canal público ou admin sem vínculo): `"emissor": null`, `"concessoes": []` (concessões só existem para demandas com dono). `efetivos` continua listando implícitos (admins + chefe da Ouvidoria).

## POST `/ouvidoria/manifestacoes/:id/solicitar-acesso`

Registra um pedido de acesso (FR-021) para quem recebeu `403 OUVIDORIA_ACCESS_DENIED` no detalhe, na edição ou numa ação da listagem. Não exige `assertManifestacaoAccess` — o ator autenticado com módulo Ouvidoria pode pedir mesmo sem ver o registro.

**Autorização:** `@RequireModulo('ouvidoria')`. Se o ator já tem acesso, a API devolve `already_has_access` sem criar evento.

**Respostas:**
- `200` `{ "status": "requested", "destinos": ["Maria Silva", "Chefe Ouv"] }` — pedido novo (evento `note` "Acesso solicitado" + auditoria `ouvidoria_acesso_requested`).
- `200` `{ "status": "already_requested", "destinos": [...] }` — pedido idêntico nos últimos 30 minutos (no-op).
- `200` `{ "status": "already_has_access" }` — ator já pode abrir o registro.
- `404 OUVIDORIA_NOT_FOUND` — manifestação inexistente. Corpo sem `subject`/`description`.

O emissor, um chefe da ouvidoria ou um admin concede o acesso depois via `POST /ouvidoria/acessos` (tela de detalhe, ação da listagem ou CTA "Conceder acesso" no 403, se o ator puder).
