# CI v2 Constitution

## Core Principles

### I. Spec-Driven Development (CANÔNICO)

Toda feature nova segue o fluxo [GitHub Spec Kit](https://github.com/github/spec-kit):

1. `/speckit-constitution` — princípios (este arquivo)
2. `/speckit-specify` — o quê e por quê (sem stack)
3. `/speckit-plan` — stack e arquitetura
4. `/speckit-tasks` — tarefas acionáveis
5. `/speckit-implement` — execução com TDD
6. `/speckit-complete` — arquivar: STATUS.md + mover para `specs/arquivados/`

**Ativas:** `civ2-docs/specs/<feature>/` · **Arquivadas:** `civ2-docs/specs/arquivados/<feature>/` · Índice: [specs/README.md](../specs/README.md). Infra: `civ2-docs/.specify/`. Skills: [spec-kit/SKILLS.md](../spec-kit/SKILLS.md).

### II. Test-First (NON-NEGOTIABLE)

TDD obrigatório: RED → GREEN → REFACTOR. Nenhum código de produção sem teste correspondente. Skills: `tdd`, `test-driven-development`, `testing-conventions`.

### III. Stack fixa (sem desvio)

| Pacote | Stack |
|--------|-------|
| **ci-api-v2** | NestJS 11, Fastify, Pino, Zod (nestjs-zod), Prisma 7, PostgreSQL |
| **ci-client-v2** | React 19, Vite 8, Tailwind v4, shadcn/ui, Nivo |

**NUNCA** class-validator na API — só Zod em `*.schemas.ts`.

Monorepo Turborepo em **ci-client-v2** (`apps/web` + `packages/*`) — **adotado**; ci-api-v2 permanece pacote independente na raiz do repo.

### IV. Multi-tenant e licenças

- Tenant via `X-Tenant-ID` + AsyncLocalStorage — nunca passar `tenantId` manualmente nos services
- Soft delete transparente via Prisma extensions
- Licenças: Carvalho, Pau-Brasil, Jatobá, Cedro — ver `.cursor/docs/licencas-canonicas.md`
- Produto/UI: `.cursor/docs/regras-plataforma.md`

### V. Clean code e modularidade

- API: pastas modulares por domínio — camadas **repository** (persistência), **use-cases** (negócio), **services** (opcional, externo)
- 1 arquivo = 1 operação em repository e use-cases; 1 controller e 1 schemas por módulo
- Constructor injection; escopo mínimo por PR/feature
- Módulos legados migram incrementalmente; referência: `ci-api-v2/src/modules/permissao/`
- Client: pastas modulares por domínio em `apps/web/src/modules/<slug>/` — espelho de `ci-api-v2/src/modules/`
- Camadas frontend: `pages/`, `components/`, `api/` (mínimo); `hooks/`, `lib/`, `context/` quando aplicável
- Infra SPA: `modules/shell/`; reuso cross-domain: `modules/shared/`; UI genérica: `@ci/ui`; tipos licença: `@ci/domain`
- Referência viva: `modules/ouvidoria/` + `modules/permissao/`; composition root: `modules/shell/pages/ScreenPage.tsx`

## Hierarquia de documentação

1. `civ2-docs/.specify/memory/constitution.md` — processo e princípios
2. `civ2-docs/specs/<feature>/` — specs **ativas** (Spec Kit)
3. `civ2-docs/specs/arquivados/<feature>/` — specs **concluídas** (`/speckit-complete`)
4. `.cursor/docs/licencas-canonicas.md` — produto (licenças)
5. `.cursor/docs/regras-plataforma.md` — copy e UI
6. `ci-api-v2/CONTEXT.md` — vocabulário backend
7. [spec-kit/SKILLS.md](../spec-kit/SKILLS.md) — **quando usar cada skill** (índice canônico)
8. Skills em `.cursor/skills/` — execução por domínio (ler `SKILL.md` antes de implementar)

## Repositórios do monorepo

```
ci-v2/
├── civ2-docs/     # Spec Kit + specs + índice de skills
│   ├── .specify/  # templates, scripts, constitution
│   ├── specs/     # features ativas (/speckit-specify)
│   │   └── arquivados/  # concluídas (/speckit-complete)
│   └── spec-kit/  # SKILLS.md
├── ci-api-v2/     # REST API Nest + Prisma + PostgreSQL
└── ci-client-v2/  # frontend monorepo Turborepo
```

## Governance

- Constitution supersede práticas ad hoc
- Conflito stack vs spec: constitution vence
- Amendments: atualizar este arquivo + rodar sync de templates se necessário

**Version**: 1.2.0 | **Ratified**: 2026-06-05 | **Last Amended**: 2026-06-25
