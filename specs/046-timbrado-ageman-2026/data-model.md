# Data Model: Timbrado oficial AGEMAN 2026

Nenhum modelo Prisma novo. O ofício é **efêmero** (gerado no request). Este arquivo descreve os tipos de domínio do kernel e as entidades de produto já existentes que ele toca.

## Entidades de produto (já existem — sem mudança de persistência)

| Entidade | Módulo | Emissão coberta |
|---|---|---|
| Manifestação | Ouvidoria | Dossiê PDF + Word |
| Relatório de gestão | Ouvidoria | Ofício PDF + Word (Excel permanece) |
| Processo / seleção Diagnóstico | Diagnóstico | Painel e seleção PDF + Word |
| Documento institucional | Documento institucional | PDF + Word |
| Demanda de gabinete | Gabinete | Histórico PDF + Word |
| Protocolo | Tramitação | Dossiê PDF + Word |
| Incidente de segurança | IT fiscalização | Notificação ANPD PDF + Word |
| Lote de insights / período de maturidade | Compras | Ofício PDF + Word; HTML extra |

## Tipos do kernel (em memória)

### OfficialPageMetrics

Métricas fixas da folha 2026 (não configuráveis por tenant nesta entrega).

| Campo | Tipo | Regra |
|---|---|---|
| pageSize | `'A4'` | Só vertical |
| widthPt / heightPt | number | 595,3 × 841,9 pt |
| marginTopMm | 40,0 | Área da faixa |
| marginRightMm | 17,5 | |
| marginBottomMm | 22,5 | Sem rodapé de sistema |
| marginLeftMm | 22,5 | |
| headerBandHeightMm | ≈ 29 | Faixa oficial |
| watermark | centered | Atrás do miolo |

### LetterheadAssets

| Campo | Tipo | Regra |
|---|---|---|
| headerBandPath | string? | PNG da faixa; `undefined` se ausente |
| watermarkPath | string? | PNG do brasão; `undefined` se ausente |

`resolveLetterheadAssets()`: os dois paths presentes **ou** nenhum (não carimbar faixa sem brasão ou vice-versa — evita folha “meia oficial”).

### LetterheadResult

| Campo | Tipo | Significado |
|---|---|---|
| applied | boolean | `true` só no tenant AGEMAN com os dois assets embutidos |
| reason | `'applied' \| 'not-ageman' \| 'assets-missing' \| 'embed-failed'` | Para log + header HTTP |

Validação:
- `applied === true` ⇒ `reason === 'applied'`
- Tenant AGEMAN + assets ausentes ⇒ `applied === false`, `reason === 'assets-missing'`
- Nunca `applied === true` fora do UUID AGEMAN

### DocumentoEmitido (efêmero — resposta HTTP)

| Campo | Tipo | Regra |
|---|---|---|
| buffer | bytes | PDF ou DOCX |
| mimeType | string | `application/pdf` ou OOXML Word |
| fileName | string | attachment |
| letterheadApplied | boolean | vira `X-Letterhead-Applied: 0\|1` no tenant AGEMAN |

Não é persistido. Anexos do usuário **não** entram neste modelo (não são re-timbrados).

## Tenant AGEMAN

| Campo | Valor |
|---|---|
| id | `00000000-0000-0000-0000-000000000002` |
| regra | comparação case-insensitive do UUID do `X-Tenant-ID` / ALS |

Não há tabela `Letterhead` / `TenantBranding` nova: a 025 (foto/banner da instituição) **não** alimenta o ofício nesta entrega.

## Transições

Não há ciclo de vida. Cada clique de exportar:

1. Resolver tenant.
2. Se AGEMAN e assets ok → carimbar (`applied`).
3. Se AGEMAN e assets falham → miolo + aviso (`assets-missing` / `embed-failed`).
4. Se não AGEMAN → renderer legado, header omitido.

Arquivos já baixados pelo usuário não reentram no fluxo.
