# Quickstart — validar 054

Guia de verificação, não o implementação. Contratos em [contracts/rest-api-download-massa.md](./contracts/rest-api-download-massa.md). Segurança em [security.md](./security.md).

## Pré-requisitos

- API e SPA de desenvolvimento no ar (tenant de teste, usuário da Ouvidoria e um segundo usuário **sem** acesso a pelo menos uma manifestação).
- Três manifestações conhecidas no tenant: uma só com dados, uma com JPG ou PDF anexado, uma com `.docx` ou `.xlsx`.
- Anotar um UUID de manifestação de **outro** tenant, se houver base para isso.

```powershell
cd ci-api-v2; npm test -- --testPathPatterns=bulk-download
cd ci-client-v2/apps/web; npm test -- BulkDownload
```

TDD: cada teste abaixo nasce vermelho antes do código de produção correspondente.

## 0. Operação do bucket (uma vez por ambiente)

A aplicação apaga o PDF de cache ao passar de 24 h e ao gravar uma revisão nova. Lifecycle no prefixo `…/ouvidoria/pdf-cache/` (48 h) é só rede de segurança. Objetos privados, mesma credencial dos anexos.

## 1. Caminho feliz (SC-001, SC-009, SC-012)

1. Na lista, "Baixar em massa". Buscar `2026-3-09` (ou o trecho real), escolher 3 manifestações **só com dados, JPG ou PDF**, confirmar.
2. O indicador mostra "0 de 3 manifestações" e o aviso de montagem no servidor; o navegador baixa **um único `.pdf`** assim que a montagem termina.
3. Abrir o PDF: para cada manifestação, uma **página inteira de separação** (protocolo; listas de embutidos / fora do PDF / indisponíveis) seguida do dossiê completo com timbrado e anexos embutidos. A **última página** é o resumo do lote (autor, data/hora do download, gerado agora × reaproveitado).
4. Repetir com uma manifestação que tem `.docx`/`.xlsx`/`.mp4`: o download é um **`.zip`** com o PDF único + `{manifestação}/anexos/…`; separador e resumo listam os "fora do PDF".
5. Não existem `lote.txt` nem `indice-do-lote.pdf`.
## 2. Cache (SC-004, SC-007)

1. Repetir o mesmo lote. O segundo conclui pelo menos 3× mais rápido e a página-resumo marca reaproveitado, com "gerado em" **anterior** ao deste download.
2. Excluir um anexo (fluxo da 053) ou tramitar uma das manifestações. Baixar de novo. Essa manifestação vem como gerada agora; o anexo excluído não aparece.
3. PDF individual da mesma manifestação (rota já existente) continua recusando acima de 200 MB de anexos. O lote não usa esse teto; usa o de ~300 MB.

## 3. Recusas (SC-005, SC-006)

| Ação | Esperado |
|---|---|
| Incluir uma manifestação que o usuário não acessa (047) | 403 `LOTE_ACESSO_NEGADO`, modal lista qual, nenhum arquivo |
| Incluir UUID de outro tenant | 404 `LOTE_NAO_ENCONTRADA`, sem dizer que existe noutro lugar |
| 51 ids | 422 `LOTE_LIMITE_QUANTIDADE` antes de qualquer geração |
| Seleção cuja soma de anexos passa de 314 572 800 bytes (300 MiB) | 422 `LOTE_LIMITE_VOLUME` |
| Segunda aba disparando outro lote enquanto o primeiro transmite | 409 `LOTE_JA_EM_ANDAMENTO` |

Cada linha gera audit `recusado` com o código, sem ticket e sem conteúdo.

## 4. Montagem, cancelar, falha (SC-003, SC-008, FR-021)

1. Lote grande (perto do teto de 300 MiB, ou o maior que o ambiente de teste permitir). Memória do processo fica limitada pelo teto; os dossiês individuais ficam em disco temporário, removido ao fim.
2. Cancelar no indicador. Em até 5 s o processo para de ler armazenamento (log de sessão `cancelada`). O diretório temporário do download é removido.
3. Derrubar a leitura de um anexo no meio (chave ausente). O download **conclui**, o separador e o resumo citam o arquivo como indisponível (`armazenamento`) e o restante está lá.
4. Forçar erro fatal na renderização de uma manifestação. O indicador mostra falha na geração, nenhum arquivo parcial é entregue, audit `falho` e o diretório temporário é removido.

## 5. Navegador e navegação (FR-019, FR-019a)

1. Qualquer navegador (inclusive Chrome/Edge): **não** abre seletor de local; o download é o nativo do navegador, e o indicador mostra "N de total" ao trocar de página dentro da SPA. Fechar o modal não cancela.
2. Cancelar no indicador durante a montagem: `POST …/cancelar`, o servidor para em até 5 s e o indicador mostra "Download cancelado.".
3. A URL do download leva `ticket` e a resposta manda `Referrer-Policy: no-referrer`. Repetir o GET com o mesmo ticket → 409. Esperar 60 s sem abrir o GET → 410.
4. Proxy reverso: `proxy_read_timeout` ≥ 10 min; sem isso, lotes grandes podem falhar como "falha na geração".

## 6. Segurança objetiva

Executar a lista "Testes de segurança mínimos" de [security.md](./security.md). O de zip slip e o de cache com acesso negado são obrigatórios no Jest, não só manuais.

## Fora desta verificação

Retomada de download, checkboxes na lista, job em background, mais de um processo Node (R-3).
