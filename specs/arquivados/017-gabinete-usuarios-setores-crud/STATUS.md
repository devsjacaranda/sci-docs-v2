# STATUS — 017 Gestão Institucional (Usuários e Setores)

**Data**: 2026-06-25  
**Estado**: Concluída — 90/90 tasks em `tasks.md`

## Entregue

### API (`ci-api-v2`)
- `InstitutionalAdminGuard` + rotas paginadas `/users` e `/setores`
- CRUD completo: create, update, inactivate, restore, reset-password (users)
- CRUD setores: create, update, inactivate, restore
- Login bloqueado para usuário inativo — mensagem institucional FR-012
- Schemas Zod institucionais (roles `user` | `chefe_setor` only)
- **50 testes** Jest: guard, schemas, use-cases, repositories, controller Supertest (200 + 403)

### Client (`ci-client-v2`)
- Layout stack institucional (`components/institutional/*`)
- `UsersAdminPanel` + `SetoresAdminPanel` (listagem + CRUD dialogs)
- Rotas `/gabinete/usuarios`, `/gabinete/setores` + paridade Plataforma
- `InstitutionalAdminGate` nas pages Gabinete
- MSW handlers + fixtures
- Navegação **Gestão institucional** + imunidade filtro licença
- **18 testes** Vitest: KPI, stats, list, CRUD dialogs, plataforma, navigation, pages

## Validação

```powershell
cd ci-api-v2; npm test -- --testPathPatterns=setor --testPathPatterns=auth.service
cd ci-client-v2/apps/web; npm test -- setor
```

Quickstart manual (SC-001/SC-002 timing): `quickstart.md` §1–6 com seed Jacaranda.

## Critérios spec

| SC | Status |
|----|--------|
| SC-001 Listagem paginada | OK (automated + manual timing opcional) |
| SC-002 CRUD usuários | OK |
| SC-003 Login inativo bloqueado | OK (auth.service.spec) |
| SC-004 Componente compartilhado | OK |
| SC-005 Sem licença premium | OK |
| SC-006 Paridade Plataforma | OK |
