# Phase 0 — Research: Timbrado oficial AGEMAN 2026

Todas as ambiguidades de produto já foram resolvidas em `/speckit-specify` + `/speckit-clarify`. Este documento fecha o **como** técnico.

---

## R1 — Um kernel transversal, não um timbrado por módulo

**Decisão**: implementar a folha 2026 em `ci-api-v2/src/common/letterhead/` (arquivos pequenos, 1 operação cada). Os renderers atuais (Ouvidoria, Diagnóstico, Gabinete, Tramitação, ANPD, Compras) **chamam** o kernel; deixam de desenhar cabeçalho próprio no tenant AGEMAN.

**Rationale**: FR-004 exige um único timbrado geral. Hoje há artes paralelas (`render-manifestacao-pdf` com faixa azul + selo OUVIDORIA, `DiagnosticoLetterheadService` com linha mint, histórico do Gabinete sem cabeçalho). Copiar a arte em cada módulo recria a divergência que a spec proíbe. `common/` é o lugar canônico de cross-cutting (constitution + `ci-api-arquitetura`).

**Alternatives considered**:
- Módulo Nest `LetterheadModule` injetável — rejeitado: o kernel é função pura + filesystem, sem Prisma; DI extra não paga.
- Pacote npm interno — rejeitado: um único consumidor (ci-api-v2).

---

## R2 — Carimbar os PNGs oficiais, não reconstruir a arte

**Decisão**: extrair da `Folha padrão 2026 - Vertical.docx` e versionar:
- `header-faixa.png` — faixa do `header2` (imagem recortada ~19,25 cm × 2,89 cm: marca AGEMAN à esquerda + Prefeitura de Manaus à direita)
- `marca-dagua-brasao.png` — brasão municipal (`image1.png`)

Cada página: marca d’água central atrás do texto + faixa no topo. Sem desenhar textos/logos com fonte do sistema. Sem rodapé.

**Rationale**: Q2 do specify pediu folha **à risca**. Reconstruir tipografia/slogan/endereço em Helvetica diverge da arte (cores teal da Prefeitura, geometria da marca AGEMAN). O Word oficial já é um par de imagens.

**Alternatives considered**:
- Usar o DOCX como template Carbone e preencher o miolo — rejeitado: a maior parte das emissões hoje é PDFKit/pdf-lib; Carbone só existia no v1 SEDEL (038 R16, fora de escopo).
- Recriar vetores em PDFKit — rejeitado: fidelidade visual baixa e manutenção cara.

---

## R3 — Três adaptadores (as stacks que já existem)

**Decisão**:
| Stack | Onde hoje | Adaptador |
|---|---|---|
| PDFKit | Manifestação, relatório de gestão, Diagnóstico, documento institucional, histórico Gabinete | `apply-letterhead-pdfkit.ts` |
| pdf-lib | Dossiê Tramitação, ANPD | `apply-letterhead-pdf-lib.ts` |
| `docx` | Dossiê de manifestação (e todos os Words novos) | `apply-letterhead-docx.ts` |

Cada adaptador recebe o documento + `tenantId` + paths de asset e devolve `LetterheadResult`.

**Rationale**: unificar tudo em PDFKit quebraria Tramitação/ANPD (pdf-lib) e o Word. Três adaptadores finos em volta da mesma métrica/asset evitam reescrita dos miolos.

**Alternatives considered**: gerar sempre PDFKit e converter para Word — rejeitado (conversão PDF→DOCX é perda e dependência nova).

---

## R4 — Tenant AGEMAN por UUID canônico

**Decisão**: reutilizar `00000000-0000-0000-0000-000000000002` (já em `manifestacao-document-branding.ts` e seed). `isAgemanTenant(tenantId)` compara UUID normalizado em minúsculas. `getRequestContext().tenantId` alimenta o kernel — nunca `tenantId` solto no use-case além do contexto.

**Rationale**: FR-005. O branding atual da Ouvidoria já usa esse ID. Centralizar o UUID no kernel e fazer a Ouvidoria importá-lo (um único lugar).

**Alternatives considered**: slug `ageman` no host — rejeitado: o isolamento canônico é `X-Tenant-ID` / ALS, não o hostname.

---

## R5 — Arte ausente: miolo + header HTTP (não JSON wrapping)

**Decisão**: se `isAgemanTenant` e os PNGs não existem / falham ao embutir → **não** carimbar, **não** usar arte antiga, devolver o arquivo mesmo assim e setar `X-Letterhead-Applied: 0`. Se carimbou: `X-Letterhead-Applied: 1`. Tenant não-AGEMAN: header omitido (fallback atual, sem aviso de folha 2026).

Copy do toast no client: *“A folha oficial não pôde ser aplicada. O arquivo contém apenas o conteúdo.”*

