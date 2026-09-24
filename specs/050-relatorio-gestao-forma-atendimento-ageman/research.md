# Research: Forma de atendimento no Relatório de Gestão (gap 2)

**Feature**: 050-relatorio-gestao-forma-atendimento-ageman  
**Date**: 2026-09-24  
**Referências**: spec 042 (bloco original), spec 049 (clarify — `serviceMode` só em orientações/encaminhamentos), planilha `FORMAS_ATENDIMENTO` / `FORMAS ATENDIMENTO_GRAF`, export AGEMAN em `new-demanda/ajustes-extraido-2.txt`.

## 1. Sintoma observado (produção AGEMAN)

O bloco **Forma de atendimento** do relatório de gestão (tela, PDF, Excel) exibe apenas:

| Mês | Forma (atual) | Total (exemplo acum. 2026) |
|-----|---------------|----------------------------|
| vários | `interna` | 314 |
| vários | `sem_canal` | 58 |

Nota de rodapé no export: *"De acordo com formulário: Aplicativo de mensagens; presencial…"* — mas os valores agregados não correspondem ao formulário nem à planilha manual.

## 2. Implementação atual (causa raiz)

### 2.1 SQL — `dashboard.repositories.ts`

A série `porFormaAtendimento` (reutilizada por `GET /ouvidoria/dashboard/agregacoes`, `GET /ouvidoria/relatorio-gestao` e módulo Diretor) agrupa por:

```sql
COALESCE(
  NULLIF(TRIM("dadosAdicionais"->>'formaAtendimento'), ''),
  NULLIF(TRIM("origem"), ''),
  'sem_canal'
) AS forma
```

- `origem` na migração AGEMAN v1 é **`interna`** (registro pelo operador) ou **`publica`** (manifestação pública) — **dimensão de provenência**, não canal físico.
- `dadosAdicionais.formaAtendimento` está **vazio em 100%** das manifestações AGEMAN no banco consultado (372/372).

### 2.2 Campo correto no domínio — `Manifestacao.serviceMode`

- Schema: `ci-api-v2/prisma/schema/manifestacao.prisma` — `serviceMode String?`
- Formulário interno: valor escolhido no select alimentado por **`OuvidoriaFormaAtendimento.descricao`** (catálogo tenant); persistido em `serviceMode` (`invalid-reference-field.ts` mapeia `formaAtendimento` → `serviceMode`).
- Ficha/PDF individual: rotulado **"Canal de atendimento"** em `documento-header.ts` (linhas 132, 166) — **mesmo campo** `serviceMode`.
- Migração v1: `resolveManifestationServiceMode` grava `extra.serviceChannelName` em `serviceMode`.

**Conclusão**: a fonte canônica de negócio para “como o cidadão foi atendido” é **`Manifestacao.serviceMode`**, alinhada ao catálogo `OuvidoriaFormaAtendimento` na escrita. O catálogo **não** é FK na manifestação; é lista de referência + validação na API/UI.

### 2.3 O que **não** usar

| Fonte | Motivo |
|-------|--------|
| `origem` | Proveniência interna/pública — explica 314× `interna` |
| `dadosAdicionais.formaAtendimento` | Legado v1 não populado pós-migração AGEMAN |
| `OuvidoriaFormaAtendimento` direto na agregação | Tabela catálogo; contagem deve vir das manifestações via `serviceMode` |
| Reutilizar bloco `orientacoesEncaminhamentos[].canal` | Mesmo campo (`serviceMode`), mas bloco diferente (concessão×ano, histórico multi-ano); não substitui série mensal `porFormaAtendimento` |

## 3. Dados reais — tenant AGEMAN (Neon, 2026-09-24)

Consulta com a expressão **atual** vs **`serviceMode`**:

| Dimensão | Distribuição |
|----------|--------------|
| **porFormaAtendimento (SQL atual)** | `interna` 314, `sem_canal` 58 |
| **`serviceMode`** | Aplicativos de mensagem 250, E-mail 34, Presencial 30, Fala.Br 27, 0800 16, *(vazio)* 13, Outros 2 |
| **`origem`** | interna 314, *(vazio)* 58 |
| **`dadosAdicionais.formaAtendimento`** | *(vazio)* 372 |

Catálogo seed AGEMAN (8 itens): Aplicativos de mensagem, Presencial, Presencial Ação Social, E-mail, 0800, Telefone (celular/fixo), Outros, Fala.Br — espelha `AGEMAN_FORMAS_ATENDIMENTO` / planilha de formulário.

## 4. Planilha AGEMAN — `FORMAS ATENDIMENTO_GRAF`

Categorias acumuladas (2018–2026, 5331 demandas):

