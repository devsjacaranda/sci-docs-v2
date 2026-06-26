# Contract: Mock Data Layout — Tramitação SIGED

**Feature**: 005-tramitacao-siged-licencas  
**Files**: `ci-client-v2/apps/web/src/modules/shell/data/`

## Arquivos e responsabilidades

| Arquivo | Conteúdo novo/alterado |
|---------|------------------------|
| `tramitacao-mock.ts` | Tipos SIGED; fixtures demandas; `tramitacaoOrigemPorMes`; stats dashboard |
| `mock-data.ts` | `maturityByModule.tramitacao`; `mockTableRows['tramitacao-auditoria']`; `jatobaProblems.tramitacao`; `cedroInsightsByModule.tramitacao` |
| `traceability-mock.ts` | Traces JAT-TRAM-*, tram-ins-*, carvalho-tram-001 |

## Demandas mínimas (`tramitacaoMessages`)

| id | origem | folder | sectorContext | subject (resumo) | SIGED |
|----|--------|--------|---------------|------------------|-------|
| `msg-1` | interna | recebidas | gab | Re: teste | — |
| `msg-2` | interna | recebidas | dejur | Encaminhamento jurídico | — |
| `msg-3` | interna | enviadas | ouv | OUV-0142 | — |
| `msg-sig-1` | siged | recebidas | dejur | Parecer SEMEF | `SIGED-2026-0042817` + 2 docs |
| `msg-sig-2` | siged | recebidas | gab | Despacho SEMUSB | `SIGED-2026-0042901` + 1 doc assinatura pendente |
| `msg-sig-3` | siged | recebidas | ouv | Processo ouvidoria encaminhado | `SIGED-2026-0042955` + 0 docs |

**Total mínimo**: 6 mensagens (3 internas existentes + 3 SIGED novas).

## Processo SIGED — fixture `msg-sig-1`

```yaml
protocolo: SIGED-2026-0042817
tipo: Processo Administrativo
secretariaOrigem: SEMEF
assunto: Solicitação de parecer sobre aditivo contratual
statusProcesso: Em tramitação
recebidoEm: 03/06/2026
documentos:
  - tipo: Ofício
    numero: OF-12847/2026
    statusAssinatura: Concluída
  - tipo: Anexo técnico
    numero: ANX-442/2026
    statusAssinatura: Não aplicável
```

## Jatobá — `tramitacao-auditoria` rows (mín. 3)

| registro | conformidade | problemas |
|----------|--------------|-----------|
| `msg-sig-2` / DESP-SEMUSB | Parcial | Assinatura pendente em memorando SIGED |
| `msg-2` / DEJUR | Não conforme | Tramitação 3 dias acima da meta SLA |
| `msg-sig-1` / SEMEF | Pendente | Aguardando parecer interno |

## Cedro — `cedroInsightsByModule.tramitacao` (mín. 2)

| id | impact | title |
|----|--------|-------|
| `tram-ins-001` | Crítico | Gargalo recorrente Gabinete → Jurídico |
| `tram-ins-002` | Alto | Volume SIGED +18% vs mês anterior |

## Carvalho — `maturityByModule.tramitacao`

```yaml
label: Tramitação
overall: 71
jatobaContribution: 39
scores:
  Controle Interno: 68
  Governança: 74
  TI: 72
```

## Jatobá problems — `jatobaProblems.tramitacao` (para alert bar)

Mínimo 1 entrada `Não conforme` ligada a `JAT-TRAM-SLA-001` para disparar barra crítica na inbox.

## Dashboard stats — `tramitacaoDashboardStats` (estender)

```yaml
sigedCount: 6
internaCount: 18
sigedPercent: 25
```

## Rastreabilidade — IDs

| ID | Tipo | Título sheet |
|----|------|--------------|
| `JAT-TRAM-SLA-001` | Jatobá | Por que esta checagem deu este resultado |
| `JAT-TRAM-SIG-002` | Jatobá | Por que esta checagem deu este resultado |
| `tram-ins-001` | Cedro | De onde veio este insight |
| `tram-ins-002` | Cedro | De onde veio este insight |
| `carvalho-tram-001` | Carvalho | Como calculamos este score |

## `moduleLicenseConfig.tramitacao` (`@ci/domain`)

```typescript
{
  jatoba: { internalRespondent: true, externalRespondent: false },
  cedroFocus: 'Eficiência inter-setorial e volume SIGED',
  pauBrasilFocus: 'Ofícios, memorandos e alertas de prazo de tramitação',
}
```

## `license-alerts.ts`

Adicionar: `tramitacao: '/tramitacao'` em `MODULE_PATHS`.

## Regressão — não alterar

- Fixtures de outros módulos em `mock-data.ts`
- `tramitacao-draft.ts` contrato de cross-module (ouvidoria → demandas)
- Mensagens `msg-1`..`msg-3` estrutura base (apenas adicionar `origem: 'interna'` se tipagem exigir)
