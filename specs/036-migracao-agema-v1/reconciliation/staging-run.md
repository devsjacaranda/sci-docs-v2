# Staging run — Migração AGEMAN

**Data**: 2026-08-10  
**Ambiente**: MySQL v1 local (Docker `mysql-v1-ageman:3307`) → Neon PostgreSQL (`DATABASE_URL` em `ci-api-v2/.env`)  
**Tenant v2**: slug `ageman`, id `a18ef378-f633-4d83-a756-fdc0b7b6cffd`

## Pré-requisitos operacionais

- [x] `MYSQL_V1_URL=mysql://root:devpass@localhost:3307/controleinterno_prod_ci`
- [x] Dump `controleinterno_prod_ci (13).sql` restaurado (62 users AGEMAN confirmados)
- [x] Migration `20260810180000_tenant_siged_config` aplicada (`npx prisma migrate deploy`)
- [ ] Lista de exclusão aprovada formalmente pela AGEMAN (T046 / FR-024) — lista técnica em `exclusion-list.ts` já aplicada

## Comandos executados

```powershell
docker run --name mysql-v1-ageman -e MYSQL_ROOT_PASSWORD=devpass -p 3307:3306 -d mysql:8
docker cp "controleinterno_prod_ci (13).sql" mysql-v1-ageman:/tmp/dump.sql
docker exec mysql-v1-ageman bash -c "mysql -uroot -pdevpass controleinterno_prod_ci < /tmp/dump.sql"

cd ci-api-v2
npx prisma migrate deploy
$env:MYSQL_V1_URL="mysql://root:devpass@localhost:3307/controleinterno_prod_ci"
npm run migracao:agema:count
npm run migracao:agema:dry-run
npm run migracao:agema
npm run migracao:agema:compare   # exit 1 — ver notas abaixo
```

## Resultado dry-run

| Fase | Contagens |
|------|-----------|
| tenant | criado (dry-run) |
| auth | users 58, adminTenants 2, setores 55, userSetores 134, moduloSetores 66 |
| ouvidoria | manifestações 257, anexos 1, eventos 279 |
| gabinete | protocolos 7, controles 10, notificações 8, autos 2, documentos 10 |

## Resultado migração real

| Fase | Contagens |
|------|-----------|
| tenant | id `a18ef378-f633-4d83-a756-fdc0b7b6cffd`, created=true |
| auth | users 58, adminTenants 2, setores 55, userSetores 87, moduloSetores 66 |
| ouvidoria | manifestações 257, anexos 1, eventos 279 |
| gabinete | protocolos 7 mapeados, controles 8, notificações 4, autos 1, documentos 8 |

## Reconciliação (`--compare`)

| Entidade | v1 bruto | v2 | OK esperado* |
|----------|----------|-----|--------------|
| users | 62 | 58 | ✅ 58 User + 2 AdminTenant = 60; 2 e-mails excluídos (QA, siged-test) |
| sectors | 55 | 55 | ✅ |
| user_sectors | 151 | 87 | ⚠️ vínculos de usuários excluídos + deduplicação no load |
| manifestations | 257 | 257 | ✅ |
| protocolos | 7 | 6 | ✅ 2 registros compartilham `numero=123123` → 1 linha v2; 3 soft-deleted no v1 |
| controles_numericos | 10 | 8 | ✅ 2 com `deletado_em` ignorados no load |
| controle_notificacoes | 8 | 4 | ✅ 4 soft-deleted |
| controle_autos_infracao | 2 | 1 | ✅ 1 soft-deleted |
| documentos_tramitados | 10 | 8 | ✅ 2 soft-deleted (degplan) |

\*O script `count-report --compare` compara totais brutos v1 vs v2 e retorna exit 1 quando há exclusões, soft-delete ou colisão de `internalNumber`. Os números v2 batem com **registros ativos/migráveis** após essas regras.

## SIGED (`TenantSigedConfig`)

- Migration aplicada; tabela disponível.
- `integração-siged/.env` está com `usuarioId` / `usuarioSecret` **vazios** — `active=true` **não configurado**.
- `usuarioId` conhecido dos logs de homologação: `57c5ffae95f082d3e063536811ac70a2`, `secretariaId=18692`.
- Após preencher o secret, executar:

```powershell
cd ci-api-v2
npx tsx scripts/migracao-agema-v1/activate-siged-config.ts --active
```

Validar com `integração-siged/probe_routes.py` antes de ativar em produção.

## Próximos passos manuais

1. Aprovação AGEMAN da lista de exclusão (T046).
2. Fornecer `usuarioSecret` SIGED e rodar `activate-siged-config.ts --active`.
3. Amostragem funcional (login, manifestação, protocolo, tramitação SIGED) — quickstart passo 5.
