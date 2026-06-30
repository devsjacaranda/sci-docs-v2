# Contract: UI — Export e-SUS Mockdown

**Feature**: 026-esus-mockdown-export  
**Componentes**: `EsusExportButton`, `EsusExportSheet`

## Pontos de entrada

| Local | Ação | Prioridade |
|-------|------|------------|
| `ConsultaDetailPage` — aside "Ações" | Substituir toast por `EsusExportButton` | P1 |
| `SaudeConferenciaPage` — linha `pronto_envio` | Ícone export rápido (opcional P2) | P2 |
| `SaudeCadastrosDashboardPage` | "Exportar cadastros demo" | P3 |
| `SaudeConferenciaPage` — toolbar | "Exportar lote (prontas)" | P3 |

## EsusExportButton

**Props**: `consulta: ConsultaDetail` (ou ids + loader)

**Comportamento**:

1. Click → `validateConsultaExportReady`
2. Se `ok: false` → toast destructive com lista `missing` (max 5 + "e mais N")
3. Se status ≠ `pronto_envio` → toast informativo com status atual + link conferência
4. Se `ok: true` → abre `EsusExportSheet` com payload gerado

**Acessibilidade**: `aria-label="Exportar consulta no padrão e-SUS FAI"`

## EsusExportSheet

**Layout** (shadcn Sheet, lado direito, `max-w-2xl`):

| Seção | Conteúdo |
|-------|----------|
| Header | "Exportação e-SUS (FAI)" + badge LEDI 7.4.2 subset |
| Tabs | **FAI** · **Extensões** (disabled se vazio) · **JSON completo** |
| Footer | Copiar · Baixar JSON · Fechar |

**Copy extensões** (banner Mint):

> Complementos de demonstração — não fazem parte do layout oficial MS. Uso exclusivo mockdown Careiro.

**Warnings**: lista amarela acima do JSON se `warnings` presentes.

## Download

- `lib/esus-download.ts` — `triggerJsonDownload(filename, payload)`
- MIME: `application/json;charset=utf-8`
- Filename: `fai-{cnes}-{YYYYMMDD}-{slug}.json`

## Estados vazios

- Sem extensões: aba Extensões oculta ou mensagem "Nenhum complemento demo vinculado"
- Lote vazio: toast "Nenhuma consulta pronta para envio nos filtros atuais"

## Design system

- Paleta Mint (`mint-palette.mdc`)
- Botão primário export: `SAUDE_PRIMARY_BUTTON_CLASS` existente
- Ícone: `Download` (Lucide) — já usado no placeholder

## Test IDs

- `esus-export-button`
- `esus-export-sheet`
- `esus-export-download`
- `esus-export-missing-list`
