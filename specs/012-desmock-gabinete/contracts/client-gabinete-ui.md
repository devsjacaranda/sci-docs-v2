# Contract: Client UI — Gabinete

**Feature**: 012-desmock-gabinete  
**App**: `ci-client-v2/apps/web`  
**Module**: `apps/web/src/modules/gabinete/`

## Rotas (substituem mock `/gabinete/atos/*`)

| Path | Page | Licença |
|------|------|---------|
| `/gabinete/dashboard` | `GabineteDashboardPage` | base |
| `/gabinete/demandas` | `GabineteDemandasListPage` | base |
| `/gabinete/demandas/novo` | `GabineteDemandaCreatePage` | base |
| `/gabinete/demandas/:id` | `GabineteDemandaDetailPage` | base |
| `/gabinete/demandas/:id/editar` | `GabineteDemandaEditPage` | base |
| `/gabinete/auditoria` | `GabineteAuditoriaPage` | jatoba |
| `/gabinete/maturidade` | `GabineteMaturidadePage` | carvalho |
| `/gabinete/insights` | `GabineteInsightsPage` | cedro |

Redirects: `/gabinete/atos` → `/gabinete/demandas`; `/gabinete/atos/*` → equivalente `demandas/*`.

## Navegação (`navigation.ts`)

- Label lista: **Demandas** (não "Atos")
- Label create: **Nova demanda**
- `licenseNav('gabinete')` → Maturidade + Insights IA (inalterado)

## GabineteDemandaCreatePage

Seções:

1. **Dados da demanda** — assunto*, descrição*, origem, setor
2. **Protocolo (opcional)** — campos v1 colapsáveis
3. **Anexos** — `AnexoUploadZone` reutilizado de shared ou ouvidoria
4. **Revisão** — resumo + confirmar

Copy: vocabulário *Demanda*; tooltip *ata* opcional em help text.

## GabineteDemandaDetailPage

- Header: protocolNumber, status badge operacional, ações **Tramitar**, **Editar**
- Tabs: **Resumo** | **Protocolo** | **Controle numérico** | **Notificações e autos** | **Documentos tramitados** | **Anexos** | **Linha do tempo**
- Tramitar dialog: Select setor + observação; banner: *Tramitação inter-setorial completa em breve*
- Card Jatobá contextual (link fiscalização) — read-only

## GabineteAuditoriaPage

Clone estrutural de `OuvidoriaAuditoriaPage`:

- `FiscalizacaoPanel`, stats, history, trace sheet
- Título: **Painel de Fiscalização — Gabinete**
- Badge **Somente leitura**
- MSW fixtures: `fixtures/fiscalizacao-panel-empty.json`

## GabineteMaturidadePage / GabineteInsightsPage

Espelham ouvidoria; textos Carvalho/Cedro adaptados (`moduleLicenseConfig.gabinete`).

## Dashboard

- Cards KPI from `GET /gabinete/dashboard`
- Gráfico Nivo status distribution
- Remover `customDashboard: 'gabinete'` mock em `DashboardCharts.tsx` para rota real

## Shell integration

- `ScreenPage.tsx`: rotas `gabinete-*` delegam a pages reais (padrão ouvidoria)
- `useModuleAccess('gabinete')`
- Paleta mint-palette; shadcn DataTable, Sheet trace

## Listas operacionais (cadastros + atos)

Conforme [regras-plataforma §4.1–§4.2](../../../.cursor/docs/regras-plataforma.md):

| Elemento | Componente |
|----------|------------|
| Breadcrumb | `GabineteCadastroLayout` + `screenId` |
| Cabeçalho + criar | `GabineteListPageHeader` |
| Estatísticas | `GabineteStatGrid` + `lib/gabinete-list-stats.ts` |
| Filtros | `GabineteFiltersCard` |
| Tabela | `GabineteTableCard` |
| Paginação | `GabinetePagination` |
| Ações por linha | `TableRowActionsMenu` (shared) — menu ⋮, **NUNCA** botões inline |

Menu típico cadastro: **Ver detalhes** · **Vincular a ato** (sem vínculo). Menu atos: **Ver detalhes** · **Tramitar**.

## API client

`modules/gabinete/api/`:

- `demandas.ts`, `protocolos.ts`, `controles.ts`, `dashboard.ts`
- `fiscalizacao.ts`, `maturidade.ts`, `insights.ts`
- mappers PT-BR ↔ EN
