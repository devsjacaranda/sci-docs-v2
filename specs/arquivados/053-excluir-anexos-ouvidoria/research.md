# Research — 053 Excluir Anexos de Manifestação

Todas as incógnitas do Technical Context foram resolvidas abaixo. Nenhum `NEEDS CLARIFICATION` restante.

## R1 — Ordem das operações (Wasabi × banco)

- **Decision**: apagar no Wasabi **primeiro**; só depois gravar o tombstone e o evento no banco (transação).
- **Rationale**: a spec exige que falha do armazenamento mantenha o anexo ativo e acessível, sem evento (FR-014/015). Se o banco falhar *depois* de o arquivo sumir, o usuário vê erro, o item continua listado, e o retry é idempotente (objeto inexistente = sucesso, FR-016) — o estado converge sem "arquivo fantasma".
- **Alternatives**: (a) banco primeiro + Wasabi depois — se o Wasabi falhar, o item já estaria oculto mas o arquivo ainda baixável (viola FR-014/015); (b) estado `pending_deletion` + job de reconciliação — mais seguro contra queda no meio, porém exige worker, nova máquina de estados e UI para estado intermediário; desproporcional para a janela de milissegundos.

## R2 — Exclusão definitiva no bucket (versionamento / object lock)

- **Decision**: novo `StorageService.deleteObjectPermanently(storageKey)`:
  1. `validateTenantPath(key, tenantId)` (mesma invariante do download) + rejeitar chave vazia, com `..` ou `\`.
  2. `ListObjectVersionsCommand({ Prefix: key })` paginado; **filtrar `v.Key === key`** (prefixo casaria `…/anexo` com `…/anexo-2`).
  3. Para cada versão e delete-marker: `DeleteObjectCommand` com `VersionId` (quando presente e ≠ `"null"`); sem versão ⇒ delete simples.
  4. `HeadObjectCommand` deve falhar com `NotFound`/`404`; se o objeto ainda existir ⇒ erro (FR-015).
  5. Qualquer erro S3 (inclusive `AccessDenied` por object lock/retenção) ⇒ exceção; **nunca** engolir.
  Em modo stub (sem credenciais) usa `deleteLocalObject`, igual ao restante do serviço.
- **Rationale**: `deleteObject` atual faz `DeleteObjectCommand` sem `VersionId` — em bucket **versionado** isso apenas cria *delete marker* e deixa as versões recuperáveis, contrariando "apagar definitivamente". Também não valida o tenant. A listagem + exclusão por versão cobre bucket versionado e não versionado sem precisar conhecer a configuração (pendência da spec).
- **Pré-requisitos operacionais** (checados no [quickstart](./quickstart.md)): a credencial do Wasabi precisa de `s3:ListBucketVersions`, `s3:DeleteObjectVersion` e `s3:GetObject`/`HeadObject`; se houver **Object Lock** em modo compliance/governance, a exclusão falhará por design e a UI mostrará erro — a spec não permite contornar retenção.
- **Nota de custo**: o Wasabi cobra no mínimo 90 dias de armazenamento por objeto, mesmo apagado antes; não muda o comportamento funcional.
- **Alternatives**: `DeleteObjects` em lote (desnecessário: poucas versões por anexo); manter `deleteObject` e documentar o risco (rejeitado: deixa dado "excluído" recuperável).

## R3 — Tombstone no banco

- **Decision**: colunas em `ManifestacaoAnexo`: `deletedAt`, `deletedByUserId` (FK User, nullable, `SET NULL`), `deletedByActorId`, `deletedByActorRole` (`UserRole?`). Ao excluir: `storageKey = NULL`, `externalUrl = NULL`. `CHECK ("deletedAt" IS NULL OR ("storageKey" IS NULL AND "externalUrl" IS NULL))`. Mantém `fileName`, `kind`, `mimeType`, `sizeBytes`, `uploadedByUserId`, `createdAt` (FR-010).
- **Rationale**: ponteiro nulo + `CHECK` garantem que um tombstone nunca expõe conteúdo, mesmo se algum filtro de leitura for esquecido (defesa em profundidade; `isVisibleManifestacaoAnexo` já oculta `file` sem `storageKey`). Para `link`, o filtro por `deletedAt` é necessário (links são visíveis por `kind`), por isso o mapper também checa `deletedAt`.
- **Alternatives**: adicionar `ManifestacaoAnexo` a `SOFT_DELETE_MODELS` (rejeitado: a extensão só existe em `prisma.db`, o Ouvidoria usa o client base, e `include` aninhado não é filtrado pela extensão); tabela separada de auditoria (rejeitado: duplica dados sem ganho).

## R4 — Evento na linha do tempo

- **Decision**: novo valor `attachment_deleted` em `ManifestacaoEventoTipo` (migration própria, padrão da `closed_meio_juridico`). `titulo = "Anexo excluído"` (constante); `descricao = Arquivo "<nome>" excluído.` + ` Por <rótulo>.` quando o autor não é linha de `User`. `autorUserId` = `resolveUserTableId(...)`.
- **Rationale**: `autorNome` do timeline vem do FK; AdminTenant não tem FK (regra `admin-tenant-user-fk`), então o rótulo vai na `descricao` (FR-012). Enum dedicado permite filtrar o evento nas superfícies públicas e distinguir de `note`. O nome do arquivo fica só em `descricao` (nunca no `titulo`, que é o único campo exposto a cidadão em `marcos`).
- **Rótulo do AdminTenant**: `adminTenant.findFirst({ where: { id, tenantId } })` → `name ?? email`; `admin_saas` → "Administrador da plataforma".
- **Alternatives**: reutilizar `note` (rejeitado: mistura com "Acesso solicitado" e impede filtro semântico); gravar actor em JSON (rejeitado: o evento não tem coluna JSON).

## R5 — Exposição pública do evento

- **Decision**: `ConsultaPublicaUseCase` filtra `tipo !== attachment_deleted` em `marcos`.
- **Rationale**: hoje `marcos` mapeia **todos** os eventos (`data` + `titulo`) para o cidadão. O evento é trilha interna de auditoria; não deve virar marco público.

## R6 — Segurança da rota

- **Decision**: `@RequireModulo('ouvidoria')` + `ManifestacaoAccessService.assertForUser` (spec 047) + `@Throttle` mais restritivo que o padrão (ex.: 20 req/min) + params validados por Zod (`z.string().trim().min(1).max(64)` — **sem `z.uuid()`**, pois IDs migrados do v1 podem não ser UUID).
- **Rationale**: ação destrutiva; a regra "qualquer usuário com acesso" foi decisão de produto, então os limites técnicos (tenant explícito, status, rate limit, auditoria) são a compensação.

## R7 — Queries que não podem depender da extensão de tenant

- **Decision**: repositories novos filtram `tenantId` (via `getRequestContext()`) e `deletedAt: null` (manifestação) **explicitamente**; `updateMany`/`update` incluem `tenantId` no `where`. Não reutilizar `RequireManifestacaoRepository` nem `FindManifestacaoAnexoRepository` sem filtro de tenant.
- **Rationale**: confirmado no código — `createTenantExtension` / `createSoftDeleteExtension` só são aplicados em `PrismaService.db`; os repositories do Ouvidoria usam `this.prisma.<model>` (client base). Além disso, a extensão tenant só cobre `findMany/findFirst/count/create/createMany`, nunca `update*`. Ver achado F1 em [security.md](./security.md).

## R8 — Chave de storage compartilhada

- **Decision**: antes de apagar o objeto, contar outros `ManifestacaoAnexo` ativos (`deletedAt IS NULL`, `id ≠ atual`) com a mesma `storageKey`; se > 0 ⇒ 409 `OUVIDORIA_ANEXO_DELETE_BLOCKED` e nada é apagado.
- **Rationale**: as chaves não são únicas no schema; anexos migrados/importados ou copiados poderiam apontar para o mesmo objeto. Apagar o objeto quebraria o outro registro (FR-018). Caso raro, falha fechada, registrado em log para operação.
- **Alternatives**: só tombstone sem apagar o objeto (rejeitado: contradiz FR-008).

## R9 — Leitura: onde o tombstone deve sumir

| Superfície | Origem | Ajuste |
|---|---|---|
| Detalhe (`GET /manifestacoes/:id`) | `FindManifestacaoByIdRepository` | `include: { anexos: { where: { deletedAt: null } } }` |
| Revisão do assistente | idem | idem (+ `anexosExcluiveis`) |
| Export PDF/DOCX e documento | idem (`row.anexos`) | herdam o filtro |
| `confirm` de anexo | `FindManifestacaoAnexoRepository` | `deletedAt: null` (confirmar tombstone ⇒ 404) |
| Mapper | `isVisibleManifestacaoAnexo` | também rejeita `deletedAt` (defesa em profundidade) |
| Consulta pública | `marcos` | exclui `attachment_deleted` |
| Presign de download | só por anexos listados | tombstone não lista ⇒ sem URL |

URLs pré-assinadas já emitidas expiram em ≤ 15 min (`PRESIGN_EXPIRES = 900`); após a exclusão o objeto deixa de existir, então a URL passa a retornar 404 imediatamente (aceito na spec).

## R10 — Cliente

- **Decision**: componente `ManifestacaoAnexoItem` reutilizado em: card Anexos (detalhe), `AnexoUploadZone` (edição) e `RevisaoAnexos` (revisão). Diálogo com `Dialog` de `@ci/ui` (o monorepo não tem `AlertDialog`), foco inicial no botão **Cancelar**, botão destrutivo desabilitado durante a requisição, erro exibido com `OuvidoriaErrorAlert` dentro do diálogo.
- **Visibilidade do botão**: vem do servidor (`anexosExcluiveis`), calculado por `canDeleteAnexos(status)`; o client trata ausência como `false` (fail-closed). O servidor revalida sempre.
- **Bug encontrado que bloqueia a feature**: `AnexoUploadZone` insere anexos recém-enviados com `id: file.name` / `id: linkTitle` (não é o id real). `presignAnexo` já devolve `anexoId` e `addLinkAnexo` também; o componente deve usá-los, senão o botão excluiria um id inexistente.
- **Erros novos** no `CODE_SPECS`: `OUVIDORIA_ANEXO_DELETE_CLOSED` (conflict), `OUVIDORIA_ANEXO_DELETE_BLOCKED` (conflict), `OUVIDORIA_ANEXO_DELETE_FAILED` (server, retryable). **HTTP 500** (não 502/503/504) para que `mapOuvidoriaError` chegue à tabela por código em vez do ramo genérico "servidores fora do ar".

## R11 — Concorrência com mudança de status

- **Decision**: o status é lido antes da exclusão no storage e **relido dentro da transação do tombstone** apenas para log (`warn`) caso a manifestação tenha sido encerrada no intervalo; o tombstone é concluído mesmo assim.
- **Rationale**: depois que o objeto foi apagado, abortar deixaria o registro apontando para um arquivo inexistente. A janela é de milissegundos e o efeito é o mesmo que o usuário confirmou. Segurar uma transação de banco aberta durante chamada de rede foi descartado (anti-padrão). Risco residual aceito e documentado em [security.md](./security.md).

## R12 — Auditoria

- **Decision**: três trilhas — (1) evento `attachment_deleted` na linha do tempo; (2) tombstone com autor/`deletedAt`; (3) `AuditInterceptor` já registra toda mutação `DELETE` (userId, role, rota). Log Pino estruturado `anexo.deleted` / `anexo.delete_failed` com `tenantId`, `manifestacaoId`, `anexoId`, `actorId`, `role` — **sem** nome do arquivo (pode conter PII).
- **Rationale**: como não há motivo obrigatório (decisão de produto), a rastreabilidade compensa.

## Fora de escopo (confirmado)

Exclusão em massa, limpeza de órfãos/`ManifestacaoAnexoPublicoTemp`, outros módulos, restauração, reabrir manifestação, aprovação em duas etapas, correção dos achados pré-existentes F1–F3 de [security.md](./security.md) (apenas reportados).
