# Research: Desmock Tramitação (014)

**Feature**: 014-desmock-tramitacao · **Date**: 2026-06-24

## R1 — Slug e módulo aberto

**Decision**: Slug `tramitacao`; pasta `ci-api-v2/src/modules/tramitacao/`; rotas `/tramitacao/*`; `@RequireModulo('tramitacao')`; módulo em `OPEN_MODULES` — qualquer setor autenticado acessa, filtro inbox por setor ativo do JWT.

**Rationale**: `modulos.ts` já registra `tramitacao` em `OPEN_MODULES`; spec FR-024; inbox filtra por setor ativo sem bloquear acesso ao módulo.

**Alternatives considered**: Sem `@RequireModulo` — rejeitado; perde rastreabilidade de vínculo módulo↔setor em permissões futuras.

---

## R2 — Entidade central e linked record inline

**Decision**: Uma entidade `TramitacaoDemanda` com campos opcionais `sourceModule`, `sourceRecordId`, `sourceSnapshot` (JSON imutável). Origem genérica quando os três são null. Não criar tabela `LinkedRecord` separada.

**Rationale**: Spec Key Entities; snapshot é atributo da demanda; simplifica inbox unificada e fiscalização.

**Alternatives considered**: Tabela polimórfica `LinkedRecord` — rejeitado; overhead sem ganho (1:1 com demanda).

---

## R3 — Pastas inbox (derivadas, não persistidas)

**Decision**: Campo `folder` **não** persistido. Query deriva:

| Pasta | Regra (setor ativo S) |
|-------|------------------------|
| Recebidas | `currentSectorId = S` AND `status != archived` |
| Enviadas | `senderSectorId = S` AND `currentSectorId != S` OR primeira mensagem enviada por S |
| Arquivadas | `status = archived` AND (`currentSectorId = S` OR `senderSectorId = S`) |

Unread flag opcional v1: `lastReadAt` por usuário ou omitir (P2).

**Rationale**: Evita duplicar registros por pasta; alinha UX email-like do mock `TramitacaoInboxPanel`.

**Alternatives considered**: Coluna `folder` enum — rejeitado; inconsistente após encaminhamento (mesma demanda em múltiplas pastas).

---

## R4 — Sequência de protocolo

**Decision**: `TramitacaoDemandaSequence` (tenantId + year → nextNumber); formato `TRAM-{YYYY}-{NNNN}`; unique `(tenantId, protocolNumber)`.

**Rationale**: FR-002; padrão `CabinetDemandaSequence` / `ManifestacaoSequence`.

---

## R5 — Timeline e thread

**Decision**: `TramitacaoDemandaEvento` com types: `created`, `reply`, `forwarded`, `status_changed`, `archived`. Respostas criam evento `reply` com `body` em payload; thread = eventos ordenados por `createdAt`.

**Rationale**: Padrão `CabinetDemandaEvento` / `ManifestacaoEvento`; FR-006/FR-009.

**Alternatives considered**: Tabela `TramitacaoDemandaResposta` separada — rejeitado; duplica evento + resposta.

---

## R6 — Integração cross-módulo

**Decision**: `CreateLinkedDemandaUseCase` em `tramitacao` exportado via provider NestJS; módulos origem importam `TramitacaoModule` (forwardRef se necessário) e chamam com DTO:

```typescript
{ sourceModule, sourceRecordId, sourceSnapshot, senderSectorId, targetSectorId, subject, body?, deadline? }
```

Snapshot construído no módulo origem (mapper local) antes da chamada.

**Rationale**: FR-004/FR-020–022; evita HTTP interno; transação única tenant-scoped.

**Alternatives considered**: Endpoint público `POST /tramitacao/demandas/linked` só para integração — rejeitado para v1 interna; expõe superfície extra.

---

## R7 — Submódulos de licença

**Decision**: Quatro módulos NestJS:

| Licença | Módulo API | Prefixo REST |
|---------|------------|--------------|
| Base | `tramitacao` | `/tramitacao/*` |
| Jatobá | `tramitacao-fiscalizacao` | `/tramitacao/fiscalizacao/*` |
| Cedro | `tramitacao-insights` | `/tramitacao/insights/*` |
| Carvalho | `tramitacao-maturidade` | `/tramitacao/maturidade/*` |

