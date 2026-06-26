# Quickstart: Fiscalização de Compras — Purchasing (Jatobá)

**Feature**: 019-purchasing-fiscalizacao  
**Pré-requisitos**: CRUD Compras (018) concluído, tenant Jacaranda com licença Jatobá, seed demandas demo

## 1. Testes automatizados (sem banco extra)

### API

```powershell
cd c:\ci-v2\ci-api-v2
npm test -- --testPathPattern=compras-fiscalizacao
npm run test:e2e -- --testPathPattern=compras-fiscalizacao
```

**Esperado**:

- Unitário: 8 rule specs + agregação + throttle
- Integração: run persiste 1 result/demanda ativa
- E2E: guards 403, throttle 429, read-only SC-005

### Client

```powershell
cd c:\ci-v2\ci-client-v2
npm test --workspace=@ci/web -- --run ComprasFiscalizacao
npm test --workspace=@ci/web -- --run fiscalizacao-mappers
npm run typecheck --workspace=@ci/web
```

**Esperado**:

- Painel stats 4 conformidades canônicas
- Sheet títulos canônicos pt-BR
- Card demanda + scoped run

---

## 2. Validação manual (dev com Postgres)

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

Garante PCA + demandas Jacaranda DEAE (pós-018).

### Login

- `paulo@demo.com` ou `admin@jacaranda.com`
- Tenant Jacaranda · módulo Compras · licença Jatobá

---

## 3. Cenários VS (validação ponta a ponta)

### VS-001 — Painel vazio → primeira execução

1. Navegar `/compras/fiscalizacao`
2. Verificar título **Fiscalização de Compras**, badge **Somente leitura**
3. Clicar **Fiscalizar demandas**
4. Painel exibe stats, checagens e achados reais — não mock

### VS-002 — Demanda sem DFD

1. Criar demanda nova (sem preencher DFD)
2. Fiscalizar
3. Achado **Não conforme** ou **Parcial** — Completude DFD

### VS-003 — ETP dispensado

1. Demanda com ETP `waived=true` sem motivo → **Não conforme**
2. Adicionar motivo → refiscalizar → **Conforme** para checagem ETP

### VS-004 — Consistência orçamentária

1. Pesquisa de Preços `estimatedValue = 100000`
2. Dotação `allocatedValue = 80000`
3. Fiscalizar → achado **Parcial** — Consistência orçamentária

### VS-005 — Throttle

1. Fiscalizar demandas (completa)
2. Tentar novamente em < 1h
3. Toast/mensagem clara — execução anterior ainda visível

### VS-006 — Read-only (SC-005)

1. Snapshot campos demanda + DFD antes de fiscalizar
2. Executar fiscalização completa + scoped
3. Comparar — **zero** alterações operacionais

### VS-007 — Card hub (SC-008)

1. Abrir `/compras/:demandaId`
2. Card **Fiscalização Jatobá desta demanda**
3. **Fiscalizar demanda** → checagens atualizadas em ≤ 5s

### VS-008 — Jornada SC-007 (≤ 10 min)

1. Criar demanda incompleta
2. Fiscalizar → ver achado DFD
3. Completar DFD
4. Refiscalizar → achado DFD resolvido

---

## 4. Referências

- [REST contract](./contracts/rest-api-compras-fiscalizacao.md)
- [UI contract](./contracts/client-compras-fiscalizacao-ui.md)
- [Data model](./data-model.md)
- [Test strategy](./contracts/test-strategy.md)
