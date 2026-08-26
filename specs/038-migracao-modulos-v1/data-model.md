# Phase 1 — Data Model: Migração de Módulos v1 → v2

**Spec**: [spec.md](./spec.md) · **Plan**: [plan.md](./plan.md) · **Research**: [research.md](./research.md)

Este documento descreve **o que muda no modelo do v2** e **como cada dado do v1 chega lá**. Modelos que já existem e não mudam são citados apenas como destino de mapeamento.

Convenções: nomes de modelo em PascalCase são modelos Prisma do v2; nomes em `snake_case` são tabelas MySQL do v1. Campos marcados **novo** não existem hoje no v2.

---

## 1. Alterações de schema no v2

### 1.1 Ouvidoria — `Manifestacao`

| Campo | Tipo | Origem v1 | Nota |
|---|---|---|---|
| `status` | enum | `manifestations.status` | **valor novo** no enum: encerrada sem resolução, distinta de encerrada com resolução (R6) |
| `numeroPersonalizado` **novo** | `String?` | `id_personalizado` | protocolo institucional AGEMAN, formato ano-tipo-mês-sequência; único por tenant |
| `motivo` **novo** | `String?` | `extra_fields.motivoManifestacao` | taxonomia AGEMAN; alimenta a agregação por motivo |
| `programa` **novo** | `String?` | `extra_fields.manifestacao` | programa/serviço da AGEMAN |
| `foiAtendido` **novo** | `Boolean?` | `foiAtendido` | descritivo; **não** é fonte do KPI de resolutividade |
| `medidasResolucao` **novo** | `String?` | `medidasResolucao` | texto livre |
| `desejaResposta` **novo** | `Boolean?` | `wantsResponse` | |
| `arquivadoEm` **novo** | `DateTime?` | `archivedAt` | eixo temporal da resolutividade |
| `arquivadoPorId` **novo** | `String?` | `archivedById` | FK nullable para `User` |
| `respondidoEm` **novo** | `DateTime?` | `respondedAt` | eixo temporal de finalizadas |
| `respondidoPorId` **novo** | `String?` | `respondedById` | FK nullable para `User` |
| `addressId` | `String?` | `manifestation_addresses` | já existe; **passa a ser populado** pela migração |
| `requesterDocument`, `holderName`, `registrationNumber` | | `manifestation_claimants` | já existem |

**Regras de validação**: `numeroPersonalizado` único por tenant quando presente; `arquivadoEm` obrigatório quando o status é de encerramento; `medidasResolucao` exigido quando `foiAtendido` é verdadeiro em registros novos (registros migrados aceitam ausência).

**Transições de estado** (as duas últimas são novas):

```
rascunho → em análise → (encaminhada) → respondida → encerrada com resolução
                                     └→ encerrada sem resolução
```

Encerrar exige informar se houve resolução. Não há retorno de estado encerrado.

### 1.2 Ouvidoria — dados sem destino atual

| Origem v1 | Destino no v2 | Decisão |
|---|---|---|
| `manifestation_concessionaire_infos` (ordem de serviço, prazos, contato) | **`ManifestacaoConcessionaria` novo** | modelo dedicado 1:1 com a manifestação; sem ele o dado se perde (FR-018) |
| `manifestation_document_links` | `ManifestacaoAnexo` com `kind = link` | já suportado |
| `manifestation_id_sequences` (por prefixo) | `ManifestacaoSequence` (por ano) + sequência do número personalizado | dois contadores distintos, ver 1.3 |
| `public_manifestations` (tabela separada) | `Manifestacao` com marca de origem pública | **`origem` novo** (`String`): interna ou portal público |
| `extra_fields` (restante não mapeado) | `dadosAdicionais` **novo** (`Json?`) | preserva o que não tem coluna; não é usado em regra de negócio |

### 1.3 Ouvidoria — `ManifestacaoNumeroPersonalizadoSequence` (novo)

