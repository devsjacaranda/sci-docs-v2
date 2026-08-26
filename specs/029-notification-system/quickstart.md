# Quickstart: Sistema de Notificações CI v2

**Feature**: 029-notification-system  
**Prerequisites**: API + client dev; tenant Jacaranda seeded; dois usuários em setores distintos com acesso Tramitação

## Setup

```powershell
cd ci-api-v2
npm run prisma:migrate
npm run prisma:seed
npm run start:dev

cd ci-client-v2
npm run dev
```

Variáveis (`.env` client):

```env
VITE_API_URL=http://localhost:3000
VITE_WS_URL=http://localhost:3000
VITE_USE_API=true
```

---

## Cenário 1 — Nova demanda (US1)

**Atores**: Operador A (setor remetente) · Operador B (setor destinatário)

1. Login Operador B em browser/tab 2 — manter dashboard aberto
2. Login Operador A — Tramitação → Nova demanda → setor de B → enviar
3. **Esperado em ≤ 5s (tab B)**:
   - Toast "Nova demanda na Tramitação"
   - Badge sino incrementa
4. Clicar toast "Abrir" → detalhe demanda `/tramitacao/demandas/:id`
5. Notificação marcada lida; badge decrementa

**API check**:

```powershell
# como Operador B (token + X-Tenant-ID)
curl -H "Authorization: Bearer $TOKEN_B" -H "X-Tenant-ID: jacaranda" `
  http://localhost:3000/notificacoes/unread-count
# → unreadCount >= 1
```

---

## Cenário 2 — Sino e histórico (US2)

1. Gerar 3 demandas para mesmo destinatário (ou usar seed demo)
2. Abrir sino — lista 3 itens, mais recente primeiro
3. Badge mostra 3 (ou `99+` se > 99)
4. Clicar item antigo — navega + marca lida

---

## Cenário 3 — Resposta (US3)

1. Operador A cria demanda para setor de A (via B respondendo) ou A envia para B
2. Operador B responde demanda
3. **Operador A** recebe toast/notificação tipo `tramitacao_resposta`
4. Operador B **não** recebe notificação da própria resposta

---

## Cenário 4 — Encaminhamento (US3)

1. Demanda no setor B
2. B encaminha para setor C
3. Criador original recebe `tramitacao_encaminhamento`
4. Operadores setor C recebem `tramitacao_nova_demanda`

---

## Cenário 5 — Offline / reconexão (SC-004)

1. Operador B: parar client ou fechar tab
2. A envia demanda
3. B reabre app / reconecta WS
4. Sino mostra notificação pendente (REST sync)
5. Sem duplicatas visíveis no dropdown

---

## Cenário 6 — Marcar todas lidas (US4)

1. Acumular ≥ 2 não lidas
2. Abrir sino → "Marcar todas como lidas"
3. Badge zera; itens sem dot

---

## Cenário 7 — Extensibilidade contrato (US5)

Validação documental + unit test:

- Inspecionar row persistida: campos `sourceModule`, `sourceRecordId`, `sourceType`, `sourceSnapshot`
- Confirmar registry client aceita novo módulo sem migration destrutiva (test NT-021)

---

## Troubleshooting

| Sintoma | Verificar |
|---------|-----------|
| Sem toast | WS conectado? Console `connection.ready` |
| Badge 0 mas há notificações | Token/tenant errado |
| 403 REST | JWT expirado |
| Duplicatas | dedupeKey — mesmo eventId+recipient |

---

## Referências

- [REST contract](./contracts/rest-api-notificacoes.md)
- [WebSocket contract](./contracts/websocket-notificacoes.md)
- [Data model](./data-model.md)
- [Test strategy](./contracts/test-strategy.md)
