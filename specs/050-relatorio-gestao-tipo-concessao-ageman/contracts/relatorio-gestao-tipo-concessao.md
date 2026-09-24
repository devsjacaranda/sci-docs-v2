# Contrato: Relatório de Gestão — bloco tipo de concessão (050)

Documento **delta** sobre [`042-relatorio-gestao-ouvidoria/contracts/relatorio-gestao.md`](../../042-relatorio-gestao-ouvidoria/contracts/relatorio-gestao.md) e [`049-ajustes-relatorio-gestao-ouvidoria/contracts/ajustes-relatorio-gestao.md`](../../049-ajustes-relatorio-gestao-ouvidoria/contracts/ajustes-relatorio-gestao.md). Rotas, auth e query string **inalteradas**.

## `GET /ouvidoria/relatorio-gestao` (alterado — bloco `porTipoManifestacao`)

### Semântica (breaking de conteúdo, não de shape)

| Antes (042 US4) | Depois (050) |
|-----------------|--------------|
| `type` = enum persistido `Manifestacao.type` (`complaint`, `request`, …) | `type` = **rótulo de tipo de concessão** (espelho de `tipoConcessao`) |
| Sem `tipoConcessao` | `tipoConcessao` = campo **canônico** |

Agregação: `COUNT(*)` por `(EXTRACT(MONTH FROM createdAt), tipoConcessao)` no recorte `year`/`month` da query — mesmas regras de período da spec 042.

Mapa de `tipoConcessao` (ordem de resolução):

1. `CASE TRIM(programa)` → `'Água / Saneamento' | 'Transporte Coletivo' | 'Iluminação Pública' | 'Coleta de Lixo' | 'Zona Azul'`
2. Se NULL: `NULLIF(TRIM(serviceMode), '')`
3. Se ainda NULL/vazio na resposta JSON: `"Não informado"` (normalização no use-case)

**Paridade**: Para o mesmo `year`/`month`, ∀ concessão C:  
`SUM(porTipoManifestacao.total WHERE tipoConcessao=C) = SUM(porMotivo.total WHERE tipoConcessionaria=C)`  
(com C normalizado para `"Não informado"` quando null em ambos os lados).

### Response — trecho alterado

```json
{
  "porTipoManifestacao": [
    {
      "month": 8,
      "tipoConcessao": "Água / Saneamento",
      "type": "Água / Saneamento",
      "total": 86
    },
    {
      "month": 8,
      "tipoConcessao": "Iluminação Pública",
      "type": "Iluminação Pública",
      "total": 3
    }
  ]
}
```

- **`type`**: mantido por compatibilidade estrutural; MUST equal `tipoConcessao` em toda linha. Clientes novos MUST preferir `tipoConcessao`. Clientes MUST NOT interpretar `type` como `ManifestacaoType` neste bloco.
- Valores MUST NOT ser `complaint`, `request`, `praise`, `suggestion`, `denunciation`, `simplifique` após deploy da 050 (salvo bug).

Demais campos da resposta: inalterados (incl. blocos adicionados pela 049).

### Zod / OpenAPI interno

Estender schema em `ouvidoria.schemas.ts`:

```typescript
porTipoManifestacao: z.array(
  z.object({
    month: z.number().int().min(1).max(12),
    tipoConcessao: z.string(),
    type: z.string(), // deprecated semântica; espelho
    total: z.number().int().nonnegative(),
  }),
);
```

## `GET /ouvidoria/relatorio-gestao/pdf`

- Query `bloco=porTipoManifestacao`: **identificador mantido**.
- Título da seção no PDF: **"Tipo de concessão"** (substitui "Tipo de manifestação").
- Colunas da tabela: `Mês | Concessão | Total` (valores = `tipoConcessao`).
- Nota de rodapé opcional (paridade DOCX): *"De acordo com formulário: Abastecimento/saneamento; transporte coletivo e demais opções."*

## `GET /ouvidoria/relatorio-gestao/excel`

- Nome da aba: **"Tipo de concessão"** (substitui "Tipo de manifestação").
- Cabeçalhos: `Mês | Concessão | Total`.
- Linhas: `row.month`, `row.tipoConcessao ?? row.type`, `row.total`.

## Client (`@ci/web`)

| Artefato | Mudança |
|----------|---------|
| `RelatorioGestaoResponse.porTipoManifestacao` | Adicionar `tipoConcessao: string` |
| `mapTipoManifestacaoChart` | Agregar por `tipoConcessao ?? type`; sem `TYPE_OPTIONS` |
| `TipoManifestacaoChartCard` | title/description/emptyLabel → "concessão" |
| Export parcial PDF | Continua `onDownloadBloco('porTipoManifestacao')` |

Rename de componente/arquivo para `TipoConcessaoChartCard` é **opcional** (não afeta contrato HTTP).

## Erros

Inalterados (`403 MODULO_SETOR_DENIED`, etc.).

## Fora de contrato (explicitamente não muda)

- Endpoints de catálogo `OuvidoriaTipoManifestacao` (`POST /ouvidoria/tipos-manifestacao`, …).
- Campo `Manifestacao.type` em CRUD/detalhe/listagem.
- Chave JSON `porMotivo` (já traz `tipoConcessionaria` por linha de motivo).