Contador do protocolo institucional AGEMAN, separado do contador do protocolo do v2.

| Campo | Tipo | Nota |
|---|---|---|
| `tenantId` | `String` | |
| `prefixo` | `String` | componente de tipo/mês conforme formato AGEMAN |
| `ano` | `Int` | |
| `ultimoNumero` | `Int` | semeado pelo máximo do v1 (R12) |

Chave primária composta por tenant, prefixo e ano. Incremento **dentro de transação**.

### 1.4 Ouvidoria — catálogos por tenant

O v1 administra tipos, categorias e canais de atendimento **por tenant** (com CRUD); o v2 usa enum fixo e catálogo global. Para não perder a capacidade de administração (FR-021):

| Modelo novo | Campos | Origem v1 |
|---|---|---|
| `OuvidoriaTipoManifestacao` | `tenantId`, `codigo`, `nome`, `ativo`, timestamps, soft delete | `manifestation_types` |
| `OuvidoriaFormaAtendimento` | `tenantId`, `codigo`, `nome`, `ativo`, timestamps, soft delete | `service_channels` |

`Manifestacao.type` (enum) permanece para classificação canônica; `tipoId` **novo** (`String?`) referencia o catálogo do tenant quando existir. Categoria segue em `OuvidoriaAssunto`, ganhando escopo por tenant.

**Regra**: um item de catálogo referenciado por manifestação não pode ser excluído — apenas inativado.

### 1.5 Ouvidoria — `OuvidoriaAtendimentoInterno` (novo)

Registro de atendimento presencial/telefônico que não gera manifestação.

| Campo | Tipo | Origem v1 (`internal_services`) |
|---|---|---|
| `tenantId`, `id` | | |
| `assunto` | `String` | `subject` |
| `descricao` | `String?` | |
| `nomeCidadao`, `contato` | `String?` | |
| `dataAtendimento` | `DateTime` | |
| `registradoPorId` | `String?` | FK nullable para `User` |
| soft delete + timestamps | | |

### 1.6 Gabinete — `CabinetDemanda` e fluxo

| Campo | Situação | Nota |
|---|---|---|
| `currentSector` | existe, **não é atualizado** no encaminhamento | passa a ser atualizado em toda transição (R9) |
| `sectorId` | existe | idem |
| `recebidoEm` **novo** | `DateTime?` | marca o recebimento pelo setor destino |
| `recebidoPorId` **novo** | `String?` | FK nullable para `User` |
| `forwardings` | JSON | mantido como registro compacto; a **linha do tempo canônica** é `CabinetDemandaEvento` |

**Novos tipos de evento** em `CabinetDemandaEvento`: recebimento, devolução e resposta (o v1 os distingue no JSON por `tipo`; no v2 são tipos de evento tipados).

**Transições** (19 status, mapeamento 1:1 com o v1):

```
rascunho → aguardando recebimento → recebido → em análise → … → finalizado → arquivado
                                                    └→ devolvida (Ouvidoria | Gabinete)
```

Regras: devolver só é permitido a partir do setor jurídico, com destino Ouvidoria ou Gabinete; receber só quando o status é *aguardando recebimento*; encaminhar exige destino válido para o setor de origem.

### 1.7 Gabinete — `CabinetDocumentoTramitado`

| Campo | Tipo | Origem v1 | Nota |
|---|---|---|---|
| `order` **novo** | `Int?` | `ord` (tabelas `deret`, `deres`) | **não** confundir com `quantity` (`qtde`) |
| `sigedNumber` | existe | `numero_siged` \| `n_siged` \| `siged` | três grafias convergem |
| `protocolType` | existe | `tipo_protocolo` \| `tipo_do_protocolo` | duas grafias convergem |
| `deadline` | existe | `prazo` (só DEGPLAN) | **não** misturar com `notes` |
| `dispatchDate` | existe | `data_despacho` (só DEGPLAN) | |
| `sectorId` | existe | nome da tabela de origem | obrigatório; mapeado por sigla |

