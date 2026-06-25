# Research: Desmock Gabinete (012)

**Feature**: 012-desmock-gabinete · **Date**: 2026-06-23

## R1 — Nomenclatura API e módulo NestJS

**Decision**: Slug de domínio `gabinete`; pasta `ci-api-v2/src/modules/gabinete/`; rotas REST prefix `/gabinete/*`; `@RequireModulo('gabinete')`.

**Rationale**: Alinha com `ModuloSlug.gabinete` existente, navegação client e guards já registrados em `ci-api-v2/src/common/constants/modulos.ts`.

**Alternatives considered**: `cabinet` (inglês) — rejeitado por divergir do slug canônico de produto e permissões.

---

## R2 — Modelo unificado Documento Tramitado por Setor

**Decision**: Uma entidade Prisma `CabinetDocumentoTramitado` com FK obrigatória `setorId` → `Setor`; campos comuns opcionais unificados (qtde, datas, protocolo, SIGED, documento, requerente, assunto, prazo/observacao).

**Rationale**: Elimina 13 tabelas legadas v1 (DEGPLAN, DEAE, …); setor cadastrado substitui sigla hardcoded.

**Alternatives considered**: Tabela por setor v1 — rejeitado (débito técnico explícito do stakeholder).

---

## R3 — Controle Numérico unificado por tipo

**Decision**: Uma entidade `CabinetControleNumerico` com enum `CabinetControleNumericoTipo` ∈ {oficio, oficio_circular, portaria, memorando, memorando_circular, resolucao}; todos os campos v1 opcionais em colunas flat (numero, data, orgao, enderecado, historico, assunto, solicitante, formalizadoPor, minutadoPor).

**Rationale**: v1 tinha 7 tabelas com overlap; UI exibe subset por tipo via mapper.

**Alternatives considered**: 7 modelos Prisma — rejeitado por duplicação sem ganho.

---

## R4 — Anexos Wasabi (reuso StorageService)

**Decision**: Extrair `StorageService` de `ouvidoria` para `ci-api-v2/src/modules/shared/storage/` (ou `common/storage/`); entidades `CabinetDemandaAnexo` e `CabinetProtocoloAnexo` com fluxo presign → upload direto → confirm; `entityType` ∈ {`cabinet_demanda`, `cabinet_protocolo`}.

**Rationale**: FR-004; padrão comprovado em 003-ouvidoria; evita proxy binário.

**Alternatives considered**: JSON `anexos` na Demanda (v1) — rejeitado; Ouvidoria v2 já migrou para tabela + Wasabi.

---

## R5 — Sequência de protocolo da Demanda

**Decision**: Tabela `CabinetDemandaSequence` (tenantId + year → nextNumber); formato `GAB-{YYYY}-{NNNN}` (configurável por mapper).

**Rationale**: Mesmo padrão atômico de `ManifestacaoSequence` (003 R2); unicidade `(tenantId, protocolNumber)`.

**Alternatives considered**: UUID como protocolo — rejeitado; operação AGEMAN espera numeração legível.

---

## R6 — Timeline e encaminhamentos (stub Tramitar)

**Decision**: `CabinetDemandaEvento` para timeline (created, updated, forwarded, status_changed); ação **Tramitar** append em `encaminhamentos` JSON **e** cria evento `forwarded`; **não** integra módulo Tramitação.

**Rationale**: Spec FR-007; JSON preserva compatibilidade v1; eventos alimentam UI como Ouvidoria.

**Alternatives considered**: Só JSON — rejeitado; timeline inconsistente com resto da plataforma.

---

## R7 — Status de fluxo (enum v1 simplificado)

**Decision**: Enum `CabinetDemandaStatus` espelhando v1 essencial: `draft`, `awaiting_receipt`, `received`, `in_analysis`, `in_transit`, `awaiting_concessionaire`, `finished`, `archived`, `returned_ouvidoria`, `returned_gabinete` (+ subset operacional para badges).

**Rationale**: Assumption spec; transições validadas em use-case; default `received` ou `draft` conforme confirmar no create.

