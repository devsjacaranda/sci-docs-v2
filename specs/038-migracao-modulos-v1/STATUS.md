# STATUS — 038 Migração de Módulos v1 → v2 (rascunho)

**Data**: 2026-08-21  
**Estado**: implementação de código das US1–US6 + Polish T117–T123 **feita**; feature **NÃO arquivada** e **NÃO** considerada encerrada.

`/speckit-complete` **não** foi executado. Sem commit. `.env` **não** commitado.

---

## Veredito

A 038 **não pode ser considerada implementada/liberada**.

| Trilho | Estado |
|---|---|
| Unitário (Jest API + Vitest `@ci/web`) | **Verde** nos quatro domínios |
| Typecheck `@ci/web` | **Verde** (`tsc -b --noEmit`) |
| Build API (`tsconfig.build.json`) | **Verde** |
| E2E Playwright | **6 passou / 0 skipped / 0 falhou** (5 autenticados na 3ª corrida + portal; diagnóstico+portal reconfirmados na 4ª) |
| Carga live US1 | **Não refeita** após o fix de código (P2002 + +29). Jest 41/41. |
| Diagnóstico com dados | **Coluna alinhada ao v1** (`Requerido_Reu`); GET dashboard/list 200 com dados (não é mais 503 de coluna desconhecida) |
| SC-004 | **Bloqueia** (fumaça rasa; sem divergência proposital na UI; v1 não comparado) |
| SC-006 | **Bloqueia** (29/54 itens técnicos; sem aceite humano) |

Falta o caminho completo do [quickstart.md](./quickstart.md): carga/reconciliação **verde**.

---

## Placar E2E (único)

Comando canônico autenticado (3ª corrida): `npx playwright test specs/ouvidoria-paridade.e2e.spec.ts specs/gabinete-demandas-paridade.e2e.spec.ts specs/gabinete-cadastros-paridade.e2e.spec.ts specs/diagnostico-paridade.e2e.spec.ts --workers=1` em `ci-client-v2/e2e/`.

4ª corrida (pós-env Diagnóstico): `npx playwright test specs/diagnostico-paridade.e2e.spec.ts specs/portal-publico.e2e.spec.ts --workers=1` — **3 passou / 18.1s**.

| Spec | Testes | Resultado vigente | Nota |
|---|---|---|---|
| `ouvidoria-paridade` | 1 | **PASSOU** (3ª) | Lista + painel «Em análise» ≠ 0 (seed Jacaranda) |
| `gabinete-demandas-paridade` | 1 | **PASSOU** (3ª) | Filtros + detalhe + «PDF do histórico» |
| `gabinete-cadastros-paridade` | 1 | **PASSOU** (3ª) | Cinco cadastros carregam |
| `diagnostico-paridade` (v2) | 1 | **PASSOU** (3ª e 4ª) | Relatórios + processos OK. Dashboard ainda no empty/error explícito (FR-059) |
| `diagnostico-paridade` (v1/v2) | 1 | **PASSOU** (3ª e 4ª) | Lado v2 da busca; API v1 não está em localhost |
| `portal-publico` | 1 | **PASSOU** (2ª e 4ª) | Envio + consulta 404 sem vazar existência |

**Placar vigente: 6 passou / 0 skipped / 0 falhou.**

Histórico (não misturar com o placar vigente):

- 1ª corrida: 0 passou / 0 skipped / 6 falhou — API `:3000` DOWN.
- 2ª corrida: 1 passou / 5 skipped — sem `E2E_V2_*` localhost; só o portal rodou.
- 3ª corrida: 5 passou / 0 skipped nos autenticados — auth Jacaranda (`e2e/.env` gitignored).
- 4ª corrida: diagnóstico + portal reconfirmados após copiar `DIAGNOSTICO_*` / `WASABI_*`.

