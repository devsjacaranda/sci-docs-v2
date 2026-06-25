# Contract: REST API — Gabinete (Base)

**Feature**: 012-desmock-gabinete  
**Version**: 1.0.0  
**Base URL**: `/` (Fastify)  
**Module guard**: `@RequireModulo('gabinete')` em todas as rotas deste contrato

## Headers

| Header | Required |
|--------|----------|
| `Authorization: Bearer <jwt>` | yes |
| `X-Tenant-ID` | yes |

---

## Dashboard

### GET `/gabinete/dashboard`

**Query**: `periodDays` (optional, default 365)

**Response 200**:

```json
{
  "total": 42,
  "inAnalysis": 8,
  "inTransit": 5,
  "finished": 24,
  "pending": 3,
  "byStatus": [{ "status": "in_analysis", "count": 8 }],
  "periodStart": "2025-06-23T00:00:00.000Z",
  "periodEnd": "2026-06-23T23:59:59.999Z"
}
```

---

## Cabinets (ato — entidade `CabinetDemanda` internamente)

> **Amendment 2026-06-23**: rotas públicas usam `cabinetId`; UI mantém `/gabinete/atos/*` e vocabulário *ato*.

### POST `/gabinete/cabinets`

Cria ato (cabinet). Body: `CreateCabinetBody` (mesmo shape anterior `CreateCabinetDemandaBody`).

**Response 201**: `{ id, protocolNumber, status }`

Legacy: `POST /gabinete/demandas` permanece como alias deprecated.

---

### GET `/gabinete/cabinets/:cabinetId`

Detalhe completo: ato, protocolo, forwardings, timeline, counts de controles.

---

### PATCH `/gabinete/cabinets/:cabinetId`

Atualiza campos editáveis; emite evento `updated`.

---

### DELETE `/gabinete/cabinets/:cabinetId`

Soft delete.

---

### POST `/gabinete/cabinets/:cabinetId/forward`

Stub Tramitar (FR-007).

---

## Protocolo (nested under cabinet)

Base: `/gabinete/cabinets/:cabinetId/protocolo`

| Method | Action |
|--------|--------|
| GET | Protocolo vinculado |
| POST | Cria e vincula |
| PATCH | Atualiza |
| DELETE | Desvincula + soft delete |

---

## Anexos

### POST `/gabinete/cabinets/:cabinetId/anexos/presign`

### POST `/gabinete/cabinets/:cabinetId/anexos/:anexoId/confirm`

Mesmo contrato de [003-ouvidoria REST anexos](../../003-ouvidoria/contracts/rest-api-ouvidoria.md): 30 MB, MIME allowlist, Wasabi presigned.

---

## Controles — nested under cabinet

Base path: `/gabinete/cabinets/:cabinetId/...`

| Resource | Methods |
|----------|---------|
| `/controles-numericos` | GET, POST |
| `/controles-numericos/:id` | GET, PATCH, DELETE |
| `/notificacoes` | GET, POST |
| `/notificacoes/:id` | GET, PATCH, DELETE |
| `/autos-infracao` | GET, POST |
| `/autos-infracao/:id` | GET, PATCH, DELETE |
| `/documentos-tramitados` | GET, POST |
| `/documentos-tramitados/:id` | GET, PATCH, DELETE |

**POST documentos-tramitados** exige `setorId`; demais campos opcionais. *(API documentos tramitados adiada — UI mock até Tramitação.)*

**Errors**: 400 validação Zod; 403 módulo/setor; 404 tenant-scoped.

---

## Erros padrão

```json
{
  "statusCode": 403,
  "code": "MODULO_SETOR_DENIED",
  "moduloSlug": "gabinete",
  "moduloLabel": "Gabinete do Presidente"
}
```
