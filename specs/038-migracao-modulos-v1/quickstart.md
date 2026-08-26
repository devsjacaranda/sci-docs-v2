# Quickstart — Validação da Migração de Módulos v1 → v2

**Spec**: [spec.md](./spec.md) · **Plan**: [plan.md](./plan.md) · **Contratos**: [contracts/](./contracts/README.md)

Guia de execução e validação. Cenários organizados pelas histórias de usuário da spec. Detalhes de contrato e de modelo estão nos documentos referenciados, não duplicados aqui.

---

## 1. Pré-requisitos

| Item | Requisito |
|---|---|
| Node | versão exigida pelo Playwright (22, 24 ou 26) |
| PostgreSQL | base do v2, com migrações aplicadas |
| MySQL local | base do v1 restaurada a partir do dump de produção `controleinterno_prod_ci (14).sql` |
| MySQL externo | base de processos judiciais do Diagnóstico, acesso somente leitura |
| Wasabi | mesmo bucket usado pelo v1 |
| Código do v1 | `C:\controle-interno-workspace\controle-interno-api` e `controle-interno-client`, para comparação lado a lado |

### Variáveis de ambiente

Nomes apenas — valores não constam desta documentação.

| Pacote | Variáveis |
|---|---|
| `ci-api-v2` | `DATABASE_URL`, `DATABASE_URL_UNPOOLED`, `JWT_*`, `MYSQL_V1_URL`, `DIAGNOSTICO_DATABASE_URL`, `DIAGNOSTICO_PROCESSO_TABLE`, `DIAGNOSTICO_DB_POOL_SIZE`, `DIAGNOSTICO_QUERY_CACHE_TTL_MS`, `DIAGNOSTICO_QUERY_CACHE_MAX_ENTRIES`, `WASABI_ENDPOINT`, `WASABI_REGION`, `WASABI_BUCKET`, `WASABI_ACCESS_KEY`, `WASABI_SECRET_KEY` |
| `ci-client-v2` | `VITE_API_URL`, `VITE_TENANT_ID` |
| `apps/publico` | `VITE_API_URL`, `VITE_TENANT_ID`, `VITE_TENANT_SLUG`, `VITE_TENANT_NAME`, e a chave pública da verificação contra automação |
| `e2e` | endereços dos dois clientes e da API, e credenciais de teste — **sem valor padrão embutido** |

**Atenção**: `WASABI_PREFIX` deve permanecer vazio. Preenchê-lo faria as chaves novas ganharem prefixo enquanto as migradas não o têm.

### Verificação obrigatória de storage

Antes de qualquer coisa, confirmar que a API **não** está em modo de armazenamento local. Sintoma do defeito corrigido por esta feature: endereços de download apontando para caminho local em vez do provedor. Com as variáveis validadas no schema de ambiente, a API deve **falhar no boot** se a configuração estiver incompleta — comportamento esperado, não regressão.

### Portas

| Serviço | Porta |
|---|---|
| API v2 | 3000 |
| Cliente v2 (`@ci/web`) | 5173, fixa |
| Cliente v2 admin | 5174 |
| Portal público v2 | porta própria, distinta das acima |
| API v1 | 3001 |
| Cliente v1 | 8080 |

A porta do cliente v2 é fixada explicitamente. Sem isso o Vite recorre à porta seguinte quando 5173 está ocupada, e os testes acabariam apontando para o app administrativo.

---

## 2. Subir o ambiente

```powershell
# API v2
cd ci-api-v2; npm run start:dev

# Cliente v2
cd ci-client-v2; npm run dev

# Portal público v2 (tenant por modo do Vite)
cd ci-client-v2; npm run dev:publico -- --mode ageman

# API v1 (porta 3001)
cd C:\controle-interno-workspace\controle-interno-api; npm run dev

# Cliente v1 (porta 8080, apontado para a API v1)
cd C:\controle-interno-workspace\controle-interno-client; npm run dev
```

Resultado esperado: os cinco serviços respondem, e o cliente v1 autentica contra a API v1 — não contra a v2.

---

## 3. Migração de dados (História 1)

Ordem obrigatória. Nenhuma etapa é dispensável.

```powershell
cd ci-api-v2

# 1. Contagem da origem, já descontando exclusões aprovadas
npm run migracao:count

# 2. Ensaio — percorre todo o mapeamento sem gravar
npm run migracao:dry-run

# 3. Execução
npm run migracao

# 4. Reconciliação
npm run migracao:compare
```

**Resultados esperados**:

