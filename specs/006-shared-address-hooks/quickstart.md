# Quickstart: Shared Address Hooks

**Feature**: 006-shared-address-hooks  
**Prerequisites**: Node.js 20+  
**References**: [data-model.md](./data-model.md) · [contracts/](./contracts/) · [spec.md](./spec.md)

> Executar **após** implementação (`/speckit-implement`). Inclui validação automatizada (unit/component/contract) e smoke manual. **Sem testes E2E.**

## Setup

```powershell
cd ci-client-v2
npm install
```

## Testes automatizados (obrigatório)

```powershell
cd ci-client-v2/apps/web
npm run test
```

**Expected**: exit 0; suites:
- `lib/__tests__/cep.test.ts`
- `lib/__tests__/via-cep.test.ts`
- `lib/__tests__/ibge-municipios.test.ts`
- `schemas/__tests__/contracts.test.ts`
- `hooks/__tests__/useViaCep.test.tsx`
- `hooks/__tests__/useIbgeMunicipios.test.tsx`
- `components/__tests__/AddressForm.test.tsx`
- `components/__tests__/AddressFields.test.tsx`

Watch mode (desenvolvimento):

```powershell
npm run test:watch
```

Build de segurança:

```powershell
cd ci-client-v2
npm run build
```

**Expected**: exit 0.

---

## VS-001 — Auto-preenchimento CEP (US1, SC-002)

| Step | Action | Expected |
|------|--------|----------|
| 1 | Abrir página demo/dev com `AddressForm` | Formulário com 9 áreas de campo |
| 2 | Digitar CEP `69005-040` (Manaus) | Loading breve no CEP |
| 3 | Aguardar lookup | Logradouro e bairro preenchidos |
| 4 | Verificar UF e município | UF `AM`; município Manaus selecionado |
| 5 | Tempo total | &lt; 2 segundos |

---

## VS-002 — CEP inválido e não encontrado (edge cases)

| Step | Action | Expected |
|------|--------|----------|
| 1 | Digitar `123` | Mensagem *CEP inválido*; sem request (Network tab vazio) |
| 2 | Digitar `99999-999` | Mensagem *CEP não encontrado* |
| 3 | Após erro | Campos manuais editáveis |

---

## VS-003 — Municípios por UF (US2, SC-003)

| Step | Action | Expected |
|------|--------|----------|
| 1 | Selecionar UF `AM` | Loading no município |
| 2 | Abrir select município | Lista com Manaus, Parintins, etc. |
| 3 | Tempo após UF | &lt; 1 segundo |
| 4 | Trocar UF para `SP` | Município anterior limpo; lista SP carregada |

---

## VS-004 — Preservação campos manuais (FR-006)

| Step | Action | Expected |
|------|--------|----------|
| 1 | Preencher Número `123`, Complemento `Apto 4` | Valores mantidos |
| 2 | Informar CEP válido | Lookup preenche logradouro/bairro |
| 3 | Verificar | Número e Complemento **inalterados** |

---

## VS-005 — AddressForm completo (US3, SC-004)

| Step | Action | Expected |
|------|--------|----------|
| 1 | Inspecionar AddressForm | Campos: CEP, Logradouro, Número, Complemento, Bairro, Zona, UF, Município, Ponto de referência |
| 2 | Preencher todos manualmente | `onChange` emite `AddressInput` completo |
| 3 | Verificar objeto | Apenas chaves canônicas — sem extras |

---

## VS-006 — AddressFields composável (US4)

| Step | Action | Expected |
|------|--------|----------|
| 1 | Montar layout só CEP + Logradouro + UF + Município | Render OK |
| 2 | CEP lookup | Propaga para contexto |
| 3 | Submit mock | Objeto parcial válido |

---

## VS-007 — Import único shared (SC-001)

| Step | Action | Expected |
|------|--------|----------|
| 1 | Em módulo consumidor: `import { useViaCep, AddressForm } from '@/modules/shared'` | Typecheck OK |
| 2 | Grep por `viacep` fora de `modules/shared/` | Zero ocorrências de fetch duplicado |

---

## VS-008 — Erro serviço indisponível

| Step | Action | Expected |
|------|--------|----------|
| 1 | Simular offline (DevTools → Offline) ou MSW error | Mensagem *Serviço indisponível* |
| 2 | Voltar online | Retry manual (blur CEP ou trocar UF) funciona |

---

## Checklist pós-implementação

- [ ] `npm run test` exit 0 (unit + component + contract)
- [ ] `npm run typecheck` exit 0
- [ ] `npm run build` exit 0
- [ ] VS-001 a VS-008 smoke manual OK
- [ ] Nenhum campo fora do schema `Address` no client
