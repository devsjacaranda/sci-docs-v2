# Test Strategy — 045 Rascunho local de manifestação (Ouvidoria)

TDD obrigatório (Constitution II). Prefixo novo `CT-OUV-RASCUNHO-*` (API) e `CT-OUV-RASCUNHO-CLIENT-*` (web).

## API (Jest) — RED primeiro

| ID | Alvo | Casos |
|---|---|---|
| CT-OUV-RASCUNHO-001 | `GetManifestacaoRetomabilidadeUseCase` | `draft` + dono/tenant correto → `{ retomavel: true, status: 'draft' }`; `in_review`/`forwarding`/`answered`/`closed`/`closed_unresolved` → `{ retomavel: false, status }`; outro operador do mesmo tenant → `{ retomavel: false }` (sem erro); id inexistente → `NotFoundException`; outro tenant → `NotFoundException` (nunca `403`, evita enumeração) |
| CT-OUV-RASCUNHO-002 | `OuvidoriaController.retomabilidade` (novo handler) | passa `{ userId, role }` do `req.user` ao use-case; rota exige `@RequireModulo('ouvidoria')` |
| CT-OUV-RASCUNHO-003 | Isolamento multi-tenant (espelha `SC-009` da 038) | requisição com `X-Tenant-ID` de outro tenant para um `manifestacaoId` válido → `404`, nunca confirma existência |

## Client (Vitest) — RED primeiro

| ID | Alvo | Casos |
|---|---|---|
| CT-OUV-RASCUNHO-CLIENT-001 | `rascunho-local-store.ts` (com `fake-indexeddb`) | `put`/`get`/`delete` por chave `tenantId:userId`; `get` de chave inexistente → `null`; `put` duas vezes na mesma chave → sobrescreve (nunca 2 registros) |
| CT-OUV-RASCUNHO-CLIENT-002 | `rascunho-local-expiry.ts` | `updatedAt` há 23h59 → elegível; há 24h01 → não elegível + remove o registro na leitura |
| CT-OUV-RASCUNHO-CLIENT-003 | `rascunho-local-anexos-limit.ts` | soma ≤ 30MB e ≤ 5 arquivos → todos entram; anexo que faria exceder → descartado (não persistido), sinal de aviso retornado para a UI |
| CT-OUV-RASCUNHO-CLIENT-004 | `use-rascunho-local-autosave` | muda campo → grava (debounce); sem mudança por 5s → não grava de novo; muda etapa → grava imediatamente, mesmo sem mudança de campo |
| CT-OUV-RASCUNHO-CLIENT-005 | `use-ultimo-rascunho-convite` | sem `manifestacaoId` → `visible-unchecked` sem chamar API; com `manifestacaoId` + API `retomavel: true` → `visible-checked`; API `retomavel: false` → `hidden` + apaga registro local; API falha (rede/timeout) → `hidden`, mantém registro local intocado (permite nova tentativa na próxima carga) |
| CT-OUV-RASCUNHO-CLIENT-006 | `UltimoRascunhoBanner` (RTL) | renderiza convite quando `visible-*`; nada quando `hidden`; clique em "Retomar" navega para `/ouvidoria/manifestacoes/nova` com estado de hidratação; clique em "Descartar" exige confirmação antes de remover |
| CT-OUV-RASCUNHO-CLIENT-007 | `ManifestacaoWizardPage` (RTL, novo cenário) | ao montar com rascunho local elegível e flag de retomada → hidrata `form`/`step` a partir do IndexedDB, sem chamar `getManifestacaoDetail` quando não há `editId` |
| CT-OUV-RASCUNHO-CLIENT-008 | `no-business-storage.test.ts` (atualização do guardrail existente) | passa a aceitar `indexedDB`/`idb` **apenas** em `lib/rascunho-local/**`; qualquer outro arquivo do módulo com `indexedDB`/`localStorage`/`sessionStorage` fora do allowlist continua falhando o teste |

## Ordem RED → GREEN

1. `GetManifestacaoRetomabilidadeUseCase` (API, puro em relação ao resto do domínio)
2. `OuvidoriaController.retomabilidade` (fiação do handler)
3. `rascunho-local-store` + `rascunho-local-expiry` + `rascunho-local-anexos-limit` (client, puro, com `fake-indexeddb`)
4. `use-rascunho-local-autosave` (hook)
5. Atualização do `no-business-storage.test.ts` (allowlist) — **antes** de qualquer arquivo em `lib/rascunho-local/**` existir, para provar que o teste falharia sem o allowlist
6. `use-ultimo-rascunho-convite` (combina store + API)
7. `UltimoRascunhoBanner` + integração em `ManifestacoesListPage`
8. Integração em `ManifestacaoWizardPage` (hidratação + gravação + limpeza ao confirmar/descartar)

## E2E

Não obrigatório nesta entrega (mesma decisão da 044 para o caminho feliz). Se o Playwright interno de ouvidoria estiver disponível, um cenário de "preencher etapa 1 sem servidor (rota mockada offline) → simular novo login → retomar pelo convite" é o candidato natural para entrar depois.
