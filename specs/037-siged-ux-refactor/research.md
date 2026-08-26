# Research — 037 Refactor UX do SIGED

**Date**: 2026-08-10  
**Spec**: [spec.md](./spec.md)

## R1 — Detecção de diretorias de topo vs. drill-down

**Decision**: Usar a árvore retornada por `GET /siged/departamentos/hierarquia` como fonte canônica. Órgãos de topo = nós do array raiz (`departamentos[]`). Filhos diretos = `node.subordinados`. Drill-down recursivo por profundidade arbitrária.

**Rationale**: A API SIGED já entrega hierarquia aninhada; `orgaoSuperiorId` existe no DTO mas a árvore é mais confiável para UX (evita inferir pai a partir de ID numérico). O util `departamentos-tree.ts` hoje achata tudo via `flattenDepartamentosAtivos` — será substituído por helpers `listTopLevelOrgaos`, `getDirectChildren`, `findNodeWithPath`.

**Alternatives considered**:
- Filtrar por `orgaoSuperiorId === 0` — rejeitado: semântica do campo não documentada no OpenAPI além do tipo numérico; a raiz da árvore já é o contrato estável.
- Sidebar tree permanente (componente `SigedDepartamentoTree`) — rejeitado para MVP: spec pede cards + drill-down; tree pode ser reutilizada dentro do drill-down no futuro.

---

## R2 — Rotas e fluxo de navegação (client)

**Decision**:

| Rota | Página | Papel |
| --- | --- | --- |
| `/siged` | `SigedHomePage` | Home com post-its (nova) |
| `/siged/diretorias` | `SigedDiretoriasPage` | Cards só de topo |
| `/siged/diretorias/:orgaoId` | `SigedOrgaoDrilldownPage` | Filhos diretos + CTA "Ver protocolos desta diretoria" |
| `/siged/diretorias/:orgaoId/protocolos` | `SigedProtocolosPage` | Existente (mantida) |
| `/siged/diretorias/:orgaoId/protocolos/:protocoloId` | detalhe | Existente |
| `/siged/auditoria` | `SigedAuditoriaPage` | Jatobá dedicada |
| `/siged/insights` | `SigedInsightsPage` | Cedro dedicada |

Leaf org (sem `subordinados`): clique no card navega direto para `/protocolos` (FR-008).

**Rationale**: Separa Home de diretorias sem quebrar URLs de protocolo já bookmarkadas. Breadcrumb deriva de `findDepartamentoWithAncestors`.

**Alternatives considered**:
- Home substituindo diretorias na mesma rota — rejeitado (decisão do usuário na elicitação).

---

## R3 — Histórico local para tendências (FR-028)

**Decision**: Persistir snapshots leves em PostgreSQL, coletados de forma **passiva** nos use-cases de leitura existentes + job diário de consolidação.

| Entidade | Granularidade | Quando grava |
| --- | --- | --- |
| `SigedOrgaoDailyMetric` | 1 linha/tenant/órgão/dia | Após listagem de protocolos por órgão; job diário |
| `SigedProtocoloObservacao` | último estado conhecido/protocolo | Após consulta de tramitações ou listagem que inclua protocolo |

Campos agregados por órgão/dia: `protocolCount`, `avgDaysInOrgao`, `stalledCount`, `tramitacaoCount`.  
Retenção: **90 dias** (suficiente para médias de 30 dias + margem; detalhado em tasks).

Indicador de origem nos DTOs de fiscalização/insights: `dataSource: 'live' | 'historical' | 'mixed'`.

**Rationale**: Consulta SIGED permanece ao vivo para detalhe operacional; histórico local alimenta Home, Cedro e Jatobá sem duplicar tramitações completas. Coleta passiva evita crawler agressivo à API municipal.

**Alternatives considered**:
- Persistir cada tramitação integral — rejeitado: volume alto, dados sensíveis, redundante com cache TTL curto.
- Só cache Redis — rejeitado: não permite tendência multi-dia nem sobrevive a restart.
- Insights só com instantâneo — rejeitado: viola FR-028 e decisão do usuário.

---

## R4 — Fiscalização SIGED (Jatobá) — escopo e regras v1

**Decision**: Novo submódulo `siged-fiscalizacao` espelhando `gabinete-fiscalizacao` (Run → Result → Check → Finding), com entidade fiscalizada `siged_protocolo` (IDs numéricos SIGED).

Regras iniciais (determinísticas, sem LLM):

