# STATUS — 027 Fix Ouvidoria Tramitar

**Data**: 2026-07-01 (arquivada)  
**Estado**: Concluída — 20/20 tasks em `tasks.md`

## Entregue

### Bug principal — "Setor ativo não definido" (400)

**API (`ci-api-v2`)**
- `ResolveTramitacaoSectorUseCase` — parâmetro opcional `preferredModuloSlug`; prioriza setor OUV entre vínculos do usuário; fallback `ModuloSlug.ouvidoria`
- Export do use case em `tramitacao.module.ts`
- `ouvidoria.controller.ts` — remove check manual `setorIds?.[0]`; usa `resolveSector.execute(req.user, undefined, ModuloSlug.ouvidoria)`
- Copy acionável PT-BR para `ACTIVE_SECTOR_UNDEFINED`
- **14 testes** Jest: `resolve-tramitacao-sector` (8), `ouvidoria.controller` (3), `encaminhar-manifestacao` integration (3)

### Correções colaterais (T016–T020, pós-validação)

**Erro 500 — FK `ManifestacaoEvento_autorUserId_fkey`**
- `encaminhar-manifestacao.use-case.ts` — padrão `resolveUserTableId` para `admin_tenant` (`autorUserId` / `createdByUserId` opcionais na timeline e demanda vinculada)

**Client — pós-tramitar**
- `ForwardManifestacaoDialog.tsx` / `ManifestacaoActionDialogs.tsx` — redirect para `/tramitacao/demandas/{tramitacaoDemandaId}` após sucesso

**Snapshot v2 + aba Vínculos (spec 014)**
- `manifestacao-tramitacao-snapshot.mapper.ts` — `schemaVersion: 2` com typeLabel, statusLabel, description, requesterSummary, addressSummary, capturedAt
- `FindManifestacaoByIdRepository` (com endereço) substitui `RequireManifestacaoRepository` no encaminhar
- `LinkedRecordPanel.tsx` — painel rico na aba Vínculos de `TramitacaoInboxWorkspace.tsx`
- `linked-record-snapshot.ts` — parser/merge do contrato ouvidoria/gabinete/jurídico
- `linked-record-pdf.ts` — export PDF client-side (HTML + `window.print()`, sem API)
- Hidratação automática via `getManifestacaoDetail()` para snapshots legados (ex.: seed `OUV-DEMO-2026-0013`)

## Validação

```powershell
cd ci-api-v2; npm test -- --testPathPatterns="resolve-tramitacao-sector|encaminhar-manifestacao|ouvidoria.controller"
cd ci-client-v2/apps/web; npx tsc --noEmit
# Login: admin@jacaranda.com / password123
# Manifestação demo: 11111111-1111-1111-1111-000000000018
# 1) Tramitar → sucesso + redirect demanda TRAM
# 2) Aba Vínculos → metadados completos + Baixar PDF
```

## Critérios spec

| SC / FR | Status |
|---------|--------|
| SC-001–SC-005 tramitação sem erro setor | OK |
| FR-001–FR-010 requisitos originais | OK |
| LinkedRecordPanel (spec 014, escopo ampliado) | OK |
| Responder / Encerrar para admin_tenant | Fora de escopo — mesmo padrão FK pendente |

## Dívidas / futuro

- Aplicar mesmo fix de setor em `juridico.controller.ts` (issue separada)
- `responder` / `encerrar` ouvidoria para `admin_tenant` (FK User)
- Vitest para `linked-record-snapshot.ts` (opcional)
