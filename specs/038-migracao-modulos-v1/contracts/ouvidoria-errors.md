# Contrato — Erros da Ouvidoria

Contrato canônico para os agentes de **API** e **client** alinharem tratamento de erros da Ouvidoria (Base). **Não implementa** geração/coluna de protocolo ou IDs personalizados — outro agente cuida disso. Este arquivo só define códigos, HTTP, copy e regras de superfície.

Idioma das mensagens ao usuário: **português brasileiro**, tom institucional acessível (R-80 de regras-plataforma). Sem jargão de stack.

---

## 1. Envelope global — REUTILIZAR, não inventar

A skill `api-response-standard` descreve RFC 9457 (`application/problem+json`). **Esse envelope NÃO é o da ci-api-v2.** Não criar um formato paralelo.

Envelope **já usado** por `AllExceptionsFilter` (`ci-api-v2/src/common/filters/all-exceptions.filter.ts`):

```json
{
  "statusCode": 400,
  "message": "Assunto é obrigatório.",
  "error": "BadRequestException",
  "timestamp": "2026-08-24T16:00:00.000Z",
  "path": "/ouvidoria/manifestacoes",
  "code": "OUVIDORIA_VAL_SUBJECT",
  "errors": [
    { "code": "too_small", "path": ["subject"], "message": "Assunto é obrigatório." }
  ]
}
```

| Campo | Obrigatório | Uso |
|---|---|---|
| `statusCode` | sim | HTTP |
| `message` | sim | Frase única para o usuário (PT-BR). Se houver vários campos, a do primeiro issue + `errors[]` |
| `error` | sim | Nome da exceção Nest. **Não exibir no client** |
| `timestamp` | sim | ISO 8601 |
| `path` | sim | URL da requisição (já existe no filtro) |
| `code` | **sim para todo erro conhecido** | Código estável deste catálogo. Hoje falta na maioria das respostas |
| `errors` | validação Zod | Array `{ code, path, message }` — um item por campo |
| `requestId` | recomendado no 500 | Correlação com log. Hoje **não existe** no filtro |
| `retryAfterSeconds` | 429 público | Já usado no rate-limit público |

O filtro já espalha o payload da `HttpException` (`code`, `errors`, etc.) no JSON. Use-cases **DEVEM** lançar `HttpException` com `{ message, code, … }`. **NUNCA** lançar `Error` cru (vira 500 genérico).

### 1.1 O que já existe vs o que falta

| Camada | Já existe | Falta na Ouvidoria |
|---|---|---|
| Envelope HTTP | `AllExceptionsFilter` | `code` obrigatório; `requestId` no 500; mapeamento Prisma |
| Validação de borda | `ZodValidationPipe` global → 400 | Mensagens PT-BR por campo; `code` estável; hoje Zod fala inglês e `message` costuma ser `"Validation failed"` |
| Domínio (use-case) | Alguns `{ message, code }` | Códigos incompletos; várias strings sem `code`; PDF/DOCX lançam `Error` → **500** |
| Prisma | Nenhum mapper na Ouvidoria | `P2002` e `P2025` estouram **500** |
| Auth / tenant / módulo | Guards globais | Mensagens em inglês (`Licenca required`, `X-Tenant-ID header is required`) |
| 500 inesperado | `"Internal server error"` | Copy PT-BR + código rastreável; **sem** stack no JSON |
| Client | `ApiError { status, message, body }`; `useApiAction` toast genérico; 403 via `AccessDenied403` | Mapper por `code`; inline em form; banner de API fora do ar; ações (encerrar/responder/catálogo) **engolem** o erro |

**Não alterar** login, `AuthContext`, tenant middleware nem geração de protocolo.

---

## 2. Regras da API

### 2.1 O que a API DEVE fazer

1. Toda falha conhecida vira `HttpException` com `code` deste catálogo e `message` PT-BR.
2. Validação Zod: cada campo/refine tem mensagem própria e `path`. O pipe/filtro devolve `code` do campo (tabela §4) **e** `errors[]`.
3. Prisma known errors (`P2002`, `P2025`, `P2003`) → 409/404/400. **Nunca** 500.
4. 500 só para falha realmente inesperada: `code = UNEXPECTED_ERROR`. `message` amigável. Logar stack **só no servidor**.
5. Consulta pública com chave errada = **mesmo** 404 de protocolo inexistente (já está certo). Não revelar qual dos dois falhou.
6. Soft-delete / registro inexistente → 404. Não vazar existência entre tenants.

### 2.2 O que a API NÃO DEVE fazer

- Inventar envelope RFC 9457, `{ error: { code, message, details } }` aninhado, ou campo `success`.
- Devolver `"Internal server error"`, `"Validation failed"` ou issue Zod em inglês no `message`.
- Incluir `stack`, SQL, constraint name cru, storage key interna ou hash da chave de consulta no JSON.
- Lançar `new Error(...)` em use-case (PDF/DOCX hoje fazem isso).
- Tratar `P2002` de protocolo/nº institucional como 500 — mapear para 409 (a **geração** do número é de outro agente; o **mapeamento do conflito** é deste contrato).
- Alterar formato/atribuição de protocolo ou `numeroPersonalizado`.
- Alterar guards de login/JWT além de, no máximo, acrescentar `code` estável no payload já lançado.
- Expor dados do solicitante em 404/403 de consulta pública.

### 2.3 Prisma — mapeamento obrigatório

Aplicar no `AllExceptionsFilter` (preferido: uma vez para toda a API) **ou** helper `mapPrismaKnownError` usado pelos repositórios da Ouvidoria.

