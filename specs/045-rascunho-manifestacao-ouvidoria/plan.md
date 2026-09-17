# Implementation Plan: Recuperar último rascunho de manifestação (Ouvidoria)

**Branch**: `045-rascunho-manifestacao-ouvidoria` | **Date**: 2026-09-14 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `civ2-docs/specs/045-rascunho-manifestacao-ouvidoria/spec.md`

## Summary

Operadores autenticados da Ouvidoria perdem trabalho não enviado quando a API, a internet ou o token cai durante o preenchimento do assistente de **nova** manifestação (`/ouvidoria/manifestacoes/nova`) — o `apiFetch` do `@ci/shared` detecta 401/erro de rede, força logout (`registerSessionLostHandler`) e redireciona para `/login`, descartando o estado em memória do React. A solução: gravar automaticamente um **rascunho local recuperável** (IndexedDB, escopado por tenant+operador, TTL 24h) durante o preenchimento, e oferecer um **convite de retomada acima da tabela** em `/ouvidoria/manifestacoes`. O backend expõe um endpoint dedicado de **retomabilidade** para revalidar, antes de qualquer retomada, se o rascunho referenciado ainda é editável — nunca confiando ciegamente na cópia local.

Essa abordagem exige uma **exceção documentada e estreita** à `SC-010` (spec [038](../038-migracao-modulos-v1/spec.md)), que proíbe dado de negócio dependente de armazenamento do navegador nos módulos migrados. A exceção foi negociada explicitamente com o usuário nesta sessão de planejamento (ver Constitution Check) e já registrada em `038/spec.md` e `038/research.md`.

## Technical Context

**Language/Version**: TypeScript 5.9+ (Node 22 na API via NestJS 11; navegador evergreen no client via Vite 8/React 19)

**Primary Dependencies**:
- Client: React 19, React Router 7, Zod 3 (schema já existente `manifestacao-draft.schema.ts`), **`idb`** (novo — wrapper leve sobre IndexedDB, ~1.2KB gzip, mesma autoria do Workbox usado no `vite-plugin-pwa` já presente) para acesso assíncrono/tipado ao armazenamento local
- Testes client: Vitest + **`fake-indexeddb`** (novo, devDependency) para simular IndexedDB em jsdom
- API: NestJS 11, Fastify, Zod (`nestjs-zod`), Prisma 7 — reaproveita `RequireManifestacaoRepository` e o enum `ManifestacaoStatus` já existentes; **nenhum novo modelo Prisma**

**Storage**:
- Local (novo, exceção SC-010): IndexedDB, 1 object store (`rascunho-local`), 1 registro por `tenantId:userId` (chave composta) — dados do formulário (mesmo shape de `CreateManifestacaoDraftInput`) + etapa do assistente + anexos pendentes (como `Blob`) + timestamps
- Servidor (existente, inalterado): PostgreSQL via Prisma — tabela `Manifestacao` já suporta status `draft`

**Testing**: Vitest (client, `apps/web`) · Jest (API, `ci-api-v2`) — TDD RED→GREEN→REFACTOR obrigatório (constitution II)

**Target Platform**: Navegador web evergreen (desktop + mobile), SPA `apps/web` autenticada — fora do canal público

**Project Type**: Web application (frontend `ci-client-v2/apps/web` + backend `ci-api-v2`) — monorepo já estruturado, sem novo pacote

**Performance Goals**: gravação local não bloqueia a digitação (IndexedDB é assíncrono); no máximo 1 escrita local a cada 5s por campo alterado + 1 escrita imediata a cada mudança de etapa (FR-001); consulta de retomabilidade é 1 `GET` leve (sem payload de detalhe completo) ao abrir a lista

**Constraints**:
- Rascunho local expira em **24h** (FR-015)
- Anexos locais limitados a **30MB no total / 5 arquivos por rascunho** (alinhado a `MAX_ANEXO_BYTES = 30MB` já usado em `ouvidoria-anexo.constants.ts` para upload individual — ver `research.md` R-ANEXOS)
- Exceção SC-010 restrita aos arquivos em `modules/ouvidoria/lib/rascunho-local/**` (allowlist explícito no guardrail `no-business-storage.test.ts`)
- Falha técnica na consulta de retomabilidade → oculta o convite (postura conservadora, FR-016)

**Scale/Scope**: 1 slot de rascunho recuperável por operador+tenant (sem histórico); escopo apenas ao assistente de **nova** manifestação interna — canal público e edição de manifestação existente ficam fora (FR-013)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Princípio | Avaliação |
|---|---|
| I. Spec-Driven Development | ✅ specify → clarify → **plan** (aqui) → tasks → implement, nesta ordem |
| II. Test-First | ✅ TDD obrigatório em todo código novo (client e API); ver `contracts/test-strategy.md` |
| III. Stack fixa | ✅ React 19/Vite 8/Zod (client), NestJS 11/Fastify/Zod/Prisma (API) — sem desvio de stack. `idb`/`fake-indexeddb` são dependências pontuais de utilidade (não mudam a stack), documentadas abaixo |
| IV. Multi-tenant e licenças | ✅ Escopo local por `tenantId:userId`; endpoint de retomabilidade reaplica `X-Tenant-ID` + `AsyncLocalStorage` + `@RequireModulo('ouvidoria')` como todo endpoint do módulo |
| V. Clean code e modularidade | ✅ 1 arquivo = 1 operação (`use-cases/get-manifestacao-retomabilidade.use-case.ts`); client em `modules/ouvidoria/lib/rascunho-local/**` + `components/` — espelha padrão vivo do módulo |

