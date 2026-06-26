# Design System — Gestão Institucional (017)

**Gerado via** `ui-ux-pro-max` · **Adaptado** paleta Mint (`mint-palette.mdc`)

## Padrão

**Data-Dense Dashboard** — KPI cards + filtros inline + tabela + paginação; máxima densidade útil sem poluição visual.

## Layout stack (ordem vertical)

1. **Breadcrumb** — `ScreenBreadcrumb` / `InstitutionalListLayout`
2. **Header** — título `text-2xl font-semibold`, descrição muted, contador, **CTA criar** (direita)
3. **KPI grid** — 4 cards `sm:grid-cols-2 xl:grid-cols-4`
4. **Filtros** — card compacto: Select status + Input busca + Botão Buscar
5. **Tabela** — Card com `Table` desktop; `MobileDataCard` em mobile
6. **Paginação** — `{from}–{to} de {total}` + Anterior/Próxima

## Cores (Mint — override ui-ux-pro-max)

| Token | Light | Dark |
|-------|-------|------|
| Fundo página | `#F8FAFC` | `#090D16` |
| Card | `#E2E8F0/30` border `#1E293B/10` | `#1E293B/40` border `#E2E8F0/15` |
| Texto | `#090D16` | `#F8FAFC` |
| CTA | `#0F766E` bg, `#F8FAFC` text | `#2DD4BF` bg, `#090D16` text |
| Badge ativo | primary teal | mint |

## KPI cards (Usuários)

| Label | Valor |
|-------|-------|
| Total de usuários | total (status=all count) |
| Ativos | active count |
| Inativos | inactive count |
| Chefias | chefe_setor count |

## KPI cards (Setores)

| Label | Valor |
|-------|-------|
| Total de setores | total |
| Ativos | active |
| Inativos | inactive |
| Sem chefe | active without chefe |

## Interações

- `cursor-pointer` em linhas/ações clicáveis
- Hover row: `hover:bg-[#E2E8F0]/40` dark `hover:bg-[#1E293B]/40`
- Transições 150–200ms
- Ícones Lucide only (sem emoji)
- Copy: **Inativar** / **Restaurar** — nunca "Excluir" como label principal

## Proibido nesta feature

- Badges/stats Carvalho, Cedro, Jatobá, Pau-Brasil
- `LicenseBadges` no layout institucional
