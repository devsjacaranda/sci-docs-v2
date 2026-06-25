# Quickstart: Validação Ouvidoria Interna

**Feature**: 003-ouvidoria  
**Prerequisites**: Node.js 20+, PostgreSQL, Wasabi (ou MinIO local compatível S3), `.env` em `ci-api-v2`  
**References**: [data-model.md](./data-model.md) · [contracts/](./contracts/) · [spec.md](./spec.md)

> Executar **após** implementação (`/speckit-implement`). Cenários mapeiam user stories da spec.

## Setup inicial

```powershell
cd ci-api-v2
npm install
npx prisma migrate dev
npx prisma db seed

# .env — adicionar Wasabi/MinIO
# WASABI_ENDPOINT=http://localhost:9000
# WASABI_BUCKET=ci-anexos
# ...

npm run start:dev
```

Em outro terminal:

```powershell
cd ci-client-v2
npm install
npm run dev
```

**Expected**: API `:3000`; client `:5173`; seed com setor Ouvidoria vinculado ao módulo; municípios IBGE carregados.

---

## VS-001 — Permissão módulo Ouvidoria (US5)

| Step | Action | Expected |
|------|--------|----------|
| 1 | Login usuário lotado Ouvidoria | JWT OK |
| 2 | GET `/ouvidoria/manifestacoes` | 200 lista |
| 3 | Login usuário só Patrimônio (sem vínculo) | JWT OK |
| 4 | GET `/ouvidoria/manifestacoes` | 403 `MODULO_SETOR_DENIED` |

Client: navegar `/ouvidoria/manifestacoes` — 403 padronizado; item sidebar visível.

---

## VS-002 — Registrar manifestação completa (US1)

| Step | Action | Expected |
|------|--------|----------|
| 1 | POST rascunho com campos obrigatórios | 201 `status: rascunho` |
| 2 | POST presign anexo PDF 1 MB | 200 `uploadUrl` |
| 3 | PUT arquivo no storage | 200 storage |
| 4 | POST confirm anexo | 200 |
| 5 | GET revisão | Dados + anexo listados |
| 6 | POST confirmar | 200 `protocolo` + `chaveConsulta` |
| 7 | GET lista | Item com protocolo |

**Expected**: copy revisão presente no client wizard step 3.

---

## VS-003 — Anexo inválido (US2, FR-008)

```powershell
curl -s -X POST "http://localhost:3000/ouvidoria/manifestacoes/{id}/anexos/presign" `
  -H "Authorization: Bearer <token>" `
  -H "X-Tenant-ID: demo" `
  -H "Content-Type: application/json" `
  -d '{"fileName":"virus.exe","mimeType":"application/x-msdownload","sizeBytes":1024}'
```

**Expected**: 400 `FILE_TYPE_NOT_ALLOWED`

Arquivo > 30 MB → `FILE_TOO_LARGE`.

---

## VS-004 — Tramitar, responder, encerrar (US4)

| Step | Action | Expected |
|------|--------|----------|
| 1 | POST encaminhar com setor destino | `status: tramitando`; evento timeline |
| 2 | POST responder | `status: respondida`; evento resposta |
| 3 | POST encerrar | `status: encerrada`; ações bloqueadas |

---

## VS-005 — Sigilo denúncia (US6)

| Step | Action | Expected |
|------|--------|----------|
| 1 | Criar denúncia `sigilo: true` com manifestante | Confirm OK |
| 2 | GET detalhe como usuário sem setor Ouvidoria mas com acesso leitura* | `manifestante: null` |
| 3 | GET detalhe como admin_plataforma | manifestante completo |

\* Se produto restringir leitura cross-setor, ajustar cenário — sigilo aplica dentro de quem vê o módulo.

---

## VS-006 — Consulta pública (US7, FR-017)

```powershell
curl -s "http://localhost:3000/ouvidoria/consulta?protocolo=OUV-2026-0138&chave=K7X9M2P4" `
  -H "X-Tenant-ID: demo"
```

**Expected**: 200 status + marcos; sem PII.

Chave errada:

**Expected**: 404 mensagem genérica (mesma de protocolo inexistente).

---

## VS-007 — Isolamento tenant (FR-018)

Consultar manifestação tenant A com header tenant B.

**Expected**: 404 ou lista vazia; zero vazamento cross-tenant.

---

## VS-008 — Edição bloqueada pós-encaminhamento (FR-020)

PATCH relato após encaminhar.

**Expected**: 403 `MANIFESTACAO_NOT_EDITABLE`.

---

## Testes automatizados

```powershell
cd ci-api-v2
npm test -- --testPathPattern=ouvidoria
npm run test:e2e -- --testPathPattern=ouvidoria
```

**Expected**: RED antes implementação; GREEN após `/speckit-implement`.

---

## Checklist pós-smoke

- [ ] Protocolo único em 10 confirmações sequenciais
- [ ] Badges vencendo/critico na lista conforme prazo
- [ ] Copy mint-palette nos CTAs wizard
- [ ] Chave consulta exibida uma vez no client