Linhas do setor jurídico no v1 têm **apenas vínculos** — migram como registro mínimo (setor + vínculos), sem inventar conteúdo.

### 1.8 Gabinete — `Setor`

| Campo | Tipo | Origem v1 | Nota |
|---|---|---|---|
| `nomeCompleto` **novo** | `String?` | `nomeCompleto` | exigido por FR-038 |
| `descricao` **novo** | `String?` | `descricao` | |
| `active` **novo** | `Boolean` | `active` | inativar ≠ excluir; `deletedAt` continua sendo exclusão |
| `chefeUserId` | existe | `user_sectors.is_manager` | v1 admite vários gestores; a migração elege um e reporta os demais |

**Regra**: setor inativo não aparece como destino de encaminhamento nem em seletores de cadastro, mas permanece visível na administração e nos registros históricos.

### 1.9 Diagnóstico — modelos novos

`DiagnosticoProcessoMarcador` — marcação pessoal de processo:

| Campo | Tipo | Nota |
|---|---|---|
| `tenantId`, `userId` | `String` | |
| `numeroProcesso` | `String` | |
| `createdAt` | `DateTime` | |

Único por tenant + usuário + número de processo. Sem persistência no navegador (R15).

`ProcessoJudicial` — **não é modelo Prisma**. É projeção de leitura da base externa (R2), com os campos: número do processo, autor, requerido, juízo, objeto da reclamação e resultado da reclamação. Derivados calculados na consulta: **categoria** (sentença, petição inicial, outros) e **tipo de resultado** (sem resultado, condenação, improcedência, procedência, julgado, em andamento, outros), pelas regras de R14. Uma linha por número de processo, deduplicada pela ocorrência de resultado mais longo.

### 1.10 Documentos institucionais — 4 modelos novos

`DocumentoInstitucionalModelo`:

| Campo | Tipo | Nota |
|---|---|---|
| `tenantId`, `tipo`, `nome`, `descricao` | | tipo: processo coletivo \| processo individual |
| `campos` | `Json` | lista de campos tipados, com chave, rótulo, tipo, obrigatoriedade e ordem |
| `ativo` | `Boolean` | |

Único por tenant + tipo. Tipos de campo suportados: texto, área de texto, data, moeda, texto rico, assinatura, parágrafos e tabela de informações.

`DocumentoInstitucional`:

| Campo | Tipo | Nota |
|---|---|---|
| `tenantId`, `modeloId`, `tipo` | | |
| `numero` | `String` | atribuído na reserva; nunca reutilizado |
| `status` | enum | reservado \| rascunho \| enviado \| cancelado \| abandonado |
| `payload` | `Json?` | nulo enquanto reservado; congelado ao enviar |
| `motivoCancelamento` | `String?` | **obrigatório** quando cancelado |
| `reservadoEm`, `rascunhoEm`, `enviadoEm`, `canceladoEm`, `abandonadoEm` | `DateTime?` | |
| `criadoPorId`, `atualizadoPorId` | `String?` | FK nullable para `User` |

`DocumentoInstitucionalSequence`: chave composta por tenant, tipo e ano, com `proximoValor`. Incremento **transacional** (R17).

`DocumentoInstitucionalAuditoria`: `documentoId`, `acao` (criação, salvamento, envio, cancelamento, abandono, acesso, download), `dadosAnteriores`, `dadosNovos`, `motivo`, `atorId`, `atorRole`, `ip`, `userAgent`, `createdAt`.

**Transições**:

```
reservado → rascunho → enviado
   │  └──────────────→ cancelado (com motivo)
   └→ abandonado (sem conclusão no prazo)
```

Regras: número atribuído na reserva; sem reserva não há documento; PDF bloqueado em reservado e abandonado; payload imutável após envio; abandono **gera evento de auditoria** (correção sobre o v1); leitura de documento enviado gera registro de acesso.