| Prisma | HTTP | Código | Mensagem ao usuário | Target típico |
|---|---|---|---|---|
| `P2002` | 409 | `OUVIDORIA_PROTOCOL_CONFLICT` | Este número de protocolo já existe. Recarregue e tente de novo. | `protocol` |
| `P2002` | 409 | `OUVIDORIA_NUMERO_CONFLICT` | Este número institucional já está em uso. | `numeroPersonalizado` |
| `P2002` | 409 | `OUVIDORIA_CATALOG_CODE_CONFLICT` | Já existe um item de catálogo com este código. | `OuvidoriaTipoManifestacao.codigo` |
| `P2002` | 409 | `OUVIDORIA_CATALOG_NAME_CONFLICT` | Já existe uma forma de atendimento com este nome. | `OuvidoriaFormaAtendimento.descricao` |
| `P2025` | 404 | código do recurso (`OUVIDORIA_NOT_FOUND`, `OUVIDORIA_TIPO_NOT_FOUND`, …) | Recurso não encontrado. | update/inativar/delete |
| `P2003` | 400 | `OUVIDORIA_INVALID_REFERENCE` | Referência inválida. Verifique setor, tipo ou anexo. | FK |
| Outro known / unknown Prisma | 500 | `UNEXPECTED_ERROR` | §5.2 | — |

Uniques no schema hoje: `Manifestacao(tenantId, protocol)`, `Manifestacao(tenantId, numeroPersonalizado)`, `OuvidoriaTipoManifestacao(tenantId, codigo)`, `OuvidoriaFormaAtendimento(tenantId, descricao)`.

---

## 3. Códigos de plataforma (já usados — reutilizar)

Não prefixar de novo. O client mapeia estes códigos **e** o HTTP.

| Código | HTTP | Mensagem PT-BR (canônica) | Origem hoje | Superfície client |
|---|---|---|---|---|
| `VALIDATION_FAILED` | 400 | Verifique os campos destacados. | **Novo** no filtro Zod | inline por `errors[].path` |
| `MODULO_SETOR_DENIED` | 403 | Você não tem permissão para a Ouvidoria neste setor. | `ModuloPermissaoGuard` (message ainda em inglês) | página `AccessDenied403` — já existe; não toast |
| `INVALID_TENANT` | 400/403 | Instituição inválida ou inativa. | interceptor admin | toast |
| `FILE_TOO_LARGE` | 400 | O arquivo excede o tamanho permitido (30 MB). | `PresignAnexoUseCase` | inline na zona de anexo |
| `FILE_TYPE_NOT_ALLOWED` | 400 | Este tipo de arquivo não é permitido. | `PresignAnexoUseCase` | inline na zona de anexo |
| `INVALID_STATUS_TRANSITION` | 409 | Esta ação não é permitida no status atual da manifestação. | encaminhar / responder / encerrar | toast + inline no diálogo |
| `CATALOG_IN_USE` | 409 | Este item está em uso. Inative em vez de excluir. | `DeleteTipoManifestacaoUseCase` | toast na tela de catálogos |
| `MANIFESTACAO_NOT_EDITABLE` | 403 | Não é possível editar após o encaminhamento. | `UpdateManifestacaoDraftUseCase` | banner no wizard |
| `RESOLUTION_FLAG_REQUIRED` | 400 | Informe se houve resolução. | `EncerrarManifestacaoUseCase` | inline no rádio de encerrar |
| `CHALLENGE_INVALID` | 400 | Não foi possível validar o envio. Atualize a página e tente de novo. | criação pública | inline (portal) |
| `ACTIVE_SECTOR_UNDEFINED` | 400 | Selecione o setor ativo antes de tramitar. | `ResolveTramitacaoSectorUseCase` | toast |

Códigos de **Jatobá / Cedro / Carvalho** (`FISCALIZACAO_*`, `INSIGHTS_*`, `PERIOD_CLOSED`, etc.) já existem e **ficam fora** do escopo Base deste contrato — não reescrever.

Guards **sem `code` hoje** (mapear no client pelo HTTP até o guard ganhar código):

| Situação | HTTP | Message atual | Código proposto | Mensagem canônica |
|---|---|---|---|---|
| Sem JWT | 401 | default Nest | `UNAUTHORIZED` | Sessão expirada. Entre novamente. (já em `SESSION_EXPIRED_MESSAGE`) |
| Sem `X-Tenant-ID` | 400 | `X-Tenant-ID header is required` | `TENANT_REQUIRED` | Informe a instituição para continuar. |
| Tenant inexistente/inativo | 404 | `Tenant not found or inactive` | `TENANT_NOT_FOUND` | Instituição não encontrada ou inativa. |
| Licença ausente | 403 | `Licenca required` | `LICENCA_REQUIRED` | Esta funcionalidade não está disponível para a instituição. |
| Papel insuficiente | 403 | `Insufficient role` | `INSUFFICIENT_ROLE` | Seu perfil não permite esta ação. |

`401` já redireciona ao login pelo `create-api-client` — o agente de client **não** altera esse fluxo.

---

## 4. Catálogo Zod — um código por campo / refine

Toda mensagem Zod na API deve ser PT-BR (`.min(1, '…')` / `{ error: '…' }` no Zod v4). O filtro normaliza para `errors[]` e escolhe `code` pela tabela abaixo. Se o path não estiver na tabela: `VALIDATION_FAILED` + path original.

### 4.1 Rascunho / atualização de manifestação (`createManifestacaoDraftBodySchema`, `updateManifestacaoDraftBodySchema`)

