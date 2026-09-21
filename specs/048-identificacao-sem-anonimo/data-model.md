# Data Model: Identificação sem anônimo + e-mail

Nenhuma tabela ou coluna nova. Esta feature altera apenas **regras de validação e valores padrão** na camada Zod, sobre colunas já existentes do model `Manifestacao` (ver `ci-api-v2/prisma/schema/manifestacao.prisma`).

## Colunas existentes afetadas (sem alteração de schema Prisma)

| Coluna | Antes | Depois (só para registros criados/atualizados por este fluxo) |
|---|---|---|
| `isAnonymous: Boolean @default(true)` | Controlava se o formulário exigia `requesterFullName`; UI permitia o usuário escolher `true` | Sempre gravado como `false` por este fluxo (default de aplicação muda para `false`); deixa de ser o gatilho de obrigatoriedade de nome. Coluna e valor `true` continuam válidos para **registros legados** (FR-011) — nenhuma migração/backfill. |
| `requesterFullName: String?` | Obrigatório apenas quando `isAnonymous === false` | Obrigatório sempre, **exceto** quando `type === 'whistleblower'` |
| `replyEmail: String?` | Campo opcional, exibido em um `<Card>` separado no formulário, rotulado "E-mail para resposta" | Mesmo campo, mesmo tipo, mesma opcionalidade — passa a ser exibido dentro do bloco "Identificação" do formulário, rotulado apenas "E-mail". Nenhuma mudança de nome/tipo/persistência. |

## Zod — API (`ci-api-v2/src/modules/ouvidoria/ouvidoria.schemas.ts`)

```typescript
// ANTES
isAnonymous: z
  .boolean({ error: 'Indicador de anonimato inválido.' })
  .optional()
  .default(true),

function refineIdentifiedManifestacaoRequiresName(
  data: { isAnonymous?: boolean; requesterFullName?: string },
  ctx: z.RefinementCtx,
) {
  if (data.isAnonymous === false && !data.requesterFullName?.trim()) {
    ctx.addIssue({
      code: 'custom',
      message: 'Informe o nome do solicitante em manifestação identificada.',
      path: ['requesterFullName'],
    });
  }
}
```

```typescript
// DEPOIS
isAnonymous: z
  .boolean({ error: 'Indicador de anonimato inválido.' })
  .optional()
  .default(false),

function refineRequesterNameRequiredUnlessWhistleblower(
  data: { type?: string; requesterFullName?: string },
  ctx: z.RefinementCtx,
) {
  if (data.type !== 'whistleblower' && !data.requesterFullName?.trim()) {
    ctx.addIssue({
      code: 'custom',
      message: 'Informe o nome do solicitante.',
      path: ['requesterFullName'],
    });
  }
}
```

Aplicada nos mesmos dois schemas que já usavam a função anterior:

```typescript
export const createManifestacaoDraftBodySchema = draftFieldsSchema
  .superRefine(refineRequesterNameRequiredUnlessWhistleblower)
  .transform(sanitizeDraftInput);

export const updateManifestacaoDraftBodySchema = draftFieldsSchema
  .partial()
  .superRefine(refineRequesterNameRequiredUnlessWhistleblower)
  .transform(sanitizeDraftInput);
```

`sanitizeDraftInput` **não muda** (continua limpando campos de identificação quando `isAnonymous` vier `true` — comportamento morto para este fluxo após a mudança, mas inofensivo e necessário para não quebrar chamadas que ainda enviem `isAnonymous: true` explicitamente, ex.: scripts/testes de regressão de dados legados).

`replyEmail` (`optionalReplyEmailSchema`) **não muda** — mesma validação de formato, mesmo `undefined` quando vazio.

## Zod — Client (`ci-client-v2/apps/web/src/modules/ouvidoria/schemas/manifestacao-draft.schema.ts`)

Espelha a mudança acima (comentário já existente no arquivo: *"Espelha ci-api-v2/..."*):

```typescript
// ANTES
.superRefine((data, ctx) => {
  if (data.isAnonymous === false && !data.requesterFullName?.trim()) {
    ctx.addIssue({
      code: z.ZodIssueCode.custom,
      path: ['requesterFullName'],
      message: 'Informe o nome do solicitante em manifestação identificada.',
    });
  }
});
```

```typescript
// DEPOIS
.superRefine((data, ctx) => {
  if (data.type !== 'whistleblower' && !data.requesterFullName?.trim()) {
    ctx.addIssue({
      code: z.ZodIssueCode.custom,
      path: ['requesterFullName'],
      message: 'Informe o nome do solicitante.',
    });
  }
});
```

`isAnonymous` continua no `z.object({...})` como `z.boolean().optional()` (tipo inalterado — só deixa de influenciar o `superRefine`).

## Estado inicial do formulário (client)

`ManifestacaoWizardPage.tsx` — `emptyForm`:

```typescript
// ANTES
isAnonymous: true,

// DEPOIS
isAnonymous: false,
```

## Entidades não afetadas

- **`ManifestacaoConcessionaria`**, **`ManifestacaoAnexo`**, **`ManifestacaoEvento`** — sem relação com esta feature.
- **Portal público** (`criarManifestacaoPublicaBodySchema`, `ci-api-v2/src/modules/ouvidoria/ouvidoria.schemas.ts`) — schema totalmente separado (`manifestacaoTipoPublico`, que já **não inclui** `whistleblower`); fora de escopo (FR-008), não sofre nenhuma alteração.
- **`ManifestacaoRequesterCard.tsx`** (client, tela de detalhe) — o branch `if (view.isAnonymous)` que exibe "Manifestação anônima" permanece exatamente como está, para continuar exibindo corretamente os registros legados (FR-011). Para registros novos (sempre `isAnonymous: false`), esse branch simplesmente nunca mais é acionado neste fluxo.
