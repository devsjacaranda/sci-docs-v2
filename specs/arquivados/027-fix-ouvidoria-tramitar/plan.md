# Implementation Plan: Corrigir tramitação de manifestações na Ouvidoria

**Branch**: `027-fix-ouvidoria-tramitar` | **Date**: 2026-07-01 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/027-fix-ouvidoria-tramitar/spec.md`

## Summary

Corrigir bug em que **Tramitar manifestação** falha com `400 "Setor ativo não definido"` para usuários sem `setorIds` no JWT (principalmente **admin_tenant**), apesar de setor destino preenchido no modal.

**Causa**: `ouvidoria.controller.ts` valida apenas `req.user.setorIds?.[0]` antes de chamar o use case — diverge do módulo Tramitação que usa `ResolveTramitacaoSectorUseCase` com fallbacks (DB, chefe, setor de módulo, primeiro setor tenant).

**Abordagem**: Exportar e estender `ResolveTramitacaoSectorUseCase` com `preferredModuloSlug: ouvidoria`; substituir check manual no controller; TDD unit + integration; **sem migration** e **sem alteração obrigatória no client**.

## Technical Context

**Language/Version**: TypeScript 5.x / 6.x; Node.js 20 LTS

**Primary Dependencies**:

| Pacote | Stack |
|--------|-------|
| **ci-api-v2** | NestJS 11, Fastify, Pino, Zod, Prisma 7, PostgreSQL |
| **ci-client-v2** | React 19, Vite 8, Tailwind v4, shadcn/ui (smoke only) |

**Storage**: PostgreSQL — entidades existentes (`Manifestacao`, `Setor`, `ModuloSetor`, `UserSetor`, `TramitacaoDemanda`); **sem schema change**

**Testing**: Jest unit + integration (`ci-api-v2`); smoke manual client — [test-strategy.md](./contracts/test-strategy.md)

**Target Platform**: API Linux/container; SPA browser (`@ci/web`)

**Project Type**: Bugfix full-stack (correção API; client validação regressiva)

**Performance Goals**: Resolução de setor < 50ms p95 (2–3 queries Prisma); encaminhar total < 500ms p95 (inalterado)

**Constraints**:

- TDD obrigatório RED → GREEN → REFACTOR
- Zod only — sem class-validator
- Tenant AsyncLocalStorage — nunca passar `tenantId` manual
- Escopo mínimo: rota `encaminhar` + resolver compartilhado; **não** alterar jurídico controller nesta feature (mesmo padrão, issue separada)
- Sem mudança de contrato body/response 200
- Copy PT-BR acionável para `ACTIVE_SECTOR_UNDEFINED`

**Scale/Scope**: 3 arquivos API alterados, 1 spec novo, 1 integration spec estendido; 0 migrations; 0 páginas client novas

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Princípio | Status | Notas |
|-----------|--------|-------|
| I. Spec-Driven | ✅ PASS | Spec 027 + checklist validados |
| II. Test-First | ✅ PASS | test-strategy CT-OT-001..010 |
| III. Stack fixa | ✅ PASS | NestJS 11 + Prisma 7; sem desvio |
| IV. Multi-tenant | ✅ PASS | Fallback usa `getRequestContext().tenantId` |
| IV. Licenças | ✅ PASS | Ouvidoria Base; sem alteração licença |
| V. Escopo mínimo | ✅ PASS | Reuso use case Tramitação; 3 arquivos API |

**Post-design re-check**: Extensão de `ResolveTramitacaoSectorUseCase` com parâmetro opcional preserva compatibilidade Tramitação (default `tramitacao`). Export adicional em `TramitacaoModule` — acoplamento já existente via `CreateLinkedDemandaUseCase`. Sem Complexity Tracking necessário.

## Project Structure

### Documentation (this feature)

```text
civ2-docs/specs/027-fix-ouvidoria-tramitar/
├── plan.md              # This file
├── research.md          # Phase 0
├── data-model.md        # Phase 1
├── quickstart.md        # Phase 1
├── contracts/
│   ├── rest-api-ouvidoria-encaminhar-fix.md
│   └── test-strategy.md
└── tasks.md             # Phase 2 — /speckit-tasks
```

### Source Code (repository root)

```text
ci-api-v2/
├── src/modules/tramitacao/
│   ├── tramitacao.module.ts                          # export ResolveTramitacaoSectorUseCase
│   └── use-cases/
│       ├── resolve-tramitacao-sector.use-case.ts     # + preferredModuloSlug, priorização
│       └── resolve-tramitacao-sector.use-case.spec.ts  # NEW
├── src/modules/ouvidoria/
│   ├── ouvidoria.controller.ts                       # usar resolveSector.execute
│   └── test/use-cases/
│       └── encaminhar-manifestacao-tramitacao.integration.spec.ts  # regressão
└── test/ ou src/modules/ouvidoria/
    └── ouvidoria.controller.spec.ts                  # NEW ou estender — CT-OT-008/009

