# Quickstart: Insights Cedro — Ouvidoria

**Feature**: 007-ouvidoria-cedro-insights  
**Pré-requisitos**: API ouvidoria Base (003), endereço shared (006), tenant com licenças incluindo Cedro

## 1. Testes automatizados (sem banco extra)

### API

```powershell
cd c:\ci-v2\ci-api-v2
npm test
npm run test:e2e -- --testPathPattern=ouvidoria-insights
```

**Esperado**: todos unit + integration + e2e passam com mocks Prisma.

### Client

```powershell
cd c:\ci-v2\ci-client-v2\apps\web
npm run test -- insights
npm run typecheck
```

**Esperado**: contract + component + integration + e2e Vitest passam com MSW.

---

## 2. Validação manual (dev com Postgres real)

### Subir stack

```powershell
cd c:\ci-v2\ci-api-v2
npm run start:dev

cd c:\ci-v2\ci-client-v2
npm run dev
```

### Seed de manifestações

Registrar ≥ 10 manifestações confirmadas via UI **ou** rodar `npm run prisma:seed` no `ci-api-v2` (18 manifestações + 7 insights no tenant `demo`).

### Insights

1. Login usuário setor Ouvidoria
2. Navegar `/ouvidoria/insights`
3. Acionar **Consultar IA**
4. Verificar:
   - Fonte *Dados internos — Ouvidoria* em todos os cards
   - Badge **Somente leitura**
   - Impacto Crítico/Alto/Médio
   - *De onde veio este insight?* abre sheet (~85% altura)
   - Sheet **sem** referências a Fala.BR/NLP
5. Histórico: após 2 gerações, comparar lotes anteriores
6. Throttle: segundo *Consultar IA* na mesma hora → mensagem clara

### Acesso negado

Usuário sem setor Ouvidoria → `403` em API ou tela 403 no client.

---

## 3. Checklist SC da spec

| SC | Como validar |
|----|----------------|
| SC-001 | Overview → Insights em ≤ 3 cliques |
| SC-002 | Zero fonte externa na UI e trace API |
| SC-003 | Generate com ~1000 manifestações &lt; 30s (perf manual ou benchmark script) |
| SC-004 | Histórico com ≥ 3 gerações mostra 2 anteriores |
| SC-005 | Manifestações idênticas antes/depois de usar insights |
| SC-006 | Rastreio só via sheet |
| SC-007 | Evidências anônimas sem PII |

---

## 4. Referências

- [rest-api-ouvidoria-insights.md](./contracts/rest-api-ouvidoria-insights.md)
- [client-ouvidoria-insights-ui.md](./contracts/client-ouvidoria-insights-ui.md)
- [test-strategy.md](./contracts/test-strategy.md)
- [data-model.md](./data-model.md)
