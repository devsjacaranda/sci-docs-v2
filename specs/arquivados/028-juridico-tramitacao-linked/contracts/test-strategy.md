# Test Strategy: Jurídico Tramitação Linked

**Feature**: 028-juridico-tramitacao-linked

## Camadas

| Camada | Framework | Escopo |
|--------|-----------|--------|
| Unit API mappers | Jest | snapshot v2, list/detail mappers PT-BR |
| Unit API use cases | Jest | list, detail, tramitar guards |
| Integration API | Jest | tramitar → linked demanda; GET tenant isolation |
| Unit client | Vitest | mergeJuridicoDetail, needsJuridicoHydration |
| Component client | Vitest/RTL | ForwardProcessoDialog submit; LinkedRecordPanel juridico |
| MSW | Vitest | handlers GET list/detail |

Sem Postgres dedicado — Prisma mock + MSW.

---

## Casos de teste

### CT-JT-001 — Snapshot v2 contém labels

**Arquivo**: `ci-api-v2/src/modules/juridico/test/lib/process-tramitacao-snapshot.mapper.spec.ts`  
**Given** processo judicial open com partes  
**When** `mapProcessTramitacaoSnapshot`  
**Then** `schemaVersion === 2`, `typeLabel`, `statusLabel`, `capturedAt` ISO

### CT-JT-002 — Lista exclui soft-deleted

**Arquivo**: `list-processos.use-case.spec.ts`  
**Given** 2 processos, 1 deletedAt set  
**When** list execute  
**Then** total 1

### CT-JT-003 — Detalhe 404 outro tenant

**Arquivo**: `get-processo-detail.use-case.spec.ts`  
**Given** processo tenant A  
**When** execute com context tenant B  
**Then** NotFoundException

### CT-JT-004 — Detalhe acoesPermitidas tramitar

**Given** processo open  
**Then** `acoesPermitidas` includes `tramitar`  
**Given** draft  
**Then** `acoesPermitidas` empty

### CT-JT-005 — Tramitar rascunho 400

**Arquivo**: `tramitar-processo-tramitacao.integration.spec.ts` (existente)  
**Then** BadRequestException

### CT-JT-006 — Tramitar cria linked demanda snapshot v2

**Then** `createLinkedDemanda` called with `sourceModule: juridico`, snapshot v2

### CT-JT-007 — Tramitar cria evento forwarding

**Then** `legalProcessEvent.create` type forwarding

### CT-JT-008 — Controller tramitar resolveSector juridico

**Arquivo**: `juridico.controller.spec.ts`  
**Given** admin_tenant sem setorIds JWT  
**When** POST tramitar  
**Then** resolveSector called with preferredModuloSlug juridico; 200

### CT-JT-009 — mergeJuridicoDetail enriquece campos

**Arquivo**: `linked-record-snapshot.test.ts`  
**Given** base snapshot v1  
**When** merge with detail API  
**Then** typeLabel, parties, isHydrated true

### CT-JT-010 — needsJuridicoHydration v1 true

**Given** snapshot without schemaVersion 2  
**Then** true

### CT-JT-011 — needsJuridicoHydration v2 complete false

**Given** snapshot v2 with all labels  
**Then** false

### CT-JT-012 — ForwardProcessoDialog submit

**Arquivo**: `ForwardProcessoDialog.test.tsx`  
**When** fill setor + obs + submit  
**Then** tramitarProcesso called; toast with protocol

### CT-JT-013 — LinkedRecordPanel juridico hydrate

**Given** sourceModule juridico, snapshot v1  
**Then** getProcessoDetail called; fields populated

### CT-JT-014 — LinkedRecordPanel origem removida

**Given** getProcessoDetail 404  
**Then** hydrationError or origemRemovida; link disabled

### CT-JT-015 — List page renders API rows

**Arquivo**: `JuridicoProcessosListPage.test.tsx`  
**MSW** GET list  
**Then** numeroInterno from fixture visible

### CT-JT-016 — Detail page tramitar button draft hidden

**MSW** detail draft  
**Then** no Tramitar button

### CT-JT-017 — Contract list response shape

**Arquivo**: `juridico.contract.spec.ts`  
**Then** items[].numeroInterno, tipo, status PT-BR

### CT-JT-018 — Seed ID consistency (manual/quickstart)

**Pós-seed**: GET processo `00000000-0000-4000-8000-000000000088` 200; demanda linked Abrir origem OK

---

## Ordem TDD recomendada

1. CT-JT-001 (snapshot) → CT-JT-006/007 (integration tramitar update)
2. CT-JT-002–004 (list/detail use cases) → CT-JT-017
3. CT-JT-008 (controller sector)
4. CT-JT-009–011 (client snapshot)
5. CT-JT-012–016 (UI)
6. CT-JT-018 (seed smoke manual)

---

## Comandos

```powershell
cd ci-api-v2; npm test -- --testPathPatterns=juridico
cd ci-client-v2/apps/web; npm test -- juridico
cd ci-client-v2/apps/web; npm test -- linked-record-snapshot
```
