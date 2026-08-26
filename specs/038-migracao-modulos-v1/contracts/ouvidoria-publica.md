# Contrato — API pública da Ouvidoria

Consumida pelo portal do cidadão. Dispensa token; exige o cabeçalho de tenant. **Nenhum destes endpoints existe hoje no v2** — a única rota pública atual da Ouvidoria é a consulta por protocolo e chave.

## Abertura de manifestação

Entrada: identificação (identificada ou anônima), dados do solicitante quando identificada, programa e motivo conforme taxonomia da instituição, assunto, descrição, endereço com zona da cidade, dados específicos por programa, referências de anexos previamente enviados, e prova de que o envio não é automatizado.

Saída: número de protocolo e chave de consulta, apresentados uma única vez.

Regras: campos obrigatórios variam por programa — o de água exige matrícula em formato próprio, o de iluminação exige número de protocolo e identificação de poste. Manifestação anônima não coleta dados pessoais. A prova contra envio automatizado é obrigatória e verificada no servidor. Há limite de envios por origem em janela de tempo.

## Envio de anexo

Entrada: arquivo, dentro dos tipos e do tamanho permitidos.

Saída: referência temporária a ser informada na abertura da manifestação.

Regras: a referência expira se não for utilizada. Tipo de arquivo e tamanho são validados no servidor, não apenas no navegador. Referência não vinculada a nenhuma manifestação é descartada por rotina de limpeza.

## Consulta de manifestação

Entrada: número de protocolo e chave de consulta.

Saída: situação, data de registro, assunto, resposta quando houver, e histórico resumido de andamento.

Regras: sem a chave correta não há retorno de dado algum — inclusive não se revela se o protocolo existe. Dados pessoais do solicitante não são retornados. Tentativas repetidas com chave inválida são limitadas por origem.

## Catálogos públicos

Programas, motivos por programa e formas de atendimento, somente leitura. Apenas itens ativos.

## Consulta de endereço por código postal

Entrada: código postal. Saída: endereço quando localizado. Serve para preenchimento assistido; o cidadão pode corrigir qualquer campo.

## Erros específicos

| Situação | Comportamento |
|---|---|
| Prova contra automação ausente ou inválida | envio rejeitado |
| Limite de envios por origem excedido | rejeitado, com indicação de quando tentar novamente |
| Referência de anexo expirada | rejeitado, com orientação de reenviar o arquivo |
| Chave de consulta incorreta | resposta idêntica à de protocolo inexistente |
| Campo obrigatório do programa ausente | erro de validação apontando o campo |
