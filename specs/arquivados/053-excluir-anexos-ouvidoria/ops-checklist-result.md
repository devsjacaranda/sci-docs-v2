# Checklist operacional — quickstart §0 (spec 053)

**Data**: 2026-10-08  
**Ambiente registrado**: DB dev (Neon, mesma conexão do `prisma migrate deploy` local).  
**Wasabi / homologação**: **Pendente homologação** — itens 1–3 e conferência §4 não executados nesta sessão (exigem validação explícita no bucket de homologação/produção, não apenas credenciais no `.env` local).

> Não registrar segredos (`WASABI_*`) neste arquivo. Credenciais podem existir no `.env` local do desenvolvedor; isso não substitui o checklist no bucket alvo.

## 0.1 Versionamento do bucket

| Campo | Resultado |
| --- | --- |
| Status | **Pendente homologação** |
| Notas | Executar `aws s3api get-bucket-versioning --bucket <bucket> --endpoint-url <WASABI_ENDPOINT>` no bucket de homologação antes de go-live. |

## 0.2 Object Lock

| Campo | Resultado |
| --- | --- |
| Status | **Pendente homologação** |
| Notas | `aws s3api get-object-lock-configuration …`. Se houver retenção, exclusões devem falhar com `OUVIDORIA_ANEXO_DELETE_FAILED` — alinhar com PO. |

## 0.3 Permissões da credencial

| Campo | Resultado |
| --- | --- |
| Status | **Pendente homologação** |
| Permissões exigidas | `s3:ListBucketVersions`, `s3:DeleteObjectVersion`, `s3:DeleteObject`, `s3:GetObject` |
| Notas | Validar IAM/policy da chave usada em homologação. |

## 0.4 Chaves legadas (SQL)

Query quickstart §0 item 4 — executada no DB dev após migrate:

```sql
SELECT count(*) FROM "ManifestacaoAnexo" a
WHERE a."storageKey" IS NOT NULL AND a."deletedAt" IS NULL
  AND a."storageKey" NOT LIKE a."tenantId" || '/%';
```

| Campo | Resultado |
| --- | --- |
| **count** | **933** |
| Impacto | Anexos com chave fora do prefixo `<tenantId>/` falham fechado na exclusão (`OUVIDORIA_ANEXO_DELETE_FAILED`). Tratamento de legado à parte com PO/ops. |

## 0.5 Chaves duplicadas (SQL)

```sql
SELECT "storageKey", count(*) FROM "ManifestacaoAnexo"
WHERE "storageKey" IS NOT NULL GROUP BY 1 HAVING count(*) > 1;
```

| Campo | Resultado |
| --- | --- |
| **grupos duplicados** | **310** |
| Impacto | Segundo anexo ativo com a mesma `storageKey` recebe 409 `OUVIDORIA_ANEXO_DELETE_BLOCKED` até reconciliar dados. |

## §4 Conferência Wasabi pós-exclusão

| Campo | Resultado |
| --- | --- |
| Status | **Pendente homologação** |
| Notas | Após cenário 1 em homolog: `list-object-versions` na chave — esperado zero versões/delete markers (SC-002). |

## Gate de produção

Marcar feature **operacionalmente pronta** para Wasabi real somente após 0.1–0.3 e §4 OK em homologação e decisão sobre contagens 0.4/0.5.
