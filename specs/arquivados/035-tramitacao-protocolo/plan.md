# Implementation Plan: Tramitação como Protocolo

**Branch**: `035-tramitacao-protocolo` | **Date**: 2026-07-08 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `civ2-docs/specs/035-tramitacao-protocolo/spec.md`

## Summary

Refatorar o módulo de Tramitação de um modelo de **mensagem/demanda** (encaminhamento que move entre setores, pastas Recebidas/Enviadas/Arquivadas) para um modelo de **Protocolo** (contêiner persistente com participantes — setores ou 1:1 pessoal — que colaboram numa linha do tempo única de atualizações, podem ser baixados como dossiê PDF+ZIP a qualquer momento, e opcionalmente encerrados em somente-leitura permanente). Abordagem técnica: reescrever o schema Prisma do módulo `tramitacao` in place (reset total de dados, sem migração), introduzindo tabelas associativas de participação (`TramitacaoProtocoloSetor`, `TramitacaoProtocoloGestor`) que substituem os campos únicos `senderSectorId`/`currentSectorId`; reescrever use-cases/controller/rotas (`/tramitacao/protocolos`); reconciliar a feature 034 (desentranhamento, em curso) adaptando a resolução de aprovadores de "lado receptor atual" para "qualquer outro participante"; adicionar exportação PDF+ZIP reaproveitando `pdf-lib` (já usado em IT-Fiscalização) e uma nova dependência leve `jszip`; reescrever a UI do módulo (`ui-ux-pro-max`) em torno do novo vocabulário (Protocolo, Participantes, Atualizações, Encerrar, Baixar).

## Technical Context

**Language/Version**: TypeScript 5.x (stack fixa do monorepo — Constitution III), sem mudança.

**Primary Dependencies**: NestJS 11 + Fastify + Zod (nestjs-zod) + Prisma 7 (API); React 19 + Vite 8 + Tailwind v4 + shadcn/ui (client). Nova dependência: `jszip` (`ci-api-v2`, geração de ZIP para exportação — research.md §8). Reaproveita `pdf-lib` (já presente).

**Storage**: PostgreSQL via Prisma, multi-tenant (AsyncLocalStorage) — mesmo padrão do monorepo. Reset total das tabelas do módulo Tramitação numa única migration (research.md §1, data-model.md → Migration). Object storage Wasabi/S3 (`StorageService`, presign+putObject) reaproveitado sem mudança de infraestrutura; adiciona-se apenas `getObjectBuffer` ao serviço.

**Testing**: Jest (API, TDD obrigatório — Constitution II, skills `tdd`/`testing-conventions`) + Vitest (client, `js-ts-data-transforms`/component tests).

**Target Platform**: Web — SPA multi-tenant existente (`ci-client-v2/apps/web`) consumindo REST API (`ci-api-v2`), sem mudança de plataforma.

**Project Type**: Web application (monorepo já estabelecido: `ci-api-v2` backend independente + `ci-client-v2` Turborepo frontend).

**Performance Goals**: Lista "Meus protocolos" ordenada por `updatedAt DESC` deve refletir nova atualização em segundos (SC-003) — atendido por índice `@@index([tenantId, status, updatedAt])` e ausência de agregação pesada na query de listagem. Exportação síncrona aceitável para o volume esperado (documentos administrativos internos, não datasets massivos).

**Constraints**: Exportação limitada a soma de anexos ≤ 200MB por chamada (guard simples, research.md §9) — acima disso, `422 EXPORT_TOO_LARGE` em vez de streaming otimizado (fora do escopo do MVP). Sem paginação incremental na busca de protocolos para entranhar (limite de 20 resultados).

