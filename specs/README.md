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
| 022 | [it-seguranca-informacao](./022-it-seguranca-informacao/spec.md) |
| 023 | [global-docs](./023-global-docs/spec.md) |
| 025 | [tenant-branding-config](./025-tenant-branding-config/spec.md) |
| 026 | [esus-mockdown-export](./026-esus-mockdown-export/spec.md) |
| 029 | [notification-system](./029-notification-system/spec.md) |
| 030 | [gabinete-tramitacao-linked](./030-gabinete-tramitacao-linked/spec.md) |
| 034 | [desentranhamento-tramitacao](./034-desentranhamento-tramitacao/spec.md) |
| 036 | ~~[migracao-agema-v1](./036-migracao-agema-v1/spec.md)~~ — **substituída pela 038** |
| 037 | [siged-ux-refactor](./037-siged-ux-refactor/spec.md) |
| 038 | [migracao-modulos-v1](./038-migracao-modulos-v1/spec.md) |
| 039 | [modulo-diretor](./039-modulo-diretor/spec.md) — **ativa** |
| 040 | [dossie-detalhe-ui](./040-dossie-detalhe-ui/spec.md) — **norma de UI** (dossiê de detalhe; piloto Ouvidoria) |
| 041 | [migracao-historico-ouvidoria](./041-migracao-historico-ouvidoria/spec.md) |
| 042 | [relatorio-gestao-ouvidoria](./042-relatorio-gestao-ouvidoria/spec.md) |
| 043 | [ouvidoria-publica-ageman](./043-ouvidoria-publica-ageman/spec.md) |
| 044 | [emissor-criador-ageman](./044-emissor-criador-ageman/spec.md) |
| 045 | [rascunho-manifestacao-ouvidoria](./045-rascunho-manifestacao-ouvidoria/spec.md) |
| 046 | [timbrado-ageman-2026](./046-timbrado-ageman-2026/spec.md) — **Draft** (folha padrão oficial) |
| 047 | [acesso-ouvidoria-ageman](./047-acesso-ouvidoria-ageman/spec.md) |
| 048 | [identificacao-sem-anonimo](./048-identificacao-sem-anonimo/spec.md) — **Draft** (remove opção anônimo + e-mail único em Identificação, assistente interno) |
| 049 | [ajustes-relatorio-gestao-ouvidoria](./049-ajustes-relatorio-gestao-ouvidoria/spec.md) — **Draft** (satisfação Sim/Não, bug PDF, orientações/encaminhamentos detalhado, participação em eventos) |

## Arquivadas

Índice completo: [arquivados/README.md](./arquivados/README.md) (001–035).

**Última concluída:** [035 Tramitação Protocolo](./arquivados/035-tramitacao-protocolo/STATUS.md)

Infra Spec Kit: `civ2-docs/.specify/` · Skills: [spec-kit/SKILLS.md](../spec-kit/SKILLS.md)
