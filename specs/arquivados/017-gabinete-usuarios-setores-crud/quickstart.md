# Quickstart: Gestão Institucional — Usuários e Setores

**Feature**: 017-gabinete-usuarios-setores-crud · **Date**: 2026-06-25

Validação end-to-end pós-implementação. Detalhes de contrato: [rest-api](./contracts/rest-api-gestao-institucional.md) · [client-ui](./contracts/client-gestao-institucional-ui.md) · [data-model](./data-model.md)

## Prerequisites

- PostgreSQL rodando
- Seed tenant Jacaranda: `cd ci-api-v2; npm run prisma:seed`
- API: `cd ci-api-v2; npm run start:dev`
- Client: `cd ci-client-v2; npm run dev`

### Credenciais demo (Jacaranda)

| Persona | Uso |
|---------|-----|
| Maria Oliveira (GAB / admin) | Gestor Gabinete |
| Servidor sem GAB | Teste 403 |

Consultar [seed-jacaranda-tenant.ts](../../../ci-api-v2/prisma/seed/seed-jacaranda-tenant.ts) para e-mails/senhas atuais.

---

## 1. Navegação Gabinete

1. Login como membro GAB
2. Sidebar → **Administração** → **Gabinete** → **Gestão institucional**
3. Abrir **Usuários** (`/gabinete/usuarios`)

**Esperado**:

- Breadcrumb: Início → Gabinete → Usuários
- 4 KPI cards (Total, Ativos, Inativos, Chefias) — **sem** badges de licença
- Botão **Novo usuário** (teal/mint)
- Filtros status + busca
- Tabela com paginação (*1–20 de N* se N > 20)

Repetir para **Setores** (`/gabinete/setores`).

---

## 2. CRUD usuário (Gabinete)

1. **Novo usuário** → e-mail único, nome, senha, setor GAB, perfil Servidor → salvar
2. Usuário aparece na listagem **Ativo**
3. **Editar** → alterar nome → salvar → listagem atualizada em < 2s
4. **Resetar senha** → nova senha → logout do alvo → login com nova senha ✅
5. **Inativar** → status Inativo → login do alvo ❌ mensagem clara
6. Filtro **Inativos** → usuário visível → **Restaurar** → Ativo → login ✅

---

## 3. CRUD setor (Gabinete)

1. **Novo setor** → sigla única, nome → salvar
2. **Inativar** → some da lista Ativos
3. **Restaurar** via filtro Inativos
4. Tentar sigla duplicada → erro claro

---

## 4. Paridade Plataforma

1. Login `admin_plataforma` ou `admin_tenant`
2. **Administração → Plataforma → Usuários**
3. Verificar **mesmas** colunas, filtros, KPI, paginação que `/gabinete/usuarios`
4. Alteração feita aqui reflete na rota Gabinete

---

## 5. Controle de acesso (403)

1. Login servidor **sem** setor GAB
2. Navegar manualmente para `/gabinete/usuarios`
3. **Esperado**: 403 · Acesso negado (copy padronizada)

---

## 6. Licença filter

1. Ativar filtro global ocultando Cedro (ou outra licença)
2. Usuários/Setores Gabinete e Plataforma **permanecem acessíveis**

---

## 7. Testes automatizados

```powershell
cd ci-api-v2
npm test -- --testPathPattern="setor|institutional"

cd ci-client-v2
npm test -- --filter=@ci/web -- institutional
```

Todos verdes antes de merge.

---

## 8. Checklist SC (spec)

| ID | Verificação |
|----|-------------|
| SC-001 | Cronometrar cadastro novo usuário < 3 min |
| SC-002 | CRUD reflete listagem < 2s |
| SC-003 | Inativo não loga |
| SC-004 | Restaurado loga na 1ª tentativa |
| SC-005 | Zero badges licença premium nas 4 telas |
| SC-006 | Diff visual Gabinete vs Plataforma = zero em colunas/ações |

---

## Troubleshooting

| Sintoma | Causa provável |
|---------|----------------|
| 403 para Maria | JWT sem setor GAB ou módulo não vinculado — re-seed |
| Lista vazia com API | `VITE_USE_API=false` — setar true |
| Paginação ausente | total ≤ limit — adicionar usuários seed |
| Login após inativar funciona | soft delete não aplicado — verificar DELETE use-case |
