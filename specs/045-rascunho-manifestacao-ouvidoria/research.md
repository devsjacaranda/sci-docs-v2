# Phase 0 — Research: Recuperar último rascunho de manifestação (Ouvidoria)

Todas as ambiguidades de `spec.md` já foram resolvidas em `/speckit-clarify` (ver seção `## Clarifications`). Este documento resolve as decisões técnicas necessárias para a implementação (o "COMO"), levantadas ao inspecionar o código existente.

---

## R1 — Mecanismo de storage local (exceção SC-010)

**Decisão**: IndexedDB, acessado via a lib `idb` (wrapper leve, tipado, assíncrono; mesma linhagem do Workbox já usado pelo `vite-plugin-pwa` presente em `apps/web`). Um único object store `rascunho-local`, chave primária = `` `${tenantId}:${userId}` ``.

**Rationale**:
- **Por que não `localStorage`**: síncrono (bloqueia a main thread a cada escrita), limite de ~5-10MB por origem, só aceita strings — inviável para incluir anexos binários (FR-011/FR-017 exigem incluir arquivos ainda não enviados).
- **Por que não `sessionStorage`**: mesmas limitações de `localStorage` **e** é apagado ao fechar a aba/navegador — contraria a User Story 3 ("fecha o navegador e reabre após login" deve manter o rascunho).
- **Por que IndexedDB**: assíncrono (não bloqueia digitação), aceita `Blob`/`File` nativamente (armazena anexos sem serializar para base64), quota tipicamente centenas de MB a alguns GB (via `navigator.storage.estimate()`), e sobrevive a fechar o navegador — exatamente o requisito de US1/US3.
- **Exceção à SC-010**: ver `plan.md` (Constitution Check) e a nota já registrada em `civ2-docs/specs/038-migracao-modulos-v1/spec.md` (SC-010) e `research.md` (addendum ao R15). A exceção é estreita: só os arquivos em `ci-client-v2/apps/web/src/modules/ouvidoria/lib/rascunho-local/**` podem tocar `indexedDB`; nenhum outro arquivo do módulo ganha essa permissão.

**Alternatives considered**:
- **Cache API / Service Worker storage**: rejeitada — pensada para respostas HTTP, não para dados estruturados de formulário; adicionaria complexidade do `vite-plugin-pwa` sem benefício.
- **Dexie.js**: biblioteca mais completa sobre IndexedDB, mas maior superfície e dependências — `idb` é suficiente para 1 object store simples e mantém a superfície da exceção mínima.
- **Manter em memória (Context/Zustand) sem persistência**: rejeitada — não sobrevive ao reload/fechamento de aba que o `registerSessionLostHandler` força ao detectar 401/erro de rede (ver R2).

---

## R2 — Gatilho real de perda de sessão no client

**Decisão**: o gatilho é `apiFetch` (`ci-client-v2/packages/shared/src/api/create-api-client.ts`) chamando `notifySessionLost('unauthorized' | 'network')` em 401 ou falha de `fetch`, que o `AuthProvider` (`modules/auth/context/AuthContext.tsx`) consome via `registerSessionLostHandler` para: limpar `user`, chamar `authLogout()`, e **navegar para `/login`** (`sessionNavigate`, substituindo a rota atual). Isso desmonta `ManifestacaoWizardPage` e descarta todo estado em memória — confirma que a persistência precisa ser **durável e fora do ciclo de vida do componente/contexto React**, escrita continuamente durante o preenchimento (não só "ao detectar a falha", porque a falha não dá aviso prévio).

**Rationale**: valida a escolha de storage local assíncrono e contínuo (FR-001) em vez de uma tentativa de "capturar o evento de logout e salvar nesse momento" — não há garantia de tempo/ciclo de vida suficiente no momento exato da falha.

**Alternatives considered**: interceptar `registerSessionLostHandler` para forçar 1 gravação de última chance — rejeitada como mecanismo **único**: complementa, mas não substitui, a gravação contínua a cada 5s/mudança de campo já exigida por FR-001.

