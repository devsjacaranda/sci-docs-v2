FOUNDATION: READY

# Coordenação — Spec 038 Migração de Módulos v1 → v2

Fonte de verdade para os orquestradores de domínio. **Não implementar US1–US6 daqui** — só fundação (T001–T020).

## Foundation

| Item | Status |
|---|---|
| T001–T007 Setup | READY |
| T008–T014 Schema Prisma | READY |
| T015 Migration aplicada | READY — `20260821160000_038_migracao_modulos_foundation` |
| T016 `validateTenantPath` | READY |
| T017–T019 Playwright dual-session | READY |
| T020 Slug `diagnostico` (sem licença extra, sem UUID de tenant) | READY |

Sinal de “fundação pronta”: T015 aplicada **e** esta seção Foundation = READY.

## Convenções obrigatórias (todos os agentes)

- **1 use-case = 1 arquivo.** Mesmo para repository. Sem monólitos de PDF.
- **TDD:** teste RED primeiro; confirmar falha; depois GREEN. Constitution II.
- **Zod only** na borda (`*.schemas.ts`). Sem class-validator.
- **Tenant via ALS.** Nunca passar `tenantId` no service. Novos modelos já estão em `TENANT_SCOPED_MODELS`.
- **FK para `User`:** `resolveUserTableId(userId, role)`. `uploadedByUserId` / `criadoPorId` / `arquivadoPorId` / `recebidoPorId` são **nullable**.
- **Sem `localStorage` de negócio.** Token E2E v2 vai em `sessionStorage` só no fixture.
- **Sem filtro client-side** sobre página carregada. Lista/KPI/agregação no servidor.
- **Sem UUID AGEMAN hardcoded.** Diagnóstico = permissão de módulo `diagnostico`.
- **Paleta Mint** (`mint-palette.mdc`). Portal público não usa o azul institucional do v1.
- **Nivo, não Recharts.**
- **`WASABI_PREFIX` vazio.** Chaves de anexo do v1 reutilizadas verbatim.
- **Fora de escopo:** fiscalização, insights, maturidade. Não tocar nesses arquivos.

## Ownership de arquivos (não colidir)

### Migração (US1)

- `ci-api-v2/scripts/migracao-agema-v1/**`
- scripts npm `migracao:*` em `ci-api-v2/package.json`
- `civ2-docs/specs/038-migracao-modulos-v1/reconciliation/`

### Ouvidoria (US2 + US6)

- `ci-api-v2/src/modules/ouvidoria/**`
- `ci-client-v2/apps/web/src/modules/ouvidoria/**`
- `ci-client-v2/apps/publico/**` (US6)
- `ci-client-v2/e2e/specs/ouvidoria*` e `portal*`

Schema já pronto: `manifestacao.prisma`, `ouvidoria-catalog.prisma` (`closed_unresolved`, concessionária, catálogos por tenant, atendimento interno).

### Gabinete (US3 + US4)

- `ci-api-v2/src/modules/gabinete/**`
- `ci-api-v2/src/modules/setor/**`
- `ci-client-v2/apps/web/src/modules/gabinete/**`
- `ci-client-v2/e2e/specs/gabinete*`

Schema já pronto: `order` em documento tramitado; `recebidoEm`/`recebidoPorId`; eventos `received`/`returned`/`response`; Setor `nomeCompleto`/`descricao`/`active`; anexos com uploader nullable.

**Status US3/US4 (2026-08-21):** T062–T084 feitos. Encaminhar persiste `currentSector`/`sectorId` e `awaiting_receipt`. Receber/devolver (só DEJUR → Ouvidoria|Gabinete)/reencaminhar/anexar resposta/PDF histórico no ar. Cadastros: `order` ≠ `quantity`, superRefine por tipo, amount Decimal string, Setor inativa sem delete. Client: ações de fluxo, filtros setor/período, Diretorias, listas paginadas no servidor. E2E: `gabinete-demandas-paridade` e `gabinete-cadastros-paridade`.

### Diagnóstico (US5)

- `ci-api-v2/src/modules/diagnostico/**`
- `ci-api-v2/src/modules/documento-institucional/**`
- `ci-client-v2/apps/web/src/modules/diagnostico/**`
- `ci-client-v2/e2e/specs/diagnostico*`

Schema já pronto: `DiagnosticoProcessoMarcador`; modelos/sequence/auditoria de documento institucional. Env `DIAGNOSTICO_*` no `env.schema`. Slug `diagnostico` em `ModuloSlug` + `MODULO_SLUGS` (sem licença nova).

**Status (2026-08-21)**: T085–T104 concluídos.

| Faixa | Status | Evidência |
|---|---|---|
| T085–T090 | GREEN | Jest 6 suites / 41 testes |
| T091–T099 | feito | mysql2 RO, CTE/cache, 7 `buscaPor`, marcador sem localStorage, PDFKit decomposto, `@RequireModulo('diagnostico')`, reserva transacional, job 6h/24h com auditoria |
| T100–T103 | feito | 3 views + hook API-only + Nivo + gate por permissão no router |
| T104 | spec escrita | `e2e/specs/diagnostico-paridade.e2e.spec.ts` (comparação v1 gated por `E2E_V1_ENABLED`) |

