# Research: Desmock Jurídico (012)

**Feature**: 012-desmock-juridico · **Date**: 2026-06-23

## R1 — Nomenclatura API e módulo NestJS

**Decision**: Slug `juridico`; pasta `ci-api-v2/src/modules/juridico/`; rotas REST prefix `/juridico/*`; `@RequireModulo('juridico')`.

**Rationale**: Alinha com `ModuloSlug.juridico`, navegação client (`/juridico/processos`) e seed DEJUR existente.

**Alternatives considered**: `legal` (inglês) — rejeitado por divergir do slug canônico de permissões.

---

## R2 — Entidade central `LegalProcess`

**Decision**: Modelo Prisma `LegalProcess` (API EN); UI PT-BR *Processo*; número interno `internalNumber` formato `JUR-{YYYY}-{NNNN}` via `LegalProcessSequence`.

**Rationale**: Padrão `Manifestacao` + `ManifestacaoSequence` (003 R2); imutabilidade pós-confirmação; `judicialNumber` opcional separado (CNJ).

**Alternatives considered**: Reutilizar nome `Processo` no Prisma — rejeitado (palavra reservada/confusão com processo OS).

---

## R3 — Wizard multi-etapa (client + API)

**Decision**:

- API: status `draft` até `POST /juridico/processos/:id/confirm`; partes/anexos editáveis em draft; confirmação gera `internalNumber` + evento `registration`.
- Client: 4 steps — **Dados** (tipo, identificação, partes, órgão, observações, prazo, valor, responsável) → **Anexos** → **Revisão** → **Confirmação**; state local + persist draft via PATCH entre steps.

**Rationale**: FR-001; espelha wizard Ouvidoria; copy de revisão canônica da spec.

**Alternatives considered**: Single-page form — rejeitado (spec exige wizard como ouvidoria).

---

## R4 — Partes estruturadas (tudo opcional)

**Decision**: Tabela `LegalProcessParty` com `role` ∈ {active, passive, other}, `personType` ∈ {individual, legal_entity, government_entity}, `name`, `document` (CPF/CNPJ texto), `addressId` FK opcional → `Address`.

**Rationale**: FR-006; inspiração PJe sem integração Receita/OAB; zero campos obrigatórios no cadastro.

**Resumo partes na lista**: concatenação dos primeiros nomes por polo (ex.: *Instituição x Fornecedor X*) — calculado no mapper, não coluna denormalizada.

---

## R5 — Órgão e juízo (campos flat no processo)

**Decision**: Colunas opcionais em `LegalProcess`: `sphere`, `courtOrAgency`, `districtOrSection`, `courtUnit` — sem tabela de catálogo externo.

**Rationale**: FR-008; simplicidade v1; Cedro pode agregar por `courtOrAgency`.

---

## R6 — Status operacional e prazo

**Decision**: Enum `LegalProcessStatus`: `draft`, `open`, `expiring`, `critical`, `completed`. Cálculo derivado:

- `critical`: `deadlineAt < now()` e status ≠ completed
- `expiring`: dias restantes ≤ 20% do intervalo `(confirmedAt → deadlineAt)` e não critical
- `open`: default pós-confirmação
- Recálculo em read/list (use-case) — **não** persistir `critical`/`expiring` como fonte única (evita drift)

**Rationale**: FR-016/FR-017; separação eixo operacional vs conformidade Jatobá.

---

## R7 — Anexos Wasabi

**Decision**: `LegalProcessAttachment` + fluxo presign → upload direto → confirm; `storageKey` pattern `{tenantId}/juridico/{processId}/{attachmentId}`; reutilizar/extrair `StorageService` para `modules/shared/storage/`.

**Rationale**: FR-011–FR-013; política MIME/tamanho idêntica à Ouvidoria (30 MB, extensões da spec).

**Alternatives considered**: JSON blob de anexos — rejeitado (padrão v2 comprovado).

---

## R8 — Submódulos de licença (espelho Ouvidoria)

**Decision**: Três módulos NestJS separados:

| Licença | Módulo API | Prefixo REST |
|---------|------------|--------------|
| Jatobá | `juridico-fiscalizacao` | `/juridico/fiscalizacao/*` |
| Cedro | `juridico-insights` | `/juridico/insights/*` |
| Carvalho | `juridico-maturidade` | `/juridico/maturidade/*` |

**Rationale**: Fronteiras de licença; copiar estrutura 007/008/009 substituindo `Manifestacao` → `LegalProcess`.

---

## R9 — Probabilidade de Perda (regras determinísticas)

**Decision**: Função pura `computeLossProbability(input) → { band, score, factors[] }` em `loss-probability.rules.ts`.

**Input DTO**:

| Campo | Origem |
|-------|--------|
| `type` | LegalProcess.type |
| `deadlineAt`, `confirmedAt` | processo |
| `operationalStatus` | derivado (open/expiring/critical/completed) |
| `attachmentCount`, `hasPdf` | anexos confirmados |
| `causeValue` | Decimal opcional |

**Pontuação de risco** (0–100, soma capped):

