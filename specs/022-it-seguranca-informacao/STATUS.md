# STATUS — 022 IT Segurança da Informação

**Data**: 2026-06-25 · **Fase**: 17 Polish concluída  
**Estado**: Implementação funcional — Phase 16–17 (governança + E2E) validadas via testes automatizados

## Entregue (Phase 17)

### Governança US14
- `ci-api-v2/test/it-guards.e2e-spec.ts` — 403 módulo IT + licenças Cedro/Jatobá/Carvalho
- `ItPages.guards.test.tsx` — alertas licença + AccessDenied403 no client
- Guards `@RequireModulo('it')` + `@RequireLicenca` validados nos 4 controllers IT
- `useModuleAccess('it')` em dashboard, ativos, incidentes, operadores, insights, fiscalização e maturidade

### E2E e contrato
- `ci-api-v2/test/it.e2e-spec.ts` — jornada CRUD + Cedro + Jatobá + Carvalho
- `it.e2e.test.tsx` — jornada client SC-012 (dashboard → maturidade)
- `it.contract.test.ts` — Zod round-trip vs fixtures principais

### Rastreabilidade (T131)
- Insight: `InsightTraceSheet` em `/it/insights`
- Backup: `FiscalizacaoTraceSheet` em `/it/fiscalizacao` (+ teste integração INT-IT-FIS-005)
- Score maturidade: `ItMaturidadeTraceSheet` em `/it/maturidade`
- Matriz risco: sheet inline em `ItRiskMatrixForm`

## Validação quickstart (Cenários 1–10)

| Cenário | Objetivo | Status | Notas |
|---------|----------|--------|-------|
| 1 CRUD ativos | FR-002–004, SC-001 | OK | Testes unitários + integração + E2E API/client |
| 2 Incidente + linha defesa | FR-005–006 | OK | `resolve-incidente` exige defense line |
| 3 Dashboard LGPD | FR-007–008, SC-003 | OK | MSW + dashboard fixture 73% |
| 4 Classificador Cedro + apply | FR-013–014, SC-011 | OK | readOnly até POST apply-sensitive-flag |
| 5 Config + matriz risco | FR-011–012, SC-004/006 | OK | port:21 alerta; matriz Risco Alto |
| 6 Backup workflow | FR-017–019, SC-007 | OK | cron/run manual + evidência; trace sheet |
| 7 Trilha imutável | FR-020–021, SC-008 | OK | repository rejeita delete |
| 8 ANPD PDF | FR-022, SC-009 | OK | pdf-lib + botão oculto non-critical |
| 9 Maturidade Carvalho | FR-024–027, SC-010 | OK | 75% score + ranking + trace sheet |
| 10 Governança licenças | FR-031, US14 | OK | guards E2E API + client |

## Comandos de validação

```powershell
cd ci-api-v2
npm test -- --testPathPatterns="it-guards|test/it\\.e2e"

cd ci-client-v2/apps/web
npm test -- --run "ItPages.guards|it\\.e2e|it\\.contract"
npm test -- --run it
```

## Desvios conhecidos

| Item | Descrição |
|------|-----------|
| T130 | Seeds demo Jacaranda (5 ativos, 2 incidentes) — pendente |
| T096 | `ItBackupEvidenceForm` integrado; seção backup reusa `FiscalizacaoPanel` |
| T021–T022 | Schemas Prisma fiscalização/maturidade parcialmente via migration 022 |
| Manual E2E | Validação browser completa requer `npm run prisma:seed` + dev servers |

## Próximo passo

- Completar T130 seeds demo
- `/speckit-complete` após validação manual final do tenant Jacaranda
