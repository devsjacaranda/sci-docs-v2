# Test Strategy: Global Dashboard Demock

**Feature**: 031-global-dashboard-demock

## Camadas

| Camada | Framework | Escopo |
| --- | --- | --- |
| Unit API schemas | Jest | Zod parse query + response fixture |
| Unit API use case | Jest | agregações, permissão ouvidoria, KPI mock |
| Unit API mapper | Jest | títulos evento → activity item |
| Unit client mappers | Vitest | API → ViewModel, timeLabel, isMock |
| Component client | Vitest/RTL | MockDataBadge, GlobalWelcomeDashboard estados |
| Integration API | Jest (opcional) | tenant com seed tramitação — se infra disponível |

Sem migration — Prisma mock nos unit tests.

---

## Casos de teste API

### CT-GD-001 — Query default periodDays 30

**Arquivo**: `global-dashboard.schemas.spec.ts`  
**Given** query `{}`  
**Then** `periodDays === 30`

### CT-GD-002 — Query periodDays inválido 400

**Given** `periodDays=0`  
**Then** Zod parse fails

### CT-GD-003 — KPI pending_demands conta pendentes

**Arquivo**: `get-global-dashboard.use-case.spec.ts`  
**Given** repo retorna `pending: 7`  
**Then** kpi `pending_demands.value === 7`, `source: 'real'`

### CT-GD-004 — KPI active_records_cross sempre mock

**Then** kpi `active_records_cross.source === 'mock'`

### CT-GD-005 — priority_occurrences sem ouvidoria

**Given** actor sem módulo ouvidoria  
**Then** conta apenas demandas atrasadas; `meta.includesOuvidoria === false`

### CT-GD-006 — priority_occurrences com ouvidoria

**Given** actor com ouvidoria + manifestações high/urgent  
**Then** soma manifestações + demandas atrasadas

### CT-GD-007 — recentActivity mapeia evento forwarded

**Given** evento type `forwarded` com subject  
**Then** item com `kind: 'tramitacao'`, `navigationPath` preenchido

### CT-GD-008 — chart bySourceModule labels

**Given** módulo `ouvidoria`  
**Then** `label === 'Ouvidoria'`, `source: 'real'`

### CT-GD-009 — Empty tenant

**Given** zero registros  
**Then** KPIs reais com value 0; activity `[]`; chart `data: []`

### CT-GD-010 — Fixture empty parse

**Arquivo**: `fixtures/global-dashboard-empty.json`  
**Then** response schema valida

---

## Casos de teste client

### CT-GD-UI-001 — Perfil sem loadProfile

**Arquivo**: `GlobalWelcomeDashboard.test.tsx`  
**Given** mock `useAuth` com name/cargo  
**Then** exibe valores; `loadProfile` não mockado/chamado

### CT-GD-UI-002 — MockDataBadge em KPI mock

**Given** kpi `source: 'mock'`  
**Then** badge "Mock" visível

### CT-GD-UI-003 — Sem badge em KPI real

**Given** kpi `source: 'real'`  
**Then** badge ausente

### CT-GD-UI-004 — Activity link

**Given** activity com `navigationPath`  
**Then** `<a href="...">` ou Router link presente

### CT-GD-UI-005 — Error não renderiza welcomeActivities

**Given** hook retorna `error`  
**Then** sem itens fictícios da lista antiga

### CT-GD-UI-006 — Mapper timeLabel

**Arquivo**: `global-dashboard-mappers.test.ts`  
**Given** ISO recente  
**Then** string relativa PT-BR ("Há X min")

### CT-GD-UI-007 — Filtro licença no gráfico

**Given** filter `cedro`, chart com ouvidoria + gabinete  
**Then** apenas módulos compatíveis com filtro (ou all)

---

## Ordem TDD sugerida

1. CT-GD-001/002 schemas (RED → GREEN)
2. CT-GD-003..009 use case
3. CT-GD-UI-006 mappers
4. CT-GD-UI-001..005 component
5. CT-GD-010 fixture contract

## Comandos

```powershell
cd ci-api-v2; npm test -- --testPathPatterns=global-dashboard
cd ci-client-v2/apps/web; npm test -- global-dashboard
```