## Env e E2E (nomes, sem valores)

API: `WASABI_*` (grupo coerente), `MYSQL_V1_URL`, `DIAGNOSTICO_*`.  
E2E: `E2E_V2_API_URL`, `E2E_V2_TENANT_ID`, `E2E_V2_EMAIL`, `E2E_V2_PASSWORD` — **sem default**.  
Porta `@ci/web`: **5173** `strictPort: true`. v1 client: **8080**.

## O que a fundação NÃO fez

T021+ (US1–US6 e Polish). Use-cases de domínio, loaders, UI e specs comparativos ficam com os orquestradores de domínio.

---

## US1 — Carga / reconciliação (orquestrador migração)

**Status**: T021–T043 concluídos no código. Jest verde. Live 2026-08-21 **vermelho** (P2002 + não-idempotente) — [reconciliation/staging-run.md](./reconciliation/staging-run.md).

Convenções: `ARQUIVADO` → `closed_unresolved`, `ARQUIVADO_OK` → `closed`; `origem` `"interna"` \| `"publica"`.

| ID | Status | Notas |
|---|---|---|
| T021–T026 | GREEN | specs RED agora passam |
| T027 / T040 | feito | `equivalence-map.ts` + `field-compare.ts` (exit 1 em divergência) |
| T028 | feito | `persistRegistroOrigem` no banco + cache JSON |
| T029 | feito | `research-anexos-publicos.md` — public/temp sem vínculo → relatório |
| T030–T033 | feito | 13 tabelas, `ord`→`order`, anexo verbatim, ouvidoria+gabinete mappers |
| T034–T036 | feito | upsert por chave natural; endereço/concessionária/sequence; demandas |
| T037–T038 | feito | `diagnostico.load.ts`; fases no `run-migration.ts` (`--dry-run` igual) |
| T039 / T041 / T042 | feito | count com exclusões; `migracao:compare-fields` + `migracao:anexos` |
| T043 | live vermelho | dump restaurado no XAMPP; count/dry-run OK; carga P2002 (`tenantId,entidade,idV2`); 2ª carga +29 manifestações sem protocolo; compare FAIL |

---

## US2 + US6 — Ouvidoria (orquestrador)

**Status**: T048–T061 e T108–T116 concluídos. Sem commit. Sem prisma / sem `migracao-agema-v1`.

| Faixa | Status | Evidência |
|---|---|---|
| T044–T047 | GREEN | Jest 4 suites / 25 testes (dashboard, encerrar, catálogos, controller) |
| T048–T054 | feito | 7 agregações no banco; encerrar `closed`/`closed_unresolved` + carta; catálogos tenant; auditoria; DOCX/PDFKit decomposto; filtros servidor |
| T055–T061 | feito | dashboard Nivo; KPIs reais; encerrar+docs; catálogos/atendimentos; campos AGEMAN; rotas; e2e `ouvidoria-paridade` |
| T105–T107 | GREEN | Jest incluído no lote 8 suites / 46 testes (público + schemas) |
| T108–T116 | feito | `@Public()` create/upload/consulta; `@ci/publico` `envDir` local `--mode ageman`; toast+stepper em `@ci/ui`; `dev:publico`; e2e `portal-publico` |

Convenções: resolutividade pelo **status** (nunca `foiAtendido`); KPI em análise real; `origem` `"interna"` \| `"publica"`; `resolveUserTableId` em `arquivadoPorId`/`registradoPorId`; documentos no servidor; portal AGEMAN sem LLM.

---

## Phase 9 — Polish (orquestrador geral)

**Status (2026-08-21)**: T117–T123 executados. Sem commit. Sem `/speckit-complete`.

| Task | Veredito |
|---|---|
| T117 | GREEN — sem dado de negócio em localStorage; único sessionStorage = hint `tramitacao-active-sector-id` |
| T118 | GREEN com ressalva — listas no servidor; cadastros Gabinete / processos Diagnóstico ainda fatiam em memória no Node |
| T119 | GREEN — testes cross-tenant em ouvidoria + diagnóstico |
| T120 | GREEN — loading / empty / error-with-retry nas telas novas |
| T121 | feito — `checklists/capacidades.md` (unchecked, assinatura humana) |
| T122 | PARCIAL — Jest 142/460 + Vitest 44/117 verdes; Playwright e carga live **rodaram e falharam** (ver STATUS.md) |
| T123 | GREEN — `*-fiscalizacao`/`*-insights`/`*-maturidade` intactos (timestamps jun/2026; SIGED 17/08 = 037). Sem revert |

### Veredito geral

Fundação + 4 domínios + Polish unitário = **código das US1–US6 entregue**.  
A 038 **NÃO está implementada para liberação**: E2E Playwright vermelho; carga live contra dump **vermelha** (P2002 + não-idempotente); falta assinatura SC-006. Feature **não arquivada**. Detalhe em [STATUS.md](./STATUS.md).
