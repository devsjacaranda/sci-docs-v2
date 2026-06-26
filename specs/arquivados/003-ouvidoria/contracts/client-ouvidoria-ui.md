# Contract: Client UI — Ouvidoria Interna

**Feature**: 003-ouvidoria  
**App**: `ci-client-v2/apps/web`  
**References**: [rest-api-ouvidoria.md](./rest-api-ouvidoria.md) · [regras-plataforma.md](../../../.cursor/docs/regras-plataforma.md) · mint-palette

## Rotas (existentes em `screens.ts`)

| screenId | Path | Implementação |
|----------|------|---------------|
| `ouvidoria-lista` | `/ouvidoria/manifestacoes` | `ManifestacoesListPage` |
| `ouvidoria-nova` | `/ouvidoria/manifestacoes/nova` | `ManifestacaoWizardPage` |
| `ouvidoria-detalhes` | `/ouvidoria/manifestacoes/:id` | `ManifestacaoDetailPage` |
| `ouvidoria-editar` | `/ouvidoria/manifestacoes/:id/editar` | Reusa wizard em modo edição (rascunho ou pré-encaminhamento) |

Lazy load via `React.lazy` — skill vite-react-best-practices.

---

## Wizard — Nova manifestação (FR-004)

### Etapas

| Step | Título UI | Campos |
|------|-----------|--------|
| 1 | Dados da manifestação | Relato*, Tipo*, Esfera*, Assunto*, Origem*, Canal*, Prazo*, Sigilo (checkbox), Manifestante (opcional), Município (autocomplete), Local do fato |
| 2 | Anexos | Upload drag-and-drop; copy: *"Adicione arquivos que complementem/documentem a demanda..."*; lista nome + tamanho |
| 3 | Revisão | Resumo read-only; copy: *"Revise os dados da sua manifestação. Caso queira alterar algum campo, retorne ao formulário."*; botões **Voltar ao formulário** e **Confirmar envio** |

### Pós-confirmação

Modal ou página de sucesso com:

- **Protocolo**: `OUV-2026-0138`
- **Chave de consulta**: exibida uma vez com aviso para anotar/repassar
- Botão **Ir para lista** / **Ver detalhe**

---

## Lista de manifestações (FR-010)

Layout conforme [regras-plataforma.md §4.1–§4.2](../../../.cursor/docs/regras-plataforma.md):

1. Breadcrumb → cabeçalho (título, contagem, **Nova manifestação**) → cards de estatística → card filtros → tabela → paginação.

Colunas conforme spec:

| Coluna | Fonte API |
|--------|-----------|
| Protocolo | `protocol` |
| Tipo | `typeLabel` |
| Categoria | `category` |
| Prioridade | `priorityLabel` |
| Status | `statusLabel` + badges operacionais (`badges`) |

Filtros: tipo, status, prioridade, busca por protocolo.

Paginação server-side (`page`, `limit`).

### Coluna Ações (menu ⋮)

**NUNCA** botões inline na linha. Usar `TableRowActionsMenu`:

| Item | Condição |
|------|----------|
| Ver detalhes | sempre |
| Editar | `status === draft` |
| Tramitar | `status ∈ { in_review, forwarding }` → abre `ForwardManifestacaoDialog` |

---

## Detalhe (FR-011, FR-012)

Layout:

1. **Cabeçalho**: protocolo, status badge, prazo
2. **Dados**: relato, tipo, esfera, assunto, origem, canal
3. **Manifestante**: seção oculta ou *"Manifestação anônima"* / *"Dados sob sigilo"* conforme API
4. **Local**: município + descrição
5. **Anexos**: lista com download
6. **Timeline**: eventos ordenados por data
7. **Ações** (toolbar): **Encaminhar**, **Responder**, **Encerrar** — habilitadas conforme `acoesPermitidas`

### Dialogs

| Ação | Campos |
|------|--------|
| Encaminhar | Setor destino (select), Observação |
| Responder | Texto resposta (textarea) |
| Encerrar | Motivo (textarea); confirmação se sem resposta |

Copy botões conforme `screens.ts` ouvidoria-detalhes.

---

## Permissão (FR-015)

- `useModuleAccess('ouvidoria')` antes de renderizar páginas
- 403 → `AccessDenied403` existente (spec 002)
- Item Ouvidoria **sempre visível** na navegação

---

## API client

Arquivo: `src/lib/ouvidoria-api.ts`

Funções espelhando REST contract; tipos compartilhados em `@ci/domain` quando estável (opcional v1 — tipos locais OK).

Upload flow:

1. `presignAnexo(manifestacaoId, file)`
2. `PUT uploadUrl` (fetch direto, fora do api-client)
3. `confirmAnexo(manifestacaoId, anexoId)`

---

## Paleta e UX

- Seguir mint-palette (CTA claro `#0F766E` / escuro `#2DD4BF`)
- Wizard: indicador de progresso; botões **Continuar** / **Voltar**
- Anexos inválidos: toast destructive com mensagem API
- Status operacionais: chips sem misturar conformidade Jatobá (§7.3 regras-plataforma)

---

## Fora de escopo (UI)

- SPA público de envio
- Tela pública de consulta por protocolo (API pronta; UI spec futura)
- Dashboard Carvalho, Fiscalização Jatobá, modelos Pau-Brasil, Insights Cedro nesta entrega