| path | Regra atual | Código | Mensagem |
|---|---|---|---|
| `type` | enum obrigatório | `OUVIDORIA_VAL_TYPE` | Escolha o tipo da manifestação. |
| `subject` | `min(1).max(500)` | `OUVIDORIA_VAL_SUBJECT` | Informe o assunto (até 500 caracteres). |
| `description` | `min(1)` | `OUVIDORIA_VAL_DESCRIPTION` | Descreva a manifestação. |
| `priority` | enum opcional | `OUVIDORIA_VAL_PRIORITY` | Prioridade inválida. Use baixa, média, alta ou urgente. |
| `replyEmail` | email ou `''` | `OUVIDORIA_VAL_REPLY_EMAIL` | Informe um e-mail válido ou deixe em branco. |
| `serviceMode` | `max(255)` | `OUVIDORIA_VAL_SERVICE_MODE` | Forma de atendimento muito longa. |
| `category` | `max(255)` | `OUVIDORIA_VAL_CATEGORY` | Categoria muito longa. |
| `motivo` | `max(200)` | `OUVIDORIA_VAL_MOTIVO` | Motivo muito longo. |
| `programa` | `max(100)` | `OUVIDORIA_VAL_PROGRAMA` | Programa inválido. |
| `numeroPersonalizado` | `max(80)` | `OUVIDORIA_VAL_NUMERO` | Número institucional muito longo. |
| `requesterFullName` | `max(200)` | `OUVIDORIA_VAL_REQUESTER_NAME` | Nome do solicitante muito longo. |
| `requesterDocument` | `max(20)` | `OUVIDORIA_VAL_REQUESTER_DOC` | Documento do solicitante inválido. |
| `holderName` | `max(200)` | `OUVIDORIA_VAL_HOLDER_NAME` | Nome do titular muito longo. |
| `registrationNumber` | `max(50)` | `OUVIDORIA_VAL_REGISTRATION` | Matrícula / inscrição muito longa. |
| `requesterHomePhone` / `Mobile` / `Business` | `max(20)` | `OUVIDORIA_VAL_PHONE` | Telefone inválido. |
| `address.municipioIbge` | `length(7)` | `OUVIDORIA_VAL_IBGE` | Código IBGE do município deve ter 7 dígitos. |
| `address.postalCode` | `max(9)` | `OUVIDORIA_VAL_CEP` | CEP inválido. |
| `address.street` | `max(255)` | `OUVIDORIA_VAL_STREET` | Logradouro muito longo. |
| `address.number` | `max(20)` | `OUVIDORIA_VAL_ADDRESS_NUMBER` | Número do endereço muito longo. |
| `address.complement` | `max(100)` | `OUVIDORIA_VAL_COMPLEMENT` | Complemento muito longo. |
| `address.landmark` | `max(500)` | `OUVIDORIA_VAL_LANDMARK` | Ponto de referência muito longo. |
| `address.neighborhood` | `max(100)` | `OUVIDORIA_VAL_NEIGHBORHOOD` | Bairro muito longo. |
| `address.zone` | `max(100)` | `OUVIDORIA_VAL_ZONE` | Zona muito longa. |
| `concessionaria.ordemServico` | `max(80)` | `OUVIDORIA_VAL_OS` | Ordem de serviço muito longa. |
| `isAnonymous` | boolean | `OUVIDORIA_VAL_ANONYMOUS` | Informe se a manifestação é anônima. |

Sanitização anônima (`sanitizeDraftInput`) **não** é erro — só limpa PII. Não gerar código para isso.

**Gap de schema:** rascunho interno **não** exige nome quando `isAnonymous === false`. O público exige (`superRefine`). O agente de API **DEVE** acrescentar o mesmo refine no draft interno e usar `OUVIDORIA_VAL_REQUESTER_REQUIRED`: "Informe o nome do solicitante em manifestação identificada."

### 4.2 Listagens e queries

| Schema / path | Regra | Código | Mensagem |
|---|---|---|---|
| `listManifestacoesQuery.type` | enum | `OUVIDORIA_VAL_TYPE` | Tipo de filtro inválido. |
| `.status` | enum de status | `OUVIDORIA_VAL_STATUS` | Situação de filtro inválida. |
| `.priority` | enum | `OUVIDORIA_VAL_PRIORITY` | Prioridade de filtro inválida. |
| `.origem` | `interna` \| `publica` | `OUVIDORIA_VAL_ORIGEM` | Origem deve ser interna ou pública. |
| `.page` | int ≥ 1 | `OUVIDORIA_VAL_PAGE` | Página deve ser um número a partir de 1. |
| `.limit` | 1–100 | `OUVIDORIA_VAL_LIMIT` | Limite deve ser entre 1 e 100. |
| `.motivo` | max 200 | `OUVIDORIA_VAL_MOTIVO` | Motivo do filtro muito longo. |
| `.channel` | max 255 | `OUVIDORIA_VAL_CHANNEL` | Canal do filtro muito longo. |
| `dashboardQuery.year` | 2000–2100 | `OUVIDORIA_VAL_YEAR` | Ano inválido. |
| `dashboardQuery.month` | 1–12 | `OUVIDORIA_VAL_MONTH` | Mês deve ser entre 1 e 12. |
| `listAuditoriaQuery` page/limit | iguais | mesmos códigos | mesmas mensagens |
| `listAtendimentosQuery.q` | max 200 | `OUVIDORIA_VAL_SEARCH` | Texto de busca muito longo. |
| `listOuvidoriaAssuntosQuery.q` | max 100 | `OUVIDORIA_VAL_SEARCH` | Texto de busca muito longo. |
| `consultaQuery.protocol` | `min(1)` | `OUVIDORIA_VAL_PROTOCOL` | Informe o número de protocolo. |
| `consultaQuery.chave` | `min(1)` | `OUVIDORIA_VAL_CHAVE` | Informe a chave de consulta. |

