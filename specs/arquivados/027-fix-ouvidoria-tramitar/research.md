# Research: Corrigir tramitação de manifestações na Ouvidoria

**Feature**: 027-fix-ouvidoria-tramitar  
**Date**: 2026-07-01

## R1 — Causa raiz do erro "Setor ativo não definido"

**Decision**: O bug está no **controller** da Ouvidoria, não no use case de encaminhamento nem no client.

**Rationale**: `ouvidoria.controller.ts` (rota `POST .../encaminhar`) valida apenas `req.user.setorIds?.[0]` do JWT e lança `BadRequestException` antes de chamar `EncaminharManifestacaoUseCase`. Usuários **admin_tenant** recebem JWT com `setorIds: []` (confirmado em `auth.service.spec.ts`), mas passam no `ModuloPermissaoGuard` por bypass de role. O modal do client envia corretamente `destinoSetorId` e `observacao`; o campo ausente é o **setor de origem** (autor da tramitação).

**Alternatives considered**:

| Alternativa | Rejeitada porque |
|-------------|------------------|
| Corrigir apenas no client (seletor de setor ativo) | Spec FR-002 exige resolução automática; UX extra desnecessária |
| Duplicar lógica de fallback no controller | Viola DRY; Tramitação já possui use case canônico |
| Exigir vínculo de setor para admin_tenant | Contraria FR-005 e uso de demonstração Jacaranda |

---

## R2 — Reuso do use case de resolução de setor

**Decision**: Reutilizar e estender `ResolveTramitacaoSectorUseCase` (`ci-api-v2/src/modules/tramitacao/use-cases/resolve-tramitacao-sector.use-case.ts`) com parâmetro opcional `preferredModuloSlug`.

**Rationale**: O módulo Tramitação já implementa a cadeia de fallback exigida pela spec (JWT → DB user setores → chefe → setor de módulo → primeiro setor tenant). `OuvidoriaModule` já importa `TramitacaoModule` para `CreateLinkedDemandaUseCase`. Exportar o resolver evita duplicação e atende FR-004.

**Extensões necessárias**:

1. **Export** de `ResolveTramitacaoSectorUseCase` em `tramitacao.module.ts`.
2. **Parâmetro** `preferredModuloSlug?: ModuloSlug` — fallback de módulo usa `ouvidoria` na rota encaminhar (FR-003 passo 4); default `tramitacao` preserva comportamento existente.
3. **Priorização entre múltiplos setores do usuário**: quando `preferredModuloSlug` informado, preferir setor do usuário que esteja vinculado a esse módulo antes de retornar `setorIds[0]` genérico (edge case da spec).

**Alternatives considered**:

| Alternativa | Rejeitada porque |
|-------------|------------------|
| Novo `ResolveOuvidoriaSectorUseCase` | Duplica 90% da lógica; divergência futura |
| Mover para `modules/permissao/` | Escopo maior que bugfix; Tramitação já é referência viva |
| Resolver no `EncaminharManifestacaoUseCase` | Controller é o ponto de falha atual; resolver antes do execute mantém use case puro |

---

## R3 — Escopo de alteração no client

**Decision**: **Sem alteração obrigatória** no client; validar regressão visual apenas.

**Rationale**: `ForwardManifestacaoDialog.tsx` já exibe `error` do servidor e preserva campos preenchidos (FR-009). Após correção da API, admin tenant conclui tramitação sem mudança de UI.

**Opcional (P2)**: mapear código `ACTIVE_SECTOR_UNDEFINED` para copy orientativa se a API retornar payload estruturado — fora do caminho crítico P1.

**Alternatives considered**:

| Alternativa | Rejeitada porque |
|-------------|------------------|
| Adicionar seletor "Setor origem" no modal | Contraria FR-002 |
| Forçar refresh de token no login admin | Não resolve admin sem setor; workaround frágil |

---

## R4 — Estratégia de testes

**Decision**: TDD em duas camadas — unit do resolver estendido + integration do controller/rota encaminhar.

**Rationale**: Constitution II exige RED → GREEN → REFACTOR. Não existe `resolve-tramitacao-sector.use-case.spec.ts` hoje; criar cobertura mínima junto com teste de controller para admin_tenant (FR-010).

**Casos mínimos**:

| ID | Cenário |
|----|---------|
| CT-OT-001 | JWT com `setorIds` → retorna primeiro (ou preferido ouvidoria) |
| CT-OT-002 | JWT vazio, DB com userSetor → retorna do banco |
| CT-OT-003 | JWT vazio, chefe de setor → retorna chiefOfSetorIds |
| CT-OT-004 | Admin tenant sem vínculo → fallback setor módulo ouvidoria |
| CT-OT-005 | Tenant sem setores → `ACTIVE_SECTOR_UNDEFINED` |
| CT-OT-006 | POST encaminhar admin_tenant Jacaranda → 200 + demanda vinculada |
| CT-OT-007 | POST encaminhar manifestação draft → 409 (regressão) |

**Alternatives considered**:

| Alternativa | Rejeitada porque |
|-------------|------------------|
| Apenas e2e Supertest | Mais lento; unit do resolver isola fallback |
| Teste só do use case encaminhar | Não cobre guard do controller onde o bug vive |

---

## R5 — Mensagem de erro acionável (FR-008)

**Decision**: Manter código `ACTIVE_SECTOR_UNDEFINED`; enriquecer `message` em português operacional quando nenhum setor resolvível.

**Rationale**: `ResolveTramitacaoSectorUseCase` já lança objeto `{ code, message }`. Ajustar copy para: *"Não foi possível identificar o setor de origem. Cadastre setores no tenant ou vincule seu usuário a um setor autorizado na Ouvidoria."*

**Alternatives considered**:

| Alternativa | Rejeitada porque |
|-------------|------------------|
| Novo código HTTP 422 | Breaking change desnecessário; 400 adequado |
| Erro silencioso com setor destino como origem | Semântica incorreta na demanda Tramitação |
