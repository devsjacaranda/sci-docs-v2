# STATUS — 024 Saúde Atendimento UBS / e-SUS

**Data**: 2026-06-29  
**Estado**: Concluída — 88/88 tasks em `tasks.md` (80 originais + 8 pós-implement)

## Entregue

### Client (`sci-client-monorepo/apps/web`)

Módulo **`modules/saude/`** — 100% mock client-side, persistência `localStorage` (`ci:saude:v1:{tenantId}:*`), tenant demo Careiro.

| Área | Entrega |
|------|---------|
| **US1 Consulta** | CRUD agregado 6 dimensões, SOAP tabs, procedimentos, receitas |
| **US2 Cadastros** | 8 UBS Careiro, cidadãos, profissionais, medicamentos |
| **US3 Relatórios** | ~400 receitas + ~100 exames (somente leitura) |
| **US4 Fila** | Solicitações cidadão→UBS editável + paginação |
| **US5 Validação** | `/validar` público + `receita-signature.ts` |
| **US6 Controle** | Indicadores Nivo, conferência, tramitação integrada |
| **Navegação** | Sidebar Saúde; 4 domínios (Atendimento, Cadastros, Acompanhamento, Controle) |
| **Dashboards** | Um por domínio (`/saude/atendimento`, `/cadastros`, `/acompanhamento`, `/controle`) |
| **Design system** | Layout institucional + detalhe com `CopyableField` |
| **Licenças mock** | Insights Cedro, Fiscalização Jatobá, Maturidade Carvalho |

**Telas registradas**: 20+ overrides em `SAUDE_OVERRIDES` + rota pública `/validar`.

**Testes**: **114** Vitest passando (`npm test -- saude navigation`).

### Pós-implement (T081–T088)

- Reorganização sidebar (Administração · Gestão · **Saúde**)
- 4 agrupamentos internos com dashboards dedicados
- Design system páginas lista + detalhe copiável
- 3 telas de licença com mocks realistas (6 insights, 7 achados fiscalização, 5 dimensões maturidade)
- Correções: UUID medicamentos seed, imports `InstitutionalStatGrid`, constantes licença local

## Validação

```powershell
cd sci-client-monorepo
npm run dev
# Login tenant demo · licença Base ou Todas

cd sci-client-monorepo/apps/web
npm test -- saude navigation
```

Cenários manuais: [quickstart.md](./quickstart.md).

## Critérios spec

| SC / US | Status |
|---------|--------|
| US1 CRUD consulta 6 dimensões | OK |
| US2 Cadastros 8 UBS Careiro | OK |
| US3 Relatórios receitas/exames | OK |
| US4 Fila solicitações | OK |
| US5 Validação pública `/validar` | OK |
| US6 Indicadores + conferência + tramitação | OK |
| US7 Export FAI e-SUS | **Adiado** — placeholder toast |
| Licenças Cedro/Jatobá/Carvalho | OK (mock) |

## Dívidas / futuro

- Implementar `lib/esus-export.ts` + testes FAI (US7)
- Atalhos Saúde em `welcome-shortcuts.ts`
- E2E Vitest leve (`saude.e2e.test.tsx`)
- Remover `_schema.sql` da raiz workspace
- Integração API NestJS + e-SUS real (fora escopo mock)
