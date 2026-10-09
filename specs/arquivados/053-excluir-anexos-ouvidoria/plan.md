# Implementation Plan: Excluir Anexos de Manifestação (Ouvidoria)

**Branch**: `053-excluir-anexos-ouvidoria` | **Date**: 2026-10-08 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `civ2-docs/specs/053-excluir-anexos-ouvidoria/spec.md`

## Summary

Nova rota `DELETE /ouvidoria/manifestacoes/:id/anexos/:anexoId` que apaga **definitivamente** o arquivo no Wasabi (todas as versões) e mantém no banco um registro **"excluído"** (tombstone) + evento `attachment_deleted` na linha do tempo. Cliente: botão "Excluir" com diálogo de confirmação no card Anexos do detalhe e nas listas de anexos do assistente.

Pontos centrais da abordagem (detalhe em [research.md](./research.md) e [security.md](./security.md)):

1. **Ordem das operações: Wasabi primeiro, banco depois.** Falha no Wasabi ⇒ nada muda (FR-014). Falha no banco após apagar o arquivo ⇒ retry conclui (FR-016/017). Nunca "esconder" um arquivo que ainda existe.
2. **Exclusão real no bucket**: método novo `StorageService.deleteObjectPermanently` — valida caminho do tenant, lista versões da chave **exata**, apaga versões e delete-markers, confirma por `HeadObject`. O `deleteObject` atual (delete simples, sem validar tenant) **não** é usado.
3. **Isolamento explícito**: os repositories do Ouvidoria usam o `PrismaService` base (sem a extensão de tenant/soft-delete de `prisma.db`). Todas as queries novas levam `tenantId` e `deletedAt: null` **no `where`**, e não reutilizam `RequireManifestacaoRepository`.
4. **Tombstone sem conteúdo**: `storageKey` e `externalUrl` viram `null`; `CHECK` no banco impede tombstone com ponteiro de conteúdo.
5. **Idempotência/concorrência**: `updateMany ... WHERE deletedAt IS NULL` + evento criado só quando `count === 1`.
6. **Superfícies de leitura filtradas**: detalhe, revisão, exportações PDF/DOCX e documento usam o `include` de anexos filtrado; consulta pública não expõe o evento de exclusão.

## Technical Context

**Language/Version**: TypeScript (Node, NestJS 11 + Fastify) na API; React 19 + Vite 8 no client

**Primary Dependencies**: `@aws-sdk/client-s3` (já instalado: acrescenta `ListObjectVersionsCommand`, `HeadObjectCommand`, `DeleteObjectCommand` com `VersionId`), Prisma 7, Zod (nestjs-zod), `@ci/ui` (`Dialog`, `Button`), Lucide

**Storage**: PostgreSQL (2 migrations: colunas do tombstone + valor de enum de evento) e Wasabi (S3-compatível; `WASABI_PREFIX` permanece vazio)

**Testing**: Jest (API, `test/` espelhando camadas) e Vitest + Testing Library (client). TDD RED → GREEN → REFACTOR

**Target Platform**: API REST multi-tenant + SPA `@ci/web`

**Project Type**: web-service + web-application (monorepo `ci-api-v2` / `ci-client-v2`)

**Performance Goals**: exclusão de 1 anexo concluída em < 3 s em condições normais (SC-001: < 10 s ponta a ponta); sem tarefas assíncronas

**Constraints**: fail-closed; sem estado "meio apagado" visível ao usuário; sem mudança em dados de produção na entrega; sem `class-validator`; `@RequireModulo('ouvidoria')` + regra de acesso da spec 047

**Scale/Scope**: 1 rota, 1 use-case, 4–5 repositories novos, 1 método de storage, 2 migrations, ~3 componentes client novos/alterados

## Constitution Check

*GATE: passa antes da pesquisa e após o design.*

