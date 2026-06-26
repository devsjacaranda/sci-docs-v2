# Contract: Client UI — Tramitação

**Feature**: 014-desmock-tramitacao  
**App**: `@ci/web`  
**Module**: `apps/web/src/modules/tramitacao/`

## Rotas

| Path | Page | Licença | Screen id |
|------|------|---------|-------------|
| `/tramitacao/dashboard` | `TramitacaoDashboardPage` | Base | `tramitacao-dashboard` |
| `/tramitacao/demandas` | `TramitacaoInboxPage` | Base | `tramitacao-demandas` |
| `/tramitacao/demandas/novo` | `TramitacaoComposePage` | Base | — |
| `/tramitacao/demandas/:id` | `TramitacaoDemandaDetailPage` | Base | — |
| `/tramitacao/auditoria` | `TramitacaoAuditoriaPage` | Jatobá | `tramitacao-auditoria` |
| `/tramitacao/insights` | `TramitacaoInsightsPage` | Cedro | `tramitacao-insights` |
| `/tramitacao/maturidade` | `TramitacaoMaturidadePage` | Carvalho | `tramitacao-maturidade` |

Registro: `router.tsx` overrides (padrão `gabinete/`, `juridico/`). `screens.ts` mantém metadados; `ScreenPage` **não** renderiza `tramitacao-*`.

Navegação: `navigation.ts` — `licenseNav('tramitacao')` + Fiscalização.

---

## Inbox (`TramitacaoInboxPage`)

Layout email-like — evolução de `TramitacaoInboxPanel`:

```
┌─────────────────────────────────────────────────────────┐
│ ListLicenseAlertBar (tramitacao)                        │
├──────────┬──────────────────────────────────────────────┤
│ Pastas   │ Lista demandas                               │
│ Recebidas│ ┌──────────────────────────────────────────┐ │
│ Enviadas │ │ TRAM-2026-0012 · Assunto                 │ │
│ Arquivadas│ │ OUV → DEJUR · Linked · Prazo 01/07     │ │
│          │ └──────────────────────────────────────────┘ │
│ [Compor] │                                              │
└──────────┴──────────────────────────────────────────────┘
```

- Pastas: tabs ou sidebar — query `folder=received|sent|archived`
- Badge origem: `Genérica` | `Gabinete` | `Ouvidoria` | `Jurídico`
- Botão **Compor** → `/tramitacao/demandas/novo`
- Empty states por pasta
- Mobile: bottom nav existente

---

## Compor (`TramitacaoComposePage`)

Form texto simples:

- Select setor destino (lista setores tenant)
- Assunto (required)
- Corpo (textarea, required)
- Prazo (date optional)
- Submit → POST `/tramitacao/demandas` → redirect detalhe

---

## Detalhe (`TramitacaoDemandaDetailPage`)

```
┌ Header: protocolo, status badge, origem badge ─────────┐
├ LinkedRecordPanel (snapshot JSON formatado)          │
├ DemandaThread (timeline created/reply/forward)       │
├ Actions: Responder | Encaminhar | Arquivar           │
└ License sheets bloqueados se sem licença               │
```

- `LinkedRecordPanel`: exibe `sourceSnapshot`; se registro origem deletado → badge "Origem removida"
- `ForwardDemandaDialog`: select setor + notas
- Reply inline na thread

---

## Dashboard (`TramitacaoDashboardPage`)

KPI cards: total, pendentes, respondidas, resolutividade.

Gráficos Nivo:

- Donut/pie `bySourceModule`
- Filtro período (7/30/90/365 dias)

---

## Licenças UI

| Page | Componentes reuso | Adaptação |
|------|-------------------|-----------|
| Auditoria | `OuvidoriaAuditoriaPage` / `GabineteAuditoriaPage` clone | labels Tramitação, protocol TRAM-* |
| Insights | Cedro panel clone | gargalos setores, volume módulo |
| Maturidade | Carvalho radar clone | eixos tramitacao seed |

Alertas: `ListLicenseAlertBar` + `getModuleLicenseTraffic('tramitacao')` com dados API licença tenant.

Sheets rastreabilidade: substituir `traceability-mock.ts` por config canônica licenças.

---

## Integrações cross-módulo (client)

| Módulo | UI | API origem | Efeito |
|--------|-----|------------|--------|
| Gabinete | `ForwardDemandaDialog` / Tramitar | `POST /gabinete/cabinets/:id/forward` | cria demanda tramitacao |
| Ouvidoria | Encaminhar setor | `POST /ouvidoria/manifestacoes/:id/encaminhar` | idem |
| Jurídico | Tramitar processo | `POST /juridico/processos/:id/tramitar` | idem |

Após sucesso: toast + link "Ver na Tramitação" → `/tramitacao/demandas/:tramitacaoId`

---

## Remoção mock shell

Após paridade, remover ou deprecar:

- `shell/data/tramitacao-mock.ts`
- `shell/components/mock/TramitacaoInboxPanel.tsx`
- `shell/lib/tramitacao-status.ts` (migrar lógica útil a `tramitacao/lib/`)
- Entradas mock `tramitacao` em `mock-data.ts` (jatoba/cedro rows)

Manter `tramitacao-draft.ts` apenas se cross-módulo localStorage ainda usado — avaliar remoção na implementação.

---

## Copy e UX

- Vocabulário: **demanda** (Tramitação), não "ato" (Gabinete)
- Protocolo: `TRAM-AAAA-NNNN`
- Paleta mint-palette; shadcn/ui
- Skills: `ui-ux-pro-max`, `vite-react-best-practices`
