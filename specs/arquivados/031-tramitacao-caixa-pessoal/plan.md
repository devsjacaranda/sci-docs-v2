# Implementation Plan: Caixa Pessoal na Tramitação

**Branch**: `031-tramitacao-caixa-pessoal` | **Date**: 2026-07-02 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/031-tramitacao-caixa-pessoal/spec.md`

## Summary

Estender o módulo Tramitação com **caixa pessoal** (mensagens usuário-a-usuário) reutilizando `TramitacaoDemanda`, sem entidade paralela. Hoje a inbox é 100% inter-setorial (`senderSectorId` / `currentSectorId`); a feature adiciona `originType: personal`, destinatário usuário (`targetUserId`), filtros de inbox por participante, guards de autorização em detalhe/ações, toggle **Setor / Pessoal** no client, encaminhamento para outro usuário ou promoção setorial irreversível, linked record pessoal e auditoria read-only para `admin_tenant`.

**Abordagem**: migration Prisma mínima + use cases dedicados (`create-personal-demanda`, `forward-personal-to-user`, `promote-personal-to-sector`, `assert-personal-access`, `list-personal-inbox`, `list-personal-audit`); estender notificações (029) com tipos pessoais; hardening de autorização em endpoints existentes para demandas pessoais.

## Technical Context

**Language/Version**: TypeScript 5.x / 6.x; Node.js 20 LTS

**Primary Dependencies**:

| Pacote | Stack |
|--------|-------|
| **ci-api-v2** | NestJS 11, Fastify, Pino, Zod, Prisma 7, PostgreSQL |
| **ci-client-v2** | React 19, Vite 8, Tailwind v4, shadcn/ui, react-router-dom 7, Vitest 3 |

**Storage**: PostgreSQL — migration em `tramitacao.prisma`: enum `personal`, campos `targetUserId`, `personalActive`, índices inbox pessoal

**Testing**: Jest unit + integration (`ci-api-v2`); Vitest/RTL (`ci-client-v2`) — [test-strategy.md](./contracts/test-strategy.md)

**Target Platform**: API Linux/container; SPA browser (`@ci/web`)

**Project Type**: Full-stack feature (extensão módulo tramitação + notificações)

**Performance Goals**: Compor pessoal < 3s p95; list inbox pessoal < 500ms p95; notificação < 30s SC-003

**Constraints**:

- TDD obrigatório RED → GREEN → REFACTOR
- Zod only em `tramitacao.schemas.ts`
- Tenant AsyncLocalStorage — nunca passar `tenantId` manual
- `@RequireModulo('tramitacao')` em rotas tramitação
- `resolveUserTableId` + `withActorPayload` para admin_tenant (FK User nullable)
- Demandas pessoais **excluídas** de `buildInboxWhere` setorial via filtro `originType != personal OR personalActive = false`
- Notificações pessoais: **somente participante relevante** — sem broadcast setorial (FR-013)
- Copy PT-BR [regras-plataforma.md](../../../.cursor/docs/regras-plataforma.md); paleta mint-palette
- Licença **Base** apenas — sem upgrade Jatobá/Cedro

**Scale/Scope**: ~6 endpoints novos/alterados; 1 migration; ~8 use cases novos/alterados; 1 componente workspace alterado; extensão notificações; ~25 arquivos tocados

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Princípio | Status | Notas |
|-----------|--------|-------|
| I. Spec-Driven | ✅ PASS | Spec 031 + checklist validados |
| II. Test-First | ✅ PASS | test-strategy CT-CP-001..020 |
| III. Stack fixa | ✅ PASS | NestJS 11 + Prisma 7 + React 19 + Vite 8 |
| IV. Multi-tenant | ✅ PASS | Repositories tenant-scoped; guards por actor JWT |
| IV. Licenças | ✅ PASS | Base Tramitação only |
| V. Escopo mínimo | ✅ PASS | Reuso `TramitacaoDemanda` + eventos; sem módulo paralelo |

**Post-design re-check**: Migration justificada (FR-001/002 campos destinatário). Guards de autorização fecham gap de segurança existente (GET detalhe aberto). Polimorfismo admin_tenant via actor payload + `targetUserId` / participação lógica — alinhado rule `admin-tenant-user-fk.mdc`. Sem Complexity Tracking necessário.

## Project Structure

### Documentation (this feature)

```text
civ2-docs/specs/031-tramitacao-caixa-pessoal/
├── plan.md              # This file
├── research.md          # Phase 0
├── data-model.md        # Phase 1
├── quickstart.md        # Phase 1
├── contracts/
│   ├── rest-api-tramitacao-caixa-pessoal.md
│   ├── client-tramitacao-caixa-pessoal-ui.md
│   └── test-strategy.md
└── tasks.md             # Phase 2 — /speckit-tasks
```

### Source Code (repository root)

```text
ci-api-v2/
├── prisma/schema/tramitacao.prisma                    # UPDATE enum + fields + indexes
├── prisma/migrations/YYYYMMDD_tramitacao_personal/    # NEW
├── src/modules/tramitacao/
│   ├── tramitacao.controller.ts                       # UPDATE routes + guards
│   ├── tramitacao.schemas.ts                          # UPDATE Zod (inboxMode, personal body)
│   ├── tramitacao.mapper.ts                           # UPDATE DTOs (participants, mode)
│   ├── lib/
│   │   ├── inbox-folder-filter.ts                     # UPDATE exclude personal from sector
│   │   ├── personal-inbox-folder-filter.ts            # NEW
│   │   └── assert-personal-demanda-access.ts          # NEW
│   ├── use-cases/
│   │   ├── create-personal-demanda.use-case.ts        # NEW
│   │   ├── create-personal-linked-demanda.use-case.ts # NEW (optional v1 compose w/ link)
│   │   ├── forward-personal-to-user.use-case.ts       # NEW
│   │   ├── promote-personal-to-sector.use-case.ts     # NEW
│   │   ├── list-personal-inbox.use-case.ts             # NEW
│   │   ├── list-personal-audit.use-case.ts            # NEW (admin_tenant)
│   │   ├── get-demanda-detail.use-case.ts             # UPDATE access guard
│   │   ├── reply-demanda.use-case.ts                  # UPDATE personal branch
│   │   └── archive-demanda.use-case.ts                # UPDATE personal branch
│   └── test/
│       ├── personal-inbox.integration.spec.ts         # NEW
│       ├── personal-access.integration.spec.ts        # NEW
│       └── promote-personal-sector.integration.spec.ts # NEW
├── src/modules/notificacao/
│   ├── services/resolve-tramitacao-recipients.service.ts  # UPDATE forPersonalParticipant
│   └── services/tramitacao-notificacao.service.ts           # UPDATE personal events

