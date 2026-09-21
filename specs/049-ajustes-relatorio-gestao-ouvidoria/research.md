# Research: Ajustes na Pesquisa de Satisfação e no Relatório de Gestão da Ouvidoria

**Input**: `spec.md` (com Clarifications 2026-09-21) · Constitution v1.3.0 · Levantamento técnico do codebase real (`ci-api-v2/src/modules/ouvidoria/`), incluindo os artefatos já entregues pela spec 042.

Todas as decisões abaixo são técnicas (arquitetura/implementação); nenhum item de produto ficou aberto — todas as dúvidas de escopo foram resolvidas no `spec.md` (sessão de Clarifications) e na sessão de `/speckit-plan` (contradição do FR-008 vs. Acceptance Scenario da User Story 4, resolvida com o usuário antes deste documento).

## 1. Bug de sobreposição no PDF (US2 / FR-006)

**Root cause identificado no código**: em `ci-api-v2/src/modules/ouvidoria/lib/render-relatorio-gestao-pdf.ts`, a função `addTable()` desenha cada linha com `doc.text(cell, x, y, { width: colW - 4 })` — que já quebra automaticamente o texto (`word-wrap`) dentro da largura da coluna — mas avança `y += 16` de forma **fixa**, sem medir quantas linhas o texto realmente ocupou. Para células curtas isso funciona; para "Motivo" longos (ex.: "Recomposição asfáltica (concessionária abriu buraco e não fechou)"), o texto quebra em 3–4 linhas dentro da coluna, mas a próxima linha da tabela já é desenhada 16pt abaixo — sobrepondo o texto ainda "ocupado" pela linha anterior. É exatamente o comportamento capturado na imagem anexada pelo cliente.

**Decision**: Calcular a altura real de cada linha antes de desenhá-la, usando `doc.heightOfString(cell, { width: colW - 4 })` (API nativa do PDFKit, já usada indiretamente por `doc.text`) para cada célula da linha, tomar o `Math.max(...)` entre as células (mínimo de 16pt, igual ao comportamento atual para linhas de uma linha só), usar esse valor tanto em `ensureSpace(rowHeight)` (antes de desenhar) quanto no avanço `y += rowHeight` (depois). Aplicar isso genericamente em `addTable()` — corrige "Manifestações por motivo" e qualquer outra tabela do mesmo export com texto de tamanho variável (FR-006), sem duplicar lógica por bloco.

**Rationale**: Zero dependência nova — `heightOfString` já existe na API do PDFKit (`^0.19.1`, já instalado). É a correção mínima e localizada (um único arquivo, uma única função) que resolve a causa raiz, não um paliativo (ex.: truncar texto, reduzir fonte, ou fixar uma altura maior "no achismo" que ainda quebraria para motivos muito longos).

**Alternatives considered**:
- Aumentar a altura fixa de 16pt para um valor maior (ex. 40pt): rejeitado — ainda quebraria para o texto mais longo do sistema, além de desperdiçar espaço em linhas curtas (a maioria).
- Truncar o texto do motivo com "…": rejeitado — perde informação que o cliente precisa para conferência, contraria o objetivo do PDF ("arquivar/enviar por e-mail").
- Trocar PDFKit por outra lib com layout de tabela automático (ex. `pdfmake`): rejeitado — nova dependência sem precedente no monorepo, para corrigir um bug que já tem correção simples na lib atual.

## 2. Modelo de dados da Pesquisa de Satisfação (US1 / FR-001 a FR-005)

**Decision**: Alterar o model `OuvidoriaPesquisaSatisfacaoLancamento` (`ci-api-v2/prisma/schema/ouvidoria-catalog.prisma`): remover a coluna `valor Decimal`, adicionar `consultados Int?` (informativo, sem validação cruzada — Edge Case do spec.md), `respostasSim Int @default(0)`, `respostasNao Int @default(0)`. O percentual de satisfação (`respostasSim ÷ (respostasSim + respostasNao)`) passa a ser **derivado em tempo de leitura** (no use-case/mapper), não persistido — mesmo princípio de "sem tabela de cache" já usado no resto do módulo (FR-013).

