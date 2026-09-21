# Research — 044 Emissor automático ao criar demanda AGEMAN

**Date**: 2026-09-14
**Spec**: [spec.md](./spec.md)

## R1 — Resolver o emissor no use-case, não no schema Zod

**Decision**: Extrair uma função pura `resolveEmissorUserId` em `ci-api-v2/src/modules/ouvidoria/lib/resolve-emissor-user-id.ts`, chamada por `CreateManifestacaoDraftUseCase` e `UpdateManifestacaoDraftUseCase`. O schema Zod **continua aceitando** `emissorUserId` opcional (`z.uuid()`); a regra de negócio (operador institucional → sempre o autenticado; administrador da instituição → valor pedido se for um operador real, senão vazio) vive no use-case.

```text
resolveEmissorUserId({
  actor: { userId, role },
  requestedEmissorUserId?: string,
  phase: 'draft' | 'confirmed',
}) → string | undefined
```

- `phase === 'confirmed'` → retorna `undefined` no sentido de **não aplicar patch** (o chamador não toca `emissorUserId`).
- Operador institucional (`resolveUserTableId` devolve id) → **sempre** esse id; `requestedEmissorUserId` é ignorado (FR-003, sem 400).
- Administrador da instituição / `admin_saas` (`resolveUserTableId` devolve `undefined`) → se `requestedEmissorUserId` for um usuário do tenant (já validado por `FindEmissorUserRepository`), usa esse id; senão `undefined` (emissor vazio).

**Rationale**: Constitution V + `clean-architecture` — regra de negócio no use-case, não no pipe Zod. `zod-validation-sanitization` valida forma (UUID), não política de ator. A função pura é testável sem Nest/Prisma (TDD, `CT-OUV-EMISSOR-016`).

**Alternatives considered**:

- Transform no schema Zod com o ator — rejeitado: schema não tem `req.user`; `createZodDto` + `transform` já é exceção no projeto.
- Rejeitar 400 quando operador envia outro id — rejeitado na clarificação (FR-003): sobrescrita silenciosa.
- Novo campo/FK para `AdminTenant` — rejeitado na clarificação (fora de escopo; viola `admin-tenant-user-fk.mdc`).

---

## R2 — Sem migration: auditoria do administrador via `dadosAdicionais`

**Decision**: Não alterar `manifestacao.prisma`. `emissorUserId` permanece `String?` → `User`. Quando o criador não tem linha em `User`, o emissor fica `null`. A identidade real é mesclada em `dadosAdicionais` com `withActorPayload(userId, role)` (padrão já usado em Gabinete/Tramitação), **somente** se o ator não for operador institucional — não sobrescreve chaves de negócio já existentes (`jaEntrouContatoConcessionaria`, `formaAtendimento`, etc.).

O detalhe **não** passa a exibir `actorId`/`actorRole` (SC-007: auditoria interna, não nesta tela). Emissor no detalhe continua `emissorLabel` / `—`.

**Rationale**: Spec e constitution IV (`admin-tenant-user-fk`): nunca gravar `AdminTenant.id` em FK de `User`. `ManifestacaoEvento.autorUserId` também aponta para `User` — não serve para `admin_tenant`. JSON já existente evita migration.

**Alternatives considered**:

- Evento `ManifestacaoEvento` com `autorUserId` nulo + título “criado por admin” — possível, mas exige novo `tipo` ou texto livre sem contrato; `dadosAdicionais` já é o envelope JSON do módulo.
- Coluna nova `emissorActorId`/`emissorActorRole` — rejeitado: mudança de schema sem ganho de produto visível.

---

## R3 — PATCH de rascunho recebe o ator; pós-confirmação ignora emissor

**Decision**: `PATCH /ouvidoria/manifestacoes/:id` hoje **não** passa `req.user` para `UpdateManifestacaoDraftUseCase`. Passa a passar `{ userId, role }` (mesmo padrão do `POST`). Enquanto `status === draft`, o use-case **recalcula** o emissor com `resolveEmissorUserId(..., phase: 'draft')`. Quando `status !== draft` (confirmação já ocorreu: tipicamente `in_review`), o patch **omite** `emissorUserId` em `collectManifestacaoScalarUpdate` — demais campos continuam editáveis (`isManifestacaoEditable` não muda).

`ConfirmManifestacaoUseCase` não altera emissor (já está gravado no último PATCH/POST do rascunho).

**Rationale**: Clarificação: imutável só após confirmação; recálculo automático no rascunho. O detalhe já mostra Emissor como `ManifestacaoMetaItem` (somente leitura). O risco real é o wizard de edição (`/ouvidoria/manifestacoes/:id`) e o PATCH parcial do draft — o backend é a fonte da verdade.

**Alternatives considered**:

- Tornar a manifestação inteira não-editável após confirmar — rejeitado: fora de escopo; outros campos (assunto, categoria) já têm edição inline em `in_review`.
- `isManifestacaoEditable` passar a bloquear só o emissor — a regra fica no use-case de update, sem mudar o helper global (menor blast radius).

