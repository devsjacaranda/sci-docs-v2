# Research: Fiscalização de Gestão — Gabinete (Jatobá)

**Feature**: 016-gabinete-fiscalizacao-integrada · **Date**: 2026-06-24

## R1 — Unidade fiscalizada: ato + cadastros órfãos

**Decision**: Duas fontes de registro na execução completa:

1. **Atos** (`CabinetDemanda`, status ≠ `draft`) — checagens do ato + agregação worst-of com protocolo e controles **vinculados** (`cabinetId` = ato.id).
2. **Cadastros órfãos** — registros com `cabinetId IS NULL` e `deletedAt IS NULL` em: `CabinetProtocolo`, `CabinetControleNumerico`, `CabinetControleNotificacao`, `CabinetControleAutoInfracao`, `CabinetDocumentoTramitado` — cada um gera **resultado independente** na execução.

**Rationale**: FR-021; decisão de produto na spec. Evita duplicar: cadastro vinculado a ato **não** entra como órfão na mesma execução.

**Alternatives considered**:

- Só atos (012 MVP) → rejeitado (spec 016)
- Fiscalizar cada entidade sempre separada → rejeitado (perde agregação ato + controles)

---

## R2 — Schema Result: entityType + entityId

**Decision**: Adicionar enum `FiscalizedEntityType` ∈ `{ cabinet_demanda, protocolo, controle_numerico, notificacao, auto_infracao, documento_tramitado }`. Em `GabineteFiscalizacaoResult`: `entityType`, `entityId` (UUID), `demandaId` opcional (preenchido quando `entityType = cabinet_demanda` ou quando resultado agregado de ato). Unique `(runId, entityType, entityId)`.

**Rationale**: FR-006; persistência histórica para órfãos sem FK rígida a `CabinetDemanda`.

**Alternatives considered**:

- Só `demandaId` + JSON metadata → rejeitado (FK obrigatória impede órfãos)
- Tabela Result por tipo → rejeitado (over-engineering)

---

## R3 — Regras de checagem (lib/checks/)

**Decision**: Funções puras espelhando 008 + extensões Gabinete:

| Arquivo | ruleId prefix | Escopo |
|---------|---------------|--------|
| `deadline.rules.ts` | JAT-GAB-PRZ | Prazo concessionária (ato) |
| `forwarding.rules.ts` | JAT-GAB-TRM | Encaminhamento pendente (ato) |
| `completeness.rules.ts` | JAT-GAB-CMP | Assunto/descrição (ato) |
| `evidence.rules.ts` | JAT-GAB-EVD | Anexos não confirmados (ato) |
| `protocol.rules.ts` | JAT-GAB-PRT | Vínculo + completude protocolo |
| `controle-numerico.rules.ts` | JAT-GAB-CNU | Número/data por tipo |
| `notificacao.rules.ts` | JAT-GAB-NOT | Prazo + completude termo/destinatário |
| `auto-infracao.rules.ts` | JAT-GAB-AUT | Prazo + setor emissor |
| `pairing.rules.ts` | JAT-GAB-PAR | Pareamento groupId notif/auto |
| `documento-tramitado.rules.ts` | JAT-GAB-DTR | Prazo/observação vencidos |

**Agregação ato**: `aggregate-ato-with-links.ts` — worst-of entre checagens do ato, protocolo vinculado e cada controle vinculado (controles checados individualmente, pior prevalece).

**Rationale**: 012 research R9; FR-011–FR-020.

**Status avançados exigem protocolo**: `in_analysis`, `in_transit`, `awaiting_concessionaire`, `finished`, `archived`.

**Alternatives considered**:

- Monolito `controls.rules.ts` → rejeitado (difícil testar por domínio)

---

## R4 — Carga de dados para fiscalização

**Decision**:

- `LoadAtosForFiscalizacaoRepository` — `findMany` atos não-draft com `include`: `protocolo`, `controlesNumericos`, `controlesNotificacao`, `controlesAutoInfracao`, `documentosTramitados`, `eventos`, `anexos`.
- `LoadOrphanCadastrosForFiscalizacaoRepository` — 5 queries paralelas (ou uma union tipada) filtrando `cabinetId: null`, `deletedAt: null`.
- Para pareamento: carregar mapa `groupId → { notificacoes[], autos[] }` por tenant na execução (in-memory).

**Rationale**: FR-001; performance aceitável para escala SC-002 (≤700 registros).

---

