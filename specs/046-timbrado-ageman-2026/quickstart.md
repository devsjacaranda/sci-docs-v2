# Quickstart — Timbrado oficial AGEMAN 2026

Validação humana + comandos para provar a entrega. Detalhe de rotas: [contracts/rest-api-letterhead.md](./contracts/rest-api-letterhead.md). Tipos: [data-model.md](./data-model.md).

## Pré-requisitos

- API: `cd ci-api-v2; npm run prisma:seed` (Jacaranda + AGEMAN)
- Tenant AGEMAN: `00000000-0000-0000-0000-000000000002`
- Arte em `ci-api-v2/src/common/letterhead/assets/` (faixa + brasão)
- Fonte visual ao lado: `new-timbrado/Folha padrão 2026 - Vertical.docx`
- `npm run start:dev` (API) e `cd ci-client-v2; npm run dev`

## Testes automatizados

```powershell
cd ci-api-v2; npm test -- --testPathPatterns=letterhead
cd ci-api-v2; npm test -- --testPathPatterns=ouvidoria
cd ci-client-v2/apps/web; npm test -- letterhead
cd ci-client-v2/apps/web; npm test -- compras
```

Esperado: CT-LH-* e CT-LH-CLIENT-* verdes (ver [contracts/test-strategy.md](./contracts/test-strategy.md)).

## Conferência visual (SC-002)

1. Login no tenant **AGEMAN**.
2. Emitir **PDF e Word** de pelo menos um item de cada família:
   - Manifestação
   - Relatório de gestão
   - Diagnóstico (painel ou seleção) e um documento institucional
   - Histórico de uma demanda do Gabinete
   - Dossiê de um protocolo (Tramitação)
   - Notificação ANPD
   - Compras Insights e Compras Maturidade (ofício PDF/Word **e** HTML extra)
3. Abrir cada arquivo ao lado da `Folha padrão 2026 - Vertical.docx`.
4. Conferir em **todas** as páginas: faixa AGEMAN + Prefeitura no topo; brasão em marca d’água; **sem** selo “OUVIDORIA”; **sem** “página X de Y”; miolo abaixo da faixa.
5. Login num tenant **não** AGEMAN (Jacaranda) e repetir uma emissão: a arte 2026 **não** aparece; o fallback atual permanece.

## Arte ausente (FR-012 / SC-007)

1. Renomear temporariamente a pasta `assets` do kernel (ou rodar o teste CT-LH-006).
2. Emitir uma manifestação no AGEMAN.
3. Esperado: arquivo baixa; toast *“A folha oficial não pôde ser aplicada…”*; header `X-Letterhead-Applied: 0`; **sem** timbrado antigo.

## Fora de escopo neste check

- Export Excel do relatório de gestão e planilha SIGED (não mudam)
- Insights/Maturidade de Ouvidoria, Gabinete, TI, SIGED (sem botão de exportar)
- Regenerar arquivos já salvos no disco do usuário

## Checklist de execução (T049)

| Item | Resultado | Observação |
| --- | --- | --- |
| CT-LH-* + CT-LH-CLIENT-* (Jest/Vitest) | ✅ | Rodado na implementação 046 — `letterhead-fallback`, `letterhead.service.spec`, RTL `OficioExportMenu` + páginas migradas |
| Conferência visual AGEMAN vs DOCX oficial | ⏸ | Requer login manual no tenant AGEMAN |
| Jacaranda sem arte 2026 | ⏸ | Requer login manual Jacaranda |
| Arte ausente + toast | ⏸ | Renomear `letterhead/assets` ou CT-LH-006 |
| ANPD PDF via URL assinada | ⚠ | Toast de folha só no Word (`generate-docx`); PDF abre URL — sem header HTTP no client |
| Tramitação ZIP + Word | ⚠ | ZIP permanece botão separado; ofício PDF+Word unificado aguarda rota PDF dedicada |
