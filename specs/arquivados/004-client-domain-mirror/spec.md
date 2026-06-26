# Feature Specification: Arquitetura Modular Espelho da API (Client)

**Feature Branch**: `004-client-domain-mirror`

**Created**: 2026-06-06

**Status**: Completed

**Input**: User description: "Ajustar modelo de pasta e arquitetura monorepo com turborepo para arquitetura espelho da API — modular por domínio (apenas pastas), ser espelho da API."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Continuidade do produto após reorganização (Priority: P1)

Como desenvolvedor frontend, preciso que a aplicação web continue funcionando exatamente como antes após a reorganização modular por domínio, para que usuários finais e stakeholders não sofram regressões durante a refatoração estrutural de pastas.

**Why this priority**: A migração só é aceitável se o comportamento visível permanecer intacto — login, navegação por licenças, telas de ouvidoria com API real, painéis administrativos e catálogo de telas mock. Sem isso, qualquer ganho de arquitetura é inválido.

**Independent Test**: Pode ser testado executando os fluxos principais da SPA (login, dashboard global, navegação Carvalho/Pau-Brasil/Jatobá/Cedro, ouvidoria lista/nova/detalhe, telas admin de usuários/setores/permissões) e comparando com o comportamento pré-migração. Entrega valor imediato: zero downtime funcional.

**Acceptance Scenarios**:

1. **Given** a estrutura modular já migrada, **When** um desenvolvedor inicia o ambiente de desenvolvimento da aplicação principal, **Then** a SPA carrega com as mesmas rotas, layouts e componentes visíveis que antes da migração.
2. **Given** a aplicação em execução, **When** o usuário navega entre telas de diferentes licenças, **Then** breadcrumbs, alertas de licença, filtros e restrições de acesso se comportam como na versão anterior.
3. **Given** fluxos de ouvidoria e admin já existentes, **When** o usuário cria, edita, lista ou consulta manifestações e gerencia usuários/setores/permissões, **Then** todas as interações concluem com o mesmo resultado observável de antes.
4. **Given** o código migrado, **When** é executado o build de produção da aplicação principal, **Then** o artefato gerado é implantável sem alterações no processo de deploy atual.

---

### User Story 2 - Navegabilidade espelho da API (Priority: P2)

Como desenvolvedor frontend, preciso localizar o código de cada domínio de negócio na mesma estrutura de pastas que a API usa por módulo, para reduzir tempo de onboarding e manter paridade mental entre backend e frontend.

**Why this priority**: O objetivo central da feature é espelhar a API — slugs de domínio idênticos e camadas previsíveis por módulo. Isso acelera implementação de features full-stack e revisões de código.

**Independent Test**: Pode ser testado pedindo a um desenvolvedor que encontre, sem mapa externo, o client HTTP e as páginas de ouvidoria, auth e permissão — todos devem estar sob `modules/<slug>/` com camadas `pages/`, `components/`, `api/` conforme aplicável.

**Acceptance Scenarios**:

1. **Given** um módulo de domínio registrado na API (ex.: ouvidoria, auth, permissao, setor), **When** o desenvolvedor busca o código frontend correspondente, **Then** encontra pasta homônima em `modules/<slug>/` dentro da aplicação web.
2. **Given** um módulo de domínio com UI implementada, **When** o desenvolvedor abre a pasta do módulo, **Then** encontra camadas organizadas por responsabilidade (pages, components, api, hooks, lib ou context conforme necessidade do domínio).
3. **Given** consumo de endpoint de municípios pela ouvidoria, **When** o desenvolvedor busca o client HTTP de endereços, **Then** encontra em `modules/address/api/` e não duplicado em outros domínios.

---

### User Story 3 - Convenção documentada para novos domínios (Priority: P3)

Como desenvolvedor ou revisor, preciso de regras claras sobre onde colocar código novo — domínio, shell, shared ou pacote compartilhado — para que cada feature futura siga a mesma arquitetura sem ambiguidade.

