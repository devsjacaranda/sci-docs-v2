# Implementation Plan: Níveis de Acesso Ouvidoria AGEMAN (403)

**Branch**: `047-acesso-ouvidoria-ageman` | **Date**: 2026-09-16 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `civ2-docs/specs/047-acesso-ouvidoria-ageman/spec.md`

## Summary

Restringir a visibilidade de demandas internas da Ouvidoria (`emissorUserId` preenchido) ao próprio emissor por padrão, com bypass total para chefes da ouvidoria e admins, e um mecanismo de concessão explícita de acesso (por demanda específica ou por todas as demandas de um emissor) que outro usuário pode receber via UUID. Ações diretas sobre um registro específico (detalhe, edição, download de PDF/Word) retornam **403 explícito** quando não autorizadas — sem vazamento de conteúdo. A listagem apenas filtra silenciosamente. Demandas do canal público continuam sem restrição. Dashboard/Relatório/Auditoria/Pesquisa de Satisfação ficam fora de escopo. Toda a restrição (FR-001 a FR-009) fica atrás de um **feature flag por tenant** (`OuvidoriaAcessoFeatureFlag`, ligado por padrão), alterável por `admin_saas` (qualquer tenant, via app admin-saas) ou `admin_tenant` (própria instituição, via app web) — um kill-switch que, quando desligado, restaura exatamente o comportamento anterior a esta feature, sem apagar concessões já feitas.

Abordagem técnica: reaproveitar os padrões já existentes no monorepo — `assertProtocoloParticipant`/`isPersonalProtocoloParticipant` (módulo `tramitacao`), `ADMIN_BYPASS_ROLES` (módulo `tela-permissao`) e o par grant/revoke de `reset-senha` — em vez de inventar um mecanismo novo. Nova tabela Prisma `OuvidoriaAcessoConcessao` guarda as concessões; uma função pura de checagem (`assertManifestacaoAccess`) é chamada explicitamente dentro de cada use-case que opera sobre um registro específico (mesmo padrão dos asserts de tramitação — não é um `CanActivate` de NestJS, porque a decisão depende de dados do próprio registro já carregado).

## Technical Context

**Language/Version**: TypeScript 5.9+ (Node.js 22 LTS) — API e Client

**Primary Dependencies**:
- API (`ci-api-v2`): NestJS 11, Fastify, Pino, Zod v4 (`nestjs-zod`), Prisma 7, PostgreSQL
- Client (`ci-client-v2`, `apps/web`): React 19, Vite 8, Tailwind v4, `@ci/ui` (shadcn/ui), React Router

**Storage**: PostgreSQL via Prisma — novas tabelas `OuvidoriaAcessoConcessao` e `OuvidoriaAcessoFeatureFlag` (1 linha por tenant, ausência de linha = ligado); nenhuma migração de dados históricos (checagem em tempo de leitura, conforme FR-011 e FR-018)

**Testing**: Jest (unit + e2e) em `ci-api-v2` — TDD obrigatório (RED → GREEN → REFACTOR); Vitest em `ci-client-v2/apps/web` para mappers/lib puro

**Target Platform**: Web (SPA multi-tenant), API REST server-side (Linux container)

**Project Type**: Web application (backend `ci-api-v2` + frontend `ci-client-v2/apps/web`) — feature full-stack dentro do módulo `ouvidoria` existente em ambos

**Performance Goals**: Sem meta nova de performance — checagem de acesso é O(1) a O(n pequeno) por request (poucas concessões por manifestação/emissor), sem N+1 (concessões carregadas em lote por lista, não por item)

**Constraints**:
- Nenhum dado de conteúdo pode vazar em resposta 403 (FR-007) — o assert deve ocorrer **antes** de montar o DTO de resposta
- Checagem de "chefe da ouvidoria" e `setorIds`/`chiefOfSetorIds` vem do JWT (mesma semântica de staleness já aceita no resto da plataforma para `setorIds` — não é recalculado em tempo real a cada request; atualiza no próximo login/refresh de token). Documentado como decisão aceita em `research.md`, não como gap novo.
- Zero migração de dados históricos
- Diferente do JWT, o estado do feature flag NUNCA é lido do token — é lido do banco a cada request relevante, para que ligar/desligar tenha efeito imediato (SC-009/SC-010) sem exigir novo login

