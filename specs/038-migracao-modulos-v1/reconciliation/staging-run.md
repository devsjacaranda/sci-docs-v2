# T043 — Ensaio live contra dump v1 (2026-08-21)

**Spec**: 038 · **Pipeline**: `ci-api-v2/scripts/migracao-agema-v1/`  
**Dump**: `c:\ci-v2\controleinterno_prod_ci (14).sql` (16 383 528 bytes, gerado 21/08/2026 13:22)  
**Commit**: nenhum.

## Ambiente

| Item | Resultado |
|---|---|
| MySQL local | XAMPP MariaDB 10.4.32 em `127.0.0.1:3306` — **não estava no ar**; `mysqld` iniciado a partir de `C:\xampp\mysql`. |
| Dump restaurado? | **Não**. Banco `controleinterno_prod_ci` inexistente. Única escrita no MySQL: `CREATE DATABASE` + import do dump (exit 0, ~72 s, 164 tabelas). |
| `MYSQL_V1_URL` | Não existia no `.env`. Apontado para o MySQL **local** (root, host `127.0.0.1`, DB `controleinterno_prod_ci`). Senha não documentada. |
| Destino v2 | `DATABASE_URL` já configurado (Neon pooler `sa-east-1`, database `neondb`). Tenant slug `ageman` **já existia** (`created: false`). Não é o MySQL de produção do v1. |
| Origem na carga | Somente leitura. Contagens v1 idênticas antes e depois (users 73, manifestations 315, addresses 310). |

Produção v1 **não** foi tocada. Docker MySQL indisponível.

## Comandos (ordem quickstart §3)

Aliases reais em `ci-api-v2/package.json`: `migracao:agema:count`, `migracao:agema:dry-run`, `migracao:agema`, `migracao:agema:compare`, `migracao:compare-fields`, `migracao:anexos`.

```powershell
cd ci-api-v2
npm run migracao:agema:count          # exit 0
npm run migracao:agema:dry-run        # exit 0
npm run migracao:agema                # exit 1 — P2002 em MigracaoRegistroOrigem
npm run migracao:agema:compare        # exit 1 — 10 mismatches
npm run migracao:compare-fields       # exit 0 — CLI só confirma a lib (não compara o dump)
npm run migracao:anexos               # exit 1 — referenced=682 linked=0
npm run migracao:agema                # 2ª carga — exit 1, mesmo P2002
npm run migracao:agema:compare        # exit 1 — 11 mismatches (manifestações +29)
```

## 1. Contagem da origem (`migracao:agema:count`)

| Entidade | Origem | Exclusões | Esperado |
|---|---:|---:|---:|
| users | 73 | 4 | 69 |
| sectors | 55 | 0 | 55 |
| user_sectors | 151 | 0 | 151 |
| manifestations | 315 | 0 | 315 |
| manifestation_attachments | 1 | 0 | 1 |
| manifestation_addresses | 310 | 0 | 310 |
| manifestation_concessionaire_infos | 310 | 0 | 310 |
| protocolos | 7 | 0 | 7 |
| demandas | 0 | 0 | 0 |
| diagnostico_processo_marcadores | 3 | 0 | 3 |
| controle_numerico_oficio | 7 | 0 | 7 |
| controle_numerico_oficio_circular | 1 | 0 | 1 |
| controle_numerico_portaria | 1 | 0 | 1 |
| controle_numerico_memorando | 1 | 0 | 1 |
| controle_numerico_memorando_circular | 0 | 0 | 0 |
| controle_numerico_resolucao | 0 | 0 | 0 |
| controle_notificacoes | 8 | 0 | 8 |
| controle_autos_infracao | 2 | 0 | 2 |
| documentos_tramitados_deae | 2 | 0 | 2 |
| documentos_tramitados_degplan | 6 | 0 | 6 |
| documentos_tramitados_dejur | 1 | 0 | 1 |
| documentos_tramitados_deres | 1 | 0 | 1 |
| demais `documentos_tramitados_*` (9 tabelas) | 0 | 0 | 0 |