**Migration**: uma única migration Prisma (`DROP COLUMN valor`, `ADD COLUMN` das três novas) na mesma tabela — sem tabela nova, sem duplicar dados. O único registro manual já existente hoje no modelo antigo (`"Atendimento Geral" 2026/08 = 8.5`, criado durante a validação da spec 042) é **descartado** por esta migration — decisão justificada no spec.md (Assumptions): é dado de transição, nenhum histórico real (spec 041) foi migrado ainda, então não há retrabalho de dado real a perder.

**Rationale**: Reaproveita a mesma tabela e a mesma constraint `@@unique([tenantId, perguntaId, ano, mes])` (upsert, "última gravação vence" — já resolve FR-004 sem mudança de regra). Resolve FR-002 (percentual = Sim ÷ (Sim+Não), "sem dados" quando total é zero) e a decisão de "sem campo `responderam`" tomada em `/speckit-clarify`.

**Alternatives considered**:
- Manter `valor` e adicionar as 3 colunas novas em paralelo (migração "aditiva", sem quebrar o schema antigo): rejeitado no `/speckit-clarify` (User Story 1 já fecha essa decisão — migrar totalmente, não manter os dois modelos).
- Nova tabela `OuvidoriaPesquisaSatisfacaoLancamentoV2` versionada: rejeitado — cria duas fontes de verdade para o mesmo dado, contrariando "sem débito técnico" da spec original (042) e o princípio de banco de dados minimalista da constitution.

## 3. Bloco Orientações/Encaminhamentos detalhado (US3 / FR-007)

**Decision**: Nova query dedicada (`get-relatorio-gestao-orientacoes-encaminhamentos.repository.ts`), agrupando `Manifestacao` por **ano** (`EXTRACT(YEAR FROM "createdAt")`), por **concessão** (reaproveitando exatamente o mapeamento `programa → tipoConcessionaria` já usado em `porMotivo`, `dashboard.repositories.ts` linhas 215–228) e por **canal de atendimento** — usando o campo `serviceMode` (rotulado "Canal de atendimento" na ficha/PDF da manifestação — `documento-header.ts`), decisão tomada em `/speckit-clarify` por já conter valores reais (Presencial, Telefone, E-mail, Aplicativos de mensagem) compatíveis com a planilha, diferente do campo usado no bloco "Forma de Atendimento" já existente (que usa `origem`/`dadosAdicionais.formaAtendimento`, com valores "interna"/"sem_canal" — mantido inalterado, é uma dimensão diferente).

Este bloco **ignora o filtro `year`/`month` do relatório** e sempre retorna o histórico completo multi-ano do tenant — é o próprio propósito do bloco (comparar anos), replicando o comportamento da aba `ORIENTAÇÕES_ENCAMINH.` da planilha (que nunca é "filtrada por mês", sempre mostra 2020→ano atual lado a lado).

**Rationale**: Reaproveita 100% o padrão `$queryRaw` + `COALESCE(NULLIF(TRIM(...)), 'fallback')` já dominante no arquivo; não introduz nova entidade persistida (mantém a restrição do FR-007 original da spec 042: dado deriva exclusivamente de manifestações já existentes). Retornar sempre o histórico completo (sem respeitar o filtro do resto do relatório) é a interpretação mais consistente com "acumulado histórico multi-ano" (spec.md) e evita um contrato ambíguo (ex.: "o que significa filtrar por mês uma comparação entre anos?").

**Alternatives considered**:
- Aplicar o mesmo filtro `year`/`month` do resto do relatório a este bloco também: rejeitado — um filtro de mês/ano não faz sentido para um bloco cujo objetivo é comparar anos entre si; a planilha original nunca filtra essa aba.
- Persistir o detalhamento numa tabela de resumo anual (pré-calculada): rejeitado — mesma restrição de "sem tabela de cache" (FR-013); o volume (~5.160 manifestações no maior tenant) não justifica.

## 4. Catálogo de Eventos Institucionais e lançamento de participações (US4 / FR-008 a FR-010)

