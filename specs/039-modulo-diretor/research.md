# Research — 039 Módulo Diretor

**Date**: 2026-08-25  
**Spec**: [spec.md](./spec.md)

## R1 — Autorização (papel + e-mail + tenant AGEMAN)

**Decision**: `DiretorAccessGuard` local no `DiretorModule` (`@UseGuards` no controller). **Não** registrar como `APP_GUARD`. **Não** usar só `@Roles()` (hierarquia `hasMinimumRole` não expressa o OU com e-mail).

Libera quando **todas** as condições abaixo:

1. Tenant resolvido (`getRequestContext().tenantId` após `TenantGuard`) é AGEMAN — UUID `00000000-0000-0000-0000-000000000002` **ou** slug `ageman` (comparar contra o `tenant.id` já resolvido).
2. `role ∈ { admin_tenant, admin_saas, admin_plataforma }` **OU** e-mail do actor (lookup) === `ebenezer.bezerra@ageman.am.gov.br` (case-insensitive, trim).

E-mail **não** está no JWT (`JwtPayload` = `sub`, `tenantId`, `role`, setores). Lookup:

| Role | Tabela |
| --- | --- |
| `user` / `chefe_setor` / `admin_plataforma` | `User.email` |
| `admin_tenant` | `AdminTenant.email` |
| `admin_saas` | `AdminPlataforma.email` |

Constante única: `DIRETOR_ALLOWED_EMAIL` em `diretor.constants.ts`. Falha → `ForbiddenException` sem calcular KPI.

**Rationale**: Padrão `InstitutionalAdminGuard`. Barreira real na API; client só esconde nav. Lookup de e-mail é o único jeito de honrar FR-001.

**Alternatives considered**:

- `UserTelaOverride` — rejeitado pelo usuário.
- Novo `UserRole.diretor` — rejeitado (migration + hierarquia).
- Confiar no e-mail do JWT — impossível (campo inexistente).
- `@Roles(admin_tenant)` sozinho — `admin_saas` passaria por rank, mas o e-mail nominado com role `user` não; e não checa AGEMAN.

---

## R2 — `admin_saas` no `apps/web` (achado da spec)

**Decision**: A API **aceita** `admin_saas` quando o `X-Tenant-ID` resolve para AGEMAN. `TenantGuard` usa o header, não o `tenantId` do JWT (`platform`). Não há tela em `apps/admin-saas` (FR-014).

**Gap de produto documentado**: `/auth/login` do tenant **não** autentica `AdminPlataforma`. Login SaaS é `POST /admin/auth/login` + `apps/admin-saas` + JWT `tenantId: 'platform'`. Nesta entrega **não** há impersonation nem login SaaS no `apps/web`. Na prática o superadmin só consome `/diretor/*` via API (token SaaS + header AGEMAN) ou via fluxo futuro de sessão tenant. Ebenezer (`admin_plataforma` no tenant AGEMAN) e `admin_tenant` no `apps/web` cobrem o uso real.

**Rationale**: Honra FR-001/FR-014 sem inventar impersonation. Spec já previa este achado.

**Alternatives considered**:

- Duplicar a tela em `admin-saas` — rejeitado (FR-014).
- Bloquear `admin_saas` na API — viola FR-001.
- Ensinar `AuthService.login` a aceitar `AdminPlataforma` — fora de escopo (muda auth global).

---

## R3 — Rotas, catálogo e nav

**Decision**:

| Camada | Valor |
| --- | --- |
| `screenId` | `diretor-dashboard` |
| Path | `/diretor` |
| Título | `Visão do Diretor` |
| `SCREEN_CATALOG.moduloSlug` | `global` (não criar `ModuloSlug.diretor`) |
| Client `screens.ts` | `module: 'global'`, `type: 'dashboard'`, `licenses: ['base']` |
| Nav | Grupo `Diretoria` com `outsideModules: true`, um item; visível só se `canAccessDiretor(user) && isAgemanTenant()` |
| Router | `DIRETOR_OVERRIDES['diretor-dashboard']` → lazy `DiretorPage` |

`ADMIN_BYPASS_ROLES` já devolve todas as telas do catálogo a `admin_plataforma` / `admin_tenant` / `admin_saas` em **qualquer** tenant. Por isso o filtro de nav **e** o guard de tenant são obrigatórios — sem eles Jacaranda veria o item e tomaria 403.

**Rationale**: Reusa pipeline de telas; evita `ModuloSetor` e `ModuloPermissaoGuard` (bypass de admin). Página real, não mock `ScreenPage`.

**Alternatives considered**:

- `ModuloSlug.diretor` + `@RequireModulo` — rejeitado: seed de vínculos, enum Prisma, e bypass de admin anularia o guard de módulo.
- `moduloSlug: 'administracao'` + `scope: 'platform'` — rejeitado: mistura com telas de cadastro institucional.

---

## R4 — Endpoints dedicados vs. reuso direto

**Decision**: Endpoints **novos** sob `/diretor/*` (todos GET). O frontend **não** chama `/ouvidoria/dashboard` nem `/diagnostico/dashboard` nesta tela — o guard + cache + presets 7/3 dias ficam num único prefixo.

