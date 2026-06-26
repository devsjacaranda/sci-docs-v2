# Quickstart: Maturidade Carvalho — Compras

**Feature**: 021-purchasing-maturidade · **Branch**: `021-purchasing-maturidade`

Guia de validação ponta a ponta. Detalhes de contrato: [contracts/](./contracts/) · modelo: [data-model.md](./data-model.md).

---

## Pré-requisitos

- Node.js 20 LTS
- PostgreSQL rodando (dev)
- Tenant Jacaranda seedado com módulo Compras + licença Carvalho
- Specs Base (018) e ideally Jatobá (019) implementadas para testar score híbrido

```powershell
cd ci-api-v2
npm install
npm run prisma:migrate
npm run prisma:seed    # inclui demandas Compras + perguntas maturidade (pós-implementação)
npm run start:dev

# Terminal separado
cd ci-client-v2
npm install
npm run dev            # → http://localhost:5173
```

Credenciais demo: ver seed Jacaranda (`prisma/seed/seed-jacaranda-tenant.ts`).

---

## Cenário 1 — Primeira autoavaliação (P1)

**Objetivo**: FR-001–003, FR-008, SC-001/002

1. Autenticar usuário com módulo Compras + licença Carvalho
2. Navegar para `/compras/maturidade`
3. Verificar empty state convidando autoavaliação — **sem** scores fabricados
4. Abrir **Responder questionário**
5. Responder parcialmente 2 perguntas → sair da tela → retornar
6. **Esperado**: respostas parciais preservadas (banner draft)
7. Completar todas obrigatórias → submeter
8. **Esperado**: score global + 4 dimensões em ≤ 3s; autor/data registrados

**API manual**:

```powershell
# Período corrente
curl -H "Authorization: Bearer $TOKEN" -H "X-Tenant-ID: $TENANT" http://localhost:3000/compras/maturidade/periods/current

# Salvar parcial
curl -X PATCH -H "Content-Type: application/json" -H "Authorization: Bearer $TOKEN" -H "X-Tenant-ID: $TENANT" -d '{"answers":[{"questionId":"...","value":"4"}]}' http://localhost:3000/compras/maturidade/self-assessment/answers

# Submeter
curl -X PUT -H "Content-Type: application/json" -H "Authorization: Bearer $TOKEN" -H "X-Tenant-ID: $TENANT" -d '{"answers":[...]}' http://localhost:3000/compras/maturidade/self-assessment
```

---

## Cenário 2 — Score híbrido Conformidade + Jatobá (P1)

**Objetivo**: FR-007, US2.5

**Pré**: Executar fiscalização Jatobá (`POST /compras/fiscalizacao/run`) com demandas não conformes

1. Submeter autoavaliação com score moderado em Conformidade
2. Abrir dashboard → dimensão **Conformidade** deve mostrar `selfAssessmentComponent` + `jatobaConformityComponent`
3. Abrir sheet **Como calculamos este score**
4. **Esperado**: fórmula 60/40 só em Conformidade; demais dimensões = autoavaliação pura
5. Tenant **sem** run Jatobá: `partialSource: true`; Carvalho **não** bloqueado

---

## Cenário 3 — Orientações de melhoria (P1)

**Objetivo**: FR-006, SC-004

1. Submeter avaliação com dimensão **Instrução processual** &lt; 60
2. **Esperado**: ≥ 1 orientação imperativa consultiva para essa dimensão
3. Dimensão ≥ 60: reconhecimento de boa prática — **sem** ação corretiva desnecessária
4. Conformidade baixa + Jatobá: orientação menciona temas agregados — **sem** protocolo de demanda

---

## Cenário 4 — Histórico e evolução (P1/P2)

**Objetivo**: FR-005, SC-003, US4

1. Submeter avaliação no período Q1 (ou simular snapshot seed)
2. Avançar/simular período Q2 → nova submissão
3. **Esperado**: lista histórica com 2 entradas; gráfico evolução visível
4. Re-submeter no **mesmo** período → substitui (sem duplicar)

---

## Cenário 5 — Exportação (P2)

**Objetivo**: FR-010, SC-006

1. Com avaliação submetida → **Exportar relatório**
2. **Esperado**: HTML imprimível com scores, orientações, data/autor em ≤ 30s
3. Sem avaliação → mensagem orientando completar autoavaliação

```powershell
curl -H "Authorization: Bearer $TOKEN" -H "X-Tenant-ID: $TENANT" http://localhost:3000/compras/maturidade/export -o maturidade.html
```

---

## Cenário 6 — Governança e read-only (P1)

**Objetivo**: FR-011, FR-012, SC-005

| Caso | Esperado |
|------|----------|
| Usuário sem módulo Compras | 403 · Acesso negado |
| Usuário sem licença Carvalho | Alerta licença padrão |
| Após submeter avaliação | Demandas/artefatos inalterados (comparar GET demanda antes/depois) |
| Licença Carvalho expirada | Histórico consultável; nova submissão bloqueada |

---

## Testes automatizados

```powershell
# API unit + integration
cd ci-api-v2
npm test -- --testPathPatterns=compras-maturidade

# API e2e
npm test -- --testPathPatterns=compras-maturidade.e2e

# Client
cd ci-client-v2/apps/web
npm test -- compras-maturidade
```

Ver [contracts/test-strategy.md](./contracts/test-strategy.md) para matriz completa.

---

## Checklist de conclusão (antes de `/speckit-complete`)

- [ ] Questionário 4 dimensões seedado no tenant demo
- [ ] PATCH parcial + PUT submit funcionando
- [ ] Score híbrido só Conformidade com/sem Jatobá
- [ ] Orientações below/above patamar 60
- [ ] Histórico ≥ 2 períodos + timeline Nivo
- [ ] Export HTML
- [ ] Guards licença/módulo
- [ ] SC-005 read-only validado
- [ ] Todos os testes verdes
