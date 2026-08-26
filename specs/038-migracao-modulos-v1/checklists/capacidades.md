# Checklist de capacidades — Spec 038 (SC-006)

**Verificação técnica (agente) — não substitui aceite do responsável do módulo.**

**Propósito**: Nenhuma capacidade que o servidor da AGEMAN tinha no v1 nos módulos migrados deixa de existir no v2. Assinatura humana obrigatória antes da liberação.

**Estado**: verificação técnica 2026-08-21 — `[x]` só com arquivo + teste que cobre. Playwright e carga live (`MYSQL_V1_URL`) **não rodaram**. Fora de escopo: fiscalização, insights com IA, maturidade.

**Resumo técnico**: 29 `[x]` / 25 `[ ]` (54 itens). SC-006 **ainda bloqueia** liberação (gaps + sem assinatura humana).

---

## Como assinar

Cada responsável marca `[x]` só depois de conferir no v2, com dados reais da AGEMAN, que a capacidade existe e o fluxo fecha sem recorrer ao v1. Data e nome no rodapé da seção.

A marcação abaixo é só evidência de código/teste. **Não é aceite de produto.**

---

## Ouvidoria (US2)

- [ ] Painel gerencial com os indicadores do período (total, pendentes, em análise real, respondidas, encerradas com/sem resolução)
  - **Gap**: API e tela têm total / em análise / respondidas / encerradas com e sem resolução (`dashboard.repositories.ts`, `OuvidoriaDashboardPage.tsx`; testes `dashboard-agregacoes.use-case.spec.ts`, `OuvidoriaDashboardPage.test.tsx`). **Falta KPI "pendentes"** (existe só a série `demandasPendentes`). Sem filtro mês na tela (query aceita `month`).
- [ ] Gráficos do período equivalentes aos do v1 (Nivo no v2)
  - **Gap**: API devolve 7 séries; a tela só desenha 2 (resolutividade e atendimentos por mês) com `ResponsiveBar`. Faltam gráficos de finalizadas, pendentes, tipo, forma e motivo.
- [x] Listar manifestações com filtros de situação, prioridade, tipo, motivo, canal, origem e período
  - `list-manifestacoes.use-case.ts` + `ManifestacoesListPage.tsx`; schema em `ouvidoria.schemas.ts`; e2e `ouvidoria-paridade.e2e.spec.ts` (escrito, não executado neste ciclo).
- [x] Paginação percorre todos os registros (filtro no servidor)
  - `skip`/`take` em `manifestacao.repositories.ts`; `sc012-server-list.spec.ts`.
- [ ] Registrar manifestação com protocolo e número institucional sem colisão
  - **Gap**: sequence + `@@unique([tenantId, protocol])` e `numeroPersonalizado` no Prisma; `confirm-manifestacao.use-case.spec.ts` só confere protocolo devolvido. Sem teste de concorrência/colisão. Número institucional é campo opcional do rascunho, não sequence.
- [x] Editar rascunho e confirmar
  - `update-manifestacao-draft.use-case.spec.ts`, `confirm-manifestacao.use-case.spec.ts`, `ManifestacaoWizardPage.tsx`.
- [x] Responder ao cidadão (data, autor, evento na linha do tempo)
  - `responder-manifestacao.use-case.ts` + spec; evento na timeline (`ManifestacaoDetailPage.tsx`). **Ressalva**: `respondidoEm`/`respondidoPorId` não são gravados no update de status.
- [ ] Encaminhar para setor gerando demanda vinculada (navegável nos dois sentidos)
  - **Gap**: encaminhar cria demanda de tramitação (`encaminhar-manifestacao-tramitacao.integration.spec.ts`) e navega para `/tramitacao/protocolos/:id`. Ato do Gabinete liga `manifestationId` → manifestação. Detalhe da manifestação **não** lista demanda persistente; o outro sentido some depois do toast.
- [x] Encerrar informando se houve resolução (`closed` / `closed_unresolved`)
  - `encerrar-manifestacao.use-case.spec.ts`; UI `ManifestacaoActionDialogs.test.tsx`.
