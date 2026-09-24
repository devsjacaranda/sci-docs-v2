# Contrato: Desfecho AGEMAN — Relatório de Gestão (gap 1)

Delta sobre [042 contracts/relatorio-gestao.md](../../042-relatorio-gestao-ouvidoria/contracts/relatorio-gestao.md) e [049 contracts](../049-ajustes-relatorio-gestao-ouvidoria/contracts/ajustes-relatorio-gestao.md).

## `POST /ouvidoria/manifestacoes/:id/encerrar` (alterado)

**Body** (shape Zod):

```json
{
  "houveResolucao": false,
  "desfechoEncerramento": "meio_juridico",
  "motivo": "string opcional",
  "medidasResolucao": "string opcional"
}
```

- `desfechoEncerramento`: enum `'meio_juridico' | 'sem_resolucao_outros'`.
- **Obrigatório** quando `houveResolucao === false`.
- **Proibido** (400) quando `houveResolucao === true` (ignorar ou rejeitar se enviado).
- Encerramento legacy (body string): inalterado.

**Response**: manifestação atualizada inclui `desfechoEncerramento` nullable quando aplicável.

---

## `GET /ouvidoria/relatorio-gestao` (alterado)

**Query**: inalterada (`year?`, `month?`).

### KPIs (`kpis`) — campos novos / deprecados

```json
{
  "kpis": {
    "total": 526,
    "pendentes": 2,
    "emAnalise": 1,
    "resolvidaPelaAgeman": 524,
    "meioJuridico": 0,
    "pendente": 2,

    "respondidas": 16,
    "encerradasComResolucao": 2,
    "encerradasSemResolucao": 3
  }
}
```

- **Primários (UI relatório AGEMAN)**: `resolvidaPelaAgeman`, `meioJuridico`, `pendente`.
- **Legado (deprecar em UI relatório; manter 1 release)**: `respondidas`, `encerradasComResolucao`, `encerradasSemResolucao` — preenchidos por compatibilidade a partir dos mesmos dados de status.
- KPI `pendente` (desfecho) ≡ bucket planilha "DEMANDAS PENDENTES"; pode diferir de `kpis.pendentes` (operacional) — documentar no mapper: desfecho usa status não finalizados (`draft`, `in_review`, `forwarding`).

### Bloco novo — substitui `demandasFinalizadas`

**Removido**:

```json
"demandasFinalizadas": [{ "month": 8, "respondidas": 0, "arquivadasOk": 0, "arquivadas": 1 }]
```

**Adicionado**:

```json
"demandasPorDesfecho": [
  { "month": 8, "resolvidaPelaAgeman": 103, "meioJuridico": 0, "pendente": 2 }
]
```

- Cohort: `createdAt` no período filtrado.
- Meses omitidos quando série zerada (mesma regra `omitZeroSeries`).

### Resolutividade AGEMAN (opcional neste gap — preferível entregar)

```json
"demandasEResolutividade": {
  "resolvidaPelaAgeman": 524,
  "meioJuridico": 0,
  "pendente": 2,
  "percentualResolutividade": 0.9962
}
```

`percentualResolutividade = resolvidaPelaAgeman / total` (0 se total = 0).

### Inalterado neste gap

`resolutividade[]` (série por `arquivadoEm`), `orientacoesEncaminhamentos`, `pesquisaSatisfacao`, `participacaoEventos`, demais blocos.

---

## `GET /ouvidoria/relatorio-gestao/pdf|excel|docx`

- Seção **"Finalizadas e respondidas"** → **"Demandas por desfecho"** com colunas: Mês | Resolvida pela AGEMAN | Meio jurídico | Pendente.
- KPIs PDF: refletir campos primários acima.

---

## `GET /ouvidoria/dashboard`

**v1 gap 1**: response pode permanecer com `demandasFinalizadas` / KPIs legados; refatoração dashboard → gap futuro ou mesma spec fase 2. Relatório é source of truth para paridade planilha.