**Scale/Scope**: Escala multi-tenant já suportada pelo monorepo; refatoração cobre 8 user stories (P1–P3), ~22 use-cases reescritos/adaptados no backend e reescrita completa das telas do módulo no client (Constitution — sem novo módulo, mesmo domínio `tramitacao`).

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Princípio | Avaliação | Conformidade |
|---|---|---|
| I. Spec-Driven Development | Segue `/speckit-specify` → `/speckit-plan` → `/speckit-tasks` → `/speckit-implement` → `/speckit-complete`; specs ativas em `civ2-docs/specs/035-tramitacao-protocolo/` | ✅ |
| II. Test-First (NON-NEGOTIABLE) | Todo código novo do `/speckit-tasks`/`/speckit-implement` seguirá RED→GREEN→REFACTOR (Jest API, Vitest client); tasks.md organizará "Tests for User Story" antes de "Implementation" por US, como no padrão já usado em 034 | ✅ (a verificar na execução das tasks) |
| III. Stack fixa | Nenhum desvio — NestJS/Fastify/Zod/Prisma/PostgreSQL (API) e React/Vite/Tailwind/shadcn (client) mantidos; única adição é `jszip` (lib pura JS, sem infra nova) | ✅ |
| IV. Multi-tenant e licenças | `tenantId` via AsyncLocalStorage em todas as novas tabelas/queries, sem `tenantId` manual em services; licença **Base** inalterada | ✅ |
| V. Clean code e modularidade | Refatoração acontece **dentro** do módulo `tramitacao/` existente (não cria módulo paralelo); camadas repository/use-cases/schemas mantidas; client espelha em `modules/tramitacao/` com `api/components/lib/hooks/pages` | ✅ |

**Nenhuma violação identificada.** Não há necessidade de preencher Complexity Tracking.

**Ponto de atenção não-bloqueante**: a feature 034 (desentranhamento) está em curso (~66%, 29/44 tasks) e será reconciliada como parte desta refatoração em vez de concluída isoladamente no modelo antigo (research.md §6) — decisão já validada com o usuário nas Assumptions da spec 035.

## Project Structure

### Documentation (this feature)

```text
civ2-docs/specs/035-tramitacao-protocolo/
├── spec.md                          # Feature spec (/speckit-specify)
├── plan.md                          # This file (/speckit-plan)
├── research.md                      # Phase 0 — decisões técnicas
├── data-model.md                    # Phase 1 — entidades Prisma
├── contracts/
│   └── protocolo-api.md             # Phase 1 — contrato REST completo
├── quickstart.md                    # Phase 1 — roteiro de validação (8 cenários)
├── checklists/
│   └── requirements.md              # Checklist de qualidade da spec
└── tasks.md                         # Phase 2 (/speckit-tasks — não criado por este comando)
```

### Source Code (repository root)

