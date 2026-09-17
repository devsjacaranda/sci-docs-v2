# Data Model: Relatório de Gestão da Ouvidoria

**Nota de escopo**: As duas primeiras entidades (`OuvidoriaPesquisaSatisfacaoPergunta`, `OuvidoriaPesquisaSatisfacaoLancamento`) são **compartilhadas com a spec 041** (Migração Histórico Ouvidoria). Este documento define o shape completo; ao planejar a 041, reutilizar o mesmo modelo sem redefinir — a 041 só faz `INSERT` em massa nas tabelas aqui descritas (com `origem = 'migracao'`), a 042 adiciona a tela de CRUD que também escreve nelas (com `origem = 'manual'`).

## Entidades persistidas (novas)

### `OuvidoriaPesquisaSatisfacaoPergunta` (catálogo, por tenant)

Segue o padrão de `OuvidoriaFormaAtendimento` (`ci-api-v2/prisma/schema/ouvidoria-catalog.prisma`).

| Campo | Tipo | Notas |
|---|---|---|
| `id` | `Int @id @default(autoincrement())` | |
| `tenantId` | `String` | isolamento multi-tenant |
| `codigo` | `String?` | slug estável (ex. `atendimento_geral`, `tempo_resposta`) — usado como chave lógica, não muda entre migrações |
| `nome` | `String` | rótulo exibido (ex. "Atendimento Geral") |
| `ordem` | `Int` | ordem de exibição no formulário/relatório |
| `ativo` | `Boolean @default(true)` | desativar sem apagar histórico |
| `deletedAt` | `DateTime?` | soft delete padrão do projeto |
| `createdAt` / `updatedAt` | `DateTime` | padrão |

**Regras de negócio**: catálogo é fixo por tenant — CRUD de perguntas é administrativo (seed/admin), **não** exposto na tela de lançamento do usuário final (Clarification 1). `@@unique([tenantId, codigo])`.

### `OuvidoriaPesquisaSatisfacaoLancamento` (agregado mensal)

| Campo | Tipo | Notas |
|---|---|---|
| `id` | `String @id @default(uuid())` | |
| `tenantId` | `String` | |
| `perguntaId` | `Int` | FK → `OuvidoriaPesquisaSatisfacaoPergunta` |
| `ano` | `Int` | ex. 2026 |
| `mes` | `Int` | 1–12 |
| `valor` | `Decimal` (ou `Float`) | média/percentual do mês para essa pergunta |
| `origem` | `String` (`'migracao' \| 'manual'`) | rastreabilidade — resolve FR-005/FR-009 da spec 041 e a Edge Case da 042 sobre conflito migração×lançamento manual |
| `criadoPorUserId` | `String?` | via `resolveUserTableId` (regra `admin-tenant-user-fk`) — null para lançamentos de migração |
| `createdAt` / `updatedAt` | `DateTime` | |

**Regras de negócio**:
- `@@unique([tenantId, perguntaId, ano, mes])` — resolve FR-006 (impede duplicidade; upsert em vez de insert).
- Se já existir um registro com `origem = 'migracao'` para o mês e o usuário lança manualmente, o **upsert sobrescreve o valor e atualiza `origem` para `'manual'`** — a última gravação vence (Clarification 5), sem tabela de histórico de versões.
- `valor` sem validação de range fixo na modelagem (perguntas podem ser % ou nota 0–10, dependendo do indicador) — validação de faixa (se necessária) fica no Zod schema por tipo de pergunta, não no banco.

## Entidades consultadas (já existentes — sem alteração de schema)

### `Manifestacao` (`ci-api-v2/prisma/schema/manifestacao.prisma`)

Campos usados pelas novas agregações: `tenantId`, `createdAt`, `type`, `addressId`, `deletedAt`. Nenhuma migração necessária — apenas novas queries de leitura.

### `Address` (`ci-api-v2/prisma/schema/address.prisma`)

Campos usados: `zone`, `neighborhood` (ambos `String?` livres). Registros sem esses campos preenchidos entram na categoria `"Não informado"` via `COALESCE(NULLIF(TRIM(campo), ''), 'Não informado')` — mesmo padrão já usado para `motivo` em `porMotivo`.

## Composições em tempo de consulta (não persistidas)

### `RelatorioGestaoOuvidoria` (view de API, agregando):

- KPIs (reuso de `GetDashboardAgregacoesRepository`: total, pendentes, respondidas, encerradas com/sem resolução)
- KPI "acumulado geral" (novo — mesmas contagens, sem filtro de ano)
- `atendimentosPorMes`, `resolutividade`, `porFormaAtendimento` (reuso direto do dashboard existente)
- `porTipoManifestacao` (novo — `GROUP BY type`, taxonomia `ManifestacaoStatus`/`ManifestacaoTipo` existente)
- `porZona` (novo — `GROUP BY zone` via `Address`, com `"Não informado"`)
- `porBairro` (novo — `GROUP BY neighborhood` via `Address`, com `"Não informado"`, ordenado por total desc)
- `pesquisaSatisfacao` (novo — `OuvidoriaPesquisaSatisfacaoLancamento` join `Pergunta`, por mês/ano filtrado)

Esta composição não é uma entidade Prisma — é o shape de retorno do endpoint `GET /ouvidoria/relatorio-gestao`, montado por um use-case orquestrador que chama os repositories acima (reusando o que já existe + os novos).

## Migração Prisma necessária

Uma migration única adiciona as duas tabelas novas (`OuvidoriaPesquisaSatisfacaoPergunta`, `OuvidoriaPesquisaSatisfacaoLancamento`) — nenhuma alteração em tabelas existentes (`Manifestacao`, `Address` permanecem inalteradas). Nome sugerido: `ouvidoria_pesquisa_satisfacao`.
