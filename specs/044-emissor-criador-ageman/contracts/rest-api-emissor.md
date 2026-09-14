# Contrato REST — Emissor na criação interna AGEMAN

**Base**: rotas já existentes em `OuvidoriaController`. Nenhuma rota nova.

Autenticação: JWT + `X-Tenant-ID` + `@RequireModulo('ouvidoria')` — inalterado.

## POST `/ouvidoria/manifestacoes`

Body: `createManifestacaoDraftBodySchema` — `emissorUserId` permanece `uuid` opcional.

| Ator | `emissorUserId` no body | Persistido | Resposta |
| --- | --- | --- | --- |
| Operador institucional | ausente, ou qualquer UUID | Sempre `actor.userId` (User do tenant) | `201` `{ id, status: draft }` — **sem 400** por divergência |
| Admin instituição / SaaS | ausente | `null` | `201` |
| Admin instituição / SaaS | UUID de operador do tenant | esse UUID | `201` |
| Admin instituição / SaaS | UUID que não é User do tenant | — | `400` `EMISSOR_INVALID` (já existe) |

`dadosAdicionais` no registro, para ator sem linha em `User`: inclui `actorId` + `actorRole`. Não faz parte do JSON de resposta deste POST (resposta continua `{ id, status }`).

## PATCH `/ouvidoria/manifestacoes/:id`

Body: `updateManifestacaoDraftBodySchema` — `emissorUserId` continua opcional.

O handler **passa a enviar** `req.user` ao use-case (mudança de assinatura interna; contrato HTTP do body não muda).

| Estado | Efeito em `emissorUserId` |
| --- | --- |
| `status === draft` | Mesma tabela do POST (recálculo). |
| `status !== draft` | Campo **ignorado**. Outros campos seguem `isManifestacaoEditable`. Sem 400 só por enviar emissor. |

## POST `/ouvidoria/manifestacoes/:id/confirmar`

Inalterado. Não lê nem escreve emissor.

## GET `/ouvidoria/manifestacoes/:id`

Inalterado: `emissorUserId`, `emissorLabel`, `emissorVisivel: true`. Label `null` → UI “—”.

## GET `/ouvidoria/usuarios-emissores`

Inalterado (lista de `User` ativos do tenant). O **client** deixa de chamá-lo no fluxo do operador institucional.

## Fora de contrato

- Portal público (`POST` público de manifestações).
- Shape de erro: `AllExceptionsFilter` existente.
