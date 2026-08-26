# Contrato de API: Tramitação como Protocolo

Base: `ci-api-v2/src/modules/tramitacao/tramitacao.controller.ts` (reescrito). Prefixo de rota muda de `/tramitacao/demandas` para `/tramitacao/protocolos` (research.md §11). Guard de classe `@RequireModulo('tramitacao')` mantido; licença **Base** inalterada.

Todas as rotas exigem tenant resolvido (`X-Tenant-ID`) e usuário autenticado (`JwtAuthGuard`).

## 1. Abrir novo protocolo

```
POST /tramitacao/protocolos
```

**Body** (`CreateProtocoloBody`, Zod):

```ts
{
  subject: string;              // obrigatório, max 500 chars
  tipo: 'setorial' | 'pessoal';
  setorIds?: string[];          // obrigatório e não-vazio quando tipo=setorial
  targetUserId?: string;        // obrigatório quando tipo=pessoal, != actor
  body?: string;                // conteúdo inicial (evento `aberto`)
  anexos?: StagedAnexoInput[];  // upload já confirmado antes (padrão presign existente)
}
```

**Regras**: FR-002, FR-003, FR-004. `tipo=setorial` exige `setorIds.length >= 1`; `tipo=pessoal` exige `targetUserId` e proíbe `setorIds`.

**Responses**:
- `201 Created` → `{ id, protocolNumber, tipo, status: 'aberto', subject, createdAt }`
- `400 Bad Request` → `SUBJECT_REQUIRED` | `AT_LEAST_ONE_SECTOR_REQUIRED` | `PERSONAL_TARGET_REQUIRED`

**Notificação**: `tramitacao_protocolo_setor_incluido` (setorial) ou `tramitacao_protocolo_pessoal_aberto` (pessoal).

## 2. Abrir protocolo vinculado a outro módulo

```
POST /tramitacao/protocolos/linked
```

Chamado internamente por Gabinete/Ouvidoria/Jurídico (equivalente ao `CreateLinkedDemandaUseCase` atual). Mesmo body do item 1, mais:

```ts
{
  sourceModule: 'gabinete' | 'ouvidoria' | 'juridico' | 'compras';
  sourceRecordId: string;
  sourceSnapshot: Record<string, unknown>;
}
```

**Responses**: iguais ao item 1.

## 3. Listar "Meus protocolos"

```
GET /tramitacao/protocolos?status=&tipo=&q=&page=&pageSize=
```

Substitui `GET /tramitacao/demandas?folder=...`. Sem `folder` — lista única (FR-010).

**Query params**:
- `status?: 'aberto' | 'encerrado'` — filtro (FR-011)
- `tipo?: 'setorial' | 'pessoal'` — filtro auxiliar
- `q?: string` — busca por assunto ou `protocolNumber`
- `sectorId?: string` — quando o actor participa de múltiplos setores, filtra pela visão de um setor específico (equivalente ao seletor de setor atual já existente)

**Responses**:
- `200 OK` → `{ items: ProtocoloListItem[]; total: number }`, ordenado por `updatedAt DESC` (research.md §10)

```ts
type ProtocoloListItem = {
  id: string;
  protocolNumber: string;
  subject: string;
  tipo: 'setorial' | 'pessoal';
  status: 'aberto' | 'encerrado';
  setores: { id: string; nome: string }[];   // vazio se pessoal
  targetUser?: { id: string; displayName: string }; // presente se pessoal
  updatedAt: string;
  createdAt: string;
};
```

## 4. Detalhe do protocolo

```
GET /tramitacao/protocolos/:id
```

**Responses**:
- `200 OK` → `ProtocoloDetail`:

```ts
type ProtocoloDetail = ProtocoloListItem & {
  autor: { id?: string; displayName: string };
  gestores: { userId: string; displayName: string }[]; // autor + TramitacaoProtocoloGestor
  canManage: boolean;   // actor atual pode incluir setor/encerrar
  sourceModule?: string;
  sourceRecordId?: string;
  sourceSnapshot?: Record<string, unknown>;
  encerradoAt?: string;
  encerradoMotivo?: string;
  encerradoBy?: { displayName: string };
  timeline: ProtocoloTimelineEvent[];
};

type ProtocoloTimelineEvent = {
  id: string;
  tipo: 'aberto' | 'atualizacao' | 'setor_incluido' | 'gestao_concedida'
      | 'vinculo_anexado' | 'encerrado'
      | 'desentranhamento_solicitado' | 'desentranhamento_aprovado' | 'desentranhamento_rejeitado';
  author: { displayName: string };
  createdAt: string;
  payload: Record<string, unknown>;
  anexos: TramitacaoAnexoView[]; // mesmo shape hoje existente (accessLevel, desentranhamento block)
};
```

