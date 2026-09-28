# Contrato: Matriz Concessão × Desfecho + Filtro de Concessão (AGEMAN)

Delta sobre [042 contracts/relatorio-gestao.md](../../042-relatorio-gestao-ouvidoria/contracts/relatorio-gestao.md), [049](../../049-ajustes-relatorio-gestao-ouvidoria/contracts/ajustes-relatorio-gestao.md) e [050-desfecho contracts/desfecho-relatorio-gestao.md](../../050-relatorio-gestao-desfecho-ageman/contracts/desfecho-relatorio-gestao.md) (este último como referência de nomenclatura — **não** assume o design de enum `desfechoEncerramento` ali proposto; ver `research.md` §1).

---

## `GET /ouvidoria/relatorio-gestao` (estendido)

**Query**: inalterada (`year?`, `month?`).

### Bloco novo — `concessaoPorDesfecho`

```json
"concessaoPorDesfecho": [
  {
    "concessao": "Água / Saneamento",
    "resolvidaPelaAgeman": 73,
    "meioJuridico": 0,
    "pendente": 12,
    "pendenteEncerradaLegado": 1,
    "total": 86
  },
  {
    "concessao": "Coleta de Lixo",
    "resolvidaPelaAgeman": 0,
    "meioJuridico": 0,
    "pendente": 0,
    "pendenteEncerradaLegado": 0,
    "total": 0
  }
]
```

- Uma linha por concessão canônica conhecida (`AGEMAN_PROGRAMA_LABEL` + `"Não informado"`), **mesmo com `total: 0`** — não se aplica `omitZeroSeries` aqui (dimensão finita, não série temporal).
- `concessao`: rótulo canônico — para o código `'5'` (Estacionamento Rotativo) MUST ser `"Estacionamento Rotativo (Zona Azul)"`, não o valor bruto `"Zona Azul"` que o `CASE` SQL legado retorna (via `normalizeConcessaoSqlLabel`, `lib/concessao-label.ts` — ver `research.md` §5; divergência encontrada entre `sqlMapProgramaConcessaoCase`, `AGEMAN_PROGRAMA_LABEL` e `AGEMAN_TIPO_MANIFESTACAO_OPTIONS`). `AGEMAN_PROGRAMA_LABEL` em si **não** é alterado (preserva o endpoint público `ListProgramasPublicosUseCase`).
- `pendente`: demandas daquele tipo de concessão **ainda não encerradas** no período (ver `data-model.md` §3) — coluna "Pendente" da planilha AGEMAN.
- `pendenteEncerradaLegado`: demandas **já encerradas** antes desta feature com o desfecho legado "Pendente" (`closed_unresolved`) — bucket histórico, não recebe novas entradas após esta feature (FR-004). Rótulo de exibição: **"Pendente (desfecho)"** (mesmo texto de `STATUS_OPTIONS`, não um rótulo novo). **Não somar** com `pendente` na UI/PDF/Excel sem indicação clara de que são conceitos diferentes.
- `total = resolvidaPelaAgeman + meioJuridico + pendente + pendenteEncerradaLegado`.

### Inalterado neste contrato

Todos os demais blocos do relatório (`kpis`, `resolutividade`, `demandasFinalizadas`/`demandasPorDesfecho`, `demandasPendentes`, `porTipo`/`porTipoManifestacao`, `porFormaAtendimento`, `porMotivo`, `orientacoesEncaminhamentos`, `pesquisaSatisfacao`, `participacaoEventos`) — esta feature **não** altera o shape desses blocos, só adiciona `concessaoPorDesfecho`.

---

## `GET /ouvidoria/relatorio-gestao/pdf|excel|docx` (estendido)

- Nova seção/aba **"Concessão × Desfecho"** com colunas: Concessão | Resolvida pela AGEMAN | Meio Jurídico | Pendente | Pendente (desfecho) | Total — as 4 colunas de desfecho são sempre exibidas (não são opcionais/auxiliares), consistente com FR-001 (4 colunas).

---

## `POST /ouvidoria/manifestacoes/:id/encerrar` (restringido)

**Body** (delta sobre o schema atual `encerrarBodySchema`):

```json
{
  "desfecho": "resolvida",
  "motivo": "string opcional",
  "medidasResolucao": "string opcional"
}
```

- `desfecho`: enum passa de `'resolvida' | 'meio_juridico' | 'pendente'` para **`'resolvida' | 'meio_juridico'`** (FR-003). Enviar `'pendente'` responde **400** (`OUVIDORIA_ERROR.RESOLUTION_FLAG_REQUIRED` ou código equivalente de validação Zod).
- Comportamento para `houveResolucao`/desfecho ausente: inalterado (`OUVIDORIA_ERROR.RESOLUTION_FLAG_REQUIRED`).

---

## `GET /ouvidoria/manifestacoes` (estendido)

**Query** — novo parâmetro opcional:

```
concessao?: string   // rótulo canônico (ex.: "Água / Saneamento", "Estacionamento Rotativo (Zona Azul)") ou "Não informado"
```

- Combinável com `status`, `type`, `priority`, `from`/`to`, etc. (todos os filtros já existentes, aplicados em conjunto).
- Resolvido pela mesma expressão de concessão usada no relatório (`sqlMapProgramaConcessaoCase`), aplicada a `programa`/`serviceMode` de cada manifestação.
- Valor não reconhecido ⇒ resultado vazio (sem erro 400) — mesmo comportamento tolerante de outros filtros textuais da lista.

### Opções do filtro (metadados)

Fonte das opções exibidas na UI: lista de concessões **distintas presentes no tenant** (endpoint/agregação leve — detalhe de implementação em `tasks.md`). Tenant sem nenhuma concessão mapeável ⇒ lista vazia ⇒ UI **não renderiza** o controle de filtro (FR-007, decisão em `research.md` §4).

---

## Rótulos (sem mudança de shape de contrato)

Textos "Em análise" → "Pendente" nas superfícies listadas em `data-model.md` §5. Nenhum destes é um campo de contrato JSON alterado — são apenas strings de rótulo/copy (client) ou colunas textuais de export (PDF/Excel), portanto **não versionadas como breaking change de API**.
