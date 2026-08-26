# Quickstart — 037 Refactor UX do SIGED

Validação manual end-to-end após implementação. Detalhes de modelo e API: [data-model.md](./data-model.md), [contracts/](./contracts/).

## Pré-requisitos

- PostgreSQL com migrations 037 aplicadas
- `TenantSigedConfig.active = true` para tenant de dev (credenciais SIGED)
- Usuário com módulo **Gabinete** e licenças **Jatobá** + **Cedro**
- API e client rodando:

```powershell
cd ci-api-v2; npm run start:dev
cd ci-client-v2; npm run dev
```

---

## 1. US1 — Diretorias agrupadas (P1)

1. Abra `/siged/diretorias`
2. **Esperado**: cards apenas de diretorias de topo (sem departamentos subordinados misturados)
3. Clique em diretoria com subordinados
4. **Esperado**: tela de drill-down com filhos diretos + breadcrumb
5. Se houver sub-departamentos, repita drill-down
6. Em órgão folha, **esperado**: lista de protocolos com filtros/paginação/exportação funcionando
7. Diretoria com protocolos próprios: **Esperado**: botão **Ver protocolos desta diretoria**

**Automatizado**: `npm test -- departamentos-tree` em `apps/web`

---

## 2. US2 — Home post-its (P2)

1. Abra `/siged`
2. **Esperado**: Home antes das diretorias; grid de post-its (KPIs + resumo Cedro se existir)
3. Clique **Ver diretorias** → `/siged/diretorias`
4. Sem insights gerados: post-it orientando **Consultar IA** em Insights
5. (Opcional) Desative SIGED upstream: Home ainda mostra histórico local + aviso live

**API**:

```powershell
curl -H "Authorization: Bearer $TOKEN" -H "X-Tenant-ID: $TENANT" http://localhost:3000/siged/home
```

---

## 3. US3 — Fiscalização Jatobá (P3)

1. Navegue `/siged/auditoria`
2. **Esperado**: badge **Somente leitura**; painel vazio com CTA fiscalizar ou run anterior
3. Clique **Fiscalizar protocolos** (label final conforme copy)
4. **Esperado**: achados com conformidade canônica; nenhum dado SIGED alterado
5. Abra trace de achado → sheet **Por que esta checagem deu este resultado**
6. Com achado crítico: volte à Home — **Esperado**: barra **Alertas ativos nas licenças**

**Automatizado**:

```powershell
cd ci-api-v2; npm test -- --testPathPatterns=siged-fiscalizacao
```

---

## 4. US4 — Insights Cedro (P4)

1. Navegue `/siged/insights`
2. **Consultar IA** → confirmar dialog
3. **Esperado**: insights com impacto; badge **Somente leitura**
4. Trace → **De onde veio este insight** com evidências (protocolo/diretoria)
5. Post-it na Home linka para insight completo

**Automatizado**:

```powershell
cd ci-api-v2; npm test -- --testPathPatterns=siged-insights
cd ci-client-v2/apps/web; npm test -- SigedInsights
```

---

## 5. Regressão Controle Interno (Base)

1. Abra protocolo em `/siged/diretorias/:orgaoId/protocolos/:id`
2. Edite **Controle Interno** (status/nota/tags) → salvar
3. **Esperado**: persiste; independente de conformidade Jatobá

---

## 6. Critérios de aceite (spec)

| ID | Verificação rápida |
| --- | --- |
| SC-001 | Home → protocolo qualquer ≤ 4 cliques |
| SC-003 | Fiscalização só status canônicos |
| SC-004 | Insights read-only |
| SC-005 | Alertas visíveis em <5s na Home |
| SC-007 | Home utilizável com SIGED offline (histórico) |

---

## Troubleshooting

| Sintoma | Ação |
| --- | --- |
| Hierarquia vazia | Verificar `TenantSigedConfig.active` e credenciais |
| Insights "dados insuficientes" | Navegar protocolos/tramitações para popular snapshots; aguardar job diário |
| 403 Fiscalização/Insights | Confirmar licenças tenant + papel usuário |
| Grade ainda achatada | Confirmar deploy US1 (`listTopLevelOrgaos` na página diretorias) |
