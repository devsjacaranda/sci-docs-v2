# Revisão de segurança — 054 Download em Massa (OWASP)

Base: skill `owasp-security` (Top 10:2025, ASVS 5.0). Escopo: as rotas novas, o cache de PDF, o ZIP e o cliente que grava o arquivo. Cada achado diz o caminho concreto e se é explorável ou defesa em profundidade.

O ativo é o dossiê da manifestação (texto, identificação do solicitante, anexos). O abuso óbvio é extrair volume — várias manifestações, até ~300 MB — por quem não deveria ver alguma delas, ou derrubar o processo com geração paralela.

## Modelo de ameaça

| Ativo | Ameaça | Controle |
|---|---|---|
| Conteúdo da manifestação | IDOR: UUID de outro usuário/tenant no array | Preflight carrega com `tenantId` + `deletedAt: null`. Fora do tenant → `naoEncontradas` (404). No tenant sem acesso (047) → lote inteiro 403, zero bytes. Cache não pula essa checagem |
| Ticket / sessionId | Quem não é o dono baixa o ZIP ou lê o progresso | Progresso e cancelamento: Bearer + `userId` + `tenantId` da sessão; alheio responde 404. Arquivo: Bearer do dono **ou** ticket; ticket de 256 bits, 60 s, uso único |
| Ticket na query | Vaza em log, Referer, histórico | Sem PII dentro do token; `Referrer-Policy: no-referrer`; pino não loga a query `ticket`; TTL 60 s; uso único. Ver R-1 |
| ZIP | Zip Slip / sobrescrita via nome de anexo | Nomes passam por sanitização; entrada nunca usa `storageKey` nem path do cliente; teste de regressão com `../` e absoluto |
| Cache | PDF de um tenant servido a outro; PDF velho após exclusão de anexo | Chave começa com `tenantId` via `buildStorageKey`; `validateTenantPath` antes de ler; revisão inclui fingerprint com `deletedAt` |
| Disponibilidade | 50 PDFs grandes em paralelo, várias abas, vários usuários | 1 por usuário, 2 no processo, 50 itens, ~300 MB, geração sequencial, aborta no `close` |
| Auditoria | AdminTenant gravado como se fosse `User.id` (FK quebra ou atribui pessoa errada) | `resolveUserTableId` + `withActorPayload` |
| Erro | Stack, chave S3 ou nome de cidadão na resposta | Códigos estáveis + mensagem em português; detalhe só no log, e o log não leva ticket nem conteúdo |

## Mapeamento OWASP Top 10:2025

| # | Item | Situação |
|---|---|---|
| A01 Broken Access Control | **Endereçado.** Deny-by-default no use case, não no client. Uma manifestação sem acesso recusa o lote inteiro antes do stream. Sessão alheia é 404. Cache atrás da mesma checagem |
| A02 Security Misconfiguration | **Endereçado na app, com rede de operação.** Objetos de cache no mesmo bucket privado dos anexos. A app apaga expirado e revisão substituída; lifecycle 48 h no prefixo só se a exclusão falhar. Sem ACL pública. Credencial Wasabi inalterada |
| A03 Supply Chain | Dependência nova `yazl`, versão exata no `package.json` (sem `^` solto além do que o repo já pratica — travar no lockfile). Nenhuma outra lib de ZIP no caminho deste fluxo (`jszip` fica fora) |
| A04 Cryptographic Failures | Ticket sai de CSPRNG (`crypto.randomBytes(32)`). Comparação em tempo constante. TLS do Wasabi já existente. Sem segredo novo em código |
| A05 Injection | Prisma parametrizado na busca e no preflight. Nomes de ZIP sanitizados (allowlist de caracteres + rejeitar `..`, separadores, controle). Chave S3 só por `buildStorageKey` |
| A06 Insecure Design | **Endereçado.** Preflight antes do byte; tetos de quantidade, volume e concorrência; aborta ao desconectar; índice por último para ZIP incompleto não parecer válido. Residuais R-1 a R-4 |
| A07 Authentication Failures | Herda o guard JWT global. Ticket não autentica o resto da API |
| A08 Software/Data Integrity | ZIP truncado (sem `end()`) não é pacote válido. Cache amarrado ao fingerprint; época `PDF_RENDER_REVISION` impede servir PDF de layout antigo depois de mudar renderer/timbrado |
| A09 Logging & Alerting | Log Pino `bulk_download.refused` / `.started` / `.completed` / `.failed` (ids, actor, role, resultado; **sem** ticket e **sem** conteúdo). `AuditLog` em todo desfecho (FR-027). Redigir query `ticket` no serializer |
| A10 Exceptional Conditions | Fail-closed: erro na checagem de acesso ou tamanho desconhecido → recusa, nada transmitido. Anexo isolado ilegível → índice, o resto segue. Erro fatal no meio → destrói o stream sem finalizar o ZIP e audita `falho`. Mensagem sem internals |

## ASVS 5.0 (itens tocados)