Datas `from`/`to` hoje são `z.string()` sem formato. **DEVE** validar ISO date (`YYYY-MM-DD` ou datetime) com `OUVIDORIA_VAL_DATE`: "Informe uma data válida."

### 4.3 Anexos autenticados

| path | Regra | Código | Mensagem |
|---|---|---|---|
| `fileName` | min 1 max 255 | `OUVIDORIA_VAL_FILE_NAME` | Informe o nome do arquivo. |
| `mimeType` | min 1 | `OUVIDORIA_VAL_MIME` | Informe o tipo do arquivo. |
| `sizeBytes` | int positivo | `OUVIDORIA_VAL_SIZE` | Tamanho do arquivo inválido. |
| `externalUrl` | url max 2048 | `OUVIDORIA_VAL_URL` | Informe um endereço de link válido. |

### 4.4 Encaminhar / responder / encerrar

| path | Regra | Código | Mensagem |
|---|---|---|---|
| `destinoSetorId` | uuid | `OUVIDORIA_VAL_DESTINO` | Selecione o setor de destino. |
| `observacao` | min 1 | `OUVIDORIA_VAL_OBSERVACAO` | Informe a observação do encaminhamento. |
| `texto` | min 1 | `OUVIDORIA_VAL_RESPOSTA` | Informe o texto da resposta. |
| `houveResolucao` | boolean obrigatório | `RESOLUTION_FLAG_REQUIRED` | Informe se houve resolução. |
| `medidasResolucao` | max 5000 | `OUVIDORIA_VAL_MEDIDAS` | Medidas adotadas muito longas. |
| `cartaResposta.fileName` | min 1 max 255 | `OUVIDORIA_VAL_FILE_NAME` | Informe o nome da carta de resposta. |
| `cartaResposta.storageKey` | min 1 | `OUVIDORIA_VAL_STORAGE_KEY` | Carta de resposta incompleta. Reenvie o arquivo. |

### 4.5 Catálogos e atendimento interno

| path | Regra | Código | Mensagem |
|---|---|---|---|
| `codigo` | trim min 1 max 50 | `OUVIDORIA_VAL_CATALOG_CODE` | Informe o código (até 50 caracteres). |
| `nome` | trim min 1 max 200 | `OUVIDORIA_VAL_CATALOG_NAME` | Informe o nome (até 200 caracteres). |
| `descricao` (assunto) | trim min 1 max 255 | `OUVIDORIA_VAL_ASSUNTO` | Informe a descrição do assunto. |
| `assunto` (atendimento) | trim min 1 max 255 | `OUVIDORIA_VAL_ATENDIMENTO_ASSUNTO` | Informe o assunto do atendimento. |
| `descricao` (atendimento) | max 5000 | `OUVIDORIA_VAL_ATENDIMENTO_DESC` | Descrição do atendimento muito longa. |
| `nomeCidadao` | max 200 | `OUVIDORIA_VAL_CIDADAO` | Nome do cidadão muito longo. |
| `contato` | max 100 | `OUVIDORIA_VAL_CONTATO` | Contato muito longo. |
| `dataAtendimento` | min 1 | `OUVIDORIA_VAL_DATA_ATENDIMENTO` | Informe a data do atendimento. |

`dataAtendimento` hoje é string solta. **DEVE** validar datetime ISO com a mesma mensagem.

### 4.6 Manifestação pública (`criarManifestacaoPublicaBodySchema`)

| path | Regra | Código | Mensagem |
|---|---|---|---|
| `programa` | `agua` \| `iluminacao` | `OUVIDORIA_VAL_PROGRAMA` | Escolha o programa (água ou iluminação). |
| `motivo` | trim min 1 max 200 | `OUVIDORIA_VAL_MOTIVO` | Informe o motivo. |
| `subject` / `description` | iguais ao rascunho | mesmos códigos | mesmas mensagens |
| `matricula` | refine água; regex 5–12 dígitos | `OUVIDORIA_VAL_MATRICULA` | Informe a matrícula de água (5 a 12 dígitos). |
| `protocoloConcessionaria` | refine iluminação | `OUVIDORIA_VAL_PROT_CONCESS` | Informe o protocolo da concessionária. |
| `identificacaoPoste` | refine iluminação | `OUVIDORIA_VAL_POSTE` | Informe a identificação do poste. |
| `requesterFullName` | refine identificada | `OUVIDORIA_VAL_REQUESTER_REQUIRED` | Informe o nome do solicitante em manifestação identificada. |
| `challengeToken` | min 1 | `OUVIDORIA_VAL_CHALLENGE` | Validação de envio ausente. Atualize a página. |
| `anexoTempIds.*` | array de string | `OUVIDORIA_VAL_ANEXO_TEMP` | Referência de anexo inválida. |

Upload público (`uploadPublicoBodySchema`): mesmos códigos de anexo; limite de negócio é **10 MB** e MIME reduzido — use `FILE_TOO_LARGE` / `FILE_TYPE_NOT_ALLOWED` no use-case (já valida, mas **sem `code`** hoje).

---

## 5. Catálogo de domínio (use-cases)

Códigos novos usam prefixo `OUVIDORIA_*`. Códigos já testados **permanecem** (coluna “já existe”).

### 5.1 Manifestações autenticadas