Exclusões de users: 3 e-mails + 1 id fixture em `exclusion-list.ts`.

## 2. Dry-run (`migracao:agema:dry-run`)

`dryRun=true phase=all` — sem escrita. Contagens do mapeamento:

| Fase | Resultado |
|---|---|
| tenant | `created: false` (tenant `ageman` já no destino) |
| auth | users 69, adminTenants 2, setores 55, userSetores **134**, moduloSetores 66 |
| ouvidoria | manifestações 315, anexos 1, eventos 338, endereços 310, concessionárias 310 |
| gabinete | protocolos 7, controlesNumericos 10, notificações 8, autos 2, documentosTramitados 10, demandas 0 |
| diagnostico | marcadores 3, documentosInstitucionais 0 |

`userSetores` dry-run (134) ≠ origem (151): o mapper descarta 17 vínculos. Os 47 restantes na carga real pertencem a `isSuperAdmin` (viram `AdminTenant`, sem linha em `User`).

## 3. Carga 1 (`migracao:agema`) — **FALHOU**

Auth concluiu: users 69, adminTenants 2, setores 55, userSetores **87**, moduloSetores 66.

Abortou em `loadOuvidoria` → `persistRegistroOrigem` (`id-map-store.ts:70`):

```
P2002 Unique constraint failed on (`tenantId`, `entidade`, `idV2`)
```

Causa: endereços v1 com o mesmo `endereco`+`numero` são colapsados num único `Address` v2 (`findFirst` por street+number). O segundo `idV1` tenta gravar `MigracaoRegistroOrigem` com o mesmo `idV2`. Há **18 grupos** colidentes no dump (ex.: `tesste/123` ×5, `Rua Comendador Clementino/183` ×5).

Fases **não executadas**: resto de ouvidoria (concessionárias, anexos, eventos), gabinete, diagnóstico.

## 4. Compare após carga 1 — **FAIL** (10 entidades)

| Entidade | Esperado | v2 | Resultado |
|---|---:|---:|---|
| users | 69 | 69 | PASS |
| sectors | 55 | 55 | PASS |
| user_sectors | 151 | 87 | FAIL |
| manifestations | 315 | 315 | PASS |
| manifestation_attachments | 1 | 3 | FAIL |
| manifestation_addresses | 310 | 21 | FAIL |
| manifestation_concessionaire_infos | 310 | 0 | FAIL |
| protocolos | 7 | 6 | FAIL |
| demandas | 0 | 0 | PASS |
| controle_notificacoes | 8 | 4 | FAIL |
| controle_autos_infracao | 2 | 1 | FAIL |
| diagnostico_processo_marcadores | 3 | 0 | FAIL |
| controles_numericos (sum) | 10 | 8 | FAIL |
| documentos_tramitados (sum) | 10 | 8 | FAIL |

Gabinete/diagnóstico no destino refletem dados **pré-existentes** do tenant (a carga abortou antes dessas fases). Anexos 3 vs 1: resíduo anterior no Neon.

`migracao:compare-fields` **não compara o dump** — só imprime que a lib está pronta.

## 5. Idempotência — **FALHOU**

Segunda carga: mesmo P2002; auth idêntico (69 / 2 / 55 / 87 / 66). Compare depois:

| Entidade | Após 1ª | Após 2ª |
|---|---:|---:|
| manifestations | 315 PASS | **344 FAIL** (+29) |
| manifestation_addresses | 21 | 21 |
| user_sectors | 87 | 87 |
| demais incompletas | iguais | iguais |

**+29 manifestações**: o dump tem 29 linhas com `numeroProtocolo` nulo/vazio. Sem protocolo o loader faz `create` (não `upsert`). Cada reexecução duplica essas 29. É o caso que o quickstart §3 alerta (entidade sem chave natural).

Idempotência **não comprovada**. Origem MySQL intacta.

## 6. Anexos não localizados (`migracao:anexos`)

`referenced=682  linked=0  not_found=682` — exit 1.

