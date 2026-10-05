# Quickstart: Ajustes internos da Ouvidoria AGEMAN

Validação da spec 025. Detalhe dos contratos em [contracts/](./contracts/). Não substitui `tasks.md`.

## Pré-requisitos

- `sci-api-v2` e `sci-client-v2/sci-client-monorepo/apps/web` com dependências instaladas.
- Tenant de teste com pelo menos: uma manifestação real, uma `closed_unresolved`, uma `OUV-DEMO-2026-0014`, e um `createdAt` na virada do mês em UTC.

## API

No `sci-api-v2`:

```text
npx jest src/modules/ouvidoria/repository/dashboard.repositories.spec.ts src/modules/ouvidoria/test/use-cases/get-relatorio-gestao.use-case.spec.ts src/modules/ouvidoria/use-cases/purge-manifestacoes-demo.use-case.spec.ts src/modules/ouvidoria/use-cases/list-manifestacoes.use-case.spec.ts --no-coverage
```

Os caminhos novos entram quando as tarefas criarem os arquivos. Até lá, rode o spec que a tarefa citar.

Esperado:

- Pendentes + Resolvidas + Meio jurídico = Total da métrica.
- Soma de atendimentos por mês = Total da métrica.
- `OUV-DEMO-2026-0014` não entra nas contas e, depois do purge, não é encontrada.
- `situacao=pendente` devolve análise, tramitação e desfecho pendente, e não devolve rascunho.

## Client

No `sci-client-v2/sci-client-monorepo/apps/web`:

```text
npx vitest run src/modules/ouvidoria/pages/__tests__/ManifestacoesListPage.status-labels.test.tsx src/modules/ouvidoria/__tests__/OuvidoriaRelatorioGestaoPage.test.tsx src/modules/shared/components/__tests__/AddressFields.test.tsx src/modules/ouvidoria/components/__tests__/ManifestacaoAcessoCard.test.tsx
```

Esperado:

- Filtro com exatamente quatro opções, sem “Pendente (desfecho)”.
- Métrica do período com Total, Pendentes, Resolvida pela AGEMAN e Meio jurídico.
- Zona do formulário de nova manifestação preenchida pelo bairro e não digitável.
- Cartão “Quem tem acesso” só com o super administrador Romulo Gabriel Pinheiro Pereira.

## Conferência manual

1. Abrir o relatório do período do relato. Os três grupos somam o total. A soma dos meses de atendimento é esse total. Se `ouv-demo` fazia parte do 105, o total novo é menor e igual nas três leituras.
2. Buscar `ouv-demo-2026-0014` na lista. Não aparece e não abre.
3. Ir à página 4, abrir uma manifestação, voltar. A lista está na página 4. Sair pelo menu e abrir Manifestações de novo: ainda a página 4. Fechar o navegador e entrar: página 1.
4. Nova manifestação: informar um bairro de Manaus com zona. A zona aparece sozinha e o campo não aceita texto.
5. Entrar com administrador comum: o bloco Quem tem acesso não está na ficha. Entrar com a conta nomeada: o bloco está.
