# Research: Série histórica — Relatório de Gestão (050)

**Date**: 2026-09-24

## 1. API: endpoint dedicado vs. `modo=historico` no GET principal

**Decision**: **`GET /ouvidoria/relatorio-gestao/serie-historica`** (+ export Excel sibling). Não adicionar `modo=historico` ao `GET /ouvidoria/relatorio-gestao`.

**Rationale**:

- O GET principal já monta dezenas de blocos; incluir grades 12×(N anos) no “acumulado geral” duplicaria trabalho e arriscaria SC-005 (5s) na rota mais usada.
- Lazy load na UI (aba “Série histórica”) mapeia 1:1 para uma rota dedicada — padrão já usado implicitamente quando 049 faz orientações ignorarem filtro (dado pesado separado do recorte).
- Exports por período permanecem estáveis; Excel histórico não infla o export padrão.

**Alternatives considered**:

- `?modo=historico` no mesmo GET: rejeitado — acoplamento e regressão de performance no default.
- GraphQL / BFF agregador: rejeitado — fora do stack REST do módulo.

## 2. Shape da grade (paridade planilha)

**Decision**: Estrutura tabular explícita no JSON:

- `years: number[]` — cabeçalho de colunas (ordenado ASC).
- `rows: { month: 1..12, label: string, byYear: Record<string, number>, totalAcumulado: number, percentual: number }[]`.
- `totals: { byYear: Record<string, number>, grandTotal: number }`.

**Rationale**: Facilita renderização shadcn `Table` sticky header, export Excel linha a linha, e testes Vitest com fixture fixa. Percentual = `totalAcumuladoPorMes / grandTotal` (0 se grandTotal = 0), alinhado à planilha (fração 0–1 ou % na UI — contrato usa 0–1).

**Alternatives considered**:

- Matriz `number[][]` sem metadados: rejeitado — frágil para anos esparsos e i18n de mês.

## 3. Resolutividade e concessão (P2)

**Decision**: Grades **somente eixo ano** (linhas × colunas ano), reutilizando classificadores dos repositories 042 (`get-relatorio-gestao-*`).

**Rationale**: RESUMO GERAL linhas 26–38 já atendem gestão; matriz mês×ano de resolutividade (QUANT_MENSAL) triplica volume de células e duplica lógica de status — adiada a P3.

**Concessão**: Agrupar por taxonomia de concessionária já exposta no relatório (`Manifestacao` + catálogo), não por combinação mês×concessão (sheet 7).

## 4. Forma de atendimento — fora do MVP

**Decision**: Não incluir na 050 v1.

**Rationale**: Planilha usa canais (Presencial, Call center, WhatsApp, Fala.br) por **mês×ano**; o bloco “Forma” da 042 usa `interna`/`sem_canal`. A 049 alinha “Canal de atendimento” na ficha — até cobertura ≥ ~90% nos tenants alvo, a grade geraria colunas “Não informado” dominantes. Spec futura ou 050 v2 após métrica de qualidade de dado.

## 5. Performance (FR-013, sem cache)

**Decision**:

- 1–3 consultas SQL agregadas por bloco (`GROUP BY EXTRACT(YEAR FROM createdAt), EXTRACT(MONTH FROM createdAt)` para atendimentos; `GROUP BY year` + dimensão para P2).
- Reutilizar índice composto `(tenantId, createdAt)` se SC-005 falhar em implementação (mesma mitigação T056 da 042).
- Paralelizar repositories no use-case com `Promise.all` (mesmo orquestrador pattern).
- **Não** materialized view, **não** tabela `RelatorioGestaoSnapshot`.

**Volume de referência**: ~5.331 manifestações AGEMAN acumulado — ~108 células na grade atendimentos (12×9 anos) + linha totais; trivial em CPU; custo dominante = scan indexado por tenant.

**Alternatives considered**:

- Pré-agregar na migração 041: rejeitado — viola FR-013 e FR-003 on-demand.
- Cache Redis TTL: rejeitado — mesma restrição.

## 6. Dependências entre specs

| Spec | Relação |
|------|---------|
| 042 | Base obrigatória — blocos e use-case orquestrador |
| 041 | Histórico 2018+ — dados |
| 049 | Não bloqueia MVP US1; desbloqueia forma/canal futuro |
| 048+ | Sem impacto |
