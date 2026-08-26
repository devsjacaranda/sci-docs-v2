# Contrato — Comandos de migração e relatório de reconciliação

Interface de linha de comando executada por operador, não exposta como API.

## Comandos

| Comando | Propósito |
|---|---|
| Migração completa | executa todas as fases na ordem de dependência |
| Migração por fase | executa uma fase isolada, respeitando as anteriores |
| Ensaio | percorre todo o mapeamento e relata contagens **sem gravar** no destino |
| Contagem de origem | relata as contagens do sistema antigo, descontando as exclusões aprovadas |
| Comparação | compara origem e destino por entidade e por campo, e falha quando há divergência |

Fases, na ordem: instituição, acessos e setores, ouvidoria, gabinete, diagnóstico, anexos.

## Garantias exigidas

**Idempotência**: executar o mesmo comando duas vezes produz o mesmo estado final, sem duplicar registro algum. Cada registro é identificado por chave natural determinística, e a origem é persistida no banco de destino — não apenas em arquivo local.

**Interrupção**: falha no meio da execução não deixa registro pela metade. Ao reexecutar, o que já foi migrado é reconhecido e não se repete.

**Ensaio fiel**: o ensaio percorre exatamente o mesmo mapeamento da execução real. Contagens divergentes entre ensaio e execução indicam defeito.

**Ausência de efeito na origem**: nenhum comando escreve no sistema antigo. A conexão de origem é somente leitura.

## Relatório de reconciliação

Formato tabular legível por pessoa e processável por script. Uma linha por entidade, com:

| Coluna | Conteúdo |
|---|---|
| Entidade | nome do conjunto de dados |
| Origem | contagem no sistema antigo |
| Exclusões | registros deliberadamente não migrados, conforme lista aprovada |
| Esperado | origem menos exclusões |
| Destino | contagem no sistema novo |
| Situação | conforme ou divergente |

Critério de aprovação: esperado igual a destino, em **todas** as entidades. Qualquer divergência resulta em código de saída de falha.

Entidades cobertas: instituição, usuários, administradores, setores, vínculos usuário-setor, manifestações, anexos de manifestação, endereços, dados de concessionária, eventos de manifestação, atendimentos internos, catálogos, protocolos do gabinete, demandas, eventos de demanda, documentos tramitados, controle numérico, notificações, autos de infração, marcadores e documentos institucionais.

## Comparação campo a campo

Além das contagens, a comparação verifica o conteúdo. Diferenças esperadas de representação entre os dois sistemas são tratadas como equivalentes segundo um **mapa declarado e revisável**:

| Classe de diferença | Tratamento |
|---|---|
| Valores de enumeração traduzidos | tabela de correspondência explícita |
| Data e hora entre bancos distintos | comparação no mesmo fuso; divergência de dia é falha |
| Valores monetários | comparação em escala decimal fixa; nunca em ponto flutuante |
| Texto com espaços à margem, ou vazio versus ausente | normalização declarada, aplicada só onde a origem usava as duas formas sem distinção |
| Identificadores | resolvidos pelo registro de origem persistido |

Qualquer diferença fora do mapa é reportada com entidade, registro e campo. O relatório de divergências permite localizar o registro no sistema antigo e no novo.

## Relatório de anexos

Além das contagens, relatório específico com: total de referências de arquivo na origem, quantas foram vinculadas a um registro do destino, e a relação das **não localizadas**, com a informação disponível na origem. Nenhuma referência desaparece sem constar deste relatório.

## Verificação do próprio verificador

O comparador é exercitado por teste que introduz divergência deliberada e exige reprovação. Um comparador que aprova tudo é indistinguível de um comparador quebrado.
