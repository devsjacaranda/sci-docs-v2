# CI v2 — Documentação

Pasta unificada de documentação do monorepo: Spec Kit, specs de features e índice de skills.

## Estrutura

| Caminho | Conteúdo |
|---------|----------|
| [`.specify/`](./.specify/) | Templates, scripts PowerShell, constitution |
| [`specs/`](./specs/) | Features: `specs/<NNN-nome>/spec.md`, `plan.md`, `tasks.md` |
| [`spec-kit/`](./spec-kit/) | Índice + [SKILLS.md](./spec-kit/SKILLS.md) |

## Fluxo Spec Kit

1. `/speckit-constitution` — [`.specify/memory/constitution.md`](./.specify/memory/constitution.md)
2. `/speckit-specify` — cria `civ2-docs/specs/<feature>/`
3. `/speckit-plan` — `plan.md`
4. `/speckit-tasks` — `tasks.md`
5. `/speckit-implement` — execução TDD

**Índice de skills:** [spec-kit/SKILLS.md](./spec-kit/SKILLS.md)

## Docs de produto (fora desta pasta)

- [licencas-canonicas.md](../.cursor/docs/licencas-canonicas.md)
- [regras-plataforma.md](../.cursor/docs/regras-plataforma.md)
