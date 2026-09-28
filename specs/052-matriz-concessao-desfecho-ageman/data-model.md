# Data Model: Matriz Concessão × Desfecho e Ajustes de Status/Encerramento (AGEMAN)

**Spec**: [spec.md](./spec.md) · **Research**: [research.md](./research.md)

Nenhuma migration Prisma nesta feature (FR/NFR herdados: sem tabela de cache, sem novo enum/coluna — ver research.md §7). Este documento descreve as **composições em tempo de consulta** e os ajustes de rótulo, não entidades persistidas novas.

## 1. `ManifestacaoStatus` (existente, inalterado)

```
draft → in_review → forwarding → answered → closed
                                           → closed_unresolved
                                           → closed_meio_juridico
```

- `in_review`: rótulo muda de "Em análise" para **"Pendente"** (FR-005), em todos os pontos listados em `research.md` §3. Transições de estado **não mudam**.
- `closed_unresolved`: continua existindo como valor de status; deixa de ser **alcançável via `desfecho: 'pendente'`** no encerramento (FR-003) — só resta alcançável, se ainda necessário, pelo caminho legado `houveResolucao: false` sem `desfecho` explícito (decisão de implementação: manter ou não esse fallback é detalhe de `tasks.md`, sem impacto de produto, pois a UI atual (`ManifestacaoActionDialogs.tsx`) sempre envia `desfecho`).
- `closed_meio_juridico`: inalterado.

## 2. `ManifestacaoDesfechoEncerramento` (enum Zod/TS, existente — restringido)

**Antes**: `'resolvida' | 'meio_juridico' | 'pendente'`
**Depois (FR-003)**: `'resolvida' | 'meio_juridico'`

Afeta:
- `ci-api-v2/src/modules/ouvidoria/ouvidoria.schemas.ts` → `manifestacaoDesfechoEncerramentoSchema`
- `ci-api-v2/src/modules/ouvidoria/lib/manifestacao-desfecho.ts` → `MANIFESTACAO_DESFECHO_ENCERRAMENTO`, `statusFromDesfechoEncerramento` (remove branch `'pendente'`)
- `ci-client-v2/apps/web/src/modules/ouvidoria/lib/manifestacao-desfecho-copy.ts` → `MANIFESTACAO_DESFECHO_ENCERRAMENTO`, `DESFECHO_ENCERRAMENTO_UI`, `DESFECHO_ENCERRAMENTO_OPTIONS`

## 3. Matriz Concessão × Desfecho (composição, não persistida)

**Fonte**: `Manifestacao` filtrada por `createdAt` no período (`year`/`month`, mesma regra de cohort do relatório 042/049/050), agrupada por:

1. **Concessão**: `sqlMapProgramaConcessaoCase(programa)` com fallback `NULLIF(TRIM(serviceMode), '')`, senão `'Não informado'` (reaproveita `mapProgramaConcessao` de `lib/map-programa-concessao.ts`) — **com uma correção de rótulo**: o valor bruto `'Zona Azul'` retornado pelo `CASE` para o código `'5'` MUST ser reescrito para `'Estacionamento Rotativo (Zona Azul)'` via `normalizeConcessaoSqlLabel` (novo `lib/concessao-label.ts`) antes de compor a linha — ver `research.md` §5. Não altera o `CASE` em si nem `AGEMAN_PROGRAMA_LABEL` (evita regressão em `porMotivo`/`porTipoManifestacao` e no endpoint público `ListProgramasPublicosUseCase`).
2. **Desfecho** (4 colunas por linha, ver contrato):
   - `resolvidaPelaAgeman`: `status IN ('answered', 'closed')`
   - `meioJuridico`: `status = 'closed_meio_juridico'`
   - `pendente`: `status NOT IN ('answered','closed','closed_unresolved','closed_meio_juridico')` (= aberta, FR-001a — mesma regra de `demandasPendentes.naoFinalizadas`)
   - `pendenteEncerradaLegado`: `status = 'closed_unresolved'` (bucket legado, FR-004 — mesma regra de `resolutividade.pendentes`/`kpis.desfechoPendentes`). Rótulo de exibição da coluna: **"Pendente (desfecho)"** — mesmo texto já usado hoje em `STATUS_OPTIONS` para o status `closed_unresolved` (não introduzir um terceiro rótulo, ver research.md §7 consolidado).

