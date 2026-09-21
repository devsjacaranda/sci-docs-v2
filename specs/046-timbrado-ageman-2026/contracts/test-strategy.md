# Test Strategy — 046 Timbrado oficial AGEMAN 2026

TDD obrigatório (Constitution II). Prefixo `CT-LH-*` (API) e `CT-LH-CLIENT-*` (web).

## API (Jest) — RED primeiro

| ID | Alvo | Casos |
|---|---|---|
| CT-LH-001 | `isAgemanTenant` | UUID canônico (qualquer caixa) → true; outro UUID / vazio → false |
| CT-LH-002 | `resolve-letterhead-assets` | ambos PNGs presentes → paths; um ausente → vazio (não “meia folha”) |
| CT-LH-003 | `apply-letterhead-pdfkit` | AGEMAN + assets → `applied`; PDF contém as imagens; não desenha selo `OUVIDORIA` nem faixa `#E8F2FF` |
| CT-LH-004 | `apply-letterhead-pdf-lib` | idem CT-LH-003 na stack pdf-lib |
| CT-LH-005 | `apply-letterhead-docx` | AGEMAN + assets → header com faixa + watermark; sem rodapé textual de paginação |
| CT-LH-006 | Kernel sem assets | AGEMAN + files missing → `applied: false`, `reason: 'assets-missing'`; buffer do miolo ainda é PDF/DOCX válido |
| CT-LH-007 | Kernel não-AGEMAN | não embute PNGs 2026; `applied: false`, `reason: 'not-ageman'` |
| CT-LH-008 | Header HTTP | controller AGEMAN + applied → `X-Letterhead-Applied: 1`; assets missing → `0`; outro tenant → header ausente |
| CT-LH-009 | Manifestação PDF/DOCX | tenant AGEMAN: sem selo OUVIDORIA / título “AGEMAN — Ouvidoria”; tenant default: fallback atual |
| CT-LH-010 | Relatório de gestão | PDF existente + **novo** DOCX; ambos passam pelo kernel; Excel inalterado |
| CT-LH-011 | Diagnóstico / doc institucional | PDF existente usa kernel; DOCX novos existem e compartilham o assembly |
| CT-LH-012 | Gabinete histórico | PDF deixa de ser “só título”; DOCX novo |
| CT-LH-013 | Tramitação / ANPD | pdf-lib carimbado; rota DOCX nova |
| CT-LH-014 | Compras Insights/Maturidade | `GET export` continua `text/html`; `export/pdf` e `export/docx` devolvem ofício |
| CT-LH-015 | Multipage | 2+ páginas: faixa e marca d’água em **todas**; miolo não sobrepõe a faixa (y inicial ≥ métrica) |

## Client (Vitest) — RED primeiro

| ID | Alvo | Casos |
|---|---|---|
| CT-LH-CLIENT-001 | `letterhead-download.ts` | lê `X-Letterhead-Applied`; `0` → sinal de aviso; ausente/`1` → sem aviso |
| CT-LH-CLIENT-002 | `OficioExportMenu` | mostra PDF e Word; slot HTML extra só quando `htmlExtra` é passado |
| CT-LH-CLIENT-003 | Compras Insights | botão principal não baixa mais HTML; HTML é item extra; PDF/Word chamam as rotas novas |
| CT-LH-CLIENT-004 | Compras Maturidade | idem CT-LH-CLIENT-003 (`maturidade-export-button` vira menu) |
| CT-LH-CLIENT-005 | Ouvidoria / Gabinete / Diagnóstico / Tramitação | cada superfície coberta oferece PDF + Word |
| CT-LH-CLIENT-006 | Toast de arte ausente | `X-Letterhead-Applied: 0` → mensagem canônica; download do arquivo ainda ocorre |

## Ordem RED → GREEN

1. `isAgemanTenant` + `official-page-metrics` + `resolve-letterhead-assets`
2. Adaptadores PDFKit / pdf-lib / docx (com fixtures dos PNGs)
3. Header HTTP num controller já existente (manifestação PDF) como piloto
4. Migrar renderers PDF/DOCX existentes (remover arte antiga no caminho AGEMAN)
5. Use-cases + rotas Word novas, uma família por vez
6. Ofício Compras (PDF/DOCX) mantendo HTML
7. Client: `letterhead-download` → `OficioExportMenu` → trocar botões

## E2E

Não obrigatório no CI. `quickstart.md` cobre a conferência visual humana (SC-002) no tenant AGEMAN vs Jacaranda.
