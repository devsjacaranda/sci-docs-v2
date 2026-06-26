# Feature Specification: Monorepo Frontend com Turborepo

**Feature Branch**: `001-client-turborepo`

**Created**: 2026-06-05

**Status**: Completed

**Input**: User description: "Transformar frontend ci-client-v2 em monorepo com Turborepo — refatorar para monorepo com turbo repo"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Continuidade do produto após migração (Priority: P1)

Como desenvolvedor frontend, preciso que a aplicação web existente continue funcionando exatamente como antes após a reorganização em monorepo, para que usuários finais e stakeholders não sofram regressões durante a refatoração estrutural.

**Why this priority**: A migração só é aceitável se o comportamento visível e os fluxos atuais (navegação, telas mock, autenticação simulada, temas, filtros de licença) permanecerem intactos. Sem isso, qualquer ganho de arquitetura é inválido.

**Independent Test**: Pode ser testado executando os fluxos principais da SPA (login, dashboard, navegação por licenças, telas administrativas) e comparando com o comportamento pré-migração. Entrega valor imediato: zero downtime funcional.

**Acceptance Scenarios**:

1. **Given** a estrutura monorepo já migrada, **When** um desenvolvedor inicia o ambiente de desenvolvimento da aplicação principal, **Then** a SPA carrega com as mesmas rotas, layouts e componentes visíveis que antes da migração.
2. **Given** a aplicação em execução, **When** o usuário navega entre telas de diferentes licenças (Carvalho, Pau-Brasil, Jatobá, Cedro), **Then** breadcrumbs, alertas de licença e restrições de acesso se comportam como na versão anterior.
3. **Given** o código migrado, **When** é executado o build de produção da aplicação principal, **Then** o artefato gerado é implantável sem alterações no processo de deploy atual.

---

### User Story 2 - Código compartilhado entre pacotes (Priority: P2)

Como desenvolvedor frontend, preciso extrair e consumir código reutilizável (componentes de interface, utilitários, tipos e configurações) em pacotes internos, para evitar duplicação e preparar o crescimento do frontend.

**Why this priority**: O principal motivo da migração é habilitar reutilização. Sem pacotes compartilhados funcionais, o monorepo seria apenas reorganização de pastas sem ganho sustentável.

**Independent Test**: Pode ser testado criando ou movendo um módulo compartilhado (ex.: utilitário de licenças ou componente de UI) para um pacote interno e importando-o na aplicação principal. Entrega valor: base para futuros apps ou bibliotecas frontend.

**Acceptance Scenarios**:

1. **Given** um pacote interno com código compartilhado, **When** a aplicação principal importa esse pacote, **Then** o código compila e executa sem cópia duplicada no repositório.
2. **Given** alteração em um pacote compartilhado, **When** a aplicação principal é reconstruída, **Then** a alteração reflete automaticamente no build sem passos manuais de sincronização.
3. **Given** dependências entre pacotes, **When** um pacote downstream é alterado, **Then** apenas os pacotes afetados precisam ser reconstruídos (build incremental).

---

### User Story 3 - Orquestração de tarefas a partir da raiz do frontend (Priority: P3)

Como desenvolvedor ou pipeline de integração contínua, preciso executar tarefas comuns (desenvolvimento, build, lint, verificação de tipos) a partir de um único ponto na raiz do frontend, para reduzir comandos manuais e tempo de CI.

**Why this priority**: Turborepo entrega valor quando centraliza e cacheia tarefas. É secundário à continuidade funcional e à extração de pacotes, mas essencial para justificar a adoção.

**Independent Test**: Pode ser testado rodando comandos unificados na raiz do monorepo frontend e verificando que todas as aplicações e pacotes relevantes são processados na ordem correta. Entrega valor: DX e CI mais previsíveis.

**Acceptance Scenarios**:

1. **Given** o monorepo configurado, **When** um desenvolvedor executa o comando de desenvolvimento na raiz, **Then** a aplicação principal inicia sem exigir navegação manual para subpastas.
2. **Given** o monorepo configurado, **When** um pipeline executa build na raiz, **Then** todos os pacotes com dependências são construídos na ordem correta e falhas em qualquer pacote interrompem o pipeline com mensagem clara.
3. **Given** uma segunda execução de build sem alterações, **When** o orquestrador utiliza cache, **Then** o tempo total de build reduz significativamente em relação à primeira execução.

---

### Edge Cases

