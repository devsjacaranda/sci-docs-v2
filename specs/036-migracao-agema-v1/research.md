# Research — Migração de Dados v1 → v2 (Tenant AGEMAN)

## R1. Como extrair os dados do v1 (dump `.sql` vs. MySQL vivo)

**Decision**: Restaurar o dump `controleinterno_prod_ci (13).sql` em uma instância MySQL descartável (container Docker local/CI) e extrair via `mysql2` com queries `SELECT ... WHERE tenantId = '00000000-0000-0000-0000-000000000002'`.

**Rationale**: O dump é MySQL (sintaxe `` ` ``, `ENGINE=InnoDB`, `CHECK (json_valid(...))`, `tinyint(1)`). Parsear o `.sql` diretamente com regex é frágil — há JSON escapado dentro de strings, aspas simples em texto livre (`Rômulo`, `d'água`, `Q&A`) e colunas `longtext` com payloads grandes. Restaurar em um MySQL real e consultar via SQL é robusto, reaproveita índices/tipagem e permite reconciliação por `COUNT(*)` diretamente na fonte.

**Alternatives considered**:
- Parsear o `.sql` com regex/state machine — rejeitado: alto risco de corromper texto livre com aspas/escapes, sem ganho real de simplicidade.
- Conectar direto ao MySQL de produção do v1 — preferível se/quando houver acesso de rede liberado; o plano usa o dump como fonte por ser o que está disponível hoje, mas o script de extração deve aceitar qualquer `DATABASE_URL` MySQL (dump restaurado ou produção), sem acoplamento ao arquivo específico.

## R2. Tradução do modelo de papéis/permissões do v1 para o v2

**Decision**: Mapear por **acesso efetivo**, não por nome de papel:
- `users.isSuperAdmin = 1` (AGEMAN) → registro em `AdminTenant` (não em `User`), reaproveitando `resolveUserTableId`/padrão já documentado na regra `admin-tenant-user-fk`.
- Demais usuários → `User` com `role = user` por padrão; `chefe_setor` só é aplicado se houver evidência de chefia (ver R5 — hoje não há).
- `user_sectors` (v1) → `UserSetor` (v2), 1:1 direto.
- `roles`/`permissions`/`role_permissions`/`user_roles`/`user_permissions` (v1, RBAC granular) **não têm equivalente 1:1** no v2 (que usa `ModuloSetor` + `SetorTela`/`UserTelaOverride` por setor). Esses registros **não são migrados como estão**; servem apenas de referência para, na fase de `tasks`, decidir manualmente quais módulos cada setor da AGEMAN deve ter liberados por padrão (`ModuloSetor`), já que o v1 não modela "módulo por setor" da mesma forma.

**Rationale**: Tentar replicar nomes de papéis do v1 (`Role-Total-Permissoes-...`, `PRESTACAO_CONTAS_ADMIN` etc.) no v2 criaria conceitos inexistentes no domínio v2 e violaria a Constitution V (clean code / modelo do domínio v2). Preservar acesso efetivo é testável e mensurável (SC-005).

**Alternatives considered**: Criar uma tabela de compatibilidade "role v1 → permissão v2" genérica — rejeitado por complexidade desnecessária para um único tenant pequeno (~62 usuários); mapeamento direto e documentado é mais simples de auditar.

## R3. Contexto de tenant no script de migração (multi-tenant, Constitution IV)

**Decision**: O script de migração **não** usa o middleware `AsyncLocalStorage` de request HTTP (que só existe no ciclo de requisição da API). Segue o padrão já existente em `ci-api-v2/prisma/seed.ts`: instancia o Prisma Client diretamente (`createPrismaClient()`) e passa `tenantId` explicitamente em todo `create`/`upsert`.

**Rationale**: Consistente com o único precedente real do repositório para escrita em lote fora do ciclo HTTP.

## R4. Ambiente e credenciais da integração SIGED

**Decision**: Implementar o módulo `siged` com a URL base **configurável por variável de ambiente** (`SIGED_BASE_URL`), inicializando para o ambiente de homologação hoje documentado (`https://siged-integracao-api-tst.manaus.am.gov.br`, conforme `integração-siged/openapi.json` e `auth_token.py`). Credenciais (`usuarioId`/`usuarioSecret`) armazenadas por tenant (ver Data Model), não em `.env` global.

**Bloqueio externo conhecido**: `integração-siged/.env` está com `usuarioId`/`usuarioSecret` vazios — a equipe SIGED precisa fornecer credenciais válidas (e confirmar se o endpoint de produção é diferente do de homologação `-tst`) antes de ativar a consulta viva além de testes com mocks. Isso **não bloqueia** o desenvolvimento do módulo (que pode ser construído e testado com mocks do contrato OpenAPI), mas bloqueia o go-live real da User Story 4.

**Rationale**: Evita hardcode de ambiente; permite trocar homologação → produção sem deploy de código.

## R5. Ausência de "chefe de setor" como coluna no v1

**Finding**: A tabela `sectors` do v1 não possui nenhuma coluna equivalente a `chefeUserId`/responsável (campos existentes: `nome`, `ativo`, `descricao`, `nome_completo`, `sigla`, `icon`, `is_inbox_enabled`, `order_in_sidebar`, `slug`). A tabela `committee_members` é um conceito diferente (comitê de aprovação financeira, não chefia de setor).

**Decision**: Nenhum `Setor.chefeUserId` é preenchido automaticamente pela migração — todos os setores migram com `chefeUserId = null`. A definição de chefe por setor da AGEMAN é uma ação manual pós-migração pelo administrador da instituição no v2 (fora do escopo desta migração de dados).

**Impacto na spec**: A Acceptance Scenario 4 da User Story 1 ("setor com chefe definido no v1 → mesmo usuário aparece como chefe no v2") **não é satisfazível a partir dos dados do v1** tal como existem hoje. Deve ser removida/ajustada em `spec.md` antes de `/speckit-tasks`, ou tratada como fora do escopo de dados (decisão registrada aqui; recomenda-se atualizar a spec).

## R6. Curadoria da lista de exclusão de dados de teste/QA (FR-024)

**Decision**: Lista de exclusão **curada manualmente** em `ci-api-v2/scripts/migracao-agema-v1/mappers/exclusion-list.ts`, revisada por alguém da equipe AGEMAN/CI antes da execução em produção. Heurísticas automáticas (regex em e-mail/conteúdo) são usadas apenas para **gerar a lista candidata** para revisão humana — nunca para excluir automaticamente sem aprovação.

**Candidatos identificados na exploração do dump** (para a lista inicial, sujeitos a confirmação): usuários com e-mail contendo `qa@`, `teste@teste.com`, `usuario.especial.*@ageman`, `siged-ageman-test@controle-interno.test`; registros de `controle_autos_infracao`/`protocolos` com conteúdo literal "teste"/"asdasd"/"sdaasd".

**Rationale**: Decisão do usuário foi excluir dados de teste — mas fazer isso de forma automática e não supervisionada arrisca excluir dados reais com nomes curtos/incomuns ou manter lixo por escapar do regex. Curadoria manual com lista candidata gerada por heurística equilibra segurança e esforço.

## R7. Armazenamento de arquivos anexados (FR-009)

**Finding**: Anexos do v1 (`manifestation_attachments`, `demandas_refact_attachments` etc.) referenciam caminhos de storage prefixados por `tenantId` (ex.: `00000000-0000-0000-0000-000000000002/demandas-refact-message/...`). O v2 usa `StorageService`/`storage.port.ts` em `ci-api-v2/src/modules/shared/storage/`.

**Decision**: Migração de arquivo físico é uma cópia bucket-a-bucket (ou storage-a-storage) por `storageKey`, reaproveitando o mesmo prefixo de tenant quando o backend de storage do v2 for compatível; detalhamento do mecanismo exato (S3/local) fica para `tasks.md`, pois depende de qual `StorageService` está configurado em produção para o v2.
