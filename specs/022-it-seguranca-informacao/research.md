# Research: Módulo IT — Segurança da Informação

**Feature**: 022-it-seguranca-informacao · **Date**: 2026-06-25

## R1 — Registro do 9º módulo (`it`)

**Decision**: Adicionar slug `it` em `ci-api-v2/src/common/constants/modulos.ts`, enum `ModuloSlug` em `prisma/schema/enums.prisma`, relations em `tenant.prisma`, seed `ModuloSetor` para setor TI Jacaranda. Client: bloco em `navigation.ts`, `screens.ts`, `license-screens.ts` (`modules[]`), `IT_OVERRIDES` em `router.tsx`, `moduleLicenseConfig.it` em `packages/domain`. Atualizar `.cursor/docs/regras-plataforma.md` §3.

**Rationale**: FR-001; spec assumption "novo módulo"; paridade com `compras`/`gabinete`.

**Alternatives considered**:

- Sub-área Global → rejeitado (decisão produto: 9º módulo)
- Slug `seguranca-informacao` → rejeitado (spec define `it`; paths mais curtos)

---

## R2 — Arquitetura API: 4 módulos Nest

**Decision**: `it`, `it-insights`, `it-fiscalizacao`, `it-maturidade` — imports separados em `app.module.ts`. Prefixos REST: `it`, `it/insights`, `it/fiscalizacao`, `it/maturidade`.

**Rationale**: Padrão canônico Compras; fronteiras de licença por controller.

**Alternatives considered**:

- Monolito único `it.module.ts` → rejeitado (mistura guards Cedro/Jatobá/Carvalho)
- Subpastas sem módulos Nest → rejeitado (viola Constitution V)

---

## R3 — Trilha de auditoria imutável (escopo IT)

**Decision**: Model `ItAuditTrail` em `it-fiscalizacao.prisma` — campos: `tenantId`, `userId`, `action` (create|read|update|delete), `ipAddress`, `entityType`, `entityId`, `payloadSummary` (JSON opcional), `createdAt`. Repository **append-only**: expõe `create` e `findMany` — **sem** `update`/`delete`. Chamado explicitamente nos use-cases IT (incluindo GET de dados sensíveis). Painel Jatobá: `GET /it/fiscalizacao/audit-trail` paginado.

**Rationale**: FR-020–021; spec decision "apenas módulo IT"; interceptor global (`audit.interceptor.ts`) não cobre reads, IP nem imutabilidade.

**Alternatives considered**:

- Reutilizar só `AuditLog` global → rejeitado (permite delete lógico; sem escopo IT; sem read)
- Event sourcing completo → rejeitado (over-engineering)

---

## R4 — PDF notificação ANPD

**Decision**: Adicionar `pdf-lib` em `ci-api-v2`. Template ANPD como layout programático em `lib/anpd-pdf-template.ts`; endpoint `POST /it/fiscalizacao/incidentes/:id/anpd` retorna `application/pdf`. Campos preenchidos do incidente + ativo vinculado; campos ausentes editáveis no client antes de gerar (US10).

**Rationale**: SC-009 exige PDF real; monorepo hoje só exporta HTML+print (maturidade).

**Alternatives considered**:

- HTML + `window.print()` → rejeitado (não cumpre spec literal)
- Serviço externo (DocRaptor) → rejeitado (dependência SaaS desnecessária)

---

## R5 — Workflow auditoria de backup (cron)

**Decision**: Job `BackupAuditScheduledJob` em `it-fiscalizacao/jobs/`:

- Cron: `0 6 ${BACKUP_AUDIT_DAY:-5} * *` (dia 5 às 06:00 UTC, env `BACKUP_AUDIT_DAY`)
- Por tenant: servidores (`ItAsset.type=server`) elegíveis → `backupAuditStatus=alerta`
- Job D+1 (`BackupAuditOverdueJob`): sem evidência válida → `vermelho` + `NotifySecretaryUseCase` (in-app notification reutilizando padrão existente)
- Evidência: `ItBackupEvidence` com `backupSizeBytes>0`, `restoreDate`, `logStorageKey` (presign upload)

**Rationale**: FR-017–019; paridade `RunFiscalizacaoScheduledJob`; config dia X via env/tenant config.

**Alternatives considered**:

- Cron diário checando dia → rejeitado (menos previsível)
- Status só em run Jatobá sem campo no ativo → rejeitado (Base precisa status operacional visível)

---

## R6 — Classificador LGPD Cedro (read-only + apply)

**Decision**:

1. Cedro: `POST /it/insights/lgpd/classify/:assetId` → varre `ItDataDictionary` por termos de `ItLgpdSensitiveTerm` (seed) → persiste `ItInsight` tipo `lgpd_classification` com recomendação — **não** altera `ItAsset.containsSensitiveData`
2. Base: `POST /it/ativos/:id/apply-sensitive-flag` → usuário confirma → seta flag + audit trail

**Rationale**: FR-013–014; decisão produto Cedro recomenda, usuário confirma (R-21).

**Alternatives considered**:

- Flag automática pelo insight → rejeitado (viola R-21)
- Só client-side → rejeitado (sem persistência de insight Cedro)

---

## R7 — Análise de configurações (regex)

