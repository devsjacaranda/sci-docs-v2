# Feature Specification: Ajustes na Pesquisa de Satisfação e no Relatório de Gestão da Ouvidoria

**Feature Branch**: `049-ajustes-relatorio-gestao-ouvidoria`

**Created**: 2026-09-21

**Status**: Draft

**Input**: User description: "feats em Pesquisa de Satisfação e Relatório de gestão da Ouvidoria — ajustes solicitados pela AGEMAN após uso real do relatório de gestão (spec 042), com base em `AJUSTES RELATORIO AGEMAN.docx` (relatório exportado com anotação de bug) e `PLANILHAS OUVIDORIA AGEMAN - 2026 - 08 e Consolidado.xlsx` (planilha manual real, mostrando divergências com o que foi implementado)."

## Clarifications

### Session 2026-09-21

- Q: A Pesquisa de Satisfação hoje implementada (spec 042) usa um campo único "valor" (escala 0–10) por pergunta/mês. A planilha real usa 2 perguntas fixas com contagens Sim/Não (consultados, responderam, Sim, Não), calculando o % de satisfação a partir disso. Qual modelo adotar? → A: Migrar totalmente para o modelo Sim/Não com contagens, substituindo o campo "valor" único — alinhado à planilha real.
- Q: O `.docx` anexado mostra (via imagem anotada em vermelho "PDF") texto sobreposto na tabela "Manifestações por motivo" do PDF exportado. Corrigir esse bug faz parte do escopo? → A: Sim, corrigir o bug de overlap no PDF faz parte desta feature.
- Q: O bloco de Orientações/Encaminhamentos hoje é derivado só de dados já vinculados a manifestações, sem o detalhamento por concessão × canal × ano que a planilha real tem. Isso entra no escopo? → A: Sim, enriquecer esse bloco com o detalhamento por concessão/canal/ano.
- Q: "Participação em Eventos" foi decisão explícita de ficar fora de escopo na spec 042 (FR-012). Reconsiderar agora, já que a planilha trouxe dados reais? → A: Sim, incluir nesta feature agora.
- Q: Existem dois campos de "canal" hoje no sistema — o campo já rotulado "Canal de atendimento" na ficha/PDF da manifestação (valores reais: Presencial, Telefone, E-mail, Aplicativos de mensagem) e o campo usado no bloco "Forma de Atendimento" já existente no relatório (spec 042), hoje só com valores "interna"/"sem_canal". Qual usar como base do detalhamento por canal em Orientações/Encaminhamentos? → A: Usar o campo já rotulado "Canal de atendimento" na ficha/PDF da manifestação — já tem os valores (Presencial/Telefone/E-mail/Mensagens) que batem com a planilha; é uma dimensão diferente do bloco "Forma de Atendimento" existente, que continua como está.
- Q: Para o lançamento manual de "Participação em Eventos", ao relançar o mesmo evento/mês/ano, o sistema deve sobrescrever (upsert) ou somar às participações já lançadas? → A: Sobrescrever (upsert) — mesma regra "última gravação vence" já usada na pesquisa de satisfação.
- Q: A planilha real tem uma coluna "QTD. USUÁRIOS RESPONDERAM" quase sempre vazia. O lançamento de satisfação deve capturar "responderam" como campo próprio, ou tratar como Sim+Não (sem campo separado)? → A: Sem campo próprio — responderam = Sim + Não sempre; só Consultados, Sim e Não são lançados.
- Q: FR-008 dizia que o catálogo de eventos segue "o mesmo padrão já usado para as perguntas de satisfação" (fixo, só seed/admin), mas o Acceptance Scenario 1 da User Story 4 descreve o próprio usuário da Ouvidoria cadastrando um evento pela tela — contradição identificada durante o planejamento técnico. Qual vale? → A: O usuário final da Ouvidoria cadastra/edita eventos livremente pela UI (segue o Acceptance Scenario) — eventos são dinâmicos (mudam a cada ano), diferente das 2 perguntas fixas de satisfação.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Lançar pesquisa de satisfação no modelo Sim/Não com contagens (Priority: P1)

Como usuário com acesso ao módulo Ouvidoria, quero lançar os resultados mensais da pesquisa de satisfação informando quantas pessoas foram consultadas e quantas responderam "Sim" e quantas responderam "Não" para cada pergunta do catálogo — em vez de digitar um valor único numa escala 0–10 — para que o relatório de gestão calcule e exiba o percentual de satisfação da mesma forma que a AGEMAN calcula manualmente hoje.