### 1.11 Anexos

Todos os modelos de anexo passam a aceitar `uploadedByUserId` **nullable** — o v1 tem autor nulo em parte das linhas, e a regra do repositório já prevê FK nullable para actors sem linha em `User`. Anexos migrados entram com confirmação de upload verdadeira e `storageKey` copiada verbatim do v1 (R3).

---

## 2. Mapeamento de enums

### 2.1 Status da manifestação

| v1 | v2 |
|---|---|
| `PENDENTE` | em análise (rascunho apenas quando não confirmada) |
| `EM_ANALISE` | em análise |
| `RESPONDIDO` | respondida |
| `ARQUIVADO_OK` | encerrada com resolução |
| `ARQUIVADO` | encerrada sem resolução **(novo)** |

Status público do v1 (pendente, em análise, respondida, arquivada) converge para os mesmos valores.

### 2.2 Prioridade

`BAIXA` → baixa · `MEDIA` → média · `ALTA` → alta · `URGENTE` → urgente.

### 2.3 Setor da demanda — 1:1, sem órfãos

Gabinete, Ouvidoria, jurídico, suporte técnico, diretoria de economia, diretoria técnica, concessionária.

### 2.4 Status do fluxo da demanda — 1:1, 19 valores, sem órfãos

Rascunho, aguardando recebimento, recebido, em análise, aguardando concessionária, concessionária respondeu no prazo, concessionária respondeu fora do prazo, concessionária não respondeu, aguardando laudo, laudo concluído, aguardando dosimetria, dosimetria concluída, aguardando auto de infração, auto de infração emitido, em trâmite, finalizado, arquivado, devolvida à Ouvidoria, devolvida ao Gabinete.

Observação: o v1 tem inconsistência interna — a lista de validação omite os dois status de devolução, embora o schema os defina e o código os use. O v2 aceita os 19.

### 2.5 Forma de entrada do protocolo

`PRESENCIAL` → presencial · `EMAIL` → e-mail · `SIGED` → SIGED.

---

## 3. Rastreabilidade da migração

Cada registro migrado precisa ser localizável a partir do identificador do v1 (FR-002, SC-003). O mecanismo atual da 036 é um id-map em arquivo JSON no diretório de cache — suficiente para a carga, **insuficiente** para auditoria posterior, porque o arquivo não acompanha o banco.

**Decisão**: manter o id-map em arquivo como índice de trabalho durante a carga **e** persistir a origem no banco, em `MigracaoRegistroOrigem`:

| Campo | Tipo | Nota |
|---|---|---|
| `tenantId` | `String` | |
| `entidade` | `String` | nome do modelo v2 |
| `idV2` | `String` | |
| `tabelaV1` | `String` | |
| `idV1` | `String` | |
| `migradoEm` | `DateTime` | |

Único por tenant + entidade + id do v1, e único por tenant + entidade + id do v2. Isso torna a idempotência verificável **contra o banco** e não contra um arquivo local, e sustenta o relatório de correspondência (FR-006).

---

## 4. Contagens de referência

O relatório de reconciliação precisa de três números por entidade — origem, exclusões aprovadas e destino — e a igualdade `origem − exclusões = destino` é o critério de aprovação (FR-006, SC-006).

Entidades cobertas: tenant, usuários, administradores, setores, vínculos usuário-setor, manifestações, anexos de manifestação, endereços, eventos, atendimentos internos, protocolos do Gabinete, demandas, documentos tramitados (soma das 13 tabelas), controle numérico (soma das 6 tabelas), notificações, autos de infração, marcadores e documentos institucionais.

Duas armadilhas conhecidas na contagem, herdadas da execução de staging: registros com exclusão lógica no v1 e colisões de número em protocolos produziram falsos negativos no comparador. A correção é declarar explicitamente o tratamento de exclusão lógica em cada contagem e resolver colisão por chave natural composta, não por número isolado.
