# Implementation Plan: Migração de Módulos Inteiros v1 → v2 (Tenant AGEMAN)

**Branch**: `038-migracao-modulos-v1` | **Date**: 2026-08-21 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `civ2-docs/specs/038-migracao-modulos-v1/spec.md`

**Artefatos**: [research.md](./research.md) · [data-model.md](./data-model.md) · [contracts/](./contracts/README.md) · [quickstart.md](./quickstart.md)

## Summary

Migrar oito módulos do sistema legado para o v2 — Ouvidoria, Diagnóstico, Gabinete, Protocolo, Diretorias, Documentos Tramitados, Notificações e Autos, e Controle Numérico — de forma que cada módulo, ao final, torne o correspondente do v1 desnecessário para a AGEMAN. Escopo inclui código, telas, dados e o portal público do cidadão. Fiscalização, insights com IA e maturidade ficam fora.

A abordagem técnica tem quatro pilares:

**Estender, não recomeçar.** O repositório já tem um pipeline de migração em `ci-api-v2/scripts/migracao-agema-v1/` com quatro camadas (extração, mapeamento, carga, reconciliação), execução de staging validada e testes de mapeamento. O plano corrige suas lacunas conhecidas — idempotência incompleta em cinco entidades, endereços não migrados, contagens que não descontam exclusões — em vez de descartá-lo.

**Paridade de capacidade, não de pixel.** O v2 já cobre parte dos módulos. Onde há lacuna, implementar; onde o v1 tem dívida, corrigir em vez de portar. As dívidas identificadas e explicitamente não reproduzidas: filtragem no navegador sobre página já carregada, indicador de painel com valor fixo, persistência de dado de negócio no navegador, gating de módulo por identificador de instituição no código, arquivos de mais de mil linhas concentrando geração de documento, e cadastros que aceitam corpo de requisição sem validação de tipo.

**Verificação por dado, não por inspeção.** Comparação direta entre os dois bancos (MySQL e PostgreSQL) por contagem e por campo, com equivalências de representação declaradas num mapa revisável; e testes de navegador que percorrem a mesma jornada nos dois sistemas comparando o que cada um apresenta. O comparador é ele próprio testado com divergência deliberada.

**Um módulo por vez, com critério de encerramento explícito.** A ordem é ditada por dependência: dados primeiro, depois Ouvidoria, Gabinete e cadastros, Diagnóstico, e por fim o portal público.

## Technical Context

**Language/Version**: TypeScript. Node na versão exigida pelo Playwright (22, 24 ou 26).

**Primary Dependencies**:

| Camada | Dependências |
|---|---|
| API | NestJS 11, Fastify, Pino, Zod com nestjs-zod, Prisma 7.8 com adapter PostgreSQL |
| Cliente | React 19, Vite 8, Tailwind v4, shadcn/ui, Nivo |
| Novas nesta feature | `mysql2` (leitura da base externa do Diagnóstico e da base do v1), PDFKit (documentos com timbre no servidor), `docx` (documento editável da manifestação), `@playwright/test` 1.62.1 (testes de navegador comparativos) |

**Storage**: PostgreSQL para o v2. MySQL somente leitura em duas frentes — a base restaurada do v1, para migração e comparação, e a base externa de processos judiciais, consumida em tempo real pelo Diagnóstico. Wasabi para arquivos, no mesmo bucket do v1.

**Testing**: Jest na API, com TDD obrigatório. Vitest com MSW no cliente. Playwright para os testes comparativos entre os dois sistemas. Scripts de comparação direta entre bancos.

**Target Platform**: navegador para os três aplicativos web; servidor Node para a API. Desenvolvimento em Windows com PowerShell.

**Project Type**: aplicação web multi-pacote — uma API e um monorepo de frontend com três aplicativos.

**Performance Goals**: listagens paginadas respondendo em até dois segundos para os volumes da instituição; painéis em até três segundos. Consultas à base externa do Diagnóstico usam cache em memória com tempo de vida curto para não sobrecarregar uma base que não controlamos, mantendo coerência entre a contagem e a listagem de uma mesma consulta.

**Constraints**:

- A base do v1 e a base externa do Diagnóstico são **somente leitura**. Nenhuma escrita, em nenhuma circunstância.
- Migração idempotente e interrompível sem deixar registro parcial.
- Chaves de armazenamento do v1 reutilizadas verbatim; nenhuma cópia de objeto no bucket. O prefixo de armazenamento permanece vazio.
- Indisponibilidade de dependência externa é sempre erro explícito. Nunca lista vazia, nunca dado estimado, nunca persistência local como alternativa.
- Nenhum teste aponta para produção; nenhuma credencial tem valor padrão no código.
- Tenant exclusivamente AGEMAN nesta feature, mas sem nome de instituição em condicional de código.

**Scale/Scope**: oito módulos; cerca de 40 tabelas de origem consolidadas em cerca de 20 modelos de destino; três aplicativos de frontend; aproximadamente 25 telas; 81 requisitos funcionais e 20 critérios de sucesso mensuráveis.

## Constitution Check

*GATE: aprovado para a Phase 0 e reavaliado após a Phase 1.*

| Princípio | Situação | Observação |
|---|---|---|
| **I. Spec-Driven Development** | Conforme | Fluxo seguido; esta feature substitui a 036, que foi marcada como superada |
| **II. Test-First** | Conforme, com exigência reforçada | Ver abaixo |
| **III. Stack fixa** | Conforme com quatro desvios justificados | Ver [Complexity Tracking](#complexity-tracking) |
| **IV. Multi-tenant e licenças** | Conforme | Tenant por cabeçalho e contexto assíncrono; exclusão lógica por extensão do Prisma; Diagnóstico protegido por permissão de módulo, sem exigir licença nova |
| **V. Clean code e modularidade** | Conforme, com exigência reforçada | Ver abaixo |

**Sobre o princípio II.** A ordem vermelho-verde-refatoração se aplica a todo código novo, mas esta feature tem duas exigências adicionais que decorrem da sua natureza. Primeiro: o mapeamento de cada campo tem teste antes da carga, porque descobrir um mapeamento errado depois de migrar significa reexecutar tudo. Segundo: o comparador precisa de teste que **introduza divergência e exija reprovação** — um verificador que aprova tudo é indistinguível de um verificador quebrado, e a spec faz disso critério de sucesso.

**Sobre o princípio V.** A constitution exige uma operação por arquivo em repositórios e casos de uso. O legado concentra a geração de documentos em arquivos de 1260 e 758 linhas. Reproduzir essa estrutura violaria o princípio e recriaria a dívida que a spec proíbe. A geração de documentos é decomposta em: resolução do timbre, composição de cabeçalho e rodapé, renderização de tabelas, renderização de gráficos, e o caso de uso que orquestra.

**Sobre validação.** A constitution proíbe class-validator na API. O v1 usa class-validator nas rotas que têm validação, e **nenhuma validação** nos cadastros de protocolo. Nada disso é portado: todo endpoint do v2 valida por schema Zod com o pipe global, inclusive os cadastros que no v1 aceitavam qualquer chave permitida sem verificação de tipo.

**Sobre a paleta e os gráficos.** Nivo é imposto pela stack; o v1 usa Recharts em parte dos painéis. Os gráficos são reescritos, não portados. O portal público usa a paleta Mint do projeto, não o azul institucional do portal antigo.

### Reavaliação após a Phase 1

Sem violação nova. Três pontos merecem registro:

1. O modelo ganha um novo status de encerramento de manifestação, decidido para preservar o indicador de resolutividade. Isso amplia um enum existente em vez de criar entidade paralela — caminho de menor complexidade.
2. O portal público entra como terceiro aplicativo do monorepo, coerente com a estrutura já adotada (`apps/web` e `apps/admin-saas`). Não requer alteração na configuração do Turborepo, cujas tarefas são genéricas e descobrem aplicativos pelo padrão de diretório.
3. A origem de cada registro migrado passa a ser persistida no banco, e não apenas num arquivo de cache local. Isso adiciona um modelo, mas torna a idempotência verificável contra o banco e sustenta o relatório de correspondência exigido pela spec.

## Project Structure

### Documentation (this feature)

```text
civ2-docs/specs/038-migracao-modulos-v1/
├── spec.md
├── plan.md               # este arquivo
├── research.md           # Phase 0 — 21 decisões
├── data-model.md         # Phase 1
├── quickstart.md         # Phase 1
├── contracts/            # Phase 1
│   ├── README.md
│   ├── ouvidoria.md
│   ├── ouvidoria-publica.md
│   ├── gabinete.md
│   ├── diagnostico.md
│   └── migracao-cli.md
├── checklists/
│   └── requirements.md
└── tasks.md              # Phase 2 — gerado por /speckit-tasks
```

### Source Code (repository root)

```text
ci-api-v2/
├── prisma/schema/
│   ├── manifestacao.prisma            # novo status, novos campos, concessionária, catálogos
│   ├── gabinete.prisma                # ordem em documentos tramitados, recebimento em demanda
│   ├── setor.prisma                   # nome completo, descrição, situação de atividade
│   ├── diagnostico.prisma             # novo — marcadores
│   ├── documento-institucional.prisma # novo — modelo, documento, sequência, auditoria
│   └── migracao.prisma                # novo — origem dos registros migrados
├── src/modules/
│   ├── ouvidoria/                     # estende: painel, catálogos, atendimentos, documentos, público
│   │   ├── use-cases/                 # uma operação por arquivo
│   │   ├── repository/
│   │   ├── ouvidoria.schemas.ts
│   │   └── ouvidoria.controller.ts
│   ├── gabinete/                      # estende: receber, devolver, reencaminhar, histórico em PDF
│   ├── setor/                         # estende: campos de diretoria
│   ├── diagnostico/                   # novo módulo
│   │   ├── services/automacao-db.service.ts   # base externa, somente leitura
│   │   ├── repository/                        # consultas com deduplicação e classificação
│   │   ├── use-cases/
│   │   ├── lib/                               # classificação de categoria e tipo de resultado
│   │   └── diagnostico.schemas.ts
│   ├── documento-institucional/       # novo módulo
│   │   ├── use-cases/
│   │   ├── jobs/                      # abandono de reserva, com auditoria
│   │   └── pdf/                       # timbre, cabeçalho, tabelas, gráficos — arquivos pequenos
│   └── shared/storage/                # correção da configuração e validação de chave por tenant
├── src/infrastructure/config/env.schema.ts    # passa a validar armazenamento e base externa
└── scripts/migracao-agema-v1/         # estendido
    ├── source/                        # clientes de leitura
    ├── mappers/                       # + testes por campo
    ├── load/                          # + idempotência por chave natural
    └── reconciliation/                # + comparação campo a campo e relatório de anexos

ci-client-v2/
├── apps/web/
│   ├── vite.config.ts                 # porta fixada
│   └── src/modules/
│       ├── ouvidoria/                 # painel real, catálogos, atendimentos, documentos
│       ├── gabinete/                  # ações de fluxo, diretorias, cadastros consolidados
│       └── diagnostico/               # novo — três visões
├── apps/publico/                      # novo aplicativo — portal do cidadão
├── packages/ui/                       # + aviso temporário e indicador de etapas
└── e2e/                               # novo workspace — testes comparativos
    ├── playwright.config.ts
    ├── fixtures/                      # sessão do v1 e do v2, mecânicas distintas
    └── specs/
```

**Structure Decision**: mantida a estrutura do monorepo já adotada. A API permanece pacote independente na raiz, com módulos por domínio nas camadas repositório, casos de uso e serviços. O frontend ganha um terceiro aplicativo (`apps/publico`) e um workspace de testes de navegador (`e2e/`), este último fora de `packages/` porque não é biblioteca consumida pelos aplicativos e precisa ficar fora dos padrões de varredura do Tailwind. Os módulos do cliente espelham os da API, conforme o princípio V.

## Sequência de implementação

A ordem decorre de dependências reais, não de preferência.

| Etapa | Conteúdo | Depende de |
|---|---|---|
| 0 | Correção da configuração de armazenamento e sua validação no boot | — |
| 1 | Alterações de schema e migrações | 0 |
| 2 | Pipeline de migração: idempotência, entidades faltantes, anexos, origem persistida | 1 |
| 3 | Reconciliação: contagens com exclusões, comparação campo a campo, relatório de anexos, teste do comparador | 2 |
| 4 | Fundação dos testes de navegador: workspace, porta fixa, sessões dos dois sistemas | — |
| 5 | Ouvidoria: painel, catálogos, atendimentos, documentos, encerramento com resolução | 1, 3 |
| 6 | Gabinete: ações de fluxo, correção do setor atual, histórico em PDF, cadastros, diretorias | 1, 3 |
| 7 | Diagnóstico: base externa, consulta, painel, marcadores, exportação | 1 |
| 8 | Documentos institucionais: modelos, reserva transacional, ciclo de vida, job com auditoria | 1 |
| 9 | Endpoints públicos na API | 5 |
| 10 | Portal público como aplicativo do monorepo | 9 |
| 11 | Testes comparativos por módulo e verificação dos critérios de sucesso | 4–10 |

A etapa 0 vem primeiro porque a API está hoje em modo de armazenamento local silencioso: sem corrigi-la, qualquer validação de anexo daria falso positivo. A etapa 4 é independente das demais e pode correr em paralelo.

## Riscos

| Risco | Impacto | Mitigação |
|---|---|---|
| Anexos do portal público sem vínculo reconstruível na origem | perda de arquivos enviados pelo cidadão | investigação **precede** a carga de anexos; o que não for reconstruível entra no relatório de não localizados, nunca desaparece em silêncio |
| Divergência entre 12 e 13 tabelas de documentos tramitados | um setor inteiro não migrar | conciliar a contagem de tabelas antes da carga; a reconciliação compara as 13 origens individualmente |
| Múltiplos gestores no mesmo setor na origem | escolha silenciosa de chefe | a migração elege um e **relata** os demais como membros |
| Colisão de número em protocolos | falso negativo na reconciliação | resolver por chave natural composta, não por número isolado |
| Base externa do Diagnóstico com schema fora do nosso controle | quebra em produção sem aviso | consulta restrita às colunas conhecidas; indisponibilidade e ausência de coluna tratadas como erro explícito |
| Volume real de dados desconhecido em algumas entidades | estimativas de esforço e de desempenho erradas | as contagens da etapa 3 precedem as etapas de módulo; nenhuma suposição de volume zero sem verificação |

## Complexity Tracking

| Violação | Por que é necessária | Alternativa mais simples rejeitada porque |
|---|---|---|
| `mysql2` como segunda fonte de dados, fora do Prisma | O Diagnóstico consome em tempo real uma base MySQL externa, somente leitura, alimentada por automação jurídica e cujo schema não controlamos. A migração lê a base restaurada do v1, também MySQL. | Um segundo client Prisma com provedor MySQL exigiria schema e generator adicionais, ampliando a superfície de build para uma base que a aplicação nunca escreve. Sincronizar para o PostgreSQL introduziria defasagem e uma cópia a manter, contra a decisão de conexão direta. Ler via API do v1 manteria o v1 vivo, contra o objetivo de encerramento de módulo. O padrão `mysql2` paralelo já foi validado neste repositório. |
| PDFKit para documentos com timbre | Documentos com timbre institucional, tabelas e gráficos, gerados no servidor. A stack fixa não define biblioteca de PDF porque nenhum módulo anterior precisou. | Gerar no navegador — como o v1 faz para o PDF da manifestação — joga branding e dados sensíveis para o cliente, produz saída dependente do navegador e impede teste automatizado do documento. |
| `docx` para o documento editável da manifestação | O v1 entrega o documento em formato editável e a instituição depende dele; a paridade de capacidade exige manter. | Entregar apenas PDF removeria capacidade existente, o que a spec proíbe. |
| `@playwright/test` como quarta ferramenta de teste | A verificação exigida compara **dois sistemas em execução** lado a lado, o que nem Jest nem Vitest com MSW conseguem fazer: ambos simulam a borda, e é justamente a borda real dos dois sistemas que precisa ser comparada. | Comparar apenas pelos bancos verificaria dados mas não a jornada, e a spec exige as duas frentes. Testes manuais não são repetíveis nem servem de critério de aceite. |

Nenhuma das quatro adiciona pacote ao caminho de execução em produção do cliente. As três primeiras ficam na API; a quarta fica num workspace de teste fora dos aplicativos.
