# Revisão de segurança — 053 Excluir Anexos (OWASP)

Base: skill `owasp-security` (Top 10:2025, ASVS 5.0). Escopo: a rota nova, o método de storage novo e as superfícies de leitura alteradas. Cada achado declara o caminho concreto e se é diretamente explorável ou apenas defesa em profundidade.

## Modelo de ameaça (resumo)

| Ativo | Ameaça | Controle |
|---|---|---|
| Arquivos no Wasabi | Apagar arquivo de outra manifestação/tenant | Params + `tenantId` no `where`; `validateTenantPath`; chave **exata** na listagem de versões; checagem de chave compartilhada |
| Integridade do dossiê | Excluir após encerramento | `isManifestacaoEncerrada` no servidor; botão apenas conveniência |
| Rastreabilidade | Exclusão sem rastro / com autor errado | Tombstone + evento + `AuditInterceptor` + log estruturado; AdminTenant tratado sem FK |
| Disponibilidade | Excluir em loop / abuso | `@Throttle` restritivo; idempotência |
| Confidencialidade | Vazar nome do arquivo ao cidadão | Nome só em `descricao`; evento filtrado em `marcos` |
| Recuperabilidade | Dado "excluído" ainda recuperável (bucket versionado) | `deleteObjectPermanently` apaga versões e delete-markers + verificação |

## Mapeamento OWASP Top 10:2025

