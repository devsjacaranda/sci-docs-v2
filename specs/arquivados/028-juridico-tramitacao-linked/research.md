# Research: Integrar Jurídico à Tramitação — Linked Record

**Feature**: 028-juridico-tramitacao-linked  
**Date**: 2026-07-01

## R1 — Gap analysis (estado atual vs spec)

**Decision**: Feature é **completar US11 da spec 014**, não greenfield.

**Findings**:

| Capacidade | API | Client |
|------------|-----|--------|
| POST tramitar | ✅ `TramitarProcessoUseCase` | ❌ sem UI |
| GET lista processos | ❌ schema existe, rota ausente | ❌ mock `ScreenPage` |
| GET detalhe processo | ❌ ausente | ❌ mock `ScreenPage` |
| Snapshot linked v2 | ❌ v1 (`processType`, sem labels) | parcial parse |
| LinkedRecordPanel hydrate | N/A | ❌ só ouvidoria |
| Seed linked juridico | ❌ demanda genérica sem processo real | — |

**Rationale**: Evita duplicar trabalho; foco em endpoints/UI faltantes + paridade ouvidoria.

**Alternatives considered**: Nova entidade `JuridicoTramitacaoLink` — rejeitado; `TramitacaoDemanda.sourceRecordId` já cobre.

---

## R2 — Contrato REST lista/detalhe

**Decision**: Implementar GET conforme spec 012 arquivada; resposta PT-BR via mapper (`tipo`, `status`, `numeroInterno`).

**Rationale**: `listProcessosQuerySchema` e `juridico.mapper.ts` já existem; contrato 012 validado em produto.

**Alternatives considered**: GraphQL ou campos EN na API — rejeitado; client ouvidoria usa PT-BR.

**Detalhes**:

- Lista: `partesResumo` = primeiras 2–3 partes `"Nome (polo)"` separadas por ` · `
- Status lista: `deriveOperationalStatus` (open/expiring/critical) — não status armazenado bruto
- Detalhe: incluir `acoesPermitidas: ['tramitar']` quando status ≠ draft; timeline eventos ordenados ASC
- Anexos confirmados: presign download URL (padrão ouvidoria)

---

## R3 — Resolução setor origem (tramitar)

**Decision**: Reutilizar `ResolveTramitacaoSectorUseCase` com `preferredModuloSlug: ModuloSlug.juridico` no controller — mesmo fix aplicado à Ouvidoria na spec 027.

**Rationale**: `juridico.controller.ts` hoje usa `req.user.setorIds?.[0]` → 400 para admin_tenant.

**Alternatives considered**: Exigir setor explícito no body — rejeitado; quebra paridade ouvidoria/gabinete.

---

## R4 — Snapshot schemaVersion 2

**Decision**: Estender `mapProcessTramitacaoSnapshot` para incluir:

```typescript
{
  schemaVersion: 2,
  protocolNumber: internalNumber,
  processType: type,
  typeLabel: 'Administrativo' | 'Judicial' | 'Consultivo',
  status, statusLabel,
  summary: subject,
  partiesSummary,
  capturedAt: ISO8601,
}
```

**Rationale**: `LinkedRecordPanel.needsOuvidoriaHydration` checa `schemaVersion !== 2`; snapshots jurídicos atuais sempre forçam fetch ou exibem campos crus.

**Alternatives considered**: Hidratação sempre via GET — rejeitado como única estratégia; snapshot deve ser autossuficiente offline.

---

## R5 — UI lista/detalhe (client)

**Decision**: Criar `JuridicoProcessosListPage` + `JuridicoProcessoDetailPage`; registrar em `JURIDICO_OVERRIDES` — **não** alterar `ScreenPage` global.

**Rationale**: Padrão estabelecido ouvidoria (`ManifestacoesListPage`, `ManifestacaoDetailPage`).

**Alternatives considered**: Desmock completo jurídico (012) — fora escopo; dashboard/auditoria permanecem mock.

**Componentes reuso**:

- `ForwardProcessoDialog` ← clone `ForwardManifestacaoDialog` (setores + toast + navigate)
- `ProcessoTimeline` ← clone `ManifestacaoTimeline`
- `useModuleAccess('juridico')` + `AccessDenied403`

---

## R6 — Linked record hidratação jurídica

**Decision**: Espelhar fluxo ouvidoria em `LinkedRecordPanel`:

1. `needsJuridicoHydration(snapshot)` — true se `schemaVersion !== 2` ou faltam labels
2. `getProcessoDetail(sourceRecordId)` → `mergeJuridicoDetail`
3. 404 → manter snapshot + flag `origemRemovida` (desabilitar link)

**Rationale**: FR-010 spec 028; paridade UX ouvidoria.

---

## R7 — Seed demo

**Decision**: Novo `seed-juridico-demo.ts` com ID fixo `00000000-0000-4000-8000-000000000088` (processo linked) + 2 processos extras; atualizar `seed-tramitacao-demo.ts` linked record.

**Rationale**: Lição spec 028 ouvidoria fix — phantom IDs causam 404 em "Abrir origem".

**Alternatives considered**: Query dinâmica pós-seed — rejeitado; ID fixo facilita quickstart e testes E2E.

---

## R8 — Test strategy

**Decision**: 5 camadas espelhando 027/014:

1. Unit mapper snapshot v2
2. Unit list/detail mappers client
3. Integration tramitar + linked demanda
4. Integration GET list/detail tenant isolation
5. Vitest linked-record-snapshot merge juridico
6. MSW handlers juridico GET

**Rationale**: Constitution II; sem Postgres dedicado — mocks Prisma + MSW.