**Why this priority**: O modelo atual (score 0–10) não corresponde ao processo real do cliente e já foi identificado como divergente ao comparar o relatório exportado com a planilha manual — sem essa correção, o bloco de satisfação do relatório de gestão continua sendo confiável apenas na aparência, não no conteúdo.

**Independent Test**: Pode ser testado lançando as contagens (consultados, Sim, Não) de uma pergunta/mês e confirmando que o percentual de satisfação exibido no relatório de gestão bate com o cálculo manual "Sim ÷ (Sim + Não)" para esse mesmo lançamento.

**Acceptance Scenarios**:

1. **Given** um usuário autorizado no módulo Ouvidoria, **When** ele lança, para uma pergunta/mês/ano, as quantidades de consultados/Sim/Não, **Then** o sistema salva o lançamento e o relatório de gestão passa a exibir o percentual de satisfação calculado (Sim ÷ (Sim + Não)) para aquele mês.
2. **Given** um lançamento de satisfação já existente para um mês/pergunta, **When** o usuário relança o mesmo mês/pergunta com novas contagens, **Then** o sistema atualiza o lançamento existente (sem duplicar), mantendo a regra de "última gravação vence" já adotada na spec 042.
3. **Given** um lançamento em que a soma de "Sim" e "Não" é zero (nenhuma resposta registrada), **When** o relatório de gestão calcula o percentual, **Then** o sistema exibe "sem dados" para aquele mês/pergunta em vez de um erro ou divisão por zero.

---

### User Story 2 - Corrigir sobreposição de texto no PDF exportado (Priority: P1)

Como usuário que exporta o relatório de gestão em PDF, quero que a tabela "Manifestações por motivo" (e qualquer outra tabela do mesmo export com texto de tamanho variável) seja renderizada sem sobreposição de linhas quando o texto do motivo é longo, para que o PDF exportado seja de fato legível e utilizável — hoje o PDF gerado para períodos reais mostra linhas de texto sobrepostas e ilegíveis nessa tabela.

**Why this priority**: É um bug crítico de usabilidade num recurso já entregue (export PDF da spec 042) — o cliente não consegue usar o PDF para os motivos reais registrados no sistema, que frequentemente têm texto longo (ex.: "Recomposição asfáltica (concessionária abriu buraco e não fechou)").

**Independent Test**: Pode ser testado exportando o PDF do relatório de gestão para um período com manifestações cujo motivo seja um texto longo e confirmando visualmente que cada linha da tabela "Manifestações por motivo" é totalmente legível, sem sobreposição com a linha anterior ou seguinte, em qualquer página do PDF.

**Acceptance Scenarios**:

1. **Given** um período com manifestações cujo motivo tem texto longo, **When** o usuário exporta o relatório em PDF, **Then** cada linha da tabela "Manifestações por motivo" é renderizada em sua própria área, sem sobrepor texto de outra linha, mesmo que isso exija mais altura de linha ou quebra de página.
2. **Given** o "acumulado geral" (maior volume e maior variedade de motivos), **When** o usuário exporta o PDF, **Then** o mesmo comportamento de legibilidade se mantém do início ao fim do documento.

---

### User Story 3 - Ver orientações/encaminhamentos detalhados por concessão, canal e ano (Priority: P2)

Como usuário com acesso ao módulo Ouvidoria, quero ver (em tela e nos exports) o bloco de orientações/encaminhamentos detalhado por tipo de concessão (Água/Saneamento, Transporte Coletivo, Iluminação Pública, Coleta de Lixo, Zona Azul), por canal de atendimento (telefone, presencial, e-mail, aplicativo de mensagens) e comparando anos (incluindo percentuais e acumulado histórico), para que esse bloco tenha o mesmo nível de detalhe que a AGEMAN usa hoje na planilha manual.

**Why this priority**: O bloco já existe de forma simplificada (spec 042); este ajuste é um enriquecimento sobre algo que já funciona — tem menos urgência que corrigir um bug ou um modelo de dados incorreto, mas ainda é necessário para o relatório substituir de fato a planilha manual.

**Independent Test**: Pode ser testado comparando o detalhamento exibido (por concessão × canal × ano) com uma contagem manual das manifestações/encaminhamentos do mesmo período agrupados pelos mesmos critérios.

**Acceptance Scenarios**:

