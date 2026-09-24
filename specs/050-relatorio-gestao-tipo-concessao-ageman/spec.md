# Feature Specification: Relatório de Gestão — Tipo de concessão (correção AGEMAN)

**Feature Branch**: `050-relatorio-gestao-tipo-concessao-ageman`

**Created**: 2026-09-24

**Status**: Draft

**Input**: ORQUESTRADOR gap 3 — O bloco do relatório rotulado "Tipo de manifestação" hoje agrega `Manifestacao.type` (`complaint`, `request`, …). O DOCX/planilha AGEMAN pede **tipo de concessão** (Abastecimento/saneamento, transporte, iluminação, …), alinhado ao trecho **TIPO DE CONCESSÃO** da aba **RESUMO GERAL DEMAND.** e à aba **7 — DEMANDAS_EMITIDAS CONC.** da planilha `PLANILHAS OUVIDORIA AGEMAN - 2026`.

**Relacionamento**: Corrige entrega da spec [042](../042-relatorio-gestao-ouvidoria/spec.md) (US4 / Clarification 2026-08-27 Q4), que assumiu erroneamente `Manifestacao.type`. Não altera o catálogo `OuvidoriaTipoManifestacao` nem o campo `type` das manifestações — apenas a **agregação do relatório de gestão**.

## Clarifications

### Session 2026-09-24

- Q: Renomear a chave JSON `porTipoManifestacao`? → A: **Não** — manter a chave e o identificador de bloco `porTipoManifestacao` (PDF parcial, Excel, Zod enum de `bloco`) para compatibilidade de contrato HTTP; corrigir **semântica** e **rótulos de UI/export**.
- Q: Nome do campo em cada linha da série? → A: Introduzir **`tipoConcessao`** como campo canônico; manter **`type`** espelhando o mesmo valor de `tipoConcessao` (deprecated para leitura semântica antiga — ver contrato).
- Q: Qual mapa programa → concessão? → A: O **mesmo** `CASE TRIM(programa) …` + fallback `serviceMode` já usado em `porMotivo` em `dashboard.repositories.ts` (não o variant de orientações que cai direto em `'Não informado'`).
- Q: Rótulos exatos vs planilha? → A: Usar rótulos canônicos do produto (`Água / Saneamento`, `Transporte Coletivo`, `Iluminação Pública`, `Coleta de Lixo`, `Zona Azul`); validação contra planilha aceita equivalência semântica (ex.: planilha "ABASTECIMENTO/COLETA DE ESGOTO" ↔ API "Água / Saneamento").

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Ver tipo de concessão no relatório (Priority: P1)

Como usuário do módulo Ouvidoria (AGEMAN), quero que o bloco antes intitulado "Tipo de manifestação" mostre a distribuição por **tipo de concessão** (água/saneamento, transporte, iluminação, etc.), coerente com a planilha manual e com o parágrafo do DOCX ("De acordo com Formulário: Abastecimento/saneamento; transporte coletivo e demais opções"), para que o relatório deixe de exibir reclamação/solicitação/elogio.

**Why this priority**: Gap 3 bloqueia paridade com o entregável AGEMAN; números atuais não são comparáveis à planilha.

**Independent Test**: Filtrar ano 2026 acumulado; somar totais do bloco por concessão e comparar com rollup de `porMotivo` agrupado por `tipoConcessionaria` no mesmo período — deve bater. Conferir amostra contra aba RESUMO GERAL (TIPO DE CONCESSÃO) e aba 7 (totais por mês × concessão).

**Acceptance Scenarios**:

1. **Given** manifestações com `programa` `agua`/`1`, `3`, `2`, etc., **When** o relatório carrega, **Then** o bloco lista rótulos de concessão (não `complaint`/`request`).
2. **Given** o mesmo tenant e período, **When** somo `total` do bloco por `tipoConcessao`, **Then** o resultado equals soma de `porMotivo` agrupado por `tipoConcessionaria` (mesma regra de mapa + fallback).
3. **Given** período sem manifestações, **When** abro o bloco, **Then** exibo estado vazio ("Nenhum tipo de concessão no período") sem erro.

---

### User Story 2 - Exports PDF/Excel alinhados (Priority: P1)

Como usuário que arquiva o relatório, quero PDF (completo e por bloco) e Excel com título/aba **Tipo de concessão** e colunas coerentes, para substituir a planilha sem retrabalho manual.

**Why this priority**: AGEMAN entrega PDF/DOCX derivado dos mesmos blocos.

**Independent Test**: Exportar Excel; aba renomeada; coluna "Tipo" contém concessões. PDF seção `porTipoManifestacao` com título "Tipo de concessão".

**Acceptance Scenarios**:

