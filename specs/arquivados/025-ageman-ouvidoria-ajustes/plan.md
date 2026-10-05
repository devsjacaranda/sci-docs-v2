# Implementation Plan: Ajustes internos da Ouvidoria AGEMAN

**Branch**: `025-ageman-ouvidoria-ajustes` | **Date**: 2026-10-05 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/025-ageman-ouvidoria-ajustes/spec.md`

Git desta pasta de docs está em `main`. O diretório da feature é o pin de `.specify/feature.json`.

## Summary

Corrigir a Ouvidoria da AGEMAN em seis pontos já fechados no clarify: as três contas do relatório passam a usar o mesmo conjunto oficial; manifestações com `ouv-demo` no protocolo são apagadas; a lista reabre na página e nos filtros da mesma visita; o filtro de status fica em quatro opções, com os grupos combinados na spec; o bloco Quem tem acesso só aparece para o super administrador nomeado; a zona do formulário de nova manifestação volta a sair do bairro e deixa de ser digitável.

Não há tabela nova. A planilha do relatório e a ficha individual não são redesenhadas. O campo `desfechoPendentes` permanece na resposta para a planilha, mas a tela e o PDF deixam de tratar esse número como bloco separado: ele entra em Pendentes, para a soma bater com o total.

## Technical Context

**Language/Version**: TypeScript no `sci-api-v2` (NestJS 11) e no `sci-client-v2` (React 19, Vite 8)

**Primary Dependencies**: NestJS 11, Fastify, Zod (`*.schemas.ts`), Prisma 7, PostgreSQL; no client, Tailwind v4, shadcn/ui, Vitest, React Router.

**Storage**: PostgreSQL existente. Nenhuma migration. A limpeza apaga linhas cujo `Manifestacao.protocol` contém `ouv-demo`. A página da lista fica na URL e no `sessionStorage` da visita, não no banco.

**Testing**: Jest no `sci-api-v2` (agregações, purge, filtro da lista). Vitest no `sci-client-v2` (zona, página da lista, cartão de acesso, cards do relatório).

**Target Platform**: API e SPA já em uso pela Ouvidoria, multi-tenant.

**Project Type**: Aplicação web (API + client).

**Performance Goals**: A lista e o relatório continuam uma consulta por ação do operador. A limpeza `ouv-demo` roda uma vez por ambiente, não a cada abertura de tela.

**Constraints**: Zod apenas, sem class-validator. Tenant pelo contexto da requisição, sem `tenantId` manual nos services. TDD: teste falhando antes do código. A planilha (`export-relatorio-gestao-excel.use-case.ts`) e os renderizadores da ficha não entram nesta entrega. Excluir `ouv-demo` é exclusão física, não soft delete — ver Complexity Tracking.

**Scale/Scope**: Um tenant AGEMAN. O relato de referência tem 105 manifestações no período, soma das partes 1 abaixo e atendimento por mês em 98. O seed de insights cria protocolos `OUV-DEMO-2026-NNNN`, inclusive `OUV-DEMO-2026-0014`.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Princípio | Resultado |
|-----------|-----------|
| I. Spec-driven | Passa. O plano cobre a spec 025 e as cinco respostas do clarify de 2026-10-05. |
| II. Test-first | Passa. Jest e Vitest cobrem contas, purge, filtro, zona, página da lista e o cartão de acesso antes do código de produção. |
| III. Stack fixa | Passa. NestJS, Zod, Prisma, React, Vite, Tailwind, shadcn. Sem class-validator. Pacotes reais: `sci-api-v2` e `sci-client-v2`. |
| IV. Multi-tenant e licenças | Passa. A limpeza e as consultas usam o tenant do contexto. O cartão de acesso restringe a visão; não cria licença nova. |
| V. Modularidade | Passa. Alteração dentro de `ouvidoria` e no campo de zona compartilhado, com a trava só no formulário de nova manifestação. Sem módulo novo. |

Revisão pós-desenho: os contratos não criam tabela. A exclusão física de `ouv-demo` é a única exceção à soft delete, justificada abaixo. O gate passa com essa justificativa.

## Project Structure

### Documentation (this feature)

```text
specs/025-ageman-ouvidoria-ajustes/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   ├── contas-relatorio.md
│   ├── lista-manifestacoes.md
│   └── formulario-zona-e-acesso.md
└── tasks.md              # /speckit-tasks — não criado aqui
```

### Source Code (repository root)

```text
sci-api-v2/src/modules/ouvidoria/
├── lib/relatorio-gestao-period.ts
├── repository/dashboard.repositories.ts
├── repository/get-relatorio-gestao-acumulado.repository.ts
├── repository/get-relatorio-gestao-*.repository.ts
├── use-cases/get-relatorio-gestao.use-case.ts
├── use-cases/list-manifestacoes.use-case.ts
├── use-cases/purge-manifestacoes-demo.use-case.ts
├── ouvidoria.schemas.ts
└── ouvidoria.types.ts

sci-api-v2/prisma/seed/seed-manifestacoes-insights.ts

sci-client-v2/sci-client-monorepo/apps/web/src/modules/ouvidoria/
├── pages/ManifestacoesListPage.tsx
├── pages/ManifestacaoDetailPage.tsx
├── pages/ManifestacaoWizardPage.tsx
├── pages/OuvidoriaRelatorioGestaoPage.tsx
├── components/dashboard/DashboardStatsCards.tsx
├── components/ManifestacaoAcessoCard.tsx
├── lib/can-view-quem-tem-acesso.ts
└── lib/relatorio-gestao-mappers.ts

sci-client-v2/sci-client-monorepo/apps/web/src/modules/shared/components/fields/index.tsx
sci-client-v2/sci-client-monorepo/apps/web/src/modules/shared/lib/via-cep.ts
```

**Structure Decision**: A mudança mora no módulo Ouvidoria dos dois pacotes, mais o campo Zona do endereço compartilhado. A lista guarda a página na própria rota. A limpeza é um use case chamado por script, não um endpoint de tela. A planilha e a ficha ficam de fora.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| Soft delete transparente (constitution IV) | O clarify escolheu apagar de vez os protocolos `ouv-demo`. Soft delete deixaria o registro recuperável na tela e foi a opção recusada. | Ocultar com `deletedAt` é a opção A do clarify. O aceite é busca e abertura não encontrarem o protocolo, só recuperação operacional fora do produto. |