- [ ] Gerar carta/documento em DOCX e PDF com timbre e campos do v1
  - **Gap**: endpoints e `generate-manifestacao-{docx,pdf}.use-case.ts` existem; controller spec só delega. Timbre genérico (`documento-letterhead.ts`: "Ouvidoria"), sem paridade de campos/timbre do v1 nem teste de conteúdo.
- [x] Consultar respostas e arquivados
  - Mesma listagem com filtro `answered` / `closed` / `closed_unresolved` (`ManifestacoesListPage.tsx` + schema). Sem telas separadas — paridade de capacidade via filtro no servidor.
- [ ] Catálogos: tipos, assuntos e formas de atendimento (criar, editar, inativar; item em uso não exclui)
  - **Gap**: criar + inativar cobertos (`catalogos.use-case.spec.ts`, `OuvidoriaCatalogosPage.tsx`). Editar só forma na API (`update-forma-atendimento.use-case.ts`), sem UI. Tipos/assuntos sem update.
- [ ] Atendimentos internos (registrar, editar, excluir — sem gerar manifestação)
  - **Gap**: só criar + listar (`create-atendimento-interno.use-case.ts` + spec; `OuvidoriaAtendimentosPage.tsx`). Sem editar/excluir (endpoint, use-case, tela).
- [ ] Auditoria filtrável por período, autor e tipo
  - **Gap**: `GET /ouvidoria/auditoria` + `list-auditoria.repository.ts` + teste no `ouvidoria.controller.spec.ts`. A rota `/ouvidoria/auditoria` no client é **fiscalização Jatobá** (`OuvidoriaAuditoriaPage.tsx`), fora de escopo. Sem tela da trilha de eventos.
- [ ] Anexos abrem; chave migrada do v1 sem prefixo extra
  - **Gap**: chave verbatim (`anexo.mapper.spec.ts`); `WASABI_PREFIX` vazio em `env.schema.ts` (sem assert no `env.schema.spec.ts`). Detalhe presigna download (`get-manifestacao-detail.use-case.ts`). Sem teste de abertura; `migracao:anexos` não rodou.

**Assinado por**: _________________ **Data**: __________

---

## Gabinete — demandas e tramitação (US3)

- [x] Encaminhar: situação vai para aguardando recebimento **e o setor atual muda**
  - `forward-cabinet.use-case.ts` + `forward-cabinet.use-case.spec.ts` (T062).
- [x] Receber (só quando aguarda recebimento; notifica quem encaminhou)
  - `receber-demanda.use-case.spec.ts`; botão na `GabineteAtoDetailPage.tsx`; `fluxo-acoes.test.tsx`.
- [x] Devolver (só a partir do setor jurídico, destino restrito a Ouvidoria|Gabinete)
  - `devolver-demanda.use-case.spec.ts`; UI via `prompt` no detalhe; `fluxo-acoes.test.tsx`.
- [x] Reencaminhar distinguível do primeiro encaminhamento no histórico
  - Evento `forwarded` com `payload.kind = 'reforwarded'` (`reencaminhar-demanda.use-case.spec.ts`).
- [ ] Anexar resposta sem alterar situação nem setor
  - **Gap**: use-case e `POST .../anexar-resposta` existem. Sem spec Jest. Client **não** expõe a ação (`cabinets.ts` / detalhe).
- [x] Histórico em PDF (ordem cronológica, autor e setores)
  - `generate-historico-pdf.use-case.spec.ts`; download no detalhe (`fluxo-acoes.test.tsx`).
- [x] Lista de atos/demandas com filtros de setor e período no servidor
  - `list-cabinets.use-case.ts`; `GabineteAtosListPage.filters.test.tsx`.
- [ ] Ciclo completo sem recorrer ao v1 (SC-014)
  - **Gap**: e2e `gabinete-demandas-paridade.e2e.spec.ts` escrito, **não executado**. Falta anexar resposta na UI. Devolver/reencaminhar via `window.prompt`.