| Fator | Condição | Pontos |
|-------|----------|--------|
| Tipo base | judicial | +25 |
| Tipo base | administrative | +12 |
| Tipo base | advisory | +5 |
| Prazo | vencido (deadline < hoje) | +35 |
| Prazo | ≤ 3 dias úteis restantes | +25 |
| Prazo | ≤ 20% tempo restante | +12 |
| Status | critical (operacional) | +15 |
| Status | expiring | +8 |
| Status | completed | −30 (floor score 0) |
| Anexos | judicial/administrative e count = 0 | +15 |
| Anexos | hasPdf confirmed | −8 |
| Valor | causeValue ≥ R$ 500.000 | +15 |
| Valor | causeValue ≥ R$ 100.000 | +8 |

**Faixas**:

| Band EN | UI PT-BR | Score |
|---------|----------|-------|
| `low` | Baixa | 0–24 |
| `medium` | Média | 25–49 |
| `high` | Alta | 50–100 |
| `undetermined` | Indeterminada | tipo **e** prazo ausentes |

**Rationale**: Spec Assumptions; explicável no rastreio listando `factors[]` com pontos; limiares configuráveis futuro via tenant settings (v1: constantes no módulo).

**Alternatives considered**: Campo manual editável — rejeitado (stakeholder escolheu regras determinísticas).

---

## R10 — Checagens Jatobá específicas do Jurídico

**Decision**: Conjunto de checks (além de loss probability):

| slug | Regra resumida |
|------|----------------|
| `loss_probability` | R9 — band + trace |
| `process_deadline` | Prazo vencido sem evento `justification` → non_conforme |
| `cadastral_completeness` | judicial sem CNJ → partial; sem tipo → pending |
| `judicial_identification` | judicial + empty judicialNumber → partial |
| `attachments_evidence` | judicial sem PDF → partial/non_conforme conforme tipo |
| `parties_consistency` | polo ativo e passivo vazios → partial (nunca bloqueia cadastro) |

Agregação: pior status entre checks (`aggregate-conformity.ts` reutilizado).

---

## R11 — Persistência fiscalização

**Decision**: Tabelas `JuridicoFiscalizacaoRun`, `Result`, `Check`, `Finding`, `Question`, `Questionnaire`, `Answer` — prefixo `Juridico` para evitar colisão com Ouvidoria; JSON `tracePayload` + campo `lossProbabilityBand` em Result.

**Rationale**: Espelho 008; coluna Probabilidade de Perda no painel lê `Result.lossProbabilityBand`.

---

## R12 — Insights Cedro (agregadores)

**Decision**: Agregadores determinísticos em `lib/aggregation/`:

1. Volume por `type` e `sphere`
2. Concentração processos `critical` / `expiring`
3. Distribuição `lossProbabilityBand` (última fiscalização)
4. Top `courtOrAgency` por volume
5. Prazos críticos backlog (> 30 dias abertos)

Branding **Insights IA**; fonte API `internal_juridico`.

**Rationale**: FR-032/FR-033; sem NLP/LLM.

---

## R13 — Maturidade Carvalho

**Decision**: Espelho 009 — `JuridicoMaturidadeScore`, autoavaliação trimestral, planos ação; fórmula `round(0.6 × self + 0.4 × jatobaConformity)` por eixo; indicadores: volume processos, prazos críticos, conformidade legal (último run), pareceres/mês (eventos tipo `opinion`).

**Rationale**: FR-036/FR-037; reutilizar libs de score de ouvidoria-maturidade onde possível.

---

## R14 — Client overrides

**Decision**: `JURIDICO_OVERRIDES` em `router.tsx` para screenIds:

`juridico-dashboard`, `juridico-lista`, `juridico-novo`, `juridico-detalhes`, `juridico-editar`, `juridico-auditoria`, `juridico-insights`, `juridico-maturidade`

**Rationale**: Padrão `OUVIDORIA_OVERRIDES`; rotas já definidas em `screens.ts`.

---

## R15 — Throttling e jobs

**Decision**: Reutilizar padrões 007/008:

- Fiscalização manual: 1 run/tenant/hora (`429 FISCALIZACAO_THROTTLED`)
- Insights Consultar IA: 1/tenant/15min
- Cron diário 03:00 UTC (`JURIDICO_FISCALIZACAO_CRON`, `JURIDICO_INSIGHTS_CRON`)

**Teste**: fake timers + mocks — sem Redis.

---

## R16 — Questionários externos (Parte externa)

**Decision**: Elegibilidade externa: parte em polo com `name` + (`email` ou `phone` campo opcional em Party) OU responsável interno com contato — v1 simplificada: **email/phone** colunas opcionais em `LegalProcessParty`. Canal WhatsApp/E-mail metadata + token público `GET/POST /public/juridico/fiscalizacao/responder/:token`.

**Rationale**: FR-030; `externalLabel` canônico *Parte externa* em `licenses.ts`.

---

## R17 — Valor da causa e CNJ

**Decision**: `causeValue` Decimal(15,2) nullable; `judicialNumber` VarChar(25) nullable — validação Zod alerta formato CNJ (`^\d{7}-\d{2}\.\d{4}\.\d\.\d{2}\.\d{4}$`) mas **allow** confirm com warning flag `judicialNumberNeedsReview` boolean default false, set true se regex falhar.

**Rationale**: Edge case spec — alerta, não bloqueio.
