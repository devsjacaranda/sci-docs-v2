# Feature Specification: Desmockar Central de Documentação

**Feature Branch**: `023-global-docs`

**Created**: 2026-06-26

**Status**: Draft

**Input**: User description: "titulo: desmockar Central de Documentação | tipo: feature | modulo: global-docs | contexto: /global/documentacao | criar pelo menos 2 documentos de cada modulo desmocado existente"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Consultar documentação na Central Global (Priority: P1)

Como servidor autenticado com acesso à licença Base, preciso abrir a **Central de Documentação** (`/global/documentacao`) e ver manuais internos de uso do sistema organizados por módulo, carregados a partir de dados persistidos do meu órgão — **sem** depender de listas estáticas de demonstração.

**Why this priority**: A tela é o hub transversal de orientação operacional; enquanto exibir mock, equipes não confiam no conteúdo nem validam fluxos reais de consulta.

**Independent Test**: Autenticar em tenant com documentação seedada; acessar `/global/documentacao`; verificar que artigos exibidos correspondem aos registros persistidos (título, tipo, módulo, resumo, data de atualização) — **não** ao array `globalUsageDocs` em memória.

**Acceptance Scenarios**:

1. **Given** usuário autenticado com licença Base, **When** acessa `/global/documentacao`, **Then** vê a **Central de Documentação — Base** com artigos reais do tenant, distintos da Biblioteca Normativa (Pau-Brasil) e do Painel de Dados & IA (Cedro).
2. **Given** tenant com documentos cadastrados, **When** a central carrega, **Then** cada card exibe **título**, **tipo** (*Uso do módulo* ou *Guia de processo*), **módulo** associado, **resumo** e **data de atualização** provenientes do backend.
3. **Given** tenant sem documentos cadastrados, **When** a central carrega, **Then** exibe estado vazio orientando que a documentação ainda não foi publicada — **sem** cards fabricados de demonstração.
4. **Given** artigos de módulos distintos no tenant, **When** a central é exibida, **Then** o usuário identifica claramente a qual módulo operacional cada manual se refere.

---

### User Story 2 - Abrir detalhe de documento com passo a passo (Priority: P1)

Como servidor que consulta a central, preciso abrir o detalhe de um documento — especialmente **guias de processo** — e ler o conteúdo completo com passos numerados, dicas e referências, para executar o fluxo operacional corretamente.

**Why this priority**: O valor da central está no conteúdo acionável (passo a passo), não apenas em cards-resumo; hoje o mock limita essa experiência a um único guia estático de Compras.

**Independent Test**: Selecionar documento do tipo *Guia de processo* com passos seedados; verificar renderização ordenada de passos, dicas opcionais e referências; repetir para documento *Uso do módulo* sem passos.

**Acceptance Scenarios**:

1. **Given** documento do tipo *Guia de processo* com passos cadastrados, **When** o usuário abre o detalhe, **Then** vê lista numerada com **título**, **descrição** e **dica** (quando existir) para cada passo — na ordem definida.
2. **Given** documento com referências normativas ou internas, **When** o detalhe é exibido, **Then** referências aparecem como rótulos consultivos — **sem** confundir com modelos Pau-Brasil ou achados Jatobá.
3. **Given** documento do tipo *Uso do módulo*, **When** o usuário abre o detalhe, **Then** vê resumo e metadados completos — passos **não** são exibidos se não existirem.
4. **Given** documento inexistente ou removido, **When** o usuário tenta abrir o detalhe, **Then** recebe feedback claro de indisponibilidade — **sem** quebra silenciosa ou fallback para mock.

---

### User Story 3 - Filtrar e localizar documentação por módulo e tipo (Priority: P2)

Como servidor operacional, preciso filtrar a central por **módulo** e **tipo** de documento e buscar por palavras-chave no título ou resumo, para encontrar rapidamente o manual relevante ao meu trabalho diário.

**Why this priority**: Com ≥2 documentos por módulo, a navegação linear de cards deixa de ser suficiente; filtros reduzem tempo de localização.

**Independent Test**: Popular tenant com documentos de tipos e módulos distintos; aplicar filtro por módulo *Compras*; aplicar filtro por tipo *Guia de processo*; buscar termo presente no título; verificar resultados coerentes.

**Acceptance Scenarios**:

1. **Given** documentos de vários módulos, **When** o usuário filtra por um módulo específico, **Then** vê **somente** artigos daquele módulo.
2. **Given** documentos de tipos distintos, **When** o usuário filtra por *Uso do módulo* ou *Guia de processo*, **Then** a lista reflete exclusivamente o tipo selecionado.
3. **Given** termo de busca com correspondência no título ou resumo, **When** o usuário pesquisa, **Then** resultados aparecem em até **2 interações** (digitar + ver lista filtrada).
4. **Given** combinação de filtros sem resultados, **When** aplicada, **Then** exibe estado vazio informando que nenhum documento corresponde — **sem** restaurar mock.

---

### User Story 4 - Conteúdo inicial mínimo por módulo desmockado (Priority: P1)

Como administrador de plataforma ou equipe de implantação, preciso que cada módulo que hoje possui documentação mockada na central tenha **pelo menos 2 documentos persistidos** no tenant de referência, para validar a experiência real e orientar usuários desde o go-live.

**Why this priority**: O pedido explícito da feature define o piso de conteúdo; sem seed mínimo, a central ficaria vazia após desmock e inviabilizaria testes e demonstrações.

**Independent Test**: Após seed/carga inicial, contar documentos por módulo no tenant de referência; verificar ≥2 para cada módulo da lista canônica abaixo; abrir central e confirmar visibilidade.

**Acceptance Scenarios**:

1. **Given** tenant de referência após seed, **When** consultados os documentos dos módulos **Ouvidoria**, **Jurídico**, **Compras**, **Contratos** e **Patrimônio**, **Then** cada um possui **≥ 2** documentos publicados.
2. **Given** tenant de referência após seed, **When** consultado o módulo **Compras**, **Then** existe **pelo menos 1** *Guia de processo* com passos estruturados — preservando o valor do exemplo ETP hoje mockado.
3. **Given** documentos seedados, **When** exibidos na central, **Then** respeitam vocabulário de produto: tipos *Uso do módulo* e *Guia de processo*; distinção clara de Pau-Brasil, Jatobá e Cedro no copy.
4. **Given** módulo **Protocolo Virtual** (oculto na navegação principal), **When** avaliado escopo desta entrega, **Then** documentação seed **PODE** ser incluída no backend para consistência — **sem** exigir item de menu dedicado.

---

### User Story 5 - Desmockar painel de documentação por módulo (Priority: P2)

Como servidor que acessa documentação contextual de um módulo operacional (ex.: telas `docs` fora do escopo global), preciso ver guias reais daquele módulo — **não** mensagem genérica ou objeto estático `moduleProcessGuides`.

**Why this priority**: A central global e os painéis por módulo compartilham a mesma fonte de verdade; manter mock parcial perpetua inconsistência.

**Independent Test**: Acessar tela de documentação contextual de módulo com guias seedados (ex.: Compras); verificar renderização do guia de processo com passos a partir da API; acessar módulo sem guia e ver estado vazio orientativo.

**Acceptance Scenarios**:

1. **Given** módulo com *Guia de processo* cadastrado, **When** o usuário abre a documentação contextual do módulo, **Then** vê o guia mais relevante (ou lista para escolha) carregado do backend.
2. **Given** módulo sem guia cadastrado, **When** a tela contextual carrega, **Then** exibe mensagem orientativa — **sem** fallback para mock em memória.
3. **Given** módulo com múltiplos documentos, **When** painel contextual suporta seleção, **Then** usuário consegue alternar entre documentos daquele módulo.

---

### Edge Cases

