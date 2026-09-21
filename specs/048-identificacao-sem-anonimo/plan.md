# Implementation Plan: Identificação sem anônimo + e-mail

**Branch**: `048-identificacao-sem-anonimo` | **Date**: 2026-09-17 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `civ2-docs/specs/048-identificacao-sem-anonimo/spec.md`

## Summary

No assistente interno de nova manifestação (`ci-client-v2/apps/web`, módulo `ouvidoria`), remover os dois cards de escolha «Permanecer anônimo» / «Quero me identificar» da etapa Identificação — o formulário de dados do manifestante passa a ficar sempre visível. Nome completo passa a ser obrigatório em toda manifestação criada por esse fluxo, **exceto** para o tipo **denúncia** (`whistleblower`), que continua permitindo relato sem identificação pessoal. Um único campo **E-mail** (opcional) passa a viver dentro do bloco Identificação, absorvendo o campo hoje solto «E-mail para resposta» — sem renomear o campo subjacente (`replyEmail`), apenas reposicionando-o na UI e no schema de validação. Nenhuma migração de dado é necessária: `isAnonymous` continua existindo (compatibilidade com registros legados — FR-011), mas passa a ser sempre gravado como `false` pelas rotas de rascunho/atualização deste fluxo, e deixa de ser o campo que decide se `requesterFullName` é obrigatório (quem decide agora é `type`). O portal público (`apps/publico`, AGEMAN — spec 043) e seu schema (`criarManifestacaoPublicaBodySchema`) **não são tocados**.

## Technical Context

**Language/Version**: TypeScript 5.9+ (Node.js 22 LTS) — API e Client

**Primary Dependencies**:
- API (`ci-api-v2`): NestJS 11, Fastify, Pino, Zod v4 (`nestjs-zod`), Prisma 7, PostgreSQL
- Client (`ci-client-v2`, `apps/web` apenas — `apps/publico` fora de escopo): React 19, Vite 8, Tailwind v4, `@ci/ui` (shadcn/ui)

**Storage**: PostgreSQL via Prisma — **nenhuma migração**. Colunas já existentes em `Manifestacao` (`isAnonymous`, `requesterFullName`, `replyEmail`) mudam apenas de **regra de validação/valor padrão na camada de aplicação** (Zod), não de schema de banco.

**Testing**: Jest (unit) em `ci-api-v2` para `ouvidoria.schemas.spec.ts` (TDD RED→GREEN→REFACTOR); Vitest em `ci-client-v2/apps/web` para `manifestacao-draft.schema.test.ts` e `ManifestacaoStepOneForm.validation.test.tsx`

**Target Platform**: Web (SPA multi-tenant, `apps/web`), API REST server-side

**Project Type**: Web application — alteração pontual dentro do módulo `ouvidoria` já existente em API e client (`apps/web`); nenhum módulo novo

**Performance Goals**: Sem meta nova — mudança é de UI (menos um passo de decisão) e de regra de validação, sem novo I/O

**Constraints**:
- Zero migração de dados/schema Prisma
- `apps/publico` (portal público AGEMAN) e sua spec 043 **não podem ser alterados** por esta feature (FR-008)
- Registros e rascunhos anônimos já existentes **não podem ser alterados retroativamente** (FR-011)
- O campo de e-mail não pode ser renomeado no banco/DTO (`replyEmail` permanece o nome do campo — evita tocar `ManifestacaoRequesterCard.tsx`, `manifestacao.mapper.ts`, geração de PDF/DOCX, e o card de detalhe "Manifestante", que já leem `replyEmail`)

**Scale/Scope**: 1 módulo já existente (`ouvidoria`), ~2 arquivos de schema (API + client) e ~2 arquivos de componente (form + página wizard) alterados; nenhum endpoint novo

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Princípio | Avaliação |
|---|---|
| I. Spec-Driven Development | ✅ Spec 048 clarificada (2 sessões: `/speckit-specify` + `/speckit-clarify`), plan segue o fluxo Spec Kit |
| II. Test-First (NON-NEGOTIABLE) | ✅ `ouvidoria.schemas.spec.ts` (API) e `manifestacao-draft.schema.test.ts` + `ManifestacaoStepOneForm.validation.test.tsx` (client) ganham casos RED→GREEN antes da implementação — skills `tdd` + `testing-conventions` na fase `/speckit-implement` |
| III. Stack fixa | ✅ Só Zod (`nestjs-zod` na API, Zod v3 no client) — nenhuma lib nova; reaproveita `@ci/ui` já instalado |
| IV. Multi-tenant e licenças | ✅ N/A — nenhuma entidade/tabela nova; nenhuma checagem de tenant nova (reaproveita o fluxo de draft já existente, já tenant-scoped) |
| V. Clean code e modularidade | ✅ Alteração cirúrgica dentro dos arquivos já existentes do módulo `ouvidoria` (`ouvidoria.schemas.ts`, `ManifestacaoStepOneForm.tsx`, `manifestacao-draft.schema.ts`); nenhum arquivo novo de use-case/repository necessário |

