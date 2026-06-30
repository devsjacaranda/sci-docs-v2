# Data Model: Exportação e-SUS — Dados Mockdown

**Feature**: 026-esus-mockdown-export · **Date**: 2026-06-29

> DTOs internos permanecem **camelCase** (`api/types.ts`). Payload export usa **snake_case e-SUS**. Validação export: Zod em `schemas/esus-fai.schema.ts`. Referência arquivada: [024 data-model](../arquivados/024-saude-atendimento-ubs/data-model.md).

## Fluxo de dados

```text
Consulta (store) + refs (Cidadao, Profissional, Unidade, Equipe?)
        │
        ├─ statusConferencia === 'pronto_envio'? ──no──► bloqueio UI
        │
        └─ validateConsultaExportReady()
                 │
                 ├─ ok: false ──► missing[] (PT-BR)
                 │
                 └─ ok: true ──► exportConsultaToFai()
                              │
                              ├─ EsusFaiPayload (core FAI)
                              └─ _demoExtensions? (P2)
```

## EsusFaiPayload (core)

| Campo | Tipo | Obrigatório | Origem interna |
|-------|------|-------------|----------------|
| `tipoFicha` | `'cadastroIndividual'` | sim | constante demo (header fixo 024) |
| `uuidFicha` | string | sim | `consulta.id` |
| `tpCdsOrigem` | `3` | sim | PEC |
| `headerTransport` | object | sim | profissional + unidade + equipe + consulta |
| `identificacaoUsuarioCidadao` | object | sim | `cidadao` |
| `atendimentosIndividuais` | array[1] | sim | consulta clínica + procedimentos |

### headerTransport

| Campo FAI | Origem |
|-----------|--------|
| `nuCns` | `profissional.cns` |
| `cboCodigo_2002` | `profissional.cbo.codigo` |
| `nuIne` | `equipe.ine` (opcional se ausente — pendência se obrigatório demo) |
| `nuCnes` | `unidade.cnes` |
| `dataAtendimento` | `consulta.dataInicio` (ISO date) |
| `turno` | enum 1–3 de `consulta.turno` |
| `profissionalCbo` | `{ codigo, descricao }` |

### identificacaoUsuarioCidadao

| Campo FAI | Origem |
|-----------|--------|
| `cnsCidadao` | `cidadao.cns` |
| `cpfCidadao` | `cidadao.cpf` |
| `dataNascimentoCidadao` | `cidadao.dataNascimento` |
| `sexoCidadao` | M/F/I |

### atendimentosIndividuais[0]

| Campo FAI | Origem |
|-----------|--------|
| `tipoAtendimento` | enum de `consulta.tipoAtendimento` |
| `localDeAtendimento` | enum de `consulta.localAtendimento` |
| `problemasCondicoes` | `clinico.condicoes` (CID/CIAP) |
| `procedimentos` | `consulta.procedimentos` → SIGTAP |
| `condutas` | enum de `clinico.conduta` |
| `subjetivo` / `avaliacao` / `plano` | extensão texto demo (SOAP) |

## validateConsultaExportReady

**Input**: `Consulta`, `ConsultaExportRefs`, opcional `ExameSolicitado[]`

**Output**:

```typescript
type ExportValidationResult =
  | { ok: true }
  | { ok: false; missing: string[]; warnings?: string[] };
```

### Impeditivos (`missing`)

| Regra | Label PT-BR |
|-------|-------------|
| `statusConferencia !== 'pronto_envio'` | Conferência: status deve ser "Pronto para envio" |
| Sem CNS profissional | Profissional sem CNS |
| Sem CBO | Profissional sem CBO |
| Unidade inativa ou sem CNES | Unidade inativa ou sem CNES |
| Cidadão sem CNS e sem CPF | Cidadão sem identificação (CNS ou CPF) |
| Sem data nascimento | Cidadão sem data de nascimento |
| Sem data atendimento | Consulta sem data de atendimento |
| Sem CID/CIAP/avaliação | Avaliação clínica incompleta |
| Flag `detectInconsistencias` | Labels de `getInconsistenciaLabel` |

### Avisos (`warnings`) — não bloqueiam FAI core

| Regra | Label |
|-------|-------|
| Exame solicitante CBO ≠ 225* | Exame solicitado por profissional não médico |
| Cidadão só CPF | Cidadão sem CNS (apenas CPF) — informativo |

## _demoExtensions (P2)

| Campo | Tipo | Origem |
|-------|------|--------|
| `_demo` | `true` | meta |
| `_lediVersion` | `'7.4.2'` | meta |
| `_disclaimer` | string | texto fixo demo |
| `medicamentosPrescritos` | array | `consulta.itensReceita` |
| `examesSolicitados` | array | `ExameSolicitado` por consultaId |
| `solicitacoesRelacionadas` | array? | `SolicitacaoCidadao` correlacionadas |

### medicamentosPrescritos[]

| Campo | Origem |
|-------|--------|
| `principioAtivo` | `medicamentoNome` / catálogo |
| `posologia` | `item.posologia` |
| `usoContinuo` | `item.usoContinuo` |
| `codigoValidacao` | `item.codigoValidacao` |

### examesSolicitados[]

| Campo | Origem |
|-------|--------|
| `codigo` | `procedimento.codigo` (SIGTAP) |
| `descricao` | `procedimento.descricao` |
| `dataSolicitacao` | ISO date |
| `prioridade` | rotina/urgente |
| `solicitanteCns` | lookup profissional |
| `solicitanteCbo` | lookup profissional |
| `solicitanteInconsistente` | boolean CBO ≠ 225* |

## EsusCadastrosDemoPackage (P3)

| Campo | Tipo |
|-------|------|
| `_demo` | `true` |
| `exportedAt` | ISO datetime |
| `tenantId` | string |
| `cidadaos` | subset campos exportáveis |
| `unidades` | CNES, nome, tipo, ativo |
| `profissionais` | CNS, CBO, unidadeId, equipeId |
| `medicamentos` | principioAtivo, forma, unidade |

## EsusBatchExportResult (P3)

```typescript
type EsusBatchExportResult = {
  exported: EsusFaiPayload[];
  skipped: Array<{ consultaId: string; reason: string }>;
  exportedAt: string;
};
```

## State transitions (conferência → export)

```text
pendente ──► conferido ──► pronto_envio ──► [export habilitado]
     │              │              │
     └──────────────┴──────────────┴──► export bloqueado (mensagem status)
```

## Relacionamentos

- **Consulta** 1—N **ProcedimentoRealizado**
- **Consulta** 1—N **ItemReceita**
- **Consulta** 1—N **ExameSolicitado** (via `consultaId`)
- **Consulta** N—1 **Cidadao**, **Profissional**, **UnidadeSaude**, **Equipe?**
- **Exportação** derivada efêmera — sem persistência
