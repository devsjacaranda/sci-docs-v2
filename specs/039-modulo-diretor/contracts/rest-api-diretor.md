# REST API Contract — Módulo Diretor (039)

**Base path**: `/diretor`  
**Auth**: JWT + `X-Tenant-ID`  
**Guard**: `DiretorAccessGuard` em **todos** os handlers (tenant AGEMAN + papel ou e-mail nominado)  
**Licença / módulo**: nenhum `@RequireLicenca` / `@RequireModulo`  
**Validação**: Zod v4 em `diretor.schemas.ts` + `ZodValidationPipe`  
**Métodos**: somente GET  
**Envelope de erro**: `AllExceptionsFilter` (403 sem body de KPI)

Constantes: e-mail `ebenezer.bezerra@ageman.am.gov.br`; tenant AGEMAN `00000000-0000-0000-0000-000000000002`.

## Query comum de período (blocos de módulo)

```text
year?: int 2000–2100
month?: int 1–12
presetDays?: 3 | 7
fresh?: boolean          # ignora cache servidor
```

Se `presetDays` presente → janela rolante UTC. Senão → mês (`year`/`month` default = atuais UTC).

## Query comum de lista

```text
+ page?: int ≥ 1 default 1
+ limit?: int 1–50 default 20
+ autorUserId?: uuid
```

Response de lista: `{ items, total, page, limit }`.

Cache: KPIs 90s; listas/atores 30s. Header opcional `X-Diretor-Cache: hit | miss`.

---

## `GET /diretor/ouvidoria/kpis`

**200**

```json
{
  "period": { "from": "ISO", "to": "ISO", "source": "calendar" },
  "kpis": {
    "total": 0,
    "pendentes": 0,
    "emAnalise": 0,
    "respondidas": 0,
    "encerradasComResolucao": 0,
    "encerradasSemResolucao": 0
  }
}
```

`source`: `calendar` | `preset_3` | `preset_7`.  
Fórmulas = dashboard Ouvidoria existente.

---

## `GET /diretor/ouvidoria/acoes`

Query: período + paginação + `autorUserId?`.

**200** — `items[]`:

```json
{
  "id": "uuid",
  "occurredAt": "ISO",
  "kind": "registration",
  "summary": "string",
  "ref": { "manifestacaoId": "uuid", "protocol": "string|null", "subject": "string" },
  "actor": { "id": "uuid", "name": "string", "email": "string" }
}
```

`actor` pode ser `null`.

---

## `GET /diretor/diagnostico/kpis`

**200** (mesmo com MySQL externo fora)

```json
{
  "period": { "from": "ISO", "to": "ISO", "source": "calendar" },
  "estoqueIgnoraPeriodo": true,
  "estoqueErro": false,
  "estoque": {
    "total": 0,
    "sentencas": 0,
    "peticoesIniciais": 0,
    "procedencias": 0
  },
  "locais": {
    "marcadoresNoPeriodo": 0,
    "documentosNoPeriodo": 0
  }
}
```

Se MySQL falhar: `estoque: null`, `estoqueErro: true`, `locais` preenchido.

---

## `GET /diretor/diagnostico/acoes`

Query: período + paginação + `autorUserId?`.  
`items[]`: `kind: "marcador"`, `ref.numeroProcesso`, `actor` obrigatório (userId do marcador).

---

## `GET /diretor/audit-logs`

Query: **somente** `year`, `month`, `page`, `limit`, `action?` (`POST`|`PUT`|`PATCH`|`DELETE`), `q?` (trim, max 200, busca em `entity`). **Sem** `presetDays`.

**200** — `items[]`:

```json
{
  "id": "uuid",
  "occurredAt": "ISO",
  "action": "POST",
  "entity": "/path",
  "actor": {
    "id": "uuid",
    "name": "string|null",
    "email": "string|null",
    "role": "admin_tenant|null"
  }
}
```

`actor` pode ser `null` se não houver `userId` nem `payload.actorId`.

---

## `GET /diretor/atores`

Query: período + `modulo=ouvidoria|diagnostico`.

**200**

```json
{
  "items": [{ "id": "uuid", "name": "string", "email": "string" }]
}
```

Distinct de autores com pelo menos uma ação no período. Sem paginação (lista curta); se passar de 200, truncar e `truncated: true`.

---

## Códigos

| Status | Quando |
| --- | --- |
| 200 | OK (inclusive estoque degradado) |
| 400 | Zod validation |
| 401 | Sem JWT |
| 403 | Tenant ≠ AGEMAN ou actor não autorizado |
| 404 | Tenant header inválido (`TenantGuard`) |

Nenhum POST/PUT/PATCH/DELETE neste controller.
