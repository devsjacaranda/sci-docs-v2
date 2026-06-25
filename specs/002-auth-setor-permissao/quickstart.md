# Quickstart: Validação Auth e Permissão por Setor

**Feature**: 002-auth-setor-permissao  
**Prerequisites**: Node.js 20+, PostgreSQL, `.env` em `ci-api-v2`  
**References**: [data-model.md](./data-model.md) · [contracts/](./contracts/) · [spec.md](./spec.md)

> Executar **após** implementação (`/speckit-implement`). Cenários mapeiam user stories da spec.

## Setup inicial

```powershell
cd ci-api-v2
npm install
npx prisma migrate dev
npx prisma db seed

npm run start:dev
```

Em outro terminal:

```powershell
cd ci-client-v2
npm install
npm run dev
```

**Expected**: API em `:3000` (ou porta configurada); client em `:5173`; seed demo com setores Gabinete/Jurídico e vínculo Protocolo Virtual.

---

## VS-001 — Login e contexto multi-setor (US4, FR-002)

```powershell
curl -s -X POST http://localhost:3000/auth/login `
  -H "Content-Type: application/json" `
  -H "X-Tenant-ID: demo" `
  -d '{"email":"user@demo.com","password":"password123"}'
```

**Expected**: JWT com `setorIds` array (não singular).

```powershell
curl -s http://localhost:3000/auth/me `
  -H "Authorization: Bearer <token>" `
  -H "X-Tenant-ID: demo"
```

**Expected**: `setorIds`, `chiefOfSetorIds`, `isPlatformAdmin` presentes.

---

## VS-002 — Acesso permitido por interseção de setores (US1)

| Step | Action | Expected |
|------|--------|----------|
| 1 | Login usuário lotado em Gabinete + Ouvidoria | Token OK |
| 2 | Navegar para `/protocolo/dashboard` (client) | Conteúdo renderiza (Gabinete autorizado) |
| 3 | Login usuário só Patrimônio | Token OK |
| 4 | Navegar para `/protocolo/dashboard` | Tela **403 · Acesso negado** |

**Expected**: Item Protocolo Virtual **visível** na sidebar em ambos os casos (FR-005).

---

## VS-003 — Copy 403 Protocolo Virtual (US2, FR-006)

Com usuário Patrimônio em `/protocolo/*`:

| Elemento | Expected |
|----------|----------|
| Código | `403 · Acesso negado` |
| Título | `Sem permissão para Protocolo Virtual` |
| Setores listados | Gabinete, Jurídico |
| Líderes | Maria Oliveira (Gabinete), Paulo Ribeiro (Jurídico) — ou equivalente seed |
| Botões | Voltar, Pedir permissão ao líder do setor |

---

## VS-004 — Solicitação multi-chefe (US2, US5, FR-007)

| Step | Action | Expected |
|------|--------|----------|
| 1 | Na 403, clicar **Pedir permissão ao líder do setor** | Confirmação de envio |
| 2 | Login chefe Gabinete → painel notificações | 1 notificação com solicitante + módulo |
| 3 | Login chefe Jurídico → painel notificações | 1 notificação equivalente |
| 4 | Clicar novamente na mesma sessão 403 | Sem duplicatas; estado "já enviada" |

**API check**:

```powershell
curl -s -X POST http://localhost:3000/permissoes/solicitacoes `
  -H "Authorization: Bearer <token-user>" `
  -H "X-Tenant-ID: demo" `
  -H "Content-Type: application/json" `
  -d '{"moduloSlug":"protocolo"}'
```

**Expected**: `notificacoesCriadas: 2` (Gabinete + Jurídico).

---

## VS-005 — Admin bypass e módulos abertos (US1, FR-008, FR-009)

| Persona | Rota | Expected |
|---------|------|----------|
| `admin@demo.com` | `/patrimonio/dashboard` | Acesso OK (bypass setor) |
| Qualquer user | `/global/dashboard` | Acesso OK |
| Qualquer user | `/tramitacao/dashboard` | Acesso OK |

---

## VS-006 — Gestão vínculos (US3, FR-010)

Login `admin@demo.com`:

| Step | Action | Expected |
|------|--------|----------|
| 1 | Abrir admin vínculos módulo–setor | Lista módulos + setores |
| 2 | PUT adicionar setor Patrimônio a Protocolo | 200 |
| 3 | Login user Patrimônio → Protocolo | Acesso OK |

User comum em admin vínculos → 403 admin (não menu oculto).

---

## VS-007 — Backend consistency (FR-012)

```powershell
curl -s http://localhost:3000/<rota-protegida-protocolo> `
  -H "Authorization: Bearer <token-patrimonio>" `
  -H "X-Tenant-ID: demo"
```

**Expected**: HTTP 403 com body `MODULO_SETOR_DENIED` e `authorizedSetores`.

---

## VS-008 — Testes automatizados (Constitution II)

```powershell
cd ci-api-v2
npm test
```

**Expected**: suites verdes para `ModuloPermissaoGuard`, services de setor/permissão, e2e login+403.

```powershell
cd ci-client-v2
npm run typecheck
```

**Expected**: zero erros; `permissions.ts` tipado contra API responses.

---

## Rollback / troubleshooting

| Sintoma | Check |
|---------|-------|
| 403 inesperado | `GET /permissoes/modulos` — setores do módulo |
| JWT sem setorIds | Re-login após migration UserSetor |
| Notificação só 1 chefe | Bug — spec exige todos (ver `requestModulePermission`) |
| Licença 403 | Verificar tenant tem 4 licenças ativas (FR-015) |