Auth: `E2E_V2_API_URL`, `E2E_V2_ORIGIN`, `E2E_V2_TENANT_ID`, `E2E_V2_EMAIL`, `E2E_V2_PASSWORD` (localhost). Produção recusada no resolver. API v1 **não** religada (`E2E_V1_*` ausente).

### Servidores (4ª corrida)

| Serviço | Porta | Estado | Nota |
|---|---|---|---|
| API v2 | 3000 | **UP** | `GET /health` 200. Login Jacaranda 201. Reiniciada para ler o `.env` novo. |
| `@ci/web` | 5173 | **UP** | Playwright reusou/subiu. `VITE_TENANT_ID=jacaranda`. |
| Portal público `@ci/publico` | 5175 | **UP** | `VITE_API_URL=http://localhost:3000`. |
| API v1 | 3001 | **DOWN** | Não religada. Produção proibida. |

---

## Env legado → v2 (nomes apenas; sem valores)

Fonte: `controle-interno-api/.env` do workspace legado. Destino: `ci-api-v2/.env`. **Nada apagado** do que já funcionava (Neon, JWT, dump local).

| Copiado / mapeado | Origem v1 | Destino v2 |
|---|---|---|
| sim | `AUTOMACAO_DATABASE_URL` | `DIAGNOSTICO_DATABASE_URL` (aspas removidas) |
| sim (alias) | `AUTOMACAO_PROCESSO_TABLE` | `DIAGNOSTICO_PROCESSO_TABLE=processos_extraidos` — o v1 grava o alias legado com espaço; o código v1 redireciona para `processos_extraidos`. O v2 rejeita espaço no nome. |
| sim | `AUTOMACAO_DB_POOL_SIZE` | `DIAGNOSTICO_DB_POOL_SIZE` |
| sim | `AUTOMACAO_QUERY_CACHE_TTL_MS` | `DIAGNOSTICO_QUERY_CACHE_TTL_MS` |
| sim | `AUTOMACAO_QUERY_CACHE_MAX_ENTRIES` | `DIAGNOSTICO_QUERY_CACHE_MAX_ENTRIES` |
| não (sem alvo v2) | `AUTOMACAO_DB_CONNECT_TIMEOUT_MS` | — |
| sim | `ACCESS_KEY` | `WASABI_ACCESS_KEY` |
| sim | `SECRET_KEY` | `WASABI_SECRET_KEY` |
| sim | `BUCKET` | `WASABI_BUCKET` |
| sim | `ENDPOINT_URL` | `WASABI_ENDPOINT` |
| sim | `REGION_NAME` | `WASABI_REGION` |
| sim (vazio) | — | `WASABI_PREFIX` (obrigatório vazio) |
| não | `MYSQL` de produção | — |
| preservado | — | `MYSQL_V1_URL` já apontava para `127.0.0.1` (dump da carga) |
| preservado | — | `DATABASE_URL`, `DATABASE_URL_UNPOOLED`, `JWT_SECRET`, `JWT_EXPIRES_IN`, `NODE_ENV`, `PORT` |
| não | `DATABASE_URL` da API v1 | produção — **não** copiada para API nem E2E |

E2E já usava só localhost; nenhuma URL de produção da API v1 foi copiada para `e2e/.env`.

### Diagnóstico depois do env

- `GET /health` → 200.
- `POST /auth/login` (Jacaranda) → 201.
- `GET /diagnostico/dashboard` e `GET /diagnostico/processos` → **200** (6848). Coluna alinhada ao v1 (`Requerido_Reu`).
- A URL **está certa**: o pool conecta e a consulta chega na tabela.
- Causa anterior do 503: coluna `Requerido` no SQL do v2; a base expõe `Requerido_Reu` (e `Objeto_da_Reclamacao`). Corrigido.
- Dashboard **com dados**. Não é mais ausência de `DIAGNOSTICO_*` nem coluna desconhecida.

---

## Phase 9 (T117–T123)