**Why this priority**: A reorganização só escala se houver guia explícito de decisão (shell vs shared vs domínio) e checklist de paridade com novos módulos da API.

**Independent Test**: Pode ser testado entregando a documentação a um par revisor e verificando que consegue classificar corretamente três exemplos hipotéticos (layout global, componente usado por ouvidoria e permissão, página exclusiva de setor) sem consultar o autor da migração.

**Acceptance Scenarios**:

1. **Given** a documentação atualizada na raiz do frontend, **When** um desenvolvedor consulta como adicionar um novo domínio espelhando a API, **Then** encontra estrutura de pastas, regra shell/shared/domínio e grafo de dependências permitido.
2. **Given** um componente reutilizado por dois ou mais domínios de negócio, **When** o revisor inspeciona a localização, **Then** o componente reside em `modules/shared/` e não duplicado entre domínios.
3. **Given** código de infraestrutura da SPA (layout, navegação, catálogo mock, config global), **When** o revisor inspeciona a localização, **Then** reside em `modules/shell/` e não em pastas legadas na raiz de `src/`.

---

### Edge Cases

- O que acontece quando um domínio frontend importa implementação interna de outro domínio? A verificação de tipos ou build deve falhar ou o revisor deve rejeitar — dependências cross-domain só via barrels públicos do módulo ou via `modules/shared/`.
- Como tratar componentes mock usados por múltiplas licenças? Infraestrutura de demonstração permanece em `shell/`; widgets reutilizáveis entre domínios vão para `shared/`.
- O que acontece quando a API ganha um novo módulo sem pasta correspondente no client? Deve ser detectado em revisão de paridade ou checklist de onboarding — a spec exige correspondência 1:1 de slugs.
- Como ouvidoria consome municípios sem acoplar internals de address? Ouvidoria importa apenas a API pública exportada por `modules/address/` (barrel), não arquivos internos do módulo.
- O que acontece com pastas legadas (`pages/`, `components/`, `lib/` na raiz de `src/`) após migração? Devem estar vazias ou removidas — nenhum arquivo de produção permanece nelas.
- Como evitar acoplamento circular entre shell e domínios? `shell` não importa domínios de negócio; domínios importam shell e shared conforme necessário.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: A aplicação web DEVE organizar código de domínio de negócio sob `modules/<slug>/`, onde `<slug>` corresponde aos módulos de domínio registrados na API (auth, address, ouvidoria, permissao, setor, tenant, audit).
- **FR-002**: Cada módulo de domínio com UI DEVE expor camadas mínimas `pages/`, `components/` e `api/`; camadas opcionais (`hooks/`, `lib/`, `context/`) DEVEM ser usadas quando o domínio possui lógica ou estado próprio nessas categorias.
- **FR-003**: Código de plataforma da SPA (layout, navegação, catálogo de telas mock, configuração global de telas, contextos globais de tema e filtros) DEVE residir em `modules/shell/`.
- **FR-004**: Código reutilizado por dois ou mais domínios de negócio (componentes, hooks, pages ou composições de UI locais) DEVE residir em `modules/shared/` e NÃO ser duplicado entre domínios.
- **FR-005**: Pacotes compartilhados do monorepo frontend responsáveis por componentes de interface genéricos, tipos de licença e configuração de tipos DEVEM permanecer inalterados em escopo e responsabilidade nesta feature.
- **FR-006**: A migração DEVE ser completa (big bang): ao final, nenhum arquivo de produção permanece nas pastas legadas top-level `src/pages/`, `src/components/`, `src/lib/`, `src/config/`, `src/context/`, `src/data/` ou `src/hooks/`.
- **FR-007**: Os domínios address, tenant e audit DEVEM existir como módulos mesmo sem UI completa; address DEVE abrigar o client HTTP de consulta de municípios consumido pela ouvidoria.
- **FR-008**: Dependências entre módulos DEVEM respeitar grafo acíclico: shell não importa domínios de negócio; domínios não importam internals de outros domínios — apenas barrels públicos ou `modules/shared/`.
- **FR-009**: A documentação do frontend DEVE descrever layout de módulos, distinção shell/shared/domínio, grafo de dependências e checklist para adicionar novo domínio espelhando a API.
- **FR-010**: O escopo DEVE limitar-se à reorganização de pastas dentro da aplicação web do frontend; a API REST e seus contratos permanecem inalterados nesta feature.
- **FR-011**: O registro central de rotas DEVE permanecer em `app/` na raiz de `src/`; domínios PODEM exportar helpers de carregamento lazy via barrels públicos consumidos pelo router.
- **FR-012**: Clients HTTP hoje agrupados em arquivos cross-domain (ex.: admin unificado) DEVEM ser divididos nas fronteiras de domínio correspondentes (permissao vs setor; ouvidoria vs address).