**Decision**: Dois models Prisma novos, reaproveitando **dois** padrões já existentes no mesmo arquivo `ouvidoria-catalog.prisma`:
- `OuvidoriaEvento` (catálogo, **CRUD completo pelo usuário final** — decisão tomada nesta sessão de `/speckit-plan`, resolvendo a contradição entre o FR-008 original e o Acceptance Scenario 1 da User Story 4): mesmo formato de `OuvidoriaFormaAtendimento` (`id Int autoincrement`, `tenantId`, `nome`, `ativo`, `deletedAt`, timestamps) — inclusive reaproveitando o mesmo trio de rotas já usado para formas de atendimento (`POST`, `PATCH /:id`, `POST /:id/inativar`, todas hoje sob `@RequireModulo('ouvidoria')`, sem papel adicional).
- `OuvidoriaEventoParticipacaoLancamento` (lançamento mensal, upsert): mesmo formato de `OuvidoriaPesquisaSatisfacaoLancamento`, com `@@unique([tenantId, eventoId, ano, mes])` — resolve a decisão de `/speckit-clarify` de sobrescrever (nunca somar) ao relançar o mesmo evento/mês/ano.

**Rationale**: Ambos os padrões (catálogo com CRUD de usuário final via `formas-atendimento`; lançamento mensal com upsert via `pesquisa-satisfacao`) já existem, testados em produção, no mesmo módulo — esta feature não introduz nenhum padrão arquitetural novo, só combina dois padrões existentes para uma entidade nova.

**Alternatives considered**:
- Catálogo fixo via seed/admin (como perguntas de satisfação): rejeitado nesta sessão de planejamento — contradiz o Acceptance Scenario 1 da spec e não faz sentido de produto (eventos institucionais mudam a cada ano; exigir um deploy/seed para cada evento novo seria fricção desnecessária).
- Reaproveitar a mesma tabela de perguntas de satisfação para eventos (usando `codigo`/`nome` genérico): rejeitado — são conceitos de domínio diferentes (pergunta de pesquisa vs. evento institucional), com regras de edição diferentes (uma é fixa, outra é livre); misturá-los numa tabela só criaria acoplamento acidental.

## 5. Exports (PDF e Excel) — refletir os blocos alterados/novos

**Decision**: Estender os arquivos já existentes sem novo padrão:
- `relatorio-gestao-pdf-sections.ts` / `render-relatorio-gestao-pdf.ts`: atualizar a seção `pesquisaSatisfacao` (novas colunas: Consultados, Sim, Não, %) e adicionar duas seções novas (`orientacoesEncaminhamentos`, `participacaoEventos`), usando o `addTable()` já corrigido (item 1).
- `export-relatorio-gestao-excel.use-case.ts`: atualizar a aba "Pesquisa de satisfação" (mesmas colunas novas) e adicionar duas abas novas ("Orientações e Encaminhamentos", "Participação em Eventos"), reaproveitando a função `addSheet()` já existente — mantendo a restrição já estabelecida (spec 042, FR-010): sem fórmulas, sem gráficos nativos.

**Rationale**: Mesmo padrão 100% reaproveitado (nenhuma lib nova, nenhuma duplicação de lógica de renderização); os dois arquivos já são organizados por "seção = bloco do relatório", então adicionar/alterar seções é a extensão natural do design existente.

**Alternatives considered**: Nenhuma — a spec 042 já fechou esse padrão (research.md §1–2 daquela spec) e nada nesta feature exige mudá-lo.

## 6. Autorização

**Decision**: Todas as rotas novas/alteradas (`OuvidoriaController`) MUST usar `@RequireModulo('ouvidoria')`, sem `@RequireLicenca` adicional — idêntico a `formas-atendimento` e `pesquisa-satisfacao` hoje.

**Rationale**: FR-012 exige a mesma regra de autorização já usada nas demais telas do módulo; nenhuma licença nova foi solicitada.

## Resumo de dependências

| Necessidade | Decisão | Nova dependência? |
|---|---|---|
| Corrigir overlap no PDF | `doc.heightOfString()` (API já existente do PDFKit) | Não |
| Modelo Sim/Não da satisfação | Migration na tabela existente (`OuvidoriaPesquisaSatisfacaoLancamento`) | Não (só migration) |
| Orientações/Encaminhamentos detalhado | `$queryRaw` novo, campo `serviceMode` já existente | Não |
| Catálogo de Eventos | 2 models Prisma novos, padrão já existente (`OuvidoriaFormaAtendimento` + `OuvidoriaPesquisaSatisfacaoLancamento`) | Não (só migration) |
| Exports PDF/Excel | Extensão dos arquivos existentes (PDFKit/ExcelJS já instalados) | Não |
| Autorização | `@RequireModulo('ouvidoria')` (existente) | Não |

**Nenhuma dependência nova é necessária para esta feature** — alinhado com a constitution (III) e com o histórico da spec 042.
