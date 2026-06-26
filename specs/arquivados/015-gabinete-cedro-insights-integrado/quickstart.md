# Quickstart: Insights Cedro — Gabinete (integração completa)

**Feature**: 015-gabinete-cedro-insights-integrado  
**Pré-requisitos**: Gabinete Base (012), licença Cedro no tenant, submódulo `gabinete-insights` registrado

## 1. Testes automatizados (sem banco extra)

### API

```powershell
cd c:\ci-v2\ci-api-v2
npm test -- --testPathPatterns=gabinete-insights
```

**Esperado**: unit regras (13 slugs), use-cases, throttle, trace — todos com mocks Prisma.

### Client

```powershell
cd c:\ci-v2\ci-client-v2
npm run test --workspace=@ci/web -- --run GabineteInsights
npm run typecheck --workspace=@ci/web
```

**Esperado**: page + shared cedro + MSW passam.

---

## 2. Validação manual (dev com Postgres)

### Subir stack

```powershell
cd c:\ci-v2\ci-api-v2
npm run start:dev

cd c:\ci-v2\ci-client-v2
npm run dev
```

### Seed demo

```powershell
cd c:\ci-v2\ci-api-v2
npm run prisma:seed
```

Tenant `demo` / `jacaranda`: ≥ 12 atos + cadastros standalone (protocolo, controle numérico, notificações, autos, docs tramitados).

### Fluxo VS-001 — Painel integrado

1. Login `paulo@demo.com` ou `admin@jacaranda.com`
2. Gabinete → **Insights IA** (`/gabinete/insights`)
3. Verificar stats row, badge **Somente leitura**, fonte *Dados internos — Gabinete*
4. Acionar **Consultar IA** → confirmar dialog
5. Verificar ≥ 3 categorias distintas nos cards (operacional, protocolo/controle, enforcement/tramitação)
6. *De onde veio este insight?* → sheet ~85%, `module: gabinete`, link ato quando aplicável

### Fluxo VS-002 — Histórico e throttle

1. Acionar **Consultar IA** novamente (&lt; 1h) → mensagem throttle clara
2. Após 3 gerações (2 manuais + 1 agendada ou manual), abrir histórico → comparar 2 lotes anteriores

### Fluxo VS-003 — Standalone

1. Cadastrar 5+ protocolos standalone (sem ato) via Gabinete → Cadastros
2. Consultar IA → insight `protocol_orphan` ou `protocol_entry_mode`

### Fluxo VS-004 — Acesso negado

Usuário sem setor Gabinete → tela 403 padronizada.

---

## 3. Checklist SC

| SC | Validação |
|----|-----------|
| SC-001 | Overview Gabinete → Insights ≤ 3 cliques |
| SC-002 | Zero fonte externa UI + trace |
| SC-003 | Generate tenant ~1000 registros &lt; 30s |
| SC-004 | Histórico ≥ 3 gerações, 2 anteriores visíveis |
| SC-005 | Atos/controles idênticos antes/depois insights |
| SC-006 | Rastreio só sheet |
| SC-007 | ≥ 3 categorias com seed demo completo |
| SC-008 | emptyReason com mensagem + CTA |

---

## 4. Referências

- [rest-api-gabinete-insights.md](./contracts/rest-api-gabinete-insights.md)
- [client-gabinete-insights-ui.md](./contracts/client-gabinete-insights-ui.md)
- [test-strategy.md](./contracts/test-strategy.md)
- [data-model.md](./data-model.md)
- [research.md](./research.md)
