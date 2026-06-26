# Status: Desmock Gabinete — Atos, Cadastros e Licenças

| Campo | Valor |
|-------|-------|
| **Status** | Concluída (merge-ready) |
| **Concluída em** | 2026-06-24 |
| **Spec** | [spec.md](./spec.md) |
| **Plano** | [plan.md](./plan.md) |
| **Tasks** | [tasks.md](./tasks.md) — T001–T096 `[X]` · polish/licenças parcial |

## Entregas

### API (`ci-api-v2/src/modules/gabinete/`)

- Schema `CabinetProtocolo`, `CabinetDemanda`, controles, documentos tramitados unificados por setor
- CRUD atos (`/gabinete/cabinets/…`) + cadastros tenant-level standalone (`/gabinete/protocolos`, `/controles-numericos`, `/notificacoes`, `/autos-infracao`, `/documentos-tramitados`)
- Vínculo posterior ao ato (`cabinetId` opcional, `vincular-protocolo`, PATCH com `cabinetId`)
- Dashboard executivo, forward stub, anexos Wasabi (protocolo + ato)
- Módulos licença: `gabinete-fiscalizacao`, `gabinete-maturidade`, `gabinete-insights` (API + testes)
- Migration `20260624140000_gabinete_cadastros_standalone`
- Seed demo: `seed-gabinete-demo.ts` (12 atos Jacaranda)

### Client (`ci-client-v2/apps/web/src/modules/gabinete/`)

- Vocabulário UI: **ato/atos** — rotas `/gabinete/atos/*`
- Atos: lista, criar, detalhe (abas legado + vínculo protocolo)
- **Cadastros** (sidebar → list/create/detail, design system v1):
  - Protocolo, Controle numérico, Notificações e autos, Documentos tramitados
  - Breadcrumbs, cards de estatística, card filtros, tabela shadcn, paginação client-side, campos v1
  - Coluna **Ações** com menu ⋮ (`TableRowActionsMenu`) — ver [regras-plataforma §4.2](../../../.cursor/docs/regras-plataforma.md)
  - Fluxo: cadastrar standalone → vincular a ato depois
- **Lista de Atos** e **Manifestações (Ouvidoria)**: mesmo padrão §4.1–§4.2
- Páginas licença: auditoria, maturidade, insights (simplificadas vs Ouvidoria)
- Toast de confirmação pós-criação (notificações/autos)

## Dívidas / fora do escopo arquivado

- E2E guards 403/200 (T051–T052) — pendente
- Seeds perguntas fiscalização/maturidade **Gabinete** (T082, T092) — pendente
- Painéis client licença no nível Ouvidoria (US11/US12 polish)
- Validação manual quickstart VS-001…VS-009 (T108)
- Tramitação real entre setores (fora de spec)

## Validação

```powershell
cd ci-api-v2
npm test -- --testPathPatterns=gabinete    # 68+ testes gabinete

cd ci-client-v2
npm run typecheck --workspace=@ci/web
npm test --workspace=@ci/web -- --run Gabinete
```

## Manual

`paulo@demo.com` ou `admin@jacaranda.com` → Gabinete → Cadastros / Atos (ver [quickstart.md](./quickstart.md))

## Próximo passo Spec Kit

Plano ativo: [013 Auth Session Logout](../013-auth-session-logout/plan.md). Nova feature: `/speckit-specify`.