**Assinado por**: _________________ **Data**: __________

---

## Gabinete — cadastros (US4)

- [ ] Protocolos: filtros e paginação no servidor; anexos abrem
  - **Gap**: lista manda `q`/`page`/`limit`, mas `ListProtocolosUseCase` fatia em memória após `findMany`. Presign de anexo na API; detalhe importa presign e **não** lista/abre anexos. Spec só cobre create/vincular (`protocolo-crud.use-case.spec.ts`).
- [x] Documentos tramitados: cadastro único filtrável por setor; 13 origens presentes
  - Modelo único + filtro `sectorId` na lista; 13 tabelas em `documentos-tramitados.mapper.spec.ts`.
- [x] Coluna de ordem **não** vira quantidade; prazo **não** vira observação
  - Mapper + `gabinete.schemas.spec.ts` + `cadastros-038.test.ts`.
- [x] Origem só com vínculos migra como registro mínimo
  - Caso DEJUR em `documentos-tramitados.mapper.spec.ts`.
- [x] Controle numérico: seis tipos; campos próprios preservados (destino dos memorandos)
  - Seis tipos em `controle-numerico-fields.ts`; `addressee` em memorando; superRefine em `gabinete.schemas.spec.ts`; `cadastros-038.test.ts`.
- [ ] Notificações e autos: valores monetários conferem; agrupamento do mesmo caso
  - **Gap**: `amount` Decimal string (`cadastros.use-case.spec.ts`, `cadastros-038.test.ts`). `groupId` no schema/API; lista **não** agrupa o mesmo caso.
- [x] Diretorias: criar, editar, inativar; setor inativo sai dos destinos de encaminhamento e permanece na administração
  - `GabineteDiretoriasPage.tsx` → `SetoresAdminPanel`; `inactivate-setor.use-case.spec.ts`; destinos `active=true` em `list-setores-paginated.repository.spec.ts`.

**Assinado por**: _________________ **Data**: __________

---

## Diagnóstico (US5)

- [x] Listagem: uma linha por processo; sete campos de busca no servidor
  - Dedup + 7 `buscaPor` (`classificacao-processo.spec.ts`, `list-processos.use-case.spec.ts`, `build-list-query.test.ts`); `DiagnosticoRelatoriosPage.tsx`.
- [x] Categoria e tipo de resultado iguais aos do v1 para os mesmos processos
  - Cascata em `classificacao-processo.spec.ts`. Paridade numérica live (mesmos processos AGEMAN) **não** rodou.
- [x] Painel: totais da base inteira (não da página); filtro ativo fica explícito
  - `dashboard-kpis.test.ts`; `DiagnosticoDashboardPage.tsx`.
- [x] Marcadores persistem no servidor (recarregar / outro navegador)
  - `toggle-marcador.use-case.spec.ts`; `use-diagnostico-marcadores.test.ts` (sem `localStorage`).
- [x] Base externa indisponível: erro explícito, sem lista vazia inventada
  - `list-processos.unavailable.spec.ts`; tela com erro + retry (`DiagnosticoRelatoriosPage.tsx`, dashboard).
- [ ] Marcadores indisponíveis: erro com nova tentativa — nunca “salvo só neste navegador”
  - **Gap**: hook propaga erro e não grava no browser (teste). Listagem **não** mostra `marcadores.error` nem botão de retry dos marcadores.
- [ ] Exportação de painel e seleção (com/sem gráficos; timbre, filtro, data, responsável)
  - **Gap**: API `generate-dashboard-pdf` / `generate-selecao-pdf`. Tela só “Exportar PDF” do painel com `incluirGraficos=true`. Sem exportação de seleção, sem opção sem gráficos, sem teste de timbre/responsável.
- [ ] Documentos institucionais: reservar, rascunho, enviar, cancelar com motivo, PDF, histórico de acessos
  - **Gap**: use-cases na API (`reservar`, `salvar-campos`, `enviar`, `cancelar`, PDF, histórico). Testes só reserva + job de abandono. Tela só lista + “Reservar coletivo/individual”.
