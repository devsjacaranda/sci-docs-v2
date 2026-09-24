# Data Model: Forma de atendimento no Relatório de Gestão

**Feature**: 050-relatorio-gestao-forma-atendimento-ageman

## Alterações de schema

**Nenhuma.** Migration Prisma não necessária.

## Entidades existentes (somente leitura)

### `Manifestacao` (`manifestacao.prisma`)

| Campo | Papel nesta feature |
|-------|---------------------|
| `serviceMode` | **Dimensão de agregação** — forma/canal informada na manifestação |
| `origem` | Proveniência (`interna`/`publica`) — **não** usar no bloco Forma de atendimento |
| `dadosAdicionais` JSON | Legado; chave `formaAtendimento` **não** populada no AGEMAN pós-migração |
| `createdAt` | Eixo temporal (`EXTRACT(MONTH FROM "createdAt")`) — inalterado |
| `tenantId`, `deletedAt` | Filtros padrão — inalterados |

### `OuvidoriaFormaAtendimento` (`ouvidoria-catalog.prisma`)

Catálogo por tenant (`descricao`, `codigo`, `ordem`). A UI grava `descricao` em `Manifestacao.serviceMode`. A agregação agrupa pelo **valor armazenado**, não por JOIN ao catálogo (evita perder valores históricos fora do catálogo).

## Shape de resposta (inalterado)

```typescript
porFormaAtendimento: Array<{ month: number; forma: string; total: number }>;
```

**Mudança semântica**: `forma` passa a conter descrições de `serviceMode` ou `'Não informado'`, em vez de `interna`/`sem_canal`.

## Rollup AGEMAN (P2, opcional — camada de apresentação)

Mapa estático documentado em `research.md` §D2; implementação sugerida como função pura sem persistência:

```typescript
type BucketPlanilhaAgeman =
  | 'PRESENCIAL'
  | 'CALL CENTER'
  | 'CELULAR'
  | 'E-MAIL'
  | 'WHATSAPP'
  | 'FALA.BR'
  | 'OUTROS';
```

Não altera linhas armazenadas em banco.
