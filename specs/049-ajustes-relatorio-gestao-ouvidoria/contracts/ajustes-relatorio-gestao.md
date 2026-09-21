# Contrato: Ajustes na Pesquisa de Satisfação e no Relatório de Gestão da Ouvidoria

Todas as rotas continuam em `OuvidoriaController` (`ci-api-v2/src/modules/ouvidoria/ouvidoria.controller.ts`), protegidas por `@RequireModulo('ouvidoria')`. Tenant implícito via `AsyncLocalStorage`. Este documento cobre apenas o que **muda** em relação ao contrato já existente ([`042-relatorio-gestao-ouvidoria/contracts/relatorio-gestao.md`](../../042-relatorio-gestao-ouvidoria/contracts/relatorio-gestao.md)).

## `GET /ouvidoria/relatorio-gestao` (alterado)

**Query**: inalterada (`year?`, `month?`).

**Response** (200) — campos alterados/novos:

```json
{
  "pesquisaSatisfacao": [
    {
      "ano": 2026, "mes": 8, "perguntaId": 1, "perguntaNome": "string",
      "consultados": 0, "respostasSim": 0, "respostasNao": 0,
      "percentual": 0
    }
  ],
  "orientacoesEncaminhamentos": [
    { "ano": 2026, "concessao": "Água / Saneamento", "canal": "Presencial", "total": 0 }
  ],
  "participacaoEventos": [
    { "evento": "Manaus + Cidadã", "ano": 2026, "mes": 1, "participacoes": 0 }
  ]
}
```

- `pesquisaSatisfacao[].percentual`: `respostasSim / (respostasSim + respostasNao)`, arredondado; `null` quando `respostasSim + respostasNao === 0` (FR-002 — UI exibe "sem dados").
- `orientacoesEncaminhamentos`: **ignora** `year`/`month` da query — sempre retorna o histórico completo multi-ano do tenant (ver `research.md` §3). `canal` usa `'Não informado'` como fallback quando `serviceMode` está vazio.
- `participacaoEventos`: respeita `year` (todos os 12 meses daquele ano, um evento por linha/mês) — quando `year` ausente ("acumulado geral"), agrega por ano em vez de por mês: `{ evento, ano, participacoes }` (mesmo padrão de "sem eixo mensal no acumulado geral" já usado nos outros blocos).

**Erros**: inalterados.

---

## `POST /ouvidoria/pesquisa-satisfacao` (alterado)

**Body** (novo shape):

```json
{ "perguntaId": 1, "ano": 2026, "mes": 8, "consultados": 25, "respostasSim": 22, "respostasNao": 3 }
```

- `consultados` é opcional (`Int?`); `respostasSim`/`respostasNao` são obrigatórios (`Int`, `>= 0`).
- **Removido**: campo `valor` (não existe mais).

**Comportamento**: inalterado — upsert por `[tenantId, perguntaId, ano, mes]` (FR-004), "última gravação vence".

**Response** (200/201):

```json
{
  "id": "uuid", "perguntaId": 1, "ano": 2026, "mes": 8,
  "consultados": 25, "respostasSim": 22, "respostasNao": 3,
  "percentual": 0.88, "origem": "manual"
}
```

**Erros**: inalterados (`400` Zod, `404` pergunta inexistente/inativa).

---

## `GET /ouvidoria/relatorio-gestao/pdf` e `/excel` (alterados — sem mudança de contrato HTTP)

Mesma query, mesmo `Content-Type`/`Content-Disposition` já existentes. O **conteúdo** reflete os blocos alterados/novos acima: seção "Pesquisa de satisfação" com as colunas novas (Consultados, Sim, Não, %); duas seções/abas novas ("Orientações e Encaminhamentos", "Participação em Eventos"). O PDF corrige o bug de sobreposição de texto (FR-006) — sem mudança de contrato, é uma correção de renderização.

---

## `GET /ouvidoria/eventos` (novo)

Lista o catálogo de eventos institucionais do tenant.

**Query**: `incluirInativos?: boolean` (default `false`).

**Response** (200): `[{ "id": 1, "nome": "Manaus + Cidadã", "ativo": true }]`.

---

## `POST /ouvidoria/eventos` (novo)

Cria um evento institucional — usuário final do módulo Ouvidoria (mesmo padrão de `POST /ouvidoria/formas-atendimento`).

**Body**: `{ "nome": "string" }`.

**Response** (201): `{ "id": 1, "nome": "string", "ativo": true }`.

**Erros**: `400` (nome vazio); `409` se já existir evento ativo com o mesmo nome no tenant.

---

## `PATCH /ouvidoria/eventos/:id` (novo)

Edita o nome de um evento existente.

**Body**: `{ "nome": "string" }`.

**Response** (200): registro atualizado.

---

## `POST /ouvidoria/eventos/:id/inativar` (novo)

Inativa um evento (soft — preserva participações já lançadas).

**Response** (200): `{ "id": 1, "ativo": false }`.

---

## `GET /ouvidoria/eventos/participacoes` (novo)

**Query**: `year: number` (obrigatório), `eventoId?: number`.

**Response** (200): `[{ "id": "uuid", "eventoId": 1, "eventoNome": "string", "ano": 2026, "mes": 1, "participacoes": 0 }]`.

---

## `POST /ouvidoria/eventos/participacoes` (novo)

**Body**: `{ "eventoId": 1, "ano": 2026, "mes": 1, "participacoes": 6 }`.

**Comportamento**: upsert por `[tenantId, eventoId, ano, mes]` — relançar o mesmo evento/mês/ano **sobrescreve** a quantidade (nunca soma, decisão de `/speckit-clarify`).

**Response** (200/201): registro criado/atualizado, mesmo shape do GET.

**Erros**: `400` (Zod); `404` se `eventoId` não existir/não pertencer ao tenant/estiver inativo.
