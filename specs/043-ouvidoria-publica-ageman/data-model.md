# Data Model — 043 Ouvidoria Pública AGEMAN

**Spec**: [spec.md](./spec.md) · **Research**: [research.md](./research.md)

Convenções: `tenantId` via AsyncLocalStorage (rotas `@Public()` resolvem pelo header `X-Tenant-ID`, sem JWT). FK para `User` fica `null` no fluxo público — não há ator autenticado (ver `admin-tenant-user-fk.mdc`, extensão: aqui nem `AdminTenant` existe, é anônimo/identificado por texto livre).

## 1. Existentes (leitura + escrita ampliada)

### `Manifestacao` — `prisma/schema/manifestacao.prisma`

Nenhum campo novo — todos os campos abaixo **já existem** no schema, mas hoje não são preenchidos pelo fluxo público. Esta feature passa a escrevê-los:

| Campo | Tipo | Hoje (fluxo público) | Depois |
| --- | --- | --- | --- |
| `type` | `ManifestacaoTipo` | fixo `complaint` | mapeado do `tipo` enviado pelo cidadão |
| `replyEmail` | `String?` | nunca setado | e-mail de contato (obrigatório no schema de entrada) |
| `requesterMobilePhone` / `requesterHomePhone` / `requesterBusinessPhone` | `String?` | nunca setados | telefones opcionais informados pelo cidadão |
| `addressId` | `String?` | nunca setado | FK para `Address` criado via `CreateAddressRepository` quando `input.address` vier preenchido |
| `createdByUserId` | `String?` | **bug**: usuário arbitrário do tenant (`user.findFirst`) | `undefined` — sem ator autenticado no fluxo público |
| `registrationNumber` | `String?` | matrícula (programa água) | inalterado |
| `programa` / `motivo` | `String` | 2 valores (água/iluminação) | 6 valores (+ transporte/lixo/zona_azul/institucional); `motivo` livre para `institucional` |
| `dadosAdicionais` (Json) | — | `{ protocoloConcessionaria, identificacaoPoste }` | inalterado |
| `origem` | `String` | `'publica'` | inalterado |
| `status` | `ManifestacaoStatus` | `in_review` na criação | inalterado |

`ManifestacaoTipo` (enum, inalterado — reaproveitado, sem mapeamento paralelo):

```text
complaint | request | whistleblower | praise | suggestion | simplify
```

Mapeamento do rótulo exibido ao cidadão (client) → valor persistido: Reclamação→`complaint`, Solicitação→`request`, Denúncia→`whistleblower`, Elogio→`praise`, Sugestão→`suggestion`.

### `Address` / `Municipio` — `address.prisma` / `municipio.prisma`

Reaproveitados sem alteração via `CreateAddressRepository.execute({ municipioIbge, postalCode, street, number, complement, landmark, neighborhood, zone })`. Já usado pelo fluxo autenticado (`create-manifestacao-draft.use-case.ts`) — mesmo contrato.

### `ManifestacaoAnexo` — `manifestacao.prisma:142-161`

Sem alteração de schema. Passa a ser **criado de fato** pelo fluxo público (hoje nunca é criado — `BindAnexosPublicosRepository` é stub):

| Campo | Origem no fluxo público |
| --- | --- |
| `kind` | `file` (anexos públicos só suportam arquivo nesta entrega — links externos ficam para uma iteração futura, fora do escopo da spec) |
| `storageKey` | copiado do registro temporário (`ManifestacaoAnexoPublicoTemp.storageKey`) |
| `uploadConfirmed` | `true` no bind (o `PUT` presignado já aconteceu antes da confirmação — mesmo padrão do fluxo autenticado, que confia no client após o presign) |
| `uploadedByUserId` | `null` — sem ator autenticado |

## 2. Nova (migration additive)

### `ManifestacaoAnexoPublicoTemp`

Substitui o `Map` em memória de `store-public-temp-anexo.repository.ts` (hoje sem `tenantId`, perdido a cada restart do processo).

```prisma
model ManifestacaoAnexoPublicoTemp {
  id          String   @id @default(uuid())
  tenantId    String
  storageKey  String
  fileName    String
  mimeType    String
  sizeBytes   Int
  expiresAt   DateTime
  consumedAt  DateTime?
  createdAt   DateTime @default(now())

  tenant Tenant @relation(fields: [tenantId], references: [id])

  @@index([tenantId, expiresAt])
}
```

