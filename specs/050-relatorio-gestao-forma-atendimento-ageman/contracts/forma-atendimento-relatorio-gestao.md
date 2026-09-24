# Contrato: Forma de atendimento — delta vs. 042/049

Rotas inalteradas (`GET /ouvidoria/relatorio-gestao`, `GET /ouvidoria/dashboard/agregacoes`, exports PDF/Excel/bloco PDF). Tenant via `AsyncLocalStorage`; `@RequireModulo('ouvidoria')`.

Contrato base: [`042-relatorio-gestao-ouvidoria/contracts/relatorio-gestao.md`](../../042-relatorio-gestao-ouvidoria/contracts/relatorio-gestao.md).  
Ajustes 049 (orientações, satisfação, eventos): [`049-ajustes-relatorio-gestao-ouvidoria/contracts/ajustes-relatorio-gestao.md`](../../049-ajustes-relatorio-gestao-ouvidoria/contracts/ajustes-relatorio-gestao.md) — **sem alteração** nesta feature.

## Campo alterado: `porFormaAtendimento`

### Antes (comportamento bugado)

```json
"porFormaAtendimento": [
  { "month": 6, "forma": "interna", "total": 70 },
  { "month": 8, "forma": "sem_canal", "total": 14 }
]
```

- `forma` derivada de `COALESCE(dadosAdicionais.formaAtendimento, origem, 'sem_canal')`.

### Depois (comportamento correto)

```json
"porFormaAtendimento": [
  { "month": 6, "forma": "Aplicativos de mensagem", "total": 55 },
  { "month": 6, "forma": "Presencial", "total": 8 },
  { "month": 8, "forma": "Não informado", "total": 2 }
]
```

- `forma` derivada de `COALESCE(NULLIF(TRIM("serviceMode"), ''), 'Não informado')`.
- Valores típicos AGEMAN: descrições do catálogo (`Presencial`, `E-mail`, `0800`, `Fala.Br`, `Aplicativos de mensagem`, `Telefone (celular/fixo)`, `Outros (redes sociais, pedidos, etc)`, `Presencial Ação Social`).
- **`interna`**, **`publica`**, **`sem_canal`** deixam de ser emitidos por este bloco (salvo coincidência acidental improvável em `serviceMode`).

### Filtros

Inalterados — mesma semântica `year`/`month` da spec 042 (incl. acumulado geral = `EXTRACT(MONTH)` somando todos os anos).

### Dashboard

`GET /ouvidoria/dashboard/agregacoes` → `porFormaAtendimento.series[]` — **mesma regra** que acima (mesmo repository).

## Apresentação (frontend / PDF)

| Camada | Responsabilidade |
|--------|------------------|
| API JSON | Valor bruto `forma` (= `serviceMode` ou `Não informado`) |
| Web (tela) | `labelFormaAtendimento(forma)` para exibição |
| PDF/Excel relatório | Preferir rótulo humanizado igual à tela (não slug SQL legado) |

## Rollup AGEMAN (P2 — opcional)

Se implementado, **não** substitui o array acima na API por padrão. Opções compatíveis:

1. **Somente UI**: segundo gráfico "Visão planilha AGEMAN" agrega client-side via mapa D2.
2. **Campo adicional** *(breaking leve — requer acordo)*: `porFormaAtendimentoPlanilhaAgeman[]` com `{ month, bucket, total }` — **fora do MVP** salvo pedido explícito.

Recomendação MVP: opção 1.

## Compatibilidade

- **Breaking para consumidores** que dependiam dos slugs `interna`/`sem_canal` no bloco Forma de atendimento — comportamento incorreto documentado como bug; corrigir testes/fixtures.
- Contrato de `orientacoesEncaminhamentos[].canal` permanece independente (mesmo campo fonte, agregação diferente).

## Erros

Inalterados (`403` módulo). Bloco vazio = array vazio (válido).
