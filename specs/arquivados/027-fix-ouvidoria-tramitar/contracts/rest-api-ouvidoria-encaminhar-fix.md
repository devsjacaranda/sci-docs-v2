# Contract: REST API — Encaminhar manifestação (fix setor origem)

**Feature**: 027-fix-ouvidoria-tramitar  
**Base contract**: [003-ouvidoria rest-api-ouvidoria.md](../../arquivados/003-ouvidoria/contracts/rest-api-ouvidoria.md)  
**Delta**: resolução automática de setor de origem; sem mudança de body/response de sucesso.

## Endpoint

### POST `/ouvidoria/manifestacoes/:id/encaminhar`

**Guard**: `@RequireModulo('ouvidoria')`  
**Auth**: Bearer JWT + `X-Tenant-ID`

#### Request body (inalterado)

```json
{
  "destinoSetorId": "uuid-do-setor-destino",
  "observacao": "Motivo do encaminhamento."
}
```

| Campo | Tipo | Obrigatório |
|-------|------|-------------|
| `destinoSetorId` | UUID | Sim |
| `observacao` | string (min 1) | Sim |

> **Nota**: setor de **origem** NÃO é enviado pelo client — resolvido server-side a partir do contexto do usuário.

#### Response 200 (inalterado)

```json
{
  "status": "forwarding",
  "tramitacaoDemandaId": "uuid",
  "tramitacaoProtocolNumber": "TRAM-2026-0001"
}
```

Efeitos colaterais:

- Status manifestação → `forwarding`
- Evento timeline tipo `forwarding`
- Demanda vinculada criada em `/tramitacao` com `senderSectorId` = setor origem resolvido

#### Response 400 — setor origem irresolvível

```json
{
  "statusCode": 400,
  "message": "Não foi possível identificar o setor de origem. Cadastre setores no tenant ou vincule seu usuário a um setor autorizado na Ouvidoria.",
  "error": "BadRequestException",
  "code": "ACTIVE_SECTOR_UNDEFINED"
}
```

> Copy orientativa (FR-008). Código estável para mapeamento opcional no client.

#### Response 409 — status inválido (regressão)

```json
{
  "statusCode": 409,
  "message": "Status inválido para encaminhamento",
  "code": "INVALID_STATUS_TRANSITION"
}
```

Manifestação em `draft` ou `closed`.

#### Response 403 — sem permissão módulo (regressão)

Payload `MODULO_SETOR_DENIED` — inalterado.

## Resolução server-side de setor origem

Implementada via `ResolveTramitacaoSectorUseCase.execute(user, undefined, ModuloSlug.ouvidoria)`.

| Actor | Comportamento esperado |
|-------|------------------------|
| Servidor com `setorIds` no JWT | Origem = setor ouvidoria do usuário se vinculado; senão primeiro setor válido |
| Admin tenant (`setorIds: []`) | Origem = setor OUV vinculado ao módulo ouvidoria (seed Jacaranda) |
| Usuário com token desatualizado | Refresh via `loadUserSetorContext` antes de fallback institucional |
| Tenant sem setores | 400 `ACTIVE_SECTOR_UNDEFINED` |

## Wiring API (implementação)

| Arquivo | Alteração |
|---------|-----------|
| `tramitacao.module.ts` | Export `ResolveTramitacaoSectorUseCase` |
| `resolve-tramitacao-sector.use-case.ts` | Parâmetro `preferredModuloSlug`; priorização setor do módulo |
| `ouvidoria.controller.ts` | Substituir check manual por `await resolveSector.execute(...)` |

## Client (validação — sem contrato novo)

`ForwardManifestacaoDialog` continua POST com body acima; exibe `message` de erro sem limpar formulário.
