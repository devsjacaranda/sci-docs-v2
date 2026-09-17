# Research: Níveis de Acesso Ouvidoria AGEMAN (403)

**Phase 0** — todas as decisões abaixo resolvem os pontos técnicos abertos após a spec (nenhum `NEEDS CLARIFICATION` de negócio restava; o que resta aqui é **como implementar**, não **o quê**).

## 1. Onde aplicar a checagem de acesso: guard NestJS vs. assert manual no use-case

**Decision**: Assert manual (`assertManifestacaoAccess(row, actor)`), chamado explicitamente dentro de cada use-case, logo após carregar o registro e **antes** de montar qualquer DTO de resposta.

**Rationale**: A decisão de acesso depende de um campo do próprio registro (`emissorUserId`) que só existe depois de uma consulta ao banco. Um `CanActivate` de NestJS roda antes do handler, sem acesso fácil ao registro carregado, forçando uma segunda consulta redundante (ou um guard "burro" que decora o controller mas delega tudo ao use-case de qualquer forma). O projeto já resolve exatamente esse problema com `assertProtocoloParticipant`/`assertPersonalProtocoloParticipant` (módulo `tramitacao`), chamados manualmente dentro de `ConcederGestorUseCase` e outros — mesmo formato: função pura, `ForbiddenException` explícita, sem duplicar I/O.

**Alternatives considered**:
- **NestJS Guard dedicado** (`ManifestacaoAccessGuard`): rejeitado — exigiria buscar o registro duas vezes (guard + use-case) ou acoplar o guard ao repository de forma incomum no projeto. Quebraria o padrão já estabelecido em `tramitacao`.
- **Prisma middleware/extension que filtra automaticamente por `emissorUserId`**: rejeitado — filtraria também o **detalhe** de forma silenciosa (viraria 404, não 403), violando FR-007 explicitamente. Extensions do projeto hoje só fazem tenant/soft-delete (constitution §IV), não regra de negócio de dono.

## 2. Modelagem da Concessão de Acesso (Grant)

**Decision**: Uma única tabela `OuvidoriaAcessoConcessao` com um campo `scope` (`enum OuvidoriaAcessoScope { manifestacao, emissor }`), `manifestacaoId` nullable (preenchido só quando `scope = manifestacao`) e `emissorUserId` nullable (preenchido só quando `scope = emissor`), + `granteeUserId` (sempre preenchido), + auditoria de quem concedeu/revogou.

**Rationale**: FR-004 e FR-005 pedem duas granularidades. Duas tabelas separadas duplicariam a lógica de "está ativo?"/"quem concedeu?"/revogação. Uma tabela com discriminador é o padrão idiomático (mapeia 1:1 para o `z.discriminatedUnion` do body da API — `typescript-mastery`). Idempotência (evitar concessão duplicada) é feita em código no use-case, seguindo o padrão já existente de `ConcederGestorUseCase` (`GESTOR_ALREADY_GRANTED` via `exists()` antes de `create()`), não via unique constraint do Postgres (que não distinguiria corretamente linhas revogadas de ativas sem uma constraint parcial, fora do padrão Prisma atual do projeto).

**Alternatives considered**:
- **Reaproveitar `UserTelaOverride`/`SetorTela`** (módulo `tela-permissao`): rejeitado — aquele modelo é sobre **telas** (rotas de UI), não sobre **registros de negócio** específicos; misturar os dois conceitos quebraria a separação de domínio.
- **Campo array `acessoLiberadoParaUserIds` direto em `Manifestacao`**: rejeitado — não cobre a concessão "geral por emissor" (FR-005) sem duplicar a escrita em N linhas ao criar cada nova demanda, e dificulta a revogação/auditoria (sem `createdAt`/`revokedAt`/quem concedeu).

## 3. Derivação de "chefe da ouvidoria"

**Decision**: Reaproveitar `FindModuloSetoresRepository.execute(ModuloSlug.ouvidoria)` (já existe em `modules/permissao/repository/`) para obter os setores vinculados ao módulo Ouvidoria, e checar se `actor.role === UserRole.chefe_setor` e a interseção entre `actor.chiefOfSetorIds` e os IDs desses setores é não vazia. Nova função pura `isChefeDaOuvidoria(actor, setoresDoModulo)` em `lib/is-chefe-da-ouvidoria.ts`.

