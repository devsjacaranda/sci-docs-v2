# Client UI Contract — Módulo Diretor (039)

**App**: `ci-client-v2/apps/web` apenas  
**Rota**: `/diretor`  
**screenId**: `diretor-dashboard`  
**Página**: `modules/diretor/pages/DiretorPage.tsx` (override lazy no router)

## Acesso (client)

`canAccessDiretor(user)` = `role ∈ {admin_tenant, admin_saas, admin_plataforma}` **OU** `email` (trim, lower) === e-mail nominado.

Nav e página: `canAccessDiretor(user) && isAgemanTenant()`. Caso contrário `AccessDenied403` — **não** disparar fetches.

`admin_saas` no `apps/web` é caminho residual (ver research R2). `isSuperAdmin` conta como autorizado se a sessão existir.

## Layout

1. Header: título **Visão do Diretor** + badge **Somente leitura** + botão Atualizar (`fresh=1` + invalidate queries).
2. Filtro global: ano + mês (default = atuais). Reusar/adaptar `YearMonthFilters`.
3. Bloco **Ouvidoria** (chunk 1): 6 KPI cards + toggles 7d/3d + select de pessoa + lista paginada de ações.
4. Bloco **Diagnóstico** (chunk 1): 4 KPI de estoque (badge “não recorta por data”) + 2 KPI locais + mesmos controles de preset/pessoa + lista de marcadores.
5. Bloco **Auditoria geral** (chunk 2, lazy após KPIs): tabela paginada; **não** mostra toggles 7d/3d.

Presets: um por bloco; clicar de novo no ativo desliga (volta ao calendário). Trocar calendário global **não** limpa preset ativo (o bloco com preset ignora o calendário até o diretor desligar).

## Estados

| Estado | UI |
| --- | --- |
| Loading do bloco | skeleton **só daquele** bloco |
| Vazio | copy “Nenhum movimento neste período” |
| Erro de estoque Diagnóstico | aviso no sub-bloco; locais seguem |
| Erro de bloco | alerta + retry; demais blocos intactos |
| 403 | `AccessDenied403` tela cheia |

Sem botões Novo/Editar/Excluir/Encaminhar/Arquivar. Cards não são links para escrita.

## Data fetching

React Query, uma query key por recurso:

```text
['diretor', 'ouvidoria-kpis', periodKey]
['diretor', 'ouvidoria-acoes', periodKey, autorUserId, page]
['diretor', 'diagnostico-kpis', periodKey]
['diretor', 'diagnostico-acoes', periodKey, autorUserId, page]
['diretor', 'audit-logs', year, month, page]
['diretor', 'atores', modulo, periodKey]
```

`staleTime`: 90s KPIs, 30s listas. Contract parse Zod v3 em `diretor.schemas.ts` (espelho da API, com comentário de origem).

## Tokens visuais

Paleta Mint (`mint-palette.mdc`). Cards/superfícies com tokens semânticos. Alvos de clique ≥ 44px. Contraste 4.5:1. Sem emoji como ícone — Lucide.