- **8.2.1 / 8.2.2 / 8.3.1** — autorização por objeto no use case do servidor, para cada id, inclusive quando o PDF está em cache.
- **1.2.4 / 1.2.5** — query parametrizada; nenhuma chamada de SO com nome de arquivo.
- **2.2.1 / 2.2.2** — body e query validados por Zod (allowlist de tamanho: 1–50 UUID, `q` 2–80).
- **7.2.3** — ticket com 256 bits de CSPRNG (o requisito fala de sessão; o ticket é capability e segue a mesma barra).
- **14.2.1** — o download nativo (único caminho desde 2026-10-09) põe o ticket na URL; mitigado em R-1 (não é PII, é capability de 60 s). Nenhum nome de arquivo, protocolo ou id de manifestação precisa ir na query: o `sessionId` no path é opaco e inútil sem Bearer ou ticket.
- **16.3.1–16.3.4 / 16.5.1** (L2) — recusa, sucesso, cancelamento e falha vão para log e `AuditLog`; usuário vê código + frase, não stack.
- **16.3.2 cláusula L3** (recomendada, não exigida) — decisões **permitidas** também ficam no audit `concluido`, não só as negativas.

## Achados

### F1 — Repositories atuais do Ouvidoria não filtram tenant (pré-existente, herdado da 053)

- **Caminho**: `FindManifestacaoByIdRepository` e vizinhos usam o client Prisma base, sem `tenantId` no `where`. `assertForUser` não compara tenant; papéis admin passam direto.
- **Alcançabilidade**: quem já está autenticado e souber um UUID de outro tenant. A 053 classificou como teórico / defesa em profundidade.
- **Impacto aqui**: reutilizar esse find no preflight poderia colocar manifestação de outro tenant no ZIP de um admin. **Mitigação desta feature**: repository novo do lote, `where` com `tenantId` e `deletedAt: null`. Id fora desse conjunto entra em `naoEncontradas` e o lote não gera. Não reutilizar o find solto.

### F2 — `getObjectBuffer` materializa o objeto inteiro (pré-existente)

- **Caminho**: `StorageService.getObjectBuffer` faz `transformToByteArray()`. O PDF individual depende disso.
- **Impacto**: usar isso para cada original não embutível de um lote segura centenas de MB no processo, além de abrir espaço para DoS de memória.
- **Mitigação**: método novo `getObjectStream` (e `headContentLength`) com a mesma `validateTenantPath`. O lote usa stream para originais e para hit de cache. `getObjectBuffer` permanece para o merge de imagem/PDF, um anexo por vez, dentro de uma manifestação.

## Riscos residuais aceitos

| ID | Risco | Por que aceito |
|---|---|---|
| R-1 | Ticket na query do fallback pode aparecer em log de proxy que a app não controla, ou em histórico local do navegador | 256 bits, 60 s, uso único, sem PII, Referrer-Policy. O caminho com Bearer não usa ticket. Trocar por cookie cross-site piora CSRF |
| R-2 | Restart da API no meio do download derruba a sessão (memória) | O cliente vê falha; não fica ZIP "oficial" sem índice. Cache já gravado de manifestações anteriores continua válido. Sem dado corrompido no banco |
| R-3 | Mais de um processo Node: teto global e ticket não se enxergam | Deploy atual é um processo; não há Redis. Segundo processo é mudança de infra e exige outro desenho (não esta spec) |
| R-4 | Uma manifestação com muitas imagens grandes ainda segura **um** PDF na RAM (pdf-lib) | A spec limita a soma do lote, não o pico de uma peça. Sequencial + teto de 2 sessões impede o pico de multiplicar por 50. Original de vídeo/planilha não entra nessa RAM |

## Testes de segurança mínimos

- Lote com um id de outro tenant → 404, body só com esse id, nenhum byte de ZIP, audit `recusado`.
- Lote com um id do tenant sem acesso 047 → 403 do lote inteiro, mesmo que as outras sejam do usuário.
- `sessionId` de outro usuário com Bearer válido → 404 no progresso, no cancelamento e no arquivo.
- Ticket expirado, ticket trocado, segundo GET → 410 ou 409, sem stream.
- Nome de anexo `../../etc/passwd` e `a\\b` → entrada dentro de `{slug}/anexos/`, sem sair.
- Cache hit não é servido se `assertForUser` falha (teste duplo: objeto existe, acesso negado).
- Log/audit de um pedido de teste não contém o ticket nem o corpo do PDF.

## Addendum 2026-10-09 (PDF único)

- O ticket na URL (R-1) passa a valer para **todos** os navegadores: o download é sempre nativo.
- A montagem usa diretório temporário em disco do servidor: nome aleatório (mkdtemp), removido em sucesso/falha/cancelamento (dispose()); nada de storageKey/ticket em nomes de arquivo temporário. Disco cheio = falha na geração, sem conteúdo parcial entregue.
- O teto de ~300 MB limita a memória da junção do PDF (pdf-lib em memória, heap 3 GB). Proxy com timeout curto pode abortar a montagem: aceitar como falha na geração e tentar de novo (cache de 24 h acelera).
- Zip slip: agora cobre apenas os originais fora do PDF no ZIP condicional (sanitize-zip-entry-name).
