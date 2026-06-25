# Research: Tramitação — Demandas SIGED e Licenças

**Feature**: 005-tramitacao-siged-licencas  
**Date**: 2026-06-17

## R1 — Modelagem de origem SIGED no mock

**Decision**: Estender `TramitacaoMessage` com `origem: 'interna' | 'siged'`. Quando `siged`, incluir `processoSiged: ProcessoSigedSnapshot` obrigatório e `documentosSiged: DocumentoSigedSnapshot[]` (array vazio permitido — edge case spec).

**Rationale**: FR-003/FR-004 exigem distinção visual e metadados de processo/documento sem API. Tipos aninhados evitam poluir demandas internas.

**Alternatives considered**:

| Alternativa | Motivo de rejeição |
|-------------|-------------------|
| Prefixo no assunto (`[SIGED]`) | Frágil; não estrutura metadados |
| Tabela separada `sigedDemands` | Duplicação; quebra filtro unificado da inbox |
| Integração REST mock com MSW | Over-engineering para demo estática (FR-022) |

---

## R2 — Onde vive o código (shell vs modules/tramitacao)

**Decision**: Manter em `modules/shell/` (config, data, components/mock) até existir API `ci-api-v2/src/modules/tramitacao/`.

**Rationale**: FR-021/FR-022 e estado atual do repo; `TramitacaoInboxPanel` já em shell. Constitution V permite shell para infra mock.

**Alternatives considered**:

| Alternativa | Motivo de rejeição |
|-------------|-------------------|
| Criar `modules/tramitacao/` agora | Sem API espelho; escopo inflado |
| Mover tudo para `modules/shared/` | Tramitação não é cross-domain widget — é domínio próprio |

---

## R3 — Registro de telas de licença

**Decision**:

1. Adicionar `tramitacao` ao array `modules` em `license-screens.ts` → gera `tramitacao-maturidade` e `tramitacao-insights` automaticamente.
2. Adicionar `tramitacao-auditoria` manualmente em `screens.ts` (padrão `protocolo-auditoria`).
3. Atualizar `navigation.ts` com `...licenseNav('tramitacao')` + item Fiscalização.

**Rationale**: `buildLicenseScreens()` já centraliza Carvalho/Cedro; Jatobá panel segue padrão dos outros módulos.

**Alternatives considered**:

| Alternativa | Motivo de rejeição |
|-------------|-------------------|
| Só hardcode em screens.ts | Duplica lógica de stats de maturidade |
| Rotas dinâmicas sem ScreenConfig | Quebra `ScreenPage` e breadcrumbs |

---

## R4 — moduleLicenseConfig para Tramitação

**Decision**: Entrada em `@ci/domain`:

```typescript
tramitacao: {
  jatoba: { internalRespondent: true, externalRespondent: false },
  cedroFocus: 'Eficiência inter-setorial e volume SIGED',
  pauBrasilFocus: 'Ofícios, memorandos e alertas de prazo de tramitação',
}
```

**Rationale**: Espelha Protocolo (Jatobá só interno) com foco Cedro adaptado a transporte + SIGED. Alimenta descrições em `license-screens.ts`.

**Alternatives considered**:

| Alternativa | Motivo de rejeição |
|-------------|-------------------|
| Reusar config `protocolo` | Domínios distintos na spec; copy incorreta |
| Config só em screens.ts | Viola fonte única em `@ci/domain` |

---

## R5 — Barra de alertas na inbox

**Decision**: Renderizar `ListLicenseAlertBar` no layout da tela `tramitacao-demandas` (type `inbox`) quando `getModuleWorstStatus('tramitacao') !== 'ok'`. Registrar `tramitacao` em `MODULE_PATHS` de `license-alerts.ts`. Popular `jatobaProblems`, `cedroInsightsByModule`, `maturityByModule` para `tramitacao`.

**Rationale**: FR-016; paridade com listas (`ScreenPageLayout` já suporta barra para `type: list` — estender para `inbox`).

**Alternatives considered**:

