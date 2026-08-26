# Quickstart — Validação da Migração AGEMAN v1 → v2

## Pré-requisitos

- Docker (para restaurar o dump MySQL v1 localmente) ou acesso a uma instância MySQL com o dump `controleinterno_prod_ci (13).sql` já restaurado
- `ci-api-v2` configurado localmente (`npm install`, `.env` com `DATABASE_URL` do PostgreSQL v2 de teste/staging)
- Variável `MYSQL_V1_URL` apontando para a instância MySQL de origem (dump restaurado)
- Lista de exclusão de teste/QA revisada e aprovada (`scripts/migracao-agema-v1/mappers/exclusion-list.ts`) — **não executar em staging/produção sem essa lista aprovada** (FR-024)

## Passo 1 — Restaurar a fonte v1

```powershell
docker run --name mysql-v1-ageman -e MYSQL_ROOT_PASSWORD=devpass -p 3307:3306 -d mysql:8
# aguardar o container subir, depois:
docker exec -i mysql-v1-ageman mysql -uroot -pdevpass -e "CREATE DATABASE controleinterno_prod_ci"
Get-Content "controleinterno_prod_ci (13).sql" | docker exec -i mysql-v1-ageman mysql -uroot -pdevpass controleinterno_prod_ci
```

## Passo 2 — Rodar o relatório de contagem (antes de migrar)

```powershell
cd ci-api-v2
npx tsx scripts/migracao-agema-v1/reconciliation/count-report.ts --source-only
```

Saída esperada: contagem por entidade (usuários, setores, manifestações, protocolos, controles etc.) para o tenant AGEMAN no v1, já subtraindo os ids da lista de exclusão — esse número é o "esperado" para conferência depois (SC-006).

## Passo 3 — Executar a migração (staging primeiro, sempre)

```powershell
cd ci-api-v2
npx tsx scripts/migracao-agema-v1/run-migration.ts --dry-run   # valida mapeamentos sem escrever no v2
npx tsx scripts/migracao-agema-v1/run-migration.ts             # executa de fato (idempotente — pode re-rodar)
```

Ordem interna executada pelo orquestrador: Tenant → Auth (User/Setor/UserSetor/AdminTenant) → Ouvidoria (Manifestacao + Anexo + Evento) → Gabinete (Protocolo → Demanda → Controles/Documentos Tramitados).

## Passo 4 — Reconciliar (depois de migrar)

```powershell
npx tsx scripts/migracao-agema-v1/reconciliation/count-report.ts --compare
```

Critério de sucesso (SC-006): contagem v2 = contagem v1 esperada (Passo 2) para cada entidade, sem diferença.

## Passo 5 — Validar cenários funcionais (amostragem manual)

1. Login no v2 com e-mail/senha de um usuário real da AGEMAN migrado (US1, SC-001).
2. Buscar uma manifestação pelo número de protocolo original e confirmar anexo baixável (US2, SC-003).
3. Abrir um protocolo do Gabinete com número interno conhecido e confirmar controles numéricos/documentos tramitados vinculados (US3, SC-004).
4. Para um protocolo com número SIGED preenchido, chamar `GET /gabinete/protocolos/:id/tramitacoes-siged` e comparar com a consulta equivalente feita com `integração-siged/probe_routes.py` contra o mesmo `protocoloId` (US4, SC-007) — **requer credenciais SIGED reais configuradas em `TenantSigedConfig`**, ver research.md R4.
5. Para um protocolo sem número SIGED, confirmar que a resposta é `{ "disponivel": false, "motivo": "sem_numero_siged" }` sem erro.

## Ativar integração SIGED (pós-migração)

1. Aplicar migration `20260810180000_tenant_siged_config` (`npm run prisma:migrate` em staging/produção).
2. Inserir registro em `TenantSigedConfig` para o tenant AGEMAN (`secretariaId = 18692`, credenciais M2M fornecidas pela equipe SIGED).
3. Definir `active = true` somente após validar credenciais com `integração-siged/probe_routes.py`.
4. Endpoint exposto: `GET /gabinete/protocolos/:protocoloId/tramitacoes-siged` (requer JWT + módulo gabinete).
5. UI: painel "Tramitação SIGED" na página de detalhe do protocolo (`GabineteProtocoloDetailPage`).

## Testes automatizados (TDD — antes da implementação)

```powershell
cd ci-api-v2
npm test -- --testPathPatterns=migracao-agema-v1
npm test -- --testPathPatterns=siged
```

Ver `research.md` para decisões de fonte de dados, mapeamento de papéis, contexto de tenant no script e ambiente/credenciais SIGED. Ver `data-model.md` para o mapeamento completo de campos v1 → v2 e `contracts/siged-integration.md` para o contrato HTTP consumido/exposto.
