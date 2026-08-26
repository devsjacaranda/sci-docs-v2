# Quickstart: Validação da Feature

**Feature**: [spec.md](./spec.md) · **Contratos**: [contracts/api-contracts.md](./contracts/api-contracts.md)

## Pré-requisitos

```powershell
cd ci-api-v2
npm run prisma:migrate:dev   # aplica migration SetorTela/UserTelaOverride
npm run prisma:seed          # popula setores/usuários + baseline
npm run start:dev
```

```powershell
cd ci-client-v2
npm run dev   # turbo → @ci/web, http://localhost:5173
```

Login como `admin_tenant` do tenant seed (ver `ci-api-v2/prisma/seed.ts` para credenciais).

## Cenário 1 — Configurar visibilidade por setor (US1)

1. Acessar `/administracao/plataforma/navegacao`, modo **Por setor**.
2. Selecionar setor "Ouvidoria" (OUV).
3. Verificar que a grade mostra `source: "baseline"` (nenhuma configuração salva) — telas dos módulos vinculados aparecem habilitadas.
4. Ativar a tela "Contratos" para o setor.
5. Confirmar via `curl`:

   ```powershell
   curl -H "Authorization: Bearer $TOKEN" -H "X-Tenant-ID: $TENANT" http://localhost:3000/setores/$SETOR_ID/telas
   ```

   Esperado: `"source": "explicit"` e `screenIds` incluindo `contratos-*`.

## Cenário 2 — Exceções por usuário (US2)

1. Modo **Por usuário**, selecionar um usuário com múltiplos setores (ex.: admin plataforma com 2 setores).
2. Verificar banner "N conflito(s)" e diálogo automático.
3. Confirmar 1 exceção `exceeds_sector` individualmente.
4. Confirmar as demais em lote.
5. Verificar badge "Exceção" no nome do usuário.
6. Confirmar via API:

   ```powershell
   curl -H "Authorization: Bearer $TOKEN" -H "X-Tenant-ID: $TENANT" http://localhost:3000/users/$USER_ID/tela-overrides
   ```

   Esperado: lista com os overrides confirmados.

## Cenário 3 — Sidebar reflete permissões (US5)

1. Logar como o usuário do Cenário 2 (ou outro usuário comum do setor OUV).
2. Verificar que a sidebar mostra: módulos abertos (global, tramitação) + telas configuradas para o setor + telas de chefia (se aplicável) + overrides.
3. Confirmar via API:

   ```powershell
   curl -H "Authorization: Bearer $TOKEN" -H "X-Tenant-ID: $TENANT" http://localhost:3000/me/screens
   ```

## Cenário 4 — CRUD de membros (US4)

1. Logar como chefe do setor GAB.
2. Acessar `/administracao/membros`.
3. Clicar "Adicionar membro" → selecionar usuário existente não vinculado → confirmar que aparece na lista.
4. Clicar "Criar novo usuário" → preencher formulário → confirmar criação e vínculo automático.
5. Desvincular um membro (não-chefe) → confirmar remoção da lista.
6. Tentar desvincular o chefe → confirmar erro 400 `CANNOT_UNLINK_CHIEF`.
7. Logar como chefe de outro setor (OUV) → tentar acessar API de membros do setor GAB diretamente → confirmar 403.

## Cenário 5 — Catálogo de telas (US3)

```powershell
curl -H "Authorization: Bearer $TOKEN" -H "X-Tenant-ID: $TENANT" http://localhost:3000/screens
```

Esperado: lista com todas as telas do sistema, incluindo `scope: "platform"` e `scope: "chefia"` nas telas administrativas.

Testar rejeição de screenId inválido:

```powershell
curl -X PUT -H "Authorization: Bearer $TOKEN" -H "X-Tenant-ID: $TENANT" -H "Content-Type: application/json" `
  -d '{"screenIds":["tela-que-nao-existe"]}' `
  http://localhost:3000/setores/$SETOR_ID/telas
```

Esperado: 400 com `invalidScreenIds: ["tela-que-nao-existe"]`.

## Critérios de sucesso (mapeamento SC → validação)

| SC | Como validar |
|----|---------------|
| SC-001 | Cenário 1 completo em < 1 min manual |
| SC-002 | Cenário 2, passo 2 — banner aparece imediatamente após seleção |
| SC-003 | Cenário 3 — sem cache manual, `/me/screens` reflete mudança do Cenário 1 |
| SC-004 | Grep por `platformUsersSeed`, `adminSectors`, `sectorMembersSeed`, `moduleSectorLinks` fora de `admin-mock.ts` deve retornar zero (arquivo mantido só como fallback/dev-seed local, se aplicável) |
| SC-005 | Cenário 4 completo via UI real |
| SC-006 | Logar com usuário sem setor — sidebar mostra só módulos abertos + perfil |
| SC-007 | Checar `AuditLog`/payload de `PUT /setores/:id/telas` e `PUT /users/:id/tela-overrides` — ator correto mesmo logado como `admin_tenant` |
