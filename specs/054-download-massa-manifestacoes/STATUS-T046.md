# T046 — Verificação de segurança (automática vs manual)

**Data:** 2026-10-08

## Coberto por testes Jest (security.md § Testes mínimos)

| Item | Spec / arquivo |
| --- | --- |
| Id de outro tenant → 404, sem ZIP | `prepare-bulk-download.use-case.spec.ts` |
| Sem acesso 047 → 403 lote inteiro | `prepare-bulk-download.use-case.spec.ts` |
| `sessionId` alheio → 404 progresso/cancel/arquivo | `bulk-download-progress-cancel.spec.ts` |
| Ticket: Bearer-only no progresso; uso único no arquivo | `bulk-download-progress-cancel.spec.ts` |
| Zip slip (`../`, `\\`) | `sanitize-zip-entry-name.spec.ts`, `stream-bulk-download.use-case.spec.ts` |
| Cache hit bloqueado se `assertForUser` falha | `stream-bulk-download.use-case.spec.ts` |
| Audit/log sem ticket, storageKey ou bytes | `bulk-download-audit.spec.ts` |
| Query `ticket` redigida no Pino | `http-logger-options.spec.ts` |

## Manual (com API de dev no ar)

- **Quickstart cenário 1:** lote com manifestações mistas (imagem embutida + planilha no ZIP + seção "Anexos não embutidos" no PDF).
- **Lifecycle 48 h** no prefixo `ouvidoria/pdf-cache/`: rede de operação Wasabi, não bloqueante para dev.

T046 permanece `[ ]` em `tasks.md` até o cenário manual 1 ser validado pelo operador.

## Atualização 2026-10-09

O formato mudou para PDF único (T047–T058). Os testes de segurança acima continuam valendo; o caso de zip slip agora se aplica aos originais fora do PDF ({slug}/anexos/…) no ZIP condicional. O cenário manual 1 do quickstart foi reescrito (T060).
