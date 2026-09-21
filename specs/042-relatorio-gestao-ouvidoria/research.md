# Research: Relatório de Gestão da Ouvidoria

**Input**: `spec.md` (com Clarifications 2026-08-27) · Constitution v1.2.0 · Levantamento técnico do codebase (ci-api-v2 + ci-client-v2)

Este documento resolve as decisões técnicas necessárias para o Phase 1 (design). Nenhum item ficou como `NEEDS CLARIFICATION` — todas as dúvidas de produto já foram resolvidas no `spec.md`; as decisões abaixo são puramente técnicas (arquitetura/implementação), decididas por precedente direto no próprio codebase.

## 1. Export PDF do relatório

**Decision**: Usar **PDFKit** (`pdfkit` ^0.19.1, já instalado), com renderização imperativa local ao módulo `ouvidoria` — sem HTML/Puppeteer.

**Rationale**: É a biblioteca já usada em dois lugares do mesmo módulo Ouvidoria (`generate-manifestacao-pdf.use-case.ts`) e em Diagnóstico (`generate-dashboard-pdf.use-case.ts`). Não há Puppeteer/pdfmake/react-pdf no projeto — introduzir uma nova biblioteca de PDF só para este relatório violaria a diretriz "sem débito técnico" ao criar um segundo caminho de renderização para o mesmo problema.

**Alternatives considered**:
- Puppeteer/HTML→PDF: rejeitado — dependência pesada nova, sem precedente no monorepo, risco de flakiness em ambiente serverless/CI.
- Reaproveitar diretamente os services de PDF do módulo `diagnostico` (`letterhead.service.ts`, `tables.service.ts`): rejeitado como import cross-módulo — quebraria a modularidade por domínio (constitution V). Em vez disso, replicar o padrão (não o código) dentro de `ouvidoria/lib/`, do mesmo jeito que `render-manifestacao-pdf.ts` já faz localmente.

## 2. Export Excel do relatório

**Decision**: Usar **ExcelJS** (`exceljs` ^4.4.0, já instalado), no mesmo padrão do SIGED (`export-siged-protocolos-excel.use-case.ts`): workbook em memória, 1 aba por bloco do relatório, `workbook.xlsx.writeBuffer()` → `StreamableFile`.

**Rationale**: Único gerador de Excel já existente no backend; mesma lib cobre a decisão de clarificação (arquivo consolidado simples, sem fórmulas/gráficos nativos — FR-010).

**Alternatives considered**: Nenhuma — não há outra lib de Excel no projeto e a spec já fechou o formato (consolidado, sem fórmulas).

## 3. Fonte dos dados agregados

**Decision**: Estender o padrão já existente em `dashboard.repositories.ts` (queries `$queryRaw` agrupadas por mês, com `COALESCE(NULLIF(TRIM(campo), ''), 'Não informado')` para valores ausentes — mesmo padrão já usado em `porMotivo` para `motivo`). Novas agregações (zona, bairro, tipo de manifestação, acumulado geral) seguem o mesmo arquivo/padrão, sem introduzir ORM query builder alternativo.

**Rationale**: Reuso direto de um padrão testado no mesmo domínio; evita duas formas de fazer a mesma coisa (SQL raw vs Prisma query builder) dentro do mesmo módulo.

**Alternatives considered**:
- Prisma `groupBy`: viável para zona/bairro/tipo (sem `FILTER`/`EXTRACT` complexos), mas rejeitado em favor de consistência com o padrão dominante do arquivo (todas as 7 agregações atuais usam `$queryRaw`). Manter um único estilo reduz custo cognitivo de manutenção.
- View materializada / tabela de cache: rejeitado explicitamente pela spec (FR-013) — sem justificativa de performance que exija isso na v1 (meta de 5s/30s é atingível com índices adequados em `tenantId`, `createdAt`, `addressId`).

## 4. PostgreSQL — relevância de features "PG18"

**Decision**: Não depender de nenhuma feature específica de uma versão recente do PostgreSQL. As agregações necessárias (`GROUP BY`, `EXTRACT`, `FILTER (WHERE ...)`, `COALESCE`/`NULLIF`) são suportadas desde versões antigas do Postgres (9.x+).

**Rationale**: O provider Prisma não fixa versão (`datasource db { provider = "postgresql" }`), e produção usa Neon (gerenciado, versão não fixada no repo). Depender de sintaxe exclusiva de uma versão específica seria um risco de portabilidade sem ganho real — os únicos gargalos possíveis (volume de linhas no "acumulado geral") se resolvem com índice, não com feature de versão.

**Alternatives considered**: Particionamento por ano/tenant, materialized views incrementais — descartados por over-engineering para o volume atual (maior tenant conhecido tem ~5.160 manifestações acumuladas); reavaliar apenas se um tenant real ultrapassar ordens de grandeza maiores.

## 5. Catálogo de perguntas de satisfação

**Decision**: Novo model Prisma `OuvidoriaPesquisaSatisfacaoPergunta`, seguindo exatamente o formato de `OuvidoriaFormaAtendimento` (`id Int autoincrement`, `tenantId`, `codigo`, `nome`, `ordem`, `ativo`, `deletedAt`, `createdAt`, `updatedAt`).

**Rationale**: Resolve a Clarification 1 (catálogo fixo por tenant, não configurável em runtime pelo usuário final) reaproveitando um padrão já validado em produção no mesmo arquivo `ouvidoria-catalog.prisma`.

## 6. Autorização / licença

**Decision**: A rota do relatório de gestão fica no `OuvidoriaController` existente, protegida por `@RequireModulo('ouvidoria')` (mesmo padrão do dashboard atual) — sem `@RequireLicenca` adicional. No frontend, `licenses: ['base']` no `screens.ts`, igual ao dashboard atual.

**Rationale**: FR-011 exige que o acesso siga a mesma regra das demais telas do módulo Ouvidoria, "sem exigir papel gerencial adicional" — nenhuma licença premium foi mencionada na spec. Introduzir uma licença nova sem pedido explícito do produto seria escopo não solicitado.

**Alternatives considered**: `@RequireLicenca('pau-brasil')` (usada em telas de manifestação) — descartado por falta de decisão de produto explícita; pode ser revisitado depois se o time de produto quiser monetizar o relatório separadamente.

## 7. Camada de leitura (frontend): fetch manual vs React Query

**Decision**: Seguir o padrão dominante do módulo (`useState`/`useEffect`/`useCallback` manual, como em `OuvidoriaDashboardPage.tsx` e `OuvidoriaAtendimentosPage.tsx`), não introduzir React Query nesta feature.

**Rationale**: Consistência com 100% das páginas do módulo Ouvidoria hoje (a única exceção, Diretor, é um módulo diferente). Introduzir uma segunda estratégia de data-fetching no mesmo módulo é a definição de débito técnico incremental que a spec pediu para evitar.

## Resumo de dependências

| Necessidade | Decisão | Nova dependência? |
|---|---|---|
| PDF | PDFKit (existente) | Não |
| Excel | ExcelJS (existente) | Não |
| Agregação SQL | `$queryRaw` (padrão existente) | Não |
| Catálogo satisfação | Model Prisma novo, padrão existente | Não (só migration) |
| Autorização | `@RequireModulo('ouvidoria')` (existente) | Não |
| Data-fetching frontend | `useState`/`useEffect` manual (existente) | Não |

**Nenhuma dependência nova é necessária para esta feature** — alinhado com a diretriz explícita do solicitante de evitar débito técnico e complexidade desnecessária.
