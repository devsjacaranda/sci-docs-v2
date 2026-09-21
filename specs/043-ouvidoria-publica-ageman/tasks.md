---
description: "Task list for Ouvidoria Pública AGEMAN (043-ouvidoria-publica-ageman)"
---

# Tasks: Ouvidoria Pública AGEMAN (v2)

**Input**: Design documents from `civ2-docs/specs/043-ouvidoria-publica-ageman/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Tests**: **Obrigatórios** — TDD (Constitution II + `contracts/test-strategy.md`): RED → GREEN → REFACTOR. IDs `CT-OUV-PUB-NNN` na API.

**Organization**: 5 user stories (US1–US5). Caminhos relativos à raiz `ci-v2/`. Estende o módulo `ouvidoria` existente (API) e o app `@ci/publico` existente (client). Sem projeto novo.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Pode executar em paralelo (arquivos diferentes, sem dependências pendentes)
- **[Story]**: User story da spec (US1–US5)

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Dependências, pastas, env, fixtures e assets — não altera comportamento de produção ainda

- [X] T001 [P] Adicionar `react-hook-form`, `@hookform/resolvers`, `@tanstack/react-query`, `@ci/shared` em `ci-client-v2/apps/publico/package.json` e instalar no workspace
- [X] T002 [P] Adicionar Vitest (`vitest`, `@testing-library/react`, `jsdom`) + script `test` em `ci-client-v2/apps/publico/package.json` e config mínima em `ci-client-v2/apps/publico/vitest.config.ts` (espelhar `apps/web`)
- [X] T003 [P] Criar esqueleto de pastas em `ci-client-v2/apps/publico/src/modules/manifestacao/` (`pages/`, `components/layout/`, `components/accessibility/`, `context/`, `hooks/`, `constants/`, `schemas/`, `utils/`, `api/`, `fixtures/`) com `index.ts` vazio
- [X] T004 [P] Atualizar `ci-client-v2/apps/publico/.env.ageman.example` com `VITE_API_BASE_URL`, `VITE_TENANT_ID=ageman`, `VITE_TENANT_NAME`, `VITE_ASSISTANT_NAME`, `VITE_TENANT_LOGO`, `VITE_TENANT_WEBSITE_URL`, `VITE_TENANT_PROTOCOL_SUFFIX`, `VITE_RECAPTCHA_SITE_KEY` (vazio em dev)
- [X] T005 [P] Criar fixtures API `ci-api-v2/src/modules/ouvidoria/test/fixtures/criar-manifestacao-publica-agua.json`, `criar-manifestacao-publica-institucional.json`, `consulta-publica-response.json`, `programas-publicos-response.json` conforme `contracts/rest-api-ouvidoria-publica.md`
- [X] T006 [P] Criar fixtures client `ci-client-v2/apps/publico/src/modules/manifestacao/fixtures/criar-manifestacao-agua.json`, `consulta-ok.json`, `consulta-404.json`, `programas.json`
- [X] T007 [P] Copiar assets AGEMAN da v1 (`age-tucano.png`, `age-profile.png`, `age-error.png`, `age-voice.mp3`, `loading-animation.svg`, `ageman-2025.png`, `ageman-facade.jpg`, favicons) de `C:\controle-interno-workspace\manifestatiion-public-client\public\` para `ci-client-v2/apps/publico/public/` (servidos em `/…`) e `ci-client-v2/apps/publico/src/assets/` (imports `@/assets/…`) — **concluído 2026-09-11**: binários obtidos de `manifestatiion-public-client/public/` (não versionados no git da v1); `index.html` atualizado com favicons

**Checkpoint**: `npm install` ok; pastas existem; fixtures e assets no lugar; nenhum endpoint/UI alterado

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Catálogo institucional, schema Zod expandido, reCAPTCHA (falha fechada), cliente HTTP, constantes/utils do portal — **bloqueia US1–US5**

**⚠️ CRITICAL**: Schemas + reCAPTCHA + catálogo + `createApiClient` devem estar GREEN antes de portar o chatbot ou persistir manifestações

### Tests first (TDD — RED)

- [X] T008 [P] Escrever testes (RED) `ci-api-v2/src/modules/ouvidoria/test/ouvidoria.schemas.publico.spec.ts` — CT-OUV-PUB-001: happy path dos 6 programas; `tipo` inválido; `email` ausente/inválido; `institucional` com motivo livre; `matricula` ausente em `agua`; campos de iluminação ausentes; `address` parcial aceito
- [X] T009 [P] Escrever testes (RED) `ci-api-v2/src/modules/ouvidoria/test/repository/verify-public-challenge.repository.spec.ts` — CT-OUV-PUB-004: secret ausente → bypass (`length >= 4`); secret + `siteverify` ok (`score>=0.5`, `action=submit_manifestation`); score baixo; action errada; `fetch` timeout → **falha fechada** (inválido)
- [X] T010 [P] Escrever testes (RED) `ci-api-v2/src/modules/ouvidoria/test/use-cases/list-programas-publicos.use-case.spec.ts` — CT-OUV-PUB-008: 6 `code`/`label`; `institucional` com `motivos: []`; demais com `AGEMAN_MOTIVOS_BY_PROGRAMA`
- [X] T011 [P] Escrever testes (RED) `ci-client-v2/apps/publico/src/modules/manifestacao/schemas/public-manifestacao.schema.test.ts` — paridade com CT-OUV-PUB-001 (6 programas, `tipo`, e-mail obrigatório mesmo anônimo, condicionais água/iluminação)
- [X] T012 [P] Escrever testes (RED) `ci-client-v2/apps/publico/src/modules/manifestacao/hooks/use-recaptcha.test.ts` — site key ausente → `execute()` retorna `undefined`; site key presente → mock de `window.grecaptcha` devolve token

### Implementation for Foundational

- [X] T013 [P] Adicionar `AGEMAN_PROGRAMA_LABEL['6'] = 'Assuntos institucionais'` e alias `institucional` em `ci-api-v2/src/modules/ouvidoria/lib/ageman-catalog.ts` (sem lista de motivos)
- [X] T014 [P] Adicionar `PROGRAMA_CODE.institucional = '6'` em `ci-api-v2/src/modules/ouvidoria/lib/numero-personalizado.ts`
- [X] T015 Expandir `criarManifestacaoPublicaBodySchema` em `ci-api-v2/src/modules/ouvidoria/ouvidoria.schemas.ts`: `programa` 6 valores; `tipo` reaproveitando `manifestacaoTipo` (sem `simplify` no público); `email` (`z.email()`, obrigatório); `mobilePhone`/`homePhone`/`businessPhone` opcionais; manter `superRefine` de água/iluminação/nome (GREEN T008)
- [X] T016 Implementar reCAPTCHA v3 real + bypass de dev + falha fechada em `ci-api-v2/src/modules/ouvidoria/repository/verify-public-challenge.repository.ts` (GREEN T009); ler `RECAPTCHA_SECRET_KEY` do env
- [X] T017 [P] Adicionar `RECAPTCHA_SECRET_KEY` opcional em `ci-api-v2/src/infrastructure/config/env.schema.ts` (e `.env.example` da API)
- [X] T018 Implementar `ci-api-v2/src/modules/ouvidoria/use-cases/list-programas-publicos.use-case.ts` e registrar `GET /ouvidoria/publico/programas` (`@Public()`) em `ci-api-v2/src/modules/ouvidoria/ouvidoria.controller.ts` **sem** alterar o shape de `GET /ouvidoria/publico/catalogos` (GREEN T010)
- [X] T019 [P] Portar `ci-client-v2/apps/publico/src/config/tenant-config.ts` da v1 (`getTenantConfig()` lendo `VITE_TENANT_*`)
- [X] T020 [P] Criar cliente HTTP em `ci-client-v2/apps/publico/src/modules/manifestacao/api/client.ts` via `createApiClient` de `@ci/shared` — **sem** `setAccessToken` / `registerSessionLostHandler`; `tenantId` de `VITE_TENANT_ID`
- [X] T021 Implementar `ci-client-v2/apps/publico/src/modules/manifestacao/schemas/public-manifestacao.schema.ts` (Zod v3, comentário de origem apontando `ouvidoria.schemas.ts`) e aposentar `form-schema.ts` após GREEN T011
- [X] T022 [P] Portar `ci-client-v2/apps/publico/src/modules/manifestacao/constants/manifestation-options.ts` — 6 programas + `TIPO_MANIFESTACAO_OPTIONS` mapeando labels PT → enum inglês da API
- [X] T023 [P] Portar `ci-client-v2/apps/publico/src/modules/manifestacao/schemas/ageman-public-fields.ts`, `utils/masks.ts`, `utils/manaus-zones.ts` da v1 (com testes Vitest em `utils/masks.test.ts` e `utils/manaus-zones.test.ts`) — *testes RED entregues; port v1 pendente (GREEN)*
- [X] T024 [P] Portar `ci-client-v2/apps/publico/src/modules/manifestacao/hooks/use-recaptcha.ts` da v1 (GREEN T012)
- [X] T025 [P] Portar `ci-client-v2/apps/publico/src/modules/manifestacao/hooks/use-viacep.ts` da v1 (ViaCEP via React Query)
- [X] T026 [P] Portar `ci-client-v2/apps/publico/src/modules/manifestacao/components/layout/Header.tsx` e `Footer.tsx` da v1 (identidade visual AGEMAN, **não** paleta Mint)
- [X] T027 Recompor `ci-client-v2/apps/publico/src/main.tsx` com `QueryClientProvider` + estado `screen: 'welcome' | 'chatbot' | 'consulta'` e listeners de `start-manifestation` / `open-review-modal` / `reset-chatbot` / `open-consulta` — placeholders por tela (stepper atual pode ficar só no placeholder de chatbot até US1)

**Checkpoint**: Schema público GREEN; reCAPTCHA GREEN (bypass + falha fechada); `GET /ouvidoria/publico/programas` responde; app público sobe com Header/Footer e troca de tela por evento

---

## Phase 3: User Story 1 — Registrar manifestação pelo assistente conversacional (Priority: P1) 🎯 MVP

**Goal**: Cidadão percorre landing → chatbot (6 categorias + tipo + anonimato + e-mail) → revisão → envio e recebe protocolo + chave únicos

**Independent Test**: Completar o assistente para cada uma das 6 categorias e confirmar protocolo + chave; água sem matrícula bloqueia; iluminação sem poste/protocolo bloqueia; anônimo ainda exige e-mail; challenge inválido não registra (`quickstart.md` §1)

### Tests for User Story 1 (TDD — RED first)

- [X] T028 [P] [US1] Escrever testes (RED) `ci-api-v2/src/modules/ouvidoria/test/repository/create-manifestacao-publica.repository.spec.ts` — CT-OUV-PUB-002: persiste `type` mapeado; `replyEmail`/telefones; `addressId` via `CreateAddressRepository`; **`createdByUserId` é `undefined`**; retorna `id`
- [X] T029 [P] [US1] Escrever testes (RED) `ci-api-v2/src/modules/ouvidoria/test/use-cases/criar-manifestacao-publica.use-case.spec.ts` — CT-OUV-PUB-003: challenge inválido → 400; rate limit → 429; matrícula/iluminação inválidas → 400; bind chamado com `manifestacaoId` (não `protocol`)
- [X] T030 [P] [US1] Escrever testes (RED) RTL `ci-client-v2/apps/publico/src/modules/manifestacao/components/PublicChatbotForm.test.tsx` — pergunta de e-mail sempre aparece no fluxo anônimo; água exige matrícula antes da descrição

### Implementation for User Story 1

- [X] T031 [US1] Persistir `tipo`, `replyEmail`, telefones e `addressId` (`CreateAddressRepository`) em `ci-api-v2/src/modules/ouvidoria/repository/create-manifestacao-publica.repository.ts`; remover `user.findFirst` de `createdByUserId`; devolver `id` no retorno (GREEN T028)
- [X] T032 [US1] Atualizar `CriarManifestacaoPublicaInput` + `execute` em `ci-api-v2/src/modules/ouvidoria/use-cases/criar-manifestacao-publica.use-case.ts` para aceitar `tipo`/contato/endereço e chamar `bindAnexos` com `created.id` (GREEN T029). Bind real de arquivo fica na US2 — nesta fase o bind pode continuar no-op se `anexoTempIds` vazio
- [X] T033 [P] [US1] Implementar `ci-client-v2/apps/publico/src/modules/manifestacao/api/public-manifestacao.ts` (`POST /ouvidoria/publico/manifestacoes`) e `api/programas.ts` (`GET /ouvidoria/publico/programas`) com parse Zod da resposta
- [X] T034 [P] [US1] Portar `ci-client-v2/apps/publico/src/modules/manifestacao/components/WelcomePage.tsx` da v1 (hero, cards de serviço, AGE, institucional) + ponto de entrada “Nova manifestação” disparando `start-manifestation`
- [X] T035 [US1] Portar `ci-client-v2/apps/publico/src/modules/manifestacao/components/PublicChatbotForm.tsx` da v1 — 6 categorias, tipo, anonimato, e-mail obrigatório, voz, CEP/zona; motivos via `GET /ouvidoria/publico/programas` (GREEN T030)
- [X] T036 [US1] Portar `ci-client-v2/apps/publico/src/modules/manifestacao/components/ReviewFormModal.tsx` da v1 — `react-hook-form` + `zodResolver(public-manifestacao.schema)` + `useMutation` + `executeRecaptcha('submit_manifestation')`; sucesso exibe `protocol` + `chaveConsulta` com aviso de que a chave não reaparece
- [X] T037 [US1] Ligar `welcome`/`chatbot` + `open-review-modal` em `ci-client-v2/apps/publico/src/main.tsx`; remover `ManifestacaoGuidedForm.tsx` e o stepper legado

**Checkpoint**: US1 independente — registro ponta a ponta das 6 categorias gera protocolo + chave; anti-robô bloqueia token inválido

---

## Phase 4: User Story 2 — Anexar evidências à manifestação (Priority: P2)

**Goal**: Upload real persistido (presign + PUT + bind em `ManifestacaoAnexo`); limites alinhados ao padrão interno (30MB + `ALLOWED_MIME_TYPES`)

**Independent Test**: Arquivo válido aparece vinculado após o envio; arquivo fora do limite/tipo é rejeitado com mensagem clara; equipe interna consegue baixar o arquivo (`quickstart.md` §2)

### Tests for User Story 2 (TDD — RED first)

- [X] T038 [P] [US2] Escrever testes (RED) `ci-api-v2/src/modules/ouvidoria/test/use-cases/upload-anexo-publico.use-case.spec.ts` — CT-OUV-PUB-005: mime/tamanho ok → presign via `StorageService` mock; fora do limite → `ANEXO_INVALID`; temp gravado com `tenantId`
- [X] T039 [P] [US2] Escrever testes (RED) `ci-api-v2/src/modules/ouvidoria/test/repository/bind-anexos-publicos.repository.spec.ts` — CT-OUV-PUB-006: cria `ManifestacaoAnexo` real; ignora temp expirado/consumido/de outro tenant; marca `consumedAt`

### Implementation for User Story 2

- [X] T040 [US2] Adicionar model `ManifestacaoAnexoPublicoTemp` em `ci-api-v2/prisma/schema/manifestacao.prisma` (campos em `data-model.md` §2) e gerar/aplicar migration `ci-api-v2/prisma/migrations/*_ouvidoria_publica_anexo_temp/`
- [X] T041 [US2] Reescrever `ci-api-v2/src/modules/ouvidoria/repository/store-public-temp-anexo.repository.ts` e `find-public-temp-anexo.repository.ts` para persistir/ler via Prisma (substituir o `Map` em memória)
- [X] T042 [US2] Reescrever `ci-api-v2/src/modules/ouvidoria/use-cases/upload-anexo-publico.use-case.ts` para validar com `MAX_ANEXO_BYTES` / `normalizeAnexoMimeType` de `ouvidoria-anexo.constants.ts`, gerar `storageKey` via `StorageService.buildStorageKey(tenantId, 'publico-temp', anexoId)`, `presignUpload`, persistir temp e devolver `{ tempId, uploadUrl, expiresIn }` (GREEN T038)
- [X] T043 [US2] Reescrever `ci-api-v2/src/modules/ouvidoria/repository/bind-anexos-publicos.repository.ts` para criar `ManifestacaoAnexo` (`kind: file`, `uploadConfirmed: true`, `uploadedByUserId: null`) a partir de temps válidos e marcar `consumedAt` (GREEN T039)
- [X] T044 [P] [US2] Implementar `ci-client-v2/apps/publico/src/modules/manifestacao/api/anexos-publicos.ts` — `POST /ouvidoria/publico/anexos` + `PUT` direto em `uploadUrl`
- [X] T045 [US2] Portar `ci-client-v2/apps/publico/src/modules/manifestacao/components/PublicAttachmentsInput.tsx` da v1 (drag-and-drop, limite 30MB, lista MIME interna) e ligar em `ReviewFormModal.tsx` / etapa de detalhes do chatbot via `anexoTempIds[]`. Links externos **fora de escopo** nesta entrega (`data-model.md` §1)

**Checkpoint**: US1 continua funcionando sem anexos; US2 adiciona persistência real acessível internamente

---

## Phase 5: User Story 3 — Consultar o andamento de uma manifestação (Priority: P2)

**Goal**: Tela nova (inexistente na v1) consulta por protocolo + chave e mostra status **simplificado** (Recebida/Em análise/Respondida/Encerrada)

**Independent Test**: Consultar com protocolo+chave de US1 mostra status/assunto/marcos; chave errada = mesma mensagem de protocolo inexistente; 429 informa espera (`quickstart.md` §3)

### Tests for User Story 3 (TDD — RED first)

- [X] T046 [P] [US3] Escrever testes (RED) `ci-api-v2/src/modules/ouvidoria/test/use-cases/consulta-publica.use-case.spec.ts` (estender o spec existente) — CT-OUV-PUB-007: `statusLabel` vem de `PUBLIC_MANIFESTACAO_STATUS_LABEL` para os 6 status internos; 404 idêntico para protocolo inexistente e chave incorreta
- [X] T047 [P] [US3] Escrever testes (RED) RTL `ci-client-v2/apps/publico/src/modules/manifestacao/pages/ConsultaProtocoloPage.test.tsx` — 200 renderiza `statusLabel`/`marcos`; 404 mensagem genérica; 429 tempo de espera

### Implementation for User Story 3

- [X] T048 [P] [US3] Adicionar `PUBLIC_MANIFESTACAO_STATUS_LABEL` em `ci-api-v2/src/modules/ouvidoria/ouvidoria.mapper.ts` (`draft→Recebida`, `in_review|forwarding→Em análise`, `answered→Respondida`, `closed|closed_unresolved→Encerrada`) — **não** alterar `MANIFESTACAO_STATUS_LABEL` interno
- [X] T049 [US3] Usar o mapa público em `ci-api-v2/src/modules/ouvidoria/use-cases/consulta-publica.use-case.ts` (GREEN T046); shape da resposta inalterado
- [X] T050 [P] [US3] Implementar `ci-client-v2/apps/publico/src/modules/manifestacao/api/consulta.ts` — `GET /ouvidoria/consulta` + schema Zod de resposta
- [X] T051 [US3] Criar `ci-client-v2/apps/publico/src/modules/manifestacao/pages/ConsultaProtocoloPage.tsx` (form protocolo+chave, card de status/marcos/resposta, paleta AGEMAN) (GREEN T047)
- [X] T052 [US3] Ligar entrada “Consultar protocolo” em `WelcomePage.tsx` (`open-consulta`) e a tela `consulta` em `ci-client-v2/apps/publico/src/main.tsx`

**Checkpoint**: US3 independente da UI do chatbot (pode ser testada com curl + tela); US1/US2 intactas

---

## Phase 6: User Story 4 — Usar o portal com recursos de acessibilidade (Priority: P3)

**Goal**: Fonte, contraste para daltonismo e leitura em voz alta (pt-BR) em **todas** as telas, inclusive consulta

**Independent Test**: Ativar cada recurso isoladamente e em conjunto; nenhum botão/conteúdo cortado (`quickstart.md` §4)

### Tests for User Story 4 (TDD — RED first)

- [X] T053 [P] [US4] Escrever testes (RED) `ci-client-v2/apps/publico/src/modules/manifestacao/context/AccessibilityContext.test.tsx` — persistência em `localStorage` de `fontSize`/`colorMode`/`speech`; defaults; toggle

### Implementation for User Story 4

- [X] T054 [US4] Portar `ci-client-v2/apps/publico/src/modules/manifestacao/context/AccessibilityContext.tsx` da v1 (GREEN T053)
- [X] T055 [P] [US4] Portar `ci-client-v2/apps/publico/src/modules/manifestacao/components/accessibility/AccessibilityWidget.tsx` da v1
- [X] T056 [US4] Envolver o app com `AccessibilityProvider` em `ci-client-v2/apps/publico/src/main.tsx` e renderizar o widget em welcome/chatbot/consulta

**Checkpoint**: US4 não altera contratos de API; US1–US3 permanecem utilizáveis com a11y ligado

---

## Phase 7: User Story 5 — Tirar dúvidas rápidas antes de registrar (Priority: P3)

**Goal**: Widget FAQ “Tucaninho” na landing; resposta de acompanhamento menciona a tela de consulta (FR do US5)

**Independent Test**: Abrir o widget e confirmar respostas de serviços fiscalizados e de “como acompanhar” mencionando protocolo + chave (`quickstart.md` §5)

### Tests for User Story 5 (TDD — RED first)

- [X] T057 [P] [US5] Escrever testes (RED) `ci-client-v2/apps/publico/src/modules/manifestacao/components/FloatingAgeWidget.test.tsx` — pergunta de acompanhamento menciona consulta por protocolo e chave

### Implementation for User Story 5

- [X] T058 [US5] Portar `ci-client-v2/apps/publico/src/modules/manifestacao/components/FloatingAgeWidget.tsx` da v1 (FAQ institucional fixo, sem IA) e atualizar a resposta de acompanhamento para citar a tela de consulta (GREEN T057)
- [X] T059 [US5] Ligar o widget em `WelcomePage.tsx` / `main.tsx` via evento `open-age-chat`, disponível a qualquer momento na página institucional

**Checkpoint**: US5 complementar; não bloqueia registro nem consulta

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Pipeline de deploy (dívida #1 do research R9), regressão e validação do quickstart

- [X] T060 [P] Incluir `@ci/publico` no pipeline: `ci-client-v2/package.json` (script de build se faltar), `ci-client-v2/Dockerfile` (stage nginx), `ci-client-v2/compose.dev.yaml` (serviço `publico` porta 5175) e o workflow de deploy que hoje só publica `@ci/web` / `@ci/admin-saas`
- [X] T061 [P] Rodar regressão `cd ci-api-v2; npm test -- --testPathPatterns=ouvidoria` — fluxo autenticado (draft/encaminhar/encerrar/responder) não pode quebrar
- [X] T062 [P] Rodar `cd ci-client-v2/apps/publico; npm test` e `npm run typecheck` — **50/50 Vitest GREEN** + typecheck OK (follow-up pós-orquestrador frontend)
- [ ] T063 Validar `civ2-docs/specs/043-ouvidoria-publica-ageman/quickstart.md` §§1–5 + anti-robô — **parcial (2026-09-11)** — quickstart corrigido ([T063 validar quickstart §§1-5](dc731f81-8f9f-4f0f-a7b2-017ec1f8ddc7): `dev:publico`, matrícula API, throttle consulta, seção «Validação T063»); anti-robô + contratos cobertos por Jest/Vitest (454 API + 50 client GREEN pós-T061/T062). **Manual restante**: browser E2E §§1–2 (chatbot completo + anexos reais), consulta com protocolo vivo §3, inspeção visual a11y §4, FAQ institucional §5, reCAPTCHA real com secret Google.
- [X] T064 Remover leftovers do stepper (`ManifestacaoGuidedForm.tsx`, `form-schema.ts`, `form-schema.test.ts` se ainda existirem) e imports mortos em `ci-client-v2/apps/publico/src/`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: sem dependências
- **Foundational (Phase 2)**: depende da Phase 1 — **bloqueia todas as stories**
- **US1 (Phase 3)**: depende da Phase 2 — MVP
- **US2 (Phase 4)**: depende da US1 (bind usa `manifestacaoId` do create) — anexos opcionais no registro
- **US3 (Phase 5)**: API de consulta só depende da Phase 2; a tela client pode começar em paralelo com US2; validação E2E usa protocolo gerado na US1
- **US4 (Phase 6)**: só client; pode começar após T027 (main.tsx)
- **US5 (Phase 7)**: só client; melhor após US3 (copy da FAQ cita consulta) — pode stubar a menção se US3 atrasar
- **Polish (Phase 8)**: após as stories desejadas

### User Story Dependencies

| Story | Depende de | Independente para testar? |
| --- | --- | --- |
| US1 (P1) | Phase 2 | Sim — registro sem anexos |
| US2 (P2) | US1 (bind) | Sim — um envio com arquivo |
| US3 (P2) | Phase 2 (API); US1 para demo E2E | Sim — curl + tela com fixture/chave conhecida |
| US4 (P3) | T027 | Sim — toggles de a11y |
| US5 (P3) | WelcomePage (T034) | Sim — widget FAQ |

### Within Each User Story

- Testes RED **antes** da implementação
- Repository antes de use-case; use-case antes de ligar o client
- API client (`api/*.ts`) antes dos componentes que consomem
- Story completa e validada no checkpoint antes de avançar prioridade

### Parallel Opportunities

- **Phase 1**: T001–T007 todos [P]
- **Phase 2 RED**: T008–T012 [P]
- **Phase 2 GREEN**: T013+T014+T017+T019+T020+T022–T026 [P] após T015/T016/T018 no caminho crítico
- **US1 RED**: T028–T030 [P]
- **US1 GREEN**: T033+T034 [P] enquanto T031/T032 fecham a API
- **US2 RED**: T038+T039 [P]
- **US3** API (T046/T048/T049) em paralelo com **US2** client (T044/T045)
- **US4** pode rodar em paralelo com US2/US3 após T027

### Parallel Example: User Story 1

```text
# RED em paralelo:
T028 create-manifestacao-publica.repository.spec.ts
T029 criar-manifestacao-publica.use-case.spec.ts
T030 PublicChatbotForm.test.tsx

# Depois GREEN API sequencial (T031 → T032), client em paralelo:
T033 public-manifestacao.ts + programas.ts
T034 WelcomePage.tsx
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Phase 1: Setup
2. Phase 2: Foundational (**crítico**)
3. Phase 3: US1
4. **STOP and VALIDATE** — `quickstart.md` §1
5. Demo: cidadão registra e recebe protocolo + chave

### Incremental Delivery

1. Setup + Foundational → infra pronta
2. US1 → MVP (registro conversacional)
3. US2 → anexos reais
4. US3 → consulta de protocolo
5. US4 → acessibilidade
6. US5 → FAQ Tucaninho
7. Polish → deploy `@ci/publico` + regressão

### Parallel Team Strategy

| Dev | Fase | Entrega |
| --- | --- | --- |
| A | Phase 2 + US1 API | Schema, reCAPTCHA, create/persist, catálogo |
| B | Phase 2 client + US1 UI | Welcome + chatbot + review |
| C | US2 (após T032) | Migration + presign + bind + input |
| — | US3 API pode começar após Phase 2 | Label público + tela consulta |

---

## Notes

- **Não** criar enum paralelo em português para `tipo` — reusar `manifestacaoTipo` (research R1)
- **Não** estender `GET /ouvidoria/publico/catalogos` — rota nova `GET /ouvidoria/publico/programas`
- **Não** aplicar paleta Mint em `apps/publico` — identidade AGEMAN da v1 (FR-019)
- `createdByUserId` no fluxo público fica `undefined` (bugfix research R2)
- Rate limit em memória (`CheckPublicRateLimitRepository`) **não** migrar nesta feature (research R9, prioridade 8)
- Links externos de anexo fora de escopo (só `kind: file`)
- Commit após cada task ou grupo lógico; parar em qualquer checkpoint para validar a story
- Skills na implementação: `tdd` + `testing-conventions` (API), `zod-validation-sanitization`, `nestjs-module-scaffold`, `prisma-schema-workflow` (US2), `vite-react-best-practices` + `ui-ux-pro-max` (client, paleta tenant)
