# Research — 054 Download em Massa de Manifestações

Decisões técnicas que a spec deixou para o plano. Cada uma fecha um ponto que mudaria arquitetura, testes ou segurança.

## Addendum 2026-10-09 — correção para PDF único (substitui §2, §3, §5, §7 e §9 onde conflitarem)

A spec foi corrigida: a entrega é **um único PDF** (separador + dossiê por manifestação + página-resumo final), e só vira **ZIP** quando há anexos que não cabem em PDF. Decisões que valem a partir de agora:

- **A1. Montagem em disco, entrega no fim.** O `GET` cria `mkdtemp(os.tmpdir()/ouv-lote-)`, grava cada dossiê (cache hit ou geração nova) e cada original fora do PDF em arquivos, junta tudo com `pdf-lib` (`assembleLotePdf`) e só então responde. O download **não** começa em segundos (SC-002 revisado): o indicador mostra o progresso enquanto o navegador espera. `dispose()` apaga o diretório temporário em sucesso, falha e cancelamento.
- **A2. Teto 300 MiB.** `pdf-lib` carrega cada dossiê e o resultado em memória; o heap do Node está em 3 GB (`NODE_OPTIONS`). Por isso o teto de volume caiu de ~1 GB para 300 MiB (`BULK_DOWNLOAD_MAX_ATTACHMENTS_BYTES`). Quantidade segue 50.
- **A3. Extensão decidida no fim.** `fileName` do preflight não tem extensão. `resolveLoteDeliverable` escolhe `pdf` (sem originais) ou `zip` (com originais; `yazl` `addFile` do PDF e dos originais a partir de arquivos temporários). O servidor define `Content-Type`/`Content-Disposition`.
- **A4. Download nativo para todos.** `showSaveFilePicker` sai: ele exige conhecer o tipo antes e grava o corpo no cliente. O download nativo com ticket (§4) vira o único caminho; progresso por polling; Cancelar chama `POST …/cancelar`.
- **A5. Cache com sidecar.** Além de `{revision}.pdf`, grava-se `{revision}.report.json` (`{ issues: [{ fileName, storageKey, reason }] }`) com as pendências de embutimento, para que o PDF único reaproveitado reporte os mesmos anexos indisponíveis/`pdf-invalido`. PDF sem sidecar é miss. A exclusão das revisões anteriores (`deleteObjectsByPrefix`) acontece **antes** do `putObject` (corrige a ordem anterior, que apagava a revisão recém-gravada).
- **A6. Corrompido vs. indisponível.** Imagem/PDF lido mas inválido → original vai para o ZIP e fica listado `pdf-invalido`. Arquivo que o armazenamento não devolve → só listado, motivo `armazenamento`. `appendImagePage` embute a imagem antes de criar a página (sem página órfã).
- **A7. Risco operacional.** Proxy reverso com timeout curto pode cortar o GET durante a montagem. Configurar `proxy_read_timeout` ≥ 10 min (o cliente desiste do polling após ~10 min).
## 1. Entrega: preflight JSON + stream ZIP na segunda requisição

**Decision**: Duas rotas. `POST .../documento/massa` só valida e devolve um ticket (sem gerar PDF). `GET .../documento/massa/:sessionId/arquivo` escreve o ZIP em blocos na resposta. O progresso é `GET .../progresso` (JSON), autenticado com o Bearer da sessão.

**Rationale**: Recusas (403, 404, limite, ocupado) precisam ser HTTP de verdade, com corpo JSON, **antes** do primeiro byte. Depois que o ZIP começa, o status não muda mais. A spec exige recusar o lote inteiro sem entregar conteúdo (FR-010, FR-012) e, ao mesmo tempo, o download começar em segundos (FR-016, SC-002).

**Alternatives considered**:

- Um único POST cujo corpo já é o ZIP. Recusa tardia viraria ZIP truncado indistinguível de falha de rede.
- Job em fila com arquivo pronto para baixar depois. A spec excluiu explicitamente.

## 2. ZIP em streaming com `yazl` (dependência nova, versão fixa)