| Task | Resultado | Evidência |
|---|---|---|
| T117 | PASSOU | Grep + Vitest `no-business-storage.test.ts`. Diagnóstico só menciona `localStorage` em teste que afirma ausência. Ouvidoria: único `sessionStorage` é `tramitacao-active-sector-id` (hint de navegação, não entidade). |
| T118 | PASSOU com ressalva | Listas novas de ouvidoria/gabinete-demandas usam `skip`/`take` no Prisma. Diagnóstico pagina no servidor. **Ressalva**: cadastros do Gabinete e o repositório de processos do Diagnóstico ainda fatiam em memória **no Node** depois do `findMany`/carga — não é filtro no browser. |
| T119 | PASSOU | Jest: `ouvidoria.controller.spec.ts` (lista sem `tenantId`; detalhe cross-tenant → 404) e `diagnostico/test/tenant-isolation.spec.ts` (schema + ALS no marcador). |
| T120 | PASSOU | Loading / empty / error-with-retry em dashboard, listas, catálogos, atendimentos, diagnóstico e portal público. |
| T121 | PASSOU | [checklists/capacidades.md](./checklists/capacidades.md) criado; itens **unchecked** para assinatura humana. |
| T122 | PARCIAL | Playwright vigente **6 passou / 0 skipped**. Live carga ainda vermelha no dump; bugs **corrigidos em código**. Diagnóstico: coluna alinhada ao v1 (`Requerido_Reu`); GET 200. |
| T123 | PASSOU | Sem `.git` no workspace; inspeção por timestamp. Módulos `*-fiscalizacao` / `*-insights` / `*-maturidade` na API datam de junho/2026 (SIGED 17/08, spec 037). **Nada revertido**. |

---

## T122 — o que rodou (dump MySQL local + Neon já no `.env` / sem produção v1)

| Suíte | Resultado |
|---|---|
| Jest API `--testPathPatterns=migracao\|ouvidoria\|gabinete\|diagnostico` | **142 suites / 460 testes PASSOU** |
| Vitest `@ci/web` `ouvidoria` + `gabinete` + `diagnostico` | **44 arquivos / 117 testes PASSOU** |
| `tsc -b --noEmit` / `npm run typecheck -- --filter=@ci/web` | **PASSOU** |
| Playwright (5 autenticados + portal) | **6 passou / 0 skipped / 0 falhou** |
| `migracao:agema:count` / `dry-run` / `migracao:agema` / `compare` | Live **vermelho** (P2002 + +29). **Código corrigido** (Jest 41/41); live **não** refeito. [staging-run.md](./reconciliation/staging-run.md) §7 |
| Build dos três apps do monorepo client | **NÃO RODOU** (typecheck `@ci/web` verde; build API verde) |

---

## SC-004 ainda bloqueia?

**Sim.** Exige cobertura automatizada de interface em **todas** as telas dos módulos migrados e detecção em 100% das tentativas quando uma divergência é introduzida de propósito.

- Specs autenticados e portal **passaram** (Jacaranda localhost).
- Specs continuam fumaça rasa; nenhum introduz divergência de propósito na UI.
- Comparação v1/v2 de dados **não** rodou (API v1 down; produção proibida).
- Diagnóstico lista/dashboard **conecta** na base externa; coluna alinhada ao v1 (`Requerido_Reu`) — GET 200 com dados.

---

## Tasks ainda abertas (fora do unitário)

- Assinatura humana de [checklists/capacidades.md](./checklists/capacidades.md) (SC-006). Verificação técnica (agente, 2026-08-21): **29 `[x]` / 25 `[ ]`**. Gaps em painel/gráficos Ouvidoria, auditoria (tela é fiscalização), atendimentos sem editar/excluir, anexar resposta Gabinete sem UI, docs institucionais só reserva, portal sem anexo/consulta, reconciliação live.
- Pipeline live US1: bugs de carga **corrigidos em código**; live **não** reexecutado. Falta `migracao:agema` + compare até PASS.
- E2E vigente **6 passou / 0 skipped**. Restam **SC-004** e comparação v1/v2.
- Diagnóstico com dados: coluna alinhada ao v1 (`Requerido_Reu`). GET dashboard/list 200.
- Build dos apps do monorepo client (typecheck `@ci/web` e build API já verdes).
- T043 evidência live gravada; aceite FR-006/SC-001 **não** atingido.

