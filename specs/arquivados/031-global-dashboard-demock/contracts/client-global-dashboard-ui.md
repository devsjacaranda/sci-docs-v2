# Client UI Contract: Global Dashboard Home

**Feature**: 031-global-dashboard-demock  
**Route**: `/global/dashboard`  
**Component**: `GlobalWelcomeDashboard` (mover para `modules/global/components/`)

## Data flow

```text
ScreenPage (shell)
  └── GlobalWelcomeDashboard
        ├── useAuth()              → perfil (nome, cargo, avatar, badges)
        ├── useTenantBranding()    → identidade institucional (já real)
        ├── useGlobalDashboard()   → GET /global/dashboard
        ├── useLicenseFilter()     → filtra barras do gráfico client-side
        ├── useRecentAccess()      → "Continuar no módulo" (já real)
        └── welcomeShortcuts       → atalhos estáticos filtrados (já real)
```

## Remoções obrigatórias

| Artefato | Ação |
| --- | --- |
| `loadProfile()` em `GlobalWelcomeDashboard` | Remover import/uso |
| `screens['global-dashboard'].stats` | Remover array `stats` de `screens.ts` |
| `welcomeActivities` em render | Substituir por `activities` do hook |
| Dados inline do `GenericBarChart` | Substituir por `chart.data` da API |
| Pasta `components/mock/` (componente) | Mover para `modules/global/components/` |

## Novos artefatos client

```
ci-client-v2/apps/web/src/modules/global/
├── api/global-dashboard.ts
├── hooks/useGlobalDashboard.ts
├── lib/global-dashboard-mappers.ts
├── lib/__tests__/global-dashboard-mappers.test.ts
├── components/GlobalWelcomeDashboard.tsx
└── components/__tests__/GlobalWelcomeDashboard.test.tsx

ci-client-v2/apps/web/src/modules/shared/components/
└── MockDataBadge.tsx
```

## MockDataBadge

- Props: `className?`
- Render: `<Badge variant="outline">Mock</Badge>` + tooltip
- Usado quando `kpi.source === 'mock'` ou `chart.source === 'mock'`
- Posição: canto superior direito do `CardHeader` / título da seção

## Estados UI

| Estado | Comportamento |
| --- | --- |
| Loading | Skeleton nos KPIs + feed + gráfico; hero/branding imediato |
| Error | Card com mensagem + botão "Tentar novamente" (`refetch`); sem mock fallback |
| Empty KPI real | Valor `0`, trend contextual |
| Empty activity | Mensagem "Nenhuma atividade recente" (sem mock) |
| Empty chart | Gráfico vazio com eixo — não seed fake |

## KPI cards

Substituir loop `kpiStats.map` por `dashboard.kpis.map`:

```tsx
<CardHeader className="flex flex-row items-start justify-between">
  <CardTitle>{kpi.label}</CardTitle>
  {kpi.source === 'mock' && <MockDataBadge />}
</CardHeader>
```

## Atividade recente

- Item clicável quando `navigationPath` presente → `<Link to={path}>`
- Tempo relativo via mapper (`formatRelativeTime`)
- Ícone por `kind` (mapear `notificacao` → `Bell`, etc.)

## Gráfico

- Título dinâmico: `chart.title` da API
- `MockDataBadge` se `chart.source === 'mock'`
- Filtrar `chart.data` por módulos visíveis no `licenseFilter` antes de passar ao `GenericBarChart`
- Renomear prop mental: de "Ocorrências críticas" para título da API

## Testes client (Vitest/RTL)

| ID | Caso |
| --- | --- |
| CT-GD-UI-001 | Hero usa `user.name`/`user.cargo` — não chama `loadProfile` |
| CT-GD-UI-002 | KPI mock exibe `MockDataBadge` |
| CT-GD-UI-003 | KPI real não exibe badge |
| CT-GD-UI-004 | Activity item com path renderiza link |
| CT-GD-UI-005 | Error state sem dados mock |
| CT-GD-UI-006 | Branding tests existentes continuam passando |

## ScreenPage

Atualizar import:

```tsx
import { GlobalWelcomeDashboard } from '@/modules/global/components/GlobalWelcomeDashboard'
```

## index / barrel

Exportar em `modules/global/index.ts` para consumo shell.
