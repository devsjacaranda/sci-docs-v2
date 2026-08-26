# Test Strategy: Gabinete Tramitação Linked

**Feature**: 030-gabinete-tramitacao-linked

## Camadas

| Camada | Framework | Escopo |
|--------|-----------|--------|
| Unit API snapshot | Jest | `mapCabinetTramitacaoSnapshot` v2 |
| Unit API use case | Jest | forward guards status, notes required |
| Integration API | Jest | forward → linked demanda; admin_tenant actor |
| Unit client | Vitest | mergeGabineteDetail, needsGabineteHydration |
| Component client | Vitest/RTL | ForwardAtoDialog notes; LinkedRecordPanel gabinete |

Sem Postgres dedicado — Prisma mock + fetch mock.

---

## Casos de teste

### CT-GT-001 — Snapshot v2 contém labels

**Arquivo**: `ci-api-v2/src/modules/gabinete/test/lib/cabinet-tramitacao-snapshot.mapper.spec.ts`  
**Given** ato `in_analysis` origin `internal`  
**When** `mapCabinetTramitacaoSnapshot`  
**Then** `schemaVersion === 2`, `statusLabel`, `originLabel`, `capturedAt` ISO

### CT-GT-002 — Forward rascunho 400

**Arquivo**: `forward-cabinet.use-case.spec.ts`  
**Given** cabinet status `draft`  
**Then** BadRequestException INVALID_STATUS

### CT-GT-003 — Forward archived/finished 400

**Given** status `archived` ou `finished`  
**Then** BadRequestException

### CT-GT-004 — Forward notes vazio 400 (schema)

**Arquivo**: `gabinete.schemas.spec.ts`  
**Given** body `{ sectorId, notes: '' }`  
**Then** Zod parse fails

### CT-GT-005 — Forward cria linked demanda snapshot v2

**Arquivo**: `forward-cabinet-tramitacao.integration.spec.ts` (existente — UPDATE)  
**Then** `createLinkedDemanda` with `sourceModule: gabinete`, snapshot v2 fields

### CT-GT-006 — Forward atualiza status in_transit

**Then** `forwardCabinet.execute` sets status `in_transit`

### CT-GT-007 — Forward cria evento forwarded

**Then** `createEvento` type `forwarded`, `withActorPayload`

### CT-GT-008 — Admin tenant sem User FK

**Given** actor role `admin_tenant`  
**When** forward  
**Then** success; `authorUserId` undefined/null in evento; payload has actorId

### CT-GT-009 — mergeGabineteDetail enriquece campos

**Arquivo**: `linked-record-snapshot.test.ts`  
**Given** base snapshot v1  
**When** merge with CabinetDetail  
**Then** statusLabel, originLabel, isHydrated true

### CT-GT-010 — needsGabineteHydration v1 true

**Given** snapshot without schemaVersion 2  
**Then** true

### CT-GT-011 — needsGabineteHydration v2 complete false

**Given** snapshot v2 with statusLabel + originLabel  
**Then** false

### CT-GT-012 — ForwardAtoDialog notes required

**Arquivo**: `ForwardAtoDialog.test.tsx`  
**When** setor selected, notes empty, submit  
**Then** button disabled or validation error; API not called

### CT-GT-013 — ForwardAtoDialog submit success

**When** setor + notes filled  
**Then** forwardCabinet called; toast with protocol

### CT-GT-014 — LinkedRecordPanel gabinete hydrate

**Arquivo**: `LinkedRecordPanel.gabinete.test.tsx`  
**Given** sourceModule gabinete, snapshot v1  
**Then** getCabinetDetail called; fields populated

### CT-GT-015 — LinkedRecordPanel origem removida

**Given** getCabinetDetail 404  
**Then** origemRemovida; link disabled

### CT-GT-016 — Seed ID consistency (manual/quickstart)

**Pós-seed**: GET cabinet `00000000-0000-4000-8000-000000000077` 200; demanda linked Abrir origem OK

---

## Ordem TDD recomendada

1. CT-GT-001 (snapshot) → CT-GT-004 (schema notes)
2. CT-GT-002–003, CT-GT-005–008 (use case + integration)
3. CT-GT-009–011 (client snapshot)
4. CT-GT-012–015 (UI)
5. CT-GT-016 (seed smoke manual)

---

## Comandos

```powershell
cd ci-api-v2; npm test -- --testPathPatterns=gabinete
cd ci-api-v2; npm test -- --testPathPatterns=forward-cabinet
cd ci-client-v2/apps/web; npm test -- linked-record-snapshot
cd ci-client-v2/apps/web; npm test -- ForwardAtoDialog
cd ci-client-v2/apps/web; npm test -- LinkedRecordPanel
```
