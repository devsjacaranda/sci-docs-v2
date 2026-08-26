# Data Model: Desentranhamento de Documentos em Tramitação

Local do schema: `ci-api-v2/prisma/schema/tramitacao.prisma` (mesmo arquivo dos demais modelos de tramitação).

## Alterações em modelos existentes

### `TramitacaoDemandaAnexo` (novo campo)

| Campo | Tipo | Descrição |
|---|---|---|
| `desentranhadoAt` | `DateTime?` | Preenchido quando um pedido de desentranhamento é **aprovado**. `null` = anexo normal. Distinto de `deletedAt` (exclusão definitiva, já existente e não usado nesta feature). |

Regras de leitura:
- Listagens normais de anexo (`demanda.repositories.ts`, mapper) DEVEM continuar filtrando por `deletedAt: null` e agora também considerar `desentranhadoAt` para decidir se o anexo aparece na lista padrão (`desentranhadoAt: null`) ou apenas na visão de histórico.
- `resolveAnexoAccessLevel` (ver `research.md` §5) passa a considerar `desentranhadoAt` como um gate adicional de acesso ao conteúdo.

### `TramitacaoDemandaEventType` (enum — novos valores)

```prisma
enum TramitacaoDemandaEventType {
  created
  reply
  forwarded
  status_changed
  archived
  desentranhamento_solicitado
  desentranhamento_aprovado
  desentranhamento_rejeitado
}
```

Payload de cada novo tipo (JSON em `TramitacaoDemandaEvento.payload`, seguindo o padrão `withActorPayload`):

| Tipo | Payload |
|---|---|
| `desentranhamento_solicitado` | `{ anexoId, solicitacaoId, reason? }` + actor |
| `desentranhamento_aprovado` | `{ anexoId, solicitacaoId, decisionReason? }` + actor |
| `desentranhamento_rejeitado` | `{ anexoId, solicitacaoId, decisionReason? }` + actor |

## Nova entidade

### `TramitacaoDemandaAnexoDesentranhamento`

Representa a **Solicitação de Desentranhamento** descrita na spec (Key Entities).

```prisma
enum TramitacaoDesentranhamentoStatus {
  pending
  approved
  rejected
}

enum TramitacaoDesentranhamentoDirection {
  author_requests     // autor do anexo solicitou; contraparte decide
  recipient_requests  // contraparte solicitou; autor do anexo decide
}

model TramitacaoDemandaAnexoDesentranhamento {
  id                String                             @id @default(uuid())
  tenantId          String
  anexoId           String
  demandaId         String
  direction         TramitacaoDesentranhamentoDirection
  status            TramitacaoDesentranhamentoStatus   @default(pending)
  requestedByUserId String?
  requestReason     String?                             @db.Text
  decidedByUserId   String?
  decisionReason    String?                             @db.Text
  decidedAt         DateTime?
  createdAt         DateTime                            @default(now())
  updatedAt         DateTime                            @updatedAt

  anexo           TramitacaoDemandaAnexo @relation(fields: [anexoId], references: [id], onDelete: Cascade)
  demanda         TramitacaoDemanda      @relation(fields: [demandaId], references: [id], onDelete: Cascade)
  requestedByUser User?                  @relation("DesentranhamentoRequestedBy", fields: [requestedByUserId], references: [id], onDelete: SetNull)
  decidedByUser   User?                  @relation("DesentranhamentoDecidedBy", fields: [decidedByUserId], references: [id], onDelete: SetNull)

  @@index([tenantId, anexoId])
  @@index([tenantId, demandaId, status])
}
```

**Notas de campo**:
- `requestedByUserId` / `decidedByUserId` são `String?` (nullable) porque o ator pode ser `admin_tenant`/`admin_saas` (sem linha em `User`) — segue a regra de FK da rule `admin-tenant-user-fk`. Quando nulo, o ator real fica registrado no `payload` do evento de timeline correspondente via `withActorPayload` (nunca só na tabela de solicitação).
- `direction` é decidido no momento da criação, comparando `requestedByUserId` (ou o ator, se admin) com `anexo.uploadedByUserId`: igual → `author_requests`; diferente → `recipient_requests`. Guardar explicitamente evita recalcular em toda leitura e documenta a intenção de negócio.
- `requestReason` / `decisionReason`: sempre opcionais (FR-002, FR-006).
- Nenhum campo de soft-delete: a linha nunca é apagada, é o próprio histórico auditável do pedido.

**Constraint de unicidade (defesa em profundidade contra concorrência)**:

Índice único parcial criado via SQL bruto na migration (Prisma não expressa índices parciais no DSL):

```sql
CREATE UNIQUE INDEX "tramitacao_desentranhamento_pending_unique"
ON "TramitacaoDemandaAnexoDesentranhamento" ("anexoId")
WHERE "status" = 'pending';
```

Garante, a nível de banco, que nunca existam duas solicitações pendentes para o mesmo anexo (FR-004), mesmo sob requisições concorrentes.

## Notificações (`notificacao.prisma`)

### `NotificacaoType` (enum — novos valores)

```prisma
enum NotificacaoType {
  tramitacao_nova_demanda
  tramitacao_resposta
  tramitacao_encaminhamento
  tramitacao_pessoal_nova
  tramitacao_pessoal_resposta
  tramitacao_pessoal_encaminhada
  tramitacao_desentranhamento_solicitado
  tramitacao_desentranhamento_aprovado
  tramitacao_desentranhamento_rejeitado
}
```

Nenhuma alteração estrutural no model `Notificacao` — reaproveita `sourceModule: 'tramitacao'`, `sourceRecordId: demandaId`, `sourceEventId: <id do evento de timeline correspondente>`.

## Máquina de estados

```
                 solicitar
   (sem pedido) ──────────────► pending
                                   │  │
                          aprovar  │  │  rejeitar
                                   ▼  ▼
                             approved  rejected
```

- `pending → approved`: seta `TramitacaoDemandaAnexo.desentranhadoAt = now()`; `updateMany` condicional em `status = 'pending'`.
- `pending → rejected`: anexo permanece inalterado; `updateMany` condicional em `status = 'pending'`.
- `approved` e `rejected` são estados finais para aquela solicitação (não há "reabrir"); uma **nova** solicitação pode ser criada normalmente após `rejected` (não após `approved`, pois o anexo já estaria desentranhado e uma nova solicitação para o mesmo anexo desentranhado é bloqueada pela regra de "não solicitar para anexo já desentranhado", aplicada no `RequestDesentranhamentoUseCase`).

## Validações de negócio (aplicadas no use-case, não apenas no schema Zod)

1. Anexo deve existir, não estar `deletedAt`, e pertencer à `demandaId` da rota.
2. Demanda não pode estar `archived` para **criar** uma nova solicitação (FR-015); decisões sobre pedidos já pendentes continuam permitidas mesmo se a demanda for arquivada nesse meio tempo (FR-016).
3. Anexo não pode já estar `desentranhadoAt != null` (impede solicitar de novo para um anexo já desentranhado).
4. Não pode haver outra solicitação com `status = pending` para o mesmo `anexoId` (FR-004; reforçado pelo índice único parcial).
5. Deve existir ao menos um aprovador resolvível (`forDesentranhamentoApprovers`) — caso contrário, bloquear com erro de negócio (FR-005).
6. Apenas usuários resolvidos como aprovadores daquela solicitação específica podem chamar aprovar/rejeitar; qualquer outro usuário recebe 403.
