# Client UI Contract — SIGED UX Refactor (037)

**App**: `ci-client-v2/apps/web`  
**Módulo**: `src/modules/siged/`  
**Permissão**: `useModuleAccess('gabinete')` — SIGED não vira módulo separado

## Rotas (React Router)

| Path | Componente | screenId (shell) |
| --- | --- | --- |
| `/siged` | `SigedHomePage` | `siged-home` |
| `/siged/diretorias` | `SigedDiretoriasPage` | `siged-diretorias` |
| `/siged/diretorias/:orgaoId` | `SigedOrgaoDrilldownPage` | `siged-diretorias` |
| `/siged/diretorias/:orgaoId/protocolos` | `SigedProtocolosPage` | `siged-protocolos` |
| `/siged/diretorias/:orgaoId/protocolos/:protocoloId` | `SigedProtocoloDetailPage` | `siged-protocolo-detalhe` |
| `/siged/diretorias/:orgaoId/protocolos/:protocoloId/tramitacoes` | `SigedProtocoloTramitacoesPage` | `siged-protocolo-detalhe` |
| `/siged/auditoria` | `SigedAuditoriaPage` | `siged-auditoria` |
| `/siged/insights` | `SigedInsightsPage` | `siged-insights` |

**Redirect**: `/siged/diretorias/:orgaoId` → protocolos se leaf (sem filhos).

## Navegação shell (`navigation.ts`)

Grupo `siged` (outsideModules):

1. Início → `siged-home`
2. Diretorias → `siged-diretorias`
3. Fiscalização → `siged-auditoria` (licença jatoba)
4. Insights IA → `siged-insights` (licença cedro)

## Layout por tela

### Home (`SigedHomePage`)

Ordem vertical (regras-plataforma §4 adaptado):

1. Badges: Base + condicional Cedro/Jatobá
2. Título + descrição
3. `ListLicenseAlertBar` (se alertas)
4. Grid post-its (`SigedPostItGrid`) — KPIs + insights resumidos
5. CTA primário Mint: **Ver diretorias**
6. Links secundários: Fiscalização, Insights IA

Post-it visual: card com leve rotação, sombra, cor surface Mint; **sem** edição.

### Diretorias topo / Drill-down

- Reutilizar `SigedDiretoriasGrid` refatorado: prop `nodes` = topo ou filhos diretos
- Breadcrumb via `SigedBreadcrumb` + `findDepartamentoWithAncestors`
- Busca escopada ao nível atual
- Drill-down: banner **Ver protocolos desta diretoria** quando `hasOwnProtocolos`

### Protocolos / Detalhe

- Manter componentes existentes
- Adicionar `ListLicenseAlertBar` acima dos KPIs (FR-023)
- Controle Interno sidebar inalterado

### Fiscalização (`SigedAuditoriaPage`)

- Paridade `GabineteAuditoriaPage`: `FiscalizacaoPanel`, `QuestionBankPanel`, `QuestionnaireDialog`, `FiscalizacaoTraceSheet`
- Config copy SIGED: coluna protocolo, intro achados tramitação
- `allowExternalAudience: false`
- Badge **Somente leitura** no header

### Insights (`SigedInsightsPage`)

- Paridade `GabineteInsightsPage`: shared `@/modules/shared/components/cedro`
- `InsightTraceSheet` resolve path → `/siged/diretorias/:orgaoId/protocolos/:id` quando evidência tiver IDs
- Botão **Consultar IA** + confirmação dialog

## API client (`modules/siged/api/`)

| Arquivo | Funções |
| --- | --- |
| `siged.service.ts` | existente + hierarquia |
| `siged-home.service.ts` | `fetchSigedHome()` |
| `fiscalizacao.ts` | panel, run, trace, questions |
| `insights.ts` | list, generate, trace, batches |
| `*-mappers.ts` | DTO → ViewModel post-its, alertas |

## Hooks

- `useSigedHome`
- `useSigedFiscalizacaoPanel` / `useRunSigedFiscalizacao`
- `useSigedInsights` / `useGenerateSigedInsights`
- Refatorar `useSigedDepartamentos` — expor árvore + helpers drill-down

## Utils (`departamentos-tree.ts`)

Novos exports:

- `listTopLevelOrgaos(departamentos)`
- `getDirectChildren(departamentos, orgaoId)`
- `isLeafOrgao(node)`
- Manter `findDepartamentoWithAncestors` (já existe)

## Constantes (`siged-routes.ts`)

Adicionar: `diretorias`, `orgao(orgaoId)`, `auditoria`, `insights`.

## Testes client (Vitest)

| Arquivo | Cobertura |
| --- | --- |
| `departamentos-tree.test.ts` | topo, filhos, leaf redirect |
| `navigation.siged.test.ts` | 4 itens nav + licenças |
| `siged-home-mappers.test.ts` | post-its, empty, degraded |
| `SigedHomePage.test.tsx` | render, CTA, alert bar |
| `SigedOrgaoDrilldownPage.test.tsx` | breadcrumb, ver protocolos |

MSW handlers para novos endpoints em `modules/siged/__tests__/handlers.ts`.

## Copy obrigatória

- **Somente leitura** (Cedro/Jatobá panels)
- **Consultar IA** (não "Gerar insights")
- **Fiscalização** / **Insights IA**
- Sheets: títulos §1.7 regras-plataforma
