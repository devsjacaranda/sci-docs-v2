# Skills — quando usar cada uma

Índice canônico de skills do monorepo CI v2.  
Localização: `.cursor/skills/<nome>/SKILL.md` (espelhadas em `.agents/skills/`).

**Regra geral:** não improvisar — leia a skill antes de implementar.

---

## 1. Processo (sempre primeiro em feature nova)

| Skill / comando | Quando usar |
|-----------------|-------------|
| `/speckit-specify` | Nova feature — definir **o quê** e **por quê** (sem stack) |
| `/speckit-clarify` | *(opcional)* Spec ambígua — **antes** de `/speckit-plan` |
| `/speckit-plan` | Após spec — stack, arquitetura, estrutura de pastas |
| `/speckit-tasks` | Após plan — quebrar em tarefas acionáveis |
| `/speckit-analyze` | *(opcional)* Consistência entre artefatos — **antes** de implementar |
| `/speckit-implement` | Executar tasks com TDD |
| `/speckit-complete` | **Arquivar** — STATUS.md, `feature.json`, move para `specs/arquivados/` |
| `/speckit-checklist` | *(opcional)* Validar completude da spec/plan |
| `/speckit-constitution` | Criar ou alterar princípios do projeto |
| `/speckit-taskstoissues` | Exportar tasks para GitHub Issues |

**Ordem mínima:** specify → plan → tasks → implement → **complete** (move para `specs/arquivados/`).

**Layout specs:** ativas em `civ2-docs/specs/<NNN-feature>/` · arquivadas em `civ2-docs/specs/arquivados/` · índice [specs/README.md](../specs/README.md).

---

## 2. TDD (obrigatório em código novo)

| Skill | Quando usar |
|-------|-------------|
| `tdd` | **Sempre** antes de escrever código — ciclo RED → GREEN → REFACTOR |
| `test-driven-development` | Reforço anti-patterns de teste (complementa `tdd`) |
| `testing-conventions` | **ci-api-v2** — Jest unit/e2e, mocks, estrutura de testes |

---

## 3. API — `ci-api-v2/`

| Skill | Quando usar |
|-------|-------------|
| `ci-api-arquitetura` | Estrutura de pastas, pipeline de request, clean code, patterns |
| `nestjs-best-practices` | NestJS geral — módulos, DI, guards, performance, error handling (fonte: `kadajett/agent-nestjs-skills`, 40 regras/10 categorias) |
| `fastify-best-practices` | Fastify puro sob o Nest — rotas, plugins, hooks, JSON Schema, Pino, CORS, ciclo de vida da request (fonte: `mcollina/skills`) |
| `nestjs-module-scaffold` | Criar ou estender módulo (`*.schemas.ts`, controller, service, specs) |
| `prisma-schema-workflow` | Schema, migrations, seed, extensions tenant/soft-delete |
| `prisma-postgres` | Provisionar/gerenciar Postgres via Prisma Console, `create-db`, Management API (fonte: `prisma/skills`) |
| `neon-postgres` | *(opcional)* Neon/Lakebase Postgres — branching, scale-to-zero, pooling, se o ambiente usar Neon (fonte: `neondatabase/agent-skills`) |
| `auth-patterns` | JWT, guards, roles, tenant, `X-Tenant-ID`, `AdminPlataforma` |
| `licenca-contracts` | `@RequireLicenca`, LicencaGuard, slugs Carvalho/Pau-Brasil/Jatobá/Cedro |
| `js-ts-data-transforms` | Shaping Prisma→DTO, agregações em service — **complementa** scaffold |
| `js-ts-performance-readability` | Seeds, scripts, utils puros — **complementa** nestjs/prisma |
| `typescript-mastery` | Generics, conditional/mapped/template-literal types, `satisfies`, DTOs Zod — ver §5.1 |
| `reset-senha` | Resetar senha de `User`/`AdminTenant`/`AdminPlataforma` — senha forte gerada + `mustChangePassword`, via API ou `scripts/reset-account-password.ts` |

