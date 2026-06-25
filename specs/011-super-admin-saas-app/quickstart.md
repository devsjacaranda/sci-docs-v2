# Quickstart: Super Admin SaaS App

**Feature**: 011-super-admin-saas-app  
**References**: [plan.md](./plan.md) · [contracts/rest-api-admin-plataforma.md](./contracts/rest-api-admin-plataforma.md) · [contracts/client-admin-saas-ui.md](./contracts/client-admin-saas-ui.md)

Guia de validação pós-implementação. Comandos assumem repo root `ci-v2/`.

---

## Pré-requisitos

- Node.js 20 LTS
- PostgreSQL rodando
- Seed aplicado (`saas@ci.com` / `password123`, tenant `demo`)

```powershell
cd ci-api-v2
npm install
npm run prisma:migrate
npm run prisma:seed
```

---

## Subir ambiente dev

**Terminal 1 — API**:

```powershell
cd ci-api-v2
npm run start:dev
```

**Terminal 2 — Admin SaaS app**:

```powershell
cd ci-client-v2
npm install
npm run dev:admin
```

**Terminal 3 (opcional) — App tenant** (validar isolamento):

```powershell
cd ci-client-v2
npm run dev
```

| Serviço | URL |
|---------|-----|
| API | `http://localhost:3000` |
| Admin SaaS | `http://localhost:5174` |
| Tenant app | `http://localhost:5173` |

---

## Validação manual — P1 Login e shell

1. Abrir `http://localhost:5174/login`
2. Confirmar: **sem** campo tenant
3. Login `saas@ci.com` / `password123`
4. **Expected**: redirect `/` com sidebar Admins + Tenants
5. Logout → tentar `/tenants` → redirect `/login`

---

## Validação manual — P2 Super admins

1. `/admins` — lista inclui `saas@ci.com`
2. Criar admin `ops@test.com`
3. Editar → desativar (não deve permitir se único ativo)
4. Reset senha com dialog confirmação
5. `/profile` — alterar própria senha

**API curl (opcional)**:

```powershell
# Login
$login = Invoke-RestMethod -Method POST -Uri http://localhost:3000/admin/auth/login `
  -ContentType application/json -Body '{"email":"saas@ci.com","password":"password123"}'
$headers = @{ Authorization = "Bearer $($login.accessToken)" }

# List admins
Invoke-RestMethod -Uri http://localhost:3000/admin/admins -Headers $headers
```

---

## Validação manual — P3 Tenants

1. `/tenants` — lista tenant `demo`
2. Criar tenant `prefeitura-x` / slug `prefeitura-x`
3. Detalhe → ver dados + datas
4. Editar nome; desativar tenant
5. Tentar login tenant app com user do tenant desativado → **Expected**: falha

---

## Validação manual — P4 Licenças

1. Detalhe tenant → aba Licenças
2. Confirmar 4 licenças com labels Carvalho, Pau-Brasil, Jatobá, Cedro
3. Desativar Jatobá
4. No app tenant (`demo`), acessar tela Fiscalização → **Expected**: bloqueio licença (403 ou UI indisponível)
5. Reativar Jatobá → funcionalidade volta

---

## Validação manual — P5 Setores

1. `/tenants/demo/setores`
2. Listar setores existentes do seed
3. Criar setor `Teste` / sigla `TST`
4. Editar chefe; desativar setor

---

## Validação manual — P6 Usuários

1. `/tenants/demo/users`
2. Criar user `novo@demo.com` role Administrador da plataforma
3. Login no app tenant (`5173`) com novo user + header tenant `demo`
4. Reset senha via admin SaaS; login com nova senha

---

## Validação isolamento credenciais

| Tentativa | Expected |
|-----------|----------|
| `saas@ci.com` no app tenant (`/auth/login` + X-Tenant-ID demo) | Falha ou não retorna admin_saas no tenant app |
| `ouvidoria@demo.com` no admin SaaS login | 401 |
| Token admin SaaS em rota tenant `/setores` sem role | 403 |

---

## Testes automatizados

```powershell
# API
cd ci-api-v2
npm test -- admin-plataforma
npm run test:e2e -- admin-plataforma

# Client
cd ci-client-v2/apps/admin-saas
npm run test
npm run typecheck

# Build
cd ci-client-v2
npm run build --filter=@ci/admin-saas
```

**Expected**: todos green; artefato em `apps/admin-saas/dist/`.

---

## Checklist SC (spec)

| ID | Critério | Como validar |
|----|----------|--------------|
| SC-001 | Login < 30s sem tenant | Cronometrar fluxo P1 |
| SC-002 | Provisionamento < 5 min | Tenant + licenças + user admin P3–P6 |
| SC-003 | Feedback CRUD claro | Toasts/erros em cada operação |
| SC-004 | Zero acesso não-admin | CT-E2E-004 + isolamento |
| SC-005 | Tenant em ≤3 cliques | Dashboard → Tenants → detalhe |
| SC-006 | Desativar tenant/licença reflete | P4 + login tenant |

---

## Troubleshooting

| Problema | Causa provável | Ação |
|----------|----------------|------|
| 401 em `/admin/*` | Token expirado ou role errada | Re-login admin SaaS |
| 400 X-Tenant-ID | Client enviando header tenant | Remover header no api client admin |
| CORS | API não permite origin 5174 | Configurar CORS Fastify |
| Porta 5174 ocupada | Conflito Vite | Alterar `server.port` em vite.config |