**Rationale**: É exatamente a combinação validada com o usuário (role + setor vinculado ao módulo, sem role nova). O repository já existe e já é usado por `CheckModuloAccessUseCase` para o gate de módulo — reaproveitar evita duplicar a leitura de `ModuloSetor`.

**Alternatives considered**: Nova role `chefe_ouvidoria` no enum `UserRole` — descartada explicitamente pelo usuário nas clarificações.

## 4. Bypass de admins

**Decision**: Reaproveitar o `ADMIN_BYPASS_ROLES` já existente em `modules/tela-permissao/tela-permissao.types.ts` (`admin_plataforma`, `admin_tenant`, `admin_saas`).

**Rationale**: Já é o conjunto usado por `ResetSenhaAccessGuard` e por `GrantResetSenhaViewerUseCase` para o mesmo tipo de bypass. Reaproveitar a constante evita duas fontes de verdade sobre "quem é admin" no projeto.

## 5. Staleness de `chiefOfSetorIds`/`setorIds` no JWT

**Decision**: Aceitar a mesma semântica já existente na plataforma — `chiefOfSetorIds` vem do payload do JWT (`jwt.strategy.ts`), atualizado no login/refresh, não recalculado a cada request. Um chefe que perde a chefia continua com o bypass até expirar/renovar o token, exatamente como já acontece hoje com `setorIds` para acesso a módulo.

**Rationale**: Não é uma regressão introduzida por esta feature — é o comportamento já aceito no restante da plataforma (`ModuloPermissaoGuard` também confia em `setorIds` do JWT). Resolver isso de forma diferente só para Ouvidoria criaria uma inconsistência de segurança percebida entre módulos, sem que o usuário tenha pedido isso.

**Alternatives considered**: Recalcular `chiefOfSetorIds` do banco a cada request — rejeitado por escopo (mudaria o comportamento de auth global do projeto, fora do pedido desta feature) e custo (consulta extra em toda request).

## 6. UI de concessão e "quem tem acesso" (client)

**Decision**: Um novo `Card` (`ManifestacaoAcessoCard`) na página de detalhe (`ManifestacaoDetailPage.tsx`), abaixo do card de anexos, mostrando:
- Emissor (nome, `Badge` "Dono")
- Indicação textual de que chefes da ouvidoria e admins também têm acesso (grupo, sem listar nomes individuais — evita expor lista de todos os chefes/admins do tenant sem necessidade)
- Lista de concessões ativas (`granteeName` + `Badge` com o escopo: "Esta demanda" ou "Todas as demandas de {emissor}") + botão de revogar (`AlertDialog` de confirmação, seguindo a regra shadcn de nunca revogar sem confirmação)
- Botão "Conceder acesso" (visível só quando o viewer atual é o emissor, chefe da ouvidoria ou admin — o servidor sempre revalida independentemente do que o client mostra) abrindo um `Dialog` com `Command`/Combobox para buscar o usuário destinatário por nome (resolve para UUID internamente — o UUID nunca é digitado manualmente pelo usuário final) e um `ToggleGroup` de 2 opções para o escopo (Esta demanda / Todas as demandas deste emissor).

**Rationale**: Reaproveita exatamente os primitivos shadcn já usados no restante do módulo (`Card`, `Badge`, `AlertDialog` já em uso nas ações de manifestação). Busca por nome em vez de UUID cru é exigência básica de UX (`ui-ux-pro-max` — forms) mesmo com o contrato de API sendo por UUID.

**Alternatives considered**: Tela dedicada de "gestão de acessos" separada do detalhe — rejeitada para o MVP porque a spec pede a visão "na própria tela da demanda" (US6); pode ser revisitado em iteração futura se o volume de concessões por demanda crescer muito.

## 7. Erro 403 no client

