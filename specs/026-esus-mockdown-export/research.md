# Research: Exportação e-SUS — Dados Mockdown para Demonstração

**Feature**: 026-esus-mockdown-export · **Date**: 2026-06-29

## R1 — Escopo de implementação (client vs API)

**Decision**: Implementação **100% client-side** em `sci-client-monorepo/apps/web/src/modules/saude/`; nenhum endpoint NestJS.

**Rationale**: Spec 026 e Out of Scope explicitam mock demonstração local; spec 024 já entregou stores e UI; export é transformação read-only sobre dados existentes (FR-012).

**Alternatives considered**:
- API `POST /saude/consultas/:id/export` — rejeitado: escopo inflado, mock não tem backend Saúde.
- Worker Web para JSON grande — rejeitado: volume seed < 500 consultas; main thread suficiente.

---

## R2 — Formato do artefato (JSON legível vs LEDI binário)

**Decision**: JSON pretty-printed com nomes de campo **snake_case e-SUS** (subset FAI LEDI 7.4.2); **sem** Thrift/XML.

**Rationale**: Demonstração contratual e validação humana; skill e-SUS APS recomenda mock client com JSON FAI legível; transmissão real fica fora de escopo.

**Alternatives considered**:
- XML LEDI completo — rejeitado: complexidade XSD/Thrift; spec limita a subset legível.
- CSV flat — rejeitado: perde hierarquia FAI (headerTransport, atendimentosIndividuais[]).

---

## R3 — Contrato FAI base

**Decision**: Reutilizar mapeamento arquivado em `024-saude-atendimento-ubs/contracts/esus-fai-export.md` como contrato canônico; funções `exportConsultaToFai(consulta, refs)` e `validateConsultaExportReady(consulta, refs)`.

**Rationale**: Evita redescoberta de campos; alinhamento LEDI 7.4.2 já documentado na skill `esus-aps`.

**Alternatives considered**:
- Novo contrato do zero — rejeitado: duplicação e risco de divergência.
- DTO e-SUS na UI — rejeitado na 024; mantém camelCase interno.

---

## R4 — Gate de conferência

**Decision**: Exportação bloqueada unless `consulta.statusConferencia === 'pronto_envio'` **e** `validateConsultaExportReady` retorna `{ ok: true }`.

**Rationale**: FR-003/FR-004; fluxo operacional já existe em `SaudeConferenciaPage`; mensagem orienta usuário a atualizar status.

**Alternatives considered**:
- Exportar com status `conferido` — rejeitado: spec exige "pronto para envio".
- Ignorar conferência se validação OK — rejeitado: quebra governança mock.

---

## R5 — Validação: conferência vs export

**Decision**: `validateConsultaExportReady` **compõe** regras de `detectInconsistencias` + checks export-specific (data atendimento, turno, mapeamento enums). Retorno unificado `{ ok, missing: string[] }` com labels PT-BR operacionais.

**Rationale**: DRY — flags conferência já cobrem CNS, CNES, avaliação, SIGTAP; export adiciona apenas campos FAI obrigatórios ausentes na conferência.

**Alternatives considered**:
- Validador duplicado independente — rejeitado: drift entre conferência e export.
- Bloquear export só por inconsistências sem gate status — rejeitado: viola FR-003.

---

## R6 — Extensões demo (receitas, exames, solicitações)

**Decision**: Objeto top-level `_demoExtensions` (meta `_demo: true`, `_lediVersion: '7.4.2'`) contendo:
- `medicamentosPrescritos[]` — de `consulta.itensReceita`
- `examesSolicitados[]` — lookup `exames-relatorio` por `consultaId`
- `solicitacoesCidadao[]` — opcional, fila UBS correlacionada por unidade/cidadão quando existir

**Rationale**: FR-007/FR-008; skill e-SUS: receitas fora FAI clássico; separação visual clara na UI preview.

**Alternatives considered**:
- Misturar receitas dentro de `atendimentosIndividuais` — rejeitado: inventa campo MS.
- Omitir extensões no MVP — rejeitado parcialmente: MVP = FAI core; extensões entram P2 na mesma feature.

---

## R7 — Regra solicitante exame (CBO médico)

**Decision**: Em extensão exames, flag `solicitanteInconsistente: true` quando CBO solicitante não inicia com `225`; incluir na lista `missing`/warnings se política export for strict — default: **exporta FAI core + extensão com warning**, não bloqueia FAI.

**Rationale**: FR-008 pede sinalização; bloqueio total prejudicaria demo de inconsistências Jatobá; FAI core permanece válido.

**Alternatives considered**:
- Bloquear export inteiro — rejeitado: consulta clínica válida não deve perder FAI por exame mal atribuído.
- Silenciar — rejeitado: viola FR-008.

---

## R8 — UI preview e download

**Decision**: `EsusExportSheet` (shadcn Sheet): abas **Resumo** (missing/status), **FAI** (JSON syntax highlight ou `<pre>`), **Extensões** (se houver); botões **Copiar** e **Baixar JSON**. Filename: `fai-{cnes}-{data}-{cidadaoSlug}.json`.

**Rationale**: FR-006, SC-001/SC-004; reutiliza padrão `CopyableField` e toast existentes.

**Alternatives considered**:
- Download direto sem preview — rejeitado: stakeholders precisam inspecionar em demo.
- Modal fullscreen custom — rejeitado: Sheet alinhado ao design system institucional.

---

## R9 — Pacote cadastros (P3)

**Decision**: `exportCadastrosDemoPackage()` retorna JSON `{ _demo: true, cidadaos[], unidades[], profissionais[], medicamentos[], exportedAt }` lendo stores/seed atuais; ação em `SaudeCadastrosDashboardPage` ou submenu Controle.

**Rationale**: FR-010/US5; workshop implantação; independente do MVP FAI.

**Alternatives considered**:
- ZIP multi-arquivo — rejeitado v1: JSON único suficiente para demo.
- Export só entidades da consulta — rejeitado: US5 pede visão cadastros.

---

## R10 — Exportação em lote (P3)

**Decision**: `exportConsultasBatch(ids)` → `{ exported: EsusFaiPayload[], skipped: { id, reason }[] }`; UI opcional na conferência filtrada por `pronto_envio`; download JSON array ou ZIP futuro — v1 array JSON.

**Rationale**: FR-014; conferência já lista consultas elegíveis.

**Alternatives considered**:
- Lote sem relatório skipped — rejeitado: spec exige motivo por registro excluído.

---

## R11 — Enums internos → e-SUS

**Decision**: Mapas centralizados em `esus-export.ts`:

| Interno | FAI |
|---------|-----|
| `consulta_agendada` | 2 |
| `demanda_espontanea` | 4 |
| `urgencia` | 6 |
| `ubs` | 1 |
| `domicilio` | 2 |
| `manha/tarde/noite` | 1/2/3 |
| `feminino/masculino/ignorado` | F/M/I |

**Rationale**: Evita magic numbers espalhados; testável unitariamente.

**Alternatives considered**:
- Enums e-SUS no DTO interno — rejeitado na 024.

---

## R12 — Testes e snapshot

**Decision**: Snapshot Vitest de consulta seed `pronto_envio` completa; testes negativos para cada campo `missing`; round-trip `esusFaiSchema.parse(exportConsultaToFai(...))`.

**Rationale**: Constitution II; contrato arquivado 024 já previa `esus-export.test.ts`.

**Alternatives considered**:
- Apenas testes manuais — rejeitado: TDD obrigatório.
