# STATUS — 035 Tramitação como Protocolo

**Data**: 2026-07-08  
**Estado**: Concluída — 110/110 tasks em `tasks.md`

## Entregue (spec)

### API (`ci-api-v2`)

- Migration `tramitacao_protocolo_reset` — entidade `Protocolo`, eventos, setores participantes, gestores, anexos reconciliados
- CRUD protocolo: abrir setorial/pessoal, listar, detalhe, atualizações, incluir setor, conceder gestor
- Cross-módulo: `POST /protocolos/linked`, `POST /protocolos/:id/entranhar`, `GET /protocolos/buscar`
- Ciclo de vida: baixar dossiê (PDF+ZIP), encerrar (bloqueio de escrita)
- Anexos: presign, confirm, link, download (compatível com 033 confidencial)
- Desentranhamento reconciliado (034): request/approve/reject sobre protocolo
- Dashboard: KPIs `abertos`/`encerrados`/`byTipo`/`bySourceModule`
- Remoção do modelo antigo (`forward-demanda`, `archive-demanda`, pastas inbox)

### Client (`ci-client-v2/apps/web`)

- Rotas `/tramitacao/protocolos*` com redirects legados `/tramitacao/demandas*`
- `TramitacaoProtocolosPage` — lista única "Meus protocolos" (sem abas Recebidas/Enviadas)
- `TramitacaoProtocoloWorkspace` — timeline, participantes, anexos, ações (atualizar/incluir setor/baixar/encerrar)
- `TramitacaoAbrirProtocoloForm` — setorial e pessoal
- `TramitacaoEntranharDialog` + `LinkedRecordPanel` — vocabulário protocolo
- `TramitacaoDashboardPage` — KPIs por status/tipo
- Limpeza legado: removidos `useTramitacaoInboxMode`, `api/demandas.ts`, inbox/compose pages
- MSW/fixtures/notificações atualizados para `/tramitacao/protocolos/`

### Testes

- **API**: 88 testes Jest (`npm test -- --testPathPatterns=tramitacao`) — 20 integration specs
- **Client**: 42 testes Vitest (`npm test -- Tramitacao`) — 15 arquivos

---

## User stories

| US | Descrição | Status |
| --- | --- | --- |
| US1 | Abrir protocolo setorial | OK |
| US2 | Incluir setores e colaborar | OK |
| US3 | Lista única Meus protocolos | OK |
| US4 | Tramitar/entranhar cross-módulo | OK |
| US5 | Baixar dossiê PDF+ZIP | OK |
| US6 | Encerrar protocolo | OK |
| US7 | Protocolo pessoal | OK |
| US8 | Conceder gestão | OK |
| 034 | Desentranhamento reconciliado | OK |

---

## Validação quickstart (Cenários 1–8)

Cobertura automatizada mapeada em `quickstart.md`. Smoke manual E2E no browser permanece recomendado antes de deploy.

| Cenário | Cobertura automatizada |
| --- | --- |
| 1 — Abrir setorial + colaborar | `abrir-protocolo-setorial`, `adicionar-atualizacao`, `TramitacaoAbrirProtocoloForm`, `TramitacaoProtocolosPage` |
| 2 — Incluir setor + gestão | `incluir-setor`, `conceder-gestor`, `TramitacaoParticipantesPanel` |
| 3 — Lista/filtros/busca | `listar-protocolos`, `TramitacaoProtocolosPage` |
| 4 — Cross-módulo entranhar | `abrir-protocolo-linked`, `entranhar-protocolo`, `entranhar-protocolo-encerrado`, `TramitacaoEntranharDialog`, `LinkedRecordPanel.*` |
| 5 — Baixar dossiê | `baixar-protocolo`, `baixar-protocolo-limite`, `TramitacaoBaixarButton`, `download-anexo` |
| 6 — Encerrar | `encerrar-protocolo`, `encerrar-protocolo-concorrencia`, `protocolo-encerrado-bloqueia-escrita`, `TramitacaoEncerrarDialog` |
| 7 — Protocolo pessoal | `abrir-protocolo-pessoal`, `acesso-protocolo-pessoal` |
| 8 — Desentranhamento | `desentranhamento-author-approve`, `desentranhamento-author-reject`, `desentranhamento-recipient-approve` |

```powershell
cd ci-api-v2; npm test -- --testPathPatterns=tramitacao
cd ci-api-v2; npm run build
cd ci-client-v2/apps/web; npm test -- --run Tramitacao
```

## Dívidas / futuro

- Smoke manual E2E no browser (fluxo Ouvidoria → entranhar) — não bloqueia arquivamento
- `ci-client-v2/src/` (cópia legada pré-migração) ainda referencia `/tramitacao/demandas` — fora do pacote `@ci/web`
- Build `tsc -b` do `@ci/web` tem erros pré-existentes em outros módulos (global-docs, saude, permissao)