| Princípio | Verificação | Status |
|---|---|---|
| I. Spec-Driven | spec → clarify → plan (este) → tasks → implement → complete | PASS |
| II. Test-First | Toda tarefa de produção precede teste RED (ver [quickstart.md](./quickstart.md) e a matriz de testes abaixo) | PASS |
| III. Stack fixa | NestJS/Prisma/Zod; React/shadcn via `@ci/ui`; sem nova dependência | PASS |
| IV. Multi-tenant | `tenantId` explícito no `where` (repos do Ouvidoria usam o client base); `deletedAt: null` explícito; AdminTenant via `resolveUserTableId` + `deletedByActorId/Role`; sem licença nova (`@RequireModulo('ouvidoria')`) | PASS |
| V. Clean code/modularidade | 1 arquivo = 1 operação em repository/use-case; 1 controller/1 schemas; client em `modules/ouvidoria/` | PASS |
| Regra `admin-tenant-user-fk` | FK `deletedByUserId` nullable `ON DELETE SET NULL`; admin gravado em `deletedByActorId` + `deletedByActorRole` | PASS |
| OWASP (skill `owasp-security`) | Revisão em [security.md](./security.md): A01, A04, A06, A09, A10 endereçados; 1 achado pré-existente fora de escopo reportado | PASS (com ressalvas documentadas) |

**Re-check pós-design (Phase 1)**: sem violações novas. Complexity Tracking vazio.

## Project Structure

### Documentation (this feature)

```text
civ2-docs/specs/053-excluir-anexos-ouvidoria/
├── plan.md                 # este arquivo
├── research.md             # Phase 0 — decisões e alternativas
├── data-model.md           # Phase 1 — colunas, enum, invariantes, queries
├── security.md             # Revisão OWASP (A01–A10, ASVS), achados e mitigação
├── quickstart.md           # Phase 1 — validação ponta a ponta
├── contracts/
│   └── delete-manifestacao-anexo.md   # rota, respostas, erros, contrato do client
├── checklists/requirements.md
└── tasks.md                # /speckit-tasks (não criado aqui)
```

### Source Code (repository root)

```text
ci-api-v2/
├── prisma/
│   ├── schema/manifestacao.prisma            # + deletedAt/deletedBy*, enum attachment_deleted, relações nomeadas
│   ├── schema/user.prisma                    # relações nomeadas (uploadedBy / deletedBy)
│   └── migrations/
│       ├── 20261008120000_manifestacao_anexo_tombstone/migration.sql
│       └── 20261008120100_manifestacao_evento_attachment_deleted/migration.sql
└── src/
    ├── modules/shared/storage/
    │   ├── storage.port.ts                   # + deleteObjectPermanently(storageKey)
    │   ├── storage.service.ts                # implementação S3 (versões, verificação) e stub
    │   └── storage.service.delete-permanently.spec.ts
    └── modules/ouvidoria/
        ├── ouvidoria.controller.ts           # + DELETE manifestacoes/:id/anexos/:anexoId (@Throttle)
        ├── ouvidoria.schemas.ts              # + DeleteManifestacaoAnexoParams (Zod)
        ├── ouvidoria.module.ts               # registra repos/use-case
        ├── lib/
        │   ├── ouvidoria-errors.ts           # + ANEXO_DELETE_CLOSED / _BLOCKED / _FAILED
        │   ├── manifestacao-anexo-delete-policy.ts      # canDeleteAnexos(status) — pura
        │   └── map-manifestacao-anexos.ts    # isVisible: ignora deletedAt
        ├── repository/
        │   ├── find-manifestacao-for-anexo-delete.repository.ts       # tenant + deletedAt null
        │   ├── find-manifestacao-anexo-including-deleted.repository.ts
        │   ├── count-anexos-sharing-storage-key.repository.ts
        │   ├── tombstone-manifestacao-anexo.repository.ts             # $transaction: updateMany + evento
        │   ├── resolve-anexo-actor-label.repository.ts                # AdminTenant → nome
        │   └── manifestacao.repositories.ts  # findById: anexos { where: { deletedAt: null } }; FindAnexo: deletedAt null
        ├── use-cases/
        │   ├── delete-manifestacao-anexo.use-case.ts
        │   ├── get-manifestacao-detail.use-case.ts      # + anexosExcluiveis
        │   ├── get-manifestacao-revisao.use-case.ts     # + anexosExcluiveis
        │   └── consulta-publica.use-case.ts             # marcos sem attachment_deleted
        └── test/
            ├── use-cases/delete-manifestacao-anexo.use-case.spec.ts
            ├── repository/tombstone-manifestacao-anexo.repository.spec.ts
            ├── repository/find-manifestacao-for-anexo-delete.repository.spec.ts
            └── lib/manifestacao-anexo-delete-policy.spec.ts

ci-client-v2/apps/web/src/modules/ouvidoria/
├── api/anexos.ts                             # + deleteManifestacaoAnexo; presign/link retornam anexoId real
├── api/anexos-mappers.ts                     # sem alteração de contrato de item
├── lib/manifestacao-detail-view.ts           # + anexosExcluiveis (default false)
├── lib/ouvidoria-errors.ts                   # CODE_SPECS dos 3 novos códigos
├── components/
│   ├── ManifestacaoAnexoItem.tsx             # item (link + botão Excluir) — reuso detalhe/assistente
│   ├── ConfirmDeleteAnexoDialog.tsx          # Dialog @ci/ui; foco inicial em Cancelar
│   └── AnexoUploadZone.tsx                   # usa ManifestacaoAnexoItem; ids reais; onDeleted
├── pages/ManifestacaoDetailPage.tsx          # card Anexos usa ManifestacaoAnexoItem
├── pages/ManifestacaoWizardPage.tsx          # RevisaoAnexos usa ManifestacaoAnexoItem
└── __tests__/ ManifestacaoAnexoItem.test.tsx · ConfirmDeleteAnexoDialog.test.tsx · anexos-api.delete.test.ts · manifestacao-detail-view.anexos.test.ts
```

