# Implementation Plan: Shared Address Hooks

**Branch**: `006-shared-address-hooks` | **Date**: 2026-06-19 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/006-shared-address-hooks/spec.md`

## Summary

Implementar capacidades reutilizáveis de captura de endereço no **cliente web** (`ci-client-v2`), colocated em `modules/shared/`: hooks `useViaCep` e `useIbgeMunicipios` (fetch direto do browser para ViaCEP e IBGE), utilitários puros (`normalizeCep`, mapeadores), schemas Zod de contrato externo, componentes `AddressForm` e `AddressFields` (shadcn via `@ci/ui`), alinhados ao modelo canônico `Address`/`Municipio` da API. **Sem alterações em `ci-api-v2`**. Testes: **unitários**, **de componente** e **de contrato** (Vitest + Testing Library + MSW); **sem integração nem E2E**.

## Technical Context

**Language/Version**: TypeScript 6.x, React 19, Node.js 20 LTS

**Primary Dependencies**: Vite 8, Vitest 3.x, `@testing-library/react`, `@testing-library/user-event`, `jsdom`, `msw` (mock fetch em testes), Zod (schemas de contrato ViaCEP/IBGE), shadcn/ui via `@ci/ui`, Tailwind v4

**Storage**: N/A — hooks consultam serviços públicos on-demand; persistência permanece na API (`Address` Prisma)

**Testing**: Vitest (`npm run test` em `@ci/web`); três camadas obrigatórias:
- **Unit**: funções puras em `modules/shared/lib/` (`cep`, `via-cep`, `ibge-municipios`)
- **Component**: `AddressForm`, `AddressFields`, subcampos — `@testing-library/react` + user-event
- **Contract**: schemas Zod validam fixtures de ViaCEP/IBGE; testes garantem mapeamento → `AddressInput` canônico
- **Excluído**: testes de integração (fetch real) e E2E (Playwright/Cypress)

**Target Platform**: Browser SPA (`@ci/web`)

**Project Type**: Frontend-only — extensão de `modules/shared/`

**Performance Goals**: Lookup CEP &lt; 2s (SC-002); lista municípios por UF &lt; 1s (SC-003) em rede normal; debounce 300ms no CEP antes de fetch

**Constraints**:

- Modelo canônico: [address.prisma](../../ci-api-v2/prisma/schema/address.prisma) + [municipio.prisma](../../ci-api-v2/prisma/schema/municipio.prisma)
- Fetch direto browser → ViaCEP / IBGE (sem proxy API)
- Todos os artefatos em `modules/shared/` — proibida duplicação em `modules/address/` ou domínios
- Skills: `ui-ux-pro-max` (formulário shadcn, mint-palette), `vite-react-best-practices` (Vitest config, colocation)
- TDD obrigatório (constitution II): RED → GREEN → REFACTOR por camada de teste
- `AddressInput` existente em `modules/address/api/types.ts` migra/reexporta de `shared` para fonte única

**Scale/Scope**: ~20 arquivos TS/TSX novos + ~12 arquivos de teste; 0 endpoints API; 2 integrações externas (ViaCEP, IBGE)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Princípio | Status | Notas |
|-----------|--------|-------|
| I. Spec-Driven | ✅ PASS | Spec 006 validada; plano segue fluxo |
| II. Test-First | ✅ PASS | Vitest + unit + component + contract; TDD por função/hook/componente |
| III. Stack fixa | ✅ PASS | React 19 + Vite 8 + Tailwind v4 + shadcn; Zod para schemas client-side |
| IV. Multi-tenant/licenças | ✅ PASS | Endereço agnóstico a tenant/licença (spec assumption) |
| V. Modularidade | ✅ PASS | `modules/shared/` para reuso cross-domain; `modules/address/` consome shared |

**Post-design re-check**: Sem violações; Complexity Tracking vazio. Tipos canônicos centralizados em `shared/lib/address-types.ts`; `modules/address/` reexporta sem lógica duplicada.

## Project Structure

### Documentation (this feature)

```text
specs/006-shared-address-hooks/
├── plan.md              # Este arquivo
├── research.md          # Decisões técnicas (Phase 0)
├── data-model.md        # Tipos Address, Municipio, estados de hook
├── quickstart.md        # Validação manual + comandos de teste
├── contracts/
│   ├── shared-address-api.md      # Exports públicos hooks/componentes
│   ├── via-cep-integration.md     # Contrato ViaCEP
│   ├── ibge-municipios-integration.md  # Contrato IBGE
│   ├── address-form-ui.md         # Contrato UI AddressForm/AddressFields
│   └── test-strategy.md           # Matriz unit / component / contract
└── tasks.md             # Phase 2 — /speckit-tasks
```

### Source Code (repository root)

```text
ci-client-v2/
└── apps/web/
    ├── package.json                 # + vitest, @testing-library/*, jsdom, msw; script "test"
    ├── vite.config.ts               # + test: { environment: 'jsdom', setupFiles }
    ├── vitest.setup.ts              # MSW server lifecycle, cleanup RTL
    └── src/modules/shared/
        ├── index.ts                 # barrel público
        ├── lib/
        │   ├── address-types.ts     # AddressInput, MunicipioOption (fonte única)
        │   ├── cep.ts               # normalizeCep, isValidCep
        │   ├── via-cep.ts           # fetchViaCep, mapViaCepToAddress
        │   ├── ibge-municipios.ts   # fetchMunicipiosByUf, mapIbgeMunicipio
        │   └── __tests__/
        │       ├── cep.test.ts                    # unit
        │       ├── via-cep.test.ts                # unit + contract
        │       └── ibge-municipios.test.ts        # unit + contract
        ├── schemas/
        │   ├── via-cep.schema.ts      # Zod — resposta ViaCEP
        │   ├── ibge-municipio.schema.ts
        │   └── __tests__/
        │       └── contracts.test.ts  # contract — fixtures vs schema
        ├── hooks/
        │   ├── useViaCep.ts
        │   ├── useIbgeMunicipios.ts
        │   ├── index.ts
        │   └── __tests__/
        │       ├── useViaCep.test.tsx           # component (renderHook)
        │       └── useIbgeMunicipios.test.tsx
        ├── components/
        │   ├── AddressForm.tsx
        │   ├── AddressFields.tsx
        │   ├── AddressFieldsContext.tsx         # contexto composável
        │   ├── fields/                          # PostalCodeField, UfSelect, etc.
        │   └── __tests__/
        │       ├── AddressForm.test.tsx         # component
        │       └── AddressFields.test.tsx
        └── fixtures/
            ├── via-cep-success.json
            ├── via-cep-not-found.json
            └── ibge-municipios-am.json

