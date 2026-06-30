# Quickstart: Exportação e-SUS — Dados Mockdown

**Feature**: 026-esus-mockdown-export · **Status**: Planejado

## Pré-requisitos

- Node.js 20+
- Módulo Saúde mockdown entregue (spec 024 arquivada)
- Dependências em `sci-client-monorepo`

```powershell
cd sci-client-monorepo
npm install
```

## Subir o client

```powershell
cd sci-client-monorepo
npm run dev
```

Autenticar com usuário licença **Base** (módulo Saúde).

## Seed demo Careiro

Primeira visita ao módulo popula consultas, cadastros e conferência. Para reset:

```javascript
Object.keys(localStorage).filter(k => k.startsWith('ci:saude:')).forEach(k => localStorage.removeItem(k))
```

Recarregar `/saude/atendimento` para re-seed.

## Cenários de validação manual

### 1. Export FAI — happy path (P1)

1. **Saúde → Controle → Conferência**
2. Localizar consulta finalizada; alterar status para **Pronto p/ envio**
3. Abrir **Detalhe** da consulta (ícone olho)
4. Clicar **Exportar e-SUS**

**Esperado**:
- Sheet abre com JSON FAI formatado
- Campos `nuCns`, `nuCnes`, `cnsCidadao`, procedimentos SIGTAP visíveis
- Botão **Baixar JSON** gera arquivo `fai-*.json`

### 2. Bloqueio — status conferência (P1)

1. Consulta com status **Pendente** ou **Conferido**
2. Tentar exportar no detalhe

**Esperado**: toast informando necessidade de status "Pronto para envio" — **sem** download.

### 3. Bloqueio — dados incompletos (P1)

1. Editar consulta removendo CID/CIAP e texto avaliação
2. Marcar `pronto_envio` na conferência
3. Tentar exportar

**Esperado**: lista de pendências ("Avaliação clínica incompleta") — **sem** payload parcial.

### 4. Extensões demo (P2)

1. Consulta seed com receita + exame vinculado
2. Exportar com extensões habilitadas
3. Aba **Extensões** no Sheet

**Esperado**:
- `medicamentosPrescritos` com `codigoValidacao`
- Banner "Complemento de demonstração — não MS"
- Exame com solicitante médico (CBO 225*) sem warning

### 5. Inconsistência solicitante exame (P2)

1. Seed ou consulta com exame solicitado por enfermeiro (se existir no mock)
2. Exportar

**Esperado**: warning "Exame solicitado por profissional não médico" — FAI core ainda exportável.

### 6. Pacote cadastros (P3)

1. **Saúde → Cadastros** (dashboard)
2. **Exportar cadastros demo**

**Esperado**: JSON com ~8 UBS, profissionais CNS/CBO, cidadãos sintéticos; `_demo: true`.

### 7. Consistência cruzada (P3)

1. Exportar FAI de consulta X
2. Exportar pacote cadastros
3. Verificar CNS cidadão/profissional e CNES unidade presentes em ambos

**Esperado**: identificadores idênticos.

## Testes automatizados

```powershell
cd sci-client-monorepo/apps/web
npm test -- esus-export
npm test -- esus-fai
npm test -- EsusExport
```

**Esperado**: snapshots FAI estáveis; validate missing 100% nos casos negativos.

## Referências

- Contrato FAI: [contracts/esus-fai-export.md](./contracts/esus-fai-export.md)
- Extensões: [contracts/esus-export-extensions.md](./contracts/esus-export-extensions.md)
- Data model: [data-model.md](./data-model.md)
- Skill e-SUS: `.cursor/skills/esus-aps/SKILL.md`

## Fora deste quickstart

- Importação no PEC real
- Transmissão LEDI Thrift
- Backend NestJS
