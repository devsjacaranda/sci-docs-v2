# Contract: Export e-SUS — Ficha de Atendimento Individual (FAI)

**Feature**: 026-esus-mockdown-export  
**Mapper**: `lib/esus-export.ts`  
**Schema Zod**: `schemas/esus-fai.schema.ts`  
**Herança**: [024 esus-fai-export.md](../../arquivados/024-saude-atendimento-ubs/contracts/esus-fai-export.md)

## Objetivo

Gerar JSON legível compatível com a **Ficha de Atendimento Individual** do e-SUS APS (CDS/PEC), mapeando DTOs internos camelCase → campos nacionais snake_case. **Não** gera Thrift/LEDI XML; **não** envia ao centralizador/SISAB.

## API pública (lib)

```typescript
exportConsultaToFai(
  consulta: Consulta,
  refs: ConsultaExportRefs,
  options?: { includeDemoExtensions?: boolean; exames?: ExameSolicitado[] },
): EsusFaiPayload

validateConsultaExportReady(
  consulta: Consulta,
  refs: ConsultaExportRefs,
  options?: { exames?: ExameSolicitado[] },
): ExportValidationResult

buildExportFilename(consulta: Consulta, refs: ConsultaExportRefs): string
```

## Estrutura top-level

```typescript
type EsusFaiPayload = {
  tipoFicha: 'cadastroIndividual'
  uuidFicha: string
  tpCdsOrigem: 3
  headerTransport: EsusHeaderTransport
  identificacaoUsuarioCidadao: EsusIdentificacaoCidadao
  atendimentosIndividuais: EsusAtendimentoIndividual[]
  _demoExtensions?: EsusDemoExtensions
}
```

## Mapeamento dimensão → e-SUS

Ver tabela completa em [024 contract](../../arquivados/024-saude-atendimento-ubs/contracts/esus-fai-export.md). Resumo obrigatório:

### headerTransport

| Campo interno | Campo FAI |
|---------------|-----------|
| `profissional.cns` | `nuCns` |
| `profissional.cbo.codigo` | `cboCodigo_2002` |
| `equipe.ine` | `nuIne` |
| `unidade.cnes` | `nuCnes` |
| `consulta.dataInicio` | `dataAtendimento` |
| `consulta.turno` | `turno` (1–3) |

### Cidadão, atendimento, clínico, procedimentos, conduta

Idêntico ao contrato 024 — enums conduta e-SUS (retorno=1, encaminhamento=4, alta=11).

## Campos obrigatórios (`validateConsultaExportReady`)

- Status conferência `pronto_envio`
- `headerTransport.nuCns`, `cboCodigo_2002`, `nuCnes`
- `identificacaoUsuarioCidadao` — CNS **ou** CPF
- `dataNascimentoCidadao`
- `atendimentosIndividuais[0].dataAtendimento` (via header)
- ≥1 condição: CID, CIAP ou texto avaliação
- Regras `detectInconsistencias` sem flags impeditivas

## Exemplo reduzido

```json
{
  "tipoFicha": "cadastroIndividual",
  "uuidFicha": "550e8400-e29b-41d4-a716-446655440000",
  "tpCdsOrigem": 3,
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

- Snapshot JSON consulta seed `pronto_envio`
- `validateConsultaExportReady` → `missing` quando CNES ausente
- Round-trip: `esusFaiSchema.parse` após export
- Gate: status ≠ `pronto_envio` → missing inclui mensagem conferência
