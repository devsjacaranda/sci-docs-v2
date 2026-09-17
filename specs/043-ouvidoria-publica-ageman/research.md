# Research — 043 Ouvidoria Pública AGEMAN

**Date**: 2026-09-11
**Spec**: [spec.md](./spec.md)

## R1 — 6 categorias + `tipo`: reaproveitar enums canônicos, não duplicar

**Decision**: `programa` passa de `z.enum(['agua','iluminacao'])` para `z.enum(['agua','transporte','iluminacao','lixo','zona_azul','institucional'])` em `criarManifestacaoPublicaBodySchema` ([ouvidoria.schemas.ts:606-608](../../../ci-api-v2/src/modules/ouvidoria/ouvidoria.schemas.ts)) — já alinhado com `PROGRAMA_ALIAS` de `lib/ageman-catalog.ts`. `tipo` **reaproveita** o enum `manifestacaoTipo` já declarado no topo do mesmo arquivo (`complaint | request | whistleblower | praise | suggestion | simplify`) em vez de introduzir um enum paralelo em português — o client traduz label↔valor (`TIPO_MANIFESTACAO_OPTIONS`), a API mantém uma única fonte de verdade.

Mapeamento client → API: RECLAMAÇÃO→`complaint`, SOLICITAÇÃO→`request`, DENÚNCIA→`whistleblower`, ELOGIO→`praise`, SUGESTÃO→`suggestion` (`simplify` não é usado pelo assistente público).

Nova categoria `institucional`: sem `motivo` de catálogo fixo — o cidadão descreve livremente (assunção da spec). `AGEMAN_PROGRAMA_LABEL['6'] = 'Assuntos institucionais'`; `PROGRAMA_CODE.institucional = '6'` em `lib/numero-personalizado.ts` (hoje cai no fallback genérico `'99'` via `inferTypeCodeFromName` — funciona, mas fica implícito; adicionar a entrada explícita documenta a decisão e mantém o protocolo `YYYY-6-MM-NNNN` consistente com os demais programas).

**Rationale**: Enum de domínio já existe e está testado em todo o resto do módulo (`ouvidoria.mapper.ts`, `get-manifestacao-detail.use-case.ts`); duplicar em português criaria duas fontes de verdade para a mesma informação (violação do princípio "não duplicar enum/shape" da skill `zod-validation-sanitization`).

**Alternatives considered**:

- Enum novo em português (`RECLAMACAO`, `SUGESTAO`, ...) espelhando literalmente o payload da v1 — rejeitado: cria tradução duplicada e diverge do resto do módulo, que já usa o enum inglês em toda parte (dashboards, filtros, documentos gerados).
- Deixar `institucional` cair no fallback `'99'` sem entrada explícita — aceitável, mas menos rastreável; custo de adicionar a entrada é uma linha.

**Catálogo de motivos exposto ao público**: nova rota `GET /ouvidoria/publico/programas`, devolvendo `AGEMAN_PROGRAMA_LABEL` + `AGEMAN_MOTIVOS_BY_PROGRAMA` (77 itens já existentes) — em vez de estender `GET /ouvidoria/publico/catalogos` (que hoje devolve só formas de atendimento e é consumido como tal). Rota nova evita mudar o shape de uma resposta já em contrato; nome espelha o recurso (`programas`, não `catalogos` genérico). Elimina o hardcode de motivos que a v1 mantinha no client.

---

## R2 — Contato obrigatório + persistência de endereço (reaproveitar `CreateAddressRepository`)

**Decision**: Adicionar `email` (obrigatório, `z.email()`), `mobilePhone`/`homePhone`/`businessPhone` (opcionais, `superRefine` mantendo a regra client-side da v1 de "ao menos um contato") ao body schema. `create-manifestacao-publica.repository.ts` passa a:

1. Mapear `tipo` → `ManifestacaoTipo` (constante local, sem `class-validator`).
2. Setar `replyEmail`, `requesterMobilePhone`, `requesterHomePhone`, `requesterBusinessPhone` — campos já existentes no Prisma (`manifestacao.prisma:51-59`), nunca preenchidos hoje.
3. Injetar `CreateAddressRepository` (`modules/address/repository/address.repositories.ts`) e persistir `addressId` quando `input.address` vier preenchido — **mesmo padrão** já usado por `create-manifestacao-draft.use-case.ts` no fluxo autenticado.
4. **Corrigir bug existente**: remover `createdByUserId: (await tx.user.findFirst({ where: { tenantId } }))?.id` — hoje atribui um usuário **arbitrário** do tenant como autor de uma manifestação pública/anônima. Campo é `String?`; fica `undefined` (não há ator autenticado no fluxo público).
5. **Reduzir uma query redundante**: `create()` retorna também `id` (hoje só retorna `protocol`/`numeroPersonalizado`/`chaveConsulta`); `bind-anexos-publicos.repository.ts` deixa de fazer `findFirst({ where: { protocol } })` para descobrir o `manifestacaoId` — o use-case já tem o `id` em mãos.

