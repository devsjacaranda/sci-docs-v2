# Quickstart: Fiscalização de Gestão — Gabinete (Jatobá)

**Feature**: 016-gabinete-fiscalizacao-integrada  
**Pré-requisitos**: API Gabinete Base (012), tenant Jacaranda com licença Jatobá, seed atos + cadastros demo

## 1. Testes automatizados (sem banco extra)

### API

```powershell
cd c:\ci-v2\ci-api-v2
npm test -- --testPathPattern=gabinete-fiscalizacao
npm run test:e2e -- --testPathPattern=gabinete-fiscalizacao
```

**Esperado**:

- Unitário: 10+ rule specs + agregação ato/vínculos + pareamento
- Integração: run persiste atos + órfãos
- E2E: guards, throttle 429, read-only

### Client

```powershell
cd c:\ci-v2\ci-client-v2
npm test --workspace=@ci/web -- --run GabineteAuditoria
npm test --workspace=@ci/web -- --run fiscalizacao
npm run typecheck --workspace=@ci/web
```

**Esperado**:

- Painel stats 4 conformidades
- Sheet títulos canônicos
- Card ato + scoped run

---

## 2. Validação manual (dev com Postgres)

### Subir stack

```powershell
cd c:\ci-v2\ci-api-v2
npm run start:dev

cd c:\ci-v2\ci-client-v2
npm run dev
```

### Seed

```powershell
cd c:\ci-v2\ci-api-v2
npm run prisma:seed
```

Garante atos Jacaranda + perguntas fiscalização Gabinete (pós-implementação 016).

### Login

- `admin@jacaranda.com` ou `paulo@demo.com`
- Tenant Jacaranda · módulo Gabinete

---

## 3. Cenários VS (validação ponta a ponta)

### VS-001 — Painel vazio → primeira execução

1. Navegar `/gabinete/auditoria`
2. Verificar título **Fiscalização de Gestão — Gabinete**, badge **Somente leitura**
3. Clicar **Fiscalizar atos**
4. Painel exibe stats, checagens e achados reais — **não** estado vazio permanente

### VS-002 — Ato com prazo vencido

1. Seed/atualizar ato com `concessionaireDeadline` passado, sem resposta
2. Fiscalizar
3. Achado **Não conforme** — Prazo concessionária
4. Abrir rastreio → sheet **Por que esta checagem deu este resultado**

### VS-003 — Pareamento notificação/auto

1. Cadastrar notificação órfã com `groupId` sem auto pareado
2. Fiscalizar
3. Painel lista **Cadastro órfão — Notificação** com conformidade **Parcial**

### VS-004 — Throttle

1. Executar **Fiscalizar atos** duas vezes em < 1h
2. Segunda tentativa → mensagem clara de limite — execução anterior visível

### VS-005 — Read-only (SC-005)

1. Anotar status operacional de ato antes da fiscalização
2. Fiscalizar + responder questionário interno
3. Status e campos do ato **idênticos** ao snapshot

### VS-006 — Card detalhe do ato

1. Abrir `/gabinete/atos/:id`
2. Card **Fiscalização Jatobá deste registro** visível
3. **Fiscalizar dados** → checagens atualizadas em ≤ 5s percebidos

### VS-007 — Questionário interno

1. No painel, **Novo questionário** sobre ato fiscalizado
2. Responder autenticado
3. Histórico: Destinatário *Interno*, Canal *Portal interno*, estado *Respondido*

### VS-008 — Histórico comparável

1. Executar ≥ 3 fiscalizações (aguardar throttle ou usar dias distintos)
2. Selecionar execução anterior no histórico
3. Stats/checagens refletem execução selecionada

### VS-009 — Cadastros órfãos isolados

1. Tenant só com notificação standalone (sem atos)
2. Fiscalizar → painel exibe resultados do cadastro órfão
3. **Sem** achados fabricados para atos inexistentes

---

## 4. Referências

- [REST contract](./contracts/rest-api-gabinete-fiscalizacao.md)
- [UI contract](./contracts/client-gabinete-fiscalizacao-ui.md)
- [Data model](./data-model.md)
- [Test strategy](./contracts/test-strategy.md)

---

## 5. Troubleshooting

| Sintoma | Verificar |
|---------|-----------|
| Painel sempre vazio após run | API logs; run `status=failed`; migration 016 aplicada |
| 403 na auditoria | Usuário lotado setor Gabinete; licença Jatobá tenant |
| Órfãos não aparecem | `cabinetId IS NULL`; registro não soft-deleted |
| Questionário externo visível | Bug — Gabinete deve ocultar opção externa |
