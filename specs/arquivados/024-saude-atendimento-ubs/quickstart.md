# Quickstart: Módulo Saúde — Atendimento UBS

**Feature**: 024-saude-atendimento-ubs · **Status**: Concluída (2026-06-29)

## Pré-requisitos

- Node.js 20+
- Dependências instaladas em `sci-client-monorepo`

```powershell
cd sci-client-monorepo
npm install
```

## Subir o client

```powershell
cd sci-client-monorepo
npm run dev
```

Abrir SPA tenant (turbo → `@ci/web`), autenticar com usuário licença **Base** (ou **Todas** para ver telas de licença).

## Navegação (pós-implement)

Sidebar **Saúde** — quatro domínios:

| Domínio | Dashboard | Operação |
|---------|-----------|----------|
| Atendimento | `/saude/atendimento` | Consultas, Solicitações |
| Cadastros | `/saude/cadastros` | Cidadãos, Unidades, Profissionais, Medicamentos |
| Acompanhamento | `/saude/acompanhamento` | Receitas, Exames |
| Controle | `/saude/controle` | Conferência + indicadores |

**Controle — licenças mock:**

| Tela | Licença | Rota |
|------|---------|------|
| Insights IA | Cedro | `/saude/insights` |
| Fiscalização | Jatobá | `/saude/fiscalizacao` |
| Maturidade | Carvalho | `/saude/maturidade` |

Redirecionamento: `/saude` → `/saude/atendimento`.

## Seed demo Careiro

Na primeira visita ao módulo Saúde, `ensureSaudeSeed()` popula:

- 8 UBS de Careiro da Várzea (AM)
- ~40 consultas + ~400 linhas receita + ~100 exames
- Fila inicial de solicitações

Limpar store local (opcional):

```javascript
// DevTools console
Object.keys(localStorage).filter(k => k.startsWith('ci:saude:')).forEach(k => localStorage.removeItem(k))
```

## Cenários de validação manual

### 1. CRUD Consulta (P1)

1. **Saúde → Atendimento → Consultas**
2. **Nova consulta** — preencher cidadão, profissional, UBS, data, SOAP, 1 procedimento, 1 item receita
3. Salvar → reabrir detalhe → verificar 6 abas + ícones **copiar** em cada campo
4. Editar plano clínico → salvar → confirmar listagem

**Esperado**: persistência após refresh (localStorage).

### 2. Relatório receitas (P2)

1. **Saúde → Acompanhamento → Receitas**
2. Agrupar por médico + mês
3. Tentar editar linha

**Esperado**: ~400 registros; somente leitura.

### 3. Relatório exames (P2)

1. **Exames solicitados**
2. Verificar coluna prioridade rotina/urgente
3. Confirmar solicitantes — todos médicos (CBO 225*)

**Esperado**: ~100 registros; zero enfermeiros.

### 4. Fila solicitações (P2)

1. **Atendimento → Solicitações**
2. Criar pedido para UBS
3. Alterar status para **Em análise**

**Esperado**: filtro por UBS + paginação.

### 5. Validação pública (P2)

1. Abrir `/validar` **sem login**
2. Informar código de receita seed
3. Repetir com código inventado

**Esperado**: autêntica vs não encontrada.

### 6. Conferência (P2)

1. **Controle → Conferência**
2. Revisar flags de inconsistência
3. Alterar status conferência

**Esperado**: stats grid + tabela institucional.

### 7. Licenças mock (pós-implement)

1. Filtro shell → **Cedro** → **Insights IA**
2. Filtro → **Jatobá** → **Fiscalização** (detalhe sheet com copy)
3. Filtro → **Carvalho** → **Maturidade** (radar + ranking UBS)

### 8. Export e-SUS (US7 — adiado)

1. Detalhe consulta → **Exportar e-SUS**

**Esperado atual**: toast placeholder — mapper FAI não implementado.

### 9. Tramitação (P2)

1. Detalhe consulta → **Tramitar**
2. Confirmar compose tramitação com assunto pré-preenchido

**Esperado**: draft `module: saude`.

## Testes automatizados

```powershell
cd sci-client-monorepo/apps/web
npm test -- saude navigation
```

**114 testes** (módulo saude + navigation).

Ver [contracts/test-strategy.md](./contracts/test-strategy.md).

## Referências

- Spec: [spec.md](./spec.md)
- Data model: [data-model.md](./data-model.md)
- UI contract: [contracts/client-saude-ui.md](./contracts/client-saude-ui.md)
- DTOs: [contracts/client-saude-dtos.md](./contracts/client-saude-dtos.md)
