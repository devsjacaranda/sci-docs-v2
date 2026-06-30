# Data Model: Módulo Saúde — Atendimento UBS / e-SUS

**Feature**: 024-saude-atendimento-ubs · **Date**: 2026-06-29

> DTOs internos em **camelCase** (PT-BR labels na UI). Export e-SUS usa snake_case legado — ver [esus-fai-export.md](./contracts/esus-fai-export.md). Validação: **Zod** em `modules/saude/schemas/`.

## Enums

```typescript
type TurnoAtendimento = 'manha' | 'tarde' | 'noite'
type TipoAtendimento = 'consulta_agendada' | 'demanda_espontanea' | 'urgencia'
type LocalAtendimento = 'ubs' | 'domicilio' | 'escola' | 'outros'
type StatusConsulta = 'rascunho' | 'finalizada' | 'cancelada'
type StatusConferencia = 'pendente' | 'conferido' | 'pronto_envio'
type PrioridadeExame = 'rotina' | 'urgente'
type StatusSolicitacao = 'pendente' | 'em_analise' | 'concluida' | 'cancelada'
type TipoSolicitacao = 'agendamento' | 'medicamento' | 'encaminhamento' | 'outro'
type Sexo = 'feminino' | 'masculino' | 'ignorado'
```

## CodigoClinico (value object)

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `codigo` | string | yes | CID-10 ou CIAP-2 |
| `descricao` | string | yes | Label legível |
| `sistema` | `'cid10' \| 'ciap2'` | yes | |

## Cidadao

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `id` | string | yes | UUID |
| `cns` | string? | no* | 15 dígitos |
| `cpf` | string? | no* | 11 dígitos |
| `nome` | string | yes | |
| `nomeMae` | string? | no | |
| `dataNascimento` | string (ISO date) | yes | |
| `sexo` | Sexo | yes | |
| `telefone` | string? | no | |
| `enderecoResumo` | string? | no | Bairro/logradouro sintético |
| `createdAt` | string | yes | |
| `updatedAt` | string | yes | |

\* Pelo menos um de `cns` ou `cpf`.

## Profissional

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `id` | string | yes | |
| `nome` | string | yes | |
| `cns` | string | yes | |
| `cbo` | CodigoClinico | yes | ex. 225125 Médico clínico |
| `conselhoClasse` | string? | no | CRM/COREN |
| `unidadeId` | string | yes | FK UnidadeSaude |
| `equipeId` | string? | no | FK Equipe |
| `ativo` | boolean | yes | |

## Equipe

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `id` | string | yes | |
| `ine` | string | yes | 10 dígitos |
| `nome` | string | yes | ESF nome popular |
| `unidadeId` | string | yes | |

## UnidadeSaude (UBS)

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `id` | string | yes | |
| `nome` | string | yes | |
| `cnes` | string | yes | 7 dígitos |
| `tipo` | string | yes | UBS, USF, etc. |
| `equipeIds` | string[] | yes | |
| `horarioFuncionamento` | string | yes | ex. "07h–17h seg–sex" |
| `ativo` | boolean | yes | |
| `enderecoResumo` | string? | no | |

## Medicamento

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `id` | string | yes | |
| `principioAtivo` | string | yes | |
| `concentracao` | string? | no | |
| `formaFarmaceutica` | string | yes | |
| `unidadeFornecimento` | string | yes | |

## ConteudoClinico

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `subjetivo` | string? | no | Queixa |
| `objetivo` | string? | no | Exame físico |
| `avaliacao` | string? | no | Texto livre |
| `plano` | string? | no | |
| `condicoes` | CodigoClinico[] | no | CID/CIAP |
| `conduta` | string? | no | Desfecho textual |
| `encaminhamentos` | string[] | no | Destinos |

## ProcedimentoRealizado

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `id` | string | yes | |
| `sigtap` | CodigoClinico | yes | sistema = cid10 placeholder ou campo sigtap |
| `cidPrincipal` | CodigoClinico? | no | |

> Nota: `CodigoClinico` para SIGTAP usa `sistema: 'sigtap'` (estender enum na implementação).

## ItemReceita

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `id` | string | yes | |
| `medicamentoId` | string | yes | FK |
| `medicamentoNome` | string | yes | denormalizado listagem |
| `posologia` | string | yes | |
| `dose` | string? | no | |
| `frequencia` | string? | no | |
| `usoContinuo` | boolean | yes | |
| `quantidade` | number? | no | |
| `condicao` | CodigoClinico? | no | CID ou CIAP (mutuamente exclusivos) |
| `codigoValidacao` | string | yes | gerado por `receita-signature` |
| `revogada` | boolean | yes | default false |

