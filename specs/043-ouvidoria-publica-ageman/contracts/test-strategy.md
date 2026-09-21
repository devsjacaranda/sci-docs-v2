# Test Strategy — 043 Ouvidoria Pública AGEMAN

TDD obrigatório (Constitution II). IDs `CT-OUV-PUB-NNN` nos describes da API.

## API (Jest) — RED primeiro

| ID | Alvo | Casos |
| --- | --- | --- |
| CT-OUV-PUB-001 | `criarManifestacaoPublicaBodySchema` | happy (cada um dos 6 programas); `tipo` inválido; `email` ausente/inválido; `institucional` sem `motivo` de catálogo (texto livre aceito); `matricula` ausente em `agua`; `protocoloConcessionaria`/`identificacaoPoste` ausentes em `iluminacao`; `address` parcial aceito |
| CT-OUV-PUB-002 | `create-manifestacao-publica.repository` | persiste `type` mapeado; persiste `replyEmail`/telefones; persiste `addressId` via `CreateAddressRepository` quando `address` presente; **`createdByUserId` fica `undefined`** (regressão do bug corrigido); retorna `id` |
| CT-OUV-PUB-003 | `criar-manifestacao-publica.use-case` | mapeia `tipo` client→enum; chama `bindAnexos` com `manifestacaoId` (não `protocol`); challenge inválido → 400; rate limit → 429; matrícula/iluminação inválidas → 400 |
| CT-OUV-PUB-004 | `verify-public-challenge.repository` | secret ausente → bypass (`length >= 4`); secret presente + `siteverify` sucesso (`score>=0.5`, `action` correta) → válido; `score` baixo → inválido; `action` errada → inválido; **`fetch` lança/timeout → falha fechada (inválido)** — mock de `fetch` |
| CT-OUV-PUB-005 | `upload-anexo-publico.use-case` | mimeType/tamanho dentro do padrão interno (30MB, lista `ALLOWED_MIME_TYPES`) → presign via `StorageService` mockado; fora do limite → `ANEXO_INVALID`; persiste registro temp com `tenantId` |
| CT-OUV-PUB-006 | `bind-anexos-publicos.repository` | cria `ManifestacaoAnexo` real por `tempId` válido; ignora `tempId` expirado/consumido/de outro tenant; marca `consumedAt` |
| CT-OUV-PUB-007 | `consulta-publica.use-case` | `statusLabel` vem de `PUBLIC_MANIFESTACAO_STATUS_LABEL` (não do mapa interno) para os 6 status; protocolo inexistente e chave incorreta → 404 idêntico nos dois casos |
| CT-OUV-PUB-008 | `GET /ouvidoria/publico/programas` (use-case/controller) | devolve os 6 `code`/`label`; `institucional` com `motivos: []`; demais com os motivos de `AGEMAN_MOTIVOS_BY_PROGRAMA` |

Regressão explícita: nenhum teste existente de `ouvidoria` deve quebrar — schemas/use-cases do fluxo **autenticado** (draft, encaminhar, encerrar, responder) não são tocados por esta feature.

## Client (Vitest)

| Alvo | Casos |
| --- | --- |
| `public-manifestacao.schema.ts` | fixture de cada um dos 6 programas; `tipo` inválido rejeitado; `email` obrigatório mesmo anônimo; matrícula/iluminação condicionais (paridade com o schema da API) |
| `masks.ts` / `manaus-zones.ts` / `ageman-public-fields.ts` | portados sem alteração de comportamento — reusar `form-schema.test.ts` atual como base, adaptar aos novos campos |
| `use-recaptcha.ts` | ausência de site key → `execute()` retorna `undefined` (não trava o submit); presença de site key → carrega script e retorna token (mock do `window.grecaptcha`) |
| `PublicChatbotForm` (RTL, opcional nesta entrega se o custo de setup for alto) | fluxo feliz por categoria; pergunta de e-mail sempre aparece mesmo em fluxo anônimo |
| `ConsultaProtocoloPage` (RTL) | 200 renderiza `statusLabel`/`marcos`; 404 mostra mensagem genérica (nunca diferencia protocolo/chave); 429 mostra tempo de espera |

## E2E (opcional nesta entrega)

Playwright no tenant AGEMAN: completar o assistente para cada um dos 6 programas até receber protocolo+chave; consultar imediatamente após com o protocolo/chave recebidos → status "Recebida" ou "Em análise". Pode ficar para uma tarefa isolada em `/speckit-tasks` se o ambiente E2E público ainda não estiver configurado.

## Ordem RED → GREEN

1. Schemas (API + client) — `programa`/`tipo`/`email`/contato
2. `verify-public-challenge.repository` (reCAPTCHA real + falha fechada)
3. `store-public-temp-anexo` / `find-public-temp-anexo` (Prisma) + migration
4. `upload-anexo-publico.use-case` (presign real)
5. `create-manifestacao-publica.repository` (tipo/contato/endereço/bugfix `createdByUserId`)
6. `criar-manifestacao-publica.use-case` (bind por `manifestacaoId`)
7. `bind-anexos-publicos.repository` (cria `ManifestacaoAnexo` real)
8. `consulta-publica.use-case` (label público)
9. Catálogo `GET /ouvidoria/publico/programas`
10. Client: schema → services (`api/*.ts`) → componentes portados → `ConsultaProtocoloPage` → `main.tsx`