**Decision**: `lib/config-scan.ts` — lê texto uploadado; aplica lista `ItSecurityPolicyPattern` (seed): `{ pattern: RegExp|string, label, impact: critical|high|medium, messageTemplate }`. Resultado em `ItConfigAnalysis` + `ItInsight` evidências. Upload via presign S3 (`StorageModule`), MIME `.txt/.json/.csv`, max 5MB.

**Rationale**: FR-011–012; spec descreve regex; reutiliza storage Compras/Ouvidoria.

**Alternatives considered**:

- Parser YAML completo → rejeitado (escopo v1: texto + regex)
- LLM análise → rejeitado (Out of Scope; determinismo TDD)

---

## R8 — Matriz de impacto de mudanças

**Decision**: Árvore de decisão JSON versionada em `lib/risk-matrix-tree.ts` (ou seed `ItRiskMatrixNode`). Input: `{ systemId?, accessType, mfaEnabled, dataNature }`. Output: `{ level: low|moderate|high|critical, score: 0-100, explanation, path: string[] }`. Endpoint stateless `POST /it/insights/risk-matrix/evaluate` — **não persiste** submissão na v1 (opcional log em `ItRiskMatrixEvaluation` para histórico consultivo).

**Rationale**: FR-015; cálculo instantâneo; TDD determinístico.

**Alternatives considered**:

- Formulário dinâmico por tenant → rejeitado (v2)
- Integração change management externo → rejeitado (Out of Scope)

---

## R9 — Ativos TI: tipos, vínculos, soft delete

**Decision**: Enum `ItAssetType`: `server | workstation | software_license | database | system`. Vínculos N:N via `ItAssetLink { fromAssetId, toAssetId, linkType: hosts|uses|depends_on }`. Soft delete: `deletedAt` + Prisma extension; restore zera `deletedAt`. Tags: `ItAssetTag` ou `tags String[]` — preferir join table `ItAssetTag` para filtros.

**Rationale**: FR-002–004; paridade `CompraDemanda.deletedAt`.

**Alternatives considered**:

- Single table inheritance → rejeitado (Prisma não suporta nativamente)
- Hard delete → rejeitado (FR-003)

---

## R10 — Incidentes e linhas de defesa

**Decision**: Enum `ItIncidentSeverity`: `low | moderate | critical`. Enum `ItIncidentStatus`: `open | resolved`. Enum `ItDefenseLine`: `antivirus_operator | internal_control | external_audit`. Resolução exige `resolvedAt`, `resolvedByDefenseLine`. Alimenta Carvalho `defense-lines.ts`.

**Rationale**: FR-005–006, FR-024; fórmula spec US11.

**Alternatives considered**:

- Status operacional misturado com Jatobá → rejeitado (R-33 regras-plataforma)

---

## R11 — Conformidade LGPD operacional (Base dashboard)

**Decision**: Percentual = `(sistemas com ≥1 categoria mapeada em ItOperatorTreatment) / (total ItAsset type=system)` × 100. Sistemas sem mapeamento = pendente na listagem conformidade.

**Rationale**: FR-007–008; spec SC-003.

**Alternatives considered**:

- Score por campo individual → rejeitado (spec: regras de campos preenchidos por sistema)

---

## R12 — Carvalho: aderência CIS/LGPD

**Decision**: Seed 20 controles (`ItFrameworkControl`): 10 CIS + 10 LGPD representativos. Status enum: `pending | active | completed`. Score = `(active + completed) / total × 100`. Gestor marca via `PATCH /it/maturidade/controls/:id`. Alertas Carvalho: &lt;70 critical, 70–79 attention (R-64/65).

**Rationale**: FR-026; assumption spec 20 controles.

**Alternatives considered**:

- Import catálogo CIS completo (~153) → rejeitado (v1 seed 20)

---

## R13 — Índice vulnerabilidade por secretaria

**Decision**: Agregar por `setorId` (reutilizar `Setor` existente como secretaria). Fórmula em `lib/vulnerability-index.ts`:

```
score = max(0, 10 - ((criticalOpen * 3) + (lowOpen * 1)) / max(1, assetCount))
```

Ranking ascendente (menor = mais vulnerável). Secretarias sem ativos omitidas (edge case spec).

**Rationale**: FR-027; reutiliza cadastro setores.

**Alternatives considered**:

- Nova entidade Secretaria → rejeitado (duplicaria Setor)

---

## R14 — Notificação Secretário (backup vermelho)

**Decision**: `NotifySecretaryUseCase` — resolve responsável via `Setor.responsavelUserId` ou role `secretario` no setor do servidor; persiste `Notification` in-app (reutilizar model existente se houver, senão `ItBackupAlertNotification`). E-mail opcional v2.

**Rationale**: FR-019; assumption "reutiliza infra existente".

**Alternatives considered**:

- E-mail obrigatório v1 → rejeitado (sem infra e-mail garantida no repo)

---

## R15 — Client UI e rotas

**Decision**: Rotas lazy em `IT_OVERRIDES`. Ordem lista §4 regras-plataforma. Menu ⋮ `TableRowActionsMenu`. Fiscalização reutiliza `FiscalizacaoPanel` adaptado. Maturidade: Nivo pie (linhas defesa) + bar (vulnerabilidade). Insights: upload + cards insight com *Aplicar classificação* redirecionando action Base.

**Rationale**: FR-009–010, FR-030; paridade Compras/Ouvidoria.

**Alternatives considered**:

- Mock prolongado → rejeitado (spec exige REST real)
