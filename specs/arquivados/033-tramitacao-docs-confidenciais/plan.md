# Implementation Plan: Documentos confidenciais na Tramitação

**Branch**: `033-tramitacao-docs-confidenciais` | **Date**: 2026-07-03 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/033-tramitacao-docs-confidenciais/spec.md`

## Summary

Implementar **upload de anexos** (arquivo + link) no módulo Tramitação e **confidencialidade granular por documento**: mensagem/registro/timeline permanecem visíveis ao setor; cada anexo pode ser público ou confidencial com ACL multi-setor (≥1 usuário por setor). Inclui todos os fluxos: criar setorial, responder, encaminhar, caixa pessoal e promoção pessoal→setor (ACL imutável). `admin_tenant` vê tudo em auditoria; não autorizados veem placeholder sem download.

**Abordagem**: migration Prisma (`uploadConfirmed`, `uploadedByUserId`, `isConfidential` + tabela `TramitacaoDemandaAnexoAccess`); use cases presign/confirm/link/download reutilizando `StorageService`; `resolveAnexoAccessLevel` no mapper e download guard; UI `TramitacaoAnexoUploadZone` + `ConfidentialAccessPicker` no workspace existente.

## Technical Context

**Language/Version**: TypeScript 5.x / 6.x; Node.js 20 LTS

**Primary Dependencies**:

| Pacote | Stack |
|--------|-------|
| **ci-api-v2** | NestJS 11, Fastify, Pino, Zod (nestjs-zod), Prisma 7, PostgreSQL, Wasabi/MinIO |
| **ci-client-v2** | React 19, Vite 8, Tailwind v4, shadcn/ui, Vitest 3 |

**Storage**: PostgreSQL — `tramitacao.prisma` + `TramitacaoDemandaAnexoAccess`; Wasabi presigned via `StorageModule`

**Testing**: Jest unit + integration; Vitest/RTL client — [test-strategy.md](./contracts/test-strategy.md)

**Target Platform**: API Linux/container; SPA browser (`@ci/web`)

**Project Type**: Full-stack feature (extensão módulo tramitação)

**Performance Goals**: Upload presign < 500ms p95; detail com anexos < 800ms p95; download guard < 200ms p95

**Constraints**:

- TDD obrigatório RED → GREEN → REFACTOR
- Zod only em `tramitacao.schemas.ts`
- Tenant AsyncLocalStorage — nunca passar `tenantId` manual
- `@RequireModulo('tramitacao')` em rotas
- `resolveUserTableId` para `uploadedByUserId`; actor payload quando admin
- `MAX_ANEXO_BYTES` 30 MB + MIME allowlist (ouvidoria constants)
- Placeholder **nunca** expõe `url`, `storageKey`, `downloadUrl` (SC-002)
- ACL imutável após confirm (forward/promote não alteram grants)
- Copy PT-BR [regras-plataforma.md](../../../.cursor/docs/regras-plataforma.md); paleta mint-palette
- Licença **Base** Tramitação — sem upgrade

**Scale/Scope**: ~5 endpoints novos; 1 migration; ~10 use cases/repos novos; 4 componentes client; ~35 arquivos tocados

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Princípio | Status | Notas |
|-----------|--------|-------|
| I. Spec-Driven | ✅ PASS | Spec 033 + checklist validados |
| II. Test-First | ✅ PASS | CT-DC-001..022 em test-strategy |
| III. Stack fixa | ✅ PASS | NestJS 11 + Prisma 7 + React 19 + Zod only |
| IV. Multi-tenant | ✅ PASS | Repos tenant-scoped; ACL por tenant |
| IV. Licenças | ✅ PASS | Módulo tramitacao Base |
| V. Escopo mínimo | ✅ PASS | Extensão `TramitacaoDemandaAnexo`; padrão gabinete/ouvidoria |

**Post-design re-check**: Tabela junction justificada (multi-setor, query download). Reuso StorageService evita novo subsistema. Mapper placeholder fecha SC-002 sem vazar URLs. Sem Complexity Tracking necessário.

## Project Structure

### Documentation (this feature)

```text
civ2-docs/specs/033-tramitacao-docs-confidenciais/
├── plan.md              # This file
├── research.md          # Phase 0
├── data-model.md        # Phase 1
├── quickstart.md        # Phase 1
├── contracts/
│   ├── rest-api-tramitacao-docs-confidenciais.md
│   ├── client-tramitacao-docs-confidenciais-ui.md
│   └── test-strategy.md
└── tasks.md             # Phase 2 — /speckit-tasks
```

### Source Code (repository root)

```text
ci-api-v2/
├── prisma/schema/tramitacao.prisma                           # UPDATE anexo fields + Access model
├── prisma/migrations/YYYYMMDD_tramitacao_anexo_confidential/ # NEW
├── src/modules/tramitacao/
│   ├── tramitacao.controller.ts                              # UPDATE anexo routes
│   ├── tramitacao.schemas.ts                                 # UPDATE Zod presign/confirm/access
│   ├── tramitacao.mapper.ts                                  # UPDATE timeline anexos + accessLevel
│   ├── tramitacao-anexo.constants.ts                         # NEW (re-export ouvidoria)
│   ├── lib/
│   │   ├── resolve-anexo-access.ts                           # NEW
│   │   └── validate-anexo-access.ts                          # NEW
│   ├── repository/
│   │   └── anexo.repositories.ts                           # NEW
│   ├── use-cases/
│   │   ├── presign-anexo.use-case.ts                         # NEW
│   │   ├── confirm-anexo.use-case.ts                         # NEW
│   │   ├── add-link-anexo.use-case.ts                        # NEW
│   │   ├── download-anexo.use-case.ts                        # NEW
│   │   ├── get-demanda-detail.use-case.ts                    # UPDATE include anexos+access
│   │   ├── reply-demanda.use-case.ts                         # UPDATE return eventId for anexo bind
│   │   └── forward-demanda.use-case.ts                       # UPDATE idem
│   └── test/
│       ├── anexo-upload.integration.spec.ts                  # NEW CT-DC-001..005
│       ├── anexo-confidential.integration.spec.ts            # NEW CT-DC-006..014
│       └── anexo-forward-promote.integration.spec.ts         # NEW CT-DC-015..018

