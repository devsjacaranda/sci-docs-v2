# Quickstart: Gabinete Tramitação Linked

**Feature**: 030-gabinete-tramitacao-linked  
**Prerequisites**: PostgreSQL, tenant Jacaranda seeded, API + client dev

## Setup

```powershell
cd ci-api-v2; npm run prisma:seed
cd ci-api-v2; npm run start:dev
cd ci-client-v2; npm run dev
```

`.env` client:

```
VITE_TENANT_ID=jacaranda
VITE_API_URL=http://localhost:3000
VITE_USE_API=true
```

Credenciais demo:

- `admin@jacaranda.com` / `password123` (acesso amplo — admin tenant)
- Operador gabinete conforme seed Jacaranda

---

## Cenário 1 — Tramitar ato do detalhe (US1)

1. Login como `admin@jacaranda.com`
2. Navegar para http://localhost:5173/gabinete/atos
3. Abrir ato elegível (status ≠ arquivado/finalizado)
4. Clicar **Tramitar**
5. Selecionar setor destino (ex.: Jurídico) + observação obrigatória
6. Confirmar
7. **Esperado**:
   - Toast com protocolo `TRAM-2026-*`
   - Link para demanda na Tramitação
   - Status ato → *Em trâmite*
   - Evento "Encaminhado" na timeline

**API smoke**:

```powershell
$login = Invoke-RestMethod -Uri "http://localhost:3000/auth/login" -Method POST `
  -Headers @{"X-Tenant-ID"="jacaranda"; "Content-Type"="application/json"} `
  -Body '{"email":"admin@jacaranda.com","password":"password123"}'
$h = @{"Authorization"="Bearer $($login.accessToken)"; "X-Tenant-ID"="jacaranda"}
# Substituir CABINET_ID e SETOR_ID
Invoke-RestMethod -Uri "http://localhost:3000/gabinete/cabinets/CABINET_ID/forward" `
  -Method POST -Headers $h -ContentType "application/json" `
  -Body '{"sectorId":"SETOR_JUR_ID","notes":"Encaminhar para parecer"}'
```

---

## Cenário 2 — Tramitar da lista (US2)

1. Em `/gabinete/atos`, menu ⋮ → **Tramitar** em linha elegível
2. Preencher modal e confirmar
3. **Esperado**: mesmos critérios do cenário 1; lista atualizada após reload

---

## Cenário 3 — Linked record + Abrir origem (US3)

1. Tramitação → pasta Recebidas → demanda demo linked **Gabinete**
2. **Esperado**: painel registro de origem com protocolo `GAB-*`, assunto, status, origem
3. Clicar **Abrir origem**
4. **Esperado**: `/gabinete/atos/00000000-0000-4000-8000-000000000077` — **sem 404**

Detalhes snapshot: [data-model.md](./data-model.md)

---

## Cenário 4 — Status inelegível bloqueado

1. Localizar ato *Finalizado* ou *Arquivado* na lista
2. **Esperado**: ação "Tramitar" ausente no menu
3. API POST forward em ato archived → 400 mensagem clara

---

## Cenário 5 — Observação obrigatória

1. Abrir modal Tramitar
2. Selecionar setor sem preencher observação
3. **Esperado**: botão confirmar desabilitado ou erro de validação
4. API com `notes: ""` → 400 validação Zod

---

## Cenário 6 — Admin tenant sem setor JWT (US4)

1. Login `admin@jacaranda.com`
2. Tramitar ato elegível
3. **Esperado**: 200 — setor origem resolvido via módulo Gabinete; **sem** erro FK ou setor indefinido

---

## Cenário 7 — Mesmo setor bloqueado

1. Tramitar ato para o mesmo setor de origem (Gabinete → Gabinete)
2. **Esperado**: 400 "Não é possível tramitar ao mesmo setor"

---

## Cenário 8 — Origem removida

1. Tramitar ato → anotar demanda ID
2. Soft-delete ato origem (admin/DB)
3. Reabrir demanda Tramitação
4. **Esperado**: snapshot visível; "Origem removida"; link desabilitado

---

## IDs demo (pós-seed)

| Recurso | ID |
|---------|-----|
| Ato linked | `00000000-0000-4000-8000-000000000077` |
| Protocolo esperado | `GAB-2026-0001` (primeiro ato seed) |

---

## Testes automatizados

Ver [test-strategy.md](./contracts/test-strategy.md).

```powershell
cd ci-api-v2; npm test -- --testPathPatterns=forward-cabinet
cd ci-client-v2/apps/web; npm test -- linked-record-snapshot
cd ci-client-v2/apps/web; npm test -- ForwardAtoDialog
```

---

## Troubleshooting

| Sintoma | Causa provável | Ação |
|---------|----------------|------|
| 404 Abrir origem | Seed ID inconsistente | Re-run seed; conferir `sourceRecordId` tramitação |
| Painel linked sem labels | Snapshot v1 | Verificar snapshot v2 pós-forward; hidratação gabinete |
| 400 setor remetente | Tenant sem setores | Cadastrar setor + vínculo módulo gabinete |
| Tramitar sem observação aceito | Schema/client desatualizado | Verificar notes min(1) API + UI required |
| Erro FK admin tenant | resolveUserTableId ausente | Verificar evento usa payload actor |
