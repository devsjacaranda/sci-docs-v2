# Feature Specification: Timbrado oficial AGEMAN 2026

**Feature Branch**: `046-timbrado-ageman-2026`

**Created**: 2026-09-15

**Status**: Draft

**Input**: User description: "vamos trocar o timbrado geral do ageman no civ2 em todos os módulos" — fonte visual: `new-timbrado/Folha padrão 2026 - Vertical.docx`

## Clarifications

### Session 2026-09-15

- Q: Quais saídas passam a usar a folha padrão 2026? → **C**: todos os PDFs e Words institucionais (incluindo os que hoje saem sem timbrado: histórico do Gabinete, dossiê da Tramitação, notificação ANPD) **e** os relatórios de Insights/Maturidade que hoje saem em HTML — estes passam a nascer como ofício timbrado. Planilhas (SIGED e similares) ficam de fora.
- Q: Como deve ser a composição visual? → **A**: folha oficial à risca — faixa institucional + marca d’água do brasão em todas as páginas; **sem** selo de módulo e **sem** rodapé extra (sem data de geração e sem “página X de Y”).
- Q: Para quais instituições vale a arte 2026? → **A**: somente o tenant AGEMAN; os demais tenants mantêm o fallback atual. Arquivos já baixados não são reescritos.
- Q: Se a folha padrão 2026 não puder ser aplicada no momento da emissão (arte indisponível), o que deve acontecer? → **C**: emitir só o miolo, sem cabeçalho nem marca d’água — não recusar e não voltar ao timbrado antigo.
- Q: Os relatórios de Insights/Maturidade hoje saem em HTML e devem virar ofício timbrado. O HTML some ou continua? → **B**: o ofício timbrado é o padrão; a exportação HTML continua disponível como opção extra.
- Q: O ofício padrão de Insights/Maturidade vale para quais módulos? → **C**: todos os Insights/Maturidade que **já tiverem** qualquer botão de exportar; módulos sem exportação ficam de fora (não se cria exportação nova). Hoje isso cobre Compras Insights e Compras Maturidade.
- Q: O ofício padrão das famílias que hoje são HTML sai em qual formato? → **B**: PDF e Word, ambos com a folha 2026; a exportação HTML continua como opção extra.
- Q: Criamos Word nas famílias que hoje saem só em PDF? → **B**: sim — todas as famílias cobertas passam a ter PDF e Word com a mesma folha 2026 (não só Insights/Maturidade e a manifestação).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Operador emite documento institucional com a folha padrão 2026 (Priority: P1)

Um operador autenticado da AGEMAN exporta um documento oficial do sistema (por exemplo, o dossiê de uma manifestação). O arquivo baixado usa a **folha padrão 2026** — a mesma identidade visual da arte oficial: faixa superior com a marca AGEMAN à esquerda e a identidade da Prefeitura de Manaus (brasão, slogan e dados de contato) à direita, sobre papel A4 vertical, com o brasão municipal em marca d’água ao centro da folha. Não há selo de módulo nem rodapé de paginação.

**Why this priority**: É o pedido central — o documento que sai do sistema precisa parecer o papel timbrado oficial vigente, não o cabeçalho genérico ou o timbrado antigo (logo isolada + título textual + selo de módulo).

**Independent Test**: Autenticar no tenant AGEMAN, exportar um documento de um módulo que já emite papel timbrado e comparar visualmente com a folha padrão 2026 (faixa, margens e marca d’água; ausência de selo e de rodapé extra).

**Acceptance Scenarios**:

1. **Given** um operador autenticado no tenant AGEMAN, **When** exporta um documento oficial previsto no escopo desta feature, **Then** o arquivo usa a folha padrão 2026 (faixa institucional + marca d’água do brasão) e **não** o timbrado anterior (logo isolada, faixa azul, título textual “AGEMAN — Ouvidoria”, selo de módulo ou linha decorativa solta).
2. **Given** o documento tem mais de uma página, **When** o operador abre qualquer página, **Then** a faixa oficial e a marca d’água permanecem — o timbrado não some após a primeira folha.
3. **Given** o conteúdo do documento (textos, tabelas, anexos embutidos), **When** o arquivo é gerado com a arte disponível, **Then** o conteúdo útil começa abaixo da faixa oficial e não encobre a arte do cabeçalho.
4. **Given** a arte da folha 2026 está indisponível, **When** o operador tenta emitir no tenant AGEMAN, **Then** recebe o miolo sem faixa e sem marca d’água, um aviso de que a folha oficial não pôde ser aplicada, e **não** vê o timbrado antigo.

