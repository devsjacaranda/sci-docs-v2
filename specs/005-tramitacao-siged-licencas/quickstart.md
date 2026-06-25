# Quickstart: Validação Tramitação SIGED + Licenças

**Feature**: 005-tramitacao-siged-licencas  
**Prerequisites**: Node.js 20+  
**References**: [data-model.md](./data-model.md) · [contracts/](./contracts/) · [spec.md](./spec.md)

> Executar **após** implementação (`/speckit-implement`). Cenários mapeiam user stories da spec. **Somente client** — API não necessária.

## Setup

```powershell
cd ci-client-v2
npm install
npm run dev
```

**Expected**: SPA em `http://localhost:5173`; login mock/demo; módulo Tramitação visível na sidebar.

Build de segurança:

```powershell
cd ci-client-v2
npm run build
```

**Expected**: exit 0; artefato em `apps/web/dist/`.

---

## VS-001 — Identificar demanda SIGED na inbox (US1, SC-001)

| Step | Action | Expected |
|------|--------|----------|
| 1 | Navegar `/tramitacao/demandas` | Inbox carrega |
| 2 | Pasta **Recebidas** | Lista com demandas internas e SIGED |
| 3 | Localizar badge **SIGED** | Visível em &lt; 5s sem abrir detalhe |
| 4 | Abrir demanda `msg-sig-1` | Painel processo SIGED com protocolo `SIGED-2026-0042817` |
| 5 | Ver documentos vinculados | Tabela com ≥ 1 documento |

---

## VS-002 — Demanda SIGED sem documentos (edge case)

| Step | Action | Expected |
|------|--------|----------|
| 1 | Abrir `msg-sig-3` | Processo SIGED visível |
| 2 | Seção documentos | Mensagem *Nenhum documento vinculado...* — inbox não bloqueia |

---

## VS-003 — Tramitação inter-setorial (US2)

| Step | Action | Expected |
|------|--------|----------|
| 1 | Alternar pastas Recebidas / Enviadas / Arquivadas | Listas distintas |
| 2 | Abrir demanda recebida → **Encaminhar** | Dialog setor + texto |
| 3 | Confirmar | Novo evento no histórico de encaminhamento |
| 4 | **Responder** na thread | Entrada em conversa com autor/data |
| 5 | **Compor** nova demanda interna | Aparece em Enviadas (setor ativo) |

---

## VS-004 — Dashboard consolidado (US3, SC-007)

| Step | Action | Expected |
|------|--------|----------|
| 1 | Navegar `/tramitacao/dashboard` | KPIs visíveis |
| 2 | Ver indicador origem SIGED | Card ou gráfico SIGED vs Interna |
| 3 | Filtrar setor **DEJUR** | KPIs refletem subset DEJUR |
| 4 | Filtrar **Todos** | Visão institucional restaurada |

---

## VS-005 — Fiscalização Jatobá (US4, SC-003)

| Step | Action | Expected |
|------|--------|----------|
| 1 | Navegar `/tramitacao/auditoria` | Tabela fiscalização |
| 2 | Verificar coluna Conformidade | Valores ∈ {Conforme, Não conforme, Parcial, Pendente} |
| 3 | Linha SLA estourado | **Não conforme** ou **Parcial** |
| 4 | **Como chegamos aqui?** em achado | Sheet *Por que esta checagem deu este resultado* |
| 5 | Confirmar | Demanda na inbox **inalterada** após visualizar fiscalização |

---

## VS-006 — Insights Cedro (US5, SC-006)

| Step | Action | Expected |
|------|--------|----------|
| 1 | Navegar `/tramitacao/insights` | Lista insights |
| 2 | Ver badge **Somente leitura** | Presente |
| 3 | Abrir insight gargalo | Texto menciona setores |
| 4 | Abrir insight SIGED | Distingue origem externa |
| 5 | Sheet rastreabilidade | *De onde veio este insight* |

---

## VS-007 — Maturidade Carvalho (US6)

| Step | Action | Expected |
|------|--------|----------|
| 1 | Navegar `/tramitacao/maturidade` | Score e eixos CI/GOV/TI |
| 2 | Ver contribuição Jatobá | % exibido |
| 3 | **Como calculamos este score?** | Sheet rastreabilidade |

---

## VS-008 — Pau-Brasil na composição (US7)

| Step | Action | Expected |
|------|--------|----------|
| 1 | `/tramitacao/demandas` → **Compor** | Sheet aberto |
| 2 | Acionar **Usar modelo — Ofício** | Dialog mock Pau-Brasil |
| 3 | Concluir preset | Corpo pré-preenchido no editor |
| 4 | Alerta normativo prazo | Visível — não substitui campo prazo operacional |

---

## VS-009 — Barra de alertas e demo completa (US8, SC-002, SC-005)

| Step | Action | Expected |
|------|--------|----------|
| 1 | `/tramitacao/demandas` com alertas mock | Barra **Alertas ativos nas licenças** |
| 2 | Clicar chip Fiscalização | Navega `/tramitacao/auditoria` |
| 3 | Fluxo completo &lt; 10 min | SIGED → encaminhar → fiscalizar → insight → maturidade |
| 4 | Tabela inbox | **Sem** chips de licença nas linhas |

---

## VS-010 — Módulo aberto (FR-019)

| Step | Action | Expected |
|------|--------|----------|
| 1 | Login usuário qualquer setor demo | OK |
| 2 | Acessar `/tramitacao/demandas` | 200 — sem 403 |
| 3 | Acessar `/tramitacao/insights` | 200 |

---

## Checklist conformidade produto

Antes de considerar entrega completa ([regras-plataforma §8](../../.cursor/docs/regras-plataforma.md)):

- [ ] Vocabulário §1 (Carvalho, Jatobá, Cedro, Pau-Brasil, Insights IA, Fiscalização, Maturidade)
- [ ] Nenhuma regra **NUNCA** §2 violada (Cedro read-only, Jatobá não altera registro, etc.)
- [ ] Status Jatobá ⊆ conjunto fechado de 4 valores
- [ ] Prazos: Base opera, Jatobá fiscaliza SLA, Pau-Brasil normativo
- [ ] Cores mint-palette em badges SIGED e CTAs
