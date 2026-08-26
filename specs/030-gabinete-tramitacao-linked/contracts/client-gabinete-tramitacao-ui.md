# Contract: Client UI — Gabinete Tramitação Linked

**Feature**: 030-gabinete-tramitacao-linked  
**App**: `@ci/web`  
**Modules**: `apps/web/src/modules/gabinete/`, `apps/web/src/modules/tramitacao/`

## Rotas (existentes — sem novas páginas)

| screenId | Path | Page | Alteração |
|----------|------|------|-----------|
| `gabinete-lista` | `/gabinete/atos` | `GabineteAtosListPage` | Tramitar modal — hardening |
| `gabinete-detalhes` | `/gabinete/atos/:id` | `GabineteAtoDetailPage` | `ForwardAtoDialog` — hardening |

Lista e detalhe já reais (spec 012). Esta feature **não** adiciona páginas novas.

---

## GabineteAtosListPage (alterações)

Menu linha → ação **Tramitar** (`Share2`):

- Oculta quando `status ∈ {archived, finished}` (`NON_TRAMITABLE_STATUSES`)
- Abre `ForwardAtoDialog` controlado via `tramitarId`
- `onComplete`: reload lista + toast

---

## GabineteAtoDetailPage (alterações)

Header ações → `ForwardAtoDialog` (trigger inline "Tramitar"):

- Ocultar/desabilitar para rascunho, arquivado, finalizado
- `onComplete`: reload detail (timeline + status)

---

## ForwardAtoDialog (alterações)

| Campo | Validação | Alteração |
|-------|----------|-----------|
| Setor destino | select `fetchSetores()` | — |
| Observações | textarea **required** min 1 | era optional |

**Submit**: `forwardCabinet(cabinetId, { sectorId, notes })`

**Sucesso** (mantido):

- Toast `Demanda TRAM-* criada na Tramitação`
- Link protocolo → `/tramitacao/demandas/:id`
- Botão "Ver inbox do setor destino"
- `sessionStorage` `tramitacao-active-sector-id`

**Erro**: mensagem inline preservando form (400 status, SAME_SECTOR, SENDER_SECTOR_UNDEFINED)

**Copy**:

- Título modal: "Tramitar ato"
- Botão confirmar: "Confirmar tramitação"
- Label observações: "Observações *" placeholder "Motivo do encaminhamento"

---

## API client (`modules/gabinete/api/cabinets.ts`)

**Existente** — sem alteração de assinatura:

```typescript
forwardCabinet(cabinetId: string, body: { sectorId: string; notes: string })
getCabinetDetail(cabinetId: string): Promise<CabinetDetail>
```

Tipo `notes` passa a required no TypeScript após schema API.

---

## Tramitação — LinkedRecordPanel (alterações)

Arquivo: `modules/tramitacao/components/LinkedRecordPanel.tsx`

**Quando** `sourceModule === 'gabinete'`:

1. Parse snapshot via `parseLinkedRecordSnapshot` (já resolve `buildGabineteSourceHref`)
2. Se `needsGabineteHydration(snapshot)` → `getCabinetDetail(sourceRecordId)` → `mergeGabineteDetail`
3. 404 → `origemRemovida: true`; desabilitar "Abrir origem"

### `linked-record-snapshot.ts` (alterações)

- `mergeGabineteDetail(base, detail)` — protocolo, assunto, statusLabel, originLabel, description
- `needsGabineteHydration(snapshot)` — espelho jurídico/ouvidoria
- `CABINET_STATUS_LABELS` / `CABINET_ORIGIN_LABELS` maps (PT-BR)

**Badge painel**: status operacional + origem do ato.

---

## MSW (opcional)

Se handlers gabinete existirem em testes tramitação, adicionar fixture GET detail para hydrate — não bloqueante se testes mockam `getCabinetDetail` diretamente.

---

## Copy e UX

- Vocabulário: **Tramitar** (Gabinete), **demanda** (Tramitação), **ato** (nunca "demanda" na UI gabinete)
- Paleta mint-palette
- Toast institucional PT-BR
- regras-plataforma: SEMPRE "Tramitar" no Gabinete

---

## Fora de escopo UI

- Dashboard, auditoria, insights, maturidade gabinete
- Alteração de rotas `/gabinete/atos/*`
- Tramitar cadastros auxiliares isolados (protocolo, numérico, etc.)
