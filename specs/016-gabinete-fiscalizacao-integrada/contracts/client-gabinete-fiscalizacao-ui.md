# Contract: Client UI — Gabinete Fiscalização Jatobá

**Feature**: 016-gabinete-fiscalizacao-integrada  
**Route**: `/gabinete/auditoria`  
**Screen ID**: `gabinete-auditoria`  
**Licença**: Jatobá — badge **Somente leitura**

Substitui esqueleto atual de `GabineteAuditoriaPage` por paridade com [008 client-ouvidoria-fiscalizacao-ui.md](../008-ouvidoria-jatoba-fiscalizacao/contracts/client-ouvidoria-fiscalizacao-ui.md).

## Navegação

| Origem | Destino | Cliques (SC-001) |
|--------|---------|------------------|
| `/gabinete` overview | Card *Fiscalização* | 1 |
| Shell nav | *Fiscalização* | 1–2 |

**Sem** rota pública de questionário no Gabinete.

---

## Layout da página (`GabineteAuditoriaPage`)

Reutiliza componentes de `modules/ouvidoria/components/` com config Gabinete:

| Prop / config | Valor Gabinete |
|---------------|----------------|
| Título | **Fiscalização de Gestão — Gabinete** |
| Subtítulo | Licença Jatobá: fiscalização operacional sobre atos e cadastros do Gabinete (somente leitura). |
| Badge | **Somente leitura** |
| Botão run | **Fiscalizar atos** |
| Botão questionário | **Novo questionário** (somente interno) |
| Coluna entidade | **Ato** (valor: protocolo do ato ou label órfão) |

### Banner Jatobá

Card mint border — *A Jatobá sinaliza achados — não altera o registro fiscalizado.*

### Stats row

Conformes / Não conformes / Parciais / Pendentes — `conformityStatusClass()` de `@/modules/shell/lib/jatoba`.

### Seções

- Checagem automática de dados (`checksSummary`)
- Problemas e inconformidades (`findings`) — inclui órfãos com `entityTypeLabel`
- Banco de perguntas Gabinete (`QuestionBankPanel` — filtro domínio gabinete)
- Histórico (`FiscalizacaoHistoryTable`) — colunas: **Ato**, Dados fiscalizados, Questionário, Destinatário, Canal, Conformidade, Problemas

### Toolbar actions

| Label | API |
|-------|-----|
| **Fiscalizar atos** | `POST /gabinete/fiscalizacao/run` |
| **Novo questionário** | dialog → `POST /gabinete/fiscalizacao/questionnaires` |

Throttle 429 → toast com mensagem clara (SC-006).

---

## Trace sheets (`FiscalizacaoTraceSheet`)

Títulos canônicos [regras-plataforma §3](../../../.cursor/docs/regras-plataforma.md):

| Contexto | Título |
|----------|--------|
| Checagem | **Por que esta checagem deu este resultado** |
| Achado | **O que gerou este achado** |
| Registro | **O que verificamos neste registro** |
| Pergunta | **Por que esta pergunta foi enviada** |

Sheet ~85% viewport — **sem** rota dedicada.

---

## Card detalhe do ato (`/gabinete/atos/:id`)

Componente: `GabineteFiscalizacaoRecordCard`

| Elemento | Conteúdo |
|----------|----------|
| Título card | **Fiscalização Jatobá deste registro** |
| Checagens | última execução scoped ao ato + vínculos |
| Ação | **Fiscalizar dados** → `POST /gabinete/fiscalizacao/run/atos/:cabinetId` |
| Link | **Abrir tela** → `/gabinete/auditoria` |
| Estado vazio | *Nenhuma fiscalização registrada — fiscalize este ato* |

Badge **Somente leitura** no card.

---

## API client (`modules/gabinete/api/fiscalizacao.ts`)

Paridade com `modules/ouvidoria/api/fiscalizacao.ts`:

- `fetchGabineteFiscalizacaoPanel()`
- `fetchGabineteFiscalizacaoRunDetail(runId)`
- `runGabineteFiscalizacao()`
- `runGabineteFiscalizacaoScoped(cabinetId)`
- `fetchGabineteFiscalizacaoRecord(cabinetId)`
- `fetchCheckTrace(checkId)` / `fetchFindingTrace(findingId)`
- CRUD questions + questionnaires + submit respostas

Mappers em `fiscalizacao-mappers.ts` — labels PT-BR, `entityTypeLabel` para órfãos.

---

## MSW

Handlers em `src/test/msw/handlers/gabinete-fiscalizacao.ts` — fixtures:

- `modules/gabinete/fixtures/fiscalizacao-panel-completed.json`
- `modules/gabinete/fixtures/fiscalizacao-panel-empty.json`
- `modules/gabinete/fixtures/fiscalizacao-run-completed.json`

---

## Paleta e acessibilidade

[mint-palette.mdc](../../../.cursor/rules/mint-palette.mdc) — CTAs `#0F766E` light / `#2DD4BF` dark.

---

## Testes client (ver test-strategy)

- `GabineteAuditoriaPage.integration.test.tsx` — painel + MSW
- `GabineteAuditoriaPage.e2e.test.tsx` — jornada fiscalizar → trace → questionário interno
- Reuso/adaptação de testes `FiscalizacaoPanel.test.tsx` com props Gabinete
