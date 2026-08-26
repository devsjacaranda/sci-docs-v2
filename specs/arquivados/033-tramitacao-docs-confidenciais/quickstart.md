# Quickstart: Documentos confidenciais na Tramitação

**Feature**: 033-tramitacao-docs-confidenciais  
**Prerequisites**: PostgreSQL, tenant Jacaranda seeded, API + client dev, migration 033 aplicada

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

- Operador A — setor remetente (ex.: Gabinete)
- Operador B — setor destino (ex.: Jurídico), colega B2 não autorizado
- Operador C — outro setor (ex.: RH), autorizado no confidencial
- `admin@jacaranda.com` / `password123` — auditoria

Detalhes: [data-model.md](./data-model.md) · REST: [rest-api-tramitacao-docs-confidenciais.md](./contracts/rest-api-tramitacao-docs-confidenciais.md)

---

## Cenário 1 — Anexo público na criação (US1)

1. Login Operador A
2. http://localhost:5173/tramitacao/demandas → **Nova tramitação**
3. Setor destino Jurídico, assunto/corpo, anexar PDF **sem** confidencial
4. Enviar
5. **Esperado**:
   - Demanda na Enviadas de A / Recebidas Jurídico
   - Timeline evento criação com anexo
   - Operador B e B2 veem e baixam anexo

---

## Cenário 2 — Anexo confidencial multi-setor (US2, US3)

1. Operador A compõe tramitação para Jurídico
2. Anexa PDF, marca **Documento confidencial**
3. Adiciona setor Jurídico → seleciona apenas Operador B
4. Adiciona setor RH → seleciona Operador C
5. Enviar
6. **Esperado**:
   - B e C: anexo com botão baixar
   - Colega B2 (Jurídico, não listado): placeholder "Documento confidencial", sem download
   - Assunto, corpo e timeline visíveis para B2

**API smoke** (após criar demanda `DEMANDA_ID`):

```powershell
$h = @{"Authorization"="Bearer $tokenA"; "X-Tenant-ID"="jacaranda"}
# presign + upload omitido — ver contrato REST
Invoke-RestMethod -Uri "http://localhost:3000/tramitacao/demandas/DEMANDA_ID/anexos/ANEXO_ID/confirm" `
  -Method POST -Headers $h -ContentType "application/json" `
  -Body '{"isConfidential":true,"access":[{"sectorId":"JURIDICO_UUID","userIds":["B_UUID"]},{"sectorId":"RH_UUID","userIds":["C_UUID"]}]}'
```

---

## Cenário 3 — Validação confidencial incompleta (US2, FR-006)

1. Marcar anexo confidencial, adicionar setor sem selecionar usuário
2. **Esperado**: botão Enviar desabilitado + mensagem "Selecione ao menos um usuário em cada setor marcado"

---

## Cenário 4 — Encaminhar preserva ACL (US5)

1. Abrir demanda do Cenário 2 no Jurídico (Operador B)
2. Encaminhar para outro setor (ex.: Compras) com observação
3. **Esperado**:
   - Membros de Compras veem mensagem; anexo confidencial = placeholder
   - B e C mantêm acesso full
   - Novo anexo público no encaminhamento visível a todos

---

## Cenário 5 — Caixa pessoal confidencial (US4)

1. Toggle **Pessoal** → A envia mensagem para B com anexo confidencial autorizando C (RH)
2. **Esperado**:
   - B vê placeholder no anexo
   - C (se acessar thread) vê anexo full
   - Colegas de A/B não veem demanda (regra 031)

---

## Cenário 6 — Promover pessoal→setor (US6)

1. Mensagem pessoal A↔B com anexo confidencial (autoriza C)
2. Promover para setor Jurídico
3. **Esperado**:
   - Inbox setorial Jurídico lista demanda
   - Colegas Jurídico: mensagem sim, anexo placeholder
   - C mantém acesso

---

## Cenário 7 — Auditoria admin (US7)

1. Login `admin@jacaranda.com`
2. Abrir demanda com anexo confidencial (modo auditoria ou detail)
3. **Esperado**: todos anexos full; mutações bloqueadas

---

## Testes automatizados

```powershell
cd ci-api-v2; npm test -- --testPathPatterns=anexo-confidential
cd ci-api-v2; npm test -- --testPathPatterns=anexo-upload
cd ci-client-v2/apps/web; npm test -- ConfidentialAccessPicker
```

Ver [test-strategy.md](./contracts/test-strategy.md) para CT-DC-001..022.
