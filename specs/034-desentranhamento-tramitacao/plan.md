# Implementation Plan: Desentranhamento de Documentos em Tramitação

**Branch**: `034-desentranhamento-tramitacao` | **Date**: 2026-07-07 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `civ2-docs/specs/034-desentranhamento-tramitacao/spec.md`

## Summary

Implementar, dentro do módulo já existente `tramitacao` (`ci-api-v2/src/modules/tramitacao/`), um fluxo de solicitação/aprovação bidirecional para marcar um anexo (`TramitacaoDemandaAnexo`) como **desentranhado**: o autor do documento ou a contraparte da tramitação pode solicitar; quem decide é sempre "o outro lado" (contraparte se o autor solicitou; autor se a contraparte solicitou). Aprovação marca o anexo com `desentranhadoAt`, removendo-o das listagens normais mas preservando-o em uma visão de histórico, visível apenas a quem já tinha acesso original (autor, ACL confidencial, `admin_tenant`/`admin_saas`). Abordagem técnica: nova entidade Prisma `TramitacaoDemandaAnexoDesentranhamento` (workflow com estado consultável, distinto de eventos append-only), três novos tipos de evento de timeline, três novos tipos de notificação in-app, extensão da função de controle de acesso já usada para confidencialidade, e reaproveitamento do serviço já existente de resolução de destinatários (`ResolveTramitacaoRecipientsService`) para determinar aprovadores. Sem novas páginas no frontend — UI inline nos componentes de anexo já existentes.

## Technical Context

**Language/Version**: TypeScript (Node.js LTS) — backend e frontend

**Primary Dependencies**: NestJS 11 + Fastify + Pino (API); Prisma 7 + PostgreSQL (persistência); Zod + `nestjs-zod` (validação, via `createZodDto`); Socket.IO (`NotificacaoGateway`, já existente); React 19 + Vite 8 + Tailwind v4 + shadcn/ui (client)

**Storage**: PostgreSQL via Prisma — mesmo banco/schema de `ci-api-v2/prisma/schema/tramitacao.prisma` e `notificacao.prisma`

**Testing**: Jest — testes de integração mockados (`*.integration.spec.ts`, sem DB real), seguindo padrão de `ci-api-v2/src/modules/tramitacao/test/`; Vitest para componentes/hooks do client (`ci-client-v2/apps/web/src/modules/tramitacao/**/__tests__/`)

**Target Platform**: Web — API REST (Fastify) consumida por SPA (React)

**Project Type**: Web application (monorepo já existente: `ci-api-v2` backend + `ci-client-v2` frontend, ambos com módulo `tramitacao` espelhado)

**Performance Goals**: Sem requisito de performance diferenciado — mesma expectativa dos demais endpoints de tramitação (resposta em latência de API padrão do projeto, sem lote/alto volume). Notificação in-app deve refletir em segundos (já garantido pelo `DispatchNotificacaoService` + WebSocket existentes).

**Constraints**:
- Multi-tenant: `tenantId` sempre via `AsyncLocalStorage` (`getRequestContext()`), nunca passado manualmente entre camadas.
- FK para `User` deve ser nullable e resolvida via `resolveUserTableId`/`withActorPayload` (actor pode ser `admin_tenant`/`admin_saas`, sem linha em `User`) — regra `admin-tenant-user-fk`.
- Não pode reduzir nem ampliar as regras de acesso confidencial já existentes (feature 033) — apenas compor uma condição adicional.
- Ação é não-destrutiva: nenhum conteúdo de anexo pode ser apagado por este fluxo.
- Concorrência: duas decisões simultâneas sobre o mesmo pedido devem resultar em exatamente uma vencedora (FR-009), garantido a nível de banco.

**Scale/Scope**: Extensão de um módulo já maduro (~17 use-cases, 5 repositórios). Escopo desta feature: +1 model Prisma, +2 enums, +3 valores em enum existente (`TramitacaoDemandaEventType`), +3 valores em `NotificacaoType`, +1 campo em `TramitacaoDemandaAnexo`, ~5 novos use-cases, 1 novo repository file, extensão de 2 arquivos `lib/` existentes, 3 novas rotas no controller existente, extensão do mapper, e ajustes pontuais em 2-3 componentes React já existentes (sem novas páginas).

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Princípio | Avaliação |
|---|---|
| I. Spec-Driven Development | ✅ Spec (`spec.md`) já criada e validada via `/speckit-specify` antes deste plano. |
| II. Test-First (NON-NEGOTIABLE) | ✅ Nenhuma implementação prevista sem teste correspondente; `/speckit-tasks` deve gerar tarefas em ordem RED → GREEN → REFACTOR, seguindo `tdd` + `testing-conventions`. |
| III. Stack fixa | ✅ NestJS/Fastify/Zod/Prisma/PostgreSQL no backend; React/Vite/Tailwind/shadcn no client. Nenhuma dependência nova introduzida. `nestjs-zod` (não class-validator) para os novos DTOs. |
| IV. Multi-tenant e licenças | ✅ Reaproveita `tenantId` via `AsyncLocalStorage` já injetado pelo Prisma; FKs para `User` nullable conforme `admin-tenant-user-fk`; módulo `tramitacao` já está em `OPEN_MODULES`, sem necessidade de nova regra de licença. |
| V. Clean code e modularidade | ✅ Segue padrão `repository/` (persistência) + `use-cases/` (negócio) + `lib/` (helpers puros) já usado no módulo; 1 arquivo = 1 operação (um use-case por ação: solicitar, aprovar, rejeitar). |