**Docs de produto (não são skills):** `.cursor/docs/licencas-canonicas.md`, `regras-plataforma.md`  
**Vocabulário API:** `ci-api-v2/CONTEXT.md`

### Prioridade API (conflito)

| Situação | Skill principal |
|----------|-----------------|
| Novo endpoint | `testing-conventions` + `nestjs-module-scaffold` |
| Schema/migration | `prisma-schema-workflow` |
| Provisionar banco Prisma Postgres | `prisma-postgres` |
| Auth/guards/tenant | `auth-patterns` |
| Licença na rota | `licenca-contracts` |
| Pastas/arquitetura | `ci-api-arquitetura` |
| Review NestJS geral | `nestjs-best-practices` |
| Rota/plugin/hook Fastify puro | `fastify-best-practices` |
| Mapper / agregação service | `js-ts-data-transforms` |
| Seed / script | `js-ts-performance-readability` |
| Tipo avançado / generics / DTO Zod | `typescript-mastery` |
| Resetar senha de conta | `reset-senha` |

---

## 4. Frontend — `ci-client-v2/`

| Skill | Quando usar |
|-------|-------------|
| `ui-ux-pro-max` | UI, layout, cores, tipografia, shadcn, Nivo, design system, mockup |
| `shadcn` | Adicionar/atualizar componentes shadcn/ui via CLI, `components.json`, registries, presets (fonte: `shadcn-ui/ui`) — **complementa** `ui-ux-pro-max` |
| `vite-react-best-practices` | Vite, build, rotas lazy, performance, deploy SPA, `VITE_*` |
| `react-vite-best-practices` | Otimização React+Vite — code splitting, lazy loading, HMR, bundle size, 23 regras/6 categorias (fonte: `asyrafhussin/agent-skills`) — **complementa** `vite-react-best-practices` |
| `typescript-mastery` | Generics, conditional/mapped/template-literal types, `satisfies`, tipos de props/hooks — ver §5.1 |
| `js-ts-data-transforms` | `*-mappers.ts`, ViewModels, API→UI, fixtures Vitest — **complementa** vite |
| `js-ts-performance-readability` | Utils puros, parsers, agregações — **complementa** vite |

**Usar as duas** em feature completa (página + rotas + gráficos + layout).

**Paleta:** rule `mint-palette.mdc`  
**Copy/UI de produto:** `.cursor/docs/regras-plataforma.md`  
**Tela de detalhe (dossiê canônico):** [specs/040-dossie-detalhe-ui](../specs/040-dossie-detalhe-ui/spec.md) · §4.3 de `regras-plataforma.md`

### Prioridade frontend (conflito)

| Situação | Skill principal |
|----------|-----------------|
| "Deixe mais bonito" | `ui-ux-pro-max` |
| App lento / bundle grande | `vite-react-best-practices` |
| Novo dashboard visual | `ui-ux-pro-max` (+ vite se rotas/estado) |
| Erro de build Vite | `vite-react-best-practices` |
| Deploy produção | `vite-react-best-practices` |
| Componente shadcn novo/atualizar | `shadcn` |
| Bundle size / code splitting React | `react-vite-best-practices` |
| Mapper / transform de dados | `js-ts-data-transforms` |
| Util / parser puro | `js-ts-performance-readability` |
| Tipo avançado / generics | `typescript-mastery` |

### Saúde / e-SUS / UBS

| Skill | Quando usar |
|-------|-------------|
| `esus-aps` | PEC, LEDI 7.4.x, FAI, fichas CDS, DW relatórios, CNS/CNES/SIGTAP, export e-SUS, integração MS, módulo `saude/` |

**Combinar com** `ui-ux-pro-max` em telas Saúde · spec arquivada 024 em `specs/arquivados/024-saude-atendimento-ubs/`

---

## 5.1 JS/TS transversal (complementar)

