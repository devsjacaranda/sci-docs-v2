# Tasks: 050 — Desfecho AGEMAN (gap 1)

**Spec**: [spec.md](./spec.md) · **Contrato**: [contracts/desfecho-relatorio-gestao.md](./contracts/desfecho-relatorio-gestao.md)

Ordem: T101 → T120. IDs **T1xx** reservados ao gap 1.

---

## Fase A — Schema e encerramento (backend)

- [ ] **T101** [P] [US1] Adicionar enum `ManifestacaoDesfechoEncerramento` e coluna `desfechoEncerramento` nullable em `prisma/schema/manifestacao.prisma`; gerar migration.
- [ ] **T102** [US1] Estender `encerrarBodySchema` — `desfechoEncerramento` obrigatório iff `houveResolucao === false`; testes RED em `ouvidoria.schemas.spec.ts`.
- [ ] **T103** [US1] `persist-encerramento.repository.ts` — persistir desfecho; limpar desfecho quando `closed`.
- [ ] **T104** [US1] `encerrar-manifestacao.use-case.ts` — validar combinações; testes `encerrar-manifestacao.use-case.spec.ts` (GREEN).
- [ ] **T105** [US1] Expor `desfechoEncerramento` no DTO de detalhe/listagem manifestação (se já serializado) — Zod response parse client.

## Fase B — Agregações relatório (backend)

- [ ] **T106** [US2] Helper puro `classificar-desfecho-relatorio.ts` — tabela de mapeamento status + enum + tenant default (testes unitários isolados).
- [ ] **T107** [US2] `dashboard.repositories.ts` — queries KPI `resolvidaPelaAgeman`, `meioJuridico`, `pendenteDesfecho`; série `demandasPorDesfecho` por mês (`createdAt` cohort).
- [ ] **T108** [US3] Resolver `tenantDefaultJuridico` (flag tenant/slug AGEMAN) usado em T106–T107; documentar em plan.md se constante.
- [ ] **T109** [US2] `get-dashboard-agregacoes.use-case.ts` — expor raw; ajustar tipos em `DashboardAgregacoesRaw`.
- [ ] **T110** [P] [US3] Script backfill opcional AGEMAN: `closed_unresolved` → `meio_juridico` (não bloqueante para GREEN).

## Fase C — Contrato relatório (backend)

- [ ] **T111** [US2] `ouvidoria.types.ts` + Zod response — `demandasPorDesfecho`, KPIs novos; deprecar `demandasFinalizadas` no schema relatório.
- [ ] **T112** [US2] `get-relatorio-gestao.use-case.ts` — montar payload; `omitZeroSeries` para novo bloco; **não** alterar blocos 049 (orientações/satisfação/eventos).
- [ ] **T113** [US2] `get-relatorio-gestao.use-case.spec.ts` — fixtures answered/closed/jurídico/pendente; assert percentual resolutividade se entregue.
- [ ] **T114** [US2] `relatorio-gestao-pdf-sections.ts` + specs — seção desfecho PT-BR planilha.
- [ ] **T115** [US2] `export-relatorio-gestao-excel.use-case.ts` — aba/colunas desfecho; spec export.

## Fase D — Frontend

- [ ] **T116** [US1] `ManifestacaoActionDialogs.tsx` — se `Sem resolução`, subescolha "Meio jurídico" vs "Encerrada sem resolução (outros)"; wire `workflow.ts`.
- [ ] **T117** [US1] Testes `ManifestacaoActionDialogs.test.tsx` + copy `errors.ts`.
- [ ] **T118** [US2] `relatorio-gestao.ts` types + `relatorio-gestao-mappers.ts` — gráfico três barras; KPI cards planilha.
- [ ] **T119** [US2] `OuvidoriaRelatorioGestaoPage.tsx` — substituir bloco "Resolvidas / Arquivadas OK / Arquivadas"; testes página.
- [ ] **T120** [P] Atualizar `civ2-docs/specs/README.md` com entrada 050; quickstart manual (encerrar jurídico + conferir relatório vs planilha mês 08/2026).

---

## Agent routing

| Agente | Tasks |
| --- | --- |
| **Backend** | T101–T115, T110 |
| **Frontend** | T105 (parse), T116–T119 |
| **Docs/QA** | T120, validação SC-101 contra `extracted-sheets.txt` |

## Dependências externas

- Merge **049** concluído.
- Gaps 2–4: ler [coordination-gaps-2-4.md](./coordination-gaps-2-4.md) antes de editar `get-relatorio-gestao.use-case.ts`.