- [x] Reserva simultânea gera números distintos; abandonada tem auditoria e número não reutilizado
  - `reservar-numero.use-case.spec.ts`; `abandonar-reservados.job.spec.ts` (auditoria). Sequência transacional não devolve número.
- [ ] Documento enviado não aceita alteração; leitura registra acesso
  - **Gap**: `salvar-campos` / `enviar` / `get-documento` implementam a regra. Sem spec. Sem UI de leitura/edição.
- [ ] Permissão: fora do setor responsável vê só enviados e não reserva número
  - **Gap**: reserva recusada sem membership (`reservar-numero.use-case.spec.ts`). `list-documentos.use-case.ts` filtra `sent` se não for membro — **sem teste**.

**Assinado por**: _________________ **Data**: __________

---

## Portal público (US6)

- [x] Abertura identificada: fluxo guiado; protocolo e chave de consulta
  - `ManifestacaoGuidedForm.tsx` (stepper); `criar-manifestacao-publica.use-case.spec.ts`; e2e `portal-publico.e2e.spec.ts` (não executado).
- [x] Abertura anônima: nenhum dado pessoal solicitado nem armazenado
  - Spec anônima zera nome/documento; UI esconde nome quando anônimo.
- [x] Água: matrícula no formato próprio; iluminação: protocolo e poste
  - `ouvidoria.schemas.spec.ts` + `criar-manifestacao-publica.use-case.spec.ts`; form água em `form-schema.test.ts`.
- [ ] Anexo vinculado aparece no lado interno
  - **Gap**: upload público + bind na API (`upload-publico.use-case.spec.ts`). Portal **não** tem UI de anexo (`anexoTempIds` nunca preenchido).
- [ ] Consulta: protocolo+chave corretos; chave errada responde igual a protocolo inexistente
  - **Gap**: API coberta (`consulta-publica.use-case.spec.ts`). `@ci/publico` **não** tem tela de consulta (só exibe protocolo após envio). E2e consulta via HTTP.
- [x] Proteção contra automação e limite de envios
  - Challenge + rate limit (`criar-manifestacao-publica.use-case.spec.ts`); `@Throttle` no controller. **Ressalva**: form manda `challengeToken: 'ageman-ok'` fixo.
- [ ] Acessibilidade (fonte, daltonismo, leitura por voz) e responsividade em telefone
  - **Gap**: barra em `main.tsx` + `feColorMatrix` em `index.html`. Sem teste. Botão “Daltonismo” só alterna protanopia. Sem evidência de layout em telefone.
- [ ] Aparência do design system v2 (paleta Mint), não do portal antigo
  - **Gap**: tokens Mint em `apps/publico/src/index.css`. Sem teste visual / e2e de paleta.
- [x] Manifestação pública aparece na listagem interna como origem pública
  - Create grava `origem: 'publica'` (spec); lista interna filtra `origem`.

**Assinado por**: _________________ **Data**: __________

---

## Migração / reconciliação (US1)

- [ ] Contagem origem − exclusões = destino para cada entidade (SC-006 / FR-006)
  - **Gap**: `count-report.ts` (`applyExclusions`). Sem spec da fórmula. Dump live **não** rodou (`staging-run.md`).
- [ ] Comparação campo a campo sem divergência não justificada
  - **Gap**: comparador + mapa (`compare-detects-divergence.spec.ts`, `equivalence-map.spec.ts`). Resultado zero-diff contra dump **pendente**.
- [x] Idempotência: segunda execução não altera contagens
  - `load/__tests__/idempotency.spec.ts`; ensaio em memória em `reconciliation/staging-run.md`.
- [ ] Anexos existentes abrem; ausentes listados no relatório
  - **Gap**: `anexo-report.ts` (`classifyAnexos`) sem teste. `migracao:anexos` não executado. Abertura no v2 sem evidência com chaves reais.

**Assinado por**: _________________ **Data**: __________