## Consulta (agregado raiz)

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `id` | string | yes | |
| `dataInicio` | string (ISO datetime) | yes | |
| `dataFim` | string? | no | |
| `turno` | TurnoAtendimento | yes | derivável de dataInicio |
| `tipoAtendimento` | TipoAtendimento | yes | |
| `localAtendimento` | LocalAtendimento | yes | |
| `status` | StatusConsulta | yes | |
| `statusConferencia` | StatusConferencia | yes | default pendente |
| `inconsistencias` | string[] | no | flags conferência |
| `cidadaoId` | string | yes | FK |
| `profissionalId` | string | yes | FK |
| `unidadeId` | string | yes | FK |
| `equipeId` | string? | no | FK |
| `clinico` | ConteudoClinico | yes | |
| `procedimentos` | ProcedimentoRealizado[] | yes | default [] |
| `itensReceita` | ItemReceita[] | yes | default [] |
| `createdAt` | string | yes | |
| `updatedAt` | string | yes | |

### State transitions — Consulta

```text
rascunho → finalizada | cancelada
finalizada → (conferência) pendente → conferido → pronto_envio
cancelada (terminal)
```

## ReceitaRelatorio (projeção somente leitura)

| Field | Type | Notes |
|-------|------|-------|
| `id` | string | = itemReceita.id ou composto |
| `consultaId` | string | |
| `dataEmissao` | string | |
| `medicoNome` | string | |
| `medicoId` | string | |
| `unidadeNome` | string | |
| `medicamentoNome` | string | |
| `posologia` | string | |
| `codigoValidacao` | string | |

~400 registros seed; agrupáveis por `medicoId`, mês(`dataEmissao`), período.

## ExameSolicitado (projeção somente leitura)

| Field | Type | Notes |
|-------|------|-------|
| `id` | string | |
| `consultaId` | string | |
| `procedimento` | CodigoClinico | SIGTAP |
| `dataSolicitacao` | string | |
| `dataResultado` | string? | |
| `prioridade` | PrioridadeExame | rotina \| urgente |
| `solicitanteId` | string | FK Profissional — **CBO médico only** |
| `solicitanteNome` | string | |
| `unidadeId` | string | |

~100 registros seed; enfermeiros excluídos na geração.

## SolicitacaoCidadao (fila editável)

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `id` | string | yes | |
| `cidadaoNome` | string | yes | texto livre ou FK futuro |
| `cidadaoContato` | string? | no | |
| `unidadeId` | string | yes | |
| `tipo` | TipoSolicitacao | yes | |
| `descricao` | string | yes | |
| `status` | StatusSolicitacao | yes | |
| `observacaoInterna` | string? | no | |
| `createdAt` | string | yes | |
| `updatedAt` | string | yes | |

## UnidadeStats (agregado derivado)

| Field | Type | Notes |
|-------|------|-------|
| `unidadeId` | string | |
| `consultasNoPeriodo` | number | |
| `receitasNoPeriodo` | number | |
| `examesNoPeriodo` | number | |
| `periodoLabel` | string | ex. "Jun/2026" |

Calculado por `lib/unidades-stats.ts` — **não persistido**.

## ExportacaoFai (DTO export — ver contrato)

Payload JSON separado; não armazenado; gerado on-demand por `lib/esus-export.ts`.

## Relacionamentos

```text
UnidadeSaude 1──* Equipe
UnidadeSaude 1──* Profissional
Cidadao 1──* Consulta
Profissional 1──* Consulta
Consulta 1──* ProcedimentoRealizado
Consulta 1──* ItemReceita
Consulta 0──* ExameSolicitado (projeção)
UnidadeSaude 1──* SolicitacaoCidadao
```

## Validação Zod (regras de negócio)

- Consulta save: `cidadaoId`, `profissionalId`, `unidadeId`, `dataInicio` obrigatórios.
- UBS `ativo === false` → bloquear create consulta.
- ItemReceita: `condicao` — no máximo um CID **ou** um CIAP (espelha CK e-SUS).
- Exame seed/query: filtrar profissionais onde `cbo.codigo` starts with `225`.
- Export FAI: falhar com lista de campos ausentes se CNS profissional, CNES ou identificação cidadão faltando.
