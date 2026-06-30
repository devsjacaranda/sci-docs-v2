# Contract: Client UI — Saúde (Atenção Primária / UBS)

**Feature**: 024-saude-atendimento-ubs  
**App**: `@ci/web`  
**Module**: `apps/web/src/modules/saude/`

## Licença

| Escopo | Licença |
|--------|---------|
| CRUD consultas, cadastros, fila, relatórios, conferência, indicadores, tramitar | **Base** |
| Camadas Cedro/Jatobá futuras | Opcional — fora P1 |

## Rotas autenticadas

| Path | Page | Licença | Screen id |
|------|------|---------|-----------|
| `/saude/dashboard` | `SaudeDashboardPage` | Base | `saude-dashboard` |
| `/saude/consultas` | `ConsultasListPage` | Base | `saude-consultas` |
| `/saude/consultas/nova` | `ConsultaFormPage` | Base | `saude-consultas-nova` |
| `/saude/consultas/:id` | `ConsultaDetailPage` | Base | `saude-consultas-detalhe` |
| `/saude/consultas/:id/editar` | `ConsultaFormPage` | Base | `saude-consultas-editar` |
| `/saude/conferencia` | `SaudeConferenciaPage` | Base | `saude-conferencia` |
| `/saude/unidades` | `UnidadesPage` | Base | `saude-unidades` |
| `/saude/cidadaos` | ScreenPage ou dedicada | Base | `saude-cidadaos` |
| `/saude/profissionais` | ScreenPage ou dedicada | Base | `saude-profissionais` |
| `/saude/medicamentos` | ScreenPage | Base | `saude-medicamentos` |
| `/saude/relatorios/receitas` | `ReceitasRelatorioPage` | Base | `saude-receitas-relatorio` |
| `/saude/relatorios/exames` | `ExamesRelatorioPage` | Base | `saude-exames-relatorio` |
| `/saude/solicitacoes` | `SolicitacoesPage` | Base | `saude-solicitacoes` |

Registro: `SAUDE_OVERRIDES` em `router.tsx` (padrão `IT_OVERRIDES`, `TRAMITACAO_OVERRIDES`). Metadados em `screens.ts`; páginas ricas **não** usam `MockDataTable` genérico.

## Rota pública

| Path | Page | Auth |
|------|------|------|
| `/validar` | `ValidarReceitaPage` | **Nenhuma** |

Registrar **fora** do layout `RequireAuth` — sibling de `/login`.

---

## ConsultaDetail (`ConsultaDetailPage`)

Layout com abas:

```
┌ Header: cidadão, data, UBS, profissional, status conferência ─┐
├ [Profissional/Local] [Cidadão] [Atendimento] [Clínico]      │
│  [Procedimentos] [Receitas/Exames]                           │
├ Ações: Editar | Exportar e-SUS | Tramitar                    │
└ Inconsistências (badges) se conferência pendente           ┘
```

- **Tramitar**: `TramitarButton` com `module="saude"`, snapshot consulta.
- **Exportar e-SUS**: chama `exportConsultaToFai(consulta)` → preview/download JSON.

---

## SaudeDashboard (indicadores)

- Filtros: UBS, médico, mês, período custom
- Cards: total consultas, receitas, exames
- Gráfico Nivo (bar/line) — produção mensal
- Stats por UBS via `unidades-stats.ts`

---

## Relatórios (somente leitura)

**Receitas**: tabela + agrupamento médico/mês; ~400 linhas; sem actions edit.

**Exames**: tabela com badge rotina/urgente; ~100 linhas; solicitante sempre médico.

---

## SolicitacoesPage (fila editável)

- DataTable com status editável inline ou dialog
- Filtro UBS + status
- CRUD via `solicitacoes-store.ts`

---

## UnidadesPage

- Grid/list 8 UBS Careiro
- Card: CNES, equipe, horário, `UnidadeStatsCard`
- Cadastro fixo seed — edição limitada ou read-only conforme tasks

---

## ValidarReceitaPage (público)

```
┌ Validar receita — Secretaria de Saúde ─────────────┐
│  [ Código da receita________________ ] [Validar]  │
│  → Resultado: autêntica | inválida | revogada      │
│     Prescritor, data, UBS (mínimo)                 │
└────────────────────────────────────────────────────┘
```

Sem sidebar shell; banner Careiro opcional (`careiro-banner.png`).

---

## Navegação

`navigation.ts` — grupo **Saúde** com ícone `HeartPulse` ou `Stethoscope`:

- Dashboard
- Consultas
- Unidades
- Solicitações
- Relatórios (sub: Receitas, Exames)
- Conferência

`welcome-shortcuts.ts` — atalhos consulta nova + validar receita (link externo `/validar`).