**Rationale**: FR-012 + downloads atuais são `StreamableFile` / blob. Embrulhar em JSON quebraria todos os clientes. Header custom é o contrato mínimo (ver `contracts/rest-api-letterhead.md`).

**Alternatives considered**:
- Recusar 503 — rejeitado no clarify (opção C = emitir miolo).
- Voltar ao timbrado antigo — rejeitado no clarify.

---

## R6 — Assets no build (`nest-cli.json`)

**Decisão**: incluir `src/common/letterhead/assets/**/*` em `compilerOptions.assets` (hoje só `modules/ouvidoria/assets/**/*`). `resolve-letterhead-assets` tenta `__dirname`, `src/…` e `dist/…` (mesmo padrão da logo antiga).

**Rationale**: 038 R16 já alertou que PNG de timbrado “precisa de etapa de cópia para o build”. Sem isso, produção cai sempre no FR-012 (miolo sem folha).

---

## R7 — Word em todas as famílias = use-case + rota irmã

**Decisão**: cada família que hoje só tem PDF ganha `generate-*-docx.use-case.ts` (ou `export-*-docx`) que **reusa o mesmo assembly de dados** do PDF e renderiza via `docx` + `apply-letterhead-docx`. Rotas irmãs documentadas no contrato REST. Manifestação já tem PDF+Word — só troca o header.

**Rationale**: FR-008 / SC-008. Constitution V: 1 arquivo = 1 operação. Não inflar o use-case de PDF com um `if (docx)`.

**Alternatives considered**: query `?formato=docx` no mesmo handler — rejeitado: mistura duas saídas no mesmo use-case e complica `StreamableFile` / testes.

---

## R8 — Compras Insights/Maturidade: HTML permanece; ofício é extra de rota

**Decisão**: `GET /compras/insights/export` e `GET /compras/maturidade/export` **continuam HTML**. Novas rotas `…/export/pdf` e `…/export/docx` (e equivalentes de maturidade) geram o ofício. No client, o botão principal vira menu: PDF / Word / “HTML (extra)”.

**Rationale**: clarify Q2=B e Q3=C. Só esses dois módulos têm botão de exportar hoje. Não criar exportação em Ouvidoria/Gabinete/TI/SIGED Insights.

---

## R9 — Sem persistência do ofício

**Decisão**: geração on-demand, como hoje. FR-006 (“arquivos já baixados não são reescritos”) é automaticamente verdadeiro: o que o usuário guardou no disco não muda; um **novo** clique gera folha 2026.

**Rationale**: nenhum `DocumentoEmitido` persistido no Prisma para essas famílias (exceto documento institucional, cujo PDF já é gerado na hora a partir do payload). Não há job de reprocessamento.

---

## R10 — Tenant não-AGEMAN

**Decisão**: kernel retorna `{ applied: false, reason: 'not-ageman' }` e o renderer **mantém o comportamento atual** (Ouvidoria: branding genérico “OUVIDORIA / Sistema de Controle Interno”; Diagnóstico: cabeçalho textual atual; demais: sem folha 2026). Não se aplica a arte da AGEMAN.

**Rationale**: FR-005 / SC-006. Nota: `DiagnosticoLetterheadService` hoje escreve a string `'AGEMAN'` mesmo fora do tenant — **fora desta entrega** corrigir isso (não expandir escopo); apenas garantir que a arte 2026 não vaze.

---

## R11 — Métricas da folha oficial

**Decisão** (medidas do `document.xml` / `header2.xml`):

| Grandeza | Valor |
|---|---|
| Página | A4 portrait (11906 × 16838 twips) |
| Margem superior | 2269 twips ≈ 40,0 mm |
| Margem direita | 992 twips ≈ 17,5 mm |
| Margem inferior | 1276 twips ≈ 22,5 mm |
| Margem esquerda | 1276 twips ≈ 22,5 mm |
| Faixa | ~19,25 cm × 2,89 cm no topo |
| Marca d’água | brasão centrado, atrás do texto |

O miolo começa **abaixo** da faixa (FR-007). Sem linha decorativa mint/azul.

---

## R12 — Como testar a arte sem OCR visual em CI

**Decisão**: testes de kernel (Jest) verificam (1) `applied === true` quando os PNGs existem; (2) PDF/DOCX gerado contém os bytes/embutidos das imagens; (3) PDF AGEMAN **não** contém as strings do timbrado antigo (`OUVIDORIA` como selo de cabeçalho, `#00468C` / `#E8F2FF` da Ouvidoria antiga, “Diagnóstico — documento institucional”); (4) tenant não-AGEMAN não embute os PNGs 2026; (5) assets ausentes → `applied === false` e arquivo ainda válido. Revisão visual humana no `quickstart.md` (SC-002).

**Rationale**: CI não tem aprovador institucional. Os asserts estruturais cobrem FR-002/003/009; SC-002 fica no quickstart.