- `expiresAt`: `createdAt + 1h` (mesmo TTL do stub atual).
- `consumedAt`: setado por `BindAnexosPublicosRepository` ao criar o `ManifestacaoAnexo` real — evita reuso do mesmo `tempId` em duas manifestações.
- Sem FK para `Manifestacao` (o registro é *pré*-manifestação — o cidadão pode anexar antes de confirmar o envio).

## 3. Modelos de query (não persistidos)

### `PUBLIC_MANIFESTACAO_STATUS_LABEL`

Novo mapa em `ouvidoria.mapper.ts`, usado **somente** por `ConsultaPublicaUseCase` (rota pública). Não substitui `MANIFESTACAO_STATUS_LABEL` (interno, continua em uso nas telas da equipe de ouvidoria).

| `ManifestacaoStatus` (interno) | Label público |
| --- | --- |
| `draft` | Recebida |
| `in_review` | Em análise |
| `forwarding` | Em análise |
| `answered` | Respondida |
| `closed` | Encerrada |
| `closed_unresolved` | Encerrada |

### `ConsultaPublicaResponse` (já implementado, sem mudança de shape — só de conteúdo do `statusLabel`)

```text
protocol: string
status: ManifestacaoStatus       # valor interno — mantido no payload por compat, mas UI usa statusLabel
statusLabel: string              # agora vem de PUBLIC_MANIFESTACAO_STATUS_LABEL
assunto: string
resposta?: string
registradaEm: string (ISO)
marcos: Array<{ data: string (YYYY-MM-DD), titulo: string }>
```

`marcos[]` já é seguro hoje (nunca inclui `descricao` livre, só `titulo` genérico como "Registro"/"Encaminhamento"/"Resposta"/"Encerramento") — sem mudança necessária.

### `CriarManifestacaoPublicaInput` (schema de entrada, expandido)

```text
isAnonymous?: boolean (default true)
requesterFullName?: string        # obrigatório se !isAnonymous
requesterDocument?: string
tipo: 'complaint' | 'request' | 'whistleblower' | 'praise' | 'suggestion'   # NOVO
programa: 'agua' | 'transporte' | 'iluminacao' | 'lixo' | 'zona_azul' | 'institucional'  # 6 valores
motivo: string                    # livre para 'institucional'; catálogo fixo nos demais
subject: string
description: string
email: string                     # NOVO — obrigatório, mesmo anônimo
mobilePhone?: string              # NOVO
homePhone?: string                # NOVO
businessPhone?: string            # NOVO
address?: { municipioIbge?, postalCode?, street?, number?, complement?, landmark?, neighborhood?, zone? }
matricula?: string                # obrigatório se programa === 'agua'
protocoloConcessionaria?: string  # obrigatório se programa === 'iluminacao'
identificacaoPoste?: string       # obrigatório se programa === 'iluminacao'
challengeToken: string            # reCAPTCHA v3
anexoTempIds?: string[]
```

### `UploadAnexoPublicoResponse` (presign real)

```text
tempId: string
uploadUrl: string       # NOVO — PUT presignado (S3/Wasabi ou fallback local)
expiresIn: number       # segundos
```

## 4. Validação (borda Zod)

Ver [contracts/rest-api-ouvidoria-publica.md](./contracts/rest-api-ouvidoria-publica.md). Resumo das regras novas/alteradas:

- `programa`: 6 valores (era 2).
- `tipo`: reaproveita `manifestacaoTipo` já declarado no arquivo — sem novo enum.
- `email`: `z.email()`, obrigatório mesmo com `isAnonymous: true`.
- `mobilePhone`/`homePhone`/`businessPhone`: opcionais, sem `superRefine` adicional (a v1 exigia "ao menos um contato", mas `email` já é obrigatório nesta versão — cobre o requisito sem regra condicional extra).
- `superRefine` existente mantido: `matricula` obrigatória para `agua`; `protocoloConcessionaria` + `identificacaoPoste` obrigatórios para `iluminacao`; nome obrigatório se `!isAnonymous`. `institucional` **não** ganha regra condicional nova (motivo livre, sem campo extra obrigatório).
- `address`: schema já existente (`addressInputSchema`), sem alteração de shape.

## 5. Transições de estado

Nenhuma nova. O fluxo público cria a manifestação já em `in_review` (inalterado) — as transições de status (`forwarding`, `answered`, `closed`, `closed_unresolved`) continuam exclusivas do fluxo interno/autenticado da equipe de ouvidoria. A consulta pública é 100% leitura.
