# Contract: Client DTOs — Saúde

**Feature**: 024-saude-atendimento-ubs  
**Module**: `apps/web/src/modules/saude/`

## Convenções

- Tipos TS exportados de `api/types.ts`
- Schemas Zod espelhados em `schemas/*.schema.ts`
- Facades `api/*.ts` delegam a stores — **sem** `apiFetch` nesta entrega
- Naming **camelCase** interno; export e-SUS em snake_case via mapper

## Store API (facades)

### consultas.ts

```typescript
listConsultas(filters?: { unidadeId?: string; profissionalId?: string; mes?: string }): ConsultaListItem[]
getConsulta(id: string): Consulta | null
createConsulta(input: CreateConsultaInput): Consulta
updateConsulta(id: string, input: UpdateConsultaInput): Consulta
deleteConsulta(id: string): void
updateConferencia(id: string, status: StatusConferencia): Consulta
```

### cidadaos.ts / profissionais.ts / unidades.ts / medicamentos.ts

CRUD padrão: `list`, `get`, `create`, `update`, `delete`.

### receitas-relatorio.ts

```typescript
listReceitasRelatorio(filters: ReceitasRelatorioFilters): ReceitaRelatorio[]
groupReceitasByMedicoMes(items: ReceitaRelatorio[]): ReceitasGrouped[]
```

### exames-relatorio.ts

```typescript
listExamesRelatorio(filters: ExamesRelatorioFilters): ExameSolicitado[]
// Garantia: todos solicitantes passam isMedicoCbo(cbo)
```

### solicitacoes.ts

```typescript
listSolicitacoes(filters?: { unidadeId?: string; status?: StatusSolicitacao }): SolicitacaoCidadao[]
createSolicitacao(input: CreateSolicitacaoInput): SolicitacaoCidadao
updateSolicitacao(id: string, input: UpdateSolicitacaoInput): SolicitacaoCidadao
```

## lib/receita-signature.ts

```typescript
generateReceitaCodigo(receita: Pick<ItemReceita, 'id'> & { profissionalCns: string; dataEmissao: string }): string
validateReceitaCodigo(codigo: string): ValidacaoReceitaResult

type ValidacaoReceitaResult =
  | { valid: true; prescritor: string; data: string; unidade: string }
  | { valid: false; reason: 'not_found' | 'revoked' | 'invalid_format' }
```

## lib/esus-export.ts

```typescript
exportConsultaToFai(consulta: Consulta, refs: ConsultaExportRefs): EsusFaiPayload
validateConsultaExportReady(consulta: Consulta, refs: ConsultaExportRefs): { ok: true } | { ok: false; missing: string[] }

type ConsultaExportRefs = {
  cidadao: Cidadao
  profissional: Profissional
  unidade: UnidadeSaude
  equipe?: Equipe
}
```

## lib/conferencia-rules.ts

```typescript
detectInconsistencias(consulta: Consulta, refs: ConsultaExportRefs): string[]
// Ex.: 'cidadao_sem_cns', 'avaliacao_sem_cid_ciap', 'procedimento_sem_sigtap'
```

## lib/unidades-stats.ts

```typescript
computeUnidadeStats(unidadeId: string, periodo: { inicio: string; fim: string }): UnidadeStats
computeIndicadores(filters: IndicadoresFilters): IndicadoresDashboard
```

## lib/indicadores.ts

Agregações para dashboard — delega a stores + stats.

## Persistência

```typescript
// consultas-store.ts
const STORAGE_KEY = (tenantId: string) => `ci:saude:v1:${tenantId}:consultas`
```

Boot: `ensureSaudeSeed(tenantId)` idempotente.

## Zod — exemplos mínimos

```typescript
const codigoClinicoSchema = z.object({
  codigo: z.string().min(1),
  descricao: z.string().min(1),
  sistema: z.enum(['cid10', 'ciap2', 'sigtap', 'cbo']),
})

const createConsultaSchema = z.object({
  cidadaoId: z.string().uuid(),
  profissionalId: z.string().uuid(),
  unidadeId: z.string().uuid(),
  dataInicio: z.string().datetime(),
  tipoAtendimento: z.enum(['consulta_agendada', 'demanda_espontanea', 'urgencia']),
  localAtendimento: z.enum(['ubs', 'domicilio', 'escola', 'outros']),
  clinico: conteudoClinicoSchema,
  procedimentos: z.array(procedimentoSchema).default([]),
  itensReceita: z.array(itemReceitaSchema).default([]),
})
```

## Integração tramitação

```typescript
// uso em ConsultaDetailPage
<TramitarButton
  module="saude"
  moduleLabel="Saúde"
  fields={{
    consultaId: consulta.id,
    cidadao: cidadao.nome,
    ubs: unidade.nome,
  }}
/>
```

Draft inclui `sourceModule: 'saude'`, `sourceRecordId: consulta.id`.
