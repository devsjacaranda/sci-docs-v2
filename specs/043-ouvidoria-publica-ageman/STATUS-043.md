# STATUS — 043 Ouvidoria Pública AGEMAN

**Data**: 2026-09-11  
**Branch**: `043-ouvidoria-publica-ageman`  
**Orquestrador**: agente cross-cutting (esta rodada)  
**Spec**: [spec.md](./spec.md) · **Tasks**: [tasks.md](./tasks.md) · **Plano**: [plan.md](./plan.md)

---

## Estado da rodada (orquestrador)

| Item | Status |
| --- | --- |
| STATUS-043.md (matriz + ownership + TDD) | **Concluído** |
| Fixtures API T005 | **Concluído** |
| Pipeline deploy T060 (`@ci/publico`) | **Concluído** |
| Ignore files (speckit-implement §4) | **Verificado** — padrões essenciais já presentes |
| Testes client (T062) | **GREEN** — 50/50 Vitest + typecheck OK |
| Testes API (T061) | **GREEN** — 454/454 Jest ouvidoria ([T061 regressão API ouvidoria](8b48ecab-0c49-45b7-8fdd-a1bc4f0dc6b3)) |
| WelcomePage paridade v1 | **Concluído** — hero AGE, 5 cards, áudio, seções institucionais ([WelcomePage paridade v1 AGEMAN](701aebed-75c7-4b3f-9610-2ffbdec43b8b)) |
| Quickstart (T063) | **Parcial** — quickstart corrigido + tabela «Validação T063» ([T063 validar quickstart §§1-5](dc731f81-8f9f-4f0f-a7b2-017ec1f8ddc7)); E2E browser manual pendente |
| API Phase 2 + US1–US3 backend | **GREEN** — T008–T049 |
| Client US1–US5 | **GREEN** — T001–T007, T019–T059, T064 |
| Assets binários T007 | **Concluído** — PNG/JPG/MP3/SVG + favicons em `apps/publico/public/` e `src/assets/` |
| Phase 1 client (T002, T006) | **Concluído** |

---

## Matriz de agentes

| Agente | Fases / stories | Escopo principal | Tasks típicas |
| --- | --- | --- | --- |
| **Orquestrador** | Cross-cutting | Docs, fixtures API T005, pipeline Docker/CI | T005, T060, STATUS-043 |
| **A — API** | Phase 2 + US1–US3 API + US2 backend | `ci-api-v2/src/modules/ouvidoria/**` | T008–T010, T013–T018, T028–T032, T038–T043, T046, T048–T049 |
| **B — Client infra** | Phase 1–2 client | Setup, schemas, hooks, layout, `main.tsx` base | T001–T004, T006–T007, T011–T012, T019–T027 |
| **C — US1 UI** | Phase 3 | Chatbot, welcome, review, API client | T030, T033–T037 |
| **D — US2** | Phase 4 | Migration anexo temp, upload, bind, input | T038–T045 (client após T032) |
| **E — US3** | Phase 5 | Consulta pública (API label + tela) | T046–T052 |
| **F — US4** | Phase 6 | Acessibilidade | T053–T056 |
| **G — US5** | Phase 7 | FAQ Tucaninho | T057–T059 |
| **Humano / final** | Phase 8 | Regressão + quickstart | T061–T063 |

### Dependências entre agentes

```text
Orquestrador (T005 fixtures, T060 pipeline)
    ↓
A + B em paralelo (Phase 2 RED → GREEN) — B depende T001–T004 de B
    ↓
C (US1 MVP) — C depende Phase 2 GREEN
    ↓
D (US2) + E (US3 API/UI) em paralelo após T032
F (US4) após T027 · G (US5) após T034 (stub consulta ok se US3 atrasar)
    ↓
Humano: T061–T063 · Orquestrador/polish: T064
```

---

## Ownership de arquivos (evitar conflitos)

### 🔒 Exclusivo do Orquestrador — **não editar** sem coordenação

