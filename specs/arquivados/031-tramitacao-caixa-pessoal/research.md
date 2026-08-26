# Research: Caixa Pessoal na Tramitação

**Feature**: 031-tramitacao-caixa-pessoal  
**Date**: 2026-07-02

## R1 — Modelo de dados: estender TramitacaoDemanda vs entidade paralela

**Decision**: Estender `TramitacaoDemanda` com `originType: personal`, `targetUserId` (FK `User`) e `personalActive: boolean`.

**Rationale**:

- Spec FR-001 e assumption explícita: mesma entidade Demanda, sem mensagens paralelas.
- Reutiliza protocolo, eventos, timeline, linked record e notificações.
- Promoção setorial = `personalActive: false` + atualizar `currentSectorId` — demanda passa a inbox setorial sem duplicar registro.

**Alternatives considered**:

| Opção | Motivo rejeição |
|-------|-----------------|
| Tabela `TramitacaoMensagemPessoal` | Duplica thread/timeline; spec proíbe entidade paralela |
| Flag `isPrivate` em demanda setorial | Confunde custódia setor vs usuário; colegas ainda veriam por setor |
| Junction `Participante` only | Mais normalizado, porém over-engineering v1; `targetUserId` + `createdByUserId` suficientes |

**Campos setoriais obrigatórios (NOT NULL)**: Enquanto `personalActive=true`, definir `senderSectorId` e `currentSectorId` = setor resolvido do remetente (mesmo valor). Inbox setorial **filtra out** demandas pessoais ativas — setores não veem na pasta Recebidas.

---

## R2 — Inbox pessoal: pastas e filtros

**Decision**: Novo helper `buildPersonalInboxWhere(folder, actorRef)` espelhando pastas setoriais:

| Pasta | Critério |
|-------|----------|
| `received` | `originType=personal`, `personalActive=true`, `targetUserId=actorUserId` (ou admin target futuro) |
| `sent` | `originType=personal`, `personalActive=true`, `createdByUserId=actorUserId`, `targetUserId≠actorUserId` |
| `archived` | `status=archived`, participante era remetente ou destinatário |

Query param `inboxMode: sector | personal` em `GET /tramitacao/demandas`. Default `sector` (retrocompatível).

**Rationale**: Espelha UX email-like da spec 014; operador não depende de setor ativo no modo Pessoal.

**Alternatives considered**: Filtro client-side — rejeitado (vazamento de dados + paginação incorreta).

---

## R3 — Autorização e privacidade

**Decision**: Helper central `assertPersonalDemandaAccess(demanda, actor)`:

- **Permite**: `createdByUserId === actorUserId`, `targetUserId === actorUserId`, ou `role === admin_tenant` (read-only)
- **Nega**: todos os demais — HTTP 404 (não 403) para não vazar existência (edge case spec)

Aplicar em: GET detail, reply, archive, forward-user, promote-sector.

**Rationale**: Fecha gap atual (`get-demanda-detail` sem checagem de setor). chefe_setor **não** recebe exceção (FR-015).

**Alternatives considered**: 403 Forbidden — rejeitado para terceiros; spec pede não revelar metadados.

---

## R4 — Encaminhar para usuário vs promover para setor

**Decision**: Dois use cases distintos:

1. **Forward to user**: atualiza `targetUserId`; payload evento `forwarded` com `targetKind: 'user'`, `fromUserId`, `toUserId`, `notes`
2. **Promote to sector**: `personalActive=false`, `currentSectorId=targetSectorId`, `targetUserId=null`; payload `targetKind: 'sector'`; dispara notificação setorial (`forNovaDemanda`)

Participante intermediário perde acesso após forward-user (não está mais em createdBy/target).

**Rationale**: Transição irreversível de privacidade (US5) fica explícita no modelo; encaminhamento usuário preserva `personalActive=true`.

---

## R5 — admin_tenant como participante

**Decision**:

- **Auditoria**: `ListPersonalAuditUseCase` — lista todas `originType=personal` do tenant; detail read-only.
- **Envio/recebimento**: v1 primary path User→User; admin_tenant envia com `createdByUserId=undefined` + evento `created` com `withActorPayload(actorId, admin_tenant)`.
- **Inbox admin**: quando admin é destinatário lógico, estender v1.1 se necessário; v1 foca User destinatário + auditoria read-only (spec US7 prioridade P2).

**Rationale**: Polimorfismo completo admin↔user aumenta escopo; spec enfatiza operadores + auditoria admin. Participação admin como remetente coberta por actor payload existente.

**Alternatives considered**: `targetAdminTenantId` FK — reservado para follow-up se cliente exigir caixa pessoal admin↔admin.

---

## R6 — Linked record pessoal

**Decision**: `CreatePersonalLinkedDemandaUseCase` — combina `CreateLinkedDemandaUseCase` (snapshot v2) + `originType personal` + `targetUserId`. Visibilidade pessoal até promoção setorial.

Compose client: opcional seletor de registro origem (módulos gabinete/ouvidoria/juridico) — reutilizar padrão snapshot builders existentes.

**Rationale**: US6 exige vínculo sem expor ao setor; snapshot imutável já padronizado (028/030).

---

## R7 — Notificações (integração spec 029)

**Decision**: Novos tipos:

| Tipo | Destinatário |
|------|--------------|
| `tramitacao_pessoal_nova` | `targetUserId` |
| `tramitacao_pessoal_resposta` | outro participante (não autor) |
| `tramitacao_pessoal_encaminhada` | novo `targetUserId` |

Resolver `forPersonalParticipant(demanda, eventType, excludeActor)` — **nunca** chamar `forNovaDemanda` enquanto `personalActive=true`.

Promoção setorial: após promote, disparar `tramitacao_nova_demanda` para setor destino.

**Rationale**: FR-013 proíbe broadcast setorial em fluxo pessoal; framework 029 já suporta destinatário polimórfico.

---

## R8 — Seletor de destinatários (client)

**Decision**: Reutilizar `fetchUsers({ status: 'active', limit: 100 })` de `@/modules/setor/api/users-admin` — filtrar `id !== currentUserId` no client.

**Rationale**: Endpoint já existe para admin de setores; evita novo endpoint `/tramitacao/destinatarios` na v1.

**Alternatives considered**: Endpoint dedicado com filtro módulo tramitação — follow-up se lista > 100 ou RBAC granular necessário.

---

## R9 — UI toggle Setor / Pessoal

**Decision**: Segmented control no header de `TramitacaoInboxWorkspace`; persistir `inboxMode` em URL `?inboxMode=personal|sector` + `sessionStorage` key `tramitacao-inbox-mode`.

Modo Pessoal: ocultar pills de setor ativo; compose abre formulário com seletor de operador.

Modo admin auditoria: rota/query `?inboxMode=audit` visível apenas se JWT `role=admin_tenant`.

**Rationale**: Spec FR-004; paridade UX com pastas existentes.

---

## R10 — Dashboard e licenças

**Decision**: Dashboard tramitação (`GET /tramitacao/dashboard`) **exclui** demandas pessoais ativas dos KPIs setoriais v1.

**Rationale**: Demandas pessoais não são operação setorial; evita distorção de métricas. Out of scope explicitar agregação pessoal.
