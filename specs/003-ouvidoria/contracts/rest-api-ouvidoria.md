# Contract: REST API — Ouvidoria

**Feature**: 003-ouvidoria  
**Version**: 1.0.0  
**Base URL**: `/` (Fastify)  
**Module guard**: `@RequireModulo('ouvidoria')` em rotas autenticadas (exceto consulta pública)

## Headers

| Header | Rotas autenticadas | Consulta pública |
|--------|-------------------|------------------|
| `Authorization: Bearer <jwt>` | Obrigatório | Não |
| `X-Tenant-ID` | Obrigatório | Obrigatório |

---

## Referência — Municípios

### GET `/address/municipios` (Public ou autenticado)

**Query**: `q` (opcional, min 2 chars), `uf` (opcional)

**Response 200**:

```json
{
  "items": [
    { "codigoIbge": "3550308", "nome": "São Paulo", "uf": "SP" }
  ]
}
```

---

## Manifestações — CRUD e fluxo

### POST `/ouvidoria/manifestacoes` (autenticado)

Cria rascunho (etapa 1).

**Body** (Zod `CreateManifestacaoDraftBody`):

```json
{
  "tipo": "reclamacao",
  "esfera": "municipal",
  "assunto": "Iluminação pública",
  "relato": "Texto do relato...",
  "origem": "interna",
  "canal": "presencial",
  "prazoResposta": "2026-06-20T00:00:00.000Z",
  "sigilo": false,
  "address": {
    "municipioIbge": "3550308",
    "descricaoLocal": "Praça central, quadra 12"
  },
  "manifestante": {
    "nome": "João Silva",
    "email": "joao@email.com"
  }
}
```

**Response 201**:

```json
{
  "id": "uuid",
  "status": "rascunho"
}
```

---

### PATCH `/ouvidoria/manifestacoes/:id` (autenticado)

Atualiza rascunho ou campos permitidos (FR-020). **403** se encaminhada e campos substantivos.

---

### POST `/ouvidoria/manifestacoes/:id/anexos/presign` (autenticado)

Solicita URL de upload.

**Body**:

```json
{
  "fileName": "evidencia.pdf",
  "mimeType": "application/pdf",
  "sizeBytes": 1048576
}
```

**Response 200**:

```json
{
  "anexoId": "uuid",
  "uploadUrl": "https://...",
  "expiresIn": 900
}
```

**Errors**: 400 `FILE_TYPE_NOT_ALLOWED` | `FILE_TOO_LARGE` (> 30 MB)

---

### POST `/ouvidoria/manifestacoes/:id/anexos/:anexoId/confirm` (autenticado)

Confirma upload concluído no storage.

**Response 200**: `{ "ok": true }`

---

### GET `/ouvidoria/manifestacoes/:id/revisao` (autenticado)

Retorna DTO completo para etapa de revisão (copy UI spec).

**Response 200**: manifestação + anexos + address + manifestante (respeitando sigilo).

---

### POST `/ouvidoria/manifestacoes/:id/confirmar` (autenticado)

Confirma registro; gera protocolo e chave.

**Response 200**:

```json
{
  "protocolo": "OUV-2026-0138",
  "chaveConsulta": "K7X9M2P4",
  "status": "em_analise"
}
```

> `chaveConsulta` retornada **uma única vez**; cliente MUST exibir para servidor repassar ao manifestante.

---

### GET `/ouvidoria/manifestacoes` (autenticado)

Lista paginada.

**Query**: `tipo`, `status`, `origem`, `protocolo`, `prazoVencendo`, `page`, `limit`

**Response 200**:

```json
{
  "items": [
    {
      "id": "uuid",
      "protocolo": "OUV-2026-0138",
      "tipo": "reclamacao",
      "tipoLabel": "Reclamação",
      "status": "em_analise",
      "statusLabel": "Em análise",
      "prazoResposta": "2026-06-20",
      "origem": "publica",
      "origemLabel": "Pública",
      "badges": ["vencendo"]
    }
  ],
  "total": 42,
  "page": 1,
  "limit": 20
}
```

---

### GET `/ouvidoria/manifestacoes/:id` (autenticado)

Detalhe + timeline + anexos (URLs presigned download). Manifestante omitido se sigilo sem permissão.

**Response 200**:

```json
{
  "id": "uuid",
  "protocolo": "OUV-2026-0138",
  "tipo": "denuncia",
  "esfera": "federal",
  "assunto": "...",
  "relato": "...",
  "status": "tramitando",
  "sigilo": true,
  "manifestante": null,
  "address": { "municipio": { "nome": "São Paulo", "uf": "SP" }, "descricaoLocal": "..." },
  "anexos": [{ "id": "uuid", "fileName": "evidencia.pdf", "downloadUrl": "https://..." }],
  "eventos": [
    {
      "tipo": "registro",
      "titulo": "Registro",
      "descricao": "Manifestação registrada via portal interno.",
      "createdAt": "2026-06-02T09:15:00.000Z",
      "autorNome": "Maria Servidor"
    }
  ],
  "acoesPermitidas": ["encaminhar", "responder", "encerrar"]
}
```

---

## Ações operacionais

### POST `/ouvidoria/manifestacoes/:id/encaminhar`

**Body**:

```json
{
  "destinoSetorId": "uuid",
  "observacao": "Encaminhada ao setor responsável."
}
```

**Response 200**: `{ "status": "tramitando" }` + evento criado.

---

### POST `/ouvidoria/manifestacoes/:id/responder`

**Body**:

```json
{
  "texto": "Resposta oficial ao manifestante..."
}
```

**Response 200**: `{ "status": "respondida" }`

---

### POST `/ouvidoria/manifestacoes/:id/encerrar`

**Body**:

```json
{
  "motivo": "Demanda concluída."
}
```

**Response 200**: `{ "status": "encerrada" }`

---

## Consulta pública (sem UI nesta feature)

### GET `/ouvidoria/consulta` (@Public, Throttle 10/min)

**Query**: `protocolo`, `chave`

**Headers**: `X-Tenant-ID` obrigatório

**Response 200**:

```json
{
  "protocolo": "OUV-2026-0138",
  "status": "tramitando",
  "statusLabel": "Tramitando",
  "marcos": [
    { "data": "2026-06-02", "titulo": "Registro" },
    { "data": "2026-06-02", "titulo": "Triagem" }
  ]
}
```

**Response 404** (genérico): `{ "message": "Manifestação não encontrada." }` — mesmo texto para protocolo inexistente ou chave errada.

---

## Error codes (domínio)

| Code | HTTP | When |
|------|------|------|
| `MODULO_SETOR_DENIED` | 403 | Sem permissão ouvidoria |
| `MANIFESTACAO_NOT_EDITABLE` | 403 | Edição após encaminhamento |
| `FILE_TYPE_NOT_ALLOWED` | 400 | MIME/extensão inválida |
| `FILE_TOO_LARGE` | 400 | > 30 MB |
| `INVALID_STATUS_TRANSITION` | 409 | Ação em status inválido |

---

## MIME whitelist (FR-007)

| Categoria | MIME / extensões |
|-----------|------------------|
| Documentos | `application/pdf`, `application/msword`, `application/vnd.openxmlformats-officedocument.wordprocessingml.document`, `text/plain` |
| Imagens | `image/jpeg`, `image/png`, `image/bmp` |
| Planilhas | `application/vnd.ms-excel`, `application/vnd.openxmlformats-officedocument.spreadsheetml.sheet` |
| Multimídia | `audio/mpeg`, `video/mp4` |