| Caminho | Motivo |
| --- | --- |
| `ci-client-v2/Dockerfile` | Stage nginx `@ci/publico` |
| `ci-client-v2/Dockerfile.dev` | EXPOSE 5175 |
| `ci-client-v2/compose.dev.yaml` | Serviço `publico` |
| `ci-client-v2/.github/workflows/deploy-client-ageman.yml` | Build/deploy `@ci/publico` |
| `civ2-docs/specs/043-ouvidoria-publica-ageman/STATUS-043.md` | Este documento |

### Agente A — API (`ci-api-v2`)

| Caminho | Tasks |
| --- | --- |
| `src/modules/ouvidoria/ouvidoria.schemas.ts` | T015 |
| `src/modules/ouvidoria/ouvidoria.mapper.ts` | T048 |
| `src/modules/ouvidoria/ouvidoria.controller.ts` | T018 |
| `src/modules/ouvidoria/lib/ageman-catalog.ts` | T013 |
| `src/modules/ouvidoria/lib/numero-personalizado.ts` | T014 |
| `src/modules/ouvidoria/repository/*.ts` (público) | T016, T031, T041–T043 |
| `src/modules/ouvidoria/use-cases/*.ts` (público) | T018, T032, T042, T049 |
| `src/modules/ouvidoria/test/**` (specs) | T008–T010, T028–T029, T038–T039, T046 |
| `src/modules/ouvidoria/test/fixtures/*.json` | T005 ✅ (orquestrador) |
| `prisma/schema/manifestacao.prisma` + migration | T040 |
| `src/infrastructure/config/env.schema.ts` | T017 |

### Agente B — Client infra (`ci-client-v2/apps/publico`)

| Caminho | Tasks |
| --- | --- |
| `package.json`, `vitest.config.ts` | T001–T002 |
| `src/modules/manifestacao/**` (esqueleto, constants, utils, hooks base) | T003, T006–T007, T019–T026 |
| `.env.ageman.example` | T004 |
| `src/main.tsx` (shell + providers) | T027 — **sequencial** com C/D/E/F/G em trechos distintos |
| `src/config/tenant-config.ts` | T019 |

### Agentes C–G — Client features

| Agente | Caminhos exclusivos |
| --- | --- |
| C (US1) | `components/WelcomePage.tsx`, `PublicChatbotForm.tsx`, `ReviewFormModal.tsx`, `api/public-manifestacao.ts`, `api/programas.ts` |
| D (US2) | `api/anexos-publicos.ts`, `components/PublicAttachmentsInput.tsx` |
| E (US3) | `pages/ConsultaProtocoloPage.tsx`, `api/consulta.ts` |
| F (US4) | `context/AccessibilityContext.tsx`, `components/accessibility/**` |
| G (US5) | `components/FloatingAgeWidget.tsx` |

### Arquivos compartilhados — **coordenação obrigatória**

| Arquivo | Regra |
| --- | --- |
| `apps/publico/src/main.tsx` | B abre shell (T027); C/D/E/F/G ligam telas em commits sequenciais |
| `apps/publico/package.json` | B adiciona deps (T001–T002); Orquestrador **não** toca |
| `ReviewFormModal.tsx` | C cria (T036); D adiciona anexos (T045) |

### Proibido nesta feature

- Estender `GET /ouvidoria/publico/catalogos` — usar rota nova `GET /ouvidoria/publico/programas`
- Paleta Mint em `apps/publico` — identidade AGEMAN v1
- Enum `tipo` em português — reusar `manifestacaoTipo`
- `createdByUserId` no fluxo público — sempre `undefined`

---

## Ordem TDD (RED → GREEN → REFACTOR)

Conforme [contracts/test-strategy.md](./contracts/test-strategy.md):