---

### User Story 2 - Todos os módulos emitem com o mesmo timbrado geral (Priority: P1)

Quem emite documento em **qualquer módulo** da AGEMAN no CI v2 obtém a **mesma** folha padrão — não uma arte por módulo. Isso inclui o que já nascia timbrado, o que já nascia sem timbrado (Gabinete, Tramitação, ANPD) e os relatórios de Insights/Maturidade: o caminho padrão passa a ser ofício na folha 2026; a exportação HTML permanece como opção extra.

**Why this priority**: O pedido foi explícito (“timbrado geral” / “em todos os módulos”). Hoje cada família de documento desenha um cabeçalho diferente — ou nenhum.

**Independent Test**: Exportar um documento de cada família do inventário coberto e confirmar que o cabeçalho e a marca d’água são os mesmos.

**Acceptance Scenarios**:

1. **Given** o tenant AGEMAN, **When** o operador exporta documentos de módulos distintos cobertos pelo escopo, **Then** todos compartilham a mesma folha padrão 2026.
2. **Given** um módulo que hoje emite PDF **sem** timbrado (histórico do Gabinete, dossiê da Tramitação, notificação ANPD), **When** o operador exporta, **Then** o arquivo passa a nascer na folha padrão 2026.
3. **Given** um relatório de Insights ou Maturidade que já exporta, no tenant AGEMAN, **When** o operador usa a exportação de ofício, **Then** pode baixar PDF e Word, ambos na folha padrão 2026.
4. **Given** o mesmo relatório, **When** o operador escolhe a opção extra HTML, **Then** a página HTML continua disponível (sem substituir o ofício).
5. **Given** uma família coberta que hoje só tem PDF (Gabinete, Tramitação, ANPD, Diagnóstico, documento institucional, relatório de gestão), **When** o operador exporta no tenant AGEMAN, **Then** passa a poder baixar PDF e Word, ambos na folha 2026.
6. **Given** uma exportação em planilha (SIGED ou similar), **When** o operador exporta, **Then** o formato atual permanece — esta feature não converte planilha em ofício.

---

### User Story 3 - Destinatário reconhece o ofício oficial vigente (Priority: P2)

Um gestor, setor destinatário ou cidadão que recebe o arquivo consegue identificar imediatamente a AGEMAN e a Prefeitura de Manaus pelos elementos oficiais (marca, brasão, slogan “Gente que trabalha” e dados de contato da arte), sem selo interno de módulo e sem rodapé de sistema.

**Why this priority**: O valor institucional do timbrado é o reconhecimento externo; a arte 2026 já identifica a instituição.

**Independent Test**: Mostrar o arquivo gerado a alguém que conhece a folha padrão 2026 e obter confirmação de que a identidade visual é a oficial (faixa + marca d’água, sem acréscimos).

**Acceptance Scenarios**:

1. **Given** um documento emitido após esta mudança, **When** comparado lado a lado com `Folha padrão 2026 - Vertical.docx`, **Then** a faixa superior e a marca d’água correspondem à arte oficial (mesmos elementos, mesma ordem, mesma orientação vertical), sem selo de módulo e sem rodapé extra.
2. **Given** um documento emitido **antes** desta mudança e já arquivado pelo usuário, **When** ele reabre esse arquivo antigo, **Then** o arquivo antigo não é reescrito — só novas emissões usam a folha 2026.
3. **Given** um operador autenticado em tenant que **não** é a AGEMAN, **When** exporta um documento, **Then** continua vendo o fallback atual — a arte 2026 não aparece.

---

### Edge Cases

