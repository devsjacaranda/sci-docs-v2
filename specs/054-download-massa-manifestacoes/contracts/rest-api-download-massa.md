# Contrato — Download em massa de manifestações

Prefixo igual ao resto da Ouvidoria (`/ouvidoria`). Todas as rotas exigem módulo `ouvidoria` e JWT, **exceto** o GET do arquivo, que aceita JWT **ou** ticket. Tenant pelo contexto já existente (`X-Tenant-ID` + AsyncLocalStorage), nunca pelo body.

Erros JSON no formato padrão da API (`code`, `message` em português). Sem stack, sem `storageKey`, sem dados da manifestação além dos UUID que o cliente enviou.

## 1. Busca do dropdown

`GET /ouvidoria/manifestacoes/busca-download?q={texto}`

| Regra | Valor |
|---|---|
| `q` | 2–80 caracteres, trim |
| Máximo | 20 itens |
| Filtro | tenant atual, não excluídas, `protocol` ou `numeroPersonalizado` contém `q` |

`200`

```json
{
  "items": [
    {
      "id": "uuid",
      "protocol": "2026-3-09-0003",
      "numeroPersonalizado": "2026-1-09-0007",
      "status": "pendente"
    }
  ]
}
```

`numeroPersonalizado` vem `null` quando vazio. `400` se `q` inválido. Não aplica a regra 047 (a lista também não aplica); o preflight aplica.

## 2. Preflight

`POST /ouvidoria/manifestacoes/documento/massa`

```json
{ "manifestacaoIds": ["uuid", "uuid"] }
```

Zod: array de UUID, 1 a 50 itens. Duplicata conta uma vez. Acima de 50 itens no JSON (antes de deduplicar) → `422 LOTE_LIMITE_QUANTIDADE`.

`201` quando o lote pode começar:

```json
{
  "sessionId": "uuid",
  "ticket": "base64url",
  "fileName": "manifestacoes-ouvidoria-20261008-1503",
  "expiresAt": "2026-10-08T19:04:00.000Z",
  "total": 3,
  "totalBytesEstimado": 1048576
}
```

`fileName` vem **sem extensão**: o servidor decide `.pdf` ou `.zip` ao fim da montagem e informa no `Content-Disposition` do GET. `expiresAt` é agora + 60 s (para **abrir** o GET, não para terminar).

### Recusas (nenhuma sessão, nenhum byte de ZIP)

| HTTP | `code` | Quando |
|---|---|---|
| 403 | `LOTE_ACESSO_NEGADO` | Algum id do tenant em que `assertForUser` falha. Body: `semAcesso: uuid[]` e, se houver, `naoEncontradas: uuid[]` |
| 404 | `LOTE_NAO_ENCONTRADA` | Algum id não existe neste tenant (outro tenant, apagada, UUID inventado) e **nenhum** falhou por acesso. Body: `naoEncontradas` |
| 422 | `LOTE_LIMITE_QUANTIDADE` | Mais de 50 |
| 422 | `LOTE_LIMITE_VOLUME` | Soma dos anexos de arquivo > 314 572 800 bytes (300 MiB). Body: `totalBytes`, `limiteBytes` |
| 422 | `LOTE_TAMANHO_DESCONHECIDO` | Anexo de arquivo sem `sizeBytes` e sem `ContentLength` no armazenamento |
| 409 | `LOTE_JA_EM_ANDAMENTO` | Esse usuário já tem sessão `preparada` ou `transmitindo` |
| 429 | `LOTE_SERVIDOR_OCUPADO` | Já há 2 transmissões no processo |

Ordem: validar forma → quantidade → carregar no tenant → 404 ou 403 → volume → concorrência. Audit `recusado` em todas essas saídas.

Throttle do POST: no máximo 5 por minuto por usuário (além do 409).

## 3. Arquivo

`GET /ouvidoria/manifestacoes/documento/massa/:sessionId/arquivo`

Autorização (uma das duas):

- `Authorization: Bearer` do mesmo `userId` + tenant da sessão, ou
- `?ticket=` igual ao da sessão, em tempo constante.

Sem os dois, ou sessão de outro dono: `404`. Ticket errado com Bearer de outro usuário: `404` (não distinguir).

| Situação | HTTP |
|---|---|
| Sessão `preparada` dentro do TTL | `200` **depois da montagem completa**: corpo = `.pdf` (`Content-Type: application/pdf`, `Content-Length` conhecido) quando não há anexos fora do PDF, ou `.zip` (`Content-Type: application/zip`, **sem** `Content-Length`) com o PDF único + originais. `Content-Disposition: attachment; filename=...` traz a extensão correta |
| Segundo GET, ou status já `transmitindo` | `409 LOTE_JA_EM_ANDAMENTO` |
| TTL de 60 s esgotado antes do GET | `410 LOTE_EXPIRADO` |
| Sessão inexistente | `404` |

