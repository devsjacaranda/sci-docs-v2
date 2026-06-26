# Quickstart: Fiscalização Jatobá — Ouvidoria

**Feature**: 008-ouvidoria-jatoba-fiscalizacao  
**Pré-requisitos**: API ouvidoria Base (003), endereço shared (006), tenant com licenças incluindo Jatobá

## 1. Testes automatizados (sem banco extra)

### API — todas as camadas

```powershell
cd c:\ci-v2\ci-api-v2
npm test -- --testPathPattern=ouvidoria-fiscalizacao
npm run test:e2e -- --testPathPattern=ouvidoria-fiscalizacao
```

**Esperado**:

- Unitário: regras SLA, tramitação, agregação conformidade, throttle
- Integração: run + persist mock in-memory
- E2E Supertest: guards Jatobá, throttle 429, read-only SC-004

### Client — todas as camadas

```powershell
cd c:\ci-v2\ci-client-v2\apps\web
npm run test -- fiscalizacao
npm run typecheck
```

**Esperado**:

- Contrato: Zod parse fixtures + MSW paths
- Componente: painel, sheet títulos canônicos, card detalhe
- Integração: page + MSW refetch
- E2E Vitest: jornada fiscalizar → trace → questionário

---

## 2. Validação manual (dev com Postgres real)

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

Garante manifestações confirmadas no tenant `demo` + perguntas Jatobá default (após implementação).

### Fiscalização — painel

1. Login usuário setor Ouvidoria
2. Navegar `/ouvidoria/auditoria`
3. Verificar:
   - Título **Painel de Fiscalização — Ouvidoria**
   - Badge **Somente leitura**
   - Stats: Conforme / Não conforme / Parcial / Pendente (4 apenas)
   - Dados reais do tenant — não mock `OUV-2026-0138` fixo
4. Acionar **Fiscalizar manifestações**
5. Conferir achados com rastreio — sheet **Por que esta checagem deu este resultado**
6. Segundo clique na mesma hora → mensagem throttle

### Detalhe manifestação

1. Abrir manifestação confirmada
2. Card **Fiscalização Jatobá deste registro**
3. **Fiscalizar dados** → checagens atualizadas
4. Status operacional da manifestação **inalterado**

### Questionário interno

1. *Novo questionário* → Interno → selecionar perguntas → criar
2. Responder no portal
3. Histórico do painel: Destinatário *Interno*, Canal *Portal interno*, fluxo *Respondido*

### Questionário externo

1. Manifestação **identificada** com e-mail ou telefone
2. *Novo questionário* → Externo → WhatsApp ou E-mail
3. Copiar link gerado → abrir em aba anônima → responder
4. Manifestação **anônima**: opção externa **ausente** (não desabilitada)

### Banco de perguntas

1. Gerenciar banco → criar/editar/desativar pergunta
2. Nova pergunta disponível em *Novo questionário*

### Acesso negado

Usuário sem setor Ouvidoria → `403` em API ou tela 403 no client.

---

## 3. Checklist SC da spec

| SC | Como validar |
|----|----------------|
| SC-001 | Overview → Fiscalização em ≤ 3 cliques |
| SC-002 | Run manual 500 manifestações &lt; 30s (benchmark script ou seed ampliado) |
| SC-003 | 100% achados com rastreio via sheet |
| SC-004 | Manifestação idêntica antes/depois de fiscalizar (E2E-FIS-005 ou diff manual) |
| SC-005 | Rastreio só via sheet |
| SC-006 | Anônimo: zero PII em trace |
| SC-007 | Zero UI externo para anônimos |
| SC-008 | Jornada ponta a ponta ≤ 15 min |
| SC-009 | ≥ 3 execuções → comparar 2 anteriores no histórico |

---

## 4. Referências

- [spec.md](./spec.md)
- [data-model.md](./data-model.md)
- [rest-api-ouvidoria-fiscalizacao.md](./contracts/rest-api-ouvidoria-fiscalizacao.md)
- [client-ouvidoria-fiscalizacao-ui.md](./contracts/client-ouvidoria-fiscalizacao-ui.md)
- [test-strategy.md](./contracts/test-strategy.md)
- [regras-plataforma.md](../../.cursor/docs/regras-plataforma.md) §1.3, §1.7
- [licencas-canonicas.md](../../.cursor/docs/licencas-canonicas.md) §6 Ouvidoria