- Documento com muitas páginas, tabelas largas ou gráficos: o conteúdo não invade a faixa do cabeçalho; a marca d’água permanece atrás do texto, sem impedir a leitura.
- Documento com anexos embutidos (imagens ou outras folhas coladas no mesmo arquivo): as folhas geradas pelo sistema levam o timbrado; anexos externos já prontos **não** são “re-timbrados”.
- Exportação em Word e em PDF do mesmo registro: as duas saídas usam a mesma identidade visual oficial (não uma arte no PDF e texto solto no Word).
- Tenant que **não** é a AGEMAN: mantém o cabeçalho/fallback atual; a folha 2026 não é aplicada.
- Relatórios de Insights/Maturidade no tenant AGEMAN: só entram os que **já têm** botão de exportar (hoje: Compras Insights e Compras Maturidade). Nesses, o ofício sai em PDF e Word na folha 2026 e a HTML permanece extra. Módulos sem exportação (Ouvidoria, Gabinete, TI, SIGED Insights/Maturidade, no estado atual) ficam de fora. Em outros tenants, o comportamento atual permanece.
- Orientação paisagem ou formatos que não sejam A4 vertical: fora desta entrega — a fonte oficial fornecida é só a folha vertical.
- Sem rodapé de sistema: não há data de geração nem “página X de Y” impressos na folha — a arte oficial não define rodapé.
- Planilhas e anexos enviados pelo usuário permanecem fora do papel timbrado.
- Arte oficial indisponível no momento da emissão (tenant AGEMAN): o sistema **não** recusa e **não** volta ao timbrado antigo; entrega só o miolo, sem faixa e sem marca d’água, e avisa o operador de que a folha oficial não pôde ser aplicada.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: No tenant AGEMAN, o sistema DEVE aplicar a folha padrão 2026 a todas as emissões institucionais em PDF e Word, incluindo: dossiê de manifestação; relatório de gestão da Ouvidoria; relatórios do painel e da seleção do Diagnóstico; documento institucional; histórico da demanda no Gabinete; dossiê do protocolo na Tramitação; notificação de incidente ANPD; e a exportação **padrão** dos relatórios de Insights e Maturidade (ofício timbrado; HTML permanece como opção extra).
- **FR-002**: A folha padrão DEVE reproduzir a arte oficial do arquivo `Folha padrão 2026 - Vertical.docx`: faixa superior com marca AGEMAN à esquerda e bloco Prefeitura de Manaus (brasão, nome, slogan e contatos) à direita, em A4 vertical.
- **FR-003**: A folha padrão DEVE incluir a marca d’água central do brasão de Manaus em **todas** as páginas, como no Word oficial, e NÃO DEVE incluir selo de módulo nem rodapé extra (data de geração ou paginação).
- **FR-004**: O sistema DEVE usar o **mesmo** timbrado geral em todos os módulos cobertos — sem artes paralelas por domínio (a arte antiga da Ouvidoria, a linha decorativa do Diagnóstico e o cabeçalho só-texto deixam de ser a identidade oficial).
- **FR-005**: O sistema DEVE aplicar o timbrado 2026 **somente** ao tenant AGEMAN; os demais tenants mantêm o fallback atual até haver folha própria.
- **FR-006**: Novas emissões DEVEM nascer já na folha 2026; arquivos já baixados ou anexos externos já prontos NÃO são reescritos.
- **FR-007**: O conteúdo do documento (textos, tabelas, seções) DEVE respeitar a área útil da folha oficial — abaixo da faixa e dentro das margens da arte — sem sobrepor o cabeçalho.
- **FR-008**: Todas as famílias cobertas pelo FR-001 DEVEM oferecer download em PDF e em Word; os dois DEVEM carregar a mesma identidade visual oficial da folha 2026.
- **FR-009**: O sistema NÃO DEVE apresentar o timbrado antigo (logo isolada + título textual + selo “OUVIDORIA” no estilo atual, ou linha decorativa solta) em nenhuma emissão coberta após a troca.
- **FR-010**: Exportações em planilha e arquivos de dados PERMANECEM no formato atual — não são convertidas em ofício.
- **FR-011**: Relatórios de Insights e Maturidade do tenant AGEMAN que **já possuem** botão de exportar DEVEM oferecer ofício na folha 2026 em **PDF e Word** (ambos com a mesma identidade) e DEVEM manter a exportação HTML (quando ela já existir) como opção extra. Módulos de Insights/Maturidade **sem** exportação atual ficam fora desta entrega — o sistema NÃO DEVE criar botão de exportar novo só para aplicar o timbrado.
- **FR-012**: Se a arte da folha padrão 2026 estiver indisponível no momento da emissão no tenant AGEMAN, o sistema DEVE emitir somente o miolo (sem faixa, sem marca d’água e sem o timbrado antigo) e DEVE informar o operador de que a folha oficial não pôde ser aplicada.

