# Quickstart: Validar tipo de concessão (gap 3)

## Pré-requisitos

- Tenant AGEMAN (ou seed) com manifestações variando `programa` (`agua`, `iluminacao`, `2`, …)
- API `ci-api-v2` + web `ci-client-v2`
- Referência: `new-demanda/extracted-sheets.txt` (abas RESUMO GERAL + sheet 7)

## Após implementação

1. `GET /ouvidoria/relatorio-gestao?year=2026` — inspecionar `porTipoManifestacao`:
   - Cada linha tem `tipoConcessao` e `type` iguais.
   - Nenhum valor `complaint` / `request`.
2. Rollup: agrupar `porMotivo` por `tipoConcessionaria` (normalizar null → "Não informado") e comparar totais com soma de `porTipoManifestacao` no mesmo filtro.
3. Tela Ouvidoria → Relatório de gestão — card **Tipo de concessão**.
4. Export Excel — aba **Tipo de concessão**; export PDF bloco `porTipoManifestacao` — título **Tipo de concessão**.
5. Conferência planilha (manual): totais acumulados 2026 por concessão vs seção **TIPO DE CONCESSÃO** (coluna TOTAL 2026), tolerando diferença de rótulo (tabela em `research.md`).

## Comandos teste

```powershell
cd ci-api-v2; npm test -- --testPathPatterns=get-relatorio-gestao-tipo-manifestacao
cd ci-client-v2/apps/web; npm test -- relatorio-gestao-mappers
```
