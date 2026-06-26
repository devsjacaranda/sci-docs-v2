# Research: Arquitetura Modular Espelho da API (Client)

**Feature**: 004-client-domain-mirror  
**Date**: 2026-06-06

## R1 — Estratégia de migração

**Decision**: Big bang em entrega única, com ordem interna scaffold → shell/shared → domínios → router/cleanup.

**Rationale**: Stakeholder escolheu big bang na spec. Ordem interna reduz janela de imports quebrados: infra primeiro, domínios depois, remoção de legado por último. Typecheck/lint após cada sub-milestone como checkpoint local (não commits parciais obrigatórios se PR único).

**Alternatives considered**:

| Alternativa | Motivo de rejeição |
|-------------|-------------------|
| Incremental por domínio (coexistência legado) | Spec FR-006 exige big bang; pastas legadas não podem permanecer |
| Feature flags por módulo | Over-engineering para refatoração de pastas sem mudança de comportamento |
| Symlinks temporários | Frágil no Windows; confunde IDEs |

---

## R2 — Layout de módulo e camadas

**Decision**: Cada domínio em `modules/<slug>/` com camadas mínimas `pages/`, `components/`, `api/` quando há UI; camadas opcionais `hooks/`, `lib/`, `context/` conforme necessidade. Slugs idênticos à API: `auth`, `address`, `ouvidoria`, `permissao`, `setor`, `tenant`, `audit`.

**Rationale**: Alinha com skill `react-colocation` (organizar por feature/domínio) e Principle V da API (módulos por domínio). Camadas frontend mapeiam mentalmente: `api/` ≈ client HTTP do controller; `pages/` ≈ telas; `components/` ≈ UI do domínio.

**Alternatives considered**:

| Alternativa | Motivo de rejeição |
|-------------|-------------------|
| Flat `modules/<slug>/*.tsx` sem subcamadas | Não espelha profundidade escolhida pelo stakeholder |
| `features/` em vez de `modules/` | Quebra paridade de nomenclatura com `ci-api-v2/src/modules/` |
| Pacote npm por domínio (`packages/ouvidoria`) | Spec FR-005: apenas pastas; Turborepo packages inalterados |

---

## R3 — shell vs shared

**Decision**:

- **`modules/shell/`**: infraestrutura SPA — layout, navegação, mocks genéricos, config de telas, contextos globais (tema, filtro licença), `api-client` base, `ScreenPage` orquestrador
- **`modules/shared/`**: código usado por **2+ domínios de negócio** — ex.: `AccessDenied403` (permissao + setor + ouvidoria via ScreenPage)

**Rationale**: Distinção explícita na spec FR-003/FR-004. Shell ≠ domínio de negócio; shared ≠ infra de plataforma.

**Alternatives considered**:

| Alternativa | Motivo de rejeição |
|-------------|-------------------|
| Tudo em shell | shared perde semântica; domínios acoplados a infra |
| `common/` na raiz (espelho API) | Stakeholder escolheu `shell/` dentro de `modules/` |
| AccessDenied403 em permissao | Usado por setor e fluxos admin globais — viola fronteira |

---

## R4 — Composition root (ScreenPage)

**Decision**: `modules/shell/pages/ScreenPage.tsx` é o **composition root** config-driven e é a **única exceção** autorizada a importar barrels públicos de domínios (`@/modules/permissao`, `@/modules/setor`, `@/modules/audit`).

**Rationale**: `ScreenPage` despacha painéis admin e mock por `screen.customDashboard` — padrão análogo a `AppModule` importando feature modules no Nest. Proibir totalmente imports shell→domínio exigiria reescrever `screens.ts` em rotas dedicadas (regressão UX). Domínios continuam proibidos de importar internals uns dos outros.

**Alternatives considered**:

| Alternativa | Motivo de rejeição |
|-------------|-------------------|
| Mover ScreenPage para `app/` | Mistura bootstrap com orquestração de telas mock |
| Registry injetado por domínios em runtime | Complexidade desproporcional para v1 |
| AuditLogsPanel permanece em shell/mock | Domínio audit perderia paridade; spec FR-007 |

---

## R5 — Boundaries enforcement

**Decision**: ESLint `no-restricted-imports` em `apps/web/eslint.config.js` + script PowerShell `scripts/verify-module-layout.ps1` (zero arquivos em pastas legadas).