**Rationale**: Padrão 007/008/009 e 012-gabinete/jurídico (R8).

---

## R8 — Checagens Jatobá Tramitação

**Decision**: Regras puras em `tramitacao-fiscalizacao/lib/checks/`:

| Check | Fonte | Achado típico |
|-------|-------|---------------|
| SLA prazo | `deadline` vs now, status não resolvido | `sla_exceeded` |
| Completude | subject, body, target sector | `incomplete_data` |
| Encaminhamento pendente | último evento `forwarded` sem `reply` em X dias | `forwarding_pending` |

Conformidade ∈ {conforme, non_conforme, partial, pending} — 4 status canônicos.

**Rationale**: FR-012/FR-013; distinto de status operacional Base.

---

## R9 — Insights Cedro Tramitação

**Decision**: Agregações determinísticas: tempo médio resposta por setor (gargalos), volume por `sourceModule` (incl. `generic`), tendência volume/resolutividade por período. Entidades `TramitacaoInsightBatch`, `TramitacaoInsight`, `TramitacaoInsightEvidence`.

**Rationale**: FR-015; padrão 007 Cedro.

---

## R10 — Maturidade Carvalho Tramitação

**Decision**: Score híbrido 60% autoavaliação + 40% Jatobá (fórmula R-50 ouvidoria); eixos seed `tramitacao`; planos de ação por eixo.

**Rationale**: FR-016/FR-018; padrão 009.

---

## R11 — Client: migrar shell → modules/tramitacao

**Decision**: Criar `modules/tramitacao/` espelhando `ouvidoria/`; reutilizar UX de `TramitacaoInboxPanel` migrando componentes; `router.tsx` overrides para `/tramitacao/*`; remover `tramitacao-mock.ts` e `TramitacaoInboxPanel` após paridade.

**Rationale**: Constitution V; spec 005 reservou `modules/tramitacao/` para fase API; mock types em `tramitacao-mock.ts` servem como referência UX.

**Alternatives considered**: Manter shell mock com MSW — rejeitado; desmock exige API real.

---

## R12 — SIGED no desmock

**Decision**: Integração SIGED real fora de escopo. Fixtures mock SIGED em shell **removidas** na migração; `sourceModule` futuro pode incluir `siged` sem implementação v1. Opcional: seed com `sourceModule=generic` apenas.

**Rationale**: Spec Assumptions; plano stakeholder.

---

## R13 — Encaminhamento e visibilidade histórica

**Decision**: `forward-demanda` atualiza `currentSectorId`, cria evento `forwarded` com `fromSectorId`, `toSectorId`, `notes`. Setores anteriores mantêm entrada em Enviadas/Arquivadas conforme regra R3; timeline completa visível a qualquer setor que abriu a demanda (tenant-scoped).

**Rationale**: FR-007/SC-010; encaminhamento circular permitido com auditoria em timeline.

---

## R14 — Edge cases resolvidos

| Edge case | Decisão v1 |
|-----------|------------|
| Setor destino inválido | 400 `INVALID_TARGET_SECTOR` |
| Registro origem deletado | Snapshot preservado; UI badge "origem removida" |
| Encaminhar arquivada | 409 `DEMANDA_ARCHIVED` |
| Compor para próprio setor | 400 `SAME_SECTOR` |
| Licença rebaixada | Dados Jatobá/Cedro/Carvalho persistidos; rotas 403; UI alertas |

---

## R15 — Testes sem Postgres dedicado

**Decision**: Idêntico 008/012: Jest + Prisma mock; Vitest + MSW; fixtures JSON; e2e Supertest.

**Rationale**: Constitution II.

---

## Referências

- Mock UX: `ci-client-v2/apps/web/src/modules/shell/data/tramitacao-mock.ts`
- Gabinete forward stub: `POST /gabinete/cabinets/:id/forward` (012)
- Ouvidoria encaminhar: `POST /ouvidoria/manifestacoes/:id/encaminhar` (003)
- Spec mock anterior: `005-tramitacao-siged-licencas` (substituída por esta entrega API)
