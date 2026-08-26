# Quickstart: Caixa Pessoal na Tramitação

**Feature**: 031-tramitacao-caixa-pessoal  
**Prerequisites**: PostgreSQL, tenant Jacaranda seeded, API + client dev, migration aplicada

## Setup

```powershell
cd ci-api-v2; npx prisma migrate dev
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

- Operador A / B — usuários seed Jacaranda em setores distintos (ex.: Gabinete + Jurídico)
- `admin@jacaranda.com` / `password123` — auditoria (US7)

Detalhes schema: [data-model.md](./data-model.md) · REST: [rest-api-tramitacao-caixa-pessoal.md](./contracts/rest-api-tramitacao-caixa-pessoal.md)

---

## Cenário 1 — Compor mensagem pessoal (US1, US2)

1. Login como Operador A
2. Navegar http://localhost:5173/tramitacao/demandas
3. Alternar toggle **Pessoal**
4. Clicar **Nova mensagem**
5. Selecionar Operador B, assunto e corpo
6. Enviar
7. **Esperado**:
   - Protocolo `TRAM-2026-*`
   - Pasta **Enviadas** (A) contém demanda
   - Login B → toggle Pessoal → **Recebidas** contém demanda
   - Colega de setor de A **não** vê demanda em inbox Setor nem Pessoal

**API smoke**:

```powershell
$login = Invoke-RestMethod -Uri "http://localhost:3000/auth/login" -Method POST `
  -Headers @{"X-Tenant-ID"="jacaranda"; "Content-Type"="application/json"} `
  -Body '{"email":"OPERADOR_A_EMAIL","password":"password123"}'
$h = @{"Authorization"="Bearer $($login.accessToken)"; "X-Tenant-ID"="jacaranda"}
Invoke-RestMethod -Uri "http://localhost:3000/tramitacao/demandas/personal" `
  -Method POST -Headers $h -ContentType "application/json" `
  -Body '{"targetUserId":"OPERADOR_B_UUID","subject":"Teste pessoal","body":"Mensagem privada"}'
```

---

## Cenário 2 — Responder na thread (US3)

1. Operador B abre demanda recebida (modo Pessoal)
2. Aba **Conversa** → escrever resposta → enviar
3. **Esperado**:
   - Resposta na timeline
   - Operador A recebe notificação (sino) em ≤30s se online
   - Colega de setor de B não vê demanda

---

## Cenário 3 — Acesso negado a terceiro (US3, FR-003)

1. Operador C (não participante) tenta URL direta `/tramitacao/demandas/DEMANDA_ID`
2. **Esperado**: tela erro / 404 — sem assunto ou nomes vazados

---

## Cenário 4 — Encaminhar para setor (US5)

1. Participante abre demanda pessoal
2. **Encaminhar para setor** → selecionar setor destino + observação
3. Confirmar dialog irreversível
4. **Esperado**:
   - Demanda some da inbox Pessoal ativa
   - Setor destino → inbox **Setor** → Recebidas contém demanda
   - Timeline registra transição pessoal → setorial

---

## Cenário 5 — Encaminhar para outro usuário (US4)

1. Participante encaminha demanda de B para C
2. **Esperado**:
   - C vê em Recebidas; B não vê mais em pastas ativas
   - Histórico encaminhamento na timeline

---

## Cenário 6 — Auditoria admin_tenant (US7)

1. Login `admin@jacaranda.com`
2. Tramitação → toggle **Auditoria** (ou tab equivalente)
3. **Esperado**: lista todas demandas pessoais do tenant
4. Abrir demanda entre A e B
5. **Esperado**: thread completa, banner somente leitura, sem botões de ação

---

## Cenário 7 — Linked pessoal (US6)

1. Compor mensagem pessoal com vínculo registro Gabinete (ou seed demo)
2. Destinatário abre painel **Registro de origem**
3. **Esperado**: snapshot visível; visibilidade ainda privada entre participantes

---

## Validação automatizada

```powershell
cd ci-api-v2; npm test -- --testPathPatterns=personal
cd ci-client-v2/apps/web; npm test -- tramitacao
```

Test IDs: [test-strategy.md](./contracts/test-strategy.md)

---

## Troubleshooting

| Sintoma | Verificar |
|---------|-----------|
| Pessoal aparece na inbox setor | Migration + filtro `NOT personal active` |
| Terceiro vê demanda | Guard `AssertPersonalDemandaAccess` no GET detail |
| Notificação broadcast setor | Hook pessoal não deve chamar `forNovaDemanda` |
| 500 ao admin compor | `resolveUserTableId` em create |