| Código | HTTP | Mensagem | Técnico (log, não no client) | Superfície | Já existe? |
|---|---|---|---|---|---|
| `OUVIDORIA_NOT_FOUND` | 404 | Manifestação não encontrada. | id + tenant | página de detalhe / banner wizard | message sim, **code não**; PDF/DOCX viram **500** |
| `OUVIDORIA_ALREADY_CONFIRMED` | 409 | Esta manifestação já foi confirmada. | status atual | banner wizard | hoje 400 string sem code |
| `OUVIDORIA_ANEXO_DRAFT_ONLY` | 400 | Anexos só podem ser adicionados em rascunho. | status | inline anexo | string sem code |
| `OUVIDORIA_ANEXO_NOT_FOUND` | 404 | Anexo não encontrado. | anexoId | inline anexo | string sem code |
| `FILE_TOO_LARGE` | 400 | §3 | sizeBytes | inline | sim |
| `FILE_TYPE_NOT_ALLOWED` | 400 | §3 | mimeType | inline | sim |
| `MANIFESTACAO_NOT_EDITABLE` | 403 | §3 | status + encaminhado | banner wizard | sim |
| `INVALID_STATUS_TRANSITION` | 409 | §3 | de→para | toast + inline diálogo | sim (3 fluxos, mesma message genérica) |
| `RESOLUTION_FLAG_REQUIRED` | 400 | §3 | — | inline | sim |
| `OUVIDORIA_PROTOCOL_CONFLICT` | 409 | §2.3 | P2002 protocol | toast | **não** — hoje 500 |
| `OUVIDORIA_NUMERO_CONFLICT` | 409 | §2.3 | P2002 numeroPersonalizado | inline + toast | **não** — hoje 500 |
| `ACTIVE_SECTOR_UNDEFINED` | 400 | §3 | encaminhar | toast | sim (tramitação) |

Mensagens específicas recomendadas para `INVALID_STATUS_TRANSITION` (mesmo código; `message` varia — o client usa `message`):

| Fluxo | Message |
|---|---|
| Encerrar já encerrada | Manifestação já encerrada. |
| Encerrar ainda em rascunho | Confirme a manifestação antes de encerrar. |
| Encaminhar draft/closed | Status inválido para encaminhamento. |
| Responder fora de em análise/tramitando | Status inválido para resposta. |

### 5.2 Inesperado e infraestrutura

| Código | HTTP | Mensagem | Superfície |
|---|---|---|---|
| `UNEXPECTED_ERROR` | 500 | Não foi possível concluir a operação. Se o problema continuar, informe o código do erro. | toast **ou** banner; mostrar `code` + `requestId` em texto secundário (`text-muted`) |
| `OUVIDORIA_STORAGE_UNAVAILABLE` | 503 | Não foi possível enviar o arquivo agora. Tente novamente em instantes. | inline anexo (presign/storage) |
| `OUVIDORIA_DOCUMENT_FAILED` | 503 | Não foi possível gerar o documento. Tente novamente. | toast no detalhe |

`requestId`: o filtro **DEVE** ecoar `x-request-id` ou gerar UUID e devolver no JSON do 500. Sem stack.

### 5.3 Catálogos e atendimentos

| Código | HTTP | Mensagem | Já existe? |
|---|---|---|---|
| `OUVIDORIA_TIPO_NOT_FOUND` | 404 | Tipo de manifestação não encontrado. | P2025 no inativar/excluir → hoje 500 |
| `OUVIDORIA_FORMA_NOT_FOUND` | 404 | Forma de atendimento não encontrada. | idem |
| `OUVIDORIA_ASSUNTO_NOT_FOUND` | 404 | Assunto não encontrado. | idem |
| `OUVIDORIA_ATENDIMENTO_NOT_FOUND` | 404 | Atendimento interno não encontrado. | endpoints get/update ainda não existem |
| `CATALOG_IN_USE` | 409 | §3 | só em **excluir tipo**; inativar **não** bloqueia (ok) |
| `OUVIDORIA_CATALOG_CODE_CONFLICT` | 409 | §2.3 | create tipo → hoje 500 |
| `OUVIDORIA_CATALOG_NAME_CONFLICT` | 409 | §2.3 | create forma → hoje 500 |

### 5.4 Público (portal do cidadão)

Não há tela no SPA tenant (`apps/web`). Mesmo assim a API **DEVE** cumprir o catálogo.

| Código | HTTP | Mensagem | Já existe? |
|---|---|---|---|
| `CHALLENGE_INVALID` | 400 | §3 | sim |
| `OUVIDORIA_PUBLIC_RATE_LIMITED` | 429 | Limite de envios atingido. Aguarde e tente novamente. | message sem `code`; tem `retryAfterSeconds` |
| `OUVIDORIA_VAL_MATRICULA` | 400 | §4.6 | use-case duplica Zod, sem code |
| `OUVIDORIA_PROGRAMA_FIELDS` | 400 | Iluminação exige protocolo da concessionária e identificação do poste. | sem code |
| `OUVIDORIA_ANEXO_TEMP_NOT_FOUND` | 404 | Referência de anexo não encontrada. | sem code |
| `OUVIDORIA_ANEXO_EXPIRED` | 400 | Referência expirada. Reenvie o arquivo. | sem code |
| `OUVIDORIA_PUBLIC_NOT_FOUND` | 404 | Manifestação não encontrada. | message ok; **mesmo texto** para chave errada |
| `FILE_TOO_LARGE` / `FILE_TYPE_NOT_ALLOWED` | 400 | Upload público: 10 MB; JPEG, PNG, PDF, DOCX | message genérica sem code |

Throttle Nest (`@Throttle`) em rotas públicas: 429. Se o body do Throttler não tiver `code`, o client/portal trata HTTP 429 como `OUVIDORIA_PUBLIC_RATE_LIMITED`.

---

## 6. Inventário — estado atual

### 6.1 Endpoints API (`OuvidoriaController`)

