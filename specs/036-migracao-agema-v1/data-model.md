# Data Model — Migração de Dados v1 → v2 (Tenant AGEMAN)

Fonte: tabelas MySQL do v1 (`controleinterno_prod_ci (13).sql`), filtradas por `tenant_id = '00000000-0000-0000-0000-000000000002'`.
Destino: modelos Prisma do v2 em `ci-api-v2/prisma/schema/*.prisma`.

Convenção de chave: toda entidade v2 usa `id` (uuid) próprio — o `id` do v1 **não é reaproveitado como PK** no v2 (evita colisão entre tenants/ambientes), mas é preservado em um campo auxiliar (`legacyV1Id`, ver Nota de Rastreabilidade) para permitir reconciliação/rollback.

## Nota de rastreabilidade

Todas as tabelas migradas armazenam, durante a migração, um mapa `v1Id → v2Id` (arquivo JSON de rastreabilidade em `scripts/migracao-agema-v1/reconciliation/id-map.<entidade>.json`, não versionado — contém apenas UUIDs, sem dado sensível). Esse mapa é a base para: (a) resolver FKs entre entidades na ordem correta de carga, (b) permitir re-execução idempotente (buscar `id` v2 já criado antes de gerar um novo), (c) o relatório de reconciliação (SC-006).

## 1. Tenant

| v1 (`tenants`) | v2 (`Tenant`) | Regra |
|---|---|---|
| `id` = `...002` | novo `id` (uuid) | Mapeado via id-map; `slug` gerado a partir do nome (`ageman`) — não existe no v1 |
| `name` | `name` | Cópia direta |
| `ativo` | `active` | Cópia direta |
| `createdAt`/`updatedAt` | `createdAt`/`updatedAt` | Cópia direta |
| (branding/menu — tabelas de config específicas do v1, se existirem) | `avatarStorageKey`/`bannerStorageKey` | Copiar arquivo + metadado (ver Ouvidoria/Anexos) |

**Pré-condição de carga**: é o primeiro registro migrado (todas as outras entidades dependem do `tenantId` v2 gerado aqui).

## 2. Auth — Usuário, Setor, AdminTenant

| v1 | v2 | Regra |
|---|---|---|
| `users` (isSuperAdmin=0) | `User` | `email`, `name`, `cargo`(se existir), `passwordHash` copiados como estão (bcrypt); `role = user` por padrão (ver R2 em research.md) |
| `users` (isSuperAdmin=1) | `AdminTenant` | Não cria linha em `User`; `email`/`name`/`passwordHash` copiados; qualquer FK que apontaria para este usuário usa `resolveUserTableId` (regra `admin-tenant-user-fk`) → `undefined` |
| `sectors` | `Setor` | `name`, `sigla`, `deletedAt` copiados; **`chefeUserId` fica `null`** — v1 não tem coluna de chefia (ver research.md R5); atribuição de chefe é ação manual pós-migração |
| `user_sectors` | `UserSetor` | Par `(userId, setorId)` recriado com os ids v2 mapeados (id-map) |
| `roles`/`permissions`/`role_permissions`/`user_roles`/`user_permissions` | `ModuloSetor` (por setor) + `SetorTela`/`UserTelaOverride` (se necessário) | **Não é cópia 1:1** — usado apenas como insumo manual em `tasks.md` para decidir quais `ModuloSlug` cada `Setor` da AGEMAN recebe por padrão (ver research.md R2) |

**Validações**:
- `@@unique([tenantId, email])` em `User` — se dois registros v1 tiverem mesmo e-mail (não deveria, mas há colisão possível com contas de teste), a curadoria de exclusão (FR-024) deve resolver antes da carga.
- E-mail duplicado **entre tenants diferentes** não é conflito (unicidade é por tenant no v2) — não precisa de tratamento especial.

## 3. Ouvidoria — Manifestação

| v1 | v2 | Regra |
|---|---|---|
| `manifestations` | `Manifestacao` | `protocol`→`protocol` (preservar número original, `@@unique([tenantId, protocol])`); `type`, `status`, `priority`, `category`, `subject`, `description` mapeados para os enums v2 (`ManifestacaoTipo`/`Status`/`Priority` — tabela de conversão de valores em `tasks.md`); `isAnonymous` preservado; se `isAnonymous = true`, campos `requesterFullName`/`requesterDocument`/telefones **não são migrados** (ficam `null`) mesmo que existam no v1, para reforçar o anonimato no v2 (Edge Case da spec) |
| `manifestation_addresses` | `Address` + `Manifestacao.addressId` | Copiado quando existir; `Address` já é tabela compartilhada no v2 |
| `manifestation_attachments` | `ManifestacaoAnexo` | `fileName`, `mimeType`, `sizeBytes` copiados; `storageKey` **novo** (arquivo físico copiado para o storage do v2 — ver research.md R7); `uploadedByUserId` resolvido via id-map (ou `resolveUserTableId` se o autor era admin/isSuperAdmin) |
| (eventos derivados do fluxo de tramitação/resposta em `documentos_tramitados_ouvidoria` e histórico de status) | `ManifestacaoEvento` | Reconstituído em ordem cronológica (`createdAt` ascendente) a partir dos registros de mudança de status/encaminhamento disponíveis no v1; tipo mapeado para `ManifestacaoEventoTipo` (`registration`/`forwarding`/`response`/`closure`/`note`) |