## R5 — Persistência, job, throttle

**Decision**: Reutilizar padrão 008 inalterado:

- Job `@Cron` diário, origin `scheduled`
- Throttle 1h por tenant para `on_demand` e `on_record`
- `aggregate-conformity.ts` existente
- `scopedDemandaId` em Run para execução por ato

**Rationale**: Código já presente em `gabinete-fiscalizacao`; estender escopo do use-case.

---

## R6 — Questionários internos (sem externo)

**Decision**: Endpoints espelhando ouvidoria **exceto** rota pública e audience external:

- `GET/POST/PATCH /gabinete/fiscalizacao/questions`
- `GET/POST /gabinete/fiscalizacao/questionnaires`
- `POST /gabinete/fiscalizacao/questionnaires/:id/respostas`
- Questionnaire: `audience = internal`, `channel = portal` fixos; `demandaId` ou `entityType`+`entityId` para órfãos (migration questionnaire)

**Rationale**: FR-025; Out of Scope spec — sem WhatsApp/token público Gabinete.

---

## R7 — Seed perguntas Gabinete

**Decision**: `seed-fiscalizacao-questions-gabinete.ts` — 4–6 perguntas default `allowedAudience: internal`:

- Prazo concessionária registrado corretamente?
- Controles numéricos vinculados completos?
- Notificação/auto pareados quando aplicável?
- Documentos tramitados com setor informado?

Invocar em `seed-jacaranda-tenant.ts` (dívida T082 012).

**Rationale**: US7; separado de `seed-fiscalizacao-questions.ts` (ouvidoria).

---

## R8 — Client: reutilizar componentes Ouvidoria

**Decision**: `GabineteAuditoriaPage` importa `FiscalizacaoPanel`, `FiscalizacaoRunsHistoryPanel`, `FiscalizacaoTraceSheet` de `modules/ouvidoria/components/` com interface props:

```typescript
type FiscalizacaoModuleConfig = {
  moduleId: 'gabinete';
  title: 'Fiscalização de Gestão — Gabinete';
  entityColumnLabel: 'Ato';
  runButtonLabel: 'Fiscalizar atos';
  apiBasePath: '/gabinete/fiscalizacao';
};
```

Extrair props opcionais nos componentes ouvidoria (refactor mínimo) se hardcoded "manifestação" hoje.

**Rationale**: Constitution V escopo mínimo; 008 já provou componentes; evita duplicar ~800 LOC.

**Alternatives considered**:

- Mover para `modules/shared/` → adiado (refactor opcional pós-MVP)
- Copiar componentes para gabinete/ → rejeitado (duplicação)

---

## R9 — Card contextual no detalhe do ato

**Decision**: `GabineteFiscalizacaoRecordCard` em `modules/gabinete/components/` — wrapper fino sobre padrão ouvidoria `FiscalizacaoRecordCard` (criar em ouvidoria se ausente) ou inline no `GabineteAtoDetailPage`. Consome `GET /gabinete/fiscalizacao/atos/:cabinetId` (alias `demandas/:id`).

**Rationale**: FR-027; US8.

---

## R10 — Identificadores UI para órfãos

**Decision**: Coluna **Ato** no histórico exibe:

| entityType | Label UI |
|------------|----------|
| `cabinet_demanda` | `{protocolNumber}` |
| `protocolo` | `Cadastro órfão — Protocolo {id curto}` |
| `controle_numerico` | `Cadastro órfão — Controle numérico` |
| `notificacao` | `Cadastro órfão — Notificação` |
| `auto_infracao` | `Cadastro órfão — Auto de infração` |
| `documento_tramitado` | `Cadastro órfão — Documento tramitado` |

**Rationale**: US9 acceptance; mapper PT-BR.

---

## R11 — Testes sem Postgres dedicado

**Decision**: Mesma estratégia 008/012 — Jest unit para rules; fixtures JSON `test/fixtures/`; Supertest e2e com deps mockadas; Vitest + MSW handlers `gabinete-fiscalizacao.ts`.

**Rationale**: Constitution II; CI sem banco extra.

---

## Referências

- [008 research](../008-ouvidoria-jatoba-fiscalizacao/research.md) — padrões base
- [012 research R9](../012-desmock-gabinete/research.md) — checagens protocol + controls planejadas
- Código vivo: `ci-api-v2/src/modules/gabinete-fiscalizacao/`, `ci-api-v2/src/modules/ouvidoria-fiscalizacao/`
