# VALIDATION — Cenários manuais 1–13 (spec 053)

**Data**: 2026-10-08  
**Ambiente**: stub local (testes automatizados) + DB Neon dev (migrations aplicadas via `prisma migrate deploy`)

Legenda: **pass** = coberto por testes automatizados ou executado; **skip** = requer browser/Wasabi/homologação.

| # | Status | Notas |
| --- | --- | --- |
| 1 | pass | `delete-manifestacao-anexo.use-case.spec.ts` (file happy path: storage antes do tombstone, evento); `ManifestacaoAnexoItem.test.tsx` (sucesso remove item). Storage stub em `storage.service.delete-permanently.spec.ts`. |
| 2 | pass | `ConfirmDeleteAnexoDialog.test.tsx` — Cancelar, Esc, clique fora não chamam `onConfirm`. |
| 3 | pass | Use-case: status encerrados → 409 `OUVIDORIA_ANEXO_DELETE_CLOSED`; `ManifestacaoAnexoItem.test.tsx` — sem botão quando `anexosExcluiveis=false`. |
| 4 | pass | Use-case: anexo de outra manifestação / tenant / manifestação removida → 404; storage não chamado. |
| 5 | pass (API) / skip (UI+Wasabi) | Use-case: falha de storage → sem tombstone/evento, `OUVIDORIA_ANEXO_DELETE_FAILED`; UI: erro mantém item (`ManifestacaoAnexoItem.test.tsx`). Recuperação com credencial real não exercitada (homolog). |
| 6 | pass | Use-case: `alreadyDeleted: true` na segunda chamada; tombstone `count === 0` não duplica evento (`tombstone-manifestacao-anexo.repository.spec.ts`). |
| 7 | pass | Use-case: `kind=link` — sem `deleteObjectPermanently`, tombstone zera `externalUrl`; diálogo "Remover link" (`ConfirmDeleteAnexoDialog.test.tsx` T043). |
| 8 | pass (API) / skip (login UI) | Use-case: `admin_tenant` — `deletedByActorId/Role`, descrição "Por …"; `deletedByUserId` ausente. Smoke manual com login admin_tenant não executado nesta sessão. |
| 9 | skip | Assistente (wizard) — integração manual no browser; componentes `RevisaoAnexos` / `AnexoUploadZone` implementados (T032), sem e2e Playwright. |
| 10 | skip | Upload imediato sem reload — fluxo manual presign→confirm→delete; API retorna `anexoId` real (`anexos-api.delete.test.ts`). |
| 11 | pass | `compose-manifestacao-export-anexos.spec.ts` + `map-manifestacao-anexos.spec.ts` — anexo tombstone fora de export/DTO. |
| 12 | pass | `consulta-publica.use-case.spec.ts` — `marcos` omite `attachment_deleted`. |
| 13 | pass | Use-case: objeto ausente no storage após upload não confirmado → sucesso (sem tombstone bloqueado por HeadObject). |

## Testes quickstart §2 (2026-10-08)

| Pacote | Comando | Resultado |
| --- | --- | --- |
| API | `npm test -- --testPathPatterns="delete-manifestacao-anexo|tombstone-manifestacao-anexo|manifestacao-anexo-delete-policy|storage.service.delete-permanently|consulta-publica|map-manifestacao-anexos"` | 6 suites, 54 testes **OK** |
| Client | `npm test -- ManifestacaoAnexoItem ConfirmDeleteAnexoDialog anexos manifestacao-detail-view` | 7 arquivos, 40 testes **OK** |
| API build | `npm run build` | **OK** |
| API lint | `npm run lint` | **Falha pré-existente** (~1113 erros fora do escopo 053; não bloqueia entrega de código da feature) |

## Migrations

`npx prisma migrate deploy` — aplicadas `20261008120000_manifestacao_anexo_tombstone` e `20261008120100_manifestacao_evento_attachment_deleted` com sucesso.
