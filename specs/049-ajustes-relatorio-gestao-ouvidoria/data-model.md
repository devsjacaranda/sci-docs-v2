# Data Model: Ajustes na Pesquisa de Satisfação e no Relatório de Gestão da Ouvidoria

## Entidade alterada

### `OuvidoriaPesquisaSatisfacaoLancamento` (alteração de colunas — mesma tabela da spec 042)

| Campo | Antes (spec 042) | Depois (esta feature) |
|---|---|---|
| `valor` | `Decimal @db.Decimal(10, 2)` — score/percentual único | **removido** |
| `consultados` | — | **novo** `Int?` — quantidade de pessoas consultadas; puramente informativo, sem validação cruzada com Sim/Não (Edge Case do spec.md) |
| `respostasSim` | — | **novo** `Int @default(0)` — quantidade de respostas "Sim" |
| `respostasNao` | — | **novo** `Int @default(0)` — quantidade de respostas "Não" |

Campos inalterados: `id`, `tenantId`, `perguntaId` (FK → `OuvidoriaPesquisaSatisfacaoPergunta`, catálogo fixo por tenant — inalterado por esta feature), `ano`, `mes`, `origem` (`'migracao' \| 'manual'`), `criadoPorUserId`, `createdAt`, `updatedAt`. Constraint inalterada: `@@unique([tenantId, perguntaId, ano, mes])` (upsert — "última gravação vence").

**Campo derivado (não persistido)**: `percentual = respostasSim / (respostasSim + respostasNao)`, calculado no mapper/use-case de leitura; quando `respostasSim + respostasNao === 0`, o campo derivado é `null` (UI exibe "sem dados" — FR-002).

**Migration**: `DROP COLUMN "valor"`, `ADD COLUMN "consultados" INTEGER`, `ADD COLUMN "respostasSim" INTEGER NOT NULL DEFAULT 0`, `ADD COLUMN "respostasNao" INTEGER NOT NULL DEFAULT 0` na tabela `OuvidoriaPesquisaSatisfacaoLancamento`. Descarta o único registro manual já existente no modelo antigo (dado de transição, ver spec.md § Assumptions) — sem script de backfill (não há dado real a preservar).

## Entidades novas

### `OuvidoriaEvento` (catálogo, por tenant — CRUD pelo usuário final)

Segue o padrão de `OuvidoriaFormaAtendimento` (mesmo arquivo `ouvidoria-catalog.prisma`), mas com CRUD completo exposto ao usuário do módulo Ouvidoria (não é seed/admin-only, ao contrário do catálogo de perguntas de satisfação — decisão tomada em `/speckit-plan`, resolvendo a contradição do FR-008 original).

| Campo | Tipo | Notas |
|---|---|---|
| `id` | `Int @id @default(autoincrement())` | |
| `tenantId` | `String` | isolamento multi-tenant |
| `nome` | `String` | nome do evento (ex. "Manaus + Cidadã") |
| `ativo` | `Boolean @default(true)` | inativar sem apagar histórico de participações |
| `deletedAt` | `DateTime?` | soft delete padrão do projeto |
| `createdAt` / `updatedAt` | `DateTime` | padrão |

**Regras de negócio**: `@@unique([tenantId, nome])` — evita evento duplicado por nome no mesmo tenant. Criação/edição/inativação seguem o mesmo padrão de `formas-atendimento` (`POST /ouvidoria/eventos`, `PATCH /ouvidoria/eventos/:id`, `POST /ouvidoria/eventos/:id/inativar`), mesma autorização (`@RequireModulo('ouvidoria')`, sem papel adicional — FR-012).

### `OuvidoriaEventoParticipacaoLancamento` (lançamento mensal, upsert)

Segue o padrão de `OuvidoriaPesquisaSatisfacaoLancamento`.

| Campo | Tipo | Notas |
|---|---|---|
| `id` | `String @id @default(uuid())` | |
| `tenantId` | `String` | |
| `eventoId` | `Int` | FK → `OuvidoriaEvento` |
| `ano` | `Int` | |
| `mes` | `Int` | 1–12 |
| `participacoes` | `Int` | quantidade de participações naquele mês |
| `criadoPorUserId` | `String?` | via `resolveUserTableId` (regra `admin-tenant-user-fk`) |
| `createdAt` / `updatedAt` | `DateTime` | |

**Regras de negócio**: `@@unique([tenantId, eventoId, ano, mes])` — upsert; relançar o mesmo evento/mês/ano **sobrescreve** (nunca soma), decisão tomada em `/speckit-clarify`. `@@index([tenantId, ano])`.

## Entidades consultadas (já existentes — sem alteração de schema)

### `Manifestacao`

Campo adicional usado pela nova agregação de Orientações/Encaminhamentos (US3): `serviceMode` (já existente, rotulado "Canal de atendimento" na ficha/PDF individual — `documento-header.ts`). Campos já usados por outras agregações (`createdAt`, `programa`, `motivo`) permanecem os mesmos, sem alteração de schema.

## Composições em tempo de consulta (não persistidas)

### `RelatorioGestaoOuvidoria` (view de API — alterações no shape existente)

- `pesquisaSatisfacao`: cada linha passa a ter `{ ano, mes, perguntaId, perguntaNome, consultados, respostasSim, respostasNao, percentual }` em vez de `{ ano, mes, perguntaId, perguntaNome, valor }`.
- `orientacoesEncaminhamentos` *(novo bloco)*: `Array<{ ano: number; concessao: string; canal: string; total: number }>` — histórico multi-ano completo (não respeita o filtro `year`/`month` do restante do relatório, ver `research.md` §3). `concessao` reaproveita o mesmo mapeamento de `programa` já usado em `porMotivo`; `canal` vem de `serviceMode` (fallback `'Não informado'` quando ausente, mesmo padrão de "Não informado" já usado em zona/bairro).
- `participacaoEventos` *(novo bloco)*: `Array<{ evento: string; ano: number; mes: number; participacoes: number }>` — todos os meses (1–12) preenchidos com zero quando não há lançamento, mesmo padrão `fill12Months` já usado no dashboard existente.

Nenhuma dessas composições é uma entidade Prisma — são o shape de retorno do endpoint `GET /ouvidoria/relatorio-gestao`, já existente, apenas com blocos alterados/adicionados.

## Migrações Prisma necessárias

Uma migration única cobre as três mudanças de schema:
1. Alteração de colunas em `OuvidoriaPesquisaSatisfacaoLancamento` (remove `valor`, adiciona `consultados`/`respostasSim`/`respostasNao`).
2. Criação da tabela `OuvidoriaEvento`.
3. Criação da tabela `OuvidoriaEventoParticipacaoLancamento`.

Nome sugerido: `ouvidoria_ajustes_satisfacao_eventos`. Nenhuma alteração em `Manifestacao`, `Address` ou qualquer tabela fora do domínio `ouvidoria-catalog.prisma`.