**Resultado**: Nenhuma violação. Nenhum item necessário em Complexity Tracking.

## Project Structure

### Documentation (this feature)

```text
civ2-docs/specs/034-desentranhamento-tramitacao/
├── spec.md                          # Especificação funcional (/speckit-specify)
├── plan.md                          # Este arquivo (/speckit-plan)
├── research.md                      # Decisões técnicas (Phase 0)
├── data-model.md                    # Modelo de dados (Phase 1)
├── quickstart.md                    # Roteiro de validação ponta a ponta (Phase 1)
├── contracts/
│   └── desentranhamento-api.md      # Contrato REST (Phase 1)
├── checklists/
│   └── requirements.md              # Checklist de qualidade da spec
└── tasks.md                         # Tarefas acionáveis (/speckit-tasks — não criado por este comando)
```

### Source Code (repository root)

```text
ci-api-v2/
├── prisma/
│   ├── schema/
│   │   ├── tramitacao.prisma        # + campo desentranhadoAt em TramitacaoDemandaAnexo
│   │   │                            # + 3 valores em TramitacaoDemandaEventType
│   │   │                            # + model TramitacaoDemandaAnexoDesentranhamento
│   │   │                            # + enums TramitacaoDesentranhamentoStatus / Direction
│   │   └── notificacao.prisma       # + 3 valores em NotificacaoType
│   └── migrations/
│       └── <timestamp>_tramitacao_desentranhamento/
│           └── migration.sql        # inclui índice único parcial (ver data-model.md)
│
└── src/modules/tramitacao/
    ├── tramitacao.controller.ts     # + 3 rotas novas (request/approve/reject)
    ├── tramitacao.schemas.ts        # + requestDesentranhamentoBodySchema, decideDesentranhamentoBodySchema
    ├── tramitacao.mapper.ts         # + bloco `desentranhamento` no DTO de anexo; + labels dos 3 novos event types
    ├── tramitacao.module.ts         # registra os novos use-cases/repository no DI
    ├── lib/
    │   ├── resolve-anexo-access.ts          # (edição) gate adicional por desentranhadoAt
    │   └── resolve-desentranhamento-approvers.ts   # (novo) direction + conjunto de aprovadores elegíveis
    ├── repository/
    │   └── desentranhamento.repositories.ts # (novo) create / findPendingByAnexo / decide (updateMany condicional)
    └── use-cases/
        ├── request-desentranhamento.use-case.ts   # (novo)
        ├── approve-desentranhamento.use-case.ts    # (novo)
        └── reject-desentranhamento.use-case.ts     # (novo)

src/modules/notificacao/
    ├── notificacao.mapper.ts                        # + TYPE_LABELS dos 3 novos tipos
    └── services/
        ├── tramitacao-notificacao.service.ts        # + notifyDesentranhamentoSolicitado / Aprovado / Rejeitado
        └── resolve-tramitacao-recipients.service.ts # + forDesentranhamentoApprovers(demanda, requesterActor)

ci-client-v2/apps/web/src/modules/tramitacao/
├── api/
│   └── anexos.ts                                # + requestDesentranhamento / approveDesentranhamento / rejectDesentranhamento
├── lib/
│   └── anexo-schemas.ts                          # + tipos/estado de desentranhamento no TramitacaoAnexoView
└── components/
    ├── TramitacaoAnexoList.tsx                   # + badge de status + ação de solicitar/aprovar/rejeitar por anexo
    └── TramitacaoInboxWorkspace.tsx               # + indicador de pedidos pendentes aguardando decisão do usuário atual
```

**Structure Decision**: Reaproveitar integralmente a estrutura modular já existente do domínio `tramitacao` em ambos os pacotes (`ci-api-v2/src/modules/tramitacao/` e `ci-client-v2/apps/web/src/modules/tramitacao/`), sem criar novo módulo, nova rota de nível superior, ou nova página no client — a feature é uma extensão de comportamento sobre a entidade `TramitacaoDemandaAnexo` já modelada, seguindo a Constitution (V. Clean code e modularidade) e o precedente direto da feature 033 (documentos confidenciais), que estendeu o mesmo módulo da mesma forma.

## Fases seguintes

- **Phase 0 (research.md)**: decisões técnicas já documentadas — ver arquivo.
- **Phase 1 (data-model.md, contracts/, quickstart.md)**: já geradas — ver arquivos.
- **Phase 2 (tasks.md)**: gerado por `/speckit-tasks` (fora do escopo deste comando).

## Complexity Tracking

> Nenhuma violação da Constitution identificada nesta feature — tabela intencionalmente vazia.
