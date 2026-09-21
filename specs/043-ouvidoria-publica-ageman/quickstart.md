# Quickstart — 043 Ouvidoria Pública AGEMAN

Validação manual end-to-end. Contratos: [contracts/](./contracts/). Modelo: [data-model.md](./data-model.md).

## Pré-requisitos

- PostgreSQL com a migration da tabela `ManifestacaoAnexoPublicoTemp` aplicada
- Tenant AGEMAN ativo (`X-Tenant-ID: ageman` ou UUID canônico)
- `ci-api-v2/.env`: `RECAPTCHA_SECRET_KEY` **ausente** para testar o bypass de dev, ou configurada (chave de teste do Google) para testar a validação real
- `ci-client-v2/apps/publico/.env`: copiar de `.env.ageman.example` — `VITE_API_BASE_URL`, `VITE_TENANT_ID=ageman`, `VITE_RECAPTCHA_SITE_KEY` (vazio em dev)
- Wasabi/S3 configurado (`WASABI_*` em `ci-api-v2/.env`) ou ausente (fallback stub local automático do `StorageService` — presign em `/storage/stub/...`)

```powershell
cd ci-api-v2; npm run start:dev          # API em http://localhost:3000
cd ci-client-v2; npm run dev:publico       # @ci/publico em http://localhost:5175 (strictPort)
```

## Testes automatizados

```powershell
cd ci-api-v2; npm test -- --testPathPatterns=ouvidoria
cd ci-client-v2/apps/publico; npm test
```

## 1. US1 — Registrar manifestação pelo assistente conversacional (P1)

1. Abrir `http://localhost:5175` → `WelcomePage` → iniciar manifestação
2. Escolher categoria **água/saneamento** → avançar sem matrícula → **Esperado**: bloqueado, mensagem pedindo matrícula
3. Voltar, escolher **iluminação pública** → avançar sem protocolo da concessionária/poste → **Esperado**: bloqueado
4. Escolher **assuntos institucionais da AGEMAN** → **Esperado**: campo de motivo é texto livre, sem lista fixa
5. Optar por permanecer anônimo → chegar à etapa de contato → **Esperado**: e-mail continua obrigatório; nome/documento não aparecem
6. Revisar na `ReviewFormModal` e confirmar → **Esperado**: protocolo + chave de consulta exibidos, com aviso de que a chave não será mostrada novamente

```powershell
curl -X POST http://localhost:3000/ouvidoria/publico/manifestacoes `
  -H "X-Tenant-ID: ageman" -H "Content-Type: application/json" `
  -d '{"isAnonymous":true,"tipo":"complaint","programa":"agua","motivo":"FALTA DAGUA","subject":"Sem água há 3 dias","description":"Relato detalhado do problema.","email":"a@b.com","matricula":"12345678","challengeToken":"dev-bypass-token"}'
```

## 2. US2 — Anexar evidências (P2)

1. Na etapa de detalhes, arrastar um arquivo dentro do limite (30MB, tipo permitido) → **Esperado**: aceito, listado antes do envio
2. Tentar um arquivo acima do limite ou de tipo não suportado → **Esperado**: rejeitado com mensagem clara
3. Confirmar o envio com anexo → consultar a manifestação (via API interna/autenticada da equipe de ouvidoria) → **Esperado**: anexo real, `uploadConfirmed: true`, arquivo recuperável via `presignDownload`

```powershell
curl -X POST http://localhost:3000/ouvidoria/publico/anexos `
  -H "X-Tenant-ID: ageman" -H "Content-Type: application/json" `
  -d '{"fileName":"foto.jpg","mimeType":"image/jpeg","sizeBytes":204800}'
# → { tempId, uploadUrl, expiresIn } — PUT o binário em uploadUrl, depois enviar tempId em anexoTempIds[]
```

## 3. US3 — Consultar o andamento (P2, capacidade nova)

1. Usar o protocolo + chave recebidos em US1 na tela **Consultar protocolo**
2. **Esperado**: status simplificado (Recebida/Em análise/Respondida/Encerrada — nunca o vocabulário interno), assunto, histórico de marcos
3. Repetir com uma chave incorreta → **Esperado**: mensagem genérica, idêntica à de protocolo inexistente
4. Exceder o throttle da rota (10 req/min por IP — `@Throttle` em `GET /ouvidoria/consulta`) → **Esperado**: HTTP 429 com `retryAfterSeconds`

