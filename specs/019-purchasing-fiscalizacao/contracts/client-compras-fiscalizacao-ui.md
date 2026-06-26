# Contract: Client UI — Compras Fiscalização Jatobá

**Feature**: 019-purchasing-fiscalizacao  
**Route**: `/compras/fiscalizacao`  
**Screen ID**: `compras-fiscalizacao` (migrar de `compras-auditoria`)  
**Licença**: Jatobá — badge **Somente leitura**

Substitui esqueleto mock de `compras-auditoria` por paridade estrutural com [008 client-ouvidoria-fiscalizacao-ui.md](../arquivados/008-ouvidoria-jatoba-fiscalizacao/contracts/client-ouvidoria-fiscalizacao-ui.md), **sem** questionários.

## Navegação

| Origem | Destino | Cliques (SC-001) |
|--------|---------|------------------|
| `/compras` overview | Card *Fiscalização* | 1 |
| Shell nav Compras → *Fiscalização* | `/compras/fiscalizacao` | 1–2 |

**Redirect**: `/compras/auditoria` → `/compras/fiscalizacao` (compatibilidade).

---

## Layout da página (`ComprasFiscalizacaoPage`)

Reutiliza componentes de `modules/ouvidoria/components/` com config Compras:

| Prop / config | Valor Compras |
|---------------|---------------|
| Título | **Fiscalização de Compras** |
| Subtítulo | Licença Jatobá: checagens automáticas sobre demandas e artefatos documentais (somente leitura). |
| Badge | **Somente leitura** |
| Botão run | **Fiscalizar demandas** |
| Coluna entidade | **Demanda** (valor: `DEM-{n}`) |

**Não exibir**: `QuestionBankPanel`, `QuestionnaireDialog`, botão *Novo questionário*.

### Banner Jatobá

Card mint border — *A Jatobá sinaliza achados — não altera demandas nem artefatos.*

### Stats row

Conformes / Não conformes / Parciais / Pendentes — `conformityStatusClass()` de `@/modules/shell/lib/jatoba`.

**Nunca** exibir *Aguardando resposta*, *Crítico* ou *Vencendo* como status de conformidade.

### Seções

- Checagem automática de dados (`checksSummary`)
- Problemas e inconformidades (`findings`)
- Histórico (`FiscalizacaoHistoryTable`) — colunas: **Demanda**, **PCA**, **Artefatos fiscalizados**, **Conformidade**, **Problemas**

### Toolbar actions

| Label | API |
|-------|-----|
| **Fiscalizar demandas** | `POST /compras/fiscalizacao/run` |

Throttle 429 → toast com mensagem clara (SC-006).

### Estado vazio

- `never_run`: CTA *Fiscalizar demandas*
- `no_data`: *Registre demandas para habilitar fiscalização* — sem achados fabricados

---

## Trace sheets (`FiscalizacaoTraceSheet`)

Títulos canônicos [regras-plataforma §3](../../../.cursor/docs/regras-plataforma.md):

| Contexto | Título |
|----------|--------|
| Checagem | **Por que esta checagem deu este resultado** |
| Achado | **O que gerou este achado** |
| Demanda | **O que verificamos nesta demanda** |

Sheet ~85% viewport — **sem** rota dedicada.

Badge **Somente leitura** visível no sheet — **nunca** *Read-only*.

---

## Card hub da demanda (`/compras/:demandaId`)

Componente: `ComprasFiscalizacaoRecordCard` em `DemandaHubPage`.

| Elemento | Conteúdo |
|----------|----------|
| Título card | **Fiscalização Jatobá desta demanda** |
| Checagens | última execução para demanda |
| Ação | **Fiscalizar demanda** → `POST /compras/fiscalizacao/run/demandas/:demandaId` |
| Link | **Abrir tela** → `/compras/fiscalizacao` |
| Estado vazio | *Nenhuma fiscalização registrada — fiscalize esta demanda* |
| Sem licença Jatobá | card oculto ou CTA licença — sem dados conformidade |

Badge **Somente leitura** no card.

---

## API client (`modules/compras/api/fiscalizacao.ts`)

Paridade com `modules/gabinete/api/fiscalizacao.ts`:

- `fetchComprasFiscalizacaoPanel()`
- `fetchComprasFiscalizacaoRunDetail(runId)`
- `runComprasFiscalizacao()`
- `runComprasFiscalizacaoScoped(demandaId)`
- `fetchComprasFiscalizacaoRecord(demandaId)`
- `fetchCheckTrace(checkId)` / `fetchFindingTrace(findingId)` / `fetchDemandaTrace(demandaId)`

---

## Mappers (`fiscalizacao-mappers.ts`)

- `conformityLabel(status)` → PT-BR 4 status
- `originLabel(origin)` → Agendada | Sob demanda | Por registro | Ao abrir painel
- `formatDemandaProtocol(number)` → `DEM-{number}`
- `emptyReasonMessage(reason)` → copy orientador
- `artefactsSummaryLabel(satisfied, total)` → `"3/7 preenchidos"`

---

## Shell config updates

| Arquivo | Alteração |
|---------|-----------|
| `screens.ts` | `compras-fiscalizacao` path `/compras/fiscalizacao`; title *Fiscalização de Compras*; remover colunas questionário |
| `navigation.ts` | screenId `compras-fiscalizacao` |
| `router.tsx` | lazy `ComprasFiscalizacaoPage`; redirect `/compras/auditoria` |
| `mock-data.ts` | remover mock `compras-auditoria` após MSW real |

---

## MSW

`apps/web/src/mocks/handlers/compras-fiscalizacao.ts` — panel, run, trace, scoped.

Registrado em `setupTests` junto handlers compras CRUD.

---

## Acessibilidade e paleta

Seguir `mint-palette.mdc`: CTA Jatobá escuro `#0F766E` (light) / mint `#2DD4BF` texto escuro em botões dark.
