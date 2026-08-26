# Contrato de API: Desentranhamento de Documentos em Tramitação

Base: `ci-api-v2/src/modules/tramitacao/tramitacao.controller.ts` (novas rotas, mesmo controller, guard `@RequireModulo('tramitacao')` já aplicado à classe).

Todas as rotas exigem tenant resolvido (`X-Tenant-ID` via `AsyncLocalStorage`, já tratado pelo pipeline existente) e usuário autenticado.

## 1. Solicitar desentranhamento

```
POST /tramitacao/demandas/:id/anexos/:anexoId/desentranhamento
```

**Body** (`RequestDesentranhamentoBody`, Zod):

```ts
{
  reason?: string; // opcional, texto livre, max 1000 chars
}
```

**Regras**: ver `data-model.md` → Validações de negócio (1–5).

**Responses**:
- `201 Created` → `{ solicitacaoId: string; status: 'pending'; direction: 'author_requests' | 'recipient_requests' }`
- `404 Not Found` → demanda ou anexo não encontrados
- `409 Conflict` → `ANEXO_ALREADY_DESENTRANHADO` | `PENDING_REQUEST_EXISTS`
- `422 Unprocessable Entity` → `NO_APPROVER_AVAILABLE` (FR-005)
- `403 Forbidden` → demanda arquivada (FR-015) ou usuário sem acesso à demanda

## 2. Aprovar solicitação

```
POST /tramitacao/demandas/:id/desentranhamento/:solicitacaoId/approve
```

**Body** (`DecideDesentranhamentoBody`):

```ts
{
  decisionReason?: string; // opcional, max 1000 chars
}
```

**Responses**:
- `200 OK` → `{ solicitacaoId: string; status: 'approved'; anexoId: string; desentranhadoAt: string }`
- `403 Forbidden` → usuário não é um aprovador elegível para esta solicitação
- `404 Not Found` → solicitação não encontrada
- `409 Conflict` → `ALREADY_DECIDED` (FR-009 — outra decisão já resolveu o pedido)

## 3. Rejeitar solicitação

```
POST /tramitacao/demandas/:id/desentranhamento/:solicitacaoId/reject
```

**Body** (`DecideDesentranhamentoBody`): igual ao endpoint de aprovar.

**Responses**:
- `200 OK` → `{ solicitacaoId: string; status: 'rejected'; anexoId: string }`
- `403 Forbidden` → usuário não é um aprovador elegível
- `404 Not Found` → solicitação não encontrada
- `409 Conflict` → `ALREADY_DECIDED`

## 4. Leitura — extensão do detalhe da demanda

```
GET /tramitacao/demandas/:id
```

(rota já existente — `GetDemandaDetailUseCase` / `tramitacao.mapper.ts`)

Cada item de anexo no DTO de resposta ganha os campos:

```ts
{
  // ...campos já existentes (id, kind, fileName, accessLevel, ...)
  desentranhamento: {
    status: 'none' | 'pending' | 'approved' | 'rejected';
    solicitacaoId?: string;
    direction?: 'author_requests' | 'recipient_requests';
    requestedBy?: { displayName: string };
    requestReason?: string;
    decidedBy?: { displayName: string };
    decisionReason?: string;
    desentranhadoAt?: string;
    canApprove: boolean; // true se o actor atual é um aprovador elegível para o pedido pendente
    canRequest: boolean; // true se o actor atual pode abrir uma nova solicitação para este anexo
  } | null;
}
```

Anexos com `desentranhadoAt != null` e `accessLevel === 'placeholder'` (calculado por `resolveAnexoAccessLevel` estendido) NÃO expõem `url`/`storageKey`/`fileName` real — mesmo comportamento hoje aplicado a anexos confidenciais sem permissão (ver `resolve-anexo-access.ts`).

## 5. Download

```
GET /tramitacao/demandas/:id/anexos/:anexoId/download
```

(rota já existente — `DownloadAnexoUseCase`) passa a negar download (`403 Forbidden`, mesmo padrão de erro já usado para confidencial sem permissão) quando `resolveAnexoAccessLevel` retornar `'placeholder'` por causa do desentranhamento, mesmo que o anexo não seja confidencial.

## Erros — resumo

| Código | Quando |
|---|---|
| `ANEXO_ALREADY_DESENTRANHADO` | Solicitar desentranhamento de anexo já desentranhado |
| `PENDING_REQUEST_EXISTS` | Já existe solicitação pendente para o anexo |
| `NO_APPROVER_AVAILABLE` | Nenhum usuário elegível para decidir (ex.: demanda sem contraparte definida) |
| `ALREADY_DECIDED` | Tentativa de decidir uma solicitação que outra pessoa já decidiu (concorrência) |
| `DEMANDA_ARCHIVED` | Tentativa de solicitar (não de decidir) em demanda arquivada |
| `FORBIDDEN_APPROVER` | Usuário autenticado não está no conjunto de aprovadores elegíveis da solicitação |
