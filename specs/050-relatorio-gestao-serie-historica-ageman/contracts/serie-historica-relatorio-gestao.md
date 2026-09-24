# Contrato: Série histórica — Relatório de Gestão da Ouvidoria

Rotas em `OuvidoriaController`, `@RequireModulo('ouvidoria')`, tenant via `AsyncLocalStorage`.

Complementa [`042-relatorio-gestao-ouvidoria/contracts/relatorio-gestao.md`](../../042-relatorio-gestao-ouvidoria/contracts/relatorio-gestao.md) — **não altera** query nem body do `GET /ouvidoria/relatorio-gestao`.

## Conceito `modo=historico` (produto, não query)

A “visão histórica” da planilha RESUMO GERAL / MENSAL_DEMAND corresponde a **chamar as rotas abaixo**, não a um parâmetro `modo` no endpoint por período. Isso mantém FR-005 e SC-002.

---

## Tipos compartilhados

```typescript
/** Colunas de ano ordenadas ASC; chaves de byYear são string decimal ("2018"). */
type GradeColunasAno = {
  years: number[];
  grandTotal: number;
};

type GradeMesAnoRow = {
  month: number;           // 1–12
  label: string;           // "Janeiro" … local pt-BR
  byYear: Record<string, number>;
  totalAcumulado: number;  // soma across years para este mês civil
  percentual: number;      // totalAcumulado / grandTotal; 0 se grandTotal === 0
};

type GradeMesAno = GradeColunasAno & {
  rows: GradeMesAnoRow[];
  totals: {
    byYear: Record<string, number>;
    grandTotal: number;
  };
};

type GradeMetricaAnualRow = {
  key: string;             // ex. "resolvidas", "meio_juridico", "pendentes"
  label: string;           // rótulo UI
  byYear: Record<string, number>;
  totalAcumulado: number;
  percentual: number;
};

type GradeMetricaAnual = GradeColunasAno & {
  rows: GradeMetricaAnualRow[];
  totals: { byYear: Record<string, number>; grandTotal: number };
};
```

---

## `GET /ouvidoria/relatorio-gestao/serie-historica`

**Query** (`serieHistoricaQuerySchema`):

| Param | Tipo | Default | Regras |
|-------|------|---------|--------|
| `yearFrom` | `number` | `2018` | 2000–2100 |
| `yearTo` | `number` | ano civil UTC corrente | ≥ `yearFrom` |

- **`year` / `month`**: não suportados — enviar não causa erro, **são ignorados** (documentado para evitar confusão com dashboard).
- Agregação sempre **12 meses** × anos no intervalo inclusivo.

**Comportamento** (FR-007 on-demand, sem cache):

- Contagem de **atendimentos** = manifestações do tenant com `createdAt` no intervalo `[yearFrom-01-01, yearTo-12-31]` (timezone: mesmo critério já usado no relatório 042 — tipicamente UTC ou tenant; implementação MUST reutilizar helper existente de recorte de datas).
- `years` inclui **todos** os inteiros de `yearFrom`..`yearTo` mesmo se count zero.
- `percentual` por linha de mês: `totalAcumulado / grandTotal` (número 0–1).

**Response** (200):

```json
{
  "meta": {
    "yearFrom": 2018,
    "yearTo": 2026,
    "generatedAt": "2026-09-24T12:00:00.000Z"
  },
  "atendimentosMesAno": {
    "years": [2018, 2019, 2020, 2021, 2022, 2023, 2024, 2025, 2026],
    "grandTotal": 5331,
    "rows": [
      {
        "month": 1,
        "label": "Janeiro",
        "byYear": { "2018": 0, "2019": 75, "2026": 53 },
        "totalAcumulado": 411,
        "percentual": 0.07709622960045019
      }
    ],
    "totals": {
      "byYear": { "2018": 761, "2026": 526 },
      "grandTotal": 5331
    }
  },
  "resolutividadeAnual": null,
  "concessaoAnual": null
}
```

**P2**: `resolutividadeAnual` e `concessaoAnual` seguem `GradeMetricaAnual` (sem eixo mês). Linhas de resolutividade (MVP P2):

| `key` | Semântica (alinhar 042) |
|-------|-------------------------|
| `resolvidas` | Encerradas com resolução / equivalente “demandas resolvidas pela ouvidoria” |
| `meio_juridico` | Usuário optou por buscar meio jurídico |
| `pendentes` | Demandas pendentes no fechamento |

Linhas de `concessaoAnual`: uma por tipo canônico de concessionária do tenant + linha `totals`.

**Erros**:

- `400` — `yearFrom` > `yearTo` ou fora de faixa Zod
- `403 MODULO_SETOR_DENIED`

**Performance**: p95 ≤ 5s (SC-003), tenant referência AGEMAN; sem paginação.

---

## `GET /ouvidoria/relatorio-gestao/serie-historica/excel`

**Query**: idêntica a `GET .../serie-historica`.

**Response**: `200`, `Content-Type: application/vnd.openxmlformats-officedocument.spreadsheetml.sheet`, `Content-Disposition: attachment; filename="relatorio-gestao-serie-historica-{yearFrom}-{yearTo}.xlsx"`.

**Abas** (MVP → P2):

1. `Atendimentos mês×ano` — grade completa + linha TOTAL (valores calculados, sem fórmulas)
2. `Resolutividade anual` — quando `resolutividadeAnual` implementado
3. `Concessão anual` — quando `concessaoAnual` implementado

**Performance**: ≤ 30s (SC-003).

---

## O que esta feature **não** expõe

| Item planilha | Motivo |
|---------------|--------|
| `modo=historico` no GET principal | Performance + FR-005 |
| Forma de atendimento mês×canal×ano | Fora MVP — research.md §4 |
| Resolutividade mês×ano (QUANT_MENSAL) | P3 spec |
| Média mensal por ano (“MÉDIA MENSAL=”) | Derivável no client; fora contrato v1 |
| PDF série histórica | P3 spec |

---

## Compatibilidade forward

Clientes que ignoram rotas novas continuam funcionando. Cliente 050 MUST usar apenas estas rotas para grades wide — **não** inferir mês×ano a partir de `atendimentosPorMes` do GET principal (aquele bloco soma meses across years quando `year` ausente).
