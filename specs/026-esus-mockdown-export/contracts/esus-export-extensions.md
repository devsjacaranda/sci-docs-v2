# Contract: Extensões Demo — Export e-SUS

**Feature**: 026-esus-mockdown-export  
**Namespace**: `_demoExtensions` no payload FAI  
**LEDI ref**: 7.4.2 (campos **não oficiais** MS)

## Objetivo

Incluir receitas, exames e solicitações vinculados à consulta mockdown em bloco **claramente separado** da FAI clássica, para narrativa completa de demonstração Careiro sem inventar campos CDS oficiais.

## Estrutura

```typescript
type EsusDemoExtensions = {
  _demo: true
  _lediVersion: '7.4.2'
  _disclaimer: 'Complemento de demonstração CI v2 — não faz parte do layout FAI oficial MS'
  medicamentosPrescritos?: MedicamentoPrescritoDemo[]
  examesSolicitados?: ExameSolicitadoDemo[]
  solicitacoesRelacionadas?: SolicitacaoDemo[]
}
```

## medicamentosPrescritos

Origem: `consulta.itensReceita[]` (não revogados).

| Campo | Tipo | Obrigatório |
|-------|------|-------------|
| `principioAtivo` | string | sim |
| `posologia` | string | sim |
| `usoContinuo` | boolean | sim |
| `codigoValidacao` | string | sim |
| `dose` | string? | não |
| `frequencia` | string? | não |

**Privacidade**: não incluir texto clínico SOAP na extensão receita.

## examesSolicitados

Origem: `listExames` filtrado por `consultaId`.

| Campo | Tipo | Notas |
|-------|------|-------|
| `codigo` | string | SIGTAP |
| `descricao` | string | |
| `dataSolicitacao` | string | ISO date |
| `prioridade` | `'rotina' \| 'urgente'` | |
| `solicitanteNome` | string | |
| `solicitanteCns` | string | |
| `solicitanteCbo` | string | |
| `solicitanteInconsistente` | boolean | `true` se CBO ∉ 225* |

### Regra FR-008

- `solicitanteInconsistente: true` → adicionar em `warnings` do validate, **não** em `missing`
- UI preview: badge "Inconsistência APS" na seção Extensões

## solicitacoesRelacionadas (opcional)

Origem: fila `SolicitacaoCidadao` mesma `unidadeId` + nome cidadão correlacionado (heurística demo).

| Campo | Tipo |
|-------|------|
| `tipo` | TipoSolicitacao |
| `descricao` | string |
| `status` | StatusSolicitacao |
| `createdAt` | string |

## UI — separação visual

Preview Sheet deve renderizar:

1. **FAI oficial (subset)** — sem prefixo `_demo`
2. **Divisor** — "Complementos de demonstração (não MS)"
3. **`_demoExtensions`** — JSON colapsável ou aba dedicada

## Testes

- Consulta com receita → extensão presente; FAI core unchanged vs snapshot sem extensão
- Exame enfermeiro solicitante → `solicitanteInconsistente: true` + warning
- Consulta sem itens → `_demoExtensions` omitido ou campos arrays ausentes
