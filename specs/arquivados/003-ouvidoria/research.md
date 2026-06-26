# Research: Ouvidoria Interna

**Feature**: 003-ouvidoria  
**Date**: 2026-06-05

## R1 — Endereço centralizado (`Address`)

**Decision**: Tabela Prisma `Address` em schema dedicado `address.prisma`, escopo `tenantId`, referenciada por `Manifestacao.addressId` (opcional). Módulo NestJS `address` com use-cases mínimos (`create-address`, `find-address-by-id`); Ouvidoria não duplica campos de logradouro.

**Rationale**: FR-006 e CONTEXT.md exigem entidade global reutilizável. FK única evita drift entre módulos futuros (Patrimônio, Contratos).

**Alternatives considered**:

| Alternativa | Motivo de rejeição |
|-------------|-------------------|
| JSON `localDoFato` em `Manifestacao` | Viola FR-006; impede reuso |
| Tabela `ManifestacaoAddress` 1:1 | Duplica conceito; Address já é o agregado |
| Endereço embutido só na Ouvidoria | Contradiz decisão de plataforma |

---

## R2 — Geração de protocolo (`OUV-AAAA-NNNN`)

**Decision**: Tabela `ManifestacaoSequence` com PK composta `(tenantId, year)` e coluna `lastNumber`. Incremento atômico dentro de transação Prisma `$transaction` no use-case `confirm-manifestacao`; formato `OUV-{year}-{lastNumber.padStart(4,'0')}`.

**Rationale**: FR-009 exige unicidade sob concorrência (edge case spec). Sequência por tenant+ano alinha ao mock `OUV-2026-0138`.

**Alternatives considered**:

| Alternativa | Motivo de rejeição |
|-------------|-------------------|
| UUID como protocolo | Viola formato legível da spec |
| `MAX(protocolo)` scan | Race condition sob carga |
| Sequência global PostgreSQL | Menos legível; mistura tenants |

---

## R3 — Chave de consulta pública

**Decision**: Gerar chave alfanumérica 8–12 chars (`crypto.randomBytes` base32) no confirm; persistir **hash** (bcrypt) em `Manifestacao.chaveConsultaHash`; exibir chave **uma vez** na resposta de confirmação. Consulta pública compara hash — resposta genérica se protocolo ou chave inválidos (FR-017, US7).

**Rationale**: Evita vazamento se DB comprometido; impede enumeração protocolo+chave.

**Alternatives considered**:

| Alternativa | Motivo de rejeição |
|-------------|-------------------|
| Chave em plain text | Risco de vazamento |
| JWT de consulta | Over-engineering para v1 |
| Só protocolo | Viola FR-017 |

---

## R4 — Armazenamento de anexos (Wasabi / S3)

**Decision**: `StorageService` em `ci-api-v2/src/modules/ouvidoria/services/storage.service.ts` usando `@aws-sdk/client-s3` com endpoint Wasabi (`WASABI_*` env). Fluxo **presigned URL**: client solicita URL → upload direto ao bucket → confirma metadados na API. Metadados em `ManifestacaoAnexo`; binário nunca passa pelo NestJS em produção.

**Rationale**: FR-007/008 (30 MB); Wasabi citado na spec; presigned reduz carga na API e escala uploads.

**Alternatives considered**:

| Alternativa | Motivo de rejeição |
|-------------|-------------------|
| Multipart via API | Memória/latência; limite Fastify |
| Filesystem local | Não produção; multi-instance |
| Base64 em PostgreSQL | Inviable para 30 MB |

**Env vars**: `WASABI_ENDPOINT`, `WASABI_REGION`, `WASABI_BUCKET`, `WASABI_ACCESS_KEY`, `WASABI_SECRET_KEY`, `WASABI_PREFIX` (por tenant).

---

## R5 — Catálogo de municípios

**Decision**: Tabela global `Municipio` (`codigoIbge`, `nome`, `uf`) sem `tenantId` — seed estático IBGE (~5570 rows). API `GET /address/municipios?q=` para autocomplete no form. `Address.municipioIbge` FK opcional + `descricaoLocal` para texto livre.

**Rationale**: Assumption spec; municípios são dados de referência nacionais; evita duplicar por tenant.

