# Data Model — 039 Módulo Diretor

**Spec**: [spec.md](./spec.md) · **Research**: [research.md](./research.md)

Nenhuma entidade de persistência nova. A feature **lê** modelos existentes e adiciona um índice.

Convenções: `tenantId` via AsyncLocalStorage; FK para `User` pode ser nula (admin_tenant / admin_saas) — ver `resolveUserTableId`.

## 1. Existentes (leitura)

### `Manifestacao` — `prisma/schema/manifestacao.prisma`

Fonte dos 6 KPIs de Ouvidoria. Recorte por `createdAt` no intervalo resolvido (mês calendário **ou** últimos N dias). Status usados nas fórmulas atuais (sem mudança):

| KPI | Status |
| --- | --- |
| total | todos no intervalo |
| pendentes | `draft` \| `in_review` \| `forwarding` |
| emAnalise | `in_review` |
| respondidas | `answered` |
| encerradasComResolucao | `closed` |
| encerradasSemResolucao | `closed_unresolved` |

### `ManifestacaoEvento`

Ações de usuário do bloco Ouvidoria.

| Campo | Uso |
| --- | --- |
| `tipo` | `registration` \| `forwarding` \| `response` \| `closure` \| `note` |
| `autorUserId` | filtro de pessoa (nullable) |
| `titulo` / `descricao` | lista |
| `createdAt` | recorte do bloco |
| `manifestacaoId` | join para `protocol` / `subject` |

Índice existente: `[manifestacaoId, createdAt]`. Query diretor filtra `createdAt` + `autorUserId` + `tenantId` (extension).

### `DiagnosticoProcessoMarcador` — `diagnostico.prisma`

Ações locais + KPI `marcadoresNoPeriodo`.

| Campo | Uso |
| --- | --- |
| `userId` | autor (linha em `User`) |
| `numeroProcesso` | alvo |
| `createdAt` | recorte |

Unique `(tenantId, userId, numeroProcesso)`.

### `DocumentoInstitucional` — `documento-institucional.prisma`

KPI `documentosNoPeriodo`. Recorte por `createdAt` (ou `reservadoEm` se `createdAt` ausente — mesmo critério no repository). **Não** entra na lista de ações v1.

### Processos Diagnóstico (MySQL externo)

Não é modelo Prisma. Alimenta só `estoque` (sem recorte de data). Sem persistência nova.

### `AuditLog` — `audit-log.prisma`

Auditoria geral.

| Campo | Semântica atual |
| --- | --- |
| `userId` | FK `User` se role ∈ {user, chefe_setor, admin_plataforma}; senão null |
| `action` | método HTTP (`POST`/`PUT`/`PATCH`/`DELETE`) |
| `entity` | path da URL sem query |
| `entityId` | não preenchido pelo interceptor (não corrigir nesta feature) |
| `payload` | body; pode conter `actorId` + `actorRole` |
| `createdAt` | recorte ano/mês **global** |

### `User` / `AdminTenant` / `AdminPlataforma`

Lookup de e-mail no guard e resolução de `actor` nas listas.

## 2. Migration (additive)

```prisma
model AuditLog {
  // ... campos inalterados
  @@index([tenantId])
  @@index([tenantId, createdAt])  // NOVO
}
```

Sem DROP, sem backfill.

## 3. Modelos de query (não persistidos)

### `DiretorPeriod`

Resolvido no server e no client pela mesma regra:

| Input | Output |
| --- | --- |
| `presetDays` ∈ {3, 7} | `from = now - N dias`, `to = now` (UTC) |
| senão `year` + `month` | início/fim do mês UTC |
| senão | mês/ano correntes UTC |

`AuditLog` **nunca** recebe `presetDays`.

### `DiretorKpisOuvidoria`

Os 6 números do dashboard atual + `period: DiretorPeriod`.

### `DiretorKpisDiagnostico`

```text
estoque: { total, sentencas, peticoesIniciais, procedencias } | null
estoqueErro: boolean
estoqueIgnoraPeriodo: true
locais: { marcadoresNoPeriodo, documentosNoPeriodo }
period: DiretorPeriod   // aplica-se só a locais
```

### `DiretorAcao`

União de leitura (não é tabela):

| Campo | Ouvidoria | Diagnóstico |
| --- | --- | --- |
| `id` | `ManifestacaoEvento.id` | `DiagnosticoProcessoMarcador.id` |
| `occurredAt` | `createdAt` | `createdAt` |
| `actor` | User ou null | User |
| `kind` | `tipo` do evento | `marcador` |
| `summary` | `titulo` | `Marcou processo {numero}` |
| `ref` | protocol/subject | `numeroProcesso` |

### `DiretorAuditEvent`

| Campo | Origem |
| --- | --- |
| `id` / `occurredAt` / `action` / `entity` | `AuditLog` |
| `actor` | User **ou** `{ id: actorId, role: actorRole, name: null }` |

## 4. Validação (borda Zod)

Ver [contracts/rest-api-diretor.md](./contracts/rest-api-diretor.md). Resumo:

- `year`: 2000–2100; `month`: 1–12
- `presetDays`: 3 \| 7
- `page` ≥ 1; `limit` 1–50 default 20
- `autorUserId`: UUID opcional
- `superRefine`: `presetDays` e calendário podem coexistir no query string; se `presetDays` presente, calendário é ignorado (não é erro)

## 5. Transições de estado

Nenhuma. Feature 100% leitura — nenhum write em Manifestacao, Marcador, Documento ou AuditLog a partir de `/diretor`.