| Etapa | Esperado |
|---|---|
| Contagem | três números por entidade — origem, exclusões, esperado |
| Ensaio | contagens idênticas às da execução real; nenhuma escrita no destino |
| Execução | conclui sem erro; relatório de anexos lista o que não foi localizado |
| Reconciliação | todas as entidades conformes; código de saída de sucesso |

**Verificações que não podem ser puladas**:

1. **Idempotência** — executar a migração duas vezes seguidas e conferir que a segunda não altera contagem alguma. Esta é a verificação mais importante: o pipeline herdado grava parte das entidades sem chave natural, e é exatamente aí que a duplicação aparece.
2. **Interrupção** — interromper a execução no meio, reexecutar, e conferir ausência de registro parcial ou duplicado.
3. **Origem intacta** — comparar as contagens do v1 antes e depois. Devem ser iguais.
4. **Rastreabilidade** — buscar no v2 por um identificador conhecido do v1 e encontrar o registro correspondente.
5. **Anexo antigo** — abrir no v2 um anexo migrado e confirmar o download do arquivo, com o nome original preservado.

O comparador precisa provar que sabe reprovar: existe teste que introduz divergência deliberada e exige falha. Rodar a suíte de migração antes de confiar no relatório.

```powershell
cd ci-api-v2; npm test -- --testPathPatterns=migracao
```

---

## 4. Ouvidoria (História 2)

Pré-requisito: migração concluída e reconciliada.

| Cenário | Verificação |
|---|---|
| Listagem | filtros de situação, prioridade, tipo, motivo, canal e período retornam os mesmos conjuntos que o v1; a paginação percorre todos os registros |
| Registro | criar manifestação gera protocolo e número institucional; nenhum número se repete |
| Encaminhamento | manifestação encaminhada gera demanda vinculada, e o vínculo é navegável nos dois sentidos |
| Resposta | responder registra data, autor e evento na linha do tempo |
| Encerramento | encerrar exige informar se houve resolução; as duas modalidades ficam distinguíveis na listagem |
| Documentos | gerar o documento em formato editável e em PDF; conferir timbre e presença de todos os campos que o v1 imprimia |
| Painel | os sete indicadores conferem com os do v1 para o mesmo período |
| Catálogos | criar, editar e inativar tipos e formas de atendimento; confirmar que item em uso não pode ser excluído |
| Atendimentos internos | registrar, editar e excluir; confirmar que não gera manifestação |
| Auditoria | a listagem de eventos permite filtrar por período, autor e tipo |

**Comparação numérica com o v1** (critério de aprovação SC-011): abrir o painel do v1 e o do v2 no mesmo período e conferir cada indicador. Duas diferenças são **esperadas e corretas**, porque corrigem defeito do v1: o cartão de manifestações em análise mostra o valor real (no v1 o painel exibe zero fixo), e o cartão de respondidas conta apenas respondidas (no v1 o rótulo somava respondidas com encerradas).

---

## 5. Gabinete (Histórias 3 e 4)

| Cenário | Verificação |
|---|---|
| Encaminhar | situação passa a aguardando recebimento **e o setor atual muda** — este é o defeito corrigido; conferir na listagem filtrada por setor |
| Receber | disponível apenas quando aguarda recebimento; notifica quem encaminhou |
| Devolver | disponível apenas a partir do setor jurídico, com destino restrito |
| Reencaminhar | histórico permite distinguir do primeiro encaminhamento |
| Anexar resposta | registra evento sem alterar situação nem setor |
| Histórico em PDF | sequência completa, em ordem cronológica, com autor e setores por evento |
| Protocolos | filtros e paginação no servidor; anexos abrem |
| Documentos tramitados | cadastro único filtrável por setor; conferir que os registros das 13 origens estão presentes, incluindo os do setor jurídico que só têm vínculo |
| Controle numérico | os seis tipos presentes; campos próprios de cada tipo preservados — em especial o destino dos memorandos |
| Notificações e autos | valores monetários conferem centavo a centavo; agrupamento relaciona notificação e auto do mesmo caso |
| Diretorias | criar, editar, inativar; setor inativo sai dos destinos de encaminhamento mas permanece na administração |

**Verificação de consolidação** (critério SC-016): para cada uma das 13 origens de documentos tramitados e das 6 de controle numérico, confirmar contagem e conteúdo. Pontos de atenção conhecidos: a coluna de ordem existe em apenas duas das origens e **não** deve virar quantidade; o prazo existe em apenas uma origem e **não** deve virar observação; e uma das origens só tem vínculos, migrando como registro mínimo.