- O que acontece quando um pacote compartilhado é removido ou renomeado enquanto a aplicação principal ainda depende dele? O build deve falhar com diagnóstico explícito, não em runtime silencioso.
- Como o sistema lida com dependências circulares entre pacotes internos? Devem ser detectadas e bloqueadas na configuração do workspace.
- O que acontece quando apenas um subpacote é alterado? Apenas esse subpacote e seus dependentes devem ser reprocessados.
- Como novos desenvolvedores configuram o ambiente? A documentação na raiz do frontend deve listar os passos mínimos (instalação, dev, build) sem ambiguidade.
- A API (`ci-api-v2`) permanece fora do escopo deste monorepo frontend — alterações não devem exigir mudanças na API.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: O diretório `ci-client-v2` DEVE ser reorganizado como monorepo com múltiplos pacotes internos, mantendo a aplicação web existente como pacote principal.
- **FR-002**: A aplicação principal DEVE preservar 100% dos fluxos de usuário e telas existentes após a migração, sem alteração de comportamento visível.
- **FR-003**: O monorepo DEVE suportar pelo menos um pacote compartilhado interno para código reutilizável (componentes de UI, utilitários ou tipos).
- **FR-004**: Pacotes internos DEVEM ser consumíveis pela aplicação principal via referências de workspace, sem publicação externa.
- **FR-005**: O monorepo DEVE expor comandos unificados na raiz para desenvolvimento, build, lint e verificação de tipos da aplicação principal e pacotes dependentes.
- **FR-006**: O orquestrador DEVE respeitar a ordem de dependências entre pacotes ao executar tarefas (pacotes upstream antes dos downstream).
- **FR-007**: O orquestrador DEVE suportar cache de tarefas para acelerar execuções repetidas sem alterações de código.
- **FR-008**: A migração DEVE incluir documentação atualizada na raiz do frontend descrevendo a nova estrutura, comandos e convenções de pacotes.
- **FR-009**: Variáveis de ambiente e configurações de deploy da SPA DEVEM continuar funcionando sem exigir renomeação de prefixos ou mudança de contrato com o ambiente de hospedagem.
- **FR-010**: O escopo DEVE limitar-se ao frontend (`ci-client-v2`); a API (`ci-api-v2`) e demais pacotes da raiz do repositório CI v2 permanecem inalterados nesta feature.
- **FR-011**: A estrutura inicial DEVE prever extensão futura (novos apps ou pacotes) sem nova migração estrutural.
- **FR-012**: Dependências circulares entre pacotes internos DEVEM ser impedidas ou detectadas com falha explícita no build.

### Key Entities

- **Aplicação principal**: O pacote que entrega a SPA CI v2 ao usuário final — contém rotas, páginas, layouts e integração com mocks/dados locais.
- **Pacote compartilhado**: Módulo interno reutilizável (UI, utilitários, tipos, config) consumido por uma ou mais aplicações do monorepo.
- **Workspace frontend**: O conjunto de pacotes sob `ci-client-v2` gerenciados como unidade, com dependências internas resolvidas localmente.
- **Tarefa orquestrada**: Operação padronizada (dev, build, lint, typecheck) executável na raiz e propagada aos pacotes conforme grafo de dependências.
- **Grafo de dependências**: Relação direcional entre pacotes que define ordem de build e escopo de cache incremental.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% dos fluxos de aceitação da aplicação principal (login, navegação, telas por licença, tema claro/escuro) passam em teste manual ou automatizado pós-migração, sem regressões reportadas.
- **SC-002**: Um novo desenvolvedor consegue clonar o repositório, instalar dependências e iniciar o ambiente de desenvolvimento em menos de 10 minutos seguindo apenas a documentação da raiz do frontend.
- **SC-003**: O build completo na raiz do monorepo frontend conclui com sucesso e produz artefato implantável equivalente ao build pré-migração.
- **SC-004**: Em execução repetida de build sem alterações de código, o tempo total reduz em pelo menos 50% em relação à primeira execução (cache efetivo).
- **SC-005**: Pelo menos um módulo real do código atual (ex.: utilitários de licença, componente UI ou tipos de tela) reside em pacote compartilhado e é consumido pela aplicação principal sem duplicação.
- **SC-006**: Alteração em pacote compartilhado reflete na aplicação principal em uma única etapa de rebuild, sem cópia manual de arquivos.
- **SC-007**: Documentação na raiz do frontend lista estrutura de pacotes, comandos e convenção para adicionar novos pacotes — validável por revisão de par sem ambiguidades.

## Assumptions

- O gerenciador de pacotes será workspaces nativos do ecossistema já utilizado no projeto (npm), sem migração para outro gerenciador nesta feature.
- A aplicação principal continuará sendo uma SPA com roteamento client-side; não há escopo para SSR ou novos apps nesta entrega inicial.
- A extração inicial de pacotes compartilhados focará em código já existente com alto potencial de reuso (componentes UI base, utilitários de licença/tema, tipos), não em reescrita de lógica de negócio.
- O deploy continua sendo estático (artefato build da SPA); não há mudança de infraestrutura de hospedagem nesta feature.
- Testes automatizados existentes (se houver) serão adaptados aos novos caminhos; ausência de suite ampla não bloqueia a migração, mas fluxos críticos serão validados manualmente.
- A constituição do projeto será atualizada na fase de implementação para refletir que o monorepo Turborepo frontend deixou de ser "fora de escopo".
- Não há requisito de publicar pacotes internos em registry externo (npm público/privado) nesta feature.
