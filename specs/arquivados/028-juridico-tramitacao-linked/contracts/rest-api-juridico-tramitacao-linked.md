# Contract: REST API — Jurídico Tramitação Linked

**Feature**: 028-juridico-tramitacao-linked  
**Version**: 1.0.0  
**Base URL**: `/` (Fastify)  
**Module guard**: `@RequireModulo('juridico')`

Extensão do contrato [012 rest-api-juridico](../../arquivados/012-desmock-juridico/contracts/rest-api-juridico.md) — endpoints **novos ou alterados** nesta feature.

## Headers

| Header | Rotas autenticadas |
|--------|-------------------|
| `Authorization: Bearer <jwt>` | Obrigatório |
| `X-Tenant-ID` | Obrigatório |

---

## GET `/juridico/processos` (NEW)

Lista paginada de processos do tenant.

**Query** (`ListProcessosQuery`):

| Param | Tipo | Default |
|-------|------|---------|
| `tipo` | `administrativo` \| `judicial` \| `consultivo` | — |
| `status` | `rascunho` \| `aberto` \| `vencendo` \| `critico` \| `concluido` | — |
| `q` | string | busca `internalNumber` + `subject` |
| `prazoAte` | ISO8601 | filtro deadline ≤ |
| `page` | int ≥ 1 | 1 |
| `pageSize` | int 1–100 | 20 |

**Response 200**:

```json
{
  "items": [
    {
      "id": "uuid",
      "numeroInterno": "JUR-2026-0047",
      "tipo": "judicial",
      "tipoLabel": "Judicial",
      "partesResumo": "Instituição · Fornecedor X",
      "status": "critico",
      "statusLabel": "Crítico",
      "prazo": "2026-06-01T00:00:00.000Z",
      "responsavel": "Dra. Silva"
    }
  ],
  "total": 47,
  "page": 1,
  "pageSize": 20
}
```

**Notas**:

- Rascunhos (`draft`) incluídos na lista com `numeroInterno: null`
- `status` operacional derivado (não status Prisma bruto quando aplicável)

---

## GET `/juridico/processos/:id` (NEW)

Detalhe completo para página de processo.

**Response 200**:

```json
{
  "id": "uuid",
  "numeroInterno": "JUR-2026-0047",
  "tipo": "judicial",
  "tipoLabel": "Judicial",
  "assunto": "Aditivo contratual — Fornecedor X",
  "numeroJudicial": "0001234-56.2026.8.26.0100",
  "observacoes": "Prazo improrrogável.",
  "prazo": "2026-07-15T00:00:00.000Z",
  "valorCausa": 250000.0,
  "responsavelInterno": "Dra. Silva",
  "status": "aberto",
  "statusLabel": "Aberto",
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
    }
  ],
  "anexos": [
    {
      "id": "uuid",
      "nomeArquivo": "peticao.pdf",
      "downloadUrl": "https://..."
    }
  ],
  "eventos": [
    {
      "tipo": "registration",
      "titulo": "Registro",
      "descricao": "Processo confirmado.",
      "createdAt": "2026-06-23T14:00:00.000Z",
      "autorNome": "Paulo Ribeiro"
    }
  ],
  "acoesPermitidas": ["tramitar"]
}
```

**Response 404**: `{ "message": "Processo não encontrado" }`

**Regras `acoesPermitidas`**:

| Status | Ações |
|--------|-------|
| `rascunho` | `[]` |
| confirmado | `["tramitar"]` |

---

## POST `/juridico/processos/:id/tramitar` (ALTERADO)

Comportamento existente; **alteração**: resolução setor origem via `ResolveTramitacaoSectorUseCase` (`preferredModuloSlug: juridico`).

**Body**:

```json
{
  "destinoSetorId": "uuid-setor",
  "observacao": "Encaminhar para parecer do Gabinete."
}
```

**Response 200**:

```json
{
  "tramitacaoDemandaId": "uuid",
  "tramitacaoProtocolNumber": "TRAM-2026-0012",
  "status": "pending"
}
```

**Response 400**:

| Caso | Message |
|------|---------|
| Rascunho | `Processo em rascunho não pode ser tramitado` |
| Setor origem indefinido | `ACTIVE_SECTOR_UNDEFINED` + copy institucional |

**Efeitos colaterais**:

1. Cria `TramitacaoDemanda` linked (`sourceModule: juridico`)
2. Snapshot v2 imutável
3. Cria `LegalProcessEvent` type `forwarding`

---

## Snapshot v2 (linked record)

Gerado em `mapProcessTramitacaoSnapshot` — ver [data-model.md](../data-model.md).

Campos mínimos FR-005: `protocolNumber`, `processType`/`typeLabel`, `status`/`statusLabel`, `summary`, `partiesSummary`.

---

## Erros canônicos

| Code | HTTP | Quando |
|------|------|--------|
| `MODULO_SETOR_DENIED` | 403 | Sem permissão módulo jurídico |
| `PROCESS_NOT_FOUND` | 404 | ID inexistente / outro tenant |
| `ACTIVE_SECTOR_UNDEFINED` | 400 | Tramitar sem setor origem resolvível |

---

## Endpoints inalterados nesta feature

- POST/PATCH `/juridico/processos` (wizard)
- POST `/juridico/processos/:id/confirm`
- Anexos presign/confirm (futuro wizard — fora escopo lista/detalhe v1 se anexos vazios)
