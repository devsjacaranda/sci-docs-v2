# Contract: REST API — Gabinete Tramitação Linked

**Feature**: 030-gabinete-tramitacao-linked  
**Version**: 1.0.0  
**Base URL**: `/` (Fastify)  
**Module guard**: `@RequireModulo('gabinete')`

Extensão do contrato [012 rest-api-gabinete](../../arquivados/012-desmock-gabinete/contracts/rest-api-gabinete.md) — endpoint **alterado** nesta feature.

## Headers

| Header | Rotas autenticadas |
|--------|-------------------|
| `Authorization: Bearer <jwt>` | Obrigatório |
| `X-Tenant-ID` | Obrigatório |

---

## POST `/gabinete/cabinets/:cabinetId/forward` (ALTERADO)

Encaminha ato a outro setor e cria demanda linked na Tramitação.

**Alias deprecated**: `POST /gabinete/demandas/:cabinetId/forward` — mesmo comportamento.

**Body** (`ForwardCabinetBody`):

```json
{
  "sectorId": "uuid-setor-destino",
  "notes": "Encaminhar para parecer jurídico sobre cláusula 5."
}
```

| Campo | Tipo | Obrigatório | Notas |
|-------|------|-------------|-------|
| `sectorId` | UUID | sim | Setor destinatário |
| `notes` | string 1–1000 | **sim** (alteração v1) | Motivo do encaminhamento |

**Response 200**:

```json
{
  "id": "uuid-cabinet",
  "status": "in_transit",
  "forwardings": [
    {
      "sectorId": "uuid-destino",
      "userId": "uuid-actor",
      "at": "2026-07-01T12:00:00.000Z",
      "notes": "Encaminhar para parecer jurídico…"
    }
  ],
  "tramitacaoDemandaId": "uuid-demanda",
  "tramitacaoProtocolNumber": "TRAM-2026-0012",
  "tramitacaoTargetSectorId": "uuid-destino"
}
```

**Response 400**:

| Caso | Code | Message (PT-BR) |
|------|------|-----------------|
| Rascunho | `INVALID_STATUS` | Apenas atos registrados podem ser tramitados |
| Arquivado/finalizado | `INVALID_STATUS` | Ato arquivado/finalizado não pode ser tramitado |
| Mesmo setor | `SAME_SECTOR` | Não é possível tramitar ao mesmo setor |
| Setor origem indefinido | `SENDER_SECTOR_UNDEFINED` | Setor remetente não definido (+ copy acionável) |
| Notes vazio | Zod validation | Observação obrigatória |

**Efeitos colaterais**:

1. Atualiza `CabinetDemanda.status` → `in_transit`
2. Append `forwardings` JSON
3. Cria `CabinetDemandaEvento` type `forwarded` (actor auditável)
4. Cria `TramitacaoDemanda` linked (`sourceModule: gabinete`, snapshot v2)

---

## Snapshot v2 (linked record)

Gerado em `mapCabinetTramitacaoSnapshot` — ver [data-model.md](../data-model.md).

Campos mínimos FR-003: `protocolNumber`, `subject`, `status`/`statusLabel`, `origin`/`originLabel`, `description`, `capturedAt`.

---

## Endpoints inalterados nesta feature

- GET `/gabinete/cabinets` (lista atos)
- GET `/gabinete/cabinets/:cabinetId` (detalhe)
- POST/PATCH CRUD atos, protocolos, controles
- Demais rotas gabinete (fiscalização, insights, maturidade)

---

## Erros canônicos

| Code | HTTP | Quando |
|------|------|--------|
| `MODULO_SETOR_DENIED` | 403 | Sem permissão módulo gabinete |
| `CABINET_NOT_FOUND` | 404 | ID inexistente / outro tenant |
| `SAME_SECTOR` | 400 | Origem = destino |
| `SENDER_SECTOR_UNDEFINED` | 400 | Tramitar sem setor origem resolvível |
| `INVALID_STATUS` | 400 | Status inelegível |