### Key Entities

- **Folha padrão AGEMAN 2026**: arte oficial de papel timbrado vertical — faixa institucional, dados de contato da Prefeitura/AGEMAN e brasão em marca d’água. Fonte de verdade: `new-timbrado/Folha padrão 2026 - Vertical.docx`.
- **Documento emitido**: arquivo gerado pelo sistema para um registro ou relatório (ofício, dossiê, painel, histórico, insights, maturidade), destinado a download ou encaminhamento.
- **Tenant AGEMAN**: única instituição à qual a folha oficial se aplica nesta entrega.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% das emissões **padrão** cobertas pelo FR-001, feitas no tenant AGEMAN após a troca **com a arte disponível**, usam a folha padrão 2026 — zero emissão padrão nova com o timbrado antigo. A opção extra HTML de Insights/Maturidade pode existir, mas não é o caminho padrão.
- **SC-007**: Quando a arte oficial estiver indisponível, 100% dessas emissões saem só com o miolo (sem faixa, sem marca d’água e sem o cabeçalho antigo) e o operador recebe aviso explícito.
- **SC-008**: Em cada família coberta pelo FR-001, o operador encontra download em PDF e em Word após a publicação — ambos com a mesma folha 2026 quando a arte está disponível.
- **SC-002**: Um revisor institucional consegue reconhecer a folha oficial em até 10 segundos ao comparar o arquivo gerado com a `Folha padrão 2026 - Vertical.docx` (faixa + marca d’água, sem selo e sem rodapé extra).
- **SC-003**: Em uma amostragem de pelo menos um documento de cada família coberta pelo FR-001, o conteúdo útil não invade a faixa do cabeçalho em nenhuma página.
- **SC-004**: Um operador emite documentos de módulos distintos e confirma que a identidade visual é a mesma (um único timbrado geral, não artes por módulo).
- **SC-005**: Arquivos emitidos antes da troca permanecem inalterados; a mudança vale só da data de publicação em diante.
- **SC-006**: Em tenant que não é a AGEMAN, nenhuma emissão nova passa a exibir a arte 2026.

## Assumptions

- A fonte visual desta entrega é **somente** a folha **vertical** fornecida; não há folha paisagem nesta spec.
- Documentos já baixados pelo usuário ou anexos externos **não** são regenerados automaticamente.
- Planilhas e arquivos de dados não são papel timbrado.
- O texto, as tabelas e a estrutura interna de cada tipo de documento (o “miolo”) não mudam — só a identidade da folha, a oferta de PDF e Word em todas as famílias cobertas, e, no caso de Insights/Maturidade que já exportam, o ofício como caminho de ofício (HTML permanece extra).
- Outros tenants não recebem a arte da AGEMAN.
- Sem rodapé textual e sem selo de módulo: a faixa oficial já identifica AGEMAN e Prefeitura.
- “Insights e Maturidade” nesta entrega cobre **somente** os módulos que já têm botão de exportar — hoje, Compras Insights e Compras Maturidade. Não se inventa exportação em Ouvidoria, Gabinete, TI ou SIGED Insights/Maturidade.

## Inventário de escopo (após clarificação)

**Entram (tenant AGEMAN, emissões novas — PDF e Word em todas):**

- Dossiê de manifestação
- Relatório de gestão da Ouvidoria
- Relatório do painel e da seleção do Diagnóstico
- Documento institucional
- Histórico da demanda no Gabinete
- Dossiê do protocolo na Tramitação
- Notificação de incidente ANPD
- Relatórios de Insights e Maturidade **que já exportam** (hoje: Compras Insights e Compras Maturidade) — HTML permanece extra além do ofício

**Ficam fora:**

- Exportações em planilha (SIGED e similares)
- Anexos enviados pelo usuário
- Arquivos já baixados antes da publicação
- Qualquer emissão de tenant que não seja a AGEMAN
- Insights/Maturidade sem botão de exportar hoje (Ouvidoria, Gabinete, TI, SIGED)
