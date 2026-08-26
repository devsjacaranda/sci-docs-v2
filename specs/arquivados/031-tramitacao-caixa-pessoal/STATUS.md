# STATUS — 031 Caixa Pessoal na Tramitação

**Data**: 2026-07-02 (arquivada)  
**Estado**: Concluída — 67/67 tasks em `tasks.md`

## Entregue (spec)

### API (`ci-api-v2`)

- Migration `20260702173132_tramitacao_caixa_pessoal` — `originType.personal`, `targetUserId`, `personalActive`, índices
- Tipos de notificação: `tramitacao_pessoal_nova`, `tramitacao_pessoal_resposta`, `tramitacao_pessoal_encaminhada`
- Filtros: `buildPersonalInboxWhere`, `buildPersonalAuditWhere`, exclusão de pessoais ativas na inbox setorial
- Guard `assertPersonalDemandaAccess` — participante ou auditoria read-only (`admin_tenant`)
- Rotas: `GET /demandas?inboxMode=sector|personal|audit`, `POST /demandas/personal`, `/personal/linked`, `/forward-user`, `/promote-sector`
- Use cases: compose, list personal/audit, reply, archive, forward-user, promote-sector, linked personal
- Dashboard KPIs excluem demandas pessoais ativas
- Seed Jacaranda: usuária Maria Silva + mensagem pessoal demo Paulo→Maria

### Client (`ci-client-v2/apps/web`)

- Toggle **Setor / Pessoal / Auditoria** na `TramitacaoInboxWorkspace`
- Hook `useTramitacaoInboxMode` (URL + sessionStorage)
- Compose pessoal com seletor de operador (`fetchUsers`)
- Dialogs encaminhar usuário e promover setor (confirmação irreversível)
- Banner e ações respeitam `permissions.isReadOnlyAudit`
- MSW handlers para inbox pessoal e ações personal

### Testes

- **API**: 68 testes Jest (`--testPathPatterns=personal|tramitacao|resolve-tramitacao-recipients`)
- **Client**: 4 testes Vitest (`TramitacaoInboxWorkspace.personal`)

---

## Pós-spec (fora do plano original)

- Labels de notificação pessoal em `notificacao.mapper.ts` (fix compilação TS)
- `promote-personal-to-sector` — payload de `notifyNovaDemanda` alinhado ao `Pick<>` do serviço

---

## Validação

```powershell
cd ci-api-v2; npm run prisma:seed
cd ci-api-v2; npm test -- --testPathPatterns=personal
cd ci-api-v2; npm test -- --testPathPatterns=tramitacao
cd ci-client-v2/apps/web; npm test -- TramitacaoInboxWorkspace.personal

# Smoke manual (quickstart C1–C7)
# paulo@demo.com → Tramitação → Pessoal → compor/responder
# colega de setor → não vê threads alheias
# admin@jacaranda.com → Auditoria → somente leitura
```

## Critérios spec

| US | Status |
|----|--------|
| US1 Toggle + inbox pessoal | OK |
| US2 Compor mensagem pessoal | OK |
| US3 Responder/arquivar privado | OK |
| US4 Encaminhar usuário | OK |
| US5 Promover setor | OK |
| US6 Linked pessoal (API) | OK — compose linked opcional no client não implementado |
| US7 Auditoria admin_tenant | OK |

## Dívidas / futuro

- Compose UI para `POST /demandas/personal/linked` (vínculo origem no sheet pessoal)
- `createPersonalLinkedDemanda` no client API (`demandas.ts`)
