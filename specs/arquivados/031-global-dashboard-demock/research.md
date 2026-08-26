# Research: Desmock do Dashboard Global

**Feature**: 031-global-dashboard-demock  
**Date**: 2026-07-02

## R1 — Estratégia de agregação: endpoint único vs. múltiplas chamadas client

**Decision**: Criar módulo API `global-dashboard` com `GET /global/dashboard` (BFF tenant-scoped).

**Rationale**:
- Home exige KPIs + feed + gráfico com filtros de permissão consistentes.
- Repositórios de tramitação, ouvidoria e notificação já existem; agregação server-side evita 3–4 round-trips e vazamento de totais cross-módulo.
- Padrão alinhado a `GET /tramitacao/dashboard` (já produção).

**Alternatives considered**:
- Client chama `/tramitacao/dashboard` + `/notificacoes` em paralelo — rejeitado: ouvidoria KPIs exigiriam terceira rota; permissões heterogêneas difíceis de compor no client.
- Reutilizar apenas `screens.ts` stats com fetch opcional — rejeitado: não resolve feed/gráfico nem SC-003.

---

## R2 — Mapeamento dos 4 KPIs originais

**Decision**: Substituir KPIs estáticos por contrato explícito com campo `source: 'real' | 'mock'`:

| KPI (rótulo UI) | Fonte | `source` |
| --- | --- | --- |
| **Ocorrências prioritárias** | Manifestações ouvidoria `priority ∈ {high, urgent}` + status operacional (`in_review`, `forwarding`) + demandas tramitação pendentes com `deadline < now` | `real` |
| **Demandas pendentes** | `TramitacaoDemanda` pendentes (status `open`/`in_progress`, excl. personal ativo) — janela 30 dias | `real` |
| **Atualizações (24h)** | Contagem `TramitacaoDemandaEvento.createdAt >= now-24h` no tenant | `real` |
| **Registros ativos (transversal)** | Sem definição canônica cross-módulo no produto | `mock` (rotulado) |

**Rationale**: 3/4 KPIs com fonte real atende SC-003 (≥50%). "Registros ativos" permanece mock honesto até spec futura de inventário transversal.

**Alternatives considered**:
- Manter rótulos literais originais ("4.218 registros") — rejeitado: induz falsa operação.
- KPI "Módulos monitorados" — rejeitado como KPI numérico: melhor como metadado client-side (contagem de módulos acessíveis) sem número fictício.

---

## R3 — Definição de "ocorrências críticas" no gráfico

**Decision**: Renomear gráfico para **"Demandas linked por módulo de origem"** usando `bySourceModule` do repositório de dashboard de tramitação (janela 30 dias). Dados reais; sem rótulo Mock.

**Rationale**: `GetDashboardRepository` já agrega `sourceModule` para demandas linked. Não existe entidade transversal "ocorrência crítica" com mesmo critério em patrimônio/contratos/compras. Renomear é mais honesto que manter título enganoso.

**Alternatives considered**:
- Manter título "Ocorrências críticas" com barras mock — rejeitado pela spec (US4).
- Agregar por módulo somando manifestações urgentes + demandas — adiado: complexidade alta; pode ser extensão futura.

---

## R4 — Feed "Atividade recente"

**Decision**: Compor feed a partir de:
1. **Primário**: últimos 8 eventos `TramitacaoDemandaEvento` (tenant), mapeados para título + módulo + `navigationPath` (`/tramitacao/demandas/:id`).
2. **Complementar** (se implementado): mesclar até 4 notificações recentes do usuário autenticado (`ListNotificacoesUseCase`), deduplicando por `sourceRecordId`.
3. Ordenar por `createdAt` DESC; limitar 10 itens.

**Rationale**: Eventos de tramitação existem no schema com índice `(demandaId, createdAt)`. Notificações (spec 029) já têm API e `navigationPath` — complemento natural sem mock.

**Alternatives considered**:
- Apenas notificações — rejeitado: depende de usuário ser destinatário; eventos tenant-wide enriquecem visão gestor.
- Mock `welcomeActivities` com fetch parcial — rejeitado.

---

## R5 — Perfil do operador na home

**Decision**: Remover `loadProfile()` de `GlobalWelcomeDashboard`; usar exclusivamente `useAuth().user` (origem `/auth/me`).

**Rationale**: `loadProfile()` faz fallback para `admin-mock`/`sessionStorage` — viola FR-001. AuthContext já hidrata via API em `VITE_USE_API !== 'false'`.

**Alternatives considered**:
- Manter `loadProfile` para avatar editado localmente — rejeitado: avatar oficial vem de `/auth/me` + presign; perfil admin usa rota dedicada.

---

## R6 — Indicador visual Mock

**Decision**: Componente `MockDataBadge` em `modules/shared/components/` — Badge shadcn variant `outline`, texto **Mock**, `title` tooltip "Dados de demonstração — não refletem operação real".

**Rationale**: Não existe componente prévio; padrão único reutilizável. Paleta mint: borda muted, texto `text-muted-foreground`, sem confundir com alertas de licença.

**Alternatives considered**:
- Banner global "modo demo" — rejeitado: spec exige granularidade por bloco.
- Ícone apenas — rejeitado: SC-005 exige identificação clara.

---

## R7 — Permissões e filtro de licença

**Decision**:
- API: JWT + tenant scope (Prisma extensions). Sub-agregações ouvidoria omitidas se actor não tem módulo `ouvidoria` (via `ModuloPermissao` / setores — checar no use case).
- Client: filtro de licença aplicado **após** fetch nos KPIs/gráfico que listam módulos (filtrar barras por módulos visíveis no filtro). Hero/atalhos/branding inalterados.

**Rationale**: FR-010. Global é `OPEN_MODULES`; tramitação idem; ouvidoria requer permissão explícita.

**Alternatives considered**:
- Ignorar filtro de licença na home — rejeitado: inconsistente com resto da shell.

---

## R8 — Estrutura de pastas client

**Decision**: Novo domínio `apps/web/src/modules/global/` (espelho API) com `api/`, `hooks/`, `lib/*-mappers.ts`. Componente `GlobalWelcomeDashboard` permanece referenciado de `shell/pages/ScreenPage.tsx` mas importa dados de `@/modules/global`.

**Rationale**: Constitution V — colocation por domínio; componente shell continua composition root.

**Alternatives considered**:
- Tudo em `shell/components/mock/` — rejeitado: pasta `mock` contradiz objetivo; mover para `global/components/` na implementação.
