# Contract: Client UI — Ouvidoria Maturidade Carvalho

**Feature**: 009-ouvidoria-carvalho-maturidade  
**Route**: `/ouvidoria/maturidade`  
**Screen ID**: `ouvidoria-maturidade`  
**Licença**: Carvalho — badge **Somente leitura** (scores/indicadores); planos de ação são escrita gerencial

## Navegação

| Origem | Destino | Cliques (SC-001) |
|--------|---------|------------------|
| `/ouvidoria` overview | Card *Maturidade* | 1 |
| Shell nav | *Maturidade* | 1–2 |

Registrar lazy route em `app/router.tsx` — **substituir** render mock `ScreenPage` + `CarvalhoMaturityPanel` para este screenId.

---

## Layout da página

### Header

| Elemento | Conteúdo |
|----------|----------|
| Título | Maturidade — Ouvidoria |
| Subtítulo | Licença Carvalho: diagnóstico de maturidade institucional — score híbrido, indicadores e planos de ação. |
| Badge | **Somente leitura** (scores e indicadores) |

### Ações primárias

| Label | Comportamento |
|-------|---------------|
| **Responder autoavaliação** | Abre `SelfAssessmentDialog`; `GET/PUT /ouvidoria/maturidade/self-assessment` |
| **Novo plano de ação** | Abre `ActionPlanDialog` (gestor); `POST action-plans` |
| **Como calculamos este score?** | Abre `MaturidadeTraceSheet` (~85% viewport) |

Copy autoavaliação: *Registre a percepção da equipe — alimenta 60% da nota de maturidade.*

---

### Seção score — `MaturidadeScoreCards`

| Elemento | Fonte API |
|----------|-----------|
| Nota geral | `score.overall` + sufixo `%` |
| Chip alerta | `score.overallAlertLabel` (Crítico/Atenção) ou ausente |
| Meta institucional | `score.institutionalTarget` (80%) |
| Badge fonte parcial | `score.partialSource` → *Fonte parcial — fiscalização indisponível* |
| Cards por eixo | `score.axes[]` — barra progresso Mint |
| Por eixo: *Entenda esta nota* | trace filtrado por eixo |

Quando `score.overallAvailable === false`: mensagem *Responda a autoavaliação do período para habilitar o score de maturidade* — **sem** números fabricados.

---

### Seção gráficos

#### `MaturidadeRadarChart` (Nivo Radar)

- 3 eixos: Controle Interno, Governança, TI
- Valores: `score.axes[].score`
- Linha referência meta 80%
- Cores semânticas: crítico/atenção conforme limiares R-52
- Empty: ocultar chart se nenhum eixo disponível

#### `MaturidadeTimelineChart` (Nivo Line)

- Série `overall` + opcional por eixo
- Dados: `history[]`
- 1 ponto: mensagem *Histórico se formará após próximas autoavaliações*
- Eixo X: `periodLabel`

---

### Seção indicadores — `MaturidadeIndicatorsRow`

5 cards canônicos de `indicators[]`:

| type | Label UI |
|------|----------|
| `volume` | Volume de manifestações |
| `avg_response_time` | Tempo médio de resposta |
| `overdue_rate` | Prazos vencidos |
| `resolution_rate` | Taxa de resolução |
| `satisfaction` | Satisfação |

Cada card: valor formatado, `periodLabel`, ação *Como chegamos aqui?* → trace indicador.

Badge `partialSource` em Satisfação quando aplicável.

---

### Banner Jatobá desatualizada

Quando `jatobaReference.isStale === true`:

> A conformidade operacional pode estar desatualizada. [Abrir Fiscalização](/ouvidoria/auditoria)

---

### Seção planos — `ActionPlansPanel`

- Tabela/cards com filtros eixo, status, criticidade
- Destaque prazo vencido (`isOverdue`)
- Detalhe com timeline de `ActionPlanNote`
- Gestor: editar status, adicionar nota

---

## Sheet de rastreio (`MaturidadeTraceSheet`)

- Abertura: ~85% viewport (R-40)
- Título: **Como calculamos este score**
- Conteúdo: `GET /ouvidoria/maturidade/score/trace`
- Seções: intro somente leitura, fórmula 60/40, por eixo autoavaliação + Jatobá
- Detalhe técnico recolhível: `technicalDetail` (R-44)
- **Nunca** rota dedicada `/rastreio/:id`

---

## Dialog autoavaliação (`SelfAssessmentDialog`)

- Accordion ou tabs por eixo (CI, GOV, TI)
- Controles: escala 1–5, Sim/Não, textarea descritiva
- Submit → PUT; toast sucesso; refetch dashboard
- Período encerrado: dialog read-only

---

## Integração alertas licença

`license-alerts.ts`: consumir `score.overallAlert` do dashboard ou endpoint dedicado; chip Carvalho → `/ouvidoria/maturidade`.

| overallAlert | Severidade chip |
|--------------|-----------------|
| `critical` | Crítico |
| `attention` | Atenção |
| null | Ok (sem chip) |

---

## Estados vazios

| emptyReason | Mensagem | CTA |
|-------------|----------|-----|
| `no_self_assessment` | Responda a autoavaliação do período… | Responder autoavaliação |
| `no_data` | Registre manifestações confirmadas… | Ir para manifestações |

---

## Componentes a criar/substituir

| Componente | Substitui |
|------------|-----------|
| `OuvidoriaMaturidadePage` | `ScreenPage` mock |
| `MaturidadePanel` | orquestra seções |
| `MaturidadeScoreCards` | cards do `CarvalhoMaturityPanel` |
| `MaturidadeRadarChart` | barras estáticas mock |
| `MaturidadeTimelineChart` | — (novo) |
| `MaturidadeIndicatorsRow` | — (novo) |
| `MaturidadeTraceSheet` | `TraceabilityTrigger` mock |
| `SelfAssessmentDialog` | mock action button |
| `ActionPlansPanel` | `actionPlansFull` mock parcial |

---

## Test IDs (RTL)

| ID | Elemento |
|----|----------|
| `maturidade-panel` | container página |
| `maturidade-overall-score` | nota geral |
| `maturidade-axis-{axis}` | card eixo |
| `maturidade-radar-chart` | canvas Nivo |
| `maturidade-timeline-chart` | canvas Nivo |
| `maturidade-indicator-{type}` | card indicador |
| `maturidade-trace-sheet` | sheet rastreio |
| `maturidade-self-assessment-dialog` | dialog |
| `maturidade-action-plans` | lista planos |
| `maturidade-empty-state` | estado vazio |

---

## Referências visuais

- Paleta Mint: rule `mint-palette.mdc`
- Copy: [regras-plataforma.md](../../../.cursor/docs/regras-plataforma.md) §1.2, §1.4, §2.6, R-43, R-50–R-53, R-81
- Mock atual: `CarvalhoMaturityPanel` em `LicensePanels.tsx` (referência layout, não dados)