**Decision**: Novo código de erro `OUVIDORIA_ACCESS_DENIED` em `ouvidoria-errors.ts` (API) e novo `CODE_SPECS.OUVIDORIA_ACCESS_DENIED` (client, `kind: 'permission'`, `surface: 'page'`), com mensagem distinta de `MODULO_SETOR_DENIED`: "Você não tem acesso a esta demanda. Peça ao emissor, a um chefe da Ouvidoria ou a um administrador para liberar seu acesso." Renderizado pelo `OuvidoriaErrorAlert` já existente (não precisa de um novo componente de página — `AccessDenied403` fica reservado para o bypass de **módulo**, não de **registro**, para não confundir as duas causas de 403 distintas).

**Rationale**: Mantém consistência com o mapeador de erro já existente (`mapOuvidoriaError`) e evita introduzir um segundo padrão visual de "acesso negado" sem necessidade — a spec não pede uma UI de "solicitar acesso" nesta tela (diferente do fluxo de módulo, que já tem `requestModulePermission`).

**Alternatives considered**: Reaproveitar `AccessDenied403` com um `variant="record"` novo, com botão "solicitar acesso" que já dispara uma notificação ao emissor — desejável, mas não pedido em nenhum FR/SC da spec; registrado como possível melhoria futura, não incluído nas tasks desta feature para não expandir escopo sem pedido explícito.

## 8. Auditoria das concessões/revogações

**Decision**: Registrar concessão e revogação como novos valores de `ManifestacaoEventoTipo` (`access_granted`, `access_revoked`) na timeline já existente (`ManifestacaoEvento`), com `autorUserId` = quem concedeu/revogou (via `resolveUserTableId` + `withActorPayload` quando o autor é admin sem linha em `User`, conforme regra `admin-tenant-user-fk`).

**Rationale**: A timeline de eventos já é o mecanismo de auditoria visível do domínio (aparece em `ManifestacaoTimeline` no client). Reaproveitar em vez de criar uma tabela de log paralela atende OWASP A09 (Security Logging) com o menor custo de implementação, e fica visível para quem audita a demanda sem tela nova.

**Alternatives considered**: Tabela de auditoria dedicada (`OuvidoriaAcessoAuditLog`) — descartada por redundância; a tabela `OuvidoriaAcessoConcessao` já guarda `createdAt`/`revokedAt`/`grantedByUserId`/`revokedByUserId`, e a timeline cobre a visibilidade humana.

## 9. Feature flag por tenant (FR-014 a FR-020)

**Decision**: Nova tabela `OuvidoriaAcessoFeatureFlag` (1 linha por tenant, `enabled: Boolean @default(true)`), seguindo exatamente o padrão já usado em `TenantLicenca.active` (booleano por tenant, alterado via `Patch` idempotente). Ausência de linha para um tenant é tratada como `enabled = true` — evita qualquer migração/backfill para tenants existentes no deploy desta feature. A checagem do flag é o **primeiro passo** de `assertManifestacaoAccess` e do filtro de `list-manifestacoes`: se desligado, retorna acesso liberado (`reason: 'flag-disabled'`) sem avaliar dono/chefe/grant — kill-switch completo, conforme FR-015.

**Rationale**: Reaproveita um padrão já validado no monorepo (`TenantLicenca`) em vez de inventar um mecanismo de feature flag genérico (que não foi pedido — ver Out of Scope da spec). Curto-circuitar a checagem no primeiro passo garante que "desligado" realmente significa "nenhuma das regras desta feature roda", sem risco de algum caminho de código esquecer de checar o flag depois de checar dono/chefe (evitaria bugs de "meio ligado").

**Alternatives considered**:
- **Campo `active` em `ModuloSetor`/reaproveitar licença existente** (`LicencaSlug`): rejeitado — o flag não é uma licença comercial (não controla cobrança/contrato), é um kill-switch operacional; misturar os dois conceitos confundiria o catálogo de licenças exibido ao cliente.
- **Flag global único (env var / config da plataforma)**: rejeitado explicitamente pelo usuário — precisa ser por tenant.
- **Guardar o estado do flag no JWT** (calculado no login): rejeitado — violaria SC-009/SC-010 (efeito imediato sem novo login); o flag precisa ser lido no servidor a cada request relevante, como qualquer outra configuração de tenant já é (ex.: `TenantLicenca`).