**Scale/Scope**: Módulo `ouvidoria` já existente (não é módulo novo); afeta ~10 endpoints diretos sobre registro específico + listagem + 3 endpoints novos (grant/revoke/listar acessos)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Princípio | Avaliação |
|---|---|
| I. Spec-Driven Development | ✅ Spec 047 aprovada, plan segue o fluxo Spec Kit |
| II. Test-First (NON-NEGOTIABLE) | ✅ Cada use-case novo/alterado (`assertManifestacaoAccess`, grant/revoke, filtro de listagem) ganha teste RED→GREEN antes da implementação — skills `tdd` + `testing-conventions` aplicadas em `/speckit-implement` |
| III. Stack fixa | ✅ Zod v4 (`nestjs-zod`) na API, nenhuma lib nova no client — reaproveita `@ci/ui` (shadcn) já instalado |
| IV. Multi-tenant e licenças | ✅ `OuvidoriaAcessoConcessao` e `OuvidoriaAcessoFeatureFlag` carregam `tenantId`; rotas self-service (`/ouvidoria/acesso-flag`, grant/revoke/list) sempre via `getRequestContext().tenantId!`, nunca por parâmetro de rota. Exceção documentada: a rota `admin_saas` (`/admin/tenants/:tenantId/feature-flags/ouvidoria-acesso`) recebe `tenantId` por parâmetro — mesmo padrão já aceito em `toggle-tenant-licenca.use-case.ts`, pois `admin_saas` opera cross-tenant por definição. Soft delete não se aplica a `OuvidoriaAcessoConcessao` (revogação é campo `revokedAt`); `OuvidoriaAcessoFeatureFlag` nunca é deletado, só atualizado (`upsert`) |
| V. Clean code e modularidade | ✅ 1 arquivo = 1 operação: `grant-ouvidoria-acesso.use-case.ts`, `revoke-ouvidoria-acesso.use-case.ts`, `list-ouvidoria-acessos.use-case.ts` separados; lib pura `assert-manifestacao-access.ts` sem I/O direto (recebe dados já carregados) |

**Skills aplicadas nesta fase** (canon + anexadas pelo usuário nesta mensagem):
- `ci-api-arquitetura`, `prisma-schema-workflow`, `auth-patterns`, `nestjs-module-scaffold` — estrutura do módulo e schema novo
- `owasp-security` (anexada) — A01 Broken Access Control: deny-by-default, checagem 100% server-side, sem IDOR, sem vazamento de conteúdo em 403, log de decisões de concessão/revogação (A09)
- `zod-validation-sanitization` (anexada) — schema `z.discriminatedUnion` para o body de concessão (escopo `manifestacao` vs `emissor`), `z.uuid()` nos identificadores
- `typescript-mastery` (anexada) — discriminated union para `AccessDecision`/escopo de concessão, tipos derivados de `z.infer`
- `shadcn` + `ui-ux-pro-max` (anexadas) — componentes do card "Quem tem acesso" e diálogo de concessão no client (`Card`, `Badge`, `Dialog`, `Command`/`Combobox`, `AlertDialog` para revogação — ver `research.md` §6 e `quickstart.md`)
- `js-ts-data-transforms` — mapear a resposta de `GET /ouvidoria/manifestacoes/:id/acessos` para o ViewModel do card
- `auth-patterns` (aplicada ao flag) — guard por role em duas superfícies distintas (`admin_tenant` self-service via `getRequestContext().tenantId!` vs. `admin_saas` cross-tenant via parâmetro de rota, espelhando `toggle-tenant-licenca`)

**Resultado**: PASS, sem violações a justificar em Complexity Tracking.

## Project Structure

### Documentation (this feature)

```text
civ2-docs/specs/047-acesso-ouvidoria-ageman/
├── plan.md              # este arquivo
├── research.md          # Phase 0
├── data-model.md         # Phase 1
├── quickstart.md        # Phase 1
├── contracts/           # Phase 1
│   ├── ouvidoria-acessos.md
│   └── ouvidoria-visibilidade-listagem-e-403.md
└── tasks.md             # Phase 2 (/speckit-tasks — não criado aqui)
```

### Source Code (repository root)

