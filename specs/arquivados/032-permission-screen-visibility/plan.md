# Implementation Plan: Sistema de Permissão de Telas e De-mock Navegação

**Branch**: `032-permission-screen-visibility` | **Date**: 2026-07-02 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `civ2-docs/specs/032-permission-screen-visibility/spec.md`

## Summary

Persistir permissão de telas granular por setor (`SetorTela`) e por usuário (`UserTelaOverride`, grant/deny), expor um catálogo de telas via `GET /screens`, calcular visibilidade efetiva (`GET /me/screens`), completar o CRUD de vínculo de membros do setor, e substituir toda a camada mock do painel "Telas e agrupamentos" e do `SectorMembersPanel` por chamadas reais à API — seguindo exatamente os padrões já em uso nos módulos `permissao` e `setor` (Nest + Prisma + Zod, use-case/repository).

## Technical Context

**Language/Version**: TypeScript 5.x (API e client)

**Primary Dependencies**: NestJS 11, Fastify, Prisma 7, nestjs-zod/Zod, Pino (API) · React 19, Vite 8, Tailwind v4, shadcn/ui (client)

**Storage**: PostgreSQL via Prisma — 2 tabelas novas (`SetorTela`, `UserTelaOverride`) + 1 enum (`TelaOverrideKind`); catálogo de telas é constante TS, não persistido

**Testing**: Jest (API, `testing-conventions` skill) · Vitest (client, `js-ts-data-transforms` skill)

**Target Platform**: Web — API REST multi-tenant + SPA React

**Project Type**: Web application (backend + frontend monorepo)

**Performance Goals**: `GET /me/screens` deve resolver em < 200ms (catálogo pequeno em memória + 1-2 queries indexadas)

**Constraints**: Multi-tenant via `X-Tenant-ID`/AsyncLocalStorage (nunca `tenantId` manual); FK para `User` deve ser nullable onde o ator pode ser `admin_tenant` (regra `admin-tenant-user-fk`); zero downtime — telas não configuradas devem cair em baseline, nunca 403 silencioso

**Scale/Scope**: ~80-100 telas no catálogo; 5-10 setores por tenant; overrides esperados como exceção rara (não a maioria dos usuários)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-checked after Phase 1 design.*

| Princípio | Verificação | Status |
|-----------|-------------|--------|
| I. Spec-Driven Development | Spec (`spec.md`) → Plan (este arquivo) → Tasks → Implement, na ordem | PASS |
| II. Test-First | Todo use-case/repository novo terá spec antes da implementação (RED→GREEN→REFACTOR) — enforced em `/speckit-implement` via skill `tdd`/`testing-conventions` | PASS (a verificar na implementação) |
| III. Stack fixa | Zod em `*.schemas.ts` (nunca class-validator); Prisma para persistência; React/Vite/Tailwind/shadcn no client — nenhum desvio | PASS |
| IV. Multi-tenant e licenças | `SetorTela`/`UserTelaOverride` levam `tenantId`; nenhuma feature nova de licença introduzida | PASS |
| V. Clean code e modularidade | Novo módulo `tela-permissao/` com `repository/`+`use-cases/` (1 arquivo = 1 operação); `SetorController` ganha rotas sem novo módulo (extensão, não duplicação); client espelha em `modules/permissao/` e `modules/setor/` existentes | PASS |

Nenhuma violação — não é necessário preencher Complexity Tracking.

## Project Structure

### Documentation (this feature)

```text
civ2-docs/specs/032-permission-screen-visibility/
├── plan.md              # este arquivo
├── research.md          # decisões técnicas (Phase 0)
├── data-model.md         # entidades, algoritmo de visibilidade (Phase 1)
├── contracts/
│   └── api-contracts.md  # contratos REST (Phase 1)
├── quickstart.md         # roteiro de validação manual (Phase 1)
└── tasks.md               # gerado por /speckit-tasks (não criado aqui)
```

### Source Code (repository root)

```text
ci-api-v2/
├── prisma/schema/
│   ├── tela-permissao.prisma          # NOVO: SetorTela, UserTelaOverride
│   ├── enums.prisma                    # + enum TelaOverrideKind
│   ├── setor.prisma                    # + relation setorTelas
│   ├── user.prisma                     # + relations telaOverrides*
│   └── tenant.prisma                   # + relations
└── src/
    ├── common/constants/
    │   └── screens.ts                  # NOVO: SCREEN_CATALOG, isScreenId(), getScreenCatalogEntry()
    └── modules/
        ├── tela-permissao/              # NOVO módulo
        │   ├── tela-permissao.module.ts
        │   ├── tela-permissao.controller.ts
        │   ├── tela-permissao.schemas.ts
        │   ├── tela-permissao.types.ts
        │   ├── repository/
        │   │   ├── find-setor-telas.repository.ts
        │   │   ├── replace-setor-telas.repository.ts
        │   │   ├── find-user-tela-overrides.repository.ts
        │   │   └── replace-user-tela-overrides.repository.ts
        │   └── use-cases/
        │       ├── list-screens.use-case.ts
        │       ├── get-setor-telas.use-case.ts
        │       ├── replace-setor-telas.use-case.ts
        │       ├── get-user-tela-overrides.use-case.ts
        │       ├── replace-user-tela-overrides.use-case.ts
        │       ├── detect-user-tela-conflicts.use-case.ts
        │       └── get-effective-screens.use-case.ts
        └── setor/                       # EXTENSÃO (existente)
            ├── setor.controller.ts       # + 3 rotas de membros
            ├── setor.module.ts           # + 2 use-cases novos
            └── use-cases/
                ├── link-user-to-setor.use-case.ts     # NOVO
                └── unlink-user-from-setor.use-case.ts # NOVO

ci-client-v2/apps/web/src/modules/
├── permissao/
│   └── api/
│       └── telas.ts                     # NOVO: fetchScreenCatalog, fetchSetorTelas, replaceSetorTelas,
│                                         #        fetchUserTelaOverrides, replaceUserTelaOverrides,
│                                         #        fetchUserTelaConflicts, fetchMeScreens
├── setor/
│   ├── api/setores.ts                    # + linkMember, unlinkMember, createMemberUser
│   └── components/
│       └── SectorMembersPanel.tsx        # de-mock: chama API real, remove sectorMembersSeed
└── shell/
    ├── lib/
    │   ├── navigation-user-access.ts      # de-mock: consome GET /me/screens
    │   └── navigation-sector-presets.ts   # de-mock: consome GET /setores/:id/telas
    ├── data/admin-mock.ts                 # reduzido: só o que ainda não tem API (se algo restar)
    └── components/mock/                   # renomeado: mock/ → permissions/ (sem prefixo Mock*)
        ├── NavigationVisibilityPanel.tsx  # → usa hooks API em vez de seeds
        ├── MockUserPicker.tsx             # → UserPicker.tsx (dados via useUsers)
        ├── MockSectorPicker.tsx           # → SectorPicker.tsx (dados via useSetores)
        └── UserSectorConflictDialog.tsx   # → consome GET /users/:id/tela-conflicts
```

**Structure Decision**: Extensão de módulos existentes (`setor/`) sempre que a operação já pertence ao domínio; módulo novo (`tela-permissao/`) apenas para o domínio genuinamente novo (catálogo + vínculos de tela). Client segue o mesmo espelhamento 1:1 API↔client já estabelecido pela constitution V, com a pasta `shell/components/mock/` perdendo o prefixo `Mock*` conforme os dados passam a ser reais (rename simples, sem mudança de responsabilidade do componente).

## Complexity Tracking

*Sem violações — tabela não aplicável.*
