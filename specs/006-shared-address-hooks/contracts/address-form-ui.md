# Contract: AddressForm / AddressFields UI

**Feature**: 006-shared-address-hooks  
**App**: `ci-client-v2/apps/web`  
**References**: [data-model.md](../data-model.md) · [regras-plataforma.md](../../../.cursor/docs/regras-plataforma.md) · mint-palette

## Campos e labels (PT-BR)

| Campo `AddressInput` | Label | Input type | Lookup |
|---------------------|-------|------------|--------|
| `postalCode` | CEP | text (máscara `00000-000`) | ViaCEP on valid 8 digits |
| `street` | Logradouro | text | auto via CEP |
| `number` | Número | text | manual |
| `complement` | Complemento | text | manual |
| `landmark` | Ponto de referência | text | manual |
| `neighborhood` | Bairro | text | auto via CEP |
| `zone` | Zona | text | manual |
| *(UF select)* | UF | select | estático 27 UFs |
| `municipioIbge` | Município | select/combobox | IBGE por UF |

**Regra FR-010**: Não exibir campo "Cidade" texto livre — município ONLY via select IBGE.

---

## AddressForm — layout padrão

Grid responsivo (Tailwind):

```text
┌─────────────────────────────────────┐
│ CEP [________]  (spinner se loading)│
├─────────────────────────────────────┤
│ Logradouro [________________________]│
├──────────────────┬──────────────────┤
│ Número [____]    │ Complemento [___]│
├──────────────────┼──────────────────┤
│ Bairro [________]│ Zona [__________] │
├──────────────────┼──────────────────┤
│ UF [▼]           │ Município [▼]     │
├─────────────────────────────────────┤
│ Ponto de referência [_______________]│
└─────────────────────────────────────┘
```

- Mensagens de erro inline abaixo do CEP ou município
- `MunicipioSelect` disabled até UF selecionada
- Loading: spinner/disabled no CEP durante lookup; skeleton ou disabled no município durante fetch IBGE

---

## AddressFields — composição

Provider obrigatório. Campos individuais:

| Export | Renderiza |
|--------|-----------|
| `PostalCodeField` | Input CEP + erro lookup |
| `StreetField` | Input logradouro |
| `NumberField` | Input número |
| `ComplementField` | Input complemento |
| `LandmarkField` | Input ponto de referência |
| `NeighborhoodField` | Input bairro |
| `ZoneField` | Input zona |
| `UfSelectField` | Select UF |
| `MunicipioSelectField` | Select municípios |

Uso fora de `AddressFields` provider → throw em dev / noop em prod (documentar).

---

## Estados visuais

| Estado | CEP field | Município select |
|--------|-----------|------------------|
| idle | normal | disabled se sem UF |
| loading | spinner, editable | disabled + loading |
| success | normal | enabled com opções |
| error | border destructive + msg | msg se fetch falhou |

Copy de erro: ver research R9.

---

## Acessibilidade

- Labels associados via `htmlFor` / `id`
- `aria-busy="true"` durante loading
- `aria-invalid="true"` + `aria-describedby` para erros
- Select município: `aria-disabled` quando sem UF

---

## Component tests (obrigatórios)

| ID | Cenário | Assert |
|----|---------|--------|
| CMP-001 | Render AddressForm | 9 campos visíveis (CEP…referência + UF) |
| CMP-002 | Digitar CEP válido (MSW) | street e neighborhood preenchidos |
| CMP-003 | CEP não encontrado | mensagem erro; campos editáveis |
| CMP-004 | Trocar UF | municipioIbge limpo |
| CMP-005 | AddressFields parcial | só campos filhos renderizados |
| CMP-006 | number preenchido + CEP lookup | number preservado (FR-006) |
| CMP-007 | disabled prop | todos inputs disabled |