- `403 Forbidden` → actor não participa (não é membro de setor incluído nem participante pessoal)
- `404 Not Found` → protocolo inexistente/removido

## 5. Adicionar atualização (mensagem/anexo)

```
POST /tramitacao/protocolos/:id/atualizacoes
```

Substitui `POST .../reply`.

**Body**:

```ts
{
  body?: string;
  anexos?: StagedAnexoInput[];
}
```

**Regras**: FR-007. Bloqueado se `status = encerrado` (`409 PROTOCOLO_ENCERRADO`).

**Responses**:
- `201 Created` → `{ eventoId: string; createdAt: string }`
- `409 Conflict` → `PROTOCOLO_ENCERRADO`

**Notificação**: `tramitacao_protocolo_atualizacao` (setorial) ou `tramitacao_protocolo_pessoal_atualizacao` (pessoal) para os demais participantes.

## 6. Incluir setor

```
POST /tramitacao/protocolos/:id/setores
```

Substitui o antigo `forward` (que movia). Agora **adiciona**, não move.

**Body**: `{ setorId: string; notes?: string }`

**Regras**: FR-008, FR-009 — restrito a `canManage`. Bloqueado se `tipo = pessoal` (`400 PERSONAL_NO_SECTOR`) ou `status = encerrado` (`409 PROTOCOLO_ENCERRADO`).

**Responses**:
- `201 Created` → `{ eventoId: string; setorId: string }`
- `403 Forbidden` → `FORBIDDEN_NOT_MANAGER`
- `409 Conflict` → `SECTOR_ALREADY_INCLUDED` | `PROTOCOLO_ENCERRADO`

**Notificação**: `tramitacao_protocolo_setor_incluido` para membros do novo setor.

## 7. Conceder permissão de gestão (US8)

```
POST /tramitacao/protocolos/:id/gestores
```

**Body**: `{ userId: string }` — `userId` deve ser participante atual (membro de setor incluído ou o outro lado, no pessoal).

**Regras**: FR-009, restrito a `canManage`.

**Responses**:
- `201 Created` → `{ eventoId: string; userId: string }`
- `403 Forbidden` → `FORBIDDEN_NOT_MANAGER`
- `400 Bad Request` → `USER_NOT_A_PARTICIPANT`

## 8. Tramitar dados de outro módulo → entranhar em protocolo existente

```
POST /tramitacao/protocolos/:id/entranhar
```

**Body**:

```ts
{
  sourceModule: 'gabinete' | 'ouvidoria' | 'juridico' | 'compras';
  sourceRecordId: string;
  sourceSnapshot: Record<string, unknown>;
}
```

**Regras**: FR-012, FR-013, FR-014 — bloqueado se `status = encerrado` (`409 PROTOCOLO_ENCERRADO`).

**Responses**:
- `201 Created` → `{ eventoId: string }`
- `409 Conflict` → `PROTOCOLO_ENCERRADO`

## 9. Buscar protocolos elegíveis para entranhar

```
GET /tramitacao/protocolos/buscar?q=&excludeEncerrados=true
```

Usado pela UI de outros módulos ao escolher "entranhar em protocolo existente" (US4). Retorna apenas protocolos `status=aberto` em que o actor participa.

**Responses**:
- `200 OK` → `{ items: ProtocoloListItem[] }` (mesmo shape do item 3, sem paginação — resultado limitado a 20)

## 10. Encerrar protocolo

```
POST /tramitacao/protocolos/:id/encerrar
```

Substitui `archive`.

**Body**: `{ motivo?: string }`

**Regras**: FR-017, FR-018, FR-020 — restrito a `canManage`. "Primeira ação vale": segunda tentativa retorna `409` informativo, não erro genérico.