ci-client-v2/apps/web/src/modules/address/
    └── api/types.ts                 # reexport de @/modules/shared/lib/address-types

ci-api-v2/                           # FORA DE ESCOPO — nenhuma alteração
```

**Structure Decision**: Feature vive inteiramente em `modules/shared/` conforme constitution V e spec FR-009. `modules/address/` mantém apenas API client server-side (`searchMunicipios`) e reexporta tipos de shared. Vitest configurado em `apps/web` (padrão Vite nativo).

## Complexity Tracking

> Nenhuma violação de constitution que exija justificativa.

## Phase 0 → research.md

Decisões consolidadas — ver [research.md](./research.md).

| ID | Tópico | Decisão |
|----|--------|---------|
| R1 | Stack de testes | Vitest 3 + RTL + MSW; sem Playwright/E2E |
| R2 | Debounce CEP | 300ms após 8 dígitos válidos |
| R3 | IBGE endpoint | `GET /api/v1/localidades/estados/{UF}/municipios` |
| R4 | ViaCEP endpoint | `GET https://viacep.com.br/ws/{cep}/json/` |
| R5 | Tipos canônicos | `AddressInput` em `shared/lib/address-types.ts` espelha Prisma |
| R6 | Composabilidade | `AddressFieldsContext` + campos individuais exportados |
| R7 | UF select | Lista estática BR (27 UFs) em `lib/brazilian-ufs.ts` |

## Phase 1 → artefatos

- [data-model.md](./data-model.md) — tipos, estados de hook, transições
- [contracts/shared-address-api.md](./contracts/shared-address-api.md) — exports públicos
- [contracts/via-cep-integration.md](./contracts/via-cep-integration.md)
- [contracts/ibge-municipios-integration.md](./contracts/ibge-municipios-integration.md)
- [contracts/address-form-ui.md](./contracts/address-form-ui.md)
- [contracts/test-strategy.md](./contracts/test-strategy.md)
- [quickstart.md](./quickstart.md) — VS-001…VS-008 + `npm run test`

## Test Strategy Summary

| Camada | Ferramenta | Escopo | Exemplos |
|--------|------------|--------|----------|
| Unit | Vitest | Funções puras, zero DOM | `normalizeCep`, `mapViaCepToAddress`, `isValidCep` |
| Component | Vitest + RTL | Render, interação, estados UI | `AddressForm` preenche após CEP mock; UF limpa município |
| Contract | Vitest + Zod + fixtures | Shape resposta externa → tipo canônico | ViaCEP JSON válido passa schema; `ibge` → `municipioIbge` |
| ~~Integration~~ | — | **Fora de escopo** | fetch real ViaCEP/IBGE |
| ~~E2E~~ | — | **Fora de escopo** | Playwright, Cypress |

Ordem TDD sugerida em `/speckit-tasks`: lib/schemas → hooks → components; cada slice RED → GREEN → REFACTOR.
