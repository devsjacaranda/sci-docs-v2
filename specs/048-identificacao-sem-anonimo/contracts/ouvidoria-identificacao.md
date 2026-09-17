# Contract: Identificação do manifestante — rascunho de manifestação (assistente interno)

Base: `/ouvidoria/manifestacoes` (`OuvidoriaController`, `@RequireModulo('ouvidoria')` — autenticado, com módulo Ouvidoria liberado). Endpoints afetados por esta feature: `POST /ouvidoria/manifestacoes` (criar rascunho) e `PATCH /ouvidoria/manifestacoes/:id` (atualizar rascunho). **Não afetados**: `POST /ouvidoria/manifestacoes/:id/confirmar` (não revalida estes campos — a validação ocorre no save do rascunho, antes de confirmar) e todos os endpoints sob `/ouvidoria/publico/*` (portal público, fora de escopo — spec 043).

## POST `/ouvidoria/manifestacoes` — criar rascunho

**Body** (`createManifestacaoDraftBodySchema`) — campos relevantes para esta feature:

```jsonc
{
  "type": "complaint" | "request" | "whistleblower" | "praise" | "suggestion" | "simplify",
  "subject": "...",
  "description": "...",
  "requesterFullName": "Maria Silva",      // obrigatório, EXCETO quando type = "whistleblower"
  "replyEmail": "maria@example.com",       // opcional em qualquer type; validado como e-mail quando preenchido
  "requesterDocument": "...",               // opcional (inalterado)
  "holderName": "...",                      // opcional (inalterado)
  "registrationNumber": "...",              // opcional (inalterado)
  "requesterHomePhone": "...",              // opcional (inalterado)
  "requesterMobilePhone": "...",            // opcional (inalterado)
  "requesterBusinessPhone": "..."           // opcional (inalterado)
  // "isAnonymous" pode ser omitido — default passa a ser `false` (antes era `true`)
}
```

**Mudança de comportamento**:
- **Antes**: `requesterFullName` só era obrigatório se `isAnonymous: false` fosse explicitamente enviado; por padrão (`isAnonymous` omitido) o rascunho nascia anônimo e nenhum campo de identificação era exigido.
- **Depois**: `requesterFullName` é obrigatório sempre que `type !== 'whistleblower'`, **independentemente** de `isAnonymous`. Quando `type === 'whistleblower'`, `requesterFullName` continua opcional (mesma regra de antes para "identificada com nome" se preenchido — sem regra nova de formato).

**Respostas**:
- `201`: rascunho criado — `isAnonymous` na resposta é sempre `false` para registros criados a partir desta mudança (exceto se o chamador enviar `isAnonymous: true` explicitamente — comportamento legado preservado por compatibilidade, não exercitado pela UI atual).
- `400 VALIDATION_FAILED`, path `requesterFullName`, mensagem `"Informe o nome do solicitante."` — quando `type !== 'whistleblower'` e `requesterFullName` vazio/ausente.
- `400 VALIDATION_FAILED`, path `replyEmail` — quando `replyEmail` preenchido em formato inválido (mensagem inalterada: `"E-mail de resposta inválido."`).

## PATCH `/ouvidoria/manifestacoes/:id` — atualizar rascunho

Mesmo `body` (schema `.partial()`), mesma regra de `requesterFullName` reaplicada a cada PATCH com os campos combinados (campos não enviados mantêm o valor já persistido — comportamento de `.partial()` inalterado). Exemplo:

- Rascunho com `type: "complaint"` e `requesterFullName` vazio → `PATCH { "subject": "novo assunto" }` → **ainda falha** com `400` em `requesterFullName` (a obrigatoriedade se aplica ao estado final do registro, não apenas ao body do PATCH — mesma semântica de validação incremental já existente para outros campos condicionais, ex. `concessionaria`).
- Rascunho muda de `type: "whistleblower"` para `type: "complaint"` via `PATCH { "type": "complaint" }`, sem `requesterFullName` preenchido → `400` em `requesterFullName` (edge case da spec: a exceção deixa de valer quando o tipo muda).

**Respostas**: mesmos códigos/mensagens do POST.

## Tabela de exemplos (matriz de decisão)

| `type` | `requesterFullName` | Resultado |
|---|---|---|
| `complaint` / `request` / `praise` / `suggestion` / `simplify` | preenchido | ✅ 201/200 |
| `complaint` / `request` / `praise` / `suggestion` / `simplify` | vazio/ausente | ❌ 400 `requesterFullName` |
| `whistleblower` | preenchido | ✅ 201/200 |
| `whistleblower` | vazio/ausente | ✅ 201/200 (exceção) |

## Fora de escopo desta feature (inalterado)

- `POST /ouvidoria/publico/manifestacoes` (`criarManifestacaoPublicaBodySchema`) — continua exigindo `email` sempre (já era obrigatório nesse schema, independente desta feature) e continua aceitando `isAnonymous` como escolha do cidadão; `manifestacaoTipoPublico` não inclui `whistleblower`.
- `GET /ouvidoria/manifestacoes/:id`, `/:id/revisao` — resposta já inclui `isAnonymous`/`requester`/`replyEmail`; nenhuma mudança de forma de resposta, apenas o valor de `isAnonymous` tende a ser sempre `false` em registros novos.