---

## R3 — Reaproveitamento do rascunho institucional existente

**Decisão**: o assistente já chama `createManifestacaoDraft`/`updateManifestacaoDraft` (via `saveDraft()` em `ManifestacaoWizardPage.tsx`) ao avançar da etapa 1 para a 2 — isso já cria um registro `Manifestacao` com `status = draft` no servidor quando a API está disponível. O rascunho local **referencia esse `manifestacaoId`** quando ele existir (armazenado no registro IndexedDB), mas continua existindo de forma independente quando esse `manifestacaoId` ainda não existe (ex.: a própria chamada de criação falhou por queda de API — exatamente o cenário motivador).

**Rationale**: evita duplicar o conceito de "rascunho" — o registro institucional (`Manifestacao.status = draft`) continua sendo a fonte de verdade para o fluxo de edição/listagem já existente; o rascunho local é um **cache de resiliência** por cima dele, nunca uma segunda fonte de verdade paralela.

---

## R4 — Endpoint de retomabilidade (FR-006)

**Decisão**: novo endpoint dedicado `GET /ouvidoria/manifestacoes/:id/retomabilidade`, com use-case próprio `GetManifestacaoRetomabilidadeUseCase`, retornando um payload mínimo `{ retomavel: boolean; status: ManifestacaoStatus }` — **não** o detalhe completo da manifestação.

**Rationale**:
- **Por que não reaproveitar `GET /ouvidoria/manifestacoes/:id` (`GetManifestacaoDetailUseCase`)** direto: esse endpoint devolve o payload completo (todos os campos de negócio, anexos, etc.) só para responder "ainda posso retomar?" — desnecessário e mais pesado a cada carga da lista, além de ampliar a superfície de dados expostos numa checagem que deveria ser mínima.
- Reaproveita `RequireManifestacaoRepository` (já existe, já valida tenant via `getRequestContext()`) para buscar o registro; adiciona checagem de posse (o `createdByUserId` do registro deve corresponder ao `resolveUserTableId(actor.userId, actor.role)` do requisitante — ver regra `admin-tenant-user-fk`) antes de responder `retomavel`.
- `retomavel = true` somente se `status === ManifestacaoStatus.draft` **e** o registro pertence ao operador+tenant requisitante. Qualquer outro caso (`in_review`, `forwarding`, `answered`, `closed`, `closed_unresolved`, 404, ou não pertence ao operador) → `retomavel = false`.

**Alternatives considered**: expor via `GET /ouvidoria/manifestacoes/:id` existente com um novo query param `?somenteStatus=1` — rejeitada: misturaria duas responsabilidades no mesmo endpoint/use-case, violando "1 arquivo = 1 operação" (constitution V).

**Sem consulta quando não há `manifestacaoId`**: se o rascunho local nunca chegou a ser criado no servidor (nenhum `manifestacaoId` referenciado), a consulta de retomabilidade é **dispensada** — o convite é oferecido com base apenas no estado local (não há nada a revalidar ainda). A postura conservadora do FR-016 (ocultar em caso de falha técnica) aplica-se apenas quando **existe** `manifestacaoId` e a consulta a esse endpoint falha tecnicamente.

---

## R5 — Limite de anexos locais (FR-017)

**Decisão**: até **5 arquivos** e **30MB no total** por rascunho local (mesma ordem de grandeza do limite já usado para upload individual, `MAX_ANEXO_BYTES = 30 * 1024 * 1024` em `ouvidoria-anexo.constants.ts`). Arquivo/anexo que faria o total exceder o limite não entra na cópia local; a UI avisa que ele precisará ser reanexado ao retomar (FR-017).

**Rationale**: alinhar com um limite já validado e testado no backend para um único anexo evita introduzir um número arbitrário novo; multiplicar por ~1 arquivo médio grande + folga para 2-4 pequenos é suficiente para o caso de uso real (poucos documentos/fotos por manifestação).

