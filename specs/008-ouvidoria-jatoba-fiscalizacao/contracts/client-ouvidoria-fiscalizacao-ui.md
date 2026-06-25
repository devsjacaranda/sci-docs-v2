# Contract: Client UI — Ouvidoria Fiscalização Jatobá

**Feature**: 008-ouvidoria-jatoba-fiscalizacao  
**Route**: `/ouvidoria/auditoria`  
**Screen ID**: `ouvidoria-auditoria`  
**Licença**: Jatobá — badge **Somente leitura**

## Navegação

| Origem | Destino | Cliques (SC-001) |
|--------|---------|------------------|
| `/ouvidoria` overview | Card *Fiscalização* | 1 |
| Shell nav | *Fiscalização* | 1–2 |

Registrar lazy route em `app/router.tsx` — **substituir** render mock `ScreenPage` + `JatobaFiscalPanel` para este screenId.

Rota pública adicional: `/public/ouvidoria/fiscalizacao/responder/:token` (formulário externo, fora do AppShell autenticado).

---

## Layout da página (`OuvidoriaAuditoriaPage`)

### Header

| Elemento | Conteúdo |
|----------|----------|
| Título | Painel de Fiscalização — Ouvidoria |
| Subtítulo | Licença Jatobá: fiscalização operacional de dados (somente leitura) — checagens automáticas, achados e questionários sobre manifestações confirmadas. |
| Badge | **Somente leitura** |

Copy intro opcional de [`jatoba-ouvidoria-copy.ts`](../../../ci-client-v2/src/lib/jatoba-ouvidoria-copy.ts).

### Banner Jatobá

Card emerald border — descrição Jatobá + *A Jatobá sinaliza achados — não altera o registro fiscalizado.*

### Stats row

| Label | Fonte |
|-------|-------|
| Conformes | `run.stats.conforme` |
| Não conformes | `run.stats.nonConforme` |
| Parciais | `run.stats.partial` |
| Pendentes | `run.stats.pending` |

Usar `conformityStatusClass()` de `@/modules/shell/lib/jatoba` — **apenas** 4 status canônicos.

### Seção — Checagem automática de dados

Grid 2 colunas (lg): lista de `checksSummary` com badge conformidade + link rastreio.

### Seção — Problemas e inconformidades

Lista `findings` com badges conformidade + fluxo questionário (se aplicável) — fluxo **não** como badge de conformidade.

### Seção — Banco de perguntas

Lista perguntas ativas + botão *Gerenciar banco de perguntas* → sheet/dialog `QuestionBankPanel`.

### Tabela — Histórico de fiscalizações e questionários

Colunas (espelho `screens.ts`):

| Coluna | Campo |
|--------|-------|
| Manifestação | `protocol` |
| Dados fiscalizados | `fiscalizedData` |
| Questionário | `questionnaireTitle` |
| Destinatário | `recipientLabel` |
| Canal | `channelLabel` |
| Conformidade | badge `conformityLabel` |
| Problemas | `problems` |

Linha clicável → rastreio registro ou detalhe manifestação quando `manifestacaoId` presente.

### Toolbar actions

| Label | Comportamento |
|-------|---------------|
| **Fiscalizar manifestações** | `POST /ouvidoria/fiscalizacao/run`; loading; toast sucesso ou throttle 429 |
| **Novo questionário** | Abre `QuestionnaireDialog` — destinatário interno sempre; externo **omitido** se `canExternal === false` |

### Histórico de execuções

`FiscalizacaoRunsHistoryPanel`: lista `GET /ouvidoria/fiscalizacao/runs`; clique compara execuções (mín. 2 anteriores quando ≥ 3 existem — SC-009).

### Estado vazio

| `emptyReason` | Mensagem |
|---------------|----------|
| `no_data` | Registre e confirme manifestações para habilitar fiscalização. |
| `never_run` | Acione *Fiscalizar manifestações* para a primeira análise. |

---

## Sheet de rastreio (`FiscalizacaoTraceSheet`)

- Abertura: ~85% viewport height
- Títulos por `traceType`:

| traceType | Título |
|-----------|--------|
| `check` | Por que esta checagem deu este resultado |
| `finding` | O que gerou este achado |
| `question` | Por que esta pergunta foi enviada |
| `record` | O que verificamos neste registro |

Conteúdo: `GET .../trace` correspondente. Link **Ver registro** → `/ouvidoria/manifestacoes/:id` quando permitido.

---

## Card detalhe manifestação (`FiscalizacaoRecordCard`)

Inserir em `ManifestacaoDetailPage` abaixo da timeline (manifestações confirmadas apenas).

| Elemento | Comportamento |
|----------|---------------|
| Título | Fiscalização Jatobá deste registro |
| Checagens | Lista da última execução |
| Link | **Abrir tela** → `/ouvidoria/auditoria` |
| Ação | *Fiscalizar dados* → `POST .../run/manifestacoes/:id` |
| Rastreio | *O que verificamos neste registro* |

---

## QuestionnaireDialog

- Seleção manifestação (pré-preenchida se aberto do detalhe)
- Perguntas do banco (multi-select) ou ad hoc
- Destinatário: Interno | Externo (condicional)
- Canal externo: WhatsApp | E-mail
- Após criar externo: exibir `responseLink` copiável + aviso *Repasse o link ao manifestante — envio automático não disponível nesta versão.*

---

## QuestionnairePublicRespondPage

Rota pública minimal — lista perguntas + submit. Sem sidebar. Mensagens token inválido/expirado.

---

## Paleta e componentes

- shadcn Card, Badge, Sheet, Button, Table
- Paleta Mint (`mint-palette.mdc`)
- Ícones: `ShieldAlert`, `ClipboardCheck`, `MessageSquare`, `Users` (espelho mock)

---

## Guards client

- `useModuleAccess('ouvidoria')` → 403
- Licença Jatobá via filtro existente (`licenses: ['jatoba']` em screens.ts)

---

## Remoções

- `ScreenPage` + `JatobaFiscalPanel` para `ouvidoria-auditoria`
- Dados de `mock-data.ts` `ouvidoria-auditoria`, `jatobaProblems.ouvidoria`, `jatobaDataChecks['ouvidoria-record']` permanecem para outros módulos mock até migração global
