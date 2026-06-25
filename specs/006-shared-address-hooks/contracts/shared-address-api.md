# Contract: Shared Address — Public API

**Feature**: 006-shared-address-hooks  
**Module**: `ci-client-v2/apps/web/src/modules/shared/`  
**References**: [data-model.md](../data-model.md)

## Barrel export (`index.ts`)

Consumidores MUST importar exclusivamente de `@/modules/shared`:

```typescript
// Hooks
export { useViaCep } from './hooks/useViaCep'
export { useIbgeMunicipios } from './hooks/useIbgeMunicipios'

// Components
export { AddressForm } from './components/AddressForm'
export { AddressFields } from './components/AddressFields'
export {
  PostalCodeField,
  StreetField,
  NumberField,
  ComplementField,
  LandmarkField,
  NeighborhoodField,
  ZoneField,
  UfSelectField,
  MunicipioSelectField,
} from './components/fields'

// Types
export type {
  AddressInput,
  MunicipioOption,
  UfOption,
  ViaCepError,
  IbgeMunicipiosError,
} from './lib/address-types'
```

**Regra**: Módulos de domínio (`ouvidoria`, `tramitacao`, etc.) **NUNCA** importam de paths internos (`shared/lib/via-cep`); apenas do barrel.

---

## useViaCep

```typescript
function useViaCep(options?: { debounceMs?: number }): UseViaCepResult
```

| Método/Prop | Contrato |
|-------------|----------|
| `lookup(cep)` | Normaliza CEP; se inválido → `error: invalid_cep` sem fetch |
| `lookup(cep)` | Se válido → debounce → fetch ViaCEP → `data` parcial AddressInput |
| `reset()` | Volta `idle`, limpa `data` e `error` |
| `status` | `idle` \| `loading` \| `success` \| `error` |

---

## useIbgeMunicipios

```typescript
function useIbgeMunicipios(uf: string | undefined): UseIbgeMunicipiosResult
```

| Comportamento | Contrato |
|---------------|----------|
| `uf` undefined/empty | `idle`, `municipios: []`, sem fetch |
| `uf` válida | fetch IBGE → `municipios` ordenados por `nome` |
| `uf` muda | cancela fetch anterior; nova lista |

---

## AddressForm

Renderiza layout padrão (grid responsivo) com **todos** os campos canônicos:

1. CEP (com lookup)
2. Logradouro
3. Número | Complemento
4. Bairro | Zona
5. UF | Município
6. Ponto de referência

Props: ver [address-form-ui.md](./address-form-ui.md).

---

## AddressFields

Provider + composição. Consumidor:

```tsx
<AddressFields value={addr} onChange={setAddr}>
  <PostalCodeField />
  <StreetField />
  <UfSelectField />
  <MunicipioSelectField />
</AddressFields>
```

---

## Migração modules/address

`modules/address/api/types.ts` MUST reexportar:

```typescript
export type { AddressInput, MunicipioOption } from '@/modules/shared'
```

Sem duplicar definições.
