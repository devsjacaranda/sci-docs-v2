# Test Strategy: Caixa Pessoal na Tramitação

**Feature**: 031-tramitacao-caixa-pessoal  
**API**: Jest (`ci-api-v2`) · **Client**: Vitest/RTL (`ci-client-v2/apps/web`)

## Conventions

- TDD RED → GREEN → REFACTOR
- Integration specs em `ci-api-v2/src/modules/tramitacao/test/`
- Fixtures tenant isolado; operadores A, B, C em setores distintos
- Assert 404 opaco para terceiros (não assert message contém subject)

---

## API — CT-CP-001..016

### Inbox & compose (P1)

| ID | Descrição | Tipo |
|----|-----------|------|
| CT-CP-001 | `POST /demandas/personal` A→B cria protocolo; B received, A sent | integration |
| CT-CP-002 | `SAME_RECIPIENT` quando target=self | integration |
| CT-CP-003 | Colega setor C não lista pessoal A↔B (`inboxMode=personal` e `sector`) | integration |
| CT-CP-004 | `GET /demandas?inboxMode=sector` exclui pessoais ativas | integration |
| CT-CP-005 | `GET /demandas/:id` terceiro → 404 | integration |
| CT-CP-006 | `POST .../reply` B→A notifica A (`tramitacao_pessoal_resposta`) | integration |
| CT-CP-007 | `POST .../archive` arquiva para A e B | integration |
| CT-CP-008 | `resolveUserTableId` admin_tenant create sem FK violation | integration |

### Encaminhamentos (P2)

| ID | Descrição | Tipo |
|----|-----------|------|
| CT-CP-009 | `POST .../forward-user` B→C; B perde acesso; C received | integration |
| CT-CP-010 | Após forward-user, A+C reply; B 404 detail | integration |
| CT-CP-011 | `POST .../promote-sector` → setor X Recebidas contém demanda | integration |
| CT-CP-012 | `ALREADY_PROMOTED` segunda promote | integration |

### Linked + audit (P2)

| ID | Descrição | Tipo |
|----|-----------|------|
| CT-CP-013 | `POST /demandas/personal/linked` snapshot v2 gabinete | integration |
| CT-CP-014 | Participante vê snapshot; terceiro 404 | integration |
| CT-CP-015 | `inboxMode=audit` admin lista todas pessoais | integration |
| CT-CP-016 | Operador comum `audit` → 403 | integration |

### Unit

| ID | Descrição | Arquivo |
|----|-----------|---------|
| CT-CP-U01 | `buildPersonalInboxWhere` received/sent/archived | `personal-inbox-folder-filter.spec.ts` |
| CT-CP-U02 | `assertPersonalDemandaAccess` matrix | `assert-personal-demanda-access.spec.ts` |
| CT-CP-U03 | `forPersonalParticipant` exclui actor | `resolve-tramitacao-recipients.service.spec.ts` |

---

## Client — CT-CP-017..020

| ID | Descrição | Arquivo |
|----|-----------|---------|
| CT-CP-017 | Toggle Pessoal oculta setor pills | `TramitacaoInboxWorkspace.test.tsx` |
| CT-CP-018 | Compose pessoal chama `createPersonalDemanda` | `TramitacaoInboxWorkspace.test.tsx` |
| CT-CP-019 | Promote dialog confirma irreversibilidade | `TramitacaoInboxWorkspace.test.tsx` |
| CT-CP-020 | Audit mode read-only esconde ações | `TramitacaoInboxWorkspace.test.tsx` |

---

## Regression

- Suite existente `tramitacao` setorial (014) — zero falhas
- Notificações 029 — tipos setoriais inalterados
- Linked record gabinete/ouvidoria/juridico panels

---

## Quickstart mapping

| Cenário quickstart | Test IDs |
|--------------------|----------|
| C1 Compor pessoal | CT-CP-001, CT-CP-017, CT-CP-018 |
| C2 Responder privado | CT-CP-006 |
| C3 Terceiro negado | CT-CP-003, CT-CP-005 |
| C4 Promover setor | CT-CP-011 |
| C5 Auditoria admin | CT-CP-015, CT-CP-020 |