### ⚠️ Violação a justificar: SC-010 (spec 038) — "nenhum dado de negócio em storage do navegador"

| Violação | Por que é necessária | Alternativa mais simples rejeitada e motivo |
|---|---|---|
| Uso de IndexedDB para persistir o rascunho local do assistente de nova manifestação em `modules/ouvidoria/lib/rascunho-local/**` | O cenário central da spec 045 é exatamente a API/internet/token cair **durante** o preenchimento — nesse momento não há "servidor" para persistir nada; sem armazenamento local, a perda de trabalho não enviado é garantida (o próprio problema que o usuário pediu para resolver) | **B) Manter SC-010 intacta, sem storage local** — rejeitada pelo usuário nesta sessão: dependeria só de autosave no servidor, que por definição não funciona quando a API está indisponível — anularia o valor central da feature. **C) Usar IndexedDB sem atualizar o guardrail/rationale** — rejeitada: contornaria a intenção da SC-010 em vez de resolver a tensão de forma auditável |

**Decisão registrada com o usuário** (`AskQuestion`, sessão `/speckit-plan` de 2026-09-14): opção **"amenda documentada"** — exceção estreita, escopada, com TTL, sempre revalidada no servidor, e allowlist explícito no teste de guardrail. Já refletida em `038/spec.md` (nota na SC-010) e `038/research.md` (addendum ao R15). Diferença crítica em relação ao anti-padrão do v1 que originou a SC-010: o rascunho da 045 é **visível na UI** (convite explícito) e **nunca mascara indisponibilidade como sucesso** — o v1 gravava silenciosamente e avisava "só neste navegador" como se fosse aceitável; a 045 sempre revalida no servidor antes de qualquer ação definitiva (FR-006/FR-016).

**Gate**: ✅ Aprovado para seguir com a exceção documentada acima. Reavaliar após Phase 1 (ver seção ao final deste documento).

## Project Structure

### Documentation (this feature)

```text
civ2-docs/specs/045-rascunho-manifestacao-ouvidoria/
├── spec.md                      # Já existente (specify + clarify)
├── plan.md                      # Este arquivo
├── research.md                  # Phase 0 (a seguir)
├── data-model.md                # Phase 1
├── quickstart.md                # Phase 1
├── contracts/
│   ├── rest-api-retomabilidade.md
│   └── test-strategy.md
└── tasks.md                     # Phase 2 (/speckit-tasks — não criado aqui)
```

### Source Code (repository root)

```text
ci-api-v2/src/modules/ouvidoria/
├── ouvidoria.controller.ts                              # + rota GET manifestacoes/:id/retomabilidade
├── use-cases/
│   └── get-manifestacao-retomabilidade.use-case.ts      # novo — 1 operação
├── repository/
│   └── manifestacao.repositories.ts                     # reaproveita RequireManifestacaoRepository (leitura)
└── test/use-cases/
    └── get-manifestacao-retomabilidade.use-case.spec.ts # novo (TDD)

ci-client-v2/apps/web/src/modules/ouvidoria/
├── lib/rascunho-local/                                  # novo diretório — única superfície com exceção SC-010
│   ├── rascunho-local-db.ts                             # abertura IndexedDB + schema do object store (idb)
│   ├── rascunho-local-key.ts                            # chave composta tenantId:userId
│   ├── rascunho-local-store.ts                          # put/get/delete/list (1 operação por arquivo)
│   ├── rascunho-local-expiry.ts                         # regra de 24h
│   ├── rascunho-local-anexos-limit.ts                   # regra de 30MB/5 arquivos
│   ├── use-rascunho-local-autosave.ts                   # hook: debounce por campo + salvaguarda 5s + por etapa
│   ├── use-ultimo-rascunho-convite.ts                    # hook: lê IndexedDB + chama retomabilidade (lista)
│   └── __tests__/*.test.ts                              # TDD, com fake-indexeddb
├── api/
│   └── manifestacoes.ts                                 # + getManifestacaoRetomabilidade(id)
├── components/list/
│   └── UltimoRascunhoBanner.tsx                          # convite acima da tabela + confirmação de descarte
├── pages/
│   ├── ManifestacoesListPage.tsx                         # + <UltimoRascunhoBanner /> acima de InstitutionalTableCard
│   └── ManifestacaoWizardPage.tsx                        # + hidratação/gravação via use-rascunho-local-autosave
└── __tests__/
    └── no-business-storage.test.ts                       # + allowlist explícito para lib/rascunho-local/**
```

**Structure Decision**: segue o padrão vivo do módulo (`ouvidoria/` em ambos os pacotes, camadas `use-cases/`+`repository/`+`*.schemas.ts` na API; `pages/`+`components/`+`api/`+`lib/` no client). Toda a superfície nova de armazenamento do navegador fica isolada em `lib/rascunho-local/**`, facilitando auditoria da exceção SC-010 e o allowlist do teste de guardrail.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|---|---|---|
| Exceção à SC-010 (IndexedDB em `modules/ouvidoria/lib/rascunho-local/**`) | Resiliência exatamente no cenário de API/internet/token indisponível — sem storage local, o problema central do usuário não tem solução possível | Autosave só no servidor não cobre o cenário motivador; usar storage sem documentar a exceção contornaria a governança sem resolvê-la |

## Post-Phase 1 Constitution Check (re-avaliação)

✅ Sem novas violações introduzidas pelo desenho de Phase 1 (`data-model.md`, `contracts/`). A única violação permanece a exceção SC-010 já justificada e documentada acima, com desenho concreto (TTL, allowlist, revalidação server-side) que cumpre os termos da decisão negociada com o usuário.
