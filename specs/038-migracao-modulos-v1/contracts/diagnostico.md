# Contrato — API do Diagnóstico

Requer token e tenant. Acesso condicionado a permissão do módulo no setor do usuário — **não** a comparação com o nome ou identificador da instituição.

## Consulta de processos judiciais

Fonte: base externa somente leitura. A API nunca escreve nessa base.

Entrada: texto de busca, campo de busca (número do processo, autor, requerido, juízo, objeto, resultado ou todos), categoria processual, número de processo específico, ordenação por número ou autor, página e limite com máximo declarado.

Saída: página de processos, cada um com número, autor, requerido, juízo, objeto da reclamação, resultado da reclamação, categoria processual derivada e tipo de resultado derivado; mais o total de registros correspondentes.

Regras:

- **Uma linha por número de processo.** Quando a base traz múltiplas ocorrências, prevalece a de resultado mais extenso.
- **Todos** os campos de busca são filtrados no servidor. Nenhum refinamento ocorre sobre a página já retornada.
- Categoria processual é derivada do texto do objeto e do resultado: sentença quando há termo de sentença; petição inicial quando há termo de petição e não de sentença; outros no restante.
- Tipo de resultado é derivado em cascata exclusiva e ordenada: sem resultado, condenação, improcedência, procedência, julgado, em andamento, outros. A ordem é normativa.
- Resultados de consulta são mantidos em memória por tempo limitado para reduzir carga sobre a base externa. A contagem e a listagem de uma mesma consulta são coerentes entre si.

## Painel do Diagnóstico

Saída: total de processos, quantidade com resultado registrado, distribuição por categoria processual, distribuição por tipo de resultado, e concentração por autor, por juízo e por requerido.

Regras: os totais refletem a **base inteira**, não a página exibida. Quando há filtro ativo, o painel informa claramente que os números correspondem ao conjunto filtrado. A data de última atualização não é informada pela base externa e é apresentada como indisponível — não é estimada.

## Marcadores

| Operação | Entrada | Saída |
|---|---|---|
| Listar | — | processos marcados pelo usuário |
| Alternar | número do processo e intenção de marcar ou desmarcar | estado resultante |

Regras: marcação é pessoal — por tenant, usuário e processo, única. Marcar é idempotente. **A marcação existe somente no servidor**: não há persistência no navegador nem modo degradado. Falha de comunicação é erro explícito com possibilidade de nova tentativa.

## Exportação em PDF

Duas exportações: painel completo e seleção de processos. Ambas com timbre da instituição e opção de incluir os gráficos.

Entrada da exportação de seleção: relação de números de processo e opção de incluir gráficos.

Regras: geração no servidor. Sem a opção de gráficos, o documento traz apenas indicadores e a relação de processos. O documento identifica o filtro aplicado, a data de emissão e o responsável pela emissão.

## Documentos institucionais

| Operação | Entrada | Regras |
|---|---|---|
| Obter modelo | tipo de documento | devolve os campos tipados do modelo ativo |
| Reservar número | tipo de documento | número atribuído em transação; nunca reutilizado; exige participação no setor responsável |
| Listar | tipo, situação, ano, texto | quem não participa do setor responsável vê apenas documentos enviados |
| Obter | identificador | leitura de documento enviado registra acesso |
| Salvar campos | identificador e valores | primeira gravação transforma a reserva em rascunho; recusado após envio |
| Enviar | identificador | valida campos obrigatórios do modelo; congela o conteúdo |
| Cancelar | identificador e motivo | motivo obrigatório |
| Gerar PDF | identificador | bloqueado para reservado e abandonado; registra o download |
| Histórico de acessos | identificador | sequência de ações com autor, data e origem |

Rotina automática: reserva não concluída dentro do prazo é marcada como abandonada, **com registro de auditoria**, e o número não é reutilizado — a lacuna permanece rastreável.

Tipos de campo suportados pelos modelos: texto, área de texto, data, moeda, texto rico, assinatura, parágrafos e tabela de informações. A geração do documento respeita a ordem definida no modelo.

## Erros específicos

| Situação | Comportamento |
|---|---|
| Base externa indisponível | erro explícito identificando a indisponibilidade; nunca lista vazia |
| Marcadores indisponíveis | erro explícito; nunca persistência local |
| Salvar campos em documento enviado | rejeitado |
| Enviar documento com campo obrigatório vazio | rejeitado, apontando os campos |
| Cancelar sem motivo | rejeitado |
| PDF de documento reservado ou abandonado | rejeitado |
| Reservar número sem participação no setor responsável | rejeitado por falta de permissão |
