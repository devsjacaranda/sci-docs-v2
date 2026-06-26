# Quickstart: Insights IA Cedro — Purchasing

**Feature**: 020-purchasing-insights  
**Pré-requisitos**: [018 Purchasing CRUD](../arquivados/018-purchasing-crud/spec.md) concluído, licença Cedro no tenant, submódulo `compras-insights` registrado

## 1. Testes automatizados (sem banco extra)

### API

```powershell
cd c:\ci-v2\ci-api-v2
npm test -- --testPathPatterns=compras-insights
```

**Esperado**: unit regras (8 slugs), simulador PNCP, use-cases, throttle, trace com externalQueries — todos com mocks Prisma.

### Client

```powershell
cd c:\ci-v2\ci-client-v2
npm run test --workspace=@ci/web -- --run ComprasInsights
npm run typecheck --workspace=@ci/web
```

**Esperado**: page + shared cedro + MSW passam; regressão Gabinete/Ouvidoria intacta.

---

## 2. Validação manual (dev com Postgres)

### Subir stack

```powershell
cd c:\ci-v2\ci-api-v2
npm run start:dev

cd c:\ci-v2\ci-client-v2
npm run dev
```

### Seed demo

```powershell
cd c:\ci-v2\ci-api-v2
npm run prisma:seed
```

Tenant Jacaranda: PCAs + demandas DEAE com objetos, Pesquisas de Preços e status variados (018).

### Fluxo VS-001 — Painel funcional

1. Login usuário com setor Compras + licença Cedro (`admin@jacaranda.com` ou equivalente seed)
2. Compras → **Insights IA** (`/compras/insights`) — ≤ 3 cliques desde overview
3. Verificar stats row, badge **Somente leitura**, branding **Insights IA**
4. Insights refletem demandas reais do tenant — **não** mock fixo `comp-ins-001`
5. Acionar **Consultar IA** → confirmar dialog
6. Verificar ≥ 1 insight operacional + ≥ 1 com fonte PNCP simulada (chip *Dados simulados — MVP*)
7. *De onde veio este insight?* → sheet ~85%, passos legíveis, link demanda quando aplicável

### Fluxo VS-002 — PNCP simulado e rastreio externo

1. Criar demanda com objeto *Aquisição de equipamentos de informática* + Pesquisa de Preços
2. **Consultar IA**
3. Localizar insight de referência externa
4. Abrir rastreio → seção *PNCP/COMPRASNET — simulado* com objeto, mediana, faixa, fornecedores fictícios
5. Confirmar disclaimer de integração não ativa

### Fluxo VS-003 — Histórico e throttle

1. Acionar **Consultar IA** novamente (&lt; 1h) → mensagem throttle clara (FR-009)
2. Após 3 gerações, abrir histórico → comparar ≥ 2 lotes anteriores

### Fluxo VS-004 — Estados vazios e governança

1. Tenant/usuário sem demandas → estado vazio *registre demandas* — zero insights fabricados
2. Usuário sem módulo Compras → **403 · Acesso negado**
3. Comparar registro demanda antes/depois de Consultar IA → **inalterado** (SC-004)

### Fluxo VS-005 — Exportação (P2)

1. Com geração existente, acionar **Exportar relatório**
2. Verificar download HTML com insights, data, badge consultivo, disclaimer PNCP
3. Sem geração → orientação para gerar primeiro

---

## 3. Checklist SC

| SC | Validação |
|----|-----------|
| SC-001 | Overview Compras → Insights ≤ 3 cliques |
| SC-002 | Consulta simulada ≤ 5s percebidos |
| SC-003 | 100% insights com rastreio via sheet |
| SC-004 | Zero alteração em demandas/artefatos pós-Cedro |
| SC-005 | 2º recálculo &lt; 1h → throttle claro |
| SC-006 | Tenant sem demandas → empty orientador |
| SC-007 | Export ≤ 30s com até 20 insights |
| SC-008 | Demo ponta a ponta ≤ 10 min (criar demanda → insights → PNCP → rastrear → exportar) |

---

## 4. Referências

- [data-model.md](./data-model.md) — slugs e trace payload
- [contracts/rest-api-compras-insights.md](./contracts/rest-api-compras-insights.md) — endpoints
- [contracts/client-compras-insights-ui.md](./contracts/client-compras-insights-ui.md) — UI
- [018 quickstart](../arquivados/018-purchasing-crud/quickstart.md) — seed demandas base
