# Test Strategy — 039 Módulo Diretor

TDD obrigatório (Constitution II). IDs `CT-DIR-NNN` nos describes da API.

## API (Jest) — RED primeiro

| ID | Alvo | Casos |
| --- | --- | --- |
| CT-DIR-001 | `diretor.schemas` | happy; `presetDays` 3/7; `presetDays` inválido; `month` 13; `limit` 51; `year` default implícito |
| CT-DIR-002 | `resolve-diretor-period` | calendário UTC; preset substitui calendário; default mês atual |
| CT-DIR-003 | `DiretorAccessGuard` | 403 tenant Jacaranda; 403 `user` sem e-mail nominado; allow `admin_plataforma` AGEMAN; allow e-mail nominado com role `user`; allow `admin_saas` + header AGEMAN; 403 `admin_saas` + outro tenant |
| CT-DIR-004 | `get-ouvidoria-kpis` | 6 KPIs no mês; janela 7 dias; cache hit na 2ª chamada; `fresh` bypass |
| CT-DIR-005 | `list-ouvidoria-acoes` | página; filtro `autorUserId`; vazio |
| CT-DIR-006 | `get-diagnostico-kpis` | estoque + locais; MySQL down → `estoqueErro` e locais ok |
| CT-DIR-007 | `list-diagnostico-acoes` | marcadores no período; filtro autor |
| CT-DIR-008 | `list-audit-logs` | recorte mês; ignora preset se alguém mandar; paginação `{items,total,page,limit}`; actor via `userId` e via `payload.actorId` |

Controller: nenhum método de escrita registrado (assert das rotas no spec de módulo).

## Client (Vitest)

| Alvo | Casos |
| --- | --- |
| `can-access-diretor` | roles allow; e-mail case-insensitive; user comum negado |
| `resolve-diretor-period` | paridade com a API |
| schemas Zod | fixture de cada response |
| `DiretorPage` (RTL) | default mês atual; preset só no bloco; 403; empty; estoque degradado; zero botões de escrita |

## E2E (opcional nesta entrega)

Playwright no tenant AGEMAN: login Ebenezer (ou `admin_plataforma`) → `/diretor` visível; login operador comum → 403. Pode ficar para `/speckit-tasks` se o ambiente E2E AGEMAN já estiver estável.

## Ordem RED → GREEN

1. Schemas + period helper  
2. Guard  
3. Use-cases (repos mockados)  
4. Controller + cache  
5. Client helpers + página  
6. Migration do índice (teste de query com `explain` não é obrigatório)
