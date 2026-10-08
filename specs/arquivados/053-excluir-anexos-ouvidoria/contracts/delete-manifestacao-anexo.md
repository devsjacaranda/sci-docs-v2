# Contrato — Excluir anexo de manifestação

## Rota

`DELETE /ouvidoria/manifestacoes/:id/anexos/:anexoId`

| Item | Valor |
|---|---|
| Auth | JWT + `X-Tenant-ID` (pipeline padrão) |
| Guards | `@RequireModulo('ouvidoria')`; regra de acesso à manifestação (`ManifestacaoAccessService.assertForUser`, spec 047) |
| Rate limit | `@Throttle` restritivo (ex.: 20 req/min) |
| Body | nenhum |
| Params (Zod) | `id: string(trim,1..64)`, `anexoId: string(trim,1..64)` — sem exigir UUID (IDs migrados do v1) |
| Auditoria | `AuditInterceptor` (mutação `DELETE`) + evento `attachment_deleted` + tombstone |

## Respostas

### 200 — excluído (ou já excluído)

```json
{ "ok": true, "alreadyDeleted": false }
```

`alreadyDeleted: true` quando o anexo já estava excluído (idempotência): sem chamada ao storage, sem novo evento.

### Erros (`{ message, code }`, mensagens em PT-BR, sem detalhes internos)

| HTTP | `code` | Quando | Mensagem |
|---|---|---|---|
| 400 | `VALIDATION_FAILED` | params inválidos | "Verifique os campos destacados." |
| 401 | `UNAUTHORIZED` | sem sessão | — |
| 403 | `OUVIDORIA_ACCESS_DENIED` | sem acesso à manifestação | "Você não tem acesso a esta demanda." |
| 403 | `MODULO_SETOR_DENIED` / licença | sem permissão no módulo | padrão do pipeline |
| 404 | `OUVIDORIA_NOT_FOUND` | manifestação inexistente, removida ou de outro tenant | "Manifestação não encontrada." |
| 404 | `OUVIDORIA_ANEXO_NOT_FOUND` | anexo inexistente, de outra manifestação/tenant | "Anexo não encontrado." |
| 409 | `OUVIDORIA_ANEXO_DELETE_CLOSED` | manifestação encerrada (`closed`, `closed_unresolved`, `closed_meio_juridico`) | "Anexos não podem ser excluídos de uma manifestação encerrada." |
| 409 | `OUVIDORIA_ANEXO_DELETE_BLOCKED` | outro anexo ativo usa a mesma chave de armazenamento | "Este arquivo é usado por outro registro e não pode ser excluído." |
| 429 | `THROTTLED` (padrão) | excesso de requisições | padrão |
| 500 | `OUVIDORIA_ANEXO_DELETE_FAILED` | Wasabi indisponível/negou, retenção ativa, chave fora do tenant | "Não foi possível excluir o arquivo agora. Ele continua disponível. Tente novamente." |

Garantias de erro: em qualquer resposta ≠ 200, **nenhum** evento é criado e o anexo continua ativo; em 500 após o Wasabi ter apagado parcialmente, o retry conclui (idempotente).

## Contrato de leitura (alterações)

`GET /ouvidoria/manifestacoes/:id` (e revisão):

```json
{
  "anexos": [ { "id": "…", "kind": "file|link", "fileName": "…", "downloadUrl": "…" } ],
  "anexosExcluiveis": true
}
```

- `anexos` nunca contém itens excluídos.
- `anexosExcluiveis` = status ∉ {`closed`, `closed_unresolved`, `closed_meio_juridico`}. O client trata ausência como `false`.
- Evento na lista `eventos`: `{ "tipo": "attachment_deleted", "titulo": "Anexo excluído", "descricao": "Arquivo \"x.pdf\" excluído. Por Fulano.", "autorNome": "…|null" }`.

`GET` da consulta pública: `marcos` **não** inclui eventos `attachment_deleted`.

## Contrato do client

```ts
// api/anexos.ts
deleteManifestacaoAnexo(manifestacaoId: string, anexoId: string): Promise<{ ok: true; alreadyDeleted: boolean }>
// presignAnexo(...) e addLinkAnexo(...) devem expor o anexoId real para a lista local.
```

UI: botão "Excluir" por item (somente com `anexosExcluiveis`), diálogo `Dialog` com nome do arquivo, aviso de irreversibilidade ("O arquivo será apagado definitivamente e não poderá ser recuperado."), **foco inicial em Cancelar**, botão destrutivo "Excluir arquivo" (para link: "Remover link"), desabilitado durante a requisição; Esc/clique fora/Cancelar não chamam a API.