`file_storage` no dump (tenant AGEMAN):

| `tipo_entidade` | Qtde |
|---|---:|
| manifestation | 632 |
| protocolo-virtual-solicitacao | 21 |
| demanda | 14 |
| protocolo | 10 |
| notification | 7 |
| ticket-message | 4 |
| **total** | **688** (682 após o mapper) |

Tabela `manifestation_attachments`: **1** linha. O relatório lê `file_storage` e cruza com `ManifestacaoAnexo.storageKey` no v2. A carga de anexos **não chegou a rodar**. `copyStorageObject` só copia disco local (`.local-storage`); Wasabi não foi exercitado. Chaves no formato `{tenantId}/{entityType}/{entityId}/{file}`.

## Veredito

Pipeline live **executado e bloqueado**. Count e dry-run verdes. Carga aborta no persist de endereço. Compare vermelho. Segunda carga **duplica** manifestações sem protocolo. FR-006 / SC-001 **não atendidos**.

### Bloqueios para reexecução

1. ~~`persistRegistroOrigem` P2002 em endereço street+number~~ — **corrigido em código** (2026-08-21, sem reexecução live). Ver §7.
2. ~~Manifestações sem `numeroProtocolo` duplicam na 2ª carga~~ — **corrigido em código** (2026-08-21). Ver §7.
3. Compare de `user_sectors` deve descontar superadmin→`AdminTenant` (47) e exclusões do mapper (17); esperado real da carga = 87.
4. Anexos: ou a carga completa, ou o relatório precisa cruzar Wasabi / `file_storage` além de `ManifestacaoAnexo`.
5. Destino já tinha cadastros parciais de gabinete (protocolos 6, controles 8, etc.).

## 7. Correção em código (sem reexecução live)

Carga live **não** foi refeita neste turno (dump permanece no MySQL local). Jest `scripts/migracao-agema-v1`: **11 suites / 41 testes PASSOU**.

| Bug | Causa real | Correção |
|---|---|---|
| P2002 em `MigracaoRegistroOrigem` | Dedup de Address por rua+número colapsava linhas v1 distintas no mesmo `idV2` | **1 Address v2 por linha v1** (`id-map` / `MigracaoRegistroOrigem`). Rua+número deixa de ser chave. Persistência: unique canônica `tenant+entidade+idV1`; N:1 residual não lança P2002; os dois `idV1` ficam no id-map. |
| +29 manifestações na 2ª carga | `create` puro quando `numeroProtocolo` é nulo/vazio | Chave natural = **id v1**. Resolve via id-map ou `findRegistroOrigem`; `update` se já existe; `upsert` por protocolo só quando há protocolo; nunca `create` na reexecução. |

Testes novos: `idempotency.spec.ts` (dois endereços v1 mesma rua → dois v2; manifestação sem protocolo não duplica) e `id-map-store.spec.ts` (dois `idV1` → um `idV2` sem P2002).

FR-006 / SC-001 **ainda não** comprovados ao vivo — falta reexecutar `migracao:agema` + compare.

## 8. Colisão `numeroPersonalizado` (2026-08-24)

Carga `--phase=ouvidoria` abortava com Prisma P2002 em `(tenantId, numeroPersonalizado)`. O v1 AGEMAN tem 3 `id_personalizado` duplicados.

**Correção**: `resolveNumeroPersonalizadoCollisions` — primeiro (createdAt, id v1) conserva o ID verbatim; duplicados seguintes ficam `null`. Loader não aborta a fase; P2002 residual nessa unique vira `null` + relatório.

**Live** (MySQL `127.0.0.1` → Neon DEV; `DIAGNOSTICO_DATABASE_URL` não usada): exit 0, 315 manifestações, 3 colisões. v2 agora 346 total / **311 preenchidos** / 35 nulos. Cada par: 1 preenchido + 1 null. `2026-3-08-0007` e `2026-4-08-0009` existem.

Detalhe: [ouvidoria-numero-personalizado-collisions.md](./ouvidoria-numero-personalizado-collisions.md).
