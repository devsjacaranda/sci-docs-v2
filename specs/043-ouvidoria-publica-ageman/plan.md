# Implementation Plan: Ouvidoria Pública AGEMAN (v2)

**Branch**: `043-ouvidoria-publica-ageman` | **Date**: 2026-09-11 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/043-ouvidoria-publica-ageman/spec.md`

## Summary

Recriar em `ci-client-v2/apps/publico` a experiência pública de ouvidoria da v1 (AGEMAN: `WelcomePage` + `PublicChatbotForm` + `ReviewFormModal` + `FloatingAgeWidget` + acessibilidade), com **layout e fluxo idênticos**, conectada aos endpoints reais da API v2. Fecha os gaps de paridade identificados na exploração: expande `criarManifestacaoPublicaBodySchema` de 2 para 6 categorias (água/transporte/iluminação/lixo/zona azul/institucional), adiciona `tipo`, contato e persistência de endereço, substitui o stub de anexos por upload real (reaproveitando `StorageService`), substitui o stub de anti-robô por reCAPTCHA v3 real (falha fechada), simplifica o status exposto ao cidadão na consulta (capacidade nova em relação à v1, já parcialmente implementada), e inclui `@ci/publico` no pipeline de build/deploy do monorepo.

**API** (`ci-api-v2`): módulo `ouvidoria` existente — schema/repository/use-cases das rotas `@Public()` já mapeadas (`ouvidoria.controller.ts:480-507`), sem rotas novas exceto uma extensão de catálogo. Reaproveita `CreateAddressRepository`, `manifestacaoTipo` (enum canônico já existente), `StorageService`, `AGEMAN_MOTIVOS_BY_PROGRAMA`.

**Client** (`ci-client-v2/apps/publico`): substituição do wizard/stepper atual (`ManifestacaoGuidedForm.tsx`) pela experiência conversacional portada da v1, com `react-hook-form` + `@hookform/resolvers/zod` + `@tanstack/react-query` + `@ci/shared` (`createApiClient`, sem uso de sessão/token). Nova tela `ConsultaProtocoloPage.tsx` (capacidade sem equivalente na v1).

## Technical Context

**Language/Version**: TypeScript 5.9 (strict) · Node.js 20+ LTS (mesma versão do resto do monorepo)

**Primary Dependencies**:

| Pacote | Stack |
| --- | --- |
| **ci-api-v2** | NestJS 11, Fastify, Pino, Zod v4 (`nestjs-zod`), Prisma 7, PostgreSQL, `StorageService` (S3/Wasabi + fallback local), `bcryptjs` |
| **ci-client-v2/apps/publico** | React 19, Vite 8, Tailwind v4 (paleta própria do tenant AGEMAN — não a Mint do workspace), `react-hook-form` + `@hookform/resolvers/zod`, `@tanstack/react-query`, `@ci/shared` (`createApiClient`), Zod v3, `lucide-react` |

**Storage**: PostgreSQL existente (`Manifestacao`, `ManifestacaoAnexo`, `Address`, `Municipio`) + **1 tabela nova** (migration) para anexos temporários públicos, com `tenantId`. Arquivo: Wasabi/S3 via `StorageService.presignUpload` (já em produção no fluxo autenticado), fallback local em dev sem credenciais.

**Testing**:

| Camada | API | Client |
| --- | --- | --- |
| Unitário | Jest — schemas, use-cases, repositórios | Vitest — schema Zod, masks, zonas |
| Contrato | fixtures + `safeParse` | fixtures JSON + `parse` |
| Integração | use-cases + Prisma mock (reCAPTCHA via mock de `fetch`) | RTL do fluxo do assistente (mock de API) |

**Target Platform**: SPA pública mobile-first (sem login) + API REST Fastify já em produção multi-tenant.

**Project Type**: Web application (frontend + backend) — estende dois pacotes já existentes no monorepo; não cria projeto novo.

**Performance Goals**: alinhados à spec — registro completo < 5 min (SC-001); consulta de protocolo < 30s (SC-003); throttle já configurado permanece (5/min criação, 10/min anexos e consulta).

**Constraints**:

- TDD obrigatório (Constitution II) — RED antes de qualquer schema/repository/use-case alterado.
- Zod only — sem `class-validator` (Constitution III).
- Tenant via `X-Tenant-ID` + AsyncLocalStorage — rotas `@Public()` já resolvem tenant pelo header, sem JWT.
- Anti-robô com **falha fechada** (Clarifications Q3): se o `siteverify` não responder, bloquear o envio.
- Retenção de dados segue a política já vigente no módulo de Ouvidoria — nenhuma regra nova (Clarifications Q1).
- Status exibido ao cidadão é **simplificado** (Recebida/Em análise/Respondida/Encerrada) — a rota `GET /ouvidoria/consulta` hoje reutiliza `MANIFESTACAO_STATUS_LABEL` (rótulo **interno** granular); passa a usar um mapeamento público dedicado (Clarifications Q2).
- Layout/UX idênticos à v1 — paleta emerald/teal própria do tenant, desvio justificado da paleta Mint do workspace (decisão já confirmada com o usuário antes do `/speckit-specify`; ver Constitution Check).
- Limite de anexo público alinhado ao padrão interno já vigente (`MAX_ANEXO_BYTES` = 30MB, `ALLOWED_MIME_TYPES` de `ouvidoria-anexo.constants.ts`), não ao limite mais permissivo da v1 (50MB).
- `apps/publico` ainda não consta em `turbo.json` / `Dockerfile` / `compose.dev.yaml` / workflow de deploy — precisa entrar nesta entrega para o portal ser utilizável em produção.

**Scale/Scope**: 1 tenant (AGEMAN) nesta etapa; 6 categorias de manifestação; ~15 arquivos novos/alterados em `ci-api-v2/src/modules/ouvidoria/`; ~25 arquivos portados/criados em `ci-client-v2/apps/publico/`. Reaproveita infraestrutura já existente (`StorageService`, `CreateAddressRepository`, enum `ManifestacaoTipo`, catálogo AGEMAN de 77 motivos) em vez de recriar do zero.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Princípio | Status | Notas |
| --- | --- | --- |
| I. Spec-Driven | PASS | Spec 043 + `/speckit-clarify` (3 perguntas) + checklist 16/16 validados |
| II. Test-First | PASS | [contracts/test-strategy.md](./contracts/test-strategy.md) — RED antes de schemas/repository/use-cases alterados, em ambos os pacotes |
| III. Stack fixa | PASS | NestJS 11 + Prisma 7 + Zod v4 na API; React 19 + Vite 8 + Tailwind v4 no client; zero `class-validator`; zero dependência de infra nova (reusa Wasabi/S3 já configurado) |
| III. Desvio de paleta (justificado) | PASS COM NOTA | `apps/publico` mantém a identidade visual emerald/teal própria da v1/AGEMAN, não a paleta Mint do workspace — é marca pública do tenant, não UI administrativa interna; decisão já confirmada com o usuário antes do `/speckit-specify` |
| IV. Multi-tenant | PASS | Rotas `@Public()` resolvem `tenantId` via `X-Tenant-ID` + ALS; a nova tabela de anexo temporário público inclui `tenantId` |
| IV. FK → `User` | PASS (corrige bug existente) | `CreateManifestacaoPublicaRepository` hoje atribui `createdByUserId` a um usuário **arbitrário** do tenant (`user.findFirst`) — bug pré-existente; passa a ficar `undefined` (campo já é `String?`), pois não há ator autenticado no fluxo público |
| V. Clean code / modularidade | PASS | 1 arquivo = 1 operação em `repository/`/`use-cases/`; client em `apps/publico/src/modules/manifestacao/` com `components/`, `pages/`, `api/`, `hooks/`, `schemas/`, `constants/`, `utils/`, `context/` |

**Post-design re-check** (após Phase 1): nenhuma tabela existente alterada de forma destrutiva (migration additive); nenhuma rota de escrita nova além das já existentes (`POST manifestacoes`/`POST anexos` já eram públicas — só deixam de ser stub); reCAPTCHA e storage reaproveitam padrões já usados no fluxo autenticado. Sem violações não justificadas — sem entradas em Complexity Tracking.

## Project Structure

### Documentation (this feature)

```text
civ2-docs/specs/043-ouvidoria-publica-ageman/
├── plan.md              # este arquivo
├── research.md          # Phase 0
├── data-model.md         # Phase 1
├── quickstart.md         # Phase 1
├── contracts/
│   ├── rest-api-ouvidoria-publica.md
│   ├── client-publico-ui.md
│   └── test-strategy.md
└── tasks.md              # Phase 2 — /speckit-tasks (ainda não criado)
```

### Source Code (repository root)

```text
ci-api-v2/
├── prisma/
│   ├── schema/manifestacao.prisma          # + model ManifestacaoAnexoPublicoTemp
│   └── migrations/<timestamp>_ouvidoria_publica_anexo_temp/
└── src/modules/
    ├── address/repository/address.repositories.ts        # reaproveitado (CreateAddressRepository)
    └── ouvidoria/
        ├── ouvidoria.schemas.ts                # criarManifestacaoPublicaBodySchema expandido
        ├── ouvidoria.controller.ts              # rota de catálogo público estendida
        ├── ouvidoria.mapper.ts                  # + PUBLIC_MANIFESTACAO_STATUS_LABEL
        ├── lib/
        │   ├── ageman-catalog.ts                # + código '6' institucional
        │   └── numero-personalizado.ts          # + PROGRAMA_CODE['institucional'] = '6'
        ├── repository/
        │   ├── create-manifestacao-publica.repository.ts   # persiste tipo/contato/endereço; corrige createdByUserId
        │   ├── verify-public-challenge.repository.ts        # reCAPTCHA v3 real + bypass dev
        │   ├── bind-anexos-publicos.repository.ts           # cria ManifestacaoAnexo real
        │   ├── store-public-temp-anexo.repository.ts        # Prisma em vez de Map em memória
        │   └── find-public-temp-anexo.repository.ts         # idem, Prisma
        ├── use-cases/
        │   ├── criar-manifestacao-publica.use-case.ts        # tipo + contato; bind por id (não por protocol)
        │   ├── upload-anexo-publico.use-case.ts              # presign real via StorageService
        │   └── consulta-publica.use-case.ts                  # usa PUBLIC_MANIFESTACAO_STATUS_LABEL
        └── test/
            ├── use-cases/ (criar-manifestacao-publica, upload-anexo-publico, consulta-publica)
            └── repository/ (create-manifestacao-publica, verify-public-challenge, bind-anexos-publicos)

