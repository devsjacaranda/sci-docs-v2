# Feature Specification: Shared Address Hooks

**Feature Branch**: `006-shared-address-hooks`

**Created**: 2026-06-19

**Status**: Completed

**Input**: User description: "Importar e criar hooks reutilizáveis no monorepo — módulo shared, integração ViaCEP e API IBGE. Endereço universal controlado pela tabela Address (postalCode, street, number, complement, landmark, neighborhood, zone, municipioIbge). Frontend only: hooks React em modules/shared, chamadas diretas do browser, municípios por UF, hooks + AddressForm + AddressFields."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Auto-preencher endereço por CEP (Priority: P1)

Como servidor que preenche cadastros com endereço (manifestações, cadastros institucionais, etc.), preciso informar o CEP e ver logradouro, bairro e município preenchidos automaticamente, para reduzir digitação manual e erros de endereço inconsistente com o padrão nacional.

**Why this priority**: Consulta por CEP é o fluxo mais frequente em formulários de endereço no Brasil; sem isso, cada módulo reimplementa a mesma lógica com risco de divergência do modelo canônico de endereço.

**Independent Test**: Pode ser testado digitando um CEP válido de 8 dígitos em qualquer formulário que use a capacidade compartilhada e verificando preenchimento automático de logradouro, bairro e município — sem depender de formulário completo ou lista de municípios.

**Acceptance Scenarios**:

1. **Given** um CEP válido com 8 dígitos numéricos, **When** o usuário conclui a digitação do CEP, **Then** o sistema consulta a base postal e preenche logradouro, bairro e código do município conforme o modelo canônico de endereço.
2. **Given** um CEP inexistente na base postal, **When** a consulta retorna sem resultado, **Then** o usuário vê mensagem clara de CEP não encontrado e pode continuar preenchendo manualmente os demais campos.
3. **Given** um CEP com formato inválido (menos de 8 dígitos, letras ou espaços), **When** o usuário tenta consultar, **Then** o sistema não dispara consulta externa e informa que o formato do CEP é inválido.
4. **Given** campos já preenchidos manualmente (número, complemento, ponto de referência), **When** o CEP é consultado com sucesso, **Then** apenas os campos derivados da consulta postal são atualizados — campos preenchidos pelo usuário permanecem intactos.

---

### User Story 2 - Selecionar município por UF (Priority: P1)

Como servidor que cadastra endereços, preciso selecionar o município a partir de uma lista filtrada pela UF escolhida, para garantir que o município informado corresponda ao código IBGE canônico exigido pelo modelo de endereço.

**Why this priority**: O vínculo com município IBGE é obrigatório no modelo canônico; sem lista padronizada por UF, cada tela inventa opções ou aceita texto livre incompatível com persistência.

**Independent Test**: Pode ser testado selecionando uma UF e verificando que a lista de municípios exibe nome e código IBGE correspondentes — sem depender de consulta por CEP ou formulário completo.

**Acceptance Scenarios**:

1. **Given** uma UF selecionada (ex.: AM), **When** o usuário abre o seletor de município, **Then** vê lista de municípios daquela UF com identificador IBGE de 7 dígitos e nome.
2. **Given** nenhuma UF selecionada, **When** o usuário tenta escolher município, **Then** o seletor permanece desabilitado ou solicita UF primeiro.
3. **Given** troca de UF após município já selecionado, **When** a UF muda, **Then** a seleção de município anterior é limpa para evitar inconsistência UF/município.
4. **Given** consulta por CEP que retorna município, **When** o município IBGE é identificado, **Then** o seletor de município reflete a opção correspondente na UF retornada.

---

### User Story 3 - Formulário de endereço reutilizável (Priority: P2)

Como desenvolvedor de módulo de domínio (ouvidoria, tramitação, etc.), preciso usar um formulário de endereço pronto que cubra todos os campos do modelo canônico e integre consulta por CEP e seleção de município, para não duplicar UI e regras de endereço em cada feature.

**Why this priority**: Acelera entrega de novas telas com endereço e garante paridade visual e funcional entre módulos, desde que os fluxos P1 (CEP e municípios) existam.

**Independent Test**: Pode ser testado incorporando o formulário reutilizável em uma tela mock e verificando presença de todos os campos canônicos, consulta CEP e seletor UF/município — sem implementar lógica adicional no módulo consumidor.

**Acceptance Scenarios**:

