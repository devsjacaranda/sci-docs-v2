# Research: Documentos confidenciais na Tramitação

**Feature**: 033-tramitacao-docs-confidenciais  
**Date**: 2026-07-03

## R1 — Upload de anexos (baseline)

**Decision**: Implementar fluxo presign → upload Wasabi → confirm reutilizando `StorageService` e constantes de `ouvidoria-anexo.constants.ts` (30 MB, MIME allowlist), com prefixo de storage `tramitacao`.

**Rationale**: Schema `TramitacaoDemandaAnexo` já existe mas sem use cases. Gabinete (`demanda-anexo.use-case.ts`) e Ouvidoria são referências maduras; contrato 014 já documenta rotas `/tramitacao/demandas/:id/anexos/presign|confirm`.

**Alternatives considered**:
- *Concluir spec 014 separadamente primeiro* — rejeitado; stakeholder confirmou upload + confidencialidade na mesma entrega 033.
- *Upload inline no body create* — rejeitado; inconsistente com padrão presigned do monorepo.

## R2 — Modelo de ACL confidencial

**Decision**: Flag `isConfidential` em `TramitacaoDemandaAnexo` + tabela junction `TramitacaoDemandaAnexoAccess` (`anexoId`, `userId`, `sectorId`) com unique `(anexoId, userId)`.

**Rationale**: ACL por anexo (não por demanda); suporta multi-setor/multi-usuário; setor armazenado para auditoria e validação de que usuário pertence ao setor no momento da concessão. Autor (`uploadedByUserId` + actor payload) e `admin_tenant` bypassam junction em runtime.

**Alternatives considered**:
- *JSON array de userIds no anexo* — rejeitado; difícil indexar, validar FK e consultar em download.
- *ACL por evento/demanda* — rejeitado; spec exige granularidade por documento com mix público/confidencial na mesma thread.

## R3 — Momento de vincular anexo ao evento

**Decision**: Confirm de anexo recebe `eventoId` opcional; quando ausente, vincula ao último evento mutável ou evento criado na mesma transação (create/reply/forward). Compose: criar demanda → presign/confirm anexos com `eventoId` do evento `created`.

**Rationale**: Schema já tem `eventoId` em `TramitacaoDemandaAnexo`; timeline exibe anexos por evento (FR-003).

**Alternatives considered**:
- *Anexos só no nível demanda* — rejeitado; viola FR-003 e UX de timeline.

## R4 — Resposta de detalhe para não autorizados

**Decision**: Mapper retorna `accessLevel: 'full' | 'placeholder'` por anexo. Placeholder inclui `id`, `kind`, `isConfidential: true`, `fileName` ou `title` genérico ("Documento confidencial"), **sem** `storageKey`, `url`, `downloadUrl`.

**Rationale**: Alinhado à decisão de produto — usuário sabe que existe documento restrito sem vazar conteúdo ou URL assinada.

**Alternatives considered**:
- *Omitir anexo da lista* — rejeitado pelo stakeholder.
- *Contagem agregada só* — rejeitado.

## R5 — Download / presign GET

**Decision**: Nova rota `GET /tramitacao/demandas/:id/anexos/:anexoId/download` (ou presign download) com guard `assertAnexoAccess(actor, anexo)` antes de gerar URL.

**Rationale**: Impede bypass via URL direta se cliente vazar ID; centraliza ACL server-side.

**Alternatives considered**:
- *URL no detail para todos* — rejeitado; viola SC-002.

## R6 — Fluxo UI confidencialidade

**Decision**: Componente `TramitacaoAnexoUploadZone` com toggle confidencial por item staged; ao marcar, `ConfidentialAccessPicker` (setor multi + usuários por setor via `fetchSetores` + `fetchUsers` filtrado por setor). Estado local até confirm; ACL enviada no body de `confirm` e `add-link`.

**Rationale**: Espelha exemplo do stakeholder (anexou → marcou setor → usuários → outro setor). Reusa APIs de setor/usuário já usadas em `TramitacaoInboxWorkspace`.

**Alternatives considered**:
- *Modal pós-upload* — rejeitado; pior UX para múltiplos anexos com regras distintas.
- *Limitar a participantes da thread na caixa pessoal* — rejeitado; stakeholder escolheu fluxo setor→usuários igual ao setorial.

## R7 — Promoção pessoal→setor e encaminhamento

**Decision**: Nenhuma mutação de `TramitacaoDemandaAnexoAccess` em forward/promote; ACL imutável após confirm (salvo autor/admin). Novos anexos em reply/forward trazem ACL própria no confirm.

**Rationale**: FR-011, FR-012, FR-013 e decisão "mantém ACL" na promoção.

**Alternatives considered**:
- *Reconfigurar ACL na promoção* — rejeitado pelo stakeholder.
- *Expandir ao setor destino* — rejeitado.

## R8 — uploadedByUserId e admin_tenant

**Decision**: `uploadedByUserId String?` + actor em payload de evento quando admin; ACL check inclui `uploadedByUserId === actor.userId` OU actor em `TramitacaoDemandaAnexoAccess` OU `actorRole === admin_tenant`.

**Rationale**: Rule `admin-tenant-user-fk.mdc`; autor sempre vê (FR-010).

## R9 — Validação Zod ACL

**Decision**: Schema `confidentialAccessSchema = z.array(z.object({ sectorId: z.string().uuid(), userIds: z.array(z.string().uuid()).min(1) })).min(1)` obrigatório quando `isConfidential: true` no confirm/add-link.

**Rationale**: FR-005/006 — ao menos um usuário por setor; server valida que cada `userId` pertence ao `sectorId` e está ativo.
