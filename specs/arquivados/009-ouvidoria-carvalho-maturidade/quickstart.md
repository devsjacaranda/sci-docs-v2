# Quickstart: Maturidade Carvalho — Ouvidoria

**Feature**: 009-ouvidoria-carvalho-maturidade  
**Pré-requisitos**: API ouvidoria Base (003), fiscalização Jatobá (008), tenant com licenças incluindo Carvalho

## 1. Testes automatizados (sem banco extra)

### API

```powershell
cd c:\ci-v2\ci-api-v2
npm test -- ouvidoria-maturidade
npm run test:e2e -- --testPathPatterns=ouvidoria-maturidade
```

**Esperado**: todos unit + integration + e2e passam com mocks Prisma.

### Client

```powershell
cd c:\ci-v2\ci-client-v2\apps\web
npm run test -- maturidade
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

### Seed

```powershell
cd c:\ci-v2\ci-api-v2
npm run prisma:seed
```

Inclui manifestações demo, fiscalização Jatobá e (após implementação) perguntas Carvalho + período trimestral.

### Maturidade — fluxo principal

1. Login usuário setor Ouvidoria (gestor)
2. Navegar `/ouvidoria/maturidade`
3. Verificar estado inicial:
   - Badge **Somente leitura**
   - Score **indisponível** se autoavaliação não respondida (SC-006)
4. Acionar **Responder autoavaliação**
5. Preencher perguntas dos 3 eixos → submeter
6. Verificar:
   - Nota geral e 3 eixos calculados (não mock 72% fixo)
   - Gráfico radar com meta 80%
   - 5 indicadores operacionais
   - *Como calculamos este score?* abre sheet (~85% altura)
   - Fórmula 60% autoavaliação + 40% Jatobá no rastreio
7. **Novo plano de ação**: criar, adicionar nota, concluir (SC-008)
8. Segundo período (seed ou avanço trimestre): evolução temporal com ≥ 2 pontos (SC-009)

### Integração Jatobá

1. Executar fiscalização em `/ouvidoria/auditoria` se run desatualizado
2. Voltar maturidade — componente Jatobá no rastreio referencia execução recente
3. Se run &gt; 48h: banner desatualização visível

### Fonte parcial

Tenant sem execução Jatobá: score usa 100% autoavaliação + badge *Fonte parcial*.

### Acesso negado

Usuário sem setor Ouvidoria → `403` API ou tela 403 client.

Usuário sem perfil gestor → planos somente leitura; POST action-plan → 403.

---

## 3. Checklist SC da spec

| SC | Como validar |
|----|----------------|
| SC-001 | Overview → Maturidade em ≤ 3 cliques |
| SC-002 | Comparar nota eixo com calculadora 0,6×self + 0,4×jatoba |
| SC-003 | Todo score tem botão rastreio |
| SC-004 | Manifestação idêntica antes/depois de usar maturidade |
| SC-005 | Rastreio só via sheet |
| SC-006 | Sem autoavaliação → score indisponível |
| SC-007 | Indicadores ≠ mock estático |
| SC-008 | CRUD plano em ≤ 10 min |
| SC-009 | ≥ 2 pontos no gráfico temporal |
| SC-010 | Chip Carvalho Crítico &lt; 70%; Atenção 70–79% |

---

## 4. Referências

- [spec.md](./spec.md)
- [data-model.md](./data-model.md)
- [rest-api-ouvidoria-maturidade.md](./contracts/rest-api-ouvidoria-maturidade.md)
- [client-ouvidoria-maturidade-ui.md](./contracts/client-ouvidoria-maturidade-ui.md)
- [test-strategy.md](./contracts/test-strategy.md)