ci-client-v2/apps/web/src/modules/tramitacao/
├── components/TramitacaoInboxWorkspace.tsx            # UPDATE toggle Setor/Pessoal + compose user
├── api/demandas.ts                                    # UPDATE inboxMode, personal APIs
├── hooks/useTramitacaoInboxMode.ts                    # NEW (sector|personal|audit)
└── lib/__tests__/personal-inbox.test.ts               # NEW (folder helpers)
```

**Structure Decision**: Extensão incremental em `tramitacao/` (API + client) e `notificacao/` (dispatch); reutilizar `fetchUsers` de `@/modules/setor/api/users-admin` para seletor de destinatário.

## Implementation Phases

### Phase A — Schema & migration (P1)

1. `TramitacaoDemandaOriginType.personal`
2. Campos `targetUserId`, `personalActive` (default `true`)
3. Índices `(tenantId, targetUserId, personalActive, status)`, `(tenantId, createdByUserId, originType)`
4. `TramitacaoDemandaEventType`: payload estendido em `forwarded` com `targetKind: 'user' | 'sector'`

### Phase B — API inbox pessoal + compose (P1 US1–US3)

1. `buildPersonalInboxWhere(folder, actor)` — received/sent/archived por participante
2. `ListPersonalInboxUseCase` + query `inboxMode=personal`
3. `CreatePersonalDemandaUseCase` — valida destinatário ativo ≠ remetente
4. `AssertPersonalDemandaAccess` em GET detail, reply, archive
5. Excluir `originType=personal AND personalActive=true` de inbox setorial
6. TDD integration specs CT-CP-001..008

### Phase C — Encaminhamentos (P2 US4–US5)

1. `ForwardPersonalToUserUseCase` — troca `targetUserId`, evento forwarded user
2. `PromotePersonalToSectorUseCase` — `personalActive=false`, `currentSectorId=target`, notifica setor
3. TDD CT-CP-009..012

### Phase D — Linked pessoal + auditoria (P2 US6–US7)

1. `CreatePersonalLinkedDemandaUseCase` — snapshot v2 existente + `originType personal`
2. `ListPersonalAuditUseCase` — role `admin_tenant`, read-only detail flag
3. TDD CT-CP-013..016

### Phase E — Notificações (P1/P2)

1. Tipos: `tramitacao_pessoal_nova`, `tramitacao_pessoal_resposta`, `tramitacao_pessoal_encaminhada`
2. `forPersonalParticipant(sender, target, excludeActor)` — User + AdminTenant polimórfico
3. Sem `forNovaDemanda` em fluxo pessoal ativo

### Phase F — Client UI (P1–P2)

1. Toggle Setor/Pessoal (`?inboxMode=` + sessionStorage)
2. Compose pessoal: seletor operadores (`fetchUsers` active)
3. Ações: encaminhar usuário, encaminhar setor (promover)
4. Modo auditoria admin_tenant (read-only UI)
5. Vitest CT-CP-017..020

## Risk & Mitigation

| Risco | Mitigação |
|-------|-----------|
| GET detalhe aberto hoje | Guard central `AssertPersonalDemandaAccess` + 404 opaco |
| admin_tenant sem FK User | Actor em eventos + inbox por `actorId`/`role`; targetUserId para User destinatários |
| Inbox setorial poluída | Filtro explícito `NOT (personal AND personalActive)` |
| Promoção setorial ambígua | Flag `personalActive=false` + evento `promoted_to_sector` no payload |
| Regressão linked setorial | Testes existentes tramitação + filtros originType |

## Artifacts Generated

| Artifact | Path |
|----------|------|
| Research | [research.md](./research.md) |
| Data model | [data-model.md](./data-model.md) |
| REST contract | [contracts/rest-api-tramitacao-caixa-pessoal.md](./contracts/rest-api-tramitacao-caixa-pessoal.md) |
| UI contract | [contracts/client-tramitacao-caixa-pessoal-ui.md](./contracts/client-tramitacao-caixa-pessoal-ui.md) |
| Test strategy | [contracts/test-strategy.md](./contracts/test-strategy.md) |
| Quickstart | [quickstart.md](./quickstart.md) |
