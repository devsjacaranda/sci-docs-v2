# Implementation Plan: Migração de Dados v1 → v2 — Tenant AGEMAN (Agema)

**Branch**: `036-migracao-agema-v1` | **Date**: 2026-08-10 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `civ2-docs/specs/036-migracao-agema-v1/spec.md`

**Note**: This template is filled in by the `/speckit-plan` command. See `.specify/templates/plan-template.md` for the execution workflow.

## Summary

Migrar para o v2 todos os dados do tenant AGEMAN hoje existentes no banco MySQL do v1 (dump `controleinterno_prod_ci (13).sql`) nas áreas Auth, Tenant, Ouvidoria e Gabinete, excluindo dados identificados como teste/QA, e adicionar ao `ci-api-v2` um módulo novo de integração viva com o sistema SIGED da Prefeitura de Manaus (contrato em `integração-siged/openapi.json`), permitindo consultar a tramitação real de protocolos do Gabinete que possuam número SIGED. Abordagem técnica: (1) scripts de migração one-off no estilo `prisma/seed.ts` (extract do MySQL v1 → transform em mappers puros testados → load idempotente via Prisma no PostgreSQL v2), executados uma vez por domínio na ordem Tenant → Auth → Ouvidoria → Gabinete; (2) um módulo NestJS `siged` seguindo o scaffold padrão do projeto (repository/use-cases/schemas Zod) para a consulta viva.

## Technical Context

**Language/Version**: TypeScript 5.x / Node.js LTS (alinhado ao `ci-api-v2`, NestJS 11)

**Primary Dependencies**:
- `mysql2` — leitura do MySQL de origem (v1) onde o dump é restaurado para extração (ver Research R1)
- `@prisma/client` (Prisma 7) — escrita no PostgreSQL do v2, reaproveitando `ci-api-v2/prisma/schema/*.prisma` já existente
- `undici`/`fetch` nativo do Node — cliente HTTP do módulo `siged` (`POST /api/auth/token`, `GET /api/movimentacoes/tramitacoes`, `GET /api/protocolos`, `GET /api/departamentos/hierarquia/{secretariaId}`)
- `zod` (`nestjs-zod`) — schemas de entrada/saída do módulo `siged` e dos scripts de migração (`*.schemas.ts`), conforme Constitution III (nunca `class-validator`)
- Nenhuma lib de hashing nova: senhas migram como hash bcrypt já existente, sem re-hash

**Storage**: Origem = MySQL (dump `controleinterno_prod_ci (13).sql`, filtrado pelo tenant AGEMAN `00000000-0000-0000-0000-000000000002`). Destino = PostgreSQL via Prisma (schema modular em `ci-api-v2/prisma/schema/`). Novo: tabela de configuração de credenciais SIGED por tenant (ver Data Model).

**Testing**: Jest (`testing-conventions`). Mappers de migração testados com fixtures JSON (linha v1 → shape v2 esperado), incluindo casos de exclusão de teste/QA. Módulo `siged` testado com mock do cliente HTTP (sem chamar a API real nos testes).

**Target Platform**: (1) Scripts CLI Node.js/ts-node de execução única (job de migração, roda fora do ciclo de request HTTP, dentro do repositório `ci-api-v2`); (2) módulo NestJS novo rodando junto do `ci-api-v2` já em produção.

**Project Type**: Extensão de serviço backend existente (`ci-api-v2`) — não é uma aplicação nova nem exige mudanças no `ci-client-v2` além de um botão/seção para exibir a tramitação SIGED na tela de protocolo do Gabinete (fora do escopo obrigatório desta spec de dados, mas necessário para US4 gerar valor visível).

**Performance Goals**: N/A para a migração em lote (executa uma vez, fora de horário de pico, tenant único e volume pequeno). Para a consulta SIGED ao vivo: resposta perceptível pelo usuário em poucos segundos, respeitando a paginação fixa de 50 registros por página imposta pela API externa.

**Constraints**:
- Migração idempotente: pode ser re-executada sem duplicar registros (upsert por chave natural: e-mail+tenant para usuários, número de protocolo+tenant para protocolos/manifestações etc.)
- Migração restrita ao tenant AGEMAN — nenhuma escrita pode afetar outro tenant
- Credenciais SIGED (`usuarioId`/`usuarioSecret`) hoje estão vazias em `integração-siged/.env` — **dependência externa bloqueante** para ativar a consulta viva em produção (ver Research R4)
- Endpoint SIGED hoje documentado é o de homologação (`https://siged-integracao-api-tst.manaus.am.gov.br`) — endpoint de produção precisa ser confirmado com a equipe SIGED antes do go-live
- `sectors` no v1 **não possui** uma coluna de "chefe de setor" — a FR-005/User Story 1 (chefe migrado automaticamente) não tem fonte de dados direta no v1 (ver Research R5)

