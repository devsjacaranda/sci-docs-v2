# STATUS — 031 Desmock do Dashboard Global

**Data**: 2026-07-02 (arquivada)  
**Estado**: Concluída — 39/39 tasks em `tasks.md`

## Entregue (spec)

### API (`ci-api-v2`)

- Módulo `global-dashboard` — `GET /global/dashboard?periodDays=30`
- KPIs reais: ocorrências prioritárias, demandas pendentes, atualizações 24h
- KPI mock rotulado: registros ativos transversal (`source: mock`)
- Feed: eventos `TramitacaoDemandaEvento` + notificações do usuário (até 10 itens)
- Gráfico: demandas linked por módulo de origem (`bySourceModule`)
- Ouvidoria condicional via `CheckModuloAccessUseCase` (`meta.includesOuvidoria`)
- Export `ListNotificacoesRepository` em `NotificacaoModule`

### Client (`ci-client-v2/apps/web`)

- Domínio `modules/global/` — api, hook, mappers, componente
- `GlobalWelcomeDashboard` movido de `shell/components/mock/`
- Perfil 100% `useAuth()` — removido `loadProfile()` / admin-mock
- `MockDataBadge` em KPIs mock
- Loading skeleton + error state sem fallback silencioso para mock
- Removidos `stats` estáticos de `screens.global-dashboard` e `welcomeActivities`

### Testes

- **API**: 10 testes Jest (`--testPathPatterns=global-dashboard`)
- **Client**: 10 testes Vitest (`global-dashboard`, `GlobalWelcomeDashboard`)

---

## Inventário final (home `/global/dashboard`)

| Bloco | Fonte |
| --- | --- |
| Branding institucional | Real (`useTenantBranding`) |
| Hero perfil | Real (`useAuth`) |
| KPIs 3/4 | Real (API) |
| KPI registros transversal | Mock rotulado |
| Atalhos + continuar módulo | Real (inalterado) |
| Atividade recente | Real (API) |
| Gráfico linked por módulo | Real (API) |

---

## Validação

```powershell
cd ci-api-v2; npm test -- --testPathPatterns=global-dashboard
cd ci-client-v2/apps/web; npm test -- global-dashboard GlobalWelcomeDashboard

# Smoke manual (quickstart)
# Login → /global/dashboard → KPIs reais + badge Mock no 4º KPI
# Encaminhar demanda → item no feed com link
```

## Critérios spec

| US | Status |
| --- | --- |
| US1 Perfil e identidade real | OK |
| US2 KPIs operacionais | OK |
| US3 Atividade + gráfico | OK |
| US4 Transparência mock | OK |
| US5 Atalhos sem regressão | OK |

## Dívidas / futuro

- KPI "Registros ativos (transversal)" — aguarda definição canônica cross-módulo
- Enriquecer feed com mais tipos de evento além de tramitação/notificações
