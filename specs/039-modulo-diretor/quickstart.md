# Quickstart — 039 Módulo Diretor

Validação manual end-to-end. Contratos: [contracts/](./contracts/). Modelo: [data-model.md](./data-model.md).

## Pré-requisitos

- PostgreSQL com a migration do índice `AuditLog(tenantId, createdAt)`
- Tenant AGEMAN ativo (`slug=ageman` ou UUID canônico)
- Usuário `ebenezer.bezerra@ageman.am.gov.br` **ou** `admin_tenant` / `admin_plataforma` nesse tenant
- `VITE_TENANT_ID=ageman` no `apps/web`
- API e client:

```powershell
cd ci-api-v2; npm run start:dev
cd ci-client-v2; npm run dev
```

## Testes automatizados

```powershell
cd ci-api-v2; npm test -- --testPathPatterns=diretor
cd ci-client-v2/apps/web; npm test -- diretor
```

## 1. US1 — Panorama do mês corrente (P1)

1. Login autorizado no tenant AGEMAN → abrir `/diretor`
2. **Esperado**: filtro ano/mês = atuais; 6 cards Ouvidoria; 4 cards de estoque + 2 locais Diagnóstico; badge Somente leitura
3. Login operador (`user`) → `/diretor` → **Esperado**: acesso negado, zero cards
4. Mesmo usuário autorizado com `VITE_TENANT_ID` de outro tenant → item de nav ausente; API 403

```powershell
curl -H "Authorization: Bearer $TOKEN" -H "X-Tenant-ID: ageman" http://localhost:3000/diretor/ouvidoria/kpis
```

## 2. US2 — Troca de ano/mês (P2)

1. Selecionar mês anterior
2. **Esperado**: blocos calendário atualizam; bloco em loading isolado; auditoria acompanha o mês
3. Recarregar a página → volta ao mês atual

## 3. US3 — Presets 7 / 3 dias (P2)

1. Em Ouvidoria, acionar **Últimos 7 dias**
2. **Esperado**: só aquele bloco muda; Diagnóstico e auditoria permanecem no mês
3. Acionar **Últimos 3 dias** no mesmo bloco → substitui o 7
4. Desligar o preset → volta ao calendário
5. Diagnóstico com preset: estoque **não** muda; badge “não recorta por data”; KPIs locais mudam

## 4. US4 — Ações por pessoa (P3)

1. Abrir o select de pessoa (Ouvidoria) → lista vinda de `GET /diretor/atores?modulo=ouvidoria`
2. Escolher alguém com eventos → lista só dessa pessoa
3. Pessoa sem eventos → empty state
4. Diagnóstico: filtro aplica-se aos marcadores locais

## 5. US5 — Auditoria geral (P3)

1. Rolar até o bloco de auditoria (carrega depois dos KPIs)
2. **Esperado**: página 1; avançar página não trava a tela
3. Preset ativo em Ouvidoria **não** altera esta lista
4. Sem controles de escrita

## Degradação Diagnóstico

Com MySQL externo indisponível: tela sobe; aviso só no estoque; `locais` e Ouvidoria ok.

## Cache

1. Abrir a tela (miss)
2. Recarregar em < 90s → resposta rápida (hit)
3. **Atualizar** → busca de novo (`fresh`)
