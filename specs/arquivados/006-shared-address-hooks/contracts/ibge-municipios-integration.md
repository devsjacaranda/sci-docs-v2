# Contract: IBGE Municípios Integration

**Feature**: 006-shared-address-hooks  
**Service**: [IBGE Localidades](https://servicodados.ibge.gov.br/api/docs/localidades)  
**References**: [data-model.md](../data-model.md)

## Request

```
GET https://servicodados.ibge.gov.br/api/v1/localidades/estados/{UF}/municipios
```

| Parâmetro | Formato | Exemplo |
|-----------|---------|---------|
| `{UF}` | Sigla 2 letras maiúsculas | `AM`, `SP` |

**Precondition**: UF MUST ser válida (lista estática `brazilian-ufs.ts`). UF inválida → não fetch.

---

## Response — success (HTTP 200)

Array de objetos:

```json
[
  {
    "id": 1302603,
    "nome": "Manaus",
    "microrregiao": {
      "id": 13007,
      "nome": "Manaus",
      "mesorregiao": {
        "id": 1303,
        "nome": "Centro Amazonense",
        "UF": {
          "id": 13,
          "sigla": "AM",
          "nome": "Amazonas",
          "regiao": {
            "id": 1,
            "sigla": "N",
            "nome": "Norte"
          }
        }
      }
    }
  }
]
```

### Zod schema (contract test)

Elemento array MUST ter: `id` (number), `nome` (string), `microrregiao.mesorregiao.UF.sigla` (string 2 chars).

---

## Mapeamento → MunicipioOption

| IBGE | MunicipioOption | Transformação |
|------|-----------------|-----------------|
| `id` | `codigoIbge` | `String(id).padStart(7, '0')` se necessário |
| `nome` | `nome` | direto |
| `microrregiao.mesorregiao.UF.sigla` | `uf` | direto |

**Ordenação client**: por `nome` ascendente (locale `pt-BR`).

---

## Contract tests (obrigatórios)

| ID | Fixture / cenário | Assert |
|----|-------------------|--------|
| CT-IBGE-001 | `ibge-municipios-am.json` | Schema parse OK (array) |
| CT-IBGE-002 | fixture AM | `mapIbgeMunicipio` → `codigoIbge: "1302603"` |
| CT-IBGE-003 | UF vazia | hook `idle`, array vazio |
| CT-IBGE-004 | UF inválida `XX` | sem fetch (se não estiver em lista estática) |
| CT-IBGE-005 | MSW network error | `municipios_load_error` |

Fixture em `modules/shared/fixtures/ibge-municipios-am.json`.

---

## Error handling

| Condição | Código client |
|----------|---------------|
| Network error / timeout | `municipios_load_error` |
| Empty array | `success` com `municipios: []` |
| Parse/schema fail | `municipios_load_error` |
| AbortController cancel | silencioso |

---

## Relação com API interna

`modules/address/api/municipios.ts` (`searchMunicipios`) permanece para autocomplete server-side.  
**Nesta feature**: lista completa por UF vem do IBGE direto (browser), não da API `/address/municipios`.
