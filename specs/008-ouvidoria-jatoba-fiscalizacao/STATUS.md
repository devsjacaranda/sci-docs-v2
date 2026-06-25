# Status: Fiscalização Jatobá — Ouvidoria

| Campo | Valor |
|-------|-------|
| **Status** | Arquivada (MVP implementado) |
| **Concluída em** | 2026-06-19 |
| **Spec** | [spec.md](./spec.md) |
| **Plano** | [plan.md](./plan.md) |
| **Tasks** | [tasks.md](./tasks.md) — T001–T073 `[X]` (MVP); T049+ pendentes (rastreio, questionários, card detalhe) |

## Entregas (MVP)

- **API** (`ci-api-v2/src/modules/ouvidoria-fiscalizacao/`): checagens automáticas, execuções persistidas, SLA por tipo, throttle 1h, job cron, REST `/ouvidoria/fiscalizacao`
- **Prisma**: migration `20260619173829_ouvidoria_fiscalizacao` + seed perguntas/SLA (`seed-fiscalizacao-questions.ts`)
- **Client** (`ci-client-v2/apps/web/src/modules/ouvidoria/`): página `/ouvidoria/auditoria` real (substitui mock), painel stats/checagens/achados/histórico, MSW

## Fora do MVP (backlog na spec)

- Rastreabilidade sheet + endpoints trace (Fase 5)
- Questionários interno/externo + banco de perguntas UI (Fases 9–10)
- Card fiscalização no detalhe da manifestação (Fase 11)

## Validação

- API: `npm test -- --testPathPatterns=ouvidoria-fiscalizacao`, `npm run test:e2e -- --testPathPatterns=ouvidoria-fiscalizacao`
- Client: `npm run test -- fiscalizacao`, `npm run test -- OuvidoriaAuditoria`
- Manual: `ouvidoria@demo.com` → `/ouvidoria/auditoria` (ver [quickstart.md](./quickstart.md))

## Próximo passo Spec Kit

Nenhuma feature ativa. Para nova feature: `/speckit-specify`. Para retomar pendências desta spec: reabrir `tasks.md` a partir de T049.
