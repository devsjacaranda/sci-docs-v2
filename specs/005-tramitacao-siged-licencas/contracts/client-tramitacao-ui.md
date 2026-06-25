# Contract: Client UI — Tramitação Demandas SIGED

**Feature**: 005-tramitacao-siged-licencas  
**App**: `ci-client-v2/apps/web`  
**References**: [data-model.md](../data-model.md) · [regras-plataforma.md](../../../.cursor/docs/regras-plataforma.md) · mint-palette · [traceability-mock.md](../../../.cursor/docs/traceability-mock.md)

## Rotas

| screenId | Path | Type | Licenças | Componente |
|----------|------|------|----------|------------|
| `tramitacao-dashboard` | `/tramitacao/dashboard` | `dashboard` | `base` | `DashboardCharts` custom `tramitacao` |
| `tramitacao-demandas` | `/tramitacao/demandas` | `inbox` | `base`, `pau-brasil` | `TramitacaoInboxPanel` |
| `tramitacao-maturidade` | `/tramitacao/maturidade` | `maturity` | `carvalho` | `ScreenPage` + maturity layout |
| `tramitacao-insights` | `/tramitacao/insights` | `insights` | `cedro` | `ScreenPage` + insights list |
| `tramitacao-auditoria` | `/tramitacao/auditoria` | `panel` | `jatoba` | `MockDataTable` |

Geradas por `buildLicenseScreens()` + entrada manual auditoria. Lazy load via router existente.

---

## Navegação sidebar (`navigation.ts`)

```text
Tramitação
├── Dashboard de demandas
├── Demandas
├── Maturidade          # licenseNav
├── Insights IA         # licenseNav
└── Fiscalização        # tramitacao-auditoria
```

---

## Inbox — Demandas (FR-001–FR-004)

### Layout

1. **Barra de alertas** (`ListLicenseAlertBar`) — quando `getModuleWorstStatus('tramitacao')` ≠ ok
2. **Toolbar**: pastas Recebidas / Enviadas / Arquivadas; filtro setor; busca; **Compor**
3. **Lista**: cards com avatar setor, assunto, preview, data, badge **SIGED** se `origem === 'siged'`
4. **Detalhe** (split pane): metadados, painel SIGED (se aplicável), históricos, ações

### Badge SIGED

- Variante visual distinta (outline + ícone institucional)
- Tooltip: *SIGED — Prefeitura de Manaus*
- **Nunca** usar como status operacional ou conformidade

### Painel Processo SIGED (detalhe)

| Campo UI | Fonte |
|----------|-------|
| Protocolo SIGED | `processoSiged.protocolo` |
| Tipo | `processoSiged.tipo` |
| Secretaria de origem | `processoSiged.secretariaOrigem` |
| Assunto | `processoSiged.assunto` |
| Status do processo | `processoSiged.statusProcesso` |
| Recebido em | `processoSiged.recebidoEm` |

### Tabela Documentos vinculados

| Coluna | Fonte |
|--------|-------|
| Tipo | `documentosSiged[].tipo` |
| Número | `documentosSiged[].numero` |
| Assinatura | `documentosSiged[].statusAssinatura` |

Estado vazio: *Nenhum documento vinculado neste processo SIGED.*

### Ações operacionais (Base)

| Ação | Comportamento mock |
|------|-------------------|
| **Compor** | Sheet: destinatários, assunto, corpo, prazo opcional, modelos Pau-Brasil |
| **Responder** | Adiciona entrada `kind: resposta` em `conversationHistory` |
| **Encaminhar** | Adiciona `kind: encaminhamento`; atualiza destinatários |
| **Arquivar** | Move para pasta `arquivadas` |

### Ações Pau-Brasil (Compor)

| Botão | Preset |
|-------|--------|
| Usar modelo — Ofício | `getLicenseActionPreset('pau-brasil', ...)` |
| Usar modelo — Memorando | idem |
| Usar modelo — Despacho | idem |

Alerta normativo (card): prazo legal de tramitação — copy normativo, **não** substitui prazo operacional.

### Ações licença no detalhe (P3)

| Contexto | Ação | Painel |
|----------|------|--------|
| Demanda aberta | Fiscalizar dados | `JatobaRecordCheck` module=`tramitacao` |
| Demanda aberta | Consultar IA | `CedroModulePanel` read-only |
| Link | Abrir Maturidade | navega `/tramitacao/maturidade` |

Elementos ocultos se filtro de licença não incluir — **nunca** `disabled` por licença (R-11).

---

## Dashboard (FR-005)

### Cards stats (`screens.ts`)

| Label | Exemplo |
|-------|---------|
| Tramitações (ano) | 24 |
| Pendentes | 3 |
| Em análise | 8 |
| Resolutividade | 78% |
| Origem SIGED | 6 *(novo)* |

### Gráficos (`DashboardCharts`)

- Resolutividade mensal (existente)
- Volume mensal (existente)
- **Novo**: origem SIGED vs Interna por mês (`tramitacaoOrigemPorMes`)

Filtro setor: dropdown reutilizando `tramitacaoSectors`.

---

## Fiscalização — Jatobá (FR-008–FR-010)

Colunas `mockTableRows['tramitacao-auditoria']`:

| Coluna | key |
|--------|-----|
| Demanda | `registro` |
| Dados fiscalizados | `dados` |
| Questionário | `questionario` |
| Destinatário | `destinatario` |
| Canal | `canal` |
| Conformidade | `conformidade` (badge) |
| Problemas | `problemas` |

Ações toolbar: **Fiscalizar demandas**, **Novo questionário interno**.

Sheet: **Por que esta checagem deu este resultado**

---

## Insights IA — Cedro (FR-011–FR-012)

Lista insights com impacto badge; detalhe read-only; sheet **De onde veio este insight**; badge global **Somente leitura**.

Temas mock obrigatórios:

1. Gargalo entre setores (ex.: GAB → DEJUR)
2. Tendência volume SIGED vs interno

---

## Maturidade — Carvalho (FR-013–FR-014)

Stats cards: score híbrido, eixos CI/GOV/TI, contribuição Jatobá.

Sheet: **Como calculamos este score**

Botão: **Exportar relatório PDF** (mock dialog — preset Carvalho)

---

## Barra de alertas (FR-016)

| Situação | Título |
|----------|--------|
| Crítico | **Alertas ativos nas licenças** |
| Só atenção | **Pontos de atenção nas licenças** |
| Tudo ok | *(oculta)* |

Subtítulo fixo: *Atalhos para Fiscalização, Insights IA e Maturidade deste módulo.*

---

## Copy obrigatória

| Contexto | Texto |
|----------|-------|
| Explicação genérica | **Como chegamos aqui?** |
| Maturidade | **Como calculamos este score?** |
| Cedro | **Somente leitura** |
| Módulo label | **Tramitação** (não "Tramitação de documentos") |

---

## Fora de escopo UI

- Rotas `/protocolo/*`
- Integração real SIGED (OAuth, webhook UI)
- Persistência server-side
- Tela pública de consulta