Autenticados, `@RequireModulo('ouvidoria')`:

| Método | Rota | Schema | Use-case | Erro hoje |
|---|---|---|---|---|
| GET | `/ouvidoria/dashboard` | `DashboardQuery` | `GetDashboardAgregacoes` | só Zod 400 inglês; falha Prisma → 500 |
| GET | `/ouvidoria/auditoria` | `ListAuditoriaQuery` | `ListAuditoria` | idem |
| GET | `/ouvidoria/tipos` | — | `ListTipoManifestacao` | 500 se Prisma cair |
| POST | `/ouvidoria/tipos` | `CreateTipoManifestacaoBody` | `CreateTipoManifestacao` | P2002 → **500** |
| POST | `/ouvidoria/tipos/:id/inativar` | param cru | `InactivateTipoManifestacao` | P2025 → **500** |
| POST | `/ouvidoria/tipos/:id/excluir` | param cru | `DeleteTipoManifestacao` | 409 `CATALOG_IN_USE`; P2025 → 500 |
| POST | `/ouvidoria/formas-atendimento` | `CreateFormaAtendimentoBody` | `CreateFormaAtendimento` | P2002 → **500** |
| PATCH | `/ouvidoria/formas-atendimento/:id` | `UpdateFormaAtendimentoBody` | `UpdateFormaAtendimento` | P2025 → **500** |
| POST | `/ouvidoria/formas-atendimento/:id/inativar` | param cru | `InactivateFormaAtendimento` | P2025 → **500** |
| GET | `/ouvidoria/formas-atendimento` | — | `ListOuvidoriaFormasAtendimento` | 500 Prisma |
| POST | `/ouvidoria/assuntos` | `CreateAssuntoBody` | `CreateOuvidoriaAssunto` | id manual; colisão → 500 |
| POST | `/ouvidoria/assuntos/:id/inativar` | param cru | `InactivateOuvidoriaAssunto` | P2025 → **500** |
| GET | `/ouvidoria/assuntos` | `ListOuvidoriaAssuntosQuery` | `ListOuvidoriaAssuntos` | Zod / 500 |
| GET | `/ouvidoria/atendimentos-internos` | `ListAtendimentosQuery` | `ListAtendimentoInterno` | Zod / 500 |
| POST | `/ouvidoria/atendimentos-internos` | `CreateAtendimentoInternoBody` | `CreateAtendimentoInterno` | Zod / 500; sem catch de data inválida no use-case |
| POST | `/ouvidoria/manifestacoes` | `CreateManifestacaoDraftBody` | `CreateManifestacaoDraft` | Zod inglês; P2002 nº → 500 |
| PATCH | `/ouvidoria/manifestacoes/:id` | `UpdateManifestacaoDraftBody` | `UpdateManifestacaoDraft` | 403 com code; 404 string sem code |
| GET | `/ouvidoria/manifestacoes` | `ListManifestacoesQuery` | `ListManifestacoes` | Zod / 500 |
| GET | `/ouvidoria/manifestacoes/:id` | — | `GetManifestacaoDetail` | 404 string sem code |
| GET | `/ouvidoria/manifestacoes/:id/revisao` | — | `GetManifestacaoRevisao` | 404 string sem code |
| POST | `/ouvidoria/manifestacoes/:id/confirmar` | — | `ConfirmManifestacao` | 400 string sem code; P2002 protocolo → 500 |
| POST | `…/anexos/presign` | `PresignAnexoBody` | `PresignAnexo` | 400 string / codes de arquivo; 404 via require |
| POST | `…/anexos/link` | `AddLinkAnexoBody` | `AddLinkAnexo` | 400 string sem code |
| POST | `…/anexos/:anexoId/confirm` | — | `ConfirmAnexo` | 404 string sem code |
| POST | `…/encaminhar` | `EncaminharBody` | `Encaminhar` + resolve setor | 404 string; 409 com code; 400 setor |
| POST | `…/responder` | `ResponderBody` | `Responder` | 409 com code |
| POST | `…/encerrar` | `EncerrarBody` | `Encerrar` | 409/400 com code |
| GET | `…/documento/docx` | — | `GenerateManifestacaoDocx` | `throw new Error` → **500** `"Internal server error"` |
| GET | `…/documento/pdf` | — | `GenerateManifestacaoPdf` | idem |

Públicos (`@Public`, throttle):

| Método | Rota | Schema | Use-case | Erro hoje |
|---|---|---|---|---|
| GET | `/ouvidoria/consulta` | `ConsultaQuery` | `ConsultaPublica` | 404 genérico (correto quanto a não vazar chave) |
| POST | `/ouvidoria/publico/manifestacoes` | `CriarManifestacaoPublicaBody` | `CriarManifestacaoPublica` | challenge/rate/campos; refine Zod PT-BR **já** existe; use-case duplica sem code |
| POST | `/ouvidoria/publico/anexos` | `UploadPublicoBody` | `UploadAnexoPublico` | 400 genérico sem code |
| GET | `/ouvidoria/publico/catalogos` | — | lista formas | 500 Prisma |

Params `:id` **não** passam por Zod. **DEVE** validar UUID (tipos/manifestações) ou inteiro (formas/assuntos) com `OUVIDORIA_VAL_ID`: "Identificador inválido."

### 6.2 Telas client (`apps/web` módulo ouvidoria)