| Endpoint | Fonte | Período |
| --- | --- | --- |
| `GET /diretor/ouvidoria/kpis` | Mesmos 6 KPIs de `GetDashboardAgregacoes` | `year`+`month` **ou** `presetDays` (3\|7) |
| `GET /diretor/ouvidoria/acoes` | `ManifestacaoEvento` (repo de `list-auditoria`) | mesmo recorte do bloco + `autorUserId?` |
| `GET /diretor/diagnostico/kpis` | Estoque = dashboard atual (sem data); locais = counts PG | preset/calendário só em `locais` |
| `GET /diretor/diagnostico/acoes` | `DiagnosticoProcessoMarcador` (+ auditoria de documento se trivial) | recorte local + `autorUserId?` |
| `GET /diretor/audit-logs` | `AuditLog` | **somente** `year`+`month` (não herda preset) |
| `GET /diretor/atores` | Distinct de autores com ação no período do `modulo` | alimenta o select de pessoa |

Presets substituem calendário **no query do bloco**. Query Zod: `year`/`month` opcionais + `presetDays` opcional; `superRefine` — se `presetDays` presente, ignora calendário (servidor resolve `from`/`to`).

Dashboard atual de Ouvidoria **não** aceita janela de 7/3 dias — o use-case diretor resolve o intervalo e agrega `createdAt` (e os mesmos status) nesse recorte. Fórmulas dos 6 KPIs **não mudam**.

Dashboard de Diagnóstico **não** tem data — o bloco devolve `estoque` intacto + `locais` recortáveis + flag `estoqueIgnoraPeriodo: true`.

**Rationale**: FR-006 (reusar indicadores) + FR-007 (preset por bloco) + FR-012 (cache no prefixo) + um único guard.

**Alternatives considered**:

- Client chama 3 endpoints existentes em paralelo — rejeitado: Ouvidoria não tem 7/3 dias; Diagnóstico não tem KPIs locais; `AuditLog` não tem GET; cache/guard espalhados.
- Um único `GET /diretor/dashboard` monolítico — rejeitado: FR-011 (blocos independentes); falha do MySQL derrubaria a tela.

---

## R5 — Cache sem Redis

**Decision**: `DiretorCacheService` no módulo (cópia do contrato de `SigedCacheService`: `buildKey`, `get`, `set`, TTL). **Não** importar o service do SIGED (acoplamento).

| Recurso | TTL |
| --- | --- |
| KPIs | 90s |
| Listas / atores | 30s |

Chave: `tenantId + path + params canônicos`. Miss → use-case; hit → return. Query `fresh=1` (opcional) ignora cache (botão atualizar). Process restart esvazia o Map — aceitável (FR-012).

Client: React Query com `staleTime` alinhado (90s KPIs, 30s listas), queries **separadas** por bloco. Chunking: bloco de auditoria em `lazy()` / render diferido após os KPIs.

**Rationale**: Padrão já em produção; atende SC-001 sem Redis.

**Alternatives considered**:

- `cache-manager` + memory store — rejeitado: dependência nova, constitution privilegia o que já existe.
- Redis — rejeitado pelo usuário.
- Só React Query — rejeitado: SC-001 também pede cache no servidor (agregações pesadas).

---

## R6 — Auditoria geral (`AuditLog`)

**Decision**: Primeiro GET de leitura sobre `AuditLog`. Filtros: `year`, `month`, `page`, `limit` (1–50, default 20), opcional `action` (método HTTP), `q` (busca em `entity`). Response inclui `actor` resolvido:

- Se `userId` → `{ id, name, email }` de `User`
- Senão `payload.actorId` / `payload.actorRole` (admin_tenant / admin_saas)

Migration: `@@index([tenantId, createdAt])`. **Não** backfill de `entityId` (interceptor hoje não preenche — fora de escopo).

**Rationale**: FR-009 + SC-005. Índice evita seq scan no mês.

**Alternatives considered**:

- Expor `GET /audit-logs` global sem guard diretor — rejeitado: dado sensível; fica atrás do mesmo guard.
- Usar só `GET /ouvidoria/auditoria` — rejeitado: é domínio, não plataforma.

---

## R7 — Diagnóstico: estoque vs. locais

**Decision**: Response de `GET /diretor/diagnostico/kpis` tem duas seções:

```text
estoque          → total, sentencas, peticoesIniciais, procedencias (mappers atuais)
locais           → marcadoresNoPeriodo, documentosNoPeriodo
estoqueIgnoraPeriodo: true
```

Falha do MySQL externo: HTTP 200 com `estoque: null` + `estoqueErro: true`; `locais` ainda preenchidos. Client mostra aviso só no sub-bloco de estoque.

Ações: `DiagnosticoProcessoMarcador` (`userId`, `createdAt`, `numeroProcesso`). Documentos institucionais entram nos KPIs locais (`reservadoEm`/`createdAt`); lista de ações v1 = marcadores (volume menor, autor claro).

**Rationale**: FR-013 sem inventar histórico na base externa.

**Alternatives considered**:

- Filtrar MySQL por algum campo de data — rejeitado pelo usuário (só PG local).
- Omitir estoque na tela diretor — rejeitado: FR-006 pede reuso dos KPIs existentes.

---

## R8 — UI e copy

**Decision**: Paleta Mint; cards KPI no ritmo dos dashboards atuais (6 Ouvidoria, 4+2 Diagnóstico); `YearMonthFilters` extraído/reusado; presets como toggle por bloco (um ativo); select de pessoa com busca; listas compactas paginadas; badge **Somente leitura** no header. Sem gráficos Nivo nesta entrega (cards bastam). Sem ações de escrita.

React Query + Suspense por bloco (SC-003: outros blocos não somem). Empty states explícitos.

**Rationale**: Skills `ui-ux-pro-max` + `vite-react-best-practices` (route split, server state, colocation).

**Alternatives considered**:

- Copiar página de Ouvidoria inteira — rejeitado: presets e auditoria não cabem.
- `useEffect` como Ouvidoria — rejeitado: cache/chunking pedem React Query (já no app via SIGED).
