# Contract: Pacote Cadastros Demo — Export e-SUS

**Feature**: 026-esus-mockdown-export  
**Mapper**: `lib/esus-cadastros-export.ts`

## Objetivo

Exportar snapshot dos cadastros mockdown (cidadãos, UBS, profissionais, medicamentos) com identificadores canônicos e-SUS para workshops de implantação (US5 / FR-010).

## API

```typescript
exportCadastrosDemoPackage(tenantId?: string): EsusCadastrosDemoPackage
```

## Payload

```typescript
type EsusCadastrosDemoPackage = {
  _demo: true
  _disclaimer: string
  exportedAt: string
  tenantId: string
  cidadaos: Array<{
    id: string
    cns?: string
    cpf?: string
    nome: string
    dataNascimento: string
    sexo: string
  }>
  unidades: Array<{
    id: string
    cnes: string
    nome: string
    tipo: string
    ativo: boolean
  }>
  profissionais: Array<{
    id: string
    cns: string
    nome: string
    cboCodigo: string
    cboDescricao: string
    unidadeId: string
    equipeId?: string
    ativo: boolean
  }>
  medicamentos: Array<{
    id: string
    principioAtivo: string
    formaFarmaceutica: string
    unidadeFornecimento: string
  }>
}
```

## Filename

`cadastros-demo-{tenantId}-{YYYYMMDD}.json`

## Consistência cruzada (SC-005)

Teste integração: para consulta seed exportada, CNS cidadão/profissional e CNES unidade no FAI **DEVEM** existir no pacote cadastros do mesmo tenant.

## UI

- Botão secundário em **Saúde → Cadastros** dashboard ou **Controle**
- Copy: "Exportar cadastros demo (e-SUS)"
- Badge `_demo` visível no preview antes do download

## Fora de escopo

- CATMAT completo (medicamentos mock não têm código CATMAT hoje — campo reservado futuro)
- Cadastro Individual LEDI XML
