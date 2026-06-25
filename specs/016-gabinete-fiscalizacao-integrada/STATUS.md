# Status: Fiscalização de Gestão — Gabinete (Jatobá)

| Campo | Valor |
|-------|-------|
| **Status** | MVP+ entregue — Phase 12 concluída; dívidas ToastProvider/MSW/typecheck resolvidas |
| **Concluída em** | 2026-06-24 |
| **Spec** | [spec.md](./spec.md) |
| **Plano** | [plan.md](./plan.md) |
| **Tasks** | [tasks.md](./tasks.md) — T001–T085 + T086–T090 (Phase 12) |

## Entregas

### API (`ci-api-v2/src/modules/gabinete-fiscalizacao/`)

- Enum `FiscalizedEntityType` (6 tipos) + migration + persistência `entityType`/`entityId`/`demandaId`
- Loaders: atos (`load-atos-for-fiscalizacao`) + órfãos (`load-orphan-cadastros-for-fiscalizacao`)
- Agregação worst-of (`aggregate-ato-with-links`) + orquestrador `run-checks-for-ato` / `run-checks-for-orphan`
- 10+ rule modules: deadline, forwarding, completeness, evidence, protocol, controle-numerico, notificacao, auto-infracao, pairing, documento-tramitado
- Use-cases: run (full + scoped), panel, runs list, trace (check/finding/result), record
- Use-cases questions/questionnaires (API wiring no controller)
- Throttle 1h + job agendado + guards `@RequireModulo('gabinete')` + `@RequireLicenca('jatoba')`
- Fixtures API com **todos os 6 entityTypes** em `fiscalizacao-run-completed.json`
- Seed Gabinete questions em `seed-fiscalizacao-questions-gabinete.ts`

### Client (`ci-client-v2/apps/web/src/modules/`)

- `FiscalizacaoPanel` compartilhado com `moduleConfig` (Ouvidoria intacta nos testes de componente/integração)
- `GabineteAuditoriaPage` — painel funcional, histórico, trace sheets, badge Somente leitura
- `GabineteFiscalizacaoRecordCard` + scoped run no detalhe do ato
- API client + mappers + fixtures + MSW `gabinete-fiscalizacao.ts`
- Fixture MSW `fiscalizacao-panel-completed.json` alinhada com API (6 entityTypes; `resultId` em UUID válido para Zod client)

## Validação automatizada (Phase 12 — T088)

Executado em 2026-06-24:

```powershell
cd ci-api-v2
npm test -- --testPathPatterns=gabinete-fiscalizacao          # 76 passed, 26 suites
npm run test:e2e -- --testPathPatterns=gabinete-fiscalizacao  # 7 passed

cd ci-client-v2
npm test --workspace=@ci/web -- --run GabineteAuditoria      # 4 passed
npm test --workspace=@ci/web -- --run fiscalizacao           # 16 passed
npm test --workspace=@ci/web -- --run OuvidoriaAuditoria     # 7 passed (integration 4 + e2e 3)
npm run typecheck --workspace=@ci/web                        # OK
```

### Regressão Ouvidoria (T087)

```powershell
cd ci-api-v2
npm test -- --testPathPatterns=ouvidoria-fiscalizacao          # 25 passed

cd ci-client-v2
npm test --workspace=@ci/web -- --run FiscalizacaoPanel      # 3 passed
npm test --workspace=@ci/web -- --run OuvidoriaAuditoria     # 7 passed
```

**Resultado T087:** `FiscalizacaoPanel` com `moduleConfig` **não quebrou** Ouvidoria — componente (3/3), integração (4/4) e e2e (3/3) verdes.

## Validação VS (T089) — cobertura automatizada vs QA manual

