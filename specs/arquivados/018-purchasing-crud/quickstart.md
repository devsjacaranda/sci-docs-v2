# Quickstart: Compras — CRUD de Demandas e Artefatos

**Feature**: 018-purchasing-crud · **Date**: 2026-06-25

Validação end-to-end pós-implementação. Detalhes: [rest-api](./contracts/rest-api-compras.md) · [client-ui](./contracts/client-compras-ui.md) · [data-model](./data-model.md)

## Prerequisites

- PostgreSQL rodando
- Migration aplicada: `cd ci-api-v2; npx prisma migrate dev`
- Seed tenant Jacaranda (com módulo Compras + DEAE): `cd ci-api-v2; npm run prisma:seed`
- API: `cd ci-api-v2; npm run start:dev`
- Client: `cd ci-client-v2; npm run dev`

### Credenciais demo

Consultar usuário vinculado ao setor **DEAE** (Compras) em [seed-jacaranda-tenant.ts](../../../ci-api-v2/prisma/seed/seed-jacaranda-tenant.ts).

| Persona | Uso |
|---------|-----|
| Servidor DEAE / Compras | Fluxo principal |
| Servidor sem módulo Compras | Teste 403 |
| Segundo tenant (se seed) | Isolamento FR-030 |

---

## 1. Listagem (`/compras`)

1. Login como usuário com acesso ao módulo Compras
2. Sidebar → **Compras** → abrir `/compras`

**Esperado**:

- Tabela com colunas **Número**, **Título**, **Objeto**, **PCA**, **Status**, **Progresso** (ex.: `2/7 preenchidos`)
- Dados reais da API — **não** mock fixo
- Filtros por PCA e status funcionais
- Botões **Gerenciar PCAs** e **Nova demanda**

---

## 2. Gestão PCA (modal/sheet)

1. Clicar **Gerenciar PCAs**
2. Criar PCA com título "PCA Quickstart 2026"
3. Verificar status **Ativo** e contagem de demandas
4. (Opcional) Encerrar PCA de teste — demandas existentes permanecem vinculadas

**Esperado**: PCA ativo aparece no seletor de `/compras/novo`; PCA encerrado **não** aparece.

---

## 3. Criar demanda (`/compras/novo`)

1. **Nova demanda** → selecionar PCA ativo
2. Preencher título e objeto → salvar

**Esperado**:

- Validação se PCA ausente
- Número sequencial atribuído
- Redirect para `/compras/:id` com status **Rascunho** e checklist 7× **Pendente**

---

## 4. Hub quebra-cabeça (`/compras/:id`)

1. Verificar cabeçalho (número, título, objeto, PCA, setor)
2. Confirmar 7 cards: DFD, ETP, Análise de Riscos, TR, Pesquisa de Preços, Dotação, Parecer
3. Clicar card pendente → navega sub-rota

**Esperado**: estados **Preenchido** / **Pendente** / **Dispensado** (ETP) refletem API.

---

## 5. Preencher artefatos (jornada mínima)

1. **DFD** — preencher 5 campos obrigatórios → salvar → hub mostra **Preenchido**; status **Em andamento**
2. **ETP** — marcar *Dispensado* + motivo → hub **Dispensado**; progresso conta ETP como satisfeito
3. **Análise de Riscos** — adicionar ≥1 risco → salvar
4. **TR**, **Pesquisa de Preços** (valor > 0), **Dotação**, **Parecer** — preencher campos obrigatórios

**Esperado**:

- Breadcrumb *Compras → Demanda #N → {artefato}*
- Checklist lateral navegável
- Após 7/7 satisfeitos → status **Concluído** automático (sem ação manual)
- Upload comprovante opcional — falha não apaga campos salvos

---

## 6. ETP — validações

1. Tentar salvar dispensado **sem** motivo → erro claro
2. Preencher ETP técnico → marcar dispensado → confirmar dialog → salvar

---

## 7. Filtros listagem

1. Com demandas em status distintos, filtrar por **Em andamento**
2. Filtrar por PCA específico

**Esperado**: resultados corretos; resposta ≤ 2s com volume seed.

---

## 8. Controle de acesso

1. Login usuário **sem** módulo Compras
2. Navegar manualmente para `/compras`

**Esperado**: 403 ou tela de acesso negado padronizada.

---

## 9. Isolamento tenant

1. Login tenant A → anotar ID demanda
2. Login tenant B → acessar `/compras/{idTenantA}`

**Esperado**: 404 — nenhum dado vazado.

---

## 10. PDF indisponível

1. No hub, acionar exportação PDF (se visível)

**Esperado**: ação desabilitada ou mensagem orientadora (FR-028).

---

## Testes automatizados

```powershell
cd ci-api-v2; npm test -- --testPathPattern=compras
cd ci-client-v2; npm test -- --filter=@ci/web -- compras
```

Estratégia completa: [test-strategy.md](./contracts/test-strategy.md)

---

## Demonstração ponta a ponta (SC-007)

Sequência alvo ≤ 20 minutos:

**Criar PCA → criar demanda → DFD → dispensar ETP → preencher 5 artefatos restantes → Concluído**