---

## Typecheck `@ci/web` (desbloqueio 2026-08-21)

`npm run typecheck -- --filter=@ci/web` no `ci-client-v2` — **PASSOU** (4/4 tasks, `tsc -b --noEmit` sem erros). Sem commit.

**Antes:** ~39 erros TS. Dois do recorte 038; o resto era dívida pré-existente.

| Classe | Erros | Correção (diff mínimo) |
|---|---|---|
| (a) 038 — gabinete protocolo | `LinkedAtoBadge` / `VincularAtoDialog` não importados em `GabineteProtocoloDetailPage.tsx` | Import do mesmo módulo usado nas outras páginas de cadastro |
| (a) 038 — ouvidoria | `statsItems` inexistente em `ManifestacoesListPage.tsx` | `statsLoading && !kpis` |
| (b) global-docs | tipos locais não reexportados | `export type` em `global-docs.api.ts` |
| (b) permissão | `kind`/`source` dos fixtures JSON como `string` | casts em `telas.ts` e handlers MSW |
| (b) saúde | args extras em store `never`; `erasableSyntaxOnly` em `EsusExportError`; toast; unused | wrappers sem args; campo de classe; `body`; imports/params mortos |
| (b) shell/permissões | `VisibilityGridSkeleton` sem import; `Bone` sem `style`; unused | import + `CSSProperties` no Bone |
| (b) SIGED | módulo `constants/siged-ano` ausente; import morto | arquivo mínimo `SIGED_ANO_MIN/MAX` 2000–2100 |
| (b) tramitação | `prev` não lido em `setRecord` | callback sem parâmetro |

---

## Typecheck API v2 (desbloqueio compilação 2026-08-21)

`npx tsc -p tsconfig.build.json --noEmit` em `ci-api-v2` — **PASSOU** (exit 0). Mesmo recorte do `nest start` / `start:dev`. Sem commit. Sem apontar produção.

**Antes:** 8 erros TS no build.

| Classe | Erros | Correção (diff mínimo) |
|---|---|---|
| (a) Diagnóstico PDF | 7× `TS2503` namespace `PDFKit` | DevDep `@types/pdfkit` (`^0.17.6`) |
| (b) Ouvidoria pública / rate-limit | 1× `TooManyRequestsException` inexistente | `HttpException` + `HttpStatus.TOO_MANY_REQUESTS` (Jest 6/6) |

`npx tsc --noEmit` sem `-p tsconfig.build.json` continua vermelho por dívida fora do recorte — **não** bloqueia `start:dev`.

---

## Domínios (relato dos orquestradores)

| Domínio | Tasks | Unitário |
|---|---|---|
| Fundação T001–T020 | READY | — |
| US1 Migração T021–T043 | feito (live vermelho; código corrigido) | Jest 41/41; Address 1:1 + upsert por id v1; live não refeita |
| US2+US6 Ouvidoria T044–T061, T105–T116 | feito | Jest + Vitest verdes; e2e autenticado **PASSOU** |
| US3+US4 Gabinete T062–T084 | feito | Jest + Vitest verdes; e2e autenticado **PASSOU** |
| US5 Diagnóstico T085–T104 | feito | Jest + Vitest verdes; e2e **PASSOU**; coluna alinhada ao v1 (`Requerido_Reu`); GET dashboard/list 200 |
| Phase 9 T117–T123 | feito (T122 parcial) | ver tabela acima |
