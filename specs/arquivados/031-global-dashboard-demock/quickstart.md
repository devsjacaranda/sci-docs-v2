# Quickstart: Desmock do Dashboard Global

**Feature**: 031-global-dashboard-demock

## Pré-requisitos

- PostgreSQL com seed demo (`cd ci-api-v2; npm run prisma:seed`)
- API: `cd ci-api-v2; npm run start:dev`
- Client: `cd ci-client-v2; npm run dev`
- `VITE_USE_API=true` (default) no client

## 1. Perfil real na home

1. Login com usuário seed (ex.: `maria.oliveira@instituicao.gov.br`)
2. Navegar para `/global/dashboard`
3. **Esperado**: saudação com nome/cargo do JWT; avatar de `/auth/me`
4. **Não esperado**: dados de `admin-mock` ou "Maria Oliveira" fixa se logado como outro usuário

## 2. KPIs reais vs mock

1. Com seed tramitação + ouvidoria ativo, recarregar home
2. **Esperado**:
   - "Demandas pendentes" > 0 (coerente com inbox tramitação)
   - "Atualizações (24h)" reflete eventos recentes ou 0
   - "Registros ativos (transversal)" com badge **Mock**
3. Tenant vazio: KPIs reais em 0, nunca "12" ou "4.218" fixos

## 3. API direta

```powershell
# Obter token via login, depois:
curl -s -H "Authorization: Bearer $TOKEN" -H "X-Tenant-ID: jacaranda" `
  "http://localhost:3000/global/dashboard?periodDays=30" | jq .
```

**Esperado**: JSON com `kpis[]`, `recentActivity[]`, `chart.data[]`, exatamente um KPI com `"source": "mock"`.

## 4. Atividade recente

1. Encaminhar uma demanda na tramitação (UI ou API)
2. Voltar à home
3. **Esperado**: item no feed com título de encaminhamento e link para demanda
4. Clicar → navega para `/tramitacao/demandas/:id`

## 5. Gráfico

1. Verificar título **"Demandas linked por módulo de origem"**
2. Barras proporcionais ao seed (ouvidoria, gabinete, etc.)
3. Sem badge Mock no gráfico
4. Ativar filtro de licença Cedro → barras filtradas conforme módulos visíveis

## 6. Transparência mock

1. Localizar KPI "Registros ativos (transversal)"
2. **Esperado**: badge **Mock** visível no cartão
3. Demais KPIs sem badge

## 7. Falha de rede

1. Parar API ou bloquear request
2. Recarregar home
3. **Esperado**: mensagem de erro nos blocos assíncronos; hero/branding ainda visível
4. **Não esperado**: lista `welcomeActivities` fictícia

## 8. Testes automatizados

```powershell
cd ci-api-v2; npm test -- --testPathPatterns=global-dashboard
cd ci-client-v2/apps/web; npm test -- global-dashboard
cd ci-client-v2/apps/web; npm test -- GlobalWelcomeDashboard
```

Todos devem passar antes de `/speckit-implement` complete.

## Referências

- [rest-api-global-dashboard.md](./contracts/rest-api-global-dashboard.md)
- [client-global-dashboard-ui.md](./contracts/client-global-dashboard-ui.md)
- [data-model.md](./data-model.md)
- [test-strategy.md](./contracts/test-strategy.md)
