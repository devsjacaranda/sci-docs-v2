# Test Strategy: Módulo IT — Segurança da Informação

**Feature**: 022-it-seguranca-informacao · **Date**: 2026-06-25

TDD obrigatório (Constitution II): RED → GREEN → REFACTOR.

## Pirâmide

| Camada | Ferramenta | Foco |
|--------|------------|------|
| Unitário API | Jest | lib pura: regex, LGPD terms, risk tree, defense %, vulnerability formula, backup validation |
| Unitário Client | Vitest | mappers, chart adapters, form validation |
| Contrato | Zod round-trip + fixtures JSON | schemas ↔ exemplos contracts/ |
| Integração API | Jest + Prisma mock | use-cases isolados |
| Integração Client | Vitest + MSW | pages com handlers |
| E2E API | Supertest | fluxos HTTP principais |
| E2E Client | RTL | jornadas US1–US14 |

## Suites API (`ci-api-v2`)

### `it` (Base)

| Arquivo | Cobre |
|---------|-------|
| `it/lib/*.spec.ts` | — |
| `it/use-cases/create-ativo.use-case.spec.ts` | FR-002, soft delete |
| `it/use-cases/restore-ativo.use-case.spec.ts` | FR-003 |
| `it/use-cases/link-ativos.use-case.spec.ts` | FR-004 |
| `it/use-cases/create-incidente.use-case.spec.ts` | FR-005 |
| `it/use-cases/resolve-incidente.use-case.spec.ts` | FR-006 |
| `it/use-cases/get-dashboard.use-case.spec.ts` | FR-008, SC-003 |
| `it/use-cases/apply-sensitive-flag.use-case.spec.ts` | FR-014, SC-011 |
| `test/it.e2e-spec.ts` | CRUD + dashboard |

### `it-insights` (Cedro)

| Arquivo | Cobre |
|---------|-------|
| `it-insights/lib/config-scan.spec.ts` | FR-011–012, SC-004 |
| `it-insights/lib/lgpd-classifier.spec.ts` | FR-013, SC-005 |
| `it-insights/lib/risk-matrix-tree.spec.ts` | FR-015, SC-006 |
| `it-insights/use-cases/*.spec.ts` | read-only guard |
| `test/it-insights.e2e-spec.ts` | classify + evaluate |

### `it-fiscalizacao` (Jatobá)

| Arquivo | Cobre |
|---------|-------|
| `it-fiscalizacao/lib/backup-validation.spec.ts` | FR-018 |
| `it-fiscalizacao/repository/it-audit-trail.repository.spec.ts` | FR-020, SC-008 (no delete) |
| `it-fiscalizacao/use-cases/submit-backup-evidence.spec.ts` | FR-017–018 |
| `it-fiscalizacao/use-cases/generate-anpd-notification.spec.ts` | FR-022, SC-009 |
| `it-fiscalizacao/jobs/backup-audit-scheduled.job.spec.ts` | cron alerta |
| `test/it-fiscalizacao.e2e-spec.ts` | audit trail + ANPD |

### `it-maturidade` (Carvalho)

| Arquivo | Cobre |
|---------|-------|
| `it-maturidade/lib/defense-lines.spec.ts` | FR-024–025 |
| `it-maturidade/lib/framework-adherence.spec.ts` | FR-026, SC-010 |
| `it-maturidade/lib/vulnerability-index.spec.ts` | FR-027 |
| `test/it-maturidade.e2e-spec.ts` | dashboard read-only |

## Suites Client (`ci-client-v2/apps/web`)

| Arquivo | Cobre |
|---------|-------|
| `modules/it/__tests__/it.contract.test.ts` | Zod API responses |
| `modules/it/__tests__/ItAtivosListPage.integration.test.tsx` | §4 layout, menu ⋮ |
| `modules/it/__tests__/ItInsightsPage.integration.test.tsx` | badge Somente leitura, Aplicar classificação |
| `modules/it/__tests__/ItFiscalizacaoPage.integration.test.tsx` | backup form, audit trail |
| `modules/it/__tests__/ItMaturidadePage.integration.test.tsx` | charts, trace sheet |
| `modules/it/__tests__/it.e2e.test.tsx` | jornada ponta a ponta SC-012 |

## Casos críticos (must-pass antes merge)

1. **SC-011**: insight Cedro não altera `containsSensitiveData` até POST apply-sensitive-flag
2. **SC-008**: repository audit trail rejeita delete (test explícito)
3. **R-20**: fiscalização backup não PATCH ativo fields além de status backup
4. **403**: sem licença Cedro/Jatobá/Carvalho nos prefixos corretos
5. **UI condicional**: ANPD oculto para incidente non-critical (R-10)

## Fixtures

`ci-api-v2/src/modules/it/test/fixtures/` — ativos, incidentes, dicionário com termos sensíveis, config com `port: 21`.

## Comandos

```powershell
cd ci-api-v2
npm test -- --testPathPatterns=it

cd ci-client-v2/apps/web
npm test -- it
```

## Cobertura mínima sugerida

- lib/ use-cases: **100%** branches em regras de negócio
- controllers: happy path + 403 + 422
- pages: render + interação principal por US P1
