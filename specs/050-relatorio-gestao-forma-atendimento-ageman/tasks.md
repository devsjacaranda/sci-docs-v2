# Tasks: Forma de atendimento no Relatório de Gestão (AGEMAN gap 2)

**Input**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `contracts/forma-atendimento-relatorio-gestao.md`

**Tests**: TDD obrigatório (Constitution II).

## Format: `[ID] [P?] [Story] Description`

- **[P]**: paralelo (arquivos distintos)
- **US1**: formas reais no relatório · **US2**: dashboard/Diretor · **US3**: rollup planilha (P2)

---

## Phase 1: Setup

- [ ] T001 Confirmar branch `050-relatorio-gestao-forma-atendimento-ageman` e ambiente local (`ci-api-v2` + `ci-client-v2`); tenant AGEMAN com manifestações e catálogo de formas seedado

---

## Phase 2: User Story 1 — Relatório e exports (Priority: P1)

**Goal**: `porFormaAtendimento` agrupa por `serviceMode`; exports refletem o JSON.

**Independent Test**: `get-relatorio-gestao.use-case.spec.ts` + sanity SQL AGEMAN (`research.md` §6).

### Tests (RED primeiro)

- [ ] T002 [P] [US1] Atualizar/criar teste em `ci-api-v2/src/modules/ouvidoria/test/use-cases/get-relatorio-gestao.use-case.spec.ts` — fixture dashboard com `forma: 'Aplicativos de mensagem'`; assert que **não** retorna `interna`/`sem_canal`
- [ ] T003 [P] [US1] Atualizar `ci-api-v2/src/modules/ouvidoria/test/use-cases/export-relatorio-gestao-excel.use-case.spec.ts` e `export-relatorio-gestao-pdf.use-case.spec.ts` / `relatorio-gestao-pdf-sections.spec.ts` com formas de catálogo
- [ ] T004 [P] [US1] Atualizar `ci-client-v2/apps/web/src/modules/ouvidoria/__tests__/OuvidoriaRelatorioGestaoPage.test.tsx` — mock `porFormaAtendimento` com `Aplicativos de mensagem`; expect label humanizado, não "Interna"

### Implementation

- [ ] T005 [US1] Alterar query `porFormaAtendimento` em `ci-api-v2/src/modules/ouvidoria/repository/dashboard.repositories.ts` — `COALESCE(NULLIF(TRIM("serviceMode"), ''), 'Não informado') AS forma` (remover `dadosAdicionais`/`origem`) — depende T002–T004 falhando
- [ ] T006 [P] [US1] *(Opcional)* Extrair expressão SQL para `ci-api-v2/src/modules/ouvidoria/lib/forma-atendimento-sql.ts` (constante ou fragmento documentado) se facilitar teste/reuso
- [ ] T007 [US1] Revisar `ci-api-v2/src/modules/ouvidoria/lib/relatorio-gestao-pdf-sections.ts` — exibir rótulo via helper compartilhado ou `label` server-side mínimo (mesmo texto que UI) para PDF bloco Forma
- [ ] T008 [US1] Rodar `npm test -- --testPathPatterns=relatorio-gestao|dashboard-agregacoes` em `ci-api-v2`

### Frontend relatório

- [ ] T009 [US1] Em `ci-client-v2/apps/web/src/modules/ouvidoria/pages/OuvidoriaRelatorioGestaoPage.tsx`, remover mapa local `FORMA_ATENDIMENTO_LABELS` / `formaAtendimentoLabel`; usar `labelFormaAtendimento` de `forma-atendimento-label.ts` (alinhar com `relatorio-gestao-mappers.ts`)
- [ ] T010 [P] [US1] Atualizar comentário em `forma-atendimento-label.ts` — documentar que API agora envia `serviceMode`, não códigos `interna`/`sem_canal`
- [ ] T011 [US1] Vitest: `apps/web` — `OuvidoriaRelatorioGestaoPage`, `relatorio-gestao-mappers`, `forma-atendimento-label`

**Checkpoint US1**: Relatório + PDF/Excel bloco forma OK no AGEMAN.

---

## Phase 3: User Story 2 — Dashboard Ouvidoria e Diretor (Priority: P1)

**Goal**: Mesma série em dashboard e Diretor.

### Tests

- [ ] T012 [P] [US2] Atualizar `ci-api-v2/src/modules/ouvidoria/test/use-cases/dashboard-agregacoes.use-case.spec.ts` — `forma` = valores `serviceMode`
- [ ] T013 [P] [US2] Atualizar `ci-client-v2/apps/web/src/modules/ouvidoria/__tests__/dashboard-mappers.test.ts` e `ci-client-v2/apps/web/src/modules/diretor/lib/__tests__/diretor-ouvidoria-mappers.test.ts` + `DiretorPage.test.tsx` fixtures

### Implementation

- [ ] T014 [US2] Verificar `get-dashboard-agregacoes.use-case.ts` — nenhuma transformação extra em `porFormaAtendimento` além do repository (ajustar só se houver)
- [ ] T015 [US2] Confirmar `mapPorFormaChart` / Diretor mappers aplicam `labelFormaAtendimento` — ajustar testes apenas se necessário

**Checkpoint US2**: Dashboard = relatório para `porFormaAtendimento`.

---

## Phase 4: User Story 3 — Rollup planilha AGEMAN (Priority: P2, opcional)

**Goal**: Visão buckets `FORMAS ATENDIMENTO_GRAF` na UI (client-side).

### Tests

- [ ] T016 [P] [US3] Criar `ci-api-v2/src/modules/ouvidoria/lib/ageman-relatorio-forma-rollup.spec.ts` *(ou client `__tests__/ageman-forma-rollup.test.ts`)* — tabela D2 completa

### Implementation

- [ ] T017 [US3] Implementar `rollupFormaAtendimentoAgeman(forma: string): BucketPlanilhaAgeman` conforme `research.md` D2
- [ ] T018 [US3] *(Opcional UI)* Segundo gráfico ou toggle em `OuvidoriaRelatorioGestaoPage` — agregar `porFormaAtendimento` client-side por bucket; só tenant AGEMAN ou flag de produto

---

## Phase 5: Polish

- [ ] T019 [P] Atualizar `civ2-docs/specs/README.md` — entrada 050 forma-atendimento (se ainda não listada)
- [ ] T020 Validar manual AGEMAN conforme `plan.md` § Validação manual; anotar divergência vs planilha histórica (volume parcial 2026 vs acumulado 2018–2026)
- [ ] T021 `/speckit-complete` após merge — arquivar spec

---

## Dependencies

```text
T002–T004 (RED) → T005 (SQL) → T008–T011
T005 → T012–T015 (US2 reutiliza mesmo repository)
T016 → T017 → T018 (P2 opcional, após US1)
```

## Parallel example

```text
T002 + T003 + T004 + T012 + T013 em paralelo (RED)
T009 + T010 após T005
```
