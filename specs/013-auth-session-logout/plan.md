# Implementation Plan: Sessão inválida sem logout e tratamento de erros

**Branch**: `013-auth-session-logout` | **Date**: 2026-06-24 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/013-auth-session-logout/spec.md`

## Summary

Corrigir bug de sessão no app tenant (`@ci/web`) e resiliência do backend tenant: quando token expira, credencial é rejeitada (401) ou comunicação falha, o client MUST deslogar, redirecionar ao login com mensagem e preservar rota de origem. Paralelamente, mutações tenant MUST NOT derrubar a API por falha de audit log quando o ator JWT é `AdminTenant` (FK `AuditLog.userId` → `User`).

**Abordagem**:

1. **API** — `AuditService` resolve `userId` apenas se existir em `User`; grava `actorId`/`actorRole` no `payload` JSON; interceptor envolve audit em `try/catch` + log Pino (fire-and-forget).
2. **Shared** — estender `createApiClient` com `registerSessionLostHandler`, detecção 401 + erros de rede, guard anti-loop para requisições paralelas.
3. **Web** — `AuthProvider` registra handler (logout + `navigate('/login', { state: { from, sessionMessage } })`); `isAuthenticated` coerente; `ToastProvider` transversal; `useApiAction` para páginas; `LoginPage` exibe mensagem de sessão encerrada.

## Technical Context

**Language/Version**: TypeScript 5.x / 6.x; Node.js 20 LTS

**Primary Dependencies**:

| Pacote | Stack |
|--------|-------|
| **ci-api-v2** | NestJS 11, Fastify, Pino, Zod, Prisma 7, PostgreSQL, Passport JWT |
| **ci-client-v2** | React 19, Vite 8, Tailwind v4, shadcn/ui (`@ci/ui`), react-router-dom 7, Vitest 3, MSW 2 |
| **packages/shared** | `createApiClient` — estendido nesta feature |

**Storage**: PostgreSQL — `AuditLog` (sem migration obrigatória: `userId` já nullable; metadados de ator em `payload` JSON)

**Testing**:

| Camada | API | Client |
|--------|-----|--------|
| Unitário | `audit.service.spec.ts`, `audit.interceptor.spec.ts` | `create-api-client.test.ts`, `session-errors.test.ts` |
| Integração | — | `AuthContext` + handler MSW |
| E2E | `audit-resilience.e2e-spec.ts` (Supertest) | `session-logout.e2e.test.tsx`, `LoginPage` session message |
| Contrato | fixtures audit entry | MSW 401/network scenarios |

**Target Platform**: API Linux/container; SPA browser (`@ci/web` tenant)

**Project Type**: Full-stack (API tenant + client tenant); **fora de escopo**: `@ci/admin-saas`

**Performance Goals**: Logout redirect ≤ 2s (SC-001); zero crash API em 10 mutações AdminTenant consecutivas (SC-003)

**Constraints**:

- TDD obrigatório RED → GREEN → REFACTOR (Constitution II)
- Skills: `auth-patterns`, `tdd`, `testing-conventions`, `vite-react-best-practices`
- 401 e falha de rede → logout (decisão stakeholder); 403 → **sem** logout
- Modo mock `VITE_USE_API=false` inalterado
- Zod only na API; tenant AsyncLocalStorage

**Scale/Scope**: ~8 arquivos API (audit + testes), ~12 arquivos client (shared + auth + toast + hook), 0 migrations Prisma obrigatórias, refactor transversal de páginas com `reload()` sem catch

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Princípio | Status | Notas |
|-----------|--------|-------|
| I. Spec-Driven | ✅ PASS | Spec 013 + checklist validados |
| II. Test-First | ✅ PASS | [contracts/test-strategy.md](./contracts/test-strategy.md) |
| III. Stack fixa | ✅ PASS | NestJS 11 + Prisma 7 + React 19 + Vite 8 |
| IV. Multi-tenant | ✅ PASS | Audit scoped por `tenantId`; auth tenant headers |
| IV. Licenças | ✅ N/A | Auth cross-cutting; sem nova licença |
| V. Escopo mínimo | ✅ PASS | Audit fix cirúrgico; client handler centralizado + hook reutilizável |

**Post-design re-check**: Metadados de ator em `payload` JSON evitam migration Prisma imediata; hook `useApiAction` concentra tratamento transversal sem reescrever cada módulo de uma vez. ToastProvider espelha padrão admin-saas (escopo mínimo). Sem Complexity Tracking necessário.

## Project Structure

### Documentation (this feature)

```text
specs/013-auth-session-logout/
├── plan.md              # Este arquivo
├── research.md          # Decisões técnicas (Phase 0)
├── data-model.md        # Sessão client + audit entry
├── quickstart.md        # Validação manual pós-implement
├── contracts/
│   ├── client-auth-session.md
│   ├── rest-api-audit-resilience.md
│   └── test-strategy.md
└── tasks.md             # Phase 2 — /speckit-tasks
```

### Source Code (repository root)

```text
ci-api-v2/
├── src/
│   ├── common/interceptors/
│   │   └── audit.interceptor.ts          # try/catch + void safe
│   └── modules/audit/
│       ├── audit.service.ts              # resolve userId; actor in payload
│       └── audit.service.spec.ts
└── test/
    └── audit-resilience.e2e-spec.ts

ci-client-v2/
├── packages/shared/src/api/
│   ├── create-api-client.ts              # session lost handler, 401, network
│   └── create-api-client.test.ts
└── apps/web/src/
    ├── App.tsx                           # ToastProvider
    └── modules/
        ├── auth/
        │   ├── context/AuthContext.tsx     # register handler, isAuthenticated fix
        │   ├── pages/LoginPage.tsx         # sessionMessage from location.state
        │   ├── lib/session-messages.ts     # copy constants
        │   └── __tests__/session-logout.e2e.test.tsx
        └── shared/
            ├── context/ToastContext.tsx  # novo — padrão admin-saas
            └── hooks/useApiAction.ts       # wrap async + toast + no unhandled
```

**Structure Decision**: Fix API em módulo `audit/` existente; extensão `@ci/shared` beneficia futuro admin-saas mas implementação/testes focados em `@ci/web`. Páginas existentes migram gradualmente para `useApiAction` — prioridade em gabinete (repro do bug).

## Phase 0 — Research

Ver [research.md](./research.md) — 6 decisões (R1–R6), zero NEEDS CLARIFICATION.

## Phase 1 — Design & Contracts

| Artefato | Path |
|----------|------|
| Data model | [data-model.md](./data-model.md) |
| Client session contract | [contracts/client-auth-session.md](./contracts/client-auth-session.md) |
| API audit contract | [contracts/rest-api-audit-resilience.md](./contracts/rest-api-audit-resilience.md) |
| Test strategy | [contracts/test-strategy.md](./contracts/test-strategy.md) |
| Quickstart | [quickstart.md](./quickstart.md) |

## Complexity Tracking

> Nenhuma violação de constitution que exija justificativa.
