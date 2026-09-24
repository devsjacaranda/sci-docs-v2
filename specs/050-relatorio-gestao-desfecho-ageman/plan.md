# Implementation Plan: Desfecho da demanda (gap 1)

**Branch**: `050-relatorio-gestao-desfecho-ageman` · **Spec**: [spec.md](./spec.md)

## Decisões de produto (backend)

### 1. Modelo de dados

| Decisão | Escolha | Motivo |
| --- | --- | --- |
| Novo status Prisma? | **Não** | Workflow permanece `answered` / `closed` / `closed_unresolved`. |
| Onde persiste jurídico? | **Enum nullable** `ManifestacaoDesfechoEncerramento` em `Manifestacao.desfechoEncerramento` | Só se aplica a encerramentos sem resolução; resolvida deriva de `closed` + `answered`. |
| Valores do enum | `meio_juridico`, `sem_resolucao_outros` | Planilha só destaca jurídico; demais encerramentos sem resolução ficam fora da coluna JURÍDICO. |
| Nullable? | **Sim** | Registros antigos e `answered`/`closed` não exigem valor; encerramento novo sem resolução **exige** valor via API. |
| Migration | **Sim** — `ALTER TYPE` + coluna + backfill opcional AGEMAN | Única alteração de schema deste gap. |

```prisma
enum ManifestacaoDesfechoEncerramento {
  meio_juridico
  sem_resolucao_outros
}
// Manifestacao.desfechoEncerramento ManifestacaoDesfechoEncerramento?
```

### 2. Encerramento (`POST .../encerrar`)

- Manter `houveResolucao: boolean`.
- Se `true`: `status = closed`, `desfechoEncerramento = null` (resolvida implícita).
- Se `false`: `status = closed_unresolved`, body MUST incluir `desfechoEncerramento: 'meio_juridico' | 'sem_resolucao_outros'`.
- Legacy string-only encerramento (admin): continua forçando `closed` sem desfecho.

Arquivos: `encerrar-manifestacao.use-case.ts`, `persist-encerramento.repository.ts`, `encerrarBodySchema`.

### 3. Mapeamento → relatório (cohort RESUMO GERAL)

Contagem por manifestação no filtro de período (**`createdAt` no intervalo**, alinhado à planilha "TOTAL DO ANO/MÊS" de entradas):

| Bucket planilha | Regra SQL lógica |
| --- | --- |
| **resolvidaPelaAgeman** | `status IN ('answered', 'closed')` |
| **meioJuridico** | `status = 'closed_unresolved' AND (desfechoEncerramento = 'meio_juridico' OR (desfecho IS NULL AND tenantDefaultJuridico))` |
| **pendente** | `status IN ('draft','in_review','forwarding')` — *excluir* `answered`/`closed*` |

`tenantDefaultJuridico`: helper de config tenant AGEMAN (flag existente ou constante de slug Jacaranda/AGEMAN documentada em T108) — **não** hardcode em SQL cru.

### 4. Mapeamento histórico `closed_unresolved`

| Situação | Contagem relatório AGEMAN | Contagem outros tenants |
| --- | --- | --- |
| `closed_unresolved`, desfecho NULL | **meioJuridico** (default) | **sem_resolucao_outros** (não jurídico) |
| `closed_unresolved`, `meio_juridico` | meioJuridico | meioJuridico |
| `closed_unresolved`, `sem_resolucao_outros` | não entra em meioJuridico; KPI legado "sem resolução" se necessário | idem |

Backfill T110 (opcional): `UPDATE Manifestacao SET desfechoEncerramento = 'meio_juridico' WHERE status = 'closed_unresolved' AND tenantId = :agemann` — torna default explícito e facilita auditoria.

### 5. Série mensal (substitui `demandasFinalizadas`)

- **Remover** do contrato público do relatório: `{ respondidas, arquivadasOk, arquivadas }`.
- **Adicionar** `demandasPorDesfecho[]`: `{ month, resolvidaPelaAgeman, meioJuridico, pendente }`.
- Eixo temporal: **`createdAt`** (mesmo cohort do RESUMO); diverge do SQL atual que usa `COALESCE(respondidoEm, arquivadoEm)` — **mudança intencional** para paridade planilha (documentar em release notes).

### 6. Resolutividade (KPI linha planilha)

- **Gap 1 entrega** campo derivado no KPI ou bloco `demandasEResolutividade`: percentual `resolvidaPelaAgeman / total` para o período.
- Série mensal `resolutividade` (com/sem resolução por `arquivadoEm`) **permanece** até gap 2 refatorar — evitar conflito: gap 2 owner altera `resolutividade[]`; gap 1 não altera essa série salvo renomear labels.

## Arquitetura

```
encerrar (UI/API) → desfechoEncerramento + status
        ↓
dashboard.repositories (novas agregações desfecho)
        ↓
get-dashboard-agregacoes.use-case (expõe raw)
        ↓
get-relatorio-gestao.use-case (monta KPIs + demandasPorDesfecho)
        ↓
client mappers / PDF / Excel
```

## Testes

- TDD: `encerrar-manifestacao.use-case.spec.ts` (desfecho obrigatório).
- Novo: `dashboard-desfecho.repository.spec.ts` ou estender `dashboard-agregacoes.use-case.spec.ts` com fixtures answered/closed/jurídico/pendente.
- Contrato: `get-relatorio-gestao.use-case.spec.ts` — shape novo + omit zero series.
- Client: `relatorio-gestao-mappers.test.ts`, `OuvidoriaRelatorioGestaoPage.test.tsx`.

## Dependências

- Implementar **após** merge 049 (orientações/satisfação estáveis).
- Coordenação paralela: [coordination-gaps-2-4.md](./coordination-gaps-2-4.md).