| Cenário | Descrição | Cobertura |
|---------|-----------|-----------|
| VS-001 | Painel vazio → primeira execução | **Coberto por teste automatizado** — client `GabineteAuditoriaPage.e2e.test.tsx` (E2E-GAB-FIS-UI-002 empty + E2E-GAB-FIS-UI-003 CTA); `OuvidoriaAuditoriaPage.e2e.test.tsx` (E2E-FIS-UI-002); API `run-fiscalizacao.use-case.spec.ts`, e2e `E2E-GAB-FIS-005`. **Requer QA manual** para fluxo completo com Postgres + seed Jacaranda. |
| VS-002 | Ato com prazo vencido + rastreio | **Coberto por teste automatizado** — API `deadline.rules.spec.ts`, `get-check-trace.use-case.spec.ts`; client `FiscalizacaoTraceSheet.test.tsx`; fixture painel com achado *Prazo concessionária excedido*. **Requer QA manual** para abrir sheet no browser. |
| VS-003 | Pareamento notificação/auto órfão | **Coberto por teste automatizado** — API `pairing.rules.spec.ts`, `run-checks-for-orphan.spec.ts`, `gabinete-fiscalizacao.schemas.spec.ts`; fixture MSW/API com finding *Notificação sem auto pareado* (`entityType: notificacao`). **Requer QA manual** com cadastro real no tenant. |
| VS-004 | Throttle < 1h | **Coberto por teste automatizado** — API `throttle.spec.ts`, e2e `E2E-GAB-FIS-006`; client `OuvidoriaAuditoriaPage.e2e.test.tsx` (E2E-FIS-UI-003). **Requer QA manual** para segunda execução Gabinete no browser. |
| VS-005 | Read-only SC-005 | **Coberto por teste automatizado** — e2e API `E2E-GAB-FIS-007 / SC-005` (sem `cabinetDemanda.update`); client badge *Somente leitura* em `GabineteAuditoriaPage.e2e.test.tsx` e `GabineteFiscalizacaoRecordCard.test.tsx`. **Requer QA manual** para snapshot de campos operacionais antes/depois. |
| VS-006 | Card detalhe do ato + scoped run | **Coberto por teste automatizado** — client `GabineteFiscalizacaoRecordCard.test.tsx` (3 tests); API `get-fiscalizacao-record.use-case.spec.ts`, `run-fiscalizacao.use-case.spec.ts` (scoped `on_record`). **Requer QA manual** para *Fiscalizar dados* no detalhe `/gabinete/atos/:id`. |
| VS-007 | Questionário interno + histórico | **Coberto por teste automatizado** — API `create-questionnaire.use-case.spec.ts`, `submit-questionnaire-answers.use-case.spec.ts`; MSW handler questionários/respostas. **Requer QA manual** para fluxo UI *Novo questionário* → responder → histórico no painel. |
| VS-008 | Histórico comparável ≥ 3 runs | **Coberto parcialmente** — API `list-fiscalizacao-runs.use-case.spec.ts`, e2e `E2E-GAB-FIS-004`; client `OuvidoriaAuditoriaPage.e2e.test.tsx` (E2E-FIS-UI-001 compara 2 runs). **Requer QA manual** para ≥ 3 execuções reais e seleção no histórico Gabinete. |
| VS-009 | Tenant só com cadastro órfão | **Coberto por teste automatizado** — API `load-orphan-cadastros-for-fiscalizacao.repository.spec.ts`, `run-checks-for-orphan.spec.ts`, `run-fiscalizacao.use-case.spec.ts`; fixture com 5 entityTypes órfãos + `cabinet_demanda`. **Requer QA manual** com tenant isolado (sem atos). |

Validação manual ponta a ponta requer stack dev (`npm run start:dev` + `npm run dev`) + seed Jacaranda — ver [quickstart.md](./quickstart.md) §2–3.

## Dívidas remanescentes

| ID | Descrição |
|----|-----------|
| **Vitest glob** | `gabinete/__tests__/fiscalizacao-mappers.spec.ts` usa `.spec.ts` — não entra no filtro vitest (`*.test.*`) |
| **US6/US7 client E2E** | `QuestionBankPanel` / fluxo questionário no painel — API pronta; cobertura UI parcial via MSW |
| **Tasks.md sync** | T023–T028 marcadas abertas mas specs existem e passam — reconciliar checklist |
| **Manual VS browser** | VS-001…VS-009 — passos finais com Postgres + browser (automação cobre regras e contratos) |

## Próximo passo Spec Kit

E2E client US6–US7 (questionários no painel), reconciliar tasks.md, QA manual quickstart nos cenários marcados *Requer QA manual*.
