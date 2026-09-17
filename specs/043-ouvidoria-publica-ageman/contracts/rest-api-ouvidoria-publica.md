# REST API Contract — Ouvidoria Pública AGEMAN (043)

**Base path**: `/ouvidoria`
**Auth**: nenhuma (`@Public()`) — apenas `X-Tenant-ID` resolve o tenant (AsyncLocalStorage)
**Validação**: Zod v4 em `ouvidoria.schemas.ts` + `ZodValidationPipe` global
**Envelope de erro**: `AllExceptionsFilter` (400/404/409/429 conforme `OUVIDORIA_ERROR`)
**Rate limit**: `@Throttle` por rota (abaixo) + `CheckPublicRateLimitRepository` (5 envios/IP/60s, camada adicional dentro do use-case de criação)

---

## `GET /ouvidoria/consulta`

**Inalterado no shape** — só o conteúdo de `statusLabel` muda (R3).

Throttle: 10/min.

Query:

```text
protocol: string (obrigatório)
chave: string (obrigatório)
```

**200**

```json
{
  "protocol": "2026-1-09-0007",
  "status": "in_review",
  "statusLabel": "Em análise",
  "assunto": "string",
  "resposta": "string | undefined",
  "registradaEm": "2026-09-01T12:00:00.000Z",
  "marcos": [{ "data": "2026-09-01", "titulo": "Registro" }]
}
```

`statusLabel` agora vem de `PUBLIC_MANIFESTACAO_STATUS_LABEL` (Recebida/Em análise/Respondida/Encerrada) — nunca do mapa interno.

**404**: protocolo inexistente **ou** chave incorreta — resposta idêntica nos dois casos (`OUVIDORIA_PUBLIC_NOT_FOUND`), sem indicar qual dos dois falhou (FR-016).

---

## `POST /ouvidoria/publico/manifestacoes`

Throttle: 5/min. Body validado por `criarManifestacaoPublicaBodySchema` (expandido).

```json
{
  "isAnonymous": true,
  "requesterFullName": "string?",
  "requesterDocument": "string?",
  "tipo": "complaint | request | whistleblower | praise | suggestion",
  "programa": "agua | transporte | iluminacao | lixo | zona_azul | institucional",
  "motivo": "string (livre para institucional; catálogo fixo nos demais)",
  "subject": "string",
  "description": "string",
  "email": "string (obrigatório, mesmo anônimo)",
  "mobilePhone": "string?",
  "homePhone": "string?",
  "businessPhone": "string?",
  "address": {
    "municipioIbge": "string? (7 dígitos)",
    "postalCode": "string?",
    "street": "string?",
    "number": "string?",
    "complement": "string?",
    "landmark": "string?",
    "neighborhood": "string?",
    "zone": "string?"
  },
  "matricula": "string? (obrigatório se programa=agua, 5-12 dígitos)",
  "protocoloConcessionaria": "string? (obrigatório se programa=iluminacao)",
  "identificacaoPoste": "string? (obrigatório se programa=iluminacao)",
  "challengeToken": "string (reCAPTCHA v3)",
  "anexoTempIds": ["string"]
}
```

**201** (implícito — Nest default 201 em `@Post`)

```json
{
  "protocol": "2026-1-09-0007",
  "numeroPersonalizado": "2026-1-09-0007",
  "chaveConsulta": "aB3xY9kLmZ"
}
```

`chaveConsulta` é devolvida **só nesta resposta** — nunca mais recuperável depois (`queryKeyHash` é bcrypt one-way).

**400**: `CHALLENGE_INVALID` (recaptcha falhou/indisponível — falha fechada), `MATRICULA_INVALID`, `PROGRAMA_FIELDS`, `VALIDATION_FAILED` (Zod).
**429**: `PUBLIC_RATE_LIMIT` (`retryAfterSeconds` no body).

---

## `POST /ouvidoria/publico/anexos`

Throttle: 10/min. Body: `uploadPublicoBodySchema` (inalterado).

```json
{ "fileName": "foto.jpg", "mimeType": "image/jpeg", "sizeBytes": 204800 }
```

**201**

```json
{ "tempId": "uuid", "uploadUrl": "https://...", "expiresIn": 900 }
```

`uploadUrl` é **novo** — antes a rota só devolvia `tempId`/`expiresAt` sem transporte real. Cliente faz `PUT` direto em `uploadUrl` com o binário do arquivo (`Content-Type: mimeType`) — sem passar pela API.

Limites (alinhados ao padrão interno já vigente, não ao mais permissivo da v1): `MAX_ANEXO_BYTES` = 30MB; `ALLOWED_MIME_TYPES` de `ouvidoria-anexo.constants.ts` (pdf, doc/docx, txt, jpeg/png/bmp, xls/xlsx, mp3, mp4).

**400**: `ANEXO_INVALID` (tipo ou tamanho fora do permitido).

`tempId` é referenciado em `anexoTempIds[]` no `POST /ouvidoria/publico/manifestacoes` — se a manifestação nunca for confirmada, o registro expira em 1h (`expiresAt`) e o arquivo correspondente no storage fica órfão (aceito — mesmo comportamento do fluxo autenticado; sem job de limpeza nesta entrega).

---

## `GET /ouvidoria/publico/catalogos`

**Inalterado** — continua devolvendo só formas de atendimento (`listFormasAtendimento.execute()`). Não estender este shape.

---

## `GET /ouvidoria/publico/programas` (NOVO)

Sem throttle dedicado (payload estático, cacheável pelo client). `@Public()`.

**200**

```json
{
  "items": [
    {
      "code": "agua",
      "label": "Água / Saneamento",
      "motivos": ["ABASTECIMENTO PRECARIO (INTERMITENCIA NO FORNECIMENTO)", "..."]
    },
    {
      "code": "transporte",
      "label": "Transporte Coletivo",
      "motivos": ["..."]
    },
    {
      "code": "iluminacao",
      "label": "Iluminação Pública",
      "motivos": ["..."]
    },
    {
      "code": "lixo",
      "label": "Coleta de Lixo",
      "motivos": ["..."]
    },
    {
      "code": "zona_azul",
      "label": "Estacionamento Rotativo",
      "motivos": ["..."]
    },
    {
      "code": "institucional",
      "label": "Assuntos institucionais",
      "motivos": []
    }
  ]
}
```

`code` usa o slug semântico (`PROGRAMA_ALIAS` de `lib/ageman-catalog.ts`), não o código numérico interno (`'1'`-`'6'`) — o client envia o mesmo `code` de volta em `programa` no `POST /ouvidoria/publico/manifestacoes`. `institucional` sempre com `motivos: []` (motivo é texto livre).

---

## Códigos

| Status | Quando |
| --- | --- |
| 200/201 | OK |
| 400 | Zod validation, `CHALLENGE_INVALID`, `MATRICULA_INVALID`, `PROGRAMA_FIELDS`, `ANEXO_INVALID` |
| 404 | `PUBLIC_NOT_FOUND` (consulta) — protocolo **ou** chave incorretos, resposta idêntica |
| 429 | `PUBLIC_RATE_LIMIT` (throttle da rota **ou** rate limit por IP do use-case) |

Nenhuma rota exige `Authorization`. Todas resolvem `tenantId` só pelo header `X-Tenant-ID` (`TenantGuard` permite rotas `@Public()` sem header, mas os repositories usam `getRequestContext().tenantId!` — o client **deve** sempre enviar o header, mesmo sem token).