**Scale/Scope**: ~62 usuários, ~55 setores, ~250 manifestações de ouvidoria (com anexos/eventos), ~10 protocolos de gabinete, ~20 controles numéricos, poucas dezenas de documentos tramitados por setor, ~150 vínculos usuário-setor — volume pequeno, mas com bastante ramificação relacional entre tabelas.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Princípio | Gate | Status |
|---|---|---|
| I. Spec-Driven Development | Spec (`spec.md`) concluída antes deste plano | ✅ Pass |
| II. Test-First (NON-NEGOTIABLE) | Mappers de migração e módulo `siged` precisam de teste RED antes do código — ver `tasks.md` (fase futura) | ⚠️ A garantir na fase `/speckit-tasks` / `/speckit-implement` |
| III. Stack fixa | Migração e módulo `siged` usam só Prisma + Zod (`nestjs-zod`); nenhum `class-validator`, nenhuma nova stack | ✅ Pass |
| IV. Multi-tenant e licenças | Scripts de migração fixam `tenantId` explicitamente por escrita (padrão já usado em `prisma/seed.ts`, sem depender do middleware `AsyncLocalStorage` de request HTTP); módulo `siged` lê credenciais por tenant | ✅ Pass (ver Research R3) |
| V. Clean code e modularidade | Scripts de migração organizados por domínio (extract/mappers/load); módulo `siged` segue camadas repository/use-cases/schemas | ✅ Pass |

Nenhuma violação que exija entrada em Complexity Tracking.

## Project Structure

### Documentation (this feature)

```text
civ2-docs/specs/036-migracao-agema-v1/
├── spec.md              # Especificação (/speckit-specify)
├── plan.md              # Este arquivo (/speckit-plan)
├── research.md          # Fase 0 (/speckit-plan)
├── data-model.md        # Fase 1 (/speckit-plan)
├── quickstart.md        # Fase 1 (/speckit-plan)
├── contracts/           # Fase 1 (/speckit-plan) — contrato SIGED consumido
└── tasks.md             # Fase 2 (/speckit-tasks — ainda não gerado)
```

### Source Code (repository root)

```text
ci-api-v2/
├── scripts/
│   └── migracao-agema-v1/
│       ├── source/
│       │   └── mysql-v1.client.ts          # conexão de leitura ao MySQL v1 (restaurado do dump)
│       ├── mappers/                        # funções puras v1 → v2, testadas com fixtures
│       │   ├── tenant.mapper.ts
│       │   ├── auth.mapper.ts              # users, sectors, user_sectors, isSuperAdmin→AdminTenant
│       │   ├── ouvidoria.mapper.ts         # manifestations + anexos/eventos
│       │   ├── gabinete.mapper.ts          # protocolos, controle_numerico_*, notificacoes, autos_infracao, documentos_tramitados_*
│       │   └── exclusion-list.ts           # lista curada de ids/e-mails de teste/QA a excluir (FR-024)
│       ├── load/                           # upserts idempotentes via Prisma, um arquivo por entidade
│       ├── reconciliation/
│       │   └── count-report.ts             # comparação de contagem v1 (menos exclusões) vs v2 — SC-006
│       └── run-migration.ts                # orquestrador: tenant → auth → ouvidoria → gabinete
│
├── src/modules/siged/                      # módulo novo — integração viva (FR-020..023)
│   ├── siged.module.ts
│   ├── siged.controller.ts                 # GET tramitações de um CabinetProtocolo
│   ├── siged.schemas.ts                    # Zod: TokenResponseDto, TramitacaoListaDto (espelha openapi.json)
│   ├── repository/
│   │   ├── siged-api.client.ts             # HTTP: /api/auth/token, /api/movimentacoes/tramitacoes
│   │   └── siged-token-cache.ts            # cache do JWT M2M até expirar
│   ├── use-cases/
│   │   └── get-tramitacoes-protocolo.use-case.ts
│   └── test/
│
└── prisma/schema/
    └── siged.prisma                        # novo: TenantSigedConfig (credenciais M2M por tenant)
```

**Structure Decision**: Não é uma "web app" nova (Option 2) nem um projeto CLI isolado (Option 1) — é uma extensão do serviço backend já existente `ci-api-v2`. A migração de dados vive em `ci-api-v2/scripts/migracao-agema-v1/` (padrão já usado por `ci-api-v2/prisma/seed.ts`, fora do ciclo de request HTTP) e a integração viva SIGED vive em `ci-api-v2/src/modules/siged/` seguindo o scaffold modular padrão do projeto (repository/use-cases/schemas). Nenhuma estrutura nova de frontend é obrigatória para esta spec (dados); a exposição visual da tramitação SIGED na tela de protocolo do Gabinete em `ci-client-v2` fica registrada como consumidor natural da API nova, a ser detalhada em tasks.

## Complexity Tracking

> Nenhuma violação de constituição identificada — seção não aplicável.

## Constitution Check (pós-design, Fase 1)

Reavaliado após `data-model.md`, `contracts/` e `quickstart.md`: nenhuma decisão de design introduziu desvio da stack fixa (Prisma + Zod), nem violou o modelo multi-tenant (`TenantSigedConfig` é escopado por `tenantId`, com `@@unique([tenantId])`). Único ponto ainda aberto é operacional, não arquitetural: a Acceptance Scenario 4 de User Story 1 (chefe de setor migrado automaticamente) não é satisfazível a partir dos dados do v1 (Research R5) — recomenda-se ajustar `spec.md` antes de `/speckit-tasks`, mas isso não bloqueia o restante do plano. Gates seguem ✅, exceto II (Test-First), que permanece ⚠️ até a fase `/speckit-implement` aplicar RED→GREEN→REFACTOR de fato.