---

## 6. Diagnóstico (História 5)

| Cenário | Verificação |
|---|---|
| Listagem | uma linha por processo, mesmo quando a base externa tem várias; os sete campos de busca funcionam **no servidor** |
| Categoria e tipo de resultado | classificação idêntica à do v1 para os mesmos processos |
| Painel | totais refletem a base inteira, não a página; com filtro ativo isso fica explícito na tela |
| Marcadores | marcar, desmarcar, recarregar a página e reabrir em outro navegador com o mesmo usuário — a marcação persiste |
| Base indisponível | derrubar a conexão externa e confirmar mensagem explícita, sem lista vazia e sem dado inventado |
| Marcadores indisponíveis | confirmar erro explícito com nova tentativa — **nunca** aviso de "salvo apenas neste navegador" |
| Exportação | painel e seleção, com e sem gráficos; conferir timbre, filtro aplicado, data e responsável |
| Documentos institucionais | reservar número, salvar rascunho, enviar, cancelar com motivo, gerar PDF, consultar histórico de acessos |
| Reserva simultânea | reservar de duas sessões ao mesmo tempo e confirmar números distintos |
| Reserva abandonada | após o prazo, confirmar marcação como abandonada, **com registro de auditoria**, e que o número não é reutilizado |
| Documento enviado | confirmar que o conteúdo não aceita mais alteração e que a leitura registra acesso |
| Permissão | usuário fora do setor responsável vê apenas documentos enviados e não consegue reservar número |

**Comparação com o v1** (critério SC-013): mesmos filtros nos dois sistemas, conferindo total de processos e distribuições. Uma diferença é esperada: campos de busca que o v1 refinava no navegador sobre a página carregada passam a filtrar o conjunto completo — o v2 pode retornar **mais** resultados, e isso é correção, não divergência.

---

## 7. Portal público (História 6)

| Cenário | Verificação |
|---|---|
| Abertura identificada | fluxo guiado completo; recebe protocolo e chave de consulta |
| Abertura anônima | nenhum dado pessoal é solicitado nem armazenado |
| Campos por programa | água exige matrícula no formato próprio; iluminação exige protocolo e identificação de poste |
| Anexo | enviar arquivo, concluir a manifestação, e confirmar que o anexo aparece vinculado no lado interno |
| Consulta | protocolo e chave corretos retornam situação e resposta; chave incorreta responde igual a protocolo inexistente |
| Proteção contra automação | envio sem a verificação é recusado |
| Limite de envios | exceder o limite por origem resulta em recusa com orientação |
| Acessibilidade | ajuste de fonte, modos de daltonismo e leitura por voz funcionam — conferir especialmente os modos de cor, que dependem de definições no documento HTML |
| Responsividade | fluxo completo em largura de telefone |
| Aparência | paleta e tipografia do design system do v2, não as do portal antigo |

Confirmar que a manifestação aberta pelo portal aparece na listagem interna identificada como de origem pública.

---

## 8. Testes de navegador comparativos

```powershell
cd ci-client-v2
npm run test:e2e
```

Os dois clientes precisam estar no ar. Os testes autenticam **por API**, nunca pela interface, e usam mecânicas diferentes por app: o v1 recebe a sessão por estado de armazenamento persistente do navegador; o v2 precisa da semeadura antes do primeiro script da página, porque guarda o token em armazenamento de sessão, que o mecanismo nativo do Playwright não persiste.

Cobertura esperada, por módulo: percorrer a mesma jornada nos dois sistemas e comparar o conjunto de dados apresentado — contagens, campos de cada registro e valores dos indicadores.

**Regras invioláveis**: nenhum teste aponta para produção; nenhuma credencial tem valor padrão no código; todo teste que cria dado o remove ao final, mesmo quando falha.

---

## 9. Suítes completas

```powershell
cd ci-api-v2; npm test
cd ci-client-v2; npm test
cd ci-client-v2; npm run build
cd ci-client-v2; npm run typecheck
```

Esperado: tudo verde, e a construção dos três aplicativos concluída.

---

## 10. Critério de encerramento de módulo

Um módulo só é considerado migrado quando, cumulativamente: a reconciliação aprova todas as suas entidades; os cenários deste guia passam; os testes de navegador comparativos passam; e a jornada equivalente no v1 não oferece nada que o v2 não ofereça. A partir daí o módulo correspondente do v1 deixa de ser necessário para a instituição.
