# Research: Painel de Fiscalização — Ouvidoria (Jatobá)

**Feature**: 008-ouvidoria-jatoba-fiscalizacao · **Date**: 2026-06-19

## R1 — Regras de checagem determinísticas

**Decision**: Funções puras em `lib/checks/` — uma por domínio (deadline, forwarding, completeness, contact, evidence). Input: DTO in-memory da manifestação + eventos + anexos + SLA dias; output: `{ ruleId, label, status, tracePayload }`.

**Rationale**: FR-001/FR-013 exigem regras testáveis sem side effects. Espelha padrão `lib/aggregation/` da feature 007.

**Alternatives considered**:

- Regras inline nos use-cases → rejeitado (difícil unit test, viola SRP)
- Motor de regras genérico (JSON DSL) → rejeitado (over-engineering v1)

---

## R2 — Persistência de execuções

**Decision**: Tabelas `OuvidoriaFiscalizacaoRun`, `OuvidoriaFiscalizacaoResult`, `OuvidoriaFiscalizacaoCheck`, `OuvidoriaFiscalizacaoFinding` com JSON `tracePayload` em checks/findings.

**Rationale**: FR-005/FR-006/FR-010 exigem histórico rastreável e comparação temporal. JSON para passos de rastreio evita schema rígido.

**Alternatives considered**:

- Calcular sempre on-the-fly → rejeitado (spec exige persistência de runs)
- Snapshot só agregado sem checks → rejeitado (SC-003 exige rastreio por checagem)

---

## R3 — SLA por tipo de manifestação

**Decision**: Tabela `OuvidoriaFiscalizacaoSlaConfig` com `(tenantId, manifestacaoType)` unique + `daysLimit` Int. Seed defaults da spec na migration/seed; fallback em `sla-resolver.ts` se row ausente.

**Rationale**: FR-011; configurável por tenant sem campo manual por registro. Data limite = `confirmedAt` (primeiro status ≠ draft, usar `createdAt` pós-confirm ou campo `confirmedAt` derivado do evento `registration`).

**Alternatives considered**:

- JSON blob em `Tenant.settings` → rejeitado (menos queryável; tabela explícita facilita admin futuro)
- Reintroduzir `prazoResposta` em Manifestacao → rejeitado (Out of Scope spec 008)

**Proximidade Parcial**: `remainingDays / totalDays ≤ 0.20` e sem evento `response` → status `partial` na checagem deadline.

---

## R4 — Agregação de conformidade

**Decision**: `aggregate-conformity.ts` — ordem de severidade: `non_conforme` > `partial` > `pending` > `conforme`; retorna pior status entre checagens da execução.

**Rationale**: FR-014; mapeamento enum API → labels PT-BR no mapper.

---

## R5 — Job agendado

**Decision**: `@nestjs/schedule` `@Cron` diário (default 03:00 UTC, env `FISCALIZACAO_CRON`), origin `scheduled`, escopo tenant completo.

**Rationale**: FR-007; reutiliza infra 007; sem Redis/Bull.

**Teste sem banco extra**: unit mock de `RunFiscalizacaoUseCase`; fake timers no job spec.

---

## R6 — Throttling execução manual

**Decision**: Consultar último `Run` com `origin IN (on_demand, on_record)` nas últimas 60 min; retornar `429` código `FISCALIZACAO_THROTTLED`. Execução scoped a um registro **conta** no mesmo limite horário por tenant.

**Rationale**: FR-009; decisão do plano (Assumptions spec); simplicidade vs Redis.

**Alternatives considered**:

- Limite separado por registro → rejeitado (complexidade; usuário delegou "mesmo limite" no plan)

---

## R7 — Submódulo vs extensão de `ouvidoria`

**Decision**: `modules/ouvidoria-fiscalizacao/` — controller separado, rotas `/ouvidoria/fiscalizacao/*`, importado em `AppModule`.

**Rationale**: Domínio distinto (execução + questionários + SLA); mantém use-cases ouvidoria CRUD pequenos. Espelha 007.

---

## R8 — Questionários e banco de perguntas

**Decision**:

- `OuvidoriaFiscalizacaoQuestion` — banco por tenant (seed ouvidoria)
- `OuvidoriaFiscalizacaoQuestionnaire` — instância por manifestação; `audience` internal|external; `channel` portal|whatsapp|email; `flowState`
- `OuvidoriaFiscalizacaoQuestionnaireItem` — snapshot pergunta + ordem
- Respostas em `OuvidoriaFiscalizacaoAnswer`

**Rationale**: FR-018–FR-022; normalização vs JSON blob de perguntas.

**Elegibilidade externa**: `!isAnonymous && (replyEmail || mobilePhone || homePhone || businessPhone)`.

---

## R9 — Resposta externa tokenizada

**Decision**: `responseTokenHash` (bcrypt) + rota `@Public()` `GET/POST /public/ouvidoria/fiscalizacao/responder/:token` — padrão `ConsultaPublicaUseCase` (protocol + chave).

**Rationale**: FR-020; v1 sem SMTP/WhatsApp; equipe copia link gerado na UI.

**Alternatives considered**:

- JWT long-lived → rejeitado (revogação mais difícil; hash + lookup idêntico ao padrão ouvidoria)

---

## R10 — Client: página vs ScreenPage mock

**Decision**: `OuvidoriaAuditoriaPage` lazy; `OUVIDORIA_OVERRIDES['ouvidoria-auditoria']` em `router.tsx`; reutilizar layout visual de `JatobaFiscalPanel` com dados API.

**Rationale**: Espelha override `ouvidoria-insights` da 007.

---

## R11 — Rastreabilidade UI

**Decision**: `FiscalizacaoTraceSheet` dedicado (ou extensão de padrão shell) com títulos canônicos por `traceType`: `check` | `finding` | `question` | `record`. Sheet ~85vh.

**Rationale**: FR-015; regras-plataforma §1.7.

---

## R12 — Estratégia de testes (5 camadas)

**Decision**: Matriz idêntica à 007 — unit/component/contract/integration/e2e; sem Postgres de teste; MSW no client; Supertest + mocks na API.

**Rationale**: Requisito explícito do usuário + Constitution II.

**Alternatives considered**:

- Playwright → rejeitado v1 (sem tooling); jornada Vitest + RTL = E2E simulado
- Postgres ci_api_v2_test → rejeitado

---

## R13 — ConfirmedAt para SLA

**Decision**: Usar timestamp do evento `ManifestacaoEvento` tipo `registration` quando existir; fallback `Manifestacao.createdAt` para registros legados seed.

**Rationale**: Spec Assumptions: "data de confirmação"; evento `registration` é criado em `confirm-manifestacao`.

---

## R14 — Checagem tramitação

**Decision**:

- Status `forwarding` sem evento `forwarding` nos últimos N dias (default 14) → `partial`
- Evento `forwarding` com `destinoSetorId` null → `non_conforme`
- Encerrada/respondida com timeline coerente → `conforme`

**Rationale**: FR-013; regras determinísticas testáveis com fixtures de eventos.