| Categoria planilha | Total acum. | % |
|--------------------|------------|---|
| WHATSAPP | 1694 | ~31,8% |
| CALL CENTER | 1160 | ~21,8% |
| E-MAIL | 1029 | ~19,3% |
| PRESENCIAL | 754 | ~14,1% |
| OUTROS | 592 | ~11,1% |
| FALA.BR | 99 | ~1,9% |
| CELULAR | 3 | ~0,06% |

Docx AGEMAN cita: Presencial, WhatsApp, E-mail, Call Center, Fala.br — alinhado a esta aba, não a `interna`/`sem_canal`.

## 5. Decisões

### D1 — Fonte canônica da agregação

**Usar `COALESCE(NULLIF(TRIM("serviceMode"), ''), 'Não informado')`** no `GROUP BY` de `porFormaAtendimento`, substituindo a expressão `dadosAdicionais`/`origem`.

- Fallback **`Não informado`** (não `sem_canal`) — consistente com `porZona`/`porBairro` e com `orientacoesEncaminhamentos.canal`.
- Valores no JSON/API permanecem as **descrições do catálogo** (ex.: `Aplicativos de mensagem`, `0800`) — o que o operador registrou.

### D2 — Rótulos na UI/export vs planilha histórica

Dois níveis:

1. **Padrão multi-tenant**: exibir `serviceMode` com `labelFormaAtendimento()` (`forma-atendimento-label.ts`) — já cobre códigos legados e descrições.
2. **Paridade AGEMAN / DOCX (opcional nesta feature, FR separado se escopo apertar)**: mapa de **rollup** catálogo → buckets da planilha (`FORMAS ATENDIMENTO_GRAF`) apenas para **legenda do gráfico / export DOCX**, não alterar o dado bruto na API:

| `serviceMode` (catálogo) | Bucket planilha/DOCX |
|--------------------------|----------------------|
| Presencial, Presencial Ação Social | PRESENCIAL |
| 0800 | CALL CENTER |
| Telefone (celular/fixo) | CELULAR |
| E-mail | E-MAIL |
| Aplicativos de mensagem | WHATSAPP |
| Fala.Br | FALA.BR |
| Outros (…) | OUTROS |
| *(vazio)* / Não informado | OUTROS ou Não informado *(clarificar com produto — planilha usa OUTROS para resíduo)* |

**Recomendação implementação**: entregar **D1 + rótulos D2 nível 1** como P1; rollup D2 nível 2 como P2 se o DOCX AGEMAN exigir exatamente sete séries nomeadas como na planilha (pode ser `lib/ageman-relatorio-forma-atendimento.ts` espelhando padrão `ageman-catalog.ts`).

### D3 — Escopo de superfícies afetadas

Alterar **uma** query em `dashboard.repositories.ts` propaga automaticamente:

- Dashboard Ouvidoria (`GET /ouvidoria/dashboard/agregacoes`)
- Relatório de gestão JSON/PDF/Excel/bloco PDF
- Dashboard Diretor (reuso das mesmas séries)

Testes a atualizar: `dashboard-agregacoes.use-case.spec.ts`, `get-relatorio-gestao.use-case.spec.ts`, exports PDF/Excel, frontend `OuvidoriaRelatorioGestaoPage` (hoje duplica mapa `interna`/`sem_canal` em vez de `labelFormaAtendimento`), `dashboard-mappers` / Vitest.

### D4 — Backfill

13 manifestações AGEMAN com `serviceMode` vazio: **fora de escopo** de migration automática nesta spec; aparecem como `Não informado`. Backfill manual ou script de migração histórica (spec 041) se necessário.

### D5 — Relação com spec 049

A spec 049 **deliberadamente** manteve `porFormaAtendimento` intacto ao introduzir `orientacoesEncaminhamentos` com `serviceMode`. Esta spec **corrige** o bloco 042; **não** remove nem altera orientações/encaminhamentos.

### D6 — Nomenclatura produto

Inconsistência existente: formulário/API fala "Forma de atendimento" (`errors.ts`), PDF fala "Canal de atendimento" (`documento-header.ts`). **Fora de escopo** salvo alinhar legenda do bloco do relatório para **"Forma de atendimento"** (título já correto em `relatorio-gestao-pdf-sections.ts`).

## 6. Critério de aceite técnico (sanity check AGEMAN)

Após D1, soma dos totais por forma no relatório (ano 2026, filtro default) deve bater com:

```sql
SELECT COALESCE(NULLIF(TRIM("serviceMode"), ''), 'Não informado') AS forma, COUNT(*)
FROM "Manifestacao"
WHERE "tenantId" = '<ageman>' AND "deletedAt" IS NULL
  AND EXTRACT(YEAR FROM "createdAt") = 2026
GROUP BY 1;
```

Esperado: predominância **Aplicativos de mensagem**, **zero** linhas `interna`/`sem_canal`.
