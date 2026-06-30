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
| `nestjs-best-practices` | NestJS geral — módulos, DI, guards, performance, error handling |
| `nestjs-module-scaffold` | Criar ou estender módulo (`*.schemas.ts`, controller, service, specs) |
| `prisma-schema-workflow` | Schema, migrations, seed, extensions tenant/soft-delete |
| `auth-patterns` | JWT, guards, roles, tenant, `X-Tenant-ID`, `AdminPlataforma` |
| `licenca-contracts` | `@RequireLicenca`, LicencaGuard, slugs Carvalho/Pau-Brasil/Jatobá/Cedro |

**Docs de produto (não são skills):** `.cursor/docs/licencas-canonicas.md`, `regras-plataforma.md`  
**Vocabulário API:** `ci-api-v2/CONTEXT.md`

### Prioridade API (conflito)

| Situação | Skill principal |
|----------|-----------------|
| Novo endpoint | `testing-conventions` + `nestjs-module-scaffold` |
| Schema/migration | `prisma-schema-workflow` |
| Auth/guards/tenant | `auth-patterns` |
| Licença na rota | `licenca-contracts` |
| Pastas/arquitetura | `ci-api-arquitetura` |
| Review NestJS geral | `nestjs-best-practices` |

---

## 4. Frontend — `ci-client-v2/`

| Skill | Quando usar |
|-------|-------------|
| `ui-ux-pro-max` | UI, layout, cores, tipografia, shadcn, Nivo, design system, mockup |
| `vite-react-best-practices` | Vite, build, rotas lazy, performance, deploy SPA, `VITE_*` |

**Usar as duas** em feature completa (página + rotas + gráficos + layout).

**Paleta:** rule `mint-palette.mdc`  
**Copy/UI de produto:** `.cursor/docs/regras-plataforma.md`

### Prioridade frontend (conflito)

| Situação | Skill principal |
|----------|-----------------|
| "Deixe mais bonito" | `ui-ux-pro-max` |
| App lento / bundle grande | `vite-react-best-practices` |
| Novo dashboard visual | `ui-ux-pro-max` (+ vite se rotas/estado) |
| Erro de build Vite | `vite-react-best-practices` |
| Deploy produção | `vite-react-best-practices` |

### Saúde / e-SUS / UBS

| Skill | Quando usar |
|-------|-------------|
| `esus-aps` | PEC, LEDI 7.4.x, FAI, fichas CDS, DW relatórios, CNS/CNES/SIGTAP, export e-SUS, integração MS, módulo `saude/` |

**Combinar com** `ui-ux-pro-max` em telas Saúde · spec arquivada 024 em `specs/arquivados/024-saude-atendimento-ubs/`

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