```text
ci-api-v2/
├── prisma/
│   ├── schema/
│   │   ├── tramitacao.prisma        # REESCRITO: TramitacaoProtocolo* (data-model.md)
│   │   └── notificacao.prisma       # ALTERADO: enum NotificacaoType (research.md §7)
│   └── migrations/
│       └── <timestamp>_tramitacao_protocolo_reset/
├── src/modules/
│   ├── tramitacao/                  # REESCRITO in place (mesmo módulo)
│   │   ├── tramitacao.module.ts
│   │   ├── tramitacao.controller.ts # Rotas /tramitacao/protocolos/* (contracts/protocolo-api.md)
│   │   ├── tramitacao.schemas.ts    # Zod: CreateProtocoloBody, AddAtualizacaoBody, IncluirSetorBody, etc.
│   │   ├── tramitacao.mapper.ts     # DTOs: ProtocoloListItem, ProtocoloDetail, ProtocoloTimelineEvent
│   │   ├── use-cases/               # ~22 arquivos: open/list/get-detail/add-atualizacao/incluir-setor/
│   │   │                           #   conceder-gestor/entranhar/buscar-para-entranhar/encerrar/baixar/
│   │   │                           #   anexos (presign/confirm/link/download) + desentranhamento (reconciliado)
│   │   ├── repository/              # protocolo.repositories.ts, setor-participante.repositories.ts,
│   │   │                           #   gestor.repositories.ts, evento.repositories.ts, anexo.repositories.ts,
│   │   │                           #   desentranhamento.repositories.ts, list-protocolos.repository.ts
│   │   └── lib/                     # can-manage-protocolo.ts, resolve-desentranhamento-approvers.ts (reconciliado),
│   │                               #   resolve-anexo-access.ts (preservado), generate-protocol-number.ts (preservado)
│   ├── notificacao/
│   │   └── services/
│   │       ├── resolve-tramitacao-recipients.service.ts  # ALTERADO: participantes N-setores + pessoal
│   │       └── tramitacao-notificacao.service.ts         # ALTERADO: novos tipos (research.md §7)
│   └── shared/storage/
│       └── storage.service.ts       # + getObjectBuffer (novo método, para exportação ZIP)
└── package.json                     # + jszip

ci-client-v2/apps/web/src/modules/tramitacao/
├── api/
│   ├── protocolos.ts                 # NOVO (substitui demandas.ts): listProtocolos, createProtocolo,
│   │                                 #   getProtocoloDetail, addAtualizacao, incluirSetor, concederGestor,
│   │                                 #   entranhar, buscarParaEntranhar, encerrar, baixar
│   └── anexos.ts                     # AJUSTADO: paths /protocolos/, direction renomeada
├── components/                       # REESCRITOS (research.md §12):
│   ├── TramitacaoProtocoloWorkspace.tsx   # substitui TramitacaoInboxWorkspace (lista única + detalhe)
│   ├── TramitacaoAbrirProtocoloForm.tsx   # substitui ComposeForm/Screen
│   ├── TramitacaoTimeline.tsx             # substitui ConversationThread (eventos + tipos novos)
│   ├── TramitacaoParticipantesPanel.tsx    # NOVO: setores incluídos + gestores + incluir/conceder
│   ├── TramitacaoEntranharDialog.tsx       # NOVO: buscar + selecionar protocolo existente (US4)
│   ├── TramitacaoEncerrarDialog.tsx        # NOVO
│   ├── TramitacaoBaixarButton.tsx          # NOVO
│   ├── LinkedRecordPanel.tsx               # REAPROVEITADO (ajuste de nomenclatura)
│   ├── TramitacaoAnexoUploadZone.tsx        # REAPROVEITADO sem mudança
│   ├── TramitacaoAnexoList.tsx              # REAPROVEITADO (direction renomeada)
│   ├── ConfidentialAccessPanel/Picker.tsx   # REAPROVEITADOS sem mudança
│   └── TramitacaoSectorPills.tsx            # REAPROVEITADO
├── hooks/                             # useTramitacaoSectorId (reaproveitado); useTramitacaoInboxMode REMOVIDO
├── lib/
│   ├── tramitacao-routes.ts            # AJUSTADO: /tramitacao/protocolos, sem folder/inboxMode
│   ├── can-manage-protocolo.ts         # NOVO (espelha lib da API para UI condicional)
│   └── tramitacao-theme.ts             # REAPROVEITADO
├── pages/                              # TramitacaoProtocolosPage, TramitacaoProtocoloDetailPage,
│                                       #   TramitacaoAbrirProtocoloPage, TramitacaoDashboardPage (ajustes de KPI)
└── mockdown/                           # REMOVIDO (protótipo obsoleto — modelo antigo)
```

**Structure Decision**: Refatoração **in place** dentro dos diretórios já existentes `ci-api-v2/src/modules/tramitacao/` e `ci-client-v2/apps/web/src/modules/tramitacao/` — mantém a arquitetura modular por domínio da Constitution V (nenhum módulo novo criado), apenas troca a entidade central e reescreve as camadas que dependem diretamente da semântica de mensagem/pasta. Rotas mudam de `/tramitacao/demandas` para `/tramitacao/protocolos` (client e API) para reforçar o novo vocabulário; `/tramitacao/dashboard` e `/tramitacao/auditoria` (tela Jatobá) mantêm o path atual.

## Complexity Tracking

*Sem violações da Constitution Check — tabela não aplicável.*
