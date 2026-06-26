# Contract: Client UI — Módulo IT

**Feature**: 022-it-seguranca-informacao  
**App**: `ci-client-v2/apps/web`  
**Module path**: `apps/web/src/modules/it/`

## Rotas

| Screen ID | Path | Page | Licença |
|-----------|------|------|---------|
| `it-dashboard` | `/it` | `ItDashboardPage` | Base |
| `it-ativos` | `/it/ativos` | `ItAtivosListPage` | Base |
| `it-ativo-novo` | `/it/ativos/novo` | `ItAtivoFormPage` | Base |
| `it-ativo-detalhe` | `/it/ativos/:id` | `ItAtivoDetailPage` | Base |
| `it-incidentes` | `/it/incidentes` | `ItIncidentesListPage` | Base |
| `it-incidente-novo` | `/it/incidentes/novo` | `ItIncidenteFormPage` | Base |
| `it-operadores` | `/it/operadores` | `ItOperadoresPage` | Base |
| `it-insights` | `/it/insights` | `ItInsightsPage` | Cedro |
| `it-fiscalizacao` | `/it/fiscalizacao` | `ItFiscalizacaoPage` | Jatobá |
| `it-maturidade` | `/it/maturidade` | `ItMaturidadePage` | Carvalho |

Registro: `IT_OVERRIDES` em `modules/it/index.ts` + `router.tsx`.

## Navegação (`navigation.ts`)

```text
Segurança da Informação
├── Dashboard          /it
├── Ativos de TI       /it/ativos
├── Incidentes         /it/incidentes
├── Operadores LGPD    /it/operadores
├── Maturidade         /it/maturidade      (Carvalho)
├── Insights IA        /it/insights        (Cedro)
└── Fiscalização       /it/fiscalizacao    (Jatobá)
```

## Layout lista operacional (§4 regras-plataforma)

Ordem obrigatória em `ItAtivosListPage`, `ItIncidentesListPage`:

1. Breadcrumb
2. Cabeçalho (H1, descrição, CTA criar Mint)
3. Barra alertas licença (`ListLicenseAlertBar`) — se pendência
4. Cards estatística (grid 4 colunas)
5. Filtros (card dedicado)
6. Tabela + menu ⋮ (`TableRowActionsMenu`)
7. Paginação

## Componentes principais

| Componente | Responsabilidade |
|------------|------------------|
| `ItDashboardCards` | Volumetria, incidentes abertos, % LGPD |
| `ItAssetLinksPanel` | Vínculos entre ativos |
| `ItLgpdMappingForm` | Operador → categorias |
| `ItConfigUploadPanel` | Presign + analyze Cedro |
| `ItLgpdInsightCard` | Insight + botão *Aplicar classificação* |
| `ItRiskMatrixForm` | Checklist condicional + nota instantânea |
| `ItBackupEvidenceForm` | Formulário Jatobá backup |
| `ItAuditTrailTable` | Trilha imutável read-only |
| `ItAnpdGenerateButton` | Preview + PDF (só critical) |
| `ItDefenseLinesChart` | Nivo Pie |
| `ItVulnerabilityRanking` | Nivo Bar + drill-down |
| `ItFrameworkControlsList` | Toggle status controles |

## Reuso cross-module

| De | Uso |
|----|-----|
| `modules/ouvidoria/components/FiscalizacaoPanel` | Base layout fiscalização |
| `modules/shared/components/TraceabilitySheet` | Rastreabilidade |
| `modules/shared/components/TableRowActionsMenu` | Coluna ações |
| `modules/permissao/hooks/useModuleAccess` | Guard client |
| `lib/license-alerts.ts` | `MODULE_PATHS.it = '/it'` |

## Copy UI obrigatório

| Contexto | Texto |
|----------|-------|
| Badge Cedro/Jatobá/Carvalho | **Somente leitura** |
| Insight Cedro sheet | **De onde veio este insight** |
| Maturidade sheet | **Como calculamos este score?** |
| Checagem Jatobá | **Por que esta checagem deu este resultado** |
| CTA classificação | **Aplicar classificação** |
| ANPD | **Gerar notificação ANPD** |

## Licença indisponível

- Sem Cedro: `/it/insights` → alerta licença; **ocultar** painéis insight no detalhe ativo
- Sem Jatobá: `/it/fiscalizacao` → alerta; ocultar card backup no servidor
- Sem Carvalho: `/it/maturidade` → alerta
- Sem módulo IT: `AccessDenied403`

## `moduleLicenseConfig.it` (packages/domain)

```typescript
it: {
  cedro: { focus: 'LGPD, configurações e matriz de risco' },
  jatoba: { focus: 'Backup, trilha de auditoria, ANPD' },
  carvalho: { focus: 'Linhas de defesa, CIS/LGPD, vulnerabilidade' },
}
```

## MSW handlers

`apps/web/src/test/msw/handlers/it.ts` — espelhar contratos REST para testes.

## Paleta

Mint palette (rule `mint-palette`): CTA `#0F766E` / `#2DD4BF`; alertas destructive/amber.
