# STATUS — 053 Excluir Anexos Ouvidoria

**Data**: 2026-10-08  
**Estado**: Concluída — 54/54 tasks em `tasks.md`

## Entregue (spec)

### API (`ci-api-v2`)

- Migrations tombstone em `ManifestacaoAnexo` + enum `attachment_deleted`
- Policy `canDeleteAnexos`, `deleteObjectPermanently` (Wasabi versionado + stub local)
- `DELETE /manifestacoes/:id/anexos/:anexoId` + use-case com ordem storage→tombstone
- Repositories dedicados (tenant/`deletedAt` explícitos), filtro de leitura de anexos ativos
- `anexosExcluiveis` no detalhe e revisão; consulta pública e exportações sem anexo excluído

### Client (`ci-client-v2/apps/web`)

- `ConfirmDeleteAnexoDialog`, `ManifestacaoAnexoItem`, integração detalhe + wizard
- `deleteManifestacaoAnexo`, códigos de erro mapeados, `anexoId` real pós presign/link

### Testes

- **API**: 54 testes nos padrões do quickstart §2 (+ specs de repositório/policy)
- **Client**: 40 testes nos padrões do quickstart §2
- **Build API**: OK
- **Lint API**: falha pré-existente repo-wide (não introduzida pela 053)

## Validação

- Cenários 1–13: [VALIDATION.md](./VALIDATION.md)
- Checklist Wasabi/SQL: [ops-checklist-result.md](./ops-checklist-result.md) — **homologação Wasabi pendente**; SQL dev registra 933 chaves legadas e 310 grupos duplicados

```powershell
cd ci-api-v2; npx prisma migrate deploy
cd ci-api-v2; npm test -- --testPathPatterns="delete-manifestacao-anexo|tombstone-manifestacao-anexo|manifestacao-anexo-delete-policy|storage.service.delete-permanently|consulta-publica|map-manifestacao-anexos"
cd ci-client-v2/apps/web; npm test -- ManifestacaoAnexoItem ConfirmDeleteAnexoDialog anexos manifestacao-detail-view
cd ci-api-v2; npm run build
```

## Dívidas / futuro

- Executar quickstart §0 e §4 em homologação Wasabi antes de produção
- Smoke manual browser: cenários 8–10 (admin_tenant, wizard, upload imediato)
- Reconciliar chaves legadas/duplicadas no banco (contagens em `ops-checklist-result.md`)
