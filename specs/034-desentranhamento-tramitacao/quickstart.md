# Quickstart: Desentranhamento de Documentos em Tramitação

Guia de validação ponta a ponta após a implementação (ver `contracts/desentranhamento-api.md` e `data-model.md` para detalhes).

## Pré-requisitos

- API rodando: `cd ci-api-v2; npm run start:dev`
- Migration aplicada: `cd ci-api-v2; npx prisma migrate dev`
- Dois usuários de teste no mesmo tenant, em setores diferentes (ou uma conversa de caixa pessoal entre dois usuários), autenticados via JWT (ver `auth-patterns` skill para obter token de teste)
- Uma demanda de tramitação aberta (não arquivada) com pelo menos um anexo confirmado (`uploadConfirmed: true`)

## Cenário 1 — Autor solicita e contraparte aprova (User Story 1, P1)

1. Usuário A (autor do anexo) chama `POST /tramitacao/demandas/:id/anexos/:anexoId/desentranhamento` sem `reason`.
   - Esperado: `201`, `status: 'pending'`, `direction: 'author_requests'`.
2. Usuário B (membro do setor atual/destinatário, ou outro participante da caixa pessoal) recebe notificação in-app (`tramitacao_desentranhamento_solicitado`) — verificar via `GET /notificacoes` ou evento WebSocket `notification.created`.
3. Usuário B chama `POST /tramitacao/demandas/:id/desentranhamento/:solicitacaoId/approve`.
   - Esperado: `200`, `status: 'approved'`, `desentranhadoAt` preenchido.
4. `GET /tramitacao/demandas/:id` — o anexo não aparece mais na listagem padrão de anexos (verificar filtro `desentranhadoAt: null` nas queries) mas aparece na seção/consulta de histórico com `desentranhamento.status: 'approved'`.
5. Usuário A recebe notificação in-app `tramitacao_desentranhamento_aprovado`.

**Resultado esperado**: SC-001, SC-002, SC-003 e SC-004 (spec.md) satisfeitos.

## Cenário 2 — Contraparte solicita e autor rejeita (User Story 2, P2)

1. Usuário B (não autor do anexo) chama `POST /tramitacao/demandas/:id/anexos/:anexoId/desentranhamento` com `reason: "peça de outro processo"`.
   - Esperado: `201`, `direction: 'recipient_requests'`.
2. Usuário A (autor) recebe notificação `tramitacao_desentranhamento_solicitado`.
3. Usuário A chama `POST /tramitacao/demandas/:id/desentranhamento/:solicitacaoId/reject` sem `decisionReason`.
   - Esperado: `200`, `status: 'rejected'`.
4. `GET /tramitacao/demandas/:id` — anexo continua na listagem normal, inalterado.
5. Usuário B recebe notificação `tramitacao_desentranhamento_rejeitado`.

## Cenário 3 — Edge cases (validação de robustez)

- Repetir o passo 1 do Cenário 1 duas vezes seguidas para o mesmo anexo → segunda chamada retorna `409 PENDING_REQUEST_EXISTS`.
- Com o pedido do Cenário 1 ainda pendente, dois usuários do setor atual chamam `approve` e `reject` quase simultaneamente → apenas a primeira chamada recebida pelo servidor deve ter sucesso (`200`); a segunda deve retornar `409 ALREADY_DECIDED`.
- Solicitar desentranhamento em uma demanda com `status: archived` → `403 DEMANDA_ARCHIVED`.
- Aprovar um pedido pendente criado antes do arquivamento, com a demanda já arquivada → deve funcionar normalmente (`200`), conforme FR-016.
- Usuário sem nenhuma concessão de acesso confidencial e sem ser autor tenta `GET` no detalhe da demanda após o Cenário 1 → anexo aparece no histórico com `accessLevel: 'placeholder'`, sem `url`/`fileName` reais.
- Tentar solicitar desentranhamento novamente para o anexo já aprovado no Cenário 1 → `409 ANEXO_ALREADY_DESENTRANHADO`.

## Testes automatizados equivalentes

Os cenários acima devem ser cobertos por testes de integração (mocks, sem DB real — seguir padrão de `ci-api-v2/src/modules/tramitacao/test/*.integration.spec.ts`) antes da implementação (TDD, ver skills `tdd` e `testing-conventions`). Ver `tasks.md` (gerado por `/speckit-tasks`) para a quebra em tarefas RED → GREEN → REFACTOR.
