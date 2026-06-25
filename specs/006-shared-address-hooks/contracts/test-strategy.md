# Contract: Test Strategy

**Feature**: 006-shared-address-hooks  
**References**: [plan.md](../plan.md) · constitution II (Test-First)

## Escopo de testes

| Camada | Incluído | Excluído |
|--------|----------|----------|
| Unit | ✅ | — |
| Component | ✅ | — |
| Contract | ✅ | — |
| Integration (rede real) | — | ❌ |
| E2E (browser automation) | — | ❌ |

---

## Infraestrutura

| Pacote | Versão alvo | Uso |
|--------|-------------|-----|
| `vitest` | ^3.x | runner |
| `@testing-library/react` | ^16.x | render component/hook |
| `@testing-library/user-event` | ^14.x | interações |
| `jsdom` | ^26.x | DOM environment |
| `msw` | ^2.x | mock `fetch` ViaCEP/IBGE |

### Scripts (`apps/web/package.json`)

```json
{
  "scripts": {
    "test": "vitest run",
    "test:watch": "vitest"
  }
}
```

### Config (`vite.config.ts`)

```typescript
/// <reference types="vitest/config" />
export default defineConfig({
  // ...existing
  test: {
    environment: 'jsdom',
    setupFiles: ['./vitest.setup.ts'],
    include: ['src/**/*.test.{ts,tsx}'],
  },
})
```

### Setup (`vitest.setup.ts`)

- `@testing-library/jest-dom/vitest` (opcional matchers)
- MSW server `beforeAll` / `afterEach` / `afterAll`
- RTL `cleanup` afterEach

---

## Matriz de testes

### Unit — `modules/shared/lib/`

| Arquivo teste | Funções | Casos mínimos |
|---------------|---------|---------------|
| `cep.test.ts` | `normalizeCep`, `isValidCep` | com hífen, espaços, 7/9 dígitos, letras |
| `via-cep.test.ts` | `mapViaCepToAddress`, `parseViaCepResponse` | success, erro true, campos vazios |
| `ibge-municipios.test.ts` | `mapIbgeMunicipio`, `sortMunicipiosByNome` | id padding, ordenação pt-BR |

### Contract — `modules/shared/schemas/__tests__/`

| Arquivo teste | Contrato | Casos mínimos |
|---------------|----------|---------------|
| `contracts.test.ts` | Zod ViaCEP + IBGE | fixtures JSON; reject malformed |

IDs cruzados: CT-VCEP-* (via-cep-integration.md), CT-IBGE-* (ibge-municipios-integration.md).

### Component — hooks

| Arquivo teste | Hook | Casos mínimos |
|---------------|------|---------------|
| `useViaCep.test.tsx` | `useViaCep` | loading→success, invalid, not found, abort |
| `useIbgeMunicipios.test.tsx` | `useIbgeMunicipios` | uf empty, success list, error, uf change |

Usar `renderHook` + MSW handlers.

### Component — UI

| Arquivo teste | Componente | Casos mínimos |
|---------------|------------|---------------|
| `AddressForm.test.tsx` | `AddressForm` | CMP-001…CMP-007 |
| `AddressFields.test.tsx` | `AddressFields` | composição parcial, context required |

---

## MSW handlers (test only)

```typescript
// handlers/via-cep.ts
http.get('https://viacep.com.br/ws/:cep/json/', ...)

// handlers/ibge.ts
http.get('https://servicodados.ibge.gov.br/api/v1/localidades/estados/:uf/municipios', ...)
```

Fixtures reutilizam `modules/shared/fixtures/*.json`.

---

## TDD workflow (implementação)

Ordem obrigatória por slice:

1. **RED**: escrever teste que falha
2. **GREEN**: implementação mínima
3. **REFACTOR**: extrair pure functions se hook ficar complexo

Sequência sugerida:

```text
cep.test → cep.ts
contracts.test → schemas
via-cep.test → via-cep.ts
useViaCep.test → useViaCep.ts
ibge-municipios.test → ibge-municipios.ts
useIbgeMunicipios.test → useIbgeMunicipios.ts
AddressForm.test → AddressForm + fields
AddressFields.test → AddressFields + context
```

---

## CI gate

Antes de merge da feature:

```powershell
cd ci-client-v2/apps/web
npm run test
npm run typecheck
npm run build
```

**Expected**: exit 0 em todos; cobertura não obrigatória na v1 mas todos IDs CT/CMP acima MUST passar.

---

## O que NÃO testar

- Fetch real para viacep.com.br ou ibge.gov.br
- Persistência API `/address/*`
- Fluxos multi-página (login → formulário → submit)
- Playwright, Cypress, TestCafe
