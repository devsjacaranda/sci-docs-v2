# Research: Desentranhamento de Documentos em Tramitação

Todas as ambiguidades de **negócio** já foram resolvidas interativamente com o solicitante durante `/speckit-specify` (ver `spec.md` → Assumptions). Não há `[NEEDS CLARIFICATION]` pendente na spec. Este documento resolve as decisões **técnicas** necessárias para o design (Phase 1), avaliando alternativas dentro do padrão já estabelecido em `ci-api-v2/src/modules/tramitacao/` e na feature irmã mais recente (033 — documentos confidenciais).

## 1. Modelagem da solicitação de desentranhamento

**Decision**: Nova entidade Prisma dedicada, `TramitacaoDemandaAnexoDesentranhamento`, com campos próprios de workflow (status, direção, solicitante, decisor, motivos, timestamps), em vez de reaproveitar o `payload` JSON de `TramitacaoDemandaEvento`.

**Rationale**: A regra de negócio FR-004 ("não pode haver duas solicitações pendentes para o mesmo anexo") e FR-009 ("primeira decisão vale") exigem uma linha com **estado consultável e atualizável atomicamente** (`status: pending/approved/rejected`). Um payload dentro de um evento de timeline é apend-only e não é feito para ser consultado por "anexo com pedido pendente" nem atualizado depois de criado.

**Alternatives considered**:
- Guardar tudo dentro do `payload` do evento `TramitacaoDemandaEventType` — rejeitado: exigiria escanear todos os eventos da demanda para achar pedidos pendentes por anexo, e não há atualização de payload após criação no padrão atual do módulo.
- Criar uma tabela de workflow genérica reutilizável entre módulos — rejeitado: não existe hoje nenhum padrão de "workflow de aprovação" genérico no codebase; introduzir um agora está fora do escopo desta feature (YAGNI).

## 2. Novo estado no anexo (`desentranhado` vs. reaproveitar `deletedAt`)

**Decision**: Novo campo `desentranhadoAt DateTime?` em `TramitacaoDemandaAnexo`, distinto do `deletedAt` já existente.

**Rationale**: `deletedAt` já é filtrado (`where: { deletedAt: null }`) em todas as queries de listagem de anexo (`demanda.repositories.ts`), o que o tornaria **invisível também no histórico** — contradizendo diretamente a FR-011 ("continuar acessível... em uma visualização de histórico"). Usar um campo semanticamente distinto evita sobrecarregar `deletedAt` com dois significados (exclusão definitiva vs. desentranhamento reversível-só-na-forma-de-visibilidade).

**Alternatives considered**: Reaproveitar `deletedAt` com uma exceção especial nas queries de histórico — rejeitado por acoplar demais o comportamento a um campo cujo contrato atual (em todo o módulo) é "não existe mais para nenhuma tela".

## 3. Novos tipos de evento de timeline

**Decision**: Estender o enum `TramitacaoDemandaEventType` com três novos valores: `desentranhamento_solicitado`, `desentranhamento_aprovado`, `desentranhamento_rejeitado`.

**Rationale**: Mantém a convenção 1 evento = 1 ação de negócio já usada (`created`, `reply`, `forwarded`, `archived`), o que já tem suporte pronto de labels (`EVENT_TYPE_LABELS` em `tramitacao.mapper.ts`) e de renderização de autor (`resolveEventAuthor`).

**Alternatives considered**: Reaproveitar o valor genérico `status_changed` com um campo `payload.action` distinguindo o subtipo — rejeitado: perde granularidade na filtragem/labels do client e não segue o padrão de nomeação explícita já visto no enum.

## 4. Resolução de quem pode decidir (aprovadores)

**Decision**: Reaproveitar `ResolveTramitacaoRecipientsService` (já usado para notificações), adicionando um método `forDesentranhamentoApprovers(demanda, requesterActor)` que:
- Se a demanda é de caixa pessoal (`personalActive`): delega para `forPersonalOtherParticipant`.
- Se é setorial: delega para `forNovaDemanda(demanda.currentSectorId)` (todos os membros do setor atual + `admin_tenant`), excluindo o próprio solicitante via `excludeActor`.

Essa mesma resolução decide **quem recebe a notificação** de "pedido pendente" e **quem tem permissão para chamar o endpoint de aprovar/rejeitar**.

**Rationale**: A lógica de "quem é o outro lado" (setor atual vs. caixa pessoal) já existe, testada e usada para notificações de nova demanda/resposta — reaproveitá-la evita duplicar regras de pertencimento a setor.