1. **Given** manifestações com encaminhamento registradas em diferentes concessões, canais e anos, **When** o usuário abre o bloco de orientações/encaminhamentos do relatório de gestão, **Then** os totais aparecem agrupados corretamente por concessão, por canal e por ano, incluindo os percentuais correspondentes.
2. **Given** o filtro "acumulado geral", **When** o usuário exporta o relatório, **Then** o export contém o histórico multi-ano do bloco de orientações/encaminhamentos com os mesmos números exibidos em tela.

---

### User Story 4 - Registrar participação em eventos institucionais (Priority: P2)

Como usuário com acesso ao módulo Ouvidoria, quero cadastrar eventos institucionais (nome do evento) e lançar manualmente a quantidade de participações por mês/ano em cada evento, para que o relatório de gestão exiba esse indicador — hoje só controlado numa aba separada da planilha manual, sem esse dado o relatório de gestão ainda não é uma substituição completa da planilha.

**Why this priority**: Fecha a última lacuna deliberadamente deixada de fora na spec 042 (FR-012); tem prioridade menor que os itens P1 porque não é um bug nem uma correção de modelo de dados incorreto, apenas um bloco novo solicitado agora pelo cliente.

**Independent Test**: Pode ser testado cadastrando um evento, lançando participações para um ou mais meses, e confirmando que o bloco "Participação em Eventos" do relatório de gestão exibe os totais corretos por mês e por ano para esse evento.

**Acceptance Scenarios**:

1. **Given** um usuário autorizado no módulo Ouvidoria, **When** ele cadastra um novo evento institucional, **Then** o evento passa a estar disponível para lançamento de participações mensais.
2. **Given** um evento cadastrado, **When** o usuário lança a quantidade de participações para um mês/ano, **Then** o relatório de gestão exibe esse valor no bloco "Participação em Eventos", agregado por mês e por ano, incluindo o total geral por evento.
3. **Given** um lançamento de participação já existente para um evento/mês/ano, **When** o usuário relança o mesmo evento/mês/ano com uma nova quantidade, **Then** o sistema sobrescreve o valor existente (upsert, "última gravação vence") em vez de somar ou duplicar.
4. **Given** um mês sem nenhuma participação lançada para um evento, **When** o relatório de gestão exibe o bloco, **Then** aquele mês aparece com valor zero, sem quebrar o total do evento ou do ano.

---

### Edge Cases