1. **Given** relatório com dados, **When** exporto Excel, **Then** a aba não se chama mais "Tipo de manifestação" e os valores não são enums de `Manifestacao.type`.
2. **Given** export PDF por bloco `bloco=porTipoManifestacao`, **When** abro o arquivo, **Then** o título exibido é "Tipo de concessão" (identificador de bloco inalterado).

---

### User Story 3 - Compatibilidade de integração (Priority: P2)

Como mantenedor do `@ci/web`, quero que o client continue parseando `porTipoManifestacao` sem mudança de shape estrutural, migrando labels para concessão via `tipoConcessao` (e deixando de mapear `type` com `TYPE_OPTIONS`).

**Why this priority**: Evita quebra de deploy desacoplado; único consumidor conhecido é o monorepo.

**Independent Test**: Contrato Zod/TypeScript aceita linhas com `tipoConcessao` + `type` duplicado; testes de mapper não referenciam `Reclamação`/`Solicitação` neste bloco.

**Acceptance Scenarios**:

1. **Given** resposta da API, **When** o client agrega o gráfico, **Then** usa `tipoConcessao ?? type` e rótulos de concessão.

---

### Edge Cases

- `programa` vazio ou código desconhecido: aplicar fallback `serviceMode`; se ainda vazio, agrupar como **"Não informado"** (exibição), consistente com outros blocos geográficos.
- Manifestações **institucionais** (`programa = institucional`): entram no bucket mapeado ou em "Não informado" conforme o CASE (sem inventar concessão).
- Tenant não-AGEMAN: bloco continua genérico — mapa reflete programas cadastrados; sem hardcode de tenant.
- Acumulado geral / filtro só mês: mesmas regras de período da spec 042 (`createdAt`, eixo mês 1–12).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: O bloco JSON `porTipoManifestacao` MUST agregar manifestações por **mês civil** (1–12 no recorte do filtro) e **tipo de concessão**, derivado de `Manifestacao.programa` com o mapa SQL equivalente ao de `porMotivo` em `GetDashboardAgregacoesRepository` (`dashboard.repositories.ts`), incluindo fallback `NULLIF(TRIM("serviceMode"), '')`.
- **FR-002**: Cada item da série MUST expor `tipoConcessao: string` (canônico) e `type: string` com **o mesmo valor** que `tipoConcessao` (compatibilidade); `type` MUST NOT conter valores enum `ManifestacaoType` neste bloco após a mudança.
- **FR-003**: UI MUST renomear título/descrição/empty state de **"Tipo de manifestação"** para **"Tipo de concessão"**; descrição MUST referir programa/concessão do formulário, não `Manifestacao.type`.
- **FR-004**: PDF e Excel MUST usar título/aba **"Tipo de concessão"**; cabeçalho de coluna preferencial **"Concessão"** (ou "Tipo" com legenda no PDF — ver contrato).
- **FR-005**: Identificadores estáveis (`porTipoManifestacao`, query `bloco=porTipoManifestacao`, nome interno do repository/use-case existentes) MUST permanecer — apenas semântica e copy mudam.
- **FR-006**: Implementação MUST extrair o fragmento SQL `CASE TRIM(programa)…` para um único lugar compartilhado (DRY entre dashboard, relatório tipo concessão e, opcionalmente, orientações — fora do escopo mínimo se YAGNI, mas dashboard + relatório são obrigatórios).
- **FR-007**: Testes MUST provar paridade numérica com rollup de `porMotivo` no mesmo período (tolerância zero).

### Non-Functional

- **NFR-001**: Mesmos limites de performance da spec 042 (≤ 5s tela, ≤ 30s export).
- **NFR-002**: Sem migration Prisma; sem nova tabela.

## Success Criteria

- **SC-001**: Export DOCX/planilha AGEMAN de referência — totais por concessão no período 2026-acumulado conferem com aba RESUMO GERAL (TIPO DE CONCESSÃO) dentro de equivalência de rótulo documentada.
- **SC-002**: Nenhuma ocorrência de `complaint`/`request`/`praise` nos exports deste bloco para tenant AGEMAN seed/migrado.
- **SC-003**: Spec 042 permanece histórica; gap documentado como resolvido pela 050.

## Assumptions

- O gráfico continua sendo barras horizontais agregadas no período (mesmo componente base); rename de arquivo `TipoManifestacaoChartCard` → `TipoConcessaoChartCard` é opcional (cosmético).
- Não se cria bloco separado "tipo de manifestação (complaint/request)" — se necessário no futuro, seria outra feature.

## Out of Scope

- Alterar `Manifestacao.type` ou catálogo `OuvidoriaTipoManifestacao`.
- Replicar layout multi-ano da aba 7 (matriz ano×mês×concessão) — escopo 050 é o bloco mensal já existente no relatório web, com totais comparáveis.
- Dashboard ouvidoria (`porTipo` por `serviceMode`) — permanece como está.