**Alternatives considered**: Enum mínimo (3 valores) — rejeitado; perde semântica AGEMAN.

---

## R8 — Submódulos de licença (espelho Ouvidoria)

**Decision**: Três módulos NestJS separados:

| Licença | Módulo API | Prefixo REST |
|---------|------------|--------------|
| Jatobá | `gabinete-fiscalizacao` | `/gabinete/fiscalizacao/*` |
| Carvalho | `gabinete-maturidade` | `/gabinete/maturidade/*` |
| Cedro | `gabinete-insights` | `/gabinete/insights/*` |

**Rationale**: Padrão 007/008/009; isolamento de regras; guards `@RequireLicenca('jatoba'|'carvalho'|'cedro')`.

**Alternatives considered**: Módulo monolítico — rejeitado; viola escopo mínimo e dificulta manutenção.

---

## R9 — Checagens Jatobá Gabinete

**Decision**: Regras puras em `gabinete-fiscalizacao/lib/checks/`: `deadline.rules`, `completeness.rules`, `forwarding.rules`, `protocol.rules`, `controls.rules`; fonte = `CabinetDemanda` + eventos + controles vinculados.

**Rationale**: Domínio distinto de manifestação; reuso de `aggregate-conformity`, throttle, job schedule.

**Alternatives considered**: Reutilizar módulo ouvidoria-fiscalizacao — rejeitado; entidade e regras diferentes.

---

## R10 — Insights Cedro Gabinete

**Decision**: Entidades `GabineteInsightBatch`, `GabineteInsight`, `GabineteInsightEvidence`; regras determinísticas em `lib/aggregation/` (volume status, encaminhamentos, origem, notificações/autos, docs tramitados por setor); **sem** NLP/LLM.

**Rationale**: 007 R-pattern; fonte *Dados internos — Gabinete*.

---

## R11 — Maturidade Carvalho Gabinete

**Decision**: Reutilizar padrão `ouvidoria-maturidade`: perguntas seed `gabinete`, autoavaliação por período, score híbrido R-50, planos de ação, indicadores operacionais derivados de demandas.

**Rationale**: 009 spec; fórmula canônica já implementada.

---

## R12 — Client module layout

**Decision**: `ci-client-v2/apps/web/src/modules/gabinete/` espelhando `ouvidoria/`: `pages/`, `components/`, `api/`, `fixtures/`; rotas lazy em `App.tsx`; desmock `ScreenPage` para `gabinete-*` screens; paths `/gabinete/demandas/*` substituem `/gabinete/atos/*`.

**Rationale**: Constitution V; referência viva ouvidoria.

---

## R13 — Dashboard KPIs

**Decision**: Endpoint `GET /gabinete/dashboard` retorna agregações server-side (counts by status, pending, finished, transit, period filter); gráficos Nivo no client consomem DTO.

**Rationale**: Evita calcular KPIs no client a partir de lista paginada incompleta.

---

## R14 — Produto: licencas-canonicas.md

**Decision**: Atualizar seção **Gabinete do Presidente → Base** de *atos normativos* para *demandas e protocolos (CRUD), controles opcionais, timeline, encaminhamento stub*.

**Rationale**: Assumption spec; alinhamento stakeholder.

---

## R15 — Testes sem Postgres dedicado

**Decision**: Mesma estratégia 008: Jest unit/integration/e2e com Prisma mock; Vitest + MSW no client; fixtures JSON em `test/fixtures/`.

**Rationale**: Constitution II; CI sem banco extra.

---

## Referências v1 (campos)

Campos mapeados de:

- `protocolo.prisma` → `CabinetProtocolo`
- `demanda.prisma` → `CabinetDemanda`
- `documento-tramitado.prisma` → `CabinetDocumentoTramitado` (unificado)
- `notificacao-autos-infracao.prisma` → `CabinetControleNotificacao`, `CabinetControleAutoInfracao`
- `controle-numerico-documentos-ageman.prisma` → `CabinetControleNumerico`