**Alternatives considered**: Escrever uma nova query de resolução de aprovadores do zero — rejeitado, duplicaria lógica já existente e aumentaria a superfície de regressão.

## 5. Extensão do controle de acesso pós-desentranhamento

**Decision**: Estender `resolveAnexoAccessLevel` (em `resolve-anexo-access.ts`) para, quando `anexo.desentranhadoAt` estiver presente, retornar `'full'` **apenas** se o ator for o autor do anexo, `admin_tenant`/`admin_saas`, ou (quando o anexo também é confidencial) tiver uma concessão de ACL — e `'placeholder'` para todos os demais, **independentemente** de o anexo ser ou não confidencial.

**Rationale**: A FR-011/FR-012 restringe explicitamente o acesso pós-desentranhamento a quem "já teria acesso ao conteúdo antes" — o que, no caso de documentos não confidenciais, ainda restringe a visibilidade a um subconjunto menor (autor + admin) do que "qualquer participante da demanda". Centralizar essa regra na função já usada pelo mapper e pelo `DownloadAnexoUseCase` garante que listagem e download nunca fiquem inconsistentes.

**Alternatives considered**: Criar uma segunda função de resolução de acesso específica para desentranhamento — rejeitado: criaria dois caminhos de decisão de acesso divergentes para o mesmo anexo, risco real de drift entre listagem e download.

## 6. Notificações

**Decision**: Três novos valores em `NotificacaoType` — `tramitacao_desentranhamento_solicitado` (para os aprovadores), `tramitacao_desentranhamento_aprovado` e `tramitacao_desentranhamento_rejeitado` (para o solicitante) — cada um disparado por um método dedicado em `TramitacaoNotificacaoService`, seguindo o padrão de `notifyResposta`/`notifyEncaminhamento`.

**Rationale**: Mantém a correspondência 1:1 já estabelecida entre eventos de tramitação e tipos de notificação, reaproveitando `DispatchNotificacaoService` (dedupe, WebSocket) sem alterações.

**Alternatives considered**: Um único tipo genérico `tramitacao_desentranhamento` com um campo de "status" na snapshot — rejeitado: quebra a convenção de enum-por-ação e complica `TYPE_LABELS`/filtros no client.

**Navegação**: `sourceModule` continua `'tramitacao'` e `sourceRecordId` continua sendo o `demandaId` — o `navigation-registry.ts` existente já resolve `/tramitacao/demandas/${id}` sem necessidade de alteração.

## 7. Concorrência ("primeira decisão vale")

**Decision**: A decisão (aprovar/rejeitar) é implementada como um `updateMany` condicional (`WHERE id = :id AND status = 'pending'`), verificando o `count` afetado. Se `count === 0`, a solicitação já foi decidida por outra pessoa e o endpoint retorna erro de conflito. Adicionalmente, a criação de nova solicitação (FR-004) é protegida por um índice único parcial via SQL bruto na migration: `CREATE UNIQUE INDEX ... ON tramitacao_demanda_anexo_desentranhamento (anexo_id) WHERE status = 'pending'`.

**Rationale**: Garante atomicidade a nível de banco sem lock explícito em código, resolvendo diretamente o edge case de duas aprovações simultâneas (FR-009) e o de duas solicitações simultâneas (FR-004) de forma consistente mesmo sob concorrência real, não apenas verificação otimista na aplicação.

**Alternatives considered**: `SELECT` seguido de `UPDATE` no código da aplicação — rejeitado por ser sujeito a race condition (dois requests podem passar pelo `SELECT` antes de qualquer `UPDATE`).

## 8. Superfície de UI no client

**Decision**: Sem nova página/rota. Ações de solicitar/aprovar/rejeitar são adicionadas inline em `TramitacaoAnexoList.tsx` (botão contextual por anexo, badge de status) e um indicador de pedidos pendentes aguardando decisão do usuário atual em `TramitacaoInboxWorkspace.tsx`.

**Rationale**: A spec descreve uma ação por documento, não uma fila/dashboard separada. Seguir o padrão já usado para ações de anexo confidencial (`ConfidentialAccessPicker`/`ConfidentialAccessPanel`, também inline) mantém consistência visual e evita aumento de escopo não solicitado.

**Alternatives considered**: Nova aba dedicada na tela de detalhe da demanda (como a aba de "Encaminhamentos") — rejeitado como escopo excessivo para o volume esperado de pedidos por anexo; pode ser revisitado como melhoria futura se o volume justificar.
