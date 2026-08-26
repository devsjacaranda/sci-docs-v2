# Data Model: Desmock do Dashboard Global

**Feature**: 031-global-dashboard-demock  
**Date**: 2026-07-02

## Overview

Feature **não adiciona tabelas Prisma**. Introduz DTO de agregação read-only (`GlobalDashboardResponse`) composto a partir de entidades existentes. Sem migrations.

## Entidades existentes (fontes)

### TramitacaoDemanda

Usada para KPIs `pendingDemands`, `overduePendingDemands` e agregação `bySourceModule`.

| Campo relevante | Uso |
| --- | --- |
| `status` | `open`, `in_progress` → pendente |
| `deadline` | `< now` + pendente → atrasada |
| `sourceModule` | Gráfico por módulo de origem (linked) |
| `originType` | Excluir personal ativo do dashboard |
| `createdAt` | Janela de período |
| `deletedAt` | Soft delete — excluir |

### TramitacaoDemandaEvento

Usada para KPI `updatesLast24h` e feed `recentActivity`.

| Campo relevante | Uso |
| --- | --- |
| `type` | `created`, `reply`, `forwarded`, … |
| `demandaId` | Link para navegação |
| `createdAt` | Ordenação feed + filtro 24h |
| `payload` | Contexto opcional no título |

### Manifestacao (Ouvidoria)

Usada para KPI `priorityOccurrences`.

| Campo relevante | Uso |
| --- | --- |
| `priority` | `high`, `urgent` |
| `status` | Excluir `closed`, `draft` |
| `deletedAt` | Soft delete |

### Notificacao

Complemento opcional do feed (spec 029 — API existente).

| Campo relevante | Uso |
| --- | --- |
| `userId` | Destinatário |
| `title`, `body` | Exibição |
| `sourceModule`, `sourceRecordId` | Navegação |
| `createdAt` | Ordenação |

### TenantBranding

Já consumido client-side — **fora** do DTO global dashboard (permanece `useTenantBranding`).

## DTO: GlobalDashboardResponse (API)

```typescript
type GlobalDashboardKpi = {
  id: 'priority_occurrences' | 'pending_demands' | 'updates_24h' | 'active_records_cross'
  label: string
  value: number | string
  trend?: string | null
  source: 'real' | 'mock'
}

type GlobalDashboardActivityItem = {
  id: string
  title: string
  moduleLabel: string
  kind: 'tramitacao' | 'alerta' | 'doc' | 'permissao' | 'notificacao'
  createdAt: string // ISO
  navigationPath?: string | null
  source: 'real' | 'mock'
}

type GlobalDashboardModuleBar = {
  module: string
  label: string
  count: number
}

type GlobalDashboardChart = {
  id: 'linked_demands_by_module'
  title: string
  source: 'real' | 'mock'
  periodStart: string
  periodEnd: string
  data: GlobalDashboardModuleBar[]
}

type GlobalDashboardResponse = {
  periodDays: number
  periodStart: string
  periodEnd: string
  kpis: GlobalDashboardKpi[]
  recentActivity: GlobalDashboardActivityItem[]
  chart: GlobalDashboardChart
  meta: {
    includesOuvidoria: boolean
    generatedAt: string
  }
}
```

## ViewModel client (pós-mapper)

```typescript
type GlobalDashboardView = {
  kpis: Array<GlobalDashboardKpi & { isMock: boolean }>
  activities: Array<GlobalDashboardActivityItem & { timeLabel: string; href?: string }>
  chart: GlobalDashboardChart & { isMock: boolean }
  loading: boolean
  error?: string
}
```

## Regras de validação

| Regra | Detalhe |
| --- | --- |
| `periodDays` | Query 1–90, default 30 |
| KPI mock | `source === 'mock'` → client DEVE renderizar `MockDataBadge` no cartão |
| Chart mock | Idem no header do gráfico |
| Activity mock | Lista vazia + nenhum item mock silencioso — se API falhar, erro explícito |
| Permissão ouvidoria | Se actor sem módulo, KPI `priority_occurrences` conta apenas demandas atrasadas (ou retorna 0 com `includesOuvidoria: false`) |
| Tenant | Todas queries via Prisma tenant extension — nunca `tenantId` manual |

## Inventário final esperado (pós-implementação)

| Bloco UI | Classificação |
| --- | --- |
| Branding institucional | Real (client `/tenant/branding`) |
| Hero perfil | Real (`/auth/me` via AuthContext) |
| KPI Ocorrências prioritárias | Real |
| KPI Demandas pendentes | Real |
| KPI Atualizações 24h | Real |
| KPI Registros ativos | **Mock rotulado** |
| Atalhos | Real (config + permissões) |
| Continuar no módulo | Real (RecentAccessContext) |
| Atividade recente | Real (eventos + notificações) |
| Gráfico linked por módulo | Real (tramitação) |
