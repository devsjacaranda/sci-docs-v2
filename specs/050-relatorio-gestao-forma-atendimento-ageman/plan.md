# Implementation Plan: Forma de atendimento no Relatório de Gestão (AGEMAN gap 2)

**Branch**: `050-relatorio-gestao-forma-atendimento-ageman` | **Date**: 2026-09-24 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `civ2-docs/specs/050-relatorio-gestao-forma-atendimento-ageman/spec.md`

## Summary

Corrigir a agregação **`porFormaAtendimento`** (spec 042), hoje baseada em `origem`/`dadosAdicionais.formaAtendimento` e produzindo `interna`/`sem_canal` no tenant AGEMAN, para usar **`Manifestacao.serviceMode`** com fallback `'Não informado'`. Uma alteração em `dashboard.repositories.ts` alinha relatório de gestão, exports (PDF/Excel) e dashboards Ouvidoria/Diretor. Frontend deixa de rotular só `interna`/`sem_canal` e reutiliza `labelFormaAtendimento`. Rollup opcional (P2) para buckets `FORMAS ATENDIMENTO_GRAF` fica na camada de apresentação AGEMAN.

## Technical Context

**Language/Version**: TypeScript — NestJS 11 (API) / React 19 (client)

**Primary Dependencies**: Prisma `$queryRaw`, Zod (contratos existentes), PDFKit/ExcelJS (exports — sem mudança de estrutura, só dados)

**Storage**: PostgreSQL — **sem migration**

**Testing**: Jest — `dashboard-agregacoes.use-case.spec.ts`, `get-relatorio-gestao.use-case.spec.ts`, export specs; Vitest — `OuvidoriaRelatorioGestaoPage`, `forma-atendimento-label`, `dashboard-mappers`, Diretor mappers

**Target Platform**: `ci-api-v2` + `ci-client-v2/apps/web` (+ `modules/diretor` consumidor passivo)

**Performance Goals**: Herda 042/049 — p95 ≤ 5s, exports ≤ 30s

**Constraints**: TDD obrigatório; sem cache persistente; multi-tenant via ALS

**Scale/Scope**: ~372 manifestações AGEMAN atuais; query idêntica em complexidade à atual

## Constitution Check

| Princípio | Avaliação |
|-----------|-----------|
| Spec-Driven | Spec 050 + research + contrato antes de implement |
| Test-First | RED em repository/use-case antes de alterar SQL |
| Stack fixa | Sem deps novas |
| Multi-tenant | `tenantId` na query existente |
| Modularidade | Preferir extrair expressão SQL para helper compartilhado se orientações já usa padrão similar |

**PASS** — sem violações.

## Project Structure

### Documentation

```text
civ2-docs/specs/050-relatorio-gestao-forma-atendimento-ageman/
├── spec.md
├── plan.md
├── research.md
├── data-model.md
├── contracts/forma-atendimento-relatorio-gestao.md
└── tasks.md
```

### Source (implementação futura)

```text
ci-api-v2/src/modules/ouvidoria/
├── repository/dashboard.repositories.ts          # ALTERA query porFormaAtendimento
├── lib/
│   ├── forma-atendimento-aggregate.sql.ts        # NOVO (opcional) — expressão COALESCE serviceMode
│   └── ageman-relatorio-forma-rollup.ts          # NOVO (P2) — mapa bucket planilha
└── test/
    ├── use-cases/dashboard-agregacoes.use-case.spec.ts
    └── use-cases/get-relatorio-gestao.use-case.spec.ts

ci-client-v2/apps/web/src/modules/ouvidoria/
├── pages/OuvidoriaRelatorioGestaoPage.tsx        # ALTERA — usar labelFormaAtendimento
├── lib/forma-atendimento-label.ts                # REVISAR comentário (remove referência origem SQL)
├── lib/relatorio-gestao-mappers.ts               # já usa label — validar
└── __tests__/...
```

## Fases de entrega

### Phase A — Backend (P1)

1. Teste falhando: mock/raw query espera `serviceMode` → `Presencial`, não `interna`.
2. Substituir SELECT `forma` em `dashboard.repositories.ts` (linhas ~137–141) por expressão `serviceMode` + `'Não informado'`.
3. Atualizar fixtures em todos os specs que assertam `forma: 'telefone'` ou `interna`.
4. PDF sections: aplicar label humanizado na renderização (opcional se API já envia descrição legível).

### Phase B — Frontend (P1)

1. Remover `FORMA_ATENDIMENTO_LABELS` local em `OuvidoriaRelatorioGestaoPage.tsx`; usar `labelFormaAtendimento` (já usado em `relatorio-gestao-mappers` / `dashboard-mappers`).
2. Atualizar testes de página com formas reais (`Aplicativos de mensagem`).
3. Smoke Diretor: fixture `porFormaAtendimento` coerente.

### Phase C — Rollup AGEMAN (P2, opcional)

1. Função pura + testes Vitest/Jest com tabela D2.
2. Toggle ou segundo card "Visão planilha" no relatório AGEMAN *(produto)*.

## Validação manual (AGEMAN)

1. `GET /ouvidoria/relatorio-gestao?year=2026` — bloco Forma sem `interna`.
2. Comparar soma `porFormaAtendimento` com SQL de sanity em `research.md` §6.
3. Export PDF bloco `porFormaAtendimento` — rótulos legíveis.
4. Dashboard Ouvidoria — gráfico forma alinhado.

## Riscos

| Risco | Mitigação |
|-------|-----------|
| Testes legados esperam `telefone`/`interna` | Atualizar fixtures para `serviceMode` real |
| 13 registros sem `serviceMode` | "Não informado" — comunicar cliente |
| Confusão canal vs forma | Documentar em release note; unificar copy fora de escopo |

## Dependências

- Nenhuma bloqueante com 049 (blocos independentes).
- Beneficia-se de 049 merged para evitar conflito em `OuvidoriaRelatorioGestaoPage.tsx` — resolver conflitos de merge se necessário.
