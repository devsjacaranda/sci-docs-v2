# Contract: Export e-SUS — Ficha de Atendimento Individual (FAI)

**Feature**: 024-saude-atendimento-ubs  
**Mapper**: `lib/esus-export.ts`  
**Schema Zod**: `schemas/esus-fai.schema.ts`

## Objetivo

Gerar JSON legível compatível com a **Ficha de Atendimento Individual** do e-SUS APS (CDS/PEC), mapeando DTOs internos camelCase → campos nacionais snake_case. **Não** gera thrift/LEDI; **não** envia ao centralizador/SISAB.

## Estrutura top-level

```typescript
type EsusFaiPayload = {
  tipoFicha: 'cadastroIndividual' // header fixo demo
  uuidFicha: string               // consulta.id
  tpCdsOrigem: 3                  // PEC
  headerTransport: EsusHeaderTransport
  identificacaoUsuarioCidadao: EsusIdentificacaoCidadao
  atendimentosIndividuais: EsusAtendimentoIndividual[]
}
```

## Mapeamento dimensão → e-SUS

### 1. Profissional e local (`headerTransport`)

| Campo interno | Campo FAI | Origem |
|---------------|-----------|--------|
| `profissional.cns` | `nuCns` | tb_prof |
| `profissional.cbo.codigo` | `cboCodigo_2002` | tb_lotacao |
| `equipe.ine` | `nuIne` | tb_equipe |
| `unidade.cnes` | `nuCnes` | tb_unidade_saude |
| `consulta.dataInicio` | `dataAtendimento` | ISO date |
| `consulta.dataInicio` | `turno` | 1=manhã, 2=tarde, 3=noite |
| — | `profissionalCbo` | `{ codigo, descricao }` |

### 2. Cidadão (`identificacaoUsuarioCidadao`)

| Campo interno | Campo FAI |
|---------------|-----------|
| `cidadao.cns` | `cnsCidadao` |
| `cidadao.cpf` | `cpfCidadao` |
| `cidadao.dataNascimento` | `dataNascimentoCidadao` |
| `cidadao.sexo` | `sexoCidadao` (M/F/I) |

### 3. Dados do atendimento (`atendimentosIndividuais[]`)

| Campo interno | Campo FAI |
|---------------|-----------|
| `tipoAtendimento` | `tipoAtendimento` (enum e-SUS 1-6) |
| `localAtendimento` | `localDeAtendimento` |
| `consulta.status` | metadata interna — **omitir** do FAI |

### 4. Conteúdo clínico

| Campo interno | Campo FAI |
|---------------|-----------|
| `clinico.subjetivo` | `subjetivo` (texto — extensão demo) |
| `clinico.avaliacao` | `avaliacao` |
| `clinico.plano` | `plano` |
| `clinico.condicoes[cid10]` | `problemasCondicoes[].ciapCid` |
| `clinico.conduta` | `condutas[]` / desfecho |

Enums conduta e-SUS (exemplos):

| Interno | Código FAI |
|---------|------------|
| retorno | 1 |
| encaminhamento | 4 |
| alta | 11 |

### 5. Procedimentos

```typescript
procedimentos: consulta.procedimentos.map(p => ({
  codigo: p.sigtap.codigo,
  descricao: p.sigtap.descricao,
  cidPrincipal: p.cidPrincipal?.codigo,
}))
```

### 6. Medicamentos

Receitas **não** fazem parte do FAI CDS clássico — incluir em bloco extension `medicamentosPrescritos` para rastreio demo:

```typescript
medicamentosPrescritos?: Array<{
  principioAtivo: string
  posologia: string
  usoContinuo: boolean
  codigoValidacao: string
}>
```

Documentar como extensão demo — não bloqueia export principal.

## Campos obrigatórios export (`validateConsultaExportReady`)

- `headerTransport.nuCns`
- `headerTransport.cboCodigo_2002`
- `headerTransport.nuCnes`
- `identificacaoUsuarioCidadao` — CNS **ou** CPF
- `identificacaoUsuarioCidadao.dataNascimentoCidadao`
- `atendimentosIndividuais[0].dataAtendimento`
- Pelo menos uma condição CID **ou** CIAP **ou** texto avaliação

## Exemplo reduzido

```json
{
  "tipoFicha": "cadastroIndividual",
  "uuidFicha": "550e8400-e29b-41d4-a716-446655440000",
  "headerTransport": {
    "nuCns": "898001234567890",
    "cboCodigo_2002": "225125",
    "nuIne": "0000123456",
    "nuCnes": "2345678",
    "dataAtendimento": "2026-06-15",
    "turno": 1
  },
  "identificacaoUsuarioCidadao": {
    "cnsCidadao": "898009876543210",
    "dataNascimentoCidadao": "1985-03-20",
    "sexoCidadao": "F"
  },
  "atendimentosIndividuais": [{
    "tipoAtendimento": 2,
    "localDeAtendimento": 1,
    "problemasCondicoes": [{ "ciapCid": "T91", "sistema": "ciap2" }],
    "procedimentos": [{ "codigo": "0301100039", "descricao": "Aferição PA" }],
    "condutas": [1]
  }]
}
```

## Testes de contrato

- Snapshot JSON de consulta seed completa
- `validateConsultaExportReady` retorna `missing` quando CNES ausente
- Round-trip: parse `esusFaiSchema` após export
