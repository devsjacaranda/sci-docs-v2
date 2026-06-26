# Research: Purchasing — CRUD de Demandas e Artefatos

**Feature**: 018-purchasing-crud · **Date**: 2026-06-25

## R1 — Greenfield vs mocks existentes

**Decision**: Implementação **100% greenfield** — novo `compras.prisma`, módulo `ci-api-v2/src/modules/compras/` e `ci-client-v2/apps/web/src/modules/compras/`. Substituir rotas mock de `screens.ts` por páginas reais registradas em `router.tsx`.

**Rationale**: Não há model Prisma, endpoint nem página real; mocks usam paths divergentes da spec (`/compras/demandas/*` vs `/compras`, `/compras/novo`, `/compras/:id`).

**Alternatives considered**:

- Evoluir mocks `ScreenPage` — rejeitado: spec exige rotas canônicas e hub quebra-cabeça
- Módulo API `purchasing` — rejeitado: vocabulário canônico do repo é `compras` (`ModuloSlug.compras`, CONTEXT.md)

---

## R2 — Rotas client (spec vs mocks)

**Decision**: Adotar **rotas da spec 018** exclusivamente:

| Rota | Página |
|------|--------|
| `/compras` | Listagem demandas + modal PCAs |
| `/compras/novo` | Criar demanda |
| `/compras/:demandaId` | Hub quebra-cabeça |
| `/compras/:demandaId/dfd` … `/parecer` | 7 sub-rotas de artefatos |

PCA **sem rotas dedicadas** — gestão via `Sheet`/`Dialog` na listagem (FR-020).

**Rationale**: FR-001, FR-006, FR-008, FR-020; evita fragmentação de navegação.

**Alternatives considered**:

- Manter `/compras/pca/*` dos mocks — rejeitado: fora de escopo da spec
- Dashboard `/compras/dashboard` — rejeitado: não consta na spec 018 (fora de escopo)

---

## R3 — Status e progresso derivados (sem coluna persistida)

**Decision**: Entidade `CompraDemanda` **sem** coluna `status` nem flags de progresso. Derivação centralizada em `compras.mapper.ts`:

| Métrica | Regra |
|---------|-------|
| Artefato **Preenchido** | Registro 1:1 existe **e** campos obrigatórios completos |
| ETP **Dispensado** | `dispensado=true` + `motivoDispensa` preenchido → conta como satisfeito |
| Análise Riscos | Satisfeito apenas se `riscos.length >= 1` |
| **Progresso** | `{satisfied}/{7}` — ex.: `3/7 preenchidos` |
| **Status demanda** | `rascunho` (0 satisfeitos) · `em_andamento` (1–6) · `concluido` (7) |

Listagem com filtro por status: repository calcula via subconsultas/joins (ou CTE) — **sem** materializar status.

**Rationale**: FR-017, FR-018, FR-019; spec proíbe flags boolean na entidade pai.

**Alternatives considered**:

- Coluna `status` atualizada no upsert — rejeitado: viola FR-017/018 (persistência manual)
- View materializada PostgreSQL — rejeitado: complexidade desnecessária para ≤500 demandas (SC-005)

---

## R4 — Numeração sequencial de demanda

**Decision**: Tabela `CompraDemandaSequence` com unique `(tenantId)` e campo `nextNumber`. Incremento atômico no `create-demanda` use-case (padrão `CabinetDemandaSequence`, **sem** campo `year`).

**Rationale**: Assumption spec — sequencial por tenant, sem reinício por exercício.

**Alternatives considered**:

- Sequência por PCA — rejeitado: spec não prevê
- Sequência anual (gabinete) — rejeitado: assumption explícita da spec

---

## R5 — Campos TR (Termo de Referência)

**Decision**: Campos mínimos alinhados à spec + mock + Art. 6 Lei 14.133/2021 (instrução processual):

| Campo EN | UI PT-BR | Obrigatório |
|----------|----------|-------------|
| `detailedObject` | Objeto detalhado | sim |
| `technicalSpecifications` | Especificações técnicas | sim |
| `acceptanceCriteria` | Critérios de aceitação | não |

**Rationale**: Spec cita TR sem FR detalhado; mock `compras-tr` define 3 campos; suficiente para CRUD e fiscalização futura (019).