**Responses**:
- `200 OK` → `{ status: 'encerrado'; encerradoAt: string }`
- `403 Forbidden` → `FORBIDDEN_NOT_MANAGER`
- `409 Conflict` → `{ code: 'ALREADY_ENCERRADO'; encerradoAt: string }`

**Notificação**: `tramitacao_protocolo_encerrado` para todos os participantes.

## 11. Baixar (exportar PDF + ZIP)

```
POST /tramitacao/protocolos/:id/baixar
```

**Regras**: FR-015, FR-016, FR-019 — disponível a qualquer momento (aberto ou encerrado); nenhum campo de estado é alterado (idempotente/sem efeito colateral persistido, ver research.md §8 e §9).

**Responses**:
- `200 OK` → `{ downloadUrl: string; expiresIn: number; fileName: string }` (mesmo padrão de presign já usado em `download-anexo`/ANPD)
- `422 Unprocessable Entity` → `EXPORT_TOO_LARGE` (soma de anexos elegíveis > 200MB, research.md §9)

## 12. Anexos (presign/confirm/link/download) e desentranhamento

Rotas mantidas com o mesmo contrato de hoje, apenas trocando o segmento pai de `/tramitacao/demandas/:id/anexos/...` para `/tramitacao/protocolos/:id/anexos/...` e `/tramitacao/protocolos/:id/desentranhamento/...`:

- `POST /tramitacao/protocolos/:id/anexos/presign`
- `POST /tramitacao/protocolos/:id/anexos/:anexoId/confirm`
- `POST /tramitacao/protocolos/:id/anexos/link`
- `GET /tramitacao/protocolos/:id/anexos/:anexoId/download`
- `POST /tramitacao/protocolos/:id/anexos/:anexoId/desentranhamento`
- `POST /tramitacao/protocolos/:id/desentranhamento/:solicitacaoId/approve`
- `POST /tramitacao/protocolos/:id/desentranhamento/:solicitacaoId/reject`

Payloads/responses idênticos ao contrato já existente (`034-desentranhamento-tramitacao/contracts/desentranhamento-api.md`), exceto:
- `direction` no corpo de resposta passa a ser `'autor_solicita' | 'participante_solicita'` (research.md §6).
- `NO_APPROVER_AVAILABLE` deixa de ser um caso prático esperado em protocolos setoriais com múltiplos participantes (só ocorre em protocolo pessoal onde o autor é o único usuário ativo, caso residual).

## Endpoints removidos (sem equivalente 1:1)

| Rota antiga | Motivo |
|---|---|
| `POST /tramitacao/demandas/:id/forward` | Substituída pelo conceito de inclusão (item 6) — não move mais |
| `POST /tramitacao/demandas/:id/forward-user` | Não existe mais "encaminhar pessoal" — protocolo pessoal é fixo 1:1 |
| `POST /tramitacao/demandas/:id/promote-sector` | Sem equivalente — não há mais transição pessoal→setorial; tipo é imutável (FR-004) |
| `POST /tramitacao/demandas/:id/archive` | Renomeado para `encerrar` (item 10), com semântica de somente-leitura permanente |
| `GET /tramitacao/demandas?folder=` | Substituído pela lista única (item 3) |

## Erros — resumo (novos/alterados)

| Código | Quando |
|---|---|
| `SUBJECT_REQUIRED` | Abertura sem assunto |
| `AT_LEAST_ONE_SECTOR_REQUIRED` | Abertura setorial sem setor |
| `PERSONAL_TARGET_REQUIRED` | Abertura pessoal sem destinatário |
| `PROTOCOLO_ENCERRADO` | Qualquer escrita (atualização, inclusão de setor, gestor, entranhar) em protocolo encerrado |
| `FORBIDDEN_NOT_MANAGER` | Ação de gestão (incluir setor, conceder gestor, encerrar) por participante sem permissão |
| `SECTOR_ALREADY_INCLUDED` | Incluir setor já participante |
| `PERSONAL_NO_SECTOR` | Tentar incluir setor em protocolo pessoal |
| `USER_NOT_A_PARTICIPANT` | Conceder gestão a usuário que não participa do protocolo |
| `ALREADY_ENCERRADO` | Segunda tentativa de encerrar (concorrência) |
| `EXPORT_TOO_LARGE` | Exportação excede limite de tamanho |