ci-client-v2/
└── apps/web/src/modules/ouvidoria/
    └── components/ForwardManifestacaoDialog.tsx      # smoke only — sem diff obrigatório
```

**Structure Decision**: Bugfix contido em `ci-api-v2` reutilizando infra Tramitação já importada por `OuvidoriaModule`. Client espelha módulo ouvidoria existente; validação manual via quickstart.

## Phase 0: Research Summary

Ver [research.md](./research.md). Decisões-chave:

| ID | Decisão |
|----|---------|
| R1 | Bug no controller (check JWT), não no use case encaminhar |
| R2 | Reutilizar + estender `ResolveTramitacaoSectorUseCase` |
| R3 | Client sem alteração obrigatória |
| R4 | TDD resolver + controller integration |
| R5 | Enriquecer copy `ACTIVE_SECTOR_UNDEFINED` |

## Phase 1: Design Summary

### Data model

Ver [data-model.md](./data-model.md). Sem migration; documenta resolução de setor origem e transições de status.

### Contracts

| Artefato | Conteúdo |
|----------|----------|
| [rest-api-ouvidoria-encaminhar-fix.md](./contracts/rest-api-ouvidoria-encaminhar-fix.md) | Delta contrato POST encaminhar |
| [test-strategy.md](./contracts/test-strategy.md) | Matriz CT-OT + ordem TDD |

### Implementation steps (para `/speckit-tasks`)

1. **RED** — `resolve-tramitacao-sector.use-case.spec.ts`: CT-OT-001..006
2. **GREEN** — estender use case + export `TramitacaoModule`
3. **RED** — controller spec: admin_tenant encaminhar → 200 (CT-OT-008/009)
4. **GREEN** — `ouvidoria.controller.ts`: injetar resolver, remover check manual
5. **REFACTOR** — copy erro FR-008; confirmar CT-OT-007 regressão
6. **Smoke** — quickstart VS-027-001 com admin@jacaranda.com

### Wiring detalhado

```typescript
// ouvidoria.controller.ts (pós-fix)
@Post('manifestacoes/:id/encaminhar')
async encaminharRoute(...) {
  const authorSectorId = await this.resolveSector.execute(
    req.user,
    undefined,
    ModuloSlug.ouvidoria,
  );
  return this.encaminhar.execute(id, req.user.userId, body, authorSectorId);
}
```

```typescript
// tramitacao.module.ts
exports: [CreateLinkedDemandaUseCase, ResolveTramitacaoSectorUseCase],
```

## Complexity Tracking

> Não aplicável — nenhuma violação de constitution.

## Artifacts Generated

| File | Status |
|------|--------|
| `plan.md` | ✅ |
| `research.md` | ✅ |
| `data-model.md` | ✅ |
| `quickstart.md` | ✅ |
| `contracts/rest-api-ouvidoria-encaminhar-fix.md` | ✅ |
| `contracts/test-strategy.md` | ✅ |
| `tasks.md` | ⏳ `/speckit-tasks` |