| Tela | Rota típica | Como o erro aparece hoje |
|---|---|---|
| Overview | `/ouvidoria` | sem fetch — sem erro |
| Lista | `/ouvidoria/manifestacoes` | `useApiAction` toast + texto genérico *Não foi possível carregar as manifestações.* |
| Wizard | `/ouvidoria/manifestacoes/nova` e `/:id/editar` | banner vermelho com `err.message` cru (`Validation failed`, inglês); catálogo: frase genérica; **sem** Zod no client |
| Detalhe | `/ouvidoria/manifestacoes/:id` | 404 vira parágrafo *Manifestação não encontrada.* (qualquer falha, inclusive rede); ações **sem catch** — falha silenciosa |
| Encaminhar (lista) | diálogo | inline `err.message` ou *Erro ao tramitar* |
| Dashboard | `/ouvidoria/painel` (ou equivalente) | toast + *Não foi possível carregar o painel.* |
| Catálogos | `/ouvidoria/catalogos` | load: toast genérico; **criar/inativar sem catch** |
| Atendimentos | `/ouvidoria/atendimentos` | load: texto genérico; **criar sem catch** |
| Anexos (wizard) | `AnexoUploadZone` | inline `err.message` ou *Erro ao enviar arquivos* |
| Jatobá / Cedro / Carvalho | auditoria / insights / maturidade | 429 já tratado; demais frases genéricas *Não foi possível…* — fora do escopo Base |

`useApiAction` **ignora** `body.code` e substitui pela `errorMessage` fixa. Wizard/diálogos usam `Error.message` (inglês da API).

Não há schema Zod de formulário no client (só `Boolean(subject && description)` no wizard).

### 6.3 Rede / API down — copy canônica

`regras-plataforma.md` **não** tem frase de servidores fora do ar. Frase **única** deste contrato:

> **Os servidores estão temporariamente fora do ar. Tente novamente em alguns minutos.**

| Situação | Como chega no client | Superfície | Logout? |
|---|---|---|---|
| Fetch falhou (API desligada, DNS, CORS) | `ApiError` `status: 0`, message `Failed to fetch` | **hoje:** `create-api-client` dispara `session lost` → login com `SESSION_NETWORK_MESSAGE` (*Não foi possível manter sua sessão…*) | sim, **global** — **não alterar** login/`AuthContext` |
| Timeout / 502 / 503 / 504 | `status` HTTP, sem session-lost | **banner** persistente com a frase canônica + *Tentar novamente* | não |
| 500 com `UNEXPECTED_ERROR` | body com code | toast ou banner da §5.2 (não a frase de fora do ar) | não |

O agente de client **DEVE** tratar 502/503/504 (e AbortError se houver timeout local) com o banner. `status: 0` permanece no fluxo global de sessão — fora de escopo. Não mudar `SESSION_NETWORK_MESSAGE`.

---

## 7. Regras do client

Helper único: `ci-client-v2/apps/web/src/modules/ouvidoria/api/errors.ts` — `mapOuvidoriaError(err) → { code, message, fieldErrors, surface }`.

Ler nesta ordem: `body.code` → primeiro `body.errors[]` → HTTP → fallback.

| `surface` | Quando | Onde |
|---|---|---|
| `inline` | `OUVIDORIA_VAL_*`, `RESOLUTION_FLAG_REQUIRED`, anexo, refine de form | sob o campo (`aria-invalid`, texto `text-destructive`) |
| `banner` | load de página, wizard, detalhe 404, `MANIFESTACAO_NOT_EDITABLE`, 502/503/504, `UNEXPECTED_ERROR` com retry | faixa no topo do card/página + *Tentar novamente* |
| `toast` | mutação pontual (encaminhar, responder, encerrar, criar catálogo, download) | `useToast` — **sempre** a `message` canônica, nunca `Request failed` |
| `page` | `MODULO_SETOR_DENIED` / 403 de módulo | `AccessDenied403` / `OuvidoriaModuleGate` — já existe |
| `silent-redirect` | 401 | fluxo global de sessão — não toast |

Regras:

1. Validação **antes** do POST no wizard/catálogos/atendimentos/diálogos — espelhar mensagens da §4 (schema Zod v3 no client **ou** mapa de campo; sem `react-hook-form` novo sem combinado).
2. Nunca mostrar `error` (nome da classe Nest), `stack`, `"Internal server error"`, `"Validation failed"`, `"Failed to fetch"`, `"Request failed"`.
3. `useApiAction` nas telas de Ouvidoria: passar `errorMessage` só como fallback; preferir `mapOuvidoriaError(err).message`.
4. `ManifestacaoActionDialogs.run` **DEVE** `catch` e toast/inline — hoje engole o erro.
5. Catálogos e atendimentos: create/inativar com o mesmo mapper.
6. Detalhe: distinguir 404 (`OUVIDORIA_NOT_FOUND`) de rede/502 (banner de fora do ar). Hoje qualquer falha vira "não encontrada".
7. Licenças Jatobá/Cedro/Carvalho: não regressar o tratamento 429 já existente.

---

## 8. Arquivos-alvo

### 8.1 Agente de API — tocar

**Filtro / infra (sem login/tenant/protocolo):**

- `ci-api-v2/src/common/filters/all-exceptions.filter.ts` — Prisma known → 409/404; Zod → `VALIDATION_FAILED` + `errors[]` PT-BR; 500 → `UNEXPECTED_ERROR` + `requestId`; sem stack no body
- `ci-api-v2/src/common/filters/all-exceptions.filter.spec.ts` (criar se não houver)
- Helper opcional: `ci-api-v2/src/modules/ouvidoria/lib/ouvidoria-errors.ts` (fábricas `notFound()`, `conflict()`, `invalid()`)

**Schemas e testes:**