| ruleId | Checagem | Não conforme quando |
| --- | --- | --- |
| `JAT-SIG-TRM-001` | Prazo de tramitação entre órgãos | Última movimentação > **2 dias úteis** sem recebimento no destino (meta Protocolo — regras-plataforma §7.5) |
| `JAT-SIG-TRM-002` | Tempo parado no órgão | Protocolo no mesmo órgão > **5 dias corridos** sem nova movimentação |
| `JAT-SIG-TRM-003` | Movimentação registrada | Zero tramitações conhecidas → **Pendente** (nunca omitir) |

Questionários: reutilizar stack de perguntas/respostas com `allowExternalAudience: false` (FR-015). Banco de perguntas dedicado `SigedFiscalizacaoQuestion*`.

**Rationale**: Paridade com Gabinete/Ouvidoria; regras alinhadas a §7 regras-plataforma; IDs SIGED são a chave natural do domínio.

**Alternatives considered**:
- Reutilizar `GabineteFiscalizacaoRun` com FK opcional — rejeitado: mistura entidades internas e externas; trace/evidence ficam confusos.

---

## R5 — Insights SIGED (Cedro) — escopo e regras v1

**Decision**: Novo submódulo `siged-insights` espelhando `gabinete-insights` (Batch → Insight → Evidence), agregação determinística sobre snapshots + amostra live recente.

Regras iniciais:

| slug | Tema | Impacto típico |
| --- | --- | --- |
| `siged_volume_by_orgao` | Diretoria com maior volume de protocolos | Alto |
| `siged_avg_tramitacao_days` | Maior tempo médio entre movimentações | Alto/Crítico |
| `siged_stalled_orgaos` | Órgãos com maior concentração de protocolos parados | Crítico |
| `siged_orgao_comparison` | Comparativo top-3 diretorias por volume ou tempo | Médio |

Geração: sob demanda (*Consultar IA*) + throttle 1h (padrão Gabinete). Job diário opcional pós-MVP.

Evidências referenciam `sigedProtocoloId`, `numero`, `sigedOrgaoId`, `orgaoSigla`.

**Rationale**: Cedro read-only; regras explicáveis; reutiliza componentes shared `@/modules/shared/components/cedro`.

---

## R6 — Home post-its (composição)

**Decision**: Grid responsivo de cartões estilo post-it (rotação sutil, cores Mint) com blocos fixos:

1. **Operacionais (Base)**: total diretorias de topo; protocolos monitorados (snapshots); última coleta.
2. **Jatobá** (se run existir): contagem Não conforme / Pendente — link `/siged/auditoria`.
3. **Cedro**: até 3 insights de maior impacto — link `/siged/insights`; card vazio se `never_generated`.
4. **Degradação SIGED**: banner compacto se live indisponível (FR-005).

Sem CRUD de notas manuais.

**Rationale**: Atende FR-001..005; post-its são projeção de KPIs/insights, não entidade persistida.

---

## R7 — Alertas de licença e shell

**Decision**: Reutilizar `ListLicenseAlertBar` + helper `buildSigedLicenseAlerts()` alimentado por endpoints leves `GET /siged/fiscalizacao/alerts-summary` e `GET /siged/insights/alerts-summary` (ou agregador único `GET /siged/home`).

Exibir barra em: Home, Diretorias, Drill-down, Protocolos — **não** na tabela de protocolos (FR-024).

Navegação SIGED ganha itens: Início, Diretorias, Fiscalização, Insights IA — `module: gabinete`, licenças conforme tela.

**Rationale**: Paridade regras-plataforma §4 e §1.9; SIGED permanece agrupamento nav separado mas módulo `gabinete` para permissão.

---

## R8 — Controle Interno existente

**Decision**: Sem alteração de schema/comportamento. Permanece em detalhe do protocolo (`SigedControleInternoForm`), licença Base, statuses `PENDENTE|EM_ANALISE|REVISADO|ARQUIVADO` — distintos de `ConformityStatus` Jatobá.

**Rationale**: Decisão explícita do usuário na elicitação.

---

## R9 — Testes e performance

**Decision**:
- API: Jest unitário em regras de checks/aggregation; contract specs com fixtures JSON; use-cases mockando Prisma + SIGED client.
- Client: Vitest em `departamentos-tree`, mappers, rotas; RTL em Home e drill-down; MSW para novos endpoints.
- Coleta snapshot: fire-and-forget — falha de persistência **não** falha a resposta ao usuário (log Pino).

Meta: Home GET agregado < 500ms p95 com snapshots; fiscalização run amostra até 500 protocolos por execução v1 (paginar amostra por órgão prioritário).

**Alternatives considered**:
- Fiscalizar todos os protocolos de todos os órgãos em um run — rejeitado v1: risco de timeout/upstream rate limit.
