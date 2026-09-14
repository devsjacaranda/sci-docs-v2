# Implementation Plan: Emissor automático ao criar demanda AGEMAN

**Branch**: `044-emissor-criador-ageman` | **Date**: 2026-09-14 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/044-emissor-criador-ageman/spec.md`

## Summary

Refatorar o preenchimento do **emissor** na criação interna de demanda/manifestação AGEMAN: o operador institucional deixa de escolher alguém numa lista — o sistema grava sempre quem está autenticado (campo somente leitura). O administrador da instituição continua vendo um seletor, já marcado em “eu mesmo”; se não trocar, o emissor fica vazio (ele não tem linha em `User`) e a identidade vai só para auditoria em `dadosAdicionais`. Depois da confirmação do rascunho o emissor não muda mais. Sem migration, sem rota nova.

**API** (`ci-api-v2`): função pura `resolveEmissorUserId` + ajuste de `CreateManifestacaoDraftUseCase` / `UpdateManifestacaoDraftUseCase` (este último passa a receber o ator). PATCH pós-`draft` ignora `emissorUserId`.

**Client** (`ci-client-v2/apps/web`): `ManifestacaoStepOneForm` + `ManifestacaoWizardPage` — modo readonly vs Combobox conforme `user.role`; sentinela `__self__` sanitizada no schema Zod do draft; `GET usuarios-emissores` só no ramo admin em rascunho.

## Technical Context

**Language/Version**: TypeScript 5.9 (strict) · Node.js 20+ LTS

**Primary Dependencies**:

| Pacote | Stack |
| --- | --- |
| **ci-api-v2** | NestJS 11, Fastify, Pino, Zod v4 (`nestjs-zod`), Prisma 7, PostgreSQL |
| **ci-client-v2/apps/web** | React 19, Vite 8, Tailwind v4, shadcn/`@ci/ui`, Zod v3 |

**Storage**: PostgreSQL existente — `Manifestacao.emissorUserId` (`String?` → `User`) e `dadosAdicionais` (Json). **0 migrations**.

**Testing**:

| Camada | API | Client |
| --- | --- | --- |
| Unitário | Jest — `resolveEmissorUserId`, use-cases, controller | Vitest — schema + RTL form/wizard |
| Contrato | `safeParse` do schema (uuid only) | `safeParse` com `__self__` → omitido |

**Target Platform**: SPA tenant (`@ci/web`) + API REST já em produção multi-tenant.

**Project Type**: Web application (frontend + backend) — refatoração pontual no módulo `ouvidoria` já existente; não cria projeto nem módulo novo.

**Performance Goals**: alinhados à spec — zero cliques extras no emissor (SC-002); fetch da lista de emissores só quando o combobox existe.

**Constraints**:

- TDD obrigatório (Constitution II) — RED nos CT-OUV-EMISSOR antes do código.
- Zod only — sem `class-validator` (Constitution III).
- Nunca gravar `admin_tenant`/`admin_saas` em FK de `User` (`admin-tenant-user-fk.mdc`, Constitution IV).
- Sobrescrita silenciosa do emissor para operador (FR-003 / OWASP A01) — sem 400.
- Portal público e demandas históricas fora de escopo.
- Paleta Mint; sem componente shadcn novo.
- `isManifestacaoEditable` (draft + `in_review` sem encaminhamento) **não** muda — só o campo emissor congela após sair de `draft`.

**Scale/Scope**: 1 fluxo (wizard interno AGEMAN/ouvidoria autenticada). ~8 arquivos API + ~6 client tocados. Sem tela nova.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Princípio | Status | Notas |
| --- | --- | --- |
| I. Spec-Driven | PASS | Spec 044 + `/speckit-clarify` (3 perguntas) + checklist 16/16 |
| II. Test-First | PASS | [contracts/test-strategy.md](./contracts/test-strategy.md) — RED em 016+ e rewrite de 007–010 |
| III. Stack fixa | PASS | Nest + Zod v4 + Prisma; React 19 + Vite 8 + Tailwind v4 + Zod v3; zero dependência nova |
| IV. Multi-tenant | PASS | `FindEmissorUserRepository` continua validando tenant quando o **admin** escolhe um User |
| IV. FK → `User` | PASS | `resolveUserTableId` + emissor `null` para admin; `withActorPayload` em `dadosAdicionais` |
| V. Clean code / modularidade | PASS | 1 arquivo = 1 operação; lib pura nova; use-cases existentes estendidos (não god-service); client no módulo `ouvidoria/` |

**Post-design re-check** (após Phase 1): sem tabela nova; sem rota de escrita nova; helper global de editabilidade intocado; detalhe já readonly. Sem violações — Complexity Tracking vazio.

## Project Structure

### Documentation (this feature)

```text
civ2-docs/specs/044-emissor-criador-ageman/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   ├── rest-api-emissor.md
│   ├── client-emissor-ui.md
│   └── test-strategy.md
└── tasks.md              # Phase 2 — /speckit-tasks (ainda não criado)
```

### Source Code (repository root)

```text
ci-api-v2/src/
├── common/lib/resolve-user-table-id.ts          # reaproveitado (não alterar contrato)
└── modules/ouvidoria/
    ├── lib/resolve-emissor-user-id.ts           # NOVO — regra pura
    ├── lib/resolve-emissor-user-id.spec.ts      # NOVO — CT-OUV-EMISSOR-016
    ├── lib/build-manifestacao-update.ts         # inalterado (chamador omite emissor se confirmed)
    ├── ouvidoria.schemas.ts                     # sem sentinela de UI
    ├── ouvidoria.controller.ts                  # PATCH passa actor
    ├── ouvidoria.controller.spec.ts             # CT-OUV-EMISSOR-019
    ├── repository/manifestacao.repositories.ts  # create: aceitar emissor já resolvido; merge dadosAdicionais
    └── use-cases/
        ├── create-manifestacao-draft.use-case.ts
        └── update-manifestacao-draft.use-case.ts

ci-client-v2/apps/web/src/modules/ouvidoria/
├── schemas/manifestacao-draft.schema.ts         # uuid | '' | __self__ → omit
├── components/ManifestacaoStepOneForm.tsx       # readonly vs Combobox
├── pages/ManifestacaoWizardPage.tsx             # fetch emissores condicional; omit body
└── __tests__/
    ├── ManifestacaoStepOneForm.validation.test.tsx
    └── ManifestacaoWizardPage.emissor.test.tsx
```

**Structure Decision**: monorepo atual — só o módulo `ouvidoria` (API + `apps/web`). Sem `apps/publico`, sem `@ci/ui` novo.

## Complexity Tracking

> Nenhuma violação de constitution a justificar.