- `ci-api-v2/src/modules/ouvidoria/ouvidoria.schemas.ts`
- `ci-api-v2/src/modules/ouvidoria/ouvidoria.schemas.spec.ts`
- `ci-api-v2/src/modules/ouvidoria/ouvidoria.controller.ts` — parse de `:id` (não mudar geração de protocolo)

**Use-cases (acrescentar `code` + HttpException; não mudar regra de negócio de protocolo):**

- `use-cases/create-manifestacao-draft.use-case.ts`
- `use-cases/update-manifestacao-draft.use-case.ts`
- `use-cases/confirm-manifestacao.use-case.ts` — só o 409 `OUVIDORIA_ALREADY_CONFIRMED`; **não** a sequência do protocolo
- `use-cases/get-manifestacao-detail.use-case.ts`
- `use-cases/get-manifestacao-revisao.use-case.ts`
- `use-cases/encaminhar-manifestacao.use-case.ts`
- `use-cases/responder-manifestacao.use-case.ts`
- `use-cases/encerrar-manifestacao.use-case.ts`
- `use-cases/presign-anexo.use-case.ts`
- `use-cases/add-link-anexo.use-case.ts`
- `use-cases/confirm-anexo.use-case.ts`
- `use-cases/generate-manifestacao-pdf.use-case.ts` — `Error` → `NotFoundException` / `OUVIDORIA_DOCUMENT_FAILED`
- `use-cases/generate-manifestacao-docx.use-case.ts` — idem
- `use-cases/criar-manifestacao-publica.use-case.ts`
- `use-cases/upload-anexo-publico.use-case.ts`
- `use-cases/consulta-publica.use-case.ts` — só `code` no 404
- `use-cases/create-tipo-manifestacao.use-case.ts` (+ forma, assunto, update, inactivate, delete)
- `use-cases/create-atendimento-interno.use-case.ts`
- `repository/manifestacao.repositories.ts` — `RequireManifestacao` com code; **não** alterar `ConfirmManifestacaoRepository` (gera protocolo)
- `repository/create-tipo-manifestacao.repository.ts` e demais creates/updates de catálogo — capturar P2002/P2025

**Testes de use-case já existentes** (estender asserts de `code`): `test/use-cases/*.spec.ts`, `ouvidoria.controller.spec.ts`.

### 8.2 Agente de API — NÃO tocar

- Geração de `protocol` / `chaveConsulta` / `ManifestacaoSequence`
- `numeroPersonalizado` e `ManifestacaoNumeroPersonalizadoSequence`
- Login, JWT strategy, `AuthContext` equivalente de servidor, `TenantMiddleware`
- Módulos `ouvidoria-fiscalizacao`, `ouvidoria-insights`, `ouvidoria-maturidade` (já têm códigos)

### 8.3 Agente de client — tocar

- `apps/web/src/modules/ouvidoria/api/errors.ts` (**criar**) + teste Vitest
- `apps/web/src/modules/ouvidoria/schemas/manifestacao-draft.schema.ts` (**criar**, espelho §4.1)
- `pages/ManifestacaoWizardPage.tsx`
- `pages/ManifestacaoDetailPage.tsx`
- `pages/ManifestacoesListPage.tsx`
- `pages/OuvidoriaDashboardPage.tsx`
- `pages/OuvidoriaCatalogosPage.tsx`
- `pages/OuvidoriaAtendimentosPage.tsx`
- `components/ManifestacaoStepOneForm.tsx`
- `components/ManifestacaoActionDialogs.tsx`
- `components/ForwardManifestacaoDialog.tsx`
- `components/AnexoUploadZone.tsx`
- `api/manifestacoes.ts`, `api/workflow.ts`, `api/catalog.ts`, `api/anexos.ts`, `api/dashboard.ts` — só para propagar `ApiError` sem engolir
- testes em `__tests__/`: wizard, action dialogs, catalogos, detalhe

### 8.4 Agente de client — NÃO tocar

- `AuthContext`, `session-messages.ts`, `create-api-client.ts` (logout em `status: 0` / 401)
- Tenant picker / login
- UI de exibição/geração de protocolo e chave (passo final do wizard) — só erros em volta
- Telas Jatobá/Cedro/Carvalho **exceto** se reutilizarem o helper `mapOuvidoriaError` para 502/503 (opcional, sem regressão 429)

---

## 9. Checklist de aceite (agentes irmãos)

API:

- [ ] Nenhum use-case da Ouvidoria lança `Error` cru
- [ ] Todo 4xx de domínio tem `code` deste arquivo
- [ ] Zod devolve PT-BR + `errors[].path`
- [ ] P2002/P2025 de manifesto/catálogo ≠ 500
- [ ] 500 = `UNEXPECTED_ERROR` + `requestId`, sem stack, sem `"Internal server error"`
- [ ] Consulta pública: chave errada ≡ protocolo inexistente
- [ ] Testes Jest dos schemas e dos use-cases de conflito/404/transição

Client:

- [ ] Helper único mapeia `code` → copy
- [ ] Form: erro no campo, não só toast
- [ ] Mutações com catch (diálogos, catálogo, atendimento, download)
- [ ] 502/503/504: banner da frase de servidores fora do ar
- [ ] 404 de detalhe ≠ banner de rede
- [ ] Nenhuma string `"Request failed"` / `"Validation failed"` / `"Internal server error"` visível
- [ ] 403 de módulo continua `AccessDenied403`

---

## 10. Relação com os outros contratos 038

- [ouvidoria.md](./ouvidoria.md) § Erros específicos — este arquivo **detalha** códigos e copy.
- [ouvidoria-publica.md](./ouvidoria-publica.md) § Erros específicos — idem para o portal.
- Geração de protocolo / número institucional: **outro agente**. Aqui só o 409 de conflito.
)