- O que acontece com o lançamento antigo de pesquisa de satisfação já existente no modelo "valor" único (ex.: "Atendimento Geral" 2026/08 = 8.5), feito antes desta feature? Ele passa a ser um dado de transição/obsoleto; a decisão de migrá-lo automaticamente para o novo formato ou descartá-lo cabe ao planejamento técnico (`/speckit-plan`), não é um requisito de produto aqui.
- O que acontece se a quantidade de "consultados" informada for menor que a soma de "Sim" + "Não"? O sistema aceita o lançamento como informado (sem validação cruzada entre os campos) — "consultados" é apenas informativo, o percentual de satisfação usa somente Sim/Não.
- O que acontece se um evento institucional for cadastrado mas nenhuma participação for lançada em nenhum mês? O evento aparece no bloco com todos os meses e o total em zero, sem erro.
- O que acontece com o bug de overlap do PDF em outras tabelas do mesmo export que também têm texto de tamanho variável (não só "Manifestações por motivo")? O mesmo princípio de correção MUST se aplicar — nenhuma tabela do PDF pode depender de um comprimento fixo de texto para não sobrepor linhas.
- O que acontece se um tenant não tiver nenhum evento cadastrado? O bloco "Participação em Eventos" aparece vazio, com indicação clara de "sem dados", sem erro — mesmo padrão já usado nos demais blocos do relatório.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: O sistema MUST substituir o modelo de lançamento de pesquisa de satisfação baseado em um campo único "valor" (escala 0–10) por um modelo de contagens Sim/Não por pergunta/mês/ano: quantidade de pessoas consultadas, quantidade de respostas "Sim" e quantidade de respostas "Não". O sistema MUST NOT exigir um campo separado de "quantidade que respondeu" — esse total é sempre derivado como "Sim" + "Não".
- **FR-002**: O sistema MUST calcular o percentual de satisfação de cada pergunta/mês/ano como respostas "Sim" dividido pelo total de respostas ("Sim" + "Não"); quando esse total for zero, o sistema MUST exibir "sem dados" em vez de erro ou divisão por zero.
- **FR-003**: O bloco de pesquisa de satisfação do relatório de gestão MUST exibir, para cada pergunta, o percentual de satisfação calculado por mês/ano (FR-002) como métrica principal, substituindo a exibição do score 0–10 anterior.
- **FR-004**: O sistema MUST continuar impedindo lançamento duplicado de satisfação para a mesma combinação tenant/pergunta/ano/mês, atualizando o lançamento existente em vez de duplicar (mesma regra de "última gravação vence" da spec 042).
- **FR-005**: O catálogo fixo de perguntas de satisfação por tenant (spec 042, FR-005) MUST continuar sendo a fonte das perguntas disponíveis; esta feature altera apenas a forma de resposta de cada pergunta (de "valor" numérico para contagens Sim/Não), não a forma de cadastro do catálogo.
- **FR-006**: O sistema MUST corrigir a exportação em PDF do relatório de gestão para que a tabela "Manifestações por motivo" — e qualquer outra tabela do mesmo export com texto de tamanho variável — nunca sobreponha o texto de uma linha com o de outra, independentemente do comprimento do texto do motivo ou de quebras de página.
- **FR-007**: O sistema MUST enriquecer o bloco de orientações/encaminhamentos do relatório de gestão (tela e ambos os exports) para exibir quantidades agrupadas por tipo de concessão, pelo "Canal de atendimento" (o mesmo dado já capturado e exibido na ficha/PDF de cada manifestação — Presencial, Telefone, E-mail, Aplicativos de mensagem — distinto do bloco "Forma de Atendimento" já existente no relatório) e por ano, incluindo percentuais e o acumulado histórico multi-ano — sem introduzir nova entidade persistida ou tela de lançamento manual para esse bloco (mesma restrição da spec 042, FR-007: dado deriva exclusivamente das manifestações/encaminhamentos já existentes).
- **FR-008**: O sistema MUST permitir que o próprio usuário do módulo Ouvidoria cadastre e edite, pela UI, um catálogo (por tenant) de eventos institucionais identificados por nome — diferente do catálogo de perguntas de satisfação (que é fixo, só via seed/admin), pois eventos surgem e mudam ao longo do tempo e não fazem sentido como uma lista fechada por seed.
- **FR-009**: O sistema MUST permitir lançamento manual (criar/editar) da quantidade de participações por evento, por mês/ano, sem exigir lançamento em todos os meses de uma vez. Relançar o mesmo evento/mês/ano MUST sobrescrever a quantidade existente (upsert, "última gravação vence"), nunca somar ou duplicar.
- **FR-010**: O relatório de gestão MUST incluir um novo bloco "Participação em Eventos" agregando as participações lançadas por mês e por ano, com total geral por evento — revertendo a decisão de escopo da spec 042 (FR-012), que deixava essa funcionalidade fora.
- **FR-011**: As exportações em PDF e Excel do relatório de gestão MUST refletir os três blocos alterados/criados por esta feature (pesquisa de satisfação no novo modelo, orientações/encaminhamentos detalhado, participação em eventos), mantendo a restrição já estabelecida na spec 042 (FR-010) de o Excel não ter fórmulas nem gráficos nativos.
- **FR-012**: O acesso aos lançamentos manuais introduzidos ou alterados por esta feature (satisfação no novo modelo, participação em eventos) MUST seguir a mesma regra de autorização já usada nas demais telas do módulo Ouvidoria — qualquer usuário com o módulo habilitado, sem exigir papel gerencial adicional (mesma regra da spec 042, FR-011).
- **FR-013**: Nenhuma agregação nova introduzida por esta feature (satisfação recalculada, orientações/encaminhamentos detalhado) MUST introduzir tabela de cache/pré-cálculo persistente como solução padrão; apenas os catálogos manuais legítimos (perguntas de satisfação, já existente; eventos institucionais, novo) e seus lançamentos justificam estruturas de dados novas.

### Key Entities *(include if feature involves data)*

