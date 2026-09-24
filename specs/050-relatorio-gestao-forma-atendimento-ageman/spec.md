# Feature Specification: Forma de atendimento no Relatório de Gestão (AGEMAN gap 2)

**Feature Branch**: `050-relatorio-gestao-forma-atendimento-ageman`

**Created**: 2026-09-24

**Status**: Draft

**Input**: Orquestrador gap 2 — o bloco "Forma de atendimento" do Relatório de Gestão (spec 042) agrega por `origem`/`dadosAdicionais.formaAtendimento` (`interna`, `sem_canal`), enquanto o DOCX/planilha AGEMAN exige Presencial, WhatsApp, E-mail, Call Center, Fala.br (`FORMAS_ATENDIMENTO`, `FORMAS ATENDIMENTO_GRAF`). A spec 049 corrigiu orientações/encaminhamentos com `serviceMode` e deixou este bloco para uma entrega dedicada.

## Clarifications

### Session 2026-09-24

- Q: Qual fonte canônica para agrupar "forma de atendimento"? → A: **`Manifestacao.serviceMode`**, com fallback `'Não informado'` quando vazio — alinhado ao catálogo `OuvidoriaFormaAtendimento` na escrita e ao rótulo "Canal de atendimento" na ficha/PDF (`research.md` §2–§3).
- Q: `origem` continua aparecendo no relatório? → A: **Não** no bloco Forma de atendimento após esta feature; `origem` permanece campo de proveniência da manifestação, não canal.
- Q: Rollup para buckets da planilha (WHATSAPP, CALL CENTER, …)? → A: **P1** entrega valores do catálogo (`Aplicativos de mensagem`, `0800`, …); **P2 (opcional na mesma branch)** rollup AGEMAN para exports/gráfico espelhando `FORMAS ATENDIMENTO_GRAF` (`research.md` D2).
- Q: Altera schema Prisma? → A: **Não** — só query de agregação e rótulos de exibição.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Ver formas reais de atendimento no relatório (Priority: P1)

Como usuário da Ouvidoria AGEMAN, quero que o bloco "Forma de atendimento" do relatório de gestão (tela e exports) mostre as mesmas categorias que registramos na manifestação (Presencial, E-mail, Aplicativos de mensagem, 0800, Fala.Br, etc.), agrupadas por mês no período filtrado, para substituir os totais enganosos "Interna" e "Sem canal".

**Why this priority**: É a divergência mais visível entre o relatório exportado e a planilha manual; invalida o bloco inteiro para o cliente.

**Independent Test**: Abrir relatório de gestão AGEMAN (ano 2026 ou acumulado), comparar totais do bloco com contagem SQL/manual por `serviceMode` no mesmo período — deve coincidir; não deve aparecer `interna`/`sem_canal` salvo manifestações sem `serviceMode` (exibidas como "Não informado").

**Acceptance Scenarios**:

1. **Given** manifestações AGEMAN com `serviceMode` preenchido (ex.: 250 "Aplicativos de mensagem"), **When** o usuário abre o bloco Forma de atendimento filtrando o ano correspondente, **Then** os totais por forma batem com `GROUP BY serviceMode` e **não** listam `interna`.
2. **Given** manifestações com `serviceMode` NULL/vazio, **When** agregadas no bloco, **Then** entram na série **"Não informado"** (não `sem_canal`).
3. **Given** export PDF ou Excel do relatório, **When** inclui a seção Forma de atendimento, **Then** usa os mesmos rótulos exibidos na tela (via mapper/`labelFormaAtendimento`).

---

### User Story 2 - Dashboard Ouvidoria e Diretor consistentes (Priority: P1)

Como usuário que acompanha indicadores no dashboard da Ouvidoria ou no módulo Diretor, quero que o gráfico/série "por forma de atendimento" use a mesma regra do relatório de gestão, para não ver `Interna`/`Sem canal` enquanto o relatório já mostra canais reais.

**Why this priority**: A mesma query SQL alimenta três superfícies; corrigir só o relatório deixaria inconsistência operacional.

