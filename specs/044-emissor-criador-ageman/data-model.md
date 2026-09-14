# Data Model — 044 Emissor automático ao criar demanda AGEMAN

**Spec**: [spec.md](./spec.md) · **Research**: [research.md](./research.md)

Nenhuma migration. `emissorUserId` continua `String?` → `User` (`admin-tenant-user-fk.mdc`).

## 1. Entidades existentes (comportamento)

### `Manifestacao`

| Campo | Tipo | Hoje | Depois |
| --- | --- | --- | --- |
| `emissorUserId` | `String?` | Valor enviado pelo client (qualquer usuário do tenant) | **Rascunho**: resolvido por `resolveEmissorUserId`. Operador institucional → sempre `actor.userId`. Admin instituição / `admin_saas` → UUID pedido se operador real, senão `null`. **Pós-confirmação**: imutável (PATCH ignora o campo). Histórico não é recalculado. |
| `createdByUserId` | `String?` | Já via `resolveUserTableId` no create | Inalterado |
| `status` | `ManifestacaoStatus` | `draft` → `in_review` no confirm | Inalterado. `draft` = fase em que o emissor ainda pode ser recalculado. Qualquer outro status = emissor congelado. |
| `dadosAdicionais` | `Json?` | Chaves de negócio (concessionária, forma de atendimento, …) | **Merge** não destrutivo: se o ator não for operador institucional, acrescenta `actorId` + `actorRole` via `withActorPayload`. Chaves existentes permanecem. Não exposto no detalhe como “Emissor”. |

Relação `emissor` (`User?`) e mapper `resolveEmissorLabel` / `emissorVisivel` **não mudam**. Emissor vazio → detalhe mostra “—”.

### `User` / `AdminTenant` / `AdminPlataforma`

Sem alteração. Só `User` pode ser emissor. `admin_tenant` e `admin_saas` **não** entram em `emissorUserId`.

`resolveUserTableId` (já existente) é a definição canônica de “operador institucional” para esta feature:

| Role JWT | Tem linha em `User`? | Emissor automático |
| --- | --- | --- |
| `user`, `chefe_setor`, `admin_plataforma` | Sim | Sempre o autenticado |
| `admin_tenant`, `admin_saas` | Não | Vazio, salvo escolha explícita de um `User` do tenant |

## 2. Função de domínio (não persistida)

`resolveEmissorUserId` — regra pura, sem I/O:

| `phase` | Ator | `requestedEmissorUserId` | Retorno |
| --- | --- | --- | --- |
| `confirmed` | qualquer | qualquer | *não aplicar* (chamador ignora) |
| `draft` | operador institucional | qualquer / ausente | `actor.userId` |
| `draft` | admin instituição / SaaS | UUID válido do tenant | esse UUID |
| `draft` | admin instituição / SaaS | ausente / inválido | `undefined` |

Validação de “UUID pertence ao tenant” continua em `FindEmissorUserRepository` **antes** de persistir, só quando o retorno pretendido é um UUID pedido pelo admin (não quando o operador envia lixo — lixo é ignorado, sem 400).

## 3. Transições

```text
[criação POST] draft
    emissor := resolve(..., phase: draft)
    dadosAdicionais += actor* se não-operador

[PATCH] status === draft
    emissor := resolve(..., phase: draft)   // recálculo
    dadosAdicionais merge actor* se não-operador

[PATCH] status !== draft
    emissor NÃO é escrito
    demais campos: regra atual (isManifestacaoEditable)

[POST .../confirmar] draft → in_review
    emissor inalterado
```

## 4. Fora de escopo de modelo

- Portal público (`origem = publica`) — create público não seta emissor (já hoje).
- Recalcular demandas antigas.
- Novo enum / nova tabela / nova FK.