```powershell
curl "http://localhost:3000/ouvidoria/consulta?protocol=2026-1-09-0007&chave=aB3xY9kLmZ" -H "X-Tenant-ID: ageman"
# 404 genérico (protocolo inexistente ou chave errada): code OUVIDORIA_PUBLIC_NOT_FOUND
```

## 4. US4 — Acessibilidade (P3)

1. Ativar fonte ampliada → navegar por todas as telas (incluindo `ConsultaProtocoloPage`) → **Esperado**: nada cortado
2. Ativar modo de contraste para daltonismo → **Esperado**: elementos interativos ainda distinguíveis
3. Ativar leitura em voz alta → passar o foco sobre uma pergunta do assistente → **Esperado**: leitura em pt-BR

## 5. US5 — Assistente de dúvidas (P3)

1. Abrir o `FloatingAgeWidget` a qualquer momento → perguntar sobre um serviço fiscalizado → **Esperado**: resposta institucional coerente
2. Perguntar como acompanhar a manifestação → **Esperado**: resposta menciona a tela de consulta por protocolo e chave

## Anti-robô (falha fechada)

Implementação: `ci-api-v2/src/modules/ouvidoria/repository/verify-public-challenge.repository.ts`  
Testes: `ci-api-v2/src/modules/ouvidoria/test/repository/verify-public-challenge.repository.spec.ts` + `criar-manifestacao-publica.use-case.spec.ts` (400 `CHALLENGE_INVALID`)

1. Sem `RECAPTCHA_SECRET_KEY` configurada → qualquer `challengeToken` com **≥ 4 caracteres** passa (bypass de dev; client usa fallback `dev-bypass-token` quando `VITE_RECAPTCHA_SITE_KEY` está vazio)
2. Com a secret configurada e o Google respondendo → token reCAPTCHA v3 com `action=submit_manifestation`, `score ≥ 0.5`
3. Secret presente + `siteverify` indisponível (timeout/HTTP erro/rede) → repositório retorna `false` → **Esperado**: HTTP 400, `code: CHALLENGE_INVALID`

## Pipeline de deploy

```powershell
cd ci-client-v2; npm run build   # turbo → apps/web + apps/admin-saas + apps/publico/dist/
docker compose -f compose.dev.yaml up publico   # serviço dev na porta 5175
```

**Esperado**: `@ci/publico` no `turbo build`, stage `publico` no `ci-client-v2/Dockerfile` (nginx) e serviço `publico` no `compose.dev.yaml`.  
**Nota compose**: o serviço define `VITE_API_URL`, mas o app lê `VITE_API_BASE_URL` (`tenant-config.ts`); sem override explícito, o default `http://localhost:3000` aplica.

---

## Validação T063 (estática vs manual)

| Área | Verificado estaticamente / testes | Requer API+DB+ browser |
| --- | --- | --- |
| **§1 US1** | Endpoints, schema Zod, fluxo matrícula (teste Vitest `PublicChatbotForm` água), copy chave no `ReviewFormModal` | Fluxo completo chatbot (iluminação, institucional, anônimo+e-mail, submit E2E) |
| **§2 US2** | `MAX_ANEXO_BYTES=30MB`, extensões, resposta `{ tempId, uploadUrl, expiresIn }`, bind via `anexoTempIds[]` (Jest upload/bind) | Drag-drop UI, PUT binário, confirmar `uploadConfirmed` no detalhe interno |
| **§3 US3** | `GET /ouvidoria/consulta?protocol&chave`, labels públicos (`PUBLIC_MANIFESTACAO_STATUS_LABEL`), 404 genérico e 429 (Vitest `ConsultaProtocoloPage`) | Consulta real com protocolo/chave gerados na US1 |
| **§4 US4** | `AccessibilityContext` persiste fonte/contraste/leitura `pt-BR` (Vitest T053) | Inspeção visual em todas as telas (fonte ampliada, daltonismo) |
| **§5 US5** | `FloatingAgeWidget` menciona protocolo+chave+consulta (Vitest T057) | Resposta institucional sobre serviço fiscalizado (conteúdo livre) |
| **Anti-robô** | Bypass ≥4 chars sem secret; falha fechada com secret+mock rede/503 (Jest CT-OUV-PUB-004); 400 `CHALLENGE_INVALID` no use case | reCAPTCHA real com chaves Google de teste |
