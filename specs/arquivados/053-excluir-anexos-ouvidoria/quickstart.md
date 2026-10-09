# Quickstart — validar 053 Excluir Anexos

Guia de validação; os testes automatizados (TDD) vêm de `/speckit-tasks` → `/speckit-implement`.

## 0. Pré-requisitos operacionais (antes de qualquer teste em produção/homologação)

Executar **em homologação** (nunca em dados reais sem backup/consentimento):

1. **Versionamento do bucket** — confirmar se o bucket do Wasabi é versionado (console Wasabi ou `aws s3api get-bucket-versioning --bucket <bucket> --endpoint-url <WASABI_ENDPOINT>`). A implementação cobre os dois casos; o resultado define o que conferir no passo 4.
2. **Object Lock** — `aws s3api get-object-lock-configuration …`. Se houver retenção compliance/governance, a exclusão **falhará de propósito** (erro `OUVIDORIA_ANEXO_DELETE_FAILED`); decidir com o PO antes de seguir.
3. **Permissões da credencial** (`WASABI_ACCESS_KEY`): `s3:ListBucketVersions`, `s3:DeleteObjectVersion`, `s3:DeleteObject`, `s3:GetObject`.
4. **Formato das chaves legadas** — todo anexo ativo precisa passar na regra "chave começa com `<tenantId>/`" (mesma do download). Verificar:

   ```sql
   SELECT count(*) FROM "ManifestacaoAnexo" a
   WHERE a."storageKey" IS NOT NULL AND a."deletedAt" IS NULL
     AND a."storageKey" NOT LIKE a."tenantId" || '/%';
   ```

   Resultado > 0 ⇒ esses anexos não poderão ser excluídos pela feature (falham fechado) — decidir tratamento à parte.
5. **Chaves duplicadas**:

   ```sql
   SELECT "storageKey", count(*) FROM "ManifestacaoAnexo"
   WHERE "storageKey" IS NOT NULL GROUP BY 1 HAVING count(*) > 1;
   ```

## 1. Setup local

```powershell
cd ci-api-v2; npm run prisma:migrate   # aplica as 2 migrations desta feature
cd ci-api-v2; npm run prisma:generate
cd ci-api-v2; npm run start:dev         # sem WASABI_* ⇒ modo stub (arquivos locais)
cd ci-client-v2; npm run dev
```

## 2. Testes automatizados

```powershell
cd ci-api-v2; npm test -- --testPathPatterns="delete-manifestacao-anexo|tombstone-manifestacao-anexo|manifestacao-anexo-delete-policy|storage.service.delete-permanently|consulta-publica|map-manifestacao-anexos"
cd ci-client-v2/apps/web; npm test -- ManifestacaoAnexoItem ConfirmDeleteAnexoDialog anexos manifestacao-detail-view
cd ci-api-v2; npm run lint; npm run build
```

## 3. Cenários manuais (stub ou homologação)

| # | Passos | Esperado |
|---|---|---|
| 1 | Manifestação `in_review` com 1 arquivo → Excluir → Confirmar | Item some; evento "Anexo excluído" com nome, autor e data; arquivo inexistente no storage |
| 2 | Abrir diálogo → Cancelar / Esc / clique fora | Nada muda; nenhuma chamada `DELETE` na aba Rede |
| 3 | Manifestação encerrada | Botão não aparece; `DELETE` direto ⇒ 409 `OUVIDORIA_ANEXO_DELETE_CLOSED` |
| 4 | `DELETE` com `anexoId` de outra manifestação e de outro tenant | 404 `OUVIDORIA_ANEXO_NOT_FOUND`; nada apagado |
| 5 | Derrubar o storage (credencial inválida) e excluir | Erro claro; item continua listado e baixável; **sem** evento; restaurar e repetir ⇒ conclui |
| 6 | Repetir o `DELETE` (curl duas vezes / duas abas) | Segunda resposta `alreadyDeleted: true`; 1 único evento |
| 7 | Anexo tipo link → Remover link | Some; evento registrado; **sem** chamada ao storage (log/mock) |
| 8 | Logar como `admin_tenant` e excluir | Sucesso (sem erro de FK); evento com "Por <nome do admin>"; `deletedByUserId` nulo, `deletedByActorId/Role` preenchidos |
| 9 | Rascunho no assistente (edição/revisão) → Excluir | Mesma regra e diálogo; lista do assistente atualiza sem perder dados do formulário |
| 10 | Upload novo e exclusão imediata, sem recarregar | Funciona (id real, não `fileName`) |
| 11 | Exportar PDF/DOCX após excluir | Anexo excluído não aparece nem é embutido |
| 12 | Consulta pública pelo protocolo | `marcos` sem "Anexo excluído" |
| 13 | Upload iniciado e **não confirmado** → Excluir | Sucesso mesmo sem objeto no storage |

## 4. Conferência no Wasabi (homologação)

Depois do cenário 1:

```powershell
aws s3api list-object-versions --bucket <bucket> --prefix "<storageKey>" --endpoint-url <WASABI_ENDPOINT>
```

Esperado: **nenhuma** `Versions` nem `DeleteMarkers` para a chave. Se aparecer versão remanescente ⇒ bug bloqueante (viola SC-002).

## 5. Banco

```sql
SELECT id,"fileName","deletedAt","deletedByUserId","deletedByActorRole","storageKey","externalUrl"
FROM "ManifestacaoAnexo" WHERE "deletedAt" IS NOT NULL ORDER BY "deletedAt" DESC LIMIT 5;
-- storageKey e externalUrl devem ser NULL; a constraint CHECK impede o contrário
```

## Critério de pronto

Todos os cenários 1–13 OK, testes verdes, `lint` e `build` sem erro, passos 0.1–0.5 registrados em `STATUS.md` (versionamento/retenção do bucket verificados — requisito da spec para marcar concluída).