**Skills aplicadas nesta fase**:
- `zod-validation-sanitization` — regra condicional (`superRefine`) trocando o gatilho de `isAnonymous` para `type === 'whistleblower'`, em ambos os schemas (API Zod v4 + client Zod v3, mantidos espelhados conforme comentário já existente no client: "Espelha ci-api-v2/...")
- `ci-api-arquitetura` — confirma que a mudança cabe inteiramente em `ouvidoria.schemas.ts` (camada de validação), sem exigir novo use-case/repository
- `ui-ux-pro-max` + `vite-react-best-practices` — remoção dos cards de escolha e reposicionamento do campo E-mail dentro do grid de Identificação, seguindo a paleta Mint e os componentes `Field`/`SectionHeader` já existentes no arquivo (nenhum componente novo)
- `testing-conventions` — atualizar os `describe` blocks já existentes (`ouvidoria.schemas replyEmail opcional`, `identificação — condicional isAnonymous`) em vez de criar suítes paralelas

**Resultado**: PASS, sem violações a justificar em Complexity Tracking.

## Project Structure

### Documentation (this feature)

```text
civ2-docs/specs/048-identificacao-sem-anonimo/
├── plan.md              # este arquivo
├── research.md          # Phase 0
├── data-model.md         # Phase 1
├── quickstart.md        # Phase 1
├── contracts/           # Phase 1
│   └── ouvidoria-identificacao.md
└── tasks.md             # Phase 2 (/speckit-tasks — não criado aqui)
```

### Source Code (repository root)

```text
ci-api-v2/
└── src/modules/ouvidoria/
    ├── ouvidoria.schemas.ts        # ALTERADO — draftFieldsSchema.isAnonymous default true→false;
    │                                #   refineIdentifiedManifestacaoRequiresName → refineRequesterNameRequiredUnlessWhistleblower
    │                                #   (gatilho: type === 'whistleblower', não mais isAnonymous)
    └── ouvidoria.schemas.spec.ts   # ALTERADO — casos de 'identificação — condicional isAnonymous'
                                     #   migram para 'identificação — nome obrigatório exceto denúncia'

ci-client-v2/apps/web/src/modules/ouvidoria/
├── schemas/
│   └── manifestacao-draft.schema.ts   # ALTERADO — mesmo superRefine espelhado da API
├── components/
│   └── ManifestacaoStepOneForm.tsx    # ALTERADO — remove os 2 cards de escolha;
│                                       #   grid de campos do manifestante sempre visível (remove `{!form.isAnonymous && (...)}`);
│                                       #   campo "E-mail" movido do Card solto acima para dentro do grid de Identificação
├── pages/
│   └── ManifestacaoWizardPage.tsx     # ALTERADO — `emptyForm.isAnonymous: true` → `false`
└── __tests__/
    ├── manifestacao-draft.schema.test.ts        # ALTERADO — mesmos casos espelhados do lado API
    └── ManifestacaoStepOneForm.validation.test.tsx  # ALTERADO — remove asserts sobre os cards; novos asserts para exceção denúncia + campo E-mail no bloco Identificação

# NÃO alterados (fora de escopo — FR-008/FR-011):
# ci-client-v2/apps/publico/**                              — portal público AGEMAN (spec 043)
# ci-api-v2/.../criarManifestacaoPublicaBodySchema           — schema do portal público
# ci-client-v2/apps/web/.../ManifestacaoRequesterCard.tsx    — branch `if (view.isAnonymous)` preservado (legado)
# ci-api-v2/.../confirm-manifestacao.use-case.ts             — não revalida campos (validação já ocorre no save do rascunho)
```

**Structure Decision**: Nenhum pacote novo, nenhuma dependência nova, nenhum arquivo de use-case/repository novo. Toda a mudança cabe na camada de **validação** (`*.schemas.ts` em ambos os lados, espelhados conforme já é convenção no projeto) e na camada de **apresentação** (`ManifestacaoStepOneForm.tsx`), dentro do módulo `ouvidoria` já existente em `ci-api-v2` e `ci-client-v2/apps/web`. `apps/publico` permanece intocado.

## Complexity Tracking

*Sem violações da constitution a justificar — tabela omitida.*