ci-client-v2/apps/web/src/modules/tramitacao/
├── api/anexos.ts                                             # NEW
├── lib/anexo-schemas.ts                                      # NEW
├── components/
│   ├── TramitacaoAnexoUploadZone.tsx                         # NEW
│   ├── ConfidentialAccessPicker.tsx                          # NEW
│   ├── TramitacaoAnexoList.tsx                               # NEW
│   └── TramitacaoInboxWorkspace.tsx                          # UPDATE compose/reply/forward
└── components/__tests__/                                     # NEW CT-DC-019..021
```

**Structure Decision**: Extensão incremental em `tramitacao/` API + client; reuso `StorageService`, `fetchSetores`/`fetchUsers`, padrão `AnexoUploadZone` de ouvidoria adaptado com confidencialidade.

## Implementation Phases

### Phase A — Schema & migration (P1)

1. Campos `uploadConfirmed`, `uploadedByUserId`, `isConfidential` em `TramitacaoDemandaAnexo`
2. Model `TramitacaoDemandaAnexoAccess`
3. Índices e FK nullable `uploadedByUserId`

### Phase B — API upload baseline (P1 US1)

1. `presign-anexo`, `confirm-anexo`, `add-link-anexo` use cases + repos
2. Rotas controller + Zod schemas
3. `get-demanda-detail` inclui anexos por evento (públicos only inicialmente)
4. TDD CT-DC-001..005

### Phase C — ACL confidencial (P1 US2–US3)

1. `validate-anexo-access` + `resolve-anexo-access`
2. Confirm/link persiste Access rows
3. Mapper `accessLevel` full/placeholder
4. `download-anexo` com guard
5. TDD CT-DC-006..014

### Phase D — Forward, pessoal, audit (P2 US4–US7)

1. Integrar anexos em reply/forward/personal flows (eventoId binding)
2. Verificar ACL imutável em forward/promote
3. admin_tenant bypass em resolve
4. TDD CT-DC-015..018

### Phase E — Client UI (P1–P2)

1. `api/anexos.ts` + schemas
2. `ConfidentialAccessPicker` + `TramitacaoAnexoUploadZone`
3. Integrar workspace compose/reply/forward (setor + pessoal)
4. `TramitacaoAnexoList` na timeline detail
5. TDD CT-DC-019..022; MSW handlers

## Artifacts Generated

| Artifact | Path |
|----------|------|
| Research | [research.md](./research.md) |
| Data model | [data-model.md](./data-model.md) |
| REST contract | [contracts/rest-api-tramitacao-docs-confidenciais.md](./contracts/rest-api-tramitacao-docs-confidenciais.md) |
| UI contract | [contracts/client-tramitacao-docs-confidenciais-ui.md](./contracts/client-tramitacao-docs-confidenciais-ui.md) |
| Test strategy | [contracts/test-strategy.md](./contracts/test-strategy.md) |
| Quickstart | [quickstart.md](./quickstart.md) |

## Next Step

`/speckit-tasks` — quebrar fases A–E em tasks acionáveis com TDD.
