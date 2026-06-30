# Test Strategy: Módulo Saúde — Atendimento UBS

**Feature**: 024-saude-atendimento-ubs  
**Runner**: Vitest 3 (`apps/web`)

## Pirâmide

| Camada | Arquivos alvo | Prioridade |
|--------|---------------|------------|
| Unit | `lib/*.test.ts`, `schemas/*.test.ts` | P1 — RED first |
| Component | `components/*.test.tsx`, forms | P1 |
| Integration | `pages/*.test.tsx` + MemoryRouter | P2 |
| E2E leve | `__tests__/saude.e2e.test.tsx` | P2 |

## Casos unitários obrigatórios

### esus-export.test.ts

- Export consulta completa → snapshot FAI
- Campos obrigatórios ausentes → `{ ok: false, missing: [...] }`
- Lista vazia procedimentos → array vazio no payload

### receita-signature.test.ts

- Mesmos inputs → mesmo código (determinístico)
- Código válido → `{ valid: true }`
- Código inválido / revogada → `{ valid: false }`

### conferencia-rules.test.ts

- Cidadão sem CNS nem CPF → flag `cidadao_sem_identificacao`
- Avaliação vazia sem CID/CIAP → flag `avaliacao_incompleta`

### unidades-stats.test.ts / indicadores.test.ts

- Totais coerentes com seed fixo para UBS X em Jun/2026
- Filtro médico reduz contagem

### solicitacoes-store.test.ts

- Create + update status persiste (mock localStorage)
- Filtro por UBS

## Casos componente

- `ConsultaSoapTabs` renderiza 6 seções
- `ReceitasRelatorioPage` — somente leitura (sem botão editar)
- `ValidarReceitaPage` — input código + submit

## Casos integração / e2e

1. **Jornada consulta P1**: list → nova → preencher → salvar → detalhe abas
2. **Jornada validação**: `/validar` código seed → autêntica
3. **Jornada relatório exames**: 100% solicitantes CBO médico
4. **Jornada tramitação**: TramitarButton navega compose com draft saude

## Comandos

```powershell
cd sci-client-monorepo/apps/web
npm test -- saude
npm test -- esus-export
npm test -- receita-signature
```

## Cobertura mínima aceitação

- `lib/esus-export.ts` — 100% branches export/validate
- `lib/receita-signature.ts` — 100%
- `lib/conferencia-rules.ts` — 100% flags conhecidas
- Páginas P1 montam sem throw com seed

## Fora de escopo teste

- API NestJS / Prisma
- Envio real SISAB
- MSW handlers HTTP (sem API)