**Rationale**: A infraestrutura de endereço já existe e é testada; reaproveitar evita duplicar lógica de criação de `Address`/`Municipio`. O bug do `createdByUserId` é achado de código durante a exploração — corrigir custa uma linha e evita atribuição incorreta de autoria em auditoria/relatórios.

**Alternatives considered**:

- Deixar `createdByUserId` como está — rejeitado: é uma atribuição semanticamente errada (usuário aleatório "autor" de manifestação anônima), risco de auditoria incorreta.
- Criar um repository de endereço específico para o fluxo público — rejeitado: duplicaria `CreateAddressRepository` sem necessidade.

---

## R3 — Status público simplificado (Clarifications Q2)

**Decision**: `ConsultaPublicaUseCase.execute()` hoje devolve `statusLabel: MANIFESTACAO_STATUS_LABEL[row.status]` — o mapa **interno** (`ouvidoria.mapper.ts:23-29`: Rascunho/Em análise/Tramitando/Respondida/Encerrada com resolução/Encerrada sem resolução), usado também nas telas internas da equipe de ouvidoria. Passa a usar um novo mapa dedicado `PUBLIC_MANIFESTACAO_STATUS_LABEL`:

```text
draft              → "Recebida"
in_review          → "Em análise"
forwarding         → "Em análise"
answered           → "Respondida"
closed             → "Encerrada"
closed_unresolved  → "Encerrada"
```

**Rationale**: Resolução direta da cláusula de clarificação (FR-015) — o cidadão não deve ver o vocabulário operacional interno (“Tramitando”, “Encerrada sem resolução” expõe detalhe de triagem que não agrega valor e pode gerar dúvida/reclamação desnecessária). Os `marcos[]` retornados já são seguros hoje (mapeiam só `titulo` genérico + data, nunca `descricao`) — não há mudança necessária ali.

**Alternatives considered**:

- Manter `MANIFESTACAO_STATUS_LABEL` também na rota pública — rejeitado pela clarificação (Session 2026-09-11).
- Expor os 6 status internos brutos (sem label) e traduzir no client — rejeitado: duplicaria a tradução em dois lugares (API e client) para a mesma decisão de produto.

---

## R4 — reCAPTCHA v3 real, falha fechada, bypass em dev

**Decision**: `VerifyPublicChallengeRepository.execute(token)` passa de `token.length >= 4` para uma chamada real a `https://www.google.com/recaptcha/api/siteverify` com `RECAPTCHA_SECRET_KEY` (novo env var), validando `success === true`, `score >= 0.5` e `action === 'submit_manifestation'`. Três casos:

| Cenário | Comportamento |
| --- | --- |
| `RECAPTCHA_SECRET_KEY` ausente (dev/local) | bypass automático (`token.length >= 4`, comportamento atual) — não trava ambientes sem a chave |
| Secret configurada, serviço responde | valida `success`/`score`/`action` normalmente |
| Secret configurada, serviço **não responde** (timeout/erro de rede) | **falha fechada** — bloqueia o envio (Clarifications Q3), não deixa passar sem validação |

**Rationale**: Falha fechada prioriza segurança/anti-abuso (decisão explícita do usuário na clarificação) — um canal público de ouvidoria é alvo natural de spam/automação; deixar passar sem verificação quando o serviço cai anularia a proteção justamente no cenário em que ela seria mais necessária (ex.: ataque coordenado que também sobrecarrega o `siteverify`).

**Alternatives considered**:

- Falha aberta (permitir envio se o `siteverify` não responder) — rejeitada pelo usuário na clarificação; priorizaria disponibilidade sobre segurança num canal historicamente sujeito a spam.
- Cache de resultado do `siteverify` por IP — fora de escopo; o rate limit por IP já existente (`CheckPublicRateLimitRepository`) cobre o cenário de abuso repetido.

---

## R5 — Anexos públicos reais (reaproveitar `StorageService`, padrão já usado no fluxo autenticado)

**Decision**: Hoje `POST /ouvidoria/publico/anexos` grava metadados num `Map` em memória, **sem `tenantId`**, perdido a cada restart do processo (`store-public-temp-anexo.repository.ts`); `BindAnexosPublicosRepository` é stub — nunca cria `ManifestacaoAnexo`. Réplica do padrão já em produção no fluxo autenticado (`PresignAnexoUseCase` → `ConfirmAnexoUseCase`):