Headers da resposta de sucesso: `Referrer-Policy: no-referrer`, `Cache-Control: no-store`.

Ao aceitar o GET a sessão passa a `transmitindo` e o ticket não serve de novo. O cliente usa **sempre** o download nativo do navegador com `?ticket=`, sem Bearer. O GET só responde com o arquivo depois de montar tudo; durante a montagem o cliente acompanha `…/progresso`. Falha na montagem antes do primeiro byte vira resposta JSON de erro (e `status: falha` no progresso).

Queda do socket ou cancelamento: o servidor aborta a montagem e remove os temporários. Erro fatal depois dos headers: a resposta é interrompida e a sessão fica `falha`.

## 4. Progresso

`GET /ouvidoria/manifestacoes/documento/massa/:sessionId/progresso`

Só Bearer do dono. Ticket não autoriza. Alheio ou inexistente: `404`.

`200`

```json
{
  "status": "preparada",
  "concluidas": 0,
  "total": 3,
  "bytesEnviados": 0
}
```

`status`: `preparada` | `transmitindo` | `concluida` | `cancelada` | `falha` | `expirada`.

O indicador consulta cerca de 1 vez por segundo (até ~10 min) enquanto a sessão estiver `preparada`/`transmitindo`; `concluidas` avança por manifestação montada. `concluida` só quando o envio terminou. Não é canal de conteúdo.

## 5. Cancelar

`POST /ouvidoria/manifestacoes/documento/massa/:sessionId/cancelar`

Bearer do dono. `202` com `{ "status": "cancelada" }`. Dispara o abort; o GET em curso cai. Idempotente se já cancelada (`202` de novo). Alheio: `404`.

## 6. Entrega

Ver [data-model.md](../data-model.md). O nome do arquivo é o `fileName` do preflight + a extensão decidida no fim da montagem.

| Situação | Entrega |
|---|---|
| Nenhum anexo fora do PDF | `manifestacoes-ouvidoria-AAAAMMDD-HHmm.pdf` |
| Ao menos um anexo fora do PDF | `manifestacoes-ouvidoria-AAAAMMDD-HHmm.zip` com `manifestacoes-ouvidoria-AAAAMMDD-HHmm.pdf` + `{slug}/anexos/{nome}` |

O PDF único tem, por manifestação, uma **página de separação** (protocolo/número personalizado; listas de anexos embutidos, fora do PDF e indisponíveis) seguida do dossiê completo, e termina com a **página-resumo do lote** (data/hora e autor do download; manifestações; anexos fora do PDF e indisponíveis, com motivo `armazenamento` | `pdf-invalido` | `tipo-nao-embutivel`; gerado agora × reaproveitado, com o instante do carimbo "Documento gerado em"). Não existem `indice-do-lote.pdf` nem `lote.txt`.

## 7. Cliente (comportamento observável)

| Situação | Comportamento |
|---|---|
| Botão "Baixar em massa" | Na lista de manifestações; abre o modal. A tabela não ganha checkbox |
| Modal | Busca com debounce, chips removíveis, "N de 50", confirmar desabilitado com 0 ou mais de 50. Texto: PDF único; anexos que não cabem em PDF acompanham em ZIP |
| Erro de preflight | Mensagem no modal, seleção preservada. `semAcesso` / `naoEncontradas` citados pelo protocolo que o chip já mostra. Volume: "cerca de 300 MB" |
| Confirmar | Dispara **sempre** o download nativo do navegador (`<a download>` com `?ticket=`), sem seletor de local, sem `fetch` do corpo. Inicia polling do progresso |
| Indicador | "N de total manifestações" + aviso de montagem no servidor + **Cancelar** (`POST …/cancelar`). Sem link "Baixar arquivo ZIP" |
| Navegar / fechar o modal | Não cancela. Indicador global (provider em `App.tsx`) continua |
| Falha na geração | Mensagem em português de falha na geração (poll `falha`/`expirada` ou ~10 min sem estado terminal), distinta de acesso negado e de armazenamento indisponível |
| Armazenamento indisponível no lote inteiro | Mensagem em português de armazenamento indisponível. Anexo isolado ilegível não usa essa frase: o PDF conclui e a página-resumo explica |
| Fechar a aba | O navegador aborta o download; o servidor encerra a sessão e remove os temporários |

Nada deste fluxo usa `Blob` do arquivo inteiro no cliente.