- Tenant recém-criado sem seed de documentação: central exibe estado vazio; **nunca** reintroduz mock.
- Documento com título longo ou resumo extenso: layout permanece legível em viewport desktop e mobile.
- Dois documentos do mesmo módulo e tipo: ambos aparecem na listagem sem colisão de identificador.
- Documento atualizado após publicação: data de atualização reflete última alteração visível ao usuário.
- Usuário sem licença Base tenta acessar `/global/documentacao`: acesso negado conforme regras de licença existentes da plataforma.
- Busca com caracteres especiais ou termo inexistente: retorna lista vazia com mensagem clara — **sem** erro genérico.
- Guia de processo com passos fora de ordem no cadastro: exibição respeita ordem explícita definida no registro.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: O sistema **DEVE** persistir documentos da Central de Documentação por tenant, com isolamento entre órgãos.
- **FR-002**: Cada documento **DEVE** possuir: identificador único, título, tipo (*Uso do módulo* | *Guia de processo*), módulo associado, resumo, data de atualização e conteúdo detalhado quando aplicável.
- **FR-003**: Documentos do tipo *Guia de processo* **DEVEM** suportar passos ordenados com título, descrição e dica opcional.
- **FR-004**: Documentos **PODEM** incluir lista de referências consultivas (texto livre).
- **FR-005**: A tela `/global/documentacao` **DEVE** consumir exclusivamente dados persistidos — **NUNCA** arrays mock em memória após conclusão desta feature.
- **FR-006**: A central **DEVE** exibir cards-resumo coerentes com o design atual (título, badge de tipo, módulo, resumo, data).
- **FR-007**: O usuário **DEVE** poder abrir o detalhe de um documento a partir da central.
- **FR-008**: O sistema **DEVE** permitir filtrar documentos por módulo e por tipo na central.
- **FR-009**: O sistema **DEVE** permitir busca por termo no título ou resumo.
- **FR-010**: O seed/carga inicial **DEVE** criar **≥ 2 documentos** para cada módulo desmockado existente: **Ouvidoria**, **Jurídico**, **Compras**, **Contratos**, **Patrimônio** e **Protocolo Virtual**.
- **FR-011**: O seed **DEVE** incluir **≥ 1** guia de processo com passos para **Compras**, equivalente funcional ao exemplo ETP hoje mockado.
- **FR-012**: Painéis de documentação contextual por módulo **DEVEM** consumir a mesma fonte persistida — **sem** `moduleProcessGuides` estático.
- **FR-013**: Copy e rótulos **DEVEM** conformar [regras-plataforma.md](../../../.cursor/docs/regras-plataforma.md): distinção Base vs Pau-Brasil vs Jatobá vs Cedro.
- **FR-014**: Acesso à central **DEVE** exigir licença **Base** e autenticação válida no tenant.
- **FR-015**: Documentos **NÃO DEVEM** ser confundidos com normativos Pau-Brasil nem insights Cedro — escopo limitado a manuais internos de uso e guias operacionais.

### Key Entities

- **Documento**: Artigo da central pertencente a um tenant; atributos de catálogo (título, tipo, módulo, resumo, datas) e relação com passos/referências.
- **Passo de processo**: Etapa ordenada de um guia; título, descrição, dica opcional, ordem explícita.
- **Referência consultiva**: Rótulo textual associado a um documento (ex.: lei, modelo interno, integração) — informativo, sem link normativo Pau-Brasil.
- **Módulo operacional**: Domínio funcional ao qual o documento se aplica (Ouvidoria, Jurídico, Compras, etc.).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% dos artigos exibidos em `/global/documentacao` provêm de dados persistidos — zero dependência de mock em memória na tela concluída.
- **SC-002**: Cada módulo da lista FR-010 possui ≥ 2 documentos no tenant de referência após seed.
- **SC-003**: Usuário localiza documento de um módulo específico via filtro em ≤ 10 segundos (teste moderado com 12+ artigos).
- **SC-004**: Guia de processo com passos renderiza 100% das etapas cadastradas na ordem correta.
- **SC-005**: 90% dos usuários de teste identificam corretamente a diferença entre Central de Documentação (Base) e Biblioteca Normativa (Pau-Brasil) após leitura da tela.
- **SC-006**: Tenant vazio exibe estado orientativo — nenhum dado fabricado de demonstração.

## Assumptions

- Escopo **leitura + seed inicial**; CRUD administrativo de documentos por UI fica **fora** desta entrega — conteúdo inicial via seed/migração/carga administrativa técnica.
- Módulos alvo são os que **já possuem mock** em `globalUsageDocs` (6 módulos); expansão para Tramitação, IT e Gabinete é desejável mas **não** bloqueia entrega se seed cumprir FR-010.
- Protocolo Virtual permanece oculto na navegação; documentos seedados para ele existem para consistência de dados, sem exigência de visibilidade na sidebar.
- Documentos são **internos ao tenant**; não há compartilhamento cross-tenant nesta versão.
- Idioma do conteúdo seed: português (Brasil), alinhado ao copy existente nos mocks.
- Permissões seguem licença Base global; não há perfil editor dedicado nesta entrega.
- Formato de conteúdo detalhado: texto estruturado com passos — **sem** upload de PDF ou rich media nesta versão.
- A distinção semântica Base / Pau-Brasil / Jatobá / Cedro permanece conforme constitution e licenças canônicas.

## Dependencies

- Autenticação e tenant context já operacionais na plataforma.
- Tela `/global/documentacao` e componentes `GlobalDocsPanel` / `ModuleDocsPanel` existentes — substituir fonte de dados, não reinventar layout.
- Vocabulário e copy: `.cursor/docs/regras-plataforma.md` e `.cursor/docs/licencas-canonicas.md`.