ci-client-v2/apps/publico/
├── package.json                             # + react-hook-form, @hookform/resolvers, @tanstack/react-query, @ci/shared
├── .env.ageman.example                      # + VITE_RECAPTCHA_SITE_KEY, VITE_TENANT_*
└── src/
    ├── main.tsx                             # screen state welcome|chatbot|consulta + eventos customizados
    ├── config/tenant-config.ts
    ├── assets/                               # imagens/áudio copiados da v1
    └── modules/manifestacao/
        ├── pages/ConsultaProtocoloPage.tsx   # tela nova
        ├── components/
        │   ├── WelcomePage.tsx
        │   ├── PublicChatbotForm.tsx
        │   ├── ReviewFormModal.tsx
        │   ├── PublicAttachmentsInput.tsx
        │   ├── FloatingAgeWidget.tsx
        │   ├── layout/Header.tsx
        │   ├── layout/Footer.tsx
        │   └── accessibility/AccessibilityWidget.tsx
        ├── context/AccessibilityContext.tsx
        ├── hooks/use-recaptcha.ts
        ├── hooks/use-viacep.ts
        ├── constants/manifestation-options.ts   # 6 programas + TIPO_MANIFESTACAO_OPTIONS
        ├── schemas/
        │   ├── ageman-public-fields.ts
        │   └── public-manifestacao.schema.ts    # espelha o contrato v2 expandido
        ├── utils/masks.ts
        ├── utils/manaus-zones.ts
        └── api/
            ├── public-manifestacao.ts
            ├── anexos-publicos.ts
            └── consulta.ts

