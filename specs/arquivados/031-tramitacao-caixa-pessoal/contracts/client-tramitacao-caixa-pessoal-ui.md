# Contract: Client UI — Tramitação Caixa Pessoal

**Feature**: 031-tramitacao-caixa-pessoal  
**App**: `@ci/web` — `apps/web/src/modules/tramitacao/`

Extensão do contrato [014 client-tramitacao-ui](../../arquivados/014-desmock-tramitacao/contracts/client-tramitacao-ui.md).

## Rotas

| Rota | Página | Notas |
|------|--------|-------|
| `/tramitacao/demandas` | `TramitacaoInboxPage` | Query `?inboxMode=sector\|personal\|audit` |
| `/tramitacao/demandas/novo` | `TramitacaoComposePage` | Query `?inboxMode=personal` abre compose pessoal |
| `/tramitacao/demandas/:id` | `TramitacaoDemandaDetailPage` | Preserva `inboxMode` no back link |

## TramitacaoInboxWorkspace

### Toggle Setor / Pessoal

- **Componente**: segmented control (shadcn `Tabs` ou toggle group) no header
- **Default**: `sector`
- **Persistência**: URL `inboxMode` + `sessionStorage` key `tramitacao-inbox-mode`
- **Setor mode**: comportamento atual — pills setor ativo, pastas Recebidas/Enviadas/Arquivadas
- **Pessoal mode**: ocultar seletor setor; mesmas três pastas; lista via `listInbox({ inboxMode: 'personal', folder })`

### Modo auditoria (admin_tenant)

- Tab ou menu **Auditoria** visível apenas se `useAuth().role === 'admin_tenant'`
- Lista `inboxMode=audit`; detalhe com banner "Somente leitura — auditoria institucional"
- Ocultar botões: Compor (opcional permitir), Responder, Encaminhar, Arquivar

### Compose pessoal

**Trigger**: botão "Nova mensagem" em modo Pessoal ou rota `/tramitacao/demandas/novo?inboxMode=personal`

**Campos**:

| Campo | UI | Validação |
|-------|-----|-----------|
| Destinatário | `Select` operadores | `fetchUsers({ status: 'active', limit: 100 })`, excluir self |
| Assunto | `Input` | required, max 500 |
| Corpo | `Textarea` | required |
| Vínculo origem (opcional) | Seção colapsável | módulo + registro + preview snapshot |

**Submit**: `POST /tramitacao/demandas/personal` ou `/personal/linked`

**Sucesso**: toast + navegar para detalhe ou atualizar lista Enviadas

### Detalhe demanda pessoal

**Header**: badge "Pessoal" + nomes remetente → destinatário

**Ações** (toolbar):

| Ação | Ícone | API | Condição |
|------|-------|-----|----------|
| Responder | Reply | `POST .../reply` | `permissions.canReply` |
| Encaminhar usuário | UserPlus | `POST .../forward-user` | `canForwardToUser` |
| Encaminhar setor | Share2 | `POST .../promote-sector` | `canPromoteToSector` |
| Arquivar | Archive | `POST .../archive` | `canArchive` |

**Dialogs**:

- Forward user: select operador + notes opcional
- Promote sector: select setor (`fetchSetores`, excluir setor placeholder se aplicável) + notes; confirmação "Esta ação tornará a demanda visível ao setor inteiro"

**Tabs**: Conteúdo / Conversa / Encaminhamentos / Vínculos (linked) — reutilizar layout setorial

### LinkedRecordPanel

- Inalterado para `sourceModule` gabinete/ouvidoria/juridico
- Visível em demandas `originType=personal` com snapshot

## API Client (`api/demandas.ts`)

Novas funções:

```typescript
type InboxMode = 'sector' | 'personal' | 'audit';

listInbox(params: { folder; inboxMode?; sectorId?; page?; limit?; q? })
createPersonalDemanda(body: { targetUserId; subject; body })
createPersonalLinkedDemanda(body: { targetUserId; subject; body; sourceModule; sourceRecordId; sourceSnapshot })
forwardPersonalToUser(id, body: { targetUserId; notes? })
promotePersonalToSector(id, body: { targetSectorId; notes? })
```

Tipos estendidos: `originType`, `personalActive`, `targetUser`, `senderUser`, `permissions`.

## Copy PT-BR (regras-plataforma)

| Elemento | Texto |
|----------|-------|
| Toggle Setor | Setor |
| Toggle Pessoal | Pessoal |
| Badge | Pessoal |
| Compose CTA | Nova mensagem |
| Promote confirm | Esta demanda ficará visível para todos do setor selecionado. Deseja continuar? |
| Audit banner | Visualização de auditoria — somente leitura |
| Erro SAME_RECIPIENT | Não é possível enviar mensagem para você mesmo |

## Acessibilidade

- Toggle com `aria-pressed` / labels explícitos
- Foco retorna à lista após arquivar
- Dialogs promote com `role=alertdialog` por irreversibilidade

## Testes Vitest (RTL)

Ver [test-strategy.md](./test-strategy.md) CT-CP-017..020.

## Out of Scope UI v1

- Compose pessoal a partir de outros módulos (só tramitação)
- Seletor admin_tenant como destinatário
- Anexos específicos pessoais