**Rationale**: `eslint-plugin-boundaries` adiciona dependência e config não trivial. Regras mínimas cobrem 90% dos casos na v1:

- Proibir `@/pages/`, `@/components/`, `@/lib/` (legado)
- Proibir deep imports cross-domain (`@/modules/ouvidoria/components/...` de outro domínio)
- Permitir `@/modules/<dominio>` (barrel) e `@/modules/shared/...`

**Alternatives considered**:

| Alternativa | Motivo de rejeição |
|-------------|-------------------|
| eslint-plugin-boundaries | Setup extra; avaliar na v2 se regras flat insuficientes |
| Apenas code review | Big bang com ~92 arquivos — erro humano provável |
| TypeScript path aliases por domínio | Não impede imports ilegais |

---

## R6 — Split de clients HTTP

**Decision**:

| Arquivo origem | Destino | Endpoints |
|----------------|---------|-----------|
| `lib/admin-api.ts` | `permissao/api/` | `/permissoes/modulos`, `/permissoes/notificacoes` |
| `lib/admin-api.ts` | `setor/api/` | `/setores`, `/setores/:id/membros`, `/users` |
| `lib/ouvidoria-api.ts` | `address/api/` | `/address/municipios` |
| `lib/ouvidoria-api.ts` | `ouvidoria/api/` | `/ouvidoria/manifestacoes/*` |
| `lib/api-client.ts` | `shell/api/` | base fetch + `X-Tenant-ID` + auth header |
| `lib/auth.ts` | `auth/api/` | login/me |

**Rationale**: FR-012 exige fronteiras de domínio. Split segue prefixos REST existentes. Tipos compartilhados (`AddressInput`) ficam em `address/api/types.ts`; ouvidoria re-exporta ou importa via barrel `@/modules/address`.

**Alternatives considered**:

| Alternativa | Motivo de rejeição |
|-------------|-------------------|
| Manter admin-api monolítico | Viola FR-012 e paridade com módulos API |
| Mover api-client para pacote `@ci/domain` | Mistura infra HTTP com tipos de licença |

---

## R7 — Módulos scaffold (tenant, audit, address)

**Decision**:

- **address**: client HTTP mínimo + barrel; tipos de endereço
- **tenant**: `README.md` only — header tenant permanece em `shell/api/api-client.ts` (defer UI)
- **audit**: `AuditLogsPanel` extraído de `SpecialPanels.tsx` → `audit/components/`; demais panels em `SpecialPanels` permanecem em shell/mock

**Rationale**: Spec FR-007 exige existência dos módulos. Tenant não tem UI client hoje; forçar pasta vazia com README evita pasta morta sem documentação. Audit tem UI mock concreta (Cedro hub).

**Alternatives considered**:

| Alternativa | Motivo de rejeição |
|-------------|-------------------|
| AuditLogsPanel em shell/mock | Perde paridade slug audit |
| tenant/ com api/ duplicando shell | Duplicação de TENANT_ID config |

---

## R8 — Barrels públicos (index.ts)

**Decision**: Cada domínio exporta API pública em `modules/<slug>/index.ts`. Cross-domain imports MUST use barrel root only (`@/modules/address`, not `@/modules/address/api/municipios`).

**Rationale**: FR-008 — encapsulamento entre domínios. Facilita refatoração interna sem quebrar consumidores.

**Example — address/index.ts**:

```typescript
export { searchMunicipios } from './api/municipios';
export type { AddressInput, MunicipioOption } from './api/types';
```

**Example — ouvidoria/index.ts**:

```typescript
export { ManifestacoesListPage } from './pages/ManifestacoesListPage';
// lazy helpers for router...
```

---

## R9 — Pacotes Turborepo

**Decision**: Zero alteração em `packages/ui`, `packages/domain`, `packages/typescript-config`. Imports `@ci/ui` e `@ci/domain` permanecem válidos de qualquer módulo.

**Rationale**: Spec FR-005. Reorganização é intra-app apenas.

**Alternatives considered**:

| Alternativa | Motivo de rejeição |
|-------------|-------------------|
| Dissolver @ci/domain nos módulos | Stakeholder escolheu manter packages |
| @ci/domain por domínio | Escopo explícito: apenas pastas |