1. **Given** o formulário reutilizável de endereço, **When** renderizado, **Then** exibe todos os campos do modelo canônico: CEP, logradouro, número, complemento, ponto de referência, bairro, zona e município (via UF + seleção).
2. **Given** o formulário em modo controlado, **When** o módulo consumidor fornece valores iniciais, **Then** o formulário reflete o estado recebido e notifica alterações de volta ao consumidor.
3. **Given** estado de carregamento durante consulta CEP ou municípios, **When** operação em andamento, **Then** campos afetados indicam carregamento sem bloquear edição manual dos demais campos.
4. **Given** erro de rede ou serviço indisponível, **When** consulta falha, **Then** o usuário vê mensagem amigável e pode continuar preenchendo manualmente.

---

### User Story 4 - Campos de endereço composáveis (Priority: P3)

Como desenvolvedor de módulo com layout customizado, preciso usar campos de endereço individuais e composáveis (CEP, logradouro, UF, município, etc.) separadamente, para montar formulários parciais ou layouts específicos sem importar o formulário completo.

**Why this priority**: Alguns fluxos exigem apenas subconjunto de campos ou ordem visual diferente; composabilidade evita fork do formulário completo.

**Independent Test**: Pode ser testado montando uma tela com apenas CEP + logradouro + município usando os campos composáveis, verificando que cada campo mantém comportamento isolado (validação, consulta, estados).

**Acceptance Scenarios**:

1. **Given** campos composáveis exportados individualmente, **When** o desenvolvedor monta layout customizado, **Then** cada campo funciona de forma independente respeitando o modelo canônico de atributos.
2. **Given** campo CEP composável, **When** CEP válido informado, **Then** dispara consulta e propaga dados para campos irmãos via callback ou contexto compartilhado definido pelo consumidor.
3. **Given** campo município composável, **When** acoplado a seletor de UF, **Then** lista apenas municípios da UF selecionada.
4. **Given** uso exclusivo de campos composáveis (sem formulário completo), **When** persistência ocorre, **Then** o objeto resultante contém apenas atributos válidos do modelo canônico — sem campos extras inventados.

---

### Edge Cases

- CEP válido em formato mas inexistente na base postal (ex.: 99999-999): mensagem clara, preenchimento manual permitido.
- CEP com hífen ou máscara na digitação: normalização para 8 dígitos antes da consulta.
- Serviço postal temporariamente indisponível ou timeout: fallback para preenchimento manual com aviso ao usuário.
- Serviço IBGE indisponível ao carregar municípios: lista vazia com mensagem de erro e possibilidade de retry.
- UF inválida ou vazia passada ao seletor de municípios: nenhuma consulta disparada; estado idle.
- Município retornado pelo CEP não encontrado na lista IBGE da UF (divergência rara): usuário pode selecionar manualmente; sistema não bloqueia salvamento por inconsistência de lookup.
- Usuário altera manualmente logradouro/bairro após auto-preenchimento: alterações manuais são preservadas até nova consulta de CEP.
- Formulário parcial (campos composáveis): campos omitidos não impedem persistência dos demais atributos canônicos informados.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: O sistema MUST disponibilizar capacidade compartilhada de consulta de endereço por CEP, reutilizável por qualquer módulo do cliente sem duplicação de lógica.
- **FR-002**: A consulta por CEP MUST validar formato (exatamente 8 dígitos numéricos) antes de acionar serviço externo.
- **FR-003**: Resultado de consulta CEP MUST mapear para atributos canônicos: CEP (`postalCode`), logradouro (`street`), bairro (`neighborhood`) e código IBGE do município (`municipioIbge`).
- **FR-004**: O sistema MUST disponibilizar capacidade compartilhada de listagem de municípios filtrada por UF, retornando código IBGE (7 dígitos), nome e UF.
- **FR-005**: Ambas as capacidades (CEP e municípios) MUST expor estados discerníveis de carregamento, sucesso, erro e dados vazios para consumo por formulários e campos.
- **FR-006**: Auto-preenchimento por CEP MUST NOT sobrescrever campos preenchidos manualmente pelo usuário que não derivam da consulta postal (número, complemento, ponto de referência).
- **FR-007**: O formulário reutilizável de endereço MUST cobrir integralmente os campos do modelo canônico: CEP, logradouro, número, complemento, ponto de referência, bairro, zona e município (mediante UF + seleção).
- **FR-008**: Campos composáveis MUST ser exportados de forma que módulos consumidores montem layouts parciais ou customizados sem duplicar regras de consulta ou validação.
- **FR-009**: Todo artefato compartilhado de endereço MUST residir no módulo shared do cliente — proibida duplicação por domínio (ouvidoria, tramitação, etc.).
- **FR-010**: Nenhum atributo de endereço fora do modelo canônico MUST ser introduzido (sem campos extras como "cidade texto livre" ou "estado" separado do vínculo IBGE).
- **FR-011**: Mensagens de erro MUST ser compreensíveis ao usuário final (CEP inválido, CEP não encontrado, serviço indisponível) — sem expor detalhes técnicos de integração.
- **FR-012**: Troca de UF MUST limpar seleção de município anterior para manter consistência UF ↔ código IBGE.