| Alternativa | Motivo de rejeição |
|-------------|-------------------|
| Alertas só no dashboard | Viola US8 e SC-005 |
| Chips SIGED na tabela | Viola §4 regras-plataforma (alertas de licença não na tabela) |

---

## R6 — Status operacional derivado

**Decision**: Função pura `deriveOperationalStatus(demanda, now)` em `shell/lib/tramitacao-status.ts`:

- Com `prazo` no passado → `Vencendo` ou `Crítico` (crítico se &gt; 3 dias úteis — mock simples)
- Pasta `arquivadas` → `Arquivado`
- Com resposta recente sem encerrar → `Respondido`
- Encaminhamento pendente → `Tramitando`
- Default → `Pendente`

**Rationale**: FR-006/FR-007; separação clara de conformidade Jatobá (calculada em `traceability-mock` / regras JAT-TRAM-*)

**Alternatives considered**:

| Alternativa | Motivo de rejeição |
|-------------|-------------------|
| Status só em fixture estático | Não demonstra regra de prazo da Base |
| Reusar status de Protocolo | Campos diferentes (inbox vs documento protocolado) |

---

## R7 — Dashboard segregação SIGED

**Decision**: Adicionar card "Origem SIGED" e gráfico de barras empilhadas `tramitacaoOrigemPorMes` (SIGED vs Interna) em `DashboardCharts` case `tramitacao`. Filtro por setor reutiliza `tramitacaoSectors` + state existente no painel dashboard.

**Rationale**: FR-005, US3; Nivo já usado em `tramitacaoResolutividadeData`.

**Alternatives considered**:

| Alternativa | Motivo de rejeição |
|-------------|-------------------|
| Segundo dashboard | Viola consolidação institucional da spec |
| KPI só em texto | Não atende SC-007 visualmente |

---

## R8 — Rastreabilidade mock

**Decision**: IDs canônicos:

- Jatobá: `JAT-TRAM-SLA-001`, `JAT-TRAM-SIG-002` (assinatura SIGED)
- Cedro: `tram-ins-001` (gargalo setores), `tram-ins-002` (tendência SIGED)
- Carvalho: entrada em `maturityByModule.tramitacao` + trace `carvalho-tram-001`

**Rationale**: [traceability-mock.md](../../.cursor/docs/traceability-mock.md) padrão `JAT-{MOD}-{DOM}-{NNN}`; sheets com títulos §1.7.

**Alternatives considered**:

| Alternativa | Motivo de rejeição |
|-------------|-------------------|
| Reusar traces de Protocolo | Contexto e dados internos diferentes |
| Sem rastreabilidade | Viola FR-017 e US4–US6 |

---

## R9 — Pau-Brasil na composição

**Decision**: No sheet **Compor** de `TramitacaoInboxPanel`, seção de ações Pau-Brasil com botões **Usar modelo — Ofício**, **Memorando**, **Despacho** via `MockInlineActionButton` + preset existente; alerta normativo em card colapsável acima do editor.

**Rationale**: FR-015; padrão `MockForm` license actions sem criar tela Pau-Brasil dedicada (não exigida para Tramitação na matriz global — contextual como Compras/Ouvidoria).

**Alternatives considered**:

| Alternativa | Motivo de rejeição |
|-------------|-------------------|
| Tela `/tramitacao/biblioteca` | Fora do padrão módulo; Pau-Brasil global já existe |
| Modelos só em Protocolo | Usuário pediu Pau-Brasil completo no módulo |

---

## R10 — Testes nesta feature

**Decision**: Smoke manual ([quickstart.md](./quickstart.md)) + `npm run build` / typecheck. Testes unitários opcionais para `deriveOperationalStatus` e filtros de setor se extraídos.

**Rationale**: Constitution II com escopo mock UI — alinhado ao plan 004; sem API não há `testing-conventions` Jest e2e.

**Alternatives considered**:

| Alternativa | Motivo de rejeição |
|-------------|-------------------|
| Playwright E2E completo | Fora de escopo spec; custo alto para mock |
| Zero testes | Build/typecheck insuficiente para regressão de tipos mock |
