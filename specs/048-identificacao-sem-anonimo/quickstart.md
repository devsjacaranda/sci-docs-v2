# Quickstart: Validar Identificação sem anônimo + e-mail

## Pré-requisitos

```powershell
cd ci-api-v2; npm run prisma:seed
cd ci-api-v2; npm run start:dev
cd ci-client-v2; npm run dev       # turbo → @ci/web
```

Usuário de teste: qualquer operador autenticado com módulo Ouvidoria liberado (`role: user` ou `chefe_setor`, com `setorIds` vinculado ao módulo).

## Cenário 1 — Cards de escolha não existem mais (US1 / SC-001)

1. Login como operador → abrir `/ouvidoria/manifestacoes/nova`.
2. Chegar na etapa **Identificação**.
3. **Esperado**: não há os cards «Permanecer anônimo» / «Quero me identificar»; o formulário de dados do manifestante (Nome completo, CPF/CNPJ, Titular, Matrícula, telefones, **E-mail**) já está visível, sem nenhuma ação prévia de escolha.

## Cenário 2 — Nome obrigatório, exceto denúncia (US1/US2 — FR-009, SC-002)

1. Escolher `type = "complaint"` (reclamação) → deixar "Nome completo" em branco → tentar avançar/confirmar.
   - **Esperado**: bloqueado, mensagem em "Nome completo".
2. Preencher "Nome completo" → avançar/confirmar.
   - **Esperado**: sucesso.
3. Novo rascunho, escolher `type = "whistleblower"` (denúncia) → deixar "Nome completo" em branco → avançar/confirmar.
   - **Esperado**: sucesso — nome não é exigido para denúncia (edge case da spec).
4. No rascunho do passo 3, trocar o tipo para `"complaint"` → tentar avançar/confirmar sem preencher o nome.
   - **Esperado**: bloqueado — a exceção deixou de valer.

## Cenário 3 — E-mail único, dentro do bloco Identificação (US2 — FR-004 a FR-007, SC-003)

1. Na etapa Identificação, confirmar que existe **exatamente um** campo "E-mail", dentro do mesmo bloco de Nome/CPF/Telefones (não em um card separado acima).
2. Digitar um e-mail inválido (ex.: `abc`) → tentar avançar.
   - **Esperado**: bloqueado, mensagem de e-mail inválido.
3. Deixar o e-mail em branco → avançar.
   - **Esperado**: sucesso (campo opcional).
4. Preencher um e-mail válido → confirmar a manifestação → abrir o detalhe da manifestação confirmada.
   - **Esperado**: o e-mail aparece no card "Manifestante" (campo "E-mail", já existente na tela de detalhe).

## Cenário 4 — Consistência na leitura (US3 — SC-005)

1. Confirmar uma manifestação identificada criada após a mudança (Cenário 2, passo 2).
2. Abrir o detalhe.
   - **Esperado**: card "Manifestante" mostra os dados preenchidos — **não** aparece "Manifestação anônima".

## Cenário 5 — Registros legados permanecem intocados (FR-011)

1. Localizar (via seed ou registro pré-existente) uma manifestação com `isAnonymous: true` criada **antes** desta mudança.
2. Abrir o detalhe.
   - **Esperado**: continua exibindo "Manifestação anônima" no card "Manifestante", exatamente como antes — nenhuma migração aplicada.

## Cenário 6 — Portal público inalterado (FR-008 / Out of Scope)

1. Abrir o portal público AGEMAN (`apps/publico`) e iniciar uma manifestação.
   - **Esperado**: o fluxo de anonimato do portal público (spec 043) continua exatamente como estava — nenhum card removido, e-mail continua obrigatório nesse fluxo específico (regra da 043, não desta feature), tipo "denúncia" continua indisponível nesse formulário (já não existia antes).

## Testes automatizados equivalentes (referência para `/speckit-tasks`)

- `ci-api-v2/src/modules/ouvidoria/ouvidoria.schemas.spec.ts` — substituir/estender `describe('identificação — condicional isAnonymous', ...)` por casos de `type !== 'whistleblower'` (Cenário 2), mantendo os casos de `replyEmail` existentes.
- `ci-client-v2/apps/web/src/modules/ouvidoria/__tests__/manifestacao-draft.schema.test.ts` — espelhar os mesmos casos do lado client.
- `ci-client-v2/apps/web/src/modules/ouvidoria/__tests__/ManifestacaoStepOneForm.validation.test.tsx` — remover asserts sobre os cards `isAnonymous`/`aria-pressed`; adicionar assert de que o grid de campos está sempre presente e que o campo E-mail está dentro dele.
- `ci-client-v2/apps/web/src/modules/ouvidoria/__tests__/ManifestacaoWizardPage.save-draft.test.tsx` e `ManifestacaoWizardPage.rascunho-local.test.tsx` — ajustar qualquer referência a `isAnonymous: true` no estado inicial/mock.