---

## R4 — Dois modos de UI no mesmo `Field` (sem componente novo)

**Decision**: Não adicionar componente shadcn. Reusar `Field` + `Input` (somente leitura, `disabled` + `readOnly`) para operador institucional; `Field` + `Combobox` já existente para administrador da instituição **apenas em rascunho/criação**. Paleta Mint (`mint-palette.mdc`); tokens semânticos (`text-muted-foreground`, `bg-muted`). Hint do campo muda:

| Ator / fase | Controle | Hint |
| --- | --- | --- |
| Operador institucional (sempre) | Texto somente leitura com `user.name` | “Emissor atribuído automaticamente a quem está registrando.” |
| Admin instituição, rascunho | Combobox; opção padrão “eu mesmo” (`__self__`) pré-marcada | “Padrão: você. Pode escolher um operador do tenant.” |
| Admin instituição, pós-confirmação | Texto somente leitura (`emissorLabel` ou “—”) | sem ação |

`GET /ouvidoria/usuarios-emissores` só é chamado quando o combobox é necessário (`role === 'admin_tenant' \|\| role === 'admin_saas'` e status rascunho/criação). Operador institucional não dispara a lista.

**Rationale**: `ui-ux-pro-max` + `shadcn` — compose, don’t reinvent. `react-vite-best-practices` — não criar rota/chunk novo. O teste atual `CT-OUV-EMISSOR-CLIENT-006` trata `isPlatformAdmin` como se fosse admin da instituição; isso está **errado** (`isPlatformAdmin` também é `admin_plataforma`, que **tem** linha em `User`). A UI passa a decidir por `user.role` (`admin_tenant` / `admin_saas` vs demais).

**Alternatives considered**:

- Esconder o campo para operador — rejeitado na clarificação (Q3: somente leitura).
- Novo componente `EmissorField` em `@ci/ui` — rejeitado: um `if` no form existente é suficiente (clean-code: não extrair até haver segundo uso).

---

## R5 — Sentinela `__self__` só no client; API nunca recebe id de `AdminTenant`

**Decision**: No client, valor interno do combobox “eu mesmo” = literal `__self__`. O schema Zod do draft (`manifestacao-draft.schema.ts`) aceita `uuid | '' | '__self__'` e **transforma** `''`/`__self__` em `undefined` antes do POST/PATCH. A API **não** adiciona o literal — continua `z.string().uuid().optional()`. Operador institucional **omite** `emissorUserId` no body (o backend força o autenticado).

**Rationale**: `zod-validation-sanitization` — sanitizar no schema do client; API não precisa conhecer sentinela de UI. OWASP A01: nunca confiar no id enviado pelo operador.

**Alternatives considered**:

- Enviar o `user.id` do `admin_tenant` como UUID — rejeitado: causa 500 (`FindEmissorUser` / FK `User`).
- `z.null()` no body — desnecessário; omitir é o contrato atual (“opcional”).

---

## R6 — IDs de teste e regressão dos CT-OUV-EMISSOR existentes

**Decision**: Manter a série `CT-OUV-EMISSOR-*` / `CT-OUV-EMISSOR-CLIENT-*`. Novos: `016` (resolve puro), `017` (create sobrescreve operador), `018` (create admin sem id → vazio + `dadosAdicionais.actor*`), `019` (update draft recalcula), `020` (update confirmado ignora emissor), `021` (PATCH passa actor no controller). Client: `008` (operador readonly), `009` (admin `__self__` não envia id), `010` (admin troca envia uuid). Reescrever `CT-OUV-EMISSOR-007/008/CLIENT-005/006` que hoje exigem select livre para operador.

**Rationale**: Constitution II — TDD; `testing-conventions` — mesmo prefixo do domínio.

---

## Skills aplicadas neste plano

| Skill | Efeito no desenho |
| --- | --- |
| `clean-architecture` | Regra de emissor no use-case/lib puro; controller só traduz HTTP → actor |
| `clean-code` | Uma função, um propósito; nomes `resolveEmissorUserId` / `phase` |
| `typescript-mastery` | `phase` como union literal; retorno `string \| undefined` (nunca id de admin) |
| `zod-validation-sanitization` | UUID na API; sentinela + `transform` só no client |
| `nestjs-best-practices` | Constructor injection; actor no update; sem lógica no controller |
| `fastify-best-practices` | Sem rota nova; mesmo ciclo POST/PATCH já existente |
| `ui-ux-pro-max` + paleta Mint | Campo readonly vs Combobox; sem paleta “vibrant” genérica do CLI |
| `shadcn` | `Field` + `Input`/`Combobox` já instalados; sem `npx shadcn add` |
| `react-vite-best-practices` | Sem rota lazy nova; fetch de emissores só no ramo admin |
| `owasp-security` | A01: servidor ignora emissor do operador; validação de tenant no admin |
| `reset-senha` | Não aplicável — não usada |