**Independent Test**: `GET /ouvidoria/dashboard/agregacoes` e painel Diretor — mesmos totais que `GET /ouvidoria/relatorio-gestao` para `porFormaAtendimento` no mesmo `year`/`month`.

**Acceptance Scenarios**:

1. **Given** filtro ano/mês idêntico, **When** comparar `porFormaAtendimento` entre dashboard e relatório de gestão, **Then** séries idênticas (mesmos `forma` e `total` por mês).

---

### User Story 3 - Paridade opcional com buckets da planilha AGEMAN (Priority: P2)

Como gestor que ainda reconcilia com `FORMAS ATENDIMENTO_GRAF`, quero que gráficos/exports possam agrupar as descrições do catálogo nos buckets **PRESENCIAL, CALL CENTER, CELULAR, E-MAIL, WHATSAPP, FALA.BR, OUTROS**, para facilitar comparação lado a lado com a planilha histórica.

**Why this priority**: Valor analítico após corrigir o dado bruto (US1); mapping é específico AGEMAN.

**Independent Test**: Aplicar mapa documentado em `research.md` D2 sobre totais US1 — soma por bucket deve igualar total de manifestações do período (modulo arredondamentos).

**Acceptance Scenarios**:

1. **Given** tenant AGEMAN, **When** exibir modo "visão planilha" *(se implementado)* ou export DOCX configurado, **Then** "Aplicativos de mensagem" conta em WHATSAPP e "0800" em CALL CENTER conforme tabela de rollup.

---

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: A agregação `porFormaAtendimento` MUST usar `Manifestacao.serviceMode` com fallback `'Não informado'`, respeitando filtros `year`/`month` existentes do relatório/dashboard (mesma semântica da spec 042).
- **FR-002**: O bloco MUST NOT usar `origem` nem `dadosAdicionais.formaAtendimento` como dimensão de forma de atendimento.
- **FR-003**: Tela, PDF, Excel e PDF por bloco MUST refletir os mesmos dados JSON de `porFormaAtendimento` após a alteração.
- **FR-004**: A UI MUST usar `labelFormaAtendimento` (ou equivalente centralizado) para rótulos — eliminar mapa local só com `interna`/`sem_canal` na página do relatório.
- **FR-005** *(P2)*: MAY aplicar rollup AGEMAN catálogo → buckets planilha conforme `research.md` D2, sem alterar o valor bruto retornado na API (rollup só na camada de apresentação ou campo derivado documentado no contrato).

### Non-Functional Requirements

- **NFR-001**: Sem migration Prisma; sem cache persistente (herda FR-013 da spec 042).
- **NFR-002**: Performance igual à spec 042 — p95 ≤ 5s relatório, ≤ 30s exports.

### Key Entities

- **`Manifestacao.serviceMode`**: string opcional — forma/canal registrada na manifestação.
- **`OuvidoriaFormaAtendimento`**: catálogo tenant (referência na UI; não FK na agregação).

## Success Criteria

- **SC-001**: Tenant AGEMAN — zero ocorrências de `interna`/`sem_canal` no bloco Forma de atendimento quando todas as manifestações têm `serviceMode` preenchido.
- **SC-002**: Totais do bloco = contagem manual por `serviceMode` (±0) para qualquer filtro `year`/`month` testado.
- **SC-003**: Dashboard Ouvidoria e Diretor alinhados ao relatório (US2).

## Assumptions

- Spec 049 pode estar concluída ou em merge; esta feature não altera `orientacoesEncaminhamentos`.
- Manifestações históricas sem `serviceMode` permanecem como "Não informado" até backfill opcional (spec 041 / script ad hoc).
- Outros tenants beneficiam-se da correção genérica (não só AGEMAN).

## Out of Scope

- Renomear "Canal de atendimento" → "Forma de atendimento" na ficha PDF (`documento-header.ts`).
- Nova coluna FK `formaAtendimentoId` em `Manifestacao`.
- Série histórica multi-ano estilo planilha (gap 4 — spec dedicada).