ci-client-v2/ (raiz do frontend monorepo)
├── turbo.json                                # + @ci/publico no pipeline de build
├── Dockerfile                                # + stage nginx para @ci/publico
└── compose.dev.yaml                          # + serviço publico

.github/workflows/<deploy>.yml                # + build/publish @ci/publico
```

**Structure Decision**: nenhum projeto novo — estende o módulo de domínio `ouvidoria` já existente em `ci-api-v2` (mesmo padrão `repository/` + `use-cases/` + `ouvidoria.schemas.ts`) e o app `@ci/publico` já existente em `ci-client-v2` (mesmo padrão `pages/`, `components/`, `api/`, `hooks/` usado por `apps/web`/`apps/admin-saas`, adaptado sem React Router — igual à v1 AGEMAN, orquestração por estado de tela + eventos customizados em `main.tsx`).

## Complexity Tracking

Nenhuma violação constitucional não justificada.

| Item | Por que é necessário | Alternativa mais simples rejeitada porque |
| --- | --- | --- |
| Paleta própria (emerald/teal) em vez de Mint | `apps/publico` é a marca pública do tenant AGEMAN (citizen-facing), replicada 1:1 da v1 por decisão explícita do usuário | Aplicar a paleta Mint quebraria a paridade visual exigida pela spec (FR-019) e a identidade institucional já validada do tenant |
