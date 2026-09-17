# Contract: Visibilidade na Listagem e 403 nas Ações Diretas

## Passo 0 (todas as regras abaixo) — feature flag do tenant (FR-014 a FR-020)

Antes de qualquer regra de dono/chefe/admin/concessão, tanto a listagem quanto `assertManifestacaoAccess` checam `getOuvidoriaAcessoFlag(tenantId)` (ver `contracts/ouvidoria-acesso-flag.md`):

- Flag **desligado** → acesso liberado para todo mundo, sem aplicar nenhuma regra abaixo (kill-switch — FR-015). A listagem não filtra; `assertManifestacaoAccess` sempre retorna `{ allowed: true, reason: 'flag-disabled' }`.
- Flag **ligado** (padrão, inclusive quando não há linha configurada — FR-018) → seguem as regras normais desta feature, descritas abaixo.

## GET `/ouvidoria/manifestacoes` (listagem — FR-008)

**Sem mudança de assinatura** (mesmos query params). **Correção PO (2026-09-16)**: a listagem **não** filtra por dono/emissor/grant.

- Qualquer operador com módulo Ouvidoria recebe **todas** as manifestações do tenant (mesmo universo dos KPIs).
- Filtros de produto continuam (tipo, status, protocolo, rascunho, período, origem, etc.).
- Flag ligado ou desligado: **nenhum** `WHERE` extra de visibilidade por dono. `resolveListVisibility` / o use-case de lista usam `mode: 'bypass'` (ou omitem o filtro).
- **Nunca** retorna 403 nesta rota por falta de permissão de dono — a linha alheia aparece na tabela.
- `total`/`page`/`limit` refletem o universo do tenant (após filtros de produto), alinhado aos KPIs.

## Endpoints que DEVEM aplicar `assertManifestacaoAccess` (403 explícito — FR-007)

Todos operam sobre um `:id` de manifestação específica. Lista fechada nesta feature (ver spec, Assumptions):

| Método | Rota | Use-case |
|---|---|---|
| GET | `/ouvidoria/manifestacoes/:id` | `GetManifestacaoDetailUseCase` |
| PATCH | `/ouvidoria/manifestacoes/:id` | `UpdateManifestacaoDraftUseCase` |
| DELETE | `/ouvidoria/manifestacoes/:id` | `DeleteManifestacaoUseCase` |
| GET | `/ouvidoria/manifestacoes/:id/revisao` | `GetManifestacaoRevisaoUseCase` |
| GET | `/ouvidoria/manifestacoes/:id/retomabilidade` | `GetManifestacaoRetomabilidadeUseCase` |
| POST | `/ouvidoria/manifestacoes/:id/confirmar` | `ConfirmManifestacaoUseCase` |
| POST | `/ouvidoria/manifestacoes/:id/encaminhar` | `EncaminharManifestacaoUseCase` |
| POST | `/ouvidoria/manifestacoes/:id/responder` | `ResponderManifestacaoUseCase` |
| POST | `/ouvidoria/manifestacoes/:id/encerrar` | `EncerrarManifestacaoUseCase` |
| GET | `/ouvidoria/manifestacoes/:id/documento/docx` | `GenerateManifestacaoDocxUseCase` |
| GET | `/ouvidoria/manifestacoes/:id/documento/pdf` | `GenerateManifestacaoPdfUseCase` |
| POST | `/ouvidoria/manifestacoes/:id/anexos/presign` | `PresignAnexoUseCase` |
| POST | `/ouvidoria/manifestacoes/:id/anexos/link` | `AddLinkAnexoUseCase` |
| POST | `/ouvidoria/manifestacoes/:id/anexos/:anexoId/confirm` | `ConfirmAnexoUseCase` |
| GET | `/ouvidoria/manifestacoes/:id/acessos` | `ListOuvidoriaAcessosUseCase` (novo) |

**Fora desta lista, sem alteração** (conforme FR-010/Out of Scope): `dashboard`, `relatorio-gestao*`, `auditoria`, `pesquisa-satisfacao*`, `tipos`, `formas-atendimento`, `assuntos`, `atendimentos-internos`, `usuarios-emissores`, e todas as rotas `@Public()`.

**Também fora desta lista** (rotas tenant-level, não record-level — guardadas por role, não por `assertManifestacaoAccess`): `GET|PATCH /ouvidoria/acesso-flag` e `PATCH /admin/tenants/:tenantId/feature-flags/ouvidoria-acesso` — ver `contracts/ouvidoria-acesso-flag.md`. Endpoints de conceder/revogar acesso (`POST|DELETE /ouvidoria/acessos`) continuam funcionando normalmente mesmo com o flag desligado (ver `research.md` §9) — apenas não têm efeito na decisão de acesso enquanto o flag estiver desligado.

## Formato da resposta 403 (FR-007/FR-013)

```json
{
  "statusCode": 403,
  "message": "Você não tem acesso a esta demanda.",
  "error": "ForbiddenException",
  "code": "OUVIDORIA_ACCESS_DENIED",
  "timestamp": "2026-09-16T12:00:00.000Z",
  "path": "/ouvidoria/manifestacoes/<id>"
}
```

**Regra dura**: nenhum campo de conteúdo da manifestação (`subject`, `description`, `requester*`, `address`, `anexos`, `eventos`, etc.) pode aparecer nesta resposta. O `assertManifestacaoAccess` deve ser chamado **antes** de qualquer leitura/montagem de campos de conteúdo — apenas o mínimo necessário para a decisão (`id`, `emissorUserId`) pode ter sido carregado do banco previamente.

## Client — mapeamento de erro

`ci-client-v2/apps/web/src/modules/ouvidoria/api/errors.ts` — novo `CODE_SPECS.OUVIDORIA_ACCESS_DENIED`:

```typescript
OUVIDORIA_ACCESS_DENIED: {
  kind: 'permission',
  surface: 'page',
  title: 'Sem acesso a esta demanda',
  message:
    'Você não tem acesso a esta demanda. Peça ao emissor, a um chefe da Ouvidoria ou a um administrador para liberar seu acesso.',
  retryable: false,
},
```

Renderizado pelo `OuvidoriaErrorAlert` já existente no fluxo de erro de `ManifestacaoDetailPage`/`ManifestacaoWizardPage` (mesmo caminho de código já usado para 404/permission — sem componente novo, ver `research.md` §7).