**Decision**: Gerar o ZIP com [`yazl`](https://github.com/thejoshwolfe/yazl), uma entrada por vez, pipe do `outputStream` para a resposta HTTP. `jszip` (já no projeto) **não** é usado aqui: ele monta o arquivo inteiro em memória.

**Rationale**: O teto é ~1 GB. Manter o lote em RAM viola FR-017 e SC-003. `yazl` escreve o cabeçalho local e os dados conforme cada entrada fecha, e só grava o diretório central no `end()`. Abortar sem `end()` produz um ZIP inválido — o navegador marca o download como falha, que é o sinal de FR-021 (nunca parecer completo).

**Alternatives considered**:

- `archiver`: mesmo papel, superfície maior.
- Escrever o formato ZIP à mão: mais código e mais chance de pacote corrompido ou caminho inseguro.
- `jszip`: pico de memória ≈ tamanho do lote.

## 3. Dois caminhos no navegador, o mesmo GET

**Decision**:

- **Com `showSaveFilePicker`** (Chromium): `fetch` do GET com header `Authorization`, leitura do corpo em blocos e gravação direta no arquivo escolhido (`pipeTo`). Progresso nosso (poll) + Cancelar nosso (`AbortController`). A interface não acumula o ZIP.
- **Sem a API** (Firefox, Safari): o mesmo GET aberto pelo gerenciador de downloads do navegador, com ticket opaco de uso único na query (ver §4). O modal avisa que o progresso detalhado não está disponível (FR-019a). Cancelar é o do navegador; o servidor vê o socket fechar e aborta (FR-020).

**Rationale**: O login da SPA manda `Authorization: Bearer`, não cookie. Um `<a href>` nativo não envia esse header. O caminho Chromium não precisa de segredo na URL. O fallback precisa, e fica restrito ao ticket (§4 e [security.md](./security.md)).

**Alternatives considered**:

- `fetch` + `Blob` em todo navegador: estoura a memória no fallback (proibido por FR-017 / FR-019a).
- Cookie de curta duração no POST: cruza origem da API e da SPA e mexe em CSRF. Descartado.

## 4. Ticket de download (só o fallback)

**Decision**: 32 bytes de `crypto.randomBytes`, codificados em base64url. Vive só em memória, amarrado a `sessionId` + `userId` + `tenantId`. TTL de 60 s. Uso único: o segundo GET recebe 409. A rota de progresso **não** aceita ticket — só Bearer — e confere dono da sessão.

**Rationale**: É uma capability de um único ZIP já autorizado, não uma sessão. Mitigações (ASVS 14.2.1) em [security.md](./security.md): sem PII no token, `Referrer-Policy: no-referrer`, redação do query param nos logs, HTTPS, TTL curto, uso único.

**Alternatives considered**: JWT longo na query (vazaria escopo e seria reutilizável); ticket persistido no banco (desnecessário para 60 s e sobrevive a restart sem ganho).

## 5. Primeiro byte em < 5 s (SC-002)

**Decision**: A primeira entrada do ZIP é `lote.txt` (só os protocolos/números já validados no preflight, um por linha). Ela é escrita **antes** de gerar qualquer PDF. O índice oficial `indice-do-lote.pdf` é a **última** entrada, depois de todas as manifestações.

**Rationale**: Renderizar o primeiro PDF pode levar mais de 5 s. Sem uma entrada imediata, o SC-002 falha mesmo com streaming. O índice no fim também garante FR-021: ZIP sem diretório central (conexão cortada no meio) não abre como pacote completo, e o índice só existe se a geração terminou.

**Alternatives considered**: Segurar a resposta até o primeiro PDF (estoura o SC-002); índice no começo (não conheceria anexos indisponíveis e precisaria ser reescrito).

## 6. Cache do PDF no Wasabi, chave = revisão, sem tabela nova

**Decision**: Objeto `{tenantId}/ouvidoria/pdf-cache/{manifestacaoId}/{revision}.pdf`, com metadata `generatedAt`. `revision` é o SHA-256 de:

- `manifestacao.updatedAt`
- `concessionaria.updatedAt` (se houver)
- fingerprint dos anexos (id, nome, mime, tamanho, `storageKey`, `createdAt`, `deletedAt` — incluir e excluir anexo muda a chave)
- maior `evento.createdAt`
- constante `PDF_RENDER_REVISION` (inteiro no código, sobe quando o renderer muda)
- data de alteração dos arquivos de timbrado resolvidos por `resolveLetterheadAssets` (trocar o PNG invalida sem subir o inteiro)

Servir só se `generatedAt` tiver menos de 24 h. Objeto mais velho é apagado nesse acesso e a manifestação é gerada de novo. Hit dentro do prazo vale até o fim daquela manifestação no lote, mesmo se as 24 h virarem no meio da transmissão. Hit de cache vai de Wasabi para o ZIP por stream, sem buffer. Miss: gera um PDF, grava no cache, apaga as outras revisões do mesmo prefixo da manifestação, acrescenta ao ZIP e libera o buffer antes da próxima. Falha ao apagar não falha o download.

Falha ao **gravar** o cache não falha o download (o PDF segue no ZIP). Falha ao **ler** com chave de outro tenant é erro (a chave sempre sai de `buildStorageKey` + `validateTenantPath`, nunca de input do usuário).

**Rationale**: A spec pede reuso por 24 h, invalidação quando o conteúdo ou o timbrado mudam, e apagar o que deixou de valer (FR-022 a FR-026). A chave por revisão acha o arquivo certo. Apagar as outras chaves do prefixo da manifestação, e apagar o objeto no acesso em que ele passa de 24 h, cumpre o FR-024 sem tabela nova. A data de alteração dos PNG de timbrado entra no hash porque esses arquivos não têm `updatedAt` no banco. `PDF_RENDER_REVISION` cobre mudança de código do renderer.

**Alternatives considered**:

- Coluna/tabela `pdfCacheKey`: migration e job de limpeza para o mesmo resultado.
- Cache em memória do processo: perde no restart e não segura PDF grande com segurança.
- Reaplicar "gerado em" a cada download: o PO escolheu manter o carimbo da geração original.

**Operação**: a aplicação apaga o objeto expirado e as revisões substituídas. Lifecycle no bucket apagando o prefixo `*/ouvidoria/pdf-cache/` após 48 h fica só como rede de segurança, se uma exclusão falhar. Documentado no [quickstart.md](./quickstart.md), não é migration.

## 7. O que entra em cada PDF e o que vai solto no ZIP

**Decision**: Reusar `renderManifestacaoPdf` + `mergeAnexosIntoManifestacaoPdf` + `applyLetterheadPdfkit`. O lote **não** chama `assertManifestacaoExportSizeWithinLimit` (200 MB continuam só no PDF individual, FR-013). O renderer ganha a lista "Anexos não embutidos" (nome e tamanho) — única mudança de conteúdo, compartilhada com o PDF individual para os dois continuarem iguais (FR-006 / FR-007).

Originais não embutíveis (doc, docx, txt, xls, xlsx, mp3, mp4) e PDF/imagem que falhar ao embutir: stream `getObjectStream` → entrada do ZIP. Não bufferizar.

**Rationale**: pdf-lib precisa do PDF inteiro para mesclar páginas; não há como embutir imagem sem os bytes. O teto de memória do lote é o **maior PDF de uma manifestação**, não a soma, porque a geração é estritamente sequencial.

## 8. Limites de concorrência

**Decision**: 1 download em massa em transmissão por usuário; 2 simultâneos no processo. Excedente: 409 `LOTE_JA_EM_ANDAMENTO` (mesmo usuário) ou 429 `LOTE_SERVIDOR_OCUPADO` (global), antes de criar sessão. Contadores só em memória.

**Rationale**: A spec fixou o comportamento e deixou os números para o plano. 2 protege o pico de um PDF grande por vez (dois no máximo). 1 por usuário cobre o caso das duas abas.

**Alternatives considered**: Fila com espera (parece job e segura conexão); sem teto global (um lote de imagens grandes por usuário já basta para pressionar o processo, vários pioram).

**Premissa**: uma instância da API. Não há Redis no projeto. Se houver mais de um processo, o teto e o ticket deixam de ser globais — ver risco R-3 em [security.md](./security.md).

## 9. Nomes dentro do ZIP

**Decision**:

```text
lote.txt
{slug}/Manifestacao_{slug}.pdf
{slug}/anexos/{nome-seguro}
indice-do-lote.pdf
```

`slug` = número personalizado, senão protocolo, senão id. Nome seguro: sem `\`, `/`, `..`, caracteres de controle; truncado; colisão ganha sufixo ` (2)`. Pasta do slug repetido também. Nada do nome vem de caminho do storage.

## 10. Auditoria no `AuditLog` existente

**Decision**: Uma linha por pedido, action `ouvidoria.manifestacao.bulk_download`, entity `Manifestacao`, `entityId` nulo (o lote não é uma manifestação). `userId` = `resolveUserTableId` (null para `admin_tenant` / `admin_saas`). Payload via `withActorPayload`: `actorId`/`actorRole` quando não há linha em `User`, mais `resultado`, `motivo`, `manifestacaoIds`, `totalBytes`, `cacheHits`. Sem conteúdo de PDF, sem nome de cidadão, sem ticket.

Momento: recusa no preflight grava na hora; transmissão grava no fim (concluído, cancelado ou falho).

**Rationale**: FR-027 e a regra `admin-tenant-user-fk`. Sem migration (`userId` já é opcional).

## 11. Busca do dropdown

**Decision**: `GET /ouvidoria/manifestacoes/busca-download?q=` com `q` de 2 a 80 caracteres, no máximo 20 linhas, `tenantId` + `deletedAt: null`, `protocol` ou `numeroPersonalizado` contém `q` (Prisma parametrizado). Resposta: `id`, `protocol`, `numeroPersonalizado`, `status`. Sem descrição, sem dados do solicitante.

**Rationale**: A lista já mostra todas as manifestações do tenant (spec 047: 403 só no acesso direto). O dropdown segue a mesma regra. O acesso é cobrado no preflight, não na busca (FR-005 é isolamento de tenant + resposta rápida, não filtro por dono).

## 12. Andamento ao navegar

**Decision**: `BulkDownloadProvider` em `ci-client-v2/apps/web/src/App.tsx`, dentro de `AuthProvider` e por fora do `RouterProvider`, não na página da lista. O modal mora na lista; o indicador (progresso + Cancelar) fica montado enquanto a sessão existir. Fechar o modal ou trocar de rota não aborta o `fetch`.

**Rationale**: FR-019 (clarify). Provider só dentro do módulo Ouvidoria desmontaria ao sair e cancelaria o download.