```text
ci-api-v2/
├── prisma/schema/
│   ├── ouvidoria-acesso.prisma          # NOVO: model OuvidoriaAcessoConcessao + enum OuvidoriaAcessoScope
│   └── ouvidoria-acesso-flag.prisma     # NOVO: model OuvidoriaAcessoFeatureFlag (FR-014 a FR-020)
├── src/modules/ouvidoria/
│   ├── ouvidoria.controller.ts          # + 3 rotas de acessos + GET/PATCH /ouvidoria/acesso-flag (self-service admin_tenant)
│   ├── ouvidoria.schemas.ts             # + createOuvidoriaAcessoBodySchema + setOuvidoriaAcessoFlagBodySchema
│   ├── ouvidoria.mapper.ts              # + mapAcessoConcessao → ViewModel "quem tem acesso"
│   ├── lib/
│   │   ├── assert-manifestacao-access.ts        # NOVO — núcleo da decisão de acesso (pura, testável); 1º passo = checa flag
│   │   ├── assert-manifestacao-access.spec.ts   # NOVO
│   │   ├── is-chefe-da-ouvidoria.ts              # NOVO — deriva chefe via chiefOfSetorIds ∩ setores do módulo ouvidoria
│   │   └── get-ouvidoria-acesso-flag.ts          # NOVO — lê OuvidoriaAcessoFeatureFlag (ausência = enabled=true)
│   ├── repository/
│   │   ├── ouvidoria-acesso.repositories.ts     # NOVO — Create/Revoke/FindActiveForGrantee/FindActiveForManifestacao
│   │   └── ouvidoria-acesso-flag.repository.ts  # NOVO — Find/Upsert por tenantId
│   └── use-cases/
│       ├── grant-ouvidoria-acesso.use-case.ts    # NOVO — FR-004/FR-005
│       ├── revoke-ouvidoria-acesso.use-case.ts   # NOVO — FR-006
│       ├── list-ouvidoria-acessos.use-case.ts    # NOVO — FR-009 ("quem tem acesso")
│       ├── set-ouvidoria-acesso-flag.use-case.ts # NOVO — FR-017/FR-020; exportado p/ AdminPlataformaModule
│       ├── get-manifestacao-detail.use-case.ts   # ALTERADO — chama assertManifestacaoAccess
│       ├── update-manifestacao-draft.use-case.ts # ALTERADO — idem
│       ├── generate-manifestacao-docx.use-case.ts# ALTERADO — idem
│       ├── generate-manifestacao-pdf.use-case.ts # ALTERADO — idem
│       ├── encaminhar-manifestacao.use-case.ts   # ALTERADO — idem (extensão por padrão, ver spec Assumptions)
│       ├── responder-manifestacao.use-case.ts    # ALTERADO — idem
│       ├── encerrar-manifestacao.use-case.ts     # ALTERADO — idem
│       ├── delete-manifestacao.use-case.ts       # ALTERADO — idem
│       └── list-manifestacoes.use-case.ts        # ALTERADO — filtro de visibilidade (FR-008), curto-circuita se flag desligado
└── src/modules/admin-plataforma/
    ├── admin-plataforma.controller.ts    # + PATCH tenants/:tenantId/feature-flags/ouvidoria-acesso (admin_saas)
    ├── admin-plataforma.module.ts        # importa SetOuvidoriaAcessoFlagUseCase do OuvidoriaModule
    └── use-cases/get-tenant-detail.use-case.ts # ALTERADO — inclui estado do flag na resposta

ci-client-v2/apps/web/src/modules/ouvidoria/
├── api/
│   ├── acessos.ts                        # NOVO — grantAcesso/revokeAcesso/listAcessos + schema Zod v3 de resposta
│   ├── acesso-flag.ts                     # NOVO — getAcessoFlag/setAcessoFlag (self-service admin_tenant)
│   └── errors.ts                          # ALTERADO — + CODE_SPECS.OUVIDORIA_ACCESS_DENIED
├── components/
│   ├── ManifestacaoAcessoCard.tsx          # NOVO — "Quem tem acesso" + botão conceder
│   ├── ManifestacaoAcessoGrantDialog.tsx   # NOVO — Dialog + Command (busca usuário) + ToggleGroup (escopo)
│   └── ManifestacaoAcessoRevokeButton.tsx  # NOVO — AlertDialog de confirmação
├── lib/
│   └── manifestacao-detail-view.ts         # ALTERADO — + campo `acesso` no ViewModel
└── pages/
    └── ManifestacaoDetailPage.tsx           # ALTERADO — renderiza ManifestacaoAcessoCard

ci-client-v2/apps/web/src/modules/tenant/
└── components/PlatformTenantConfigPanel.tsx  # ALTERADO — + toggle do flag (admin_tenant, self-service)

ci-client-v2/apps/admin-saas/src/modules/admin-plataforma/
├── api/tenants.ts                           # ALTERADO — + toggleOuvidoriaAcessoFlag + campo no TenantDetailDto
└── pages/TenantDetailPage.tsx               # ALTERADO — + seção "Recursos" com o toggle (mesmo padrão de LicencaToggle)
```

**Structure Decision**: Web application com dois pacotes já existentes (`ci-api-v2` + `ci-client-v2/apps/web`), módulo `ouvidoria` em ambos (espelho de domínio, conforme constitution §V). Nenhum pacote novo, nenhuma dependência nova. Todo o trabalho é incremental dentro do módulo `ouvidoria` já existente, seguindo o padrão vivo de `modules/ouvidoria/` + `modules/tramitacao/` (referência de acesso pessoal/setorial) + `modules/reset-senha/` (referência de grant/revoke) + `modules/tela-permissao/` (`ADMIN_BYPASS_ROLES`). O feature flag por tenant (FR-014 a FR-020) toca também `ci-client-v2/apps/admin-saas` (app existente, sem pacote novo) e `src/modules/admin-plataforma/` na API — reaproveitando exatamente o padrão já vivo de `TenantLicenca`/`toggle-tenant-licenca.use-case.ts` para o toggle de `admin_saas`, com o caso de uso de escrita centralizado no módulo `ouvidoria` e importado pelo `AdminPlataformaModule` (mesma direção de dependência de módulo-para-módulo já usada no projeto, sem import circular).

## Complexity Tracking

*Sem violações da constitution a justificar — tabela omitida.*
