# Contrato REST — Timbrado AGEMAN 2026

Prefixos já existentes; autenticação + `X-Tenant-ID` iguais às rotas atuais. Licença/módulo: os mesmos `@RequireModulo` / `@RequireLicenca` de cada família.

## Header de resposta (todas as emissões cobertas no tenant AGEMAN)

| Header | Valores | Quando |
|---|---|---|
| `X-Letterhead-Applied` | `1` | Folha 2026 carimbada |
| `X-Letterhead-Applied` | `0` | Tenant AGEMAN, arte ausente ou falha ao embutir — arquivo é o miolo |
| *(omitido)* | — | Tenant **não** AGEMAN (fallback atual) |

O body continua sendo o arquivo (`StreamableFile` / blob). **Não** há envelope JSON.

Copy de UI quando `0`: *“A folha oficial não pôde ser aplicada. O arquivo contém apenas o conteúdo.”*

## Rotas que já existem (só mudam arte + header)

| Método | Rota | Formato |
|---|---|---|
| GET | `/ouvidoria/manifestacoes/:id/documento/pdf` | PDF |
| GET | `/ouvidoria/manifestacoes/:id/documento/docx` | Word |
| GET | `/ouvidoria/relatorio-gestao/pdf` | PDF |
| POST | `/diagnostico/dashboard/pdf` | PDF |
| POST | `/diagnostico/processos/pdf` | PDF |
| GET | `/diagnostico/documentos/:id/pdf` | PDF |
| GET | `/gabinete/cabinets/:cabinetId/historico.pdf` | PDF |
| POST | `/tramitacao/protocolos/:id/baixar` | PDF (hoje) |
| POST | `/it-fiscalizacao/incidentes/:id/anpd/generate` | PDF (hoje) |
| GET | `/compras/insights/export` | **HTML extra** (inalterado) |
| GET | `/compras/maturidade/export` | **HTML extra** (inalterado) |
| GET | `/ouvidoria/relatorio-gestao/excel` | Planilha — **fora** (FR-010) |

## Rotas novas (Word e ofício Compras)

| Método | Rota | Formato |
|---|---|---|
| GET | `/ouvidoria/relatorio-gestao/docx` | Word |
| POST | `/diagnostico/dashboard/docx` | Word |
| POST | `/diagnostico/processos/docx` | Word |
| GET | `/diagnostico/documentos/:id/docx` | Word |
| GET | `/gabinete/cabinets/:cabinetId/historico.docx` | Word |
| POST | `/tramitacao/protocolos/:id/baixar-docx` | Word |
| POST | `/it-fiscalizacao/incidentes/:id/anpd/generate-docx` | Word |
| GET | `/compras/insights/export/pdf` | Ofício PDF |
| GET | `/compras/insights/export/docx` | Ofício Word |
| GET | `/compras/maturidade/export/pdf` | Ofício PDF |
| GET | `/compras/maturidade/export/docx` | Ofício Word |

Query/body das rotas novas **espelham** a irmã PDF/HTML já existente (mesmo `periodId`, mesmos filtros do relatório de gestão, mesmo `fields` do ANPD).

## Erros

Inalterados em relação a cada família (404 do registro, 403 de módulo, 422 de período de maturidade incompleto, etc.). **Falha da arte não é erro HTTP** — 200 + `X-Letterhead-Applied: 0`.

## Isolamento

Requisição com `X-Tenant-ID` de outro tenant **nunca** embute `header-faixa.png` / `marca-dagua-brasao.png` e **omite** `X-Letterhead-Applied`.
