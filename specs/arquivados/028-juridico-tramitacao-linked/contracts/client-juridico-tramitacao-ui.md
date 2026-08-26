# Contract: Client UI — Jurídico Tramitação Linked

**Feature**: 028-juridico-tramitacao-linked  
**App**: `@ci/web`  
**Modules**: `apps/web/src/modules/juridico/`, `apps/web/src/modules/tramitacao/`

## Rotas (overrides novos)

| screenId | Path | Page | Licença |
|----------|------|------|---------|
| `juridico-lista` | `/juridico/processos` | `JuridicoProcessosListPage` | base |
| `juridico-detalhes` | `/juridico/processos/:id` | `JuridicoProcessoDetailPage` | base |

**Inalteradas nesta feature**: `juridico-novo`, `juridico-editar` (wizard), dashboard/auditoria mock.

### Router (`router.tsx`)

```typescript
const JURIDICO_OVERRIDES: Record<string, ReactNode> = {
  'juridico-lista': <Suspense><JuridicoProcessosListPage /></Suspense>,
  'juridico-detalhes': <Suspense><JuridicoProcessoDetailPage /></Suspense>,
  'juridico-novo': …,  // existente
  'juridico-editar': …,
}
```

Lazy exports em `modules/juridico/index.ts`.

---

## JuridicoProcessosListPage

Layout espelho `ManifestacoesListPage`:

```
┌ Header: Lista de Processos + [Novo Processo] ─────────────┐
├ Filtros: tipo, status, busca q                          │
├ DataTable                                               │
│  Número | Tipo | Partes | Status (badge) | Prazo | Resp.│
└ Paginação page/pageSize                                 ┘
```

- Badge vermelho quando `status === 'critico'`
- Link linha → `/juridico/processos/:id`
- Botão "Novo Processo" → `/juridico/processos/novo`
- `useModuleAccess('juridico')` + `AccessDenied403`
- Zero dados de `mock-data.ts`

---

## JuridicoProcessoDetailPage

```
┌ Header: numeroInterno, tipo badge, status badge ─────────┐
├ Seções: assunto, partes, órgão, prazo, responsável      │
├ Anexos (download links)                                 │
├ ProcessoTimeline (eventos)                              │
├ Ações: [Tramitar] (se acoesPermitidas inclui tramitar)  │
└ ForwardProcessoDialog                                   ┘
```

- 404 → "Processo não encontrado."
- Loading skeleton durante fetch

---

## ForwardProcessoDialog

Clone `ForwardManifestacaoDialog`:

| Campo | Validação |
|-------|----------|
| Setor destino | select `fetchSetores()` |
| Observação | textarea required |

**Submit**: `tramitarProcesso(id, { destinoSetorId, observacao })`

**Sucesso**:

```typescript
showToast({
  title: `Demanda ${result.tramitacaoProtocolNumber} criada`,
  action: { label: 'Ver na Tramitação', onClick: () => navigate(`/tramitacao/demandas/${result.tramitacaoDemandaId}`) },
});
onComplete(); // reload detail (novo evento timeline)
```

**Erro**: mensagem inline (400 rascunho, ACTIVE_SECTOR_UNDEFINED)

---

## API client (`modules/juridico/api/processos.ts`)

**Novos**:

```typescript
listProcessos(params: ListProcessosParams): Promise<PaginatedProcessos>
getProcessoDetail(id: string): Promise<ProcessoDetail>
```

**Existente**: `tramitarProcesso` — sem alteração de assinatura.

Mappers em `modules/juridico/lib/processos-mappers.ts` (API→UI row).

---

## Tramitação — LinkedRecordPanel (alterações)

Arquivo: `modules/tramitacao/components/LinkedRecordPanel.tsx`

**Quando** `sourceModule === 'juridico'`:

1. Parse snapshot via `parseLinkedRecordSnapshot` (já resolve `buildJuridicoSourceHref`)
2. Se `needsJuridicoHydration(snapshot)` → `getProcessoDetail(sourceRecordId)` → `mergeJuridicoDetail`
3. 404 → `origemRemovida: true`; desabilitar botão "Abrir origem"; badge "Origem removida"

### `linked-record-snapshot.ts` (alterações)

- `mergeJuridicoDetail(base, detail)` — campos: tipo, status, partes, órgão, prazo
- Labels `processType` / `TYPE_LABELS` administrativo/judicial/consultivo
- `needsJuridicoHydration` — espelho ouvidoria

---

## MSW (`test/msw/handlers/juridico.ts`)

Adicionar handlers:

- `GET */juridico/processos` — lista paginada fixture
- `GET */juridico/processos/:id` — detalhe fixture
- `POST */juridico/processos/:id/tramitar` — retorno protocol TRAM-*

---

## Copy e UX

- Vocabulário: **Tramitar** (Jurídico), **demanda** (Tramitação)
- Paleta mint-palette
- Toast institucional em PT-BR
- NUNCA "encaminhar" no Jurídico — usar **Tramitar** (regras-plataforma)

---

## Fora de escopo UI

- `JuridicoDashboardPage`, `JuridicoAuditoriaPage` — permanecem mock ScreenPage
- Ações licença Pau-Brasil/Cedro no detalhe — stub/desabilitadas