**Structure Decision**: Segue o layout canônico por módulo (`repository/` + `use-cases/` + controller/schemas únicos) e o espelho de domínio no client (`modules/ouvidoria/`). Nenhum módulo novo; nenhuma camada nova.

## Ordem de execução do use-case (resumo)

```
1. params (Zod)                                   → 400
2. manifestação {id, tenantId, deletedAt:null}    → 404 OUVIDORIA_NOT_FOUND
3. ManifestacaoAccessService.assertForUser        → 403 OUVIDORIA_ACCESS_DENIED
4. anexo {id, manifestacaoId, tenantId} (inclui excluídos)
     ausente                                      → 404 OUVIDORIA_ANEXO_NOT_FOUND
     já excluído                                  → 200 { ok:true, alreadyDeleted:true }
5. isManifestacaoEncerrada(status)                → 409 OUVIDORIA_ANEXO_DELETE_CLOSED
6. kind=file e storageKey:
     validateTenantPath                           → falha ⇒ 500 ANEXO_DELETE_FAILED (log)
     outro anexo ativo com a mesma chave          → 409 OUVIDORIA_ANEXO_DELETE_BLOCKED
     storage.deleteObjectPermanently              → falha ⇒ 500 ANEXO_DELETE_FAILED (nada gravado)
7. $transaction: updateMany(where id,manifestacaoId,tenantId,deletedAt:null → tombstone)
     count===1 → cria evento attachment_deleted   count===0 → 200 alreadyDeleted:true
8. 200 { ok:true, alreadyDeleted:false }
```

## Matriz de testes (RED primeiro)

| Camada | Casos obrigatórios |
|---|---|
| Policy | rascunho/in_review/forwarding/answered ⇒ true; 3 encerradas ⇒ false |
| Use-case | sem acesso (403, nada chamado); manifestação de outro tenant/removida (404); anexo de outra manifestação (404); encerrada (409, storage não chamado); arquivo ⇒ storage antes do banco; link ⇒ storage **não** chamado; falha no storage ⇒ sem tombstone/evento; chave inválida de tenant ⇒ falha sem apagar; chave compartilhada ⇒ 409; já excluído ⇒ idempotente sem storage/evento; `count===0` ⇒ sem evento duplicado; admin_tenant ⇒ `deletedByUserId` ausente + actor id/role + rótulo no evento; upload não confirmado/objeto inexistente ⇒ sucesso |
| Repository | tombstone limpa `storageKey`/`externalUrl`; `where` contém `tenantId`+`deletedAt:null`; evento só com `count===1`; `findById` filtra tombstone |
| Storage | chave exata (não prefixo); versões + delete-markers; bucket sem versionamento (`VersionId` nulo); `HeadObject` ainda existe ⇒ erro; `AccessDenied`/retenção ⇒ erro; stub local; chave de outro tenant ⇒ recusa |
| Leitura | detalhe/revisão/export/documento sem tombstone (arquivo **e** link); consulta pública sem evento de exclusão |
| Client | botão só com `anexosExcluiveis`; Cancelar/Esc/clique fora não chamam API; confirmação chama 1× e desabilita; erro mantém item e mostra alerta; sucesso remove e recarrega; ids reais após upload; link e arquivo |

## Complexity Tracking

Sem violações da constitution — nada a justificar.
