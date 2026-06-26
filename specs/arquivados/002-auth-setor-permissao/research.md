# Research: Autenticação e Permissão por Setor

**Feature**: 002-auth-setor-permissao  
**Date**: 2026-06-05

## R1 — Relação usuário ↔ setor (lotação)

**Decision**: Tabela de junção `UserSetor` (N:N) entre `User` e `Setor`; remover coluna única `User.setorId`.

**Rationale**: A spec (FR-002) exige um ou mais setores de lotação por usuário. O mock do client já usa `sectorIds[]`. A coluna singular em Prisma é legado insuficiente.

**Alternatives considered**:

| Alternativa | Motivo de rejeição |
|-------------|-------------------|
| Manter `setorId` + `setorSecundarioId` | Não escala; viola modelo N:N |
| Setor primário + JSON de secundários | Sem integridade referencial; difícil de consultar |
| Apenas role `chefe_setor` sem lotação | Não resolve permissão de módulo por setor |

---

## R2 — Chefia por setor (não role global)

**Decision**: Campo opcional `Setor.chefeUserId` → `User`; chefia derivada de quem lidera cada setor. Role `UserRole.chefe_setor` permanece na hierarquia para rotas administrativas, mas notificações e membros filtram por `Setor.chefeUserId`.

**Rationale**: Spec exige chefe designado por setor; usuário pode ser chefe de setor A e lotado em setor B (edge case). Mock usa `chiefOfSectorIds[]` independente de `sectorIds[]`.

**Alternatives considered**:

| Alternativa | Motivo de rejeição |
|-------------|-------------------|
| Role global `chefe_setor` = chefe de todos | Não modela multi-setor nem chefia parcial |
| Tabela `SetorChefe` N:N | Válido, mas v1 assume um chefe por setor (spec) |
| Chefia só via role, sem FK | Impossível saber qual setor o chefe lidera |

---

## R3 — Vínculo módulo ↔ setor

**Decision**: Tabela `ModuloSetor` com `moduloSlug` (enum canônico), `setorId`, `tenantId`; zero linhas = módulo aberto (FR-003).

**Rationale**: Alinha com `moduleSectorLinks` do mock e vocabulário de `ci-api-v2/CONTEXT.md`. Enum evita slugs inválidos.

**Alternatives considered**:

| Alternativa | Motivo de rejeição |
|-------------|-------------------|
| JSON em `Tenant.config` | Sem queries eficientes; difícil isolar por tenant |
| Hardcode no código | Impossibilita administração (US3) |
| Permissão por tela/rota | Fora do escopo; spec é nível módulo |

**Módulos abertos (hardcoded)**: `global`, `tramitacao` (FR-009).

---

## R4 — Guard de permissão por módulo (API)

**Decision**: Novo `ModuloPermissaoGuard` após `LicencaGuard` no pipeline global; decorator `@RequireModulo(slug)`.

**Rationale**: FR-012 exige consistência backend. `LicencaGuard` já valida licenças no **tenant** (não por usuário). FR-015 torna licença por usuário irrelevante — guard de setor é a barreira de módulo.

**Regras de bypass**:

| Condição | Comportamento |
|----------|---------------|
| `@Public()` | Skip |
| Sem `@RequireModulo` | Skip |
| `admin_plataforma` / `admin_saas` | Allow |
| Módulo `global` ou `tramitacao` | Allow |
| Zero vínculos `ModuloSetor` para o slug | Allow |
| Interseção `user.setorIds` ∩ `modulo.setorIds` | Allow |
| Caso contrário | `403 Forbidden` + payload estruturado para client |

**Alternatives considered**:

| Alternativa | Motivo de rejeição |
|-------------|-------------------|
| Lógica só no client | Viola FR-012 |
| Middleware global sem decorator | Difícil mapear rotas → módulo |
| Reutilizar `RolesGuard` | Papéis ≠ lotação por setor |

---

## R5 — JWT e `/auth/me`

**Decision**: Estender payload JWT e resposta `/auth/me` com `setorIds[]`, `chiefOfSetorIds[]`, `isPlatformAdmin` (derivado de role).

**Rationale**: Client precisa avaliar acesso sem round-trip por navegação; mock já expõe esses campos. Tokens existentes invalidados na migração (aceitável em dev).

**Alternatives considered**:

| Alternativa | Motivo de rejeição |
|-------------|-------------------|
| Manter só `setorId` singular | Incompatível com spec |
| Buscar setores a cada request sem cache | Latência desnecessária; JWT já carrega contexto |
| Session server-side | Fora do padrão JWT atual |

---

## R6 — Solicitação e notificação (notify-only)

**Decision**: Entidades `SolicitacaoPermissao` + `NotificacaoPermissao` (1 solicitação → N notificações, uma por chefe de setor vinculado ao módulo).

**Rationale**: FR-007 exige notificar **todos** os chefes; FR-016 proíbe auto-concessão. Deduplicação por `(solicitante, moduloSlug)` na mesma sessão/janela de tempo (edge case spec).

**Alternatives considered**:

| Alternativa | Motivo de rejeição |
|-------------|-------------------|
| Só e-mail externo | Fora do produto; mock usa painel de notificações |
| WebSocket push | Over-engineering para v1 |
| Uma notificação agregada sem registro | Perde rastreabilidade por chefe |

---

## R7 — Licenças universais por usuário

**Decision**: Não criar tabela `UserLicenca`; FR-015 satisfeita porque tenant demo já possui todas as licenças ativas e `LicencaGuard` valida tenant. Documentar invariante: todo tenant CI possui as 4 licenças.

**Rationale**: Decisão de produto do usuário — não existe usuário sem licença. Simplifica modelo; controle de módulo é 100% setor.

**Alternatives considered**:

| Alternativa | Motivo de rejeição |
|-------------|-------------------|
| `UserLicenca` com seed automático | Redundante com `TenantLicenca` |
| Remover `LicencaGuard` | Ainda útil para rotas `@RequireLicenca` futuras |

---

## R8 — Integração client (mock → API)

**Decision**: Fase de implementação substitui `admin-mock.ts` / `mockLogin` por chamadas REST; mantém `AccessDenied403` e `permissions.ts` como camada de domínio client, alimentada por `/auth/me` + endpoints admin.

**Rationale**: UI 403 e painéis admin já existem; plan foca wiring. Corrigir `requestModulePermission` para notificar todos os chefes (hoje só `sectorIds[0]`).

**Alternatives considered**:

| Alternativa | Motivo de rejeição |
|-------------|-------------------|
| Manter mock permanentemente | Viola FR-012 backend |
| Mover lógica toda para `@ci/domain` | Escopo extra; permissions é app-specific por ora |

---

## R9 — Testes

**Decision**: TDD com Jest (API): unit tests para guard/service; e2e para login, 403, solicitação multi-chefe. Client: smoke manual no quickstart + typecheck.

**Rationale**: Constitution II (Test-First). Skills `testing-conventions`, `tdd`.

**Alternatives considered**:

| Alternativa | Motivo de rejeição |
|-------------|-------------------|
| Só e2e | Feedback lento para guards |
| Playwright na v1 | Adiar; mock→API já é escopo grande |