- **Lançamento Mensal de Pesquisa de Satisfação (revisado)**: pergunta (do catálogo fixo por tenant), ano, mês, quantidade de pessoas consultadas, quantidade de respostas "Sim", quantidade de respostas "Não". Substitui o campo "valor" único da spec 042; não há campo próprio de "quantidade que respondeu" (é sempre Sim + Não); o percentual de satisfação passa a ser derivado (Sim ÷ (Sim + Não)), não mais lançado diretamente.
- **Catálogo de Eventos Institucionais** *(novo)*: nome do evento, por tenant — cadastrado e editado livremente pelo próprio usuário do módulo Ouvidoria pela UI (não é fixo via seed/admin, ao contrário do catálogo de perguntas de satisfação).
- **Lançamento Mensal de Participação em Evento** *(novo)*: evento (do catálogo), ano, mês, quantidade de participações.
- **Bloco Orientações/Encaminhamentos (detalhado)**: não é uma entidade persistida — é uma composição, em tempo de consulta, das mesmas manifestações e encaminhamentos já existentes, agora agrupada também por tipo de concessão, por canal de atendimento e por ano (além do que já era exibido na spec 042).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: O percentual de satisfação exibido no relatório de gestão, para qualquer pergunta/mês/ano, confere exatamente com o cálculo manual "Sim ÷ (Sim + Não)" a partir das contagens lançadas.
- **SC-002**: O PDF exportado do relatório de gestão não apresenta nenhuma linha com texto sobreposto na tabela "Manifestações por motivo" (ou em qualquer outra tabela do mesmo export), mesmo para os motivos mais longos já registrados no sistema e mesmo no filtro "acumulado geral".
- **SC-003**: O detalhamento de orientações/encaminhamentos por concessão, canal e ano (tela e exports) confere exatamente com uma consulta direta ao banco de dados agrupada pelos mesmos critérios, para qualquer período.
- **SC-004**: Um usuário consegue cadastrar um evento institucional e lançar suas participações mensais, e ver esse dado refletido corretamente (por mês e por ano) no relatório de gestão na mesma sessão, sem etapa adicional de sincronização.
- **SC-005**: O relatório de gestão completo (tela e os dois exports) continua abrindo em até 5 segundos e exportando em até 30 segundos mesmo após os três blocos desta feature serem adicionados/alterados, inclusive no filtro "acumulado geral" (mesmos alvos de performance da spec 042).
- **SC-006**: Nenhum dos três controles hoje mantidos à mão pela AGEMAN na planilha manual (pesquisa de satisfação, orientações/encaminhamentos detalhado, participação em eventos) precisa mais ser consultado ou preenchido fora do sistema após esta feature.

## Assumptions

- Esta feature revisa duas decisões de escopo da spec 042: reverte FR-012 (Participação em Eventos, agora dentro do escopo) e amplia FR-007 (Orientações/Encaminhamentos, agora com detalhamento por concessão/canal/ano). A spec 042 permanece como registro histórico do que foi originalmente decidido/entregue; esta spec 049 documenta o ajuste solicitado após uso real do relatório.
- A migração histórica de pesquisa de satisfação (spec 041, ainda em status Draft, não implementada) MUST ser revisada para usar o novo modelo de contagens Sim/Não em vez do campo "valor" único, já que nenhum dado histórico real foi migrado ainda — não há retrabalho de dados já migrados a considerar.
- O único lançamento manual de pesquisa de satisfação feito até hoje no modelo antigo (ex.: "Atendimento Geral" 2026/08 = 8.5, criado durante a validação da spec 042) é tratado como dado de transição; sua migração ou descarte é uma decisão técnica da fase de planejamento, não um requisito de produto.
- "Participação em Eventos" segue o mesmo padrão de UX, autorização e ausência de tabela de cache já estabelecido para pesquisa de satisfação na spec 042 — mesma tela/mesmo acesso, mas com uma diferença deliberada: o catálogo de eventos (FR-008) é gerenciado livremente pelo usuário final, ao contrário do catálogo de perguntas de satisfação (que continua fixo via seed/admin, sem "form builder" livre).
- O bug de sobreposição de texto no PDF (User Story 2) foi identificado a partir de uma captura de tela anotada pelo cliente mostrando a tabela "Manifestações por motivo"; assume-se que o mesmo princípio de correção (nenhuma linha depende de comprimento de texto fixo) deve ser aplicado a qualquer outra tabela do mesmo export com o mesmo risco, mesmo que não tenha sido explicitamente fotografada pelo cliente.
- Os nomes e a quantidade de tipos de concessão (Água/Saneamento, Transporte Coletivo, Iluminação Pública, Coleta de Lixo, Zona Azul) usados no detalhamento de orientações/encaminhamentos são os mesmos já em uso no bloco "Manifestações por motivo" do relatório de gestão (spec 042) — esta feature não introduz uma taxonomia nova para concessão. Já o canal de atendimento desse detalhamento usa o campo "Canal de atendimento" já capturado por manifestação (o mesmo exibido na ficha/PDF individual) — uma dimensão diferente do bloco "Forma de Atendimento" já existente no relatório, que continua inalterado.
