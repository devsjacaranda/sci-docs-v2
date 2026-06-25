# Spec Kit — CI v2

Índice de documentação do [GitHub Spec Kit](https://github.com/github/spec-kit) neste monorepo.

**Infra e features ficam em [`civ2-docs/`](../)** — esta pasta é só o índice e o guia de skills.

## Onde está cada coisa

| Caminho | Conteúdo |
|---------|----------|
| [`civ2-docs/.specify/`](../.specify/) | Templates, scripts PowerShell, constitution |
| [`civ2-docs/specs/`](../specs/) | Features: `specs/<NNN-nome>/spec.md`, `plan.md`, `tasks.md` |
| [`civ2-docs/spec-kit/`](./) | Este índice + [SKILLS.md](./SKILLS.md) |

## Fluxo

1. `/speckit-constitution` — [`civ2-docs/.specify/memory/constitution.md`](../.specify/memory/constitution.md)
2. `/speckit-specify` — cria `civ2-docs/specs/<feature>/`
3. `/speckit-plan` — `plan.md`
4. `/speckit-tasks` — `tasks.md`
5. `/speckit-implement` — execução TDD

Skills em `.cursor/skills/speckit-*` (raiz do monorepo).

## Quando usar cada skill

**Índice completo:** [SKILLS.md](./SKILLS.md)

## CLI

```powershell
specify version
specify self check
```

Instalação: `uv tool install specify-cli --from git+https://github.com/github/spec-kit.git@v0.9.5`

## Docs de produto (fora do Spec Kit)

- [licencas-canonicas.md](../../.cursor/docs/licencas-canonicas.md)
- [regras-plataforma.md](../../.cursor/docs/regras-plataforma.md)