**Alternatives considered**:

| Alternativa | Motivo de rejeição |
|-------------|-------------------|
| API externa IBGE em runtime | Latência; dependência externa |
| Campo texto livre só | UX inferior; filtros impossíveis |
| Por tenant | Redundância desnecessária |

---

## R6 — Fluxo multi-etapa (rascunho → confirmação)

**Decision**: Status `ManifestacaoStatus.rascunho` até `POST .../confirmar`. Etapas 1–2 (dados/anexos) atualizam rascunho via `PATCH`. Anexos vinculados a rascunho com `manifestacaoId`; limpeza ao abandonar rascunho (soft delete ou job — v1: soft delete na confirmação cancelada manual).

**Rationale**: FR-004 revisão obrigatória; US1 cenário 6 preserva dados entre etapas.

**Alternatives considered**:

| Alternativa | Motivo de rejeição |
|-------------|-------------------|
| SessionStorage client-only | Perde rascunho; sem auditoria |
| Criar registro só no confirm | Anexos precisam de ID antes |

---

## R7 — Status operacional vs derivados

**Decision**: Persistir `status` enum: `rascunho`, `em_analise`, `tramitando`, `respondida`, `encerrada`. Campos derivados **não persistidos**: `critico` e `vencendo` calculados em query/lista comparando `prazoResposta` com `now()` e regras tenant (ex.: crítico se tipo Denúncia + prazo < 3 dias). Exibir como badge overlay na lista (FR-013/FR-014).

**Rationale**: regras-plataforma §7.3 — status operacional ≠ conformidade Jatobá; derivados evitam jobs de sync.

---

## R8 — Sigilo do manifestante

**Decision**: `Manifestacao.sigilo: boolean`. Use-case de detalhe: se `sigilo && !canViewSigilo(user)` → omitir campos manifestante na resposta DTO. `canViewSigilo` = `admin_plataforma` OR usuário com setor em `ModuloSetor` para `ouvidoria` (mesma regra de acesso ao módulo).

**Rationale**: FR-016; US6; reutiliza permissão setor existente sem novo role.

---

## R9 — Consulta pública (sem UI)

**Decision**: Rota `@Public()` `GET /ouvidoria/consulta?protocolo=&chave=` + `@Throttle` (10 req/min/IP). Sem `X-Tenant-ID` — protocolo encode tenant ou prefixo global; **Decision**: protocolo único **por tenant** — consulta exige header `X-Tenant-ID` mesmo em rota pública (tenant identifica instituição). Retorno: `{ status, marcos: [{ data, titulo }] }` sem PII.

**Rationale**: Multi-tenant FR-018; mesmo protocolo numérico pode existir em tenants distintos.

**Alternatives considered**:

| Alternativa | Motivo de rejeição |
|-------------|-------------------|
| Protocolo global cross-tenant | Complexidade; raro em v1 |
| Consulta sem tenant | Ambiguidade FR-018 |

---

## R10 — Client: mock → REST

**Decision**: Substituir dados mock em `ouvidoria-lista`, `ouvidoria-nova`, `ouvidoria-detalhes` por páginas dedicadas (`pages/ouvidoria/`) com wizard shadcn (Steps), React Query para lista/detalhe, `ouvidoria-api.ts` espelhando contract REST. Manter rotas existentes em `screens.ts`.

**Rationale**: screens.ts já define paths; mock em `mock-data.ts` não escala para upload presigned.

**Skills**: `ui-ux-pro-max` (wizard, mint-palette), `vite-react-best-practices` (lazy routes, query keys).

---

## R11 — Layout módulo API

**Decision**: Dois módulos NestJS:

- `address` — Address + Municipio (referência)
- `ouvidoria` — Manifestacao, Anexo, Evento, Sequence, StorageService

Layout canônico `permissao/`: controller, schemas, use-cases/, repository/, services/.

**Rationale**: Constitution V; Address reutilizável; ouvidoria focado no domínio.

---

## R12 — Testes

**Decision**: Jest unit em use-cases (protocol gen, sigilo filter, status derivados); e2e com StorageService mockado (interface `StoragePort`); client typecheck + smoke quickstart.

**Rationale**: Constitution II TDD; S3 difícil em CI — port/adapter.
