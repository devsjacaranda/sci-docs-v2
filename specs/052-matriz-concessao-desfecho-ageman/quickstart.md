# Quickstart: Validação manual — 052 Matriz Concessão × Desfecho (AGEMAN)

**Spec**: [spec.md](./spec.md) · **Contrato**: [contracts/relatorio-gestao-concessao-desfecho.md](./contracts/relatorio-gestao-concessao-desfecho.md)

## Pré-requisitos

```powershell
cd ci-api-v2; npm run start:dev
cd ci-client-v2; npm run dev   # turbo → @ci/web
```

Tenant AGEMAN (Jacaranda) com manifestações reais de agosto/2026 (mesmo dataset usado nas specs 049/050 — ver `civ2-docs/specs/049-.../new-demanda/extracted-sheets.txt` se precisar recriar dados de referência).

## Cenário 1 — Matriz Concessão × Desfecho (User Story 1)

1. Login como usuário do módulo Ouvidoria, tenant AGEMAN.
2. Abrir **Relatório de gestão da Ouvidoria**, filtrar ano 2026 / mês 08.
3. Localizar o novo bloco/tabela "Concessão × Desfecho".
4. **Esperado**: uma linha por concessão (Água/Saneamento, Transporte Coletivo, Iluminação Pública, Coleta de Lixo, Estacionamento Rotativo (Zona Azul)[, Não informado]), colunas Resolvida pela AGEMAN | Meio Jurídico | Pendente | Pendente (desfecho), com total por linha.
5. Conferir célula "Água/Saneamento → Pendente": deve bater com `SELECT COUNT(*) FROM "Manifestacao" WHERE "tenantId" = :ageman AND "createdAt" BETWEEN ... AND status NOT IN ('answered','closed','closed_unresolved','closed_meio_juridico') AND <concessão = água>`.
5b. Conferir que a linha "Estacionamento Rotativo (Zona Azul)" usa esse rótulo exato — não "Zona Azul" nem "Estacionamento Rotativo" sem o sufixo — em tela, PDF e Excel.
6. Exportar PDF e Excel do relatório — confirmar que a mesma tabela aparece com os mesmos números.

## Cenário 2 — Encerramento sem opção "Pendente" (User Story 2)

1. Abrir uma demanda em tramitação (status `in_review`/`forwarding`).
2. Clicar em "Encerrar".
3. **Esperado**: o grupo "Desfecho da demanda" mostra **apenas** "Resolvida pela AGEMAN" e "Meio Jurídico" — sem terceiro botão "Pendente".
4. Tentar submeter sem selecionar nenhuma opção — **esperado**: bloqueado, mensagem de erro de campo obrigatório.
5. (Opcional, via API/Postman) Enviar `POST .../encerrar` com `{ "desfecho": "pendente" }` — **esperado**: resposta `400`.

## Cenário 3 — Status "Pendente" antes de virar demanda (User Story 3)

1. Criar uma nova manifestação/solicitação (fluxo público ou interno).
2. Antes de qualquer encaminhamento, verificar o status exibido na lista de demandas e na consulta pública (se aplicável).
3. **Esperado**: rótulo "Pendente" (não "Em análise") em ambas as telas.
4. Encaminhar/tramitar a manifestação — confirmar que o novo status ("Tramitando") não usa o rótulo "Pendente".

## Cenário 4 — Filtro por tipo de concessão (User Story 4)

1. Na lista de demandas (tenant AGEMAN), localizar o filtro "Tipo de concessão".
2. Selecionar "Água / Saneamento".
3. **Esperado**: lista mostra só demandas daquele tipo; contagem de resultados bate com a coluna "Total" da linha "Água/Saneamento" na matriz do Cenário 1 (mesmo período, se aplicado filtro de data igual).
4. Combinar com filtro de status — confirmar que os dois filtros se aplicam juntos (AND).
5. (Tenant sem concessões mapeáveis, se houver ambiente de teste) — confirmar que o filtro de concessão **não aparece**.

## Critério de aceite consolidado

- SC-001 a SC-004 da spec — ver [spec.md § Success Criteria](./spec.md#success-criteria-mandatory).
- Nenhuma regressão nos blocos existentes do relatório (KPIs, `demandasPorDesfecho`/`demandasFinalizadas`, `demandasPendentes`, `porMotivo`, `porFormaAtendimento`, `orientacoesEncaminhamentos`, `pesquisaSatisfacao`, `participacaoEventos`).
