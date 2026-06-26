# Contract: ViaCEP Integration

**Feature**: 006-shared-address-hooks  
**Service**: [ViaCEP](https://viacep.com.br/)  
**References**: [data-model.md](../data-model.md)

## Request

```
GET https://viacep.com.br/ws/{cep}/json/
```

| Parâmetro | Formato | Regra |
|-----------|---------|-------|
| `{cep}` | 8 dígitos numéricos | Sem hífen; validar client-side antes do request |

**Client validation failure**: não disparar request; retornar `invalid_cep`.

---

## Response — success (HTTP 200)

```json
{
  "cep": "69005-040",
  "logradouro": "Rua Exemplo",
  "complemento": "",
  "unidade": "",
  "bairro": "Centro",
  "localidade": "Manaus",
  "uf": "AM",
  "estado": "Amazonas",
  "regiao": "Norte",
  "ibge": "1302603",
  "gia": "",
  "ddd": "92",
  "siafi": "0255"
}
```

### Zod schema (contract test)

Campos obrigatórios no schema de sucesso: `cep`, `logradouro`, `bairro`, `localidade`, `uf`, `ibge`.  
Campo `erro` MUST NOT estar presente ou MUST NOT ser `"true"`.

---

## Response — not found (HTTP 200)

```json
{
  "erro": "true"
}
```

**Client behavior**: `status: error`, `error.code: cep_not_found`.

---

## Response — invalid format (HTTP 400)

Ocorre se CEP enviado com formato inválido (9 dígitos, alfanumérico).  
**Prevenção**: validação client impede este caso em operação normal.

---

## Mapeamento → AddressInput

| ViaCEP | AddressInput | Transformação |
|--------|--------------|---------------|
| `cep` | `postalCode` | remover hífen |
| `logradouro` | `street` | direto |
| `bairro` | `neighborhood` | direto |
| `ibge` | `municipioIbge` | string, 7 dígitos |
| `uf` | *(seletor UF)* | não persiste em AddressInput |

---

## Contract tests (obrigatórios)

| ID | Fixture | Assert |
|----|---------|--------|
| CT-VCEP-001 | `via-cep-success.json` | Schema parse OK |
| CT-VCEP-002 | `via-cep-not-found.json` | Detecta `erro: true` |
| CT-VCEP-003 | success fixture | `mapViaCepToAddress` → AddressInput esperado |
| CT-VCEP-004 | CEP `123` | `isValidCep` false, sem fetch |
| CT-VCEP-005 | CEP `12345678` inválido chars | `isValidCep` false |

Fixtures em `modules/shared/fixtures/`.

---

## Error handling

| Condição | Código client |
|----------|---------------|
| Network error / timeout | `service_unavailable` |
| `erro: true` | `cep_not_found` |
| Parse/schema fail | `service_unavailable` |
| AbortController cancel | silencioso (novo request substitui) |
