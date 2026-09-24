# Feature Specification: Série histórica mês×ano — Relatório de Gestão (paridade RESUMO GERAL / MENSAL_DEMAND)

**Feature Branch**: `050-relatorio-gestao-serie-historica-ageman`

**Created**: 2026-09-24

**Status**: Draft

**Input**: User description: "ORQUESTRADOR gap 4 — O relatório de gestão (spec 042, ajustes 049) filtra um único ano/mês ou agrega meses somando todos os anos (12 barras). A planilha manual AGEMAN (`PLANILHAS OUVIDORIA AGEMAN - 2026 - 08 e Consolidado.xlsx`, abas **RESUMO GERAL DEMAND.** e **MENSAL_DEMAND._GRAF.**) exibe grades **12 meses × colunas por ano** (2018–2026) com **total acumulado por linha** e **percentual** sobre o grand total. Fechar essa lacuna sem tabelas de cache (FR-013 herdado da 042)."

## Clarifications

### Session 2026-09-24

- Q: Estender o `GET /ouvidoria/relatorio-gestao` existente ou rota dedicada? → A: **Rota dedicada** `GET /ouvidoria/relatorio-gestao/serie-historica` (lazy load na UI). O relatório “por período” permanece inalterado; evita estourar SC-005 ao abrir a tela padrão. Query opcional `modo=historico` **não** será adicionada ao endpoint principal — `modo` fica documentado apenas como conceito de produto (“visão histórica” = chamar a rota dedicada).
- Q: Quais blocos ganham grade mês×ano no MVP? → A: **P1** — somente **Atendimentos por mês** (grade canônica da planilha). **P2** — **Resolutividade** e **Tipo de concessão** em grade **ano×métrica** (linhas de indicador/concessão × colunas de ano + total acumulado + %), como o bloco superior de RESUMO GERAL (não a matriz tridimensional mês×concessão×ano da aba DEMANDAS_EMITIDAS CONC.). **Fora do MVP** — **Forma de atendimento** mês×canal×ano (aba FORMAS_ATENDIMENTO): depende de cobertura do campo “Canal de atendimento” e de paridade de rótulos com a planilha; entra em spec futura após 049 estabilizado.
- Q: Faixa de anos fixa 2018–2026? → A: **Configurável por query** `yearFrom`/`yearTo` com defaults **2018** e **ano civil corrente** (tenant); colunas só para anos com pelo menos um registro ou todos os anos do intervalo (decisão técnica no plano — UI exibe colunas vazias como `0`).
- Q: Resolutividade na planilha mistura visões (totais anuais no RESUMO vs. mês a mês no QUANT_MENSAL). O que entregar primeiro? → A: MVP entrega **totais anuais por categoria** (resolvidas pela ouvidoria, optou por meio jurídico, pendentes) alinhados às linhas 26–30 de RESUMO GERAL; grade **mês×ano** de resolutividade fica **P3** (paridade QUANT_MENSAL), não bloqueia MVP.
- Q: Export PDF/Excel? → A: **Excel P2** — aba(s) espelhando as grades da visão histórica; **PDF P3** — tabelas wide são legibilidade difícil; MVP prioriza tela + Excel.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Ver atendimentos mês×ano (2018–2026) (Priority: P1)

Como usuário do módulo Ouvidoria, quero abrir uma visão “Série histórica” que mostre **quantos atendimentos** houve em **cada mês de cada ano**, com **total acumulado por mês civil** e **percentual** sobre o total geral — no mesmo espírito da planilha RESUMO GERAL / MENSAL_DEMAND — para comparar sazonalidade e evolução anual sem montar a matriz à mão.

**Why this priority**: É o núcleo do gap 4; todas as outras grades da planilha derivam ou complementam essa matriz.

**Independent Test**: Comparar a linha “AGOSTO” (ou qualquer mês) coluna “2025” com `COUNT(*)` de manifestações do tenant com `createdAt` naquele mês/ano; conferir total acumulado da linha = soma das colunas de ano; conferir % = linha ÷ grand total.

**Acceptance Scenarios**:

1. **Given** manifestações distribuídas de 2018 a 2026, **When** o usuário abre a série histórica de atendimentos, **Then** a grade exibe 12 linhas (meses 1–12), colunas por ano no intervalo, coluna de total acumulado por mês e coluna de percentual sobre o total geral.
2. **Given** um mês/ano sem registros, **When** a grade é renderizada, **Then** a célula exibe `0` (não omite a coluna nem quebra a grade).
3. **Given** março/2018 parcial na migração (primeiro dia com dado), **When** o usuário confere totais, **Then** os números refletem **todas** as manifestações no banco para aquele mês/ano (mesma regra FR-003 da 042 — sem snapshot); divergência pontual vs. planilha legada é aceitável se a migração tiver recorte de datas documentado na 041.

---

### User Story 2 - Resolutividade e concessão em colunas por ano (Priority: P2)

Como usuário do módulo Ouvidoria, quero ver, na mesma visão histórica, **totais anuais** de resolutividade (resolvidas, meio jurídico, pendentes) e **totais anuais por tipo de concessão**, cada um com **total acumulado** e **%** — como as seções “DEMANDAS E RESOLUTIVIDADE” e “TIPO DE CONCESSÃO” do RESUMO GERAL — sem precisar filtrar ano a ano no relatório atual.

**Why this priority**: Completa o RESUMO GERAL para gestão; não exige matriz tridimensional mês×concessão×ano.

**Independent Test**: Para um ano fixo, somar colunas da grade de resolutividade e comparar com KPIs do relatório por período (`year=YYYY`); concessão por ano vs. agregação `porConcessao` existente no dashboard/relatório.

**Acceptance Scenarios**:

1. **Given** manifestações com status de encerramento/resolutividade conhecidos, **When** a grade de resolutividade anual é exibida, **Then** cada linha (resolvidas / meio jurídico / pendentes) soma, por coluna de ano, os mesmos critérios já usados no bloco de resolutividade da spec 042.
2. **Given** manifestações com tipo de concessionária, **When** a grade de concessão anual é exibida, **Then** cada linha é um tipo canônico de concessão do tenant e cada coluna é o total daquele ano.

---

### User Story 3 - Exportar série histórica em Excel (Priority: P2)

Como usuário, quero exportar as grades da série histórica para Excel (uma aba por bloco MVP/P2), para arquivar e conferir como hoje na planilha consolidada.

**Why this priority**: Entrega o artefato que o cliente ainda usa para e-mail/arquivo; depende das grades US1/US2.

**Independent Test**: Gerar `.xlsx`, abrir aba “Atendimentos mês×ano” e validar que cabeçalhos de ano e linha TOTAL batem com a tela.

**Acceptance Scenarios**:

1. **Given** a visão histórica carregada, **When** o usuário exporta Excel da série histórica, **Then** recebe arquivo com abas para atendimentos mês×ano e, se implementado US2, resolutividade anual e concessão anual — valores calculados, sem fórmulas nativas (mesma regra FR-010 da 042).

---

### User Story 4 - Forma de atendimento mês×canal×ano (Priority: P3 — fora do MVP)

Como usuário, quero a grade da aba FORMAS_ATENDIMENTO (mês × canal × anos). **Escopo explícito pós-MVP**: requer mapeamento estável do canal de atendimento na ficha (049) e inventário de rótulos legados (Call center, WhatsApp, Fala.br, etc.).

**Independent Test**: Diferido até spec dedicada ou extensão 050 v2.

---

### Edge Cases