**Grant/revoke continuam funcionando com o flag desligado**: as rotas de conceder/revogar/listar acesso (FR-004/005/006/009) não checam o flag — continuam gravando/lendo dados normalmente. Somente a decisão de acesso (`assertManifestacaoAccess`) e o filtro de listagem ignoram esses dados enquanto o flag estiver desligado. Isso está alinhado com "keep_data": desligar não é destrutivo, apenas suspende a fiscalização.

**Exposição via API**: dois pares de rotas, ambos escrevendo na mesma tabela via o mesmo use case interno (`SetOuvidoriaAcessoFlagUseCase`), para não duplicar a regra de negócio:
- `GET|PATCH /ouvidoria/acesso-flag` — self-service, guardado por role `admin_tenant` (+ `admin_plataforma` legado, já tratado como equivalente institucional), tenant sempre resolvido por `getRequestContext().tenantId!` (nunca por parâmetro de rota, para impedir um `admin_tenant` de alterar outro tenant — FR-017).
- `PATCH /admin/tenants/:tenantId/feature-flags/ouvidoria-acesso` — módulo `admin-plataforma` (app admin-saas), guardado por role `admin_saas`, espelhando exatamente `PATCH /admin/tenants/:tenantId/licencas/:licencaSlug` já existente (`toggle-tenant-licenca.use-case.ts`). O estado do flag também é incluído na resposta de `GET /admin/tenants/:tenantId` (get-tenant-detail), do mesmo jeito que as licenças já aparecem lá.

**Onde a lib do flag mora**: `modules/ouvidoria/lib/get-ouvidoria-acesso-flag.ts` (leitura, usado por `assertManifestacaoAccess` e pela rota self-service) e `modules/ouvidoria/use-cases/set-ouvidoria-acesso-flag.use-case.ts` (escrita, exportado pelo `OuvidoriaModule` e injetado no `AdminPlataformaModule` para a rota de `admin_saas` — mesma direção de dependência já usada para outros casos de módulo-cruzando-módulo no projeto, sem import circular).

**UI (client)**:
- App admin-saas: novo toggle em `TenantDetailPage.tsx`, mesmo componente visual do `LicencaToggle` (Badge "Ativo"/"Inativo" + botão Ativar/Desativar), numa seção separada rotulada "Recursos" (para não confundir com o catálogo de licenças comerciais).
- App web (`apps/web`): novo toggle na tela já existente "Configurações da instituição" (`platform-tenant-config` / `PlatformTenantConfigPanel.tsx`), visível apenas para `admin_tenant`, reaproveitando o mesmo `Status`/`StatusBanner` já usado nesse painel para feedback de sucesso/erro.

## 10. Correção PO (2026-09-16) — listagem não esconde; 403 só no acesso direto

**Decision**: `GET /ouvidoria/manifestacoes` **não** aplica filtro de visibilidade por dono/emissor/grant. Qualquer operador com módulo Ouvidoria recebe todas as manifestações do tenant (mesmo universo dos KPIs). `assertManifestacaoAccess` / `assertForUser` continua nas ações diretas (detalhe, PATCH, DELETE, PDF/DOCX, anexos, encaminhar/responder/encerrar) e devolve `403 OUVIDORIA_ACCESS_DENIED` quando o ator não é dono, não tem grant e não é chefe/admin.

**Rationale**: A interpretação original da US1 (filtro silencioso na lista) estava **errada** — decisão explícita do product owner. Na prática, KPIs mostravam ~3669 registros e a tabela só 1 rascunho do próprio operador. A lista deve refletir o mesmo universo; o 403 aparece ao **abrir/editar** a demanda alheia, não ao listar.

**Sobrescreve**: filtro `mode: 'restricted'` em `resolveListVisibility` / `ListManifestacoesUseCase` / `ListManifestacoesRepository`; FR-008 e US1 originais (listagem que omitia linhas). Contrato atualizado em `contracts/ouvidoria-visibilidade-listagem-e-403.md`.
