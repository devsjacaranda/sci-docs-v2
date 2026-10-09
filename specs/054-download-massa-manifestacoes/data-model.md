# Data Model — 054 Download em Massa

Não há model Prisma novo nem migration. O lote é uma sessão em memória; o PDF reaproveitável é um objeto no armazenamento; o rastro é linha no `AuditLog` que já existe.

## Sessão de download (memória do processo)

Criada só depois que o preflight passa. TTL 60 s para **iniciar** a transmissão; depois disso o GET responde 410 e a sessão some. Durante a transmissão não expira por relógio — expira ao concluir, cancelar, falhar ou a conexão cair.

| Campo | Tipo | Regra |
|---|---|---|
| `sessionId` | UUID | Opaco, não sequencial |
| `ticket` | string (43+ chars) | 32 bytes aleatórios, base64url. Comparação em tempo constante |
| `tenantId` | string | Do contexto da request, nunca do body |
| `userId` | string | `req.user.userId` (pode ser `AdminTenant.id`) |
| `role` | role JWT | Para auditoria e `resolveUserTableId` |
| `manifestacaoIds` | UUID[] | Únicos, 1–50, já autorizados |
| `fileName` | string | `manifestacoes-ouvidoria-{YYYYMMDD-HHmm}` (sem extensão; o servidor acrescenta `.pdf` ou `.zip` na entrega) |
| `status` | enum | ver transições |
| `concluidas` | int | Manifestações cujo dossiê e originais já foram montados |
| `total` | int | Tamanho de `manifestacaoIds` |
| `bytesEnviados` | int | Bytes escritos na resposta |
| `cacheHits` | int | PDFs servidos do cache |
| `indisponiveis` | lista | `{ manifestacaoId, fileName, motivo }` para a página-resumo final |
| `startedAt` / `expiresAt` | Date | `expiresAt = startedAt + 60 s` até o GET começar |
| `abort` | AbortSignal | Disparado por cancelar, socket `close` ou erro fatal |

### Transições

```text
(preflight recusado) → nenhuma sessão
preparada → transmitindo     GET aceito, ticket consumido
preparada → expirada         60 s sem GET
transmitindo → concluida     envio do PDF (ou ZIP) terminado
transmitindo → cancelada     usuário, fechamento da aba ou queda da conexão
transmitindo → falha         erro fatal de geração (render, ZIP, armazenamento geral)
```

Segundo GET na mesma sessão: 409. Sessão de outro usuário ou outro tenant: 404 (não 403), sem dizer se o id existe.

## Objeto de cache do dossiê

| Campo | Regra |
|---|---|
| Chave | `buildStorageKey(tenantId, 'ouvidoria', 'pdf-cache', manifestacaoId, revision + '.pdf')` |
| `revision` | SHA-256 hex de 16 chars (prefixo) sobre o fingerprint de [research.md](./research.md) §6 |
| Metadata `generatedAt` | ISO-8601 do instante em que o PDF foi renderizado |
| Sidecar | `{revision}.report.json` = `{ issues: [{ fileName, storageKey, reason }] }` com as pendências de embutimento. PDF sem sidecar = miss |
| Validade | Servir sse `now - generatedAt < 24 h` |
| Conteúdo | PDF já com timbrado e anexos embutidos. Carimbo "Documento gerado em" é esse instante |

Fingerprint inclui anexos com `deletedAt` preenchido e a data de alteração dos arquivos de timbrado, então exclusão (053) ou troca do carimbo mudam a chave. Objeto com `generatedAt` acima de 24 h é apagado nesse acesso. Ao gravar uma revisão nova, as outras chaves do mesmo prefixo da manifestação são apagadas. O lifecycle de 48 h no bucket só cobre exclusão que falhou.

`PDF_RENDER_REVISION` entra no fingerprint. Subir o inteiro no mesmo cambio que alterar `render-manifestacao-pdf`, `render-manifestacao-pdf-ageman`, `mergeAnexosIntoManifestacaoPdf` ou os assets de timbrado.

## Linha de auditoria (`AuditLog`, schema atual)

| Campo | Valor |
|---|---|
| `tenantId` | tenant da request |
| `userId` | `resolveUserTableId(userId, role)` — `null` para `admin_tenant` e `admin_saas` |
| `action` | `ouvidoria.manifestacao.bulk_download` |
| `entity` | `Manifestacao` |
| `entityId` | `null` |
| `payload` | ver abaixo |

Payload (JSON), sempre via `withActorPayload`:

| Campo | Quando |
|---|---|
| `actorId`, `actorRole` | Só se não houver linha em `User` |
| `resultado` | `recusado` \| `concluido` \| `cancelado` \| `falho` |
| `motivo` | Código estável (`LOTE_ACESSO_NEGADO`, `LOTE_LIMITE_VOLUME`, …) quando recusado ou falho |
| `manifestacaoIds` | Os UUID pedidos (os que o usuário enviou) |
| `totalBytes` | Bytes escritos; 0 se recusado antes do stream |
| `cacheHits` | Inteiro; 0 se recusado |
| `concluidas` | Quantas manifestações entraram no ZIP |

Proibido no payload: bytes de PDF, nome de anexo, dados do solicitante, ticket, `storageKey`.

## Layout da entrega (contrato de dados)

**PDF único** (`manifestacoes-ouvidoria-AAAAMMDD-HHmm.pdf`), sempre:

| Parte | Conteúdo |
|---|---|
| Página de separação (1 por manifestação, na ordem do array deduplicado) | Página inteira: protocolo/número personalizado; listas de anexos **embutidos**, **fora do PDF** e **indisponíveis** |
| Dossiê da manifestação | PDF individual completo (dados, tramitação, timbrado, anexos JPG/PNG/PDF embutidos) |
| Página-resumo final (última) | Data/hora e autor do download; manifestações; anexos fora do PDF e indisponíveis (nome + motivo); gerado agora × reaproveitado (com o "gerado em" original) |

**ZIP** (`.zip`), só quando há ao menos um anexo fora do PDF:

| Entrada | Conteúdo |
|---|---|
| `manifestacoes-ouvidoria-AAAAMMDD-HHmm.pdf` | O PDF único acima |
| `{slug}/anexos/{nome}` | Original de cada anexo fora do PDF: tipo não embutível (Word, Excel, TXT, MP3, MP4…) e PDF/imagem inválido (`pdf-invalido`) |

Slug e nome de anexo: regras de [research.md](./research.md) §9. Anexo cujo `getObject` falha não gera arquivo; vira linha de indisponível (`armazenamento`). Link externo não gera arquivo; o dossiê já o cita. Não existem `lote.txt` nem `indice-do-lote.pdf`.
## Consulta de apoio (sem entidade nova)

Preflight e revisão leem, com `tenantId` e `deletedAt: null` no `where` (client Prisma base do módulo, igual à 053):

- `Manifestacao` (id, protocol, numeroPersonalizado, updatedAt, status, campos que o renderer já usa)
- `ManifestacaoConcessionaria.updatedAt`
- `ManifestacaoAnexo` ativos e tombstones (fingerprint + bytes)
- `max(ManifestacaoEvento.createdAt)`

Busca do dropdown não traz anexo nem descrição.

## Fora deste modelo

- Sem fila, sem tabela de lote, sem retomar download pela metade.
- Sem cache dos originais (a fonte é o anexo no Wasabi).
- O limite de 200 MB do PDF individual não é coluna nem flag: continua só no use case `GenerateManifestacaoPdfUseCase`.
