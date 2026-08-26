# Contrato — API do Gabinete

Requer token e tenant. Permissão por módulo e setor.

## Fluxo de demandas

| Operação | Entrada | Efeito |
|---|---|---|
| Listar | filtros de situação, setor atual, origem, período, texto; página e limite | página de demandas com total |
| Obter | identificador | demanda com histórico cronológico completo e anexos |
| Criar | dados da demanda, origem | demanda com número de protocolo atribuído pelo servidor |
| Encaminhar | identificador, setor destino, observações, anexos opcionais | situação passa a aguardando recebimento; **setor atual passa a ser o destino**; evento de encaminhamento; protocolo de tramitação vinculado |
| Reencaminhar | igual ao encaminhar | mesma transição, evento distinto que preserva a leitura do histórico |
| Receber | identificador | situação passa a recebido; evento de recebimento; notifica quem encaminhou |
| Devolver | identificador, destino, justificativa | situação passa a devolvida ao destino; evento de devolução |
| Anexar resposta | identificador, texto, anexos | evento de resposta; **sem** alterar situação ou setor |
| Histórico em PDF | identificador | documento com timbre, contendo a sequência completa de eventos com data, autor, setores e observações |

Regras de transição: receber só é permitido quando a situação é aguardando recebimento; devolver só a partir do setor jurídico, com destino Ouvidoria ou Gabinete; encaminhar exige destino válido para o setor de origem. Toda transição registra autor, data e setores de origem e destino. O histórico é imutável — eventos não são editados nem removidos.

## Protocolos

Listar com filtros de período, forma de entrada, remetente e texto, com paginação no servidor. Obter, criar, atualizar e excluir logicamente. Número interno e número SIGED são informados pelo usuário. Anexos por solicitação de envio e confirmação. Vínculo opcional com demanda.

## Documentos tramitados

Cadastro **único** com filtro por setor cadastrado — não há uma rota por setor. Campos: setor (obrigatório), quantidade, ordem, data de protocolo, número e tipo de protocolo, número SIGED, data de despacho, documento, requerente, assunto, prazo, observações, identificador de agrupamento e vínculos com demanda e protocolo.

Regras: setor deve existir e estar ativo; a ordem é distinta da quantidade; agrupamento relaciona registros que representam o mesmo trâmite em setores diferentes.

## Controle numérico

Cadastro único com tipo de documento obrigatório (ofício, ofício circular, portaria, memorando, memorando circular, resolução). Campos aplicáveis variam por tipo: ofício usa órgão, endereçado, histórico, formalizado por e minutado por; ofício circular usa assunto e solicitante; memorandos usam destino como endereçado; portaria e resolução usam histórico e solicitante.

Número é informado pelo usuário, não gerado. Campos não aplicáveis ao tipo são recusados na validação em vez de ignorados silenciosamente.

## Notificações e autos de infração

Dois cadastros, com filtros e paginação no servidor. Notificação: termo, destinatário, emissor, relatório técnico, fato gerador, processo institucional, data de protocolo na concessionária, prazo, vencimento, resposta e situação. Auto: documento, destinatário, setor emissor, parecer, assunto, **valor monetário com duas casas decimais**, processo institucional, número de protocolo, prazo, vencimento e resposta.

Agrupamento comum às duas entidades relaciona a notificação ao auto do mesmo caso. Valor monetário é validado como decimal de escala fixa — nunca número de ponto flutuante.

## Diretorias

Listar, obter, criar, atualizar e inativar. Campos: sigla, nome, nome completo, descrição, situação de atividade e chefe.

Regras: sigla única por tenant; inativar não exclui — o setor permanece visível na administração e nos registros históricos, mas não aparece como destino de encaminhamento nem em seletores de novo cadastro; setor com registros vinculados não pode ser excluído.

## Erros específicos

| Situação | Comportamento |
|---|---|
| Receber demanda que não aguarda recebimento | rejeitado |
| Devolver a partir de setor não autorizado | rejeitado |
| Encaminhar para destino inválido para o setor de origem | rejeitado |
| Campo não aplicável ao tipo de documento | erro de validação |
| Valor monetário com mais de duas casas | erro de validação |
| Excluir setor com registros vinculados | rejeitado, com orientação de inativar |