**Alternatives considered**: sem limite (aceitar o que o navegador permitir) — rejeitado no `/speckit-clarify` por risco de falha silenciosa de armazenamento do navegador.

---

## R6 — Periodicidade de autosave e granularidade de escrita (FR-001)

**Decisão**: hook `use-rascunho-local-autosave` grava a cada mudança relevante de campo (debounce curto, ex. `onBlur`/`onChange` com immediate write) **ou** no máximo a cada 5s como salvaguarda via `setInterval` que só escreve se houver alteração pendente desde a última gravação — o que ocorrer primeiro — e sempre imediatamente ao mudar de etapa do assistente (decisão já fechada em `/speckit-clarify`).

**Rationale**: evita gravações excessivas (uma por tecla) sem arriscar perda maior que poucos segundos de digitação.

---

## R7 — Expiração de 24h (FR-015)

**Decisão**: cada registro IndexedDB grava `updatedAt` (timestamp). Ao ler o rascunho (na lista ou no assistente), calcula-se `Date.now() - updatedAt > 24h` → trata como inexistente e remove o registro (limpeza lazy, sem worker/cron — não há necessidade de expirar proativamente em background para um dado local de um único usuário/aba).

**Rationale**: mais simples que agendar limpeza em background; suficiente porque o dado só importa quando é lido (convite na lista ou hidratação do assistente).

---

## R8 — Testabilidade do storage local

**Decisão**: `fake-indexeddb` como devDependency do `apps/web`, registrado via `setupFiles` do Vitest (import `fake-indexeddb/auto` no arquivo de setup existente ou um novo `vitest.setup.rascunho-local.ts`), permitindo testar `rascunho-local-store.ts`/hooks sem mocks manuais de IndexedDB.

**Rationale**: padrão amplamente usado para testar código IndexedDB em Node/jsdom; evita reinventar um mock e mantém os testes fiéis à API real do navegador.

---

## R9 — Atualização do guardrail `no-business-storage.test.ts`

**Decisão**: o teste (que hoje só verifica `localStorage.`/`sessionStorage.` via regex) precisa de duas mudanças, a serem feitas em `/speckit-tasks`/`/speckit-implement`:
1. Adicionar verificação equivalente para `indexedDB.open(` / uso de `idb`'s `openDB(` fora do allowlist.
2. Allowlist explícito: apenas arquivos dentro de `modules/ouvidoria/lib/rascunho-local/**` podem conter essas chamadas; qualquer outro arquivo do módulo continua proibido (mantendo a SC-010 para todo o resto).
3. Comentário no topo do teste linkando esta spec (045) e a nota de exceção em `038/spec.md` (SC-010), para que o próximo leitor entenda a origem da exceção sem arqueologia de git.

**Rationale**: mantém o guardrail vivo e auditável em vez de apenas relaxá-lo silenciosamente.

---

## Resumo das decisões (para Phase 1)

| Tema | Decisão |
|---|---|
| Storage local | IndexedDB via `idb`, 1 object store, chave `tenantId:userId` |
| Escopo da exceção SC-010 | Só `modules/ouvidoria/lib/rascunho-local/**` |
| Endpoint retomabilidade | `GET /ouvidoria/manifestacoes/:id/retomabilidade` → `{ retomavel, status }` |
| Sem `manifestacaoId` ainda | Consulta dispensada; convite baseado só no local |
| Limite de anexos locais | 30MB total / 5 arquivos por rascunho |
| Periodicidade autosave | Por campo (debounce) OU 5s, o que ocorrer primeiro; sempre por etapa |
| Expiração | 24h, checada lazy na leitura |
| Testes client | Vitest + `fake-indexeddb` |
| Guardrail | `no-business-storage.test.ts` ganha allowlist + checagem de IndexedDB |
