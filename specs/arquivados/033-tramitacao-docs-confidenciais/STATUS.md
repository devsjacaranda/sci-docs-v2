# STATUS — 033 Documentos confidenciais na Tramitação

**Data**: 2026-07-03 (arquivada)  
**Estado**: Concluída — 67/67 tasks em `tasks.md`

## Entregue (spec)

### API (`ci-api-v2`)

- Migration `20260703143000_tramitacao_anexo_confidential` — `uploadConfirmed`, `uploadedByUserId`, `isConfidential`, tabela `TramitacaoDemandaAnexoAccess`
- Use cases: `PresignAnexo`, `ConfirmAnexo`, `AddLinkAnexo`, `DownloadAnexo` com ACL por setor/usuário
- `resolveAnexoAccessLevel` + bypass `admin_tenant` (auditoria full, mutações bloqueadas)
- Mapper detail/timeline com `accessLevel` (`full` | `placeholder`)
- Rotas REST em `tramitacao.controller.ts` (presign, confirm, link, download)
- `resolveUserTableId` em `uploadedByUserId` (AdminTenant sem FK em `User`)
- Storage stub: rotas wildcard `upload/*` e `download/*` para chaves com `/`
- Seed demo: thread longa `TRAM-2026-0008` (20 mensagens, anexos simulados)

### Client (`ci-client-v2/apps/web`)

- `TramitacaoAnexoUploadZone` — upload arquivo + link, layout `compact` / `page`
- `ConfidentialAccessPanel` + `ConfidentialAccessPicker` — ACL multi-setor inline (mestre-detalhe)
- `TramitacaoAnexoList` — lista default + variant `thread` (chips, placeholder sigilo)
- `TramitacaoComposeScreen` — tela full-page `/tramitacao/demandas/novo`
- Integração anexos em compose, reply, forward, forward-user e promote (`TramitacaoInboxWorkspace`)
- `TramitacaoConversationThread` — thread estilo WhatsApp (esq/dir por viewer), hover transparente, tom mint sutil nas enviadas
- Validação client: `isConfidentialAccessValid` bloqueia envio sem usuários por setor

### Testes

- **API**: 35 testes Jest (`--testPathPatterns=anexo`)
- **Client**: 31 testes Vitest (`npm test -- tramitacao`) — CT-DC-021, CT-CP-017..020, picker, anexo list

---

## User stories

| US | Descrição | Status |
| --- | --- | --- |
| US1 | Anexar documentos (criar/responder/encaminhar) | OK |
| US2 | Marcar confidencial + ACL multi-setor/usuário | OK |
| US3 | Visualização full vs placeholder | OK |
| US4 | Confidencial na caixa pessoal | OK |
| US5 | Preservar ACL ao encaminhar setorial | OK |
| US6 | Promover pessoal→setor mantendo ACL | OK |
| US7 | Auditoria `admin_tenant` | OK |

---

## Validação

```powershell
cd ci-api-v2; npm test -- --testPathPatterns=anexo
cd ci-client-v2/apps/web; npm test -- tramitacao

# Smoke manual (quickstart)
# Cenários 1–7 em quickstart.md
# Demo thread: TRAM-2026-0008 — admin@jacaranda.com / carla@jacaranda.com (password123)
```

## Pós-entrega (sessão de polish)

- Compose full-page em vez de sheet lateral
- Painel de sigilo inline (sem modal)
- UX aba Conversa: grid 3 colunas, avatares bilateral, hover neutro/mint
- Fix upload client: verifica status HTTP do PUT antes do confirm

## Dívidas / futuro

- Teste Vitest dedicado para `TramitacaoConversationThread`
- Inbox preview ainda usa `demanda.body` (primeira msg), não a última da thread
