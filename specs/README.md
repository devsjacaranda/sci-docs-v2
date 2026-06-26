# Specs — CI v2

Diretório canônico de features Spec Kit.

## Layout

| Caminho | Conteúdo |
|---------|----------|
| `civ2-docs/specs/<NNN-feature>/` | **Specs ativas** — criadas por `/speckit-specify`, em implementação ou Draft |
| `civ2-docs/specs/arquivados/<NNN-feature>/` | **Specs concluídas** — movidas por `/speckit-complete` |

## Fluxo

```
/speckit-specify  →  specs/019-.../spec.md
/speckit-plan     →  plan.md, contracts/, ...
/speckit-tasks    →  tasks.md
/speckit-implement
/speckit-complete →  STATUS.md + move para specs/arquivados/
```

## Ativas (Draft)

| # | Spec |
|---|------|
| 019 | [purchasing-fiscalizacao](./019-purchasing-fiscalizacao/spec.md) |
| 021 | [purchasing-maturidade](./021-purchasing-maturidade/spec.md) |

## Arquivadas

Índice completo: [arquivados/README.md](./arquivados/README.md) (001–020).

**Última concluída:** [020 Purchasing Insights](./arquivados/020-purchasing-insights/STATUS.md)

Infra Spec Kit: `civ2-docs/.specify/` · Skills: [spec-kit/SKILLS.md](../spec-kit/SKILLS.md)
