# Research: Identificação sem anônimo + e-mail

**Phase 0** — a spec já resolveu todo o "o quê" nas duas sessões de clarificação; o que resta aqui é **como implementar** sem migração e sem tocar o portal público.

## 1. O que fazer com a coluna/campo `isAnonymous`

**Decision**: Manter a coluna `Manifestacao.isAnonymous` e o campo `isAnonymous` em `draftFieldsSchema` (API) e `createManifestacaoDraftSchema` (client), mas:
- Trocar o valor padrão de `.default(true)` para `.default(false)` em `draftFieldsSchema` (API).
- Deixar de usar `isAnonymous` como gatilho da regra "nome obrigatório" — o gatilho passa a ser `type === 'whistleblower'` (ver §2).
- O client simplesmente para de oferecer uma forma de o usuário setar `isAnonymous: true` (os cards que faziam isso são removidos) — o campo, se ainda enviado, vai sempre como `false`.

**Rationale**: Remover a coluna exigiria migração (`DROP COLUMN`) e quebraria leitura de registros legados (FR-011 exige que manifestações/rascunhos anônimos anteriores continuem exibidos exatamente como estão — `ManifestacaoRequesterCard.tsx` ainda depende de `view.isAnonymous` para decidir o card "Manifestação anônima"). Manter a coluna com novo default é zero-migração e 100% retrocompatível. `sanitizeDraftInput` (que hoje apaga os campos de identificação quando `isAnonymous: true`) continua existindo mas nunca mais é acionada por este fluxo, pois o client nunca mais envia `true`.

**Alternatives considered**:
- Remover `isAnonymous` do banco e da API — rejeitado por exigir migração e quebrar `ManifestacaoRequesterCard`/`manifestacao-detail-view.ts`, que dependem dele para os registros legados (fora de escopo alterar retroativamente — FR-011).
- Manter `isAnonymous` como gatilho da obrigatoriedade de nome (como é hoje) e apenas parar de expor o toggle no client, deixando o client sempre mandar `isAnonymous: false` — quase equivalente, mas não cobre a exceção de denúncia sem um segundo gatilho paralelo; misturar dois booleanos (`isAnonymous` e "é denúncia") para a mesma decisão de obrigatoriedade é mais confuso do que decidir direto por `type`. Rejeitada em favor da opção adotada.

## 2. Onde aplicar a exceção de nome obrigatório para denúncia

**Decision**: Reescrever a função pura `refineIdentifiedManifestacaoRequiresName` (API, `ouvidoria.schemas.ts`) para `refineRequesterNameRequiredUnlessWhistleblower`, com a regra:

```typescript
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

Aplicada em `createManifestacaoDraftBodySchema` e `updateManifestacaoDraftBodySchema` (mesmo ponto onde `refineIdentifiedManifestacaoRequiresName` já era chamada). No client, a mesma regra é espelhada em `createManifestacaoDraftSchema` (`manifestacao-draft.schema.ts`), conforme convenção já documentada no arquivo ("Espelha ci-api-v2/...").

**Rationale**: É o mesmo padrão já usado no projeto (`superRefine` puro, mensagem em PT-BR, path no campo). Trocar apenas o predicado do `if` (de `isAnonymous === false` para `type !== 'whistleblower'`) minimiza o diff e mantém 100% dos outros comportamentos de validação (max length, e-mail opcional, etc.) intactos.

**Alternatives considered**: Criar um novo campo booleano explícito (`requiresIdentification`) calculado a partir do `type` — rejeitado por ser um nível de indireção sem ganho: `type` já é a fonte da verdade (enum fechado com 6 valores), não muda com frequência, e checar `type !== 'whistleblower'` é tão legível quanto checar uma flag derivada.

## 3. Reaproveitar `replyEmail` como o campo único de e-mail (sem rename)

**Decision**: Não criar um campo novo (`requesterEmail` ou similar) nem renomear `replyEmail`. O campo já é rotulado **"E-mail"** em `ManifestacaoRequesterCard.tsx` (`REQUESTER_FIELDS`, `label: 'E-mail'`) e já aparece ao lado dos outros dados do manifestante na tela de detalhe — ou seja, o *dado* já é conceitualmente "o e-mail do manifestante", só a *localização no formulário de criação/edição* precisa mudar (do Card solto "E-mail para resposta" para dentro do Card "Identificação").

**Rationale**: Renomear o campo (banco, DTO, mapper, geração de PDF/DOCX, `manifestacao-detail-view.ts`) tocaria muito mais arquivos do que o pedido exige, sem nenhum ganho funcional — a spec (FR-006/FR-007) já foi escrita em termos de comportamento ("um único campo, dentro do bloco"), não de nome de campo. Ficou registrado como assumption na spec.

**Alternatives considered**: Introduzir `requesterEmail` como alias e depreciar `replyEmail` — rejeitado por complexidade desnecessária (dois campos apontando pro mesmo dado, sincronização, migração futura) sem que a spec peça isso.

## 4. Onde mover o campo E-mail dentro do JSX (`ManifestacaoStepOneForm.tsx`)

**Decision**: O campo `E-mail` (hoje um `<Field>` dentro de um `<Card>` isolado, logo **antes** do `<Card>` "Identificação") passa a ser o **primeiro campo** dentro do grid de dados do manifestante (`grid gap-4 sm:grid-cols-2`), antes de "Nome completo" — junto com a remoção do wrapper condicional `{!form.isAnonymous && (...)}` em torno desse grid (o grid passa a renderizar sempre). O `<Card>` isolado do e-mail é removido.

**Rationale**: Mantém o mesmo componente `Field`/`Input` já usado (`type="text" inputMode="email" autoComplete="email"`, ícone `Mail`), só troca o container pai. Posicionar como primeiro campo do bloco (antes do nome) segue a leitura natural do print original (campo de contato como parte da identificação, não like um adendo ao final).

**Alternatives considered**: Manter o e-mail como último campo do grid (após os telefones) — funcionalmente equivalente; não há requisito de ordem na spec. Optou-se por "primeiro campo" apenas por legibilidade do diff e proximidade semântica com "quem é" antes de "como falar com essa pessoa"; `/speckit-tasks` pode ajustar a ordem exata sem impacto de contrato.

## 5. Remoção dos cards — o que exatamente sai do JSX

**Decision**: Remove o bloco `<div className="grid gap-3 sm:grid-cols-2">...</div>` inteiro (os dois `<button>` de escolha) dentro do `<Card>` "Identificação", e o `<SectionHeader>` dessa seção tem a `description` trocada de *"Escolha se o manifestante permanece anônimo ou deseja se identificar."* para uma frase neutra (ex.: *"Dados do manifestante."*) — atende FR-010. O `{!form.isAnonymous && (...)}` que envolvia o grid de campos vira apenas `(...)` (sempre renderizado).

**Rationale**: Menor diff possível que satisfaz FR-001/FR-002/FR-010 sem tocar em mais nada da estrutura de `SectionHeader`/`Field` já usada no resto do arquivo.

## 6. Escopo confirmado: só `apps/web`, nada em `apps/publico`

**Decision**: Nenhum arquivo dentro de `ci-client-v2/apps/publico/` ou o schema `criarManifestacaoPublicaBodySchema` (API) é tocado por esta feature — confirmado explicitamente na sessão `/speckit-clarify` (FR-008/Out of Scope).

**Rationale**: Decisão explícita do usuário, revertendo uma decisão anterior mais ampla tomada durante `/speckit-specify`. O portal público já tem seu próprio schema (`manifestacaoTipoPublico`, que nem sequer inclui `whistleblower`) e seu próprio fluxo de anonimato, especificados na spec 043 — misturar as duas manutenções aumentaria o raio de impacto sem pedido do usuário.
