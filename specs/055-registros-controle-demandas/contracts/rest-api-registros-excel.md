# Contrato REST: Registros em Planilha (Ouvidoria)

## `GET /ouvidoria/manifestacoes/registros/excel`

Gera e devolve a planilha `.xlsx` de um período. Rota síncrona, sem sessão, sem ticket.

### Autenticação e licença

- Bearer JWT. `@RequireModulo('ouvidoria')` — mesma regra de quem vê a lista de manifestações.
- Sem verificação de acesso por manifestação (diferente do PDF da 054): quem vê o módulo vê o agregado do período.

### Query

| Campo | Tipo | Regra |
|---|---|---|
| `ano` | number | Obrigatório. Inteiro, 2000–2100. |
| `mes` | number | Opcional. Inteiro, 1–12. Omitido = ano inteiro. |

Zod: `ano` coagido de string para number; `mes` idem, opcional.

### Resposta 200

- `Content-Type: application/vnd.openxmlformats-officedocument.spreadsheetml.sheet`
- `Content-Disposition: attachment; filename="controle-de-demandas-{ano}[-{mes}].xlsx"`
- Corpo: `StreamableFile` do buffer do workbook (`exceljs`).

### Erros

| Status | Código | Quando |
|---|---|---|
| 400 | `VALIDATION_FAILED` | `ano` ausente ou fora de 2000–2100; `mes` fora de 1–12 |
| 404 | `REGISTROS_PERIODO_VAZIO` | Nenhuma manifestação no período, no tenant |
| 422 | `REGISTROS_LIMITE_LINHAS` | Total de linhas do período acima do teto operacional. Corpo: `{ totalLinhas, limiteLinhas }` |
| 429 | `REGISTROS_THROTTLE` | Mais de N pedidos por minuto do mesmo usuário |

Mensagens em português, no padrão de `OUVIDORIA_ERROR_MESSAGE`.

### Efeitos colaterais

- Grava `AuditLog` com `action: 'ouvidoria.manifestacao.registros_export'`, `entity: 'Manifestacao'`, `entityId: null`, `userId` via `resolveUserTableId`, payload via `withActorPayload` com `{ resultado, periodo: { ano, mes }, totalLinhas, abas: [{ nome, linhas }] }` — sem nome, telefone, endereço ou qualquer dado pessoal.
- Recusa (período vazio, limite de linhas) também grava auditoria, com `resultado: 'recusado'` e o motivo.

### Mapeamento de colunas (linha = 1 manifestação)

| Coluna | Fonte |
|---|---|
| `#` | Fórmula `=ROW(A1)` relativa à primeira linha de dados da aba |
| `ANO` | Ano de `createdAt` |
| `PROTOCOLO` | `numeroPersonalizado` (fallback: `protocol`) |
| `DATA DA EMISSÃO` | `createdAt`, `dd/mm/aaaa` |
| `FORMA DE ATENDIMENTO` | `serviceMode` (fallback `dadosAdicionais.formaAtendimento`), maiúsculas |
| `MOTIVO DA RECLAMAÇÃO` | Chave canônica de `AGEMAN_MOTIVOS_BY_PROGRAMA` (maiúsculas); fallback: `category`/`motivo` salvos, maiúsculas |
| `NOME DO RECLAMANTE` | `requesterFullName`, ou `ANÔNIMO` se `isAnonymous` |
| `NOME DO TITULAR` | `holderName` |
| `MATRÍCULA/NÚMERO DO CLIENTE` | `registrationNumber` |
| `CONTATO` | `requesterMobilePhone` → `requesterHomePhone` → `requesterBusinessPhone` → `replyEmail` |
| `RUA` | `address.street` |
| `NÚMERO DO IMÓVEL` | `address.number` |
| `BAIRRO` | `address.neighborhood` |
| `ZONA (NORTE, SUL, LESTE, CENTRO-SUL, CENTRO-OESTE OU RURAL)` | `address.zone` |
| `TINHA PROTOCOLO NA CONCESSIONÁRIA? S/N` | `ManifestacaoConcessionaria.jaEntrouContato` → `SIM`/`NÃO`/branco |
| `ATENDENTE` | Nome do `emissor`, maiúsculas |
| `PENDENTE OU RESOLVIDA?` | `closed` → `RESOLVIDA`; `closed_meio_juridico` → `MEIO JURÍDICO`; demais → `PENDENTE` |
| `DATA DE RECEBIMENTO…` até `OBSERVAÇÃO` (7 colunas) | Sem fonte no sistema — em branco |

### Layout da aba (idêntico ao de `Controle de Demandas 2026.xlsx`)

Sem células mescladas e sem indicação de período na planilha (o período fica só no nome do arquivo e nos metadados do documento):

| Linha | Conteúdo |
|---|---|
| 1 | Título `CONTROLE DE DEMANDAS GERADAS` |
| 2 | Em branco |
| 3 | Legenda `ND - NÃO DISPONÍVEL/NÃO RELACIONADA` |
| 4 | Legenda `NI - NÃO INFORMADO` |
| 5 | Em branco |
| 6 | Cabeçalho (25 colunas, negrito, centralizado, borda fina) |
| 7+ | Dados — uma linha por manifestação |

### Agrupamento em abas

Concessão resolvida por `resolveProgramaCode` sobre `{ programa, serviceMode, numeroPersonalizado, category, motivo }`. Nomes de aba, só quando houver dados:

`1 - Água e Esgoto`, `2 - Transporte Coletivo`, `3 - Iluminação Pública`, `4 - Coleta de Lixo`, `5 - Estacionamento Rotativo`, `6 - Assuntos Institucionais`, `Sem concessão`.
