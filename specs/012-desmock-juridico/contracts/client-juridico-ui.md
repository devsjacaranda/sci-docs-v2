# Contract: Client UI — Jurídico

**Feature**: 012-desmock-juridico  
**App**: `ci-client-v2/apps/web`  
**Module**: `apps/web/src/modules/juridico/`

## Rotas (substituem mock `ScreenPage`)

| screenId | Path | Page | Licença |
|----------|------|------|---------|
| `juridico-dashboard` | `/juridico/dashboard` | `JuridicoDashboardPage` | base |
| `juridico-lista` | `/juridico/processos` | `JuridicoProcessosListPage` | base |
| `juridico-novo` | `/juridico/processos/novo` | `JuridicoProcessoWizardPage` | base |
| `juridico-detalhes` | `/juridico/processos/:id` | `JuridicoProcessoDetailPage` | base |
| `juridico-editar` | `/juridico/processos/:id/editar` | `JuridicoProcessoWizardPage` | base |
| `juridico-auditoria` | `/juridico/auditoria` | `JuridicoAuditoriaPage` | jatoba |
| `juridico-insights` | `/juridico/insights` | `JuridicoInsightsPage` | cedro |
| `juridico-maturidade` | `/juridico/maturidade` | `JuridicoMaturidadePage` | carvalho |

## Router (`router.tsx`)

```typescript
const JURIDICO_OVERRIDES: Record<string, ReactNode> = {
  'juridico-dashboard': …,
  'juridico-lista': …,
  // … demais screenIds
}
```

Lazy exports em `modules/juridico/index.ts` (padrão `modules/ouvidoria`).

## JuridicoProcessoWizardPage

Steps shadcn Stepper:

1. **Dados** — seções colapsáveis:
   - Tipo de processo (select)
   - Identificação (assunto, nº judicial/CNJ)
   - Partes (`ProcessoPartesForm` — polos, adicionar parte)
   - Órgão e juízo (`ProcessoOrgaoForm`)
   - Observações, prazo, valor da causa, responsável
2. **Anexos** — `AnexoUploadZone` (presign Wasabi)
3. **Revisão** — copy *"Revise os dados do processo. Caso queira alterar algum campo, retorne ao formulário."*
4. **Confirmação** — exibe `JUR-AAAA-NNNN` + link detalhe

Persistência: PATCH draft entre steps; confirm no final.

## JuridicoProcessosListPage

- DataTable colunas spec FR-014
- Badge vermelho prazo crítico (operacional, não conformidade)
- Filtros tipo/status/prazo
- Zero linhas de `mock-data.ts` (`JUR-2026-0047` fixo)

## JuridicoProcessoDetailPage

- Header: número interno, tipo, status operacional
- Seções: identificação, partes, órgão, observações, anexos
- Timeline `ProcessoTimeline`
- Badge consultivo **Probabilidade de Perda** (última fiscalização) — opcional
- Card **Fiscalização Jatobá deste registro** + *Fiscalizar dados*
- Ações licença mock permanecem desabilitadas ou stub: Pau-Brasil *Gerar parecer*, Cedro *Consultar jurisprudência IA* (fora escopo operacional)

## JuridicoAuditoriaPage

Clone `OuvidoriaAuditoriaPage`:

- Título **Painel de Fiscalização Jurídica**
- Coluna extra **Probabilidade de Perda**
- Stats conformidade 4 valores canônicos
- Trace sheet títulos canônicos + fatores loss probability

## JuridicoInsightsPage / JuridicoMaturidadePage

Espelham ouvidoria; `moduleLicenseConfig.juridico.cedroFocus` = *Jurisprudência e risco processual*.

## JuridicoDashboardPage

- Cards: Processos Abertos, Prazos Críticos, Pareceres (mês), Conformidade Legal
- Nivo bar chart distribuição status
- Remover case `'juridico'` mock de `DashboardCharts.tsx` para esta rota

## Shell integration

- `useModuleAccess('juridico')`
- `license-alerts.ts` paths `/juridico/*` já existem
- Paleta mint-palette; vocabulário [regras-plataforma.md](../../../.cursor/docs/regras-plataforma.md)

## API client

`modules/juridico/api/`:

- `processos.ts`, `dashboard.ts`, `fiscalizacao.ts`, `maturidade.ts`, `insights.ts`
- mappers PT-BR ↔ EN
