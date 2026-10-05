# STATUS — 025 Ajustes internos da Ouvidoria AGEMAN

**Data**: 2026-10-05  
**Estado**: Concluída — 22/22 tasks em `tasks.md`

## Entregue

### API (`sci-api-v2`)
- População oficial: sem rascunho e sem protocolo `ouv-demo`, com mês extraído em UTC
- Pendentes = em análise + tramitação + desfecho pendente; Resolvidas pela AGEMAN e Meio jurídico fecham o total
- Acumulado geral usa o mesmo recorte de ano e mês da métrica
- Lista aceita `situacao=pendente|resolvida_ageman|meio_juridico` e exclui rascunho e `ouv-demo`
- Purge físico das demonstrações em `purge-manifestacoes-demo` e script `npm run ouvidoria:purge-demo` (não executado contra banco)
- `desfechoPendentes` permanece na resposta para a planilha Excel

### Client (`sci-client-v2`)
- Métrica do período com Total, Pendente, Resolvida pela AGEMAN e Meio jurídico
- Lista sem o bloco Pendente (desfecho) e com as quatro opções de status
- Volta da ficha reabre a página e os filtros da mesma visita
- Zona da nova manifestação preenchida pelo bairro e somente leitura
- Quem tem acesso só para o super administrador Rômulo Gabriel Pinheiro Pereira

## Validação

```powershell
cd sci-api-v2
npx jest src/modules/ouvidoria/test/repository src/modules/ouvidoria/lib/manifestacao-oficial.spec.ts src/modules/ouvidoria/use-cases/purge-manifestacoes-demo.use-case.spec.ts src/modules/ouvidoria/use-cases/list-manifestacoes.use-case.spec.ts src/modules/ouvidoria/ouvidoria.schemas.spec.ts src/modules/ouvidoria/test/use-cases/get-relatorio-gestao.use-case.spec.ts --no-coverage
npm test
npm run build

cd sci-client-v2/sci-client-monorepo/apps/web
npx vitest run src/modules/ouvidoria src/modules/shared/components/__tests__/AddressForm.test.tsx
npm test
npm run build
```

O script `ouvidoria:purge-demo` apaga registros de verdade. A validação automática cobre o caso de uso; a execução contra o banco da AGEMAN fica para operação.

Resultado de 2026-10-05:

- API `npm test`: 1968 passaram, 1 falhou por timeout em `tenant-branding.controller.spec.ts` (fora desta feature). Suítes da Ouvidoria passaram. `npm run build` passou.
- Client `npm test`: a suíte inteira teve 20 falhas já existentes em outros módulos e dois timeouts da Ouvidoria sob carga. Reexecução isolada do wizard, da lista, do endereço e de Quem tem acesso: 27 passaram. `npm run build` do app web conferido nesta conclusão.

## Critérios spec

| SC | Status |
|----|--------|
| SC-001 Métrica, meses e acumulado no mesmo número | OK (testes de agregação) |
| SC-002 Total oficial sem ouv-demo, igual nas três leituras | OK (filtro oficial) |
| SC-003 Manifestação ouv-demo fora da lista e das contas | OK (filtro + purge testado; purge de banco não rodado) |
| SC-004 Zona preenchida pelo bairro e não digitável | OK |
| SC-005 Retorno à página 4 da lista na mesma visita | OK |
| SC-006 Quatro status e sem bloco Pendente (desfecho) | OK |
| SC-007 Quem tem acesso só na conta nomeada | OK |
