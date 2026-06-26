# Contract: REST API — Jurídico (Base)

**Feature**: 012-desmock-juridico  
**Version**: 1.0.0  
**Base URL**: `/` (Fastify)  
**Module guard**: `@RequireModulo('juridico')` em rotas autenticadas

## Headers

| Header | Rotas autenticadas |
|--------|-------------------|
| `Authorization: Bearer <jwt>` | Obrigatório |
| `X-Tenant-ID` | Obrigatório |

---

## Processos — wizard e CRUD

### POST `/juridico/processos` (autenticado)

Cria rascunho (etapa dados).

**Body** (`CreateProcessDraftBody`):

```json
{
  "tipo": "judicial",
  "assunto": "Aditivo contratual — Fornecedor X",
  "numeroJudicial": "0001234-56.2026.8.26.0100",
  "observacoes": "Prazo improrrogável.",
  "prazo": "2026-07-15T00:00:00.000Z",
  "valorCausa": 250000.00,
  "responsavelInterno": "Dra. Silva",
  "orgao": {
    "esfera": "estadual",
    "tribunal": "TJSP",
    "comarca": "São Paulo",
    "vara": "1ª Vara Fazenda Pública"
  },
  "partes": [
    {
      "polo": "ativo",
      "tipoPessoa": "juridica",
      "nome": "Instituição",
      "documento": "12345678000199"
    },
    {
      "polo": "passivo",
      "tipoPessoa": "juridica",
      "nome": "Fornecedor X"
    }
  ]
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

### PATCH `/juridico/processos/:id` (autenticado)

Atualiza rascunho ou campos permitidos pós-confirmação. **403** se tentativa de alterar campos bloqueados após conclusão.

---

### POST `/juridico/processos/:id/confirm` (autenticado)

Confirma processo; gera `numeroInterno` (`JUR-2026-0047`); cria evento `registration`.

**Response 200**:

```json
{
  "id": "uuid",
  "numeroInterno": "JUR-2026-0047",
  "status": "aberto",
  "confirmadoEm": "2026-06-23T14:00:00.000Z"
}
```

---

### POST `/juridico/processos/:id/anexos/presign`

**Body**:

```json
{
  "fileName": "peticao.pdf",
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

---

### POST `/juridico/processos/:id/anexos/:anexoId/confirm`

Confirma upload após PUT direto ao storage.

---

### GET `/juridico/processos`

**Query**: `tipo`, `status`, `q` (busca número/assunto), `prazoAte`, `page`, `pageSize`

**Response 200**:

```json
{
  "items": [
    {
      "id": "uuid",
      "numeroInterno": "JUR-2026-0047",
      "tipo": "judicial",
      "partesResumo": "Instituição x Fornecedor X",
      "status": "critico",
      "prazo": "2026-06-01T00:00:00.000Z",
      "responsavel": "Dra. Silva"
    }
  ],
  "total": 47,
  "page": 1,
  "pageSize": 20
}
```

---

### GET `/juridico/processos/:id`

Detalhe completo: dados, partes, órgão, anexos, timeline, badge opcional `probabilidadePerda` (última fiscalização).

---

## Dashboard

### GET `/juridico/dashboard`

**Response 200**:

```json
{
  "processosAbertos": 47,
  "prazosCriticos": 6,
  "pareceresMes": 23,
  "conformidadeLegal": 82,
  "distribuicaoStatus": [
    { "status": "aberto", "count": 30 },
    { "status": "critico", "count": 6 }
  ]
}
```

`conformidadeLegal`: percentual conformes / total na última execução Jatobá (0 se sem run).

---

## Erros canônicos

| Code | HTTP | Quando |
|------|------|--------|
| `MODULO_SETOR_DENIED` | 403 | Sem permissão módulo |
| `PROCESS_NOT_FOUND` | 404 | ID inexistente ou outro tenant |
| `ATTACHMENT_INVALID` | 400 | MIME/tamanho |
| `PROCESS_ALREADY_CONFIRMED` | 409 | Confirm duplicado |

---

## Mapper PT-BR

Campos API em camelCase PT (`tipo`, `numeroInterno`) ou EN interno com mapper — **decisão implementação**: EN no Prisma/Zod (`type`, `internalNumber`); resposta REST PT-BR alinhada ao client ouvidoria (`tipo`, `status` traduzidos).
