# Research: Shared Address Hooks

**Feature**: 006-shared-address-hooks  
**Date**: 2026-06-19

## R1 — Stack de testes (unit, component, contract — sem integração/E2E)

**Decision**: Adicionar Vitest 3.x nativo ao Vite 8 em `@ci/web`, com `@testing-library/react`, `@testing-library/user-event`, `jsdom` e `msw` para mock de `fetch` em testes. Três camadas distintas conforme pedido do usuário; **excluir** testes de integração (rede real) e E2E.

**Rationale**: Constitution II exige TDD; já existe `tramitacao-status.test.ts` importando Vitest sem config formal — esta feature estabelece infraestrutura de teste reutilizável. MSW isola contratos externos sem acionar ViaCEP/IBGE reais (evita flakiness e rate limit).

**Alternatives considered**:

| Alternativa | Motivo de rejeição |
|-------------|-------------------|
| Jest | Vite 8 recomenda Vitest nativo; duplica config |
| Testes de integração com fetch real | Usuário excluiu explicitamente |
| Playwright E2E | Usuário excluiu explicitamente |
| Apenas smoke manual | Viola constitution II para código novo |

---

## R2 — Debounce e disparo de consulta CEP

**Decision**: Consultar ViaCEP somente quando CEP normalizado tiver exatamente 8 dígitos numéricos, com debounce de **300ms** após última digitação. Cancelar request anterior (AbortController) se CEP mudar durante debounce/fetch.

**Rationale**: FR-002 da spec; evita 400 do ViaCEP em CEP incompleto; reduz chamadas em digitação rápida.

**Alternatives considered**:

| Alternativa | Motivo de rejeição |
|-------------|-------------------|
| Consulta on blur apenas | UX inferior; spec SC-002 espera preenchimento fluido |
| Consulta a cada keystroke | Rate limit ViaCEP; requests desnecessários |

---

## R3 — Endpoint IBGE municípios por UF

**Decision**: `GET https://servicodados.ibge.gov.br/api/v1/localidades/estados/{UF}/municipios` — mapear `id` (number) → `codigoIbge` (string 7 dígitos), `nome`, `microrregiao.mesorregiao.UF.sigla` → `uf`.

**Rationale**: API pública estável, CORS habilitado, retorna todos municípios da UF (~400 max). Alinha com `Municipio.codigoIbge` Prisma.

**Alternatives considered**:

| Alternativa | Motivo de rejeição |
|-------------|-------------------|
| `modules/address/api/municipios.ts` (API interna) | Spec define browser direto; API é search por query, não lista completa por UF |
| Cache localStorage | Fora de escopo v1 (spec assumption) |
| Pacote npm `brasil` | Dependência extra; IBGE oficial suficiente |

---

## R4 — Endpoint ViaCEP

**Decision**: `GET https://viacep.com.br/ws/{cep}/json/` — CEP sem hífen (8 dígitos). Tratar `erro: true` como CEP não encontrado; HTTP 400 como formato inválido (não deve ocorrer se validação client prévia).

**Rationale**: Documentação oficial [ViaCEP](https://viacep.com.br/); CORS funcional em produção para SPAs.

**Alternatives considered**:

| Alternativa | Motivo de rejeição |
|-------------|-------------------|
| BrasilAPI | Segunda dependência externa; ViaCEP especificado pelo usuário |
| Proxy NestJS | Spec out of scope |

---

## R5 — Tipos canônicos e fonte única

**Decision**: Definir `AddressInput` e `MunicipioOption` em `modules/shared/lib/address-types.ts` espelhando campos opcionais de `address.prisma`. `modules/address/api/types.ts` passa a reexportar de shared.

**Rationale**: FR-009/FR-010; evita divergência entre domínio address e shared; `AddressInput` já existe parcialmente em address module.

**Alternatives considered**:

| Alternativa | Motivo de rejeição |
|-------------|-------------------|
| Tipos em `@ci/domain` | Endereço não é licença/produto domain; shared é local correto |
| Duplicar tipos em address e shared | Viola FR-009 |

---

## R6 — Composabilidade AddressFields

**Decision**: `AddressFieldsContext` (React Context) provê valor/onChange/estados de lookup; exportar campos individuais (`PostalCodeField`, `StreetField`, `UfSelectField`, `MunicipioSelectField`, etc.) que consomem contexto. `AddressForm` é wrapper opinionated que renderiza todos os campos + context provider.

**Rationale**: User Story 4 (P3); permite layout custom sem fork de lógica CEP/municípios.

**Alternatives considered**:

| Alternativa | Motivo de rejeição |
|-------------|-------------------|
| Só AddressForm monolítico | Não atende US4 |
| Props drilling sem context | Verboso em layouts parciais com muitos campos |

---

## R7 — Seletor de UF

**Decision**: Lista estática das 27 UFs brasileiras em `lib/brazilian-ufs.ts` (`{ sigla, nome }[]`). Não consultar IBGE para estados.

**Rationale**: Conjunto fechado imutável; evita request extra; IBGE usado apenas para municípios.

**Alternatives considered**:

| Alternativa | Motivo de rejeição |
|-------------|-------------------|
| IBGE `/estados` | Latência desnecessária para 27 itens fixos |
| Campo texto livre UF | Viola FR-010 |

---

## R8 — Mapeamento ViaCEP → Address (campo zone)

**Decision**: ViaCEP **não** retorna `zone`; auto-preenchimento **não** altera `zone`. Campos preenchidos: `postalCode`, `street`, `neighborhood`, `municipioIbge` (de `ibge`), UF implícita para seletor.

**Rationale**: Spec assumption linha 134; FR-006 preserva campos manuais incluindo zone.

**Alternatives considered**:

| Alternativa | Motivo de rejeição |
|-------------|-------------------|
| Inferir zone de complemento ViaCEP | Heurística frágil; fora do modelo |

---

## R9 — Mensagens de erro (copy)

**Decision**: Mensagens fixas em PT-BR:

| Código | Mensagem |
|--------|----------|
| `invalid_cep` | CEP inválido. Informe 8 dígitos. |
| `cep_not_found` | CEP não encontrado. Preencha o endereço manualmente. |
| `service_unavailable` | Serviço indisponível. Tente novamente ou preencha manualmente. |
| `municipios_load_error` | Não foi possível carregar municípios. |

**Rationale**: FR-011; copy amigável sem detalhes técnicos.

**Alternatives considered**:

| Alternativa | Motivo de rejeição |
|-------------|-------------------|
| Expor status HTTP | Viola FR-011 |
