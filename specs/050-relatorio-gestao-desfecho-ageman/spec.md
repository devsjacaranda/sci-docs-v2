# Feature Specification: Desfecho da demanda — paridade AGEMAN (Relatório de Gestão)

**Feature Branch**: `050-relatorio-gestao-desfecho-ageman`

**Status**: Draft (gap 1 — orquestração pós-049 mergeada)

**Parente**: [049 Ajustes Relatório Gestão](../049-ajustes-relatorio-gestao-ouvidoria/spec.md) · baseline [042 Relatório Gestão](../042-relatorio-gestao-ouvidoria/spec.md)

**Input**: Planilha `PLANILHAS OUVIDORIA AGEMAN - 2026 - 08 e Consolidado.xlsx` — abas **RESUMO GERAL DEMAND.** e **ACOMPANHAMENTO_MENSAL_DEMAND.** (`new-demanda/extracted-sheets.txt`).

## Problema

O relatório exportado hoje usa vocabulário de **workflow** (`answered`, `closed`, `closed_unresolved`): KPIs "Resolvidas / Encerradas com resolução / Encerradas sem resolução" e série mensal "Respondidas | Arquivadas OK | Arquivadas" (`dashboard.repositories.ts` → `get-relatorio-gestao.use-case.ts`).

A AGEMAN consolida cada demanda em **três desfechos de gestão**:

| Planilha (RESUMO GERAL) | Acumulado ref. (até 08/2026) |
| --- | --- |
| DEMANDAS RESOLVIDAS PELA AGEMAN | 5 177 |
| USUÁRIO OPTOU POR BUSCAR MEIO JURÍDICO | 56 |
| DEMANDAS PENDENTES | 98 |

A aba **ACOMPANHAMENTO_MENSAL** repete as colunas **RESOLVIDA | JURÍDICO | PENDENTE** por mês × concessão.

Sem alinhar desfecho, o relatório não substitui a planilha nem reconcilia com o histórico migrado.

## Objetivo (escopo gap 1)

1. Introduir **desfecho reportável** persistido no encerramento (distinção jurídico vs outras saídas sem resolução).
2. Expor no `GET /ouvidoria/relatorio-gestao` (e exports) blocos equivalentes à planilha:
   - KPIs e série **Demandas e resolutividade** com as três linhas acima.
   - Série mensal **desfecho** no lugar de `demandasFinalizadas` (Respondidas / Arquivadas OK / Arquivadas).
3. Regra de **resolutividade AGEMAN**: `resolvidaPelaAgeman / totalDemandas` (percentual da linha "RESOLVIDAS" na planilha ≈ 5177/5331).

**Fora deste gap (gaps 2–4)**: fórmula detalhada de resolutividade mensal, matriz concessão×mês completa, renomeação de outros blocos — ver [coordination-gaps-2-4.md](./coordination-gaps-2-4.md).

## User Stories

### US1 — Encerrar com desfecho jurídico (P1)

Como operador da Ouvidoria, ao encerrar **sem resolução**, quero indicar se o usuário **optou por meio jurídico**, para que o relatório conte esse caso na coluna JURÍDICO e não apenas em "sem resolução" genérico.

**Aceite**:

1. **Given** encerramento com `houveResolucao: false`, **When** o operador escolhe "Usuário optou por meio jurídico", **Then** a manifestação fica `closed_unresolved` com desfecho persistido `meio_juridico`.
2. **Given** encerramento com `houveResolucao: false`, **When** o operador escolhe outro motivo de encerramento sem resolução, **Then** desfecho `sem_resolucao_outros` (rótulo de produto neutro; no relatório AGEMAN não incrementa a linha jurídico).
3. **Given** encerramento com `houveResolucao: true`, **When** persiste, **Then** status `closed` e desfecho implícito **resolvida pela AGEMAN** (campo nullable ou valor canônico `resolvida_ageman`).

### US2 — Relatório com três desfechos (P1)

Como gestor, quero ver no relatório de gestão os mesmos três totais da planilha RESUMO GERAL, filtrados por ano/mês como hoje.

**Aceite**:

1. KPIs do período incluem `resolvidaPelaAgeman`, `meioJuridico`, `pendente` (e mantêm `total`); deixam de ser o foco primário `respondidas` / `encerradasComResolucao` / `encerradasSemResolucao` na UI do relatório AGEMAN.
2. Série mensal substitui `demandasFinalizadas` por `demandasPorDesfecho`: `{ month, resolvidaPelaAgeman, meioJuridico, pendente }`.
3. Manifestações `answered` contam em **resolvidaPelaAgeman** (planilha não separa "respondida" de "resolvida").

### US3 — Histórico `closed_unresolved` (P2)

Como tenant AGEMAN pós-migração, quero que encerramentos antigos sem desfecho preenchido apareçam de forma previsível no relatório até reclassificação manual.

**Aceite**:

1. **Default de relatório (tenant AGEMAN)**: `closed_unresolved` com `desfechoEncerramento` NULL → contabilizar como **meioJuridico** (paridade com planilha acumulada 56).
2. **Demais tenants**: NULL → **sem_resolucao_outros** (não inflacionar jurídico).
3. Script de backfill opcional (T110) pode setar enum explicitamente a partir de planilha/migração 041.

## Requisitos funcionais

- **FR-101**: Campo persistido `desfechoEncerramento` (enum, nullable) em `Manifestacao`, preenchido no fluxo de encerramento quando `houveResolucao === false`; obrigatório nesse caso.
- **FR-102**: Agregações do relatório MUST usar desfecho + status conforme tabela de mapeamento (plan.md), não apenas `status`.
- **FR-103**: Breaking change controlada no JSON do relatório: substituir shape de `demandasFinalizadas` por `demandasPorDesfecho`; KPIs estendidos ou substituídos — ver contrato.
- **FR-104**: Dashboard operacional (`GET /ouvidoria/dashboard`) pode manter KPIs legados na v1 desta spec; relatório de gestão MUST usar desfecho AGEMAN (decisão: dois consumidores, mesma query base refatorada internamente).
- **FR-105**: Exports PDF/Excel do relatório MUST refletir novos rótulos PT-BR alinhados à planilha.

## Assunções

- Spec **049** mergeada: satisfação, orientações, eventos não são alterados neste gap.
- Status de workflow (`ManifestacaoStatus`) **não** ganha valor novo; jurídico é desfecho de encerramento, não status.
- Gap 3 (matriz concessão×mês) reutilizará o mesmo enum; neste gap entrega-se agregação **global** mensal + KPIs.

## Success Criteria

- **SC-101**: Para tenant AGEMAN e filtro acumulado, `resolvidaPelaAgeman + meioJuridico + pendente === total` de manifestações no escopo do filtro (mesma regra de cohort da planilha: criadas no período para RESUMO GERAL).
- **SC-102**: Acumulado histórico AGEMAN reconcilia jurídico ± tolerância de migração documentada após backfill T110.
- **SC-103**: Encerramento UI impede `houveResolucao: false` sem escolha de desfecho.