### Key Entities *(include if feature involves data)*

- **Endereço (Address)**: Representação universal de localização vinculada a registros do tenant. Atributos: CEP (`postalCode`), logradouro (`street`), número (`number`), complemento (`complement`), ponto de referência (`landmark`), bairro (`neighborhood`), zona (`zone`), código IBGE do município (`municipioIbge`). Persistência e regras de negócio são definidas pelo modelo canônico da plataforma — esta feature apenas padroniza captura no cliente.

- **Município**: Entidade de referência com código IBGE (7 caracteres, identificador único), nome e UF. Usada para validar e selecionar o vínculo `municipioIbge` do endereço; lista obtida por UF via serviço público de localidades.

- **Consulta CEP**: Resultado transitório de lookup postal contendo logradouro, bairro, localidade, UF e código IBGE quando disponível — mapeado para atributos canônicos do endereço.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Desenvolvedores de módulos conseguem incorporar captura de endereço completa importando exclusivamente artefatos do módulo shared — zero reimplementação de consulta CEP ou lista de municípios em módulos de domínio.
- **SC-002**: Usuários que informam CEP válido veem logradouro, bairro e município preenchidos em menos de 2 segundos em condições normais de conectividade.
- **SC-003**: Lista de municípios por UF fica disponível para seleção em menos de 1 segundo após escolha da UF em condições normais de conectividade.
- **SC-004**: 100% dos campos do modelo canônico de endereço estão disponíveis no formulário reutilizável e como campos composáveis — verificável por checklist de atributos.
- **SC-005**: Nenhum módulo consumidor introduz atributos de endereço fora do modelo canônico após adoção dos artefatos shared.
- **SC-006**: Em testes de usabilidade interna, pelo menos 90% dos preenchimentos de endereço com CEP válido conhecido completam auto-preenchimento sem correção manual de logradouro ou bairro.

## Assumptions

- Escopo limitado ao **cliente web** (`ci-client-v2`); persistência de endereço continua responsabilidade da API existente e do modelo `Address` — sem novos endpoints nesta feature.
- Consultas a serviços públicos (CEP e municípios IBGE) são feitas **diretamente pelo navegador**; não há proxy via API nesta entrega.
- Serviços externos ([ViaCEP](https://viacep.com.br/), API pública IBGE) permanecem disponíveis e acessíveis via CORS para o domínio do cliente em produção.
- Código IBGE retornado pela consulta CEP é compatível com a tabela `Municipio` da plataforma (7 dígitos); divergências pontuais são tratadas com seleção manual.
- Campo `zone` (zona) não é retornado pelos serviços externos — permanece sempre preenchimento manual ou vazio.
- Autenticação, tenant e licenças não alteram comportamento da captura de endereço nesta feature.
- Primeira entrega não inclui cache offline nem persistência local de municípios — consultas são on-demand.
- Testes automatizados e implementação técnica (hooks, componentes) serão definidos na fase `/speckit-plan`.

## Dependencies

- Modelo canônico de endereço e município já definidos na API (`Address`, `Municipio`).
- Módulo `shared` do cliente como local único de artefatos cross-domain (constitution §V).
- Disponibilidade dos serviços públicos ViaCEP e IBGE para consulta em tempo de execução no browser.

## Out of Scope

- Novos endpoints ou módulo NestJS para proxy/cache de CEP ou IBGE.
- Sincronização ou seed de municípios a partir desta feature (dados IBGE já existem na API).
- Validação server-side de endereço ou geocodificação reversa.
- Suporte a endereços internacionais ou formatos postais fora do Brasil.
- Busca de CEP por logradouro (pesquisa reversa ViaCEP) — apenas consulta por CEP de 8 dígitos nesta entrega.
