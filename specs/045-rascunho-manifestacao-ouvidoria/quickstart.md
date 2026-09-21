# Quickstart — 045 Rascunho local de manifestação (Ouvidoria)

Validação ponta a ponta **depois** de `/speckit-implement`. Não é guia de implementação — ver `data-model.md` e `contracts/`.

## Pré-requisitos

- API: `cd ci-api-v2; npm run start:dev`
- Web: `cd ci-client-v2; npm run dev`
- Seed Jacarandá: `cd ci-api-v2; npm run prisma:seed`
- Conta operador (`user`) autenticada no módulo Ouvidoria
- DevTools do navegador (aba Application → IndexedDB) para inspecionar o registro `ci-ouvidoria-rascunho`

## 1. Testes automatizados (prova principal)

```powershell
cd ci-api-v2
npm test -- --testPathPatterns=rascunho

cd ci-client-v2/apps/web
npm test -- rascunho-local no-business-storage
```

Esperado: suíte `CT-OUV-RASCUNHO-*` / `CT-OUV-RASCUNHO-CLIENT-*` verde, incluindo o guardrail `no-business-storage.test.ts` atualizado (allowlist de `lib/rascunho-local/**`) continuando verde.

## 2. Resiliência a queda de API/rede (US1 / US3 — SC-001)

1. Login como operador → `/ouvidoria/manifestacoes/nova`.
2. Preencher assunto + descrição (etapa 1) — **sem avançar ainda**.
3. Nas DevTools, bloquear a rede (aba Network → Offline) ou derrubar a API (`Ctrl+C` no `start:dev`).
4. Aguardar ~5s (janela de autosave) e confirmar em Application → IndexedDB → `ci-ouvidoria-rascunho` que o registro existe com os dados digitados.
5. Restaurar a rede/API, recarregar a página, autenticar de novo se necessário.
6. Abrir `/ouvidoria/manifestacoes`: convite de "último rascunho" aparece **acima da tabela**.
7. Clicar em retomar → assistente reabre com os mesmos dados na etapa em que estava.

## 3. Convite some quando já foi enviado (US2 — SC-002)

1. Com um rascunho local elegível existente (passo 2), avançar o assistente até confirmar o envio com sucesso.
2. Voltar a `/ouvidoria/manifestacoes`: o convite **não** aparece.
3. Confirmar no IndexedDB que o registro foi removido.

## 4. Verificação de retomabilidade conservadora (Q1 do clarify — FR-016)

1. Criar um rascunho local com `manifestacaoId` já sincronizado (etapa 1 concluída com API disponível).
2. Derrubar só a rota `GET /ouvidoria/manifestacoes/:id/retomabilidade` (ex.: via proxy/mock) mantendo o resto da API no ar.
3. Abrir a lista: convite **não** aparece (postura conservadora), mas o registro local permanece intacto no IndexedDB.
4. Restaurar a rota e recarregar: convite volta a aparecer normalmente.

## 5. Limite de anexos locais (Q2 do clarify — FR-017)

1. Na etapa 2 do assistente, anexar arquivos que somem mais de 30MB (ou mais de 5 arquivos) antes de qualquer confirmação.
2. Simular queda de API/sessão.
3. Ao retomar: os anexos que couberam no limite estão presentes; os excedentes exibem aviso pedindo para reanexar manualmente.

## 6. Confirmação de descarte (Q4 do clarify — FR-009)

1. Com convite de último rascunho visível na lista, ir em "Nova manifestação".
2. Sistema exige confirmação explícita antes de descartar (há dados no rascunho).
3. Confirmar → convite desaparece, assistente abre vazio, registro removido do IndexedDB.

## 7. Isolamento por operador/tenant (SC-004)

1. Criar rascunho local elegível com o Operador A.
2. Fazer logout e login com o Operador B **no mesmo navegador/dispositivo**.
3. Abrir a lista: convite do Operador A **não** aparece para o Operador B.

## Fora deste guia

- Canal público de manifestação do cidadão.
- Edição de manifestação já existente (`/ouvidoria/manifestacoes/:id/editar`) — fora do escopo desta feature (FR-013).
- Sincronização do rascunho entre dispositivos diferentes do mesmo operador (fora de escopo v1).
