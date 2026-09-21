# Contrato: Relatório de Gestão da Ouvidoria

Todas as rotas ficam em `OuvidoriaController` (`ci-api-v2/src/modules/ouvidoria/ouvidoria.controller.ts`), protegidas por `@RequireModulo('ouvidoria')`. Seguem o padrão de tenant implícito via `AsyncLocalStorage` (nunca no path/query).

## `GET /ouvidoria/relatorio-gestao`

**Query**: `year?: number` (2000–2100), `month?: number` (1–12) — mesmo schema de `DashboardQuery` já existente.

**Comportamento** (FR-003, sempre recalculado — sem cache):

- `year` + `month`: recorte daquele mês.
- `year` sem `month` ("todos os meses"): ano civil inteiro; séries mensais com eixo jan–dez daquele ano.
- sem `year` ("todos os anos"): KPI `acumuladoGeral` sem filtro **e** todos os blocos (resolutividade, atendimentos, finalizadas, pendentes, forma, tipo, motivo, zona, bairro, satisfação) no histórico completo do tenant. Séries "por mês" agrupam `EXTRACT(MONTH)` somando todos os anos (12 barras jan–dez do histórico, não um eixo por ano).
- sem `year` + `month`: mesmo histórico, restrito àquele mês civil em todos os anos.

**Response** (200):

```json
{
  "kpis": { "total": 0, "pendentes": 0, "emAnalise": 0, "respondidas": 0, "encerradasComResolucao": 0, "encerradasSemResolucao": 0 },
  "acumuladoGeral": { "total": 0, "encerradasComResolucao": 0, "encerradasSemResolucao": 0 },
  "resolutividade": [{ "month": 1, "comResolucao": 0, "semResolucao": 0, "percentual": 0 }],
  "atendimentosPorMes": [{ "month": 1, "total": 0 }],
  "porFormaAtendimento": [{ "month": 1, "forma": "string", "total": 0 }],
  "porTipoManifestacao": [{ "month": 1, "type": "complaint", "total": 0 }],
  "porZona": [{ "zona": "NORTE", "total": 0 }, { "zona": "Não informado", "total": 0 }],
  "porBairro": [{ "bairro": "string", "total": 0 }, { "bairro": "Não informado", "total": 0 }],
  "pesquisaSatisfacao": [{ "mes": 1, "ano": 2026, "perguntaId": 1, "perguntaNome": "string", "valor": 0 }]
}
```

**Erros**: `403 MODULO_SETOR_DENIED` (sem acesso ao módulo). Sem erro específico de "sem dados" — bloco vazio é resposta válida (Edge Case da spec).

**Performance**: p95 ≤ 5s mesmo para `acumuladoGeral` (SC-005). Sem paginação — volume esperado por tenant não justifica.

---

## `GET /ouvidoria/relatorio-gestao/pdf`

**Query**: mesma de `GET /ouvidoria/relatorio-gestao`.

**Response**: `200`, `Content-Type: application/pdf`, `Content-Disposition: attachment; filename="relatorio-gestao-ouvidoria-{ano}-{mes|acumulado}.pdf"`. Corpo: todos os blocos do JSON acima formatados (KPIs, tabelas) — via PDFKit, sem gráficos vetoriais (mesma limitação já aceita no Diagnóstico).

**Performance**: ≤ 30s mesmo para o acumulado geral (SC-005).

---

## `GET /ouvidoria/relatorio-gestao/excel`

**Query**: mesma de `GET /ouvidoria/relatorio-gestao`.

**Response**: `200`, `Content-Type: application/vnd.openxmlformats-officedocument.spreadsheetml.sheet`, `Content-Disposition: attachment; filename="relatorio-gestao-ouvidoria-{ano}-{mes|acumulado}.xlsx"`. Uma aba por bloco (KPIs, Resolutividade, Atendimentos por Mês, Forma de Atendimento, Tipo de Manifestação, Zona, Bairro, Pesquisa de Satisfação) — valores já calculados, sem fórmulas nem gráficos nativos (Clarification 2).

**Performance**: ≤ 30s (SC-005).

---

## `GET /ouvidoria/pesquisa-satisfacao/perguntas`

Lista o catálogo fixo de perguntas do tenant (para popular o formulário de lançamento e os selects de filtro).

**Response** (200): `[{ "id": 1, "codigo": "atendimento_geral", "nome": "Atendimento Geral", "ordem": 1 }]` (somente `ativo = true`).

---

## `GET /ouvidoria/pesquisa-satisfacao`

**Query**: `year: number` (obrigatório), `month?: number`.

**Response** (200): `[{ "id": "uuid", "perguntaId": 1, "ano": 2026, "mes": 6, "valor": 8.5, "origem": "manual" }]`

---

## `POST /ouvidoria/pesquisa-satisfacao`

**Body**:

```json
{ "perguntaId": 1, "ano": 2026, "mes": 6, "valor": 8.5 }
```

**Comportamento**: **Upsert** por `[tenantId, perguntaId, ano, mes]` (FR-006). Se já existir (de migração ou lançamento anterior), sobrescreve `valor` e marca `origem = 'manual'` (Clarification 5 — última gravação vence, sem trava).

**Response** (200/201): registro criado/atualizado, mesmo shape do GET.

**Erros**: `400` se `mes` fora de 1–12 ou `ano` fora de faixa razoável (Zod); `404` se `perguntaId` não existir/não pertencer ao tenant/estiver inativo.