**Alternatives considered**:

- TR completo (20+ campos normativos) — rejeitado: assumption spec delega detalhamento fino ao plan; escopo CRUD mínimo
- Apenas `detailedObject` — rejeitado: insuficiente para conformidade operacional

---

## R6 — Campos ETP (não dispensado)

**Decision**:

| Campo EN | UI PT-BR | Obrigatório (se não dispensado) |
|----------|----------|----------------------------------|
| `dispensado` | Dispensado | flag |
| `motivoDispensa` | Motivo da dispensa | sim se dispensado |
| `solutionDescription` | Descrição da solução | sim |
| `viabilityAnalysis` | Análise de viabilidade | sim |
| `costEstimate` | Estimativa de custos | não |

Confirmação ao marcar dispensado quando dados técnicos já existem (US-6 cenário 3) — dialog client-side; API aceita upsert substituindo conteúdo técnico.

**Rationale**: FR-011, US-6; mock `compras-etp` como base.

---

## R7 — Upload de comprovante

**Decision**: Reutilizar padrão **presign → upload S3/Wasabi → confirm** de Gabinete/Ouvidoria:

- `POST /compras/demandas/:id/{artefato}/comprovante/presign`
- `POST /compras/demandas/:id/{artefato}/comprovante/confirm`
- Campo `storageKey?` + `comprovanteFileName?` + `comprovanteMimeType?` em cada tabela de artefato
- Falha no upload **não** reverte campos estruturados já salvos (edge case spec)

**Rationale**: FR-016; infra existente em `StorageModule` + `buildStorageKey(tenantId, 'compras', demandaId, artefato)`.

**Alternatives considered**:

- Multipart no controller — rejeitado: fora do padrão do repo
- Tabela anexo separada — rejeitado: 1 comprovante opcional por artefato; colunas inline bastam

---

## R8 — Autorização e licenças

**Decision**: `@RequireModulo('compras')` na classe `ComprasController` — **sem** `@RequireLicenca` (FR-024 Base). Client: `licenses: ['base']` nos screens; rotas Jatobá/Cedro/Carvalho/Pau-Brasil **fora** desta entrega (FR-029).

**Rationale**: [licenca-contracts](../../../.cursor/skills/licenca-contracts/SKILL.md); tabela de fronteiras na spec.

**Alternatives considered**:

- Submódulos licenciados nesta feature — rejeitado: escopo 018 limita-se ao CRUD base

---

## R9 — Seed e provisionamento tenant

**Decision**: Estender `seed-jacaranda-tenant.ts`:

- Vincular `ModuloSlug.compras` ao setor **DEAE** (Departamento de Aquisições — nome alinhado ao plan draft)
- Criar 1–2 PCAs demo + 2–3 demandas parciais para quickstart

**Rationale**: Assumption spec — módulo provisionado; FR-030 isolamento testável com Jacaranda.

**Alternatives considered**:

- Seed vazio — rejeitado: quickstart e demos dependem de dados

---

## R10 — Vocabulário UI vs API

**Decision**:

| Camada | Termo |
|--------|-------|
| UI (PT-BR) | **demanda/demandas**, módulo **Compras** (FR-025, FR-026) |
| Prisma/API EN | `CompraDemanda`, `CompraPca`, prefixo `Compra*` |
| Rotas API | `/compras/*` |

**Rationale**: Evita colisão com `CabinetDemanda` (Gabinete); CONTEXT.md usa vocabulário por módulo.

---

## R11 — Exportação PDF

**Decision**: Rota `GET /compras/demandas/:id/relatorio` retorna **501** com body orientador; botão desabilitado no client (FR-028).

**Rationale**: Out of scope explícito; reserva contrato para entrega futura.

---

## R12 — Arquitetura API

**Decision**: Espelhar `gabinete/` — controller fino, `repository/` (1 op/arquivo), `use-cases/`, `compras.schemas.ts` (Zod), `compras.mapper.ts` (labels PT + checklist derivado).

**Rationale**: Constitution V; referência viva `ci-api-arquitetura`.

**Alternatives considered**:

- Service monolítico — rejeitado: contrário à arquitetura canônica