### Key Entities

- **Módulo de domínio**: Unidade de organização frontend espelhando um módulo da API — contém pages, components, api e camadas opcionais; slug idêntico ao backend.
- **Módulo shell**: Infraestrutura da SPA — layout, navegação, mocks genéricos, config global, contextos transversais, client HTTP base.
- **Módulo shared**: Código reutilizado por dois ou mais domínios de negócio — componentes, hooks, pages ou composições locais (distinto de pacotes compartilhados do monorepo).
- **Pacote compartilhado do monorepo**: Módulo interno do workspace frontend para UI genérica, tipos de licença e configuração TypeScript — permanece fora de `modules/`.
- **Barrel público**: Ponto de exportação controlada de um módulo de domínio — única forma permitida de consumo cross-domain entre domínios.
- **Pastas legadas**: Estrutura anterior organizada por tipo técnico na raiz de `src/` — deve ser eliminada após migração.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% dos fluxos de aceite das features de monorepo frontend e ouvidoria interna passam após a migração, sem regressões reportadas em smoke test manual.
- **SC-002**: Um revisor consegue mapear cada módulo de domínio da API para pasta homônima em `modules/` em menos de 2 minutos, sem mapa externo.
- **SC-003**: Zero arquivos de produção (`.ts`, `.tsx`) permanecem nas pastas legadas top-level de `src/` após conclusão da migração.
- **SC-004**: Um novo desenvolvedor localiza páginas, componentes e client HTTP de ouvidoria exclusivamente pela convenção `modules/ouvidoria/` em menos de 5 minutos, sem documentação ad hoc.
- **SC-005**: O build de produção da aplicação principal conclui com sucesso e produz artefato implantável equivalente ao build pré-migração, sem alteração de contrato com o ambiente de hospedagem.
- **SC-006**: A documentação na raiz do frontend permite a um par revisor classificar corretamente 3 exemplos de código (shell vs shared vs domínio) na primeira tentativa.
- **SC-007**: Dependências circulares entre módulos de domínio são zero — verificável por revisão de imports ou ferramenta de boundary na fase de implementação.

## Assumptions

- O alias de importação `@/*` apontando para `./src/*` permanece; caminhos migram para `@/modules/<dominio>/...`.
- A reorganização é exclusivamente de pastas dentro da aplicação web — não cria pacotes npm separados por domínio no Turborepo.
- Pacotes compartilhados existentes do monorepo frontend (`@ci/ui`, `@ci/domain`, `@ci/typescript-config`) mantêm responsabilidades atuais: UI genérica, tipos de licença e bases TypeScript.
- Divisão de clients HTTP administrativos segue fronteiras REST existentes entre permissão e setor/usuários.
- Domínios tenant e audit existem como scaffold de camadas na v1; audit abriga componentes mock de logs quando aplicável.
- Validação pós-migração usa verificação de tipos, lint, build e smoke manual — suite E2E automatizada não é pré-requisito desta feature.
- A constituição do projeto será atualizada na fase de plano técnico para documentar espelho modular frontend, análogo ao backend.
- Migração big bang ocorre em entrega única; não há coexistência prolongada de pastas legadas e modulares em produção.
