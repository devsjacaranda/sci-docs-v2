# Contrato consumido — Integração viva SIGED

Fonte canônica: `integração-siged/openapi.json` (ambiente de homologação documentado: `https://siged-integracao-api-tst.manaus.am.gov.br`). Este arquivo resume apenas o subconjunto de rotas que o v2 consome (FR-020..023) — para o schema completo, ver o OpenAPI original.

## Autenticação (M2M)

```
POST /api/auth/token
Content-Type: application/json

{ "usuarioId": "...", "usuarioSecret": "..." }
```

**Resposta 200**:
```json
{ "sucesso": true, "dados": { "tokenAcesso": "<JWT HS256>", "expiraEmSegundos": 3600 } }
```

O JWT contém as claims `admin` (bool) e `cod_empresa` (secretariaId ao qual o cliente tem acesso). Todas as requisições subsequentes usam `Authorization: Bearer {tokenAcesso}`. O v2 deve cachear o token até pouco antes de expirar (`expiraEmSegundos`) e renovar automaticamente.

**Erros**: 401 quando `usuarioId`/`usuarioSecret` inválidos — v2 deve tratar como "integração SIGED não configurada" (FR-023), nunca como 500.

## Hierarquia organizacional (opcional — usado no cadastro do `secretariaId`)

```
GET /api/departamentos/hierarquia/{secretariaId}
Authorization: Bearer {token}
```

Retorna árvore de órgãos (`orgaoId`, `sigla`, `descricao`, `subordinados`). Para AGEMAN, `secretariaId = "18692"` (confirmado). Uso apenas administrativo/setup, não é chamado durante o uso normal do protocolo.

## Tramitações de um protocolo (rota principal consumida pela feature)

```
GET /api/movimentacoes/tramitacoes?ProtocoloId={id}&Pagina={n}
Authorization: Bearer {token}
```

**Resposta 200** (`dados.tramitacoes[]`, paginado, 50/página fixo):
```json
{
  "sucesso": true,
  "dados": {
    "totalRegistros": 12,
    "totalPaginas": 1,
    "tramitacoes": [
      {
        "dataMovimento": "2026-03-10T14:00:00Z",
        "orgaoOrigemSigla": "GAB",
        "orgaoDestinoSigla": "DEAE",
        "statusRecebimento": 1
      }
    ]
  }
}
```

`statusRecebimento = 1` → recebido pelo órgão de destino; outros valores → pendente/recusado (mapear tabela de significados em `tasks.md` a partir do OpenAPI completo).

**Erros que o v2 precisa tratar sem quebrar a tela do protocolo (FR-023)**:
- `403 Forbidden` — protocolo pertence a outra `SecretariaId` fora do `cod_empresa` do token (não deveria ocorrer para protocolos legitimamente da AGEMAN, mas é tratado como "sem acesso" — nunca 500)
- `401` — token expirado/inválido → renovar uma vez e tentar novamente antes de reportar erro ao usuário
- Indisponibilidade de rede/timeout — mensagem genérica de "SIGED indisponível" (FR-023)
- `ProtocoloId` inexistente no SIGED — mensagem "tramitação não encontrada no SIGED para este número" (Edge Case da spec)

## Contrato exposto pelo v2 (novo endpoint no `ci-api-v2`)

```
GET /gabinete/protocolos/:protocoloId/tramitacoes-siged
Authorization: Bearer {JWT interno do v2}
X-Tenant-ID: <tenant>
```

**Resposta 200**:
```json
{
  "sigedNumber": "12345",
  "disponivel": true,
  "tramitacoes": [
    { "dataMovimento": "2026-03-10T14:00:00Z", "origem": "GAB", "destino": "DEAE", "recebido": true }
  ]
}
```

**Resposta quando não há número SIGED** (`CabinetProtocolo.sigedNumber = null`):
```json
{ "sigedNumber": null, "disponivel": false, "motivo": "sem_numero_siged", "tramitacoes": [] }
```

**Resposta quando o SIGED está indisponível**:
```json
{ "sigedNumber": "12345", "disponivel": false, "motivo": "siged_indisponivel", "tramitacoes": [] }
```

Schema de validação (`siged.schemas.ts`) implementado com Zod (`nestjs-zod`), sem `class-validator`, conforme Constitution III.
