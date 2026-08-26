# Quickstart: Validar fix tramitação Ouvidoria

**Feature**: 027-fix-ouvidoria-tramitar  
**Prerequisites**: Node.js 20+, PostgreSQL, `.env` em `ci-api-v2` e `ci-client-v2`  
**References**: [data-model.md](./data-model.md) · [contracts/](./contracts/) · [spec.md](./spec.md)

> Executar **após** implementação (`/speckit-implement`). Reproduz o bug reportado e valida a correção.

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

**Expected**: API `:3000`; client `:5173`; tenant Jacaranda com setor OUV e manifestação demo #18.

---

## VS-027-001 — Reproduzir bug (pré-fix) / Validar correção (pós-fix)

**Actor**: Admin institucional Jacaranda  
**Manifestação**: `11111111-1111-1111-1111-000000000018`

| Step | Action | Expected (pós-fix) |
|------|--------|-------------------|
| 1 | Login `admin@jacaranda.com` / `password123` + tenant Jacaranda | JWT OK, acesso ouvidoria |
| 2 | Navegar `/ouvidoria/manifestacoes/11111111-1111-1111-1111-000000000018` | Detalhe carrega |
| 3 | Acionar **Tramitar manifestação** | Modal abre |
| 4 | Selecionar setor destino **Jurídico**, observação `Teste tramitação` | Campos preenchidos |
| 5 | **Confirmar tramitação** | **200** — sem "Setor ativo não definido" |
| 6 | Verificar toast com protocolo TRAM-* | Demanda vinculada criada |
| 7 | Abrir timeline da manifestação | Evento encaminhamento registrado |
| 8 | Navegar demanda na Tramitação | `senderSectorId` = setor OUV (origem resolvida) |

**Pré-fix (regressão conhecida)**: step 5 retorna 400 `"Setor ativo não definido"`.

---

## VS-027-002 — Servidor com setor vinculado

**Actor**: `paulo@demo.com` (ou usuário seed com setorIds)

| Step | Action | Expected |
|------|--------|----------|
| 1 | Login servidor com vínculo setorial | JWT com setorIds |
| 2 | Tramitar manifestação em `in_review` | 200 |
| 3 | Verificar demanda Tramitação | senderSectorId = setor do usuário |

---

## VS-027-003 — Regressão status inválido

| Step | Action | Expected |
|------|--------|----------|
| 1 | Tentar tramitar manifestação em rascunho | 409 INVALID_STATUS_TRANSITION |
| 2 | Tentar tramitar manifestação encerrada | 409 INVALID_STATUS_TRANSITION |

---

## VS-027-004 — Erro acionável (tenant edge)

> Cenário sintético — requer tenant de teste sem setores ou mock em teste automatizado.

| Step | Action | Expected |
|------|--------|----------|
| 1 | Usuário sem setor, tenant sem setores cadastrados | 400 |
| 2 | Mensagem | Orienta cadastro de setores ou vínculo — não ambígua com setor destino |

---

## Validação automatizada

```powershell
cd ci-api-v2
npm test -- resolve-tramitacao-sector
npm test -- encaminhar-manifestacao
```

**Expected**: todos CT-OT-001..010 verdes.

---

## Checklist de conclusão

- [ ] Admin tenant tramita sem erro (VS-027-001)
- [ ] Servidor com setor tramita (VS-027-002)
- [ ] Status draft/closed rejeitados (VS-027-003)
- [ ] Testes automatizados passando
- [ ] Zero regressão fluxo spec 003 (timeline + demanda vinculada)