1. **Nova tabela Prisma** `ManifestacaoAnexoPublicoTemp`: `id`, `tenantId`, `storageKey`, `fileName`, `mimeType`, `sizeBytes`, `expiresAt`, `consumedAt?`, `createdAt`. Substitui o `Map` em memória — sobrevive a restart, é auditável, e scoped por tenant (gap de isolamento corrigido).
2. `UploadAnexoPublicoUseCase.execute()`: valida `sizeBytes`/`mimeType` contra os limites **já vigentes internamente** (`MAX_ANEXO_BYTES` = 30MB, `ALLOWED_MIME_TYPES` de `ouvidoria-anexo.constants.ts` — Clarifications da fase de planejamento, alinhar ao padrão interno em vez do limite mais permissivo da v1), gera `anexoId`, `storageKey = storage.buildStorageKey(tenantId, 'publico-temp', anexoId)`, chama `storage.presignUpload(...)`, persiste o registro temporário via Prisma, devolve `{ tempId, uploadUrl, expiresIn }`.
3. `BindAnexosPublicosRepository.execute(manifestacaoId, tempIds)`: para cada `tempId` válido (mesmo `tenantId`, não expirado, não consumido), cria `ManifestacaoAnexo` real (`kind: file`, `uploadConfirmed: true`, `storageKey` copiado do temporário) e marca o temporário como `consumedAt`. Chamado pelo `manifestacaoId` retornado por `create()` (ver R2, item 5) — não mais por `protocol`.
4. Cliente faz `PUT` direto na `uploadUrl` presignada (em vez do multipart `POST` da v1) — mesma UI de arrastar/soltar, só muda o transporte.

**Rationale**: FR-009/FR-010/SC-006 exigem persistência real e acessível — o stub atual não cumpre nenhum dos dois (não persiste arquivo, não sobrevive restart, não isola por tenant). Reaproveitar `StorageService` evita reimplementar S3/fallback local do zero.

**Alternatives considered**:

- Manter multipart `POST` direto para a API (como a v1) — rejeitado: a API v2 já padronizou em presigned upload para o fluxo autenticado; manter dois padrões de upload no mesmo módulo é inconsistente.
- Backend com fila (SQS/BullMQ) para processar upload assíncrono — fora de escopo; volume de anexos de ouvidoria pública não justifica a complexidade nesta entrega.

---

## R6 — Identidade visual: paleta própria do tenant, não a Mint do workspace

**Decision**: `apps/publico` mantém a paleta emerald/teal/blue já validada na v1 (FR-019 — paridade visual exigida pela spec). Não aplicar `mint-palette.mdc`.

**Rationale**: `apps/publico` é a face pública do tenant AGEMAN (citizen-facing), não uma tela administrativa interna do workspace CI v2 — decisão de produto já confirmada com o usuário antes do `/speckit-specify`. Documentado no Constitution Check como desvio justificado.

**Alternatives considered**: Nenhuma — decisão de produto já fechada; registrada aqui só para rastreabilidade.

---

## R7 — Cliente HTTP: `@ci/shared` sem fluxo de sessão

**Decision**: Migrar de `fetch` cru (implementação atual) para `createApiClient` de `@ci/shared` (mesma função usada por `@ci/web`/`@ci/admin-saas`), configurado **sem** chamar `setAccessToken`/`registerSessionLostHandler` — o portal público não tem login, então não há sessão a "perder". `getTenantId` retorna o slug fixo do tenant (`ageman`, via `VITE_TENANT_ID`/`tenant-config.ts`), igual ao padrão de build por tenant já usado. Erros HTTP (400/404/429) são tratados como erro de request normal na UI (mensagem inline), não como redirecionamento de sessão.

**Rationale**: Reaproveita a mesma função testada já usada nos outros dois apps do monorepo (consistência de convenção), sem forçar conceitos de autenticação que não existem no fluxo público.

**Alternatives considered**:

- Manter `fetch` cru (implementação atual do MVP) — rejeitado: diverge da convenção do monorepo sem ganho real.
- `axios` (como a v1) — rejeitado: introduziria uma dependência HTTP que o resto do v2 não usa.

---

## R8 — Composição sem React Router (paridade com `PublicApp.tsx` da v1)