## 4. Gabinete — Protocolo, Controles, Documentos Tramitados

| v1 | v2 | Regra |
|---|---|---|
| `protocolos` | `CabinetProtocolo` | `numero`→`internalNumber`, `numero_siged`→`sigedNumber`, `remetente`→`sender`, `data_protocolo`→`protocolDate`, `assunto`→`subject`, `tipo_documento`→`documentType`; `entryMode` derivado (se havia indicação de origem SIGED no v1 → `siged`; senão `in_person`/`email` conforme dado disponível — default `in_person` quando ambíguo) |
| `demandas` | `CabinetDemanda` | **0 registros esperados para a AGEMAN** (tabela `demandas` do v1 está vazia/não usada por este tenant — confirmado na exploração do dump); script deve tratar isso como caso válido (zero migrados), não como erro |
| `controle_numerico_oficio(_circular)`, `controle_numerico_portaria`, `controle_numerico_memorando(_circular)`, `controle_numerico_resolucao` | `CabinetControleNumerico` | Uma tabela v1 por `documentType` → uma linha v2 com `documentType` no enum `CabinetControleNumericoTipo` correspondente; `cabinetId`/`protocoloId` resolvidos via id-map (podem ficar `null` se soltos, conforme Edge Case da spec) |
| `controle_notificacoes` | `CabinetControleNotificacao` | Campos de prazo (`notificationTerm`, `deadline`, `dueDate`), `response`, `situation` copiados diretamente |
| `controle_autos_infracao` | `CabinetControleAutoInfracao` | `amount` copiado como `Decimal(15,2)`; demais campos de texto copiados diretamente |
| `documentos_tramitados_ascom/ci/cmr/deae/deer/degplan/deip/dejur/deres/deret/gdp/governanca` | `CabinetDocumentoTramitado` | Uma tabela v1 por setor → uma linha v2 com `sectorId` = id do `Setor` v2 correspondente (mapear sigla/tabela → `Setor` migrado na Fase Auth); `sigedNumber` preservado quando presente |

**Ordem de carga obrigatória** (por FKs): Tenant → Auth (User/Setor/UserSetor/AdminTenant) → Ouvidoria (Manifestacao, necessária antes de Gabinete pois `CabinetDemanda.manifestationId` referencia `Manifestacao`) → Gabinete (Protocolo → Demanda → Controles/Documentos, nessa ordem interna).

## 5. SIGED — Configuração de Credenciais por Tenant (novo, não existe hoje)

Novo modelo Prisma (`ci-api-v2/prisma/schema/siged.prisma`), necessário para a consulta viva (FR-020..023):

```prisma
model TenantSigedConfig {
  id                 String    @id @default(uuid())
  tenantId           String    @unique
  secretariaId       String    // "18692" para AGEMAN, confirmado pela equipe SIGED
  usuarioId          String
  usuarioSecretHash  String    // nunca texto puro — mesmo padrão de segredo usado para outros secrets do projeto (detalhar em tasks.md)
  baseUrl            String    @default("https://siged-integracao-api-tst.manaus.am.gov.br")
  active             Boolean   @default(false) // true somente após credenciais reais confirmadas (ver research.md R4)
  createdAt          DateTime  @default(now())
  updatedAt          DateTime  @updatedAt

  tenant Tenant @relation(fields: [tenantId], references: [id])
}
```

**Regras**:
- `active = false` por padrão — a migração de dados **não** ativa a consulta viva automaticamente; alguém precisa confirmar credenciais reais e marcar `active = true` (dependência externa, ver research.md R4).
- Nenhum dado de tramitação SIGED é persistido permanentemente no v2 — é sempre consulta ao vivo (FR-020), renderizada e descartada; não há tabela `SigedTramitacao` no v2.
- `secretariaId = "18692"` é um valor confirmado pela equipe SIGED para AGEMAN (`integração-siged/probe_routes.py`), não descoberto automaticamente — deve ser inserido manualmente no `TenantSigedConfig` no momento do cadastro.

## 6. Exclusão de dados de teste/QA (FR-024/FR-025)

Estrutura de suporte (não é uma entidade v2, é um artefato do próprio script de migração):

```typescript
// scripts/migracao-agema-v1/mappers/exclusion-list.ts
export const EXCLUDED_USER_EMAILS: readonly string[] = [ /* curada e aprovada pela AGEMAN */ ];
export const EXCLUDED_RECORD_IDS: Readonly<Record<string, readonly string[]>> = {
  manifestations: [ /* ids v1 */ ],
  protocolos: [ /* ids v1 */ ],
  // ...
};
```

**Regra de integridade (FR-025)**: se um registro real (não excluído) referencia um `createdByUserId`/`uploadedByUserId` que **está** na lista de exclusão, a migração substitui essa FK por `null` (todas as FKs relevantes já são `String?` no v2, conforme regra `admin-tenant-user-fk`) em vez de excluir o registro real ou falhar a carga. Isso é validado por teste de contrato (fixture: registro real referenciando autor excluído → migra com `createdByUserId = null`, sem erro).