| # | Item | Situação no plano |
|---|---|---|
| A01 Broken Access Control | **Endereçado.** Autorização no servidor (`@RequireModulo` + `assertForUser`), deny-by-default, `anexoId` só válido dentro de `{manifestacaoId, tenantId}`. 404 uniforme para outro tenant. Ver achado **F1** (pré-existente) |
| A02 Security Misconfiguration | **Verificar em operação.** Permissões mínimas da credencial Wasabi e Object Lock (quickstart §0). `WASABI_PREFIX` permanece vazio (validado no env schema) |
| A03 Supply Chain | Sem dependência nova (`@aws-sdk/client-s3` já presente) |
| A04 Cryptographic Failures | N/A (sem novo segredo; URLs pré-assinadas já existentes expiram em 900 s) |
| A05 Injection | Prisma parametrizado; chave S3 é literal. Rejeitar `..`, `\`, chave vazia. Sem concatenação de SQL |
| A06 Insecure Design | **Endereçado.** Wasabi-primeiro/idempotente; sem estado "meio apagado"; ação destrutiva com confirmação, rate limit e trilha. **Residual R-1/R-2** abaixo |
| A07 Authentication Failures | Herda JWT/guards globais; sem alteração |
| A08 Software/Data Integrity | `CHECK` no banco: tombstone nunca com ponteiro de conteúdo; evento imutável pelo fluxo normal |
| A09 Logging & Alerting | **Endereçado.** Log Pino `anexo.deleted` / `anexo.delete_failed` (ids, actor, role; **sem** nome de arquivo); `AuditInterceptor` já grava `DELETE`. Recomendado alerta em `anexo.delete_failed` recorrente |
| A10 Exceptional Conditions | **Endereçado.** Fail-closed: falha de storage ⇒ 500 genérico, nada gravado; `AccessDenied`/retenção ⇒ erro, nunca "sucesso"; mensagens sem internals (FR-020) |

## ASVS 5.0 (itens relevantes, L1/L2)

- **8.2.1 / 8.2.2 / 8.3.1** — autorização por função e por objeto aplicada na camada de serviço do servidor (use-case), não no client.
- **1.2.4** — acesso a dados parametrizado (Prisma).
- **2.2.1 / 2.2.2** — validação positiva dos params (Zod) no servidor.
- **16.3.x / 16.5.1** (L2) — eventos de segurança logados; mensagem genérica ao usuário, detalhe no log. Recomendação L3 (16.3.2): logar também as decisões **permitidas** — atendida pelo log `anexo.deleted` + evento.
- **14.2.1** — nenhum dado sensível em URL/query (nome do arquivo não trafega em URL da rota).

## Achados

### F1 — Repositories do Ouvidoria não aplicam a extensão de tenant/soft-delete (pré-existente, **fora de escopo** — reportado)

- **Caminho**: `PrismaService` expõe `db` (com `createTenantExtension` + `createSoftDeleteExtension`), mas `RequireManifestacaoRepository`, `FindManifestacaoByIdRepository`, `FindManifestacaoAnexoRepository`, `ListManifestacoesRepository` etc. usam `this.prisma.<model>` (client **base**). Ex.: `RequireManifestacaoRepository` faz `findFirst({ where: { id } })` sem `tenantId` nem `deletedAt`.
- **Alcançabilidade**: um usuário autenticado precisaria conhecer o UUID de manifestação de **outro** tenant; `assertForUser` não compara tenant (admins passam por `ADMIN_BYPASS_ROLES`). Não foi possível confirmar, a partir do código, se há outra barreira (ex.: RLS no banco); portanto **teórico/defesa em profundidade** até prova em contrário.
- **Impacto para esta feature**: se a rota nova reutilizasse esses repositories, seria um vetor de **exclusão destrutiva cross-tenant**. **Mitigação adotada**: repositories novos com `tenantId` e `deletedAt` explícitos no `where` (inclusive em `updateMany`), sem reutilizar os antigos.
- **Recomendação**: spec separada de hardening — aplicar `tenantId`/`deletedAt` nos repositories existentes ou migrar para `prisma.db`.

### F2 — `StorageService.deleteObject` não valida tenant e não remove versões (pré-existente)

- **Caminho**: `deleteObject(storageKey)` envia `DeleteObjectCommand` direto; hoje só é chamado em `update-tenant-branding.use-case.ts` com chave validada à parte.
- **Impacto**: em bucket versionado não apaga de verdade; sem guarda de tenant caso reutilizado.
- **Mitigação**: método **novo** `deleteObjectPermanently` com guarda de tenant e remoção de versões; `deleteObject` permanece intocado e **não** é usado pela feature.

### F3 — `SoftDeleteManifestacaoRepository` usa o client base (a verificar)

- `this.prisma.manifestacao.delete` no client base é um **delete físico** (a conversão para `deletedAt` só existe em `prisma.db`); com `onDelete: Cascade` removeria também os anexos do banco deixando objetos órfãos no Wasabi. **Não confirmado** em execução — apenas observação de leitura de código. Relevância para 053: nenhuma direta (lookup devolve 404 para manifestação inexistente). Registrar para a spec de hardening.

## Riscos residuais aceitos

| ID | Risco | Probabilidade/Impacto | Decisão |
|---|---|---|---|
| R-1 | Janela entre checar status e apagar no Wasabi (encerramento concorrente) | Muito baixa / baixo (efeito igual ao confirmado pelo usuário) | Aceito; `warn` se detectado na transação (research R11) |
| R-2 | Acesso amplo ("qualquer usuário com acesso") + sem motivo ⇒ exclusão indevida por usuário legítimo | Média / médio | Decisão de produto (2026-10-08). Compensação: confirmação, rate limit, tombstone, evento, `AuditInterceptor`, log. Revisitar com motivo obrigatório se houver incidente |
| R-3 | Chave legada fora do padrão `<tenantId>/…` não excluível | Depende dos dados | Fail-closed; medir com SQL do quickstart §0.4 |
| R-4 | URL pré-assinada já emitida | Baixa | Expira em ≤ 15 min; objeto some imediatamente |
| R-5 | Object Lock/retenção ativos | Depende da conta | Falha de propósito; decisão do PO (quickstart §0.2) |

## Checklist de revisão (OWASP) aplicado ao plano

- [x] Input validado no servidor (params Zod)
- [x] Queries parametrizadas
- [x] Autorização em toda request; deny by default; referência de objeto escopada por tenant/manifestação
- [x] Sem stack trace/detalhe interno ao usuário; fail-closed
- [x] Exceções logadas com contexto, sem PII (nome de arquivo) nos logs
- [x] Segredos só por env (nenhum novo)
- [x] Rate limit na ação destrutiva
- [x] Teste de regressão cross-tenant com 2 tenants (obrigatório em `/speckit-tasks`: use-case + repository) — `FindManifestacaoForAnexoDeleteRepository` (T011) exige `tenantId` do contexto; use-case retorna 404 quando manifestação/anexo não pertence ao escopo (T033)