**Decision**: `main.tsx` espelha `PublicApp.tsx` da v1: `QueryClientProvider` + `AccessibilityProvider` + estado interno `screen: 'welcome' | 'chatbot' | 'consulta'`, orquestrado por eventos customizados (`start-manifestation`, `open-review-modal`, `reset-chatbot`, `open-consulta`) — sem `react-router`, igual à v1 AGEMAN (app de página única com poucas telas, sem necessidade de URLs profundas).

**Rationale**: Preserva a UX exata da v1 (FR-019) com o menor código possível; introduzir roteamento agora sem necessidade de produto (nenhuma URL profunda é exigida pela spec) seria complexidade não solicitada.

**Alternatives considered**: `react-router` com rotas `/`, `/manifestacao`, `/consulta` — rejeitado nesta entrega: nenhum requisito pede URLs compartilháveis/deep-link; pode ser reavaliado numa iteração futura sem quebrar a estrutura de componentes.

---

## R9 — Avaliação de dívida técnica aplicada (skill `tech-debt`)

Framework: `Prioridade = (Impacto + Risco) × (6 − Esforço)`, escala 1–5.

| Item | Categoria | Impacto | Risco | Esforço | Prioridade | Ação nesta feature |
| --- | --- | --- | --- | --- | --- | --- |
| `apps/publico` fora do pipeline de build/deploy | Infraestrutura | 5 | 5 | 2 | **40** | **Corrigido** — `turbo.json`/`Dockerfile`/`compose.dev.yaml`/workflow |
| Anti-robô stub (`token.length >= 4`) | Código/Segurança | 4 | 5 | 2 | **36** | **Corrigido** — reCAPTCHA v3 real |
| Anexos públicos sem persistência real | Código/Arquitetura | 5 | 4 | 3 | **27** | **Corrigido** — `StorageService` + tabela Prisma |
| `createdByUserId` = usuário arbitrário do tenant | Código (bug) | 2 | 3 | 1 | **25** | **Corrigido** — fica `undefined` |
| Status interno exposto na consulta pública | Código/Privacidade | 3 | 2 | 1 | **25** | **Corrigido** — label público dedicado |
| Categorias/contato/endereço não persistidos | Código/Dados | 4 | 3 | 3 | **21** | **Corrigido** — schema + repository expandidos |
| Rate limit e temp-store em memória (`Map`, não sobrevive a restart, não escala horizontalmente) | Arquitetura | 2 | 2 | 4 | **8** | **Aceito/postergado** — anexos migram para Prisma (ganho parcial); rate limit por IP continua em memória. Revisitar só se a API v2 precisar escalar horizontalmente (múltiplas instâncias) |

**Rationale**: Os 6 itens de maior prioridade (21–40) são todos resolvidos como parte natural desta feature — não é trabalho extra "de dívida técnica" isolado, é a própria expansão de paridade pedida pelo usuário. O item de menor prioridade (8) fica documentado e conscientemente postergado: o custo de trocar `Map` in-process por armazenamento distribuído (Redis/Postgres) para o rate limiter não se justifica enquanto a API roda em instância única — mesma lógica já aplicada em outras features do workspace (ex.: `DiretorCacheService` do módulo Diretor).

---

## Resumo de arquivos tocados (API)

| Arquivo | Mudança |
| --- | --- |
| `ouvidoria.schemas.ts` | `programa` 6 valores; + `tipo`, `email`, `mobilePhone`, `homePhone`, `businessPhone` |
| `ouvidoria.mapper.ts` | + `PUBLIC_MANIFESTACAO_STATUS_LABEL` |
| `lib/ageman-catalog.ts` | + `AGEMAN_PROGRAMA_LABEL['6']` |
| `lib/numero-personalizado.ts` | + `PROGRAMA_CODE.institucional = '6'` |
| `repository/create-manifestacao-publica.repository.ts` | persiste tipo/contato/endereço; corrige `createdByUserId`; retorna `id` |
| `repository/verify-public-challenge.repository.ts` | reCAPTCHA v3 real + bypass dev + falha fechada |
| `repository/bind-anexos-publicos.repository.ts` | cria `ManifestacaoAnexo` real a partir do temp Prisma |
| `repository/store-public-temp-anexo.repository.ts` + `find-public-temp-anexo.repository.ts` | Prisma em vez de `Map` |
| `use-cases/criar-manifestacao-publica.use-case.ts` | mapeia `tipo`; bind por `manifestacaoId` |
| `use-cases/upload-anexo-publico.use-case.ts` | presign real via `StorageService`; limites alinhados ao padrão interno |
| `use-cases/consulta-publica.use-case.ts` | usa `PUBLIC_MANIFESTACAO_STATUS_LABEL` |
| `prisma/schema/manifestacao.prisma` + migration | + `model ManifestacaoAnexoPublicoTemp` |