```
ConcessaoPorDesfechoRow = {
  concessao: string            // rótulo canônico ou "Não informado"
  resolvidaPelaAgeman: number
  meioJuridico: number
  pendente: number
  pendenteEncerradaLegado: number
  total: number                 // soma das 4 colunas acima
}
```

Linhas com todas as colunas zeradas **são mantidas** (FR-002: toda concessão canônica aparece, mesmo com zero no período) — diferente da regra `omitZeroSeries` usada em séries mensais; aqui a dimensão é a concessão (finita, conhecida), não o mês.

## 4. Filtro de concessão na lista de demandas (FR-007)

Novo query param opcional em `listManifestacoesQuerySchema`:

```
concessao?: string   // um dos valores de AGEMAN_PROGRAMA_LABEL (ex.: "Água / Saneamento", "Estacionamento Rotativo (Zona Azul)") ou "Não informado"
```

**Nota de rótulo**: as opções do filtro usam `resolveConcessaoMatrizLabel` (novo `lib/concessao-label.ts`), que aplica um override local (`'5'` → `'Estacionamento Rotativo (Zona Azul)'`) sobre `AGEMAN_PROGRAMA_LABEL` — **sem** alterar `AGEMAN_PROGRAMA_LABEL` em si, para não afetar o endpoint público `ListProgramasPublicosUseCase` (spec 043, fora de escopo). Consistente com o rótulo da matriz (US1) — ver `research.md` §5.

Resolvido no repositório via a mesma expressão SQL de concessão (`sqlMapProgramaConcessaoCase`) aplicada a `programa`/`serviceMode` da linha, combinável com os filtros já existentes (`status`, `from`/`to`, etc. — todos aplicados com `AND`).

**Opções do filtro (UI)**: carregadas de um novo agregado leve — concessões distintas com pelo menos 1 manifestação no tenant (não precisa de novo endpoint dedicado; pode reaproveitar/estender uma agregação já calculada, ex. lista de chaves de `porMotivo`/`concessaoPorDesfecho` sem filtro de período, ou endpoint `metadata` já usado por outros filtros da tela — decisão de implementação em `tasks.md`). Lista vazia ⇒ controle de filtro não aparece (ver research.md §4).

## 5. Rótulos afetados pelo rename (FR-005/006) — sem mudança de dado

| Constante | Antes | Depois |
| --- | --- | --- |
| `MANIFESTACAO_STATUS_LABEL.in_review` (`ouvidoria.mapper.ts`) | `'Em análise'` | `'Pendente'` |
| `PUBLIC_MANIFESTACAO_STATUS_LABEL.in_review` (idem) | `'Em análise'` | `'Pendente'` |
| `STATUS_OPTIONS` (`ManifestacoesListPage.tsx`), valor `in_review` | `'Em análise'` | `'Pendente'` (mantém `closed_unresolved` = `'Pendente (desfecho)'`, já existente) |
| KPI card `emAnalise` (`manifestacoes-list-stats.ts`, `ManifestacoesListPage.tsx`) | rótulo `'Em análise'` | rótulo `'Pendente'` (nome interno do campo `emAnalise` pode ou não ser renomeado — decisão de `tasks.md`, sem impacto de contrato externo se mantido) |
| `mapDemandasPendentesChart` (`relatorio-gestao-mappers.ts`) linha `emAnalise` | `'Em análise'` | `'Pendente'` |
| PDF/Excel do relatório (`relatorio-gestao-pdf-sections.ts`, `export-relatorio-gestao-excel.use-case.ts`) | `'Em análise'` | `'Pendente'` |

Nenhuma dessas mudanças altera o **valor** do enum `ManifestacaoStatus.in_review` nem chaves de API (`emAnalise` como nome de campo JSON permanece, só o texto exibido muda) — evita breaking change de contrato para o mesmo release.