- Tenant sem dados antes de 2018: colunas 2018–… exibem zeros; grand total reflete só anos com dado.
- Intervalo `yearFrom` > `yearTo`: resposta `400` de validação Zod.
- Ano corrente incompleto (ex. fechamento agosto/2026): meses futuros no ano corrente exibem `0`, como na planilha (SET–DEZ/2026 zerados).
- Performance com ~5k+ manifestações (AGEMAN): endpoint dedicado MUST responder em ≤ 5s p95 (SC-005 aplicado à rota de série histórica); export Excel ≤ 30s — **sem** tabela de cache (FR-013).
- Usuário sem módulo Ouvidoria: `403` como demais rotas do relatório.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: O sistema MUST oferecer uma **visão “Série histórica”** no relatório de gestão da Ouvidoria, distinta do filtro ano/mês atual, consumindo **`GET /ouvidoria/relatorio-gestao/serie-historica`** (contrato em `contracts/serie-historica-relatorio-gestao.md`).
- **FR-002** (MVP): A resposta MUST incluir a grade **`atendimentosMesAno`**: 12 meses × colunas por ano + `totalAcumuladoPorMes` + `percentualSobreTotalGeral` por linha + linha `totais` (soma por coluna e grand total), espelhando a semântica da planilha RESUMO GERAL / MENSAL_DEMAND.
- **FR-003** (P2): A resposta MUST incluir **`resolutividadeAnual`** e **`concessaoAnual`**: linhas de métrica/concessão × colunas por ano + total acumulado + percentual, usando as mesmas regras de classificação dos blocos homônimos do relatório por período (042).
- **FR-004**: Query **`yearFrom`** / **`yearTo`** (opcionais, defaults 2018 e ano corrente) MUST delimitar colunas; **`month`** MUST NOT ser suportado nesta rota (sempre 12 meses).
- **FR-005**: O endpoint MUST NOT alterar o comportamento de `GET /ouvidoria/relatorio-gestao` (modo período).
- **FR-006** (P2): O sistema MUST oferecer **`GET /ouvidoria/relatorio-gestao/serie-historica/excel`** com as abas correspondentes às grades retornadas.
- **FR-007**: Todos os valores MUST ser recalculados on-demand do banco (FR-003 da 042).
- **FR-008**: Acesso MUST seguir `@RequireModulo('ouvidoria')` (mesma regra FR-011 da 042).
- **FR-009** (P3): Grade mês×ano de resolutividade (QUANT_MENSAL) e grade forma de atendimento mês×canal×ano MUST permanecer **fora de escopo** até extensão documentada.
- **FR-010** (P3): Export PDF da série histórica — fora do MVP.
- **FR-013**: Nenhuma agregação introduzida por esta feature MUST usar tabela de cache/pré-cálculo persistente; otimização via índices e consultas agregadas eficientes (herda 042/049).

### Key Entities

- **Grade mês×ano (visão)**: composição em memória; não persistida.
- **Manifestação**: fonte única para atendimentos, resolutividade e concessão (campos e joins já usados na 042).

## Success Criteria *(mandatory)*

- **SC-001**: Usuário substitui a matriz manual “Atendimentos por mês” da planilha RESUMO GERAL pela tela/export da série histórica com conferência numérica em amostra (≥ 3 células mês×ano + totais).
- **SC-002**: Abrir o relatório **por período** (rota existente) mantém tempo ≤ 5s — série histórica carregada só ao entrar na aba (lazy).
- **SC-003**: `GET .../serie-historica` p95 ≤ 5s no tenant AGEMAN (acumulado 2018–ano corrente); Excel ≤ 30s.
- **SC-004**: Revisão técnica confirma ausência de tabela de cache (FR-013).

## Assumptions

- Depende da spec **042** entregue e preferencialmente **049** (canal de atendimento) para evoluções futuras de “forma”; MVP não exige 049 concluída para US1.
- Primeiro dia com dado em 2018 na AGEMAN (migração 041) pode diferir da planilha (“14/03/2018”); produto aceita banco como fonte da verdade.
- Médias mensais por ano (“MÉDIA MENSAL=” na planilha) **fora do MVP** — podem ser calculadas no client a partir da grade se necessário.
- Satisfação, orientações/encaminhamentos, participação em eventos, zona/bairro/motivo **não** entram nesta feature (outras abas/planos).

## Out of scope (esta spec)

- Gráficos Nivo espelhando abas `*_GRAF` (opcional polish posterior; não bloqueia paridade tabular).
- Matriz mês × concessão × ano (aba DEMANDAS_EMITIDAS CONC.).
- Alteração do módulo Diretor.