Adaptado de [icyJoseph/agent-skills](https://github.com/icyJoseph/agent-skills) para o monorepo CI v2. **Não substituem** skills de stack — preenchem lacunas em transforms e código puro.

| Skill | Quando usar |
|-------|-------------|
| `js-ts-data-transforms` | Mappers, ViewModels, agregações, pipeline fetch→validate→map, shaping Prisma→DTO |
| `js-ts-performance-readability` | Seeds, scripts, Map/Set, async paralelo, edge cases em utils |
| `typescript-mastery` | **"Code master"** — skill unificada (fusão de `wshobson/agents::typescript-advanced-types` + `spillwavesolutions/mastering-typescript-skill::mastering-typescript`). Generics, conditional/mapped/template-literal types, `infer`, type guards, `satisfies`, integração React/NestJS, Zod, toolchain TS 5.9+. Usar em **ambos** os pacotes (API e client) sempre que a lógica de tipos for o foco |

---

## 5.2 Utilidades, QA e arquitetura (via `npx skills add`)

Instaladas com o CLI [skills.sh](https://skills.sh) — rastreadas em `skills-lock.json` (raiz do repo). Uso pontual, fora do fluxo diário de stack.

| Skill | Quando usar | Fonte |
|-------|-------------|-------|
| `playwright-e2e` | Testes E2E com Playwright — Page Object Model, fixtures, seletores resilientes (`getByRole`), config multi-browser | `thetestingacademy` via qaskills.sh |
| `xlsx` | Ler/criar/editar `.xlsx`/`.csv`/`.tsv` — fórmulas, formatação, dados tabulares | `anthropics/skills` |
| `pdf` | Ler, mesclar, dividir, preencher formulário, OCR, watermark em PDF | `anthropics/skills` |
| `clean-code` | Refatorar "código que funciona" em "código limpo" (Uncle Bob) — nomes, funções, comentários | `sickn33/agentic-awesome-skills` |
| `clean-architecture` | Dependency Rule, camadas, ports & adapters, isolar regra de negócio de framework/DB | `wondelai/skills` |

**Prioridade:** qualidade de código pontual → `clean-code`; decisão de camadas/módulos → `clean-architecture` (também cobre `ci-api-arquitetura`, mas este último é a referência canônica do monorepo em caso de conflito).

---

## 5. Feature full-stack (API + client)

Ordem sugerida:

1. Spec Kit: `/speckit-specify` → `/speckit-plan` → `/speckit-tasks`
2. Implementar API: skills da seção 3 + TDD
3. Implementar client: skills da seção 4 + TDD
4. `/speckit-implement` cobre o fluxo se usar o comando único
5. `/speckit-complete` arquiva a feature (STATUS, feature.json, contexto agente)

No `/speckit-plan`, declarar explicitamente `ci-api-v2` e `ci-client-v2`.

---

## 6. Meta / engenharia (uso pontual)

| Skill | Quando usar |
|-------|-------------|
| `improve-codebase-architecture` | Refatorar arquitetura, reduzir acoplamento |
| `grill-with-docs` | Alinhar requisitos antes de spec grande |
| `diagnose` | Bug difícil — loop reproduce → fix |
| `systematic-debugging` | Debug estruturado (superpowers) |
| `writing-plans` / `executing-plans` | Planos detalhados fora do Spec Kit |

Não são obrigatórias no fluxo diário — use quando o contexto pedir.

---

## Onde o agente lê isso

| Arquivo | Escopo |
|---------|--------|
| [SKILLS.md](./SKILLS.md) | Este índice (humano + referência) |
| `.cursor/rules/skill-index.mdc` | Roteamento always-on para o agente |
| `.cursor/rules/skill-routing.mdc` | Frontend (detalhe) |
| `.cursor/rules/skill-routing-api.mdc` | API (detalhe) |
| `.cursor/rules/specify-rules.mdc` | Contexto Spec Kit + stack |
| `skills-lock.json` (raiz) | Proveniência das skills externas instaladas via `npx skills add` — reprodutibilidade (`skills experimental_install`) |
