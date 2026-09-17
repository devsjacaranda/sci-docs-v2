# Phase 1 — Data Model: Recuperar último rascunho de manifestação (Ouvidoria)

## 1. `RascunhoLocal` (IndexedDB — client, `apps/web`, exceção SC-010)

Object store `rascunho-local`, banco `ci-ouvidoria-rascunho` (nome isolado do resto do app), 1 registro por chave.

| Campo | Tipo | Obrigatório | Notas |
|---|---|---|---|
| `key` | `string` | ✅ (chave primária) | `` `${tenantId}:${userId}` `` — garante FR-002 (escopo por identidade+tenant) e FR-005 (1 único slot) |
| `tenantId` | `string` | ✅ | Redundante com `key` para consulta/depuração; sempre igual ao `VITE_TENANT_ID` ativo |
| `userId` | `string` | ✅ | `user.id` do `AuthContext` no momento da gravação |
| `manifestacaoId` | `string \| null` | — | Referência opaca ao registro institucional (`Manifestacao.id`), quando o `saveDraft()` já teve sucesso ao menos uma vez |
| `step` | `1 \| 2 \| 3` | ✅ | Etapa do assistente no momento da última gravação (FR-004) |
| `form` | `CreateManifestacaoDraftInput` (mesmo tipo de `manifestacao-draft.schema.ts`) | ✅ | Espelha exatamente os campos já coletados pelo assistente (FR-011) |
| `anexosPendentes` | `Array<{ id: string; fileName: string; mimeType: string; sizeBytes: number; blob: Blob }>` | ✅ (pode ser `[]`) | Apenas anexos **ainda não confirmados** no servidor; sujeitos ao limite de R5 (30MB/5 arquivos) |
| `createdAt` | `number` (epoch ms) | ✅ | Primeira gravação deste slot |
| `updatedAt` | `number` (epoch ms) | ✅ | Última gravação — usado para expiração de 24h (FR-015) |

**Regras de validação/estado**:
- Um registro só é considerado "elegível para convite" (FR-003) se: `Date.now() - updatedAt <= 24h` **e** `form` tem ao menos um campo de negócio não vazio além dos valores iniciais do formulário vazio (US1 cenário 3).
- Ao descartar (FR-009) ou confirmar envio com sucesso (FR-008), o registro é `delete`d do object store — não existe "soft delete" local.
- Ao detectar `retomavel === false` via `GET .../retomabilidade` (FR-007), o registro é `delete`d (não apenas ocultado na UI) — evita reaparecer após F5.
- Anexo que faria o total exceder 30MB/5 arquivos é **descartado no momento da gravação local** (nunca persistido), não apenas escondido depois (FR-017).

## 2. Estado de retomabilidade (API — não persistido, resposta de leitura)

Resultado computado do endpoint `GET /ouvidoria/manifestacoes/:id/retomabilidade` (ver `contracts/rest-api-retomabilidade.md`).

| Campo | Tipo | Notas |
|---|---|---|
| `retomavel` | `boolean` | `true` somente se `status === draft` e o registro pertence ao operador (via `resolveUserTableId`) + tenant do requisitante |
| `status` | `ManifestacaoStatus` (enum já existente: `draft \| in_review \| forwarding \| answered \| closed \| closed_unresolved`) | Status atual no servidor, para eventual mensagem específica ao operador |

**Transições relevantes** (não é uma state machine nova — reaproveita `ManifestacaoStatus` já existente em `ci-api-v2/prisma/schema/manifestacao.prisma`):

```text
draft --(confirmar envio)--> in_review --(tramitar/responder/encerrar)--> answered|forwarding|closed|closed_unresolved
```

`retomavel` é `true` unicamente no estado `draft`; qualquer transição adiante torna `retomavel = false` permanentemente para aquele `manifestacaoId` (não há caminho de volta a `draft`).

## 3. Entidades já existentes reaproveitadas (sem alteração de schema)

- **`Manifestacao`** (`ci-api-v2/prisma/schema/manifestacao.prisma`) — nenhuma migration necessária; a feature só lê `id`, `status`, `createdByUserId`, `tenantId` via `RequireManifestacaoRepository` já existente.
- **`CreateManifestacaoDraftInput`** (`ci-client-v2/apps/web/src/modules/ouvidoria/schemas/manifestacao-draft.schema.ts`) — reaproveitado como o shape do campo `form` do `RascunhoLocal`; qualquer novo campo de negócio adicionado ao assistente no futuro é automaticamente coberto sem alterar este data model.

## 4. Convite na lista (UI — estado derivado, não persistido)

Elemento computado por `use-ultimo-rascunho-convite`, combinando (1) leitura do IndexedDB e (2) resultado da retomabilidade quando aplicável:

| Estado | Condição | Comportamento do convite |
|---|---|---|
| `hidden` | Nenhum `RascunhoLocal` elegível, ou expirado, ou `retomavel === false` confirmado, ou consulta falhou tecnicamente (FR-016) | Não renderiza nada acima da tabela |
| `visible-unchecked` | `RascunhoLocal` elegível existe e **não** há `manifestacaoId` (nunca sincronizado) | Convite exibido, "Retomar" leva direto ao assistente com dados locais |
| `visible-checked` | `RascunhoLocal` elegível existe, há `manifestacaoId`, e `GET .../retomabilidade` respondeu `retomavel: true` | Convite exibido |

Não existe um quarto estado "visible mas não confirmado" por design — a decisão do `/speckit-clarify` (Q1) foi ocultar, não mostrar com aviso, quando a consulta falha tecnicamente.
