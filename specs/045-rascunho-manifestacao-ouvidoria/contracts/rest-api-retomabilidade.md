# Contrato REST — Retomabilidade do rascunho institucional

**Base**: `OuvidoriaController`. **1 rota nova**.

Autenticação: JWT + `X-Tenant-ID` + `@RequireModulo('ouvidoria')` — mesmo padrão de toda rota do módulo.

## GET `/ouvidoria/manifestacoes/:id/retomabilidade`

Verifica, para o operador autenticado, se um registro institucional de rascunho (`manifestacaoId` referenciado pelo rascunho local) ainda é retomável — **sem** devolver o payload completo da manifestação (ver `research.md` R4 para o porquê).

### Request

- `:id` — UUID da `Manifestacao` (o mesmo `manifestacaoId` guardado no `RascunhoLocal`, ver `data-model.md`).
- Sem body, sem query params.

### Response `200`

```json
{
  "retomavel": true,
  "status": "draft"
}
```

| Campo | Tipo | Notas |
|---|---|---|
| `retomavel` | `boolean` | `true` apenas se `status === "draft"` **e** o registro pertence ao operador (via `resolveUserTableId(actor.userId, actor.role)` comparado a `createdByUserId`) e ao tenant ativo (`X-Tenant-ID`) |
| `status` | `"draft" \| "in_review" \| "forwarding" \| "answered" \| "closed" \| "closed_unresolved"` | Status atual — o client usa só para telemetria/mensagem, a decisão de UI usa `retomavel` |

### Regras de resposta (nunca vazam existência para quem não é dono/tenant)

| Situação | `retomavel` | HTTP |
|---|---|---|
| `status === draft` e pertence ao operador+tenant | `true` | `200` |
| `status !== draft` (qualquer transição adiante) | `false` | `200` |
| Registro não existe (`id` inválido ou apagado) | — | `404` (mesmo shape de erro de `AllExceptionsFilter` já usado em `RequireManifestacaoRepository`) |
| Registro existe mas é de outro tenant | — | `404` (nunca `403` — não confirma existência cross-tenant, mesmo padrão de `SC-009` da spec 038) |
| Registro existe, mesmo tenant, mas de outro operador | `false` | `200` (não é erro — apenas não é retomável **por este operador**; evita enumeração por diferença de status HTTP) |

O client trata **qualquer resposta que não seja `200` com `retomavel: true`** — incluindo erro de rede/timeout — como "não confirmado" (FR-016): oculta o convite e remove a cópia local, sem tentar distinguir os motivos na UI.

### Fora de contrato

- Não altera `POST /ouvidoria/manifestacoes`, `PATCH /ouvidoria/manifestacoes/:id`, `POST /ouvidoria/manifestacoes/:id/confirmar` — inalterados.
- Não substitui `GET /ouvidoria/manifestacoes/:id` (detalhe completo) — ambos coexistem, com responsabilidades distintas.
- Canal público (`/ouvidoria/publico/**`) não é afetado.
