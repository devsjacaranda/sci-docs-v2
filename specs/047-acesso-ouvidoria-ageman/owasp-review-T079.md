# T079 — Revisão OWASP (spec 047)

**Escopo:** controle de acesso Ouvidoria (API + client), feature flag, grants/revoke, 403, auditoria.  
**Referência:** OWASP Top 10:2025 **A01** (Broken Access Control), **A09** (Security Logging).  
**Data:** 2026-09-16  
**Método:** revisão estática de código (subagent `security-review` indisponível por falha de diff no workspace).

---

## Resumo executivo

| Severidade | Quantidade | Status |
|------------|------------|--------|
| Critical | 0 | — |
| High | 0 | — |
| Medium | 2 | Aceitos / backlog documentado |
| Low | 2 | Informativo |

**Conclusão:** controles centrais estão alinhados com deny-by-default, isolamento por tenant e respostas 403 sem vazamento de conteúdo sensível. E2e `ouvidoria-acesso-controle` e `ouvidoria-acesso-flag` cobrem cenários principais.

---

## A01 — Broken Access Control

### Controles verificados (OK)

1. **Decisão centralizada** — `decideManifestacaoAccess` / `assertManifestacaoAccess` com ordem: flag OFF → bypass; sem emissor → canal; admin/chefe ouvidoria; owner; grant pontual; grant emissor; senão **negado**.
2. **Listagem** — `ManifestacaoAccessService.resolveListVisibility` restringe por emissor + grants + canal público; flag OFF → bypass total.
3. **403 sem conteúdo** — `ouvidoriaForbidden(OUVIDORIA_ACCESS_DENIED)` retorna só `code` + mensagem genérica; e2e T023 valida ausência de `subject`/`description` no corpo.
4. **Detalhe (FR-007 parcial)** — `GetManifestacaoDetailUseCase` chama `findAccessSubject` + `assertForUser` **antes** de `findById` completo.
5. **Grants/revoke** — `canManageOuvidoriaAcesso` (emissor, chefe ouvidoria, admin); grantee validado com `FindUserInTenantRepository`; repositório `findById` / queries com `tenantId` do `AsyncLocalStorage`.
6. **IDOR concessão** — `OuvidoriaAcessoRepository.findById` filtra `tenantId`; outro tenant → 404 `ACCESS_NOT_FOUND`, não revoga alheio.
7. **Flag tenant** — self-service `SetOuvidoriaAcessoFlagUseCase` usa `getRequestContext().tenantId` para `admin_tenant`; `admin_saas` só altera outro tenant via rota admin explícita (e2e FLAG-009).
8. **Listagem de acessos** — rota `GET .../acessos` exige `assertForUser` no controller antes do use case.
9. **Client** — `OUVIDORIA_ACCESS_DENIED` mapeado para superfície de página; mensagem canônica (sem preferir texto curto da API que poderia vazar contexto).

### Médio — M1: assert após carga pesada em alguns use-cases

**Descrição:** nem todos os use-cases de manifestação replicam o padrão “subject leve → assert → load completo” do detalhe. Em teoria, negação tardia poderia expor metadados em caminhos internos ou aumentar superfície de timing side-channel.

**Exploitabilidade:** baixa na API atual (403 antes de persistir mutações; downloads protegidos por assert nos use-cases revisados). **Recomendação:** backlog FR-007 estrito (já citado no plano).

### Médio — M2: `ListOuvidoriaAcessosUseCase` sem assert interno

**Descrição:** autorização só no controller. Risco se o use case for reutilizado sem guard.

**Mitigação atual:** único call site protegido; `@RequireModulo('ouvidoria')`. **Recomendação:** defense-in-depth opcional (injetar `ManifestacaoAccessService` no use case).

### Baixo — L1: listagem de acessos revela nomes de grantees

**Descrição:** quem já pode abrir a demanda vê “Quem tem acesso” (US6). Comportamento esperado, não IDOR.

### Baixo — L2: flag OFF bypass total

**Descrição:** kill-switch por tenant (FR-014+). Risco operacional se admin desligar sem governança; mitigado por auditoria e roles restritas.

---

## A09 — Security Logging and Alerting

### Controles verificados (OK)

1. **Flag** — `SetOuvidoriaAcessoFlagUseCase` grava `auditLog` (`ouvidoria_acesso_flag_toggled`) com `withActorPayload` (actorId/role quando sem FK User).
2. **Concessões** — eventos de manifestação `access_granted` / `access_revoked` em grant/revoke pontual (com `manifestacaoId`).
3. **403** — código estável `OUVIDORIA_ACCESS_DENIED` para correlação em logs de aplicação (Pino/Fastify).

### Baixo — L3: revogação escopo `emissor` sem evento em manifestação

**Descrição:** `RevokeOuvidoriaAcessoUseCase` só cria evento quando `concessao.manifestacaoId` existe. Revogação emissor-only não gera linha em timeline de uma demanda específica (auditoria ainda existe na tabela de concessão + `revokedAt`).

**Recomendação:** opcional — audit log dedicado ou evento agregado admin.

---

## Client (ci-client-v2)

- Erro 403 de registro distinto de negação de módulo; testes Vitest + e2e MSW.
- Toggle flag: apenas `admin_tenant` / `admin_plataforma` no painel web; admin-saas com rota admin.

---

## Ações tomadas nesta task

- Relatório gerado (este arquivo).
- Nenhuma alteração de código obrigatória identificada para T079.

## Referências de código

- `ci-api-v2/src/modules/ouvidoria/lib/assert-manifestacao-access.ts`
- `ci-api-v2/src/modules/ouvidoria/services/manifestacao-access.service.ts`
- `ci-api-v2/src/modules/ouvidoria/use-cases/grant-ouvidoria-acesso.use-case.ts`
- `ci-api-v2/src/modules/ouvidoria/use-cases/revoke-ouvidoria-acesso.use-case.ts`
- `ci-api-v2/src/modules/ouvidoria/use-cases/set-ouvidoria-acesso-flag.use-case.ts`
- `ci-api-v2/test/ouvidoria-acesso-controle.e2e-spec.ts`
- `ci-api-v2/test/ouvidoria-acesso-flag.e2e-spec.ts`
