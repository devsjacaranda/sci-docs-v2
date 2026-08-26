# Contrato — API da Ouvidoria (autenticada)

Base: recurso de ouvidoria. Requer token e tenant. Cada operação exige permissão do módulo no setor do usuário.

## Operação de manifestações

| Operação | Entrada | Saída | Regras |
|---|---|---|---|
| Listar | filtros de situação, prioridade, tipo, motivo, canal, período, texto livre; página e limite | página de manifestações com total | filtro e ordenação no servidor; inclui manifestações de origem pública e interna |
| Obter | identificador | manifestação com solicitante, endereço, dados da concessionária, anexos e linha do tempo | anônima não expõe dados do solicitante |
| Criar | dados da manifestação | manifestação com protocolo e número institucional | protocolo e número institucional atribuídos pelo servidor, em transação |
| Atualizar | identificador e campos alterados | manifestação atualizada | permitido enquanto não encerrada; alteração registra evento com autor |
| Excluir | identificador | confirmação | exclusão lógica; registra evento |
| Responder | identificador, texto da resposta | manifestação respondida | registra data, autor e evento |
| Encerrar | identificador, indicação de houve resolução, medidas adotadas, carta de resposta opcional | manifestação encerrada | situação resultante distingue com e sem resolução; carta anexada quando enviada |
| Encaminhar | identificador, setor destino, observações | manifestação encaminhada com vínculo de tramitação | mantém o vínculo entre manifestação e demanda gerada |

## Painel

Sete agregações, todas com ano e mês opcionais. Todas retornam série mensal completa (meses sem dado retornam zero) e são calculadas no banco.

| Agregação | Conteúdo |
|---|---|
| Resolutividade | por mês, encerradas com resolução e encerradas sem resolução, com percentual |
| Atendimentos por mês | por mês, total de manifestações registradas |
| Demandas finalizadas | por mês, respondidas e encerradas nas duas modalidades |
| Demandas pendentes | por mês, em análise e não finalizadas |
| Por tipo | por mês e tipo, incluindo categoria para registros sem tipo |
| Por forma de atendimento | por mês, para o canal informado |
| Por motivo | por mês e motivo, conforme taxonomia da instituição |

Cartões de indicador do painel: total, em análise, respondidas, encerradas com resolução, encerradas sem resolução. **Todos com valor real** — nenhum valor fixo. O rótulo de cada cartão corresponde exatamente ao que ele conta.

## Catálogos administráveis

Tipos de manifestação e formas de atendimento, ambos por tenant: listar, obter, criar, atualizar e inativar. Item referenciado por manifestação **não pode ser excluído**, apenas inativado. Item inativo não aparece em seletores de novo registro, mas continua exibido em registros históricos.

Assuntos seguem o mesmo contrato, com escopo por tenant.

## Atendimentos internos

Listar com filtros de período e texto, obter, criar, atualizar e excluir logicamente. Registro isolado, sem geração de manifestação.

## Documentos

| Operação | Saída |
|---|---|
| Documento da manifestação em formato editável | arquivo com timbre da instituição, contendo protocolo, assunto, descrição, situação, solicitante, endereço, dados da concessionária, resposta e relação de anexos |
| Documento da manifestação em PDF | mesmo conteúdo, gerado no servidor |

Geração ocorre no servidor nos dois formatos. Nenhuma geração no navegador.

## Anexos

Solicitação de envio (devolve destino de upload), confirmação de envio, vínculo de anexo por endereço externo, e obtenção de endereço temporário de download. O endereço de download é temporário, gerado sob demanda, e a chave de armazenamento é validada contra o tenant do requisitante.

## Trilha de auditoria

Listagem de eventos do módulo, com filtros de período, autor, tipo de evento e manifestação. Complementa a linha do tempo já disponível no detalhe de cada manifestação.

## Erros específicos

| Situação | Comportamento |
|---|---|
| Encerrar sem informar se houve resolução | rejeitado com erro de validação |
| Responder manifestação já encerrada | rejeitado |
| Excluir item de catálogo em uso | rejeitado, com orientação de inativar |
| Número institucional duplicado | rejeitado; atribuição é transacional |
