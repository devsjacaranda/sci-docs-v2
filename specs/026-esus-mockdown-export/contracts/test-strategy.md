# Test Strategy: Exportação e-SUS Mockdown

**Feature**: 026-esus-mockdown-export  
**Runner**: Vitest 3 (`sci-client-monorepo/apps/web`)

## Pirâmide

| Camada | Arquivos alvo | Prioridade |
|--------|---------------|------------|
| Unit | `lib/esus-export.test.ts`, `lib/esus-cadastros-export.test.ts`, `schemas/esus-fai.schema.test.ts` | P1 — RED first |
| Componente | `EsusExportButton.test.tsx`, `EsusExportSheet.test.tsx` | P1 |
| Integração | `ConsultaDetailPage.test.tsx` (export flow), `SaudeConferenciaPage.test.tsx` | P2 |
| Snapshot | FAI payload consulta seed completa | P1 |

## Casos unitários obrigatórios

### esus-export.test.ts

| Caso | Esperado |
|------|----------|
| Consulta seed `pronto_envio` completa | snapshot FAI matches |
| CNES ausente | `{ ok: false, missing includes 'CNES' }` |
| Status `pendente` | missing inclui conferência |
| Sem CID/CIAP/avaliação | missing avaliação |
| Procedimentos vazios | `procedimentos: []` no payload |
| `includeDemoExtensions: true` + receita | `_demoExtensions.medicamentosPrescritos.length > 0` |
| Exame solicitante CBO 223565 | warning solicitante inconsistente |
| Enums turno/tipo/local/sexo | valores FAI corretos |

### esus-fai.schema.test.ts

- Payload válido parse OK
- Campo obrigatório removido → Zod error

### esus-cadastros-export.test.ts

- Package contém 8 UBS seed
- CNS consulta exportada existe em `cidadaos`

### esus-download.test.ts

- Filename sanitiza caracteres especiais do nome cidadão

## Casos componente

- Botão click com missing → toast, sheet **não** abre
- Botão click OK → sheet abre com tab FAI
- Download click → mock `URL.createObjectURL` chamado

## Comandos

```powershell
cd sci-client-monorepo/apps/web
npm test -- esus-export
npm test -- esus-fai
npm test -- EsusExport
npm test -- saude
```

## Cobertura mínima aceitação

- `lib/esus-export.ts` — 100% branches validate/export
- `schemas/esus-fai.schema.ts` — shape core FAI
- `EsusExportButton` — fluxos ok/fail/status gate

## Fora de escopo teste

- Envio SISAB / PEC
- Validação CNS dígito verificador MS (formato apenas)
- API NestJS
