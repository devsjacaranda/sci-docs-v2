# Quickstart: Jurídico Tramitação Linked

**Feature**: 028-juridico-tramitacao-linked  
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

- `admin@jacaranda.com` / `password123` (acesso amplo)
- `paulo@demo.com` / `password123` (chefe DEJUR)

---

## Cenário 1 — Lista e detalhe reais (US2)

1. Login como `admin@jacaranda.com`
2. Navegar para http://localhost:5173/juridico/processos
3. **Esperado**: tabela com processos do seed (não linhas mock `JUR-2026-0047` fixo do shell)
4. Clicar em um processo confirmado
5. **Esperado**: detalhe com assunto, partes, timeline — dados persistidos

**API smoke**:

```powershell
$login = Invoke-RestMethod -Uri "http://localhost:3000/auth/login" -Method POST `
  -Headers @{"X-Tenant-ID"="jacaranda"; "Content-Type"="application/json"} `
  -Body '{"email":"admin@jacaranda.com","password":"password123"}'
$h = @{"Authorization"="Bearer $($login.accessToken)"; "X-Tenant-ID"="jacaranda"}
Invoke-RestMethod -Uri "http://localhost:3000/juridico/processos?page=1&pageSize=10" -Headers $h
```

---

## Cenário 2 — Tramitar processo (US1)

1. Abrir detalhe de processo **confirmado** (status ≠ rascunho)
2. Clicar **Tramitar**
3. Selecionar setor destino (ex.: Gabinete) + observação
4. Confirmar
5. **Esperado**:
   - Toast com protocolo `TRAM-2026-*`
   - Link "Ver na Tramitação"
   - Novo evento "Tramitação inter-setorial" na timeline

6. Clicar link Tramitação → demanda aberta com badge origem **Jurídico**

**API smoke**:

```powershell
# Substituir PROCESS_ID por UUID real da lista
Invoke-RestMethod -Uri "http://localhost:3000/juridico/processos/PROCESS_ID/tramitar" `
  -Method POST -Headers $h -ContentType "application/json" `
  -Body '{"destinoSetorId":"SETOR_GAB_ID","observacao":"Parecer urgente"}'
```

---

## Cenário 3 — Linked record + Abrir origem (US3)

1. Tramitação → pasta Recebidas → demanda demo linked Jurídico
2. **Esperado**: painel registro de origem com protocolo `JUR-*`, tipo, status, partes
3. Clicar **Abrir origem**
4. **Esperado**: `/juridico/processos/00000000-0000-4000-8000-000000000088` (pós-seed) — **sem 404**

---

## Cenário 4 — Rascunho bloqueado

1. Criar processo via wizard sem confirmar
2. Tentar tramitar (se exposto) ou API POST tramitar
3. **Esperado**: 400 "Processo em rascunho não pode ser tramitado"

---

## Cenário 5 — Admin sem setor JWT (regressão 027 pattern)

1. Login `admin@jacaranda.com`
2. Tramitar processo confirmado
3. **Esperado**: 200 (setor resolvido via modulo juridico fallback) — **não** 400 "Setor ativo não definido"

---

## Cenário 6 — Origem removida

1. Tramitar processo → anotar demanda ID
2. Soft-delete processo origem (admin/DB)
3. Reabrir demanda Tramitação
4. **Esperado**: snapshot visível; indicador origem removida; link desabilitado

---

## IDs demo (pós-seed)

| Recurso | ID |
|---------|-----|
| Processo linked | `00000000-0000-4000-8000-000000000088` |
| Protocolo interno | `JUR-DEMO-2026-0001` (seed) |

Ver [data-model.md](./data-model.md) para contrato snapshot.

---

## Testes automatizados

Ver [test-strategy.md](./contracts/test-strategy.md).

```powershell
cd ci-api-v2; npm test -- --testPathPatterns=juridico
cd ci-client-v2/apps/web; npm test -- linked-record-snapshot
cd ci-client-v2/apps/web; npm test -- ForwardProcessoDialog
```

---

## Troubleshooting

| Sintoma | Causa provável | Ação |
|---------|----------------|------|
| Lista ainda mock | Router override ausente | Verificar `JURIDICO_OVERRIDES['juridico-lista']` |
| 404 Abrir origem | Seed ID inconsistente | Re-run seed; conferir sourceRecordId tramitação |
| 400 setor origem | resolveSector não aplicado | Verificar controller usa ResolveTramitacaoSectorUseCase |
| Painel linked vazio | Snapshot v1 sem hydrate | Verificar LinkedRecordPanel juridico branch |