| Ordem | Camada | RED (escrever teste) | GREEN (implementar) |
| --- | --- | --- | --- |
| 1 | API schema | T008 CT-OUV-PUB-001 | T015 |
| 2 | API reCAPTCHA | T009 CT-OUV-PUB-004 | T016–T017 |
| 3 | API programas | T010 CT-OUV-PUB-008 | T013–T014, T018 |
| 4 | Client schema | T011 | T021 |
| 5 | Client reCAPTCHA | T012 | T024 |
| 6 | API create repo | T028 CT-OUV-PUB-002 | T031 |
| 7 | API create UC | T029 CT-OUV-PUB-003 | T032 |
| 8 | Client chatbot RTL | T030 | T035 |
| 9 | API upload/bind | T038–T039 | T040–T043 |
| 10 | API consulta | T046 CT-OUV-PUB-007 | T048–T049 |
| 11 | Client consulta RTL | T047 | T051 |
| 12 | Client a11y | T053 | T054–T056 |
| 13 | Client FAQ | T057 | T058–T059 |

**Checkpoint MVP:** após US1 (T037) — validar [quickstart.md](./quickstart.md) §1 manualmente.

---

## Conflitos conhecidos / zonas de atenção

| Conflito | Mitigação |
| --- | --- |
| `main.tsx` editado por B, C, E, F, G | Sequência: T027 → T037 → T052 → T056 → T059 |
| `ReviewFormModal.tsx` C vs D | C entrega sem anexos; D estende |
| `package.json` publico (B) vs lockfile | Um agente roda `npm install` por vez |
| Fixtures API T005 vs testes A | Orquestrador criou JSON; A usa em specs RED |
| Deploy VPS `VPS_PUBLIC_DIR` | Secret **novo** — configurar no repo + nginx `:8082` antes do smoke deploy |
| `VITE_API_BASE_URL` (tasks) vs `VITE_API_URL` (código atual) | Agente B alinhar `.env.ageman.example` com `@ci/shared` / código existente |
| Specs upload desalinhados pós-GREEN T042 | **Resolvido** — `upload-anexo-publico`, `upload-publico` e `ouvidoria-errors` alinhados ao construtor `(storeTemp, findTemp, storage)` |

---

## Pipeline `@ci/publico` (T060 ✅)

| Artefato | Alteração |
| --- | --- |
| `ci-client-v2/package.json` | `build:publico` |
| `ci-client-v2/Dockerfile` | build turbo + stage `publico` nginx |
| `ci-client-v2/compose.dev.yaml` | serviço `publico` → `:5175` |
| `ci-client-v2/.github/workflows/deploy-client-ageman.yml` | build + `publico-dist.zip` + deploy condicional `VPS_PUBLIC_DIR` |

**Dev local:** `cd ci-client-v2; npm run dev:publico` ou `docker compose -f compose.dev.yaml up publico`

**Produção:** configurar secret `VPS_PUBLIC_DIR` e vhost nginx na porta **8082** (smoke no workflow).

---

## Fixtures API (T005 ✅)

| Arquivo | Uso |
| --- | --- |
| `test/fixtures/criar-manifestacao-publica-agua.json` | CT-OUV-PUB-001 happy path água |
| `test/fixtures/criar-manifestacao-publica-institucional.json` | CT-OUV-PUB-001 institucional (motivo livre) |
| `test/fixtures/consulta-publica-response.json` | CT-OUV-PUB-007 shape 200 |
| `test/fixtures/programas-publicos-response.json` | CT-OUV-PUB-008 — 6 programas, 77 motivos |

---

## Próximos passos

1. **T063 manual** — browser E2E §§1–2 (chatbot + anexos reais), consulta com protocolo vivo §3, inspeção visual a11y §4, FAQ §5, reCAPTCHA real com secret Google.
2. **Deploy** — garantir assets binários versionados ou copiados no pipeline (T007 local OK; git pode não ter PNG/JPG grandes).

---

## Checklist Spec Kit

| Checklist | Total | OK | Pendente | Status |
| --- | --- | --- | --- | --- |
| [requirements.md](./checklists/requirements.md) | 16 | 16 | 0 | ✓ PASS |
